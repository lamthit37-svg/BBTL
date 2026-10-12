# Gom hiệu ứng của client 2026 vào thư mục dữ liệu client: phần của Effect/all.effect và
# Effect/all.particle mà các cảnh đã gom gọi tới (đổi GBK sang UTF-8, giữ nguyên cú pháp), bảng
# material của các hệ hạt ấy sau kế thừa, ảnh PNG và mesh hạt. Thay cook_fx.py, bộ chép thư viện
# nấu của client cũ.
# Quyết định:
# - Chỉ mục khối theo đúng luật của client (SRC/fx/script.cpp): khối cấp cao là từ dòng mang tên tới
#   dấu } khép; tên trùng giữ khối đầu. Nhờ vậy tên client tra được cũng là tên bộ gom chép.
# - Chỉ gom tên cảnh gọi: cả thư viện là 73 MB, client nạp trọn tệp lúc mở.
# - Material giải kế thừa bằng TOOLS/glb/ogre_material.py; bảng ghi thứ client cần để quyết có vẽ
#   được không (ảnh, chế độ trộn, hệ số màu, ảnh thứ hai, cuộn, shader, thiết lập khác). Cột
#   shader là "fixed" (không shader, lighting off), "particle" (Particle_ps.hlsl thường) hoặc tên
#   chương trình; cột extra liệt kê thiết lập của pass và texture unit mà ba cột trước không tả.
# - Thứ kho gốc không có (tên không định nghĩa, ảnh không có tệp) là ghi chú; thứ kho gốc có mà cây
#   GLB thiếu là lỗi gom. Hiệu ứng con (ParEffectName, ColEffectName) chưa gom: client chưa phát.
# Cách dùng: python collect_fx.py <kho gốc _raw> <cây GLB _glb> <thư mục dữ liệu client> [cảnh ...]
# Không nêu cảnh thì lấy mọi Scene/*.Scene của thư mục dữ liệu. Ghi effect/all.effect,
# effect/all.particle, effect/materials.tsv, effect/fx.files.tsv; mã thoát 1 khi có lỗi gom.

from __future__ import annotations

import glob
import os
import re
import sys
import xml.etree.ElementTree as ElementTree
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

GLB_TOOLS = Path(__file__).resolve().parents[1] / "glb"
if str(GLB_TOOLS) not in sys.path:
    sys.path.insert(0, str(GLB_TOOLS))

import ogre_material  # noqa: E402
from collect_map import Collector, copy_files  # noqa: E402

SOURCE_ENCODING = "gb18030"
EFFECT_FOLDER = "Effect"
OUTPUT_FOLDER = "effect"
MATERIAL_FOLDER = "Material"
MODEL_FOLDER = "Model"
SCENE_FOLDER = "Scene"
# Thứ tự nạp script material và chương trình shader, như TOOLS/glb/export_glb.py.
SCRIPT_FOLDERS = ("MaterialTemplates", "Material", "Scene", "OgreCore")
PNG_SOURCES = (".dds", ".tga")
SCENE_NAMES = {"Effect": "effect name", "ParticleSystem": "particle system name"}
TABLE_COLUMNS = ("name", "image", "blend", "gain", "second", "scroll_u", "scroll_v", "shader", "extra")
BLEND_NAMES = {
    b"add": "one one",
    b"modulate": "dest_colour zero",
    b"colour_blend": "src_colour one_minus_src_colour",
    b"alpha_blend": "src_alpha one_minus_src_alpha",
    b"replace": "one zero",
}
# Shader hạt một ảnh: màu = ảnh nhân hệ số của BLEND_OP_0 nhân màu đỉnh (ShaderLib/Diffuse.inc).
PLAIN_SOURCE = b"Particle_ps.hlsl"
PLAIN_DEFINES = {b"BLEND_OP_0", b"ENABLE_CLAMP"}
GAINS = {b"1": 2, b"2": 4}
# Hai giá trị của cột shader mà màu ra chỉ là ảnh nhân hệ số nhân màu đỉnh.
PLAIN_SHADERS = ("fixed", "particle")
# Thiết lập không đổi hình vẽ của một quad hạt một ảnh, UV trong 0..1, trộn theo cột blend. Màu vật
# liệu chỉ vào ánh sáng (hạt không tính ánh sáng), trừ emissive (shader cộng vào màu đỉnh) và alpha
# của diffuse (shader nhân vào alpha): hai thứ đó chỉ trung tính khi bằng 0 và bằng 1.
PASS_NEUTRAL = {
    b"scene_blend", b"separate_scene_blend", b"depth_write", b"lighting", b"ambient", b"specular", b"fog_override",
    b"cull_hardware", b"cull_software", b"shading",
}
UNIT_NEUTRAL = {
    b"texture", b"texture_alias", b"tex_address_mode", b"filtering", b"max_anisotropy", b"mipmap_bias",
    b"tex_border_colour",
}


