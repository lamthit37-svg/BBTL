// Ra lệnh vẽ ảnh của dàn trang Falagard: khung (FrameComponent), ảnh (ImageryComponent), state của
// look (StateImagery, Layer, Section) và các bộ vẽ của nút, ô trơn, ô nhập, thanh và radar. Công
// thức chép từ CEGUI của _ref (FalagardButton, FalagardSuperProgress, FalagardSceneMap...).
// Nguồn: TLBB Dev src/gui/sheet.cpp@e0d89a6 (phần ảnh). Khác gốc: khung và căn lề viết thành hàm
// con theo luật độ lồng, cùng phép tính và thứ tự vẽ; layer đã sắp theo độ ưu tiên lúc nạp nên
// không sắp lại; radar vẽ mũi tên người chơi của FalagardRadar::updateMyselfDir (bản Dev chỉ có
// chấm vàng, giữ làm đường lui khi layout không nêu mũi tên); thêm Falagard/MapImage.
#include "gui/asset.hpp"
#include "gui/detail/draw.hpp"
#include "gui/detail/names.hpp"
#include "gui/detail/softkey.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::gui::detail {
namespace {

constexpr float kMarker = 8.0F;
constexpr std::uint32_t kMarkerColour = 0xFFFFFF00U;
// Loại của mũi tên chính người chơi trong thuộc tính AnimateImage của radar.
constexpr std::string_view kSelf = "Animate10";
constexpr std::size_t kLeftPart = 5;
constexpr std::size_t kRightPart = 6;
constexpr std::size_t kTopPart = 7;
constexpr std::size_t kBottomPart = 8;

// Kiểu căn của một trục; GuiHorz và GuiVert có cùng giá trị cho năm kiểu này.
enum class Align : std::uint8_t { kStart, kCentre, kEnd, kStretch, kTile };

Align align_of(std::uint8_t mode) noexcept {
    return static_cast<Align>(mode);
}

// index_in đổi tên ra chỉ số trong bảng tên, và chỉ số ấy đúng là giá trị Align mà align_of ép
// sang; tên lạ hay không có tên thì ra giá trị cố định.
constexpr FormatValue kTiledFormat{.name = "Tiled", .fixed = 0};
constexpr FormatValue kUnknownFormat{.name = "Lạ", .fixed = 3};
constexpr FormatValue kUnnamedFormat{.name = std::nullopt, .fixed = 2};
static_assert(kTiledFormat.index_in(kImageHorz) == std::to_underlying(Align::kTile));
static_assert(kTiledFormat.index_in(kImageVert) == std::to_underlying(Align::kTile));
static_assert(kUnknownFormat.index_in(kImageHorz) == kUnknownFormat.fixed);
static_assert(kUnnamedFormat.index_in(kImageHorz) == kUnnamedFormat.fixed);

void push_source(Sheet& sheet, std::int32_t texture, Box dest, Box source, std::uint32_t colour) {
    if (dest.w <= 0.0F || dest.h <= 0.0F) return;
    Quad quad;
    quad.texture = texture;
    quad.dest = dest;
    quad.source = source;
    quad.colour = colour;
    sheet.quads.push_back(quad);
}

// Ô đích trên màn hình, phần cắt của ảnh (gốc 0 trong ảnh) và màu.
struct ImagePlace {
    Box dest;
    Box crop;
    std::uint32_t colour = kWhiteArgb;
};

void push_image(Sheet& sheet, const GuiImage& image, const ImagePlace& place) {
    Box source;
    source.x = image.x + place.crop.x;
    source.y = image.y + place.crop.y;
    source.w = place.crop.w;
    source.h = place.crop.h;
    push_source(sheet, image.texture, place.dest, source, place.colour);
}

// Đoạn của vùng vẽ trên một trục: điểm đầu và độ dài.
struct Axis {
    float start = 0.0F;
    float span = 0.0F;
};

// Vị trí và độ dài của ảnh trên một trục sau khi căn.
struct Placement {
    float origin = 0.0F;
    float length = 0.0F;
};

Placement align_axis(Axis axis, float size, Align mode) noexcept {
    Placement placement{.origin = axis.start, .length = size};
    if (mode == Align::kStretch) placement.length = axis.span;
    if (mode == Align::kCentre) {
        placement.origin = axis.start + pixel_align((axis.span - size) * 0.5F);
    }
    if (mode == Align::kEnd) placement.origin = axis.start + axis.span - size;
    return placement;
}

// Lát ảnh

// Một ảnh, ô area mà nó phủ và màu nhân lên: phần chung của việc lát và việc căn.
struct ImageFill {
    const GuiImage* image = nullptr;
    Box area;
    std::uint32_t colour = kWhiteArgb;
};

// Một hàng ô lát: toạ độ dọc của hàng và số ô trên hàng.
struct TileRow {
    float down = 0.0F;
    unsigned columns = 0;
};

void emit_tile(Sheet& sheet, const ImageFill& fill, float across, float down) {
    const float remain_w = fill.area.x + fill.area.w - across;
    const float remain_h = fill.area.y + fill.area.h - down;
    if (remain_w <= 0.0F || remain_h <= 0.0F) return;
    const float width = std::min(fill.image->width, remain_w);
    const float height = std::min(fill.image->height, remain_h);
    const Box dest{.x = across, .y = down, .w = width, .h = height};
    const Box crop{.x = 0.0F, .y = 0.0F, .w = dest.w, .h = dest.h};
    push_image(sheet, *fill.image, ImagePlace{.dest = dest, .crop = crop, .colour = fill.colour});
}

void tile_row(Sheet& sheet, const ImageFill& fill, const TileRow& row) {
    for (unsigned column = 0; column < row.columns; ++column) {
        const float across = fill.area.x + (static_cast<float>(column) * fill.image->width);
        emit_tile(sheet, fill, across, row.down);
    }
}

void tile_image(Sheet& sheet, const ImageFill& fill) {
    if (fill.image->width <= 0.0F || fill.image->height <= 0.0F) return;
    const auto columns = static_cast<unsigned>(std::ceil(fill.area.w / fill.image->width));
    const auto rows = static_cast<unsigned>(std::ceil(fill.area.h / fill.image->height));
    for (unsigned row = 0; row < rows; ++row) {
        const float down = fill.area.y + (static_cast<float>(row) * fill.image->height);
        tile_row(sheet, fill, TileRow{.down = down, .columns = columns});
    }
}

// Một ảnh cần vẽ trong ô của nó với định dạng ngang và dọc của thành phần.
struct ImageJob {
    ImageFill fill;
    const GuiFormat* horz = nullptr;
    const GuiFormat* vert = nullptr;
};

void paint_image(const Ctx& ctx, const Placed& self, const ImageJob& job) {
    const GuiImage& image = *job.fill.image;
    const Box& area = job.fill.area;
    const FormatValue horz = format_value(ctx, self, *job.horz);
    const FormatValue vert = format_value(ctx, self, *job.vert);
    const Align horz_mode = align_of(horz.index_in(kImageHorz));
    const Align vert_mode = align_of(vert.index_in(kImageVert));
    if (horz_mode == Align::kTile || vert_mode == Align::kTile) {
        tile_image(*ctx.sheet, job.fill);
        return;
    }
    const Axis along{.start = area.x, .span = area.w};
    const Axis across_axis{.start = area.y, .span = area.h};
    const Placement across = align_axis(along, image.width, horz_mode);
    const Placement down = align_axis(across_axis, image.height, vert_mode);
    const Box dest{.x = across.origin, .y = down.origin, .w = across.length, .h = down.length};
    Box crop{.x = 0.0F, .y = 0.0F, .w = image.width, .h = image.height};
    if (horz_mode != Align::kStretch) crop.w = dest.w;
    if (vert_mode != Align::kStretch) crop.h = dest.h;
    push_image(*ctx.sheet, image, ImagePlace{.dest = dest, .crop = crop, .colour = job.fill.colour});
}

// Khung

// Chín ảnh của FrameComponent theo GuiFramePart; nullptr khi không có.
using FrameImages = std::array<const GuiImage*, 9>;

FrameImages frame_images(const Ctx& ctx, const GuiFrame& frame) noexcept {
    const auto image_of = [&ctx](std::int32_t index) { return image_at(*ctx.asset, index); };
    FrameImages images{};
    std::ranges::transform(frame.images, images.begin(), image_of);
    return images;
}

float width_of(const GuiImage* image) noexcept {
    return image == nullptr ? 0.0F : image->width;
}

float height_of(const GuiImage* image) noexcept {
    return image == nullptr ? 0.0F : image->height;
}

// Điểm bắt đầu và độ dài của các cạnh khung sau khi trừ bốn góc.
struct FrameSpans {
    float top_offset = 0.0F;
    float left_offset = 0.0F;
    float right_offset = 0.0F;
    float bottom_offset = 0.0F;
    float top_width = 0.0F;
    float bottom_width = 0.0F;
    float left_height = 0.0F;
    float right_height = 0.0F;
};

FrameSpans spans_of(const FrameImages& images, Box area) noexcept {
    const GuiImage* top_left = images.at(1);
    const GuiImage* top_right = images.at(2);
    const GuiImage* bottom_left = images.at(3);
    const GuiImage* bottom_right = images.at(4);
    FrameSpans spans;
    spans.top_offset = width_of(top_left);
    spans.left_offset = height_of(top_left);
    spans.right_offset = height_of(top_right);
    spans.bottom_offset = width_of(bottom_left);
    spans.top_width = area.w - spans.top_offset - width_of(top_right);
    spans.bottom_width = area.w - spans.bottom_offset - width_of(bottom_right);
    spans.left_height = area.h - spans.left_offset - height_of(bottom_left);
    spans.right_height = area.h - spans.right_offset - height_of(bottom_right);
    return spans;
}

// Ô của một ảnh nằm ở góc hay mép của area: gốc ở (across, down), cỡ bằng cỡ ảnh.
Box corner_box(float across, float down, const GuiImage* image) noexcept {
    return Box{.x = across, .y = down, .w = width_of(image), .h = height_of(image)};
}

// Ô đích của tám phần quanh nền, theo thứ tự GuiFramePart từ 1 tới 8: bốn góc, rồi mép trái, phải,
// trên, dưới. Mép đặt như góc (gốc và bề dày theo ảnh) rồi kéo dài theo cạnh tới hết phần giữa hai
// góc: mép trái, phải lấy chiều cao của spans, mép trên, dưới lấy chiều rộng.
std::array<Box, 8> frame_dests(const FrameImages& images, Box area) noexcept {
    const FrameSpans spans = spans_of(images, area);
    const float right = area.x + area.w;
    const float bottom = area.y + area.h;
    const GuiImage* top_right = images.at(2);
    const GuiImage* bottom_left = images.at(3);
    const GuiImage* bottom_right = images.at(4);
    const GuiImage* left = images.at(kLeftPart);
    const GuiImage* right_edge = images.at(kRightPart);
    const GuiImage* top = images.at(kTopPart);
    const GuiImage* bottom_edge = images.at(kBottomPart);
    std::array<Box, 8> dests{};
    dests.at(0) = corner_box(area.x, area.y, images.at(1));
    dests.at(1) = corner_box(right - width_of(top_right), area.y, top_right);
    dests.at(2) = corner_box(area.x, bottom - height_of(bottom_left), bottom_left);
    dests.at(3) = corner_box(right - width_of(bottom_right), bottom - height_of(bottom_right), bottom_right);
    dests.at(4) = corner_box(area.x, area.y + spans.left_offset, left);
    dests.at(5) = corner_box(right - width_of(right_edge), area.y + spans.right_offset, right_edge);
    dests.at(6) = corner_box(area.x + spans.top_offset, area.y, top);
    dests.at(7) = corner_box(area.x + spans.bottom_offset, bottom - height_of(bottom_edge), bottom_edge);
    dests.at(4).h = spans.left_height;
    dests.at(5).h = spans.right_height;
    dests.at(6).w = spans.top_width;
    dests.at(7).w = spans.bottom_width;
    return dests;
}

void paint_part(Sheet& sheet, const GuiImage* image, Box dest, std::uint32_t colour) {
    if (image == nullptr) return;
    push_whole(sheet, *image, dest, colour);
}

// Phần ruột của khung: ô còn lại sau khi trừ cạnh trên, dưới, trái, phải (kèm độ lệch của ảnh).
Box hole_of(const FrameImages& images, Box area) noexcept {
    const GuiImage* top = images.at(kTopPart);
    const GuiImage* bottom = images.at(kBottomPart);
    const GuiImage* left = images.at(kLeftPart);
    const GuiImage* right = images.at(kRightPart);
    Box hole = area;
    if (top != nullptr) hole.y += top->height + top->offset_y;
    if (top != nullptr) hole.h -= top->height + top->offset_y;
    if (bottom != nullptr) hole.h -= bottom->height - bottom->offset_y;
    if (left != nullptr) hole.x += left->width + left->offset_x;
    if (left != nullptr) hole.w -= left->width + left->offset_x;
    if (right != nullptr) hole.w -= right->width - right->offset_x;
    return hole;
}

void paint_frame(const Ctx& ctx, const Placed& self, const GuiFrame& frame, Box local, std::uint32_t colour) {
    const Box area = shift(area_box(ctx, self, frame.area, local), local);
    const FrameImages images = frame_images(ctx, frame);
    const std::array<Box, 8> dests = frame_dests(images, area);
    for (std::size_t part = 1; part < images.size(); ++part) {
        paint_part(*ctx.sheet, images.at(part), dests.at(part - 1), colour);
    }
    const GuiImage* back = images.at(0);
    if (back == nullptr) return;
    const ImageFill fill{.image = back, .area = hole_of(images, area), .colour = colour};
    const ImageJob job{.fill = fill, .horz = &frame.horz, .vert = &frame.vert};
    paint_image(ctx, self, job);
}

// Ảnh của ImageryComponent: ảnh cố định, hay ảnh tra theo tên trong thuộc tính của cửa sổ.
const GuiImage* imagery_image(const Ctx& ctx, const Placed& self, const GuiImagery& imagery) {
    if (imagery.image_property.empty()) return image_at(*ctx.asset, imagery.image);
    const auto text = effective(ctx, self, imagery.image_property);
    const auto name = text ? parse_image(*text) : std::nullopt;
    if (!name) return nullptr;
    return named_image(ctx, *name);
}

void paint_imagery(const Ctx& ctx, const Placed& self, const GuiImagery& imagery, Box local, std::uint32_t colour) {
    const GuiImage* image = imagery_image(ctx, self, imagery);
    if (image == nullptr) return;
    const Box area = shift(area_box(ctx, self, imagery.area, local), local);
    const ImageFill fill{.image = image, .area = area, .colour = colour};
    const ImageJob job{.fill = fill, .horz = &imagery.horz, .vert = &imagery.vert};
    paint_image(ctx, self, job);
}

void paint_frames(const Ctx& ctx, const Placed& self, const GuiSpec& spec, GuiRange frames, Box local) {
    if (!in_range(ctx.asset->frames.size(), frames)) return;
    const auto items = std::span(ctx.asset->frames).subspan(frames.first, frames.count);
    for (const GuiFrame& frame : items) {
        const std::uint32_t colour = tinted(spec, frame.colour);
        paint_frame(ctx, self, frame, local, colour);
    }
}

void paint_imageries(const Ctx& ctx, const Placed& self, const GuiSpec& spec, GuiRange imageries, Box local) {
    if (!in_range(ctx.asset->imageries.size(), imageries)) return;
    const auto items = std::span(ctx.asset->imageries).subspan(imageries.first, imageries.count);
    for (const GuiImagery& imagery : items) {
        const std::uint32_t colour = tinted(spec, imagery.colour);
        paint_imagery(ctx, self, imagery, local, colour);
    }
}

void render_section(const Ctx& ctx, const Placed& self, const GuiSpec& spec, Box local) {
    if (spec.section < 0) return;
    if (static_cast<std::size_t>(spec.section) >= ctx.asset->sections.size()) return;
    const GuiSection& section = ctx.asset->sections.at(static_cast<std::size_t>(spec.section));
    paint_frames(ctx, self, spec, section.frames, local);
    paint_imageries(ctx, self, spec, section.imageries, local);
}

void render_layer(const Ctx& ctx, const Placed& self, const GuiLayer& layer, Box local) {
    if (!in_range(ctx.asset->specs.size(), layer.specs)) return;
    const auto items = std::span(ctx.asset->specs).subspan(layer.specs.first, layer.specs.count);
    for (const GuiSpec& spec : items) {
        render_section(ctx, self, spec, local);
    }
}

// Vẽ các lớp của state; false khi khoảng lớp của state nằm ngoài asset.
bool render_layers(const Ctx& ctx, const Placed& self, const GuiState& state, Box local) {
    if (!in_range(ctx.asset->layers.size(), state.layers)) return false;
    const auto items = std::span(ctx.asset->layers).subspan(state.layers.first, state.layers.count);
    for (const GuiLayer& layer : items) {
        render_layer(ctx, self, layer, local);
    }
    return true;
}

// Ảnh của thuộc tính (NormalImage, Image...) kéo giãn cả cửa sổ.
void stretch_property(const Ctx& ctx, const Placed& self, std::string_view property) {
    const auto text = effective(ctx, self, property);
    const auto parsed = text ? parse_image(*text) : std::nullopt;
    if (!parsed) return;
    const GuiImage* image = named_image(ctx, *parsed);
    if (image == nullptr) return;
    push_whole(*ctx.sheet, *image, self.screen, kWhiteArgb);
}

// Mức vẽ của thanh: mức Hub đã trượt khi người gọi đặt thanh này, không thì CurrentProgress của
// cửa sổ (mặc định 1).
float bar_amount(const Ctx& ctx, const Placed& self) {
    const std::span<const Bar> bars = ctx.input->bars;
    const auto is_mine = [&self](const Bar& bar) { return bar.window == self.window->name; };
    const auto found = std::ranges::find_if(bars, is_mine);
    const auto slot = static_cast<std::size_t>(std::distance(bars.begin(), found));
    if (slot < ctx.bar_fills.size()) return std::clamp(ctx.bar_fills[slot], 0.0F, 1.0F);
    if (found != bars.end()) return std::clamp(found->amount, 0.0F, 1.0F);
    const auto text = effective(ctx, self, "CurrentProgress");
    const auto parsed = text ? parse_float(*text) : std::nullopt;
    return std::clamp(parsed.value_or(1.0F), 0.0F, 1.0F);
}

// Điểm trên màn hình của người chơi trong radar, kẹp trong ô radar.
struct Mark {
    float x = 0.0F;
    float y = 0.0F;
};

Mark radar_mark(const Box& screen, const Radar& view, const Place& input) noexcept {
    const float across = input.player_x / input.scene_width;
    const float down = input.player_z / input.scene_depth;
    const float span_u = view.u1 - view.u0;
    const float span_v = view.v1 - view.v0;
    Mark mark{.x = screen.x + (screen.w * 0.5F), .y = screen.y + (screen.h * 0.5F)};
    if (span_u != 0.0F) mark.x = screen.x + ((across - view.u0) / span_u * screen.w);
    if (span_v != 0.0F) mark.y = screen.y + ((down - view.v0) / span_v * screen.h);
    mark.x = std::clamp(mark.x, screen.x, screen.x + screen.w);
    mark.y = std::clamp(mark.y, screen.y, screen.y + screen.h);
    return mark;
}

// Ô rộng width cao height có tâm ở mark.
Box centred_box(Mark mark, float width, float height) noexcept {
    return Box{.x = mark.x - (width * 0.5F), .y = mark.y - (height * 0.5F), .w = width, .h = height};
}

const GuiAnimate* animate_named(const GuiAsset& asset, std::string_view name) noexcept {
    const auto is_named = [name](const GuiAnimate& animate) { return animate.name == name; };
    const auto found = std::ranges::find_if(asset.animates, is_named);
    return found == asset.animates.end() ? nullptr : &*found;
}

// Hoạt ảnh mũi tên của chính người chơi: thuộc tính AnimateImage mang type:Animate10
// (IMAGE_TYPE_MYSELF của bản 2026); nullptr khi layout không nêu hay bảng hoạt ảnh không có.
const GuiAnimate* self_arrow(const Ctx& ctx, const Placed& self) {
    const auto is_self = [](const GuiProperty& property) {
        return property.name == "AnimateImage" && tagged_value(property.value, "type:") == kSelf;
    };
    const std::span<const GuiProperty> properties = window_properties(*ctx.asset, self);
    const auto found = std::ranges::find_if(properties, is_self);
    if (found == properties.end()) return nullptr;
    const TagValue name = tagged_value(found->value, "animate:");
    return name ? animate_named(*ctx.asset, *name) : nullptr;
}

// Ảnh của khung thứ slot trong hoạt ảnh; nullptr khi ngoài dãy.
const GuiImage* frame_image(const GuiAsset& asset, const GuiAnimate& animate, std::size_t slot) {
    const bool is_inside = in_range(asset.animate_frames.size(), animate.frames);
    if (!is_inside || slot >= animate.frames.count) return nullptr;
    return image_at(asset, asset.animate_frames.at(animate.frames.first + slot));
}

// Phần của ô đích (cùng phần ảnh tương ứng) nằm trong ô clip; ô đích rỗng khi không giao nhau.
ImagePlace clipped(const ImagePlace& place, const Box& clip) noexcept {
    const float left = std::max(place.dest.x, clip.x);
    const float top = std::max(place.dest.y, clip.y);
    const float right = std::min(place.dest.x + place.dest.w, clip.x + clip.w);
    const float bottom = std::min(place.dest.y + place.dest.h, clip.y + clip.h);
    ImagePlace out = place;
    out.dest = Box{.x = left, .y = top, .w = right - left, .h = bottom - top};
    if (out.dest.w <= 0.0F || out.dest.h <= 0.0F) return out;
    const float scale_x = place.crop.w / place.dest.w;
    const float scale_y = place.crop.h / place.dest.h;
    out.crop.x = place.crop.x + ((left - place.dest.x) * scale_x);
    out.crop.y = place.crop.y + ((top - place.dest.y) * scale_y);
    out.crop.w = out.dest.w * scale_x;
    out.crop.h = out.dest.h * scale_y;
    return out;
}

// Mũi tên người chơi: ảnh của khung theo hướng mặt, cỡ gốc của ảnh, tâm ở mark, cắt theo ô radar
// (cửa sổ mũi tên của bản gốc là con của radar). false khi không có mũi tên để vẽ.
bool draw_arrow(const Ctx& ctx, const Placed& self, Mark mark) {
    const GuiAnimate* arrow = self_arrow(ctx, self);
    if (arrow == nullptr) return false;
    const ArrowTurn turn{.facing = ctx.input->player_facing, .frames = arrow->frames.count};
    const std::size_t slot = arrow_frame(turn);
    const GuiImage* image = frame_image(*ctx.asset, *arrow, slot);
    if (image == nullptr) return false;
    // Đặt vào điểm ảnh nguyên cho nét. Làm tròn xuống chứ không dùng pixel_align: góc trái trên có
    // thể âm khi người chơi đứng sát mép cảnh, mà pixel_align cắt số âm về phía 0.
    Box dest = centred_box(mark, image->width, image->height);
    dest.x = std::floor(dest.x + 0.5F);
    dest.y = std::floor(dest.y + 0.5F);
    const Box crop{.x = 0.0F, .y = 0.0F, .w = image->width, .h = image->height};
    const ImagePlace whole{.dest = dest, .crop = crop, .colour = kWhiteArgb};
    push_image(*ctx.sheet, *image, clipped(whole, self.screen));
    return true;
}

// Số liệu radar_uv cần: cỡ cảnh và chỗ người chơi của input, cỡ của cửa sổ radar screen.
RadarAsk radar_ask(const Place& input, const Box& screen) noexcept {
    RadarAsk ask;
    ask.scene_width = input.scene_width;
    ask.scene_depth = input.scene_depth;
    ask.window_width = screen.w;
    ask.window_height = screen.h;
    ask.player_x = input.player_x;
    ask.player_z = input.player_z;
    return ask;
}

// Hai số "a b" của một thuộc tính bản đồ lớn (SceneMapSize, SceneMapCenter); thiếu hay hỏng thì nullopt.
struct FloatPair {
    float first = 0.0F;
    float second = 0.0F;
};

std::optional<FloatPair> pair_of(std::optional<std::string_view> text) {
    if (!text) return std::nullopt;
    const std::size_t space = text->find(' ');
    if (space == std::string_view::npos) return std::nullopt;
    const std::optional<float> first = parse_float(text->substr(0, space));
    const std::optional<float> second = parse_float(text->substr(space + 1));
    if (!first || !second) return std::nullopt;
    return FloatPair{.first = *first, .second = *second};
}

// Bản đồ lớn (cửa sổ radar mang SceneMapZoom): chế độ phóng, cỡ cảnh đang vẽ và tâm do bảng đặt qua Override,
// vì cảnh đang xem có thể không phải cảnh người chơi đứng. SceneMapSelf bật thì có mũi tên người chơi.
// Ảnh nền vẽ ở trang tĩnh để các nút con (SceneMap_Move nằm trên bản đồ) đè lên được; mũi tên và số liệu
// cho bảng nằm ở trang động vì chúng đi theo người chơi.
void draw_board(const Ctx& ctx, const Placed& self, std::string_view zoom) {
    if (ctx.is_live_pass) ctx.sheet->board = self.screen;
    const std::optional<float> mode = parse_float(zoom);
    const std::optional<FloatPair> size = pair_of(effective(ctx, self, "SceneMapSize"));
    if (!mode || !size) return;
    const std::optional<FloatPair> centre = pair_of(effective(ctx, self, "SceneMapCenter"));
    BoardAsk ask;
    ask.scene_width = size->first;
    ask.scene_depth = size->second;
    ask.window_width = self.screen.w;
    ask.window_height = self.screen.h;
    ask.mode = static_cast<std::int32_t>(*mode);
    ask.centre_x = centre ? centre->first : size->first * 0.5F;
    ask.centre_z = centre ? centre->second : size->second * 0.5F;
    const BoardView view = board_view(ask);
    if (view.pixels <= 0.0F) return;
    const Box dest{
        .x = self.screen.x + view.dest.x, .y = self.screen.y + view.dest.y, .w = view.dest.w, .h = view.dest.h};
    if (ctx.is_live_pass) {
        ctx.sheet->board_dest = dest;
        ctx.sheet->board_uv = view.uv;
        if (!flag(ctx, self, "SceneMapSelf")) return;
        const Mark mark = radar_mark(dest, view.uv, *ctx.input);
        if (draw_arrow(ctx, self, mark)) return;
        push_source(*ctx.sheet, kSolid, centred_box(mark, kMarker, kMarker), {}, kMarkerColour);
        return;
    }
    Quad map;
    map.texture = kSceneBoard;
    map.dest = dest;
    map.u0 = view.uv.u0;
    map.v0 = view.uv.v0;
    map.u1 = view.uv.u1;
    map.v1 = view.uv.v1;
    ctx.sheet->quads.push_back(map);
}

void draw_radar(const Ctx& ctx, const Placed& self) {
    if (const auto zoom = effective(ctx, self, "SceneMapZoom")) {
        draw_board(ctx, self, *zoom);
        return;
    }
    ctx.sheet->radar = self.screen;
    const Place& input = *ctx.input;
    if (input.scene_width <= 0.0F || input.scene_depth <= 0.0F) return;
    const RadarAsk ask = radar_ask(input, self.screen);
    const Radar view = radar_uv(ask);
    ctx.sheet->uv = view;
    Quad map;
    map.texture = kSceneMap;
    map.dest = self.screen;
    map.u0 = view.u0;
    map.v0 = view.v0;
    map.u1 = view.u1;
    map.v1 = view.v1;
    const auto round = effective(ctx, self, "RoundEnabled");
    map.is_round = round && parse_bool(*round);
    ctx.sheet->quads.push_back(map);
    const Mark mark = radar_mark(self.screen, view, input);
    if (draw_arrow(ctx, self, mark)) return;
    push_source(*ctx.sheet, kSolid, centred_box(mark, kMarker, kMarker), {}, kMarkerColour);
}

std::string_view button_state(const Ctx& ctx, const Placed& self) {
    if (flag(ctx, self, "Disabled")) return "Disabled";
    const bool is_hot = ctx.hot == &self;
    if (is_hot && ctx.is_down) return "Pushed";
    // FalagardCheckButton::drawSelf: đang chọn mà không bị nhấn thì vẽ như Pushed.
    if (self.kind == Kind::kCheck && flag(ctx, self, "Selected")) return "Pushed";
    if (is_hot) return "Hover";
    return "Normal";
}

std::string_view button_image(std::string_view state) noexcept {
    if (state == "Pushed") return "PushedImage";
    if (state == "Hover") return "HoverImage";
    return "NormalImage";
}

void draw_button(const Ctx& ctx, const Placed& self) {
    // Nền ô ActionBK. Khác gốc: drawSelf không gọi.
    render_state(ctx, self, "BackgroundImage", self.screen);
    const GuiState* state = button_look_state(ctx, self);
    if (state != nullptr) render_layers(ctx, self, *state, self.screen);
    const std::string_view image = button_image(button_state(ctx, self));
    const bool has_image = effective(ctx, self, image).has_value();
    stretch_property(ctx, self, has_image ? image : std::string_view("NormalImage"));
}

void draw_plain(const Ctx& ctx, const Placed& self) {
    stretch_property(ctx, self, "Image");
    const auto frame = effective(ctx, self, "FrameEnabled");
    const auto background = effective(ctx, self, "BackgroundEnabled");
    if (frame && parse_bool(*frame)) render_state(ctx, self, "EnabledFrame", self.screen);
    if (background && parse_bool(*background)) {
        render_state(ctx, self, "EnabledBackground", self.screen);
    }
    render_state(ctx, self, "Enabled", self.screen);
}

// Ảnh con mang tên name trong các thuộc tính ChildImage "name:<tên> set:<bộ> image:<ảnh>".
const GuiImage* child_image(const Ctx& ctx, const Placed& self, std::string_view name) {
    const auto is_named = [name](const GuiProperty& property) {
        return property.name == "ChildImage" && tagged_value(property.value, "name:") == name;
    };
    const std::span<const GuiProperty> properties = window_properties(*ctx.asset, self);
    const auto found = std::ranges::find_if(properties, is_named);
    if (found == properties.end()) return nullptr;
    const std::optional<ImageName> parsed = tagged_image(found->value);
    return parsed ? named_image(ctx, *parsed) : nullptr;
}

// Falagard/MapImage của client 2026 (không có mã nguồn; suy từ layout và script): ảnh tĩnh kèm
// bảng ảnh con, script chọn một ảnh bằng SetProperty("SetCurrentImage", tên). Chưa chọn hay tên lạ
// thì vẽ như ảnh tĩnh (thuộc tính Image).
void draw_map_image(const Ctx& ctx, const Placed& self) {
    const auto chosen = effective(ctx, self, "SetCurrentImage");
    const GuiImage* image = chosen ? child_image(ctx, self, *chosen) : nullptr;
    if (image == nullptr) {
        draw_plain(ctx, self);
        return;
    }
    push_whole(*ctx.sheet, *image, self.screen, kWhiteArgb);
}

// Quad mô hình: ô cửa sổ làm tròn về điểm ảnh nguyên như Imageset::draw, tên fake object để bộ vẽ
// lấy texture đã dựng.
void push_mesh_view(const Ctx& ctx, const Placed& self, std::string_view name) {
    const float right = pixel_align(self.screen.x + self.screen.w);
    const float bottom = pixel_align(self.screen.y + self.screen.h);
    Quad quad;
    quad.texture = kMeshView;
    quad.dest.x = pixel_align(self.screen.x);
    quad.dest.y = pixel_align(self.screen.y);
    quad.dest.w = right - quad.dest.x;
    quad.dest.h = bottom - quad.dest.y;
    quad.view = name;
    if (quad.dest.w <= 0.0F || quad.dest.h <= 0.0F) return;
    ctx.sheet->quads.push_back(quad);
}

// FalagardMeshWindow::populateRenderCache kéo giãn d_image kín cửa sổ. Có FakeObject thì quad là
// ảnh đầu 3D (bộ vẽ tìm theo tên). Không có thì vẽ thuộc tính Image: chân dung 2D thế chỗ texture
// mà FakeObj_Show gán. Cha MaskHost nhân mặt nạ HeadRoundRegion lên quad này.
void draw_mesh(const Ctx& ctx, const Placed& self) {
    const auto name = effective(ctx, self, "FakeObject");
    if (name && !name->empty()) {
        push_mesh_view(ctx, self, *name);
        return;
    }
    stretch_property(ctx, self, "Image");
}

// FalagardEditbox::populateRenderCache vẽ Enabled; look của kho 2026 chỉ có Normal.
void draw_edit(const Ctx& ctx, const Placed& self) {
    if (render_state(ctx, self, "Enabled", self.screen)) return;
    render_state(ctx, self, "Normal", self.screen);
}

void draw_progress(const Ctx& ctx, const Placed& self) {
    Box local = self.screen;
    local.w *= bar_amount(ctx, self);
    render_state(ctx, self, "Enabled", local);
}

} // namespace

