/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/painter.cpp
 *  PHÂN HỆ   : Client / UI
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đưa quad giao diện lên lượt vẽ 2D.
 *  - PNG vá chỉ thay ảnh gốc khi cùng cỡ, kẻo toạ độ imageset kẹp thành một
 *    màu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <iterator>
#include <limits>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
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

// Ô theo điểm ảnh của layout đổi sang điểm ảnh của màn (nhân scale).
gui::Box shrink(const gui::Box& box, float scale) {
    return gui::Box{.x = box.x * scale, .y = box.y * scale, .w = box.w * scale, .h = box.h * scale};
}

// Ngược lại: ô theo điểm ảnh của màn đổi về điểm ảnh của layout.
gui::Box grow(const gui::Box& box, float scale) {
    return gui::Box{.x = box.x / scale, .y = box.y / scale, .w = box.w / scale, .h = box.h / scale};
}

// Đỉnh theo điểm ảnh của màn đổi về điểm ảnh của layout. Dính vào lưới điểm ảnh của màn trước: mép nằm lệch nửa
// điểm ảnh làm chữ và đường kẻ nhoè.
void expand(std::span<render::UiVertex> vertices, float scale) {
    for (render::UiVertex& vertex : vertices) {
        vertex.x = std::round(vertex.x) / scale;
        vertex.y = std::round(vertex.y) / scale;
    }
}

// Quad ảnh và màu đặc theo điểm ảnh của layout: dính vào lưới điểm ảnh của màn. Chữ đã dính sẵn nên đi qua đây không đổi.
void snap(std::span<render::UiVertex> vertices, float scale) {
    for (render::UiVertex& vertex : vertices) {
        vertex.x = std::round(vertex.x * scale) / scale;
        vertex.y = std::round(vertex.y * scale) / scale;
    }
}

// Cỡ ảnh đọc từ đầu tệp. Ảnh ghép hỏng (CommonFrame.tga.png 188x63 cạnh TGA 256x256) không được
// thay: toạ độ PaoPao_BK nằm ngoài tấm nhỏ, sampler kẹp vào ô xanh và lát kín bảng chọn máy chủ.
struct Extent {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    friend constexpr bool operator==(const Extent&, const Extent&) = default;
};

[[nodiscard]] std::uint8_t byte_at(std::span<const std::byte> bytes, std::size_t index) noexcept {
    return std::to_integer<std::uint8_t>(bytes[index]);
}

[[nodiscard]] std::uint32_t le32(std::span<const std::byte> bytes, std::size_t at) noexcept {
    const std::uint32_t b0 = byte_at(bytes, at);
    const std::uint32_t b1 = byte_at(bytes, at + 1U);
    const std::uint32_t b2 = byte_at(bytes, at + 2U);
    const std::uint32_t b3 = byte_at(bytes, at + 3U);
    return b0 | (b1 << 8U) | (b2 << 16U) | (b3 << 24U);
}

[[nodiscard]] std::uint32_t be32(std::span<const std::byte> bytes, std::size_t at) noexcept {
    const std::uint32_t b0 = byte_at(bytes, at);
    const std::uint32_t b1 = byte_at(bytes, at + 1U);
    const std::uint32_t b2 = byte_at(bytes, at + 2U);
    const std::uint32_t b3 = byte_at(bytes, at + 3U);
    return (b0 << 24U) | (b1 << 16U) | (b2 << 8U) | b3;
}

[[nodiscard]] std::optional<Extent> extent_or(std::uint32_t width, std::uint32_t height) noexcept {
    if (width == 0 || height == 0) return std::nullopt;
    return Extent{.width = width, .height = height};
}

[[nodiscard]] std::uint32_t le16(std::span<const std::byte> bytes, std::size_t at) noexcept {
    const std::uint32_t low = byte_at(bytes, at);
    const std::uint32_t high = byte_at(bytes, at + 1U);
    return low | (high << 8U);
}

[[nodiscard]] std::optional<Extent> png_extent(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() < 24) return std::nullopt;
    const bool lead = byte_at(bytes, 0) == 0x89 && byte_at(bytes, 1) == 0x50;
    const bool kind = byte_at(bytes, 2) == 0x4E && byte_at(bytes, 3) == 0x47;
    const bool mark = byte_at(bytes, 4) == 0x0D && byte_at(bytes, 5) == 0x0A;
    const bool tail = byte_at(bytes, 6) == 0x1A && byte_at(bytes, 7) == 0x0A;
    if (!lead || !kind || !mark || !tail) return std::nullopt;
    return extent_or(be32(bytes, 16), be32(bytes, 20));
}

