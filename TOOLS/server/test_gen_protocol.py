# Test của gen_protocol.py: mỗi luật G1–G11 một test, sinh tất định, --check bắt bảng đã sửa, và một
# danh mục thử phủ mọi kiểu của DE-BAI §3.2 (kể cả list của record, optional của enum).
from __future__ import annotations

import contextlib
import hashlib
import io
import itertools
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
CATALOG = REPO / "SRC" / "protocol" / "catalog"
sys.path.insert(0, str(ROOT))

import gen_protocol  # noqa: E402

TAB = "\t"
GENERATED = ("src/shared/protocol/messages.hpp", "src/shared/protocol/messages.cpp", "Test/Protocol/protocol_samples.hpp",
             "docs/PROTOCOL-TIN.md")
HEADS = {
    "groups.tsv": ["# schema 1", "# source: test", "# types: hex8\tident\ttext", "id\tname\tsummary"],
    "messages.tsv": ["# schema 1", "# source: test", "# version 2", "# types: kind\tident\tport\tint\ttext",
                     "kind\tname\tport\tsince\tsummary"],
    "fields.tsv": ["# schema 1", "# source: test", "# types: ident\tint\tident\ttype\tint\ttext",
                   "owner\torder\tname\ttype\tlimit\tnote"],
    "enums.tsv": ["# schema 1", "# source: test", "# types: ident\tu8|u16\tint\tident\ttext",
                  "enum\tunderlying\tvalue\tname\tnote"],
}
# Danh mục thử: mọi kiểu vô hướng, thời lượng, enum u8 và u16, text, bytes, list của số và của record,
# optional của enum, của text và của record, một tin không có trường, một record không có trường
# dùng làm trường đơn, đủ hai cổng và hai chiều.
ROWS = {
    "groups.tsv": [["01", "demo", "Nhóm thử."], ["02", "extra", "Nhóm thử thứ hai."]],
    "messages.tsv": [
        ["record", "Item", "", "", "Một món đồ."],
        ["0x0101", "Probe", "both", "1", "Tin thử mọi kiểu."],
        ["0x0102", "Empty", "game", "2", "Tin không có trường."],
        ["0x0201", "AuthOnly", "auth", "1", "Tin chỉ có ở cổng auth."],
        ["0x8101", "Report", "game", "1", "Tin server."],
        ["record", "Blank", "", "", "Record không có trường."],
    ],
    "fields.tsv": [
        ["Item", "1", "id", "u32", "", ""], ["Item", "2", "label", "text", "8", ""],
        ["Item", "3", "color", "enum:Color", "", ""],
        ["Probe", "1", "a", "u8", "", ""], ["Probe", "2", "b", "u16", "", ""], ["Probe", "3", "c", "u32", "", ""],
        ["Probe", "4", "d", "u64", "", ""], ["Probe", "5", "e", "i8", "", ""], ["Probe", "6", "f", "i16", "", ""],
        ["Probe", "7", "g", "i32", "", ""], ["Probe", "8", "h", "i64", "", ""],
        ["Probe", "9", "flag", "bool", "", ""], ["Probe", "10", "ratio", "f32", "", ""],
        ["Probe", "11", "wait", "seconds16", "", ""], ["Probe", "12", "delay", "millis32", "", ""],
        ["Probe", "13", "stamp", "millis64", "", ""], ["Probe", "14", "color", "enum:Color", "", ""],
        ["Probe", "15", "name", "text", "16", ""], ["Probe", "16", "blob", "bytes", "4", ""],
        ["Probe", "17", "numbers", "list:u16", "4", ""], ["Probe", "18", "items", "list:record:Item", "3", ""],
        ["Probe", "19", "maybe", "optional:enum:Color", "", ""],
        ["Probe", "20", "nick", "optional:text", "5", ""],
        ["AuthOnly", "1", "code", "u8", "", ""],
        ["Report", "1", "big", "enum:Big", "", ""], ["Report", "2", "item", "optional:record:Item", "", ""],
        ["Report", "3", "blank", "record:Blank", "", ""],
    ],
    "enums.tsv": [
        ["Color", "u8", "1", "Red", ""], ["Color", "u8", "2", "Green", ""], ["Color", "u8", "5", "Blue", ""],
        ["Big", "u16", "1", "Small", ""], ["Big", "u16", "300", "Huge", ""],
    ],
}


