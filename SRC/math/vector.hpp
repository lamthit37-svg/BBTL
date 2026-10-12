// Vectơ tính toán: Vector3, Vector4, Point3 trên một __m128 (16 B, căn lề 16), và Vector2, Point2
// vô hướng — sse/vector.hpp và vec2d.hpp của ModifiedSonyMath trong _Ref. Lưu trữ và dữ liệu GPU
// dùng Float2/3/4 (math/types.hpp); load và store đổi qua lại. Ánh xạ tên ở docs/modules/math.md.
// Khác gốc:
// - phần tử trả float thẳng, không qua FloatInVec/BoolInVec/VecIdx (trình dịch hiện nay giữ float
//   trong thanh ghi XMM sẵn);
// - một quy ước lerp(a, b, t) và slerp(a, b, t), t đứng cuối;
// - mặc định là vectơ 0, gốc để rác;
// - normalize chia cho căn chính xác (sqrt, div); gốc dùng rsqrt cộng một bước Newton, lệch vài
//   ulp nên vectơ "đơn vị" có độ dài khác 1. Bản ước lượng vẫn còn: normalize_estimate;
// - recip chia chính xác; gốc gọi recipPerElem nhưng trả ước lượng 12 bit của RCPPS. Bản ước
//   lượng: recip_estimate;
// - Vector2 là Float2 (gốc tách hai kiểu cùng hai float rồi viết hàm đổi qua lại); IVector và
//   UVector là Int2..4, Uint2..4.
// Nguồn: Forge2 src/math/vector.hpp@d7fcd76. Khác gốc (so với Forge2): Point2 và Vector2 trong
// các phép toán của Point2 khởi tạo bằng tên thành viên.
#pragma once

#include "math/scalar.hpp"
#include "math/simd.hpp"
#include "math/types.hpp"
#include "math/vector_int.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <span>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

class Point3;
class Vector4;

// Vectơ 3 chiều. Làn w không xác định: phép tính không đọc nó, nơi gọi được dùng tạm.
class Vector3 {
public:
    Vector3() noexcept = default;
    Vector3(float x, float y, float z) noexcept : value_(_mm_setr_ps(x, y, z, 0.0F)) {}
    explicit Vector3(float scalar) noexcept : value_(_mm_set1_ps(scalar)) {}
    explicit Vector3(__m128 value) noexcept : value_(value) {}
    explicit Vector3(const Point3& point) noexcept;

    [[nodiscard]] __m128 simd() const noexcept { return value_; }

    [[nodiscard]] float x() const noexcept { return _mm_cvtss_f32(value_); }
    [[nodiscard]] float y() const noexcept { return _mm_cvtss_f32(simd::splat<1>(value_)); }
    [[nodiscard]] float z() const noexcept { return _mm_cvtss_f32(simd::splat<2>(value_)); }
    [[nodiscard]] float w() const noexcept { return _mm_cvtss_f32(simd::splat<3>(value_)); }
    [[nodiscard]] float operator[](std::size_t i) const noexcept { return simd::lane(value_, i); }

    Vector3& set_x(float x) noexcept { return assign(simd::with_lane<0>(value_, x)); }
    Vector3& set_y(float y) noexcept { return assign(simd::with_lane<1>(value_, y)); }
    Vector3& set_z(float z) noexcept { return assign(simd::with_lane<2>(value_, z)); }
    Vector3& set_w(float w) noexcept { return assign(simd::with_lane<3>(value_, w)); }
    Vector3& set(std::size_t i, float v) noexcept { return assign(simd::with_lane(value_, i, v)); }

    Vector3& operator+=(const Vector3& b) noexcept { return assign(_mm_add_ps(value_, b.value_)); }
    Vector3& operator-=(const Vector3& b) noexcept { return assign(_mm_sub_ps(value_, b.value_)); }
    Vector3& operator*=(float s) noexcept { return assign(_mm_mul_ps(value_, _mm_set1_ps(s))); }
    Vector3& operator/=(float s) noexcept { return assign(_mm_div_ps(value_, _mm_set1_ps(s))); }

    [[nodiscard]] static Vector3 x_axis() noexcept { return {1.0F, 0.0F, 0.0F}; }
    [[nodiscard]] static Vector3 y_axis() noexcept { return {0.0F, 1.0F, 0.0F}; }
    [[nodiscard]] static Vector3 z_axis() noexcept { return {0.0F, 0.0F, 1.0F}; }
    [[nodiscard]] static Vector3 zero() noexcept { return {}; }
    [[nodiscard]] static Vector3 one() noexcept { return {1.0F, 1.0F, 1.0F}; }

private:
    Vector3& assign(__m128 value) noexcept {
        value_ = value;
        return *this;
    }

