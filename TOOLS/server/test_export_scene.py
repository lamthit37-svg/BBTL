# Kiểm xuất cảnh: từ chối đầu vào hỏng, giữ ô nguyên văn, không ghi khi --check.
from __future__ import annotations

import os
import shutil
import struct
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import export_scene
import lint_config
import tsv_file

LEGACY = os.environ.get("THIENLONG_LEGACY_ROOT")
CRLF = "\r\n"


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-c" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _snapshot(folder: Path) -> dict[str, bytes]:
    if not folder.is_dir():
        return {}
    found: dict[str, bytes] = {}
    for path in sorted(folder.rglob("*")):
        if path.is_file():
            found[path.relative_to(folder).as_posix()] = path.read_bytes()
    return found


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.replace("\n", CRLF).encode("utf-8"))


def _nav(path: Path, width: int, height: int) -> None:
    body = struct.pack("<HH", width, height) + (b"\x01\x00\x00\x00" * (width * height))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(body)


def _monster(path: Path, extra: str = "", count: int = 1, guid: int = 10) -> None:
    blocks = ["[info]", f"monstercount={count}", ""]
    for index in range(count):
        blocks.extend(
            [
                f"[monster{index}]",
                f"guid={guid + index}",
                "type=3",
                "name=vịt",
                "title=",
                "pos_x=1.50",
                "pos_z=2",
                "dir=9",
                "script_id=4",
                "respawn_time=5",
                "group_id=6",
                "team_id=7",
                "base_ai=1",
                "ai_file=2",
                "patrol_id=0",
                "shop0=-1",
                "shop1=-1",
                "shop2=-1",
                "shop3=-1",
                extra,
                "",
            ]
        )
    _write(path, "\n".join(blocks))


def _scene_tree(root: Path, name: str = "demo", monster_extra: str = "") -> None:
    scene = root / "Public" / "Scene"
    _write(
        scene / f"{name}.scn",
        "\n".join(
            [
                "[System]",
                f"navmapname={name}.nav",
                f"monsterfile={name}_monster.ini",
                f"eventfile={name}_area.ini",
                f"patrolpoint={name}_patrolpoint.ini",
                "",
            ]
        ),
    )
    _nav(scene / f"{name}.nav", 2, 2)
    _monster(scene / f"{name}_monster.ini", monster_extra)
    _write(scene / f"{name}_area.ini", "[area_info]\narea_count=0\n")
    _write(scene / f"{name}_patrolpoint.ini", "[INFO]\nPATROLNUMBER=0\n")


def _level_operate_monster(path: Path) -> None:
    _write(
        path,
        "\n".join(
            [
                "[setting]",
                "operatecount=1",
                "datacount=0",
                "[operate0]",
                "selecttype=5",
                "selectvalue=1",
                "data_def=0",
                "maxleft=10",
                "[info]",
                "monstercount=1",
                "[monster0]",
                "guid=1",
                "type=2",
                "pos_x=3",
                "pos_z=4",
                "dir=5",
                "script_id=6",
                "respawn_time=7",
                "group_id=8",
                "team_id=9",
                "patrol_id=0",
                "",
            ]
        ),
    )


def _script_attach(path: Path) -> None:
    _write(
        path,
        "\n".join(
            [
                "# schema 1",
                "# types: text\ttext\ttext\ttext",
                "file\tfate\tscene\tevidence",
                "side_monster.ini\tscene_set\tdemo\tfixture:1",
                "side_area.ini\tscene_set\tdemo\tfixture:2",
                "login.nav\tclient_only\t\tfixture:3",
                "",
            ]
        ),
    )


