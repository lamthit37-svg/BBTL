# Sinh một tệp .path nhỏ do dự án tự vẽ (không lấy từ dữ liệu client), để PathLib.dll gốc và
# module nav cùng trả lời trên một lưới mà test chạy được ở mọi nơi.
# Lưới giống dữ liệu thật ở điểm quyết định: mọi đỉnh của vùng đi được nằm trên mép vật cản và có
# đúng hai cạnh ràng buộc, như lưới tam giác có ràng buộc của client (ở đỉnh nằm giữa vùng trống,
# bản gốc đọc ngăn xếp chưa khởi tạo khi né góc, nên câu trả lời của nó không dùng làm chuẩn được).
# Vùng 32 x 32, lưới tra 4 x 4 ô cỡ 8. Viền dày 1 quanh vùng là vật cản; bên trong có năm khối vật
# cản tứ giác và một hào vây kín một đảo đi được (đảo thứ hai). Góc các khối bị xê dịch một quãng
# nhỏ theo dãy số cố định để không có cạnh nào song song với trục. Vùng đi được chia tam giác bằng
# cách nối cầu từ lỗ ra viền rồi cắt tai, nên không sinh đỉnh mới.
# Tệp ghi theo bản 0x2000 (hoặc 0x1000 với --narrow) đúng bố cục mà SRC/nav/mesh.cpp đọc.
# Chạy ở gốc dự án:
#   python TOOLS/port/make_path_mesh.py <tệp ra.path> [--narrow] [--seed S]
import argparse
import pathlib
import random
import struct
import sys

SIDE = 32.0
CELL = 8
NONE = 1000000
NARROW_NONE = 0xFFFF
JITTER = 0.3
INSET = 1.0
# Khối vật cản: (x đầu, z đầu, x cuối, z cuối) trước khi xê dịch góc.
BLOCKS = [(6, 6, 12, 20), (16, 4, 26, 8), (16, 14, 20, 26), (24, 18, 30, 22), (4, 24, 10, 28)]
MOAT = (22, 24, 30, 30)
ISLAND = (24, 26, 28, 29)


def cross(origin, first, second) -> float:
    return ((first[0] - origin[0]) * (second[1] - origin[1])
            - (first[1] - origin[1]) * (second[0] - origin[0]))


def is_crossing(a, b, c, d) -> bool:
    """Hai đoạn cắt nhau ở điểm nằm hẳn bên trong cả hai."""
    return cross(a, b, c) * cross(a, b, d) < 0 and cross(c, d, a) * cross(c, d, b) < 0


def is_within(point, a, b, c) -> bool:
    """Điểm nằm hẳn trong tam giác ngược chiều kim đồng hồ a, b, c."""
    return cross(a, b, point) > 0 and cross(b, c, point) > 0 and cross(c, a, point) > 0


