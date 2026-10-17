#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/port/hlsl_origin.py
#  PHÂN HỆ   : Port / Hlsl Origin
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Chuyển bộ shader HLSL của client 2026 (MaterialTemplates: cú pháp D3D9,
#    tham số tự gắn của OGRE) thành gói .f2s của engine qua Slang, giữ nguyên
#    công thức của bản gốc. Quyết định:
#  - Nguồn gốc nằm ở src/client/render/shaders/origin/MaterialTemplates, đổi
#    GBK sang UTF-8 (chỉ chữ trong chú thích đổi mã hoá, NGUON.tsv giữ băm của
#    tệp gốc).
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Khai báo chương trình là các tệp .program chép nguyên đường dẫn tương đối của kho gốc. Mọi biến đổi chạy lúc dựng
# trên bản sao.
# - Chỉ biến đổi thứ Slang không nhận mà fxc nhận, và lệnh oracle chứng minh từng chương trình cho
#   cùng mã máy (khối SHEX) với bản chưa biến đổi khi dịch bằng D3DCompiler_43 của client gốc, đích
#   vs_5_0/ps_5_0 và cờ 0x1010 (tương thích ngược, ma trận theo cột: khớp từng byte ShaderCache):
#   * giá trị đầu của biến toàn cục: fxc coi biến toàn cục không static là uniform có mặc định; ở đây
#     bỏ giá trị khỏi nguồn và ghi vào bảng tham số để engine điền như OGRE;
#   * ngữ nghĩa vào ra theo luật fxc ở chế độ tương thích: POSITION ra của VS là SV_Position, COLORn ra
#     của PS là SV_Targetn, DEPTH ra là SV_Depth, POSITION hay VPOS vào PS là SV_Position;
#   * Location của Vulkan gán theo ngữ nghĩa (bảng cố định) để VS và PS nối theo tên như D3D chứ
#     không theo thứ tự khai; thuộc tính [[vk::location]] bị fxc bỏ khi dịch đối chứng;
#   * vá tay trong patches.tsv, mỗi dòng một đoạn khớp đúng một lần.
# - sampler2D, tex2D... là kiểu và hàm của compat.slang (ảnh và sampler tách riêng như mô hình gắn
#   của engine), không phải biến đổi nguồn.
# - Thứ chưa gặp trong kho (const toàn cục không static, nhiều biến một dòng có giá trị đầu,
#   sampler_state) là lỗi, không tự đoán.
# Cách dùng:
#   python hlsl_origin.py vendor <kho gốc _goc> <thư mục origin>
#   python hlsl_origin.py generate <thư mục origin> <thư mục ra>
#   python hlsl_origin.py oracle <thư mục origin> <thư mục ra của generate> --fxc <D3DCompiler_43.dll>
#       [--cache <ShaderCache>]
# Mã thoát: 0 xong, 1 lỗi dữ liệu hoặc oracle thấy khác, 2 sai cách dùng.

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

GLB_TOOLS = Path(__file__).resolve().parents[1] / "glb"
if str(GLB_TOOLS) not in sys.path:
    sys.path.insert(0, str(GLB_TOOLS))

import ogre_material  # noqa: E402

SOURCE_ENCODING = "gb18030"
TEMPLATES = "MaterialTemplates"
SHADER_SUFFIXES = (".hlsl", ".inc")
LIST_NAME = "origin.list"
PARAMS_NAME = "origin.params.tsv"
COMPAT_NAME = "compat.slang"
PATCHES_NAME = "patches.tsv"
CODE_PROGRAMS_NAME = "code_programs.tsv"
SOURCES_NAME = "NGUON.tsv"


class OriginError(Exception):
    """Dữ liệu gốc có dạng công cụ chưa xử lý, hoặc biến đổi không áp được."""


# ---------------------------------------------------------------------------------------------
# Khai báo chương trình (.program)


@dataclass(frozen=True)
class Param:
    kind: str
    name: str
    value: str


@dataclass(frozen=True)
class Program:
    name: str
    stage: str
    source: str
    entry: str
    defines: tuple[str, ...]
    target: str
    column_major: str
    params: tuple[Param, ...]
    declared_in: str


def split_defines(text: str) -> tuple[str, ...]:
    # OGRE tách preprocessor_defines theo ';' hoặc ','; tên không có giá trị nhận "1" như
    # HighLevelGpuProgram của OGRE.
    defines = []
    for part in re.split(r"[;,]", text):
        item = part.strip()
        if not item:
            continue
        name, has_value, value = item.partition("=")
        defines.append(f"{name.strip()}={value.strip() if has_value else '1'}")
    return tuple(defines)


def program_of(node: ogre_material.Node, declared_in: str) -> Program:
    kind = node.keyword.decode("ascii")
    words = node.argument.decode("ascii").split()
    if len(words) != 2 or words[1] != "hlsl":
        raise OriginError(f"{declared_in}: chương trình không phải hlsl: {node.argument!r}")
    values = {name.decode("ascii"): argument.decode("ascii") for name, argument in node.lines}
    stage = "vs" if kind == "vertex_program" else "ps"
    params = []
    for block in node.blocks(b"default_params"):
        for name, argument in block.lines:
            parts = argument.decode("ascii").split(None, 1)
            value = " ".join(parts[1].split()) if len(parts) > 1 else ""
            params.append(Param(name.decode("ascii"), parts[0], value))
    return Program(
        name=words[0],
        stage=stage,
        source=values.get("source", "").replace("\\", "/"),
        entry=values.get("entry_point", "main"),
        defines=split_defines(values.get("preprocessor_defines", "")),
        target=values.get("target", values.get("profiles", "")),
        column_major=values.get("column_major_matrices", ""),
        params=tuple(params),
        declared_in=declared_in,
    )


def read_program_file(path: Path, declared_in: str) -> list[Program]:
    lines = ogre_material.clean_lines(path.read_bytes())
    root = ogre_material.parse_blocks(lines)
    programs = []
    for node in root.children:
        if node.keyword not in (b"vertex_program", b"fragment_program"):
            continue
        programs.append(program_of(node, declared_in))
    return programs


def read_code_programs(path: Path) -> list[Program]:
    # Chương trình Render.dll tạo trong mã máy (không có .program): tên, stage, nguồn, hàm vào,
    # define (ngăn bằng ';'), ghi chú nguồn gốc.
    if not path.is_file():
        return []
    programs = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cells = line.split("\t")
        if len(cells) != 6:
            raise OriginError(f"{path.name}:{number}: cần 6 cột, có {len(cells)}")
        name, stage, source, entry, defines, note = cells
        if stage not in ("vs", "ps"):
            raise OriginError(f"{path.name}:{number}: stage lạ {stage!r}")
        program = Program(name, stage, source, entry, split_defines(defines), f"{stage}_5_0", "",
                          (), f"{CODE_PROGRAMS_NAME}: {note}")
        programs.append(program)
    return programs


def read_programs(origin: Path) -> list[Program]:
    programs = []
    for path in sorted(origin.rglob("*.program")):
        declared_in = path.relative_to(origin).as_posix()
        programs.extend(read_program_file(path, declared_in))
    programs.extend(read_code_programs(origin / CODE_PROGRAMS_NAME))
    seen = {}
    for program in programs:
        if program.name in seen:
            raise OriginError(f"chương trình {program.name} khai hai lần: {seen[program.name]}, "
                              f"{program.declared_in}")
        seen[program.name] = program.declared_in
    return programs


def package_name(program: Program) -> str:
    # Tên gói là tên tệp: '/' trong tên OGRE ("HDR/StandardVS") thành '.', '%' của biến thể sương
    # ("Terrain/TwoLayerLightmap_ps%fog_linear") thành '-'. generate báo nếu hai tên trùng nhau.
    name = program.name.replace("/", ".").replace("%", "-")
    if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.\-]*", name) or ".." in name:
        raise OriginError(f"tên chương trình không đổi được thành tên gói: {program.name}")
    return name


# ---------------------------------------------------------------------------------------------
# Nhập kho gốc (vendor)


def decode_source(raw: bytes) -> tuple[str, str]:
    try:
        return raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return raw.decode(SOURCE_ENCODING), SOURCE_ENCODING


COMMENT = re.compile(r"//[^\n]*|/\*.*?\*/", re.S)


def code_is_ascii(text: str) -> bool:
    # Đổi mã hoá chỉ được chạm chữ trong chú thích: phần mã (token và dòng chỉ thị bỏ chú thích)
    # phải thuần ASCII, nên GBK hay UTF-8 cho cùng byte mà fxc thấy.
    lexed = lex(text)
    if not all(token.text.isascii() for token in lexed.tokens):
        return False
    return all(COMMENT.sub("", directive.text).isascii() for directive in lexed.directives)


