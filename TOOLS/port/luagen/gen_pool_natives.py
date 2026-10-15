# +---------------------------------------------------------------+
# | THIENLONG                                                     |
# | Tệp: TOOLS/port/luagen/gen_pool_natives.py                    |
# | - Sinh src/client/face/ui/script/native_pool.cpp: hàm game    |
# |   của Game.exe 2026 mà thân chỉ đọc một (hay hai) trường số   |
# |   của CDataPool.                                              |
# | Dev : HiepHoon   Tele : @Hoon9xx                              |
# +---------------------------------------------------------------+

"""Sinh src/client/face/ui/script/native_pool.cpp: hàm game của Game.exe 2026 mà thân chỉ đọc một (hay hai) trường số của CDataPool.

CDataPool (DAT_141034c40) là kho dữ liệu máy chủ cấp cho giao diện: số thú cưng, số thư, cấp VIP, thời gian... Hàm Lua đọc thẳng một
trường theo offset byte rồi `lua_pushnumber`. Client này chưa có kho đó, nên các hàm ấy đọc từ `Facts::pool` (PoolImage): ghi đè
theo offset do phía mạng đặt, còn không thì giá trị mà hàm dựng CDataPool (Game.exe 0x1400dec40) đặt lúc khởi tạo.

Dạng thân hàm nhận (đối số không được dùng; ngoài các dạng này thì KHÔNG sinh ở đây mà port tay):
    lua_pushnumber(*P,(double)*(T *)(DAT_141034c40 + OFF)); lua_gettop(*P); return 1;      (tuỳ chọn mở đầu bằng `if (pool == null) return 0`)
    như trên hai lần liên tiếp, return 2
    V = FUN_x(DAT_141034c40); lua_pushnumber(*P,(double)V); ...   với FUN_x chỉ là `return *(T *)(param_1 + OFF);`
T là int, uint, short, ushort, byte hoặc char.

Giá trị đầu của một trường: lấy từ các lệnh ghi trong hàm dựng (`*(T *)(param_1 + OFF) = giá trị;`, `memset(param_1 + OFF, 0, n)`).
Trường không có trong hàm dựng coi là 0 (vùng nhớ cấp phát mới là trang 0 của hệ điều hành; ghi chú ở từng dòng sinh). Trường mà hàm dựng
ghi bằng biểu thức không phải số (con trỏ, giá trị tính) thì hàm đọc nó bị bỏ qua.

cách dùng (ở gốc dự án):
    python -B -X utf8 TOOLS/port/luagen/gen_pool_natives.py [--write]
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import re
import sys
import zipfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "source_headers"))
import source_frame  # noqa: E402  (TOOLS/source_headers: khung đầu tệp theo mẫu ENGINEHP)
import gen_event_natives as events  # noqa: E402  (dùng chung bộ đọc bảng API, thân hàm và danh sách đã port)

PROJECT = events.PROJECT
GAME = events.GAME
OUT = events.SCRIPT_DIR / "native_pool.cpp"
CTOR = "0x1400dec40"  # hàm dựng CDataPool (DAT_141034c40)
UI_CTOR = "0x1400a7be0"  # hàm dựng CUIDataPool (DAT_141034c10)
GLOBALS = {"DAT_141034c40": False, "DAT_141034c10": True}  # tên toàn cục -> là kho giao diện

TYPES = {"int": (4, True), "uint": (4, False), "short": (2, True), "ushort": (2, False), "byte": (1, False), "char": (1, True)}
STORE_SIZES = {
    "undefined8": 8, "undefined4": 4, "undefined2": 2, "undefined1": 1, "int": 4, "uint": 4, "short": 2, "ushort": 2, "byte": 1,
    "char": 1, "longlong": 8, "ulonglong": 8, "bool": 1, "float": 4, "double": 8, "undefined": 1, "undefined3": 3, "undefined5": 5,
    "undefined6": 6, "undefined7": 7,
}
WIDTH_NAMES = {("int", 4): "kI32", ("uint", 4): "kU32", ("short", 2): "kI16", ("ushort", 2): "kU16", ("byte", 1): "kU8", ("char", 1): "kI8"}

POOL_NAMES = "|".join(GLOBALS)


def load(number: int) -> str:
    return rf"\*\((?P<t{number}>int|uint|short|ushort|byte|char) ?\*\)\((?P<g{number}>{POOL_NAMES}) \+ (?P<o{number}>0x[0-9a-f]+)\)"


NULL_GUARD = rf"(?:if \((?:{POOL_NAMES}) == -0x[0-9a-f]+\) \{{ return 0; \}} )?"
ONE = re.compile(rf"^{NULL_GUARD}lua_pushnumber\(\*param_(?P<p>\d),\(double\){load(1)}\); lua_gettop\(\*param_(?P=p)\); return 1;$")
TWO = re.compile(
    rf"^{NULL_GUARD}lua_pushnumber\(\*param_(?P<p>\d),\(double\){load(1)}\); lua_gettop\(\*param_(?P=p)\); "
    rf"lua_pushnumber\(\*param_(?P=p),\(double\){load(2)}\); lua_gettop\(\*param_(?P=p)\); return 2;$"
)
VIA = re.compile(r"^int (\w+); \1 = FUN_([0-9a-f]+)\(DAT_141034c40\); lua_pushnumber\(\*param_(\d),\(double\)\1\); lua_gettop\(\*param_\3\); return 1;$")
SINGLE_LOAD = re.compile(
    r"^\w+ FUN_[0-9a-f]+\(longlong param_1\) \{ return \*\((int|uint|short|ushort|byte|char|undefined4) ?\*\)\(param_1 \+ (0x[0-9a-f]+)\); \}$"
)


@dataclasses.dataclass(frozen=True)
class Source:
    offset: int
    type: str
    ui: bool = False  # đọc CUIDataPool (DAT_141034c10) thay vì CDataPool


@dataclasses.dataclass(frozen=True)
class PoolRow:
    table: str
    name: str
    address: str
    sources: tuple[Source, ...]


def normalise(body: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
    return re.sub(r"\s+", " ", text).strip()


def inner(text: str) -> str:
    found = re.search(r"\) \{ (.*) \}$", text)
    return found.group(1).strip() if found else text


POINTEE_SIZES = {
    "undefined8": 8, "ulonglong": 8, "longlong": 8, "double": 8, "undefined4": 4, "int": 4, "uint": 4, "float": 4,
    "undefined2": 2, "short": 2, "ushort": 2, "undefined1": 1, "undefined": 1, "char": 1, "byte": 1, "void": 1, "bool": 1,
}
NUMBER = r"-?(?:0x[0-9a-f]+|\d+)"
MAX_DEPTH = 8
ARRAY_HELPER = 0x140008360  # FUN_140008360(đích, cỡ, số, hàm dựng): dựng mảng, xử lý như _eh_vector_constructor_iterator_
# Ghidra bỏ đối số rcx ở lời gọi `FUN_x();` trong chuỗi hàm dựng (hàm gọi không nhận ra rcx là con trỏ đối tượng). Mặc định là chính param_1
# của hàm gọi (offset 0); các lời gọi dưới đây rcx là param_1 cộng offset, hoặc đối tượng không phải số (None: bỏ qua). Đo từ lệnh máy của
# Game.exe ngày 2026-10-15 bằng cách theo dõi mov/lea/add trên rcx từ đầu hàm gọi tới lệnh call.
_CTOR = int(CTOR, 16)
LOST_ARGUMENT: dict[tuple[int, int], int | None] = {
    (0x1400A19E0, 0x1400A6250): 0x90,
    (0x14014F1F0, 0x1400DBC10): 0x90,
    (0x14014F820, 0x140088880): 8,
    (0x14014F900, 0x140153490): 8,
    (_CTOR, 0x14015D550): 0x5B8F10,
    (_CTOR, 0x14015E690): 0x14074,
    (_CTOR, 0x1401D5A20): None,
    (_CTOR, 0x140166C90): None,
    (0x14014E9A0, 0x140030ED0): None,
    (0x140168D70, 0x140164B50): None,
}


class ConstructorImage:
    """Ảnh bộ nhớ của CDataPool ngay sau hàm dựng: các lệnh ghi hằng của hàm dựng và mọi hàm dựng con nó gọi.

    Đi theo `FUN_x(param_1 + OFF)`, `_eh_vector_constructor_iterator_(param_1 + OFF, cỡ, số, FUN_ctor, ...)` và `FUN_140008360(param_1 + OFF,
    cỡ, số, FUN_ctor)`; offset trong hàm con tính theo kiểu con trỏ của tham số đầu (`undefined8 *` thì `param_1 + 3` là byte 24).
    Giới hạn: vòng lặp ghi qua con trỏ dẫn xuất (`p = param_1 + K; do { p[-1] = ...; p += 6; } while`) không được tính; các hàm dựng con
    có vòng lặp bao quanh trường đang dùng đã rà tay ngày 2026-10-15, đều ghi 0 ở đúng các trường đó. Thêm hàm đọc ở vùng nhớ mới thì rà lại.
    """

    def __init__(self, ctor: str = CTOR) -> None:
        self.ctor = int(ctor, 16)
        self.bodies: dict[int, str] = {}
        seen: set[int] = set()
        pending = {self.ctor}
        while pending:
            found = events.bodies_of({f"{address:#x}" for address in pending})
            seen |= pending
            self.bodies.update({int(address, 16): normalise(body) for address, body in found.items()})
            pending = {address for address in self._called({int(address, 16) for address in found}) if address not in seen}
        assert self.ctor in self.bodies, f"không thấy hàm dựng {ctor}"
        self.memory: dict[int, int] = {}
        self.opaque: set[int] = set()  # byte được ghi bằng biểu thức không phải số (con trỏ, giá trị tính)
        self.writer: dict[int, str] = {}
        self._run(self.ctor, 0, 0)

    def _called(self, parents: set[int]) -> set[int]:
        """Hàm con mà thân của `parents` gọi với đối số đầu dẫn xuất từ param_1 (hay bị Ghidra bỏ mất, xem LOST_ARGUMENT)."""
        result: set[int] = set()
        for parent in parents:
            body = self.bodies.get(parent, "")
            for found in re.finditer(r"FUN_([0-9a-f]+)\(\(?(?:longlong\))?param_1\b", body):
                result.add(int(found.group(1), 16))
            for found in re.finditer(r"(?:_eh_vector_constructor_iterator_|FUN_140008360) ?\([^;]*?,(?:0x[0-9a-f]+|\d+),(?:0x[0-9a-f]+|\d+),FUN_([0-9a-f]+)", body):
                result.add(int(found.group(1), 16))
            for found in re.finditer(r"FUN_([0-9a-f]+)\(\)", body):
                result.add(int(found.group(1), 16))
        return result

    @staticmethod
    def _scale(body: str) -> int:
        """Số byte mỗi đơn vị của `param_1 + n`: 1 khi param_1 là số nguyên hay kiểu cấu trúc, cỡ kiểu trỏ tới khi là con trỏ trần."""
        found = re.search(r"FUN_[0-9a-f]+\(((?:const )?\w+) ?(\*+) ?param_1\b", body)
        if not found:
            return 1
        return 8 if len(found.group(2)) > 1 else POINTEE_SIZES.get(found.group(1).removeprefix("const "), 1)

    def _store(self, offset: int, length: int, literal: str, function: int) -> None:
        for position in range(offset, offset + length):
            self.writer[position] = f"FUN_{function:x}"
        if not re.fullmatch(NUMBER, literal.strip()):
            self.opaque.update(range(offset, offset + length))
            return
        self.opaque.difference_update(range(offset, offset + length))
        data = (int(literal, 0) & ((1 << (8 * length)) - 1)).to_bytes(length, "little")
        for index, byte in enumerate(data):
            self.memory[offset + index] = byte

    def _run(self, function: int, base: int, depth: int) -> None:
        body = self.bodies.get(function)
        if body is None or depth > MAX_DEPTH:
            return
        scale = self._scale(body)
        statement = re.compile(
            rf"\*\((\w+) ?\*\)\(\(longlong\)param_1 \+ ({NUMBER})\) = ([^;]+);"
            rf"|\*\((\w+) ?\*\)\(param_1 \+ ({NUMBER})\) = ([^;]+);"
            rf"|\*\((\w+) ?\*\)param_1 = ([^;]+);"
            rf"|\bparam_1\[(\d+)\] = ([^;]+);"
            rf"|\*param_1 = ([^;]+);"
            rf"|memset\((?:\(void \*\)\()?param_1(?: \+ ({NUMBER}))?\)?,0,({NUMBER})\)"
            rf"|(?:_eh_vector_constructor_iterator_|FUN_140008360) ?\(\(?(?:longlong\))?param_1(?: \+ ({NUMBER}))?,({NUMBER}),({NUMBER}),FUN_([0-9a-f]+)"
            rf"|FUN_([0-9a-f]+)\(\(?(?:longlong\))?param_1(?: \+ ({NUMBER}))?[,)]"
            rf"|FUN_([0-9a-f]+)\(\)",
            re.I,
        )
        for found in statement.finditer(body):
            groups = found.groups()
            if groups[0] and groups[0] in STORE_SIZES:
                self._store(base + int(groups[1], 0), STORE_SIZES[groups[0]], groups[2], function)
            elif groups[3] and groups[3] in STORE_SIZES:
                self._store(base + int(groups[4], 0) * scale, STORE_SIZES[groups[3]], groups[5], function)
            elif groups[6] and groups[6] in STORE_SIZES:
                self._store(base, STORE_SIZES[groups[6]], groups[7], function)
            elif groups[8] is not None and scale > 1:
                self._store(base + int(groups[8]) * scale, scale, groups[9], function)
            elif groups[10] is not None and scale > 1:
                self._store(base, scale, groups[10], function)
            elif groups[12] is not None:
                length = int(groups[12], 0)
                self._store(base + int(groups[11] or "0", 0) * scale, length, "0", function)
            elif groups[16] is not None:
                start = base + int(groups[13] or "0", 0) * scale
                size, count = int(groups[14], 0), int(groups[15], 0)
                for index in range(count):
                    self._run(int(groups[16], 16), start + index * size, depth + 1)
            elif groups[17] is not None and int(groups[17], 16) != ARRAY_HELPER:
                self._run(int(groups[17], 16), base + int(groups[18] or "0", 0) * (1 if "(longlong)" in found.group(0) else scale), depth + 1)
            elif groups[19] is not None:
                callee = int(groups[19], 16)
                target = self.bodies.get(callee, "")
                if re.search(r"FUN_[0-9a-f]+\((?!void\))[^)]*\bparam_1\b", target) and LOST_ARGUMENT.get((function, callee), 0) is not None:
                    self._run(callee, base + (LOST_ARGUMENT.get((function, callee)) or 0), depth + 1)

    def initial(self, source: Source) -> tuple[int, str] | None:
        """(giá trị đầu, ghi chú) hoặc None khi hàm dựng ghi bằng biểu thức không phải số."""
        size, signed = TYPES[source.type]
        span = range(source.offset, source.offset + size)
        if any(position in self.opaque for position in span):
            return None
        raw = bytes(self.memory.get(position, 0) for position in span)
        value = int.from_bytes(raw, "little", signed=signed)
        written = [self.writer[position] for position in span if position in self.writer]
        if not written:
            return value, "không có trong hàm dựng, coi là 0"
        direct = all(name == f"FUN_{self.ctor:x}" for name in written)
        return value, "hàm dựng ghi" if direct else f"hàm dựng con {written[0]} ghi"


def parse(table: str, name: str, address: str, body: str, callees: dict[str, str]) -> PoolRow | None:
    text = inner(normalise(body))
    found = ONE.match(text)
    if found:
        return PoolRow(table, name, address, (Source(int(found["o1"], 16), found["t1"], GLOBALS[found["g1"]]),))
    found = TWO.match(text)
    if found and found["g1"] == found["g2"]:
        ui = GLOBALS[found["g1"]]
        return PoolRow(table, name, address, (Source(int(found["o1"], 16), found["t1"], ui), Source(int(found["o2"], 16), found["t2"], ui)))
    found = VIA.match(text)
    if found:
        callee = SINGLE_LOAD.match(normalise(callees.get("0x" + found.group(2), "")))
        if callee:
            # Kết quả được gán cho `int` ở hàm Lua nên undefined4 đọc như int có dấu.
            kind = "int" if callee.group(1) == "undefined4" else callee.group(1)
            return PoolRow(table, name, address, (Source(int(callee.group(2), 16), kind),))
    return None


def callee_addresses(bodies: dict[str, str]) -> set[str]:
    wanted: set[str] = set()
    for body in bodies.values():
        found = VIA.match(inner(normalise(body)))
        if found:
            wanted.add("0x" + found.group(2))
    return wanted


def generate() -> tuple[list[PoolRow], dict[bool, ConstructorImage], list[str]]:
    done = events.implemented(OUT)
    candidates = events.missing_functions(done)
    bodies = events.bodies_of({address for _, _, address in candidates})
    callees = events.bodies_of(callee_addresses(bodies))
    images = {False: ConstructorImage(CTOR), True: ConstructorImage(UI_CTOR)}
    rows: list[PoolRow] = []
    skipped: list[str] = []
    seen: set[tuple[str, str]] = set()
    for table, name, address in candidates:
        body = bodies.get(address)
        if body is None or (table, name) in seen:
            continue
        row = parse(table, name, address, body, callees)
        if row is None:
            continue
        if any(images[source.ui].initial(source) is None for source in row.sources):
            skipped.append(f"{table}:{name}" if table else name)
            continue
        seen.add((table, name))
        rows.append(row)
    rows.sort(key=lambda row: (row.table, row.name))
    return rows, images, skipped


def render_source(source: Source) -> str:
    size = TYPES[source.type][0]
    return f"{{.offset = {source.offset:#x}, .width = Width::{WIDTH_NAMES[(source.type, size)]}}}"


def initial_lines_of(rows: list[PoolRow], image: ConstructorImage, ui: bool) -> list[str]:
    """Dòng PoolInitial khác 0 cho các trường của một kho."""
    offsets = sorted({source for row in rows for source in row.sources if source.ui == ui}, key=lambda s: (s.offset, s.type))
    lines = []
    for source in offsets:
        value, note = image.initial(source)  # type: ignore[misc]
        if value != 0:
            lines.append(f"    {{.offset = {source.offset:#x}, .width = Width::{WIDTH_NAMES[(source.type, TYPES[source.type][0])]}, .value = {value}}}, // {note}")
    return lines


def render(rows: list[PoolRow], images: dict[bool, ConstructorImage]) -> str:
    initial_lines = initial_lines_of(rows, images[False], False)
    ui_initial_lines = initial_lines_of(rows, images[True], True)
    frame = source_frame.render_frame("//", "src/client/face/ui/script/native_pool.cpp", [
        "Sinh bằng gen_pool_natives.py từ decompile Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).",
        "Hàm game chỉ đọc một hay hai trường số của CDataPool hay CUIDataPool rồi lua_pushnumber.",
        "Giá trị là ảnh bộ nhớ Facts::pool hay Facts::ui_pool (mạng ghi theo offset), chưa ghi thì giá trị của hàm dựng kho (0x1400dec40, 0x1400a7be0).",
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
        "#include <span>",
        "#include <utility>",
        "",
        "namespace game::ui::script {",
        "namespace {",
        "",
        "using lua::NativeResult;",
        "",
        "struct Getter {",
        "    const char* table = nullptr; // nullptr là hàm toàn cục",
        "    const char* name = nullptr;",
        "    std::array<PoolField, 2> fields{}; // lần đẩy thứ nhất và thứ hai",
        "    int count = 0; // số lần đẩy",
        "    bool ui = false; // đọc CUIDataPool (Facts::ui_pool) thay vì CDataPool (Facts::pool)",
        "};",
        "",
        f"constexpr std::array<Getter, {len(rows)}> kGetters = {{{{",
    ]
    for row in rows:
        fields = [render_source(source) for source in row.sources]
        fields += ["{}"] * (2 - len(fields))
        table_text = events.cpp_string(row.table) if row.table else "nullptr"
        ui_text = ", .ui = true" if row.sources[0].ui else ""
        lines.append(
            f"    {{.table = {table_text}, .name = {events.cpp_string(row.name)}, .fields = {{{{{', '.join(fields)}}}}}, "
            f".count = {len(row.sources)}{ui_text}}}, // {row.address}"
        )
    lines += [
        "}};",
        "",
        "// Giá trị đầu khác 0 của các trường trên theo hàm dựng CDataPool (trường không có ở đây là 0).",
        f"constexpr std::array<PoolInitial, {len(initial_lines)}> kInitial = {{{{",
        *initial_lines,
        "}};",
        "// Như trên theo hàm dựng CUIDataPool.",
        f"constexpr std::array<PoolInitial, {len(ui_initial_lines)}> kUiInitial = {{{{",
        *ui_initial_lines,
        "}};",
        "",
        "// Một hàm Lua cho mỗi dòng của kGetters: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.",
        "template <std::size_t Index>",
        "NativeResult pool_number(lua_State* lua) {",
        "    constexpr const Getter& getter = kGetters.at(Index);",
        "    const Facts& facts = native::context_of(lua).facts;",
        "    const PoolImage& image = getter.ui ? facts.ui_pool : facts.pool;",
        "    const std::span<const PoolInitial> initial = getter.ui ? std::span<const PoolInitial>(kUiInitial) : std::span<const PoolInitial>(kInitial);",
        "    for (int pushed = 0; pushed < getter.count; ++pushed) {",
        "        lua_pushnumber(lua, static_cast<double>(image.read(getter.fields.at(static_cast<std::size_t>(pushed)), initial)));",
        "    }",
        "    return getter.count;",
        "}",
        "",
        "template <std::size_t... Index>",
        "constexpr std::array<native::Entry, sizeof...(Index)> make_entries(std::index_sequence<Index...>) {",
        "    return {{{.name = kGetters.at(Index).name, .function = &lua::adapt<pool_number<Index>>}...}};",
        "}",
        "",
        "constexpr std::array kEntries = make_entries(std::make_index_sequence<kGetters.size()>{});",
        "",
        "} // namespace",
        "",
        "void register_pool(lua_State* lua) {",
        "    for (std::size_t index = 0; index < kGetters.size(); ++index) {",
        "        const std::span<const native::Entry> entry(&kEntries.at(index), 1);",
        "        if (kGetters.at(index).table == nullptr) {",
        "            native::register_globals(lua, entry);",
        "        } else {",
        "            native::register_table(lua, kGetters.at(index).table, entry);",
        "        }",
        "    }",
        "}",
        "",
        "} // namespace game::ui::script",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--write", action="store_true", help="ghi native_pool.cpp")
    args = parser.parse_args()
    rows, images, skipped = generate()
    print(f"{len(rows)} hàm đọc trường CDataPool; bỏ {len(skipped)} vì hàm dựng ghi giá trị không phải hằng: {', '.join(skipped)}")
    if args.write:
        OUT.write_text(render(rows, images), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
