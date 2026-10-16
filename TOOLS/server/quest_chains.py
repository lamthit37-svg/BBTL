"""Gộp chuỗi tân thủ client 2026 vào bảng mission và xuất một sổ Excel.

Cách dùng:
    py -B TOOLS/server/quest_chains.py
    py -B TOOLS/server/quest_chains.py --check
    py -B TOOLS/server/quest_chains.py --excel-only

Số tiền, kinh nghiệm và vật phẩm lấy từ MisDesc. Trang hướng dẫn và bài 2006–2008 chỉ vào
sheet lệch nguồn. Bước không có bộ chạy giữ unsupported. Vòng cày sẵn có không bị đổi số.
"""
from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

import lua_build as BU
import lua_emit as E
import lua_out as O
import lua_world as W
import newquest
import tsv_file

PROJECT = Path(__file__).resolve().parents[2]
TABLES = PROJECT / "dev" / "server" / "tables"
SCENES = PROJECT / "dev" / "server" / "scenes"
SERVER = TABLES / "server"
EXCEL = PROJECT / "docs" / "NHIEM-VU-CHUOI.xlsx"
OWNED = (
    "mission_quests",
    "mission_objectives",
    "mission_rewards",
    "mission_prereqs",
    "mission_npcs",
    "mission_name_groups",
)

# Toạ độ đã đọc trên trang Changyou (không có id). Không ghi vào TSV.
PAGE_NOTE = {
    1400: "trang Changyou [160,156]; script Position 160,158. Trang không có id.",
    1401: "trang Changyou 蒲良 [216,135]; script Position 219,123.",
    1422: "trang Changyou 崔逢九 [241,137]; script Position 253,121.",
}


def emit(text: str) -> None:
    sys.stdout.buffer.write((text + "\n").encode("utf-8"))


def spec_pairs(name: str) -> list:
    return [item.split(":") for item in O.SPECS[name].split()]


def as_cells(rows: list) -> list:
    return [tuple(O.clean(cell) for cell in row) for row in rows]


def column_widths(header: tuple | list, rows: list) -> list:
    widths = [tsv_file.display_width(cell) for cell in header]
    for row in rows:
        for index, cell in enumerate(row):
            widths[index] = max(widths[index], tsv_file.display_width(cell))
    return widths


def ensure_fit(header: tuple | list, keep: list, fresh: list, label: str) -> None:
    """Ô mới không được rộng hơn cột đang có, kẻo cả tệp căn lại."""
    widths = column_widths(header, keep)
    for row in fresh:
        if len(row) != len(header):
            raise newquest.NewquestError(f"{label}: lệch số cột")
        for index, cell in enumerate(row):
            width = tsv_file.display_width(cell)
            if width > widths[index]:
                shown = cell if len(cell) <= 40 else cell[:40]
                raise newquest.NewquestError(
                    f"{label} cột {header[index]} rộng {width} vượt {widths[index]}: {shown}"
                )


def data_lines(table: tsv_file.Table, rows: list) -> list:
    text = tsv_file.render_table(
        table.source, table.tool, table.types, table.columns, rows, layout=table.layout
    )
    lines = []
    seen_header = False
    for line in text.splitlines():
        if line.startswith("#"):
            continue
        if not seen_header:
            seen_header = True
            continue
        lines.append(line)
    return lines


def file_data_lines(path: Path) -> list:
    lines = []
    seen_header = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or line == "":
            continue
        if not seen_header:
            seen_header = True
            continue
        lines.append(line)
    return lines


def require_layout(table: tsv_file.Table, name: str) -> None:
    pairs = spec_pairs(name)
    columns = tuple(column for column, _kind in pairs)
    types = tuple(kind for _column, kind in pairs)
    if tuple(table.columns) != columns or tuple(table.types) != types:
        raise newquest.NewquestError(f"{name}: cột hoặc kiểu khác bộ xuất lua_extract")
    if table.tool != O.TOOL:
        raise newquest.NewquestError(f"{name}: tool {table.tool}")


def load_world() -> W.World:
    return W.World(TABLES, SCENES).load()


def item_index() -> dict:
    """id vật phẩm -> tên đọc từ bảng đã mở. Không thấy thì không đoán."""
    found: dict[str, list] = {}
    order = ("equipment", "items_common", "gems")
    for label in order:
        header, rows = W.rows_of(TABLES / "shared" / f"{label}.tsv")
        if not header or "name" not in header:
            continue
        name_at = header.index("name")
        for row in rows:
            if not row or name_at >= len(row):
                continue
            item_id = row[0]
            if not item_id:
                continue
            found.setdefault(item_id, []).append(f"{row[name_at]} ({label})")
    return found


def dictionary_index() -> dict:
    _header, rows = W.rows_of(TABLES / "shared" / "mission_dictionary.tsv")
    found = {}
    for row in rows:
        if len(row) >= 18:
            found[W.to_int(row[1])] = row
    return found


def track_index() -> dict:
    _header, rows = W.rows_of(TABLES / "client" / "MissionTrack.tsv")
    found = {}
    for row in rows:
        if not row:
            continue
        script = W.to_int(row[0])
        text = " ".join(cell.strip() for cell in row[1:] if cell.strip())
        if script >= 0 and text and script not in found:
            found[script] = text
    return found


