# Kiểm bộ xuất bảng Config (export_config.py) trên các bảng DBC nhỏ dựng bằng byte ngay trong thư mục
# tạm, không đụng kho thật: từng kiểu ô ra đúng chữ (số nguyên âm, số thực đọc lại đúng mẫu bit, chuỗi
# GBK thành UTF-8), cột nối, bảng gộp, mọi đường lỗi nêu đúng bảng, dòng và cột, --check so từng byte,
# tệp không đổi thì không ghi lại, bước đọc lại bắt được tệp TSV bị sửa một ô, và lỗi đĩa thành một
# dòng LỖI chứ không thành traceback.
# Chạy: python -B TOOLS/content/test_export_config.py

from __future__ import annotations

import contextlib
import dataclasses
import hashlib
import io
import os
import re
import struct
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import dbc
import export_config
from export_config import Bundle, ExportError, Join, Spec

KIND_CODES = {"i": dbc.INT, "f": dbc.FLOAT, "s": dbc.STRING}
# 1000.00006: in tám chữ số (1000.0001) thì đọc lại ra mẫu bit của số bên cạnh.
NINE_DIGITS = 0x447A0001
LARGEST_FLOAT = 0x7F7FFFFF
# Mốc sửa đổi cũ (nano giây) đặt cho tệp đích để thấy nó có bị ghi lại hay không.
OLD_STAMP = 1_000_000_000 * 10**9

SAMPLE = Spec(source="Sample.txt", target="sample.tsv", names={0: "id", 2: "name"})
PLAIN = Spec(source="T.txt", target="t.tsv", names={0: "id"})
SCENE = Join(name="scene_name", key=1, other="Scene.txt", value=1)
MAIN = Spec(source="Main.txt", target="main.tsv", names={0: "id", 1: "scene"}, joins=(SCENE,))
LEVELS = Bundle(folder="Levels", target="levels.tsv", key="table", names={0: "level"}, skip=("old.txt",))


# Ô ghi nguyên 32 bit vào bảng: mẫu bit của một số thực hay offset của một chuỗi.
class Raw(int):
    pass


def float_pattern(value: float) -> int:
    return struct.unpack("<I", struct.pack("<f", value))[0]


def cell_bits(kind: str, value: object, strings: bytearray) -> int:
    if isinstance(value, Raw):
        return int(value)
    if kind == "i":
        return struct.unpack("<I", struct.pack("<i", value))[0]
    if kind == "f":
        return float_pattern(value)
    if not value:
        return 0
    offset = len(strings)
    strings += (value if isinstance(value, bytes) else value.encode("gb18030")) + b"\0"
    return offset


# Byte của một bảng DBC. kinds có một chữ cho mỗi cột (i nguyên, f thực, s chuỗi); ô là int, float,
# str (ghi GBK), bytes (ghi nguyên vào khối chuỗi) hay Raw. Khối chuỗi mở đầu bằng NUL nên offset 0
# là chuỗi rỗng. Đưa block thì khối chuỗi là đúng các byte đó, ô chuỗi khi ấy viết bằng Raw.
def dbc_bytes(kinds: str, rows: list[tuple], block: bytes | None = None) -> bytes:
    strings = bytearray(b"\0")
    cells: list[int] = []
    for row in rows:
        if len(row) != len(kinds):
            raise ValueError(f"dòng {row} không đủ {len(kinds)} ô")
        cells += [cell_bits(kind, value, strings) for kind, value in zip(kinds, row)]
    if block is not None:
        strings = bytearray(block)
    head = struct.pack("<4I", dbc.MAGIC, len(kinds), len(rows), len(strings))
    types = struct.pack(f"<{len(kinds)}I", *(KIND_CODES[kind] for kind in kinds))
    return head + types + struct.pack(f"<{len(cells)}I", *cells) + bytes(strings)


