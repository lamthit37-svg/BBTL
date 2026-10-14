#pragma once
// Phép nhân có kiểm tràn cho tiền: __builtin_mul_overflow không có ở MSVC nên viết tay, chỉ cho số không âm.

#include <cstdint>
#include <limits>
#include <optional>

namespace game::item::detail {

// a*b khi cả hai không âm và tích vừa int64; ngược lại nullopt.
[[nodiscard]] constexpr std::optional<std::int64_t> checked_mul(std::int64_t a, std::int64_t b) noexcept {
    if (a < 0 || b < 0) return std::nullopt;
    if (a != 0 && b > std::numeric_limits<std::int64_t>::max() / a) return std::nullopt;
    return a * b;
}

} // namespace game::item::detail
