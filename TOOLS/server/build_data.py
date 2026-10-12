"""Sinh lại toàn bộ bảng và cảnh của máy chủ từ một lệnh.

cách dùng: python TOOLS/server/build_data.py --legacy <tlbb> --raw <_raw> [--dest <gốc>] [--check] [--digest]

Gọi table_census, export_tables, import_legacy, export_scene, import_rules và
scene_refs, rồi lint_names và diff_tables --check. --dest chọn gốc chứa tables,
scenes và config/rules; mặc định là dev/server của dự án. --check kiểm hết và không
ghi tệp nào. --digest in SHA-256 của tables và scenes. Thoát 0 khi sạch, 1 khi có lỗi.
"""
from __future__ import annotations

import hashlib
import sys
from collections.abc import Iterable
from pathlib import Path
from typing import NamedTuple

import diff_tables
import export_scene
import export_tables
import import_legacy
import import_rules
import lint_names
import scene_refs
import table_census
import tsv_file

HELP = """\
cách dùng: python TOOLS/server/build_data.py --legacy <tlbb> --raw <_raw> [--dest <gốc>] [--check] [--digest]

Sinh lại tables, scenes và config/rules dưới gốc đích. Mặc định gốc là dev/server.
--dest chọn gốc khác để test ghi vào build. --check kiểm hết và không ghi tệp nào.
Sau khi sinh thì in tổng kết lint_names và diff_tables --check.
--digest in một mã SHA-256 của tables và scenes. Thoát 0 khi sạch, 1 khi có lỗi.
"""
PROJECT = Path(__file__).resolve().parents[2]


class _Layout(NamedTuple):
    tables: Path
    scenes: Path
    census: Path | None
    shared_columns: Path | None
    server_columns: Path | None
    scene_columns: Path | None


def _fail(message: str) -> int:
    print(f"build_data.py:1: {message}")
    return 1


def _take_value(arguments: list[str], index: int, name: str) -> tuple[int, str]:
    nxt = index + 1
    if nxt >= len(arguments):
        raise ValueError(f"thiếu giá trị {name}")
    return nxt, arguments[nxt]


def _store(arg: str, value: str, legacy: str, raw: str, dest: Path) -> tuple[str, str, Path]:
    if arg == "--legacy":
        return value, raw, dest
    if arg == "--raw":
        return legacy, value, dest
    return legacy, raw, Path(value)


def _parse(arguments: list[str]) -> tuple[str, str, Path, bool, bool]:
    legacy = ""
    raw = ""
    dest = PROJECT / "dev" / "server"
    check = False
    digest = False
    index = 0
    while index < len(arguments):
        arg = arguments[index]
        if arg == "--check":
            check = True
        elif arg == "--digest":
            digest = True
        elif arg in ("--legacy", "--raw", "--dest"):
            index, value = _take_value(arguments, index, arg)
            legacy, raw, dest = _store(arg, value, legacy, raw, dest)
        else:
            raise ValueError(f"không rõ đối số: {arg}")
        index += 1
    if not legacy or not raw:
        raise ValueError("cần --legacy và --raw")
    return legacy, raw, dest, check, digest


def _records(path: Path) -> int:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf") or b"\r" in data:
        raise ValueError(f"{path.name}:1: bảng không đúng hợp đồng")
    text = data.decode("utf-8")
    body = [line for line in text.split("\n") if line and not line.startswith("#")]
    if not body:
        raise ValueError(f"{path.name}:1: bảng không có dòng tên cột")
    return len(body) - 1


def _tally(directory: Path) -> tuple[int, int]:
    if not directory.exists():
        return 0, 0
    files = 0
    records = 0
    for path in sorted(directory.rglob("*")):
        if not path.is_file():
            continue
        files += 1
        if path.suffix == ".tsv":
            records += _records(path)
    return files, records


def _print_rollup(dest: Path) -> None:
    tables = dest / "tables"
    pairs = (
        ("tables/server", tables / "server"),
        ("tables/shared", tables / "shared"),
        ("tables/variants", tables / "variants"),
        ("scenes", dest / "scenes"),
        ("config/rules", dest / "config" / "rules"),
    )
    for label, directory in pairs:
        files, records = _tally(directory)
        print(f"{label}: {files} tệp, {records} bản ghi")


def _relative(path: Path) -> str:
    return path.relative_to(PROJECT).as_posix()


def tree_digest(roots: Iterable[Path | str]) -> str:
    """SHA-256 của nội dung và đường dẫn tương đối, theo thứ tự đường dẫn."""
    files: list[Path] = []
    for root in roots:
        folder = Path(root)
        if folder.exists():
            files.extend(path for path in folder.rglob("*") if path.is_file())
    hasher = hashlib.sha256()
    for path in sorted(files, key=_relative):
        hasher.update(_relative(path).encode())
        hasher.update(b"\0")
        hasher.update(path.read_bytes())
        hasher.update(b"\0")
    return hasher.hexdigest()


