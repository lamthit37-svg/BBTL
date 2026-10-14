# Kiểm bộ công cụ cảnh XJL7457: đối chiếu id, nhập cảnh, nguồn lưới đi, so sánh với 0859602, đổi kịch bản AI.
# Mọi ca dựng một thế giới nhỏ trong thư mục tạm (GBK như bản private); không đọc XJL7457 thật.
from __future__ import annotations

import io
import struct
import sys
import tempfile
import unittest
from collections.abc import Callable
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import ai_convert
import import_scene_xjl
import scene_diff
import scene_walk
import scene_xref
import tsv_file

CRLF = "\r\n"
EXPORT_TOOL_LINE = "# tool: TOOLS/server/export_scene.py" + tsv_file.TOOL_SUFFIX
SCENE_INFO_XJL = """[scene0]
name=洛阳
file=luoyang.scn
clientres=1
active=1

[scene7]
name=测试城
file=demo.scn
clientres=2 ;chú thích sau giá trị
active=1

[scene8]
name=私服城
file=secret.scn
clientres=99
active=1
"""


def _run_main(main: Callable[[list[str]], int], args: list[str]) -> tuple[int, str]:
    """Chạy main() với stdout là bộ đệm UTF-8 có `reconfigure`, như tiến trình thật."""
    wrapper = io.TextIOWrapper(io.BytesIO(), encoding="utf-8", newline="\n")
    with redirect_stdout(wrapper):
        code = main(args)
    wrapper.flush()
    return code, wrapper.buffer.getvalue().decode("utf-8")  # type: ignore[attr-defined]


def _gbk(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.replace("\n", CRLF).encode("gb18030"))


def _table(path: Path, types: list[str], columns: list[str], rows: list[tuple[str, ...]]) -> None:
    tsv_file.write_table(path, "fixture/mẫu", "TOOLS/server/export_tables.py", types, columns, rows)


def _attr_row(number: int, name: str, res: int) -> tuple[str, ...]:
    return (str(number), name, *(["0"] * 23), str(res))


def _define_row(res: int, stem: str) -> tuple[str, ...]:
    cells = [str(res)] + [""] * 24
    cells[4] = f"{stem}.Scene"
    cells[5] = f"{stem}.path"
    return tuple(cells)


def _monster_text(name: str, repeat: bool = False) -> str:
    keys = [
        "guid=10", "type=3", f"name={name}", "title=", "pos_x=1.50", "pos_z=2", "dir=9", "script_id=4",
        "respawn_time=5", "group_id=6", "team_id=7", "base_ai=1", "ai_file=2", "patrol_id=0",
        "shop0=-1", "shop1=-1", "shop2=-1", "shop3=-1",
    ]  # fmt: skip
    block = "[monster0]\n" + "\n".join(keys) + "\n"
    return "[info]\nmonstercount=1\n\n" + block + (block if repeat else "")


def _write_client_tables(server: Path) -> None:
    attr_columns = [f"column_{index}" for index in range(26)]
    attr_types = ["int", "text", *(["int"] * 24)]
    rows = [_attr_row(0, "洛阳", 1), _attr_row(5, "测试城", 2), _attr_row(6, "客户端独有", 3)]
    _table(server / "tables" / "shared" / "scene_attributes.tsv", attr_types, attr_columns, rows)
    define_columns = [f"column_{index}" for index in range(25)]
    define_rows = [_define_row(1, "luoyang"), _define_row(2, "demo"), _define_row(3, "alone")]
    define_types = ["int", *(["text"] * 24)]
    _table(server / "tables" / "shared" / "scene_definitions.tsv", define_types, define_columns, define_rows)
    legacy = [("0", "1", "洛阳", "luoyang.scn"), ("3", "50", "旧城", "old.scn")]
    _table(server / "tables" / "server" / "scenes.tsv", ["int", "int", "text", "text"],
           ["scene_id", "clientres_1", "name", "file"], legacy)  # fmt: skip


def _write_legacy_dirs(server: Path) -> None:
    for name in ("luoyang", "old"):
        folder = server / "scenes" / name
        folder.mkdir(parents=True)
        (folder / "scene.toml").write_text(f"{EXPORT_TOOL_LINE}\nschema = 1\n", encoding="utf-8", newline="\n")
    (server / "scenes" / "old" / "walk.nav").write_bytes(b"\x01\x00\x01\x00\x01\x00\x00\x00")


