#pragma once
// Kiểu của billing. Tiền là số nguyên có kiểu, không số thực (KE-HOACH-SERVER mục 1): điểm nạp tính
// theo phần mười (0,1 điểm) vì client 2026 hiển thị số dư bằng Get_XParam_UINT / 10 với một chữ số thập
// phân (YuanbaoExchange.lua, sự kiện UI_COMMAND 2003), nên "10" trong dữ liệu là 1,0 điểm. Ingot là số
// nguyên đếm.
//
// Id lấy từ cột bigint của PostgreSQL nên luôn nằm trong [1, kIdMax]; bộ giải mã của dây từ chối giá
// trị ngoài miền đó trước khi chạm tới database.

#include "ids/ids.hpp"

#include <cstdint>
#include <limits>
#include <optional>

namespace game::billing {

using Points = ids::StrongId<struct PointsTag, std::int64_t>;
using Ingot = ids::StrongId<struct IngotTag, std::int64_t>;
using UnixTime = ids::StrongId<struct UnixTimeTag, std::int64_t>;

using AccountId = ids::AccountId;
using CharacterId = ids::CharacterId;
using PaymentId = ids::StrongId<struct PaymentTag, std::uint64_t>;
using ExchangeId = ids::StrongId<struct ExchangeTag, std::uint64_t>;
using GrantId = ids::StrongId<struct GrantTag, std::uint64_t>;
using GrantOrderId = ids::StrongId<struct GrantOrderTag, std::uint64_t>;
using BatchId = ids::StrongId<struct BatchTag, std::uint64_t>;
using CodeId = ids::StrongId<struct CodeTag, std::uint64_t>;
// Số do bên gọi (world) cấp cho mỗi lần xin đổi, để gọi lại sau khi mạng đứt không tạo đơn thứ hai.
using RequestId = ids::StrongId<struct RequestTag, std::uint64_t>;

// Số phần mười trong một điểm.
inline constexpr std::int64_t kTenthsPerPoint = 10;
// Giây trong một ngày UTC: ranh giới "ngày" của hạn mức tiêu và đối soát ngày.
inline constexpr std::int64_t kSecondsPerDay = 86400;
// Trần id: nhỏ hơn int64 tối đa một khoảng để cộng một vẫn vừa bigint.
inline constexpr std::uint64_t kIdMax = std::uint64_t{1} << 62U;

[[nodiscard]] constexpr bool id_ok(std::uint64_t value) noexcept {
    return value >= 1 && value <= kIdMax;
}

// Cộng không tràn: nullopt khi vượt int64.
[[nodiscard]] constexpr std::optional<std::int64_t> add_checked(std::int64_t left, std::int64_t right) noexcept {
    constexpr std::int64_t kMax = std::numeric_limits<std::int64_t>::max();
    constexpr std::int64_t kMin = std::numeric_limits<std::int64_t>::min();
    if (right > 0 && left > kMax - right) return std::nullopt;
    if (right < 0 && left < kMin - right) return std::nullopt;
    return left + right;
}

// Nhân không tràn, cả hai thừa số không âm.
[[nodiscard]] constexpr std::optional<std::int64_t> multiply_checked(std::int64_t left, std::int64_t right) noexcept {
    if (left < 0 || right < 0) return std::nullopt;
    if (left == 0 || right == 0) return std::int64_t{0};
    if (left > std::numeric_limits<std::int64_t>::max() / right) return std::nullopt;
    return left * right;
}

// Ngày UTC (số ngày từ 1970-01-01) của một mốc; mốc âm không có ngày.
[[nodiscard]] constexpr std::optional<std::int64_t> day_of(UnixTime when) noexcept {
    if (when.value() < 0) return std::nullopt;
    return when.value() / kSecondsPerDay;
}

} // namespace game::billing
