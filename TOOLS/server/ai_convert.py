"""Đổi kịch bản AI quái (Public/Data/AIScript/scriptN.ai) của XJL7457 thành bảng luật có kiểu.

    python TOOLS/server/ai_convert.py <gốc dev/server> <gốc tlbb của XJL7457> [--check]

Ghi hai bảng vào <gốc dev/server>/tables/server:
  monster_ai_rules.tsv       mỗi dòng một nguyên tử của một luật: điều kiện (`if`, nối bằng VÀ) hoặc hành động
                             (`do`), kèm tham số. Đầu luật (ưu tiên, số lần) lặp ở mọi dòng của luật.
  monster_ai_rule_files.tsv  mỗi dòng một tệp .ai: số luật, tên trong AIScript.dat, có trong bảng 0859602 không.

Ngữ nghĩa theo AIScript.cpp, AIScriptFunction.cpp và AIScriptDef.h của máy chủ 2008
(thư mục Server/GameServer/Server/AI của cây `_ref/server`):
  * một tệp có năm đoạn [common] [skill] [beskill] [damage] [dead]; dòng luật `N:if(...){...};chú thích`;
    chỉ số luật (rule_index) tăng theo từng dòng có dấu `:`, kể cả dòng hỏng, vì mã gốc dùng nó làm chỗ
    đếm số lần của luật;
  * `AIS_SetTimes(n)` là số lần luật được chạy (-1 vô hạn; vắng thì 0, tức luật không bao giờ chạy);
    `AIS_SetPRI(n)` là ưu tiên (vắng thì -1); danh sách luật xếp ưu tiên giảm dần, bằng nhau giữ thứ tự tệp;
  * mỗi lần xử lý một đoạn chỉ luật đầu tiên có điều kiện đúng (và còn lượt) được chạy, rồi dừng;
  * [common]: luật có điều kiện `get_ai_state` chỉ chạy ở trạng thái đó, luật khác chạy ở các trạng thái
    0..4 (SRETURN loại trừ);
  * điều kiện nối bằng `&`; `|` và ngoặc nhóm không dùng trong dữ liệu (tệp có thì báo, không đưa vào bảng).
Hàm không có trong g_AISFuncTable của mã 2008 (do bản private thêm) vẫn vào bảng và được báo.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import scene_xref
import tsv_file

TOOL = "ai_convert.py"
HELP = __doc__ or ""
SECTIONS = ("common", "skill", "beskill", "damage", "dead")
RULE_LINE = re.compile(r"^(\d+):(.*)$")
CALL = re.compile(r"^(AIS_[A-Za-z]+)\(([^()]*)\)$")
COMPARE = re.compile(r"^(AIS_[A-Za-z]+\([^()]*\)|-?\d+)(<=|>=|!=|=|<|>)(-?\w+)$")
OPS = {"=": "eq", "!=": "ne", "<": "lt", "<=": "le", ">": "gt", ">=": "ge"}
# g_AISMacroTable với giá trị của ENUM_AISTATE (AIScriptDef.h) và ENUM_STATE (State.h).
MACROS = {
    "SIDLE": 0, "SAPPROACH": 3, "SRETURN": 5, "SATTACK": 6, "SPATROL": 7, "SFLEE": 8, "SFOLLOW": 10,
    "SKILLSECTION": 13, "ONBESKILLSECTION": 14, "ONDAMAGESECTION": 15, "ONDEADSECTION": 16,
}  # fmt: skip
FUNCTIONS_2008 = {
    "AIS_GetBuffState": "get_buff_state", "AIS_GetAIState": "get_ai_state", "AIS_GetHP": "get_hp",
    "AIS_GetMP": "get_mp", "AIS_Rand": "rand", "AIS_GetEBuffState": "get_enemy_buff_state",
    "AIS_GetEMP": "get_enemy_mp", "AIS_GetEHP": "get_enemy_hp", "AIS_GetEMenPai": "get_enemy_sect",
    "AIS_GetELevel": "get_enemy_level", "AIS_IsCanSpeak": "is_can_speak", "AIS_IsHasEnemy": "is_has_enemy",
    "AIS_GetESex": "get_enemy_sex", "AIS_GetCamp": "get_camp", "AIS_GetPK": "get_pk",
    "AIS_GetETeamNum": "get_enemy_team_num", "AIS_IsEHasSpecialItem": "is_enemy_has_special_item",
    "AIS_GetSingleDamage": "get_single_damage", "AIS_GetEnemyNum": "get_enemy_num", "AIS_IsBoss": "is_boss",
    "AIS_BeSkill": "be_skill", "AIS_ToFlee": "to_flee", "AIS_IsCanSkill": "is_can_skill",
    "AIS_ToSkill": "to_skill", "AIS_ToSummon": "to_summon", "AIS_ToLongAttack": "to_long_attack",
    "AIS_ToFollow": "to_follow", "AIS_ToSpeak": "to_speak", "AIS_SetTimes": "set_times",
    "AIS_SetPRI": "set_priority", "AIS_ToAssistTeammate": "to_assist_teammate",
}  # fmt: skip
# Hàm bản private thêm, mã 2008 không có (tên suy ra từ chữ, ngữ nghĩa chưa có mã để đối chiếu).
FUNCTIONS_ADDED = {
    "AIS_CallOtherMonsterByGroup": "call_other_monster_by_group",
    "AIS_CallOtherMonsterByTeam": "call_other_monster_by_team",
    "AIS_SetBaseAIType": "set_base_ai_type",
    "AIS_SetPatrolID": "set_patrol_id",
    "AIS_StartPatrol": "start_patrol",
}
RULE_COLUMNS = (
    "ai_id", "rule_index", "section", "priority", "times", "part", "seq", "function", "op", "value",
    "arg_0", "arg_1", "arg_2", "skill_id", "value_name",
)  # fmt: skip
RULE_TYPES = (
    "int", "int", "text", "int", "int", "text", "int", "text", "text", "int", "int", "int", "int", "int", "text",
)  # fmt: skip
SKILL_FUNCTIONS = frozenset({"is_can_skill", "to_skill", "be_skill"})  # arg_0 là id kỹ năng
FILE_COLUMNS = ("ai_id", "file", "title", "dat_name", "rules", "in_dat", "in_0859602_index")
FILE_TYPES = ("int", "text", "text", "text", "int", "int", "int")
NO_ARG = -1  # Atom của mã gốc khởi tạo mọi tham số bằng -1


@dataclass
class Atom:
    function: str
    args: tuple[int, int, int] = (NO_ARG, NO_ARG, NO_ARG)
    op: str = ""
    value: int = 0
    value_name: str = ""


@dataclass
class Rule:
    index: int
    section: str
    priority: int = NO_ARG
    times: int = 0
    conditions: list[Atom] = field(default_factory=list)
    actions: list[Atom] = field(default_factory=list)


@dataclass
class Issue:
    ai_id: int
    line: int
    kind: str
    text: str


def parse_call(text: str) -> Atom | str:
    """`AIS_X(a,b,c)` thành Atom, hoặc câu lỗi."""
    found = CALL.match(text)
    if found is None:
        return f"không phải lời gọi hàm: {text}"
    name = found.group(1)
    function = FUNCTIONS_2008.get(name) or FUNCTIONS_ADDED.get(name)
    if function is None:
        return f"hàm lạ: {name}"
    parts = [part.strip() for part in found.group(2).split(",")] if found.group(2).strip() else []
    if len(parts) > 3 or not all(re.fullmatch(r"-?\d+", part) for part in parts):
        return f"tham số không phải tối đa ba số: {text}"
    numbers = [int(part) for part in parts]
    numbers += [NO_ARG] * (3 - len(numbers))
    return Atom(function, (numbers[0], numbers[1], numbers[2]))


def parse_value(text: str) -> tuple[int, str] | None:
    if text in MACROS:
        return MACROS[text], text
    if re.fullmatch(r"-?\d+", text):
        return int(text), ""
    return None


def parse_condition(text: str) -> Atom | str:
    found = COMPARE.match(text)
    if found is None:
        return f"điều kiện không đúng dạng hàm toán-tử giá trị: {text}"
    value = parse_value(found.group(3))
    if value is None:
        return f"giá trị lạ: {found.group(3)}"
    left = found.group(1)
    if left.startswith("AIS_"):
        atom = parse_call(left)
    else:
        # `1=1` ở script100: mã 2008 gọi con trỏ hàm rỗng. Hiểu là hằng, tác giả rõ ràng muốn "luôn đúng".
        atom = Atom("const", (int(left), NO_ARG, NO_ARG))
    if isinstance(atom, str):
        return atom
    atom.op = OPS[found.group(2)]
    atom.value, atom.value_name = value
    return atom


def split_rule(body: str) -> tuple[str, str] | str:
    """(điều kiện, hành động) của phần sau dấu `:`; chú thích sau `}` bị bỏ như mã gốc."""
    if not body.startswith("if(") or "{" not in body or "}" not in body:
        return 'luật không có dạng if(...){...} (mã 2008 hiểu dấu "(" thay "{" là ngoặc điều kiện)'
    head, _brace, rest = body.partition("{")
    if not head.endswith(")"):
        return "thiếu dấu đóng ngoặc điều kiện"
    return head[3:-1], rest.split("}", 1)[0]


def parse_rule(index: int, section: str, body: str) -> Rule | str:
    pieces = split_rule(body)
    if isinstance(pieces, str):
        return pieces
    condition_text, action_text = pieces
    if "|" in condition_text:
        return "điều kiện dùng | (hoặc), bảng chỉ có VÀ"
    rule = Rule(index, section)
    for text in (part.strip() for part in condition_text.split("&")):
        atom = parse_condition(text)
        if isinstance(atom, str):
            return atom
        rule.conditions.append(atom)
    for text in (part.strip() for part in action_text.split(";") if part.strip()):
        atom = parse_call(text)
        if isinstance(atom, str):
            return atom
        _place_action(rule, atom)
    return rule


def _place_action(rule: Rule, atom: Atom) -> None:
    """SetTimes và SetPRI là đầu luật (mã gốc rút chúng ra khỏi danh sách hành động)."""
    if atom.function == "set_times":
        rule.times = atom.args[0]
    elif atom.function == "set_priority":
        rule.priority = atom.args[0]
    else:
        rule.actions.append(atom)


def parse_script(ai_id: int, text: str) -> tuple[list[Rule], list[Issue], str]:
    """Các luật hợp lệ, các dòng không đưa được vào bảng, và dòng chú thích đầu tệp."""
    rules: list[Rule] = []
    issues: list[Issue] = []
    section = ""
    index = 0
    title = ""
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        if line.startswith(";"):
            title = title or line[1:].strip()
            continue
        marker = re.fullmatch(r"\[(\w+)\]", line)
        if marker:
            section = marker.group(1)
            continue
        found = RULE_LINE.match(line)
        if found is None or section not in SECTIONS:
            continue
        result = parse_rule(index, section, found.group(2))
        if isinstance(result, str):
            issues.append(Issue(ai_id, number, "unrepresentable", f"{result} :: {line[:90]}"))
        else:
            rules.append(result)
        index += 1
    return rules, issues, title


def rule_rows(ai_id: int, rule: Rule) -> list[tuple[str, ...]]:
    rows = []
    head = (str(ai_id), str(rule.index), rule.section, str(rule.priority), str(rule.times))
    for part, atoms in (("if", rule.conditions), ("do", rule.actions)):
        for seq, atom in enumerate(atoms):
            skill = atom.args[0] if atom.function in SKILL_FUNCTIONS else NO_ARG
            args = (str(arg) for arg in atom.args)
            tail = (atom.function, atom.op, str(atom.value), *args, str(skill), atom.value_name)
            rows.append((*head, part, str(seq), *tail))
    return rows


def read_dat(text: str) -> dict[int, str]:
    """AIScript.dat: `id=scriptN.ai =tên`. Trả id -> tên."""
    names = {}
    for line in text.splitlines():
        found = re.match(r"^;?(\d+)=([^=\s]+)\s*=?(.*)$", line.strip())
        if found:
            names[int(found.group(1))] = found.group(3).strip()
    return names


def script_files(folder: Path) -> list[tuple[int, Path]]:
    found = []
    for entry in folder.iterdir():
        match = re.fullmatch(r"script(\d+)\.ai", entry.name)
        if match:
            found.append((int(match.group(1)), entry))
    return sorted(found)


def known_ids(server_root: Path) -> set[int]:
    path = server_root / "tables" / "server" / "monster_ai_scripts.tsv"
    return {int(row[0]) for row in tsv_file.read_table(path).rows} if path.is_file() else set()


def convert(server_root: Path, xjl_root: Path) -> tuple[list, list, list[Issue], dict[str, int]]:
    base = xjl_root / "Public" / "Data"
    names = read_dat(scene_xref.decode_text((base / "AIScript.dat").read_bytes()))
    legacy = known_ids(server_root)
    rule_out: list[tuple[str, ...]] = []
    file_out: list[tuple[str, ...]] = []
    issues: list[Issue] = []
    stats = {"rules": 0, "conditions": 0, "actions": 0}
    for ai_id, path in script_files(base / "AIScript"):
        rules, found, title = parse_script(ai_id, scene_xref.decode_text(path.read_bytes()))
        issues.extend(found)
        for rule in rules:
            rule_out.extend(rule_rows(ai_id, rule))
            stats["conditions"] += len(rule.conditions)
            stats["actions"] += len(rule.actions)
        stats["rules"] += len(rules)
        in_dat = ai_id in names
        file_out.append(
            (str(ai_id), path.name, title, names.get(ai_id, ""), str(len(rules)), str(int(in_dat)),
             str(int(ai_id in legacy)))  # fmt: skip
        )
    return rule_out, file_out, issues, stats


def added_functions(rows: list[tuple[str, ...]]) -> dict[str, int]:
    added = set(FUNCTIONS_ADDED.values())
    counts: dict[str, int] = {}
    for row in rows:
        if row[7] in added:
            counts[row[7]] = counts.get(row[7], 0) + 1
    return dict(sorted(counts.items()))


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    positional = [arg for arg in args if not arg.startswith("--")]
    if len(positional) != 2:
        print("ai_convert.py:1: cần hai tham số: gốc dev/server và gốc XJL7457")
        return 1
    server_root = Path(positional[0])
    rules, files, issues, stats = convert(server_root, Path(positional[1]))
    if "--check" not in args:
        out = server_root / "tables" / "server"
        source = "XJL7457/Public/Data/AIScript/*.ai"
        tsv_file.write_table(out / "monster_ai_rules.tsv", source, TOOL, RULE_TYPES, RULE_COLUMNS, rules)
        tsv_file.write_table(out / "monster_ai_rule_files.tsv", source, TOOL, FILE_TYPES, FILE_COLUMNS, files)
    for issue in issues:
        print(f"script{issue.ai_id}.ai:{issue.line}: {issue.kind}: {issue.text}")
    print(f"tệp {len(files)} luật {stats['rules']} điều kiện {stats['conditions']} hành động {stats['actions']}")
    print(f"không đưa vào bảng được {len(issues)}; hàm bản private: {added_functions(rules)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
