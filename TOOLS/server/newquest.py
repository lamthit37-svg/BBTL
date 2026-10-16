"""Đọc MisDesc của chuỗi tân thủ client 2026 (edali_newquest_*.lua) thành dòng nhiệm vụ bảng.

Các tệp này chỉ có khối MisDesc, không có OnAccept/OnSubmit. Máy chủ không chạy Lua. Nguồn
`table` chạy nói chuyện, giết quái, học kỹ năng tân thủ và đạt cấp. Nguồn `script` xét
`ready_cond`, mà -1 nghĩa là xong ngay, nên không dùng. Danh bạ client để ô NPC là "-1" và loại 0
(mission_kinds không có mã 0, mã 13 là Đại Lý). Dòng này giữ tên, loại, NPC và tiền đề đúng chữ
trong script, không gọi `fill_from_client`. Mục tiêu chỉ lấy từ script: một `DemandTrueKill`, đúng
một custom "已找到…", một nhóm custom toàn "学习…" khớp bảng thầy trong edali_zhidao_0209, hoặc
đúng một custom "已达等级". MissionTrack không phải nguồn giết quái hay mã vật phẩm. Trân thú,
hỏi đáp, đốt pháo, vào môn phái và tặng nhiều bước ghi `unsupported`.

Lần xuất `lua_extract.py` gọi `append_quests` nên các dòng không mất. Sửa tay TSV vẫn mất.
"""
from __future__ import annotations

import functools
import re
from dataclasses import dataclass, field
from pathlib import Path

import lua_build as BU
import lua_emit as E
import tsv_file
from lua_world import norm_name

PROJECT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = PROJECT / "src" / "client" / "script" / "Config" / "event" / "dali"
PATH_PREFIX = "Config/event/dali/edali_newquest_"
FOUND = "已找到"

# Trần độ rộng cột đang có của mission_quests.tsv (đo 2026-10-16). Vượt trần thì cả tệp căn lại.
LIMITS = {
    "name": 28,
    "detail": 254,
    "continue_text": 70,
    "complete_text": 192,
    "reason": 75,
    "path": 51,
    "guid": 9,
    "how": 15,
    "objective_name": 12,
    "group_name": 12,
    "template": 5,
}

LINE = re.compile(r"^(x(\d+))_g_([A-Za-z0-9_]+)\s*=\s*(.*)$")
TOKEN = re.compile(r"(id|num|name|x|z|tip)\s*=\s*(?:\"([^\"]*)\"|(-?\d+))")
INNER = re.compile(r"\{([^{}]*)\}")
TEACHER = re.compile(r'\{name="([^"]+)"\s*,\s*skill="([^"]+)"\}')
COLOR = re.compile(r"#c[0-9A-Fa-f]{6}|#[A-Za-z]")
LEVEL_MARK = "已达等级"
LEARN_MARK = "学习"
ZHIDAO = "edali_zhidao_0209.lua"


class NewquestError(ValueError):
    """Script tân thủ không đọc được, hoặc đụng script máy chủ đã có."""


@dataclass
class Entry:
    ident: str = ""
    item: int = 0
    num: int = 0
    x: int | None = None
    z: int | None = None
    tip: str = ""


@dataclass
class SkillStep:
    skill: int
    teacher: str
    label: str


@dataclass
class Desc:
    path: str
    script: int = 0
    quest: int = 0
    name: str = ""
    kind: int = 0
    level: int = 0
    elite: int = 0
    pre: int | None = None
    per: int | None = None
    next_script: int = 0
    giver: str = ""
    turn: str = ""
    qigai: str = ""
    scene: int = -1
    pos_x: int | None = None
    pos_z: int | None = None
    sign_x: int | None = None
    sign_z: int | None = None
    sign_tip: str = ""
    money: int | None = None
    bound: int | None = None
    exp: int | None = None
    items: list = field(default_factory=list)
    choices: list = field(default_factory=list)
    kills: list = field(default_factory=list)
    kill_ids: list = field(default_factory=list)
    customs: list = field(default_factory=list)
    info: str = ""
    extra_info: list = field(default_factory=list)
    target: str = ""
    cont: str = ""
    done: str = ""
    status: str = "unsupported"
    reason: str = ""
    talk_npc: str = ""
    skill_steps: list = field(default_factory=list)
    level_need: int = 0
    chain_role: str = ""
    chain_step: int = 0
    notes: list = field(default_factory=list)


