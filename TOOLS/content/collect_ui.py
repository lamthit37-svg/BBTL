# Gom giao diện gốc của client 2026 (CEGUI 0.4.1 + Falagard) vào thư mục dữ liệu client để nạp thẳng
# từ XML, không nấu nhị phân, không Lua. Đọc <raw>/Interface và <raw>/Config, ghi dưới <out>:
# Interface/** (scheme, looknfeel, imageset, font, layout của cửa sổ chọn, texture trong bao đóng
# đổi thành PNG RGBA8 tên gốc + ".png"), Table/ui_windows.tsv (cả InterfaceEx), Table/ui_strings.tsv
# (chuỗi #{khoá} tra StrDictionary) và Interface/ui.files.tsv (danh sách cho package_apk.py). Hai
# bảng chữ dịch Table/*.lang.tsv không do bộ gom ghi: build_i18n.py dựng chúng cùng client từ tệp
# assets/i18n của ngôn ngữ chọn lúc dựng, và thay ảnh ngay trong các atlas bộ gom đặt ở đây; bộ
# gom chỉ đọc assets/i18n/vi.tsv để báo khoá và tên cảnh chưa dịch.
# Phông do ui_font.py giải mã trong cùng lượt ghi (tệp phông và Schema/fonts.tsv), để danh sách
# luôn có đủ chúng.
# Bao đóng port từ tools/bake/gui_cook.cpp của bản dev: cửa sổ -> kiểu (FalagardMapping) -> look
# (section, child, look khác) -> ảnh -> bộ ảnh -> texture; thêm ảnh ở Property của look.
# Quyết định:
# - XML chỉ đổi bảng mã sang UTF-8 không BOM (UTF-16 BOM, UTF-8 BOM, GBK), nội dung giữ nguyên.
# - Tra tên đúng trước, rồi không phân biệt hoa/thường nếu chỉ một ứng viên; ca đó được đếm.
# - Tham chiếu hỏng chỉ đếm và liệt kê. Mã thoát 1 khi cửa sổ chọn không giải được, texture không
#   đổi được hay dữ liệu gốc hỏng.
# - Ghi qua tệp tạm; nội dung không đổi thì giữ nguyên; PNG không cũ hơn nguồn thì bỏ qua
#   (--force ép đổi lại).
# Cách dùng: python collect_ui.py <_raw> <dữ liệu client> [--windows A,B | --all] [--dry-run]

import argparse
import codecs
import functools
import importlib.util
import os
import re
import struct
import sys
import time
import xml.etree.ElementTree as ElementTree
from collections import Counter, defaultdict
from dataclasses import dataclass, field

from PIL import Image

import build_i18n
import dbc
import ui_font

Element = ElementTree.Element

INTERFACE = "Interface"
SCHEMA = "Schema"
ALL_IMAGESET = "Schema/all.imageset.xml"
LISTING = f"{INTERFACE}/ui.files.tsv"
WINDOWS_TABLE = "Table/ui_windows.tsv"
STRINGS_TABLE = "Table/ui_strings.tsv"
TRANSLATED_TABLE = "Table/ui_strings.lang.tsv"
PORTRAITS_TABLE = "Table/portraits.tsv"
SCENE_NAMES_TABLE = "Table/scene_names.lang.tsv"
HEAD_CAMERAS_TABLE = "Table/head_cameras.tsv"
# Số loại ô chân dung và số cột của mỗi loại trong Config/Character_3DHead.txt (một chuỗi, năm số).
HEAD_KINDS = 4
HEAD_GROUP = 6
ANIMATE_FILE = "Schema/wowanimate.xml"
SOURCE_NOTE = "Sinh bằng TOOLS/content/collect_ui.py từ Config client; sửa tay sẽ mất ở lượt sau"
DEFAULT_WINDOWS = (
    "PlayerFrame", "TargetFrame", "TargetBuff", "PlayerImpactFrame", "PetFrame", "PartyFrame",
    "Team_Frame", "MiniMap", "MainMenuBar", "MainMenuBar_2", "MainMenuBar_3", "MainMenuBar_4",
    "FunctionBarRight", "FunctionBarRight_2", "ChatFrame", "ChatInfo", "MissionTrack",
    "ProgressBar", "ScrollInfo", "AutoAttack_Button", "SuperTooltip", "SelfEquip", "Packet",
    "QuestLog", "LoginLogOn", "SoftKeyBoard", "YuanbaoShop", "Operation", "ViewSetup",
    "SoundSetup", "GameSetup", "AcceSetup", "ActionSkill", "CommonSkill", "LifeSkill",
    "ZhenfaSkill", "AutoAttackSkill", "ZongMenSkill", "Pet", "Friend", "DebugListBox",
    "SelectRole/SelectRole.layout.xml", "CreateRole/CreateRole.layout.xml", "SceneTrans",
)
USAGE = "python collect_ui.py <_raw> <dữ liệu client> [--windows A,B | --all] [--dry-run] [--force]"
DESCRIPTION = "Gom giao diện gốc của client 2026 vào thư mục dữ liệu client (CLIENT/data)."
STRING_PROPERTIES = ("Text", "Tooltip")
PROPERTY_TAGS = ("Property", "PropertyDefinition")
RECT_KEYS = ("XPos", "YPos", "Width", "Height")
INTERFACE_EX_TYPES = [
    dbc.INT, dbc.STRING, dbc.STRING, dbc.STRING, dbc.INT,
    dbc.STRING, dbc.INT, dbc.INT, dbc.INT, dbc.STRING,
]
LIST_LIMIT = 20
PROGRESS_STEP = 200
PNG_LEVEL = 6
DDS_MAGIC = b"DDS "
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
UTF8_NAMES = ("utf-8", "utf8")
# set:<bộ ảnh> image:<ảnh> như sscanf của CEGUI (nhiều dấu cách được), có thể kèm tiền tố "type:0".
IMAGE_VALUE = re.compile(r"(?:^|\s)set:(\S*)\s+image:\s*(\S*)")
# Giá trị ảnh viết trong chuỗi của mã C++: "set:<bộ> image:<ảnh>" giữa hai dấu nháy kép.
SOURCE_IMAGE = re.compile(r'"(set:[^"\s]+\s+image:[^"\s]+)"')
ANIMATE_VALUE = re.compile(r"(?:^|\s)animate:(\S+)")
# Thuộc tính mà giá trị là thẳng tên một hoạt ảnh trong wowanimate.xml.
ANIMATE_PROPERTIES = ("Animate", "FlashAnimate", "WarningAnimation", "BtnAnimation")
STRING_KEY = re.compile(r"#\{([^{}]*)\}")
# Khoá viết trong mã C++: chỉ nhận chữ, số ASCII và gạch dưới như mọi khoá của từ điển, để chữ
# "#{khoá}" trong comment và hai hằng "#{" với "}" đứng gần nhau không thành khoá giả.
SOURCE_KEY = re.compile(r"#\{([A-Za-z0-9_]+)\}")
CELL_BREAKS = re.compile(r"[\t\r\n]+")
DECLARATION = re.compile(r"\A<\?xml[^?]*\?>")
ENCODING_ATTRIBUTE = re.compile(r"""(encoding\s*=\s*)(["'])([^"']*)\2""", re.IGNORECASE)
# Kiểu do client tự đăng ký factory, không cần FalagardMapping.
BUILTIN_TYPE = re.compile(r"DefaultWindow|Falagard/.+")


