# Đọc script material của OGRE trong kho gốc (Material/all.material và các mẫu ở MaterialTemplates)
# rồi dựng material hiệu dụng sau kế thừa, để nơi ghi GLB lấy texture nền và các thiết lập của pass.
# Nguồn quy tắc: MaterialSerializer của OGRE 1.x (material con chép material cha rồi trộn technique,
# pass, texture_unit theo tên hoặc theo thứ tự; set_texture_alias thay texture của unit có alias đó).
# Quyết định:
# - Làm việc trên bytes: tên material trong .mesh là GBK và tệp script có dòng không giải mã được,
#   nên tên được so khớp theo byte, chỉ giải mã khi đưa ra ngoài.
# - Dấu ngoặc của mọi script trong kho luôn đứng riêng một dòng (đã đo), bộ tách dòng dựa vào đó.
# - Tên định nghĩa hai lần: giữ định nghĩa đầu (OGRE từ chối tạo resource trùng tên), có đếm.

import copy
from dataclasses import dataclass, field

NAMED_BLOCKS = (b"technique", b"pass", b"texture_unit")
# Các dòng cùng từ khoá nhưng khác tham số đầu là các mục riêng, không ghi đè nhau.
KEYED_LINES = (b"param_named", b"param_named_auto", b"set_texture_alias")


@dataclass
class Node:
    keyword: bytes
    argument: bytes = b""
    lines: list = field(default_factory=list)
    children: list = field(default_factory=list)

    def value(self, keyword: bytes) -> bytes | None:
        for name, argument in self.lines:
            if name == keyword:
                return argument
        return None

    def blocks(self, keyword: bytes) -> list:
        return [child for child in self.children if child.keyword == keyword]


@dataclass
class Definition:
    name: bytes
    parent: bytes | None
    node: Node
    script: bytes


@dataclass
class TextureUse:
    alias: bytes
    texture: bytes
    frame_count: int = 1
    settings: dict = field(default_factory=dict)


@dataclass
class PassInfo:
    settings: dict
    textures: list
    has_program: bool

    # Pass không ghi màu (scene_blend zero one hay colour_write off) chỉ để ghi depth.
    def is_visible(self) -> bool:
        blend = self.settings.get(b"scene_blend", b"").split()
        return blend != [b"zero", b"one"] and self.settings.get(b"colour_write") != b"off"


@dataclass
class Effective:
    name: bytes
    parents: list
    script: bytes
    passes: list

    # Pass đầu tiên có ghi màu; khi không có thì pass đầu.
    def primary(self) -> PassInfo | None:
        visible = [info for info in self.passes if info.is_visible()]
        if visible:
            return visible[0]
        return self.passes[0] if self.passes else None


def split_line(line: bytes) -> tuple[bytes, bytes]:
    parts = line.split(None, 1)
    return parts[0], parts[1].strip() if len(parts) > 1 else b""


def clean_lines(data: bytes) -> list:
    cleaned = []
    for raw in data.split(b"\n"):
        line = raw.split(b"//", 1)[0].strip()
        if line:
            cleaned.append(line)
    return cleaned


# Dựng cây khối từ các dòng đã làm sạch. Dòng đứng ngay trước "{" là tiêu đề của khối con.
def parse_blocks(lines: list) -> Node:
    root = Node(b"")
    stack = [root]
    for line in lines:
        current = stack[-1]
        if line == b"{":
            keyword, argument = current.lines.pop() if current.lines else (b"", b"")
            child = Node(keyword, argument)
            current.children.append(child)
            stack.append(child)
        elif line == b"}":
            if len(stack) > 1:
                stack.pop()
        else:
            current.lines.append(split_line(line))
    return root


def material_names(argument: bytes) -> tuple[bytes, bytes | None]:
    name, separator, parent = argument.partition(b":")
    if not separator:
        return argument.strip(), None
    return name.strip(), parent.strip()


def line_key(keyword: bytes, argument: bytes) -> tuple:
    if keyword in KEYED_LINES:
        return keyword, argument.split(None, 1)[0] if argument else b""
    return keyword, b""


def merge_lines(target: Node, added: Node) -> None:
    positions = {line_key(*line): index for index, line in enumerate(target.lines)}
    for line in added.lines:
        key = line_key(*line)
        if key in positions:
            target.lines[positions[key]] = line
        else:
            positions[key] = len(target.lines)
            target.lines.append(line)


