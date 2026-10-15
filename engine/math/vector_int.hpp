/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/math/vector_int.hpp
 *  PHÂN HỆ   : Math / Vector Int
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bốn số nguyên 32 bit trên một __m128i: phép toán số nguyên và mặt nạ từng
 *    làn cho Vector4 — Vector4Int cùng namespace vector4int của
 *    ModifiedSonyMath trong _Ref (SimdInt4 của ozz). Mặt nạ: làn "đúng" là toàn
 *    bit 1, làn "sai" là 0. Ánh xạ tên ở docs/modules/math.md. Khác gốc:
 *  - kiểu riêng thay typedef của __m128i: min, max, abs, clamp... nạp chồng
 *    cạnh bản float, và mặt nạ không lẫn với dữ liệu thô;
 *  - not_equal so số nguyên. Gốc (CmpNe) ép sang float rồi so: hai số bằng nhau
 *    mà mẫu bit là NaN thành "khác", còn 0 và INT_MIN (đều là ±0 của float)
 *    thành "bằng";
 *  - nạp và lưu qua Int4 theo giá trị; Load1Ptr của gốc đọc 8 byte từ con trỏ
 *    tới một int, các bản LoadPtr, StorePtr đòi căn lề 16 mà chỉ ghi trong
 *    comment;
 *  - min, max, abs dùng PMINSD, PMAXSD, PABSD của SSE4.1 thay so sánh rồi chọn.
 *  - Nguồn: Forge2 src/math/vector_int.hpp@d7fcd76. Khác gốc (so với Forge2):
 *    lanes() khởi tạo Int4 bằng tên thành viên.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/check.hpp"
#include "math/types.hpp"

#include <cstddef>
#include <cstdint>

#if defined(__aarch64__)
#include "math/sse.hpp"
#else
#include <smmintrin.h>
#endif

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

class Vector4i {
public:
    Vector4i() noexcept = default;
    Vector4i(std::int32_t x, std::int32_t y, std::int32_t z, std::int32_t w) noexcept
        : value_(_mm_setr_epi32(x, y, z, w)) {}
    explicit Vector4i(std::int32_t scalar) noexcept : value_(_mm_set1_epi32(scalar)) {}
    explicit Vector4i(__m128i value) noexcept : value_(value) {}

    [[nodiscard]] __m128i simd() const noexcept { return value_; }

    [[nodiscard]] std::int32_t x() const noexcept { return _mm_cvtsi128_si32(value_); }
    [[nodiscard]] std::int32_t y() const noexcept { return _mm_extract_epi32(value_, 1); }
    [[nodiscard]] std::int32_t z() const noexcept { return _mm_extract_epi32(value_, 2); }
    [[nodiscard]] std::int32_t w() const noexcept { return _mm_extract_epi32(value_, 3); }
    [[nodiscard]] Int4 lanes() const noexcept { return {.x = x(), .y = y(), .z = z(), .w = w()}; }
    [[nodiscard]] std::int32_t operator[](std::size_t i) const noexcept { return lanes()[i]; }

    Vector4i& set_x(std::int32_t x) noexcept { return assign(_mm_insert_epi32(value_, x, 0)); }
    Vector4i& set_y(std::int32_t y) noexcept { return assign(_mm_insert_epi32(value_, y, 1)); }
    Vector4i& set_z(std::int32_t z) noexcept { return assign(_mm_insert_epi32(value_, z, 2)); }
    Vector4i& set_w(std::int32_t w) noexcept { return assign(_mm_insert_epi32(value_, w, 3)); }
    Vector4i& set(std::size_t i, std::int32_t value) noexcept {
        Int4 all = lanes();
        all[i] = value;
        return assign(_mm_setr_epi32(all.x, all.y, all.z, all.w));
    }

    [[nodiscard]] static Vector4i zero() noexcept { return {}; }
    [[nodiscard]] static Vector4i one() noexcept { return Vector4i(1); }
    [[nodiscard]] static Vector4i x_axis() noexcept { return {1, 0, 0, 0}; }
    [[nodiscard]] static Vector4i y_axis() noexcept { return {0, 1, 0, 0}; }
    [[nodiscard]] static Vector4i z_axis() noexcept { return {0, 0, 1, 0}; }
    [[nodiscard]] static Vector4i w_axis() noexcept { return {0, 0, 0, 1}; }

