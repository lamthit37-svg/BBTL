// Test của client/stage: trích từ một tệp cảnh những thứ phần hiển thị cần — vật thể tĩnh có mesh
// (đúng thứ tự trong tệp, kèm phép đặt), các đèn directional và màu ambient. Vật thể kiểu khác, đèn
// điểm và vật thể tĩnh không có tên mesh không được lọt vào.
#include "client/stage/height_fog.hpp"
#include "client/stage/sky.hpp"
#include "client/stage/stage.hpp"
#include "core/check.hpp"
#include "scene/placement.hpp"
#include "scene/scene_file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

constexpr std::string_view kScene =
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
    "<Scene formatVersion=\"0.1.1\" name=\"thu\">\n"
    "  <Terrain filename=\"thu.Terrain\"/>\n"
    "  <Object name=\"#FairyEnviroment\" type=\"Enviroment\">\n"
    "    <Property name=\"ambient\" value=\"0.25 0.5 0.75\"/>\n"
    "  </Object>\n"
    "  <Object name=\"#FairyMainLightOne\" type=\"Light\">\n"
    "    <Property name=\"type\" value=\"directional\"/>\n"
    "    <Property name=\"diffuse\" value=\"0.8 0.2 0\"/>\n"
    "    <Property name=\"direction\" value=\"0.5 -0.5 -0.25\"/>\n"
    "  </Object>\n"
    "  <Object type=\"Light\">\n"
    "    <Property name=\"diffuse\" value=\"1 1 1\"/>\n"
    "    <Property name=\"position\" value=\"1 2 3\"/>\n"
    "  </Object>\n"
    "  <Object name=\"#FairyMainLightTwo\" type=\"Light\">\n"
    "    <Property name=\"type\" value=\"directional\"/>\n"
    "    <Property name=\"diffuse\" value=\"0 0.25 0\"/>\n"
    "    <Property name=\"direction\" value=\"-1 0 0\"/>\n"
    "  </Object>\n"
    "  <Object type=\"StaticEntity\">\n"
    "    <Property name=\"mesh name\" value=\"敦煌/敦煌山洞.mesh\"/>\n"
    "    <Property name=\"position\" value=\"-3241 2370.5 -8511.25\"/>\n"
    "    <Property name=\"orientation\" value=\"1 0 0.5 0\"/>\n"
    "  </Object>\n"
    "  <Object type=\"Model\">\n"
    "    <Property name=\"model name\" value=\"x.model\"/>\n"
    "  </Object>\n"
    "  <Object type=\"StaticEntity\">\n"
    "    <Property name=\"position\" value=\"9 9 9\"/>\n"
    "  </Object>\n"
    "  <Group name=\"nhom\">\n"
    "    <Object type=\"StaticEntity\">\n"
    "      <Property name=\"mesh name\" value=\"a/b.mesh\"/>\n"
    "      <Property name=\"scale\" value=\"2 3 4\"/>\n"
    "    </Object>\n"
    "  </Group>\n"
    "</Scene>\n";

[[nodiscard]] client::Stage sample_stage() {
    const auto file = scene::read_scene(kScene);
    core::check(file.has_value(), "cảnh mẫu của test phải đọc được");
    return client::stage_of(*file);
}

void stage_keeps_static_entities_with_a_mesh_in_file_order(Context& context) {
    const client::Stage stage = sample_stage();
    context.expect(stage.props.size() == 2, "hai vật thể tĩnh có mesh; cái thiếu mesh bị bỏ");
    if (stage.props.size() != 2) return;
    const client::Prop& first = stage.props[0];
    context.expect(first.mesh == "敦煌/敦煌山洞.mesh", "tên mesh UTF-8 giữ nguyên");
    const scene::Vector3 position{.x = -3241.0F, .y = 2370.5F, .z = -8511.25F};
    context.expect(first.placement.position == position, "vị trí của vật thể đầu");
    const scene::Quaternion turn{.x = 0.0F, .y = 0.5F, .z = 0.0F, .w = 1.0F};
    context.expect(first.placement.orientation == turn, "hướng đọc theo thứ tự w x y z");
    const client::Prop& second = stage.props[1];
    context.expect(second.mesh == "a/b.mesh", "vật thể trong Group đứng sau, đúng thứ tự tệp");
    const scene::Vector3 scale{.x = 2.0F, .y = 3.0F, .z = 4.0F};
    context.expect(second.placement.scale == scale, "tỉ lệ của vật thể thứ hai");
}

