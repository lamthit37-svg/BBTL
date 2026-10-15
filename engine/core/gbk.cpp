/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/gbk.cpp
 *  PHÂN HỆ   : Core / Gbk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/gbk.hpp.
 *  - Bảng ở core/detail/gbk_table.hpp là tệp sinh; mọi điểm mã trong đó thuộc
 *    BMP nên mỗi ký tự ra một tới ba byte UTF-8.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/gbk.hpp"

#include "core/detail/gbk_table.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::core {
namespace {

constexpr unsigned kAsciiEnd = 0x80;

// Một ký tự đọc ở một chỗ của chuỗi GBK: điểm mã và số byte đã dùng.
struct Step {
    char32_t code = 0;
    std::uint8_t bytes = 1;
    bool is_valid = false;
};

// Điểm mã của cặp (lead, trail), 0 khi cặp không có trong trang mã. lead thuộc kGbkLeadFirst..kGbkLeadLast.
[[nodiscard]] char32_t pair_code(unsigned lead, unsigned trail) noexcept {
    if (trail < detail::kGbkTrailFirst || trail > detail::kGbkTrailLast) return 0;
    const std::size_t slot =
        (std::size_t{lead - detail::kGbkLeadFirst} * detail::kGbkTrails) + (trail - detail::kGbkTrailFirst);
    return detail::kGbkPairs.at(slot);
}

// index < text.size().
[[nodiscard]] Step step_at(std::string_view text, std::size_t index) noexcept {
    const auto lead = static_cast<unsigned char>(text[index]);
    if (lead < kAsciiEnd) return Step{.code = lead, .bytes = 1, .is_valid = true};
    if (lead == kAsciiEnd) return Step{.code = detail::kGbkSingle80, .bytes = 1, .is_valid = true};
    const bool has_trail = lead <= detail::kGbkLeadLast && index + 1 < text.size();
    if (!has_trail) return Step{};
    const char32_t code = pair_code(lead, static_cast<unsigned char>(text[index + 1]));
    return Step{.code = code, .bytes = 2, .is_valid = code != 0};
}

// Điểm mã BMP sang UTF-8; bảng không chứa nửa cặp thay thế.
void append_bmp(std::string& out, char32_t code) {
    if (code < kAsciiEnd) {
        out.push_back(static_cast<char>(code));
        return;
    }
    if (code < 0x800) {
        out.push_back(static_cast<char>(0xC0U | (code >> 6U)));
        out.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
        return;
    }
    out.push_back(static_cast<char>(0xE0U | (code >> 12U)));
    out.push_back(static_cast<char>(0x80U | ((code >> 6U) & 0x3FU)));
    out.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
}

} // namespace

std::optional<std::string> utf8_from_gbk(std::string_view text) {
    std::string out;
    out.reserve(text.size() + (text.size() / 2));
    std::size_t index = 0;
    while (index < text.size()) {
        const Step step = step_at(text, index);
        if (!step.is_valid) return std::nullopt;
        append_bmp(out, step.code);
        index += step.bytes;
    }
    return out;
}

} // namespace game::core
