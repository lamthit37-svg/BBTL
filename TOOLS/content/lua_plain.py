# Giải script Lua của client 2026 (Interface/**/*.lua trong kho gốc đã giải gói) ra văn bản đọc
# được, để port hành vi của từng cửa sổ theo đúng bản 2026 thay vì theo script của bản cũ.
# Định dạng đã đo ngày 2026-10-08 trên 5 tệp (SelfEquip, Packet, QuestLog, PartyFrame, MainMenuBar):
# - 8 byte dấu hiệu D2 D1 E2 E1 B2 B1 C2 C1, rồi ba số u32 little-endian 1, 2, 16;
# - 236 byte bảng số (chưa rõ nghĩa), tới hết byte 0xFF;
# - từ byte 0x100 là văn bản GBK của script, mỗi byte XOR với khoá hai byte "AS" tính theo vị trí
#   trong tệp (vị trí chẵn 'A', lẻ 'S'). Bằng chứng: đoạn giải ra của SelfEquip.lua trùng từng byte
#   với đầu SelfEquip.lua đọc được của bản cũ từ byte thứ 24 trở đi.
# - 24 byte đầu của văn bản còn một lớp khoá nữa, khác nhau theo tệp, CHƯA giải được (đã thử TEA và
#   XTEA với khoá lấy từ bảng số: không trúng). Công cụ thay 24 byte đó bằng một dòng chú thích Lua.
# Tệp không mang dấu hiệu (script chưa mã hoá) được chép nguyên, chỉ đổi bảng mã.
# Chạy ở gốc dự án:
#   python TOOLS/content/lua_plain.py <_raw> <thư mục đích> [Tên cửa sổ]...
# Không nêu tên thì giải mọi Interface/**/*.lua. Đích nên là build/lua-2026 (không vào git: đây là
# script gốc của game, chỉ để đọc khi port). Tệp ra là UTF-8, xuống dòng giữ như gốc.
import argparse
import pathlib
import sys

MAGIC = bytes.fromhex("d2d1e2e1b2b1c2c1")
TEXT_AT = 0x100
VEILED_BYTES = 24
KEY = b"AS"
VEILED_NOTE = "--[[ 24 byte đầu của script chưa giải được ]]"


def plain_of(data: bytes) -> tuple[str, bool]:
    """Văn bản của một tệp .lua và cờ "tệp đã mã hoá"; byte không phải GBK thành dấu thay thế."""
    if not data.startswith(MAGIC):
        return data.decode("gbk", errors="replace"), False
    body = bytes(byte ^ KEY[index % 2] for index, byte in enumerate(data))[TEXT_AT:]
    return VEILED_NOTE + body[VEILED_BYTES:].decode("gbk", errors="replace"), True


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
