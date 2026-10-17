# -*- coding: utf-8 -*-
"""Sinh bảng thú cưỡi của client từ CharMount, CharModelEx và PetPossPositionValue.

Chạy từ gốc dự án:
  py -3 -B TOOLS/content/export_rides.py [đường-all.obj]
Có đối số thì thêm locator, hạt Effect của mẫu, skeleton và clip của mọi thú,
cùng một chuỗi ActionSet → ActionSetLine → ActionSetKV → clip trên skeleton.
"""

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MOUNTS = ROOT / "dev" / "server" / "tables" / "shared" / "mounts.tsv"
MODELS = ROOT / "dev" / "server" / "tables" / "client" / "CharModelEx.tsv"
OFFSETS = ROOT / "dev" / "server" / "tables" / "shared" / "pet_possession_position_values.tsv"
OUT = ROOT / "dev" / "client" / "assets" / "Table"

EXTERIOR = ROOT / "dev" / "server" / "tables" / "shared" / "exterior_rides.tsv"
# Dòng bản nháp trùng MountId. Chỉ bỏ khi MountId đã có dòng không mang chữ này.
DRAFT_NOTE = "没加脚本啊"
MOUNT_ID_COLUMN = 10
SPEED_COLUMN = 11
NAME_COLUMN = 7

RIDE_HEAD = (
    "id\tname\tpassenger_capacity\tmodel_id\tadd_height\tride_recipe\t"
    "driver_action_0\tdriver_action_1\tanchor_0\tpassenger_action_0\tpassenger_action_1\t"
    "anchor_1\tanchor_2\tanchor_3\tanchor_4\tanchor_5\t"
    "extra_16\textra_17\textra_18\textra_19\textra_20\textra_21\tcamera_y\teffect_id\t"
    "speed_percent"
)


def cells(line):
    return [part.strip() for part in line.rstrip("\n").split("\t")]


def data_rows(path):
    header = None
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        parts = cells(line)
        if header is None:
            header = parts
            continue
        rows.append(parts)
    return rows


def mesh_name(obj):
    if obj.lower().endswith(".obj"):
        return obj[:-4] + ".mesh"
    return obj


def write(path, note, header, lines):
    body = note + header + "\n" + "".join(lines)
    path.write_text(body, encoding="utf-8", newline="\n")


def export_rides(mounts, speeds):
    lines = []
    missing = 0
    for part in mounts:
        mount_id = integer_cell(part[0])
        percent = speeds.get(mount_id)
        if percent is None:
            percent = 0
            missing += 1
        picked = part[0:24]
        picked.append(str(percent))
        lines.append("\t".join(picked) + "\n")
    note = (
        "# source: dev/server/tables/shared/mounts.tsv\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# anchor_0 là +0x28, anchor_1 là +0x38; camera_y là +0x78; effect_id là +0x7c\n"
        "# extra_16..21 chưa có người đọc trong Game.exe\n"
        "# speed_percent là Exterior_Ride cột 11 (Speed), khoá cột 10 (MountId).\n"
        "# Không có dòng thì 0: giữ tốc độ chạy người, không cộng phần trăm.\n"
        "# Dòng tên chứa 没加脚本啊 bị bỏ khi MountId đã có dòng khác.\n"
    )
    write(OUT / "rides.tsv", note, RIDE_HEAD, lines)
    return missing


def export_models(mounts, models):
    wanted = set()
    for part in mounts:
        if part[3] != "-1":
            wanted.add(part[3])
    by_id = {part[0]: part for part in models}
    lines = []
    missing = []
    for model_id in sorted(wanted, key=int):
        row = by_id.get(model_id)
        if row is None:
            missing.append(model_id)
            continue
        mesh = mesh_name(row[1])
        lines.append(f"{model_id}\t{mesh}\t{row[5]}\t{row[20]}\n")
    note = (
        "# source: dev/server/tables/client/CharModelEx.tsv\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# scale là cột 5; action_set là cột 20 (+0x5c). Lưới đổi .obj thành .mesh.\n"
    )
    write(OUT / "ride_models.tsv", note, "model\tmesh\tscale\taction_set", lines)
    return missing


