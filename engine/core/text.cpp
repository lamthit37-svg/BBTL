// Cờ 0 cho MultiByteToWideChar và WideCharToMultiByte: chuỗi hỏng được thay bằng U+FFFD thay vì
// làm cả lời gọi thất bại, nên số ký tự của lượt đo luôn khớp lượt ghi.
// POSIX: wchar_t là UTF-32; dãy hỏng thành một U+FFFD; trần INT_MAX giữ nguyên.
// Nguồn: Forge2 src/core/text.cpp@d7fcd76. Khác gốc: macro của windows.h lấy từ core/win32.hpp (gốc
// khai ở CMake); header con của Win32 include trực tiếp; vòng của is_valid_utf8 tách thành
// next_sequence để thân vòng lặp không còn nhánh; chuỗi dài hơn INT_MAX là lỗi lập trình,
// checked_size gọi core::check thay vì ném std::length_error.
#include "core/text.hpp"

#include "core/check.hpp"
#if defined(_WIN32)
#include "core/win32.hpp" // IWYU pragma: keep

#include <stringapiset.h>
#endif

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>
#include <string>
#include <string_view>

namespace game::core {

namespace {

// Win32 nhận độ dài kiểu int.
[[nodiscard]] int checked_size(std::size_t size) noexcept {
    constexpr auto kLimit = static_cast<std::size_t>(std::numeric_limits<int>::max());
    check(size <= kLimit, "chuỗi dài quá INT_MAX để đổi mã");
    return static_cast<int>(size);
}

} // namespace

#if defined(_WIN32)
// Hai hàm dưới truyền data() kèm độ dài tường minh (size), không cần ký tự kết thúc; check của tidy
// không thấy tham số độ dài đi kèm (STD-02).
// NOLINTBEGIN(bugprone-suspicious-stringview-data-usage)
std::wstring widen(std::string_view text) {
    if (text.empty()) return {};
    const int size = checked_size(text.size());
    const int count = MultiByteToWideChar(CP_UTF8, 0, text.data(), size, nullptr, 0);
    // count 0 là lỗi; gọi lượt ghi với room 0 thì Win32 lại trả độ dài cần, vượt room.
    if (count <= 0) return {};
    std::wstring result;
    const auto fill = [&](wchar_t* out, std::size_t room) {
        return MultiByteToWideChar(CP_UTF8, 0, text.data(), size, out, static_cast<int>(room));
    };
    result.resize_and_overwrite(static_cast<std::size_t>(count), fill);
    return result;
}

std::string narrow(std::wstring_view text) {
    if (text.empty()) return {};
    const int size = checked_size(text.size());
    const int count = WideCharToMultiByte(CP_UTF8, 0, text.data(), size, nullptr, 0, nullptr, nullptr);
    if (count <= 0) return {};
    std::string result;
    const auto fill = [&](char* out, std::size_t room) {
        const int written = static_cast<int>(room);
        return WideCharToMultiByte(CP_UTF8, 0, text.data(), size, out, written, nullptr, nullptr);
    };
    result.resize_and_overwrite(static_cast<std::size_t>(count), fill);
    return result;
}
// NOLINTEND(bugprone-suspicious-stringview-data-usage)
#endif

std::string_view utf8_prefix(std::string_view text, std::size_t limit) noexcept {
    if (text.size() <= limit) return text;
    std::size_t keep = limit;
    while (keep > 0 && is_utf8_continuation(text.at(keep))) {
        --keep;
    }
    return text.substr(0, keep);
}

std::string_view utf8_suffix(std::string_view text, std::size_t limit) noexcept {
    if (text.size() <= limit) return text;
    std::string_view tail = text.substr(text.size() - limit);
    while (!tail.empty() && is_utf8_continuation(tail.front())) {
        tail.remove_prefix(1);
    }
    return tail;
}

// Kiểm hợp lệ: dạng byte theo bảng 3-7 của chuẩn Unicode, cũng là định nghĩa của RFC 3629. Đi theo
// độ dài suy từ byte đầu cộng dải hẹp của byte thứ hai; ASCII đi đường nhanh tám byte một lần, vì
// chuỗi trong gói tin phần lớn là ASCII.
namespace {

[[nodiscard]] bool is_ascii_word(std::string_view text, std::size_t index) noexcept {
    std::uint64_t word = 0;
    std::memcpy(&word, text.substr(index, sizeof(word)).data(), sizeof(word));
    return (word & 0x8080808080808080ULL) == 0;
}

[[nodiscard]] std::size_t skip_ascii(std::string_view text, std::size_t index) noexcept {
    while (index + sizeof(std::uint64_t) <= text.size() && is_ascii_word(text, index)) {
        index += sizeof(std::uint64_t);
    }
    while (index < text.size() && static_cast<unsigned char>(text.at(index)) < 0x80U) {
        ++index;
    }
    return index;
}

// 0 khi byte không mở đầu được một dãy: byte tiếp nối, C0 và C1 (luôn dài quá mức), F5..FF (vượt
// U+10FFFF).
[[nodiscard]] constexpr std::size_t sequence_length(unsigned char lead) noexcept {
    if (lead < 0x80U) return 1;
    if (lead < 0xC2U) return 0;
    if (lead < 0xE0U) return 2;
    if (lead < 0xF0U) return 3;
    if (lead < 0xF5U) return 4;
    return 0;
}

// Sau bốn byte đầu này, byte thứ hai hẹp hơn 80..BF: E0 và F0 chặn dạng dài quá mức, ED chặn nửa
// cặp thay thế UTF-16, F4 chặn điểm mã trên U+10FFFF. Hai byte liền nhau của một dãy, thứ tự theo
// vị trí trong chuỗi (ngoại lệ của API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] constexpr bool is_second_valid(unsigned char lead, unsigned char second) noexcept {
    if (lead == 0xE0U) return second >= 0xA0U && second <= 0xBFU;
    if (lead == 0xEDU) return second >= 0x80U && second <= 0x9FU;
    if (lead == 0xF0U) return second >= 0x90U && second <= 0xBFU;
    if (lead == 0xF4U) return second >= 0x80U && second <= 0x8FU;
    return (second & 0xC0U) == 0x80U;
}

// Độ dài của dãy hợp lệ bắt đầu ở index, hoặc 0 nếu dãy hỏng hay bị cụt.
[[nodiscard]] std::size_t valid_sequence(std::string_view text, std::size_t index) noexcept {
    const auto lead = static_cast<unsigned char>(text.at(index));
    const std::size_t length = sequence_length(lead);
    if (length <= 1) return length;
    if (length > text.size() - index) return 0;
    if (!is_second_valid(lead, static_cast<unsigned char>(text.at(index + 1)))) return 0;
    const std::string_view rest = text.substr(index + 2, length - 2);
    return std::ranges::all_of(rest, is_utf8_continuation) ? length : 0;
}

// Khác gốc: thân vòng lặp của is_valid_utf8 tách ra đây. Chỉ số sau dãy hợp lệ ở index và đoạn
// ASCII theo sau; npos khi dãy hỏng hay bị cụt.
[[nodiscard]] std::size_t next_sequence(std::string_view text, std::size_t index) noexcept {
    const std::size_t length = valid_sequence(text, index);
    if (length == 0) return std::string_view::npos;
    return skip_ascii(text, index + length);
}

} // namespace

