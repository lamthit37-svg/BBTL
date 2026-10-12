// Toán học SoA cho hệ hoạt hình: mỗi kiểu giữ BỐN giá trị song song, mỗi thành phần là một Vector4
// (bốn làn) — soa/*.hpp của ModifiedSonyMath trong _Ref (từ ozz-animation). SoaFloat3 là bốn vectơ
// 3 chiều, SoaQuat bốn quaternion, SoaTransform bốn bộ (tịnh tiến, quay, tỉ lệ), SoaMatrix4 bốn ma
// trận. Phép so sánh trả mặt nạ từng làn (Vector4i). Giữ thứ tự phép tính của gốc. Khác gốc:
// - so sánh là hàm có tên (less, equal...). Gốc nạp chồng operator<, operator== trả mặt nạ: đọc
//   như phép so thường nhưng `if (a == b)` không biên dịch;
// - lerp(a, b, t) và clamp(v, low, high) cùng thứ tự tham số với phần còn lại của module;
// - transpose trả mảng mới thay vì ghi qua con trỏ; transpose4x3 của gốc khai out[4] mà chỉ ghi 3;
// - một bản mẫu cho cả SoaFloat2, 3, 4 thay ba bản chép tay của mỗi hàm.
// Nguồn: Forge2 src/math/soa.hpp@d7fcd76. Khác gốc (so với Forge2): SoaFloat2, SoaFloat3,
// SoaFloat4 và SoaQuat ở mã không phải bản mẫu khởi tạo bằng tên thành viên.
#pragma once

#include "math/cofactor.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "math/vector_int.hpp"

#include <array>
#include <concepts>
#include <cstddef>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

struct SoaFloat2 {
    Vector4 x{};
    Vector4 y{};

    [[nodiscard]] static SoaFloat2 zero() noexcept { return {}; }
    [[nodiscard]] static SoaFloat2 one() noexcept { return {.x = Vector4::one(), .y = Vector4::one()}; }
    [[nodiscard]] static SoaFloat2 x_axis() noexcept { return {.x = Vector4::one(), .y = {}}; }
    [[nodiscard]] static SoaFloat2 y_axis() noexcept { return {.x = {}, .y = Vector4::one()}; }
};

struct SoaFloat3 {
    Vector4 x{};
    Vector4 y{};
    Vector4 z{};

    [[nodiscard]] static SoaFloat3 from(const SoaFloat2& xy, const Vector4& z) noexcept {
        return {.x = xy.x, .y = xy.y, .z = z};
    }
    [[nodiscard]] static SoaFloat3 zero() noexcept { return {}; }
    [[nodiscard]] static SoaFloat3 one() noexcept {
        return {.x = Vector4::one(), .y = Vector4::one(), .z = Vector4::one()};
    }
    [[nodiscard]] static SoaFloat3 x_axis() noexcept { return {.x = Vector4::one(), .y = {}, .z = {}}; }
    [[nodiscard]] static SoaFloat3 y_axis() noexcept { return {.x = {}, .y = Vector4::one(), .z = {}}; }
    [[nodiscard]] static SoaFloat3 z_axis() noexcept { return {.x = {}, .y = {}, .z = Vector4::one()}; }
};

struct SoaFloat4 {
    Vector4 x{};
    Vector4 y{};
    Vector4 z{};
    Vector4 w{};

    [[nodiscard]] static SoaFloat4 from(const SoaFloat3& xyz, const Vector4& w) noexcept {
        return {.x = xyz.x, .y = xyz.y, .z = xyz.z, .w = w};
    }
    [[nodiscard]] static SoaFloat4 from(const SoaFloat2& xy, const Vector4& z, const Vector4& w) noexcept {
        return {.x = xy.x, .y = xy.y, .z = z, .w = w};
    }
    [[nodiscard]] static SoaFloat4 zero() noexcept { return {}; }
    [[nodiscard]] static SoaFloat4 one() noexcept {
        return {.x = Vector4::one(), .y = Vector4::one(), .z = Vector4::one(), .w = Vector4::one()};
    }
    [[nodiscard]] static SoaFloat4 x_axis() noexcept { return {.x = Vector4::one(), .y = {}, .z = {}, .w = {}}; }
    [[nodiscard]] static SoaFloat4 y_axis() noexcept { return {.x = {}, .y = Vector4::one(), .z = {}, .w = {}}; }
    [[nodiscard]] static SoaFloat4 z_axis() noexcept { return {.x = {}, .y = {}, .z = Vector4::one(), .w = {}}; }
    [[nodiscard]] static SoaFloat4 w_axis() noexcept { return {.x = {}, .y = {}, .z = {}, .w = Vector4::one()}; }
};

