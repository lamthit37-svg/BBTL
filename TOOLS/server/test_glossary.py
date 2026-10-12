# Đối chiếu glossary.tsv với bảng thuật ngữ ở mục 1 của phụ lục.
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
APPENDIX = ROOT.parents[1] / "docs" / "SERVER-TEP-CAU-HINH.md"
GLOSSARY = ROOT / "glossary.tsv"
KEEP = frozenset({"mission", "task", "variance", "platform", "point"})


def _cells(line: str) -> list[str]:
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|"):
        body = body[:-1]
    return [part.strip() for part in body.split("|")]


def _split_list(text: str) -> list[str]:
    if text == "":
        return []
    return [part.strip() for part in text.split(",")]


def _name_and_note(cell: str) -> tuple[str, str]:
    if cell.endswith(")") and " (" in cell:
        name, note = cell.rsplit(" (", 1)
        return name.strip(), note[:-1].strip()
    return cell, ""


def _align(originals: list[str], values: list[str]) -> list[str]:
    if len(values) == 1:
        return values * len(originals)
    if len(values) == len(originals):
        return values
    raise ValueError(f"không khớp số mục: {originals} / {values}")


def _banned(original: str, name: str) -> str:
    folded = original.casefold()
    if folded in KEEP or folded in name.split("_") or folded == name:
        return "0"
    return "1"


def appendix_rows() -> list[tuple[str, str, str, str]]:
    """Mỗi từ gốc một dòng: original, chinese, name, banned."""
    lines = APPENDIX.read_text(encoding="utf-8").splitlines()
    start = lines.index("Bảng thuật ngữ (tên gốc sang từ dùng trong tên tệp, tên cột và mã):")
    rows: list[tuple[str, str, str, str]] = []
    for line in lines[start + 1 :]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = _cells(line)
        if len(cells) < 3 or cells[0] in ("Bản gốc", "---") or set(cells[0]) <= {"-"}:
            continue
        originals = _split_list(cells[0])
        chinese = _align(originals, _split_list(cells[1]))
        name_cell, _note = _name_and_note(cells[2])
        names = _align(originals, _split_list(name_cell))
        for index, original in enumerate(originals):
            rows.append((original, chinese[index], names[index], _banned(original, names[index])))
    return rows


def _tsv_rows() -> list[tuple[str, str, str, str]]:
    rows: list[tuple[str, str, str, str]] = []
    for line in GLOSSARY.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or line.startswith("original\t"):
            continue
        original, chinese, name, banned = line.split("\t")
        rows.append((original, chinese, name, banned))
    return rows


class GlossaryMatchesAppendixTest(unittest.TestCase):
    def test_rows_match_the_markdown_table(self) -> None:
        self.assertEqual(_tsv_rows(), appendix_rows())

    def test_hand_file_has_no_tool_line(self) -> None:
        text = GLOSSARY.read_text(encoding="utf-8")
        self.assertIn("# schema 1\n", text)
        self.assertIn("# types: text\ttext\ttext\ttext\n", text)
        self.assertNotIn("# tool:", text)


if __name__ == "__main__":
    unittest.main()
