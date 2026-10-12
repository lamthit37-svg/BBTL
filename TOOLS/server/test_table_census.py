# Kiểm kê bảng DBC: mọi tệp Config có đúng một phân loại, bảng hỏng bị từ chối, --check không ghi.
from __future__ import annotations

import hashlib
import io
import os
import shutil
import struct
import subprocess
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import table_census
import tsv_file

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


def _run(argv: list[str]) -> tuple[int, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    with redirect_stdout(stdout), redirect_stderr(stderr):
        code = table_census.main(argv)
    return code, stdout.getvalue() + stderr.getvalue()


class CensusCollectTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.raw = self.root / "raw"
        self.config = self.raw / "Config"
        self.names = self.root / "names.tsv"

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_counts_types_and_hash(self) -> None:
        _dbc(self.config / "Skill.txt", [0, 1, 2], [[1, 0x3F000000, 0], [2, 0, 2]], b"a\0b\0")
        (self.config / "note.lua").write_text("x\n", encoding="utf-8")
        _names(
            self.names,
            [
                ("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", ""),
                ("client_2026", "note.lua", "deferred", "", "", "", "", "0", "script"),
            ],
        )
        result = table_census.collect(self.raw, self.names)
        self.assertEqual(result.errors, ())
        self.assertEqual(len(result.rows), 1)
        row = result.rows[0]
        self.assertEqual(row.source, "Skill.txt")
        self.assertEqual(row.column_count, 3)
        self.assertEqual(row.row_count, 2)
        self.assertEqual(row.types, "int,float,text")
        digest = hashlib.sha256((self.config / "Skill.txt").read_bytes()).hexdigest()
        self.assertEqual(row.sha256, digest)
        self.assertEqual(result.counts["table"], 1)
        self.assertEqual(result.counts["deferred"], 1)
        self.assertEqual(result.records, 2)
        self.assertEqual(result.unclassified_directories, 0)

    def test_unknown_file_is_an_error(self) -> None:
        _dbc(self.config / "Skill.txt", [0], [[1]])
        (self.config / "extra.txt").write_bytes(b"nope")
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        result = table_census.collect(self.raw, self.names)
        self.assertTrue(any("extra.txt" in error and "chưa phân loại" in error for error in result.errors))
        self.assertEqual(result.rows, ())

    def test_missing_file_is_an_error(self) -> None:
        self.config.mkdir(parents=True)
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        result = table_census.collect(self.raw, self.names)
        self.assertTrue(any("Skill.txt" in error and "không có trên đĩa" in error for error in result.errors))

    def test_bad_magic(self) -> None:
        path = self.config / "Skill.txt"
        path.parent.mkdir(parents=True)
        path.write_bytes(b"not a dbc file!!")
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        result = table_census.collect(self.raw, self.names)
        self.assertTrue(any("sai magic" in error for error in result.errors))

    def test_truncated(self) -> None:
        path = self.config / "Skill.txt"
        path.parent.mkdir(parents=True)
        path.write_bytes(struct.pack("<IIII", MAGIC, 2, 10, 1))
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        result = table_census.collect(self.raw, self.names)
        self.assertTrue(any("tệp cụt" in error for error in result.errors))

    def test_empty_directory_is_unclassified(self) -> None:
        _dbc(self.config / "Skill.txt", [0], [[1]])
        (self.config / "empty_dir").mkdir()
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])
        result = table_census.collect(self.raw, self.names)
        self.assertTrue(any("empty_dir" in error for error in result.errors))
        self.assertGreater(result.unclassified_directories, 0)


class CensusCommandTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.raw = self.root / "raw"
        self.output = self.root / "census.tsv"
        self.names = self.root / "names.tsv"
        _dbc(self.raw / "Config" / "Skill.txt", [0], [[7]])
        _names(self.names, [("client_2026", "Skill.txt", "table", "tables/shared/skills.tsv", "", "", "A", "0", "")])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_check_writes_nothing(self) -> None:
        code, output = _run(["--check", "--names", str(self.names), "--output", str(self.output), str(self.raw)])
        self.assertEqual(code, 0)
        self.assertFalse(self.output.exists())
        self.assertIn("chưa phân loại: 0", output)
        self.assertIn("table: 1", output)

    def test_write_is_deterministic(self) -> None:
        other = self.root / "census2.tsv"
        first, _ = _run(["--names", str(self.names), "--output", str(self.output), str(self.raw)])
        second, _ = _run(["--names", str(self.names), "--output", str(other), str(self.raw)])
        self.assertEqual(first, 0)
        self.assertEqual(second, 0)
        self.assertEqual(self.output.read_bytes(), other.read_bytes())
        self.assertNotIn(b"\r", self.output.read_bytes())
        text = self.output.read_text(encoding="utf-8")
        self.assertIn("client_2026/Config (1 tệp .txt)", text)
        self.assertIn("\t1\t1\tint\t", text)

    def test_bad_magic_exits_one_and_skips_write(self) -> None:
        (self.raw / "Config" / "Skill.txt").write_bytes(b"bad-magic-bytes!")
        code, output = _run(["--names", str(self.names), "--output", str(self.output), str(self.raw)])
        self.assertEqual(code, 1)
        self.assertIn("sai magic", output)
        self.assertFalse(self.output.exists())

    def test_help(self) -> None:
        code, output = _run(["--help"])
        self.assertEqual(code, 0)
        self.assertIn("không ghi", output)


class RealCensusTest(unittest.TestCase):
    def test_real_config_is_classified(self) -> None:
        raw = os.environ.get("THIENLONG_RAW_ROOT")
        legacy = os.environ.get("THIENLONG_LEGACY_ROOT")
        if not raw or not legacy:
            self.skipTest("thiếu THIENLONG_RAW_ROOT hoặc THIENLONG_LEGACY_ROOT")
        output_path = Path("build") / "p1-a" / "real-census" / "table_census.tsv"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        completed = subprocess.run(
            [sys.executable, "-W", "error", "TOOLS/server/table_census.py", raw, "--output", str(output_path)],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        output = completed.stdout + completed.stderr
        self.assertEqual(completed.returncode, 0, output)
        self.assertIn("chưa phân loại: 0", output)
        self.assertIn("table: 635", output)
        self.assertIn("client_only: 109", output)
        self.assertIn("dropped: 1", output)
        self.assertIn("deferred: 1132", output)
        self.assertIn("bảng: 745", output)
        self.assertIn("thư mục chưa phân loại: 0", output)
        table = tsv_file.read_table(output_path)
        self.assertEqual(len(table.rows), 745)
        self.assertEqual(table.columns, ("source", "column_count", "row_count", "types", "sha256"))


if __name__ == "__main__":
    unittest.main()
