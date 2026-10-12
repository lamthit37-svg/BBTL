"""Giải mã phông giao diện của client Thiên Long Bát Bộ 3.71.9685 (Interface/Schema/*.font).

Cách dùng: python ui_font.py <Interface đã giải gói> <Interface đích>
Cho công cụ khác: collect_fonts(interface_dir, out_interface_dir) -> list[FontEntry]. Đọc mọi
Schema/*.font, ghi vào <đích>/Schema/ các phông đã giải mã (han_main.ttf, latin_sans.ttf), bản chép
nguyên của phông bitmap (GBK12.bin, VTNAM14.bin) và fonts.tsv: mỗi cặp (tên, CodePage) một dòng, cột
name size codepage kind file texture_size note anti_alias (anti_alias thêm ở cuối, 1 hay 0). Mọi tệp
ghi qua tệp tạm rồi đổi tên. Điều dưới đây là số đo trên dữ liệu thật, trừ chỗ ghi "suy đoán".

TỆP .font. Mỗi tệp có hai thẻ <Font> cùng Name: CodePage 936 (Hán) và 1258 (Việt). Thuộc tính: Name,
Filename (các mảnh nối bằng '|'), Size (thực), TextureSize, CodePage, NeedCode (mặc định false),
AntiAlias (mặc định true), Type (FreeType hay Bitmap). Thẻ 1258 của 7 trong 8 tệp trỏ
Schema/tahoma.ttf, tệp này không có trong gói (phông hệ thống): dòng fonts.tsv có file rỗng, note
"thiếu trong gói"; thẻ 1258 của SongTiBmp12 trỏ VTNAM14.bin. Client chọn thẻ theo System_CodePage
(chuỗi có trong Game.exe; System.cfg không đặt nên mặc định 936: suy đoán).

NEEDCODE. Nối các mảnh theo thứ tự trong Filename rồi XOR mọi byte với 0xFE: ra một TTF nguyên vẹn.
Không có xáo trộn, không có khoá đổi theo vị trí. Bằng chứng: 0_FIREFOX_2.bin (4611581 byte) cộng
1_FIREFOX_2.bin (4611579 byte) là 9223160 byte, đúng chỗ bảng DSIG kết thúc theo bảng thư mục TTF;
sau XOR cả 15 bảng đúng checksum, head.magicNumber là 0x5F0F3CF5, checkSumAdjustment đúng, fontTools
mở được (21992 glyph). Trong mã máy: Bin64/CEGUIBase.dll, hàm đọc luồng của FreeType, lệnh
xor byte ptr [rbx], 0xFE (VA 0x180139784) chạy khi cờ NeedCode của phông bật. Công cụ này tự kiểm
checksum trước khi ghi: sai khoá hay dữ liệu hỏng là lỗi, tệp đó không được ghi và fonts.tsv cũng
không được ghi (tệp đã ghi xong trước đó thì còn lại).

PHÔNG TRONG GÓI.
- 0_FIREFOX_2.bin và 1_FIREFOX_2.bin thành han_main.ttf: họ LiSu (隶书, Stone Co. 1996), em 256, 21992
  glyph, phủ trọn GBK (21791/21791) và ASCII, chỉ 11/134 chữ tiếng Việt có dấu. Dùng cho mọi dòng
  CodePage 936 trừ VDA_N và SongTiBmp12.
- 2_FIREFOX.bin thành latin_sans.ttf: TTF thường (không NeedCode), nền Arial của Monotype đổi tên
  Andy_Char, em 2048, 1674 glyph, ASCII đủ, tiếng Việt đủ 134/134, không có chữ Hán. Dùng cho VDA_N
  CodePage 936. Có thể thay tahoma.ttf đang thiếu cho CodePage 1258 (đề xuất, chưa thử trong
  client).
- Timeline/FZLTH-GBK.TTF: TTF thường hợp lệ, dùng thẳng được, không cần giải mã
  (FZLanTingHei-DB-GBK, em 1000, 22035 glyph, GBK đủ, tiếng Việt chỉ 11/134). Không .font nào trỏ
  tới nó, công cụ này không đụng tới nó.
- GBK12.bin (宋体 12 px, CodePage 936) và VTNAM14.bin (Tahoma 14 px, CodePage 1258): bitmap AXFT.
- Cỡ pixel của phông FreeType (suy đoán từ mã máy, chưa đối chiếu ảnh chụp): bản 3.71 gọi
  FT_Set_Char_Size(Size*64, DPI), renderer giữ DPI 96 x 96 (hằng 96.0f trong hàm dựng của
  CEGUIOgreRenderer.dll), nên em gần Size*96/72 px (14.1 thành khoảng 18.8 px).

AXFT (GBK12.bin, VTNAM14.bin). Số little-endian. Hàm nạp: Bin/CEGUIBase.dll tại VA 0x101128F0.
Đầu tệp 164 byte (0xA4):
- 0x00 magic "AXFT". 0x04 phiên bản, bằng 1. 0x08 cỡ glyph px: 12 hoặc 14 hoặc 16 (client từ chối
  cỡ khác; công cụ này còn đòi Size trong .font trùng). 0x0C số dải mã N (31 ở GBK12, 5 ở VTNAM14).
- 0x10 vị trí bảng dải (luôn 0xA4). 0x14 vị trí bảng chỉ mục (0xA4 + 8*N). 0x18 vị trí khối glyph
  (bảng chỉ mục + 0x40000). 0x1C độ dài khối glyph, khối này chạy tới hết tệp. Loader thật không đọc
  ba trường 0x10, 0x14, 0x18: nó đi theo bố cục cố định; ở đây đòi chúng khớp để bắt tệp hỏng.
- 0x20 tên phông UTF-16LE đệm 0 tới 0xA0 ("宋体", "Tahoma"). 0xA0 một u32 bằng 12 ở cả hai tệp,
  loader bỏ qua (nghĩa chưa rõ).
Bảng dải: N mục 8 byte (u16 đầu khối Unicode, u16 mã đầu, u16 mã cuối, u16 bằng 0). Mỗi mã trong
dải có đúng một bản ghi. GBK12 có 24507 mã (Latin tới 1EF9, Hy Lạp, Kirin, dấu câu, ký hiệu, kana,
bopomofo, 4E00-9FBF và các dải tương thích), VTNAM14 có 776 mã (Latin cơ bản, Latin-1, Latin mở
rộng A và B, 1E00-1EF9).
Bảng chỉ mục: đúng 65536 u32, đánh số theo MÃ UTF-16, KHÔNG theo mã GBK hai byte. Giá trị 0xFFFFFFFF
là không có glyph (loader đổi thành con trỏ NULL), còn lại là offset byte trong khối glyph. Muốn
tra theo mã GBK thì đổi sang Unicode bằng codec GBK trước rồi tra bảng này. (Bản 2008 trong _ref
không có đầu tệp, glyph thứ n nằm ở n*18 hay n*32 với n tính từ hai byte GBK; AXFT không dùng cách
đó, nhưng giữ nguyên bố cục điểm ảnh của nó.)
Khối glyph: bản ghi cỡ cố định, offset của chúng lát kín khối: 20 byte ở cỡ 12, 30 byte ở cỡ 14 (34
byte ở cỡ 16 là suy đoán, không có tệp mẫu). Bản ghi:
- u16 advance, bước ngang tính bằng px (GBK12: chữ Hán 12, ASCII 6; VTNAM14: Tahoma tỉ lệ, 2 tới 12,
  riêng '&' có advance 0 dù có bitmap).
- Bitmap, hàng 0 ở trên cùng, cột 0 ở trái, bit 1 là điểm sáng.
  Cỡ 12: 18 byte, 6 cặp hàng, mỗi cặp 3 byte b0 b1 b2. Đặt w = b0 | b1<<8. Hàng chẵn: cột j là bit
  (15-j) của w, j từ 0 tới 11. Hàng lẻ kế đó: cột 0..3 là bit 3..0 của w, cột 4..11 là bit 7..0 của
  b2. Đây đúng là bố cục trong CEGUIFont_Bitmap.cpp 2008.
  Cỡ 14: 14 hàng, mỗi hàng u16 little-endian w, cột j là bit (15-j) của w (byte thứ hai chứa cột
  0..7, byte thứ nhất chứa cột 8..15), cột 14 và 15 luôn 0. Cỡ 16 (suy đoán) cũng vậy với 16 hàng.
- Mã không có glyph thật nhưng nằm trong dải thì mang bản ghi ô vuông chung (981 mã ở GBK12, 165 mã
  ở VTNAM14 cùng một bitmap hình chữ nhật): GBK12 thiếu 46 trong 67 chữ Việt thường, VTNAM14 đủ.
Đặt glyph lên màn hình (suy đoán, chỉ có mã 2008 làm căn cứ, chưa kiểm với 3.71): ảnh glyph rộng
cỡ, cao cỡ + 2, xếp trong atlas; khi vẽ dịch ảnh theo x = -1, y = -(cỡ + 2 - 3) so với điểm bút trên
đường cơ sở rồi đẩy bút đi advance của bản ghi. Số đo trên bitmap: chữ hoa Latin chiếm hàng 3..11
ở VTNAM14 (cỡ 14) và hàng 2..9 ở GBK12 (cỡ 12).
"""

