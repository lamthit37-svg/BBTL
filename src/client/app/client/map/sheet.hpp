/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/map/sheet.hpp
 *  PHÂN HỆ   : Client / Map / Sheet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lưới tam giác của địa hình trong thế giới OGRE (Y lên, đơn vị centimet).
 *    Mỗi điểm là một góc ô. Chỉ số một ô chép TerrainTileEditable: corners[1],
 *    corners[0], corners[2] rồi corners[1], corners[2], corners[3]. Không lật
 *    thì đường chéo phải-trên tới trái-dưới, trùng getHeightAt. Thứ tự đó đã có
 *    pháp tuyến +Y (FrontFace::kCounterClockwise). Ô pixmap nền 0 là lỗ, không
 *    sinh mặt.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "client/map/picture.hpp"

#include <cstdint>
#include <span>
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

// Sáu góc của hai tam giác một ô, mỗi số là chỉ số góc cục bộ (0 trái-trên, 1 phải-trên, 2
// trái-dưới, 3 phải-dưới), theo cờ lật đường chéo. build_sheet và bộ dựng đỉnh theo ô của mặt đất
// lớp cọ cùng dùng bảng này.
[[nodiscard]] std::span<const std::uint8_t, 6> cell_order(bool is_flipped) noexcept;

// Lưới thế giới. Cao độ thế giới = origin.y + scale.y * độ cao trong tệp.
[[nodiscard]] Sheet build_sheet(const TerrainFile& file, const HeightField& heights, const GridField& grid);

} // namespace game::client::map
