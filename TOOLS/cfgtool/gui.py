"""Giao diện cfgtool: Qt6 (PySide6), kiểu Fusion sáng, không stylesheet riêng."""
from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import (QApplication, QFileDialog, QHeaderView, QLabel, QListWidget, QListWidgetItem,
                               QMainWindow, QMessageBox, QPlainTextEdit, QSplitter, QTableView, QTabWidget,
                               QTextBrowser, QVBoxLayout, QWidget)

import core

COLUMNS = [("group", "Nhóm"), ("key", "Khoá"), ("value", "Giá trị"), ("kind", "Kiểu"), ("range", "Miền hợp lệ"),
           ("required", "Bắt buộc"), ("default", "Mặc định"), ("unit", "Đơn vị"), ("desc", "Chức năng"),
           ("guide", "Cách đặt cho production"), ("prod", "Gợi ý production")]
VALUE_COLUMN = 2


class FieldModel(QAbstractTableModel):
    def __init__(self, window: "MainWindow"):
        super().__init__()
        self.window = window
        self.rows: list[dict] = []
        self.bad_lines: set[int] = set()

    def load(self, rows: list[dict], bad_lines: set[int]) -> None:
        self.beginResetModel()
        self.rows, self.bad_lines = rows, bad_lines
        self.endResetModel()

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self.rows)

    def columnCount(self, parent=QModelIndex()) -> int:
        return len(COLUMNS)

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if role == Qt.DisplayRole and orientation == Qt.Horizontal:
            return COLUMNS[section][1]
        return None

    def data(self, index, role=Qt.DisplayRole):
        row = self.rows[index.row()]
        key = COLUMNS[index.column()][0]
        if role in (Qt.DisplayRole, Qt.EditRole):
            value = row[key]
            if key == "value" and not value:
                return "(chưa đặt)" if role == Qt.DisplayRole else ""
            return value
        if role == Qt.ToolTipRole:
            return f"{row['desc']}\n\nProduction: {row['guide']}" if row["guide"] else row["desc"]
        if role == Qt.CheckStateRole:
            return None
        if role == Qt.ForegroundRole and key == "value" and row["line"] in self.bad_lines:
            return QApplication.palette().color(QApplication.palette().ColorRole.Highlight)
        return None

    def flags(self, index):
        base = Qt.ItemIsEnabled | Qt.ItemIsSelectable
        row = self.rows[index.row()]
        if index.column() == VALUE_COLUMN and not row["secret"]:
            base |= Qt.ItemIsEditable
        return base

    def setData(self, index, value, role=Qt.EditRole):
        if role != Qt.EditRole or index.column() != VALUE_COLUMN:
            return False
        row = self.rows[index.row()]
        return self.window.apply_edit(row, str(value).strip())


