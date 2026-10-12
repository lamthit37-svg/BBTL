// Quaternion (x, y, z, w) trên một __m128 — sse/quaternion.hpp của ModifiedSonyMath trong _Ref.
// Phép nhân và rotate giữ đúng thứ tự phép tính của gốc. Khác gốc:
// - normalize chia cho căn chính xác; gốc nhân với RSQRTPS trần, sai số 3e-4 nên quaternion "đơn
//   vị" làm ma trận quay co giãn;
// - rotation(unit0, unit1) cũng dùng căn chính xác thay RSQRTPS;
// - góc vô hướng tính bằng std::sin, std::cos thay đa thức xấp xỉ;
// - slerp, squad, lerp nhận t ở cuối.
// Nguồn: Forge2 src/math/quat.hpp@d7fcd76. Khác gốc (so với Forge2): không.
#pragma once

#include "math/vector.hpp"

#include <cmath>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

class Matrix3;

class Quat {
public:
    // Quaternion 0, không phải đơn vị; phép quay "không làm gì" là identity().
    Quat() noexcept = default;
    Quat(float x, float y, float z, float w) noexcept : value_(_mm_setr_ps(x, y, z, w)) {}
    Quat(const Vector3& xyz, float w) noexcept : value_(simd::with_lane<3>(xyz.simd(), w)) {}
    explicit Quat(const Vector4& vector) noexcept : value_(vector.simd()) {}
    explicit Quat(float scalar) noexcept : value_(_mm_set1_ps(scalar)) {}
    explicit Quat(__m128 value) noexcept : value_(value) {}
    // Từ ma trận quay thuần (trực chuẩn, định thức 1); định nghĩa ở math/matrix.hpp.
    explicit Quat(const Matrix3& rotation) noexcept;

    [[nodiscard]] __m128 simd() const noexcept { return value_; }

    [[nodiscard]] float x() const noexcept { return _mm_cvtss_f32(value_); }
    [[nodiscard]] float y() const noexcept { return _mm_cvtss_f32(simd::splat<1>(value_)); }
    [[nodiscard]] float z() const noexcept { return _mm_cvtss_f32(simd::splat<2>(value_)); }
    [[nodiscard]] float w() const noexcept { return _mm_cvtss_f32(simd::splat<3>(value_)); }
    [[nodiscard]] float operator[](std::size_t i) const noexcept { return simd::lane(value_, i); }
    [[nodiscard]] Vector3 xyz() const noexcept { return Vector3(value_); }

    Quat& set_x(float x) noexcept { return assign(simd::with_lane<0>(value_, x)); }
    Quat& set_y(float y) noexcept { return assign(simd::with_lane<1>(value_, y)); }
    Quat& set_z(float z) noexcept { return assign(simd::with_lane<2>(value_, z)); }
    Quat& set_w(float w) noexcept { return assign(simd::with_lane<3>(value_, w)); }
    Quat& set(std::size_t i, float v) noexcept { return assign(simd::with_lane(value_, i, v)); }
    Quat& set_xyz(const Vector3& xyz) noexcept { return assign(simd::select(value_, xyz.simd(), simd::mask_xyz())); }

    Quat& operator+=(const Quat& b) noexcept { return assign(_mm_add_ps(value_, b.value_)); }
    Quat& operator-=(const Quat& b) noexcept { return assign(_mm_sub_ps(value_, b.value_)); }
    Quat& operator*=(float s) noexcept { return assign(_mm_mul_ps(value_, _mm_set1_ps(s))); }
    Quat& operator/=(float s) noexcept { return assign(_mm_div_ps(value_, _mm_set1_ps(s))); }
    Quat& operator*=(const Quat& b) noexcept;

    [[nodiscard]] static Quat identity() noexcept { return {0.0F, 0.0F, 0.0F, 1.0F}; }
    // Phép quay ngắn nhất đưa unit0 tới unit1 (hai vectơ đơn vị). Hai vectơ đối nhau cho NaN:
    // trường hợp đó dùng from_vectors.
    [[nodiscard]] static Quat rotation(const Vector3& unit0, const Vector3& unit1) noexcept;
    // Quay radians quanh trục đơn vị.
    [[nodiscard]] static Quat rotation(float radians, const Vector3& unit_axis) noexcept;
    [[nodiscard]] static Quat rotation_x(float radians) noexcept;
    [[nodiscard]] static Quat rotation_y(float radians) noexcept;
    [[nodiscard]] static Quat rotation_z(float radians) noexcept;
    // Phép quay ngắn nhất đưa from tới to, không cần đơn vị; hai vectơ đối nhau quay 180 độ quanh
    // một trục vuông góc bất kỳ, một vectơ gần 0 cho identity.
    [[nodiscard]] static Quat from_vectors(const Vector3& from, const Vector3& to) noexcept;
    // Từ trục đơn vị và cos của góc quay (góc trong [0, pi]).
    [[nodiscard]] static Quat from_axis_cos(const Vector3& unit_axis, float cos_angle) noexcept;

private:
    Quat& assign(__m128 value) noexcept {
        value_ = value;
        return *this;
    }

