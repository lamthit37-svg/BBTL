// Xác suất rơi đồ bằng số nguyên: xem chance.hpp.
#include "loot/chance.hpp"

#include "loot/types.hpp"

#include "dice/dice.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::loot {
namespace {

constexpr std::uint64_t kLimit = std::uint64_t{1} << 62;
constexpr std::uint32_t kFractionDigits = 6;
constexpr std::uint64_t kLow32 = 0xFFFF'FFFFU;

// Số không dấu 128 bit: tích của hai số u64 hay u64 x u32 có thể vượt 64 bit.
struct Wide {
    std::uint64_t hi = 0;
    std::uint64_t lo = 0;
};

constexpr Wide multiply(std::uint64_t a, std::uint64_t b) noexcept {
    const std::uint64_t low_low = (a & kLow32) * (b & kLow32);
    const std::uint64_t low_high = (a & kLow32) * (b >> 32U);
    const std::uint64_t high_low = (a >> 32U) * (b & kLow32);
    const std::uint64_t high_high = (a >> 32U) * (b >> 32U);
    const std::uint64_t middle = (low_low >> 32U) + (low_high & kLow32) + (high_low & kLow32);
    return Wide{.hi = high_high + (low_high >> 32U) + (high_low >> 32U) + (middle >> 32U),
        .lo = (middle << 32U) | (low_low & kLow32)};
}

constexpr void shift_right(Wide& value) noexcept {
    value.lo = (value.lo >> 1U) | (value.hi << 63U);
    value.hi >>= 1U;
}

constexpr bool fits(const Wide& value) noexcept { return value.hi == 0 && value.lo < kLimit; }

// Co num/den (cùng một số bit) cho tới khi cả hai dưới kLimit. Tỉ lệ lớn hơn kLimit (den co về 0) đổi thành số lớn nhất biểu
// diễn được, vì các phép nhân sau còn có thể nhân với hệ số nhỏ hơn 1: kẹp về 1 ở đây sẽ làm sai kết quả. Sai số tuyệt đối
// của tỉ lệ sau khi co dưới 2^-61.
Ratio shrink(Wide num, Wide den) noexcept {
    if ((num.hi == 0 && num.lo == 0) || (den.hi == 0 && den.lo == 0)) return Ratio{.num = 0, .den = 1};
    while (!fits(num) || !fits(den)) {
        shift_right(num);
        shift_right(den);
    }
    if (den.lo == 0) return Ratio{.num = kLimit - 1, .den = 1};
    if (num.lo == 0) return Ratio{.num = 0, .den = 1};
    return Ratio{.num = num.lo, .den = den.lo};
}

// ratio x mul / div với mul và div là u32.
Ratio scale(const Ratio& ratio, std::uint32_t mul, std::uint32_t div) noexcept {
    return shrink(multiply(ratio.num, mul), multiply(ratio.den, div));
}

} // namespace

std::optional<std::uint32_t> parse_ppm(std::string_view text, std::uint32_t max_ppm) noexcept {
    std::uint64_t whole = 0;
    std::size_t pos = 0;
    const auto digit = [&text](std::size_t at) { return at < text.size() && text[at] >= '0' && text[at] <= '9'; };
    const std::uint64_t whole_cap = std::uint64_t{max_ppm} / kPpm + 1;
    if (!digit(pos)) return std::nullopt;
    for (; digit(pos); ++pos) {
        whole = std::min(whole * 10 + static_cast<std::uint64_t>(text[pos] - '0'), whole_cap);
    }
    std::uint64_t fraction = 0;
    if (pos < text.size()) {
        if (text[pos] != '.' || !digit(pos + 1)) return std::nullopt;
        ++pos;
        std::uint32_t used = 0;
        for (; digit(pos); ++pos, ++used) {
            const auto value = static_cast<std::uint64_t>(text[pos] - '0');
            if (used < kFractionDigits) {
                fraction = fraction * 10 + value;
            } else if (value != 0) {
                return std::nullopt;  // phần thập phân mịn hơn phần triệu: bảng đang đòi độ chính xác mà bản này không có
            }
        }
        for (; used < kFractionDigits; ++used) fraction *= 10;
        if (pos != text.size()) return std::nullopt;
    }
    const std::uint64_t total = whole * kPpm + fraction;
    if (whole >= whole_cap || total > max_ppm) return std::nullopt;
    return static_cast<std::uint32_t>(total);
}

Ratio drop_ratio(const DropFactors& factors) noexcept {
    if (factors.monster_value <= 0 || factors.box_value <= 0) return Ratio{};
    Ratio ratio = shrink(Wide{.hi = 0, .lo = static_cast<std::uint64_t>(factors.monster_value)},
        Wide{.hi = 0, .lo = static_cast<std::uint64_t>(factors.box_value)});
    ratio = scale(ratio, factors.gap_ppm, kPpm);
    ratio = scale(ratio, factors.param_ppm, kPpm);
    return scale(ratio, factors.wallow_ppm, kPpm);
}

bool succeeds(const Ratio& ratio, dice::Dice& dice) noexcept {
    return dice.below(std::max<std::uint64_t>(ratio.den, 1)) < ratio.num;
}

} // namespace game::loot
