// Test của camera bám theo (camera/follow): vị trí mắt theo _GetEyePos, mặt gần và mặt xa theo tỉ lệ
// địa hình, zoom theo nấc có kẹp, và pitch tự dốc lên khi mắt chạm địa hình rồi hồi về từng độ
// (KT-01, KT-02).
#include "camera/follow.hpp"
#include "core/check.hpp"
#include "math/vector.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <numbers>
#include <vector>

namespace game::test {
namespace {

constexpr int kCells = 64;
constexpr float kTolerance = 0.01F;

[[nodiscard]] bool is_close(float left, float right) noexcept {
    return std::fabs(left - right) <= kTolerance;
}

// Lưới phẳng 64 x 64 ô, mỗi ô 100 đơn vị, tâm ở gốc toạ độ.
[[nodiscard]] camera::Terrain flat(const std::vector<float>& heights) noexcept {
    camera::Terrain terrain;
    terrain.origin = math::Vector3(-3200.0F, 0.0F, -3200.0F);
    terrain.columns = kCells;
    terrain.rows = kCells;
    terrain.heights = heights;
    return terrain;
}

[[nodiscard]] std::vector<float> level_heights() {
    const std::size_t stride = static_cast<std::size_t>(kCells) + 1;
    const std::size_t corners = stride * stride;
    return std::vector<float>(corners, 0.0F);
}

void eye_follows_original_formula(Context& context) {
    const math::Point3 target(10.0F, 20.0F, 30.0F);
    const float pitch = -0.5F;
    const camera::Orbit orbit{.distance = 100.0F, .direction = 0.0F, .pitch = pitch};
    const math::Point3 eye = camera::eye_position(target, orbit);
    context.expect(is_close(eye.x(), 10.0F), "hướng 0: mắt không lệch theo X");
    context.expect(is_close(eye.y(), 20.0F + (100.0F * std::sin(0.5F))), "pitch âm: mắt ở trên");
    context.expect(is_close(eye.z(), 30.0F - (100.0F * std::cos(0.5F))), "mắt lùi theo -Z");
}

void pose_uses_client_defaults(Context& context) {
    const std::vector<float> heights = level_heights();
    const camera::Terrain terrain = flat(heights);
    camera::FollowCamera follow{camera::FollowRules{}};
    const camera::FollowPose pose = follow.update(terrain, math::Point3(0.0F, 0.0F, 0.0F));
    context.expect(is_close(pose.near_plane, 25.0F), "mặt gần 0,25 lần tỉ lệ địa hình");
    context.expect(is_close(pose.far_plane, 15000.0F), "mặt xa 150 lần tỉ lệ địa hình");
    context.expect(is_close(pose.fov_degrees, 35.0F), "FOV 35 độ");
    context.expect(is_close(pose.target.y(), 70.0F), "điểm nhìn cao hơn chân 0,7 đơn vị game");
    const float height = pose.eye.y() - pose.target.y();
    context.expect(is_close(height, 2750.0F * std::sin(0.6981317F)), "xa nhất, nhìn xuống 40 độ");
}

void zoom_moves_in_clamped_steps(Context& context) {
    camera::FollowCamera follow{camera::FollowRules{}};
    context.expect(is_close(follow.zoom_level(), 1.0F), "bắt đầu ở khoảng cách xa nhất");
    follow.zoom_steps(2);
    context.expect(is_close(follow.zoom_level(), 0.9F), "hai nấc lại gần là 0,1");
    follow.zoom_steps(-40);
    context.expect(is_close(follow.zoom_level(), 1.0F), "ra xa bị kẹp ở 1");
    follow.zoom_steps(40);
    context.expect(is_close(follow.zoom_level(), 0.0F), "lại gần bị kẹp ở 0");
    follow.set_zoom(1.5F);
    context.expect(is_close(follow.zoom_level(), 0.0F), "zoom ngoài [0, 1] bị bỏ qua");
}

// Dựng một vách cao 5000 ở mọi đỉnh có hàng nhỏ hơn 22 (phía sau điểm nhìn khi hướng là 0).
[[nodiscard]] std::vector<float> wall_heights() {
    std::vector<float> heights = level_heights();
    const std::size_t stride = static_cast<std::size_t>(kCells) + 1;
    std::fill_n(heights.begin(), stride * 22, 50.0F);
    return heights;
}

void pitch_lifts_over_terrain_then_recovers(Context& context) {
    const std::vector<float> wall = wall_heights();
    const std::vector<float> level = level_heights();
    camera::FollowRules rules;
    rules.direction = 0.0F;
    camera::FollowCamera follow{rules};
    const math::Point3 foot(0.0F, 0.0F, 0.0F);
    const float standard = follow.pitch();
    const camera::FollowPose blocked = follow.update(flat(wall), foot);
    context.expect(follow.pitch() < standard, "mắt chạm vách thì pitch dốc thêm");
    const bool is_out = !camera::touches_sphere(flat(wall), blocked.eye, blocked.near_plane);
    context.expect(is_out, "sau khi dốc, mắt không còn chạm địa hình");
    const float lifted = follow.pitch();
    static_cast<void>(follow.update(flat(level), foot));
    const float step = std::numbers::pi_v<float> / 180.0F;
    context.expect(is_close(follow.pitch(), lifted + step), "hết vướng thì hồi về mỗi lần một độ");
}

void sphere_test_only_counts_cells_under_it(Context& context) {
    const std::vector<float> wall = wall_heights();
    const camera::Terrain terrain = flat(wall);
    const math::Point3 above_wall(0.0F, 6000.0F, -2000.0F);
    const math::Point3 inside_wall(0.0F, 4000.0F, -2000.0F);
    const math::Point3 outside_map(9000.0F, 0.0F, 0.0F);
    context.expect(!camera::touches_sphere(terrain, above_wall, 25.0F), "trên đỉnh vách: không chạm");
    context.expect(camera::touches_sphere(terrain, inside_wall, 25.0F), "trong vách: chạm");
    context.expect(!camera::touches_sphere(terrain, outside_map, 25.0F), "ngoài map: không chạm");
}

constexpr std::array kCases{
    Case{.name = "eye_follows_original_formula", .body = &eye_follows_original_formula},
    Case{.name = "pose_uses_client_defaults", .body = &pose_uses_client_defaults},
    Case{.name = "zoom_moves_in_clamped_steps", .body = &zoom_moves_in_clamped_steps},
    Case{.name = "pitch_lifts_over_terrain_then_recovers", .body = &pitch_lifts_over_terrain_then_recovers},
    Case{.name = "sphere_test_only_counts_cells_under_it", .body = &sphere_test_only_counts_cells_under_it},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "follow_tests: mọi ca phải qua");
    return 0;
}