void stage_takes_directional_lights_and_ambient(Context& context) {
    const client::Stage stage = sample_stage();
    context.expect(stage.suns.size() == 2, "hai đèn directional; đèn điểm bị bỏ");
    if (stage.suns.size() != 2) return;
    const scene::Vector3 direction{.x = 0.5F, .y = -0.5F, .z = -0.25F};
    context.expect(stage.suns[0].direction == direction, "hướng tia của đèn thứ nhất");
    const client::Rgb warm{.red = 0.8F, .green = 0.2F, .blue = 0.0F};
    context.expect(stage.suns[0].colour == warm, "màu của đèn thứ nhất");
    const client::Rgb green{.red = 0.0F, .green = 0.25F, .blue = 0.0F};
    context.expect(stage.suns[1].colour == green, "màu của đèn thứ hai");
    const client::Rgb ambient{.red = 0.25F, .green = 0.5F, .blue = 0.75F};
    context.expect(stage.ambient == ambient, "màu ambient của Enviroment");
}

void stage_keeps_terrain_liquid(Context& context) {
    constexpr std::string_view text =
        "<Scene name=\"nuoc\">\n"
        "  <Object type=\"TerrainLiquid\">\n"
        "    <Property name=\"material\" value=\"nham\"/>\n"
        "    <Property name=\"position\" value=\"1 2 3\"/>\n"
        "    <Property name=\"texture scale\" value=\"0.3\"/>\n"
        "  </Object>\n"
        "</Scene>\n";
    const auto file = scene::read_scene(text);
    context.expect(file.has_value(), "cảnh có mặt nước đọc được");
    if (!file) return;
    const client::Stage stage = client::stage_of(*file);
    context.expect(stage.liquids.size() == 1, "một mặt nước");
    if (stage.liquids.size() != 1) return;
    context.expect(stage.liquids.front().material == "nham", "tên chất liệu");
    context.expect(stage.liquids.front().texture_scale == 0.3F, "tỉ lệ texture");
}

void sky_uses_the_current_weather(Context& context) {
    constexpr std::string_view text =
        "<SkySphere>\n"
        "  <SkyWeathers current_weather=\"default\">\n"
        "    <Weather name=\"default\">\n"
        "      <SkySphereTextureGroups>\n"
        "        <TextureGroup background_texture=\"BS_dongho.jpg\" background_wrap=\"4\" "
        "fog_texture=\"FogJianbian.tga\" fog_wrap=\"1\"/>\n"
        "      </SkySphereTextureGroups>\n"
        "    </Weather>\n"
        "  </SkyWeathers>\n"
        "  <SkySphereLayers>\n"
        "    <SkyLayer name=\"background\" pitch_start=\"0\" pitch_end=\"1.5708\" "
        "texture_count=\"1\"/>\n"
        "    <SkyLayer name=\"fog\" pitch_start=\"1.3\" pitch_end=\"1.8\" texture_count=\"1\"/>\n"
        "    <SkyLayer name=\"far_cloud\" pitch_start=\"1\" pitch_end=\"1.5\" texture_count=\"0\"/>\n"
        "  </SkySphereLayers>\n"
        "</SkySphere>\n";
    const client::SkyDome dome = client::read_sky(text);
    context.expect(dome.bands.size() == 2, "nền và sương, bỏ lớp không có ảnh");
    if (dome.bands.size() != 2) return;
    context.expect(dome.bands.front().texture == "BS_dongho.jpg", "ảnh nền của thời tiết");
    context.expect(dome.bands.front().repeats == 4, "quấn bốn lần");
    context.expect(dome.bands.back().blends, "lớp sương trộn");
    context.expect(!client::sky_band(dome.bands.front()).vertices.empty(), "vòm có đỉnh");
    client::Stage stage;
    client::apply_sky(stage, text);
    context.expect(stage.sky.size() == dome.bands.size(), "cảnh giữ các dải ảnh");
}

[[nodiscard]] bool is_close(float actual, float expected) noexcept {
    return std::abs(actual - expected) < 1.0e-5F;
}

