# Kiểm cây GLB đã xuất bằng cách đọc lại từng tệp và so với tệp gốc, đi đường đọc riêng (accessor
# của glTF) chứ không dùng lại mã ghi:
# - mesh: buffer đỉnh và buffer chỉ số của từng submesh trùng từng byte; từng thuộc tính đọc qua
#   accessor trùng bit với thành phần đỉnh gốc; JOINTS/WEIGHTS khớp chunk gán xương theo đúng thứ tự;
#   tên material khớp; URI ảnh trỏ tới tệp có thật. Node xương trong GLB của mesh không kiểm ở đây
#   (cùng mã ghi với GLB của skeleton, đã kiểm ở mục dưới).
# - skeleton: node xương trùng bit; byte chunk animation nhúng trùng nguồn; thời điểm tăng ngặt; kênh
#   dịch bằng tư thế gốc cộng khoá; kênh quay khớp tích ma trận quay (đường tính khác với lúc ghi).
# - cả hai: chỉ số trong JSON hợp lệ, accessor nằm gọn trong bufferView, bufferView trong buffer.
# Cách dùng: python verify_glb.py <kho gốc> <cây đã xuất> [--match <chuỗi>] [--sample N] [--workers N]
# In JSON tổng hợp ra stdout; mã thoát 1 khi có tệp sai.

import argparse
import json
import os
import random
import sys
from collections import Counter
from multiprocessing import Pool
from urllib.parse import unquote

import numpy as np

import glb_writer
import ogre_mesh
import ogre_skeleton
import rig

COMPONENTS = {5120: "i1", 5121: "u1", 5122: "<i2", 5123: "<u2", 5125: "<u4", 5126: "<f4"}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
POSITION = 1
state = {}


class Mismatch(Exception):
    pass


def require(is_true: bool, message: str) -> None:
    if not is_true:
        raise Mismatch(message)


class Glb:
    def __init__(self, path: str):
        with open(path, "rb") as stream:
            self.document, self.binary = glb_writer.read_glb(stream.read())
        self.folder = os.path.dirname(path)

    def view_bytes(self, index: int) -> bytes:
        view = self.document["bufferViews"][index]
        start = view.get("byteOffset", 0)
        require(start + view["byteLength"] <= len(self.binary), "bufferView tràn buffer")
        return self.binary[start : start + view["byteLength"]]

    # Giá trị của một accessor dạng [count, số thành phần], đọc theo byteStride của bufferView.
    def read(self, index: int) -> np.ndarray:
        accessor = self.document["accessors"][index]
        view = self.document["bufferViews"][accessor["bufferView"]]
        kind = np.dtype(COMPONENTS[accessor["componentType"]])
        width = WIDTHS[accessor["type"]]
        size = kind.itemsize * width
        stride = view.get("byteStride", size)
        data = np.frombuffer(self.view_bytes(accessor["bufferView"]), np.uint8)
        offset = accessor.get("byteOffset", 0)
        count = accessor["count"]
        require(count > 0, "accessor rỗng")
        require(offset + stride * (count - 1) + size <= len(data), "accessor tràn bufferView")
        positions = offset + stride * np.arange(count)[:, None] + np.arange(size)[None, :]
        return data[positions].copy().view(kind).reshape(count, width)


def check_indices(document: dict) -> None:
    counts = {key: len(value) for key, value in document.items() if isinstance(value, list)}
    for node in document.get("nodes", []):
        for child in node.get("children", []):
            require(child < counts["nodes"], "node con ngoài danh sách")
        require(node.get("mesh", 0) < max(counts.get("meshes", 0), 1), "node trỏ mesh không có")
    for accessor in document.get("accessors", []):
        require(accessor["bufferView"] < counts["bufferViews"], "accessor trỏ bufferView không có")
    for scene in document.get("scenes", []):
        roots = scene.get("nodes", [])
        require(all(node < counts.get("nodes", 0) for node in roots), "scene trỏ node không có")


