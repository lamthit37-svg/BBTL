# Kiểm import_item: chỉ nhập dòng mà client xác nhận, đầu vào hỏng bị từ chối, --check bắt bảng lệch.
from __future__ import annotations

import io
import shutil
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import import_item
import tsv_file


def _scratch(name: str) -> Path:
    path = Path("build") / "p1-b" / "unit" / name
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)
    return path


def _shared(root: Path, name: str, columns: list[str], rows: list[list[str]]) -> None:
    types = ["int"] * len(columns)
    tsv_file.write_table(root / "tables" / "shared" / f"{name}.tsv", "client_2026/x.txt", "import_item.py", types,
                         columns, rows)


def _raw(path: Path, header: list[str], rows: list[list[str]], kinds: list[str] | None = None) -> None:
    """Bảng chữ gốc: dòng kiểu, dòng tên, bản ghi; mỗi dòng kết thúc bằng tab như tệp thật."""
    path.parent.mkdir(parents=True, exist_ok=True)
    kinds = kinds or ["INT"] * len(header)
    lines = ["\t".join(kinds) + "\t", "\t".join(header) + "\t", *("\t".join(row) + "\t" for row in rows)]
    path.write_bytes("\r\n".join(lines).encode("gbk") + b"\r\n")


class ImportItemTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _scratch(self.id().split(".")[-1])
        self.server = self.root / "server"
        self.xjl = self.root / "xjl"
        self._build_client()
        self._build_xjl()

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _build_client(self) -> None:
        _shared(self.server, "items_common", ["index"], [["30000001"], ["30000002"]])
        _shared(self.server, "gems", ["index"], [["50101001"]])
        _shared(self.server, "pet_equipment_base", ["index"], [["70100000"]])
        _shared(self.server, "equipment", ["index", "quality_rules", "value_band_start", "attribute_count_max"],
                [["10100000", "0", "-1", "0"], ["10200008", "10", "80", "3"], ["10200009", "11", "100", "0"]])
        _shared(self.server, "item_segment_values", ["index", "a", "b"], [["80", "1", "1"], ["81", "2", "2"]])

    def _build_xjl(self) -> None:
        config = self.xjl / "Server" / "Config"
        public = self.xjl / "Public" / "Config"
        # Đoạn 82 và 88 nằm trong gốc 80..88, 89 ngoài khoảng, 500 không trang bị nào trỏ tới.
        _raw(config / "ItemSegValue.txt", ["i", "a", "b"], [["80", "9", "9"], ["82", "3", "3"], ["88", "4", "4"],
                                                              ["89", "5", "5"], ["500", "6", "6"]])
        rule_header = ["rule"] + [str(i) for i in range(190)]
        cells = [str(20 if column < 100 else -1) for column in range(190)]
        _raw(config / "ItemSegQuality.txt", rule_header, [["10", *cells], ["11", *cells], ["12", *cells]])
        _raw(config / "ItemSegAffect.txt", ["id", "total", *[f"w{i}" for i in range(1, 10)]],
             [["20", "1000", "1000", *["0"] * 8], ["21", "1000", "1000", *["0"] * 8]])
        _raw(config / "OnSaleLimit.txt", ["id", "a", "b"], [["30000001", "1", "1"], ["99999999", "1", "0"]])
        _raw(public / "SuperWeaponUpgrade.txt", ["a", "b", "c", "d", "e", "f"],
             [["10100000", "10200008", "9000", "1", "30000001", "30000002"],
              ["10100000", "88888888", "9000", "1", "30000001", "30000002"],
              ["10100000", "10200008", "9000", "1", "30000001", "77777777"]])
        _raw(public / "PetEquipUpProductInfo.txt", ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
             [["39990000", "20301009", "3", "-1", "-1", "10000", "39990001", "0", "_001", "2"]],
             ["INT"] * 8 + ["STRING", "INT"])
        shop = self.xjl / "Public" / "Config" / "RandShop"
        shop.mkdir(parents=True, exist_ok=True)
        (shop / "mystery_shop.ini").write_bytes(b"[General]\r\nTotal=1\r\n")
        (shop / "randgemshop.ini").write_bytes(b"[General]\r\nTotal=1\r\n")

    def _run(self, *extra: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = import_item.main([str(self.server), str(self.xjl), *extra])
        return code, out.getvalue(), err.getvalue()

    def _table(self, name: str) -> tsv_file.Table:
        return tsv_file.read_table(self.server / "tables" / "server" / name)

    def test_keeps_only_client_confirmed_rows(self) -> None:
        code, _out, err = self._run()
        self.assertEqual(code, 0, err)
        # Gốc 80..88 của 10200008; 80 đã có ở client nên không nhập lại; 89 ngoài khoảng, 500 không ai trỏ tới.
        self.assertEqual([row[0] for row in self._table("item_segment_values_xjl.tsv").rows], ["82", "88"])
        self.assertEqual([row[0] for row in self._table("item_segment_quality_rules_xjl.tsv").rows], ["10", "11"])
        self.assertEqual([row[0] for row in self._table("item_segment_distributions_xjl.tsv").rows], ["20"])
        self.assertEqual([row[0] for row in self._table("item_sale_limits_xjl.tsv").rows], ["30000001"])
        self.assertEqual(len(self._table("super_weapon_advances.tsv").rows), 1)

    def test_reports_skipped_tables(self) -> None:
        _code, out, _err = self._run()
        self.assertIn("PetEquipUpProductInfo.txt: không nhập, 0/1 dòng", out)
        self.assertIn("mystery_shop.ini: trùng nguyên văn randgemshop.ini", out)
        (self.xjl / "Public" / "Config" / "RandShop" / "mystery_shop.ini").write_bytes(b"[General]\r\nTotal=2\r\n")
        _code, out, _err = self._run()
        self.assertIn("KHÁC randgemshop.ini", out)

    def test_check_detects_missing_and_stale_tables(self) -> None:
        self.assertEqual(self._run("--check")[0], 1)
        self.assertEqual(self._run()[0], 0)
        self.assertEqual(self._run("--check")[0], 0)
        _raw(self.xjl / "Server" / "Config" / "OnSaleLimit.txt", ["id", "a", "b"], [["30000002", "0", "1"]])
        code, _out, err = self._run("--check")
        self.assertEqual(code, 1)
        self.assertIn("item_sale_limits_xjl.tsv", err)

    def test_rejects_hostile_raw_tables(self) -> None:
        config = self.xjl / "Server" / "Config"
        _raw(config / "OnSaleLimit.txt", ["id", "a", "b"], [["30000001", "x", "1"]])
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("OnSaleLimit.txt:3: cột 2 không phải số nguyên", err)
        (config / "OnSaleLimit.txt").write_bytes(b"INT\tINT\tINT\r\na\tb\tc\r\n30000001\t1\r\n")
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("OnSaleLimit.txt:3: 2 ô, bảng khai 3 cột", err)
        (config / "OnSaleLimit.txt").write_bytes(b"INT\tINT\tINT\r\n")
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("thiếu dòng kiểu hoặc dòng tên", err)

    def test_rejects_width_and_dangling_references(self) -> None:
        config = self.xjl / "Server" / "Config"
        _raw(config / "ItemSegValue.txt", ["i", "a"], [["80", "9"]])
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("ItemSegValue.txt: 2 cột, bảng client có 3", err)
        self._build_xjl()
        _raw(config / "ItemSegAffect.txt", ["id", "total", *[f"w{i}" for i in range(1, 10)]],
             [["21", "1000", "1000", *["0"] * 8]])
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("phân bố không có", err)
        self._build_xjl()
        _raw(config / "ItemSegQuality.txt", ["rule"] + [str(i) for i in range(190)], [["10", *["20"] * 190]])
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("dòng luật không có: [11]", err)

    def test_refuses_to_overwrite_foreign_table(self) -> None:
        target = self.server / "tables" / "server" / "super_weapon_advances.tsv"
        target.parent.mkdir(parents=True, exist_ok=True)
        tsv_file.write_table(target, "tự soạn", "import_combat.py", ["int"], ["a"], [["1"]])
        code, _out, err = self._run()
        self.assertEqual(code, 1)
        self.assertIn("không phải của TOOLS/server/import_item.py", err)


if __name__ == "__main__":
    unittest.main()
