// Mặt TerrainLiquid: lũ điền các đỉnh địa hình thấp hơn mực nước, đúng thứ tự thăm của
// WXTerrainLiquid::build. Tam giác thêm ngay lúc thăm đỉnh, khi hai đỉnh kia đã thăm.
// Camera của client 2026 không dò nước (_IsValidEye chỉ thử hộp ô địa hình), nên ở đây không
// có lưới mực nước hay tia dò nước.
#pragma once

#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::client::map {

// Vị trí và tỉ lệ UV trong tệp cảnh. Gốc không ghi bán kính: mặt nước lan theo độ cao.
struct LiquidPlace {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float texture_scale = 1.0F;
    float texture_rotate = 0.0F;
};

struct LiquidPoint {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
};

struct LiquidSheet {
    std::vector<LiquidPoint> points;
    std::vector<std::uint32_t> indices;
};

// Địa hình và chỗ đặt mặt nước. Mặt rỗng khi không có đỉnh nào dưới mực.
struct LiquidField {
    const TerrainFile* terrain = nullptr;
    const HeightField* heights = nullptr;
    const GridField* grid = nullptr;
    LiquidPlace place{};
};

// Mặt nằm ngang ở place.y. Trần 32768 đỉnh, đúng TERRAIN_LIQUID_VERTEX_LIMIT.
[[nodiscard]] LiquidSheet build_liquid(const LiquidField& field);

// Một chất liệu nước trong script OGRE (.material). texture là tên tệp, kể cả đuôi.
struct LiquidLook {
    std::string texture;
    int frames = 1;
    float duration = 1.0F;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    float speed_u = 0.0F;
    float speed_v = 0.0F;
    bool blends = false;
};

using LiquidLookResult = std::optional<LiquidLook>;

// Không có khi script không khai đúng tên. 岩浆11 không khớp 岩浆1.
[[nodiscard]] LiquidLookResult find_liquid_look(std::string_view script, std::string_view name);

} // namespace game::client::map
