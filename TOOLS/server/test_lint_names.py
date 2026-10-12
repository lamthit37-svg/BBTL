# Kiểm cổng thuật ngữ: N1, N2, ngoại lệ, và tên nhóm TOML.
from __future__ import annotations

import io
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import lint_names

PROJECT = ROOT.parents[1]


class _Capture(io.StringIO):
    def reconfigure(self, **_kwargs: object) -> None:
        return None


def _banned() -> tuple[set[str], set[str]]:
    return lint_names._glossary_banned()


class NameRuleTest(unittest.TestCase):
    def test_single_token_hits_the_seven_kinds(self) -> None:
        banned, official = _banned()
        self.assertIn("xinfa", lint_names._hits("xinfa_max_level", banned, official))
        self.assertIn("refix", lint_names._hits("pk_refix", banned, official))
        self.assertIn("ability", lint_names._hits("ability", banned, official))
        self.assertEqual(lint_names._hits("copy", banned, official), [])
        self.assertEqual(lint_names._hits("ingot_ticket", banned, official), [])
        self.assertEqual(lint_names._hits("mission_id", banned, official), [])

    def test_joined_tokens_catch_copy_scene_not_the_official_name(self) -> None:
        banned, official = _banned()
        self.assertIn("copyscene", lint_names._hits("copy_scene", banned, official))
        self.assertEqual(lint_names._hits("grow_point", banned, official), [])

    def test_exception_skips_a_name(self) -> None:
        banned, official = _banned()
        problems = lint_names._problems("xinfa_max_level", banned, official, {"xinfa_max_level"})
        self.assertEqual(problems, [])

    def test_bad_shape(self) -> None:
        self.assertEqual(lint_names._n2("Bad"), "sai dạng tên")
        self.assertEqual(lint_names._n2("ok_name"), "")

    def test_term_pattern_is_checked_after_a_digit_is_filled(self) -> None:
        banned, official = _banned()
        filled = lint_names._filled_term("weapon_min_{n}")
        self.assertEqual(lint_names._problems(filled or "", banned, official, set()), [])
        self.assertEqual(lint_names._n2(lint_names._filled_term("{n}") or ""), "sai dạng tên")
        self.assertIsNone(lint_names._filled_term("a_{n}}"))
        xinfa = lint_names._filled_term("xinfa_{n}")
        self.assertIn("xinfa", lint_names._hits(xinfa or "", banned, official))

    def test_morpheme_requires_the_word_and_rejects_the_banned_one(self) -> None:
        morphemes = lint_names._morphemes()
        defense = lint_names._n3("物理防御", "physical_defense", morphemes, set())
        self.assertEqual(defense, ["thiếu từ defence", "chứa từ cấm defense"])
        defence = lint_names._n3("物理防御", "physical_defence", morphemes, set())
        self.assertEqual(defence, [])
        label = "珍兽技能类型,0:物功,1:法功,2:护主,3:防御,4:复仇;"
        excused = lint_names._n3(label, "pet_skill_type", morphemes, {"pet_skill_type"})
        self.assertEqual(excused, [])

    def test_one_original_keeps_one_name(self) -> None:
        path = ROOT / "column_terms.tsv"
        clash = [(path, 2, "闪避", "dodge"), (path, 9, "闪避", "miss")]
        same = [(path, 2, "闪避", "dodge"), (path, 9, "闪避", "dodge")]
        self.assertEqual(len(lint_names._n4(clash, set())), 2)
        self.assertEqual(lint_names._n4(clash, {"闪避"}), [])
        self.assertEqual(lint_names._n4(same, set()), [])

    def test_help_is_quiet(self) -> None:
        stdout = _Capture()
        old = sys.stdout
        sys.stdout = stdout
        try:
            code = lint_names.main(["--help"])
        finally:
            sys.stdout = old
        self.assertEqual(code, 0)
        self.assertIn("--stats", stdout.getvalue())


class StatsFixtureTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = PROJECT / "build" / "p1-d3-names" / self.id().split(".")[-1]
        if self.root.exists():
            shutil.rmtree(self.root)
        self.root.mkdir(parents=True)

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_kind_partitions_empty_han_and_ascii(self) -> None:
        self.assertEqual(lint_names._kind(""), "empty")
        self.assertEqual(lint_names._kind("门派"), "han")
        self.assertEqual(lint_names._kind("PNUM(每组)"), "mixed")
        self.assertEqual(lint_names._kind("PvpRuler"), "ascii")
        self.assertEqual(lint_names._kind("12"), "han")


if __name__ == "__main__":
    unittest.main()
