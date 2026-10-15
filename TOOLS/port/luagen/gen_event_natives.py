"""Sinh src/client/face/ui/script/native_events.cpp: hàm game của Game.exe 2026 mà thân chỉ đẩy một sự kiện giao diện.

Ba dạng thân (CEventSystem, DAT_141035fd8; ô ảo 27, 28, 29 của lớp, xem classes.tsv):
    +0xe8  PushEvent(id)                 không đối số
    +0xe0  PushEvent(id, số)             đối số là số in "%d" (Game.exe 0x1401feb70)
    +0xd8  PushEvent(id, "chuỗi hằng")   đối số là chuỗi hằng
Thân hàm là đúng một lời gọi như thế (tuỳ chọn bọc trong `if (DAT_141035fd8 != 0)`) rồi `return 0`; hàm nào có thêm bất cứ việc gì khác
(kiểm đối số, đọc trạng thái, gọi đối tượng khác) thì KHÔNG sinh ở đây mà port tay.

Nguồn: decompile.zip, lua_api.tsv/API-TAN-SUAT.tsv (hàm nào còn thiếu native), bảng id -> tên sự kiện trích từ ba hàm khởi tạo tĩnh
(disasm/0x140a10cd0.asm, 0x140a18c10.asm, 0x140a272b0.asm: mỗi sự kiện `MOV dword ptr [..], id` rồi `LEA RAX, [tên]`; tên tra ở strings.tsv).

cách dùng (ở gốc dự án):
    python -B TOOLS/port/luagen/gen_event_natives.py [--events-out TAILIEU/SU-KIEN-GAME.tsv]
Không đối số thì chỉ in số hàm sinh được; có --write thì ghi native_events.cpp và (nếu có --events-out) bảng sự kiện đầy đủ.
"""

from __future__ import annotations

import argparse
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

PUSH = re.compile(
    r"^(?:if \(DAT_141035fd8 != \(longlong \*\)0x0\) \{ )?"
    r"\(\*\*\(code \*\*\)\(\*DAT_141035fd8 \+ (0xd8|0xe0|0xe8)\)\)\(DAT_141035fd8,(0x[0-9a-f]+|\d+)(?:,(0x[0-9a-f]+|\d+|\"[^\"]*\"))?\); (?:\} )?return 0;$"
)


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


def implemented() -> set[str]:
    done: set[str] = set()
    for path in SCRIPT_DIR.glob("native_*.cpp"):
        if path == OUT:
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


def generate() -> tuple[list[tuple[str, str, str, str, str]], dict[int, str]]:
    events = read_events()
    candidates = missing_functions(implemented())
    bodies = bodies_of({address for _, _, address in candidates})
    pushes = []
    seen: set[tuple[str, str]] = set()
    for table, name, address in candidates:
        body = bodies.get(address)
        if body is None:
            continue
        match = PUSH.match(inner_statement(body))
        if not match:
            continue
        slot, event_token, argument = match.groups()
        event = events.get(int(event_token, 0))
        if event is None:
            continue
        if slot == "0xe8" and argument is None:
            kind, number, text = "kNone", "0", '""'
        elif slot == "0xe0" and argument is not None and not argument.startswith('"'):
            kind, number, text = "kNumber", str(to_int32(argument)), '""'
        elif slot == "0xd8" and argument is not None and argument.startswith('"'):
            kind, number, text = "kText", "0", cpp_string(argument[1:-1])
        else:
            continue
        if (table, name) in seen:
            continue
        seen.add((table, name))
        pushes.append((table, name, event, f"Arg::{kind}", number, text, address))
    pushes.sort(key=lambda row: (row[0], row[1]))
    return pushes, events


def render(pushes) -> str:
    lines = [
        "// Sinh bằng TOOLS/port/luagen/gen_event_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).",
        "// Hàm game mà thân chỉ đẩy một sự kiện giao diện qua CEventSystem (+0xe8: không đối số, +0xe0: số in %d, +0xd8: chuỗi hằng) rồi",
        "// trả 0. Hàm có thêm bất cứ việc gì khác (kiểm đối số, đọc trạng thái, gọi đối tượng khác) được port tay ở native_*.cpp khác.",
        '#include "lua/capi.hpp"',
        '#include "lua/native.hpp"',
        '#include "ui/script/context.hpp"',
        '#include "ui/script/native_groups.hpp"',
        '#include "ui/script/native_support.hpp"',
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "#include <format>",
        "#include <span>",
        "#include <string_view>",
        "#include <utility>",
        "",
        "namespace game::ui::script {",
        "namespace {",
        "",
        "using lua::NativeResult;",
        "",
        "enum class Arg : std::uint8_t { kNone, kNumber, kText };",
        "",
        "struct Push {",
        "    const char* table; // nullptr là hàm toàn cục",
        "    const char* name;",
        "    std::string_view event;",
        "    Arg arg;",
        "    std::int32_t number;",
        "    std::string_view text;",
        "};",
        "",
        f"constexpr std::array<Push, {len(pushes)}> kPushes = {{{{",
    ]
    for table, name, event, kind, number, text, address in pushes:
        table_text = cpp_string(table) if table else "nullptr"
        lines.append(
            f"    {{.table = {table_text}, .name = {cpp_string(name)}, .event = {cpp_string(event)}, "
            f".arg = {kind}, .number = {number}, .text = {text}}}, // {address}"
        )
    lines += [
        "}};",
        "",
        "// Một hàm Lua cho mỗi dòng của kPushes: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.",
        "template <std::size_t Index>",
        "NativeResult push_event(lua_State* lua) {",
        "    constexpr const Push& push = kPushes.at(Index);",
        "    Context& context = native::context_of(lua);",
        "    switch (push.arg) {",
        "    case Arg::kNone:",
        "        context.push_event(push.event, std::span<const std::string_view>{});",
        "        break;",
        "    case Arg::kNumber: {",
        "        // %d của gốc: tối đa 11 ký tự cho int32.",
        "        std::array<char, 16> digits{};",
        "        const std::format_to_n_result<char*> done = std::format_to_n(digits.data(), digits.size(), \"{}\", push.number);",
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
    pushes, events = generate()
    print(f"{len(pushes)} hàm đẩy sự kiện, {len(events)} sự kiện trong bảng")
    if args.write:
        OUT.write_text(render(pushes), encoding="utf-8", newline="\n")
    if args.events_out:
        header = [
            "# Bảng id sự kiện giao diện của client 2026: PushEvent(id) trong Game.exe -> tên mà script Lua đăng ký.",
            "# Trích bằng TOOLS/port/luagen/gen_event_natives.py --events-out từ ba hàm khởi tạo tĩnh của Game.exe",
            "# (disasm/0x140a10cd0.asm, 0x140a18c10.asm, 0x140a272b0.asm): mỗi sự kiện `MOV dword [..], id` rồi `LEA RAX, [tên]`.",
            "# Cột: id hex, id thập phân, tên.",
            "id_hex\tid\tname",
        ]
        rows = [f"0x{ident:x}\t{ident}\t{name}" for ident, name in sorted(events.items())]
        args.events_out.write_text("\n".join(header + rows) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
