#include "client/map/samples.hpp"

#include "client/map/terrain.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client::map {
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
        const std::string_view slice = bytes.substr(offset, size);
        std::memcpy(out, slice.data(), size);
        offset += size;
        return true;
    }

    [[nodiscard]] bool finished() const noexcept { return offset == bytes.size(); }
};

[[nodiscard]] bool read_u32(Cursor& cursor, std::uint32_t& value) noexcept {
    return cursor.take(&value, sizeof value);
}

[[nodiscard]] int junctions_of(int grids) noexcept {
    return grids + 1;
}

[[nodiscard]] bool read_height_header(Cursor& cursor, GridSpan span) noexcept {
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t width = 0;
    std::uint32_t depth = 0;
    if (!read_u32(cursor, magic) || !read_u32(cursor, version)) return false;
    if (!read_u32(cursor, width) || !read_u32(cursor, depth)) return false;
    const auto expect_x = static_cast<std::uint32_t>(junctions_of(span.columns));
    const auto expect_z = static_cast<std::uint32_t>(junctions_of(span.rows));
    return magic == kHeightMagic && version == kHeightVersion && std::cmp_equal(width, expect_x) &&
        std::cmp_equal(depth, expect_z);
}

[[nodiscard]] bool read_wide_layer(Cursor& cursor, Layer& layer) noexcept {
    std::uint16_t pixmap = 0;
    std::uint8_t orientation = 0;
    if (!cursor.take(&pixmap, sizeof pixmap)) return false;
    if (!cursor.take(&orientation, sizeof orientation)) return false;
    layer.pixmap = pixmap;
    layer.orientation = orientation;
    return true;
}

[[nodiscard]] bool read_narrow_layer(Cursor& cursor, Layer& layer) noexcept {
    std::uint8_t pixmap = 0;
    std::uint8_t orientation = 0;
    if (!cursor.take(&pixmap, sizeof pixmap)) return false;
    if (!cursor.take(&orientation, sizeof orientation)) return false;
    layer.pixmap = pixmap;
    layer.orientation = orientation;
    return true;
}

[[nodiscard]] bool read_layer(Cursor& cursor, Layer& layer, bool is_wide) noexcept {
    if (is_wide) return read_wide_layer(cursor, layer);
    return read_narrow_layer(cursor, layer);
}

[[nodiscard]] bool pixmap_fits(const Layer& layer, std::uint32_t pixmap_count) noexcept {
    return layer.pixmap <= pixmap_count;
}

[[nodiscard]] bool read_cell(Cursor& cursor, Cell& cell, bool is_wide, bool has_flags,
    std::uint32_t pixmap_count) noexcept {
    if (!read_layer(cursor, cell.base, is_wide)) return false;
    if (!read_layer(cursor, cell.cover, is_wide)) return false;
    if (!pixmap_fits(cell.base, pixmap_count) || !pixmap_fits(cell.cover, pixmap_count)) {
        return false;
    }
    if (!has_flags) return true;
    return cursor.take(&cell.flags, sizeof cell.flags);
}

[[nodiscard]] bool span_fits(GridSpan span) noexcept {
    return span.columns > 0 && span.rows > 0 && span.columns <= kMaxGrids && span.rows <= kMaxGrids;
}

struct GridHeader {
    bool is_wide = false;
    bool has_flags = false;
    bool is_ok = false;
};

[[nodiscard]] bool take_wide_flag(Cursor& cursor, std::uint32_t version, bool& is_wide) noexcept {
    if (version < kGridVersionWide) return true;
    std::uint8_t flag = 0;
    if (!cursor.take(&flag, sizeof flag)) return false;
    is_wide = flag != 0;
    return true;
}

[[nodiscard]] GridHeader read_grid_header(Cursor& cursor, GridSpan span) noexcept {
    GridHeader header;
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t width = 0;
    std::uint32_t depth = 0;
    if (!read_u32(cursor, magic) || !read_u32(cursor, version)) return header;
    if (!read_u32(cursor, width) || !read_u32(cursor, depth)) return header;
    const bool magic_ok = magic == kGridMagic && version >= kGridVersionMin && version <= kGridVersionMax;
    const bool size_ok = std::cmp_equal(width, span.columns) && std::cmp_equal(depth, span.rows);
    if (!magic_ok || !size_ok) return header;
    if (!take_wide_flag(cursor, version, header.is_wide)) return header;
    header.has_flags = version >= kGridVersionFlags;
    header.is_ok = true;
    return header;
}

[[nodiscard]] bool read_cells(Cursor& cursor, GridField& field, const GridHeader& header,
    std::uint32_t pixmap_count) noexcept {
    bool is_ok = true;
    for (Cell& cell : field.cells) {
        is_ok = is_ok && read_cell(cursor, cell, header.is_wide, header.has_flags, pixmap_count);
    }
    return is_ok && cursor.finished();
}

} // namespace

HeightResult read_heightmap(std::string_view bytes, GridSpan span) {
    if (!span_fits(span)) return std::unexpected(MapError::kBadSize);
    Cursor cursor{.bytes = bytes};
    if (!read_height_header(cursor, span)) return std::unexpected(MapError::kBadHeight);
    const int width = junctions_of(span.columns);
    const int depth = junctions_of(span.rows);
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

GridResult read_grid(std::string_view bytes, GridSpan span, std::uint32_t pixmap_count) {
    if (!span_fits(span)) return std::unexpected(MapError::kBadSize);
    Cursor cursor{.bytes = bytes};
    const GridHeader header = read_grid_header(cursor, span);
    if (!header.is_ok) return std::unexpected(MapError::kBadGrid);
    const auto count = static_cast<std::size_t>(span.columns) * static_cast<std::size_t>(span.rows);
    GridField field;
    field.cells.resize(count);
    if (!read_cells(cursor, field, header, pixmap_count)) {
        return std::unexpected(MapError::kBadGrid);
    }
    return field;
}

} // namespace game::client::map
