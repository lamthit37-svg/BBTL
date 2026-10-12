# Đọc .mesh OGRE (MeshSerializer v1.40 và v1.30) của client TLBB thành cấu trúc thô: mọi buffer đỉnh,
# chỉ số, gán xương giữ nguyên byte như trong tệp, không đổi đơn vị, không gộp hay sắp lại.
# Nguồn định dạng: OgreMeshSerializerImpl.cpp của OGRE 1.x và bộ đọc đã kiểm trên dữ liệu thật ở
# G:\TLBB\Dev\tools\bake\ogre_mesh.cpp. Quyết định:
# - Đọc theo cấu trúc, không theo độ dài ghi trong header chunk: serializer của client ghi độ dài
#   M_MESH và M_SUBMESH sai (lớn hơn cả tệp). Độ dài chỉ dùng để nhảy qua chunk không đọc thân.
# - Chuỗi (tên material, skeleton) giữ ở dạng bytes; client ghi bằng GBK, nơi dùng tự giải mã.
# - Chunk lạ không bị nuốt: ghi vào Mesh.stopped_at để lượt thống kê nhìn thấy.

import struct
from dataclasses import dataclass, field

import numpy as np

HEADER = 0x1000
MESH = 0x3000
SUBMESH = 0x4000
SUBMESH_OPERATION = 0x4010
SUBMESH_BONE = 0x4100
SUBMESH_ALIAS = 0x4200
GEOMETRY = 0x5000
DECLARATION = 0x5100
ELEMENT = 0x5110
BUFFER = 0x5200
BUFFER_DATA = 0x5210
SKELETON_LINK = 0x6000
MESH_BONE = 0x7000
LOD = 0x8000
LOD_USAGE = 0x8100
LOD_MANUAL = 0x8110
LOD_GENERATED = 0x8120
BOUNDS = 0x9000
NAME_TABLE = 0xA000
NAME_ELEMENT = 0xA100
EDGE_LISTS = 0xB000
POSES = 0xC000
ANIMATIONS = 0xD000
EXTREMES = 0xE000

VERSIONS = (b"[MeshSerializer_v1.40]", b"[MeshSerializer_v1.30]")
CHUNK_HEADER_BYTES = 6
# OT_TRIANGLE_LIST: giá trị OGRE dùng khi submesh không có chunk 0x4010.
TRIANGLE_LIST = 4

# Số byte của kiểu thành phần đỉnh (VertexElementType của OGRE), theo giá trị trên tệp.
ELEMENT_BYTES = {0: 4, 1: 8, 2: 12, 3: 16, 4: 4, 5: 2, 6: 4, 7: 6, 8: 8, 9: 4, 10: 4, 11: 4}

# Một bản ghi gán xương kèm header chunk của nó: các bản ghi nằm liền nhau, cách đều 16 byte.
BONE_RECORD = np.dtype(
    [("id", "<u2"), ("length", "<u4"), ("vertex", "<u4"), ("bone", "<u2"), ("weight", "<f4")]
)


class MeshError(Exception):
    pass


@dataclass
class VertexElement:
    source: int
    type: int
    semantic: int
    offset: int
    index: int


@dataclass
class VertexBuffer:
    bind_index: int
    vertex_size: int
    data: bytes


@dataclass
class Geometry:
    vertex_count: int
    elements: list = field(default_factory=list)
    buffers: list = field(default_factory=list)


@dataclass
class SubMesh:
    material: bytes
    uses_shared: bool
    index_count: int
    is_wide: bool
    indices: bytes
    geometry: Geometry | None = None
    operation: int = TRIANGLE_LIST
    has_operation: bool = False
    weights: np.ndarray | None = None
    aliases: list = field(default_factory=list)
    name: bytes | None = None


@dataclass
class LodLevel:
    from_depth_squared: float
    manual_mesh: bytes | None = None
    # Mỗi submesh một bộ (số chỉ số, 32 bit hay không, byte chỉ số).
    generated: list = field(default_factory=list)


@dataclass
class Mesh:
    version: bytes
    is_animated: bool
    shared: Geometry | None = None
    submeshes: list = field(default_factory=list)
    skeleton: bytes | None = None
    shared_weights: np.ndarray | None = None
    bounds: tuple | None = None
    lod_levels: list = field(default_factory=list)
    is_lod_manual: bool = False
    # id của các chunk cấp mesh bị nhảy qua theo độ dài (edge list, pose, animation, extremes).
    skipped: list = field(default_factory=list)
    # id chunk lạ làm bộ đọc dừng, và số byte còn lại lúc dừng; None khi đọc hết tệp.
    stopped_at: int | None = None
    trailing_bytes: int = 0


