#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/profiles.py
#  PHÂN HỆ   : Source Headers / Profiles
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Ký hiệu comment và phần mở đầu (đứng trước khung) của từng loại tệp nguồn.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Ký hiệu comment và phần mở đầu (đứng trước khung) của từng loại tệp nguồn.

Chủ dự án chốt 2026-10-15: C, C++, Slang, GLSL, Java, JS, Objective-C++, rc dùng //; Python, CMake, TOML, sh, ps1 dùng #;
Lua dùng --; bat và cmd dùng ::. Shebang, dòng khai bảng mã và BOM đứng trước khung; `#pragma once` (hay `@echo off` của
bat) đứng sau khung.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import PurePosixPath

SLASH_SUFFIXES = frozenset({".cpp", ".hpp", ".h", ".c", ".mm", ".m", ".slang", ".glsl", ".java", ".mjs", ".js", ".ts", ".tsx",
                            ".kt", ".rc", ".inc"})
HASH_SUFFIXES = frozenset({".py", ".cmake", ".toml", ".sh", ".ps1"})
CODING = re.compile(r"^[ \t\f]*#.*?coding[:=][ \t]*[-\w.]+")
ECHO_OFF = re.compile(r"^@echo\s+off\s*$", re.IGNORECASE)


@dataclass(frozen=True)
class Profile:
    name: str
    # Ký hiệu mở một dòng comment ("//", "#", "--", "::").
    prefix: str
    # Tệp có thể mở đầu bằng shebang.
    shebang: bool
    # Tệp Python: dòng khai bảng mã nằm trong hai dòng đầu.
    coding: bool
    # Dòng đứng sau khung (và sau comment còn lại) nhưng trước mọi mã: "#pragma once" của C++.
    lead: re.Pattern[str] | None
    # Comment khối /* ... */ làm comment đầu tệp được.
    block: bool
    # Tệp Python: chuỗi tài liệu của mô-đun giữ nguyên.
    docstring: bool


PRAGMA_ONCE = re.compile(r"^#\s*pragma\s+once\s*$")

_SLASH = Profile("slash", "//", True, False, PRAGMA_ONCE, True, False)
_HASH = Profile("hash", "#", True, False, None, False, False)
_PYTHON = Profile("python", "#", True, True, None, False, True)
_LUA = Profile("lua", "--", False, False, None, False, False)
_BAT = Profile("bat", "::", False, False, ECHO_OFF, False, False)


def profile_for(path: str) -> Profile | None:
    """Profile của tệp theo tên (đường dẫn dấu /); None khi loại tệp không thuộc phạm vi."""
    pure = PurePosixPath(path)
    suffix = pure.suffix.lower()
    if suffix == ".py":
        return _PYTHON
    if suffix in SLASH_SUFFIXES:
        return _SLASH
    if suffix in HASH_SUFFIXES or pure.name == "CMakeLists.txt":
        return _HASH
    if suffix == ".lua":
        return _LUA
    if suffix in {".bat", ".cmd"}:
        return _BAT
    return None
