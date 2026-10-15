#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/test_export_creatures.py
#  PHÂN HỆ   : Content / Test Export Creatures
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm logic thuần của export_creatures.py: số thực float32, nhận cảnh, chọn
#    skeleton, material chồng, hộp ngoài, chuỗi clip.
#  - Không đụng kho thật. Chạy: python -B
#    TOOLS/content/test_export_creatures.py
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

import struct
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ElementTree
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import export_creatures as ec
from export_look import ExportError


def float32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


class FloatText(unittest.TestCase):
    def test_whole_numbers_have_no_fraction_or_exponent(self) -> None:
        self.assertEqual([ec.float_text(value) for value in (100.0, -1.0, 175.0, 0.0, 360.0)],
                         ["100", "-1", "175", "0", "360"])

    def test_float32_shortest_round_trip(self) -> None:
        self.assertEqual(ec.float_text(float32(0.15)), "0.15")
        self.assertEqual(ec.float_text(float32(1.2)), "1.2")
        self.assertEqual(ec.float_text(float32(3.2)), "3.2")
        self.assertEqual(ec.float_text(float32(0.50392157)), "0.50392157")

    def test_text_reads_back_as_the_same_float32(self) -> None:
        for value in (float32(0.1), float32(182.123456), float32(1.05), float32(1234567.0), float32(1.0e-5)):
            self.assertEqual(float32(float(ec.float_text(value))), value)

    def test_not_finite_is_an_error(self) -> None:
        for value in (float("nan"), float("inf"), float("-inf")):
            with self.assertRaises(ExportError):
                ec.float_text(value)


class ServerTable(unittest.TestCase):
    def test_aligned_padding_is_stripped_and_comments_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "scene_ids.tsv"
            path.write_text("# schema 1\n# layout: aligned\nclient_id_first  \tscene_dir  \n0               \tdali        \n",
                            encoding="utf-8")
            header, rows = ec.read_server_table(path)
        self.assertEqual(header, ["client_id_first", "scene_dir"])
        self.assertEqual(rows, [["0", "dali"]])


class SceneResolution(unittest.TestCase):
    book = ec.SceneBook({0: ["luoyang"], 2: ["dali"], 9: ["a", "b", "gone"]}, {"dali_new_320": 2, "luoyang_new": 0},
                        {"luoyang", "dali", "a", "b", "yewai"})

    def test_resid_directory_and_client_file_name(self) -> None:
        self.assertEqual(ec.resolve_scene(self.book, "2"), ["dali"])
        self.assertEqual(ec.resolve_scene(self.book, "yewai"), ["yewai"])
        self.assertEqual(ec.resolve_scene(self.book, "dali_new_320"), ["dali"])
        self.assertEqual(ec.resolve_scene(self.book, "Dali_New_320.Scene"), ["dali"])

    def test_resid_may_name_several_directories_and_unknown_ones_are_dropped(self) -> None:
        self.assertEqual(ec.resolve_scene(self.book, "9"), ["a", "b"])

    def test_unknown_scene_is_an_error(self) -> None:
        for argument in ("77", "nowhere", "nowhere.Scene"):
            with self.assertRaises(ExportError):
                ec.resolve_scene(self.book, argument)


class SkeletonChoice(unittest.TestCase):
    def test_first_entity_by_gbk_bytes_wins_among_those_with_a_skeleton(self) -> None:
        self.assertEqual(ec.pick_skeleton([("b", ""), ("a", "x.skeleton"), ("c", "x.skeleton")]), "x.skeleton")

    def test_static_model_has_no_skeleton(self) -> None:
        self.assertEqual(ec.pick_skeleton([("a", ""), ("b", "")]), "")
        self.assertEqual(ec.pick_skeleton([]), "")

    def test_two_different_skeletons_are_refused(self) -> None:
        with self.assertRaises(ExportError):
            ec.pick_skeleton([("a", "x.skeleton"), ("b", "y.skeleton")])


class MaterialOverride(unittest.TestCase):
    def test_entity_without_material_keeps_the_mesh_material(self) -> None:
        self.assertEqual(ec.overriding_material("", ["镜湖花妖身"]), "")

    def test_same_material_on_every_submesh_is_no_override(self) -> None:
        self.assertEqual(ec.overriding_material("a", ["a"]), "")
        self.assertEqual(ec.overriding_material("a", ["a", "a"]), "")

    def test_a_different_material_replaces_all_submeshes(self) -> None:
        self.assertEqual(ec.overriding_material("断桥花妖身", ["镜湖花妖身"]), "断桥花妖身")
        self.assertEqual(ec.overriding_material("a", ["a", "b"]), "a")


def template_of(attributes: str):
    return ElementTree.fromstring(f'<Object name="t.obj"><Attributes>{attributes}</Attributes></Object>')


class Height(unittest.TestCase):
    def test_three_numbers_are_a_size(self) -> None:
        self.assertEqual(ec.height_text(template_of('<Attribute name="BoundingBox" value="50 190 50"/>')), "190")

    def test_six_numbers_are_min_and_max(self) -> None:
        box = "-14 0 -14 14 170 14"
        self.assertEqual(ec.height_text(template_of(f'<Attribute name="BoundingBox" value="{box}"/>')), "170")
        box = "-10 -5 -10 10 195.5 10"
        self.assertEqual(ec.height_text(template_of(f'<Attribute name="BoundingBox" value="{box}"/>')), "200.5")

    def test_missing_box_is_zero_and_bad_boxes_are_errors(self) -> None:
        self.assertEqual(ec.height_text(template_of("")), "0")
        for value in ("1 2", "1 2 3 4", "1 nan 3", "1 -2 3"):
            with self.assertRaises(ExportError):
                ec.height_text(template_of(f'<Attribute name="BoundingBox" value="{value}"/>'))


