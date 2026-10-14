# Gom đúng phần tài nguyên mà một map cần vào thư mục dữ liệu của client, giữ nguyên bố cục tương
# đối để URI ảnh trong GLB vẫn trỏ đúng: Scene/<map>.* (tệp gốc: .Scene, .Terrain, .Heightmap,
# .GridInfo, lightmap...), Brushes/<ảnh nền địa hình>, Model/<mesh>.mesh.glb và Material/<ảnh>.
# Đi theo chuỗi phụ thuộc: .Scene -> tên mesh của StaticEntity và TerrainLiquid, .model của Model
# -> GLB -> URI ảnh; .Scene -> .Terrain -> heightmap, gridInfo, lightmap, colorMap, ảnh nền;
# .Scene -> tệp .skysphere của phần tử SkySphere (ánh sáng theo giờ); bảng cảnh -> lưới đi .path và
# mặt công trình .WCollision (tùy chọn: nhiều cảnh không có).
# Quyết định:
# - Tên mesh tra đúng đường dẫn dưới Model/ trước; không thấy thì tra theo tên tệp trong cả cây và
#   chỉ nhận khi đúng một tệp khớp. Thứ không tìm được ghi vào danh sách thiếu, không dừng.
# - Chỉ chép, không đổi nội dung. Tệp đích đã có và cùng cỡ thì bỏ qua. Ngoại lệ duy nhất là ô ảnh
#   minimap Scene/jpg_<token>_<cột>_<hàng>.dds (256x256, 64 đơn vị cảnh mỗi ô): đổi sang PNG cùng
#   tên vì client chỉ giải mã PNG. Token là cột thứ 11 (szSceneMap) của Config/SceneDefineEx.txt
#   trong thư mục dữ liệu client. Cảnh không có dòng trong bảng hay không có ô ảnh thì chỉ ghi chú.
# - Hệ hạt, hiệu ứng và Actor chưa gom (client chưa nạp các loại đó); số lượng được in ra.
# Cách dùng: python collect_map.py <kho gốc _raw> <cây GLB _glb> <thư mục dữ liệu client> <tên map>
# Ghi <thư mục dữ liệu client>/Scene/<map>.files.tsv và in tổng hợp; mã thoát 1 khi có thứ thiếu.

import glob
import json
import os
import shutil
import struct
import sys
import xml.etree.ElementTree as ElementTree
from collections import Counter
from urllib.parse import unquote

SCENE_FOLDER = "Scene"
MODEL_FOLDER = "Model"
BRUSH_FOLDER = "Brushes"
CONFIG_FOLDER = "Config"
SCENE_TABLE = "SceneDefineEx.txt"
# Cột của bảng cảnh: tên tệp .Scene và token ảnh minimap.
SCENE_FILE_COLUMN = 4
PATH_COLUMN = 5
RADAR_COLUMN = 10
MESH_OWNERS = {"StaticEntity": "mesh name", "TerrainLiquid": "mesh name"}
JSON_CHUNK = 0x4E4F534A


