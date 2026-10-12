// Test của mặt đất (control/ground), tia từ màn hình (control/view_ray), luật con trỏ và chọn thứ
// dưới chuột. Số mong đợi tính tay theo công thức của TerrainData.cpp, OgreMath.cpp và
// Camera_Scene.cpp trong ref, ghi ngay cạnh phép kiểm để người đọc tự đối chiếu. Camera cảnh và
// chuột của người chơi theo bản 2026 có test riêng ở pilot_tests.cpp.
// Nguồn: TLBB Dev tests/control/control_test.cpp@e0d89a6. Khác gốc: khung test của dự án;
// GroundShape thay cho dữ liệu đã nấu; thêm ca tia màn hình, ca luật con trỏ (names và rules) và ca
// chọn thứ dưới chuột.
#include "control/char_camera.hpp"
#include "control/cursor_rules.hpp"
#include "control/ground.hpp"
#include "control/hover.hpp"
#include "control/view_ray.hpp"
#include "core/check.hpp"
#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <numbers>
#include <optional>
#include <set>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using control::Ground;
using control::GroundShape;
using control::Ray;
using ogre::Vec3;

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) <= 1e-4F;
}

[[nodiscard]] bool near_point(Vec3 left, Vec3 right) {
    return near_value(left.x, right.x) && near_value(left.y, right.y) && near_value(left.z, right.z);
}

// Gốc (đỉnh (0, 0)) đặt ở tâm map như khi tệp .Terrain chỉ có <scale>, để các số tính tay dưới đây
// đọc được: map 2 x 2 tỉ lệ (100, 2, 50) có gốc (-100, 0, -50). Map lệch tâm có test riêng.
[[nodiscard]] GroundShape shape_of(int x_size, int z_size, Vec3 scale, std::vector<float> heights) {
    GroundShape shape;
    shape.x_size = x_size;
    shape.z_size = z_size;
    shape.scale = scale;
    const float half_x = scale.x * static_cast<float>(x_size) / 2.0F;
    const float half_z = scale.z * static_cast<float>(z_size) / 2.0F;
    shape.position = Vec3{.x = -half_x, .y = 0.0F, .z = -half_z};
    shape.heights = std::move(heights);
    return shape;
}

// Map 2 x 2 ô, tỉ lệ (100, 2, 50), gốc ở tâm: (-100, 0, -50). Ô (0, 0) không phẳng: bốn góc thô
// 0, 10, 0, 40 nên hai cách chia đường chéo cho hai độ cao khác nhau.
[[nodiscard]] std::vector<float> bumpy_heights() {
    return {0.0F, 10.0F, 20.0F, 0.0F, 40.0F, 20.0F, 0.0F, 0.0F, 0.0F};
}

[[nodiscard]] std::optional<Ground> bumpy(std::vector<bool> flipped) {
    GroundShape shape = shape_of(2, 2, Vec3{.x = 100.0F, .y = 2.0F, .z = 50.0F}, bumpy_heights());
    shape.flipped = std::move(flipped);
    return Ground::create(std::move(shape));
}

void create_rejects(Context& context) {
    const Vec3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    context.expect(!Ground::create(shape_of(0, 2, unit, bumpy_heights())).has_value(), "kích thước 0");
    const Vec3 flat{.x = 1.0F, .y = 1.0F, .z = 0.0F};
    context.expect(!Ground::create(shape_of(2, 2, flat, bumpy_heights())).has_value(), "tỉ lệ z bằng 0");
    context.expect(!Ground::create(shape_of(3, 2, unit, bumpy_heights())).has_value(), "lưới độ cao lệch");
    GroundShape three = shape_of(2, 2, unit, bumpy_heights());
    three.flipped = {false, false, false};
    context.expect(!Ground::create(std::move(three)).has_value(), "số ô lệch x_size * z_size");
    context.expect(bumpy({}).has_value(), "map hợp lệ, không có ô: mọi ô không lật");
    context.expect(bumpy({false, false, false, false}).has_value(), "map hợp lệ, đủ ô");
}

