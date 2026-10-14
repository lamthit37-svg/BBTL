"""Nhập cảnh từ máy chủ 14 môn phái (XJL7457) vào dev/server/scenes.

    python TOOLS/server/import_scene_xjl.py <gốc dev/server> <gốc tlbb của XJL7457> <thư mục Scene của client>
        [--check]

Chỉ nhập cảnh mà (1) XJL7457 có chạy (có mục [sceneN] trong SceneInfo.ini), (2) client 2026 có (khớp theo
id, tên tệp hoặc tên cảnh: xem scene_xref.py) và (3) dev/server/scenes chưa có thư mục, hoặc thư mục đó do
chính công cụ này ghi (chạy lại thì thay). Cảnh private của nhà phát hành (client 2026 không có) bị bỏ. Cảnh
bản 0859602 đã có không bị đụng tới: nguồn đó vào trước, mọi chênh lệch với XJL7457 nằm ở scene_diff.py.
Thứ tự chạy cả đường ống: export_scene.py, import_scene_xjl.py, scene_walk.py, scene_xref.py, scene_diff.py.

Định dạng đầu ra giống export_scene.py (cùng mã đọc ini và cùng kiểm miền), khác ở ba chỗ:
  * XJL7457 là GBK (tệp UTF-8 hiếm gặp thì nhận ra được), nên giải mã rồi ghi lại UTF-8, xuống dòng CRLF
    như bản 0859602, bỏ khoảng trắng quanh dấu `=`;
  * scn trỏ tới tệp không có trên đĩa thì khoá đó vào scene.toml mục "Khoá scn không có tệp";
  * `# tool:` là import_scene_xjl.py và `# source:` bắt đầu bằng XJL7457/ để biết dòng đến từ đâu.
Mỗi cảnh chạy riêng: một cảnh hỏng chỉ bị liệt kê, không chặn cảnh khác. Thoát 1 nếu có cảnh hỏng.
"""
from __future__ import annotations

import shutil
import sys
import tempfile
from collections import Counter
from pathlib import Path

import export_scene
import scene_classify as kinds
import scene_xref
import tsv_file

TOOL = "import_scene_xjl.py"
HELP = __doc__ or ""
PROFILE = export_scene.Profile(
    tool=TOOL,
    source_prefix="XJL7457/Public/Scene/",
    intro="Dữ liệu cảnh bản 14 môn phái (XJL7457) do công cụ sinh, sửa tay sẽ mất khi nhập lại.",
    tolerant=True,
)
TEXT_KINDS = frozenset(
    {
        kinds.SCN, kinds.MONSTER, kinds.MONSTER_LEVEL, kinds.MONSTER_BY_LEVEL, kinds.MONSTER_GROUP,
        kinds.MONSTER_BARE, kinds.MONSTER_ENTRANCE, kinds.AREA, kinds.PATROL, kinds.GROWPOINT,
        kinds.GROWPOINT_SETUP, kinds.PET, kinds.PLATFORM, kinds.PORTAL, kinds.BUS,
    }
)  # fmt: skip
INI_KINDS = TEXT_KINDS - {kinds.GROWPOINT, kinds.GROWPOINT_SETUP}
SCN_FILE_KEYS = (
    "navmapname", "monsterfile", "eventfile", "patrolpoint", "platformfile", "growpointdata",
    "growpointsetup", "stallinfodata", "petfile", "portalfile", "busfile",
)  # fmt: skip


def scene_root(xjl_root: Path) -> Path:
    return xjl_root / "Public" / "Scene"


def normalize_ini(text: str) -> str:
    """CRLF, bỏ khoảng trắng hai đầu dòng và quanh dấu `=`. Chú thích `;` đầu dòng giữ nguyên."""
    lines = []
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith(";") or line.startswith("[") or "=" not in line:
            lines.append(line)
            continue
        key, value = line.split("=", 1)
        lines.append(f"{key.strip()}={value.strip()}")
    return "\r\n".join(lines) + "\r\n"


def normalize_table(text: str) -> str:
    """Bảng chữ (growpoint): bỏ BOM, dòng trống và dòng bắt đầu bằng #, những dòng mà bộ đọc gốc
    (OpenFromMemoryImpl_Text) cũng bỏ. Hai dòng đầu là kiểu và tên cột nên luôn giữ. Tệp mà dòng kiểu
    cách nhau bằng dấu cách (vài tệp không có bản ghi nào của bản private) thì đổi sang tab."""
    lines = text.splitlines()
    if lines and "\t" not in lines[0]:
        lines = [line.replace(" ", "\t") for line in lines]
    body = [line for line in lines[2:] if line != "" and not line.startswith("#")]
    return "\n".join([*lines[:2], *body]) + "\n"


