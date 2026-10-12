// Test của scene: đọc .Scene (vật thể trong Group được trải phẳng đúng thứ tự) và phép đặt đọc theo
// đúng quy tắc của client gốc (thứ tự w x y z, số token sai, giá trị mặc định) (KT-01, KT-02).
#include "core/check.hpp"
#include "scene/placement.hpp"
#include "scene/scene_file.hpp"
#include "test.hpp"

#include <array>
#include <string_view>

namespace game::test {
namespace {

// Trích từ BattleField.Scene của kho gốc, thêm một Group như các cảnh bản 3.71.
constexpr std::string_view kSample = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
                                     "<Scene formatVersion=\"0.1.1\" name=\"BattleField\">\n"
                                     "  <Author>Genva Xie</Author>\n"
                                     "  <Terrain filename=\"BattleField.Terrain\"/>\n"
                                     "  <Object name=\"#FairyEnviroment\" type=\"Enviroment\">\n"
                                     "    <Property name=\"ambient\" value=\"0.286275 0.309804 0.713726\"/>\n"
                                     "  </Object>\n"
                                     "  <Group name=\"nhóm\">\n"
                                     "    <Object type=\"StaticEntity\">\n"
                                     "      <Property name=\"mesh name\" value=\"a/b.mesh\"/>\n"
                                     "      <Property name=\"position\" value=\"-7681.1 449.898 -7414.98\"/>\n"
                                     "      <Property name=\"orientation\" value=\"0.846857 0 0.531823 0\"/>\n"
                                     "    </Object>\n"
                                     "  </Group>\n"
                                     "  <Object type=\"StaticEntity\">\n"
                                     "    <Property name=\"mesh name\" value=\"c.mesh\"/>\n"
                                     "    <Property name=\"scale\" value=\"0.5 1 1\"/>\n"
                                     "  </Object>\n"
                                     "</Scene>\n";

void read_scene_flattens_groups_in_file_order(Context& context) noexcept {
    const auto file = scene::read_scene(kSample);
    context.expect(file.has_value(), "cảnh mẫu đọc được");
    if (!file) return;
    context.expect(file->name == "BattleField", "tên cảnh");
    context.expect(file->terrain_file == "BattleField.Terrain", "tệp địa hình");
    context.expect(file->objects.size() == 3, "ba vật thể, kể cả cái trong Group");
    context.expect(file->objects[0].name == "#FairyEnviroment", "tên riêng của vật thể");
    context.expect(scene::property(file->objects[1], "mesh name") == "a/b.mesh", "thứ tự tệp");
    context.expect(scene::property(file->objects[2], "mesh name") == "c.mesh", "sau Group");
    context.expect(!scene::property(file->objects[2], "position").has_value(), "thuộc tính vắng");
}

void read_scene_rejects_other_documents(Context& context) noexcept {
    const auto other = scene::read_scene("<Terrain name=\"x\"/>");
    context.expect(!other && other.error() == scene::SceneError::kNotScene, "gốc không phải Scene");
    const auto broken = scene::read_scene("<Scene><Object></Scene>");
    context.expect(!broken && broken.error() == scene::SceneError::kBadXml, "XML hỏng");
}

void placement_follows_original_rules(Context& context) noexcept {
    const auto file = scene::read_scene(kSample);
    context.expect(file.has_value(), "cảnh mẫu đọc được");
    if (!file) return;
    const scene::Placement placed = scene::placement_of(file->objects[1]);
    const scene::Vector3 position{.x = -7681.1F, .y = 449.898F, .z = -7414.98F};
    context.expect(placed.position == position, "vị trí x y z");
    // Tệp ghi w x y z = 0.846857 0 0.531823 0.
    const scene::Quaternion turn{.x = 0.0F, .y = 0.531823F, .z = 0.0F, .w = 0.846857F};
    context.expect(placed.orientation == turn, "hướng đọc theo thứ tự w x y z");
    const scene::Vector3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    context.expect(placed.scale == unit, "tỉ lệ mặc định 1");
    const scene::Placement scaled = scene::placement_of(file->objects[2]);
    context.expect(scaled.scale == scene::Vector3{.x = 0.5F, .y = 1.0F, .z = 1.0F}, "tỉ lệ x y z");
    context.expect(scaled.position == scene::Vector3{}, "vị trí mặc định 0");
    context.expect(scaled.orientation == scene::Quaternion{}, "hướng mặc định đơn vị");
}

void parsing_matches_ogre_string_converter(Context& context) noexcept {
    context.expect(scene::parse_real("1e-005") == 1e-5F, "số mũ ba chữ số");
    context.expect(scene::parse_real(" +3.5") == 3.5F, "khoảng trắng và dấu cộng đứng đầu");
    context.expect(scene::parse_real("2.5abc") == 2.5F, "phần đầu đọc được");
    context.expect(scene::parse_real("abc") == 0.0F, "không đọc được thì 0");
    // 16777217 nằm giữa hai float; qua double rồi thu về float thì làm tròn về số chẵn.
    context.expect(scene::parse_real("16777217") == 16777216.0F, "đọc qua double rồi thu về float");
    context.expect(scene::parse_vector3("1 2") == scene::Vector3{}, "thiếu token: 0 0 0");
    context.expect(scene::parse_vector3("1 2 3 4") == scene::Vector3{}, "thừa token: 0 0 0");
    const scene::Vector3 spaced{.x = 1.0F, .y = 2.0F, .z = 3.0F};
    context.expect(scene::parse_vector3("  1\t2\n3 ") == spaced, "tách theo cách, tab, xuống dòng");
    context.expect(scene::parse_quaternion("1 0 0") == scene::Quaternion{}, "thiếu token: đơn vị");
}

constexpr std::array kCases{
    Case{.name = "read_scene_flattens_groups_in_file_order", .body = &read_scene_flattens_groups_in_file_order},
    Case{.name = "read_scene_rejects_other_documents", .body = &read_scene_rejects_other_documents},
    Case{.name = "placement_follows_original_rules", .body = &placement_follows_original_rules},
    Case{.name = "parsing_matches_ogre_string_converter", .body = &parsing_matches_ogre_string_converter},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "scene_tests: mọi ca phải qua");
    return 0;
}
