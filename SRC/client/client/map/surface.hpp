// Nướng hai lớp cọ và lightmap của địa hình thành một ảnh. Góc pixmap chép từ
// Terrain::_getPixmapCorner: orientation là các bit lật/xoay, cờ lật đường chéo
// chọn nửa bảng. Ảnh nướng thuộc dữ liệu map, renderer chỉ nhận một texture.
#pragma once

#include "client/map/picture.hpp"
#include "client/map/terrain.hpp"

#include <cstdint>
#include <span>

namespace game::client::map {

// RGBA8, hàng trên cùng trước. rgba rỗng thì lớp đó bị bỏ.
struct SurfaceImage {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::span<const std::uint8_t> rgba;
};

struct SurfaceInputs {
    // Đúng thứ tự texture trong .Terrain. Thiếu phần tử thì lớp trỏ tới nó bị bỏ.
    std::span<const SurfaceImage> brushes;
    const SurfaceImage* light = nullptr;
};

struct PixmapPoint {
    float u = 0.0F;
    float v = 0.0F;
};

// corner 0 trái-trên, 1 phải-trên, 2 trái-dưới, 3 phải-dưới.
struct CornerQuery {
    std::uint16_t orientation = 0;
    int corner = 0;
    bool flip_diagonal = false;
};

// Ngoài corner 0..3 thì trả (0, 0). orientation từ 16 trở lên coi như 0.
[[nodiscard]] PixmapPoint pixmap_corner(const Pixmap& pixmap, CornerQuery query) noexcept;

// Rỗng khi không có cọ nào. Lỗ (pixmap nền 0) để alpha 0. Cạnh dài không quá 2048.
[[nodiscard]] Picture paint_surface(const TerrainFile& file, const GridField& grid, SurfaceInputs inputs);

} // namespace game::client::map