    // Mặt nạ: mọi bit bật (all_true, mask_ffff của gốc); mặt nạ rỗng là zero().
    [[nodiscard]] static Vector4i all_bits() noexcept { return Vector4i(-1); }
    // Chỉ bit dấu ở mỗi làn, và mọi bit trừ bit dấu.
    [[nodiscard]] static Vector4i mask_sign() noexcept { return Vector4i(static_cast<std::int32_t>(0x8000'0000U)); }
    [[nodiscard]] static Vector4i mask_not_sign() noexcept { return Vector4i(0x7FFF'FFFF); }
    // Bật trọn các làn nêu tên (mask_fff0, mask_f000, mask_0f00, mask_00f0, mask_000f).
    [[nodiscard]] static Vector4i mask_xyz() noexcept { return {-1, -1, -1, 0}; }
    [[nodiscard]] static Vector4i mask_x() noexcept { return {-1, 0, 0, 0}; }
    [[nodiscard]] static Vector4i mask_y() noexcept { return {0, -1, 0, 0}; }
    [[nodiscard]] static Vector4i mask_z() noexcept { return {0, 0, -1, 0}; }
    [[nodiscard]] static Vector4i mask_w() noexcept { return {0, 0, 0, -1}; }
    // Mặt nạ từ bool: true thành toàn bit 1.
    [[nodiscard]] static Vector4i mask(bool x, bool y, bool z, bool w) noexcept {
        return {x ? -1 : 0, y ? -1 : 0, z ? -1 : 0, w ? -1 : 0};
    }
    [[nodiscard]] static Vector4i mask(bool all) noexcept { return Vector4i(all ? -1 : 0); }

private:
    Vector4i& assign(__m128i value) noexcept {
        value_ = value;
        return *this;
    }

    __m128i value_ = _mm_setzero_si128();
};

static_assert(sizeof(Vector4i) == 16 && alignof(Vector4i) == 16);

[[nodiscard]] inline Vector4i load(Int4 i) noexcept {
    return {i.x, i.y, i.z, i.w};
}

[[nodiscard]] inline Int4 store(const Vector4i& v) noexcept {
    return v.lanes();
}

[[nodiscard]] inline Vector4i operator+(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_add_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i operator-(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_sub_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i operator&(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_and_si128(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i operator|(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_or_si128(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i operator^(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_xor_si128(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i operator~(const Vector4i& v) noexcept {
    return Vector4i(_mm_xor_si128(v.simd(), _mm_set1_epi32(-1)));
}

// Một bit cho mỗi làn, lấy từ bit dấu: x ở bit 0, w ở bit 3.
[[nodiscard]] inline int move_mask(const Vector4i& v) noexcept {
    return _mm_movemask_ps(_mm_castsi128_ps(v.simd()));
}

// Cả bốn làn bằng nhau.
[[nodiscard]] inline bool operator==(const Vector4i& a, const Vector4i& b) noexcept {
    return move_mask(Vector4i(_mm_cmpeq_epi32(a.simd(), b.simd()))) == 0xF;
}

// Mặt nạ so sánh từng làn (CmpEq..CmpGe).
[[nodiscard]] inline Vector4i equal(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_cmpeq_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i not_equal(const Vector4i& a, const Vector4i& b) noexcept {
    return ~equal(a, b);
}

[[nodiscard]] inline Vector4i less(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_cmplt_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i greater(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_cmpgt_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i less_equal(const Vector4i& a, const Vector4i& b) noexcept {
    return ~greater(a, b);
}

[[nodiscard]] inline Vector4i greater_equal(const Vector4i& a, const Vector4i& b) noexcept {
    return ~less(a, b);
}

// lanes làn đầu (1..4) đều có bit dấu bật (AreAllTrue, AreAllTrue3...), hoặc đều tắt.
[[nodiscard]] inline bool all_true(const Vector4i& mask, int lanes = 4) noexcept {
    core::check(lanes >= 1 && lanes <= 4, "all_true: lanes phải trong 1..4");
    const int wanted = (1 << lanes) - 1;
    return (move_mask(mask) & wanted) == wanted;
}

[[nodiscard]] inline bool all_false(const Vector4i& mask, int lanes = 4) noexcept {
    core::check(lanes >= 1 && lanes <= 4, "all_false: lanes phải trong 1..4");
    return (move_mask(mask) & ((1 << lanes) - 1)) == 0;
}

// Từng bit: b ở bit mặt nạ bật, a ở bit còn lại.
[[nodiscard]] inline Vector4i select_mask(const Vector4i& a, const Vector4i& b, const Vector4i& mask) noexcept {
    const __m128i kept = _mm_andnot_si128(mask.simd(), a.simd());
    return Vector4i(_mm_or_si128(_mm_and_si128(mask.simd(), b.simd()), kept));
}

[[nodiscard]] inline Vector4i splat_x(const Vector4i& v) noexcept {
    return Vector4i(_mm_shuffle_epi32(v.simd(), _MM_SHUFFLE(0, 0, 0, 0)));
}

[[nodiscard]] inline Vector4i splat_y(const Vector4i& v) noexcept {
    return Vector4i(_mm_shuffle_epi32(v.simd(), _MM_SHUFFLE(1, 1, 1, 1)));
}

[[nodiscard]] inline Vector4i splat_z(const Vector4i& v) noexcept {
    return Vector4i(_mm_shuffle_epi32(v.simd(), _MM_SHUFFLE(2, 2, 2, 2)));
}

[[nodiscard]] inline Vector4i splat_w(const Vector4i& v) noexcept {
    return Vector4i(_mm_shuffle_epi32(v.simd(), _MM_SHUFFLE(3, 3, 3, 3)));
}

// Cộng dồn vào làn x: x + y, x + y + z, hoặc cả bốn; ba làn còn lại giữ nguyên (HAdd2, 3, 4).
[[nodiscard]] inline Vector4i hadd_xy(const Vector4i& v) noexcept {
    Vector4i out = v;
    return out.set_x(v.x() + v.y());
}

[[nodiscard]] inline Vector4i hadd_xyz(const Vector4i& v) noexcept {
    const Vector4i total = v + splat_y(v) + splat_z(v);
    Vector4i out = v;
    return out.set_x(total.x());
}

[[nodiscard]] inline Vector4i hadd_xyzw(const Vector4i& v) noexcept {
    const Vector4i total = (v + splat_y(v)) + (splat_z(v) + splat_w(v));
    Vector4i out = v;
    return out.set_x(total.x());
}

// Số nguyên nhỏ nhất giữ nguyên (không có số đối).
[[nodiscard]] inline Vector4i abs(const Vector4i& v) noexcept {
    return Vector4i(_mm_abs_epi32(v.simd()));
}

// Bit dấu của từng làn, các bit khác bằng 0 (Sign).
[[nodiscard]] inline Vector4i sign_bit(const Vector4i& v) noexcept {
    return v & Vector4i::mask_sign();
}

[[nodiscard]] inline Vector4i min(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_min_epi32(a.simd(), b.simd()));
}

[[nodiscard]] inline Vector4i max(const Vector4i& a, const Vector4i& b) noexcept {
    return Vector4i(_mm_max_epi32(a.simd(), b.simd()));
}

// low phải không lớn hơn high.
[[nodiscard]] inline Vector4i clamp(const Vector4i& v, const Vector4i& low, const Vector4i& high) noexcept {
    return max(low, min(v, high));
}

// Dịch bit từng làn; bits từ 32 trở lên cho 0 (dịch phải số học: toàn bit dấu).
[[nodiscard]] inline Vector4i shift_left(const Vector4i& v, int bits) noexcept {
    return Vector4i(_mm_sll_epi32(v.simd(), _mm_cvtsi32_si128(bits)));
}

// Dịch phải số học: kéo bit dấu vào (ShiftR).
[[nodiscard]] inline Vector4i shift_right(const Vector4i& v, int bits) noexcept {
    return Vector4i(_mm_sra_epi32(v.simd(), _mm_cvtsi32_si128(bits)));
}

// Dịch phải logic: kéo 0 vào (ShiftRu).
[[nodiscard]] inline Vector4i shift_right_logical(const Vector4i& v, int bits) noexcept {
    return Vector4i(_mm_srl_epi32(v.simd(), _mm_cvtsi32_si128(bits)));
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
