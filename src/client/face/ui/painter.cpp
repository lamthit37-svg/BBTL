#include "ui/painter.hpp"

#include "core/error.hpp"
#include "gui/asset.hpp"
#include "gui/sheet.hpp"
#include "io/file.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"
#include "resource/tier.hpp"
#include "ui/text.hpp"
#include "ui/view.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <iterator>
#include <limits>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::ui {
namespace {

using Vertices = std::vector<render::UiVertex>;

// Số đỉnh gui::round_fan ghi cho hai tam giác liền nhau, và chỗ của đỉnh vành thứ ba trong đó.
constexpr std::size_t kFanPairVertices = 6;
constexpr std::size_t kFanThirdRim = 5;

// Toạ độ ảnh của bốn cạnh một quad.
struct UvBox {
    float left = 0.0F;
    float top = 0.0F;
    float right = 1.0F;
    float bottom = 1.0F;
};

[[nodiscard]] bool is_sized(const gui::Quad& quad) noexcept {
    return quad.dest.w > 0.0F && quad.dest.h > 0.0F;
}

// Cỡ một texture, điểm ảnh.
struct TextureSize {
    float width = 1.0F;
    float height = 1.0F;
};

// Ô nguồn của quad (điểm ảnh trong texture cỡ size) đổi sang toạ độ 0..1.
[[nodiscard]] UvBox source_uv(const gui::Quad& quad, TextureSize size) noexcept {
    UvBox texel;
    texel.left = quad.source.x / size.width;
    texel.top = quad.source.y / size.height;
    texel.right = (quad.source.x + quad.source.w) / size.width;
    texel.bottom = (quad.source.y + quad.source.h) / size.height;
    return texel;
}

// Bốn đỉnh theo thứ tự trên trái, trên phải, dưới phải, dưới trái.
void push_box(Vertices& out, const gui::Box& dest, const UvBox& texel, std::uint32_t colour) {
    const float right = dest.x + dest.w;
    const float bottom = dest.y + dest.h;
    const auto vertex = [colour](float across, float down, float u_at, float v_at) {
        return render::UiVertex{.x = across, .y = down, .u = u_at, .v = v_at, .colour = colour};
    };
    out.push_back(vertex(dest.x, dest.y, texel.left, texel.top));
    out.push_back(vertex(right, dest.y, texel.right, texel.top));
    out.push_back(vertex(right, bottom, texel.right, texel.bottom));
    out.push_back(vertex(dest.x, bottom, texel.left, texel.bottom));
}

// Hai tam giác liền nhau của quạt (tâm, vành a, vành b) và (tâm, vành b, vành c) thành một quad
// (tâm, a, b, c): chỉ số quad của UiPass là 0 1 2 rồi 0 2 3.
void push_fan_pair(Vertices& out, std::span<const gui::Fan> pair, std::uint32_t colour) {
    const auto vertex = [colour](const gui::Fan& fan) {
        return render::UiVertex{.x = fan.x, .y = fan.y, .u = fan.u, .v = fan.v, .colour = colour};
    };
    out.push_back(vertex(pair[0]));
    out.push_back(vertex(pair[1]));
    out.push_back(vertex(pair[2]));
    out.push_back(vertex(pair[kFanThirdRim]));
}

void push_fan(Vertices& out, const gui::Box& dest, const UvBox& texel, std::uint32_t colour) {
    const gui::FanView view{.dest = dest, .u0 = texel.left, .v0 = texel.top, .u1 = texel.right, .v1 = texel.bottom};
    std::array<gui::Fan, gui::kRoundCount> fan{};
    gui::round_fan(view, fan);
    const std::span<const gui::Fan> all(fan);
    for (std::size_t first = 0; first < gui::kRoundCount; first += kFanPairVertices) {
        push_fan_pair(out, all.subspan(first, kFanPairVertices), colour);
    }
}

// Quad chữ nhật hay quạt tròn của cùng một ô.
void push_shape(Vertices& out, const gui::Quad& quad, const UvBox& texel) {
    if (quad.is_round) {
        push_fan(out, quad.dest, texel, quad.colour);
        return;
    }
    push_box(out, quad.dest, texel, quad.colour);
}

[[nodiscard]] bool is_same_box(const render::UiRect& one, const render::UiRect& other) noexcept {
    const bool is_same_corner = one.x == other.x && one.y == other.y;
    return is_same_corner && one.width == other.width && one.height == other.height;
}

// Hai lô có cùng texture, cùng mặt nạ và cùng ô mặt nạ không (thì nối được thành một lệnh vẽ).
[[nodiscard]] bool is_same_state(const render::UiBatch& one, const render::UiBatch& other) noexcept {
    const bool is_same_image = one.texture == other.texture && one.mask == other.mask;
    return is_same_image && is_same_box(one.mask_box, other.mask_box);
}

// Số phần tử đầu của items cùng mang lớp layer.
template <typename Item>
[[nodiscard]] std::size_t run_length(std::span<const Item> items, std::uint16_t layer) noexcept {
    const auto is_other = [layer](const Item& item) { return item.layer != layer; };
    const auto stop = std::ranges::find_if(items, is_other);
    return static_cast<std::size_t>(std::distance(items.begin(), stop));
}

// Lớp của phần tử đầu, hay giá trị lớn nhất khi danh sách đã hết.
template <typename Item>
[[nodiscard]] std::uint16_t head_layer(std::span<const Item> items) noexcept {
    if (items.empty()) return std::numeric_limits<std::uint16_t>::max();
    return items.front().layer;
}

} // namespace

