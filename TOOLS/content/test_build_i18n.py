# Kiểm bộ dựng bản địa hoá (build_i18n.py) trên một tệp i18n và một cây dữ liệu nhỏ dựng trong thư
# mục tạm: tách ba loại khoá, từ chối tệp sai dạng, ghi hai bảng chữ, thay ảnh ngay trong atlas của
# thư mục dữ liệu (bản triển khai chỉ có một bộ ảnh) và trả atlas về gốc khi ảnh thôi được thay.
# Chạy: python -B TOOLS/content/test_build_i18n.py

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import build_i18n

MANIFEST = """# chú thích
image/Frames/Logo\tlogo.png
KEY_A\t#YXin chào
=帮助\tTrợ giúp
scene/洛阳\tLạc Dương
"""

IMAGESETS = """<?xml version="1.0" encoding="utf-8"?>
<Imagesets>
  <Imageset Name="Frames" Imagefile="Common/Frames.dds">
    <Image Name="Other" XPos="0" YPos="0" Width="4" Height="2" />
    <Image Name="Logo" XPos="2" YPos="3" Width="4" Height="2" />
  </Imageset>
</Imagesets>
"""

RED = (255, 0, 0, 255)
GREEN = (0, 255, 0, 255)
BLUE = (0, 0, 255, 128)
WHITE = (255, 255, 255, 255)


class ManifestKinds(unittest.TestCase):
    def test_three_kinds_are_split(self) -> None:
        manifest = build_i18n.read_manifest(MANIFEST)
        self.assertEqual(manifest.strings, [("KEY_A", "#YXin chào"), ("=帮助", "Trợ giúp")])
        self.assertEqual(manifest.scenes, [("洛阳", "Lạc Dương")])
        self.assertEqual(manifest.images, [build_i18n.ImageRow("Frames", "Logo", "logo.png")])

    def test_bad_lines_are_rejected_with_line_number(self) -> None:
        cases = {
            "không tab": ("KEY_A\tx\nKHONG_TAB\n", "dòng 2"),
            "hai tab": ("KEY_A\tx\ty\n", "dòng 1"),
            "khoá rỗng": ("\tx\n", "dòng 1"),
            "khoá lặp": ("KEY_A\tx\nKEY_B\ty\nKEY_A\tz\n", "dòng 3"),
            "ảnh thiếu tên": ("image/Frames\tlogo.png\n", "dòng 1"),
            "cảnh rỗng": ("scene/\tLạc Dương\n", "dòng 1"),
            "tệp ra ngoài": ("file/../x.html\tx.html\n", "dòng 1"),
            "tệp có ổ đĩa": ("file/C" + ":/x.html\tx.html\n", "dòng 1"),
            "tệp rỗng tên": ("file/\tx.html\n", "dòng 1"),
        }
        for name, (text, where) in cases.items():
            with self.subTest(name), self.assertRaises(build_i18n.ManifestError) as caught:
                build_i18n.read_manifest(text)
            self.assertIn(where, str(caught.exception))


class TableCells(unittest.TestCase):
    def test_table_keys_are_grouped_by_table(self) -> None:
        text = "table/items/20101000/name\tBản đồ kho báu\ntable/skills/-1/explain\t#GChiêu%s0\nKEY_A\tx\n"
        manifest = build_i18n.read_manifest(text)
        self.assertEqual(manifest.tables, {
            "items": [("20101000", "name", "Bản đồ kho báu")],
            "skills": [("-1", "explain", "#GChiêu%s0")],
        })
        self.assertEqual(manifest.strings, [("KEY_A", "x")], "khoá bảng không lẫn vào bảng chữ")

    def test_bad_table_keys_are_rejected(self) -> None:
        cases = {
            "thiếu cột": "table/items/1\tx\n",
            "thừa phần": "table/items/1/name/x\tx\n",
            "id không số": "table/items/a1/name\tx\n",
            "bảng chữ hoa": "table/Items/1/name\tx\n",
            "cột rỗng": "table/items/1/\tx\n",
            "bảng giao diện": "table/ui_strings/1/text\tx\n",
            "khoá lặp": "table/items/1/name\tx\ntable/items/1/name\ty\n",
        }
        for name, text in cases.items():
            with self.subTest(name), self.assertRaises(build_i18n.ManifestError):
                build_i18n.read_manifest(text)


