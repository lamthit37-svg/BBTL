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


if __name__ == "__main__":
    unittest.main()