def empty_spawn_notes(templates: set) -> dict:
    """Đếm spawn có cột name trống. World tự điền tên quái nên không dùng world cho việc này."""
    tally = {template: [0, 0] for template in templates}
    if not SCENES.is_dir():
        return {}
    for folder in sorted(SCENES.iterdir()):
        header, rows = W.rows_of(folder / "spawns.tsv")
        if "type" not in header or "name" not in header:
            continue
        type_at = header.index("type")
        name_at = header.index("name")
        for row in rows:
            if type_at >= len(row):
                continue
            template = W.to_int(row[type_at], 0)
            if template not in tally:
                continue
            tally[template][0] += 1
            name = row[name_at] if name_at < len(row) else ""
            if name == "":
                tally[template][1] += 1
    notes = {}
    for template, (total, empty) in tally.items():
        if total == 0:
            notes[template] = f"mẫu {template} không có trong spawn đã mở"
            continue
        notes[template] = (
            f"mẫu {template}: {total} spawn, {empty} spawn để trống cột name. "
            "Zone lấy tên từ cột đó. Tên trống thì băm tên không khớp tên quái. "
            "Dòng mission_name_groups khiến giết đúng mẫu vẫn tính."
        )
    return notes


def item_text(entries: list, items: dict) -> str:
    parts = []
    for entry in entries:
        names = items.get(str(entry.item))
        label = "; ".join(names) if names else "không thấy trong bảng vật phẩm đã mở"
        parts.append(f"{entry.item} × {entry.num} — {label}")
    return "; ".join(parts)


def gate_reason(desc: newquest.Desc, by_quest: dict) -> str:
    seen: set[int] = set()

    def walk(item: newquest.Desc) -> str:
        if item.quest in seen:
            return "vòng tiền đề"
        seen.add(item.quest)
        if item.status != "ok":
            return item.reason or "không chạy"
        for pre in newquest.positive_pre(item):
            earlier = by_quest.get(pre)
            if earlier is None:
                return f"tiền đề {pre} không có trong 22 script"
            why = walk(earlier)
            if why:
                return f"chờ {pre}"
        return ""

    return walk(desc)


def exp_text(desc: newquest.Desc) -> str:
    if desc.exp is None:
        return "script không có trường kinh nghiệm"
    source = "g_exp" if any("g_exp" in note for note in desc.notes) else "g_ExpBonus"
    if desc.exp == 0:
        return f"0 ({source}; TSV không thêm dòng vì số 0; không quy đổi)"
    return f"{desc.exp} ({source}; không quy đổi)"


def objective_text(desc: newquest.Desc) -> str:
    if desc.status == "ok" and desc.skill_steps:
        parts = [f"học {step.skill} với {step.teacher}" for step in desc.skill_steps]
        return "; ".join(parts)
    if desc.status == "ok" and desc.level_need > 0:
        return f"đạt cấp {desc.level_need}"
    if desc.status == "ok" and desc.talk_npc:
        return f"nói chuyện với {desc.talk_npc}"
    kill = newquest.chosen_kill(desc)
    if kill is None:
        return ""
    demand = ""
    if len(desc.kill_ids) == 1 and desc.kill_ids[0].item:
        demand = f"; DemandKill id {desc.kill_ids[0].item} chỉ là ghi chú, không phải mục tiêu"
    return f"giết {kill.ident} × {kill.num}{demand}"


def dict_cell(row: list | None, index: int) -> str:
    if row is None:
        return "không có dòng danh bạ"
    if index >= len(row):
        return ""
    return row[index]