def digest_of(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# Một kho gốc và một thư mục dữ liệu rỗng trong thư mục tạm của build/.
class Tree(unittest.TestCase):
    def setUp(self) -> None:
        build = ROOT.parents[1] / "build"
        build.mkdir(exist_ok=True)
        self.folder = tempfile.TemporaryDirectory(dir=build)
        self.raw = Path(self.folder.name) / "raw"
        self.data = Path(self.folder.name) / "data"
        self.tables = self.data / "Table"
        (self.raw / "Config").mkdir(parents=True)

    def tearDown(self) -> None:
        self.folder.cleanup()

    def put(self, name: str, kinds: str, rows: list[tuple], block: bytes | None = None) -> bytes:
        return self.put_bytes(name, dbc_bytes(kinds, rows, block))

    def put_bytes(self, name: str, data: bytes) -> bytes:
        path = self.raw / "Config" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return data

    def put_sample(self) -> bytes:
        rows = [(-5, 1.5, "洛阳"), (7, Raw(NINE_DIGITS), "abc"), (2147483647, -0.0, ""), (-2147483648, 0.1, "镜湖")]
        return self.put("Sample.txt", "ifs", rows)

    def put_joined(self) -> None:
        self.put("Main.txt", "ii", [(10, 3), (11, 99), (12, 4), (13, -1)])
        self.put("Scene.txt", "is", [(3, "洛阳"), (4, "苏州"), (3, "后来"), (-1, "无")])

    # Hai bảng cùng hình dạng viết ngược thứ tự tên, một bảng khác hình dạng có tên trong skip và một
    # bảng trong thư mục con; trả byte của hai bảng được gộp theo thứ tự tên.
    def put_levels(self) -> tuple[bytes, bytes]:
        late = self.put("Levels/b.txt", "is", [(1, "丙")])
        early = self.put("Levels/a.txt", "is", [(1, "甲"), (2, "乙")])
        self.put("Levels/old.txt", "iii", [(1, 2, 3)])
        self.put("Levels/deeper/c.txt", "is", [(9, "子")])
        return early, late

    # Mã thoát, stdout và stderr của một lượt chạy trên các bảng nêu ra.
    def run_tool(self, *specs: Spec | Bundle, is_check: bool = False) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = export_config.run(self.raw, self.data, is_check, specs)
        return code, out.getvalue(), err.getvalue()

    # Lượt chạy một bảng phải hỏng với mã 1 và đúng một dòng LỖI; trả dòng đó.
    def failure(self, spec: Spec | Bundle, is_check: bool = False) -> str:
        code, out, err = self.run_tool(spec, is_check=is_check)
        self.assertEqual((code, out), (1, ""), err)
        self.assertEqual(len(err.splitlines()), 1, err)
        self.assertTrue(err.startswith("LỖI "), err)
        return err

    def written(self, name: str) -> str:
        return (self.tables / name).read_bytes().decode("utf-8")

    def call_main(self, *arguments: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = export_config.main(list(arguments))
        return code, out.getvalue(), err.getvalue()


class PlainTable(Tree):
    def test_every_kind_of_cell_is_written_as_text(self) -> None:
        data = self.put_sample()
        code, out, err = self.run_tool(SAMPLE)
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out, "sample.tsv: 12 ô khớp bảng gốc Sample.txt (ghi mới)\n")
        lines = [
            f"# {export_config.NOTE}",
            f"# Nguồn: Config/Sample.txt, 4 dòng x 3 cột, sha256 {digest_of(data)}",
            "# Kiểu: int\tfloat\ttext",
            "id\tcolumn_1\tname",
            "-5\t1.5\t洛阳",
            "7\t1000.00006\tabc",
            "2147483647\t-0\t",
            "-2147483648\t0.1\t镜湖",
        ]
        wanted = ("\n".join(lines) + "\n").encode("utf-8")
        self.assertEqual((self.tables / "sample.tsv").read_bytes(), wanted, "UTF-8 không BOM, xuống dòng kiểu \\n")
        self.assertEqual([path.name for path in self.tables.iterdir()], ["sample.tsv"], "không sót tệp tạm")

    def test_float_text_is_the_shortest_that_reads_back_to_the_same_bits(self) -> None:
        self.assertEqual(export_config.float_text(float_pattern(0.1)), "0.1")
        self.assertEqual(export_config.float_text(float_pattern(1.5)), "1.5")
        self.assertEqual(export_config.float_text(0x80000000), "-0", "số không âm giữ bit dấu")
        self.assertEqual(export_config.float_text(NINE_DIGITS), "1000.00006")
        self.assertNotEqual(float_pattern(float("1000.0001")), NINE_DIGITS, "tám chữ số không đủ cho số này")
        # Số không, số nhỏ nhất, hai bờ của số chuẩn hoá, số có 9 chữ số, số âm, số sát miền bị từ chối.
        patterns = (0, 1, 0x007FFFFF, 0x00800000, 0x3F800001, NINE_DIGITS, 0xC0490FDB, 0x4B800000, 0x7F7FF9C4)
        for bits in patterns:
            with self.subTest(f"{bits:08x}"):
                self.assertEqual(float_pattern(float(export_config.float_text(bits))), bits)

    # Lượt thử 4 chữ số làm tròn một số sát FLT_MAX thành 3.403e+38, vượt miền float32: đó chỉ là
    # "chưa đủ chữ số", phải thử tiếp chứ không phải lỗi. Dải dính là 7f7ff9c5..7f7fffff và dải âm
    # tương ứng; ca này từng đỏ với lỗi "3.403e+38" không phải số thực float32.
    def test_floats_next_to_the_largest_are_written(self) -> None:
        self.assertEqual(export_config.float_text(LARGEST_FLOAT), "3.4028235e+38")
        for bits in (LARGEST_FLOAT, 0xFF7FFFFF, 0x7F7FF9C5, 0xFF7FF9C5):
            with self.subTest(f"{bits:08x}"):
                self.assertEqual(float_pattern(float(export_config.float_text(bits))), bits)
        self.put("T.txt", "if", [(1, Raw(LARGEST_FLOAT)), (2, Raw(0xFF7FFFFF))])
        code, out, _ = self.run_tool(PLAIN)
        self.assertEqual((code, out), (0, "t.tsv: 4 ô khớp bảng gốc T.txt (ghi mới)\n"), "bước đọc lại cũng nhận")
        self.assertTrue(self.written("t.tsv").endswith("\n1\t3.4028235e+38\n2\t-3.4028235e+38\n"))

    # Câu bảo vệ "không đọc lại được từ 9 chữ số" không tới được bằng mẫu bit thật (9 chữ số đủ cho
    # mọi float32); hạ trần chữ số xuống mới tới.
    def test_float_that_does_not_read_back_within_the_digit_limit_is_refused(self) -> None:
        with mock.patch.object(export_config, "FLOAT_DIGITS", 8), self.assertRaises(ExportError) as caught:
            export_config.float_text(NINE_DIGITS)
        self.assertIn(f"mẫu bit {NINE_DIGITS:08x} không đọc lại được từ 8 chữ số", str(caught.exception))

    # Số không hữu hạn không viết được thành thập phân và bộ đọc của client không nhận: NaN (cả NaN
    # âm và NaN báo hiệu) lẫn vô cực đều bị từ chối, câu lỗi nêu bảng, dòng và cột.
    def test_nan_and_infinity_are_refused_with_their_place(self) -> None:
        kinds = {0x7FC00000: "NaN", 0xFFC00000: "NaN", 0x7F800001: "NaN", 0x7F800000: "vô cực", 0xFF800000: "vô cực"}
        for bits, kind in kinds.items():
            with self.subTest(f"{bits:08x}"):
                self.put("T.txt", "if", [(1, 1.5), (2, Raw(bits))])
                reason = f"số thực {kind} (mẫu bit {bits:08x}) không viết được thành thập phân"
                self.assertIn(f"LỖI T.txt: dòng 1 cột 1: {reason}", self.failure(PLAIN))
                self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")
                with self.assertRaises(ExportError):
                    export_config.float_text(bits)

    def test_string_with_tab_or_line_break_is_refused(self) -> None:
        for name, mark in {"tab": "\t", "xuống dòng": "\n", "về đầu dòng": "\r"}.items():
            with self.subTest(name):
                self.put("T.txt", "is", [(1, "好"), (2, f"a{mark}b")])
                self.assertIn("T.txt: dòng 1 cột 1: chuỗi có tab hay xuống dòng", self.failure(PLAIN))
                self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")

    def test_string_that_is_not_gbk_is_refused(self) -> None:
        for name, raw in {"byte đầu không có trong GBK": b"\xff\xfe", "ký tự hai byte cụt": b"ab\x81"}.items():
            with self.subTest(name):
                self.put("T.txt", "is", [(1, raw)])
                self.assertIn(f"T.txt: dòng 0 cột 1: chuỗi không phải GBK ({raw.hex()})", self.failure(PLAIN))

    # Không dãy byte nào bộ giải mã gb18030 của Python 3.13 nhận mà mã hoá lại ra byte khác (đã vét
    # cạn mọi dãy hai byte và bốn byte), nên câu bảo vệ này chỉ tới được bằng một bộ giải mã giả.
    def test_string_that_does_not_encode_back_is_refused(self) -> None:
        class Lossy(bytes):
            def decode(self, *_: object) -> str:
                return "?"

        self.put("T.txt", "is", [(1, "好")])
        with mock.patch.object(export_config, "raw_string", return_value=Lossy("好".encode("gb18030"))):
            error = self.failure(PLAIN)
        self.assertIn("T.txt: dòng 0 cột 1: chuỗi không đổi ngược lại được đúng byte gốc", error)

    def test_string_offset_must_lie_inside_the_block(self) -> None:
        block = b"\0ab\0"
        self.put("T.txt", "is", [(1, Raw(1)), (2, Raw(3))], block)
        self.assertEqual(self.run_tool(PLAIN)[0], 0, "offset trỏ vào NUL cuối khối là chuỗi rỗng")
        self.assertTrue(self.written("t.tsv").endswith("\n1\tab\n2\t\n"))
        for offset in (len(block), 0xFFFFFFFF):
            with self.subTest(offset):
                self.put("T.txt", "is", [(1, Raw(1)), (2, Raw(offset))], block)
                self.assertIn(f"T.txt: dòng 1 cột 1: offset chuỗi {offset} ngoài khối", self.failure(PLAIN))

    # Bộ đọc ép byte cuối của khối chuỗi thành NUL như client gốc: chuỗi cuối không có NUL kết thúc
    # bị cắt ở đó chứ không đọc quá khối.
    def test_unterminated_last_string_stops_at_the_end_of_the_block(self) -> None:
        self.put("T.txt", "is", [(1, Raw(1))], b"\0abc")
        self.assertEqual(self.run_tool(PLAIN)[0], 0)
        self.assertTrue(self.written("t.tsv").endswith("\n1\tab\n"))

    def test_row_starting_with_a_hash_is_refused(self) -> None:
        self.put("T.txt", "si", [("ok", 1), ("#ghi chú", 2)])
        self.assertIn("T.txt: dòng 1 mở đầu bằng #", self.failure(Spec("T.txt", "t.tsv", {})))
        self.put("T.txt", "is", [(1, "#ghi chú")])
        self.assertEqual(self.run_tool(PLAIN)[0], 0, "dấu # ở cột sau không mở đầu dòng")
        self.assertTrue(self.written("t.tsv").endswith("\n1\t#ghi chú\n"))

    def test_named_column_outside_the_table_is_refused(self) -> None:
        self.put("T.txt", "iii", [(1, 2, 3)])
        for index in (3, -1):
            with self.subTest(index):
                error = self.failure(Spec("T.txt", "t.tsv", {0: "id", index: "extra"}))
                self.assertIn(f"T.txt: không có cột {index} (bảng có 3 cột)", error)

    def test_repeated_column_name_is_refused(self) -> None:
        self.put("T.txt", "iii", [(1, 2, 3)])
        cases = {
            "hai cột cùng tên": Spec("T.txt", "t.tsv", {0: "id", 1: "id"}),
            "trùng tên tự đặt của cột khác": Spec("T.txt", "t.tsv", {0: "column_2"}),
            "cột nối trùng tên cột": Spec("T.txt", "t.tsv", {0: "id"}, joins=(Join("id", 1, "Scene.txt", 1),)),
        }
        for name, spec in cases.items():
            with self.subTest(name):
                self.assertIn("T.txt: tên cột lặp trong [", self.failure(spec))

    def test_unreadable_source_is_reported_by_name(self) -> None:
        good = dbc_bytes("is", [(1, "a")])
        head = struct.pack("<I", dbc.MAGIC)
        not_dbc, bad_size = "không phải bảng nhị phân DBC", "đầu tệp lệch cỡ"
        cases = {
            "văn bản thường": (b"id\tname\n1\ta\n" * 4, not_dbc),
            "ngắn hơn đầu tệp": (good[:12], not_dbc),
            "tệp rỗng": (b"", not_dbc),
            "sai magic": (b"\x01" + good[1:], not_dbc),
            "cụt một byte": (good[:-1], bad_size),
            "số dòng khai quá cỡ tệp": (head + struct.pack("<4I", 1, 0xFFFFFFFF, 1, dbc.INT) + b"\0", bad_size),
            "không có cột": (head + struct.pack("<3I", 0, 0, 1) + b"\0", bad_size),
            "khối chuỗi rỗng": (head + struct.pack("<4I", 1, 0, 0, dbc.INT), bad_size),
            "kiểu cột lạ": (head + struct.pack("<4I", 1, 0, 1, 3) + b"\0", "kiểu cột lạ"),
        }
        error = self.failure(PLAIN)
        self.assertTrue(error.startswith("LỖI T.txt: không đọc được bảng gốc: "), "thiếu tệp: " + error)
        for name, (data, reason) in cases.items():
            with self.subTest(name):
                self.put_bytes("T.txt", data)
                error = self.failure(PLAIN)
                self.assertTrue(error.startswith("LỖI T.txt: không đọc được bảng gốc: "), error)
                self.assertIn(reason, error)
                self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")

    def test_table_without_rows_gives_only_the_header(self) -> None:
        self.put("T.txt", "is", [])
        code, out, _ = self.run_tool(PLAIN)
        self.assertEqual((code, out), (0, "t.tsv: 0 ô khớp bảng gốc T.txt (ghi mới)\n"))
        self.assertTrue(self.written("t.tsv").endswith("\n# Kiểu: int\ttext\nid\tcolumn_1\n"))

    # Bảng chỉ có một cột chuỗi mà có ô rỗng sẽ cho một dòng rỗng, thứ bộ đọc TSV bỏ qua: từ chối
    # trước khi ghi, nêu bảng và dòng (trước đây tệp hỏng được ghi rồi bước đọc lại mới báo thiếu dòng).
    def test_lone_empty_text_cell_is_refused_before_anything_is_written(self) -> None:
        lone = Spec("T.txt", "t.tsv", {})
        self.put("T.txt", "s", [("a",), ("",), ("b",)])
        self.assertIn("LỖI T.txt: dòng 1 là dòng rỗng", self.failure(lone))
        self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")
        self.put("T.txt", "s", [("a",), ("b",)])
        self.assertEqual(self.run_tool(lone)[0], 0, "bảng một cột chuỗi không có ô rỗng vẫn xuất được")
        self.assertTrue(self.written("t.tsv").endswith("\n# Kiểu: text\ncolumn_0\na\nb\n"))
        self.put("T.txt", "is", [(1, ""), (2, "")])
        self.assertEqual(self.run_tool(PLAIN)[0], 0, "ô rỗng ở bảng nhiều cột không làm dòng rỗng")

    def test_one_bad_table_does_not_stop_the_others(self) -> None:
        self.put("T.txt", "i", [(1,)])
        code, out, err = self.run_tool(Spec("Missing.txt", "missing.tsv", {}), PLAIN)
        self.assertEqual(code, 1)
        self.assertEqual(out, "t.tsv: 1 ô khớp bảng gốc T.txt (ghi mới)\n")
        self.assertTrue(err.startswith("LỖI Missing.txt: không đọc được bảng gốc: "), err)
        self.assertEqual([path.name for path in self.tables.iterdir()], ["t.tsv"])


class Joins(Tree):
    def test_joined_column_holds_the_text_of_the_matching_row(self) -> None:
        self.put_joined()
        build_index = mock.patch.object(export_config, "index_first_column", wraps=export_config.index_first_column)
        with mock.patch.object(dbc, "read", wraps=dbc.read) as read, build_index as index:
            code, out, err = self.run_tool(MAIN)
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out, "main.tsv: 12 ô khớp bảng gốc Main.txt (ghi mới)\n")
        lines = self.written("main.tsv").split("\n")[2:]
        rows = ["10\t3\t洛阳", "11\t99\t", "12\t4\t苏州", "13\t-1\t无"]
        wanted = ["# Kiểu: int\tint\ttext", "id\tscene\tscene_name"] + rows + [""]
        self.assertEqual(lines, wanted, "khoá lặp giữ dòng gặp trước; khoá không có dòng thì ô rỗng")
        self.assertEqual(read.call_count, 2, "mỗi bảng chỉ đọc một lần dù tra cho từng dòng")
        self.assertEqual(index.call_count, 1, "chỉ mục của bảng nối chỉ dựng một lần, không dựng lại cho từng dòng")

    def test_join_with_wrong_column_kinds_is_refused(self) -> None:
        cases = {
            "khoá là số thực": ("if", (10, 3.0), "is", (3, "洛阳")),
            "khoá là chuỗi": ("is", (10, "3"), "is", (3, "洛阳")),
            "giá trị là số nguyên": ("ii", (10, 3), "ii", (3, 7)),
            "giá trị là số thực": ("ii", (10, 3), "if", (3, 7.0)),
        }
        for name, (main_kinds, main_row, scene_kinds, scene_row) in cases.items():
            with self.subTest(name):
                self.put("Main.txt", main_kinds, [main_row])
                self.put("Scene.txt", scene_kinds, [scene_row])
                self.assertIn("Main.txt: cột nối scene_name sai kiểu", self.failure(MAIN))
                self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")

    def test_joined_table_needs_an_integer_first_column(self) -> None:
        self.put("Main.txt", "ii", [(10, 3)])
        self.put("Scene.txt", "ss", [("3", "洛阳")])
        self.assertIn("Scene.txt: cột 0 không phải số nguyên", self.failure(MAIN))

    def test_missing_joined_table_is_reported_by_name(self) -> None:
        self.put("Main.txt", "ii", [(10, 3)])
        self.assertIn("Scene.txt: không đọc được bảng gốc", self.failure(MAIN))

    def test_joined_text_is_checked_like_any_other_cell(self) -> None:
        self.put("Scene.txt", "is", [(3, "洛\t阳"), (4, "苏州")])
        self.put("Main.txt", "ii", [(10, 4)])
        self.assertEqual(self.run_tool(MAIN)[0], 0, "dòng hỏng không ai tra tới thì không cản")
        self.put("Main.txt", "ii", [(10, 4), (11, 3)])
        self.assertIn("Scene.txt: dòng 0 cột 1: chuỗi có tab hay xuống dòng", self.failure(MAIN))

    # Cột nối trỏ ra ngoài bảng (bảng nối hẹp hơn cột giá trị, bảng chính hẹp hơn cột khoá, chỉ số
    # âm) là lỗi của riêng bảng đó, nêu tên cột nối; các bảng đứng sau vẫn được xuất. Trước đây cả
    # lượt chạy dừng bằng IndexError hay DbcError chưa bọc.
    def test_join_pointing_outside_a_table_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])
        cases = {
            "bảng nối thiếu cột giá trị": (SCENE, "i", (3,)),
            "bảng chính thiếu cột khoá": (dataclasses.replace(SCENE, key=2), "is", (3, "洛阳")),
            "khoá âm": (dataclasses.replace(SCENE, key=-1), "is", (3, "洛阳")),
            "giá trị âm": (dataclasses.replace(SCENE, value=-1), "is", (3, "洛阳")),
        }
        for name, (join, scene_kinds, scene_row) in cases.items():
            with self.subTest(name):
                self.put("Main.txt", "ii", [(10, 3)])
                self.put("Scene.txt", scene_kinds, [scene_row])
                code, out, err = self.run_tool(dataclasses.replace(MAIN, joins=(join,)), PLAIN)
                self.assertEqual(code, 1)
                self.assertEqual(len(err.splitlines()), 1, err)
                self.assertIn("LỖI Main.txt: cột nối scene_name trỏ ngoài bảng", err)
                self.assertIn("t.tsv: 1 ô khớp bảng gốc T.txt", out, "bảng đứng sau vẫn được xuất")
                self.assertFalse((self.tables / "main.tsv").exists(), "bảng hỏng thì không ghi")

    def test_read_back_catches_a_changed_joined_cell(self) -> None:
        self.put_joined()
        source = export_config.Source(self.raw)
        text = export_config.table_text(source, MAIN)
        self.assertEqual(export_config.verify(source, MAIN, text), 12)
        cases = {
            "tên khác": ("10\t3\t洛阳\n", "10\t3\t苏州\n", "dòng dữ liệu 0 cột nối scene_name lệch bảng gốc"),
            "ô rỗng bị điền": ("11\t99\t\n", "11\t99\t洛阳\n", "dòng dữ liệu 1 cột nối scene_name lệch bảng gốc"),
            "thiếu ô nối": ("12\t4\t苏州\n", "12\t4\n", "dòng dữ liệu 2 có 2 ô, cần 3"),
        }
        for name, (old, new, where) in cases.items():
            with self.subTest(name):
                self.assertEqual(text.count(old), 1)
                with self.assertRaises(ExportError) as caught:
                    export_config.verify(source, MAIN, text.replace(old, new))
                self.assertIn(f"main.tsv: {where}", str(caught.exception))


