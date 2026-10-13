# Xuất 22 con trỏ chuột của client 2026 thành <dữ liệu client>/Interface/cursor/: bảng cursors.tsv và
# một ảnh RGBA8 .ttex cho mỗi loại, để client tự viết (SRC/client/viewer/cursors.cpp) dựng con trỏ như
# CCursorMng của Game.exe. Nguồn là tài nguyên CURSOR nằm ngay trong Game.exe, không phải tệp rời.
# Đọc từ mã máy Game.exe 2026 (CCursorMng::Initial @0x14007b2d0, docs/CON-TRO-2026.md): hàm gọi
# LoadCursorA 23 lần với id nhóm con trỏ 0x7f00, 0x81, 0x9b, 0x82... và cất tay cầm ở this+0x30+8*i; thứ
# tự i là thứ tự CursorKind của control/cursor_rules.hpp, i = 0 là mũi tên hệ thống (0x7f00 không có
# trong exe, nên không có tệp). Bảng RESOURCES dưới đây chép đúng dãy id ấy.
# Định dạng đọc ra:
# - Tài nguyên PE: thư mục tài nguyên tầng ba (loại, id, ngôn ngữ). RT_GROUP_CURSOR (12) cho id của RT_CURSOR
#   (1); dữ liệu RT_CURSOR là hotspot (hai uint16) rồi DIB của ICO (chiều cao gấp đôi: XOR rồi mặt nạ AND).
# - Chỉ ba kiểu ảnh có trong exe: 8 bit có bảng màu, 24 bit và 32 bit. Độ trong suốt lấy từ kênh alpha
#   khi ảnh 32 bit có alpha khác 0 ở ít nhất một điểm, không thì từ mặt nạ AND. Ảnh ghi ra là RGBA8 alpha
#   thẳng (Cursor::from_rgba tự nhân alpha).
# - Tệp .ttex: "TLBBTEX " + phiên bản 2 + định dạng 1 (RGBA8) + loại phẳng 1 + rộng + cao + một mức +
#   số byte + điểm ảnh; 28 byte đầu cố định (cursors.cpp: header_is_rgba).
# Sau khi ghi, công cụ đọc lại từng tệp và so với ảnh đã giải từ exe. Chạy ở gốc dự án:
#   python -B TOOLS/content/export_cursors.py <Game.exe> <dữ liệu client>            ghi rồi kiểm
#   python -B TOOLS/content/export_cursors.py <Game.exe> <dữ liệu client> --check    chỉ kiểm, không ghi
# Mã thoát: 0 khi khớp, 1 khi exe hỏng, tệp ghi lệch hay lỗi đĩa, 2 khi sai cách dùng.
from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

TARGET_DIR = ("Interface", "cursor")
TABLE = "cursors.tsv"
HEADER = "kind\tfile\thot_x\thot_y"
NOTE = "# Sinh bằng TOOLS/content/export_cursors.py từ tài nguyên CURSOR của Game.exe 2026; sửa tay sẽ mất ở lượt sau"
TTEX_MAGIC = b"TLBBTEX "
TTEX_HEAD = struct.Struct("<8sHHHIIHI")
MAX_EDGE = 256
RT_CURSOR = 1
RT_GROUP_CURSOR = 12
SYSTEM_ARROW = 0x7F00

# Tên sạch (cursor_rules.hpp) và id nhóm con trỏ theo thứ tự CursorKind; None là mũi tên hệ thống.
RESOURCES: tuple[tuple[str, int | None], ...] = (
    ("system", SYSTEM_ARROW),
    ("normal", 0x81),
    ("normal_down", 0x9B),
    ("attack", 0x82),
    ("auto_run", 0x87),
    ("pick_up", 0x89),
    ("unreachable", 0x88),
    ("mine", 0x8A),
    ("herbs", 0x8B),
    ("fish", 0x97),
    ("speak", 0x8D),
    ("interact", 0x8C),
    ("repair", 0x91),
    ("hover", 0x93),
    ("identify", 0x95),
    ("add_friend", 0x96),
    ("exchange", 0x99),
    ("catch_pet", 0x9A),
    ("scroll", 0x9E),
    ("cabinet", 0x9F),
    ("house", 0xA0),
    ("bow", 0xA1),
    ("bow_down", 0xA2),
)


class CursorError(Exception):
    """Exe không đọc được hay thiếu tài nguyên, ảnh kiểu lạ, tệp đích không ghi hay đọc lại được, hay
    tệp đã ghi lệch ảnh trong exe."""


@dataclass(frozen=True)
class Picture:
    width: int
    height: int
    hot_x: int
    hot_y: int
    rgba: bytes


