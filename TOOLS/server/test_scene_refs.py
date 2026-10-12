# Kiểm lời gọi LuaFnSetSceneLoad và hình dạng scene_attach.tsv.
from __future__ import annotations

import io
import os
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import scene_refs
import tsv_file

LEGACY = os.environ.get("THIENLONG_LEGACY_ROOT")
ATTACH = ROOT / "scene_attach.tsv"
SET_FILES = {
    "_pingpan_40_monster.ini": "_pingpan_1",
    "_pingpan_55_monster.ini": "_pingpan_1",
    "_pingpan_70_monster.ini": "_pingpan_1",
    "_pingpan_85_monster.ini": "_pingpan_1",
    "gongdishaolinmis_area.ini": "gongdi",
    "gongdishaolinmis_monster.ini": "gongdi",
    "jishiemeimis_area.ini": "jishi",
    "jishiemeimis_monster.ini": "jishi",
    "yamentianshanmis_area.ini": "yamen",
    "yamentianshanmis_monster.ini": "yamen",
}


class _Capture(io.StringIO):
    def reconfigure(self, **_kwargs: object) -> None:
        return None


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-c-refs" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _run(args: list[str]) -> tuple[int, str, str]:
    stdout = _Capture()
    stderr = _Capture()
    old_out = sys.stdout
    old_err = sys.stderr
    sys.stdout = stdout
    sys.stderr = stderr
    try:
        code = scene_refs.main(args)
    finally:
        sys.stdout = old_out
        sys.stderr = old_err
    return code, stdout.getvalue(), stderr.getvalue()


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def _fixture(root: Path) -> None:
    script = root / "Public" / "Data" / "Script" / "event" / "demo.lua"
    _write(
        script,
        "\n".join(
            [
                'local NAME = "plain_monster.ini"',
                'x_g_Map = "plain.nav"',
                '--LuaFnSetSceneLoad_Monster(sceneId, "hidden_monster.ini")',
                "function make(sceneId)",
                "  LuaFnSetSceneLoad_Map(sceneId, x_g_Map)",
                '  LuaFnSetSceneLoad_Monster(sceneId, "literal_monster.ini")',
                "  LuaFnSetSceneLoad_Monster(sceneId, NAME)",
                '  LuaFnSetSceneLoad_Monster(sceneId, "lvl_monster_" .. iniLevel .. ".ini")',
                "  LuaFnSetSceneLoad_Area(sceneId, unknownName)",
                "end",
                "",
            ]
        ),
    )


class SceneRefsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.legacy = self.root / "tlbb"
        self.dest = self.root / "tables"

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_resolves_literal_constant_format_and_skips_comment(self) -> None:
        _fixture(self.legacy)
        calls, commented = scene_refs.collect_calls(self.legacy / "Public" / "Data" / "Script")
        active = [call for call in calls if not call.commented]
        self.assertEqual(commented, 1)
        found = {(call.kind, call.how, call.resolved) for call in active}
        self.assertIn(("map", "constant", "plain.nav"), found)
        self.assertIn(("monster", "literal", "literal_monster.ini"), found)
        self.assertIn(("monster", "constant", "plain_monster.ini"), found)
        self.assertIn(("monster", "format", "lvl_monster_*.ini"), found)
        self.assertIn(("area", "unresolved", ""), found)
        self.assertEqual(len(active), 5)

    def test_block_comment_and_string_are_not_calls(self) -> None:
        script = self.legacy / "Public" / "Data" / "Script" / "block.lua"
        _write(
            script,
            "\n".join(
                [
                    "--[[",
                    'LuaFnSetSceneLoad_Map(1, "hidden.nav")',
                    "]]",
                    'local name = "shown.nav"',
                    "LuaFnSetSceneLoad_Monster(1, name)",
                    'print("LuaFnSetSceneLoad_Area(1, \\"in_string.nav\\")")',
                    "",
                ]
            ),
        )
        calls, commented = scene_refs.collect_calls(self.legacy / "Public" / "Data" / "Script")
        active = [call for call in calls if not call.commented]
        resolved = {call.resolved for call in active}
        kinds = {(call.kind, call.how, call.resolved) for call in active}
        self.assertNotIn("hidden.nav", resolved)
        self.assertNotIn("in_string.nav", resolved)
        self.assertEqual(kinds, {("monster", "constant", "shown.nav")})
        self.assertEqual(commented, 1)

    def test_disk_count_and_level_verdict(self) -> None:
        script = self.legacy / "Public" / "Data" / "Script" / "event" / "demo.lua"
        _write(
            script,
            "\n".join(
                [
                    'x_g_Map = "plain.nav"',
                    "function make(sceneId)",
                    "  LuaFnSetSceneLoad_Map(sceneId, x_g_Map)",
                    '  LuaFnSetSceneLoad_Monster(sceneId, "literal_monster.ini")',
                    '  LuaFnSetSceneLoad_Monster(sceneId, "plain_monster_10.ini")',
                    '  LuaFnSetSceneLoad_Monster(sceneId, "lvl_monster_" .. iniLevel .. ".ini")',
                    "  LuaFnSetSceneLoad_Area(sceneId, unknownName)",
                    "end",
                    "",
                ]
            ),
        )
        lost = self.legacy / "Public" / "Data" / "Script" / "event" / "lost.lua"
        _write(lost, 'LuaFnSetSceneLoad_Monster(1, "lost_monster_10.ini")\n')
        scene = self.legacy / "Public" / "Scene"
        _write(scene / "Literal_Monster.ini", "x\n")
        _write(scene / "lvl_monster_10.ini", "x\n")
        _write(scene / "plain_monster_10.ini", "x\n")
        _write(scene / "orphan_monster_10.ini", "x\n")
        _write(scene / "lost_monster_10.ini", "x\n")
        _write(scene / "plain.scn", "[System]\r\nnavmapname=plain.nav\r\n")
        code, out, err = _run([str(self.legacy), str(self.dest)])
        self.assertEqual(err, "")
        self.assertEqual(code, 0, out)
        table = tsv_file.read_table(self.dest / "scene_load_refs.tsv")
        by_resolved = {row[4]: row[-1] for row in table.rows}
        self.assertEqual(by_resolved["literal_monster.ini"], "1")
        self.assertEqual(by_resolved[""], "")
        self.assertEqual(by_resolved["lvl_monster_*.ini"], "1")
        levels = tsv_file.read_table(self.dest / "scene_level_files.tsv")
        self.assertEqual(levels.columns, ("file", "scene_by_name", "script_scenes", "verdict"))
        self.assertEqual(
            levels.rows,
            (
                ("lost_monster_10.ini", "", "", "map_unknown"),
                ("lvl_monster_10.ini", "", "plain", "mismatch"),
                ("orphan_monster_10.ini", "", "", "unpointed"),
                ("plain_monster_10.ini", "plain", "plain", "same"),
            ),
        )

    def test_unreadable_call_stays_unresolved(self) -> None:
        script = self.legacy / "Public" / "Data" / "Script" / "guess.lua"
        _write(
            script,
            "\n".join(
                [
                    "function make(sceneId)",
                    '  LuaFnSetSceneLoad_Monster(sceneId, Mystery() .. ".ini")',
                    '  LuaFnSetSceneLoad_Monster(sceneId, "shuilao_monster_" .. Mystery() .. ".ini")',
                    "end",
                    "",
                ]
            ),
        )
        scene = self.legacy / "Public" / "Scene"
        _write(scene / "plain.scn", "[System]\r\nnavmapname=plain.nav\r\n")
        _write(scene / "shuilao_monster_10.ini", "x\n")
        _write(scene / "shuilao_monster_99.ini", "x\n")
        _write(scene / "unrelated_monster_10.ini", "x\n")
        _write(scene / "notes.txt", "x\n")
        code, out, err = _run([str(self.legacy), str(self.dest)])
        self.assertEqual(err, "")
        self.assertEqual(code, 0, out)
        table = tsv_file.read_table(self.dest / "scene_load_refs.tsv")
        by_arg = {row[3]: row for row in table.rows}
        broad = by_arg['Mystery() .. ".ini"']
        self.assertEqual(broad[5], "unresolved")
        self.assertEqual(broad[6], "")
        self.assertNotEqual(broad[4], "*.ini")
        narrow = by_arg['"shuilao_monster_" .. Mystery() .. ".ini"']
        self.assertEqual(narrow[5], "unresolved")
        self.assertEqual(narrow[6], "")
        levels = tsv_file.read_table(self.dest / "scene_level_files.tsv")
        verdicts = {row[0]: row[3] for row in levels.rows}
        self.assertEqual(verdicts["shuilao_monster_99.ini"], "unpointed")
        self.assertEqual(verdicts["shuilao_monster_10.ini"], "unpointed")
        self.assertNotIn("notes.txt", verdicts)

    def test_level_file_case_matches_disk_count(self) -> None:
        script = self.legacy / "Public" / "Data" / "Script" / "case.lua"
        _write(
            script,
            "\n".join(
                [
                    'x_g_Map = "plain.nav"',
                    "function make(sceneId)",
                    "  LuaFnSetSceneLoad_Map(sceneId, x_g_Map)",
                    '  LuaFnSetSceneLoad_Monster(sceneId, "plain_monster_10.ini")',
                    "end",
                    "",
                ]
            ),
        )
        scene = self.legacy / "Public" / "Scene"
        _write(scene / "plain.scn", "[System]\r\nnavmapname=plain.nav\r\nmonsterfile=Plain_monster_10.ini\r\n")
        _write(scene / "Plain_monster_10.ini", "x\n")
        code, out, err = _run([str(self.legacy), str(self.dest)])
        self.assertEqual(err, "")
        self.assertEqual(code, 0, out)
        table = tsv_file.read_table(self.dest / "scene_load_refs.tsv")
        monster = [row for row in table.rows if row[2] == "monster"]
        self.assertEqual(len(monster), 1)
        self.assertEqual(monster[0][6], "1")
        levels = tsv_file.read_table(self.dest / "scene_level_files.tsv")
        self.assertEqual(levels.rows, (("Plain_monster_10.ini", "plain", "plain", "same"),))

    def test_format_local_long_string_and_name_table(self) -> None:
        script = self.legacy / "Public" / "Data" / "Script" / "copy.lua"
        _write(
            script,
            "\n".join(
                [
                    'x_g_CopySceneMonsterIni = "zhulin_monster_%d.ini"',
                    'names = {"tongrenxiang_1_monster", "gudi_1_monster"}',
                    "function make(sceneId)",
                    "  LuaFnSetSceneLoad_Map(sceneId, [[plain.nav]])",
                    "  local monsterINI = format(x_g_CopySceneMonsterIni, iniLevel)",
                    "  LuaFnSetSceneLoad_Monster(sceneId, monsterINI)",
                    '  LuaFnSetSceneLoad_Monster(sceneId, names[index] .. "_" .. tostring(iniLevel) .. ".ini")',
                    "end",
                    "",
                ]
            ),
        )
        calls, _commented = scene_refs.collect_calls(self.legacy / "Public" / "Data" / "Script")
        active = [call for call in calls if not call.commented]
        found = {(call.kind, call.how, call.resolved) for call in active}
        self.assertIn(("map", "literal", "plain.nav"), found)
        self.assertIn(("monster", "format", "zhulin_monster_%d.ini"), found)
        patterns = [call.resolved for call in active if call.how == "format"]
        self.assertTrue(any("tongrenxiang_1_monster_" in pattern for pattern in patterns))
        self.assertTrue(scene_refs._points_at(active[-1], "tongrenxiang_1_monster_10.ini"))
        self.assertTrue(scene_refs._points_at(active[-1], "gudi_1_monster_20.ini"))

    def test_check_does_not_write_and_keeps_import_legacy(self) -> None:
        _fixture(self.legacy)
        kept = self.dest / "scenes.tsv"
        tsv_file.write_table(kept, "Server/Config/SceneInfo.ini", "import_legacy.py", ["int"], ["id"], [("1",)])
        foreign = self.dest / "note.txt"
        foreign.write_text("giữ\n", encoding="utf-8")
        code, _out, _err = _run([str(self.legacy), str(self.dest), "--check"])
        self.assertEqual(code, 0)
        self.assertFalse((self.dest / "scene_load_refs.tsv").exists())
        self.assertTrue(kept.is_file())
        self.assertEqual(foreign.read_text(encoding="utf-8"), "giữ\n")

    def test_write_keeps_import_legacy_and_rejects_foreign(self) -> None:
        _fixture(self.legacy)
        kept = self.dest / "scenes.tsv"
        tsv_file.write_table(kept, "Server/Config/SceneInfo.ini", "import_legacy.py", ["int"], ["id"], [("1",)])
        code, out, err = _run([str(self.legacy), str(self.dest)])
        self.assertEqual(err, "")
        self.assertEqual(code, 0, out)
        self.assertTrue(kept.is_file())
        table = tsv_file.read_table(self.dest / "scene_load_refs.tsv")
        self.assertEqual(table.columns, scene_refs.COLUMNS)
        self.assertNotIn("hidden_monster.ini", {row[4] for row in table.rows})
        foreign = self.dest / "note.txt"
        foreign.write_text("lạ\n", encoding="utf-8")
        again, text, err = _run([str(self.legacy), str(self.dest)])
        self.assertEqual(err, "")
        self.assertEqual(again, 1)
        self.assertIn("tệp lạ", text)
        self.assertTrue(kept.is_file())

    def test_attach_shape(self) -> None:
        text = ATTACH.read_text(encoding="utf-8")
        self.assertNotIn("# tool:", text)
        lines = [line for line in text.splitlines() if line]
        self.assertEqual(lines[0], "# schema 1")
        self.assertIn("# types: text\ttext\ttext\ttext", lines)
        rows = [line.split("\t") for line in lines if not line.startswith("#")]
        header = rows[0]
        body = rows[1:]
        self.assertEqual(header, ["file", "fate", "scene", "evidence"])
        files = [row[0] for row in body]
        self.assertEqual(len(files), 45)
        self.assertEqual(len(files), len(set(files)))
        by_file = {row[0]: row for row in body}
        for name, scene in SET_FILES.items():
            row = by_file[name]
            self.assertEqual(row[1], "scene_set")
            self.assertEqual(row[2], scene)
            self.assertIn(".lua:", row[3])
        clients = [row for row in body if row[1] == "client_only"]
        self.assertEqual(len(clients), 35)
        for row in clients:
            self.assertEqual(row[2], "")
            self.assertIn(row[0], row[3])
            self.assertTrue(row[3].startswith("findstr "))