    __m128 value_ = _mm_setzero_ps();
};

class Vector4 {
public:
    Vector4() noexcept = default;
    Vector4(float x, float y, float z, float w) noexcept : value_(_mm_setr_ps(x, y, z, w)) {}
    Vector4(const Vector3& xyz, float w) noexcept : value_(simd::with_lane<3>(xyz.simd(), w)) {}
    // w = 0 (hướng).
    explicit Vector4(const Vector3& xyz) noexcept : Vector4(xyz, 0.0F) {}
    // w = 1 (vị trí).
    explicit Vector4(const Point3& point) noexcept;
    explicit Vector4(float scalar) noexcept : value_(_mm_set1_ps(scalar)) {}
    explicit Vector4(__m128 value) noexcept : value_(value) {}

    [[nodiscard]] __m128 simd() const noexcept { return value_; }

    [[nodiscard]] float x() const noexcept { return _mm_cvtss_f32(value_); }
    [[nodiscard]] float y() const noexcept { return _mm_cvtss_f32(simd::splat<1>(value_)); }
    [[nodiscard]] float z() const noexcept { return _mm_cvtss_f32(simd::splat<2>(value_)); }
    [[nodiscard]] float w() const noexcept { return _mm_cvtss_f32(simd::splat<3>(value_)); }
    [[nodiscard]] float operator[](std::size_t i) const noexcept { return simd::lane(value_, i); }
    [[nodiscard]] Vector3 xyz() const noexcept { return Vector3(value_); }

    Vector4& set_x(float x) noexcept { return assign(simd::with_lane<0>(value_, x)); }
    Vector4& set_y(float y) noexcept { return assign(simd::with_lane<1>(value_, y)); }
    Vector4& set_z(float z) noexcept { return assign(simd::with_lane<2>(value_, z)); }
    Vector4& set_w(float w) noexcept { return assign(simd::with_lane<3>(value_, w)); }
    Vector4& set(std::size_t i, float v) noexcept { return assign(simd::with_lane(value_, i, v)); }
    // Thay x, y, z; giữ w.
    Vector4& set_xyz(const Vector3& xyz) noexcept { return assign(simd::select(value_, xyz.simd(), simd::mask_xyz())); }

    Vector4& operator+=(const Vector4& b) noexcept { return assign(_mm_add_ps(value_, b.value_)); }
    Vector4& operator-=(const Vector4& b) noexcept { return assign(_mm_sub_ps(value_, b.value_)); }
    Vector4& operator*=(float s) noexcept { return assign(_mm_mul_ps(value_, _mm_set1_ps(s))); }
    Vector4& operator/=(float s) noexcept { return assign(_mm_div_ps(value_, _mm_set1_ps(s))); }

    [[nodiscard]] static Vector4 x_axis() noexcept { return {1.0F, 0.0F, 0.0F, 0.0F}; }
    [[nodiscard]] static Vector4 y_axis() noexcept { return {0.0F, 1.0F, 0.0F, 0.0F}; }
    [[nodiscard]] static Vector4 z_axis() noexcept { return {0.0F, 0.0F, 1.0F, 0.0F}; }
    [[nodiscard]] static Vector4 w_axis() noexcept { return {0.0F, 0.0F, 0.0F, 1.0F}; }
    [[nodiscard]] static Vector4 zero() noexcept { return {}; }
    [[nodiscard]] static Vector4 one() noexcept { return Vector4(1.0F); }
    // Bốn số nguyên có dấu thành float.
    [[nodiscard]] static Vector4 from_int(const Vector4i& value) noexcept {
        return Vector4(_mm_cvtepi32_ps(value.simd()));
    }

private:
    Vector4& assign(__m128 value) noexcept {
        value_ = value;
        return *this;
    }

    __m128 value_ = _mm_setzero_ps();
};

// Điểm trong không gian: điểm trừ điểm ra vectơ, điểm cộng vectơ ra điểm; ma trận nhân điểm có tính
// phần tịnh tiến, nhân vectơ thì không. Làn w không xác định.
class Point3 {
public:
    Point3() noexcept = default;
    Point3(float x, float y, float z) noexcept : value_(_mm_setr_ps(x, y, z, 0.0F)) {}
    explicit Point3(const Vector3& vector) noexcept : value_(vector.simd()) {}
    explicit Point3(const Vector4& vector) noexcept : value_(vector.simd()) {}
    explicit Point3(float scalar) noexcept : value_(_mm_set1_ps(scalar)) {}
    explicit Point3(__m128 value) noexcept : value_(value) {}