bool render_state(const Ctx& ctx, const Placed& self, std::string_view name, Box local) {
    if (self.look == nullptr) return false;
    const GuiState* state = state_named(*ctx.asset, *self.look, name);
    return state != nullptr && render_layers(ctx, self, *state, local);
}

void clip_quads(Sheet& sheet, std::size_t first, const Box& clip) {
    const auto cut = [&clip](Quad& quad) {
        const ImagePlace whole{.dest = quad.dest, .crop = quad.source, .colour = quad.colour};
        const ImagePlace part = clipped(whole, clip);
        quad.dest = part.dest;
        quad.source = part.crop;
    };
    const auto tail = std::span(sheet.quads).subspan(std::min(first, sheet.quads.size()));
    std::ranges::for_each(tail, cut);
    const auto is_empty = [](const Quad& quad) { return quad.dest.w <= 0.0F || quad.dest.h <= 0.0F; };
    const auto gone = std::ranges::remove_if(tail, is_empty);
    const auto kept = static_cast<std::size_t>(std::distance(sheet.quads.data(), gone.data()));
    sheet.quads.resize(kept);
}

Box shift(Box local, Box origin) noexcept {
    local.x += origin.x;
    local.y += origin.y;
    return local;
}

std::uint32_t colour_of(const GuiColourSource& source) noexcept {
    return source.colours.at(0);
}

