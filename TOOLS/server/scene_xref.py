"""Đối chiếu cảnh: client 2026, máy chủ 0859602 và máy chủ 14 môn phái (XJL7457).

    python TOOLS/server/scene_xref.py <gốc dev/server> <gốc tlbb của XJL7457> <thư mục Scene của client 2026>
        [--check] [--import-list]

Ghi hai bảng vào <gốc dev/server>/tables/server:
  scene_xref.tsv         một dòng mỗi thư mục cảnh (đã có hoặc XJL7457 có), cột nói ai có gì;
  scene_client_only.tsv  tài nguyên cảnh của client 2026 mà không thư mục cảnh nào ghép tới;
  scene_ids.tsv          id cảnh mà client 2026 dùng (bảng SceneAttr) sang thư mục cảnh, nén thành khoảng id.

Thứ bậc nguồn (đề bài chung đợt gameplay): client 2026 thắng. Id cảnh của client là id mà máy chủ phải
gửi cho client, nên khi id của XJL7457 lệch id của client thì ghép theo tài nguyên rồi theo tên và ghi
`id_relation = shifted`. --import-list in tên các thư mục cảnh XJL7457 cần nhập (import_scene_xjl.py dùng
cùng hàm `plan` nên hai công cụ không thể lệch nhau).
"""
from __future__ import annotations

import sys
import tomllib
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

import tsv_file

TOOL = "scene_xref.py"
HELP = __doc__ or ""
ID_CAP = 12
# Chữ biến thể giữa các bản: XJL7457 viết 淩波洞, client 2026 viết 凌波洞.
NAME_FOLD = str.maketrans({"淩": "凌"})
NAME_AMBIGUOUS_MAX = 4  # ghép theo tên mà ra nhiều hơn số này tài nguyên client thì tên chung chung, bỏ
GENERIC_RES_IDS = 256  # tài nguyên client có nhiều id hơn số này là tài nguyên dùng chung (擂台)
UNHOSTED_RES = 10001  # clientres của các cảnh PCity<vùng>: client không có tệp .Scene riêng cho chúng

XREF_COLUMNS = (
    "scene_dir",
    "status",
    "action",
    "match",
    "client_res",
    "client_res_ids",
    "client_name",
    "client_id_count",
    "client_ids",
    "client_files",
    "s0859_ids",
    "s0859_name",
    "xjl_ids",
    "xjl_name",
    "id_relation",
    "walk_source",
    "note",
)
XREF_TYPES = (
    "text", "text", "text", "text", "text", "text", "text", "int", "text",
    "text", "text", "text", "text", "text", "text", "text", "text",
)  # fmt: skip
ONLY_COLUMNS = ("client_res_id", "client_res", "client_name", "client_id_count", "client_ids", "client_files")
ONLY_TYPES = ("int", "text", "text", "int", "text", "text")
IDS_COLUMNS = ("client_id_first", "client_id_last", "scene_dir", "client_res_id", "match")
IDS_TYPES = ("int", "int", "text", "int", "text")


@dataclass(frozen=True)
class Info:
    """Một mục [sceneN] của SceneInfo.ini."""

    scene_id: int
    name: str
    stem: str
    clientres: int
    active: bool


@dataclass
class Client:
    """SceneAttr (id, tên, tài nguyên) và SceneDefineEx (tài nguyên, tệp)."""

    names: dict[int, str] = field(default_factory=dict)
    res_of: dict[int, int] = field(default_factory=dict)
    stem_of_res: dict[int, str] = field(default_factory=dict)
    path_of_res: dict[int, str] = field(default_factory=dict)
    ids_of_res: dict[int, list[int]] = field(default_factory=lambda: defaultdict(list))
    res_of_stem: dict[str, list[int]] = field(default_factory=lambda: defaultdict(list))
    files: dict[str, set[str]] = field(default_factory=dict)


