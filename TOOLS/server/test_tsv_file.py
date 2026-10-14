# Kiểm hợp đồng ghi và đọc TSV: từ chối ô làm mất dữ liệu khi parse_tsv đọc, ghi nguyên tử.
from __future__ import annotations

import os
import shutil
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import tsv_file


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-l-tsv" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


class WriteTableTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_roundtrip_and_bytes(self) -> None:
        path = self.root / "skills.tsv"
        rows = [("1", "0.5", "a"), ("2", "", "b")]
        tsv_file.write_table(
            path,
            "client_2026/SkillTemplate_V1.txt",
            "export_tables.py",
            ["int", "float", "text"],
            ["id", "ratio", "label"],
            rows,
        )
        data = path.read_bytes()
        self.assertFalse(data.startswith(b"\xef\xbb\xbf"))
        self.assertNotIn(b"\r", data)
        self.assertTrue(data.endswith(b"\n"))
        table = tsv_file.read_table(path)
        self.assertEqual(table.source, "client_2026/SkillTemplate_V1.txt")
        self.assertEqual(table.tool, "TOOLS/server/export_tables.py")
        self.assertEqual(table.types, ("int", "float", "text"))
        self.assertEqual(table.columns, ("id", "ratio", "label"))
        self.assertEqual(table.rows, tuple(rows))
        again = self.root / "skills2.tsv"
        tsv_file.write_table(
            again,
            "client_2026/SkillTemplate_V1.txt",
            "TOOLS/server/export_tables.py",
            ["int", "float", "text"],
            ["id", "ratio", "label"],
            rows,
        )
        self.assertEqual(path.read_bytes(), again.read_bytes())
        self.assertEqual(list(self.root.glob("*.tmp")), [])

    def test_zero_rows(self) -> None:
        path = self.root / "empty.tsv"
        tsv_file.write_table(path, "client_2026/WeekShopCommon.txt", "export_tables.py", ["int"], ["id"], [])
        table = tsv_file.read_table(path)
        self.assertEqual(table.rows, ())

    def test_reject_bad_column(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text"], ["Column"], [("a",)])
        self.assertFalse(path.exists())

    def test_reject_duplicate_column(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["int", "int"], ["id", "id"], [])

    def test_reject_tab_in_cell(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text"], ["label"], [("a\tb",)])
        self.assertFalse(path.exists())

    def test_reject_break_in_cell(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text", "text"], ["a", "b"], [("x", "y\n")])
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text", "text"], ["a", "b"], [("x", "y\r")])

    def test_reject_hash_first_cell(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text", "int"], ["label", "n"], [("#an", "1")])

    def test_reject_empty_single_column(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["text"], ["label"], [("ok",), ("",)])

    def test_allow_empty_middle_cell(self) -> None:
        path = self.root / "ok.tsv"
        tsv_file.write_table(path, "x", "export_tables.py", ["int", "text"], ["id", "label"], [("1", "")])
        table = tsv_file.read_table(path)
        self.assertEqual(table.rows, (("1", ""),))

    def test_reject_width(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["int", "int"], ["id", "n"], [("1",)])

    def test_reject_type(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["string"], ["label"], [])

    def test_reject_non_string_cell(self) -> None:
        path = self.root / "bad.tsv"
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["int"], ["id"], [(1,)])

    def test_refuse_foreign_replace(self) -> None:
        path = self.root / "hand.tsv"
        path.write_text("id\n1\n", encoding="utf-8", newline="\n")
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.write_table(path, "x", "export_tables.py", ["int"], ["id"], [("2",)])
        self.assertEqual(path.read_text(encoding="utf-8"), "id\n1\n")

    def test_replace_owned(self) -> None:
        path = self.root / "owned.tsv"
        tsv_file.write_table(path, "a", "export_tables.py", ["int"], ["id"], [("1",)])
        self.assertEqual(tsv_file.owned_tool(path), "TOOLS/server/export_tables.py")
        tsv_file.write_table(path, "a", "export_tables.py", ["int"], ["id"], [("2",)])
        self.assertEqual(tsv_file.read_table(path).rows, (("2",),))


class ReadTableTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _owned(self, name: str, body: str) -> Path:
        path = self.root / name
        path.write_bytes(body.encode("utf-8"))
        return path

    def test_reject_bad_utf8(self) -> None:
        path = self.root / "bad.tsv"
        path.write_bytes(b"\xff\xfe")
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_table(path)

    def test_reject_crlf(self) -> None:
        text = (
            "# schema 1\r\n"
            "# source: x\r\n"
            "# tool: TOOLS/server/export_tables.py; sửa tay sẽ mất ở lượt xuất sau\r\n"
            "# types: int\r\n"
            "id\r\n"
            "1\r\n"
        )
        path = self._owned("cr.tsv", text)
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_table(path)

    def test_reject_short_row(self) -> None:
        path = self.root / "short.tsv"
        tsv_file.write_table(path, "x", "export_tables.py", ["int", "int"], ["id", "n"], [("1", "2")], layout="plain")
        raw = path.read_bytes().replace(b"1\t2\n", b"1\n")
        path.write_bytes(raw)
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_table(path)

    def test_reject_wrong_schema(self) -> None:
        path = self.root / "schema.tsv"
        tsv_file.write_table(path, "x", "export_tables.py", ["int"], ["id"], [("1",)])
        raw = path.read_bytes().replace(b"# schema 1", b"# schema 2")
        path.write_bytes(raw)
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_table(path)


class AlignedTableTest(unittest.TestCase):
    """Bố cục căn cột: đệm dấu cách trước tab, dấu cách cuối thật thành ký hiệu, đọc lại ra đúng ô."""

    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def write(self, rows: list[tuple[str, ...]], columns: list[str], types: list[str]) -> Path:
        path = self.root / "t.tsv"
        tool = "TOOLS/server/lua_extract.py"
        tsv_file.write_table(path, "Public/Data/Script", tool, types, columns, rows, layout="aligned")
        return path

    def test_columns_line_up_by_display_width(self) -> None:
        path = self.write([("1", "帮会大总管", "x"), ("22", "ab", "y")], ["id", "name", "tail"], ["int", "text", "text"])
        lines = path.read_text(encoding="utf-8").split("\n")
        self.assertEqual(lines[4], "# layout: aligned")
        body = [line.split("\t") for line in lines[5:8]]
        for column in (0, 1):
            self.assertEqual(len({tsv_file.display_width(row[column]) for row in body}), 1)
        self.assertEqual(body[1][2], "x")
        self.assertEqual(tsv_file.display_width(body[0][1]), 10 + tsv_file.ALIGN_GAP)

    def test_roundtrip_trailing_spaces_and_empty_cells(self) -> None:
        rows = [("1", "  lead and trail  ", ""), ("2", " ", "end "), ("3", "", "")]
        path = self.write(rows, ["id", "a", "b"], ["int", "text", "text"])
        text = path.read_text(encoding="utf-8")
        self.assertIn("trail" + tsv_file.SPACE_MARK * 2, text)
        table = tsv_file.read_table(path)
        self.assertEqual(table.layout, "aligned")
        self.assertEqual(table.columns, ("id", "a", "b"))
        self.assertEqual(table.rows, tuple(rows))

    def test_split_rows_matches_read_table(self) -> None:
        rows = [("1", "  lead and trail  ", ""), ("2", " ", "end "), ("3", "", "")]
        path = self.write(rows, ["id", "a", "b"], ["int", "text", "text"])
        cells = tsv_file.split_rows(path.read_text(encoding="utf-8"))
        self.assertEqual(cells[0], ["id", "a", "b"])
        self.assertEqual([tuple(row) for row in cells[1:]], rows)
        plain = "# schema 1\nid\tn\n1\tx \n"
        self.assertEqual(tsv_file.split_rows(plain), [["id", "n"], ["1", "x "]])
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.split_rows("# layout: wide\nid\n1\n")

    def test_reject_space_mark_in_data(self) -> None:
        with self.assertRaises(tsv_file.TsvError):
            self.write([("1", "a" + tsv_file.SPACE_MARK, "b")], ["id", "a", "b"], ["int", "text", "text"])

    def test_reject_unknown_layout(self) -> None:
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.render_table("s", "TOOLS/server/x.py", ["text"], ["a"], [("1",)], layout="wide")
        path = self.root / "bad.tsv"
        path.write_text("# schema 1\n# source: s\n# tool: TOOLS/server/x.py" + tsv_file.TOOL_SUFFIX
                        + "\n# types: text\n# layout: wide\na\n1\n", encoding="utf-8")
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_table(path)

    def test_auto_aligns_small_and_leaves_large_plain(self) -> None:
        columns, types = ["id", "name"], ["int", "text"]
        rows = [("1", "a"), ("22", "bb")]
        small = tsv_file.render_table("s", "TOOLS/server/x.py", types, columns, rows)
        self.assertIn(tsv_file.LAYOUT_PREFIX + "aligned", small)
        original = tsv_file.ALIGN_LIMIT
        tsv_file.ALIGN_LIMIT = 10
        try:
            plain = tsv_file.render_table("s", "TOOLS/server/x.py", types, columns, rows)
        finally:
            tsv_file.ALIGN_LIMIT = original
        self.assertNotIn(tsv_file.LAYOUT_PREFIX, plain)
        self.assertEqual(plain.split("\n")[4:], ["id\tname", "1\ta", "22\tbb", ""])

    def test_auto_falls_back_for_space_mark(self) -> None:
        text = tsv_file.render_table("s", "TOOLS/server/x.py", ["text"], ["a"], [("x" + tsv_file.SPACE_MARK,)])
        self.assertNotIn(tsv_file.LAYOUT_PREFIX, text)

    def test_plain_table_keeps_spaces(self) -> None:
        path = self.root / "p.tsv"
        tsv_file.write_table(path, "s", "TOOLS/server/x.py", ["text", "text"], ["a", "b"], [("x  ", "y")])
        self.assertEqual(tsv_file.read_table(path).rows, (("x  ", "y"),))


class DirectoryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_foreign_blocks_delete(self) -> None:
        owned = self.root / "a.tsv"
        tsv_file.write_table(owned, "x", "export_tables.py", ["int"], ["id"], [("1",)])
        foreign = self.root / "note.txt"
        foreign.write_text("giữ\n", encoding="utf-8", newline="\n")
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.prepare_directory(self.root, "export_tables.py")
        self.assertTrue(owned.exists())
        self.assertTrue(foreign.exists())

    def test_keep_tools_leaves_named_tool(self) -> None:
        mine = self.root / "a.tsv"
        other = self.root / "b.tsv"
        tsv_file.write_table(mine, "x", "export_tables.py", ["int"], ["id"], [("1",)])
        tsv_file.write_table(other, "x", "scene_refs.py", ["int"], ["id"], [("2",)])
        tsv_file.prepare_directory(self.root, "export_tables.py", keep_tools=("scene_refs.py",))
        self.assertFalse(mine.exists())
        self.assertTrue(other.exists())

    def test_other_tool_is_foreign(self) -> None:
        mine = self.root / "a.tsv"
        other = self.root / "b.tsv"
        tsv_file.write_table(mine, "x", "export_tables.py", ["int"], ["id"], [("1",)])
        tsv_file.write_table(other, "x", "import_legacy.py", ["int"], ["id"], [("1",)])
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.prepare_directory(self.root, "export_tables.py")
        self.assertTrue(mine.exists())
        self.assertTrue(other.exists())

    def test_own_binary_removed(self) -> None:
        path = self.root / "a.tsv"
        binary = self.root / "walk.nav"
        tsv_file.write_table(path, "x", "export_scene.py", ["int"], ["id"], [("1",)])
        binary.write_bytes(b"\x00\x01")
        tsv_file.prepare_directory(self.root, "export_scene.py", own_binaries=["walk.nav"])
        self.assertFalse(path.exists())
        self.assertFalse(binary.exists())

    def test_unlisted_binary_is_foreign(self) -> None:
        path = self.root / "a.tsv"
        binary = self.root / "walk.nav"
        tsv_file.write_table(path, "x", "export_scene.py", ["int"], ["id"], [("1",)])
        binary.write_bytes(b"\x00\x01")
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.prepare_directory(self.root, "export_scene.py")
        self.assertTrue(path.exists())
        self.assertTrue(binary.exists())

    def test_clean_then_empty(self) -> None:
        path = self.root / "a.tsv"
        tsv_file.write_table(path, "x", "export_tables.py", ["int"], ["id"], [("1",)])
        tsv_file.prepare_directory(self.root, "export_tables.py")
        self.assertFalse(path.exists())
        self.assertTrue(self.root.is_dir())


class Float32Test(unittest.TestCase):
    def test_common_values(self) -> None:
        cases = {0x00000000: "0", 0x3F800000: "1", 0xBF800000: "-1", 0x3F000000: "0.5"}
        for bits, text in cases.items():
            self.assertEqual(tsv_file.format_float32(bits), text)
            back = struct.unpack("<I", struct.pack("<f", float(text)))[0]
            self.assertEqual(back, bits)

    def test_roundtrip_odd_value(self) -> None:
        bits = struct.unpack("<I", struct.pack("<f", 0.1))[0]
        text = tsv_file.format_float32(bits)
        back = struct.unpack("<I", struct.pack("<f", float(text)))[0]
        self.assertEqual(back, bits)
        self.assertNotIn(" ", text)
        self.assertNotIn("+", text)

    def test_largest_finite(self) -> None:
        cases = {
            0x7F7FFFFF: "3.4028235e+38",
            0xFF7FFFFF: "-3.4028235e+38",
            0x7F7FFFFE: "3.4028233e+38",
        }
        for bits, text in cases.items():
            self.assertEqual(tsv_file.format_float32(bits), text)
            back = struct.unpack("<I", struct.pack("<f", float(text)))[0]
            self.assertEqual(back, bits)

    def test_reject_special(self) -> None:
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.format_float32(0x7FC00000)
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.format_float32(0x7F800000)
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.format_float32(True)  # type: ignore[arg-type]


class NameMapTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_reject_bad_fate(self) -> None:
        path = self.root / "names.tsv"
        header = "tree\tsource\tfate\ttarget\tkey_field\tkey\towner\tunresolved\tnote\n"
        row = "server_config\ta.txt\tnope\t\t\t\t\t0\t\n"
        path.write_bytes((header + row).encode("utf-8"))
        with self.assertRaises(tsv_file.TsvError):
            tsv_file.read_name_map(path)

    def test_project_map_loads(self) -> None:
        rows = tsv_file.read_name_map()
        self.assertGreater(len(rows), 0)
        trees = {row.tree for row in rows}
        self.assertTrue(trees <= {"server_config", "public_config", "public_data", "client_2026"})


if __name__ == "__main__":
    unittest.main()