template <class V>
concept SoaVector = std::same_as<V, SoaFloat2> || std::same_as<V, SoaFloat3> || std::same_as<V, SoaFloat4>;

namespace detail {

// Áp op lên từng thành phần của a, hoặc từng cặp thành phần của a và b.
template <class Op>
[[nodiscard]] SoaFloat2 map(const SoaFloat2& a, Op op) noexcept {
    return {op(a.x), op(a.y)};
}

template <class Op>
[[nodiscard]] SoaFloat3 map(const SoaFloat3& a, Op op) noexcept {
    return {op(a.x), op(a.y), op(a.z)};
}

template <class Op>
[[nodiscard]] SoaFloat4 map(const SoaFloat4& a, Op op) noexcept {
    return {op(a.x), op(a.y), op(a.z), op(a.w)};
}

template <class Op>
[[nodiscard]] SoaFloat2 zip(const SoaFloat2& a, const SoaFloat2& b, Op op) noexcept {
    return {op(a.x, b.x), op(a.y, b.y)};
}

template <class Op>
[[nodiscard]] SoaFloat3 zip(const SoaFloat3& a, const SoaFloat3& b, Op op) noexcept {
    return {op(a.x, b.x), op(a.y, b.y), op(a.z, b.z)};
}

template <class Op>
[[nodiscard]] SoaFloat4 zip(const SoaFloat4& a, const SoaFloat4& b, Op op) noexcept {
    return {op(a.x, b.x), op(a.y, b.y), op(a.z, b.z), op(a.w, b.w)};
}

// Áp test (trả mặt nạ) lên từng cặp thành phần rồi gộp các mặt nạ từ trái sang bằng join.
template <class Test, class Join>
[[nodiscard]] Vector4i compare(const SoaFloat2& a, const SoaFloat2& b, Test test, Join join) noexcept {
    return join(test(a.x, b.x), test(a.y, b.y));
}

template <class Test, class Join>
[[nodiscard]] Vector4i compare(const SoaFloat3& a, const SoaFloat3& b, Test test, Join join) noexcept {
    return join(join(test(a.x, b.x), test(a.y, b.y)), test(a.z, b.z));
}

template <class Test, class Join>
[[nodiscard]] Vector4i compare(const SoaFloat4& a, const SoaFloat4& b, Test test, Join join) noexcept {
    return join(join(join(test(a.x, b.x), test(a.y, b.y)), test(a.z, b.z)), test(a.w, b.w));
}

[[nodiscard]] inline Vector4i both(const Vector4i& p, const Vector4i& q) noexcept {
    return p & q;
}

[[nodiscard]] inline Vector4i either(const Vector4i& p, const Vector4i& q) noexcept {
    return p | q;
}

// |squared - 1| < tolerance ở từng làn.
[[nodiscard]] inline Vector4i near_one(const Vector4& squared, float tolerance) noexcept {
    return less(abs(squared - Vector4::one()), Vector4(tolerance));
}

// Bình phương độ dài lệch 1 dưới mức này thì coi là đã chuẩn hoá; mức rộng dành cho giá trị vừa
// qua một phép chuẩn hoá ước lượng.
inline constexpr float kNormalizedTolerance = 1e-6F;
inline constexpr float kNormalizedEstimateTolerance = 2e-3F;

} // namespace detail

// Cộng các thành phần ở từng làn: x + y (+ z (+ w)) từ trái sang (HAdd).
[[nodiscard]] inline Vector4 hadd(const SoaFloat2& v) noexcept {
    return v.x + v.y;
}

[[nodiscard]] inline Vector4 hadd(const SoaFloat3& v) noexcept {
    return v.x + v.y + v.z;
}

[[nodiscard]] inline Vector4 hadd(const SoaFloat4& v) noexcept {
    return v.x + v.y + v.z + v.w;
}

