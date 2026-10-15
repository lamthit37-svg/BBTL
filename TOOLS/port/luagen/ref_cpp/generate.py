"""Bộ sinh C++ của LUA-GEN: dịch mọi chunk của mass_units (và world.lua) thành các tệp .cpp và sổ đơn vị.

    python -B TOOLS/port/luagen/ref_cpp/generate.py --out <thư mục> [--buckets K] [--only Đơn vị,...] [--layout-root <Interface>]

Đầu ra trong <thư mục> (cho CMake: <cây dựng>/gen/luagen):
- units.hpp   : `game::lua::gen::UnitEntry`, `units()`, `world()` (hợp đồng với bộ chạy thienlong_lua_mass).
- units.cpp   : bảng đơn vị theo đúng thứ tự mass_units.units(); mỗi đơn vị trỏ vào dải Chunk của nó (mảng hằng ở tệp tu_*).
- tu_NNN.cpp  : K tệp (K cố định, tệp rỗng vẫn được ghi để CMake biết trước tên). Đơn vị được chia liền khối theo số dòng C++
                ước lượng và không bao giờ bị tách giữa hai tệp: dải Chunk của đơn vị là một mảng hằng định nghĩa ở tệp chứa nó,
                nên bảng ở units.cpp chỉ gồm địa chỉ và cỡ (hằng khởi tạo tĩnh, không chép 25 000 Chunk lúc chạy).
Tệp chỉ được ghi lại khi nội dung đổi (không làm dựng lại tệp .cpp không đổi). Chunk lỗi cú pháp (21 đoạn "();" của layout,
chính LuaPlus.dll cũng từ chối) vẫn có mặt: main = nullptr, syntax_error = câu lỗi của bộ phân tích.
Mã sinh không vào git.
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from luagen import mass_units  # noqa: E402
from luagen.ref_cpp.emit import ChunkOutput, EmitError, emit_chunk, string_view_literal  # noqa: E402
from luagen.lexer import LuaSyntaxError  # noqa: E402
from luagen.parser import parse  # noqa: E402

DEFAULT_BUCKETS = 48
HERE = pathlib.Path(__file__).resolve().parent
WORLD_SOURCE = HERE.parent / "world.lua"

BANNER = "// Sinh bởi TOOLS/port/luagen/ref_cpp/generate.py từ script Lua của client 2026; không sửa tay, không vào git.\n"

UNITS_HEADER = BANNER + """// Sổ chunk đã dịch cho bộ chạy đối soát (thienlong_lua_mass): đơn vị theo đúng thứ tự và tên của mass_units.units(),
// mỗi đơn vị một dải Chunk theo thứ tự nạp; world() là world.lua.
#pragma once

#include "lua/vm.hpp"

#include <span>
#include <string_view>

