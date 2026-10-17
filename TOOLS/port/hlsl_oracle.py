#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/port/hlsl_oracle.py
#  PHÂN HỆ   : Port / Hlsl Oracle
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Đối chứng bằng trình dịch của client gốc: gọi D3DCompile của
#    D3DCompiler_43.dll qua ctypes, đọc khối DXBC (SHEX, RDEF, ISGN, OSGN) và
#    so bản gốc với bản đã chuyển của hlsl_origin.py. Quyết định:
#  - Hai bản cùng được dịch với cờ của client gốc (tương thích ngược, gói ma
#    trận theo .program), nên khác nhau ở mã máy là biến đổi đã đổi nghĩa; khác
#    ở RDEF chỉ được là giá trị mặc định (bản đã chuyển bỏ giá trị đầu khỏi
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# nguồn), và giá trị ấy phải bằng đúng số bảng tham số ghi lại.
# - [[vk::location]] không có trong cú pháp fxc; bộ đọc include bỏ nó khi nạp bản đã chuyển.
# - Chỉ chạy trên Windows, cần D3DCompiler_43.dll của client gốc (G:\XTLBB\Bin64).

from __future__ import annotations

import ctypes
import hashlib
import re
import struct
from ctypes import wintypes
from dataclasses import dataclass, field
from pathlib import Path

ENABLE_BACKWARDS_COMPATIBILITY = 0x1000
PACK_MATRIX_ROW_MAJOR = 0x8
PACK_MATRIX_COLUMN_MAJOR = 0x10
LOCATION_ATTRIBUTE = re.compile(rb"\[\[vk::location\(\d+\)\]\] ")
E_FAIL = 0x80004005
# Bản fxc của các macro sampler mà hlsl_origin.py sinh: đổi lại đúng khai báo D3D9 gốc, để oracle
# so được mọi biến đổi còn lại (compat.slang là bản Slang của cùng các macro).
COMPAT_NAME = "origin.compat.fxc"
COMPAT_TEXT = b"""#define ORIGIN_SAMPLER2D(name, slot) sampler2D name : register(s##slot)
#define ORIGIN_SAMPLERCUBE(name, slot) samplerCUBE name : register(s##slot)
#define ORIGIN_SAMPLER2D_ARRAY(name, slot, count) sampler2D name[count] : register(s##slot)
#define ORIGIN_USE2D(name) name
#define ORIGIN_USECUBE(name) name
#define ORIGIN_INDEX2D(name, index) name[index]
"""
# Loại tài nguyên trong RDEF (D3D_SHADER_INPUT_TYPE): ảnh và sampler.
RESOURCE_TEXTURE = 2
RESOURCE_SAMPLER = 3
USER_PACKED = 0x1


class Macro(ctypes.Structure):
    _fields_ = [("Name", ctypes.c_char_p), ("Definition", ctypes.c_char_p)]


OPEN = ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.c_void_p, ctypes.c_int, ctypes.c_char_p,
                          ctypes.c_void_p, ctypes.POINTER(ctypes.c_void_p),
                          ctypes.POINTER(wintypes.UINT))
CLOSE = ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.c_void_p, ctypes.c_void_p)


class Include:
    """ID3DInclude: tìm tệp cạnh tệp đang include, rồi ở các thư mục gốc, như OGRE nạp theo tên."""

    def __init__(self, main_folder: Path, roots: list[Path], strip_locations: bool):
        self.roots = roots
        self.strip_locations = strip_locations
        self.buffers: dict[int, tuple[ctypes.Array, Path]] = {}
        self.main_folder = main_folder
        self.opened: list[Path] = []
        self.open_callback = OPEN(self.open)
        self.close_callback = CLOSE(self.close)
        open_address = ctypes.cast(self.open_callback, ctypes.c_void_p)
        close_address = ctypes.cast(self.close_callback, ctypes.c_void_p)
        self.table = (ctypes.c_void_p * 2)(open_address, close_address)
        self.object = (ctypes.c_void_p * 1)(ctypes.cast(self.table, ctypes.c_void_p))

    def load(self, path: Path) -> bytes:
        data = path.read_bytes()
        return LOCATION_ATTRIBUTE.sub(b"", data) if self.strip_locations else data

    def serve(self, data: bytes, path: Path, out_data, out_bytes) -> int:
        buffer = ctypes.create_string_buffer(data, len(data))
        self.buffers[ctypes.addressof(buffer)] = (buffer, path)
        self.opened.append(path)
        out_data[0] = ctypes.addressof(buffer)
        out_bytes[0] = len(data)
        return 0

    def open(self, this, kind, name, parent, out_data, out_bytes) -> int:
        relative = name.decode("ascii")
        if relative == COMPAT_NAME:
            return self.serve(COMPAT_TEXT, self.main_folder / COMPAT_NAME, out_data, out_bytes)
        parent_entry = self.buffers.get(parent or 0)
        folder = parent_entry[1].parent if parent_entry else self.main_folder
        for root in [folder, *self.roots]:
            path = root / relative
            if path.is_file():
                return self.serve(self.load(path), path, out_data, out_bytes)
        return E_FAIL

    def close(self, this, data) -> int:
        # Bộ đệm sống tới hết lần dịch (Include huỷ cùng lần dịch) để con trỏ cha luôn tra được.
        return 0