class Outputs(unittest.TestCase):
    def setUp(self) -> None:
        build = ROOT.parents[1] / "build"
        build.mkdir(exist_ok=True)
        self.folder = tempfile.TemporaryDirectory(dir=build)
        self.source = Path(self.folder.name) / "i18n"
        self.data = Path(self.folder.name) / "data"
        self.state = Path(self.folder.name) / "state"
        self.atlas = self.data / "Interface" / "Common" / "Frames.dds.png"
        (self.source / "vi").mkdir(parents=True)
        self.write_manifest(MANIFEST)
        self.paint_patch((4, 2), BLUE)

    def tearDown(self) -> None:
        self.folder.cleanup()

    def write_manifest(self, text: str) -> None:
        (self.source / "vi.tsv").write_text(text, encoding="utf-8", newline="\n")

    def paint_patch(self, size: tuple[int, int], colour: tuple[int, int, int, int]) -> None:
        Image.new("RGBA", size, colour).save(self.source / "vi" / "logo.png")

    # Đặt atlas gốc một màu vào thư mục dữ liệu, như bộ gom vừa chạy.
    def gather(self, colour: tuple[int, int, int, int] = RED) -> None:
        schema = self.data / "Interface" / "Schema"
        schema.mkdir(parents=True, exist_ok=True)
        (schema / "all.imageset.xml").write_text(IMAGESETS, encoding="utf-8")
        self.atlas.parent.mkdir(exist_ok=True)
        Image.new("RGBA", (8, 8), colour).save(self.atlas)

    def run_tool(self) -> int:
        return build_i18n.main([str(self.source / "vi.tsv"), str(self.data), "--state", str(self.state)])

    # Màu trong ô của mảnh Logo và màu ở phần còn lại của atlas đang nằm trong thư mục dữ liệu.
    def atlas_colours(self) -> tuple[set, set]:
        with Image.open(self.atlas) as atlas:
            self.assertEqual(atlas.size, (8, 8))
            inside = {atlas.getpixel((x, y)) for x in range(2, 6) for y in range(3, 5)}
            outside = {atlas.getpixel((x, y)) for x in range(8) for y in range(8) if not (2 <= x < 6 and 3 <= y < 5)}
        return inside, outside

    def test_text_tables_are_written_without_gathered_data(self) -> None:
        self.assertEqual(self.run_tool(), 0)
        strings = (self.data / "Table" / "ui_strings.lang.tsv").read_text(encoding="utf-8")
        self.assertTrue(strings.endswith("key\ttext\nKEY_A\t#YXin chào\n=帮助\tTrợ giúp\n"))
        scenes = (self.data / "Table" / "scene_names.lang.tsv").read_text(encoding="utf-8")
        self.assertTrue(scenes.endswith("key\ttext\n洛阳\tLạc Dương\n"))
        self.assertFalse((self.data / "Interface").exists(), "chưa gom giao diện thì không dựng ảnh")

    def test_image_replaces_the_region_in_the_deployed_atlas(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.atlas_colours(), ({BLUE}, {RED}), "ô bị thay trọn kể cả alpha, phần khác giữ nguyên")
        pictures = sorted(path.name for path in self.data.rglob("*.png"))
        self.assertEqual(pictures, ["Frames.dds.png"], "thư mục dữ liệu chỉ có một bản của atlas")
        with Image.open(self.state / "base" / "Common" / "Frames.dds.png") as base:
            self.assertEqual(base.getpixel((3, 3)), RED, "bản gốc được giữ ngoài thư mục dữ liệu")

    def test_wrong_size_or_unknown_image_fails_before_any_write(self) -> None:
        self.gather()
        self.paint_patch((5, 2), BLUE)
        self.assertEqual(self.run_tool(), 1, "ảnh lệch cỡ mảnh gốc")
        self.paint_patch((4, 2), BLUE)
        self.write_manifest(MANIFEST.replace("image/Frames/Logo", "image/Frames/KhongCo"))
        self.assertEqual(self.run_tool(), 1, "bộ ảnh không có mảnh ấy")
        self.assertEqual(self.atlas_colours(), ({RED}, {RED}), "atlas còn nguyên bản gốc")
        self.assertFalse((self.data / "Table").exists(), "lượt hỏng không ghi bảng chữ")

    def test_bad_manifest_fails(self) -> None:
        self.write_manifest("KEY_A\n")
        self.assertEqual(self.run_tool(), 1)
        self.assertFalse((self.data / "Table").exists(), "tệp sai thì không ghi gì")

    def test_second_run_rewrites_nothing(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        made = [self.data / "Table" / "ui_strings.lang.tsv", self.atlas, self.state / "atlases.tsv"]
        stamps = [path.stat().st_mtime_ns for path in made]
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual([path.stat().st_mtime_ns for path in made], stamps)

    def test_edited_patch_is_rebuilt_from_the_original(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        self.paint_patch((4, 2), WHITE)
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.atlas_colours(), ({WHITE}, {RED}))

    def test_regathered_atlas_becomes_the_new_original(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        self.gather(GREEN)
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.atlas_colours(), ({BLUE}, {GREEN}), "ảnh thay dán lên atlas vừa gom lại")
        with Image.open(self.state / "base" / "Common" / "Frames.dds.png") as base:
            self.assertEqual(base.getpixel((3, 3)), GREEN, "bản gốc giữ lại là bản vừa gom")

    def test_dropped_image_restores_the_original_atlas(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        self.write_manifest(MANIFEST.replace("image/Frames/Logo\tlogo.png\n", ""))
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.atlas_colours(), ({RED}, {RED}), "atlas về bản gốc khi ảnh thôi được thay")
        self.assertEqual((self.state / "atlases.tsv").read_text(encoding="utf-8"), "")

    # Xoá thư mục trạng thái (xoá cả build/) lúc atlas đang mang ảnh thay: lượt dựng kế không được
    # coi atlas đã thay là bản gốc. Nó phải dừng mà không ghi gì; gom lại rồi thì dựng tiếp như thường.
    def test_lost_state_is_refused_until_the_atlas_is_regathered(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        replaced = self.atlas.read_bytes()
        shutil.rmtree(self.state)
        self.assertEqual(self.run_tool(), 1, "atlas đang mang ảnh thay mà bản gốc đã mất")
        self.assertEqual(self.atlas.read_bytes(), replaced, "lượt bị từ chối không ghi gì lên atlas")
        kept = self.state / "base" / "Common" / "Frames.dds.png"
        self.assertFalse(kept.exists(), "ảnh đã thay không được giữ làm bản gốc")
        self.gather(GREEN)
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(self.atlas_colours(), ({BLUE}, {GREEN}), "gom lại rồi thì dựng tiếp")

    # Cùng tình huống mà tệp nguồn đã thôi nêu ảnh: atlas không trả về gốc được, cũng phải dừng.
    def test_lost_state_is_refused_even_when_the_image_was_dropped(self) -> None:
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        shutil.rmtree(self.state)
        self.write_manifest(MANIFEST.replace("image/Frames/Logo\tlogo.png\n", ""))
        self.assertEqual(self.run_tool(), 1, "không còn bản gốc để trả atlas về")
        self.assertEqual(self.atlas_colours(), ({BLUE}, {RED}), "atlas giữ nguyên, không ai coi nó là gốc")

    # Bộ ảnh gốc có ô khai chồng lên nhau một hàng (Logon_Erweima_Normal và _Pushed của client 2026):
    # hai ảnh thay phải giống nhau ở hàng chung, không thì atlas ra sao tuỳ thứ tự dán.
    def test_overlapping_cells_must_agree_on_the_shared_pixels(self) -> None:
        self.gather()
        schema = self.data / "Interface" / "Schema" / "all.imageset.xml"
        low = '<Image Name="Low" XPos="2" YPos="4" Width="4" Height="2" />\n  </Imageset>'
        schema.write_text(IMAGESETS.replace("</Imageset>", low), encoding="utf-8")
        self.write_manifest(MANIFEST + "image/Frames/Low\tlow.png\n")
        rows = Image.new("RGBA", (4, 2), BLUE)
        rows.paste(GREEN, (0, 1, 4, 2))
        rows.save(self.source / "vi" / "logo.png")
        Image.new("RGBA", (4, 2), WHITE).save(self.source / "vi" / "low.png")
        self.assertEqual(self.run_tool(), 1, "hàng chung khác nhau")
        self.assertEqual(self.atlas_colours(), ({RED}, {RED}), "atlas còn nguyên bản gốc")
        agreed = Image.new("RGBA", (4, 2), GREEN)
        agreed.paste(WHITE, (0, 1, 4, 2))
        agreed.save(self.source / "vi" / "low.png")
        self.assertEqual(self.run_tool(), 0, "hàng chung giống nhau")
        with Image.open(self.atlas) as atlas:
            column = [atlas.getpixel((3, y)) for y in range(2, 7)]
        self.assertEqual(column, [RED, BLUE, GREEN, WHITE, RED])

    # Dòng file/: tệp của ngôn ngữ chép nguyên vào thư mục dữ liệu; thôi nêu thì tệp bị gỡ; thiếu tệp
    # nguồn thì dừng trước khi ghi gì.
    def test_listed_file_is_copied_then_removed_when_dropped(self) -> None:
        page = self.source / "vi" / "web" / "soon.html"
        page.parent.mkdir()
        page.write_text("<p>Sắp ra mắt</p>", encoding="utf-8")
        listed = MANIFEST + "file/Web/soon.html\tweb/soon.html\n"
        self.write_manifest(listed)
        self.assertEqual(self.run_tool(), 0)
        copied = self.data / "Web" / "soon.html"
        self.assertEqual(copied.read_text(encoding="utf-8"), "<p>Sắp ra mắt</p>")
        stamp = (self.state / "deployed.stamp").read_bytes()
        page.write_text("<p>Coming soon</p>", encoding="utf-8")
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual(copied.read_text(encoding="utf-8"), "<p>Coming soon</p>")
        self.assertNotEqual((self.state / "deployed.stamp").read_bytes(), stamp, "đổi tệp thì mốc đổi")
        page.unlink()
        self.assertEqual(self.run_tool(), 1, "thiếu tệp nguồn")
        self.write_manifest(MANIFEST)
        self.assertEqual(self.run_tool(), 0)
        self.assertFalse(copied.exists(), "tệp thôi được nêu bị gỡ khỏi thư mục dữ liệu")

    # Bản dịch ô: một tệp Table/<bảng>.lang.tsv mỗi bảng; bảng thôi được nêu thì tệp bị gỡ, mốc đổi.
    def test_table_translations_are_written_and_dropped(self) -> None:
        cells = "table/items/7/name\tKiếm\ntable/items/7/description\t#GSắc\ntable/skills/3/name\tChưởng\n"
        self.write_manifest(MANIFEST + cells)
        self.assertEqual(self.run_tool(), 0)
        items = self.data / "Table" / "items.lang.tsv"
        skills = self.data / "Table" / "skills.lang.tsv"
        self.assertTrue(items.read_text(encoding="utf-8").endswith("id\tcolumn\ttext\n7\tname\tKiếm\n7\tdescription\t#GSắc\n"))
        self.assertTrue(skills.read_text(encoding="utf-8").endswith("id\tcolumn\ttext\n3\tname\tChưởng\n"))
        stamp = (self.state / "deployed.stamp").read_bytes()
        self.write_manifest(MANIFEST + cells.replace("table/skills/3/name\tChưởng\n", ""))
        self.assertEqual(self.run_tool(), 0)
        self.assertFalse(skills.exists(), "bảng thôi được nêu thì bản dịch bị gỡ")
        self.assertTrue(items.exists())
        self.assertNotEqual((self.state / "deployed.stamp").read_bytes(), stamp, "đổi bản dịch bảng thì mốc đổi")

    # Mốc của bước đóng gói: đổi khi và chỉ khi thứ đã đưa vào thư mục dữ liệu đổi.
    def test_stamp_changes_exactly_when_the_deployment_changes(self) -> None:
        stamp = self.state / "deployed.stamp"
        self.gather()
        self.assertEqual(self.run_tool(), 0)
        first = (stamp.read_bytes(), stamp.stat().st_mtime_ns)
        self.assertEqual(self.run_tool(), 0)
        self.assertEqual((stamp.read_bytes(), stamp.stat().st_mtime_ns), first, "không đổi gì thì mốc đứng yên")
        self.write_manifest(MANIFEST.replace("Trợ giúp", "Giúp"))
        self.assertEqual(self.run_tool(), 0)
        after_text = stamp.read_bytes()
        self.assertNotEqual(after_text, first[0], "đổi một chuỗi")
        self.paint_patch((4, 2), WHITE)
        self.assertEqual(self.run_tool(), 0)
        after_image = stamp.read_bytes()
        self.assertNotEqual(after_image, after_text, "đổi một ảnh thay")
        self.write_manifest(MANIFEST.replace("Trợ giúp", "Giúp").replace("image/Frames/Logo\tlogo.png\n", ""))
        self.assertEqual(self.run_tool(), 0)
        self.assertNotEqual(stamp.read_bytes(), after_image, "thôi thay một ảnh")


if __name__ == "__main__":
    unittest.main()
