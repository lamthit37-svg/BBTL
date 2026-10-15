# Kiểm tệp chữ thoại (dialogue_text.py): đọc ghi không mất chữ ở mọi ca biên, lỗi định dạng có số dòng, mã chuỗi trùng
# bị chặn, và tệp thật trong dev/server/tables/server đúng dạng chuẩn của công cụ.
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import dialogue_text as D
import lua_emit

SAMPLES = [
    D.Entry("lua.00000001", "同盟介绍", "2:-1"),
    D.Entry("lua.00000002", "  {0}少侠#{OBJ_dali_0008}", "2:-1"),
    D.Entry("lua.00000003", "四級材料 ", "500046:7"),
    D.Entry("lua.00000004", "hai cách cuối  ", "500046:7"),
    D.Entry("lua.00000005", "", "quest:2091"),
    D.Entry("lua.00000006", " ", "quest:2091"),
    D.Entry("lua.00000007", "#R đỏ = có dấu # và =", "1022:-9"),
]
HEADER = "key\ttext\n"


def colliding_keys() -> tuple[str, str]:
    """Hai khoá khác nhau cùng fnv1a32, tìm theo nghịch lý ngày sinh (khoảng 2^16 lần thử)."""
    seen: dict[int, str] = {}
    index = 0
    while True:
        key = f"k{index}"
        ident = lua_emit.fnv1a32(key)
        if ident in seen:
            return seen[ident], key
        seen[ident] = key
        index += 1


class RoundTrip(unittest.TestCase):
    def test_render_then_parse_keeps_every_character(self) -> None:
        text = D.render(SAMPLES, {"2:-1": "obj/luoyang/a.lua", "quest:2091": "tên\tcó tab"})
        self.assertEqual(sorted(D.parse(text), key=lambda e: e.key), SAMPLES)
        self.assertIn("## quest:2091  tên có tab\n", text)
        self.assertIn("lua.00000003  \t四級材料␣\n", text)

    def test_groups_follow_script_then_quest_order(self) -> None:
        text = D.render(SAMPLES, {})
        order = [line for line in text.splitlines() if line.startswith("## ")]
        self.assertEqual(order, ["## 2:-1", "## 1022:-9", "## 500046:7", "## quest:2091"])

    def test_plain_file_of_publisher_reads_raw(self) -> None:
        entries = D.parse("# của nhà phát hành\n" + HEADER + "## 7:-1\nlua.a\t  chữ có cách đầu\n")
        self.assertEqual(entries, [D.Entry("lua.a", "  chữ có cách đầu", "7:-1")])


class Errors(unittest.TestCase):
    def expect_error(self, text: str, fragment: str) -> None:
        with self.assertRaises(D.DialogueError) as caught:
            D.parse(text)
        self.assertIn(fragment, str(caught.exception))

    def test_line_before_first_group(self) -> None:
        self.expect_error(HEADER + "lua.a\tchữ\n", "dòng 2: câu đứng trước dòng nhóm")

    def test_duplicate_key_names_first_line(self) -> None:
        self.expect_error(HEADER + "## 1:-1\nlua.a\tx\nlua.a\ty\n", "dòng 4: khoá lua.a đã có ở dòng 3")

    def test_missing_or_extra_tab(self) -> None:
        self.expect_error(HEADER + "## 1:-1\nlua.a chữ\n", "dòng 3: cần đúng MỘT tab")
        self.expect_error(HEADER + "## 1:-1\nlua.a\tx\ty\n", "dòng 3: cần đúng MỘT tab")

    def test_bad_group_line(self) -> None:
        self.expect_error(HEADER + "##1:-1\n", "dòng 2: dòng nhóm")
        self.expect_error(HEADER + "## npc:1\n", "dòng 2: dòng nhóm")

    def test_bad_key_and_mark_inside_text(self) -> None:
        self.expect_error(HEADER + "## 1:-1\nlua a\tx\n", "khoá không hợp lệ")
        self.expect_error(HEADER + "## 1:-1\nlua.a\tx␣y\n", "chữ chứa tab")

    def test_header_required(self) -> None:
        self.expect_error("## 1:-1\nlua.a\tx\n", "dòng 1: dòng nhóm đứng trước dòng tên cột")
        self.expect_error("id\ttext\n", "dòng 1: dòng tên cột")

    def test_two_keys_with_one_string_id(self) -> None:
        first, second = colliding_keys()
        self.expect_error(HEADER + f"## 1:-1\n{first}\tx\n{second}\ty\n", "cùng mã chuỗi")

    def test_write_refuses_foreign_file(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / D.FILE_NAME
            path.write_text("# tool: TOOLS/server/khac.py; sửa tay sẽ mất ở lượt xuất sau\n", encoding="utf-8")
            with self.assertRaises(D.DialogueError):
                D.write(path, SAMPLES, {})
            self.assertTrue(path.read_text(encoding="utf-8").startswith("# tool: TOOLS/server/khac.py"))


@unittest.skipUnless(D.TABLE_FILE.is_file(), "chưa có dev/server/tables/server/dialogue.zh.txt")
class RealFile(unittest.TestCase):
    def test_real_file_is_canonical(self) -> None:
        text = D.TABLE_FILE.read_bytes().decode("utf-8")
        entries = D.parse(text)
        self.assertGreater(len(entries), 0)
        self.assertEqual(D.render(entries, D.labels_of(entries, D.TABLE_FILE.parent)), text)


if __name__ == "__main__":
    unittest.main()
