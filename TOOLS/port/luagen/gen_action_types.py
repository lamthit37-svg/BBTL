"""Sinh src/client/face/ui/script/action_type.cpp: bảng tên loại -> mã loại của CActionSystem (Game.exe 2026).

Hàm dựng CActionSystem (0x14002c290) điền std::map<std::string, int> ở this + 0xf8: mỗi lần là `FUN_1400308d0(map, tên)` rồi
`*puVar2 = mã`, tên là con trỏ ở bảng .data (`PTR_..._140ed88d0` -> chuỗi). GetActionNum (0x140234160) tra tên ở map này
(FUN_14002f270, so khớp đúng, phân biệt hoa thường) để có mã loại.

Thân hàm lấy từ decompile.zip; con trỏ tên đọc từ Game.exe bản 9001 (SHA-256 ở GAME_SHA256, bản mà decompile.zip phân tích):
    python -B -X utf8 TOOLS/port/luagen/gen_action_types.py [--exe D:/rea/work/client/Game.exe] [--write]
Không --write thì chỉ in số dòng và so với tệp đang có.
"""
from __future__ import annotations

import argparse
import hashlib
import pathlib
import re
import struct
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import gen_event_natives as events  # noqa: E402  (bộ đọc thân hàm từ decompile.zip)

CTOR = "0x14002c290"  # hàm dựng CActionSystem
OUT = events.SCRIPT_DIR / "action_type.cpp"
GAME_SHA256 = "3f8bb47de0bc0b233421ebd96957c23209ba1f7ee4924902de0511439ba1a9d6"
IMAGE_BASE = 0x140000000


class Image:
    """Ảnh PE đủ để đọc qword và chuỗi C theo địa chỉ ảo."""

    def __init__(self, path: pathlib.Path) -> None:
        self.data = path.read_bytes()
        digest = hashlib.sha256(self.data).hexdigest()
        if digest != GAME_SHA256:
            raise SystemExit(f"{path}: SHA-256 {digest} không phải bản 9001 mà decompile.zip phân tích")
        header = struct.unpack_from("<I", self.data, 0x3C)[0]
        count = struct.unpack_from("<H", self.data, header + 6)[0]
        optional = struct.unpack_from("<H", self.data, header + 20)[0]
        self.sections = [struct.unpack_from("<8sIIII", self.data, header + 24 + optional + 40 * i) for i in range(count)]

    def offset(self, address: int) -> int:
        relative = address - IMAGE_BASE
        for _, virtual_size, virtual_address, raw_size, raw_offset in self.sections:
            if virtual_address <= relative < virtual_address + max(virtual_size, raw_size):
                return raw_offset + relative - virtual_address
        raise SystemExit(f"địa chỉ {address:#x} ngoài mọi đoạn")

    def qword(self, address: int) -> int:
        return struct.unpack_from("<Q", self.data, self.offset(address))[0]

    def c_string(self, address: int) -> str:
        start = self.offset(address)
        return self.data[start : self.data.index(b"\0", start)].decode("ascii")


def table(image: Image) -> list[tuple[str, int]]:
    body = events.bodies_of({CTOR})[CTOR]
    rows: list[tuple[str, int]] = []
    pointer: int | None = None
    for match in re.finditer(r"PTR_\w*?_?(14[0-9a-f]{7})\b|\*puVar2 = (-?\w+);", body):
        if match.group(1):
            pointer = int(match.group(1), 16)
            continue
        if pointer is None:
            raise SystemExit(f"mã {match.group(2)} không có con trỏ tên đứng trước")
        rows.append((image.c_string(image.qword(pointer)), int(match.group(2), 0)))
        pointer = None
    if body.count("FUN_1400308d0") != len(rows):
        raise SystemExit(f"{body.count('FUN_1400308d0')} lần chèn map nhưng đọc được {len(rows)} cặp")
    if len({name for name, _ in rows}) != len(rows):
        raise SystemExit("tên lặp")
    return sorted(rows)


def render(rows: list[tuple[str, int]]) -> str:
    limit = max(code for _, code in rows) + 1
    lines = [
        "// Sinh bằng TOOLS/port/luagen/gen_action_types.py từ hàm dựng CActionSystem (Game.exe 2026, 0x14002c290); không sửa tay (sửa bộ",
        "// sinh rồi sinh lại). Bảng tên loại -> mã loại mà GetActionNum tra (map ở CActionSystem + 0xf8), xếp theo tên để tìm nhị phân.",
        '#include "ui/script/action_type.hpp"',
        "",
        "#include <algorithm>",
        "#include <array>",
        "#include <cstdint>",
        "#include <optional>",
        "#include <string_view>",
        "",
        "namespace game::ui::script {",
        "namespace {",
        "",
        "struct Row {",
        "    std::string_view name;",
        "    std::int32_t code;",
        "};",
        "",
        f"constexpr std::array<Row, {len(rows)}> kRows = {{{{",
    ]
    lines += [f'    {{.name = "{name}", .code = {code}}},' for name, code in rows]
    lines += [
        "}};",
        f"static_assert(kActionTypeLimit == {limit}, \"action_type.hpp: kActionTypeLimit lệch bảng sinh\");",
        "static_assert(std::ranges::is_sorted(kRows, {}, &Row::name));",
        "",
        "} // namespace",
        "",
        "std::optional<std::int32_t> action_type_of(const std::string_view name) noexcept {",
        "    const auto found = std::ranges::lower_bound(kRows, name, {}, &Row::name);",
        "    if (found == kRows.end() || found->name != name) return std::nullopt;",
        "    return found->code;",
        "}",
        "",
        "} // namespace game::ui::script",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--exe", type=pathlib.Path, default=pathlib.Path("D:/rea/work/client/Game.exe"))
    parser.add_argument("--write", action="store_true", help="ghi action_type.cpp")
    arguments = parser.parse_args()
    rows = table(Image(arguments.exe))
    text = render(rows)
    if arguments.write:
        OUT.write_text(text, encoding="utf-8", newline="\n")
        print(f"đã ghi {OUT} ({len(rows)} loại)")
    else:
        same = OUT.exists() and OUT.read_text(encoding="utf-8") == text
        print(f"{len(rows)} loại; {'khớp' if same else 'KHÁC'} {OUT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
