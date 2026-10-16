"""Trình xem và sửa bảng TSV của THIENLONG. Chạy: py -3 dev/GM/table_editor/main.py"""
from __future__ import annotations

import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

try:
    from PySide6.QtCore import QByteArray, QRectF, QSize
    from PySide6.QtGui import QIcon, QPainter, QPalette, QPixmap
    from PySide6.QtSvg import QSvgRenderer
    from PySide6.QtCore import QAbstractTableModel, QModelIndex, QSortFilterProxyModel, Qt
    from PySide6.QtGui import QAction, QColor, QKeySequence, QPen, QUndoCommand, QUndoStack
    from PySide6.QtWidgets import (
        QAbstractItemView, QApplication, QFileDialog, QHBoxLayout, QLabel, QLineEdit, QMainWindow,
        QMessageBox, QPlainTextEdit, QSplitter, QStyledItemDelegate, QTableView, QToolBar, QTreeWidget,
        QTreeWidgetItem, QVBoxLayout, QWidget,
    )
except ImportError:
    sys.exit("Chưa có PySide6. Cài bằng: py -3 -m pip install PySide6")

import core  # đặt sys.path tới TOOLS/server của repo
import tsv_file as tf

BAD_ROLE = Qt.UserRole + 1
ICON_DIR = HERE / "icons"
VIEW_ONLY_ROOTS = ("dev/client/assets/Table", "assets/i18n", "src/shared/protocol/catalog")
_ICONS: dict[str, QIcon] = {}


def _render(svg: str, color: QColor, size: int) -> QPixmap:
    data = QByteArray(svg.replace("currentColor", color.name()).encode("utf-8"))
    pix = QPixmap(size, size)
    pix.fill(Qt.transparent)
    painter = QPainter(pix)
    QSvgRenderer(data).render(painter, QRectF(0, 0, size, size))
    painter.end()
    return pix


def icon(name: str) -> QIcon:
    """Biểu tượng Lucide từ icons/, nét theo màu chữ palette; chế độ Disabled dùng màu chữ bị tắt."""
    if name in _ICONS:
        return _ICONS[name]
    path = ICON_DIR / f"{name}.svg"
    result = QIcon()
    if path.is_file():
        svg = path.read_text(encoding="utf-8")
        pal = QApplication.palette()
        normal = pal.color(QPalette.Active, QPalette.WindowText)
        off = pal.color(QPalette.Disabled, QPalette.WindowText)
        for size in (16, 32):  # 16 cho 100%, 32 cho HiDPI 200%; QIcon chọn theo devicePixelRatio
            result.addPixmap(_render(svg, normal, size), QIcon.Normal)
            result.addPixmap(_render(svg, off, size), QIcon.Disabled)
    _ICONS[name] = result
    return result
MAX_COL_CHARS = 48


class EditCell(QUndoCommand):
    def __init__(self, model, row, col, old, new):
        super().__init__(f"sửa ô {row + 1},{col + 1}")
        self.m, self.r, self.c, self.old, self.new = model, row, col, old, new

    def redo(self):
        self.m._set(self.r, self.c, self.new)

    def undo(self):
        self.m._set(self.r, self.c, self.old)


class InsertRow(QUndoCommand):
    def __init__(self, model, row):
        super().__init__("thêm dòng")
        self.m, self.r = model, row

    def redo(self):
        self.m._insert(self.r, [""] * len(self.m.lt.columns))

    def undo(self):
        self.m._remove(self.r)


class RemoveRows(QUndoCommand):
    def __init__(self, model, rows):
        super().__init__("xoá dòng")
        self.m, self.rows, self.saved = model, sorted(rows), []

    def redo(self):
        self.saved = [(r, self.m.rows[r]) for r in self.rows]
        for r in reversed(self.rows):
            self.m._remove(r)

    def undo(self):
        for r, data in self.saved:
            self.m._insert(r, data)