def read_blob(address: int | None) -> bytes:
    if not address:
        return b""
    table = ctypes.cast(ctypes.cast(address, ctypes.POINTER(ctypes.c_void_p))[0],
                        ctypes.POINTER(ctypes.c_void_p))
    release = ctypes.WINFUNCTYPE(ctypes.c_ulong, ctypes.c_void_p)(table[2])
    pointer = ctypes.WINFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p)(table[3])
    size = ctypes.WINFUNCTYPE(ctypes.c_size_t, ctypes.c_void_p)(table[4])
    data = ctypes.string_at(pointer(address), size(address))
    release(address)
    return data


@dataclass
class Compiled:
    result: int
    code: bytes
    messages: str
    opened: list[Path]


class Fxc:
    def __init__(self, dll: Path):
        self.library = ctypes.WinDLL(str(dll))
        compile_function = self.library.D3DCompile
        compile_function.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p,
                                     ctypes.POINTER(Macro), ctypes.c_void_p, ctypes.c_char_p,
                                     ctypes.c_char_p, wintypes.UINT, wintypes.UINT,
                                     ctypes.POINTER(ctypes.c_void_p),
                                     ctypes.POINTER(ctypes.c_void_p)]
        compile_function.restype = ctypes.c_long
        self.compile_function = compile_function

    def compile(self, source: bytes, name: str, include: Include, entry: str, target: str,
                defines: list[tuple[str, str]], flags: int) -> Compiled:
        pairs = [Macro(key.encode("ascii"), value.encode("ascii")) for key, value in defines]
        macros = (Macro * (len(pairs) + 1))(*pairs, Macro(None, None))
        code = ctypes.c_void_p()
        errors = ctypes.c_void_p()
        include_address = ctypes.cast(include.object, ctypes.c_void_p)
        result = self.compile_function(source, len(source), name.encode("ascii"), macros,
                                       include_address, entry.encode("ascii"),
                                       target.encode("ascii"), flags, 0, ctypes.byref(code),
                                       ctypes.byref(errors))
        messages = read_blob(errors.value).decode("utf-8", "replace")
        return Compiled(result & 0xFFFFFFFF, read_blob(code.value), messages, include.opened)


# ---------------------------------------------------------------------------------------------
# Đọc DXBC


def chunks(data: bytes) -> dict[str, bytes]:
    if data[:4] != b"DXBC":
        return {}
    count = struct.unpack_from("<I", data, 28)[0]
    found = {}
    for index in range(count):
        offset = struct.unpack_from("<I", data, 32 + 4 * index)[0]
        tag = data[offset:offset + 4].decode("ascii", "replace")
        size = struct.unpack_from("<I", data, offset + 4)[0]
        found[tag] = data[offset + 8:offset + 8 + size]
    return found


def c_string(data: bytes, offset: int) -> str:
    end = data.index(b"\0", offset)
    return data[offset:end].decode("ascii", "replace")


@dataclass(frozen=True)
class TypeInfo:
    kind: int
    scalar: int
    rows: int
    columns: int
    elements: int
    members: tuple


@dataclass(frozen=True)
class Variable:
    name: str
    start: int
    size: int
    flags: int
    type: TypeInfo
    default: bytes | None


@dataclass(frozen=True)
class Reflection:
    buffers: tuple
    resources: tuple


def read_type(rdef: bytes, offset: int) -> TypeInfo:
    kind, scalar, rows, columns, elements, member_count, member_offset = struct.unpack_from(
        "<HHHHHHI", rdef, offset)
    members = []
    for index in range(member_count):
        name_offset, type_offset, start = struct.unpack_from("<III", rdef, member_offset + 12 * index)
        member_type = read_type(rdef, type_offset)
        members.append((c_string(rdef, name_offset), start, member_type))
    return TypeInfo(kind, scalar, rows, columns, elements, tuple(members))


