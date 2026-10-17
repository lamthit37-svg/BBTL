#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/port/test_hlsl_origin.py
#  PHÂN HỆ   : Port / Test Hlsl Origin
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm bộ chuyển shader HLSL của client gốc (hlsl_origin.py) trên một kho
#    gốc nhỏ dựng trong thư mục tạm: location vào ra theo semantic, ghim gốc
#    location của struct, chặn struct trả về cùng biến ra rời, và vá nguồn.
#    Phép kiểm mã máy fxc (oracle) cần D3DCompiler_43.dll của client gốc nên
#    không ở đây. Chạy: py TOOLS/port/test_hlsl_origin.py
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import hlsl_origin
from hlsl_origin import Edit, OriginError, Patch

PROGRAMS = """vertex_program MiniVS hlsl
{
\tsource Mini.hlsl
\tentry_point mainVS
\ttarget vs_3_0
}

fragment_program MiniPS hlsl
{
\tsource Mini.hlsl
\tentry_point mainPS
\ttarget ps_3_0
}
"""

# Struct vào ra kèm biến rời ở cả hai phía: đúng dạng làm slangc 2026.17 dời location trường struct
# (WaveGrass.hlsl của client gốc).
SOURCE = """struct V
{
\tfloat4 P : POSITION;
\tfloat4 C : COLOR0;
\tfloat2 T : TEXCOORD0;
};

void mainVS(float4 p : POSITION, out V o, out float f : TEXCOORD1)
{
\to.P = p;
\to.C = p;
\to.T = p.xy;
\tf = p.z;
}

float4 mainPS(V i, float f : TEXCOORD1) : COLOR0
{
\treturn i.C * f;
}
"""

RETURNED = """struct V
{
\tfloat4 P : POSITION;
\tfloat2 T : TEXCOORD0;
};

V mainVS(float4 p : POSITION, out float f : TEXCOORD1)
{
\tV o;
\to.P = p;
\to.T = p.xy;
\tf = p.z;
\treturn o;
}

float4 mainPS(V i, float f : TEXCOORD1) : COLOR0
{
\treturn i.T.xyxy * f;
}
"""


def make_origin(base: Path, source: str) -> Path:
    origin = base / "origin"
    templates = origin / hlsl_origin.TEMPLATES
    templates.mkdir(parents=True)
    (templates / "Mini.program").write_text(PROGRAMS, encoding="utf-8")
    (templates / "Mini.hlsl").write_text(source, encoding="utf-8")
    (origin / hlsl_origin.COMPAT_NAME).write_text("#pragma once\n", encoding="utf-8")
    return origin


def generate(base: Path, source: str) -> str:
    origin = make_origin(base, source)
    output = base / "out"
    hlsl_origin.generate(origin, output)
    return (output / "src" / "Mini.hlsl").read_text(encoding="utf-8")


class LocationTest(unittest.TestCase):
    def test_struct_params_pin_base_and_fields_follow_table(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            text = generate(Path(temp), SOURCE)
        self.assertIn("[[vk::location(0)]] out V o", text)
        self.assertIn("[[vk::location(0)]] V i", text)
        self.assertIn("[[vk::location(11)]] float4 C : COLOR0;", text)
        self.assertIn("[[vk::location(0)]] float2 T : TEXCOORD0;", text)
        self.assertIn("[[vk::location(1)]] out float f : TEXCOORD1", text)
        self.assertIn("float4 P : SV_Position;", text)

    def test_returned_struct_with_loose_output_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(OriginError, "MiniVS: struct V trả về cùng biến ra rời"):
                generate(Path(temp), RETURNED)

    def test_semantic_tables_stay_below_sixteen(self) -> None:
        tables = (hlsl_origin.VARYING_LOCATIONS, hlsl_origin.INPUT_LOCATIONS)
        for table in tables:
            locations = list(table.values())
            self.assertEqual(len(locations), len(set(locations)))
            self.assertTrue(all(0 <= location < 16 for location in locations))


class PatchTest(unittest.TestCase):
    def test_patch_follows_crlf_of_the_file(self) -> None:
        patch = Patch("a.hlsl", "x = 1;\n", "x = 2;\n", "lý do")
        text = hlsl_origin.apply_patches("a.hlsl", "x = 1;\r\ny = 0;\r\n", [patch])
        self.assertEqual(text, "x = 2;\r\ny = 0;\r\n")

    def test_patch_must_match_exactly_once(self) -> None:
        patch = Patch("a.hlsl", "x", "y", "lý do")
        with self.assertRaisesRegex(OriginError, "khớp 2 lần"):
            hlsl_origin.apply_patches("a.hlsl", "x x", [patch])
        with self.assertRaisesRegex(OriginError, "khớp 0 lần"):
            hlsl_origin.apply_patches("a.hlsl", "z", [patch])


class EditTest(unittest.TestCase):
    def test_whole_line_insert_goes_before_inline_insert_at_same_place(self) -> None:
        # Hồi quy: "uniform " chèn trước dòng #define vừa thêm sinh "uniform #define ...".
        text = "float a;\n"
        edits = [Edit(0, 0, "uniform "), Edit(0, 0, "#define B 1\n")]
        self.assertEqual(hlsl_origin.apply_edits(text, edits), "#define B 1\nuniform float a;\n")

    def test_overlapping_edits_are_rejected(self) -> None:
        with self.assertRaisesRegex(OriginError, "chồng nhau"):
            hlsl_origin.apply_edits("abcdef", [Edit(0, 3, "x"), Edit(2, 4, "y")])


if __name__ == "__main__":
    unittest.main()
