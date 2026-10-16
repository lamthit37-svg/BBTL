"""Test thuần, không mở cửa sổ: py -3 -m unittest dev/GM/table_editor/test_editor.py"""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bulk  # noqa: E402
import core  # noqa: E402
import tsv_file as tf  # noqa: E402


class EditorTest(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp(prefix="table_editor_test_"))

    def tearDown(self):
        shutil.rmtree(self.dir, ignore_errors=True)

    def small(self, layout="aligned"):
        p = self.dir / "small.tsv"
        tf.write_table(p, "test/small", "TOOLS/server/import_legacy.py", ["int", "text", "float"],
                       ["id", "name", "rate"], [["1", "a  ", "0.5"], ["2", "洛阳", "1"], ["3", "x", "2e3"]], layout)
        return p

    def test_edit_render_roundtrip(self):
        for layout in ("aligned", "plain"):
            p = self.small(layout)
            lt = core.load(p)
            self.assertEqual(lt.kind, 1)
            self.assertTrue(lt.can_overwrite)
            rows = [list(r) for r in lt.rows]
            rows[1][1] = "Lạc Dương "
            text = core.render(lt, rows)
            out = self.dir / "out.tsv"
            out.write_bytes(text.encode("utf-8"))
            back = tf.read_table(out)
            self.assertEqual(back.rows[1][1], "Lạc Dương ")
            self.assertEqual(back.rows[0], ("1", "a  ", "0.5"))
            self.assertEqual(back.rows[2], ("3", "x", "2e3"))
            self.assertEqual(back.tool, lt.tool)
            # ghi đè thật + đọc lại so từng ô
            self.assertEqual(core.write_inplace(lt, rows), [])
            # aligned giữ aligned; plain ghi auto, bảng nhỏ dưới ALIGN_LIMIT nên được căn
            self.assertEqual(tf.read_table(p).layout, "aligned")

    def test_stray_comment_not_overwritable(self):
        p = self.small("plain")
        text = p.read_text(encoding="utf-8").replace("# types:", "# giải thích tự do\n# types:", 1)
        p.write_bytes(text.encode("utf-8"))
        lt = core.load(p)
        self.assertEqual(lt.kind, 1)
        self.assertEqual(lt.stray, ["# giải thích tự do"])
        self.assertFalse(lt.can_overwrite)
        self.assertTrue(lt.can_export)
        with self.assertRaises(tf.TsvError):
            core.write_inplace(lt, lt.rows)

    def test_annotation_join_scenes(self):
        notes = tf.read_table(core.REPO / "TOOLS/server/columns/server/scenes.tsv")
        i_name, i_note = notes.columns.index("name"), notes.columns.index("note")
        expected = next(r[i_note] for r in notes.rows if r[i_name] == "scene_id")
        ann = core.annotations("dev/server/tables/server/scenes.tsv")
        self.assertEqual(ann["scene_id"]["note"], expected)
        self.assertEqual(expected, "chỉ số section sceneN, mã 2008 gán m_SceneID = i")
        lines = core.column_lines("scene_id", "int", ann)
        self.assertEqual(lines[3], f"Chú thích (note): {expected}")
        self.assertEqual(len(lines), 4)

    def test_tab_rejected_before_write(self):
        p = self.small()
        before = p.read_bytes()
        lt = core.load(p)
        rows = [list(r) for r in lt.rows]
        rows[2][1] = "a\tb"
        self.assertEqual(core.check_cells(lt.columns, rows), [(2, 1, "ô chứa tab hoặc xuống dòng")])
        with self.assertRaises(tf.TsvError):
            core.write_inplace(lt, rows)
        self.assertEqual(p.read_bytes(), before)

    def test_notes_verbatim(self):
        ann = {"a": {"original": "A", "type": "int", "note": "?"},
               "b": {"original": "", "type": "int", "note": "không có bản đối chiếu"},
               "c": {"original": "C", "type": "int", "note": ""}}
        self.assertEqual(core.note_text("?"), "?")
        self.assertEqual(core.note_text("không có bản đối chiếu"), "không có bản đối chiếu")
        self.assertEqual(core.column_lines("a", "int", ann)[3], "Chú thích (note): ?")
        self.assertEqual(core.column_lines("b", "int", ann)[3], "Chú thích (note): không có bản đối chiếu")
        self.assertEqual(core.column_lines("c", "int", ann)[3], "Chú thích (note): chưa có chú thích")


