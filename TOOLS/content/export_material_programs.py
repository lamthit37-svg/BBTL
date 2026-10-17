# -*- coding: utf-8 -*-
#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/export_material_programs.py
#  PHÂN HỆ   : Content / Export Material Programs
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Sinh Material/programs.tsv: chất liệu dùng luồng sáng (Model_Flow_ps.hlsl)
#    hay viền sáng (USE_OUTLINE=1) của client 2026, sau kế thừa OGRE đầy đủ.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Sinh Material/programs.tsv: chất liệu dùng luồng sáng (Model_Flow_ps.hlsl) hay viền sáng
(USE_OUTLINE=1) của client 2026, sau kế thừa OGRE đầy đủ.

Chạy từ gốc dự án:
  py -3 -B TOOLS/content/export_material_programs.py

Bộ đọc all.material của engine (resource/ogre_mesh.cpp) đọc từng dòng, không đọc MaterialTemplates
và không phân biệt pass, nên mất chương trình, tham số và pass ghi depth của các mẫu này. Bảng này
là phần còn thiếu đó, tính bằng TOOLS/glb/ogre_material.py (trộn technique, pass, texture_unit như
MaterialSerializer). Tham số: mặc định của chương trình trong Character.program, rồi pass của mẫu,
rồi pass của chất liệu con, cái sau thắng. Define không khai coi là 0, như bộ tiền xử lý của HLSL.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "TOOLS" / "glb"))

import ogre_material as ogre  # noqa: E402

ASSETS = ROOT / "dev" / "client" / "assets"
TEMPLATES = ASSETS / "MaterialTemplates"
LIBRARY = ASSETS / "Material" / "all.material"
PROGRAMS = ROOT / "src" / "client" / "render" / "shaders" / "origin" / "MaterialTemplates"
OUT = ASSETS / "Material" / "programs.tsv"

FLOW_SOURCE = b"Model_Flow_ps.hlsl"
ALIASES = {
    "base": b"<baseTexture>",
    "ctl": b"<ctlTex>",
    "reflection": b"<_Reflection>",
    "outline_ctrl": b"<outlineCtrlTexture>",
}
PARAMS = {"flow_factor": (b"flowFactor", 4), "outline_pow": (b"outlinePow", 2),
          "outline_color": (b"outlineColor", 4)}
HEADER = ("material\tprogram\tflow\tflow_light_type\tflow_tex_type\toutline\toutline_ctrl\tdissolve\t"
          "blend\tdepth_write\talpha_ref\tcull\tdepth_pass\tdepth_ref\temissive\tdiffuse\t"
          "flow_factor\toutline_pow\toutline_color\tbase\tctl\treflection\toutline_ctrl_texture")


def text(value):
    return value.decode("gb18030", errors="replace")


def read_programs():
    """fragment_program của Character.program: tên -> (nguồn, define, tham số mặc định)."""
    data = (PROGRAMS / "Character.program").read_bytes()
    root = ogre.parse_blocks(ogre.clean_lines(data))
    found = {}
    for node in root.blocks(b"fragment_program"):
        name = node.argument.split()[0]
        source = node.value(b"source") or b""
        defines = {}
        for pair in (node.value(b"preprocessor_defines") or b"").split(b";"):
            key, _, value = pair.strip().partition(b"=")
            if key:
                defines[key] = value or b"1"
        params = {}
        for block in node.blocks(b"default_params"):
            params.update(named_params(block))
        found[name] = (source, defines, params)
    return found


def named_params(block):
    params = {}
    for keyword, argument in block.lines:
        parts = argument.split()
        if keyword == b"param_named" and len(parts) >= 3:
            params[parts[0]] = parts[2:]
    return params


def merged_passes(library, name):
    """Pass gần của chất liệu sau kế thừa, kèm bảng alias. None khi tên không có định nghĩa."""
    chain = library.chain(name)
    if not chain:
        return None
    merged = ogre.Node(b"material")
    for definition in reversed(chain):
        ogre.merge_node(merged, definition.node)
    aliases = {}
    for keyword, argument in merged.lines:
        parts = argument.split()
        if keyword == b"set_texture_alias" and len(parts) >= 2:
            aliases[parts[0]] = parts[1]
    return ogre.near_passes(merged), aliases


def program_of(node):
    refs = node.blocks(b"fragment_program_ref")
    if not refs:
        return b"", {}
    return refs[0].argument.split()[0] if refs[0].argument else b"", named_params(refs[0])


def is_family(programs, program):
    entry = programs.get(program)
    if entry is None:
        return False
    source, defines, _ = entry
    return source == FLOW_SOURCE or defines.get(b"USE_OUTLINE") == b"1"


