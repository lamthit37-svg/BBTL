# Kiểm table_names.tsv: mỗi tệp gốc một phân loại, đúng fate, không đường dẫn máy.
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import tsv_file

PROJECT = ROOT.parents[1]
FATES = {
    "table",
    "reference",
    "rules",
    "process_config",
    "scene_data",
    "client_only",
    "dropped",
    "deferred",
}
TARGET_OK = (
    "tables/server/",
    "tables/shared/",
    "tables/variants/",
)


def _banned() -> str:
    slash = "F:" + "/"
    back = "F:" + "\\" + "\\"
    return "Users|Desktop|THIENLONG_LEGACY|" + slash + "|" + back


def _row(
    rows: tuple[tsv_file.NameRow, ...],
    tree: str,
    source: str,
    **expect: str,
) -> list[tsv_file.NameRow]:
    found = [row for row in rows if row.tree == tree and row.source == source]
    if not found:
        raise AssertionError(f"thiếu {tree}/{source}")
    for row in found:
        for field, value in expect.items():
            if getattr(row, field) != value:
                raise AssertionError(f"{tree}/{source} {field}={getattr(row, field)!r} khác {value!r}")
    return found


class NameMapContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.rows = tsv_file.read_name_map()

    def test_required_fields_and_enums(self) -> None:
        seen = set()
        for row in self.rows:
            self.assertIn(row.fate, FATES)
            self.assertIn(row.owner, {"", "A", "B", "C"})
            self.assertIn(row.unresolved, {"0", "1"})
            self.assertIn(row.key_field, {"", "box_key", "shop_key", "variant"})
            self.assertNotIn("\\", row.source)
            self.assertNotIn("\\", row.target)
            self.assertNotRegex(row.source, r"^[A-Za-z]:")
            self.assertNotIn("..", Path(row.source).parts)
            identity = (row.tree, row.source, row.fate, row.target, row.key)
            self.assertNotIn(identity, seen)
            seen.add(identity)
            self.assertEqual(row.unresolved, "1" if "?" in row.note else "0")
            for cell in (row.tree, row.source, row.fate, row.target, row.key_field, row.key, row.owner, row.note):
                self.assertNotIn("\t", cell)
                self.assertNotRegex(cell, _banned())
            if row.fate == "table":
                self.assertTrue(row.target.startswith(TARGET_OK))
                self.assertIn(row.owner, {"A", "B", "C"})
                self.assertTrue(row.target.endswith(".tsv"))
            else:
                self.assertEqual(row.target, "")
            if row.key_field == "":
                self.assertEqual(row.key, "")
            else:
                self.assertNotEqual(row.key, "")
            if row.owner == "A":
                self.assertEqual(row.tree, "client_2026")
                self.assertEqual(row.fate, "table")
            if row.owner == "B":
                self.assertIn(row.tree, {"server_config", "public_config", "public_data"})
                self.assertEqual(row.fate, "table")
            if row.owner == "C":
                self.assertEqual(row.tree, "public_data")
                self.assertEqual(row.source, "Script")
                self.assertIn(
                    row.target,
                    {
                        "tables/server/scene_load_refs.tsv",
                        "tables/server/scene_level_files.tsv",
                    },
                )

    def test_server_examples(self) -> None:
        rows = self.rows
        _row(
            rows,
            "server_config",
            "StandardImpact.txt",
            fate="table",
            target="tables/server/effects.tsv",
            owner="B",
            unresolved="0",
        )
        _row(rows, "server_config", "Account.txt", fate="dropped", target="", owner="", key="")
        _row(
            rows,
            "server_config",
            "boxdroplist.txt",
            fate="table",
            target="tables/server/loot_box_entries.tsv",
            key_field="box_key",
            key="default",
            owner="B",
        )
        _row(
            rows,
            "server_config",
            "boxdroplist_baibaoshuxia.txt",
            key="treasure_tree",
            unresolved="1",
            key_field="box_key",
        )
        _row(rows, "server_config", "boxdroplist_zhuandan1.txt", key="gacha_1", unresolved="0")
        _row(rows, "server_config", "boxdroplist_zhuandansl.txt", key="gacha_shaolin")
        scene = _row(rows, "server_config", "SceneInfo.ini", fate="table", owner="B")
        self.assertEqual({row.target for row in scene}, {"tables/server/scenes.tsv", "tables/server/scene_hosting.tsv"})
        system = _row(rows, "server_config", "SystemInfo.ini", fate="table")
        system_targets = {row.target for row in system}
        self.assertEqual(
            system_targets,
            {"tables/server/rolling_announcements.tsv", "tables/server/scheduled_events.tsv"},
        )
        config = _row(rows, "server_config", "ConfigInfo.ini", target="", owner="")
        self.assertEqual({row.fate for row in config}, {"process_config", "rules"})
        _row(rows, "server_config", "ChatConfig.txt", fate="reference", target="")
        _row(rows, "server_config", "ItemSegValue.txt", target="tables/server/item_segment_values.tsv", owner="B")
        _row(rows, "server_config", "ItemSerial.ini", fate="dropped")
        _row(rows, "server_config", "AllowableScriptFunc.txt", fate="deferred")
        boxes = [row for row in rows if row.key_field == "box_key"]
        self.assertEqual(len(boxes), 35)
        self.assertEqual(len({row.key for row in boxes}), 35)

    def test_public_and_client_examples(self) -> None:
        rows = self.rows
        _row(
            rows,
            "public_data",
            "Script.dat",
            fate="table",
            target="tables/server/script_index.tsv",
            owner="B",
            unresolved="0",
        )
        _row(
            rows,
            "public_data",
            "AIScript.dat",
            fate="table",
            target="tables/server/monster_ai_scripts.tsv",
            owner="B",
            unresolved="0",
        )
        scripts = _row(rows, "public_data", "Script", fate="table", owner="C", unresolved="0")
        targets = {row.target for row in scripts}
        self.assertEqual(
            targets,
            {
                "tables/server/scene_load_refs.tsv",
                "tables/server/scene_level_files.tsv",
            },
        )

    def test_public_config_examples(self) -> None:
        rows = self.rows
        _row(rows, "public_config", "CombatLimits.ini", fate="rules", target="", owner="")
        _row(
            rows,
            "public_config",
            "CampAndStand.txt",
            fate="table",
            target="tables/server/camp_relations.tsv",
            owner="B",
        )
        _row(rows, "public_config", "SkillTemplate_V1.txt", fate="reference", target="", owner="")
        _row(
            rows,
            "public_config",
            "RandShop/60wufang.ini",
            fate="table",
            target="tables/server/random_shop_goods.tsv",
            key_field="shop_key",
            key="workshop_60",
            owner="B",
        )
        _row(rows, "public_config", "AbilityLevelUp/caikuang.txt", fate="reference")
        _row(rows, "public_config", "AbilityLevelUp/XinFaStudySpend_V1.txt", fate="dropped")
        shops = [row for row in rows if row.key_field == "shop_key"]
        self.assertEqual(len(shops), 15)
        self.assertEqual(len({row.key for row in shops}), 15)
        flights = [row for row in rows if row.source.startswith("MountFlight/")]
        self.assertGreater(len(flights), 0)
        self.assertTrue(all(row.fate == "deferred" and row.target == "" for row in flights))

    def test_client_examples(self) -> None:
        rows = self.rows
        _row(
            rows,
            "client_2026",
            "SkillTemplate_V1.txt",
            fate="table",
            target="tables/shared/skills.tsv",
            owner="A",
            unresolved="0",
        )
        _row(rows, "client_2026", "ItemSegValue.txt", target="tables/shared/item_segment_values.tsv", owner="A")
        _row(rows, "client_2026", "StrDictionary.txt", fate="client_only", target="", owner="")
        _row(
            rows,
            "client_2026",
            "AbilityLevelUp/caikuang.txt",
            fate="table",
            target="tables/shared/life_skill_levels/mining.tsv",
            owner="A",
        )
        _row(rows, "client_2026", "AbilityLevelUp/XinFaStudySpend_V1.txt", fate="dropped", target="")
        _row(rows, "client_2026", "ActionSet/ActionSet.txt", fate="table", owner="A", unresolved="1")
        _row(rows, "client_2026", "Script.dat", fate="deferred", target="")
        _row(rows, "client_2026", "city0_LevelUp.lua", fate="deferred")
        variants = [row for row in rows if row.source.startswith("ShopTable_") and row.key == "level_cap"]
        self.assertEqual(len(variants), 1)
        self.assertEqual(variants[0].target, "tables/variants/level_cap/shops.tsv")
        self.assertEqual(variants[0].key_field, "variant")
        events = [row for row in rows if row.source.startswith("event/") and row.source.endswith(".lua")]
        self.assertGreater(len(events), 0)
        self.assertTrue(all(row.fate == "deferred" for row in events))

    def test_variant_targets_match_key(self) -> None:
        for row in self.rows:
            if row.key_field != "variant":
                continue
            prefix = f"tables/variants/{row.key}/"
            self.assertTrue(row.target.startswith(prefix), row.source)
            self.assertEqual(row.owner, "A")
            self.assertEqual(row.tree, "client_2026")


