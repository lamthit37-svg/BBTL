#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/test_bake_mobile_textures.py
#  PHÂN HỆ   : Content / Bake Mobile Textures
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm luật chọn nguồn của bộ nấu texture điện thoại: ảnh giao diện đã địa hoá
#    (<gốc>.png) chỉ thay bản gốc khi cùng cỡ, đúng như ui/painter.cpp sheet_file.
#    Hồi quy: bản nấu từng đọc bản gốc nên logo mới không lên APK.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Chạy: python -B TOOLS/content/test_bake_mobile_textures.py

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

import bake_mobile_textures


def write_png(path: Path, size: tuple[int, int]) -> None:
    # Tên tệp gốc giữ đuôi .dds nhưng nội dung PNG: Pillow nhận theo nội dung, đủ cho phép so cỡ.
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", size, (255, 0, 0, 255)).save(path, format="PNG")


class PatchedSourceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.folder = Path(tempfile.mkdtemp())
        self.source = self.folder / "Interface" / "Common" / "tga_Logo.dds"

    def tearDown(self) -> None:
        shutil.rmtree(self.folder, ignore_errors=True)

    def test_without_patch_the_source_is_used(self) -> None:
        write_png(self.source, (16, 8))
        self.assertEqual(bake_mobile_textures.patched_source(self.source), self.source)

    def test_same_size_patch_replaces_the_source(self) -> None:
        write_png(self.source, (16, 8))
        patch = self.source.with_name(self.source.name + ".png")
        write_png(patch, (16, 8))
        self.assertEqual(bake_mobile_textures.patched_source(self.source), patch)

    def test_other_size_patch_is_ignored(self) -> None:
        write_png(self.source, (16, 8))
        write_png(self.source.with_name(self.source.name + ".png"), (32, 8))
        self.assertEqual(bake_mobile_textures.patched_source(self.source), self.source)

    def test_unreadable_patch_falls_back_to_the_source(self) -> None:
        write_png(self.source, (16, 8))
        self.source.with_name(self.source.name + ".png").write_bytes(b"khong phai anh")
        self.assertEqual(bake_mobile_textures.patched_source(self.source), self.source)


if __name__ == "__main__":
    unittest.main()
