#include "map/terrain.hpp"

#include "xml/document.hpp"

#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::map {
namespace {

using OptionalText = std::optional<std::string_view>;

[[nodiscard]] OptionalText attribute(const xml::Element& element, std::string_view name) noexcept {
    return xml::attribute(element, name);
}

[[nodiscard]] std::optional<std::uint32_t> parse_uint(std::string_view text) noexcept {
    if (text.empty()) return std::nullopt;
    std::uint32_t value = 0;
    for (const char digit : text) {
        if (digit < '0' || digit > '9') return std::nullopt;
        const std::uint32_t next = (value * 10U) + static_cast<std::uint32_t>(digit - '0');
        if (next < value) return std::nullopt;
        value = next;
    }
    return value;
}

[[nodiscard]] bool fits_grid(std::uint32_t value) noexcept {
    return value > 0 && value <= static_cast<std::uint32_t>(kMaxGrids);
}

// Gốc của serializer khi gặp scale hoặc size: nửa bản đồ nằm mỗi bên tâm 0.
void place_from_scale(TerrainFile& file) noexcept {
    const float half_x = file.scale.x * static_cast<float>(file.x_size) / 2.0F;
    const float half_z = file.scale.z * static_cast<float>(file.z_size) / 2.0F;
    file.origin = scene::Vector3{.x = -half_x, .y = 0.0F, .z = -half_z};
}

[[nodiscard]] bool apply_scale(TerrainFile& file, const xml::Element& element) noexcept {
    const OptionalText x = attribute(element, "x");
    const OptionalText y = attribute(element, "y");
    const OptionalText z = attribute(element, "z");
    if (!x || !y || !z) return false;
    const scene::Vector3 scale{
        .x = scene::parse_real(*x), .y = scene::parse_real(*y), .z = scene::parse_real(*z)};
    if (scale.x <= 0.0F || scale.y <= 0.0F || scale.z <= 0.0F) return false;
    file.scale = scale;
    place_from_scale(file);
    return true;
}

// size là kích thước thế giới của cả bản đồ; scale = size / số ô, y giữ nguyên.
[[nodiscard]] bool apply_size(TerrainFile& file, const xml::Element& element) noexcept {
    const OptionalText x = attribute(element, "x");
    const OptionalText y = attribute(element, "y");
    const OptionalText z = attribute(element, "z");
    if (!x || !y || !z) return false;
    const float width = scene::parse_real(*x);
    const float height = scene::parse_real(*y);
    const float depth = scene::parse_real(*z);
    const float cells_x = static_cast<float>(file.x_size);
    const float cells_z = static_cast<float>(file.z_size);
    const scene::Vector3 scale{.x = width / cells_x, .y = height, .z = depth / cells_z};
    if (scale.x <= 0.0F || scale.y <= 0.0F || scale.z <= 0.0F) return false;
    file.scale = scale;
    place_from_scale(file);
    return true;
}

[[nodiscard]] bool apply_position(TerrainFile& file, const xml::Element& element) noexcept {
    const OptionalText x = attribute(element, "x");
    const OptionalText y = attribute(element, "y");
    const OptionalText z = attribute(element, "z");
    if (!x || !y || !z) return false;
    file.origin = scene::Vector3{
        .x = scene::parse_real(*x), .y = scene::parse_real(*y), .z = scene::parse_real(*z)};
    return true;
}

[[nodiscard]] bool apply_centre(TerrainFile& file, const xml::Element& element) noexcept {
    const OptionalText x = attribute(element, "x");
    const OptionalText y = attribute(element, "y");
    const OptionalText z = attribute(element, "z");
    if (!x || !y || !z) return false;
    const float half_x = file.scale.x * static_cast<float>(file.x_size) / 2.0F;
    const float half_z = file.scale.z * static_cast<float>(file.z_size) / 2.0F;
    file.origin = scene::Vector3{.x = scene::parse_real(*x) - half_x,
        .y = scene::parse_real(*y),
        .z = scene::parse_real(*z) - half_z};
    return true;
}

[[nodiscard]] bool take_sizes(TerrainFile& file, const xml::Element& root) noexcept {
    const OptionalText x = attribute(root, "xsize");
    const OptionalText z = attribute(root, "zsize");
    const OptionalText tile = attribute(root, "tileSize");
    if (!x || !z || !tile) return false;
    const std::optional<std::uint32_t> x_size = parse_uint(*x);
    const std::optional<std::uint32_t> z_size = parse_uint(*z);
    const std::optional<std::uint32_t> tile_size = parse_uint(*tile);
    if (!x_size || !z_size || !tile_size) return false;
    if (!fits_grid(*x_size) || !fits_grid(*z_size) || *tile_size == 0) return false;
    file.x_size = static_cast<int>(*x_size);
    file.z_size = static_cast<int>(*z_size);
    file.tile_size = static_cast<int>(*tile_size);
    return true;
}

void take_named(std::string& name, std::string& type, const xml::Element& element,
    std::string_view fallback_type) {
    const OptionalText filename = attribute(element, "filename");
    const OptionalText kind = attribute(element, "type");
    if (filename) name = std::string(*filename);
    type = kind ? std::string(*kind) : std::string(fallback_type);
}

void add_texture(TerrainFile& file, const xml::Document& document, const xml::Element& parent) {
    for (const std::uint32_t child : parent.children) {
        const xml::Element& element = document.elements[child];
        if (element.name != "texture") continue;
        const OptionalText filename = attribute(element, "filename");
        if (filename) file.textures.emplace_back(*filename);
    }
}

[[nodiscard]] bool add_pixmap(TerrainFile& file, const xml::Element& element) {
    const OptionalText texture = attribute(element, "textureId");
    if (!texture) return false;
    const std::optional<std::uint32_t> texture_id = parse_uint(*texture);
    if (!texture_id) return false;
    Pixmap pixmap;
    pixmap.texture = *texture_id;
    const OptionalText left = attribute(element, "left");
    const OptionalText top = attribute(element, "top");
    const OptionalText right = attribute(element, "right");
    const OptionalText bottom = attribute(element, "bottom");
    if (left) pixmap.left = scene::parse_real(*left);
    if (top) pixmap.top = scene::parse_real(*top);
    if (right) pixmap.right = scene::parse_real(*right);
    if (bottom) pixmap.bottom = scene::parse_real(*bottom);
    file.pixmaps.push_back(pixmap);
    return true;
}

[[nodiscard]] bool add_pixmaps(
    TerrainFile& file, const xml::Document& document, const xml::Element& parent) {
    for (const std::uint32_t child : parent.children) {
        const xml::Element& element = document.elements[child];
        if (element.name != "pixmap") continue;
        if (!add_pixmap(file, element)) return false;
    }
    return true;
}

[[nodiscard]] bool visit(
    TerrainFile& file, const xml::Document& document, const xml::Element& element) {
    if (element.name == "scale") return apply_scale(file, element);
    if (element.name == "size") return apply_size(file, element);
    if (element.name == "position") return apply_position(file, element);
    if (element.name == "centre" || element.name == "center") return apply_centre(file, element);
    if (element.name == "heightmap") {
        take_named(file.heightmap, file.height_type, element, "standard");
        return true;
    }
    if (element.name == "gridInfo") {
        std::string ignored;
        take_named(file.grid_info, ignored, element, "standard");
        return true;
    }
    if (element.name == "lightmap") {
        take_named(file.lightmap, file.light_type, element, "standard");
        return true;
    }
    if (element.name == "textures") {
        add_texture(file, document, element);
        return true;
    }
    if (element.name == "pixmaps") return add_pixmaps(file, document, element);
    return true;
}

} // namespace