class Cursor:
    def __init__(self, data: bytes):
        self.data = data
        self.position = 0

    def remaining(self) -> int:
        return len(self.data) - self.position

    def take(self, size: int) -> bytes:
        if size < 0 or size > self.remaining():
            raise MeshError(f"thiếu dữ liệu: cần {size} byte ở vị trí {self.position}")
        start = self.position
        self.position += size
        return self.data[start : start + size]

    def unpack(self, layout: str):
        size = struct.calcsize(layout)
        if size > self.remaining():
            raise MeshError(f"thiếu dữ liệu: cần {size} byte ở vị trí {self.position}")
        values = struct.unpack_from(layout, self.data, self.position)
        self.position += size
        return values

    def u8(self) -> int:
        return self.unpack("<B")[0]

    def u16(self) -> int:
        return self.unpack("<H")[0]

    def u32(self) -> int:
        return self.unpack("<I")[0]

    def f32(self) -> float:
        return self.unpack("<f")[0]

    # Chuỗi của OGRE kết thúc bằng "\n", không có độ dài đứng trước.
    def line(self) -> bytes:
        end = self.data.find(b"\n", self.position)
        if end < 0:
            raise MeshError(f"chuỗi không có dấu kết ở vị trí {self.position}")
        value = self.data[self.position : end]
        self.position = end + 1
        return value

    # id của chunk kế tiếp, None khi không còn đủ một header.
    def peek_id(self) -> int | None:
        if self.remaining() < CHUNK_HEADER_BYTES:
            return None
        return struct.unpack_from("<H", self.data, self.position)[0]

    def begin_chunk(self, expected: int) -> int:
        chunk_id, length = self.unpack("<HI")
        if chunk_id != expected:
            raise MeshError(f"chờ chunk {expected:#06x}, gặp {chunk_id:#06x}")
        return length

    # Nhảy qua một chunk theo độ dài nó khai; trả về False khi độ dài không dẫn tới chỗ hợp lệ.
    def skip_chunk(self) -> bool:
        start = self.position
        _, length = self.unpack("<HI")
        target = start + length
        if length < CHUNK_HEADER_BYTES or target > len(self.data):
            self.position = start
            return False
        self.position = target
        return True


def read_declaration(cursor: Cursor, geometry: Geometry) -> None:
    cursor.begin_chunk(DECLARATION)
    while cursor.peek_id() == ELEMENT:
        cursor.begin_chunk(ELEMENT)
        source, kind, semantic, offset, index = cursor.unpack("<5H")
        geometry.elements.append(VertexElement(source, kind, semantic, offset, index))


def read_buffer(cursor: Cursor, geometry: Geometry) -> None:
    cursor.begin_chunk(BUFFER)
    bind_index, vertex_size = cursor.unpack("<2H")
    if vertex_size == 0:
        raise MeshError("buffer đỉnh có cỡ đỉnh 0")
    cursor.begin_chunk(BUFFER_DATA)
    # Cỡ thân tính từ số đỉnh, không lấy độ dài header khai.
    data = cursor.take(geometry.vertex_count * vertex_size)
    geometry.buffers.append(VertexBuffer(bind_index, vertex_size, data))


def check_geometry(geometry: Geometry) -> None:
    sizes = {buffer.bind_index: buffer.vertex_size for buffer in geometry.buffers}
    if len(sizes) != len(geometry.buffers):
        raise MeshError("hai buffer đỉnh cùng bind index")
    for element in geometry.elements:
        size = ELEMENT_BYTES.get(element.type)
        if size is None:
            raise MeshError(f"kiểu thành phần đỉnh lạ: {element.type}")
        if element.source not in sizes:
            raise MeshError(f"thành phần trỏ buffer {element.source} không có")
        if element.offset + size > sizes[element.source]:
            raise MeshError("thành phần tràn khỏi cỡ đỉnh")


# Hình học 0 đỉnh có thật trong dữ liệu; OGRE coi như không có.
def read_geometry(cursor: Cursor) -> Geometry | None:
    cursor.begin_chunk(GEOMETRY)
    geometry = Geometry(cursor.u32())
    if geometry.vertex_count == 0:
        return None
    while True:
        chunk_id = cursor.peek_id()
        if chunk_id == DECLARATION:
            read_declaration(cursor, geometry)
        elif chunk_id == BUFFER:
            read_buffer(cursor, geometry)
        else:
            break
    check_geometry(geometry)
    return geometry


# Một dãy bản ghi gán xương liền nhau cùng id, đọc một lần bằng numpy.
def read_weights(cursor: Cursor, chunk_id: int) -> np.ndarray:
    capacity = cursor.remaining() // BONE_RECORD.itemsize
    records = np.frombuffer(cursor.data, BONE_RECORD, capacity, cursor.position)
    foreign = np.flatnonzero(records["id"] != chunk_id)
    count = int(foreign[0]) if foreign.size else capacity
    cursor.position += count * BONE_RECORD.itemsize
    return records[:count]


