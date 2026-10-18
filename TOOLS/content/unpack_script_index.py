# Tách bảng id script sang tệp (Script.dat) của client 2026 ra khỏi gói Data/Config.axp, ghi byte nguyên (thuần ASCII,
# CRLF của gốc) vào <đích>/Config/Script.dat. Bộ nạp của Game.exe là 0x1406865b0 (xem src/client/book/quest/defs.hpp):
# dòng "MGR_TXT", rồi từng dòng "id=\đường\dẫn.lua"; quest::DefBook tra id nhiệm vụ ra tệp event/*.lua qua bảng này.
# Tệp không phải ASCII hay thiếu dòng MGR_TXT thì dừng với mã 1: bảng hỏng là lỗi dữ liệu, không đoán.
# Chạy ở gốc dự án:
#   py -X utf8 TOOLS/content/unpack_script_index.py <thư mục Data của client> src/client/script
import argparse
import hashlib
import sys
from pathlib import Path

import cryptbox
import script_crypt
from axp_pack import Axp

PACK = "Config.axp"
ENTRY = b"Script.dat"
HEADER = b"MGR_TXT"


def read_index(data_dir: Path) -> bytes:
    with Axp(data_dir / PACK) as pack:
        if ENTRY not in pack.names():
            raise ValueError(f"{PACK} không có {ENTRY.decode()}")
        stored = pack.read(ENTRY)
    inner = cryptbox.unwrap(stored) if cryptbox.is_wrapped(stored) else stored
    text = script_crypt.decode(inner)
    if not text.isascii():
        raise ValueError("Script.dat có byte ngoài ASCII; cần bộ đổi mã trước khi nhận")
    if not text.startswith(HEADER):
        raise ValueError("Script.dat không bắt đầu bằng dòng MGR_TXT")
    return text


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Tách Script.dat của client 2026 ra khỏi Config.axp")
    parser.add_argument("data", type=Path, help="thư mục Data của client (có Config.axp)")
    parser.add_argument("out", type=Path, help="thư mục đích, ví dụ src/client/script")
    chosen = parser.parse_args()
    try:
        text = read_index(chosen.data)
    except (OSError, ValueError) as error:
        print(f"LỖI {error}", file=sys.stderr)
        return 1
    target = chosen.out / "Config" / "Script.dat"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(text)
    rows = sum(1 for line in text.split(b"\n") if b"=" in line)
    print(f"{target}: {len(text):,} byte, {rows} dòng id=đường dẫn, sha256 {hashlib.sha256(text).hexdigest()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
