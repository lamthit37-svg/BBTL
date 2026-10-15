#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/rewrite.py
#  PHÂN HỆ   : Source Headers / Rewrite
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Dựng tệp mới có khung từ tệp cũ: ý lấy từ comment đầu tệp cũ, phần không
#    vừa khung giữ thành comment thường dưới khung.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Dựng tệp mới có khung từ tệp cũ: ý lấy từ comment đầu tệp cũ, phần không vừa khung giữ thành comment thường dưới khung.

Không mất chữ: mọi từ của comment cũ nằm trong khung hoặc trong phần comment thường dưới nó (kiểm bằng lossless()).
"""
from __future__ import annotations

import textwrap
from dataclasses import dataclass, field

import legacy_box
import source_frame as frame
from extract import BULLET_START, Item, Layout, Run, locate, sentences, to_items, words
from profiles import Profile

# Số dòng của khung còn lại cho phần chữ khi tóm tắt chuỗi tài liệu Python (chuỗi ấy vẫn nằm nguyên trong tệp).
DOCSTRING_LINES = 4
REMAINDER_WIDTH = 118


@dataclass
class Plan:
    """Điều sẽ ghi: các ý của khung, các dòng comment thường dưới khung, và có cần mô tả viết tay không."""

    items: list[str] = field(default_factory=list)
    remainder: list[str] = field(default_factory=list)
    needs_description: bool = False
    reason: str = ""


def frame_text(item: Item) -> str:
    """Chữ của một ý khi vào khung: bỏ dấu liệt kê "-", "*" của comment cũ (khung tự thêm "- ")."""
    return BULLET_START.sub("", item.text, count=1) if item.literal and not item.text[:1].isdigit() else item.text


def _fits(text: str, room: int) -> bool:
    try:
        return frame.wrapped_height(text) <= room
    except frame.FrameError:
        return False


def _cut(text: str, room: int) -> tuple[str, str] | None:
    """Phần đầu của text vừa room dòng khung và phần còn lại; ưu tiên cắt ở hết câu, không thì ở ranh giới từ. None nếu không cắt được."""
    parts = sentences(text)
    for count in range(len(parts) - 1, 0, -1):
        head = " ".join(parts[:count])
        if _fits(head, room):
            return head, " ".join(parts[count:])
    tokens = text.split()
    for count in range(len(tokens) - 1, 0, -1):
        head = " ".join(tokens[:count])
        if _fits(head, room):
            return head, " ".join(tokens[count:])
    return None


def _group_cost(items: list[Item], start: int) -> int | None:
    """Số dòng khung của cả đoạn văn bắt đầu ở items[start]; None khi có ý không vào được khung."""
    total = 0
    for item in items[start:]:
        if item.paragraph != items[start].paragraph:
            break
        try:
            total += frame.wrapped_height(frame_text(item))
        except frame.FrameError:
            return None
    return total


def select(items: list[Item], budget: int) -> tuple[list[str], int, str]:
    """Chọn ý đưa vào khung theo thứ tự: (các ý, số Item đã dùng hết, phần chữ còn lại của ý bị cắt giữa chừng)."""
    chosen: list[str] = []
    used = 0
    taken = 0
    last_paragraph = None
    for at, item in enumerate(items):
        text = frame_text(item)
        starts_paragraph = item.paragraph != last_paragraph
        if starts_paragraph and chosen:
            cost = _group_cost(items, at)
            if cost is None or used + cost > budget:
                break
        if _fits(text, budget - used):
            chosen.append(text)
            used += frame.wrapped_height(text)
            taken = at + 1
            last_paragraph = item.paragraph
            continue
        if not chosen or last_paragraph == item.paragraph:
            cut = _cut(text, budget - used)
            if cut is not None:
                chosen.append(cut[0])
                return chosen, taken, cut[1]
        break
    return chosen, taken, ""


def wrap_comment(prefix: str, text: str) -> list[str]:
    width = REMAINDER_WIDTH - len(prefix) - 1
    return [f"{prefix} {line}" for line in textwrap.wrap(text, width=width, break_long_words=False, break_on_hyphens=False)]


def remainder_lines(run: Run, items: list[Item], taken: int, leftover: str, profile: Profile) -> list[str]:
    """Phần comment cũ chưa vào khung thành dòng comment thường: nguyên văn khi là comment dòng, đổi ký hiệu khi là comment khối.

    taken là số ý đã vào khung trọn vẹn; leftover là phần còn lại của ý thứ taken khi nó bị cắt giữa chừng (rỗng nếu không).
    """
    out = wrap_comment(profile.prefix, leftover) if leftover else []
    if leftover:
        from_line = items[taken].last + 1
    elif taken < len(items):
        from_line = items[taken].first
    else:
        from_line = len(run.content)
    block = run.raw[0].startswith("/*")
    for index in range(from_line, len(run.content)):
        text = run.content[index]
        out.append(f"{profile.prefix} {text}".rstrip() if block else run.raw[index].rstrip())
    while out and out[0].strip() in {"", profile.prefix}:
        out.pop(0)
    while out and out[-1].strip() in {"", profile.prefix}:
        out.pop()
    return out


def docstring_items(doc: list[str]) -> list[str]:
    """Ý tóm tắt lấy từ đoạn đầu của chuỗi tài liệu Python: các câu đầu vừa DOCSTRING_LINES dòng khung."""
    paragraph: list[str] = []
    for line in doc:
        if not line.strip():
            if paragraph:
                break
            continue
        paragraph.append(line.strip())
    text = " ".join(paragraph)
    if not text:
        return []
    if _fits(text, DOCSTRING_LINES):
        return [text]
    cut = _cut(text, DOCSTRING_LINES)
    return [cut[0]] if cut else []


def plan_for(lines: list[str], profile: Profile, layout: Layout, description: list[str] | None) -> Plan:
    """Kế hoạch ghi khung cho một tệp chưa có khung. description (viết tay) thay mọi thứ ở các ý và giữ nguyên comment cũ."""
    run = layout.run
    if description:
        plan = Plan(items=list(description))
        if run is not None:
            plan.remainder = remainder_lines(run, to_items(run.content), 0, "", profile)
        return plan
    if run is not None:
        items = to_items(run.content)
        chosen, taken, leftover = select(items, frame.MAX_BULLET_LINES)
        if chosen:
            return Plan(chosen, remainder_lines(run, items, taken, leftover, profile))
        return Plan(needs_description=True, reason="comment đầu tệp không vào được khung (chữ Hán hoặc từ quá dài)")
    summary = docstring_items(layout.docstring)
    if summary:
        return Plan(summary)
    return Plan(needs_description=True, reason="tệp không có comment đầu tệp")


def lossless(run: Run | None, plan: Plan, profile: Profile) -> bool:
    """Mọi từ của comment cũ có mặt, đúng thứ tự, trong ý của khung rồi phần comment thường dưới khung."""
    if run is None:
        return True
    old = words(" ".join(run.content))
    tail = [strip for strip in (line[len(profile.prefix) :] for line in plan.remainder)]
    new = words(" ".join(plan.items)) + words(" ".join(tail))
    return old == new


def assemble(lines: list[str], profile: Profile, layout: Layout, path: str, plan: Plan) -> list[str]:
    """Các dòng của tệp mới (tệp chưa có khung)."""
    out = lines[: layout.preamble]
    out += frame.render_frame(profile.prefix, path, plan.items)
    lead = lines[layout.lead] if layout.lead is not None else None
    if plan.remainder:
        out += ["", *plan.remainder]
    if lead is not None:
        out += ["", lead] if plan.remainder else [lead]
    rest = lines[layout.code :]
    while rest and not rest[0].strip():
        rest.pop(0)
    if rest:
        out += ["", *rest]
    return out


def rebuild_frame(lines: list[str], profile: Profile, layout: Layout, path: str) -> list[str] | None:
    """Tệp đã có khung mới: dựng lại từ chữ của nó nếu có sai lệch (độ rộng, đường dẫn, CHUẨN...); None khi khung đã đúng
    hay hỏng tới mức không đọc được ý (check_file báo lỗi)."""
    at = layout.frame_at
    if at is None:
        return None
    parsed = frame.parse_frame(lines, at, profile.prefix, path)
    if parsed is None or not parsed.problems or not parsed.items:
        return None
    rebuilt = frame.render_frame(profile.prefix, path, parsed.items, parsed.subsystem or None)
    return lines[:at] + rebuilt + lines[parsed.stop :]


def migrate_legacy(lines: list[str], profile: Profile, layout: Layout, path: str) -> tuple[list[str] | None, Plan]:
    """Tệp mang khung hộp cũ: đổi sang khung mới, ý không vừa thì thành comment thường ngay dưới khung (không mất chữ)."""
    at = layout.legacy_at
    read = legacy_box.read(lines, at, profile.prefix) if at is not None else None
    if at is None or read is None or not read[1]:
        return None, Plan(needs_description=True, reason="khung hộp cũ hỏng, không đọc được ý")
    stop, old = read
    items = [Item(text, index, index, index) for index, text in enumerate(old)]
    chosen, taken, leftover = select(items, frame.MAX_BULLET_LINES)
    if not chosen:
        return None, Plan(needs_description=True, reason="ý của khung cũ không vào được khung mới (chữ Hán hoặc từ quá dài)")
    spill = ([leftover] if leftover else []) + old[taken + 1 if leftover else taken :]
    remainder = [line for text in spill for line in wrap_comment(profile.prefix, text)]
    out = lines[:at] + frame.render_frame(profile.prefix, path, chosen)
    if remainder:
        out += ["", *remainder]
        if stop < len(lines) and lines[stop].strip():
            out.append("")
    return out + lines[stop:], Plan(items=chosen, remainder=remainder)


def rewrite(text_lines: list[str], profile: Profile, path: str, description: list[str] | None) -> tuple[list[str] | None, Plan]:
    """(các dòng mới hoặc None khi không đổi, kế hoạch). Kế hoạch needs_description thì không có dòng mới."""
    layout = locate(text_lines, profile, frame.border(profile.prefix), legacy_box.border(profile.prefix))
    if layout.frame_at is not None:
        return rebuild_frame(text_lines, profile, layout, path), Plan()
    if layout.legacy_at is not None:
        return migrate_legacy(text_lines, profile, layout, path)
    plan = plan_for(text_lines, profile, layout, description)
    if plan.needs_description:
        return None, plan
    if not description and not lossless(layout.run, plan, profile):
        plan.needs_description = True
        plan.reason = "tách comment cũ làm mất chữ (lỗi của bộ tách)"
        return None, plan
    return assemble(text_lines, profile, layout, path, plan), plan