def export_offsets(offsets):
    lines = []
    for part in offsets:
        # id, x, y, z, axis xyz, angle, label — đúng cột tệp gốc.
        ordered = [part[0], part[1], part[2], part[3], part[4], part[5], part[6], part[7], part[8]]
        lines.append("\t".join(ordered) + "\n")
    note = (
        "# source: dev/server/tables/shared/pet_possession_position_values.tsv\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# Lời gọi +0x288 lấy x y z angle axis_x axis_y axis_z. label không đưa vào lời gọi.\n"
    )
    head = "id\tx\ty\tz\taxis_x\taxis_y\taxis_z\tangle\tlabel"
    write(OUT / "ride_offsets.tsv", note, head, lines)


def usable(text):
    return text is not None and "\t" not in text and "\n" not in text and "\r" not in text


def locator_line(obj_name, locator):
    name = locator.get("name") or ""
    bone = locator.get("bonename") or ""
    numbers = [locator.get(key) for key in ("x", "y", "z", "qx", "qy", "qz", "qw")]
    if not usable(name) or not usable(bone) or any(not usable(number) for number in numbers):
        return None
    first = locator.get("translateFirst") or ""
    flag = "1" if first.lower() == "true" else "0"
    cells = [obj_name, name, bone, *numbers, flag, ""]
    return "\t".join(cells) + "\n"


def object_names(mounts, models):
    """Tên .obj của CharModelEx mà thú trỏ tới, mỗi mẫu một lần, theo thứ tự gặp."""
    by_id = {part[0]: part for part in models}
    names = []
    for part in mounts:
        if part[3] == "-1":
            continue
        row = by_id.get(part[3])
        if row is None or row[1] in names:
            continue
        names.append(row[1])
    return names


def export_locators(book, mounts, models):
    """Locator của mẫu .obj mà thú cưỡi dùng. qx qy qz là trục, qw là góc, không phải quaternion."""
    names = object_names(mounts, models)
    lines = []
    seen = set()
    absent = 0
    for obj_name in names:
        items = book.by_name.get(obj_name, [])
        if not items:
            absent += 1
            continue
        for locator in items[0].iter("Locator"):
            key = (obj_name, locator.get("name") or "")
            if key in seen:
                continue
            line = locator_line(obj_name, locator)
            if line is None:
                continue
            seen.add(key)
            lines.append(line)
    lines.sort()
    note = (
        "# source: Model/all.obj, mẫu CharModelEx mà CharMount trỏ tới\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# qx qy qz qw là trục và góc radian của all.obj, không phải quaternion.\n"
    )
    head = "object\tlocator\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\tslot"
    write(OUT / "ride_locators.tsv", note, head, lines)
    print(f"locators {len(lines)} objects {len(names) - absent} absent {absent}")


def effect_line(obj_name, element):
    """Một thẻ Effect. translateAll thiếu hoặc khác true thì 0, đúng mặc định parser."""
    slot = element.get("name") or ""
    effect = element.get("effect") or ""
    locator = element.get("locator") or ""
    if not usable(slot) or not usable(effect) or not usable(locator):
        return None
    raw = element.get("translateAll")
    flag = "1" if raw is not None and raw.lower() == "true" else "0"
    cells = [obj_name, slot, effect, locator, flag]
    return "\t".join(cells) + "\n"


def entity_line(obj_name, index, element):
    """Một thẻ Entity. material giữ nguyên chuỗi gốc, kể cả dấu ; giữa các submesh."""
    file_name = element.get("file") or ""
    material = element.get("material") or ""
    condition = element.get("condition") or ""
    if not file_name or not usable(file_name) or not usable(material) or not usable(condition):
        return None
    cells = [obj_name, str(index), file_name, material, condition]
    return "\t".join(cells) + "\n"


