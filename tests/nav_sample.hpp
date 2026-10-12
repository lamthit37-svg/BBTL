// Tệp .path nhỏ nhất dựng tay, dùng chung cho test của nav (bộ đọc, truy vấn tính nhẩm được) và của
// client/world (cảnh có tệp lưới đi). Hình vuông cạnh 4 cắt theo đường chéo: nửa dưới phải (tam giác
// 0) đi được, nửa trên trái (tam giác 1) là vật cản, đường chéo là cạnh ràng buộc, lưới tra một ô.
// Bố cục byte theo SRC/nav/mesh.cpp.
#pragma once

#include "nav/mesh.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <utility>
#include <vector>

namespace game::test {

using Bytes = std::vector<std::byte>;

// Số byte của một trường trong tệp.
enum class Width : std::uint8_t { kOne = 1, kTwo = 2, kFour = 4 };

// Mẫu bit của 4.0F.
inline constexpr std::uint32_t kFourBits = 0x40800000U;

// Ghi các byte thấp của value, byte thấp trước.
inline void put(Bytes& out, std::uint32_t value, Width width) {
    for (std::size_t index = 0; index < std::to_underlying(width); ++index) {
        out.push_back(static_cast<std::byte>((value >> (index * 8U)) & 0xFFU));
    }
}

inline void put_all(Bytes& out, std::initializer_list<std::uint32_t> values, Width width) {
    for (const std::uint32_t value : values) {
        put(out, value, width);
    }
}

// Mỗi trường là một chỗ để ca test bẻ; mặc định là tệp hợp lệ bản 0x2000.
struct Sample {
    bool is_wide = true;
    std::uint32_t version = 0x2000;
    std::uint32_t vertex_count = 4;
    float first_x = 0.0F;
    float second_x = 4.0F;
    std::uint32_t first_corner = 0;
    std::uint32_t edge_end = 2;
    std::uint32_t cell_size = 8;
    std::uint32_t columns = 1;
    std::uint32_t listed_triangle = 1;
    std::uint32_t listed_edge = 0;
};

[[nodiscard]] inline Bytes encode(const Sample& sample) {
    const Width wide = sample.is_wide ? Width::kFour : Width::kTwo;
    const std::uint32_t none = sample.is_wide ? nav::kNone : 0xFFFFU;
    const auto first_x = std::bit_cast<std::uint32_t>(sample.first_x);
    const auto second_x = std::bit_cast<std::uint32_t>(sample.second_x);
    Bytes out;
    put(out, sample.version, Width::kTwo);
    put(out, sample.vertex_count, wide);
    put_all(out, {first_x, 0U, second_x, 0U, kFourBits, kFourBits, 0U, kFourBits}, Width::kFour);
    put(out, 2, wide);
    put_all(out, {sample.first_corner, 1U, 2U, none, 1U, none}, wide);
    put(out, 0, Width::kOne);
    put(out, 1, wide);
    put_all(out, {0U, 2U, 3U, none, none, 0U}, wide);
    put(out, 1, Width::kOne);
    put(out, 0, wide);
    put(out, 1, wide);
    put_all(out, {0U, sample.edge_end, 1U, 0U}, wide);
    put(out, sample.cell_size, Width::kFour);
    put_all(out, {sample.columns, 1U, 2U, 1U, 0U, sample.listed_triangle, sample.listed_edge}, wide);
    return out;
}

// Cùng lưới ở bản 0x1000 (số đếm và chỉ số 16 bit).
[[nodiscard]] inline Sample narrow_sample() {
    Sample sample;
    sample.is_wide = false;
    sample.version = 0x1000;
    return sample;
}

} // namespace game::test
