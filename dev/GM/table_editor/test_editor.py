"""Test thuần, không mở cửa sổ: py -3 -m unittest dev/GM/table_editor/test_editor.py"""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
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


if __name__ == "__main__":
    unittest.main()
