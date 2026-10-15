# Cầu nối tới LuaPlus.dll của client 2026 (Lua 5.0.1): kiểm cú pháp bằng luaL_loadbuffer và chạy đoạn Lua thử.
# Bộ dịch dùng nó để chứng minh hai việc: (1) tệp nào bộ phân tích của ta từ chối thì chính DLL cũng từ chối;
# (2) nghĩa của phương ngữ (continue, thứ tự đánh giá) đo trên DLL, không đoán. Cần Python 64 bit trên Windows.
from __future__ import annotations

import ctypes
import os
from pathlib import Path

DEFAULT_BIN = Path("D:/XTLBB/Bin64")
# lua.h của Lua 5.0: chỉ số giả của bảng toàn cục.
LUA_GLOBALSINDEX = -10001


class LuaDllError(Exception):
    """Không nạp được DLL, hay một đoạn chạy báo lỗi."""


class LuaDll:
    """Một máy Lua của LuaPlus.dll với thư viện base, string, table, math; chuỗi vào và ra là UTF-8 (byte nguyên văn)."""

    def __init__(self, bin_folder: Path = DEFAULT_BIN) -> None:
        library = bin_folder / "LuaPlus.dll"
        if not library.is_file():
            raise LuaDllError(f"không thấy {library}")
        os.add_dll_directory(str(bin_folder))
        self.dll = ctypes.CDLL(str(library))
        dll = self.dll
        dll.lua_open.restype = ctypes.c_void_p
        dll.lua_tostring.restype = ctypes.c_char_p
        dll.lua_tostring.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.luaL_loadbuffer.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p]
        dll.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        dll.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
        dll.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        dll.lua_settable.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.state = ctypes.c_void_p(dll.lua_open())
        for library_name in ("luaopen_base", "luaopen_string", "luaopen_table", "luaopen_math"):
            opener = getattr(dll, library_name)
            opener.argtypes = [ctypes.c_void_p]
            opener(self.state)
        dll.lua_settop(self.state, 0)
        self.lines: list[bytes] = []
        callback = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p)
        self._emit_callback = callback(self._emit)
        dll.lua_pushcclosure.argtypes = [ctypes.c_void_p, callback, ctypes.c_int]
        dll.lua_pushstring(self.state, b"__emit")
        dll.lua_pushcclosure(self.state, self._emit_callback, 0)
        dll.lua_settable(self.state, LUA_GLOBALSINDEX)

    def _emit(self, state: int) -> int:
        self.lines.append(self.dll.lua_tostring(ctypes.c_void_p(state), 1) or b"")
        return 0

    def _message(self) -> str:
        text = self.dll.lua_tostring(self.state, -1) or b"?"
        self.dll.lua_settop(self.state, 0)
        return text.decode("utf-8", errors="replace")

    def syntax_error(self, code: bytes, name: str = "chunk") -> str | None:
        """None khi luaL_loadbuffer nhận đoạn code; ngược lại câu lỗi cú pháp của DLL. Không chạy code."""
        failed = self.dll.luaL_loadbuffer(self.state, code, len(code), ("=" + name).encode("utf-8"))
        if failed:
            return self._message()
        self.dll.lua_settop(self.state, 0)
        return None

    def run(self, code: str, name: str = "chunk") -> list[str]:
        """Chạy một đoạn Lua; mọi lời gọi __emit(chuỗi) trả về theo thứ tự. Lỗi cú pháp hay chạy là LuaDllError."""
        self.lines = []
        data = code.encode("utf-8")
        failed = self.dll.luaL_loadbuffer(self.state, data, len(data), ("=" + name).encode("utf-8"))
        failed = failed or self.dll.lua_pcall(self.state, 0, 0, 0)
        if failed:
            raise LuaDllError(self._message())
        return [line.decode("utf-8", errors="replace") for line in self.lines]