def same_bits(left, right) -> bool:
    first = np.asarray(left, "<f4")
    second = np.asarray(right, "<f4")
    return first.shape == second.shape and first.tobytes() == second.tobytes()


def check_bones(glb: Glb, skeleton, first_node: int = 0) -> None:
    nodes = glb.document.get("nodes", [])
    require(len(nodes) >= first_node + len(skeleton.bones), "thiếu node xương")
    parents = dict(skeleton.parents)
    for bone in skeleton.bones:
        node = nodes[first_node + bone.handle]
        require(node["name"] == rig.decode_name(bone.name), "tên xương lệch")
        require(same_bits(node["translation"], bone.position), "vị trí xương lệch")
        require(same_bits(node["rotation"], bone.orientation), "hướng xương lệch")
        require(("scale" in node) == (bone.scale is not None), "scale xương lệch")
        if bone.scale is not None:
            require(same_bits(node["scale"], bone.scale), "scale xương lệch")
    for child, parent in parents.items():
        children = nodes[first_node + parent].get("children", [])
        require(first_node + child in children, "quan hệ cha con lệch")


def source_element(geometry, element) -> np.ndarray:
    buffer = next(b for b in geometry.buffers if b.bind_index == element.source)
    raw = np.frombuffer(buffer.data, np.uint8).reshape(geometry.vertex_count, buffer.vertex_size)
    size = ogre_mesh.ELEMENT_BYTES[element.type]
    return raw[:, element.offset : element.offset + size].copy()


# Tên thuộc tính chuẩn mà một thành phần gốc phải xuất hiện dưới đó, kèm cách diễn giải byte gốc.
def expected_attributes(geometry) -> dict:
    expected = {}
    for element in geometry.elements:
        raw = source_element(geometry, element)
        key = (element.semantic, element.type)
        if key == (1, 2):
            expected["POSITION"] = raw.view("<f4")
        elif key == (1, 3):
            expected["POSITION"] = raw.view("<f4")[:, :3]
            expected["_POSITION_W"] = raw.view("<f4")[:, 3:]
        elif key == (4, 2):
            expected["NORMAL"] = raw.view("<f4")
        elif element.semantic == 7 and element.type == 1:
            expected[f"TEXCOORD_{element.index}"] = raw.view("<f4")
        elif element.semantic == 7:
            expected[f"_TEXCOORD_{element.index}"] = raw.view("<f4")
        elif key == (9, 3):
            expected["TANGENT"] = raw.view("<f4")
        elif key == (9, 2):
            expected["_TANGENT"] = raw.view("<f4")
        elif element.semantic == 5:
            is_direct = element.type == 11
            expected[f"COLOR_{element.index}"] = raw if is_direct else raw[:, [2, 1, 0, 3]]
    return expected


def check_buffers(glb: Glb, primitive: dict, geometry) -> None:
    views = {glb.document["accessors"][a]["bufferView"] for a in primitive["attributes"].values()}
    contents = [glb.view_bytes(view) for view in views]
    for buffer in geometry.buffers:
        require(buffer.data in contents, f"buffer đỉnh {buffer.bind_index} không trùng byte")


def check_attributes(glb: Glb, primitive: dict, geometry) -> None:
    attributes = primitive["attributes"]
    for name, source in expected_attributes(geometry).items():
        require(name in attributes, f"thiếu thuộc tính {name}")
        values = glb.read(attributes[name])
        require(values.tobytes() == np.ascontiguousarray(source).tobytes(), f"{name} lệch bit")
    position = glb.document["accessors"][attributes["POSITION"]]
    values = glb.read(attributes["POSITION"])
    require(same_bits(position["min"], values.min(axis=0)), "min của POSITION lệch")
    require(same_bits(position["max"], values.max(axis=0)), "max của POSITION lệch")


