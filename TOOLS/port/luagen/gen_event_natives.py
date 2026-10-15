"""Sinh src/client/face/ui/script/native_events.cpp: hàm game của Game.exe 2026 mà thân chỉ đẩy một sự kiện giao diện.

Ba dạng lời gọi (CEventSystem, DAT_141035fd8; ô ảo 27, 28, 29 của lớp, xem classes.tsv):
    +0xe8  PushEvent(id)                 không đối số
    +0xe0  PushEvent(id, số)             đối số là số in "%d" (Game.exe 0x1401feb70)
    +0xd8  PushEvent(id, "chuỗi hằng")   đối số là chuỗi hằng
Thân hàm là đúng một lời gọi như thế rồi `return 0`, có thể bọc thêm bốn lớp mà kết quả vẫn là "đẩy hay không đẩy":
    - `if (DAT_141035fd8 != 0)`: hệ thống sự kiện luôn có ở client này, bỏ qua;
    - phép kiểm khoá `FUN_140229d50(DAT_141036068)` (IsInHell: cảnh địa ngục thì không đẩy);
    - đối số số lấy từ script: `lua_type == 3` (số nghiêm) rồi `(int)lua_tonumber` làm đối số của sự kiện;
      sai kiểu thì hoặc bỏ qua im lặng, hoặc ném `tThrowStringException("câu lỗi của hàm")`.
Hàm có thêm bất cứ việc gì khác (đọc trạng thái, gọi đối tượng khác, ghi biến) thì KHÔNG sinh ở đây mà port tay.

Nguồn: decompile.zip, lua_api.tsv/API-TAN-SUAT.tsv (hàm nào còn thiếu native), bảng id -> tên sự kiện trích từ ba hàm khởi tạo tĩnh
(disasm/0x140a10cd0.asm, 0x140a18c10.asm, 0x140a272b0.asm: mỗi sự kiện `MOV dword ptr [..], id` rồi `LEA RAX, [tên]`; tên tra ở strings.tsv).

cách dùng (ở gốc dự án):
    python -B TOOLS/port/luagen/gen_event_natives.py [--events-out TAILIEU/SU-KIEN-GAME.tsv]
Không đối số thì chỉ in số hàm sinh được; có --write thì ghi native_events.cpp và (nếu có --events-out) bảng sự kiện đầy đủ.
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import re
import sys
import zipfile

PROJECT = pathlib.Path(__file__).resolve().parents[3]
GAME = PROJECT / "TAILIEU/GAME-EXE-2026"
API_TABLE = PROJECT / "docs/giao-viec/LUA-GEN/API-TAN-SUAT.tsv"
SCRIPT_DIR = PROJECT / "src/client/face/ui/script"
OUT = SCRIPT_DIR / "native_events.cpp"
REGISTRIES = ("0x140a10cd0", "0x140a18c10", "0x140a272b0")

# Chuỗi hằng trong .rdata mà lời gọi +0xd8 truyền bằng địa chỉ (`&DAT_...`); đọc từ Game.exe bằng llvm-objdump ngày 2026-10-15.
KNOWN_STRINGS = {
    "DAT_140b3e66c": "2",
    "DAT_140b30af8": "save",
}

DECLARATIONS = re.compile(r"^(?:(?:longlong|char|int|double|undefined8|undefined4|ulonglong|float) \**\w+; )+")
ALIAS = re.compile(r"\b(\w+) = DAT_141035fd8; ")
NUMBER = r"(?:0x[0-9a-f]+|\d+)"

# Từng mảnh của thân hàm; ghép theo thứ tự xuất hiện, cả thân phải được tiêu thụ hết.
TOKENS = (
    ("nullcheck", re.compile(r"if \(DAT_141035fd8 != \(longlong \*\)0x0\) \{ ")),
    (
        "hell",
        re.compile(
            r"(\w+) = FUN_140229d50\(DAT_141036068\); "
            r"if \((?:\(\1 == '\\0'\) && \(DAT_141035fd8 != \(longlong \*\)0x0\)|\1 == '\\0')\) \{ "
        ),
    ),
    (
        "throw",
        re.compile(
            r"(\w+) = lua_type\(\*param_\d,(\d)\); if \(\1 != 3\) \{ "
            r"tThrowStringException\(\"([^\"]*)\"\); (?:return \w+; )?\} "
        ),
    ),
    ("silent", re.compile(r"(\w+) = lua_type\(\*param_\d,(\d)\); if \(\1 == 3\) \{ ")),
    ("number", re.compile(r"(\w+) = \(double\)lua_tonumber\(\*param_\d,(\d)\); ")),
    (
        "push",
        re.compile(
            r"\(\*\*\(code \*\*\)\(\*DAT_141035fd8 \+ (0xd8|0xe0|0xe8)\)\)\(DAT_141035fd8,(" + NUMBER + r")"
            r"(?:,(" + NUMBER + r"|\"[^\"]*\"|&DAT_[0-9a-f]+|\(int\)\w+))?\); "
        ),
    ),
    ("close", re.compile(r"\} ")),
    ("return", re.compile(r"return 0;$")),
)


@dataclasses.dataclass(frozen=True)
class PushRow:
    table: str
    name: str
    address: str
    event: str
    kind: str  # kNone, kNumber, kText, kArgument
    number: int = 0
    text: str = ""
    hell_guard: bool = False
    argument: int = 0  # chỉ số ngăn xếp của đối số số (kArgument)
    bad_argument: str | None = None  # câu ném khi đối số không phải số; None là bỏ qua im lặng
    check_first: bool = False  # phép kiểm đối số (ném) đứng trước phép kiểm khoá


def read_events() -> dict[int, str]:
    """Bảng id -> tên sự kiện của ba hàm khởi tạo tĩnh."""
    names: dict[int, str] = {}
    strings: dict[int, str] = {}
    with open(GAME / "strings.tsv", encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t", 2)
            if len(parts) == 3 and parts[0].startswith("0x"):
                strings[int(parts[0], 16)] = parts[2]
    for registry in REGISTRIES:
        lines = (GAME / "disasm" / f"{registry}.asm").read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            found = re.match(r"^0x[0-9a-f]+: MOV dword ptr \[0x[0-9a-f]+\], (0x[0-9a-f]+|\d+)$", line)
            if not found:
                continue
            for look in lines[index + 1:index + 3]:
                target = re.match(r"^0x[0-9a-f]+: LEA RAX, \[(0x[0-9a-f]+)\]$", look)
                if target:
                    text = strings.get(int(target.group(1), 16), "")
                    if re.fullmatch(r"[A-Za-z0-9_]+", text):
                        names.setdefault(int(found.group(1), 0), text)
                    break
    return names


def implemented(skip: pathlib.Path = OUT) -> set[str]:
    """Tên hàm đã có native ở các native_*.cpp, trừ tệp skip (tệp sinh của chính bộ sinh đang chạy)."""
    done: set[str] = set()
    for path in SCRIPT_DIR.glob("native_*.cpp"):
        if path == skip:
            continue
        done.update(re.findall(r'\.name\s*=\s*"([A-Za-z0-9_]+)"', path.read_text(encoding="utf-8")))
    return done


def missing_functions(done: set[str]) -> list[tuple[str, str, str]]:
    """(bảng hay rỗng, tên Lua, địa chỉ) của hàm game/global có địa chỉ mà chưa có native."""
    rows = []
    for line in open(API_TABLE, encoding="utf-8"):
        if line.startswith(("#", "rank")):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 7 or parts[1] not in ("game", "global") or not parts[6].startswith("0x"):
            continue
        table, _, name = parts[2].rpartition(":")
        if name in done:
            continue
        rows.append((table, name, parts[6].lower()))
    return rows


def bodies_of(addresses: set[str]) -> dict[str, str]:
    found: dict[str, str] = {}
    with zipfile.ZipFile(GAME / "decompile.zip") as archive:
        for entry in archive.namelist():
            text = archive.read(entry).decode("utf-8", "replace")
            heads = list(re.finditer(r"^// ==== (0x[0-9a-f]+)[^\n]*$", text, re.M | re.I))
            for index, head in enumerate(heads):
                address = head.group(1).lower()
                if address in addresses:
                    end = heads[index + 1].start() if index + 1 < len(heads) else len(text)
                    found[address] = text[head.end():end]
    return found


def inner_statement(body: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
    text = re.sub(r"\s+", " ", text).strip()
    match = re.search(r"\{ (.*) \}$", text)
    return match.group(1).strip() if match else text


def to_int32(token: str) -> int:
    value = int(token, 0) & 0xFFFFFFFF
    return value - (1 << 32) if value >= (1 << 31) else value


def cpp_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def tokenize(body: str) -> list[tuple[str, tuple[str, ...]]] | None:
    """Tách thân hàm thành các mảnh của TOKENS; None nếu có đoạn lạ."""
    text = DECLARATIONS.sub("", inner_statement(body))
    alias = ALIAS.search(text)
    if alias:
        text = ALIAS.sub("", text, count=1)
        text = re.sub(r"\b" + re.escape(alias.group(1)) + r"\b", "DAT_141035fd8", text)
    tokens: list[tuple[str, tuple[str, ...]]] = []
    position = 0
    while position < len(text):
        for kind, pattern in TOKENS:
            found = pattern.match(text, position)
            if found:
                tokens.append((kind, found.groups()))
                position = found.end()
                break
        else:
            return None
    return tokens


def parse_push(table: str, name: str, address: str, body: str, events: dict[int, str]) -> PushRow | None:
    tokens = tokenize(body)
    if not tokens or tokens[-1][0] != "return":
        return None
    kinds = [kind for kind, _ in tokens]
    pushes = kinds.count("push")
    openers = sum(kinds.count(kind) for kind in ("nullcheck", "hell", "silent"))
    if pushes != 1 or kinds.count("close") != openers:
        return None
    if any(kinds.count(kind) > 1 for kind in ("hell", "throw", "silent", "number")) or ("throw" in kinds and "silent" in kinds):
        return None
    last = kinds.index("push")
    if any(kind != "close" for kind in kinds[last + 1:-1]):
        return None
    slot, event_token, argument = tokens[last][1]
    event = events.get(int(event_token, 0))
    if event is None:
        return None

    check_index = next((i for i, kind in enumerate(kinds) if kind in ("throw", "silent")), None)
    number_index = kinds.index("number") if "number" in kinds else None
    from_script = argument is not None and argument.startswith("(int)")
    if from_script != (number_index is not None) or from_script != (check_index is not None):
        return None
    if from_script and (slot != "0xe0" or tokens[check_index][1][1] != tokens[number_index][1][1] or check_index > number_index):
        return None

    base = dict(table=table, name=name, address=address, event=event)
    guard = {"hell_guard": "hell" in kinds}
    if from_script:
        kind, groups = tokens[check_index]
        guard.update(
            argument=int(groups[1]),
            bad_argument=groups[2] if kind == "throw" else None,
            check_first=kind == "throw" and "hell" in kinds and check_index < kinds.index("hell"),
        )
        return PushRow(kind="kArgument", **base, **guard)
    if slot == "0xe8" and argument is None:
        return PushRow(kind="kNone", **base, **guard)
    if slot == "0xe0" and argument is not None and re.fullmatch(NUMBER, argument):
        return PushRow(kind="kNumber", number=to_int32(argument), **base, **guard)
    if slot == "0xd8" and argument is not None:
        if argument.startswith('"'):
            return PushRow(kind="kText", text=argument[1:-1], **base, **guard)
        constant = KNOWN_STRINGS.get(argument.removeprefix("&"))
        if constant is not None:
            return PushRow(kind="kText", text=constant, **base, **guard)
    return None


def generate() -> tuple[list[PushRow], dict[int, str]]:
    events = read_events()
    candidates = missing_functions(implemented())
    bodies = bodies_of({address for _, _, address in candidates})
    rows: list[PushRow] = []
    seen: set[tuple[str, str]] = set()
    for table, name, address in candidates:
        body = bodies.get(address)
        if body is None or (table, name) in seen:
            continue
        row = parse_push(table, name, address, body, events)
        if row is None:
            continue
        seen.add((table, name))
        rows.append(row)
    rows.sort(key=lambda row: (row.table, row.name))
    return rows, events


def render_row(row: PushRow) -> str:
    fields = [
        f".table = {cpp_string(row.table) if row.table else 'nullptr'}",
        f".name = {cpp_string(row.name)}",
        f".event = {cpp_string(row.event)}",
        f".arg = Arg::{row.kind}",
        f".number = {row.number}",
        f".text = {cpp_string(row.text)}",
    ]
    if row.hell_guard:
        fields.append(".hell_guard = true")
    if row.kind == "kArgument":
        fields.append(f".argument = {row.argument}")
        if row.bad_argument is not None:
            fields.append(f".bad_argument = {cpp_string(row.bad_argument)}")
        if row.check_first:
            fields.append(".check_first = true")
    return f"    {{{', '.join(fields)}}}, // {row.address}"


def render(rows: list[PushRow]) -> str:
    lines = [
        "// Sinh bằng TOOLS/port/luagen/gen_event_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).",
        "// Hàm game mà thân chỉ đẩy một sự kiện giao diện qua CEventSystem (+0xe8: không đối số, +0xe0: số in %d, +0xd8: chuỗi hằng) rồi",
        "// trả 0, có thể bọc phép kiểm khoá cảnh (IsInHell) và một đối số số lấy từ script. Hàm có thêm bất cứ việc gì khác (đọc trạng",
        "// thái, gọi đối tượng khác) được port tay ở native_*.cpp khác.",
        '#include "lua/capi.hpp"',
        '#include "lua/native.hpp"',
        '#include "ui/script/context.hpp"',
        '#include "ui/script/native_groups.hpp"',
        '#include "ui/script/native_support.hpp"',
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "#include <expected>",
        "#include <format>",
        "#include <optional>",
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
        "// kNumber và kText mang đối số hằng; kArgument lấy số từ đối số `argument` của script (số nghiêm, ép (int)).",
        "enum class Arg : std::uint8_t { kNone, kNumber, kText, kArgument };",
        "",
        "struct Push {",
        "    const char* table; // nullptr là hàm toàn cục",
        "    const char* name;",
        "    std::string_view event;",
        "    Arg arg;",
        "    std::int32_t number;",
        "    std::string_view text;",
        "    bool hell_guard = false; // cảnh địa ngục (Facts::in_hell) thì không đẩy",
        "    int argument = 0;",
        "    const char* bad_argument = nullptr; // câu ném khi đối số không phải số; nullptr là bỏ qua im lặng",
        "    bool check_first = false; // gốc kiểm (và ném) đối số trước khi kiểm khoá",
        "};",
        "",
        f"constexpr std::array<Push, {len(rows)}> kPushes = {{{{",
    ]
    lines += [render_row(row) for row in rows]
    lines += [
        "}};",
        "",
        "// Một hàm Lua cho mỗi dòng của kPushes: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.",
        "template <std::size_t Index>",
        "NativeResult push_event(lua_State* lua) {",
        "    constexpr const Push& push = kPushes.at(Index);",
        "    Context& context = native::context_of(lua);",
        "    std::optional<double> given;",
        "    if constexpr (push.arg == Arg::kArgument) {",
        "        given = native::strict_number(lua, push.argument);",
        "        if constexpr (push.check_first) {",
        "            if (!given) return std::unexpected(NativeError::of(push.bad_argument));",
        "        }",
        "    }",
        "    if constexpr (push.hell_guard) {",
        "        if (context.facts.in_hell()) return 0;",
        "    }",
        "    if constexpr (push.arg == Arg::kArgument && !push.check_first) {",
        "        if (!given) {",
        "            if constexpr (push.bad_argument != nullptr) return std::unexpected(NativeError::of(push.bad_argument));",
        "            return 0;",
        "        }",
        "    }",
        "    switch (push.arg) {",
        "    case Arg::kNone:",
        "        context.push_event(push.event, std::span<const std::string_view>{});",
        "        break;",
        "    case Arg::kNumber:",
        "    case Arg::kArgument: {",
        "        const std::int32_t value = given ? native::to_int(*given) : push.number;",
        "        // %d của gốc: tối đa 11 ký tự cho int32.",
        "        std::array<char, 16> digits{};",
        "        const std::format_to_n_result<char*> done = std::format_to_n(digits.data(), digits.size(), \"{}\", value);",
        "        const std::array<std::string_view, 1> args = {std::string_view(digits.data(), static_cast<std::size_t>(done.size))};",
        "        context.push_event(push.event, args);",
        "        break;",
        "    }",
        "    case Arg::kText: {",
        "        const std::array<std::string_view, 1> args = {push.text};",
        "        context.push_event(push.event, args);",
        "        break;",
        "    }",
        "    }",
        "    return 0;",
        "}",
        "",
        "template <std::size_t... Index>",
        "constexpr std::array<native::Entry, sizeof...(Index)> make_entries(std::index_sequence<Index...>) {",
        "    return {{{.name = kPushes.at(Index).name, .function = &lua::adapt<push_event<Index>>}...}};",
        "}",
        "",
        "constexpr std::array kEntries = make_entries(std::make_index_sequence<kPushes.size()>{});",
        "",
        "} // namespace",
        "",
        "void register_events(lua_State* lua) {",
        "    for (std::size_t index = 0; index < kPushes.size(); ++index) {",
        "        const std::span<const native::Entry> entry(&kEntries.at(index), 1);",
        "        if (kPushes.at(index).table == nullptr) {",
        "            native::register_globals(lua, entry);",
        "        } else {",
        "            native::register_table(lua, kPushes.at(index).table, entry);",
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
    parser.add_argument("--write", action="store_true", help="ghi native_events.cpp")
    parser.add_argument("--events-out", type=pathlib.Path, help="ghi bảng id -> tên sự kiện đầy đủ ra tệp TSV này")
    args = parser.parse_args()
    rows, events = generate()
    print(f"{len(rows)} hàm đẩy sự kiện, {len(events)} sự kiện trong bảng")
    if args.write:
        OUT.write_text(render(rows), encoding="utf-8", newline="\n")
    if args.events_out:
        header = [
            "# Bảng id sự kiện giao diện của client 2026: PushEvent(id) trong Game.exe -> tên mà script Lua đăng ký.",
            "# Trích bằng TOOLS/port/luagen/gen_event_natives.py --events-out từ ba hàm khởi tạo tĩnh của Game.exe",
            "# (disasm/0x140a10cd0.asm, 0x140a18c10.asm, 0x140a272b0.asm): mỗi sự kiện `MOV dword [..], id` rồi `LEA RAX, [tên]`.",
            "# Cột: id hex, id thập phân, tên.",
            "id_hex\tid\tname",
        ]
        table = [f"0x{ident:x}\t{ident}\t{name}" for ident, name in sorted(events.items())]
        args.events_out.write_text("\n".join(header + table) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