@dataclass
class Script:
    # Một tệp script khối ngoặc đã giải mã: tên khối cấp cao -> (đầu dòng tên, sau dấu } khép).
    text: str
    spans: dict[str, tuple[int, int]] = field(default_factory=dict)

    def block(self, name: str) -> str:
        begin, end = self.spans[name]
        return self.text[begin:end]


@dataclass
class Program:
    source: bytes
    defines: dict[bytes, bytes]


@dataclass
class Wanted:
    # Tên effect và hệ hạt các cảnh gọi kèm số lần đặt (hệ hạt chỉ do effect kéo theo thì 0), cùng
    # material và mesh chúng dùng; notes là thứ kho gốc không có.
    effects: Counter = field(default_factory=Counter)
    systems: Counter = field(default_factory=Counter)
    materials: set[str] = field(default_factory=set)
    meshes: set[str] = field(default_factory=set)
    notes: list[str] = field(default_factory=list)


def name_of(line: str, name_word: int) -> str:
    words = line.split("//", 1)[0].split()
    return words[name_word] if name_word < len(words) else ""


# Đầu dòng mang tên của khối mở ở vị trí brace: dòng chứa ký tự không trắng cuối cùng trước brace.
def name_line_at(text: str, brace: int) -> int:
    at = brace
    while at > 0 and text[at - 1] in " \t\r\n":
        at -= 1
    return text.rfind("\n", 0, at) + 1 if at > 0 else 0


def index_script(text: str, name_word: int) -> Script:
    script = Script(text)
    depth = 0
    opened = 0
    for match in re.finditer(r"[{}]", text):
        if match.group() == "{":
            opened = match.start() if depth == 0 else opened
            depth += 1
            continue
        if depth == 0:
            continue
        depth -= 1
        if depth != 0:
            continue
        begin = name_line_at(text, opened)
        stop = text.find("\n", begin)
        name = name_of(text[begin:stop if stop >= 0 else len(text)], name_word)
        if name and name not in script.spans:
            script.spans[name] = (begin, match.end())
    return script


def read_script(raw_root: str, file_name: str, name_word: int) -> Script:
    path = os.path.join(raw_root, EFFECT_FOLDER, file_name)
    with open(path, "rb") as stream:
        return index_script(stream.read().decode(SOURCE_ENCODING), name_word)


def scene_paths(target: str, scenes: list[str]) -> list[str]:
    folder = os.path.join(target, SCENE_FOLDER)
    if scenes:
        return [os.path.join(folder, scene + ".Scene") for scene in scenes]
    return sorted(glob.glob(os.path.join(glob.escape(folder), "*.Scene")))


# Tên effect và tên hệ hạt mà một tệp cảnh đặt, kèm số lần đặt.
def add_scene(wanted: Wanted, path: str) -> None:
    root = ElementTree.parse(path).getroot()
    for node in root.iter("Object"):
        key = SCENE_NAMES.get(node.get("type", ""))
        if key is None:
            continue
        names = [item.get("value", "") for item in node.findall("Property") if item.get("name") == key]
        tally = wanted.effects if node.get("type") == "Effect" else wanted.systems
        tally.update(name for name in names if name)


