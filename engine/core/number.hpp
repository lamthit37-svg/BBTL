// Đọc số ở đầu một chuỗi bằng std::from_chars: không phụ thuộc locale, không cấp phát, không ném,
// làm tròn đúng. Gom về một chỗ để mọi module đọc số theo cùng một cách và để phần đổi từ
// string_view sang cặp con trỏ mà from_chars đòi chỉ viết một lần.
#pragma once

#include <charconv>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <string_view>
#include <system_error>

namespace game::core {

struct ParsedDouble {
    double value = 0.0;
    // Số ký tự ở đầu chuỗi đã dùng để tạo thành value.
    std::size_t length = 0;
};

struct ParsedUnsigned {
    std::uint32_t value = 0;
    // Số ký tự ở đầu chuỗi đã dùng để tạo thành value.
    std::size_t length = 0;
};

struct ParsedSigned {
    std::int32_t value = 0;
    // Số ký tự ở đầu chuỗi đã dùng để tạo thành value.
    std::size_t length = 0;
};

using OptionalDouble = std::optional<ParsedDouble>;
using OptionalUnsigned = std::optional<ParsedUnsigned>;
using OptionalSigned = std::optional<ParsedSigned>;

// Số thực thập phân ở đầu text (không nhận dấu cộng hay khoảng trắng đứng đầu); không có khi text
// không mở đầu bằng một số hoặc số vượt miền double.
[[nodiscard]] inline OptionalDouble parse_double(std::string_view text) noexcept {
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    double value = 0.0;
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{}) return std::nullopt;
    const auto length = static_cast<std::size_t>(std::distance(first, stop));
    return ParsedDouble{.value = value, .length = length};
}

// Số nguyên không dấu theo cơ số base (2..36) ở đầu text; không có khi text không mở đầu bằng chữ
// số hoặc số vượt 32 bit.
[[nodiscard]] inline OptionalUnsigned parse_unsigned(std::string_view text, int base) noexcept {
    // from_chars đòi base 2..36: ngoài miền là vi phạm tiền điều kiện (UB).
    if (base < 2 || base > 36) return std::nullopt;
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    std::uint32_t value = 0;
    const auto [stop, error] = std::from_chars(first, last, value, base);
    if (error != std::errc{}) return std::nullopt;
    const auto length = static_cast<std::size_t>(std::distance(first, stop));
    return ParsedUnsigned{.value = value, .length = length};
}

// Số nguyên có dấu cơ số 10 ở đầu text (nhận dấu trừ; không nhận dấu cộng hay khoảng trắng đứng
// đầu); không có khi text không mở đầu bằng một số hoặc số vượt 32 bit có dấu.
[[nodiscard]] inline OptionalSigned parse_signed(std::string_view text) noexcept {
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    std::int32_t value = 0;
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{}) return std::nullopt;
    const auto length = static_cast<std::size_t>(std::distance(first, stop));
    return ParsedSigned{.value = value, .length = length};
}

// Số nguyên không âm cơ số 10 chiếm TRỌN text và vừa kiểu int (mã cảnh, cỡ bảng); không có khi
// text rỗng, còn ký tự thừa, có dấu hay vượt miền int.
[[nodiscard]] inline std::optional<int> parse_whole_int(std::string_view text) noexcept {
    const OptionalUnsigned parsed = parse_unsigned(text, 10);
    if (!parsed || parsed->length != text.size()) return std::nullopt;
    const auto largest = static_cast<std::uint32_t>(std::numeric_limits<int>::max());
    if (parsed->value > largest) return std::nullopt;
    return static_cast<int>(parsed->value);
}

} // namespace game::core
