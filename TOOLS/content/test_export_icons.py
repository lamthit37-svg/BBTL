# Kiểm bộ xuất bảng tra icon (export_icons.py): thứ tự map của CEGUI (ngắn hơn đứng trước, cùng độ
# dài so byte UTF-32), bộ nào là bộ icon và tên ảnh trùng thuộc về bộ nào, nội dung icons.tsv, bước
# đọc lại, và cả lượt chạy trên một cây Interface/Schema/all.imageset.xml nhỏ dựng trong thư mục tạm
# (ghi mới, giữ nguyên, --check, kho gốc hỏng, sai cách dùng). Không đụng kho thật.
# Chạy: python -B TOOLS/content/test_export_icons.py

from __future__ import annotations

import contextlib
import io
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import collect_ui
import export_config
import export_icons
from export_icons import IconError, IconSet

ALL = collect_ui.ALL_IMAGESET
EXTRA = "Schema/extra.imageset.xml"
HEAD = '<?xml version="1.0" encoding="utf-8"?>\n'
# Mốc sửa đổi cũ (nano giây) đặt cho tệp đích để thấy nó có bị ghi lại hay không.
OLD_STAMP = 1_000_000_000 * 10**9
# U+0100 có byte thấp 00, U+00E9 có byte thấp E9: so byte UTF-32 thì U+0100 đứng trước cả chữ ASCII.
LOW_BYTE_ZERO = chr(0x0100)
LOW_BYTE_HIGH = chr(0x00E9)


def order(names: list[str]) -> list[str]:
    return sorted(names, key=export_icons.cegui_order)


# Một bộ icon khai trong all.imageset.xml.
def icons(name: str, *images: str) -> IconSet:
    return IconSet(name, f"Icons/{name}.dds", ALL, images)


# Phần tử Imageset của một bộ ảnh; tên đưa vào nguyên văn nên viết được cả thực thể XML.
def imageset(name: str, imagefile: str, *images: str) -> str:
    rows = "".join(f'    <Image Name="{image}" XPos="0" YPos="0" Width="1" Height="1" />\n' for image in images)
    return f'  <Imageset Name="{name}" Imagefile="{imagefile}">\n{rows}  </Imageset>\n'


def imagesets(*sets: str) -> str:
    return HEAD + "<Imagesets>\n" + "".join(sets) + "</Imagesets>\n"


# Bốn bộ ảnh viết ngược thứ tự của CEGUI: hai bộ icon chung ảnh Ride_01, một bộ không phải icon
# cũng có Ride_01, và một bộ icon tên tiếng Trung có tệp ảnh viết bằng dấu gạch ngược.
DEFAULT = imagesets(
    imageset("NPCRideHeader1", "Icons/NPCRide1.dds", "Ride_01", "Ride_02"),
    imageset("RideHeader1", "Icons/Ride1.dds", "Ride_01", "Ride_09"),
    imageset("Frames", "Common/Frames.dds", "Ride_01", "Border"),
    imageset("技能", "Icons\\Skill.dds", "火球", "a"),
)
DEFAULT_TABLE = "\n".join([
    f"# {export_icons.NOTE}",
    "# 5 icon của 3 bộ ảnh",
    "icon\timageset",
    "Ride_01\tRideHeader1",
    "Ride_02\tNPCRideHeader1",
    "Ride_09\tRideHeader1",
    "a\t技能",
    "火球\t技能",
]) + "\n"