class UiError(Exception):
    pass


# Mốc: văn bản và XML


def decode_text(data: bytes, label: str) -> str:
    is_wide = data.startswith((codecs.BOM_UTF16_LE, codecs.BOM_UTF16_BE))
    choices = ("utf-16",) if is_wide else ("utf-8-sig", "gbk")
    for codec in choices:
        try:
            return data.decode(codec)
        except UnicodeDecodeError:
            continue
    raise UiError(f"{label}: không giải mã được bằng {', '.join(choices)}")


# Khai báo encoding trong <?xml?> phải khớp bảng mã mới; chỉ sửa khi nó khác UTF-8.
def utf8_declaration(match: re.Match) -> str:
    if match.group(3).lower() in UTF8_NAMES:
        return match.group(0)
    quote = match.group(2)
    return f"{match.group(1)}{quote}utf-8{quote}"


def normalize_xml(data: bytes, label: str) -> bytes:
    text = decode_text(data, label)
    head = DECLARATION.match(text)
    if head is not None:
        text = ENCODING_ATTRIBUTE.sub(utf8_declaration, head.group(0)) + text[head.end():]
    return text.encode("utf-8")


def read_raw(path: str) -> bytes:
    with open(path, "rb") as stream:
        return stream.read()


def property_name(element: Element) -> str:
    return element.get("Name") or element.get("name") or ""


# Layout viết Value, looknfeel viết value, PropertyDefinition viết initialValue; có cả chỗ viết lẫn.
def property_value(element: Element) -> str:
    return element.get("Value") or element.get("value") or element.get("initialValue") or ""


# Mốc: tra tên và cây nguồn


class Names:
    # Từ điển tra đúng tên; không thấy thì tra không phân biệt hoa/thường nếu chỉ có một ứng viên.
    def __init__(self):
        self.items: dict = {}
        self._folded = None

    def add(self, name: str, value) -> bool:
        if name in self.items:
            return False
        self.items[name] = value
        self._folded = None
        return True

    # (tên thật, true nếu phải bỏ phân biệt hoa/thường); tên thật là None khi không thấy.
    def find(self, name: str) -> tuple[str | None, bool]:
        if name in self.items:
            return name, False
        if self._folded is None:
            self._folded = defaultdict(list)
            for known in self.items:
                self._folded[known.lower()].append(known)
        candidates = self._folded.get(name.lower(), [])
        if len(candidates) != 1:
            return None, False
        return candidates[0], True


class Source:
    # Cây <raw>/Interface: tra đường dẫn không phân biệt hoa/thường và trả tên thật trên đĩa.
    def __init__(self, raw_root: str):
        self.root = os.path.join(raw_root, INTERFACE)
        if not os.path.isdir(self.root):
            raise UiError(f"không có thư mục {self.root}")
        self.files: dict[str, str] = {}
        for base, folders, names in os.walk(self.root):
            folders.sort()
            for name in sorted(names):
                relative = os.path.relpath(os.path.join(base, name), self.root)
                relative = relative.replace(os.sep, "/")
                self.files.setdefault(relative.lower(), relative)

    def find(self, relative: str) -> str | None:
        return self.files.get(relative.replace("\\", "/").lower())

    def path(self, relative: str) -> str:
        return os.path.join(self.root, *relative.split("/"))

    # Tệp theo đuôi; có folder thì chỉ lấy tệp nằm thẳng trong thư mục đó.
    def matching(self, suffix: str, folder: str | None = None) -> list[str]:
        found = [real for key, real in self.files.items() if key.endswith(suffix)]
        if folder is not None:
            prefix = folder.lower() + "/"
            direct = [real for real in found if real.count("/") == 1]
            found = [real for real in direct if real.lower().startswith(prefix)]
        return sorted(found)

    def normalized(self, relative: str) -> bytes:
        return normalize_xml(read_raw(self.path(relative)), relative)

    # Nội dung đã chuẩn hoá UTF-8 và cây phần tử của một tệp XML.
    def read_xml(self, relative: str) -> tuple[bytes, Element]:
        data = self.normalized(relative)
        try:
            return data, ElementTree.fromstring(data)
        except ElementTree.ParseError as error:
            raise UiError(f"{relative}: XML hỏng: {error}") from error


# Mốc: bảng DBC của Config


# Như Dbc.text nhưng không cắt khối chuỗi ở mỗi lần gọi (StrDictionary có 155 nghìn dòng).
def text_cell(table: dbc.Dbc, row: int, column: int) -> str:
    if table.types[column] != dbc.STRING:
        raise dbc.DbcError(f"{table.name}: cột {column} không phải chuỗi")
    offset = table.raw(row, column)
    end = table.strings.find(b"\0", offset)
    if offset >= len(table.strings) or end < 0:
        size = len(table.strings)
        raise dbc.DbcError(f"{table.name}: offset chuỗi {offset} ngoài khối {size} byte")
    return table.strings[offset:end].decode("gb18030")


@dataclass
class WindowRow:
    number: int
    name: str
    layout: str
    demise: int
    open_sound: int
    close_sound: int
    flag: int
    note: str


class Registry:
    # Sổ cửa sổ InterfaceEx; layout sửa theo tên thật trên đĩa (dấu / và đúng hoa/thường).
    def __init__(self, raw_root: str, source: Source):
        path = os.path.join(raw_root, "Config", "InterfaceEx.txt")
        table = dbc.read(path, "InterfaceEx.txt")
        if table.types != INTERFACE_EX_TYPES:
            raise UiError("InterfaceEx.txt: kiểu cột lạ (cần số, 3 chuỗi, số, chuỗi, 3 số, chuỗi)")
        self.rows: list[WindowRow] = []
        self.names = Names()
        self.case_fixed = 0
        self.unfound = 0
        for row in range(table.rows):
            self._add(table, row, source)

    def _add(self, table: dbc.Dbc, row: int, source: Source) -> None:
        listed = text_cell(table, row, 2).replace("\\", "/")
        real = source.find(listed)
        if real is None:
            self.unfound += 1
        elif real != listed:
            self.case_fixed += 1
        record = WindowRow(
            number=table.integer(row, 0), name=text_cell(table, row, 1), layout=real or listed,
            demise=table.integer(row, 4), open_sound=table.integer(row, 6),
            close_sound=table.integer(row, 7), flag=table.integer(row, 8),
            note=text_cell(table, row, 9),
        )
        self.rows.append(record)
        self.names.add(record.name, record)

    def layouts(self) -> set[str]:
        return {row.layout.lower() for row in self.rows}

    def layout_of(self, name: str) -> str | None:
        key, _ = self.names.find(name)
        return None if key is None else self.names.items[key].layout


# Mốc: chọn cửa sổ


@dataclass
class Selection:
    layouts: list[str] = field(default_factory=list)
    unresolved: list[str] = field(default_factory=list)


