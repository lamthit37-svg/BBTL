# Kiểm một lệnh sinh lại cây dữ liệu: thiếu tham số thì lỗi, hai lần --digest trùng mã.
from __future__ import annotations

import io
import os
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import build_data

PROJECT = ROOT.parents[1]


class _Capture(io.StringIO):
    def reconfigure(self, **_kwargs: object) -> None:
        return None


def _run(args: list[str]) -> tuple[int, str, str]:
    stdout = _Capture()
    stderr = _Capture()
    old_out = sys.stdout
    old_err = sys.stderr
    sys.stdout = stdout
    sys.stderr = stderr
    try:
        code = build_data.main(args)
    finally:
        sys.stdout = old_out
        sys.stderr = old_err
    return code, stdout.getvalue(), stderr.getvalue()


def _scratch(name: str) -> Path:
    path = PROJECT / "build" / "p1-l-build" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


class BuildDataContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def test_help(self) -> None:
        code, text, err = _run(["--help"])
        self.assertEqual(code, 0)
        self.assertEqual(err, "")
        self.assertIn("không ghi", text)
        self.assertIn("--digest", text)
        self.assertIn("--dest", text)
        self.assertIn("config/rules", text)

    def test_missing_arguments(self) -> None:
        code, _text, err = _run([])
        self.assertEqual(code, 1)
        self.assertEqual(err, "")
        code, _text, err = _run(["--legacy", str(self.root)])
        self.assertEqual(code, 1)
        self.assertEqual(err, "")

    def test_unknown_argument(self) -> None:
        code, text, err = _run(["--nope"])
        self.assertEqual(code, 1)
        self.assertEqual(err, "")
        self.assertIn("không rõ đối số", text)

    def test_missing_dest_value(self) -> None:
        code, text, err = _run(["--legacy", str(self.root), "--raw", str(self.root), "--dest"])
        self.assertEqual(code, 1)
        self.assertEqual(err, "")
        self.assertIn("thiếu giá trị --dest", text)

    def test_missing_config_does_not_write(self) -> None:
        dest = self.root / "out"
        code, _text, err = _run(
            [
                "--legacy",
                str(self.root / "tlbb"),
                "--raw",
                str(self.root / "raw"),
                "--dest",
                str(dest),
                "--check",
            ]
        )
        self.assertEqual(code, 1)
        self.assertEqual(err, "")
        self.assertFalse(dest.exists())

    def test_dest_redirects_away_from_server(self) -> None:
        dest = self.root / "out"
        layout = build_data._layout(dest)
        self.assertEqual(layout.tables, dest / "tables")
        self.assertEqual(layout.shared_columns, dest / "columns" / "shared")
        self.assertEqual(layout.server_columns, dest / "columns" / "server")
        self.assertEqual(layout.scene_columns, dest / "columns" / "scenes")
        self.assertEqual(layout.census, dest / "table_census.tsv")
        default = build_data._layout(PROJECT / "dev" / "server")
        self.assertIsNone(default.shared_columns)
        self.assertIsNone(default.census)
        self.assertEqual(default.tables, PROJECT / "dev" / "server" / "tables")

    def test_digest_changes_when_bytes_change(self) -> None:
        tree = self.root / "SERVER" / "tables"
        tree.mkdir(parents=True)
        target = tree / "one.tsv"
        target.write_bytes(b"id\n1\n")
        first = build_data.tree_digest([tree])
        second = build_data.tree_digest([tree])
        self.assertEqual(first, second)
        self.assertEqual(len(first), 64)
        target.write_bytes(b"id\n2\n")
        self.assertNotEqual(build_data.tree_digest([tree]), first)


class RealBuildTest(unittest.TestCase):
    def test_two_digests_match(self) -> None:
        legacy = os.environ.get("THIENLONG_LEGACY_ROOT")
        raw = os.environ.get("THIENLONG_RAW_ROOT")
        if not legacy or not raw:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT hoặc THIENLONG_RAW_ROOT")
        dest = PROJECT / "build" / "p1-l-build" / "digest"
        if dest.exists():
            shutil.rmtree(dest)
        args = ["--legacy", legacy, "--raw", raw, "--dest", str(dest), "--digest"]
        try:
            first_code, first_text, _err = _run(args)
            second_code, second_text, _err = _run(args)
        finally:
            shutil.rmtree(dest, ignore_errors=True)
        unattached = sum(1 for line in first_text.splitlines() if "không gắn được vào cảnh nào" in line)
        self.assertEqual(first_code, 0, f"lần 1 thoát {first_code}, tệp không gắn cảnh {unattached}")
        self.assertEqual(second_code, 0, f"lần 2 thoát {second_code}")
        self.assertIn("tables/server:", first_text)
        self.assertIn("tables/shared:", first_text)
        self.assertIn("tables/variants:", first_text)
        self.assertIn("scenes:", first_text)
        self.assertIn("lint_names:", first_text)
        self.assertIn("diff_tables:", first_text)
        first_hash = [line for line in first_text.splitlines() if line.startswith("sha256: ")]
        second_hash = [line for line in second_text.splitlines() if line.startswith("sha256: ")]
        self.assertEqual(len(first_hash), 1)
        self.assertEqual(first_hash, second_hash)


if __name__ == "__main__":
    unittest.main()
