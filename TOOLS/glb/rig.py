# Đưa skeleton OGRE vào GLB: mỗi xương một node (chỉ số node = handle của xương), tư thế gốc chép
# nguyên giá trị trong tệp, ma trận nghịch đảo tư thế gốc cho skin, và animation.
# Quyết định:
# - Khoá hình của OGRE là độ lệch so với tư thế gốc, glTF cần giá trị tuyệt đối. Đổi theo đúng
#   NodeAnimationTrack::applyToNode và Node::translate/rotate/scale của OGRE:
#   dịch = dịch gốc + khoá; quay = quay gốc * chuẩn hoá(khoá); scale = scale gốc * khoá.
#   Phép tính làm ở double rồi làm tròn về float32. Nguyên byte chunk animation gốc được nhúng kèm
#   (extras.ogre.source_view) để không mất giá trị nào.
# - Thành phần mà tệp không ghi (cờ khoá vắng) bằng tư thế gốc, nên không sinh kênh.
# - glTF đòi thời điểm tăng ngặt. Khoá trùng thời điểm (bước nhảy trong OGRE) được dời lên số thực
#   float32 kế tiếp; số lần dời trả về để báo cáo.
# - Ma trận nghịch đảo tính theo nghĩa glTF (tích ma trận T*R*S dọc cây). Với xương scale khác 1,
#   OGRE nhân scale theo từng thành phần chứ không qua ma trận nên có thể lệch khi đang chuyển động.

from dataclasses import dataclass

import numpy as np

import glb_writer
import ogre_skeleton

IDENTITY_SCALE = (1.0, 1.0, 1.0)


# Tên trong tệp OGRE của client là GBK; gb18030 là tập cha nên giải được cả hai.
def decode_name(raw: bytes) -> str:
    try:
        return raw.decode("gb18030")
    except UnicodeDecodeError:
        return raw.decode("gb18030", "replace")


@dataclass
class BoneNodes:
    first_node: int
    count: int
    roots: list
    inverse_binds: np.ndarray