def reflect(rdef: bytes) -> Reflection:
    # Bố cục RDEF của D3D11 (shader model 5: mô tả biến 40 byte).
    buffer_count, buffer_offset, resource_count, resource_offset = struct.unpack_from("<IIII", rdef, 0)
    version = struct.unpack_from("<I", rdef, 16)[0] & 0xFFFF
    stride = 40 if version >= 0x500 else 24
    resources = []
    for index in range(resource_count):
        fields = struct.unpack_from("<IIIIIIII", rdef, resource_offset + 32 * index)
        resources.append((c_string(rdef, fields[0]), *fields[1:]))
    buffers = []
    for index in range(buffer_count):
        name_offset, variable_count, variable_offset, size, flags, kind = struct.unpack_from(
            "<IIIIII", rdef, buffer_offset + 24 * index)
        variables = []
        for slot in range(variable_count):
            base = variable_offset + stride * slot
            name, start, var_size, var_flags, type_offset, default_offset = struct.unpack_from(
                "<IIIIII", rdef, base)
            default = rdef[default_offset:default_offset + var_size] if default_offset else None
            var_type = read_type(rdef, type_offset)
            variables.append(Variable(c_string(rdef, name), start, var_size, var_flags, var_type,
                                      default))
        buffers.append((c_string(rdef, name_offset), size, flags, kind, tuple(variables)))
    return Reflection(tuple(buffers), tuple(resources))


def comparable_resource(resource: tuple) -> tuple:
    # Ảnh và sampler: fxc đặt tên tài nguyên là tham số của hàm vào bằng "$tên", bản đã chuyển
    # khai chúng ở cấp ngoài cùng nên không có '$'; sampler gốc không ghi register thì bản đã
    # chuyển ghi ô fxc đã chọn, nên cờ D3D_SIF_USERPACKED (bit 0) khác. Ô gắn và số ô vẫn phải
    # bằng nhau. Bộ đệm hằng ($Globals, $Params) so nguyên.
    name, kind, *middle, flags = resource
    if kind not in (RESOURCE_TEXTURE, RESOURCE_SAMPLER):
        return resource
    return (name.removeprefix("$"), kind, *middle, flags & ~USER_PACKED)


def layout(reflection: Reflection) -> tuple:
    # Mọi thứ của RDEF trừ giá trị mặc định.
    buffers = []
    for name, size, flags, kind, variables in reflection.buffers:
        shapes = tuple((v.name, v.start, v.size, v.flags, v.type) for v in variables)
        buffers.append((name, size, flags, kind, shapes))
    resources = tuple(comparable_resource(resource) for resource in reflection.resources)
    return tuple(buffers), resources


# ---------------------------------------------------------------------------------------------
# Giá trị mặc định


SCALAR_FORMATS = {1: "<i", 2: "<i", 3: "<f", 19: "<I"}
NUMBER = re.compile(r"[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?[fFhHlLuU]*|true|false")
CONSTRUCTOR = re.compile(r"\b(?:float|half|int|uint|bool|double)(?:[1-4](?:x[1-4])?)?\s*\(")


def literal_values(text: str) -> list[float] | None:
    # Số trong giá trị đầu dạng hằng (số, {..}, floatN(..)); None khi có phép tính.
    stripped = CONSTRUCTOR.sub("(", text)
    rest = NUMBER.sub("", stripped)
    if re.sub(r"[\s(){},]", "", rest):
        return None
    values = []
    for match in NUMBER.finditer(stripped):
        token = match.group()
        if token in ("true", "false"):
            values.append(1.0 if token == "true" else 0.0)
            continue
        values.append(float(token.rstrip("fFhHlLuU")))
    return values


def stored_values(variable: Variable) -> list[float]:
    # Đọc giá trị mặc định theo thứ tự viết trong HLSL (phần tử, hàng, cột).
    info = variable.type
    unpack = SCALAR_FORMATS.get(info.scalar)
    if unpack is None or info.members:
        raise ValueError(f"kiểu chưa đọc được (lớp {info.kind}, loại {info.scalar})")
    rows, columns = (info.rows, info.columns) if info.kind >= 2 else (1, info.columns)
    registers = rows if info.kind != 3 else columns
    element_stride = 16 * registers
    data = variable.default
    values = []
    for element in range(max(info.elements, 1)):
        for row in range(rows):
            for column in range(columns):
                register, lane = (row, column) if info.kind != 3 else (column, row)
                offset = element * element_stride + register * 16 + lane * 4
                values.append(float(struct.unpack_from(unpack, data, offset)[0]))
    return values


