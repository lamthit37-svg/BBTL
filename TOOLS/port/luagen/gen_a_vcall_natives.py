# +---------------------------------------------------------------+
# | THIENLONG                                                     |
# | Tệp: TOOLS/port/luagen/gen_a_vcall_natives.py                 |
# | - Sinh src/client/face/ui/script/native_a_vcall.cpp: hàm game |
# |   của Game.exe 2026 mà thân chỉ đẩy kết quả của một hàm ảo:   |
# |   getter của CDataPool và phương thức của ActionItem rỗng.    |
# | Dev : HiepHoon   Tele : @Hoon9xx                              |
# +---------------------------------------------------------------+

"""Sinh src/client/face/ui/script/native_a_vcall.cpp từ decompile và mã máy của Game.exe 2026 (bản 9001, đúng tệp của decompile).

Hai nhóm hàm có thân chỉ là "gọi một hàm ảo rồi đẩy kết quả", mà gen_pool_natives.py không nhận vì đích của lời gọi nằm trong vtable:

1. Getter ảo của CDataPool (DAT_141034c40):
       T v = (**(code **)(*DAT_141034c40 + OFF))(); lua_pushnumber(*P,(double)v); lua_gettop(*P); return 1;
   Ô OFF của vtable CDataPool (RTTI, 0x140a6f5e8) trỏ tới một hàm lá `mov/movzx/movsx eax, [rcx + X]; ret`: đọc trường X của kho. Giá trị
   lấy như native_pool.cpp: Facts::pool, chưa ghi thì giá trị hàm dựng CDataPool đặt (ConstructorImage của gen_pool_natives.py).
2. Phương thức của bảng ActionItem (ActionButtonMetaTable, metatable DAT_141034670) khi đối tượng là ActionItem rỗng (CActionItem
   s_InvalidAction ở 0x140ed9180, vtable 0x140a41cb8): EnumAction trả nó khi CActionSystem không có action ở vị trí đó, và client này chưa
   có ActionSystem nên mọi EnumAction trả nó. Thân dạng `T v = (**(code **)(*param_1 + OFF))(); lua_pushnumber/lua_pushstring(*P, v); ...`;
   hàm lá ở ô OFF của vtable CActionItem trả hằng (`xor eax,eax`, `or eax,-1`, `mov eax, imm`), một trường của s_InvalidAction (ảnh
   do hàm khởi tạo tĩnh 0x140a102a0 ghi, xem INVALID_ACTION) hay chuỗi (hằng `lea rax,[rip+X]`, hay std::string rỗng ở +0x10).

Hàm có thêm việc khác (kiểm đối số, nhánh) thì không sinh ở đây mà port tay. Tên (bảng, hàm) đã có native ở tệp native_*.cpp khác thì bỏ.

cách dùng (ở gốc dự án; cần capstone):
    python -B -X utf8 TOOLS/port/luagen/gen_a_vcall_natives.py [--exe D:/rea/work/client/Game.exe] [--write]
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import pathlib
import re
import struct
import sys

import capstone

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "source_headers"))
import source_frame  # noqa: E402
import gen_event_natives as events  # noqa: E402
import gen_pool_natives as pool  # noqa: E402

OUT = events.SCRIPT_DIR / "native_a_vcall.cpp"
EXE_SHA256 = "3f8bb47de0bc0b233421ebd96957c23209ba1f7ee4924902de0511439ba1a9d6"  # bản 9001 mà decompile.zip phân tích (README)
DATA_POOL_VTABLE = 0x140A6F5E8
ACTION_VTABLE = 0x140A41CB8
ACTION_TABLE = "ActionButtonMetaTable"
# Ảnh s_InvalidAction sau hàm khởi tạo tĩnh 0x140a102a0 (mã máy): +8 m_ID = 0, +0x60 = 0, +0x64 = 1, byte +0x6c = 0; +0x10 là std::string
# rỗng (FUN_140001840). Trường khác của CActionItem không được ghi ở đó và .data của nó là 0.
INVALID_ACTION = {8: 0, 0x60: 0, 0x64: 1}
INVALID_ACTION_BYTES = {0x6C: 0}

LUA_TYPES = {"int": (4, True), "uint": (4, False), "undefined4": (4, True), "byte": (1, False), "char": (1, True), "short": (2, True), "ushort": (2, False)}
WIDTHS = {(1, False): "kU8", (1, True): "kI8", (2, False): "kU16", (2, True): "kI16", (4, False): "kU32", (4, True): "kI32"}
POOL_TYPE = {(1, False): "byte", (1, True): "char", (2, False): "ushort", (2, True): "short", (4, False): "uint", (4, True): "int"}

POOL_CALL = re.compile(
    r"^(?P<t>\w+) (?P<v>\w+); (?P=v) = \(\*\*\(code \*\*\)\(\*DAT_141034c40 \+ (?P<off>0x[0-9a-f]+|\d+)\)\)\(\); "
    r"lua_pushnumber\(\*param_(?P<p>\d),\(double\)(?P=v)\); lua_gettop\(\*param_(?P=p)\); return 1;$"
)
ACTION_NUMBER = re.compile(
    r"^(?P<t>\w+) (?P<v>\w+); (?P=v) = \(\*\*\(code \*\*\)(?:\*param_1|\(\*param_1 \+ (?P<off>0x[0-9a-f]+|\d+)\))\)\(\); "
    r"lua_pushnumber\(\*param_2,\(double\)(?P=v)\); lua_gettop\(\*param_2\); return 1;$"
)
ACTION_STRING = re.compile(
    r"^(?P<t>\w+) (?P<v>\w+); (?P=v) = \(\*\*\(code \*\*\)(?:\*param_1|\(\*param_1 \+ (?P<off>0x[0-9a-f]+|\d+)\))\)\(\); "
    r"lua_pushstring\(\*param_2,(?P=v)\); lua_gettop\(\*param_2\); return 1;$"
)


class Image:
    """Tệp PE chỉ đọc: đọc qword, chuỗi C và tháo hàm lá."""

    def __init__(self, path: pathlib.Path) -> None:
        self.data = path.read_bytes()
        digest = hashlib.sha256(self.data).hexdigest()
        if digest != EXE_SHA256:
            raise SystemExit(f"{path}: SHA-256 {digest} không phải bản 9001 của decompile ({EXE_SHA256})")
        header = struct.unpack_from("<I", self.data, 0x3C)[0]
        count = struct.unpack_from("<H", self.data, header + 6)[0]
        optional = struct.unpack_from("<H", self.data, header + 20)[0]
        self.base = struct.unpack_from("<Q", self.data, header + 24 + 24)[0]
        table = header + 24 + optional
        self.sections = [struct.unpack_from("<8sIIII", self.data, table + 40 * index) for index in range(count)]
        self.disasm = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_64)

    def offset(self, address: int) -> int:
        relative = address - self.base
        for _, virtual_size, virtual_address, raw_size, raw_pointer in self.sections:
            if virtual_address <= relative < virtual_address + min(virtual_size, raw_size):
                return raw_pointer + relative - virtual_address
        raise ValueError(f"{address:#x} không nằm trong phần có dữ liệu của tệp")

    def qword(self, address: int) -> int:
        return struct.unpack_from("<Q", self.data, self.offset(address))[0]

    def c_string(self, address: int) -> bytes:
        start = self.offset(address)
        return self.data[start:self.data.index(b"\0", start)]

    def leaf(self, address: int, depth: int = 0) -> list[tuple[str, str, int]]:
        """Lệnh của hàm lá tới ret đầu tiên (theo jmp thẳng tối đa 4 lần): (mnemonic, toán hạng, địa chỉ lệnh kế)."""
        start = self.offset(address)
        result = []
        for instruction in self.disasm.disasm(self.data[start:start + 64], address):
            result.append((instruction.mnemonic, instruction.op_str, instruction.address + instruction.size))
            if instruction.mnemonic in ("ret", "repz ret"):
                return result
            if instruction.mnemonic == "jmp":
                target = re.fullmatch(r"0x([0-9a-f]+)", instruction.op_str)
                if target and len(result) == 1 and depth < 4:
                    return self.leaf(int(target.group(1), 16), depth + 1)
                return []
            if len(result) > 6:
                return []
        return []


LOAD = re.compile(r"^(?:(?P<op>movzx|movsx) eax, (?P<w>byte|word) ptr|mov eax, dword ptr) \[rcx \+ (?P<x>0x[0-9a-f]+|\d+)\]$")


def field_read(code: list[tuple[str, str, int]]) -> tuple[int, int, bool] | None:
    """(offset, cỡ byte, có dấu) khi hàm lá là đúng một lần đọc trường của rcx rồi ret."""
    if len(code) != 2 or code[1][0] not in ("ret", "repz ret"):
        return None
    found = LOAD.match(f"{code[0][0]} {code[0][1]}")
    if not found:
        return None
    size = {"byte": 1, "word": 2}.get(found["w"] or "", 4)
    return int(found["x"], 0), size, found["op"] == "movsx" or size == 4


def constant(code: list[tuple[str, str, int]]) -> int | None:
    """Hằng mà hàm lá trả trong eax, hay giá trị trường của s_InvalidAction mà nó đọc."""
    if not code or code[-1][0] not in ("ret", "repz ret") or len(code) != 2:
        return None
    mnemonic, operands, _ = code[0]
    if mnemonic == "xor" and operands == "eax, eax":
        return 0
    if mnemonic == "or" and operands == "eax, 0xffffffff":
        return -1
    found = re.fullmatch(r"eax, (0x[0-9a-f]+|\d+)", operands)
    if mnemonic == "mov" and found:
        value = int(found.group(1), 0) & 0xFFFFFFFF
        return value - (1 << 32) if value >= 1 << 31 else value
    read = field_read(code)
    if read and read[1] == 4 and read[0] in INVALID_ACTION:
        return INVALID_ACTION[read[0]]
    if read and read[1] == 1 and read[0] in INVALID_ACTION_BYTES:
        return INVALID_ACTION_BYTES[read[0]]
    return None


def text_constant(image: Image, code: list[tuple[str, str, int]]) -> bytes | None:
    """Chuỗi mà hàm lá trả trong rax: hằng `lea rax, [rip + X]` hay std::string ở +0x10 của s_InvalidAction (rỗng)."""
    if len(code) == 2 and code[0][0] == "lea":
        found = re.fullmatch(r"rax, \[rip \+ (0x[0-9a-f]+)\]", code[0][1])
        if found:
            return image.c_string(code[0][2] + int(found.group(1), 16))
    shape = [f"{mnemonic} {operands}" for mnemonic, operands, _ in code]
    if shape[:2] == ["cmp qword ptr [rcx + 0x28], 0x10", "lea rax, [rcx + 0x10]"]:
        return b""
    return None


@dataclasses.dataclass(frozen=True)
class PoolRow:
    table: str
    name: str
    address: str
    source: pool.Source
    note: str


@dataclasses.dataclass(frozen=True)
class ActionRow:
    name: str
    address: str
    number: int | None
    text: bytes | None
    note: str


def implemented_pairs() -> set[tuple[str, str]]:
    """(bảng, tên) đã có native ở native_*.cpp khác: dòng `.table = "T", .name = "N"` (tệp sinh) hay `.name = "N"` trong tệp có
    register_table(lua, "T", ...) (bảng rỗng là register_globals)."""
    done: set[tuple[str, str]] = set()
    for path in events.SCRIPT_DIR.glob("native_*.cpp"):
        if path == OUT:
            continue
        text = path.read_text(encoding="utf-8")
        for table, name in re.findall(r'\.table = (?:"(\w+)"|nullptr), \.name = "(\w+)"', text):
            done.add((table, name))
        tables = set(re.findall(r'register_table\(lua, "(\w+)"', text))
        if "register_globals" in text:
            tables.add("")
        if "natives.cpp" in path.name or "native_target" in path.name:
            pass
        for name in re.findall(r'\{\.name = "(\w+)"', text):
            for table in tables:
                done.add((table, name))
    text = (events.SCRIPT_DIR / "natives.cpp").read_text(encoding="utf-8")
    for name in re.findall(r'\{\.name = "(\w+)"', text):
        done.add(("DataPool", name))
    return done


def api_rows() -> list[tuple[str, str, str]]:
    """(bảng Lua hay rỗng, tên, địa chỉ) của mọi hàm trong lua_api.tsv (kể cả phương thức ActionItem không có tên bảng toàn cục)."""
    rows = []
    for line in open(events.GAME / "lua_api.tsv", encoding="utf-8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 4 or parts[0] == "table" or not parts[3].startswith("0x"):
            continue
        meta, table, name, address = parts[0], parts[1], parts[2], parts[3].lower()
        rows.append((ACTION_TABLE if meta == ACTION_TABLE else table, name, address))
    return rows


def lua_width(kind: str, read_size: int, read_signed: bool) -> tuple[int, bool]:
    """Độ rộng và dấu của giá trị Lua thấy: hàm lá đọc read_size byte vào eax (mở rộng theo dấu của lệnh), hàm Lua cất vào biến kiểu kind."""
    size, signed = LUA_TYPES[kind]
    return (read_size, read_signed) if read_size < size else (size, signed)


def generate(image: Image) -> tuple[list[PoolRow], list[ActionRow], dict[bool, pool.ConstructorImage]]:
    done = implemented_pairs()
    rows = [row for row in api_rows() if (row[0], row[1]) not in done]
    bodies = events.bodies_of({address for _, _, address in rows})
    constructor = pool.ConstructorImage(pool.CTOR)
    pool_rows: list[PoolRow] = []
    action_rows: list[ActionRow] = []
    seen: set[tuple[str, str]] = set()
    for table, name, address in sorted(rows):
        body = bodies.get(address)
        if body is None or (table, name) in seen:
            continue
        text = pool.inner(pool.normalise(body))
        if table == ACTION_TABLE:
            found = ACTION_NUMBER.match(text) or ACTION_STRING.match(text)
            if not found or (found.re is ACTION_NUMBER and found["t"] not in LUA_TYPES):
                continue
            slot = int(found["off"] or "0", 0)
            target = image.qword(ACTION_VTABLE + slot)
            code = image.leaf(target)
            note = f"{address}, ô {slot:#x} của vtable CActionItem -> {target:#x}"
            if found.re is ACTION_NUMBER:
                value = constant(code)
                if value is None:
                    continue
                size, signed = LUA_TYPES[found["t"]]
                value &= (1 << (8 * size)) - 1
                if signed and value >= 1 << (8 * size - 1):
                    value -= 1 << (8 * size)
                action_rows.append(ActionRow(name, address, value, None, note))
            else:
                value_text = text_constant(image, code)
                if value_text is None:
                    continue
                action_rows.append(ActionRow(name, address, None, value_text, note))
            seen.add((table, name))
            continue
        found = POOL_CALL.match(text)
        if not found or found["t"] not in LUA_TYPES:
            continue
        slot = int(found["off"], 0)
        target = image.qword(DATA_POOL_VTABLE + slot)
        read = field_read(image.leaf(target))
        if read is None:
            continue
        size, signed = lua_width(found["t"], read[1], read[2])
        source = pool.Source(read[0], POOL_TYPE[(size, signed)])
        if constructor.initial(source) is None:
            continue
        seen.add((table, name))
        pool_rows.append(PoolRow(table, name, address, source, f"{address}, ô {slot:#x} của vtable CDataPool -> {target:#x}"))
    return pool_rows, action_rows, {False: constructor}


def cpp_bytes(text: bytes) -> str:
    """Chuỗi C++ cho byte GBK/ASCII của exe: byte ngoài ASCII in viết thoát \\x để không phụ thuộc mã hoá tệp."""
    out = []
    for byte in text:
        if 0x20 <= byte < 0x7F and byte not in (0x22, 0x5C):
            out.append(chr(byte))
        else:
            out.append(f'\\x{byte:02x}""')
    return '"' + "".join(out) + '"'


def render(pool_rows: list[PoolRow], action_rows: list[ActionRow], images: dict[bool, pool.ConstructorImage]) -> str:
    initial = []
    for source in sorted({row.source for row in pool_rows}, key=lambda s: (s.offset, s.type)):
        value, note = images[False].initial(source)  # type: ignore[misc]
        if value != 0:
            size, signed = pool.TYPES[source.type]
            initial.append(f"    {{.offset = {source.offset:#x}, .width = Width::{WIDTHS[(size, signed)]}, .value = {value}}}, // {note}")
    frame = source_frame.render_frame("//", "src/client/face/ui/script/native_a_vcall.cpp", [
        "Sinh bằng TOOLS/port/luagen/gen_a_vcall_natives.py từ decompile và mã máy của Game.exe 2026 (bản 9001); không sửa tay (sửa bộ sinh rồi sinh lại).",
        "Hàm game mà thân chỉ đẩy kết quả một hàm ảo: getter của CDataPool (đọc Facts::pool) và phương thức của ActionItem rỗng mà EnumAction trả.",
        "Khác gốc: client chưa có CActionSystem nên EnumAction luôn trả ActionItem rỗng (s_InvalidAction), như gốc khi vị trí không có action.",
    ])
    lines = [
        *frame,
        "",
        '#include "lua/capi.hpp"',
        '#include "lua/native.hpp"',
        '#include "ui/script/context.hpp"',
        '#include "ui/script/native_groups.hpp"',
        '#include "ui/script/native_support.hpp"',
        '#include "ui/script/pool_image.hpp"',
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <expected>",
        "#include <span>",
        "#include <string_view>",
        "#include <utility>",
        "",
        "namespace game::ui::script {",
        "namespace {",
        "",
        "using lua::NativeError;",
        "using lua::NativeResult;",
        "",
        "struct Getter {",
        "    const char* table = nullptr; // nullptr là hàm toàn cục",
        "    const char* name = nullptr;",
        "    PoolField field;",
        "};",
        "",
        "// Getter ảo của CDataPool: hàm lá ở ô vtable đọc đúng một trường (độ rộng và dấu là của giá trị Lua thấy).",
        f"constexpr std::array<Getter, {len(pool_rows)}> kGetters = {{{{",
    ]
    for row in pool_rows:
        size, signed = pool.TYPES[row.source.type]
        table_text = events.cpp_string(row.table) if row.table else "nullptr"
        lines.append(f"    {{.table = {table_text}, .name = {events.cpp_string(row.name)}, .field = {{.offset = {row.source.offset:#x}, "
                     f".width = Width::{WIDTHS[(size, signed)]}}}}}, // {row.note}")
    lines += [
        "}};",
        "",
        "// Giá trị đầu khác 0 của các trường trên theo hàm dựng CDataPool 0x1400dec40 (trường không có ở đây là 0).",
        f"constexpr std::array<PoolInitial, {len(initial)}> kInitial = {{{{",
        *initial,
        "}};",
        "",
        "template <std::size_t Index>",
        "NativeResult pool_number(lua_State* lua) {",
        "    constexpr const Getter& getter = kGetters.at(Index);",
        "    lua_pushnumber(lua, static_cast<double>(native::context_of(lua).facts.pool.read(getter.field, kInitial)));",
        "    return 1;",
        "}",
        "",
        "template <std::size_t... Index>",
        "constexpr std::array<native::Entry, sizeof...(Index)> make_getters(std::index_sequence<Index...>) {",
        "    return {{{.name = kGetters.at(Index).name, .function = &lua::adapt<pool_number<Index>>}...}};",
        "}",
        "",
        "constexpr std::array kGetterEntries = make_getters(std::make_index_sequence<kGetters.size()>{});",
        "",
        "// Phương thức của ActionItem rỗng: số (text == nullptr) hay chuỗi hằng.",
        "struct ActionMethod {",
        "    const char* name = nullptr;",
        "    double number = 0;",
        "    const char* text = nullptr;",
        "};",
        "",
        f"constexpr std::array<ActionMethod, {len(action_rows)}> kActionMethods = {{{{",
    ]
    for row in action_rows:
        if row.text is None:
            lines.append(f"    {{.name = {events.cpp_string(row.name)}, .number = {row.number}}}, // {row.note}")
        else:
            lines.append(f"    {{.name = {events.cpp_string(row.name)}, .text = {cpp_bytes(row.text)}}}, // {row.note}")
    lines += [
        "}};",
        "",
        "template <std::size_t Index>",
        "NativeResult action_method(lua_State* lua) {",
        "    constexpr const ActionMethod& method = kActionMethods.at(Index);",
        "    if (method.text == nullptr) {",
        "        lua_pushnumber(lua, method.number);",
        "    } else {",
        "        lua_pushstring(lua, method.text);",
        "    }",
        "    return 1;",
        "}",
        "",
        "template <std::size_t... Index>",
        "constexpr std::array<native::Entry, sizeof...(Index)> make_methods(std::index_sequence<Index...>) {",
        "    return {{{.name = kActionMethods.at(Index).name, .function = &lua::adapt<action_method<Index>>}...}};",
        "}",
        "",
        "constexpr std::array kActionEntries = make_methods(std::make_index_sequence<kActionMethods.size()>{});",
        "",
        "// Khoá registry của metatable ActionItem (gốc: DAT_141034670, LuaObject tạo lúc khởi động hệ script).",
        "[[nodiscard]] void* action_metatable_key() noexcept {",
        "    static char key = 0;",
        "    return &key;",
        "}",
        "",
        "// EnumAction(vị trí, \"bộ lọc\") (0x1402348b0): đối số 1 số nghiêm, đối số 2 chuỗi hay số, sai thì câu lỗi của gốc. Gốc hỏi",
        "// CActionSystem (DAT_141034678, ô 0xb8) action thứ vị trí trong bộ lọc, không có thì đóng hộp s_InvalidAction; cả hai gắn metatable",
        "// ActionItem. Khác gốc: chưa có CActionSystem nên luôn đóng hộp ActionItem rỗng (userdata 8 byte, giữ nullptr).",
        "NativeResult enum_action(lua_State* lua) {",
        "    if (!native::strict_number(lua, 1)) return std::unexpected(NativeError::of(\"LUA: EnumAction Wrong Param1\"));",
        "    if (!native::text_arg(lua, 2)) return std::unexpected(NativeError::of(\"LUA: EnumAction Wrong Param2\"));",
        "    void* const box = lua_newuserdata(lua, sizeof(void*));",
        "    *static_cast<void**>(box) = nullptr;",
        "    lua_pushlightuserdata(lua, action_metatable_key());",
        "    lua_rawget(lua, LUA_REGISTRYINDEX);",
        "    lua_setmetatable(lua, -2);",
        "    return 1;",
        "}",
        "",
        "constexpr std::array<native::Entry, 1> kGlobals = {{",
        "    {.name = \"EnumAction\", .function = &lua::adapt<enum_action>},",
        "}};",
        "",
        "} // namespace",
        "",
        "void register_a_vcall(lua_State* lua) {",
        "    for (std::size_t index = 0; index < kGetters.size(); ++index) {",
        "        const std::span<const native::Entry> entry(&kGetterEntries.at(index), 1);",
        "        if (kGetters.at(index).table == nullptr) {",
        "            native::register_globals(lua, entry);",
        "        } else {",
        "            native::register_table(lua, kGetters.at(index).table, entry);",
        "        }",
        "    }",
        "    // Metatable ActionItem: __index là bảng phương thức (gốc: LuaObject có __index trỏ chính nó và các hàm đăng ký bằng RegisterObjectDirect).",
        "    lua_pushlightuserdata(lua, action_metatable_key());",
        "    lua_newtable(lua);",
        "    lua_pushstring(lua, \"__index\");",
        "    lua_newtable(lua);",
        "    for (const native::Entry& entry : kActionEntries) {",
        "        lua_pushstring(lua, entry.name);",
        "        lua_pushcfunction(lua, entry.function);",
        "        lua_rawset(lua, -3);",
        "    }",
        "    lua_rawset(lua, -3);",
        "    lua_rawset(lua, LUA_REGISTRYINDEX);",
        "    native::register_globals(lua, kGlobals);",
        "}",
        "",
        "} // namespace game::ui::script",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--exe", type=pathlib.Path, default=pathlib.Path("D:/rea/work/client/Game.exe"), help="Game.exe bản 9001")
    parser.add_argument("--write", action="store_true", help="ghi native_a_vcall.cpp")
    args = parser.parse_args()
    image = Image(args.exe)
    pool_rows, action_rows, images = generate(image)
    print(f"{len(pool_rows)} getter ảo của CDataPool, {len(action_rows)} phương thức của ActionItem rỗng")
    for row in pool_rows:
        print(f"  {row.table or '(toàn cục)'}:{row.name} {row.note}")
    for row in action_rows:
        print(f"  ActionItem:{row.name} = {row.number if row.text is None else row.text!r} ({row.note})")
    if args.write:
        OUT.write_text(render(pool_rows, action_rows, images), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())