std::uint32_t tinted(const GuiSpec& spec, const GuiColourSource& part) noexcept {
    const std::uint32_t own = colour_of(part);
    return spec.overrides ? modulate(own, colour_of(spec.colour)) : own;
}

// FalagardButton::doButtonRender: look không có state của trạng thái đang có thì vẽ Normal, không
// có cả Normal thì không vẽ gì.
const GuiState* button_look_state(const Ctx& ctx, const Placed& self) {
    if (self.look == nullptr) return nullptr;
    const GuiState* wanted = state_named(*ctx.asset, *self.look, button_state(ctx, self));
    return wanted != nullptr ? wanted : state_named(*ctx.asset, *self.look, "Normal");
}

FormatValue format_value(const Ctx& ctx, const Placed& self, const GuiFormat& format) {
    FormatValue read;
    read.fixed = format.value;
    if (!format.property.empty()) read.name = effective(ctx, self, format.property);
    return read;
}

void push_whole(Sheet& sheet, const GuiImage& image, Box dest, std::uint32_t colour) {
    const Box crop{.x = 0.0F, .y = 0.0F, .w = image.width, .h = image.height};
    push_image(sheet, image, ImagePlace{.dest = dest, .crop = crop, .colour = colour});
}

const GuiImage* named_image(const Ctx& ctx, const ImageName& name) {
    if (ctx.images == nullptr) return nullptr;
    const std::string key = std::format("{}/{}", name.set, name.image);
    const auto found = ctx.images->find(key);
    if (found == ctx.images->end()) return nullptr;
    return image_at(*ctx.asset, found->second);
}