template <SoaVector V>
[[nodiscard]] V operator+(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return p + q; });
}

template <SoaVector V>
[[nodiscard]] V operator-(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return p - q; });
}

template <SoaVector V>
[[nodiscard]] V operator-(const V& v) noexcept {
    return detail::map(v, [](const Vector4& p) { return -p; });
}

// Nhân, chia từng thành phần; với Vector4 thì mỗi làn của scale áp cho một trong bốn vectơ.
template <SoaVector V>
[[nodiscard]] V operator*(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return mul(p, q); });
}

template <SoaVector V>
[[nodiscard]] V operator*(const V& a, const Vector4& scale) noexcept {
    return detail::map(a, [&scale](const Vector4& p) { return mul(p, scale); });
}

template <SoaVector V>
[[nodiscard]] V operator/(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return div(p, q); });
}

template <SoaVector V>
[[nodiscard]] V operator/(const V& a, const Vector4& scale) noexcept {
    return detail::map(a, [&scale](const Vector4& p) { return div(p, scale); });
}

// Mặt nạ từng làn: bật khi phép so đúng với MỌI thành phần của vectơ ở làn đó (not_equal: với ít
// nhất một thành phần).
template <SoaVector V>
[[nodiscard]] Vector4i less(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return less(p, q); };
    return detail::compare(a, b, test, detail::both);
}

template <SoaVector V>
[[nodiscard]] Vector4i less_equal(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return less_equal(p, q); };
    return detail::compare(a, b, test, detail::both);
}

template <SoaVector V>
[[nodiscard]] Vector4i greater(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return greater(p, q); };
    return detail::compare(a, b, test, detail::both);
}

template <SoaVector V>
[[nodiscard]] Vector4i greater_equal(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return greater_equal(p, q); };
    return detail::compare(a, b, test, detail::both);
}

template <SoaVector V>
[[nodiscard]] Vector4i equal(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return equal(p, q); };
    return detail::compare(a, b, test, detail::both);
}

template <SoaVector V>
[[nodiscard]] Vector4i not_equal(const V& a, const V& b) noexcept {
    const auto test = [](const Vector4& p, const Vector4& q) { return not_equal(p, q); };
    return detail::compare(a, b, test, detail::either);
}

template <SoaVector V>
[[nodiscard]] Vector4 dot(const V& a, const V& b) noexcept {
    return hadd(a * b);
}

[[nodiscard]] inline SoaFloat3 cross(const SoaFloat3& a, const SoaFloat3& b) noexcept {
    return {
        .x = mul(a.y, b.z) - mul(b.y, a.z),
        .y = mul(a.z, b.x) - mul(b.z, a.x),
        .z = mul(a.x, b.y) - mul(b.x, a.y),
    };
}

template <SoaVector V>
[[nodiscard]] Vector4 length_sq(const V& v) noexcept {
    return dot(v, v);
}

template <SoaVector V>
[[nodiscard]] Vector4 length(const V& v) noexcept {
    return sqrt(length_sq(v));
}

// Vectơ độ dài 0 cho NaN ở làn đó.
template <SoaVector V>
[[nodiscard]] V normalize(const V& v) noexcept {
    return v * div(Vector4::one(), length(v));
}

template <SoaVector V>
[[nodiscard]] Vector4i is_normalized(const V& v) noexcept {
    return detail::near_one(length_sq(v), detail::kNormalizedTolerance);
}

template <SoaVector V>
[[nodiscard]] Vector4i is_normalized_estimate(const V& v) noexcept {
    return detail::near_one(length_sq(v), detail::kNormalizedEstimateTolerance);
}

// (b - a) * t + a, t riêng cho từng làn và không bị kẹp.
template <SoaVector V>
[[nodiscard]] V lerp(const V& a, const V& b, const Vector4& t) noexcept {
    return ((b - a) * t) + a;
}

template <SoaVector V>
[[nodiscard]] V min(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return min(p, q); });
}

template <SoaVector V>
[[nodiscard]] V max(const V& a, const V& b) noexcept {
    return detail::zip(a, b, [](const Vector4& p, const Vector4& q) { return max(p, q); });
}