# "thư mục/tệp" chỉ tới layout chưa đăng ký; tên trơn tra trong InterfaceEx.
def layout_of(name: str, registry: Registry, source: Source) -> str | None:
    text = name.replace("\\", "/").strip()
    if "/" not in text:
        found = registry.layout_of(text)
        return None if found is None else source.find(found)
    return source.find(text if text.lower().endswith(".layout.xml") else f"{text}.layout.xml")


def choose_windows(names: tuple | list, registry: Registry, source: Source) -> Selection:
    selection = Selection()
    for name in names:
        layout = layout_of(name, registry, source)
        if layout is None:
            where = "tệp" if "/" in name else "InterfaceEx"
            selection.unresolved.append(f"{name} (không có trong {where})")
        elif layout not in selection.layouts:
            selection.layouts.append(layout)
    return selection


# Mốc: imageset


@dataclass
class ImageSet:
    name: str
    imagefile: str
    rects: Names


def read_rect(image: Element, owner: str) -> tuple:
    try:
        return tuple(float(image.get(key, "0")) for key in RECT_KEYS)
    except ValueError as error:
        raise UiError(f"imageset {owner}: ảnh {image.get('Name')}: số lạ ({error})") from error


def read_imageset(element: Element) -> ImageSet:
    name = element.get("Name", "")
    imageset = ImageSet(name, element.get("Imagefile", "").replace("\\", "/"), Names())
    for image in element.findall("Image"):
        imageset.rects.add(image.get("Name", ""), read_rect(image, name))
    return imageset


class ImageIndex:
    # Mọi bộ ảnh của *.imageset.xml; trùng tên thì bộ đến trước thắng (all.imageset.xml đọc đầu).
    def __init__(self):
        self.sets = Names()
        self.duplicates: list[str] = []
        self.image_total = 0

    def add(self, element: Element) -> None:
        imageset = read_imageset(element)
        if not self.sets.add(imageset.name, imageset):
            self.duplicates.append(imageset.name)
            return
        self.image_total += len(imageset.rects.items)


def load_imagesets(source: Source, texts: dict) -> tuple[ImageIndex, list[str]]:
    files = source.matching(".imageset.xml")
    files.sort(key=lambda relative: relative != ALL_IMAGESET)
    index = ImageIndex()
    for relative in files:
        data, root = source.read_xml(relative)
        texts[f"{INTERFACE}/{relative}"] = data
        for element in ([root] if root.tag == "Imageset" else root.findall("Imageset")):
            index.add(element)
    return index, files


# Bảng hoạt ảnh của AnimateManager theo tên; tên lặp thì giữ dòng gặp trước. Không có tệp thì rỗng.
def load_animates(source: Source) -> dict:
    relative = source.find(ANIMATE_FILE)
    if relative is None:
        return {}
    _, root = source.read_xml(relative)
    animates: dict[str, Element] = {}
    for element in root.findall("Animate"):
        animates.setdefault(element.get("Name", ""), element)
    return animates


# Tệp hoạt ảnh của client: chỉ các hoạt ảnh trong bao đóng, giữ thứ tự và thuộc tính của tệp gốc.
def animate_bytes(animates: dict, used: set[str]) -> bytes:
    root = ElementTree.Element("AnimateManager")
    for name, element in animates.items():
        if name in used:
            root.append(element)
    ElementTree.indent(root)
    body = ElementTree.tostring(root, encoding="unicode")
    return f'<?xml version="1.0" ?>\n{body}\n'.encode("utf-8")


# Mốc: scheme và looknfeel


@dataclass
class Schema:
    mappings: dict = field(default_factory=dict)
    looks: dict = field(default_factory=dict)
    scheme_files: list = field(default_factory=list)
    look_files: list = field(default_factory=list)
    font_files: list = field(default_factory=list)
    duplicate_mappings: int = 0
    absent_files: list = field(default_factory=list)


def read_scheme(source: Source, relative: str, schema: Schema, texts: dict) -> list[str]:
    data, root = source.read_xml(relative)
    texts[f"{INTERFACE}/{relative}"] = data
    listed = []
    for element in root:
        if element.tag == "FalagardMapping":
            window = element.get("WindowType", "")
            if window in schema.mappings:
                schema.duplicate_mappings += 1
            schema.mappings[window] = element.get("LookNFeel", "")
        elif element.tag == "LookNFeel":
            listed.append(element.get("Filename", ""))
    return listed


def read_looknfeel(source: Source, relative: str, schema: Schema, texts: dict) -> None:
    data, root = source.read_xml(relative)
    texts[f"{INTERFACE}/{relative}"] = data
    for element in root.findall("WidgetLook"):
        schema.looks.setdefault(element.get("name", ""), element)


def load_schema(source: Source, texts: dict) -> Schema:
    schema = Schema(scheme_files=source.matching(".scheme.xml", SCHEMA))
    if not schema.scheme_files:
        raise UiError(f"không có {SCHEMA}/*.scheme.xml trong {source.root}")
    listed = []
    for relative in schema.scheme_files:
        listed += read_scheme(source, relative, schema, texts)
    schema.absent_files = [name for name in listed if source.find(name) is None]
    schema.look_files = source.matching(".looknfeel.xml", SCHEMA)
    for relative in schema.look_files:
        read_looknfeel(source, relative, schema, texts)
    schema.font_files = source.matching(".font", SCHEMA)
    for relative in schema.font_files:
        texts[f"{INTERFACE}/{relative}"] = source.normalized(relative)
    return schema


# Mốc: bao đóng


class Misses:
    # Thứ không giải được, theo loại; đếm đủ, khi in chỉ liệt kê LIST_LIMIT tên.
    def __init__(self):
        self.counts: dict[str, Counter] = defaultdict(Counter)

    def add(self, kind: str, name: str) -> None:
        self.counts[kind][name] += 1

    def distinct(self, kind: str) -> int:
        return len(self.counts[kind])

    def describe(self, kind: str) -> str:
        counter = self.counts[kind]
        if not counter:
            return f"{kind}: 0"
        names = sorted(counter)[:LIST_LIMIT]
        rest = len(counter) - len(names)
        tail = f" ... còn {rest}" if rest else ""
        total = sum(counter.values())
        return f"{kind}: {len(counter)} khác nhau, {total} lần: {', '.join(names)}{tail}"


def string_keys(value: str) -> list[str]:
    return [key for key in STRING_KEY.findall(value) if key]