def rotation_matrix(orientation) -> np.ndarray:
    x, y, z, w = (float(value) for value in orientation)
    return np.array(
        [
            [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
        ]
    )


def local_matrix(bone: ogre_skeleton.Bone) -> np.ndarray:
    matrix = np.identity(4)
    scale = bone.scale if bone.scale is not None else IDENTITY_SCALE
    matrix[:3, :3] = rotation_matrix(bone.orientation) * np.float64(scale)
    matrix[:3, 3] = bone.position
    return matrix


def parent_map(skeleton: ogre_skeleton.Skeleton) -> dict:
    count = len(skeleton.bones)
    parents = {}
    for child, parent in skeleton.parents:
        is_known = child < count and parent < count and child not in parents
        if not is_known:
            raise ogre_skeleton.SkeletonError(f"quan hệ cha con sai: {child} -> {parent}")
        parents[child] = parent
    return parents


def global_matrices(skeleton: ogre_skeleton.Skeleton, parents: dict) -> list:
    matrices = [None] * len(skeleton.bones)
    for handle in range(len(skeleton.bones)):
        chain = []
        current = handle
        while current is not None and matrices[current] is None:
            if current in chain:
                raise ogre_skeleton.SkeletonError("cây xương có vòng")
            chain.append(current)
            current = parents.get(current)
        for link in reversed(chain):
            local = local_matrix(skeleton.bones[link])
            above = parents.get(link)
            matrices[link] = local if above is None else matrices[above] @ local
    return matrices


def inverse_bind_matrices(matrices: list) -> np.ndarray:
    result = np.zeros((len(matrices), 4, 4), np.float32)
    for index, matrix in enumerate(matrices):
        inverse = np.linalg.inv(matrix)
        inverse[3] = (0.0, 0.0, 0.0, 1.0)
        # glTF lưu ma trận theo cột.
        result[index] = inverse.T.astype(np.float32)
    return result


def bone_node(bone: ogre_skeleton.Bone) -> dict:
    node = {"name": decode_name(bone.name)}
    node["translation"] = list(bone.position)
    node["rotation"] = list(bone.orientation)
    if bone.scale is not None:
        node["scale"] = list(bone.scale)
    return node


# Thêm mọi xương thành node theo thứ tự handle; phải gọi khi builder chưa có node nào khác đứng
# trước nếu muốn chỉ số node trùng handle.
def add_bones(builder: glb_writer.GlbBuilder, skeleton: ogre_skeleton.Skeleton) -> BoneNodes:
    handles = [bone.handle for bone in skeleton.bones]
    if handles != list(range(len(handles))):
        raise ogre_skeleton.SkeletonError("handle xương không liền mạch từ 0")
    parents = parent_map(skeleton)
    first_node = len(builder.document.get("nodes", []))
    nodes = [bone_node(bone) for bone in skeleton.bones]
    for child, parent in skeleton.parents:
        nodes[parent].setdefault("children", []).append(first_node + child)
    for node in nodes:
        builder.add("nodes", node)
    roots = [first_node + handle for handle in range(len(nodes)) if handle not in parents]
    inverse_binds = inverse_bind_matrices(global_matrices(skeleton, parents))
    return BoneNodes(first_node, len(nodes), roots, inverse_binds)


# Thời điểm tăng ngặt: giá trị không lớn hơn giá trị đứng trước được dời lên float32 kế tiếp.
def increasing_times(times: np.ndarray) -> tuple[np.ndarray, int]:
    if len(times) < 2 or (np.diff(times) > 0).all():
        return times, 0
    fixed = times.copy()
    moved = 0
    for index in range(1, len(fixed)):
        if fixed[index] <= fixed[index - 1]:
            fixed[index] = np.nextafter(fixed[index - 1], np.float32(np.inf))
            moved += 1
    return fixed, moved


# Tích quaternion a * b theo thứ tự x, y, z, w, công thức của Quaternion::operator* trong OGRE.
def multiply_rotations(first, keys: np.ndarray) -> np.ndarray:
    ax, ay, az, aw = (float(value) for value in first)
    keys = keys.astype(np.float64)
    keys = keys / np.sqrt((keys * keys).sum(axis=1, keepdims=True))
    bx, by, bz, bw = keys[:, 0], keys[:, 1], keys[:, 2], keys[:, 3]
    product = np.empty_like(keys)
    product[:, 0] = aw * bx + ax * bw + ay * bz - az * by
    product[:, 1] = aw * by + ay * bw + az * bx - ax * bz
    product[:, 2] = aw * bz + az * bw + ax * by - ay * bx
    product[:, 3] = aw * bw - ax * bx - ay * by - az * bz
    return product.astype(np.float32)


def absolute_channels(bone: ogre_skeleton.Bone, track: ogre_skeleton.Track) -> list:
    channels = []
    if track.flags & ogre_skeleton.KEY_ROTATION:
        channels.append(("rotation", "VEC4", multiply_rotations(bone.orientation, track.rotations)))
    if track.flags & ogre_skeleton.KEY_TRANSLATE:
        moved = np.float64(bone.position) + track.translations.astype(np.float64)
        channels.append(("translation", "VEC3", moved.astype(np.float32)))
    if track.flags & ogre_skeleton.KEY_SCALE:
        base = bone.scale if bone.scale is not None else IDENTITY_SCALE
        scaled = np.float64(base) * track.scales.astype(np.float64)
        channels.append(("scale", "VEC3", scaled.astype(np.float32)))
    return channels


class AnimationPack:
    # Gom dữ liệu của một animation vào một bufferView; accessor trỏ bằng byteOffset.
    def __init__(self, builder: glb_writer.GlbBuilder):
        self.builder = builder
        self.parts = []
        self.byte_length = 0
        self.pending = []

    def add(self, values: np.ndarray, kind: str, bounds=None) -> int:
        accessor = {"componentType": glb_writer.FLOAT, "type": kind, "count": len(values)}
        accessor["byteOffset"] = self.byte_length
        if bounds is not None:
            accessor["min"] = [float(bounds[0])]
            accessor["max"] = [float(bounds[1])]
        data = np.ascontiguousarray(values, "<f4").tobytes()
        self.parts.append(data)
        self.byte_length += len(data)
        self.pending.append(accessor)
        return self.builder.add("accessors", accessor)

    def close(self) -> None:
        if not self.pending:
            return
        view = self.builder.add_view(b"".join(self.parts))
        for accessor in self.pending:
            accessor["bufferView"] = view


def add_track(pack: AnimationPack, track, bone, node: int, target: dict) -> int:
    if len(track.times) == 0:
        return 0
    channels = absolute_channels(bone, track)
    if not channels:
        return 0
    times, moved = increasing_times(track.times)
    time_accessor = pack.add(times, "SCALAR", (times[0], times[-1]))
    for path, kind, values in channels:
        sampler = {"input": time_accessor, "output": pack.add(values, kind)}
        target["samplers"].append(sampler)
        channel_target = {"node": node, "path": path}
        channel = {"sampler": len(target["samplers"]) - 1, "target": channel_target}
        target["channels"].append(channel)
    return moved


# Trả về số khoá đã phải dời thời điểm. Animation không có kênh nào vẫn được ghi tên và độ dài trong
# extras của scene, vì glTF không cho animation rỗng.
def add_animations(builder, skeleton: ogre_skeleton.Skeleton, bones: BoneNodes) -> tuple[int, list]:
    moved = 0
    empty = []
    for animation in skeleton.animations:
        name = decode_name(animation.name)
        target = {"name": name, "samplers": [], "channels": []}
        pack = AnimationPack(builder)
        for track in animation.tracks:
            if track.bone >= bones.count:
                raise ogre_skeleton.SkeletonError(f"track trỏ xương {track.bone} không có")
            bone = skeleton.bones[track.bone]
            moved += add_track(pack, track, bone, bones.first_node + track.bone, target)
        pack.close()
        source_view = builder.add_view(animation.source)
        details = {"length": animation.length, "source_view": source_view}
        if not target["channels"]:
            empty.append({"name": name, **details})
            continue
        target["extras"] = {"ogre": details}
        builder.add("animations", target)
    return moved, empty
