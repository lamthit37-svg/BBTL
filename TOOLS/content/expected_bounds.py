# Tính ĐỘC LẬP với client (Python, float64) hộp bao thế giới của từng StaticEntity trong một cảnh,
# để so với tệp mà client ghi bằng --dump-bounds. Dùng để kiểm bằng số rằng client đặt vật thể đúng
# phép đặt gốc.
#   python TOOLS/content/expected_bounds.py <thư mục data> <tên cảnh> [--out <tệp.tsv>]
#                                           [--compare <tệp.tsv của client>] [--tolerance 0.001]
# Cách tính, theo client gốc (OGRE 1.2.5):
# - "position", "scale" là ba số, "orientation" là bốn số theo thứ tự w x y z; mỗi số đọc như atof
#   rồi làm tròn về float32. Sai số token: vector thành 0 0 0, quaternion thành đơn vị. Thiếu thuộc
#   tính: vị trí 0, hướng đơn vị, tỉ lệ 1.
# - Ma trận là T * R * S với vectơ cột; R tính từ quaternion KHÔNG chuẩn hoá bằng công thức của
#   Quaternion::ToRotationMatrix.
# - Hộp cục bộ của một GLB là hợp của min/max mọi accessor POSITION mà các primitive của nó dùng;
#   hộp thế giới là hộp bao theo trục của tám góc hộp cục bộ sau khi nhân ma trận.
# Mỗi dòng của tệp TSV: số thứ tự (từ 0, theo thứ tự StaticEntity trong tệp cảnh), tên mesh, rồi
# sáu số thấp x y z, cao x y z. Mã thoát: 0 khớp hoặc không so; 1 lệch quá ngưỡng; 2 dữ liệu lạ.
import argparse
import json
import pathlib
import struct
import sys
import xml.etree.ElementTree as ElementTree

GLB_MAGIC = 0x46546C67
JSON_CHUNK = 0x4E4F534A
NODE_TRANSFORM_KEYS = ("matrix", "translation", "rotation", "scale")


def to_float32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


# Số ở đầu chuỗi như atof: không đọc được thì 0.
def parse_real(text: str) -> float:
    for end in range(len(text), 0, -1):
        try:
            return to_float32(float(text[:end]))
        except (ValueError, OverflowError):
            continue
    return 0.0


def parse_numbers(text: str | None, count: int, fallback: list[float]) -> list[float]:
    if text is None:
        return list(fallback)
    tokens = text.split()
    if len(tokens) != count:
        return [0.0] * count if count == 3 else [1.0, 0.0, 0.0, 0.0]
    return [parse_real(token) for token in tokens]


def rotation_rows(quat_w: float, quat_x: float, quat_y: float, quat_z: float) -> list[list[float]]:
    two_x, two_y, two_z = 2.0 * quat_x, 2.0 * quat_y, 2.0 * quat_z
    two_wx, two_wy, two_wz = two_x * quat_w, two_y * quat_w, two_z * quat_w
    two_xx, two_xy, two_xz = two_x * quat_x, two_y * quat_x, two_z * quat_x
    two_yy, two_yz, two_zz = two_y * quat_y, two_z * quat_y, two_z * quat_z
    return [
        [1.0 - (two_yy + two_zz), two_xy - two_wz, two_xz + two_wy],
        [two_xy + two_wz, 1.0 - (two_xx + two_zz), two_yz - two_wx],
        [two_xz - two_wy, two_yz + two_wx, 1.0 - (two_xx + two_yy)],
    ]


def transform_rows(properties: dict[str, str]) -> list[list[float]]:
    position = parse_numbers(properties.get("position"), 3, [0.0, 0.0, 0.0])
    turn = parse_numbers(properties.get("orientation"), 4, [1.0, 0.0, 0.0, 0.0])
    scale = parse_numbers(properties.get("scale"), 3, [1.0, 1.0, 1.0])
    rotation = rotation_rows(turn[0], turn[1], turn[2], turn[3])
    return [[rotation[row][0] * scale[0], rotation[row][1] * scale[1], rotation[row][2] * scale[2],
             position[row]] for row in range(3)]


