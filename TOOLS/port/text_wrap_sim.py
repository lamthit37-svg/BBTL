# Mô phỏng phép đo và bẻ dòng của Font bản 2026 (CEGUIBase.dll) cho phông bitmap AXFT, để ra ví dụ
# số ở docs/GIAO-DIEN-2026.md mục 5. Theo mã máy: advance = u16 đầu bản ghi glyph, cộng 1 khi bằng cỡ phông
# (rasterise 0x18003bdda); mã không có bản ghi lấy cỡ phông (0x180133440) rồi cũng cộng 1;
# getTextExtent cộng advance (0x18004f848); drawWrappedText bẻ khi extent > bề rộng (0x18004d209),
# trang mã 936 bẻ theo ký tự, trang khác lùi tối đa 12 ký tự tìm ' ', ',', '.', '?', '!'.
# Chạy: python -B TOOLS/port/text_wrap_sim.py <tệp AXFT> <bề rộng> <936|1258> <chuỗi đã bỏ thẻ>
import struct
import sys

DELIMS = " ,.?!"
LOOK_BACK = 12


def load(path: str) -> tuple[int, dict[int, int]]:
    data = open(path, "rb").read()
    assert data[:4] == b"AXFT"
    size, ranges = struct.unpack_from("<II", data, 8)
    index_at = 0xA4 + 8 * ranges
    glyph_at = index_at + 0x40000
    advances = {}
    for code in range(0x10000):
        offset = struct.unpack_from("<I", data, index_at + 4 * code)[0]
        if offset != 0xFFFFFFFF:
            advances[code] = struct.unpack_from("<H", data, glyph_at + offset)[0]
    return size, advances


def advance(size: int, advances: dict[int, int], ch: str) -> int:
    value = advances.get(ord(ch), size)
    return value + 1 if value == size else value


def extent(size: int, advances: dict[int, int], text: str) -> int:
    return sum(advance(size, advances, ch) for ch in text)


def wrap(size: int, advances: dict[int, int], text: str, width: int, page: int) -> list[str]:
    lines = []
    line = ""
    c = 0
    while c < len(text):
        ch = text[c]
        if extent(size, advances, line + ch) > width:
            if page != 936 and ch not in DELIMS:
                back = min(len(line), LOOK_BACK)
                for k in range(back):
                    if line[len(line) - 1 - k] in DELIMS:
                        line = line[:len(line) - k - 1]
                        c -= k + 1
                        break
            lines.append(line)
            if len(line) > 1:
                c -= 1
            line = ""
        else:
            line += ch
        c += 1
    lines.append(line)
    return lines


def main() -> None:
    size, advances = load(sys.argv[1])
    width = int(sys.argv[2])
    page = int(sys.argv[3])
    text = sys.argv[4]
    print("cỡ", size, "số glyph", len(advances), "extent cả chuỗi", extent(size, advances, text))
    for number, line in enumerate(wrap(size, advances, text, width, page)):
        print(number, extent(size, advances, line), repr(line))


if __name__ == "__main__":
    main()