    [[nodiscard]] __m128 simd() const noexcept { return value_; }

    [[nodiscard]] float x() const noexcept { return _mm_cvtss_f32(value_); }
    [[nodiscard]] float y() const noexcept { return _mm_cvtss_f32(simd::splat<1>(value_)); }
    [[nodiscard]] float z() const noexcept { return _mm_cvtss_f32(simd::splat<2>(value_)); }
    [[nodiscard]] float w() const noexcept { return _mm_cvtss_f32(simd::splat<3>(value_)); }
    [[nodiscard]] float operator[](std::size_t i) const noexcept { return simd::lane(value_, i); }

    Point3& set_x(float x) noexcept { return assign(simd::with_lane<0>(value_, x)); }
    Point3& set_y(float y) noexcept { return assign(simd::with_lane<1>(value_, y)); }
    Point3& set_z(float z) noexcept { return assign(simd::with_lane<2>(value_, z)); }
    Point3& set_w(float w) noexcept { return assign(simd::with_lane<3>(value_, w)); }
    Point3& set(std::size_t i, float v) noexcept { return assign(simd::with_lane(value_, i, v)); }

    Point3& operator+=(const Vector3& b) noexcept { return assign(_mm_add_ps(value_, b.simd())); }
    Point3& operator-=(const Vector3& b) noexcept { return assign(_mm_sub_ps(value_, b.simd())); }

private:
    Point3& assign(__m128 value) noexcept {
        value_ = value;
        return *this;
    }

    __m128 value_ = _mm_setzero_ps();
};

inline Vector3::Vector3(const Point3& point) noexcept : value_(point.simd()) {}

inline Vector4::Vector4(const Point3& point) noexcept : value_(simd::with_lane<3>(point.simd(), 1.0F)) {}

static_assert(sizeof(Vector3) == 16 && alignof(Vector3) == 16);
static_assert(sizeof(Vector4) == 16 && sizeof(Point3) == 16);

// Đổi qua lại với kiểu lưu trữ (v3ToF3, f3Tov3... của gốc).

[[nodiscard]] inline Vector3 load(Float3 f) noexcept {
    return {f.x, f.y, f.z};
}

[[nodiscard]] inline Vector4 load(Float4 f) noexcept {
    return Vector4(_mm_loadu_ps(&f.x));
}

[[nodiscard]] inline Float4 store(const Vector4& v) noexcept {
    Float4 out;
    _mm_storeu_ps(&out.x, v.simd());
    return out;
}

[[nodiscard]] inline Float3 store(const Vector3& v) noexcept {
    return store(Vector4(v.simd())).xyz();
}

[[nodiscard]] inline Float3 store(const Point3& p) noexcept {
    return store(Vector4(p.simd())).xyz();
}

// Vector3

