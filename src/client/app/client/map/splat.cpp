/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/map/splat.cpp
 *  PHÂN HỆ   : Client / Map / Splat
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bảng góc là Terrain::_getPixmapCorner, cornerIndexMap[lật đường
 *    chéo][orientation][góc]. Mỗi byte: nibble cao là cạnh U, nibble thấp là
 *    cạnh V. 0 trái, 1 trên, 2 phải, 3 dưới.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/map/splat.hpp"

#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::client::map {
namespace {

constexpr std::size_t kTurnCount = 16;
constexpr std::size_t kCornerCount = 4;
// Đệm quanh mỗi ảnh cọ và bước đặt trong atlas: mip mức n gộp khối 2^n điểm ảnh, nên với bước 16 các mức 0..4
// không bao giờ gộp qua mép ảnh, và đệm 16 che hết vệt lọc bất đẳng hướng ở các mức ấy.
constexpr std::uint32_t kPad = 16;
constexpr std::uint32_t kAlign = 16;
constexpr std::uint32_t kStartEdge = 256;
// Ảnh cọ của bản gốc tối đa 512 cạnh; trần này chỉ để tính toán uint32 không tràn với dữ liệu hỏng.
constexpr std::uint32_t kMaxBrushEdge = 16384;
constexpr int kMaxShrink = 8;
constexpr std::size_t kPixmapTexels = 4;

// Mỗi dòng một orientation, bốn góc: trái-trên, phải-trên, trái-dưới, phải-dưới.
constexpr std::array<std::uint8_t, kTurnCount * kCornerCount> kStraight{
    0x01, 0x21, 0x03, 0x23, // 0
    0x21, 0x01, 0x23, 0x03, // 1
    0x03, 0x23, 0x01, 0x21, // 2
    0x23, 0x03, 0x21, 0x01, // 3
    0x21, 0x23, 0x01, 0x03, // 4
    0x01, 0x03, 0x21, 0x23, // 5
    0x23, 0x21, 0x03, 0x01, // 6
    0x03, 0x01, 0x23, 0x21, // 7
    0x01, 0x21, 0x03, 0x01, // 8
    0x21, 0x01, 0x23, 0x21, // 9
    0x03, 0x23, 0x01, 0x03, // 10
    0x23, 0x03, 0x21, 0x23, // 11
    0x21, 0x23, 0x01, 0x21, // 12
    0x01, 0x03, 0x21, 0x01, // 13
    0x23, 0x21, 0x03, 0x23, // 14
    0x03, 0x01, 0x23, 0x03 // 15
};

constexpr std::array<std::uint8_t, kTurnCount * kCornerCount> kFlipped{
    0x01, 0x21, 0x03, 0x23, // 0
    0x21, 0x01, 0x23, 0x03, // 1
    0x03, 0x23, 0x01, 0x21, // 2
    0x23, 0x03, 0x21, 0x01, // 3
    0x21, 0x23, 0x01, 0x03, // 4
    0x01, 0x03, 0x21, 0x23, // 5
    0x23, 0x21, 0x03, 0x01, // 6
    0x03, 0x01, 0x23, 0x21, // 7
    0x01, 0x21, 0x21, 0x23, // 8
    0x21, 0x01, 0x01, 0x03, // 9
    0x03, 0x23, 0x23, 0x21, // 10
    0x23, 0x03, 0x03, 0x01, // 11
    0x21, 0x23, 0x23, 0x03, // 12
    0x01, 0x03, 0x03, 0x23, // 13
    0x23, 0x21, 0x21, 0x01, // 14
    0x03, 0x01, 0x01, 0x21 // 15
};

[[nodiscard]] constexpr std::uint32_t round_up(std::uint32_t value, std::uint32_t step) noexcept {
    return ((value + step - 1U) / step) * step;
}

// Ảnh cọ đã nhân alpha. rgba rỗng là cọ không dùng.
struct Brush {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::vector<std::uint8_t> rgba;

