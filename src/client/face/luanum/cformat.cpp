#include "luanum/cformat.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::luanum {
namespace {

// Số chữ số có nghĩa mà CRT sinh ra trước khi làm tròn về độ chính xác cần in.
constexpr int kSignificantDigits = 17;
constexpr int kDefaultPrecision = 6;
constexpr int kExponentWidth = 3;

// Giá trị = 0.text × 10^point. Vô cực và NaN dùng chuỗi chữ số giả của CRT. text rỗng là số không đã làm tròn.
struct Digits {
    std::string text;
    int point = 0;
    bool zero = false;
};

[[nodiscard]] Digits digits_of(double value) {
    Digits digits;
    if (std::isnan(value)) {
        digits.text = std::signbit(value) ? "1#IND" : "1#QNAN";
        digits.point = 1;
        return digits;
    }
    if (std::isinf(value)) {
        digits.text = "1#INF";
        digits.point = 1;
        return digits;
    }
    const double magnitude = std::fabs(value);
    if (magnitude == 0.0) {
        digits.text = "0";
        digits.zero = true;
        return digits;
    }
    // "d.dddddddddddddddde+XX": 1 + 16 chữ số, rồi số mũ thập phân.
    std::array<char, 40> buffer{};
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): to_chars nhận cặp con trỏ đầu-cuối.
    char* const buffer_end = buffer.data() + buffer.size();
    const auto result = std::to_chars(buffer.data(), buffer_end, magnitude, std::chars_format::scientific, kSignificantDigits - 1);
    const std::string_view text(buffer.data(), static_cast<std::size_t>(result.ptr - buffer.data()));
    const std::size_t mark = text.find('e');
    digits.text.push_back(text[0]);
    digits.text.append(text.substr(2, mark - 2));
    int exponent = 0;
    const std::string_view exponent_text = text.substr(mark + 1);
    const std::string_view unsigned_part = exponent_text.substr(1);
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
    static_cast<void>(std::from_chars(unsigned_part.data(), unsigned_part.data() + unsigned_part.size(), exponent));
    digits.point = (exponent_text[0] == '-' ? -exponent : exponent) + 1;
    return digits;
}

[[nodiscard]] char digit_at(const Digits& digits, int index) noexcept {
    if (index < 0 || static_cast<std::size_t>(index) >= digits.text.size()) return '0';
    return digits.text[static_cast<std::size_t>(index)];
}

// _fptostr của CRT: giữ keep chữ số đầu, tăng chữ số cuối nếu chữ số kế >= '5'. Chữ số giả (ký tự không phải số)
// tăng như mã ký tự, nên "1#IN" làm tròn thành "1#IO".
void round_at(Digits& digits, int keep) {
    const auto size = static_cast<int>(digits.text.size());
    if (keep >= size) return;
    if (keep < 0) {
        digits.text.clear();
        digits.point = 0;
        return;
    }
    const bool up = digits.text[static_cast<std::size_t>(keep)] >= '5';
    digits.text.resize(static_cast<std::size_t>(keep));
    if (!up) {
        if (keep == 0) digits.point = 0;
        return;
    }
    int at = keep - 1;
    while (at >= 0 && digits.text[static_cast<std::size_t>(at)] == '9') {
        digits.text[static_cast<std::size_t>(at)] = '0';
        --at;
    }
    if (at < 0) {
        digits.text.insert(0, 1, '1');
        ++digits.point;
    } else {
        ++digits.text[static_cast<std::size_t>(at)];
    }
}

// Bỏ các số không cuối của phần thập phân, rồi dấu chấm nếu không còn gì sau nó (%g không có cờ '#').
void strip_fraction_zeros(std::string& text) {
    if (text.find('.') == std::string::npos) return;
    while (text.back() == '0')
        text.pop_back();
    if (text.back() == '.') text.pop_back();
}

[[nodiscard]] std::string render_fixed(const Digits& digits, int precision, bool alternate) {
    std::string text;
    if (digits.point <= 0) {
        text.push_back('0');
    } else {
        for (int i = 0; i < digits.point; ++i)
            text.push_back(digit_at(digits, i));
    }
    if (precision > 0 || alternate) text.push_back('.');
    for (int j = 0; j < precision; ++j)
        text.push_back(digit_at(digits, digits.point + j));
    return text;
}

[[nodiscard]] std::string render_scientific(const Digits& digits, int precision, bool alternate, bool upper) {
    std::string text;
    text.push_back(digit_at(digits, 0));
    if (precision > 0 || alternate) text.push_back('.');
    for (int i = 1; i <= precision; ++i)
        text.push_back(digit_at(digits, i));
    return text + (upper ? "E" : "e");
}

[[nodiscard]] std::string exponent_suffix(int exponent) {
    const std::string text(1, exponent < 0 ? '-' : '+');
    std::string number = std::to_string(exponent < 0 ? -exponent : exponent);
    if (number.size() < static_cast<std::size_t>(kExponentWidth)) number.insert(0, static_cast<std::size_t>(kExponentWidth) - number.size(), '0');
    return text + number;
}

