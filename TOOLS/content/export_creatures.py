#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/export_creatures.py
#  PHÂN HỆ   : Content / Export Creatures
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Xuất bốn bảng quái và NPC cho client từ Config của client 2026:
#    creature_templates, creatures, creature_clips, creature_materials.
#  - Template lấy từ spawns*.tsv của các cảnh; chạy lặp cho byte y hệt, --check
#    chỉ so, --collect gọi collect_creatures.py.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

# Nguồn dữ liệu và chuỗi tra (client 2026, đo bằng chạy trên cây _goc/_cook và đối chiếu mã máy Game.exe):
# - Template (id trong spawns*.tsv của cảnh) -> MonsterAttrExTable: cột 1 tên, cột 2 cờ không-bị-đánh
#   (nCannotBeAttack, >0 là NPC, còn lại quái; bảng máy chủ gọi nhầm là gender), cột 36 id mô hình, cột 39..41
#   bảng tên / vòng chọn / bóng (fBoardHeight, fProjTexRange, fShadowRange).
# - Mô hình -> CharModelEx: cột 1 là tên mẫu .obj trong Model/all.obj, cột 5 là hệ số scale đều của mô hình, cột 20 là
#   tệp action set (-1 là không có). Cột 5: Game.exe đọc nó ở +0x20 của dòng (CObject_Character vtable slot 98, mặc
#   định 1; slot 99 bọc lại và chỉ nhân thêm cho thú cưng) rồi đặt SetScale ba trục lên mô hình lúc
#   CObject_PlayerNPC dựng nó; một mẫu .obj được dùng lại với nhiều hệ số (boss "头目" 1,2, "缩小" 0,6, người tuyết
#   1,05..1,55). Chưa nhìn tận mắt: ngoài Scale của mẫu trong all.obj hay thay nó (ghi cạnh nhau, client nhân).
# - Mẫu .obj -> lưới (Entity file, theo thứ tự tài liệu như objects.tsv), material chồng (Entity material),
#   Scale, BoundingBox, khối Skeletons, DefaultAnimation.
# Quyết định:
# - Skeleton chính của mô hình là skeleton của lưới đầu tiên có skeleton theo thứ tự byte GBK của tên entity (EntityMap
#   của bản gốc là std::map; docs/NGOAI-HINH.md của TLBB Dev). Lưới của một mô hình mang hai skeleton khác nhau thì
#   bỏ mô hình đó và nêu trong báo cáo (chưa có ca nào), vì đoán sẽ vẽ sai thầm. Mô hình hỏng không chặn các mô hình khác.
# - Entity có material khác material mặc định của lưới là "áp lại da" (Entity::setMaterialName áp cho mọi submesh):
#   1 522 trên 3 407 entity có khai material của 5 891 mô hình quái/NPC làm vậy (vd. 断桥花妖 dùng lưới 镜湖花妖 với da
#   riêng), nên bỏ đi sẽ vẽ sai da. Tên material ghi ở cột materials của creatures.tsv (cùng thứ tự với meshes, rỗng
#   là không chồng) và creature_materials.tsv giải sẵn thành ảnh nền, chế độ alpha, hai mặt, không-chiếu-sáng bằng
#   đúng luật convert.py dùng khi ghi GLB.
# - Chưa xuất: vũ khí mặc định trong Slot của locator (Đại Lý + Lạc Dương: 2 trong 130 mô hình, vd. 书生扇), locator,
#   entity có condition (chỉ đếm).
# - Loại vũ khí của clip: mẫu không bị đánh dùng cột npc (15) của ActionSetLine, còn lại cột monster (14) -- đúng
#   GetCharActionNameByActionSetID ở CT_MONSTER. Một mô hình có thể được cả NPC lẫn quái dùng (397 trên 5 891) và hai
#   cột có tên khác nhau ở 624 dòng, nên creature_clips.tsv khoá theo (model, kind).
# - Hành động thiếu (action set -1, dòng ActionSet không có, tên rỗng, clip không có ở skeleton chính lẫn khối
#   Skeletons) thì bỏ dòng và đếm lý do, không bịa clip. "default" là DefaultAnimation của mẫu (client chạy nó khi
#   không có action set).
# - Cảnh: tên thư mục máy chủ (dali), tên tệp cảnh của client (dali_new_320) hoặc resid (2). Template lấy từ cột
#   type của mọi dev/server/scenes/<thư mục>/spawns*.tsv; thú hoang (wild_pets.tsv) là bảng PetAttrTable khác nên chưa vào.
# - Bảng ra phụ thuộc đúng danh sách cảnh ở đối số (không cộng dồn với lượt trước): chạy lại cho byte y hệt.
# Khác TLBB Dev (tools/export/model_anims.cpp): thêm walk, combat_walk, hit, death, corpse, attack*, default; skeleton
# suy từ lưới của mẫu chứ không từ .tlobj đã nấu; thêm material chồng và chiều cao hộp ngoài.
# Cách dùng: python export_creatures.py <_raw> <_glb> <thư mục dữ liệu client> <cảnh>... [--server dev/server]
#            [--check] [--collect]
# --check chỉ so với tệp đang có (mã thoát 1 khi lệch); --collect gọi thêm collect_creatures.py.
# Mã thoát 1 khi có lỗi dữ liệu.

