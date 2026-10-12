# Đo chữ của giao diện có vừa ô không: với mỗi cửa sổ có thuộc tính Text trong các layout đã gom,
# lấy chữ client sẽ hiện (bản dịch tiếng Việt nếu có, không thì chữ gốc), đo bề rộng bằng độ tiến
# của phông bitmap client đang vẽ (Schema/VTNAM14.bin, định dạng AXFT như SRC/ui/pace.cpp đọc) rồi
# so với bề rộng ô ở 1280x720 trong tests/golden/ui_rects.tsv. Layout gốc vẽ ô cho hai chữ Hán nên
# chữ Việt dễ tràn; nhãn của nút phải ngắn kiểu "Thú", "Thể Lực", "Đóng/Mở" (chủ dự án chốt ngày
# 2026-10-08).
# Chạy ở gốc dự án:
#   python TOOLS/content/ui_text_fit.py CLIENT/data tests/golden/ui_rects.tsv [--all]
# In các nút có chữ rộng hơn ô; --all in thêm cửa sổ loại khác. Mã thoát 1 khi còn nút tràn.
# Giới hạn: so với cả ô của cửa sổ, chưa trừ lề của vùng chữ trong look; chữ nhiều dòng (#r) lấy
# dòng dài nhất; ký tự phông không có tính bằng cỡ phông.
import argparse
import pathlib
import re
import struct
import sys
import xml.etree.ElementTree as ET

FONT_FILE = "Interface/Schema/VTNAM14.bin"
AXFT_MAGIC = 0x54465841
AXFT_HEADER_BYTES = 0xA4
AXFT_INDEX_ENTRIES = 65536
AXFT_NO_GLYPH = 0xFFFFFFFF
SCREEN_WIDTH = "1280"
TAG = re.compile(r"#[ceg][0-9A-Fa-f]{6}|#[A-Za-qs-zA-Z]")
KEY = re.compile(r"#\{([^}]*)\}")
DECLARATION = re.compile(r"\A<\?xml[^?]*\?>")


class Font:
    """Cỡ điểm ảnh và độ tiến của từng mã ký tự trong một tệp AXFT."""

    def __init__(self, data: bytes) -> None:
        header = struct.unpack_from("<8I", data, 0)
        magic, _, self.pixel_size, range_count, _, _, glyphs_at, _ = header
        if magic != AXFT_MAGIC:
            raise ValueError("tệp phông không phải AXFT")
        index_at = AXFT_HEADER_BYTES + 8 * range_count
        offsets = struct.unpack_from(f"<{AXFT_INDEX_ENTRIES}I", data, index_at)
        self.advances: dict[int, int] = {}
        for code, offset in enumerate(offsets):
            if offset != AXFT_NO_GLYPH:
                self.advances[code] = struct.unpack_from("<H", data, glyphs_at + offset)[0]

    def width_of(self, text: str) -> int:
        return sum(self.advances.get(ord(letter), self.pixel_size) for letter in text)


def table_of(path: pathlib.Path) -> dict[str, str]:
    rows: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or "\t" not in line:
            continue
        key, text = line.split("\t", 1)
        rows[key] = text
    return rows


class Words:
    """Chữ client hiện cho một giá trị Text: bảng dịch đè lên bảng chuỗi gốc."""

    def __init__(self, data: pathlib.Path) -> None:
        self.source = table_of(data / "Table" / "ui_strings.tsv")
        self.vietnamese = table_of(data / "Table" / "ui_strings.lang.tsv")

    def lookup(self, key: str) -> str:
        return self.vietnamese.get(key, self.source.get(key, ""))

    def shown(self, value: str) -> str:
        literal = self.vietnamese.get("=" + value)
        if literal is not None:
            return literal
        return KEY.sub(lambda match: self.lookup(match.group(1)), value)


def widest_line(font: Font, text: str) -> tuple[int, str]:
    lines = [TAG.sub("", line) for line in text.split("#r")]
    return max((font.width_of(line), line) for line in lines)


def boxes_of(golden: pathlib.Path) -> dict[tuple[str, str], float]:
    boxes: dict[tuple[str, str], float] = {}
    for line in golden.read_text(encoding="utf-8").splitlines():
        cells = line.split("\t")
        if len(cells) == 9 and cells[0] == SCREEN_WIDTH:
            boxes[(cells[2], cells[3])] = float(cells[6])
    return boxes


def text_of(window: ET.Element) -> str | None:
    values = [item.get("Value", "") for item in window.findall("Property")
              if item.get("Name") == "Text"]
    return values[-1] if values else None


def overflows(data: pathlib.Path, golden: pathlib.Path) -> list[tuple]:
    """Mỗi cửa sổ có chữ rộng hơn ô: (là nút, layout, cửa sổ, kiểu, rộng ô, rộng chữ, chữ)."""
    font = Font((data / FONT_FILE).read_bytes())
    words = Words(data)
    boxes = boxes_of(golden)
    root = data / "Interface"
    found = []
    for path in sorted(root.rglob("*.layout.xml")):
        layout = path.relative_to(root).as_posix()
        tree = ET.fromstring(DECLARATION.sub("", path.read_text(encoding="utf-8")))
        for window in tree.iter("Window"):
            value = text_of(window)
            box = boxes.get((layout, window.get("Name", "")))
            kind = window.get("Type", "")
            # Layout gốc có nút để tên kiểu làm Text (QuestLog_Close: "TLBB_ButtonClose"); look của
            # các nút đó không vẽ chữ.
            if not value or box is None or value == kind:
                continue
            width, line = widest_line(font, words.shown(value))
            if width > box:
                found.append(("Button" in kind, layout, window.get("Name"), kind, box, width, line))
    return found


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Đo chữ giao diện có vừa ô không")
    parser.add_argument("data", help="thư mục dữ liệu client đã gom (CLIENT/data)")
    parser.add_argument("golden", help="tests/golden/ui_rects.tsv")
    parser.add_argument("--all", action="store_true", help="in cả cửa sổ không phải nút")
    chosen = parser.parse_args()
    found = overflows(pathlib.Path(chosen.data), pathlib.Path(chosen.golden))
    buttons = [row for row in found if row[0]]
    for is_button, layout, name, kind, box, width, line in found:
        if is_button or chosen.all:
            print(f"{layout}\t{name}\t{kind}\tô {box:.0f}\tchữ {width}\t{line}")
    print(f"chữ rộng hơn ô: {len(buttons)} nút, {len(found) - len(buttons)} cửa sổ loại khác")
    return 1 if buttons else 0


if __name__ == "__main__":
    sys.exit(main())