def check_weights(glb: Glb, primitive: dict, submesh, vertex_count: int) -> None:
    attributes = primitive["attributes"]
    weights = submesh.weights
    if weights is None or len(weights) == 0:
        require("JOINTS_0" not in attributes, "có JOINTS mà nguồn không gán xương")
        return
    sets = sorted(int(name[7:]) for name in attributes if name.startswith("JOINTS_"))
    require(sets == list(range(len(sets))) and sets, "bộ JOINTS không liền mạch")
    joints = np.concatenate([glb.read(attributes[f"JOINTS_{index}"]) for index in sets], axis=1)
    values = np.concatenate([glb.read(attributes[f"WEIGHTS_{index}"]) for index in sets], axis=1)
    vertices = weights["vertex"].astype(np.int64)
    order = np.argsort(vertices, kind="stable")
    sorted_vertices = vertices[order]
    ranks = np.arange(len(order)) - np.searchsorted(sorted_vertices, sorted_vertices, side="left")
    require(ranks.max() < joints.shape[1], "thiếu bộ JOINTS cho đỉnh nhiều xương")
    require((joints[sorted_vertices, ranks] == weights["bone"][order]).all(), "chỉ số xương lệch")
    written = values[sorted_vertices, ranks].astype("<f4").tobytes()
    require(written == weights["weight"][order].astype("<f4").tobytes(), "trọng số lệch bit")
    used = np.zeros(joints.shape, bool)
    used[sorted_vertices, ranks] = True
    require((joints[~used] == 0).all() and (values[~used] == 0).all(), "ô trống không bằng 0")


def check_images(glb: Glb) -> None:
    for image in glb.document.get("images", []):
        path = os.path.normpath(os.path.join(glb.folder, unquote(image["uri"])))
        require(os.path.isfile(path), f"ảnh không tồn tại: {image['uri']}")


def check_mesh(source: str, output: str) -> None:
    with open(source, "rb") as stream:
        mesh = ogre_mesh.read_mesh(stream.read())
    glb = Glb(output)
    check_indices(glb.document)
    primitives = glb.document["meshes"][0]["primitives"]
    submeshes = [s for s in mesh.submeshes if s.geometry is not None and s.index_count]
    require(len(primitives) == len(submeshes), "số primitive khác số submesh")
    for primitive, submesh in zip(primitives, submeshes):
        geometry = submesh.geometry
        accessor = glb.document["accessors"][primitive["indices"]]
        require(glb.view_bytes(accessor["bufferView"]) == submesh.indices, "chỉ số không trùng byte")
        require(accessor["count"] == submesh.index_count, "số chỉ số lệch")
        indices = glb.read(primitive["indices"])
        require(int(indices.max()) < geometry.vertex_count, "chỉ số vượt số đỉnh")
        require(submesh.index_count % 3 == 0, "số chỉ số không chia hết cho 3")
        check_buffers(glb, primitive, geometry)
        check_attributes(glb, primitive, geometry)
        check_weights(glb, primitive, submesh, geometry.vertex_count)
        material = glb.document["materials"][primitive["material"]]
        require(material["name"] == rig.decode_name(submesh.material), "tên material lệch")
    check_images(glb)


def rotation_matrices(quaternions: np.ndarray) -> np.ndarray:
    q = quaternions.astype(np.float64)
    q = q / np.linalg.norm(q, axis=1, keepdims=True)
    x, y, z, w = q[:, 0], q[:, 1], q[:, 2], q[:, 3]
    rows = [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ]
    return np.array(rows).transpose(2, 0, 1)


def check_channel(glb: Glb, channel: dict, sampler: dict, skeleton, track) -> None:
    times = glb.read(sampler["input"])[:, 0]
    require(len(times) == len(track.times), "số khoá lệch")
    require((np.diff(times) > 0).all(), "thời điểm không tăng ngặt")
    require(np.abs(times - track.times).max() <= 1e-4, "thời điểm lệch")
    bone = skeleton.bones[track.bone]
    values = glb.read(sampler["output"])
    path = channel["target"]["path"]
    if path == "translation":
        moved = (np.float64(bone.position) + track.translations.astype(np.float64)).astype("<f4")
        require(values.tobytes() == moved.tobytes(), "kênh dịch lệch bit")
    elif path == "rotation":
        base = rotation_matrices(np.float64([bone.orientation]))[0]
        expected = base @ rotation_matrices(track.rotations)
        require(np.abs(rotation_matrices(values) - expected).max() < 2e-6, "kênh quay lệch")
    else:
        base = bone.scale if bone.scale is not None else (1.0, 1.0, 1.0)
        scaled = (np.float64(base) * track.scales.astype(np.float64)).astype("<f4")
        require(values.tobytes() == scaled.tobytes(), "kênh scale lệch bit")


