#!/usr/bin/env python3
"""Xếp hạng logic kỹ năng và logic hiệu ứng theo số dòng dữ liệu mỗi môn phái, rồi đo độ phủ của mã chiến đấu.

Dòng = một kỹ năng cấp (dòng skill_levels.tsv) mà mẫu kỹ năng của môn phái 0..8, 10..15 trỏ tới qua
16 ô skill_id_at_inner_art_level_N. Một dòng được phủ khi logic kỹ năng của nó có mã xử lý thật (không phải
`unsupported`) trong dev/server/tables/server/skill_logics.tsv và mọi hiệu ứng nó chạm tới (theo cột `roles`, đệ quy
qua các vai `sub` ở effect_logics.tsv) có logic hiệu ứng với mã xử lý. Hiệu ứng mà effects.tsv không có dòng tách
riêng thành "thiếu dữ liệu": mã không thể phủ thứ dữ liệu không tồn tại. Dòng của logic chưa có mã xử lý mà mọi ô
tham số đều rỗng (trận pháp, triệu hồi: cơ chế chỉ có trong mã máy chủ 2026, bảng không mang số nào) tách thành
"không tham số" vì lý do tương tự. Tỉ lệ tính trên các dòng còn lại.

Ba mức phủ, mỗi mức nằm trong mức trước:
  phủ   — mọi logic chạm tới đều có mã xử lý (kể cả mức `event`: lõi chỉ phát sự kiện cho module ngoài).
  chắc  — như trên và không logic nào ở mức `event` (phần chính được làm trong lõi).
  trọn  — như trên và mọi logic ở mức `full` (cơ chế phụ cũng đủ).

Cách dùng:
    python TOOLS/server/skill_coverage.py                 xếp hạng chung + bảng độ phủ
    python TOOLS/server/skill_coverage.py --per-sect      thêm xếp hạng logic kỹ năng và hiệu ứng của từng phái
    python TOOLS/server/skill_coverage.py --markdown      bảng Markdown cho docs/SERVER-COMBAT.md
    python TOOLS/server/skill_coverage.py --pending       logic còn chặn dòng, giảm dần
    python TOOLS/server/skill_coverage.py --check 95      thoát 1 nếu phái nào có độ phủ dưới 95% trên dòng còn dữ liệu
"""

from __future__ import annotations

import argparse
import collections
import dataclasses
import re
import sys
from pathlib import Path

import tsv_file

ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "dev" / "server" / "tables"
SECTS = [*range(0, 9), *range(10, 16)]
LEVEL_SLOTS = 16
FIRST_PARAM_COLUMN = 24  # skill_levels.tsv: mô tả/giá trị xen kẽ từ cột 24, giá trị ở +1
EFFECT_PARAM_COLUMN = 27  # effects.tsv: ba cột (mô tả, giá trị, bước) từ cột 27, giá trị ở +1
SKILL_LOGIC_COLUMN = 5
SKILL_PARAM_PAIRS = 15
EFFECT_LOGIC_COLUMN = 2
UNSUPPORTED = "unsupported"

# Vai mà tham số là id một hiệu ứng (khớp RoleKind của src/server/combat/catalog.hpp). Các vai còn lại
# (trap, trap_tick, summon, totem, dispel_self, cut_cooldown) mang id dữ liệu khác, không phải hiệu ứng.
EFFECT_ROLE = re.compile(
    r"^(target|self|target_tick|self_tick|friend|enemy|rest|friend_rest|enemy_rest|self_male|self_female|sub|"
    r"(?:rank|friend|enemy)\d+|combo[0-3])$"
)
ROLE_PART = re.compile(r"^(\d+):([a-z_]+\d*)((?:[@*+]\d+)*)$")

FULL, CORE, EVENT = "full", "core", "event"