class Closure:
    # Bao đóng cửa sổ -> ảnh theo gui_cook.cpp: mỗi kiểu, look và section chỉ đi một lần.
    def __init__(self, schema: Schema, images: ImageIndex, animates: dict):
        self.schema = schema
        self.images = images
        self.animates = animates
        self.used_animates: set[str] = set()
        self.misses = Misses()
        self.seen_types: set[str] = set()
        self.seen_looks: set[str] = set()
        self.seen_sections: set[tuple[str, str]] = set()
        self.used: dict[str, set[str]] = {}
        self.empty_refs = 0
        self.folded_refs: Counter = Counter()
        self.layout_keys: set[str] = set()
        self.look_keys: set[str] = set()
        self.panel_keys: set[str] = set()
        self._sections: dict[str, dict[str, Element]] = {}

    def visit_layout(self, root: Element) -> None:
        for element in root.iter():
            if element.tag == "Window":
                self.visit_type(element.get("Type", "DefaultWindow"))
            elif element.tag == "Property":
                self.take_property(element, self.layout_keys)

    def visit_type(self, name: str) -> None:
        if name in self.seen_types:
            return
        self.seen_types.add(name)
        look = self.schema.mappings.get(name)
        if look is not None:
            self.visit_look(look)
        elif not BUILTIN_TYPE.fullmatch(name):
            self.misses.add("kiểu", name)

    def visit_look(self, name: str) -> None:
        if name in self.seen_looks:
            return
        self.seen_looks.add(name)
        look = self.schema.looks.get(name)
        if look is None:
            self.misses.add("look", name)
            return
        for part in look:
            self.visit_look_part(name, part)

    def visit_look_part(self, look: str, part: Element) -> None:
        if part.tag == "StateImagery":
            for section in part.iter("Section"):
                self.visit_section(section.get("look", look), section.get("section", ""))
        elif part.tag == "Child":
            self.visit_type(part.get("type", ""))
            self.take_inside(part)
        elif part.tag == "NamedArea":
            self.take_inside(part)
        elif part.tag in PROPERTY_TAGS:
            self.take_property(part, self.look_keys)

    def visit_section(self, owner: str, name: str) -> None:
        if (owner, name) in self.seen_sections:
            return
        self.seen_sections.add((owner, name))
        if owner not in self.schema.looks:
            self.misses.add("look", owner)
        section = self.sections_of(owner).get(name)
        if section is None:
            self.misses.add("section", f"{owner}/{name}")
            return
        self.take_inside(section)

    def sections_of(self, owner: str) -> dict[str, Element]:
        if owner not in self._sections:
            look = self.schema.looks.get(owner)
            found = [] if look is None else look.findall("ImagerySection")
            self._sections[owner] = {section.get("name", ""): section for section in found}
        return self._sections[owner]

    # Mọi <Image>, <ImageDim> và Property bên trong một phần tử của look.
    def take_inside(self, part: Element) -> None:
        for element in part.iter():
            if element.tag in ("Image", "ImageDim"):
                self.take_image(element.get("imageset", ""), element.get("image", ""))
            elif element.tag in PROPERTY_TAGS:
                self.take_property(element, self.look_keys)

    # Ảnh và hoạt ảnh trong giá trị; thêm khoá #{...} của Text và Tooltip vào keys.
    def take_property(self, element: Element, keys: set[str]) -> None:
        value = property_value(element)
        name = property_name(element)
        self.take_image_value(value)
        self.take_animate_value(name, value)
        if name == "MaskImage" and value.strip():
            self.take_imageset(value.strip())
        if name in STRING_PROPERTIES:
            keys.update(string_keys(value))

    # MaskImage mang tên một imageset: mặt nạ là cả texture của bộ đó, nên gom mọi ảnh của bộ.
    def take_imageset(self, set_name: str) -> None:
        set_key, _ = self.images.sets.find(set_name)
        if set_key is None:
            self.misses.add("bộ ảnh", set_name)
            return
        for image_name in self.images.sets.items[set_key].rects.items:
            self.take_image(set_name, image_name)

    # Hoạt ảnh mà thuộc tính nhắc tới: tên thẳng (ANIMATE_PROPERTIES), hay thẻ animate:<tên> như
    # AnimateImage và FlashAnimateImage của radar.
    def take_animate_value(self, name: str, value: str) -> None:
        names = ANIMATE_VALUE.findall(value)
        if name in ANIMATE_PROPERTIES and value.strip() and not names:
            names.append(value.strip())
        for found in names:
            self.take_animate(found)

    # Tên đúng từng chữ như AnimateManager tra; ảnh của mọi khung đi vào bao đóng ảnh.
    def take_animate(self, name: str) -> None:
        if name in self.used_animates:
            return
        element = self.animates.get(name)
        if element is None:
            self.misses.add("hoạt ảnh", name)
            return
        self.used_animates.add(name)
        for image in element.findall("Image"):
            self.take_image_value(image.get("ImageName", ""))

    def take_image_value(self, value: str) -> None:
        if "image:" not in value:
            return
        match = IMAGE_VALUE.search(value)
        if match is None:
            self.misses.add("giá trị ảnh sai dạng", value.strip()[:60])
            return
        self.take_image(match.group(1), match.group(2))

    def take_image(self, set_name: str, image_name: str) -> None:
        if not set_name and not image_name:
            self.empty_refs += 1
            return
        label = f"{set_name}/{image_name}"
        set_key, set_folded = self.images.sets.find(set_name)
        if set_key is None:
            self.misses.add("bộ ảnh", set_name)
            self.misses.add("ảnh", label)
            return
        imageset = self.images.sets.items[set_key]
        image_key, image_folded = imageset.rects.find(image_name)
        if image_key is None:
            self.misses.add("ảnh", label)
            return
        self.used.setdefault(set_key, set()).add(image_key)
        if set_folded or image_folded:
            self.folded_refs[label] += 1


# Mốc: chuỗi


class Dictionary:
    # StrDictionary: khoá lặp thì dòng sau thắng, như m_theDirectionary[khoá] = chuỗi của client.
    def __init__(self, raw_root: str):
        path = os.path.join(raw_root, "Config", "StrDictionary.txt")
        self.table = dbc.read(path, "StrDictionary.txt")
        if self.table.types != [dbc.STRING, dbc.STRING]:
            raise UiError("StrDictionary.txt: không đúng 2 cột chuỗi (khoá, chuỗi)")
        self.rows: dict[str, int] = {}
        self.repeated: set[str] = set()
        for row in range(self.table.rows):
            key = text_cell(self.table, row, 0)
            if key in self.rows:
                self.repeated.add(key)
            self.rows[key] = row

    def lookup(self, key: str) -> str | None:
        row = self.rows.get(key)
        return None if row is None else text_cell(self.table, row, 1)


@dataclass
class Strings:
    rows: list = field(default_factory=list)
    missing: list = field(default_factory=list)
    repeated: int = 0
    # Khoá đã gom mà bảng dịch tiếng Việt chưa có.
    untranslated: list = field(default_factory=list)


# Khoá #{...} của Text và Tooltip trong MỌI look đã chép, kể cả look chưa cửa sổ nào dùng: tệp
# looknfeel chép nguyên nên bảng chuỗi phải đủ cho cả tệp.
def schema_keys(schema: Schema) -> set[str]:
    keys: set[str] = set()
    for look in schema.looks.values():
        for element in look.iter():
            if element.tag in PROPERTY_TAGS and property_name(element) in STRING_PROPERTIES:
                keys.update(string_keys(property_value(element)))
    return keys