class Builder:
    """Gom đỉnh và tam giác; đỉnh dùng chung theo chỉ số."""

    def __init__(self, seed: int) -> None:
        self.dice = random.Random(seed)
        self.points: list[tuple[float, float]] = []
        self.triangles: list[dict] = []

    def quad(self, box, shake: bool) -> list[int]:
        """Bốn góc của một hình chữ nhật, ngược chiều kim đồng hồ; trả chỉ số đỉnh."""
        low_x, low_z, high_x, high_z = box
        loop = []
        for across, down in ((low_x, low_z), (high_x, low_z), (high_x, high_z), (low_x, high_z)):
            shift = (self.dice.uniform(-JITTER, JITTER), self.dice.uniform(-JITTER, JITTER))
            moved = (across + shift[0], down + shift[1]) if shake else (float(across), float(down))
            loop.append(len(self.points))
            self.points.append(moved)
        return loop

    def add(self, corners, flag: int) -> None:
        self.triangles.append({"corners": tuple(corners), "flag": flag})

    def fan(self, loop, flag: int) -> None:
        self.add((loop[0], loop[1], loop[2]), flag)
        self.add((loop[0], loop[2], loop[3]), flag)

    def ring(self, outer, inner, flag: int) -> None:
        """Dải giữa hai tứ giác lồng nhau có góc tương ứng."""
        for index in range(4):
            after = (index + 1) % 4
            self.add((outer[index], outer[after], inner[after]), flag)
            self.add((outer[index], inner[after], inner[index]), flag)

    def segments_of(self, loops):
        for loop in loops:
            for index, start in enumerate(loop):
                yield self.points[start], self.points[loop[(index + 1) % len(loop)]]

    def bridge(self, merged, hole, loops) -> list[int]:
        """Nối lỗ vào đường viền đã gộp bằng một cầu không cắt cạnh nào."""
        choices = []
        for at_hole, inner in enumerate(hole):
            for at_merged, outer in enumerate(merged):
                first, second = self.points[inner], self.points[outer]
                # Đỉnh đã là đầu một cầu khác xuất hiện hai lần trong đường viền: không nối vào nó.
                is_free = merged.count(outer) == 1
                if is_free and not any(is_crossing(first, second, a, b) for a, b in self.segments_of(loops)):
                    gap = (first[0] - second[0]) ** 2 + (first[1] - second[1]) ** 2
                    choices.append((gap, at_merged, at_hole))
        _, at_merged, at_hole = min(choices)
        turned = hole[at_hole:] + hole[:at_hole + 1]
        return merged[:at_merged + 1] + turned + merged[at_merged:]

    def is_ear(self, loop, index: int) -> bool:
        before, here, after = loop[index - 1], loop[index], loop[(index + 1) % len(loop)]
        a, b, c = self.points[before], self.points[here], self.points[after]
        if cross(a, b, c) <= 1e-9:
            return False
        others = [self.points[other] for other in loop if other not in (before, here, after)]
        return not any(is_within(point, a, b, c) for point in others)

    def clip(self, loop, flag: int) -> None:
        """Cắt tai một đa giác ngược chiều kim đồng hồ (có thể có đỉnh lặp do cầu nối)."""
        loop = list(loop)
        while len(loop) > 3:
            ear = next(index for index in range(len(loop)) if self.is_ear(loop, index))
            self.add((loop[ear - 1], loop[ear], loop[(ear + 1) % len(loop)]), flag)
            del loop[ear]
        self.add(loop, flag)


def build(seed: int):
    builder = Builder(seed)
    area = builder.quad((0, 0, SIDE, SIDE), shake=False)
    yard = builder.quad((INSET, INSET, SIDE - INSET, SIDE - INSET), shake=False)
    blocks = [builder.quad(box, shake=True) for box in BLOCKS]
    moat = builder.quad(MOAT, shake=True)
    island = builder.quad(ISLAND, shake=True)
    builder.ring(area, yard, 1)
    for block in blocks:
        builder.fan(block, 1)
    builder.ring(moat, island, 1)
    builder.fan(island, 0)
    holes = blocks + [moat]
    merged = list(yard)
    for hole in sorted(holes, key=lambda loop: -max(builder.points[index][0] for index in loop)):
        merged = builder.bridge(merged, list(reversed(hole)), [yard] + holes + [merged])
    builder.clip(merged, 0)
    triangles = builder.triangles
    covered = sum(cross(*(builder.points[corner] for corner in triangle["corners"])) / 2 for triangle in triangles)
    is_tiling = all(cross(*(builder.points[corner] for corner in triangle["corners"])) > 0 for triangle in triangles)
    if not is_tiling or abs(covered - SIDE * SIDE) > 1e-6:
        raise SystemExit(f"lưới không phủ kín vùng: diện tích {covered}, mong đợi {SIDE * SIDE}")
    edges = link(triangles)
    label_islands(triangles)
    return builder.points, triangles, edges


def link(triangles) -> list[tuple[int, int, int, int]]:
    """Điền hàng xóm (ô k đối diện đỉnh k) và trả các cạnh giữa tam giác vật cản và tam giác đi được."""
    sides = {}
    for number, triangle in enumerate(triangles):
        corners = triangle["corners"]
        triangle["neighbours"] = [NONE, NONE, NONE]
        for k in range(3):
            key = frozenset((corners[(k + 1) % 3], corners[(k + 2) % 3]))
            sides.setdefault(key, []).append((number, k))
    edges = []
    for key, users in sorted(sides.items(), key=lambda item: sorted(item[0])):
        if len(users) != 2:
            continue
        (first, first_side), (second, second_side) = users
        triangles[first]["neighbours"][first_side] = second
        triangles[second]["neighbours"][second_side] = first
        flags = triangles[first]["flag"], triangles[second]["flag"]
        if flags[0] != flags[1]:
            wall, open_side = (first, second) if flags[0] else (second, first)
            low, high = sorted(key)
            edges.append((low, high, wall, open_side))
    return edges