def _level_patrol_scene(legacy: Path) -> None:
    _scene_tree(legacy)
    scene = legacy / "Public" / "Scene"
    monster_text = (scene / "demo_monster.ini").read_text(encoding="utf-8")
    monster_text = monster_text.replace("script_id=4", "script_id=040001")
    monster_text = monster_text.replace("shop3=-1\n", "shop3=-1\nlevel=-1\n")
    _write(scene / "demo_monster.ini", monster_text)
    _write(scene / "demo_monster_level.ini", "[monster0]\nlevel=63\n")
    patrol_lines = [
        "[INFO]",
        "PATROLNUMBER=1",
        "[PATROL0]",
        "PATROLPOINTNUM=1 ",
        "POSX0=1.25",
        "POSY0=9.5",
        "POSZ0=3",
        "scriptid=050031",
        "paopao0_1=155",
        "isturnback=0",
        "isTeleportToRespawnPos=0 ",
        "",
    ]
    _write(scene / "demo_patrolpoint.ini", "\n".join(patrol_lines))
    grow_text = "INT\tINT\tFLOAT\tFLOAT\nINT\tINT\tFLOAT\tFLOAT\n1\t8\t1.50\t2.25\n"
    _write(scene / "demo_growpoint.txt", grow_text)
    kind_line = "INT\tINT\tINT\tSTRING\tINT\tINT\n"
    name_line = "类型\t数量\t每次生成数量\t生成函数\t种子补充的间隔时间\t补充时间随机增量\n"
    rule_line = "620\t1\t1\t\t3900000\t3600000\n"
    _write(scene / "demo_growpointsetup.txt", kind_line + name_line + rule_line)
    text = (scene / "demo.scn").read_text(encoding="utf-8")
    added = "[System]\ngrowpointdata=demo_growpoint.txt\ngrowpointsetup=demo_growpointsetup.txt\n"
    text = text.replace("[System]\n", added)
    _write(scene / "demo.scn", text)


class ExportSceneTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.legacy = self.root / "tlbb"
        self.dest = self.root / "out"
        self.columns = self.root / "columns"

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _export(self, check_only: bool = False) -> export_scene.Report:
        return export_scene.export_scenes(self.legacy, self.dest, self.columns, check_only)

    def test_minimal_scene_roundtrip(self) -> None:
        _scene_tree(self.legacy, monster_extra="ReputationID=9")
        report = self._export()
        self.assertTrue(report.ok, report.errors)
        self.assertEqual(report.scene_count, 1)
        self.assertEqual(report.kinds["scn"], 1)
        scene = self.dest / "demo"
        table = tsv_file.read_table(scene / "spawns.tsv")
        self.assertEqual(table.rows[0][table.columns.index("position_x")], "1.50")
        self.assertEqual(table.rows[0][table.columns.index("reputation_id")], "9")
        nav_out = (scene / "walk.nav").read_bytes()
        nav_src = (self.legacy / "Public" / "Scene" / "demo.nav").read_bytes()
        self.assertEqual(nav_out, nav_src)
        problems = lint_config.check_file(scene / "scene.toml")
        self.assertEqual(problems, [])
        text = (scene / "scene.toml").read_text(encoding="utf-8")
        self.assertRegex(text, r"schema\s+=\s+1")
        self.assertIn("grid_width", text)
        self.assertIn("grid_height", text)
        column = tsv_file.read_table(self.columns / "spawns.tsv")
        notes = {row[2]: row[4] for row in column.rows}
        self.assertIn("không đọc", notes["reputation_id"])
        self.assertEqual(notes["level"], "cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào")

    def test_check_writes_nothing(self) -> None:
        _scene_tree(self.legacy)
        report = self._export(check_only=True)
        self.assertTrue(report.ok, report.errors)
        self.assertFalse(self.dest.exists())
        self.assertFalse(self.columns.exists())

    def test_reject_nav_size(self) -> None:
        _scene_tree(self.legacy)
        (self.legacy / "Public" / "Scene" / "demo.nav").write_bytes(struct.pack("<HH", 2, 2))
        report = self._export()
        self.assertFalse(report.ok)
        self.assertIn("không khớp", report.errors[0])
        self.assertFalse((self.dest / "demo" / "walk.nav").exists())

    def test_reject_unknown_key(self) -> None:
        _scene_tree(self.legacy, monster_extra="foo=1")
        report = self._export()
        self.assertFalse(report.ok)
        self.assertIn("khoá lạ", report.errors[0])

    def test_reject_count_mismatch(self) -> None:
        _scene_tree(self.legacy)
        path = self.legacy / "Public" / "Scene" / "demo_monster.ini"
        text = path.read_text(encoding="utf-8").replace("monstercount=1", "monstercount=2")
        path.write_bytes(text.replace("\n", CRLF).encode("utf-8"))
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(any("monstercount" in error for error in report.errors))

    def test_reject_tab_inside_value(self) -> None:
        _scene_tree(self.legacy, monster_extra="title=a\tb")
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(any(":title: ô chứa tab" in error for error in report.errors))
        self.assertFalse(self.dest.exists())

    def test_tab_padding_before_comment_is_value(self) -> None:
        _scene_tree(self.legacy)
        scene = self.legacy / "Public" / "Scene"
        _write(
            scene / "demo.scn",
            "\n".join(
                [
                    "[System]",
                    "navmapname=demo.nav",
                    "monsterfile=demo_monster.ini",
                    "eventfile=demo_area.ini",
                    "patrolpoint=demo_patrolpoint.ini",
                    "platformfile=demo_platform.ini",
                    "",
                ]
            ),
        )
        _write(
            scene / "demo_platform.ini",
            "[info]\nplatformcount=1\n\n[platform0]\nindex=17\t\t;số\n"
            "class=10\npos_X=1.5\npos_Z=2\ndir=3\nTip=bến\t;\n",
        )
        report = self._export()
        self.assertTrue(report.ok, report.errors)
        table = tsv_file.read_table(self.dest / "demo" / "platforms.tsv")
        self.assertEqual(table.rows[0][table.columns.index("tip")], "bến")
        column = tsv_file.read_table(self.columns / "platforms.tsv")
        notes = {row[2]: row[4] for row in column.rows}
        self.assertIn("không đọc", notes["tip"])

    def test_reject_bad_utf8(self) -> None:
        _scene_tree(self.legacy)
        path = self.legacy / "Public" / "Scene" / "demo_area.ini"
        path.write_bytes(b"[area_info]\r\narea_count=0\r\n\xff\r\n")
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(any("UTF-8" in error for error in report.errors))

    def test_int32_overflow_names_source_line(self) -> None:
        _scene_tree(self.legacy)
        path = self.legacy / "Public" / "Scene" / "demo_monster.ini"
        _monster(path, count=2)
        raw = path.read_text(encoding="utf-8")
        head, tail = raw.split("[monster1]", 1)
        tail = tail.replace("type=3", "type=9999999999", 1)
        merged = (head + "[monster1]" + tail).replace("\r\n", "\n").replace("\r", "\n")
        _write(path, merged)
        source_line = merged.splitlines().index("type=9999999999") + 1
        self.assertGreater(source_line, 1)
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(report.errors)
        self.assertIn(f"spawns.tsv:{source_line}: số vượt int32", report.errors[0])
        self.assertNotIn("spawns.tsv:1: số vượt int32", report.errors[0])

    def test_reject_hash_name(self) -> None:
        _scene_tree(self.legacy)
        path = self.legacy / "Public" / "Scene" / "demo_monster.ini"
        text = path.read_text(encoding="utf-8").replace("guid=10", "guid=#10")
        _write(path, text)
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(any("#" in error for error in report.errors))

    def test_keep_duplicate_guid(self) -> None:
        scene = self.legacy / "Public" / "Scene"
        _scene_tree(self.legacy)
        _monster(scene / "demo_monster.ini", count=2, guid=5)
        text = (scene / "demo_monster.ini").read_text(encoding="utf-8").replace("guid=6", "guid=5")
        _write(scene / "demo_monster.ini", text)
        report = self._export()
        self.assertTrue(report.ok, report.errors)
        table = tsv_file.read_table(self.dest / "demo" / "spawns.tsv")
        self.assertEqual([row[0] for row in table.rows], ["5", "5"])
        self.assertGreaterEqual(report.changes.get("duplicate_guid", 0), 1)

    def test_reject_case_collision(self) -> None:
        # Windows không giữ hai tên chỉ khác chữ hoa trong một thư mục, nên kiểm hàm dùng khi gán cảnh.
        message = export_scene.case_conflict({"Demo", "demo"})
        self.assertIsNotNone(message)
        self.assertIn("chữ hoa", message or "")
        self.assertIsNone(export_scene.case_conflict({"luoyang", "dali"}))

    def test_reject_unclassified(self) -> None:
        _scene_tree(self.legacy)
        _write(self.legacy / "Public" / "Scene" / "notes.dat", "x\n")
        report = self._export()
        self.assertFalse(report.ok)
        self.assertTrue(any("chưa phân loại" in error for error in report.errors))

    def test_reject_foreign_destination(self) -> None:
        _scene_tree(self.legacy)
        first = self._export()
        self.assertTrue(first.ok, first.errors)
        foreign = self.dest / "demo" / "keep.txt"
        foreign.write_text("giữ\n", encoding="utf-8")
        owned = (self.dest / "demo" / "spawns.tsv").read_bytes()
        second = self._export()
        self.assertFalse(second.ok)
        self.assertIn("tệp lạ", second.errors[0])
        self.assertEqual(foreign.read_text(encoding="utf-8"), "giữ\n")
        self.assertEqual((self.dest / "demo" / "spawns.tsv").read_bytes(), owned)

    def test_check_rejects_foreign_without_deleting(self) -> None:
        _scene_tree(self.legacy)
        first = self._export()
        self.assertTrue(first.ok, first.errors)
        foreign = self.dest / "demo" / "keep.txt"
        foreign.write_text("giữ\n", encoding="utf-8")
        before_dest = _snapshot(self.dest)
        before_columns = _snapshot(self.columns)
        report = self._export(check_only=True)
        self.assertFalse(report.ok)
        self.assertTrue(any("tệp lạ" in error for error in report.errors))
        self.assertEqual(foreign.read_text(encoding="utf-8"), "giữ\n")
        self.assertEqual(_snapshot(self.dest), before_dest)
        self.assertEqual(_snapshot(self.columns), before_columns)

    def test_level_override_and_patrol_unread(self) -> None:
        _level_patrol_scene(self.legacy)
        report = self._export()
        self.assertTrue(report.ok, report.errors)
        spawns = tsv_file.read_table(self.dest / "demo" / "spawns.tsv")
        self.assertEqual(spawns.rows[0][spawns.columns.index("level")], "-1")
        self.assertEqual(spawns.rows[0][spawns.columns.index("script_id")], "40001")
        self.assertNotIn("monster_level", spawns.source)
        levels = tsv_file.read_table(self.dest / "demo" / "spawn_levels.tsv")
        self.assertEqual(levels.rows, (("0", "63"),))
        self.assertTrue(any(place.endswith(":script_id") for place in report.int_places))
        self.assertTrue(any(place.endswith(":teleport_to_respawn") for place in report.int_places))
        self.assertTrue(any(place.endswith(":PATROLPOINTNUM") for place in report.int_places))
        level_note = tsv_file.read_table(self.columns / "spawns.tsv")
        notes = {row[2]: row[4] for row in level_note.rows}
        self.assertNotIn("ghi đè", notes["level"])
        patrols = tsv_file.read_table(self.dest / "demo" / "patrols.tsv")
        self.assertEqual(patrols.rows[0][patrols.columns.index("position_y")], "9.5")
        self.assertEqual(patrols.rows[0][patrols.columns.index("teleport_to_respawn")], "0")
        self.assertEqual(patrols.rows[0][patrols.columns.index("route_script_id")], "050031")
        self.assertGreaterEqual(report.changes.get("cells_rewritten", 0), 2)
        self.assertEqual(patrols.rows[0][patrols.columns.index("speech_1")], "155")
        points = tsv_file.read_table(self.dest / "demo" / "grow_points.tsv")
        self.assertEqual(points.rows[0][points.columns.index("position_x")], "1.50")
        rules = tsv_file.read_table(self.dest / "demo" / "grow_point_rules.tsv")
        self.assertEqual(rules.rows[0][rules.columns.index("column_4")], "3900000")
        rule_columns = tsv_file.read_table(self.columns / "grow_point_rules.tsv")
        notes = {row[2]: row[4] for row in rule_columns.rows}
        self.assertIn("?", notes["column_4"])

    def test_operate_value_extra_kept(self) -> None:
        _scene_tree(self.legacy)
        scene = self.legacy / "Public" / "Scene"
        _write(
            scene / "demo_monster.ini",
            "\n".join(
                [
                    "[setting]",
                    "operatecount=1",
                    "datacount=1",
                    "[operate0]",
                    "selecttype=5",
                    "selectvalue=1",
                    "data_def=0",
                    "maxleft=10",
                    "[data_def0]",
                    "datatype=3",
                    "count=1",
                    "value0=55",
                    "valueex0=30",
                    "[info]",
                    "monstercount=1",
                    "[monster0]",
                    "guid=1",
                    "type=2",
                    "pos_x=3",
                    "pos_z=4",
                    "dir=5",
                    "script_id=6",
                    "respawn_time=7",
                    "group_id=8",
                    "team_id=9",
                    "patrol_id=0",
                    "",
                ]
            ),
        )
        report = self._export()
        self.assertTrue(report.ok, report.errors)
        values = tsv_file.read_table(self.dest / "demo" / "spawn_operate_values.tsv")
        self.assertEqual(values.rows[0][values.columns.index("value_extra")], "30")

    def test_level_operate_names_and_script_set(self) -> None:
        _scene_tree(self.legacy)
        scene = self.legacy / "Public" / "Scene"
        _level_operate_monster(scene / "demo_monster_10.ini")
        _monster(scene / "side_monster.ini")
        _write(scene / "side_area.ini", "[area_info]\narea_count=0\n")
        _nav(scene / "login.nav", 1, 1)
        attach = self.root / "attach.tsv"
        _script_attach(attach)
        report = export_scene.export_scenes(self.legacy, self.dest, self.columns, False, attach)
        self.assertTrue(report.ok, report.errors)
        self.assertTrue((self.dest / "demo" / "spawn_operates.level_10.tsv").is_file())
        self.assertFalse((self.dest / "demo" / "ops.level_10.tsv").exists())
        self.assertTrue((self.dest / "demo" / "spawns.set_side.tsv").is_file())
        self.assertTrue((self.dest / "demo" / "areas.set_side.tsv").is_file())
        self.assertEqual(report.changes.get("client_only"), 1)
        self.assertFalse((self.dest / "login").exists())
        text = (self.dest / "demo" / "scene.toml").read_text(encoding="utf-8")
        self.assertNotIn("ops.", text)
        problems = lint_config.check_file(self.dest / "demo" / "scene.toml")
        self.assertEqual(problems, [])

    def test_orphan_scene_and_dropped_test_file(self) -> None:
        _scene_tree(self.legacy)
        scene = self.legacy / "Public" / "Scene"
        _write(scene / "testdata.txt", "không xuất\n")
        _nav(scene / "stray.nav", 1, 1)
        _monster(scene / "stray_monster.ini")
        report = self._export()
        self.assertFalse(report.ok)
        self.assertEqual(report.kinds["dropped"], 1)
        self.assertEqual(report.orphan_scene_count, 0)
        loose_nav = "stray.nav:1: không gắn được vào cảnh nào"
        loose_monster = "stray_monster.ini:1: không gắn được vào cảnh nào"
        self.assertTrue(any(error.endswith(loose_nav) for error in report.errors))
        self.assertTrue(any(loose_monster in error for error in report.errors))
        self.assertFalse(any("testdata" in error for error in report.errors))
        self.assertFalse((self.dest / "stray").exists())
        self.assertFalse(self.dest.exists())

    def test_deterministic_bytes(self) -> None:
        _scene_tree(self.legacy)
        other = self.root / "out2"
        first = self._export()
        second = export_scene.export_scenes(self.legacy, other, self.root / "columns2", False)
        self.assertTrue(first.ok and second.ok, first.errors + second.errors)
        left_paths = [path for path in self.dest.rglob("*") if path.is_file()]
        right_paths = [path for path in other.rglob("*") if path.is_file()]
        left = sorted((path.relative_to(self.dest).as_posix(), path.read_bytes()) for path in left_paths)
        right = sorted((path.relative_to(other).as_posix(), path.read_bytes()) for path in right_paths)
        self.assertEqual(left, right)

    def test_published_spawn_level_note(self) -> None:
        column = tsv_file.read_table(ROOT / "columns" / "scenes" / "spawns.tsv")
        notes = {row[2]: row[4] for row in column.rows}
        self.assertEqual(notes["level"], "cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào")
        self.assertNotIn("ghi đè", notes["level"])

    def test_help_and_cli_error(self) -> None:
        help_run = subprocess.run(
            [sys.executable, "-W", "error", str(ROOT / "export_scene.py"), "--help"],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        self.assertEqual(help_run.returncode, 0)
        self.assertIn("không ghi", help_run.stdout)
        bad = subprocess.run(
            [sys.executable, "-W", "error", str(ROOT / "export_scene.py"), str(self.legacy), str(self.dest)],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        self.assertEqual(bad.returncode, 1)
        self.assertIn(":", bad.stdout)


def _one_scene(report: export_scene.Report, name: str) -> export_scene.Scene:
    found = [scene for scene in report.scenes if scene.name == name]
    if len(found) != 1:
        raise AssertionError(name)
    return found[0]


def _assert_script_sets(case: unittest.TestCase, destination: Path, report: export_scene.Report) -> None:
    case.assertEqual(report.changes.get("client_only"), 35)
    case.assertTrue((destination / "_pingpan_1" / "spawns.set__pingpan_40.tsv").is_file())
    case.assertTrue((destination / "gongdi" / "areas.set_gongdishaolinmis.tsv").is_file())
    case.assertTrue((destination / "jishi" / "spawns.set_jishiemeimis.tsv").is_file())
    case.assertTrue((destination / "yamen" / "spawns.set_yamentianshanmis.tsv").is_file())
    case.assertEqual(list(destination.rglob("ops.*.tsv")), [])
    case.assertEqual(list(destination.rglob("vals.*.tsv")), [])
    case.assertFalse((destination / "chuangjian").exists())
    case.assertFalse((destination / "登陆").exists())


def _one_table(scene: export_scene.Scene, relative: str) -> export_scene.Table:
    found = [table for table in scene.tables if table.relative == relative]
    if len(found) != 1:
        raise AssertionError(relative)
    return found[0]


class RealSceneTest(unittest.TestCase):
    def test_real_tree_if_present(self) -> None:
        if not LEGACY:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT")
        root = _scratch("real")
        destination = root / "scenes"
        columns = root / "columns"
        try:
            report = export_scene.export_scenes(Path(LEGACY), destination, columns, False)
            loose = [error for error in report.errors if "không gắn" in error]
            self.assertTrue(report.ok, report.errors)
            self.assertEqual(loose, [])
            self.assertEqual(report.orphan_scene_count, 0)
            self.assertEqual(sum(report.kinds.values()), 3251)
            _assert_script_sets(self, destination, report)
            self.assertFalse(any(scene.name in {"chuangjian", "登陆"} for scene in report.scenes))
            luoyang = _one_scene(report, "luoyang")
            nav_path = luoyang.nav
            if nav_path is None:
                self.fail("luoyang thiếu nav")
            self.assertEqual(nav_path.stat().st_size, 1_638_404)
            self.assertEqual(luoyang.grid, (640, 640))
            text = export_scene._render_toml(luoyang)
            self.assertRegex(text, r"grid_width\s+=\s+640")
            self.assertRegex(text, r"grid_height\s+=\s+640")
            caoyuan = _one_scene(report, "caoyuan")
            spawns = _one_table(caoyuan, "spawns.tsv")
            self.assertNotIn("monster_level", spawns.source)
            self.assertEqual(spawns.rows[67][spawns.columns.index("level")], "-1")
            levels = _one_table(caoyuan, "spawn_levels.tsv")
            self.assertEqual(levels.rows[67], ("67", "63"))
            self.assertEqual(report.changes["padded_count"], 24)
            self.assertEqual(report.changes["int_not_canonical"], 289)
            self.assertEqual(report.changes["cells_rewritten"], 266)
            self.assertEqual(len(report.int_places), 289)
            self.assertEqual(sum(place.endswith(":teleport_to_respawn") for place in report.int_places), 200)
            self.assertEqual(sum(place.endswith(":script_id") for place in report.int_places), 65)
            self.assertEqual(sum(place.endswith(":PATROLPOINTNUM") for place in report.int_places), 24)
            problems = []
            toml_dir = root / "toml"
            toml_dir.mkdir()
            for scene in report.scenes:
                path = toml_dir / f"{scene.name}.toml"
                path.write_text(export_scene._render_toml(scene), encoding="utf-8", newline="\n")
                problems.extend(lint_config.check_file(path))
            self.assertEqual(problems, [])
        finally:
            shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    unittest.main(verbosity=2)