const GuiState* state_named(const GuiAsset& asset, const GuiLook& look, std::string_view name) {
    if (!in_range(asset.states.size(), look.states)) return nullptr;
    const auto items = std::span(asset.states).subspan(look.states.first, look.states.count);
    const auto matches = [name](const GuiState& state) { return state.name == name; };
    const auto found = std::ranges::find_if(items, matches);
    return found == items.end() ? nullptr : &*found;
}

namespace {

// Một thành phố của WorldMapCities: id, chỗ nút, chỗ nhãn, loại nút và ảnh nhãn.
struct WorldCity {
    int id = 0;
    FloatPair icon;
    FloatPair label;
    std::string_view sign;
    ImageName name;
    // Tên đã dịch (rỗng thì vẽ ảnh nhãn của bản gốc) và sắc của nhãn.
    std::string_view title;
    bool is_red = false;
};

// Ô thứ index của dòng tách bằng dấu tab; rỗng khi dòng ngắn hơn.
std::string_view tab_field(std::string_view line, std::size_t index) noexcept {
    for (std::size_t skipped = 0; skipped < index; ++skipped) {
        const std::size_t tab = line.find('\t');
        if (tab == std::string_view::npos) return {};
        line.remove_prefix(tab + 1);
    }
    return line.substr(0, line.find('\t'));
}

std::optional<WorldCity> parse_city(std::string_view line) {
    const std::optional<float> id = parse_float(tab_field(line, 0));
    const std::optional<float> icon_x = parse_float(tab_field(line, 1));
    const std::optional<float> icon_y = parse_float(tab_field(line, 2));
    const std::optional<float> label_x = parse_float(tab_field(line, 3));
    const std::optional<float> label_y = parse_float(tab_field(line, 4));
    if (!id || !icon_x || !icon_y || !label_x || !label_y) return std::nullopt;
    WorldCity city;
    city.id = static_cast<int>(*id);
    city.icon = FloatPair{.first = *icon_x, .second = *icon_y};
    city.label = FloatPair{.first = *label_x, .second = *label_y};
    city.sign = tab_field(line, 5);
    city.name = ImageName{.set = tab_field(line, 6), .image = tab_field(line, 7)};
    city.title = tab_field(line, 8);
    city.is_red = tab_field(line, 9) == "red";
    return city;
}

// Ảnh CityImageNormal hay CityImageHover của loại nút sign ("type:Sign5 set:... image:...").
const GuiImage* sign_image(const Ctx& ctx, const Placed& self, std::string_view property, std::string_view sign) {
    const auto is_sign = [property, sign](const GuiProperty& item) {
        return item.name == property && tagged_value(item.value, "type:") == sign;
    };
    const std::span<const GuiProperty> properties = window_properties(*ctx.asset, self);
    const auto found = std::ranges::find_if(properties, is_sign);
    if (found == properties.end()) return nullptr;
    const std::optional<ImageName> parsed = tagged_image(found->value);
    return parsed ? named_image(ctx, *parsed) : nullptr;
}

// Ô của ảnh có tâm ở point (HookMode Center của FalagardWorldMap::createNewCity), cỡ gốc của ảnh.
Box centred_image_box(const GuiImage& image, FloatPair point) noexcept {
    return Box{.x = point.first - (image.width * 0.5F),
        .y = point.second - (image.height * 0.5F),
        .w = image.width,
        .h = image.height};
}

Box overlap(const Box& first, const Box& second) noexcept {
    const float left = std::max(first.x, second.x);
    const float top = std::max(first.y, second.y);
    const float right = std::min(first.x + first.w, second.x + second.w);
    const float bottom = std::min(first.y + first.h, second.y + second.h);
    return Box{.x = left, .y = top, .w = std::max(right - left, 0.0F), .h = std::max(bottom - top, 0.0F)};
}

// Ước lượng bề rộng nhãn chữ (số ký tự UTF-8 nhân bề rộng trung bình của chữ 14 điểm ảnh) và cao một dòng của phông
// Việt.
constexpr float kLabelGlyph = 8.0F;
constexpr float kLabelPad = 6.0F;
constexpr float kLabelHeight = 18.0F;
// Màu thẻ #e (viền sáng) và #c (chữ đen, đỏ của phó bản) của nhãn chữ; GuiTextHorz và GuiTextVert canh giữa.
constexpr std::string_view kLabelHalo = "F4EBC8";
constexpr std::string_view kLabelInk = "201810";
constexpr std::string_view kLabelRed = "C01818";
constexpr std::uint8_t kLabelHorz = 2;
constexpr std::uint8_t kLabelVert = 1;

[[nodiscard]] float utf8_length(std::string_view text) noexcept {
    return static_cast<float>(std::ranges::count_if(text,
        [](char byte) { return (static_cast<unsigned char>(byte) & 0xC0U) != 0x80U; }));
}

// Ô của nhãn chữ: tâm ở chỗ nhãn của thành phố (HookMode Center như ảnh nhãn), bề rộng theo số ký tự.
[[nodiscard]] Box label_box(const WorldCity& city, FloatPair origin) noexcept {
    const float width = (utf8_length(city.title) * kLabelGlyph) + (2.0F * kLabelPad);
    return Box{.x = origin.first + city.label.first - (width * 0.5F),
        .y = origin.second + city.label.second - (kLabelHeight * 0.5F),
        .w = width,
        .h = kLabelHeight};
}

// Một thành phố theo createNewCity và resetWorldMap (CEGUIFalagard.dll 0x18008c320, 0x18008dd50): ảnh
// nhãn (bản gốc luôn đặt ảnh "khi trỏ" lên cửa sổ nhãn, cả khi không trỏ), ảnh nút (thường hay khi trỏ),
// rồi dấu MySelf ở chỗ nút nếu đây là cảnh người chơi đang đứng. Nút và nhãn đều bấm được.
void draw_city(const Ctx& ctx, const Placed& self, const WorldCity& city, FloatPair origin) {
    Sheet& sheet = *ctx.sheet;
    const auto shift = [origin](FloatPair point) {
        return FloatPair{.first = origin.first + point.first, .second = origin.second + point.second};
    };
    const std::optional<float> hovered =
        parse_float(effective(ctx, self, "WorldMapHover").value_or(std::string_view{}));
    const std::optional<float> mine = parse_float(effective(ctx, self, "WorldMapSelf").value_or(std::string_view{}));
    const bool is_hovered = hovered && static_cast<int>(*hovered) == city.id;
    const auto hit = [&](const GuiImage& image, FloatPair at) {
        const Box box = centred_image_box(image, shift(at));
        push_whole(sheet, image, box, kWhiteArgb);
        const Box seen = overlap(box, self.screen);
        if (seen.w > 0.0F && seen.h > 0.0F) sheet.world_hits.push_back(WorldHit{.city = city.id, .box = seen});
    };
    if (!city.title.empty()) {
        const Box box = label_box(city, origin);
        const Box seen = overlap(box, self.screen);
        if (seen.w > 0.0F && seen.h > 0.0F) sheet.world_hits.push_back(WorldHit{.city = city.id, .box = seen});
    } else if (const GuiImage* label = named_image(ctx, city.name)) {
        hit(*label, city.label);
    }
    if (const GuiImage* icon = sign_image(ctx, self, is_hovered ? "CityImageHover" : "CityImageNormal", city.sign))
        hit(*icon, city.icon);
    if (!mine || static_cast<int>(*mine) != city.id) return;
    const auto text = effective(ctx, self, "MySelfImage");
    const std::optional<ImageName> name = text ? parse_image(*text) : std::nullopt;
    const GuiImage* marker = name ? named_image(ctx, *name) : nullptr;
    if (marker != nullptr) push_whole(sheet, *marker, centred_image_box(*marker, shift(city.icon)), kWhiteArgb);
}

} // namespace

