#pragma once
// Số học nguyên của công thức chiến đấu: làm tròn đúng kiểu Float2Int của GameServer 2008 và kẹp
// không tràn. Cả công thức gốc dùng float; actor tính bằng số nguyên chính xác để cùng đầu vào luôn
// ra cùng kết quả trên mọi nền tảng (không phụ thuộc làm tròn của FPU).
//
// Nguồn: Common/GameUtil.h Float2Int. Khác gốc: tử và mẫu là số nguyên 64 bit thay vì float; kết quả
// khác bản float chỉ ở các thương rất lớn (trên 2^24) nơi float đã mất chữ số.

#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <span>

namespace game::actor {

// Phần tử `index` của mảng, chỉ số lúc chạy. std::array::operator[] với chỉ số không hằng bị
// cppcoreguidelines-pro-bounds-constant-array-index từ chối; qua std::span thì kiểm biên nằm ở chế độ
// hardening của thư viện chuẩn (đã bật ở mọi preset). Tiền điều kiện: index < N.
template <typename T, std::size_t N>
[[nodiscard]] constexpr T& slot(std::array<T, N>& array, std::size_t index) noexcept {
    return std::span<T, N>{array}[index];
}

template <typename T, std::size_t N>
[[nodiscard]] constexpr const T& slot(const std::array<T, N>& array, std::size_t index) noexcept {
    return std::span<const T, N>{array}[index];
}

// Mảng đánh chỉ số bằng enum (Stat, AttrId, BaseInfo): nơi dùng viết a[Stat::kMaxHp], không phải ép kiểu.
// Tiền điều kiện: giá trị enum < N (mọi enum dùng ở đây có hằng đếm tương ứng và static_assert).
template <typename Key, typename Value, std::size_t N>
class EnumArray {
public:
    [[nodiscard]] constexpr Value& operator[](Key key) noexcept { return slot(items_, static_cast<std::size_t>(key)); }
    [[nodiscard]] constexpr const Value& operator[](Key key) const noexcept {
        return slot(items_, static_cast<std::size_t>(key));
    }

    friend constexpr bool operator==(const EnumArray&, const EnumArray&) noexcept = default;

private:
    std::array<Value, N> items_{};
};

// Float2Int(n / d) với d > 0: phần thập phân dưới 0,5 thì bỏ, từ 0,5 thì lên một; số âm luôn cắt về 0
// (bản gốc: iValue = (int)v, hiệu v - iValue <= 0 < 0,5 nên trả iValue). d <= 0 trả 0.
[[nodiscard]] constexpr std::int64_t round_ratio(std::int64_t n, std::int64_t d) noexcept {
    if (d <= 0) return 0;
    if (n < 0) return n / d;
    const std::int64_t q = n / d;
    const std::int64_t r = n % d;
    return (r > d - r - 1) ? q + 1 : q; // 2r >= d, viết không nhân đôi để khỏi tràn
}

[[nodiscard]] constexpr std::int32_t saturate32(std::int64_t value) noexcept {
    constexpr auto kMax = static_cast<std::int64_t>(std::numeric_limits<std::int32_t>::max());
    constexpr auto kMin = static_cast<std::int64_t>(std::numeric_limits<std::int32_t>::min());
    if (value > kMax) return std::numeric_limits<std::int32_t>::max();
    if (value < kMin) return std::numeric_limits<std::int32_t>::min();
    return static_cast<std::int32_t>(value);
}

// Float2Int(n / d) đã kẹp về int32.
[[nodiscard]] constexpr std::int32_t round_ratio32(std::int64_t n, std::int64_t d) noexcept {
    return saturate32(round_ratio(n, d));
}

[[nodiscard]] constexpr std::int32_t clamp32(std::int64_t value, std::int32_t low, std::int32_t high) noexcept {
    if (value < low) return low;
    if (value > high) return high;
    return static_cast<std::int32_t>(value);
}

} // namespace game::actor