def _write_xjl(xjl: Path, monster_repeat: bool) -> None:
    _gbk(xjl / "Server" / "Config" / "SceneInfo.ini", SCENE_INFO_XJL)
    scene = xjl / "Public" / "Scene"
    scn = "[System]\nmonsterfile=demo_monster.ini\neventfile=demo_area.ini\npatrolpoint=demo_patrolpoint.ini\n"
    _gbk(scene / "demo.scn", scn)
    _gbk(scene / "demo_monster.ini", _monster_text("鸭", monster_repeat))
    _gbk(scene / "demo_area.ini", "[area_info]\narea_count=0\n")
    _gbk(scene / "demo_patrolpoint.ini", "[INFO]\nPATROLNUMBER=0\n")
    _gbk(scene / "secret.scn", "[System]\n")
    _gbk(scene / "luoyang.scn", "[System]\n")


def _path_bytes(points: list[tuple[float, float]], wide: bool = False) -> bytes:
    """Đầu tệp .path (số bản, số đỉnh, đỉnh); đủ cho mesh_bounds, không đủ cho bộ đọc đầy đủ."""
    version, count = (0x2000, struct.pack("<I", len(points))) if wide else (0x1000, struct.pack("<H", len(points)))
    return struct.pack("<H", version) + count + b"".join(struct.pack("<ff", x, z) for x, z in points)


def _write_client_scene(client: Path) -> None:
    client.mkdir(parents=True)
    for stem in ("luoyang", "demo"):
        (client / f"{stem}.Scene").write_bytes(b"scene")
        (client / f"{stem}.path").write_bytes(f"path-{stem}".encode())


class WorldCase(unittest.TestCase):
    """Thế giới nhỏ: client có 3 tài nguyên, 0859602 có luoyang và old, XJL7457 có luoyang, demo, secret."""

    monster_repeat = False

    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory(prefix="scene_xjl_test_")
        self.addCleanup(self._temporary.cleanup)
        base = Path(self._temporary.name)
        self.server = base / "server"
        self.xjl = base / "tlbb"
        self.client = base / "Scene"
        _write_client_tables(self.server)
        _write_legacy_dirs(self.server)
        _write_xjl(self.xjl, self.monster_repeat)
        _write_client_scene(self.client)

    def groups(self) -> dict[str, scene_xref.Group]:
        found, _client = scene_xref.build(self.server, self.xjl, self.client)
        return {group.scene_dir: group for group in found}

    def do_import(self, check_only: bool = False) -> tuple[dict[str, int], list[str]]:
        return import_scene_xjl.run(self.server, self.xjl, self.client, check_only)