class MainWindow(QMainWindow):
    def __init__(self, folder: Path):
        super().__init__()
        self.setWindowTitle("Công cụ cấu hình máy chủ THIÊN LONG")
        self.resize(1400, 860)
        self.folder = folder
        self.paths: list[Path] = []
        self.current: Path | None = None
        self.text = ""
        self.original = b""

        self.files = QListWidget()
        self.files.currentRowChanged.connect(self.open_index)
        self.model = FieldModel(self)
        self.table = QTableView()
        self.table.setModel(self.model)
        self.table.setWordWrap(True)
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QTableView.SelectRows)
        self.table.verticalHeader().setVisible(False)
        header = self.table.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.Interactive)
        for column, width in enumerate((130, 170, 170, 150, 150, 80, 110, 80, 320, 320, 140)):
            self.table.setColumnWidth(column, width)
        self.table.selectionModel().currentRowChanged.connect(self.show_detail)

        self.issues = QListWidget()
        self.preview = QPlainTextEdit()
        self.preview.setReadOnly(True)
        self.preview.setLineWrapMode(QPlainTextEdit.NoWrap)
        self.detail = QTextBrowser()
        self.tabs = QTabWidget()
        self.tabs.addTab(self.issues, "Lỗi và việc đã làm")
        self.tabs.addTab(self.detail, "Chi tiết trường")
        self.tabs.addTab(self.preview, "Văn bản sẽ xuất (đúng byte)")

        left = QWidget()
        layout = QVBoxLayout(left)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(QLabel("Tệp cấu hình"))
        layout.addWidget(self.files)
        right = QSplitter(Qt.Vertical)
        right.addWidget(self.table)
        right.addWidget(self.tabs)
        right.setSizes([560, 260])
        split = QSplitter(Qt.Horizontal)
        split.addWidget(left)
        split.addWidget(right)
        split.setSizes([230, 1170])
        self.setCentralWidget(split)
        self.build_actions()
        self.load_folder(folder)

    # ------------------------------------------------------------ thao tác
    def build_actions(self) -> None:
        bar = self.addToolBar("Thao tác")
        bar.setMovable(False)
        menu = self.menuBar().addMenu("&Tệp")
        tools = self.menuBar().addMenu("&Kiểm tra")
        specs = [
            (menu, "Mở thư mục config…", QKeySequence.Open, self.choose_folder),
            (menu, "Nhập tệp…", QKeySequence("Ctrl+I"), self.import_file),
            (menu, "Lưu vào tệp gốc", QKeySequence.Save, self.save),
            (menu, "Xuất tệp…", QKeySequence("Ctrl+E"), self.export_file),
            (menu, "Xuất cả bộ cấu hình…", None, self.export_all),
            (tools, "Căn chỉnh", QKeySequence("Ctrl+L"), self.realign),
            (tools, "Kiểm tra cả thư mục", QKeySequence("F5"), self.check_all),
            (tools, "Kiểm bằng bộ đọc của máy chủ (thienlong_lint)", QKeySequence("F6"), self.server_check),
        ]
        for owner, title, shortcut, slot in specs:
            action = QAction(title, self)
            if shortcut:
                action.setShortcut(shortcut)
            action.triggered.connect(slot)
            owner.addAction(action)
            bar.addAction(action)
        quit_action = QAction("Thoát", self)
        quit_action.setShortcut(QKeySequence.Quit)
        quit_action.triggered.connect(self.close)
        menu.addSeparator()
        menu.addAction(quit_action)

    def load_folder(self, folder: Path) -> None:
        self.folder = folder
        self.paths = core.config_files(folder) if folder.is_dir() else []
        self.files.clear()
        for path in self.paths:
            QListWidgetItem(path.relative_to(folder).as_posix(), self.files)
        self.statusBar().showMessage(f"{folder} — {len(self.paths)} tệp (bỏ qua *.local.toml: tệp bí mật không bao giờ được mở)")
        if self.paths:
            self.files.setCurrentRow(0)

    def choose_folder(self) -> None:
        chosen = QFileDialog.getExistingDirectory(self, "Chọn thư mục config", str(self.folder))
        if chosen:
            self.load_folder(Path(chosen))

    def open_index(self, row: int) -> None:
        if 0 <= row < len(self.paths):
            self.open_path(self.paths[row])

    def open_path(self, path: Path, as_name: str | None = None) -> None:
        name = as_name or path.name
        try:
            core.guard(name)
            raw = path.read_bytes()
            text, notes = core.normalize(name, raw)
        except core.SecretFileError as error:
            QMessageBox.warning(self, "Từ chối", str(error))
            return
        except (ValueError, OSError) as error:
            QMessageBox.critical(self, "Không đọc được tệp", str(error))
            return
        self.current, self.original, self.text = path, raw, text
        self.current_name = name
        self.refresh(notes)

    def refresh(self, notes: list[str] | None = None) -> None:
        issues = core.validate(self.current_name, self.text)
        if self.current and self.current.parent == self.folder and self.current_name == "supervisor.toml":
            issues += core.check_startup(self.folder)
        self.model.load(core.describe(self.current_name, self.text), {i.line for i in issues})
        self.table.resizeRowsToContents()
        self.issues.clear()
        for note in notes or []:
            QListWidgetItem(f"Đã làm: {note}", self.issues)
        for issue in issues:
            QListWidgetItem(f"Lỗi {issue.text()}", self.issues)
        if not issues:
            QListWidgetItem("Sạch: tệp đúng lược đồ của bộ đọc máy chủ.", self.issues)
        self.preview.setPlainText(self.text)
        same = self.text.encode("utf-8") == self.original
        self.statusBar().showMessage(f"{self.current} — {len(issues)} lỗi — "
                                     + ("không đổi so với tệp gốc" if same else "đã đổi, chưa lưu"))

    def apply_edit(self, row: dict, value: str) -> bool:
        try:
            self.text = core.set_value(self.current_name, self.text, row["path"], row["row"], row["key"], value)
        except ValueError as error:
            QMessageBox.warning(self, "Giá trị không hợp lệ", f"{error}\n\nChuỗi phải đặt trong dấu nháy kép, ví dụ \"info\".")
            return False
        self.refresh(["sửa " + row["key"]])
        return True

    def show_detail(self, current, _previous=None) -> None:
        if not current.isValid():
            return
        r = self.model.rows[current.row()]
        value = r["value"] or "(chưa đặt)"
        self.detail.setHtml(
            f"<h3>{r['group']} → {r['key']}</h3><p><b>Giá trị hiện tại:</b> <code>{value}</code></p>"
            f"<p><b>Chức năng:</b> {r['desc']}</p><p><b>Kiểu:</b> {r['kind']} &nbsp; <b>Miền:</b> {r['range'] or '—'}"
            f" &nbsp; <b>{r['required']}</b> &nbsp; <b>Mặc định:</b> {r['default'] or '—'}"
            f" &nbsp; <b>Đơn vị:</b> {r['unit'] or '—'}</p><p><b>Cách đặt cho production:</b> {r['guide'] or '—'}</p>"
            f"<p><b>Gợi ý:</b> <code>{r['prod'] or '—'}</code></p>")
        self.tabs.setCurrentWidget(self.detail)

    def realign(self) -> None:
        if self.current:
            self.text, notes = core.normalize(self.current_name, self.text)
            self.refresh(notes or ["tệp đã thẳng cột"])

    def import_file(self) -> None:
        chosen, _ = QFileDialog.getOpenFileName(self, "Nhập tệp cấu hình", str(self.folder), "TOML (*.toml);;Mọi tệp (*)")
        if not chosen:
            return
        path = Path(chosen)
        names = [p.name for p in self.paths] or [path.name]
        name = path.name if path.name in names or path.name.endswith(".toml") else names[0]
        self.open_path(path, name)

    def confirm_write(self, path: Path) -> bool:
        issues = core.validate(path.name, self.text)
        if not issues:
            return True
        answer = QMessageBox.question(self, "Còn lỗi", f"Tệp còn {len(issues)} lỗi; máy chủ sẽ từ chối khởi động. Vẫn ghi?")
        return answer == QMessageBox.Yes

    def save(self) -> None:
        if self.current and self.confirm_write(self.current):
            self.original = core.write_export(self.current, self.text)
            self.refresh(["đã lưu " + str(self.current)])

    def export_file(self) -> None:
        if not self.current:
            return
        chosen, _ = QFileDialog.getSaveFileName(self, "Xuất tệp", str(self.folder / self.current_name), "TOML (*.toml)")
        if chosen and self.confirm_write(Path(chosen)):
            try:
                core.write_export(Path(chosen), self.text)
            except core.SecretFileError as error:
                QMessageBox.warning(self, "Từ chối", str(error))
                return
            self.refresh([f"đã xuất {chosen}"])

    def export_all(self) -> None:
        chosen = QFileDialog.getExistingDirectory(self, "Chọn thư mục đích để xuất cả bộ")
        if not chosen:
            return
        count = 0
        for path in self.paths:
            text, _ = core.normalize(path.name, path.read_bytes())
            core.write_export(Path(chosen) / path.relative_to(self.folder), text)
            count += 1
        QMessageBox.information(self, "Đã xuất", f"Đã xuất {count} tệp vào {chosen}. Tệp *.local.toml không được xuất.")

    def check_all(self) -> None:
        self.issues.clear()
        total = 0
        for path in self.paths:
            for issue in core.validate(path.name, path.read_text(encoding="utf-8")):
                QListWidgetItem(f"{path.relative_to(self.folder).as_posix()}: {issue.text()}", self.issues)
                total += 1
        for issue in core.check_startup(self.folder):
            QListWidgetItem(f"supervisor.toml: {issue.text()}", self.issues)
            total += 1
        QListWidgetItem(f"Kiểm {len(self.paths)} tệp: {total} lỗi.", self.issues)
        self.tabs.setCurrentWidget(self.issues)

    def server_check(self) -> None:
        import tempfile
        import cfgtool
        lint = self.folder.parent / "bin" / "thienlong_lint.exe"
        if not lint.is_file():
            QMessageBox.warning(self, "Thiếu thienlong_lint", f"Không thấy {lint}")
            return
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "config"
            for path in self.paths:
                text = self.text if path == self.current else core.normalize(path.name, path.read_bytes())[0]
                core.write_export(out / path.relative_to(self.folder), text)
            code, report = cfgtool.run_lint(lint, out)
        self.issues.clear()
        QListWidgetItem(f"thienlong_lint (bộ đọc của máy chủ) trên bản sẽ xuất: mã thoát {code}"
                        + (" — ĐẠT" if code == 0 else " — CÓ LỖI"), self.issues)
        for line in report.strip().splitlines():
            QListWidgetItem(line, self.issues)
        self.tabs.setCurrentWidget(self.issues)


def run(folder: Path) -> int:
    app = QApplication.instance() or QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setPalette(app.style().standardPalette())
    window = MainWindow(folder)
    window.show()
    return app.exec()
