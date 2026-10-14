# Kiểm xuất DBC: từ chối ô làm mất dòng, căn tên cột khi bố cục bản 0859602 khác.
from __future__ import annotations

import io
import os
import shutil
import struct
import subprocess
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import export_tables
import tsv_file

CONTENT = ROOT.parent / "content"
if str(CONTENT) not in sys.path:
    sys.path.insert(0, str(CONTENT))

import dbc

MAGIC = 0xDDBBCC00
NAMES = (
    "tree\tsource\tfate\ttarget\tkey_field\tkey\towner\tunresolved\tnote\n"
)


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-a" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _names(path: Path, rows: list[tuple[str, ...]]) -> None:
    body = "".join("\t".join(row) + "\n" for row in rows)
    path.write_bytes((NAMES + body).encode("utf-8"))


def _dbc(path: Path, kinds: list[int], rows: list[list[int]], strings: bytes = b"\0") -> None:
    if not strings or strings[-1] != 0:
        strings += b"\0"
    header = struct.pack("<IIII", MAGIC, len(kinds), len(rows), len(strings))
    types = struct.pack("<" + "I" * len(kinds), *kinds)
    cells = b"".join(struct.pack("<" + "I" * len(kinds), *row) for row in rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + types + cells + strings)


def _legacy(path: Path, types: list[str], names: list[str], rows: list[list[str]]) -> None:
    lines = ["\t".join(types), "\t".join(names)]
    lines.extend("\t".join(row) for row in rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(("\r\n".join(lines) + "\r\n").encode("utf-8"))


def _run(argv: list[str]) -> tuple[int, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    with redirect_stdout(stdout), redirect_stderr(stderr):
        code = export_tables.main(argv)
    return code, stdout.getvalue() + stderr.getvalue()


class EnglishNameTest(unittest.TestCase):
    def test_ascii_snake_and_glossary(self) -> None:
        self.assertEqual(export_tables.english_name("ID"), ("id", False))
        self.assertEqual(export_tables.english_name("MenPai"), ("sect", False))
        self.assertEqual(export_tables.english_name("AbilityId"), ("life_skill_id", False))
        self.assertEqual(export_tables.english_name("门派"), ("sect", False))
        self.assertEqual(export_tables.english_name("KFS"), ("martial_soul", True))
        self.assertEqual(export_tables.english_name("MissionID"), ("mission_id", False))
        self.assertEqual(export_tables.english_name("名称$1$"), (None, False))
        self.assertEqual(export_tables.english_name("nLevel"), ("n_level", False))


class ExportCollectTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.raw = self.root / "raw"
        self.legacy = self.root / "tlbb"
        self.tables = self.root / "tables"
        self.columns = self.root / "columns"
        self.names = self.root / "names.tsv"
        self.config = self.raw / "Config"

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _export(self, write: bool = True) -> export_tables.ExportResult:
        return export_tables.collect(self.raw, self.legacy, self.tables, self.names, self.columns, write=write)

    def test_roundtrip_int_float_text(self) -> None:
        bits = struct.unpack("<I", struct.pack("<f", 0.1))[0]
        _dbc(self.config / "Odd.txt", [0, 1, 2], [[0xFFFFFFFF, bits, 0]], "剑\0".encode("gb18030"))
        _names(self.names, [("client_2026", "Odd.txt", "table", "tables/shared/odd.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "odd.tsv")
        self.assertEqual(table.source, "client_2026/Odd.txt")
        self.assertEqual(table.types, ("int", "float", "text"))
        self.assertEqual(table.columns, ("column_0", "column_1", "column_2"))
        self.assertEqual(table.rows, (("-1", tsv_file.format_float32(bits), "剑"),))
        columns = tsv_file.read_table(self.columns / "odd.tsv")
        self.assertEqual(columns.rows[0][1], "")
        self.assertIn("không có bản đối chiếu", columns.rows[0][4])

    def test_names_from_matching_legacy(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 0], [[1, 10], [2, 20]])
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10"], ["2", "21"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("id", "sect"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertEqual(notes.rows[0][1], "ID")
        self.assertIn("khớp 100.0% (2/2 id)", notes.rows[0][4])
        self.assertIn("khớp 50.0% (1/2 id)", notes.rows[1][4])
        self.assertEqual(result.named_columns, 2)
        self.assertEqual(result.question_columns, 0)

    def test_empty_legacy_id_is_counted(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 0], [[1, 10], [2, 20]])
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "Value"],
            [["1", "10"], ["2", "20"], ["", "999"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        self.assertTrue(any("ô đầu rỗng" in note for note in result.notices))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertIn("khớp 100.0% (2/2 id)", notes.rows[0][4])
        self.assertNotIn("999", notes.rows[1][4])

    def test_legacy_float_overflow_is_an_error_line(self) -> None:
        _dbc(self.config / "Odd.txt", [0, 1], [[1, 0]])
        _legacy(
            self.legacy / "Public" / "Config" / "Odd.txt",
            ["INT", "FLOAT"],
            ["ID", "Value"],
            [["1", "1e308"]],
        )
        _names(self.names, [("client_2026", "Odd.txt", "table", "tables/shared/odd.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("Odd.txt:" in error and "float32" in error for error in result.errors))
        self.assertEqual(result.written, ())
        self.assertFalse((self.tables / "shared" / "odd.tsv").exists())

    def test_fractional_legacy_id_still_pairs(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 0], [[1, 10]])
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "Value"],
            [["1.0", "10"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertNotIn("không có id chung", notes.rows[0][4])
        self.assertIn("khớp 100.0% (1/1 id)", notes.rows[1][4])
        self.assertTrue(any("không phải số nguyên thuần" in note for note in result.notices))

    def test_layout_mismatch_keeps_default_names(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 2], [[1, 0]], b"a\0")
        _legacy(self.legacy / "Public" / "Config" / "Pet.txt", ["INT", "INT"], ["ID", "MenPai"], [["1", "2"]])
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("column_0", "column_1"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertIn("mới ở 2026", notes.rows[0][4])
        self.assertNotIn("?", notes.rows[0][4])

    def test_unknown_chinese_marks_question(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 2], [[1, 0]], "甲\0".encode("gb18030"))
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "STRING"],
            ["ID", "试探列甲"],
            [["1", "甲"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertEqual(notes.rows[1][1], "试探列甲")
        self.assertEqual(notes.rows[1][2], "column_1")
        self.assertIn("?", notes.rows[1][4])
        self.assertEqual(result.question_columns, 1)
        self.assertEqual(result.named_columns, 1)

    def test_variant_directory(self) -> None:
        _dbc(self.config / "ShopTable_KaJi.txt", [0], [[3]])
        _names(
            self.names,
            [
                (
                    "client_2026",
                    "ShopTable_KaJi.txt",
                    "table",
                    "tables/variants/level_cap/shops.tsv",
                    "variant",
                    "level_cap",
                    "A",
                    "0",
                    "",
                )
            ],
        )
        result = self._export()
        self.assertEqual(result.errors, ())
        self.assertTrue((self.tables / "variants" / "level_cap" / "shops.tsv").is_file())
        self.assertTrue((self.columns / "variants" / "level_cap" / "shops.tsv").is_file())

    def test_client_only_is_not_exported(self) -> None:
        _dbc(self.config / "StrDictionary.txt", [0], [[1]])
        _names(self.names, [("client_2026", "StrDictionary.txt", "client_only", "", "", "", "", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        self.assertEqual(result.written, ())
        self.assertFalse(self.tables.exists() and any(self.tables.rglob("*.tsv")))

    def test_one_error_writes_nothing_and_keeps_previous(self) -> None:
        _dbc(self.config / "Also.txt", [0], [[9]])
        _names(self.names, [("client_2026", "Also.txt", "table", "tables/shared/also.tsv", "", "", "A", "0", "")])
        clean = self._export()
        self.assertEqual(clean.errors, ())
        also = self.tables / "shared" / "also.tsv"
        also_columns = self.columns / "also.tsv"
        table_before = also.read_bytes()
        columns_before = also_columns.read_bytes()
        (self.config / "Also.txt").unlink()
        _dbc(self.config / "Bad.txt", [2], [[0]], b"a\tb\0")
        _dbc(self.config / "Good.txt", [0], [[1]])
        _names(
            self.names,
            [
                ("client_2026", "Bad.txt", "table", "tables/shared/bad.tsv", "", "", "A", "0", ""),
                ("client_2026", "Good.txt", "table", "tables/shared/good.tsv", "", "", "A", "0", ""),
            ],
        )
        result = self._export()
        self.assertTrue(any("Bad.txt" in error and "tab" in error for error in result.errors))
        self.assertEqual(result.written, ())
        self.assertEqual(also.read_bytes(), table_before)
        self.assertEqual(also_columns.read_bytes(), columns_before)
        self.assertFalse((self.tables / "shared" / "bad.tsv").exists())
        self.assertFalse((self.tables / "shared" / "good.tsv").exists())
        self.assertFalse((self.columns / "good.tsv").exists())

    def test_reject_duplicate_id(self) -> None:
        _dbc(self.config / "Dup.txt", [0, 0], [[5, 1], [5, 2]])
        _names(self.names, [("client_2026", "Dup.txt", "table", "tables/shared/dup.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("trùng" in error for error in result.errors))
        self.assertFalse((self.tables / "shared" / "dup.tsv").exists())

    def test_reject_hash_first_cell(self) -> None:
        _dbc(self.config / "Hash.txt", [2, 0], [[0, 1]], b"#an\0")
        _names(self.names, [("client_2026", "Hash.txt", "table", "tables/shared/hash.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("bắt đầu bằng #" in error for error in result.errors))
        self.assertEqual(result.written, ())

    def test_reject_truncated_and_bad_magic(self) -> None:
        short = self.config / "Short.txt"
        short.parent.mkdir(parents=True)
        short.write_bytes(struct.pack("<IIII", MAGIC, 1, 4, 1))
        bad = self.config / "Bad.txt"
        bad.write_bytes(b"this is not dbc!")
        _names(
            self.names,
            [
                ("client_2026", "Short.txt", "table", "tables/shared/short.tsv", "", "", "A", "0", ""),
                ("client_2026", "Bad.txt", "table", "tables/shared/bad.tsv", "", "", "A", "0", ""),
            ],
        )
        result = self._export()
        self.assertTrue(any("tệp cụt" in error for error in result.errors))
        self.assertTrue(any("sai magic" in error for error in result.errors))
        self.assertEqual(result.written, ())

    def test_reject_bad_utf8_reference(self) -> None:
        _dbc(self.config / "Also.txt", [0], [[4]])
        _names(self.names, [("client_2026", "Also.txt", "table", "tables/shared/also.tsv", "", "", "A", "0", "")])
        self._export()
        before = (self.tables / "shared" / "also.tsv").read_bytes()
        (self.config / "Also.txt").unlink()
        _dbc(self.config / "Pet.txt", [0], [[1]])
        legacy = self.legacy / "Public" / "Config" / "Pet.txt"
        legacy.parent.mkdir(parents=True)
        legacy.write_bytes(b"INT\n\xff\n")
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("UTF-8" in error for error in result.errors))
        self.assertEqual(result.written, ())
        self.assertEqual((self.tables / "shared" / "also.tsv").read_bytes(), before)
        self.assertFalse((self.tables / "shared" / "pets.tsv").exists())

    def test_reject_extra_legacy_cell(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 0], [[1, 2]])
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "Level"],
            [["1", "2", "thừa"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("thừa ô" in error for error in result.errors))
        self.assertEqual(result.written, ())
        self.assertFalse((self.tables / "shared" / "pets.tsv").exists())

    def test_numeric_string_column_is_listed_not_retyped(self) -> None:
        _dbc(self.config / "Num.txt", [2], [[0], [3]], b"12\0" + b"30\0")
        _names(self.names, [("client_2026", "Num.txt", "table", "tables/shared/num.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.numeric_strings, ("Num.txt\t0\tcolumn_0",))
        table = tsv_file.read_table(self.tables / "shared" / "num.tsv")
        self.assertEqual(table.types, ("text",))

    def test_foreign_file_blocks_delete(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1]])
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        foreign = self.tables / "shared" / "note.txt"
        foreign.parent.mkdir(parents=True)
        foreign.write_text("giữ\n", encoding="utf-8")
        kept = self.tables / "server" / "effects.tsv"
        kept.parent.mkdir(parents=True)
        kept.write_text("id\n1\n", encoding="utf-8")
        result = self._export()
        self.assertTrue(any("tệp lạ" in error for error in result.errors))
        self.assertTrue(foreign.is_file())
        self.assertEqual(kept.read_text(encoding="utf-8"), "id\n1\n")
        self.assertFalse((self.tables / "shared" / "pets.tsv").exists())

    def test_check_writes_nothing(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1]])
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export(write=False)
        self.assertEqual(result.errors, ())
        self.assertEqual(result.records, 1)
        self.assertFalse(self.tables.exists())
        self.assertFalse(self.columns.exists())

    def test_digest_per_table_with_check_writes_only_digest(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1], [2], [3]])
        _dbc(self.config / "ShopTable_KaJi.txt", [0], [[7]])
        _names(
            self.names,
            [
                ("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", ""),
                (
                    "client_2026",
                    "ShopTable_KaJi.txt",
                    "table",
                    "tables/variants/level_cap/shops.tsv",
                    "variant",
                    "level_cap",
                    "A",
                    "0",
                    "",
                ),
            ],
        )
        out = self.root / "digest" / "per_table.tsv"
        argv = [str(self.raw), str(self.legacy), str(self.tables), "--names", str(self.names)]
        argv.extend(["--columns", str(self.columns), "--check", "--digest-per-table", str(out)])
        code, output = _run(argv)
        self.assertEqual(code, 0, output)
        table = tsv_file.read_table(out)
        self.assertEqual(table.columns, ("target", "kind", "source", "records"))
        self.assertEqual(
            table.rows,
            (
                ("tables/shared/pets.tsv", "shared", "Pet.txt", "3"),
                ("tables/variants/level_cap/shops.tsv", "variants", "ShopTable_KaJi.txt", "1"),
            ),
        )
        self.assertFalse(self.tables.exists())
        self.assertFalse(self.columns.exists())
        self.assertEqual(sorted(path.name for path in out.parent.iterdir()), ["per_table.tsv"])

    def test_digest_per_table_not_written_on_error(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1]])
        (self.config / "stray.txt").write_bytes(b"x")
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        out = self.root / "digest" / "per_table.tsv"
        argv = [str(self.raw), str(self.legacy), str(self.tables), "--names", str(self.names)]
        argv.extend(["--columns", str(self.columns), "--check", "--digest-per-table", str(out)])
        code, _output = _run(argv)
        self.assertEqual(code, 1)
        self.assertFalse(out.parent.exists())

    def test_digest_per_table_not_written_when_alignment_write_fails(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1]])
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        out = self.root / "digest" / "per_table.tsv"
        argv = [str(self.raw), str(self.legacy), str(self.tables), "--names", str(self.names)]
        argv.extend(["--columns", str(self.columns), "--alignment", str(self.root / "alignment.tsv")])
        argv.extend(["--digest-per-table", str(out)])
        failure = OSError("alignment write failed")
        with mock.patch.object(export_tables, "_write_alignment", side_effect=failure) as patched:
            code, output = _run(argv)
        self.assertEqual(patched.call_count, 1)
        self.assertEqual(code, 1, output)
        self.assertIn("alignment write failed", output)
        self.assertFalse(out.exists())
        self.assertFalse(out.parent.exists())

    def test_second_write_matches_bytes(self) -> None:
        _dbc(self.config / "Pet.txt", [0], [[1], [2]])
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        self._export()
        first = (self.tables / "shared" / "pets.tsv").read_bytes()
        self._export()
        self.assertEqual((self.tables / "shared" / "pets.tsv").read_bytes(), first)

    def test_invalid_gb18030(self) -> None:
        _dbc(self.config / "Bad.txt", [2], [[0]], b"\xff\0")
        _names(self.names, [("client_2026", "Bad.txt", "table", "tables/shared/bad.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertTrue(any("UTF-8" in error or "giải mã" in error for error in result.errors))
        self.assertEqual(result.written, ())

    def test_repeated_names_are_numbered(self) -> None:
        _dbc(self.config / "Pet.txt", [0, 0], [[1, 10], [2, 20], [3, 30], [4, 40]])
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["MenPai", "MenPai"],
            [["1", "10"], ["2", "20"], ["3", "30"], ["4", "40"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("sect_1", "sect_2"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertNotIn("trùng tên", notes.rows[0][4])
        self.assertNotIn("trùng tên", notes.rows[1][4])

    def test_extra_cells_on_different_layout_still_align(self) -> None:
        rows = [[1, 0, 10], [2, 0, 20], [3, 0, 30], [4, 0, 40]]
        _dbc(self.config / "Pet.txt", [0, 0, 0], rows)
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10", "thừa"], ["2", "20", "thừa"], ["3", "30", "thừa"], ["4", "40", "thừa"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        self.assertTrue(any("thừa ô" in note for note in result.notices))
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("id", "column_1", "sect"))

    def test_different_layout_names_anchors(self) -> None:
        rows = [[1, 0, 10], [2, 0, 20], [3, 0, 30], [4, 0, 40]]
        _dbc(self.config / "Pet.txt", [0, 0, 0], rows)
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10"], ["2", "20"], ["3", "30"], ["4", "40"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("id", "column_1", "sect"))
        self.assertEqual(table.rows[0], ("1", "0", "10"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertIn("neo: cột gốc 0", notes.rows[0][4])
        self.assertIn("mới ở 2026", notes.rows[1][4])
        self.assertIn("neo: cột gốc 1", notes.rows[2][4])
        self.assertEqual(notes.rows[2][1], "MenPai")

    def test_leading_id_keeps_embedded_legacy_names(self) -> None:
        rows = [[10, 1, 10], [20, 2, 20], [30, 3, 30], [40, 4, 40]]
        _dbc(self.config / "Pet.txt", [0, 0, 0], rows)
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10"], ["2", "20"], ["3", "30"], ["4", "40"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("column_0", "id", "sect"))
        self.assertEqual(table.rows[0], ("10", "1", "10"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertEqual(notes.rows[0][1], "")
        self.assertIn("mới ở 2026", notes.rows[0][4])
        self.assertEqual(notes.rows[1][1], "ID")
        self.assertIn("neo: cột gốc 0", notes.rows[1][4])
        self.assertEqual(notes.rows[2][1], "MenPai")
        self.assertIn("neo: cột gốc 1", notes.rows[2][4])

    def test_partial_row_does_not_borrow_names(self) -> None:
        rows = [[10, 1, 99], [20, 2, 98], [30, 3, 97], [40, 4, 96]]
        _dbc(self.config / "Pet.txt", [0, 0, 0], rows)
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10"], ["2", "20"], ["3", "30"], ["4", "40"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        table = tsv_file.read_table(self.tables / "shared" / "pets.tsv")
        self.assertEqual(table.columns, ("column_0", "column_1", "column_2"))
        notes = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertEqual(notes.rows[1][1], "")
        self.assertIn("mới ở 2026", notes.rows[1][4])

    def test_padded_legacy_id_is_reported(self) -> None:
        rows = [[1, 0, 100], [2, 0, 200], [3, 0, 300], [4, 0, 400]]
        _dbc(self.config / "Pet.txt", [0, 0, 0], rows)
        _legacy(
            self.legacy / "Public" / "Config" / "Pet.txt",
            ["INT", "INT"],
            ["ID", "Value"],
            [["1", "100"], ["01", "100"], ["2", "200"], ["3", "300"], ["4", "400"]],
        )
        _names(self.names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        result = self._export()
        self.assertEqual(result.errors, ())
        self.assertTrue(any("01" in note for note in result.notices))
        columns = tsv_file.read_table(self.columns / "pets.tsv")
        self.assertNotIn("mới ở 2026", columns.rows[0][4])
        self.assertIn("không duy nhất", columns.rows[0][4])

    def test_variant_copies_base_column_names(self) -> None:
        _dbc(self.config / "Shop.txt", [0, 0], [[1, 10], [2, 20]])
        _dbc(self.config / "Shop_KaJi.txt", [0, 0], [[3, 30]])
        _legacy(
            self.legacy / "Public" / "Config" / "Shop.txt",
            ["INT", "INT"],
            ["ID", "MenPai"],
            [["1", "10"], ["2", "20"]],
        )
        _names(
            self.names,
            [
                ("client_2026", "Shop.txt", "table", "tables/shared/shops.tsv", "", "", "A", "0", ""),
                (
                    "client_2026",
                    "Shop_KaJi.txt",
                    "table",
                    "tables/variants/level_cap/shops.tsv",
                    "variant",
                    "level_cap",
                    "A",
                    "0",
                    "",
                ),
            ],
        )
        result = self._export()
        self.assertEqual(result.errors, ())
        base = tsv_file.read_table(self.tables / "shared" / "shops.tsv")
        variant = tsv_file.read_table(self.tables / "variants" / "level_cap" / "shops.tsv")
        self.assertEqual(base.columns, ("id", "sect"))
        self.assertEqual(variant.columns, base.columns)
        self.assertEqual(variant.rows, (("3", "30"),))


class ExportCommandTest(unittest.TestCase):
    def test_help(self) -> None:
        code, output = _run(["--help"])
        self.assertEqual(code, 0)
        self.assertIn("không ghi", output)

    def test_help_is_vietnamese(self) -> None:
        code, output = _run(["--help"])
        self.assertEqual(code, 0)
        self.assertNotIn("usage:", output)
        self.assertNotIn("positional arguments", output)
        self.assertNotIn("show this help message and exit", output)

    def test_missing_arguments_exit_one(self) -> None:
        code, output = _run([])
        self.assertEqual(code, 1)
        self.assertIn("export_tables.py:1:", output)

    def test_unknown_source_exits_one(self) -> None:
        root = _scratch(self.id().split(".")[-1])
        self.addCleanup(shutil.rmtree, root, True)
        raw = root / "raw"
        _dbc(raw / "Config" / "Skill.txt", [0], [[1]])
        (raw / "Config" / "stray.txt").write_bytes(b"x")
        names = root / "names.tsv"
        _names(names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        argv = [str(raw), str(root / "tlbb"), str(root / "tables"), "--names", str(names)]
        argv.extend(["--columns", str(root / "columns")])
        code, output = _run(argv)
        self.assertEqual(code, 1)
        self.assertIn("stray.txt", output)
        self.assertIn("chưa phân loại", output)
        self.assertFalse((root / "tables" / "shared" / "skills.tsv").exists())

    def test_check_names_tables_it_would_write(self) -> None:
        root = _scratch(self.id().split(".")[-1])
        self.addCleanup(shutil.rmtree, root, True)
        raw = root / "raw"
        _dbc(raw / "Config" / "Pet.txt", [0], [[1]])
        names = root / "names.tsv"
        _names(names, [("client_2026", "Pet.txt", "table", "tables/shared/pets.tsv", "", "", "A", "0", "")])
        code, output = _run(
            [
                "--check",
                "--names",
                str(names),
                "--columns",
                str(root / "columns"),
                str(raw),
                str(root / "tlbb"),
                str(root / "tables"),
            ]
        )
        self.assertEqual(code, 0, output)
        self.assertIn("bảng sẽ ghi: 1", output)
        self.assertIn("bảng đã ghi: 0", output)
        self.assertFalse((root / "tables").exists())
        self.assertFalse((root / "columns").exists())


def _signed(bits: int) -> int:
    if bits >= 0x80000000:
        return bits - 0x100000000
    return bits


def _text_at(block: bytes, offset: int) -> str:
    end = block.find(b"\0", offset)
    if end < 0:
        end = len(block)
    return block[offset:end].decode("gb18030")


def _repacked_float(cell: str) -> int:
    """32 bit sau khi đóng gói lại chuỗi thập phân, cùng cách so với DBC."""
    packed = struct.pack("<f", float(cell))
    return struct.unpack("<I", packed)[0]


def _mismatch(source: str, binary: dbc.Dbc, table: tsv_file.Table) -> str:
    if len(table.rows) != binary.rows or len(table.columns) != binary.columns:
        wide = f"{len(table.rows)}x{len(table.columns)} khác {binary.rows}x{binary.columns}"
        return f"{source}: {wide}"
    for index in range(binary.rows):
        for column, kind in enumerate(binary.types):
            cell = table.rows[index][column]
            bits = binary.raw(index, column)
            if kind == dbc.INT and cell != str(_signed(bits)):
                return f"{source}:{index + 1}: cột {column} int {cell}"
            if kind == dbc.FLOAT and _repacked_float(cell) != bits:
                return f"{source}:{index + 1}: cột {column} float {cell}"
            if kind == dbc.STRING and cell != _text_at(binary.strings, bits):
                return f"{source}:{index + 1}: cột {column} chuỗi lệch"
    return ""


def _real_roots() -> tuple[str, str] | None:
    raw = os.environ.get("THIENLONG_RAW_ROOT")
    legacy = os.environ.get("THIENLONG_LEGACY_ROOT")
    if not raw or not legacy:
        return None
    return raw, legacy


def _export_real(raw: str, legacy: str, root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            "-W",
            "error",
            "TOOLS/server/export_tables.py",
            raw,
            legacy,
            str(root / "tables"),
            "--columns",
            str(root / "columns"),
            "--alignment",
            str(root / "column_alignment.tsv"),
        ],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def _assert_cells(case: unittest.TestCase, raw: str, tables: Path) -> None:
    config = Path(raw) / "Config"
    shared = sorted((tables / "shared").rglob("*.tsv"))
    variants = sorted((tables / "variants").rglob("*.tsv"))
    written = shared + variants
    case.assertEqual(len(written), 635)
    for path in written:
        table = tsv_file.read_table(path)
        relative = table.source.removeprefix("client_2026/")
        binary = dbc.read(str(config / relative), relative)
        case.assertEqual(_mismatch(relative, binary, table), "")


class RealExportTest(unittest.TestCase):
    def test_real_tables_roundtrip(self) -> None:
        roots = _real_roots()
        if roots is None:
            self.skipTest("thiếu THIENLONG_RAW_ROOT hoặc THIENLONG_LEGACY_ROOT")
        raw, legacy = roots
        sample = next(Path("dev/server/tables/shared").glob("*.tsv"), None)
        before = None if sample is None else sample.read_bytes()
        root = Path("build") / "p1-a" / "real-export"
        if root.exists():
            shutil.rmtree(root)
        root.mkdir(parents=True)
        completed = _export_real(raw, legacy, root)
        output = completed.stdout + completed.stderr
        log = Path("build") / "p1-a" / "export-stdout.txt"
        log.write_text(output, encoding="utf-8")
        self.assertEqual(completed.returncode, 0, output)
        self.assertIn("chưa phân loại: 0", output)
        self.assertIn("bảng sẽ ghi: 635", output)
        self.assertIn("bảng đã ghi: 635", output)
        self.assertIn("bản ghi: 994925", output)
        self.assertIn("thư mục chưa phân loại: 0", output)
        self.assertTrue((root / "column_alignment.tsv").is_file())
        if sample is not None:
            self.assertEqual(sample.read_bytes(), before)
        _assert_cells(self, raw, root / "tables")


if __name__ == "__main__":
    unittest.main()