def script_dir() -> Path:
    return SCRIPT_DIR


def strip_comment(line: str) -> str:
    """Bỏ chú thích `--` nằm ngoài chuỗi. Chuỗi trong MisDesc không chứa `--`."""
    out: list[str] = []
    quote = ""
    index = 0
    while index < len(line):
        char = line[index]
        if quote:
            out.append(char)
            if char == quote:
                quote = ""
            index += 1
            continue
        if char in "\"'":
            quote = char
            out.append(char)
            index += 1
            continue
        if char == "-" and index + 1 < len(line) and line[index + 1] == "-":
            break
        out.append(char)
        index += 1
    return "".join(out).strip()


def as_int(text: str) -> int | None:
    body = text.strip()
    if re.fullmatch(r"-?\d+", body):
        return int(body)
    return None


def as_text(text: str) -> str | None:
    body = text.strip()
    if len(body) >= 2 and body[0] == body[-1] and body[0] in "\"'":
        return body[1:-1]
    return None


def entry_of(body: str) -> Entry | None:
    found = TOKEN.findall(body)
    if not found:
        return None
    entry = Entry()
    for key, quoted, number in found:
        if key == "id" and quoted:
            entry.ident = quoted
        elif key == "id" and number:
            entry.item = int(number)
        elif key == "num" and number:
            entry.num = int(number)
        elif key == "name" and quoted:
            entry.ident = quoted
        elif key == "x" and number:
            entry.x = int(number)
        elif key == "z" and number:
            entry.z = int(number)
        elif key == "tip" and quoted:
            entry.tip = quoted
    return entry


def entries_of(raw: str) -> list:
    rows = []
    for body in INNER.findall(raw):
        entry = entry_of(body)
        if entry is not None:
            rows.append(entry)
    return rows


def region_of(text: str) -> str:
    begin = text.find("--MisDescBegin")
    end = text.find("--MisDescEnd")
    if begin >= 0 and end > begin:
        return text[begin:end]
    return text


def fields_of(text: str, desc: Desc) -> dict:
    """Ánh xạ tên trường MisDesc sang vế phải. Trường lặp giữ lần gán đầu."""
    fields: dict[str, str] = {}
    prefix = 0
    for raw_line in region_of(text).splitlines():
        line = strip_comment(raw_line)
        match = LINE.match(line)
        if match is None:
            continue
        prefix = int(match.group(2))
        name = match.group(3)
        if name in fields:
            desc.notes.append(f"trường {name} gán hai lần, giữ lần đầu")
            continue
        fields[name] = match.group(4).strip()
    if prefix and "ScriptId" in fields:
        declared = as_int(fields["ScriptId"])
        if declared is not None and declared != prefix:
            desc.notes.append(f"tiền tố x{prefix} khác g_ScriptId {declared}")
    return fields


def optional_int(fields: dict, key: str) -> int | None:
    if key not in fields:
        return None
    return as_int(fields[key])


def text_field(fields: dict, key: str) -> str:
    if key not in fields:
        return ""
    return as_text(fields[key]) or ""


def strip_color(text: str) -> str:
    """Bỏ #G và #cRRGGBB. Khoá #{...} giữ nguyên vì không phải tên kỹ năng."""
    return COLOR.sub("", text)


@functools.lru_cache(maxsize=1)
def teacher_of_label() -> dict:
    """Nhãn kỹ năng -> tên thầy, lấy từ x210209_g_XinShouJiNeng. Nhãn hai thầy thì bỏ."""
    path = script_dir() / ZHIDAO
    if not path.is_file():
        raise NewquestError(f"thiếu bảng thầy {path}")
    found: dict[str, set[str]] = {}
    for match in TEACHER.finditer(path.read_text(encoding="utf-8")):
        label = strip_color(match.group(2))
        if not label:
            continue
        found.setdefault(label, set()).add(match.group(1))
    return {label: names.copy().pop() for label, names in found.items() if len(names) == 1}


@functools.lru_cache(maxsize=1)
def skill_of_label() -> dict:
    """Nhãn '学习'+tên -> skill_id nhỏ nhất có icon FightSkillXinShou."""
    path = PROJECT / "dev" / "server" / "tables" / "shared" / "skills.tsv"
    if not path.is_file():
        raise NewquestError(f"thiếu bảng kỹ năng {path}")
    table = tsv_file.read_table(path)
    id_at = table.columns.index("skill_id")
    name_at = table.columns.index("skill_name")
    icon_at = table.columns.index("icon_name")
    best: dict[str, int] = {}
    for row in table.rows:
        if not row[icon_at].startswith("FightSkillXinShou"):
            continue
        label = LEARN_MARK + row[name_at]
        skill_id = int(row[id_at])
        current = best.get(label)
        if current is None or skill_id < current:
            best[label] = skill_id
    return best


