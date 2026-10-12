"""Chạy T3 rồi hai lần T4. Ghi log UTF-8, không in Account.txt."""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
LEGACY = os.environ["THIENLONG_LEGACY_ROOT"]
RAW = os.environ["THIENLONG_RAW_ROOT"]


def run(name: str, extra: list[str]) -> int:
    log = OUT / f"{name}.txt"
    completed = subprocess.run(
        [
            sys.executable,
            "-W",
            "error",
            "TOOLS/server/build_data.py",
            "--legacy",
            LEGACY,
            "--raw",
            RAW,
            *extra,
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    text = completed.stdout + completed.stderr
    log.write_text(text, encoding="utf-8")
    tail = "\n".join(text.splitlines()[-25:])
    print(f"## {name} exit {completed.returncode}")
    print(tail)
    print()
    return completed.returncode


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    codes = [
        run("t3", []),
        run("t4-a", ["--digest"]),
        run("t4-b", ["--digest"]),
    ]
    return 0 if codes == [0, 0, 0] else 1


if __name__ == "__main__":
    sys.exit(main())