    __m128 value_ = _mm_setzero_ps();
};

[[nodiscard]] inline Quat operator+(const Quat& a, const Quat& b) noexcept {
    return Quat(_mm_add_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Quat operator-(const Quat& a, const Quat& b) noexcept {
    return Quat(_mm_sub_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Quat operator-(const Quat& a) noexcept {
    return Quat(simd::negate(a.simd()));
}

[[nodiscard]] inline Quat operator*(const Quat& a, float s) noexcept {
    return Quat(_mm_mul_ps(a.simd(), _mm_set1_ps(s)));
}

[[nodiscard]] inline Quat operator*(float s, const Quat& a) noexcept {
    return a * s;
}

[[nodiscard]] inline Quat operator/(const Quat& a, float s) noexcept {
    return Quat(_mm_div_ps(a.simd(), _mm_set1_ps(s)));
}

[[nodiscard]] inline bool operator==(const Quat& a, const Quat& b) noexcept {
    return _mm_movemask_ps(_mm_cmpeq_ps(a.simd(), b.simd())) == 0xF;
}

// Tích Hamilton: (a * b) quay b trước rồi a.
[[nodiscard]] inline Quat operator*(const Quat& a, const Quat& b) noexcept {
    const __m128 l = a.simd();
    const __m128 r = b.simd();
    const __m128 l_yzx = _mm_shuffle_ps(l, l, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 r_zxy = _mm_shuffle_ps(r, r, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 l_zxy = _mm_shuffle_ps(l, l, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 r_yzx = _mm_shuffle_ps(r, r, _MM_SHUFFLE(3, 0, 2, 1));
    __m128 xyz = _mm_mul_ps(simd::splat<3>(l), r);
    xyz = simd::madd(simd::splat<3>(r), l, xyz);
    xyz = simd::madd(l_yzx, r_zxy, xyz);
    xyz = _mm_sub_ps(xyz, _mm_mul_ps(l_zxy, r_yzx));
    // w = (lw*rw - lz*rz) - (ly*ry + lx*rx)
    const __m128 product = _mm_mul_ps(l, r);
    const __m128 ww_zz = _mm_sub_ps(simd::splat<3>(product), simd::splat<2>(product));
    const __m128 yy_xx = _mm_add_ps(simd::splat<1>(product), simd::splat<0>(product));
    return Quat(_mm_blend_ps(xyz, _mm_sub_ps(ww_zz, yy_xx), 0b1000));
}

inline Quat& Quat::operator*=(const Quat& b) noexcept {
    return *this = *this * b;
}

// Sang kiểu lưu trữ (x, y, z, w); chiều ngược lại là Quat(load(f)).
[[nodiscard]] inline Float4 store(const Quat& q) noexcept {
    return store(Vector4(q.simd()));
}

[[nodiscard]] inline Quat conj(const Quat& q) noexcept {
    const __m128 flip = _mm_castsi128_ps(_mm_setr_epi32(static_cast<int>(0x8000'0000U), static_cast<int>(0x8000'0000U),
        static_cast<int>(0x8000'0000U), 0));
    return Quat(_mm_xor_ps(q.simd(), flip));
}

[[nodiscard]] inline float dot(const Quat& a, const Quat& b) noexcept {
    return _mm_cvtss_f32(simd::dot4(a.simd(), b.simd()));
}

// Bình phương độ dài.
[[nodiscard]] inline float norm(const Quat& q) noexcept {
    return dot(q, q);
}

[[nodiscard]] inline float length(const Quat& q) noexcept {
    return _mm_cvtss_f32(_mm_sqrt_ps(simd::dot4(q.simd(), q.simd())));
}

[[nodiscard]] inline Quat normalize(const Quat& q) noexcept {
    return Quat(_mm_div_ps(q.simd(), _mm_sqrt_ps(simd::dot4(q.simd(), q.simd()))));
}

[[nodiscard]] inline Quat inverse(const Quat& q) noexcept {
    return conj(q) * (1.0F / dot(q, q));
}

// Quay vectơ bằng quaternion đơn vị: q * v * conj(q).
[[nodiscard]] inline Vector3 rotate(const Quat& unit, const Vector3& vector) noexcept {
    const __m128 q = unit.simd();
    const __m128 v = vector.simd();
    const __m128 q_yzx = _mm_shuffle_ps(q, q, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 q_zxy = _mm_shuffle_ps(q, q, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 v_zxy = _mm_shuffle_ps(v, v, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 v_yzx = _mm_shuffle_ps(v, v, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 wwww = simd::splat<3>(q);
    // t = w*v + q.xyz x v
    __m128 t = _mm_mul_ps(wwww, v);
    t = simd::madd(q_yzx, v_zxy, t);
    t = _mm_sub_ps(t, _mm_mul_ps(q_zxy, v_yzx));
    // d = qz*vz + (qy*vy + qx*vx)
    const __m128 product = _mm_mul_ps(q, v);
    const __m128 yy_xx = _mm_add_ps(simd::splat<1>(product), simd::splat<0>(product));
    const __m128 d = _mm_add_ps(simd::splat<2>(product), yy_xx);
    const __m128 t_zxy = _mm_shuffle_ps(t, t, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 t_yzx = _mm_shuffle_ps(t, t, _MM_SHUFFLE(3, 0, 2, 1));
    // d*q + w*t + q.xyz x t
    __m128 result = _mm_mul_ps(d, q);
    result = simd::madd(wwww, t, result);
    result = simd::madd(q_yzx, t_zxy, result);
    return Vector3(_mm_sub_ps(result, _mm_mul_ps(q_zxy, t_yzx)));
}

// Nội suy tuyến tính, không chuẩn hoá lại.
[[nodiscard]] inline Quat lerp(const Quat& a, const Quat& b, float t) noexcept {
    return a + ((b - a) * t);
}

// Nội suy cầu giữa hai quaternion đơn vị theo cung ngắn (đổi dấu a khi tích vô hướng âm).
[[nodiscard]] inline Quat slerp(const Quat& a, const Quat& b, float t) noexcept {
    const __m128 raw = simd::dot4(a.simd(), b.simd());
    const __m128 far_side = _mm_cmpgt_ps(_mm_setzero_ps(), raw);
    const __m128 cos_angle = simd::select(raw, simd::negate(raw), far_side);
    const __m128 start = simd::select(a.simd(), simd::negate(a.simd()), far_side);
    const simd::SlerpScales scales = simd::slerp_scales(cos_angle, t);
    const __m128 second = _mm_mul_ps(b.simd(), scales.second);
    return Quat(simd::madd(start, scales.first, second));
}

// Nội suy cầu bậc hai qua bốn mốc: q0, q3 là hai đầu, q1, q2 là hai điểm điều khiển.
[[nodiscard]] inline Quat squad(const Quat& q0, const Quat& q1, const Quat& q2, const Quat& q3, float t) noexcept {
    const Quat ends = slerp(q0, q3, t);
    const Quat inner = slerp(q1, q2, t);
    return slerp(ends, inner, (2.0F * t) * (1.0F - t));
}

[[nodiscard]] inline Quat select(const Quat& a, const Quat& b, bool pick_b) noexcept {
    const __m128 mask = simd::bits(pick_b ? 0xFFFF'FFFFU : 0U);
    return Quat(simd::select(a.simd(), b.simd(), mask));
}

inline Quat Quat::rotation(const Vector3& unit0, const Vector3& unit1) noexcept {
    // cos(a/2) * 2 = sqrt(2 cos a + 2); xyz = (u0 x u1) / (2 cos(a/2)), w = cos(a/2).
    const float root = std::sqrt((dot(unit0, unit1) * 2.0F) + 2.0F);
    return {cross(unit0, unit1) / root, root * 0.5F};
}

inline Quat Quat::rotation(float radians, const Vector3& unit_axis) noexcept {
    const float half = radians * 0.5F;
    return {unit_axis * std::sin(half), std::cos(half)};
}

inline Quat Quat::rotation_x(float radians) noexcept {
    const float half = radians * 0.5F;
    return {std::sin(half), 0.0F, 0.0F, std::cos(half)};
}

inline Quat Quat::rotation_y(float radians) noexcept {
    const float half = radians * 0.5F;
    return {0.0F, std::sin(half), 0.0F, std::cos(half)};
}

inline Quat Quat::rotation_z(float radians) noexcept {
    const float half = radians * 0.5F;
    return {0.0F, 0.0F, std::sin(half), std::cos(half)};
}

inline Quat Quat::from_vectors(const Vector3& from, const Vector3& to) noexcept {
    constexpr float kTolerance = 1e-6F;
    const float norms = std::sqrt(length_sq(from) * length_sq(to));
    if (norms < kTolerance) return identity();
    const float real = norms + dot(from, to);
    const bool opposite = real < kTolerance * norms;
    if (!opposite) return normalize(Quat(cross(from, to), real));
    // Đối nhau: quay 180 độ quanh một trục vuông góc với from, chọn theo thành phần lớn hơn để
    // trục không gần 0.
    const bool x_larger = std::abs(from.x()) > std::abs(from.z());
    const Quat around_z(-from.y(), from.x(), 0.0F, 0.0F);
    const Quat around_x(0.0F, -from.z(), from.y(), 0.0F);
    return normalize(x_larger ? around_z : around_x);
}

inline Quat Quat::from_axis_cos(const Vector3& unit_axis, float cos_angle) noexcept {
    const float half_cos_sq = (1.0F + cos_angle) * 0.5F;
    const float half_sin_sq = 1.0F - half_cos_sq;
    return {unit_axis * std::sqrt(half_sin_sq), std::sqrt(half_cos_sq)};
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