class Check(Tree):
    def test_check_fails_when_the_table_was_never_written(self) -> None:
        self.put_sample()
        self.assertIn(f"sample.tsv: chưa có trong {self.tables}", self.failure(SAMPLE, is_check=True))
        self.assertFalse(self.data.exists(), "--check không tạo gì")

    def test_check_fails_on_a_single_changed_byte(self) -> None:
        self.put_sample()
        self.assertEqual(self.run_tool(SAMPLE)[0], 0)
        path = self.tables / "sample.tsv"
        good = path.read_bytes()
        places = {
            "dòng chú thích": good.index(b"Sinh"),
            "dòng tên cột": good.index(b"column_1"),
            "ô dữ liệu": good.index(b"abc"),
            "byte cuối": len(good) - 1,
        }
        for name, at in places.items():
            with self.subTest(name):
                changed = good[:at] + bytes([good[at] ^ 1]) + good[at + 1:]
                path.write_bytes(changed)
                error = self.failure(SAMPLE, is_check=True)
                self.assertIn("sample.tsv: khác tệp sẽ sinh từ kho gốc", error)
                self.assertEqual(path.read_bytes(), changed, "--check không sửa tệp")
        path.write_bytes(good + b"\n")
        self.assertIn("sample.tsv: khác tệp sẽ sinh từ kho gốc", self.failure(SAMPLE, is_check=True))

    def test_check_passes_on_the_written_table_and_leaves_it_alone(self) -> None:
        self.put_sample()
        self.assertEqual(self.run_tool(SAMPLE)[0], 0)
        path = self.tables / "sample.tsv"
        os.utime(path, ns=(OLD_STAMP, OLD_STAMP))
        code, out, err = self.run_tool(SAMPLE, is_check=True)
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out, "sample.tsv: 12 ô khớp bảng gốc Sample.txt (giữ nguyên)\n")
        self.assertEqual(path.stat().st_mtime_ns, OLD_STAMP, "--check không ghi")

    def test_check_fails_when_the_source_changed_after_the_export(self) -> None:
        self.put_sample()
        self.assertEqual(self.run_tool(SAMPLE)[0], 0)
        self.put("Sample.txt", "ifs", [(-5, 1.5, "洛阳")])
        self.assertIn("sample.tsv: khác tệp sẽ sinh từ kho gốc", self.failure(SAMPLE, is_check=True))

    def test_unchanged_table_is_not_rewritten(self) -> None:
        self.put_sample()
        self.assertEqual(self.run_tool(SAMPLE)[1], "sample.tsv: 12 ô khớp bảng gốc Sample.txt (ghi mới)\n")
        path = self.tables / "sample.tsv"
        os.utime(path, ns=(OLD_STAMP, OLD_STAMP))
        code, out, _ = self.run_tool(SAMPLE)
        self.assertEqual((code, out), (0, "sample.tsv: 12 ô khớp bảng gốc Sample.txt (giữ nguyên)\n"))
        self.assertEqual(path.stat().st_mtime_ns, OLD_STAMP, "nội dung không đổi thì không ghi lại")
        self.put("Sample.txt", "ifs", [(1, 2.0, "新")])
        code, out, _ = self.run_tool(SAMPLE)
        self.assertEqual((code, out), (0, "sample.tsv: 3 ô khớp bảng gốc Sample.txt (ghi mới)\n"))
        self.assertNotEqual(path.stat().st_mtime_ns, OLD_STAMP)
        self.assertTrue(self.written("sample.tsv").endswith("\n1\t2\t新\n"))
        self.assertEqual([item.name for item in self.tables.iterdir()], ["sample.tsv"], "không sót tệp tạm")

    # Bước đọc lại phải đọc tệp nằm trên đĩa chứ không tin nội dung vừa dựng: giả một lượt ghi làm
    # hỏng một ô.
    def test_read_back_reads_the_file_that_is_on_disk(self) -> None:
        self.put_sample()

        def torn_write(path: Path, content: bytes) -> bool:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content.replace(b"\tabc\n", b"\tabd\n"))
            return True

        with mock.patch.object(export_config, "write_changed", torn_write):
            error = self.failure(SAMPLE)
        self.assertIn("sample.tsv: dòng dữ liệu 1 cột 2 lệch bảng gốc: \"abd\"", error)