// Đệm sign + body tới độ rộng: trái, số không chen giữa dấu và thân, hoặc phải.
[[nodiscard]] std::string pad(std::string_view sign, std::string_view body, const FormatSpec& spec, bool zero_pad) {
    const std::size_t used = sign.size() + body.size();
    const auto width = static_cast<std::size_t>(std::max(spec.width, 0));
    std::string text;
    if (used >= width) {
        text.append(sign).append(body);
    } else if (spec.left) {
        text.append(sign).append(body).append(width - used, ' ');
    } else if (zero_pad) {
        text.append(sign).append(width - used, '0').append(body);
    } else {
        text.append(width - used, ' ').append(sign).append(body);
    }
    return text;
}

[[nodiscard]] std::string_view sign_of(bool negative, const FormatSpec& spec) noexcept {
    if (negative) return "-";
    if (spec.sign) return "+";
    return spec.blank ? " " : "";
}

[[nodiscard]] std::string cut_at_nul(std::string text) {
    text.resize(std::min(text.size(), text.find('\0')));
    return text;
}

[[nodiscard]] std::string integer_digits(std::uint64_t magnitude, int base, bool upper, const FormatSpec& spec) {
    std::string digits;
    if (spec.precision == 0 && magnitude == 0) return digits;
    constexpr std::string_view kLower = "0123456789abcdef";
    constexpr std::string_view kUpper = "0123456789ABCDEF";
    const std::string_view alphabet = upper ? kUpper : kLower;
    do {
        digits.insert(digits.begin(), alphabet[magnitude % static_cast<std::uint64_t>(base)]);
        magnitude /= static_cast<std::uint64_t>(base);
    } while (magnitude != 0);
    if (spec.precision > 0 && digits.size() < static_cast<std::size_t>(spec.precision))
        digits.insert(0, static_cast<std::size_t>(spec.precision) - digits.size(), '0');
    return digits;
}

} // namespace

std::string format_double(char conversion, const FormatSpec& spec, double value) {
    const bool negative = std::signbit(value);
    const bool upper = conversion == 'E' || conversion == 'G';
    const int precision = spec.precision < 0 ? kDefaultPrecision : spec.precision;
    Digits digits = digits_of(value);
    std::string body;
    switch (conversion) {
    case 'f':
        round_at(digits, digits.point + precision);
        body = render_fixed(digits, precision, spec.alternate);
        break;
    case 'e':
    case 'E': {
        round_at(digits, precision + 1);
        const int exponent = digits.zero ? 0 : digits.point - 1;
        body = render_scientific(digits, precision, spec.alternate, upper) + exponent_suffix(exponent);
        break;
    }
    default: {
        const int significant = std::max(precision, 1);
        round_at(digits, significant);
        const int exponent = digits.point - 1;
        if (exponent < -4 || exponent >= significant) {
            std::string mantissa = render_scientific(digits, significant - 1, spec.alternate, upper);
            const std::string tail = mantissa.substr(mantissa.size() - 1) + exponent_suffix(exponent);
            mantissa.pop_back();
            if (!spec.alternate) strip_fraction_zeros(mantissa);
            body = mantissa + tail;
        } else {
            body = render_fixed(digits, significant - 1 - exponent, spec.alternate);
            if (!spec.alternate) strip_fraction_zeros(body);
        }
        break;
    }
    }
    return pad(sign_of(negative, spec), body, spec, spec.zero);
}

std::string format_signed(const FormatSpec& spec, std::int32_t value) {
    const bool negative = value < 0;
    const std::uint64_t magnitude = negative ? static_cast<std::uint64_t>(-static_cast<std::int64_t>(value)) : static_cast<std::uint64_t>(value);
    return pad(sign_of(negative, spec), integer_digits(magnitude, 10, false, spec), spec, spec.zero && spec.precision < 0);
}

std::string format_unsigned(char conversion, const FormatSpec& spec, std::uint32_t value) {
    const int base = conversion == 'o' ? 8 : (conversion == 'u' ? 10 : 16);
    std::string digits = integer_digits(value, base, conversion == 'X', spec);
    std::string_view prefix;
    if (spec.alternate && conversion == 'o' && (digits.empty() || digits.front() != '0')) prefix = "0";
    if (spec.alternate && (conversion == 'x' || conversion == 'X') && value != 0) prefix = conversion == 'x' ? "0x" : "0X";
    return pad(prefix, digits, spec, spec.zero && spec.precision < 0);
}

std::string format_char(const FormatSpec& spec, std::int32_t value) {
    const std::string body(1, static_cast<char>(static_cast<std::uint8_t>(static_cast<std::uint32_t>(value) & 0xFFU)));
    return cut_at_nul(pad("", body, spec, spec.zero));
}

std::string format_text(const FormatSpec& spec, std::string_view text) {
    std::string_view shown = text.substr(0, text.find('\0'));
    if (spec.precision >= 0) shown = shown.substr(0, static_cast<std::size_t>(spec.precision));
    return pad("", shown, spec, spec.zero);
}

} // namespace game::luanum
