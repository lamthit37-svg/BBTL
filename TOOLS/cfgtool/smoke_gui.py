"""Chạy thử giao diện không màn hình: QT_QPA_PLATFORM=offscreen python TOOLS/cfgtool/smoke_gui.py <ảnh.png>"""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from PySide6.QtWidgets import QApplication  # noqa: E402

import gui  # noqa: E402

app = QApplication(sys.argv)
app.setStyle("Fusion")
app.setPalette(app.style().standardPalette())
folder = Path(__file__).resolve().parents[2] / "dev" / "server" / "config"
window = gui.MainWindow(folder)
window.show()
names = [p.name for p in window.paths]
window.files.setCurrentRow(names.index("gate.toml"))
row = next(i for i, r in enumerate(window.model.rows) if r["key"] == "max_connections")
ok = window.model.setData(window.model.index(row, gui.VALUE_COLUMN), "50000")
assert ok and "max_connections      = 50000" in window.text
window.model.setData(window.model.index(row, gui.VALUE_COLUMN), "2000")
assert window.text.encode("utf-8") == window.original, "sửa rồi trả lại phải về đúng byte gốc"
window.files.setCurrentRow(names.index("secrets.example.toml"))
assert all(not r["value"] or r["value"] in ('""', "••••••") for r in window.model.rows if r["secret"])
window.files.setCurrentRow(names.index("gate.toml"))
window.table.selectRow(row)
window.show_detail(window.model.index(row, 0))
window.server_check()
items = [window.issues.item(i).text() for i in range(window.issues.count())]
print(items[0])
assert "ĐẠT" in items[0]
app.processEvents()
window.grab().save(sys.argv[1] if len(sys.argv) > 1 else str(Path(tempfile.gettempdir()) / "cfgtool.png"))
print("giao diện chạy thử: ĐẠT")
