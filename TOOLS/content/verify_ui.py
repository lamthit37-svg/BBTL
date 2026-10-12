# Kiểm chứng ĐỘC LẬP giao diện đã gom (CLIENT/data) với kho gốc (_raw) để bắt lỗi của collect_ui.py.
# Chỉ đọc. Không import collect_ui.py, ui_font.py, glb/texture.py: tự dò bảng mã XML, tự giải mã DDS
# (BC1/BC2/BC3, không nén theo mặt nạ) và TGA; Pillow chỉ mở JPG/PNG; dbc.py chỉ đọc vỏ DBC.
# Mục: 1 tệp có nguồn, 2 cây XML giống hệt, 3 điểm ảnh texture, 4 bao đóng kiểu -> look -> ảnh -> bộ
# ảnh -> texture, 4b cạnh ngoài chuỗi đó (hoạt ảnh, phông, ảnh trực tiếp, kiểu nạp động), 5 danh
# sách và bảng, 6 (--all-raw) số liệu cả kho gốc, không PASS/FAIL.
# Quyết định:
# - Tham chiếu hỏng so với kho gốc: hỏng cả ở gốc là ghi chú, chỉ "mất do gom" mới là lỗi.
# - Khớp tên không phân biệt hoa/thường khi cần; các ca đó được đếm riêng.
# - Texture không nén và TGA khớp tuyệt đối; BCn cho lệch tối đa 2 mỗi kênh (làm tròn nội suy).
# - Phông và fonts.tsv do ui_font.py sinh không có nguồn cùng tên: tính lại từ nguồn rồi so byte.
# - Bộ giải mã tự kiểm bằng ca tổng hợp và đối chiếu Pillow trước khi tin kết quả mục 3.
# - Atlas mà build_i18n.py đã thay ảnh theo ngôn ngữ của bản dựng không còn khớp kho gốc. Có --i18n
#   (thư mục trạng thái của nó) thì mục 3 so bản gốc giữ ở đó với kho gốc, và đòi bản triển khai
#   đúng băm sổ đã ghi; không có --i18n thì các atlas ấy báo lệch điểm ảnh.
# Cách dùng: python verify_ui.py --raw <_raw> --data <CLIENT/data> [--i18n build/i18n] [--all-raw]
#   [--report <tệp.tsv>]
# Mã thoát: 0 mọi mục qua, 1 có mục FAIL hay không chạy được, 2 sai tham số.

import argparse
import codecs
import functools
import io
import os
import re
import struct
import sys
import time
import traceback
import xml.etree.ElementTree as ElementTree
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

# Chỉ để đọc sổ băm của các atlas đã thay ảnh; không dùng lại mã dán ảnh.
import build_i18n
# Chỉ để đọc vỏ DBC (đầu tệp, kiểu cột, ô thô, khối chuỗi); không dùng lại mã gom.
import dbc

Element = ElementTree.Element

INTERFACE = "Interface"
SCHEMA = "Schema"
LISTING = "ui.files.tsv"
WINDOWS_TABLE = "Table/ui_windows.tsv"
STRINGS_TABLE = "Table/ui_strings.tsv"
# Chữ của ngôn ngữ bản dựng: build_i18n.py dựng từ assets/i18n/<mã>.tsv, không do bộ gom ghi.
VIETNAMESE_TABLE = "Table/ui_strings.lang.tsv"
PORTRAITS_TABLE = "Table/portraits.tsv"
# Bảng hoạt ảnh của bản gom là bản lọc của tệp gốc (chỉ hoạt ảnh trong bao đóng).
ANIMATE_FILE = "Schema/wowanimate.xml"
SCENE_NAMES_TABLE = "Table/scene_names.lang.tsv"
HEAD_CAMERAS_TABLE = "Table/head_cameras.tsv"
# Các bảng Table mà collect_ui.py ghi ở đuôi danh sách.
LISTED_TABLES = (WINDOWS_TABLE, STRINGS_TABLE, VIETNAMESE_TABLE, PORTRAITS_TABLE, SCENE_NAMES_TABLE,
                 HEAD_CAMERAS_TABLE)
