#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/export_look.py
#  PHÂN HỆ   : Content / Export Look
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Xuất bảng ngoại hình người chơi cho client từ Config nhị phân của chính
#    client 2026 (_raw) và cây GLB (_glb): player_bodies, faces, hairs,
#    outfits, anim_sets, ghi vào <dữ liệu client>/Table/*.tsv.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Logic đọc bảng port từ TLBB Dev tools/export/looks.cpp, action_sets.cpp, model_template.cpp @e0d89a6 (đọc lại bằng
# Python); khác: tên tệp giữ nguyên tên gốc (Model/<tên>.mesh, Model/<tên>.skeleton) thay cho tên sạch đã nấu, và mọi
# số liệu lấy từ dữ liệu của chính client này.

# Chuỗi clip của một hành động: CharModelEx (cột 20) -> ActionSet (hành động cơ sở) -> ActionSetLine (cột theo loại vũ
# khí) -> ActionSetKV (tên hành động) -> tên là skill của Effect/all.skill thì lấy dòng Animation của skill, không thì
# chính tên đó -> tệp chứa animation: skeleton chính của giới nếu nó có animation cùng tên, không thì tệp mà khối
# Skeletons của mẫu trong Model/all.obj ghi cho tên đó (cái đầu tiên, như emplace của bản gốc). Quyết định:
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
# Hành động cơ sở (ENUM_BASE_ACTION của ref) của tám hành động có clip. jump_stand là BASE_ACTION_N_JUMP_N (9),
# jump_run là BASE_ACTION_N_JUMP_R (12) của CObject_Character::Jump.
ACTIONS = {"idle": 0, "idle_alt": 1, "idle_alt2": 2, "run": 4, "jump_stand": 9, "jump_run": 12, "combat_idle": 14,
           "combat_run": 16}
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
    if "\t" in name or "\n" in name or "\r" in name:
        raise ExportError(f"{source} dòng {row}: tên có tab hay xuống dòng")
    return name


# Các dòng phải tăng dần theo (id, race) như tệp gốc: module look tra theo khoá đó, còn màn tạo
# nhân vật đếm vị trí dòng trong từng giới.
def keep_file_order(rows: list, source: str) -> list:
    keys = [(row[0], row[1]) for row in rows]
    if keys != sorted(set(keys)):
        raise ExportError(f"{source}: dòng không tăng dần theo (id, race) hay khoá lặp")
    return rows


def read_faces(sources: Sources, report: dict) -> list:
    table = sources.table("CharFaceGeo.txt")
    rows = []
    for row in range(table.rows):
        choice = table.integer(row, FACE_CHOICE)
        race = table.integer(row, GEO_RACE)
        if race not in RACES:
            raise ExportError(f"CharFaceGeo dòng {row}: race {race} không phải người chơi")
        mesh = table.text(row, GEO_MESH)
        if not sources.has_glb(mesh):
            if choice != HIGH_POLY:
                raise ExportError(f"CharFaceGeo dòng {row}: không có GLB của lưới {mesh}")
            report["face_high_poly"] += 1
            continue
        item_id = table.integer(row, 0)
        if not 0 <= item_id <= MAX_SHORT:
            raise ExportError(f"CharFaceGeo dòng {row}: id {item_id} ngoài miền")
        rows.append((item_id, race, mesh, name_cell(table, row, FACE_NAME, "CharFaceGeo"), choice))
    return keep_file_order(rows, "CharFaceGeo")


def read_hairs(sources: Sources, report: dict) -> list:
    table = sources.table("CharHairGeo.txt")
    rows = []
    for row in range(table.rows):
        choice = table.integer(row, HAIR_CHOICE)
        race = table.integer(row, GEO_RACE)
        if race not in RACES:
            raise ExportError(f"CharHairGeo dòng {row}: race {race} không phải người chơi")
        mesh = table.text(row, GEO_MESH)
        accessory = table.text(row, HAIR_ACCESSORY)
        absent = [name for name in (mesh, accessory) if name and not sources.has_glb(name)]
        if absent and choice != HIGH_POLY:
            raise ExportError(f"CharHairGeo dòng {row}: không có GLB của lưới {absent[0]}")
        if absent:
            report["hair_high_poly"] += 1
            continue
        item_id = table.integer(row, 0)
        if not 0 <= item_id <= MAX_SHORT:
            raise ExportError(f"CharHairGeo dòng {row}: id {item_id} ngoài miền")
        rows.append((item_id, race, mesh, accessory, name_cell(table, row, HAIR_NAME, "CharHairGeo"), choice))
    return keep_file_order(rows, "CharHairGeo")