def values_of(block: str, keyword: str) -> list[str]:
    return re.findall(rf"(?m)^[ \t]*{keyword}[ \t]+(\S+)", block)


# Hệ hạt, material và mesh mà các effect và hệ hạt được gọi kéo theo.
def follow(wanted: Wanted, effects: Script, particles: Script) -> None:
    for name in sorted(wanted.effects):
        if name not in effects.spans:
            wanted.notes.append(f"kho gốc không định nghĩa effect {name}")
            continue
        block = effects.block(name)
        for system in values_of(block, "ParticleSystem"):
            wanted.systems.setdefault(system, 0)
        wanted.materials.update(values_of(block, "Material"))
    for name in sorted(wanted.systems):
        if name not in particles.spans:
            wanted.notes.append(f"kho gốc không định nghĩa hệ hạt {name}")
            continue
        block = particles.block(name)
        wanted.materials.update(values_of(block, "material"))
        wanted.meshes.update(values_of(block, "mesh_name"))


# Các khối được gọi, theo thứ tự trong tệp nguồn, thành một tệp UTF-8 xuống dòng bằng LF.
def subset(script: Script, names: set[str]) -> str:
    kept = sorted((script.spans[name] for name in names if name in script.spans))
    blocks = [script.text[begin:end].replace("\r\n", "\n") for begin, end in kept]
    return "\n\n".join(blocks) + "\n" if blocks else ""


def script_files(raw_root: str, extension: str) -> list[str]:
    found = []
    for position, top in enumerate(SCRIPT_FOLDERS):
        for folder, _, names in os.walk(os.path.join(raw_root, top)):
            paths = [os.path.join(folder, name) for name in names if name.lower().endswith(extension)]
            found.extend((position, path) for path in paths)
    return [path for _, path in sorted(found)]


def load_materials(raw_root: str) -> ogre_material.MaterialLibrary:
    library = ogre_material.MaterialLibrary()
    for path in script_files(raw_root, ".material"):
        with open(path, "rb") as stream:
            library.load(stream.read())
    return library


def defines_of(text: bytes | None) -> dict[bytes, bytes]:
    pairs = [item.partition(b"=") for item in (text or b"").replace(b",", b";").split(b";") if item.strip()]
    return {key.strip(): value.strip() for key, _, value in pairs}


# Chương trình fragment của kho gốc: tên -> tệp nguồn và các define tiền xử lý.
def load_programs(raw_root: str) -> dict[bytes, Program]:
    programs: dict[bytes, Program] = {}
    for path in script_files(raw_root, ".program"):
        with open(path, "rb") as stream:
            root = ogre_material.parse_blocks(ogre_material.clean_lines(stream.read()))
        for node in root.blocks(b"fragment_program"):
            name = node.argument.split()[0] if node.argument else b""
            source = node.value(b"source") or b""
            programs.setdefault(name, Program(source, defines_of(node.value(b"preprocessor_defines"))))
    return programs


# Pass có ghi màu đầu tiên của material sau kế thừa, kèm bảng alias ảnh; None khi không định nghĩa.
def primary_pass(library: ogre_material.MaterialLibrary, name: bytes) -> tuple | None:
    chain = library.chain(name)
    if not chain:
        return None
    merged = ogre_material.Node(b"material")
    for definition in reversed(chain):
        ogre_material.merge_node(merged, definition.node)
    pairs = [argument.split() for keyword, argument in merged.lines if keyword == b"set_texture_alias"]
    aliases = {parts[0]: parts[1] for parts in pairs if len(parts) >= 2}
    passes = ogre_material.near_passes(merged)
    visible = [node for node in passes if ogre_material.pass_info(node, aliases).is_visible()]
    chosen = visible or passes
    return (chosen[0], aliases) if chosen else None