def find_child(target: Node, child: Node, position: int) -> Node | None:
    same = target.blocks(child.keyword)
    if child.keyword not in NAMED_BLOCKS:
        return same[0] if same else None
    if child.argument:
        named = [block for block in same if block.argument == child.argument]
        if named:
            return named[0]
    return same[position] if position < len(same) else None


# Trộn khối added vào target theo cách OGRE trộn material con vào bản chép của cha.
def merge_node(target: Node, added: Node) -> None:
    merge_lines(target, added)
    positions = {}
    for child in added.children:
        position = positions.get(child.keyword, 0)
        positions[child.keyword] = position + 1
        match = find_child(target, child, position)
        if match is None:
            target.children.append(copy.deepcopy(child))
        else:
            merge_node(match, child)


def texture_of(unit: Node) -> tuple[bytes, int]:
    texture = unit.value(b"texture")
    if texture:
        return texture.split()[0], 1
    animated = unit.value(b"anim_texture")
    if not animated:
        return b"", 1
    parts = animated.split()
    is_counted = len(parts) >= 3 and parts[1].isdigit()
    return parts[0], int(parts[1]) if is_counted else 1


class MaterialLibrary:
    def __init__(self):
        self.definitions = {}
        self.duplicate_count = 0
        self.conflicting_duplicates = []

    def load(self, data: bytes) -> None:
        lines = clean_lines(data)
        root = parse_blocks(lines)
        for node in root.blocks(b"material"):
            name, parent = material_names(node.argument)
            script = render_script(node)
            known = self.definitions.get(name)
            if known is None:
                self.definitions[name] = Definition(name, parent, node, script)
                continue
            self.duplicate_count += 1
            if known.script != script:
                self.conflicting_duplicates.append(name)

    def chain(self, name: bytes) -> list | None:
        chain = []
        current = name
        while current is not None:
            definition = self.definitions.get(current)
            if definition is None or definition in chain:
                return None if not chain else chain
            chain.append(definition)
            current = definition.parent
        return chain

    # Material hiệu dụng của tên này; None khi tên không có định nghĩa.
    def effective(self, name: bytes) -> Effective | None:
        chain = self.chain(name)
        if not chain:
            return None
        merged = Node(b"material")
        for definition in reversed(chain):
            merge_node(merged, definition.node)
        aliases = {}
        for keyword, argument in merged.lines:
            parts = argument.split()
            if keyword == b"set_texture_alias" and len(parts) >= 2:
                aliases[parts[0]] = parts[1]
        parents = [definition.name for definition in chain[1:]]
        passes = [pass_info(node, aliases) for node in near_passes(merged)]
        return Effective(name, parents, chain[0].script, passes)


def pass_info(node: Node, aliases: dict) -> PassInfo:
    textures = [texture_use(unit, aliases) for unit in node.blocks(b"texture_unit")]
    has_program = bool(node.blocks(b"fragment_program_ref"))
    return PassInfo(dict(node.lines), textures, has_program)


def texture_use(unit: Node, aliases: dict) -> TextureUse:
    alias = unit.value(b"texture_alias") or unit.argument
    texture, frame_count = texture_of(unit)
    settings = dict(unit.lines)
    if alias in aliases:
        return TextureUse(alias, aliases[alias], 1, settings)
    return TextureUse(alias, texture, frame_count, settings)


# Các pass của technique đầu tiên không phải mức LOD thấp: thứ OGRE vẽ ở khoảng cách gần.
def near_passes(material: Node) -> list:
    techniques = material.blocks(b"technique")
    near = [t for t in techniques if t.value(b"lod_index") in (None, b"0") and not t.value(b"scheme")]
    for technique in near or techniques:
        passes = technique.blocks(b"pass")
        if passes:
            return passes
    return []


def render_node(node: Node, depth: int, output: list) -> None:
    indent = b"\t" * depth
    header = node.keyword + (b" " + node.argument if node.argument else b"")
    output.append(indent + header)
    output.append(indent + b"{")
    for keyword, argument in node.lines:
        output.append(indent + b"\t" + keyword + (b" " + argument if argument else b""))
    for child in node.children:
        render_node(child, depth + 1, output)
    output.append(indent + b"}")


# Script của một khối ở dạng chuẩn hoá (bỏ comment, thụt lề lại); giữ đủ mọi dòng có nghĩa.
def render_script(node: Node) -> bytes:
    output = []
    render_node(node, 0, output)
    return b"\n".join(output)
