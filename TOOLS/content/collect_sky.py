# Gom bầu trời EnScene của client 2026 vào thư mục dữ liệu client: tệp Scene/<tên>.EnScene mà
# phần tử Object type="EnScene" của <map>.Scene nêu (thuộc tính config_file), ảnh Material/ và mesh
# Model/ mà tệp ấy gọi, cộng ba ảnh hằng của vật liệu EnScene (gradient mie và hai ảnh sương) và
# mesh vòm enskydome.mesh.
# Quyết định:
# - Tệp .EnScene chép nguyên byte (GBK hay UTF-8): client tự nhận bảng mã khi đọc (ensky::read_scene).
# - Tên ảnh đọc từ chính tệp: thẻ texture, textureEx, texturename và thuộc tính moon_tex_name,
#   sun_tex_name, sunflare_tex_name. Ảnh .tga thành Material/<tên>.tga.png (client chỉ giải PNG, DDS và
#   JPEG; bản .tga.png lấy ở cây GLB hay đổi bằng Pillow như collect_fx.bake_image); mọi định dạng khác
#   chép nguyên.
# - Mesh chép nguyên .mesh của kho gốc (client mở .mesh của OGRE trực tiếp, resource::load_named_model).
# - Hiệu ứng nền bầu trời (thẻ Effect, effect_name) do collect_fx.py gom cùng hiệu ứng của cảnh.
# - Bổ sung vào Scene/<map>.files.tsv, không ghi đè phần collect_map.py đã ghi.
# Cách dùng: python collect_sky.py <kho gốc _raw> <cây GLB _glb> <thư mục dữ liệu client> [map ...]
# Không nêu map thì lấy mọi Scene/*.Scene của thư mục dữ liệu. Mã thoát 1 khi có thứ thiếu.

from __future__ import annotations

import glob
import os
import sys
import xml.etree.ElementTree as ElementTree
from collections import Counter
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from collect_fx import bake_image  # noqa: E402
from collect_map import MODEL_FOLDER, SCENE_FOLDER, Collector, copy_files, property_of  # noqa: E402

MATERIAL_FOLDER = "Material"
# Ảnh và mesh cố định của vật liệu EnScene (MaterialTemplates/EnScene.hlsl, mesh EnDome).
FIXED_IMAGES = ("mie_gradient.dds", "bmp_overhead_weak_fog.dds", "bmp_horizon_fog_strong.dds")
FIXED_MESHES = ("enskydome.mesh",)
TEXT_TAGS = ("texture", "textureEx", "texturename")
MESH_TAG = "meshname"
IMAGE_ATTRIBUTES = ("moon_tex_name", "sun_tex_name", "sunflare_tex_name")


def decode(data: bytes) -> str:
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("gb18030")


def names_in(root: ElementTree.Element) -> tuple[set[str], set[str]]:
    images: set[str] = set()
    meshes: set[str] = set()
    for node in root.iter():
        text = (node.text or "").strip()
        if node.tag in TEXT_TAGS and text:
            images.add(text)
        if node.tag == MESH_TAG and text:
            meshes.add(text)
        for attribute in IMAGE_ATTRIBUTES:
            if node.get(attribute):
                images.add(node.get(attribute))
    return images, meshes


def sky_files_of(collector: Collector, scene: str) -> list[str]:
    path = os.path.join(collector.target, SCENE_FOLDER, scene + ".Scene")
    root = ElementTree.parse(path).getroot()
    names = []
    for node in root.iter("Object"):
        name = property_of(node, "config_file") if node.get("type") == "EnScene" else None
        if name:
            names.append(name)
    return names


def claim_image(collector: Collector, name: str) -> None:
    relative = os.path.join(MATERIAL_FOLDER, name)
    if not name.lower().endswith(".tga"):
        collector.want("sky_texture", collector.raw_root, relative)
        return
    baked = (relative + ".png").replace(os.sep, "/")
    if bake_image(collector, baked):
        collector.made[baked] = "sky_texture"
        return
    collector.missing.append(("sky_texture", baked))


def claim_mesh(collector: Collector, name: str) -> None:
    collector.want("sky_mesh", collector.raw_root, os.path.join(MODEL_FOLDER, name))


def collect_file(collector: Collector, name: str) -> None:
    relative = os.path.join(SCENE_FOLDER, name)
    if not collector.want("sky_scene", collector.raw_root, relative):
        return
    with open(os.path.join(collector.raw_root, relative), "rb") as stream:
        text = decode(stream.read())
    images, meshes = names_in(ElementTree.fromstring(text.split("?>", 1)[-1]))
    for image in sorted(images):
        claim_image(collector, image)
    for mesh in sorted(meshes):
        claim_mesh(collector, mesh)


def merge_list(collector: Collector, scene: str) -> None:
    path = os.path.join(collector.target, SCENE_FOLDER, scene + ".files.tsv")
    rows: dict[str, str] = {}
    if os.path.isfile(path):
        with open(path, encoding="utf-8") as stream:
            for line in stream.read().splitlines()[1:]:
                kind, _, relative = line.partition("\t")
                rows[relative] = kind
    for relative, (kind, _) in collector.files.items():
        rows[relative.replace(os.sep, "/")] = kind
    for relative in collector.made:
        rows[relative.replace(os.sep, "/")] = collector.made[relative]
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("kind\tpath\n")
        for relative, kind in sorted(rows.items()):
            stream.write(f"{kind}\t{relative}\n")


def collect_scene(raw_root: str, glb_root: str, target: str, scene: str) -> tuple[Collector, Counter]:
    collector = Collector(raw_root, glb_root, target)
    for name in sky_files_of(collector, scene):
        collect_file(collector, name)
    if collector.files:
        for image in FIXED_IMAGES:
            claim_image(collector, image)
        for mesh in FIXED_MESHES:
            claim_mesh(collector, mesh)
    sizes = copy_files(collector)
    merge_list(collector, scene)
    return collector, sizes


def main() -> int:
    if len(sys.argv) < 4:
        print("Cách dùng: python collect_sky.py <_raw> <_glb> <dữ liệu client> [map ...]", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    scenes = sys.argv[4:]
    if not scenes:
        pattern = os.path.join(target, SCENE_FOLDER, "*.Scene")
        scenes = sorted(os.path.splitext(os.path.basename(path))[0] for path in glob.glob(pattern))
    failed = False
    for scene in scenes:
        collector, sizes = collect_scene(raw_root, glb_root, target, scene)
        total = sum(sizes.values())
        print(f"Bầu trời {scene}: {len(collector.files)} tệp, {total} byte, "
              f"{len(collector.made)} ảnh đổi, thiếu {len(collector.missing)}")
        for kind, name in collector.missing:
            print(f"  THIẾU {kind}: {name}")
        failed = failed or bool(collector.missing)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