# Trang phục: mỗi dòng ItemVisualChar cho mỗi giới một lưới ở cột 1 + 11 * race và danh sách
# material ở cột kế. Lưới không có GLB bị bỏ và đếm lại (bộ tân thủ 121..129 là ví dụ ở bản TLBB).
def read_outfits(sources: Sources, report: dict) -> list:
    table = sources.table("ItemVisualChar.txt")
    rows = []
    for row in range(table.rows):
        for race in RACES:
            column = 1 + VISUAL_STRIDE * race
            mesh = table.text(row, column)
            if not mesh:
                continue
            item_id = table.integer(row, 0)
            if not sources.has_glb(mesh):
                report["absent_outfits"].append(f"{item_id} {RACES[race]}")
                continue
            rows.append((item_id, race, mesh, table.text(row, column + 1)))
    return sorted(rows)


SKILL_BLOCKS = ("AnimEffect", "Ribbon", "Sound", "SceneLight")


# Máy trạng thái theo dòng của parseSkillFile (port từ TLBB Dev tools/export/skill_book.cpp): ngoài
# skill thì chờ dòng "skill <tên>"; trong skill thì "}" đóng, tên khối con thì nhảy qua khối, dòng
# khác là thuộc tính "<tên> <giá trị>" mà chỉ Animation được giữ. Trả về tên skill -> animation.
def read_skills(path: str) -> dict:
    lines = [line.strip() for line in read_text_file(path).splitlines()]
    animations = {}
    current = None
    at = 0
    while at < len(lines):
        line = lines[at]
        at += 1
        if not line or line.startswith("//"):
            continue
        if current is None:
            words = line.split()
            if len(words) == 2 and words[0] == "skill":
                if words[1] in animations:
                    raise ExportError(f"all.skill: skill {words[1]} định nghĩa hai lần")
                animations[words[1]] = ""
                current = words[1]
                while at < len(lines) and lines[at] != "{":
                    at += 1
                at += 1
            continue
        if line == "}":
            current = None
        elif line in SKILL_BLOCKS:
            while at < len(lines) and lines[at] != "{":
                at += 1
            while at < len(lines) and lines[at] != "}":
                at += 1
            at += 1
        else:
            words = line.split(None, 1)
            if len(words) == 2 and words[0] == "Animation":
                animations[current] = words[1].strip()
    return animations


# Tên là skill thì animation của skill, không thì animation cùng tên.
def animation_of(skills: dict, name: str) -> str:
    if name not in skills:
        return name
    if not skills[name]:
        raise ExportError(f"skill {name} không có Animation")
    return skills[name]


def action_name(index: dict, lines: dict, names: dict, key: tuple) -> str:
    action_set, base, column = key
    line_id = index.get((action_set, base))
    if line_id is None or line_id not in lines:
        raise ExportError(f"action set {action_set}: không có hành động {base}")
    kv_id = lines[line_id][column]
    if kv_id not in names:
        raise ExportError(f"ActionSetKV không có dòng {kv_id}")
    return names[kv_id]


# Tìm tệp và clip cho một tên animation: skeleton chính trước, rồi khối Skeletons của mẫu.
def find_clip(sources: Sources, main: str, links: dict, animation: str) -> tuple:
    if animation in sources.animations_of(main):
        return main, animation
    linked = links.get(animation)
    if linked is None:
        raise ExportError(f"animation {animation} không có tệp (skeleton chính {main})")
    if animation not in sources.animations_of(linked):
        raise ExportError(f"{linked} không có animation {animation}")
    return linked, animation


def read_action_tables(sources: Sources, wanted: set, extra_columns=()) -> tuple:
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
    columns = sorted({*WEAPON_COLUMNS.values(), *extra_columns})
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


