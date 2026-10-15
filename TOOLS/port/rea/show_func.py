# In thân hàm decompile của Game.exe 2026 theo địa chỉ, từ docs/TAILIEU/GAME-EXE-2026/decompile.zip.
# Dùng:  python -X utf8 -I TOOLS/port/rea/show_func.py 0x1402e7d70 [0x... ...] [--str 0x140b49460 ...]
# - Mỗi địa chỉ hàm in khối "// ==== 0x<địa chỉ> ..." của nó (tới khối kế).
# - --str: tra chuỗi/dữ liệu ở địa chỉ trong strings.tsv (cột address), vì pseudo-code chỉ ghi &DAT_<địa chỉ>.
# - --raw <địa chỉ> [số byte]: đọc byte thô ở địa chỉ ảo từ tệp exe (--exe, mặc định bản xuất lại ở
#   D:/rea/work/client/Game.exe) và in chuỗi C kết thúc bằng 0 giải GBK; Ghidra hầu như không giải chuỗi Hán.
# Tệp .c trong zip đặt tên theo khoảng địa chỉ nên chọn tệp bằng so số, không quét cả zip.
import argparse
import bisect
import pathlib
import re
import struct
import sys
import zipfile

DUMP = pathlib.Path(__file__).resolve().parents[3] / "docs" / "TAILIEU" / "GAME-EXE-2026"
RANGE = re.compile(r"decompile/([0-9a-f]+)-([0-9a-f]+)\.c$")
SECTION_HEADER = 40


def parse_address(text: str) -> int:
    return int(text.lower().removeprefix("0x"), 16)


def function_text(archive: zipfile.ZipFile, address: int) -> str | None:
    """Khối decompile của hàm bắt đầu đúng tại address; None khi không có."""
    for name in archive.namelist():
        match = RANGE.match(name)
        if match and int(match.group(1), 16) <= address <= int(match.group(2), 16):
            text = archive.read(name).decode("utf-8", errors="replace")
            head = f"// ==== 0x{address:x} "
            start = text.find(head)
            if start < 0:
                return None
            stop = text.find("\n// ==== 0x", start + len(head))
            return text[start : stop if stop >= 0 else len(text)].rstrip() + "\n"
    return None


def show_strings(addresses: list[int]) -> None:
    rows: list[tuple[int, str]] = []
    with (DUMP / "strings.tsv").open(encoding="utf-8") as file:
        header = file.readline().rstrip("\n").split("\t")
        column = header.index("address")
        for line in file:
            cells = line.rstrip("\n").split("\t")
            if len(cells) > column and cells[column].lower().startswith("0x"):
                rows.append((parse_address(cells[column]), line.rstrip("\n")))
    rows.sort()
    keys = [row[0] for row in rows]
    for address in addresses:
        index = bisect.bisect_right(keys, address) - 1
        near = rows[index] if index >= 0 else None
        found = near is not None and near[0] == address
        print(f"0x{address:x}: {near[1] if found and near else 'không có chuỗi bắt đầu đúng đó'}")


def read_virtual(exe: pathlib.Path, address: int, size: int) -> bytes:
    """size byte ở địa chỉ ảo address của một PE64, đọc theo bảng đoạn (không cần pefile)."""
    data = exe.read_bytes()
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    section_count = struct.unpack_from("<H", data, pe + 6)[0]
    optional_size = struct.unpack_from("<H", data, pe + 20)[0]
    base = struct.unpack_from("<Q", data, pe + 24 + 24)[0]
    table = pe + 24 + optional_size
    for index in range(section_count):
        virtual_size, virtual, raw_size, raw = struct.unpack_from("<IIII", data, table + index * SECTION_HEADER + 8)
        start = base + virtual
        if start <= address < start + max(virtual_size, raw_size):
            offset = raw + (address - start)
            return data[offset : offset + size]
    return b""


def show_raw(exe: pathlib.Path, spec: list[str]) -> None:
    address = parse_address(spec[0])
    size = int(spec[1]) if len(spec) > 1 else 64
    chunk = read_virtual(exe, address, size)
    text = chunk.split(b"\0", 1)[0].decode("gbk", errors="replace")
    print(f"0x{address:x}: {chunk.hex(' ')}\n  chuỗi: {text!r}")


def main() -> int:
    parser = argparse.ArgumentParser(description="In thân hàm decompile của Game.exe 2026.")
    parser.add_argument("addresses", nargs="*", help="địa chỉ hàm, dạng 0x1402e7d70")
    parser.add_argument("--str", nargs="*", default=[], help="địa chỉ dữ liệu cần tra chuỗi")
    parser.add_argument("--raw", nargs="+", default=[], help="địa chỉ [số byte]: byte thô và chuỗi GBK ở đó")
    parser.add_argument("--exe", type=pathlib.Path, default=pathlib.Path("D:/rea/work/client/Game.exe"))
    args = parser.parse_args()
    failed = False
    if args.addresses:
        with zipfile.ZipFile(DUMP / "decompile.zip") as archive:
            for given in args.addresses:
                text = function_text(archive, parse_address(given))
                if text is None:
                    print(f"{given}: không có khối hàm bắt đầu đúng địa chỉ này", file=sys.stderr)
                    failed = True
                else:
                    print(text)
    if args.str:
        show_strings([parse_address(item) for item in args.str])
    if args.raw:
        show_raw(args.exe, args.raw)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
