# Đọc .skeleton OGRE (Serializer v1.10) của client TLBB thành cấu trúc thô: xương, quan hệ cha con,
# animation với khoá hình đúng giá trị trong tệp (khoá của OGRE là độ lệch so với tư thế gốc).
# Nguồn định dạng: OgreSkeletonSerializer.cpp của client (G:\TLBB\_ref) và bộ đọc đã kiểm ở
# G:\TLBB\Dev\tools\bake\ogre_skeleton.cpp. Quyết định:
# - Xương có scale khi độ dài chunk lớn hơn 36, khoá lẻ 0x4110 có scale khi lớn hơn 38: đúng phép thử
#   mà OGRE dùng lúc đọc (độ dài không tính tên xương).
# - Animation đọc theo nội dung, không theo độ dài: writer của client khai thiếu 2 byte ở chunk danh
#   sách khoá 0x4120 và mọi chunk bọc nó.
# - Quaternion trên tệp theo thứ tự x, y, z, w; giữ nguyên thứ tự đó (trùng thứ tự của glTF).
# - Tên giữ ở dạng bytes (client ghi GBK).

from dataclasses import dataclass, field

import numpy as np

from ogre_mesh import Cursor, MeshError

HEADER = 0x1000
BONE = 0x2000
BONE_PARENT = 0x3000
ANIMATION = 0x4000
TRACK = 0x4100
KEY_FRAME = 0x4110
KEY_LIST = 0x4120
ANIMATION_LINK = 0x5000

VERSION = b"[Serializer_v1.10]"
BONE_WITHOUT_SCALE = 36
KEY_WITHOUT_SCALE = 38

KEY_ROTATION = 1
KEY_TRANSLATE = 2
KEY_SCALE = 4
KEY_ALL = KEY_ROTATION | KEY_TRANSLATE | KEY_SCALE


class SkeletonError(MeshError):
    pass


@dataclass
class Bone:
    name: bytes
    handle: int
    position: tuple
    orientation: tuple
    scale: tuple | None


@dataclass
class Track:
    bone: int
    # Hợp các cờ KEY_* của mọi chunk khoá trong track: thành phần nào có ghi trong tệp.
    flags: int = 0
    times: list = field(default_factory=list)
    rotations: list = field(default_factory=list)
    translations: list = field(default_factory=list)
    scales: list = field(default_factory=list)


@dataclass
class Animation:
    name: bytes
    length: float
    tracks: list = field(default_factory=list)
    # Nguyên byte của chunk animation trong tệp, để nơi ghi GLB nhúng kèm dữ liệu gốc.
    source: bytes = b""


@dataclass
class Skeleton:
    bones: list = field(default_factory=list)
    # Từng cặp (handle con, handle cha) theo thứ tự trong tệp.
    parents: list = field(default_factory=list)
    animations: list = field(default_factory=list)
    link_name: bytes | None = None
    link_scale: float | None = None
    stopped_at: int | None = None
    trailing_bytes: int = 0


def read_bone(cursor: Cursor) -> Bone:
    length = cursor.begin_chunk(BONE)
    name = cursor.line()
    handle = cursor.u16()
    position = cursor.unpack("<3f")
    orientation = cursor.unpack("<4f")
    scale = cursor.unpack("<3f") if length > BONE_WITHOUT_SCALE else None
    return Bone(name, handle, position, orientation, scale)


def key_layout(flags: int) -> np.dtype:
    fields = [("time", "<f4")]
    if flags & KEY_ROTATION:
        fields.append(("rotation", "<f4", 4))
    if flags & KEY_TRANSLATE:
        fields.append(("translate", "<f4", 3))
    if flags & KEY_SCALE:
        fields.append(("scale", "<f4", 3))
    return np.dtype(fields)


# Thành phần vắng trong tệp nhận giá trị trung hoà của OGRE: không quay, không dịch, scale 1.
def append_keys(track: Track, keys: np.ndarray, flags: int) -> None:
    count = len(keys)
    track.flags |= flags
    track.times.append(keys["time"].copy())
    rotation = np.tile(np.float32([0, 0, 0, 1]), (count, 1))
    translate = np.zeros((count, 3), np.float32)
    scale = np.ones((count, 3), np.float32)
    track.rotations.append(keys["rotation"].copy() if flags & KEY_ROTATION else rotation)
    track.translations.append(keys["translate"].copy() if flags & KEY_TRANSLATE else translate)
    track.scales.append(keys["scale"].copy() if flags & KEY_SCALE else scale)


