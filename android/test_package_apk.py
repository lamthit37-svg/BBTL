# Danh sách tệp đóng vào APK: cảnh chơi, hai cảnh đăng nhập, không nhân đôi khi trùng tên.
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import package_apk


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def fixture(root: Path, startup_stem: str) -> None:
    write(root / "Config" / "startup.id", "7\n")
    write(root / "Config" / "SceneDefineEx.txt", f"7\tten\t1\t1\t{startup_stem}.Scene\n")
    stems = [startup_stem, *package_apk.login_scene_stems()]
    for stem in stems:
        write(root / "Scene" / f"{stem}.files.tsv", f"scene\tScene/{stem}.Scene\n")


class PackageList(unittest.TestCase):
    def test_constants_match_the_headers(self) -> None:
        self.assertEqual(package_apk.login_scene_stems(), ["erengu_DL", "tl3chuangjian"])

    def test_startup_and_login_scenes_are_listed_once(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            fixture(root, "huoyangu")
            write(root / "Web" / "coming_soon.html", "<p>Coming soon</p>\n")
            paths = package_apk.scene_paths(root, False)
            self.assertIn("Scene/huoyangu.Scene", paths)
            self.assertIn("Scene/erengu_DL.Scene", paths)
            self.assertIn("Scene/tl3chuangjian.Scene", paths)
            self.assertIn("Web/coming_soon.html", paths)
            self.assertEqual(paths.count("Scene/erengu_DL.Scene"), 1)
            self.assertEqual(paths.count("Config/startup.id"), 1)

    def test_startup_that_is_the_login_scene_is_not_repeated(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            fixture(root, "erengu_DL")
            paths = package_apk.scene_paths(root, False)
            self.assertEqual(paths.count("Scene/erengu_DL.Scene"), 1)
            self.assertIn("Scene/tl3chuangjian.Scene", paths)

    def test_a_bad_constant_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            header = Path(raw) / "bad.hpp"
            header.write_text('constexpr std::string_view kLoginScene = "../x";\n', encoding="utf-8")
            with self.assertRaises(SystemExit):
                package_apk.quoted_constant(header, "kLoginScene")

    def test_a_comment_does_not_hide_the_real_constant(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            header = Path(raw) / "note.hpp"
            header.write_text(
                '// constexpr std::string_view kLoginScene = "sai";\n'
                'inline constexpr std::string_view kLoginScene = "erengu_DL";\n',
                encoding="utf-8",
            )
            self.assertEqual(package_apk.quoted_constant(header, "kLoginScene"), "erengu_DL")

    def test_two_listings_share_one_file_once(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            fixture(root, "huoyangu")
            shared = "Scene/chung.png"
            login = package_apk.login_scene_stems()[0]
            write(root / "Scene" / "huoyangu.files.tsv", f"scene\tScene/huoyangu.Scene\ntex\t{shared}\n")
            write(root / "Scene" / f"{login}.files.tsv", f"scene\tScene/{login}.Scene\ntex\t{shared}\n")
            paths = package_apk.scene_paths(root, False)
            self.assertEqual(paths.count(shared), 1)


if __name__ == "__main__":
    unittest.main()