import array
import collections
import dataclasses
import functools
import math
import os
import struct
import sys
import xml.etree.ElementTree as element_tree
from pathlib import Path, PurePosixPath

SCHEMA_FOLDER = "Schema"
FONT_SUFFIX = ".font"
TSV_NAME = "fonts.tsv"
MISSING_NOTE = "thiếu trong gói"
NEED_CODE_KEY = 0xFE
NEED_CODE_TABLE = bytes(value ^ NEED_CODE_KEY for value in range(256))
SFNT_VERSIONS = (b"\x00\x01\x00\x00", b"true", b"OTTO")
HEAD_MAGIC = 0x5F0F3CF5
CHECKSUM_TARGET = 0xB1B0AFBA
HEAD_MIN_BYTES = 54
WORD_CODE = "I" if array.array("I").itemsize == 4 else "L"
KIND_OF_TYPE = {"freetype": "ttf", "bitmap": "bitmap"}
REQUIRED_ATTRIBUTES = ("Name", "Filename", "Size", "TextureSize", "CodePage", "Type")
TSV_COLUMNS = ("name", "size", "codepage", "kind", "file", "texture_size", "note", "anti_alias")
# Tên tệp ghi ra cho hai nguồn đã biết; nguồn lạ lấy tên của mảnh đầu.
OUTPUT_NAMES = {
    ("Schema/0_FIREFOX_2.bin", "Schema/1_FIREFOX_2.bin"): "han_main.ttf",
    ("Schema/2_FIREFOX.bin",): "latin_sans.ttf",
}
# cmap: bảng con Unicode BMP theo thứ tự ưu tiên (nền tảng, mã hoá).
CMAP_PREFERENCE = ((3, 1), (0, 3), (0, 2), (0, 1), (0, 0))
VIETNAMESE_LOWER = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
VIETNAMESE = VIETNAMESE_LOWER + VIETNAMESE_LOWER.upper()

