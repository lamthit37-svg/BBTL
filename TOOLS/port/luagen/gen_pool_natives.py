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
import gen_event_natives as events  # noqa: E402  (dùng chung bộ đọc bảng API, thân hàm và danh sách đã port)

PROJECT = events.PROJECT
GAME = events.GAME
OUT = events.SCRIPT_DIR / "native_pool.cpp"
CTOR = "0x1400dec40"

TYPES = {"int": (4, True), "uint": (4, False), "short": (2, True), "ushort": (2, False), "byte": (1, False), "char": (1, True)}
STORE_SIZES = {
    "undefined8": 8, "undefined4": 4, "undefined2": 2, "undefined1": 1, "int": 4, "uint": 4, "short": 2, "ushort": 2, "byte": 1,
    "char": 1, "longlong": 8, "ulonglong": 8, "bool": 1,
}
WIDTH_NAMES = {("int", 4): "kI32", ("uint", 4): "kU32", ("short", 2): "kI16", ("ushort", 2): "kU16", ("byte", 1): "kU8", ("char", 1): "kI8"}

LOAD = r"\*\((int|uint|short|ushort|byte|char) ?\*\)\(DAT_141034c40 \+ (0x[0-9a-f]+)\)"
NULL_GUARD = r"(?:if \(DAT_141034c40 == -0x[0-9a-f]+\) \{ return 0; \} )?"
ONE = re.compile(rf"^{NULL_GUARD}lua_pushnumber\(\*param_(\d),\(double\){LOAD}\); lua_gettop\(\*param_\1\); return 1;$")
TWO = re.compile(
    rf"^{NULL_GUARD}lua_pushnumber\(\*param_(\d),\(double\){LOAD}\); lua_gettop\(\*param_\1\); "
    rf"lua_pushnumber\(\*param_\1,\(double\){LOAD}\); lua_gettop\(\*param_\1\); return 2;$"
)
VIA = re.compile(r"^int (\w+); \1 = FUN_([0-9a-f]+)\(DAT_141034c40\); lua_pushnumber\(\*param_(\d),\(double\)\1\); lua_gettop\(\*param_\3\); return 1;$")
SINGLE_LOAD = re.compile(
    r"^\w+ FUN_[0-9a-f]+\(longlong param_1\) \{ return \*\((int|uint|short|ushort|byte|char|undefined4) ?\*\)\(param_1 \+ (0x[0-9a-f]+)\); \}$"
)


@dataclasses.dataclass(frozen=True)
class Source:
    offset: int
    type: str


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


class ConstructorImage:
    """Các lệnh ghi hằng của hàm dựng CDataPool, tra giá trị đầu của một trường."""

    def __init__(self) -> None:
        with zipfile.ZipFile(GAME / "decompile.zip") as archive:
            entry = next(name for name in archive.namelist() if name.startswith("decompile/1400d1120"))
            text = archive.read(entry).decode("utf-8", "replace")
        head = re.search(rf"^// ==== {CTOR}[^\n]*$", text, re.M)
        assert head, "không thấy hàm dựng CDataPool"
        rest = text[head.end():]
        following = re.search(r"^// ==== 0x[0-9a-f]+", rest, re.M)
        body = rest[: following.start()] if following else rest
        self.stores: list[tuple[int, int, str]] = []
        for found in re.finditer(r"\*\(([A-Za-z0-9_]+) ?\*\)\(param_1 \+ (0x[0-9a-f]+)\) = ([^;]+);", body):
            if found.group(1) in STORE_SIZES:
                self.stores.append((int(found.group(2), 16), STORE_SIZES[found.group(1)], found.group(3).strip()))
        for found in re.finditer(r"memset\(param_1 \+ (0x[0-9a-f]+),0,(0x[0-9a-f]+|\d+)\)", body):
            self.stores.append((int(found.group(1), 16), int(found.group(2), 0), "0"))

    def initial(self, source: Source) -> tuple[int, str] | None:
        """(giá trị đầu, ghi chú) hoặc None khi hàm dựng ghi bằng biểu thức không phải số."""
        size, signed = TYPES[source.type]
        raw = bytearray(size)
        covered = [False] * size
        for offset, length, literal in self.stores:
            lo, hi = max(offset, source.offset), min(offset + length, source.offset + size)
            if lo >= hi:
                continue
            if not re.fullmatch(r"-?(?:0x[0-9a-f]+|\d+)", literal):
                return None
            value = int(literal, 0) & ((1 << (8 * length)) - 1)
            data = value.to_bytes(length, "little")
            for position in range(lo, hi):
                raw[position - source.offset] = data[position - offset]
                covered[position - source.offset] = True
        value = int.from_bytes(bytes(raw), "little", signed=signed)
        return value, "hàm dựng ghi" if any(covered) else "không có trong hàm dựng, coi là 0"


