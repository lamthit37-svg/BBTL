# Kiểm căn cột: neo giữ thứ tự, nội suy giữa hai neo, đổi kiểu cần 99%.
from __future__ import annotations

import unittest
from pathlib import Path

import align_columns
from align_columns import TablePair, align, link_note, summarize

ROOT = Path(__file__).resolve().parent
Cell = tuple[str, int | str]


def _int(value: int) -> Cell:
    return ("int", value)


def _text(value: str) -> Cell:
    return ("text", value)


def _rows(columns: list[list[Cell]]) -> tuple[tuple[Cell, ...], ...]:
    height = len(columns[0])
    rows = []
    for index in range(height):
        row = []
        for column in columns:
            row.append(column[index])
        rows.append(tuple(row))
    return tuple(rows)


def _pair(
    kinds_new: tuple[str, ...],
    rows_new: tuple[tuple[Cell, ...], ...],
    kinds_old: tuple[str, ...],
    names_old: tuple[str, ...],
    rows_old: tuple[tuple[Cell, ...], ...],
) -> TablePair:
    return TablePair(kinds_new, rows_new, kinds_old, names_old, rows_old)


class AlignTest(unittest.TestCase):
    def test_inserted_column_stays_between_anchors(self) -> None:
        ids = [_int(1), _int(2), _int(3), _int(4)]
        values = [_int(10), _int(20), _int(30), _int(40)]
        extra = [_int(0), _int(0), _int(0), _int(0)]
        rows_new = _rows([ids, extra, values])
        rows_old = _rows([ids, values])
        pair = _pair(("int", "int", "int"), rows_new, ("int", "int"), ("ID", "Value"), rows_old)
        links = align(pair)
        self.assertEqual([link.kind for link in links], ["neo", "new", "neo"])
        self.assertEqual(links[0].legacy_index, 0)
        self.assertEqual(links[2].legacy_name, "Value")
        self.assertEqual(link_note(links[2]), "neo: cột gốc 1, khớp 100.0% (4/4 id)")
        self.assertEqual(link_note(links[1]), "mới ở 2026")
        summary = summarize("Pet.txt", links, pair.names_old)
        self.assertEqual(summary.anchors, 2)
        self.assertEqual(summary.new_in_2026, 1)
        self.assertEqual(summary.lost, 0)

    def test_constant_between_anchors_is_interpolated(self) -> None:
        ids = [_int(1), _int(2), _int(3), _int(4)]
        flag = [_int(1), _int(1), _int(1), _int(1)]
        values = [_int(10), _int(20), _int(30), _int(40)]
        pair = _pair(
            ("int", "int", "int"),
            _rows([ids, flag, values]),
            ("int", "int", "int"),
            ("ID", "Flag", "Value"),
            _rows([ids, flag, values]),
        )
        links = align(pair)
        self.assertEqual([link.kind for link in links], ["neo", "interpolated", "neo"])
        self.assertEqual(links[1].legacy_name, "Flag")
        self.assertIn("nội suy: cột gốc 1", link_note(links[1]))

    def test_varied_column_between_anchors_stays_new(self) -> None:
        ids = [_int(1), _int(2), _int(3), _int(4)]
        left = [_int(10), _int(20), _int(30), _int(40)]
        right = [_int(100), _int(200), _int(300), _int(400)]
        pair = _pair(
            ("int", "int", "int"),
            _rows([ids, left, ids]),
            ("int", "int", "int"),
            ("ID", "Khác", "ID2"),
            _rows([ids, right, ids]),
        )
        links = align(pair)
        self.assertEqual([link.kind for link in links], ["neo", "new", "neo"])
        self.assertEqual(link_note(links[1]), "mới ở 2026")
        summary = summarize("Pet.txt", links, pair.names_old)
        self.assertEqual(summary.lost_list, "1:Khác")

    def test_type_change_between_anchors_needs_99_percent(self) -> None:
        ids = [_int(1), _int(2), _int(3), _int(4)]
        flag_new = [_int(7), _int(8), _int(9), _int(10)]
        flag_old = [_text("7"), _text("8"), _text("9"), _text("10")]
        values = [_int(10), _int(20), _int(30), _int(40)]
        pair = _pair(
            ("int", "int", "int"),
            _rows([ids, flag_new, values]),
            ("int", "text", "int"),
            ("ID", "Cờ", "Value"),
            _rows([ids, flag_old, values]),
        )
        links = align(pair)
        self.assertEqual(links[1].kind, "retyped")
        self.assertEqual(links[1].legacy_index, 1)
        self.assertIn("đổi kiểu: cột gốc 1", link_note(links[1]))

    def test_two_distinct_values_are_not_anchors(self) -> None:
        flag = [_int(1), _int(1), _int(2), _int(2)]
        pair = _pair(("int",), _rows([flag]), ("int",), ("Flag",), _rows([flag]))
        links = align(pair)
        self.assertEqual(links[0].kind, "new")
        summary = summarize("Pet.txt", links, pair.names_old)
        self.assertEqual(summary.lost, 1)
        self.assertEqual(summary.lost_list, "0:Flag")

    def test_ninety_five_percent_is_an_anchor_and_ninety_is_not(self) -> None:
        matched = [_int(value) for value in range(20)]
        almost = list(matched)
        almost[0] = _int(1000)
        pair = _pair(("int",), _rows([matched]), ("int",), ("Value",), _rows([almost]))
        self.assertEqual(align(pair)[0].kind, "neo")
        weaker = list(matched)
        weaker[0] = _int(1000)
        weaker[1] = _int(1001)
        pair = _pair(("int",), _rows([matched]), ("int",), ("Value",), _rows([weaker]))
        self.assertEqual(align(pair)[0].kind, "new")

    def test_identical_columns_keep_order(self) -> None:
        column = [_int(1), _int(2), _int(3), _int(4)]
        pair = _pair(("int", "int"), _rows([column, column]), ("int", "int"), ("A", "B"), _rows([column, column]))
        links = align(pair)
        self.assertEqual([link.kind for link in links], ["neo", "neo"])
        self.assertEqual([link.legacy_index for link in links], [0, 1])

    def test_crossed_pair_is_recorded_when_each_side_is_unique(self) -> None:
        left = [_int(1), _int(2), _int(3), _int(4)]
        right = [_int(10), _int(20), _int(30), _int(40)]
        pair = _pair(("int", "int"), _rows([left, right]), ("int", "int"), ("Right", "Left"), _rows([right, left]))
        links = align(pair)
        self.assertEqual([link.kind for link in links], ["neo", "cross"])
        self.assertEqual(links[0].legacy_index, 1)
        self.assertEqual(links[1].legacy_index, 0)
        self.assertIn("chéo: cột gốc 0", link_note(links[1]))
        summary = summarize("Pet.txt", links, pair.names_old)
        self.assertEqual(summary.anchors, 2)
        self.assertEqual(summary.lost, 0)

    def test_trailing_legacy_column_is_lost(self) -> None:
        ids = [_int(1), _int(2), _int(3), _int(4)]
        values = [_int(10), _int(20), _int(30), _int(40)]
        noise = [_int(100), _int(200), _int(300), _int(400)]
        pair = _pair(
            ("int", "int"),
            _rows([ids, values]),
            ("int", "int", "int"),
            ("ID", "Value", "Noise"),
            _rows([ids, values, noise]),
        )
        summary = summarize("Pet.txt", align(pair), pair.names_old)
        self.assertEqual(summary.lost, 1)
        self.assertEqual(summary.lost_list, "2:Noise")
        self.assertEqual(summary.anchors, 2)


