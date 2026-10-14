# Kiểm import_combat và skill_coverage: bảng sinh ra khớp bộ sinh, tên mã xử lý có thật trong C++, vai đúng cú pháp,
# độ phủ dữ liệu thật không tụt dưới mức đã chốt. Test không ghi đè cây bảng thật.
from __future__ import annotations

import io
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import combat_logics
import import_combat
import skill_coverage
import tsv_file

PROJECT = ROOT.parents[1]
COMBAT_SOURCES = PROJECT / "src" / "server" / "combat" / "detail"
TABLE_FILES = ("sect_templates.tsv", "sect_rage_rules.tsv", "skill_logics.tsv", "effect_logics.tsv")
HAS_REAL_TABLES = (skill_coverage.TABLES / "shared" / "skill_levels.tsv").is_file() and (
    skill_coverage.TABLES / "server" / "effects.tsv"
).is_file()
SKILL_PARAMS = 15
EFFECT_PARAMS = 16
# Logic kỹ năng được phép còn chặn dòng, và lý do ở combat_logics.NEED_ADVANCE: bí pháp tiến giai không nối được với
# kỹ năng gốc bằng bảng.
ADVANCE_LOGICS = frozenset({700, 701, 702, 703, 704, 705, 706, 707, 734, 735})
COVERAGE_FLOOR = 90.0


def _cpp_names(pattern: str, files: list[Path]) -> set[str]:
    found: set[str] = set()
    for path in files:
        found.update(re.findall(pattern, path.read_text(encoding="utf-8")))
    return found


def _quiet_run(folder: Path, check: bool) -> tuple[int, str]:
    out = io.StringIO()
    err = io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = import_combat.run(folder, check)
    return code, out.getvalue() + err.getvalue()


def _read(path: Path) -> tsv_file.Table:
    return tsv_file.read_table(path)


