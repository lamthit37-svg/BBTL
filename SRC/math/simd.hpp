// Phép tính trên __m128 dùng chung cho Vector3, Vector4, Point3, Quat, Matrix — sse/internal.hpp
// của ModifiedSonyMath trong _Ref. Nền là SSE4.1 (mọi CPU x64 từ 2008; Windows 11 đòi SSE4.2). Thứ
// tự cộng của dot3, dot4 giữ như gốc (x + (y + z)) để kết quả khớp từng bit. Khác gốc:
// - sin và sin_cos so số góc phần tư bằng phép so số nguyên. Gốc so mẫu bit số nguyên như float
//   (_mm_cmpeq_ps với 1 và 2, tức số không chuẩn): bật DAZ là chọn nhầm đa thức và sai dấu — gốc
//   chỉ vá riêng cho Xbox và Android;
// - đặt một phần tử bằng _mm_insert_ps hoặc qua mảng, không ép con trỏ __m128 thành float*.
// Nguồn: Forge2 src/math/simd.hpp@d7fcd76. Khác gốc (so với Forge2): không.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <numbers>

#if defined(__aarch64__)
#include "math/sse.hpp"
#else
#include <smmintrin.h>
#endif

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math::simd {

// Dưới ngưỡng cos này slerp nội suy theo cung; từ ngưỡng trở lên (hai vectơ gần trùng) nội suy
// tuyến tính để khỏi chia cho sin gần 0.
inline constexpr float kSlerpTolerance = 0.999F;

[[nodiscard]] inline __m128 bits(std::uint32_t pattern) noexcept {
    return _mm_castsi128_ps(_mm_set1_epi32(static_cast<int>(pattern)));
}

// Mặt nạ bật ba làn x, y, z.
[[nodiscard]] inline __m128 mask_xyz() noexcept {
    return _mm_castsi128_ps(_mm_setr_epi32(-1, -1, -1, 0));
}

template <int Lane>
[[nodiscard]] inline __m128 splat(__m128 v) noexcept {
    return _mm_shuffle_ps(v, v, _MM_SHUFFLE(Lane, Lane, Lane, Lane));
}

// b ở làn có mặt nạ bật, a ở làn còn lại.
[[nodiscard]] inline __m128 select(__m128 a, __m128 b, __m128 mask) noexcept {
    return _mm_or_ps(_mm_and_ps(mask, b), _mm_andnot_ps(mask, a));
}

[[nodiscard]] inline __m128 abs(__m128 v) noexcept {
    return _mm_and_ps(v, bits(0x7FFF'FFFFU));
}

[[nodiscard]] inline __m128 negate(__m128 v) noexcept {
    return _mm_sub_ps(_mm_setzero_ps(), v);
}

// Độ lớn của value, dấu của sign.
[[nodiscard]] inline __m128 copysign(__m128 value, __m128 sign) noexcept {
    const __m128 magnitude = bits(0x7FFF'FFFFU);
    return _mm_or_ps(_mm_and_ps(magnitude, value), _mm_andnot_ps(magnitude, sign));
}

// a.x*b.x + (a.y*b.y + a.z*b.z) ở mọi làn.
[[nodiscard]] inline __m128 dot3(__m128 a, __m128 b) noexcept {
    const __m128 product = _mm_mul_ps(a, b);
    const __m128 yz = _mm_add_ps(splat<1>(product), splat<2>(product));
    return _mm_add_ps(splat<0>(product), yz);
}

// x + (y + (z + w)) ở mọi làn.
[[nodiscard]] inline __m128 dot4(__m128 a, __m128 b) noexcept {
    const __m128 product = _mm_mul_ps(a, b);
    const __m128 zw = _mm_add_ps(splat<2>(product), splat<3>(product));
    const __m128 yzw = _mm_add_ps(splat<1>(product), zw);
    return _mm_add_ps(splat<0>(product), yzw);
}

[[nodiscard]] inline __m128 cross3(__m128 a, __m128 b) noexcept {
    const __m128 a_yzx = _mm_shuffle_ps(a, a, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 b_zxy = _mm_shuffle_ps(b, b, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 a_zxy = _mm_shuffle_ps(a, a, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 b_yzx = _mm_shuffle_ps(b, b, _MM_SHUFFLE(3, 0, 2, 1));
    return _mm_sub_ps(_mm_mul_ps(a_yzx, b_zxy), _mm_mul_ps(a_zxy, b_yzx));
}

// 1/sqrt(v): RSQRTPS rồi một bước Newton-Raphson, sai số tương đối khoảng 2^-22.
[[nodiscard]] inline __m128 rsqrt_nr(__m128 v) noexcept {
    const __m128 estimate = _mm_rsqrt_ps(v);
    const __m128 product = _mm_mul_ps(_mm_mul_ps(v, estimate), estimate);
    const __m128 half = _mm_mul_ps(_mm_set1_ps(0.5F), estimate);
    return _mm_mul_ps(half, _mm_sub_ps(_mm_set1_ps(3.0F), product));
}

[[nodiscard]] inline float lane(__m128 v, std::size_t i) noexcept {
    alignas(16) std::array<float, 4> values{};
    _mm_store_ps(values.data(), v);
    return values.at(i);
}

[[nodiscard]] inline __m128 with_lane(__m128 v, std::size_t i, float value) noexcept {
    alignas(16) std::array<float, 4> values{};
    _mm_store_ps(values.data(), v);
    values.at(i) = value;
    return _mm_load_ps(values.data());
}

template <int Lane>
[[nodiscard]] inline __m128 with_lane(__m128 v, float value) noexcept {
    return _mm_insert_ps(v, _mm_set_ss(value), Lane << 4);
}

// c + a * b.
[[nodiscard]] inline __m128 madd(__m128 a, __m128 b, __m128 c) noexcept {
    return _mm_add_ps(c, _mm_mul_ps(a, b));
}

// acos từng làn, đa thức bậc 7 của Sony; đầu vào trong [-1, 1], sai số tuyệt đối khoảng 2e-7.
[[nodiscard]] inline __m128 acos(__m128 x) noexcept {
    const __m128 x_abs = abs(x);
    const __m128 negative = _mm_cmplt_ps(x, _mm_setzero_ps());
    const __m128 root = _mm_sqrt_ps(_mm_sub_ps(_mm_set1_ps(1.0F), x_abs));
    const __m128 x2 = _mm_mul_ps(x_abs, x_abs);
    const __m128 x4 = _mm_mul_ps(x2, x2);
    __m128 high = madd(_mm_set1_ps(-0.0012624911F), x_abs, _mm_set1_ps(0.0066700901F));
    high = madd(high, x_abs, _mm_set1_ps(-0.0170881256F));
    high = madd(high, x_abs, _mm_set1_ps(0.0308918810F));
    __m128 low = madd(_mm_set1_ps(-0.0501743046F), x_abs, _mm_set1_ps(0.0889789874F));
    low = madd(low, x_abs, _mm_set1_ps(-0.2145988016F));
    low = madd(low, x_abs, _mm_set1_ps(1.5707963050F));
    const __m128 positive_result = _mm_mul_ps(root, madd(high, x4, low));
    const __m128 negative_result = _mm_sub_ps(_mm_set1_ps(std::numbers::pi_v<float>), positive_result);
    return select(positive_result, negative_result, negative);
}

// Phần chung của sin và sin_cos: thu góc về [-pi/4, pi/4] rồi tính cả hai đa thức.
struct Reduced {
    __m128 sine;
    __m128 cosine;
    // Số góc phần tư của từng làn (số nguyên).
    __m128i quadrant;
};

[[nodiscard]] inline Reduced reduce(__m128 x) noexcept {
    constexpr float kTwoOverPi = 0.63661977236F;
    constexpr float kHalfPiHigh = 1.57079625129F;
    constexpr float kHalfPiLow = 7.54978995489e-8F;
    const __m128i quadrant = _mm_cvtps_epi32(_mm_mul_ps(x, _mm_set1_ps(kTwoOverPi)));
    const __m128 turns = _mm_cvtepi32_ps(quadrant);
    const __m128 coarse = _mm_sub_ps(x, _mm_mul_ps(turns, _mm_set1_ps(kHalfPiHigh)));
    const __m128 r = _mm_sub_ps(coarse, _mm_mul_ps(turns, _mm_set1_ps(kHalfPiLow)));
    const __m128 r2 = _mm_mul_ps(r, r);
    const __m128 r3 = _mm_mul_ps(r2, r);
    __m128 cosine = madd(_mm_set1_ps(-0.0013602249F), r2, _mm_set1_ps(0.0416566950F));
    cosine = madd(cosine, r2, _mm_set1_ps(-0.4999990225F));
    cosine = madd(cosine, r2, _mm_set1_ps(1.0F));
    __m128 sine = madd(_mm_set1_ps(-0.0001950727F), r2, _mm_set1_ps(0.0083320758F));
    sine = madd(sine, r2, _mm_set1_ps(-0.1666665247F));
    sine = madd(sine, r3, r);
    return Reduced{.sine = sine, .cosine = cosine, .quadrant = quadrant};
}

// Chọn đa thức theo góc phần tư offset: sin khi chẵn, cos khi lẻ; đổi dấu khi bit 1 bật.
[[nodiscard]] inline __m128 pick(const Reduced& reduced, __m128i offset) noexcept {
    const __m128i zero = _mm_setzero_si128();
    const __m128i even = _mm_cmpeq_epi32(_mm_and_si128(offset, _mm_set1_epi32(1)), zero);
    const __m128i keep = _mm_cmpeq_epi32(_mm_and_si128(offset, _mm_set1_epi32(2)), zero);
    const __m128 value = select(reduced.cosine, reduced.sine, _mm_castsi128_ps(even));
    return select(negate(value), value, _mm_castsi128_ps(keep));
}

// sin từng làn, sai số tuyệt đối khoảng 1e-6 với |x| tới vài nghìn radian.
[[nodiscard]] inline __m128 sin(__m128 x) noexcept {
    const Reduced reduced = reduce(x);
    return pick(reduced, reduced.quadrant);
}

struct SinCos {
    __m128 sine;
    __m128 cosine;
};

[[nodiscard]] inline SinCos sin_cos(__m128 x) noexcept {
    const Reduced reduced = reduce(x);
    const __m128i shifted = _mm_add_epi32(reduced.quadrant, _mm_set1_epi32(1));
    return SinCos{.sine = pick(reduced, reduced.quadrant), .cosine = pick(reduced, shifted)};
}

// Hệ số của a và b khi nội suy cầu tại t (ở mọi làn), biết cos góc giữa hai vectơ đơn vị.
struct SlerpScales {
    __m128 first;
    __m128 second;
};

[[nodiscard]] inline SlerpScales slerp_scales(__m128 cos_angle, float t) noexcept {
    const __m128 curved = _mm_cmpgt_ps(_mm_set1_ps(kSlerpTolerance), cos_angle);
    const __m128 angle = acos(cos_angle);
    const __m128 tttt = _mm_set1_ps(t);
    const __m128 one_minus_t = _mm_sub_ps(_mm_set1_ps(1.0F), tttt);
    // angles = (1, 1 - t, t, 1 - t) * angle
    const __m128 one_t = _mm_unpacklo_ps(_mm_set1_ps(1.0F), tttt);
    const __m128 angles = _mm_mul_ps(_mm_unpacklo_ps(one_t, one_minus_t), angle);
    const __m128 sines = sin(angles);
    const __m128 scales = _mm_div_ps(sines, splat<0>(sines));
    return SlerpScales{
        .first = select(one_minus_t, splat<1>(scales), curved),
        .second = select(tttt, splat<2>(scales), curved),
    };
}

} // namespace game::math::simd
// NOLINTEND(readability-identifier-length)