def newbie_rows(descs: list, items: dict, dictionary: dict, tracks: dict, spawn_notes: dict) -> list:
    header = [
        "Vai trò chuỗi",
        "Bước",
        "Tệp script",
        "Mã script",
        "Mã nhiệm vụ",
        "Tên trong script",
        "Tên ô danh bạ (ô 2, chưa chứng minh schema)",
        "Loại script g_MissionKind",
        "Loại ô danh bạ (ô 3, chưa chứng minh schema)",
        "Cấp script",
        "Cấp tối thiểu ô danh bạ (ô 6)",
        "Cấp tối đa ô danh bạ (ô 7)",
        "Tiền đề g_MissionIdPre (0 hoặc trống là không có)",
        "Ô tiền đề danh bạ 8-12 (chưa chứng minh schema)",
        "g_MissionIdPer (không đưa vào tiền đề)",
        "Script kế",
        "Nhiệm vụ kế",
        "NPC giao trong script",
        "NPC trả trong script",
        "Ô danh bạ 13 tên giao",
        "Ô danh bạ 14 guid giao",
        "Ô danh bạ 15 tên trả",
        "Ô danh bạ 16 guid trả",
        "Cảnh script",
        "Toạ độ Position",
        "Toạ độ SignPost",
        "Chữ MissionTrack (không phải mục tiêu)",
        "Toạ độ trang Changyou (không ghi vào TSV)",
        "Trạng thái máy chủ",
        "Lý do không chạy",
        "Mục tiêu máy chủ sẽ chạy",
        "Vào được lúc chưa xong tiền đề unsupported",
        "Tiền g_MoneyBonus (không quy đổi)",
        "Tiền khoá g_MoneyJZBonus (không quy đổi)",
        "Kinh nghiệm",
        "Vật phẩm cố định",
        "Vật phẩm chọn một",
        "Việc custom trong script",
        "Mô tả g_MissionInfo",
        "Mô tả thêm MissionInfo1 trở đi",
        "Chữ mục tiêu",
        "Lời chưa xong",
        "Lời xong",
        "Ghi chú",
    ]
    by_quest = {item.quest: item for item in descs}
    ordered = sorted(descs, key=lambda item: (item.chain_role != "chính", item.chain_step, item.quest))
    rows = [header]
    for desc in ordered:
        row = dictionary.get(desc.quest)
        notes = list(desc.notes)
        dict_name = dict_cell(row, 2) if row is not None else ""
        if row is not None and dict_name != desc.name:
            notes.append(f"ô danh bạ ghi {dict_name}; TSV giữ tên script")
        track = tracks.get(desc.script, "")
        if "38000173" in track:
            notes.append("38000173 chỉ có trong MissionTrack, không có trong g_ItemBonus, không ghi thành thưởng")
        if desc.quest == 1423:
            for script in (210271, 210272):
                extra = tracks.get(script)
                if extra:
                    notes.append(f"MissionTrack {script} không có file lua: {extra}")
            notes.append("210271 và 210272 không được thêm vào chuỗi. 210280 là nhiệm vụ này.")
        kill = newquest.chosen_kill(desc)
        if kill is not None:
            for demand in desc.kill_ids:
                note = spawn_notes.get(demand.item)
                if note:
                    notes.append(note)
        quest_of = newquest.quest_of_scripts(descs)
        pre = "" if desc.pre is None else desc.pre
        per = "" if desc.per is None else desc.per
        next_quest = quest_of[desc.next_script] if desc.next_script in quest_of else -1
        prereq_cells = ""
        if row is not None:
            prereq_cells = ", ".join(dict_cell(row, index) for index in range(8, 13))
        position = ""
        if desc.pos_x is not None and desc.pos_z is not None:
            position = f"{desc.pos_x}, {desc.pos_z}"
        sign = ""
        if desc.sign_x is not None and desc.sign_z is not None:
            sign = f"{desc.sign_x}, {desc.sign_z} {desc.sign_tip}".strip()
        money = "" if desc.money is None else desc.money
        bound = "" if desc.bound is None else desc.bound
        ready = "có" if gate_reason(desc, by_quest) == "" else "không"
        rows.append(
            [
                desc.chain_role,
                desc.chain_step,
                desc.path,
                desc.script,
                desc.quest,
                desc.name,
                dict_name or "không có dòng danh bạ",
                desc.kind,
                dict_cell(row, 3),
                desc.level,
                dict_cell(row, 6),
                dict_cell(row, 7),
                pre,
                prereq_cells or "không có dòng danh bạ",
                per,
                desc.next_script,
                next_quest,
                desc.giver,
                desc.turn,
                dict_cell(row, 13),
                dict_cell(row, 14),
                dict_cell(row, 15),
                dict_cell(row, 16),
                desc.scene,
                position,
                sign,
                track,
                PAGE_NOTE.get(desc.quest, ""),
                desc.status,
                desc.reason,
                objective_text(desc),
                ready,
                money,
                bound,
                exp_text(desc),
                item_text(desc.items, items),
                item_text(desc.choices, items),
                "; ".join(f"{item.ident} × {item.num}" for item in desc.customs if item.ident),
                desc.info,
                "\n".join(desc.extra_info),
                desc.target,
                desc.cont,
                desc.done,
                "; ".join(notes),
            ]
        )
    return rows


def reward_sheet(descs: list, items: dict) -> list:
    header = [
        "Mã script",
        "Mã nhiệm vụ",
        "Tên script",
        "Nhóm",
        "Loại",
        "Id hoặc 0",
        "Tên vật phẩm trong bảng đã mở",
        "Số lượng",
        "Điều kiện thưởng",
        "Trường script",
    ]
    rows = [header]
    ordered = sorted(descs, key=lambda item: (item.chain_role != "chính", item.chain_step))
    for desc in ordered:
        if desc.money is not None:
            rows.append([desc.script, desc.quest, desc.name, "fixed", "money", 0, "", desc.money, -1, "g_MoneyBonus"])
        if desc.bound is not None:
            rows.append(
                [desc.script, desc.quest, desc.name, "fixed", "bound_money", 0, "", desc.bound, -1, "g_MoneyJZBonus"]
            )
        if desc.exp is not None:
            field_name = "g_exp" if any("g_exp" in note for note in desc.notes) else "g_ExpBonus"
            if desc.exp == 0:
                field_name += "; số 0 không ghi vào TSV"
            rows.append([desc.script, desc.quest, desc.name, "fixed", "exp", 0, "", desc.exp, -1, field_name])
        for entry in desc.items:
            names = items.get(str(entry.item), ["không thấy trong bảng vật phẩm đã mở"])
            rows.append(
                [desc.script, desc.quest, desc.name, "fixed", "item", entry.item, "; ".join(names), entry.num, -1, "g_ItemBonus"]
            )
        for entry in desc.choices:
            names = items.get(str(entry.item), ["không thấy trong bảng vật phẩm đã mở"])
            rows.append(
                [
                    desc.script,
                    desc.quest,
                    desc.name,
                    "choice",
                    "item",
                    entry.item,
                    "; ".join(names),
                    entry.num,
                    -1,
                    "g_RadioItemBonus",
                ]
            )
    return rows