class Order(unittest.TestCase):
    def test_shorter_name_comes_first(self) -> None:
        names = ["NPCRideHeader1", "RideHeader1", "Zz", "b"]
        self.assertEqual(order(names), ["b", "Zz", "RideHeader1", "NPCRideHeader1"])
        self.assertEqual(sorted(names)[0], "NPCRideHeader1", "xếp theo chữ thì bộ dài hơn lại đứng trước")

    def test_same_length_compares_bytes(self) -> None:
        self.assertEqual(order(["ab", "aB", "Ab", "AB"]), ["AB", "Ab", "aB", "ab"])
        self.assertEqual(export_icons.cegui_order("ab"), (2, b"a\0\0\0b\0\0\0"))

    def test_non_ascii_compares_the_low_byte_first(self) -> None:
        names = ["z", LOW_BYTE_HIGH, LOW_BYTE_ZERO]
        self.assertEqual(sorted(names), ["z", LOW_BYTE_HIGH, LOW_BYTE_ZERO], "thứ tự theo mã ký tự")
        self.assertEqual(order(names), [LOW_BYTE_ZERO, "z", LOW_BYTE_HIGH], "thứ tự theo byte của UTF-32")
        # U+4E01 (byte 01 4E) và U+4F00 (byte 00 4F): byte thấp quyết định trước byte cao.
        self.assertEqual(order([chr(0x4E01), chr(0x4F00)]), [chr(0x4F00), chr(0x4E01)])
        self.assertEqual(order(["a" + LOW_BYTE_ZERO, "az"]), ["a" + LOW_BYTE_ZERO, "az"], "ký tự đầu bằng nhau")

    # Ký tự ngoài mặt phẳng cơ bản (U+1D11E) là một phần tử của chuỗi UTF-32, không phải hai.
    def test_length_counts_characters_not_bytes(self) -> None:
        clef = chr(0x1D11E)
        self.assertEqual(export_icons.cegui_order(clef), (1, b"\x1e\xd1\x01\x00"))
        self.assertEqual(order(["abc", "技能", clef]), [clef, "技能", "abc"])


class Owners(unittest.TestCase):
    def test_only_sets_whose_image_file_starts_with_icons_count(self) -> None:
        sets = [
            IconSet("Skill", "Icons/Skill.dds", ALL, ("fire",)),
            IconSet("Extra", "IconsEx/Extra.dds", ALL, ("gem",)),
            IconSet("Lower", "icons/Lower.dds", ALL, ("lower",)),
            IconSet("Upper", "ICONS/Upper.dds", ALL, ("upper",)),
            IconSet("Inside", "Common/Icons/Inside.dds", ALL, ("inside",)),
            IconSet("Blank", "", ALL, ("blank",)),
        ]
        self.assertEqual(export_icons.icon_owners(sets), {"fire": "Skill", "gem": "Extra"})
        self.assertEqual(export_icons.icon_owners([]), {})

    def test_shared_image_belongs_to_the_set_that_sorts_first(self) -> None:
        sets = [icons("NPCRideHeader1", "Ride_01", "Ride_02"), icons("RideHeader1", "Ride_01", "Ride_09")]
        wanted = {"Ride_01": "RideHeader1", "Ride_02": "NPCRideHeader1", "Ride_09": "RideHeader1"}
        for name, listed in {"dài trước": sets, "ngắn trước": sets[::-1]}.items():
            with self.subTest(name):
                self.assertEqual(export_icons.icon_owners(list(listed)), wanted)

    def test_same_length_sets_are_ordered_by_bytes(self) -> None:
        sets = [icons("Skilla", "fire"), icons("SkillB", "fire", "ice"), icons("Skill" + LOW_BYTE_ZERO, "ice")]
        self.assertEqual(export_icons.icon_owners(sets), {"fire": "SkillB", "ice": "Skill" + LOW_BYTE_ZERO})

    def test_set_that_is_not_an_icon_set_never_owns_an_image(self) -> None:
        sets = [IconSet("A", "Common/A.dds", ALL, ("fire",)), icons("Skill", "fire")]
        self.assertEqual(export_icons.icon_owners(sets), {"fire": "Skill"})

    def test_icon_set_outside_the_main_imageset_file_is_refused(self) -> None:
        stray = IconSet("Pet", "Icons/Pet.dds", EXTRA, ("cat",))
        with self.assertRaises(IconError) as caught:
            export_icons.icon_owners([icons("Skill", "fire"), stray])
        self.assertIn(f"bộ icon Pet nằm ở {EXTRA}, ngoài {ALL}", str(caught.exception))
        plain = IconSet("Frames", "Common/Frames.dds", EXTRA, ("Border",))
        self.assertEqual(export_icons.icon_owners([icons("Skill", "fire"), plain]), {"fire": "Skill"})


