"""Chữ thoại của máy chủ ở dạng văn bản: tables/server/dialogue.zh.txt.

Chữ ở đây là những câu viết thẳng trong script Lua gốc (lời NPC, lựa chọn, chuỗi nhiệm vụ); đoạn thoại nằm ở khoá
StrDictionary của client thì không có trong tệp này. lua_extract.py sinh tệp (nhà phát triển); nhà phát hành không sửa
tệp này mà đặt câu muốn đổi vào config/text/dialogue.zh.txt cùng định dạng, khoá trùng thì câu của config thắng
(docs/SERVER-DU-LIEU.md).

Định dạng là bảng hai cột của dự án (bộ đọc C++ table::parse_tsv và thienlong_lint đọc thẳng), đuôi .txt để mở bằng
Notepad thay vì Excel (Excel đổi bảng mã của chữ Hán khi lưu):
    # ...                    dòng hợp đồng (schema, source, tool, types, layout) và chú thích
    key           <tab>text  dòng tên cột
    ## 350999:-1  <nhãn>     mở nhóm của một script ("<script>:<số GetNumText>") hoặc nhiệm vụ ("quest:<số>");
                             bộ đọc bảng bỏ dòng này như mọi dòng #, công cụ dùng nó để xếp câu theo NPC
    lua.0aa406a1  <tab>chữ   một câu: khoá đệm dấu cách cho thẳng cột, một tab, chữ; dấu cách cuối thật ghi bằng ␣
Mã chuỗi gửi qua dây là fnv1a32 của khoá (ops::string_id), nên khoá là mã định danh: sửa chữ thì giữ khoá.

Kiểm một tệp (của nhà phát triển hay của nhà phát hành), ở gốc dự án:
    python -X utf8 TOOLS/server/dialogue_text.py check [tệp]
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import lua_emit
import tsv_file

PROJECT = Path(__file__).resolve().parents[2]
FILE_NAME = "dialogue.zh.txt"
TABLE_FILE = PROJECT / "dev/server/tables/server" / FILE_NAME
SOURCE = "Public/Data/Script"
TOOL = "TOOLS/server/lua_extract.py"
COLUMNS = ("key", "text")
KEY = re.compile(r"[A-Za-z0-9_.]+")
OWNER = re.compile(r"\d+:-?\d+|quest:\d+")
GROUP = "##"
MARK = tsv_file.SPACE_MARK
GAP = tsv_file.ALIGN_GAP
NOTES = (
    "# Chữ thoại của máy chủ: lời NPC, lựa chọn và chuỗi nhiệm vụ viết thẳng trong script Lua gốc.",
    "# Nhà phát hành KHÔNG sửa tệp này (lần nâng bản sau ghi đè): chép dòng muốn đổi sang",
    "# config/text/dialogue.zh.txt, giữ nguyên khoá, sửa chữ. Khoá trùng thì câu của config thắng.",
    "# Mỗi dòng: khoá, dấu cách cho thẳng cột, MỘT tab, chữ. Dấu cách đầu chữ giữ nguyên; dấu cách cuối ghi bằng ␣.",
    "# Dòng \"## <script>:<số>\" hoặc \"## quest:<số>\" mở nhóm của một script NPC hay nhiệm vụ; phần sau là nhãn.",
)


class DialogueError(ValueError):
    """Tệp sai định dạng; thông báo kèm số dòng khi biết."""


@dataclass(frozen=True)
class Entry:
    key: str
    text: str
    owner: str


def _owner_order(owner: str) -> tuple[int, int, int]:
    if owner.startswith("quest:"):
        return (1, int(owner[len("quest:") :]), 0)
    script, number = owner.split(":")
    return (0, int(script), int(number))


def _check_entry(entry: Entry, where: str) -> None:
    if not KEY.fullmatch(entry.key):
        raise DialogueError(f"{where}: khoá không hợp lệ: {entry.key!r}")
    if not OWNER.fullmatch(entry.owner):
        raise DialogueError(f"{where}: chủ nhóm không hợp lệ: {entry.owner!r}")
    if any(char in entry.text for char in "\t\r\n") or MARK in entry.text:
        raise DialogueError(f"{where}: chữ chứa tab, xuống dòng hoặc {MARK}: {entry.key}")


def _mark(text: str) -> str:
    body = text.rstrip(" ")
    return body + MARK * (len(text) - len(body))


def _unmark(cell: str) -> str:
    body = cell.rstrip(MARK)
    return body + " " * (len(cell) - len(body))


def check_ids(entries: list[Entry]) -> None:
    """Hai khoá cùng fnv1a32 là lỗi: mã chuỗi gửi qua dây sẽ lẫn hai câu."""
    by_id: dict[int, str] = {}
    for entry in sorted(entries, key=lambda item: item.key):
        ident = lua_emit.fnv1a32(entry.key)
        if ident in by_id:
            raise DialogueError(f"khoá {entry.key} và {by_id[ident]} cùng mã chuỗi {ident}")
        by_id[ident] = entry.key


def render(entries: list[Entry], labels: dict[str, str]) -> str:
    """Nội dung tệp: nhóm theo chủ (script rồi nhiệm vụ), trong nhóm theo khoá. O(n log n)."""
    groups: dict[str, list[Entry]] = {}
    for entry in sorted(entries, key=lambda item: item.key):
        _check_entry(entry, "bản ghi")
        groups.setdefault(entry.owner, []).append(entry)
    check_ids(entries)
    width = max((len(entry.key) for entry in entries), default=0)
    width = max(width, len(COLUMNS[0])) + GAP
    lines = [
        f"# schema {tsv_file.SCHEMA}",
        f"# source: {SOURCE}",
        f"# tool: {TOOL}{tsv_file.TOOL_SUFFIX}",
        "# types: text\ttext",
        f"{tsv_file.LAYOUT_PREFIX}aligned",
        *NOTES,
        f"{COLUMNS[0].ljust(width)}\t{COLUMNS[1]}",
    ]
    for owner in sorted(groups, key=_owner_order):
        label = " ".join(labels.get(owner, "").split())
        lines.append(f"{GROUP} {owner}  {label}".rstrip())
        lines.extend(f"{entry.key.ljust(width)}\t{_mark(entry.text)}" for entry in groups[owner])
    return "\n".join(lines) + "\n"


def _data_line(line: str, owner: str, aligned: bool, where: str) -> Entry:
    key, tab, cell = line.partition("\t")
    if not tab or "\t" in cell:
        raise DialogueError(f"{where}: cần đúng MỘT tab giữa khoá và chữ")
    if not owner:
        raise DialogueError(f"{where}: câu đứng trước dòng nhóm đầu tiên")
    entry = Entry(key.rstrip(" ") if aligned else key, _unmark(cell.rstrip(" ")) if aligned else cell, owner)
    _check_entry(entry, where)
    return entry


def parse(text: str) -> list[Entry]:
    """Đọc tệp (của nhà phát triển hay nhà phát hành; dòng tên cột "key<tab>text" bắt buộc, dòng hợp đồng thì không).
    Sai định dạng, khoá trùng hay hai khoá cùng mã chuỗi thì DialogueError kèm số dòng. O(độ dài tệp)."""
    entries: list[Entry] = []
    first_line: dict[str, int] = {}
    owner, aligned, header = "", False, False
    for number, line in enumerate(text.removeprefix("﻿").replace("\r\n", "\n").split("\n"), start=1):
        where = f"dòng {number}"
        if line == f"{tsv_file.LAYOUT_PREFIX}aligned" and not header:
            aligned = True
        if line.startswith(GROUP):
            fields = line[len(GROUP) :].split()
            if not line.startswith(GROUP + " ") or not fields or not OWNER.fullmatch(fields[0]):
                raise DialogueError(f"{where}: dòng nhóm phải là '## <script>:<số>' hoặc '## quest:<số>'")
            if not header:
                raise DialogueError(f"{where}: dòng nhóm đứng trước dòng tên cột 'key<tab>text'")
            owner = fields[0]
            continue
        if not line.strip() or line.startswith("#"):
            continue
        if not header:
            if tuple(cell.strip(" ") for cell in line.split("\t")) != COLUMNS:
                raise DialogueError(f"{where}: dòng tên cột phải là 'key<tab>text'")
            header = True
            continue
        entry = _data_line(line, owner, aligned, where)
        if entry.key in first_line:
            raise DialogueError(f"{where}: khoá {entry.key} đã có ở dòng {first_line[entry.key]}")
        first_line[entry.key] = number
        entries.append(entry)
    check_ids(entries)
    return entries


def labels_of(entries: list[Entry], table_dir: Path) -> dict[str, str]:
    """Nhãn của từng nhóm cho người đọc: đường dẫn script NPC, không có thì tên nhiệm vụ. Thiếu bảng thì không nhãn."""
    names: dict[str, str] = {}
    quests = table_dir / "mission_quests.tsv"
    roles = table_dir / "talk_npc_roles.tsv"
    if quests.is_file():
        table = tsv_file.read_table(quests)
        script, quest, name = (table.columns.index(column) for column in ("script", "quest", "name"))
        for row in table.rows:
            names.setdefault(f"quest:{row[quest]}", row[name])
            names.setdefault(f"script:{row[script]}", row[name])
    if roles.is_file():
        table = tsv_file.read_table(roles)
        script, path = table.columns.index("script"), table.columns.index("path")
        for row in table.rows:
            names[f"script:{row[script]}"] = row[path]
    labels = {}
    for owner in {entry.owner for entry in entries}:
        labels[owner] = names.get(owner if owner.startswith("quest:") else f"script:{owner.split(':')[0]}", "")
    return labels


def write(path: Path, entries: list[Entry], labels: dict[str, str]) -> None:
    """Ghi tệp qua tệp tạm. Tệp có sẵn mà không phải của lua_extract thì không ghi đè."""
    if path.exists() and tsv_file.owned_tool(path) != TOOL:
        raise DialogueError(f"{path}: không phải tệp do {TOOL} ghi")
    text = render(entries, labels)
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f"{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        os.replace(temporary, path)
    except OSError:
        if os.path.exists(temporary):
            os.unlink(temporary)
        raise


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=("check",))
    parser.add_argument("file", type=Path, nargs="?", default=TABLE_FILE)
    args = parser.parse_args(argv)
    try:
        entries = parse(args.file.read_bytes().decode("utf-8"))
    except (DialogueError, OSError, UnicodeError) as error:
        print(f"{args.file}: {error}", file=sys.stderr)
        return 1
    print(f"{args.file}: {len(entries)} câu, không lỗi")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