# Lỗi của đĩa (không ghi, không đọc, không liệt kê được) là lỗi của riêng bảng đó: một dòng LỖI, mã
# 1, không traceback, và các bảng đứng sau vẫn được xuất.
class DiskFaults(Tree):
    # Đích đang là một thư mục nên không đổi tên tệp tạm đè lên được.
    def test_target_that_cannot_be_replaced_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])
        self.put_sample()
        (self.tables / "t.tsv").mkdir(parents=True)
        code, out, err = self.run_tool(PLAIN, SAMPLE)
        self.assertEqual(code, 1)
        self.assertEqual(out, "sample.tsv: 12 ô khớp bảng gốc Sample.txt (ghi mới)\n", "bảng đứng sau vẫn được xuất")
        self.assertEqual(len(err.splitlines()), 1, err)
        self.assertTrue(err.startswith(f"LỖI t.tsv: không ghi hay đọc lại được {self.tables / 't.tsv'}: "), err)
        left = sorted(path.name for path in self.tables.iterdir())
        self.assertEqual(left, ["sample.tsv", "t.tsv"], "không sót tệp tạm")

    # Chỗ của thư mục Table đang là một tệp: không tạo được thư mục, mọi bảng hỏng từng dòng một.
    def test_table_folder_that_cannot_be_made_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])
        self.put_sample()
        self.data.mkdir()
        self.tables.write_bytes(b"khong phai thu muc")
        code, out, err = self.run_tool(PLAIN, SAMPLE)
        self.assertEqual((code, out), (1, ""))
        starts = [line.split(": ")[0] for line in err.splitlines()]
        self.assertEqual(starts, ["LỖI t.tsv", "LỖI sample.tsv"], err)
        self.assertIn("không ghi hay đọc lại được", err)
        self.assertEqual(self.tables.read_bytes(), b"khong phai thu muc")

    def test_write_changed_removes_its_spare_file_when_the_swap_fails(self) -> None:
        path = self.tables / "t.tsv"
        path.mkdir(parents=True)
        with self.assertRaises(OSError):
            export_config.write_changed(path, b"x")
        self.assertEqual([item.name for item in self.tables.iterdir()], ["t.tsv"], "không sót tệp tạm")
        self.assertTrue(path.is_dir(), "thứ đang nằm ở đích không bị đụng tới")

    def test_write_that_fails_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])
        with mock.patch.object(export_config, "write_changed", side_effect=PermissionError(13, "đĩa khoá")):
            error = self.failure(PLAIN)
        self.assertIn("t.tsv: không ghi hay đọc lại được", error)
        self.assertIn("đĩa khoá", error)

    def test_target_that_cannot_be_read_under_check_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])
        self.assertEqual(self.run_tool(PLAIN)[0], 0)
        read_bytes = Path.read_bytes

        def locked(path: Path) -> bytes:
            if path.name == "t.tsv":
                raise PermissionError(13, "tệp khoá", str(path))
            return read_bytes(path)

        with mock.patch.object(Path, "read_bytes", locked):
            error = self.failure(PLAIN, is_check=True)
        self.assertIn("t.tsv: không ghi hay đọc lại được", error)
        self.assertIn("tệp khoá", error)

    # Tệp vừa ghi đọc lại không còn là UTF-8 (ghi hỏng giữa chừng): cũng là một dòng LỖI.
    def test_file_that_reads_back_as_something_else_than_utf8_is_an_ordinary_failure(self) -> None:
        self.put("T.txt", "i", [(1,)])

        def torn_write(path: Path, content: bytes) -> bool:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"\xff\xfe" + content)
            return True

        with mock.patch.object(export_config, "write_changed", torn_write):
            error = self.failure(PLAIN)
        self.assertIn("t.tsv: không ghi hay đọc lại được", error)

    def test_bundle_folder_that_cannot_be_listed_is_an_ordinary_failure(self) -> None:
        self.put_levels()
        with mock.patch.object(Path, "iterdir", side_effect=PermissionError(13, "thư mục khoá")):
            error = self.failure(LEVELS)
        self.assertIn(f"Levels: không đọc được thư mục {self.raw / 'Config' / 'Levels'}", error)
        self.assertIn("thư mục khoá", error)


