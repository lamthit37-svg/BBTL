// Một map đã nạp đủ để cả ba nền vẽ: mô tả, độ cao, lưới, ảnh nhìn từ trên và lưới tam giác.
// Android và Windows đưa lưới vào renderer Vulkan. iOS đưa ảnh vào UIKit theo minimap_area.
// Đường dẫn tệp chỉ là tên trong thư mục Scene, không có slash, để không thoát khỏi dữ liệu.
#pragma once

#include "map/sheet.hpp"

#include <cstddef>
#include <expected>
#include <filesystem>
#include <string_view>

namespace game::map {

struct Ground {
    TerrainFile file;
    HeightField heights;
    GridField grid;
    Picture overview;
    Sheet sheet;

    [[nodiscard]] std::size_t triangle_count() const noexcept { return sheet.indices.size() / 3; }
};

using GroundResult = std::expected<Ground, MapError>;

// `folder` là thư mục Scene. `terrain_file` là tên tệp .Terrain trong thư mục đó.
[[nodiscard]] GroundResult load_ground(
    const std::filesystem::path& folder, std::string_view terrain_file);

// Đọc .Scene rồi nạp .Terrain mà cảnh trỏ tới. iOS gọi đường này khi gói có data/Scene.
[[nodiscard]] GroundResult load_scene_ground(const std::filesystem::path& scene_file);

} // namespace game::map