class SceneXrefTest(WorldCase):
    def test_parse_scene_info_cuts_comment_and_keeps_first_key(self) -> None:
        text = "[scene3]\nname=a\nname=b\nfile=x.scn\nclientres=4\t;ghi chú\nactive=0\n[other]\nfile=y.scn\n"
        infos = scene_xref.parse_scene_info(text)
        self.assertEqual(infos, [scene_xref.Info(3, "a", "x", 4, False)])

    def test_parse_scene_info_skips_section_without_file(self) -> None:
        self.assertEqual(scene_xref.parse_scene_info("[scene1]\nname=a\nclientres=2\n"), [])

    def test_decode_text_utf8_then_gbk(self) -> None:
        self.assertEqual(scene_xref.decode_text("洛阳".encode()), "洛阳")
        self.assertEqual(scene_xref.decode_text("洛阳".encode("gb18030")), "洛阳")

    def test_decode_text_gbk_that_is_also_valid_utf8(self) -> None:
        data = "鸭".encode("gb18030")
        self.assertEqual(data.decode("utf-8"), "Ѽ")
        self.assertEqual(scene_xref.decode_text(data), "鸭")

    def test_decode_text_bom_means_utf8_and_is_stripped(self) -> None:
        self.assertEqual(scene_xref.decode_text(scene_xref.UTF8_BOM + b"[a]"), "[a]")

    def test_fold_unifies_variant_character(self) -> None:
        self.assertEqual(scene_xref.fold("淩波洞"), scene_xref.fold("凌波洞"))

    def test_status_and_action_per_scene(self) -> None:
        groups = self.groups()
        self.assertEqual(scene_xref._status(groups["luoyang"]), "present_0859602")
        self.assertEqual(scene_xref._status(groups["demo"]), "importable_xjl7457")
        self.assertEqual(scene_xref._status(groups["secret"]), "absent_xjl_private")
        self.assertEqual(scene_xref._action(groups["demo"]), "import")
        self.assertEqual(scene_xref._action(groups["secret"]), "skip")
        self.assertEqual(scene_xref._action(groups["old"]), "drop_candidate")

    def test_match_kinds_and_shifted_id(self) -> None:
        groups = self.groups()
        self.assertEqual(groups["luoyang"].match, "id")
        self.assertEqual(groups["demo"].match, "stem")
        self.assertEqual(scene_xref._relation(groups["luoyang"]), "same")
        self.assertEqual(groups["demo"].client_ids, [5])
        self.assertEqual(scene_xref._relation(groups["demo"]), "shifted")
        self.assertEqual(scene_xref._relation(groups["old"]), "client_missing")

    def test_client_only_lists_unmatched_resource(self) -> None:
        found, client = scene_xref.build(self.server, self.xjl, self.client)
        rows = scene_xref.client_only_rows(found, client)
        self.assertEqual([row[0] for row in rows], ["3"])
        self.assertEqual(rows[0][1], "alone")

    def test_ids_rows_merges_adjacent_ids(self) -> None:
        client = scene_xref.Client(res_of={1: 7, 2: 7, 3: 7, 5: 7})
        group = scene_xref.Group("a", "id", [7], [1, 2, 3, 5], has_dir=True)
        rows = scene_xref.ids_rows([group], client)
        self.assertEqual(rows, [("1", "3", "a", "7", "id"), ("5", "5", "a", "7", "id")])

    def test_write_tables_and_check_mode(self) -> None:
        found, client = scene_xref.build(self.server, self.xjl, self.client)
        scene_xref.write_tables(self.server, found, client)
        table = tsv_file.read_table(self.server / "tables" / "server" / "scene_xref.tsv")
        self.assertEqual([row[0] for row in table.rows], ["demo", "luoyang", "old", "secret"])
        before = (self.server / "tables" / "server" / "scene_ids.tsv").read_bytes()
        code, _text = _run_main(scene_xref.main, [str(self.server), str(self.xjl), str(self.client), "--check"])
        self.assertEqual(code, 0)
        self.assertEqual((self.server / "tables" / "server" / "scene_ids.tsv").read_bytes(), before)

    def test_import_list_names_only_importable(self) -> None:
        _code, text = _run_main(scene_xref.main, [str(self.server), str(self.xjl), str(self.client), "--import-list"])
        self.assertEqual(text.split(), ["demo"])


