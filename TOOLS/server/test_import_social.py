# Kiểm import_social: chỉ nhập từ cấm mà client chưa có, khung bảng xếp hạng đọc từ ScriptGlobal.lua, đầu vào hỏng bị
# từ chối, --check bắt bảng lệch hoặc thiếu.
from __future__ import annotations

import io
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import import_social
import tsv_file

SCRIPT = """\
function SetPaimingold(sceneId,key,owosstring)
	local mystring = "chongzi"
	if key == 1 then
		mystring = "chongzi"
	elseif key == 12 then
		mystring = "bxchongzi"
	elseif key == 11 then
		mystring = "axchongzi"
	end
	local f = openfile("./Config/Paiming/"..mystring..".txt", "wb")
end
function GetPaimingold(sceneId,key)
	local mystring = "chongzi"
	if key == 1 then
		mystring = "chongzi"
	elseif key == 12 then
		mystring = "bxchongzi"
	elseif key == 11 then
		mystring = "axchongzi"
	end
	local nyols = openfile("./Config/Paiming/"..mystring..".txt", "r")
	for i=1, 10 do
		local line=read(nyols, "*l") --ID
	end
end
function GetPaimingoldX3(sceneId,key)
	for i=1, 1 do
	end
end
"""

PLAYER = "123\n角色\n40\n1\n0\n"


def _client_filter(root: Path, rows: list[tuple[str, str, str]]) -> None:
    path = root / "server" / "tables" / "shared" / "text_filter.tsv"
    tsv_file.write_table(path, "client_2026/x.txt", "import_social.py", ["int", "text", "int"], ["id", "text", "type"],
                         [list(row) for row in rows])