// Lưới 33 cột x 9 hàng, đỉnh xếp theo hàng. Cột 8 là một phần tư vòng, hàng 4 là giữa dải.
void sky_band_runs_columns_around_and_rows_down(Context& context) {
    client::SkyBand band;
    band.pitch_start = 0.5F;
    band.pitch_end = 1.5F;
    band.repeats = 4;
    const client::SkyMesh mesh = client::sky_band(band);
    context.expect(mesh.vertices.size() == 297, "33 cột x 9 hàng đỉnh");
    context.expect(mesh.indices.size() == 1536, "32 x 8 ô, mỗi ô sáu chỉ số");
    if (mesh.vertices.size() != 297 || mesh.indices.size() != 1536) return;
    const client::SkyVertex& top = mesh.vertices.front();
    context.expect(is_close(top.x, 0.0F) && is_close(top.z, std::sin(0.5F)), "cột 0 nhìn về +Z");
    context.expect(is_close(top.y, std::cos(0.5F)), "hàng 0 ở pitch_start");
    const client::SkyVertex& quarter = mesh.vertices[(4 * 33) + 8];
    context.expect(is_close(quarter.x, std::sin(1.0F)), "một phần tư vòng nằm trên +X");
    context.expect(is_close(quarter.y, std::cos(1.0F)), "hàng 4 ở giữa dải");
    context.expect(is_close(quarter.z, 0.0F), "một phần tư vòng không còn phần Z");
    context.expect(is_close(quarter.u, 1.0F), "một phần tư của bốn lần quấn");
    context.expect(is_close(quarter.v, 0.5F), "v chạy 0..1 theo dải");
    // Ô hàng 1 cột 2 là ô thứ 1 * 32 + 2 = 34, mỗi ô sáu chỉ số.
    constexpr std::size_t kFirst = 204;
    constexpr std::array<std::uint32_t, 6> kCell{35, 68, 36, 36, 68, 69};
    const std::span<const std::uint32_t> indices(mesh.indices);
    const std::span<const std::uint32_t> cell = indices.subspan(kFirst, kCell.size());
    context.expect(std::ranges::equal(cell, kCell), "ô hàng 1 cột 2");
}

void stage_of_empty_scene_is_empty(Context& context) {
    const auto file = scene::read_scene("<Scene name=\"rong\"></Scene>");
    context.expect(file.has_value(), "cảnh rỗng đọc được");
    if (!file) return;
    const client::Stage stage = client::stage_of(*file);
    context.expect(stage.props.empty() && stage.suns.empty() && stage.liquids.empty(),
        "không vật thể, không đèn, không mặt nước");
    context.expect(stage.figures.empty() && stage.lamps.empty(), "không model, không đèn điểm");
    context.expect(stage.ambient == client::Rgb{}, "ambient mặc định là đen");
}

void stage_keeps_scene_models(Context& context) {
    const client::Stage stage = sample_stage();
    context.expect(stage.figures.size() == 1, "một object Model");
    if (stage.figures.size() != 1) return;
    context.expect(stage.figures.front().model == "x.model", "tên tệp model giữ nguyên");
    context.expect(stage.props.size() == 2, "model chưa bung thành mesh ở bước trích cảnh");
}

void stage_turns_spot_lights_into_lamps(Context& context) {
    constexpr std::string_view text =
        "<Scene name=\"den\">\n"
        "  <Object type=\"Light\">\n"
        "    <Property name=\"type\" value=\"spot\"/>\n"
        "    <Property name=\"position\" value=\"4 5 6\"/>\n"
        "    <Property name=\"diffuse\" value=\"0.2 0.3 0.4\"/>\n"
        "    <Property name=\"range\" value=\"12\"/>\n"
        "    <Property name=\"attenuation\" value=\"2\"/>\n"
        "    <Property name=\"intensity\" value=\"3\"/>\n"
        "  </Object>\n"
        "  <Object type=\"Light\">\n"
        "    <Property name=\"type\" value=\"spotlight\"/>\n"
        "    <Property name=\"position\" value=\"1 1 1\"/>\n"
        "  </Object>\n"
        "  <Object type=\"Light\">\n"
        "    <Property name=\"type\" value=\"directional\"/>\n"
        "    <Property name=\"direction\" value=\"0 -1 0\"/>\n"
        "  </Object>\n"
        "</Scene>\n";
    const auto file = scene::read_scene(text);
    context.expect(file.has_value(), "cảnh đèn đọc được");
    if (!file) return;
    const client::Stage stage = client::stage_of(*file);
    context.expect(stage.lamps.size() == 2, "spot và spotlight là đèn điểm");
    context.expect(stage.suns.size() == 1, "directional không vào danh sách đèn điểm");
    if (stage.lamps.size() != 2) return;
    const client::Lamp& spot = stage.lamps.front();
    const scene::Vector3 position{.x = 4.0F, .y = 5.0F, .z = 6.0F};
    context.expect(spot.position == position, "vị trí đèn spot");
    context.expect(spot.range == 12.0F && spot.falloff == 2.0F && spot.power == 3.0F, "tầm, mũ, cường độ");
    const client::Rgb colour{.red = 0.2F, .green = 0.3F, .blue = 0.4F};
    context.expect(spot.colour == colour, "màu đèn spot");
}