def parse_text(text: str, path: str) -> Desc:
    desc = Desc(path=path)
    fields = fields_of(text, desc)
    script = optional_int(fields, "ScriptId")
    quest = optional_int(fields, "MissionId")
    if script is None or quest is None:
        raise NewquestError(f"{path}: thiếu g_ScriptId hoặc g_MissionId")
    desc.script = script
    desc.quest = quest
    desc.name = text_field(fields, "MissionName")
    desc.kind = optional_int(fields, "MissionKind") or 0
    desc.level = optional_int(fields, "MissionLevel") or 0
    desc.elite = optional_int(fields, "IfMissionElite") or 0
    desc.pre = optional_int(fields, "MissionIdPre")
    desc.per = optional_int(fields, "MissionIdPer")
    desc.next_script = optional_int(fields, "NextScriptId") or 0
    desc.giver = text_field(fields, "Name")
    desc.turn = text_field(fields, "AccomplishNPC_Name")
    accept = text_field(fields, "AcceptNPC_Name")
    if accept and accept != desc.giver:
        desc.notes.append(f"g_Name là {desc.giver}, NPC giao là g_AcceptNPC_Name {accept}")
        desc.giver = accept
    desc.qigai = text_field(fields, "QigaiName")
    desc.scene = optional_int(fields, "SceneID")
    if desc.scene is None:
        desc.scene = -1
    desc.pos_x = optional_int(fields, "Position_X")
    desc.pos_z = optional_int(fields, "Position_Z")
    desc.money = optional_int(fields, "MoneyBonus")
    desc.bound = optional_int(fields, "MoneyJZBonus")
    if "ExpBonus" in fields:
        desc.exp = optional_int(fields, "ExpBonus")
    elif "exp" in fields:
        desc.exp = optional_int(fields, "exp")
        desc.notes.append("kinh nghiệm nằm ở g_exp, không phải g_ExpBonus")
    desc.info = text_field(fields, "MissionInfo")
    for key, raw in fields.items():
        if not key.startswith("MissionInfo") or key == "MissionInfo":
            continue
        extra = as_text(raw) or ""
        if extra:
            desc.extra_info.append(f"{key}: {extra}")
    if desc.extra_info:
        desc.notes.append("script có thêm MissionInfo1 trở đi; TSV chỉ giữ g_MissionInfo")
    desc.target = text_field(fields, "MissionTarget")
    desc.cont = text_field(fields, "ContinueInfo")
    desc.done = text_field(fields, "MissionComplete")
    desc.items = entries_of(fields.get("ItemBonus", ""))
    desc.choices = entries_of(fields.get("RadioItemBonus", ""))
    desc.kills = entries_of(fields.get("DemandTrueKill", ""))
    desc.kill_ids = entries_of(fields.get("DemandKill", ""))
    desc.customs = entries_of(fields.get("Custom", ""))
    sign = entry_of(fields.get("SignPost", ""))
    if sign is not None:
        desc.sign_x = sign.x
        desc.sign_z = sign.z
        desc.sign_tip = sign.tip
    if desc.per is not None:
        desc.notes.append("script ghi g_MissionIdPer, không đưa vào tiền đề")
    classify(desc)
    return desc


def classify(desc: Desc) -> None:
    """Chọn bộ chạy hoặc lý do không chạy. Không đổi số thưởng."""
    kills = [item for item in desc.kills if item.ident]
    if kills and desc.customs:
        desc.status = "unsupported"
        desc.reason = fit_reason("vừa giết quái vừa việc khác", custom_text(desc))
        return
    if len(kills) > 1:
        desc.status = "unsupported"
        desc.reason = fit_reason("nhiều nhóm quái", "; ".join(item.ident for item in kills))
        return
    if len(kills) == 1:
        kill = kills[0]
        if kill.num <= 0:
            desc.status = "unsupported"
            desc.reason = "DemandTrueKill thiếu số lượng"
            return
        desc.status = "ok"
        desc.reason = ""
        note_kill_id(desc, kill)
        return
    if len(desc.customs) == 1 and desc.customs[0].ident.startswith(FOUND):
        npc = desc.customs[0].ident[len(FOUND):]
        if not npc:
            desc.status = "unsupported"
            desc.reason = "custom đã tìm nhưng không có tên"
            return
        desc.talk_npc = npc
        desc.status = "ok"
        desc.reason = ""
        if desc.turn and desc.turn != npc:
            desc.notes.append(f"custom tìm {npc}, NPC trả là {desc.turn}")
        return
    if classify_level(desc):
        return
    if classify_learn(desc):
        return
    desc.status = "unsupported"
    desc.reason = fit_reason("không có bộ chạy", custom_text(desc))