def objective_sheet(descs: list) -> list:
    header = ["Mã script", "Mã nhiệm vụ", "Tên script", "Loại", "Tên", "Số lượng", "Trạng thái", "Ghi chú DemandKill"]
    rows = [header]
    for desc in sorted(descs, key=lambda item: item.quest):
        note = "; ".join(item for item in desc.notes if item.startswith("DemandKill"))
        if desc.status == "ok" and desc.skill_steps:
            for step in desc.skill_steps:
                rows.append([desc.script, desc.quest, desc.name, "skill", step.teacher, 1, desc.status, f"mã {step.skill}"])
            continue
        if desc.status == "ok" and desc.level_need > 0:
            rows.append([desc.script, desc.quest, desc.name, "level", "", desc.level_need, desc.status, ""])
            continue
        kill = newquest.chosen_kill(desc)
        if desc.status == "ok" and desc.talk_npc:
            rows.append([desc.script, desc.quest, desc.name, "talk", desc.talk_npc, 1, desc.status, ""])
        elif kill is not None:
            rows.append([desc.script, desc.quest, desc.name, "kill", kill.ident, kill.num, desc.status, note])
        else:
            custom = "; ".join(item.ident for item in desc.customs if item.ident)
            rows.append([desc.script, desc.quest, desc.name, "", custom, "", desc.status, desc.reason])
    return rows


def conflict_sheet() -> list:
    header = ["Việc", "Nguồn", "Điều nguồn nói", "Điều script client 2026", "Quyết định"]
    return [
        header,
        [
            "Thứ tự tên tân thủ",
            "https://tl.changyou.com/events/helper/index87.shtml đã mở 2026-10-16",
            "初涉江湖 tới 宏大的江湖, không có id và không có số kinh nghiệm",
            "g_NextScriptId của edali_newquest khớp thứ tự tên đó, trừ chỗ ghi bên dưới",
            "Giữ thứ tự và số của script. Trang chỉ để đối chiếu.",
        ],
        [
            "十四大门派",
            "cùng trang Changyou",
            "Nằm giữa 最后的试炼 và 宏大的江湖",
            "Script giữa hai tên đó là 1421, tên là khoá #{XMPHM_210604_22}, ô danh bạ là 十一大门派",
            "Không gộp ba chuỗi này thành một tên.",
        ],
        [
            "喜庆焰火 và 大理美景",
            "trang Changyou và ô danh bạ",
            "Trang ghi 喜庆焰火. Trang không có 大理美景 và không có 十年",
            "1417 tên script là 大理美景. 1424 tên script và danh bạ là 十年",
            "TSV giữ tên script.",
        ],
        [
            "剑阁猴患 có vũ khí",
            "trang Changyou",
            "Lời trang nói được chọn vũ khí",
            "edali_newquest_008.lua để trống ItemBonus và RadioItemBonus. ExpBonus 1008, giết 蜀道白猿 × 5",
            "Không chép 5 id vũ khí của 1401 sang 1407.",
        ],
        [
            "第一次杀怪 8 con",
            "https://tl.52pk.com/data/20070427/133516.html năm 2007",
            "Cấp 4, giết 8 蜀道白猿. Nhiệm vụ trước đó là 第一把武器 tiền 240 kinh nghiệm 10",
            "1403 cấp 2, giết 5 高山白猿, tiền 30, kinh nghiệm 258. Script cũ trong bảng là 210213 nhiệm vụ 453",
            "Không gộp bài 2007 với chuỗi 2026, cũng không gộp với 210213.",
        ],
        [
            "Nhiệm vụ đầu là 第一把武器",
            "http://tl.17173.com/content/2006-07-27/20060727141041637.shtml năm 2006",
            "第一把武器 tại 赵天师 (161,140)",
            "Script 2026 bắt đầu bằng 1400 初涉江湖. 1401 mới là 第一把武器",
            "Không lấy bài 2006 làm chuỗi của client này.",
        ],
        [
            "第一次送货 thưởng馒头",
            "https://forum.gamer.com.tw/G2.php?bsn=12413&sn=128 năm 2008",
            "Bắt đầu 第一把武器 rồi 第一次送货",
            "22 file edali_newquest không có bước 第一次送货",
            "Không thêm bước này.",
        ],
        [
            "天龙八部·归来",
            "https://tlbbgl.changyou.com/data/new/xsrwx_6.shtml",
            "Mục lục một sản phẩm khác: vào môn rồi mới tới các nhiệm vụ cấp 8",
            "Chuỗi MisDesc này là client 2026, có 1400 trước khi vào môn",
            "Chỉ thấy mục lục, không mở hết trang, không gộp.",
        ],
        [
            "Kinh nghiệm 258 và 1008",
            "tìm công khai cùng ngày",
            "Không thấy trang nào ghi hai số này",
            "edali_newquest_004.lua g_ExpBonus=258; edali_newquest_008.lua g_ExpBonus=1008",
            "Số trong TSV là số script.",
        ],
        [
            "第一把武器 cũ",
            "edali_zhidao_0200.lua",
            "Script 210200, nhiệm vụ 440, cùng tên 第一把武器",
            "1401 là script 210255",
            "Giữ hai nhiệm vụ riêng.",
        ],
        [
            "第一件防具 và 890252",
            "QuestLog.lua và emission_2.lua",
            "Chú thích gom 890252 với 第一件防具",
            "890252 là nhiệm vụ 1683. 1402 là script 210256",
            "Không gộp.",
        ],
        [
            "1424 là 初涉江湖",
            "MissionTrack.lua nhánh đã chú thích tắt",
            "Một nhánh -- ghi Mission 1424 là 初涉江湖. Nhánh đang dùng ghi 十年",
            "edali_newquest_000.lua g_MissionName là 十年",
            "Giữ 十年.",
        ],
        [
            "Quy đổi đồng và bạc",
            "trang Changyou ghi 1 đồng hoặc 1 bạc",
            "Lời văn, không có tỉ lệ đã đo",
            "g_MoneyBonus và g_MoneyJZBonus là số nguyên trong script",
            "Không quy đổi.",
        ],
    ]