def _column(root: Path | None, name: str) -> Path | None:
    if root is None:
        return None
    return root / name


def _layout(dest: Path) -> _Layout:
    redirect = dest.resolve() != (PROJECT / "dev" / "server").resolve()
    columns = dest / "columns" if redirect else None
    census = dest / "table_census.tsv" if redirect else None
    return _Layout(
        dest / "tables",
        dest / "scenes",
        census,
        _column(columns, "shared"),
        _column(columns, "server"),
        _column(columns, "scenes"),
    )


def _flag(check: bool) -> list[str]:
    if check:
        return ["--check"]
    return []


def _run_census(raw: str, check: bool, output: Path | None) -> int:
    args = [raw, *_flag(check)]
    if output is not None:
        args.extend(["--output", str(output)])
    return table_census.main(args)


def _run_tables(raw: str, legacy: str, tables: Path, check: bool, columns: Path | None) -> int:
    args = [raw, legacy, str(tables), *_flag(check)]
    if columns is not None:
        args.extend(["--columns", str(columns)])
    return export_tables.main(args)


def _print_lines(lines: list[str]) -> None:
    for line in lines:
        print(line)


def _run_legacy(legacy: str, output: Path, check: bool, columns: Path | None) -> int:
    if columns is None:
        return import_legacy.main([legacy, str(output), *_flag(check)])
    errors, summary = import_legacy.export_legacy(
        Path(legacy),
        output,
        tsv_file.read_name_map(),
        check_only=check,
        column_dir=columns,
        include_script_index=True,
    )
    _print_lines(errors)
    if errors:
        return 1
    _print_lines(summary)
    return 0


def _print_pairs(title: str, pairs: dict[str, int]) -> None:
    print(title)
    for name, count in pairs.items():
        print(f"  {name} {count}")


def _print_scene(report: export_scene.Report) -> None:
    _print_lines(report.errors)
    _print_lines(report.int_places)
    if not report.show_summary:
        return
    print(f"cảnh: {report.scene_count}")
    print(f"cảnh không scn: {report.orphan_scene_count}")
    _print_pairs("tệp nguồn:", report.kinds)
    _print_pairs("bản ghi:", report.records)
    _print_pairs("biến đổi:", report.changes)


def _run_scenes(legacy: str, output: Path, check: bool, columns: Path | None) -> int:
    if columns is None:
        return export_scene.main([legacy, str(output), *_flag(check)])
    report = export_scene.export_scenes(Path(legacy), output, columns, check)
    _print_scene(report)
    if report.ok:
        return 0
    return 1


def _run_rules(legacy: str, output: Path, check: bool) -> int:
    return import_rules.main([legacy, str(output), *_flag(check)])


def _run_refs(legacy: str, output: Path, check: bool) -> int:
    return scene_refs.main([legacy, str(output), *_flag(check)])


def _run_steps(legacy: str, raw: str, dest: Path, check: bool) -> int:
    layout = _layout(dest)
    server_tables = layout.tables / "server"
    if _run_census(raw, check, layout.census) != 0:
        return 1
    if _run_tables(raw, legacy, layout.tables, check, layout.shared_columns) != 0:
        return 1
    if _run_legacy(legacy, server_tables, check, layout.server_columns) != 0:
        return 1
    if _run_scenes(legacy, layout.scenes, check, layout.scene_columns) != 0:
        return 1
    if _run_rules(legacy, dest / "config" / "rules", check) != 0:
        return 1
    return _run_refs(legacy, server_tables, check)


def _run_gates(legacy: str, dest: Path) -> int:
    """Tổng kết cổng tên và độ phủ. Lỗi của một cổng thì dừng."""
    print("lint_names:")
    if lint_names.main(["--stats"]) != 0:
        return 1
    print("diff_tables:")
    return diff_tables.main([legacy, str(dest), "--check"])


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def main(argv: list[str] | None = None) -> int:
    """Sinh cây dữ liệu. --check không ghi. --digest in mã của hai cây."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        legacy, raw, dest, check, digest = _parse(arguments)
    except ValueError as exc:
        return _fail(str(exc))
    if _run_steps(legacy, raw, dest, check) != 0:
        return 1
    if check:
        print("không ghi tệp")
    try:
        _print_rollup(dest)
    except ValueError as exc:
        return _fail(str(exc))
    if _run_gates(legacy, dest) != 0:
        return 1
    if digest:
        print(f"sha256: {tree_digest([dest / 'tables', dest / 'scenes'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
