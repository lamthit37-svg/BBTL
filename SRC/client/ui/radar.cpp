#include "ui/radar.hpp"

#include "core/error.hpp"
#include "gui/sheet.hpp"
#include "io/file.hpp"
#include "resource/image.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <iterator>
#include <span>
#include <string>
#include <utility>

namespace game::ui {
namespace {

constexpr float kPixelsPerUnit = 4.0F;
constexpr int kAtlasPixels = kRadarTilePixels * kRadarAtlasTiles;
constexpr std::size_t kTileRow = static_cast<std::size_t>(kRadarTilePixels) * 4;
constexpr std::size_t kTileBytes = kTileRow * static_cast<std::size_t>(kRadarTilePixels);
constexpr std::size_t kAtlasRow = static_cast<std::size_t>(kAtlasPixels) * 4;
constexpr std::size_t kAtlasBytes = kAtlasRow * static_cast<std::size_t>(kAtlasPixels);

// Đoạn điểm ảnh của vùng thấy trên một trục của ảnh cả cảnh.
struct PixelSpan {
    float low = 0.0F;
    float high = 0.0F;
};

// Vùng thấy theo chiều ngang và theo chiều dọc của ảnh cả cảnh.
[[nodiscard]] PixelSpan across_span(const RadarAim& seen) noexcept {
    const float pixels = seen.scene_width * kPixelsPerUnit;
    return PixelSpan{.low = seen.view.u0 * pixels, .high = seen.view.u1 * pixels};
}

[[nodiscard]] PixelSpan down_span(const RadarAim& seen) noexcept {
    const float pixels = seen.scene_depth * kPixelsPerUnit;
    return PixelSpan{.low = seen.view.v0 * pixels, .high = seen.view.v1 * pixels};
}

// Atlas bắt đầu ở ô first có phủ trọn đoạn span không.
[[nodiscard]] bool holds(int first, PixelSpan span) noexcept {
    const auto start = static_cast<float>(first * kRadarTilePixels);
    return span.low >= start && span.high <= start + static_cast<float>(kAtlasPixels);
}

// Ô đầu của atlas để tâm đoạn span nằm gần tâm atlas, kẹp trong số ô count của cảnh.
[[nodiscard]] int first_tile(PixelSpan span, int count) noexcept {
    const float centre = (span.low + span.high) * 0.5F;
    const auto nearest = static_cast<int>(std::floor((centre / kRadarTilePixels) + 0.5F));
    const int last_first = std::max(count - kRadarAtlasTiles, 0);
    return std::clamp(nearest - 1, 0, last_first);
}

[[nodiscard]] float atlas_part(float whole_part, float scene, int first) noexcept {
    const float pixel = whole_part * scene * kPixelsPerUnit;
    const auto start = static_cast<float>(first * kRadarTilePixels);
    return (pixel - start) / static_cast<float>(kAtlasPixels);
}

} // namespace

RadarAtlas::RadarAtlas(std::filesystem::path data_root) : root_(std::move(data_root)) {
    atlas_.name = "ui.radar";
    atlas_.width = static_cast<std::uint32_t>(kAtlasPixels);
    atlas_.height = static_cast<std::uint32_t>(kAtlasPixels);
    atlas_.rgba.assign(kAtlasBytes, 0);
}

void RadarAtlas::reset(const RadarAim& seen) {
    token_ = seen.token;
    scene_width_ = seen.scene_width;
    scene_depth_ = seen.scene_depth;
    columns_ = gui::radar_tiles(seen.scene_width);
    rows_ = gui::radar_tiles(seen.scene_depth);
    tiles_.clear();
    origin_.reset();
    filled_ = 0;
}

bool RadarAtlas::covers(const RadarAim& seen) const noexcept {
    if (!origin_) return false;
    return holds(origin_->column, across_span(seen)) && holds(origin_->row, down_span(seen));
}

RadarAtlas::Origin RadarAtlas::origin_for(const RadarAim& seen) const noexcept {
    const int column = first_tile(across_span(seen), columns_);
    return Origin{.column = column, .row = first_tile(down_span(seen), rows_)};
}

bool RadarAtlas::aim(const RadarAim& seen) {
    const bool is_same_scene =
        seen.token == token_ && seen.scene_width == scene_width_ && seen.scene_depth == scene_depth_;
    if (!is_same_scene) reset(seen);
    if (columns_ <= 0 || rows_ <= 0 || token_.empty()) return false;
    if (covers(seen)) return false;
    const Origin wanted = origin_for(seen);
    if (origin_ == wanted) return false;
    origin_ = wanted;
    stitch();
    return true;
}

RadarAtlas::Tile RadarAtlas::load(int column, int row) {
    Tile tile;
    tile.column = column;
    tile.row = row;
    ++reads_;
    const std::string name = gui::radar_tile_path(token_, column, row);
    const io::TextResult bytes = io::read_text(root_ / io::path_from_utf8(name));
    if (!bytes) return tile;
    const auto raw = std::as_bytes(std::span(*bytes));
    core::Result<resource::Image> image = resource::decode_image(raw);
    if (!image) return tile;
    const bool is_tile_sized = image->width == static_cast<std::uint32_t>(kRadarTilePixels) &&
        image->height == static_cast<std::uint32_t>(kRadarTilePixels);
    if (!is_tile_sized || image->rgba.size() != kTileBytes) return tile;
    tile.rgba = std::move(image->rgba);
    return tile;
}

// Ô đã giải mã lấy từ bộ đệm; chưa có thì đọc, đầy bộ đệm thì bỏ ô lâu chưa dùng nhất.
const RadarAtlas::Tile& RadarAtlas::tile_at(int column, int row) {
    const auto is_wanted = [column, row](const Tile& tile) { return tile.column == column && tile.row == row; };
    auto found = std::ranges::find_if(tiles_, is_wanted);
    if (found == tiles_.end() && tiles_.size() >= kRadarKeptTiles) {
        found = std::ranges::min_element(tiles_, {}, &Tile::used);
        *found = load(column, row);
    }
    if (found == tiles_.end()) {
        tiles_.push_back(load(column, row));
        found = std::prev(tiles_.end());
    }
    found->used = ++clock_;
    return *found;
}

// Chép ô (cột across, hàng down của atlas) vào ảnh atlas; ô ngoài cảnh hay thiếu tệp thì trong
// suốt.
void RadarAtlas::place(Origin origin, Slot slot) {
    const int column = origin.column + slot.across;
    const int row = origin.row + slot.down;
    if (column >= columns_ || row >= rows_) return;
    const Tile& tile = tile_at(column, row);
    if (tile.rgba.empty()) return;
    ++filled_;
    const std::size_t left = static_cast<std::size_t>(slot.across) * kTileRow;
    const std::size_t top = static_cast<std::size_t>(slot.down) * kRadarTilePixels;
    const std::span<const std::uint8_t> source(tile.rgba);
    const std::span<std::uint8_t> target(atlas_.rgba);
    for (std::size_t line = 0; line < static_cast<std::size_t>(kRadarTilePixels); ++line) {
        const std::span<const std::uint8_t> row_bytes = source.subspan(line * kTileRow, kTileRow);
        std::ranges::copy(row_bytes, target.subspan(((top + line) * kAtlasRow) + left).begin());
    }
}

void RadarAtlas::stitch() {
    std::ranges::fill(atlas_.rgba, std::uint8_t{0});
    filled_ = 0;
    const Origin origin = origin_.value_or(Origin{});
    for (int index = 0; index < kRadarAtlasTiles * kRadarAtlasTiles; ++index) {
        const Slot slot{.across = index % kRadarAtlasTiles, .down = index / kRadarAtlasTiles};
        place(origin, slot);
    }
}

gui::Radar RadarAtlas::to_atlas(const gui::Radar& whole) const noexcept {
    if (!origin_) return whole;
    gui::Radar part;
    part.u0 = atlas_part(whole.u0, scene_width_, origin_->column);
    part.u1 = atlas_part(whole.u1, scene_width_, origin_->column);
    part.v0 = atlas_part(whole.v0, scene_depth_, origin_->row);
    part.v1 = atlas_part(whole.v1, scene_depth_, origin_->row);
    return part;
}

} // namespace game::ui