def convert_text(kind: str, data: bytes) -> bytes:
    text = scene_xref.decode_text(data.removeprefix(b"\xef\xbb\xbf"))
    if kind in INI_KINDS:
        return normalize_ini(text).encode("utf-8")
    return normalize_table(text).encode("utf-8")


def scn_references(data: bytes) -> list[str]:
    """Tên tệp mà một scn nhắc tới, theo thứ tự khoá cố định."""
    values: dict[str, str] = {}
    for line in scene_xref.decode_text(data).splitlines():
        key, _eq, value = line.strip().partition("=")
        values.setdefault(key.strip(), value.strip())
    return [values[key] for key in SCN_FILE_KEYS if values.get(key)]


def classify_dir(source: Path) -> dict[str, str]:
    """Tên tệp -> loại, cho mọi tệp của Public/Scene mà export_scene hiểu."""
    found = {}
    for entry in sorted(source.iterdir()):
        kind = kinds.classify_name(entry.name) if entry.is_file() else None
        if kind is not None and kind != kinds.DROPPED:
            found[entry.name] = kind
    return found


def owned_files(source: Path, kind_of: dict[str, str], target: str, stems: set[str]) -> list[str]:
    """Tệp thuộc về cảnh target: scn của nó, tệp scn nhắc tới và tệp có tiền tố dài nhất là target."""
    owned = {f"{target}.scn"}
    owned.update(name for name in scn_references((source / f"{target}.scn").read_bytes()) if name in kind_of)
    for name, kind in kind_of.items():
        if kind != kinds.SCN and kinds.longest_stem(name, stems) == target:
            owned.add(name)
    return sorted(owned)


def stage_scene(source: Path, kind_of: dict[str, str], names: list[str], stage: Path) -> None:
    target = stage / "Public" / "Scene"
    target.mkdir(parents=True, exist_ok=True)
    for name in names:
        data = (source / name).read_bytes()
        kind = kind_of[name]
        out = convert_text(kind, data) if kind in TEXT_KINDS else data
        (target / name).write_bytes(out)


def import_one(
    source: Path, kind_of: dict[str, str], target: str, stems: set[str], scratch: Path
) -> tuple[export_scene.Report, Path]:
    stage = scratch / "stage" / target
    out = scratch / "out" / target
    names = owned_files(source, kind_of, target, stems)
    stage_scene(source, kind_of, names, stage)
    report = export_scene.export_scenes(stage, out, scratch / "columns" / target, False, None, PROFILE)
    return report, out


def install(out: Path, target: str, scenes: Path) -> None:
    """Chép thư mục cảnh đã xuất vào dev/server/scenes. Thư mục cũ do chính công cụ này ghi thì thay."""
    folder = scenes / target
    if folder.exists():
        tsv_file.prepare_directory(folder, TOOL, ["walk.nav", "walk.path"])
    shutil.copytree(out / target, folder, dirs_exist_ok=True)


def case_conflict(dirs: set[str], targets: list[str]) -> str | None:
    seen = {name.casefold(): name for name in dirs}
    for name in targets:
        other = seen.get(name.casefold())
        if other is not None and other != name:
            return f"{name}:1: trùng tên không phân biệt hoa thường với thư mục cảnh {other}"
        seen[name.casefold()] = name
    return None


def run(server_root: Path, xjl_root: Path, client_scene: Path, check_only: bool) -> tuple[dict[str, int], list[str]]:
    groups, _client = scene_xref.build(server_root, xjl_root, client_scene)
    targets = [group.scene_dir for group in groups if scene_xref.wants_import(group)]
    existing = {group.scene_dir for group in groups if group.has_dir}
    conflict = case_conflict(existing, targets)
    if conflict is not None:
        return {}, [conflict]
    source = scene_root(xjl_root)
    kind_of = classify_dir(source)
    stems = {name[: -len(".scn")] for name, kind in kind_of.items() if kind == kinds.SCN}
    totals: Counter[str] = Counter()
    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="import_scene_xjl_") as temporary:
        for target in targets:
            report, out = import_one(source, kind_of, target, stems, Path(temporary))
            if not report.ok:
                errors.extend(f"{target}: {line}" for line in report.errors)
                continue
            totals["scenes"] += 1
            totals.update({f"rows_{key}": value for key, value in report.records.items()})
            if not check_only:
                install(out, target, server_root / "scenes")
    return dict(sorted(totals.items())), errors


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    positional = [arg for arg in args if not arg.startswith("--")]
    if len(positional) != 3:
        print("import_scene_xjl.py:1: cần ba tham số: gốc dev/server, gốc XJL7457, thư mục Scene của client")
        return 1
    totals, errors = run(Path(positional[0]), Path(positional[1]), Path(positional[2]), "--check" in args)
    for line in errors:
        print(line)
    for key, value in totals.items():
        print(f"{key} {value}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