AXFT_MAGIC = b"AXFT"
AXFT_HEADER_BYTES = 0xA4
AXFT_NAME_AT = 0x20
AXFT_RANGE_BYTES = 8
AXFT_INDEX_ENTRIES = 0x10000
AXFT_NO_GLYPH = 0xFFFFFFFF
AXFT_SIZES = (12, 14, 16)
PLACEHOLDER_MIN_REPEATS = 16

# (checksum, offset, độ dài) của một bảng sfnt, và bảng thư mục theo tên bảng.
TableEntry = tuple[int, int, int]
Directory = dict[str, TableEntry]
# Một dải mã AXFT: (đầu khối Unicode, mã đầu, mã cuối, số 0 đệm).
AxftRange = tuple[int, int, int, int]


# Lỗi dữ liệu phông; thông báo đã là tiếng Việt để in thẳng cho người dùng.
class FontError(ValueError):
    pass


@dataclasses.dataclass(frozen=True)
class FontEntry:
    name: str
    size: float
    codepage: int
    kind: str
    # Đường dẫn tương đối thư mục Interface, dấu "/"; rỗng khi tệp thiếu trong gói.
    file: str
    texture_size: int
    note: str
    anti_alias: bool = True


@dataclasses.dataclass(frozen=True)
class FontSpec:
    name: str
    parts: tuple[str, ...]
    size: float
    texture_size: int
    codepage: int
    kind: str
    need_code: bool
    anti_alias: bool


@dataclasses.dataclass(frozen=True)
class TtfInfo:
    glyph_count: int
    units_per_em: int
    family: str
    codepoints: frozenset[int]


@dataclasses.dataclass(frozen=True)
class AxftGlyph:
    advance: int
    # Mỗi hàng là số cỡ bit, cột 0 ở bit cao nhất.
    rows: tuple[int, ...]


@dataclasses.dataclass(frozen=True)
class Axft:
    size: int
    name: str
    ranges: tuple[AxftRange, ...]
    glyph_count: int
    record_bytes: int
    index: array.array
    payload: bytes

    # Glyph của một mã UTF-16; None khi phông không có.
    def glyph(self, code: int) -> AxftGlyph | None:
        if not 0 <= code < AXFT_INDEX_ENTRIES: return None
        offset = self.index[code]
        if offset == AXFT_NO_GLYPH: return None
        record = self.payload[offset:offset + self.record_bytes]
        advance = struct.unpack_from("<H", record, 0)[0]
        return AxftGlyph(advance, glyph_rows(record, self.size))


@dataclasses.dataclass(frozen=True)
class OutputFile:
    relative: str
    size_bytes: int
    summary: str
    is_written: bool


@dataclasses.dataclass(frozen=True)
class BuildResult:
    entries: list[FontEntry]
    outputs: list[OutputFile]
    # Tệp nguồn thiếu trong gói, kèm các dòng "Name/CodePage" cần nó.
    missing: dict[str, list[str]]


@dataclasses.dataclass(frozen=True)
class Product:
    relative: str
    note: str


# Khối: TTF (kiểm cấu trúc, checksum, cmap).

# Giải mã NeedCode: XOR từng byte với 0xFE (bảng tra nên nhanh với tệp chục MB).
def decode_need_code(data: bytes) -> bytes:
    return data.translate(NEED_CODE_TABLE)


# Tổng các từ 32 bit big-endian, đệm 0 cuối, theo đặc tả checksum bảng sfnt.
def checksum_words(data: bytes) -> int:
    padded = data + b"\0" * (-len(data) % 4)
    words = array.array(WORD_CODE)
    words.frombytes(padded)
    if sys.byteorder == "little": words.byteswap()
    return sum(words) & 0xFFFFFFFF


def read_entry(data: bytes, position: int, label: str) -> tuple[str, TableEntry]:
    tag, checksum, offset, length = struct.unpack_from(">4sIII", data, 12 + 16 * position)
    name = tag.decode("latin-1")
    if offset + length > len(data): raise FontError(f"{label}: bảng {name} vượt cuối tệp")
    return name, (checksum, offset, length)


