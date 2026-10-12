// Ma trận cột: Matrix2 (vô hướng), Matrix3, Matrix4, Transform3 (3x4 affine), AffineTransform —
// sse/matrix.hpp và vec2d.hpp của ModifiedSonyMath trong _Ref. Vectơ là cột, M * v; m[c] là cột c.
// Phép chiếu theo quy ước D3D và Vulkan: z của NDC trong [0, 1]. Khác gốc:
// - inverse của Matrix3 và Transform3 (kéo theo affine_inverse), frustum_lh và orthographic_lh chia
//   chính xác; gốc nhân với nghịch đảo ước lượng 12 bit của RCPPS;
// - frustum_lh giữ hai hệ số lệch tâm; gốc đặt chúng về 0 nên chỉ đúng với khối nhìn đối xứng;
// - clip_planes lấy mặt gần ở z = 0; gốc lấy z = -w (quy ước OpenGL) dù ma trận chiếu của chính nó
//   cho z trong [0, 1];
// - cột nằm trong std::array; gốc cộng con trỏ qua các member (UB);
// - góc vô hướng tính bằng std::sin, std::cos thay đa thức xấp xỉ.
// Nguồn: Forge2 src/math/matrix.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator của CubeFace
// mang tiền tố k; transpose3 trả struct Rows3 thay std::array<__m128, 3> (GCC báo
// -Wignored-attributes); bỏ {} thừa của AffineTransform::translation; Matrix2 khởi tạo bằng tên
// thành viên; NOLINT kèm lý do cho minors (hai cột đúng thứ tự như cross).
#pragma once

#include "math/quat.hpp"
#include "math/vector.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

namespace detail {

struct Rows3 {
    __m128 row0;
    __m128 row1;
    __m128 row2;
};

// Chuyển vị ba cột 3 chiều: làn w của kết quả không xác định.
// Khác gốc: gốc trả std::array<__m128, 3>, GCC báo -Wignored-attributes.
[[nodiscard]] inline Rows3 transpose3(__m128 c0, __m128 c1, __m128 c2) noexcept {
    const __m128 low = _mm_unpacklo_ps(c0, c2);
    const __m128 high = _mm_unpackhi_ps(c0, c2);
    const __m128 row0 = _mm_unpacklo_ps(low, c1);
    const __m128 row1 = _mm_blend_ps(_mm_shuffle_ps(low, low, _MM_SHUFFLE(0, 3, 2, 2)), c1, 0b0010);
    const __m128 z_mix = _mm_shuffle_ps(high, high, _MM_SHUFFLE(0, 1, 1, 0));
    const __m128 row2 = _mm_blend_ps(z_mix, simd::splat<2>(c1), 0b0010);
    return {.row0 = row0, .row1 = row1, .row2 = row2};
}

// Xoay làn sang trái Count vị trí: ror<1>(x, y, z, w) = (y, z, w, x) — sseRor của gốc.
template <int Count>
[[nodiscard]] inline __m128 ror(__m128 v) noexcept {
    constexpr int kA = Count % 4;
    constexpr int kB = (Count + 1) % 4;
    constexpr int kC = (Count + 2) % 4;
    constexpr int kD = (Count + 3) % 4;
    return _mm_shuffle_ps(v, v, _MM_SHUFFLE(kD, kC, kB, kA));
}

} // namespace detail

class Matrix3 {
public:
    // Ma trận 0; ma trận đơn vị là identity().
    Matrix3() noexcept = default;
    Matrix3(const Vector3& col0, const Vector3& col1, const Vector3& col2) noexcept : cols_{col0, col1, col2} {}
    explicit Matrix3(const Quat& unit) noexcept;
    explicit Matrix3(float scalar) noexcept : Matrix3(Vector3(scalar), Vector3(scalar), Vector3(scalar)) {}

    [[nodiscard]] const Vector3& col0() const noexcept { return std::get<0>(cols_); }
    [[nodiscard]] const Vector3& col1() const noexcept { return std::get<1>(cols_); }
    [[nodiscard]] const Vector3& col2() const noexcept { return std::get<2>(cols_); }
    [[nodiscard]] const Vector3& operator[](std::size_t col) const noexcept { return cols_.at(col); }
    [[nodiscard]] Vector3& operator[](std::size_t col) noexcept { return cols_.at(col); }
    [[nodiscard]] Vector3 row(std::size_t row) const noexcept { return {col0()[row], col1()[row], col2()[row]}; }
    [[nodiscard]] float at(std::size_t col, std::size_t row) const noexcept { return cols_.at(col)[row]; }

    Matrix3& set_col(std::size_t col, const Vector3& v) noexcept {
        cols_.at(col) = v;
        return *this;
    }
    Matrix3& set_row(std::size_t row, const Vector3& v) noexcept {
        std::get<0>(cols_).set(row, v.x());
        std::get<1>(cols_).set(row, v.y());
        std::get<2>(cols_).set(row, v.z());
        return *this;
    }
    Matrix3& set(std::size_t col, std::size_t row, float value) noexcept {
        cols_.at(col).set(row, value);
        return *this;
    }

    Matrix3& operator+=(const Matrix3& b) noexcept;
    Matrix3& operator-=(const Matrix3& b) noexcept;
    Matrix3& operator*=(float s) noexcept;
    Matrix3& operator*=(const Matrix3& b) noexcept;

    [[nodiscard]] static Matrix3 identity() noexcept {
        return {Vector3::x_axis(), Vector3::y_axis(), Vector3::z_axis()};
    }
    [[nodiscard]] static Matrix3 rotation_x(float radians) noexcept;
    [[nodiscard]] static Matrix3 rotation_y(float radians) noexcept;
    [[nodiscard]] static Matrix3 rotation_z(float radians) noexcept;
    // Quay quanh X, rồi Y, rồi Z: Rz * Ry * Rx.
    [[nodiscard]] static Matrix3 rotation_zyx(const Vector3& radians_xyz) noexcept;
    [[nodiscard]] static Matrix3 rotation(float radians, const Vector3& unit_axis) noexcept;
    [[nodiscard]] static Matrix3 rotation(const Quat& unit) noexcept { return Matrix3(unit); }
    [[nodiscard]] static Matrix3 scale(const Vector3& factors) noexcept {
        return {{factors.x(), 0.0F, 0.0F}, {0.0F, factors.y(), 0.0F}, {0.0F, 0.0F, factors.z()}};
    }

private:
    std::array<Vector3, 3> cols_{};
};

[[nodiscard]] inline Matrix3 operator+(const Matrix3& a, const Matrix3& b) noexcept {
    return {a.col0() + b.col0(), a.col1() + b.col1(), a.col2() + b.col2()};
}

[[nodiscard]] inline Matrix3 operator-(const Matrix3& a, const Matrix3& b) noexcept {
    return {a.col0() - b.col0(), a.col1() - b.col1(), a.col2() - b.col2()};
}

[[nodiscard]] inline Matrix3 operator-(const Matrix3& a) noexcept {
    return {-a.col0(), -a.col1(), -a.col2()};
}

[[nodiscard]] inline Matrix3 operator*(const Matrix3& a, float s) noexcept {
    return {a.col0() * s, a.col1() * s, a.col2() * s};
}

[[nodiscard]] inline Matrix3 operator*(float s, const Matrix3& a) noexcept {
    return a * s;
}

