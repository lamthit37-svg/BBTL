"""Phía gốc của đối soát hàng loạt LUA-GEN: chạy mọi đơn vị (mass_units.py) trên LuaPlus.dll của client 2026 cùng thế
giới giả world.lua, ghi vết từng đơn vị và bảng tóm tắt mà ctest lua_mass so với bản dịch C++.

cách dùng (ở gốc dự án, Python 64 bit trên Windows):
    python -B TOOLS/port/luagen/mass_oracle.py <Bin64 của client 2026> [--layouts <thư mục Interface của layout>]
        [--traces build/luagen/oracle] [--summary Test/golden/lua_mass/oracle.tsv] [--only <đơn vị>...]

Vết của một đơn vị (mỗi dòng một lần __emit hay một dòng của bộ chạy):
    unit<TAB><đơn vị>
    load<TAB><chunk>       rồi !syntax nếu chunk không dịch được, !err nếu chạy thân chunk lỗi
    drive                  rồi các dòng của __drive (world.lua)
    end
Chunk đầu luôn là world. Máy chạy thêm một móc đếm lệnh (debug.sethook) trước world: vượt BUDGET lệnh thì đơn vị là
`timeout` và không đối soát được (bản C++ có trần riêng, khác đơn vị đếm). Bảng tóm tắt: đơn vị, trạng thái (ok hay
timeout), số dòng, sha256 của vết (byte, mỗi dòng kết thúc bằng \\n).
Mã thoát: 0 khi ghi xong, 2 khi không nạp được DLL hay đọc được đơn vị.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import os
import pathlib
import sys

import mass_units

WORLD = pathlib.Path(__file__).with_name("world.lua")
LUA_GLOBALSINDEX = -10001
# Trần lệnh máy ảo của một đơn vị ở phía gốc. Đơn vị bình thường dùng dưới 10^6 (đo khi chạy toàn bộ).
BUDGET = 200_000_000


def hook(perturb: int) -> str:
    """Chunk móc đếm lệnh. perturb > 0: giữ thêm perturb bảng và chuỗi cỡ khác nhau qua upvalue của móc (không lộ ra
    _G) để dời địa chỉ mọi đối tượng tạo sau đó; đơn vị nào đổi vết khi đổi perturb là vết phụ thuộc địa chỉ (thứ tự
    pairs trên khoá là bảng hay hàm), phía C++ không thể khớp từng byte."""
    return (
        "local stop, fail, keep = __timeout, error, {}\n"
        f"for i = 1, {perturb} do keep[i] = {{ i, string.rep('x', i) }} end\n"
        f"debug.sethook(function() stop() fail(keep and 'vượt trần lệnh của trọng tài') end, '', {BUDGET})\n"
        "debug = nil\n"
        "__timeout = nil\n"
    )
CALLBACK = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p)


class Library:
    """Các hàm C của LuaPlus.dll mà bộ chạy cần."""

    def __init__(self, bin_folder: pathlib.Path) -> None:
        os.add_dll_directory(str(bin_folder))
        dll = ctypes.CDLL(str(bin_folder / "LuaPlus.dll"))
        dll.lua_open.restype = ctypes.c_void_p
        dll.lua_close.argtypes = [ctypes.c_void_p]
        dll.lua_tostring.restype = ctypes.c_void_p
        dll.lua_tostring.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.lua_strlen.restype = ctypes.c_size_t
        dll.lua_strlen.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.luaL_loadbuffer.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p]
        dll.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        dll.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        dll.lua_settable.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.lua_pushcclosure.argtypes = [ctypes.c_void_p, CALLBACK, ctypes.c_int]
        self.dll = dll
        self.openers = []
        for name in ("luaopen_base", "luaopen_string", "luaopen_table", "luaopen_math", "luaopen_debug"):
            opener = getattr(dll, name)
            opener.argtypes = [ctypes.c_void_p]
            self.openers.append(opener)


class Run:
    """Một máy Lua mới cho một đơn vị: thư viện chuẩn như lua_oracle.py (base, string, table, math) cộng debug cho móc
    đếm lệnh, hàm __emit ghi vết."""

    def __init__(self, library: Library) -> None:
        self.dll = library.dll
        self.state = ctypes.c_void_p(self.dll.lua_open())
        for opener in library.openers:
            opener(self.state)
        self.dll.lua_settop(self.state, 0)
        self.lines: list[bytes] = []
        self.is_timeout = False
        # Giữ tham chiếu tới callback cho tới khi máy đóng.
        self.callbacks = [CALLBACK(self._emit), CALLBACK(self._timeout)]
        self._register("__emit", self.callbacks[0])
        self._register("__timeout", self.callbacks[1])

    def _register(self, name: str, callback: ctypes._CFuncPtr) -> None:
        self.dll.lua_pushstring(self.state, name.encode("ascii"))
        self.dll.lua_pushcclosure(self.state, callback, 0)
        self.dll.lua_settable(self.state, LUA_GLOBALSINDEX)

    def _text(self, state: ctypes.c_void_p, index: int) -> bytes:
        address = self.dll.lua_tostring(state, index)
        if not address:
            return b""
        return ctypes.string_at(address, self.dll.lua_strlen(state, index))

    def _emit(self, state: int) -> int:
        self.lines.append(self._text(ctypes.c_void_p(state), 1))
        return 0

    def _timeout(self, state: int) -> int:
        self.is_timeout = True
        return 0

    def chunk(self, name: str, source: str, *, quiet: bool = False) -> None:
        """Nạp và chạy một chunk, ghi load/!syntax/!err (quiet: không ghi gì, cho móc đếm lệnh)."""
        if not quiet:
            self.lines.append(b"load\t" + name.encode("utf-8"))
        data = source.encode("utf-8")
        if self.dll.luaL_loadbuffer(self.state, data, len(data), ("=" + name).encode("utf-8")):
            self.dll.lua_settop(self.state, 0)
            if not quiet:
                self.lines.append(b"!syntax")
            return
        if self.dll.lua_pcall(self.state, 0, 0, 0):
            self.dll.lua_settop(self.state, 0)
            if not quiet:
                self.lines.append(b"!err")

    def close(self) -> None:
        self.dll.lua_close(self.state)


def trace(library: Library, unit: mass_units.Unit, world: str, perturb: int = 0) -> tuple[bytes, bool]:
    run = Run(library)
    try:
        run.lines.append(b"unit\t" + unit.name.encode("utf-8"))
        run.chunk("hook", hook(perturb), quiet=True)
        run.chunk("world", world)
        for item in unit.chunks:
            run.chunk(item.name, item.source)
        run.lines.append(b"drive")
        run.chunk("drive", "__drive()", quiet=True)
        run.lines.append(b"end")
        return b"".join(line + b"\n" for line in run.lines), run.is_timeout
    finally:
        run.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("bin", type=pathlib.Path, help="thư mục Bin64 của client 2026 (có LuaPlus.dll)")
    parser.add_argument("--layouts", type=pathlib.Path, default=mass_units.LAYOUT_ROOT)
    parser.add_argument("--traces", type=pathlib.Path, default=mass_units.PROJECT / "build/luagen/oracle")
    parser.add_argument("--summary", type=pathlib.Path, default=mass_units.PROJECT / "Test/golden/lua_mass/oracle.tsv")
    parser.add_argument("--only", nargs="*", default=[], help="chỉ chạy các đơn vị này (không ghi bảng tóm tắt)")
    parser.add_argument("--perturb", type=int, default=0,
                        help="số đối tượng rác giữ trước world để dời địa chỉ (đo vết phụ thuộc địa chỉ; bảng vàng dùng 0)")
    args = parser.parse_args(argv)
    if not (args.bin / "LuaPlus.dll").is_file():
        print(f"không thấy LuaPlus.dll trong {args.bin}", file=sys.stderr)
        return 2
    try:
        found = mass_units.units(layout_root=args.layouts)
    except mass_units.UnitError as error:
        print(error, file=sys.stderr)
        return 2
    if args.only:
        wanted = set(args.only)
        found = [unit for unit in found if unit.name in wanted]
    library = Library(args.bin)
    world = WORLD.read_text(encoding="utf-8")
    args.traces.mkdir(parents=True, exist_ok=True)
    rows = ["# Sinh bằng TOOLS/port/luagen/mass_oracle.py trên LuaPlus.dll của client 2026; không sửa tay",
            "unit\tstatus\tlines\tsha256"]
    counts = {"ok": 0, "timeout": 0}
    for unit in found:
        data, is_timeout = trace(library, unit, world, args.perturb)
        (args.traces / f"{unit.name}.trace").write_bytes(data)
        status = "timeout" if is_timeout else "ok"
        counts[status] += 1
        rows.append(f"{unit.name}\t{status}\t{data.count(b'\n')}\t{hashlib.sha256(data).hexdigest()}")
    if not args.only:
        args.summary.parent.mkdir(parents=True, exist_ok=True)
        args.summary.write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")
    print(f"đơn vị: {len(found)}, ok: {counts['ok']}, timeout: {counts['timeout']}; vết ở {args.traces}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
