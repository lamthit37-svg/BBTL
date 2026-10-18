# Đưa script giao diện gốc (src/client/script) vào dữ liệu client (dev/client/assets/Script) cho phần chủ của giao diện
# Lua (ui/script) đọc lúc chạy: sổ cửa sổ windows.tsv và đúng các script mà sổ nêu (client gốc chỉ nạp script có
# trong sổ; tệp .lua khác của gói không chạy). Bố cục giữ đường dẫn trong gói: Script/Interface/<cửa sổ>/<tên>.lua.
# Ghi Script/script.files.tsv ("kind<tab>đường dẫn", như danh sách của collect_map) để android/package_apk.py đóng
# vào APK; iOS dùng cùng danh sách.
# Cùng đợt chép thêm dữ liệu nhiệm vụ: Config/Script.dat (id script sang tệp, unpack_script_index.py) và mọi
# Config/event/**/*.lua (khối MisDesc của từng nhiệm vụ, quest::DefBook nạp trễ theo bảng này), cũng dưới Script/Config/.
# Chữ giữ nguyên byte UTF-8 của bản trong repo (chế độ chuỗi kUtf8 của TANG-C.md mục 4; bản zh đổi GBK là bước sau).
# Tệp không đổi thì không ghi lại; tệp do lượt trước đưa vào mà sổ nay không nêu thì xoá (chỉ trong Script/, chỉ tệp
# có trong danh sách cũ). Tên trong sổ tra không phân biệt hoa thường; tệp đích mang tên đúng như trên đĩa nguồn.
# Mã thoát: 0 khi xong, 1 khi sổ hỏng hay nêu script không có, 2 khi sai cách dùng.
# --stamp: tệp mốc chỉ ghi lại khi có tệp đích đổi (hay mốc chưa có), để bước đóng APK khai làm đầu vào và đóng lại ngay
# trong lượt dựng vừa đổi script (Ninja xét ngày tệp trước khi bước này chạy, như mốc của build_i18n.py).
# Chạy ở gốc dự án (CMake chạy ở mỗi lượt dựng client, target thienlong_scripts):
#   python -B TOOLS/content/stage_scripts.py src/client/script dev/client/assets [--stamp build/scripts/staged.stamp]
from __future__ import annotations

import argparse
import contextlib
import sys
from pathlib import Path

FOLDER = "Script"
REGISTRY = "windows.tsv"
LISTING = "script.files.tsv"
SCRIPT_COLUMN = "script"
QUEST_INDEX = "Config/Script.dat"
QUEST_FOLDER = "Config/event"


class StageError(Exception):
    """Sổ cửa sổ hỏng, script sổ nêu không có, hay không ghi được tệp đích."""


def registry_scripts(text: str) -> list[str]:
    """Đường dẫn script (dưới Interface/) của từng dòng sổ, theo thứ tự sổ, không lặp."""
    lines = [line for line in text.split("\n") if line and not line.startswith("#")]
    if not lines:
        raise StageError(f"{REGISTRY}: không có dòng tên cột")
    header = lines[0].split("\t")
    if SCRIPT_COLUMN not in header:
        raise StageError(f"{REGISTRY}: thiếu cột {SCRIPT_COLUMN}")
    at = header.index(SCRIPT_COLUMN)
    scripts: list[str] = []
    seen: set[str] = set()
    for number, line in enumerate(lines[1:], start=1):
        cells = line.split("\t")
        if len(cells) != len(header):
            raise StageError(f"{REGISTRY}: dòng dữ liệu {number} có {len(cells)} ô, cần {len(header)}")
        path = cells[at].replace("\\", "/")
        if path.startswith("/") or ".." in path.split("/") or not path.lower().endswith(".lua"):
            raise StageError(f"{REGISTRY}: dòng dữ liệu {number}: đường dẫn script lạ \"{path}\"")
        if path.lower() not in seen:
            seen.add(path.lower())
            scripts.append(path)
    return scripts