# Khoá #{...} mà mã thay script (SRC/ui/panel/*.cpp) viết trong chuỗi: script gốc đặt các chữ đó
# lúc chạy nên layout không nhắc tới, bảng chuỗi vẫn phải có.
def panel_keys() -> set[str]:
    tools = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    folder = os.path.join(os.path.dirname(tools), "SRC", "ui", "panel")
    keys: set[str] = set()
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".cpp"):
            continue
        with open(os.path.join(folder, name), encoding="utf-8") as stream:
            keys.update(SOURCE_KEY.findall(stream.read()))
    return keys


# Ảnh "set:<bộ> image:<ảnh>" mà mã thay script viết trong chuỗi: script gốc gán các ảnh đó lúc
# chạy (SetProperty("Image", ...)) nên layout không nhắc tới, texture của chúng vẫn phải được gom.
def panel_images() -> set[str]:
    tools = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    folder = os.path.join(os.path.dirname(tools), "SRC", "ui", "panel")
    values: set[str] = set()
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".cpp"):
            continue
        with open(os.path.join(folder, name), encoding="utf-8") as stream:
            values.update(SOURCE_IMAGE.findall(stream.read()))
    return values


# Khoá không viết được ra TSV: rỗng, mở đầu bằng # (thành dòng chú thích) hay chứa tab/xuống dòng.
def is_writable_key(key: str) -> bool:
    return bool(key) and not key.startswith("#") and CELL_BREAKS.search(key) is None


def build_strings(dictionary: Dictionary, keys: set[str]) -> Strings:
    strings = Strings()
    for key in sorted(keys):
        text = dictionary.lookup(key) if is_writable_key(key) else None
        if text is None:
            strings.missing.append(key)
            continue
        strings.rows.append((key, text))
        if key in dictionary.repeated:
            strings.repeated += 1
    return strings


# Mốc: bảng TSV


def clean_row(row: list[str]) -> tuple[list[str], int]:
    cells = [CELL_BREAKS.sub(" ", cell) for cell in row]
    return cells, sum(1 for before, after in zip(row, cells) if before != after)


# Bảng theo tsv.hpp: dòng # là chú thích, dòng đầu còn lại là tên cột, ô không chứa tab/xuống dòng.
def build_tsv(comments: list[str], header: list[str], rows: list[list[str]]) -> tuple[bytes, int]:
    lines = [f"# {comment}" for comment in comments]
    lines.append("\t".join(header))
    changed = 0
    for row in rows:
        cells, altered = clean_row(row)
        changed += altered
        lines.append("\t".join(cells))
    return ("\n".join(lines) + "\n").encode("utf-8"), changed


def windows_table(registry: Registry) -> tuple[bytes, int]:
    comments = [
        "Sổ cửa sổ giao diện gốc (Config/InterfaceEx.txt), khoá id.", SOURCE_NOTE,
        "layout: đường dẫn dấu / tương đối với Interface/, đã sửa đúng hoa/thường theo tệp thật.",
    ]
    header = ["id", "name", "layout", "demise", "open_sound", "close_sound", "flag", "note"]
    rows = [
        [str(row.number), row.name, row.layout, str(row.demise), str(row.open_sound),
         str(row.close_sound), str(row.flag), row.note]
        for row in registry.rows
    ]
    return build_tsv(comments, header, rows)


# Bản tiếng Việt của dự án (assets/i18n/vi.tsv). build_i18n.py dựng tệp của ngôn ngữ chọn lúc dựng
# thành hai bảng Table/ui_strings.lang.tsv và Table/scene_names.lang.tsv; bộ gom chỉ đọc bản
# tiếng Việt để báo chỗ chưa dịch.
def i18n_manifest() -> build_i18n.Manifest:
    tools = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(os.path.dirname(tools), "assets", "i18n", "vi.tsv")
    with open(path, encoding="utf-8") as stream:
        return build_i18n.read_manifest(stream.read())


# Các khoá chuỗi đã gom mà bản tiếng Việt chưa có.
def untranslated_keys(strings: Strings) -> list[str]:
    done = {key for key, _ in i18n_manifest().strings}
    return [key for key, _ in strings.rows if key not in done]


# Bảng chân dung (Config/CharacterFace.txt): id máy chủ gửi cho từng nhân vật, giới (0 nữ, 1 nam),
# ảnh chân dung, cờ chọn và khoá sắp của màn tạo nhân vật. Mọi dòng theo đúng thứ tự tệp gốc: bộ
# quản chân dung của client gốc sắp ổn định theo order, nên thứ tự tệp quyết định thứ tự giữa các
# dòng cùng order (docs/TAO-NHAN-VAT-2026.md). Ảnh đi vào bao đóng để texture của nó được gom.
def portraits_table(raw_root: str, closure: Closure) -> tuple[bytes, int]:
    table = dbc.read(os.path.join(raw_root, "Config", "CharacterFace.txt"), "CharacterFace.txt")
    if table.types[:5] != [dbc.INT, dbc.INT, dbc.STRING, dbc.INT, dbc.INT]:
        raise UiError("CharacterFace.txt: kiểu cột lạ (năm cột đầu phải là số, số, chuỗi, số, số)")
    rows = []
    for row in range(table.rows):
        image = text_cell(table, row, 2)
        closure.take_image_value(image)
        numbers = [str(table.integer(row, column)) for column in (0, 1, 3, 4)]
        rows.append([numbers[0], numbers[1], image, numbers[2], numbers[3]])
    comments = [
        "Chân dung nhân vật (Config/CharacterFace.txt), khoá id; race 0 là nữ, 1 là nam.",
        "choice 1 hay 3 là chọn được lúc tạo nhân vật; order là khoá sắp tăng dần của màn tạo.",
        SOURCE_NOTE,
    ]
    return build_tsv(comments, ["id", "race", "image", "choice", "order"], rows)


# Tên mẫu (cột template) của các thân người chơi client đang dùng: <dữ liệu client>/Table/
# player_bodies.tsv do export_look.py sinh. Chưa có tệp thì rỗng.
def player_templates(out_root: str) -> list[str]:
    path = os.path.join(out_root, "Table", "player_bodies.tsv")
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8") as stream:
        lines = [line for line in stream.read().splitlines() if line and not line.startswith("#")]
    header = lines[0].split("\t")
    column = header.index("template")
    return [line.split("\t")[column] for line in lines[1:]]