def write_catalog(folder: Path, rows: dict[str, list[list[str]]]) -> None:
    """Ghi bốn bảng thử, LF, UTF-8 không BOM."""
    folder.mkdir(parents=True, exist_ok=True)
    for name, head in HEADS.items():
        lines = [*head, *(TAB.join(row) for row in rows[name])]
        (folder / name).write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def copy_rows() -> dict[str, list[list[str]]]:
    return {name: [list(row) for row in rows] for name, rows in ROWS.items()}


def run_tool(arguments: list[str]) -> tuple[int, str]:
    """Chạy gen_protocol.main, gom cả stdout và stderr."""
    sink = io.StringIO()
    with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
        code = gen_protocol.main(arguments)
    return code, sink.getvalue()


def digests(folder: Path) -> dict[str, str]:
    return {name: hashlib.sha256((folder / name).read_bytes()).hexdigest() for name in GENERATED}


class Scratch(unittest.TestCase):
    """Mỗi test một thư mục tạm riêng của hệ điều hành, xoá khi xong; không ghi vào cây dự án."""

    def setUp(self) -> None:
        self.folder = Path(tempfile.mkdtemp(prefix="gen-protocol-"))

    def tearDown(self) -> None:
        shutil.rmtree(self.folder, ignore_errors=True)

    def run_rows(self, rows: dict[str, list[list[str]]]) -> tuple[int, str]:
        write_catalog(self.folder / "catalog", rows)
        return run_tool(["--catalog", str(self.folder / "catalog"), "--out", str(self.folder / "out")])

    def expect_rule(self, rows: dict[str, list[list[str]]], table: str, line: int, rule: str) -> None:
        code, output = self.run_rows(rows)
        self.assertEqual(code, 1, output)
        pattern = rf"{re.escape(table)}:{line}: \[{rule}\] "
        self.assertRegex(output, pattern)


