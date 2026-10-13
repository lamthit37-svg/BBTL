# Rút trường của gói tin từ bản decompile Game.exe do decompile.bat sinh với khoá v:Packets::<tên>.
# Mỗi gói có hàm "Read" (gọi FUN_1406e7f60(luồng, đích, cỡ) cho từng trường); script giữ lại các
# lệnh đọc trường, điều kiện và vòng lặp theo thứ tự, bỏ phần còn lại. Địa chỉ trong ngoặc là độ dời
# của trường trong đối tượng gói của client (không phải vị trí trên dây): thứ tự dòng là thứ tự trên
# dây. Chạy ở gốc dự án:
#   python -B TOOLS/port/ghidra/packet_fields.py <tệp decompile> <tệp markdown ra>
import re
import sys
from pathlib import Path

READ_CALL = "FUN_1406e7f60(param_2"
KEPT = re.compile(r"FUN_1406e7f60\(|^\s*(if|for|while|do|else)\b|^\s*}\s*$|^\s*\w+ = \*\(|rand\(")
FIELD = re.compile(r"FUN_1406e7f60\(param_2,\s*(param_1(?: \+ (?:0x)?[0-9a-fA-F]+)?|[^,]+),\s*(.+?)\);")


def blocks(text: str) -> dict[str, str]:
    """Nhóm 'v:<lớp>' -> văn bản của nhóm đó."""
    result: dict[str, str] = {}
    parts = re.split(r"^######## ", text, flags=re.M)
    for part in parts[1:]:
        head, _, body = part.partition("\n")
        result[head.strip()] = body
    return result


def functions(body: str) -> list[tuple[str, str]]:
    """Danh sách (tiêu đề, thân) của các hàm trong một nhóm."""
    chunks = re.split(r"^==== ", body, flags=re.M)
    found = []
    for chunk in chunks[1:]:
        head, _, rest = chunk.partition("\n")
        found.append((head.strip(), rest))
    return found


def condensed(rest: str) -> list[str]:
    lines = []
    for line in rest.split("\n"):
        stripped = line.strip()
        if not stripped or stripped.startswith(("/*", "//", "undefined", "longlong", "int ", "uint", "char ")):
            continue
        if READ_CALL in line:
            match = FIELD.search(line)
            if match:
                indent = " " * (len(line) - len(line.lstrip()))
                lines.append(f"{indent}đọc {match.group(1).replace('param_1', 'gói')} cỡ {match.group(2)}")
                continue
        if KEPT.search(line):
            lines.append(line.rstrip())
    return lines


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    source = Path(sys.argv[1]).read_text(encoding="utf-8")
    out = ["# Trường của gói tin đăng nhập (suy từ hàm Read trong Game.exe)\n",
           "Sinh bằng `TOOLS/port/ghidra/packet_fields.py` từ `TAILIEU/ghidra/login_packets.txt`.\n"]
    for name, body in blocks(source).items():
        if not name.startswith("v:"):
            continue
        reads = [(head, rest) for head, rest in functions(body) if READ_CALL in rest]
        out.append(f"\n## {name[2:]}\n")
        if not reads:
            out.append("Không có hàm đọc trường (gói rỗng hoặc chỉ mang kiểu).\n")
            continue
        head, rest = max(reads, key=lambda item: item[1].count(READ_CALL))
        out.append(f"Hàm Read: `{head}`\n\n```\n" + "\n".join(condensed(rest)) + "\n```\n")
    Path(sys.argv[2]).write_text("\n".join(out), encoding="utf-8", newline=chr(10))
    print("ok", sys.argv[2])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