def read_table(relative: str) -> tuple[list[str], list[list[str]]]:
    """Đọc bảng TSV của dự án: bỏ dòng # và dòng rỗng, dòng đầu là tên cột."""
    rows = tsv_file.split_rows((TABLES / relative).read_text(encoding="utf-8"))
    return rows[0], rows[1:]


@dataclasses.dataclass(frozen=True)
class Role:
    param: int
    name: str
    carries_effect: bool


def parse_roles(text: str) -> list[Role]:
    """`0:target;1:self@2` thành danh sách vai, đúng cú pháp của parse_roles ở catalog.cpp."""
    roles: list[Role] = []
    if text in ("", "-"):
        return roles
    for part in text.split(";"):
        match = ROLE_PART.fullmatch(part)
        if match is None:
            raise ValueError(f"vai sai cú pháp: {part!r}")
        name = match.group(2)
        roles.append(Role(int(match.group(1)), name, EFFECT_ROLE.fullmatch(name) is not None))
    return roles


@dataclasses.dataclass
class Registry:
    handlers: dict[int, str]
    fidelity: dict[int, str]
    roles: dict[int, list[Role]]

    def covered(self, logic: int) -> bool:
        return logic in self.handlers and self.handlers[logic] != UNSUPPORTED


def load_registry(relative: str) -> Registry:
    if not (TABLES / relative).exists():
        return Registry({}, {}, {})
    header, rows = read_table(relative)
    col = {name: i for i, name in enumerate(header)}
    registry = Registry({}, {}, {})
    for row in rows:
        logic = int(row[col["logic_id"]])
        registry.handlers[logic] = row[col["handler"]]
        registry.fidelity[logic] = row[col["fidelity"]]
        registry.roles[logic] = parse_roles(row[col["roles"]])
    return registry


def collect_rows() -> tuple[dict[int, list[str]], dict[str, list[str]], dict[str, list[str]]]:
    """Mỗi phái -> các mã kỹ năng cấp (không lặp); bảng cấp theo mã; bảng hiệu ứng theo mã."""
    sk_header, skills = read_table("shared/skills.tsv")
    _, levels = read_table("shared/skill_levels.tsv")
    sect_col = sk_header.index("sect")
    slot_cols = [sk_header.index(f"skill_id_at_inner_art_level_{n}") for n in range(1, LEVEL_SLOTS + 1)]
    by_level = {row[0]: row for row in levels}
    per_sect: dict[int, list[str]] = {sect: [] for sect in SECTS}
    for row in skills:
        sect = int(row[sect_col])
        if sect not in per_sect:
            continue
        seen: set[str] = set()
        for col in slot_cols:
            instance = row[col]
            if instance in by_level and instance not in seen:
                seen.add(instance)
                per_sect[sect].append(instance)
    _, effects = read_table("server/effects.tsv")
    return per_sect, by_level, {row[0]: row for row in effects}


def referenced_ids(row: list[str], roles: list[Role], first_column: int, stride: int) -> list[int]:
    """Id hiệu ứng mà các vai mang id hiệu ứng của một dòng trỏ tới; ô trống hay <= 0 bị bỏ."""
    ids: list[int] = []
    for role in roles:
        if not role.carries_effect:
            continue
        cell = first_column + stride * role.param + 1
        if cell >= len(row):
            continue
        try:
            value = int(row[cell])
        except ValueError:
            continue
        if value > 0:
            ids.append(value)
    return ids


@dataclasses.dataclass
class RowInfo:
    skill_logic: int
    effect_logics: set[int]
    missing: int  # số hiệu ứng được tham chiếu mà effects.tsv không có
    empty: bool   # mọi ô tham số của dòng kỹ năng đều rỗng (<= 0)


def no_parameters(row: list[str]) -> bool:
    """Dòng kỹ năng không mang số dương nào ở 15 ô tham số."""
    for k in range(SKILL_PARAM_PAIRS):
        cell = FIRST_PARAM_COLUMN + 2 * k + 1
        if cell >= len(row):
            break
        try:
            if int(row[cell]) > 0:
                return False
        except ValueError:
            continue
    return True


