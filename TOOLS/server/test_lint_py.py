# Kiểm cổng lint_py: mỗi luật G1–G6 một ca hỏng và một ca sát ngưỡng.
from __future__ import annotations

import io
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import lint_py

PROJECT = ROOT.parents[1]


class _Capture(io.StringIO):
    def reconfigure(self, **_kwargs: object) -> None:
        return None


def _scratch(name: str) -> Path:
    path = PROJECT / "build" / "p1-lint" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _run(args: list[str]) -> tuple[int, str, str]:
    stdout = _Capture()
    stderr = _Capture()
    old_out = sys.stdout
    old_err = sys.stderr
    sys.stdout = stdout
    sys.stderr = stderr
    try:
        code = lint_py.main(args)
    finally:
        sys.stdout = old_out
        sys.stderr = old_err
    return code, stdout.getvalue(), stderr.getvalue()


def _body(assignments: int) -> str:
    lines = ["def sample() -> None:"]
    for index in range(assignments):
        lines.append(f"    value = {index}")
    lines.append("    return")
    return "\n".join(lines) + "\n"


def _drive_text() -> str:
    letter = "C"
    escaped = "\\" + "\\"
    return f'path = "{letter}:{escaped}Windows"\n'


class LintFixtureTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _file(self, text: str) -> Path:
        path = self.root / "sample.py"
        path.write_text(text, encoding="utf-8", newline="\n")
        return path

    def _errors(self, text: str) -> list[str]:
        return lint_py._check_file(self._file(text))

    def test_threshold_passes(self) -> None:
        text = _body(48) + "def flat(value: int) -> int:\n    if value:\n        return value\n    return 0\n"
        self.assertEqual(self._errors(text), [])

    def test_long_function(self) -> None:
        errors = self._errors(_body(49))
        self.assertEqual(len(errors), 1)
        self.assertIn("dài 51 dòng", errors[0])

    def test_deep_nesting(self) -> None:
        text = (
            "def deep() -> None:\n"
            "    if True:\n"
            "        if True:\n"
            "            if True:\n"
            "                if True:\n"
            "                    return\n"
        )
        errors = self._errors(text)
        self.assertTrue(any("lồng 4 mức" in error for error in errors))

    def test_elif_and_else_if_do_not_add(self) -> None:
        text = (
            "def flat() -> None:\n"
            "    if True:\n"
            "        return\n"
            "    elif False:\n"
            "        return\n"
            "    else:\n"
            "        if False:\n"
            "            return\n"
        )
        self.assertEqual(self._errors(text), [])

    def test_nested_function_restarts(self) -> None:
        text = (
            "def outer() -> None:\n"
            "    if True:\n"
            "        def inner() -> None:\n"
            "            if True:\n"
            "                if True:\n"
            "                    if True:\n"
            "                        if True:\n"
            "                            return\n"
            "        return\n"
        )
        errors = self._errors(text)
        self.assertEqual(len(errors), 1)
        self.assertIn("hàm inner", errors[0])

    def test_long_line(self) -> None:
        text = "def short() -> None:\n    value = " + ("x" * 110) + "\n    return\n"
        errors = self._errors(text)
        self.assertTrue(any("quá 120" in error for error in errors))

    def test_missing_types(self) -> None:
        errors = self._errors("def bare(value):\n    return value\n")
        self.assertTrue(any("tham số value" in error for error in errors))
        self.assertTrue(any("thiếu kiểu trả" in error for error in errors))

    def test_self_and_cls_are_exempt(self) -> None:
        text = (
            "class Box:\n"
            "    def read(self, name: str) -> str:\n"
            "        return name\n"
            "    @classmethod\n"
            "    def make(cls, name: str) -> Box:\n"
            "        return cls()\n"
        )
        self.assertEqual(self._errors(text), [])

    def test_bare_except(self) -> None:
        text = "def run() -> None:\n    try:\n        return\n    except:\n        return\n"
        errors = self._errors(text)
        self.assertTrue(any("except trần" in error for error in errors))

    def test_broad_except_must_reraise(self) -> None:
        bad = "def run() -> None:\n    try:\n        return\n    except Exception:\n        return\n"
        good = "def run() -> None:\n    try:\n        return\n    except Exception:\n        raise\n"
        self.assertTrue(any("không raise lại" in error for error in self._errors(bad)))
        self.assertEqual(self._errors(good), [])

    def test_drive_path_and_url(self) -> None:
        self.assertTrue(any("ổ đĩa" in error for error in self._errors(_drive_text())))
        url = 'url = "https://example.com/a"\n'
        self.assertEqual(self._errors(url), [])

    def test_main_captures_and_formats(self) -> None:
        path = self._file("def bare(value):\n    return value\n")
        code, out, err = _run([str(path)])
        self.assertEqual(code, 1)
        self.assertEqual(err, "")
        self.assertIn("hàm bare thiếu kiểu của tham số value", out)
        self.assertIn("hàm bare thiếu kiểu trả", out)
        code, out, err = _run([str(self._file("def ready() -> None:\n    return\n"))])
        self.assertEqual(code, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")

    def test_help_and_unknown(self) -> None:
        code, out, err = _run(["--help"])
        self.assertEqual(code, 0)
        self.assertIn("50 dòng", out)
        self.assertEqual(err, "")
        code, out, err = _run(["--nope"])
        self.assertEqual(code, 1)
        self.assertIn("không rõ đối số", out)
        self.assertEqual(err, "")

    def test_missing_file(self) -> None:
        errors = lint_py._check_file(self.root / "khong-co.py")
        self.assertEqual(len(errors), 1)
        self.assertIn("không phải tệp", errors[0])

    def test_linter_files_are_clean(self) -> None:
        self.assertEqual(lint_py._check_file(ROOT / "lint_py.py"), [])
        self.assertEqual(lint_py._check_file(Path(__file__)), [])


if __name__ == "__main__":
    unittest.main()