def export_entities(book, mounts, models):
    """Mọi Entity của mẫu, đúng thứ tự tài liệu. Không lấy tên lưới CharModelEx thay cho danh sách này."""
    names = object_names(mounts, models)
    lines = []
    absent = 0
    skipped = 0
    for obj_name in names:
        items = book.by_name.get(obj_name, [])
        if not items:
            absent += 1
            print(f"entities absent {obj_name}")
            continue
        index = 0
        for entity in items[0].iter("Entity"):
            line = entity_line(obj_name, index, entity)
            if line is None:
                skipped += 1
                continue
            lines.append(line)
            index += 1
    note = (
        "# source: Model/all.obj, thẻ Entity của mẫu CharModelEx mà CharMount trỏ tới\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# file là lưới thật. CharModelEx chỉ đặt tên mẫu; nhiều mẫu không có tệp .mesh trùng tên.\n"
        "# materials là thuộc tính material, tên submesh ngăn bởi dấu ; theo thứ tự submesh.\n"
        "# Ô rỗng của một submesh giữ material ghi trong lưới. Cả ô rỗng là không chồng.\n"
        "# condition khác rỗng thì client không vẽ: bản đo 2026-10-17 mọi thú đều rỗng.\n"
        "# slot là thứ tự trong mẫu, bắt đầu từ 0. Trùng (object, slot) là lỗi.\n"
    )
    head = "object\tslot\tfile\tmaterials\tcondition"
    write(OUT / "ride_entities.tsv", note, head, lines)
    print(f"entities {len(lines)} objects {len(names) - absent} absent {absent} skipped {skipped}")


def export_effects(book, mounts, models):
    """Hạt gắn sẵn: thẻ Effect con của Effects. Không có colour trên thú. Tên trùng giữ dòng đầu."""
    names = object_names(mounts, models)
    lines = []
    seen = set()
    absent = 0
    skipped = 0
    for obj_name in names:
        items = book.by_name.get(obj_name, [])
        if not items:
            absent += 1
            print(f"effects absent {obj_name}")
            continue
        for block in items[0].findall("Effects"):
            for child in list(block):
                if child.tag != "Effect":
                    continue
                slot = child.get("name") or ""
                key = (obj_name, slot)
                if key in seen:
                    skipped += 1
                    continue
                line = effect_line(obj_name, child)
                if line is None:
                    skipped += 1
                    continue
                seen.add(key)
                lines.append(line)
    note = (
        "# source: Model/all.obj, thẻ Effect trong Effects của mẫu CharModelEx\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# translate_all 1 là translateAll=true: hạt lấy cả hướng của điểm.\n"
        "# Thiếu thuộc tính hay giá trị khác true thì 0: chỉ lấy vị trí điểm.\n"
        "# Không mẫu thú nào ghi colour: không nhân màu.\n"
        "# Tên slot trùng trong một mẫu thì giữ dòng đầu, như LogicModel::addEffect.\n"
    )
    head = "object\tslot\teffect\tlocator\ttranslate_all"
    write(OUT / "ride_effects.tsv", note, head, lines)
    print(f"effects {len(lines)} objects {len(names) - absent} absent {absent} skipped {skipped}")


# Hành động cơ sở và cột vũ khí, cùng số với export_look.py (ENUM_BASE_ACTION, ENUM_WEAPON_TYPE).
ACTIONS = {"idle": 0, "idle_alt": 1, "idle_alt2": 2, "run": 4, "jump_stand": 9, "jump_run": 12,
           "combat_idle": 14, "combat_run": 16}
WEAPON_COLUMNS = {"none": 1, "spear": 2, "blade": 3, "dual_short": 4, "short": 5, "fan": 6, "ring": 7}
SHARED = ROOT / "dev" / "server" / "tables" / "shared"
MODEL_DIR = ROOT / "dev" / "client" / "assets" / "Model"
# Cột người cưỡi và khách trên rides.tsv. Chỉ số 0 là giới mà client truyền khi race = 0.
RIDER_COLUMNS = ((6, 0), (7, 1), (9, 0), (10, 1))


def integer_cell(text):
    try:
        return int(text)
    except ValueError:
        return None