class TableText(unittest.TestCase):
    def test_rows_are_sorted_by_the_bytes_of_the_icon_name(self) -> None:
        owners = {"b": "Two", "ab": "One", "B": "One", LOW_BYTE_HIGH: "Two", "一": "One"}
        lines = export_icons.table_text(owners).split("\n")
        self.assertEqual(lines[:3], [f"# {export_icons.NOTE}", "# 5 icon của 2 bộ ảnh", "icon\timageset"])
        wanted = ["B\tOne", "ab\tOne", "b\tTwo", f"{LOW_BYTE_HIGH}\tTwo", "一\tOne", ""]
        self.assertEqual(lines[3:], wanted, "chữ hoa trước chữ thường, không xếp theo độ dài")

    def test_empty_table_has_only_the_header(self) -> None:
        self.assertEqual(export_icons.table_text({}), f"# {export_icons.NOTE}\n# 0 icon của 0 bộ ảnh\nicon\timageset\n")

    def test_names_that_do_not_fit_a_cell_are_refused(self) -> None:
        cases = {
            "tên icon rỗng": {"": "Skill"},
            "tên icon có tab": {"a\tb": "Skill"},
            "tên icon có xuống dòng": {"a\nb": "Skill"},
            "tên icon có về đầu dòng": {"a\rb": "Skill"},
            "tên icon mở đầu bằng #": {"#a": "Skill"},
            "tên bộ rỗng": {"fire": ""},
            "tên bộ có tab": {"fire": "Sk\till"},
            "tên bộ mở đầu bằng #": {"fire": "#Skill"},
        }
        for name, owners in cases.items():
            (icon, owner), = owners.items()
            with self.subTest(name):
                with self.assertRaises(IconError) as caught:
                    export_icons.table_text({"good": "Skill"} | owners)
                self.assertIn(f"tên \"{icon}\" hay \"{owner}\" không viết được thành một ô TSV", str(caught.exception))


class ReadBack(unittest.TestCase):
    OWNERS = {"fire": "Skill", "ice": "Skill", "cat": "Pet"}

    def setUp(self) -> None:
        self.text = export_icons.table_text(self.OWNERS)

    def error_after(self, old: str, new: str) -> str:
        self.assertEqual(self.text.count(old), 1, old)
        with self.assertRaises(IconError) as caught:
            export_icons.verify(self.OWNERS, self.text.replace(old, new))
        return str(caught.exception)

    def test_untouched_text_matches_every_row(self) -> None:
        self.assertEqual(export_icons.verify(self.OWNERS, self.text), 3)
        self.assertEqual(export_icons.verify({}, export_icons.table_text({})), 0)

    def test_missing_or_extra_rows_are_caught(self) -> None:
        row = "fire\tSkill\n"
        cases = {"thiếu dòng": ("", 2), "dòng thành chú thích": ("#" + row, 2), "thừa dòng": (row + "x\tSkill\n", 4)}
        for name, (new, count) in cases.items():
            with self.subTest(name):
                self.assertIn(f"icons.tsv: {count} dòng, kho gốc có 3 icon", self.error_after(row, new))

    def test_changed_row_is_caught_with_its_number(self) -> None:
        cases = {
            "bộ ảnh khác": ("fire\tSkill\n", "fire\tPet\n", 1),
            "tên icon lạ": ("ice\tSkill\n", "snow\tSkill\n", 2),
            "thiếu ô": ("cat\tPet\n", "cat\n", 0),
            "thừa ô": ("cat\tPet\n", "cat\tPet\tPet\n", 0),
        }
        for name, (old, new, number) in cases.items():
            with self.subTest(name):
                self.assertIn(f"icons.tsv: dòng dữ liệu {number} lệch kho gốc: [", self.error_after(old, new))

    def test_repeated_icon_name_is_caught(self) -> None:
        self.assertIn("icons.tsv: có tên icon lặp", self.error_after("ice\tSkill\n", "fire\tSkill\n"))