class ImportSocialTest(unittest.TestCase):
    def setUp(self) -> None:
        self._temp = tempfile.TemporaryDirectory()
        self.root = Path(self._temp.name)
        self.server = self.root / "server"
        self.xjl = self.root / "xjl"
        self.config = self.xjl / "Server" / "Config"
        self.script = self.xjl / "Public" / "Data" / "Script" / "ScriptGlobal.lua"
        self.config.mkdir(parents=True)
        self.script.parent.mkdir(parents=True)
        (self.config / "Paiming").mkdir()
        _client_filter(self.root, [("1", "已有", "1"), ("2", "[a][b]", "11"), ("3", "只在类型三", "3")])
        (self.config / "Filt.txt").write_bytes("已有\r\n新词\r\n  空格词  \r\n\r\n共有\r\n".encode("gbk"))
        (self.config / "FiltV2.txt").write_bytes(
            "INT\tSTRING\r\n序号\t过滤字符串\r\n1\t共有\r\n2\t只在二\r\n3\t只在类型三\r\n".encode("gbk"))
        self.script.write_bytes(SCRIPT.encode("gbk"))
        for name in ("chongzi", "axchongzi", "bxchongzi"):
            (self.config / "Paiming" / f"{name}.txt").write_bytes((PLAYER * 2).encode("gbk"))

    def tearDown(self) -> None:
        self._temp.cleanup()

    def _run(self, *extra: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = import_social.main([str(self.server), str(self.xjl), *extra])
        return code, out.getvalue(), err.getvalue()

    def _table(self, name: str) -> tsv_file.Table:
        return tsv_file.read_table(self.server / "tables" / "server" / name)

    def test_keeps_only_words_the_client_lacks(self) -> None:
        code, out, err = self._run()
        self.assertEqual(code, 0, err)
        rows = [tuple(row) for row in self._table("chat_blocked_words.tsv").rows]
        # "已有" đã có ở client (type 1) nên bỏ; "只在类型三" chỉ có ở client với type 3, không tính là đã có.
        self.assertEqual(rows, [("1", "新词", "filt"), ("2", "空格词", "filt"), ("3", "共有", "filt+filt_v2"),
                                ("4", "只在二", "filt_v2"), ("5", "只在类型三", "filt_v2")])
        self.assertIn("5 từ nhập", out)

    def test_rank_boards_come_from_the_script(self) -> None:
        self.assertEqual(self._run()[0], 0)
        table = self._table("rank_boards.tsv")
        self.assertEqual(table.columns, ("board_id", "name", "capacity"))
        self.assertEqual([tuple(row) for row in table.rows],
                         [("1", "chongzi", "10"), ("11", "axchongzi", "10"), ("12", "bxchongzi", "10")])
        _code, out, _err = self._run()
        self.assertIn("bỏ 6 dòng người chơi", out)

    def test_check_detects_missing_and_stale_tables(self) -> None:
        self.assertEqual(self._run("--check")[0], 1)
        self.assertEqual(self._run()[0], 0)
        self.assertEqual(self._run("--check")[0], 0)
        (self.config / "Filt.txt").write_bytes("新词\r\n另一个词\r\n".encode("gbk"))
        code, _out, err = self._run("--check")
        self.assertEqual(code, 1)
        self.assertIn("chat_blocked_words.tsv", err)

    def test_long_words_and_control_characters(self) -> None:
        (self.config / "Filt.txt").write_bytes(("词" * 257 + "\r\n短词\r\n").encode("gbk"))
        code, out, err = self._run()
        self.assertEqual(code, 0, err)
        self.assertIn("1 từ quá 256 ký tự bị bỏ", out)
        self.assertEqual([row[1] for row in self._table("chat_blocked_words.tsv").rows][0], "短词")
        (self.config / "Filt.txt").write_bytes(b"ab\x01cd\r\n")
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("Filt.txt:1: từ có ký tự điều khiển 0x01", err)

    def test_rejects_hostile_typed_words(self) -> None:
        bodies = {
            b"STRING\tINT\r\nx\r\n": "FiltV2.txt:1: dòng đầu phải là 'INT<tab>STRING'",
            "INT\tSTRING\r\nn\tw\r\nx\t词\r\n".encode("gbk"): "FiltV2.txt:3: cần 'số<tab>từ'",
            "INT\tSTRING\r\nn\tw\r\n1\t词\t额外\r\n".encode("gbk"): "FiltV2.txt:3: cần 'số<tab>từ'",
            b"": "FiltV2.txt:1: dòng đầu phải là 'INT<tab>STRING'",
        }
        for body, message in bodies.items():
            (self.config / "FiltV2.txt").write_bytes(body)
            code, _out, err = self._run()
            self.assertEqual(code, 1, message)
            self.assertIn(message, err)

    def test_rejects_missing_client_table_and_files(self) -> None:
        (self.server / "tables" / "shared" / "text_filter.tsv").unlink()
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("thiếu bảng client text_filter.tsv", err)
        _client_filter(self.root, [("1", "已有", "1")])
        (self.config / "Paiming" / "bxchongzi.txt").unlink()
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("bxchongzi.txt:1: ScriptGlobal.lua trỏ tới tệp xếp hạng không có", err)

    def test_rejects_inconsistent_scripts(self) -> None:
        head, sep, tail = SCRIPT.partition("function GetPaimingold(")
        cases = {
            "không thấy hàm": SCRIPT.replace("function GetPaimingold(", "function Khac("),
            "ánh xạ khoá bảng khác nhau": head.replace('"bxchongzi"', '"cxchongzi"') + sep + tail,
            "không có vòng": SCRIPT.replace("for i=1, 10 do", "while true do"),
            "không nằm trong ánh xạ": head + sep + tail.replace('= "chongzi"\n\tif', '= "la"\n\tif', 1),
            "không có khoá bảng": head + sep + re.sub(r"key == [0-9]+ then", "key == x then", tail),
        }
        for label, script in cases.items():
            self.script.write_bytes(script.encode("gbk"))
            code, _out, err = self._run()
            self.assertEqual(code, 1, label)
            self.assertIn("ScriptGlobal.lua:1:", err, label)
            self.assertIn(label, err, label)

    def test_help_and_bad_arguments(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(import_social.main(["--help"]), 0)
            self.assertEqual(import_social.main([]), 1)
        self.assertIn("import_social.py", out.getvalue())


if __name__ == "__main__":
    unittest.main()
