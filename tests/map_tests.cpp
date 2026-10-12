// Test map: XML .Terrain theo serializer gốc, byte FEHM/FEGI, ảnh minimap và chiều tam giác +Y.
#include "client/map/book.hpp"
#include "client/map/gates.hpp"
#include "client/map/ground.hpp"
#include "client/map/liquid.hpp"
#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/sheet.hpp"
#include "client/map/surface.hpp"
#include "client/map/terrain.hpp"
#include "core/check.hpp"
#include "test.hpp"

#ifdef GAME_CLIENT_DATA
#include "io/file.hpp"
#endif

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#ifdef GAME_CLIENT_DATA
#include <filesystem>
#endif
#include <iterator>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

constexpr std::string_view kTerrain =
    "<Terrain name=\"nho\" tileSize=\"32\" xsize=\"128\" zsize=\"128\">\n"
    "  <scale x=\"100\" y=\"100\" z=\"100\"/>\n"
    "  <centre x=\"-3200\" y=\"0\" z=\"-3200\"/>\n"
    "  <heightmap filename=\"nho.Heightmap\" type=\"standard\"/>\n"
    "  <gridInfo filename=\"nho.GridInfo\" type=\"standard\"/>\n"
    "  <position x=\"3\" y=\"4\" z=\"5\"/>\n"
    "</Terrain>\n";

constexpr std::string_view kCentreOnly =
    "<Terrain name=\"nho\" tileSize=\"32\" xsize=\"128\" zsize=\"128\">\n"
    "  <scale x=\"100\" y=\"100\" z=\"100\"/>\n"
    "  <centre x=\"-3200\" y=\"2\" z=\"-3200\"/>\n"
    "</Terrain>\n";

void put_u32(std::string& out, std::uint32_t value) {
    std::array<char, 4> bytes{};
    std::memcpy(bytes.data(), &value, sizeof value);
    out.append(bytes.data(), bytes.size());
}

void put_f32(std::string& out, float value) {
    std::array<char, 4> bytes{};
    std::memcpy(bytes.data(), &value, sizeof value);
    out.append(bytes.data(), bytes.size());
}

[[nodiscard]] std::string height_bytes() {
    std::string bytes;
    put_u32(bytes, 0x4645484DU);
    put_u32(bytes, 0x00100000U);
    put_u32(bytes, 2);
    put_u32(bytes, 2);
    put_f32(bytes, 0.0F);
    put_f32(bytes, 0.0F);
    put_f32(bytes, 0.0F);
    put_f32(bytes, 0.0F);
    return bytes;
}

[[nodiscard]] std::string grid_bytes(std::uint8_t pixmap, std::uint8_t flags) {
    std::string bytes;
    put_u32(bytes, 0x46454749U);
    put_u32(bytes, 0x00100002U);
    put_u32(bytes, 1);
    put_u32(bytes, 1);
    bytes.push_back(0);
    bytes.push_back(static_cast<char>(pixmap));
    bytes.push_back(0);
    bytes.push_back(0);
    bytes.push_back(0);
    bytes.push_back(static_cast<char>(flags));
    return bytes;
}