class ReadBack(Tree):
    def setUp(self) -> None:
        super().setUp()
        self.put_sample()
        self.source = export_config.Source(self.raw)
        self.text = export_config.table_text(self.source, SAMPLE)

    # Lỗi của bước đọc lại khi đoạn old (có đúng một chỗ trong tệp) bị đổi thành new.
    def error_after(self, old: str, new: str) -> str:
        self.assertEqual(self.text.count(old), 1, old)
        with self.assertRaises(ExportError) as caught:
            export_config.verify(self.source, SAMPLE, self.text.replace(old, new))
        return str(caught.exception)

    def test_untouched_text_matches_every_cell(self) -> None:
        self.assertEqual(export_config.verify(self.source, SAMPLE, self.text), 12)

    def test_changed_cell_is_caught_with_its_place(self) -> None:
        cases = {
            "số nguyên": ("-5\t1.5\t", "-6\t1.5\t", "dòng dữ liệu 0 cột 0"),
            "số nguyên viết khác": ("\n7\t", "\n07\t", "dòng dữ liệu 1 cột 0"),
            "số thực lệch một bậc": ("\t1000.00006\t", "\t1000.0001\t", "dòng dữ liệu 1 cột 1"),
            "dấu của số không": ("\t-0\t", "\t0\t", "dòng dữ liệu 2 cột 1"),
            "số thực thành NaN": ("\t0.1\t", "\tnan\t", "dòng dữ liệu 3 cột 1"),
            "chuỗi": ("洛阳", "洛陽", "dòng dữ liệu 0 cột 2"),
            "chuỗi rỗng bị điền": ("\t-0\t\n", "\t-0\tx\n", "dòng dữ liệu 2 cột 2"),
        }
        for name, (old, new, where) in cases.items():
            with self.subTest(name):
                self.assertIn(f"sample.tsv: {where} lệch bảng gốc", self.error_after(old, new))

    # Ô số thực không đọc được thành số, hay vượt miền float32, là một ô lệch như mọi ô lệch khác:
    # lỗi nêu tệp, dòng và cột (trước đây lỗi trần của float_bits lọt ra, không nêu chỗ nào).
    def test_float_cell_that_is_not_a_number_is_caught_with_its_place(self) -> None:
        for bad in ("abc", "", "1e300", "0x1.8p0"):
            with self.subTest(bad):
                error = self.error_after("\t1.5\t", f"\t{bad}\t")
                self.assertEqual(error, f"sample.tsv: dòng dữ liệu 0 cột 1 lệch bảng gốc: \"{bad}\"")

    def test_missing_or_extra_rows_are_caught(self) -> None:
        cases = {
            "thiếu dòng cuối": ("-2147483648\t0.1\t镜湖\n", "", 3),
            "dòng thành chú thích": ("\n7\t", "\n#7\t", 3),
            "thừa một dòng": ("\n7\t", "\n9\t9\t9\n7\t", 5),
        }
        for name, (old, new, count) in cases.items():
            with self.subTest(name):
                self.assertIn(f"sample.tsv: {count} dòng, bảng gốc có 4", self.error_after(old, new))

    def test_missing_or_extra_cells_are_caught(self) -> None:
        cases = {"thiếu ô": ("\tabc\n", "\n", 2), "thừa ô": ("\tabc\n", "\tabc\tabc\n", 4)}
        for name, (old, new, count) in cases.items():
            with self.subTest(name):
                self.assertIn(f"sample.tsv: dòng dữ liệu 1 có {count} ô, cần 3", self.error_after(old, new))

    def test_data_rows_skip_blank_lines_comments_and_the_header(self) -> None:
        rows = export_config.data_rows("# chú thích\n\nid\tname\n1\ta\n#2\tb\n\n3\t\n")
        self.assertEqual(rows, [["1", "a"], ["3", ""]])
        self.assertEqual(export_config.data_rows("# chỉ có chú thích\n"), [])


