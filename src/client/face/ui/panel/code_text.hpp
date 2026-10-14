// Chữ UTF-8 do người chơi gõ vào một ô nhập: đếm, bỏ và thêm từng điểm mã của mặt phẳng cơ bản.
// Các bảng có ô nhận chữ có dấu (tên nhân vật, ô tìm máy chủ) dùng chung ba hàm này.
#pragma once

#include <algorithm>
#include <cstddef>
#include <string>
#include <string_view>

namespace game::ui::panel {

[[nodiscard]] inline bool starts_point(unsigned char byte) noexcept {
    return (byte & 0xC0U) != 0x80U;
}

// Số điểm mã của text: byte tiếp nối không đếm.
[[nodiscard]] inline std::size_t code_points(std::string_view text) noexcept {
    return static_cast<std::size_t>(std::ranges::count_if(text,
        [](char byte) { return starts_point(static_cast<unsigned char>(byte)); }));
}

// Bỏ điểm mã cuối; chuỗi rỗng thì không làm gì.
inline void pop_code_point(std::string& text) noexcept {
    while (!text.empty() && !starts_point(static_cast<unsigned char>(text.back())))
        text.pop_back();
    if (!text.empty()) text.pop_back();
}

// Thêm một điểm mã của mặt phẳng cơ bản (U+0000..U+FFFF, người gọi đã loại nửa cặp thay thế) dưới
// dạng UTF-8.
inline void append_utf8(std::string& text, char32_t code) {
    if (code < 0x80) {
        text.push_back(static_cast<char>(code));
        return;
    }
    if (code < 0x800) {
        text.push_back(static_cast<char>(0xC0U | (code >> 6U)));
        text.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
        return;
    }
    text.push_back(static_cast<char>(0xE0U | (code >> 12U)));
    text.push_back(static_cast<char>(0x80U | ((code >> 6U) & 0x3FU)));
    text.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
}

} // namespace game::ui::panel