// Đổi toạ độ: thế giới = gốc + game * tỉ lệ, game = (thế giới - gốc) / tỉ lệ.
void coordinates(Context& context) {
    const auto ground = bumpy({});
    context.expect(ground.has_value(), "dựng map");
    if (!ground) return;
    const Vec3 world = ground->to_world(core::GroundPoint{.x = 1.0F, .z = 2.0F});
    // Góc (1, 2) có độ cao thô 0 nên y = 0 + 2 * 0.
    context.expect(near_point(world, Vec3{.x = 0.0F, .y = 0.0F, .z = 50.0F}), "game sang thế giới");
    const core::GroundPoint game = ground->to_game(Vec3{.x = -50.0F, .y = 7.0F, .z = -25.0F});
    context.expect(near_value(game.x, 0.5F) && near_value(game.z, 0.5F), "thế giới sang game");
}

// Gốc lệch tâm như treasure_1 của ref: đỉnh (0, 0) ở (-4700, 30, -20800), không phải tâm map, và y
// của gốc cộng vào mọi độ cao (TerrainData::_convertPosition).
void coordinates_offset(Context& context) {
    GroundShape shape = shape_of(2, 2, Vec3{.x = 100.0F, .y = 2.0F, .z = 50.0F}, bumpy_heights());
    shape.position = Vec3{.x = -4700.0F, .y = 30.0F, .z = -20800.0F};
    const auto ground = Ground::create(std::move(shape));
    context.expect(ground.has_value(), "dựng map lệch tâm");
    if (!ground) return;
    // Góc (1, 2): x = -4700 + 100, z = -20800 + 50 * 2, độ cao thô 0 nên y = 30.
    const Vec3 world = ground->to_world(core::GroundPoint{.x = 1.0F, .z = 2.0F});
    context.expect(near_point(world, Vec3{.x = -4600.0F, .y = 30.0F, .z = -20700.0F}), "theo gốc");
    const core::GroundPoint game = ground->to_game(Vec3{.x = -4650.0F, .y = 0.0F, .z = -20775.0F});
    context.expect(near_value(game.x, 0.5F) && near_value(game.z, 0.5F), "thế giới sang game theo gốc");
    // Ô (0, 0) ở (0.75, 0.75): độ cao thô 22.5 như height_default, y = 30 + 2 * 22.5.
    context.expect(near_value(ground->height_at(-4625.0F, -20762.5F), 75.0F), "độ cao cộng y của gốc");
    const Ray down{.origin = Vec3{.x = -4625.0F, .y = 500.0F, .z = -20762.5F},
        .direction = Vec3{.x = 0.0F, .y = -1.0F, .z = 0.0F}};
    const auto hit = ground->intersect(down);
    const Vec3 want{.x = -4625.0F, .y = 75.0F, .z = -20762.5F};
    context.expect(hit && near_point(*hit, want), "tia đứng theo gốc");
}

// Ô (0, 0) không lật: x + z <= 1 thì tam giác quanh (0, 0), còn lại quanh (1, 1).
void height_default(Context& context) {
    const auto ground = bumpy({});
    if (!ground) return;
    // (0.25, 0.25): t = h(0,0) = 0; h = 0 + 10 * 0.25 + 0 * 0.25 = 2.5; y = 2 * 2.5.
    context.expect(near_value(ground->height_at(-75.0F, -37.5F), 5.0F), "tam giác gần gốc ô");
    // (0.75, 0.75): t = h(1,1) = 40; h = 40 - 30 * 0.25 - 40 * 0.25 = 22.5; y = 45. Song tuyến
    // ra 48.75.
    context.expect(near_value(ground->height_at(-25.0F, -12.5F), 45.0F), "không phải song tuyến");
    // (0.75, 0.25): x + z = 1 nên vẫn tam giác gần gốc: h = 10 * 0.75 = 7.5; y = 15.
    context.expect(near_value(ground->height_at(-25.0F, -37.5F), 15.0F), "trên đường chéo mặc định");
}