def named_customs(desc: Desc) -> list:
    return [item for item in desc.customs if item.ident]


def classify_level(desc: Desc) -> bool:
    """True khi custom duy nhất là 已达等级 và trạng thái đã gán."""
    customs = named_customs(desc)
    if len(customs) != 1 or customs[0].ident != LEVEL_MARK:
        return False
    if customs[0].num <= 0:
        desc.status = "unsupported"
        desc.reason = "đã đạt cấp nhưng thiếu số cấp"
        return True
    desc.level_need = customs[0].num
    desc.status = "ok"
    desc.reason = ""
    desc.notes.append("cấp cần là num của 已达等级, không phải g_MissionLevel")
    return True


def classify_learn(desc: Desc) -> bool:
    """True khi mọi custom bắt đầu bằng 学习. Một nhãn không khớp thì cả nhiệm vụ không chạy."""
    customs = named_customs(desc)
    if not customs or not all(item.ident.startswith(LEARN_MARK) for item in customs):
        return False
    teachers = teacher_of_label()
    skills = skill_of_label()
    steps = []
    for item in customs:
        label = strip_color(item.ident)
        teacher = teachers.get(label, "")
        skill = skills.get(label, 0)
        if not teacher or skill <= 0:
            desc.skill_steps = []
            desc.status = "unsupported"
            desc.reason = fit_reason("không khớp kỹ năng tân thủ", item.ident)
            return True
        steps.append(SkillStep(skill, teacher, label))
    desc.skill_steps = steps
    desc.status = "ok"
    desc.reason = ""
    desc.notes.append("học khi mở hội thoại với thầy; MisDesc không có hàm học")
    return True


def custom_text(desc: Desc) -> str:
    return "; ".join(item.ident for item in desc.customs if item.ident)


def fit_reason(label: str, detail: str) -> str:
    """Lý do vừa đủ cột reason. Phần custom đầy đủ vẫn nằm ở Desc.customs."""
    if not detail:
        return label
    full = f"{label}: {detail}"
    if tsv_file.display_width(full) <= LIMITS["reason"]:
        return full
    return label


def note_kill_id(desc: Desc, kill: Entry) -> None:
    if len(desc.kill_ids) != 1:
        return
    demand = desc.kill_ids[0]
    if demand.num and demand.num != kill.num:
        desc.notes.append(f"DemandKill num {demand.num} khác TrueKill {kill.num}")
    if demand.item:
        desc.notes.append(f"DemandKill id {demand.item} là mẫu quái, đếm theo tên {kill.ident}")


def clip(desc: Desc, text: str, column: str) -> str:
    if tsv_file.display_width(text) <= LIMITS[column]:
        return text
    desc.notes.append(f"{column} dài hơn trần {LIMITS[column]}, không ghi vào TSV")
    return ""


def positive_pre(desc: Desc) -> list:
    """Tiền đề là g_MissionIdPre dương. 0, thiếu trường, và g_MissionIdPer không tính."""
    if desc.pre is None or desc.pre <= 0:
        return []
    return [desc.pre]


def add_reward(out: BU.QuestOut, group: str, kind: str, ref: int, count: int) -> None:
    if count <= 0:
        return
    out.rewards.append(BU.RewardOut(group, kind, ref, count, -1))


def add_link(desc: Desc, out: BU.QuestOut, world: object, role: str, name: str) -> int:
    if not name or name == "-1":
        return 0
    if world is None:
        out.npc_links.append((role, 0, desc.scene, name, "script"))
        return 0
    guid = BU.link_npc(world, out, role, desc.scene, name, 0)
    if tsv_file.display_width(str(guid)) <= LIMITS["guid"]:
        return guid
    role_name, _guid, scene, linked, _how = out.npc_links[-1]
    out.npc_links[-1] = (role_name, 0, scene, linked, "name")
    desc.notes.append(f"guid {guid} của {name} rộng hơn cột, khớp bằng tên")
    return 0