def read_directory(data: bytes, label: str) -> Directory:
    if len(data) < 12 or data[:4] not in SFNT_VERSIONS:
        raise FontError(f"{label}: không phải TTF (đầu tệp {data[:4].hex()})")
    count = struct.unpack_from(">H", data, 4)[0]
    if count == 0 or 12 + 16 * count > len(data):
        raise FontError(f"{label}: bảng thư mục TTF hỏng ({count} bảng)")
    return dict(read_entry(data, position, label) for position in range(count))


# Checksum của một bảng; bảng head tính với checkSumAdjustment đặt về 0.
def verify_table(data: bytes, tag: str, entry: TableEntry, label: str) -> None:
    checksum, offset, length = entry
    chunk = data[offset:offset + length]
    if tag == "head" and length >= HEAD_MIN_BYTES: chunk = chunk[:8] + b"\0\0\0\0" + chunk[12:]
    computed = checksum_words(chunk)
    if computed == checksum: return
    raise FontError(f"{label}: bảng {tag} sai checksum, tính {computed:#x}, ghi {checksum:#x}")


# Kiểm head.magicNumber và checkSumAdjustment của cả tệp.
def verify_whole(data: bytes, tables: Directory, label: str) -> None:
    head = tables.get("head")
    if head is None or head[2] < HEAD_MIN_BYTES: raise FontError(f"{label}: thiếu bảng head")
    offset = head[1]
    magic = struct.unpack_from(">I", data, offset + 12)[0]
    if magic != HEAD_MAGIC: raise FontError(f"{label}: head.magicNumber là {magic:#x}")
    adjustment = struct.unpack_from(">I", data, offset + 8)[0]
    zeroed = data[:offset + 8] + b"\0\0\0\0" + data[offset + 12:]
    expected = (CHECKSUM_TARGET - checksum_words(zeroed)) & 0xFFFFFFFF
    if adjustment != expected:
        raise FontError(f"{label}: checkSumAdjustment {adjustment:#x}, tính ra {expected:#x}")


def segment_codes(cmap: bytes, glyph_base: int, span: tuple[int, int, int]) -> list[int]:
    first, last, delta = span
    codes = range(first, min(last, 0xFFFE) + 1)
    if glyph_base < 0: return [code for code in codes if (code + delta) & 0xFFFF]
    glyphs = struct.unpack_from(f">{len(codes)}H", cmap, glyph_base)
    return [code for code, glyph in zip(codes, glyphs) if glyph and (glyph + delta) & 0xFFFF]


# Các mã có glyph của bảng con định dạng 4 bắt đầu tại start trong cmap.
def codepoints_format4(cmap: bytes, start: int) -> frozenset[int]:
    double = struct.unpack_from(">H", cmap, start + 6)[0]
    count = double // 2
    ends = struct.unpack_from(f">{count}H", cmap, start + 14)
    firsts = struct.unpack_from(f">{count}H", cmap, start + 16 + double)
    deltas = struct.unpack_from(f">{count}H", cmap, start + 16 + 2 * double)
    shifts_at = start + 16 + 3 * double
    shifts = struct.unpack_from(f">{count}H", cmap, shifts_at)
    found: set[int] = set()
    for i in range(count):
        glyph_base = -1 if shifts[i] == 0 else shifts_at + 2 * i + shifts[i]
        found.update(segment_codes(cmap, glyph_base, (firsts[i], ends[i], deltas[i])))
    return frozenset(found)


def read_codepoints(data: bytes, tables: Directory, label: str) -> frozenset[int]:
    entry = tables.get("cmap")
    if entry is None: raise FontError(f"{label}: thiếu bảng cmap")
    cmap = data[entry[1]:entry[1] + entry[2]]
    count = struct.unpack_from(">H", cmap, 2)[0]
    records = {(p, e): o for p, e, o in struct.iter_unpack(">HHI", cmap[4:4 + 8 * count])}
    start = next((records[key] for key in CMAP_PREFERENCE if key in records), None)
    if start is None: raise FontError(f"{label}: cmap không có bảng con Unicode BMP")
    layout = struct.unpack_from(">H", cmap, start)[0]
    if layout != 4: raise FontError(f"{label}: cmap định dạng {layout}, chỉ đọc định dạng 4")
    return codepoints_format4(cmap, start)


def name_rank(record: tuple[int, ...]) -> int:
    platform, language = record[0], record[2]
    if platform == 3 and language == 0x409: return 0
    if platform == 3: return 1
    return 2 if platform == 1 else 3


# Tên họ phông (nameID 1): ưu tiên Windows tiếng Anh Mỹ, rồi Windows khác, Mac, Unicode.
def read_family_name(data: bytes, tables: Directory) -> str:
    entry = tables.get("name")
    if entry is None: return ""
    block = data[entry[1]:entry[1] + entry[2]]
    count, strings_at = struct.unpack_from(">HH", block, 2)
    records = struct.iter_unpack(">6H", block[6:6 + 12 * count])
    found = [r for r in records if r[3] == 1 and strings_at + r[5] + r[4] <= len(block)]
    if not found: return ""
    best = min(found, key=name_rank)
    begin = strings_at + best[5]
    encoding = "mac_roman" if best[0] == 1 else "utf-16-be"
    return block[begin:begin + best[4]].decode(encoding, errors="replace")