// low phải không lớn hơn high ở mọi thành phần.
template <SoaVector V>
[[nodiscard]] V clamp(const V& v, const V& low, const V& high) noexcept {
    return max(low, min(v, high));
}

// Bốn quaternion song song.
struct SoaQuat {
    Vector4 x{};
    Vector4 y{};
    Vector4 z{};
    Vector4 w{};

    [[nodiscard]] static SoaQuat identity() noexcept { return {.x = {}, .y = {}, .z = {}, .w = Vector4::one()}; }
};

// Liên hợp: nghịch đảo của quaternion đơn vị.
[[nodiscard]] inline SoaQuat conj(const SoaQuat& q) noexcept {
    return {.x = -q.x, .y = -q.y, .z = -q.z, .w = q.w};
}

// Đổi dấu cả bốn thành phần: vẫn là phép quay ấy.
[[nodiscard]] inline SoaQuat operator-(const SoaQuat& q) noexcept {
    return {.x = -q.x, .y = -q.y, .z = -q.z, .w = -q.w};
}

[[nodiscard]] inline SoaQuat operator+(const SoaQuat& a, const SoaQuat& b) noexcept {
    return {.x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z, .w = a.w + b.w};
}

[[nodiscard]] inline SoaQuat operator*(const SoaQuat& q, const Vector4& scale) noexcept {
    return {.x = mul(q.x, scale), .y = mul(q.y, scale), .z = mul(q.z, scale), .w = mul(q.w, scale)};
}

// Tích Hamilton: a * b quay theo b trước rồi a.
[[nodiscard]] inline SoaQuat operator*(const SoaQuat& a, const SoaQuat& b) noexcept {
    const Vector4 x = mul(a.w, b.x) + mul(a.x, b.w) + mul(a.y, b.z) - mul(a.z, b.y);
    const Vector4 y = mul(a.w, b.y) + mul(a.y, b.w) + mul(a.z, b.x) - mul(a.x, b.z);
    const Vector4 z = mul(a.w, b.z) + mul(a.z, b.w) + mul(a.x, b.y) - mul(a.y, b.x);
    const Vector4 w = mul(a.w, b.w) - mul(a.x, b.x) - mul(a.y, b.y) - mul(a.z, b.z);
    return {.x = x, .y = y, .z = z, .w = w};
}

// Bình phương độ dài của từng quaternion.
[[nodiscard]] inline Vector4 norm(const SoaQuat& q) noexcept {
    return mul(q.x, q.x) + mul(q.y, q.y) + mul(q.z, q.z) + mul(q.w, q.w);
}

[[nodiscard]] inline SoaQuat normalize(const SoaQuat& q) noexcept {
    return q * div(Vector4::one(), sqrt(norm(q)));
}

// Chuẩn hoá bằng RSQRTPS cộng một bước Newton-Raphson (NormalizeEst).
[[nodiscard]] inline SoaQuat normalize_estimate(const SoaQuat& q) noexcept {
    return q * rsqrt_estimate(norm(q));
}

[[nodiscard]] inline Vector4i is_normalized(const SoaQuat& q) noexcept {
    return detail::near_one(norm(q), detail::kNormalizedTolerance);
}

[[nodiscard]] inline Vector4i is_normalized_estimate(const SoaQuat& q) noexcept {
    return detail::near_one(norm(q), detail::kNormalizedEstimateTolerance);
}

// Nội suy tuyến tính từng thành phần; kết quả chưa chuẩn hoá.
[[nodiscard]] inline SoaQuat lerp(const SoaQuat& a, const SoaQuat& b, const Vector4& t) noexcept {
    return {
        .x = mul(b.x - a.x, t) + a.x,
        .y = mul(b.y - a.y, t) + a.y,
        .z = mul(b.z - a.z, t) + a.z,
        .w = mul(b.w - a.w, t) + a.w,
    };
}

// lerp rồi chuẩn hoá. Không chọn cung ngắn: nơi gọi tự đổi dấu b khi dot(a, b) âm.
[[nodiscard]] inline SoaQuat nlerp(const SoaQuat& a, const SoaQuat& b, const Vector4& t) noexcept {
    return normalize(lerp(a, b, t));
}

