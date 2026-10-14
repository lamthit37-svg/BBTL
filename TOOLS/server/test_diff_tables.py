# Kiểm hiệu id và độ phủ tham chiếu. Dữ liệu thử nằm trong build/.
from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import diff_tables
import tsv_file

BUILD = ROOT.parents[1] / "build" / "p1-a" / "diff"
HEADER = (
    "# schema 1\n"
    "# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
    "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n"
)


def _names(folder: Path, source: str, target: str) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    text = (
        "# schema 1\n"
        "# source: test\n"
        "# types: text\ttext\ttext\ttext\ttext\ttext\ttext\ttext\ttext\n"
        "tree\tsource\tfate\ttarget\tkey_field\tkey\towner\tunresolved\tnote\n"
        f"public_config\t{source}\treference\t\t\t\t\t0\t\n"
        f"client_2026\t{source}\ttable\t{target}\t\t\tA\t0\t\n"
    )
    (folder / "names.tsv").write_text(text, encoding="utf-8", newline="\n")


def _legacy(folder: Path, source: str, body: str) -> None:
    path = folder / "tlbb" / "Public" / "Config" / source
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8", newline="\n")


def _table(path: Path, types: tuple[str, ...], columns: tuple[str, ...], rows: list[tuple[str, ...]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tsv_file.write_table(path, "client_2026/test", "diff_tables.py", types, columns, rows)


class IdKeyTest(unittest.TestCase):
    def test_int_text_and_overflow_follow_the_export_key(self) -> None:
        self.assertEqual(diff_tables.id_key("int", "01"), diff_tables.id_key("int", "1"))
        self.assertEqual(diff_tables.id_key("text", "08"), diff_tables.id_key("text", "8"))
        self.assertNotEqual(diff_tables.id_key("text", "a"), diff_tables.id_key("text", "b"))
        self.assertIsNone(diff_tables.id_key("int", ""))


class PairListTest(unittest.TestCase):
    def test_reference_without_a_client_table_is_an_error(self) -> None:
        rows = (
            tsv_file.NameRow("public_config", "A.txt", "reference", "", "", "", "", "0", ""),
            tsv_file.NameRow("client_2026", "B.txt", "table", "tables/shared/b.tsv", "", "", "A", "0", ""),
        )
        with self.assertRaises(ValueError):
            diff_tables.paired_sources(rows)


def _clear(folder: Path) -> None:
    if not folder.exists():
        return
    for path in sorted(folder.rglob("*"), reverse=True):
        if path.is_file():
            path.unlink()
            continue
        path.rmdir()


def _command(folder: Path, server: Path, output: Path) -> list[str]:
    return [
        sys.executable,
        "-B",
        str(ROOT / "diff_tables.py"),
        str(folder / "tlbb"),
        str(server),
        "--names",
        str(folder / "names.tsv"),
        "--refs",
        str(folder / "refs"),
        "--output",
        str(output),
    ]


class CommandTest(unittest.TestCase):
    def test_check_prints_totals_and_rejects_a_wrong_missing_count(self) -> None:
        folder = BUILD / "one"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _legacy(folder, "Pet.txt", "INT\tINT\nID\tV\n1\t0\n02\t0\n4\t0\n")
        _table(
            server / "tables/shared/pets.tsv",
            ("int", "int"),
            ("id", "value"),
            [("1", "0"), ("2", "0"), ("3", "0")],
        )
        _table(
            server / "tables/shared/skills.tsv",
            ("int",),
            ("skill_id",),
            [("1",), ("9",)],
        )
        refs = folder / "refs"
        refs.mkdir(parents=True, exist_ok=True)
        row = "tables/shared/pets.tsv\tvalue\ttables/shared/skills.tsv\tskill_id\t-1;0\t1\tdata\tthử\n"
        (refs / "shared.tsv").write_text(HEADER + row, encoding="utf-8", newline="\n")
        output = folder / "out"
        command = _command(folder, server, output)
        command.append("--check")
        done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertIn("cặp: 1", done.stdout)
        self.assertIn("ids_2026: 3", done.stdout)
        self.assertIn("ids_legacy: 3", done.stdout)
        self.assertIn("common: 2", done.stdout)
        self.assertIn("only_2026: 1", done.stdout)
        self.assertIn("only_legacy: 1", done.stdout)
        self.assertIn("missing_values 0", done.stdout)
        fixed = row.replace("\t1\t", "\t0\t")
        (refs / "shared.tsv").write_text(HEADER + fixed, encoding="utf-8", newline="\n")
        again = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(again.returncode, 0, again.stdout + again.stderr)
        self.assertFalse(output.exists())

    def test_check_rejects_parent_that_matches_no_file(self) -> None:
        folder = BUILD / "absent"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _legacy(folder, "Pet.txt", "INT\nID\n7\n")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("7",)])
        refs = folder / "refs"
        refs.mkdir(parents=True, exist_ok=True)
        body = "tables/shared/pets.tsv\tid\ttables/missing.tsv\tid\t\t1\tdata\tcha không có\n"
        (refs / "shared.tsv").write_text(HEADER + body, encoding="utf-8", newline="\n")
        command = _command(folder, server, folder / "out")
        command.append("--check")
        done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertIn("mẫu không khớp", done.stdout)

    def test_write_sorts_first_missing_by_number_and_scene(self) -> None:
        folder = BUILD / "star"
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _legacy(folder, "Pet.txt", "INT\nID\n1\n")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("1",)])
        _table(server / "scenes/b/spawns.tsv", ("int",), ("type",), [("2",), ("-10",)])
        _table(server / "scenes/a/spawns.tsv", ("int",), ("type",), [("3",)])
        _table(server / "scenes/a/monsters.tsv", ("int",), ("monster_id",), [("3",)])
        refs = folder / "refs"
        refs.mkdir(parents=True, exist_ok=True)
        body = (
            "scenes/*/spawns.tsv\ttype\tscenes/*/monsters.tsv\tmonster_id\t\t2\tdata\tkhớp 0%\n"
        )
        (refs / "shared.tsv").write_text(HEADER + body, encoding="utf-8", newline="\n")
        output = folder / "out"
        done = subprocess.run(_command(folder, server, output), capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
        rows = tsv_file.read_table(output / "table_ref_coverage.tsv").rows
        self.assertIn(("2", "3", "3", "3", "2", "2", "b:-10;b:2"), [row[-7:] for row in rows])

    def test_bad_utf8_reports_the_line(self) -> None:
        folder = BUILD / "utf8"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("1",)])
        path = folder / "tlbb" / "Public" / "Config" / "Pet.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"INT\nID\n1\n\xff\n")
        (folder / "refs").mkdir(parents=True, exist_ok=True)
        command = _command(folder, server, folder / "out")
        command.append("--check")
        done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertIn("Pet.txt:4: byte UTF-8 hỏng", done.stdout)

    def test_id_float_overflow_names_the_line(self) -> None:
        folder = BUILD / "float-id"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("1",)])
        _legacy(folder, "Pet.txt", "FLOAT\nID\n1e39\n")
        (folder / "refs").mkdir(parents=True, exist_ok=True)
        command = _command(folder, server, folder / "out")
        command.append("--check")
        done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertIn("Pet.txt:3: số thực không vừa float32", done.stdout)

    def test_missing_refs_directory_is_an_error(self) -> None:
        folder = BUILD / "missing-refs"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _legacy(folder, "Pet.txt", "INT\nID\n1\n")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("1",)])
        command = _command(folder, server, folder / "out")
        command.append("--check")
        done = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertIn("missing-refs/refs:1: thư mục refs không tồn tại", done.stdout)
        self.assertNotIn("dòng tham chiếu: 0", done.stdout)

    def test_type_clash_keeps_the_coverage_row(self) -> None:
        folder = BUILD / "clash"
        _clear(folder)
        server = folder / "server"
        _names(folder, "Pet.txt", "tables/shared/pets.tsv")
        _legacy(folder, "Pet.txt", "INT\nID\n7\n")
        _table(server / "tables/shared/pets.tsv", ("int",), ("id",), [("7",)])
        _table(server / "tables/shared/skills.tsv", ("text",), ("id",), [("7",)])
        refs = folder / "refs"
        refs.mkdir(parents=True, exist_ok=True)
        body = "tables/shared/pets.tsv\tid\ttables/shared/skills.tsv\tid\t\t0\tdata\tkhác kiểu\n"
        (refs / "shared.tsv").write_text(HEADER + body, encoding="utf-8", newline="\n")
        output = folder / "out"
        command = _command(folder, server, output)
        command.append("--check")
        checked = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(checked.returncode, 1, checked.stdout + checked.stderr)
        self.assertIn("dòng tham chiếu: 1", checked.stdout)
        self.assertIn("hai cột khác kiểu", checked.stdout)
        self.assertFalse(output.exists())
        command.pop()
        written = subprocess.run(command, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(written.returncode, 1, written.stdout + written.stderr)
        text = (output / "table_ref_coverage.tsv").read_text(encoding="utf-8")
        self.assertIn("public_config/Pet.txt (1 tệp)", (output / "table_id_diff.tsv").read_text(encoding="utf-8"))
        self.assertIn("refs/*.tsv (1 tệp)", text)
        expected = ("tables/shared/pets.tsv", "id", "tables/shared/skills.tsv", "id", "1", "1", "1", "1", "0", "0", "")
        self.assertIn(expected, tsv_file.read_table(output / "table_ref_coverage.tsv").rows)


if __name__ == "__main__":
    unittest.main()