void model_file_lists_entity_meshes(Context& context) {
    constexpr std::string_view text =
        "<model>\n"
        "  <frame name=\"a\">\n"
        "    <entity mesh=\"a/b.mesh\"/>\n"
        "    <entity mesh=\"\"/>\n"
        "  </frame>\n"
        "  <entity mesh=\"c.mesh\"/>\n"
        "</model>\n";
    const std::vector<std::string> meshes = client::model_meshes(text);
    context.expect(meshes.size() == 2, "bỏ entity không có mesh");
    if (meshes.size() != 2) return;
    context.expect(meshes[0] == "a/b.mesh" && meshes[1] == "c.mesh", "đúng thứ tự trong tệp");
    context.expect(client::model_meshes("<not").empty(), "XML hỏng không có mesh");
}

void height_fog_reads_sixty_four_bytes(Context& context) {
    float source[16] = {0.3F, 0.4F, 0.5F, 1.0F, 1.0F, -1781.0F, 0.132F, 8.8F,
        0.178F, 0.499F, 0.0F, 2.0F, 0.7F, 0.84F, 1.0F, 1.0F};
    std::array<std::byte, client::kHeightFogBytes> bytes{};
    std::memcpy(bytes.data(), source, bytes.size());
    const std::optional<client::HeightFog> fog = client::read_height_fog(bytes);
    context.expect(fog.has_value(), "64 byte là một tệp sương");
    if (!fog) return;
    context.expect(fog->color_r == 0.3F && fog->height == -1781.0F, "màu và cao độ");
    context.expect(fog->pow_factor == 8.8F && fog->depth_start == 0.0F, "mũ và tầm sâu");
    context.expect(fog->inscatter == 2.0F && fog->scatter_b == 1.0F, "tán xạ đứng sau tầm sâu");
    bytes[0] = std::byte{0};
    context.expect(!client::read_height_fog(std::span(bytes).first(63)).has_value(), "thiếu byte thì bỏ");
}

constexpr std::array kCases{
    Case{.name = "stage_keeps_static_entities_with_a_mesh_in_file_order",
        .body = &stage_keeps_static_entities_with_a_mesh_in_file_order},
    Case{.name = "stage_takes_directional_lights_and_ambient",
        .body = &stage_takes_directional_lights_and_ambient},
    Case{.name = "stage_keeps_terrain_liquid", .body = &stage_keeps_terrain_liquid},
    Case{.name = "sky_uses_the_current_weather", .body = &sky_uses_the_current_weather},
    Case{.name = "sky_band_runs_columns_around_and_rows_down",
        .body = &sky_band_runs_columns_around_and_rows_down},
    Case{.name = "stage_of_empty_scene_is_empty", .body = &stage_of_empty_scene_is_empty},
    Case{.name = "stage_keeps_scene_models", .body = &stage_keeps_scene_models},
    Case{.name = "stage_turns_spot_lights_into_lamps", .body = &stage_turns_spot_lights_into_lamps},
    Case{.name = "model_file_lists_entity_meshes", .body = &model_file_lists_entity_meshes},
    Case{.name = "height_fog_reads_sixty_four_bytes", .body = &height_fog_reads_sixty_four_bytes},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "stage_tests: mọi ca phải qua");
    return 0;
}
