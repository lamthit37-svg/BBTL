"""Cổng kiểm mã Python trong TOOLS/server.

cách dùng: python TOOLS/server/lint_py.py [tệp...]
Không tham số thì kiểm mọi TOOLS/server/*.py. Thoát 0 khi sạch, 1 khi có lỗi.
Mỗi lỗi một dòng tệp:dòng: nội dung. Luật G1 tới G6 ở đề bài P1 đợt 2.
"""
from __future__ import annotations

import ast
import re
import sys
from pathlib import Path

HELP = """\
cách dùng: python TOOLS/server/lint_py.py [tệp...]

Kiểm hàm tối đa 50 dòng, lồng tối đa 3 mức, dòng tối đa 120 ký tự,
kiểu tham số và kiểu trả, except không nuốt lỗi, và chuỗi đường dẫn ổ đĩa.
Không tham số thì kiểm mọi TOOLS/server/*.py. Thoát 0 khi sạch, 1 khi có lỗi.
"""
PROJECT = Path(__file__).resolve().parents[2]
_NEST = (ast.If, ast.For, ast.While, ast.Try, ast.With, ast.Match)
_SKIP = (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)
_BROAD = frozenset({"Exception", "BaseException"})
_DRIVE = re.compile("(?<![A-Za-z])[A-Za-z]:" + r"[/\\]")
_FUNCS = (ast.FunctionDef, ast.AsyncFunctionDef)


def _display(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(PROJECT).as_posix()
    except ValueError:
        return resolved.as_posix()


def _default_paths() -> list[Path]:
    folder = Path(__file__).resolve().parent
    return sorted(path for path in folder.glob("*.py") if path.is_file())


def _step(node: ast.AST, child: ast.AST, level: int) -> int:
    if isinstance(node, ast.If) and isinstance(child, ast.If) and child in node.orelse:
        return level
    if isinstance(child, _NEST):
        return level + 1
    return level


def _depth(node: ast.AST, level: int) -> int:
    deepest = level
    for child in ast.iter_child_nodes(node):
        if isinstance(child, _SKIP):
            continue
        found = _depth(child, _step(node, child, level))
        if found > deepest:
            deepest = found
    return deepest


def _untyped(node: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    args = node.args
    slots = [*args.posonlyargs, *args.args, *args.kwonlyargs]
    if args.vararg is not None:
        slots.append(args.vararg)
    if args.kwarg is not None:
        slots.append(args.kwarg)
    missing = []
    for arg in slots:
        if arg.arg in ("self", "cls"):
            continue
        if arg.annotation is None:
            missing.append(arg.arg)
    return missing


def _type_errors(display: str, node: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    errors = []
    for name in _untyped(node):
        errors.append(f"{display}:{node.lineno}: hàm {node.name} thiếu kiểu của tham số {name}")
    if node.returns is None:
        errors.append(f"{display}:{node.lineno}: hàm {node.name} thiếu kiểu trả")
    return errors


def _one_function(display: str, node: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    errors = []
    length = 1 if node.end_lineno is None else node.end_lineno - node.lineno + 1
    if length > 50:
        errors.append(f"{display}:{node.lineno}: hàm {node.name} dài {length} dòng, quá 50")
    nest = _depth(node, 0)
    if nest > 3:
        errors.append(f"{display}:{node.lineno}: hàm {node.name} lồng {nest} mức, quá 3")
    errors.extend(_type_errors(display, node))
    return errors


def _function_errors(display: str, tree: ast.AST) -> list[str]:
    errors = []
    for node in ast.walk(tree):
        if isinstance(node, _FUNCS):
            errors.extend(_one_function(display, node))
    return errors


def _line_errors(display: str, text: str) -> list[str]:
    errors = []
    for number, line in enumerate(text.split("\n"), start=1):
        if len(line) > 120:
            errors.append(f"{display}:{number}: dòng dài {len(line)} ký tự, quá 120")
    return errors


def _has_raise(node: ast.AST) -> bool:
    if isinstance(node, _SKIP):
        return False
    if isinstance(node, ast.Raise):
        return True
    for child in ast.iter_child_nodes(node):
        if _has_raise(child):
            return True
    return False


def _one_except(display: str, node: ast.ExceptHandler) -> list[str]:
    if node.type is None:
        return [f"{display}:{node.lineno}: except trần"]
    kind = ast.unparse(node.type)
    if kind in _BROAD and not _has_raise(node):
        return [f"{display}:{node.lineno}: except {kind} không raise lại"]
    return []


def _except_errors(display: str, tree: ast.AST) -> list[str]:
    errors = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ExceptHandler):
            errors.extend(_one_except(display, node))
    return errors


def _path_errors(display: str, tree: ast.AST) -> list[str]:
    errors = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Constant) or not isinstance(node.value, str):
            continue
        if _DRIVE.search(node.value):
            line = node.lineno or 1
            errors.append(f"{display}:{line}: chuỗi có đường dẫn ổ đĩa Windows")
    return errors


def _syntax(path: Path, exc: SyntaxError) -> str:
    line = exc.lineno if isinstance(exc.lineno, int) else 1
    return f"{_display(path)}:{line}: không phân tích được"


def _read(path: Path) -> tuple[str | None, list[str]]:
    display = _display(path)
    try:
        return path.read_text(encoding="utf-8"), []
    except UnicodeError:
        return None, [f"{display}:1: không phải UTF-8"]
    except OSError:
        return None, [f"{display}:1: không đọc được"]


def _check_file(path: Path) -> list[str]:
    """Các lỗi của một tệp. Tệp sạch thì danh sách rỗng."""
    if not path.is_file():
        return [f"{_display(path)}:1: không phải tệp"]
    text, failed = _read(path)
    if text is None:
        return failed
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        return [_syntax(path, exc)]
    display = _display(path)
    errors = _line_errors(display, text)
    errors.extend(_function_errors(display, tree))
    errors.extend(_except_errors(display, tree))
    errors.extend(_path_errors(display, tree))
    return errors


def _arguments(arguments: list[str]) -> list[Path]:
    if not arguments:
        return _default_paths()
    paths = []
    for arg in arguments:
        if arg.startswith("-"):
            raise ValueError(f"không rõ đối số: {arg}")
        paths.append(Path(arg))
    return paths


def _check_all(paths: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in paths:
        errors.extend(_check_file(path))
    return errors


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def main(argv: list[str] | None = None) -> int:
    """Kiểm các tệp. In từng lỗi và trả 1 khi còn lỗi."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        paths = _arguments(arguments)
    except ValueError as exc:
        print(f"lint_py.py:1: {exc}")
        return 1
    errors = _check_all(paths)
    for error in errors:
        print(error)
    if errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
