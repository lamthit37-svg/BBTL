#include "map/samples.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <string_view>
#include <vector>

namespace game::map {
namespace {

static_assert(std::endian::native == std::endian::little);

constexpr std::uint32_t kHeightMagic = 0x4645484DU;
constexpr std::uint32_t kHeightVersion = 0x00100000U;
constexpr std::uint32_t kGridMagic = 0x46454749U;
constexpr std::uint32_t kGridVersionMin = 0x00100000U;
constexpr std::uint32_t kGridVersionFlags = 0x00100001U;
constexpr std::uint32_t kGridVersionWide = 0x00100002U;
constexpr std::uint32_t kGridVersionMax = 0x00100002U;
struct Cursor {
    std::string_view bytes;
    std::size_t offset = 0;

    [[nodiscard]] bool take(void* out, std::size_t size) noexcept {
        if (offset > bytes.size()) return false;
        if (size > bytes.size() - offset) return false;
        std::memcpy(out, bytes.data() + offset, size);
        offset += size;
        return true;
    }

    [[nodiscard]] bool finished() const noexcept { return offset == bytes.size(); }
};

[[nodiscard]] bool read_u32(Cursor& cursor, std::uint32_t& value) noexcept {
    return cursor.take(&value, sizeof value);
}

[[nodiscard]] int junctions_of(int grids) noexcept { return grids + 1; }

[[nodiscard]] bool read_height_header(Cursor& cursor, int x_size, int z_size) noexcept {
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t width = 0;
    std::uint32_t depth = 0;
    if (!read_u32(cursor, magic) || !read_u32(cursor, version)) return false;
    if (!read_u32(cursor, width) || !read_u32(cursor, depth)) return false;
    const auto expect_x = static_cast<std::uint32_t>(junctions_of(x_size));
    const auto expect_z = static_cast<std::uint32_t>(junctions_of(z_size));
    return magic == kHeightMagic && version == kHeightVersion && width == expect_x &&
        depth == expect_z;
}

[[nodiscard]] bool read_layer(Cursor& cursor, Layer& layer, bool is_wide) noexcept {
    if (is_wide) {
        std::uint16_t pixmap = 0;
        std::uint8_t orientation = 0;
        if (!cursor.take(&pixmap, sizeof pixmap)) return false;
        if (!cursor.take(&orientation, sizeof orientation)) return false;
        layer.pixmap = pixmap;
        layer.orientation = orientation;
        return true;
    }
    std::uint8_t pixmap = 0;
    std::uint8_t orientation = 0;
    if (!cursor.take(&pixmap, sizeof pixmap)) return false;
    if (!cursor.take(&orientation, sizeof orientation)) return false;
    layer.pixmap = pixmap;
    layer.orientation = orientation;
    return true;
}

[[nodiscard]] bool pixmap_fits(const Layer& layer, std::uint32_t pixmap_count) noexcept {
    return layer.pixmap <= pixmap_count;
}

[[nodiscard]] bool read_cell(
    Cursor& cursor, Cell& cell, bool is_wide, bool has_flags, std::uint32_t pixmap_count) noexcept {
    if (!read_layer(cursor, cell.base, is_wide)) return false;
    if (!read_layer(cursor, cell.cover, is_wide)) return false;
    if (!pixmap_fits(cell.base, pixmap_count) || !pixmap_fits(cell.cover, pixmap_count)) {
        return false;
    }
    if (!has_flags) return true;
    return cursor.take(&cell.flags, sizeof cell.flags);
}

} // namespace

HeightResult read_heightmap(std::string_view bytes, int x_size, int z_size) {
    if (x_size <= 0 || z_size <= 0 || x_size > kMaxGrids || z_size > kMaxGrids) {
        return std::unexpected(MapError::kBadSize);
    }
    Cursor cursor{.bytes = bytes};
    if (!read_height_header(cursor, x_size, z_size)) return std::unexpected(MapError::kBadHeight);
    const int width = junctions_of(x_size);
    const int depth = junctions_of(z_size);
    const std::size_t count = static_cast<std::size_t>(width) * static_cast<std::size_t>(depth);
    HeightField field;
    field.samples.resize(count);
    const std::size_t bytes_needed = count * sizeof(float);
    if (!cursor.take(field.samples.data(), bytes_needed)) {
        return std::unexpected(MapError::kBadHeight);
    }
    if (!cursor.finished()) return std::unexpected(MapError::kBadHeight);
    return field;
}

GridResult read_grid(
    std::string_view bytes, int x_size, int z_size, std::uint32_t pixmap_count) {
    if (x_size <= 0 || z_size <= 0 || x_size > kMaxGrids || z_size > kMaxGrids) {
        return std::unexpected(MapError::kBadSize);
    }
    Cursor cursor{.bytes = bytes};
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t width = 0;
    std::uint32_t depth = 0;
    if (!read_u32(cursor, magic) || !read_u32(cursor, version)) {
        return std::unexpected(MapError::kBadGrid);
    }
    if (!read_u32(cursor, width) || !read_u32(cursor, depth)) {
        return std::unexpected(MapError::kBadGrid);
    }
    const bool header_ok = magic == kGridMagic && version >= kGridVersionMin &&
        version <= kGridVersionMax && width == static_cast<std::uint32_t>(x_size) &&
        depth == static_cast<std::uint32_t>(z_size);
    if (!header_ok) return std::unexpected(MapError::kBadGrid);
    bool is_wide = false;
    if (version >= kGridVersionWide) {
        std::uint8_t flag = 0;
        if (!cursor.take(&flag, sizeof flag)) return std::unexpected(MapError::kBadGrid);
        is_wide = flag != 0;
    }
    const bool has_flags = version >= kGridVersionFlags;
    const std::size_t count = static_cast<std::size_t>(x_size) * static_cast<std::size_t>(z_size);
    GridField field;
    field.cells.resize(count);
    for (Cell& cell : field.cells) {
        if (!read_cell(cursor, cell, is_wide, has_flags, pixmap_count)) {
            return std::unexpected(MapError::kBadGrid);
        }
    }
    if (!cursor.finished()) return std::unexpected(MapError::kBadGrid);
    return field;
}

} // namespace game::map