Painter::Painter(render::UiPass& pass, std::filesystem::path root) : pass_(&pass), root_(std::move(root)) {}

// Đọc đúng tệp Imagefile của imageset gốc (dds, tga, png, jpg) rồi đưa lên GPU. Không nối
// ".png" và không lấy bản ghép hay bản chữ tiếng Việt. Lỗi thì ghi một dòng và trả bản hỏng.
Painter::Loaded Painter::load(const std::string& name) {
    const std::filesystem::path file = root_ / io::path_from_utf8(name);
    const io::TextResult bytes = io::read_text(file);
    if (!bytes) {
        std::println(stderr, "Giao diện: không đọc được {}: {}", name, io::describe(bytes.error()));
        return {};
    }
    const auto raw = std::as_bytes(std::span(*bytes));
    const core::Result<resource::Image> image = resource::read_stored(raw);
    if (!image) {
        std::println(stderr, "Giao diện: ảnh {} hỏng: {}", name, image.error());
        return {};
    }
    const core::Result<std::uint32_t> id = pass_->add_texture(*image);
    if (!id) {
        std::println(stderr, "Giao diện: không tải được {} lên GPU: {}", name, id.error());
        return {};
    }
    const auto width = static_cast<float>(image->width);
    const auto height = static_cast<float>(image->height);
    return Loaded{.id = *id, .width = width, .height = height, .is_ok = true};
}

const Painter::Loaded& Painter::texture_of(const gui::GuiAsset& asset, std::int32_t index) {
    const std::string& name = asset.textures.at(static_cast<std::size_t>(index));
    const auto known = cache_.find(name);
    if (known != cache_.end()) return known->second;
    return cache_.emplace(name, load(name)).first->second;
}

// Các đỉnh thêm từ lúc mở thành một lô; nối vào lô cuối khi cùng texture và cùng mặt nạ.
void Painter::close_batch(Open open) {
    const auto first_quad = static_cast<std::uint32_t>(open.first_vertex / 4);
    const auto count = static_cast<std::uint32_t>((vertices_.size() - open.first_vertex) / 4);
    if (count == 0) return;
    render::UiBatch batch;
    batch.texture = open.texture;
    batch.first_quad = first_quad;
    batch.quad_count = count;
    batch.mask = open.mask;
    batch.mask_box = open.mask_box;
    if (!batches_.empty() && is_same_state(batches_.back(), batch)) {
        batches_.back().quad_count += count;
        return;
    }
    batches_.push_back(batch);
}

// Lô sẽ mở cho quad: đỉnh đầu là đỉnh kế tiếp, mặt nạ lấy của quad (tải texture mặt nạ khi cần).
// nullopt khi quad có mặt nạ mà texture mặt nạ không tải được: quad đó không vẽ, như renderer gốc
// bỏ batch thiếu mặt nạ.
std::optional<Painter::Open> Painter::open_for(const gui::GuiAsset& asset, const gui::Quad& quad) {
    Open open;
    open.first_vertex = vertices_.size();
    if (quad.mask < 0) return open;
    const Loaded& mask = texture_of(asset, quad.mask);
    if (!mask.is_ok) return std::nullopt;
    open.mask = mask.id;
    const gui::Box& box = quad.mask_box;
    open.mask_box = render::UiRect{.x = box.x, .y = box.y, .width = box.w, .height = box.h};
    return open;
}

void Painter::add_image(const gui::GuiAsset& asset, const gui::Quad& quad) {
    std::optional<Open> open = open_for(asset, quad);
    const bool is_solid = quad.texture < 0;
    const Loaded solid{.id = render::kUiWhite, .width = 1.0F, .height = 1.0F, .is_ok = true};
    const Loaded& texture = is_solid ? solid : texture_of(asset, quad.texture);
    if (!open || !texture.is_ok) {
        ++missing_;
        return;
    }
    const TextureSize size{.width = texture.width, .height = texture.height};
    const UvBox texel = is_solid ? UvBox{} : source_uv(quad, size);
    push_shape(vertices_, quad, texel);
    open->texture = texture.id;
    close_batch(*open);
}

