// Đọc Scene/<cảnh>.hfog. 64 byte, little-endian, đúng thứ tự FUN_1801c0c90.
#pragma once

#include "client/stage/stage.hpp"

#include <cstddef>
#include <cstring>
#include <optional>
#include <span>

namespace game::client {

inline constexpr std::size_t kHeightFogBytes = 64;

[[nodiscard]] inline std::optional<HeightFog> read_height_fog(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() != kHeightFogBytes) return std::nullopt;
    float value[16] = {};
    std::memcpy(value, bytes.data(), kHeightFogBytes);
    HeightFog fog;
    fog.color_r = value[0];
    fog.color_g = value[1];
    fog.color_b = value[2];
    fog.color_a = value[3];
    fog.density = value[4];
    fog.height = value[5];
    fog.height_falloff = value[6];
    fog.pow_factor = value[7];
    fog.depth_density = value[8];
    fog.depth_falloff = value[9];
    fog.depth_start = value[10];
    fog.inscatter = value[11];
    fog.scatter_r = value[12];
    fog.scatter_g = value[13];
    fog.scatter_b = value[14];
    fog.scatter_a = value[15];
    return fog;
}

} // namespace game::client