def gap_sheet(dictionary: dict, quest_ids: set) -> list:
    header = [
        "Mã nhiệm vụ",
        "Tên ô danh bạ (ô 2, chưa chứng minh schema)",
        "Cấp tối thiểu ô 6",
        "Vì sao chưa dựng",
    ]
    rows = [header]
    for quest, row in sorted(dictionary.items()):
        if quest < 0 or quest in quest_ids:
            continue
        rows.append([quest, row[2], row[6], "có trong danh bạ, không có script đã hạ và không có bảng Mission_*"])
    for quest in (1409, 1410, 1411):
        if quest not in dictionary and quest not in quest_ids:
            rows.append([quest, "", "", "không có trong danh bạ và không có file edali_newquest"])
    return rows


def source_sheet(playable: list, single_count: int, merged: bool) -> list:
    header = ["Mục", "Nội dung"]
    names = ", ".join(f"{item.quest} {item.name}" for item in playable)
    state = "đã gộp vào mission_*.tsv" if merged else "chỉ xuất excel, chưa gộp bảng"
    return [
        header,
        ["Lần chạy", state],
        ["Lệnh sinh lại", "py -B TOOLS/server/quest_chains.py"],
        ["Nguồn số", "src/client/script/Config/event/dali/edali_newquest_*.lua, chỉ khối MisDesc"],
        ["Vì sao source=table", "Tệp không có OnAccept/OnSubmit. source=script với ready_cond -1 sẽ nộp được ngay."],
        ["Không gọi fill_from_client", "Ô NPC danh bạ là -1 và loại ô là 0. mission_kinds không có mã 0. Script ghi loại 13."],
        [
            "Bộ chạy bảng",
            "Nói chuyện, giết quái, học kỹ năng tân thủ khi mở hội thoại với thầy, đạt cấp. "
            "Thầy lấy từ edali_zhidao_0209. Mã kỹ năng là skill_id nhỏ nhất có icon FightSkillXinShou.",
        ],
        [
            "Vẫn unsupported",
            "1414 trân thú lên cấp, 1415 bắt trân thú, 1417 đốt pháo, 1419 năm câu hỏi, "
            "1421 vào môn phái, 1423 bốn món tặng không có mã vật phẩm. Không bịa bộ chạy.",
        ],
        ["Nhận được khi tiền đề chạy được", names or "không có"],
        ["Vòng cày", "Các dòng source=table repeat=loop giữ nguyên số. Cột cấp không quá 30 chỉ là cách xem."],
        ["Chuỗi một nhiệm vụ trong bảng hiện có", str(single_count)],
        ["826 id còn lại", "Sheet Chưa có dữ liệu. Không bịa mục tiêu."],
        ["Client HUD", "Chưa vẽ dấu nhận trên NPC và sổ nhiệm vụ còn lỗ. Bảng này là phía máy chủ."],
    ]


def index_rows(path: Path) -> tuple:
    if not path.is_file():
        return (), []
    table = tsv_file.read_table(path)
    return table.columns, list(table.rows)


def reward_brief(rows: list) -> str:
    parts = []
    for row in rows:
        kind, ref, count = row[3], row[4], row[5]
        if kind in ("money", "bound_money", "exp"):
            parts.append(f"{kind} {count}")
            continue
        if kind == "item":
            parts.append(f"item {ref} × {count} ({row[2]})")
    return "; ".join(parts)


def farm_sheet(quests: list, rewards: dict, items: dict) -> list:
    header = [
        "Mã script",
        "Mã nhiệm vụ",
        "Tên",
        "Cấp",
        "Lặp",
        "Cấp không quá 30",
        "Thưởng đúng các dòng đang có",
        "Trạng thái",
        "Đường",
    ]
    rows = [header]
    for quest in quests:
        if quest["source"] != "table" or quest["repeat"] != "loop":
            continue
        level = quest["level"]
        low = "có" if isinstance(level, int) and level <= 30 else "không"
        brief = reward_brief(rewards.get(quest["script_text"], []))
        rows.append(
            [
                quest["script"],
                quest["quest"],
                quest["name"],
                level,
                quest["repeat"],
                low,
                brief,
                quest["status"],
                quest["path"],
            ]
        )
    return rows


def follow_of(quests: list, by_script: dict, by_quest: dict):
    def follow(quest: dict) -> tuple:
        nxt = quest["next_script"]
        if nxt and nxt in by_script:
            return by_script[nxt], "next_script"
        if nxt:
            return None, "script kế không có trong bảng"
        later = quest["next_quest"]
        if later < 0:
            return None, ""
        owners = by_quest.get(later, [])
        if len(owners) == 1:
            return owners[0], "một biến thể"
        if len(owners) > 1:
            return None, "nhiều biến thể"
        return None, "nhiệm vụ kế không có trong bảng"

    return follow


