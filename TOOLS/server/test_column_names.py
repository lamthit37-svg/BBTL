# Kiểm phần đặt tên đã dời sang column_names, cùng kết quả với mã cũ.
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import column_names


class MovedNameTest(unittest.TestCase):
    def test_english_name_matches_the_old_cases(self) -> None:
        self.assertEqual(column_names.english_name("ID"), ("id", False))
        self.assertEqual(column_names.english_name("MenPai"), ("sect", False))
        self.assertEqual(column_names.english_name("AbilityId"), ("life_skill_id", False))
        self.assertEqual(column_names.english_name("门派"), ("sect", False))
        self.assertEqual(column_names.english_name("KFS"), ("martial_soul", True))
        self.assertEqual(column_names.english_name("MissionID"), ("mission_id", False))
        self.assertEqual(column_names.english_name("名称$1$"), (None, False))
        self.assertEqual(column_names.english_name("nLevel"), ("n_level", False))

    def test_repeated_names_are_numbered_from_one(self) -> None:
        names, clashes = column_names.number_repeated(["id", "id", "note"])
        self.assertEqual(names, ["id_1", "id_2", "note"])
        self.assertEqual(clashes, set())

    def test_server_names_use_glossary_and_m2(self) -> None:
        columns, notes = column_names.named_columns(
            ["PvpRuler", "ZhuandanID", "不是", "PNUM(每组多少个)", "ItemID1", ""],
            terms=(),
        )
        self.assertEqual(columns, ["pvp_rules", "gacha_id", "column_2", "pnum", "item_id_1", "column_5"])
        self.assertEqual(notes[0], "luật: M1")
        self.assertEqual(notes[1], "luật: M1")
        self.assertEqual(notes[2], "?")
        self.assertEqual(notes[3], "luật: M2")
        self.assertEqual(notes[5], "?")

    def test_scope_term_beats_m1_and_pattern_fills_digits(self) -> None:
        terms = (
            column_names.TermRow("MenPai", "", "ignored", "direct", ""),
            column_names.TermRow("MenPai", "ShopTable.txt", "sect_shop", "direct", ""),
            column_names.TermRow("参数{n}", "ShopTable.txt", "param_{n}", "direct", ""),
        )
        columns, notes = column_names.named_columns(["MenPai", "参数3", "Rate", "Rate"], "ShopTable.txt", terms)
        self.assertEqual(columns, ["sect_shop", "param_3", "rate_1", "rate_2"])
        self.assertEqual(notes[0], "luật: nguyên văn")
        self.assertEqual(notes[1], "luật: mẫu {n}")
        self.assertEqual(notes[2], "luật: M1")

    def test_m2_takes_the_identifier_before_the_paren(self) -> None:
        self.assertEqual(column_names.m2_identifier("PNUM(每组多少个)"), "PNUM")
        self.assertEqual(column_names.m2_identifier("ID（掉落包编号）"), "ID")
        self.assertIsNone(column_names.m2_identifier("商区ID"))


if __name__ == "__main__":
    unittest.main()