[[nodiscard]] client::map::TerrainFile one_cell() {
    client::map::TerrainFile file;
    file.x_size = 1;
    file.z_size = 1;
    file.tile_size = 32;
    file.scale = scene::Vector3{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    return file;
}

void terrain_origin_matches_original(Context& context) {
    const client::map::TerrainResult file = client::map::read_terrain(kCentreOnly);
    context.expect(file.has_value(), "đọc được");
    if (!file) return;
    context.expect(file->name == "nho", "tên");
    context.expect(file->origin.x == -9600.0F, "gốc x = tâm - nửa cạnh");
    context.expect(file->origin.y == 2.0F, "gốc y lấy tâm");
    context.expect(file->origin.z == -9600.0F, "gốc z");
    context.expect(file->heightmap.empty(), "không có heightmap");
    const client::map::TerrainResult overwritten = client::map::read_terrain(kTerrain);
    context.expect(overwritten.has_value(), "bản có position đọc được");
    if (!overwritten) return;
    const scene::Vector3 placed{.x = 3.0F, .y = 4.0F, .z = 5.0F};
    context.expect(overwritten->origin == placed, "position ghi đè centre");
}

void terrain_rejects_bad_documents(Context& context) {
    const client::map::TerrainResult other = client::map::read_terrain("<Scene/>");
    context.expect(
        !other && other.error() == client::map::MapError::kNotTerrain, "không phải Terrain");
    const client::map::TerrainResult broken = client::map::read_terrain("<Terrain>");
    context.expect(!broken && broken.error() == client::map::MapError::kBadXml, "XML hỏng");
    const client::map::TerrainResult huge =
        client::map::read_terrain(R"(<Terrain tileSize="1" xsize="3000" zsize="1"/>)");
    context.expect(!huge && huge.error() == client::map::MapError::kBadSize, "quá trần 2048");
}

constexpr std::string_view kUntypedHeight =
    "<Terrain name=\"nho\" tileSize=\"32\" xsize=\"128\" zsize=\"128\">\n"
    "  <heightmap filename=\"nho.Heightmap\"/>\n"
    "</Terrain>\n";

constexpr std::string_view kImageHeight =
    "<Terrain name=\"nho\" tileSize=\"32\" xsize=\"128\" zsize=\"128\">\n"
    "  <heightmap filename=\"nho.png\" type=\"image\"/>\n"
    "</Terrain>\n";

void terrain_height_type_defaults_to_standard(Context& context) {
    const client::map::TerrainResult bare = client::map::read_terrain(kCentreOnly);
    context.expect(bare && bare->height_type == "standard", "không có heightmap vẫn là standard");
    const client::map::TerrainResult untyped = client::map::read_terrain(kUntypedHeight);
    context.expect(untyped && untyped->height_type == "standard", "vắng type là standard");
    const client::map::TerrainResult typed = client::map::read_terrain(kImageHeight);
    context.expect(typed && typed->height_type == "image", "có type thì giữ chuỗi của tệp");
}

void height_and_grid_follow_original_layout(Context& context) {
    const std::string heights = height_bytes();
    const client::map::GridSpan span{.columns = 1, .rows = 1};
    const client::map::HeightResult field = client::map::read_heightmap(heights, span);
    context.expect(field.has_value(), "heightmap 2x2 điểm");
    if (!field) return;
    context.expect(field->samples.size() == 4, "bốn điểm");
    context.expect(field->samples.front() == 0.0F, "điểm đầu");
    std::string bad = heights;
    bad.push_back('\0');
    const client::map::HeightResult extra = client::map::read_heightmap(bad, span);
    context.expect(!extra && extra.error() == client::map::MapError::kBadHeight, "thừa byte");
    const std::string cells = grid_bytes(1, client::map::kFlipDiagonal);
    const client::map::GridResult grid = client::map::read_grid(cells, span, 1);
    context.expect(grid.has_value(), "grid một ô");
    if (!grid) return;
    context.expect(grid->cells[0].base.pixmap == 1, "pixmap nền");
    context.expect(grid->cells[0].flags == client::map::kFlipDiagonal, "cờ lật chéo");
    const client::map::GridResult missing = client::map::read_grid(grid_bytes(2, 0), span, 1);
    context.expect(
        !missing && missing.error() == client::map::MapError::kBadGrid, "pixmap vượt số ảnh");
}

[[nodiscard]] bool same_order(
    const std::vector<std::uint32_t>& got, const std::array<std::uint32_t, 6>& want) {
    return got.size() == want.size() && std::equal(got.begin(), got.end(), want.begin());
}

[[nodiscard]] client::map::Corner corner_nth(const client::map::Sheet& sheet, std::ptrdiff_t nth) {
    const auto index = *std::next(sheet.indices.begin(), nth);
    return *std::next(sheet.corners.begin(), static_cast<std::ptrdiff_t>(index));
}

[[nodiscard]] float facing_of(const client::map::Sheet& sheet) {
    const client::map::Corner first = corner_nth(sheet, 0);
    const client::map::Corner second = corner_nth(sheet, 1);
    const client::map::Corner third = corner_nth(sheet, 2);
    const float edge_x = second.x - first.x;
    const float edge_z = second.z - first.z;
    const float other_x = third.x - first.x;
    const float other_z = third.z - first.z;
    return (edge_z * other_x) - (edge_x * other_z);
}

void sheet_faces_up_and_skips_holes(Context& context) {
    const client::map::TerrainFile file = one_cell();
    const std::string heights_bytes = height_bytes();
    const client::map::GridSpan span{.columns = 1, .rows = 1};
    const client::map::HeightResult heights = client::map::read_heightmap(heights_bytes, span);
    context.expect(heights.has_value(), "độ cao");
    if (!heights) return;
    const std::string solid_bytes = grid_bytes(1, 0);
    const std::string flip_bytes = grid_bytes(1, client::map::kFlipDiagonal);
    const std::string hole_bytes = grid_bytes(0, 0);
    const client::map::GridResult solid = client::map::read_grid(solid_bytes, span, 1);
    const client::map::GridResult flipped = client::map::read_grid(flip_bytes, span, 1);
    const client::map::GridResult hole = client::map::read_grid(hole_bytes, span, 1);
    context.expect(solid.has_value() && flipped.has_value() && hole.has_value(), "ba lưới");
    if (!solid || !flipped || !hole) return;
    const client::map::Sheet sheet = client::map::build_sheet(file, *heights, *solid);
    context.expect(sheet.corners.size() == 4, "bốn góc");
    context.expect(sheet.corners.front().normal_y == 1.0F, "mặt phẳng pháp tuyến lên");
    const std::array<std::uint32_t, 6> plain{1, 0, 2, 1, 2, 3};
    context.expect(same_order(sheet.indices, plain), "không lật: góc 1, 0, 2 rồi 1, 2, 3");
    context.expect(facing_of(sheet) > 0.0F, "tích có hướng hướng lên");
    const client::map::Sheet turned = client::map::build_sheet(file, *heights, *flipped);
    const std::array<std::uint32_t, 6> diagonal{0, 2, 3, 0, 3, 1};
    context.expect(same_order(turned.indices, diagonal), "lật: góc 0, 2, 3 rồi 0, 3, 1");
    const client::map::Sheet empty = client::map::build_sheet(file, *heights, *hole);
    context.expect(empty.indices.empty(), "lỗ không sinh mặt");
    const client::map::Picture picture = client::map::paint_overview(file, *heights, *hole);
    context.expect(picture.width == 1 && picture.height == 1, "một điểm ảnh");
    context.expect(picture.rgba.size() == 4 && picture.rgba.back() == 0, "lỗ trong suốt");
}

void book_keeps_active_rows_and_skips_spares(Context& context) {
    constexpr std::string_view kTable =
        "INT\tSTRING\tINT\tINT\tSTRING\n"
        "#0\tPhu\t1\t1\told.Scene\n"
        "0\tLacDuong\t320\t320\tluoyang.Scene\ta.path\ta.col\ta.jpg\n"
        "251\tHoaYen\t128\t128\thuoyangu.Scene\n";
    const client::map::BookResult book = client::map::read_book(kTable);
    context.expect(book.has_value(), "bảng đọc được");
    if (!book) return;
    context.expect(book->rows.size() == 2, "bỏ dòng đầu và dòng #");
    const client::map::SceneRef* flame = client::map::find_id(*book, 251);
    context.expect(
        flame != nullptr && client::map::file_of(*book, *flame) == "huoyangu.Scene", "resid 251");
    const client::map::SceneRef* by_name = client::map::find_scene(*book, "HUOYANGU");
    context.expect(by_name == flame, "tìm theo tên không đuôi");
    context.expect(client::map::find_id(*book, 9) == nullptr, "resid lạ");
    context.expect(!client::map::read_book("INT\tSTRING\n").has_value(), "bảng rỗng là lỗi");
}

// Cột thứ 11 của bảng cảnh (szSceneMap) là token ảnh minimap; dòng ngắn hơn thì không có.
void book_reads_radar_token(Context& context) {
    constexpr std::string_view kTable =
        "0\tLacDuong\t320\t320\tluoyang.Scene\ta.path\ta.col\ta.jpg\t18\t60000\tluoyang_SP\t590\n"
        "251\tHoaYen\t128\t128\thuoyangu.Scene\ta.path\ta.col\ta.jpg\t122\t60000\thuoyangu\n"
        "7\tNgan\t64\t64\tshort.Scene\ta.path\n"
        "8\tLa\t64\t64\todd.Scene\ta.path\ta.col\ta.jpg\t1\t2\t../ngoai\n";
    const client::map::BookResult book = client::map::read_book(kTable);
    context.expect(book.has_value() && book->rows.size() == 4, "bốn dòng dùng được");
    if (!book || book->rows.size() != 4) return;
    const client::map::SceneRef* capital = client::map::find_id(*book, 0);
    const client::map::SceneRef* flame = client::map::find_id(*book, 251);
    const client::map::SceneRef* brief = client::map::find_id(*book, 7);
    const client::map::SceneRef* odd = client::map::find_id(*book, 8);
    if (capital == nullptr || flame == nullptr || brief == nullptr || odd == nullptr) return;
    context.expect(client::map::radar_of(*book, *capital) == "luoyang_SP", "token giữa dòng");
    context.expect(client::map::radar_of(*book, *flame) == "huoyangu", "token ở cuối dòng");
    context.expect(client::map::radar_of(*book, *brief).empty(), "dòng thiếu cột thì rỗng");
    context.expect(client::map::radar_of(*book, *odd).empty(), "token có dấu gạch chéo thì bỏ");
}

// Cột thứ 16 và 17 là mặt cắt xa và gần của camera cảnh; thiếu hay sai thì 15000 và 10.
void book_reads_clip_planes(Context& context) {
    constexpr std::string_view kTable =
        "3	Nui	320	320	a.Scene	a.path	a.col	a.jpg	1	6	nui	1	2	3	4	25000	20	Sign
"
        "4	Ngan	64	64	b.Scene	a.path	a.col	a.jpg	1	6	ngan	1	2	3	4
"
        "5	Sai	64	64	c.Scene	a.path	a.col	a.jpg	1	6	sai	1	2	3	4	10	10
"
        "6	Am	64	64	d.Scene	a.path	a.col	a.jpg	1	6	am	1	2	3	4	9000	-1
";
    const client::map::BookResult book = client::map::read_book(kTable);
    context.expect(book.has_value() && book->rows.size() == 4, "bốn dòng dùng được");
    if (!book || book->rows.size() != 4) return;
    const client::map::SceneRef* hill = client::map::find_id(*book, 3);
    const client::map::SceneRef* brief = client::map::find_id(*book, 4);
    const client::map::SceneRef* equal = client::map::find_id(*book, 5);
    const client::map::SceneRef* minus = client::map::find_id(*book, 6);
    if (hill == nullptr || brief == nullptr || equal == nullptr || minus == nullptr) return;
    context.expect(hill->far_clip == 25000 && hill->near_clip == 20, "đọc hai cột");
    context.expect(brief->far_clip == 15000 && brief->near_clip == 10, "dòng thiếu cột: mặc định");
    context.expect(equal->far_clip == 15000 && equal->near_clip == 10, "gần bằng xa: mặc định");
    context.expect(minus->far_clip == 15000 && minus->near_clip == 10, "số âm: mặc định");
}

void pixmap_corner_follows_original_table(Context& context) {
    client::map::Pixmap pixmap;
    pixmap.left = 0.25F;
    pixmap.top = 0.10F;
    pixmap.right = 0.75F;
    pixmap.bottom = 0.90F;
    client::map::CornerQuery query;
    const client::map::PixmapPoint natural = client::map::pixmap_corner(pixmap, query);
    context.expect(natural.u == 0.25F && natural.v == 0.10F, "góc 0 là trái-trên");
    query.corner = 3;
    const client::map::PixmapPoint far = client::map::pixmap_corner(pixmap, query);
    context.expect(far.u == 0.75F && far.v == 0.90F, "góc 3 là phải-dưới");
    query.corner = 0;
    query.orientation = 1;
    const client::map::PixmapPoint flipped = client::map::pixmap_corner(pixmap, query);
    context.expect(flipped.u == 0.75F && flipped.v == 0.10F, "lật ngang đổi trái phải");
}

void surface_paints_the_base_brush(Context& context) {
    client::map::TerrainFile file;
    file.x_size = 1;
    file.z_size = 1;
    client::map::Pixmap pixmap;
    pixmap.left = 0.0F;
    pixmap.top = 0.0F;
    pixmap.right = 1.0F;
    pixmap.bottom = 1.0F;
    file.pixmaps.push_back(pixmap);
    client::map::Cell cell;
    cell.base.pixmap = 1;
    client::map::GridField grid;
    grid.cells.push_back(cell);
    const std::array<std::uint8_t, 16> red{
        200, 10, 10, 255, 200, 10, 10, 255, 200, 10, 10, 255, 200, 10, 10, 255};
    client::map::SurfaceImage brush;
    brush.width = 2;
    brush.height = 2;
    brush.rgba = red;
    const std::array<client::map::SurfaceImage, 1> brushes{brush};
    client::map::SurfaceInputs inputs;
    inputs.brushes = brushes;
    const client::map::Picture painted = client::map::paint_surface(file, grid, inputs);
    context.expect(painted.width == 8 && painted.height == 8, "tám điểm mỗi ô");
    context.expect(!painted.rgba.empty() && painted.rgba[0] == 200, "cọ đỏ");
    context.expect(painted.rgba[3] == 255, "ô có nền thì đặc");
}

void liquid_covers_the_pool_and_stays_flat(Context& context) {
    client::map::TerrainFile terrain;
    terrain.x_size = 1;
    terrain.z_size = 1;
    terrain.scale = {.x = 100.0F, .y = 100.0F, .z = 100.0F};
    client::map::HeightField heights;
    heights.samples = {0.0F, 0.0F, 0.0F, 0.0F};
    client::map::GridField grid;
    grid.cells.emplace_back();
    client::map::LiquidField field;
    field.terrain = &terrain;
    field.heights = &heights;
    field.grid = &grid;
    field.place.x = 50.0F;
    field.place.y = 10.0F;
    field.place.z = 50.0F;
    field.place.texture_scale = 0.3F;
    const client::map::LiquidSheet wet = client::map::build_liquid(field);
    context.expect(wet.indices.size() == 6, "ô chìm là hai tam giác");
    context.expect(!wet.points.empty() && wet.points.front().y == 10.0F, "mặt ở cao độ đặt");
    const client::map::LiquidPoint& corner = wet.points[wet.indices[0]];
    const client::map::LiquidPoint& left = wet.points[wet.indices[1]];
    const client::map::LiquidPoint& right = wet.points[wet.indices[2]];
    const float edge_x = left.x - corner.x;
    const float edge_z = left.z - corner.z;
    const float other_x = right.x - corner.x;
    const float other_z = right.z - corner.z;
    const float normal_y = (edge_z * other_x) - (edge_x * other_z);
    context.expect(normal_y > 0.0F, "pháp tuyến hướng lên");
    field.place.y = -1.0F;
    const client::map::LiquidSheet dry = client::map::build_liquid(field);
    context.expect(dry.indices.empty(), "cao hơn mọi đỉnh thì không có mặt");
}

// Cảnh nhỏ nhất có nước: một ô đất 100 x 100 phẳng ở độ cao 0.
struct Pond {
    client::map::TerrainFile terrain;
    client::map::HeightField heights;
    client::map::GridField grid;
};

[[nodiscard]] Pond flat_pond() {
    Pond pond;
    pond.terrain.x_size = 1;
    pond.terrain.z_size = 1;
    pond.terrain.scale = {.x = 100.0F, .y = 100.0F, .z = 100.0F};
    pond.heights.samples = {0.0F, 0.0F, 0.0F, 0.0F};
    pond.grid.cells.emplace_back();
    return pond;
}

// Mặt nước đặt giữa ô ở mực level. Trỏ vào pond nên pond phải sống lâu hơn.
[[nodiscard]] client::map::LiquidField liquid_at(const Pond& pond, float level) {
    client::map::LiquidField field;
    field.terrain = &pond.terrain;
    field.heights = &pond.heights;
    field.grid = &pond.grid;
    field.place.x = 50.0F;
    field.place.y = level;
    field.place.z = 50.0F;
    return field;
}

void water_cover_keeps_the_higher_level(Context& context) {
    const Pond pond = flat_pond();
    client::map::WaterCover cover = client::map::water_cover(pond.terrain);
    const client::map::LiquidField shallow = liquid_at(pond, 10.0F);
    client::map::pour_liquid(cover, shallow);
    const std::optional<float> level = client::map::water_at(cover, 50.0F, 50.0F);
    context.expect(level.has_value() && *level == 10.0F, "ô chìm có mực 10");
    const std::optional<float> edge = client::map::water_at(cover, 1000.0F, -20.0F);
    context.expect(edge.has_value() && *edge == 10.0F, "ngoài bản đồ kẹp vào ô biên");
    const client::map::LiquidField deep = liquid_at(pond, 25.0F);
    client::map::pour_liquid(cover, deep);
    const std::optional<float> higher = client::map::water_at(cover, 50.0F, 50.0F);
    context.expect(higher.has_value() && *higher == 25.0F, "hai mặt chồng lấy mực cao");
    client::map::WaterCover barren = client::map::water_cover(pond.terrain);
    const client::map::LiquidField buried = liquid_at(pond, -1.0F);
    client::map::pour_liquid(barren, buried);
    const std::optional<float> dry_level = client::map::water_at(barren, 50.0F, 50.0F);
    context.expect(!dry_level, "không có tam giác thì không có nước");
}

void water_ray_matches_nav_collider(Context& context) {
    const Pond pond = flat_pond();
    client::map::WaterCover cover = client::map::water_cover(pond.terrain);
    const client::map::LiquidField shallow = liquid_at(pond, 10.0F);
    client::map::pour_liquid(cover, shallow);
    client::map::WaterRay falling;
    falling.origin_x = 50.0F;
    falling.origin_y = 100.0F;
    falling.origin_z = 50.0F;
    falling.direction_y = -1.0F;
    falling.reach = 200.0F;
    const std::optional<client::map::WaterHit> hit = client::map::ray_water(cover, falling);
    context.expect(hit.has_value(), "tia xuống cắt mặt nước");
    if (hit) context.expect(hit->y == 10.0F && hit->x == 50.0F, "chạm tại bước y <= mực");
    falling.reach = 50.0F;
    context.expect(!client::map::ray_water(cover, falling), "len < reach nên chưa tới mặt");
}

void liquid_look_matches_the_named_material(Context& context) {
    constexpr std::string_view kScript = "material magma11\n{\n}\nmaterial magma1\n{\n"
                                         "scene_blend alpha_blend\nanim_texture lava.dds 14 1.5\n"
                                         "scroll 0 -10.9888\nscroll_anim 0 0.02\n}\n";
    const client::map::LiquidLookResult look = client::map::find_liquid_look(kScript, "magma1");
    context.expect(look.has_value(), "đúng tên, không lấy tên dài hơn");
    if (!look) return;
    context.expect(look->texture == "lava.dds" && look->frames == 14, "ảnh chạy 14 khung");
    context.expect(look->blends, "trộn alpha");
    context.expect(look->scroll_v < -10.0F && look->speed_v > 0.0F, "cuộn và tốc độ cuộn");
    context.expect(
        !client::map::find_liquid_look(kScript, "magma").has_value(), "thiếu tên thì rỗng");
}

void minimap_frame_matches_desktop_layout(Context& context) {
    const client::map::Frame area = client::map::minimap_area(1280.0F);
    context.expect(area.x == 1123.5F, "cách mép phải 156.5");
    context.expect(area.y == 42.0F, "cách mép trên 42");
    context.expect(area.width == 119.0F && area.height == 121.0F, "cỡ MapArea");
    const client::map::GroundResult missing =
        client::map::load_ground("khong-co-thu-muc-nay", "khong-co.Terrain");
    context.expect(!missing && missing.error() == client::map::MapError::kMissingFile, "thiếu tệp");
    context.expect(!client::map::describe(client::map::MapError::kBadGrid).empty(), "có câu lỗi");
}

[[nodiscard]] client::map::Gate dunhuang_gate() {
    client::map::Gate gate;
    gate.id = 1;
    gate.source_scene = 0;
    gate.source_x = 85;
    gate.source_z = 257;
    gate.dest_scene = 8;
    gate.dest_x = 284;
    gate.dest_z = 146;
    gate.field_nine = 0;
    gate.field_ten = 1;
    gate.field_eleven = 0;
    return gate;
}

[[nodiscard]] client::map::Gate later_dunhuang() {
    client::map::Gate gate = dunhuang_gate();
    gate.id = 9;
    gate.source_x = 1;
    gate.source_z = 1;
    gate.dest_x = 2;
    gate.dest_z = 2;
    return gate;
}

[[nodiscard]] client::map::Gate valley_gate() {
    client::map::Gate gate;
    gate.id = 2;
    gate.source_scene = 244;
    gate.source_x = 26;
    gate.source_z = 103;
    gate.dest_scene = 251;
    gate.dest_x = 68;
    gate.dest_z = 23;
    gate.field_nine = 0;
    gate.field_ten = 0;
    gate.field_eleven = 90;
    return gate;
}

[[nodiscard]] client::map::Gate mountain_gate() {
    client::map::Gate gate;
    gate.id = 3;
    gate.source_scene = 251;
    gate.source_x = 68;
    gate.source_z = 23;
    gate.dest_scene = 244;
    gate.dest_x = 26;
    gate.dest_z = 103;
    gate.field_nine = 0;
    gate.field_ten = 1;
    gate.field_eleven = 90;
    return gate;
}

[[nodiscard]] client::map::Gate other_valley() {
    client::map::Gate gate = valley_gate();
    gate.id = 4;
    gate.source_scene = 1;
    gate.source_x = 1;
    gate.source_z = 1;
    gate.dest_x = 10;
    gate.dest_z = 11;
    return gate;
}

void write_types(std::string& bytes) {
    const std::array<std::uint32_t, 12> kinds{0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0};
    for (const std::uint32_t kind : kinds)
        put_u32(bytes, kind);
}

void write_gate(std::string& bytes, const client::map::Gate& gate) {
    put_u32(bytes, static_cast<std::uint32_t>(gate.id));
    put_u32(bytes, 0);
    put_u32(bytes, static_cast<std::uint32_t>(gate.source_scene));
    put_u32(bytes, static_cast<std::uint32_t>(gate.source_x));
    put_u32(bytes, static_cast<std::uint32_t>(gate.source_z));
    put_u32(bytes, 0);
    put_u32(bytes, static_cast<std::uint32_t>(gate.dest_scene));
    put_u32(bytes, static_cast<std::uint32_t>(gate.dest_x));
    put_u32(bytes, static_cast<std::uint32_t>(gate.dest_z));
    put_u32(bytes, static_cast<std::uint32_t>(gate.field_nine));
    put_u32(bytes, static_cast<std::uint32_t>(gate.field_ten));
    put_u32(bytes, static_cast<std::uint32_t>(gate.field_eleven));
}

[[nodiscard]] std::string gate_bytes(std::span<const client::map::Gate> rows) {
    std::string bytes;
    put_u32(bytes, 0xDDBBCC00U);
    put_u32(bytes, 12);
    put_u32(bytes, static_cast<std::uint32_t>(rows.size()));
    put_u32(bytes, 1);
    write_types(bytes);
    for (const client::map::Gate& gate : rows)
        write_gate(bytes, gate);
    bytes.push_back('\0');
    return bytes;
}

[[nodiscard]] client::map::GateResult sample_table() {
    std::vector<client::map::Gate> rows;
    const client::map::Gate dunhuang = dunhuang_gate();
    const client::map::Gate valley = valley_gate();
    const client::map::Gate mountain = mountain_gate();
    rows.push_back(dunhuang);
    rows.push_back(valley);
    rows.push_back(mountain);
    const std::string bytes = gate_bytes(rows);
    return client::map::read_gates(bytes);
}

void gate_table_rejects_a_bad_file(Context& context) {
    const client::map::GateResult empty = client::map::read_gates({});
    context.expect(!empty, "tệp rỗng không phải DBC");
    if (empty) return;
    context.expect(empty.error() == client::map::GateError::kBadMagic, "magic sai");
    std::string bytes;
    put_u32(bytes, 0xDDBBCC00U);
    put_u32(bytes, 12);
    put_u32(bytes, 5);
    put_u32(bytes, 1);
    const client::map::GateResult short_file = client::map::read_gates(bytes);
    context.expect(!short_file, "bản ghi khai không đủ");
    if (short_file) return;
    context.expect(short_file.error() == client::map::GateError::kBadShape, "lệch cỡ");
    const std::string_view magic = client::map::describe(client::map::GateError::kBadMagic);
    context.expect(!magic.empty(), "có câu lỗi");
}

void gate_table_rejects_an_empty_string_block(Context& context) {
    std::string bytes;
    put_u32(bytes, 0xDDBBCC00U);
    put_u32(bytes, 12);
    put_u32(bytes, 0);
    put_u32(bytes, 0);
    const client::map::GateResult table = client::map::read_gates(bytes);
    context.expect(!table, "khối chuỗi rỗng");
    if (table) return;
    context.expect(table.error() == client::map::GateError::kBadShape, "cỡ khối chuỗi");
}

void gate_table_rejects_a_wrong_type(Context& context) {
    std::vector<client::map::Gate> rows;
    const client::map::Gate gate = dunhuang_gate();
    rows.push_back(gate);
    std::string bytes = gate_bytes(rows);
    bytes[16] = 1;
    const client::map::GateResult table = client::map::read_gates(bytes);
    context.expect(!table, "sai kiểu cột");
    if (table) return;
    context.expect(table.error() == client::map::GateError::kBadShape, "kiểu cột không phải INT");
}

void gate_table_keeps_a_trailing_byte(Context& context) {
    std::vector<client::map::Gate> rows;
    const client::map::Gate gate = dunhuang_gate();
    rows.push_back(gate);
    std::string bytes = gate_bytes(rows);
    bytes.push_back('x');
    const client::map::GateResult table = client::map::read_gates(bytes);
    context.expect(table.has_value(), "byte thừa sau khối chuỗi vẫn nhận");
    if (!table) return;
    context.expect(table->size() == 1, "một cổng");
    context.expect(table->front().dest_x == 284, "x đến còn nguyên");
    context.expect(table->front().dest_z == 146, "z đến còn nguyên");
}

void valley_gate_matches_the_client(Context& context) {
    const client::map::GateResult table = sample_table();
    context.expect(table.has_value(), "bảng mẫu");
    if (!table) return;
    client::map::GateEnds to_valley;
    to_valley.source_scene = 244;
    to_valley.dest_scene = 251;
    const client::map::Gate* valley = client::map::find_gate(*table, to_valley);
    context.expect(valley != nullptr, "có cửa sang cốc");
    if (valley == nullptr) return;
    context.expect(valley->source_x == 26, "x đi 26");
    context.expect(valley->source_z == 103, "z đi 103");
    context.expect(valley->dest_x == 68, "x đến 68");
    context.expect(valley->dest_z == 23, "z đến 23");
    context.expect(valley->field_nine == 0, "cột 9 là 0");
    context.expect(valley->field_ten == 0, "cột 10 là 0");
    context.expect(valley->field_eleven == 90, "cột 11 là 90");
    client::map::GateEnds back;
    back.source_scene = 251;
    back.dest_scene = 244;
    const client::map::Gate* mountain = client::map::find_gate(*table, back);
    context.expect(mountain != nullptr, "có cửa về núi");
    if (mountain == nullptr) return;
    context.expect(mountain->source_x == 68, "về núi đi từ x 68");
    context.expect(mountain->source_z == 23, "về núi đi từ z 23");
    context.expect(mountain->dest_x == 26, "về núi đến x 26");
    context.expect(mountain->dest_z == 103, "về núi đến z 103");
    context.expect(mountain->field_ten == 1, "cột 10 của cửa về là 1");
}

void luoyang_query_uses_scene_zero(Context& context) {
    std::vector<client::map::Gate> rows;
    const client::map::Gate first = dunhuang_gate();
    const client::map::Gate later = later_dunhuang();
    rows.push_back(first);
    rows.push_back(later);
    const std::string bytes = gate_bytes(rows);
    const client::map::GateResult table = client::map::read_gates(bytes);
    context.expect(table.has_value(), "bảng hai dòng cùng cửa");
    if (!table) return;
    client::map::GateEnds mirror;
    mirror.source_scene = client::map::kLuoyangMirror;
    mirror.dest_scene = 8;
    const client::map::Gate* gate = client::map::find_gate(*table, mirror);
    context.expect(gate != nullptr, "242 sang 8 có cửa");
    if (gate == nullptr) return;
    context.expect(gate->id == 1, "lấy dòng đầu, không lấy dòng sau");
    context.expect(gate->source_x == 85, "x đi của dòng đầu");
    context.expect(gate->source_z == 257, "z đi của dòng đầu");
    client::map::GateEnds folded;
    folded.source_scene = client::map::kLuoyangMirror;
    folded.dest_scene = 0;
    const client::map::Gate* same = client::map::find_gate(*table, folded);
    context.expect(same == nullptr, "242 sang 0 là cùng cảnh");
    client::map::GateEnds reverse;
    reverse.source_scene = 0;
    reverse.dest_scene = client::map::kLuoyangMirror;
    const client::map::Gate* flipped = client::map::find_gate(*table, reverse);
    context.expect(flipped == nullptr, "0 sang 242 là cùng cảnh");
    client::map::GateEnds loop;
    loop.source_scene = 0;
    loop.dest_scene = 0;
    const client::map::Gate* none = client::map::find_gate(*table, loop);
    context.expect(none == nullptr, "cùng cảnh thì không có cửa");
}

void cold_enter_uses_the_only_dest(Context& context) {
    const client::map::GateResult table = sample_table();
    context.expect(table.has_value(), "bảng mẫu");
    if (!table) return;
    const client::map::GateStand only = client::map::entrance_of(*table, 251);
    context.expect(only.has, "cốc có điểm đến");
    context.expect(only.x == 68.0F, "x đến 68");
    context.expect(only.z == 23.0F, "z đến 23");
    client::map::SceneStep cold;
    cold.previous = -1;
    cold.scene = 251;
    const client::map::GateStand stand = client::map::arrival_at(*table, cold);
    context.expect(stand.has, "vào lạnh có điểm");
    context.expect(stand.x == 68.0F, "vào lạnh tại x 68");
    context.expect(stand.z == 23.0F, "vào lạnh tại z 23");
    client::map::SceneStep back;
    back.previous = 251;
    back.scene = 244;
    const client::map::GateStand returned = client::map::arrival_at(*table, back);
    context.expect(returned.has, "có cửa về núi");
    context.expect(returned.x == 26.0F, "về núi tại x 26");
    context.expect(returned.z == 103.0F, "về núi tại z 103");
}

void clashing_entrances_do_not_pick_one(Context& context) {
    std::vector<client::map::Gate> rows;
    const client::map::Gate valley = valley_gate();
    const client::map::Gate other = other_valley();
    rows.push_back(valley);
    rows.push_back(other);
    const std::string bytes = gate_bytes(rows);
    const client::map::GateResult table = client::map::read_gates(bytes);
    context.expect(table.has_value(), "bảng hai cửa vào cốc");
    if (!table) return;
    const client::map::GateStand cold = client::map::entrance_of(*table, 251);
    context.expect(!cold.has, "hai điểm đến khác nhau thì không chọn");
    client::map::SceneStep from_mountain;
    from_mountain.previous = 244;
    from_mountain.scene = 251;
    const client::map::GateStand linked = client::map::arrival_at(*table, from_mountain);
    context.expect(linked.has, "cửa thẳng vẫn có điểm");
    context.expect(linked.x == 68.0F, "cửa thẳng tại x 68");
    context.expect(linked.z == 23.0F, "cửa thẳng tại z 23");
    client::map::SceneStep from_nowhere;
    from_nowhere.previous = 99;
    from_nowhere.scene = 251;
    const client::map::GateStand missed = client::map::arrival_at(*table, from_nowhere);
    context.expect(!missed.has, "không có cửa thẳng và không có điểm chung");
}

void plan_point_matches_huoyangu(Context& context) {
    client::map::PlanFrame frame;
    frame.origin_x = -9600.0F;
    frame.origin_z = -9600.0F;
    frame.scale_x = 100.0F;
    frame.scale_z = 100.0F;
    client::map::GameCell cell;
    cell.x = 68.0F;
    cell.z = 23.0F;
    const client::map::WorldPoint world = client::map::plan_to_world(frame, cell);
    context.expect(world.x == -2800.0F, "x thế giới -2800");
    context.expect(world.z == -7300.0F, "z thế giới -7300");
}

void procedure_scenes_match_the_binary(Context& context) {
    context.expect(client::map::kCharacterCreateScene == -2, "tạo nhân vật id -2");
    context.expect(client::map::kCharacterCreateFile == "tl3chuangjian.Scene", "tệp tạo nhân vật");
    context.expect(client::map::kFactionLoginScene == -1, "phông erengu id -1");
    context.expect(client::map::kFactionLoginFile == "erengu_DL.Scene", "tệp phông erengu");
    context.expect(client::map::kLuoyangMirror == 242, "Lạc Dương bản sao là 242");
}

#ifdef GAME_CLIENT_DATA
void expect_first_gate(Context& context, const client::map::Gate& gate) {
    context.expect(gate.id == 1, "id dòng đầu");
    context.expect(gate.source_scene == 0, "cảnh đi là 0");
    context.expect(gate.source_x == 85, "x đi 85");
    context.expect(gate.source_z == 257, "z đi 257");
    context.expect(gate.dest_scene == 8, "cảnh đến 8");
    context.expect(gate.dest_x == 284, "x đến 284");
    context.expect(gate.dest_z == 146, "z đến 146");
    context.expect(gate.field_nine == 0, "cột 9 là 0");
    context.expect(gate.field_ten == 1, "cột 10 là 1");
    context.expect(gate.field_eleven == 0, "cột 11 là 0");
}

void expect_valley_gate(Context& context, std::span<const client::map::Gate> rows) {
    client::map::GateEnds ends;
    ends.source_scene = 244;
    ends.dest_scene = 251;
    const client::map::Gate* gate = client::map::find_gate(rows, ends);
    context.expect(gate != nullptr, "có cửa 244 sang 251");
    if (gate == nullptr) return;
    context.expect(gate->source_x == 26, "x đi 26");
    context.expect(gate->source_z == 103, "z đi 103");
    context.expect(gate->dest_x == 68, "x đến 68");
    context.expect(gate->dest_z == 23, "z đến 23");
    context.expect(gate->field_nine == 0, "cột 9 của cửa là 0");
    context.expect(gate->field_ten == 0, "cột 10 của cửa là 0");
    context.expect(gate->field_eleven == 90, "cột 11 của cửa là 90");
}
#endif

void real_gate_file_matches_the_client(Context& context) {
#ifndef GAME_CLIENT_DATA
    context.expect(true, "không có thư mục data trong bản build này");
#else
    const std::filesystem::path path =
        std::filesystem::path(GAME_CLIENT_DATA) / "Config" / "ScenePosDefineEx.txt";
    const io::TextResult text = io::read_text(path);
    context.expect(text.has_value(), "đọc được ScenePosDefineEx");
    if (!text) return;
    const client::map::GateResult table = client::map::read_gates(*text);
    context.expect(table.has_value(), "bảng cổng đúng dạng DBC");
    if (!table) return;
    context.expect(table->size() == 1957, "1957 cổng");
    const client::map::Gate& first = table->front();
    expect_first_gate(context, first);
    expect_valley_gate(context, *table);
#endif
}

constexpr std::array kCases{
    Case{.name = "terrain_origin_matches_original", .body = &terrain_origin_matches_original},
    Case{.name = "terrain_rejects_bad_documents", .body = &terrain_rejects_bad_documents},
    Case{.name = "terrain_height_type_defaults_to_standard",
        .body = &terrain_height_type_defaults_to_standard},
    Case{.name = "height_and_grid_follow_original_layout",
        .body = &height_and_grid_follow_original_layout},
    Case{.name = "sheet_faces_up_and_skips_holes", .body = &sheet_faces_up_and_skips_holes},
    Case{.name = "book_keeps_active_rows_and_skips_spares",
        .body = &book_keeps_active_rows_and_skips_spares},
    Case{.name = "book_reads_radar_token", .body = &book_reads_radar_token},
    Case{.name = "book_reads_clip_planes", .body = &book_reads_clip_planes},
    Case{.name = "pixmap_corner_follows_original_table",
        .body = &pixmap_corner_follows_original_table},
    Case{.name = "surface_paints_the_base_brush", .body = &surface_paints_the_base_brush},
    Case{.name = "liquid_covers_the_pool_and_stays_flat",
        .body = &liquid_covers_the_pool_and_stays_flat},
    Case{.name = "water_cover_keeps_the_higher_level", .body = &water_cover_keeps_the_higher_level},
    Case{.name = "water_ray_matches_nav_collider", .body = &water_ray_matches_nav_collider},
    Case{.name = "liquid_look_matches_the_named_material",
        .body = &liquid_look_matches_the_named_material},
    Case{.name = "minimap_frame_matches_desktop_layout",
        .body = &minimap_frame_matches_desktop_layout},
    Case{.name = "gate_table_rejects_a_bad_file", .body = &gate_table_rejects_a_bad_file},
    Case{.name = "gate_table_rejects_an_empty_string_block",
        .body = &gate_table_rejects_an_empty_string_block},
    Case{.name = "gate_table_rejects_a_wrong_type", .body = &gate_table_rejects_a_wrong_type},
    Case{.name = "gate_table_keeps_a_trailing_byte", .body = &gate_table_keeps_a_trailing_byte},
    Case{.name = "valley_gate_matches_the_client", .body = &valley_gate_matches_the_client},
    Case{.name = "luoyang_query_uses_scene_zero", .body = &luoyang_query_uses_scene_zero},
    Case{.name = "cold_enter_uses_the_only_dest", .body = &cold_enter_uses_the_only_dest},
    Case{.name = "clashing_entrances_do_not_pick_one", .body = &clashing_entrances_do_not_pick_one},
    Case{.name = "plan_point_matches_huoyangu", .body = &plan_point_matches_huoyangu},
    Case{.name = "procedure_scenes_match_the_binary", .body = &procedure_scenes_match_the_binary},
    Case{.name = "real_gate_file_matches_the_client", .body = &real_gate_file_matches_the_client},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "map_tests: mọi ca phải qua");
    return 0;
}