class BulkTest(unittest.TestCase):
    """Logic thuần của sửa hàng loạt và chú giải cột."""

    COLS = ["id", "rate", "name"]
    TYPES = ["int", "float", "text"]

    def rows(self):
        return [["1", "0.1", "a  "], ["2", "1.50", "Lạc Dương"], ["x", "2e3", " b"], ["-4", ".5", "c"]]

    def test_assign(self):
        rows = self.rows()
        ch = bulk.op_assign(rows, [(0, 2), (1, 2), (3, 2)], "z ", self.COLS)
        self.assertEqual(len(ch), 3)
        bulk.apply(rows, ch)
        self.assertEqual([r[2] for r in rows], ["z ", "z ", " b", "z "])

    def test_delta_int_float(self):
        rows = self.rows()
        ch, skipped = bulk.op_delta(rows, [(0, 0), (1, 0), (2, 0), (3, 0)], self.TYPES, "3", self.COLS)
        self.assertEqual(skipped, [(2, 0)])
        self.assertEqual([c[3] for c in ch], ["4", "5", "-1"])
        ch, _ = bulk.op_delta(rows, [(0, 1), (1, 1), (2, 1), (3, 1)], self.TYPES, "0.2", self.COLS)
        self.assertEqual([c[3] for c in ch], ["0.3", "1.70", "2.0002e3", "0.7"])
        with self.assertRaises(bulk.BulkError):
            bulk.op_delta(rows, [(0, 0)], self.TYPES, "0.5", self.COLS)
        with self.assertRaises(bulk.BulkError):
            bulk.op_delta(rows, [(0, 2)], self.TYPES, "1", self.COLS)

    def test_scale(self):
        rows = self.rows()
        ch, _ = bulk.op_scale(rows, [(0, 0), (1, 0)], self.TYPES, "3", self.COLS)
        self.assertEqual([c[3] for c in ch], ["3", "6"])
        with self.assertRaises(bulk.BulkError):
            bulk.op_scale(rows, [(0, 0)], self.TYPES, "1.5", self.COLS)
        ch, _ = bulk.op_scale(rows, [(0, 1)], self.TYPES, "3", self.COLS)
        self.assertEqual(ch[0][3], "0.3")
        self.assertNotIn("e", ch[0][3])

    def test_series_and_filldown(self):
        rows = self.rows()
        cells = [(r, 0) for r in range(4)] + [(1, 1), (3, 1)]
        ch = bulk.op_series(rows, cells, self.TYPES, "10", "5", self.COLS)
        got = {(r, c): v for r, c, _o, v in ch}
        self.assertEqual([got.get((r, 0), rows[r][0]) for r in range(4)], ["10", "15", "20", "25"])
        self.assertEqual(got[(1, 1)], "10")
        self.assertEqual(got[(3, 1)], "15")
        with self.assertRaises(bulk.BulkError):
            bulk.op_series(rows, [(0, 0)], self.TYPES, "1", "0.5", self.COLS)
        fd = bulk.op_filldown(rows, [(0, 2), (1, 2), (2, 2)], self.COLS)
        self.assertEqual([c[3] for c in fd], ["a  ", "a  "])

    def test_replace(self):
        rows = self.rows()
        ch = bulk.op_replace(rows, [(1, 2), (2, 2)], "lạc", "X.", False, self.COLS)
        self.assertEqual(ch, [(1, 2, "Lạc Dương", "X. Dương")])
        self.assertEqual(bulk.op_replace(rows, [(1, 2)], "lạc", "X", True, self.COLS), [])
        self.assertEqual(bulk.op_replace([["a.b"]], [(0, 0)], ".", "\\1", True, ["v"])[0][3], "a\\1b")
        with self.assertRaises(bulk.BulkError):
            bulk.op_replace(rows, [(1, 2)], "Lạc", "a\tb", True, self.COLS)

    def test_paste_parsing(self):
        grid = bulk.parse_paste("1\tq \r\n2\t\n")
        self.assertEqual(grid, [["1", "q "], ["2", ""]])
        self.assertEqual(bulk.parse_paste("a\rb"), [["a"], ["b"]])
        rows = self.rows()
        ch, clipped = bulk.op_paste(rows, [["7", "8", "9", "10"], ["5", "6"]], 2, 1, 3, [2, 0], self.COLS)
        self.assertEqual(clipped, 2)  # "9", "10" vượt cột cuối
        self.assertEqual(sorted((r, c, v) for r, c, _o, v in ch), [(0, 1, "5"), (0, 2, "6"), (2, 1, "7"), (2, 2, "8")])
        self.assertEqual(bulk.copy_text(rows, [(0, 0), (1, 2)]), "1\t\n\tLạc Dương\n")

    def test_tab_rejected(self):
        rows = self.rows()
        with self.assertRaises(bulk.BulkError) as cm:
            bulk.op_assign(rows, [(1, 2), (3, 2)], "a\tb", self.COLS)
        self.assertIn("dòng 2, cột name", str(cm.exception))
        for bad in ("x\ny", "x\ry"):
            with self.assertRaises(bulk.BulkError):
                bulk.op_affix(rows, [(0, 2)], "", bad, self.COLS)
        with self.assertRaises(bulk.BulkError):
            bulk.op_clear([["a"]], [(0, 0)], ["only"])

    def test_undo_restores_exactly(self):
        rows = self.rows()
        before = [list(r) for r in rows]
        cells = [(r, c) for r in range(4) for c in range(3)]
        ch = bulk.op_affix(rows, cells, "", "  ", self.COLS)
        bulk.apply(rows, ch, True)
        self.assertNotEqual(rows, before)
        bulk.apply(rows, ch, False)
        self.assertEqual(rows, before)
        self.assertEqual(rows[0][2], "a  ")
        ch2 = bulk.op_clear(rows, cells, self.COLS)
        bulk.apply(rows, ch2, True)
        bulk.apply(rows, ch2, False)
        self.assertEqual(rows, before)

    def test_number_format(self):
        D = bulk.Decimal
        self.assertEqual(bulk.format_number(D("3"), "int"), "3")
        self.assertEqual(bulk.format_number(D("3.0"), "int"), "3")
        self.assertEqual(bulk.format_number(D("0.00000012"), "float", "0.1"), "0.00000012")
        self.assertEqual(bulk.format_number(D("1E+3"), "float", "1"), "1000")
        self.assertEqual(bulk.format_number(D("-0.0"), "float", "0"), "0.0")

    def test_tooltip(self):
        st = bulk.column_stats([["1"], ["x"], [""], ["30"], ["1"]], 0, "int")
        self.assertEqual((st.empty, st.distinct, st.bad, st.minimum, st.maximum), (1, 4, 2, "1", "30"))
        for note in ("?", "không có bản đối chiếu"):
            h = bulk.tooltip_html("c", 0, "int", {"original": "O", "note": note, "index": "3"}, True, st, "3")
            self.assertIn(f"<td width='300'>{note}</td>", h)
        h = bulk.tooltip_html("c", 2, "text", {"original": "<b>&", "note": "", "index": ""}, True, None)
        self.assertIn("&lt;b&gt;&amp;", h)
        self.assertNotIn("<b>&", h)
        self.assertIn("chưa có chú thích", h)
        self.assertIn("vị trí thật trong tệp: 2", h)
        h = bulk.tooltip_html("c", 0, "int", {"original": "O", "note": "n", "index": "3"}, True, st, "3")
        for text in ("Số ô rỗng", "<td width='300'>1</td>", "1 / 30", "Số ô sai kiểu", "index chú thích: 3"):
            self.assertIn(text, h)
        ann = core.annotations("dev/server/tables/server/scenes.tsv")
        h = bulk.tooltip_html("scene_id", 0, "int", ann["scene_id"], True, None, ann["scene_id"]["index"])
        self.assertIn(ann["scene_id"]["note"], h)


if __name__ == "__main__":
    unittest.main()