[[nodiscard]] inline SoaQuat nlerp_estimate(const SoaQuat& a, const SoaQuat& b, const Vector4& t) noexcept {
    return normalize_estimate(lerp(a, b, t));
}

// Mặt nạ: làn bật khi cả bốn thành phần bằng nhau (so chính xác).
[[nodiscard]] inline Vector4i equal(const SoaQuat& a, const SoaQuat& b) noexcept {
    return equal(a.x, b.x) & equal(a.y, b.y) & equal(a.z, b.z) & equal(a.w, b.w);
}

// Bốn phép biến đổi affine tách rời; mặc định là phép đồng nhất.
struct SoaTransform {
    SoaFloat3 translation{};
    SoaQuat rotation = SoaQuat::identity();
    SoaFloat3 scale = SoaFloat3::one();

    [[nodiscard]] static SoaTransform identity() noexcept { return {}; }
};

// Bốn ma trận 4x4 song song, cột trước: v' = M * v.
struct SoaMatrix4 {
    std::array<SoaFloat4, 4> cols{};

    [[nodiscard]] static SoaMatrix4 identity() noexcept { return scaling(SoaFloat4::one()); }
    // Co giãn theo x, y, z của factors; w bị bỏ qua.
    [[nodiscard]] static SoaMatrix4 scaling(const SoaFloat4& factors) noexcept;
    [[nodiscard]] static SoaMatrix4 from_quat(const SoaQuat& unit) noexcept;
    // Ghép tịnh tiến, quay, tỉ lệ thành ma trận: T * R * S.
    [[nodiscard]] static SoaMatrix4 from_affine(const SoaFloat3& translation, const SoaQuat& rotation,
        const SoaFloat3& scale) noexcept;
    [[nodiscard]] static SoaMatrix4 from_affine(const SoaTransform& t) noexcept {
        return from_affine(t.translation, t.rotation, t.scale);
    }
};

inline SoaMatrix4 SoaMatrix4::scaling(const SoaFloat4& factors) noexcept {
    const SoaFloat4 col0{.x = factors.x, .y = {}, .z = {}, .w = {}};
    const SoaFloat4 col1{.x = {}, .y = factors.y, .z = {}, .w = {}};
    const SoaFloat4 col2{.x = {}, .y = {}, .z = factors.z, .w = {}};
    return {{col0, col1, col2, SoaFloat4::w_axis()}};
}

inline SoaMatrix4 SoaMatrix4::from_quat(const SoaQuat& unit) noexcept {
    return from_affine(SoaFloat3::zero(), unit, SoaFloat3::one());
}

inline SoaMatrix4 SoaMatrix4::from_affine(const SoaFloat3& translation, const SoaQuat& rotation,
    const SoaFloat3& scale) noexcept {
    const Vector4 one = Vector4::one();
    const Vector4 two = one + one;
    const Vector4 xx = mul(rotation.x, rotation.x);
    const Vector4 xy = mul(rotation.x, rotation.y);
    const Vector4 xz = mul(rotation.x, rotation.z);
    const Vector4 xw = mul(rotation.x, rotation.w);
    const Vector4 yy = mul(rotation.y, rotation.y);
    const Vector4 yz = mul(rotation.y, rotation.z);
    const Vector4 yw = mul(rotation.y, rotation.w);
    const Vector4 zz = mul(rotation.z, rotation.z);
    const Vector4 zw = mul(rotation.z, rotation.w);
    const Vector4 x2 = mul(scale.x, two);
    const Vector4 y2 = mul(scale.y, two);
    const Vector4 z2 = mul(scale.z, two);
    const Vector4 diagonal_x = mul(scale.x, one - mul(two, yy + zz));
    const Vector4 diagonal_y = mul(scale.y, one - mul(two, xx + zz));
    const Vector4 diagonal_z = mul(scale.z, one - mul(two, xx + yy));
    const SoaFloat4 col0{.x = diagonal_x, .y = mul(x2, xy + zw), .z = mul(x2, xz - yw), .w = {}};
    const SoaFloat4 col1{.x = mul(y2, xy - zw), .y = diagonal_y, .z = mul(y2, yz + xw), .w = {}};
    const SoaFloat4 col2{.x = mul(z2, xz + yw), .y = mul(z2, yz - xw), .z = diagonal_z, .w = {}};
    const SoaFloat4 col3{.x = translation.x, .y = translation.y, .z = translation.z, .w = one};
    return {{col0, col1, col2, col3}};
}