def chosen_kill(desc: Desc) -> Entry | None:
    named = [item for item in desc.kills if item.ident]
    if desc.status != "ok" or desc.talk_npc or len(named) != 1:
        return None
    return named[0]


def add_skill_objectives(desc: Desc, out: BU.QuestOut, world: object) -> bool:
    if desc.status != "ok" or not desc.skill_steps:
        return False
    for index, step in enumerate(desc.skill_steps):
        guid = add_link(desc, out, world, "target", step.teacher)
        out.objectives.append(BU.Obj("skill", guid, 1, step.skill, 0, desc.scene, 0, step.teacher, index))
    return True


def add_level_objective(desc: Desc, out: BU.QuestOut) -> bool:
    if desc.status != "ok" or desc.level_need <= 0:
        return False
    out.objectives.append(BU.Obj("level", 0, desc.level_need, 0, 0, 0, 0, "", 0))
    return True


def add_objective(desc: Desc, out: BU.QuestOut, world: object, regs: BU.Registries) -> None:
    if add_skill_objectives(desc, out, world):
        return
    if add_level_objective(desc, out):
        return
    if desc.talk_npc and desc.status == "ok":
        guid = add_link(desc, out, world, "target", desc.talk_npc)
        out.objectives.append(BU.Obj("talk", guid, 1, 0, 0, desc.scene, 0, desc.talk_npc, 0))
        return
    kill = chosen_kill(desc)
    if kill is None:
        return
    group = BU.name_group(regs, kill.ident)
    out.objectives.append(BU.Obj("kill", group, kill.num, 0, 0, 0, 0, kill.ident, 0))


def build_out(desc: Desc, world: object, regs: BU.Registries, quest_of: dict) -> BU.QuestOut:
    """Một Desc thành QuestOut. `quest_of` là script kế -> id nhiệm vụ trong cùng chuỗi."""
    name = clip(desc, desc.name, "name")
    if not name:
        raise NewquestError(f"{desc.path}: tên nhiệm vụ không vừa cột name")
    out = BU.QuestOut(desc.script, desc.quest, "table", path=desc.path)
    out.kind = desc.kind
    out.level = desc.level
    out.elite = desc.elite
    out.repeat = "once"
    out.name = name
    out.detail = clip(desc, desc.info, "detail")
    out.cont = clip(desc, desc.cont, "continue_text")
    out.done = clip(desc, desc.done, "complete_text")
    out.accept_scene = desc.scene
    out.turn_scene = desc.scene
    out.status = desc.status
    out.reason = desc.reason
    out.in_client = 1 if world is None or desc.quest in world.client_quests else 0
    out.prereqs = positive_pre(desc)
    out.next_script = desc.next_script if desc.next_script in quest_of else 0
    out.next_quest = quest_of.get(desc.next_script, -1)
    out.accept_guid = add_link(desc, out, world, "give", desc.giver)
    out.turn_guid = add_link(desc, out, world, "turn", desc.turn)
    add_objective(desc, out, world, regs)
    add_reward(out, "fixed", "money", 0, desc.money or 0)
    add_reward(out, "fixed", "bound_money", 0, desc.bound or 0)
    add_reward(out, "fixed", "exp", 0, desc.exp or 0)
    for item in desc.items:
        add_reward(out, "fixed", "item", item.item, item.num)
    for item in desc.choices:
        add_reward(out, "choice", "item", item.item, item.num)
    check_widths(desc, out)
    return out


def check_widths(desc: Desc, out: BU.QuestOut) -> None:
    path_width = tsv_file.display_width(out.path)
    if path_width > LIMITS["path"]:
        raise NewquestError(f"{desc.path}: đường dài {path_width}")
    reason_width = tsv_file.display_width(out.reason)
    if reason_width > LIMITS["reason"]:
        raise NewquestError(f"{desc.path}: lý do dài {reason_width}")
    for objective in out.objectives:
        width = tsv_file.display_width(objective.name)
        if width > LIMITS["objective_name"]:
            raise NewquestError(f"{desc.path}: tên mục tiêu dài {width}: {objective.name}")
    for _role, _guid, _scene, name, how in out.npc_links:
        if tsv_file.display_width(how) > LIMITS["how"]:
            raise NewquestError(f"{desc.path}: cách nối NPC dài: {how}")
        if tsv_file.display_width(name) > 22:
            raise NewquestError(f"{desc.path}: tên NPC dài: {name}")