class ImportSceneXjlTest(WorldCase):
    def test_normalize_ini_trims_around_equals_and_uses_crlf(self) -> None:
        text = import_scene_xjl.normalize_ini("[a]\n key = value \n;note = x\n")
        self.assertEqual(text, "[a]\r\nkey=value\r\n;note = x\r\n")

    def test_normalize_table_drops_blank_and_hash_lines_keeps_header(self) -> None:
        text = import_scene_xjl.normalize_table("INT\tINT\n#名\t值\n\n1\t2\n# ghi chú\n3\t4\n")
        self.assertEqual(text, "INT\tINT\n#名\t值\n1\t2\n3\t4\n")

    def test_normalize_table_fixes_space_separated_header(self) -> None:
        text = import_scene_xjl.normalize_table("INT INT\nname other\n")
        self.assertEqual(text, "INT\tINT\nname\tother\n")

    def test_convert_text_gbk_to_utf8_crlf(self) -> None:
        data = "[a]\nname = 洛阳\n".encode("gb18030")
        out = import_scene_xjl.convert_text("scn", data)
        self.assertEqual(out.decode("utf-8"), "[a]\r\nname=洛阳\r\n")

    def test_scn_references_follow_fixed_key_order(self) -> None:
        data = b"patrolpoint=p.ini\nmonsterfile=m.ini\nunknown=zzz\neventfile=a.ini\n"
        self.assertEqual(import_scene_xjl.scn_references(data), ["m.ini", "a.ini", "p.ini"])

    def test_case_conflict(self) -> None:
        self.assertIsNone(import_scene_xjl.case_conflict({"abc"}, ["abc", "xyz"]))
        self.assertIn("không phân biệt hoa thường", import_scene_xjl.case_conflict({"Abc"}, ["abc"]) or "")
        self.assertIn("Abc", import_scene_xjl.case_conflict(set(), ["Abc", "abc"]) or "")

    def test_run_imports_only_importable_scene(self) -> None:
        totals, errors = self.do_import()
        self.assertEqual(errors, [])
        self.assertEqual(totals["scenes"], 1)
        names = sorted(entry.name for entry in (self.server / "scenes").iterdir())
        self.assertEqual(names, ["demo", "luoyang", "old"])
        toml = (self.server / "scenes" / "demo" / "scene.toml").read_text(encoding="utf-8")
        self.assertIn("import_scene_xjl.py", toml)
        table = tsv_file.read_table(self.server / "scenes" / "demo" / "spawns.tsv")
        self.assertEqual(table.rows[0][table.columns.index("name")], "鸭")
        self.assertIn("XJL7457/Public/Scene/", table.source)

    def test_check_writes_nothing(self) -> None:
        totals, errors = self.do_import(check_only=True)
        self.assertEqual((totals["scenes"], errors), (1, []))
        self.assertFalse((self.server / "scenes" / "demo").exists())

    def test_rerun_replaces_own_directory_with_identical_bytes(self) -> None:
        self.do_import()
        first = _snapshot(self.server / "scenes" / "demo")
        totals, errors = self.do_import()
        self.assertEqual((totals["scenes"], errors), (1, []))
        self.assertEqual(_snapshot(self.server / "scenes" / "demo"), first)

    def test_foreign_directory_is_not_touched(self) -> None:
        folder = self.server / "scenes" / "demo"
        folder.mkdir()
        (folder / "scene.toml").write_text(EXPORT_TOOL_LINE + "\nschema = 1\n", encoding="utf-8", newline="\n")
        totals, errors = self.do_import()
        self.assertEqual((totals, errors), ({}, []))
        self.assertEqual((folder / "scene.toml").read_text(encoding="utf-8"), EXPORT_TOOL_LINE + "\nschema = 1\n")


class DuplicateSectionImportTest(WorldCase):
    monster_repeat = True

    def test_duplicate_section_ignored_not_fatal(self) -> None:
        totals, errors = self.do_import()
        self.assertEqual(errors, [])
        self.assertEqual(totals["rows_spawns"], 1)


def _snapshot(folder: Path) -> dict[str, bytes]:
    files = sorted(path for path in folder.rglob("*") if path.is_file())
    return {path.relative_to(folder).as_posix(): path.read_bytes() for path in files}