[[nodiscard]] inline Vector3 operator*(const Matrix3& m, const Vector3& v) noexcept {
    __m128 result = _mm_mul_ps(m.col0().simd(), simd::splat<0>(v.simd()));
    result = simd::madd(m.col1().simd(), simd::splat<1>(v.simd()), result);
    return Vector3(simd::madd(m.col2().simd(), simd::splat<2>(v.simd()), result));
}

[[nodiscard]] inline Matrix3 operator*(const Matrix3& a, const Matrix3& b) noexcept {
    return {a * b.col0(), a * b.col1(), a * b.col2()};
}

[[nodiscard]] inline bool operator==(const Matrix3& a, const Matrix3& b) noexcept {
    return a.col0() == b.col0() && a.col1() == b.col1() && a.col2() == b.col2();
}

inline Matrix3& Matrix3::operator+=(const Matrix3& b) noexcept {
    return *this = *this + b;
}

inline Matrix3& Matrix3::operator-=(const Matrix3& b) noexcept {
    return *this = *this - b;
}

inline Matrix3& Matrix3::operator*=(float s) noexcept {
    return *this = *this * s;
}

inline Matrix3& Matrix3::operator*=(const Matrix3& b) noexcept {
    return *this = *this * b;
}

inline Matrix3::Matrix3(const Quat& unit) noexcept {
    const __m128 q = unit.simd();
    const __m128 q2 = _mm_add_ps(q, q);
    const __m128 wwww = simd::splat<3>(q);
    const __m128 yzx = _mm_shuffle_ps(q, q, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 zxy = _mm_shuffle_ps(q, q, _MM_SHUFFLE(3, 1, 0, 2));
    const __m128 yzx2 = _mm_shuffle_ps(q2, q2, _MM_SHUFFLE(3, 0, 2, 1));
    const __m128 zxy2 = _mm_shuffle_ps(q2, q2, _MM_SHUFFLE(3, 1, 0, 2));
    // sum = 2zx + 2yw, 2xy + 2zw, 2yz + 2xw
    const __m128 sum = _mm_add_ps(_mm_mul_ps(zxy, q2), _mm_mul_ps(yzx2, wwww));
    // diagonal = 1 - 2y2 - 2z2, 1 - 2z2 - 2x2, 1 - 2x2 - 2y2
    const __m128 one_minus = _mm_sub_ps(_mm_set1_ps(1.0F), _mm_mul_ps(yzx, yzx2));
    const __m128 diagonal = _mm_sub_ps(one_minus, _mm_mul_ps(zxy, zxy2));
    // difference = 2xy - 2zw, 2yz - 2xw, 2xz - 2yw
    const __m128 difference = _mm_sub_ps(_mm_mul_ps(yzx, q2), _mm_mul_ps(zxy2, wwww));
    const __m128 c0 = _mm_blend_ps(_mm_blend_ps(sum, diagonal, 0b0001), difference, 0b0100);
    const __m128 c1 = _mm_blend_ps(_mm_blend_ps(diagonal, difference, 0b0001), sum, 0b0100);
    const __m128 c2 = _mm_blend_ps(_mm_blend_ps(difference, sum, 0b0001), diagonal, 0b0100);
    cols_ = {Vector3(c0), Vector3(c1), Vector3(c2)};
}

inline Matrix3 Matrix3::rotation_x(float radians) noexcept {
    const float s = std::sin(radians);
    const float c = std::cos(radians);
    return {Vector3::x_axis(), {0.0F, c, s}, {0.0F, -s, c}};
}

inline Matrix3 Matrix3::rotation_y(float radians) noexcept {
    const float s = std::sin(radians);
    const float c = std::cos(radians);
    return {{c, 0.0F, -s}, Vector3::y_axis(), {s, 0.0F, c}};
}

inline Matrix3 Matrix3::rotation_z(float radians) noexcept {
    const float s = std::sin(radians);
    const float c = std::cos(radians);
    return {{c, s, 0.0F}, {-s, c, 0.0F}, Vector3::z_axis()};
}

inline Matrix3 Matrix3::rotation_zyx(const Vector3& radians_xyz) noexcept {
    const float sx = std::sin(radians_xyz.x());
    const float cx = std::cos(radians_xyz.x());
    const float sy = std::sin(radians_xyz.y());
    const float cy = std::cos(radians_xyz.y());
    const float sz = std::sin(radians_xyz.z());
    const float cz = std::cos(radians_xyz.z());
    const float cz_sy = cz * sy;
    const float sz_sy = sz * sy;
    const Vector3 col0(cz * cy, sz * cy, -sy);
    const Vector3 col1((cz_sy * sx) + (-sz * cx), (sz_sy * sx) + (cz * cx), cy * sx);
    const Vector3 col2((cz_sy * cx) - (-sz * sx), (sz_sy * cx) - (cz * sx), cy * cx);
    return {col0, col1, col2};
}

// Công thức Rodrigues: cột i = trục * trục[i] * (1 - cos) + phần sin, cos.
inline Matrix3 Matrix3::rotation(float radians, const Vector3& unit_axis) noexcept {
    const float s = std::sin(radians);
    const float c = std::cos(radians);
    const float x = unit_axis.x();
    const float y = unit_axis.y();
    const float z = unit_axis.z();
    const Vector3 spread = unit_axis * (1.0F - c);
    const Vector3 col0 = (spread * x) + Vector3(c, z * s, -y * s);
    const Vector3 col1 = (spread * y) + Vector3(-z * s, c, x * s);
    const Vector3 col2 = (spread * z) + Vector3(y * s, -x * s, c);
    return {col0, col1, col2};
}

// mat * scale: co giãn trước rồi mới tới mat (nhân từng cột).
[[nodiscard]] inline Matrix3 append_scale(const Matrix3& m, const Vector3& factors) noexcept {
    return {m.col0() * factors.x(), m.col1() * factors.y(), m.col2() * factors.z()};
}

// scale * mat: co giãn sau mat (nhân từng hàng).
[[nodiscard]] inline Matrix3 prepend_scale(const Vector3& factors, const Matrix3& m) noexcept {
    return {mul(m.col0(), factors), mul(m.col1(), factors), mul(m.col2(), factors)};
}

[[nodiscard]] inline Matrix3 mul(const Matrix3& a, const Matrix3& b) noexcept {
    return {mul(a.col0(), b.col0()), mul(a.col1(), b.col1()), mul(a.col2(), b.col2())};
}

[[nodiscard]] inline Matrix3 abs(const Matrix3& m) noexcept {
    return {abs(m.col0()), abs(m.col1()), abs(m.col2())};
}

[[nodiscard]] inline Matrix3 transpose(const Matrix3& m) noexcept {
    const auto rows = detail::transpose3(m.col0().simd(), m.col1().simd(), m.col2().simd());
    return {Vector3(rows.row0), Vector3(rows.row1), Vector3(rows.row2)};
}

[[nodiscard]] inline float determinant(const Matrix3& m) noexcept {
    return dot(m.col2(), cross(m.col0(), m.col1()));
}

// Ma trận suy biến (định thức 0) cho vô cùng hoặc NaN.
[[nodiscard]] inline Matrix3 inverse(const Matrix3& m) noexcept {
    const __m128 c01 = simd::cross3(m.col0().simd(), m.col1().simd());
    const __m128 c12 = simd::cross3(m.col1().simd(), m.col2().simd());
    const __m128 c20 = simd::cross3(m.col2().simd(), m.col0().simd());
    const __m128 scale = _mm_div_ps(_mm_set1_ps(1.0F), simd::dot3(c01, m.col2().simd()));
    const auto rows = detail::transpose3(c12, c20, c01);
    const Vector3 col0(_mm_mul_ps(rows.row0, scale));
    const Vector3 col1(_mm_mul_ps(rows.row1, scale));
    const Vector3 col2(_mm_mul_ps(rows.row2, scale));
    return {col0, col1, col2};
}

// Ma trận phụ hợp chuyển vị (cofactor), bằng determinant(m) * transpose(inverse(m)) nhưng không
// chia: đưa pháp tuyến từ không gian model sang world đúng cả với co giãn lệch và ma trận suy biến
// (adjoint của ShaderUtilities.h, theo Inigo Quilez). Kết quả chưa chuẩn hoá.
[[nodiscard]] inline Matrix3 adjoint(const Matrix3& m) noexcept {
    return {cross(m.col1(), m.col2()), cross(m.col2(), m.col0()), cross(m.col0(), m.col1())};
}

[[nodiscard]] inline Matrix3 select(const Matrix3& a, const Matrix3& b, bool pick_b) noexcept {
    return pick_b ? b : a;
}

// a * b^T: phần tử (hàng i, cột j) là a[i] * b[j].
[[nodiscard]] inline Matrix3 outer(const Vector3& a, const Vector3& b) noexcept {
    return {a * b.x(), a * b.y(), a * b.z()};
}

// Vectơ hàng nhân ma trận: v^T * m.
[[nodiscard]] inline Vector3 row_mul(const Vector3& v, const Matrix3& m) noexcept {
    return transpose(m) * v;
}

// Ma trận phản đối xứng của v: cross_matrix(v) * u = cross(v, u).
[[nodiscard]] inline Matrix3 cross_matrix(const Vector3& v) noexcept {
    return {{0.0F, v.z(), -v.y()}, {-v.z(), 0.0F, v.x()}, {v.y(), -v.x(), 0.0F}};
}

// cross_matrix(v) * m.
[[nodiscard]] inline Matrix3 cross_matrix_mul(const Vector3& v, const Matrix3& m) noexcept {
    return {cross(v, m.col0()), cross(v, m.col1()), cross(v, m.col2())};
}

// Xem ghi chú ở class Quat: ma trận phải là phép quay thuần. Bốn trường hợp theo phần tử đường
// chéo lớn nhất, như bản chọn không rẽ nhánh của gốc.
inline Quat::Quat(const Matrix3& rotation) noexcept {
    const float xx = rotation.col0().x();
    const float yy = rotation.col1().y();
    const float zz = rotation.col2().z();
    const float sum_z = rotation.col0().y() + rotation.col1().x();
    const float sum_y = rotation.col2().x() + rotation.col0().z();
    const float sum_x = rotation.col1().z() + rotation.col2().y();
    const float diff_x = rotation.col1().z() - rotation.col2().y();
    const float diff_y = rotation.col2().x() - rotation.col0().z();
    const float diff_z = rotation.col0().y() - rotation.col1().x();
    if (xx + yy + zz > 0.0F) {
        const float radicand = (xx + yy + zz) + 1.0F;
        const float scale = 0.5F / std::sqrt(radicand);
        value_ = _mm_setr_ps(diff_x * scale, diff_y * scale, diff_z * scale, radicand * scale);
    } else if (zz > xx && zz > yy) {
        const float radicand = (zz - xx - yy) + 1.0F;
        const float scale = 0.5F / std::sqrt(radicand);
        value_ = _mm_setr_ps(sum_y * scale, sum_x * scale, radicand * scale, diff_z * scale);
    } else if (yy > xx) {
        const float radicand = (yy - zz - xx) + 1.0F;
        const float scale = 0.5F / std::sqrt(radicand);
        value_ = _mm_setr_ps(sum_z * scale, radicand * scale, sum_x * scale, diff_y * scale);
    } else {
        const float radicand = (xx - yy - zz) + 1.0F;
        const float scale = 0.5F / std::sqrt(radicand);
        value_ = _mm_setr_ps(radicand * scale, sum_z * scale, sum_y * scale, diff_x * scale);
    }
}

// Biến đổi affine 3x4: ba cột của phần tuyến tính và cột tịnh tiến; hàng cuối ngầm là (0, 0, 0, 1).
class Transform3 {
public:
    Transform3() noexcept = default;
    Transform3(const Vector3& col0, const Vector3& col1, const Vector3& col2, const Vector3& col3) noexcept
        : cols_{col0, col1, col2, col3} {}
    Transform3(const Matrix3& linear, const Vector3& translation) noexcept
        : cols_{linear.col0(), linear.col1(), linear.col2(), translation} {}
    Transform3(const Quat& unit, const Vector3& translation) noexcept : Transform3(Matrix3(unit), translation) {}
    explicit Transform3(float scalar) noexcept
        : cols_{Vector3(scalar), Vector3(scalar), Vector3(scalar), Vector3(scalar)} {}

    [[nodiscard]] const Vector3& col0() const noexcept { return std::get<0>(cols_); }
    [[nodiscard]] const Vector3& col1() const noexcept { return std::get<1>(cols_); }
    [[nodiscard]] const Vector3& col2() const noexcept { return std::get<2>(cols_); }
    [[nodiscard]] const Vector3& col3() const noexcept { return std::get<3>(cols_); }
    [[nodiscard]] const Vector3& operator[](std::size_t col) const noexcept { return cols_.at(col); }
    [[nodiscard]] Vector3& operator[](std::size_t col) noexcept { return cols_.at(col); }
    [[nodiscard]] Vector4 row(std::size_t row) const noexcept {
        return {col0()[row], col1()[row], col2()[row], col3()[row]};
    }
    [[nodiscard]] float at(std::size_t col, std::size_t row) const noexcept { return cols_.at(col)[row]; }
    [[nodiscard]] Matrix3 upper3x3() const noexcept { return {col0(), col1(), col2()}; }
    [[nodiscard]] const Vector3& translation() const noexcept { return col3(); }

    Transform3& set_col(std::size_t col, const Vector3& v) noexcept {
        cols_.at(col) = v;
        return *this;
    }
    Transform3& set_row(std::size_t row, const Vector4& v) noexcept {
        std::get<0>(cols_).set(row, v.x());
        std::get<1>(cols_).set(row, v.y());
        std::get<2>(cols_).set(row, v.z());
        std::get<3>(cols_).set(row, v.w());
        return *this;
    }
    Transform3& set(std::size_t col, std::size_t row, float value) noexcept {
        cols_.at(col).set(row, value);
        return *this;
    }
    Transform3& set_upper3x3(const Matrix3& m) noexcept {
        cols_ = {m.col0(), m.col1(), m.col2(), col3()};
        return *this;
    }
    Transform3& set_translation(const Vector3& translation) noexcept {
        std::get<3>(cols_) = translation;
        return *this;
    }

    Transform3& operator*=(const Transform3& b) noexcept;

    [[nodiscard]] static Transform3 identity() noexcept { return {Matrix3::identity(), {}}; }
    [[nodiscard]] static Transform3 rotation_x(float radians) noexcept { return {Matrix3::rotation_x(radians), {}}; }
    [[nodiscard]] static Transform3 rotation_y(float radians) noexcept { return {Matrix3::rotation_y(radians), {}}; }
    [[nodiscard]] static Transform3 rotation_z(float radians) noexcept { return {Matrix3::rotation_z(radians), {}}; }
    [[nodiscard]] static Transform3 rotation_zyx(const Vector3& radians_xyz) noexcept {
        return {Matrix3::rotation_zyx(radians_xyz), {}};
    }
    [[nodiscard]] static Transform3 rotation(float radians, const Vector3& unit_axis) noexcept {
        return {Matrix3::rotation(radians, unit_axis), {}};
    }
    [[nodiscard]] static Transform3 rotation(const Quat& unit) noexcept { return {Matrix3(unit), {}}; }
    [[nodiscard]] static Transform3 scale(const Vector3& factors) noexcept { return {Matrix3::scale(factors), {}}; }
    [[nodiscard]] static Transform3 translation(const Vector3& offset) noexcept {
        return {Matrix3::identity(), offset};
    }

private:
    std::array<Vector3, 4> cols_{};
};

[[nodiscard]] inline Vector3 operator*(const Transform3& t, const Vector3& v) noexcept {
    return t.upper3x3() * v;
}

[[nodiscard]] inline Point3 operator*(const Transform3& t, const Point3& p) noexcept {
    const __m128 x = _mm_mul_ps(t.col0().simd(), simd::splat<0>(p.simd()));
    const __m128 y = _mm_mul_ps(t.col1().simd(), simd::splat<1>(p.simd()));
    const __m128 xz = simd::madd(t.col2().simd(), simd::splat<2>(p.simd()), x);
    return Point3(_mm_add_ps(xz, _mm_add_ps(t.col3().simd(), y)));
}

[[nodiscard]] inline Transform3 operator*(const Transform3& a, const Transform3& b) noexcept {
    return {a * b.col0(), a * b.col1(), a * b.col2(), Vector3(a * Point3(b.col3()))};
}

[[nodiscard]] inline bool operator==(const Transform3& a, const Transform3& b) noexcept {
    return a.upper3x3() == b.upper3x3() && a.col3() == b.col3();
}

inline Transform3& Transform3::operator*=(const Transform3& b) noexcept {
    return *this = *this * b;
}

[[nodiscard]] inline Transform3 append_scale(const Transform3& t, const Vector3& factors) noexcept {
    return {append_scale(t.upper3x3(), factors), t.col3()};
}

[[nodiscard]] inline Transform3 prepend_scale(const Vector3& factors, const Transform3& t) noexcept {
    return {prepend_scale(factors, t.upper3x3()), mul(t.col3(), factors)};
}

[[nodiscard]] inline Transform3 mul(const Transform3& a, const Transform3& b) noexcept {
    return {mul(a.upper3x3(), b.upper3x3()), mul(a.col3(), b.col3())};
}

[[nodiscard]] inline Transform3 abs(const Transform3& t) noexcept {
    return {abs(t.upper3x3()), abs(t.col3())};
}

// Nghịch đảo affine tổng quát: phần tuyến tính nghịch đảo, tịnh tiến = -(inv * t).
[[nodiscard]] inline Transform3 inverse(const Transform3& t) noexcept {
    const Matrix3 linear = inverse(t.upper3x3());
    return {linear, -(linear * t.col3())};
}

// Nghịch đảo khi phần tuyến tính trực chuẩn (quay thuần): chuyển vị thay cho nghịch đảo.
[[nodiscard]] inline Transform3 ortho_inverse(const Transform3& t) noexcept {
    const Matrix3 linear = transpose(t.upper3x3());
    return {linear, -(linear * t.col3())};
}

[[nodiscard]] inline Transform3 select(const Transform3& a, const Transform3& b, bool pick_b) noexcept {
    return pick_b ? b : a;
}

// Vị trí, hướng, tỉ lệ tách rời — đơn vị của hệ hoạt hình (AffineTransform của gốc).
struct AffineTransform {
    Vector3 translation;
    Quat rotation = Quat::identity();
    Vector3 scale = Vector3::one();

    [[nodiscard]] static AffineTransform identity() noexcept { return {}; }
};

// Mặt của cubemap theo thứ tự của D3D và Vulkan.
enum class CubeFace : std::uint8_t {
    kPositiveX,
    kNegativeX,
    kPositiveY,
    kNegativeY,
    kPositiveZ,
    kNegativeZ,
};

struct ViewWindow {
    float left = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;
    float top = 0.0F;
    float z_near = 0.0F;
    float z_far = 0.0F;
};

struct FovLens {
    float fov_x = 0.0F;
    float aspect_inverse = 0.0F;
    float z_near = 0.0F;
    float z_far = 0.0F;
};

// Sáu mặt cắt của khối nhìn, mỗi mặt (a, b, c, d) với ax + by + cz + d >= 0 ở phía trong.
struct ClipPlanes {
    Vector4 right{};
    Vector4 left{};
    Vector4 top{};
    Vector4 bottom{};
    Vector4 z_far{};
    Vector4 z_near{};
};

class Matrix4 {
public:
    Matrix4() noexcept = default;
    Matrix4(const Vector4& col0, const Vector4& col1, const Vector4& col2, const Vector4& col3) noexcept
        : cols_{col0, col1, col2, col3} {}
    // Hàng cuối (0, 0, 0, 1).
    explicit Matrix4(const Transform3& t) noexcept : Matrix4(t.upper3x3(), t.translation()) {}
    Matrix4(const Matrix3& linear, const Vector3& translation) noexcept;
    Matrix4(const Quat& unit, const Vector3& translation) noexcept : Matrix4(Matrix3(unit), translation) {}
    explicit Matrix4(float scalar) noexcept
        : cols_{Vector4(scalar), Vector4(scalar), Vector4(scalar), Vector4(scalar)} {}

    [[nodiscard]] const Vector4& col0() const noexcept { return std::get<0>(cols_); }
    [[nodiscard]] const Vector4& col1() const noexcept { return std::get<1>(cols_); }
    [[nodiscard]] const Vector4& col2() const noexcept { return std::get<2>(cols_); }
    [[nodiscard]] const Vector4& col3() const noexcept { return std::get<3>(cols_); }
    [[nodiscard]] const Vector4& operator[](std::size_t col) const noexcept { return cols_.at(col); }
    [[nodiscard]] Vector4& operator[](std::size_t col) noexcept { return cols_.at(col); }
    [[nodiscard]] Vector4 row(std::size_t row) const noexcept {
        return {col0()[row], col1()[row], col2()[row], col3()[row]};
    }
    [[nodiscard]] float at(std::size_t col, std::size_t row) const noexcept { return cols_.at(col)[row]; }
    [[nodiscard]] Matrix3 upper3x3() const noexcept { return {col0().xyz(), col1().xyz(), col2().xyz()}; }
    [[nodiscard]] Vector3 translation() const noexcept { return col3().xyz(); }

    Matrix4& set_col(std::size_t col, const Vector4& v) noexcept {
        cols_.at(col) = v;
        return *this;
    }
    Matrix4& set_row(std::size_t row, const Vector4& v) noexcept {
        std::get<0>(cols_).set(row, v.x());
        std::get<1>(cols_).set(row, v.y());
        std::get<2>(cols_).set(row, v.z());
        std::get<3>(cols_).set(row, v.w());
        return *this;
    }
    Matrix4& set(std::size_t col, std::size_t row, float value) noexcept {
        cols_.at(col).set(row, value);
        return *this;
    }
    // Thay ba hàng trên của ba cột đầu; giữ hàng cuối và cột tịnh tiến.
    Matrix4& set_upper3x3(const Matrix3& m) noexcept {
        std::get<0>(cols_).set_xyz(m.col0());
        std::get<1>(cols_).set_xyz(m.col1());
        std::get<2>(cols_).set_xyz(m.col2());
        return *this;
    }
    Matrix4& set_translation(const Vector3& translation) noexcept {
        std::get<3>(cols_).set_xyz(translation);
        return *this;
    }

    Matrix4& operator+=(const Matrix4& b) noexcept;
    Matrix4& operator-=(const Matrix4& b) noexcept;
    Matrix4& operator*=(float s) noexcept;
    Matrix4& operator*=(const Matrix4& b) noexcept;
    Matrix4& operator*=(const Transform3& b) noexcept;

    [[nodiscard]] static Matrix4 identity() noexcept {
        return {Vector4::x_axis(), Vector4::y_axis(), Vector4::z_axis(), Vector4::w_axis()};
    }
    [[nodiscard]] static Matrix4 rotation_x(float radians) noexcept { return {Matrix3::rotation_x(radians), {}}; }
    [[nodiscard]] static Matrix4 rotation_y(float radians) noexcept { return {Matrix3::rotation_y(radians), {}}; }
    [[nodiscard]] static Matrix4 rotation_z(float radians) noexcept { return {Matrix3::rotation_z(radians), {}}; }
    [[nodiscard]] static Matrix4 rotation_zyx(const Vector3& radians_xyz) noexcept {
        return {Matrix3::rotation_zyx(radians_xyz), {}};
    }
    [[nodiscard]] static Matrix4 rotation(float radians, const Vector3& unit_axis) noexcept {
        return {Matrix3::rotation(radians, unit_axis), {}};
    }
    [[nodiscard]] static Matrix4 rotation(const Quat& unit) noexcept { return {Matrix3(unit), {}}; }
    // Ry * Rx; nghịch đảo của rotation_xy(x, y) là rotation_yx(-y, -x).
    [[nodiscard]] static Matrix4 rotation_yx(float radians_y, float radians_x) noexcept;
    // Rx * Ry.
    [[nodiscard]] static Matrix4 rotation_xy(float radians_x, float radians_y) noexcept;
    [[nodiscard]] static Matrix4 scale(const Vector3& factors) noexcept { return {Matrix3::scale(factors), {}}; }
    [[nodiscard]] static Matrix4 translation(const Vector3& offset) noexcept { return {Matrix3::identity(), offset}; }

    // Ma trận nhìn: thế giới sang không gian camera, tay trái (nhìn theo +Z) hoặc tay phải (-Z).
    [[nodiscard]] static Matrix4 look_at_lh(const Point3& eye, const Point3& target, const Vector3& up) noexcept;
    [[nodiscard]] static Matrix4 look_at_rh(const Point3& eye, const Point3& target, const Vector3& up) noexcept;

    // Phối cảnh từ hình chữ nhật trên mặt gần, có thể lệch tâm.
    [[nodiscard]] static Matrix4 frustum_lh(ViewWindow window) noexcept;
    // Phối cảnh theo góc nhìn NGANG và nghịch đảo tỉ lệ khung (cao / rộng).
    [[nodiscard]] static Matrix4 perspective_lh(FovLens lens) noexcept;
    [[nodiscard]] static Matrix4 perspective_rh(FovLens lens) noexcept;
    // Z đảo: mặt gần ra z = 1, mặt xa ra z = 0 (độ chính xác float dồn về phía xa).
    [[nodiscard]] static Matrix4 perspective_lh_reverse_z(FovLens lens) noexcept {
        // Z đảo: gần và xa đổi chỗ có chủ ý.
        FovLens swapped = lens;
        swapped.z_near = lens.z_far;
        swapped.z_far = lens.z_near;
        return perspective_lh(swapped);
    }
    [[nodiscard]] static Matrix4 orthographic_lh(ViewWindow window) noexcept;
    [[nodiscard]] static Matrix4 orthographic_rh(ViewWindow window) noexcept;
    [[nodiscard]] static Matrix4 orthographic_lh_reverse_z(ViewWindow window) noexcept {
        // Z đảo: gần và xa đổi chỗ có chủ ý.
        ViewWindow swapped = window;
        swapped.z_near = window.z_far;
        swapped.z_far = window.z_near;
        return orthographic_lh(swapped);
    }
    // Phối cảnh 90 độ, khung vuông, cho một mặt cubemap.
    [[nodiscard]] static Matrix4 cube_projection_lh(float z_near, float z_far) noexcept;
    [[nodiscard]] static Matrix4 cube_projection_rh(float z_near, float z_far) noexcept;
    // Ma trận nhìn từ tâm cubemap ra một mặt.
    [[nodiscard]] static Matrix4 cube_view(CubeFace face) noexcept;

private:
    std::array<Vector4, 4> cols_{};
};

inline Matrix4::Matrix4(const Matrix3& linear, const Vector3& translation) noexcept {
    const Vector4 col0(linear.col0());
    const Vector4 col1(linear.col1());
    const Vector4 col2(linear.col2());
    cols_ = {col0, col1, col2, Vector4(translation, 1.0F)};
}

[[nodiscard]] inline Matrix4 operator+(const Matrix4& a, const Matrix4& b) noexcept {
    return {a.col0() + b.col0(), a.col1() + b.col1(), a.col2() + b.col2(), a.col3() + b.col3()};
}

[[nodiscard]] inline Matrix4 operator-(const Matrix4& a, const Matrix4& b) noexcept {
    return {a.col0() - b.col0(), a.col1() - b.col1(), a.col2() - b.col2(), a.col3() - b.col3()};
}

[[nodiscard]] inline Matrix4 operator-(const Matrix4& a) noexcept {
    return {-a.col0(), -a.col1(), -a.col2(), -a.col3()};
}

[[nodiscard]] inline Matrix4 operator*(const Matrix4& a, float s) noexcept {
    return {a.col0() * s, a.col1() * s, a.col2() * s, a.col3() * s};
}

[[nodiscard]] inline Matrix4 operator*(float s, const Matrix4& a) noexcept {
    return a * s;
}

// (c0*x + c1*y) + (c2*z + c3*w).
[[nodiscard]] inline Vector4 operator*(const Matrix4& m, const Vector4& v) noexcept {
    const __m128 x = _mm_mul_ps(m.col0().simd(), simd::splat<0>(v.simd()));
    const __m128 y = _mm_mul_ps(m.col1().simd(), simd::splat<1>(v.simd()));
    const __m128 z = _mm_mul_ps(m.col2().simd(), simd::splat<2>(v.simd()));
    const __m128 w = _mm_mul_ps(m.col3().simd(), simd::splat<3>(v.simd()));
    return Vector4(_mm_add_ps(_mm_add_ps(x, y), _mm_add_ps(z, w)));
}

// Hướng: w = 0, không cộng tịnh tiến.
[[nodiscard]] inline Vector4 operator*(const Matrix4& m, const Vector3& v) noexcept {
    const __m128 x = _mm_mul_ps(m.col0().simd(), simd::splat<0>(v.simd()));
    const __m128 y = _mm_mul_ps(m.col1().simd(), simd::splat<1>(v.simd()));
    const __m128 z = _mm_mul_ps(m.col2().simd(), simd::splat<2>(v.simd()));
    return Vector4(_mm_add_ps(_mm_add_ps(x, y), z));
}

// Vị trí: w = 1, cộng cột tịnh tiến.
[[nodiscard]] inline Vector4 operator*(const Matrix4& m, const Point3& p) noexcept {
    const __m128 x = _mm_mul_ps(m.col0().simd(), simd::splat<0>(p.simd()));
    const __m128 y = _mm_mul_ps(m.col1().simd(), simd::splat<1>(p.simd()));
    const __m128 z = _mm_mul_ps(m.col2().simd(), simd::splat<2>(p.simd()));
    return Vector4(_mm_add_ps(_mm_add_ps(x, y), _mm_add_ps(z, m.col3().simd())));
}

[[nodiscard]] inline Matrix4 operator*(const Matrix4& a, const Matrix4& b) noexcept {
    return {a * b.col0(), a * b.col1(), a * b.col2(), a * b.col3()};
}

[[nodiscard]] inline Matrix4 operator*(const Matrix4& a, const Transform3& b) noexcept {
    return {a * b.col0(), a * b.col1(), a * b.col2(), a * Point3(b.col3())};
}

[[nodiscard]] inline bool operator==(const Matrix4& a, const Matrix4& b) noexcept {
    const bool first = a.col0() == b.col0() && a.col1() == b.col1();
    return first && a.col2() == b.col2() && a.col3() == b.col3();
}

inline Matrix4& Matrix4::operator+=(const Matrix4& b) noexcept {
    return *this = *this + b;
}

inline Matrix4& Matrix4::operator-=(const Matrix4& b) noexcept {
    return *this = *this - b;
}

inline Matrix4& Matrix4::operator*=(float s) noexcept {
    return *this = *this * s;
}

inline Matrix4& Matrix4::operator*=(const Matrix4& b) noexcept {
    return *this = *this * b;
}

inline Matrix4& Matrix4::operator*=(const Transform3& b) noexcept {
    return *this = *this * b;
}

[[nodiscard]] inline Matrix4 append_scale(const Matrix4& m, const Vector3& factors) noexcept {
    return {m.col0() * factors.x(), m.col1() * factors.y(), m.col2() * factors.z(), m.col3()};
}

[[nodiscard]] inline Matrix4 prepend_scale(const Vector3& factors, const Matrix4& m) noexcept {
    const Vector4 scale(factors, 1.0F);
    return {mul(m.col0(), scale), mul(m.col1(), scale), mul(m.col2(), scale), mul(m.col3(), scale)};
}

[[nodiscard]] inline Matrix4 mul(const Matrix4& a, const Matrix4& b) noexcept {
    return {mul(a.col0(), b.col0()), mul(a.col1(), b.col1()), mul(a.col2(), b.col2()), mul(a.col3(), b.col3())};
}

[[nodiscard]] inline Matrix4 abs(const Matrix4& m) noexcept {
    return {abs(m.col0()), abs(m.col1()), abs(m.col2()), abs(m.col3())};
}

[[nodiscard]] inline Matrix4 transpose(const Matrix4& m) noexcept {
    const __m128 low02 = _mm_unpacklo_ps(m.col0().simd(), m.col2().simd());
    const __m128 low13 = _mm_unpacklo_ps(m.col1().simd(), m.col3().simd());
    const __m128 high02 = _mm_unpackhi_ps(m.col0().simd(), m.col2().simd());
    const __m128 high13 = _mm_unpackhi_ps(m.col1().simd(), m.col3().simd());
    const Vector4 row0(_mm_unpacklo_ps(low02, low13));
    const Vector4 row1(_mm_unpackhi_ps(low02, low13));
    const Vector4 row2(_mm_unpacklo_ps(high02, high13));
    const Vector4 row3(_mm_unpackhi_ps(high02, high13));
    return {row0, row1, row2, row3};
}

[[nodiscard]] inline Matrix4 select(const Matrix4& a, const Matrix4& b, bool pick_b) noexcept {
    return pick_b ? b : a;
}

[[nodiscard]] inline Matrix4 outer(const Vector4& a, const Vector4& b) noexcept {
    return {a * b.x(), a * b.y(), a * b.z(), a * b.w()};
}

namespace detail {

// Ba vectơ tiểu định thức chung của hai cột a, b (thuật toán minterm của Intel): hàng của ma trận
// phụ hợp là tổ hợp tuyến tính của chúng với một cột thứ ba đã xoay làn.
struct Minors {
    __m128 r1;
    __m128 r2;
    __m128 r3;
};

// Hai cột theo đúng thứ tự của chúng trong ma trận,
// như cross(a, b) (ngoại lệ của API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] inline Minors minors(__m128 a, __m128 b) noexcept {
    const __m128 a1 = ror<1>(a);
    const __m128 va = _mm_mul_ps(a1, ror<2>(b));
    const __m128 vb = _mm_mul_ps(a1, ror<3>(b));
    const __m128 vc = _mm_mul_ps(a1, b);
    return Minors{
        .r1 = _mm_sub_ps(ror<1>(va), ror<2>(vc)),
        .r2 = _mm_sub_ps(ror<2>(vb), vb),
        .r3 = _mm_sub_ps(va, ror<1>(vc)),
    };
}

// ror<1>(c)*r1 + ror<2>(c)*r2 + ror<3>(c)*r3.
[[nodiscard]] inline __m128 combine(__m128 c, const Minors& m) noexcept {
    const __m128 first = _mm_mul_ps(ror<1>(c), m.r1);
    const __m128 second = _mm_add_ps(first, _mm_mul_ps(ror<2>(c), m.r2));
    return _mm_add_ps(second, _mm_mul_ps(ror<3>(c), m.r3));
}

// Định thức ở làn 0, từ tổ hợp của cột 1 với tiểu định thức của cột 2, 3.
[[nodiscard]] inline __m128 determinant4(__m128 col0, __m128 cofactor) noexcept {
    const __m128 products = _mm_mul_ps(cofactor, col0);
    const __m128 pairs = _mm_add_ps(products, _mm_movehl_ps(products, products));
    return _mm_sub_ss(pairs, _mm_shuffle_ps(pairs, pairs, 1));
}

} // namespace detail