def check_skeleton(source: str, output: str) -> None:
    with open(source, "rb") as stream:
        skeleton = ogre_skeleton.read_skeleton(stream.read())
    glb = Glb(output)
    check_indices(glb.document)
    check_bones(glb, skeleton)
    written = {a["name"]: a for a in glb.document.get("animations", [])}
    empty = glb.document["scenes"][0].get("extras", {}).get("ogre", {})
    empty = {a["name"]: a for a in empty.get("animations_without_channels", [])}
    require(len(written) + len(empty) == len(skeleton.animations), "số animation lệch")
    for animation in skeleton.animations:
        name = rig.decode_name(animation.name)
        entry = written.get(name)
        details = entry["extras"]["ogre"] if entry else empty[name]
        require(glb.view_bytes(details["source_view"]) == animation.source, "chunk gốc không trùng byte")
        require(same_bits([details["length"]], [animation.length]), "độ dài animation lệch")
        if entry is None:
            continue
        tracks = {track.bone: track for track in animation.tracks}
        expected = sum(bin(t.flags).count("1") for t in animation.tracks if len(t.times))
        require(len(entry["channels"]) == expected, "số kênh lệch")
        for channel in entry["channels"]:
            sampler = entry["samplers"][channel["sampler"]]
            check_channel(glb, channel, sampler, skeleton, tracks[channel["target"]["node"]])


def check_one(task: tuple) -> tuple:
    kind, source, output = task
    try:
        checker = check_mesh if kind == "mesh" else check_skeleton
        checker(os.path.join(state["root"], source), os.path.join(state["target"], output))
    # Mọi lỗi của một tệp thành một dòng kết quả, không làm dừng lượt kiểm.
    except Exception as error:  # noqa: BLE001
        return kind, source, f"{type(error).__name__}: {error}"
    return kind, source, ""


def start_worker(root: str, target: str) -> None:
    state.update(root=root, target=target)


def read_tasks(target: str, match: str | None, sample: int | None) -> list:
    tasks = []
    with open(target + ".manifest.tsv", encoding="utf-8") as stream:
        next(stream)
        for line in stream:
            kind, source, output, status = line.rstrip("\n").split("\t")[:4]
            is_wanted = kind in ("mesh", "skeleton") and status != "lỗi"
            if is_wanted and (not match or match in source):
                tasks.append((kind, source, output))
    if sample is not None and sample < len(tasks):
        tasks = random.Random(20261005).sample(tasks, sample)
    return tasks


def main() -> int:
    parser = argparse.ArgumentParser(description="Kiểm cây GLB so với kho gốc")
    parser.add_argument("root")
    parser.add_argument("target")
    parser.add_argument("--match")
    parser.add_argument("--sample", type=int)
    parser.add_argument("--workers", type=int, default=16)
    arguments = parser.parse_args()
    root = os.path.abspath(arguments.root)
    target = os.path.abspath(arguments.target)
    tasks = read_tasks(target, arguments.match, arguments.sample)
    counts = Counter()
    failures = []
    with Pool(arguments.workers, start_worker, (root, target)) as pool:
        for kind, source, error in pool.imap_unordered(check_one, tasks, chunksize=16):
            counts[f"{kind} {'sai' if error else 'đúng'}"] += 1
            if error:
                failures.append([kind, source, error])
    report = {"checked": len(tasks), "counts": dict(sorted(counts.items()))}
    report["failures"] = sorted(failures)[:15]
    json.dump(report, sys.stdout, ensure_ascii=False, indent=1)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