[[nodiscard]] inline SoaMatrix4 transpose(const SoaMatrix4& m) noexcept {
    const auto& [c0, c1, c2, c3] = m.cols;
    const SoaFloat4 row0{.x = c0.x, .y = c1.x, .z = c2.x, .w = c3.x};
    const SoaFloat4 row1{.x = c0.y, .y = c1.y, .z = c2.y, .w = c3.y};
    const SoaFloat4 row2{.x = c0.z, .y = c1.z, .z = c2.z, .w = c3.z};
    const SoaFloat4 row3{.x = c0.w, .y = c1.w, .z = c2.w, .w = c3.w};
    return {{row0, row1, row2, row3}};
}

namespace detail {

[[nodiscard]] inline std::array<Vector4, 4> lanes(const SoaFloat4& v) noexcept {
    return {v.x, v.y, v.z, v.w};
}

[[nodiscard]] inline SoaFloat4 scaled(const std::array<Vector4, 4>& lanes, const Vector4& scale) noexcept {
    const auto& [x, y, z, w] = lanes;
    return {.x = mul(x, scale), .y = mul(y, scale), .z = mul(z, scale), .w = mul(w, scale)};
}

} // namespace detail

// Nghịch đảo tổng quát (Invert). Làn có ma trận suy biến cho vô cùng hoặc NaN.
[[nodiscard]] inline SoaMatrix4 inverse(const SoaMatrix4& m) noexcept {
    const auto& [c0, c1, c2, c3] = m.cols;
    const detail::Grid4<Vector4> grid{detail::lanes(c0), detail::lanes(c1), detail::lanes(c2), detail::lanes(c3)};
    const auto times = [](const Vector4& p, const Vector4& q) { return mul(p, q); };
    const detail::Cofactors<Vector4> parts = detail::cofactors(grid, times);
    const Vector4 scale = div(Vector4::one(), parts.determinant);
    const auto& [a0, a1, a2, a3] = parts.adjugate;
    const SoaFloat4 col0 = detail::scaled(a0, scale);
    const SoaFloat4 col1 = detail::scaled(a1, scale);
    const SoaFloat4 col2 = detail::scaled(a2, scale);
    return {{col0, col1, col2, detail::scaled(a3, scale)}};
}

// m * scaling(factors): nhân ba cột đầu với x, y, z của factors; w bị bỏ qua (Scale).
[[nodiscard]] inline SoaMatrix4 append_scale(const SoaMatrix4& m, const SoaFloat4& factors) noexcept {
    const auto& [c0, c1, c2, c3] = m.cols;
    return {{c0 * factors.x, c1 * factors.y, c2 * factors.z, c3}};
}

[[nodiscard]] inline SoaFloat4 operator*(const SoaMatrix4& m, const SoaFloat4& v) noexcept {
    const auto& [c0, c1, c2, c3] = m.cols;
    return (c0 * v.x) + (c1 * v.y) + (c2 * v.z) + (c3 * v.w);
}

[[nodiscard]] inline SoaMatrix4 operator*(const SoaMatrix4& a, const SoaMatrix4& b) noexcept {
    const auto& [c0, c1, c2, c3] = b.cols;
    return {{a * c0, a * c1, a * c2, a * c3}};
}

[[nodiscard]] inline SoaMatrix4 operator+(const SoaMatrix4& a, const SoaMatrix4& b) noexcept {
    const auto& [a0, a1, a2, a3] = a.cols;
    const auto& [b0, b1, b2, b3] = b.cols;
    return {{a0 + b0, a1 + b1, a2 + b2, a3 + b3}};
}

[[nodiscard]] inline SoaMatrix4 operator-(const SoaMatrix4& a, const SoaMatrix4& b) noexcept {
    const auto& [a0, a1, a2, a3] = a.cols;
    const auto& [b0, b1, b2, b3] = b.cols;
    return {{a0 - b0, a1 - b1, a2 - b2, a3 - b3}};
}

// Đổi giữa bốn vectơ (x, y, z, w) — AoS — và các mảng theo thành phần — SoA.