def mount_speeds(rows):
    """MountId → phần trăm. Hai dòng sạch lệch nhau thì dừng, không tự chọn."""
    grouped = {}
    for part in rows:
        if len(part) <= SPEED_COLUMN:
            raise SystemExit(f"exterior_rides thiếu cột: {len(part)}")
        mount_id = integer_cell(part[MOUNT_ID_COLUMN])
        percent = integer_cell(part[SPEED_COLUMN])
        if mount_id is None or percent is None or percent < 0:
            raise SystemExit(f"exterior speed không đọc được, id {part[0]}")
        name = part[NAME_COLUMN]
        grouped.setdefault(mount_id, []).append((percent, DRAFT_NOTE in name))
    chosen = {}
    for mount_id, items in grouped.items():
        clean = [item for item in items if not item[1]]
        pool = clean if clean else items
        percents = {item[0] for item in pool}
        if len(percents) != 1:
            listed = " ".join(str(value) for value in sorted(percents))
            raise SystemExit(f"mount {mount_id} lệch tốc độ: {listed}")
        chosen[mount_id] = pool[0][0]
    return chosen


def load_sets(wanted):
    """(action set, hành động cơ sở) → id dòng ActionSetLine."""
    index = {}
    path = SHARED / "action_set.tsv"
    for part in data_rows(path):
        if len(part) < 4:
            continue
        action_set = integer_cell(part[1])
        base = integer_cell(part[2])
        line = integer_cell(part[3])
        if action_set not in wanted or base is None or line is None:
            continue
        index.setdefault((action_set, base), line)
    return index


def load_lines(needed):
    """id dòng → cột vũ khí → id ActionSetKV. Chỉ giữ dòng mà action set trỏ tới."""
    lines = {}
    columns = list(WEAPON_COLUMNS.values())
    for part in data_rows(SHARED / "action_set_line.tsv"):
        line_id = integer_cell(part[0]) if part else None
        if line_id not in needed:
            continue
        cells_of = {}
        for column in columns:
            if column < len(part):
                value = integer_cell(part[column])
                if value is not None:
                    cells_of[column] = value
        lines[line_id] = cells_of
    return lines


def load_names():
    names = {}
    for part in data_rows(SHARED / "action_set_kv.tsv"):
        if len(part) < 2:
            continue
        key = integer_cell(part[0])
        if key is None:
            continue
        names[key] = part[1].strip()
    return names


def load_skills():
    """Tên skill → animation. Không có all.skill thì tên KV dùng nguyên.

    Cây lỏng F:\\tl 2026 là nguồn. Tên KV của thú bốn chân (npc_qichenglang_tudi)
    không phải tên clip; trường Animation của skill mới là 跑步.
    """
    candidates = [
        Path(r"F:\tl 2026") / "_goc" / "Effect" / "all.skill",
        ROOT / "dev" / "client" / "assets" / "Effect" / "all.skill",
        Path(r"G:\XTLBB") / "Effect" / "all.skill",
    ]
    path = next((item for item in candidates if item.is_file()), None)
    if path is None:
        return {}
    sys.path.insert(0, str(ROOT / "TOOLS" / "content"))
    from export_look import read_skills
    return read_skills(str(path))


def document_of(cache, skeleton):
    if skeleton in cache:
        return cache[skeleton]
    document = {}
    path = MODEL_DIR / f"{skeleton}.glb"
    if path.is_file():
        data = path.read_bytes()
        length = struct.unpack_from("<I", data, 12)[0] if len(data) >= 20 else 0
        if 20 + length <= len(data):
            document = json.loads(data[20:20 + length].decode("utf-8"))
    cache[skeleton] = document
    return document


def animations_of(cache, skeleton):
    document = document_of(cache, skeleton)
    return [item.get("name", "") for item in document.get("animations", [])]


def bone_names(cache, skeleton):
    document = document_of(cache, skeleton)
    return [item.get("name", "") for item in document.get("nodes", [])]


def same_bones(cache, clip_skeleton, main):
    """Cùng luật check_same_bones: tiền tố tên xương theo handle phải khớp."""
    if clip_skeleton == main:
        return True
    left = bone_names(cache, clip_skeleton)
    right = bone_names(cache, main)
    shared = min(len(left), len(right))
    if shared == 0:
        return False
    return left[:shared] == right[:shared]


def find_clip(cache, main, links, animation):
    if animation and animation in animations_of(cache, main):
        return main, animation
    linked = links.get(animation) if animation else None
    if not linked or animation not in animations_of(cache, linked):
        return None
    return linked, animation


