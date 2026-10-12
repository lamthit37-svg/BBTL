# Xuất bảng ngoại hình người chơi cho client từ Config nhị phân của chính client 2026 (_raw) và cây
# GLB (_glb): player_bodies, faces, hairs, outfits, anim_sets, ghi vào <dữ liệu client>/Table/*.tsv.
# Logic đọc bảng port từ TLBB Dev tools/export/looks.cpp, action_sets.cpp, model_template.cpp
# @e0d89a6 (đọc lại bằng Python); khác: tên tệp giữ nguyên tên gốc (Model/<tên>.mesh,
# Model/<tên>.skeleton) thay cho tên sạch đã nấu, và mọi số liệu lấy từ dữ liệu của chính client này.
# Chuỗi clip của một hành động: CharModelEx (cột 20) -> ActionSet (hành động cơ sở) ->
# ActionSetLine (cột theo loại vũ khí) -> ActionSetKV (tên hành động) -> tên là skill của
# Effect/all.skill thì lấy dòng Animation của skill, không thì chính tên đó -> tệp chứa animation:
# skeleton chính của giới nếu nó có animation cùng tên, không thì tệp mà khối Skeletons của mẫu
# trong Model/all.obj ghi cho tên đó (cái đầu tiên, như emplace của bản gốc).
# Quyết định:
# - Dòng cao mô (cờ chọn -1, id là id thường cộng 10000) của mặt, tóc được giữ: màn tạo nhân vật
#   của client gốc vẽ người mẫu bằng chúng (docs/TAO-NHAN-VAT-2026.md). Dòng cờ -1 mà tệp lưới không
#   có trong _glb thì bỏ và đếm; trang phục mà tệp lưới không có trong _glb bị bỏ và được đếm trong
#   báo cáo; mặt, tóc cờ khác -1 và bộ mặc định mà thiếu thì dừng với lỗi.
# - faces và hairs giữ MỌI dòng theo đúng thứ tự tệp gốc, kèm tên (name) và cờ chọn (choice) nguyên
#   giá trị: màn tạo nhân vật trao đổi với game bằng vị trí của dòng trong từng giới và tự lọc theo
#   choice (ui/panel/role_cast). Tệp gốc đã xếp theo (id, race); lệch thì dừng với lỗi.
# - Mọi bảng là tệp TSV UTF-8, dòng đầu bắt đầu bằng # là chú thích, không căn cột.
# Cách dùng: python export_look.py <_raw> <_glb> <thư mục dữ liệu client>
# Mã thoát 1 khi có lỗi dữ liệu.

import json
import os
import re
import struct
import sys
import xml.etree.ElementTree as ElementTree

import dbc

RACES = {0: "female", 1: "male"}
# ActionSetLine: cột của từng loại vũ khí trong client 2026 (bảy loại cầm tay đầu như bản 2008;
# monster và npc dời sang 14, 15).
WEAPON_COLUMNS = {"none": 1, "spear": 2, "blade": 3, "dual_short": 4, "short": 5, "fan": 6, "ring": 7}
# Hành động cơ sở (ENUM_BASE_ACTION của ref) của sáu hành động có clip.
ACTIONS = {"idle": 0, "idle_alt": 1, "idle_alt2": 2, "run": 4, "combat_idle": 14, "combat_run": 16}
MODEL_OBJECT_COLUMN = 1
MODEL_ACTIONS_COLUMN = 20
RACE_MODEL, RACE_FACE, RACE_HAIR, RACE_BODY, RACE_ARM, RACE_FOOT = 3, 4, 5, 6, 7, 8
GEO_RACE, GEO_MESH = 1, 2
HAIR_ACCESSORY = 4
FACE_NAME, HAIR_NAME = 4, 6
FACE_CHOICE, HAIR_CHOICE = 7, 9
VISUAL_STRIDE = 11
HIGH_POLY = -1
MAX_SHORT = 65535


class ExportError(Exception):
    pass


class Sources:
    def __init__(self, raw_root: str, glb_root: str):
        self.raw_root = raw_root
        self.glb_root = glb_root
        self.config = os.path.join(raw_root, "Config")
        self.animation_cache = {}

    def table(self, relative: str) -> dbc.Dbc:
        return dbc.read(os.path.join(self.config, relative), os.path.basename(relative))

    def glb_path(self, name: str) -> str:
        return os.path.join(self.glb_root, "Model", name + ".glb")

    def has_glb(self, name: str) -> bool:
        return bool(name) and os.path.isfile(self.glb_path(name))

    # Tên các animation trong một tệp .skeleton (đọc từ JSON của GLB tương ứng).
    def animations_of(self, skeleton: str) -> list:
        if skeleton in self.animation_cache:
            return self.animation_cache[skeleton]
        path = self.glb_path(skeleton)
        names = []
        if os.path.isfile(path):
            with open(path, "rb") as stream:
                head = stream.read(20)
                length = struct.unpack_from("<I", head, 12)[0]
                document = json.loads(stream.read(length).decode("utf-8"))
            names = [item.get("name", "") for item in document.get("animations", [])]
        self.animation_cache[skeleton] = names
        return names

    # Skeleton mà lưới liên kết (extras.ogre.skeleton của GLB); rỗng khi lưới không có skeleton.
    def skeleton_of_mesh(self, mesh: str) -> str:
        with open(self.glb_path(mesh), "rb") as stream:
            head = stream.read(20)
            length = struct.unpack_from("<I", head, 12)[0]
            document = json.loads(stream.read(length).decode("utf-8"))
        extras = document["meshes"][0].get("extras", {}).get("ogre", {})
        return extras.get("skeleton", "")


