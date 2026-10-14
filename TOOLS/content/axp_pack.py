# Đọc gói .axp của client Thiên Long (Data/*.axp). Định dạng và phép băm port từ
# G:\TLBB\Dev\tools\assetpack\axp.cpp (đã đối chiếu trên 23 gói của client 3.71.9667); chỉ đọc, không ghi.
# Bố cục: đầu 40 byte (chữ ký "AXPK", phiên bản 0x00010001, vị trí bảng băm ở byte 12, bảng mục ở 16, số
# mục ở 20); bảng băm 0x8000 ô x 12 byte (băm A, băm B, cờ tồn tại + số mục); bảng mục 12 byte mỗi mục
# (offset, cỡ, cờ). Danh mục tên là mục "(list)": dòng 1 mã kiểm tra, dòng 2 số tệp, rồi "tên|cỡ hex|mã".
# Tên là GB18030, gấp chữ hoa theo ký tự GB18030 (không hạ byte đuôi), phân cách "/".
import mmap
import struct
from pathlib import Path

SIGNATURE = 0x4B505841
VERSION = 0x00010001
HEADER_BYTES = 40
SLOTS = 0x8000
CELL_BYTES = 12
ENTRY_BYTES = 12
EXISTS = 0x80000000
BLOCK_MASK = 0x3FFFFFFF
MASK32 = 0xFFFFFFFF
FIRST, SECOND, SLOT = 1, 2, 3


def _crypt_table() -> list[int]:
    # Thứ tự ghi của client: chỉ số n chạy ngoài, bốn bảng con n/4 + k*0x100 chạy trong.
    table = [0] * 0x400
    seed = 0x00100001

    def step(value: int) -> int:
        return (125 * value + 3) % 0x2AAAAB

    for n in range(0x400):
        seed = step(seed)
        high = (seed << 16) & MASK32
        seed = step(seed)
        table[n // 4 + (n % 4) * 0x100] = high | (seed & 0xFFFF)
    return table


CRYPT = _crypt_table()


def axp_hash(name: bytes, kind: int) -> int:
    """HashString của client: byte tên đọc như signed char (byte từ 0x80 cho chỉ số âm, lùi về bảng con trước)."""
    seed1, seed2 = 0x7FED7FED, 0xEEEEEEEE
    base = kind << 8
    for byte in name:
        ch = byte - 256 if byte >= 0x80 else byte
        seed1 = CRYPT[base + ch] ^ ((seed1 + seed2) & MASK32)
        seed2 = (ch + seed1 + seed2 + ((seed2 << 5) & MASK32) + 3) & MASK32
    return seed1


def fold_name(name: bytes) -> bytes:
    """Hạ chữ hoa ASCII, bỏ qua mọi byte của ký tự GB18030 (byte dẫn 0x81-0xFE; byte thứ hai 0x30-0x39 là chữ bốn byte)."""
    out = bytearray(name)
    at = 0
    while at < len(out):
        byte = out[at]
        if 0x81 <= byte <= 0xFE:
            nxt = out[at + 1] if at + 1 < len(out) else 0
            at += 4 if 0x30 <= nxt <= 0x39 else 2
            continue
        if 0x41 <= byte <= 0x5A:
            out[at] = byte + 0x20
        at += 1
    return bytes(out)


class AxpError(Exception):
    pass


class Axp:
    """Một gói .axp đã ánh xạ vào bộ nhớ. names() là tên GB18030 thô; read(name) là byte lưu trong gói (chưa gỡ vỏ CryptBox)."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self._file = path.open("rb")
        self._map = mmap.mmap(self._file.fileno(), 0, access=mmap.ACCESS_READ)
        self._parse_header()
        self._listing = self._read_listing()

    def close(self) -> None:
        self._map.close()
        self._file.close()

    def __enter__(self) -> "Axp":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def _u32(self, at: int) -> int:
        return struct.unpack_from("<I", self._map, at)[0]

    def _parse_header(self) -> None:
        if len(self._map) < HEADER_BYTES:
            raise AxpError("gói ngắn hơn đầu gói")
        if self._u32(0) != SIGNATURE:
            raise AxpError("sai chữ ký AXPK")
        if self._u32(4) != VERSION:
            raise AxpError(f"phiên bản gói lạ {self._u32(4):08X}")
        self.cells, self.index, self.count = self._u32(12), self._u32(16), self._u32(20)
        if self.cells + SLOTS * CELL_BYTES > len(self._map):
            raise AxpError("bảng băm nằm ngoài gói")
        if self.index + self.count * ENTRY_BYTES > len(self._map):
            raise AxpError("bảng mục nằm ngoài gói")

    def _find_block(self, folded: bytes) -> int | None:
        first, second = axp_hash(folded, FIRST), axp_hash(folded, SECOND)
        start = axp_hash(folded, SLOT) & (SLOTS - 1)
        for n in range(SLOTS):
            at = self.cells + ((start + n) & (SLOTS - 1)) * CELL_BYTES
            cell = self._u32(at + 8)
            if cell & EXISTS and self._u32(at) == first and self._u32(at + 4) == second:
                return cell & BLOCK_MASK
        return None

    def _slot(self, block: int) -> tuple[int, int]:
        if block >= self.count:
            raise AxpError(f"ô băm trỏ mục {block} ngoài bảng mục")
        at = self.index + block * ENTRY_BYTES
        if not self._u32(at + 8) & EXISTS:
            raise AxpError(f"mục {block} đã bỏ")
        offset, size = self._u32(at), self._u32(at + 4)
        if offset + size > len(self._map):
            raise AxpError(f"mục {block} nằm ngoài gói")
        return offset, size

    def _read_listing(self) -> dict[bytes, int]:
        block = self._find_block(b"(list)")
        if block is None:
            raise AxpError("không thấy (list) trong bảng băm")
        offset, size = self._slot(block)
        lines = bytes(self._map[offset:offset + size]).split(b"\n")
        lines = [line.rstrip(b"\r") for line in lines]
        if len(lines) < 2:
            raise AxpError("danh mục thiếu hai dòng đầu")
        declared = int(lines[1])
        listing: dict[bytes, int] = {}
        for number, line in enumerate(lines[2:], 3):
            if not line:
                continue
            # Tách từ phải: byte đuôi GB18030 có thể là "|".
            parts = line.rsplit(b"|", 2)
            if len(parts) != 3:
                raise AxpError(f"danh mục dòng {number}: thiếu cột")
            listing[parts[0]] = int(parts[1], 16)
        if len(listing) != declared:
            raise AxpError(f"danh mục ghi {declared} tệp, có {len(listing)}")
        return listing

    def names(self) -> list[bytes]:
        return list(self._listing)

    def read(self, name: bytes) -> bytes:
        block = self._find_block(fold_name(name))
        if block is None:
            raise AxpError(f"{name!r}: không có trong bảng băm")
        offset, size = self._slot(block)
        if size != self._listing[name]:
            raise AxpError(f"{name!r}: cỡ {size} khác danh mục {self._listing[name]}")
        return bytes(self._map[offset:offset + size])