class RuleTests(Scratch):
    """Một test cho mỗi luật; số dòng tính cả các dòng `#` và dòng tiêu đề."""

    def test_base_catalog_is_valid(self) -> None:
        code, output = self.run_rows(copy_rows())
        self.assertEqual(code, 0, output)

    def test_g1_header(self) -> None:
        write_catalog(self.folder / "catalog", copy_rows())
        path = self.folder / "catalog" / "fields.tsv"
        path.write_text(path.read_text(encoding="utf-8").replace("owner\torder", "order\towner"), encoding="utf-8",
                        newline="\n")
        code, output = run_tool(["--catalog", str(self.folder / "catalog"), "--out", str(self.folder / "out")])
        self.assertEqual(code, 1, output)
        self.assertRegex(output, r"fields\.tsv:4: \[G1\] ")

    def test_g2_kind(self) -> None:
        rows = copy_rows()
        rows["messages.tsv"][2][0] = "0x0101"
        rows["messages.tsv"][3][0] = "0x0901"
        self.expect_rule(rows, "messages.tsv", 8, "G2")
        self.expect_rule(rows, "messages.tsv", 9, "G2")

    def test_g3_names(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"][0][2] = "Id"
        rows["messages.tsv"][3][1] = "Probe"
        rows["enums.tsv"][0][0] = rows["enums.tsv"][1][0] = rows["enums.tsv"][2][0] = "class"
        self.expect_rule(rows, "fields.tsv", 5, "G3")
        self.expect_rule(rows, "messages.tsv", 9, "G3")
        self.expect_rule(rows, "enums.tsv", 5, "G3")

    def test_g3_reserved_names(self) -> None:
        # Tên lớp của channel.hpp và bí danh của protocol_samples.hpp cũng là tên đã dùng (N7).
        for name in ("Channel", "ChannelError", "InFrame", "NextFrame", "Buffer"):
            rows = copy_rows()
            rows["messages.tsv"][3][1] = name
            self.expect_rule(rows, "messages.tsv", 9, "G3")

    def test_g3_generated_names(self) -> None:
        rows = copy_rows()
        rows["messages.tsv"].append(["0x0103", "ProbeItem", "game", "1", "Tin có tên sinh ra trùng."])
        rows["fields.tsv"].append(["Probe", "21", "item_label", "text", "4", ""])
        rows["fields.tsv"].append(["ProbeItem", "1", "label", "text", "4", ""])
        rows["fields.tsv"].append(["ProbeItem", "2", "unit", "enum:Millis32", "", ""])
        rows["enums.tsv"].append(["Millis32", "u8", "1", "One", ""])
        self.expect_rule(rows, "fields.tsv", 33, "G3")
        self.expect_rule(rows, "enums.tsv", 10, "G3")

    def test_g4_port_and_since(self) -> None:
        rows = copy_rows()
        rows["messages.tsv"][1][2] = "web"
        rows["messages.tsv"][2][3] = "3"
        rows["messages.tsv"][0][2] = "game"
        self.expect_rule(rows, "messages.tsv", 7, "G4")
        self.expect_rule(rows, "messages.tsv", 8, "G4")
        self.expect_rule(rows, "messages.tsv", 6, "G4")

    def test_g5_order(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"][1][1] = "3"
        rows["fields.tsv"][4][2] = "a"
        self.expect_rule(rows, "fields.tsv", 6, "G5")
        self.expect_rule(rows, "fields.tsv", 9, "G5")

    def test_g6_types(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"][3][3] = "u128"
        rows["fields.tsv"][4][3] = "enum:Missing"
        rows["fields.tsv"][5][3:5] = ["list:list:u8", "4"]
        self.expect_rule(rows, "fields.tsv", 8, "G6")
        self.expect_rule(rows, "fields.tsv", 9, "G6")
        self.expect_rule(rows, "fields.tsv", 10, "G6")
        rows = copy_rows()
        rows["messages.tsv"].append(["record", "Hollow", "", "", "Chỉ chứa record rỗng."])
        rows["fields.tsv"].extend([["Hollow", "1", "inner", "record:Blank", "", ""],
                                   ["Report", "4", "blanks", "list:record:Blank", "3", ""],
                                   ["Report", "5", "hollows", "list:record:Hollow", "2", ""]])
        # Phần tử list 0 byte trên dây (kể cả qua record lồng) làm hỏng bất biến của Reader::count.
        self.expect_rule(rows, "fields.tsv", 33, "G6")
        self.expect_rule(rows, "fields.tsv", 34, "G6")

    def test_g6_recursive_record(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"].append(["Item", "4", "child", "optional:record:Item", "", ""])
        self.expect_rule(rows, "messages.tsv", 6, "G6")

    def test_g7_limits(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"][1][4] = ""
        rows["fields.tsv"][0][4] = "4"
        rows["fields.tsv"][18][4] = "0"
        self.expect_rule(rows, "fields.tsv", 6, "G7")
        self.expect_rule(rows, "fields.tsv", 5, "G7")
        self.expect_rule(rows, "fields.tsv", 23, "G7")

    def test_g8_enum_values(self) -> None:
        rows = copy_rows()
        rows["enums.tsv"][0][2] = "0"
        rows["enums.tsv"][2][2] = "2"
        rows["enums.tsv"][4][2] = "70000"
        self.expect_rule(rows, "enums.tsv", 5, "G8")
        self.expect_rule(rows, "enums.tsv", 7, "G8")
        self.expect_rule(rows, "enums.tsv", 9, "G8")

    def test_g8_bad_underlying_in_list(self) -> None:
        rows = copy_rows()
        for row in rows["enums.tsv"][:3]:
            row[1] = "U8"
        self.expect_rule(rows, "enums.tsv", 5, "G8")

    def test_g9_body_size(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"][17][4] = "4096"
        self.expect_rule(rows, "messages.tsv", 7, "G9")

    def test_g10_unused(self) -> None:
        rows = copy_rows()
        rows["enums.tsv"].append(["Spare", "u8", "1", "One", ""])
        rows["messages.tsv"].append(["record", "Orphan", "", "", "Không ai dùng."])
        rows["fields.tsv"].append(["Orphan", "1", "x", "u8", "", ""])
        self.expect_rule(rows, "enums.tsv", 10, "G10")
        self.expect_rule(rows, "messages.tsv", 12, "G10")

    def test_g11_owner_without_declaration(self) -> None:
        rows = copy_rows()
        rows["fields.tsv"].append(["Ghost", "1", "x", "u8", "", ""])
        self.expect_rule(rows, "fields.tsv", 32, "G11")

    def test_g11_message_without_fields(self) -> None:
        code, output = self.run_rows(copy_rows())
        self.assertEqual(code, 0, output)
        header = (self.folder / "out" / "SRC" / "protocol" / "messages.hpp").read_text(encoding="utf-8")
        self.assertIn("struct Empty {", header)


class OutputTests(Scratch):
    """Tệp sinh của danh mục thử và của danh mục thật."""

    def test_test_catalog_covers_every_type(self) -> None:
        code, output = self.run_rows(copy_rows())
        self.assertEqual(code, 0, output)
        header = (self.folder / "out" / "SRC" / "protocol" / "messages.hpp").read_text(encoding="utf-8")
        for text in ("std::vector<Item> items", "std::optional<Color> maybe", "std::optional<std::string> nick",
                     "std::chrono::seconds wait", "std::array<std::byte, kProbeBlobBytes> blob", "decode_auth_client",
                     "decode_game_server", "enum class Big : std::uint16_t"):
            self.assertIn(text, header)

    def test_empty_record_field(self) -> None:
        code, output = self.run_rows(copy_rows())
        self.assertEqual(code, 0, output)
        source = (self.folder / "out" / "SRC" / "protocol" / "messages.cpp").read_text(encoding="utf-8")
        # Record rỗng làm trường đơn: Report gọi put_blank/get_blank nên hai hàm phải được sinh.
        for text in ("void put_blank([[maybe_unused]] const Writer& writer",
                     "Blank get_blank([[maybe_unused]] const Reader& reader)", "put_blank(writer, message.blank);",
                     "message.blank = get_blank(reader);"):
            self.assertIn(text, source)

    def test_long_cases_stay_whole(self) -> None:
        rows = copy_rows()
        # Tin ngắn đầu tiên làm số dòng lệch lẻ, rồi 31 tin tên dài, mỗi `case` bẻ thành hai dòng: chia
        # phần theo dòng phẳng sẽ để nhãn `case` ở cuối một hàm và `return` ở đầu hàm sau (V2).
        rows["messages.tsv"].append(["0x0103", "Tiny", "game", "1", "Tin tên ngắn."])
        for number in range(31):
            name = f"VeryLongMessageNameForcingTheCaseToWrap{number:02d}"
            rows["messages.tsv"].append([f"0x{0x0104 + number:04X}", name, "game", "1", "Tin tên dài."])
        code, output = self.run_rows(rows)
        self.assertEqual(code, 0, output)
        lines = (self.folder / "out" / "SRC" / "protocol" / "messages.cpp").read_text(encoding="utf-8").split("\n")
        wrapped = [index for index, line in enumerate(lines) if re.fullmatch(r" {4}case \w+::kKind:", line)]
        self.assertGreater(len(wrapped), 30)
        for index in wrapped:
            self.assertTrue(lines[index + 1].startswith("        return checked("), lines[index:index + 2])
        self.assertIn("decode_game_client_2_of_", "\n".join(lines))

    def test_signatures_one_line(self) -> None:
        # AGENTS.md mục 7: chữ ký nằm trọn một dòng; dòng cột 0 kết thúc bằng `(` là chữ ký bị bẻ (N3).
        code, output = run_tool(["--out", str(self.folder / "real")])
        self.assertEqual(code, 0, output)
        for name in GENERATED:
            if name.endswith((".hpp", ".cpp")):
                text = (self.folder / "real" / name).read_text(encoding="utf-8")
                wrapped = [line for line in text.split("\n") if re.fullmatch(r"[^ /#].*\(", line)]
                self.assertEqual(wrapped, [], name)
        self.assertEqual(function_lengths("int f(\n    int a) {\n    return a;\n}\n"), [(1, 4)])

    def test_clang_format_keeps_generated_code(self) -> None:
        # Bộ sinh tự bẻ dòng. Lệch với .clang-format của dự án thì lần định dạng cả cây kế tiếp sửa
        # tệp sinh và protocol_catalog_fresh đỏ (đã xảy ra ngày 2026-10-08 khi trần lên 120 cột).
        tool = shutil.which("clang-format")
        if tool is None:
            self.skipTest("không có clang-format trên PATH")
        self.run_rows(copy_rows())
        self.assertEqual(run_tool(["--out", str(self.folder / "real")])[0], 0)
        for folder, name in itertools.product(("out", "real"), GENERATED[:3]):
            made = (self.folder / folder / name).read_bytes()
            command = [tool, f"--style=file:{REPO / '.clang-format'}", f"--assume-filename={name}"]
            styled = subprocess.run(command, input=made, capture_output=True, check=True).stdout
            self.assertTrue(styled == made, f"clang-format sửa {folder}/{name}")

    def test_generated_files_start_with_notice(self) -> None:
        self.run_rows(copy_rows())
        for name in GENERATED:
            first = (self.folder / "out" / name).read_text(encoding="utf-8").split("\n", 1)[0]
            self.assertIn("gen_protocol.py", first, name)
            self.assertNotIn(b"\r", (self.folder / "out" / name).read_bytes(), name)

    def test_generated_functions_fit_limits(self) -> None:
        self.run_rows(copy_rows())
        for name in GENERATED[:3]:
            text = (self.folder / "out" / name).read_text(encoding="utf-8")
            for start, length in function_lengths(text):
                self.assertLessEqual(length, 40, f"{name}:{start}")

    def test_deterministic(self) -> None:
        first, second = self.folder / "one", self.folder / "two"
        self.assertEqual(run_tool(["--out", str(first)])[0], 0)
        self.assertEqual(run_tool(["--out", str(second)])[0], 0)
        self.assertEqual(digests(first), digests(second))

    def test_check_reports_stale_files(self) -> None:
        copy = self.folder / "catalog"
        shutil.copytree(CATALOG, copy)
        fields = copy / "fields.tsv"
        text = fields.read_text(encoding="utf-8").replace("\tticket\ttext\t512\t", "\tticket\ttext\t511\t")
        fields.write_text(text, encoding="utf-8", newline="\n")
        code, output = run_tool(["--catalog", str(copy), "--check"])
        self.assertEqual(code, 1, output)
        self.assertIn("src/shared/protocol/messages.hpp", output)
        self.assertIn("Test/Protocol/protocol_samples.hpp", output)

    def test_check_passes_on_repo(self) -> None:
        code, output = run_tool(["--check"])
        self.assertEqual(code, 0, output)

    def test_doc_shows_kinds(self) -> None:
        doc = gen_protocol.render_all(gen_protocol.load_catalog(CATALOG))["docs/PROTOCOL-TIN.md"]
        self.assertIn("| `0x0101` | Hello |", doc)
        self.assertIn("### Reject (0x8106)", doc)
        self.assertNotIn("bound method", doc)


class EncoderTests(unittest.TestCase):
    """Bộ mã hoá Python độc lập tính byte mong đợi cho protocol_samples.hpp."""

    def test_dev_hello_bytes(self) -> None:
        import protocol_wire
        catalog = gen_protocol.load_catalog(CATALOG)
        hello = next(m for m in catalog.messages if m.name == "Hello")
        frame = protocol_wire.encode_frame(catalog, hello, {"version": 1, "platform": 2, "build": 0x01020304})
        self.assertEqual(frame.hex(" "), "07 00 00 00 01 01 00 00 01 00 02 04 03 02 01")

    def test_every_type_bytes(self) -> None:
        import protocol_wire
        with tempfile.TemporaryDirectory(prefix="gen-protocol-") as folder:
            write_catalog(Path(folder), copy_rows())
            catalog = gen_protocol.load_catalog(Path(folder))
        report = next(m for m in catalog.messages if m.name == "Report")
        value = {"big": 300, "item": {"id": 1, "label": "é", "color": 5}, "blank": {}}
        frame = protocol_wire.encode_frame(catalog, report, value)
        self.assertEqual(frame.hex(" "), "0c 00 00 00 01 81 00 00 2c 01 01 01 00 00 00 02 00 c3 a9 05")


def function_lengths(text: str) -> list[tuple[int, int]]:
    """Dòng bắt đầu và số dòng của mỗi hàm cấp ngoài cùng: mở ở cột 0, đóng bằng `}` ở cột 0."""
    found: list[tuple[int, int]] = []
    start = 0
    for number, line in enumerate(text.split("\n"), 1):
        # Đầu hàm là dòng cột 0 có `(` và kết thúc bằng `{`, hoặc bằng `(` khi chữ ký bị bẻ dòng (N4).
        head = "(" in line and not line.startswith((" ", "struct", "namespace", "enum", "//", "#"))
        if head and line.endswith(("{", "(")):
            start = number
        elif line == "}" and start:
            found.append((start, number - start + 1))
            start = 0
    return found


if __name__ == "__main__":
    unittest.main()
