// Bảng góc là Terrain::_getPixmapCorner, cornerIndexMap[lật đường chéo][orientation][góc].
// Mỗi byte: nibble cao là cạnh U, nibble thấp là cạnh V. 0 trái, 1 trên, 2 phải, 3 dưới.
#include "client/map/surface.hpp"

#include "client/map/picture.hpp"
#include "client/map/terrain.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <span>
#include <stop_token>
#include <thread>
#include <utility>
#include <vector>

namespace game::client::map {
namespace {

constexpr int kTexelsPerCell = 16;
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

[[nodiscard]] int bake_scale(const TerrainFile& file, std::uint32_t max_edge) noexcept {
    const int side = std::max(file.x_size, file.z_size);
    if (side <= 0) return 1;
    int scale = kTexelsPerCell;
    while (std::cmp_greater(side * scale, max_edge) && scale > 1)
        scale /= 2;
    return scale;
}

[[nodiscard]] bool image_ok(const SurfaceImage& image) noexcept {
    const std::size_t need = static_cast<std::size_t>(image.width) * static_cast<std::size_t>(image.height) * 4U;
    return image.width > 0 && image.height > 0 && image.rgba.size() >= need;
}

// Tổng có trọng số của các điểm ảnh, kênh màu đã nhân alpha (thang 0..255): trộn tuyến tính được mà
// viền trong suốt của cọ không kéo màu đen vào, như bộ lọc của GPU với ảnh nhân sẵn alpha.
struct Premultiplied {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;
    float alpha = 0.0F;
};

struct Texel {
    std::uint32_t column = 0;
    std::uint32_t row = 0;
};

void accumulate(Premultiplied& sum, const SurfaceImage& image, Texel texel, float weight) noexcept {
    const std::size_t offset = ((static_cast<std::size_t>(texel.row) * image.width) + texel.column) * 4U;
    const float alpha = static_cast<float>(image.rgba[offset + 3]) / 255.0F;
    sum.red += static_cast<float>(image.rgba[offset]) * alpha * weight;
    sum.green += static_cast<float>(image.rgba[offset + 1]) * alpha * weight;
    sum.blue += static_cast<float>(image.rgba[offset + 2]) * alpha * weight;
    sum.alpha += static_cast<float>(image.rgba[offset + 3]) * weight;
}

// Lọc song tuyến, mép kẹp: tâm điểm ảnh ở nửa số nguyên, như lấy mẫu LINEAR của bản gốc.
[[nodiscard]] Premultiplied bilinear(const SurfaceImage& image, float u, float v) noexcept {
    const float across = (std::clamp(u, 0.0F, 1.0F) * static_cast<float>(image.width)) - 0.5F;
    const float down = (std::clamp(v, 0.0F, 1.0F) * static_cast<float>(image.height)) - 0.5F;
    const float floor_across = std::floor(across);
    const float floor_down = std::floor(down);
    const float along = across - floor_across;
    const float beside = down - floor_down;
    const auto last_column = static_cast<float>(image.width - 1);
    const auto last_row = static_cast<float>(image.height - 1);
    const auto column_at = [last_column](float value) { return static_cast<std::uint32_t>(std::clamp(value, 0.0F, last_column)); };
    const auto row_at = [last_row](float value) { return static_cast<std::uint32_t>(std::clamp(value, 0.0F, last_row)); };
    const std::uint32_t left = column_at(floor_across);
    const std::uint32_t right = column_at(floor_across + 1.0F);
    const std::uint32_t top = row_at(floor_down);
    const std::uint32_t bottom = row_at(floor_down + 1.0F);
    Premultiplied sum;
    accumulate(sum, image, Texel{.column = left, .row = top}, (1.0F - along) * (1.0F - beside));
    accumulate(sum, image, Texel{.column = right, .row = top}, along * (1.0F - beside));
    accumulate(sum, image, Texel{.column = left, .row = bottom}, (1.0F - along) * beside);
    accumulate(sum, image, Texel{.column = right, .row = bottom}, along * beside);
    return sum;
}

[[nodiscard]] Sampled finished(const Premultiplied& sum) noexcept {
    Sampled pixel;
    const float alpha = std::clamp(sum.alpha, 0.0F, 255.0F);
    pixel.alpha = static_cast<std::uint8_t>(std::lround(alpha));
    if (alpha <= 0.0F) return pixel;
    const float scale = 255.0F / alpha;
    const auto channel = [scale](float value) {
        return static_cast<std::uint8_t>(std::lround(std::clamp(value * scale, 0.0F, 255.0F)));
    };
    pixel.red = channel(sum.red);
    pixel.green = channel(sum.green);
    pixel.blue = channel(sum.blue);
    return pixel;
}

// Chuỗi mip của một ảnh cọ: mức 0 là ảnh gốc, mức sau là trung bình hộp 2 x 2 của mức trước (nhân alpha).
// Ảnh cọ nhỏ (tối đa 512 x 512) nên dựng một lần mỗi lượt nướng là rẻ.
struct Pyramid {
    std::vector<std::vector<std::uint8_t>> storage;
    std::vector<SurfaceImage> levels;
};

[[nodiscard]] std::vector<std::uint8_t> halved(const SurfaceImage& image, std::uint32_t width, std::uint32_t height) {
    std::vector<std::uint8_t> out(static_cast<std::size_t>(width) * height * 4U, 0);
    const auto last_column = image.width - 1U;
    const auto last_row = image.height - 1U;
    for (std::uint32_t row = 0; row < height; ++row) {
        for (std::uint32_t column = 0; column < width; ++column) {
            Premultiplied sum;
            const std::uint32_t first_column = std::min(column * 2U, last_column);
            const std::uint32_t first_row = std::min(row * 2U, last_row);
            const std::uint32_t next_column = std::min(first_column + 1U, last_column);
            const std::uint32_t next_row = std::min(first_row + 1U, last_row);
            accumulate(sum, image, Texel{.column = first_column, .row = first_row}, 0.25F);
            accumulate(sum, image, Texel{.column = next_column, .row = first_row}, 0.25F);
            accumulate(sum, image, Texel{.column = first_column, .row = next_row}, 0.25F);
            accumulate(sum, image, Texel{.column = next_column, .row = next_row}, 0.25F);
            const Sampled pixel = finished(sum);
            const std::size_t offset = ((static_cast<std::size_t>(row) * width) + column) * 4U;
            out[offset] = pixel.red;
            out[offset + 1] = pixel.green;
            out[offset + 2] = pixel.blue;
            out[offset + 3] = pixel.alpha;
        }
    }
    return out;
}

[[nodiscard]] Pyramid pyramid_of(const SurfaceImage& base) {
    Pyramid pyramid;
    if (!image_ok(base)) return pyramid;
    pyramid.levels.push_back(base);
    // Mỗi mức nhỏ một nửa tới 1 x 1: tối đa 14 mức cho ảnh 8192 cạnh; reserve để địa chỉ vùng nhớ không đổi.
    pyramid.storage.reserve(16);
    while (pyramid.levels.back().width > 1U || pyramid.levels.back().height > 1U) {
        const SurfaceImage& from = pyramid.levels.back();
        const std::uint32_t width = std::max(from.width / 2U, 1U);
        const std::uint32_t height = std::max(from.height / 2U, 1U);
        pyramid.storage.push_back(halved(from, width, height));
        SurfaceImage next;
        next.width = width;
        next.height = height;
        next.rgba = pyramid.storage.back();
        pyramid.levels.push_back(next);
    }
    return pyramid;
}

// Lọc tam tuyến ở mức lod (số thực, 0 là ảnh gốc): hai mức kề nhau trộn theo phần lẻ.
[[nodiscard]] Sampled sample_pyramid(const Pyramid& pyramid, PixmapPoint uv, float lod) noexcept {
    if (pyramid.levels.empty()) return {};
    const auto last = static_cast<float>(pyramid.levels.size() - 1U);
    const float level = std::clamp(lod, 0.0F, last);
    const float lower = std::floor(level);
    const float amount = level - lower;
    const auto low_index = static_cast<std::size_t>(lower);
    const std::size_t high_index = std::min(low_index + 1U, pyramid.levels.size() - 1U);
    Premultiplied sum = bilinear(pyramid.levels[low_index], uv.u, uv.v);
    if (amount > 0.0F && high_index != low_index) {
        const Premultiplied high = bilinear(pyramid.levels[high_index], uv.u, uv.v);
        sum.red += (high.red - sum.red) * amount;
        sum.green += (high.green - sum.green) * amount;
        sum.blue += (high.blue - sum.blue) * amount;
        sum.alpha += (high.alpha - sum.alpha) * amount;
    }
    return finished(sum);
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

struct LayerSource {
    std::span<const Pyramid> brushes;
    // Mức mip của từng pixmap của .Terrain: số điểm ảnh cọ mà một điểm ảnh nướng phủ, lấy log2.
    std::span<const float> lods;
};

[[nodiscard]] bool paint_layer(Sampled& pixel, const TerrainFile& file, const Layer& layer, bool flip_diagonal,
    PixmapPoint along, const LayerSource& source) noexcept {
    if (layer.pixmap == 0 || layer.pixmap > file.pixmaps.size()) return false;
    const std::size_t index = static_cast<std::size_t>(layer.pixmap) - 1U;
    const Pixmap& pixmap = file.pixmaps[index];
    if (pixmap.texture >= source.brushes.size() || source.brushes[pixmap.texture].levels.empty()) return false;
    const PixmapPoint uv = cell_uv(pixmap, layer, flip_diagonal, along.u, along.v);
    pixel = sample_pyramid(source.brushes[pixmap.texture], uv, source.lods[index]);
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
    LayerSource source;
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
    const PixmapPoint along{.u = along_x, .v = along_z};
    if (!paint_layer(color, *input.file, ground.base, flip_diagonal, along, input.source)) {
        return;
    }
    color.alpha = 255;
    Sampled cover;
    if (paint_layer(cover, *input.file, ground.cover, flip_diagonal, along, input.source)) {
        color = blend_over(color, cover);
    }
    if (input.light != nullptr && image_ok(*input.light)) {
        const float across = static_cast<float>(cell_x) + along_x;
        const float down = static_cast<float>(cell_z) + along_z;
        const float light_u = across / static_cast<float>(input.file->x_size);
        const float light_v = 1.0F - (down / static_cast<float>(input.file->z_size));
        color = shade_light(color, finished(bilinear(*input.light, light_u, light_v)));
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

namespace {

// Mức mip của từng pixmap: một điểm ảnh nướng phủ (cạnh pixmap trong ảnh cọ) / scale điểm ảnh cọ; lấy cạnh lớn
// hơn của hai trục, log2, không âm. Pixmap trỏ tới cọ không có thì mức 0.
[[nodiscard]] std::vector<float> lods_of(const TerrainFile& file, std::span<const SurfaceImage> brushes, int scale) {
    std::vector<float> lods(file.pixmaps.size(), 0.0F);
    for (std::size_t index = 0; index < file.pixmaps.size(); ++index) {
        const Pixmap& pixmap = file.pixmaps[index];
        if (pixmap.texture >= brushes.size() || !image_ok(brushes[pixmap.texture])) continue;
        const SurfaceImage& brush = brushes[pixmap.texture];
        const float across = std::fabs(pixmap.right - pixmap.left) * static_cast<float>(brush.width);
        const float down = std::fabs(pixmap.bottom - pixmap.top) * static_cast<float>(brush.height);
        const float footprint = std::max(across, down) / static_cast<float>(scale);
        lods[index] = footprint > 1.0F ? std::log2(footprint) : 0.0F;
    }
    return lods;
}

} // namespace

Picture paint_surface(const TerrainFile& file, const GridField& grid, SurfaceInputs inputs) {
    Picture picture;
    if (inputs.brushes.empty() || file.x_size <= 0 || file.z_size <= 0) return picture;
    const std::size_t cells = static_cast<std::size_t>(file.x_size) * static_cast<std::size_t>(file.z_size);
    if (grid.cells.size() < cells) return picture;
    const int scale = bake_scale(file, std::max(inputs.max_edge, 1U));
    picture.width = static_cast<std::uint32_t>(file.x_size * scale);
    picture.height = static_cast<std::uint32_t>(file.z_size * scale);
    const std::size_t pixels = static_cast<std::size_t>(picture.width) * picture.height;
    picture.rgba.assign(pixels * 4U, 0);
    std::vector<Pyramid> pyramids;
    pyramids.reserve(inputs.brushes.size());
    for (const SurfaceImage& brush : inputs.brushes)
        pyramids.push_back(pyramid_of(brush));
    const std::vector<float> lods = lods_of(file, inputs.brushes, scale);
    const CellPaint input{.file = &file,
        .grid = &grid,
        .source = LayerSource{.brushes = pyramids, .lods = lods},
        .light = inputs.light,
        .scale = scale};
    const int rows = file.z_size * scale;
    paint_rows(picture, input, rows);
    return picture;
}

} // namespace game::client::map