def vendor(raw_root: Path, origin: Path) -> int:
    rows = []
    templates = raw_root / TEMPLATES
    files = [p for p in templates.rglob("*") if p.suffix.lower() in SHADER_SUFFIXES]
    files += list(raw_root.rglob("*.program"))
    for path in sorted(set(files)):
        relative = path.relative_to(raw_root).as_posix()
        raw = path.read_bytes()
        text, encoding = decode_source(raw)
        if text.encode(encoding) != raw:
            raise OriginError(f"{relative}: đổi mã hoá không hoàn nguyên được")
        target = origin / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        data = text.encode("utf-8")
        target.write_bytes(data)
        if path.suffix.lower() in SHADER_SUFFIXES and not code_is_ascii(text):
            raise OriginError(f"{relative}: có chữ ngoài ASCII nằm ngoài chú thích")
        rows.append((relative, hashlib.sha256(raw).hexdigest(), encoding,
                     hashlib.sha256(data).hexdigest(), str(len(raw))))
    lines = ["# Bộ shader gốc của client 2026, chép bằng TOOLS/port/hlsl_origin.py vendor.",
             f"# Kho gốc: {raw_root.as_posix()}. Cột: tệp, sha256 gốc, mã hoá gốc, sha256 bản UTF-8, byte.",
             "\t".join(("tệp", "sha256_gốc", "mã_hoá", "sha256_utf8", "byte"))]
    lines += ["\t".join(row) for row in rows]
    (origin / SOURCES_NAME).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"origin: chép {len(rows)} tệp vào {origin}")
    return 0


# ---------------------------------------------------------------------------------------------
# Tách từ HLSL


@dataclass(frozen=True)
class Token:
    kind: str
    text: str
    start: int
    end: int


@dataclass(frozen=True)
class Directive:
    text: str
    start: int
    end: int


@dataclass
class Lexed:
    tokens: list[Token]
    directives: list[Directive]


TOKEN_PATTERN = re.compile(r"""
    (?P<space>\s+)
  | (?P<line_comment>//[^\n]*)
  | (?P<block_comment>/\*.*?\*/)
  | (?P<string>"(?:\\.|[^"\\\n])*")
  | (?P<number>(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?[fFhHlLuU]*)
  | (?P<word>[A-Za-z_]\w*)
  | (?P<mark>.)
""", re.S | re.X)


def directive_end(text: str, start: int) -> int:
    # Dòng chỉ thị kéo dài qua các dòng kết thúc bằng '\'.
    position = start
    while True:
        newline = text.find("\n", position)
        if newline < 0:
            return len(text)
        line = text[position:newline].rstrip("\r")
        if not line.endswith("\\"):
            return newline
        position = newline + 1


def at_line_start(text: str, position: int) -> bool:
    line_start = text.rfind("\n", 0, position) + 1
    return text[line_start:position].strip() == ""


def lex(text: str) -> Lexed:
    tokens: list[Token] = []
    directives: list[Directive] = []
    position = 0
    while position < len(text):
        match = TOKEN_PATTERN.match(text, position)
        if match is None:
            raise OriginError(f"không tách được ở vị trí {position}")
        kind = match.lastgroup
        end = match.end()
        if kind == "mark" and match.group() == "#" and at_line_start(text, position):
            end = directive_end(text, position)
            directives.append(Directive(text[position:end], position, end))
        elif kind == "block_comment" and not match.group().endswith("*/"):
            raise OriginError("chú thích /* không đóng")
        elif kind in ("string", "number", "word", "mark"):
            tokens.append(Token(kind, match.group(), position, end))
        position = end
    return Lexed(tokens, directives)


def matching(tokens: list[Token], index: int) -> int:
    opener = tokens[index].text
    closer = {"(": ")", "[": "]", "{": "}"}[opener]
    depth = 0
    for position in range(index, len(tokens)):
        if tokens[position].text == opener:
            depth += 1
        elif tokens[position].text == closer:
            depth -= 1
            if depth == 0:
                return position
    raise OriginError(f"thiếu '{closer}' cho '{opener}' ở vị trí {tokens[index].start}")


# ---------------------------------------------------------------------------------------------
# Cấu trúc cấp ngoài cùng: struct, hàm, khai báo biến


@dataclass
class Item:
    kind: str
    first: int
    last: int
    body: tuple[int, int] | None = None
    name: str = ""


def classify_block(tokens: list[Token], first: int, brace: int) -> tuple[str, str]:
    head = tokens[first:brace]
    words = [token.text for token in head]
    if words and words[0] == "struct":
        return "struct", words[1] if len(words) > 1 else ""
    if words and words[0] in ("cbuffer", "tbuffer"):
        return "buffer", words[1] if len(words) > 1 else ""
    closers = [index for index, token in enumerate(head) if token.text == ")"]
    if not closers:
        raise OriginError(f"khối lạ ở cấp ngoài cùng: {' '.join(words[:8])}")
    opener = first + closers[-1]
    depth = 0
    for index in range(opener, first - 1, -1):
        depth += {")": 1, "(": -1}.get(tokens[index].text, 0)
        if depth == 0:
            name_index = index - 1
            break
    else:
        raise OriginError(f"hàm lạ: {' '.join(words[:8])}")
    return "function", tokens[name_index].text


def statement_kind(tokens: list[Token], first: int, last: int) -> str:
    # Câu kết thúc bằng ';' ở cấp ngoài cùng: khai báo hàm (prototype) khi '(' đến trước ':' và '='.
    for index in range(first, last):
        text = tokens[index].text
        if text in (":", "="):
            return "declaration"
        if text == "(":
            return "prototype"
    return "declaration"


def top_items(tokens: list[Token]) -> list[Item]:
    items = []
    index = 0
    while index < len(tokens):
        first = index
        parens = 0
        has_equals = False
        while index < len(tokens):
            text = tokens[index].text
            if text in ("(", "["):
                parens += 1
            elif text in (")", "]"):
                parens -= 1
            elif text == "=" and parens == 0:
                has_equals = True
            elif text == "{" and has_equals:
                index = matching(tokens, index)
            elif text == "{":
                close = matching(tokens, index)
                kind, name = classify_block(tokens, first, index)
                last = close + 1 if close + 1 < len(tokens) and tokens[close + 1].text == ";" else close
                items.append(Item(kind, first, last, (index, close), name))
                index = last + 1
                break
            elif text == ";" and parens == 0:
                items.append(Item(statement_kind(tokens, first, index), first, index))
                index += 1
                break
            index += 1
        else:
            if first < len(tokens):
                raise OriginError("hết tệp giữa một câu khai báo")
    return items


def split_commas(tokens: list[Token], first: int, last: int) -> list[tuple[int, int]]:
    # Các đoạn [đầu, cuối) ngăn bằng ',' ở độ sâu ngoặc 0.
    parts = []
    depth = 0
    start = first
    for index in range(first, last):
        text = tokens[index].text
        if text in ("(", "[", "{"):
            depth += 1
        elif text in (")", "]", "}"):
            depth -= 1
        elif text == "," and depth == 0:
            parts.append((start, index))
            start = index + 1
    if start < last:
        parts.append((start, last))
    return parts


@dataclass
class Declarator:
    # Một tham số hay một trường: chỉ số token đầu, tên, kiểu (chữ), ngữ nghĩa (chỉ số token) và
    # các từ bổ nghĩa (in, out, inout, uniform...).
    first: int
    name: str
    type_name: str
    modifiers: tuple[str, ...]
    semantic: int | None
    # Kích thước mảng như viết trong nguồn (có thể là macro), rỗng khi không phải mảng.
    array: str = ""


MODIFIERS = {"in", "out", "inout", "uniform", "const", "linear", "centroid", "nointerpolation",
             "noperspective", "sample", "precise", "row_major", "column_major", "static", "volatile"}


def declarator_of(tokens: list[Token], first: int, last: int) -> Declarator:
    index = first
    modifiers = []
    while index < last and tokens[index].text in MODIFIERS:
        modifiers.append(tokens[index].text)
        index += 1
    semantic = None
    end = last
    depth = 0
    for position in range(index, last):
        text = tokens[position].text
        if text in ("(", "[", "{"):
            depth += 1
        elif text in (")", "]", "}"):
            depth -= 1
        elif text in (":", "=") and depth == 0:
            end = position
            break
    if end < last and tokens[end].text == ":":
        semantic = end + 1
    brackets = [position for position in range(index, end) if tokens[position].text == "["]
    name_end = brackets[0] if brackets else end
    array = ""
    if brackets:
        close = matching(tokens, brackets[0])
        array = " ".join(token.text for token in tokens[brackets[0] + 1:close])
    names = [position for position in range(index, name_end) if tokens[position].kind == "word"]
    if len(names) < 2:
        raise OriginError(f"khai báo lạ: {' '.join(t.text for t in tokens[first:last])}")
    name_index = names[-1]
    type_name = " ".join(token.text for token in tokens[index:name_index])
    return Declarator(first, tokens[name_index].text, type_name, tuple(modifiers), semantic, array)


# ---------------------------------------------------------------------------------------------
# Biến đổi


@dataclass(frozen=True)
class Edit:
    start: int
    end: int
    text: str


