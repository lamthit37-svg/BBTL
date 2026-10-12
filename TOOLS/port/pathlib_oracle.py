# Trọng tài cho module nav: nạp chính PathLib.dll của client 2026 (chỉ đọc), cho nó một tệp .path
# và hỏi nó các truy vấn ngẫu nhiên, rồi ghi câu trả lời thành tệp số vàng để test C++ so từng bit.
# Thư viện gốc là nguồn sự thật: bản port ở SRC/nav phải ra đúng những con số này.
# PathLib.dll không xuất hàm C: mọi thứ đi qua bảng hàm ảo của ba lớp nó xuất hàm dựng
# (PathData, PathFinder). Số của ô trong bảng và chữ ký đọc từ mã máy, ghi ở
# docs/DUONG-DI-2026.md. Cần Python 64 bit trên Windows và thư mục Bin64 của client.
# Chạy ở gốc dự án:
#   python TOOLS/port/pathlib_oracle.py golden <Bin64> <tệp.path> <tệp ra.tsv>
#       [--queries N] [--seed S] [--embed]
# --embed ghi kèm chính tệp .path (dạng hex) vào dòng "mesh", để test không cần dữ liệu client;
# chỉ dùng cho lưới nhỏ. Mỗi dòng của tệp ra là một truy vấn, các trường cách nhau bằng tab, số
# thực ghi bằng 8 chữ số hex của mẫu bit:
#   locate x z <tam giác đi được|-> <tam giác vật cản|->
#   cross  x1 z1 x2 z2 <số chỗ cắt|-> (khoảng cách bình phương, cờ, x, z)...
#   find   x1 z1 x2 z2 <số điểm|-> (x, z)...
# Mã thoát: 0 khi ghi xong, 2 khi đối số sai hoặc không nạp được thư viện.
import argparse
import ctypes
import os
import pathlib
import random
import struct
import sys

GET_DATA = "?getPathData@PathLibRoot@PathLib@@QEAAPEAVPathData@2@XZ"
GET_FINDER = "?getPathFinder@PathLibRoot@PathLib@@QEAAPEAVPathFinder@2@XZ"
# Ô trong bảng hàm ảo của PathDataImpl và PathFinderImpl.
DATA_FROM_MEMORY = 3
FINDER_INIT = 1
FINDER_FIND = 3
FINDER_DIRECT = 5
FINDER_LOCATE = 6
FINDER_COUNT = 7
FINDER_POINT = 8
# std::set các chỗ cắt nằm ở PathFinderImpl + 0x50: con trỏ nút đầu, rồi số phần tử.
CROSSINGS_AT = 0x50
NODE_LEFT = 0x00
NODE_PARENT = 0x08
NODE_RIGHT = 0x10
NODE_IS_NIL = 0x19
NODE_KEY = 0x1C
NODE_FLAGS = 0x20
NODE_X = 0x24
NODE_Z = 0x28


def bits_of(value: float) -> str:
    return struct.pack(">f", value).hex()


