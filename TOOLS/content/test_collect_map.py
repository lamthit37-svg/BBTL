# Kiểm chuỗi phụ thuộc của collect_map trên một cây nguồn nhỏ dựng trong thư mục tạm.
# Chạy: python TOOLS/content/test_collect_map.py

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import collect_map

SCENE_WITH_SKY = """<?xml version="1.0" encoding="utf-8"?>
<Scene>
  <SkySphere enabled="true" filename="demo.skysphere" objectname="#FairySkySphere"/>
  <Object name="#FairySkySphere" type="SkySphere"/>
</Scene>
"""


class SceneDependencies(unittest.TestCase):
    def setUp(self) -> None:
        self.folder = tempfile.TemporaryDirectory()
        self.raw = Path(self.folder.name) / "raw"
        (self.raw / "Scene").mkdir(parents=True)
        (self.raw / "Scene" / "demo.Scene").write_text(SCENE_WITH_SKY, encoding="utf-8")
        target = Path(self.folder.name) / "data"
        self.collector = collect_map.Collector(str(self.raw), str(self.raw), str(target))

    def tearDown(self) -> None:
        self.folder.cleanup()

    # Client đọc bảng môi trường theo giờ từ tệp mà phần tử SkySphere của cảnh nêu tên: thiếu tệp
    # này trong danh sách thì bản đóng gói (APK) mất ánh sáng theo giờ mà bản PC vẫn có.
    def test_sky_file_of_the_scene_is_listed(self) -> None:
        (self.raw / "Scene" / "demo.skysphere").write_text("<SkySphere/>", encoding="utf-8")
        collect_map.collect_scene(self.collector, "demo")
        sky = os.path.normpath("Scene/demo.skysphere")
        self.assertIn(sky, self.collector.files)
        self.assertEqual(self.collector.files[sky][0], "sky")
        self.assertEqual(self.collector.missing, [])

    def test_missing_sky_file_is_reported(self) -> None:
        collect_map.collect_scene(self.collector, "demo")
        sky = os.path.normpath("Scene/demo.skysphere")
        self.assertIn(("sky", sky), self.collector.missing)


# Một dòng của bảng cảnh: cột 4 tên .Scene, cột 5 tên .path, cột 10 token minimap.
def table_row(scene: str, path_name: str) -> str:
    cells = ["2", "Demo", "320", "320", f"{scene}.Scene", path_name, f"{scene}.wCollision", f"{scene}.jpg", "0", "0", scene]
    return "\t".join(cells) + "\n"


class WalkFiles(unittest.TestCase):
    def setUp(self) -> None:
        self.folder = tempfile.TemporaryDirectory()
        self.raw = Path(self.folder.name) / "raw"
        (self.raw / "Scene").mkdir(parents=True)
        self.target = Path(self.folder.name) / "data"
        (self.target / "Config").mkdir(parents=True)
        self.collector = collect_map.Collector(str(self.raw), str(self.raw), str(self.target))

    def tearDown(self) -> None:
        self.folder.cleanup()

    def write_table(self, *rows: str) -> None:
        (self.target / "Config" / "SceneDefineEx.txt").write_text("".join(rows), encoding="utf-8")

    # Client mở lưới đi theo tên .path của bảng cảnh và mặt công trình theo tên cảnh đổi đuôi: thiếu
    # hai tệp này trong danh sách thì cảnh có kho gốc đầy đủ vẫn cho nhân vật đi xuyên mọi vật cản.
    def test_walk_and_collision_files_are_listed(self) -> None:
        (self.raw / "Scene" / "demo.path").write_bytes(b"path")
        (self.raw / "Scene" / "demo.WCollision").write_bytes(b"wc")
        self.write_table(table_row("demo", "demo.path"))
        collect_map.collect_walk(self.collector, "demo")
        self.assertEqual(self.collector.files[os.path.normpath("Scene/demo.path")][0], "walk")
        self.assertEqual(self.collector.files[os.path.normpath("Scene/demo.WCollision")][0], "collision")
        self.assertEqual(self.collector.missing, [])
        self.assertEqual(self.collector.notes, [])

    # Nhiều cảnh không có hai tệp ấy ở kho gốc: chỉ là ghi chú, không làm map hỏng (mã thoát 1).
    def test_scene_without_walk_files_only_leaves_notes(self) -> None:
        self.write_table(table_row("demo", "demo.path"))
        collect_map.collect_walk(self.collector, "demo")
        self.assertEqual(self.collector.files, {})
        self.assertEqual(self.collector.missing, [])
        self.assertEqual(len(self.collector.notes), 2)

    def test_scene_missing_from_the_table_keeps_collision_only(self) -> None:
        (self.raw / "Scene" / "demo.WCollision").write_bytes(b"wc")
        collect_map.collect_walk(self.collector, "demo")
        self.assertEqual(list(self.collector.files), [os.path.normpath("Scene/demo.WCollision")])
        self.assertEqual(self.collector.missing, [])
        self.assertEqual(len(self.collector.notes), 1)


if __name__ == "__main__":
    unittest.main()