class TableModel(QAbstractTableModel):
    """Mô hình ảo: dữ liệu là list các list chuỗi, không widget cho từng ô."""

    def __init__(self, lt: core.Loaded, ann, stack: QUndoStack):
        super().__init__()
        self.lt, self.rows, self.ann, self.stack = lt, lt.rows, ann, stack
        self.has_ann_file = core.annotation_path(lt.relpath) is not None

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self.rows)

    def columnCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self.lt.columns)

    def kind(self, c):
        return self.lt.types[c] if c < len(self.lt.types) else ""

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        value = self.rows[index.row()][index.column()]
        if role == Qt.DisplayRole:
            return core.show_cell(value)
        if role == Qt.EditRole:
            return value
        if role == BAD_ROLE:
            return self.lt.kind == 1 and not core.type_ok(self.kind(index.column()), value)
        if role == Qt.ToolTipRole and self.lt.kind == 1 and not core.type_ok(self.kind(index.column()), value):
            return f"Giá trị không khớp kiểu {self.kind(index.column())}"
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal:
            if role == Qt.DisplayRole:
                return self.lt.columns[section]
            if role == Qt.ToolTipRole:
                return "\n".join(self.column_lines(section))
        elif role == Qt.DisplayRole:
            return str(section + 1)
        return None

    def column_lines(self, c):
        return core.column_lines(self.lt.columns[c], self.kind(c), self.ann, self.has_ann_file)

    def flags(self, index):
        base = Qt.ItemIsEnabled | Qt.ItemIsSelectable
        return base | Qt.ItemIsEditable if self.lt.kind == 1 else base

    def setData(self, index, value, role=Qt.EditRole):
        if role != Qt.EditRole or self.lt.kind != 1:
            return False
        old = self.rows[index.row()][index.column()]
        if value == old:
            return False
        self.stack.push(EditCell(self, index.row(), index.column(), old, str(value)))
        return True

    def _set(self, r, c, v):
        self.rows[r][c] = v
        i = self.index(r, c)
        self.dataChanged.emit(i, i)

    def _insert(self, r, data):
        self.beginInsertRows(QModelIndex(), r, r)
        self.rows.insert(r, list(data))
        self.endInsertRows()

    def _remove(self, r):
        self.beginRemoveRows(QModelIndex(), r, r)
        del self.rows[r]
        self.endRemoveRows()


class WarnDelegate(QStyledItemDelegate):
    """Vẽ viền cảnh báo cho ô sai kiểu; không chặn gõ."""

    def paint(self, painter, option, index):
        super().paint(painter, option, index)
        if index.data(BAD_ROLE):
            painter.save()
            painter.setPen(QPen(QColor(220, 120, 0), 2))
            painter.drawRect(option.rect.adjusted(1, 1, -2, -2))
            painter.restore()