@dataclass
class Group:
    """Một nhóm cảnh: thư mục cảnh của máy chủ và/hoặc tài nguyên client."""

    scene_dir: str = ""
    match: str = "none"
    client_res_ids: list[int] = field(default_factory=list)
    client_ids: list[int] = field(default_factory=list)
    s_infos: list[Info] = field(default_factory=list)
    x_infos: list[Info] = field(default_factory=list)
    has_dir: bool = False
    dir_tool: str = ""


def fold(name: str) -> str:
    """Tên so sánh được giữa các bản."""
    return name.translate(NAME_FOLD)


def _int(text: str) -> int | None:
    try:
        return int(text)
    except ValueError:
        return None


def parse_scene_info(text: str) -> list[Info]:
    """SceneInfo.ini (đã giải mã): các section [sceneN]. Khoá lặp lấy bản đầu, như FindData."""
    sections: dict[int, dict[str, str]] = {}
    current: dict[str, str] | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("[scene") and line.endswith("]") and line[6:-1].isdigit():
            current = sections.setdefault(int(line[6:-1]), {})
        elif line.startswith("["):
            current = None
        elif current is not None and "=" in line and not line.startswith(";"):
            key, value = line.split("=", 1)
            current.setdefault(key.strip(), _cut_comment(value))
    return [info for number, body in sorted(sections.items()) if (info := _info_of(number, body))]


def _cut_comment(value: str) -> str:
    for mark in (";", "\t"):
        if mark in value:
            value = value.split(mark, 1)[0]
    return value.strip()


def _info_of(number: int, body: dict[str, str]) -> Info | None:
    file = body.get("file", "")
    res = _int(body.get("clientres", ""))
    if not file or res is None:
        return None
    stem = file[: -len(".scn")] if file.lower().endswith(".scn") else file
    return Info(number, body.get("name", ""), stem, res, body.get("active", "1") != "0")


UTF8_BOM = b"\xef\xbb\xbf"
# Ký tự mà văn bản Trung của máy chủ có thể chứa; ký tự ngoài ASCII mà không thuộc các khoảng này là dấu hiệu
# giải mã sai (vd. hai byte GBK của 鸭 cũng là UTF-8 hợp lệ cho chữ Cyrillic Ѽ).
PLAUSIBLE_RANGES = (
    (0x00B7, 0x00B7), (0x00D7, 0x00D7), (0x2000, 0x2BFF), (0x3000, 0x303F), (0x3400, 0x4DBF),
    (0x4E00, 0x9FFF), (0xF900, 0xFAFF), (0xFF00, 0xFFEF),
)  # fmt: skip


def _odd_chars(text: str) -> int:
    return sum(
        1 for char in text
        if ord(char) > 127 and not any(low <= ord(char) <= high for low, high in PLAUSIBLE_RANGES)
    )  # fmt: skip


def decode_text(data: bytes) -> str:
    """Tệp của bản private: GBK, hiếm khi UTF-8 (tongtianta5_monster.ini, GemCarve.txt). BOM là UTF-8. Không BOM
    mà cả hai cách giải mã đều hợp lệ thì lấy cách ít ký tự lạ hơn (hoà thì UTF-8); sai cả hai thì lỗi, không
    thay ký tự."""
    if data.startswith(UTF8_BOM):
        return data[len(UTF8_BOM) :].decode("utf-8")
    try:
        modern = data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("gb18030")
    try:
        legacy = data.decode("gb18030")
    except UnicodeDecodeError:
        return modern
    return modern if _odd_chars(modern) <= _odd_chars(legacy) else legacy


def load_legacy_info(tables: Path) -> list[Info]:
    """tables/server/scenes.tsv (SceneInfo.ini của 0859602)."""
    table = tsv_file.read_table(tables / "server" / "scenes.tsv")
    column = {name: index for index, name in enumerate(table.columns)}
    infos = []
    for row in table.rows:
        file = row[column["file"]]
        stem = file[: -len(".scn")] if file.lower().endswith(".scn") else file
        res = int(row[column["clientres_1"]])
        infos.append(Info(int(row[0]), row[column["name"]], stem, res, True))
    return infos


