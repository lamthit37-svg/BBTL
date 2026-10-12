// Ảnh bản đồ nhìn từ trên, một điểm ảnh mỗi ô, và khung MiniMap_MapArea của bản desktop.
// Layout: Interface/MiniMap/MiniMap.layout.xml. Frame bám mép phải (1, -251) cỡ 251x224;
// Background_Frame lệch (32, 0); Background_Map lệch (44, 27) trong khung 219; MapArea lệch
// (18.5, 15) cỡ 119x121. Cộng lại: cách mép phải 156.5, cách mép trên 42.
// Hàng 0 của ảnh là z lớn nhất, để +Z của địa hình nằm phía trên ảnh khi vẽ UI.
#pragma once

#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <cstdint>
#include <vector>

namespace game::client::map {

struct Rgb {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;
};

struct Picture {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // width * height * 4, RGBA8, hàng trên cùng trước.
    std::vector<std::uint8_t> rgba;
};

// Hình chữ nhật điểm ảnh (hoặc point của UIKit), gốc trên-trái.
struct Frame {
    float x = 0.0F;
    float y = 0.0F;
    float width = 0.0F;
    float height = 0.0F;
};

// Màu theo độ cao trong [low, high]. Bằng nhau thì lấy màu thấp.
[[nodiscard]] Rgb shade_of(float height, float low, float high) noexcept;

// Ảnh x_size * z_size. Ô có pixmap lớp nền bằng 0 là lỗ, alpha 0.
[[nodiscard]] Picture paint_overview(const TerrainFile& file, const HeightField& heights, const GridField& grid);

// Vùng vẽ map của minimap khi gốc UI rộng root_width. Không kẹp vào màn hình.
[[nodiscard]] Frame minimap_area(float root_width) noexcept;

} // namespace game::client::map