class SceneWalkTest(WorldCase):
    def apply(self) -> dict[str, int]:
        groups, client = scene_xref.build(self.server, self.xjl, self.client)
        chosen = scene_walk.plan(self.server, groups, client, self.client)
        scene_walk.apply(self.server, chosen)
        counts: dict[str, int] = {}
        for _, choice in chosen:
            counts[choice.source] = counts.get(choice.source, 0) + 1
        return dict(sorted(counts.items()))

    def test_client_path_wins_then_nav_fallback(self) -> None:
        self.do_import()
        counts = self.apply()
        self.assertEqual(counts, {"client_2026_path": 2, "legacy_nav_0859602": 1})
        self.assertEqual((self.server / "scenes" / "demo" / "walk.path").read_bytes(), b"path-demo")
        self.assertFalse((self.server / "scenes" / "old" / "walk.path").exists())

    def test_scene_toml_records_source_and_is_idempotent(self) -> None:
        self.do_import()
        self.apply()
        toml = (self.server / "scenes" / "demo" / "scene.toml").read_text(encoding="utf-8")
        self.assertRegex(toml, r'walk_source\s+= "client_2026_path"')
        self.assertRegex(toml, r'walk_client_file\s+= "demo.path"')
        first = _snapshot(self.server / "scenes")
        self.apply()
        self.assertEqual(_snapshot(self.server / "scenes"), first)

    def test_strip_block_restores_original_lines(self) -> None:
        original = ["# tool", "schema = 1"]
        with_block = [*original, "", *scene_walk.block_lines("none", "", False)]
        self.assertEqual(scene_walk.strip_block(with_block), original)
        self.assertEqual(scene_walk.strip_block(original), original)

    def test_check_mode_only_counts(self) -> None:
        self.do_import()
        code, text = _run_main(scene_walk.main, [str(self.server), str(self.xjl), str(self.client), "--check"])
        self.assertEqual(code, 0)
        self.assertIn("client_2026_path 2", text)
        self.assertFalse((self.server / "scenes" / "demo" / "walk.path").exists())

    def test_mesh_bounds_reads_both_versions(self) -> None:
        points = [(1.0, -2.0), (30.5, 4.0), (8.0, 64.0)]
        for wide in (False, True):
            self.assertEqual(scene_walk.mesh_bounds(_path_bytes(points, wide)), (1.0, -2.0, 30.5, 64.0))

    def test_mesh_bounds_none_when_head_unreadable(self) -> None:
        good = _path_bytes([(1.0, 2.0)])
        nan = _path_bytes([(float("nan"), 2.0)])
        for data in (b"", b"\x00", b"path-demo", good[:-1], _path_bytes([]), nan):
            self.assertIsNone(scene_walk.mesh_bounds(data), data)

    def test_mesh_bounds_rejects_count_beyond_file(self) -> None:
        self.assertIsNone(scene_walk.mesh_bounds(struct.pack("<HH", 0x1000, 60000) + bytes(16)))

    def test_extent_conflict_allows_slack_at_edge(self) -> None:
        mesh = (0.0, 0.0, 64.0, 64.0)
        self.assertEqual(scene_walk.extent_conflict(mesh, [(0.0, 0.0), (64.0, 64.9), (30.0, 30.0)]), "")
        self.assertIn("1/2 quái đứng ngoài", scene_walk.extent_conflict(mesh, [(30.0, 30.0), (115.0, 106.0)]))
        self.assertIn("1/1 quái đứng ngoài", scene_walk.extent_conflict(mesh, [(-3.0, 10.0)]))

    def test_extent_conflict_tolerates_few_strays(self) -> None:
        mesh = (0.0, 0.0, 64.0, 64.0)
        inside = [(10.0, 10.0)] * 9
        self.assertEqual(scene_walk.extent_conflict(mesh, [*inside, (500.0, 500.0)]), "")
        self.assertNotEqual(scene_walk.extent_conflict(mesh, [*inside, (500.0, 500.0), (500.0, 500.0)]), "")

    def test_generic_resource_is_not_a_scene_mesh(self) -> None:
        group = scene_xref.Group("a", "id", [7], [1], has_dir=True)
        files = {"shared.path": Path("shared.path")}
        crowd = list(range(scene_xref.GENERIC_RES_IDS + 1))
        shared = scene_xref.Client(path_of_res={7: "shared.path"}, ids_of_res={7: crowd})
        own = scene_xref.Client(path_of_res={7: "shared.path"}, ids_of_res={7: [1, 2]})
        self.assertIsNone(scene_walk.client_path_file(group, shared, files))
        self.assertEqual(scene_walk.client_path_file(group, own, files), Path("shared.path"))

    def test_path_smaller_than_spawns_falls_back_to_nav_and_says_why(self) -> None:
        self.do_import()
        (self.client / "demo.path").write_bytes(_path_bytes([(0.0, 0.0), (0.25, 0.25)]))
        (self.server / "scenes" / "demo" / "walk.nav").write_bytes(b"\x01\x00\x01\x00\x01\x00\x00\x00")
        groups, client = scene_xref.build(self.server, self.xjl, self.client)
        planned = scene_walk.plan(self.server, groups, client, self.client)
        chosen = {group.scene_dir: choice for group, choice in planned}
        self.assertEqual(chosen["demo"].source, "legacy_nav_xjl7457")
        self.assertIn("demo.path", chosen["demo"].rejected)
        scene_walk.apply(self.server, planned)
        toml = (self.server / "scenes" / "demo" / "scene.toml").read_text(encoding="utf-8")
        self.assertIn("Đã bỏ demo.path", toml)
        self.assertRegex(toml, r'walk_source\s+= "legacy_nav_xjl7457"')
        self.assertFalse((self.server / "scenes" / "demo" / "walk.path").exists())

    def test_path_covering_spawns_is_kept(self) -> None:
        self.do_import()
        (self.client / "demo.path").write_bytes(_path_bytes([(0.0, 0.0), (8.0, 8.0)]))
        groups, client = scene_xref.build(self.server, self.xjl, self.client)
        planned = scene_walk.plan(self.server, groups, client, self.client)
        chosen = {group.scene_dir: choice for group, choice in planned}
        self.assertEqual((chosen["demo"].source, chosen["demo"].rejected), ("client_2026_path", ""))

    def test_removed_client_path_removes_stale_walk_path(self) -> None:
        self.do_import()
        self.apply()
        (self.client / "demo.path").unlink()
        counts = self.apply()
        self.assertNotIn("demo", counts)
        self.assertFalse((self.server / "scenes" / "demo" / "walk.path").exists())


