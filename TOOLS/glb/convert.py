# Đổi một .mesh hoặc một .skeleton của OGRE thành GLB, không đổi đơn vị, hướng hay giá trị.
# Quyết định:
# - Buffer đỉnh và buffer chỉ số được chép nguyên byte vào GLB; accessor trỏ thẳng vào buffer xen kẽ
#   bằng byteStride và byteOffset. Vị trí, pháp tuyến, UV, tangent trong GLB vì thế trùng từng bit
#   với tệp gốc.
# - Thành phần glTF chuẩn không có chỗ chứa được giữ ở thuộc tính riêng (tên mở đầu bằng gạch dưới):
#   thành phần w của vị trí 4 số (_POSITION_W), UV 3 số (_TEXCOORD_n), tangent 3 số (_TANGENT),
#   màu specular (_SPECULAR), trọng số và chỉ số trộn có sẵn trong buffer (_BLEND_WEIGHTS,
#   _BLEND_INDICES).
# - Màu đỉnh kiểu ARGB của Direct3D nằm trong bộ nhớ theo thứ tự B, G, R, A; glTF cần R, G, B, A nên
#   kênh được hoán vị vào một bufferView riêng (không đổi giá trị). Kiểu VET_COLOUR cũ được coi là
#   ARGB như OGRE làm.
# - JOINTS_n và WEIGHTS_n dựng từ chunk gán xương, theo thứ tự trong tệp, 4 mục một bộ, trọng số giữ
#   nguyên (không chuẩn hoá, không cắt bớt). Chỉ số joint là handle xương của OGRE.
# - Material: tên, texture nền, chế độ alpha và hai mặt suy từ pass có ghi màu đầu tiên; script gốc
#   của material nằm trọn trong extras.ogre để không mất thiết lập nào glTF không diễn tả được.
# - alpha_rejection greater N của Direct3D 9 so alpha đã làm tròn về 8 bit, nên ngưỡng glTF là
#   (N + 0,5) / 255.

import os
from urllib.parse import quote

import numpy as np

import glb_writer
import ogre_mesh
import rig
from glb_writer import ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER, FLOAT, UNSIGNED_BYTE, UNSIGNED_SHORT

GENERATOR = "THIENLONG xuat_glb 1"

POSITION = 1
BLEND_WEIGHTS = 2
BLEND_INDICES = 3
NORMAL = 4
DIFFUSE = 5
SPECULAR = 6
TEXCOORD = 7
BINORMAL = 8
TANGENT = 9

FLOAT_KINDS = {0: "SCALAR", 1: "VEC2", 2: "VEC3", 3: "VEC4"}
COLOUR = 4
UBYTE4 = 9
COLOUR_ARGB = 10
COLOUR_ABGR = 11

BASE_ALIASES = (b"<baseTexture>", b"<BaseTexture>", b"<albedoTexture>")
WRAP_MODES = {b"clamp": 33071, b"mirror": 33648}
PNG_SOURCES = (".dds", ".tga")


# Đường dẫn tương đối (trong cây xuất) của ảnh ứng với một texture trong Material của kho gốc.
def texture_output(relative: str) -> str:
    extension = os.path.splitext(relative)[1].lower()
    return relative + ".png" if extension in PNG_SOURCES else relative


class Context:
    # Thứ một lượt đổi cần biết về kho: gốc của Material, thư viện material, vị trí tệp GLB đang ghi.
    def __init__(self, material_root: str, library, output_folder: str, texture_folder: str):
        self.material_root = material_root
        self.library = library
        self.output_folder = output_folder
        self.texture_folder = texture_folder

    def has_texture(self, relative: str) -> bool:
        return os.path.isfile(os.path.join(self.material_root, relative))

    def texture_uri(self, relative: str) -> str:
        target = os.path.join(self.texture_folder, texture_output(relative))
        path = os.path.relpath(target, self.output_folder).replace(os.sep, "/")
        return quote(path, safe="/")


def element_bytes(geometry, element) -> np.ndarray:
    buffer = next(b for b in geometry.buffers if b.bind_index == element.source)
    raw = np.frombuffer(buffer.data, np.uint8).reshape(geometry.vertex_count, buffer.vertex_size)
    size = ogre_mesh.ELEMENT_BYTES[element.type]
    return raw[:, element.offset : element.offset + size]