def blend_of(node: ogre_material.Node) -> str:
    whole = node.value(b"scene_blend")
    parts = (whole or node.value(b"separate_scene_blend") or b"one zero").split()
    if len(parts) == 1:
        return BLEND_NAMES.get(parts[0], parts[0].decode("ascii", "replace"))
    return " ".join(part.decode("ascii", "replace") for part in parts[:2])


# Cột shader và hệ số màu của ảnh thứ nhất.
def shading_of(node: ogre_material.Node, programs: dict[bytes, Program]) -> tuple[str, int]:
    references = node.blocks(b"fragment_program_ref")
    if not references:
        return ("fixed" if node.value(b"lighting") == b"off" else "fixed_lit"), 1
    name = references[0].argument.split()[0] if references[0].argument else b""
    program = programs.get(name)
    if program is None:
        return name.decode(SOURCE_ENCODING, "replace"), 1
    gain = GAINS.get(program.defines.get(b"BLEND_OP_0", b""), 1)
    is_plain = program.source == PLAIN_SOURCE and set(program.defines) <= PLAIN_DEFINES
    return ("particle" if is_plain else name.decode(SOURCE_ENCODING, "replace")), gain


def spoken(keyword: bytes, argument: bytes) -> str:
    return (keyword + b" " + argument).decode(SOURCE_ENCODING, "replace").strip()


def numbers_of(argument: bytes) -> list[float] | None:
    try:
        return [float(part) for part in argument.split()]
    except ValueError:
        return None


def is_neutral_pass_line(keyword: bytes, argument: bytes) -> bool:
    if keyword in PASS_NEUTRAL or (keyword, argument) == (b"depth_check", b"on"):
        return True
    numbers = numbers_of(argument)
    if keyword == b"emissive":
        return numbers is not None and not any(numbers[:3])
    if keyword == b"diffuse":
        return argument == b"vertexcolour" or (numbers is not None and (len(numbers) < 4 or numbers[3] == 1.0))
    return False


# Thiết lập của pass và texture unit mà các cột khác của bảng không tả. scroll_anim của unit đầu đã
# có cột riêng; của unit sau thì nằm ở đây.
def extra_of(node: ogre_material.Node) -> str:
    found = [spoken(*line) for line in node.lines if not is_neutral_pass_line(*line)]
    for position, unit in enumerate(node.blocks(b"texture_unit")):
        skipped = UNIT_NEUTRAL | {b"scroll_anim"} if position == 0 else UNIT_NEUTRAL
        found.extend(spoken(*line) for line in unit.lines if line[0] not in skipped)
    return "; ".join(found)


def scroll_of(unit: ogre_material.Node | None) -> tuple[str, str]:
    parts = (unit.value(b"scroll_anim") or b"").split() if unit is not None else []
    if len(parts) != 2:
        return "0", "0"
    return parts[0].decode("ascii", "replace"), parts[1].decode("ascii", "replace")


# Đường dẫn (trong cây GLB lẫn cây đích) của ảnh ứng với một texture của unit; rỗng khi unit không
# nêu ảnh. Ảnh nhiều khung (anim_texture) lấy khung đầu, như TOOLS/glb/convert.py.
def image_path(use: ogre_material.TextureUse) -> str:
    if not use.texture:
        return ""
    relative = use.texture.decode(SOURCE_ENCODING, "replace").replace("\\", "/")
    stem, extension = os.path.splitext(relative)
    if use.frame_count > 1:
        relative = f"{stem}_0{extension}"
    twin = relative + ".png" if extension.lower() in PNG_SOURCES else relative
    return f"{MATERIAL_FOLDER}/{twin}"


@dataclass
class Row:
    name: str
    image: str
    blend: str
    gain: int
    second: str
    scroll: tuple[str, str]
    shader: str
    extra: str

    def cells(self) -> list[str]:
        return [self.name, self.image, self.blend, str(self.gain), self.second, *self.scroll, self.shader, self.extra]

    # Một ảnh đứng yên qua shader thường: thứ client vẽ được khi chế độ trộn của nó cũng vẽ được.
    def is_plain(self) -> bool:
        is_still = self.scroll == ("0", "0") and not self.extra
        return bool(self.image) and not self.second and is_still and self.shader in PLAIN_SHADERS