class SceneDiffTest(WorldCase):
    def test_compare_counts_same_changed_and_one_sided(self) -> None:
        left = [(("1",), ("a", "1")), (("2",), ("a", "2")), (("3",), ("a", "3"))]
        right = [(("1",), ("a", "1")), (("2",), ("a", "2x")), (("4",), ("a", "4"))]
        self.assertEqual(scene_diff.compare(left, right), (1, 1, 1, 1))

    def test_compare_multiset_duplicates(self) -> None:
        row = (("1",), ("a", "1"))
        self.assertEqual(scene_diff.compare([row, row], [row]), (1, 0, 1, 0))

    def test_run_reports_changed_row_between_sources(self) -> None:
        self.do_import()
        folder = self.server / "scenes" / "demo"
        toml = folder / "scene.toml"
        text = toml.read_text(encoding="utf-8").replace("import_scene_xjl.py", "export_scene.py")
        toml.write_text(text, encoding="utf-8", newline="\n")
        spawns = folder / "spawns.tsv"
        spawns.write_text(spawns.read_text(encoding="utf-8").replace("鸭", "鹅"), encoding="utf-8", newline="\n")
        rows, errors = scene_diff.run(self.server, self.xjl)
        self.assertEqual(errors, [])
        by_table = {row[1]: row for row in rows}
        self.assertEqual(by_table["spawns"], ("demo", "spawns", "1", "1", "0", "1", "0", "0"))

    def test_run_skips_scene_not_in_xjl(self) -> None:
        rows, errors = scene_diff.run(self.server, self.xjl)
        self.assertEqual((rows, errors), ([], []))


SCRIPT = """;kịch bản thử
[common]
0:if(AIS_GetAIState()=SATTACK&AIS_GetHP()<30){AIS_ToSkill(564);AIS_SetTimes(-1);AIS_SetPRI(5);};chú thích
1:if(AIS_Rand()<50){AIS_ToFlee();};không đặt số lần
2:if(AIS_GetHP()<5|AIS_Rand()<5){AIS_ToFlee();AIS_SetTimes(1);};dùng hoặc
3:if(AIS_GetHP()<5)(AIS_ToFlee();AIS_SetTimes(1););sai ngoặc
4:if(AIS_NoSuch()=1){AIS_ToFlee();AIS_SetTimes(1);};hàm lạ
[skill]
5:if(1=1){AIS_ToSpeak(3);AIS_SetTimes(2);};hằng luôn đúng
"""


