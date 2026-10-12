# Kiểm collect_fx trên một kho gốc nhỏ dựng trong thư mục tạm: tập con script, bảng material sau kế
# thừa, tệp chép và cách phân biệt "kho gốc không có" với "cây GLB thiếu".
# Chạy: python TOOLS/content/test_collect_fx.py

from __future__ import annotations

import json
import os
import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import collect_fx
from collect_map import Collector

GBK = "gb18030"

EFFECTS = """effect 火
{
\telement Particle
\t{
\t\tParticleSystem\t火_1
\t}

\telement Particle
\t{
\t\tParticleSystem\t雾
\t}

\telement Beam
\t{
\t\tMaterial\t光束
\t}

\tLifeTime\t0
}

effect 不用
{
\telement Particle
\t{
\t\tParticleSystem\t不用
\t}
}
"""

PARTICLES = """火_1
{
\tquota 4
\tmaterial 火
\trenderer billboard

\temitter Box
\t{
\t\temission_rate 2
\t}
}

不用
{
\tmaterial 不用
}

雾
{
\tmaterial 雾
}

冰
{
\tmaterial 冰
\trenderer mesh
\tmesh_name 冰.mesh
}

火_1
{
\tmaterial 第二个定义
}
"""

TEMPLATES = """material Mtl_Particle
{
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\tdiffuse 0 0 0 1
\t\t\tscene_blend add
\t\t\tdepth_write off
\t\t\tfragment_program_ref Particle_PS
\t\t\t{
\t\t\t}
\t\t\ttexture_unit
\t\t\t{
\t\t\t\ttexture <baseTex>.jpg
\t\t\t\ttexture_alias <baseTexture>
\t\t\t}
\t\t}
\t}
}

material Mtl_Particle_ColorX4
{
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\tscene_blend add
\t\t\tfragment_program_ref Particle_ColorX4_PS
\t\t\t{
\t\t\t}
\t\t\ttexture_unit
\t\t\t{
\t\t\t\ttexture <baseTex>.jpg
\t\t\t\ttexture_alias <baseTexture>
\t\t\t}
\t\t}
\t}
}

material Mtl_Particle_TwoTex
{
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\tscene_blend add
\t\t\tfragment_program_ref Particle_TwoTex_PS
\t\t\t{
\t\t\t}
\t\t\ttexture_unit
\t\t\t{
\t\t\t\ttexture <baseTex>.jpg
\t\t\t\ttexture_alias <baseTexture>
\t\t\t}
\t\t\ttexture_unit scrollTex
\t\t\t{
\t\t\t\ttexture <scrollTex>.jpg
\t\t\t\ttexture_alias <scrollTex>
\t\t\t}
\t\t}
\t}
}
"""

PROGRAMS = """fragment_program Particle_PS hlsl
{
\tsource Particle_ps.hlsl
}

fragment_program Particle_ColorX4_PS hlsl
{
\tsource Particle_ps.hlsl
\tpreprocessor_defines BLEND_OP_0=2
}

fragment_program Particle_TwoTex_PS hlsl
{
\tsource Particle_2Tex_ps.hlsl
\tpreprocessor_defines ENABLE_DIFFUSE_2=1
}
"""

MATERIALS = """material 火 : Mtl_Particle_ColorX4
{
\tset_texture_alias <baseTexture> 火.dds
}

material 雾 : Mtl_Particle
{
\tset_texture_alias <baseTexture> 雾.dds
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\tscene_blend src_alpha one_minus_src_alpha
\t\t}
\t}
}

material 冰 : Mtl_Particle_TwoTex
{
\tset_texture_alias <baseTexture> 冰.dds
\tset_texture_alias <scrollTex> 流.dds
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\ttexture_unit
\t\t\t{
\t\t\t\tscale 2 1
\t\t\t\tscroll_anim 0 0.5
\t\t\t}
\t\t}
\t}
}

material 光束
{
\ttechnique
\t{
\t\tpass
\t\t{
\t\t\tlighting off
\t\t\tscene_blend add
\t\t\ttexture_unit
\t\t\t{
\t\t\t\ttexture 光束.png
\t\t\t}
\t\t}
\t}
}
"""