// Falagard/WorldMap (CEGUIFalagard.dll 0x18008b200 createBackground, 0x18008ea20 updataBackground):
// ảnh nền ghép từ lưới ô, đặt trong cửa sổ theo độ lệch WorldMapView (điểm ảnh, đã kẹp), kèm các thành phố
// ở WorldMapCities (mỗi dòng: id, nút x y, nhãn x y, loại nút, bộ ảnh và ảnh của nhãn, cách nhau bằng tab).
// Khác gốc: cuộn và kẹp làm ở ui/panel/world_map; chưa có tooltip, bạn bè, đối địch, cờ chỉ huy.
void draw_world(const Ctx& ctx, const Placed& self) {
    draw_plain(ctx, self);
    if (ctx.is_live_pass) return;
    Sheet& sheet = *ctx.sheet;
    sheet.world = self.screen;
    const std::optional<FloatPair> size = pair_of(effective(ctx, self, "WorldMapSize"));
    const std::optional<FloatPair> offset = pair_of(effective(ctx, self, "WorldMapView"));
    if (!size || !offset || size->first <= 0.0F || size->second <= 0.0F) return;
    const Box whole{
        .x = self.screen.x + offset->first, .y = self.screen.y + offset->second, .w = size->first, .h = size->second};
    const Box shown = overlap(whole, self.screen);
    if (shown.w > 0.0F && shown.h > 0.0F) {
        Quad map;
        map.texture = kWorldBoard;
        map.dest = shown;
        map.u0 = (shown.x - whole.x) / whole.w;
        map.v0 = (shown.y - whole.y) / whole.h;
        map.u1 = (shown.x + shown.w - whole.x) / whole.w;
        map.v1 = (shown.y + shown.h - whole.y) / whole.h;
        sheet.quads.push_back(map);
    }
    const std::size_t first = sheet.quads.size();
    std::string_view rest = effective(ctx, self, "WorldMapCities").value_or(std::string_view{});
    while (!rest.empty()) {
        const std::size_t end = rest.find('\n');
        const std::string_view line = rest.substr(0, end);
        rest.remove_prefix(end == std::string_view::npos ? rest.size() : end + 1);
        if (const std::optional<WorldCity> city = parse_city(line))
            draw_city(ctx, self, *city, FloatPair{.first = whole.x, .second = whole.y});
    }
    clip_quads(sheet, first, self.screen);
}

