/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/aligned.hpp
 *  PHÂN HỆ   : Core / Aligned
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bố cục căn cột của bảng TSV (chủ dự án giao 2026-10-15): dòng
 *    kAlignedLayout nằm trước dòng tên cột báo rằng mọi ô (cả tên cột) có thể
 *    mang dấu cách đệm ở cuối để cột thẳng hàng khi mở bằng trình soạn. Dấu
 *    cách cuối ô khi đó là đệm, không phải dữ liệu; dấu cách cuối thật được ghi
 *    bằng kSpaceMark, mỗi dấu cách một ký hiệu, và dữ liệu của bảng căn cột
 *    không chứa kSpaceMark (bộ ghi TOOLS/server/tsv_file.py từ chối). Dấu cách
 *    ở đầu và giữa ô vẫn là dữ liệu. Dòng "# layout: <khác>" trước dòng tên cột
 *    là lỗi, để một dòng gõ sai không biến đệm thành dữ liệu. Bảng không có
 *    dòng đó đọc nguyên văn như trước. Gom ở core vì mọi bộ đọc TSV của dự án
 *    (table::parse_tsv, item::tsv::Rows, content::RecordReader) phải bỏ đệm
 *    theo đúng một luật, mà module item không phụ thuộc module table.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::core {

inline constexpr std::string_view kLayoutPrefix = "# layout: ";
inline constexpr std::string_view kAlignedLayout = "# layout: aligned";
// U+2423 OPEN BOX "␣". Nguồn phải dịch theo UTF-8 (MSVC /utf-8).
inline constexpr std::string_view kSpaceMark = "␣";
static_assert(kSpaceMark == "\xE2\x90\xA3", "kSpaceMark phải là UTF-8 của U+2423");

enum class Layout : std::uint8_t { kPlain, kAligned };

// Một ô của bảng căn cột sau khi bỏ đệm: phần chữ và số dấu cách thật ở cuối mà dãy kSpaceMark mã hoá.
// Chữ thật của ô là body nối thêm trailing_spaces dấu cách.
struct AlignedCell {
    std::string_view body;
    std::size_t trailing_spaces = 0;
};

// Bỏ dấu cách đệm ở cuối rồi tách dãy kSpaceMark cuối. O(độ dài ô); body trỏ vào cell.
[[nodiscard]] constexpr AlignedCell unpad(std::string_view cell) noexcept {
    const std::size_t last = cell.find_last_not_of(' ');
    AlignedCell out{.body = last == std::string_view::npos ? std::string_view{} : cell.substr(0, last + 1)};
    while (out.body.ends_with(kSpaceMark)) {
        out.body.remove_suffix(kSpaceMark.size());
        ++out.trailing_spaces;
    }
    return out;
}

} // namespace game::core