class Collector:
    def __init__(self, raw_root: str, glb_root: str, target: str):
        self.raw_root = raw_root
        self.glb_root = glb_root
        self.target = target
        self.files = {}
        # Tệp sinh ra bằng cách đổi định dạng (đường dẫn trong cây đích -> loại), không chép nguyên.
        self.made = {}
        self.notes = []
        self.missing = []
        self.model_index = None

    # Ghi nhận một tệp cần chép: relative là đường dẫn trong cả cây nguồn lẫn cây đích.
    def want(self, kind: str, source_root: str, relative: str) -> bool:
        relative = os.path.normpath(relative)
        if os.path.isfile(os.path.join(source_root, relative)):
            self.files[relative] = (kind, source_root)
            return True
        self.missing.append((kind, relative))
        return False

    # Như want nhưng thiếu tệp không phải lỗi: dành cho tệp mà nhiều cảnh không có.
    def want_if_present(self, kind: str, source_root: str, relative: str) -> bool:
        relative = os.path.normpath(relative)
        if not os.path.isfile(os.path.join(source_root, relative)):
            return False
        self.files[relative] = (kind, source_root)
        return True

    def index_models(self) -> dict:
        if self.model_index is None:
            self.model_index = {}
            folder = os.path.join(self.glb_root, MODEL_FOLDER)
            for path, _, names in os.walk(folder):
                for name in names:
                    relative = os.path.relpath(os.path.join(path, name), self.glb_root)
                    self.model_index.setdefault(name.lower(), []).append(relative)
        return self.model_index

    # Đường dẫn GLB (trong cây GLB) của một mesh mà scene gọi tên; None khi không tìm được.
    def find_mesh(self, name: str) -> str | None:
        clean = name.replace("\\", "/").strip()
        relative = os.path.normpath(os.path.join(MODEL_FOLDER, clean + ".glb"))
        if os.path.isfile(os.path.join(self.glb_root, relative)):
            return relative
        matches = self.index_models().get(os.path.basename(clean).lower() + ".glb", [])
        return matches[0] if len(matches) == 1 else None

    def add_mesh(self, name: str) -> None:
        relative = self.find_mesh(name)
        if relative is None:
            self.missing.append(("mesh", name))
            return
        self.want("mesh", self.glb_root, relative)
        folder = os.path.dirname(relative)
        for uri in image_uris(os.path.join(self.glb_root, relative)):
            self.want("texture", self.glb_root, os.path.join(folder, unquote(uri)))

    # .model: XML liệt kê skeleton (frame) và các mesh gắn vào nó, tên tương đối với chính tệp đó.
    def add_model(self, name: str) -> None:
        relative = os.path.normpath(os.path.join(MODEL_FOLDER, name.replace("\\", "/")))
        if not self.want("model", self.raw_root, relative):
            return
        folder = os.path.dirname(relative)
        root = ElementTree.parse(os.path.join(self.raw_root, relative)).getroot()
        for frame in root.iter("frame"):
            frame_path = os.path.join(folder, frame.get("name") + ".glb")
            self.want("skeleton", self.glb_root, frame_path)
        for entity in root.iter("entity"):
            inside = os.path.relpath(os.path.join(folder, entity.get("mesh")), MODEL_FOLDER)
            self.add_mesh(inside)

    def add_terrain(self, file_name: str) -> None:
        relative = os.path.join(SCENE_FOLDER, file_name)
        if not self.want("terrain", self.raw_root, relative):
            return
        root = ElementTree.parse(os.path.join(self.raw_root, relative)).getroot()
        for tag in ("heightmap", "gridInfo", "lightmap", "colorMap"):
            for node in root.iter(tag):
                self.want("terrain", self.raw_root, os.path.join(SCENE_FOLDER, node.get("filename")))
        for texture in root.iter("texture"):
            self.want("brush", self.raw_root, os.path.join(BRUSH_FOLDER, texture.get("filename")))


def image_uris(path: str) -> list:
    with open(path, "rb") as stream:
        header = stream.read(20)
        length, kind = struct.unpack_from("<II", header, 12)
        if kind != JSON_CHUNK:
            raise ValueError(f"GLB hỏng: {path}")
        document = json.loads(stream.read(length).decode("utf-8"))
    return [image["uri"] for image in document.get("images", []) if "uri" in image]


def property_of(node, name: str) -> str | None:
    for item in node.findall("Property"):
        if item.get("name") == name:
            return item.get("value")
    return None


def collect_scene(collector: Collector, scene: str) -> Counter:
    relative = os.path.join(SCENE_FOLDER, scene + ".Scene")
    types = Counter()
    if not collector.want("scene", collector.raw_root, relative):
        return types
    root = ElementTree.parse(os.path.join(collector.raw_root, relative)).getroot()
    for terrain in root.iter("Terrain"):
        collector.add_terrain(terrain.get("filename"))
    # Bảng môi trường theo giờ (EnvKey): client đọc tệp mà phần tử SkySphere nêu tên.
    for sky in root.iter("SkySphere"):
        if sky.get("filename"):
            collector.want("sky", collector.raw_root, os.path.join(SCENE_FOLDER, sky.get("filename")))
    for node in root.iter("Object"):
        kind = node.get("type")
        types[kind] += 1
        mesh = property_of(node, MESH_OWNERS.get(kind, ""))
        if mesh:
            collector.add_mesh(mesh)
        model = property_of(node, "model name") if kind == "Model" else None
        if model:
            collector.add_model(model)
    return types


# Các ô của dòng bảng cảnh có tệp <scene>.Scene, đọc từ bảng đã gom; None khi bảng hay dòng không có.
def scene_cells(target: str, scene: str) -> list[str] | None:
    table = os.path.join(target, CONFIG_FOLDER, SCENE_TABLE)
    if not os.path.isfile(table):
        return None
    wanted = (scene + ".Scene").lower()
    with open(table, encoding="utf-8") as stream:
        for line in stream:
            cells = line.rstrip("\r\n").split("\t")
            if len(cells) > RADAR_COLUMN and cells[SCENE_FILE_COLUMN].lower() == wanted:
                return cells
    return None


# Token ảnh minimap của cảnh có tệp <scene>.Scene; None khi không có.
def radar_token(target: str, scene: str) -> str | None:
    cells = scene_cells(target, scene)
    if cells is None:
        return None
    return cells[RADAR_COLUMN] or None