namespace {

// Gốc ảnh nền của bản đồ thế giới trên màn hình (WorldMapView là độ lệch so với góc cửa sổ).
std::optional<FloatPair> world_origin(const Ctx& ctx, const Placed& self) {
    const std::optional<FloatPair> offset = pair_of(effective(ctx, self, "WorldMapView"));
    if (!offset) return std::nullopt;
    return FloatPair{.first = self.screen.x + offset->first, .second = self.screen.y + offset->second};
}

} // namespace

// Tên đã dịch của các thành phố, chữ đen (đỏ với phó bản) viền sáng như nhãn gốc, canh giữa quanh chỗ nhãn.
// Chuỗi dựng lúc chạy nằm ở Sheet::made để TextRun mượn.
void world_texts(const Ctx& ctx, const Placed& self) {
    const std::optional<FloatPair> origin = world_origin(ctx, self);
    if (!origin) return;
    std::string_view rest = effective(ctx, self, "WorldMapCities").value_or(std::string_view{});
    while (!rest.empty()) {
        const std::size_t end = rest.find('\n');
        const std::string_view line = rest.substr(0, end);
        rest.remove_prefix(end == std::string_view::npos ? rest.size() : end + 1);
        const std::optional<WorldCity> city = parse_city(line);
        if (!city || city->title.empty()) continue;
        const Box box = label_box(*city, *origin);
        if (overlap(box, self.screen).w <= 0.0F) continue;
        ctx.sheet->made.push_back(std::format("#e{}#c{}{}", kLabelHalo, city->is_red ? kLabelRed : kLabelInk,
            city->title));
        TextRun run;
        run.text = ctx.sheet->made.back();
        run.box = box;
        run.clip = self.screen;
        run.rule = TextRule::kSimpleText;
        run.horz = kLabelHorz;
        run.vert = kLabelVert;
        ctx.sheet->texts.push_back(run);
    }
}

