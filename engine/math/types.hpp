// Kiểu lưu trữ cỡ cố định cho dữ liệu chung với GPU (constant buffer, đỉnh, structured buffer):
// Float2/3/4, Int2/3/4, Uint2/3/4 và Half — float2..uint4 và half của common.hpp trong _Ref. Không
// SIMD, không căn lề 16; tính toán nặng dùng Vector3/Vector4 (math/vector.hpp). Khác gốc:
// - aggregate: Float3{1, 2, 3} hay {.x = 1}; mọi kiểu mặc định 0 (int2..uint4 của gốc để rác);
// - s / v chia đúng nghĩa (gốc trả v / s cho cả float, int, uint);
// - == so chính xác; gốc so float với ε tuyệt đối FLT_EPSILON — không bắc cầu, vô nghĩa với số
//   lớn. So gần đúng dùng near();
// - so thứ tự "mọi thành phần" là all_less..., không phải operator<: nó không phải thứ tự yếu
//   nghiêm ngặt nên làm khoá của std::sort hay std::map là sai âm thầm;
// - operator[] đi qua con trỏ tới member, không cộng con trỏ vượt qua một member (UB ở gốc);
// - Half làm tròn về số chẵn gần nhất và đúng với mọi float; gốc cộng 0x1000 rồi cắt (tròn nửa
//   lên) và dịch bit quá 31 (UB) khi số mũ dưới -31.
// Nguồn: Forge2 src/math/types.hpp@d7fcd76. Khác gốc (so với Forge2): không.
#pragma once

#include <array>
#include <bit>
#include <cmath>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <type_traits>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

template <class T>
concept Component = std::same_as<T, float> || std::same_as<T, double> || std::same_as<T, std::int32_t> ||
    std::same_as<T, std::uint32_t>;

template <class T>
concept SignedComponent = Component<T> && !std::unsigned_integral<T>;

template <class T>
concept Real = Component<T> && std::floating_point<T>;

namespace detail {

// x < y ? x : y và x > y ? x : y như min, max của gốc: có NaN thì trả đối số thứ hai.
template <Component T>
[[nodiscard]] constexpr T lesser(T x, T y) noexcept {
    return x < y ? x : y;
}

template <Component T>
[[nodiscard]] constexpr T greater(T x, T y) noexcept {
    return x > y ? x : y;
}

// Bit dấu của số thực (kể cả -0 và NaN âm) hoặc của số nguyên.
[[nodiscard]] constexpr bool is_negative(float x) noexcept {
    return (std::bit_cast<std::uint32_t>(x) >> 31U) != 0;
}

[[nodiscard]] constexpr bool is_negative(double x) noexcept {
    return (std::bit_cast<std::uint64_t>(x) >> 63U) != 0;
}

[[nodiscard]] constexpr bool is_negative(std::int32_t x) noexcept {
    return x < 0;
}

[[nodiscard]] constexpr float negated(float x) noexcept {
    return -x;
}

[[nodiscard]] constexpr double negated(double x) noexcept {
    return -x;
}

// 0 - x tính theo số không dấu: số nguyên nhỏ nhất quay về chính nó thay vì tràn (UB).
[[nodiscard]] constexpr std::int32_t negated(std::int32_t x) noexcept {
    return static_cast<std::int32_t>(0U - static_cast<std::uint32_t>(x));
}

template <SignedComponent T>
[[nodiscard]] constexpr T magnitude(T x) noexcept {
    return is_negative(x) ? negated(x) : x;
}

template <SignedComponent T>
[[nodiscard]] constexpr T with_sign(T value, T sign) noexcept {
    return is_negative(value) == is_negative(sign) ? value : negated(value);
}

} // namespace detail

template <Component T>
struct Plain2 {
    T x{};
    T y{};

    [[nodiscard]] static constexpr Plain2 splat(T value) noexcept { return {value, value}; }

    [[nodiscard]] constexpr T& operator[](std::size_t i) noexcept { return this->*member(i); }
    [[nodiscard]] constexpr T operator[](std::size_t i) const noexcept { return this->*member(i); }

    friend constexpr bool operator==(const Plain2&, const Plain2&) = default;

