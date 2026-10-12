"""Bố cục chung của tệp TOML trong dev/server/config, theo mẫu chủ dự án đưa ngày 2026-10-06.

    #==================================================
    # TIÊU ĐỀ TỆP VIẾT IN HOA
    #==================================================
    # Vài dòng nói tệp này của ai, để làm gì.

    #==================================================
    # Tên nhóm cài đặt
    #==================================================
    [bảng]
    khoá_ngắn = 1          # chú thích tiếng Việt ngang hàng
    khoá_dài  = "giá trị"  # dấu = và dấu # thẳng cột trong nhóm

- Mỗi nhóm (các khoá gốc, hoặc một bảng [x] hay [[x]]) mở đầu bằng một khung tiêu đề; các nhóm cách
  nhau một dòng trống; các cài đặt trong nhóm nằm sát nhau.
- Mỗi cài đặt có chú thích tiếng Việt ngang hàng; chú thích dài quá thì đặt ngay dòng trên.
- Căn thẳng cột: trong mọi nhóm cùng tên bảng của một tệp, dấu = thẳng một cột và dấu # thẳng một
  cột. Không ai căn tay: align_lines() làm việc đó, gọi qua `lint_config.py --fix`.

lint_config.py kiểm bố cục này; setup_db.py dùng render() để ghi secrets.local.toml.
"""
import re
import textwrap

# Dòng kẻ của khung tiêu đề: dấu # và 50 dấu bằng, như mẫu.
RULE = "#" + "=" * 50
# Khoảng cách giữa giá trị dài nhất của nhóm và cột chú thích.
GAP = "   "
# Dòng cài đặt kèm chú thích không dài quá số cột này.
LINE_LIMIT = 110
COMMENT_WIDTH = 96

KEY = re.compile(r"^[A-Za-z0-9_-]+\s*=")
TABLE = re.compile(r"^\[\[?[A-Za-z0-9_.-]+\]\]?\s*(#.*)?$")


def banner(title: str) -> list[str]:
    """Ba dòng của một khung tiêu đề."""
    return [RULE, f"# {title}", RULE]


def comment(text: str) -> list[str]:
    """Một đoạn văn thành các dòng chú thích đã bẻ dòng."""
    return ["# " + line for line in textwrap.wrap(text, width=COMMENT_WIDTH)]


def comment_start(line: str) -> int | None:
    """Vị trí dấu # mở chú thích ngang hàng, tức dấu # nằm ngoài mọi chuỗi; không có thì None."""
    quote = ""
    escaped = False
    for index, char in enumerate(line):
        if escaped:
            escaped = False
        elif quote == '"' and char == "\\":
            escaped = True
        elif quote and char == quote:
            quote = ""
        elif not quote and char in "\"'":
            quote = char
        elif not quote and char == "#":
            return index
    return None


def split_setting(line: str) -> tuple[str, str, str | None]:
    """Một dòng cài đặt thành (khoá, giá trị, chú thích ngang hàng hoặc None)."""
    key, rest = line.split("=", 1)
    at = comment_start(rest)
    if at is None:
        return key.strip(), rest.strip(), None
    return key.strip(), rest[:at].strip(), rest[at + 1 :].strip()


def align_lines(lines: list[str]) -> list[str]:
    """Các dòng của một tệp với mọi dòng cài đặt đã căn thẳng cột; dòng khác giữ nguyên.

    Bề rộng tính chung cho mọi nhóm cùng dòng mở bảng trong tệp (các khối [[process]] thẳng hàng với
    nhau). Cột chú thích chỉ tính theo những dòng có chú thích ngang hàng.
    """
    header: str | None = None
    owners: list[str | None] = []
    for line in lines:
        if TABLE.match(line):
            header = line.split("#")[0].strip()
        owners.append(header if KEY.match(line) else None)
    key_width: dict[str | None, int] = {}
    value_width: dict[str | None, int] = {}
    for line, owner in zip(lines, owners):
        if not KEY.match(line):
            continue
        key, value, note = split_setting(line)
        key_width[owner] = max(key_width.get(owner, 0), len(key))
        if note is not None:
            value_width[owner] = max(value_width.get(owner, 0), len(value))
    out = []
    for line, owner in zip(lines, owners):
        if not KEY.match(line):
            out.append(line)
            continue
        key, value, note = split_setting(line)
        head = f"{key.ljust(key_width[owner])} = "
        out.append(head + value if note is None else f"{head}{value.ljust(value_width[owner])}{GAP}# {note}")
    return out


def render(title: str, intro: list[str], sections: list) -> str:
    """Nội dung một tệp cấu hình đúng bố cục, đã căn thẳng cột.

    sections là danh sách (tên nhóm, dòng mở bảng hoặc None, các đoạn mô tả nhóm, các khoá); mỗi
    khoá là (tên, giá trị đã viết dạng TOML, chú thích ngắn).
    """
    out = banner(title)
    for paragraph in intro:
        out += comment(paragraph)
    for name, header, about, keys in sections:
        out += [""] + banner(name)
        for paragraph in about:
            out += comment(paragraph)
        if header:
            out.append(header)
        for key, value, note in keys:
            out.append(f"{key} = {value}{GAP}# {note}")
    return "\n".join(align_lines(out)) + "\n"
