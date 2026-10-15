#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/test_source_headers.py
#  PHÂN HỆ   : Source Headers / Test Source Headers
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Thử khung đầu tệp: đúng từng byte với mẫu của chủ dự án, đổi khung cũ
#    không mất chữ, chạy lại không đổi gì.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Thử khung đầu tệp: đúng từng byte với mẫu của chủ dự án, đổi khung cũ không mất chữ, chạy lại không đổi gì.

Chạy: python -B -m unittest discover -s TOOLS/source_headers -p "test_source_headers.py"
"""
from __future__ import annotations

import unittest
from pathlib import Path

import legacy_box
import source_frame as frame
from extract import words
from profiles import profile_for
from rewrite import rewrite

# Mẫu chủ dự án đưa ngày 2026-10-15 (engine/core/clock.cpp của EngineHP).
SAMPLE = """/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/clock.cpp
 *  PHÂN HỆ   : Core / Timing
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Quản lý đồng hồ, giấc ngủ và lịch tick chính xác cao.
 *  - Windows : Bộ hẹn giờ độ phân giải cao theo từng luồng.
 *  - POSIX   : clock_nanosleep; Apple sử dụng nanosleep.
 *  - Sleep   : Hẹn giờ kết hợp spin-wait, tránh trả về trước hạn.
 *  - Tick    : Bước thời gian hữu tỉ, tránh sai lệch tích lũy.
 *  - Frame   : Đo thời gian khung hình và đồng bộ thời gian.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/""".split("\n")

SAMPLE_ITEMS = [
    "Quản lý đồng hồ, giấc ngủ và lịch tick chính xác cao.",
    "Windows : Bộ hẹn giờ độ phân giải cao theo từng luồng.",
    "POSIX   : clock_nanosleep; Apple sử dụng nanosleep.",
    "Sleep   : Hẹn giờ kết hợp spin-wait, tránh trả về trước hạn.",
    "Tick    : Bước thời gian hữu tỉ, tránh sai lệch tích lũy.",
    "Frame   : Đo thời gian khung hình và đồng bộ thời gian.",
]


def legacy(prefix: str, path: str, bullets: list[str]) -> list[str]:
    """Khung hộp cũ đúng như công cụ cũ ghi (rộng 63)."""
    rows = ["THIENLONG", f"Tệp: {path}", *bullets, "Dev : HiepHoon   Tele : @Hoon9xx"]
    return [legacy_box.border(prefix), *[f"{prefix} | {text.ljust(61)} |" for text in rows], legacy_box.border(prefix)]


class RenderTest(unittest.TestCase):
    def test_matches_the_owner_sample_byte_for_byte(self) -> None:
        lines = frame.render_frame("//", "engine/core/clock.cpp", SAMPLE_ITEMS, "Core / Timing")
        self.assertEqual(lines, SAMPLE)

    def test_sample_fits_the_limits(self) -> None:
        self.assertEqual(len(SAMPLE), frame.MAX_LINES)
        self.assertTrue(all(len(line) <= frame.COLUMNS for line in SAMPLE))

    def test_parse_round_trip(self) -> None:
        parsed = frame.parse_frame(SAMPLE, 0, "//", "engine/core/clock.cpp")
        assert parsed is not None
        self.assertEqual(parsed.problems, [])
        self.assertEqual(parsed.items, SAMPLE_ITEMS)
        self.assertEqual(parsed.subsystem, "Core / Timing")
        self.assertEqual(parsed.stop, len(SAMPLE))

    def test_line_comment_languages_use_the_same_layout(self) -> None:
        for prefix, path in (("#", "TOOLS/content/x.py"), ("#", "CMakeLists.txt"), ("--", "a/b.lua"), ("::", "a/b.bat")):
            if profile_for(path) is None:
                continue
            lines = frame.render_frame(prefix, path, ["Một ý."]) if frame.standard_of(path) else []
            parsed = frame.parse_frame(lines, 0, prefix, path)
            assert parsed is not None
            self.assertEqual(parsed.problems, [], path)
            self.assertTrue(all(line.startswith(prefix) for line in lines), path)
            self.assertTrue(all(len(line) <= frame.COLUMNS for line in lines), path)

    def test_wrong_fields_are_reported(self) -> None:
        bad = list(SAMPLE)
        bad[3] = bad[3].replace("clock.cpp", "other.cpp")
        bad[5] = " *  CHUẨN     : C++20"
        parsed = frame.parse_frame(bad, 0, "//", "engine/core/clock.cpp")
        assert parsed is not None
        self.assertEqual(len(parsed.problems), 2)

    def test_chinese_text_is_refused(self) -> None:
        with self.assertRaises(frame.FrameError):
            frame.render_frame("//", "a/b.cpp", ["Gồm chữ 漢字"])

    def test_too_many_lines_is_refused(self) -> None:
        with self.assertRaises(frame.FrameError):
            frame.render_frame("//", "a/b.cpp", ["từ " * 200])


class RewriteTest(unittest.TestCase):
    def test_legacy_box_becomes_new_frame_and_stays_stable(self) -> None:
        path = "src/server/account/ipc_key.hpp"
        profile = profile_for(path)
        assert profile is not None
        bullets = ["- Khoá 32 byte chung của cụm, chỉ để bọc khung ipc.", "  Không phải mật khẩu database."]
        before = [*legacy("//", path, bullets), "#pragma once", "", "namespace x {}"]
        after, plan = rewrite(before, profile, path, None)
        assert after is not None
        self.assertFalse(plan.needs_description)
        self.assertEqual(after[0], frame.border("//"))
        parsed = frame.parse_frame(after, 0, "//", path)
        assert parsed is not None
        self.assertEqual(parsed.problems, [])
        self.assertEqual(parsed.subsystem, "Server / Account / Ipc Key")
        self.assertEqual(parsed.items, ["Khoá 32 byte chung của cụm, chỉ để bọc khung ipc. Không phải mật khẩu database."])
        self.assertEqual(after[parsed.stop :], ["#pragma once", "", "namespace x {}"])
        again, _ = rewrite(after, profile, path, None)
        self.assertIsNone(again)

    def test_legacy_overflow_keeps_every_word(self) -> None:
        path = "src/client/app/x.cpp"
        profile = profile_for(path)
        assert profile is not None
        sentences = [f"Câu số {index} nói về một quyết định thiết kế đã chốt." for index in range(10)]
        bullets = [f"- {text}" for text in sentences]
        before = [*legacy("//", path, bullets), "", "int x;"]
        after, plan = rewrite(before, profile, path, None)
        assert after is not None
        self.assertTrue(plan.remainder)
        self.assertLessEqual(after.index("") if "" in after else 0, frame.MAX_LINES + 1)
        old_words = words(" ".join(sentences))
        new_words = words(" ".join(after[: len(after) - 2]))
        # Chữ mới có thêm nhãn của khung (TỆP, TÁC GIẢ...); mọi từ cũ phải còn, đúng thứ tự.
        cursor = 0
        for word in new_words:
            if cursor < len(old_words) and word == old_words[cursor]:
                cursor += 1
        self.assertEqual(cursor, len(old_words))

    def test_plain_comment_is_folded_into_the_frame(self) -> None:
        path = "engine/core/x.cpp"
        profile = profile_for(path)
        assert profile is not None
        before = ["// Giấc ngủ và lịch tick của luồng.", "// Nguồn: Forge2.", '#include "core/x.hpp"']
        after, _ = rewrite(before, profile, path, None)
        assert after is not None
        parsed = frame.parse_frame(after, 0, "//", path)
        assert parsed is not None
        self.assertEqual(parsed.problems, [])
        self.assertEqual(parsed.items, ["Giấc ngủ và lịch tick của luồng. Nguồn: Forge2."])
        self.assertEqual(after[-1], '#include "core/x.hpp"')

    def test_python_keeps_shebang_and_coding_first(self) -> None:
        path = "TOOLS/content/x.py"
        profile = profile_for(path)
        assert profile is not None
        before = ["#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""Đọc bảng."""', "import os"]
        after, _ = rewrite(before, profile, path, None)
        assert after is not None
        self.assertEqual(after[:2], before[:2])
        self.assertEqual(after[2], frame.border("#"))
        self.assertEqual(after[-2:], ['"""Đọc bảng."""', "import os"])

    def test_a_correct_frame_is_left_alone(self) -> None:
        profile = profile_for("engine/core/clock.cpp")
        assert profile is not None
        after, _ = rewrite([*SAMPLE, "", '#include "core/clock.hpp"'], profile, "engine/core/clock.cpp", None)
        self.assertIsNone(after)

    def test_a_wrong_path_is_repaired_keeping_the_subsystem(self) -> None:
        profile = profile_for("engine/core/clock.cpp")
        assert profile is not None
        moved = [line.replace("clock.cpp", "tick.cpp") for line in SAMPLE]
        after, _ = rewrite(moved, profile, "engine/core/clock.cpp", None)
        assert after is not None
        self.assertEqual(after, SAMPLE)

    def test_repository_tool_files_have_the_expected_encoding(self) -> None:
        for name in ("source_frame.py", "legacy_box.py"):
            text = Path(__file__).with_name(name).read_text(encoding="utf-8")
            self.assertEqual(text, frame.nfc(text), name)


if __name__ == "__main__":
    unittest.main()