# Một kho gốc chỉ có cây Interface và một thư mục dữ liệu rỗng trong thư mục tạm của build/.
class Tree(unittest.TestCase):
    def setUp(self) -> None:
        build = ROOT.parents[1] / "build"
        build.mkdir(exist_ok=True)
        self.folder = tempfile.TemporaryDirectory(dir=build)
        self.raw = Path(self.folder.name) / "raw"
        self.data = Path(self.folder.name) / "data"
        self.target = self.data / "Table" / "icons.tsv"
        self.interface = self.raw / collect_ui.INTERFACE

    def tearDown(self) -> None:
        self.folder.cleanup()

    # Dựng lại cây Interface chỉ gồm các tệp nêu ra (đường dẫn tính từ Interface).
    def put(self, files: dict[str, str | bytes]) -> None:
        if self.interface.exists():
            shutil.rmtree(self.interface)
        self.interface.mkdir(parents=True)
        for relative, content in files.items():
            path = self.interface / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content if isinstance(content, bytes) else content.encode("utf-8"))

    def run_tool(self, is_check: bool = False) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = export_icons.run(self.raw, self.data, is_check)
        return code, out.getvalue(), err.getvalue()

    # Lượt chạy phải hỏng với mã 1 và đúng một dòng LỖI; trả dòng đó.
    def failure(self, is_check: bool = False) -> str:
        code, out, err = self.run_tool(is_check)
        self.assertEqual((code, out), (1, ""), err)
        self.assertEqual(len(err.splitlines()), 1, err)
        self.assertTrue(err.startswith("LỖI "), err)
        return err

    def call_main(self, *arguments: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = export_icons.main(list(arguments))
        return code, out.getvalue(), err.getvalue()


class ReadSets(Tree):
    def by_name(self) -> dict[str, IconSet]:
        return {one.name: one for one in export_icons.read_sets(self.raw)}

    def test_sets_carry_their_file_and_image_names(self) -> None:
        self.put({ALL: DEFAULT})
        sets = self.by_name()
        self.assertEqual(sorted(sets), ["Frames", "NPCRideHeader1", "RideHeader1", "技能"])
        self.assertEqual(sets["技能"], IconSet("技能", "Icons/Skill.dds", ALL, ("火球", "a")), "gạch ngược thành gạch xuôi")
        self.assertEqual(sets["Frames"], IconSet("Frames", "Common/Frames.dds", ALL, ("Ride_01", "Border")))

    # Tệp aaa đứng trước all theo tên; bộ trùng tên vẫn phải lấy bản của all.imageset.xml.
    def test_main_imageset_file_is_read_first_so_its_sets_win(self) -> None:
        early = "Schema/aaa.imageset.xml"
        self.put({
            early: imagesets(imageset("Skill", "Common/Old.dds", "old"), imageset("Frames", "Common/F.dds", "Border")),
            ALL: imagesets(imageset("Skill", "Icons/Skill.dds", "fire")),
        })
        sets = self.by_name()
        self.assertEqual(sets["Skill"], IconSet("Skill", "Icons/Skill.dds", ALL, ("fire",)))
        self.assertEqual(sets["Frames"].origin, early)

    def test_lone_imageset_files_anywhere_under_interface_are_read(self) -> None:
        lone = "Minimap/Deep/Map.imageset.xml"
        self.put({ALL: DEFAULT, lone: HEAD + imageset("Map", "Minimap/Map.dds", "North")})
        self.assertEqual(self.by_name()["Map"], IconSet("Map", "Minimap/Map.dds", lone, ("North",)))

    def test_gbk_file_is_decoded(self) -> None:
        text = imagesets(imageset("技能", "Icons/Skill.dds", "火球")).replace('encoding="utf-8"', 'encoding="GB2312"')
        self.put({ALL: text.encode("gbk")})
        self.assertEqual(self.by_name()["技能"].images, ("火球",))

    def test_broken_source_becomes_an_icon_error(self) -> None:
        cases = {
            "XML hỏng": (imagesets("  <Imageset Name=\"Skill\">\n"), f"{ALL}: XML hỏng"),
            "không giải mã được": (b"<Imagesets>\xff\xff\xff</Imagesets>", f"{ALL}: không giải mã được"),
            "số lạ": (imagesets(imageset("Skill", "Icons/S.dds", "fire").replace('XPos="0"', 'XPos="x"')),
                      "imageset Skill: ảnh fire: số lạ"),
        }
        for name, (content, reason) in cases.items():
            with self.subTest(name):
                self.put({ALL: content})
                with self.assertRaises(IconError) as caught:
                    export_icons.read_sets(self.raw)
                self.assertIn(reason, str(caught.exception))
        shutil.rmtree(self.interface)
        with self.assertRaises(IconError) as caught:
            export_icons.read_sets(self.raw)
        self.assertIn(f"không có thư mục {self.interface}", str(caught.exception))


class Run(Tree):
    def test_table_is_written_from_the_imagesets(self) -> None:
        self.put({ALL: DEFAULT})
        code, out, err = self.run_tool()
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out, "icons.tsv: 5 icon khớp kho gốc (ghi mới)\n")
        self.assertEqual(self.target.read_bytes(), DEFAULT_TABLE.encode("utf-8"), "UTF-8 không BOM, dòng kết bằng \\n")
        self.assertEqual([path.name for path in self.target.parent.iterdir()], ["icons.tsv"], "không sót tệp tạm")

    def test_unchanged_table_is_not_rewritten(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        os.utime(self.target, ns=(OLD_STAMP, OLD_STAMP))
        code, out, _ = self.run_tool()
        self.assertEqual((code, out), (0, "icons.tsv: 5 icon khớp kho gốc (giữ nguyên)\n"))
        self.assertEqual(self.target.stat().st_mtime_ns, OLD_STAMP, "nội dung không đổi thì không ghi lại")
        self.put({ALL: imagesets(imageset("Skill", "Icons/Skill.dds", "fire"))})
        code, out, _ = self.run_tool()
        self.assertEqual((code, out), (0, "icons.tsv: 1 icon khớp kho gốc (ghi mới)\n"))
        self.assertTrue(self.target.read_text(encoding="utf-8").endswith("icon\timageset\nfire\tSkill\n"))

    def test_check_fails_when_the_table_was_never_written(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertIn(f"icons.tsv: chưa có trong {self.target.parent}", self.failure(is_check=True))
        self.assertFalse(self.data.exists(), "--check không tạo gì")

    def test_check_fails_on_a_single_changed_byte(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        good = self.target.read_bytes()
        places = {"chú thích": good.index(b"Sinh"), "ô dữ liệu": good.index(b"Ride_09"), "byte cuối": len(good) - 1}
        for name, at in places.items():
            with self.subTest(name):
                changed = good[:at] + bytes([good[at] ^ 1]) + good[at + 1:]
                self.target.write_bytes(changed)
                self.assertIn("icons.tsv: khác tệp sẽ sinh từ kho gốc", self.failure(is_check=True))
                self.assertEqual(self.target.read_bytes(), changed, "--check không sửa tệp")

    def test_check_passes_on_the_written_table_and_leaves_it_alone(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        os.utime(self.target, ns=(OLD_STAMP, OLD_STAMP))
        code, out, err = self.run_tool(is_check=True)
        self.assertEqual((code, out, err), (0, "icons.tsv: 5 icon khớp kho gốc (giữ nguyên)\n", ""))
        self.assertEqual(self.target.stat().st_mtime_ns, OLD_STAMP, "--check không ghi")

    def test_check_fails_when_the_source_changed_after_the_export(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        self.put({ALL: DEFAULT.replace("Ride_09", "Ride_10")})
        self.assertIn("icons.tsv: khác tệp sẽ sinh từ kho gốc", self.failure(is_check=True))

    # Kho gốc hỏng thì lượt chạy trả 1 và bảng đang có không bị đụng tới.
    def test_broken_source_fails_and_keeps_the_written_table(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        os.utime(self.target, ns=(OLD_STAMP, OLD_STAMP))
        stray = imageset("Pet", "Icons/Pet.dds", "cat")
        plain = imagesets(imageset("Frames", "Common/Frames.dds", "Border"))
        cases = {
            "không còn icon nào": ({ALL: plain}, "icons.tsv: kho gốc không có icon nào"),
            "XML hỏng": ({ALL: DEFAULT.replace("</Imagesets>", "")}, f"{ALL}: XML hỏng"),
            "tệp lẻ hỏng": ({ALL: DEFAULT, EXTRA: "<Imageset"}, f"{EXTRA}: XML hỏng"),
            "bộ icon ở tệp lẻ": ({ALL: DEFAULT, EXTRA: HEAD + stray}, f"bộ icon Pet nằm ở {EXTRA}, ngoài {ALL}"),
            "ảnh không tên": ({ALL: imagesets(imageset("Skill", "Icons/S.dds", "fire").replace(' Name="fire"', ""))},
                             "tên \"\" hay \"Skill\" không viết được thành một ô TSV"),
            "ảnh tên có tab": ({ALL: imagesets(imageset("Skill", "Icons/S.dds", "fi&#9;re"))},
                               "tên \"fi\tre\" hay \"Skill\" không viết được thành một ô TSV"),
            "bộ icon không tên": ({ALL: imagesets(imageset("", "Icons/S.dds", "fire"))},
                                 "tên \"fire\" hay \"\" không viết được thành một ô TSV"),
            "thiếu thư mục Interface": (None, f"không có thư mục {self.interface}"),
        }
        for name, (files, reason) in cases.items():
            with self.subTest(name):
                self.put(files or {})
                if files is None:
                    shutil.rmtree(self.interface)
                self.assertIn(reason, self.failure())
                self.assertEqual(self.target.read_bytes(), DEFAULT_TABLE.encode("utf-8"))
                self.assertEqual(self.target.stat().st_mtime_ns, OLD_STAMP)

    # Bước đọc lại phải đọc tệp nằm trên đĩa chứ không tin nội dung vừa dựng: giả một lượt ghi làm
    # hỏng một dòng.
    def test_read_back_reads_the_file_that_is_on_disk(self) -> None:
        self.put({ALL: DEFAULT})

        def torn_write(path: Path, content: bytes) -> bool:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content.replace(b"Ride_09\tRideHeader1\n", b"Ride_09\tNPCRideHeader1\n"))
            return True

        with mock.patch.object(export_config, "write_changed", torn_write):
            self.assertIn("icons.tsv: dòng dữ liệu 2 lệch kho gốc: ['Ride_09', 'NPCRideHeader1']", self.failure())

    # Kho gốc không có icon nào (không tệp imageset, chỉ có bộ không phải icon, hay bộ icon không có
    # ảnh) là kho gốc hỏng: bảng 0 dòng không bao giờ là kết quả đúng, nên không ghi, và --check
    # cũng từ chối một bảng 0 dòng đang nằm sẵn dù nó trùng từng byte.
    def test_source_without_any_icon_is_refused(self) -> None:
        cases = {
            "không có tệp imageset": {},
            "chỉ có bộ không phải icon": {ALL: imagesets(imageset("Frames", "Common/Frames.dds", "Border"))},
            "bộ icon không có ảnh": {ALL: imagesets(imageset("Skill", "Icons/Skill.dds"))},
        }
        for name, files in cases.items():
            with self.subTest(name):
                self.put(files)
                self.assertIn("LỖI icons.tsv: kho gốc không có icon nào", self.failure())
                self.assertFalse(self.data.exists(), "không ghi bảng rỗng")
        empty = export_icons.table_text({}).encode("utf-8")
        self.target.parent.mkdir(parents=True)
        self.target.write_bytes(empty)
        self.assertIn("LỖI icons.tsv: kho gốc không có icon nào", self.failure(is_check=True))
        self.assertEqual(self.target.read_bytes(), empty, "--check không sửa tệp")

    # Lỗi của đĩa là một dòng LỖI mã 1, không traceback. Đích đang là một thư mục nên không đổi tên
    # tệp tạm đè lên được; tệp tạm không được để sót.
    def test_target_that_cannot_be_replaced_is_an_ordinary_failure(self) -> None:
        self.put({ALL: DEFAULT})
        self.target.mkdir(parents=True)
        error = self.failure()
        self.assertTrue(error.startswith(f"LỖI icons.tsv: không ghi hay đọc lại được {self.target}: "), error)
        self.assertEqual([path.name for path in self.target.parent.iterdir()], ["icons.tsv"], "không sót tệp tạm")

    def test_target_that_cannot_be_read_under_check_is_an_ordinary_failure(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.run_tool()[0], 0)
        read_bytes = Path.read_bytes

        def locked(path: Path) -> bytes:
            if path.name == "icons.tsv":
                raise PermissionError(13, "tệp khoá", str(path))
            return read_bytes(path)

        with mock.patch.object(Path, "read_bytes", locked):
            error = self.failure(is_check=True)
        self.assertIn("icons.tsv: không ghi hay đọc lại được", error)
        self.assertIn("tệp khoá", error)

    # Tệp vừa ghi đọc lại không còn là UTF-8 (ghi hỏng giữa chừng): cũng là một dòng LỖI.
    def test_file_that_reads_back_as_something_else_than_utf8_is_an_ordinary_failure(self) -> None:
        self.put({ALL: DEFAULT})

        def torn_write(path: Path, content: bytes) -> bool:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"\xff\xfe" + content)
            return True

        with mock.patch.object(export_config, "write_changed", torn_write):
            self.assertIn("icons.tsv: không ghi hay đọc lại được", self.failure())

    def test_source_file_that_cannot_be_read_is_an_ordinary_failure(self) -> None:
        self.put({ALL: DEFAULT})
        with mock.patch.object(collect_ui, "read_raw", side_effect=PermissionError(13, "tệp khoá")):
            error = self.failure()
        self.assertIn("không đọc được kho gốc", error)
        self.assertIn("tệp khoá", error)
        self.assertFalse(self.data.exists(), "kho gốc hỏng thì không ghi gì")

    # Bộ trùng tên ở tệp lẻ không tính (bản của all.imageset.xml thắng); bộ không phải icon ở tệp
    # lẻ không cản và không góp ảnh nào vào bảng.
    def test_set_declared_again_in_a_lone_file_is_ignored(self) -> None:
        again = HEAD + imageset("RideHeader1", "Icons/Other.dds", "Ride_77")
        plain = HEAD + imageset("Map", "Minimap/Map.dds", "a")
        self.put({ALL: DEFAULT, EXTRA: again, "Other/Map.imageset.xml": plain})
        self.assertEqual(self.run_tool()[0], 0)
        self.assertEqual(self.target.read_bytes(), DEFAULT_TABLE.encode("utf-8"))


class MainEntry(Tree):
    def test_missing_interface_folder_is_a_usage_error(self) -> None:
        code, out, err = self.call_main(str(self.raw), str(self.data))
        self.assertEqual((code, out), (2, ""))
        self.assertEqual(err, f"không thấy {self.interface}\n")
        self.assertFalse(self.data.exists(), "sai cách dùng thì không ghi gì")

    def test_missing_arguments_exit_with_two(self) -> None:
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            export_icons.main([str(self.raw)])
        self.assertEqual(caught.exception.code, 2)

    def test_export_then_check_through_the_command_line(self) -> None:
        self.put({ALL: DEFAULT})
        self.assertEqual(self.call_main(str(self.raw), str(self.data), "--check")[0], 1, "chưa có bảng")
        code, out, err = self.call_main(str(self.raw), str(self.data))
        self.assertEqual((code, out, err), (0, "icons.tsv: 5 icon khớp kho gốc (ghi mới)\n", ""))
        code, out, err = self.call_main(str(self.raw), str(self.data), "--check")
        self.assertEqual((code, out, err), (0, "icons.tsv: 5 icon khớp kho gốc (giữ nguyên)\n", ""))
        self.put({ALL: "<Imagesets>"})
        code, out, err = self.call_main(str(self.raw), str(self.data))
        self.assertEqual((code, out), (1, ""))
        self.assertTrue(err.startswith(f"LỖI {ALL}: XML hỏng"), err)


if __name__ == "__main__":
    unittest.main()