def load_client(tables: Path, scene_dir: Path) -> Client:
    """Bảng client 2026 đã xuất sang TSV và tệp thật trong thư mục Scene của client."""
    client = Client()
    attr = tsv_file.read_table(tables / "shared" / "scene_attributes.tsv")
    for row in attr.rows:
        number, res = int(row[0]), int(row[25])
        client.names[number] = row[1]
        client.res_of[number] = res
        client.ids_of_res[res].append(number)
    defs = tsv_file.read_table(tables / "shared" / "scene_definitions.tsv")
    for row in defs.rows:
        res = int(row[0])
        stem = row[4].rsplit(".", 1)[0]
        client.stem_of_res[res] = stem
        client.path_of_res[res] = row[5]
        client.res_of_stem[stem.lower()].append(res)
    for entry in scene_dir.iterdir():
        stem, _dot, ext = entry.name.rpartition(".")
        client.files.setdefault(stem.lower(), set()).add(ext.lower())
    return client


def _by_stem(infos: list[Info]) -> dict[str, list[Info]]:
    grouped: dict[str, list[Info]] = defaultdict(list)
    for info in infos:
        grouped[info.stem].append(info)
    return grouped


def _link_client(group: Group, client: Client) -> None:
    """Gắn nhóm vào tài nguyên client: id trùng cả tên, rồi tên tệp, rồi tên cảnh."""
    infos = group.s_infos + group.x_infos
    names = {fold(info.name) for info in infos}
    strong = {info.scene_id for info in infos if fold(client.names.get(info.scene_id, "")) in names}
    by_id = {client.res_of[number] for number in strong}
    by_stem = set(client.res_of_stem.get(group.scene_dir.lower(), []))
    by_name = {client.res_of[number] for number, name in client.names.items() if fold(name) in names}
    if len(by_name) > NAME_AMBIGUOUS_MAX:
        by_name = set()
    for kind, found in (("id", by_id), ("stem", by_stem), ("name", by_name)):
        if found:
            group.match = kind
            group.client_res_ids = sorted(found)
            break
    group.client_ids = _ids_of(group, client, names)


def _ids_of(group: Group, client: Client, names: set[str]) -> list[int]:
    """id cảnh của client thuộc nhóm. Tài nguyên chung chung (擂台 dùng cho hàng chục nghìn id) chỉ lấy
    id cùng tên; tài nguyên nhỏ mà không id nào cùng tên thì lấy hết."""
    every = [number for res in group.client_res_ids for number in client.ids_of_res[res]]
    named = [number for number in every if fold(client.names[number]) in names]
    if named:
        return sorted(named)
    return sorted(every) if len(every) <= GENERIC_RES_IDS else []


def plan(
    server_tables: Path,
    xjl_info: list[Info],
    dirs: dict[str, str],
    client: Client,
) -> list[Group]:
    """Nhóm theo thư mục cảnh. dirs: tên thư mục cảnh đã có -> công cụ ghi nó."""
    legacy = _by_stem(load_legacy_info(server_tables))
    xjl = _by_stem(xjl_info)
    names = set(dirs) | set(xjl)
    groups = []
    for name in sorted(names, key=lambda item: (item.lower(), item)):
        group = Group(scene_dir=name, has_dir=name in dirs, dir_tool=dirs.get(name, ""))
        group.s_infos = legacy.get(name, [])
        group.x_infos = xjl.get(name, [])
        _link_client(group, client)
        groups.append(group)
    return groups


def wants_import(group: Group) -> bool:
    """Cảnh XJL7457 cần nhập: máy chủ đó có chạy nó (có mục SceneInfo), client 2026 có nó, và thư mục
    cảnh chưa có hoặc do chính import_scene_xjl.py ghi (nhập lại thì thay, không thì bỏ qua)."""
    ours = group.has_dir and group.dir_tool.endswith("import_scene_xjl.py")
    return (not group.has_dir or ours) and bool(group.x_infos) and group.match != "none"


def _client_files(group: Group, client: Client) -> str:
    stems = {client.stem_of_res[res].lower() for res in group.client_res_ids if res in client.stem_of_res}
    exts: set[str] = set()
    for stem in stems:
        exts |= client.files.get(stem, set())
    wanted = ("scene", "path", "wcollision", "region", "heightmap")
    return "+".join(ext for ext in wanted if ext in exts)


