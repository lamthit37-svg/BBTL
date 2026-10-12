// Hằng và hàm vô hướng — phần "float operations" của common.hpp trong ModifiedSonyMath của _Ref.
// Giữ nguyên toán tử của gốc ở lerp, cerp, s_curve, smoothstep. Khác gốc:
// - một quy ước lerp(a, b, t) duy nhất; gốc có cả lerp(t, a, b) của Sony lẫn lerp(u, v, x), và
//   chính noise của gốc gọi nhầm thứ tự;
// - các hàm luỹ thừa 2 của gốc lặp vô hạn khi x > 2^31 (biến đếm tràn về 0), ở đây dùng <bit>;
// - round_up của gốc chia cho 0 khi multiple = 0 và tràn khi value + multiple - 1 vượt trần;
// - clamp, min, max, abs vô hướng dùng thẳng STL (std::clamp, std::min, std::max, std::abs).
// Nguồn: Forge2 src/math/scalar.hpp@d7fcd76. Khác gốc (so với Forge2): NOLINT
// bugprone-easily-swappable-parameters kèm lý do cho cerp.
#pragma once

#include "core/check.hpp"

#include <bit>
#include <cmath>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <span>

#if defined(__aarch64__)
#include "math/sse.hpp"
#else
#include <xmmintrin.h>
#endif

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

inline constexpr float kPi = std::numbers::pi_v<float>;
inline constexpr float kTwoPi = 2.0F * kPi;
inline constexpr float kHalfPi = 0.5F * kPi;

[[nodiscard]] constexpr float radians(float degrees) noexcept {
    return degrees * kPi / 180.0F;
}

[[nodiscard]] constexpr float degrees(float radians) noexcept {
    return radians * 180.0F / kPi;
}

// a khi t = 0, b khi t = 1; không kẹp t.
[[nodiscard]] constexpr float lerp(float a, float b, float t) noexcept {
    return a + (t * (b - a));
}

// Nội suy bậc ba qua bốn mốc u0..u3, t trong [0, 1] chạy từ u1 tới u2.
// Các mốc rồi t đứng cuối, cùng quy ước với lerp(a, b, t) (ngoại lệ của API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] constexpr float cerp(float u0, float u1, float u2, float u3, float t) noexcept {
    const float p = (u3 - u2) - (u0 - u1);
    const float q = (u0 - u1) - p;
    const float r = u2 - u0;
    return (t * ((t * ((t * p) + q)) + r)) + u1;
}

// 1, -1, hoặc 0 khi v bằng 0 (và khi v là NaN).
[[nodiscard]] constexpr float sign(float v) noexcept {
    if (v > 0.0F) return 1.0F;
    return v < 0.0F ? -1.0F : 0.0F;
}

// Kẹp vào [0, 1]; NaN cho 0 (phép so sánh đầu sai với NaN), để lượng tử hoá ở packing.hpp không
// bao giờ ép một NaN sang số nguyên.
[[nodiscard]] constexpr float saturate(float x) noexcept {
    if (!(x > 0.0F)) return 0.0F;
    return x < 1.0F ? x : 1.0F;
}

[[nodiscard]] constexpr float sqr(float x) noexcept {
    return x * x;
}

// Đường cong Hermite 3t^2 - 2t^3, không kẹp t.
[[nodiscard]] constexpr float s_curve(float t) noexcept {
    return t * t * (3.0F - (2.0F * t));
}

// 0 dưới edge0, 1 từ edge1 trở lên, Hermite ở giữa. edge0 = edge1 không chia cho 0: hai nhánh đầu
// đã phủ mọi x.
[[nodiscard]] constexpr float smoothstep(float edge0, float edge1, float x) noexcept {
    if (x < edge0) return 0.0F;
    if (x >= edge1) return 1.0F;
    return s_curve((x - edge0) / (edge1 - edge0));
}

// sin(x)/x, bằng 1 tại 0.
[[nodiscard]] inline float sinc(float x) noexcept {
    return x == 0.0F ? 1.0F : std::sin(x) / x;
}

// x làm tròn về số nguyên gần nhất khi cách nó dưới tolerance, không thì giữ nguyên (intAdjustf).
[[nodiscard]] inline float snap(float x, float tolerance = 0.01F) noexcept {
    const float rounded = std::round(x);
    return std::abs(rounded - x) < tolerance ? rounded : x;
}

// 1/sqrt(v) ước lượng bằng RSQRTSS, sai số tương đối tối đa 1,5 * 2^-12; dùng khi độ chính xác
// không quan trọng. Cần đúng thì 1 / std::sqrt(v).
[[nodiscard]] inline float rsqrt_estimate(float v) noexcept {
    return _mm_cvtss_f32(_mm_rsqrt_ss(_mm_set_ss(v)));
}

// Luỹ thừa 2 gần x nhất, nghiêng về số nhỏ khi x dưới 3/4 luỹ thừa trên (getClosestPowerOfTwo).
// 0 cho 0; trên 2^31 trả 2^31, luỹ thừa lớn nhất vừa 32 bit. Luỹ thừa trên và dưới dùng thẳng
// std::bit_ceil và std::bit_floor; kiểm luỹ thừa 2 dùng std::has_single_bit (sai với 0, khác
// isPowerOf2 của gốc trả đúng cho 0).
[[nodiscard]] constexpr std::uint32_t closest_pow2(std::uint32_t x) noexcept {
    constexpr std::uint32_t kTop = 0x8000'0000U;
    if (x > kTop) return kTop;
    const std::uint32_t upper = std::bit_ceil(x);
    const bool nearer_lower = 4ULL * x < 3ULL * upper;
    return nearer_lower ? upper >> 1U : upper;
}

// Bội của multiple nhỏ nhất không dưới value. multiple phải khác 0 và kết quả phải vừa kiểu: vi
// phạm dừng chương trình ở mọi cấu hình (gốc chia cho 0 và tràn im lặng).
template <std::unsigned_integral T>
[[nodiscard]] constexpr T round_up(T value, T multiple) noexcept {
    core::check(multiple != 0, "round_up: multiple bằng 0");
    const T rest = value % multiple;
    if (rest == 0) return value;
    const T step = multiple - rest;
    core::check(value <= static_cast<T>(~T{0}) - step, "round_up: tràn kiểu");
    return value + step;
}

// Bội của multiple lớn nhất không vượt value. multiple phải khác 0.
template <std::unsigned_integral T>
[[nodiscard]] constexpr T round_down(T value, T multiple) noexcept {
    core::check(multiple != 0, "round_down: multiple bằng 0");
    return value - (value % multiple);
}

// Băm FNV-1 32 bit trên từng phần tử (tf_mem_hash của gốc): nhân trước rồi mới xor, kết quả như
// nhau trên mọi nền vì trạng thái luôn là 32 bit. previous để băm nối nhiều đoạn.
template <std::integral T>
[[nodiscard]] constexpr std::uint32_t fnv1_hash(std::span<const T> items,
    std::uint32_t previous = 2166136261U) noexcept {
    constexpr std::uint32_t kPrime = 16777619U;
    std::uint32_t result = previous;
    for (const T item : items) {
        result = (result * kPrime) ^ static_cast<std::uint32_t>(item);
    }
    return result;
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