def edit_order(edit: Edit) -> tuple[int, int, int]:
    # Cùng vị trí: chèn cả dòng (dòng #define sau khai báo sampler) đứng trước chèn trong dòng
    # ("uniform " trước khai báo đầu dòng kế tiếp); cùng loại thì giữ thứ tự danh sách.
    is_line = edit.start == edit.end and edit.text.endswith("\n")
    return edit.start, edit.end, 0 if is_line else 1


def apply_edits(text: str, edits: list[Edit]) -> str:
    ordered = sorted(edits, key=edit_order)
    pieces = []
    cursor = 0
    for edit in ordered:
        if edit.start < cursor:
            raise OriginError(f"hai biến đổi chồng nhau ở vị trí {edit.start}")
        pieces.append(text[cursor:edit.start])
        pieces.append(edit.text)
        cursor = edit.end
    pieces.append(text[cursor:])
    return "".join(pieces)


@dataclass(frozen=True)
class Patch:
    file: str
    old: str
    new: str
    reason: str


def unescape(text: str) -> str:
    return text.replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\")


def read_patches(path: Path) -> list[Patch]:
    if not path.is_file():
        return []
    patches = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cells = line.split("\t")
        if len(cells) != 4:
            raise OriginError(f"{PATCHES_NAME}:{number}: cần 4 cột, có {len(cells)}")
        patches.append(Patch(cells[0], unescape(cells[1]), unescape(cells[2]), cells[3]))
    return patches


def apply_patches(relative: str, text: str, patches: list[Patch]) -> str:
    for patch in patches:
        if patch.file != relative:
            continue
        # patches.tsv viết xuống dòng là \n; tệp gốc phần lớn dùng CRLF.
        newline = "\r\n" if "\r\n" in text else "\n"
        old = patch.old.replace("\n", newline)
        count = text.count(old)
        if count != 1:
            raise OriginError(f"{relative}: đoạn vá khớp {count} lần, cần đúng 1: {patch.old!r}")
        text = text.replace(old, patch.new.replace("\n", newline))
    return text


@dataclass(frozen=True)
class Initial:
    # Giá trị đầu của một biến toàn cục: vị trí khai báo trong tệp, tên, giá trị như viết.
    position: int
    name: str
    value: str


STORAGE_WORDS = {"uniform", "static", "const", "extern", "typedef", "struct", "groupshared"}


def needs_uniform(words: list[str]) -> bool:
    # fxc coi biến toàn cục không static là uniform; Slang cũng vậy nhưng báo E39019 khi thiếu từ
    # khoá, nên bộ sinh viết "uniform" ra (fxc dịch y hệt, oracle kiểm). Sampler đã thành macro.
    if STORAGE_WORDS & set(words):
        return False
    return not any(word.startswith(("sampler", "texture", "Texture")) for word in words)


def strip_initializers(text: str, lexed: Lexed) -> tuple[list[Edit], list[Initial]]:
    # Biến toàn cục không static có giá trị đầu: fxc ghi giá trị ấy làm mặc định của uniform,
    # Slang không nhận. Bỏ "= ..." khỏi nguồn, trả các giá trị đầu kèm vị trí khai báo để bảng tham
    # số chọn đúng bản khai mà define của từng gói bật.
    tokens = lexed.tokens
    edits = []
    defaults = []
    for item in top_items(tokens):
        if item.kind != "declaration":
            continue
        words = [token.text for token in tokens[item.first:item.last + 1]]
        if words[0] in ("typedef", "static", "struct") or "static" in words:
            continue
        if needs_uniform(words):
            first = tokens[item.first].start
            edits.append(Edit(first, first, "uniform "))
        equals = None
        depth = 0
        for index in range(item.first, item.last):
            text_here = tokens[index].text
            if text_here in ("(", "[", "{"):
                depth += 1
            elif text_here in (")", "]", "}"):
                depth -= 1
            elif text_here == "=" and depth == 0:
                equals = index
                break
        if equals is None:
            continue
        if len(split_commas(tokens, item.first, item.last)) > 1:
            raise OriginError(f"nhiều biến một dòng có giá trị đầu: {' '.join(words[:10])}")
        if "const" in words[:words.index("=")]:
            raise OriginError(f"const toàn cục không static chưa hỗ trợ: {' '.join(words[:10])}")
        value = text[tokens[equals + 1].start:tokens[item.last - 1].end]
        if "sampler_state" in value:
            raise OriginError(f"sampler_state chưa hỗ trợ: {' '.join(words[:10])}")
        declarator = declarator_of(tokens, item.first, equals)
        initial = Initial(tokens[item.first].start, declarator.name, " ".join(value.split()))
        defaults.append(initial)
        edits.append(Edit(tokens[equals - 1].end, tokens[item.last].start, ""))
    return edits, defaults


# Location của biến truyền giữa VS và PS theo ngữ nghĩa (luôn dưới 16, mức tối thiểu của Vulkan).
# Hai bảng dưới phải trùng bảng của semantic_location (engine/shader/reflection.cpp): engine tính
# location của chữ ký DXIL theo đó, lệch thì bước đối chiếu SPIR-V với DXIL báo lỗi khi dựng gói.
VARYING_LOCATIONS = {f"TEXCOORD{n}": n for n in range(11)} | {
    "COLOR0": 11, "COLOR1": 12, "FOG0": 13, "PSIZE0": 14, "NORMAL0": 15}
# Location của thuộc tính đỉnh theo ngữ nghĩa (dưới 16). Bảng phủ đúng các ngữ nghĩa kho dùng:
# TANGENT1 là tiếp tuyến lớp hai của địa hình; kho không dùng BINORMAL.
INPUT_LOCATIONS = {"POSITION0": 0, "BLENDWEIGHT0": 1, "BLENDINDICES0": 2, "NORMAL0": 3,
                   "COLOR0": 4, "COLOR1": 5, "TANGENT0": 14, "TANGENT1": 15} | {
    f"TEXCOORD{n}": 6 + n for n in range(8)}


def semantic_key(semantic: str) -> str:
    match = re.fullmatch(r"([A-Za-z_]+?)(\d*)", semantic)
    if match is None:
        raise OriginError(f"ngữ nghĩa lạ: {semantic}")
    return f"{match.group(1).upper()}{match.group(2) or '0'}"


@dataclass
class Role:
    # Vai của một struct trong các hàm vào: vs_in, vs_out, ps_in, ps_out.
    roles: set[str] = field(default_factory=set)
    users: set[str] = field(default_factory=set)


def legal_semantic(role: str, key: str) -> str | None:
    # Tên ngữ nghĩa thay theo luật của fxc ở chế độ tương thích; None là giữ nguyên.
    base = re.sub(r"\d+$", "", key)
    if role == "vs_out" and base == "POSITION":
        return "SV_Position"
    if role == "ps_in" and base in ("POSITION", "VPOS"):
        return "SV_Position"
    if role == "ps_out" and base == "COLOR":
        return f"SV_Target{key[len(base):]}"
    if role == "ps_out" and base == "DEPTH":
        return "SV_Depth"
    return None


def location_of(role: str, key: str) -> int | None:
    if role == "vs_in":
        if key not in INPUT_LOCATIONS:
            raise OriginError(f"thuộc tính đỉnh chưa có trong bảng Location: {key}")
        return INPUT_LOCATIONS[key]
    if role in ("vs_out", "ps_in"):
        if key not in VARYING_LOCATIONS:
            raise OriginError(f"biến truyền chưa có trong bảng Location: {key}")
        return VARYING_LOCATIONS[key]
    return None


# Slang coi [[vk::location]] trên trường struct là độ lệch so với gốc của struct, và gốc ấy tự cấp
# sau các location tường minh của tham số rời hay struct đứng trước (đo với slangc 2026.17: struct
# vào cùng tham số rời ở location 1 thì TEXCOORD0 ra location 2). Ghim gốc về 0 để location trên
# trường là tuyệt đối, đúng bảng. fxc không thấy thuộc tính này (oracle gỡ trước khi dịch).
PIN_LOCATION = "[[vk::location(0)]] "


def declarator_edits(tokens: list[Token], declarator: Declarator, role: str,
                     io_structs: set[str]) -> list[Edit]:
    if declarator.semantic is None and declarator.type_name in io_structs:
        first = tokens[declarator.first]
        return [Edit(first.start, first.start, PIN_LOCATION)]
    if declarator.semantic is None:
        return []
    token = tokens[declarator.semantic]
    if token.text.upper().startswith("SV_"):
        return []
    key = semantic_key(token.text)
    edits = []
    renamed = legal_semantic(role, key)
    if renamed is not None:
        edits.append(Edit(token.start, token.end, renamed))
        return edits
    location = location_of(role, key)
    if location is not None:
        first = tokens[declarator.first]
        edits.append(Edit(first.start, first.start, f"[[vk::location({location})]] "))
    return edits


