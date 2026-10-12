# Đọc bảng Config nhị phân của client 2026 (DBC).
# Bố cục (theo OpenFromMemoryImpl_Binary của client; đọc lại từ TLBB Dev tools/export/dbc.cpp
# @e0d89a6): đầu 16 byte gồm magic 0xDDBBCC00, số cột, số bản ghi, cỡ khối chuỗi; rồi kiểu cột u32
# (0 INT, 1 FLOAT, 2 STRING); rồi bản ghi, mỗi ô 4 byte (int32, float32 hay offset vào khối chuỗi);
# rồi khối chuỗi GBK. Mọi số little-endian. Offset chuỗi ngoài khối là lỗi, không đọc bậy.
import struct

MAGIC = 0xDDBBCC00
HEAD_BYTES = 16
INT, FLOAT, STRING = 0, 1, 2


class DbcError(ValueError):
    pass


class Dbc:
    def __init__(self, name: str, types: list, cells: list, strings: bytes):
        self.name = name
        self.types = types
        self.columns = len(types)
        self.cells = cells
        self.strings = strings
        self.rows = len(cells) // self.columns

    def raw(self, row: int, column: int) -> int:
        if not (0 <= row < self.rows and 0 <= column < self.columns):
            raise DbcError(f"{self.name}: ô ({row}, {column}) ngoài bảng {self.rows}x{self.columns}")
        return self.cells[row * self.columns + column]

    def integer(self, row: int, column: int) -> int:
        kind = self.types[column]
        value = self.raw(row, column)
        if kind == INT:
            return struct.unpack("<i", struct.pack("<I", value))[0]
        raise DbcError(f"{self.name}: cột {column} không phải số nguyên")

    def real(self, row: int, column: int) -> float:
        if self.types[column] != FLOAT:
            raise DbcError(f"{self.name}: cột {column} không phải số thực")
        return struct.unpack("<f", struct.pack("<I", self.raw(row, column)))[0]

    def text(self, row: int, column: int) -> str:
        if self.types[column] != STRING:
            raise DbcError(f"{self.name}: cột {column} không phải chuỗi")
        offset = self.raw(row, column)
        if offset >= len(self.strings):
            raise DbcError(f"{self.name}: offset chuỗi {offset} ngoài khối {len(self.strings)} byte")
        end = self.strings.index(b"\0", offset) if b"\0" in self.strings[offset:] else len(self.strings)
        return self.strings[offset:end].decode("gb18030")

    # Giá trị của ô theo kiểu cột, để in và so sánh.
    def cell(self, row: int, column: int):
        kind = self.types[column]
        if kind == INT:
            return self.integer(row, column)
        if kind == FLOAT:
            return self.real(row, column)
        return self.text(row, column)

    def find(self, key: int, column: int = 0) -> int | None:
        for row in range(self.rows):
            if self.types[column] == INT and self.integer(row, column) == key:
                return row
        return None


def read(path: str, name: str | None = None) -> Dbc:
    with open(path, "rb") as stream:
        data = stream.read()
    label = name or path
    if len(data) < HEAD_BYTES or struct.unpack_from("<I", data, 0)[0] != MAGIC:
        raise DbcError(f"{label}: không phải bảng nhị phân DBC")
    columns, rows, strings = struct.unpack_from("<III", data, 4)
    need = HEAD_BYTES + 4 * (columns + columns * rows) + strings
    if need > len(data) or columns == 0 or strings == 0:
        raise DbcError(f"{label}: đầu tệp lệch cỡ ({need} byte cần, có {len(data)})")
    types = list(struct.unpack_from(f"<{columns}I", data, HEAD_BYTES))
    if any(kind not in (INT, FLOAT, STRING) for kind in types):
        raise DbcError(f"{label}: kiểu cột lạ")
    cells_at = HEAD_BYTES + 4 * columns
    cells = list(struct.unpack_from(f"<{columns * rows}I", data, cells_at))
    block_at = cells_at + 4 * columns * rows
    block = bytearray(data[block_at:block_at + strings])
    block[-1] = 0  # bản gốc ép byte cuối của khối thành NUL
    return Dbc(label, types, cells, bytes(block))