def decode_skeleton(raw):
    if not raw:
        return ""
    text = raw.split(b"\x00", 1)[0].decode("gb18030")
    text = text.replace("\\", "/").rsplit("/", 1)[-1]
    return text


def mesh_skeleton(cache, mesh):
    if mesh in cache:
        return cache[mesh]
    path = MODEL_DIR / mesh
    name = ""
    if path.is_file():
        sys.path.insert(0, str(ROOT / "TOOLS" / "glb"))
        from ogre_mesh import read_mesh
        name = decode_skeleton(read_mesh(path.read_bytes()).skeleton)
    cache[mesh] = name
    return name


def model_skeleton(book, row, cache):
    """Skeleton của lưới CharModelEx. Tệp đó không có thì lấy lưới Entity đầu tiên có liên kết."""
    found = mesh_skeleton(cache, mesh_name(row[1]))
    if found:
        return found
    items = book.by_name.get(row[1], [])
    if not items:
        return ""
    for entity in items[0].iter("Entity"):
        found = mesh_skeleton(cache, entity.get("file") or "")
        if found:
            return found
    return ""


def player_rigs(book):
    from export_look import skeleton_links
    rigs = {}
    for part in data_rows(OUT / "player_bodies.tsv"):
        sex = integer_cell(part[0])
        items = book.by_name.get(part[2], [])
        links = skeleton_links(items[0]) if items else {}
        rigs[sex] = {"skeleton": part[3], "links": links}
    return rigs


def clip_of(index, lines, names, skills, cache, main, links, action_set, base, column):
    line_id = index.get((action_set, base))
    if line_id is None or line_id not in lines:
        return None
    kv_id = lines[line_id].get(column)
    if kv_id is None or kv_id not in names:
        return None
    name = names[kv_id]
    from export_look import animation_of
    animation = animation_of(skills, name)
    if not animation:
        return None
    found = find_clip(cache, main, links, animation)
    if found is None or not same_bones(cache, found[0], main):
        return None
    return found


def rider_sets_of(mounts):
    found = {}
    for part in mounts:
        for column, sex in RIDER_COLUMNS:
            action_set = integer_cell(part[column]) if column < len(part) else None
            if action_set is None or action_set < 0:
                continue
            found.setdefault(action_set, set()).add(sex)
    return found


