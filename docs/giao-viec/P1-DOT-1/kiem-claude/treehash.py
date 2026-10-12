"""Băm từng cây đầu ra: số tệp, tổng byte, SHA-256 của (đường dẫn tương đối, byte) theo thứ tự tên."""
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
for name in ("dev/server/tables/shared", "dev/server/tables/variants", "dev/server/tables/server", "dev/server/scenes", "TOOLS/server/columns"):
    digest = hashlib.sha256()
    count = size = 0
    for path in sorted((ROOT / name).rglob("*")):
        if not path.is_file():
            continue
        data = path.read_bytes()
        digest.update(path.relative_to(ROOT).as_posix().encode("utf-8") + b"\0" + data)
        count += 1
        size += len(data)
    print(f"{name}: {count} tệp, {size} byte, {digest.hexdigest()[:16]}")
sys.stdout.flush()
