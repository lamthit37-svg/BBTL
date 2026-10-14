#include "ui/panel/lua_value.hpp"

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <format>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// isspace của locale "C".
[[nodiscard]] constexpr bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

[[nodiscard]] constexpr bool is_digit(char letter) noexcept {
    return letter >= '0' && letter <= '9';
}

[[nodiscard]] constexpr bool is_sign(char letter) noexcept {
    return letter == '+' || letter == '-';
}

// strtod của MSVCR110 nhận cả 'd' và 'D' làm dấu số mũ (đo bằng "1d5" trên LuaPlus.dll).
[[nodiscard]] constexpr bool is_exponent_mark(char letter) noexcept {
    return letter == 'e' || letter == 'E' || letter == 'd' || letter == 'D';
}

// Số chữ số thập phân liên tiếp bắt đầu ở vị trí at.
[[nodiscard]] std::size_t digits_at(std::string_view text, std::size_t at) noexcept {
    std::size_t end = at;
    while (end < text.size() && is_digit(text[end]))
        ++end;
    return end - at;
}

// Độ dài phần số mũ ("e+12") bắt đầu ở vị trí at; 0 khi không có chữ số sau dấu số mũ (khi đó strtod
// dừng trước chữ e và phần còn lại làm chuỗi không hợp lệ).
[[nodiscard]] std::size_t exponent_at(std::string_view text, std::size_t at) noexcept {
    if (at >= text.size() || !is_exponent_mark(text[at])) return 0;
    const std::size_t sign = (at + 1 < text.size() && is_sign(text[at + 1])) ? 1 : 0;
    const std::size_t power = digits_at(text, at + 1 + sign);
    return power == 0 ? 0 : 1 + sign + power;
}

} // namespace

std::optional<double> lua_tonumber(std::string_view text) {
    text = text.substr(0, text.find('\0'));
    std::size_t at = 0;
    while (at < text.size() && is_space(text[at]))
        ++at;
    const std::size_t begin = at;
    if (at < text.size() && is_sign(text[at])) ++at;
    const std::size_t whole = digits_at(text, at);
    at += whole;
    std::size_t fraction = 0;
    if (at < text.size() && text[at] == '.') {
        fraction = digits_at(text, at + 1);
        at += 1 + fraction;
    }
    if (whole + fraction == 0) return std::nullopt;
    at += exponent_at(text, at);
    const std::size_t end = at;
    while (at < text.size() && is_space(text[at]))
        ++at;
    if (at != text.size()) return std::nullopt;
    std::string number(text.substr(begin, end - begin));
    std::ranges::replace(number, 'd', 'e');
    std::ranges::replace(number, 'D', 'E');
    errno = 0;
    const double value = std::strtod(number.c_str(), nullptr);
    // strtod của MSVCR110 trả +0 khi số âm nhỏ quá tràn xuống dưới mức biểu diễn (đo "-1e-400" ra "0");
    // chuỗi "-0" thì vẫn ra -0.
    return (errno == ERANGE && value == 0.0) ? 0.0 : value;
}

std::string lua_tostring(double value) {
    if (std::isnan(value)) return std::signbit(value) ? "-1.#IND" : "1.#QNAN";
    if (std::isinf(value)) return std::signbit(value) ? "-1.#INF" : "1.#INF";
    std::string text = std::format("{:.14g}", value);
    const std::size_t mark = text.find('e');
    if (mark == std::string::npos) return text;
    // Số mũ của MSVCR110 luôn có ít nhất ba chữ số; sau 'e' là dấu rồi các chữ số.
    const std::size_t digits = text.size() - (mark + 2);
    if (digits < 3) text.insert(mark + 2, 3 - digits, '0');
    return text;
}

} // namespace game::ui::panel
