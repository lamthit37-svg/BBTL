# Kiểm hình dạng refs/*.tsv. Ba tệp thật phải đọc được và không có dòng tool.
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import table_refs

HEADER = (
    "# schema 1\n"
    "# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
    "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n"
)


class RefHeaderTest(unittest.TestCase):
    def test_three_files_are_hand_tables(self) -> None:
        for name in ("shared.tsv", "server.tsv", "scenes.tsv"):
            path = ROOT / "refs" / name
            text = path.read_text(encoding="utf-8")
            self.assertIn("# schema 1\n", text)
            self.assertNotIn("# tool:", text)
            rows = table_refs.read_ref_file(path)
            self.assertIsInstance(rows, tuple)

    def test_duplicate_key_across_files_is_an_error(self) -> None:
        folder = ROOT.parents[1] / "build" / "p1-d3-refs"
        if folder.exists():
            for path in folder.glob("*.tsv"):
                path.unlink()
        folder.mkdir(parents=True, exist_ok=True)
        body = (
            "tables/shared/a.tsv\tid\ttables/shared/b.tsv\tid\t-1;0\t0\tlabel\tnhãn\n"
        )
        (folder / "a.tsv").write_text(HEADER + body, encoding="utf-8", newline="\n")
        (folder / "b.tsv").write_text(HEADER + body, encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError):
            table_refs.read_refs(folder)

    def test_two_stars_in_one_segment_are_a_shape_error(self) -> None:
        folder = ROOT.parents[1] / "build" / "p2-c-refs-star"
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / "bad.tsv"
        row = "tables/a*b*.tsv\tid\ttables/shared/b.tsv\tid\t\t0\tdata\tx\n"
        path.write_text(HEADER + row, encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError) as caught:
            table_refs.read_ref_file(path)
        self.assertIn("sai mẫu", str(caught.exception))

    def test_column_n_and_bad_basis_are_rejected(self) -> None:
        folder = ROOT.parents[1] / "build" / "p1-d3-refs-bad"
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / "bad.tsv"
        row = "tables/shared/a.tsv\tcolumn_0\ttables/shared/b.tsv\tid\t\t0\tguess\t\n"
        path.write_text(HEADER + row, encoding="utf-8", newline="\n")
        with self.assertRaises(ValueError):
            table_refs.read_ref_file(path)


if __name__ == "__main__":
    unittest.main()