    friend constexpr Plain2 operator+(Plain2 a, Plain2 b) noexcept { return {a.x + b.x, a.y + b.y}; }
    friend constexpr Plain2 operator-(Plain2 a, Plain2 b) noexcept { return {a.x - b.x, a.y - b.y}; }
    friend constexpr Plain2 operator*(Plain2 a, Plain2 b) noexcept { return {a.x * b.x, a.y * b.y}; }
    friend constexpr Plain2 operator/(Plain2 a, Plain2 b) noexcept { return {a.x / b.x, a.y / b.y}; }
    friend constexpr Plain2 operator*(Plain2 a, T s) noexcept { return {a.x * s, a.y * s}; }
    friend constexpr Plain2 operator*(T s, Plain2 a) noexcept { return a * s; }
    friend constexpr Plain2 operator/(Plain2 a, T s) noexcept { return {a.x / s, a.y / s}; }
    friend constexpr Plain2 operator/(T s, Plain2 a) noexcept { return {s / a.x, s / a.y}; }

    constexpr Plain2& operator+=(Plain2 b) noexcept { return *this = *this + b; }
    constexpr Plain2& operator-=(Plain2 b) noexcept { return *this = *this - b; }
    constexpr Plain2& operator*=(Plain2 b) noexcept { return *this = *this * b; }
    constexpr Plain2& operator/=(Plain2 b) noexcept { return *this = *this / b; }
    constexpr Plain2& operator*=(T s) noexcept { return *this = *this * s; }
    constexpr Plain2& operator/=(T s) noexcept { return *this = *this / s; }

private:
    [[nodiscard]] static constexpr T Plain2::* member(std::size_t i) noexcept {
        constexpr std::array<T Plain2::*, 2> kMembers{&Plain2::x, &Plain2::y};
        return kMembers.at(i);
    }
};

template <Component T>
struct Plain3 {
    T x{};
    T y{};
    T z{};

    [[nodiscard]] static constexpr Plain3 splat(T value) noexcept { return {value, value, value}; }

    [[nodiscard]] constexpr Plain2<T> xy() const noexcept { return {x, y}; }

    [[nodiscard]] constexpr T& operator[](std::size_t i) noexcept { return this->*member(i); }
    [[nodiscard]] constexpr T operator[](std::size_t i) const noexcept { return this->*member(i); }

    friend constexpr bool operator==(const Plain3&, const Plain3&) = default;