@dataclass
class Unit:
    # Một tệp nguồn đã tách: văn bản sau vá, các token, các mục cấp ngoài cùng.
    relative: str
    text: str
    lexed: Lexed
    items: list[Item]


def struct_fields(unit: Unit, item: Item) -> list[Declarator]:
    tokens = unit.lexed.tokens
    first, close = item.body
    fields = []
    start = first + 1
    for index in range(first + 1, close):
        if tokens[index].text != ";":
            continue
        if index > start:
            if len(split_commas(tokens, start, index)) > 1:
                raise OriginError(f"{unit.relative}: trường nhiều biến trong struct {item.name}")
            fields.append(declarator_of(tokens, start, index))
        start = index + 1
    return fields


def list_opener(unit: Unit, item: Item, close: int) -> int:
    # Chỉ số token '(' khớp với ')' ở close.
    tokens = unit.lexed.tokens
    depth = 0
    for index in range(close, item.first - 1, -1):
        depth += {")": 1, "(": -1}.get(tokens[index].text, 0)
        if depth == 0:
            return index
    raise OriginError(f"{unit.relative}: danh sách tham số của {item.name} không đóng")


def param_ranges(unit: Unit, item: Item) -> tuple[list[tuple[int, int]], int]:
    # Đoạn token [đầu, cuối) của từng tham số và chỉ số token ')' đóng danh sách tham số.
    tokens = unit.lexed.tokens
    brace = item.body[0]
    closers = [index for index in range(item.first, brace) if tokens[index].text == ")"]
    close = closers[-1]
    opener = list_opener(unit, item, close)
    ranges = split_commas(tokens, opener + 1, close)
    is_void = len(ranges) == 1 and ranges[0][1] - ranges[0][0] == 1 and tokens[ranges[0][0]].text == "void"
    return ([] if is_void else ranges), close


def entry_params(unit: Unit, item: Item) -> tuple[list[Declarator], int | None]:
    # Tham số của hàm vào và ngữ nghĩa của giá trị trả về (chỉ số token, nếu có).
    tokens = unit.lexed.tokens
    ranges, close = param_ranges(unit, item)
    params = [declarator_of(tokens, first, last) for first, last in ranges]
    has_semantic = close + 2 < item.body[0] and tokens[close + 1].text == ":"
    return params, (close + 2 if has_semantic else None)


def include_names(unit: Unit) -> list[str]:
    names = []
    for directive in unit.lexed.directives:
        match = re.match(r'\s*#\s*include\s*[<"]([^">]+)[">]', directive.text)
        if match:
            names.append(match.group(1).replace("\\", "/"))
    return names


class Corpus:
    """Mọi tệp nguồn của MaterialTemplates sau vá, kèm tra include như OGRE và fxc."""

    def __init__(self, origin: Path, patches: list[Patch]):
        self.root = origin / TEMPLATES
        self.units: dict[str, Unit] = {}
        for path in sorted(self.root.rglob("*")):
            if path.suffix.lower() not in SHADER_SUFFIXES:
                continue
            relative = path.relative_to(self.root).as_posix()
            # Đọc byte rồi giải mã để giữ nguyên CRLF của bản gốc trong bản đã chuyển.
            original = path.read_bytes().decode("utf-8")
            text = apply_patches(relative, original, patches)
            lexed = lex(text)
            self.units[relative] = Unit(relative, text, lexed, top_items(lexed.tokens))
        known = {patch.file for patch in patches}
        missing = known - set(self.units)
        if missing:
            raise OriginError(f"{PATCHES_NAME} nêu tệp không có: {sorted(missing)}")

    def resolve(self, name: str, including: str) -> str | None:
        # Như fxc với trình include của OGRE: cạnh tệp đang include, rồi gốc MaterialTemplates, rồi
        # ShaderLib.
        here = Path(including).parent.as_posix()
        for base in (here, "", "ShaderLib"):
            candidate = f"{base}/{name}" if base and base != "." else name
            candidate = os.path.normpath(candidate).replace("\\", "/")
            if candidate in self.units:
                return candidate
        return None

    def closure(self, relative: str) -> list[str]:
        # Tệp nguồn và mọi tệp nó include (mọi nhánh #if), theo thứ tự gặp.
        order = []
        pending = [relative]
        while pending:
            current = pending.pop(0)
            if current in order:
                continue
            order.append(current)
            for name in include_names(self.units[current]):
                found = self.resolve(name, current)
                if found is None:
                    raise OriginError(f"{current}: không thấy tệp include {name}")
                pending.append(found)
        return order


def mark_struct(corpus: Corpus, files: list[str], type_name: str, role: str, user: str,
                roles: dict[tuple[str, int], Role]) -> None:
    for relative in files:
        unit = corpus.units[relative]
        for item in unit.items:
            if item.kind != "struct" or item.name != type_name:
                continue
            entry = roles.setdefault((relative, item.first), Role())
            entry.roles.add(role)
            entry.users.add(user)
            for declarator in struct_fields(unit, item):
                mark_struct(corpus, files, declarator.type_name, role, user, roles)


def find_entries(corpus: Corpus, program: Program) -> list[tuple[str, Item]]:
    # Mọi định nghĩa hàm vào trong tệp nguồn và tệp nó include (có thể nhiều bản trong các nhánh
    # #if khác nhau).
    found = []
    for relative in corpus.closure(program.source):
        unit = corpus.units[relative]
        found += [(relative, item) for item in unit.items
                  if item.kind == "function" and item.name == program.entry]
    if not found:
        raise OriginError(f"{program.name}: không thấy hàm vào {program.entry} trong {program.source}")
    return found


def program_roles(corpus: Corpus, program: Program, roles: dict, params: dict) -> None:
    files = corpus.closure(program.source)
    for relative, item in find_entries(corpus, program):
        unit = corpus.units[relative]
        declarators, returned = entry_params(unit, item)
        for declarator in declarators:
            if "uniform" in declarator.modifiers:
                continue
            is_output = "out" in declarator.modifiers or "inout" in declarator.modifiers
            role = f"{program.stage}_{'out' if is_output else 'in'}"
            key = (relative, declarator.first)
            params.setdefault(key, set()).add(role)
            mark_struct(corpus, files, declarator.type_name, role, program.name, roles)
        return_type = unit.lexed.tokens[item.first].text
        mark_struct(corpus, files, return_type, f"{program.stage}_out", program.name, roles)
        check_returned_struct(corpus, files, program, return_type, declarators)
        if returned is not None:
            params.setdefault((relative, -returned), set()).add(f"{program.stage}_out")


def is_struct(corpus: Corpus, files: list[str], type_name: str) -> bool:
    return any(item.kind == "struct" and item.name == type_name
               for relative in files for item in corpus.units[relative].items)


def check_returned_struct(corpus: Corpus, files: list[str], program: Program, return_type: str,
                          declarators: list[Declarator]) -> None:
    # Giá trị trả về không gắn được thuộc tính nên không ghim được gốc location (PIN_LOCATION): struct
    # trả về cùng biến ra rời thì Slang dời location các trường của struct.
    if not is_struct(corpus, files, return_type):
        return
    loose = [d.name for d in declarators
             if ("out" in d.modifiers or "inout" in d.modifiers) and d.semantic is not None]
    if loose:
        raise OriginError(f"{program.name}: struct {return_type} trả về cùng biến ra rời {loose}; "
                          "Slang sẽ dời location, cần vá nguồn")


def one_role(found: set[str], where: str) -> str:
    # vs_out và ps_in cùng một struct (VS_OUT dùng chung) là một vai: biến truyền.
    merged = {"varying" if role in ("vs_out", "ps_in") else role for role in found}
    if len(merged) != 1:
        raise OriginError(f"{where}: một khai báo mang nhiều vai {sorted(found)}")
    if "varying" in merged:
        return "ps_in" if found == {"ps_in"} else "vs_out"
    return merged.pop()


def legalize(corpus: Corpus, programs: list[Program]) -> dict[str, list[Edit]]:
    roles: dict[tuple[str, int], Role] = {}
    params: dict[tuple[str, int], set[str]] = {}
    for program in programs:
        program_roles(corpus, program, roles, params)
    edits: dict[str, list[Edit]] = {}
    io_structs = {item.name for (relative, first) in roles for item in corpus.units[relative].items
                  if item.first == first and item.kind == "struct"}
    for (relative, first), role in roles.items():
        unit = corpus.units[relative]
        item = next(item for item in unit.items if item.first == first and item.kind == "struct")
        chosen = one_role(role.roles, f"{relative}: struct {item.name}")
        for declarator in struct_fields(unit, item):
            edits.setdefault(relative, []).extend(
                declarator_edits(unit.lexed.tokens, declarator, chosen, io_structs))
    for (relative, first), found in params.items():
        unit = corpus.units[relative]
        tokens = unit.lexed.tokens
        chosen = one_role(found, f"{relative}: tham số ở vị trí {abs(first)}")
        if first < 0:
            token = tokens[-first]
            renamed = legal_semantic(chosen, semantic_key(token.text))
            if renamed is not None:
                edits.setdefault(relative, []).append(Edit(token.start, token.end, renamed))
            continue
        item = next(item for item in unit.items if item.kind == "function" and item.first < first < item.body[0])
        declarators, _ = entry_params(unit, item)
        declarator = next(d for d in declarators if d.first == first)
        edits.setdefault(relative, []).extend(
            declarator_edits(tokens, declarator, chosen, io_structs))
    return edits