namespace game::lua::gen {

struct UnitEntry {
    std::string_view name;
    std::span<const Chunk> chunks;
};

// Mọi đơn vị; bảng dựng ở lần gọi đầu và sống tới hết chương trình.
[[nodiscard]] std::span<const UnitEntry> units();
// Chunk "world" (bản dịch của world.lua).
[[nodiscard]] const Chunk& world();

} // namespace game::lua::gen
"""


# Literal chuỗi sinh dùng escape bát phân (gạch chéo ngược + 134, 042, 077...) để mang đúng byte và không bao giờ thành trigraph.
# clang-tidy gợi ý raw string khi mọi escape của literal đều bắt đầu bằng một ký tự trong nhóm `'"\?x01`; raw string không đổi nghĩa,
# chỉ làm mã sinh dài ra và phải né dấu ngoặc đóng. modernize-use-std-numbers gợi ý std::numbers cho hằng số của script chỉ "gần"
# pi, 1/pi... (sai khác cỡ 1e-4): thay vào là đổi giá trị Lua, mà bộ dịch phải giữ đúng từng bit. Chỉ bỏ hai check này, chỉ trong tệp sinh.
RAW_STRING_NOLINT_BEGIN = "// NOLINTBEGIN(modernize-raw-string-literal,modernize-use-std-numbers): mã sinh, lý do ở generate.py\n"
RAW_STRING_NOLINT_END = "// NOLINTEND(modernize-raw-string-literal,modernize-use-std-numbers)\n"


@dataclasses.dataclass
class ChunkRecord:
    """Một chunk của một đơn vị: tên, và cách nó được phát (đã dịch, hoặc chỉ mang câu lỗi cú pháp)."""

    name: str
    output: ChunkOutput | None
    syntax_error: str | None = None

    @property
    def weight(self) -> int:
        return self.output.line_count if self.output is not None else 2


@dataclasses.dataclass
class UnitRecord:
    """Một đơn vị: dải Chunk của nó thành một mảng hằng `symbol` ở tệp tu_* chứa đơn vị."""

    name: str
    symbol: str
    chunks: list[ChunkRecord]

    @property
    def weight(self) -> int:
        return sum(chunk.weight for chunk in self.chunks) + 2


def translate(source: str, name: str, prefix: str) -> ChunkRecord:
    try:
        tree_ = parse(source.encode("utf-8"), name)
    except LuaSyntaxError as error:
        return ChunkRecord(name, None, str(error))
    return ChunkRecord(name, emit_chunk(tree_, prefix))


def chunk_initializer(record: ChunkRecord) -> str:
    name = string_view_literal(record.name.encode("utf-8"))
    if record.output is None:
        assert record.syntax_error is not None
        message = string_view_literal(record.syntax_error.encode("utf-8"))
        return f"Chunk{{.name = {name}, .strings = {{}}, .main = nullptr, .syntax_error = {message}}}"
    prefix = record.output.prefix
    return (
        f"Chunk{{.name = {name}, .strings = std::span<const std::string_view>({prefix}_strings), "
        f".main = {prefix}_protos.data(), .syntax_error = {{}}}}"
    )


def unit_definition(unit: UnitRecord) -> str:
    count = len(unit.chunks)
    declaration = f"extern const std::array<Chunk, {count}> {unit.symbol};\n"
    if count == 0:
        return f"{declaration}const std::array<Chunk, 0> {unit.symbol}{{}};\n"
    items = "".join(f"    {chunk_initializer(chunk)},\n" for chunk in unit.chunks)
    return f"{declaration}const std::array<Chunk, {count}> {unit.symbol}{{{{\n{items}}}}};\n"


def used_headers(text: str) -> list[str]:
    """Chỉ include thứ tệp thật sự dùng (cổng clang-tidy misc-include-cleaner)."""
    wanted = [
        ("<array>", ("std::array", "std::to_array")),
        ("<limits>", ("std::numeric_limits",)),
        ("<span>", ("std::span",)),
        ("<string_view>", ("std::string_view",)),
    ]
    return [header for header, names in wanted if any(name in text for name in names)]


def support_header() -> str:
    """Header mã sinh include: runtime đã gộp có gen_support.hpp (failed, tick, proto... inline cho đường nóng); chưa thì vm.hpp."""
    present = (mass_units.PROJECT / "src/client/face/lua/gen_support.hpp").is_file()
    return "lua/gen_support.hpp" if present else "lua/vm.hpp"


def translation_unit(units: list[UnitRecord]) -> str:
    if not units:
        return BANNER + "// Không có đơn vị nào được chia vào tệp này.\n"
    bodies = [chunk.output.body for unit in units for chunk in unit.chunks if chunk.output is not None]
    definitions = "".join(unit_definition(unit) for unit in units)
    body_text = "".join(body + "\n" for body in bodies)
    headers = used_headers(body_text + definitions)
    parts = [BANNER, f'#include "{support_header()}"\n\n']
    if headers:
        parts.append("".join(f"#include {header}\n" for header in headers) + "\n")
    parts.append(RAW_STRING_NOLINT_BEGIN)
    parts.append("namespace game::lua::gen {\n")
    if bodies:
        parts.append("namespace {\n\n")
        parts.append(body_text)
        parts.append("} // namespace\n\n")
    parts.append(definitions)
    parts.append("\n} // namespace game::lua::gen\n")
    parts.append(RAW_STRING_NOLINT_END)
    return "".join(parts)


def registry_source(units: list[UnitRecord], world: UnitRecord) -> str:
    lines = [BANNER, '#include "luagen/units.hpp"\n', '#include "lua/vm.hpp"\n\n', "#include <array>\n#include <span>\n#include <string_view>\n\n"]
    lines.append("namespace game::lua::gen {\n\n")
    for unit in [*units, world]:
        lines.append(f"extern const std::array<Chunk, {len(unit.chunks)}> {unit.symbol};\n")
    lines.append("\n")
    lines.append(
        f"std::span<const UnitEntry> units() {{\n"
        f"    static const std::array<UnitEntry, {len(units)}> entries{{\n"
    )
    for unit in units:
        literal = string_view_literal(unit.name.encode("utf-8"))
        lines.append(f"        UnitEntry{{.name = {literal}, .chunks = std::span<const Chunk>({unit.symbol})}},\n")
    lines.append("    };\n    return entries;\n}\n\n")
    lines.append(f"const Chunk& world() {{ return {world.symbol}.front(); }}\n\n}} // namespace game::lua::gen\n")
    return "".join(lines)


def write_if_changed(path: pathlib.Path, text: str) -> bool:
    data = text.encode("utf-8")
    if path.is_file() and path.read_bytes() == data:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return True


def assign_buckets(units: list[UnitRecord], buckets: int) -> list[list[UnitRecord]]:
    """Chia liền khối theo trọng số (số dòng C++): đơn vị thứ i vào tệp floor(tổng dồn trước nó * K / tổng)."""
    total = sum(unit.weight for unit in units) or 1
    result: list[list[UnitRecord]] = [[] for _ in range(buckets)]
    running = 0
    for unit in units:
        index = min(buckets - 1, running * buckets // total)
        result[index].append(unit)
        running += unit.weight
    return result


def run(out: pathlib.Path, buckets: int, only: set[str] | None, layout_root: pathlib.Path) -> dict[str, float]:
    started = time.perf_counter()
    # mass_units bỏ qua lặng lẽ các đơn vị chỉ có layout khi thiếu thư mục: danh sách đơn vị sẽ lệch sổ vàng, nên dừng.
    if not layout_root.is_dir():
        raise SystemExit(f"không thấy thư mục layout: {layout_root} (worktree không có dev/client/assets; dùng --layout-root)")
    units = mass_units.units(layout_root=layout_root)
    if only is not None:
        units = [unit for unit in units if unit.name in only]
        missing = only - {unit.name for unit in units}
        if missing:
            raise SystemExit(f"không có đơn vị: {', '.join(sorted(missing))}")
    unit_records: list[UnitRecord] = []
    counter = 0
    for index, unit in enumerate(units):
        records = []
        for chunk in unit.chunks:
            try:
                records.append(translate(chunk.source, chunk.name, f"c{counter}"))
            except EmitError as error:
                raise SystemExit(f"{chunk.name}: {error}") from error
            counter += 1
        unit_records.append(UnitRecord(unit.name, f"u{index}", records))
    world_chunk = translate(WORLD_SOURCE.read_text(encoding="utf-8"), "world", "cworld")
    if world_chunk.output is None:
        raise SystemExit(f"world.lua không phân tích được: {world_chunk.syntax_error}")
    world = UnitRecord("world", "uworld", [world_chunk])
    translated = time.perf_counter()
    changed = 0
    for index, group in enumerate(assign_buckets([*unit_records, world], buckets)):
        changed += write_if_changed(out / f"tu_{index:03d}.cpp", translation_unit(group))
    changed += write_if_changed(out / "units.hpp", UNITS_HEADER)
    changed += write_if_changed(out / "units.cpp", registry_source(unit_records, world))
    chunk_records = [chunk for unit in [*unit_records, world] for chunk in unit.chunks]
    outputs = [chunk.output for chunk in chunk_records if chunk.output is not None]
    return {
        "units": float(len(unit_records)),
        "chunks": float(len(chunk_records)),
        "functions": float(sum(output.function_count for output in outputs)),
        "cpp_lines": float(sum(output.line_count for output in outputs)),
        "files_written": float(changed),
        "translate_seconds": translated - started,
        "write_seconds": time.perf_counter() - translated,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--buckets", type=int, default=DEFAULT_BUCKETS)
    parser.add_argument("--only", help="danh sách đơn vị cách nhau dấu phẩy (mặc định: tất cả)")
    parser.add_argument("--layout-root", type=pathlib.Path, default=mass_units.LAYOUT_ROOT)
    args = parser.parse_args(argv)
    only = {name for name in args.only.split(",") if name} if args.only else None
    stats = run(args.out, args.buckets, only, args.layout_root)
    print(" ".join(f"{key}={value:.1f}" if isinstance(value, float) and value != int(value) else f"{key}={int(value)}" for key, value in stats.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