def inspect_ttf(data: bytes, label: str) -> TtfInfo:
    tables = read_directory(data, label)
    for tag, entry in tables.items():
        verify_table(data, tag, entry, label)
    verify_whole(data, tables, label)
    maxp = tables.get("maxp")
    if maxp is None or maxp[2] < 6: raise FontError(f"{label}: thiếu bảng maxp")
    glyph_count = struct.unpack_from(">H", data, maxp[1] + 4)[0]
    units_per_em = struct.unpack_from(">H", data, tables["head"][1] + 18)[0]
    family = read_family_name(data, tables)
    codepoints = read_codepoints(data, tables, label)
    return TtfInfo(glyph_count, units_per_em, family, codepoints)


# Kiểm một TTF đã giải: cấu trúc, checksum từng bảng, checksum cả tệp, số glyph, cmap.
def check_ttf(data: bytes, label: str) -> TtfInfo:
    try:
        return inspect_ttf(data, label)
    except (struct.error, IndexError) as error:
        raise FontError(f"{label}: TTF bị cắt cụt hoặc bảng hỏng ({error})") from error


# Khối: AXFT (phông bitmap).

def record_bytes_of(size: int) -> int:
    return 2 + (18 if size == 12 else 2 * size)


# Hàng của bitmap: số cỡ bit, cột 0 ở bit cao nhất (bố cục điểm ảnh ghi ở đầu tệp).
def glyph_rows(record: bytes, size: int) -> tuple[int, ...]:
    if size != 12:
        words = struct.unpack_from(f"<{size}H", record, 2)
        return tuple(word >> (16 - size) for word in words)
    rows: list[int] = []
    for pair in range(6):
        low, high, tail = record[2 + 3 * pair:5 + 3 * pair]
        word = low | (high << 8)
        rows.append(word >> 4)
        rows.append(((word & 0xF) << 8) | tail)
    return tuple(rows)


def read_ranges(data: bytes, start: int, count: int, label: str) -> tuple[AxftRange, ...]:
    ranges = tuple(struct.iter_unpack("<4H", data[start:start + AXFT_RANGE_BYTES * count]))
    inverted = [r for r in ranges if not r[0] <= r[1] <= r[2]]
    if inverted: raise FontError(f"{label}: dải mã AXFT lộn {inverted[0]}")
    return ranges


# Mọi mục chỉ mục phải là "không có glyph" hoặc offset đúng ranh giới một bản ghi trong khối.
def read_index(data: bytes, start: int, sizes: tuple[int, int], label: str) -> array.array:
    record_bytes, payload_bytes = sizes
    index = array.array(WORD_CODE)
    index.frombytes(data[start:start + 4 * AXFT_INDEX_ENTRIES])
    if sys.byteorder == "big": index.byteswap()
    last_start = payload_bytes - record_bytes
    stray = [o for o in index if o != AXFT_NO_GLYPH and (o % record_bytes or o > last_start)]
    if stray: raise FontError(f"{label}: chỉ mục AXFT trỏ ra ngoài khối glyph ({stray[0]})")
    return index


def inspect_axft(data: bytes, label: str) -> Axft:
    if len(data) < AXFT_HEADER_BYTES or data[:4] != AXFT_MAGIC:
        raise FontError(f"{label}: không phải phông AXFT")
    fields = struct.unpack_from("<4sIIIIIII", data, 0)
    version, size, range_count, ranges_at, index_at, payload_at, payload_bytes = fields[1:]
    if version != 1: raise FontError(f"{label}: AXFT phiên bản {version}, chỉ hiểu phiên bản 1")
    if size not in AXFT_SIZES: raise FontError(f"{label}: AXFT cỡ {size}px, chỉ nhận 12 14 16")
    want_index = AXFT_HEADER_BYTES + AXFT_RANGE_BYTES * range_count
    want_payload = want_index + 4 * AXFT_INDEX_ENTRIES
    layout = (ranges_at, index_at, payload_at, payload_at + payload_bytes)
    if layout != (AXFT_HEADER_BYTES, want_index, want_payload, len(data)):
        raise FontError(f"{label}: AXFT lệch bố cục {layout}, tệp dài {len(data)} byte")
    ranges = read_ranges(data, ranges_at, range_count, label)
    glyph_count = sum(r[2] - r[1] + 1 for r in ranges)
    record_bytes = record_bytes_of(size)
    wanted = glyph_count * record_bytes
    if payload_bytes != wanted:
        raise FontError(f"{label}: khối glyph {payload_bytes} byte, cần {wanted} byte")
    index = read_index(data, index_at, (record_bytes, payload_bytes), label)
    name = data[AXFT_NAME_AT:AXFT_HEADER_BYTES - 4].decode("utf-16-le", errors="replace")
    return Axft(size, name.split("\0", 1)[0], ranges, glyph_count, record_bytes, index,
                data[payload_at:])