class FakeSources:
    def __init__(self, animations: dict):
        self.animations = animations

    def animations_of(self, skeleton: str) -> list:
        return self.animations.get(skeleton, [])


def look_of(**changes) -> ec.ModelLook:
    values = dict(model=1, meshes=["a.mesh"], materials=[""], skeleton="main.skeleton", scale=("1", "1", "1"),
                  height="0", links={}, default_animation="", action_set=10, conditional=0)
    values.update(changes)
    return ec.ModelLook(**values)


class ClipChain(unittest.TestCase):
    # Action set 10: hành động cơ sở 0 (idle) ra "站立" ở cột npc (15) nhưng "站立B" ở cột monster (14); hành động 24
    # (death) ra tên skill "死亡" có Animation "倒地"; hành động 4 (run) ra tên rỗng; hành động 3 (walk) không có dòng.
    lines = {1: {14: 100, 15: 101}, 2: {14: 102, 15: 102}, 3: {14: 0, 15: 0}}
    index = {(10, 0): 1, (10, 24): 2, (10, 4): 3}
    names = {100: "站立B", 101: "站立", 102: "死亡", 0: ""}

    def book(self, animations: dict | None = None) -> ec.ClipBook:
        animations = animations if animations is not None else {"main.skeleton": ["站立", "站立B", "倒地"]}
        return ec.ClipBook(FakeSources(animations), {"死亡": "倒地"}, self.index, self.lines, self.names)

    def test_kind_selects_the_column(self) -> None:
        look = look_of()
        self.assertEqual(ec.resolve_clip(self.book(), look, "npc", "idle"), ("main.skeleton", "站立"))
        self.assertEqual(ec.resolve_clip(self.book(), look, "monster", "idle"), ("main.skeleton", "站立B"))

    def test_skill_name_goes_through_its_animation(self) -> None:
        self.assertEqual(ec.resolve_clip(self.book(), look_of(), "npc", "death"), ("main.skeleton", "倒地"))

    def test_absent_action_and_empty_name_are_dropped_with_a_reason(self) -> None:
        self.assertEqual(ec.resolve_clip(self.book(), look_of(), "npc", "walk"),
                         (None, "action set không có hành động"))
        self.assertEqual(ec.resolve_clip(self.book(), look_of(), "npc", "run"), (None, "tên hành động rỗng"))

    def test_clip_missing_from_every_skeleton_is_dropped_not_invented(self) -> None:
        book = self.book({"main.skeleton": ["站立B"]})
        self.assertEqual(ec.resolve_clip(book, look_of(), "npc", "idle")[0], None)

    def test_clip_found_in_the_linked_skeleton(self) -> None:
        book = self.book({"main.skeleton": [], "other.skeleton": ["站立"]})
        look = look_of(links={"站立": "other.skeleton"})
        self.assertEqual(ec.resolve_clip(book, look, "npc", "idle"), ("other.skeleton", "站立"))

    def test_default_animation_needs_no_action_set(self) -> None:
        book = self.book({"main.skeleton": ["循环"]})
        look = look_of(action_set=-1, default_animation="循环")
        self.assertEqual(ec.resolve_clip(book, look, "monster", ec.DEFAULT_ACTION), ("main.skeleton", "循环"))

    def test_rows_keep_vocabulary_order_and_skip_models_without_a_set_or_skeleton(self) -> None:
        report = {"dropped": ec.Counter()}
        looks = [look_of(model=2, action_set=-1, default_animation="站立"), look_of(model=1),
                 look_of(model=3, skeleton="")]
        book = self.book()
        rows = ec.clip_rows(book, looks, {1: {"npc"}, 2: {"npc"}, 3: {"npc"}}, report)
        self.assertEqual([(row[0], row[2]) for row in rows], [(2, "default"), (1, "idle"), (1, "death")])
        self.assertEqual(report["dropped"]["không có action set"], len(ec.ACTIONS))


class UnresolvedMaterial(unittest.TestCase):
    def test_unresolved_names_become_no_override_and_others_stay(self) -> None:
        looks = [look_of(materials=["a", "", "b"]), look_of(model=2, materials=["b"])]
        result = ec.without_materials(looks, {"b"})
        self.assertEqual([look.materials for look in result], [["a", "", ""], [""]])
        self.assertEqual(looks[0].materials, ["a", "", "b"])

    def test_nothing_unresolved_returns_the_same_looks(self) -> None:
        looks = [look_of()]
        self.assertIs(ec.without_materials(looks, set()), looks)


class Rendering(unittest.TestCase):
    def test_table_text_is_deterministic_and_has_no_blank_cells_lost(self) -> None:
        text = ec.render_table(["schema 1"], ["a", "b", "c"], [(1, "x", ""), (2, "", "z")])
        self.assertEqual(text, "# schema 1\na\tb\tc\n1\tx\t\n2\t\tz\n")

    def test_cells_with_tab_or_newline_are_refused(self) -> None:
        for text in ("a\tb", "a\nb", "a\rb"):
            with self.assertRaises(ExportError):
                ec.clean(text)

    def test_store_only_reports_in_check_mode(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            texts = {"creatures.tsv": "x\n"}
            self.assertEqual(ec.store(Path(folder), texts, True), ["creatures.tsv"])
            self.assertFalse((Path(folder) / "Table" / "creatures.tsv").exists())
            self.assertEqual(ec.store(Path(folder), texts, False), ["creatures.tsv"])
            self.assertEqual(ec.store(Path(folder), texts, True), [])
            self.assertEqual(ec.store(Path(folder), {"creatures.tsv": "y\n"}, True), ["creatures.tsv"])


if __name__ == "__main__":
    unittest.main()
