# Kiểm import_rules: bảng luật đủ khoá, số thực ra phần nghìn, test không ghi đè cây thật.
from __future__ import annotations

import io
import os
import shutil
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import import_rules
import lint_config

LEGACY = os.environ.get("THIENLONG_LEGACY_ROOT")
HEADER = "\t".join(import_rules.HEADER)
TYPES = "# types: " + "\t".join(["text"] * len(import_rules.HEADER))
RULE_FILES = {
    "global.toml",
    "combat.toml",
    "character.toml",
    "new_character.toml",
    "monster.toml",
    "instances.toml",
    "pet.toml",
    "hidden_weapon.toml",
    "pvp.toml",
    "guild.toml",
    "social.toml",
    "economy.toml",
    "fatigue.toml",
}


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-b" / "rules-unit" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _capture(args: list[str]) -> tuple[int, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    with redirect_stdout(stdout), redirect_stderr(stderr):
        code = import_rules.main(args)
    return code, stdout.getvalue() + stderr.getvalue()


def _cell(
    source: str,
    section: str,
    key: str,
    fate: str,
    target_file: str = "",
    target_table: str = "",
    target_key: str = "",
    index: str = "",
    convert: str = "",
    note: str = "",
    basis: str = "",
    reason: str = "",
) -> str:
    return "\t".join(
        (
            source,
            section,
            key,
            fate,
            target_file,
            target_table,
            target_key,
            index,
            convert,
            note,
            basis,
            reason,
        )
    )


def _sheet(rows: tuple[str, ...]) -> str:
    return "\n".join(("# schema 1", TYPES, HEADER, *rows)) + "\n"


def _demo_ini() -> str:
    return "[Global]\nDropParam=1.5\nFlag=1\n[Item]\nid0=3\nid1=4\n[Count]\nmonsters=1\n"


def _scalar_rows() -> tuple[str, ...]:
    drop = _cell(
        "Server/Config/Demo.ini",
        "Global",
        "DropParam",
        "rule",
        "global.toml",
        "drop",
        "drop_factor_permille",
        convert="permille",
        note="Hệ số rơi đồ.",
        basis="comment",
    )
    flag = _cell(
        "Server/Config/Demo.ini",
        "Global",
        "Flag",
        "rule",
        "global.toml",
        "pet_guard",
        "auto_remove_bad",
        convert="bool",
        note="Cờ bật tắt.",
        basis="comment",
    )
    monsters = _cell(
        "Server/Config/Demo.ini",
        "Count",
        "monsters",
        "process_config",
        "zone.toml",
        "capacity",
        "monsters",
        convert="int",
    )
    return (drop, flag, monsters)


def _array_rows() -> tuple[str, ...]:
    first = _cell(
        "Server/Config/Demo.ini",
        "Item",
        "id0",
        "rule",
        "instances.toml",
        "copy",
        "id",
        "0",
        "int",
        "Số hiệu.",
        "comment",
    )
    second = _cell(
        "Server/Config/Demo.ini",
        "Item",
        "id1",
        "rule",
        "instances.toml",
        "copy",
        "id",
        "1",
        "int",
        "Số hiệu.",
        "comment",
    )
    return (first, second)


def _demo_rows() -> tuple[str, ...]:
    return _scalar_rows() + _array_rows()


class HandTableTest(unittest.TestCase):
    def test_shape_and_fates(self) -> None:
        path = ROOT / "legacy_rules.tsv"
        text = path.read_text(encoding="utf-8")
        self.assertIn("# schema 1\n", text)
        self.assertIn(TYPES + "\n", text)
        self.assertNotIn("# tool:", text)
        rows = import_rules._hand_rows(path)
        counts = import_rules._counts(rows)
        self.assertEqual(sum(counts.values()), len(rows))
        self.assertGreater(counts["rule"], 0)
        files = {row.target_file for row in rows if row.fate == "rule"}
        self.assertEqual(files, RULE_FILES)
        for row in rows:
            if row.fate == "unknown" and row.reason != "chưa làm ở đợt 3":
                self.assertIn("mốc P3", row.reason)
        by_key = {(row.section, row.key): row for row in rows}
        position = by_key[("baseinfo", "pos_x")]
        self.assertEqual(position.target_key, "position_x")
        self.assertEqual(position.convert, "decimal")
        self.assertEqual(by_key[("attribute", "str")].basis, "code:Common/GameDefine_Attr.h:10")
        self.assertEqual(by_key[("attribute", "str")].target_key, "strength")
        self.assertEqual(by_key[("attribute", "str")].fate, "rule")
        self.assertEqual(by_key[("Human", "XinfaMaxDefaultLevel")].target_key, "inner_art_max_level")
        self.assertEqual(by_key[("Global", "PkRefixOfDamage")].target_key, "pk_modifier")
        self.assertEqual(by_key[("copy0", "id")].target_table, "instance")


class ExportRulesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.legacy = self.root / "tlbb"
        self.output = self.root / "out"
        self.rules = self.root / "legacy_rules.tsv"
        source = self.legacy / "Server" / "Config" / "Demo.ini"
        source.parent.mkdir(parents=True)
        source.write_text(_demo_ini(), encoding="utf-8", newline="\n")
        self.rules.write_text(_sheet(_demo_rows()), encoding="utf-8", newline="\n")
        self.sources = (("Server/Config/Demo.ini", "ini"),)

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _export(self, check_only: bool = False) -> tuple[list[str], list[str]]:
        return import_rules.export_rules(
            self.legacy,
            self.output,
            check_only=check_only,
            rules_path=self.rules,
            sources=self.sources,
        )

    def test_decimal_keeps_source_digits(self) -> None:
        source = self.legacy / "Server" / "Config" / "Demo.ini"
        source.write_text("[Pos]\nx=165.10\n", encoding="utf-8", newline="\n")
        row = _cell(
            "Server/Config/Demo.ini",
            "Pos",
            "x",
            "rule",
            "new_character.toml",
            "profile",
            "position_x",
            convert="decimal",
            note="Hoành độ.",
            basis="name",
        )
        self.rules.write_text(_sheet((row,)), encoding="utf-8", newline="\n")
        errors, _summary = self._export()
        self.assertEqual(errors, [])
        text = (self.output / "new_character.toml").read_text(encoding="utf-8")
        self.assertIn("position_x = 165.10", text)

    def test_hash_equals_is_a_key(self) -> None:
        source = self.legacy / "Server" / "Config" / "Demo.ini"
        source.write_text("[Global]\nDropParam=1.5\n#extra=9\n", encoding="utf-8", newline="\n")
        row = _cell(
            "Server/Config/Demo.ini",
            "Global",
            "DropParam",
            "rule",
            "global.toml",
            "drop",
            "drop_factor_permille",
            convert="permille",
            note="Hệ số rơi đồ.",
            basis="comment",
        )
        self.rules.write_text(_sheet((row,)), encoding="utf-8", newline="\n")
        errors, _summary = self._export()
        self.assertTrue(any("#extra" in error and "chưa có dòng" in error for error in errors))
        self.assertIn("Demo.ini:3:", errors[0])

    def test_permille_bool_and_array(self) -> None:
        errors, summary = self._export()
        self.assertEqual(errors, [])
        text = (self.output / "global.toml").read_text(encoding="utf-8")
        self.assertIn("schema = 1", text)
        self.assertIn("drop_factor_permille = 1500", text)
        self.assertIn("auto_remove_bad = true", text)
        copied = (self.output / "instances.toml").read_text(encoding="utf-8")
        self.assertIn("id = [3, 4]", copied)
        self.assertTrue(any("lệch tiến trình: 1" in line for line in summary))
        self.assertEqual(lint_config.check_file(self.output / "global.toml"), [])

    def test_index_gap_is_rejected(self) -> None:
        source = self.legacy / "Server" / "Config" / "Demo.ini"
        source.write_text("[Item]\nid0=3\nid2=9\n", encoding="utf-8", newline="\n")
        first = _cell(
            "Server/Config/Demo.ini",
            "Item",
            "id0",
            "rule",
            "instances.toml",
            "copy",
            "id",
            "0",
            "int",
            "Số hiệu.",
            "comment",
        )
        second = _cell(
            "Server/Config/Demo.ini",
            "Item",
            "id2",
            "rule",
            "instances.toml",
            "copy",
            "id",
            "2",
            "int",
            "Số hiệu.",
            "comment",
        )
        self.rules.write_text(_sheet((first, second)), encoding="utf-8", newline="\n")
        errors, _summary = self._export()
        self.assertTrue(any("index khuyết" in error for error in errors))
        self.assertFalse((self.output / "instances.toml").exists())

    def test_check_writes_nothing(self) -> None:
        errors, summary = self._export(check_only=True)
        self.assertEqual(errors, [])
        self.assertTrue(summary)
        self.assertFalse(self.output.exists())

    def test_merge_window_is_two_hours(self) -> None:
        literal = import_rules._toml_literal(
            "0\tProcreate\tmo ta\t7040400\t7040400",
            "window",
            "MergeConfig.txt",
            3,
        )
        self.assertEqual(literal, "[7040400, 7040400]")

    def test_help_and_bad_argument_are_captured(self) -> None:
        code, text = _capture(["--help"])
        self.assertEqual(code, 0)
        self.assertIn("không ghi", text)
        code, text = _capture(["--nope"])
        self.assertEqual(code, 1)
        self.assertIn("không rõ đối số", text)


class RealRulesTest(unittest.TestCase):
    def test_real_tree(self) -> None:
        if not LEGACY:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT")
        root = Path(LEGACY)
        scratch = _scratch("real_rules")
        output = scratch / "out"
        try:
            code, text = _capture([str(root), str(output)])
            self.assertEqual(code, 0, text)
            self.assertIn("lệch tiến trình: 0", text)
            for name in RULE_FILES:
                path = output / name
                self.assertTrue(path.is_file(), name)
                self.assertEqual(lint_config.check_file(path), [])
            self.assertTrue((output / "pet.toml").is_file())
        finally:
            shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