def _files(root: Path) -> set[str]:
    found = set()
    for path in root.rglob("*"):
        if path.is_file():
            found.add(path.relative_to(root).as_posix())
    return found


class DiskCoverageTest(unittest.TestCase):
    def test_every_source_file_once(self) -> None:
        legacy = os.environ.get("THIENLONG_LEGACY_ROOT")
        raw = os.environ.get("THIENLONG_RAW_ROOT")
        if not legacy or not raw:
            self.skipTest("thiếu THIENLONG_LEGACY_ROOT hoặc THIENLONG_RAW_ROOT")
        trees = {
            "server_config": Path(legacy) / "Server" / "Config",
            "public_config": Path(legacy) / "Public" / "Config",
            "client_2026": Path(raw) / "Config",
        }
        for tree, root in trees.items():
            if not root.is_dir():
                self.fail(f"không thấy {root}")
        rows = tsv_file.read_name_map()
        multi = {
            ("server_config", "SceneInfo.ini"),
            ("server_config", "SystemInfo.ini"),
            ("server_config", "ConfigInfo.ini"),
        }
        data_root = Path(legacy) / "Public" / "Data"
        data_rows = [row for row in rows if row.tree == "public_data"]
        self.assertEqual({row.source for row in data_rows}, {"Script.dat", "AIScript.dat", "Script"})
        for row in data_rows:
            found = data_root / row.source
            if row.source == "Script":
                self.assertTrue(found.is_dir(), row.source)
                continue
            self.assertTrue(found.is_file(), row.source)
        for tree, root in trees.items():
            disk = _files(root)
            listed = [row.source for row in rows if row.tree == tree]
            self.assertEqual(set(listed), disk, tree)
            counts: dict[str, int] = {}
            for source in listed:
                counts[source] = counts.get(source, 0) + 1
            for source, count in counts.items():
                if (tree, source) in multi:
                    self.assertEqual(count, 2, source)
                else:
                    self.assertEqual(count, 1, source)


if __name__ == "__main__":
    unittest.main()
