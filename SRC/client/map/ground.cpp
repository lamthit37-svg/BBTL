#include "client/map/ground.hpp"

#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/sheet.hpp"
#include "client/map/terrain.hpp"
#include "io/file.hpp"
#include "scene/scene_file.hpp"

#include <cstdint>
#include <expected>
#include <filesystem>
#include <string>
#include <string_view>

namespace game::client::map {
namespace {

[[nodiscard]] bool is_file_name(std::string_view name) noexcept {
    if (name.empty() || name == "." || name == "..") return false;
    return !name.contains('/') && !name.contains('\\');
}

[[nodiscard]] GroundResult fail(MapError error) {
    return std::unexpected(error);
}

[[nodiscard]] GroundResult from_text(const std::filesystem::path& folder, std::string_view terrain_text) {
    const TerrainResult described = read_terrain(terrain_text);
    if (!described) return fail(described.error());
    if (described->height_type != kStandardType) return fail(MapError::kBadHeight);
    if (!is_file_name(described->heightmap) || !is_file_name(described->grid_info)) {
        return fail(MapError::kMissingFile);
    }
    const std::filesystem::path height_path = folder / io::path_from_utf8(described->heightmap);
    const std::filesystem::path grid_path = folder / io::path_from_utf8(described->grid_info);
    const io::TextResult height_text = io::read_text(height_path);
    const io::TextResult grid_text = io::read_text(grid_path);
    if (!height_text || !grid_text) return fail(MapError::kMissingFile);
    const GridSpan span{.columns = described->x_size, .rows = described->z_size};
    const HeightResult heights = read_heightmap(*height_text, span);
    if (!heights) return fail(heights.error());
    const auto pixmap_count = static_cast<std::uint32_t>(described->pixmaps.size());
    const GridResult grid = read_grid(*grid_text, span, pixmap_count);
    if (!grid) return fail(grid.error());
    Ground ground;
    ground.file = *described;
    ground.heights = *heights;
    ground.grid = *grid;
    ground.overview = paint_overview(ground.file, ground.heights, ground.grid);
    ground.sheet = build_sheet(ground.file, ground.heights, ground.grid);
    return ground;
}

} // namespace

GroundResult load_ground(const std::filesystem::path& folder, std::string_view terrain_file) {
    if (!is_file_name(terrain_file)) return fail(MapError::kMissingFile);
    const std::filesystem::path path = folder / io::path_from_utf8(terrain_file);
    const io::TextResult text = io::read_text(path);
    if (!text) return fail(MapError::kMissingFile);
    return from_text(folder, *text);
}

GroundResult load_scene_ground(const std::filesystem::path& scene_file) {
    const io::TextResult text = io::read_text(scene_file);
    if (!text) return fail(MapError::kMissingFile);
    const scene::SceneResult scene = scene::read_scene(*text);
    if (!scene) return fail(MapError::kBadXml);
    if (scene->terrain_file.empty()) return fail(MapError::kNotTerrain);
    return load_ground(scene_file.parent_path(), scene->terrain_file);
}

} // namespace game::client::map