    [[nodiscard]] bool is_used() const noexcept { return !rgba.empty(); }
};

// Hình chữ nhật của một ảnh cọ trong atlas, tính cả đệm.
struct Slot {
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

struct Arrangement {
    std::vector<Slot> slots;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

[[nodiscard]] bool image_ok(const BrushImage& image) noexcept {
    if (image.width == 0 || image.height == 0) return false;
    if (image.width > kMaxBrushEdge || image.height > kMaxBrushEdge) return false;
    const std::size_t need = static_cast<std::size_t>(image.width) * static_cast<std::size_t>(image.height) * 4U;
    return image.rgba.size() >= need;
}

[[nodiscard]] std::uint8_t premultiply(std::uint8_t channel, std::uint8_t alpha) noexcept {
    const std::uint32_t product = (static_cast<std::uint32_t>(channel) * static_cast<std::uint32_t>(alpha)) + 127U;
    return static_cast<std::uint8_t>(product / 255U);
}

[[nodiscard]] Brush premultiplied(const BrushImage& source) {
    Brush brush;
    brush.width = source.width;
    brush.height = source.height;
    const std::size_t pixels = static_cast<std::size_t>(source.width) * static_cast<std::size_t>(source.height);
    brush.rgba.resize(pixels * 4U);
    for (std::size_t pixel = 0; pixel < pixels; ++pixel) {
        const std::size_t offset = pixel * 4U;
        const std::uint8_t alpha = source.rgba[offset + 3U];
        brush.rgba[offset] = premultiply(source.rgba[offset], alpha);
        brush.rgba[offset + 1U] = premultiply(source.rgba[offset + 1U], alpha);
        brush.rgba[offset + 2U] = premultiply(source.rgba[offset + 2U], alpha);
        brush.rgba[offset + 3U] = alpha;
    }
    return brush;
}

// (tổng 4 mẫu + 2) / 4: làm tròn 0,5 lên, cùng phép với bản trước.
[[nodiscard]] std::uint8_t box_channel(const Brush& from, std::span<const std::size_t, 4> taps,
    std::size_t channel) noexcept {
    std::uint32_t sum = 2U;
    for (const std::size_t tap : taps) sum += from.rgba[tap + channel];
    return static_cast<std::uint8_t>(sum / 4U);
}

struct BoxWindow {
    std::uint32_t row = 0;
    std::uint32_t column = 0;
    std::uint32_t top = 0;
    std::uint32_t bottom = 0;
};

void write_halved_texel(const Brush& from, Brush& brush, BoxWindow window) {
    const std::uint32_t left = std::min(window.column * 2U, from.width - 1U);
    const std::uint32_t right = std::min(left + 1U, from.width - 1U);
    const std::array<std::size_t, 4> taps{
        ((static_cast<std::size_t>(window.top) * from.width) + left) * 4U,
        ((static_cast<std::size_t>(window.top) * from.width) + right) * 4U,
        ((static_cast<std::size_t>(window.bottom) * from.width) + left) * 4U,
        ((static_cast<std::size_t>(window.bottom) * from.width) + right) * 4U,
    };
    const std::size_t target = ((static_cast<std::size_t>(window.row) * brush.width) + window.column) * 4U;
    for (std::size_t channel = 0; channel < 4U; ++channel) {
        brush.rgba[target + channel] = box_channel(from, taps, channel);
    }
}

void halve_row(const Brush& from, Brush& brush, std::uint32_t row) {
    const std::uint32_t top = std::min(row * 2U, from.height - 1U);
    const std::uint32_t bottom = std::min(top + 1U, from.height - 1U);
    for (std::uint32_t column = 0; column < brush.width; ++column) {
        const BoxWindow window{.row = row, .column = column, .top = top, .bottom = bottom};
        write_halved_texel(from, brush, window);
    }
}

// Trung bình hộp 2 x 2 (kẹp mép) của ảnh đã nhân alpha: thu nhỏ một nửa.
[[nodiscard]] Brush halved(const Brush& from) {
    Brush brush;
    brush.width = std::max(from.width / 2U, 1U);
    brush.height = std::max(from.height / 2U, 1U);
    brush.rgba.resize(static_cast<std::size_t>(brush.width) * static_cast<std::size_t>(brush.height) * 4U);
    for (std::uint32_t row = 0; row < brush.height; ++row) halve_row(from, brush, row);
    return brush;
}

[[nodiscard]] Slot padded_size(const Brush& brush) noexcept {
    Slot size;
    size.width = round_up(brush.width + (2U * kPad), kAlign);
    size.height = round_up(brush.height + (2U * kPad), kAlign);
    return size;
}

// Cỡ atlas thử xếp: bề rộng của kệ và trần cạnh dài.
struct Limits {
    std::uint32_t width = 0;
    std::uint32_t max_edge = 0;
};

struct Shelf {
    std::uint32_t cursor = 0;
    std::uint32_t top = 0;
    std::uint32_t height = 0;
};

// false khi ảnh rộng hơn kệ. So bằng trừ: cursor + width có thể tràn uint32 khi trần cạnh rất lớn.
[[nodiscard]] bool place_on_shelf(Arrangement& layout, Shelf& shelf, std::size_t index, const Slot& size,
    std::uint32_t limit) {
    if (size.width > limit) return false;
    if (shelf.cursor > limit - size.width) {
        if (shelf.height > std::numeric_limits<std::uint32_t>::max() - shelf.top) return false;
        shelf.top += shelf.height;
        shelf.cursor = 0;
        shelf.height = 0;
    }
    layout.slots[index] = Slot{.x = shelf.cursor, .y = shelf.top, .width = size.width, .height = size.height};
    shelf.cursor += size.width;
    shelf.height = std::max(shelf.height, size.height);
    return true;
}

// Xếp theo kệ, ảnh cao trước, kệ rộng limits.width. Vị trí luôn là bội của kAlign vì kích cỡ đệm là bội của nó.
[[nodiscard]] std::optional<Arrangement> shelf_pack(const std::vector<Brush>& brushes, Limits limits) {
    std::vector<std::size_t> order;
    order.reserve(brushes.size());
    for (std::size_t index = 0; index < brushes.size(); ++index) {
        if (brushes[index].is_used()) order.push_back(index);
    }
    std::ranges::stable_sort(order, [&](std::size_t left, std::size_t right) {
        return padded_size(brushes[left]).height > padded_size(brushes[right]).height;
    });
    Arrangement layout;
    layout.width = limits.width;
    layout.slots.assign(brushes.size(), Slot{});
    Shelf shelf;
    for (const std::size_t index : order) {
        const Slot size = padded_size(brushes[index]);
        if (!place_on_shelf(layout, shelf, index, size, limits.width)) return std::nullopt;
    }
    if (shelf.height > std::numeric_limits<std::uint32_t>::max() - shelf.top) return std::nullopt;
    layout.height = round_up(shelf.top + shelf.height, kAlign);
    if (layout.height > limits.max_edge) return std::nullopt;
    return layout;
}

[[nodiscard]] std::uint64_t area_of(const Arrangement& layout) noexcept {
    return static_cast<std::uint64_t>(layout.width) * layout.height;
}

// false khi lần nhân hai sẽ tràn uint32 hoặc vượt trần. width *= 2 lúc width > 2^31 ra 0 và vòng lặp không thoát.
[[nodiscard]] bool widen(std::uint32_t& width, std::uint32_t max_edge) noexcept {
    if (width > max_edge / 2U) return false;
    width *= 2U;
    return true;
}

// Bề rộng nhỏ nhất (lũy thừa của hai) cho atlas gần vuông; không có bề rộng nào vừa trần thì rỗng.
[[nodiscard]] std::optional<Arrangement> best_layout(const std::vector<Brush>& brushes, std::uint32_t max_edge) {
    std::optional<Arrangement> best;
    for (std::uint32_t width = kStartEdge; width <= max_edge;) {
        std::optional<Arrangement> tried = shelf_pack(brushes, Limits{.width = width, .max_edge = max_edge});
        const bool is_square = tried && tried->height <= width;
        const bool tighter = tried && (!best || area_of(*tried) < area_of(*best));
        if (tighter) best = std::move(tried);
        if (is_square || !widen(width, max_edge)) break;
    }
    return best;
}

void shrink_used(std::vector<Brush>& brushes) {
    for (Brush& brush : brushes) {
        if (brush.is_used()) brush = halved(brush);
    }
}

// Không vừa trần thì thu nhỏ mọi ảnh một nửa rồi thử lại: giữ tỉ lệ giữa các ảnh, nên mức chi tiết giảm đều.
[[nodiscard]] std::optional<Arrangement> arrange(std::vector<Brush>& brushes, std::uint32_t max_edge) {
    for (int shrink = 0; shrink <= kMaxShrink; ++shrink) {
        if (std::optional<Arrangement> layout = best_layout(brushes, max_edge)) return layout;
        shrink_used(brushes);
    }
    return std::nullopt;
}

// Vị trí nguồn của texel đệm: kẹp vào ảnh, nên viền đệm là lặp mép.
[[nodiscard]] std::uint32_t source_index(std::uint32_t position, std::uint32_t size) noexcept {
    if (position < kPad) return 0;
    return std::min(position - kPad, size - 1U);
}

void blit_row(Picture& atlas, const Brush& brush, const Slot& slot, std::uint32_t row) {
    const std::size_t from_row = source_index(row, brush.height);
    const std::size_t target_row = static_cast<std::size_t>(slot.y) + row;
    for (std::uint32_t column = 0; column < slot.width; ++column) {
        const std::size_t from = ((from_row * brush.width) + source_index(column, brush.width)) * 4U;
        const std::size_t target = ((target_row * atlas.width) + slot.x + column) * 4U;
        const std::span<const std::uint8_t> pixel = std::span<const std::uint8_t>(brush.rgba).subspan(from, 4);
        std::ranges::copy(pixel, atlas.rgba.begin() + static_cast<std::ptrdiff_t>(target));
    }
}

void blit_brush(Picture& atlas, const Brush& brush, const Slot& slot) {
    if (!brush.is_used()) return;
    for (std::uint32_t row = 0; row < slot.height; ++row) blit_row(atlas, brush, slot, row);
}

[[nodiscard]] Picture render_atlas(const std::vector<Brush>& brushes, const Arrangement& layout) {
    Picture atlas;
    atlas.width = layout.width;
    atlas.height = layout.height;
    atlas.rgba.assign(static_cast<std::size_t>(layout.width) * layout.height * 4U, 0);
    for (std::size_t index = 0; index < brushes.size(); ++index) blit_brush(atlas, brushes[index], layout.slots[index]);
    return atlas;
}

// Id pixmap dùng được của một lớp (1 trở lên), hoặc 0: lớp trống, id ngoài bảng hay ngoài 10 bit, hoặc cọ của nó
// không có ảnh dùng được.
[[nodiscard]] std::uint32_t usable_id(const TerrainFile& file, std::span<const std::uint8_t> ready,
    Layer layer) noexcept {
    const std::size_t id = layer.pixmap;
    if (id == 0 || id > file.pixmaps.size() || id > kSplatMaxPixmap) return 0;
    const std::size_t texture = file.pixmaps[id - 1U].texture;
    if (texture >= ready.size() || ready[texture] == 0) return 0;
    return static_cast<std::uint32_t>(id);
}

[[nodiscard]] std::uint32_t quantised(float value) noexcept {
    return static_cast<std::uint32_t>(std::lround(std::clamp(value, 0.0F, 1.0F) * 65535.0F));
}

// Hai số 16 bit vào một texel RGBA8: (cao, thấp) của số thứ nhất rồi của số thứ hai.
void put_pair(std::span<std::uint8_t> texel, float first, float second) noexcept {
    const std::uint32_t one = quantised(first);
    const std::uint32_t two = quantised(second);
    texel[0] = static_cast<std::uint8_t>(one >> 8U);
    texel[1] = static_cast<std::uint8_t>(one & 0xFFU);
    texel[2] = static_cast<std::uint8_t>(two >> 8U);
    texel[3] = static_cast<std::uint8_t>(two & 0xFFU);
}

[[nodiscard]] std::size_t table_rows(const TerrainFile& file) noexcept {
    const std::size_t ids = std::min<std::size_t>(file.pixmaps.size(), kSplatMaxPixmap) + 1U;
    const std::size_t texels = ids * kPixmapTexels;
    return 1U + ((texels + kSplatTableWidth - 1U) / kSplatTableWidth);
}

void write_pixmap(Picture& table, const Pixmap& pixmap, const Brush& brush, const Slot& slot, std::size_t id,
    const Arrangement& layout) {
    const auto across = static_cast<float>(layout.width);
    const auto down = static_cast<float>(layout.height);
    const std::size_t first = id * kPixmapTexels;
    const std::size_t base = ((1U + (first / kSplatTableWidth)) * kSplatTableWidth) + (first % kSplatTableWidth);
    const std::span<std::uint8_t> texels = std::span<std::uint8_t>(table.rgba).subspan(base * 4U, kPixmapTexels * 4U);
    put_pair(texels.subspan(0, 4), pixmap.left, pixmap.top);
    put_pair(texels.subspan(4, 4), pixmap.right, pixmap.bottom);
    put_pair(texels.subspan(8, 4), static_cast<float>(slot.x + kPad) / across, static_cast<float>(slot.y + kPad) / down);
    put_pair(texels.subspan(12, 4), static_cast<float>(brush.width) / across, static_cast<float>(brush.height) / down);
}

// Hàng 0 là bốn góc theo (lật đường chéo * 16 + orientation); từ hàng 1, pixmap id chiếm bốn texel liền nhau từ
// vị trí 4 * id: hộp (trái, trên | phải, dưới) rồi phép đổi (gốc x, gốc y | tỉ lệ x, tỉ lệ y) sang atlas.
[[nodiscard]] Picture table_image(const TerrainFile& file, const std::vector<Brush>& brushes, const Arrangement& layout,
    std::span<const std::uint8_t> ready) {
    Picture table;
    table.width = kSplatTableWidth;
    table.height = static_cast<std::uint32_t>(table_rows(file));
    table.rgba.assign(static_cast<std::size_t>(table.width) * table.height * 4U, 0);
    for (std::size_t flip = 0; flip < 2U; ++flip) {
        const std::array<std::uint8_t, kTurnCount * kCornerCount>& corners = flip == 0 ? kStraight : kFlipped;
        std::ranges::copy(corners, table.rgba.begin() + static_cast<std::ptrdiff_t>(flip * kTurnCount * kCornerCount));
    }
    const std::size_t ids = std::min<std::size_t>(file.pixmaps.size(), kSplatMaxPixmap);
    for (std::size_t id = 1; id <= ids; ++id) {
        const Pixmap& pixmap = file.pixmaps[id - 1U];
        const bool is_ready = pixmap.texture < ready.size() && ready[pixmap.texture] != 0;
        if (!is_ready) continue;
        write_pixmap(table, pixmap, brushes[pixmap.texture], layout.slots[pixmap.texture], id, layout);
    }
    return table;
}

[[nodiscard]] std::uint8_t turn_of(Layer layer) noexcept {
    return layer.orientation < kTurnCount ? layer.orientation : std::uint8_t{0};
}

// R, G: 8 bit thấp của pixmap nền và phủ. B: bit 0-1 và 2-3 là hai bit cao của chúng, bit 4 là cờ đường chéo.
// A: orientation nền ở nibble thấp, phủ ở nibble cao.
[[nodiscard]] Picture cell_image(const TerrainFile& file, const GridField& grid, std::span<const std::uint8_t> ready) {
    Picture cells;
    cells.width = static_cast<std::uint32_t>(file.x_size);
    cells.height = static_cast<std::uint32_t>(file.z_size);
    const std::size_t count = static_cast<std::size_t>(cells.width) * cells.height;
    cells.rgba.assign(count * 4U, 0);
    for (std::size_t index = 0; index < count; ++index) {
        const Cell& cell = grid.cells[index];
        const std::uint32_t base = usable_id(file, ready, cell.base);
        // Ô không có nền là lỗ: lớp phủ không còn nghĩa.
        const std::uint32_t cover = base != 0 ? usable_id(file, ready, cell.cover) : 0U;
        const std::uint32_t flip = (cell.flags & kFlipDiagonal) != 0 ? 1U : 0U;
        const std::uint32_t high = ((base >> 8U) & 3U) | (((cover >> 8U) & 3U) << 2U) | (flip << 4U);
        const std::uint32_t turns = turn_of(cell.base) | (static_cast<std::uint32_t>(turn_of(cell.cover)) << 4U);
        const std::size_t offset = index * 4U;
        cells.rgba[offset] = static_cast<std::uint8_t>(base & 0xFFU);
        cells.rgba[offset + 1U] = static_cast<std::uint8_t>(cover & 0xFFU);
        cells.rgba[offset + 2U] = static_cast<std::uint8_t>(high);
        cells.rgba[offset + 3U] = static_cast<std::uint8_t>(turns);
    }
    return cells;
}

[[nodiscard]] bool grid_ok(const TerrainFile& file, const GridField& grid) noexcept {
    if (file.x_size <= 0 || file.z_size <= 0 || file.x_size > kMaxGrids || file.z_size > kMaxGrids) return false;
    const std::size_t cells = static_cast<std::size_t>(file.x_size) * static_cast<std::size_t>(file.z_size);
    return grid.cells.size() >= cells;
}

void mark_layer(const TerrainFile& file, std::vector<std::uint8_t>& used, std::span<const std::uint8_t> ready,
    Layer layer) {
    const std::uint32_t id = usable_id(file, ready, layer);
    if (id == 0) return;
    used[file.pixmaps[id - 1U].texture] = 1;
}

} // namespace

std::vector<std::uint8_t> brushes_in_use(const TerrainFile& file, const GridField& grid) {
    std::vector<std::uint8_t> used(file.textures.size(), 0);
    if (!grid_ok(file, grid)) return used;
    const std::vector<std::uint8_t> everything(file.textures.size(), 1);
    const std::size_t count = static_cast<std::size_t>(file.x_size) * static_cast<std::size_t>(file.z_size);
    for (std::size_t index = 0; index < count; ++index) {
        mark_layer(file, used, everything, grid.cells[index].base);
        mark_layer(file, used, everything, grid.cells[index].cover);
    }
    return used;
}

SplatImages build_splat(const TerrainFile& file, const GridField& grid, std::span<const BrushImage> brushes,
    std::uint32_t max_edge) {
    SplatImages images;
    if (!grid_ok(file, grid)) return images;
    const std::vector<std::uint8_t> used = brushes_in_use(file, grid);
    std::vector<std::uint8_t> ready(used.size(), 0);
    std::vector<Brush> sources(used.size());
    bool has_any = false;
    for (std::size_t index = 0; index < used.size(); ++index) {
        if (used[index] == 0 || index >= brushes.size() || !image_ok(brushes[index])) continue;
        sources[index] = premultiplied(brushes[index]);
        ready[index] = 1;
        has_any = true;
    }
    if (!has_any) return images;
    const std::optional<Arrangement> layout = arrange(sources, max_edge);
    if (!layout) return images;
    images.atlas = render_atlas(sources, *layout);
    images.table = table_image(file, sources, *layout, ready);
    images.cells = cell_image(file, grid, ready);
    return images;
}

} // namespace game::client::map