import argparse
import glob
import json
import os
import struct
import sys
from collections import Counter
from decimal import Decimal
from pathlib import Path
from typing import NamedTuple

GLB_TOOLS = Path(__file__).resolve().parents[1] / "glb"
if str(GLB_TOOLS) not in sys.path:
    sys.path.insert(0, str(GLB_TOOLS))

import convert  # noqa: E402
import dbc  # noqa: E402
from collect_fx import load_materials  # noqa: E402
from export_look import (ExportError, ObjectBook, Sources, action_name, animation_of, find_clip,  # noqa: E402
                         read_action_tables, read_skills, skeleton_links)
from export_weapons import Templates, scale_of  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
TABLE_FOLDER = "Table"
SOURCE_ENCODING = "gb18030"
# MonsterAttrExTable.
MONSTER_NAME, MONSTER_CANNOT_ATTACK, MONSTER_MODEL = 1, 2, 36
MONSTER_PLATE, MONSTER_RING, MONSTER_SHADOW = 39, 40, 41
# CharModelEx.
MODEL_OBJECT, MODEL_SCALE, MODEL_ACTIONS = 1, 5, 20
# ActionSetLine: cột loại vũ khí của quái và NPC (client 2026; export_look.py ghi chú vì sao 14 và 15).
KIND_COLUMNS = {"monster": 14, "npc": 15}
# Hành động có clip: tên trong bảng -> hành động cơ sở (ENUM_BASE_ACTION của ref; attack* là bước 1..3 của
# "普通攻击" ở SkillTemplate_V1 cột 18, xem export_skills.py). Thứ tự này cũng là thứ tự dòng của bảng.
ACTIONS = {"idle": 0, "idle_alt": 1, "idle_alt2": 2, "walk": 3, "run": 4, "combat_idle": 14, "combat_walk": 15,
           "combat_run": 16, "hit": 23, "death": 24, "corpse": 25, "attack": 162, "attack_alt": 163,
           "attack_alt2": 164}
DEFAULT_ACTION = "default"
TOOL_LINE = "TOOLS/content/export_creatures.py; sửa tay sẽ mất ở lượt xuất sau"


class Creature(NamedTuple):
    template: int
    name: str
    kind: str
    model: int
    plate_height: str
    ring_size: str
    shadow_size: str
    scale: str


class ModelLook(NamedTuple):
    model: int
    meshes: list
    materials: list
    skeleton: str
    scale: tuple
    height: str
    links: dict
    default_animation: str
    action_set: int
    conditional: int


def float_text(value: float) -> str:
    """Số thực float32 ngắn nhất đọc lại ra đúng giá trị, không số mũ (100 chứ không 100.0 hay 1e+02)."""
    if value != value or value in (float("inf"), float("-inf")):
        raise ExportError(f"số thực không hữu hạn: {value}")
    for digits in range(1, 10):
        text = f"{value:.{digits}g}"
        if struct.unpack("<f", struct.pack("<f", float(text)))[0] == value:
            return format(Decimal(text), "f")
    return format(Decimal(f"{value:.9g}"), "f")