class Bundles(Tree):
    def test_tables_are_joined_in_name_order_under_a_key_column(self) -> None:
        early, late = self.put_levels()
        code, out, err = self.run_tool(LEVELS)
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out, "levels.tsv: 9 ô khớp bảng gốc Levels (ghi mới)\n")
        digest = digest_of((digest_of(early) + digest_of(late)).encode("ascii"))
        lines = [
            f"# {export_config.NOTE}",
            f"# Nguồn: Config/Levels, 2 tệp, 3 dòng x 2 cột, sha256 {digest}",
            "# Kiểu: text\tint\ttext",
            "table\tlevel\tcolumn_1",
            "a.txt\t1\t甲",
            "a.txt\t2\t乙",
            "b.txt\t1\t丙",
        ]
        self.assertEqual((self.tables / "levels.tsv").read_bytes(), ("\n".join(lines) + "\n").encode("utf-8"))

    def test_bundle_is_checked_and_kept_like_a_single_table(self) -> None:
        self.put_levels()
        self.assertIn("levels.tsv: chưa có trong", self.failure(LEVELS, is_check=True))
        self.assertEqual(self.run_tool(LEVELS)[0], 0)
        os.utime(self.tables / "levels.tsv", ns=(OLD_STAMP, OLD_STAMP))
        for is_check in (True, False):
            code, out, _ = self.run_tool(LEVELS, is_check=is_check)
            self.assertEqual((code, out), (0, "levels.tsv: 9 ô khớp bảng gốc Levels (giữ nguyên)\n"))
        self.assertEqual((self.tables / "levels.tsv").stat().st_mtime_ns, OLD_STAMP)
        self.put("Levels/c.txt", "is", [(1, "丁")])
        self.assertIn("levels.tsv: khác tệp sẽ sinh từ kho gốc", self.failure(LEVELS, is_check=True))

    def test_folder_must_exist_and_hold_a_table(self) -> None:
        self.assertIn(f"Levels: không thấy thư mục {self.raw / 'Config' / 'Levels'}", self.failure(LEVELS))
        (self.raw / "Config" / "Levels").mkdir()
        self.assertIn("Levels: không có bảng nào", self.failure(Bundle("Levels", "levels.tsv", "table", {})))
        self.put("Levels/old.txt", "iii", [(1, 2, 3)])
        self.assertIn("Levels: không có bảng nào", self.failure(LEVELS), "rỗng sau khi bỏ tệp của skip")

    def test_skip_must_name_a_file_that_is_there(self) -> None:
        self.put("Levels/a.txt", "is", [(1, "甲")])
        self.assertIn("Levels: skip nêu tệp không có: old.txt", self.failure(LEVELS))

    def test_tables_of_another_shape_are_refused(self) -> None:
        for name, kinds, row in (("kiểu cột khác", "ii", (1, 2)), ("thừa một cột", "isi", (1, "丙", 2))):
            with self.subTest(name):
                self.put_levels()
                self.put("Levels/b.txt", kinds, [row])
                self.assertIn("Levels/b.txt: kiểu cột khác Levels/a.txt", self.failure(LEVELS))

    def test_key_and_column_names_must_be_distinct_and_inside_the_table(self) -> None:
        self.put_levels()
        repeated = "Levels: tên cột lặp trong ["
        cases = {
            "khoá trùng tên cột": ("level", {0: "level"}, repeated),
            "khoá trùng tên tự đặt": ("column_1", {0: "level"}, repeated),
            "hai cột cùng tên": ("table", {0: "level", 1: "level"}, repeated),
            "cột ngoài bảng": ("table", {0: "level", 2: "limit"}, "Levels: không có cột 2 (bảng có 2 cột)"),
        }
        for name, (key, names, reason) in cases.items():
            with self.subTest(name):
                self.assertIn(reason, self.failure(dataclasses.replace(LEVELS, key=key, names=names)))
                self.assertFalse(self.tables.exists(), "bảng hỏng thì không ghi gì")

    def test_bad_file_in_the_folder_is_reported_with_its_path(self) -> None:
        self.put_levels()
        self.put_bytes("Levels/notes.txt", b"ghi chu cua ai do, khong phai bang")
        error = self.failure(LEVELS)
        self.assertIn("Levels/notes.txt: không đọc được bảng gốc", error)
        self.assertIn("không phải bảng nhị phân DBC", error)

    def test_file_name_that_would_start_a_comment_is_refused(self) -> None:
        self.put_levels()
        self.put("Levels/#draft.txt", "is", [(1, "丁")])
        self.assertIn("Levels/#draft.txt: tên tệp không viết được thành một ô TSV", self.failure(LEVELS))

    # Tên tệp có tab hay xuống dòng không đặt được trên NTFS, nên tên đi vào qua một bundle_tables giả.
    def test_file_name_with_a_tab_or_line_break_is_refused(self) -> None:
        self.put_levels()
        source = export_config.Source(self.raw)
        loaded = source.load("Levels/a.txt")
        for name in ("a\tb.txt", "a\nb.txt", "a\rb.txt"):
            listed = mock.patch.object(export_config, "bundle_tables", return_value=[(name, loaded)])
            with self.subTest(name):
                with listed, self.assertRaises(ExportError) as caught:
                    export_config.bundle_text(source, LEVELS)
                self.assertIn(f"Levels/{name}: tên tệp không viết được thành một ô TSV", str(caught.exception))

    def test_cell_errors_name_the_file_inside_the_folder(self) -> None:
        self.put_levels()
        self.put("Levels/a.txt", "is", [(1, "甲"), (2, "乙\t乙")])
        self.assertIn("Levels/a.txt: dòng 1 cột 1: chuỗi có tab hay xuống dòng", self.failure(LEVELS))

    # Ô số thực của bảng gộp đi cùng đường với bảng đơn: vô cực bị từ chối kèm tên tệp trong thư
    # mục, và ô không phải số trong tệp TSV là một ô lệch có chỗ.
    def test_float_cells_of_a_bundle_are_refused_and_read_back_like_any_table(self) -> None:
        self.put("Levels/old.txt", "i", [(1,)])
        self.put("Levels/a.txt", "if", [(1, 1.5)])
        self.put("Levels/b.txt", "if", [(1, 2.5), (2, Raw(0x7F800000))])
        self.assertIn("LỖI Levels/b.txt: dòng 1 cột 1: số thực vô cực (mẫu bit 7f800000)", self.failure(LEVELS))
        self.put("Levels/b.txt", "if", [(1, 2.5), (2, Raw(LARGEST_FLOAT))])
        source = export_config.Source(self.raw)
        text = export_config.bundle_text(source, LEVELS)
        self.assertEqual(export_config.verify_bundle(source, LEVELS, text), 9)
        with self.assertRaises(ExportError) as caught:
            export_config.verify_bundle(source, LEVELS, text.replace("b.txt\t1\t2.5\n", "b.txt\t1\tx\n"))
        self.assertEqual(str(caught.exception), "levels.tsv: dòng dữ liệu 1 cột 1 lệch Levels/b.txt: \"x\"")

    def test_read_back_catches_wrong_table_names_and_cells(self) -> None:
        self.put_levels()
        source = export_config.Source(self.raw)
        text = export_config.bundle_text(source, LEVELS)
        self.assertEqual(export_config.verify_bundle(source, LEVELS, text), 9)
        first, second, third = "a.txt\t1\t甲\n", "a.txt\t2\t乙\n", "b.txt\t1\t丙\n"
        cases = {
            "tên bảng sai": (first, "b.txt\t1\t甲\n", "dòng dữ liệu 0 mang tên bảng \"b.txt\", cần \"a.txt\""),
            "ô nguyên lệch": (third, "b.txt\t2\t丙\n", "dòng dữ liệu 2 cột 0 lệch Levels/b.txt: \"2\""),
            "ô chuỗi lệch": (second, "a.txt\t2\t丁\n", "dòng dữ liệu 1 cột 1 lệch Levels/a.txt: \"丁\""),
            "hai dòng đổi chỗ": (first + second, second + first, "dòng dữ liệu 0 cột 0 lệch Levels/a.txt"),
            "thiếu ô": (second, "a.txt\t2\n", "dòng dữ liệu 1 có 2 ô, cần 3"),
            "thừa ô": (second, "a.txt\t2\t乙\t乙\n", "dòng dữ liệu 1 có 4 ô, cần 3"),
            "thiếu dòng": (third, "", "2 dòng, các bảng gốc có 3"),
            "thừa dòng": (third, third + third, "4 dòng, các bảng gốc có 3"),
        }
        for name, (old, new, where) in cases.items():
            with self.subTest(name):
                self.assertEqual(text.count(old), 1)
                with self.assertRaises(ExportError) as caught:
                    export_config.verify_bundle(source, LEVELS, text.replace(old, new))
                self.assertIn(f"levels.tsv: {where}", str(caught.exception))


