#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/legacy_box.py
#  PHÂN HỆ   : Source Headers / Legacy Box
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Đọc khung hộp cũ (chốt 2026-10-15 buổi đầu) để đổi sang khung theo mẫu
#    EngineHP của source_frame.py.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Đọc khung hộp cũ (chốt 2026-10-15 buổi đầu) để đổi sang khung theo mẫu EngineHP của source_frame.py.

    // +-------------------------------------------------------------+
    // | THIENLONG                                                   |
    // | Tệp: engine/core/clock.cpp                                  |
    // | - Một ý một dòng                                            |
    // | Dev : HiepHoon   Tele : @Hoon9xx                            |
    // +-------------------------------------------------------------+

Chỉ để đọc: khung mới ghi bằng source_frame.render_frame. Đọc dung sai (dòng lệch viền vẫn lấy được chữ) vì cây làm việc
đang có khoảng 1 400 tệp mang khung này và không tệp nào được mất chữ khi đổi.
"""
from __future__ import annotations

import re

from source_frame import join_items

# Số dấu gạch của dòng viền cũ.
WIDTH = 63
ROW = re.compile(r"^\S+\s*\|(.*?)\|?\s*$")
MAX_LINES = 15


def border(prefix: str) -> str:
    return f"{prefix} +{'-' * WIDTH}+"


def read(lines: list[str], start: int, prefix: str) -> tuple[int, list[str]] | None:
    """(chỉ số dòng sau khung, các ý) của khung cũ bắt đầu ở start; None khi không có viền dưới trong MAX_LINES dòng."""
    stop = start + 1
    while stop < len(lines) and lines[stop] != border(prefix) and stop - start <= MAX_LINES:
        stop += 1
    if stop >= len(lines) or lines[stop] != border(prefix):
        return None
    rows: list[str] = []
    for line in lines[start + 1 : stop]:
        match = ROW.match(line)
        # Bỏ đúng một dấu cách sau thanh dọc: phần thụt của dòng nối tiếp (hai dấu cách) là dữ liệu, join_items cần nó.
        text = match.group(1) if match else line
        rows.append(text.removeprefix(" ").rstrip())
    # Bốn dòng đầu cuối: tên, Tệp, các ý, Dev.
    body = rows[2:-1] if len(rows) >= 4 else []
    return stop + 1, join_items(body)