def glb_json(path: pathlib.Path) -> dict:
    data = path.read_bytes()
    magic, _, _ = struct.unpack_from("<III", data, 0)
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if magic != GLB_MAGIC or chunk_type != JSON_CHUNK:
        raise SystemExit(f"không phải GLB: {path}")
    return json.loads(data[20:20 + chunk_length].decode("utf-8"))


def local_box(path: pathlib.Path) -> tuple[list[float], list[float]]:
    document = glb_json(path)
    for node in document.get("nodes", []):
        if any(key in node for key in NODE_TRANSFORM_KEYS):
            print(f"GLB có nút mang phép biến đổi, công cụ chưa tính: {path}")
            raise SystemExit(2)
    low = [float("inf")] * 3
    high = [float("-inf")] * 3
    for mesh in document["meshes"]:
        for primitive in mesh["primitives"]:
            accessor = document["accessors"][primitive["attributes"]["POSITION"]]
            low = [min(a, b) for a, b in zip(low, accessor["min"])]
            high = [max(a, b) for a, b in zip(high, accessor["max"])]
    return low, high


def world_box(rows: list[list[float]], low: list[float], high: list[float]) -> list[float]:
    corners = [[(high if index >> axis & 1 else low)[axis] for axis in range(3)]
               for index in range(8)]
    moved = [[row[0] * x + row[1] * y + row[2] * z + row[3] for row in rows] for x, y, z in corners]
    return [min(point[axis] for point in moved) for axis in range(3)] + \
           [max(point[axis] for point in moved) for axis in range(3)]


# Mọi <Object> của cảnh theo thứ tự trong tệp, kể cả nằm trong <Group>.
def static_entities(scene_path: pathlib.Path) -> list[dict[str, str]]:
    root = ElementTree.parse(scene_path).getroot()
    entities = []
    for element in root.iter("Object"):
        if element.get("type") != "StaticEntity":
            continue
        entities.append({item.get("name"): item.get("value") for item in element.iter("Property")})
    return entities


def expected(data: pathlib.Path, scene: str) -> list[tuple[str, list[float]]]:
    boxes: dict[str, tuple[list[float], list[float]]] = {}
    result = []
    for properties in static_entities(data / "Scene" / f"{scene}.Scene"):
        mesh = properties.get("mesh name", "")
        if mesh not in boxes:
            boxes[mesh] = local_box(data / "Model" / f"{mesh}.glb")
        low, high = boxes[mesh]
        result.append((mesh, world_box(transform_rows(properties), low, high)))
    return result


def write_table(path: pathlib.Path, rows: list[tuple[str, list[float]]]) -> None:
    lines = ["\t".join([str(index), mesh] + [repr(value) for value in box])
             for index, (mesh, box) in enumerate(rows)]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def read_table(path: pathlib.Path) -> list[tuple[str, list[float]]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        cells = line.split("\t")
        rows.append((cells[1], [float(cell) for cell in cells[2:8]]))
    return rows


def compare(ours: list, theirs: list, tolerance: float) -> int:
    if len(ours) != len(theirs):
        print(f"số vật thể khác nhau: tính được {len(ours)}, client ghi {len(theirs)}")
        return 1
    worst = 0.0
    failures = 0
    for index, ((mesh, box), (their_mesh, their_box)) in enumerate(zip(ours, theirs)):
        gap = max(abs(a - b) for a, b in zip(box, their_box))
        worst = max(worst, gap)
        bad = gap > tolerance or mesh != their_mesh
        failures += int(bad)
        if bad:
            print(f"LỆCH vật thể {index} ({mesh} / {their_mesh}): {gap:.6f}")
    print(f"{len(ours)} vật thể, lệch lớn nhất {worst:.9f}, vượt ngưỡng {tolerance}: {failures}")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Hộp bao thế giới kỳ vọng của các StaticEntity.")
    parser.add_argument("data", type=pathlib.Path)
    parser.add_argument("scene")
    parser.add_argument("--out", type=pathlib.Path)
    parser.add_argument("--compare", type=pathlib.Path)
    parser.add_argument("--tolerance", type=float, default=0.001)
    options = parser.parse_args()
    rows = expected(options.data, options.scene)
    if options.out is not None:
        write_table(options.out, rows)
    if options.compare is not None:
        return compare(rows, read_table(options.compare), options.tolerance)
    print(f"{len(rows)} vật thể; ví dụ vật thể 0 ({rows[0][0]}): {rows[0][1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