# Camera của ảnh đầu 3D (Config/Character_3DHead.txt, khoá là id của Config/CharModelEx.txt) cho
# các mô hình người chơi client đang dùng: mỗi mô hình bốn dòng theo loại ô. Trả nội dung bảng và
# các mẫu không tìm được dòng.
def head_cameras_table(raw_root: str, out_root: str) -> tuple[bytes, list[str]]:
    models = dbc.read(os.path.join(raw_root, "Config", "CharModelEx.txt"), "CharModelEx.txt")
    heads = dbc.read(os.path.join(raw_root, "Config", "Character_3DHead.txt"),
                     "Character_3DHead.txt")
    if heads.columns != 1 + HEAD_KINDS * HEAD_GROUP:
        raise UiError("Character_3DHead.txt: số cột lạ (cần id và bốn nhóm sáu cột)")
    ids = {text_cell(models, row, 1): models.integer(row, 0) for row in range(models.rows)}
    rows, missing = [], []
    for template in player_templates(out_root):
        row = heads.find(ids.get(template, -1))
        if row is None:
            missing.append(template)
            continue
        for kind in range(HEAD_KINDS):
            first = 2 + kind * HEAD_GROUP
            numbers = [f"{heads.real(row, first + slot):.6g}" for slot in range(5)]
            rows.append([template, str(kind)] + numbers)
    comments = [
        "Camera của ảnh đầu 3D theo mô hình (Config/Character_3DHead.txt), khoá model và kind.",
        "kind là loại ô (0 quay mặt sang trái màn hình, 1 tới 3 sang phải; khung đội dùng 2); turn là",
        "hướng mặt mô hình (radian, dương là sang phải); height, distance theo đơn vị game; pitch là hệ",
        "số nhích mắt; shift là độ lệch ngang của điểm nhìn theo đơn vị mô hình.",
        SOURCE_NOTE,
    ]
    header = ["model", "kind", "turn", "height", "distance", "pitch", "shift"]
    data, _ = build_tsv(comments, header, rows)
    return data, missing


# Tên cảnh (cột 2) của bảng cảnh mà client nạp: <dữ liệu client>/Config/SceneDefineEx.txt, bảng
# văn bản hai dòng đầu là kiểu cột, dòng # là dòng tắt. Chưa có tệp thì rỗng.
def client_scene_names(out_root: str) -> list[str]:
    path = os.path.join(out_root, "Config", "SceneDefineEx.txt")
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8") as stream:
        lines = stream.read().splitlines()[2:]
    rows = [line.split("\t") for line in lines if line and not line.startswith("#")]
    return list(dict.fromkeys(row[1] for row in rows if len(row) > 1))


# Các tên cảnh client đang nạp mà bản tiếng Việt chưa có.
def unnamed_scene_names(out_root: str) -> list[str]:
    done = {name for name, _ in i18n_manifest().scenes}
    return [name for name in client_scene_names(out_root) if name not in done]


def strings_table(strings: Strings) -> tuple[bytes, int]:
    comments = [
        "Chuỗi giao diện đã chép: khoá #{khoá} trong layout và look, tra Config/StrDictionary.txt.",
        SOURCE_NOTE,
    ]
    return build_tsv(comments, ["key", "text"], [[key, text] for key, text in strings.rows])


# Mốc: texture


