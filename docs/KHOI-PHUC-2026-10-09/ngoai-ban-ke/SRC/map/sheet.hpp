// Lưới tam giác của địa hình trong thế giới OGRE (Y lên, đơn vị centimet). Mỗi điểm là một góc ô.
// Chỉ số mặt trước là ngược chiều kim đồng hồ nhìn từ +Y, đúng FrontFace::kCounterClockwise của
// pipeline. Bản gốc (TerrainTileEditable) ghi chiều kia vì D3D cũ của client cull ngược lại; ở
// đây hai đỉnh được xếp lại cho pháp tuyến hướng lên. Ô pixmap nền bằng 0 là lỗ, không sinh mặt.
// Đường chéo theo cờ kFlipDiagonal.
#pragma once

#include "map/picture.hpp"

#include <cstdint>
#include <vector>

namespace game::map {

struct Corner {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float normal_x = 0.0F;
    float normal_y = 1.0F;
    float normal_z = 0.0F;
    float red = 1.0F;
    float green = 1.0F;
    float blue = 1.0F;
};

struct Sheet {
    // (x_size + 1) * (z_size + 1) góc, chỉ số z * (x_size + 1) + x.
    std::vector<Corner> corners;
    std::vector<std::uint32_t> indices;
};

// Lưới thế giới. Cao độ thế giới = origin.y + scale.y * độ cao trong tệp.
[[nodiscard]] Sheet build_sheet(
    const TerrainFile& file, const HeightField& heights, const GridField& grid);

} // namespace game::map