def export_chain(obj_path, mounts, models):
    """Mọi thú: skeleton đúng liên kết của lưới, clip người cưỡi và clip của chính thú."""
    from export_look import ObjectBook, skeleton_links

    book = ObjectBook(str(obj_path))
    by_id = {part[0]: part for part in models}
    rigs = player_rigs(book)
    riders = rider_sets_of(mounts)
    model_sets = set()
    skeleton_of = {}
    mesh_cache = {}
    link_cache = {}
    for part in mounts:
        if part[3] == "-1" or part[3] in skeleton_of:
            continue
        row = by_id.get(part[3])
        if row is None:
            continue
        skeleton_of[part[3]] = model_skeleton(book, row, mesh_cache)
        action_set = integer_cell(row[20])
        if action_set is not None and action_set >= 0:
            model_sets.add(action_set)
        if row[1] not in link_cache:
            items = book.by_name.get(row[1], [])
            link_cache[row[1]] = skeleton_links(items[0]) if items else {}
    wanted = set(riders) | model_sets
    index = load_sets(wanted)
    lines = load_lines(set(index.values()))
    names = load_names()
    skills = load_skills()
    cache = {}
    rider_rows = []
    missed = 0
    disagreed = 0
    for action_set, sexes in sorted(riders.items()):
        for action, base in ACTIONS.items():
            for weapon, column in WEAPON_COLUMNS.items():
                found = None
                broken = False
                for sex in sorted(sexes):
                    rig = rigs.get(sex)
                    if rig is None:
                        broken = True
                        break
                    hit = clip_of(index, lines, names, skills, cache, rig["skeleton"], rig["links"],
                                  action_set, base, column)
                    if hit is None or (found is not None and hit != found):
                        broken = True
                        if hit is not None and found is not None:
                            disagreed += 1
                        break
                    found = hit
                if broken or found is None:
                    missed += 1
                    continue
                rider_rows.append(f"{action_set}\t{action}\t{weapon}\t{found[0]}\t{found[1]}\n")
    model_rows = []
    model_missed = 0
    seen_model = set()
    for part in mounts:
        if part[3] == "-1" or part[3] in seen_model:
            continue
        row = by_id.get(part[3])
        if row is None:
            continue
        seen_model.add(part[3])
        action_set = integer_cell(row[20])
        if action_set is None or action_set < 0:
            continue
        main = skeleton_of.get(part[3], "")
        links = link_cache.get(row[1], {})
        for action, base in ACTIONS.items():
            hit = clip_of(index, lines, names, skills, cache, main, links, action_set, base,
                          WEAPON_COLUMNS["none"])
            if hit is None:
                model_missed += 1
                continue
            model_rows.append(f"{part[3]}\t{action}\t{hit[0]}\t{hit[1]}\n")
    skeletons = [f"{model_id}\t{skeleton_of[model_id]}\n" for model_id in sorted(skeleton_of, key=int)]
    note = (
        "# source: liên kết skeleton trong .mesh của CharModelEx mà CharMount trỏ tới\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# Không có tệp lưới trùng tên mẫu thì lấy skeleton của Entity đầu tiên có liên kết.\n"
        "# skeleton là tệp .skeleton dưới Model/, rỗng khi không lưới nào khai.\n"
    )
    write(OUT / "ride_skeletons.tsv", note, "model\tskeleton", skeletons)
    anim_note = (
        "# source: ActionSet, ActionSetLine, ActionSetKV; clip trên skeleton người chơi\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# Cùng cột anim_sets.tsv. set là driver_action hoặc passenger_action của CharMount.\n"
    )
    write(OUT / "ride_anims.tsv", anim_note, "set\taction\tweapon\tanim\tclip", rider_rows)
    model_note = (
        "# source: action_set cột 20 của CharModelEx, cột tay không của ActionSetLine,\n"
        "# Animation của Effect/all.skill khi tên KV là skill\n"
        "# tool: TOOLS/content/export_rides.py\n"
        "# Clip của chính thú, khoá (model, action). Thiếu hành động thì không có dòng.\n"
    )
    write(OUT / "ride_model_clips.tsv", model_note, "model\taction\tanim\tclip", model_rows)
    print(f"skeletons {len(skeletons)} rider_clips {len(rider_rows)} missed {missed} "
          f"disagreed {disagreed} model_clips {len(model_rows)} model_missed {model_missed} "
          f"skills {len(skills)}")


def main():
    mounts = data_rows(MOUNTS)
    models = data_rows(MODELS)
    offsets = data_rows(OFFSETS)
    speeds = mount_speeds(data_rows(EXTERIOR))
    OUT.mkdir(parents=True, exist_ok=True)
    speed_missing = export_rides(mounts, speeds)
    missing = export_models(mounts, models)
    export_offsets(offsets)
    effects = {}
    for part in mounts:
        effects[part[23]] = effects.get(part[23], 0) + 1
    print(
        f"rides {len(mounts)} models_missing {missing} effects {effects} "
        f"speed_known {len(speeds)} speed_missing {speed_missing}"
    )
    samples = (0, 7, 21, 24, 29, 31)
    shown = " ".join(f"{mount_id}={speeds.get(mount_id, 0)}" for mount_id in samples)
    print(f"speed_sample {shown}")
    counts = {}
    for part in mounts:
        mount_id = integer_cell(part[0])
        percent = speeds.get(mount_id, 0)
        counts[percent] = counts.get(percent, 0) + 1
    listed = " ".join(f"{percent}:{counts[percent]}" for percent in sorted(counts))
    print(f"speed_counts {listed}")
    if len(sys.argv) > 1:
        from export_look import ObjectBook

        book = ObjectBook(str(Path(sys.argv[1])))
        export_locators(book, mounts, models)
        export_effects(book, mounts, models)
        export_entities(book, mounts, models)
        export_chain(Path(sys.argv[1]), mounts, models)


if __name__ == "__main__":
    main()