def read_text_file(path: str) -> str:
    with open(path, "rb") as stream:
        raw = stream.read()
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("gb18030")


class ObjectBook:
    def __init__(self, path: str):
        text = re.sub(r"<!--.*?-->", "", read_text_file(path), flags=re.S)
        self.root = ElementTree.fromstring(text)
        self.by_name = {}
        for item in self.root.iter("Object"):
            self.by_name.setdefault(item.get("name"), []).append(item)

    def template(self, name: str):
        found = self.by_name.get(name, [])
        if len(found) != 1:
            raise ExportError(f"all.obj: {len(found)} mẫu tên {name}")
        return found[0]


# Chiều cao của mẫu: thành phần y của thuộc tính BoundingBox.
def height_of(template, name: str) -> float:
    values = [item.get("value") for item in template.iter("Attribute") if item.get("name") == "BoundingBox"]
    if len(values) != 1:
        raise ExportError(f"all.obj: mẫu {name} có {len(values)} BoundingBox")
    parts = values[0].split()
    if len(parts) != 3 or float(parts[1]) <= 0:
        raise ExportError(f"all.obj: BoundingBox của {name} sai dạng: {values[0]}")
    return float(parts[1])


# Animation -> tệp .skeleton theo khối Skeletons của mẫu; tên đầu tiên thắng.
def skeleton_links(template) -> dict:
    links = {}
    for item in template.iter("Skeleton"):
        skeleton, animations = item.get("skeleton"), item.get("animations")
        if not skeleton or not animations:
            continue
        for animation in animations.split():
            links.setdefault(animation, skeleton)
    return links


# Tên của một dòng đi vào ô TSV: không được mang tab hay xuống dòng.
def name_cell(table, row: int, column: int, source: str) -> str:
    name = table.text(row, column)
    if "	" in name or "
" in name or "" in name:
        raise ExportError(f"{source} dòng {row}: tên có tab hay xuống dòng")
    return name


⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
def read_action_tables(sources: Sources, wanted: set) -> tuple:
    sets = sources.table("ActionSet/ActionSet.txt")
    lines = sources.table("ActionSet/ActionSetLine.txt")
    names = sources.table("ActionSet/ActionSetKV.txt")
    index = {}
    for row in range(sets.rows):
        action_set = sets.integer(row, 1)
        if action_set not in wanted:
            continue
        key = (action_set, sets.integer(row, 2))
        line = sets.integer(row, 3)
        if index.setdefault(key, line) != line:
            raise ExportError(f"ActionSet dòng {row}: hai dòng khác nhau cho {key}")
    columns = sorted(WEAPON_COLUMNS.values())
    line_cells = {}
    for row in range(lines.rows):
        line_cells[lines.integer(row, 0)] = {column: lines.integer(row, column) for column in columns}
    kv_names = {names.integer(row, 0): names.text(row, 1) for row in range(names.rows)}
    return index, line_cells, kv_names


def read_bodies(sources: Sources, faces: list, book: ObjectBook) -> list:
    races = sources.table("CharRace.txt")
    models = sources.table("CharModelEx.txt")
    bodies = []
    for race in RACES:
        row = races.find(race)
        if row is None:
            raise ExportError(f"CharRace không có race {race}")
        model_row = models.find(races.integer(row, RACE_MODEL))
        if model_row is None:
            raise ExportError(f"CharModelEx không có model {races.integer(row, RACE_MODEL)}")
        template_name = models.text(model_row, MODEL_OBJECT_COLUMN)
        template = book.template(template_name)
        face_id = races.integer(row, RACE_FACE)
        face = next((item for item in faces if item[0] == face_id and item[1] == race), None)
        if face is None:
            raise ExportError(f"mặt mặc định {face_id} của {RACES[race]} không có trong bảng")
        bodies.append({
            "race": race,
            "name": RACES[race],
            "template": template_name,
            "skeleton": sources.skeleton_of_mesh(face[2]),
            "face": face_id,
            "hair": races.integer(row, RACE_HAIR),
            "body": races.integer(row, RACE_BODY),
            "arm": races.integer(row, RACE_ARM),
            "foot": races.integer(row, RACE_FOOT),
            "anim_set": models.integer(model_row, MODEL_ACTIONS_COLUMN),
            "height": height_of(template, template_name),
            "links": skeleton_links(template),
        })
    return bodies


def anim_rows(sources: Sources, bodies: list) -> list:
    index, lines, names = read_action_tables(sources, {body["anim_set"] for body in bodies})
    skills = read_skills(os.path.join(sources.raw_root, "Effect", "all.skill"))
    rows = []
    for body in bodies:
        for action, base in ACTIONS.items():
            for weapon, column in WEAPON_COLUMNS.items():
                name = action_name(index, lines, names, (body["anim_set"], base, column))
                animation = animation_of(skills, name)
                anim, clip = find_clip(sources, body["skeleton"], body["links"], animation)
                rows.append((body["anim_set"], action, weapon, anim, clip))
    return sorted(set(rows))
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