@functools.cache
def texture_module():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, "glb", "texture.py")
    spec = importlib.util.spec_from_file_location("glb_texture", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@dataclass
class Texture:
    imagefile: str
    source: str
    real: str
    right: float = 0.0
    bottom: float = 0.0

    # Mép phải và dưới xa nhất của các ảnh dùng tới, để đối chiếu với kích thước PNG.
    def take(self, imageset: ImageSet, names: set[str]) -> None:
        for name in names:
            x, y, width, height = imageset.rects.items[name]
            self.right = max(self.right, x + width)
            self.bottom = max(self.bottom, y + height)


@dataclass
class TexturePlan:
    textures: list = field(default_factory=list)
    spelling_conflicts: list = field(default_factory=list)
    case_mismatch: int = 0


def plan_textures(closure: Closure, source: Source) -> TexturePlan:
    plan = TexturePlan()
    by_name: dict[str, Texture] = {}
    for set_name in sorted(closure.used):
        imageset = closure.images.sets.items[set_name]
        real = source.find(imageset.imagefile)
        if real is None:
            closure.misses.add("texture", imageset.imagefile)
            continue
        texture = by_name.get(imageset.imagefile.lower())
        if texture is None:
            texture = Texture(imageset.imagefile, source.path(real), real)
            by_name[imageset.imagefile.lower()] = texture
            if real != imageset.imagefile:
                plan.case_mismatch += 1
        elif texture.imagefile != imageset.imagefile:
            plan.spelling_conflicts.append(f"{texture.imagefile} / {imageset.imagefile}")
        texture.take(imageset, closure.used[set_name])
    plan.textures = sorted(by_name.values(), key=lambda texture: texture.imagefile)
    return plan


def load_rgba(path: str) -> Image.Image:
    data = read_raw(path)
    if not data.startswith(DDS_MAGIC):
        with Image.open(path) as image:
            return image.convert("RGBA")
    module = texture_module()
    try:
        decoded = module.decode_dds(data)
    except module.TextureError as error:
        raise UiError(f"DDS không giải được: {error}") from error
    return Image.fromarray(decoded.pixels).convert("RGBA")


def convert_texture(source: str, target: str) -> None:
    image = load_rgba(source)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    temporary = target + ".tmp"
    try:
        image.save(temporary, format="PNG", compress_level=PNG_LEVEL)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def is_current(source: str, target: str) -> bool:
    return os.path.isfile(target) and os.path.getmtime(target) >= os.path.getmtime(source)


def png_size(path: str) -> tuple[int, int]:
    with open(path, "rb") as stream:
        head = stream.read(24)
    if not head.startswith(PNG_SIGNATURE):
        raise UiError(f"{path}: không phải PNG")
    return struct.unpack(">II", head[16:24])


# Mốc: ghi tệp


def is_same(path: str, data: bytes) -> bool:
    if not os.path.isfile(path) or os.path.getsize(path) != len(data):
        return False
    return read_raw(path) == data


def write_atomic(path: str, data: bytes) -> bool:
    if is_same(path, data):
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    temporary = path + ".tmp"
    try:
        with open(temporary, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)
    return True


@dataclass
class Outcome:
    written: int = 0
    kept: int = 0
    png_written: int = 0
    png_kept: int = 0
    png_bytes: int = 0
    png_paths: list = field(default_factory=list)
    font_paths: list = field(default_factory=list)
    failures: list = field(default_factory=list)
    out_of_bounds: list = field(default_factory=list)


def out_path(out_root: str, relative: str) -> str:
    return os.path.join(out_root, *relative.split("/"))


def write_file(out_root: str, relative: str, data: bytes, outcome: Outcome) -> None:
    if write_atomic(out_path(out_root, relative), data):
        outcome.written += 1
    else:
        outcome.kept += 1


def check_bounds(texture: Texture, target: str, outcome: Outcome) -> None:
    width, height = png_size(target)
    outcome.png_bytes += os.path.getsize(target)
    if texture.right > width or texture.bottom > height:
        reach = f"{texture.right:g}x{texture.bottom:g}"
        outcome.out_of_bounds.append(f"{texture.imagefile}: ảnh tới {reach}, PNG {width}x{height}")


def write_texture(texture: Texture, out_root: str, force: bool, outcome: Outcome) -> None:
    relative = f"{INTERFACE}/{texture.imagefile}.png"
    target = out_path(out_root, relative)
    try:
        if force or not is_current(texture.source, target):
            convert_texture(texture.source, target)
            outcome.png_written += 1
        else:
            outcome.png_kept += 1
        check_bounds(texture, target, outcome)
    except Exception as error:  # một texture hỏng không được làm hỏng cả lượt; lỗi vào báo cáo
        outcome.failures.append(f"{texture.imagefile}: {type(error).__name__}: {error}")
        return
    outcome.png_paths.append(relative)


def write_textures(textures: list, out_root: str, force: bool, outcome: Outcome) -> None:
    for number, texture in enumerate(textures, 1):
        write_texture(texture, out_root, force, outcome)
        if number % PROGRESS_STEP == 0:
            print(f"  texture {number}/{len(textures)}", flush=True)


# Phông: ui_font.py giải mã, kiểm và ghi tệp phông cùng Schema/fonts.tsv; đường dẫn vào danh sách.
def write_fonts(raw_root: str, out_root: str, outcome: Outcome) -> None:
    source = os.path.join(raw_root, INTERFACE)
    result = ui_font.build_fonts(source, os.path.join(out_root, INTERFACE))
    names = [output.relative for output in result.outputs]
    names.append(f"{SCHEMA}/{ui_font.TSV_NAME}")
    outcome.font_paths = sorted({f"{INTERFACE}/{name}" for name in names})


# Danh sách cho package_apk.py: tệp dưới Interface/ (XML, PNG đã có, phông), rồi hai bảng ở đuôi.
def listing_bytes(texts: dict, made_paths: list) -> bytes:
    interface = {path for path in texts if path.startswith(f"{INTERFACE}/")}
    tables = [WINDOWS_TABLE, STRINGS_TABLE, TRANSLATED_TABLE, PORTRAITS_TABLE, SCENE_NAMES_TABLE,
              HEAD_CAMERAS_TABLE]
    paths = sorted(interface | set(made_paths)) + tables
    return ("kind\tpath\n" + "".join(f"ui\t{path}\n" for path in paths)).encode("utf-8")


# Mốc: kế hoạch (đọc nguồn, tính bao đóng, dựng nội dung các tệp văn bản)


@dataclass
class Plan:
    registry: Registry
    selection: Selection
    schema: Schema
    images: ImageIndex
    imageset_files: list
    closure: Closure
    textures: TexturePlan
    strings: Strings
    layout_total: int
    texts: dict
    cell_changes: dict
    animate_total: int
    # Tên cảnh của bảng cảnh mà bảng tên tiếng Việt chưa có.
    unnamed_scenes: list
    # Mẫu người chơi không có dòng camera ảnh đầu.
    headless: list


def read_layouts(selection: Selection, source: Source, closure: Closure, texts: dict) -> None:
    loaded = []
    for layout in selection.layouts:
        try:
            data, root = source.read_xml(layout)
        except UiError as error:
            selection.unresolved.append(str(error))
            continue
        texts[f"{INTERFACE}/{layout}"] = data
        closure.visit_layout(root)
        loaded.append(layout)
    selection.layouts = loaded


def select_windows(args: argparse.Namespace, registry: Registry, source: Source) -> Selection:
    if args.all:
        return Selection(layouts=source.matching(".layout.xml"))
    return choose_windows(args.windows or DEFAULT_WINDOWS, registry, source)


def build_plan(args: argparse.Namespace) -> Plan:
    source = Source(args.raw)
    registry = Registry(args.raw, source)
    dictionary = Dictionary(args.raw)
    selection = select_windows(args, registry, source)
    texts: dict[str, bytes] = {}
    schema = load_schema(source, texts)
    images, imageset_files = load_imagesets(source, texts)
    animates = load_animates(source)
    closure = Closure(schema, images, animates)
    read_layouts(selection, source, closure, texts)
    texts[PORTRAITS_TABLE], portraits_changed = portraits_table(args.raw, closure)
    for value in sorted(panel_images()):
        closure.take_image_value(value)
    unnamed_scenes = unnamed_scene_names(args.out)
    texts[HEAD_CAMERAS_TABLE], headless = head_cameras_table(args.raw, args.out)
    texts[f"{INTERFACE}/{ANIMATE_FILE}"] = animate_bytes(animates, closure.used_animates)
    textures = plan_textures(closure, source)
    closure.look_keys |= schema_keys(schema)
    closure.panel_keys = panel_keys()
    used_keys = closure.layout_keys | closure.look_keys | closure.panel_keys
    strings = build_strings(dictionary, used_keys)
    texts[WINDOWS_TABLE], windows_changed = windows_table(registry)
    texts[STRINGS_TABLE], strings_changed = strings_table(strings)
    strings.untranslated = untranslated_keys(strings)
    return Plan(
        registry=registry, selection=selection, schema=schema, images=images,
        imageset_files=imageset_files, closure=closure, textures=textures, strings=strings,
        layout_total=len(source.matching(".layout.xml")), texts=texts,
        cell_changes={"ui_windows": windows_changed, "ui_strings": strings_changed,
                      "portraits": portraits_changed},
        animate_total=len(animates), unnamed_scenes=unnamed_scenes, headless=headless,
    )


def write_outputs(plan: Plan, args: argparse.Namespace) -> Outcome:
    outcome = Outcome()
    out_root = args.out
    for relative in sorted(plan.texts):
        write_file(out_root, relative, plan.texts[relative], outcome)
    write_textures(plan.textures.textures, out_root, args.force, outcome)
    write_fonts(args.raw, out_root, outcome)
    listing = listing_bytes(plan.texts, outcome.png_paths + outcome.font_paths)
    write_file(out_root, LISTING, listing, outcome)
    return outcome


# Mốc: thống kê


def megabytes(size: int) -> str:
    return f"{size / 1048576:.1f} MB"


def texture_lines(plan: Plan, outcome: Outcome | None) -> list[str]:
    counts: Counter = Counter()
    sizes: Counter = Counter()
    for texture in plan.textures.textures:
        kind = os.path.splitext(texture.real)[1].lstrip(".").upper()
        counts[kind] += 1
        sizes[kind] += os.path.getsize(texture.source)
    parts = [f"{kind} {counts[kind]} ({megabytes(sizes[kind])})" for kind in sorted(counts)]
    kinds = ", ".join(parts)
    lines = [
        f"Texture trong bao đóng: {len(plan.textures.textures)}: {kinds}",
        f"  dung lượng gốc: {megabytes(sum(sizes.values()))}",
    ]
    if outcome is not None:
        lines.append(f"  PNG: ghi mới {outcome.png_written}, giữ nguyên {outcome.png_kept}, "
                     f"dung lượng {megabytes(outcome.png_bytes)}")
    if plan.textures.case_mismatch:
        lines.append(f"  tên texture sai hoa/thường so với tệp thật: {plan.textures.case_mismatch} "
                     "(PNG ghi theo tên trong imageset)")
    if plan.textures.spelling_conflicts:
        lines.append(f"  imageset viết một texture theo hai kiểu hoa/thường: "
                     f"{', '.join(plan.textures.spelling_conflicts[:LIST_LIMIT])}")
    return lines


def closure_lines(plan: Plan) -> list[str]:
    closure = plan.closure
    mapped = sum(1 for name in closure.seen_types if name in plan.schema.mappings)
    absent = closure.misses.distinct("kiểu")
    builtin = len(closure.seen_types) - mapped - absent
    used_images = sum(len(names) for names in closure.used.values())
    lines = [
        f"Bao đóng: kiểu {len(closure.seen_types)} (có mapping {mapped}, dựng sẵn {builtin}, "
        f"thiếu {absent}), look {len(closure.seen_looks)}, section {len(closure.seen_sections)}",
        f"  bộ ảnh dùng {len(closure.used)}/{len(plan.images.sets.items)}, "
        f"ảnh dùng {used_images}/{plan.images.image_total}, "
        f"tham chiếu ảnh rỗng bỏ qua {closure.empty_refs}",
        f"  hoạt ảnh dùng {len(closure.used_animates)}/{plan.animate_total}",
    ]
    if closure.folded_refs:
        names = sorted(closure.folded_refs)[:LIST_LIMIT]
        lines.append(f"  tham chiếu ảnh sai hoa/thường (đã nhận): {len(closure.folded_refs)}: "
                     f"{', '.join(names)}")
    return lines


def miss_lines(plan: Plan) -> list[str]:
    kinds = ("ảnh", "bộ ảnh", "section", "look", "kiểu", "texture", "giá trị ảnh sai dạng",
             "hoạt ảnh")
    lines = ["Chưa giải được:"]
    lines += [f"  {plan.closure.misses.describe(kind)}" for kind in kinds]
    if plan.schema.absent_files:
        absent = ", ".join(plan.schema.absent_files)
        lines.append(f"  looknfeel scheme nêu mà không có tệp: {absent}")
    return lines


def string_lines(plan: Plan) -> list[str]:
    closure = plan.closure
    keys = closure.layout_keys | closure.look_keys
    panel_only = closure.panel_keys - keys
    strings = plan.strings
    missing = [repr(key) for key in strings.missing[:LIST_LIMIT]]
    rest = len(strings.missing) - len(missing)
    tail = f" ... còn {rest}" if rest else ""
    return [
        f"Chuỗi: dùng {len(keys | panel_only)} (layout {len(closure.layout_keys)}, mọi look đã "
        f"chép thêm {len(keys - closure.layout_keys)}, mã ui/panel thêm {len(panel_only)}), "
        f"tra được {len(strings.rows)}, thiếu {len(strings.missing)}",
        f"  khoá thiếu: {', '.join(missing) or 'không'}{tail}",
        f"  khoá lặp trong từ điển mà đang dùng (lấy dòng sau): {strings.repeated}; "
        f"ô đổi tab/xuống dòng: ui_strings {plan.cell_changes['ui_strings']}, "
        f"ui_windows {plan.cell_changes['ui_windows']}",
        f"  chưa dịch sang tiếng Việt: {len(strings.untranslated)} khoá "
        f"({', '.join(strings.untranslated[:LIST_LIMIT]) or 'không'})",
        f"  tên cảnh chưa dịch: {len(plan.unnamed_scenes)} "
        f"({', '.join(plan.unnamed_scenes[:LIST_LIMIT]) or 'không'})",
        f"  mẫu người chơi thiếu camera ảnh đầu: {len(plan.headless)} "
        f"({', '.join(plan.headless[:LIST_LIMIT]) or 'không'})",
    ]


def file_lines(plan: Plan) -> list[str]:
    selection = plan.selection
    unresolved = "; ".join(selection.unresolved[:LIST_LIMIT])
    registered = len({layout.lower() for layout in selection.layouts} & plan.registry.layouts())
    return [
        f"Cửa sổ chọn: {len(selection.layouts)} (đã đăng ký {registered}), "
        f"không giải được: {len(selection.unresolved)}" + (f": {unresolved}" if unresolved else ""),
        f"Tệp XML: layout {len(selection.layouts)}/{plan.layout_total}, "
        f"looknfeel {len(plan.schema.look_files)}, scheme {len(plan.schema.scheme_files)}, "
        f"imageset {len(plan.imageset_files)}, font {len(plan.schema.font_files)}",
        f"Dữ liệu gốc: InterfaceEx {len(plan.registry.rows)} dòng (layout sửa hoa/thường "
        f"{plan.registry.case_fixed}, không có tệp {plan.registry.unfound}), "
        f"bộ ảnh trùng tên bỏ qua {len(plan.images.duplicates)}, "
        f"mapping kiểu lặp {plan.schema.duplicate_mappings}",
    ]


def write_lines(outcome: Outcome | None) -> list[str]:
    if outcome is None:
        return ["--dry-run: không ghi gì"]
    lines = [f"Tệp văn bản: ghi {outcome.written}, giữ nguyên {outcome.kept}",
             f"Phông (ui_font.py): {len(outcome.font_paths)} tệp trong danh sách"]
    if outcome.out_of_bounds:
        lines.append(f"Ảnh vượt biên texture: {len(outcome.out_of_bounds)}: "
                     f"{'; '.join(outcome.out_of_bounds[:LIST_LIMIT])}")
    if outcome.failures:
        lines.append(f"Texture không đổi được: {len(outcome.failures)}: "
                     f"{'; '.join(outcome.failures[:LIST_LIMIT])}")
    return lines


def report(plan: Plan, outcome: Outcome | None, elapsed: float) -> None:
    lines = file_lines(plan) + closure_lines(plan) + texture_lines(plan, outcome)
    lines += miss_lines(plan) + string_lines(plan) + write_lines(outcome)
    lines.append(f"Thời gian: {elapsed:.1f} s")
    print("\n".join(lines))


# Mốc: dòng lệnh


def split_names(text: str) -> list[str]:
    names = [name.strip() for name in text.split(",") if name.strip()]
    if not names:
        raise argparse.ArgumentTypeError("danh sách cửa sổ rỗng")
    return names


class VietnameseParser(argparse.ArgumentParser):
    def error(self, message: str):
        print(f"Cách dùng: {USAGE}", file=sys.stderr)
        self.exit(2, f"Lỗi tham số: {message}\n")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = VietnameseParser(prog="collect_ui.py", usage=USAGE, description=DESCRIPTION)
    parser.add_argument("raw", help="kho gốc đã giải gói (_raw)")
    parser.add_argument("out", help="thư mục dữ liệu client (CLIENT/data)")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--windows", type=split_names,
                       help="tên cửa sổ trong InterfaceEx hoặc thư mục/tệp, cách nhau dấu phẩy")
    group.add_argument("--all", action="store_true", help="mọi layout, kể cả layout chưa đăng ký")
    parser.add_argument("--dry-run", action="store_true", help="chỉ tính bao đóng và in thống kê")
    parser.add_argument("--force", action="store_true", help="đổi lại cả PNG đã mới hơn nguồn")
    args = parser.parse_args(argv)
    args.raw = os.path.abspath(args.raw)
    args.out = os.path.abspath(args.out)
    return args


def run(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    plan = build_plan(args)
    outcome = None if args.dry_run else write_outputs(plan, args)
    report(plan, outcome, time.perf_counter() - started)
    failed = bool(plan.selection.unresolved) or (outcome is not None and bool(outcome.failures))
    return 1 if failed else 0


def main() -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    args = parse_args(sys.argv[1:])
    try:
        return run(args)
    except (UiError, dbc.DbcError, ui_font.FontError, UnicodeError) as error:
        print(f"Lỗi dữ liệu: {error}", file=sys.stderr)
    except OSError as error:
        print(f"Lỗi tệp: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
