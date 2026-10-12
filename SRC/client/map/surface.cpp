// Bảng góc là Terrain::_getPixmapCorner, cornerIndexMap[lật đường chéo][orientation][góc].
// Mỗi byte: nibble cao là cạnh U, nibble thấp là cạnh V. 0 trái, 1 trên, 2 phải, 3 dưới.
#include "client/map/surface.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <stop_token>
#include <thread>
#include <vector>

namespace game::client::map {
namespace {

constexpr int kTexelsPerCell = 8;
constexpr int kMaxBake = 2048;
constexpr int kCornerCount = 4;
constexpr int kTurnCount = 16;

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

struct Sampled {
    std::uint8_t red = 0;
    std::uint8_t green = 0;
    std::uint8_t blue = 0;
    std::uint8_t alpha = 0;
};

[[nodiscard]] float edge_of(const Pixmap& pixmap, int edge) noexcept {
    if (edge == 0) return pixmap.left;
    if (edge == 1) return pixmap.top;
    if (edge == 2) return pixmap.right;
    return pixmap.bottom;
}

[[nodiscard]] int bake_scale(const TerrainFile& file) noexcept {
    const int side = std::max(file.x_size, file.z_size);
    if (side <= 0) return 1;
    int scale = kTexelsPerCell;
    while (side * scale > kMaxBake && scale > 1)
        scale /= 2;
    return scale;
}

[[nodiscard]] bool image_ok(const SurfaceImage& image) noexcept {
    const std::size_t need = static_cast<std::size_t>(image.width) * static_cast<std::size_t>(image.height) * 4U;
    return image.width > 0 && image.height > 0 && image.rgba.size() >= need;
}

[[nodiscard]] Sampled sample_at(const SurfaceImage& image, float u, float v) noexcept {
    Sampled pixel;
    if (!image_ok(image)) return pixel;
    const float clamped_u = std::clamp(u, 0.0F, 1.0F);
    const float clamped_v = std::clamp(v, 0.0F, 1.0F);
    const float last_column = static_cast<float>(image.width - 1);
    const float last_row = static_cast<float>(image.height - 1);
    const auto column = static_cast<std::uint32_t>(clamped_u * last_column);
    const auto row = static_cast<std::uint32_t>(clamped_v * last_row);
    const std::size_t offset = (static_cast<std::size_t>(row) * image.width + column) * 4U;
    pixel.red = image.rgba[offset];
    pixel.green = image.rgba[offset + 1];
    pixel.blue = image.rgba[offset + 2];
    pixel.alpha = image.rgba[offset + 3];
    return pixel;
}

[[nodiscard]] PixmapPoint mix_point(PixmapPoint from, PixmapPoint to, float amount) noexcept {
    PixmapPoint point;
    point.u = from.u + ((to.u - from.u) * amount);
    point.v = from.v + ((to.v - from.v) * amount);
    return point;
}

[[nodiscard]] PixmapPoint cell_uv(const Pixmap& pixmap, const Layer& layer, bool flip_diagonal, float along_x,
    float along_z) noexcept {
    CornerQuery query;
    query.orientation = layer.orientation;
    query.flip_diagonal = flip_diagonal;
    query.corner = 0;
    const PixmapPoint left_top = pixmap_corner(pixmap, query);
    query.corner = 1;
    const PixmapPoint right_top = pixmap_corner(pixmap, query);
    query.corner = 2;
    const PixmapPoint left_bottom = pixmap_corner(pixmap, query);
    query.corner = 3;
    const PixmapPoint right_bottom = pixmap_corner(pixmap, query);
    const PixmapPoint low = mix_point(left_top, right_top, along_x);
    const PixmapPoint high = mix_point(left_bottom, right_bottom, along_x);
    return mix_point(low, high, along_z);
}

[[nodiscard]] bool paint_layer(Sampled& pixel, const TerrainFile& file, const Layer& layer, bool flip_diagonal,
    float along_x, float along_z, std::span<const SurfaceImage> brushes) noexcept {
    if (layer.pixmap == 0 || layer.pixmap > file.pixmaps.size()) return false;
    const Pixmap& pixmap = file.pixmaps[layer.pixmap - 1];
    if (pixmap.texture >= brushes.size()) return false;
    const PixmapPoint uv = cell_uv(pixmap, layer, flip_diagonal, along_x, along_z);
    const Sampled sampled = sample_at(brushes[pixmap.texture], uv.u, uv.v);
    if (!image_ok(brushes[pixmap.texture])) return false;
    pixel = sampled;
    return true;
}

[[nodiscard]] Sampled blend_over(Sampled under, Sampled over) noexcept {
    const int cover = over.alpha;
    const int keep = 255 - cover;
    Sampled mixed;
    mixed.red = static_cast<std::uint8_t>((over.red * cover + under.red * keep) / 255);
    mixed.green = static_cast<std::uint8_t>((over.green * cover + under.green * keep) / 255);
    mixed.blue = static_cast<std::uint8_t>((over.blue * cover + under.blue * keep) / 255);
    mixed.alpha = 255;
    return mixed;
}

[[nodiscard]] Sampled shade_light(Sampled color, Sampled light) noexcept {
    Sampled shaded;
    shaded.red = static_cast<std::uint8_t>((color.red * light.red) / 255);
    shaded.green = static_cast<std::uint8_t>((color.green * light.green) / 255);
    shaded.blue = static_cast<std::uint8_t>((color.blue * light.blue) / 255);
    shaded.alpha = color.alpha;
    return shaded;
}

void write_pixel(Picture& picture, std::size_t pixel, Sampled color) noexcept {
    const std::size_t offset = pixel * 4U;
    picture.rgba[offset] = color.red;
    picture.rgba[offset + 1] = color.green;
    picture.rgba[offset + 2] = color.blue;
    picture.rgba[offset + 3] = color.alpha;
}

struct CellPaint {
    const TerrainFile* file = nullptr;
    const GridField* grid = nullptr;
    std::span<const SurfaceImage> brushes;
    const SurfaceImage* light = nullptr;
    int scale = 1;
};

void paint_texel(Picture& picture, const CellPaint& input, int column, int row) noexcept {
    const int cell_x = column / input.scale;
    const int cell_z = row / input.scale;
    const float along_x = (static_cast<float>(column % input.scale) + 0.5F) / static_cast<float>(input.scale);
    const float along_z = (static_cast<float>(row % input.scale) + 0.5F) / static_cast<float>(input.scale);
    const std::size_t cell = static_cast<std::size_t>(cell_z) * static_cast<std::size_t>(input.file->x_size) +
        static_cast<std::size_t>(cell_x);
    const Cell& ground = input.grid->cells[cell];
    const bool flip_diagonal = (ground.flags & kFlipDiagonal) != 0;
    Sampled color;
    if (!paint_layer(color, *input.file, ground.base, flip_diagonal, along_x, along_z, input.brushes)) {
        return;
    }
    color.alpha = 255;
    Sampled cover;
    if (paint_layer(cover, *input.file, ground.cover, flip_diagonal, along_x, along_z, input.brushes)) {
        color = blend_over(color, cover);
    }
    if (input.light != nullptr && image_ok(*input.light)) {
        const float across = static_cast<float>(cell_x) + along_x;
        const float down = static_cast<float>(cell_z) + along_z;
        const float light_u = across / static_cast<float>(input.file->x_size);
        const float light_v = 1.0F - (down / static_cast<float>(input.file->z_size));
        color = shade_light(color, sample_at(*input.light, light_u, light_v));
    }
    const std::size_t pixel = (static_cast<std::size_t>(row) * picture.width) + static_cast<std::size_t>(column);
    write_pixel(picture, pixel, color);
}

void paint_row(Picture& picture, const CellPaint& input, int row) noexcept {
    const int columns = input.file->x_size * input.scale;
    for (int column = 0; column < columns; ++column)
        paint_texel(picture, input, column, row);
}

// Một dải hàng. Mỗi hàng ghi vùng texel của riêng nó, nên nhiều dải chạy cùng lúc không đụng nhau.
struct RowBand {
    Picture* picture = nullptr;
    const CellPaint* input = nullptr;
    int first = 0;
    int last = 0;
};

void paint_band(const RowBand& band) {
    for (int row = band.first; row < band.last; ++row)
        paint_row(*band.picture, *band.input, row);
}

struct BandJob {
    RowBand band;
    void operator()(const std::stop_token&) const { paint_band(band); }
};

void launch_band(std::vector<std::jthread>& pool, RowBand band) {
    BandJob job;
    job.band = band;
    pool.emplace_back(job);
}

void paint_bands(Picture& picture, const CellPaint& input, int rows, unsigned workers) {
    const int span = rows / static_cast<int>(workers);
    std::vector<std::jthread> pool;
    pool.reserve(static_cast<std::size_t>(workers) - 1U);
    int first = 0;
    for (unsigned index = 0; index + 1U < workers; ++index) {
        RowBand band;
        band.picture = &picture;
        band.input = &input;
        band.first = first;
        band.last = first + span;
        launch_band(pool, band);
        first += span;
    }
    RowBand tail;
    tail.picture = &picture;
    tail.input = &input;
    tail.first = first;
    tail.last = rows;
    paint_band(tail);
}

// Để lại một lõi cho luồng vẽ. Ảnh nhỏ thì một luồng, khỏi trả giá tạo luồng.
void paint_rows(Picture& picture, const CellPaint& input, int rows) {
    const unsigned cores = std::thread::hardware_concurrency();
    const unsigned limit = cores > 1U ? cores - 1U : 1U;
    const unsigned workers = rows < 64 ? 1U : limit;
    if (workers == 1U) {
        RowBand band;
        band.picture = &picture;
        band.input = &input;
        band.last = rows;
        paint_band(band);
        return;
    }
    paint_bands(picture, input, rows, workers);
}

} // namespace

PixmapPoint pixmap_corner(const Pixmap& pixmap, CornerQuery query) noexcept {
    PixmapPoint point;
    if (query.corner < 0 || query.corner >= kCornerCount) return point;
    const int turn = query.orientation < kTurnCount ? static_cast<int>(query.orientation) : 0;
    const std::array<std::uint8_t, kTurnCount * kCornerCount>& table = query.flip_diagonal ? kFlipped : kStraight;
    const std::uint8_t packed = table[static_cast<std::size_t>(turn * kCornerCount + query.corner)];
    point.u = edge_of(pixmap, packed >> 4U);
    point.v = edge_of(pixmap, packed & 0x0FU);
    return point;
}

Picture paint_surface(const TerrainFile& file, const GridField& grid, SurfaceInputs inputs) {
    Picture picture;
    if (inputs.brushes.empty() || file.x_size <= 0 || file.z_size <= 0) return picture;
    const std::size_t cells = static_cast<std::size_t>(file.x_size) * static_cast<std::size_t>(file.z_size);
    if (grid.cells.size() < cells) return picture;
    const int scale = bake_scale(file);
    picture.width = static_cast<std::uint32_t>(file.x_size * scale);
    picture.height = static_cast<std::uint32_t>(file.z_size * scale);
    const std::size_t pixels = static_cast<std::size_t>(picture.width) * picture.height;
    picture.rgba.assign(pixels * 4U, 0);
    const CellPaint input{
        .file = &file, .grid = &grid, .brushes = inputs.brushes, .light = inputs.light, .scale = scale};
    const int rows = file.z_size * scale;
    paint_rows(picture, input, rows);
    return picture;
}

} // namespace game::client::map
