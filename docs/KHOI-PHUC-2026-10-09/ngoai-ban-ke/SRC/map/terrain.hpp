// Tệp .Terrain của client gốc (WX TerrainDataSerializer, G:\TLBB\_ref, client 2008): kích thước
// lưới, tỉ lệ, tâm, tên heightmap / gridInfo / lightmap, ảnh nền và pixmap. Gốc thế giới của ô
// (0, 0) tính lại đúng công thức trong serializer: scale và size đặt gốc về -scale * số_ô / 2,
// centre trừ nửa kích thước, position ghi đè thẳng. Mỗi phần tử sau ghi đè phần trước.
// Chưa diễn giải byte của heightmap và grid: đó là samples.hpp. Chưa vẽ.
#pragma once

#include "scene/placement.hpp"

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::map {

// Trần số ô mỗi cạnh. 2048 ô là 2049^2 điểm độ cao, đủ các map của bản desktop đã đo.
constexpr int kMaxGrids = 2048;

enum class [[nodiscard]] MapError : std::uint8_t {
    kNotTerrain,
    kBadXml,
    kBadSize,
    kBadHeight,
    kBadGrid,
    kMissingFile,
};

struct Pixmap {
    std::uint32_t texture = 0;
    float left = 0.0F;
    float top = 0.0F;
    float right = 1.0F;
    float bottom = 1.0F;
};

// Mô tả trong XML. origin là góc ô (0, 0) trong thế giới, cùng mPosition của TerrainData.
struct TerrainFile {
    std::string name;
    int x_size = 0;
    int z_size = 0;
    int tile_size = 0;
    scene::Vector3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    scene::Vector3 origin{};
    std::string heightmap;
    std::string height_type = "standard";
    std::string grid_info;
    std::string lightmap;
    std::string light_type;
    std::vector<std::string> textures;
    std::vector<Pixmap> pixmaps;
};

using TerrainResult = std::expected<TerrainFile, MapError>;

// Cây XML của một tệp .Terrain.
[[nodiscard]] TerrainResult read_terrain(std::string_view text);

// Câu tiếng Việt ngắn cho log.
[[nodiscard]] std::string_view describe(MapError error) noexcept;

} // namespace game::map