# ---------------------------------------------------------------------------------------------
# Sampler D3D9
#
# sampler2D của D3D9 là một ô sN gồm cả ảnh lẫn cách lấy mẫu; ở shader model 5 fxc tách thành ảnh
# tN và sampler sN cùng số. Slang gán binding cho trường của struct theo thứ tự chứ không theo
# register, và bỏ register trên tham số của hàm vào, nên bộ sinh viết lại mọi khai báo sampler:
#   sampler2D X : register(sN);  ->  ORIGIN_SAMPLER2D(X, N);  #define X ORIGIN_USE2D(X)
# compat.slang đổi hai macro ấy thành Texture2D X_texture : register(tN) cùng SamplerState X_sampler
# : register(sN) và một giá trị OriginSampler2D dựng từ chúng; bản fxc của oracle đổi lại đúng
# dòng gốc. Sampler là tham số uniform của hàm vào thành khai báo cấp ngoài cùng cùng tên, đặt
# ngay trước hàm vào (entry_samplers).


# Kiểu sampler của bản gốc và loại ảnh trong compat.slang; sampler trần trong kho chỉ đi với tex2D.
SAMPLER_KINDS = {"sampler2D": "2D", "sampler": "2D", "samplerCUBE": "CUBE"}
ENTRY_GUARD = "ORIGIN_ENTRY_"


@dataclass(frozen=True)
class Sampler:
    name: str
    kind: str
    slot: int
    # Rỗng là khai toàn cục; còn lại là hàm vào có tham số này.
    entry: str = ""
    # Kích thước mảng như viết trong nguồn (có thể là macro); rỗng khi không phải mảng.
    count: str = ""
    # Bản gốc không ghi register: bộ sinh chọn ô như fxc, oracle kiểm lại.
    implicit: bool = False
    # Vị trí khai báo trong tệp, để biết define của gói có bật nó không.
    position: int = 0


def sampler_kind(declarator: Declarator) -> str | None:
    for word in declarator.type_name.split():
        if word in SAMPLER_KINDS:
            return SAMPLER_KINDS[word]
        if word.startswith("sampler") or word.startswith("texture"):
            raise OriginError(f"kiểu tài nguyên chưa hỗ trợ: {word} {declarator.name}")
    return None


def explicit_slot(tokens: list[Token], declarator: Declarator, where: str) -> int | None:
    index = declarator.semantic
    if index is None:
        return None
    words = [token.text for token in tokens[index:index + 4]]
    match = re.fullmatch(r"s(\d+)", words[2]) if len(words) == 4 else None
    if words[:2] != ["register", "("] or words[3:] != [")"] or match is None:
        raise OriginError(f"{where}: sampler {declarator.name} có ngữ nghĩa lạ, cần register(sN)")
    return int(match.group(1))


def declaration_text(sampler: Sampler) -> str:
    if sampler.count:
        return f"ORIGIN_SAMPLER{sampler.kind}_ARRAY({sampler.name}, {sampler.slot}, {sampler.count})"
    return f"ORIGIN_SAMPLER{sampler.kind}({sampler.name}, {sampler.slot})"


def use_line(sampler: Sampler) -> str:
    return f"#define {sampler.name} ORIGIN_USE{sampler.kind}({sampler.name})\n"


def after_line(text: str, position: int) -> tuple[int, str]:
    # Vị trí đầu dòng kế tiếp sau position, và tiền tố xuống dòng nếu tệp hết mà không có '\n'.
    newline = text.find("\n", position)
    return (len(text), "\n") if newline < 0 else (newline + 1, "")


def global_samplers(unit: Unit) -> tuple[list[Edit], list[Sampler]]:
    tokens = unit.lexed.tokens
    edits = []
    found = []
    for item in unit.items:
        if item.kind != "declaration" or tokens[item.first].text in ("typedef", "static"):
            continue
        declarator = declarator_of(tokens, item.first, item.last)
        kind = sampler_kind(declarator)
        if kind is None:
            continue
        slot = explicit_slot(tokens, declarator, unit.relative)
        if slot is None or declarator.array:
            raise OriginError(f"{unit.relative}: sampler toàn cục {declarator.name} cần register(sN)")
        position = tokens[item.first].start
        sampler = Sampler(declarator.name, kind, slot, position=position)
        found.append(sampler)
        replaced = Edit(tokens[item.first].start, tokens[item.last - 1].end, declaration_text(sampler))
        edits.append(replaced)
        position, prefix = after_line(unit.text, tokens[item.last].end)
        edits.append(Edit(position, position, prefix + use_line(sampler)))
    return edits, found


def removal_edits(tokens: list[Token], ranges: list[tuple[int, int]], removed: set[int]) -> list[Edit]:
    # Xoá token của các tham số đã chọn và dấu phẩy đi kèm. Chỉ xoá token: giữa hai tham số có thể
    # là dòng #if hay #endif (danh sách tham số của địa hình), phải còn nguyên.
    edits = []
    kept = [index for index in range(len(ranges)) if index not in removed]
    last_kept = kept[-1] if kept else -1
    for index in sorted(removed):
        first, last = ranges[index]
        edits.append(Edit(tokens[first].start, tokens[last - 1].end, ""))
        # Dấu phẩy sau tham số; tham số cuối cùng không có.
        if index + 1 < len(ranges):
            comma = tokens[last]
            edits.append(Edit(comma.start, comma.end, ""))
    has_tail = any(index > last_kept for index in removed)
    if has_tail and last_kept >= 0:
        comma = tokens[ranges[last_kept][1]]
        edits.append(Edit(comma.start, comma.end, ""))
    return edits


def entry_guard(entry: str) -> str:
    # Macro gói bật cho đúng hàm vào của nó (define= trong danh sách gói, và khi oracle dịch).
    return f"{ENTRY_GUARD}{entry}"


def slot_span(declarator: Declarator) -> int | None:
    # Số ô một sampler chiếm; None khi kích thước mảng là macro.
    if not declarator.array:
        return 1
    return int(declarator.array) if declarator.array.isdigit() else None


def assign_slots(declared: list, taken: set[int], where: str) -> list[Sampler]:
    # Sampler không ghi register nhận ô trống thấp nhất theo thứ tự khai, sau các ô đã ghi. Mảng
    # có kích thước là macro chỉ được đứng cuối và không có ô ghi tường minh nào phía trên nó.
    assigned = []
    cursor = 0
    unknown_at = None
    for declarator, kind, slot, entry, position in declared:
        if slot is not None:
            sampler = Sampler(declarator.name, kind, slot, entry, declarator.array, False, position)
            assigned.append(sampler)
            continue
        if unknown_at is not None:
            raise OriginError(f"{where}: không xác định được ô của sampler {declarator.name}")
        while cursor in taken:
            cursor += 1
        sampler = Sampler(declarator.name, kind, cursor, entry, declarator.array, True, position)
        assigned.append(sampler)
        span = slot_span(declarator)
        if span is None:
            unknown_at = cursor
            continue
        taken.update(range(cursor, cursor + span))
    if unknown_at is not None and any(slot > unknown_at for slot in taken):
        raise OriginError(f"{where}: mảng sampler kích thước macro đè lên ô đã ghi")
    return assigned


def unique_samplers(samplers: list[Sampler], where: str) -> list[Sampler]:
    # Một khai báo cho mỗi tên; hai bản khai cùng tên (hai nhánh #if) phải cùng ô và cùng loại.
    found: dict[str, Sampler] = {}
    for sampler in samplers:
        known = found.setdefault(sampler.name, sampler)
        if (known.kind, known.slot, known.count) != (sampler.kind, sampler.slot, sampler.count):
            raise OriginError(f"{where}: khai sampler {sampler.name} hai thanh ghi")
    return list(found.values())


def param_samplers(unit: Unit, item: Item, entry: str,
                   taken: set[int]) -> tuple[set[int], list[Sampler]]:
    tokens = unit.lexed.tokens
    ranges, _ = param_ranges(unit, item)
    where = f"{unit.relative}: {entry}"
    removed = set()
    declared = []
    taken = set(taken)
    for index, (first, last) in enumerate(ranges):
        declarator = declarator_of(tokens, first, last)
        kind = sampler_kind(declarator)
        if kind is None:
            continue
        if "uniform" not in declarator.modifiers:
            raise OriginError(f"{where}: sampler {declarator.name} thiếu uniform")
        slot = explicit_slot(tokens, declarator, where)
        if slot is not None:
            taken.update(range(slot, slot + (slot_span(declarator) or 1)))
        declared.append((declarator, kind, slot, entry, tokens[first].start))
        removed.add(index)
    assigned = assign_slots(declared, taken, where)
    unique_samplers(assigned, where)
    return removed, assigned