class Window(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Trình sửa bảng TSV — THIENLONG")
        self.resize(1400, 860)
        self.lt: core.Loaded | None = None
        self.model: TableModel | None = None
        self.stack = QUndoStack(self)

        self.file_filter = QLineEdit(placeholderText="Lọc theo tên tệp…")
        self.tree = QTreeWidget()
        self.tree.setHeaderLabel("Kho bảng")
        self.tree.setIconSize(QSize(16, 16))
        self.file_filter.addAction(icon("search"), QLineEdit.LeadingPosition)
        self.tree.itemExpanded.connect(lambda it: self._folder_icon(it, True))
        self.tree.itemCollapsed.connect(lambda it: self._folder_icon(it, False))
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        lv.addWidget(self.file_filter)
        lv.addWidget(self.tree)

        self.row_filter = QLineEdit(placeholderText="Tìm trong bảng (lọc dòng đang hiện)…")
        self.row_filter.addAction(icon("search"), QLineEdit.LeadingPosition)
        self.title = QLabel("Chọn một bảng ở cây bên trái.")
        self.view = QTableView()
        self.view.setItemDelegate(WarnDelegate(self.view))
        self.view.setSelectionBehavior(QAbstractItemView.SelectItems)
        self.view.horizontalHeader().setSectionsMovable(False)
        self.view.verticalHeader().setDefaultSectionSize(self.fontMetrics().height() + 6)
        self.proxy = QSortFilterProxyModel(self)
        self.proxy.setFilterKeyColumn(-1)
        self.proxy.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.view.setModel(self.proxy)
        self.detail = QPlainTextEdit(readOnly=True)
        self.detail.setMaximumHeight(190)
        mid = QWidget()
        mv = QVBoxLayout(mid)
        mv.setContentsMargins(0, 0, 0, 0)
        top = QHBoxLayout()
        top.addWidget(self.title, 1)
        top.addWidget(self.row_filter, 1)
        mv.addLayout(top)
        mv.addWidget(self.view, 1)
        mv.addWidget(QLabel("Chi tiết cột và bảng:"))
        mv.addWidget(self.detail)

        split = QSplitter()
        split.addWidget(left)
        split.addWidget(mid)
        split.setSizes([330, 1070])
        self.setCentralWidget(split)

        bar = QToolBar("Lệnh")
        bar.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        bar.setIconSize(QSize(16, 16))
        self.addToolBar(bar)
        self.act_scan = QAction(icon("refresh-cw"), "Quét lại", self, triggered=self.rescan, shortcut=QKeySequence.Refresh)
        self.act_add = QAction(icon("list-plus"), "Thêm dòng", self, triggered=self.add_row)
        self.act_del = QAction(icon("list-minus"), "Xoá dòng", self, triggered=self.del_rows, shortcut=QKeySequence("Ctrl+Del"))
        self.act_undo = self.stack.createUndoAction(self, "Hoàn tác")
        self.act_undo.setShortcut(QKeySequence.Undo)
        self.act_undo.setIcon(icon("undo-2"))
        self.act_redo = self.stack.createRedoAction(self, "Làm lại")
        self.act_redo.setShortcut(QKeySequence.Redo)
        self.act_redo.setIcon(icon("redo-2"))
        self.act_export = QAction(icon("file-output"), "Xuất…", self, triggered=self.export)
        self.act_save = QAction(icon("save"), "Ghi trực tiếp", self, triggered=self.save_inplace, shortcut=QKeySequence.Save)
        bar.addAction(self.act_scan)
        bar.addSeparator()
        for a in (self.act_add, self.act_del, self.act_undo, self.act_redo):
            bar.addAction(a)
        bar.addSeparator()
        bar.addAction(self.act_export)
        bar.addAction(self.act_save)
        menu = self.menuBar().addMenu("&Tệp")
        menu.addAction(self.act_scan)
        menu.addSeparator()
        menu.addAction(self.act_export)
        menu.addAction(self.act_save)
        edit = self.menuBar().addMenu("&Sửa")
        for a in (self.act_undo, self.act_redo, self.act_add, self.act_del):
            edit.addAction(a)
        self.status_icon = QLabel()
        self.status = QLabel()
        self.statusBar().addWidget(self.status_icon)
        self.statusBar().addWidget(self.status, 1)

        self.file_filter.textChanged.connect(self.filter_tree)
        self.row_filter.textChanged.connect(self.proxy.setFilterFixedString)
        self.tree.currentItemChanged.connect(self.on_tree)
        self.view.horizontalHeader().sectionClicked.connect(self.show_column)
        self.stack.cleanChanged.connect(lambda _: self.update_title())
        self.populate()
        self.update_actions()

    # ---- cây ----
    def populate(self):
        self.tree.clear()
        for root, files in core.scan().items():
            top = QTreeWidgetItem([f"{root} ({len(files)})"])
            top.setIcon(0, icon("folder"))
            self.tree.addTopLevelItem(top)
            dirs = {"": top}
            for name in files:
                parts = name.split("/")
                parent, acc = top, ""
                for d in parts[:-1]:
                    acc = f"{acc}/{d}" if acc else d
                    if acc not in dirs:
                        dirs[acc] = QTreeWidgetItem(parent, [d])
                        dirs[acc].setIcon(0, icon("folder"))
                    parent = dirs[acc]
                leaf = QTreeWidgetItem(parent, [parts[-1]])
                leaf.setData(0, Qt.UserRole, str(core.REPO / root / name))
                leaf.setIcon(0, icon("lock" if root in VIEW_ONLY_ROOTS else "table"))
                if root in VIEW_ONLY_ROOTS:
                    leaf.setToolTip(0, "Chỉ xem, không ghi đè")
            top.setExpanded(True)

    def _folder_icon(self, item, opened):
        if not item.data(0, Qt.UserRole):
            item.setIcon(0, icon("folder-open" if opened else "folder"))

    def rescan(self):
        current = str(self.lt.path) if self.lt else None
        self.tree.blockSignals(True)
        self.populate()
        self.tree.blockSignals(False)
        self.filter_tree(self.file_filter.text())
        if current:
            self._mark_current()
        self.statusBar().showMessage("Đã quét lại kho bảng", 4000)

    def _mark_current(self):
        """Tệp đang mở mà không ghi đè được thì đổi biểu tượng thành ổ khoá."""
        if not self.lt:
            return
        it = self.tree.currentItem()
        if it and it.data(0, Qt.UserRole) == str(self.lt.path):
            it.setIcon(0, icon("table" if self.lt.can_overwrite else "lock"))
            it.setToolTip(0, self.lt.reason or "Sửa và ghi đè được")

    def filter_tree(self, text):
        text = text.lower()

        def walk(item):
            path = item.data(0, Qt.UserRole)
            if path:
                show = text in item.text(0).lower()
            else:
                show = any([walk(item.child(i)) for i in range(item.childCount())])
                if text:
                    item.setExpanded(show)
            item.setHidden(not show and bool(text))
            return show or not text

        for i in range(self.tree.topLevelItemCount()):
            walk(self.tree.topLevelItem(i))

    def on_tree(self, cur, prev):
        path = cur.data(0, Qt.UserRole) if cur else None
        if not path or (self.lt and str(self.lt.path) == path):
            return
        if not self.confirm_discard():
            self.tree.blockSignals(True)
            self.tree.setCurrentItem(prev)
            self.tree.blockSignals(False)
            return
        self.open_path(path)

    def confirm_discard(self) -> bool:
        if self.lt is None or self.stack.isClean():
            return True
        ans = QMessageBox.question(
            self, "Bảng chưa lưu",
            f"Bảng {self.lt.relpath} có thay đổi chưa lưu. Bỏ các thay đổi đó?",
            QMessageBox.Discard | QMessageBox.Cancel, QMessageBox.Cancel)
        return ans == QMessageBox.Discard

    # ---- mở bảng ----
    def open_path(self, path):
        QApplication.setOverrideCursor(Qt.WaitCursor)
        try:
            t0 = time.perf_counter()
            lt = core.load(path)
            ann = {}
            try:
                ann = core.annotations(lt.relpath)
            except (tf.TsvError, OSError) as exc:
                self.statusBar().showMessage(f"Không đọc được tệp chú thích: {exc}", 8000)
            self.stack.clear()
            self.lt = lt
            self.model = TableModel(lt, ann, self.stack)
            self.proxy.setSourceModel(self.model)
            self.proxy.setFilterFixedString(self.row_filter.text())
            self.size_columns()
            self.est = core.size_estimate(lt, lt.rows)
            self.load_ms = (time.perf_counter() - t0) * 1000
        finally:
            QApplication.restoreOverrideCursor()
        self.update_title()
        self.update_actions()
        self.update_status()
        self._mark_current()
        self.show_column(0 if lt.columns else -1)

    def size_columns(self):
        fm = self.view.fontMetrics()
        cw = fm.horizontalAdvance("0")
        hdr = self.view.horizontalHeader()
        for c, name in enumerate(self.lt.columns):
            w = tf.display_width(name)
            for row in self.lt.rows[: core.SAMPLE_ROWS]:
                w = max(w, tf.display_width(core.show_cell(row[c])))
            hdr.resizeSection(c, min(w, MAX_COL_CHARS) * cw + 24)

    def update_title(self):
        if self.lt:
            dirty = "" if self.stack.isClean() else " *"
            self.title.setText(f"<b>{self.lt.relpath}</b>{dirty}")
            self.setWindowTitle(f"{self.lt.relpath}{dirty} — Trình sửa bảng TSV")
            self.update_status()

    def update_actions(self):
        lt = self.lt
        editable = bool(lt and lt.kind == 1)
        self.act_add.setEnabled(editable)
        self.act_del.setEnabled(editable)
        self.act_export.setEnabled(bool(lt and lt.can_export))
        self.act_save.setEnabled(bool(lt and lt.can_overwrite))

    def update_status(self):
        lt = self.lt
        if not lt:
            return
        rows = len(self.model.rows)
        parts = [f"{rows} dòng", f"{len(lt.columns)} cột", f"layout đang có: {lt.layout}"]
        if lt.kind == 1:
            est, approx = core.size_estimate(lt, self.model.rows) if rows < 50000 else self.est
            parts.append(f"layout sẽ ghi: {lt.write_layout} → {core.predicted_layout(lt, est)}")
            parts.append(f"cỡ sau khi căn: {'~' if approx else ''}{est / 1024:.1f} KiB (trần {tf.ALIGN_LIMIT // 1024} KiB)")
        if lt.tool_suffix:
            parts.append("sửa tay sẽ mất ở lần xuất sau")
        if lt.reason:
            parts.append(lt.reason)
        if self.proxy.rowCount() != rows:
            parts.append(f"đang hiện {self.proxy.rowCount()} dòng")
        self.status.setText(" | ".join(parts))
        name = "lock" if not lt.can_overwrite else ("triangle-alert" if self.bad_count() else "info")
        self.status_icon.setPixmap(icon(name).pixmap(QSize(16, 16), self.devicePixelRatioF()))
        self.status_icon.setToolTip(lt.reason or ("Có ô sai kiểu" if name == "triangle-alert" else "Sửa và ghi đè được"))

    def bad_count(self):
        lt = self.lt
        if not lt or lt.kind != 1 or len(self.model.rows) * len(lt.columns) > 200000:
            return 0
        return sum(1 for r in self.model.rows for t, v in zip(lt.types, r) if not core.type_ok(t, v))

    def show_column(self, c):
        lt = self.lt
        if not lt:
            return
        lines = self.model.column_lines(c) if 0 <= c < len(lt.columns) else []
        lines += ["", f"Tệp: {lt.relpath}", f"# source: {lt.source or '(không có)'}", f"# tool: {lt.tool or '(không có)'}"]
        note = core.table_note(lt.relpath)
        if note is not None:
            lines.append(f"table_names.tsv note: {note}")
        if lt.stray:
            lines.append("Dòng # sẽ mất nếu ghi lại: " + " | ".join(lt.stray))
        self.detail.setPlainText("\n".join(lines))

    # ---- sửa ----
    def add_row(self):
        idx = self.proxy.mapToSource(self.view.currentIndex())
        r = idx.row() + 1 if idx.isValid() else len(self.model.rows)
        self.stack.push(InsertRow(self.model, r))
        self.update_status()

    def del_rows(self):
        rows = {self.proxy.mapToSource(i).row() for i in self.view.selectionModel().selectedIndexes()}
        if rows:
            self.stack.push(RemoveRows(self.model, rows))
            self.update_status()

    def goto(self, r, c):
        i = self.proxy.mapFromSource(self.model.index(r, c))
        if not i.isValid():
            self.row_filter.clear()
            i = self.proxy.mapFromSource(self.model.index(r, c))
        self.view.setCurrentIndex(i)
        self.view.scrollTo(i)

    def blocked(self) -> bool:
        errors = core.check_cells(self.lt.columns, self.model.rows)
        if not errors:
            return False
        r, c, msg = errors[0]
        self.goto(r, c)
        QMessageBox.warning(self, "Không ghi", f"Dòng {r + 1}, cột {self.lt.columns[c]}: {msg}.\n({len(errors)} ô lỗi)")
        return True

    def _do_write(self, path, inplace):
        try:
            issues = core.write_inplace(self.lt, self.model.rows) if inplace else core.write(path, self.lt, self.model.rows)
        except (tf.TsvError, OSError) as exc:
            QMessageBox.critical(self, "Ghi lỗi", str(exc))
            return False
        if issues:
            QMessageBox.critical(self, "Đọc lại không khớp", "Tệp đọc lại khác mô hình, chưa coi là đã ghi:\n" + "\n".join(issues))
            return False
        return True

    def export(self, path=None):
        if not self.lt or not self.lt.can_export or self.blocked():
            return False
        if self.lt.stray and path is None:
            ok = QMessageBox.warning(
                self, "Dòng # sẽ mất",
                "Bản xuất sẽ không có các dòng # sau:\n" + "\n".join(self.lt.stray),
                QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
            if ok != QMessageBox.Ok:
                return False
        if path is None:
            path, _ = QFileDialog.getSaveFileName(self, "Xuất bảng schema 1", str(self.lt.path.with_name(self.lt.path.stem + "_xuat.tsv")), "TSV (*.tsv)")
            if not path:
                return False
        if Path(path).resolve() == self.lt.path.resolve():
            QMessageBox.warning(self, "Không xuất", "Đường xuất trùng tệp đang mở. Dùng Ghi trực tiếp.")
            return False
        if self._do_write(path, False):
            self.statusBar().showMessage(f"Đã xuất và đọc lại khớp: {path}", 8000)
            return True
        return False

    def save_inplace(self, confirm=True):
        if not self.lt or not self.lt.can_overwrite or self.blocked():
            return False
        if confirm and QMessageBox.question(
                self, "Ghi trực tiếp", f"Ghi đè tệp:\n{self.lt.path}\n(tool giữ nguyên: {self.lt.tool}, layout {self.lt.write_layout})",
                QMessageBox.Yes | QMessageBox.No, QMessageBox.No) != QMessageBox.Yes:
            return False
        if self._do_write(None, True):
            self.stack.setClean()
            self.statusBar().showMessage(f"Đã ghi và đọc lại khớp từng ô: {self.lt.path}", 8000)
            return True
        return False

    def closeEvent(self, event):
        if self.confirm_discard():
            event.accept()
        else:
            event.ignore()


def main():
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setPalette(app.style().standardPalette())
    w = Window()
    w.show()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