def read_file(path: Path, root: Path) -> Desc:
    relative = path.relative_to(root).as_posix()
    return parse_text(path.read_text(encoding="utf-8"), relative)


def read_all(directory: Path | None = None) -> list:
    folder = directory or script_dir()
    # dali -> event -> Config -> script. Đường trong bảng là Config/event/dali/...
    root = folder.parents[2]
    paths = sorted(folder.glob("edali_newquest_*.lua"))
    descs = [read_file(path, root) for path in paths]
    if len(descs) != len({item.script for item in descs}):
        raise NewquestError("trùng g_ScriptId trong edali_newquest")
    if len(descs) != len({item.quest for item in descs}):
        raise NewquestError("trùng g_MissionId trong edali_newquest")
    order_chains(descs)
    return descs


def order_chains(descs: list) -> None:
    """Đánh số chuỗi theo g_NextScriptId. Nhánh là script không ai trỏ tới, ngoài đầu 1400."""
    by_script = {item.script: item for item in descs}
    pointed = {item.next_script for item in descs if item.next_script in by_script}
    roots = [item for item in descs if item.script not in pointed]
    main_root = next((item for item in roots if item.quest == 1400), None)
    if main_root is None:
        raise NewquestError("không thấy nhiệm vụ 1400 làm đầu chuỗi")
    main = walk_open(main_root, by_script, set())
    occupied = {item.script for item in main}
    for step, item in enumerate(main, start=1):
        item.chain_role = "chính"
        item.chain_step = step
    side_step = 0
    for root in roots:
        if root.script in occupied:
            continue
        for item in walk_open(root, by_script, occupied):
            side_step += 1
            item.chain_role = "nhánh"
            item.chain_step = side_step
            occupied.add(item.script)


def walk_open(start: Desc, by_script: dict, occupied: set) -> list:
    order = []
    seen = set()
    at: Desc | None = start
    while at is not None and at.script not in occupied:
        if at.script in seen:
            at.notes.append("vòng g_NextScriptId")
            break
        seen.add(at.script)
        order.append(at)
        nxt = by_script.get(at.next_script)
        at = nxt
    return order


def quest_of_scripts(descs: list) -> dict:
    return {item.script: item.quest for item in descs}


def outs_of(descs: list, world: object, regs: BU.Registries | None = None) -> list:
    regs = regs or BU.Registries(E.Strings(set()))
    quest_of = quest_of_scripts(descs)
    return [build_out(item, world, regs, quest_of) for item in descs]


def kill_names(descs: list) -> list:
    names = []
    for desc in descs:
        kill = chosen_kill(desc)
        if kill is not None:
            names.append(kill.ident)
    return names


def group_rows_for(descs: list, world: object, regs: BU.Registries) -> list:
    """Dòng mission_name_groups cho quái của nhiệm vụ giết chạy được. Thiếu mẫu thì ghi -1."""
    rows = []
    seen = set()
    for name in kill_names(descs):
        group = BU.name_group(regs, name)
        templates = world.monster_by_name.get(norm_name(name), []) if world is not None else []
        picked = templates or [-1]
        for template in picked:
            width = tsv_file.display_width(str(template))
            if width > LIMITS["template"]:
                raise NewquestError(f"mẫu {template} của {name} rộng hơn cột template")
            key = (group, template)
            if key in seen:
                continue
            seen.add(key)
            rows.append((group, template, name))
    return rows


def append_quests(ctx: object) -> None:
    """Thêm chuỗi tân thủ vào lần trích. Trùng script với Lua 14 môn thì dừng, không ghi đè."""
    descs = read_all()
    owned = {quest.script for quest in ctx.quests}
    clash = sorted(item.script for item in descs if item.script in owned)
    if clash:
        raise NewquestError(f"script tân thủ đã có trong lần trích: {clash}")
    regs = ctx.regs
    quest_of = quest_of_scripts(descs)
    for desc in descs:
        ctx.quests.append(build_out(desc, ctx.world, regs, quest_of))
    # name_group trong build_out đã đăng ký nhóm; group_rows của lần trích sẽ ghi mẫu quái.
