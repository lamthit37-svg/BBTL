#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/server/test_dialogue_i18n.py
#  PHÂN HỆ   : Server / Test Dialogue I18n
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm cổng của bản dịch chữ thoại (dialogue_i18n.py): thẻ, chỗ điền và dấu
#    cách phải còn nguyên, thứ tự chỗ điền không đảo, chữ Hán không sót, và bản
#    vi dựng ra từ tệp phần giữ đúng khoá, nhóm, thứ tự của bản gốc.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import dialogue_i18n as I
import dialogue_text as D

SOURCE = "  {0}少侠，#Y蹴鞠#W大赛在晚上19点开始。"
GOOD = "  Thiếu hiệp {0}, đại hội #Yxúc cúc#W khai cuộc lúc 19 giờ tối."


class CheckText(unittest.TestCase):
    def problems(self, source: str, target: str) -> str:
        return " | ".join(I.check_text(source, target))

    def test_good_translation_passes(self) -> None:
        self.assertEqual(I.check_text(SOURCE, GOOD), [])

    def test_leading_space_count_is_kept(self) -> None:
        self.assertIn("dấu cách đầu", self.problems(SOURCE, GOOD.lstrip()))

    def test_trailing_space_count_is_kept(self) -> None:
        self.assertIn("dấu cách cuối", self.problems("好 ", "Tốt"))
        self.assertEqual(I.check_text("好 ", "Tốt "), [])

    def test_placeholder_order_cannot_swap(self) -> None:
        source = "价值#{_MONEY%d}的#G[%s]#W"
        self.assertIn("chỗ điền", self.problems(source, "Trị giá #G[%s]#W #{_MONEY%d}"))
        self.assertEqual(I.check_text(source, "Trị giá #{_MONEY%d} của #G[%s]#W"), [])

    def test_color_tags_must_match_in_count(self) -> None:
        self.assertIn("thẻ màu", self.problems("#Y红#W字", "Chữ #Yđỏ"))

    def test_untranslated_and_han_leftovers_are_caught(self) -> None:
        self.assertIn("chưa dịch", self.problems("你好", "你好"))
        self.assertIn("chữ Hán", self.problems("你好", "Xin chào，"))

    def test_han_inside_reference_tag_is_a_client_parameter(self) -> None:
        source = "去找#{_INFOAIM345,270,0,伊天彩}伊天彩"
        self.assertEqual(I.check_text(source, "Đến tìm #{_INFOAIM345,270,0,伊天彩}Y Thiên Thái"), [])

    def test_player_name_token_and_angle_brackets(self) -> None:
        self.assertEqual(I.check_text("  $N，#{HYS_20071224_02}", "  $N, #{HYS_20071224_02}"), [])
        self.assertIn("dấu <", self.problems("<小乞丐吃馒头>", "Tiểu khất cái ăn màn thầu>"))

    def test_tab_newline_and_loose_marks_are_rejected(self) -> None:
        self.assertIn("tab", self.problems("好", "Tốt\tlắm"))
        self.assertIn("còn ký hiệu", self.problems("好", "Tốt␣"))

    def test_decomposed_vietnamese_is_rejected(self) -> None:
        self.assertIn("NFC", self.problems("好", "Tốt"))


class Whole(unittest.TestCase):
    def lines(self, *rows: tuple[str, str, str]) -> list[I.Line]:
        return [I.Line(key, owner, text) for key, owner, text in rows]

    def test_key_order_and_group_must_match(self) -> None:
        source = self.lines(("lua.a", "2:-1", "好"), ("lua.b", "2:-1", "坏"))
        swapped = self.lines(("lua.b", "2:-1", "Xấu"), ("lua.a", "2:-1", "Tốt"))
        self.assertTrue(any("thứ tự" in error for error in I.check(source, swapped)))
        moved = self.lines(("lua.a", "3:-1", "Tốt"), ("lua.b", "2:-1", "Xấu"))
        self.assertTrue(any("khác nhóm" in error for error in I.check(source, moved)))
        self.assertEqual(I.check(source, self.lines(("lua.a", "2:-1", "Tốt"), ("lua.b", "2:-1", "Xấu"))), [])


class Build(unittest.TestCase):
    def test_part_file_roundtrip_and_duplicate_key(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            part = Path(folder) / "out_01.tsv"
            part.write_text("## 2:-1  obj/a.lua\nlua.a\t  Chào\nlua.b\tTốt␣\n", encoding="utf-8")
            loaded = I.load(part)
            self.assertEqual(loaded, [I.Line("lua.a", "2:-1", "  Chào"), I.Line("lua.b", "2:-1", "Tốt ")])
            other = Path(folder) / "out_02.tsv"
            other.write_text("## 3:-1\nlua.a\tTrùng\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                I.merge([part, other])

    def test_rendered_vi_file_parses_back(self) -> None:
        entries = [D.Entry("lua.00000001", "  Chào {0}", "2:-1"), D.Entry("lua.00000002", "Tốt ", "quest:7")]
        text = D.render(entries, {}, "vi", I.TOOL)
        self.assertIn("# tool: " + I.TOOL, text)
        self.assertIn("config/text/dialogue.vi.txt", text)
        self.assertEqual(D.parse(text), entries)


VI_FILE = D.TABLE_FILE.with_name("dialogue.vi.txt")


@unittest.skipUnless(D.TABLE_FILE.is_file() and VI_FILE.is_file(), "chưa có dialogue.zh.txt và dialogue.vi.txt")
class RealFiles(unittest.TestCase):
    def test_vi_file_matches_zh_key_for_key(self) -> None:
        # lua_extract.py sinh lại bản zh khi script Lua đổi; khoá mới mà bản vi thiếu sẽ hiện chữ Hán cho người chơi.
        errors = I.check(I.load(D.TABLE_FILE), I.load(VI_FILE))
        self.assertEqual(errors[:5], [], f"{len(errors)} lỗi")

    def test_system_string_tables_have_vi_sibling_with_same_shape(self) -> None:
        for name, key_column, text_column in I.TABLES:
            source = I.tsv_file.read_table(D.TABLE_FILE.with_name(f"{name}.tsv"))
            translated = I.tsv_file.read_table(D.TABLE_FILE.with_name(f"{name}.vi.tsv"))
            self.assertEqual(source.columns, translated.columns, name)
            self.assertEqual(len(source.rows), len(translated.rows), name)
            key_at, text_at = source.columns.index(key_column), source.columns.index(text_column)
            for original, now in zip(source.rows, translated.rows, strict=True):
                self.assertEqual(original[key_at], now[key_at], name)
                if original[text_at].strip():
                    self.assertEqual(I.check_text(original[text_at], now[text_at]), [], f"{name}.{original[key_at]}")


if __name__ == "__main__":
    unittest.main()
