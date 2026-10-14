# Gỡ vỏ CryptBox của client Thiên Long (tệp bọc trong gói .axp). Port từ G:\TLBB\Dev\tools\assetpack\cryptbox.cpp,
# dịch ngược từ Game.exe 3.71.9667 (hàm sinh khoá 0x6EAFC0, bảng 25 phép biến đổi 0x6EBA88), đã đúng ở 50 377 tệp
# bọc của G:\tlbb\Data. Giữ nguyên thứ tự phép tính của bản C++.
# Tệp bọc mở đầu bằng đầu vỏ 96 byte XOR với bảng khoá thứ nhất; giải ra "SEPCIAL_FILE_HD\0" (đúng chính tả của
# client), mode 1..25, cỡ thân, một trường 32 bit chưa rõ nghĩa, rồi đệm 0. Thân biến đổi theo mode bằng 23 bảng
# khoá 128 byte sinh từ rand() của MSVC; client đếm vị trí khoá từ đầu tệp nên byte i của thân dùng khoá (96 + i) & 127.
import struct

HEADER_BYTES = 96
TABLE_BYTES = 128
ORIGIN = HEADER_BYTES
MODE_COUNT = 25
MAGIC = bytes([0x84, 0xCC, 0xFA, 0x75, 0x9A, 0x9D, 0x3B, 0x6D, 0x5A, 0xE1, 0xE8, 0x3A, 0xC6, 0x0E, 0x6C, 0x7B])
MARK = b"SEPCIAL_FILE_HD\0"

# Tên bảng là offset của nó trong đối tượng CryptBox của client; thứ tự là thứ tự trong enum của bản C++.
TABLES = ["T008", "T088", "T108", "T188", "T20C", "T28D", "T30D", "T38D", "T40D", "T48D", "T50D", "T58D", "T60D",
          "T68D", "T70D", "T78D", "T80D", "T88D", "T90D", "T98D", "TA0D", "TA8D", "TB0D"]
INDEX = {name: number for number, name in enumerate(TABLES)}


class _Rand:
    """rand() của MSVC: LCG nhân 214013 cộng 2531011, trả 15 bit từ bit 16."""

    def __init__(self, state: int) -> None:
        self.state = state

    def next(self) -> int:
        self.state = (self.state * 214013 + 2531011) & 0xFFFFFFFF
        return (self.state >> 16) & 0x7FFF


def _fill(rand: _Rand) -> bytes:
    # Mỗi byte là rand() % 255, như vòng lặp chia cho 255 của client.
    return bytes(rand.next() % 255 for _ in range(TABLE_BYTES))


def _make_keys() -> tuple[list[bytes], int, int]:
    tables: list[bytes] = [b""] * len(TABLES)
    rand = _Rand(0x19830716)
    tables[INDEX["T008"]] = _fill(rand)
    rand = _Rand(0x19811004)
    tables[INDEX["T088"]] = _fill(rand)
    rand = _Rand(0x12345687)
    tables[INDEX["T108"]] = _fill(rand)
    tables[INDEX["T188"]] = _fill(rand)
    extra = rand.next() & 0x7F  # offset 0x208: lệch thêm chỉ số khoá của mode 4
    tables[INDEX["T20C"]] = _fill(rand)
    single = rand.next() % 255  # offset 0x28C: khoá đầu của mode 6
    # Các lượt srand của 0x6EAFC0 và số bảng liền nhau mỗi lượt.
    for seed, first, count in ((0x20100118, "T28D", 1), (0x20100119, "T30D", 1), (0x20120101, "T38D", 2),
                               (0x20121212, "T48D", 4), (0x10121011, "T68D", 4), (0x20202020, "T88D", 3),
                               (0x17230517, "TA0D", 3)):
        rand = _Rand(seed)
        for n in range(count):
            tables[INDEX[first] + n] = _fill(rand)
    return tables, extra, single