TerrainResult read_terrain(std::string_view text) {
    const xml::ParseResult document = xml::parse(text);
    if (!document) return std::unexpected(MapError::kBadXml);
    const xml::Element& root = document->elements.front();
    if (root.name != "Terrain") return std::unexpected(MapError::kNotTerrain);
    TerrainFile file;
    const OptionalText name = attribute(root, "name");
    if (name) file.name = std::string(*name);
    if (!take_sizes(file, root)) return std::unexpected(MapError::kBadSize);
    for (const std::uint32_t child : root.children) {
        const xml::Element& element = document->elements[child];
        if (!visit(file, *document, element)) return std::unexpected(MapError::kBadSize);
    }
    return file;
}

std::string_view describe(MapError error) noexcept {
    switch (error) {
    case MapError::kNotTerrain: return "gốc XML không phải Terrain";
    case MapError::kBadXml: return "XML địa hình hỏng";
    case MapError::kBadSize: return "kích thước hoặc tỉ lệ địa hình không hợp lệ";
    case MapError::kBadHeight: return "heightmap hỏng hoặc không phải kiểu standard";
    case MapError::kBadGrid: return "grid info hỏng";
    case MapError::kMissingFile: return "thiếu tệp địa hình";
    }
    return "lỗi địa hình không rõ";
}

} // namespace game::map
