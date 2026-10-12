// Tên chữ của enum Format, và chiều ngược từ chuỗi về giá trị.
// kNames cùng thứ tự enum; chỉ số lạ trả "unknown", tên lạ trả nullopt.
// Nguồn: Forge2 src/gpu/format.cpp@d7fcd76. Khác gốc: không.
#include "gpu/format.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <string_view>
#include <utility>

namespace game::gpu {

namespace {

// Cùng thứ tự với enum Format.
constexpr std::array<std::string_view, kFormatCount> kNames{
    "unknown",
    "r8_unorm",
    "r8_snorm",
    "r8_uint",
    "r8_sint",
    "rg8_unorm",
    "rg8_snorm",
    "rg8_uint",
    "rg8_sint",
    "rgba8_unorm",
    "rgba8_unorm_srgb",
    "rgba8_snorm",
    "rgba8_uint",
    "rgba8_sint",
    "bgra8_unorm",
    "bgra8_unorm_srgb",
    "r16_unorm",
    "r16_snorm",
    "r16_uint",
    "r16_sint",
    "r16_float",
    "rg16_unorm",
    "rg16_snorm",
    "rg16_uint",
    "rg16_sint",
    "rg16_float",
    "rgba16_unorm",
    "rgba16_snorm",
    "rgba16_uint",
    "rgba16_sint",
    "rgba16_float",
    "r32_uint",
    "r32_sint",
    "r32_float",
    "rg32_uint",
    "rg32_sint",
    "rg32_float",
    "rgb32_uint",
    "rgb32_sint",
    "rgb32_float",
    "rgba32_uint",
    "rgba32_sint",
    "rgba32_float",
    "rgb10a2_unorm",
    "rgb10a2_uint",
    "rg11b10_float",
    "rgb9e5_float",
    "d16_unorm",
    "d24_unorm_s8_uint",
    "d32_float",
    "d32_float_s8_uint",
    "bc1_unorm",
    "bc1_unorm_srgb",
    "bc2_unorm",
    "bc2_unorm_srgb",
    "bc3_unorm",
    "bc3_unorm_srgb",
    "bc4_unorm",
    "bc4_snorm",
    "bc5_unorm",
    "bc5_snorm",
    "bc6h_ufloat",
    "bc6h_sfloat",
    "bc7_unorm",
    "bc7_unorm_srgb",
    "etc2_rgb8_unorm",
    "etc2_rgb8_unorm_srgb",
    "etc2_rgb8a1_unorm",
    "etc2_rgb8a1_unorm_srgb",
    "etc2_rgba8_unorm",
    "etc2_rgba8_unorm_srgb",
    "eac_r11_unorm",
    "eac_r11_snorm",
    "eac_rg11_unorm",
    "eac_rg11_snorm",
    "astc_4x4_unorm",
    "astc_4x4_unorm_srgb",
    "astc_5x5_unorm",
    "astc_5x5_unorm_srgb",
    "astc_6x6_unorm",
    "astc_6x6_unorm_srgb",
    "astc_8x8_unorm",
    "astc_8x8_unorm_srgb",
    "astc_10x10_unorm",
    "astc_10x10_unorm_srgb",
    "astc_12x12_unorm",
    "astc_12x12_unorm_srgb",
};

} // namespace

std::string_view name(Format format) noexcept {
    const std::size_t index = std::to_underlying(format);
    return index < kNames.size() ? kNames.at(index) : std::string_view("unknown");
}

std::optional<Format> parse_format(std::string_view text) noexcept {
    const auto found = std::ranges::find(kNames, text);
    if (found == kNames.end()) return std::nullopt;
    return static_cast<Format>(found - kNames.begin());
}

} // namespace game::gpu