def suffixed(name: str, index: int) -> str:
    return name if index == 0 else f"{name}_{index}"


# Tên thuộc tính glTF của một thành phần số thực, kèm kiểu và độ lệch thêm trong thành phần.
def float_targets(element) -> list:
    # Kiểu không phải số thực (UBYTE4 của chỉ số trộn) luôn có 4 thành phần.
    kind = FLOAT_KINDS.get(element.type, "VEC4")
    semantic, index = element.semantic, element.index
    if semantic == POSITION and element.type == 3:
        return [("POSITION", "VEC3", 0), ("_POSITION_W", "SCALAR", 12)]
    if semantic == POSITION:
        return [("POSITION" if element.type == 2 else "_POSITION", kind, 0)]
    if semantic == NORMAL:
        return [("NORMAL" if element.type == 2 else "_NORMAL", kind, 0)]
    if semantic == TEXCOORD:
        return [(f"TEXCOORD_{index}" if element.type == 1 else f"_TEXCOORD_{index}", kind, 0)]
    if semantic == TANGENT:
        return [("TANGENT" if element.type == 3 else suffixed("_TANGENT", index), kind, 0)]
    names = {BINORMAL: "_BINORMAL", BLEND_WEIGHTS: "_BLEND_WEIGHTS", BLEND_INDICES: "_BLEND_INDICES"}
    return [(suffixed(names.get(semantic, f"_SEMANTIC_{semantic}"), index), kind, 0)]


def position_bounds(geometry, element) -> tuple:
    values = element_bytes(geometry, element)[:, :12].copy().view("<f4")
    return values.min(axis=0), values.max(axis=0)


def colour_name(element) -> str:
    if element.semantic == DIFFUSE:
        return f"COLOR_{element.index}"
    return suffixed("_SPECULAR", element.index)


def add_colour(builder, geometry, element, view: int) -> int:
    count = geometry.vertex_count
    if element.type == COLOUR_ABGR:
        options = {"offset": element.offset, "is_normalized": True}
        return builder.add_accessor(view, UNSIGNED_BYTE, "VEC4", count, **options)
    swapped = np.ascontiguousarray(element_bytes(geometry, element)[:, [2, 1, 0, 3]])
    own_view = builder.add_view(swapped.tobytes(), target=ARRAY_BUFFER)
    return builder.add_accessor(own_view, UNSIGNED_BYTE, "VEC4", count, is_normalized=True)


def add_element(builder, geometry, element, view: int, attributes: dict) -> None:
    count = geometry.vertex_count
    if element.type in (COLOUR, COLOUR_ARGB, COLOUR_ABGR):
        attributes[colour_name(element)] = add_colour(builder, geometry, element, view)
        return
    if element.type == UBYTE4:
        name = float_targets(element)[0][0]
        options = {"offset": element.offset}
        attributes[name] = builder.add_accessor(view, UNSIGNED_BYTE, "VEC4", count, **options)
        return
    if element.type not in FLOAT_KINDS:
        raise ogre_mesh.MeshError(f"kiểu thành phần chưa hỗ trợ: {element.type}")
    for name, kind, extra in float_targets(element):
        options = {"offset": element.offset + extra}
        if name == "POSITION":
            options["bounds"] = position_bounds(geometry, element)
        attributes[name] = builder.add_accessor(view, FLOAT, kind, count, **options)


# Mỗi buffer đỉnh của OGRE thành một bufferView xen kẽ, chép nguyên byte.
def add_geometry(builder, geometry) -> dict:
    views = {}
    for buffer in geometry.buffers:
        size = buffer.vertex_size
        if size % 4 or size > 252:
            raise ogre_mesh.MeshError(f"cỡ đỉnh {size} không làm byteStride được")
        views[buffer.bind_index] = builder.add_view(buffer.data, size, ARRAY_BUFFER)
    attributes = {}
    seen = 0
    for element in geometry.elements:
        add_element(builder, geometry, element, views[element.source], attributes)
        seen += 2 if (element.semantic == POSITION and element.type == 3) else 1
    if len(attributes) != seen:
        raise ogre_mesh.MeshError("hai thành phần đỉnh trùng tên thuộc tính")
    if "POSITION" not in attributes:
        raise ogre_mesh.MeshError("hình học không có vị trí kiểu 3 hay 4 số thực")
    return attributes


