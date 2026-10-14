# Kiểm import_legacy: giá trị sau khi nạp phải khớp bộ đọc gốc, đầu vào hỏng phải bị từ chối.
from __future__ import annotations

import io
import os
import shutil
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import import_legacy
import tsv_file

LEGACY = os.environ.get("THIENLONG_LEGACY_ROOT")


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-b" / "unit" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _row(source: str, target: str, tree: str = "server_config", key_field: str = "", key: str = "") -> tsv_file.NameRow:
    return tsv_file.NameRow(tree, source, "table", target, key_field, key, "B", "0", "")


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


class ExportLegacyTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.output = self.root / "out"
        self.columns = self.root / "columns"
        self.legacy = self.root / "tlbb"

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _export(
        self, rows: tuple[tsv_file.NameRow, ...], **kwargs: bool
    ) -> tuple[list[str], list[str]]:
        return import_legacy.export_legacy(
            self.legacy,
            self.output,
            rows,
            column_dir=self.columns,
            **kwargs,
        )

    def test_scene_pvp_column_uses_rules(self) -> None:
        columns, _types, originals, notes = import_legacy._scene_layout()
        self.assertIn("pvp_rules", columns)
        self.assertNotIn("pvp_ruler", columns)
        self.assertEqual(originals[1], "clientres")
        self.assertEqual(originals[9], "_clientres")
        self.assertEqual(columns[1], "clientres_1")
        self.assertEqual(columns[9], "clientres_2")
        self.assertNotIn("column_9", columns)
        self.assertNotIn("?", notes[9])

    def test_reexport_keeps_curated_names_and_is_stable(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes("INT\tINT\nid\t道具空间需求\n1\t5\n".encode("utf-8"))
        rows = (_row("sample.txt", "tables/server/sample.tsv"),)
        self.assertEqual(self._export(rows)[0], [])
        mapping = self.columns / "sample.tsv"
        first = tsv_file.read_table(mapping)
        self.assertEqual(first.rows[1][2], "column_1")
        curated = [list(row) for row in first.rows]
        curated[1][2] = "space_need"
        tsv_file.write_table(mapping, first.source, import_legacy.TOOL, list(first.types),
                             list(first.columns), [tuple(row) for row in curated])
        self.assertEqual(self._export(rows)[0], [])
        self.assertEqual(tsv_file.read_table(mapping).rows[1][2], "space_need")
        self.assertEqual(tsv_file.read_table(self.output / "sample.tsv").columns[1], "space_need")
        once = mapping.read_bytes()
        self.assertEqual(self._export(rows)[0], [])
        self.assertEqual(mapping.read_bytes(), once)
    def test_float_strips_ends_only(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "FLOAT\tFLOAT\na\tb\n 0.50 \t1.25\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.rows, (("0.50", "1.25"),))
        self.assertIn("float bỏ khoảng trắng 1", "\n".join(summary))

    def test_int_float_string_and_padding(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tINT\tFLOAT\tSTRING\nid\tn\tratio\tlabel\n1\t\t1.50\thello\n2\t12abc\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.types, ("int", "int", "float", "text"))
        self.assertEqual(table.columns, ("id", "n", "ratio", "label"))
        self.assertEqual(table.rows, (("1", "0", "1.50", "hello"), ("2", "12", "", "")))
        columns = tsv_file.read_table(self.columns / "sample.tsv")
        self.assertEqual(columns.rows[0][1], "id")

    def test_drop_comment_blank_and_empty_id(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tINT\nid\tn\n# bỏ\n\n\t2\n3\t4\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.rows, (("3", "4"),))
        self.assertTrue(any("dòng bỏ" in line for line in summary))

    def test_reject_extra_cell(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tINT\na\tb\n1\t2\t3\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(errors)
        self.assertIn("thừa ô", errors[0])
        self.assertFalse((self.output / "sample.tsv").exists())

    def test_keep_value_under_blank_type(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tINT\t\na\tb\t\n1\t2\t\n3\t4\t9\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.types, ("int", "int"))
        self.assertEqual(table.rows, (("1", "2"), ("3", "4")))
        self.assertIn("ô sau kiểu bị bỏ 1", "\n".join(summary))
        columns = tsv_file.read_table(self.columns / "sample.tsv")
        self.assertEqual(len(columns.rows), 2)

    def test_reject_duplicate_id(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tINT\nid\tn\n1\t2\n01\t3\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(errors)
        self.assertIn("id trùng", errors[0])

    def test_reject_bad_utf8(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(b"INT\nname\n\xff\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(errors)
        self.assertIn("UTF-8", errors[0])

    def test_reject_truncated(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\tSTRING\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(errors)
        self.assertIn("cụt", errors[0])

    def test_reject_magic(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(b"\x00\xcc\xbb\xddrest")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(errors)
        self.assertIn("magic", errors[0])

    def test_reject_tab_inside_ini_value(self) -> None:
        source = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            source,
            "[system]\nscenenumber=1\n[scene0]\nthreadindex=1\nclientres=0\nname=ab\tcd\n"
            "active=1\nfile=a.scn\nserverid=0\ntype=0\nPvpRuler=0\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, _summary = self._export(rows)
        self.assertTrue(errors)
        self.assertIn("tab", errors[0])

    def test_scene_split_and_comment_cut(self) -> None:
        source = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            source,
            "[system]\nscenenumber=1\n[scene0]\nthreadindex=30\t;luong\nclientres=0\nname=洛阳\n"
            "active=1\nfile=luoyang.scn\nserverid=0\ntype=0\nPvpRuler=0\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, summary = self._export(rows)
        self.assertEqual(errors, [])
        scenes = tsv_file.read_table(self.output / "scenes.tsv")
        hosting = tsv_file.read_table(self.output / "scene_hosting.tsv")
        self.assertEqual(scenes.rows[0][0], "0")
        self.assertIn("洛阳", scenes.rows[0])
        self.assertIn("luoyang.scn", scenes.rows[0])
        self.assertEqual(hosting.rows[0][1], "1")
        self.assertEqual(hosting.rows[0][2], "0")
        self.assertEqual(hosting.rows[0][3], "30")
        self.assertTrue(any("cắt chú thích" in line for line in summary))

    def test_unknown_ini_key(self) -> None:
        source = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            source,
            "[system]\nscenenumber=1\n[scene0]\nthreadindex=1\nclientres=0\nname=a\n"
            "active=1\nfile=a.scn\nserverid=0\ntype=0\nPvpRuler=0\nweird=1\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, _summary = self._export(rows)
        self.assertTrue(any("khoá lạ" in error for error in errors))

    def test_hash_ini_key_is_not_swallowed(self) -> None:
        source = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            source,
            "[system]\nscenenumber=1\n[scene0]\nthreadindex=1\nclientres=0\nname=a\n"
            "active=1\nfile=a.scn\nserverid=0\ntype=0\nPvpRuler=0\n#extra=9\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, _summary = self._export(rows)
        if not errors:
            scenes = tsv_file.read_table(self.output / "scenes.tsv")
            cells = [cell for row in scenes.rows for cell in row]
            self.assertIn("9", cells)
            return
        self.assertTrue(any("khoá lạ" in error and "#extra" in error for error in errors))
        self.assertIn("SceneInfo.ini:12:", errors[0])
        self.assertFalse((self.output / "scenes.tsv").exists())

    def test_ini_line_without_equals(self) -> None:
        source = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            source,
            "[system]\nscenenumber=1\n[scene0]\nthreadindex=1\nclientres=0\nname=a\n"
            "active=1\nfile=a.scn\nserverid=0\ntype=0\nPvpRuler 7\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, _summary = self._export(rows)
        self.assertTrue(errors)
        self.assertIn("dấu bằng", errors[0])
        self.assertFalse((self.output / "scenes.tsv").exists())

    def test_box_merge(self) -> None:
        folder = self.legacy / "Server" / "Config"
        _write(folder / "boxdroplist.txt", "INT\tINT\nindex\tItemID\n1\t10\n")
        _write(folder / "boxdroplist_zhuandansl.txt", "INT\tINT\nindex\tItemID\n1\t20\n")
        rows = (
            _row(
                "boxdroplist.txt",
                "tables/server/loot_box_entries.tsv",
                key_field="box_key",
                key="default",
            ),
            _row(
                "boxdroplist_zhuandansl.txt",
                "tables/server/loot_box_entries.tsv",
                key_field="box_key",
                key="gacha_shaolin",
            ),
        )
        errors, _summary = self._export(rows)
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "loot_box_entries.tsv")
        self.assertEqual(table.columns[0], "box_key")
        self.assertEqual(table.rows, (("default", "1", "10"), ("gacha_shaolin", "1", "20")))
        self.assertIn("2 tệp", table.source)

    def test_shop_merge_and_total(self) -> None:
        folder = self.legacy / "Public" / "Config" / "RandShop"
        _write(
            folder / "60wufang.ini",
            "[General]\nTotal=1\n[Merchandise0]\nID=5\nCount=1\nCountPerUnit=1\nOdds=2\nValue=3\n",
        )
        _write(
            folder / "shide.ini",
            "[General]\nTotal=1\n[Merchandise0]\nID=6\nCount=1\nCountPerUnit=1\nodds=4\nValue=5\nRebate=9\n",
        )
        rows = (
            _row(
                "RandShop/60wufang.ini",
                "tables/server/random_shop_goods.tsv",
                "public_config",
                "shop_key",
                "workshop_60",
            ),
            _row(
                "RandShop/shide.ini",
                "tables/server/random_shop_goods.tsv",
                "public_config",
                "shop_key",
                "mentor_virtue",
            ),
        )
        errors, _summary = self._export(rows)
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "random_shop_goods.tsv")
        self.assertEqual(table.columns[5], "odds_1")
        self.assertEqual(table.columns[6], "odds_2")
        self.assertEqual(table.rows[0][0], "workshop_60")
        self.assertEqual(table.rows[0][5], "2")
        self.assertEqual(table.rows[0][6], "")
        self.assertEqual(table.rows[1][0], "mentor_virtue")
        self.assertEqual(table.rows[1][5], "")
        self.assertEqual(table.rows[1][6], "4")
        self.assertIn("9", table.rows[1])
        columns = tsv_file.read_table(self.columns / "random_shop_goods.tsv")
        self.assertEqual(columns.rows[5][1], "Odds")
        self.assertEqual(columns.rows[5][2], "odds_1")
        self.assertEqual(columns.rows[6][1], "odds")
        self.assertEqual(columns.rows[6][2], "odds_2")
        self.assertNotIn("?", columns.rows[5][4])
        self.assertNotIn("?", columns.rows[6][4])

    def test_drop_box_note_names_code_index(self) -> None:
        source = self.legacy / "Server" / "Config" / "DropBoxContent.txt"
        labels = [f"c{index}" for index in range(203)]
        labels[2] = "NotItem"
        kinds = "\t".join(["INT"] * 203)
        header = "\t".join(labels)
        body = "\t".join(["1"] * 203)
        _write(source, f"{kinds}\n{header}\n{body}\n")
        errors, _summary = self._export((_row("DropBoxContent.txt", "tables/server/drop_packages.tsv"),))
        self.assertEqual(errors, [])
        columns = tsv_file.read_table(self.columns / "drop_packages.tsv")
        self.assertEqual(columns.rows[2][1], "NotItem")
        self.assertEqual(columns.rows[2][2], "not_item")
        for index in (2, 4):
            note = columns.rows[index][4]
            self.assertIn("cột 2", note)
            self.assertIn("cột 4", note)
            self.assertIn("kFirstPairColumn", note)
        for index in (200, 202):
            self.assertNotIn("InitDropBoxTable", columns.rows[index][4])

    def test_reject_shop_total(self) -> None:
        folder = self.legacy / "Public" / "Config" / "RandShop"
        _write(
            folder / "60wufang.ini",
            "[General]\nTotal=2\n[Merchandise0]\nID=5\nCount=1\nCountPerUnit=1\nOdds=2\nValue=3\n",
        )
        rows = (
            _row(
                "RandShop/60wufang.ini",
                "tables/server/random_shop_goods.tsv",
                "public_config",
                "shop_key",
                "workshop_60",
            ),
        )
        errors, _summary = self._export(rows)
        self.assertTrue(any("Total" in error for error in errors))

    def test_script_index(self) -> None:
        path = self.legacy / "Public" / "Data" / "Script.dat"
        _write(path, "MGR_TXT\r\n; chú\r\n000001=\\obj\\a.lua\r\n帮会同盟\r\n2=b.ai =ghi chú\r\n")
        ai_path = self.legacy / "Public" / "Data" / "AIScript.dat"
        _write(ai_path, "MGR_TXT\r\n\r\n0=script0.ai\r\n")
        errors, summary = self._export((), include_script_index=True)
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "script_index.tsv")
        self.assertEqual(table.rows[0], ("1", "/obj/a.lua"))
        self.assertEqual(table.rows[1], ("2", "b.ai"))
        self.assertNotIn("帮会同盟", "\n".join(" ".join(row) for row in table.rows))
        ai_table = tsv_file.read_table(self.output / "monster_ai_scripts.tsv")
        self.assertEqual(ai_table.rows, (("0", "script0.ai"),))
        self.assertTrue(any("dòng script bỏ 2" in line for line in summary))

    def test_decimal_text_column_is_listed(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "STRING\tSTRING\nwhole\tmixed\n1\t1.5\n2\t-0.5\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.types, ("text", "text"))
        self.assertEqual(table.rows[1][1], "-0.5")
        listed = next(line for line in summary if "cột text toàn số" in line)
        self.assertIn("whole", listed)
        self.assertIn("mixed", listed)

    def test_middle_empty_type_reads_first_fields(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\t\tSTRING\na\tb\tc\n1\t2\thello\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        table = tsv_file.read_table(self.output / "sample.tsv")
        self.assertEqual(table.types, ("int", "text"))
        self.assertEqual(table.columns, ("a", "b"))
        self.assertEqual(table.rows, (("1", "2"),))
        self.assertTrue(any("ô sau kiểu bị bỏ 1" in line for line in summary))

    def test_foreign_blocks_delete(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\nid\n1\n")
        self.output.mkdir(parents=True)
        foreign = self.output / "note.txt"
        foreign.write_text("giữ\n", encoding="utf-8", newline="\n")
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertTrue(any("tệp lạ" in error for error in errors))
        self.assertTrue(foreign.exists())
        self.assertFalse((self.output / "sample.tsv").exists())

    def test_keeps_scene_refs_table(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\nid\n1\n")
        self.output.mkdir(parents=True)
        kept = self.output / "scene_load_refs.tsv"
        tsv_file.write_table(kept, "Script", "scene_refs.py", ["int"], ["id"], [("1",)])
        before = kept.read_bytes()
        errors, _summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),))
        self.assertEqual(errors, [])
        self.assertEqual(kept.read_bytes(), before)
        self.assertTrue((self.output / "sample.tsv").is_file())

    def test_check_writes_nothing(self) -> None:
        source = self.legacy / "Server" / "Config" / "sample.txt"
        _write(source, "INT\nid\n1\n")
        errors, summary = self._export((_row("sample.txt", "tables/server/sample.tsv"),), check_only=True)
        self.assertEqual(errors, [])
        self.assertTrue(summary)
        self.assertFalse(self.output.exists())
        self.assertFalse(self.columns.exists())

    def test_within_declared_count(self) -> None:
        scene = self.legacy / "Server" / "Config" / "SceneInfo.ini"
        _write(
            scene,
            "[system]\nscenenumber=1\n"
            "[scene0]\nthreadindex=1\nclientres=0\nname=a\nactive=1\nfile=a.scn\n"
            "serverid=0\ntype=0\n"
            "[scene1]\nthreadindex=1\nclientres=0\nname=b\nactive=1\nfile=b.scn\n"
            "serverid=0\ntype=0\n",
        )
        rows = (
            _row("SceneInfo.ini", "tables/server/scenes.tsv"),
            _row("SceneInfo.ini", "tables/server/scene_hosting.tsv"),
        )
        errors, _summary = self._export(rows)
        self.assertEqual(errors, [])
        scenes = tsv_file.read_table(self.output / "scenes.tsv")
        hosting = tsv_file.read_table(self.output / "scene_hosting.tsv")
        self.assertEqual(scenes.columns[-1], "within_declared_count")
        self.assertEqual(scenes.rows[0][-1], "1")
        self.assertEqual(scenes.rows[1][-1], "0")
        self.assertEqual(hosting.rows[1][-1], "0")
        self.assertNotIn("broadcount", scenes.columns)

    def test_help_and_missing_args(self) -> None:
        code, text = _capture_main(["--help"])
        self.assertEqual(code, 0)
        self.assertIn("không ghi", text)
        code, text = _capture_main(["--nope"])
        self.assertEqual(code, 1)
        self.assertIn("không rõ đối số", text)
        code, _text = _capture_main([])
        self.assertEqual(code, 1)


def _capture_main(args: list[str]) -> tuple[int, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    with redirect_stdout(stdout), redirect_stderr(stderr):
        code = import_legacy.main(args)
    return code, stdout.getvalue() + stderr.getvalue()


def _records(path: Path) -> int:
    lines = path.read_bytes().decode("utf-8").splitlines()
    count = 0
    for line in lines[2:]:
        if line == "" or line.startswith("#"):
            continue
        if line.split("\t", 1)[0] == "":
            continue
        count += 1
    return count


def _owner_targets() -> set[str]:
    return {
        Path(row.target).name
        for row in tsv_file.read_name_map()
        if row.owner == "B" and row.fate == "table"
    }


def _assert_outputs(test: unittest.TestCase, output: Path, columns: Path) -> None:
    for name in _owner_targets():
        test.assertTrue((output / name).is_file(), name)
        tsv_file.read_table(output / name)
        test.assertTrue((columns / name).is_file(), name)
    test.assertTrue((output / "script_index.tsv").is_file())
    test.assertTrue((output / "monster_ai_scripts.tsv").is_file())


def _digit_assignments(text: str) -> int:
    return sum(1 for line in text.splitlines() if line[:1].isdigit() and "=" in line)


def _script_dropped_count(text: str) -> int:
    dropped = 0
    for line in text.splitlines()[1:]:
        head = line.lstrip(" \t")
        if head == "" or head.startswith(";") or not head[:1].isdigit():
            dropped += 1
    return dropped


def _assert_scripts(test: unittest.TestCase, root: Path, output: Path, summary: list[str]) -> None:
    script_path = root / "Public" / "Data" / "Script.dat"
    script_text = script_path.read_bytes().decode("utf-8")
    script_rows = tsv_file.read_table(output / "script_index.tsv").rows
    test.assertEqual(len(script_rows), _digit_assignments(script_text))
    script_line = next(line for line in summary if line.startswith("script_index.tsv:"))
    test.assertIn(f"dòng script bỏ {_script_dropped_count(script_text)}", script_line)
    ai_path = root / "Public" / "Data" / "AIScript.dat"
    ai_text = ai_path.read_bytes().decode("utf-8")
    ai_rows = tsv_file.read_table(output / "monster_ai_scripts.tsv").rows
    test.assertEqual(len(ai_rows), _digit_assignments(ai_text))


def _assert_drop_code_notes(test: unittest.TestCase, columns: Path) -> None:
    notes = tsv_file.read_table(columns / "drop_packages.tsv")
    test.assertNotEqual(notes.rows[2][1], "Item1ID")
    test.assertEqual(notes.rows[2][2], "broadcast_type_id")
    test.assertEqual(notes.rows[202][2], "item_100_id")
    for index in (2, 4, 200, 202):
        note = notes.rows[index][4]
        test.assertIn("cột 2", note)
        test.assertIn("item_100_id", note)


def _assert_samples(test: unittest.TestCase, root: Path, output: Path, columns: Path, summary: list[str]) -> None:
    loot = tsv_file.read_table(output / "loot_box_entries.tsv")
    test.assertEqual(loot.columns[0], "box_key")
    test.assertEqual(loot.rows[0][0], "default")
    test.assertEqual(loot.rows[0][2], "10500002")
    test.assertEqual(loot.rows[0][5], "0")
    scenes = tsv_file.read_table(output / "scenes.tsv")
    test.assertEqual(len(scenes.rows), 923)
    test.assertEqual(scenes.rows[0][2], "洛阳")
    test.assertEqual(scenes.columns[-1], "within_declared_count")
    test.assertIn("pvp_rules", scenes.columns)
    test.assertNotIn("pvp_ruler", scenes.columns)
    test.assertEqual(scenes.rows[722][-1], "1")
    test.assertEqual(scenes.rows[723][-1], "0")
    notices = tsv_file.read_table(output / "rolling_announcements.tsv")
    test.assertNotIn("broadtime", notices.columns)
    test.assertNotIn("broadcount", notices.columns)
    test.assertTrue(all(row[-1] == "0" for row in notices.rows))
    events = tsv_file.read_table(output / "scheduled_events.tsv")
    test.assertNotIn("huodongcount", events.columns)
    test.assertTrue(all(row[-1] == "0" for row in events.rows))
    goods = tsv_file.read_table(output / "random_shop_goods.tsv")
    test.assertEqual(goods.columns[5], "odds_1")
    test.assertEqual(goods.columns[6], "odds_2")
    test.assertEqual(goods.columns[-1], "within_declared_count")
    outside = [row for row in goods.rows if row[-1] == "0"]
    test.assertEqual(len(outside), 1)
    effects = tsv_file.read_table(output / "effects.tsv")
    effect_source = root / "Server" / "Config" / "StandardImpact.txt"
    test.assertEqual(len(effects.rows), _records(effect_source))
    effect_line = next(line for line in summary if line.startswith("effects.tsv:"))
    test.assertIn("tên thật 76", effect_line)
    test.assertIn("cột ? 0", effect_line)
    test.assertIn("parameter_value_1", effect_line)
    segments = tsv_file.read_table(output / "item_segment_values.tsv")
    test.assertEqual(len(segments.columns), 65)
    segment_line = next(line for line in summary if line.startswith("item_segment_values.tsv:"))
    test.assertIn("ô sau kiểu bị bỏ 64", segment_line)
    notes = tsv_file.read_table(columns / "item_segment_values.tsv")
    test.assertEqual(len(notes.rows), 65)
    test.assertFalse(any("kiểu trống" in row[4] for row in notes.rows))
    text = "\n".join(summary)
    test.assertIn("dòng ngoài số khai báo 200", text)


class RealLegacyTest(unittest.TestCase):
    def test_real_tree(self) -> None:
        if not LEGACY:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT")
        root = Path(LEGACY)
        if not (root / "Server" / "Config").is_dir():
            self.fail(f"không thấy {root}")
        scratch = _scratch("real_tree")
        output = scratch / "out"
        columns = scratch / "columns"
        try:
            errors, summary = import_legacy.export_legacy(
                root,
                output,
                tsv_file.read_name_map(),
                column_dir=columns,
                include_script_index=True,
            )
            self.assertEqual(errors, [], errors[:5])
            _assert_outputs(self, output, columns)
            _assert_scripts(self, root, output, summary)
            _assert_samples(self, root, output, columns, summary)
            _assert_drop_code_notes(self, columns)
        finally:
            shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
