# Kiểm phần của export_look.py và collect_avatar.py mà màn tạo nhân vật dựa vào: bảng mặt, tóc giữ
# đúng thứ tự tệp gốc (màn tạo đếm vị trí dòng trong từng giới), tên không mang tab hay xuống dòng,
# và danh sách id cần gom lưới gồm mọi thứ chọn được (choice 1 hay 3) kèm dòng cao mô id + 10000.
# Không đụng kho thật.
# Chạy: python -B TOOLS/content/test_export_look.py

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import collect_avatar
import export_look
from export_look import ExportError


class FakeTable:
    """Bảng chỉ có ô chữ, đủ cho name_cell."""

    def __init__(self, cells: dict[tuple[int, int], str]) -> None:
        self.cells = cells

    def text(self, row: int, column: int) -> str:
        return self.cells[(row, column)]


class FileOrder(unittest.TestCase):
    def test_keeps_rows_already_in_key_order(self) -> None:
        rows = [(1, 0, "a.mesh", "Một", 3), (1, 1, "b.mesh", "Một", 3), (2, 0, "c.mesh", "Hai", 0)]
        self.assertIs(export_look.keep_file_order(rows, "CharFaceGeo"), rows)

    def test_empty_table_is_in_order(self) -> None:
        self.assertEqual(export_look.keep_file_order([], "CharFaceGeo"), [])

    def test_rejects_rows_out_of_order(self) -> None:
        rows = [(2, 0, "c.mesh", "Hai", 0), (1, 0, "a.mesh", "Một", 3)]
        with self.assertRaisesRegex(ExportError, "CharFaceGeo"):
            export_look.keep_file_order(rows, "CharFaceGeo")

    def test_rejects_race_out_of_order_within_one_id(self) -> None:
        rows = [(1, 1, "b.mesh", "Một", 3), (1, 0, "a.mesh", "Một", 3)]
        with self.assertRaises(ExportError):
            export_look.keep_file_order(rows, "CharHairGeo")

    def test_rejects_repeated_key(self) -> None:
        rows = [(1, 0, "a.mesh", "Một", 3), (1, 0, "b.mesh", "Một", 3)]
        with self.assertRaisesRegex(ExportError, "khoá lặp"):
            export_look.keep_file_order(rows, "CharHairGeo")


class NameCell(unittest.TestCase):
    def test_returns_plain_name(self) -> None:
        table = FakeTable({(4, 6): "游仙发"})
        self.assertEqual(export_look.name_cell(table, 4, 6, "CharHairGeo"), "游仙发")

    def test_empty_name_is_allowed(self) -> None:
        self.assertEqual(export_look.name_cell(FakeTable({(0, 4): ""}), 0, 4, "CharFaceGeo"), "")

    def test_rejects_marks_that_break_a_tsv_cell(self) -> None:
        for mark in ("\t", "\n", "\r"):
            table = FakeTable({(7, 4): "tên" + mark + "sau"})
            with self.assertRaisesRegex(ExportError, "dòng 7"):
                export_look.name_cell(table, 7, 4, "CharFaceGeo")


class CreationIds(unittest.TestCase):
    ROWS = {
        ("1", "0"): {"choice": "3"},
        ("2", "0"): {"choice": "0"},
        ("14", "0"): {"choice": "1"},
        ("100", "1"): {"choice": "3"},
        ("10001", "0"): {"choice": "-1"},
    }

    def test_lists_creatable_ids_with_their_high_poly_rows(self) -> None:
        self.assertEqual(collect_avatar.creation_ids(self.ROWS, "0"), ["1", "10001", "14", "10014"])

    def test_other_sex_is_separate(self) -> None:
        self.assertEqual(collect_avatar.creation_ids(self.ROWS, "1"), ["100", "10100"])

    def test_no_rows_no_ids(self) -> None:
        self.assertEqual(collect_avatar.creation_ids({}, "0"), [])
        self.assertEqual(collect_avatar.creation_ids(self.ROWS, "2"), [])


if __name__ == "__main__":
    unittest.main()