// Ba mảng x, y, z thành bốn vectơ có w = 0.
[[nodiscard]] inline std::array<Vector4, 4> transpose3x4(const std::array<Vector4, 3>& in) noexcept {
    const auto& [xs, ys, zs] = in;
    const __m128 zero = _mm_setzero_ps();
    const __m128 xy_low = _mm_unpacklo_ps(xs.simd(), ys.simd());
    const __m128 z_low = _mm_unpacklo_ps(zs.simd(), zero);
    const __m128 xy_high = _mm_unpackhi_ps(xs.simd(), ys.simd());
    const __m128 z_high = _mm_unpackhi_ps(zs.simd(), zero);
    return {
        Vector4(_mm_movelh_ps(xy_low, z_low)),
        Vector4(_mm_movehl_ps(z_low, xy_low)),
        Vector4(_mm_movelh_ps(xy_high, z_high)),
        Vector4(_mm_movehl_ps(z_high, xy_high)),
    };
}

// Ma trận chuyển vị của bốn vectơ: out[i] gom thành phần thứ i của cả bốn.
[[nodiscard]] inline std::array<Vector4, 4> transpose4x4(const std::array<Vector4, 4>& in) noexcept {
    const auto& [a, b, c, d] = in;
    const __m128 ac_low = _mm_unpacklo_ps(a.simd(), c.simd());
    const __m128 bd_low = _mm_unpacklo_ps(b.simd(), d.simd());
    const __m128 ac_high = _mm_unpackhi_ps(a.simd(), c.simd());
    const __m128 bd_high = _mm_unpackhi_ps(b.simd(), d.simd());
    return {
        Vector4(_mm_unpacklo_ps(ac_low, bd_low)),
        Vector4(_mm_unpackhi_ps(ac_low, bd_low)),
        Vector4(_mm_unpacklo_ps(ac_high, bd_high)),
        Vector4(_mm_unpackhi_ps(ac_high, bd_high)),
    };
}

// Bốn vectơ thành ba mảng x, y, z; bỏ w.
[[nodiscard]] inline std::array<Vector4, 3> transpose4x3(const std::array<Vector4, 4>& in) noexcept {
    const auto [xs, ys, zs, ws] = transpose4x4(in);
    return {xs, ys, zs};
}

// 16 mảng của một SoaMatrix4 (cột 0 hàng 0..3, cột 1 hàng 0..3...) thành cột của bốn ma trận
// thường: out[4 * i + c] là cột c của ma trận thứ i.
[[nodiscard]] inline std::array<Vector4, 16> transpose16x16(const std::array<Vector4, 16>& in) noexcept {
    std::array<Vector4, 16> out{};
    for (std::size_t col = 0; col < 4; ++col) {
        const std::size_t first = 4 * col;
        const auto [m0, m1, m2, m3] =
            transpose4x4({in.at(first), in.at(first + 1), in.at(first + 2), in.at(first + 3)});
        out.at(col) = m0;
        out.at(4 + col) = m1;
        out.at(8 + col) = m2;
        out.at(12 + col) = m3;
    }
    return out;
}

// Tách SoaMatrix4 thành bốn Matrix4 (transpose16x16 có kiểu).
[[nodiscard]] inline std::array<Matrix4, 4> unpack(const SoaMatrix4& m) noexcept {
    const auto c0 = transpose4x4(detail::lanes(std::get<0>(m.cols)));
    const auto c1 = transpose4x4(detail::lanes(std::get<1>(m.cols)));
    const auto c2 = transpose4x4(detail::lanes(std::get<2>(m.cols)));
    const auto c3 = transpose4x4(detail::lanes(std::get<3>(m.cols)));
    return {
        Matrix4(std::get<0>(c0), std::get<0>(c1), std::get<0>(c2), std::get<0>(c3)),
        Matrix4(std::get<1>(c0), std::get<1>(c1), std::get<1>(c2), std::get<1>(c3)),
        Matrix4(std::get<2>(c0), std::get<2>(c1), std::get<2>(c2), std::get<2>(c3)),
        Matrix4(std::get<3>(c0), std::get<3>(c1), std::get<3>(c2), std::get<3>(c3)),
    };
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
