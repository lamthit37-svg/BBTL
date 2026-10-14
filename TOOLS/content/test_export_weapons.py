# Kiểm phần của export_weapons.py mà ngoại hình vũ khí dựa vào: loại vũ khí theo nType của vật phẩm (30 tới 35
# cùng nhóm với 0 tới 5, giá trị khác là none), tra mẫu không phân biệt hoa thường ASCII với mẫu đầu thắng khi tên
# lặp (client gốc nạp bằng std::map::insert), locator có số không hữu hạn bị bỏ, Scale đọc thành ba ô, và hiệu ứng
# đồ (cờ đá quý của ba khe sau, 34 ô hiệu ứng theo thứ tự cột, đá quý có màu chuỗi).
# Không đụng kho thật.
# Chạy: python -B TOOLS/content/test_export_weapons.py

from __future__ import annotations

import sys
import unittest
import xml.etree.ElementTree as ElementTree
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import export_weapons
from export_look import ExportError, ObjectBook


def book_of(text: str) -> ObjectBook:
    book = ObjectBook.__new__(ObjectBook)
    book.root = ElementTree.fromstring(text)
    book.by_name = {}
    for item in book.root.iter("Object"):
        book.by_name.setdefault(item.get("name"), []).append(item)
    return book


class WeaponClass(unittest.TestCase):
    def test_six_held_classes(self) -> None:
        names = [export_weapons.class_of(kind) for kind in range(6)]
        self.assertEqual(names, ["blade", "spear", "short", "dual_short", "fan", "ring"])

    def test_thirty_range_folds_onto_base(self) -> None:
        self.assertEqual([export_weapons.class_of(kind) for kind in range(30, 36)],
                         ["blade", "spear", "short", "dual_short", "fan", "ring"])

    def test_other_values_are_none(self) -> None:
        for kind in (-1, 6, 12, 29, 36, 99):
            self.assertEqual(export_weapons.class_of(kind), "none", kind)


class Templates(unittest.TestCase):
    def test_fold_is_ascii_only(self) -> None:
        self.assertEqual(export_weapons.fold("Dweapon_2021一级.obj"), "dweapon_2021一级.obj")

    def test_case_insensitive_lookup_and_first_wins(self) -> None:
        text = ('<Root><Object name="dweapon_x.obj"><Entity file="a.mesh"/></Object>'
                '<Object name="Dweapon_X.obj"><Entity file="b.mesh"/></Object></Root>')
        found = export_weapons.Templates(book_of(text)).find("DWEAPON_x.obj")
        self.assertIsNotNone(found)
        self.assertEqual(export_weapons.mesh_files(found), ["a.mesh"])

    def test_missing_template_is_none(self) -> None:
        self.assertIsNone(export_weapons.Templates(book_of("<Root/>")).find("x.obj"))


class Locators(unittest.TestCase):
    OBJECT = ('<Object name="m.obj"><Locators>'
              '<Locator name="a" bonename="B" x="1" y="2" z="3" qx="0" qy="0" qz="1" qw="-1.5" translateFirst="true">'
              '<Slot name="RightWeaponObj"/></Locator>'
              '<Locator name="nan" bonename="" x="0" y="0" z="0" qx="1" qy="0" qz="0" qw="1.#QNAN"/>'
              '</Locators></Object>')

    def test_nan_locator_is_dropped_and_reported(self) -> None:
        dropped: list = []
        rows = export_weapons.locator_rows(ElementTree.fromstring(self.OBJECT), dropped)
        self.assertEqual([row[0] for row in rows], ["a"])
        self.assertEqual(dropped, ["m.obj/nan"])

    def test_row_keeps_text_slot_and_flag(self) -> None:
        rows = export_weapons.locator_rows(ElementTree.fromstring(self.OBJECT), [])
        self.assertEqual(rows[0], ("a", "B", "1", "2", "3", "0", "0", "1", "-1.5", 1, "RightWeaponObj"))


class FakeTable:
    """Bảng giả có cùng giao diện cell, integer, rows với dbc.Table."""

    def __init__(self, rows: list) -> None:
        self.data = rows
        self.rows = len(rows)

    def cell(self, row: int, column: int):
        return self.data[row][column]

    def integer(self, row: int, column: int) -> int:
        return int(self.data[row][column])


class GemEffects(unittest.TestCase):
    @staticmethod
    def row_with(effects: dict, flags: dict) -> list:
        cells: list = [0] * 63
        for column, name in effects.items():
            cells[column] = name
        for column, value in flags.items():
            cells[column] = value
        return cells

    def test_flags_and_ordered_slots(self) -> None:
        table = FakeTable([self.row_with({29: "a", 31: "c", 62: "z", 40: "0", 41: "-1"}, {19: "1", 23: 0, 27: "1"})])
        flags, joined = export_weapons.effects_of(table, 0)
        self.assertEqual(flags, (1, 0, 1))
        names = joined.split(";")
        self.assertEqual(len(names), export_weapons.EFFECT_COUNT)
        self.assertEqual((names[0], names[1], names[2], names[33]), ("a", "", "c", "z"))
        self.assertEqual(names[11], "", "ô 0 và -1 là không có")

    def test_empty_row_joins_to_separators_only(self) -> None:
        _, joined = export_weapons.effects_of(FakeTable([self.row_with({}, {})]), 0)
        self.assertEqual(joined.strip(";"), "")

    def test_gems_keep_only_string_colours(self) -> None:
        class Sources:
            @staticmethod
            def table(name: str) -> FakeTable:
                self_rows = []
                for gem, colour, effect in ((1, "FFFFFF09", 3), (2, -1, 7), (3, "00112233", 12)):
                    cells: list = [0] * 84
                    cells[0], cells[export_weapons.GEM_COLOUR], cells[export_weapons.GEM_EFFECT] = gem, colour, effect
                    self_rows.append(cells)
                return FakeTable(self_rows)

        gems = export_weapons.read_gems(Sources())
        self.assertEqual(gems, [(1, "FFFFFF09", 3), (3, "00112233", 12)])


class Scale(unittest.TestCase):
    def test_default_is_unit(self) -> None:
        self.assertEqual(export_weapons.scale_of(ElementTree.fromstring('<Object name="a"/>')), ("1", "1", "1"))

    def test_reads_three_parts(self) -> None:
        template = ElementTree.fromstring('<Object name="a"><Attribute name="Scale" value="0.9 0.8 0.9"/></Object>')
        self.assertEqual(export_weapons.scale_of(template), ("0.9", "0.8", "0.9"))

    def test_rejects_wrong_shape(self) -> None:
        for value in ("1 1", "0 1 1", "-1 1 1"):
            template = ElementTree.fromstring(f'<Object name="a"><Attribute name="Scale" value="{value}"/></Object>')
            with self.assertRaises(ExportError, msg=value):
                export_weapons.scale_of(template)


if __name__ == "__main__":
    unittest.main()
