# Chép script hạt đã nấu (nhỏ hơn bản gốc 48 MB) và chỉ các .ttex mà script gọi.
# Nguồn: G:\TLBB\_content\cooked. Đích: CLIENT/data/effect.
from __future__ import annotations

import re
import shutil
from pathlib import Path

COOKED = Path(r"G:\TLBB\_content\cooked")
DEST = Path(__file__).resolve().parents[2] / "CLIENT" / "data" / "effect"


def texture_after(blob: bytes, name: str) -> str | None:
    key = name.encode("utf-8") + b"\x00"
    at = blob.find(key)
    while at >= 0:
        window = blob[at : at + 1200]
        mark = window.find(b"material/")
        end = window.find(b".ttex", mark) if mark >= 0 else -1
        if mark >= 0 and end >= 0:
            return window[mark : end + len(b".ttex")].decode("utf-8", "replace")
        at = blob.find(key, at + len(key))
    return None


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    tex = DEST / "tex"
    tex.mkdir(exist_ok=True)
    for name in ("all.particle", "all.effect"):
        shutil.copyfile(COOKED / "effect" / name, DEST / name)
    particles = (COOKED / "effect" / "all.particle").read_text(encoding="utf-8")
    names = set(re.findall(r"(?m)^\s*material\s+(\S+)", particles))
    clean = {}
    table = (COOKED / "materials.tsv").read_text(encoding="utf-8")
    for line in table.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            clean[parts[0]] = parts[1]
    blob = (COOKED / "material" / "all.tlmat").read_bytes()
    copied = 0
    missing = 0
    for name in sorted(names):
        relative = texture_after(blob, clean.get(name, name))
        if relative is None:
            missing += 1
            continue
        source = COOKED / relative
        if not source.is_file():
            missing += 1
            continue
        destination = tex / f"{name}.ttex"
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        copied += 1
    print(f"effect: {copied} ảnh, thiếu {missing}, script {len(names)} material")


if __name__ == "__main__":
    main()

