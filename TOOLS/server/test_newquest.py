# Khoá số MisDesc của 22 tệp edali_newquest. Ca này đọc script trong cây, không ghi TSV.
from __future__ import annotations

import io
import sys
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import newquest
import quest_chains as QC

MAIN = [
    1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1423, 1412, 1413, 1414, 1415, 1416, 1417,
    1418, 1419, 1420, 1421, 1422,
]
CHOICES = [10402085, 10401073, 10404078, 10403073, 10406001]


def quest_of(descs, quest):
    return next(item for item in descs if item.quest == quest)


def out_of(outs, quest):
    return next(item for item in outs if item.quest == quest)


class NewquestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.descs = newquest.read_all()
        cls.outs = newquest.outs_of(cls.descs, None)

    def test_twenty_two_files_and_path(self):
        self.assertEqual(len(self.descs), 22)
        for desc in self.descs:
            self.assertTrue(desc.path.startswith(newquest.PATH_PREFIX))
            self.assertTrue(desc.path.endswith(".lua"))
            self.assertEqual(desc.kind, 13)
        self.assertTrue(all(item.source == "table" for item in self.outs))

    def test_chain_order(self):
        main = [item.quest for item in self.descs if item.chain_role == "chính"]
        main.sort(key=lambda quest: quest_of(self.descs, quest).chain_step)
        side = [item.quest for item in self.descs if item.chain_role == "nhánh"]
        self.assertEqual(main, MAIN)
        self.assertEqual(side, [1424])
        self.assertEqual(quest_of(self.descs, 1422).next_script, 0)
        self.assertEqual(out_of(self.outs, 1422).next_quest, -1)

    def test_talk_kill_and_rewards(self):
        first = quest_of(self.descs, 1400)
        first_out = out_of(self.outs, 1400)
        self.assertEqual(first.name, "初涉江湖")
        self.assertEqual(first.script, 210262)
        self.assertEqual(first.pre, 0)
        self.assertEqual(first_out.prereqs, [])
        self.assertEqual(first_out.status, "ok")
        self.assertEqual(first_out.next_script, 210255)
        self.assertEqual(first_out.next_quest, 1401)
        self.assertEqual(first_out.objectives[0].kind, "talk")
        self.assertEqual(first_out.objectives[0].name, "赵天师")
        self.assertEqual([(item.kind, item.count) for item in first_out.rewards], [("money", 1), ("exp", 50)])

        kill = out_of(self.outs, 1403)
        self.assertEqual(kill.objectives[0].kind, "kill")
        self.assertEqual(kill.objectives[0].name, "高山白猿")
        self.assertEqual(kill.objectives[0].count, 5)
        self.assertNotEqual(kill.objectives[0].target, 708)
        self.assertTrue(any("708" in note for note in quest_of(self.descs, 1403).notes))
        self.assertEqual(
            [(item.kind, item.ref, item.count) for item in kill.rewards],
            [("money", 0, 30), ("exp", 0, 258), ("item", 10110000, 1)],
        )

        learned = quest_of(self.descs, 1405)
        skill = out_of(self.outs, 1405)
        self.assertEqual(learned.giver, "赵天师")
        self.assertEqual(learned.turn, "钱龙")
        self.assertEqual(skill.status, "ok")
        self.assertEqual(skill.prereqs, [])
        self.assertEqual(skill.reason, "")
        self.assertEqual(
            [(item.kind, item.index, item.item, item.name, item.count) for item in skill.objectives],
            [("skill", 0, 244, "张获", 1), ("skill", 1, 248, "程青霜", 1)],
        )
        self.assertTrue(any("AcceptNPC_Name" in note for note in learned.notes))
        self.assertTrue(any("MisDesc không có hàm học" in note for note in learned.notes))

        ape = out_of(self.outs, 1407)
        self.assertEqual(ape.objectives[0].name, "蜀道白猿")
        self.assertEqual(ape.objectives[0].count, 5)
        self.assertEqual([item.kind for item in ape.rewards], ["money", "exp"])
        self.assertEqual(ape.rewards[1].count, 1008)
        self.assertTrue(any("719" in note for note in quest_of(self.descs, 1407).notes))

        wood = out_of(self.outs, 1420)
        self.assertEqual(wood.objectives[0].name, "木头人")
        self.assertEqual(wood.objectives[0].count, 5)
        self.assertEqual(wood.prereqs, [1419])
        self.assertEqual(wood.rewards[1].count, 3000)

        sect = quest_of(self.descs, 1421)
        sect_out = out_of(self.outs, 1421)
        self.assertEqual(sect.per, 1424)
        self.assertEqual(sect_out.prereqs, [])
        self.assertEqual(sect_out.rewards, [])
        self.assertEqual(sect_out.status, "unsupported")

        decade = quest_of(self.descs, 1424)
        decade_out = out_of(self.outs, 1424)
        self.assertIsNone(decade.pre)
        self.assertEqual(decade.exp, 0)
        self.assertEqual([(item.kind, item.count) for item in decade_out.rewards], [("bound_money", 500)])
        self.assertEqual(decade_out.next_script, 210268)
        self.assertEqual(decade_out.status, "ok")
        self.assertEqual([(item.kind, item.count, item.target) for item in decade_out.objectives], [("level", 10, 0)])
        self.assertTrue(any("g_exp" in note for note in decade.notes))
        self.assertTrue(any("已达等级" in note for note in decade.notes))

        pet = quest_of(self.descs, 1414)
        self.assertEqual(pet.status, "unsupported")
        self.assertEqual(pet.customs[0].ident, "小兔子升到2级")
        self.assertEqual(out_of(self.outs, 1414).objectives, [])

        family = quest_of(self.descs, 1413)
        family_out = out_of(self.outs, 1413)
        self.assertIsNone(family.pre)
        self.assertEqual(family_out.status, "ok")
        self.assertEqual(family.giver, "赵天师")
        self.assertEqual(family_out.objectives[0].name, "云飘飘")

        give = out_of(self.outs, 1423)
        self.assertEqual(give.status, "unsupported")
        self.assertEqual([(item.kind, item.count) for item in give.rewards], [("money", 300), ("exp", 1500)])

        weapon = out_of(self.outs, 1401)
        picked = [item.ref for item in weapon.rewards if item.group == "choice"]
        self.assertEqual(picked, CHOICES)

    def test_unsupported_has_no_objective(self):
        by_script = {item.script: item for item in self.descs}
        for out in self.outs:
            if by_script[out.script].status != "ok":
                self.assertEqual(out.objectives, [])

    def test_extract_calls_append_before_resolve(self):
        text = (ROOT / "lua_extract.py").read_text(encoding="utf-8")
        append_at = text.find("newquest.append_quests(ctx)")
        resolve_at = text.find("BU.resolve_next(ctx.quests)")
        self.assertGreater(append_at, 0)
        self.assertLess(append_at, resolve_at)
        self.assertEqual(text.count("newquest.append_quests(ctx)"), 1)

    def test_existing_rows_keep_our_prefix(self):
        path = QC.SERVER / "mission_quests.tsv"
        if not path.is_file():
            self.skipTest("chưa có mission_quests.tsv")
        import tsv_file

        table = tsv_file.read_table(path)
        script_at = table.columns.index("script")
        path_at = table.columns.index("path")
        quest_at = table.columns.index("quest")
        ours = {item.script for item in self.descs}
        for row in table.rows:
            if int(row[script_at]) in ours:
                self.assertTrue(row[path_at].startswith(newquest.PATH_PREFIX))
            if int(row[quest_at]) in {item.quest for item in self.descs}:
                self.assertTrue(row[path_at].startswith(newquest.PATH_PREFIX))

    def test_excel_fragment_keeps_script_numbers(self):
        rows = QC.newbie_rows(self.descs, QC.item_index(), QC.dictionary_index(), QC.track_index(), {})
        width = len(rows[0])
        self.assertTrue(all(len(row) == width for row in rows))
        blob = QC.workbook_bytes([("Tân thủ", rows)])
        with zipfile.ZipFile(io.BytesIO(blob)) as book:
            xml = book.read("xl/worksheets/sheet1.xml").decode("utf-8")
        self.assertIn("初涉江湖", xml)
        self.assertIn("258", xml)
        self.assertIn("10110000", xml)
        self.assertIn("(equipment)", xml)

    def test_rows_fit_live_tables(self):
        world = QC.load_world()
        planned = QC.validate(self.descs, world)
        self.assertIn("mission_quests", planned)
        groups = planned["mission_name_groups"][1]
        templates = {int(row[1]) for row in groups}
        self.assertTrue({703, 708, 709, 718, 719}.issubset(templates))
        placed = newquest.outs_of(self.descs, world)
        skill = out_of(placed, 1405)
        self.assertEqual(
            [(item.item, item.name, item.target) for item in skill.objectives],
            [(244, "张获", 3202248), (248, "程青霜", 3542065)],
        )


if __name__ == "__main__":
    unittest.main()
