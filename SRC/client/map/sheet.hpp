// Lưới tam giác của địa hình trong thế giới OGRE (Y lên, đơn vị centimet). Mỗi điểm là một góc ô.
// Chỉ số một ô chép TerrainTileEditable: corners[1], corners[0], corners[2] rồi corners[1],
// corners[2], corners[3]. Không lật thì đường chéo phải-trên tới trái-dưới, trùng getHeightAt.
// Thứ tự đó đã có pháp tuyến +Y (FrontFace::kCounterClockwise). Ô pixmap nền 0 là lỗ, không sinh
// mặt.
#pragma once

#include "client/map/picture.hpp"

#include <cstdint>
#include <vector>

namespace game::client::map {

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
[[nodiscard]] Sheet build_sheet(const TerrainFile& file, const HeightField& heights, const GridField& grid);

} // namespace game::client::map