bool is_valid_utf8(std::string_view text) noexcept {
    std::size_t index = skip_ascii(text, 0);
    while (index < text.size()) {
        index = next_sequence(text, index);
    }
    // Dãy hợp lệ dừng đúng ở cuối chuỗi; npos của dãy hỏng thì lớn hơn mọi cỡ chuỗi.
    return index == text.size();
}

#if !defined(_WIN32)

namespace {

[[nodiscard]] char32_t point_of(std::string_view bytes) noexcept {
    const auto lead = static_cast<unsigned char>(bytes.front());
    if (bytes.size() == 1) return lead;
    const auto second = static_cast<unsigned char>(bytes[1]);
    if (bytes.size() == 2) {
        const char32_t high = static_cast<char32_t>(lead & 0x1FU) << 6U;
        return high | (second & 0x3FU);
    }
    const auto third = static_cast<unsigned char>(bytes[2]);
    if (bytes.size() == 3) {
        char32_t point = static_cast<char32_t>(lead & 0x0FU) << 12U;
        point |= static_cast<char32_t>(second & 0x3FU) << 6U;
        return point | (third & 0x3FU);
    }
    const auto fourth = static_cast<unsigned char>(bytes[3]);
    char32_t point = static_cast<char32_t>(lead & 0x07U) << 18U;
    point |= static_cast<char32_t>(second & 0x3FU) << 12U;
    point |= static_cast<char32_t>(third & 0x3FU) << 6U;
    return point | (fourth & 0x3FU);
}

[[nodiscard]] char32_t decode_one(std::string_view text, std::size_t index, std::size_t& used) {
    const std::size_t length = valid_sequence(text, index);
    if (length == 0) {
        used = 1;
        return 0xFFFD;
    }
    used = length;
    return point_of(text.substr(index, length));
}

void append_byte(std::string& out, unsigned value) {
    out.push_back(static_cast<char>(value));
}

void append_point(std::string& out, char32_t point) {
    const bool surrogate = point >= 0xD800 && point <= 0xDFFF;
    if (point > 0x10FFFF || surrogate) point = 0xFFFD;
    if (point < 0x80) return append_byte(out, static_cast<unsigned>(point));
    if (point < 0x800) {
        append_byte(out, 0xC0U | (static_cast<unsigned>(point) >> 6U));
        append_byte(out, 0x80U | (static_cast<unsigned>(point) & 0x3FU));
        return;
    }
    if (point < 0x10000) {
        append_byte(out, 0xE0U | (static_cast<unsigned>(point) >> 12U));
        append_byte(out, 0x80U | ((static_cast<unsigned>(point) >> 6U) & 0x3FU));
        append_byte(out, 0x80U | (static_cast<unsigned>(point) & 0x3FU));
        return;
    }
    append_byte(out, 0xF0U | (static_cast<unsigned>(point) >> 18U));
    append_byte(out, 0x80U | ((static_cast<unsigned>(point) >> 12U) & 0x3FU));
    append_byte(out, 0x80U | ((static_cast<unsigned>(point) >> 6U) & 0x3FU));
    append_byte(out, 0x80U | (static_cast<unsigned>(point) & 0x3FU));
}

} // namespace

static_assert(sizeof(wchar_t) == 4, "POSIX wchar_t phải là UTF-32");

std::wstring widen(std::string_view text) {
    if (text.empty()) return {};
    static_cast<void>(checked_size(text.size()));
    std::wstring result;
    result.reserve(text.size());
    std::size_t index = 0;
    while (index < text.size()) {
        std::size_t used = 1;
        const char32_t point = decode_one(text, index, used);
        result.push_back(static_cast<wchar_t>(point));
        index += used;
    }
    return result;
}

std::string narrow(std::wstring_view text) {
    if (text.empty()) return {};
    static_cast<void>(checked_size(text.size()));
    std::string result;
    result.reserve(text.size());
    for (const wchar_t unit : text) {
        append_point(result, static_cast<char32_t>(unit));
    }
    return result;
}

#endif

} // namespace game::core