def read_key_frame(cursor: Cursor, track: Track) -> None:
    length = cursor.begin_chunk(KEY_FRAME)
    flags = KEY_ALL if length > KEY_WITHOUT_SCALE else KEY_ROTATION | KEY_TRANSLATE
    layout = key_layout(flags)
    keys = np.frombuffer(cursor.take(layout.itemsize), layout)
    append_keys(track, keys, flags)


def read_key_list(cursor: Cursor, track: Track) -> None:
    cursor.begin_chunk(KEY_LIST)
    count, raw_flags = cursor.unpack("<2H")
    flags = raw_flags & KEY_ALL
    layout = key_layout(flags)
    keys = np.frombuffer(cursor.take(count * layout.itemsize), layout)
    append_keys(track, keys, flags)


def join_keys(track: Track) -> None:
    if not track.times:
        track.times = np.zeros(0, np.float32)
        track.rotations = np.zeros((0, 4), np.float32)
        track.translations = np.zeros((0, 3), np.float32)
        track.scales = np.zeros((0, 3), np.float32)
        return
    times = np.concatenate(track.times)
    # AnimationTrack::_sortKeyFrames của OGRE: sắp ổn định theo thời điểm.
    order = np.argsort(times, kind="stable")
    track.times = times[order]
    track.rotations = np.concatenate(track.rotations)[order]
    track.translations = np.concatenate(track.translations)[order]
    track.scales = np.concatenate(track.scales)[order]


def read_track(cursor: Cursor) -> Track:
    cursor.begin_chunk(TRACK)
    track = Track(cursor.u16())
    while True:
        chunk_id = cursor.peek_id()
        if chunk_id == KEY_FRAME:
            read_key_frame(cursor, track)
        elif chunk_id == KEY_LIST:
            read_key_list(cursor, track)
        else:
            break
    join_keys(track)
    return track


def read_animation(cursor: Cursor) -> Animation:
    start = cursor.position
    cursor.begin_chunk(ANIMATION)
    animation = Animation(cursor.line(), cursor.f32())
    while cursor.peek_id() == TRACK:
        animation.tracks.append(read_track(cursor))
    animation.source = cursor.data[start : cursor.position]
    return animation


def read_top_chunk(cursor: Cursor, chunk_id: int, skeleton: Skeleton) -> bool:
    if chunk_id == BONE:
        skeleton.bones.append(read_bone(cursor))
    elif chunk_id == BONE_PARENT:
        cursor.begin_chunk(BONE_PARENT)
        skeleton.parents.append(cursor.unpack("<2H"))
    elif chunk_id == ANIMATION:
        skeleton.animations.append(read_animation(cursor))
    elif chunk_id == ANIMATION_LINK:
        cursor.begin_chunk(ANIMATION_LINK)
        skeleton.link_name = cursor.line()
        skeleton.link_scale = cursor.f32()
    else:
        return False
    return True


# is_bones_only: dừng ở animation đầu tiên (xương và cha con luôn đứng trước), cho nơi chỉ cần xương.
def read_skeleton(data: bytes, is_bones_only: bool = False) -> Skeleton:
    cursor = Cursor(data)
    if cursor.remaining() < 2 or cursor.u16() != HEADER:
        raise SkeletonError("không phải tệp skeleton OGRE")
    version = cursor.line()
    if version != VERSION:
        raise SkeletonError(f"phiên bản lạ: {version!r}")
    skeleton = Skeleton()
    while True:
        chunk_id = cursor.peek_id()
        if chunk_id is None:
            break
        if is_bones_only and chunk_id == ANIMATION:
            return skeleton
        if not read_top_chunk(cursor, chunk_id, skeleton):
            skeleton.stopped_at = chunk_id
            break
    skeleton.trailing_bytes = cursor.remaining()
    return skeleton