def analyse_row(row: list[str], effects: dict[str, list[str]], skill_reg: Registry, effect_reg: Registry) -> RowInfo:
    logic = int(row[SKILL_LOGIC_COLUMN])
    stack = referenced_ids(row, skill_reg.roles.get(logic, []), FIRST_PARAM_COLUMN, 2)
    seen: set[int] = set()
    logics: set[int] = set()
    missing = 0
    while stack:
        effect_id = stack.pop()
        if effect_id in seen:
            continue
        seen.add(effect_id)
        effect = effects.get(str(effect_id))
        if effect is None:
            missing += 1
            continue
        effect_logic = int(effect[EFFECT_LOGIC_COLUMN])
        logics.add(effect_logic)
        stack.extend(referenced_ids(effect, effect_reg.roles.get(effect_logic, []), EFFECT_PARAM_COLUMN, 3))
    return RowInfo(logic, logics, missing, no_parameters(row))


@dataclasses.dataclass
class SectReport:
    sect: int
    rows: int = 0
    missing_rows: int = 0
    empty_rows: int = 0
    covered: int = 0
    solid: int = 0
    exact: int = 0
    skill_rank: collections.Counter = dataclasses.field(default_factory=collections.Counter)
    effect_rank: collections.Counter = dataclasses.field(default_factory=collections.Counter)
    blocked_by_skill: collections.Counter = dataclasses.field(default_factory=collections.Counter)
    blocked_by_effect: collections.Counter = dataclasses.field(default_factory=collections.Counter)

    @property
    def usable(self) -> int:
        return self.rows - self.missing_rows - self.empty_rows


def row_level(info: RowInfo, skill_reg: Registry, effect_reg: Registry) -> str | None:
    """Mức phủ thấp nhất trong mọi logic của dòng; None khi có logic thiếu mã xử lý."""
    if not skill_reg.covered(info.skill_logic) or any(not effect_reg.covered(lg) for lg in info.effect_logics):
        return None
    levels = {skill_reg.fidelity[info.skill_logic], *(effect_reg.fidelity[lg] for lg in info.effect_logics)}
    if EVENT in levels:
        return EVENT
    return CORE if CORE in levels else FULL


def tally(report: SectReport, info: RowInfo, skill_reg: Registry, effect_reg: Registry) -> None:
    """Xếp một dòng kỹ năng vào đúng nhóm của báo cáo phái."""
    report.rows += 1
    report.skill_rank[info.skill_logic] += 1
    report.effect_rank.update(info.effect_logics)
    if info.missing:
        report.missing_rows += 1
        return
    if info.empty and not skill_reg.covered(info.skill_logic):
        report.empty_rows += 1
        return
    level = row_level(info, skill_reg, effect_reg)
    if level is None:
        if not skill_reg.covered(info.skill_logic):
            report.blocked_by_skill[info.skill_logic] += 1
        report.blocked_by_effect.update(lg for lg in info.effect_logics if not effect_reg.covered(lg))
        return
    report.covered += 1
    report.solid += level in (FULL, CORE)
    report.exact += level == FULL


def analyse(per_sect: dict[int, list[str]], by_level: dict[str, list[str]], effects: dict[str, list[str]],
            skill_reg: Registry, effect_reg: Registry) -> list[SectReport]:
    """Báo cáo độ phủ của từng phái."""
    reports: list[SectReport] = []
    for sect in SECTS:
        report = SectReport(sect)
        for instance in per_sect[sect]:
            info = analyse_row(by_level[instance], effects, skill_reg, effect_reg)
            tally(report, info, skill_reg, effect_reg)
        reports.append(report)
    return reports


def percent(part: int, whole: int) -> float:
    return 100.0 * part / whole if whole else 100.0