class MainEntry(Tree):
    # Một bảng vừa đủ cột cho mỗi bảng thật của công cụ: ô của cột k mang số k, nên khoá nối ở cột
    # key mang số key; bảng nối có một dòng cho mỗi số đó, mọi cột sau cột 0 là chuỗi.
    def put_shaped_like_the_client(self) -> None:
        for spec in export_config.SPECS:
            columns = max(spec.names) + 1
            self.put(spec.source, "i" * columns, [tuple(range(columns))])
        joins = [join for spec in export_config.SPECS for join in spec.joins]
        for other in {join.other for join in joins}:
            width = max(join.value for join in joins if join.other == other)
            keys = max(join.key for join in joins if join.other == other)
            self.put(other, "i" + "s" * width, [(key,) + ("洛阳",) * width for key in range(keys + 1)])
        for bundle in export_config.BUNDLES:
            columns = max(bundle.names) + 1
            self.put(f"{bundle.folder}/Sample.txt", "i" * columns, [tuple(range(columns))])
            for name in bundle.skip:
                self.put(f"{bundle.folder}/{name}", "i", [(1,)])

    def test_missing_config_folder_is_a_usage_error(self) -> None:
        nowhere = Path(self.folder.name) / "nowhere"
        code, out, err = self.call_main(str(nowhere), str(self.data))
        self.assertEqual((code, out), (2, ""))
        self.assertEqual(err, f"không thấy {nowhere / 'Config'}\n")
        self.assertFalse(self.data.exists(), "sai cách dùng thì không ghi gì")

    def test_missing_arguments_exit_with_two(self) -> None:
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            export_config.main([str(self.raw)])
        self.assertEqual(caught.exception.code, 2)

    def test_every_real_table_fails_by_name_on_an_empty_config(self) -> None:
        code, out, err = self.call_main(str(self.raw), str(self.data))
        self.assertEqual((code, out), (1, ""))
        origins = [spec.source for spec in export_config.SPECS] + [bundle.folder for bundle in export_config.BUNDLES]
        self.assertEqual([line.split(":")[0] for line in err.splitlines()], [f"LỖI {origin}" for origin in origins])

    def test_real_tables_export_and_check_on_a_tree_shaped_like_the_client(self) -> None:
        self.put_shaped_like_the_client()
        targets = [spec.target for spec in export_config.SPECS + export_config.BUNDLES]
        code, out, err = self.call_main(str(self.raw), str(self.data))
        self.assertEqual((code, err), (0, ""))
        self.assertEqual([line.split(":")[0] for line in out.splitlines()], targets)
        self.assertTrue(all(line.endswith("(ghi mới)") for line in out.splitlines()), out)
        self.assertEqual(sorted(path.name for path in self.tables.iterdir()), sorted(targets))
        code, out, err = self.call_main(str(self.raw), str(self.data), "--check")
        self.assertEqual((code, err), (0, ""))
        self.assertTrue(all(line.endswith("(giữ nguyên)") for line in out.splitlines()), out)
        for spec in export_config.SPECS:
            header, row = self.written(spec.target).split("\n")[3:5]
            joined = [join.name for join in spec.joins]
            self.assertEqual(header.split("\t")[len(header.split("\t")) - len(joined):], joined, spec.target)
            self.assertEqual(row.split("\t")[max(spec.names) + 1:], ["洛阳"] * len(joined), spec.target)
        (self.tables / targets[0]).write_bytes(b"")
        code, _, err = self.call_main(str(self.raw), str(self.data), "--check")
        self.assertEqual(code, 1)
        self.assertEqual(err, f"LỖI {targets[0]}: khác tệp sẽ sinh từ kho gốc; chạy lại không có --check\n")