# Đọc và kiểm một phông AXFT: đầu tệp, bố cục, từng offset trong chỉ mục.
def read_axft(data: bytes, label: str) -> Axft:
    try:
        return inspect_axft(data, label)
    except (struct.error, IndexError) as error:
        raise FontError(f"{label}: AXFT bị cắt cụt hoặc hỏng ({error})") from error


def lit_pixels(glyph: AxftGlyph) -> int:
    return sum(row.bit_count() for row in glyph.rows)


# Chữ 'A' phải có glyph không rỗng và không đặc kín, để bắt khối glyph bị xoá hay hỏng.
def check_axft_sample(font: Axft, label: str) -> None:
    glyph = font.glyph(ord("A"))
    if glyph is None: return
    lit = lit_pixels(glyph)
    is_plausible = 0 < lit < font.size * font.size and 0 < glyph.advance <= font.size
    if not is_plausible: raise FontError(f"{label}: glyph thử 'A' bất thường ({lit} điểm sáng)")


# Khối: số liệu mô tả (phủ ký tự).

def decode_row(first: int) -> list[int]:
    codes: list[int] = []
    for second in range(0xA1, 0xFF):
        text = bytes((first, second)).decode("gb2312", errors="ignore")
        codes.extend(ord(char) for char in text)
    return codes


# Chữ Hán của GB2312 (6763 chữ): hàng 0xB0 tới 0xF7 của bảng mã.
@functools.cache
def gb2312_hanzi() -> frozenset[int]:
    codes: set[int] = set()
    for first in range(0xB0, 0xF8):
        codes.update(decode_row(first))
    return frozenset(codes)


def describe_ttf(info: TtfInfo) -> str:
    hanzi = gb2312_hanzi()
    han = len(info.codepoints & hanzi)
    ascii_count = sum(1 for code in range(0x20, 0x7F) if code in info.codepoints)
    vietnamese = sum(1 for char in VIETNAMESE if ord(char) in info.codepoints)
    return (f"{info.glyph_count} glyph, họ {info.family}, em {info.units_per_em}, "
            f"Hán GB2312 {han}/{len(hanzi)}, ASCII {ascii_count}/95, "
            f"Việt {vietnamese}/{len(VIETNAMESE)}")


# Bitmap lặp nhiều nhất và số lần lặp, khi từ PLACEHOLDER_MIN_REPEATS lần trở lên: đó là ô vuông
# thay thế cho mã nằm trong dải mà phông không có glyph thật.
def find_placeholder(font: Axft) -> tuple[tuple[int, ...], int] | None:
    codes = [code for _, first, last, _ in font.ranges for code in range(first, last + 1)]
    glyphs = [font.glyph(code) for code in codes]
    counts = collections.Counter(glyph.rows for glyph in glyphs if glyph is not None)
    if not counts: return None
    rows, repeats = counts.most_common(1)[0]
    return (rows, repeats) if repeats >= PLACEHOLDER_MIN_REPEATS else None


def describe_axft(font: Axft) -> str:
    placeholder = find_placeholder(font)
    box = None if placeholder is None else placeholder[0]
    repeats = 0 if placeholder is None else placeholder[1]
    glyphs = [font.glyph(ord(char)) for char in VIETNAMESE]
    real = sum(1 for glyph in glyphs if glyph is not None and glyph.rows != box)
    return (f"AXFT {font.name} {font.size}px, {font.glyph_count} glyph, {len(font.ranges)} dải, "
            f"{repeats} mã dùng ô vuông thay thế, Việt thật {real}/{len(VIETNAMESE)}")


# Khối: tệp .font.

def parse_integer(file_name: str, attribute: str, text: str) -> int:
    try:
        value = int(text)
    except ValueError as error:
        raise FontError(f"{file_name}: {attribute}=\"{text}\" không phải số nguyên") from error
    if value <= 0: raise FontError(f"{file_name}: {attribute}={value} phải lớn hơn 0")
    return value


def parse_size(file_name: str, text: str) -> float:
    try:
        value = float(text)
    except ValueError as error:
        raise FontError(f"{file_name}: Size=\"{text}\" không phải số thực") from error
    if not math.isfinite(value) or value <= 0:
        raise FontError(f"{file_name}: Size={text} phải là số thực lớn hơn 0")
    return value


def parse_flag(file_name: str, attribute: str, text: str) -> bool:
    lowered = text.strip().lower()
    if lowered in ("true", "1"): return True
    if lowered in ("false", "0"): return False
    raise FontError(f"{file_name}: {attribute}=\"{text}\" phải là true hoặc false")


def checked_relative(file_name: str, piece: str) -> str:
    path = PurePosixPath(piece)
    is_unsafe = not piece or path.is_absolute() or ".." in path.parts or ":" in piece
    if is_unsafe: raise FontError(f"{file_name}: đường dẫn phông \"{piece}\" không hợp lệ")
    return path.as_posix()


# Filename gồm các mảnh nối bằng '|', mỗi mảnh là đường dẫn tương đối thư mục Interface.
def split_parts(file_name: str, text: str) -> tuple[str, ...]:
    pieces = [piece.strip().replace("\\", "/") for piece in text.split("|")]
    return tuple(checked_relative(file_name, piece) for piece in pieces)