# Lưới đi (.path) và mặt công trình (.WCollision) của cảnh: client mở đúng hai tên này cạnh tệp cảnh
# (world.cpp: tên .path ghi ở bảng cảnh, tên .WCollision là tên cảnh đổi đuôi). Nhiều cảnh không có
# hai tệp ấy ở kho gốc, nên thiếu chỉ là ghi chú; thiếu lưới đi thì nhân vật đi xuyên mọi vật cản.
def collect_walk(collector: Collector, scene: str) -> None:
    cells = scene_cells(collector.target, scene)
    path_name = cells[PATH_COLUMN] if cells is not None and len(cells) > PATH_COLUMN else ""
    if not path_name:
        collector.notes.append(f"bảng cảnh không nêu tên tệp .path của {scene}: không gom lưới đi")
    wanted = [("walk", os.path.join(SCENE_FOLDER, path_name))] if path_name else []
    wanted.append(("collision", os.path.join(SCENE_FOLDER, scene + ".WCollision")))
    for kind, relative in wanted:
        if not collector.want_if_present(kind, collector.raw_root, relative):
            collector.notes.append(f"kho gốc không có {relative.replace(os.sep, '/')}")


# Đổi một ô ảnh DDS sang PNG; ô đích mới hơn nguồn thì giữ.
def convert_tile(source: str, output: str) -> None:
    if os.path.isfile(output) and os.path.getmtime(output) >= os.path.getmtime(source):
        return
    from PIL import Image

    os.makedirs(os.path.dirname(output), exist_ok=True)
    part = output + ".part"
    with Image.open(source) as image:
        image.convert("RGBA").save(part, "PNG")
    os.replace(part, output)


def collect_radar(collector: Collector, scene: str) -> None:
    token = radar_token(collector.target, scene)
    if token is None:
        collector.notes.append(f"không có token minimap của {scene} trong {SCENE_TABLE}")
        return
    pattern = os.path.join(collector.raw_root, SCENE_FOLDER, f"jpg_{glob.escape(token)}_*_*.dds")
    tiles = sorted(glob.glob(pattern))
    if not tiles:
        collector.notes.append(f"không có ô ảnh minimap jpg_{token}_*")
    for source in tiles:
        name = os.path.splitext(os.path.basename(source))[0] + ".png"
        relative = os.path.join(SCENE_FOLDER, name)
        convert_tile(source, os.path.join(collector.target, relative))
        collector.made[relative] = "radar"


def copy_files(collector: Collector) -> Counter:
    sizes = Counter()
    for relative, (kind, source_root) in sorted(collector.files.items()):
        source = os.path.join(source_root, relative)
        output = os.path.join(collector.target, relative)
        size = os.path.getsize(source)
        is_present = os.path.isfile(output) and os.path.getsize(output) == size
        if not is_present:
            os.makedirs(os.path.dirname(output), exist_ok=True)
            shutil.copyfile(source, output)
        sizes[kind] += size
    return sizes


def write_list(collector: Collector, scene: str) -> None:
    path = os.path.join(collector.target, SCENE_FOLDER, scene + ".files.tsv")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("kind\tpath\n")
        rows = {relative: kind for relative, (kind, _) in collector.files.items()}
        rows.update(collector.made)
        for relative, kind in sorted(rows.items()):
            stream.write(f"{kind}\t{relative.replace(os.sep, '/')}\n")


def main() -> int:
    if len(sys.argv) != 5:
        print("Cách dùng: python collect_map.py <_raw> <_glb> <dữ liệu client> <tên map>", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    scene = sys.argv[4]
    collector = Collector(raw_root, glb_root, target)
    types = collect_scene(collector, scene)
    collect_walk(collector, scene)
    collect_radar(collector, scene)
    sizes = copy_files(collector)
    write_list(collector, scene)
    kinds = Counter(kind for kind, _ in collector.files.values())
    print(f"Map {scene}: vật thể trong scene: {dict(types)}")
    for kind in sorted(kinds):
        print(f"  {kind}: {kinds[kind]} tệp, {sizes[kind]} byte")
    print(f"  tổng: {len(collector.files)} tệp, {sum(sizes.values())} byte vào {target}")
    print(f"  radar: {len(collector.made)} ô ảnh minimap đổi sang PNG")
    for note in collector.notes:
        print(f"  GHI CHÚ: {note}")
    for kind, name in collector.missing:
        print(f"  THIẾU {kind}: {name}")
    return 1 if collector.missing else 0


if __name__ == "__main__":
    sys.exit(main())
