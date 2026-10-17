/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/map/splat.hpp
 *  PHÂN HỆ   : Client / Map / Splat
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Atlas cọ và toạ độ atlas bốn góc của mỗi ô cho lớp nền và lớp phủ, ghép
 *    sẵn ở đỉnh nên terrain.ps chỉ lấy mẫu atlas, tam giác có đạo hàm riêng.
 *  - Đo 2026-10-17 trên GE8320: tra bảng theo điểm ảnh 46,5 FPS, ở đỉnh 59,6.
 *  - Góc pixmap chép từ Terrain::_getPixmapCorner: orientation là bit lật hoặc
 *    xoay, cờ lật đường chéo chọn nửa bảng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <vector>

namespace game::client::map {

// Ảnh cọ RGBA8 thẳng (chưa nhân alpha), hàng trên cùng trước.
struct BrushImage {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::span<const std::uint8_t> rgba;
};

// Hộp của một pixmap trong atlas, theo toạ độ [0, 1] của atlas: cạnh 0 trái, 1 trên, 2 phải, 3
// dưới. is_ready sai khi cọ của pixmap không có ảnh dùng được (hoặc id không phải pixmap).
struct PixmapBox {
    std::array<float, 4> edge{};
    bool is_ready = false;
};

// atlas rỗng khi không dựng được (không cọ nào dùng được, lưới sai cỡ).
struct SplatImages {
    // RGBA8, màu đã nhân alpha. Mỗi ảnh cọ đặt ở bội của 16 điểm ảnh, đệm 16 điểm ảnh lặp mép: mip
    // tới mức 4 không trộn ảnh kề nhau, và shader kẹp mức mip ở 4 (sampler max_lod).
    Picture atlas;
    // Theo id pixmap của file (1 trở lên; phần tử 0 không dùng).
    std::vector<PixmapBox> boxes;

    [[nodiscard]] bool empty() const noexcept { return atlas.rgba.empty(); }
};

struct AtlasUv {
    float u = 0.0F;
    float v = 0.0F;
};

// Bốn góc của một lớp trong một ô: 0 trái-trên, 1 phải-trên, 2 trái-dưới, 3 phải-dưới (cùng chỉ số
// với cell_order ở sheet.hpp). is_set sai khi ô không có lớp ấy.
struct LayerUv {
    bool is_set = false;
    std::array<AtlasUv, 4> corner{};
};

// base không is_set là lỗ địa hình, và khi ấy cover cũng không is_set.
struct CellUv {
    LayerUv base;
    LayerUv cover;
};

// Cọ nào của file.textures có ô dùng tới (qua pixmap của lớp nền hoặc phủ). Để nạp ảnh nào cần, bỏ
// ảnh còn lại. Phần tử bằng 0 là không dùng.
[[nodiscard]] std::vector<std::uint8_t> brushes_in_use(const TerrainFile& file,
    const GridField& grid);

// brushes theo đúng thứ tự file.textures; ảnh không dùng (xem brushes_in_use) có thể để trống.
// max_edge là trần cạnh atlas (GLES 3 bảo đảm texture 2048); không vừa thì mọi ảnh cọ thu nhỏ một
// nửa tới khi vừa.
[[nodiscard]] SplatImages build_splat(const TerrainFile& file, const GridField& grid,
    std::span<const BrushImage> brushes, std::uint32_t max_edge);

// Toạ độ atlas bốn góc của một ô. splat phải là kết quả của build_splat cùng file.
[[nodiscard]] CellUv cell_uv(const SplatImages& splat, const Cell& cell) noexcept;

} // namespace game::client::map
