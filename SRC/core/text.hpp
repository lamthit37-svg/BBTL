// Đổi UTF-8 ↔ UTF-16 ở biên Win32. Forge2 giữ UTF-8 trong toàn bộ mã và chỉ đổi ngay tại lời gọi
// API bản W. _Ref đổi bằng mbstowcs theo code page ANSI, nên tên luồng và thông báo assert có dấu
// thành rác. Byte UTF-8 hỏng thành U+FFFD thay vì báo lỗi: hai hàm này dành cho log, tên, đường dẫn
// hiển thị, không dành cho kiểm tra dữ liệu.
// Nguồn: Forge2 src/core/text.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>

namespace game::core {

// UTF-8 sang UTF-16 cho API Win32 bản W. Dài hơn INT_MAX byte là lỗi lập trình (core::check).
[[nodiscard]] std::wstring widen(std::string_view text);

// UTF-16 nhận từ API Win32 sang UTF-8.
[[nodiscard]] std::string narrow(std::wstring_view text);

// Byte tiếp nối 10xxxxxx: không đứng đầu ký tự UTF-8 nào.
[[nodiscard]] constexpr bool is_utf8_continuation(char byte) noexcept {
    return (static_cast<unsigned char>(byte) & 0xC0U) == 0x80U;
}

// Phần đầu dài tối đa limit byte, không chẻ ký tự UTF-8: lùi về đầu ký tự đang bị cắt.
[[nodiscard]] std::string_view utf8_prefix(std::string_view text, std::size_t limit) noexcept;

// Phần đuôi dài tối đa limit byte, bắt đầu ở đầu một ký tự UTF-8 (đuôi đường dẫn là tên tệp).
[[nodiscard]] std::string_view utf8_suffix(std::string_view text, std::size_t limit) noexcept;

// Đúng RFC 3629: từ chối dãy dài quá mức, nửa cặp thay thế UTF-16 (U+D800..U+DFFF), điểm mã trên
// U+10FFFF, byte tiếp nối lạc chỗ và dãy bị cụt. Khác widen và narrow, hàm này để KIỂM dữ liệu:
// chuỗi từ mạng và tệp là dữ liệu thù địch, một dãy byte hỏng lọt qua sẽ tới log, giao diện và tên
// tệp.
[[nodiscard]] bool is_valid_utf8(std::string_view text) noexcept;

// Một ký tự đọc từ đầu chuỗi UTF-8: điểm mã và số byte đã dùng (0 khi chuỗi rỗng).
struct Utf8Step {
    char32_t code = 0;
    std::uint8_t length = 0;
};

// Số byte của ký tự theo byte đầu; 0 khi byte đó không mở đầu ký tự nào (byte tiếp nối hay từ
// 0xF8 trở lên).
[[nodiscard]] constexpr std::uint8_t utf8_length(unsigned char lead) noexcept {
    if (lead < 0x80U) return 1;
    if ((lead & 0xE0U) == 0xC0U) return 2;
    if ((lead & 0xF0U) == 0xE0U) return 3;
    if ((lead & 0xF8U) == 0xF0U) return 4;
    return 0;
}

// Sáu bit thấp của một byte tiếp nối, dịch sang trái shift bit về chỗ của nó trong điểm mã.
[[nodiscard]] constexpr char32_t utf8_tail(char byte, unsigned shift) noexcept {
    return static_cast<char32_t>(static_cast<unsigned char>(byte) & 0x3FU) << shift;
}

// Đọc một ký tự ở đầu chuỗi để VẼ chữ: dãy hỏng (byte đầu lạ, bị cụt, byte tiếp nối sai) thành
// U+FFFD dài một byte, nên vòng đọc luôn tiến. Không kiểm dãy dài quá mức; dữ liệu cần kiểm thì
// qua is_valid_utf8 trước.
[[nodiscard]] constexpr Utf8Step utf8_step(std::string_view text) noexcept {
    constexpr Utf8Step kBroken{.code = 0xFFFD, .length = 1};
    if (text.empty()) return {};
    const auto lead = static_cast<unsigned char>(text.front());
    const std::uint8_t length = utf8_length(lead);
    if (length == 1) return {.code = lead, .length = 1};
    if (length == 0 || text.size() < length) return kBroken;
    if (!std::ranges::all_of(text.substr(1, length - 1U), is_utf8_continuation)) return kBroken;
    const auto head_mask = static_cast<unsigned char>(0xFFU >> (length + 1U));
    char32_t code = static_cast<char32_t>(lead & head_mask) << (6U * (length - 1U));
    for (std::size_t index = 1; index < length; ++index)
        code |= utf8_tail(text[index], 6U * static_cast<unsigned>(length - 1U - index));
    return {.code = code, .length = length};
}

// Nhìn chuỗi như dãy byte và ngược lại, không chép. char được phép bí danh mọi đối tượng nên không
// vi phạm strict aliasing; vùng nhìn sống đúng bằng nguồn.
[[nodiscard]] inline std::span<const std::byte> view_bytes(std::string_view text) noexcept {
    return std::as_bytes(std::span{text});
}

[[nodiscard]] inline std::string_view view_text(std::span<const std::byte> bytes) noexcept {
    // Bí danh hợp lệ (xem trên); string_view không sở hữu.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return {reinterpret_cast<const char*>(bytes.data()), bytes.size()};
}

} // namespace game::core
