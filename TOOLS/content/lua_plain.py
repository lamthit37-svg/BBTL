# Giải script Lua của client 2026 (Interface/**/*.lua trong kho gốc đã giải gói) ra văn bản đọc
# được, để port hành vi của từng cửa sổ theo đúng bản 2026 thay vì theo script của bản cũ.
# Định dạng và phép giải ở script_crypt.py (đo từ Game.exe, kiểm CRC đầu tệp và biên dịch bằng LuaPlus.dll của client):
# dấu hiệu 8 byte, đầu 0x100 byte, 24 byte đầu của văn bản là một khối Rijndael 192 bit, phần còn lại XOR "AS".
# Trước 2026-10-15 công cụ này thay 24 byte đầu bằng một dòng chú thích (khi đó chưa giải được); byte ấy là mã thật
# (ví dụ QuestLog.lua mở đầu bằng "local bBeingRadio = 0;"), nên script đưa cho trọng tài thiếu một dòng khai báo.
# Tệp không mang dấu hiệu (script chưa mã hoá) được chép nguyên, chỉ đổi bảng mã.
# Muốn script nguyên byte (GBK, CRLF) thẳng từ gói .axp của client thì dùng unpack_scripts.py.
# Chạy ở gốc dự án:
#   python TOOLS/content/lua_plain.py <_raw> <thư mục đích> [Tên cửa sổ]...
# Không nêu tên thì giải mọi Interface/**/*.lua. Đích nên là build/lua-2026 (không vào git: đây là
# script gốc của game, chỉ để đọc khi port). Tệp ra là UTF-8, xuống dòng giữ như gốc.
import argparse
import pathlib
import sys

import script_charset
import script_crypt


def plain_of(data: bytes) -> tuple[str, bool]:
    """Văn bản UTF-8 của một tệp .lua (đổi từng dòng, script_charset.py) và cờ "tệp đã mã hoá"."""
    return script_charset.to_utf8(script_crypt.decode(data)).decode("utf-8"), script_crypt.is_encoded(data)


def sources_of(raw: pathlib.Path, names: list[str]) -> list[pathlib.Path]:
    root = raw / "Interface"
    if not names:
        return sorted(root.rglob("*.lua"))
    return [root / name / f"{name}.lua" for name in names]


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Giải script Lua của client 2026 ra văn bản")
    parser.add_argument("raw", help="kho gốc đã giải gói (_raw)")
    parser.add_argument("out", help="thư mục nhận script đã giải, ví dụ build/lua-2026")
    parser.add_argument("names", nargs="*", help="tên cửa sổ; bỏ trống là mọi script")
    chosen = parser.parse_args()
    raw = pathlib.Path(chosen.raw)
    out = pathlib.Path(chosen.out)
    missing = decoded = copied = 0
    for source in sources_of(raw, chosen.names):
        if not source.is_file():
            print(f"không có {source}")
            missing += 1
            continue
        text, was_veiled = plain_of(source.read_bytes())
        target = out / source.relative_to(raw)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(text.encode("utf-8"))
        decoded += was_veiled
        copied += not was_veiled
    print(f"đã giải {decoded} tệp, chép {copied} tệp chưa mã hoá, thiếu {missing}; đích {out}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