[[nodiscard]] std::optional<Extent> dds_extent(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() < 20) return std::nullopt;
    const bool lead = byte_at(bytes, 0) == 'D' && byte_at(bytes, 1) == 'D';
    const bool rest = byte_at(bytes, 2) == 'S' && byte_at(bytes, 3) == ' ';
    if (!lead || !rest) return std::nullopt;
    return extent_or(le32(bytes, 16), le32(bytes, 12));
}

[[nodiscard]] std::optional<Extent> tga_extent(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() < 18) return std::nullopt;
    return extent_or(le16(bytes, 12), le16(bytes, 14));
}

[[nodiscard]] bool same_letter(char left, char right) noexcept {
    const auto first = static_cast<unsigned char>(left);
    const auto second = static_cast<unsigned char>(right);
    return std::tolower(first) == std::tolower(second);
}

[[nodiscard]] bool ends_with_ci(std::string_view text, std::string_view suffix) noexcept {
    if (text.size() < suffix.size()) return false;
    const std::string_view tail = text.substr(text.size() - suffix.size());
    return std::ranges::equal(tail, suffix, same_letter);
}

[[nodiscard]] std::optional<Extent> stored_extent(std::string_view path,
    std::span<const std::byte> bytes) noexcept {
    if (ends_with_ci(path, ".png")) return png_extent(bytes);
    if (ends_with_ci(path, ".dds")) return dds_extent(bytes);
    if (ends_with_ci(path, ".tga")) return tga_extent(bytes);
    return std::nullopt;
}

// PNG vá chỉ thay ảnh gốc khi cùng cỡ. Lệch cỡ thì giữ gốc: imageset viết toạ độ theo tệp gốc.
[[nodiscard]] std::string sheet_file(const std::string& chosen) {
    const std::string patched = chosen + ".png";
    const std::filesystem::path patch_path = io::path_from_utf8(patched);
    if (!std::filesystem::is_regular_file(patch_path)) return chosen;
    const io::TextResult patch_bytes = io::read_text(patch_path);
    if (!patch_bytes) return chosen;
    const io::TextResult source_bytes = io::read_text(io::path_from_utf8(chosen));
    if (!source_bytes) return patched;
    const auto patch_raw = std::as_bytes(std::span(*patch_bytes));
    const auto source_raw = std::as_bytes(std::span(*source_bytes));
    const std::optional<Extent> source = stored_extent(chosen, source_raw);
    const std::optional<Extent> patch = png_extent(patch_raw);
    if (!source || !patch || *source != *patch) return chosen;
    return patched;
}

} // namespace

Painter::Painter(render::UiPass& pass, std::filesystem::path data_root, resource::TextureTier tier)
    : pass_(&pass), root_(std::move(data_root)), tier_(tier) {}

// PNG cùng cỡ cạnh Imagefile thì dùng; lệch cỡ thì tệp gốc. Lỗi thì ghi một dòng và trả bản hỏng.
Painter::Loaded Painter::load(const std::string& name) {
    const std::string chosen = resource::texture_file(io::utf8_of(root_), "Interface/" + name, tier_);
    const std::string used = sheet_file(chosen);
    const std::filesystem::path file = io::path_from_utf8(used);
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
    // Phông bitmap chỉ nét ở cỡ gốc: khi giao diện co (scale < 1) dàn chữ trong ô đã co, theo điểm ảnh của màn, rồi đổi
    // lại sang toạ độ layout; lúc vẽ pass co lần nữa nên mỗi điểm ảnh phông ra đúng một điểm ảnh màn.
    const float scale = job.kit->scale;
    const bool is_shrunk = scale > 0.0F && scale < 1.0F;
    gui::TextRun placed = run;
    if (is_shrunk) {
        placed.box = shrink(run.box, scale);
        if (run.clip) placed.clip = shrink(*run.clip, scale);
    }
    std::optional<gui::Box> caret = writer.write(placed, vertices_);
    if (is_shrunk) {
        expand(std::span(vertices_).subspan(first), scale);
        if (caret) caret = grow(*caret, scale);
    }
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
    if (kit.scale > 0.0F && kit.scale < 1.0F) snap(vertices_, kit.scale);
}

} // namespace game::ui