class TermFileTest(unittest.TestCase):
    def test_real_terms_have_the_hand_shape(self) -> None:
        path = ROOT / "column_terms.tsv"
        text = path.read_text(encoding="utf-8")
        self.assertIn("# schema 1\n", text)
        self.assertIn("# types: text\ttext\ttext\ttext\ttext\n", text)
        self.assertNotIn("# tool:", text)
        terms = align_columns.read_terms(path)
        keys = [(term.original, term.scope) for term in terms]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertGreater(len(terms), 0)

    def test_duplicate_original_and_bad_basis_are_errors(self) -> None:
        root = Path("build") / "p1-a" / "terms"
        root.mkdir(parents=True, exist_ok=True)
        header = (
            "# schema 1\n# types: text\ttext\ttext\ttext\ttext\n"
            "original\tscope\tname\tbasis\tnote\n"
        )
        bad_basis = root / "bad-basis.tsv"
        bad_basis.write_text(header + "甲\t\tname\tguess\tthử\n", encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError):
            align_columns.read_terms(bad_basis)
        duplicate = root / "duplicate.tsv"
        body = "甲\tShop.txt\tname\tdirect\tmột\n甲\tShop.txt\tother\tdirect\thai\n"
        duplicate.write_text(header + body, encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError):
            align_columns.read_terms(duplicate)
        paired = root / "two-scopes.tsv"
        scopes = "甲\tA.txt\tone\tdirect\t\n甲\tB.txt\ttwo\tdirect\t\n"
        paired.write_text(header + scopes, encoding="utf-8", newline="\n")
        loaded = align_columns.read_terms(paired)
        self.assertEqual([(item.scope, item.name) for item in loaded], [("A.txt", "one"), ("B.txt", "two")])
        mismatch = root / "mismatch.tsv"
        mismatch.write_text(header + "甲{n}\t\tname\tdirect\t\n", encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError):
            align_columns.read_terms(mismatch)


if __name__ == "__main__":
    unittest.main()