# Một dòng của bảng cho material name; None khi kho gốc không định nghĩa nó.
def row_of(name: str, library: ogre_material.MaterialLibrary, programs: dict[bytes, Program]) -> Row | None:
    found = primary_pass(library, name.encode(SOURCE_ENCODING))
    if found is None:
        return None
    node, aliases = found
    units = node.blocks(b"texture_unit")
    images = [image_path(ogre_material.texture_use(unit, aliases)) for unit in units]
    shader, gain = shading_of(node, programs)
    second = next((image for image in images[1:] if image), "")
    scroll = scroll_of(units[0] if units else None)
    return Row(name, images[0] if images else "", blend_of(node), gain, second, scroll, shader, extra_of(node))


# Ảnh của một dòng. Cây GLB có sẵn PNG thì chép. Không có thì giải DDS hoặc TGA gốc
# thành PNG đúng đường materials.tsv, vì bộ vẽ hạt đọc PNG. Kho gốc cũng không có thì ghi chú
# và xoá ô ảnh (client coi material ấy là không có ảnh).
def bake_image(collector: Collector, image: str) -> bool:
    target = os.path.join(collector.target, image)
    if os.path.isfile(target) and os.path.getsize(target) > 32:
        return True
    stem = image[: -len(".png")] if image.lower().endswith(".png") else image
    source = ""
    for root in (collector.glb_root, collector.raw_root):
        for candidate in (os.path.join(root, image), os.path.join(root, stem)):
            if os.path.isfile(candidate):
                source = candidate
                break
        if source:
            break
    if not source:
        return False
    os.makedirs(os.path.dirname(target), exist_ok=True)
    from PIL import Image

    pending = target + ".part"
    with Image.open(source) as picture:
        picture.convert("RGBA").save(pending, "PNG")
    os.replace(pending, target)
    return True


def image_ready(collector: Collector, image: str) -> bool:
    if os.path.normpath(image) in collector.files:
        return True
    target = os.path.join(collector.target, image)
    return os.path.isfile(target) and os.path.getsize(target) > 32


def claim_images(row: Row, collector: Collector, notes: list[str]) -> None:
    for image in (row.image, row.second):
        if not image or image_ready(collector, image):
            continue
        twin = os.path.normpath(image)
        source = twin[: -len(".png")] if twin.lower().endswith((".dds.png", ".tga.png")) else twin
        if os.path.isfile(os.path.join(collector.glb_root, twin)):
            collector.files[twin] = ("fx_texture", collector.glb_root)
        elif bake_image(collector, image.replace("\\", "/")):
            continue
        elif os.path.isfile(os.path.join(collector.raw_root, source)):
            collector.missing.append(("fx_texture", image))
        else:
            notes.append(f"kho gốc không có ảnh {image} của material {row.name}")
    if row.image and not image_ready(collector, row.image):
        row.image = ""


def material_rows(wanted: Wanted, collector: Collector) -> list[Row]:
    library = load_materials(collector.raw_root)
    programs = load_programs(collector.raw_root)
    rows = []
    for name in sorted(wanted.materials):
        row = row_of(name, library, programs)
        if row is None:
            wanted.notes.append(f"kho gốc không định nghĩa material {name}")
            continue
        claim_images(row, collector, wanted.notes)
        rows.append(row)
    return rows


# Mesh của hạt renderer mesh nằm ở gốc Model/ của cây GLB; tên trong script đã có đuôi .mesh.
def claim_meshes(wanted: Wanted, collector: Collector) -> None:
    for name in sorted(wanted.meshes):
        relative = collector.find_mesh(name)
        if relative is not None:
            collector.add_mesh(name)
        elif os.path.isfile(os.path.join(collector.raw_root, MODEL_FOLDER, name)):
            collector.missing.append(("fx_mesh", name))
        else:
            wanted.notes.append(f"kho gốc không có mesh hạt {name}")