// Ô (0, 0) lật: z <= x thì tam giác quanh (1, 0), còn lại quanh (0, 1).
void height_flipped(Context& context) {
    const auto ground = bumpy({true, false, false, false});
    if (!ground) return;
    // (0.75, 0.25): t = h(1,0) = 10; h = 10 - 10 * 0.25 + 30 * 0.25 = 15; y = 30.
    context.expect(near_value(ground->height_at(-25.0F, -37.5F), 30.0F), "ô lật, tam giác phải trên");
    // (0.25, 0.75): t = h(0,1) = 0; h = 0 + 0 * 0.25 + 40 * 0.25 = 10; y = 20.
    context.expect(near_value(ground->height_at(-75.0F, -12.5F), 20.0F), "ô lật, tam giác trái dưới");
}

// Ngoài map thì kẹp về mép, như getHeightAt.
void height_clamped(Context& context) {
    const auto ground = bumpy({});
    if (!ground) return;
    context.expect(near_value(ground->height_at(-500.0F, -25.0F), 0.0F), "kẹp mép trái");
    // x >= max: chỉ số 1, phần lẻ 1; z = 0.5 trong ô 0: x + z > 1 nên t = h(2,1) = 20.
    context.expect(near_value(ground->height_at(500.0F, -25.0F), 40.0F), "kẹp mép phải");
    context.expect(near_value(ground->height_at(500.0F, 500.0F), 0.0F), "kẹp góc xa");
}

// Tia thẳng đứng đi xuống: trường hợp riêng của getIntersects, lấy luôn độ cao tại (x, z).
void ray_vertical(Context& context) {
    const auto ground = bumpy({});
    if (!ground) return;
    const Vec3 down_direction{.x = 0.0F, .y = -1.0F, .z = 0.0F};
    const Ray down{.origin = Vec3{.x = -25.0F, .y = 500.0F, .z = -12.5F}, .direction = down_direction};
    const auto hit = ground->intersect(down);
    context.expect(hit && near_point(*hit, Vec3{.x = -25.0F, .y = 45.0F, .z = -12.5F}), "tia đứng chạm đúng độ cao");
    const Ray rising{.origin = down.origin, .direction = Vec3{.x = 0.0F, .y = 1.0F, .z = 0.0F}};
    context.expect(!ground->intersect(rising).has_value(), "tia đứng đi lên không chạm");
    const Ray outside{.origin = Vec3{.x = -500.0F, .y = 500.0F, .z = 0.0F}, .direction = down_direction};
    context.expect(!ground->intersect(outside).has_value(), "tia đứng ngoài map không chạm");
    const Ray below{.origin = Vec3{.x = -25.0F, .y = 1.0F, .z = -12.5F}, .direction = down_direction};
    context.expect(!ground->intersect(below).has_value(), "gốc tia dưới mặt đất không chạm");
}

// Map phẳng 4 x 4 ô, tỉ lệ 1, gốc (-2, 0, -2): tia chéo cắt mặt y = 0 tại điểm tính tay.
void ray_flat(Context& context) {
    const Vec3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const auto ground = Ground::create(shape_of(4, 4, unit, std::vector<float>(25, 0.0F)));
    if (!ground) return;
    const Ray slant{
        .origin = Vec3{.x = -1.5F, .y = 1.0F, .z = -1.5F}, .direction = Vec3{.x = 1.0F, .y = -1.0F, .z = 1.0F}};
    const auto hit = ground->intersect(slant);
    context.expect(hit && near_point(*hit, Vec3{.x = -0.5F, .y = 0.0F, .z = -0.5F}), "tia chéo chạm mặt phẳng");
    const Ray miss{.origin = slant.origin, .direction = Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F}};
    context.expect(!ground->intersect(miss).has_value(), "tia đi lên không chạm");
    const Ray away{
        .origin = Vec3{.x = 10.0F, .y = 1.0F, .z = 10.0F}, .direction = Vec3{.x = 1.0F, .y = -1.0F, .z = 0.0F}};
    context.expect(!ground->intersect(away).has_value(), "tia không qua hộp bao");
    const float nan = std::nanf("");
    const Ray broken{.origin = slant.origin, .direction = Vec3{.x = nan, .y = -1.0F, .z = 1.0F}};
    context.expect(!ground->intersect(broken).has_value(), "tia có NaN không chạm");
}