def index_edits(unit: Unit, item: Item, sampler: Sampler) -> list[Edit]:
    # Chỗ dùng mảng sampler trong thân hàm: X[i] thành ORIGIN_INDEX2D(X, i).
    tokens = unit.lexed.tokens
    first, close = item.body
    edits = []
    for index in range(first + 1, close):
        token = tokens[index]
        if token.text != sampler.name or tokens[index - 1].text == ".":
            continue
        if tokens[index + 1].text != "[":
            raise OriginError(f"{unit.relative}: mảng sampler {sampler.name} dùng không qua chỉ số")
        bracket = matching(tokens, index + 1)
        inner = unit.text[tokens[index + 2].start:tokens[bracket - 1].end]
        text = f"ORIGIN_INDEX{sampler.kind}({sampler.name}, {inner})"
        edits.append(Edit(token.start, tokens[bracket].end, text))
    return edits


@dataclass
class Region:
    # Danh sách tham số (giữa '(' và ')') của một hàm vào có tham số uniform số, cần hai bản trong
    # #ifdef __SLANG__: fxc giữ các tham số ấy (chúng nằm trong $Params như bản gốc, oracle so được
    # từng byte), Slang bỏ chúng vì đã khai ở cấp ngoài cùng ngay trước hàm. Slang đặt tham số
    # uniform của hàm vào thành khối entryPointParams, khác loại giữa SPIR-V và DXIL.
    start: int
    end: int
    fxc_edits: list[Edit]
    slang_edits: list[Edit]


@dataclass
class EntryPlan:
    edits: list[Edit] = field(default_factory=list)
    samplers: list[Sampler] = field(default_factory=list)
    region: Region | None = None
    # Giá trị đầu của tham số uniform số (fxc ghi chúng làm mặc định trong $Params).
    initials: list[Initial] = field(default_factory=list)


def numeric_uniforms(tokens: list[Token], ranges: list[tuple[int, int]]) -> set[int]:
    found = set()
    for index, (first, last) in enumerate(ranges):
        declarator = declarator_of(tokens, first, last)
        if "uniform" in declarator.modifiers and sampler_kind(declarator) is None:
            found.add(index)
    return found


def first_mark(tokens: list[Token], first: int, last: int, marks: tuple[str, ...]) -> int | None:
    # Token đầu tiên trong marks ở độ sâu ngoặc 0 của đoạn [first, last).
    depth = 0
    for index in range(first, last):
        text = tokens[index].text
        if text in ("(", "[", "{"):
            depth += 1
        elif text in (")", "]", "}"):
            depth -= 1
        elif depth == 0 and text in marks:
            return index
    return None


def uniform_block(unit: Unit, ranges: list[tuple[int, int]], numeric: set[int],
                  bounds: tuple[int, int]) -> tuple[str, list[Initial]]:
    # Bản sao của danh sách tham số chỉ còn các tham số uniform số, mỗi cái thành một khai báo cấp
    # ngoài cùng ("uniform float4 x;"): dòng #if giữa các tham số còn nguyên nên khai báo nằm đúng
    # nhánh của tham số; ngữ nghĩa register(cN) và giá trị đầu bị cắt (giá trị đầu vào bảng).
    tokens = unit.lexed.tokens
    edits = []
    initials = []
    for index, (first, last) in enumerate(ranges):
        if index + 1 < len(ranges):
            comma = tokens[last]
            edits.append(Edit(comma.start, comma.end, ""))
        if index not in numeric:
            edits.append(Edit(tokens[first].start, tokens[last - 1].end, ""))
            continue
        declarator = declarator_of(tokens, first, last)
        equals = first_mark(tokens, first, last, ("=",))
        if equals is not None:
            value = unit.text[tokens[equals + 1].start:tokens[last - 1].end]
            initials.append(Initial(tokens[first].start, declarator.name, " ".join(value.split())))
        cut = first_mark(tokens, first, last, (":", "="))
        cut_from = tokens[cut - 1].end if cut is not None else tokens[last - 1].end
        edits.append(Edit(cut_from, tokens[last - 1].end, ";"))
    start, end = bounds
    shifted = [Edit(edit.start - start, edit.end - start, edit.text) for edit in edits]
    return apply_edits(unit.text[start:end], shifted), initials


def entry_plan(unit: Unit, item: Item, entry: str, taken: set[int]) -> EntryPlan:
    # Sampler tham số của hàm vào thành khai báo ngay trước hàm, trong #ifdef của riêng hàm vào ấy
    # (hai hàm vào cùng tệp có thể dùng cùng tên ở hai ô khác nhau, như inLum của hdr.hlsl), và
    # #undef ngay sau hàm để macro tên không lan sang hàm khác có tham số trùng tên. Tham số uniform
    # số đi theo Region.
    removed, found = param_samplers(unit, item, entry, taken)
    tokens = unit.lexed.tokens
    ranges, close = param_ranges(unit, item)
    numeric = numeric_uniforms(tokens, ranges)
    if not found and not numeric:
        return EntryPlan()
    start = tokens[item.first].start
    line_start = unit.text.rfind("\n", 0, start) + 1
    if unit.text[line_start:start].strip():
        raise OriginError(f"{unit.relative}: hàm vào {entry} không bắt đầu ở đầu dòng")
    plan = EntryPlan(samplers=found)
    declarations = []
    undefines = []
    for sampler in unique_samplers(found, f"{unit.relative}: {entry}"):
        declarations.append(f"{declaration_text(sampler)};\n")
        if sampler.count:
            plan.edits += index_edits(unit, item, sampler)
            continue
        declarations.append(use_line(sampler))
        undefines.append(f"#undef {sampler.name}\n")
    if numeric:
        bounds = (tokens[list_opener(unit, item, close)].end, tokens[close].start)
        block, plan.initials = uniform_block(unit, ranges, numeric, bounds)
        declarations.append(f"#ifdef __SLANG__\n{block}\n#endif\n")
        fxc_edits = removal_edits(tokens, ranges, removed)
        slang_edits = removal_edits(tokens, ranges, removed | numeric)
        plan.region = Region(bounds[0], bounds[1], fxc_edits, slang_edits)
    else:
        plan.edits += removal_edits(tokens, ranges, removed)
    head = f"#ifdef {entry_guard(entry)}\n{''.join(declarations)}"
    plan.edits.append(Edit(line_start, line_start, head))
    position, prefix = after_line(unit.text, tokens[item.last].end)
    plan.edits.append(Edit(position, position, f"{prefix}{''.join(undefines)}#endif\n"))
    return plan


@dataclass
class EntryEdits:
    edits: dict[str, list[Edit]]
    samplers: dict[str, list[Sampler]]
    regions: dict[str, list[Region]]
    initials: dict[str, list[Initial]]


def entry_edits(corpus: Corpus, programs: list[Program]) -> EntryEdits:
    result = EntryEdits({}, {}, {}, {})
    for relative, unit in corpus.units.items():
        result.edits[relative], result.samplers[relative] = global_samplers(unit)
        result.regions[relative] = []
        result.initials[relative] = []
    entries = {}
    for program in programs:
        for relative, item in find_entries(corpus, program):
            entries[(relative, item.first)] = (relative, item, program.entry)
    for relative, item, entry in entries.values():
        unit = corpus.units[relative]
        global_names = {sampler.name for sampler in result.samplers[relative] if not sampler.entry}
        global_slots = {sampler.slot for sampler in result.samplers[relative] if not sampler.entry}
        plan = entry_plan(unit, item, entry, global_slots)
        clashes = sorted(global_names & {sampler.name for sampler in plan.samplers})
        if clashes:
            raise OriginError(f"{relative}: sampler của {entry} trùng tên sampler toàn cục: {clashes}")
        result.edits[relative] += plan.edits
        result.samplers[relative] += plan.samplers
        result.initials[relative] += plan.initials
        if plan.region is not None:
            result.regions[relative].append(plan.region)
    return result


def region_text(text: str, region: Region, edits: list[Edit]) -> str:
    shifted = [Edit(edit.start - region.start, edit.end - region.start, edit.text) for edit in edits]
    return apply_edits(text[region.start:region.end], shifted)


def compose_regions(text: str, edits: list[Edit], regions: list[Region]) -> list[Edit]:
    # Thay mỗi Region bằng hai bản của nó; biến đổi khác nằm trong Region (ngữ nghĩa, Location) áp
    # cho cả hai bản.
    remaining = list(edits)
    for region in regions:
        inside = [edit for edit in remaining if region.start <= edit.start and edit.end <= region.end]
        crossing = [edit for edit in remaining if edit.start < region.end and edit.end > region.start
                    and edit not in inside]
        if crossing:
            raise OriginError(f"biến đổi cắt ngang danh sách tham số ở vị trí {region.start}")
        remaining = [edit for edit in remaining if edit not in inside]
        fxc = region_text(text, region, inside + region.fxc_edits)
        slang = region_text(text, region, inside + region.slang_edits)
        composed = f"\n#ifdef __SLANG__\n{slang}\n#else\n{fxc}\n#endif\n"
        remaining.append(Edit(region.start, region.end, composed))
    return remaining


