#===============================================================================
#  THIENLONG  |  ANDROID SHELL
#-------------------------------------------------------------------------------
#  TỆP       : android/test_package_apk.py
#  PHÂN HỆ   : Test Package Apk
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Danh sách tệp đóng vào APK và bundle iOS: bao đóng của client, texture
#    đã nấu thay DDS gốc, thiếu tệp là lỗi, thay địa chỉ máy chủ của bảng cổng.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import package_apk


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def closure(root: Path, *paths: str) -> None:
    rows = ["kind\tpath", *(f"x\t{relative}" for relative in paths)]
    write(root / "Table" / "mobile.files.tsv", "\n".join(rows) + "\n")
    for relative in paths:
        write(root / relative, relative)


def names(files: list[tuple[str, Path]]) -> list[str]:
    return [relative for relative, _ in files]


class PackageList(unittest.TestCase):
    def test_closure_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            with self.assertRaises(SystemExit):
                package_apk.scene_files(Path(raw), False)

    def test_closure_files_are_listed_once(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            closure(root, "Config/startup.id", "Scene/a.Scene", "Scene/a.Scene")
            files = package_apk.scene_files(root, False)
            self.assertEqual(names(files).count("Scene/a.Scene"), 1)
            self.assertIn("Config/startup.id", names(files))

    def test_baked_textures_replace_the_dds(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw) / "data"
            baked = Path(raw) / "baked"
            closure(root, "Material/x/a.dds", "Material/x/b.png")
            write(baked / "mobile" / "astc" / "Material" / "x" / "a.dds", "astc")
            write(baked / "mobile" / "etc2" / "Material" / "x" / "a.dds", "etc2")
            files = package_apk.scene_files(root, False, baked)
            self.assertNotIn("Material/x/a.dds", names(files))
            self.assertIn("Material/x/b.png", names(files))
            self.assertIn("mobile/astc/Material/x/a.dds", names(files))
            self.assertIn("mobile/etc2/Material/x/a.dds", names(files))

    def test_ios_keeps_only_astc(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw) / "data"
            baked = Path(raw) / "baked"
            closure(root, "Material/a.dds")
            write(baked / "mobile" / "astc" / "Material" / "a.dds", "astc")
            files = package_apk.scene_files(root, False, baked, ("astc",))
            self.assertIn("mobile/astc/Material/a.dds", names(files))
            self.assertFalse(any(name.startswith("mobile/etc2/") for name in names(files)))

    def test_a_missing_tier_folder_is_an_error(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw) / "data"
            closure(root, "Material/a.dds")
            with self.assertRaises(SystemExit):
                package_apk.scene_files(root, False, Path(raw) / "empty")

    def test_a_listed_file_that_is_absent_is_an_error(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            closure(root, "Scene/a.Scene")
            (root / "Scene" / "a.Scene").unlink()
            with self.assertRaises(SystemExit):
                package_apk.require_files(package_apk.scene_files(root, False))

    def test_a_listing_may_not_leave_the_data_folder(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            write(root / "Table" / "mobile.files.tsv", "kind\tpath\nx\t../secret\n")
            with self.assertRaises(SystemExit):
                package_apk.scene_files(root, False)


class GateHost(unittest.TestCase):
    TABLE = "# chú thích\narea\tserver\thost\tgame_port\tauth_port\tkey\nA\tB\t127.0.0.1\t7000\t7001\tkhoá\n"

    def test_only_the_host_column_changes(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            closure(root, "Table/gates.tsv")
            write(root / "Table" / "gates.tsv", self.TABLE)
            files = package_apk.with_gate_host(package_apk.scene_files(root, False), "192.168.1.5", root / "work")
            source = dict(files)["Table/gates.tsv"]
            lines = source.read_text(encoding="utf-8").splitlines()
            self.assertEqual(lines[0], "# chú thích")
            self.assertEqual(lines[1], "area\tserver\thost\tgame_port\tauth_port\tkey")
            self.assertEqual(lines[2], "A\tB\t192.168.1.5\t7000\t7001\tkhoá")

    def test_empty_host_keeps_the_table(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            closure(root, "Table/gates.tsv")
            files = package_apk.scene_files(root, False)
            self.assertEqual(package_apk.with_gate_host(files, "", root / "work"), files)

    def test_a_host_that_is_not_ipv4_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            closure(root, "Table/gates.tsv")
            with self.assertRaises(SystemExit):
                package_apk.with_gate_host(package_apk.scene_files(root, False), "ten-may", root / "work")


if __name__ == "__main__":
    unittest.main()