# Xếp các gán xương của từng đỉnh vào các bộ 4 mục theo thứ tự trong tệp.
def add_skin_attributes(builder, weights: np.ndarray, vertex_count: int, attributes: dict) -> int:
    vertices = weights["vertex"].astype(np.int64)
    if vertices.max() >= vertex_count:
        raise ogre_mesh.MeshError("gán xương trỏ đỉnh ngoài hình học")
    order = np.argsort(vertices, kind="stable")
    vertices = vertices[order]
    starts = np.searchsorted(vertices, vertices, side="left")
    ranks = np.arange(len(vertices)) - starts
    set_count = int(ranks.max()) // 4 + 1
    joints = np.zeros((set_count, vertex_count, 4), "<u2")
    values = np.zeros((set_count, vertex_count, 4), "<f4")
    joints[ranks // 4, vertices, ranks % 4] = weights["bone"][order]
    values[ranks // 4, vertices, ranks % 4] = weights["weight"][order]
    for index in range(set_count):
        joint_view = builder.add_view(joints[index].tobytes(), target=ARRAY_BUFFER)
        weight_view = builder.add_view(values[index].tobytes(), target=ARRAY_BUFFER)
        joint_accessor = builder.add_accessor(joint_view, UNSIGNED_SHORT, "VEC4", vertex_count)
        attributes[f"JOINTS_{index}"] = joint_accessor
        attributes[f"WEIGHTS_{index}"] = builder.add_accessor(weight_view, FLOAT, "VEC4", vertex_count)
    return int(weights["bone"].max())


def alpha_mode(settings: dict) -> tuple:
    blend = settings.get(b"scene_blend", b"").split()
    is_blended = blend not in ([], [b"replace"], [b"one", b"zero"])
    if is_blended:
        return "BLEND", None
    rejection = settings.get(b"alpha_rejection", b"").split()
    is_tested = len(rejection) == 2 and rejection[1].isdigit()
    if is_tested and rejection[0] == b"greater":
        return "MASK", (int(rejection[1]) + 0.5) / 255
    if is_tested and rejection[0] == b"greater_equal":
        return "MASK", (int(rejection[1]) - 0.5) / 255
    return "OPAQUE", None


def texture_path(use) -> str:
    path = rig.decode_name(use.texture).replace("\\", "/")
    if use.frame_count <= 1:
        return path
    stem, extension = os.path.splitext(path)
    return f"{stem}_0{extension}"


# Texture nền của pass: unit mang alias nền của các mẫu, không thì unit đầu tiên có tệp thật.
def base_texture(info, context: Context):
    candidates = [use for use in info.textures if use.texture]
    preferred = [use for use in candidates if use.alias in BASE_ALIASES]
    for use in preferred + candidates:
        if context.has_texture(texture_path(use)):
            return use
    return None


class MaterialWriter:
    # Gom material, texture, image, sampler của một GLB; mỗi tên chỉ ghi một lần.
    def __init__(self, builder, context: Context):
        self.builder = builder
        self.context = context
        self.materials = {}
        self.images = {}
        self.samplers = {}
        self.textures = {}
        self.missing = []

    def sampler(self, use) -> int | None:
        mode = use.settings.get(b"tex_address_mode", b"").split()
        wrap = WRAP_MODES.get(mode[0]) if mode else None
        if wrap is None:
            return None
        if wrap not in self.samplers:
            self.samplers[wrap] = self.builder.add("samplers", {"wrapS": wrap, "wrapT": wrap})
        return self.samplers[wrap]

    def texture(self, use) -> int:
        relative = texture_path(use)
        if relative not in self.images:
            image = {"uri": self.context.texture_uri(relative), "name": relative}
            self.images[relative] = self.builder.add("images", image)
        key = (self.images[relative], self.sampler(use))
        if key not in self.textures:
            entry = {"source": key[0]}
            if key[1] is not None:
                entry["sampler"] = key[1]
            self.textures[key] = self.builder.add("textures", entry)
        return self.textures[key]

    def describe_pass(self, material: dict, details: dict, info) -> None:
        settings = info.settings
        details["settings"] = {k.decode("latin-1"): rig.decode_name(v) for k, v in settings.items()}
        details["has_program"] = info.has_program
        uses = []
        for use in info.textures:
            path = texture_path(use) if use.texture else ""
            entry = {"alias": rig.decode_name(use.alias), "texture": path}
            entry["exists"] = bool(path) and self.context.has_texture(path)
            if use.frame_count > 1:
                entry["frames"] = use.frame_count
            uses.append(entry)
        details["textures"] = uses
        base = base_texture(info, self.context)
        if base is not None:
            reference = {"index": self.texture(base)}
            material["pbrMetallicRoughness"]["baseColorTexture"] = reference
        mode, cutoff = alpha_mode(settings)
        if mode != "OPAQUE":
            material["alphaMode"] = mode
        if cutoff is not None:
            material["alphaCutoff"] = cutoff
        if settings.get(b"cull_hardware", b"").strip() == b"none":
            material["doubleSided"] = True
        if settings.get(b"lighting", b"").split()[:1] == [b"off"]:
            material["extensions"] = {"KHR_materials_unlit": {}}
            used = self.builder.document.setdefault("extensionsUsed", [])
            if "KHR_materials_unlit" not in used:
                used.append("KHR_materials_unlit")

    def material(self, name: bytes) -> int:
        if name in self.materials:
            return self.materials[name]
        material = {"name": rig.decode_name(name)}
        material["pbrMetallicRoughness"] = {"metallicFactor": 0.0, "roughnessFactor": 1.0}
        effective = self.context.library.effective(name)
        details = {"defined": effective is not None}
        if effective is None:
            self.missing.append(material["name"])
        else:
            details["script"] = rig.decode_name(effective.script)
            details["parents"] = [rig.decode_name(parent) for parent in effective.parents]
            details["pass_count"] = len(effective.passes)
            primary = effective.primary()
            if primary is not None:
                details["primary_pass"] = effective.passes.index(primary)
                self.describe_pass(material, details, primary)
        material["extras"] = {"ogre": details}
        self.materials[name] = self.builder.add("materials", material)
        return self.materials[name]


def add_indices(builder, submesh) -> int:
    view = builder.add_view(submesh.indices, target=ELEMENT_ARRAY_BUFFER)
    component = glb_writer.UNSIGNED_INT if submesh.is_wide else UNSIGNED_SHORT
    return builder.add_accessor(view, component, "SCALAR", submesh.index_count)


def declaration_of(geometry) -> dict:
    elements = [[e.source, e.type, e.semantic, e.offset, e.index] for e in geometry.elements]
    sizes = {str(buffer.bind_index): buffer.vertex_size for buffer in geometry.buffers}
    return {"elements": elements, "vertex_sizes": sizes}


def add_primitive(builder, submesh, materials: MaterialWriter, report: dict) -> dict | None:
    geometry = submesh.geometry
    if geometry is None or submesh.index_count == 0:
        report["skipped_submeshes"] = report.get("skipped_submeshes", 0) + 1
        return None
    if submesh.operation != ogre_mesh.TRIANGLE_LIST:
        raise ogre_mesh.MeshError(f"kiểu dựng hình chưa hỗ trợ: {submesh.operation}")
    attributes = add_geometry(builder, geometry)
    has_weights = submesh.weights is not None and len(submesh.weights) > 0
    if has_weights:
        highest = add_skin_attributes(builder, submesh.weights, geometry.vertex_count, attributes)
        report["highest_bone"] = max(report.get("highest_bone", -1), highest)
    primitive = {"attributes": attributes, "indices": add_indices(builder, submesh)}
    primitive["mode"] = glb_writer.TRIANGLES
    primitive["material"] = materials.material(submesh.material)
    details = declaration_of(geometry)
    details["material"] = rig.decode_name(submesh.material)
    if submesh.name is not None:
        details["name"] = rig.decode_name(submesh.name)
    primitive["extras"] = {"ogre": details}
    report["vertices"] = report.get("vertices", 0) + geometry.vertex_count
    report["indices"] = report.get("indices", 0) + submesh.index_count
    report["weighted"] = report.get("weighted", 0) + (1 if has_weights else 0)
    return primitive


# Xương mà mesh trỏ tới nhưng skeleton không có: thêm node giữ chỗ để chỉ số joint vẫn hợp lệ.
def add_skin(builder, bones: rig.BoneNodes | None, highest_bone: int, report: dict) -> int | None:
    if bones is None or highest_bone < 0:
        return None
    joints = list(range(bones.first_node, bones.first_node + bones.count))
    matrices = bones.inverse_binds
    missing = highest_bone + 1 - bones.count
    if missing > 0:
        report["placeholder_bones"] = missing
        for handle in range(bones.count, highest_bone + 1):
            joints.append(builder.add("nodes", {"name": f"__missing_bone_{handle}"}))
        identity = np.tile(np.identity(4, np.float32), (missing, 1, 1))
        matrices = np.concatenate([matrices, identity])
    view = builder.add_view(np.ascontiguousarray(matrices, "<f4").tobytes())
    accessor = builder.add_accessor(view, FLOAT, "MAT4", len(joints))
    return builder.add("skins", {"joints": joints, "inverseBindMatrices": accessor})


# mesh: kết quả của ogre_mesh.read_mesh; skeleton: skeleton mà mesh liên kết, None khi không có.
def mesh_to_glb(mesh, name: str, skeleton, context: Context) -> tuple[bytes, dict]:
    builder = glb_writer.GlbBuilder(GENERATOR)
    report = {}
    bones = rig.add_bones(builder, skeleton) if skeleton is not None else None
    materials = MaterialWriter(builder, context)
    primitives = []
    for submesh in mesh.submeshes:
        primitive = add_primitive(builder, submesh, materials, report)
        if primitive is not None:
            primitives.append(primitive)
    if not primitives:
        raise ogre_mesh.MeshError("mesh không có submesh nào ghi được")
    details = {"version": mesh.version.decode("latin-1"), "is_animated": mesh.is_animated}
    if mesh.bounds is not None:
        details["bounds"] = list(mesh.bounds)
    if mesh.skeleton is not None:
        details["skeleton"] = rig.decode_name(mesh.skeleton)
    if mesh.skipped:
        details["skipped_chunks"] = [f"{chunk_id:#06x}" for chunk_id in mesh.skipped]
    mesh_index = builder.add("meshes", {"name": name, "primitives": primitives})
    builder.document["meshes"][mesh_index]["extras"] = {"ogre": details}
    node = {"name": name, "mesh": mesh_index}
    skin = add_skin(builder, bones, report.get("highest_bone", -1), report)
    if skin is not None:
        node["skin"] = skin
    mesh_node = builder.add("nodes", node)
    roots = (bones.roots if bones is not None else []) + [mesh_node]
    placeholders = report.get("placeholder_bones", 0)
    roots += list(range(mesh_node - placeholders, mesh_node)) if placeholders else []
    builder.add("scenes", {"nodes": roots})
    builder.document["scene"] = 0
    report["missing_materials"] = materials.missing
    report["materials"] = len(materials.materials)
    report["images"] = sorted(materials.images)
    return builder.to_bytes(), report


def skeleton_to_glb(skeleton, name: str) -> tuple[bytes, dict]:
    builder = glb_writer.GlbBuilder(GENERATOR)
    bones = rig.add_bones(builder, skeleton)
    moved, empty = rig.add_animations(builder, skeleton, bones)
    # Skeleton không có xương nào (có thật trong kho): glTF cấm danh sách node rỗng nên bỏ hẳn khoá.
    scene = {"name": name}
    if bones.roots:
        scene["nodes"] = bones.roots
    if empty:
        scene["extras"] = {"ogre": {"animations_without_channels": empty}}
    builder.add("scenes", scene)
    builder.document["scene"] = 0
    report = {"bones": bones.count, "animations": len(skeleton.animations)}
    report["moved_keys"] = moved
    report["empty_animations"] = len(empty)
    return builder.to_bytes(), report
