// Đọc AXFT và ghép bảng nhịp. Khác gốc so với ui_font.py: chỉ giữ atlas và bước ngang, bỏ khối
// glyph sau khi đã trải; cỡ 16 không nhận vì bố cục đó mới là suy đoán. Atlas có thêm một ô cuối là
// ô vuông rỗng mà client 2026 vẽ cho mã không có bản ghi (bộ viết chữ ui/text dùng).
#include "ui/pace.hpp"

#include "core/error.hpp"
#include "io/file.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <filesystem>
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui {
namespace {

constexpr std::uint32_t kHeaderBytes = 0xA4;
constexpr std::uint32_t kIndexEntries = 65536;
constexpr std::uint32_t kNoGlyph = 0xFFFFFFFFU;
constexpr std::uint32_t kMagic = 0x54465841U;
constexpr int kAtlasColumns = 32;
constexpr std::uint32_t kPanel = 0xF0101418U;
constexpr std::uint32_t kInk = 0xFFFFFFFFU;
constexpr float kValueColumn = 168.0F;
constexpr float kPad = 10.0F;

struct Layout {
    int pixel_size = 0;
    std::uint32_t glyphs_at = 0;
    std::uint32_t record_bytes = 0;
};

struct Decoded {
    char32_t code = 0;
    std::size_t bytes = 0;
};

[[nodiscard]] bool read_u32(std::string_view bytes, std::size_t offset, std::uint32_t& out) {
    if (offset + 4 > bytes.size()) return false;
    const std::string_view slice = bytes.substr(offset, 4);
    std::memcpy(&out, slice.data(), slice.size());
    return true;
}

[[nodiscard]] bool read_u16(std::string_view bytes, std::size_t offset, std::uint16_t& out) {
    if (offset + 2 > bytes.size()) return false;
    const std::string_view slice = bytes.substr(offset, 2);
    std::memcpy(&out, slice.data(), slice.size());
    return true;
}

[[nodiscard]] core::Result<Layout> layout_of(std::string_view bytes) {
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t pixel_size = 0;
    std::uint32_t range_count = 0;
    std::uint32_t ranges_at = 0;
    std::uint32_t index_at = 0;
    std::uint32_t glyphs_at = 0;
    std::uint32_t glyph_bytes = 0;
    const bool is_header = read_u32(bytes, 0, magic) && read_u32(bytes, 4, version) && read_u32(bytes, 8, pixel_size) &&
        read_u32(bytes, 12, range_count) && read_u32(bytes, 16, ranges_at) && read_u32(bytes, 20, index_at) &&
        read_u32(bytes, 24, glyphs_at) && read_u32(bytes, 28, glyph_bytes);
    if (!is_header || magic != kMagic || version != 1) {
        return core::fail(core::ErrorCode::kInvalidArgument, "phông AXFT hỏng");
    }
    const bool is_known = pixel_size == 12 || pixel_size == 14;
    const std::uint32_t ranges = kHeaderBytes + (8U * range_count);
    const std::uint32_t index = ranges + (4U * kIndexEntries);
    const bool is_placed = ranges_at == kHeaderBytes && index_at == ranges && glyphs_at == index;
    const bool is_tail = glyph_bytes == bytes.size() - glyphs_at && glyphs_at <= bytes.size();
    if (!is_known || !is_placed || !is_tail) {
        return core::fail(core::ErrorCode::kInvalidArgument, "phông AXFT lệch bố cục");
    }
    Layout layout;
    layout.pixel_size = static_cast<int>(pixel_size);
    layout.glyphs_at = glyphs_at;
    layout.record_bytes = pixel_size == 12 ? 20U : 2U + (2U * pixel_size);
    return layout;
}

[[nodiscard]] std::vector<std::uint32_t> index_of(std::string_view bytes, std::uint32_t origin) {
    std::vector<std::uint32_t> index(kIndexEntries, kNoGlyph);
    const std::string_view slice = bytes.substr(origin, index.size() * 4);
    std::memcpy(index.data(), slice.data(), slice.size());
    return index;
}

void store_pair(std::string_view record, int pair, std::array<std::uint32_t, 16>& rows) {
    const auto pair_index = static_cast<std::size_t>(pair);
    const std::size_t start = 2 + (pair_index * 3);
    const auto low = static_cast<std::uint32_t>(static_cast<unsigned char>(record[start]));
    const auto high = static_cast<std::uint32_t>(static_cast<unsigned char>(record[start + 1]));
    const auto tail = static_cast<std::uint32_t>(static_cast<unsigned char>(record[start + 2]));
    const std::uint32_t word = low | (high << 8U);
    rows.at(pair_index * 2) = word >> 4U;
    rows.at((pair_index * 2) + 1) = ((word & 0xFU) << 8U) | tail;
}

void rows_of_12(std::string_view record, std::array<std::uint32_t, 16>& rows) {
    for (int pair = 0; pair < 6; ++pair)
        store_pair(record, pair, rows);
}

void rows_of_wide(std::string_view record, int pixel_size, std::array<std::uint32_t, 16>& rows) {
    const int shift = 16 - pixel_size;
    for (int line = 0; line < pixel_size; ++line) {
        std::uint16_t word = 0;
        const auto line_index = static_cast<std::size_t>(line);
        const std::size_t start = 2 + (line_index * 2);
        static_cast<void>(read_u16(record, start, word));
        rows.at(line_index) = static_cast<std::uint32_t>(word) >> static_cast<unsigned>(shift);
    }
}

struct InkBit {
    std::uint32_t row_bits = 0;
    int pixel_size = 0;
    int column = 0;
};

[[nodiscard]] bool is_ink(InkBit bit) noexcept {
    const int shift = (bit.pixel_size - 1) - bit.column;
    return ((bit.row_bits >> shift) & 1U) != 0U;
}

struct GlyphDot {
    int pixel_size = 0;
    int column = 0;
    int pixel_y = 0;
    int across = 0;
};

void paint_column(resource::Image& atlas, GlyphDot dot, std::uint32_t bits) {
    const InkBit bit{.row_bits = bits, .pixel_size = dot.pixel_size, .column = dot.across};
    if (!is_ink(bit)) return;
    const int pixel_x = (dot.column * dot.pixel_size) + dot.across;
    const auto row_span = static_cast<std::size_t>(dot.pixel_y) * atlas.width;
    const std::size_t pixel = (row_span + static_cast<std::size_t>(pixel_x)) * 4;
    atlas.rgba.at(pixel) = 255;
    atlas.rgba.at(pixel + 1) = 255;
    atlas.rgba.at(pixel + 2) = 255;
    atlas.rgba.at(pixel + 3) = 255;
}

struct RowPlace {
    int pixel_size = 0;
    int column = 0;
    int pixel_y = 0;
};

void paint_row(resource::Image& atlas, RowPlace place, std::uint32_t bits) {
    for (int across = 0; across < place.pixel_size; ++across) {
        const GlyphDot dot{
            .pixel_size = place.pixel_size, .column = place.column, .pixel_y = place.pixel_y, .across = across};
        paint_column(atlas, dot, bits);
    }
}

struct GlyphCell {
    int column = 0;
    int row = 0;
};

void paint_glyph(resource::Image& atlas, std::string_view record, const Layout& layout, GlyphCell cell) {
    std::array<std::uint32_t, 16> rows{};
    if (layout.pixel_size == 12) rows_of_12(record, rows);
    if (layout.pixel_size != 12) rows_of_wide(record, layout.pixel_size, rows);
    for (int line = 0; line < layout.pixel_size; ++line) {
        const RowPlace place{
            .pixel_size = layout.pixel_size, .column = cell.column, .pixel_y = (cell.row * layout.pixel_size) + line};
        const std::uint32_t bits = rows.at(static_cast<std::size_t>(line));
        paint_row(atlas, place, bits);
    }
}

// Ô vuông rỗng của mã không có bản ghi, toạ độ trong ô bitmap: bộ trải AXFT của CEGUIBase.dll (cỡ
// 12 ở 0x180132a06, cỡ 14 ở 0x180132e3b) ghi điểm chữ ở cột 2..8 của hàng 2 và hàng 9, và ở cột 2
// và cột 8 của hàng 3..8. Cả hai cỡ dùng cùng một mẫu.
constexpr int kBoxLeft = 2;
constexpr int kBoxRight = 8;
constexpr int kBoxTop = 2;
constexpr int kBoxBottom = 9;

[[nodiscard]] constexpr std::uint32_t column_bit(int pixel_size, int column) noexcept {
    return 1U << static_cast<unsigned>((pixel_size - 1) - column);
}

// Mẫu bit của một hàng ô vuông rỗng: hàng trên và dưới kín từ cột trái tới cột phải, hàng giữa chỉ
// có hai cột biên.
[[nodiscard]] constexpr std::uint32_t box_row(int pixel_size, int line) noexcept {
    const std::uint32_t sides = column_bit(pixel_size, kBoxLeft) | column_bit(pixel_size, kBoxRight);
    if (line != kBoxTop && line != kBoxBottom) return sides;
    std::uint32_t bar = 0;
    for (int column = kBoxLeft; column <= kBoxRight; ++column) bar |= column_bit(pixel_size, column);
    return bar;
}
static_assert(box_row(14, kBoxTop) == 0x0FE0U && box_row(14, 5) == 0x0820U);
static_assert(box_row(12, kBoxBottom) == 0x03F8U && box_row(12, 3) == 0x0208U);

void paint_missing(resource::Image& atlas, int pixel_size, GlyphCell cell) {
    for (int line = kBoxTop; line <= kBoxBottom; ++line) {
        const RowPlace place{.pixel_size = pixel_size, .column = cell.column, .pixel_y = (cell.row * pixel_size) + line};
        paint_row(atlas, place, box_row(pixel_size, line));
    }
}

struct PlacedGlyph {
    char32_t code = 0;
    std::uint16_t advance = 0;
    std::uint16_t column = 0;
    std::uint16_t row = 0;
};

struct CodeSlot {
    std::uint32_t code = 0;
    std::uint32_t offset = 0;
};

void consider_code(std::vector<PlacedGlyph>& glyphs, CodeSlot slot, std::uint32_t& cell) {
    if (slot.offset == kNoGlyph) return;
    PlacedGlyph glyph;
    glyph.code = static_cast<char32_t>(slot.code);
    glyph.column = static_cast<std::uint16_t>(cell % kAtlasColumns);
    glyph.row = static_cast<std::uint16_t>(cell / kAtlasColumns);
    ++cell;
    glyphs.push_back(glyph);
}

[[nodiscard]] std::vector<PlacedGlyph> place_glyphs(const std::vector<std::uint32_t>& index) {
    std::vector<PlacedGlyph> glyphs;
    std::uint32_t cell = 0;
    for (std::uint32_t code = 0; code < kIndexEntries; ++code) {
        const CodeSlot slot{.code = code, .offset = index.at(code)};
        consider_code(glyphs, slot, cell);
    }
    return glyphs;
}

void fill_advances(std::vector<PlacedGlyph>& glyphs, std::string_view bytes, const Layout& layout,
    const std::vector<std::uint32_t>& index) {
    for (PlacedGlyph& glyph : glyphs) {
        const std::uint32_t offset = index.at(static_cast<std::size_t>(glyph.code));
        std::uint16_t advance = 0;
        // Nới ra size_t trước khi cộng: offset do tệp khai, cộng ở 32 bit có thể quấn về trong tệp.
        static_cast<void>(read_u16(bytes, static_cast<std::size_t>(layout.glyphs_at) + offset, advance));
        glyph.advance = advance;
    }
}

void paint_placed(resource::Image& atlas, const PlacedGlyph& glyph, std::string_view bytes, const Layout& layout,
    std::uint32_t offset) {
    const std::size_t start = static_cast<std::size_t>(layout.glyphs_at) + offset;
    if (start + layout.record_bytes > bytes.size()) return;
    const std::string_view record = bytes.substr(start, layout.record_bytes);
    const GlyphCell cell{.column = glyph.column, .row = glyph.row};
    paint_glyph(atlas, record, layout, cell);
}

void fill_atlas(resource::Image& atlas, const std::vector<PlacedGlyph>& glyphs, std::string_view bytes,
    const Layout& layout, const std::vector<std::uint32_t>& index) {
    for (const PlacedGlyph& glyph : glyphs) {
        const std::uint32_t offset = index.at(static_cast<std::uint32_t>(glyph.code));
        paint_placed(atlas, glyph, bytes, layout, offset);
    }
}

[[nodiscard]] Decoded decode_utf8(std::string_view text) noexcept {
    if (text.empty()) return {};
    const auto lead = static_cast<unsigned char>(text.front());
    if (lead < 0x80U) return {.code = lead, .bytes = 1};
    if ((lead & 0xE0U) == 0xC0U && text.size() >= 2) {
        const auto next = static_cast<unsigned char>(text[1]);
        const char32_t code = (static_cast<char32_t>(lead & 0x1FU) << 6U) | (next & 0x3FU);
        return {.code = code, .bytes = 2};
    }
    if ((lead & 0xF0U) == 0xE0U && text.size() >= 3) {
        const auto mid = static_cast<unsigned char>(text[1]);
        const auto tail = static_cast<unsigned char>(text[2]);
        const char32_t high = static_cast<char32_t>(lead & 0x0FU) << 12U;
        const char32_t code = high | (static_cast<char32_t>(mid & 0x3FU) << 6U) | (tail & 0x3FU);
        return {.code = code, .bytes = 3};
    }
    return {.code = 0xFFFD, .bytes = 1};
}

struct QuadBox {
    float left = 0.0F;
    float top = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;
    float u_left = 0.0F;
    float v_top = 0.0F;
    float u_right = 1.0F;
    float v_bottom = 1.0F;
    std::uint32_t colour = kInk;
};

void push_quad(std::vector<render::UiVertex>& out, const QuadBox& box) {
    out.push_back({.x = box.left, .y = box.top, .u = box.u_left, .v = box.v_top, .colour = box.colour});
    out.push_back({.x = box.right, .y = box.top, .u = box.u_right, .v = box.v_top, .colour = box.colour});
    out.push_back({.x = box.right, .y = box.bottom, .u = box.u_right, .v = box.v_bottom, .colour = box.colour});
    out.push_back({.x = box.left, .y = box.bottom, .u = box.u_left, .v = box.v_bottom, .colour = box.colour});
}

[[nodiscard]] std::string millis_text(float millis) {
    return std::format("{:.1f} ms", millis);
}

struct PaceLine {
    std::string_view label;
    std::string value;
};

void append_lines(const BitmapFont& font, std::span<const PaceLine> lines, float origin_x, float origin_y,
    std::vector<render::UiVertex>& out) {
    const float step = static_cast<float>(font.pixel_size()) + 4.0F;
    const float label_x = origin_x + kPad;
    const float value_x = label_x + kValueColumn;
    for (std::size_t index = 0; index < lines.size(); ++index) {
        const float pen_y = origin_y + kPad + (step * static_cast<float>(index));
        font.append_text(lines[index].label, label_x, pen_y, kInk, out);
        font.append_text(lines[index].value, value_x, pen_y, kInk, out);
    }
}

} // namespace

PaceNumbers pace_of(std::span<const float> samples, const PaceNumbers& phases) {
    PaceNumbers pace = phases;
    if (samples.empty()) return pace;
    pace.last_ms = samples.back();
    std::vector<float> sorted(samples.begin(), samples.end());
    std::ranges::sort(sorted);
    const auto pick = [&sorted](double part) {
        const auto index = static_cast<std::size_t>(part * static_cast<double>(sorted.size() - 1));
        return sorted.at(index);
    };
    pace.median_ms = pick(0.5);
    pace.p95_ms = pick(0.95);
    return pace;
}

const BitmapFont::Glyph* BitmapFont::find(char32_t code) const noexcept {
    const auto same = [code](const Glyph& glyph) { return glyph.code == code; };
    const auto found = std::ranges::find_if(glyphs_, same);
    if (found == glyphs_.end()) return nullptr;
    return &*found;
}

bool BitmapFont::has_code(char32_t code) const noexcept {
    return find(code) != nullptr;
}

int BitmapFont::advance_of(char32_t code) const noexcept {
    const Glyph* glyph = find(code);
    if (glyph == nullptr) return 0;
    return glyph->advance;
}

void BitmapFont::append_cell(const Placed& placed, std::vector<render::UiVertex>& out) const {
    const auto size = static_cast<float>(pixel_size_);
    const auto atlas_w = static_cast<float>(atlas_.width);
    const auto atlas_h = static_cast<float>(atlas_.height);
    const float u_left = (static_cast<float>(placed.column) * size) / atlas_w;
    const float v_top = (static_cast<float>(placed.row) * size) / atlas_h;
    const QuadBox box{.left = placed.pen_x,
        .top = placed.pen_y,
        .right = placed.pen_x + size,
        .bottom = placed.pen_y + size,
        .u_left = u_left,
        .v_top = v_top,
        .u_right = u_left + (size / atlas_w),
        .v_bottom = v_top + (size / atlas_h),
        .colour = placed.colour};
    push_quad(out, box);
}

void BitmapFont::append_one(char32_t code, float& pen_x, float pen_y, std::uint32_t colour,
    std::vector<render::UiVertex>& out) const {
    const Glyph* glyph = find(code);
    if (glyph == nullptr) return;
    append_cell({.column = glyph->column, .row = glyph->row, .pen_x = pen_x, .pen_y = pen_y, .colour = colour}, out);
    pen_x += static_cast<float>(glyph->advance);
}

// Ô vuông rỗng nằm ở ô atlas ngay sau glyph cuối (open trải nó ở đó).
void BitmapFont::append_missing(float pen_x, float pen_y, std::uint32_t colour,
    std::vector<render::UiVertex>& out) const {
    const int cell = static_cast<int>(glyphs_.size());
    const Placed placed{
        .column = cell % columns_, .row = cell / columns_, .pen_x = pen_x, .pen_y = pen_y, .colour = colour};
    append_cell(placed, out);
}

void BitmapFont::append_text(std::string_view text, float pen_x, float pen_y, std::uint32_t colour,
    std::vector<render::UiVertex>& out) const {
    std::string_view rest = text;
    while (!rest.empty()) {
        const Decoded decoded = decode_utf8(rest);
        rest.remove_prefix(decoded.bytes);
        append_one(decoded.code, pen_x, pen_y, colour, out);
    }
}

core::Result<BitmapFont> BitmapFont::open(const std::filesystem::path& file) {
    const io::TextResult text = io::read_text(file);
    if (!text) {
        return core::fail(core::ErrorCode::kNotFound, "không đọc được phông", io::describe(text.error()));
    }
    const core::Result<Layout> layout = layout_of(*text);
    if (!layout) return std::unexpected(layout.error());
    const std::uint32_t index_at = layout->glyphs_at - (4U * kIndexEntries);
    const std::vector<std::uint32_t> index = index_of(*text, index_at);
    std::vector<PlacedGlyph> glyphs = place_glyphs(index);
    if (glyphs.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "phông AXFT không có glyph");
    fill_advances(glyphs, *text, *layout, index);
    // Thêm một ô sau glyph cuối cho ô vuông rỗng của mã không có trong phông (append_missing).
    const int missing = static_cast<int>(glyphs.size());
    const int rows = (missing + kAtlasColumns) / kAtlasColumns;
    BitmapFont font;
    font.pixel_size_ = layout->pixel_size;
    font.columns_ = kAtlasColumns;
    font.atlas_.name = "ui.pace.font";
    font.atlas_.width = static_cast<std::uint32_t>(kAtlasColumns * layout->pixel_size);
    font.atlas_.height = static_cast<std::uint32_t>(rows * layout->pixel_size);
    font.atlas_.rgba.assign(static_cast<std::size_t>(font.atlas_.width) * font.atlas_.height * 4, 0);
    fill_atlas(font.atlas_, glyphs, *text, *layout, index);
    const GlyphCell box{.column = missing % kAtlasColumns, .row = missing / kAtlasColumns};
    paint_missing(font.atlas_, layout->pixel_size, box);
    font.glyphs_.reserve(glyphs.size());
    for (const PlacedGlyph& glyph : glyphs) {
        BitmapFont::Glyph kept;
        kept.code = glyph.code;
        kept.advance = glyph.advance;
        kept.column = glyph.column;
        kept.row = glyph.row;
        font.glyphs_.push_back(kept);
    }
    return font;
}

void write_pace(const PacePlace& place, const PaceNumbers& pace, PaceOverlay& overlay) {
    overlay.vertices.clear();
    overlay.batches.clear();
    if (place.font == nullptr) return;
    const BitmapFont& font = *place.font;
    const std::array<PaceLine, 8> lines = {
        PaceLine{.label = "Vừa rồi", .value = millis_text(pace.last_ms)},
        PaceLine{.label = "Trung vị", .value = millis_text(pace.median_ms)},
        PaceLine{.label = "p95", .value = millis_text(pace.p95_ms)},
        PaceLine{.label = "Xin ảnh", .value = millis_text(pace.acquire_ms)},
        PaceLine{.label = "Ghi lệnh", .value = millis_text(pace.draw_ms)},
        PaceLine{.label = "Nộp", .value = millis_text(pace.submit_ms)},
        PaceLine{.label = "Lệnh vẽ", .value = std::to_string(pace.draws)},
        PaceLine{.label = "Quad UI", .value = std::to_string(pace.ui_quads)},
    };
    const float step = static_cast<float>(font.pixel_size()) + 4.0F;
    const float width = kPad + kValueColumn + 96.0F;
    const float height = (kPad * 2.0F) + (step * static_cast<float>(lines.size()));
    const std::size_t panel = overlay.vertices.size();
    const QuadBox board{.left = place.origin_x,
        .top = place.origin_y,
        .right = place.origin_x + width,
        .bottom = place.origin_y + height,
        .colour = kPanel};
    push_quad(overlay.vertices, board);
    const auto panel_quads = static_cast<std::uint32_t>((overlay.vertices.size() - panel) / 4);
    overlay.batches.push_back({.texture = render::kUiWhite, .first_quad = 0, .quad_count = panel_quads});
    const std::size_t text = overlay.vertices.size();
    append_lines(font, lines, place.origin_x, place.origin_y, overlay.vertices);
    const auto text_quads = static_cast<std::uint32_t>((overlay.vertices.size() - text) / 4);
    const auto first = static_cast<std::uint32_t>(text / 4);
    overlay.batches.push_back({.texture = place.texture, .first_quad = first, .quad_count = text_quads});
}

} // namespace game::ui