class Resources:
    """Cây tài nguyên của một PE x64: (loại, id) -> byte của mục đầu tiên (ngôn ngữ nào cũng được)."""

    def __init__(self, exe: bytes) -> None:
        self.exe = exe
        self.sections = self._sections()
        self.base, self.size = self._directory()
        self.items: dict[tuple[int, int], bytes] = {}
        self._walk(0, ())

    def _need(self, offset: int, length: int) -> None:
        if offset < 0 or length < 0 or offset + length > len(self.exe):
            raise CursorError(f"exe hỏng: đọc {length} byte ở {offset:#x} vượt cỡ tệp {len(self.exe)}")

    def _u32(self, offset: int) -> int:
        self._need(offset, 4)
        return struct.unpack_from("<I", self.exe, offset)[0]

    def _u16(self, offset: int) -> int:
        self._need(offset, 2)
        return struct.unpack_from("<H", self.exe, offset)[0]

    def _nt(self) -> int:
        self._need(0, 0x40)
        if self.exe[:2] != b"MZ":
            raise CursorError("không phải tệp PE (thiếu MZ)")
        nt = self._u32(0x3C)
        self._need(nt, 4)
        if self.exe[nt:nt + 4] != b"PE\0\0":
            raise CursorError("không phải tệp PE (thiếu chữ ký PE)")
        return nt

    def _sections(self) -> list[tuple[int, int, int]]:
        nt = self._nt()
        count = self._u16(nt + 6)
        optional_size = self._u16(nt + 20)
        table = nt + 24 + optional_size
        found = []
        for index in range(count):
            row = table + index * 40
            self._need(row, 40)
            virtual_size, virtual, raw_size, raw = struct.unpack_from("<IIII", self.exe, row + 8)
            found.append((virtual, max(virtual_size, raw_size), raw))
        return found

    def _directory(self) -> tuple[int, int]:
        nt = self._nt()
        optional = nt + 24
        if self._u16(optional) != 0x20B:
            raise CursorError("chỉ đọc PE x64 (PE32+)")
        rva = self._u32(optional + 112 + 2 * 8)
        size = self._u32(optional + 112 + 2 * 8 + 4)
        if rva == 0 or size == 0:
            raise CursorError("exe không có thư mục tài nguyên")
        return self._file_offset(rva), size

    def _file_offset(self, rva: int) -> int:
        for virtual, extent, raw in self.sections:
            if virtual <= rva < virtual + extent:
                return raw + rva - virtual
        raise CursorError(f"RVA {rva:#x} không nằm trong phần nào")

    def _walk(self, offset: int, path: tuple[int, ...]) -> None:
        if len(path) >= 3:
            return
        directory = self.base + offset
        named = self._u16(directory + 12)
        ids = self._u16(directory + 14)
        for index in range(named + ids):
            entry = directory + 16 + index * 8
            name = self._u32(entry)
            target = self._u32(entry + 4)
            is_dir = bool(target & 0x80000000)
            ident = name if index >= named else -1 - index
            if is_dir:
                self._walk(target & 0x7FFFFFFF, (*path, ident))
            elif len(path) == 2 and (path[0], path[1]) not in self.items:
                self._keep((path[0], path[1]), self.base + target)

    def _keep(self, key: tuple[int, int], data_entry: int) -> None:
        rva = self._u32(data_entry)
        size = self._u32(data_entry + 4)
        start = self._file_offset(rva)
        self._need(start, size)
        self.items[key] = self.exe[start:start + size]


def decode_picture(resources: Resources, group_id: int) -> Picture:
    group = resources.items.get((RT_GROUP_CURSOR, group_id))
    if group is None:
        raise CursorError(f"exe không có nhóm con trỏ {group_id:#x}")
    if len(group) < 6 + 14:
        raise CursorError(f"nhóm con trỏ {group_id:#x} quá ngắn")
    reserved, kind, count = struct.unpack_from("<HHH", group, 0)
    if reserved != 0 or kind != 2 or count < 1 or len(group) < 6 + 14 * count:
        raise CursorError(f"nhóm con trỏ {group_id:#x} sai tiêu đề")
    ident = struct.unpack_from("<H", group, 6 + 12)[0]
    data = resources.items.get((RT_CURSOR, ident))
    if data is None:
        raise CursorError(f"nhóm {group_id:#x} trỏ tới con trỏ {ident} mà exe không có")
    return decode_dib(data, group_id)