def clean(text: str) -> str:
    if any(char in text for char in "\t\r\n"):
        raise ExportError(f"ô bảng mang tab hay xuống dòng: {text!r}")
    return text


# ---------------------------------------------------------------- cảnh -> template


class SceneBook(NamedTuple):
    """scene_ids.tsv (máy chủ) và tên tệp cảnh của SceneDefineEx (client): đủ để nhận ba cách gọi một cảnh."""

    dirs_of_resid: dict
    resid_of_file: dict
    known_dirs: set


def read_server_table(path: Path) -> tuple:
    """Bảng TSV của máy chủ (bỏ dòng #, bỏ đệm dấu cách của bố cục căn cột): (tên cột, các dòng)."""
    lines = [line.rstrip("\r\n") for line in path.read_text(encoding="utf-8").splitlines() if not line.startswith("#")]
    rows = [[cell.rstrip(" ") for cell in line.split("\t")] for line in lines if line]
    return rows[0], rows[1:]


def scene_book(server_root: Path, scene_table: dbc.Dbc) -> SceneBook:
    header, rows = read_server_table(server_root / "tables" / "server" / "scene_ids.tsv")
    dir_at, res_at = header.index("scene_dir"), header.index("client_res_id")
    dirs_of_resid: dict = {}
    for row in rows:
        found = dirs_of_resid.setdefault(int(row[res_at]), [])
        if row[dir_at] not in found:
            found.append(row[dir_at])
    resid_of_file = {}
    for line in range(scene_table.rows):
        stem = os.path.splitext(scene_table.text(line, 4))[0].lower()
        resid_of_file.setdefault(stem, scene_table.integer(line, 0))
    known = {path.name for path in (server_root / "scenes").iterdir() if path.is_dir()}
    return SceneBook(dirs_of_resid, resid_of_file, known)


def resolve_scene(book: SceneBook, argument: str) -> list:
    """Thư mục máy chủ của một cảnh: resid (2), tên thư mục (dali) hoặc tên tệp cảnh của client (dali_new_320)."""
    if argument.isdigit():
        found = book.dirs_of_resid.get(int(argument), [])
    elif argument in book.known_dirs:
        found = [argument]
    else:
        stem = os.path.splitext(argument)[0].lower()
        found = book.dirs_of_resid.get(book.resid_of_file.get(stem, -1), [])
    found = [name for name in found if name in book.known_dirs]
    if not found:
        raise ExportError(f"cảnh {argument!r}: không thấy thư mục cảnh của máy chủ (resid, thư mục hay tên tệp cảnh)")
    return found


def spawn_types(server_root: Path, scene_dir: str) -> Counter:
    """Template -> số chỗ đặt, từ cột type của mọi spawns*.tsv của thư mục cảnh."""
    counts: Counter = Counter()
    for path in sorted(glob.glob(str(server_root / "scenes" / scene_dir / "spawns*.tsv"))):
        header, rows = read_server_table(Path(path))
        at = header.index("type")
        for row in rows:
            if row[at]:
                counts[int(row[at])] += 1
    return counts


# ---------------------------------------------------------------- bảng template


def read_creatures(sources: Sources, wanted: set, report: dict) -> list:
    monsters = sources.table("MonsterAttrExTable.txt")
    models = sources.table("CharModelEx.txt")
    monster_row = {monsters.integer(row, 0): row for row in range(monsters.rows)}
    model_row = {models.integer(row, 0): row for row in range(models.rows)}
    creatures = []
    for template in sorted(wanted):
        row = monster_row.get(template)
        if row is None:
            report["unknown_templates"].append(template)
            continue
        model = monsters.integer(row, MONSTER_MODEL)
        scale_row = model_row.get(model)
        creatures.append(Creature(
            template, clean(monsters.text(row, MONSTER_NAME)),
            "npc" if monsters.integer(row, MONSTER_CANNOT_ATTACK) > 0 else "monster", model,
            float_text(monsters.real(row, MONSTER_PLATE)), float_text(monsters.real(row, MONSTER_RING)),
            float_text(monsters.real(row, MONSTER_SHADOW)),
            float_text(models.real(scale_row, MODEL_SCALE)) if scale_row is not None else "1"))
    return creatures


# ---------------------------------------------------------------- mô hình