void Painter::add_map(const gui::Quad& quad, const MapPaint& map) {
    const std::size_t first = vertices_.size();
    UvBox texel;
    texel.left = map.origin_u + (quad.u0 * map.scale_u);
    texel.top = map.origin_v + (quad.v0 * map.scale_v);
    texel.right = map.origin_u + (quad.u1 * map.scale_u);
    texel.bottom = map.origin_v + (quad.v1 * map.scale_v);
    push_shape(vertices_, quad, texel);
    close_batch({.texture = map.texture, .first_vertex = first});
}

// Ảnh của fake object quad.view, phủ cả texture. Chưa có ảnh (mô hình chưa dựng) thì không vẽ.
void Painter::add_view(const Job& job, const gui::Quad& quad) {
    const auto is_named = [&quad](const ViewPaint& view) { return view.name == quad.view; };
    const auto found = std::ranges::find_if(job.kit->views, is_named);
    std::optional<Open> open = open_for(*job.asset, quad);
    if (found == job.kit->views.end() || !open) return;
    const UvBox upright{};
    const UvBox flipped{.left = 0.0F, .top = 1.0F, .right = 1.0F, .bottom = 0.0F};
    push_shape(vertices_, quad, found->is_bottom_up ? flipped : upright);
    open->texture = found->texture;
    close_batch(*open);
}

void Painter::add_quad(const Job& job, const gui::Quad& quad) {
    if (!is_sized(quad)) return;
    if (quad.texture == gui::kMeshView) {
        add_view(job, quad);
        return;
    }
    if (quad.texture == gui::kSceneBoard) {
        if (job.kit->board) add_map(quad, *job.kit->board);
        return;
    }
    if (quad.texture == gui::kWorldBoard) {
        if (job.kit->world) add_map(quad, *job.kit->world);
        return;
    }
    if (quad.texture != gui::kSceneMap) {
        add_image(*job.asset, quad);
        return;
    }
    if (job.kit->map) add_map(quad, *job.kit->map);
}

void Painter::add_text(const Job& job, const gui::TextRun& run) {
    if (job.kit->writer == nullptr) return;
    // Phông Hán trước; run có chữ tiếng Việt có dấu mà phông Việt vẽ trọn được thì đổi phông cho cả run.
    bool is_alt = false;
    if (job.kit->alt_writer != nullptr) {
        is_alt = job.kit->writer->fit_of(run).has_vietnamese && job.kit->alt_writer->fit_of(run).unknown == 0;
    }
    TextWriter& writer = is_alt ? *job.kit->alt_writer : *job.kit->writer;
    const std::size_t first = vertices_.size();
    const std::optional<gui::Box> caret = writer.write(run, vertices_);
    close_batch({.texture = is_alt ? job.kit->alt_font_texture : job.kit->font_texture, .first_vertex = first});
    if (!caret) return;
    const std::size_t caret_first = vertices_.size();
    push_box(vertices_, *caret, UvBox{}, run.colour);
    close_batch({.texture = render::kUiWhite, .first_vertex = caret_first});
}

// Vẽ trọn lớp thấp nhất còn lại: ảnh tĩnh, ảnh động rồi chữ của nó.
void Painter::add_layer(const Job& job, Cursor& cursor) {
    const std::span<const gui::Quad> still = job.parts->still.subspan(cursor.still);
    const std::span<const gui::Quad> live = job.parts->live.subspan(cursor.live);
    const std::span<const gui::TextRun> texts = job.parts->texts.subspan(cursor.text);
    const std::uint16_t layer = std::min({head_layer(still), head_layer(live), head_layer(texts)});
    const std::size_t still_count = run_length(still, layer);
    const std::size_t live_count = run_length(live, layer);
    const std::size_t text_count = run_length(texts, layer);
    for (const gui::Quad& quad : still.first(still_count)) {
        add_quad(job, quad);
    }
    for (const gui::Quad& quad : live.first(live_count)) {
        add_quad(job, quad);
    }
    for (const gui::TextRun& run : texts.first(text_count)) {
        add_text(job, run);
    }
    cursor.still += still_count;
    cursor.live += live_count;
    cursor.text += text_count;
}

void Painter::build(const gui::GuiAsset& asset, const FrameParts& parts, const PaintKit& kit) {
    vertices_.clear();
    batches_.clear();
    const Job job{.asset = &asset, .parts = &parts, .kit = &kit};
    Cursor cursor;
    const std::size_t total = parts.still.size() + parts.live.size() + parts.texts.size();
    while (cursor.still + cursor.live + cursor.text < total) {
        add_layer(job, cursor);
    }
}

} // namespace game::ui