def _ids(numbers: list[int]) -> str:
    return ",".join(str(number) for number in numbers[:ID_CAP])


def _first_name(infos: list[Info]) -> str:
    return infos[0].name if infos else ""


def _relation(group: Group) -> str:
    if not group.client_ids:
        return "client_missing"
    server = {info.scene_id for info in group.s_infos + group.x_infos}
    if not server:
        return "no_server_ids"
    return "same" if server & set(group.client_ids) else "shifted"


def _status(group: Group) -> str:
    if group.has_dir:
        return "present_xjl7457" if group.dir_tool.endswith("import_scene_xjl.py") else "present_0859602"
    if wants_import(group):
        return "importable_xjl7457"
    return "absent_xjl_private" if group.x_infos else "absent_xjl_unhosted"


def _action(group: Group) -> str:
    if group.has_dir:
        return "keep" if group.match != "none" else "drop_candidate"
    return "import" if wants_import(group) else "skip"


def _walk_source(scenes: Path, group: Group) -> str:
    toml = scenes / group.scene_dir / "scene.toml"
    if not group.has_dir or not toml.is_file():
        return ""
    value = tomllib.loads(toml.read_text(encoding="utf-8")).get("walk_source", "")
    return value if isinstance(value, str) else ""


def _note(group: Group, client: Client) -> str:
    notes = []
    if group.match == "name" and len(group.client_res_ids) > 1:
        notes.append("tên cảnh khớp nhiều tài nguyên client, chưa chọn được tệp .path")
    if group.s_infos and group.x_infos:
        if fold(_first_name(group.s_infos)) != fold(_first_name(group.x_infos)):
            notes.append("tên 0859602 khác tên XJL7457")
    if group.client_res_ids and not group.client_ids:
        notes.append("tài nguyên client không có mục SceneAttr nào")
    if any(res == UNHOSTED_RES for res in group.client_res_ids):
        notes.append("clientres 10001 của client không có tệp .Scene")
    return "; ".join(notes)


def _client_stem(group: Group, client: Client) -> str:
    stems = sorted({client.stem_of_res.get(res, "") for res in group.client_res_ids} - {""})
    return ";".join(stems)


def _client_name(group: Group, client: Client) -> str:
    names = Counter(client.names[number] for number in group.client_ids)
    return names.most_common(1)[0][0] if names else ""


def xref_row(group: Group, client: Client, scenes: Path) -> tuple[str, ...]:
    return (
        group.scene_dir,
        _status(group),
        _action(group),
        group.match,
        _client_stem(group, client),
        _ids(group.client_res_ids),
        _client_name(group, client),
        str(len(group.client_ids)),
        _ids(group.client_ids),
        _client_files(group, client),
        _ids([info.scene_id for info in group.s_infos]),
        _first_name(group.s_infos),
        _ids([info.scene_id for info in group.x_infos]),
        _first_name(group.x_infos),
        _relation(group),
        _walk_source(scenes, group),
        _note(group, client),
    )


def client_only_rows(groups: list[Group], client: Client) -> list[tuple[str, ...]]:
    """Tài nguyên client mà không thư mục cảnh nào ghép tới (client có, máy chủ chưa có dữ liệu)."""
    used = {res for group in groups for res in group.client_res_ids}
    rows = []
    for res in sorted(client.ids_of_res):
        if res in used:
            continue
        ids = sorted(client.ids_of_res[res])
        fake = Group(match="client_only", client_res_ids=[res], client_ids=ids)
        name = Counter(client.names[number] for number in ids).most_common(1)[0][0]
        rows.append(
            (str(res), client.stem_of_res.get(res, ""), name, str(len(ids)), _ids(ids), _client_files(fake, client))
        )
    return rows