// Điểm của tia ở khoảng distance có nằm dưới mặt đất không.
[[nodiscard]] bool below_ground(const Ground& ground, const Ray& ray, float distance) {
    const Vec3 step = ogre::scale_vec3(ray.direction, distance);
    const Vec3 point = ogre::add_vec3(ray.origin, step);
    return point.y < ground.height_at(point.x, point.z) - 1e-3F;
}

// Có gò cao: điểm chạm nằm trên tia, đúng trên mặt đất, và không có điểm nào trước nó nằm dưới đất.
void ray_hill(Context& context) {
    std::vector<float> heights(25, 0.0F);
    heights.at((2 * 5) + 2) = 3.0F;
    const Vec3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const auto ground = Ground::create(shape_of(4, 4, unit, std::move(heights)));
    if (!ground) return;
    const Ray ray{
        .origin = Vec3{.x = -2.0F, .y = 1.5F, .z = 0.0F}, .direction = Vec3{.x = 1.0F, .y = -0.1F, .z = 0.0F}};
    const auto hit = ground->intersect(ray);
    context.expect(hit.has_value(), "tia chạm sườn gò");
    if (!hit) return;
    context.expect(near_value(hit->y, ground->height_at(hit->x, hit->z)), "điểm chạm nằm trên mặt đất");
    context.expect(hit->x < 0.0F, "chạm sườn trước, không xuyên qua gò");
    const float travelled = hit->x - ray.origin.x;
    const std::array<float, 4> fractions = {0.2F, 0.4F, 0.6F, 0.8F};
    bool is_clear = true;
    for (const float fraction : fractions) {
        is_clear = is_clear && !below_ground(*ground, ray, travelled * fraction);
    }
    context.expect(is_clear, "không điểm nào trước điểm chạm nằm dưới đất");
}

// Tia màn hình

[[nodiscard]] control::Lens lens_looking_down() {
    control::Lens lens;
    lens.eye = Vec3{.x = 0.0F, .y = 10.0F, .z = -10.0F};
    lens.forward = ogre::normalize_vec3(Vec3{.x = 0.0F, .y = -1.0F, .z = 1.0F});
    lens.fov_y = std::numbers::pi_v<float> / 3.0F;
    lens.aspect = 2.0F;
    return lens;
}

// Điểm giữa màn hình đi đúng hướng nhìn. Hệ toạ độ là tay phải như OGRE: nhìn về +z thì +x nằm bên
// TRÁI màn hình, nên sang phải màn hình là sang -x; lên trên màn hình là ra xa (về +z) khi nhìn
// xuống.
void screen_rays(Context& context) {
    const control::Lens lens = lens_looking_down();
    const Ray middle = control::screen_ray(lens, control::ScreenPoint{.x = 0.5F, .y = 0.5F});
    context.expect(near_point(middle.direction, lens.forward), "giữa màn hình đi theo hướng nhìn");
    const Ray right = control::screen_ray(lens, control::ScreenPoint{.x = 1.0F, .y = 0.5F});
    context.expect(right.direction.x < -0.1F, "mép phải màn hình lệch sang -x khi nhìn về +z");
    const Ray top = control::screen_ray(lens, control::ScreenPoint{.x = 0.5F, .y = 0.0F});
    const Ray bottom = control::screen_ray(lens, control::ScreenPoint{.x = 0.5F, .y = 1.0F});
    context.expect(top.direction.z > bottom.direction.z, "mép trên nhìn xa hơn mép dưới");
    context.expect(near_value(ogre::length_vec3(right.direction), 1.0F), "hướng là vector đơn vị");
    // Mép phải: tan(30 độ) * 2 = 1,1547 so với hướng nhìn, đo trên mặt phẳng vuông góc hướng nhìn.
    const float across = ogre::dot_vec3(right.direction, Vec3{.x = -1.0F, .y = 0.0F, .z = 0.0F});
    const float along = ogre::dot_vec3(right.direction, lens.forward);
    context.expect(near_value(across / along, std::tan(std::numbers::pi_v<float> / 6.0F) * 2.0F),
        "nửa rộng mặt gần bằng tan(fov / 2) nhân tỉ lệ khung");
}