def totals(reports: list[SectReport]) -> SectReport:
    total = SectReport(-1)
    for r in reports:
        total.rows += r.rows
        total.missing_rows += r.missing_rows
        total.empty_rows += r.empty_rows
        total.covered += r.covered
        total.solid += r.solid
        total.exact += r.exact
        total.skill_rank.update(r.skill_rank)
        total.effect_rank.update(r.effect_rank)
        total.blocked_by_skill.update(r.blocked_by_skill)
        total.blocked_by_effect.update(r.blocked_by_effect)
    return total


def mark(logic: int, registry: Registry) -> str:
    if not registry.covered(logic):
        return "chưa" if logic not in registry.handlers else "không hỗ trợ"
    return f"{registry.handlers[logic]} ({registry.fidelity[logic]})"


def print_rank(title: str, rank: collections.Counter, registry: Registry, limit: int | None) -> None:
    print(title)
    for logic, count in rank.most_common(limit):
        print(f"  {logic:5d}  {count:5d}  {mark(logic, registry)}")


def table_lines(reports: list[SectReport], markdown: bool) -> list[str]:
    head = ["Phái", "Dòng", "Thiếu dữ liệu", "Không tham số", "Phủ", "Chắc", "Trọn", "Phủ/dòng còn dữ liệu",
            "Chắc/dòng còn dữ liệu"]
    lines = [("| " + " | ".join(head) + " |") if markdown else " | ".join(head)]
    if markdown:
        lines.append("|" + "---|" * len(head))
    for r in [*reports, totals(reports)]:
        name = "Tổng" if r.sect < 0 else str(r.sect)
        cells = [name, str(r.rows), str(r.missing_rows), str(r.empty_rows), str(r.covered), str(r.solid), str(r.exact),
                 f"{percent(r.covered, r.usable):.2f}%", f"{percent(r.solid, r.usable):.2f}%"]
        lines.append(("| " + " | ".join(cells) + " |") if markdown else " | ".join(cells))
    return lines


def print_pending(reports: list[SectReport]) -> None:
    total = totals(reports)
    print("Logic kỹ năng còn chặn dòng (giảm dần):", total.blocked_by_skill.most_common())
    print("Logic hiệu ứng còn chặn dòng (giảm dần):", total.blocked_by_effect.most_common())
    for r in reports:
        print(f"  phái {r.sect}: kỹ năng {r.blocked_by_skill.most_common()} "
              f"hiệu ứng {r.blocked_by_effect.most_common()}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--markdown", action="store_true")
    parser.add_argument("--pending", action="store_true")
    parser.add_argument("--per-sect", action="store_true")
    parser.add_argument("--check", type=float, default=None, help="ngưỡng phần trăm trên dòng còn dữ liệu")
    args = parser.parse_args()

    per_sect, by_level, effects = collect_rows()
    skill_reg = load_registry("server/skill_logics.tsv")
    effect_reg = load_registry("server/effect_logics.tsv")
    reports = analyse(per_sect, by_level, effects, skill_reg, effect_reg)
    if args.markdown:
        print("\n".join(table_lines(reports, True)))
    elif args.pending:
        print_pending(reports)
    else:
        total = totals(reports)
        print_rank("Logic kỹ năng theo số dòng (mọi phái):", total.skill_rank, skill_reg, None)
        print_rank("Logic hiệu ứng theo số dòng chạm tới (mọi phái):", total.effect_rank, effect_reg, None)
        if args.per_sect:
            for r in reports:
                print_rank(f"Phái {r.sect}: logic kỹ năng", r.skill_rank, skill_reg, 12)
                print_rank(f"Phái {r.sect}: logic hiệu ứng", r.effect_rank, effect_reg, 12)
        print("\n".join(table_lines(reports, False)))
    if args.check is not None:
        failing = [r.sect for r in reports if percent(r.covered, r.usable) < args.check]
        if failing:
            print(f"Dưới {args.check}%: phái {failing}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
