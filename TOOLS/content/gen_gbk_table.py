#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/gen_gbk_table.py
#  PHÂN HỆ   : Content / Gen Gbk Table
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Sinh engine/core/detail/gbk_table.hpp: bảng GBK (trang 936) sang Unicode
#    cho core::utf8_from_gbk, lấy từ chính MultiByteToWideChar(936) của Windows
#    (codecs.code_page_decode) để Android và iOS giải tên tệp đúng như PC.
#  - --check: chỉ so tệp đã có với bảng vừa tính, khác thì thoát mã 1.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Cách chạy (chỉ Windows): python -B TOOLS/content/gen_gbk_table.py [--out engine/core/detail/gbk_table.hpp] [--check]"""

from __future__ import annotations

import argparse
import codecs
import sys
from pathlib import Path

LEAD_FIRST = 0x81
LEAD_LAST = 0xFE
TRAIL_FIRST = 0x40
TRAIL_LAST = 0xFE
PER_LINE = 12


def decode_936(data: bytes) -> str | None:
    # MultiByteToWideChar(936, MB_ERR_INVALID_CHARS): dãy không có trong trang mã là lỗi, không thay bằng ký tự khác.
    try:
        return codecs.code_page_decode(936, data, "strict", True)[0]
    except UnicodeDecodeError:
        return None


def code_of(data: bytes) -> int:
    # Điểm mã của dãy, 0 khi dãy không giải được thành đúng một ký tự trong BMP.
    text = decode_936(data)
    if text is None or len(text) != 1 or ord(text) > 0xFFFF or ord(text) == 0:
        return 0
    return ord(text)


def render() -> str:
    pairs = [code_of(bytes([lead, trail])) for lead in range(LEAD_FIRST, LEAD_LAST + 1)
             for trail in range(TRAIL_FIRST, TRAIL_LAST + 1)]
    single = code_of(b"\x80")
    if single == 0 or sum(1 for code in pairs if code) < 20000:
        raise SystemExit("bảng GBK: trang 936 của máy này không như mong đợi")
    lines = [
        "// TỆP SINH bởi TOOLS/content/gen_gbk_table.py từ MultiByteToWideChar(936) của Windows; không sửa tay.",
        "// Ô của cặp (lead, trail) nằm ở (lead - kGbkLeadFirst) * kGbkTrails + (trail - kGbkTrailFirst); 0 là cặp không",
        "// có trong trang mã. Mọi điểm mã đều trong BMP.",
        "#pragma once",
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "",
        "namespace game::core::detail {",
        "",
        f"inline constexpr unsigned kGbkLeadFirst = 0x{LEAD_FIRST:02X};",
        f"inline constexpr unsigned kGbkLeadLast = 0x{LEAD_LAST:02X};",
        f"inline constexpr unsigned kGbkTrailFirst = 0x{TRAIL_FIRST:02X};",
        f"inline constexpr unsigned kGbkTrailLast = 0x{TRAIL_LAST:02X};",
        "inline constexpr std::size_t kGbkTrails = std::size_t{kGbkTrailLast} - kGbkTrailFirst + 1;",
        "inline constexpr std::size_t kGbkLeads = std::size_t{kGbkLeadLast} - kGbkLeadFirst + 1;",
        "// Byte đơn 0x80 của trang 936; các byte đơn khác từ 0x80 trở lên không giải được.",
        f"inline constexpr char16_t kGbkSingle80 = 0x{single:04X};",
        "",
        "inline constexpr std::array<std::uint16_t, kGbkLeads * kGbkTrails> kGbkPairs{",
    ]
    for start in range(0, len(pairs), PER_LINE):
        chunk = pairs[start:start + PER_LINE]
        lines.append("    " + " ".join(f"0x{code:04X}," for code in chunk))
    lines += ["};", "", "} // namespace game::core::detail", ""]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="engine/core/detail/gbk_table.hpp")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if sys.platform != "win32":
        raise SystemExit("bảng GBK: chỉ sinh được trên Windows (cần MultiByteToWideChar)")
    text = render()
    out = Path(args.out)
    if args.check:
        current = out.read_text(encoding="utf-8") if out.is_file() else ""
        if current != text:
            raise SystemExit(f"bảng GBK: {out} cũ hơn trang 936, chạy lại không có --check")
        print(f"bảng GBK: {out} khớp")
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8", newline="\n")
    print(f"bảng GBK: ghi {out}")


if __name__ == "__main__":
    main()