class GeneratedTables(unittest.TestCase):
    def test_write_then_check(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            folder = Path(raw)
            code, _ = _quiet_run(folder, False)
            self.assertEqual(code, 0)
            for name in TABLE_FILES:
                self.assertTrue((folder / "server" / name).is_file(), name)
            code, _ = _quiet_run(folder, True)
            self.assertEqual(code, 0)

    def test_check_flags_a_hand_edit(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            folder = Path(raw)
            _quiet_run(folder, False)
            target = folder / "server" / "skill_logics.tsv"
            target.write_text(target.read_text(encoding="utf-8") + "999\tstandard\t\tfull\tsửa tay\n", encoding="utf-8")
            code, output = _quiet_run(folder, True)
            self.assertEqual(code, 1)
            self.assertIn("skill_logics.tsv", output)

    def test_check_flags_a_missing_table(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            code, output = _quiet_run(Path(raw), True)
            self.assertEqual(code, 1)
            self.assertIn("effect_logics.tsv", output)

    def test_committed_tables_are_current(self) -> None:
        folder = skill_coverage.TABLES
        if not all((folder / "server" / name).is_file() for name in TABLE_FILES):
            self.skipTest("chưa sinh bảng chiến đấu vào dev/server/tables")
        code, output = _quiet_run(folder, True)
        self.assertEqual(code, 0, output)

    def test_logic_columns(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            _quiet_run(Path(raw), False)
            for name, count in (("skill_logics.tsv", len(combat_logics.SKILL_LOGICS)),
                                ("effect_logics.tsv", len(combat_logics.EFFECT_LOGICS))):
                table = _read(Path(raw) / "server" / name)
                self.assertEqual(table.columns, import_combat.LOGIC_HEADER)
                self.assertEqual(table.types, import_combat.LOGIC_TYPES)
                self.assertEqual(len(table.rows), count)
                ids = [int(row[0]) for row in table.rows]
                self.assertEqual(ids, sorted(set(ids)))


class LogicContent(unittest.TestCase):
    def test_skill_handlers_exist_in_cpp(self) -> None:
        names = _cpp_names(r'Entry\{\.name = "([a-z_]+)"', [COMBAT_SOURCES / "skills.cpp"])
        self.assertIn("standard", names)
        for logic, item in combat_logics.SKILL_LOGICS.items():
            self.assertIn(item.handler, names, f"logic kỹ năng {logic}")

    def test_effect_handlers_exist_in_cpp(self) -> None:
        sources = [COMBAT_SOURCES / name for name in ("effects.cpp", "effects_damage.cpp", "effects_stat.cpp",
                                                      "effects_hook.cpp")]
        names = _cpp_names(r'(?:registry|built)(?:\.|->)add\("([a-z_]+)"', sources)
        self.assertIn("damage_attack", names)
        for logic, item in combat_logics.EFFECT_LOGICS.items():
            self.assertIn(item.handler, names, f"logic hiệu ứng {logic}")

    def test_roles_parse_and_stay_in_range(self) -> None:
        for kind, table, limit in (("kỹ năng", combat_logics.SKILL_LOGICS, SKILL_PARAMS),
                                   ("hiệu ứng", combat_logics.EFFECT_LOGICS, EFFECT_PARAMS)):
            for logic, item in table.items():
                for role in skill_coverage.parse_roles(item.roles):
                    self.assertLess(role.param, limit, f"logic {kind} {logic}: ô {role.param}")

    def test_fidelity_values(self) -> None:
        for table in (combat_logics.SKILL_LOGICS, combat_logics.EFFECT_LOGICS):
            for logic, item in table.items():
                self.assertIn(item.fidelity, ("full", "core", "event"), str(logic))
                self.assertTrue(item.note, f"logic {logic} thiếu ghi chú")
        for logic, item in combat_logics.EFFECT_LOGICS.items():
            self.assertNotEqual(item.handler, "unsupported", f"logic hiệu ứng {logic}")

    def test_unsupported_skills_have_event_fidelity(self) -> None:
        for logic, item in combat_logics.SKILL_LOGICS.items():
            if item.handler == "unsupported":
                self.assertEqual(item.fidelity, "event", str(logic))

    def test_composite_effects_declare_sub_roles(self) -> None:
        for logic in (10, 60, 68, 77, 86, 88):
            roles = skill_coverage.parse_roles(combat_logics.EFFECT_LOGICS[logic].roles)
            self.assertTrue(roles, f"logic {logic} không khai vai nào")

    def test_bad_roles_are_rejected(self) -> None:
        for text in ("0target", "x:target", "0:Target", "0:target@", "0:target;;1:self"):
            with self.assertRaises(ValueError, msg=text):
                skill_coverage.parse_roles(text)

    def test_effect_id_roles(self) -> None:
        roles = skill_coverage.parse_roles("0:target;1:self@2;2:trap;3:cut_cooldown+4;4:rank3;5:combo1;6:sub")
        self.assertEqual([role.carries_effect for role in roles], [True, True, False, False, True, True, True])


class SectTables(unittest.TestCase):
    def test_templates_borrow_an_original_sect(self) -> None:
        rows = import_combat.template_rows()
        self.assertEqual([row[0] for row in rows], ["10", "11", "12", "13", "14", "15"])
        for row in rows:
            self.assertIn(int(row[1]), range(0, 9))
            self.assertEqual(row[2], import_combat.MADE_UP)

    def test_rage_rules(self) -> None:
        rows = import_combat.rage_rows()
        original = [row for row in rows if row[4] == import_combat.SOURCE_2008]
        borrowed = [row for row in rows if row[4] == import_combat.MADE_UP]
        self.assertEqual(sorted((row[0], row[1], row[2], row[3]) for row in original),
                         [("2", "strike_spent", "10", "1"), ("4", "heal_done", "1", "20"),
                          ("8", "trap_triggered", "10", "1")])
        # Chỉ phái mẫu có luật mới sinh dòng mượn: Đào Hoa Đảo (13) mượn Nga Mi (4); phái mới khác thì không.
        self.assertEqual([(row[0], row[1]) for row in borrowed], [("13", "heal_done")])


@unittest.skipUnless(HAS_REAL_TABLES, "chưa có dev/server/tables/shared và server/effects.tsv")
class RealCoverage(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        per_sect, by_level, effects = skill_coverage.collect_rows()
        skill_reg = skill_coverage.load_registry("server/skill_logics.tsv")
        effect_reg = skill_coverage.load_registry("server/effect_logics.tsv")
        cls.reports = skill_coverage.analyse(per_sect, by_level, effects, skill_reg, effect_reg)
        cls.skill_reg = skill_reg

    def test_every_sect_is_listed(self) -> None:
        self.assertEqual([report.sect for report in self.reports], skill_coverage.SECTS)

    def test_no_effect_logic_blocks_a_row(self) -> None:
        for report in self.reports:
            self.assertFalse(report.blocked_by_effect, f"phái {report.sect}: {report.blocked_by_effect}")

    def test_only_advance_secrets_remain_blocked(self) -> None:
        for report in self.reports:
            self.assertLessEqual(set(report.blocked_by_skill), ADVANCE_LOGICS, f"phái {report.sect}")

    def test_coverage_floor(self) -> None:
        for report in self.reports:
            share = skill_coverage.percent(report.covered, report.usable)
            self.assertGreaterEqual(share, COVERAGE_FLOOR, f"phái {report.sect}: {share:.2f}%")

    def test_original_sects_reach_95_percent(self) -> None:
        for report in self.reports:
            if report.sect <= 10:
                self.assertGreaterEqual(skill_coverage.percent(report.covered, report.usable), 95.0, str(report.sect))

    def test_row_accounting(self) -> None:
        for report in self.reports:
            blocked = sum(report.blocked_by_skill.values())
            self.assertEqual(report.missing_rows + report.empty_rows + report.covered + blocked, report.rows,
                             f"phái {report.sect}")
            self.assertLessEqual(report.exact, report.solid)
            self.assertLessEqual(report.solid, report.covered)


if __name__ == "__main__":
    unittest.main()