def write_changed(path: Path, content: bytes) -> bool:
    """Ghi qua tệp tạm rồi đổi tên; False khi tệp đã mang đúng nội dung."""
    if path.is_file() and path.read_bytes() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    spare = path.with_name(path.name + ".tmp")
    try:
        spare.write_bytes(content)
        spare.replace(path)
    except OSError:
        with contextlib.suppress(OSError):
            spare.unlink(missing_ok=True)
        raise
    return True


def old_listing(path: Path) -> list[str]:
    if not path.is_file():
        return []
    rows = [line.split("\t") for line in path.read_text(encoding="utf-8").splitlines() if line and not line.startswith("kind\t")]
    return [row[1] for row in rows if len(row) == 2]


def quest_files(source: Path) -> list[tuple[str, Path]]:
    """Script.dat và các script event của nhiệm vụ, theo (đường dẫn dưới dữ liệu client, tệp nguồn)."""
    index = source / QUEST_INDEX
    if not index.is_file():
        raise StageError(f"thiếu {index}; chạy TOOLS/content/unpack_script_index.py")
    found = [(f"{FOLDER}/{QUEST_INDEX}", index)]
    for path in sorted((source / QUEST_FOLDER).rglob("*.lua")):
        found.append((f"{FOLDER}/{path.relative_to(source).as_posix()}", path))
    return found


def stage(source: Path, data: Path) -> tuple[int, int, int]:
    """Trả (số tệp, số tệp ghi mới, số tệp cũ đã xoá)."""
    registry = source / REGISTRY
    try:
        text = registry.read_bytes().decode("utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise StageError(f"không đọc được {registry}: {error}") from error
    on_disk = {path.relative_to(source).as_posix().lower(): path for path in (source / "Interface").rglob("*.lua")}
    wanted: list[tuple[str, Path]] = [(f"{FOLDER}/{REGISTRY}", registry)]
    missing = []
    for script in registry_scripts(text):
        found = on_disk.get(f"interface/{script}".lower())
        if found is None:
            missing.append(script)
        else:
            wanted.append((f"{FOLDER}/{found.relative_to(source).as_posix()}", found))
    if missing:
        raise StageError(f"{len(missing)} script sổ nêu không có trong {source / 'Interface'}, đầu tiên: {missing[0]}")
    wanted.extend(quest_files(source))
    target = data / FOLDER
    listing = target / LISTING
    written = 0
    try:
        for relative, origin in wanted:
            written += write_changed(data / relative, origin.read_bytes())
        keep = {relative.lower() for relative, _ in wanted}
        removed = 0
        for relative in old_listing(listing):
            path = data / relative
            if relative.lower() not in keep and relative.startswith(f"{FOLDER}/") and ".." not in relative.split("/"):
                with contextlib.suppress(FileNotFoundError):
                    path.unlink()
                    removed += 1
        lines = ["kind\tpath"] + [f"{'script' if relative.endswith('.lua') else 'table'}\t{relative}" for relative, _ in wanted]
        written += write_changed(listing, ("\n".join(lines) + "\n").encode("utf-8"))
    except OSError as error:
        raise StageError(f"không ghi được dưới {target}: {error}") from error
    return len(wanted), written, removed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Đưa script giao diện và sổ cửa sổ vào dữ liệu client.")
    parser.add_argument("source", type=Path, help="thư mục script trong repo (src/client/script)")
    parser.add_argument("data", type=Path, help="thư mục dữ liệu client (dev/client/assets)")
    parser.add_argument("--stamp", type=Path, help="tệp mốc, ghi lại khi bản trong dữ liệu client đổi")
    args = parser.parse_args(argv)
    try:
        count, written, removed = stage(args.source, args.data)
        if args.stamp is not None and (written or removed or not args.stamp.is_file()):
            args.stamp.parent.mkdir(parents=True, exist_ok=True)
            args.stamp.write_bytes(b"")
    except OSError as error:
        print(f"LỖI không ghi được mốc {args.stamp}: {error}", file=sys.stderr)
        return 1
    except StageError as error:
        print(f"LỖI {error}", file=sys.stderr)
        return 1
    print(f"script: {count} tệp trong {args.data / FOLDER}, ghi mới {written}, xoá {removed}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