# ---------------------------------------------------------------------------------------------
# Điều kiện tiền xử lý
#
# Bảng tham số phải đúng từng gói: giá trị đầu và sampler nằm trong nhánh #if nào chỉ thuộc gói
# bật nhánh ấy (outlineColor của Model_ps.hlsl và của ShaderLib/ParamNamed.inc là hai bản ở hai
# nhánh, khác giá trị). Preprocessor chạy các chỉ thị như bộ tiền xử lý C với define của gói:
# #define và #undef dạng đối tượng, #if #ifdef #ifndef #elif #else #endif, #include theo
# Corpus.resolve, #pragma once. oracle đối chiếu kết quả với RDEF của bản dịch gốc.


CONDITION_TOKEN = re.compile(
    r"\s*(?:(\d+)[uUlL]*|([A-Za-z_]\w*)|(&&|\|\||==|!=|<=|>=|<<|>>|[-+*/%<>!~&|^()?:]))")
BINARY_LEVELS = (("||",), ("&&",), ("|",), ("^",), ("&",), ("==", "!="), ("<", "<=", ">", ">="),
                 ("<<", ">>"), ("+", "-"), ("*", "/", "%"))


def c_divide(left: int, right: int, remainder: bool) -> int:
    if right == 0:
        raise OriginError("chia cho 0 trong biểu thức #if")
    quotient = abs(left) // abs(right)
    if (left < 0) != (right < 0):
        quotient = -quotient
    return left - quotient * right if remainder else quotient


def binary_value(operator: str, left: int, right: int) -> int:
    simple = {
        "||": lambda: int(bool(left) or bool(right)), "&&": lambda: int(bool(left) and bool(right)),
        "|": lambda: left | right, "^": lambda: left ^ right, "&": lambda: left & right,
        "==": lambda: int(left == right), "!=": lambda: int(left != right),
        "<": lambda: int(left < right), "<=": lambda: int(left <= right),
        ">": lambda: int(left > right), ">=": lambda: int(left >= right),
        "<<": lambda: left << right, ">>": lambda: left >> right,
        "+": lambda: left + right, "-": lambda: left - right, "*": lambda: left * right,
        "/": lambda: c_divide(left, right, False), "%": lambda: c_divide(left, right, True),
    }
    return simple[operator]()


class Condition:
    """Biểu thức của #if đã thay macro, tính theo số nguyên và thứ tự ưu tiên của C."""

    def __init__(self, tokens: list[str], text: str):
        self.tokens = tokens
        self.text = text
        self.index = 0

    def peek(self) -> str:
        return self.tokens[self.index] if self.index < len(self.tokens) else ""

    def take(self) -> str:
        token = self.peek()
        self.index += 1
        return token

    def fail(self) -> OriginError:
        return OriginError(f"biểu thức #if không tính được: {self.text.strip()}")

    def value(self) -> int:
        result = self.ternary()
        if self.index != len(self.tokens):
            raise self.fail()
        return result

    def ternary(self) -> int:
        condition = self.binary(0)
        if self.peek() != "?":
            return condition
        self.take()
        when_true = self.ternary()
        if self.take() != ":":
            raise self.fail()
        when_false = self.ternary()
        return when_true if condition else when_false

    def binary(self, level: int) -> int:
        if level == len(BINARY_LEVELS):
            return self.unary()
        result = self.binary(level + 1)
        while self.peek() in BINARY_LEVELS[level]:
            operator = self.take()
            right = self.binary(level + 1)
            result = binary_value(operator, result, right)
        return result

    def unary(self) -> int:
        token = self.take()
        if token == "!":
            return int(not self.unary())
        if token == "-":
            return -self.unary()
        if token == "+":
            return self.unary()
        if token == "~":
            return ~self.unary()
        if token.isdigit():
            return int(token)
        if token != "(":
            raise self.fail()
        result = self.ternary()
        if self.take() != ")":
            raise self.fail()
        return result


def directive_parts(text: str) -> tuple[str, str]:
    # Tên chỉ thị và phần còn lại, đã nối dòng '\' và bỏ chú thích.
    joined = re.sub(r"\\\r?\n", " ", text)
    clean = COMMENT.sub(" ", joined).strip()
    match = re.match(r"#\s*(\w*)\s*(.*)", clean, re.S)
    return (match.group(1), match.group(2).strip()) if match else ("", "")


@dataclass
class Activity:
    """Nhánh nào bật cho một gói: mỗi lần một tệp được include là một dãy mốc (vị trí, bật)."""

    marks: dict[str, list[list[tuple[int, bool]]]] = field(default_factory=dict)

    def active(self, relative: str, position: int) -> bool:
        for marks in self.marks.get(relative, []):
            state = False
            for at, on in marks:
                if at > position:
                    break
                state = on
            if state:
                return True
        return False


class Preprocessor:
    def __init__(self, corpus: Corpus, defines: tuple[str, ...]):
        self.corpus = corpus
        # Thân macro dạng đối tượng; None là macro dạng hàm (không dùng được trong #if).
        self.macros: dict[str, str | None] = {}
        for define in defines:
            name, _, value = define.partition("=")
            self.macros[name] = value
        self.activity = Activity()
        self.once: set[str] = set()
        self.depth = 0

    def expand(self, text: str, seen: frozenset[str]) -> list[str]:
        tokens = []
        position = 0
        words = []
        while position < len(text):
            match = CONDITION_TOKEN.match(text, position)
            if match is None:
                if text[position:].strip():
                    raise OriginError(f"biểu thức #if có ký tự lạ: {text.strip()}")
                break
            position = match.end()
            words.append(match.group(1) or match.group(2) or match.group(3))
        index = 0
        while index < len(words):
            word = words[index]
            index += 1
            if word == "defined":
                has_paren = index < len(words) and words[index] == "("
                name = words[index + 1] if has_paren else words[index]
                index += 3 if has_paren else 1
                tokens.append("1" if name in self.macros else "0")
                continue
            if not (word[0].isalpha() or word[0] == "_"):
                tokens.append(word)
                continue
            tokens += self.identifier(word, seen)
        return tokens

    def identifier(self, word: str, seen: frozenset[str]) -> list[str]:
        # Macro dạng đối tượng thì thay bằng thân (đệ quy), tên lạ là 0 như bộ tiền xử lý C.
        if word not in self.macros or word in seen:
            return ["0"]
        body = self.macros[word]
        if body is None:
            raise OriginError(f"macro dạng hàm {word} trong #if chưa hỗ trợ")
        return self.expand(body, seen | {word}) if body.strip() else ["0"]

    def test(self, kind: str, rest: str) -> bool:
        if kind == "ifdef":
            return rest.split()[0] in self.macros
        if kind == "ifndef":
            return rest.split()[0] not in self.macros
        tokens = self.expand(rest, frozenset())
        return Condition(tokens, rest).value() != 0

    def define(self, rest: str) -> None:
        match = re.match(r"([A-Za-z_]\w*)(\()?\s*(.*)", rest, re.S)
        if match is None:
            raise OriginError(f"#define lạ: {rest}")
        self.macros[match.group(1)] = None if match.group(2) else match.group(3).strip()

    def include(self, rest: str, relative: str) -> None:
        match = re.match(r'[<"]([^">]+)[">]', rest)
        name = match.group(1).replace("\\", "/") if match else ""
        found = self.corpus.resolve(name, relative)
        if found is None:
            raise OriginError(f"{relative}: không thấy tệp include {name}")
        self.run(found)

    def apply(self, kind: str, rest: str, relative: str) -> None:
        if kind == "define":
            self.define(rest)
        elif kind == "undef":
            self.macros.pop(rest.split()[0], None)
        elif kind == "include":
            self.include(rest, relative)
        elif kind == "pragma" and rest.split()[:1] == ["once"]:
            self.once.add(relative)

    def run(self, relative: str) -> None:
        if relative in self.once:
            return
        self.depth += 1
        if self.depth > 32:
            raise OriginError(f"{relative}: include lồng quá sâu")
        marks = [(0, True)]
        self.activity.marks.setdefault(relative, []).append(marks)
        stack: list[list[bool]] = []
        active = True
        for directive in self.corpus.units[relative].lexed.directives:
            kind, rest = directive_parts(directive.text)
            active = self.step(stack, active, kind, rest, relative)
            marks.append((directive.end, active))
        if stack:
            raise OriginError(f"{relative}: thiếu #endif")
        self.depth -= 1

    def step(self, stack: list[list[bool]], active: bool, kind: str, rest: str,
             relative: str) -> bool:
        # Một chỉ thị; trả trạng thái bật sau nó. Mỗi phần tử stack: [cha bật, đã có nhánh bật].
        if kind in ("if", "ifdef", "ifndef"):
            on = active and self.test(kind, rest)
            stack.append([active, on])
            return on
        if kind in ("elif", "else", "endif") and not stack:
            raise OriginError(f"{relative}: #{kind} không có #if")
        if kind == "elif":
            parent, taken = stack[-1]
            on = parent and not taken and self.test("if", rest)
            stack[-1][1] = taken or on
            return on
        if kind == "else":
            parent, taken = stack[-1]
            stack[-1][1] = True
            return parent and not taken
        if kind == "endif":
            return stack.pop()[0]
        if active:
            self.apply(kind, rest, relative)
        return active


