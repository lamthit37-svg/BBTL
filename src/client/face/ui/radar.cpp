#include "ui/radar.hpp"

#include "core/error.hpp"
#include "gui/sheet.hpp"
#include "io/file.hpp"
#include "resource/image.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <iterator>
#include <optional>
#include <span>
#include <string>
#include <utility>

namespace game::ui {
namespace {

constexpr float kPixelsPerUnit = 4.0F;
constexpr std::size_t kTileRow = static_cast<std::size_t>(kRadarTilePixels) * 4;
constexpr std::size_t kTileBytes = kTileRow * static_cast<std::size_t>(kRadarTilePixels);
constexpr std::size_t kBytesPerPixel = 4;

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

// Atlas rộng tiles ô, bắt đầu ở ô first, có phủ trọn đoạn span không.
[[nodiscard]] bool holds(int first, int tiles, PixelSpan span) noexcept {
    const auto start = static_cast<float>(first * kRadarTilePixels);
    return span.low >= start && span.high <= start + static_cast<float>(tiles * kRadarTilePixels);
}

// Ô đầu của atlas rộng tiles ô để tâm đoạn span nằm gần tâm atlas, kẹp trong số ô count của cảnh.
[[nodiscard]] int first_tile(PixelSpan span, int count, int tiles) noexcept {
    const float centre = (span.low + span.high) * 0.5F;
    const auto nearest = static_cast<int>(std::floor((centre / kRadarTilePixels) + 0.5F));
    const int last_first = std::max(count - tiles, 0);
    return std::clamp(nearest - (tiles / 2), 0, last_first);
}

[[nodiscard]] float atlas_part(float whole_part, float scene, int first, int tiles) noexcept {
    const float pixel = whole_part * scene * kPixelsPerUnit;
    const auto start = static_cast<float>(first * kRadarTilePixels);
    return (pixel - start) / static_cast<float>(tiles * kRadarTilePixels);
}

} // namespace

RadarAtlas::RadarAtlas(std::filesystem::path data_root, AtlasShape shape) : root_(std::move(data_root)), shape_(shape) {
    const int tile = kRadarTilePixels / shape_.shrink;
    atlas_.name = "ui.radar";
    atlas_.width = static_cast<std::uint32_t>(shape_.across * tile);
    atlas_.height = static_cast<std::uint32_t>(shape_.down * tile);
    atlas_.rgba.assign(static_cast<std::size_t>(atlas_.width) * atlas_.height * kBytesPerPixel, 0);
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
    return holds(origin_->column, shape_.across, across_span(seen)) &&
        holds(origin_->row, shape_.down, down_span(seen));
}

RadarAtlas::Origin RadarAtlas::origin_for(const RadarAim& seen) const noexcept {
    const int column = first_tile(across_span(seen), columns_, shape_.across);
    return Origin{.column = column, .row = first_tile(down_span(seen), rows_, shape_.down)};
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
    if (found == tiles_.end() && tiles_.size() >= shape_.kept) {
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

namespace {

// Một điểm ảnh của ô thu nhỏ: trung bình hộp shrink x shrink điểm ảnh gốc, cộng từng kênh (alpha thẳng).
struct ShrinkAt {
    std::size_t line = 0;
    std::size_t column = 0;
    std::size_t shrink = 1;
};

[[nodiscard]] std::array<std::uint8_t, kBytesPerPixel> shrunk_pixel(std::span<const std::uint8_t> source,
    ShrinkAt at) noexcept {
    std::array<std::size_t, kBytesPerPixel> sum{};
    for (std::size_t dy = 0; dy < at.shrink; ++dy) {
        for (std::size_t dx = 0; dx < at.shrink; ++dx) {
            const std::size_t row = (at.line * at.shrink) + dy;
            const std::size_t first =
                ((row * static_cast<std::size_t>(kRadarTilePixels)) + (at.column * at.shrink) + dx) * kBytesPerPixel;
            for (std::size_t channel = 0; channel < kBytesPerPixel; ++channel)
                sum.at(channel) += source[first + channel];
        }
    }
    std::array<std::uint8_t, kBytesPerPixel> out{};
    for (std::size_t channel = 0; channel < kBytesPerPixel; ++channel) {
        out.at(channel) = static_cast<std::uint8_t>(sum.at(channel) / (at.shrink * at.shrink));
    }
    return out;
}

} // namespace

// Chép ô (cột across, hàng down của atlas) vào ảnh atlas, thu nhỏ khi atlas thu nhỏ; ô ngoài cảnh hay
// thiếu tệp thì trong suốt.
void RadarAtlas::place(Origin origin, Slot slot) {
    const int column = origin.column + slot.across;
    const int row = origin.row + slot.down;
    if (column >= columns_ || row >= rows_) return;
    const Tile& tile = tile_at(column, row);
    if (tile.rgba.empty()) return;
    ++filled_;
    const auto shrink = static_cast<std::size_t>(shape_.shrink);
    const std::size_t edge = static_cast<std::size_t>(kRadarTilePixels) / shrink;
    const std::size_t atlas_row = static_cast<std::size_t>(atlas_.width) * kBytesPerPixel;
    const std::size_t left = static_cast<std::size_t>(slot.across) * edge * kBytesPerPixel;
    const std::size_t top = static_cast<std::size_t>(slot.down) * edge;
    const std::span<const std::uint8_t> source(tile.rgba);
    const std::span<std::uint8_t> target(atlas_.rgba);
    for (std::size_t line = 0; line < edge; ++line) {
        const std::size_t to = ((top + line) * atlas_row) + left;
        if (shrink == 1) {
            std::ranges::copy(source.subspan(line * kTileRow, kTileRow), target.subspan(to).begin());
            continue;
        }
        for (std::size_t across = 0; across < edge; ++across) {
            const auto pixel = shrunk_pixel(source, ShrinkAt{.line = line, .column = across, .shrink = shrink});
            std::ranges::copy(pixel, target.subspan(to + (across * kBytesPerPixel)).begin());
        }
    }
}

void RadarAtlas::stitch() {
    std::ranges::fill(atlas_.rgba, std::uint8_t{0});
    filled_ = 0;
    const Origin origin = origin_.value_or(Origin{});
    for (int index = 0; index < shape_.across * shape_.down; ++index) {
        const Slot slot{.across = index % shape_.across, .down = index / shape_.across};
        place(origin, slot);
    }
}

namespace {

// Ảnh PNG của lớp phủ: đúng cỡ expect thì trả RGBA, không thì nullopt và ghi lý do vào notes.
struct OverlayPart {
    std::string name;
    int width = 0;
    int height = 0;
};

[[nodiscard]] std::optional<resource::Image> read_part(const std::filesystem::path& common_dir,
    const OverlayPart& part, std::string& notes) {
    const std::filesystem::path file = common_dir / io::path_from_utf8(part.name);
    const io::TextResult bytes = io::read_text(file);
    if (!bytes) {
        notes += std::format("thiếu {}\n", part.name);
        return std::nullopt;
    }
    const auto raw = std::as_bytes(std::span(*bytes));
    core::Result<resource::Image> image = resource::decode_image(raw);
    if (!image) {
        notes += std::format("ảnh {} hỏng\n", part.name);
        return std::nullopt;
    }
    const bool is_sized = image->width == static_cast<std::uint32_t>(part.width) &&
        image->height == static_cast<std::uint32_t>(part.height);
    if (!is_sized) {
        notes += std::format("ảnh {} sai cỡ\n", part.name);
        return std::nullopt;
    }
    return std::move(*image);
}

// Chép ảnh image vào overlay với góc trái trên ở (left, top).
void blit(resource::Image& overlay, const resource::Image& image, int left, int top) {
    const std::size_t line = static_cast<std::size_t>(image.width) * kBytesPerPixel;
    const std::size_t overlay_line = static_cast<std::size_t>(overlay.width) * kBytesPerPixel;
    const std::size_t left_bytes = static_cast<std::size_t>(left) * kBytesPerPixel;
    for (std::uint32_t row = 0; row < image.height; ++row) {
        const std::size_t from = static_cast<std::size_t>(row) * line;
        const std::size_t down = static_cast<std::size_t>(top) + row;
        const std::size_t to = (down * overlay_line) + left_bytes;
        const std::span<const std::uint8_t> source = std::span(image.rgba).subspan(from, line);
        std::ranges::copy(source, overlay.rgba.begin() + static_cast<std::ptrdiff_t>(to));
    }
}

} // namespace

OverlayImage build_overlay(const std::filesystem::path& common_dir, std::string& notes) {
    OverlayImage out;
    out.image.name = "ui.minimap_overlay";
    out.image.width = static_cast<std::uint32_t>(kOverlayWidth);
    out.image.height = static_cast<std::uint32_t>(kOverlayHeight);
    out.image.has_mips = false;
    const auto pixels = static_cast<std::size_t>(kOverlayWidth * kOverlayHeight);
    out.image.rgba.assign(pixels * kBytesPerPixel, 0);
    OverlayPart arrow_part;
    arrow_part.name = "MiniMap_Arrow.png";
    arrow_part.width = kArrowSheetWidth;
    arrow_part.height = kArrowSheetHeight;
    OverlayPart light_part;
    light_part.name = "MapSearchLight.png";
    light_part.width = kLightImageSize;
    light_part.height = kLightImageSize;
    const std::optional<resource::Image> arrow = read_part(common_dir, arrow_part, notes);
    const std::optional<resource::Image> light = read_part(common_dir, light_part, notes);
    if (arrow) blit(out.image, *arrow, 0, 0);
    if (light) blit(out.image, *light, kLightX, kLightY);
    out.has_arrow = arrow.has_value();
    out.has_light = light.has_value();
    return out;
}

gui::Radar RadarAtlas::to_atlas(const gui::Radar& whole) const noexcept {
    if (!origin_) return whole;
    gui::Radar part;
    part.u0 = atlas_part(whole.u0, scene_width_, origin_->column, shape_.across);
    part.u1 = atlas_part(whole.u1, scene_width_, origin_->column, shape_.across);
    part.v0 = atlas_part(whole.v0, scene_depth_, origin_->row, shape_.down);
    part.v1 = atlas_part(whole.v1, scene_depth_, origin_->row, shape_.down);
    return part;
}

} // namespace game::ui