void draw_images(const Ctx& ctx, const Placed& self) {
    if (self.kind == Kind::kWorld) {
        draw_world(ctx, self);
    } else if (self.kind == Kind::kRadar) {
        draw_radar(ctx, self);
    } else if (self.kind == Kind::kProgress) {
        draw_progress(ctx, self);
    } else if (self.kind == Kind::kAction) {
        draw_action(ctx, self);
    } else if (self.kind == Kind::kList) {
        draw_list(ctx, self);
    } else if (self.kind == Kind::kComplex) {
        draw_complex(ctx, self);
    } else if (self.kind == Kind::kCatalog) {
        draw_catalog(ctx, self);
    } else if (self.kind == Kind::kMoney) {
        draw_plain(ctx, self);
        draw_money(ctx, self);
    } else if (is_pressable(self.kind)) {
        draw_button(ctx, self);
    } else if (self.kind == Kind::kEdit) {
        draw_edit(ctx, self);
    } else if (self.kind == Kind::kMapImage) {
        draw_map_image(ctx, self);
    } else if (self.kind == Kind::kMesh) {
        draw_mesh(ctx, self);
    } else if (self.kind == Kind::kSoftKeys) {
        draw_soft_keys(ctx, self);
    } else {
        draw_plain(ctx, self);
    }
}

} // namespace game::gui::detail