// Số đỉnh của map vuông 20 x 20 ô.
constexpr std::size_t kCorners = 441;

// Chọn điểm đất: tia từ giữa màn hình xuống mặt phẳng y = 0 cắt tại (0, 0, 0) khi mắt ở (0, 10,
// -10) nhìn xiên 45 độ; điểm đó đổi ra toạ độ game theo gốc và tỉ lệ của map.
void ground_pick(Context& context) {
    const Vec3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const auto ground = Ground::create(shape_of(20, 20, unit, std::vector<float>(kCorners, 0.0F)));
    if (!ground) return;
    const control::Lens lens = lens_looking_down();
    const auto pick = control::pick_ground(*ground, lens, control::ScreenPoint{.x = 0.5F, .y = 0.5F});
    context.expect(pick.has_value(), "chọn được điểm đất");
    // Gốc map (-10, 0, -10): thế giới (0, 0, 0) là game (10, 10).
    context.expect(pick && near_value(pick->x, 10.0F) && near_value(pick->z, 10.0F), "giữa màn hình");
    const auto sky = control::pick_ground(*ground, lens, control::ScreenPoint{.x = 0.5F, .y = 0.0F});
    context.expect(!sky || sky->z > 10.0F, "mép trên chạm xa hơn hoặc trượt");
}

// Camera bám theo và va chạm của mắt

// Map vuông cạnh size ô, tỉ lệ scale, mọi đỉnh cao 0 trừ các hàng z >= raised_row cao raised.
[[nodiscard]] std::optional<Ground> square_map(int size, Vec3 scale, int raised_row, float raised) {
    std::vector<float> heights;
    for (int row = 0; row <= size; ++row) {
        const float value = row >= raised_row ? raised : 0.0F;
        heights.insert(heights.end(), static_cast<std::size_t>(size) + 1U, value);
    }
    return Ground::create(shape_of(size, size, scale, std::move(heights)));
}