def parse(table: str, name: str, address: str, body: str, callees: dict[str, str]) -> PoolRow | None:
    text = inner(normalise(body))
    found = ONE.match(text)
    if found:
        return PoolRow(table, name, address, (Source(int(found.group(3), 16), found.group(2)),))
    found = TWO.match(text)
    if found:
        return PoolRow(table, name, address, (Source(int(found.group(3), 16), found.group(2)), Source(int(found.group(5), 16), found.group(4))))
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


def generate() -> tuple[list[PoolRow], ConstructorImage, list[str]]:
    done = events.implemented(OUT)
    candidates = events.missing_functions(done)
    bodies = events.bodies_of({address for _, _, address in candidates})
    callees = events.bodies_of(callee_addresses(bodies))
    image = ConstructorImage()
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
        if any(image.initial(source) is None for source in row.sources):
            skipped.append(f"{table}:{name}" if table else name)
            continue
        seen.add((table, name))
        rows.append(row)
    rows.sort(key=lambda row: (row.table, row.name))
    return rows, image, skipped


def render_source(source: Source) -> str:
    size = TYPES[source.type][0]
    return f"{{.offset = {source.offset:#x}, .width = Width::{WIDTH_NAMES[(source.type, size)]}}}"


def render(rows: list[PoolRow], image: ConstructorImage) -> str:
    offsets = sorted({source for row in rows for source in row.sources}, key=lambda s: (s.offset, s.type))
    initial_lines = []
    for source in offsets:
        value, note = image.initial(source)  # type: ignore[misc]
        if value != 0:
            initial_lines.append(f"    {{.offset = {source.offset:#x}, .width = Width::{WIDTH_NAMES[(source.type, TYPES[source.type][0])]}, .value = {value}}}, // {note}")
    lines = [
        "// Sinh bằng TOOLS/port/luagen/gen_pool_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).",
        "// Hàm game mà thân chỉ đọc một hay hai trường số của CDataPool (DAT_141034c40) rồi lua_pushnumber. Client chưa có kho đó:",
        "// giá trị là ảnh bộ nhớ Facts::pool (phía mạng ghi theo offset), không có thì giá trị mà hàm dựng CDataPool (0x1400dec40) đặt.",
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
        "};",
        "",
        f"constexpr std::array<Getter, {len(rows)}> kGetters = {{{{",
    ]
    for row in rows:
        fields = [render_source(source) for source in row.sources]
        fields += ["{}"] * (2 - len(fields))
        table_text = events.cpp_string(row.table) if row.table else "nullptr"
        lines.append(
            f"    {{.table = {table_text}, .name = {events.cpp_string(row.name)}, .fields = {{{{{', '.join(fields)}}}}}, "
            f".count = {len(row.sources)}}}, // {row.address}"
        )
    lines += [
        "}};",
        "",
        "// Giá trị đầu khác 0 của các trường trên theo hàm dựng CDataPool (trường không có ở đây là 0).",
        f"constexpr std::array<PoolInitial, {len(initial_lines)}> kInitial = {{{{",
        *initial_lines,
        "}};",
        "",
        "// Một hàm Lua cho mỗi dòng của kGetters: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.",
        "template <std::size_t Index>",
        "NativeResult pool_number(lua_State* lua) {",
        "    constexpr const Getter& getter = kGetters.at(Index);",
        "    const PoolImage& pool = native::context_of(lua).facts.pool;",
        "    for (int pushed = 0; pushed < getter.count; ++pushed) {",
        "        lua_pushnumber(lua, static_cast<double>(pool.read(getter.fields.at(static_cast<std::size_t>(pushed)), kInitial)));",
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
    rows, image, skipped = generate()
    print(f"{len(rows)} hàm đọc trường CDataPool; bỏ {len(skipped)} vì hàm dựng ghi giá trị không phải hằng: {', '.join(skipped)}")
    if args.write:
        OUT.write_text(render(rows, image), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
