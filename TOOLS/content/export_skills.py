# Xuất bảng đòn đánh và tuyệt chiêu của người chơi từ Config nhị phân của client 2026 (_raw), Effect/all.skill
# và cây GLB (_glb), ghi vào <dữ liệu client>/Table/: skill_moves.tsv, skill_actions.tsv, skill_scripts.tsv,
# skill_events.tsv, skill_clips.tsv.
# Chuỗi (cùng chuỗi mà export_look.py dùng cho đứng, chạy): SkillTemplate_V1 cột 18 (danh sách hành động cơ sở
# cách nhau bằng ";": các bước của đòn) -> ActionSet của chính nhân vật (anim_set của player_bodies, khoá
# (set, hành động cơ sở)) -> ActionSetLine (cột theo loại vũ khí) -> ActionSetKV (tên) -> tên là skill của
# Effect/all.skill thì lấy khối skill (Animation, BreakTime, HitTime, ShakeTime và các khối AnimEffect, Ribbon,
# Sound, SceneLight, như WXSkill của ref), không thì chính tên là animation -> tệp chứa animation (skeleton
# chính của giới trước, rồi khối Skeletons của mẫu, như find_clip).
# Quyết định:
# - Id của cột 18 là hành động cơ sở của action set CỦA NHÂN VẬT (162 là "普通攻击01", 163 là "02", 164 là "03"),
#   không phải id của Config/CharActionSet: bảng đó (92 dòng, cột theo loại vũ khí kể cả monster, npc) là bảng
#   chung khác, chỉ trùng vài id đầu nên không dùng (đo bằng chạy: docs/NGHI-NGO.md). Tên khác nhau theo giới
#   (g01_ nữ, m01_ nam), nên bảng hành động ghi theo (race, action, weapon).
# - Chỉ giữ hành động mà action set của cả hai giới có; id -1 và id ngoài action set được đếm và nêu trong báo
#   cáo, không đoán.
# - Khối con của skill giữ nguyên chữ (skill_events.tsv): kind, thời điểm, điểm gắn, tên (effect, material
#   hay âm thanh), vị trí lệch, quay lệch (w x y z) và phần còn lại dạng khoá=giá trị cách nhau bằng "|".
# - Cột 5 của SkillTemplate_V1 là m_nSkillActionType (0 NONE: chọn ngẫu nhiên một bước; 1 CONCATENATION_EX; 2
#   CONCATENATION:轻功 nhảy nối) và cột 34 là m_nSendTime (ms): đọc từ cách Game.exe 2026 dùng hai trường ở
#   Start_MagicSend (0x1405ee920) đối chiếu bố cục _DBC_SKILL_DATA của ref (Common/GameStruct_Skill.h) và dữ
#   liệu (mọi skill nhiều bước đều có cột 5 trong 0..2; cột 34 của đánh thường là 1200).
# - Mốc BreakTime, HitTime, ShakeTime và AttachTime của khối con là PHẦN của độ dài animation (0..1), không phải
#   giây: LogicModel::execute của ref chia TimePosition cho getLength rồi so với chúng; dữ liệu khớp (hit 0.857143
#   là khung 6 trên 7 của clip 0.28 s).
# Cách dùng: python export_skills.py <_raw> <_glb> <thư mục dữ liệu client>
# Mã thoát 1 khi có lỗi dữ liệu.

from __future__ import annotations

import os
import sys

import dbc
from export_look import (ExportError, ObjectBook, Sources, WEAPON_COLUMNS, find_clip, read_action_tables, read_bodies,
                         read_faces, read_skills, read_text_file, write_table)

SKILL_ID, SKILL_NAME, SKILL_TYPE, SKILL_ACTIONS, SKILL_SEND_TIME = 0, 2, 5, 18, 34
WEAPONS = sorted(WEAPON_COLUMNS, key=WEAPON_COLUMNS.get)
EVENT_BLOCKS = ("AnimEffect", "Ribbon", "Sound", "SceneLight")
HEADER_KEYS = ("Animation", "BreakTime", "HitTime", "ShakeTime", "RepeatEffect")
# Khoá của khối con tách thành cột riêng; phần còn lại vào props.
EVENT_COLUMNS = {"AttachTime": "time", "AttachPoint": "point", "EffectTemplateName": "name", "SoundName": "name",
                 "Material": "name", "OffsetPos": "pos", "OffsetRotation": "rot", "Attach": "attach"}


def clean(text: str) -> str:
    if any(char in text for char in "\t\r\n"):
        raise ExportError(f"ô bảng mang tab hay xuống dòng: {text!r}")
    return text