def mesh_document(sources: Sources, mesh: str, cache: dict) -> dict | None:
    """JSON của GLB lưới (đọc một lần); None khi không có GLB."""
    if mesh not in cache:
        path = sources.glb_path(mesh)
        document = None
        if os.path.isfile(path):
            with open(path, "rb") as stream:
                head = stream.read(20)
                document = json.loads(stream.read(struct.unpack_from("<I", head, 12)[0]).decode("utf-8"))
        cache[mesh] = document
    return cache[mesh]


def mesh_skeleton(document: dict) -> str:
    return document["meshes"][0].get("extras", {}).get("ogre", {}).get("skeleton", "")


def mesh_materials(document: dict) -> list:
    """Tên material gốc của từng submesh (primitive) của lưới."""
    return [item.get("extras", {}).get("ogre", {}).get("material", "") for item in document["meshes"][0]["primitives"]]


def pick_skeleton(entities: list) -> str:
    """Skeleton chính từ (tên entity, skeleton của lưới): lưới đầu tiên có skeleton theo byte GBK của tên entity."""
    ordered = sorted(entities, key=lambda item: item[0].encode(SOURCE_ENCODING, errors="replace"))
    found = [skeleton for _, skeleton in ordered if skeleton]
    if len(set(found)) > 1:
        raise ExportError(f"các lưới của một mô hình mang nhiều skeleton: {sorted(set(found))}")
    return found[0] if found else ""


def overriding_material(entity_material: str, default_materials: list) -> str:
    """Material chồng của entity: rỗng khi entity không khai hoặc mọi submesh của lưới đã dùng đúng material đó."""
    if entity_material and any(name != entity_material for name in default_materials):
        return entity_material
    return ""


def height_text(template) -> str:
    """Chiều cao của hộp ngoài của mẫu: thành phần y của BoundingBox ba số (cỡ), hay maxY trừ minY khi có sáu số
    (minX minY minZ maxX maxY maxZ); đo trên 5 891 mô hình của MonsterAttrExTable: 2 026 mẫu ba số, 3 236 mẫu sáu số
    (252 trong đó có minY khác 0), 628 mẫu không khai thì 0."""
    values = [item.get("value") for item in template.iter("Attribute") if item.get("name") == "BoundingBox"]
    if not values:
        return "0"
    parts = [float(part) for part in values[0].split()]
    if len(parts) not in (3, 6) or not all(part == part for part in parts):
        raise ExportError(f"BoundingBox của mẫu {template.get('name')} sai dạng: {values[0]!r}")
    height = parts[1] if len(parts) == 3 else parts[4] - parts[1]
    if height < 0:
        raise ExportError(f"BoundingBox của mẫu {template.get('name')} có chiều cao âm: {values[0]!r}")
    return float_text(struct.unpack("<f", struct.pack("<f", height))[0])


def default_animation(template) -> str:
    values = [item.get("value") for item in template.iter("Attribute") if item.get("name") == "DefaultAnimation"]
    return values[0].strip() if values and values[0] else ""


def build_look(sources: Sources, templates: Templates, models: dbc.Dbc, model_row: dict, model: int,
               cache: dict, report: dict) -> ModelLook | None:
    try:
        return read_look(sources, templates, models, model_row, model, cache, report)
    except ExportError as error:
        report["lost_models"].append(f"{model}: {error}")
        return None


def read_look(sources: Sources, templates: Templates, models: dbc.Dbc, model_row: dict, model: int,
              cache: dict, report: dict) -> ModelLook | None:
    row = model_row.get(model)
    if row is None:
        report["lost_models"].append(f"{model}: CharModelEx không có mô hình")
        return None
    object_name = models.text(row, MODEL_OBJECT)
    template = templates.find(object_name)
    if template is None:
        report["lost_models"].append(f"{model}: all.obj không có mẫu {object_name}")
        return None
    meshes, materials, entities, conditional = [], [], [], 0
    for entity in template.iter("Entity"):
        mesh = entity.get("file")
        if not mesh:
            continue
        document = mesh_document(sources, mesh, cache)
        if document is None:
            report["lost_models"].append(f"{model}: không có GLB của lưới {mesh}")
            return None
        meshes.append(clean(mesh))
        materials.append(clean(overriding_material(entity.get("material") or "", mesh_materials(document))))
        entities.append((entity.get("name") or "", mesh_skeleton(document)))
        conditional += 1 if entity.get("condition") else 0
    if not meshes:
        report["lost_models"].append(f"{model}: mẫu {object_name} không có lưới")
        return None
    skeleton = pick_skeleton(entities)
    if skeleton and not sources.has_glb(skeleton):
        report["lost_skeletons"].append(f"{model}: không có GLB của skeleton {skeleton}")
        skeleton = ""
    return ModelLook(model, meshes, materials, skeleton, scale_of(template), height_text(template),
                     skeleton_links(template), default_animation(template), models.integer(row, MODEL_ACTIONS),
                     conditional)