def ids_rows(groups: list[Group], client: Client) -> list[tuple[str, ...]]:
    """id cảnh của client -> thư mục cảnh, nén thành khoảng id liền nhau cùng thư mục và cùng tài nguyên.
    Chỉ nhóm có thư mục và ghép được một tài nguyên duy nhất mới có dòng."""
    runs: list[list] = []
    pairs = []
    for group in groups:
        if group.has_dir and len(group.client_res_ids) == 1:
            pairs.extend((number, group.scene_dir, client.res_of[number], group.match) for number in group.client_ids)
    pairs.sort()
    for number, scene_dir, res, kind in pairs:
        last = runs[-1] if runs else None
        if last and last[1] == number - 1 and last[2:] == [scene_dir, res, kind]:
            last[1] = number
        else:
            runs.append([number, number, scene_dir, res, kind])
    return [tuple(str(cell) for cell in run) for run in runs]


def existing_dirs(scenes: Path) -> dict[str, str]:
    """Thư mục cảnh đã có trong dev/server/scenes và công cụ ghi scene.toml của nó."""
    found = {}
    if scenes.is_dir():
        for entry in sorted(scenes.iterdir()):
            if entry.is_dir():
                found[entry.name] = tsv_file.owned_tool(entry / "scene.toml") or ""
    return found


def load_xjl_info(xjl_root: Path) -> list[Info]:
    """xjl_root là thư mục tlbb của XJL7457 (có Public và Server)."""
    return parse_scene_info(decode_text((xjl_root / "Server" / "Config" / "SceneInfo.ini").read_bytes()))


def build(server_root: Path, xjl_root: Path, client_scene: Path) -> tuple[list[Group], Client]:
    tables = server_root / "tables"
    client = load_client(tables, client_scene)
    groups = plan(tables, load_xjl_info(xjl_root), existing_dirs(server_root / "scenes"), client)
    return groups, client


def write_tables(server_root: Path, groups: list[Group], client: Client) -> None:
    scenes = server_root / "scenes"
    out = server_root / "tables" / "server"
    rows = [xref_row(group, client, scenes) for group in groups]
    source = "client_2026/SceneAttr.txt + 0859602 SceneInfo.ini + XJL7457/Server/Config/SceneInfo.ini"
    tsv_file.write_table(out / "scene_xref.tsv", source, TOOL, XREF_TYPES, XREF_COLUMNS, rows)
    only = client_only_rows(groups, client)
    only_source = "client_2026/SceneAttr.txt + SceneDefineEx.txt"
    tsv_file.write_table(out / "scene_client_only.tsv", only_source, TOOL, ONLY_TYPES, ONLY_COLUMNS, only)
    ids_source = "client_2026/SceneAttr.txt"
    tsv_file.write_table(out / "scene_ids.tsv", ids_source, TOOL, IDS_TYPES, IDS_COLUMNS, ids_rows(groups, client))


def summary(groups: list[Group], client: Client) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for group in groups:
        counts[_status(group)] += 1
        counts["relation_" + _relation(group)] += 1
    counts["client_only"] = len(client_only_rows(groups, client))
    counts["client_id_conflicts"] = id_conflicts(groups)
    return dict(sorted(counts.items()))


def id_conflicts(groups: list[Group]) -> int:
    """Số id cảnh của client mà hai thư mục cảnh cùng nhận. Phải bằng 0: một id chỉ vào một thư mục."""
    owners: dict[int, int] = Counter()
    for group in groups:
        if group.has_dir and len(group.client_res_ids) == 1:
            owners.update(dict.fromkeys(group.client_ids, 1))
    return sum(1 for count in owners.values() if count > 1)


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    flags = {arg for arg in args if arg.startswith("--")}
    positional = [arg for arg in args if not arg.startswith("--")]
    if len(positional) != 3:
        print("scene_xref.py:1: cần ba tham số: gốc dev/server, gốc XJL7457, thư mục Scene của client")
        return 1
    groups, client = build(Path(positional[0]), Path(positional[1]), Path(positional[2]))
    if "--import-list" in flags:
        print("\n".join(group.scene_dir for group in groups if wants_import(group)))
        return 0
    if "--check" not in flags:
        write_tables(Path(positional[0]), groups, client)
    for key, value in summary(groups, client).items():
        print(f"{key} {value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