def label_islands(triangles) -> None:
    for triangle in triangles:
        triangle["island"] = 0
    island = 0
    for number, triangle in enumerate(triangles):
        if triangle["flag"] or triangle["island"]:
            continue
        island += 1
        pending = [number]
        triangle["island"] = island
        while pending:
            here = triangles[pending.pop()]
            for neighbour in here["neighbours"]:
                if neighbour == NONE or triangles[neighbour]["flag"]:
                    continue
                if triangles[neighbour]["island"] == 0:
                    triangles[neighbour]["island"] = island
                    pending.append(neighbour)


def cells_of(points) -> list[int]:
    """Các ô lưới tra mà hộp bao của một nhóm điểm chạm tới, kể cả chạm mép."""
    low_x = min(point[0] for point in points)
    high_x = max(point[0] for point in points)
    low_z = min(point[1] for point in points)
    high_z = max(point[1] for point in points)
    count = int(SIDE) // CELL
    found = []
    for row in range(count):
        for column in range(count):
            is_apart_x = high_x < column * CELL or low_x > (column + 1) * CELL
            is_apart_z = high_z < row * CELL or low_z > (row + 1) * CELL
            if not is_apart_x and not is_apart_z:
                found.append(row * count + column)
    return found


def encode(vertices, triangles, edges, is_narrow: bool) -> bytes:
    index = "<H" if is_narrow else "<I"
    none = NARROW_NONE if is_narrow else NONE
    out = bytearray(struct.pack("<H", 0x1000 if is_narrow else 0x2000))
    out += struct.pack(index, len(vertices))
    for across, down in vertices:
        out += struct.pack("<2f", across, down)
    out += struct.pack(index, len(triangles))
    for triangle in triangles:
        for corner in triangle["corners"]:
            out += struct.pack(index, corner)
        for neighbour in triangle["neighbours"]:
            out += struct.pack(index, none if neighbour == NONE else neighbour)
        out += struct.pack("<B", triangle["flag"])
        out += struct.pack(index, triangle["island"])
    out += struct.pack(index, len(edges))
    for edge in edges:
        for field in edge:
            out += struct.pack(index, field)
    count = int(SIDE) // CELL
    out += struct.pack("<I", CELL) + struct.pack(index, count) + struct.pack(index, count)
    in_cell = [([], []) for _ in range(count * count)]
    for number, triangle in enumerate(triangles):
        for cell in cells_of([vertices[corner] for corner in triangle["corners"]]):
            in_cell[cell][0].append(number)
    for number, edge in enumerate(edges):
        for cell in cells_of([vertices[edge[0]], vertices[edge[1]]]):
            in_cell[cell][1].append(number)
    for listed_triangles, listed_edges in in_cell:
        out += struct.pack(index, len(listed_triangles)) + struct.pack(index, len(listed_edges))
        for number in listed_triangles:
            out += struct.pack(index, number)
        for number in listed_edges:
            out += struct.pack(index, number)
    return bytes(out)


def loose_corners(triangles, edges) -> int:
    """Số đỉnh của tam giác đi được không có đúng hai cạnh ràng buộc."""
    count = {}
    for low, high, _, _ in edges:
        count[low] = count.get(low, 0) + 1
        count[high] = count.get(high, 0) + 1
    walked = {corner for triangle in triangles if not triangle["flag"] for corner in triangle["corners"]}
    return sum(1 for corner in walked if count.get(corner, 0) != 2)


def main() -> int:
    parser = argparse.ArgumentParser(description="Sinh tệp .path nhỏ tự vẽ cho test của nav.")
    parser.add_argument("out_file", type=pathlib.Path)
    parser.add_argument("--narrow", action="store_true", help="ghi bản 0x1000 (chỉ số 16 bit)")
    parser.add_argument("--seed", type=int, default=3)
    chosen = parser.parse_args()
    vertices, triangles, edges = build(chosen.seed)
    blob = encode(vertices, triangles, edges, chosen.narrow)
    chosen.out_file.write_bytes(blob)
    islands = max(triangle["island"] for triangle in triangles)
    walkable = sum(1 for triangle in triangles if not triangle["flag"])
    print(f"Đã ghi {chosen.out_file}: {len(vertices)} đỉnh, {len(triangles)} tam giác "
          f"({walkable} đi được), {len(edges)} cạnh ràng buộc, {islands} đảo, {len(blob)} byte; "
          f"đỉnh đi được không có đúng hai cạnh ràng buộc: {loose_corners(triangles, edges)}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
