"""Báo cáo độ phủ của lua_extract.py: số thật đo trên dữ liệu, không phải ước lượng.

In ra từng mục: script (theo loại, bị loại, lỗi cú pháp), nhiệm vụ (theo nguồn và trạng thái, lý do cần xử lý tay),
độ phủ trên danh bạ nhiệm vụ của client, hội thoại (lối vào), tên chưa khớp hoặc mơ hồ, chuỗi.
"""
from __future__ import annotations

import collections
import re

NUMBER = re.compile(r"\d+")


def counts(items: list) -> collections.Counter:
    return collections.Counter(items)


def lines_of(title: str, counter: collections.Counter, limit: int = 40) -> list:
    out = [f"[{title}]"]
    for key, value in counter.most_common(limit):
        out.append(f"  {value:6d}  {key}")
    return out


def normalise_reason(reason: str) -> str:
    return NUMBER.sub("N", reason)[:90]


def script_section(ctx: object) -> list:
    scan = ctx.scan
    out = [f"Script.dat: {len(scan.dat)} mục; đã nạp {len(scan.low.units)}; file thiếu {len(scan.missing_files)}; "
           f"lỗi cú pháp {len(scan.syntax_errors)}; thuộc thư mục add-on bị loại {len(scan.addon)}"]
    out += lines_of("loại script đã nạp", counts(list(scan.categories.values())))
    out += lines_of("thư mục add-on bị loại", counts(list(scan.addon.values())))
    for script, reason in sorted(scan.syntax_errors.items()):
        out.append(f"  lỗi cú pháp {script} {scan.dat[script]}: {reason}")
    return out


def quest_section(ctx: object) -> list:
    quests = ctx.quests
    where = [(q.source, q.status, "trong client" if q.in_client else "NGOÀI client") for q in quests]
    out = lines_of("nhiệm vụ theo nguồn và trạng thái", counts(where))
    bad = [q for q in quests if q.source == "script" and q.status != "ok"]
    outside = [q for q in quests if q.source == "script" and not q.in_client]
    out += lines_of("lý do script nhiệm vụ chưa chạy bằng dữ liệu", counts([normalise_reason(q.reason) for q in bad]))
    out.append(f"  script nhiệm vụ có id ngoài danh bạ client 2026 (máy chủ từ chối nhận mặc định): {len(outside)}")
    return out


def coverage_section(ctx: object) -> list:
    covered = collections.defaultdict(set)
    for q in ctx.quests:
        if q.in_client:
            covered[q.quest].add((q.source, q.status))
    client = set(ctx.world.client_quests)
    bucket: collections.Counter = collections.Counter()
    for quest in client:
        have = covered.get(quest)
        bucket[describe(have)] += 1
    out = [f"danh bạ client 2026: {len(client)} id nhiệm vụ"]
    out += lines_of("độ phủ trên danh bạ client", bucket)
    uncovered = sorted(quest for quest in client if quest not in covered)
    out.append(f"  id client không có script cũng không có bảng ({len(uncovered)}): {uncovered[:60]}")
    return out


def describe(have: set | None) -> str:
    if not have:
        return "không có script XJL7457 cũng không có bảng"
    if ("script", "ok") in have:
        return "script chạy bằng dữ liệu"
    if ("table", "ok") in have:
        return "bảng client (bộ chạy chung)"
    return "script cần xử lý tay"


def dialog_section(ctx: object) -> list:
    entries = list(ctx.walker.entries.values())
    out = [f"lối vào hội thoại: {len(entries)}; khối {ctx.regs.blocks.next_id - 1}; dòng {len(ctx.regs.blocks.rows)}"]
    out += lines_of("trạng thái lối vào", counts([e.status for e in entries]))
    reasons = [normalise_reason(e.reason) for e in entries if e.status != "ok"]
    out += lines_of("lý do lối vào chưa dịch được", counts(reasons), 30)
    collisions = sorted(set(ctx.walker.root_collisions))
    out.append("mục của chính NPC mang số -1 (trùng khoá với lần bấm vào NPC, chạy như lần bấm): "
               f"{len(collisions)} script {collisions[:20]}")
    return out


def name_section(ctx: object) -> list:
    links = [link for q in ctx.quests for link in q.npc_links]
    out = lines_of("liên kết NPC của nhiệm vụ (cách khớp)", counts([link[4].split(":")[0] for link in links]))
    ambiguous = sorted({(link[2], link[3]) for link in links if link[4].startswith("ambiguous")})
    out.append(f"  tên NPC mơ hồ (cảnh, tên): {ambiguous[:30]}")
    world = ctx.world
    sizes = counts(["không có" if not world.monster_by_name.get(n) else "một" if len(world.monster_by_name[n]) == 1
                    else "nhiều" for n in ctx.regs.groups.values()])
    out += lines_of("nhóm tên quái (số mẫu quái khớp)", sizes)
    return out


def string_section(ctx: object) -> list:
    strings = ctx.regs.strings
    return [f"chuỗi: khoá client dùng thẳng thiếu trong StrDictionary {len(strings.missing)}: "
            f"{sorted(strings.missing)[:20]}; chữ hằng của script (khoá lua.*) {len(strings.literal)}"]


def render(ctx: object) -> str:
    sections = [script_section, quest_section, coverage_section, dialog_section, name_section, string_section]
    lines: list = []
    for section in sections:
        lines += section(ctx)
        lines.append("")
    return "\n".join(lines)