def join_weights(current: np.ndarray | None, added: np.ndarray) -> np.ndarray:
    if current is None:
        return added
    return np.concatenate([current, added])


def read_submesh(cursor: Cursor) -> SubMesh:
    cursor.begin_chunk(SUBMESH)
    material = cursor.line()
    uses_shared = cursor.u8() != 0
    index_count = cursor.u32()
    is_wide = cursor.u8() != 0
    indices = cursor.take(index_count * (4 if is_wide else 2))
    submesh = SubMesh(material, uses_shared, index_count, is_wide, indices)
    while True:
        chunk_id = cursor.peek_id()
        if chunk_id == GEOMETRY:
            submesh.geometry = read_geometry(cursor)
        elif chunk_id == SUBMESH_OPERATION:
            cursor.begin_chunk(SUBMESH_OPERATION)
            submesh.operation = cursor.u16()
            submesh.has_operation = True
        elif chunk_id == SUBMESH_BONE:
            submesh.weights = join_weights(submesh.weights, read_weights(cursor, SUBMESH_BONE))
        elif chunk_id == SUBMESH_ALIAS:
            cursor.begin_chunk(SUBMESH_ALIAS)
            alias = cursor.line()
            texture = cursor.line()
            submesh.aliases.append((alias, texture))
        else:
            break
    return submesh


def read_lod_level(cursor: Cursor, mesh: Mesh) -> LodLevel:
    cursor.begin_chunk(LOD_USAGE)
    level = LodLevel(cursor.f32())
    if mesh.is_lod_manual:
        cursor.begin_chunk(LOD_MANUAL)
        level.manual_mesh = cursor.line()
        return level
    while cursor.peek_id() == LOD_GENERATED:
        cursor.begin_chunk(LOD_GENERATED)
        index_count = cursor.u32()
        is_wide = cursor.u8() != 0
        indices = cursor.take(index_count * (4 if is_wide else 2))
        level.generated.append((index_count, is_wide, indices))
    return level


def read_lod(cursor: Cursor, mesh: Mesh) -> None:
    cursor.begin_chunk(LOD)
    level_count = cursor.u16()
    mesh.is_lod_manual = cursor.u8() != 0
    # Mức 0 là chính mesh, không ghi trong chunk.
    for _ in range(max(level_count - 1, 0)):
        mesh.lod_levels.append(read_lod_level(cursor, mesh))


def read_names(cursor: Cursor, mesh: Mesh) -> None:
    cursor.begin_chunk(NAME_TABLE)
    while cursor.peek_id() == NAME_ELEMENT:
        cursor.begin_chunk(NAME_ELEMENT)
        index = cursor.u16()
        name = cursor.line()
        if index < len(mesh.submeshes):
            mesh.submeshes[index].name = name


# Trả về False khi chunk không thuộc cấp mesh hoặc không nhảy qua được.
def read_mesh_chunk(cursor: Cursor, chunk_id: int, mesh: Mesh) -> bool:
    if chunk_id == GEOMETRY:
        mesh.shared = read_geometry(cursor)
    elif chunk_id == SUBMESH:
        mesh.submeshes.append(read_submesh(cursor))
    elif chunk_id == SKELETON_LINK:
        cursor.begin_chunk(SKELETON_LINK)
        mesh.skeleton = cursor.line()
    elif chunk_id == MESH_BONE:
        mesh.shared_weights = join_weights(mesh.shared_weights, read_weights(cursor, MESH_BONE))
    elif chunk_id == BOUNDS:
        cursor.begin_chunk(BOUNDS)
        mesh.bounds = cursor.unpack("<7f")
    elif chunk_id == LOD:
        read_lod(cursor, mesh)
    elif chunk_id == NAME_TABLE:
        read_names(cursor, mesh)
    elif chunk_id in (EDGE_LISTS, POSES, ANIMATIONS, EXTREMES):
        if not cursor.skip_chunk():
            return False
        mesh.skipped.append(chunk_id)
    else:
        return False
    return True


def read_mesh(data: bytes) -> Mesh:
    cursor = Cursor(data)
    if cursor.remaining() < 2 or cursor.u16() != HEADER:
        raise MeshError("không phải tệp mesh OGRE")
    version = cursor.line()
    if version not in VERSIONS:
        raise MeshError(f"phiên bản lạ: {version!r}")
    cursor.begin_chunk(MESH)
    mesh = Mesh(version, cursor.u8() != 0)
    while True:
        chunk_id = cursor.peek_id()
        if chunk_id is None:
            break
        if not read_mesh_chunk(cursor, chunk_id, mesh):
            mesh.stopped_at = chunk_id
            break
    mesh.trailing_bytes = cursor.remaining()
    if mesh.shared is None and not mesh.submeshes:
        raise MeshError("mesh không có hình học")
    return mesh
