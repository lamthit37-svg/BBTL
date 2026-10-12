// Byte heightmap và grid info của TerrainData::_loadHeightmap / _loadGridInfo (client 2008).
// Heightmap "standard": magic 'FEHM' (0x4645484D), phiên bản 0x00100000, rộng và sâu là số điểm
// (số ô + 1), rồi float32 little-endian. Grid "standard": magic 'FEGI' (0x46454749), phiên bản
// từ 0x00100000 tới 0x00100002, rộng và sâu là số ô. Từ 0x00100002 có một byte chọn pixmap 16 bit.
// Mỗi ô hai lớp (pixmap, hướng); từ 0x00100001 thêm một byte cờ. pixmap 0 là lỗ, không phải chỉ số.
// Tệp là little-endian, đúng máy này (Windows, Android arm64, iOS arm64).
#pragma once

#include "client/map/terrain.hpp"

#include <cstdint>
#include <expected>
#include <string_view>
#include <vector>

namespace game::client::map {

// Cờ GridInfo::FlipDiagonal của bản gốc: đường chéo ô lật sang hướng kia.
constexpr std::uint8_t kFlipDiagonal = 1U;

struct Layer {
    // 0 là lỗ; khác 0 thì pixmap nằm ở pixmaps[pixmap - 1].
    std::uint16_t pixmap = 0;
    std::uint8_t orientation = 0;
};

struct Cell {
    Layer base;
    Layer cover;
    std::uint8_t flags = 0;
};

struct HeightField {
    // (x_size + 1) * (z_size + 1) điểm, hàng z, trong hàng tăng x. Chỉ số z * (x_size + 1) + x.
    std::vector<float> samples;
};

struct GridField {
    // x_size * z_size ô, chỉ số z * x_size + x.
    std::vector<Cell> cells;
};

using HeightResult = std::expected<HeightField, MapError>;
using GridResult = std::expected<GridField, MapError>;

// Số ô của bản đồ. columns là cạnh x, rows là cạnh z.
struct GridSpan {
    int columns = 0;
    int rows = 0;
};

// `bytes` là cả tệp. pixmap_count là số pixmap trong XML; id lớn hơn số đó thì tệp hỏng.
[[nodiscard]] HeightResult read_heightmap(std::string_view bytes, GridSpan span);

[[nodiscard]] GridResult read_grid(std::string_view bytes, GridSpan span, std::uint32_t pixmap_count);

} // namespace game::client::map