def decode_dib(data: bytes, group_id: int) -> Picture:
    if len(data) < 4 + 40:
        raise CursorError(f"con trỏ của nhóm {group_id:#x} quá ngắn")
    hot_x, hot_y = struct.unpack_from("<HH", data, 0)
    head, width, height2, _, bits, compression, _, _, _, used, _ = struct.unpack_from("<IiiHHIIiiII", data, 4)
    height = height2 // 2
    if head != 40 or compression != 0 or width <= 0 or height <= 0 or width > MAX_EDGE or height > MAX_EDGE:
        raise CursorError(f"con trỏ của nhóm {group_id:#x}: tiêu đề DIB lạ ({head}, {width}x{height}, nén {compression})")
    if bits not in (8, 24, 32):
        raise CursorError(f"con trỏ của nhóm {group_id:#x}: kiểu ảnh {bits} bit chưa hỗ trợ")
    offset = 4 + head
    palette: list[tuple[int, int, int]] = []
    if bits == 8:
        for index in range(used or 256):
            blue, green, red, _ = struct.unpack_from("<BBBB", data, offset + index * 4)
            palette.append((red, green, blue))
        offset += len(palette) * 4
    stride = ((width * bits + 31) // 32) * 4
    mask_stride = ((width + 31) // 32) * 4
    need = offset + stride * height + mask_stride * height
    if len(data) < need:
        raise CursorError(f"con trỏ của nhóm {group_id:#x}: thiếu {need - len(data)} byte điểm ảnh")
    color = data[offset:offset + stride * height]
    mask = data[offset + stride * height:need]
    pixels = bytearray(width * height * 4)
    alpha_seen = False
    for source_row in range(height):
        row = height - 1 - source_row
        for column in range(width):
            if bits == 32:
                blue, green, red, alpha = struct.unpack_from("<BBBB", color, source_row * stride + column * 4)
                alpha_seen = alpha_seen or alpha != 0
            elif bits == 24:
                blue, green, red = struct.unpack_from("<BBB", color, source_row * stride + column * 3)
                alpha = 255
            else:
                red, green, blue = palette[color[source_row * stride + column]]
                alpha = 255
            at = (row * width + column) * 4
            pixels[at:at + 4] = bytes((red, green, blue, alpha))
    if not (bits == 32 and alpha_seen):
        for source_row in range(height):
            row = height - 1 - source_row
            for column in range(width):
                transparent = (mask[source_row * mask_stride + column // 8] >> (7 - column % 8)) & 1
                pixels[(row * width + column) * 4 + 3] = 0 if transparent else 255
    return Picture(width, height, hot_x, hot_y, bytes(pixels))


def ttex_bytes(picture: Picture) -> bytes:
    head = TTEX_HEAD.pack(TTEX_MAGIC, 2, 1, 1, picture.width, picture.height, 1, len(picture.rgba))
    return head + picture.rgba


def read_ttex(data: bytes) -> bytes | None:
    if len(data) < TTEX_HEAD.size:
        return None
    magic, version, fmt, flat, width, height, mips, size = TTEX_HEAD.unpack_from(data)
    if magic != TTEX_MAGIC or (version, fmt, flat, mips) != (2, 1, 1, 1):
        return None
    if size != width * height * 4 or len(data) != TTEX_HEAD.size + size:
        return None
    return data[TTEX_HEAD.size:]


def table_text(pictures: dict[str, Picture]) -> str:
    lines = [NOTE, HEADER]
    for name, ident in RESOURCES:
        if ident == SYSTEM_ARROW:
            continue
        picture = pictures[name]
        lines.append(f"{name}\t{'/'.join(TARGET_DIR)}/{name}.ttex\t{picture.hot_x}\t{picture.hot_y}")
    return "\n".join(lines) + "\n"


def load_pictures(exe_path: Path) -> dict[str, Picture]:
    try:
        exe = exe_path.read_bytes()
    except OSError as error:
        raise CursorError(f"không đọc được {exe_path}: {error}") from error
    resources = Resources(exe)
    pictures: dict[str, Picture] = {}
    for name, ident in RESOURCES:
        if ident is None or ident == SYSTEM_ARROW:
            continue
        pictures[name] = decode_picture(resources, ident)
    return pictures


def write_all(folder: Path, pictures: dict[str, Picture]) -> None:
    try:
        folder.mkdir(parents=True, exist_ok=True)
        for name, picture in pictures.items():
            (folder / f"{name}.ttex").write_bytes(ttex_bytes(picture))
        (folder / TABLE).write_text(table_text(pictures), encoding="utf-8", newline="\n")
    except OSError as error:
        raise CursorError(f"không ghi được vào {folder}: {error}") from error


def check_all(folder: Path, pictures: dict[str, Picture]) -> list[str]:
    problems: list[str] = []
    for name, picture in pictures.items():
        path = folder / f"{name}.ttex"
        try:
            pixels = read_ttex(path.read_bytes())
        except OSError:
            problems.append(f"thiếu {path}")
            continue
        if pixels is None:
            problems.append(f"{path}: tiêu đề .ttex sai")
        elif pixels != picture.rgba:
            problems.append(f"{path}: điểm ảnh lệch ảnh trong exe")
    try:
        text = (folder / TABLE).read_text(encoding="utf-8")
    except OSError:
        problems.append(f"thiếu {folder / TABLE}")
        return problems
    if text != table_text(pictures):
        problems.append(f"{folder / TABLE}: lệch bảng sinh từ exe")
    return problems


def run(exe: Path, data: Path, only_check: bool) -> int:
    pictures = load_pictures(exe)
    folder = data.joinpath(*TARGET_DIR)
    if not only_check:
        write_all(folder, pictures)
    problems = check_all(folder, pictures)
    for problem in problems:
        print(f"LỖI: {problem}", file=sys.stderr)
    if problems:
        return 1
    print(f"con trỏ: {len(pictures)} ảnh khớp Game.exe ở {folder}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Xuất con trỏ chuột của Game.exe 2026")
    parser.add_argument("exe", type=Path, help="Game.exe của client 2026")
    parser.add_argument("data", type=Path, help="thư mục dữ liệu client (dev/client/assets)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm, không ghi")
    chosen = parser.parse_args(argv)
    try:
        return run(chosen.exe, chosen.data, chosen.check)
    except CursorError as error:
        print(f"LỖI: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