[[nodiscard]] inline Vector3 operator+(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_add_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 operator-(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_sub_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 operator-(const Vector3& a) noexcept {
    return Vector3(simd::negate(a.simd()));
}

[[nodiscard]] inline Vector3 operator*(const Vector3& a, float s) noexcept {
    return Vector3(_mm_mul_ps(a.simd(), _mm_set1_ps(s)));
}

[[nodiscard]] inline Vector3 operator*(float s, const Vector3& a) noexcept {
    return a * s;
}

[[nodiscard]] inline Vector3 operator/(const Vector3& a, float s) noexcept {
    return Vector3(_mm_div_ps(a.simd(), _mm_set1_ps(s)));
}

// So x, y, z; bỏ qua w.
[[nodiscard]] inline bool operator==(const Vector3& a, const Vector3& b) noexcept {
    return (_mm_movemask_ps(_mm_cmpeq_ps(a.simd(), b.simd())) & 0x7) == 0x7;
}

// Nhân, chia từng phần tử (mulPerElem, divPerElem).
[[nodiscard]] inline Vector3 mul(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_mul_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 div(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_div_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 recip(const Vector3& v) noexcept {
    return Vector3(_mm_div_ps(_mm_set1_ps(1.0F), v.simd()));
}

// 1/v ước lượng 12 bit bằng RCPPS.
[[nodiscard]] inline Vector3 recip_estimate(const Vector3& v) noexcept {
    return Vector3(_mm_rcp_ps(v.simd()));
}

[[nodiscard]] inline Vector3 abs(const Vector3& v) noexcept {
    return Vector3(simd::abs(v.simd()));
}

[[nodiscard]] inline Vector3 copysign(const Vector3& value, const Vector3& sign) noexcept {
    return Vector3(simd::copysign(value.simd(), sign.simd()));
}

[[nodiscard]] inline Vector3 max(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_max_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 min(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(_mm_min_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 clamp(const Vector3& v, const Vector3& low, const Vector3& high) noexcept {
    return min(max(v, low), high);
}

[[nodiscard]] inline float max_elem(const Vector3& v) noexcept {
    const __m128 xy = _mm_max_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    return _mm_cvtss_f32(_mm_max_ps(xy, simd::splat<2>(v.simd())));
}

[[nodiscard]] inline float min_elem(const Vector3& v) noexcept {
    const __m128 xy = _mm_min_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    return _mm_cvtss_f32(_mm_min_ps(xy, simd::splat<2>(v.simd())));
}

// x + y + z.
[[nodiscard]] inline float sum(const Vector3& v) noexcept {
    const __m128 xy = _mm_add_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    return _mm_cvtss_f32(_mm_add_ps(xy, simd::splat<2>(v.simd())));
}

[[nodiscard]] inline float dot(const Vector3& a, const Vector3& b) noexcept {
    return _mm_cvtss_f32(simd::dot3(a.simd(), b.simd()));
}

[[nodiscard]] inline float length_sq(const Vector3& v) noexcept {
    return dot(v, v);
}

[[nodiscard]] inline float length(const Vector3& v) noexcept {
    return _mm_cvtss_f32(_mm_sqrt_ps(simd::dot3(v.simd(), v.simd())));
}

// Vectơ độ dài 0 cho NaN.
[[nodiscard]] inline Vector3 normalize(const Vector3& v) noexcept {
    return Vector3(_mm_div_ps(v.simd(), _mm_sqrt_ps(simd::dot3(v.simd(), v.simd()))));
}

// Chuẩn hoá bằng RSQRTPS, sai số tương đối độ dài tới 1,5 * 2^-12 (normalizeApprox).
[[nodiscard]] inline Vector3 normalize_estimate(const Vector3& v) noexcept {
    return Vector3(_mm_mul_ps(v.simd(), _mm_rsqrt_ps(simd::dot3(v.simd(), v.simd()))));
}

[[nodiscard]] inline Vector3 cross(const Vector3& a, const Vector3& b) noexcept {
    return Vector3(simd::cross3(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector3 lerp(const Vector3& a, const Vector3& b, float t) noexcept {
    return a + ((b - a) * t);
}

// Nội suy cầu giữa hai vectơ đơn vị; gần trùng nhau (cos >= 0,999) thì nội suy tuyến tính. Hai
// vectơ đối nhau không có cung ngắn nhất duy nhất nên cho NaN (slerp của Quat đổi dấu để tránh ca
// này).
[[nodiscard]] inline Vector3 slerp(const Vector3& a, const Vector3& b, float t) noexcept {
    const simd::SlerpScales scales = simd::slerp_scales(simd::dot3(a.simd(), b.simd()), t);
    const __m128 second = _mm_mul_ps(b.simd(), scales.second);
    return Vector3(simd::madd(a.simd(), scales.first, second));
}

// b khi pick_b, không thì a; không rẽ nhánh.
[[nodiscard]] inline Vector3 select(const Vector3& a, const Vector3& b, bool pick_b) noexcept {
    const __m128 mask = simd::bits(pick_b ? 0xFFFF'FFFFU : 0U);
    return Vector3(simd::select(a.simd(), b.simd(), mask));
}

[[nodiscard]] inline Vector3 sqrt(const Vector3& v) noexcept {
    return Vector3(_mm_sqrt_ps(v.simd()));
}

// 1/sqrt từng phần tử: RSQRTPS cộng một bước Newton-Raphson (rSqrtEstNR).
[[nodiscard]] inline Vector3 rsqrt_estimate(const Vector3& v) noexcept {
    return Vector3(simd::rsqrt_nr(v.simd()));
}

// Đảo bit theo mặt nạ từng làn (xorPerElem của gốc), dùng để đổi dấu có điều kiện.
[[nodiscard]] inline Vector3 bit_xor(const Vector3& a, const Vector4i& b) noexcept {
    return Vector3(_mm_xor_ps(a.simd(), _mm_castsi128_ps(b.simd())));
}

// Bình phương độ dài lệch 1 dưới 2e-3: phép kiểm rẻ cho đầu vào phải là vectơ đơn vị.
[[nodiscard]] inline bool is_normalized(const Vector3& v) noexcept {
    constexpr float kTolerance = 2e-3F;
    const float squared = length_sq(v);
    return squared < 1.0F + kTolerance && squared > 1.0F - kTolerance;
}

// Vector4

[[nodiscard]] inline Vector4 operator+(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_add_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 operator-(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_sub_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 operator-(const Vector4& a) noexcept {
    return Vector4(simd::negate(a.simd()));
}

[[nodiscard]] inline Vector4 operator*(const Vector4& a, float s) noexcept {
    return Vector4(_mm_mul_ps(a.simd(), _mm_set1_ps(s)));
}

[[nodiscard]] inline Vector4 operator*(float s, const Vector4& a) noexcept {
    return a * s;
}

[[nodiscard]] inline Vector4 operator/(const Vector4& a, float s) noexcept {
    return Vector4(_mm_div_ps(a.simd(), _mm_set1_ps(s)));
}

[[nodiscard]] inline bool operator==(const Vector4& a, const Vector4& b) noexcept {
    return _mm_movemask_ps(_mm_cmpeq_ps(a.simd(), b.simd())) == 0xF;
}

[[nodiscard]] inline Vector4 mul(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_mul_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 div(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_div_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 recip(const Vector4& v) noexcept {
    return Vector4(_mm_div_ps(_mm_set1_ps(1.0F), v.simd()));
}

[[nodiscard]] inline Vector4 recip_estimate(const Vector4& v) noexcept {
    return Vector4(_mm_rcp_ps(v.simd()));
}

[[nodiscard]] inline Vector4 sqrt(const Vector4& v) noexcept {
    return Vector4(_mm_sqrt_ps(v.simd()));
}

// 1/sqrt ước lượng 12 bit bằng RSQRTPS (rsqrtPerElem, rSqrtEst).
[[nodiscard]] inline Vector4 rsqrt_rough(const Vector4& v) noexcept {
    return Vector4(_mm_rsqrt_ps(v.simd()));
}

// RSQRTPS cộng một bước Newton-Raphson (rSqrtEstNR).
[[nodiscard]] inline Vector4 rsqrt_estimate(const Vector4& v) noexcept {
    return Vector4(simd::rsqrt_nr(v.simd()));
}

// acos từng phần tử, đầu vào trong [-1, 1].
[[nodiscard]] inline Vector4 acos(const Vector4& v) noexcept {
    return Vector4(simd::acos(v.simd()));
}

[[nodiscard]] inline Vector4 abs(const Vector4& v) noexcept {
    return Vector4(simd::abs(v.simd()));
}

[[nodiscard]] inline Vector4 copysign(const Vector4& value, const Vector4& sign) noexcept {
    return Vector4(simd::copysign(value.simd(), sign.simd()));
}

[[nodiscard]] inline Vector4 max(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_max_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 min(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_min_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline float max_elem(const Vector4& v) noexcept {
    const __m128 xy = _mm_max_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    const __m128 zw = _mm_max_ps(simd::splat<2>(v.simd()), simd::splat<3>(v.simd()));
    return _mm_cvtss_f32(_mm_max_ps(xy, zw));
}

[[nodiscard]] inline float min_elem(const Vector4& v) noexcept {
    const __m128 xy = _mm_min_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    const __m128 zw = _mm_min_ps(simd::splat<2>(v.simd()), simd::splat<3>(v.simd()));
    return _mm_cvtss_f32(_mm_min_ps(xy, zw));
}

// (x + y) + (z + w).
[[nodiscard]] inline float sum(const Vector4& v) noexcept {
    const __m128 xy = _mm_add_ps(simd::splat<0>(v.simd()), simd::splat<1>(v.simd()));
    const __m128 zw = _mm_add_ps(simd::splat<2>(v.simd()), simd::splat<3>(v.simd()));
    return _mm_cvtss_f32(_mm_add_ps(xy, zw));
}

[[nodiscard]] inline float dot(const Vector4& a, const Vector4& b) noexcept {
    return _mm_cvtss_f32(simd::dot4(a.simd(), b.simd()));
}

[[nodiscard]] inline float length_sq(const Vector4& v) noexcept {
    return dot(v, v);
}

[[nodiscard]] inline float length(const Vector4& v) noexcept {
    return _mm_cvtss_f32(_mm_sqrt_ps(simd::dot4(v.simd(), v.simd())));
}

[[nodiscard]] inline Vector4 normalize(const Vector4& v) noexcept {
    return Vector4(_mm_div_ps(v.simd(), _mm_sqrt_ps(simd::dot4(v.simd(), v.simd()))));
}

[[nodiscard]] inline Vector4 normalize_estimate(const Vector4& v) noexcept {
    return Vector4(_mm_mul_ps(v.simd(), _mm_rsqrt_ps(simd::dot4(v.simd(), v.simd()))));
}

[[nodiscard]] inline Vector4 lerp(const Vector4& a, const Vector4& b, float t) noexcept {
    return a + ((b - a) * t);
}

[[nodiscard]] inline Vector4 slerp(const Vector4& a, const Vector4& b, float t) noexcept {
    const simd::SlerpScales scales = simd::slerp_scales(simd::dot4(a.simd(), b.simd()), t);
    const __m128 second = _mm_mul_ps(b.simd(), scales.second);
    return Vector4(simd::madd(a.simd(), scales.first, second));
}

[[nodiscard]] inline Vector4 select(const Vector4& a, const Vector4& b, bool pick_b) noexcept {
    const __m128 mask = simd::bits(pick_b ? 0xFFFF'FFFFU : 0U);
    return Vector4(simd::select(a.simd(), b.simd(), mask));
}

// Mặt nạ từng làn (toàn bit 1 khi đúng) — cmpEq..cmpGe của gốc, dùng với select_mask và các phép
// bit bên dưới. Làn có NaN: mọi phép so cho sai, trừ not_equal.
[[nodiscard]] inline Vector4i equal(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmpeq_ps(a.simd(), b.simd())));
}

[[nodiscard]] inline Vector4i not_equal(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmpneq_ps(a.simd(), b.simd())));
}

[[nodiscard]] inline Vector4i less(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmplt_ps(a.simd(), b.simd())));
}

[[nodiscard]] inline Vector4i less_equal(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmple_ps(a.simd(), b.simd())));
}

[[nodiscard]] inline Vector4i greater(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmpgt_ps(a.simd(), b.simd())));
}

[[nodiscard]] inline Vector4i greater_equal(const Vector4& a, const Vector4& b) noexcept {
    return Vector4i(_mm_castps_si128(_mm_cmpge_ps(a.simd(), b.simd())));
}

// b ở làn có mặt nạ bật, a ở làn còn lại.
[[nodiscard]] inline Vector4 select_mask(const Vector4& a, const Vector4& b, const Vector4i& mask) noexcept {
    return Vector4(simd::select(a.simd(), b.simd(), _mm_castsi128_ps(mask.simd())));
}

// Bit dấu của từng làn, các bit khác bằng 0.
[[nodiscard]] inline Vector4i sign_bit(const Vector4& v) noexcept {
    return Vector4i(_mm_castps_si128(v.simd())) & Vector4i::mask_sign();
}

[[nodiscard]] inline Vector4 bit_xor(const Vector4& a, const Vector4i& b) noexcept {
    return Vector4(_mm_xor_ps(a.simd(), _mm_castsi128_ps(b.simd())));
}

[[nodiscard]] inline Vector4 bit_or(const Vector4& a, const Vector4i& b) noexcept {
    return Vector4(_mm_or_ps(a.simd(), _mm_castsi128_ps(b.simd())));
}

[[nodiscard]] inline Vector4 bit_or(const Vector4& a, const Vector4& b) noexcept {
    return Vector4(_mm_or_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4 bit_and(const Vector4& a, const Vector4i& b) noexcept {
    return Vector4(_mm_and_ps(a.simd(), _mm_castsi128_ps(b.simd())));
}

// Float thành số nguyên: làm tròn theo chế độ của MXCSR (mặc định về số chẵn gần nhất), hoặc cắt
// phần lẻ (FromFloatRound, FromFloatTrunc). Ngoài tầm int32 và NaN cho 0x80000000.
[[nodiscard]] inline Vector4i round_to_int(const Vector4& v) noexcept {
    return Vector4i(_mm_cvtps_epi32(v.simd()));
}

[[nodiscard]] inline Vector4i truncate_to_int(const Vector4& v) noexcept {
    return Vector4i(_mm_cvttps_epi32(v.simd()));
}

// Bốn số half (16 bit thấp của mỗi làn) thành float, không rẽ nhánh; số không chuẩn và NaN đúng
// như to_float của math/types.hpp.
[[nodiscard]] inline Vector4 half_to_float(const Vector4i& halves) noexcept {
    const __m128i magnitude = _mm_and_si128(_mm_set1_epi32(0x7FFF), halves.simd());
    const __m128 scale = _mm_castsi128_ps(_mm_set1_epi32((254 - 15) << 23));
    const __m128 scaled = _mm_mul_ps(_mm_castsi128_ps(_mm_slli_epi32(magnitude, 13)), scale);
    const __m128i was_special = _mm_cmpgt_epi32(magnitude, _mm_set1_epi32(0x7BFF));
    const __m128i sign = _mm_slli_epi32(_mm_xor_si128(halves.simd(), magnitude), 16);
    const __m128 special = _mm_and_ps(_mm_castsi128_ps(was_special), simd::bits(0x7F80'0000U));
    return Vector4(_mm_or_ps(scaled, _mm_or_ps(_mm_castsi128_ps(sign), special)));
}

// Point3

[[nodiscard]] inline Vector3 operator-(const Point3& a, const Point3& b) noexcept {
    return Vector3(_mm_sub_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Point3 operator+(const Point3& p, const Vector3& v) noexcept {
    return Point3(_mm_add_ps(p.simd(), v.simd()));
}

[[nodiscard]] inline Point3 operator+(const Vector3& v, const Point3& p) noexcept {
    return p + v;
}

[[nodiscard]] inline Point3 operator-(const Point3& p, const Vector3& v) noexcept {
    return Point3(_mm_sub_ps(p.simd(), v.simd()));
}

[[nodiscard]] inline bool operator==(const Point3& a, const Point3& b) noexcept {
    return Vector3(a) == Vector3(b);
}

[[nodiscard]] inline Point3 mul(const Point3& a, const Point3& b) noexcept {
    return Point3(_mm_mul_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Point3 div(const Point3& a, const Point3& b) noexcept {
    return Point3(_mm_div_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Point3 recip(const Point3& p) noexcept {
    return Point3(recip(Vector3(p)));
}

[[nodiscard]] inline Point3 abs(const Point3& p) noexcept {
    return Point3(simd::abs(p.simd()));
}

[[nodiscard]] inline Point3 copysign(const Point3& value, const Point3& sign) noexcept {
    return Point3(simd::copysign(value.simd(), sign.simd()));
}

[[nodiscard]] inline Point3 max(const Point3& a, const Point3& b) noexcept {
    return Point3(_mm_max_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline Point3 min(const Point3& a, const Point3& b) noexcept {
    return Point3(_mm_min_ps(a.simd(), b.simd()));
}

[[nodiscard]] inline float max_elem(const Point3& p) noexcept {
    return max_elem(Vector3(p));
}

[[nodiscard]] inline float min_elem(const Point3& p) noexcept {
    return min_elem(Vector3(p));
}

[[nodiscard]] inline float sum(const Point3& p) noexcept {
    return sum(Vector3(p));
}

// Co giãn quanh gốc toạ độ.
[[nodiscard]] inline Point3 scale(const Point3& p, float factor) noexcept {
    return Point3(_mm_mul_ps(p.simd(), _mm_set1_ps(factor)));
}

[[nodiscard]] inline Point3 scale(const Point3& p, const Vector3& factors) noexcept {
    return Point3(_mm_mul_ps(p.simd(), factors.simd()));
}

// Hình chiếu vô hướng của điểm lên trục đơn vị qua gốc toạ độ.
[[nodiscard]] inline float projection(const Point3& p, const Vector3& unit) noexcept {
    return dot(Vector3(p), unit);
}

[[nodiscard]] inline float dist_sq_from_origin(const Point3& p) noexcept {
    return length_sq(Vector3(p));
}

[[nodiscard]] inline float dist_from_origin(const Point3& p) noexcept {
    return length(Vector3(p));
}

[[nodiscard]] inline float dist_sq(const Point3& a, const Point3& b) noexcept {
    return length_sq(b - a);
}

[[nodiscard]] inline float dist(const Point3& a, const Point3& b) noexcept {
    return length(b - a);
}

[[nodiscard]] inline Point3 lerp(const Point3& a, const Point3& b, float t) noexcept {
    return a + ((b - a) * t);
}

[[nodiscard]] inline Point3 select(const Point3& a, const Point3& b, bool pick_b) noexcept {
    return Point3(select(Vector3(a), Vector3(b), pick_b));
}

// Vector2 và Point2: hai float, không SIMD (vec2d.hpp của gốc).

using Vector2 = Float2;
using IVector2 = Int2;
using IVector3 = Int3;
using IVector4 = Int4;
using UVector2 = Uint2;
using UVector3 = Uint3;
using UVector4 = Uint4;

[[nodiscard]] constexpr Vector2 lerp(Vector2 a, Vector2 b, float t) noexcept {
    return a + ((b - a) * t);
}

struct Point2 {
    float x = 0.0F;
    float y = 0.0F;

    friend constexpr bool operator==(const Point2&, const Point2&) = default;
    friend constexpr Vector2 operator-(Point2 a, Point2 b) noexcept { return {.x = a.x - b.x, .y = a.y - b.y}; }
    friend constexpr Point2 operator+(Point2 p, Vector2 v) noexcept { return {.x = p.x + v.x, .y = p.y + v.y}; }
    friend constexpr Point2 operator+(Vector2 v, Point2 p) noexcept { return p + v; }
    friend constexpr Point2 operator-(Point2 p, Vector2 v) noexcept { return {.x = p.x - v.x, .y = p.y - v.y}; }
    constexpr Point2& operator+=(Vector2 v) noexcept { return *this = *this + v; }
    constexpr Point2& operator-=(Vector2 v) noexcept { return *this = *this - v; }
};

[[nodiscard]] inline Point2 abs(Point2 p) noexcept {
    return {.x = std::abs(p.x), .y = std::abs(p.y)};
}

[[nodiscard]] constexpr Point2 max(Point2 a, Point2 b) noexcept {
    return {.x = detail::greater(a.x, b.x), .y = detail::greater(a.y, b.y)};
}

[[nodiscard]] constexpr Point2 min(Point2 a, Point2 b) noexcept {
    return {.x = detail::lesser(a.x, b.x), .y = detail::lesser(a.y, b.y)};
}

[[nodiscard]] constexpr float max_elem(Point2 p) noexcept {
    return p.x > p.y ? p.x : p.y;
}

[[nodiscard]] constexpr float min_elem(Point2 p) noexcept {
    return p.x < p.y ? p.x : p.y;
}

[[nodiscard]] constexpr float dist_sq_from_origin(Point2 p) noexcept {
    return (p.x * p.x) + (p.y * p.y);
}

[[nodiscard]] inline float dist_from_origin(Point2 p) noexcept {
    return std::sqrt(dist_sq_from_origin(p));
}

[[nodiscard]] constexpr float dist_sq(Point2 a, Point2 b) noexcept {
    return length_sq(b - a);
}

[[nodiscard]] inline float dist(Point2 a, Point2 b) noexcept {
    return length(b - a);
}

[[nodiscard]] constexpr Point2 lerp(Point2 a, Point2 b, float t) noexcept {
    return a + ((b - a) * t);
}

// Mảng xyz đóng gói: bốn vectơ trong 12 float liền nhau (x0 y0 z0 x1 ...), cho bộ đệm đỉnh.

inline constexpr std::size_t kPackedFloats = 12;

// Gốc (loadXYZArray) nạp vectơ cuối bằng bốn float từ vị trí 9, đọc lố một float ngoài vùng 12;
// ở đây nạp từ vị trí 8 rồi xoay làn.
[[nodiscard]] inline std::array<Vector3, 4> load_xyz(std::span<const float, kPackedFloats> packed) noexcept {
    const __m128 tail = _mm_loadu_ps(packed.subspan(8).data());
    return {
        Vector3(_mm_loadu_ps(packed.data())),
        Vector3(_mm_loadu_ps(packed.subspan(3).data())),
        Vector3(_mm_loadu_ps(packed.subspan(6).data())),
        Vector3(_mm_shuffle_ps(tail, tail, _MM_SHUFFLE(0, 3, 2, 1))),
    };
}

inline void store_xyz(std::span<const Vector3, 4> vectors, std::span<float, kPackedFloats> packed) noexcept {
    const Float4 a = store(Vector4(vectors.front().simd()));
    const Float4 b = store(Vector4(vectors.subspan(1).front().simd()));
    const Float4 c = store(Vector4(vectors.subspan(2).front().simd()));
    const Float4 d = store(Vector4(vectors.back().simd()));
    const std::array<float, kPackedFloats> flat{a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, d.x, d.y, d.z};
    std::ranges::copy(flat, packed.begin());
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
