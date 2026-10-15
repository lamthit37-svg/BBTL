"""cfgtool — công cụ cấu hình máy chủ THIENLONG (dev/server/config).

  python TOOLS/cfgtool/cfgtool.py gui [thư mục config]          mở giao diện (PySide6)
  python TOOLS/cfgtool/cfgtool.py show <tệp>                     bảng trường: tên, chức năng, cách đặt
  python TOOLS/cfgtool/cfgtool.py check <tệp|thư mục>            kiểm theo lược đồ của bộ đọc C++
  python TOOLS/cfgtool/cfgtool.py import <tệp vào> <tệp ra>      nhập: căn chỉnh + kiểm, ghi đúng định dạng máy chủ
  python TOOLS/cfgtool/cfgtool.py export <thư mục vào> <thư mục ra>   xuất cả bộ cấu hình (bỏ *.local.toml)
  python TOOLS/cfgtool/cfgtool.py roundtrip [thư mục config] [--lint <thienlong_lint.exe>]
  python TOOLS/cfgtool/cfgtool.py doc                            in bảng mọi trường (Markdown)

Tên tệp quyết định lược đồ (auth.toml, gate.toml…); tệp trong rules/ dùng phép kiểm chung (schema = 1).
Thoát 0 khi sạch, 1 khi có lỗi, 2 khi dùng sai.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import core
import schema as S

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "dev" / "server" / "config"


def target_name(path: Path, hint: str | None = None) -> str:
    return hint or path.name


def cmd_show(path: Path) -> int:
    text, _ = core.decode(path.read_bytes())
    for r in core.describe(path.name, text):
        print(f"[{r['group']}] {r['key']} = {r['value'] or '(chưa đặt)'}")
        print(f"    kiểu: {r['kind']}" + (f"  miền: {r['range']}" if r['range'] else "") + f"  {r['required']}"
              + (f"  mặc định: {r['default']}" if r['default'] else "") + (f"  đơn vị: {r['unit']}" if r['unit'] else ""))
        print(f"    chức năng: {r['desc']}")
        if r['guide']:
            print(f"    production: {r['guide']}" + (f" (gợi ý: {r['prod']})" if r['prod'] else ""))
    return 0


def check_one(path: Path, name: str | None = None) -> int:
    text, notes = core.decode(path.read_bytes())
    issues = core.validate(name or path.name, text)
    for issue in issues:
        print(f"{path}:{issue.text()}")
    return len(issues)


def cmd_check(path: Path) -> int:
    files = core.config_files(path) if path.is_dir() else [path]
    errors = sum(check_one(p) for p in files)
    if path.is_dir():
        for issue in core.check_startup(path):
            print(f"{path / 'supervisor.toml'}:{issue.text()}")
            errors += 1
    print(f"{len(files)} tệp, {errors} lỗi")
    return 1 if errors else 0


def cmd_import(source: Path, out: Path) -> int:
    core.guard(out.name)
    text, notes = core.normalize(out.name, source.read_bytes())
    issues = core.validate(out.name, text)
    for note in notes:
        print(f"đã làm: {note}")
    for issue in issues:
        print(f"{out.name}:{issue.text()}")
    core.write_export(out, text)
    print(f"đã ghi {out} ({len(text.encode())} byte, UTF-8 không BOM, LF)" + (f"; còn {len(issues)} lỗi" if issues else "; sạch"))
    return 1 if issues else 0


def cmd_export(source: Path, out: Path) -> int:
    errors = 0
    for path in core.config_files(source):
        rel = path.relative_to(source)
        text, _ = core.normalize(path.name, path.read_bytes())
        core.write_export(out / rel, text)
        errors += len(core.validate(path.name, text))
    print(f"đã xuất {len(core.config_files(source))} tệp vào {out}; {errors} lỗi")
    return 1 if errors else 0


def run_lint(lint: Path, config: Path) -> tuple[int, str]:
    """Chạy thienlong_lint trên một gốc SERVER tạm chỉ có config (bảng và cảnh rỗng)."""
    with tempfile.TemporaryDirectory(prefix="cfgtool_rt_") as tmp:
        root = Path(tmp)
        shutil.copytree(config, root / "config", ignore=shutil.ignore_patterns("*.local.toml"))
        for name in ("tables", "scenes", "refs"):
            (root / name).mkdir()
        done = subprocess.run([str(lint), "--root", str(root), "--refs", str(root / "refs")],
                              capture_output=True, encoding="utf-8", errors="replace")
        return done.returncode, (done.stdout + done.stderr).replace(str(root), "<gốc tạm>")


def cmd_roundtrip(config: Path, lint: Path | None) -> int:
    lint = lint or config.parent / "bin" / "thienlong_lint.exe"
    failures = 0
    with tempfile.TemporaryDirectory(prefix="cfgtool_out_") as tmp:
        out = Path(tmp) / "config"
        for path in core.config_files(config):
            raw = path.read_bytes()
            text, _ = core.normalize(path.name, raw)
            data = core.write_export(out / path.relative_to(config), text)
            same = data == raw
            issues = core.validate(path.name, text)
            failures += (not same) + bool(issues)
            print(f"{'GIỐNG' if same else 'KHÁC'} byte  {'sạch' if not issues else f'{len(issues)} lỗi'}  {path.relative_to(config)}")
        if lint.is_file():
            code, report = run_lint(lint, out)
            print(f"thienlong_lint trên bản xuất: mã thoát {code}")
            print(report.strip())
            failures += code != 0
        else:
            print(f"không thấy {lint}: bỏ bước kiểm bằng bộ đọc của máy chủ")
            failures += 1
    print("ROUND-TRIP ĐẠT" if not failures else f"ROUND-TRIP HỎNG: {failures}")
    return 1 if failures else 0


def cmd_doc() -> int:
    for spec in S.FILES.values():
        print(f"\n### {spec.name}\n\nBộ đọc: `{spec.reader}`. {spec.note}\n")
        print("| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |")
        print("|---|---|---|---|---|---|")
        for g in spec.groups:
            for f in g.fields:
                where = (f"[[{g.path}]]" if g.rows else f"[{g.path}]") if g.path else "(gốc)"
                kind = S.KIND_TEXT.get(f.kind, f.kind) + (f"; {core.range_text(f)}" if core.range_text(f) else "") + (f"; đơn vị {f.unit}" if f.unit else "")
                req = "bắt buộc" if f.required and g.required else f"tuỳ chọn (mặc định {f.default})" if f.default else "tuỳ chọn"
                secret = " **Bí mật: không bao giờ hiển thị/xuất giá trị.**" if f.secret else ""
                print(f"| {where} | `{f.key}` | {kind} | {req} | {f.desc}{secret} | {f.guide} `{f.prod}` |".replace("\n", " "))
    rules = DEFAULT_CONFIG / "rules"
    print("\n## Tệp luật (config/rules/*.toml)\n")
    print("Bộ đọc: `config::read_loose` (loose.cpp) qua thienlong_lint: chỉ kiểm cú pháp TOML và `schema = 1`; "
          "khoá khác chưa có struct C++ nên không bị coi là lạ. Giá trị do mã zone/world chép vào hằng số "
          "(xem chú thích trong src/server/social/limits.hpp, item/price.hpp, account/starter.hpp). "
          "Chức năng dưới đây lấy từ chú thích trong chính tệp; \"Đơn vị chưa xác lập\" nghĩa là mã gốc chưa rõ đơn vị: "
          "giữ nguyên giá trị nếu chưa đo.")
    for path in sorted(rules.glob("*.toml")):
        text = path.read_text(encoding="utf-8")
        print(f"\n### rules/{path.name}\n")
        print("| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |")
        print("|---|---|---|---|---|")
        for r in core.describe(path.name, text):
            print(f"| {r['group']} | `{r['key']}` | `{r['value']}` | {r['kind']} | {r['desc']} |")
    return 0


def main(argv: list[str]) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 2
    cmd, rest = argv[0], argv[1:]
    try:
        if cmd == "gui":
            import gui
            return gui.run(Path(rest[0]) if rest else DEFAULT_CONFIG)
        if cmd == "show" and len(rest) == 1:
            return cmd_show(Path(rest[0]))
        if cmd == "check" and len(rest) == 1:
            return cmd_check(Path(rest[0]))
        if cmd == "import" and len(rest) == 2:
            return cmd_import(Path(rest[0]), Path(rest[1]))
        if cmd == "export" and len(rest) == 2:
            return cmd_export(Path(rest[0]), Path(rest[1]))
        if cmd == "roundtrip":
            lint = Path(rest[rest.index("--lint") + 1]) if "--lint" in rest else None
            folder = next((Path(a) for a in rest if not a.startswith("--") and (lint is None or Path(a) != lint)), DEFAULT_CONFIG)
            return cmd_roundtrip(folder, lint)
        if cmd == "doc":
            return cmd_doc()
    except core.SecretFileError as error:
        print(f"từ chối: {error}")
        return 2
    except (ValueError, OSError) as error:
        print(f"lỗi: {error}")
        return 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