SCENE = """<?xml version="1.0" encoding="UTF-8"?>
<Scene>
  <Object type="Effect">
    <Property name="effect name" value="火"/>
  </Object>
  <Object type="Effect">
    <Property name="effect name" value="火"/>
  </Object>
  <Object type="ParticleSystem">
    <Property name="particle system name" value="冰"/>
  </Object>
  <Object type="ParticleSystem">
    <Property name="particle system name" value="没有"/>
  </Object>
  <Object type="StaticEntity">
    <Property name="mesh name" value="不相干.mesh"/>
  </Object>
</Scene>
"""

IMAGES = ("火.dds", "雾.dds", "冰.dds", "流.dds", "光束.png")


def glb_bytes() -> bytes:
    document = json.dumps({"asset": {"version": "2.0"}}).encode("utf-8")
    document += b" " * (-len(document) % 4)
    chunk = struct.pack("<II", len(document), 0x4E4F534A) + document
    return struct.pack("<4sII", b"glTF", 2, 12 + len(chunk)) + chunk


def write(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


class FxGathering(unittest.TestCase):
    def setUp(self) -> None:
        self.folder = tempfile.TemporaryDirectory()
        base = Path(self.folder.name)
        self.raw, self.glb, self.data = base / "raw", base / "glb", base / "data"
        write(self.raw / "Effect" / "all.effect", EFFECTS.replace("\n", "\r\n").encode(GBK))
        write(self.raw / "Effect" / "all.particle", PARTICLES.replace("\n", "\r\n").encode(GBK))
        write(self.raw / "MaterialTemplates" / "Mtl_Particle.material", TEMPLATES.encode(GBK))
        write(self.raw / "MaterialTemplates" / "Particle.program", PROGRAMS.encode(GBK))
        write(self.raw / "Material" / "all.material", MATERIALS.encode(GBK))
        write(self.raw / "Model" / "冰.mesh", b"mesh")
        write(self.glb / "Model" / "冰.mesh.glb", glb_bytes())
        for name in IMAGES:
            write(self.raw / "Material" / name, b"raw")
            twin = name if name.endswith(".png") else name + ".png"
            write(self.glb / "Material" / twin, b"png " + name.encode("utf-8"))
        write(self.data / "Scene" / "demo.Scene", SCENE.encode("utf-8"))
        self.collector = Collector(str(self.raw), str(self.glb), str(self.data))

    def tearDown(self) -> None:
        self.folder.cleanup()

    def gathered(self) -> tuple[collect_fx.Wanted, dict[str, collect_fx.Row]]:
        wanted, rows, _ = collect_fx.collect(self.collector, [])
        return wanted, {row.name: row for row in rows}

    def output(self, name: str) -> str:
        return (self.data / "effect" / name).read_bytes().decode("utf-8")

    # Client nạp trọn hai tệp script lúc mở, nên chỉ khối được gọi mới được chép; tên trùng giữ
    # khối đầu như ScriptIndex của client, không thì client và bộ gom hiểu một tên thành hai hệ.
    def test_only_called_blocks_are_kept_as_utf8(self) -> None:
        wanted, _ = self.gathered()
        effects = self.output("all.effect")
        particles = self.output("all.particle")
        self.assertIn("effect 火\n{", effects)
        self.assertNotIn("不用", effects)
        self.assertNotIn("\r", effects + particles)
        for name in ("火_1\n{", "雾\n{", "冰\n{", "material 火\n"):
            self.assertIn(name, particles)
        self.assertNotIn("不用", particles)
        self.assertNotIn("第二个定义", particles)
        self.assertEqual(wanted.effects["火"], 2)
        self.assertEqual(wanted.systems["冰"], 1)
        self.assertEqual(wanted.systems["火_1"], 0)

    # Ảnh, chế độ trộn và hệ số màu nằm ở mẫu cha: phải giải kế thừa mới có.
    def test_rows_carry_inherited_material(self) -> None:
        _, rows = self.gathered()
        fire = rows["火"]
        self.assertEqual(fire.cells(), ["火", "Material/火.dds.png", "one one", "4", "", "0", "0", "particle", ""])
        self.assertTrue(fire.is_plain())
        self.assertEqual(rows["雾"].blend, "src_alpha one_minus_src_alpha")
        self.assertEqual(rows["雾"].gain, 1)
        beam = rows["光束"]
        self.assertEqual((beam.image, beam.shader, beam.blend), ("Material/光束.png", "fixed", "one one"))

    # Material hai ảnh có cuộn không phải thứ pipeline một ảnh vẽ đúng: bảng phải nói ra đủ.
    def test_two_texture_row_is_not_plain(self) -> None:
        _, rows = self.gathered()
        ice = rows["冰"]
        self.assertEqual(ice.second, "Material/流.dds.png")
        self.assertEqual(ice.scroll, ("0", "0.5"))
        self.assertEqual(ice.shader, "Particle_TwoTex_PS")
        self.assertEqual(ice.extra, "scale 2 1")
        self.assertFalse(ice.is_plain())

    def test_table_and_file_list_are_written(self) -> None:
        self.gathered()
        table = self.output("materials.tsv").split("\n")
        self.assertEqual(table[0].split("\t"), list(collect_fx.TABLE_COLUMNS))
        self.assertEqual([line.split("\t")[0] for line in table[1:] if line], ["光束", "冰", "火", "雾"])
        listed = self.output("fx.files.tsv")
        for line in ("fx_texture\tMaterial/火.dds.png", "mesh\tModel/冰.mesh.glb", "fx_script\teffect/materials.tsv"):
            self.assertIn(line, listed)
        self.assertEqual((self.data / "Material" / "流.dds.png").read_bytes(), "png 流.dds".encode("utf-8"))
        self.assertTrue((self.data / "Model" / "冰.mesh.glb").is_file())

    # Tên cảnh gọi mà kho gốc không định nghĩa là thiếu sót của chính client gốc, không phải lỗi gom.
    def test_names_absent_from_the_source_are_notes(self) -> None:
        wanted, _ = self.gathered()
        self.assertEqual(self.collector.missing, [])
        self.assertIn("kho gốc không định nghĩa hệ hạt 没有", wanted.notes)

    # Kho gốc có ảnh mà cây GLB không có bản PNG là lượt xuất GLB chưa đủ: phải báo lỗi, và ô ảnh để
    # trống cho client khỏi tìm một tệp không tồn tại.
    def test_missing_png_twin_is_a_failure(self) -> None:
        (self.glb / "Material" / "雾.dds.png").unlink()
        _, rows = self.gathered()
        self.assertIn(("fx_texture", "Material/雾.dds.png"), self.collector.missing)
        self.assertEqual(rows["雾"].image, "")
        self.assertFalse(rows["雾"].is_plain())

    def test_unknown_scene_is_a_failure(self) -> None:
        collect_fx.collect(self.collector, ["khong_co"])
        expected = os.path.join(str(self.data), "Scene", "khong_co.Scene")
        self.assertIn(("scene", expected), self.collector.missing)


class ScriptIndex(unittest.TestCase):
    # Cùng luật với SRC/fx/script.cpp: tên là từ thứ name_word của dòng đứng trước dấu { cấp cao.
    def test_names_follow_the_client_index(self) -> None:
        text = "// đầu tệp\n\neffect a\n{\n\telement Particle\n\t{\n\t}\n}\n\n\neffect b {\n}\neffect a\n{\n}\n"
        script = collect_fx.index_script(text, 1)
        self.assertEqual(list(script.spans), ["a", "b"])
        self.assertEqual(script.block("a"), "effect a\n{\n\telement Particle\n\t{\n\t}\n}")
        self.assertEqual(script.block("b"), "effect b {\n}")

    def test_defines_are_split_on_semicolons(self) -> None:
        defines = collect_fx.defines_of(b"BLEND_OP_0=2;ENABLE_CLAMP=1")
        self.assertEqual(defines, {b"BLEND_OP_0": b"2", b"ENABLE_CLAMP": b"1"})
        self.assertEqual(collect_fx.defines_of(None), {})


if __name__ == "__main__":
    unittest.main()