# ---------------------------------------------------------------- clip


class ClipBook(NamedTuple):
    sources: Sources
    skills: dict
    index: dict
    lines: dict
    names: dict


def resolve_clip(book: ClipBook, look: ModelLook, kind: str, action: str) -> tuple:
    """(skeleton chứa clip, tên clip) của một hành động, hoặc (None, lý do) khi mô hình không có."""
    if action == DEFAULT_ACTION:
        name = look.default_animation
    else:
        try:
            name = action_name(book.index, book.lines, book.names,
                               (look.action_set, ACTIONS[action], KIND_COLUMNS[kind]))
        except ExportError:
            return None, "action set không có hành động"
    if not name:
        return None, "tên hành động rỗng"
    try:
        return find_clip(book.sources, look.skeleton, look.links, animation_of(book.skills, name))
    except ExportError:
        return None, "clip không có ở skeleton chính lẫn khối Skeletons"


def clip_rows(book: ClipBook, looks: list, kinds_of: dict, report: dict) -> list:
    rows = []
    for look in looks:
        if not look.skeleton:
            continue
        for kind in sorted(kinds_of[look.model]):
            for action in (*ACTIONS, DEFAULT_ACTION):
                if action == DEFAULT_ACTION and not look.default_animation:
                    continue
                if look.action_set < 0 and action != DEFAULT_ACTION:
                    report["dropped"]["không có action set"] += 1
                    continue
                anim, clip = resolve_clip(book, look, kind, action)
                if anim is None:
                    report["dropped"][clip] += 1
                    continue
                rows.append((look.model, kind, action, anim, clip))
    return rows


# ---------------------------------------------------------------- material chồng


def material_rows(raw_root: str, glb_root: str, names: list, report: dict) -> list:
    """Mỗi material chồng giải thành ảnh nền và thiết lập, bằng đúng luật của TOOLS/glb/convert.py."""
    if not names:
        return []
    library = load_materials(raw_root)
    context = convert.Context(os.path.join(raw_root, "Material"), library, "", "Material")
    rows = []
    for name in sorted(names):
        effective = library.effective(name.encode(SOURCE_ENCODING))
        primary = effective.primary() if effective is not None else None
        base = convert.base_texture(primary, context) if primary is not None else None
        if base is None:
            report["unresolved_materials"].append(name)
            continue
        mode, cutoff = convert.alpha_mode(primary.settings)
        settings = primary.settings
        rows.append((clean(name), "Material/" + convert.texture_output(convert.texture_path(base)), mode,
                     "" if cutoff is None else float_text(struct.unpack("<f", struct.pack("<f", cutoff))[0]),
                     1 if settings.get(b"cull_hardware", b"").strip() == b"none" else 0,
                     1 if settings.get(b"lighting", b"").split()[:1] == [b"off"] else 0))
    return rows


def without_materials(looks: list, unresolved: set) -> list:
    """Material chồng không giải được ảnh nền thì coi như không chồng (lưới giữ da của nó), để cột materials không
    nêu tên mà creature_materials.tsv không có."""
    if not unresolved:
        return looks
    return [look._replace(materials=["" if name in unresolved else name for name in look.materials]) for look in looks]


# ---------------------------------------------------------------- ghi bảng


def render_table(comments: list, header: list, rows: list) -> str:
    lines = [f"# {comment}" for comment in comments]
    lines.append("\t".join(header))
    lines.extend("\t".join(str(cell) for cell in row) for row in rows)
    return "\n".join(lines) + "\n"


