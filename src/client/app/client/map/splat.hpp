// Ba ảnh nhỏ mà GPU ráp thành mặt đất lớp cọ (terrain.ps.hlsl), thay ảnh mặt đất nướng sẵn trên CPU: mọi ảnh
// cọ ghép một tấm atlas, một texel mỗi ô ghi pixmap nền/phủ và hướng, và một bảng tra (bốn góc theo
// orientation; hộp pixmap và phép đổi sang atlas). Bản đồ 512 x 512 ô chỉ cần ~1 MB thay vì 340 MB, dựng
// trong vài chục ms thay vì 2,7 s, và hoạ tiết được lọc bất đẳng hướng trên chính ảnh cọ nên nét ở mọi khoảng cách.
// Góc pixmap chép từ Terrain::_getPixmapCorner của client 2026: orientation là các bit lật/xoay, cờ lật
// đường chéo chọn nửa bảng. Bố cục từng texel khớp chú thích đầu terrain.ps.hlsl.
#pragma once

#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <cstdint>
#include <span>
#include <vector>

namespace game::client::map {

// Số texel mỗi hàng của bảng tra; khớp kTableWidth trong terrain.ps.hlsl và terrain.ps.glsl.
inline constexpr std::uint32_t kSplatTableWidth = 1024;

// Pixmap có 10 bit trong texel ô: id lớn hơn con số này bị bỏ.
inline constexpr std::uint32_t kSplatMaxPixmap = 1023;

// Ảnh cọ RGBA8 thẳng (chưa nhân alpha), hàng trên cùng trước.
struct BrushImage {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::span<const std::uint8_t> rgba;
};

// Cả ba ảnh rỗng khi không dựng được (không cọ nào dùng được, lưới sai cỡ).
struct SplatImages {
    // RGBA8, màu đã nhân alpha. Mỗi ảnh cọ đặt ở bội của 16 điểm ảnh, đệm 16 điểm ảnh lặp mép: mip tới mức 4 không
    // trộn ảnh kề nhau, và shader kẹp mức mip ở 4 (sampler max_lod).
    Picture atlas;
    // x_size * z_size texel, một texel mỗi ô.
    Picture cells;
    Picture table;

    [[nodiscard]] bool empty() const noexcept { return atlas.rgba.empty(); }
};

// Cọ nào của file.textures có ô dùng tới (qua pixmap của lớp nền hoặc phủ). Để nạp ảnh nào cần, bỏ ảnh còn lại.
// Phần tử bằng 0 là không dùng.
[[nodiscard]] std::vector<std::uint8_t> brushes_in_use(const TerrainFile& file, const GridField& grid);

// brushes theo đúng thứ tự file.textures; ảnh không dùng (xem brushes_in_use) có thể để trống. max_edge là trần
// cạnh atlas (GLES 3 bảo đảm texture 2048); không vừa thì mọi ảnh cọ thu nhỏ một nửa tới khi vừa.
[[nodiscard]] SplatImages build_splat(const TerrainFile& file, const GridField& grid,
    std::span<const BrushImage> brushes, std::uint32_t max_edge);

} // namespace game::client::map
