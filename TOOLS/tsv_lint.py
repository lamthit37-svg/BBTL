#!/usr/bin/env python3
"""Kiểm, sửa an toàn và xem thẳng cột các tệp TSV của dự án.

  python -B TOOLS/tsv_lint.py [đường_dẫn ...]            kiểm (mặc định: cả dự án)
  python -B TOOLS/tsv_lint.py --fix [--backup DIR] ...   sửa lỗi cấu trúc an toàn
  python -B TOOLS/tsv_lint.py --view TỆP [--rows N] [--max-width W] [--grep CHUỖI]

Sửa (--fix) CHỈ đụng tới cấu trúc, không bao giờ chèn dấu cách vào giá trị:
  bỏ BOM UTF-8, CRLF/CR -> LF, thêm LF cuối tệp, bỏ dòng trống ở cuối tệp.
  --pad-rows: thêm ô rỗng (Tab) cho dòng thiếu cột so với tiêu đề (tắt mặc định).
Ô rỗng cuối dòng có nghĩa (.editorconfig) nên Tab cuối dòng không bị cắt.
Dòng bắt đầu bằng '#' là chú thích. Mã thoát: 0 sạch, 1 còn lỗi, 2 lỗi dùng lệnh.
"""
from __future__ import annotations

import argparse
import os
import shutil
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", "vcpkg_installed", "vcpkg", "third_party", "vendor", "node_modules",
             "build", "out", ".cache", "__pycache__"}


@dataclass
class Report:
    path: Path
    issues: dict[str, list[int]] = field(default_factory=dict)
    info: dict[str, str] = field(default_factory=dict)

    def add(self, kind: str, line: int) -> None:
        self.issues.setdefault(kind, []).append(line)


def iter_tsv(paths: list[str]):
    for p in paths:
        path = Path(p)
        if path.is_file():
            yield path
            continue
        for dirpath, dirnames, filenames in os.walk(path):
            dirnames[:] = [d for d in dirnames
                           if d not in SKIP_DIRS and not d.startswith("build")]
            for name in sorted(filenames):
                if name.lower().endswith(".tsv"):
                    yield Path(dirpath) / name


def decode(raw: bytes) -> tuple[str | None, str]:
    for enc in ("utf-8",):
        try:
            return raw.decode(enc), enc
        except UnicodeDecodeError:
            pass
    return None, "không phải UTF-8"


def check(path: Path) -> Report:
    rep = Report(path)
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        rep.add("BOM UTF-8", 1)
        raw = raw[3:]
    text, enc = decode(raw)
    rep.info["encoding"] = enc
    if text is None:
        rep.add("không đọc được UTF-8", 0)
        return rep
    crlf = text.count("\r\n")
    lone_cr = text.replace("\r\n", "").count("\r")
    rep.info["eol"] = "CRLF" if crlf and crlf >= text.count("\n") - crlf else ("hỗn hợp" if crlf else "LF")
    if text and not text.endswith("\n"):
        rep.add("thiếu LF cuối tệp", text.count("\n") + 1)
    lines = text.replace("\r\n", "\n").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    header_cols = None
    headerless = False
    data = [l for l in lines if l.strip() and not l.startswith("#")]
    first_comment = next((l for l in lines if l.startswith("#")), "")
    if data:
        n0 = data[0].count("\t") + 1
        if "," in first_comment and first_comment.count(",") + 1 == n0:
            headerless = True  # tiêu đề nằm trong chú thích "# cột1, cột2, ..."
            header_cols = n0
            rep.info["columns"] = f"{n0} (tiêu đề ở chú thích)"
    skip_first = bool(data) and n0 == 1 and data[0].strip().isdigit() and len(data) > 1
    if skip_first:
        rep.info["first_line"] = "số đếm"
    trailing_blank = 0
    for no, line in enumerate(lines, 1):
        if "\r" in line:
            rep.add("CR lẻ trong dòng", no)
        if line.strip() == "":
            trailing_blank += 1
            continue
        if trailing_blank:
            rep.add("dòng trống giữa tệp", no - 1)
        trailing_blank = 0
        if line.startswith("#"):
            continue
        if skip_first:
            skip_first = False
            continue
        if line.startswith("?") and line.endswith("?") and "\t" not in line:
            rep.add("dòng giữ chỗ khôi phục (?...?)", no)
            continue
        cells = line.split("\t")
        if header_cols is None:
            header_cols = len(cells)
            rep.info["columns"] = str(header_cols)
            if len(set(cells)) != len(cells):
                rep.add("tiêu đề trùng tên cột", no)
            if "," in line and header_cols == 1:
                rep.add("có vẻ dùng dấu phẩy thay Tab", no)
            continue
        n = len(cells)
        if n < header_cols:
            rep.add("thiếu cột", no)
        elif n > header_cols:
            rep.add("thừa cột (Tab lạc trong giá trị?)", no)
        for c in cells:
            if c != c.strip(" "):
                rep.add("dấu cách đầu/cuối ô", no)
                break
        for c in cells:
            if c.count('"') % 2 == 1 or (c.startswith('"') and c.endswith('"') and len(c) > 1):
                rep.add("dấu nháy kép (TSV không có quy tắc thoát)", no)
                break
        if ";" not in line and "," in line and n == 1 and header_cols > 1:
            rep.add("dấu phẩy thay Tab", no)
        if "\\t" in line or "\\n" in line:
            rep.add("chuỗi thoát \\t/\\n trong ô (thông tin)", no)
    if lone_cr:
        rep.add("CR lẻ trong dòng", 0)
    if crlf:
        rep.add("xuống dòng CRLF", 0)
    if trailing_blank:
        rep.add("dòng trống cuối tệp", len(lines))
    _ = headerless
    rep.info["rows"] = str(len(lines))
    return rep