def parse_font_tag(file_name: str, attributes: dict[str, str]) -> FontSpec:
    missing = [key for key in REQUIRED_ATTRIBUTES if key not in attributes]
    if missing: raise FontError(f"{file_name}: thẻ <Font> thiếu thuộc tính {', '.join(missing)}")
    kind = KIND_OF_TYPE.get(attributes["Type"].strip().lower())
    if kind is None: raise FontError(f"{file_name}: Type=\"{attributes['Type']}\" lạ")
    name = attributes["Name"]
    parts = split_parts(file_name, attributes["Filename"])
    size = parse_size(file_name, attributes["Size"])
    texture_size = parse_integer(file_name, "TextureSize", attributes["TextureSize"])
    codepage = parse_integer(file_name, "CodePage", attributes["CodePage"])
    need_code = parse_flag(file_name, "NeedCode", attributes.get("NeedCode", "false"))
    anti_alias = parse_flag(file_name, "AntiAlias", attributes.get("AntiAlias", "true"))
    return FontSpec(name, parts, size, texture_size, codepage, kind, need_code, anti_alias)


def read_font_file(path: Path) -> list[FontSpec]:
    try:
        root = element_tree.parse(path).getroot()
    except (OSError, element_tree.ParseError) as error:
        raise FontError(f"{path.name}: XML hỏng hoặc không đọc được ({error})") from error
    specs = [parse_font_tag(path.name, dict(tag.attrib)) for tag in root.iter("Font")]
    if not specs: raise FontError(f"{path.name}: không có thẻ <Font>")
    return specs


def font_file_order(path: Path) -> str:
    return path.name.lower()


# Mọi Schema/*.font theo tên tệp rồi theo thứ tự thẻ trong tệp; (Name, CodePage) không được trùng.
def read_all_specs(schema_dir: Path) -> list[FontSpec]:
    if not schema_dir.is_dir(): raise FontError(f"không thấy thư mục {schema_dir}")
    candidates = [path for path in schema_dir.iterdir() if path.suffix.lower() == FONT_SUFFIX]
    if not candidates: raise FontError(f"không có tệp {FONT_SUFFIX} nào trong {schema_dir}")
    specs: list[FontSpec] = []
    for path in sorted(candidates, key=font_file_order):
        specs.extend(read_font_file(path))
    keys = [(spec.name, spec.codepage) for spec in specs]
    duplicated = sorted({key for key in keys if keys.count(key) > 1})
    if duplicated: raise FontError(f"trùng phông (Name, CodePage): {duplicated}")
    return specs


# Khối: ghi tệp và dựng bảng.

def has_same_content(path: Path, data: bytes) -> bool:
    try:
        return path.is_file() and path.stat().st_size == len(data) and path.read_bytes() == data
    except OSError:
        return False


# Ghi qua tệp tạm cùng thư mục rồi đổi tên; trả False khi tệp đã có đúng nội dung này.
def write_atomic(path: Path, data: bytes) -> bool:
    if has_same_content(path, data): return False
    temporary = path.with_name(f"{path.name}.{os.getpid()}.tmp")
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary.write_bytes(data)
        os.replace(temporary, path)
    except OSError as error:
        temporary.unlink(missing_ok=True)
        raise FontError(f"không ghi được {path}: {error.strerror}") from error
    return True


def read_bytes(path: Path) -> bytes:
    try:
        return path.read_bytes()
    except OSError as error:
        raise FontError(f"không đọc được {path}: {error.strerror}") from error


def output_name(parts: tuple[str, ...]) -> str:
    known = OUTPUT_NAMES.get(parts)
    if known is not None: return known
    return PurePosixPath(parts[0]).stem.lower() + ".ttf"


def source_key(spec: FontSpec) -> tuple:
    return (spec.parts, spec.need_code, spec.kind)