    friend constexpr Plain3 operator+(Plain3 a, Plain3 b) noexcept { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
    friend constexpr Plain3 operator-(Plain3 a, Plain3 b) noexcept { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
    friend constexpr Plain3 operator*(Plain3 a, Plain3 b) noexcept { return {a.x * b.x, a.y * b.y, a.z * b.z}; }
    friend constexpr Plain3 operator/(Plain3 a, Plain3 b) noexcept { return {a.x / b.x, a.y / b.y, a.z / b.z}; }
    friend constexpr Plain3 operator*(Plain3 a, T s) noexcept { return {a.x * s, a.y * s, a.z * s}; }
    friend constexpr Plain3 operator*(T s, Plain3 a) noexcept { return a * s; }
    friend constexpr Plain3 operator/(Plain3 a, T s) noexcept { return {a.x / s, a.y / s, a.z / s}; }
    friend constexpr Plain3 operator/(T s, Plain3 a) noexcept { return {s / a.x, s / a.y, s / a.z}; }

    constexpr Plain3& operator+=(Plain3 b) noexcept { return *this = *this + b; }
    constexpr Plain3& operator-=(Plain3 b) noexcept { return *this = *this - b; }
    constexpr Plain3& operator*=(Plain3 b) noexcept { return *this = *this * b; }
    constexpr Plain3& operator/=(Plain3 b) noexcept { return *this = *this / b; }
    constexpr Plain3& operator*=(T s) noexcept { return *this = *this * s; }
    constexpr Plain3& operator/=(T s) noexcept { return *this = *this / s; }

private:
    [[nodiscard]] static constexpr T Plain3::* member(std::size_t i) noexcept {
        constexpr std::array<T Plain3::*, 3> kMembers{&Plain3::x, &Plain3::y, &Plain3::z};
        return kMembers.at(i);
    }
};

template <Component T>
struct Plain4 {
    T x{};
    T y{};
    T z{};
    T w{};

    [[nodiscard]] static constexpr Plain4 splat(T value) noexcept { return {value, value, value, value}; }
    [[nodiscard]] static constexpr Plain4 from(Plain3<T> xyz, T w) noexcept { return {xyz.x, xyz.y, xyz.z, w}; }

    [[nodiscard]] constexpr Plain2<T> xy() const noexcept { return {x, y}; }
    [[nodiscard]] constexpr Plain3<T> xyz() const noexcept { return {x, y, z}; }

    [[nodiscard]] constexpr T& operator[](std::size_t i) noexcept { return this->*member(i); }
    [[nodiscard]] constexpr T operator[](std::size_t i) const noexcept { return this->*member(i); }

    friend constexpr bool operator==(const Plain4&, const Plain4&) = default;

    friend constexpr Plain4 operator+(Plain4 a, Plain4 b) noexcept {
        return {a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w};
    }
    friend constexpr Plain4 operator-(Plain4 a, Plain4 b) noexcept {
        return {a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w};
    }
    friend constexpr Plain4 operator*(Plain4 a, Plain4 b) noexcept {
        return {a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w};
    }
    friend constexpr Plain4 operator/(Plain4 a, Plain4 b) noexcept {
        return {a.x / b.x, a.y / b.y, a.z / b.z, a.w / b.w};
    }
    friend constexpr Plain4 operator*(Plain4 a, T s) noexcept { return {a.x * s, a.y * s, a.z * s, a.w * s}; }
    friend constexpr Plain4 operator*(T s, Plain4 a) noexcept { return a * s; }
    friend constexpr Plain4 operator/(Plain4 a, T s) noexcept { return {a.x / s, a.y / s, a.z / s, a.w / s}; }
    friend constexpr Plain4 operator/(T s, Plain4 a) noexcept { return {s / a.x, s / a.y, s / a.z, s / a.w}; }

    constexpr Plain4& operator+=(Plain4 b) noexcept { return *this = *this + b; }
    constexpr Plain4& operator-=(Plain4 b) noexcept { return *this = *this - b; }
    constexpr Plain4& operator*=(Plain4 b) noexcept { return *this = *this * b; }
    constexpr Plain4& operator/=(Plain4 b) noexcept { return *this = *this / b; }
    constexpr Plain4& operator*=(T s) noexcept { return *this = *this * s; }
    constexpr Plain4& operator/=(T s) noexcept { return *this = *this / s; }

private:
    [[nodiscard]] static constexpr T Plain4::* member(std::size_t i) noexcept {
        constexpr std::array<T Plain4::*, 4> kMembers{&Plain4::x, &Plain4::y, &Plain4::z, &Plain4::w};
        return kMembers.at(i);
    }
};

using Float2 = Plain2<float>;
using Float3 = Plain3<float>;
using Float4 = Plain4<float>;
using Int2 = Plain2<std::int32_t>;
using Int3 = Plain3<std::int32_t>;
using Int4 = Plain4<std::int32_t>;
using Uint2 = Plain2<std::uint32_t>;
using Uint3 = Plain3<std::uint32_t>;
using Uint4 = Plain4<std::uint32_t>;
// Số thực kép, cho toán học cần độ chính xác cao (math/double.hpp); GPU không nhận kiểu này.
using Double2 = Plain2<double>;
using Double3 = Plain3<double>;
using Double4 = Plain4<double>;

// Đổi dấu chỉ có ở kiểu có dấu.
template <SignedComponent T>
[[nodiscard]] constexpr Plain2<T> operator-(Plain2<T> a) noexcept {
    return {-a.x, -a.y};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain3<T> operator-(Plain3<T> a) noexcept {
    return {-a.x, -a.y, -a.z};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain4<T> operator-(Plain4<T> a) noexcept {
    return {-a.x, -a.y, -a.z, -a.w};
}

static_assert(sizeof(Float2) == 8 && sizeof(Float3) == 12 && sizeof(Float4) == 16);
static_assert(sizeof(Int3) == 12 && sizeof(Uint4) == 16);

// Nhỏ nhất, lớn nhất từng thành phần.
template <Component T>
[[nodiscard]] constexpr Plain2<T> min(Plain2<T> a, Plain2<T> b) noexcept {
    return {detail::lesser(a.x, b.x), detail::lesser(a.y, b.y)};
}

template <Component T>
[[nodiscard]] constexpr Plain3<T> min(Plain3<T> a, Plain3<T> b) noexcept {
    return {detail::lesser(a.x, b.x), detail::lesser(a.y, b.y), detail::lesser(a.z, b.z)};
}

template <Component T>
[[nodiscard]] constexpr Plain4<T> min(Plain4<T> a, Plain4<T> b) noexcept {
    return {detail::lesser(a.x, b.x), detail::lesser(a.y, b.y), detail::lesser(a.z, b.z), detail::lesser(a.w, b.w)};
}

template <Component T>
[[nodiscard]] constexpr Plain2<T> max(Plain2<T> a, Plain2<T> b) noexcept {
    return {detail::greater(a.x, b.x), detail::greater(a.y, b.y)};
}

template <Component T>
[[nodiscard]] constexpr Plain3<T> max(Plain3<T> a, Plain3<T> b) noexcept {
    return {detail::greater(a.x, b.x), detail::greater(a.y, b.y), detail::greater(a.z, b.z)};
}

template <Component T>
[[nodiscard]] constexpr Plain4<T> max(Plain4<T> a, Plain4<T> b) noexcept {
    return {detail::greater(a.x, b.x), detail::greater(a.y, b.y), detail::greater(a.z, b.z), detail::greater(a.w, b.w)};
}

// Đúng khi MỌI thành phần của a nhỏ hơn thành phần tương ứng của b (operator< của int2..uint4
// trong gốc). all_less(a, b) sai không kéo theo all_less(b, a) hay bằng nhau.
template <Component T>
[[nodiscard]] constexpr bool all_less(Plain2<T> a, Plain2<T> b) noexcept {
    return a.x < b.x && a.y < b.y;
}

template <Component T>
[[nodiscard]] constexpr bool all_less(Plain3<T> a, Plain3<T> b) noexcept {
    return a.x < b.x && a.y < b.y && a.z < b.z;
}

template <Component T>
[[nodiscard]] constexpr bool all_less(Plain4<T> a, Plain4<T> b) noexcept {
    return a.x < b.x && a.y < b.y && a.z < b.z && a.w < b.w;
}

template <Component T>
[[nodiscard]] constexpr bool all_less_equal(Plain2<T> a, Plain2<T> b) noexcept {
    return a.x <= b.x && a.y <= b.y;
}

template <Component T>
[[nodiscard]] constexpr bool all_less_equal(Plain3<T> a, Plain3<T> b) noexcept {
    return a.x <= b.x && a.y <= b.y && a.z <= b.z;
}

template <Component T>
[[nodiscard]] constexpr bool all_less_equal(Plain4<T> a, Plain4<T> b) noexcept {
    return a.x <= b.x && a.y <= b.y && a.z <= b.z && a.w <= b.w;
}

template <Real T>
[[nodiscard]] constexpr T dot(Plain2<T> a, Plain2<T> b) noexcept {
    return (a.x * b.x) + (a.y * b.y);
}

template <Real T>
[[nodiscard]] constexpr T dot(Plain3<T> a, Plain3<T> b) noexcept {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
}

template <Real T>
[[nodiscard]] constexpr T dot(Plain4<T> a, Plain4<T> b) noexcept {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w);
}

template <Real T>
[[nodiscard]] constexpr T length_sq(Plain2<T> v) noexcept {
    return dot(v, v);
}

template <Real T>
[[nodiscard]] constexpr T length_sq(Plain3<T> v) noexcept {
    return dot(v, v);
}

template <Real T>
[[nodiscard]] constexpr T length_sq(Plain4<T> v) noexcept {
    return dot(v, v);
}

template <Real T>
[[nodiscard]] inline T length(Plain2<T> v) noexcept {
    return std::sqrt(length_sq(v));
}

template <Real T>
[[nodiscard]] inline T length(Plain3<T> v) noexcept {
    return std::sqrt(length_sq(v));
}

template <Real T>
[[nodiscard]] inline T length(Plain4<T> v) noexcept {
    return std::sqrt(length_sq(v));
}

// Vectơ độ dài 0 cho thành phần vô cùng hoặc NaN, như gốc.
template <Real T>
[[nodiscard]] inline Plain2<T> normalize(Plain2<T> v) noexcept {
    return v * (T{1} / length(v));
}

template <Real T>
[[nodiscard]] inline Plain3<T> normalize(Plain3<T> v) noexcept {
    return v * (T{1} / length(v));
}

template <Real T>
[[nodiscard]] inline Plain4<T> normalize(Plain4<T> v) noexcept {
    return v * (T{1} / length(v));
}

// Mọi thành phần lệch nhau không quá tolerance (tuyệt đối).
template <Real T>
[[nodiscard]] inline bool near(Plain2<T> a, Plain2<T> b, std::type_identity_t<T> tolerance) noexcept {
    return std::abs(a.x - b.x) <= tolerance && std::abs(a.y - b.y) <= tolerance;
}

template <Real T>
[[nodiscard]] inline bool near(Plain3<T> a, Plain3<T> b, std::type_identity_t<T> tolerance) noexcept {
    return near(a.xy(), b.xy(), tolerance) && std::abs(a.z - b.z) <= tolerance;
}

template <Real T>
[[nodiscard]] inline bool near(Plain4<T> a, Plain4<T> b, std::type_identity_t<T> tolerance) noexcept {
    return near(a.xyz(), b.xyz(), tolerance) && std::abs(a.w - b.w) <= tolerance;
}

// Thành phần lớn nhất, nhỏ nhất, và tổng các thành phần (maxElem, minElem, sum).
template <Component T>
[[nodiscard]] constexpr T max_elem(Plain2<T> v) noexcept {
    return detail::greater(v.x, v.y);
}

template <Component T>
[[nodiscard]] constexpr T max_elem(Plain3<T> v) noexcept {
    return detail::greater(detail::greater(v.x, v.y), v.z);
}

template <Component T>
[[nodiscard]] constexpr T max_elem(Plain4<T> v) noexcept {
    return detail::greater(detail::greater(v.x, v.y), detail::greater(v.z, v.w));
}

template <Component T>
[[nodiscard]] constexpr T min_elem(Plain2<T> v) noexcept {
    return detail::lesser(v.x, v.y);
}

template <Component T>
[[nodiscard]] constexpr T min_elem(Plain3<T> v) noexcept {
    return detail::lesser(detail::lesser(v.x, v.y), v.z);
}

template <Component T>
[[nodiscard]] constexpr T min_elem(Plain4<T> v) noexcept {
    return detail::lesser(detail::lesser(v.x, v.y), detail::lesser(v.z, v.w));
}

template <Component T>
[[nodiscard]] constexpr T sum(Plain2<T> v) noexcept {
    return v.x + v.y;
}

template <Component T>
[[nodiscard]] constexpr T sum(Plain3<T> v) noexcept {
    return v.x + v.y + v.z;
}

// (x + y) + (z + w), như bản SIMD.
template <Component T>
[[nodiscard]] constexpr T sum(Plain4<T> v) noexcept {
    return (v.x + v.y) + (v.z + v.w);
}

// Trị tuyệt đối và chép dấu từng thành phần (absPerElem, copySignPerElem). Số nguyên nhỏ nhất
// không có số đối nên giữ nguyên, như PABSD — std::abs với nó là UB.
template <SignedComponent T>
[[nodiscard]] constexpr Plain2<T> abs(Plain2<T> v) noexcept {
    return {detail::magnitude(v.x), detail::magnitude(v.y)};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain3<T> abs(Plain3<T> v) noexcept {
    return {detail::magnitude(v.x), detail::magnitude(v.y), detail::magnitude(v.z)};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain4<T> abs(Plain4<T> v) noexcept {
    return {detail::magnitude(v.x), detail::magnitude(v.y), detail::magnitude(v.z), detail::magnitude(v.w)};
}

// Độ lớn của value, dấu của sign.
template <SignedComponent T>
[[nodiscard]] constexpr Plain2<T> copysign(Plain2<T> value, Plain2<T> sign) noexcept {
    return {detail::with_sign(value.x, sign.x), detail::with_sign(value.y, sign.y)};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain3<T> copysign(Plain3<T> value, Plain3<T> sign) noexcept {
    return {detail::with_sign(value.x, sign.x), detail::with_sign(value.y, sign.y), detail::with_sign(value.z, sign.z)};
}

template <SignedComponent T>
[[nodiscard]] constexpr Plain4<T> copysign(Plain4<T> value, Plain4<T> sign) noexcept {
    return {detail::with_sign(value.x, sign.x), detail::with_sign(value.y, sign.y), detail::with_sign(value.z, sign.z),
        detail::with_sign(value.w, sign.w)};
}

// Số thực 16 bit IEEE 754 (binary16), chỉ để lưu và truyền cho GPU.
struct Half {
    std::uint16_t bits = 0;

    friend constexpr bool operator==(Half, Half) = default;
};

namespace detail {

// Bỏ shift bit thấp của value, làm tròn về số chẵn gần nhất. shift trong 1..31.
[[nodiscard]] constexpr std::uint32_t shift_round_even(std::uint32_t value, std::uint32_t shift) noexcept {
    const std::uint32_t kept = value >> shift;
    const std::uint32_t rest = value & ((1U << shift) - 1U);
    const std::uint32_t midpoint = 1U << (shift - 1U);
    const bool up = rest > midpoint || (rest == midpoint && (kept & 1U) != 0);
    return up ? kept + 1U : kept;
}

} // namespace detail

// Làm tròn về số chẵn gần nhất; quá 65520 thành vô cùng, dưới 2^-25 thành 0 có dấu, NaN giữ bit
// cao của phần định trị. Số làm tròn tràn sang số mũ kế là đúng theo cách xếp bit của IEEE.
[[nodiscard]] constexpr Half to_half(float value) noexcept {
    constexpr std::uint32_t kInfinity = 0x7C00U;
    const auto bits = std::bit_cast<std::uint32_t>(value);
    const std::uint32_t sign = (bits >> 16U) & 0x8000U;
    const std::uint32_t magnitude = bits & 0x7FFF'FFFFU;
    const std::uint32_t mantissa = magnitude & 0x007F'FFFFU;
    const std::uint32_t exponent = magnitude >> 23U;
    std::uint32_t half = 0;
    if (exponent == 255) {
        half = kInfinity | (mantissa == 0 ? 0U : 0x0200U | (mantissa >> 13U));
    } else if (exponent >= 143) {
        half = kInfinity;
    } else if (exponent >= 113) {
        half = detail::shift_round_even(((exponent - 112U) << 23U) | mantissa, 13);
    } else if (exponent >= 102) {
        half = detail::shift_round_even(mantissa | 0x0080'0000U, 126U - exponent);
    }
    return Half{static_cast<std::uint16_t>(sign | half)};
}

[[nodiscard]] constexpr float to_float(Half half) noexcept {
    const std::uint32_t sign = (half.bits & 0x8000U) << 16U;
    const std::uint32_t exponent = (half.bits >> 10U) & 0x1FU;
    const std::uint32_t mantissa = half.bits & 0x03FFU;
    const std::uint32_t payload = sign | (mantissa << 13U);
    if (exponent == 31) return std::bit_cast<float>(payload | 0x7F80'0000U);
    if (exponent != 0) return std::bit_cast<float>(payload | ((exponent + 112U) << 23U));
    if (mantissa == 0) return std::bit_cast<float>(sign);
    // Số không chuẩn: đưa bit cao nhất của phần định trị về vị trí bit ẩn.
    const auto shift = static_cast<std::uint32_t>(std::countl_zero(mantissa)) - 21U;
    const std::uint32_t fraction = (mantissa << shift) & 0x03FFU;
    return std::bit_cast<float>(sign | ((113U - shift) << 23U) | (fraction << 13U));
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