def write_table(path: str, comments: list, header: list, rows: list) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        for line in comments:
            stream.write(f"# {line}\n")
        stream.write("\t".join(header) + "\n")
        for row in rows:
            stream.write("\t".join(str(cell) for cell in row) + "\n")


def write_all(target: str, bodies: list, faces: list, hairs: list, outfits: list, anims: list) -> None:
    table_dir = os.path.join(target, "Table")
    source = "Sinh bằng TOOLS/content/export_look.py từ Config của client; sửa tay sẽ mất ở lượt xuất sau."
    write_table(os.path.join(table_dir, "player_bodies.tsv"),
                ["Thân người chơi theo giới, khoá race (0 nữ, 1 nam).", source,
                 "template là mẫu trong Model/all.obj; skeleton là tệp .skeleton chính (dưới Model/);",
                 "face, hair, body, arm, foot là id mặc định; anim_set là id tệp action set; height là chiều cao y của BoundingBox."],
                ["race", "name", "template", "skeleton", "face", "hair", "body", "arm", "foot", "anim_set", "height"],
                [(b["race"], b["name"], b["template"], b["skeleton"], b["face"], b["hair"], b["body"],
                  b["arm"], b["foot"], b["anim_set"], b["height"]) for b in bodies])
    write_table(os.path.join(table_dir, "faces.tsv"),
                ["Mặt người chơi, khoá (id, race), mọi dòng theo thứ tự tệp gốc.", source,
                 "mesh là tên tệp .mesh dưới Model/; name là tên kiểu mặt; choice 1 hay 3 là chọn được lúc tạo nhân vật,",
                 "-1 là dòng cao mô (id thường cộng 10000) mà người mẫu của màn tạo dùng."],
                ["id", "race", "mesh", "name", "choice"], faces)
    write_table(os.path.join(table_dir, "hairs.tsv"),
                ["Tóc người chơi, khoá (id, race), mọi dòng theo thứ tự tệp gốc.", source,
                 "mesh và accessory được rỗng (đầu trọc, không phụ kiện); name là tên kiểu tóc; choice như ở faces.tsv."],
                ["id", "race", "mesh", "accessory", "name", "choice"], hairs)
    write_table(os.path.join(table_dir, "outfits.tsv"),
                ["Hình trang phục (áo, tay, giày, mũ), khoá (id, race).", source,
                 "materials: danh sách material của ItemVisualChar giữ nguyên chữ, áp theo thứ tự submesh khi không rỗng."],
                ["id", "race", "mesh", "materials"], outfits)
    write_table(os.path.join(table_dir, "anim_sets.tsv"),
                ["Clip động tác của người chơi, khoá (set, action, weapon).", source,
                 "anim là tệp .skeleton chứa clip (dưới Model/), clip là tên animation trong tệp đó."],
                ["set", "action", "weapon", "anim", "clip"], anims)


def main() -> int:
    if len(sys.argv) != 4:
        print("Cách dùng: python export_look.py <_raw> <_glb> <dữ liệu client>", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    sources = Sources(raw_root, glb_root)
    report = {"face_high_poly": 0, "hair_high_poly": 0, "absent_outfits": []}
    try:
        book = ObjectBook(os.path.join(raw_root, "Model", "all.obj"))
        faces = read_faces(sources, report)
        hairs = read_hairs(sources, report)
        outfits = read_outfits(sources, report)
        bodies = read_bodies(sources, faces, book)
        anims = anim_rows(sources, bodies)
    except (ExportError, dbc.DbcError, OSError, KeyError) as error:
        print(f"Lỗi: {error}", file=sys.stderr)
        return 1
    write_all(target, bodies, faces, hairs, outfits, anims)
    print(f"player_bodies {len(bodies)}, faces {len(faces)} (bỏ {report['face_high_poly']} cao mô thiếu lưới), "
          f"hairs {len(hairs)} (bỏ {report['hair_high_poly']} cao mô thiếu lưới), outfits {len(outfits)}, "
          f"anim_sets {len(anims)}")
    if report["absent_outfits"]:
        print(f"Trang phục bỏ vì thiếu lưới trong _glb: {len(report['absent_outfits'])}: "
              f"{', '.join(report['absent_outfits'][:12])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

