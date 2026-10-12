// Nghịch đảo ma trận 4x4 theo phần phụ đại số, viết một lần cho mọi kiểu phần tử: double của
// Matrix4d (math/double.hpp) và Vector4 — bốn ma trận song song — của SoaMatrix4 (math/soa.hpp).
// Công thức và thứ tự phép tính theo Invert của soa/float4x4.hpp trong _Ref (từ ozz-animation).
// Nguồn: Forge2 src/math/cofactor.hpp@d7fcd76. Khác gốc (so với Forge2): mười tám định thức con
// 2x2 của cofactors tính ở hàm riêng minors2x2 (hàm gốc dài 56 dòng), từng công thức và thứ tự
// của chúng giữ nguyên.
#pragma once

#include <array>
#include <cstddef>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math::detail {

// Phần tử theo cột rồi hàng: grid[c][r].
template <class T>
using Grid4 = std::array<std::array<T, 4>, 4>;

template <class T>
struct Cofactors {
    // Ma trận phụ hợp: nghịch đảo nhân với định thức.
    Grid4<T> adjugate;
    T determinant;
};

// Ba phần tử của một cột, nhân lần lượt với ba định thức con khi khai triển.
template <class T>
struct Triple {
    T p;
    T q;
    T r;
};

// Số định thức con 2x2 của cofactors
// (a00..a18, không có a11).
inline constexpr std::size_t kMinorCount = 18;

template <class T>
using Minors2x2 = std::array<T, kMinorCount>;

// Khác gốc: phần đầu của cofactors tách ra đây; công thức và thứ tự tính giữ nguyên.
template <class T, class Times>
[[nodiscard]] constexpr Minors2x2<T> minors2x2(const Grid4<T>& m, Times times) noexcept {
    const auto& [c1x, c1y, c1z, c1w] = std::get<1>(m);
    const auto& [c2x, c2y, c2z, c2w] = std::get<2>(m);
    const auto& [c3x, c3y, c3z, c3w] = std::get<3>(m);
    // p*q - r*s: định thức con 2x2.
    const auto minor = [&times](const T& p, const T& q, const T& r, const T& s) { return times(p, q) - times(r, s); };
    const T a00 = minor(c2z, c3w, c3z, c2w);
    const T a01 = minor(c2y, c3w, c3y, c2w);
    const T a02 = minor(c2y, c3z, c3y, c2z);
    const T a03 = minor(c2x, c3w, c3x, c2w);
    const T a04 = minor(c2x, c3z, c3x, c2z);
    const T a05 = minor(c2x, c3y, c3x, c2y);
    const T a06 = minor(c1z, c3w, c3z, c1w);
    const T a07 = minor(c1y, c3w, c3y, c1w);
    const T a08 = minor(c1y, c3z, c3y, c1z);
    const T a09 = minor(c1x, c3w, c3x, c1w);
    const T a10 = minor(c1x, c3z, c3x, c1z);
    const T a12 = minor(c1x, c3y, c3x, c1y);
    const T a13 = minor(c1z, c2w, c2z, c1w);
    const T a14 = minor(c1y, c2w, c2y, c1w);
    const T a15 = minor(c1y, c2z, c2y, c1z);
    const T a16 = minor(c1x, c2w, c2x, c1w);
    const T a17 = minor(c1x, c2z, c2x, c1z);
    const T a18 = minor(c1x, c2y, c2x, c1y);
    return {a00, a01, a02, a03, a04, a05, a06, a07, a08, a09, a10, a12, a13, a14, a15, a16, a17, a18};
}

// times(a, b) là phép nhân của T; T cần thêm +, - hai ngôi và - một ngôi.
template <class T, class Times>
[[nodiscard]] constexpr Cofactors<T> cofactors(const Grid4<T>& m, Times times) noexcept {
    const auto& [c0x, c0y, c0z, c0w] = std::get<0>(m);
    const auto& [c1x, c1y, c1z, c1w] = std::get<1>(m);
    const auto [a00, a01, a02, a03, a04, a05, a06, a07, a08, a09, a10, a12, a13, a14, a15, a16, a17, a18] =
        minors2x2(m, times);
    // p*a - q*b + r*c, và bản đổi dấu (-p)*a + q*b - r*c.
    const auto expand = [&times](const Triple<T>& row, const T& a, const T& b, const T& c) {
        return times(row.p, a) - times(row.q, b) + times(row.r, c);
    };
    const auto expand_negated = [&times](const Triple<T>& row, const T& a, const T& b, const T& c) {
        return times(-row.p, a) + times(row.q, b) - times(row.r, c);
    };
    const T b0x = expand({c1y, c1z, c1w}, a00, a01, a02);
    const T b1x = expand_negated({c1x, c1z, c1w}, a00, a03, a04);
    const T b2x = expand({c1x, c1y, c1w}, a01, a03, a05);
    const T b3x = expand_negated({c1x, c1y, c1z}, a02, a04, a05);
    const T b0y = expand_negated({c0y, c0z, c0w}, a00, a01, a02);
    const T b1y = expand({c0x, c0z, c0w}, a00, a03, a04);
    const T b2y = expand_negated({c0x, c0y, c0w}, a01, a03, a05);
    const T b3y = expand({c0x, c0y, c0z}, a02, a04, a05);
    const T b0z = expand({c0y, c0z, c0w}, a06, a07, a08);
    const T b1z = expand_negated({c0x, c0z, c0w}, a06, a09, a10);
    const T b2z = expand({c0x, c0y, c0w}, a07, a09, a12);
    const T b3z = expand_negated({c0x, c0y, c0z}, a08, a10, a12);
    const T b0w = expand_negated({c0y, c0z, c0w}, a13, a14, a15);
    const T b1w = expand({c0x, c0z, c0w}, a13, a16, a17);
    const T b2w = expand_negated({c0x, c0y, c0w}, a14, a16, a18);
    const T b3w = expand({c0x, c0y, c0z}, a15, a17, a18);
    const T determinant = times(c0x, b0x) + times(c0y, b1x) + times(c0z, b2x) + times(c0w, b3x);
    const std::array<T, 4> col0{b0x, b0y, b0z, b0w};
    const std::array<T, 4> col1{b1x, b1y, b1z, b1w};
    const std::array<T, 4> col2{b2x, b2y, b2z, b2w};
    const std::array<T, 4> col3{b3x, b3y, b3z, b3w};
    return {.adjugate = {col0, col1, col2, col3}, .determinant = determinant};
}

} // namespace game::math::detail
// NOLINTEND(readability-identifier-length)