INFO_ONLY = {"dòng trống giữa tệp","chuỗi thoát \\t/\\n trong ô (thông tin)", "dấu nháy kép (TSV không có quy tắc thoát)",
             "dấu cách đầu/cuối ô"}


def fix(path: Path, backup: Path | None, pad: bool) -> list[str]:
    raw = path.read_bytes()
    done = []
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
        done.append("bỏ BOM")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return ["BỎ QUA: không phải UTF-8"]
    if "\r" in text:
        text = text.replace("\r\n", "\n").replace("\r", "\n")
        done.append("CRLF->LF")
    if text and not text.endswith("\n"):
        done.append("thêm LF cuối tệp")
    body = text.split("\n")
    if body and body[-1] == "":
        body.pop()
    kept = len(body)
    while body and body[-1].strip(" \t") == "":
        body.pop()
    if len(body) != kept:
        done.append("bỏ dòng trống cuối tệp")
    text = "\n".join(body) + "\n" if body else ""
    if pad:
        out, cols = [], None
        padded = 0
        for line in text.split("\n")[:-1]:
            if line.startswith("#") or not line.strip():
                out.append(line)
                continue
            n = line.count("\t") + 1
            if cols is None:
                cols = n
            elif n < cols:
                line += "\t" * (cols - n)
                padded += 1
            out.append(line)
        if padded:
            done.append(f"thêm ô rỗng cho {padded} dòng thiếu cột")
            text = "\n".join(out) + "\n"
    if done:
        if backup is not None:
            try:
                rel = path.resolve().relative_to(ROOT)
            except ValueError:
                rel = Path(path.name)
            dst = backup / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            if not dst.exists():
                shutil.copy2(path, dst)
        path.write_bytes(text.encode("utf-8"))
    return done


def width(s: str) -> int:
    w = 0
    for ch in s:
        if unicodedata.combining(ch):
            continue
        w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return w


def clip(s: str, limit: int) -> str:
    if width(s) <= limit:
        return s
    out, w = "", 0
    for ch in s:
        cw = width(ch)
        if w + cw > limit - 1:
            break
        out += ch
        w += cw
    return out + "…"


def view(path: Path, rows: int, max_width: int, grep: str | None) -> None:
    text = path.read_bytes().decode("utf-8-sig", errors="replace").replace("\r\n", "\n")
    lines = text.split("\n")
    table = [l.split("\t") for l in lines if l and not l.startswith("#")]
    first_comment = next((l for l in lines if l.startswith("#")), "")
    if table and "," in first_comment and first_comment.count(",") + 1 == len(table[0]):
        table.insert(0, [c.strip() for c in first_comment.lstrip("# ").split(",")])
    if grep:
        table = table[:1] + [r for r in table[1:] if any(grep in c for c in r)]
    table = table[: rows + 1] if rows > 0 else table
    if not table:
        return
    ncol = max(len(r) for r in table)
    shown = [[clip(c.replace("\t", "→"), max_width) for c in r] + [""] * (ncol - len(r)) for r in table]
    widths = [max(width(r[i]) for r in shown) for i in range(ncol)]
    sep = "─┼─".join("─" * w for w in widths)
    for i, r in enumerate(shown):
        print(" │ ".join(c + " " * (widths[j] - width(c)) for j, c in enumerate(r)).rstrip())
        if i == 0:
            print(sep)


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--fix", action="store_true")
    g.add_argument("--view", action="store_true")
    ap.add_argument("--pad-rows", action="store_true")
    ap.add_argument("--backup", default=str(ROOT / "build" / "tsv_fix_backup"))
    ap.add_argument("--exclude", action="append", default=[], help="đường dẫn (tương đối gốc) bỏ qua khi --fix")
    ap.add_argument("--rows", type=int, default=50)
    ap.add_argument("--max-width", type=int, default=40)
    ap.add_argument("--grep")
    ap.add_argument("--quiet", action="store_true", help="chỉ in tệp có lỗi")
    a = ap.parse_args()
    if a.view:
        if len(a.paths) != 1:
            ap.error("--view cần đúng một tệp")
        view(Path(a.paths[0]), a.rows, a.max_width, a.grep)
        return 0
    paths = a.paths or [str(ROOT)]
    excl = {(ROOT / e).resolve() for e in a.exclude}
    bad = 0
    total = 0
    for p in iter_tsv(paths):
        total += 1
        if a.fix:
            if p.resolve() in excl:
                continue
            done = fix(p, Path(a.backup), a.pad_rows)
            if done:
                print(f"{p}: {', '.join(done)}")
            continue
        rep = check(p)
        errs = {k: v for k, v in rep.issues.items() if k not in INFO_ONLY}
        if errs:
            bad += 1
        if rep.issues or not a.quiet:
            meta = ", ".join(f"{k}={v}" for k, v in rep.info.items())
            print(f"{p} [{meta}]")
            for k, v in rep.issues.items():
                ls = ", ".join(str(x) for x in v[:8]) + (" …" if len(v) > 8 else "")
                print(f"    {k}: {len(v)} (dòng {ls})")
    if not a.fix:
        print(f"Tổng: {total} tệp, {bad} tệp có lỗi cấu trúc")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
