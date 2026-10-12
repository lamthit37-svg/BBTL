# Dựng một tệp GLB (glTF 2.0 nhị phân): gom bufferView vào một buffer duy nhất, khai accessor, rồi
# ghi header 12 byte, chunk JSON và chunk BIN. Quyết định:
# - Dữ liệu đưa vào được chép nguyên byte; lớp này không đổi giá trị nào.
# - Số thực trong JSON ghi bằng repr của double: float32 đổi sang double rồi đọc lại ra đúng float32.
# - NaN hay vô cực trong JSON là lỗi (allow_nan=False), không ghi tệp sai chuẩn.

import json
import struct

FLOAT = 5126
UNSIGNED_BYTE = 5121
UNSIGNED_SHORT = 5123
UNSIGNED_INT = 5125
ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963
TRIANGLES = 4

GLB_MAGIC = 0x46546C67
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


class GlbBuilder:
    def __init__(self, generator: str):
        self.document = {"asset": {"version": "2.0", "generator": generator}}
        self.parts = []
        self.byte_length = 0

    # Thêm một mục vào danh sách cấp cao nhất (nodes, meshes, accessors...) và trả về chỉ số của nó.
    def add(self, key: str, item: dict) -> int:
        items = self.document.setdefault(key, [])
        items.append(item)
        return len(items) - 1

    # bufferView bắt đầu ở bội của 4 để mọi accessor số thực và số nguyên đều thẳng hàng.
    def add_view(self, data: bytes, stride: int | None = None, target: int | None = None) -> int:
        padding = -self.byte_length % 4
        if padding:
            self.parts.append(b"\0" * padding)
            self.byte_length += padding
        view = {"buffer": 0, "byteOffset": self.byte_length, "byteLength": len(data)}
        if stride is not None:
            view["byteStride"] = stride
        if target is not None:
            view["target"] = target
        self.parts.append(bytes(data))
        self.byte_length += len(data)
        return self.add("bufferViews", view)

    def add_accessor(self, view: int, component: int, kind: str, count: int, **options) -> int:
        accessor = {"bufferView": view, "componentType": component, "type": kind, "count": count}
        if options.get("offset"):
            accessor["byteOffset"] = options["offset"]
        if options.get("is_normalized"):
            accessor["normalized"] = True
        bounds = options.get("bounds")
        if bounds is not None:
            accessor["min"] = [float(value) for value in bounds[0]]
            accessor["max"] = [float(value) for value in bounds[1]]
        return self.add("accessors", accessor)

    def to_bytes(self) -> bytes:
        document = dict(self.document)
        if self.byte_length:
            document["buffers"] = [{"byteLength": self.byte_length}]
        text = json.dumps(document, ensure_ascii=False, separators=(",", ":"), allow_nan=False)
        json_bytes = text.encode("utf-8")
        json_bytes += b" " * (-len(json_bytes) % 4)
        binary = b"".join(self.parts)
        binary += b"\0" * (-len(binary) % 4)
        chunks = struct.pack("<II", len(json_bytes), JSON_CHUNK) + json_bytes
        if binary:
            chunks += struct.pack("<II", len(binary), BIN_CHUNK) + binary
        return struct.pack("<III", GLB_MAGIC, 2, 12 + len(chunks)) + chunks


# Đọc lại một GLB thành (document, binary) để các phép kiểm so với nguồn.
def read_glb(data: bytes) -> tuple[dict, bytes]:
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC or version != 2 or length != len(data):
        raise ValueError("header GLB sai")
    json_length, json_kind = struct.unpack_from("<II", data, 12)
    if json_kind != JSON_CHUNK:
        raise ValueError("chunk đầu không phải JSON")
    document = json.loads(data[20 : 20 + json_length].decode("utf-8"))
    rest = 20 + json_length
    if rest == len(data):
        return document, b""
    bin_length, bin_kind = struct.unpack_from("<II", data, rest)
    if bin_kind != BIN_CHUNK:
        raise ValueError("chunk thứ hai không phải BIN")
    return document, data[rest + 8 : rest + 8 + bin_length]