# Các bảng thật mà công cụ xuất: chỉ kiểm hình thức của hằng, không cần kho gốc.
class RealTables(unittest.TestCase):
    def test_targets_are_distinct_lowercase_tsv_names(self) -> None:
        targets = [spec.target for spec in export_config.SPECS + export_config.BUNDLES]
        self.assertEqual(len(set(targets)), len(targets), f"tên tệp đích lặp trong {targets}")
        for target in targets:
            self.assertIsNotNone(re.fullmatch(r"[a-z0-9_]+\.tsv", target), f"{target}: chỉ chữ thường, số, gạch dưới")

    # Tên cột phải viết được thành một ô của dòng tên cột: không rỗng, không tab hay xuống dòng, và
    # không mở đầu bằng # (dòng tên cột sẽ thành chú thích, dòng dữ liệu đầu thành tên cột).
    def test_column_names_are_distinct_and_fit_a_header_cell(self) -> None:
        named = {bundle.folder: [bundle.key] + list(bundle.names.values()) for bundle in export_config.BUNDLES}
        for spec in export_config.SPECS:
            named[spec.source] = list(spec.names.values()) + [join.name for join in spec.joins]
        for origin, names in named.items():
            with self.subTest(origin):
                self.assertEqual(len(set(names)), len(names), f"tên cột lặp trong {names}")
                unfit = [name for name in names if not name or name.startswith("#") or re.search(r"[\t\n\r]", name)]
                self.assertEqual(unfit, [], "tên cột không viết được thành một ô của dòng tên cột")

    # Tên đã đặt không được trùng cả với tên tự đặt column_<số> của cột chưa rõ nghĩa: dựng dòng tên
    # cột cho một bảng vừa đủ rộng.
    def test_header_can_be_built_for_every_real_table(self) -> None:
        for spec in export_config.SPECS:
            with self.subTest(spec.source):
                columns = max(spec.names) + 1
                self.assertEqual(len(export_config.column_names(spec, columns)), columns + len(spec.joins))
        for bundle in export_config.BUNDLES:
            with self.subTest(bundle.folder):
                columns = max(bundle.names) + 1
                self.assertEqual(len(export_config.bundle_names(bundle, columns)), columns + 1)


if __name__ == "__main__":
    unittest.main()