KEYS, EXTRA, SINGLE = _make_keys()

# (phép, bảng, giới hạn byte; 0 là cả thân), mode = chỉ số + 1.
RULES = [
    ("xor", "T008", 0), ("xor", "T088", 0), ("xor", "T108", 0), ("shifted", "T188", 0), ("sub", "T20C", 0),
    ("running", "T008", 0), ("subxor", "T28D", 0), ("xorsub", "T30D", 0), ("sub", "T38D", 0), ("xorsub", "T40D", 0),
    ("xorsub", "T48D", 0), ("xorsub", "T50D", 0), ("xorsub", "T58D", 0x400), ("xorsub", "T60D", 0x400),
    ("xorsub", "T68D", 0x400), ("xorsub", "T70D", 0x400), ("xorsub", "T78D", 0x400), ("xorsub", "T80D", 0x400),
    ("copy", "T008", 0), ("xor", "T88D", 0), ("xorsub", "T90D", 0x800), ("xorsub", "T98D", 0x400),
    ("xorsub", "TA0D", 0), ("dwords", "TA8D", 0), ("fifteenth", "TB0D", 0),
]
assert len(RULES) == MODE_COUNT


def _key_at(table: str, position: int) -> int:
    return KEYS[INDEX[table]][position & (TABLE_BYTES - 1)]


def _apply(step: str, v: int, k: int) -> int:
    if step == "xor":
        return v ^ k
    if step in ("sub", "shifted"):
        return (v - k) & 0xFF
    if step == "xorsub":
        return ((v ^ k) - k) & 0xFF
    return ((v - k) & 0xFF) ^ k  # subxor, fifteenth


def is_wrapped(data: bytes) -> bool:
    return len(data) >= HEADER_BYTES and data[:len(MAGIC)] == MAGIC


def unwrap_body(mode: int, body: bytes) -> bytes:
    if not 1 <= mode <= MODE_COUNT:
        raise ValueError(f"mode {mode} ngoài 1..{MODE_COUNT}")
    step, table, limit = RULES[mode - 1]
    out = bytearray(body)
    if step == "running":
        k = SINGLE
        for i, v in enumerate(out):
            out[i] = v ^ k
            k = (k + v) & 0xFF
    elif step == "copy":
        pass
    elif step == "dwords":
        words = KEYS[INDEX[table]]
        for n in range(len(out) // 4):
            at = (n % (TABLE_BYTES // 4)) * 4
            for b in range(4):
                out[n * 4 + b] ^= words[at + b]
    elif step == "fifteenth":
        for i in range(0, len(out), 15):
            out[i] = _apply(step, out[i], _key_at(table, ORIGIN + i))
    else:
        end = len(out) if limit == 0 else min(len(out), limit)
        shift = ORIGIN + EXTRA if step == "shifted" else ORIGIN
        for i in range(end):
            out[i] = _apply(step, out[i], _key_at(table, shift + i))
    return bytes(out)


def unwrap(data: bytes) -> bytes:
    """Thân đã gỡ, đúng định dạng gốc. Lỗi khi đầu vỏ không giải ra dấu, cỡ thân lệch cỡ thật, đệm khác 0 hay mode lạ."""
    if not is_wrapped(data):
        raise ValueError("tệp không mang vỏ CryptBox")
    header = bytes(data[i] ^ _key_at("T008", i) for i in range(HEADER_BYTES))
    if header[:len(MARK)] != MARK:
        raise ValueError("đầu vỏ không giải ra dấu SEPCIAL_FILE_HD")
    mode, length = struct.unpack_from("<II", header, 16)
    if length != len(data) - HEADER_BYTES:
        raise ValueError(f"đầu vỏ ghi thân {length} byte, tệp có {len(data) - HEADER_BYTES}")
    if any(header[28:]):
        raise ValueError("đệm của đầu vỏ khác 0")
    return unwrap_body(mode, data[HEADER_BYTES:])