FONTS_TABLE = "Schema/fonts.tsv"
INTERFACE_EX = ("Config", "InterfaceEx.txt")
STRING_DICTIONARY = ("Config", "StrDictionary.txt")
LIST_LIMIT = 20
BCN_TOLERANCE = 2
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
KIND_SUFFIXES = (
    ".layout.xml", ".looknfeel.xml", ".scheme.xml", ".imageset.xml", ".xml", ".font", ".png",
    ".ttf", ".bin", ".tsv",
)
# Tệp do ui_font.py sinh, không có nguồn cùng tên: (các mảnh nguồn nối theo thứ tự, khoá XOR).
# Khoá 0 là chép nguyên; 0xFE là cờ NeedCode của FreeType trong client gốc.
DERIVED_FONTS = {
    "schema/han_main.ttf": (("Schema/0_FIREFOX_2.bin", "Schema/1_FIREFOX_2.bin"), 0xFE),
    "schema/latin_sans.ttf": (("Schema/2_FIREFOX.bin",), 0),
}
BOM_CHARACTER = "\N{ZERO WIDTH NO-BREAK SPACE}"
DECLARATION = re.compile(r"\A<\?xml.*?\?>", re.DOTALL)
ENCODING_ATTRIBUTE = re.compile(r"""encoding\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
CHINESE_CODECS = ("gb2312", "gbk", "gb18030", "cp936")
# set:<bộ ảnh> image:<ảnh>, có thể sau các token khác (name:, index:, dir:); như sscanf của CEGUI.
IMAGE_REF = re.compile(r"(?:^|\s)set:(\S+)\s+image:\s*(\S+)")
STRING_KEY = re.compile(r"#\{([^{}]*)\}")
CELL_BREAKS = re.compile(r"[\t\r\n]+")
BUILTIN_TYPE = re.compile(r"DefaultWindow|Falagard/.+")
PROPERTY_TAGS = ("Property", "PropertyDefinition")
ANIMATION_TOKEN = re.compile(r"(?:^|\s)animate:(\S+)")
ITEM_TYPE_TOKEN = re.compile(r"(?:^|\s)name:(\S+)")
DIRECT_TEXTURE = re.compile(r"[^\s:*?\"<>|]+\.(?:dds|tga|jpg|jpeg|png|bmp)", re.IGNORECASE)
# Thuộc tính mà giá trị trơn là tên hoạt ảnh trong wowanimate.xml (AnimateId là số, không tính).
ANIMATION_PROPERTIES = ("animate", "flashanimate", "warninganimation", "btnanimation")
INTERFACE_EX_COLUMNS = {
    "id": 0, "name": 1, "layout": 2, "demise": 4, "open_sound": 6, "close_sound": 7, "flag": 8,
    "note": 9,
}


class VerifyError(Exception):
    pass


# Mốc: kết quả


@dataclass
class Row:
    status: str
    kind: str
    subject: str
    detail: str


# Kết quả một mục: dòng FAIL làm mục hỏng, NOTE là ghi chú, INFO in đủ, DATA chỉ vào --report.
@dataclass
class Check:
    title: str
    is_report_only: bool = False
    summary: str = ""
    seconds: float = 0.0
    rows: list[Row] = field(default_factory=list)

    def add(self, status: str, kind: str, subject: str, detail: str = "") -> None:
        self.rows.append(Row(status, kind, subject, detail))

    def fail(self, kind: str, subject: str, detail: str = "") -> None:
        self.add("FAIL", kind, subject, detail)

    def note(self, kind: str, subject: str, detail: str = "") -> None:
        self.add("NOTE", kind, subject, detail)

    def info(self, kind: str, subject: str, detail: str = "") -> None:
        self.add("INFO", kind, subject, detail)

    def data(self, kind: str, subject: str, detail: str = "") -> None:
        self.add("DATA", kind, subject, detail)

    def count(self, status: str) -> int:
        return sum(1 for row in self.rows if row.status == status)

    @property
    def is_ok(self) -> bool:
        return self.count("FAIL") == 0


def verdict(check: Check) -> str:
    if check.is_report_only:
        return "INFO"
    return "PASS" if check.is_ok else "FAIL"


def row_line(label: str, row: Row) -> str:
    body = " ".join(part for part in (row.subject, row.detail) if part)
    return f"  - {label} {row.kind}: {body}" if body else f"  - {label} {row.kind}"


def print_check(check: Check) -> None:
    labels = {"FAIL": "lỗi", "NOTE": "ghi chú", "INFO": "số liệu"}
    print(f"{verdict(check)} {check.title}: {check.summary} ({check.seconds:.1f} s)")
    for status, label in labels.items():
        rows = [row for row in check.rows if row.status == status]
        shown = rows if status == "INFO" else rows[:LIST_LIMIT]
        for row in shown:
            print(row_line(label, row))
        if len(rows) > len(shown):
            print(f"  - ... còn {len(rows) - len(shown)} dòng {label} (đủ trong --report)")
    sys.stdout.flush()


def write_report(path: str, checks: list[Check]) -> None:
    lines = ["check\tstatus\tkind\tsubject\tdetail"]
    for check in checks:
        for row in check.rows:
            cells = [check.title, row.status, row.kind, row.subject, row.detail]
            lines.append("\t".join(CELL_BREAKS.sub(" ", cell) for cell in cells))
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def join_counts(counter: Counter) -> str:
    return ", ".join(f"{name} {count}" for name, count in sorted(counter.items()))


def clip(text: object, limit: int = 48) -> str:
    text = str(text)
    return text if len(text) <= limit else text[:limit] + "..."


def megabytes(size: float) -> str:
    return f"{size / 1048576:.1f} MB"


# Mốc: tệp và tên


def read_bytes(path: str) -> bytes:
    with open(path, "rb") as stream:
        return stream.read()


def kind_of(relative: str) -> str:
    lower = relative.lower()
    for suffix in KIND_SUFFIXES:
        if lower.endswith(suffix):
            return suffix.lstrip(".")
    return "khác"


def is_xml_file(relative: str) -> bool:
    return relative.lower().endswith((".xml", ".font"))


class FileIndex:
    # Cây một thư mục Interface: tên thật trên đĩa, tra không phân biệt hoa/thường khi cần.
    def __init__(self, root: str):
        self.root = root
        self.names: set[str] = set()
        self.folded: dict[str, list[str]] = defaultdict(list)
        for base, folders, files in os.walk(root):
            folders.sort()
            for name in sorted(files):
                relative = os.path.relpath(os.path.join(base, name), root).replace(os.sep, "/")
                self.names.add(relative)
                self.folded[relative.lower()].append(relative)

    # (tên thật, true nếu chỉ khớp khi bỏ phân biệt hoa/thường); không thấy hay mơ hồ thì None.
    def find(self, relative: str) -> tuple[str | None, bool]:
        text = relative.replace("\\", "/")
        if text in self.names:
            return text, False
        candidates = self.folded.get(text.lower(), [])
        if len(candidates) != 1:
            return None, False
        return candidates[0], True

    def path(self, relative: str) -> str:
        return os.path.join(self.root, *relative.split("/"))

    def direct_children(self, folder: str, suffix: str) -> list[str]:
        prefix = folder.lower() + "/"
        found = []
        for name in self.names:
            rest = name[len(prefix):]
            is_child = name.lower().startswith(prefix) and "/" not in rest
            if is_child and name.lower().endswith(suffix):
                found.append(name)
        return sorted(found)


@dataclass(frozen=True)
class Found:
    key: str
    values: list
    is_folded: bool


class NameTable:
    # Tên -> các định nghĩa theo thứ tự nạp; tra đúng tên trước, rồi bỏ hoa/thường nếu chỉ một tên.
    def __init__(self):
        self.items: dict[str, list] = {}
        self._folded: dict[str, list[str]] | None = None

    def add(self, name: str, value) -> None:
        self.items.setdefault(name, []).append(value)
        self._folded = None

    def find(self, name: str) -> Found | None:
        if name in self.items:
            return Found(name, self.items[name], False)
        if self._folded is None:
            self._folded = defaultdict(list)
            for known in self.items:
                self._folded[known.lower()].append(known)
        candidates = self._folded.get(name.lower(), [])
        if len(candidates) != 1:
            return None
        return Found(candidates[0], self.items[candidates[0]], True)


# Looknfeel viết thuộc tính thường, layout viết hoa đầu: thử đúng tên rồi bỏ hoa/thường.
def attribute(element: Element, name: str) -> str | None:
    value = element.get(name)
    if value is not None:
        return value
    wanted = name.lower()
    for key, text in element.attrib.items():
        if key.lower() == wanted:
            return text
    return None


# Layout viết Value, looknfeel viết value, PropertyDefinition viết initialValue.
def property_value(element: Element) -> str:
    for name in ("Value", "value", "initialValue"):
        value = element.get(name)
        if value is not None:
            return value
    return ""


# Mốc: bảng mã và cây XML


@dataclass(frozen=True)
class Decoded:
    text: str
    how: str


def declared_encoding(data: bytes) -> str | None:
    head = data[:200].decode("latin-1")
    match = DECLARATION.match(head)
    if match is None:
        return None
    found = ENCODING_ATTRIBUTE.search(match.group(0))
    return None if found is None else found.group(1).lower()


def decode_declared(data: bytes, name: str) -> Decoded:
    if name in ("utf-8", "utf8"):
        return Decoded(data.decode("utf-8"), f"khai báo {name}")
    codec = "gb18030" if name in CHINESE_CODECS else name
    return Decoded(data.decode(codec), f"khai báo {name}")


# Không BOM, không khai báo: UTF-8 chặt, hỏng thì GB18030 (tập cha của GBK và GB2312).
def decode_plain(data: bytes) -> Decoded:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return Decoded(data.decode("gb18030"), "gb18030")
    return Decoded(text, "ASCII" if text.isascii() else "utf-8 ngoài ASCII")


# Thứ tự dò: BOM, rồi khai báo encoding trong <?xml?>, rồi nội dung.
def decode_by_signature(data: bytes) -> Decoded:
    if data.startswith(codecs.BOM_UTF8):
        return Decoded(data[len(codecs.BOM_UTF8):].decode("utf-8"), "utf-8 BOM")
    if data.startswith((codecs.BOM_UTF16_LE, codecs.BOM_UTF16_BE)):
        return Decoded(data.decode("utf-16"), "utf-16 BOM")
    name = declared_encoding(data)
    if name is not None:
        return decode_declared(data, name)
    return decode_plain(data)


def decode_xml_bytes(data: bytes) -> Decoded:
    try:
        return decode_by_signature(data)
    except (UnicodeError, LookupError) as error:
        raise VerifyError(f"không giải mã được: {error}") from error


# Cả UTF-8 lẫn GB18030 đều giải được mà ra hai chuỗi khác nhau: bảng mã đoán sai được.
def is_ambiguous(data: bytes) -> bool:
    try:
        as_utf8 = data.decode("utf-8")
        as_chinese = data.decode("gb18030")
    except UnicodeDecodeError:
        return False
    return as_utf8 != as_chinese


def gbk_differs(data: bytes) -> bool:
    try:
        return data.decode("gbk") != data.decode("gb18030")
    except UnicodeDecodeError:
        return True


def strip_declaration(text: str) -> str:
    return DECLARATION.sub("", text.lstrip(BOM_CHARACTER), count=1)


def parse_xml(text: str, label: str) -> Element:
    body = strip_declaration(text)
    try:
        return ElementTree.fromstring(body)
    except ElementTree.ParseError as error:
        raise VerifyError(f"{label}: XML hỏng: {error}") from error


def describe_attributes(left: dict, right: dict) -> str:
    for key in sorted(set(left) | set(right)):
        if left.get(key) != right.get(key):
            return f"{key}: {clip(left.get(key))!r} khác {clip(right.get(key))!r}"
    return ""


# Khác biệt của một cặp phần tử (không xét con), hoặc None. Văn bản đã strip; parser đã bỏ comment.
def compare_node(left: Element, right: Element, path: str) -> str | None:
    if left.tag != right.tag:
        return f"{path}: thẻ {left.tag!r} khác {right.tag!r}"
    if left.attrib != right.attrib:
        return f"{path}: thuộc tính {describe_attributes(left.attrib, right.attrib)}"
    if (left.text or "").strip() != (right.text or "").strip():
        return f"{path}: văn bản {clip((left.text or '').strip())!r} khác"
    if (left.tail or "").strip() != (right.tail or "").strip():
        return f"{path}: văn bản sau thẻ khác"
    if len(left) != len(right):
        return f"{path}: số con {len(left)} khác {len(right)}"
    return None


# Duyệt tiền thứ tự, không đệ quy (cây layout có thể sâu); trả đường dẫn thẻ của chỗ lệch đầu tiên.
def first_difference(left: Element, right: Element) -> str | None:
    stack = [(left, right, left.tag)]
    while stack:
        first, second, path = stack.pop()
        found = compare_node(first, second, path)
        if found is not None:
            return found
        pairs = list(zip(first, second))
        for position in reversed(range(len(pairs))):
            child_first, child_second = pairs[position]
            stack.append((child_first, child_second, f"{path}/{child_first.tag}[{position}]"))
    return None


def count_elements(root: Element) -> int:
    return sum(1 for _ in root.iter())


# Mốc: giải mã texture


class TextureError(Exception):
    pass


DDS_MAGIC = b"DDS "
DDS_HEADER_BYTES = 128
DDSD_MIPMAPCOUNT = 0x20000
DDPF_ALPHA = 0x2
DDPF_FOURCC = 0x4
DDPF_RGB = 0x40
DDSCAPS2_CUBEMAP = 0x200
DDSCAPS2_VOLUME = 0x200000
# FourCC -> (họ BCn, tên D3D, byte mỗi khối).
BLOCK_FORMATS = {
    b"DXT1": ("BC1", "DXT1", 8), b"DXT2": ("BC2", "DXT2", 16), b"DXT3": ("BC2", "DXT3", 16),
    b"DXT4": ("BC3", "DXT4", 16), b"DXT5": ("BC3", "DXT5", 16),
}
# Giá trị lớn nhất của kênh R, G, B trong RGB565.
COLOR_MAXIMA = np.array([31, 63, 31])
MASKED_NAMES = {
    (32, (0xFF0000, 0xFF00, 0xFF, 0xFF000000)): "A8R8G8B8",
    (32, (0xFF0000, 0xFF00, 0xFF, 0)): "X8R8G8B8",
    (24, (0xFF0000, 0xFF00, 0xFF, 0)): "R8G8B8",
    (16, (0xF800, 0x7E0, 0x1F, 0)): "R5G6B5",
    (8, (0, 0, 0, 0xFF)): "A8",
}


@dataclass(frozen=True)
class DdsHeader:
    width: int
    height: int
    mip_count: int
    flags: int
    caps: int
    caps2: int
    pixel_flags: int
    fourcc: bytes
    bit_count: int
    masks: tuple[int, int, int, int]
    payload_offset: int


@dataclass
class DecodedImage:
    pixels: np.ndarray
    group: str
    is_lossy: bool = False
    mip_count: int = 1
    flags_text: str = ""
    size_note: str = ""


def read_dds_header(data: bytes) -> DdsHeader:
    if len(data) < DDS_HEADER_BYTES or data[:4] != DDS_MAGIC:
        raise TextureError("không phải DDS")
    size, flags, height, width, _pitch, _depth, mips = struct.unpack_from("<7I", data, 4)
    pixel_size, pixel_flags, fourcc, bit_count, *masks = struct.unpack_from("<2I4s5I", data, 76)
    caps, caps2 = struct.unpack_from("<2I", data, 108)
    if size != 124 or pixel_size != 32:
        raise TextureError(f"đầu DDS lạ (size {size}, pixelformat {pixel_size})")
    four = fourcc if pixel_flags & DDPF_FOURCC else b""
    count = mips if flags & DDSD_MIPMAPCOUNT and mips > 0 else 1
    return DdsHeader(width, height, count, flags, caps, caps2, pixel_flags, four, bit_count,
                     tuple(masks), DDS_HEADER_BYTES)


def level_bytes(header: DdsHeader, level: int) -> int:
    width = max(1, header.width >> level)
    height = max(1, header.height >> level)
    if header.fourcc in BLOCK_FORMATS:
        block = BLOCK_FORMATS[header.fourcc][2]
        return ((width + 3) // 4) * ((height + 3) // 4) * block
    return ((width * header.bit_count + 7) // 8) * height


# Kích thước tệp theo đầu tệp: đầu + mọi mức mip; lệch nghĩa là có dữ liệu thừa hay thiếu.
def expected_dds_size(header: DdsHeader) -> int:
    total = sum(level_bytes(header, level) for level in range(header.mip_count))
    return header.payload_offset + total


def split_565(word: np.ndarray) -> np.ndarray:
    return np.stack([(word >> 11) & 31, (word >> 5) & 63, word & 31], axis=-1)


# round(numerator * 255 / denominator), nửa lên, chỉ một lần làm tròn từ số nguyên.
def to_byte(numerator: np.ndarray, denominator: np.ndarray) -> np.ndarray:
    return (numerator * 510 + denominator) // (2 * denominator)


# Các trường little-endian `bits` bit liên tiếp từ các byte cuối trục.
def unpack_fields(raw: np.ndarray, bits: int, count: int) -> np.ndarray:
    word = np.zeros(raw.shape[:-1], dtype=np.int64)
    for position in range(raw.shape[-1]):
        word |= raw[..., position].astype(np.int64) << (8 * position)
    shifts = np.arange(count, dtype=np.int64) * bits
    return (word[..., None] >> shifts) & ((1 << bits) - 1)


# Khối màu 8 byte của BC1 (hay nửa sau của BC2/BC3) thành 16 điểm RGBA. Mọi màu của bảng màu tính
# bằng số học hữu tỉ từ giá trị 5/6 bit (2/3 c0 + 1/3 c1 như đặc tả D3D) rồi làm tròn một lần; nội
# suy trên giá trị 8 bit đã nở bit thì lệch tới 1 so với PNG đã gom (đo trên 39 tệp DXT3). BC1:
# c0 <= c1 là chế độ 3 màu, chỉ số 3 trong suốt; BC2/BC3 luôn 4 màu.
def color_pixels(blocks: np.ndarray, has_one_bit_alpha: bool) -> np.ndarray:
    word_low = blocks[..., 0].astype(np.int32) | (blocks[..., 1].astype(np.int32) << 8)
    word_high = blocks[..., 2].astype(np.int32) | (blocks[..., 3].astype(np.int32) << 8)
    low = split_565(word_low)
    high = split_565(word_high)
    is_four = (word_low > word_high) | (not has_one_bit_alpha)
    mask = is_four[..., None]
    third = np.where(mask, to_byte(2 * low + high, 3 * COLOR_MAXIMA),
                     to_byte(low + high, 2 * COLOR_MAXIMA))
    fourth = np.where(mask, to_byte(low + 2 * high, 3 * COLOR_MAXIMA), 0)
    palette = np.stack([to_byte(low, COLOR_MAXIMA), to_byte(high, COLOR_MAXIMA), third, fourth],
                       axis=-2)
    selector = unpack_fields(blocks[..., 4:8], 2, 16)
    colors = np.take_along_axis(palette, selector[..., None], axis=-2)
    is_clear = (~is_four)[..., None] & (selector == 3)
    alpha = np.where(is_clear, 0, 255)
    return np.concatenate([colors, alpha[..., None]], axis=-1).astype(np.uint8)


def explicit_alpha(blocks: np.ndarray) -> np.ndarray:
    nibbles = np.stack([blocks & 15, blocks >> 4], axis=-1)
    return nibbles.reshape(blocks.shape[:-1] + (16,)).astype(np.int32) * 17


# BC3: a0 > a1 thì 8 mức (6 giá trị nội suy chia 7), ngược lại 6 mức cộng 0 và 255.
def interpolated_alpha(blocks: np.ndarray) -> np.ndarray:
    first = blocks[..., 0].astype(np.int32)[..., None]
    second = blocks[..., 1].astype(np.int32)[..., None]
    steps_eight = np.arange(6, dtype=np.int32)
    steps_six = np.arange(4, dtype=np.int32)
    eight = ((6 - steps_eight) * first + (1 + steps_eight) * second + 3) // 7
    six = ((4 - steps_six) * first + (1 + steps_six) * second + 2) // 5
    zero = np.zeros_like(first)
    table_eight = np.concatenate([first, second, eight], axis=-1)
    table_six = np.concatenate([first, second, six, zero, zero + 255], axis=-1)
    table = np.where(first > second, table_eight, table_six)
    selector = unpack_fields(blocks[..., 2:8], 3, 16)
    return np.take_along_axis(table, selector, axis=-1)


def decode_blocks(blocks: np.ndarray, family: str) -> np.ndarray:
    if family == "BC1":
        return color_pixels(blocks, True)
    pixels = color_pixels(blocks[..., 8:16], False)
    is_explicit = family == "BC2"
    alpha = explicit_alpha(blocks[..., :8]) if is_explicit else interpolated_alpha(blocks[..., :8])
    pixels[..., 3] = alpha.astype(np.uint8)
    return pixels


def split_blocks(payload: bytes, width: int, height: int, block_bytes: int) -> np.ndarray:
    blocks_x = max(1, (width + 3) // 4)
    blocks_y = max(1, (height + 3) // 4)
    needed = blocks_x * blocks_y * block_bytes
    if len(payload) < needed:
        raise TextureError(f"khối nén bị cắt cụt: cần {needed} byte, có {len(payload)}")
    flat = np.frombuffer(payload, dtype=np.uint8, count=needed)
    return flat.reshape(blocks_y, blocks_x, block_bytes)


def assemble_blocks(pixels: np.ndarray, width: int, height: int) -> np.ndarray:
    blocks_y, blocks_x = pixels.shape[:2]
    grid = pixels.reshape(blocks_y, blocks_x, 4, 4, 4)
    image = grid.transpose(0, 2, 1, 3, 4).reshape(blocks_y * 4, blocks_x * 4, 4)
    return np.ascontiguousarray(image[:height, :width])


def scale_channel(value: np.ndarray, mask: int) -> np.ndarray | None:
    if mask == 0:
        return None
    shift = (mask & -mask).bit_length() - 1
    maximum = (mask >> shift)
    field_value = (value & mask) >> shift
    return (field_value * 255 + maximum // 2) // maximum


def decode_masked_dds(data: bytes, header: DdsHeader) -> DecodedImage:
    bits = header.bit_count
    has_color = header.pixel_flags & (DDPF_RGB | DDPF_ALPHA)
    if bits not in (8, 16, 24, 32) or not has_color:
        raise TextureError(f"DDS không nén {bits} bit, cờ {header.pixel_flags:#x} chưa hỗ trợ")
    pixel_bytes = bits // 8
    needed = header.width * pixel_bytes * header.height
    payload = data[header.payload_offset:header.payload_offset + needed]
    if len(payload) < needed:
        raise TextureError(f"dữ liệu bị cắt cụt: cần {needed} byte, có {len(payload)}")
    raw = np.frombuffer(payload, dtype=np.uint8).reshape(header.height, header.width, pixel_bytes)
    value = np.zeros((header.height, header.width), dtype=np.int64)
    for position in range(pixel_bytes):
        value |= raw[..., position].astype(np.int64) << (8 * position)
    image = np.zeros((header.height, header.width, 4), dtype=np.uint8)
    image[..., 3] = 255
    for channel, mask in enumerate(header.masks):
        scaled = scale_channel(value, mask)
        if scaled is not None:
            image[..., channel] = scaled
    name = MASKED_NAMES.get((bits, header.masks), f"{bits} bit mặt nạ {header.masks}")
    return DecodedImage(image, f"DDS {name}")


def decode_dds(data: bytes) -> DecodedImage:
    header = read_dds_header(data)
    if header.caps2 & (DDSCAPS2_CUBEMAP | DDSCAPS2_VOLUME):
        raise TextureError("DDS cubemap hay volume chưa hỗ trợ")
    if header.fourcc in BLOCK_FORMATS:
        family, label, block_bytes = BLOCK_FORMATS[header.fourcc]
        payload = data[header.payload_offset:]
        blocks = split_blocks(payload, header.width, header.height, block_bytes)
        pixels = assemble_blocks(decode_blocks(blocks, family), header.width, header.height)
        image = DecodedImage(pixels, f"DDS {family} ({label})", is_lossy=True)
    elif header.fourcc:
        raise TextureError(f"FourCC {header.fourcc!r} chưa hỗ trợ (DX10 cũng chưa)")
    else:
        image = decode_masked_dds(data, header)
    image.mip_count = header.mip_count
    image.flags_text = f"cờ {header.flags:#x} caps {header.caps:#x}"
    expected = expected_dds_size(header)
    if expected != len(data):
        image.size_note = f"kích thước tệp {len(data)} khác {expected} theo đầu tệp"
    return image


# TGA không nén 24/32 bit (kiểu 2); bit 5 của descriptor là gốc trên-trái, bit 4 là phải-sang-trái.
def decode_tga(data: bytes) -> DecodedImage:
    if len(data) < 18:
        raise TextureError("TGA ngắn hơn đầu tệp")
    head = struct.unpack_from("<BBBHHBHHHHBB", data, 0)
    id_length, map_type, image_type, _a, _b, _c, _x, _y, width, height, depth, descriptor = head
    if map_type != 0 or image_type != 2 or depth not in (24, 32):
        raise TextureError(f"TGA kiểu {image_type} {depth} bit, bảng màu {map_type} chưa hỗ trợ")
    pixel_bytes = depth // 8
    needed = width * height * pixel_bytes
    payload = data[18 + id_length:18 + id_length + needed]
    if len(payload) < needed:
        raise TextureError(f"TGA bị cắt cụt: cần {needed} byte, có {len(payload)}")
    raw = np.frombuffer(payload, dtype=np.uint8).reshape(height, width, pixel_bytes)
    image = np.full((height, width, 4), 255, dtype=np.uint8)
    image[..., 0] = raw[..., 2]
    image[..., 1] = raw[..., 1]
    image[..., 2] = raw[..., 0]
    if pixel_bytes == 4:
        image[..., 3] = raw[..., 3]
    if not descriptor & 0x20:
        image = image[::-1]
    if descriptor & 0x10:
        image = image[:, ::-1]
    group = f"TGA {depth} bit"
    flags_text = f"descriptor {descriptor:#x}"
    return DecodedImage(np.ascontiguousarray(image), group, flags_text=flags_text)


def pillow_rgba(source: str | bytes) -> np.ndarray:
    stream = io.BytesIO(source) if isinstance(source, bytes) else source
    with Image.open(stream) as image:
        image.load()
        return np.array(image.convert("RGBA"))


def decode_source(path: str) -> DecodedImage:
    data = read_bytes(path)
    extension = os.path.splitext(path)[1].lower()
    if data.startswith(DDS_MAGIC):
        return decode_dds(data)
    if extension == ".tga":
        return decode_tga(data)
    name = "JPG" if extension in (".jpg", ".jpeg") else extension.lstrip(".").upper()
    return DecodedImage(pillow_rgba(data), name)


def read_head(path: str, size: int) -> bytes:
    with open(path, "rb") as stream:
        return stream.read(size)


# (rộng, cao, độ sâu bit, kiểu màu, xen kẽ) trong khối IHDR của PNG.
def parse_png_header(head: bytes) -> tuple[int, int, int, int, int]:
    if len(head) < 29 or head[:8] != PNG_SIGNATURE or head[12:16] != b"IHDR":
        raise TextureError("không phải PNG")
    width, height, depth, color, _compression, _filter, interlace = struct.unpack(
        ">IIBBBBB", head[16:29])
    return width, height, depth, color, interlace


# Kích thước một texture bất kể loại, chỉ đọc đầu tệp (JPG qua Pillow, không nạp điểm ảnh).
def measure_image(path: str) -> tuple[int, int] | None:
    try:
        head = read_head(path, DDS_HEADER_BYTES)
        if head.startswith(PNG_SIGNATURE):
            return parse_png_header(head)[:2]
        if head.startswith(DDS_MAGIC):
            header = read_dds_header(head)
            return header.width, header.height
        if path.lower().endswith(".tga"):
            return struct.unpack_from("<HH", head, 12)
        with Image.open(path) as image:
            return image.size
    except (OSError, TextureError, struct.error, ValueError):
        return None


# Mốc: tự kiểm bộ giải mã


def expect(is_true: bool, text: str) -> None:
    if not is_true:
        raise VerifyError(text)


@dataclass(frozen=True)
class PixelFormat:
    flags: int
    fourcc: bytes = b""
    bit_count: int = 0
    masks: tuple[int, int, int, int] = (0, 0, 0, 0)


def compressed(fourcc: bytes) -> PixelFormat:
    return PixelFormat(DDPF_FOURCC, fourcc)


def build_dds(width: int, height: int, pixel_format: PixelFormat, payload: bytes) -> bytes:
    head = struct.pack("<4sIIIIIII", DDS_MAGIC, 124, 0x1007, height, width, 0, 0, 1)
    head += bytes(44)
    fourcc = pixel_format.fourcc.ljust(4, b"\0")
    head += struct.pack("<II4sIIIII", 32, pixel_format.flags, fourcc, pixel_format.bit_count,
                        *pixel_format.masks)
    head += struct.pack("<IIIII", 0x1000, 0, 0, 0, 0)
    return head + payload


def color_block(word_low: int, word_high: int) -> bytes:
    selector = sum((index % 4) << (2 * index) for index in range(16))
    return struct.pack("<HHI", word_low, word_high, selector)


def first_row(data: bytes) -> list[tuple[int, ...]]:
    return [tuple(int(value) for value in pixel) for pixel in decode_dds(data).pixels[0]]


def test_bc1_four_color() -> None:
    data = build_dds(4, 4, compressed(b"DXT1"), color_block(0xF800, 0x001F))
    expected = [(255, 0, 0, 255), (0, 0, 255, 255), (170, 0, 85, 255), (85, 0, 170, 255)]
    expect(first_row(data) == expected, "BC1 bốn màu sai")


def test_bc1_three_color() -> None:
    data = build_dds(4, 4, compressed(b"DXT1"), color_block(0x001F, 0xF800))
    expected = [(0, 0, 255, 255), (255, 0, 0, 255), (128, 0, 128, 255), (0, 0, 0, 0)]
    expect(first_row(data) == expected, "BC1 ba màu sai")


# R5 = 3 nở bit thành 24 nhưng đúng toán là 24,68 -> 25; nội suy 1/3 và 2/3 của 3 là 8,23 và 16,45.
def test_bc1_rounding() -> None:
    data = build_dds(4, 4, compressed(b"DXT1"), color_block(0x1800, 0x0000))
    reds = [pixel[0] for pixel in first_row(data)]
    expect(reds == [25, 0, 16, 8], f"làm tròn BC1 sai: {reds}")


def test_bc2_alpha_and_four_color() -> None:
    alpha = bytes((2 * step) | ((2 * step + 1) << 4) for step in range(8))
    block = alpha + color_block(0x001F, 0xF800)
    data = build_dds(4, 4, compressed(b"DXT3"), block)
    image = decode_dds(data).pixels
    expect(list(image[:, :, 3].reshape(-1)) == [i * 17 for i in range(16)], "BC2 alpha sai")
    expected = [(0, 0, 255), (255, 0, 0), (85, 0, 170), (170, 0, 85)]
    colors = [tuple(int(value) for value in pixel[:3]) for pixel in image[0]]
    expect(colors == expected, "BC2 màu sai")


def test_bc3_alpha_modes() -> None:
    selector = sum((index % 8) << (3 * index) for index in range(16)).to_bytes(6, "little")
    eight = bytes([255, 0]) + selector + color_block(0xF800, 0x001F)
    six = bytes([0, 255]) + selector + color_block(0xF800, 0x001F)
    first = decode_dds(build_dds(4, 4, compressed(b"DXT5"), eight))
    second = decode_dds(build_dds(4, 4, compressed(b"DXT5"), six))
    table_eight = [255, 0, 219, 182, 146, 109, 73, 36]
    table_six = [0, 255, 51, 102, 153, 204, 0, 255]
    expect(list(first.pixels[:, :, 3].reshape(-1)) == table_eight * 2, "BC3 tám mức sai")
    expect(list(second.pixels[:, :, 3].reshape(-1)) == table_six * 2, "BC3 sáu mức sai")


def test_block_order_and_crop() -> None:
    solid = [0xF800, 0x07E0, 0x001F, 0xFFFF]
    payload = b"".join(struct.pack("<HHI", color, color, 0) for color in solid)
    image = decode_dds(build_dds(6, 5, compressed(b"DXT1"), payload)).pixels
    expect(image.shape == (5, 6, 4), f"hình dạng sau cắt sai {image.shape}")
    positions = ((0, 0), (0, 5), (4, 0), (4, 5))
    corners = [tuple(int(value) for value in image[row, column][:3]) for row, column in positions]
    expect(corners == [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 255)], "thứ tự khối sai")


def decoded_row(width: int, pixel_format: PixelFormat, payload: bytes) -> list:
    return decode_dds(build_dds(width, 1, pixel_format, payload)).pixels[0].tolist()


def test_masked_formats() -> None:
    masks_a = (0xFF0000, 0xFF00, 0xFF, 0xFF000000)
    masks_x = masks_a[:3] + (0,)
    pixels = bytes([30, 20, 10, 40, 70, 60, 50, 80])
    argb = decoded_row(2, PixelFormat(0x41, b"", 32, masks_a), pixels)
    expect(argb == [[10, 20, 30, 40], [50, 60, 70, 80]], "A8R8G8B8 sai")
    xrgb = decoded_row(2, PixelFormat(0x40, b"", 32, masks_x), pixels)
    expect(xrgb == [[10, 20, 30, 255], [50, 60, 70, 255]], "X8R8G8B8 sai")
    rgb = decoded_row(2, PixelFormat(0x40, b"", 24, masks_x), bytes([3, 2, 1, 6, 5, 4]))
    expect(rgb == [[1, 2, 3, 255], [4, 5, 6, 255]], "R8G8B8 sai")
    alpha = decoded_row(2, PixelFormat(DDPF_ALPHA, b"", 8, (0, 0, 0, 0xFF)), bytes([7, 9]))
    expect(alpha == [[0, 0, 0, 7], [0, 0, 0, 9]], "A8 sai")
    wide = decoded_row(2, PixelFormat(0x40, b"", 16, (0xF800, 0x7E0, 0x1F, 0)),
                       struct.pack("<HH", 0xFFFF, 0))
    expect(wide == [[255, 255, 255, 255], [0, 0, 0, 255]], "R5G6B5 sai")


def test_tga_orientation() -> None:
    def tga(descriptor: int) -> bytes:
        head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, 2, 2, 32, descriptor)
        return head + bytes(value for base in (1, 2, 3, 4)
                            for value in (base, base + 10, base + 20, base + 30))
    top = decode_tga(tga(0x28)).pixels
    bottom = decode_tga(tga(0x08)).pixels
    expect(top[0, 0].tolist() == [21, 11, 1, 31], "TGA trên-trái sai")
    expect(bottom[0, 0].tolist() == [23, 13, 3, 33], "TGA dưới-trái sai")


def test_xml_decoding() -> None:
    text = '<?xml version="1.0"?>\n<a b="中文"/>'
    cases = {
        "utf-16 BOM": codecs.BOM_UTF16_LE + text.encode("utf-16-le"),
        "utf-8 BOM": codecs.BOM_UTF8 + text.encode("utf-8"),
        "gb18030": text.encode("gbk"),
        "utf-8 ngoài ASCII": text.encode("utf-8"),
        "khai báo gb2312": text.replace("1.0\"", "1.0\" encoding=\"gb2312\"").encode("gbk"),
    }
    for how, data in cases.items():
        decoded = decode_xml_bytes(data)
        expect(decoded.how == how, f"nhận dạng {how} thành {decoded.how}")
        expect("中文" in decoded.text, f"giải mã {how} sai chữ")


def test_xml_compare() -> None:
    base = ElementTree.fromstring("<r><a x='1'>t</a><b/></r>")
    same = ElementTree.fromstring("<r><!-- ghi chú --><a x='1'> t </a><b/></r>")
    changed = ElementTree.fromstring("<r><a x='2'>t</a><b/></r>")
    swapped = ElementTree.fromstring("<r><b/><a x='1'>t</a></r>")
    extra = ElementTree.fromstring("<r><a x='1'>t</a><b/><c/></r>")
    expect(first_difference(base, same) is None, "cây giống bị báo khác")
    expect("thuộc tính" in (first_difference(base, changed) or ""), "không thấy đổi thuộc tính")
    expect("khác" in (first_difference(base, swapped) or ""), "không thấy đổi thứ tự")
    expect("số con" in (first_difference(base, extra) or ""), "không thấy thêm con")


SELF_TESTS = (
    test_bc1_four_color, test_bc1_three_color, test_bc1_rounding, test_bc2_alpha_and_four_color,
    test_bc3_alpha_modes, test_block_order_and_crop, test_masked_formats, test_tga_orientation,
    test_xml_decoding, test_xml_compare,
)


def self_test() -> list[str]:
    failures = []
    for case in SELF_TESTS:
        try:
            case()
        except (VerifyError, TextureError, AssertionError, ValueError) as error:
            failures.append(f"{case.__name__}: {error}")
    return failures


def dds_label(header: DdsHeader) -> str:
    if header.fourcc in BLOCK_FORMATS:
        return BLOCK_FORMATS[header.fourcc][0]
    return MASKED_NAMES.get((header.bit_count, header.masks), f"{header.bit_count} bit")


# Tệp DDS nhỏ nhất của mỗi dạng pixel trong gốc, làm mẫu thật cho lượt đối chiếu với Pillow.
def oracle_samples(raw: FileIndex) -> dict[str, str]:
    best: dict[str, tuple[int, str]] = {}
    for relative in sorted(name for name in raw.names if name.lower().endswith(".dds")):
        path = raw.path(relative)
        try:
            label = dds_label(read_dds_header(read_head(path, DDS_HEADER_BYTES)))
        except (OSError, TextureError):
            continue
        size = os.path.getsize(path)
        if label not in best or size < best[label][0]:
            best[label] = (size, path)
    return {label: path for label, (_, path) in best.items()}


# Pillow là cài đặt C độc lập với bộ giải của ta; không nén phải khớp tuyệt đối, BCn ≤ ngưỡng.
def oracle_check(check: Check, raw: FileIndex) -> None:
    results = []
    for label, path in sorted(oracle_samples(raw).items()):
        try:
            data = read_bytes(path)
            ours = decode_dds(data)
            theirs = pillow_rgba(data)
        except (TextureError, OSError, ValueError) as error:
            check.note("đối chiếu Pillow", os.path.basename(path), f"bỏ qua: {error}")
            continue
        is_same_shape = ours.pixels.shape == theirs.shape
        gap = ours.pixels.astype(np.int16) - theirs.astype(np.int16)
        worst = int(np.abs(gap).max()) if is_same_shape else -1
        limit = BCN_TOLERANCE if ours.is_lossy else 0
        results.append(f"{label} {os.path.basename(path)} lệch {worst}")
        if worst < 0 or worst > limit:
            detail = f"{label}: lệch {worst}, ngưỡng {limit}"
            check.fail("bộ giải DDS lệch Pillow", os.path.basename(path), detail)
    check.info("đối chiếu Pillow trên mẫu thật", "", "; ".join(results))


# Mốc: không gian làm việc và nguồn của tệp


@dataclass
class Origin:
    sources: list[str]
    way: str
    is_case_different: bool


def derived_origin(raw: FileIndex, pieces: tuple[str, ...]) -> Origin | None:
    found = []
    for piece in pieces:
        real, _ = raw.find(piece)
        if real is None:
            return None
        found.append(real)
    return Origin(found, "dẫn xuất", False)


def schema_fonts(raw: FileIndex) -> list[str]:
    return raw.direct_children(SCHEMA, ".font")


def find_origin(raw: FileIndex, relative: str) -> Origin | None:
    lower = relative.lower()
    if lower in DERIVED_FONTS:
        return derived_origin(raw, DERIVED_FONTS[lower][0])
    if lower == FONTS_TABLE.lower():
        fonts = schema_fonts(raw)
        return Origin(fonts, "dẫn xuất", False) if fonts else None
    is_png = lower.endswith(".png")
    wanted = relative[:-4] if is_png else relative
    real, is_folded = raw.find(wanted)
    if real is None:
        return None
    return Origin([real], "bỏ .png" if is_png else "cùng tên", is_folded)


@dataclass
class TextureUse:
    imagefile: str
    real: str | None
    is_folded: bool
    right: float = 0.0
    bottom: float = 0.0


@dataclass
class ImagesetDef:
    name: str
    imagefile: str
    source: str
    images: NameTable


def read_rect(image: Element) -> tuple[float, float, float, float] | None:
    try:
        return tuple(float(image.get(key, "0")) for key in ("XPos", "YPos", "Width", "Height"))
    except ValueError:
        return None


class Universe:
    # Một kho giao diện đọc như client nạp: scheme -> looknfeel (theo danh sách trong scheme) ->
    # imageset (mọi *.imageset.xml) -> hoạt ảnh. texture_suffix là ".png" với dữ liệu đã gom, rỗng
    # với kho gốc (texture là tệp nguồn).
    def __init__(self, files: FileIndex, label: str, texture_suffix: str):
        self.files = files
        self.label = label
        self.texture_suffix = texture_suffix
        self.mappings = NameTable()
        self.looks = NameTable()
        self.imagesets = NameTable()
        self.animations = NameTable()
        self.fonts = NameTable()
        self.errors: list[str] = []
        self.scheme_files: list[str] = []
        self.look_files: list[str] = []
        self.absent_look_files: list[str] = []
        self.imageset_files: list[str] = []
        self.animation_files: list[str] = []
        self.look_roots: dict[str, Element] = {}
        self.malformed_rects = 0
        self._trees: dict[str, Element] = {}
        self._sizes: dict[str, tuple[int, int] | None] = {}
        self._sections: dict[int, NameTable] = {}
        self._load()

    def load_tree(self, relative: str) -> tuple[Element, str]:
        data = read_bytes(self.files.path(relative))
        decoded = decode_xml_bytes(data)
        return parse_xml(decoded.text, relative), decoded.how

    def tree(self, relative: str) -> Element:
        if relative not in self._trees:
            self._trees[relative] = self.load_tree(relative)[0]
        return self._trees[relative]

    def parse(self, relative: str) -> Element | None:
        try:
            return self.tree(relative)
        except (VerifyError, OSError) as error:
            self.errors.append(f"{relative}: {error}")
            return None

    def find_texture(self, imagefile: str) -> tuple[str | None, bool]:
        return self.files.find(imagefile.replace("\\", "/") + self.texture_suffix)

    def texture_size(self, real: str) -> tuple[int, int] | None:
        if real not in self._sizes:
            self._sizes[real] = measure_image(self.files.path(real))
        return self._sizes[real]

    def section_table(self, look: Element) -> NameTable:
        if id(look) not in self._sections:
            table = NameTable()
            for section in look.findall("ImagerySection"):
                table.add(attribute(section, "name") or "", section)
            self._sections[id(look)] = table
        return self._sections[id(look)]

    def _load(self) -> None:
        self._load_schema()
        self._load_imagesets()
        self._load_animations()

    def _load_schema(self) -> None:
        self.scheme_files = self.files.direct_children(SCHEMA, ".scheme.xml")
        if not self.scheme_files:
            raise VerifyError(f"{self.label}: không có {SCHEMA}/*.scheme.xml")
        listed: list[str] = []
        for relative in self.scheme_files:
            root = self.parse(relative)
            for element in ([] if root is None else root):
                self._take_scheme_entry(element, listed)
        for filename in listed:
            self._load_look_file(filename)

    def _take_scheme_entry(self, element: Element, listed: list[str]) -> None:
        if element.tag == "FalagardMapping":
            self.mappings.add(element.get("WindowType", ""), element.get("LookNFeel", ""))
        elif element.tag == "LookNFeel":
            listed.append(element.get("Filename", ""))
        elif element.tag == "Font":
            self.fonts.add(element.get("Name", ""), element.get("Filename", ""))

    def _load_look_file(self, filename: str) -> None:
        real, _ = self.files.find(filename)
        if real is None:
            self.absent_look_files.append(filename)
            return
        root = self.parse(real)
        if root is None:
            return
        self.look_files.append(real)
        self.look_roots[real] = root
        for element in root.findall("WidgetLook"):
            self.looks.add(element.get("name", ""), element)

    # all.imageset.xml gộp nhiều <Imageset> dưới một gốc; các tệp lẻ có <Imageset> làm gốc.
    def _load_imagesets(self) -> None:
        names = [name for name in self.files.names if name.lower().endswith(".imageset.xml")]
        names.sort(key=lambda name: (not name.lower().endswith("all.imageset.xml"), name))
        self.imageset_files = names
        for relative in names:
            root = self.parse(relative)
            if root is None:
                continue
            elements = [root] if root.tag == "Imageset" else root.findall("Imageset")
            for element in elements:
                self._add_imageset(element, relative)

    def _add_imageset(self, element: Element, relative: str) -> None:
        imagefile = element.get("Imagefile", "").replace("\\", "/")
        definition = ImagesetDef(element.get("Name", ""), imagefile, relative, NameTable())
        for image in element.findall("Image"):
            rect = read_rect(image)
            self.malformed_rects += rect is None
            definition.images.add(image.get("Name", ""), rect)
        self.imagesets.add(definition.name, definition)

    def _load_animations(self) -> None:
        skipped = (".scheme.xml", ".looknfeel.xml", ".imageset.xml", ".layout.xml")
        for relative in self.files.direct_children(SCHEMA, ".xml"):
            if relative.lower().endswith(skipped):
                continue
            root = self.parse(relative)
            if root is not None and root.tag == "AnimateManager":
                self.animation_files.append(relative)
                for element in root.findall("Animate"):
                    self.animations.add(element.get("Name", ""), element)


# Mốc: bộ duyệt bao đóng


# Khoá #{...} trong thuộc tính và văn bản của một phần tử (comment đã bị parser bỏ).
def collect_keys(element: Element, keys: Counter) -> None:
    texts = list(element.attrib.values()) + [element.text or "", element.tail or ""]
    for text in texts:
        if "#{" in text:
            keys.update(STRING_KEY.findall(text))


class Walker:
    # Duyệt bao đóng từ các layout: kiểu -> mapping -> look -> section/child/property -> ảnh ->
    # bộ ảnh -> texture. Chế độ mở rộng thêm cạnh ngoài chuỗi đó: hoạt ảnh, phông, đường dẫn ảnh
    # trực tiếp, kiểu nạp động. Tham chiếu hỏng đếm theo (loại, tên) cùng nơi gặp đầu tiên.
    def __init__(self, universe: Universe, is_extended: bool):
        self.universe = universe
        self.is_extended = is_extended
        self.context = ""
        self.unresolved: Counter = Counter()
        self.origins: dict[tuple[str, str], str] = {}
        self.folded: Counter = Counter()
        self.malformed: Counter = Counter()
        self.keys: Counter = Counter()
        self.seen_types: set[str] = set()
        self.builtin_types: set[str] = set()
        self.seen_looks: set[str] = set()
        self.seen_sections: set[tuple[str, str]] = set()
        self.seen_animations: set[str] = set()
        self.seen_fonts: set[str] = set()
        self.used_images: dict[str, set[str]] = {}
        self.textures: dict[str, TextureUse] = {}
        self.direct_textures: dict[str, TextureUse] = {}
        self.spelling_conflicts: set[str] = set()
        self.layout_errors: list[str] = []
        self.windows = 0
        self.layouts = 0
        self.empty_refs = 0

    def miss(self, kind: str, name: str) -> None:
        key = (kind, name)
        self.unresolved[key] += 1
        self.origins.setdefault(key, self.context)

    def lookup(self, table: NameTable, kind: str, name: str) -> Found | None:
        found = table.find(name)
        if found is None:
            self.miss(kind, name)
        elif found.is_folded:
            self.folded[(kind, name)] += 1
        return found

    def walk(self, relative: str) -> None:
        try:
            root = self.universe.tree(relative)
        except (VerifyError, OSError) as error:
            self.layout_errors.append(f"{relative}: {error}")
            return
        self.walk_tree(root, relative)

    def walk_tree(self, root: Element, label: str) -> None:
        self.layouts += 1
        self.context = label
        for element in root.iter():
            if element.tag == "Window":
                self.windows += 1
                self.visit_type(attribute(element, "Type") or "DefaultWindow")
            self.scan(element)
            self.context = label

    def visit_type(self, name: str) -> None:
        if name in self.seen_types:
            return
        self.seen_types.add(name)
        if BUILTIN_TYPE.fullmatch(name):
            self.builtin_types.add(name)
            return
        found = self.lookup(self.universe.mappings, "kiểu", name)
        if found is not None:
            self.visit_look(found.values[-1])

    def visit_look(self, name: str) -> None:
        if name in self.seen_looks:
            return
        self.seen_looks.add(name)
        found = self.lookup(self.universe.looks, "look", name)
        if found is None:
            return
        previous = self.context
        self.context = f"look {name}"
        for part in found.values[-1]:
            self.visit_part(name, part)
        self.context = previous

    # Phần của look: ImagerySection chỉ tới được qua Section, StateImagery chỉ kéo theo Section;
    # mọi phần khác (Child, NamedArea, Property...) luôn được quét.
    def visit_part(self, look: str, part: Element) -> None:
        if part.tag == "ImagerySection":
            return
        if part.tag == "StateImagery":
            for section in part.iter("Section"):
                owner = attribute(section, "look") or look
                self.visit_section(owner, attribute(section, "section") or "")
            return
        if part.tag == "Child":
            self.visit_type(attribute(part, "type") or "")
        for element in part.iter():
            self.scan(element)

    def visit_section(self, owner: str, name: str) -> None:
        if (owner, name) in self.seen_sections:
            return
        self.seen_sections.add((owner, name))
        found = self.lookup(self.universe.looks, "look", owner)
        if found is None:
            return
        section = self.lookup_section(found.values[-1], owner, name)
        if section is None:
            return
        previous = self.context
        self.context = f"section {owner}/{name}"
        for element in section.iter():
            self.scan(element)
        self.context = previous

    def lookup_section(self, look: Element, owner: str, name: str) -> Element | None:
        found = self.universe.section_table(look).find(name)
        if found is None:
            self.miss("section", f"{owner}/{name}")
            return None
        if found.is_folded:
            self.folded[("section", f"{owner}/{name}")] += 1
        return found.values[-1]

    def scan(self, element: Element) -> None:
        set_name = attribute(element, "imageset")
        image_name = attribute(element, "image")
        if set_name is not None or image_name is not None:
            self.take_image(set_name or "", image_name or "")
        for value in element.attrib.values():
            self.take_value(value)
        self.take_keys(element)
        if self.is_extended and element.tag in PROPERTY_TAGS:
            self.take_extended(element)

    def take_value(self, value: str) -> None:
        if "image:" not in value:
            return
        matches = list(IMAGE_REF.finditer(value))
        for match in matches:
            self.take_image(match.group(1), match.group(2))
        if not matches:
            self.malformed[clip(value.strip(), 60)] += 1

    def take_keys(self, element: Element) -> None:
        collect_keys(element, self.keys)

    def take_image(self, set_name: str, image_name: str) -> None:
        if not set_name and not image_name:
            self.empty_refs += 1
            return
        found = self.lookup(self.universe.imagesets, "bộ ảnh", set_name)
        if found is None:
            return
        for definition in found.values:
            match = definition.images.find(image_name)
            if match is not None:
                self.use_image(found.key, match.key, definition, match.values[-1])
                return
        self.miss("ảnh", f"{set_name}/{image_name}")

    def use_image(self, set_key: str, image_key: str, definition: ImagesetDef, rect) -> None:
        self.used_images.setdefault(set_key, set()).add(image_key)
        key = definition.imagefile.lower()
        use = self.textures.get(key)
        if use is None:
            use = self.new_texture(definition.imagefile, "texture")
            self.textures[key] = use
        elif use.imagefile != definition.imagefile:
            self.spelling_conflicts.add(f"{use.imagefile} / {definition.imagefile}")
        if rect is not None:
            use.right = max(use.right, rect[0] + rect[2])
            use.bottom = max(use.bottom, rect[1] + rect[3])

    def new_texture(self, imagefile: str, kind: str) -> TextureUse:
        real, is_folded = self.universe.find_texture(imagefile)
        if real is None:
            self.miss(kind, imagefile)
        elif is_folded:
            self.folded[(kind, imagefile)] += 1
        return TextureUse(imagefile, real, is_folded)

    # Cạnh mở rộng. Giá trị trong Property của layout hay look.
    def take_extended(self, element: Element) -> None:
        name = (attribute(element, "name") or "").strip().lower()
        value = property_value(element).strip()
        if not value:
            return
        token = ANIMATION_TOKEN.search(value)
        if token is not None:
            self.visit_animation(token.group(1))
        elif name in ANIMATION_PROPERTIES:
            self.visit_animation(value)
        if name == "font":
            self.visit_font(value)
        elif name == "segmentwidgettype":
            self.visit_type(value)
        elif name == "childitem":
            item = ITEM_TYPE_TOKEN.search(value)
            self.visit_type("" if item is None else item.group(1))
        if DIRECT_TEXTURE.fullmatch(value):
            self.visit_direct_texture(value)

    def visit_animation(self, name: str) -> None:
        if name in self.seen_animations:
            return
        self.seen_animations.add(name)
        found = self.lookup(self.universe.animations, "hoạt ảnh", name)
        if found is None:
            return
        previous = self.context
        self.context = f"hoạt ảnh {name}"
        for element in found.values[-1].iter():
            self.scan(element)
        self.context = previous

    def visit_font(self, name: str) -> None:
        if name in self.seen_fonts:
            return
        self.seen_fonts.add(name)
        found = self.lookup(self.universe.fonts, "phông", name)
        if found is not None and self.universe.files.find(found.values[-1])[0] is None:
            self.miss("tệp phông", found.values[-1])

    def visit_direct_texture(self, imagefile: str) -> None:
        key = imagefile.lower()
        if key not in self.direct_textures:
            self.direct_textures[key] = self.new_texture(imagefile, "tệp ảnh")

    # Ảnh phải nằm gọn trong texture: mép phải và dưới xa nhất của các ảnh dùng tới.
    def finish(self) -> None:
        for use in self.textures.values():
            size = None if use.real is None else self.universe.texture_size(use.real)
            if size is None or (use.right <= size[0] and use.bottom <= size[1]):
                continue
            reach = f"ảnh tới {use.right:g}x{use.bottom:g}, texture {size[0]}x{size[1]}"
            self.context = "texture"
            self.miss("vượt biên", f"{use.imagefile}: {reach}")

    def image_count(self) -> int:
        return sum(len(names) for names in self.used_images.values())


class Workspace:
    def __init__(self, raw_root: str, data_root: str, i18n_root: str | None = None):
        self.raw_root = raw_root
        self.data_root = data_root
        self.raw_files = FileIndex(os.path.join(raw_root, INTERFACE))
        self.data_files = FileIndex(os.path.join(data_root, INTERFACE))
        self.i18n_root = i18n_root or ""
        records = build_i18n.read_records(Path(i18n_root)) if i18n_root else {}
        # Khoá là tên PNG dưới Interface viết thường: sổ ghi tên atlas theo bộ ảnh, có thể khác
        # hoa/thường với tên tệp trên đĩa.
        self.localized = {atlas.lower() + ".png": record for atlas, record in records.items()}

    @functools.cached_property
    def data_universe(self) -> Universe:
        return Universe(self.data_files, "gom", ".png")

    @functools.cached_property
    def raw_universe(self) -> Universe:
        return Universe(self.raw_files, "gốc", "")

    @functools.cached_property
    def data_layouts(self) -> list[str]:
        return sorted(name for name in self.data_files.names if name.endswith(".layout.xml"))

    @functools.cached_property
    def raw_layouts(self) -> list[str]:
        layouts = []
        for relative in self.data_layouts:
            real, _ = self.raw_files.find(relative)
            if real is not None:
                layouts.append(real)
        return layouts

    def walk(self, universe: Universe, layouts: list[str], is_extended: bool) -> Walker:
        walker = Walker(universe, is_extended)
        for relative in layouts:
            walker.walk(relative)
        walker.finish()
        return walker

    @functools.cached_property
    def strict_data(self) -> Walker:
        return self.walk(self.data_universe, self.data_layouts, False)

    @functools.cached_property
    def strict_raw(self) -> Walker:
        return self.walk(self.raw_universe, self.raw_layouts, False)

    @functools.cached_property
    def extended_data(self) -> Walker:
        return self.walk(self.data_universe, self.data_layouts, True)

    @functools.cached_property
    def extended_raw(self) -> Walker:
        return self.walk(self.raw_universe, self.raw_layouts, True)

    def raw_table(self, parts: tuple[str, str]) -> dbc.Dbc:
        return dbc.read(os.path.join(self.raw_root, *parts), parts[1])


# Mốc: mục 1 TỆP


def verify_binary_copies(workspace: Workspace, check: Check) -> int:
    same = 0
    for relative in sorted(workspace.data_files.names):
        origin = find_origin(workspace.raw_files, relative)
        if kind_of(relative) != "bin" or origin is None:
            continue
        is_same = read_bytes(workspace.data_files.path(relative)) == read_bytes(
            workspace.raw_files.path(origin.sources[0]))
        same += is_same
        if not is_same:
            check.fail("chép khác nguồn", relative, f"khác byte với {origin.sources[0]}")
    return same


# Phông dẫn xuất tự tính lại: nối mảnh nguồn rồi XOR; khác byte với tệp trong dữ liệu là lỗi.
def verify_derived_fonts(workspace: Workspace, check: Check) -> int:
    same = 0
    for lower, (pieces, key) in DERIVED_FONTS.items():
        real, _ = workspace.data_files.find(lower)
        origin = derived_origin(workspace.raw_files, pieces)
        if real is None or origin is None:
            continue
        joined = b"".join(read_bytes(workspace.raw_files.path(piece)) for piece in origin.sources)
        expected = joined.translate(bytes(value ^ key for value in range(256)))
        is_same = read_bytes(workspace.data_files.path(real)) == expected
        same += is_same
        if not is_same:
            detail = f"khác bản tự tính {len(expected)} byte (XOR {key:#x})"
            check.fail("phông dẫn xuất sai", real, detail)
    return same


@dataclass(frozen=True)
class FontTag:
    name: str
    size: float
    codepage: int
    pieces: tuple[str, ...]


@dataclass(frozen=True)
class FontRow:
    name: str
    size: float
    codepage: int
    file: str


def split_pieces(filename: str) -> tuple[str, ...]:
    return tuple(part.strip().replace("\\", "/") for part in filename.split("|"))


def font_tags(workspace: Workspace) -> list[FontTag]:
    tags = []
    names = sorted(name for name in workspace.data_files.names if name.lower().endswith(".font"))
    for relative in names:
        decoded = decode_xml_bytes(read_bytes(workspace.data_files.path(relative)))
        for element in parse_xml(decoded.text, relative).iter("Font"):
            size = float(element.get("Size", "0"))
            codepage = int(element.get("CodePage", "0"))
            pieces = split_pieces(element.get("Filename", ""))
            tags.append(FontTag(element.get("Name", ""), size, codepage, pieces))
    return tags


def font_row(header: list[str], cells: list[str]) -> FontRow:
    row = dict(zip(header, cells))
    return FontRow(row["name"], float(row["size"]), int(row["codepage"]), row["file"])


# Ô file rỗng chỉ đúng khi có mảnh nguồn thiếu trong gốc; ô có tên thì tệp phải có trong dữ liệu.
def verify_font_row(workspace: Workspace, check: Check, row: FontRow, tags: list[FontTag]) -> None:
    if row.file:
        if workspace.data_files.find(row.file)[0] is None:
            check.fail("fonts.tsv trỏ tệp không có", row.name, row.file)
        return
    same_font = [tag for tag in tags if (tag.name, tag.codepage) == (row.name, row.codepage)]
    pieces = same_font[0].pieces if same_font else ()
    if pieces and all(workspace.raw_files.find(piece)[0] is not None for piece in pieces):
        check.fail("fonts.tsv bỏ trống file dù nguồn có đủ", row.name, "|".join(pieces))


# fonts.tsv phải có đúng một dòng cho mỗi thẻ <Font> của các tệp .font đã gom.
def verify_font_table(workspace: Workspace, check: Check) -> int:
    real, _ = workspace.data_files.find(FONTS_TABLE)
    if real is None:
        check.fail("thiếu bảng phông", FONTS_TABLE)
        return 0
    table = read_tsv(workspace.data_files.path(real))
    try:
        rows = [font_row(table.header, cells) for cells in table.rows]
    except (KeyError, ValueError) as error:
        check.fail("fonts.tsv sai cột hay kiểu số", FONTS_TABLE, f"{type(error).__name__}: {error}")
        return 0
    tags = font_tags(workspace)
    wanted = Counter((tag.name, tag.codepage, tag.size) for tag in tags)
    found = Counter((row.name, row.codepage, row.size) for row in rows)
    if wanted != found:
        check.fail("fonts.tsv lệch thẻ Font", FONTS_TABLE, f"{len(rows)} dòng, {len(tags)} thẻ")
    for row in rows:
        verify_font_row(workspace, check, row, tags)
    return len(rows)


def check_files(workspace: Workspace) -> Check:
    check = Check("1. TỆP")
    kinds: Counter = Counter()
    ways: Counter = Counter()
    sources: Counter = Counter()
    cases = 0
    for relative in sorted(name for name in workspace.data_files.names if name != LISTING):
        kinds[kind_of(relative)] += 1
        origin = find_origin(workspace.raw_files, relative)
        if origin is None:
            check.fail("mồ côi", relative, "không có nguồn trong gốc")
            continue
        ways[origin.way] += 1
        if origin.way == "bỏ .png":
            sources[os.path.splitext(origin.sources[0])[1].lower()] += 1
        cases += origin.is_case_different
        if origin.is_case_different:
            check.note("khác hoa/thường", relative, f"nguồn {origin.sources[0]}")
    copies = verify_binary_copies(workspace, check)
    derived = verify_derived_fonts(workspace, check)
    font_rows = verify_font_table(workspace, check)
    errors = check.count("FAIL")
    check.info("loại tệp", "", join_counts(kinds))
    check.info("nguồn của PNG", "", join_counts(sources))
    check.summary = (
        f"{sum(kinds.values())} tệp (trừ {LISTING}), nguồn {join_counts(ways)}; khác hoa/thường "
        f"{cases}; bin chép đúng byte {copies}, phông dẫn xuất khớp tự tính "
        f"{derived}/{len(DERIVED_FONTS)}, dòng fonts.tsv kiểm {font_rows}; lỗi {errors}")
    return check


# Mốc: mục 2 XML


@dataclass
class XmlStats:
    compared: int = 0
    elements: int = 0
    different: int = 0
    errors: int = 0
    texts_different: int = 0
    ambiguous: int = 0
    gbk_gaps: int = 0
    encodings: Counter = field(default_factory=Counter)


def read_data_xml(check: Check, relative: str, data: bytes) -> tuple[str, Element] | None:
    if data.startswith(codecs.BOM_UTF8):
        check.fail("bản gom có BOM", relative, "phải là UTF-8 không BOM")
    try:
        text = data.decode("utf-8")
        name = declared_encoding(data)
        if name is not None and name not in ("utf-8", "utf8"):
            check.fail("bản gom khai báo bảng mã khác UTF-8", relative, name)
        return text, parse_xml(text, relative)
    except (UnicodeError, VerifyError) as error:
        check.fail("bản gom không đọc được", relative, str(error))
        return None


# Khác biệt đầu tiên của một tệp đã lọc so với gốc, hoặc None: mỗi phần tử con của bản gom phải
# giống hệt phần tử cùng Name của gốc (Name lặp ở gốc thì dòng gặp trước), không thừa phần tử lạ.
def filtered_difference(raw_root: Element, data_root: Element) -> str | None:
    if raw_root.tag != data_root.tag:
        return f"thẻ gốc {raw_root.tag!r} khác {data_root.tag!r}"
    originals: dict[str, Element] = {}
    for element in raw_root:
        originals.setdefault(element.get("Name", ""), element)
    for element in data_root:
        name = element.get("Name", "")
        origin = originals.get(name)
        if origin is None:
            return f"{name}: không có trong tệp gốc"
        found = first_difference(origin, element)
        if found is not None:
            return found
    return None


def compare_xml_file(workspace: Workspace, check: Check, stats: XmlStats, relative: str) -> None:
    origin = find_origin(workspace.raw_files, relative)
    if origin is None:
        return
    raw_bytes = read_bytes(workspace.raw_files.path(origin.sources[0]))
    try:
        decoded = decode_xml_bytes(raw_bytes)
        raw_root = parse_xml(decoded.text, relative)
    except VerifyError as error:
        stats.errors += 1
        check.fail("bản gốc không đọc được", relative, str(error))
        return
    gathered = read_data_xml(check, relative, read_bytes(workspace.data_files.path(relative)))
    stats.encodings[decoded.how] += 1
    if gathered is None:
        stats.errors += 1
        return
    stats.compared += 1
    stats.elements += count_elements(raw_root)
    is_filtered = relative.lower() == ANIMATE_FILE.lower()
    compare = filtered_difference if is_filtered else first_difference
    found = compare(raw_root, gathered[1])
    if found is not None:
        stats.different += 1
        check.fail("cây XML khác", relative, found)
    if not is_filtered and strip_declaration(decoded.text) != strip_declaration(gathered[0]):
        stats.texts_different += 1
        check.note("văn bản khác từng ký tự (cây giống)", relative, "ngoài dòng khai báo")
    note_encoding_risk(check, stats, relative, decoded, raw_bytes)


# Đoạn chữ đầu tiên ngoài ASCII giải theo hai bảng mã, để người đọc tự thấy bảng nào ra chữ thật.
def ambiguity_sample(data: bytes) -> str:
    start = next(position for position, value in enumerate(data) if value >= 0x80)
    chunk = data[start:start + 30]
    as_utf8 = chunk.decode("utf-8", errors="ignore")[:8]
    as_chinese = chunk.decode("gb18030", errors="ignore")[:8]
    return f"utf-8 {as_utf8!r} | gb18030 {as_chinese!r}"


def note_encoding_risk(check: Check, stats: XmlStats, relative: str, decoded: Decoded,
                       raw_bytes: bytes) -> None:
    if decoded.how in ("utf-8 ngoài ASCII", "gb18030") and is_ambiguous(raw_bytes):
        stats.ambiguous += 1
        check.note("bảng mã mơ hồ", relative, f"chọn {decoded.how}; {ambiguity_sample(raw_bytes)}")
    if decoded.how == "gb18030" and gbk_differs(raw_bytes):
        stats.gbk_gaps += 1
        check.note("GBK khác GB18030", relative, "bộ gom dùng GBK")


def check_xml(workspace: Workspace) -> Check:
    check = Check("2. XML")
    stats = XmlStats()
    for relative in sorted(name for name in workspace.data_files.names if is_xml_file(name)):
        compare_xml_file(workspace, check, stats, relative)
    check.summary = (
        f"so {stats.compared} tệp ({stats.elements} phần tử), cây khác {stats.different}, "
        f"không đọc được {stats.errors}; bảng mã gốc: {join_counts(stats.encodings)}; "
        f"văn bản khác từng ký tự {stats.texts_different}, bảng mã mơ hồ {stats.ambiguous}, "
        f"GBK khác GB18030 {stats.gbk_gaps}")
    return check


# Mốc: mục 3 TEXTURE


@dataclass
class GroupStats:
    is_lossy: bool
    files: int = 0
    same_size: int = 0
    pixels: int = 0
    differing: int = 0
    over_limit: int = 0
    max_diff: np.ndarray = field(default_factory=lambda: np.zeros(4, dtype=np.int64))
    sum_diff: np.ndarray = field(default_factory=lambda: np.zeros(4, dtype=np.int64))
    mips: Counter = field(default_factory=Counter)
    flags: Counter = field(default_factory=Counter)

    @property
    def limit(self) -> int:
        return BCN_TOLERANCE if self.is_lossy else 0

    def add(self, expected: np.ndarray, actual: np.ndarray) -> int:
        diff = np.abs(expected.astype(np.int16) - actual.astype(np.int16)).reshape(-1, 4)
        self.pixels += diff.shape[0]
        self.differing += int(np.count_nonzero(diff.any(axis=1)))
        self.over_limit += int(np.count_nonzero((diff > self.limit).any(axis=1)))
        self.max_diff = np.maximum(self.max_diff, diff.max(axis=0))
        self.sum_diff += diff.sum(axis=0, dtype=np.int64)
        return int(diff.max())


def describe_group(stats: GroupStats) -> str:
    worst = " ".join(f"{name}{int(value)}" for name, value in zip("RGBA", stats.max_diff))
    means = stats.sum_diff / max(stats.pixels, 1)
    mean_text = " ".join(f"{name}{value:.4f}" for name, value in zip("RGBA", means))
    limit = "khớp tuyệt đối" if stats.limit == 0 else f"ngưỡng ≤ {stats.limit}"
    mips = ", ".join(f"{level} mức x{count}" for level, count in sorted(stats.mips.items()))
    flags = ", ".join(f"{text} x{count}" for text, count in sorted(stats.flags.items()) if text)
    return (f"{stats.files} tệp, cùng kích thước {stats.same_size}/{stats.files}; lệch tối đa "
            f"{worst}; trung bình {mean_text}; điểm ảnh lệch {stats.differing}/{stats.pixels}, "
            f"vượt ngưỡng {stats.over_limit} ({limit}); mipmap: {mips}; {flags or 'không có cờ'}")


# PNG đã gom phải là RGBA 8 bit không xen kẽ, đúng lời hứa của bộ gom.
def load_gathered_png(path: str) -> np.ndarray:
    _width, _height, depth, color, interlace = parse_png_header(read_head(path, 29))
    if (depth, color, interlace) != (8, 6, 0):
        raise TextureError(f"PNG không phải RGBA 8 bit (độ sâu {depth}, kiểu màu {color})")
    return pillow_rgba(read_bytes(path))


# TGA có thêm lượt so bộ giải riêng với Pillow: hai đường độc lập phải ra cùng điểm ảnh.
def cross_check_tga(check: Check, source: str, decoded: DecodedImage, relative: str) -> None:
    if not decoded.group.startswith("TGA"):
        return
    theirs = pillow_rgba(read_bytes(source))
    if decoded.pixels.shape != theirs.shape or not np.array_equal(decoded.pixels, theirs):
        check.fail("bộ giải TGA riêng khác Pillow", relative, "hai bộ giải không cùng điểm ảnh")


# Atlas mà build_i18n.py đã thay ảnh không còn khớp kho gốc: bản triển khai phải đúng băm sổ đã
# ghi, còn điểm ảnh đem so với kho gốc là của bản gốc giữ ở thư mục trạng thái.
def original_png(workspace: Workspace, check: Check, relative: str) -> str:
    deployed = workspace.data_files.path(relative)
    record = workspace.localized.get(relative.lower())
    if record is None:
        return deployed
    if build_i18n.digest(read_bytes(deployed)) != record.written:
        check.fail("atlas thay ảnh khác sổ i18n", relative, "dựng lại bằng build_i18n.py")
    check.note("ảnh thay theo ngôn ngữ", relative, "so bằng bản gốc ở thư mục trạng thái i18n")
    return os.path.join(workspace.i18n_root, "base", relative)


def compare_texture(workspace: Workspace, check: Check, groups: dict, relative: str) -> None:
    origin = find_origin(workspace.raw_files, relative)
    if origin is None:
        check.fail("PNG không có nguồn", relative)
        return
    source = workspace.raw_files.path(origin.sources[0])
    try:
        decoded = decode_source(source)
        gathered = load_gathered_png(original_png(workspace, check, relative))
        cross_check_tga(check, source, decoded, relative)
    except (TextureError, OSError, ValueError) as error:
        check.fail("không giải mã được", relative, str(error))
        return
    stats = groups.setdefault(decoded.group, GroupStats(decoded.is_lossy))
    stats.files += 1
    stats.mips[decoded.mip_count] += 1
    stats.flags[decoded.flags_text] += 1
    if decoded.size_note:
        check.note("kích thước tệp nguồn", relative, decoded.size_note)
    record_texture_result(check, stats, relative, decoded, gathered)


def record_texture_result(check: Check, stats: GroupStats, relative: str, decoded: DecodedImage,
                          gathered: np.ndarray) -> None:
    source_size = f"{decoded.pixels.shape[1]}x{decoded.pixels.shape[0]}"
    png_size = f"{gathered.shape[1]}x{gathered.shape[0]}"
    if decoded.pixels.shape != gathered.shape:
        check.fail("khác kích thước", relative, f"nguồn {source_size}, PNG {png_size}")
        return
    stats.same_size += 1
    worst = stats.add(decoded.pixels, gathered)
    check.data("so điểm ảnh", relative, f"{decoded.group} {source_size} lệch tối đa {worst}")
    if worst > stats.limit:
        check.fail("lệch điểm ảnh", relative, f"lệch tối đa {worst}, ngưỡng {stats.limit}")
    elif worst > 0:
        check.note("lệch trong ngưỡng", relative, f"{decoded.group} lệch tối đa {worst}")


def check_textures(workspace: Workspace) -> Check:
    check = Check("3. TEXTURE")
    failures = self_test()
    for failure in failures:
        check.fail("tự kiểm bộ giải mã", failure)
    oracle_check(check, workspace.raw_files)
    groups: dict[str, GroupStats] = {}
    pngs = sorted(name for name in workspace.data_files.names if name.lower().endswith(".png"))
    for relative in pngs:
        compare_texture(workspace, check, groups, relative)
    for name, stats in sorted(groups.items()):
        check.info("nhóm " + name, "", describe_group(stats))
    compared = sum(stats.same_size for stats in groups.values())
    over_limit = sum(stats.over_limit for stats in groups.values())
    swapped = sum(1 for name in pngs if name.lower() in workspace.localized)
    check.summary = (
        f"{compared}/{len(pngs)} PNG RGBA8 cùng kích thước nguồn, {len(groups)} nhóm "
        f"({', '.join(sorted(groups))}); lệch vượt ngưỡng {over_limit} điểm ảnh; {swapped} atlas "
        f"mang ảnh thay theo ngôn ngữ; tự kiểm bộ giải mã "
        f"{len(SELF_TESTS) - len(failures)}/{len(SELF_TESTS)} ca")
    return check


# Mốc: mục 4 và 4b BAO ĐÓNG


# Tham chiếu hỏng của bản gom chia theo bản gốc: hỏng cả ở gốc là ghi chú, còn lại là mất do gom.
def classify_unresolved(check: Check, data: Walker, raw: Walker, excluded: set) -> tuple[int, int]:
    lost = 0
    broken = 0
    for key in sorted(set(data.unresolved) - excluded):
        subject = f"{key[0]} {key[1]}"
        detail = f"{data.unresolved[key]} lần, từ {data.origins[key]}"
        if key in raw.unresolved:
            check.note("hỏng cả ở gốc", subject, detail)
            broken += 1
        else:
            check.fail("mất do gom", subject, detail)
            lost += 1
    return lost, broken


# Lỗi nạp schema của bản gom chỉ là lỗi khi gốc nạp được cùng tệp đó.
def report_universe(check: Check, workspace: Workspace) -> None:
    data = workspace.data_universe
    raw = workspace.raw_universe
    for error in data.errors:
        status = check.note if error in raw.errors else check.fail
        status("tệp schema không đọc được", error)
    for filename in data.absent_look_files:
        status = check.note if filename in raw.absent_look_files else check.fail
        status("scheme nêu looknfeel không có tệp", filename)
    listed = {name.lower() for name in data.look_files}
    for name in data.files.direct_children(SCHEMA, ".looknfeel.xml"):
        if name.lower() not in listed:
            check.note("looknfeel có tệp mà scheme không nêu", name)
    if data.malformed_rects:
        check.note("ảnh trong imageset có toạ độ không phải số", f"{data.malformed_rects} ảnh")
    check.info("tệp nạp", "", f"scheme {len(data.scheme_files)}, looknfeel {len(data.look_files)}, "
               f"imageset {len(data.imageset_files)}, tệp hoạt ảnh {len(data.animation_files)}, "
               f"phông trong scheme {len(data.fonts.items)}")


def report_duplicates(check: Check, universe: Universe) -> None:
    tables = universe.mappings.items
    repeated = [name for name, looks in tables.items() if len(looks) > 1]
    conflicts = [name for name in repeated if len(set(tables[name])) > 1]
    detail = f"khác look: {', '.join(conflicts) or 'không'}; bộ duyệt lấy khai báo sau"
    check.note("mapping kiểu khai báo lặp", f"{len(repeated)} kiểu", detail)
    for name, definitions in universe.imagesets.items.items():
        if len(definitions) > 1:
            same = len({definition.imagefile for definition in definitions}) == 1
            note = "giống" if same else "KHÁC"
            check.note("bộ ảnh trùng tên", name, f"{len(definitions)} nơi, Imagefile {note}")


# Ca chỉ chạy được nhờ bỏ phân biệt hoa/thường: êm trên Windows, nguy cơ trên Android.
def note_fragile_references(check: Check, walker: Walker) -> None:
    for key, count in sorted(walker.folded.items()):
        check.note("chỉ khớp khi bỏ hoa/thường", f"{key[0]} {key[1]}", f"{count} lần")
    for value, count in walker.malformed.items():
        check.note("giá trị ảnh sai dạng", value, f"{count} lần")
    for conflict in sorted(walker.spelling_conflicts):
        check.note("texture viết hai kiểu hoa/thường", conflict)


def used_textures(walker: Walker) -> list[TextureUse]:
    return list(walker.textures.values()) + list(walker.direct_textures.values())


def note_stale_textures(check: Check, workspace: Workspace) -> int:
    needed = set()
    for walker in (workspace.strict_data, workspace.extended_data):
        needed.update(use.real for use in used_textures(walker) if use.real is not None)
    pngs = [name for name in workspace.data_files.names if name.lower().endswith(".png")]
    stale = sorted(name for name in pngs if name not in needed)
    for name in stale:
        check.note("PNG không thuộc bao đóng nào", name, "còn sót từ lượt gom khác?")
    return len(stale)


# (kiểu có mapping, kiểu dựng sẵn, kiểu thiếu) trong các kiểu đã duyệt.
def count_types(walker: Walker) -> tuple[int, int, int]:
    missing = sum(1 for kind, _ in walker.unresolved if kind == "kiểu")
    builtin = len(walker.builtin_types)
    return len(walker.seen_types) - builtin - missing, builtin, missing


def closure_counts(walker: Walker) -> str:
    mapped, builtin, missing = count_types(walker)
    sets = walker.universe.imagesets.items
    total_images = sum(len(definitions[0].images.items) for definitions in sets.values())
    return (f"kiểu {len(walker.seen_types)} (mapping {mapped}, dựng sẵn {builtin}, thiếu "
            f"{missing}), look {len(walker.seen_looks)}, section {len(walker.seen_sections)}, ảnh "
            f"dùng {walker.image_count()}/{total_images}, bộ ảnh dùng {len(walker.used_images)}/"
            f"{len(sets)}, texture {len(walker.textures)}, tham chiếu ảnh rỗng {walker.empty_refs}")


def check_closure(workspace: Workspace) -> Check:
    check = Check("4. BAO ĐÓNG")
    data = workspace.strict_data
    raw = workspace.strict_raw
    report_universe(check, workspace)
    for error in data.layout_errors:
        check.fail("layout đã gom không đọc được", error)
    lost, broken = classify_unresolved(check, data, raw, set())
    for key in sorted(set(raw.unresolved) - set(data.unresolved)):
        check.note("chỉ hỏng ở gốc", f"{key[0]} {key[1]}", "bản gom không gặp")
    report_duplicates(check, workspace.data_universe)
    note_fragile_references(check, data)
    stale = note_stale_textures(check, workspace)
    check.info("bao đóng bản gom", "", closure_counts(data))
    check.info("bao đóng bản gốc", "", closure_counts(raw))
    check.summary = (
        f"{data.layouts} layout: kiểu {len(data.seen_types)}, look {len(data.seen_looks)}, "
        f"section {len(data.seen_sections)}, ảnh {data.image_count()}, bộ ảnh "
        f"{len(data.used_images)}, texture {len(data.textures)}; hỏng cả ở gốc {broken}, mất do "
        f"gom {lost}; khớp nhờ bỏ hoa/thường {len(data.folded)}; PNG thừa {stale}")
    return check


# Texture mà bản gốc cần nhưng dữ liệu không có PNG tương ứng.
def missing_textures(workspace: Workspace, walker: Walker) -> list[str]:
    missing = []
    for use in sorted(used_textures(walker), key=lambda item: item.imagefile.lower()):
        real, _ = workspace.data_universe.find_texture(use.imagefile)
        if use.real is not None and real is None:
            missing.append(use.imagefile)
    return missing


def check_extended(workspace: Workspace) -> Check:
    check = Check("4b. BAO ĐÓNG MỞ RỘNG")
    data = workspace.extended_data
    raw = workspace.extended_raw
    lost, broken = classify_unresolved(check, data, raw, set(workspace.strict_data.unresolved))
    in_chain = set(workspace.strict_raw.textures)
    reported = {key[1].lower() for key in data.unresolved if key[0] in ("texture", "tệp ảnh")}
    missing = missing_textures(workspace, raw)
    lost_textures = [name for name in missing if name.lower() not in in_chain | reported]
    for name in lost_textures:
        check.fail("texture cần mà không có PNG", name, "do cạnh mở rộng của bản gốc")
    found = sum(1 for name in data.seen_animations if ("hoạt ảnh", name) not in data.unresolved)
    dynamic = len(data.seen_types) - len(workspace.strict_data.seen_types)
    edges = (f"hoạt ảnh {len(data.seen_animations)} (giải được {found}), phông "
             f"{len(data.seen_fonts)}, đường dẫn ảnh trực tiếp {len(data.direct_textures)}, kiểu "
             f"nạp động {dynamic}")
    check.info("cạnh mở rộng", "", edges)
    check.summary = (f"{edges}; hỏng cả ở gốc {broken}, mất do gom {lost}; texture cần thêm mà "
                     f"thiếu PNG {len(lost_textures)}")
    return check


# Mốc: bảng TSV (mục 5)


@dataclass
class Tsv:
    header: list[str]
    rows: list[list[str]]


# Bảng theo tsv.hpp của client: dòng # là chú thích, dòng đầu còn lại là tên cột.
def read_tsv(path: str) -> Tsv:
    try:
        text = read_bytes(path).decode("utf-8")
    except UnicodeDecodeError as error:
        raise VerifyError(f"{path}: không phải UTF-8: {error}") from error
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    body = [line.split("\t") for line in lines if not line.startswith("#")]
    if not body:
        raise VerifyError(f"{path}: không có dòng tên cột")
    return Tsv(body[0], body[1:])


def table_columns(check: Check, name: str, table: Tsv, required: tuple[str, ...]) -> bool:
    missing = [column for column in required if column not in table.header]
    if missing:
        check.fail("thiếu cột", name, f"{missing} không có trong {table.header}")
    for number, row in enumerate(table.rows, 1):
        if len(row) != len(table.header):
            check.fail("số ô lệch tên cột", name, f"dòng dữ liệu {number}: {len(row)} ô")
            break
    return not missing


# Danh sách gồm mọi tệp dưới Interface (trừ chính nó) rồi các bảng Table làm đuôi.
def expected_listing(workspace: Workspace) -> set[str]:
    names = {f"{INTERFACE}/{name}" for name in workspace.data_files.names if name != LISTING}
    return names | set(LISTED_TABLES)


def check_listing(workspace: Workspace) -> Check:
    check = Check("5a. DANH SÁCH ui.files.tsv")
    table = read_tsv(workspace.data_files.path(LISTING))
    if not table_columns(check, LISTING, table, ("kind", "path")):
        return check
    listed = [row[table.header.index("path")] for row in table.rows]
    kinds = Counter(row[table.header.index("kind")] for row in table.rows)
    wanted = expected_listing(workspace)
    duplicates = [name for name, count in Counter(listed).items() if count > 1]
    missing = sorted(wanted - set(listed))
    extra = sorted(set(listed) - wanted)
    folded = {name.lower(): name for name in wanted}
    for name in duplicates:
        check.fail("dòng lặp", name)
    for name in missing:
        check.fail("thiếu trong danh sách", name, "có trên đĩa")
    for name in extra:
        spelled = folded.get(name.lower())
        check.fail("thừa trong danh sách", name,
                   f"chỉ khác hoa/thường với {spelled}" if spelled else "không có trên đĩa")
    for table_file in LISTED_TABLES:
        if not os.path.isfile(os.path.join(workspace.data_root, *table_file.split("/"))):
            check.fail("bảng ở đuôi danh sách không có trên đĩa", table_file)
    check.summary = (f"{len(listed)} dòng (kind: {join_counts(kinds)}), mong {len(wanted)}; thiếu "
                     f"{len(missing)}, thừa {len(extra)}, lặp {len(duplicates)}")
    return check


# Ô chuỗi của DBC giải GB18030, tự cắt tại NUL (dbc.py chỉ cho vỏ: cột, ô thô, khối chuỗi).
def dbc_text(table: dbc.Dbc, row: int, column: int) -> str:
    offset = table.cells[row * table.columns + column]
    end = table.strings.find(b"\0", offset)
    if offset >= len(table.strings) or end < 0:
        size = len(table.strings)
        raise VerifyError(f"{table.name}: offset chuỗi {offset} ngoài khối {size} byte")
    return table.strings[offset:end].decode("gb18030")


# Các ô của một dòng InterfaceEx như ui_windows.tsv phải ghi (layout theo tên thật trên đĩa).
def expected_window_row(table: dbc.Dbc, row: int, raw: FileIndex) -> dict[str, str]:
    cells = {}
    for name, column in INTERFACE_EX_COLUMNS.items():
        is_text = table.types[column] == dbc.STRING
        cells[name] = dbc_text(table, row, column) if is_text else str(table.integer(row, column))
    listed = cells["layout"].replace("\\", "/")
    cells["layout"] = raw.find(listed)[0] or listed
    return {name: CELL_BREAKS.sub(" ", cell) for name, cell in cells.items()}


def compare_window_rows(check: Check, workspace: Workspace, table: Tsv, source: dbc.Dbc) -> int:
    column = {name: table.header.index(name) for name in INTERFACE_EX_COLUMNS}
    mismatches = 0
    for number, cells in enumerate(table.rows[:source.rows]):
        expected = expected_window_row(source, number, workspace.raw_files)
        for name, index in column.items():
            if cells[index] == expected[name]:
                continue
            mismatches += 1
            check.fail("ô lệch InterfaceEx", f"dòng {number} cột {name}",
                       f"{clip(cells[index])!r} khác {clip(expected[name])!r}")
        layout = cells[column["layout"]]
        if workspace.raw_files.find(layout) != (layout, False):
            check.fail("layout không đúng tên thật trong gốc", f"dòng {number}", layout)
    return mismatches


def check_windows(workspace: Workspace) -> Check:
    check = Check("5b. BẢNG ui_windows.tsv")
    table = read_tsv(os.path.join(workspace.data_root, *WINDOWS_TABLE.split("/")))
    if not table_columns(check, WINDOWS_TABLE, table, tuple(INTERFACE_EX_COLUMNS)):
        return check
    source = workspace.raw_table(INTERFACE_EX)
    if len(table.rows) != source.rows:
        check.fail("số dòng lệch", WINDOWS_TABLE, f"{len(table.rows)} dòng, nguồn {source.rows}")
    mismatches = compare_window_rows(check, workspace, table, source)
    registered = {row[table.header.index("layout")].lower() for row in table.rows}
    gathered = [name for name in workspace.data_layouts if name.lower() in registered]
    for name in sorted(set(workspace.data_layouts) - set(gathered)):
        check.note("layout đã gom mà không có trong sổ", name)
    check.summary = (f"{len(table.rows)} dòng so với InterfaceEx {source.rows} dòng, ô lệch "
                     f"{mismatches}; layout đã gom có trong sổ {len(gathered)}/"
                     f"{len(workspace.data_layouts)}")
    return check


def dictionary_values(workspace: Workspace) -> dict[str, list[str]]:
    table = workspace.raw_table(STRING_DICTIONARY)
    if table.types != [dbc.STRING, dbc.STRING]:
        raise VerifyError("StrDictionary.txt: không đúng 2 cột chuỗi")
    values: dict[str, list[str]] = defaultdict(list)
    for row in range(table.rows):
        values[dbc_text(table, row, 0)].append(dbc_text(table, row, 1))
    return values


# Mọi khoá #{...} trong layout và looknfeel đã gom, kể cả look không với tới từ layout nào.
def gathered_keys(workspace: Workspace) -> Counter:
    keys: Counter = Counter()
    roots = [workspace.data_universe.tree(name) for name in workspace.data_layouts]
    roots += list(workspace.data_universe.look_roots.values())
    for root in roots:
        for element in root.iter():
            collect_keys(element, keys)
    return keys


def key_is_writable(key: str) -> bool:
    return bool(key) and not key.startswith("#") and CELL_BREAKS.search(key) is None


def verify_key_text(check: Check, key: str, text: str, values: dict) -> str:
    if key not in values:
        check.fail("dòng bảng không có trong StrDictionary", key)
        return "wrong"
    expected = CELL_BREAKS.sub(" ", values[key][-1])
    if text != expected:
        check.fail("chuỗi lệch StrDictionary", key, f"{clip(text)!r} khác {clip(expected)!r}")
        return "wrong"
    return "ok"


# "ok", "wrong" (có dòng mà sai), "lost" hay "lost-outside" (mất do gom, trong hay ngoài bao
# đóng) và "broken" (hỏng cả ở gốc).
def classify_key(check: Check, key: str, rows: dict, values: dict, reachable: set) -> str:
    if key in rows:
        return verify_key_text(check, key, rows[key], values)
    if not key:
        check.note("khoá hỏng cả ở gốc", "#{}", "khoá rỗng")
        return "broken"
    if key not in values:
        check.note("khoá hỏng cả ở gốc", key, "không có trong StrDictionary.txt")
        return "broken"
    where = "trong bao đóng" if key in reachable else "chỉ trong look không với tới từ layout"
    reason = "" if key_is_writable(key) else "; khoá không viết được ra TSV"
    check.fail("khoá mất do gom", key, f"có trong StrDictionary.txt, {where}{reason}")
    return "lost" if key in reachable else "lost-outside"


def check_strings(workspace: Workspace) -> Check:
    check = Check("5c. BẢNG ui_strings.tsv")
    table = read_tsv(os.path.join(workspace.data_root, *STRINGS_TABLE.split("/")))
    if not table_columns(check, STRINGS_TABLE, table, ("key", "text")):
        return check
    key_at = table.header.index("key")
    text_at = table.header.index("text")
    rows = {cells[key_at]: cells[text_at] for cells in table.rows}
    used = gathered_keys(workspace)
    values = dictionary_values(workspace)
    reachable = set(workspace.strict_data.keys)
    verdicts = Counter(classify_key(check, key, rows, values, reachable) for key in sorted(used))
    unused = sorted(set(rows) - set(used))
    for key in unused:
        check.note("dòng không được layout/look đã gom dùng", key)
    for key in sorted(key for key, text in rows.items() if "#{" in text):
        check.note("chuỗi chứa khoá lồng #{...}", key)
    if len(rows) != len(table.rows):
        check.note("khoá lặp trong bảng", f"{len(table.rows) - len(rows)} dòng", "dòng sau thắng")
    in_closure = len(set(used) & reachable)
    lost = verdicts["lost"] + verdicts["lost-outside"]
    check.summary = (f"{len(used)} khoá trong layout/looknfeel đã gom ({in_closure} trong bao "
                     f"đóng), {len(rows)} dòng bảng; mất do gom {lost} (ngoài bao đóng "
                     f"{verdicts['lost-outside']}), hỏng cả ở gốc {verdicts['broken']}, sai "
                     f"{verdicts['wrong']}; dòng thừa {len(unused)}")
    return check


# Mốc: mục 6 --all-raw


KIND_ORDER = (
    "kiểu", "look", "section", "bộ ảnh", "ảnh", "texture", "vượt biên", "hoạt ảnh", "phông",
    "tệp phông", "tệp ảnh",
)


# (số tệp theo đuôi, byte nguồn, byte ước lượng sau khi đổi sang RGBA8 chưa nén).
def texture_totals(walker: Walker) -> tuple[Counter, int, int]:
    kinds: Counter = Counter()
    source_bytes = 0
    pixel_bytes = 0
    uses = {use.real: use for use in used_textures(walker) if use.real is not None}
    for real in uses:
        kinds[os.path.splitext(real)[1].lower().lstrip(".").upper()] += 1
        source_bytes += os.path.getsize(walker.universe.files.path(real))
        size = walker.universe.texture_size(real)
        pixel_bytes += 0 if size is None else size[0] * size[1] * 4
    return kinds, source_bytes, pixel_bytes


def feed_all_layouts(universe: Universe, walkers: tuple[Walker, Walker]) -> tuple[Counter, int]:
    decodings: Counter = Counter()
    errors = 0
    layouts = sorted(name for name in universe.files.names if name.lower().endswith(".layout.xml"))
    for relative in layouts:
        try:
            root, how = universe.load_tree(relative)
        except (VerifyError, OSError) as error:
            errors += 1
            walkers[0].layout_errors.append(f"{relative}: {error}")
            continue
        decodings[how] += 1
        for walker in walkers:
            walker.walk_tree(root, relative)
    return decodings, errors


def describe_unresolved(extended: Walker, kind: str) -> str:
    keys = [key for key in extended.unresolved if key[0] == kind]
    times = sum(extended.unresolved[key] for key in keys)
    sample = ", ".join(clip(key[1], 40) for key in keys[:5])
    return f"{len(keys)} khác nhau, {times} lần" + (f": {sample}" if sample else "")


def check_all_raw(workspace: Workspace) -> Check:
    check = Check("6. TOÀN BỘ GỐC (--all-raw)", is_report_only=True)
    strict = Walker(workspace.raw_universe, False)
    extended = Walker(workspace.raw_universe, True)
    decodings, errors = feed_all_layouts(workspace.raw_universe, (strict, extended))
    strict.finish()
    extended.finish()
    for error in strict.layout_errors:
        check.note("layout gốc không đọc được", error)
    mapped, builtin, missing = count_types(strict)
    check.info("layout", "", f"{strict.layouts} đọc được, {errors} lỗi; bảng mã "
               f"{join_counts(decodings)}; thẻ Window {strict.windows}")
    check.info("kiểu cửa sổ", "", f"{len(strict.seen_types)} khác nhau: mapping {mapped}, dựng "
               f"sẵn {builtin}, thiếu {missing}")
    check.info("bao đóng theo chuỗi mục 4", "", closure_counts(strict))
    for kind in KIND_ORDER:
        check.info("hỏng cả ở gốc", kind, describe_unresolved(extended, kind))
    check.info("chỉ khớp khi bỏ hoa/thường", "", f"{len(extended.folded)} loại tên")
    for label, walker in (("theo chuỗi mục 4", strict), ("cả cạnh mở rộng", extended)):
        kinds, source_bytes, pixel_bytes = texture_totals(walker)
        check.info(f"texture cần {label}", "", f"{sum(kinds.values())} tệp "
                   f"({join_counts(kinds)}), nguồn {megabytes(source_bytes)}, ước lượng PNG RGBA8 "
                   f"{megabytes(pixel_bytes)} (rộng x cao x 4 byte, chưa nén)")
    check.summary = (f"{strict.layouts} layout, {len(used_textures(extended))} texture khi tính cả "
                     "cạnh mở rộng")
    return check


# Mốc: dòng lệnh


STEPS = (
    ("1. TỆP", check_files),
    ("2. XML", check_xml),
    ("3. TEXTURE", check_textures),
    ("4. BAO ĐÓNG", check_closure),
    ("4b. BAO ĐÓNG MỞ RỘNG", check_extended),
    ("5a. DANH SÁCH ui.files.tsv", check_listing),
    ("5b. BẢNG ui_windows.tsv", check_windows),
    ("5c. BẢNG ui_strings.tsv", check_strings),
)


def failure_check(title: str, error: Exception) -> Check:
    frame = traceback.extract_tb(error.__traceback__)[-1]
    check = Check(title)
    check.summary = f"không chạy được: {type(error).__name__}: {error}"
    check.fail("ngoại lệ", f"{os.path.basename(frame.filename)}:{frame.lineno}", str(error))
    return check


def run_step(title: str, function, workspace: Workspace) -> Check:
    started = time.perf_counter()
    try:
        check = function(workspace)
    # Một mục hỏng không được che các mục còn lại; lỗi đi vào báo cáo kèm tệp:dòng.
    except Exception as error:
        check = failure_check(title, error)
    check.seconds = time.perf_counter() - started
    return check


# Khác ổ đĩa thì chắc chắn không nằm trong nhau (commonpath ném ValueError ở ca đó).
def is_inside(path: str, folder: str) -> bool:
    path = os.path.normcase(os.path.abspath(path))
    folder = os.path.normcase(os.path.abspath(folder))
    try:
        return os.path.commonpath([path, folder]) == folder
    except ValueError:
        return False


def run(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    workspace = Workspace(args.raw, args.data, args.i18n)
    print(f"verify_ui: gốc {args.raw}, dữ liệu {args.data}", flush=True)
    steps = list(STEPS)
    if args.all_raw:
        steps.append(("6. TOÀN BỘ GỐC (--all-raw)", check_all_raw))
    checks = []
    for title, function in steps:
        checks.append(run_step(title, function, workspace))
        print_check(checks[-1])
    judged = [check for check in checks if not check.is_report_only]
    failed = [check for check in judged if not check.is_ok]
    elapsed = time.perf_counter() - started
    print(f"TỔNG: {len(judged)} mục, {len(judged) - len(failed)} PASS, {len(failed)} FAIL; "
          f"thời gian {elapsed:.1f} s")
    if args.report:
        write_report(args.report, checks)
        print(f"Đã ghi {args.report}")
    return 1 if failed else 0


class VietnameseParser(argparse.ArgumentParser):
    def error(self, message: str):
        print(f"Cách dùng: {USAGE}", file=sys.stderr)
        self.exit(2, f"Lỗi tham số: {message}\n")


USAGE = ("python verify_ui.py --raw <_raw> --data <CLIENT/data> [--i18n build/i18n] [--all-raw] "
         "[--report <tệp.tsv>]")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = VietnameseParser(prog="verify_ui.py", usage=USAGE,
                              description="Kiểm chứng độc lập giao diện đã gom với kho gốc.")
    parser.add_argument("--raw", required=True, help="kho gốc đã giải gói (_raw)")
    parser.add_argument("--data", required=True, help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("--i18n", help="thư mục trạng thái của build_i18n.py (build/i18n)")
    parser.add_argument("--all-raw", action="store_true", help="thêm số liệu cả kho gốc (mục 6)")
    parser.add_argument("--report", help="ghi mọi dòng chi tiết ra tệp TSV (ngoài raw và data)")
    args = parser.parse_args(argv)
    for name in ("raw", "data"):
        folder = os.path.join(getattr(args, name), INTERFACE)
        if not os.path.isdir(folder):
            parser.error(f"không có thư mục {folder}")
    if args.i18n and not os.path.isdir(args.i18n):
        parser.error(f"không có thư mục {args.i18n}")
    if args.report and (is_inside(args.report, args.raw) or is_inside(args.report, args.data)):
        parser.error("--report không được nằm trong thư mục gốc hay dữ liệu")
    return args


def main() -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    args = parse_args(sys.argv[1:])
    try:
        return run(args)
    except (VerifyError, dbc.DbcError, UnicodeError) as error:
        print(f"Lỗi dữ liệu: {error}", file=sys.stderr)
    except OSError as error:
        print(f"Lỗi tệp: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
