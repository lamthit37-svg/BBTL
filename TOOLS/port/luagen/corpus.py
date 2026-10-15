"""Chạy bộ phân tích trên mọi chunk của LUA-GEN (danh sách chunk của mass_units) và đối chiếu từng chunk với
luaL_loadbuffer của LuaPlus.dll: hai bên phải cùng nhận hay cùng từ chối.

    python -B TOOLS/port/luagen/corpus.py [--layout-root <thư mục Interface của layout>] [--bin <Bin64>] [--list-rejected]
"""

from __future__ import annotations

import argparse
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from luagen import mass_units  # noqa: E402
from luagen.dll import DEFAULT_BIN, LuaDll  # noqa: E402
from luagen.lexer import LuaSyntaxError  # noqa: E402
from luagen.parser import parse  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout-root", type=pathlib.Path, default=mass_units.LAYOUT_ROOT)
    parser.add_argument("--bin", type=pathlib.Path, default=DEFAULT_BIN)
    parser.add_argument("--list-rejected", action="store_true")
    args = parser.parse_args(argv)
    dll = LuaDll(args.bin)
    units = mass_units.units(layout_root=args.layout_root)
    total = ours_rejected = dll_rejected = 0
    mismatches: list[str] = []
    rejected: list[str] = []
    started = time.perf_counter()
    for unit in units:
        for chunk in unit.chunks:
            total += 1
            source = chunk.source.encode("utf-8")
            ours = None
            try:
                parse(source, chunk.name)
            except LuaSyntaxError as error:
                ours = str(error)
            theirs = dll.syntax_error(source, chunk.name)
            ours_rejected += ours is not None
            dll_rejected += theirs is not None
            if theirs is not None:
                rejected.append(f"{chunk.name}: {theirs}")
            if (ours is None) != (theirs is None):
                mismatches.append(f"{chunk.name}\n    ta : {ours}\n    dll: {theirs}")
    print(f"{len(units)} đơn vị, {total} chunk, {time.perf_counter() - started:.1f} s")
    print(f"bộ phân tích từ chối {ours_rejected}, LuaPlus.dll từ chối {dll_rejected}, lệch {len(mismatches)}")
    for line in mismatches[:50]:
        print("LỆCH", line)
    if args.list_rejected:
        for line in rejected:
            print("DLL từ chối", line)
    return 1 if mismatches else 0


if __name__ == "__main__":
    sys.exit(main())
