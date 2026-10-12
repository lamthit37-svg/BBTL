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
        tsv_file.write_table(path, "x", "export_tables.py", ["int", "int"], ["id", "n"], [("1", "2")])
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
