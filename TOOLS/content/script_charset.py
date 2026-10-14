# Đổi văn bản script Lua của client 2026 từ GBK sang UTF-8, từng dòng, để mở được trong trình soạn và đọc được bằng
# công cụ UTF-8 của dự án (bảng TSV xuất từ Config, i18n, trọng tài đều UTF-8).
# Script gốc là GBK, nhưng 38 trên 3 173 tệp của client 3.71.9509 có dòng chú thích viết bằng UTF-8 lẫn vào (đo
# 2026-10-15: 76 021 dòng GBK, 247 dòng UTF-8 thuần, 722 dòng hợp lệ cả hai, 4 dòng UTF-8 bị cắt cụt), nên không giải cả
# tệp một bảng mã được. Luật mỗi dòng có byte ngoài ASCII:
#   1. chỉ hợp lệ GB18030            -> GBK;
#   2. chỉ hợp lệ UTF-8              -> UTF-8 (giữ byte);
#   3. hợp lệ cả hai: UTF-8 viết tiếng Trung thường vẫn hợp lệ như GBK (ra chữ lạ), còn GBK thật hiếm khi hợp lệ UTF-8.
#      - không đọc được bằng GB2312 (ngoài vùng chữ thông dụng)  -> UTF-8;
#      - đọc được bằng GB2312: là GBK, trừ khi tệp có dòng UTF-8 thuần VÀ cách đọc UTF-8 chỉ ra chữ Hán và dấu câu
#        CJK (không lẫn chữ Latin/Hy Lạp/Kirin lạ như khi GBK bị đọc nhầm thành UTF-8);
#   4. không hợp lệ cả hai (UTF-8 bị cắt cụt)   -> UTF-8, byte hỏng thành U+FFFD (đều nằm trong dòng chú thích).
#   Ngoại lệ của luật 1, chỉ trong tệp có dòng UTF-8 thuần: dòng hợp lệ GB18030 mà không đọc được bằng GB2312, và đọc UTF-8
#   (byte hỏng thành U+FFFD) ra chữ Hán với số U+FFFD không quá số chữ Hán, là UTF-8 bị cắt cụt ở ký tự cuối chứ không phải
#   GBK (DressPaint_sp.lua: nhiều chú thích UTF-8 mất byte cuối; đọc như GBK ra "涓嶈兘鍜..."). Byte hỏng đó là hỏng sẵn
#   ở gói gốc, không khôi phục được; convert() trả số dòng phải thay.
# Mọi dòng chọn GBK được mã hoá ngược bằng GB18030 và phải ra đúng byte gốc, nếu không là lỗi.
# Không có chế độ đổi tại chỗ: chạy lại trên văn bản đã là UTF-8 sẽ đọc nhầm dòng "hợp lệ cả hai". Luôn đọc từ nguồn
# (gói .axp qua unpack_scripts.py, hoặc một cây GBK) và ghi sang thư mục khác.
#   python TOOLS/content/script_charset.py <cây GBK> <thư mục đích mới>
import argparse
import sys
from pathlib import Path


def _valid(line: bytes, encoding: str) -> bool:
    try:
        line.decode(encoding)
        return True
    except UnicodeDecodeError:
        return False


def _is_cjk_text(text: str) -> bool:
    """Mọi ký tự ngoài ASCII là chữ Hán, dấu câu CJK, dạng toàn chiều hay dấu câu chung."""
    return all(
        ch < "\x80" or "一" <= ch <= "鿿" or "　" <= ch <= "〿" or "＀" <= ch <= "￯"
        or " " <= ch <= "⁯"
        for ch in text)


def _is_truncated_utf8(text: str) -> bool:
    """Kết quả đọc UTF-8 có thay byte hỏng: chữ Hán thật nhiều hơn hay bằng số U+FFFD, và không còn ký tự lạ nào."""
    ideographs = sum("一" <= ch <= "鿿" for ch in text)
    damaged = text.count("�")
    return ideographs >= 1 and damaged <= ideographs and _is_cjk_text(text.replace("�", ""))


def convert(data: bytes) -> tuple[bytes, int]:
    """Văn bản UTF-8 của một script GBK (có thể lẫn dòng UTF-8) và số dòng có byte hỏng phải thay bằng U+FFFD.
    Xuống dòng, kể cả CRLF, giữ nguyên."""
    lines = data.split(b"\n")
    has_utf8_only = any(
        not line.isascii() and _valid(line, "utf-8") and not _valid(line, "gb18030") for line in lines)
    out: list[str] = []
    replaced = 0
    for number, line in enumerate(lines, 1):
        if line.isascii():
            out.append(line.decode("ascii"))
            continue
        as_gb, as_utf8 = _valid(line, "gb18030"), _valid(line, "utf-8")
        if as_gb and not as_utf8:
            use_gb = True
            if has_utf8_only and not _valid(line, "gb2312"):
                repaired = line.decode("utf-8", errors="replace")
                if _is_truncated_utf8(repaired):
                    out.append(repaired)
                    replaced += 1
                    continue
        elif as_utf8 and not as_gb:
            use_gb = False
        elif as_gb and as_utf8:
            if not _valid(line, "gb2312"):
                use_gb = False
            else:
                use_gb = not (has_utf8_only and _is_cjk_text(line.decode("utf-8")))
        else:
            out.append(line.decode("utf-8", errors="replace"))
            replaced += 1
            continue
        if use_gb:
            text = line.decode("gb18030")
            if text.encode("gb18030") != line:
                raise ValueError(f"dòng {number}: GB18030 không mã hoá ngược ra đúng byte gốc")
            out.append(text)
        else:
            out.append(line.decode("utf-8"))
    return "\n".join(out).encode("utf-8"), replaced


def to_utf8(data: bytes) -> bytes:
    return convert(data)[0]


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Đổi cây script Lua GBK sang UTF-8 (ghi sang thư mục khác)")
    parser.add_argument("src", type=Path)
    parser.add_argument("dst", type=Path)
    chosen = parser.parse_args()
    if chosen.dst.resolve() == chosen.src.resolve() or chosen.src.resolve() in chosen.dst.resolve().parents:
        print("thư mục đích không được trùng hay nằm trong nguồn (không đổi tại chỗ)", file=sys.stderr)
        return 2
    count = 0
    for source in sorted(chosen.src.rglob("*.lua")):
        target = chosen.dst / source.relative_to(chosen.src)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(to_utf8(source.read_bytes()))
        count += 1
    print(f"đã đổi {count} tệp sang {chosen.dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