def server_chains(quests: list) -> tuple:
    by_script = {item["script"]: item for item in quests}
    by_quest: dict[int, list] = {}
    for item in quests:
        by_quest.setdefault(item["quest"], []).append(item)
    follow = follow_of(quests, by_script, by_quest)
    pointed = set()
    for item in quests:
        nxt, how = follow(item)
        if nxt is not None and how in ("next_script", "một biến thể"):
            pointed.add(nxt["script"])
    heads = [item for item in quests if item["script"] not in pointed]
    heads.sort(key=lambda item: (item["level"] if isinstance(item["level"], int) else 9999, item["script"]))
    placed: set[int] = set()
    chains = []
    singles = 0
    for head in heads:
        if head["script"] in placed:
            continue
        chain = []
        seen: set[int] = set()
        stop = ""
        at = head
        while at is not None:
            if at["script"] in seen:
                stop = "vòng"
                break
            if at["script"] in placed:
                stop = f"nhập vào script {at['script']} đã kể"
                break
            seen.add(at["script"])
            placed.add(at["script"])
            chain.append(at)
            nxt, how = follow(at)
            if how not in ("", "next_script", "một biến thể"):
                stop = how
                break
            at = nxt
        if len(chain) >= 2 or stop:
            chains.append((chain, stop))
        else:
            singles += 1
    return chains, singles


def chain_sheet(quests: list) -> tuple:
    header = [
        "Chuỗi",
        "Bước",
        "Mã script",
        "Mã nhiệm vụ",
        "Tên",
        "Cấp",
        "Nguồn",
        "Trạng thái",
        "Lặp",
        "Script kế",
        "Nhiệm vụ kế",
        "Ghi chú dừng",
    ]
    chains, singles = server_chains(quests)
    rows = [header]
    for index, (chain, stop) in enumerate(chains, start=1):
        for step, quest in enumerate(chain, start=1):
            note = stop if step == len(chain) else ""
            rows.append(
                [
                    index,
                    step,
                    quest["script"],
                    quest["quest"],
                    quest["name"],
                    quest["level"],
                    quest["source"],
                    quest["status"],
                    quest["repeat"],
                    quest["next_script"],
                    quest["next_quest"],
                    note,
                ]
            )
    return rows, singles


def quest_records(rows: list, columns: tuple) -> list:
    at = {name: columns.index(name) for name in ("script", "quest", "source", "status", "level", "repeat", "name", "next_quest", "next_script", "path")}
    records = []
    for row in rows:
        records.append(
            {
                "script_text": row[at["script"]],
                "script": int(row[at["script"]]),
                "quest": int(row[at["quest"]]),
                "source": row[at["source"]],
                "status": row[at["status"]],
                "level": int(row[at["level"]]) if row[at["level"]].lstrip("-").isdigit() else row[at["level"]],
                "repeat": row[at["repeat"]],
                "name": row[at["name"]],
                "next_quest": int(row[at["next_quest"]]),
                "next_script": int(row[at["next_script"]]),
                "path": row[at["path"]],
            }
        )
    return records


def xml_text(value: object) -> str:
    text = str(value)
    kept = []
    for char in text:
        code = ord(char)
        if code in (0x9, 0xA, 0xD) or code >= 0x20:
            kept.append(char)
    text = "".join(kept)
    if len(text) > 32767:
        text = text[:32767]
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def column_letter(index: int) -> str:
    letters = ""
    while index:
        index, rem = divmod(index - 1, 26)
        letters = chr(65 + rem) + letters
    return letters


def sheet_xml(rows: list) -> str:
    width = max(len(row) for row in rows)
    last = f"{column_letter(width)}{len(rows)}"
    cols = []
    for index, title in enumerate(rows[0], start=1):
        size = min(40, max(12, len(str(title)) + 2))
        cols.append(f'<col min="{index}" max="{index}" width="{size}" customWidth="1"/>')
    body = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
        f"<cols>{''.join(cols)}</cols>",
        "<sheetViews><sheetView workbookViewId=\"0\">",
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>',
        "</sheetView></sheetViews>",
        "<sheetData>",
    ]
    for row_index, row in enumerate(rows, start=1):
        cells = []
        for col_index, value in enumerate(row, start=1):
            if value == "" or value is None:
                continue
            ref = f"{column_letter(col_index)}{row_index}"
            if row_index == 1:
                cells.append(f'<c r="{ref}" t="inlineStr" s="1"><is><t>{xml_text(value)}</t></is></c>')
                continue
            if type(value) is int:
                cells.append(f'<c r="{ref}"><v>{value}</v></c>')
                continue
            space = ' xml:space="preserve"' if str(value)[:1].isspace() or str(value)[-1:].isspace() else ""
            cells.append(f'<c r="{ref}" t="inlineStr"><is><t{space}>{xml_text(value)}</t></is></c>')
        body.append(f'<row r="{row_index}">{"".join(cells)}</row>')
    body.append("</sheetData>")
    body.append(f'<autoFilter ref="A1:{last}"/>')
    body.append("</worksheet>")
    return "".join(body)