class AiConvertTest(unittest.TestCase):
    def parse(self) -> tuple[list[ai_convert.Rule], list[ai_convert.Issue], str]:
        return ai_convert.parse_script(9, SCRIPT)

    def test_rule_head_and_atoms(self) -> None:
        rules, _issues, title = self.parse()
        first = rules[0]
        self.assertEqual((first.index, first.section, first.times, first.priority), (0, "common", -1, 5))
        self.assertEqual([atom.function for atom in first.conditions], ["get_ai_state", "get_hp"])
        self.assertEqual((first.conditions[0].op, first.conditions[0].value, first.conditions[0].value_name),
                         ("eq", 6, "SATTACK"))  # fmt: skip
        self.assertEqual([atom.function for atom in first.actions], ["to_skill"])
        self.assertEqual(title, "kịch bản thử")

    def test_defaults_when_times_and_priority_absent(self) -> None:
        second = self.parse()[0][1]
        self.assertEqual((second.times, second.priority), (0, -1))

    def test_rule_index_counts_unrepresentable_lines(self) -> None:
        rules, issues, _title = self.parse()
        self.assertEqual([rule.index for rule in rules], [0, 1, 5])
        self.assertEqual([issue.line for issue in issues], [5, 6, 7])
        self.assertTrue(all(issue.kind == "unrepresentable" for issue in issues))
        self.assertIn("hoặc", issues[0].text)
        self.assertIn("ngoặc", issues[1].text)
        self.assertIn("hàm lạ", issues[2].text)

    def test_constant_condition_and_section(self) -> None:
        last = self.parse()[0][2]
        self.assertEqual((last.section, last.times), ("skill", 2))
        self.assertEqual(last.conditions[0].function, "const")
        self.assertEqual(last.conditions[0].args[0], 1)

    def test_rule_rows_carry_head_and_skill_id(self) -> None:
        rows = ai_convert.rule_rows(9, self.parse()[0][0])
        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[0][:7], ("9", "0", "common", "5", "-1", "if", "0"))
        self.assertEqual(rows[0][13], "-1")
        self.assertEqual((rows[2][5], rows[2][7], rows[2][13]), ("do", "to_skill", "564"))

    def test_added_function_is_counted_not_rejected(self) -> None:
        atom = ai_convert.parse_call("AIS_CallOtherMonsterByGroup(1,2,3)")
        self.assertIsInstance(atom, ai_convert.Atom)
        self.assertEqual(atom.args, (1, 2, 3))
        row = ("9", "0", "dead", "-1", "1", "do", "0", "call_other_monster_by_group")
        known = ("9", "0", "dead", "-1", "1", "do", "0", "to_flee")
        self.assertEqual(ai_convert.added_functions([row, known, row]), {"call_other_monster_by_group": 2})

    def test_call_rejects_four_arguments_and_text(self) -> None:
        self.assertIsInstance(ai_convert.parse_call("AIS_ToFlee(1,2,3,4)"), str)
        self.assertIsInstance(ai_convert.parse_call("AIS_ToFlee(a)"), str)
        self.assertIsInstance(ai_convert.parse_call("not a call"), str)

    def test_read_dat(self) -> None:
        text = "1=script1.ai =Thỏ\n;2=script2.ai =Hổ\nrác\n"
        self.assertEqual(ai_convert.read_dat(text), {1: "Thỏ", 2: "Hổ"})


class AiConvertRunTest(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory(prefix="ai_convert_test_")
        self.addCleanup(self._temporary.cleanup)
        base = Path(self._temporary.name)
        self.server = base / "server"
        self.xjl = base / "tlbb"
        data = self.xjl / "Public" / "Data"
        (data / "AIScript").mkdir(parents=True)
        (data / "AIScript.dat").write_bytes("3=script3.ai =Thử\n".encode("gb18030"))
        (data / "AIScript" / "script3.ai").write_bytes(SCRIPT.encode("gb18030"))
        (data / "AIScript" / "readme.txt").write_bytes(b"bo qua")

    def run_main(self, *extra: str) -> tuple[int, str]:
        return _run_main(ai_convert.main, [str(self.server), str(self.xjl), *extra])

    def test_tables_written_with_counts(self) -> None:
        code, text = self.run_main()
        self.assertEqual(code, 0)
        self.assertIn("tệp 1 luật 3", text)
        rules = tsv_file.read_table(self.server / "tables" / "server" / "monster_ai_rules.tsv")
        self.assertEqual({row[0] for row in rules.rows}, {"3"})
        files = tsv_file.read_table(self.server / "tables" / "server" / "monster_ai_rule_files.tsv")
        self.assertEqual(files.rows[0][:5], ("3", "script3.ai", "kịch bản thử", "Thử", "3"))

    def test_check_writes_nothing(self) -> None:
        code, _text = self.run_main("--check")
        self.assertEqual(code, 0)
        self.assertFalse((self.server / "tables").exists())

    def test_wrong_argument_count(self) -> None:
        code, text = _run_main(ai_convert.main, ["only-one"])
        self.assertEqual(code, 1)
        self.assertIn("cần hai tham số", text)


if __name__ == "__main__":
    unittest.main()