def tables_text(creatures: list, looks: list, clips: list, materials: list, scenes: list) -> dict:
    where = f"cảnh {', '.join(scenes)}"
    head = ["schema 1", f"source: client_2026/MonsterAttrExTable.txt, CharModelEx.txt, Model/all.obj ({where})",
            f"tool: {TOOL_LINE}"]
    return {
        "creature_templates.tsv": render_table(head + [
            "Quái và NPC mà các cảnh đặt, khoá template (MonsterAttrExTable cột 0).",
            "name là tên chữ gốc; model là id CharModelEx (-1 là không có), khoá của creatures.tsv; plate_height, ring_size, shadow_size",
            "là fBoardHeight, fProjTexRange, fShadowRange (plate_height -1 là để client tính theo chiều cao mô hình);",
            "scale là hệ số scale đều của mô hình (CharModelEx cột 5), nhân với sx sy sz của creatures.tsv;",
            "kind là npc khi MonsterAttrExTable cột 2 lớn hơn 0 (không bị đánh), còn lại monster: chọn cột clip của creature_clips.tsv."],
            ["template", "name", "model", "plate_height", "ring_size", "shadow_size", "scale", "kind"],
            [(c.template, c.name, c.model, c.plate_height, c.ring_size, c.shadow_size, c.scale, c.kind)
             for c in creatures]),
        "creatures.tsv": render_table(head + [
            "Mô hình quái và NPC, khoá model (CharModelEx cột 0).",
            "meshes là các tệp .mesh dưới Model/ (nối bằng |, theo thứ tự entity của mẫu trong Model/all.obj);",
            "materials cùng số phần tử, tên material chồng lên lưới (rỗng là dùng material của lưới), giải ở creature_materials.tsv;",
            "skeleton là tệp .skeleton chính dưới Model/ (rỗng là mô hình tĩnh); sx sy sz là thuộc tính Scale của mẫu (1 1 1 khi không khai);",
            "height là chiều cao y của BoundingBox (0 là mẫu không khai)."],
            ["model", "meshes", "skeleton", "sx", "sy", "sz", "height", "materials"],
            [(look.model, "|".join(look.meshes), look.skeleton, *look.scale, look.height, "|".join(look.materials))
             for look in looks]),
        "creature_clips.tsv": render_table(head + [
            "Clip động tác của quái và NPC, khoá (model, kind, action); kind của creature_templates.tsv.",
            "action: idle, idle_alt, idle_alt2, walk, run, combat_idle, combat_walk, combat_run, hit, death, corpse, attack,",
            "attack_alt, attack_alt2 (hành động cơ sở 0 1 2 3 4 14 15 16 23 24 25 162 163 164 của action set của mô hình) và default",
            "(DefaultAnimation của mẫu); mô hình thiếu hành động nào thì không có dòng đó.",
            "anim là tệp .skeleton chứa clip (dưới Model/), clip là tên animation trong tệp đó."],
            ["model", "kind", "action", "anim", "clip"], clips),
        "creature_materials.tsv": render_table(head + [
            "Material chồng lên lưới của quái và NPC (cột materials của creatures.tsv), khoá material.",
            "texture là ảnh nền (đường dẫn từ gốc dữ liệu); alpha là OPAQUE, MASK hay BLEND, cutoff là ngưỡng khi MASK;",
            "double_sided và unlit là 0 hay 1. Cùng luật mà TOOLS/glb/convert.py dùng để ghi material của GLB."],
            ["material", "texture", "alpha", "cutoff", "double_sided", "unlit"], materials),
    }


def store(target: Path, texts: dict, check: bool) -> list:
    """Ghi (hoặc chỉ so) các bảng; trả danh sách tệp lệch."""
    differing = []
    for name, text in texts.items():
        path = target / TABLE_FOLDER / name
        current = path.read_bytes() if path.is_file() else None
        if current == text.encode("utf-8"):
            continue
        differing.append(name)
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(text.encode("utf-8"))
    return differing


