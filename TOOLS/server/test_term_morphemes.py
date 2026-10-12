# Đối chiếu term_morphemes.tsv với bảng thuộc tính ở mục 1 của phụ lục.
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
APPENDIX = ROOT.parents[1] / "docs" / "SERVER-TEP-CAU-HINH.md"
MORPHEMES = ROOT / "term_morphemes.tsv"
MARKER = "Thuật ngữ thuộc tính và chiến đấu, tra theo chữ Trung"


def _cells(line: str) -> list[str]:
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|"):
        body = body[:-1]
    return [part.strip().replace("`", "") for part in body.split("|")]


def appendix_rows() -> list[tuple[str, str, str, str]]:
    """Mỗi dòng bảng: chinese, name, banned, basis."""
    lines = APPENDIX.read_text(encoding="utf-8").splitlines()
    start = next(index for index, line in enumerate(lines) if line.startswith(MARKER))
    rows: list[tuple[str, str, str, str]] = []
    for line in lines[start + 1 :]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = _cells(line)
        if len(cells) < 4 or cells[0] in ("Chữ Trung", "---") or set(cells[0]) <= {"-"}:
            continue
        rows.append((cells[0], cells[1], cells[2], cells[3]))
    return rows


def _tsv_rows() -> list[tuple[str, str, str, str]]:
    rows: list[tuple[str, str, str, str]] = []
    for line in MORPHEMES.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or line.startswith("chinese\t"):
            continue
        chinese, name, banned, basis = line.split("\t")
        rows.append((chinese, name, banned, basis))
    return rows


class MorphemeMatchesAppendixTest(unittest.TestCase):
    def test_rows_match_the_markdown_table(self) -> None:
        self.assertEqual(_tsv_rows(), appendix_rows())

    def test_hand_file_has_no_tool_line(self) -> None:
        text = MORPHEMES.read_text(encoding="utf-8")
        self.assertIn("# schema 1\n", text)
        self.assertIn("# types: text\ttext\ttext\ttext\n", text)
        self.assertNotIn("# tool:", text)


if __name__ == "__main__":
    unittest.main()