[[nodiscard]] inline float determinant(const Matrix4& m) noexcept {
    const detail::Minors lower = detail::minors(m.col2().simd(), m.col3().simd());
    const __m128 cofactor = detail::combine(m.col1().simd(), lower);
    return _mm_cvtss_f32(detail::determinant4(m.col0().simd(), cofactor));
}

// Nghịch đảo tổng quát. Ma trận suy biến cho vô cùng hoặc NaN.
[[nodiscard]] inline Matrix4 inverse(const Matrix4& m) noexcept {
    const int sign_bit = static_cast<int>(0x8000'0000U);
    const __m128i odd_bits = _mm_setr_epi32(0, sign_bit, 0, sign_bit);
    const __m128i even_bits = _mm_setr_epi32(sign_bit, 0, sign_bit, 0);
    const __m128 sign_odd = _mm_castsi128_ps(odd_bits);
    const __m128 sign_even = _mm_castsi128_ps(even_bits);
    const __m128 c0 = m.col0().simd();
    const __m128 c1 = m.col1().simd();
    const __m128 c2 = m.col2().simd();
    const __m128 c3 = m.col3().simd();
    const detail::Minors lower = detail::minors(c2, c3);
    const __m128 cofactor0 = detail::combine(c1, lower);
    const __m128 determinant = detail::determinant4(c0, cofactor0);
    const __m128 inverse_det = _mm_div_ss(_mm_set_ss(1.0F), determinant);
    const __m128 scale = simd::splat<0>(inverse_det);
    const detail::Minors upper = detail::minors(c0, c1);
    const __m128 row0 = _mm_mul_ps(_mm_xor_ps(cofactor0, sign_odd), scale);
    const __m128 row1 = _mm_mul_ps(_mm_xor_ps(detail::combine(c0, lower), sign_even), scale);
    const __m128 row2 = _mm_mul_ps(_mm_xor_ps(detail::combine(c3, upper), sign_odd), scale);
    const __m128 row3 = _mm_mul_ps(_mm_xor_ps(detail::combine(c2, upper), sign_even), scale);
    return transpose(Matrix4(Vector4(row0), Vector4(row1), Vector4(row2), Vector4(row3)));
}

// Nghịch đảo khi hàng cuối là (0, 0, 0, 1).
[[nodiscard]] inline Matrix4 affine_inverse(const Matrix4& m) noexcept {
    return Matrix4(inverse(Transform3(m.upper3x3(), m.translation())));
}

// Nghịch đảo khi ma trận là quay thuần cộng tịnh tiến.
[[nodiscard]] inline Matrix4 ortho_inverse(const Matrix4& m) noexcept {
    return Matrix4(ortho_inverse(Transform3(m.upper3x3(), m.translation())));
}

// adjoint của phần 3x3 trên trái: ma trận pháp tuyến của một ma trận model (adjoint_float4x4).
[[nodiscard]] inline Matrix3 adjoint(const Matrix4& m) noexcept {
    return adjoint(m.upper3x3());
}

inline Matrix4 Matrix4::rotation_yx(float radians_y, float radians_x) noexcept {
    const float cx = std::cos(radians_x);
    const float sx = std::sin(radians_x);
    const float cy = std::cos(radians_y);
    const float sy = std::sin(radians_y);
    const Vector4 col0(cy, 0.0F, -sy, 0.0F);
    const Vector4 col1(sy * sx, cx, cy * sx, 0.0F);
    const Vector4 col2(sy * cx, -sx, cy * cx, 0.0F);
    return {col0, col1, col2, Vector4::w_axis()};
}

inline Matrix4 Matrix4::rotation_xy(float radians_x, float radians_y) noexcept {
    const float cx = std::cos(radians_x);
    const float sx = std::sin(radians_x);
    const float cy = std::cos(radians_y);
    const float sy = std::sin(radians_y);
    const Vector4 col0(cy, sx * sy, cx * -sy, 0.0F);
    const Vector4 col1(0.0F, cx, sx, 0.0F);
    const Vector4 col2(sy, -sx * cy, cx * cy, 0.0F);
    return {col0, col1, col2, Vector4::w_axis()};
}

inline Matrix4 Matrix4::look_at_lh(const Point3& eye, const Point3& target, const Vector3& up) noexcept {
    const Vector3 forward = normalize(target - eye);
    const Vector3 right = normalize(cross(normalize(up), forward));
    const Vector3 real_up = cross(forward, right);
    return ortho_inverse(Matrix4(Matrix3(right, real_up, forward), Vector3(eye)));
}

inline Matrix4 Matrix4::look_at_rh(const Point3& eye, const Point3& target, const Vector3& up) noexcept {
    const Vector3 backward = normalize(eye - target);
    const Vector3 right = normalize(cross(normalize(up), backward));
    const Vector3 real_up = cross(backward, right);
    return ortho_inverse(Matrix4(Matrix3(right, real_up, backward), Vector3(eye)));
}

inline Matrix4 Matrix4::frustum_lh(ViewWindow window) noexcept {
    const float left = window.left;
    const float right = window.right;
    const float bottom = window.bottom;
    const float top = window.top;
    const float z_near = window.z_near;
    const float z_far = window.z_far;
    const float width = right - left;
    const float height = top - bottom;
    const float depth = z_near - z_far;
    const float near2 = z_near + z_near;
    const Vector4 col0(near2 / width, 0.0F, 0.0F, 0.0F);
    const Vector4 col1(0.0F, near2 / height, 0.0F, 0.0F);
    const Vector4 col2(-(left + right) / width, -(top + bottom) / height, -(z_far / depth), 1.0F);
    const Vector4 col3(0.0F, 0.0F, (z_near / depth) * z_far, 0.0F);
    return {col0, col1, col2, col3};
}

inline Matrix4 Matrix4::perspective_lh(FovLens lens) noexcept {
    const float fov_x = lens.fov_x;
    const float aspect_inverse = lens.aspect_inverse;
    const float z_near = lens.z_near;
    const float z_far = lens.z_far;
    const float focal = std::tan(kHalfPi - (fov_x * 0.5F));
    const float range_inverse = 1.0F / (z_far - z_near);
    const Vector4 col0(focal, 0.0F, 0.0F, 0.0F);
    const Vector4 col1(0.0F, focal / aspect_inverse, 0.0F, 0.0F);
    const Vector4 col2(0.0F, 0.0F, z_far * range_inverse, 1.0F);
    const Vector4 col3(0.0F, 0.0F, -z_near * z_far * range_inverse, 0.0F);
    return {col0, col1, col2, col3};
}

inline Matrix4 Matrix4::perspective_rh(FovLens lens) noexcept {
    Matrix4 m = perspective_lh(lens);
    return m.set_col(2, -m.col2());
}

inline Matrix4 Matrix4::orthographic_lh(ViewWindow window) noexcept {
    const float left = window.left;
    const float right = window.right;
    const float bottom = window.bottom;
    const float top = window.top;
    const float z_near = window.z_near;
    const float z_far = window.z_far;
    const float width = right - left;
    const float height = top - bottom;
    const float depth = z_far - z_near;
    const Vector4 col0(2.0F / width, 0.0F, 0.0F, 0.0F);
    const Vector4 col1(0.0F, 2.0F / height, 0.0F, 0.0F);
    const Vector4 col2(0.0F, 0.0F, 1.0F / depth, 0.0F);
    const Vector4 col3(-(right + left) / width, -(top + bottom) / height, -z_near / depth, 1.0F);
    return {col0, col1, col2, col3};
}

inline Matrix4 Matrix4::orthographic_rh(ViewWindow window) noexcept {
    Matrix4 m = orthographic_lh(window);
    return m.set_col(2, -m.col2());
}

inline Matrix4 Matrix4::cube_projection_lh(float z_near, float z_far) noexcept {
    const Vector4 col2(0.0F, 0.0F, z_far / (z_far - z_near), 1.0F);
    const Vector4 col3(0.0F, 0.0F, (z_far * z_near) / (z_near - z_far), 0.0F);
    return {Vector4::x_axis(), Vector4::y_axis(), col2, col3};
}

inline Matrix4 Matrix4::cube_projection_rh(float z_near, float z_far) noexcept {
    Matrix4 m = cube_projection_lh(z_near, z_far);
    return m.set_col(2, -m.col2());
}

inline Matrix4 Matrix4::cube_view(CubeFace face) noexcept {
    const Vector4 x = Vector4::x_axis();
    const Vector4 y = Vector4::y_axis();
    const Vector4 z = Vector4::z_axis();
    const Vector4 w = Vector4::w_axis();
    switch (face) {
    case CubeFace::kPositiveX: return {z, y, -x, w};
    case CubeFace::kNegativeX: return {-z, y, x, w};
    case CubeFace::kPositiveY: return {x, z, -y, w};
    case CubeFace::kNegativeY: return {x, -z, y, w};
    case CubeFace::kPositiveZ: return {x, y, z, w};
    case CubeFace::kNegativeZ: return {-x, y, -z, w};
    }
    return identity();
}

// Sang kiểu lưu trữ: các float nằm liền nhau theo cột, để chép vào bộ đệm hay đưa cho API nhận
// float* (toFloatPtr của gốc ép con trỏ thẳng vào kiểu SIMD).
[[nodiscard]] inline std::array<Float3, 3> store(const Matrix3& m) noexcept {
    return {store(m.col0()), store(m.col1()), store(m.col2())};
}

[[nodiscard]] inline std::array<Float3, 4> store(const Transform3& t) noexcept {
    return {store(t.col0()), store(t.col1()), store(t.col2()), store(t.col3())};
}

[[nodiscard]] inline std::array<Float4, 4> store(const Matrix4& m) noexcept {
    return {store(m.col0()), store(m.col1()), store(m.col2()), store(m.col3())};
}

[[nodiscard]] inline Matrix3 load(const std::array<Float3, 3>& cols) noexcept {
    const auto& [col0, col1, col2] = cols;
    return {load(col0), load(col1), load(col2)};
}

[[nodiscard]] inline Transform3 load(const std::array<Float3, 4>& cols) noexcept {
    const auto& [col0, col1, col2, col3] = cols;
    return {load(col0), load(col1), load(col2), load(col3)};
}

[[nodiscard]] inline Matrix4 load(const std::array<Float4, 4>& cols) noexcept {
    const auto& [col0, col1, col2, col3] = cols;
    return {load(col0), load(col1), load(col2), load(col3)};
}

static_assert(sizeof(std::array<Float4, 4>) == 16 * sizeof(float));

// Góc nhìn ngang sang dọc và ngược lại, theo nghịch đảo tỉ lệ khung (cao / rộng).
[[nodiscard]] inline float fov_x_to_y(float fov_x, float aspect_inverse) noexcept {
    return 2.0F * std::atan(std::tan(fov_x / 2.0F) * aspect_inverse);
}

[[nodiscard]] inline float fov_y_to_x(float fov_y, float aspect_inverse) noexcept {
    return 2.0F * std::atan(std::tan(fov_y / 2.0F) / aspect_inverse);
}

// Sáu mặt cắt của ma trận nhìn-chiếu vp (z của NDC trong [0, 1]): điểm trong khối nhìn khi mọi
// dot(mặt, (p, 1)) >= 0. Với ma trận Z đảo thì z_near là mặt xa hình học và ngược lại. normalized:
// chia cho độ dài pháp tuyến để dot ra khoảng cách thật.
[[nodiscard]] inline ClipPlanes clip_planes(const Matrix4& vp, bool normalized) noexcept {
    const Vector4 row0 = vp.row(0);
    const Vector4 row1 = vp.row(1);
    const Vector4 row2 = vp.row(2);
    const Vector4 row3 = vp.row(3);
    ClipPlanes planes{
        .right = row3 - row0,
        .left = row3 + row0,
        .top = row3 - row1,
        .bottom = row3 + row1,
        .z_far = row3 - row2,
        .z_near = row2,
    };
    if (!normalized) return planes;
    planes.right /= length(planes.right.xyz());
    planes.left /= length(planes.left.xyz());
    planes.top /= length(planes.top.xyz());
    planes.bottom /= length(planes.bottom.xyz());
    planes.z_far /= length(planes.z_far.xyz());
    planes.z_near /= length(planes.z_near.xyz());
    return planes;
}

// Ma trận 2x2 vô hướng, cột trước (vec2d.hpp của gốc).
struct Matrix2 {
    Vector2 col0{};
    Vector2 col1{};

    // Hai hàng như trên giấy: hàng 0 rồi hàng 1.
    [[nodiscard]] static constexpr Matrix2 from_rows(Vector2 row0, Vector2 row1) noexcept {
        return {.col0 = {.x = row0.x, .y = row1.x}, .col1 = {.x = row0.y, .y = row1.y}};
    }
    [[nodiscard]] static constexpr Matrix2 identity() noexcept {
        const Vector2 row0{.x = 1.0F, .y = 0.0F};
        const Vector2 row1{.x = 0.0F, .y = 1.0F};
        return from_rows(row0, row1);
    }
    // (cos sin / -sin cos) như gốc: quay THUẬN chiều kim đồng hồ khi +Y hướng lên.
    [[nodiscard]] static Matrix2 rotation(float radians) noexcept {
        const float c = std::cos(radians);
        const float s = std::sin(radians);
        const Vector2 row0{.x = c, .y = s};
        const Vector2 row1{.x = -s, .y = c};
        return from_rows(row0, row1);
    }

    [[nodiscard]] constexpr Vector2 col(std::size_t i) const noexcept { return i == 0 ? col0 : col1; }
    [[nodiscard]] constexpr float at(std::size_t column, std::size_t row) const noexcept { return col(column)[row]; }

    friend constexpr bool operator==(const Matrix2&, const Matrix2&) = default;
    friend constexpr Matrix2 operator+(const Matrix2& m, const Matrix2& n) noexcept {
        return {.col0 = m.col0 + n.col0, .col1 = m.col1 + n.col1};
    }
    friend constexpr Matrix2 operator-(const Matrix2& m, const Matrix2& n) noexcept {
        return {.col0 = m.col0 - n.col0, .col1 = m.col1 - n.col1};
    }
    friend constexpr Matrix2 operator-(const Matrix2& m) noexcept { return {.col0 = -m.col0, .col1 = -m.col1}; }
    friend constexpr Vector2 operator*(const Matrix2& m, Vector2 v) noexcept { return (m.col0 * v.x) + (m.col1 * v.y); }
    friend constexpr Matrix2 operator*(const Matrix2& m, const Matrix2& n) noexcept {
        return {.col0 = m * n.col0, .col1 = m * n.col1};
    }
    friend constexpr Matrix2 operator*(const Matrix2& m, float s) noexcept {
        return {.col0 = m.col0 * s, .col1 = m.col1 * s};
    }
};

[[nodiscard]] constexpr float determinant(const Matrix2& m) noexcept {
    return (m.col0.x * m.col1.y) - (m.col1.x * m.col0.y);
}

// operator! của gốc. Ma trận suy biến cho vô cùng hoặc NaN.
[[nodiscard]] constexpr Matrix2 inverse(const Matrix2& m) noexcept {
    const float scale = 1.0F / determinant(m);
    const Vector2 row0{.x = m.col1.y, .y = -m.col1.x};
    const Vector2 row1{.x = -m.col0.y, .y = m.col0.x};
    return Matrix2::from_rows(row0, row1) * scale;
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