def workbook_bytes(sheets: list) -> bytes:
    if not sheets:
        raise newquest.NewquestError("workbook không có sheet")
    for name, rows in sheets:
        if len(name) > 31 or not rows or not rows[0]:
            raise newquest.NewquestError(f"sheet không hợp lệ: {name}")
    import io

    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as book:
        overrides = [
            '<Override PartName="/xl/workbook.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
            '<Override PartName="/xl/styles.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
        ]
        workbook_sheets = []
        rels = []
        for index, (name, rows) in enumerate(sheets, start=1):
            overrides.append(
                f'<Override PartName="/xl/worksheets/sheet{index}.xml" '
                'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            )
            workbook_sheets.append(f'<sheet name="{xml_text(name)}" sheetId="{index}" r:id="rId{index}"/>')
            rels.append(
                f'<Relationship Id="rId{index}" '
                'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
                f'Target="worksheets/sheet{index}.xml"/>'
            )
            book.writestr(f"xl/worksheets/sheet{index}.xml", sheet_xml(rows))
        style_id = len(sheets) + 1
        rels.append(
            f'<Relationship Id="rId{style_id}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
            'Target="styles.xml"/>'
        )
        content = (
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            + "".join(overrides)
            + "</Types>"
        )
        book.writestr("[Content_Types].xml", content)
        book.writestr(
            "_rels/.rels",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
            'Target="xl/workbook.xml"/>'
            "</Relationships>",
        )
        book.writestr(
            "xl/workbook.xml",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            f"<sheets>{''.join(workbook_sheets)}</sheets></workbook>",
        )
        book.writestr(
            "xl/_rels/workbook.xml.rels",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            + "".join(rels)
            + "</Relationships>",
        )
        book.writestr(
            "xl/styles.xml",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
            '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
            '<fills count="2"><fill><patternFill patternType="none"/></fill>'
            '<fill><patternFill patternType="gray125"/></fill></fills>'
            "<borders count=\"1\"><border/></borders>"
            '<cellStyleXfs count="1"><xf/></cellStyleXfs>'
            '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
            "</styleSheet>",
        )
    return buffer.getvalue()


def write_excel(path: Path, sheets: list) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(workbook_bytes(sheets))


def prepared(descs: list, world: W.World) -> tuple:
    outs = newquest.outs_of(descs, world)
    regs = BU.Registries(E.Strings(set()))
    groups = newquest.group_rows_for(descs, world, regs)
    fresh = {
        "mission_quests": as_cells(O.quest_rows(outs)),
        "mission_objectives": as_cells(O.objective_rows(outs)),
        "mission_rewards": as_cells(O.reward_rows(outs)),
        "mission_prereqs": as_cells(O.prereq_rows(outs)),
        "mission_npcs": as_cells(O.link_rows(outs)),
        "mission_name_groups": as_cells(groups),
    }
    return outs, fresh


def replaceable_scripts(table: tsv_file.Table, incoming: set) -> set:
    """Script tân thủ đã nằm trong mission_quests với đúng tiền tố đường. Bảng con không có cột path."""
    columns = list(table.columns)
    script_at = columns.index("script")
    path_at = columns.index("path")
    found = set()
    for row in table.rows:
        script = int(row[script_at])
        if script not in incoming:
            continue
        if not str(row[path_at]).startswith(newquest.PATH_PREFIX):
            raise newquest.NewquestError(f"script {script} đã có ở đường khác: {row[path_at]}")
        found.add(script)
    return found


def kept_rows(table: tsv_file.Table, incoming: set, replaceable: set) -> tuple:
    columns = list(table.columns)
    script_at = columns.index("script")
    keep = []
    kept_index = []
    for index, row in enumerate(table.rows):
        script = int(row[script_at])
        if script not in incoming:
            keep.append(row)
            kept_index.append(index)
            continue
        if script not in replaceable:
            raise newquest.NewquestError(f"script {script} có trong {table.source} nhưng không phải dòng tân thủ")
    return keep, kept_index


def assert_quest_ids(table: tsv_file.Table, descs: list) -> None:
    columns = list(table.columns)
    quest_at = columns.index("quest")
    path_at = columns.index("path")
    wanted = {item.quest for item in descs}
    for row in table.rows:
        quest = int(row[quest_at])
        if quest in wanted and not str(row[path_at]).startswith(newquest.PATH_PREFIX):
            raise newquest.NewquestError(f"nhiệm vụ {quest} đã có ở đường khác: {row[path_at]}")


def check_replace(path: Path, name: str, fresh: list, incoming: set, replaceable: set) -> tuple:
    table = tsv_file.read_table(path)
    require_layout(table, name)
    keep, kept_index = kept_rows(table, incoming, replaceable)
    if column_widths(table.columns, table.rows) != column_widths(table.columns, keep):
        raise newquest.NewquestError(f"{name}: bỏ dòng tân thủ cũ làm đổi độ rộng cột")
    ensure_fit(table.columns, keep, fresh, name)
    old_lines = file_data_lines(path)
    rendered_old = data_lines(table, list(table.rows))
    if rendered_old != old_lines:
        raise newquest.NewquestError(f"{name}: đọc lại không khớp tệp đang có")
    merged = [*keep, *fresh]
    new_lines = data_lines(table, merged)
    expected = [old_lines[index] for index in kept_index]
    if new_lines[: len(expected)] != expected:
        raise newquest.NewquestError(f"{name}: dòng cũ bị đổi")
    return table, merged


def check_groups(path: Path, fresh: list) -> tuple:
    table = tsv_file.read_table(path)
    require_layout(table, "mission_name_groups")
    columns = list(table.columns)
    group_at, template_at, name_at = (columns.index(name) for name in ("group", "template", "name"))
    existing = list(table.rows)
    names: dict[str, str] = {}
    template_owner: dict[str, str] = {}
    keys = set()
    for row in existing:
        group, template, name = row[group_at], row[template_at], row[name_at]
        keys.add((group, template))
        prior = names.setdefault(group, name)
        if prior != name:
            raise newquest.NewquestError(f"nhóm {group} đang có hai tên")
        if template != "-1":
            template_owner.setdefault(template, group)
    adding = []
    for row in fresh:
        group, template, name = row
        prior = names.get(group)
        if prior is not None and prior != name:
            raise newquest.NewquestError(f"nhóm {group} đã là {prior}, không gán {name}")
        if template != "-1" and template in template_owner and template_owner[template] != group:
            owner = template_owner[template]
            raise newquest.NewquestError(f"mẫu {template} đã thuộc nhóm {owner}, không thêm cho {name}")
        if (group, template) in keys:
            continue
        keys.add((group, template))
        names[group] = name
        if template != "-1":
            template_owner[template] = group
        adding.append(row)
    ensure_fit(columns, existing, adding, "mission_name_groups")
    merged = [*existing, *adding]
    old_lines = file_data_lines(path)
    if data_lines(table, existing) != old_lines:
        raise newquest.NewquestError("mission_name_groups: đọc lại không khớp tệp đang có")
    new_lines = data_lines(table, merged)
    if new_lines[: len(old_lines)] != old_lines:
        raise newquest.NewquestError("mission_name_groups: dòng cũ bị đổi")
    return table, merged, len(adding)


def validate(descs: list, world: W.World) -> dict:
    _outs, fresh = prepared(descs, world)
    incoming = {item.script for item in descs}
    missing = [item.quest for item in descs if item.quest not in world.client_quests]
    if missing:
        raise newquest.NewquestError(f"không có trong danh bạ đã nạp: {missing}")
    planned = {}
    quest_path = SERVER / "mission_quests.tsv"
    quest_table = tsv_file.read_table(quest_path)
    require_layout(quest_table, "mission_quests")
    assert_quest_ids(quest_table, descs)
    replaceable = replaceable_scripts(quest_table, incoming)
    for name, rows in fresh.items():
        path = SERVER / f"{name}.tsv"
        if name == "mission_name_groups":
            table, merged, added = check_groups(path, rows)
            planned[name] = (table, merged, added)
            continue
        table, merged = check_replace(path, name, rows, incoming, replaceable)
        planned[name] = (table, merged, len(fresh[name]) if name != "mission_quests" else len(rows))
    return planned


def write_planned(planned: dict) -> None:
    # Bảng con trước. Dòng quest không mục tiêu mà status=ok sẽ nộp được ngay.
    order = [name for name in OWNED if name != "mission_quests"] + ["mission_quests"]
    for name in order:
        table, merged, _added = planned[name]
        tsv_file.write_table(
            SERVER / f"{name}.tsv",
            table.source,
            table.tool,
            table.types,
            table.columns,
            merged,
            layout=table.layout,
        )


def build_sheets(descs: list, merged: bool) -> list:
    items = item_index()
    dictionary = dictionary_index()
    tracks = track_index()
    templates = set()
    for desc in descs:
        for demand in desc.kill_ids:
            if demand.item:
                templates.add(demand.item)
    notes = empty_spawn_notes(templates)
    columns, quest_rows = index_rows(SERVER / "mission_quests.tsv")
    _reward_columns, reward_rows = index_rows(SERVER / "mission_rewards.tsv")
    records = quest_records(quest_rows, columns) if columns else []
    rewards: dict[str, list] = {}
    for row in reward_rows:
        rewards.setdefault(row[0], []).append(row)
    chains, singles = chain_sheet(records) if records else ([[]], 0)
    by_quest = {item.quest: item for item in descs}
    playable = [item for item in descs if gate_reason(item, by_quest) == ""]
    quest_ids = {item["quest"] for item in records}
    quest_ids.update(item.quest for item in descs)
    return [
        ("Tân thủ", newbie_rows(descs, items, dictionary, tracks, notes)),
        ("Phần thưởng", reward_sheet(descs, items)),
        ("Mục tiêu", objective_sheet(descs)),
        ("Chuỗi máy chủ", chains),
        ("Vòng cày", farm_sheet(records, rewards, items)),
        ("Lệch nguồn", conflict_sheet()),
        ("Chưa có dữ liệu", gap_sheet(dictionary, quest_ids)),
        ("Nguồn", source_sheet(playable, singles, merged)),
    ]


def summary_text(descs: list, planned: dict | None) -> str:
    ok = sum(1 for item in descs if item.status == "ok")
    blocked = len(descs) - ok
    by_quest = {item.quest: item for item in descs}
    playable = [f"{item.quest} {item.name}" for item in descs if gate_reason(item, by_quest) == ""]
    lines = [
        f"script tân thủ: {len(descs)}; chạy được {ok}; không có bộ chạy {blocked}",
        "vào được khi tiền đề cũng chạy được: " + ", ".join(playable),
    ]
    if planned is not None:
        for name in OWNED:
            _table, _merged, added = planned[name]
            lines.append(f"{name}: thêm hoặc thay {added} dòng")
    return "\n".join(lines)


def parse_args(argv: list) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="không ghi excel, không ghi TSV")
    parser.add_argument("--excel-only", action="store_true", help="chỉ ghi excel")
    parser.add_argument("--excel", type=Path, default=EXCEL)
    return parser.parse_args(argv)


def main(argv: list) -> int:
    args = parse_args(argv)
    if args.check and args.excel_only:
        raise newquest.NewquestError("chỉ chọn một trong --check và --excel-only")
    descs = newquest.read_all()
    world = load_world()
    planned = validate(descs, world)
    if args.check:
        emit(summary_text(descs, planned))
        emit("check: không ghi tệp")
        return 0
    if not args.excel_only:
        write_planned(planned)
    sheets = build_sheets(descs, merged=not args.excel_only)
    write_excel(args.excel, sheets)
    emit(summary_text(descs, None if args.excel_only else planned))
    emit(f"excel: {args.excel}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