def parse_scripts(text: str) -> dict:
    """Skill -> {"header": {khoá: giá trị}, "events": [(kind, {khoá: giá trị})]}. Khối lồng một cấp như ref."""
    scripts: dict = {}
    current = None
    block = None
    expect_open = None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        if expect_open is not None:
            if line != "{":
                raise ExportError(f"all.skill: sau {expect_open} phải là dấu {{, gặp {line!r}")
            expect_open = None
            continue
        if current is None:
            words = line.split()
            if len(words) == 2 and words[0] == "skill":
                if words[1] in scripts:
                    raise ExportError(f"all.skill: skill {words[1]} định nghĩa hai lần")
                scripts[words[1]] = {"header": {}, "events": []}
                current = words[1]
                expect_open = f"skill {current}"
            continue
        if block is not None:
            if line == "}":
                scripts[current]["events"].append(block)
                block = None
                continue
            words = line.split(None, 1)
            block[1][words[0]] = words[1].strip() if len(words) == 2 else ""
            continue
        if line == "}":
            current = None
        elif line in EVENT_BLOCKS:
            block = (line, {})
            expect_open = line
        else:
            words = line.split(None, 1)
            scripts[current]["header"][words[0]] = words[1].strip() if len(words) == 2 else ""
    if current is not None or block is not None:
        raise ExportError("all.skill: tệp kết thúc giữa một khối")
    return scripts


def read_moves(sources: Sources, known: set, report: dict) -> list:
    """(skill, tên, bước, hành động cơ sở, kiểu hành động, thời gian phát ms) theo skill rồi bước; chỉ hành động mà action set có."""
    table = sources.table("SkillTemplate_V1.txt")
    moves = []
    for row in range(table.rows):
        cell = table.text(row, SKILL_ACTIONS)
        if cell in ("", "0"):
            continue
        for step, part in enumerate(cell.split(";")):
            part = part.strip()
            if not part.lstrip("-").isdigit():
                raise ExportError(f"SkillTemplate_V1 dòng {row}: id hành động {part!r} không phải số")
            action = int(part)
            if action in known:
                moves.append((table.integer(row, SKILL_ID), clean(table.text(row, SKILL_NAME)), step, action,
                              table.integer(row, SKILL_TYPE), table.integer(row, SKILL_SEND_TIME)))
            else:
                report["unknown_actions"][action] = report["unknown_actions"].get(action, 0) + 1
    return moves


def resolve(index: dict, lines: dict, names: dict, key: tuple) -> str | None:
    """Tên ở ActionSetKV cho (action set, hành động cơ sở, cột); None khi loại vũ khí đó không có động tác."""
    action_set, base, column = key
    line_id = index.get((action_set, base))
    if line_id is None or line_id not in lines:
        raise ExportError(f"action set {action_set}: không có hành động {base}")
    kv_id = lines[line_id][column]
    if kv_id <= 0:
        return None
    if kv_id not in names:
        raise ExportError(f"ActionSetKV không có dòng {kv_id}")
    return clean(names[kv_id])


def event_row(script: str, order: int, kind: str, props: dict) -> tuple:
    cells = {"time": "", "point": "", "name": "", "pos": "", "rot": "", "attach": ""}
    rest = []
    for key, value in props.items():
        column = EVENT_COLUMNS.get(key)
        if column is None:
            rest.append(f"{key}={value}")
        else:
            cells[column] = value
    pos = cells["pos"].split()
    rot = cells["rot"].split()
    if cells["pos"] and len(pos) != 3 or cells["rot"] and len(rot) != 4:
        raise ExportError(f"skill {script}: OffsetPos hay OffsetRotation sai dạng ({cells['pos']!r}, {cells['rot']!r})")
    return (script, order, kind, cells["time"], clean(cells["point"]), clean(cells["name"]), *(pos or ["", "", ""]),
            *(rot or ["", "", "", ""]), cells["attach"], clean("|".join(rest)))


def build(sources: Sources, full: dict, skills: dict, bodies: list, report: dict) -> tuple:
    """Từ các hành động cơ sở mà skill dùng ra (hành động theo giới và loại, kịch bản, sự kiện, clip)."""
    index, lines, names = read_action_tables(sources, {body["anim_set"] for body in bodies})
    known = set.intersection(*({base for (aset, base) in index if aset == body["anim_set"]} for body in bodies))
    moves = read_moves(sources, known, report)
    used = sorted({move[3] for move in moves})
    action_rows, scripts = [], set()
    for body in bodies:
        for base in used:
            for weapon, column in WEAPON_COLUMNS.items():
                name = resolve(index, lines, names, (body["anim_set"], base, column))
                if name is None:
                    continue
                action_rows.append((body["race"], base, weapon, name))
                scripts.add(name)
    script_rows, event_rows, animations = [], [], set()
    for name in sorted(scripts):
        script = full.get(name)
        if name in skills and not skills[name]:
            report["no_animation"].append(name)
            continue
        animation = skills.get(name, name)
        header = script["header"] if script else {}
        script_rows.append((name, clean(animation), *(header.get(key, "") for key in HEADER_KEYS[1:])))
        animations.add(animation)
        for order, (kind, props) in enumerate(script["events"] if script else []):
            event_rows.append(event_row(name, order, kind, props))
    clip_rows = []
    for animation in sorted(animations):
        for body in bodies:
            try:
                anim, clip = find_clip(sources, body["skeleton"], body["links"], animation)
            except ExportError as error:
                report["no_clip"].append(f"{body['name']}/{animation}: {error}")
                continue
            clip_rows.append((body["race"], animation, anim, clip))
    kept = {row[0] for row in script_rows}
    action_rows = [row for row in action_rows if row[3] in kept]
    return moves, sorted(set(action_rows)), script_rows, event_rows, sorted(set(clip_rows))