def as_single(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


class Oracle:
    """PathData và PathFinder của thư viện gốc, đã nạp một tệp .path."""

    def __init__(self, bin_folder: pathlib.Path, blob: bytes) -> None:
        os.add_dll_directory(str(bin_folder))
        self.library = ctypes.CDLL(str(bin_folder / "PathLib.dll"))
        # Giữ bộ đệm sống cùng đối tượng: thư viện có thể còn trỏ vào nó.
        self.blob = ctypes.create_string_buffer(blob, len(blob))
        self.data = self.make(GET_DATA)
        self.call(self.data, DATA_FROM_MEMORY, None, ctypes.c_char_p, ctypes.c_uint)(
            self.blob, len(blob))
        self.finder = self.make(GET_FINDER)
        self.call(self.finder, FINDER_INIT, None, ctypes.c_void_p)(self.data)
        single = ctypes.c_float
        self.find_path = self.call(self.finder, FINDER_FIND, ctypes.c_bool, single, single,
                                   single, single, single)
        self.direct = self.call(self.finder, FINDER_DIRECT, ctypes.c_bool, single, single,
                                single, single)
        self.locate_in = self.call(self.finder, FINDER_LOCATE, ctypes.c_bool, single, single,
                                   ctypes.POINTER(ctypes.c_int), ctypes.c_bool)
        self.count = self.call(self.finder, FINDER_COUNT, ctypes.c_size_t)
        self.point = self.call(self.finder, FINDER_POINT, ctypes.POINTER(ctypes.c_float),
                               ctypes.c_size_t)

    def make(self, name: str) -> int:
        factory = self.library[name]
        factory.restype = ctypes.c_void_p
        factory.argtypes = [ctypes.c_void_p]
        return factory(None)

    @staticmethod
    def call(instance: int, slot: int, restype, *argtypes):
        table = ctypes.cast(instance, ctypes.POINTER(ctypes.c_void_p))[0]
        address = ctypes.cast(table, ctypes.POINTER(ctypes.c_void_p))[slot]
        function = ctypes.CFUNCTYPE(restype, ctypes.c_void_p, *argtypes)(address)
        return lambda *arguments: function(instance, *arguments)

    def locate(self, point, is_obstacle: bool):
        triangle = ctypes.c_int(-1)
        found = self.locate_in(point[0], point[1], ctypes.byref(triangle), is_obstacle)
        return triangle.value if found else None

    def find(self, start, end):
        if not self.find_path(start[0], start[1], end[0], end[1], 0.0):
            return None
        points = []
        for index in range(self.count()):
            pair = self.point(index)
            points.append((pair[0], pair[1]))
        return points

    def crossings(self, start, end):
        if not self.direct(start[0], start[1], end[0], end[1]):
            return None
        head = ctypes.c_void_p.from_address(self.finder + CROSSINGS_AT).value
        node = ctypes.c_void_p.from_address(head + NODE_LEFT).value
        found = []
        while node != head:
            found.append(self.crossing_at(node))
            node = self.next_node(node)
        return found

    @staticmethod
    def crossing_at(node: int):
        key = ctypes.c_float.from_address(node + NODE_KEY).value
        flags = ctypes.c_ubyte.from_address(node + NODE_FLAGS).value
        across = ctypes.c_float.from_address(node + NODE_X).value
        down = ctypes.c_float.from_address(node + NODE_Z).value
        return key, flags, across, down

    @staticmethod
    def is_nil(node: int) -> bool:
        return ctypes.c_ubyte.from_address(node + NODE_IS_NIL).value != 0

    def next_node(self, node: int) -> int:
        """Nút kế tiếp theo thứ tự của cây đỏ đen của MSVC (như std::_Tree::iterator::operator++)."""
        right = ctypes.c_void_p.from_address(node + NODE_RIGHT).value
        if not self.is_nil(right):
            node = right
            left = ctypes.c_void_p.from_address(node + NODE_LEFT).value
            while not self.is_nil(left):
                node = left
                left = ctypes.c_void_p.from_address(node + NODE_LEFT).value
            return node
        parent = ctypes.c_void_p.from_address(node + NODE_PARENT).value
        while not self.is_nil(parent) and node == ctypes.c_void_p.from_address(
                parent + NODE_RIGHT).value:
            node = parent
            parent = ctypes.c_void_p.from_address(node + NODE_PARENT).value
        return parent


def grid_extent(blob: bytes) -> tuple[float, float]:
    """Cỡ vùng mà lưới tra phủ, đọc từ đầu lưới của tệp (bản 0x2000 và 0x1000)."""
    version = struct.unpack_from("<H", blob, 0)[0]
    is_wide = version == 0x2000
    index_bytes = 4 if is_wide else 2
    code = "<I" if is_wide else "<H"
    at = 2
    for record in (8, index_bytes * 7 + 1, index_bytes * 4):
        count = struct.unpack_from(code, blob, at)[0]
        at += index_bytes + count * record
    size = struct.unpack_from("<I", blob, at)[0]
    columns = struct.unpack_from(code, blob, at + 4)[0]
    rows = struct.unpack_from(code, blob, at + 4 + index_bytes)[0]
    return float(size * columns), float(size * rows)


def row(kind: str, numbers, tail) -> str:
    fields = [kind] + [bits_of(number) for number in numbers] + [str(field) for field in tail]
    return "\t".join(fields)


def write_golden(oracle: Oracle, chosen, blob: bytes, out) -> None:
    width, depth = grid_extent(blob)
    dice = random.Random(chosen.seed)

    def anywhere():
        return as_single(dice.uniform(0.0, width)), as_single(dice.uniform(0.0, depth))

    def walkable():
        while True:
            point = anywhere()
            if oracle.locate(point, False) is not None:
                return point

    for _ in range(chosen.queries):
        point = anywhere()
        open_ground = oracle.locate(point, False)
        wall = oracle.locate(point, True)
        tail = ["-" if open_ground is None else open_ground, "-" if wall is None else wall]
        out.write(row("locate", point, tail) + "\n")
    for _ in range(chosen.queries):
        start, end = anywhere(), anywhere()
        found = oracle.crossings(start, end)
        tail = ["-"] if found is None else [len(found)]
        for key, flags, across, down in found or []:
            tail += [bits_of(key), flags, bits_of(across), bits_of(down)]
        out.write(row("cross", start + end, tail) + "\n")
    for _ in range(chosen.queries):
        start, end = walkable(), walkable()
        path = oracle.find(start, end)
        tail = ["-"] if path is None else [len(path)]
        for across, down in path or []:
            tail += [bits_of(across), bits_of(down)]
        out.write(row("find", start + end, tail) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Sinh số vàng của module nav từ PathLib.dll gốc.")
    parser.add_argument("command", choices=["golden"])
    parser.add_argument("bin_folder", type=pathlib.Path, help="thư mục Bin64 của client")
    parser.add_argument("path_file", type=pathlib.Path, help="tệp .path của một cảnh")
    parser.add_argument("out_file", type=pathlib.Path, help="tệp số vàng ghi ra")
    parser.add_argument("--queries", type=int, default=300, help="số truy vấn mỗi loại")
    parser.add_argument("--seed", type=int, default=20261008, help="hạt của dãy ngẫu nhiên")
    parser.add_argument("--embed", action="store_true", help="ghi kèm tệp .path dạng hex")
    chosen = parser.parse_args()
    if struct.calcsize("P") != 8 or os.name != "nt":
        print("Cần Python 64 bit trên Windows để nạp PathLib.dll.", file=sys.stderr)
        return 2
    if not (chosen.bin_folder / "PathLib.dll").is_file():
        print(f"Không thấy PathLib.dll trong {chosen.bin_folder}.", file=sys.stderr)
        return 2
    blob = chosen.path_file.read_bytes()
    oracle = Oracle(chosen.bin_folder, blob)
    with open(chosen.out_file, "w", encoding="utf-8", newline="\n") as out:
        out.write(f"# Số vàng của nav: PathLib.dll gốc trả lời trên {chosen.path_file.name}, "
                  f"hạt {chosen.seed}. Sinh bằng TOOLS/port/pathlib_oracle.py, không sửa tay.\n")
        if chosen.embed:
            out.write("mesh\t" + blob.hex() + "\n")
        write_golden(oracle, chosen, blob, out)
    print(f"Đã ghi {chosen.out_file}: {chosen.queries} truy vấn mỗi loại.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
