"""Nhập bảng vật phẩm của máy chủ 14 môn phái (XJL7457) mà dev/server/tables chưa có hoặc đang cũ.

  python TOOLS/server/import_item.py <gốc dev/server> <gốc tlbb của XJL7457>
  python TOOLS/server/import_item.py <gốc dev/server> <gốc tlbb của XJL7457> --check

Chỉ nhập dòng mà client 2026 xác nhận: id vật phẩm có trong items_common, equipment, gems hoặc
pet_equipment_base (bảng client đã xuất ở tables/shared), hay id đoạn/luật được một trang bị của client
trỏ tới. Dòng chỉ có ở bản private của nhà phát hành bị bỏ và được đếm. Thứ bậc nguồn của dự án:
client 2026 > XJL7457 > 0859602, nên bảng ghi ra có hậu tố _xjl khi đã có bảng cùng tên từ 0859602
(import_legacy.py sở hữu bảng đó, công cụ này không ghi đè), và module item đọc bản _xjl trước.

Bảng ghi vào <gốc>/tables/server:
  item_segment_values_xjl.tsv         ItemSegValue: đoạn mà trang bị client dùng nhưng bảng client thiếu
  item_segment_quality_rules_xjl.tsv  ItemSegQuality: dòng luật mà trang bị client trỏ tới (190 cột nguồn)
  item_segment_distributions_xjl.tsv  ItemSegAffect: phân bố phẩm chất mà các dòng luật trên trỏ tới
  item_sale_limits_xjl.tsv            OnSaleLimit: vật phẩm cấm bày bán / cấm vào cửa hàng người chơi
  super_weapon_advances.tsv           SuperWeaponUpgrade: thần khí lên bậc, vật liệu và vàng

Không nhập (lý do in ra khi chạy): EquipEnance (không có id vật phẩm để client xác nhận), PetEquipUpProductInfo
(không id nào có trong client), XYJ_* (hệ thống riêng của nhà phát hành, client 2026 không biết),
mystery_shop.ini (trùng nguyên văn randgemshop.ini).
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

import scene_xref
import tsv_file

TOOL = "import_item.py"
CONFIG = "Public/Config"
SERVER_CONFIG = "Server/Config"
INTEGER = re.compile(r"^-?[0-9]+$")
TIERS = 9
RULE_COLUMNS = 190
SEGMENT_BAND = 9
CLIENT_ITEM_TABLES = ("items_common", "equipment", "gems", "pet_equipment_base")


class ItemImportError(ValueError):
    """Đầu vào hỏng; thông báo đã có tệp:dòng."""


@dataclass(frozen=True)
class Raw:
    """Một bảng chữ của máy chủ gốc: dòng kiểu và dòng tên bị bỏ, ô đã kiểm là số nguyên khi cột khai INT."""

    width: int
    rows: tuple[tuple[str, ...], ...]


@dataclass(frozen=True)
class Output:
    name: str
    source: str
    types: tuple[str, ...]
    columns: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    note: str


def read_raw(path: Path) -> Raw:
    """Bảng chữ OpenFromMemoryImpl_Text: dòng kiểu, dòng tên, rồi bản ghi. Ô INT phải là số nguyên."""
    lines = scene_xref.decode_text(path.read_bytes()).replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if len(lines) < 3:
        raise ItemImportError(f"{path.name}:1: thiếu dòng kiểu hoặc dòng tên")
    kinds = lines[0].split("\t")
    while kinds and kinds[-1] == "":
        kinds.pop()
    rows = []
    for number, line in enumerate(lines[2:], start=3):
        cells = line.split("\t")
        if cells[0].startswith("#") or cells[0].strip() == "":
            continue
        if len(cells) < len(kinds):
            raise ItemImportError(f"{path.name}:{number}: {len(cells)} ô, bảng khai {len(kinds)} cột")
        row = tuple(cells[: len(kinds)])
        for index, kind in enumerate(kinds):
            if kind == "INT" and not INTEGER.fullmatch(row[index].strip()):
                raise ItemImportError(f"{path.name}:{number}: cột {index + 1} không phải số nguyên: {row[index]!r}")
        rows.append(tuple(cell.strip() for cell in row))
    return Raw(len(kinds), tuple(rows))


def tsv_ints(tables: Path, name: str, column: int = 0) -> set[int]:
    table = tsv_file.read_table(tables / "shared" / f"{name}.tsv")
    return {int(row[column]) for row in table.rows}


def client_item_ids(tables: Path) -> set[int]:
    found: set[int] = set()
    for name in CLIENT_ITEM_TABLES:
        found |= tsv_ints(tables, name)
    return found


def equipment_rows(tables: Path) -> tuple[dict[str, int], tuple[tuple[str, ...], ...]]:
    table = tsv_file.read_table(tables / "shared" / "equipment.tsv")
    return {name: index for index, name in enumerate(table.columns)}, table.rows


def referenced_rules(tables: Path) -> set[int]:
    column, rows = equipment_rows(tables)
    return {int(row[column["quality_rules"]]) for row in rows if int(row[column["quality_rules"]]) > 0}


def referenced_segments(tables: Path) -> set[int]:
    """Đoạn ItemSegValue mà trang bị có sinh thuộc tính ngẫu nhiên của client dùng: gốc đoạn cộng 0..8."""
    column, rows = equipment_rows(tables)
    found: set[int] = set()
    for row in rows:
        start = int(row[column["value_band_start"]])
        if int(row[column["attribute_count_max"]]) > 0 and start >= 0:
            found.update(range(start, start + SEGMENT_BAND))
    return found


def segment_values(raw: Raw, tables: Path) -> Output:
    """ItemSegValue: đoạn client dùng mà bảng client thiếu. Tên cột lấy từ bảng client (cùng 65 cột)."""
    client = tsv_file.read_table(tables / "shared" / "item_segment_values.tsv")
    if raw.width != len(client.columns):
        raise ItemImportError(f"ItemSegValue.txt: {raw.width} cột, bảng client có {len(client.columns)}")
    have = {int(row[0]) for row in client.rows}
    wanted = referenced_segments(tables) - have
    rows = tuple(tuple(str(int(cell)) for cell in row) for row in raw.rows if int(row[0]) in wanted)
    note = f"{len(raw.rows)} dòng gốc, {len(have)} đoạn đã có ở client, {len(wanted)} đoạn client cần mà thiếu"
    return Output("item_segment_values_xjl.tsv", f"XJL7457/{SERVER_CONFIG}/ItemSegValue.txt",
                  ("int",) * len(client.columns), client.columns, rows, note)


def quality_rules(raw: Raw, tables: Path) -> Output:
    if raw.width != RULE_COLUMNS + 1:
        raise ItemImportError(f"ItemSegQuality.txt: {raw.width} cột, cần {RULE_COLUMNS + 1}")
    wanted = referenced_rules(tables)
    rows = tuple(tuple(str(int(cell)) for cell in row) for row in raw.rows if int(row[0]) in wanted)
    missing = wanted - {int(row[0]) for row in rows}
    if missing:
        raise ItemImportError(f"ItemSegQuality.txt: client trỏ tới dòng luật không có: {sorted(missing)}")
    columns = ("rule_id", *(f"origin_{index}" for index in range(RULE_COLUMNS)))
    return Output("item_segment_quality_rules_xjl.tsv", f"XJL7457/{SERVER_CONFIG}/ItemSegQuality.txt",
                  ("int",) * len(columns), columns, rows, f"{len(raw.rows)} dòng gốc, client dùng {len(wanted)}")


def distributions(raw: Raw, rules: Output) -> Output:
    if raw.width != TIERS + 2:
        raise ItemImportError(f"ItemSegAffect.txt: {raw.width} cột, cần {TIERS + 2}")
    wanted = {int(cell) for row in rules.rows for cell in row[1:] if int(cell) >= 0}
    by_id = {int(row[0]): row for row in raw.rows}
    missing = wanted - set(by_id)
    if missing:
        raise ItemImportError(f"ItemSegAffect.txt: dòng luật trỏ tới phân bố không có: {sorted(missing)[:10]}")
    rows = tuple(tuple(str(int(cell)) for cell in by_id[key]) for key in sorted(wanted))
    columns = ("affect_id", "total", *(f"tier_{index}_weight" for index in range(1, TIERS + 1)))
    return Output("item_segment_distributions_xjl.tsv", f"XJL7457/{SERVER_CONFIG}/ItemSegAffect.txt",
                  ("int",) * len(columns), columns, rows, f"{len(raw.rows)} dòng gốc, luật trỏ tới {len(wanted)}")


def sale_limits(raw: Raw, ids: set[int]) -> Output:
    if raw.width != 3:
        raise ItemImportError(f"OnSaleLimit.txt: {raw.width} cột, cần 3")
    rows = tuple(tuple(str(int(cell)) for cell in row) for row in raw.rows if int(row[0]) in ids)
    columns = ("item_id", "stall_list_limited", "player_shop_list_limited")
    return Output("item_sale_limits_xjl.tsv", f"XJL7457/{SERVER_CONFIG}/OnSaleLimit.txt", ("int",) * 3, columns, rows,
                  f"{len(raw.rows)} dòng gốc, {len(rows)} có id trong client")


def super_weapon_advances(raw: Raw, ids: set[int]) -> Output:
    if raw.width != 6:
        raise ItemImportError(f"SuperWeaponUpgrade.txt: {raw.width} cột, cần 6")

    def confirmed(row: tuple[str, ...]) -> bool:
        mats = [int(cell) for cell in row[4:6] if int(cell) > 0]
        return int(row[0]) in ids and int(row[1]) in ids and all(mat in ids for mat in mats)

    rows = tuple(tuple(str(int(cell)) for cell in row) for row in raw.rows if confirmed(row))
    columns = ("item_id", "advanced_item_id", "gold_cost", "material_count", "material_1_id", "material_2_id")
    return Output("super_weapon_advances.tsv", f"XJL7457/{CONFIG}/SuperWeaponUpgrade.txt", ("int",) * 6, columns, rows,
                  f"{len(raw.rows)} dòng gốc, {len(rows)} có đủ id trong client")


def skipped(xjl: Path, ids: set[int]) -> list[str]:
    """Các tệp không nhập kèm lý do đo được lúc chạy."""
    notes = ["EquipEnance.txt: không nhập, bảng theo cấp cường hoá, không có id vật phẩm để client xác nhận"]
    upgrade = read_raw(xjl / CONFIG / "PetEquipUpProductInfo.txt")
    hits = sum(1 for row in upgrade.rows if int(row[0]) in ids or int(row[6]) in ids)
    notes.append(f"PetEquipUpProductInfo.txt: không nhập, {hits}/{len(upgrade.rows)} dòng có id trong client")
    for name in ("XYJ_ShopTable.txt", "XYJ_ShopTableBak.txt", "XYJ_GemGrade.txt"):
        notes.append(f"{name}: không nhập, hệ thống riêng của nhà phát hành, client 2026 không có")
    mystery = (xjl / CONFIG / "RandShop" / "mystery_shop.ini").read_bytes()
    gem_shop = (xjl / CONFIG / "RandShop" / "randgemshop.ini").read_bytes()
    same = "trùng nguyên văn randgemshop.ini" if mystery == gem_shop else "KHÁC randgemshop.ini"
    notes.append(f"mystery_shop.ini: {same}")
    return notes


def build(server_root: Path, xjl: Path) -> tuple[list[Output], list[str]]:
    tables = server_root / "tables"
    ids = client_item_ids(tables)
    config = xjl / CONFIG
    server = xjl / SERVER_CONFIG
    values = segment_values(read_raw(server / "ItemSegValue.txt"), tables)
    rules = quality_rules(read_raw(server / "ItemSegQuality.txt"), tables)
    outputs = [
        values,
        rules,
        distributions(read_raw(server / "ItemSegAffect.txt"), rules),
        sale_limits(read_raw(server / "OnSaleLimit.txt"), ids),
        super_weapon_advances(read_raw(config / "SuperWeaponUpgrade.txt"), ids),
    ]
    return outputs, skipped(xjl, ids)


def run(server_root: Path, xjl: Path, check: bool) -> int:
    outputs, notes = build(server_root, xjl)
    status = 0
    for out in outputs:
        path = server_root / "tables" / "server" / out.name
        text = tsv_file.render_table(out.source, TOOL, out.types, out.columns, out.rows)
        if check:
            same = path.is_file() and path.read_bytes().decode("utf-8") == text
            if not same:
                print(f"{path}:1: bảng lệch hoặc thiếu so với {TOOL}", file=sys.stderr)
                status = 1
            continue
        tsv_file.write_table(path, out.source, TOOL, out.types, out.columns, out.rows)
        print(f"đã ghi {out.name} ({len(out.rows)} dòng): {out.note}")
    for note in notes:
        print(note)
    return status


def main(argv: list[str]) -> int:
    args = [item for item in argv if not item.startswith("--")]
    if len(args) != 2 or "--help" in argv:
        print(__doc__)
        return 0 if "--help" in argv else 1
    try:
        return run(Path(args[0]), Path(args[1]), "--check" in argv)
    except (ItemImportError, tsv_file.TsvError) as error:
        print(f"{TOOL}:1: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