# Dựng từng nguồn phông một lần rồi dùng lại cho mọi dòng .font cùng nguồn.
class Maker:
    def __init__(self, source: Path, target: Path) -> None:
        self.source = source
        self.target = target
        self.products: dict[tuple, Product] = {}
        self.claimed: dict[str, tuple] = {}
        self.outputs: list[OutputFile] = []
        self.missing: dict[str, list[str]] = {}

    def entry_for(self, spec: FontSpec) -> FontEntry:
        product = self.product_for(spec)
        if not product.relative: self.note_missing(spec)
        return FontEntry(spec.name, spec.size, spec.codepage, spec.kind, product.relative,
                         spec.texture_size, product.note, spec.anti_alias)

    def note_missing(self, spec: FontSpec) -> None:
        label = f"{spec.name}/{spec.codepage}"
        for part in spec.parts:
            self.missing.setdefault(part, []).append(label)

    def product_for(self, spec: FontSpec) -> Product:
        key = source_key(spec)
        if key not in self.products: self.products[key] = self.build(spec)
        return self.products[key]

    def build(self, spec: FontSpec) -> Product:
        paths = [self.source / part for part in spec.parts]
        present = [path.is_file() for path in paths]
        if not any(present): return Product("", MISSING_NOTE)
        joined = "|".join(spec.parts)
        if not all(present): raise FontError(f"{spec.name}: thiếu một mảnh của {joined}")
        payloads = [read_bytes(path) for path in paths]
        if spec.kind == "bitmap": return self.build_bitmap(spec, payloads)
        return self.build_ttf(spec, payloads)

    def build_ttf(self, spec: FontSpec, payloads: list[bytes]) -> Product:
        data = b"".join(payloads)
        if spec.need_code: data = decode_need_code(data)
        label = "|".join(spec.parts)
        info = check_ttf(data, label)
        relative = f"{SCHEMA_FOLDER}/{output_name(spec.parts)}"
        self.store(relative, data, spec, describe_ttf(info))
        names = "|".join(PurePosixPath(part).name for part in spec.parts)
        method = "XOR 0xFE" if spec.need_code else "TTF nguyên bản"
        return Product(relative, f"{method} từ {names}; {info.family}, {info.glyph_count} glyph")

    def build_bitmap(self, spec: FontSpec, payloads: list[bytes]) -> Product:
        label = spec.parts[0]
        if spec.need_code or len(payloads) != 1:
            raise FontError(f"{label}: phông Bitmap chỉ hỗ trợ một mảnh và không NeedCode")
        font = read_axft(payloads[0], label)
        check_axft_sample(font, label)
        if font.size != spec.size:
            raise FontError(f"{label}: AXFT cỡ {font.size}, nhưng .font khai Size {spec.size:g}")
        self.store(label, payloads[0], spec, describe_axft(font))
        return Product(label, f"AXFT {font.name} {font.size}px, {font.glyph_count} glyph")

    def store(self, relative: str, data: bytes, spec: FontSpec, summary: str) -> None:
        key = source_key(spec)
        owner = self.claimed.setdefault(relative, key)
        if owner != key: raise FontError(f"hai nguồn phông khác nhau cùng ghi ra {relative}")
        is_written = write_atomic(self.target / relative, data)
        self.outputs.append(OutputFile(relative, len(data), summary, is_written))


def tsv_cells(entry: FontEntry) -> list[str]:
    anti_alias = "1" if entry.anti_alias else "0"
    return [entry.name, f"{entry.size:.10g}", str(entry.codepage), entry.kind, entry.file,
            str(entry.texture_size), entry.note, anti_alias]


# Văn bản fonts.tsv theo SRC/table/tsv.hpp: dòng đầu là tên cột, ô không chứa tab hay xuống dòng.
def tsv_text(entries: list[FontEntry]) -> str:
    rows = [list(TSV_COLUMNS)] + [tsv_cells(entry) for entry in entries]
    for row in rows:
        if any(char in cell for cell in row for char in "\t\r\n"):
            raise FontError(f"ô TSV chứa tab hoặc xuống dòng: {row}")
    return "".join("\t".join(row) + "\n" for row in rows)


# Giải mã và ghi mọi phông của Schema/*.font; trả các dòng fonts.tsv cùng các tệp đã ghi.
def build_fonts(interface_dir: Path | str, out_interface_dir: Path | str) -> BuildResult:
    source = Path(interface_dir)
    target = Path(out_interface_dir)
    specs = read_all_specs(source / SCHEMA_FOLDER)
    maker = Maker(source, target)
    entries = [maker.entry_for(spec) for spec in specs]
    tsv_path = target / SCHEMA_FOLDER / TSV_NAME
    write_atomic(tsv_path, tsv_text(entries).encode("utf-8"))
    return BuildResult(entries, maker.outputs, maker.missing)


# API cho collect_ui.py: một FontEntry cho mỗi (Name, CodePage), theo thứ tự tệp .font.
def collect_fonts(interface_dir: Path | str, out_interface_dir: Path | str) -> list[FontEntry]:
    return build_fonts(interface_dir, out_interface_dir).entries


def print_report(result: BuildResult, target: Path) -> None:
    tsv_path = target / SCHEMA_FOLDER / TSV_NAME
    print(f"Phông giao diện: {len(result.entries)} dòng ghi vào {tsv_path}")
    for output in result.outputs:
        state = "ghi mới" if output.is_written else "giữ nguyên"
        print(f"  {output.relative}: {output.size_bytes} byte ({state}); {output.summary}")
    for part, labels in result.missing.items():
        print(f"  THIẾU {part} trong gói (phông hệ thống), {len(labels)} dòng file rỗng: "
              f"{', '.join(labels)}")


def configure_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"): stream.reconfigure(encoding="utf-8", errors="replace")


USAGE = "Cách dùng: python ui_font.py <Interface đã giải gói> <Interface đích>"


def main(argv: list[str] | None = None) -> int:
    configure_output()
    arguments = sys.argv[1:] if argv is None else argv
    if arguments[:1] in (["-h"], ["--help"]):
        print(USAGE)
        return 0
    if len(arguments) != 2:
        print(USAGE, file=sys.stderr)
        return 2
    target = Path(arguments[1])
    try:
        result = build_fonts(Path(arguments[0]), target)
    except (FontError, OSError) as error:
        print(f"Lỗi phông: {error}", file=sys.stderr)
        return 1
    print_report(result, target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