def define(defines, key):
    return text(defines.get(key, b"0"))


def is_visible(node):
    blend = (node.value(b"scene_blend") or b"").split()
    return blend != [b"zero", b"one"] and node.value(b"colour_write") != b"off"


def texture_by_alias(node, aliases, alias):
    for unit in node.blocks(b"texture_unit"):
        use = ogre.texture_use(unit, aliases)
        if use.alias != alias:
            continue
        # Alias chưa được chất liệu con đặt thì texture còn là tên giữ chỗ "<ctlTex>.jpg".
        return "" if use.texture.startswith(b"<") else text(use.texture)
    return ""


# StringConverter::parseReal của OGRE: istringstream >> Real lấy phần số dài nhất ở đầu và bỏ phần
# thừa, không có số thì 0. all.material có lỗi gõ như "0.0.0" (pet_2022ZSliuheE01半透), gốc đọc là 0.
NUMBER = re.compile(rb"[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")


def ogre_real(token):
    match = NUMBER.match(token)
    return text(match.group(0)) if match else "0"


def param_cell(params, key, width):
    values = params.get(key)
    if values is None:
        return ""
    return " ".join(ogre_real(value) for value in values[:width])


def row_of(name, passes, aliases, programs):
    visible = [node for node in passes if is_visible(node)]
    if not visible:
        return None
    shown = visible[0]
    program, own = program_of(shown)
    if not is_family(programs, program):
        return None
    source, defines, defaults = programs[program]
    params = dict(defaults)
    params.update(own)
    depth = [node for node in passes[:passes.index(shown)] if not is_visible(node)]
    depth_ref = text(depth[0].value(b"alpha_rejection") or b"") if depth else ""
    is_flow = source == FLOW_SOURCE
    cells = [text(name), text(program), "1" if is_flow else "0", define(defines, b"FLOW_LIGHT_TYPE"),
             define(defines, b"FLOW_TEX_TYPE"), define(defines, b"USE_OUTLINE"),
             define(defines, b"USE_OUTLINE_CTRL_TEX"), define(defines, b"DISSOLVE_EFFECT"),
             text(shown.value(b"scene_blend") or b""), text(shown.value(b"depth_write") or b""),
             text(shown.value(b"alpha_rejection") or b""),
             text(shown.value(b"cull_hardware") or b""), "1" if depth else "0", depth_ref,
             text(shown.value(b"emissive") or b""), text(shown.value(b"diffuse") or b"")]
    for key, (param, width) in PARAMS.items():
        cells.append(param_cell(params, param, width))
    for alias in ALIASES.values():
        cells.append(texture_by_alias(shown, aliases, alias))
    if not is_flow:
        cells[3] = cells[4] = "0"
    return "\t".join(" ".join(cell.split()) for cell in cells) + "\n"


def main():
    library = ogre.MaterialLibrary()
    for path in sorted(TEMPLATES.glob("*.material")):
        library.load(path.read_bytes())
    templates = set(library.definitions)
    library.load(LIBRARY.read_bytes())
    programs = read_programs()
    rows = []
    counts = {}
    for name in library.definitions:
        if name in templates:
            continue
        found = merged_passes(library, name)
        if found is None:
            continue
        row = row_of(name, found[0], found[1], programs)
        if row is None:
            continue
        rows.append(row)
        program = row.split("\t", 2)[1]
        counts[program] = counts.get(program, 0) + 1
    rows.sort()
    note = (
        "# source: Material/all.material, MaterialTemplates/*.material, Character.program\n"
        "# tool: TOOLS/content/export_material_programs.py\n"
        "# Một dòng mỗi chất liệu mà pass hiện màu đầu tiên dùng Model_Flow_ps.hlsl (flow 1) hay\n"
        "# USE_OUTLINE=1. Không có luồng thì hai cột kiểu luồng là 0.\n"
        "# blend, depth_write, alpha_ref, cull, emissive, diffuse nguyên văn của pass ấy; rỗng là mặc\n"
        "# định OGRE. depth_pass 1: có pass ghi depth (colour_write off) đứng trước, depth_ref là\n"
        "# alpha_rejection của nó. Tham số đã trộn mặc định của chương trình. Ảnh rỗng là alias chưa\n"
        "# được đặt. Tên chất liệu và ảnh là UTF-8 (bản gốc GBK).\n"
    )
    OUT.write_text(note + HEADER + "\n" + "".join(rows), encoding="utf-8", newline="\n")
    print(f"programs.tsv {len(rows)} dòng; duplicate {library.duplicate_count}")
    for program, count in sorted(counts.items(), key=lambda item: -item[1]):
        print(f"  {program} {count}")


if __name__ == "__main__":
    main()