def same_number(left: float, right: float) -> bool:
    # fxc lưu float 32 bit; giá trị viết trong nguồn đọc ở double nên so theo float 32 bit.
    packed_left = struct.unpack("<f", struct.pack("<f", left))[0]
    packed_right = struct.unpack("<f", struct.pack("<f", right))[0]
    return packed_left == packed_right


def check_default(variable: Variable, text: str | None) -> str | None:
    if text is None:
        return f"mặc định của {variable.name} không được ghi lại"
    written = literal_values(text)
    if written is None:
        return f"mặc định của {variable.name} không phải hằng: {text}"
    try:
        stored = stored_values(variable)
    except ValueError as error:
        return f"{variable.name}: {error}"
    if len(written) == 1 and len(stored) > 1:
        written = written * len(stored)
    if len(written) != len(stored):
        return f"mặc định của {variable.name}: ghi {len(written)} số, fxc lưu {len(stored)}"
    pairs = zip(written, stored)
    if not all(same_number(left, right) for left, right in pairs):
        return f"mặc định của {variable.name}: ghi {written}, fxc lưu {stored}"
    return None


# ---------------------------------------------------------------------------------------------
# So một chương trình


@dataclass
class Report:
    problems: list[str] = field(default_factory=list)
    original_hash: str = ""
    original_code: bytes = b""


def flags_of(program) -> int:
    # OGRE D3D11: column_major_matrices false là gói theo hàng, còn lại theo cột.
    packing = PACK_MATRIX_ROW_MAJOR if program.column_major == "false" else PACK_MATRIX_COLUMN_MAJOR
    return ENABLE_BACKWARDS_COMPATIBILITY | packing


def split_pairs(defines) -> list[tuple[str, str]]:
    return [tuple(define.split("=", 1)) for define in defines]


def compare(compiler: Fxc, program, source_root: Path, built_root: Path, defaults: dict[str, str],
            built_defines, flags: int | None = None) -> Report:
    # built_defines: define của gói (của .program cộng macro bật hàm vào); bản gốc dịch với define
    # của .program như client gốc.
    report = Report()
    target = f"{program.stage}_5_0"
    chosen = flags_of(program) if flags is None else flags
    defines = split_pairs(program.defines)
    original_path = source_root / program.source
    original_include = Include(original_path.parent, [source_root, source_root / "ShaderLib"], False)
    original_source = original_include.load(original_path)
    original = compiler.compile(original_source, original_path.name, original_include,
                                program.entry, target, defines, chosen)
    # Bản đã chuyển dịch qua một tệp bọc: macro sampler bản fxc rồi tới nguồn.
    built_include = Include(built_root, [built_root, built_root / "ShaderLib"], True)
    wrapper = f'#include "{COMPAT_NAME}"\n#include "{program.source}"\n'.encode("ascii")
    built = compiler.compile(wrapper, "origin.wrap.hlsl", built_include, program.entry, target,
                             split_pairs(built_defines), chosen)
    if original.result:
        report.problems.append(f"bản gốc không dịch được: {first_error(original.messages)}")
        return report
    if built.result:
        report.problems.append(f"bản đã chuyển không dịch được: {first_error(built.messages)}")
        return report
    report.original_code = original.code
    report.original_hash = hashlib.sha1(original.code).hexdigest()
    left = chunks(original.code)
    right = chunks(built.code)
    for tag in ("SHEX", "SHDR", "ISGN", "OSGN", "PCSG"):
        if left.get(tag) != right.get(tag):
            report.problems.append(f"khối {tag} khác")
    left_reflection = reflect(left["RDEF"])
    right_reflection = reflect(right["RDEF"])
    if layout(left_reflection) != layout(right_reflection):
        report.problems.append("bố cục RDEF khác")
        return report
    for buffer in left_reflection.buffers:
        report.problems += default_problems(buffer[4], defaults)
    return report


def default_problems(variables, defaults: dict[str, str]) -> list[str]:
    problems = []
    for variable in variables:
        if variable.default is None:
            continue
        problem = check_default(variable, defaults.get(variable.name))
        if problem:
            problems.append(problem)
    return problems


def first_error(messages: str) -> str:
    match = re.search(r"error X\d+: [^\n]*", messages)
    return match.group() if match else messages.strip()[:200]


def cache_index(cache: Path) -> dict[str, str]:
    # Băm SHA-1 nội dung của từng tệp ShaderCache: tên tệp.
    index = {}
    for path in sorted(cache.iterdir()):
        if path.is_file():
            index.setdefault(hashlib.sha1(path.read_bytes()).hexdigest(), path.name)
    return index