def build(raw_root: str, glb_root: str, server_root: Path, scene_args: list) -> tuple:
    sources = Sources(raw_root, glb_root)
    report = {"unknown_templates": [], "lost_models": [], "lost_skeletons": [], "unresolved_materials": [],
              "dropped": Counter()}
    book = scene_book(server_root, sources.table("SceneDefineEx.txt"))
    scenes, placed = [], Counter()
    for argument in scene_args:
        for scene_dir in resolve_scene(book, argument):
            if scene_dir not in scenes:
                scenes.append(scene_dir)
                placed.update(spawn_types(server_root, scene_dir))
    creatures = read_creatures(sources, set(placed), report)
    kinds_of: dict = {}
    for creature in creatures:
        if creature.model >= 0:
            kinds_of.setdefault(creature.model, set()).add(creature.kind)
    objects = Templates(ObjectBook(os.path.join(raw_root, "Model", "all.obj")))
    models = sources.table("CharModelEx.txt")
    model_row = {models.integer(row, 0): row for row in range(models.rows)}
    cache: dict = {}
    looks = [look for model in sorted(kinds_of)
             if (look := build_look(sources, objects, models, model_row, model, cache, report)) is not None]
    set_files = {look.action_set for look in looks if look.action_set >= 0}
    index, lines, names = read_action_tables(sources, set_files, KIND_COLUMNS.values())
    clips_book = ClipBook(sources, read_skills(os.path.join(raw_root, "Effect", "all.skill")), index, lines, names)
    clips = clip_rows(clips_book, looks, kinds_of, report)
    overrides = {name for look in looks for name in look.materials if name}
    materials = material_rows(raw_root, glb_root, sorted(overrides), report)
    looks = without_materials(looks, set(report["unresolved_materials"]))
    texts = tables_text(creatures, looks, clips, materials, scenes)
    summary = {"scenes": scenes, "spawns": sum(placed.values()), "templates": len(creatures), "models": len(looks),
               "clips": len(clips), "materials": len(materials), "conditional": sum(look.conditional for look in looks),
               "invisible": sum(1 for creature in creatures if creature.model < 0),
               "static": sum(1 for look in looks if not look.skeleton),
               "no_set": sum(1 for look in looks if look.action_set < 0)}
    return texts, summary, report


def main(argv: list | None = None) -> int:
    parser = argparse.ArgumentParser(description="Xuất bảng quái và NPC cho client từ Config của client 2026.")
    parser.add_argument("raw")
    parser.add_argument("glb")
    parser.add_argument("target")
    parser.add_argument("scenes", nargs="+")
    parser.add_argument("--server", default=str(ROOT / "dev" / "server"))
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--collect", action="store_true")
    args = parser.parse_args(argv)
    raw_root, glb_root, target = (os.path.abspath(path) for path in (args.raw, args.glb, args.target))
    try:
        texts, summary, report = build(raw_root, glb_root, Path(args.server), args.scenes)
    except (ExportError, dbc.DbcError, OSError, KeyError, ValueError) as error:
        print(f"Lỗi: {error}", file=sys.stderr)
        return 1
    differing = store(Path(target), texts, args.check)
    print(f"cảnh {', '.join(summary['scenes'])}: {summary['spawns']} chỗ đặt, templates {summary['templates']}, "
          f"models {summary['models']} ({summary['static']} tĩnh, {summary['no_set']} không có action set; "
          f"{summary['invisible']} template không có mô hình), "
          f"clips {summary['clips']}, materials chồng {summary['materials']}, entity có condition {summary['conditional']}")
    for key, label in (("unknown_templates", "Template không có trong MonsterAttrExTable"),
                       ("lost_models", "Mô hình bỏ"), ("lost_skeletons", "Skeleton thiếu GLB"),
                       ("unresolved_materials", "Material chồng không giải được ảnh nền")):
        if report[key]:
            print(f"{label}: {len(report[key])}: {', '.join(str(item) for item in report[key][:8])}")
    if report["dropped"]:
        print(f"Dòng clip bỏ: {dict(report['dropped'])}")
    for name in differing if args.check else []:
        print(f"LỆCH: Table/{name}")
    status = 1 if differing and args.check else 0
    if args.collect:
        import collect_creatures

        status |= collect_creatures.run(raw_root, glb_root, target, args.check)
    return status


if __name__ == "__main__":
    sys.exit(main())
