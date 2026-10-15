#include "luanum/luanum.h"

#include "luanum/cformat.hpp"
#include "luanum/number.hpp"

#include <algorithm>
#include <bit>
#include <cerrno>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <span>
#include <string>
#include <string_view>

namespace game::luanum {
namespace {

// Hạt của rand: MSVCR110 giữ mỗi luồng một hạt (_getptd()->_holdrand), khởi đầu 1.
constexpr std::uint32_t kRandMultiplier = 214013U;
constexpr std::uint32_t kRandIncrement = 2531011U;
constexpr std::uint32_t kRandMask = 0x7FFFU;
constexpr std::uint32_t kRandShift = 16U;
constexpr std::uint32_t kRandSeed = 1U;

// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables): trạng thái của rand là của luồng, như CRT gốc.
thread_local std::uint32_t t_rand_seed = kRandSeed;

// Đặc tả mà scanformat của lstrlib.c đã kiểm: '%', cờ, hai chữ số rộng, '.' và hai chữ số chính xác, rồi kiểu.
struct ParsedForm {
    FormatSpec spec;
    char conversion = '\0';
};

[[nodiscard]] bool is_digit(char letter) noexcept {
    return letter >= '0' && letter <= '9';
}

[[nodiscard]] bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

[[nodiscard]] int read_number(std::string_view text, std::size_t& cursor) noexcept {
    int value = 0;
    while (cursor < text.size() && is_digit(text[cursor])) {
        value = value * 10 + (text[cursor] - '0');
        ++cursor;
    }
    return value;
}

[[nodiscard]] ParsedForm parse_form(std::string_view form) noexcept {
    ParsedForm parsed;
    std::size_t cursor = form.empty() ? 0 : 1; // bỏ '%'
    for (; cursor < form.size(); ++cursor) {
        const char flag = form[cursor];
        if (flag == '-') parsed.spec.left = true;
        else if (flag == '+') parsed.spec.sign = true;
        else if (flag == ' ') parsed.spec.blank = true;
        else if (flag == '#') parsed.spec.alternate = true;
        else if (flag == '0') parsed.spec.zero = true;
        else break;
    }
    parsed.spec.width = read_number(form, cursor);
    if (cursor < form.size() && form[cursor] == '.') {
        ++cursor;
        parsed.spec.precision = read_number(form, cursor);
    }
    if (cursor < form.size()) parsed.conversion = form[cursor];
    return parsed;
}

// Chép text vào out (tối đa out.size() - 1 byte) rồi byte 0; trả số byte đã ghi.
[[nodiscard]] std::size_t store(std::span<char> out, const std::string& text) noexcept {
    if (out.empty()) return 0;
    const std::size_t count = std::min(text.size(), out.size() - 1);
    std::memcpy(out.data(), text.data(), count);
    out[count] = '\0';
    return count;
}

} // namespace
} // namespace game::luanum

extern "C" {

double luanum_indefinite(void) {
    return std::bit_cast<double>(std::uint64_t{0xFFF8000000000000ULL});
}

int luanum_number2str(char* buffer, double n) {
    constexpr std::size_t kBuffer = 32;
    return static_cast<int>(game::luanum::store({buffer, kBuffer}, game::luanum::number_to_string(n)));
}

double luanum_strtod(const char* text, char** end) {
    const std::string_view view(text);
    const game::luanum::NumberPrefix prefix = game::luanum::scan_number(view);
    if (end != nullptr) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): hợp đồng của strtod, trả char* vào chuỗi const.
        *end = const_cast<char*>(view.substr(prefix.found ? prefix.end : 0).data());
    }
    return prefix.found ? game::luanum::convert_number(view, prefix) : 0.0;
}

uint32_t luanum_strtoul(const char* text, char** end, int base) {
    // strtoull lo dấu, khoảng trắng và tiền tố 0x; strtoul của MSVCR110 chỉ khác ở độ rộng 32 bit của unsigned long.
    constexpr std::uint64_t kLimit = std::numeric_limits<std::uint32_t>::max();
    const std::string_view view(text);
    std::size_t first = 0;
    while (first < view.size() && game::luanum::is_space(view[first]))
        ++first;
    const bool negative = first < view.size() && view[first] == '-';
    errno = 0;
    char* stop = nullptr;
    const std::uint64_t raw = std::strtoull(text, &stop, base);
    if (end != nullptr) *end = stop;
    if (stop == text) return 0;
    if (errno == ERANGE) return static_cast<uint32_t>(kLimit);
    // strtoull đảo dấu theo 64 bit; lấy độ lớn ra để so với trần 32 bit rồi đảo lại theo số học 32 bit.
    const std::uint64_t magnitude = negative ? std::uint64_t{0} - raw : raw;
    if (magnitude > kLimit) return static_cast<uint32_t>(kLimit);
    const auto low = static_cast<std::uint32_t>(magnitude);
    return negative ? std::uint32_t{0} - low : low;
}

int luanum_rand(void) {
    std::uint32_t& seed = game::luanum::t_rand_seed;
    seed = seed * game::luanum::kRandMultiplier + game::luanum::kRandIncrement;
    return static_cast<int>((seed >> game::luanum::kRandShift) & game::luanum::kRandMask);
}

void luanum_srand(uint32_t seed) {
    game::luanum::t_rand_seed = seed;
}

size_t luanum_format_int(char* out, size_t capacity, const char* form, int32_t value) {
    const game::luanum::ParsedForm parsed = game::luanum::parse_form(form);
    return game::luanum::store({out, capacity}, parsed.conversion == 'c' ? game::luanum::format_char(parsed.spec, value)
                                                                      : game::luanum::format_signed(parsed.spec, value));
}

size_t luanum_format_uint(char* out, size_t capacity, const char* form, uint32_t value) {
    const game::luanum::ParsedForm parsed = game::luanum::parse_form(form);
    return game::luanum::store({out, capacity}, game::luanum::format_unsigned(parsed.conversion, parsed.spec, value));
}

size_t luanum_format_double(char* out, size_t capacity, const char* form, double value) {
    const game::luanum::ParsedForm parsed = game::luanum::parse_form(form);
    return game::luanum::store({out, capacity}, game::luanum::format_double(parsed.conversion, parsed.spec, value));
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký theo sprintf(buffer, form, giá trị), như bốn hàm trên.
size_t luanum_format_text(char* out, size_t capacity, const char* form, const char* text) {
    const game::luanum::ParsedForm parsed = game::luanum::parse_form(form);
    return game::luanum::store({out, capacity}, game::luanum::format_text(parsed.spec, text));
}

} // extern "C"
