"""Số đo mã của TOOLS/server: độ dài hàm, độ lồng, except rộng, hàm thiếu type hint, chuỗi đường dẫn tuyệt đối."""
import ast
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parents[4] / "TOOLS" / "server"
NEST = (ast.If, ast.For, ast.While, ast.Try, ast.With, ast.Match)
OLD = {"config_style.py", "lint_config.py", "setup_db.py"}


def depth(node, level=0):
    deepest = level
    for child in ast.iter_child_nodes(node):
        if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)):
            continue
        step = level + 1 if isinstance(child, NEST) else level
        # elif nằm trong orelse của If: không tính thêm mức
        if isinstance(node, ast.If) and child in node.orelse and isinstance(child, ast.If):
            step = level
        deepest = max(deepest, depth(child, step))
    return deepest


for path in sorted(ROOT.glob("*.py")):
    if path.name in OLD:
        continue
    text = path.read_text(encoding="utf-8")
    tree = ast.parse(text)
    functions = [node for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))]
    lengths = sorted(((node.end_lineno - node.lineno + 1, node.name, node.lineno) for node in functions), reverse=True)
    depths = sorted(((depth(node), node.name, node.lineno) for node in functions), reverse=True)
    broad = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ExceptHandler):
            kind = ast.unparse(node.type) if node.type else "TRẦN"
            swallow = all(isinstance(item, (ast.Pass, ast.Continue)) for item in node.body)
            if kind in ("TRẦN", "Exception", "BaseException") or swallow:
                broad.append((node.lineno, kind, "nuốt" if swallow else ""))
    untyped = [node.name for node in functions if node.returns is None and not node.name.startswith("test") and node.name not in ("setUp", "tearDown", "setUpClass", "tearDownClass")]
    absolute = [index + 1 for index, line in enumerate(text.split("\n")) if re.search(r"[\"'][A-Za-z]:[\\/]|Desktop|tl 2026", line)]
    long_lines = sum(1 for line in text.split("\n") if len(line) > 110)
    over40 = [item for item in lengths if item[0] > 40]
    deep = [item for item in depths if item[0] > 2]
    print(f"{path.name}: {len(text.splitlines())} dòng, {len(functions)} hàm; >40 dòng: {len(over40)} {over40[:4]}; lồng >2: {len(deep)} {deep[:4]}")
    print(f"    except rộng/nuốt: {broad[:6]}; thiếu kiểu trả: {len(untyped)} {untyped[:5]}; dòng có đường dẫn tuyệt đối: {absolute[:5]}; dòng >110 cột: {long_lines}")
