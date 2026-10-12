// Test của client/props: gom vật thể tĩnh của stage thành bảng nạp. Mesh trùng nhau chỉ xuất hiện
// một lần (theo thứ tự gặp đầu tiên) vì mỗi mesh chỉ nạp và tải lên GPU một lần; mỗi vật thể giữ
// chỉ số mesh của mình và phép đặt đã tính thành ma trận thế giới đúng OGRE (T * R * S, double).
#include "client/stage/props.hpp"
#include "client/stage/stage.hpp"
#include "core/check.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <initializer_list>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using client::Prop;
using client::Stage;
using scene::Placement;
using scene::Point;

// sin và cos của 45 độ đã làm tròn về float, như số đọc từ tệp cảnh.
constexpr float kHalf = 0.70710678F;
// Sai số do kHalf * kHalf * 2 không đúng bằng 1 ở float.
constexpr double kLoose = 1e-5;

[[nodiscard]] Stage stage_with(std::initializer_list<Prop> props) {
    Stage stage;
    for (const Prop& prop : props) {
        stage.props.push_back(prop);
    }
    return stage;
}

[[nodiscard]] Prop prop_of(std::string_view mesh, Placement placement) {
    Prop made;
    made.mesh = std::string(mesh);
    made.placement = placement;
    return made;
}

[[nodiscard]] bool is_near(const Point& left, const Point& right, double tolerance) noexcept {
    const bool is_x = std::abs(left.x - right.x) <= tolerance;
    const bool is_y = std::abs(left.y - right.y) <= tolerance;
    return is_x && is_y && std::abs(left.z - right.z) <= tolerance;
}

void same_mesh_is_listed_once_in_first_seen_order(Context& context) {
    const Stage stage = stage_with({prop_of("a/b.mesh", Placement{}), prop_of("c/d.mesh", Placement{}),
        prop_of("a/b.mesh", Placement{})});
    const client::PropTable table = client::table_of(stage);
    context.expect(table.meshes.size() == 2, "hai mesh trùng thành hai tên");
    if (table.meshes.size() != 2) return;
    context.expect(table.meshes[0] == "a/b.mesh", "mesh đầu theo thứ tự gặp");
    context.expect(table.meshes[1] == "c/d.mesh", "mesh thứ hai sau mesh đầu");
    context.expect(table.props.size() == 3, "mỗi vật thể một mục");
    if (table.props.size() != 3) return;
    context.expect(table.props[0].mesh == 0, "vật thể đầu trỏ mesh 0");
    context.expect(table.props[1].mesh == 1, "vật thể giữa trỏ mesh 1");
    context.expect(table.props[2].mesh == 0, "vật thể cuối trỏ lại mesh 0");
}

void world_holds_placement_of_each_prop(Context& context) {
    Placement placed;
    placed.position = {.x = 5.0F, .y = 6.0F, .z = 7.0F};
    placed.scale = {.x = 2.0F, .y = 3.0F, .z = 4.0F};
    const Stage stage = stage_with({prop_of("x.mesh", placed)});
    const client::PropTable table = client::table_of(stage);
    if (table.props.size() != 1) {
        context.expect(false, "một vật thể cho một mục");
        return;
    }
    const scene::Transform& world = table.props[0].world;
    using Row = std::array<double, 4>;
    context.expect(world.rows[0] == Row{2.0, 0.0, 0.0, 5.0}, "hàng 0: tỉ lệ x, dời x");
    context.expect(world.rows[1] == Row{0.0, 3.0, 0.0, 6.0}, "hàng 1: tỉ lệ y, dời y");
    context.expect(world.rows[2] == Row{0.0, 0.0, 4.0, 7.0}, "hàng 2: tỉ lệ z, dời z");
}

void world_follows_scale_rotation_translation(Context& context) {
    Placement placed;
    placed.position = {.x = 10.0F, .y = 20.0F, .z = 30.0F};
    // Quay 90 độ quanh Z (x y z w).
    placed.orientation = {.x = 0.0F, .y = 0.0F, .z = kHalf, .w = kHalf};
    placed.scale = {.x = 2.0F, .y = 3.0F, .z = 4.0F};
    const Stage stage = stage_with({prop_of("y.mesh", placed)});
    const client::PropTable table = client::table_of(stage);
    if (table.props.size() != 1) {
        context.expect(false, "một vật thể cho một mục");
        return;
    }
    // (1,1,1) nhân tỉ lệ thành (2,3,4); quay quanh Z thành (-3,2,4); dời thành (7,22,34).
    const Point moved = scene::apply(table.props[0].world, {.x = 1.0, .y = 1.0, .z = 1.0});
    context.expect(is_near(moved, {.x = 7.0, .y = 22.0, .z = 34.0}, kLoose), "thứ tự T * R * S");
}

void empty_stage_gives_empty_table(Context& context) {
    const client::PropTable table = client::table_of(Stage{});
    context.expect(table.meshes.empty(), "stage rỗng không có mesh");
    context.expect(table.props.empty(), "stage rỗng không có vật thể");
}

constexpr std::array kCases{
    Case{.name = "same_mesh_is_listed_once_in_first_seen_order", .body = &same_mesh_is_listed_once_in_first_seen_order},
    Case{.name = "world_holds_placement_of_each_prop", .body = &world_holds_placement_of_each_prop},
    Case{.name = "world_follows_scale_rotation_translation", .body = &world_follows_scale_rotation_translation},
    Case{.name = "empty_stage_gives_empty_table", .body = &empty_stage_gives_empty_table},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "props_tests: mọi ca phải qua");
    return 0;
}