def write_text(path: str, text: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pending = path + ".part"
    with open(pending, "w", encoding="utf-8", newline="\n") as stream:
        stream.write(text)
    os.replace(pending, path)


def table_text(rows: list[Row]) -> str:
    lines = ["\t".join(TABLE_COLUMNS)]
    lines.extend("\t".join(row.cells()) for row in rows)
    return "\n".join(lines) + "\n"


def list_text(collector: Collector, made: list[str]) -> str:
    rows = {relative.replace(os.sep, "/"): kind for relative, (kind, _) in collector.files.items()}
    rows.update(dict.fromkeys(made, "fx_script"))
    lines = ["kind\tpath"]
    lines.extend(f"{kind}\t{relative}" for relative, kind in sorted(rows.items()))
    return "\n".join(lines) + "\n"


# Gom trọn một lượt: ghi ba tệp của effect/, chép ảnh và mesh, ghi danh sách tệp. Trả thứ đã gom,
# các dòng của bảng và cỡ đã chép theo loại; thứ thiếu nằm ở collector.missing.
def collect(collector: Collector, scenes: list[str]) -> tuple[Wanted, list[Row], Counter]:
    wanted = Wanted()
    for path in scene_paths(collector.target, scenes):
        if os.path.isfile(path):
            add_scene(wanted, path)
        else:
            collector.missing.append(("scene", path))
    effects = read_script(collector.raw_root, "all.effect", 1)
    particles = read_script(collector.raw_root, "all.particle", 0)
    follow(wanted, effects, particles)
    rows = material_rows(wanted, collector)
    claim_meshes(wanted, collector)
    folder = os.path.join(collector.target, OUTPUT_FOLDER)
    write_text(os.path.join(folder, "all.effect"), subset(effects, set(wanted.effects)))
    write_text(os.path.join(folder, "all.particle"), subset(particles, set(wanted.systems)))
    write_text(os.path.join(folder, "materials.tsv"), table_text(rows))
    sizes = copy_files(collector)
    made = [f"{OUTPUT_FOLDER}/{name}" for name in ("all.effect", "all.particle", "materials.tsv")]
    write_text(os.path.join(folder, "fx.files.tsv"), list_text(collector, made))
    return wanted, rows, sizes


def report(collector: Collector, wanted: Wanted, rows: list[Row], sizes: Counter) -> None:
    kinds = Counter(kind for kind, _ in collector.files.values())
    plain = sum(1 for row in rows if row.is_plain())
    print(f"Hiệu ứng: {len(wanted.effects)} effect ({sum(wanted.effects.values())} lần đặt), "
          f"{len(wanted.systems)} hệ hạt ({sum(wanted.systems.values())} lần đặt thẳng), "
          f"{len(rows)} material ({plain} một ảnh đứng yên qua shader thường), {len(wanted.meshes)} mesh hạt")
    for kind in sorted(kinds):
        print(f"  {kind}: {kinds[kind]} tệp, {sizes[kind]} byte")
    blends = Counter(row.blend for row in rows)
    print("  chế độ trộn: " + ", ".join(f"{blend} {count}" for blend, count in blends.most_common()))
    shaders = Counter(row.shader for row in rows)
    print("  shader: " + ", ".join(f"{shader} {count}" for shader, count in shaders.most_common()))
    for note in wanted.notes:
        print(f"  GHI CHÚ: {note}")
    for kind, name in collector.missing:
        print(f"  THIẾU {kind}: {name}")


def main() -> int:
    if len(sys.argv) < 4:
        print("Cách dùng: python collect_fx.py <_raw> <_glb> <dữ liệu client> [cảnh ...]", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    collector = Collector(raw_root, glb_root, target)
    wanted, rows, sizes = collect(collector, sys.argv[4:])
    report(collector, wanted, rows, sizes)
    return 1 if collector.missing else 0


if __name__ == "__main__":
    sys.exit(main())