void ground_sphere(Context& context) {
    // 8 x 8 ô, tỉ lệ 1, gốc (-4, 0, -4), phẳng ở 0.
    const Vec3 unit{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const auto ground = square_map(8, unit, 99, 0.0F);
    context.expect(ground.has_value(), "dựng map phẳng");
    if (!ground) return;
    context.expect(near_value(ground->base_scale(), 1.0F), "thước camera");
    const Vec3 above{.x = 0.0F, .y = 5.0F, .z = 0.0F};
    context.expect(!ground->touches_sphere(above, 0.25F), "quả cầu cao hơn mặt đất");
    const Vec3 low{.x = 0.2F, .y = 0.1F, .z = 0.3F};
    context.expect(ground->touches_sphere(low, 0.25F), "quả cầu sát mặt đất");
    const Vec3 outside{.x = 50.0F, .y = 0.0F, .z = 0.0F};
    context.expect(!ground->touches_sphere(outside, 0.25F), "ngoài map");
    using control::EyeProbe;
    context.expect(ground->probe_sphere(outside, 0.25F) == EyeProbe::kNoPatch, "ngoài map");
    context.expect(ground->probe_sphere(above, 0.25F) == EyeProbe::kClear, "trên cao: trống");
    context.expect(ground->probe_sphere(low, 0.25F) == EyeProbe::kTouching, "sát đất: chạm");
    // Đỉnh gần nhất là góc (0, 0) của map: chỉ một ô hợp lệ nên bản gốc coi như không chạm.
    const Vec3 corner{.x = -3.9F, .y = 0.0F, .z = -3.9F};
    context.expect(!ground->touches_sphere(corner, 0.25F), "góc map, chỉ một ô");
    context.expect(ground->probe_sphere(corner, 0.25F) == EyeProbe::kNoPatch, "góc map: không ô");
    // Mép map, không phải góc: hai ô hợp lệ nên vẫn xét.
    const Vec3 edge{.x = 0.1F, .y = 0.0F, .z = -3.9F};
    context.expect(ground->touches_sphere(edge, 0.25F), "mép map, hai ô");
}

void cursor_names(Context& context) {
    context.expect(control::kCursorNames.size() == control::kCursorKinds, "23 loại");
    context.expect(control::cursor_name(control::CursorKind::kNormal) == "normal", "chỉ số 1");
    const auto down = control::cursor_name(control::CursorKind::kNormalDown);
    context.expect(down == "normal_down", "chỉ số 2 là thường đang nhấn");
    context.expect(control::cursor_name(control::CursorKind::kAttack) == "attack", "chỉ số 3");
    context.expect(control::cursor_name(control::CursorKind::kBowDown) == "bow_down", "chỉ số 22");
    const auto pet = control::cursor_named("catch_pet");
    context.expect(pet == control::CursorKind::kCatchPet, "tra theo tên");
    context.expect(!control::cursor_named("khong_co"), "tên lạ");
    const std::set<std::string_view> unique(control::kCursorNames.begin(), control::kCursorNames.end());
    context.expect(unique.size() == control::kCursorKinds, "không trùng tên");
}

control::CursorState hovering(control::HoverKind kind) {
    control::CursorState state;
    state.hover = kind;
    return state;
}

void cursor_rules(Context& context) {
    const control::CursorState idle;
    const auto idle_kind = control::choose_cursor(idle);
    context.expect(idle_kind == control::CursorKind::kNormal, "không có gì dưới chuột");
    control::CursorState pressed;
    pressed.primary_down = true;
    const auto down = control::choose_cursor(pressed);
    context.expect(down == control::CursorKind::kNormalDown, "thường đang nhấn");
    const control::CursorState npc_state = hovering(control::HoverKind::kNpc);
    const auto npc = control::choose_cursor(npc_state);
    context.expect(npc == control::CursorKind::kSpeak, "NPC: nói chuyện");
    const control::CursorState monster_state = hovering(control::HoverKind::kMonster);
    const auto monster = control::choose_cursor(monster_state);
    context.expect(monster == control::CursorKind::kAttack, "quái: tấn công");
    control::CursorState pressed_npc = npc_state;
    pressed_npc.primary_down = true;
    const auto still_speak = control::choose_cursor(pressed_npc);
    context.expect(still_speak == control::CursorKind::kSpeak, "chỉ con trỏ thường có biến thể nhấn");
    const control::CursorState other_state = hovering(control::HoverKind::kOtherPlayer);
    const auto other = control::choose_cursor(other_state);
    context.expect(other == control::CursorKind::kNormal, "người chơi khác");
    const control::CursorState self_state = hovering(control::HoverKind::kMyself);
    const auto self = control::choose_cursor(self_state);
    context.expect(self == control::CursorKind::kNormal, "chính mình");
    const control::CursorState pet_state = hovering(control::HoverKind::kPet);
    const auto pet = control::choose_cursor(pet_state);
    context.expect(pet == control::CursorKind::kNormal, "thú của mình");
    control::CursorState over_ui = monster_state;
    over_ui.over_ui = true;
    const auto on_ui = control::choose_cursor(over_ui);
    context.expect(on_ui == control::CursorKind::kNormal, "trên giao diện thì không xét thế giới");
    control::CursorState running = monster_state;
    running.auto_run = true;
    const auto running_kind = control::choose_cursor(running);
    context.expect(running_kind == control::CursorKind::kAutoRun, "tự chạy đè lên con trỏ thế giới");
    running.camera_held = true;
    context.expect(!control::choose_cursor(running), "đang kéo camera thì ẩn");
}

[[nodiscard]] control::Box box_between(Vec3 low, Vec3 high) {
    return control::Box{.min = low, .max = high};
}

[[nodiscard]] Ray ray_toward(Vec3 origin, Vec3 direction) {
    return Ray{.origin = origin, .direction = direction};
}

[[nodiscard]] control::Pickable actor_of(control::HoverKind kind, control::Box mesh) {
    control::Pickable item;
    item.kind = kind;
    item.meshes.push_back(mesh);
    return item;
}

void ray_box_hits(Context& context) {
    const Vec3 low{.x = -1.0F, .y = -1.0F, .z = -1.0F};
    const Vec3 high{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const control::Box cube = box_between(low, high);
    const Ray inside = ray_toward({}, Vec3{.z = -1.0F});
    const auto inside_hit = control::ray_box(inside, cube);
    context.expect(inside_hit == 0.0F, "gốc trong hộp thì khoảng 0");
    const Ray front = ray_toward(Vec3{.z = 5.0F}, Vec3{.z = -1.0F});
    const auto front_hit = control::ray_box(front, cube);
    const bool hit_face = front_hit.has_value() && near_value(*front_hit, 4.0F);
    context.expect(hit_face, "chạm mặt z = 1 ở khoảng 4");
    const Ray miss = ray_toward(Vec3{.y = 10.0F, .z = 5.0F}, Vec3{.z = -1.0F});
    context.expect(!control::ray_box(miss, cube), "tia lệch không chạm");
    control::BoxFrame shift;
    shift.origin = Vec3{.x = 10.0F};
    const control::Box moved = control::transform_box(cube, shift);
    const bool shifted = near_value(moved.min.x, 9.0F) && near_value(moved.max.x, 11.0F);
    context.expect(shifted, "tịnh tiến hộp theo trục x");
    const control::Box body = control::external_box(Vec3{.x = 2.0F, .y = 3.0F, .z = 4.0F});
    const bool floor = near_value(body.min.x, -1.0F) && near_value(body.min.y, 0.0F);
    const bool top = near_value(body.max.y, 3.0F) && near_value(body.max.z, 2.0F);
    context.expect(floor && top, "hộp ngoài từ kích thước x y z");
}

void hover_pick(Context& context) {
    const Ray ray = ray_toward(Vec3{.z = 10.0F}, Vec3{.z = -1.0F});
    const Vec3 self_low{.x = -0.5F, .y = -0.5F, .z = 3.0F};
    const Vec3 self_high{.x = 0.5F, .y = 0.5F, .z = 4.0F};
    const Vec3 npc_low{.x = -0.5F, .y = -0.5F, .z = -2.0F};
    const Vec3 npc_high{.x = 0.5F, .y = 0.5F, .z = -1.0F};
    const control::Box self_box = box_between(self_low, self_high);
    const control::Box npc_box = box_between(npc_low, npc_high);
    const control::Pickable self = actor_of(control::HoverKind::kMyself, self_box);
    const control::Pickable npc = actor_of(control::HoverKind::kNpc, npc_box);
    const std::array<control::Pickable, 2> crowd{self, npc};
    const auto chosen = control::pick_hover(ray, crowd);
    context.expect(chosen == 1U, "NPC lớp 3 thắng mình lớp 6 dù xa hơn");
    control::Pickable blocked = npc;
    const Vec3 guard_low{.x = 10.0F, .y = 10.0F, .z = 10.0F};
    const Vec3 guard_high{.x = 12.0F, .y = 12.0F, .z = 12.0F};
    blocked.external = box_between(guard_low, guard_high);
    const std::array<control::Pickable, 1> guarded{blocked};
    context.expect(!control::pick_hover(ray, guarded), "hộp ngoài trượt thì bỏ");
    const Vec3 near_low{.x = -0.5F, .y = -0.5F, .z = 6.0F};
    const Vec3 near_high{.x = 0.5F, .y = 0.5F, .z = 8.0F};
    const control::Box near_box = box_between(near_low, near_high);
    const control::Pickable far_npc = actor_of(control::HoverKind::kNpc, npc_box);
    const control::Pickable near_npc = actor_of(control::HoverKind::kNpc, near_box);
    const std::array<control::Pickable, 2> pair{far_npc, near_npc};
    const auto nearer = control::pick_hover(ray, pair);
    context.expect(nearer == 1U, "cùng lớp thì lấy cái gần");
    const std::span<const control::Pickable> none;
    context.expect(!control::pick_hover(ray, none), "không có gì thì không chọn");
}

void role_track_faces_the_feet(Context& context) {
    const control::RolePlace& slot = control::role_place(0);
    const ogre::Vec3 back{.x = 0.0F, .y = 0.0F, .z = -1.0F};
    const ogre::Vec3 forward = ogre::quat_rotate(control::kRoleLook, back);
    const float across = slot.feet.x - slot.eye.x;
    const float rise = slot.feet.y - slot.eye.y;
    const float depth = slot.feet.z - slot.eye.z;
    const float toward = (across * forward.x) + (rise * forward.y) + (depth * forward.z);
    context.expect(slot.feet.y == control::bits(0x448F4000u), "chân ô 0 cao 1146");
    context.expect(control::role_place(1).eye.x < 0.0F, "ô 1 nằm bên âm x");
    context.expect(control::role_place(2).eye.x > slot.eye.x, "ô 2 nằm bên phải ô 0");
    context.expect(toward > 200.0F, "camera nghỉ nhìn về phía chân");
    context.expect(control::kRoleFov == 65.0F, "góc nhìn dọc 65 độ");
}

void char_sel_camera_matches_the_binary(Context& context) {
    const control::CharSight sight = control::char_sel_sight();
    context.expect(std::fabs(sight.target_y - 80.0F) < 0.001F, "nhìn vào cao 80 cm");
    context.expect(std::fabs(sight.eye_x) < 0.001F, "mắt không lệch ngang");
    context.expect(std::fabs(sight.eye_y - 166.824F) < 0.02F, "mắt cao theo pitch −10 độ");
    context.expect(std::fabs(sight.eye_z - 492.404F) < 0.02F, "mắt lùi 500 cm");
    context.expect(std::fabs(control::kCharFar - 100000.0F) < 0.1F, "mặt cắt xa 100000");
}

constexpr std::array kCases{
    Case{.name = "create_rejects", .body = &create_rejects},
    Case{.name = "coordinates", .body = &coordinates},
    Case{.name = "coordinates_offset", .body = &coordinates_offset},
    Case{.name = "height_default", .body = &height_default},
    Case{.name = "height_flipped", .body = &height_flipped},
    Case{.name = "height_clamped", .body = &height_clamped},
    Case{.name = "ray_vertical", .body = &ray_vertical},
    Case{.name = "ray_flat", .body = &ray_flat},
    Case{.name = "ray_hill", .body = &ray_hill},
    Case{.name = "screen_rays", .body = &screen_rays},
    Case{.name = "ground_pick", .body = &ground_pick},
    Case{.name = "ground_sphere", .body = &ground_sphere},
    Case{.name = "cursor_names", .body = &cursor_names},
    Case{.name = "cursor_rules", .body = &cursor_rules},
    Case{.name = "ray_box_hits", .body = &ray_box_hits},
    Case{.name = "hover_pick", .body = &hover_pick},
    Case{.name = "role_track_faces_the_feet", .body = &role_track_faces_the_feet},
    Case{.name = "char_sel_camera_matches_the_binary", .body = &char_sel_camera_matches_the_binary},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "control_tests: mọi ca phải qua");
    return 0;
}