def activity_of(corpus: Corpus, program: Program) -> Activity:
    preprocessor = Preprocessor(corpus, program.defines)
    preprocessor.run(program.source)
    return preprocessor.activity


# ---------------------------------------------------------------------------------------------
# Sinh danh sách gói và bảng tham số (generate)


def generate(origin: Path, output: Path) -> int:
    patches = read_patches(origin / PATCHES_NAME)
    corpus = Corpus(origin, patches)
    programs = read_programs(origin)
    for program in programs:
        if program.source not in corpus.units:
            raise OriginError(f"{program.name}: không có nguồn {program.source}")
    io_edits = legalize(corpus, programs)
    planned = entry_edits(corpus, programs)
    initials = {}
    for relative, unit in corpus.units.items():
        global_edits, found = strip_initializers(unit.text, unit.lexed)
        initials[relative] = found + planned.initials[relative]
        edits = global_edits + io_edits.get(relative, []) + planned.edits[relative]
        edits = compose_regions(unit.text, edits, planned.regions[relative])
        text = apply_edits(unit.text, edits)
        write_if_changed(output / "src" / relative, text)
    compat = (origin / COMPAT_NAME).read_text(encoding="utf-8")
    write_if_changed(output / COMPAT_NAME, compat)
    list_lines = [
        "# Sinh bởi TOOLS/port/hlsl_origin.py generate từ src/client/render/shaders/origin. Không sửa tay.",
        "include src",
        "include src/ShaderLib",
        "include .",
        # Location vào ra theo semantic (bảng của semantic_location trong engine/shader/reflection.hpp,
        # chép y hệt VARYING_LOCATIONS và INPUT_LOCATIONS ở đây).
        "locations semantic",
    ]
    sources = sorted({program.source for program in programs})
    for source in sources:
        wrapper = (f"// Sinh bởi TOOLS/port/hlsl_origin.py: lớp tương thích rồi tới nguồn gốc đã chuyển.\n"
                   f'#include "{COMPAT_NAME}"\n#include "{source}"\n')
        write_if_changed(output / "wrap" / f"{source}.slang", wrapper)
    names = set()
    for program in programs:
        name = package_name(program)
        if name in names:
            raise OriginError(f"hai chương trình cùng tên gói {name}")
        names.add(name)
        options = [f"stage={program.stage}", f"entry={program.entry}"]
        # column_major_matrices false: OGRE dịch với gói ma trận theo hàng (khớp ShaderCache).
        if program.column_major == "false":
            options.append("matrix=row")
        options += [f"define={define}" for define in built_defines(program)]
        list_lines.append(" ".join(["shader", name, f"wrap/{program.source}.slang", *options]))
    write_if_changed(output / LIST_NAME, "\n".join(list_lines) + "\n")
    table = params_table(corpus, programs, initials, planned.samplers)
    write_if_changed(output / PARAMS_NAME, table)
    print(f"origin: {len(programs)} chương trình, {len(sources)} tệp nguồn, {len(corpus.units)} tệp đã chuyển")
    return 0


def built_defines(program: Program) -> tuple[str, ...]:
    # Define của .program cộng macro bật hàm vào của gói (entry_samplers).
    return (*program.defines, f"{entry_guard(program.entry)}=1")


def params_table(corpus: Corpus, programs: list[Program], initials: dict[str, list[Initial]],
                 samplers: dict[str, list[Sampler]]) -> str:
    # Mỗi dòng: gói, loại, tên, giá trị. Loại: meta (thông tin chương trình), param_named và
    # param_named_auto (default_params của .program), default (giá trị đầu trong nguồn), sampler
    # (ô sN gốc kèm loại ảnh). default và sampler chỉ gồm bản khai mà define của gói bật; được
    # dùng hay không do bản dịch quyết định (biến không dùng bị bỏ khỏi gói).
    rows = ["\t".join(("gói", "loại", "tên", "giá_trị"))]
    for program in programs:
        rows += program_rows(corpus, program, initials, samplers)
    return "\n".join(rows) + "\n"


def program_rows(corpus: Corpus, program: Program, initials: dict[str, list[Initial]],
                 samplers: dict[str, list[Sampler]]) -> list[str]:
    name = package_name(program)
    rows = [
        "\t".join((name, "meta", "source", program.source)),
        "\t".join((name, "meta", "target", program.target)),
        "\t".join((name, "meta", "column_major_matrices", program.column_major)),
        "\t".join((name, "meta", "declared_in", program.declared_in)),
    ]
    rows += ["\t".join((name, param.kind, param.name, param.value)) for param in program.params]
    activity = activity_of(corpus, program)
    values: dict[str, str] = {}
    slots: dict[str, Sampler] = {}
    for relative in corpus.closure(program.source):
        for initial in initials[relative]:
            if not activity.active(relative, initial.position):
                continue
            if values.setdefault(initial.name, initial.value) != initial.value:
                raise OriginError(f"{program.name}: {initial.name} có hai giá trị đầu cùng bật")
        for sampler in samplers[relative]:
            is_mine = sampler.entry in ("", program.entry)
            if is_mine and activity.active(relative, sampler.position):
                slots.setdefault(sampler.name, sampler)
    rows += ["\t".join((name, "default", key, value)) for key, value in sorted(values.items())]
    for sampler in sorted(slots.values(), key=lambda item: item.slot):
        value = f"s{sampler.slot} {sampler.kind}" + (f"[{sampler.count}]" if sampler.count else "")
        rows.append("\t".join((name, "sampler", sampler.name, value)))
    return rows


def write_if_changed(path: Path, text: str) -> None:
    # Ghi khi nội dung đổi, để bước dựng sau (băm nội dung) và CMake không thấy tệp mới vô cớ.
    data = text.encode("utf-8")
    if path.is_file() and path.read_bytes() == data:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


# ---------------------------------------------------------------------------------------------
# Đối chứng bằng trình dịch gốc (oracle)


def oracle(origin: Path, generated: Path, fxc_path: Path, cache: Path | None) -> int:
    import hlsl_oracle

    compiler = hlsl_oracle.Fxc(fxc_path)
    programs = read_programs(origin)
    source_root = origin / TEMPLATES
    built_root = generated / "src"
    defaults = read_defaults(generated / PARAMS_NAME)
    cache_index = hlsl_oracle.cache_index(cache) if cache else {}
    failures = 0
    matched_cache = set()
    for program in programs:
        program_defaults = defaults.get(package_name(program), {})
        report = hlsl_oracle.compare(compiler, program, source_root, built_root, program_defaults,
                                     built_defines(program))
        if report.original_hash in cache_index:
            matched_cache.add(cache_index[report.original_hash])
        if report.problems:
            failures += 1
            print(f"KHÁC {program.name}: " + "; ".join(report.problems))
    print(f"oracle: {len(programs) - failures}/{len(programs)} chương trình cùng mã máy với bản gốc")
    if cache_index:
        print(f"oracle: {len(matched_cache)}/{len(set(cache_index.values()))} nội dung ShaderCache khớp từng byte")
    return 1 if failures else 0


def read_defaults(path: Path) -> dict[str, dict[str, str]]:
    table: dict[str, dict[str, str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        cells = line.split("\t")
        if len(cells) == 4 and cells[1] == "default":
            table.setdefault(cells[0], {})[cells[2]] = cells[3]
    return table


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Chuyển shader HLSL của client gốc sang gói của engine.")
    commands = parser.add_subparsers(dest="command", required=True)
    vendor_args = commands.add_parser("vendor")
    vendor_args.add_argument("raw", type=Path)
    vendor_args.add_argument("origin", type=Path)
    generate_args = commands.add_parser("generate")
    generate_args.add_argument("origin", type=Path)
    generate_args.add_argument("output", type=Path)
    oracle_args = commands.add_parser("oracle")
    oracle_args.add_argument("origin", type=Path)
    oracle_args.add_argument("generated", type=Path)
    oracle_args.add_argument("--fxc", type=Path, required=True)
    oracle_args.add_argument("--cache", type=Path)
    args = parser.parse_args(argv)
    try:
        if args.command == "vendor":
            return vendor(args.raw, args.origin)
        if args.command == "generate":
            return generate(args.origin, args.output)
        return oracle(args.origin, args.generated, args.fxc, args.cache)
    except OriginError as error:
        print(f"origin: lỗi: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