def write_all(target: str, moves: list, actions: list, scripts: list, events: list, clips: list) -> None:
    table_dir = os.path.join(target, "Table")
    source = "Sinh bằng TOOLS/content/export_skills.py từ Config của client; sửa tay sẽ mất ở lượt xuất sau."
    write_table(os.path.join(table_dir, "skill_moves.tsv"),
                ["Các bước của skill, khoá (skill, step): SkillTemplate_V1 cột 18 là danh sách hành động cơ sở.", source,
                 "Đòn đánh thường có ba bước (162, 163, 164); tuyệt chiêu phần lớn một bước.",
                 "kind là m_nSkillActionType (0 chọn ngẫu nhiên một bước, 1 liên hoàn 1 2 2 2 3, 2 liên hoàn 1 2 3), send_ms là m_nSendTime."],
                ["skill", "name", "step", "action", "kind", "send_ms"], moves)
    write_table(os.path.join(table_dir, "skill_actions.tsv"),
                ["Tên skill hay animation của hành động cơ sở theo giới và loại vũ khí, khoá (race, action, weapon).",
                 source, "race 0 nữ, 1 nam; weapon: none, spear, blade, dual_short, short, fan, ring (như anim_sets.tsv)."],
                ["race", "action", "weapon", "script"], actions)
    write_table(os.path.join(table_dir, "skill_scripts.tsv"),
                ["Skill của Effect/all.skill (hay animation trần khi tên không phải skill), khoá script.", source,
                 "animation là tên clip; break_time, hit_time, shake_time, repeat nguyên văn: các số cách nhau bằng dấu cách, mỗi số",
                 "là PHẦN của độ dài clip (0..1), -1 là không có; rỗng khi tên không phải skill của all.skill)."],
                ["script", "animation", "break_time", "hit_time", "shake_time", "repeat"], scripts)
    write_table(os.path.join(table_dir, "skill_events.tsv"),
                ["Khối con của skill, khoá (script, order): kind là AnimEffect, Ribbon, Sound hay SceneLight.", source,
                 "time là AttachTime (phần của độ dài clip, 0..1); point là AttachPoint (tên xương hay tên locator); name là",
                 "EffectTemplateName, Material hay SoundName; pos x y z và rot w x y z là phần lệch; props là khoá=giá trị",
                 "còn lại cách nhau bằng |."],
                ["script", "order", "kind", "time", "point", "name", "px", "py", "pz", "rw", "rx", "ry", "rz", "attach",
                 "props"], events)
    write_table(os.path.join(table_dir, "skill_clips.tsv"),
                ["Tệp chứa clip của animation, khoá (race, animation); race 0 nữ, 1 nam.", source,
                 "anim là tệp .skeleton dưới Model/, clip là tên animation trong tệp đó."],
                ["race", "animation", "anim", "clip"], clips)


def main() -> int:
    if len(sys.argv) != 4:
        print("Cách dùng: python export_skills.py <_raw> <_glb> <dữ liệu client>", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    sources = Sources(raw_root, glb_root)
    report: dict = {"unknown_actions": {}, "no_animation": [], "no_clip": []}
    try:
        text = read_text_file(os.path.join(raw_root, "Effect", "all.skill"))
        full = parse_scripts(text)
        skills = read_skills(os.path.join(raw_root, "Effect", "all.skill"))
        book = ObjectBook(os.path.join(raw_root, "Model", "all.obj"))
        bodies = read_bodies(sources, read_faces(sources, {"face_high_poly": 0}), book)
        moves, actions, scripts, events, clips = build(sources, full, skills, bodies, report)
    except (ExportError, dbc.DbcError, OSError, KeyError) as error:
        print(f"Lỗi: {error}", file=sys.stderr)
        return 1
    write_all(target, moves, actions, scripts, events, clips)
    print(f"skill_moves {len(moves)}, skill_actions {len(actions)}, skill_scripts {len(scripts)}, "
          f"skill_events {len(events)}, skill_clips {len(clips)}")
    unknown = report["unknown_actions"]
    if unknown:
        top = sorted(unknown.items(), key=lambda item: -item[1])[:8]
        print(f"Hành động ngoài action set của người chơi: {sum(unknown.values())} lượt, {len(unknown)} id: {top}")
    for key, label in (("no_animation", "skill không có Animation"), ("no_clip", "animation không tìm thấy tệp theo giới")):
        if report[key]:
            print(f"{label}: {len(report[key])}: {'; '.join(report[key][:6])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