def _assert_real_level(case: unittest.TestCase, folder: Path, calls: list[scene_refs.LoadCall]) -> None:
    table = tsv_file.read_table(folder / "scene_load_refs.tsv")
    case.assertEqual(table.columns, scene_refs.COLUMNS)
    disk = {row[4]: row[6] for row in table.rows if row[0] == "event/fuben/efuben_3_shuilao.lua"}
    missing = (
        "shuilao_monster_15.ini",
        "shuilao_monster_25.ini",
        "shuilao_monster_35.ini",
        "shuilao_monster_45.ini",
    )
    for name in missing:
        case.assertEqual(disk[name], "0", name)
    case.assertEqual(disk["shuilao_monster_10.ini"], "1")
    unresolved = [row[6] for row in table.rows if row[5] == "unresolved"]
    case.assertTrue(unresolved)
    case.assertTrue(all(cell == "" for cell in unresolved))
    levels = tsv_file.read_table(folder / "scene_level_files.tsv")
    counts: dict[str, int] = {}
    for row in levels.rows:
        counts[row[3]] = counts.get(row[3], 0) + 1
    case.assertEqual(len(levels.rows), 1344)
    case.assertEqual(counts, {"same": 863, "mismatch": 80, "unpointed": 221, "map_unknown": 180})
    fresh = scene_refs.compare_level_files(Path(LEGACY or ""), calls)
    case.assertEqual([row[3] for row in levels.rows], [scene_refs._level_verdict(row) for row in fresh])


class RealScriptTest(unittest.TestCase):
    def test_real_scripts_if_present(self) -> None:
        if not LEGACY:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT")
        root = _scratch("real")
        try:
            calls, commented = scene_refs.collect_calls(Path(LEGACY) / "Public" / "Data" / "Script")
            active = [call for call in calls if not call.commented]
            self.assertEqual(commented, 5)
            self.assertEqual(len(calls) - commented, len(active))
            counts = scene_refs._how_counts(calls)
            self.assertEqual(sum(counts.values()), len(active))
            resolved = {call.resolved for call in active}
            for name in SET_FILES:
                self.assertIn(name, resolved)
            rows = scene_refs.compare_level_files(Path(LEGACY), calls)
            self.assertEqual(len(rows), 1344)
            code, out, err = _run([LEGACY, str(root / "server")])
            self.assertEqual(err, "")
            self.assertEqual(code, 0, out)
            self.assertTrue((root / "server" / "scene_load_refs.tsv").is_file())
            self.assertIn("chú thích bỏ qua: 5", out)
            _assert_real_level(self, root / "server", calls)
        finally:
            shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    unittest.main()
