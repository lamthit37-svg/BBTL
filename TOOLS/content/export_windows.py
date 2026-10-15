# Xuất sổ cửa sổ giao diện (Config/InterfaceEx.txt) của đúng bản client mà src/client/script tách ra, thành
# src/client/script/windows.tsv cạnh các script. Phần chủ của giao diện Lua (ui/script) nạp cửa sổ theo sổ này như
# CUIWindowMng::Init của client gốc: mỗi dòng một cửa sổ, một layout, một script dưới Interface/.
# Đọc thẳng gói Data/Config.axp (tệp bọc CryptBox, gỡ bằng cryptbox.py), không qua cây _raw: script và sổ phải cùng
# một bản (bản _goc ở F:\tl 2026 có 1 978 dòng, bản 3.71.9509 có 1 975).
# Cách ghi và kiểm từng ô dùng chung với export_config.py: số nguyên in thập phân, chuỗi GBK đổi UTF-8 và phải đổi
# ngược ra đúng byte gốc; sau khi ghi, đọc lại và so từng ô với bảng gốc. Cột 3 (script) phải trỏ tới một tệp có thật
# trong <script>/Interface (tra không phân biệt hoa thường như client gốc); thiếu là lỗi.
# Chạy ở gốc dự án:
#   python -B TOOLS/content/export_windows.py <thư mục Data của client> src/client/script            ghi rồi kiểm
#   python -B TOOLS/content/export_windows.py <thư mục Data của client> src/client/script --check    chỉ kiểm
# Mã thoát: 0 khi khớp, 1 khi bảng hỏng hay lệch, 2 khi sai cách dùng.
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

import cryptbox
import dbc
import export_config
from axp_pack import Axp, AxpError

PACK = "Config.axp"
SOURCE = "InterfaceEx.txt"
NOTE = "Sinh bằng TOOLS/content/export_windows.py từ Config.axp của client 2026; sửa tay sẽ mất ở lượt sau"
# Số, tên, layout, script, demise, mã nhóm, âm thanh mở, âm thanh đóng, cờ, ghi chú (TANG-C.md mục 1.1).
TYPES = [dbc.INT, dbc.STRING, dbc.STRING, dbc.STRING, dbc.INT, dbc.STRING, dbc.INT, dbc.INT, dbc.INT, dbc.STRING]
SCRIPT_COLUMN = 3
SPEC = export_config.Spec(
    source=SOURCE,
    target="windows.tsv",
    names={0: "id", 1: "name", 2: "layout", 3: "script", 4: "demise", 5: "group", 6: "open_sound", 7: "close_sound",
           8: "flag", 9: "note"},
)


class PackSource(export_config.Source):
    """Bảng Config lấy từ gói Config.axp thay cho thư mục Config đã giải."""

    def __init__(self, data_root: Path) -> None:
        super().__init__(data_root)
        self.pack = data_root / PACK
        self.note = NOTE

    def load(self, name: str) -> export_config.Loaded:
        if name in self.cache:
            return self.cache[name]
        try:
            with Axp(self.pack) as pack:
                stored = pack.read(name.encode("ascii"))
            body = cryptbox.unwrap(stored) if cryptbox.is_wrapped(stored) else stored
            table = dbc.parse(body, name)
        except (OSError, AxpError, ValueError) as error:
            raise export_config.ExportError(f"{name}: không đọc được trong {self.pack}: {error}") from error
        loaded = export_config.Loaded(table=table, digest=hashlib.sha256(body).hexdigest())
        self.cache[name] = loaded
        return loaded


def check_scripts(source: PackSource, script_root: Path) -> int:
    """Mỗi dòng phải nêu một script có trong <script_root>/Interface; trả số dòng đã kiểm."""
    table = source.load(SOURCE).table
    if table.types != TYPES:
        raise export_config.ExportError(f"{SOURCE}: kiểu cột lạ {table.types}, cần {TYPES}")
    folder = script_root / "Interface"
    present = {path.relative_to(folder).as_posix().lower() for path in folder.rglob("*.lua")}
    missing = []
    names = set()
    for row in range(table.rows):
        name = table.text(row, 1)
        if name in names:
            raise export_config.ExportError(f"{SOURCE}: dòng {row} lặp tên cửa sổ {name}")
        names.add(name)
        script = table.text(row, SCRIPT_COLUMN).replace("\\", "/")
        if script.lower() not in present:
            missing.append(f"{name} -> {script}")
    if missing:
        raise export_config.ExportError(f"{SOURCE}: {len(missing)} cửa sổ nêu script không có, đầu tiên: {missing[0]}")
    return table.rows


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Xuất sổ cửa sổ InterfaceEx thành windows.tsv cạnh script giao diện.")
    parser.add_argument("data", type=Path, help="thư mục Data của client (có Config.axp)")
    parser.add_argument("script", type=Path, help="thư mục script đã tách (src/client/script)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm tệp đang có, không ghi")
    args = parser.parse_args(argv)
    source = PackSource(args.data)
    try:
        rows = check_scripts(source, args.script)
        print(export_config.export_one(source, SPEC, args.script, args.check))
    except export_config.ExportError as error:
        print(f"LỖI {error}", file=sys.stderr)
        return 1
    print(f"{rows} cửa sổ, mỗi cửa sổ một script có trong {args.script / 'Interface'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
