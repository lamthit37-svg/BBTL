// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
// Test của render/shade: phần màu của khối hằng Draw tính từ chất liệu và ánh sáng của khung, phép
// chọn đèn điểm cho một vật thể, và phép chọn bản sao còn trong khung nhìn kèm đèn của từng bản; kèm
// phép kiểm gói shader lệch đời của render/detail/shaders.
#include "core/check.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/detail/shaders.hpp"
#include "render/forward.hpp"
#include "classic/bake.hpp"
#include "render/shade.hpp"
#include "render/view_size.hpp"
#include "resource/model.hpp"
#include "shader/reflection.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <vector>

namespace game::test {
namespace {

using render::Lamp;
using render::Lighting;
using render::Reach;
using render::Shade;
using render::ShadeAsk;

[[nodiscard]] bool near_value(float left, float right) noexcept {
    return std::fabs(left - right) < 1.0e-6F;
}

[[nodiscard]] bool is_rgb(const math::Float4& value, const math::Float3& wanted) noexcept {
    return near_value(value.x, wanted.x) && near_value(value.y, wanted.y) && near_value(value.z, wanted.z);
}

[[nodiscard]] Lighting valley_light() noexcept {
    Lighting lighting;
    lighting.ambient = math::Vector3(0.4F, 0.1F, 0.0F);
    lighting.actor_ambient = math::Vector3(0.5F, 0.5F, 0.5F);
    lighting.specular = math::Vector3(0.3F, 0.2F, 0.1F);
    return lighting;
}

[[nodiscard]] Shade shade(const resource::Material* material, const Lighting& lighting) noexcept {
    return render::shade_of(ShadeAsk{.material = material, .lighting = &lighting});
}

// Primitive không khai chất liệu: mặc định của Ogre::Pass, nhân màu đỉnh như cách vẽ cũ.
void bare_primitive_gets_scene_ambient(Context& context) {
    const Lighting lighting = valley_light();
    const Shade made = shade(nullptr, lighting);
    context.expect(is_rgb(made.glow, {.x = 0.4F, .y = 0.1F, .z = 0.0F}), "ánh sáng nền là ambient của cảnh");
    context.expect(is_rgb(made.diffuse, {.x = 1.0F, .y = 1.0F, .z = 1.0F}), "diffuse trắng");
    context.expect(is_rgb(made.base_color, {.x = 1.0F, .y = 1.0F, .z = 1.0F}), "màu nền trắng");
    context.expect(made.base_color.w == 1.0F && made.diffuse.w == 0.0F, "alpha 1, không cắt");
    context.expect(made.flags == render::kVertexColor, "chỉ bật nhân màu đỉnh");
}

// 自然石柱: emissive 0,15 cộng vào ánh sáng nền; specular nhân màu specular của đèn chính một.
void classic_material_adds_emissive_and_specular(Context& context) {
    const Lighting lighting = valley_light();
    resource::Material material;
    classic::Classic classic;
    classic.ambient = {.x = 0.5F, .y = 0.5F, .z = 0.5F};
    classic.emissive = {.x = 0.15F, .y = 0.15F, .z = 0.15F};
    classic.specular = {.x = 0.5F, .y = 0.5F, .z = 0.5F};
    classic.shininess = 12.8F;
    classic.diffuse = {.x = 0.9F, .y = 0.8F, .z = 0.7F, .w = 0.5F};
    material.pass = classic::pass_of(classic);
    material.alpha = resource::Alpha::kMask;
    material.alpha_cutoff = 0.5F;
    const Shade made = shade(&material, lighting);
    context.expect(is_rgb(made.glow, {.x = 0.35F, .y = 0.2F, .z = 0.15F}),
        "ambient nhân ambient chất liệu, cộng emissive");
    context.expect(near_value(made.glow.w, 12.8F), "shininess đi cùng ánh sáng nền");
    context.expect(is_rgb(made.diffuse, {.x = 0.9F, .y = 0.8F, .z = 0.7F}), "diffuse của chất liệu");
    context.expect(near_value(made.diffuse.w, 0.5F), "ngưỡng cắt alpha của glTF");
    context.expect(near_value(made.base_color.w, 0.5F), "alpha của diffuse nhân vào hệ số alpha");
    context.expect(is_rgb(made.specular, {.x = 0.15F, .y = 0.1F, .z = 0.05F}), "specular nhân specular của đèn");
    context.expect(made.flags == render::kSpecular, "có specular, không nhân màu đỉnh");
}

void actor_uses_actor_ambient(Context& context) {
    const Lighting lighting = valley_light();
    resource::Material material;
    material.pass = classic::pass_of(classic::Classic{});
    const ShadeAsk ask{.material = &material, .lighting = &lighting, .is_actor = true};
    const Shade made = render::shade_of(ask);
    context.expect(is_rgb(made.glow, {.x = 0.5F, .y = 0.5F, .z = 0.5F}), "nhân vật nhận ambient riêng");
    context.expect(made.flags == render::kActor, "bật cờ nhân vật");
}

void texture_op_scales_or_adds(Context& context) {
    const Lighting lighting = valley_light();
    resource::Material material;
    material.base_color = {.x = 0.5F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    classic::Classic classic;
    classic.combine = classic::TexOp::kModulate2;
    material.pass = classic::pass_of(classic);
    context.expect(is_rgb(shade(&material, lighting).base_color, {.x = 1.0F, .y = 2.0F, .z = 2.0F}), "nhân 2");
    classic.combine = classic::TexOp::kModulate4;
    material.pass = classic::pass_of(classic);
    context.expect(is_rgb(shade(&material, lighting).base_color, {.x = 2.0F, .y = 4.0F, .z = 4.0F}), "nhân 4");
    classic.combine = classic::TexOp::kAdd;
    material.pass = classic::pass_of(classic);
    const Shade added = shade(&material, lighting);
    context.expect(is_rgb(added.base_color, {.x = 0.5F, .y = 1.0F, .z = 1.0F}), "cộng thì không nhân hệ số");
    context.expect(added.flags == render::kAddLight, "bật cờ cộng ánh sáng");
}

void lit_kinds_and_fog_set_their_bits(Context& context) {
    const Lighting lighting = valley_light();
    resource::Material material;
    classic::Classic classic;
    classic.specular = {.x = 1.0F, .y = 1.0F, .z = 1.0F};
    classic.lit = classic::Lit::kPixel;
    material.pass = classic::pass_of(classic);
    const std::uint32_t pixel = render::kPixelLit | render::kSpecular;
    context.expect(shade(&material, lighting).flags == pixel, "pslit tính ở điểm ảnh, có specular");
    classic.lit = classic::Lit::kTerrain;
    material.pass = classic::pass_of(classic);
    const std::uint32_t terrain = render::kPixelLit | render::kRawSum | render::kSpecular;
    context.expect(shade(&material, lighting).flags == terrain, "địa hình không kẹp từng đèn");
    classic.lit = classic::Lit::kOff;
    classic.has_fog = false;
    classic.tracks_vertex = true;
    material.pass = classic::pass_of(classic);
    const std::uint32_t off = render::kNoFog | render::kVertexColor;
    context.expect(shade(&material, lighting).flags == off, "lighting off bỏ specular; không sương");
}

// Chất liệu glTF unlit không có Classic vẫn là unlit; có Classic thì luật của OGRE thắng.
void gltf_unlit_only_without_classic(Context& context) {
    const Lighting lighting = valley_light();
    resource::Material material;
    material.unlit = true;
    const std::uint32_t plain = render::kUnlit | render::kVertexColor;
    context.expect(shade(&material, lighting).flags == plain, "unlit của glTF");
    material.pass = classic::pass_of(classic::Classic{});
    context.expect(shade(&material, lighting).flags == 0, "có Classic thì vẫn nhận ánh sáng");
}

// Đèn tầm 500 nằm trên trục x.
[[nodiscard]] Lamp lamp_at(float along_x) noexcept {
    Lamp lamp;
    lamp.position = math::Vector3(along_x, 0.0F, 0.0F);
    lamp.range = 500.0F;
    return lamp;
}

void nearest_lamp_needs_reach_and_prefers_the_closer(Context& context) {
    // Đèn 2 gần gốc nhất nhưng tầm 0 nên bị bỏ qua.
    std::array<Lamp, 4> lamps{lamp_at(900.0F), lamp_at(-300.0F), lamp_at(100.0F), lamp_at(200.0F)};
    lamps[2].range = 0.0F;
    const Reach at_origin{};
    context.expect(render::nearest_lamp(lamps, at_origin) == 3, "đèn gần nhất còn với tới");
    const Reach far_away{.centre = math::Vector3(2000.0F, 0.0F, 0.0F)};
    context.expect(render::nearest_lamp(lamps, far_away) == render::kNoLamp, "ngoài tầm mọi đèn");
    // Cách đèn 0 đúng 600: tầm 500 không tới, cộng bán kính bao 100 thì vừa tới.
    const Reach edge{.centre = math::Vector3(1500.0F, 0.0F, 0.0F), .radius = 100.0F};
    context.expect(render::nearest_lamp(lamps, edge) == 0, "tầm cộng bán kính bao");
    const Reach short_edge{.centre = math::Vector3(1500.0F, 0.0F, 0.0F), .radius = 99.0F};
    context.expect(render::nearest_lamp(lamps, short_edge) == render::kNoLamp, "thiếu một đơn vị");
    const std::vector<Lamp> none;
    context.expect(render::nearest_lamp(none, at_origin) == render::kNoLamp, "cảnh không đèn");
}

// Camera đứng ở gốc nhìn theo -z, khung vuông, FOV dọc 90 độ: điểm (x, y, z) còn trong khung khi
// |x| và |y| không quá -z.
[[nodiscard]] render::Frustum forward_view() noexcept {
    render::Lens lens;
    lens.fov_degrees = 90.0F;
    lens.near_plane = 1.0F;
    lens.far_plane = 100000.0F;
    const render::ViewSize square{.width = 512, .height = 512};
    const math::Point3 eye(0.0F, 0.0F, 0.0F);
    const math::Point3 ahead(0.0F, 0.0F, -1.0F);
    const render::Camera camera = render::look_camera(eye, ahead, lens, square);
    return render::frustum_of(camera.projection * camera.view);
}

// Bản sao đứng cách camera 1000 về phía trước, lệch ngang along_x.
[[nodiscard]] math::Matrix4 copy_at(float along_x) noexcept {
    return math::Matrix4::translation(math::Vector3(along_x, 0.0F, -1000.0F));
}

[[nodiscard]] bool is_seen(const render::SeenCopy& copy, const render::SeenCopy& wanted) noexcept {
    return copy.index == wanted.index && copy.lamp == wanted.lamp;
}

void reach_follows_place_and_largest_scale(Context& context) {
    const math::Matrix4 placed = math::Matrix4::translation(math::Vector3(1.0F, 2.0F, 3.0F)) *
                                 math::Matrix4::scale(math::Vector3(2.0F, 5.0F, 3.0F));
    const Reach reach = render::reach_at(placed, 10.0F);
    context.expect(near_value(reach.centre.x(), 1.0F) && near_value(reach.centre.y(), 2.0F), "gốc theo phép dời");
    context.expect(near_value(reach.centre.z(), 3.0F), "gốc theo phép dời, trục z");
    context.expect(near_value(reach.radius, 50.0F), "bán kính nhân tỉ lệ lớn nhất trong ba trục");
}

// Mỗi bản sao mang đèn của riêng nó và giữ thứ tự gốc: bản 0 và bản 3 cùng đèn nhưng không bị gom
// lại cạnh nhau, vì cả đám vẽ bằng một lệnh chứ không còn một lệnh cho mỗi đèn.
void copies_keep_order_and_their_own_lamp(Context& context) {
    Lamp left = lamp_at(-300.0F);
    left.position = math::Vector3(-300.0F, 0.0F, -1000.0F);
    left.range = 150.0F;
    Lamp right = left;
    right.position = math::Vector3(300.0F, 0.0F, -1000.0F);
    const std::array<Lamp, 2> lamps{left, right};
    const std::array<math::Matrix4, 4> copies{copy_at(-300.0F), copy_at(-100.0F), copy_at(300.0F), copy_at(-250.0F)};
    std::vector<render::SeenCopy> seen{render::SeenCopy{.index = 99, .lamp = 7}};
    render::see_copies({.copies = copies, .lamps = lamps, .radius = 10.0F}, forward_view(), seen);
    context.expect(seen.size() == 4, "bốn bản đều trong khung; nội dung cũ của seen bị xoá");
    if (seen.size() != 4) return;
    context.expect(is_seen(seen[0], {.index = 0, .lamp = 0}), "bản 0 nhận đèn trái");
    context.expect(is_seen(seen[1], {.index = 1, .lamp = render::kNoLamp}), "bản 1 ngoài tầm cả hai đèn");
    context.expect(is_seen(seen[2], {.index = 2, .lamp = 1}), "bản 2 nhận đèn phải");
    context.expect(is_seen(seen[3], {.index = 3, .lamp = 0}), "bản 3 nhận đèn trái, vẫn đứng sau bản 2");
}

// Mặt trái của khung ở độ sâu 1000 là x = -1000; khoảng cách tới mặt là (x + 1000) / căn 2.
void copies_outside_the_view_are_dropped(Context& context) {
    const math::Matrix4 behind = math::Matrix4::translation(math::Vector3(0.0F, 0.0F, 1000.0F));
    const math::Matrix4 grown = copy_at(-1020.0F) * math::Matrix4::scale(math::Vector3(2.0F, 2.0F, 2.0F));
    const std::array<math::Matrix4, 6> copies{
        copy_at(0.0F), behind, copy_at(-2000.0F), copy_at(-1010.0F), copy_at(-1020.0F), grown};
    std::vector<render::SeenCopy> seen;
    render::see_copies({.copies = copies, .lamps = {}, .radius = 10.0F}, forward_view(), seen);
    context.expect(seen.size() == 3, "ba bản còn chạm khung nhìn");
    if (seen.size() != 3) return;
    context.expect(is_seen(seen[0], {.index = 0, .lamp = render::kNoLamp}), "bản giữa khung");
    // Tâm ngoài mặt trái 7,07 đơn vị, bán kính 10 còn thò vào.
    context.expect(is_seen(seen[1], {.index = 3, .lamp = render::kNoLamp}), "bản thò vào khung được giữ");
    // Tâm ngoài 14,1 đơn vị: bán kính 10 thì loại, tỉ lệ 2 (bán kính 20) thì giữ.
    context.expect(is_seen(seen[2], {.index = 5, .lamp = render::kNoLamp}), "tỉ lệ của bản sao nới bán kính bao");
    const std::vector<math::Matrix4> none;
    render::see_copies({.copies = none, .lamps = {}, .radius = 10.0F}, forward_view(), seen);
    context.expect(seen.empty(), "không có bản sao nào");
}

// Phản chiếu của một stage có khối push constant và hai cbuffer (space 0 là khối của khung).
[[nodiscard]] shader::StageReflection reflection_with(render::detail::BlockSizes packed) {
    shader::StageReflection stage;
    stage.blocks.push_back(shader::Block{.name = "frame", .size = packed.frame, .variables = {}});
    stage.blocks.push_back(shader::Block{.name = "draw", .size = packed.draw, .variables = {}});
    stage.blocks.push_back(shader::Block{.name = "other", .size = 48, .variables = {}});
    shader::Resource frame_buffer;
    frame_buffer.kind = shader::ResourceKind::kUniformBuffer;
    frame_buffer.block = 0;
    shader::Resource push;
    push.kind = shader::ResourceKind::kPushConstant;
    push.block = 1;
    shader::Resource elsewhere;
    elsewhere.kind = shader::ResourceKind::kUniformBuffer;
    elsewhere.space = 1;
    elsewhere.block = 2;
    stage.resources = {frame_buffer, push, elsewhere};
    return stage;
}

// Gói shader cũ (khối 96 byte) nạp cùng mã mới (1280 và 128 byte) phải bị từ chối: đây là lỗi làm
// tablet đen màn hình khi gói trên máy không được giải nén lại.
void stale_shader_package_is_refused(Context& context) {
    const render::detail::BlockSizes sizes{.frame = 1280, .draw = 128};
    const shader::StageReflection fresh = reflection_with(sizes);
    context.expect(render::detail::check_blocks(fresh, sizes, "model.vs").has_value(), "gói đúng đời");
    const render::detail::BlockSizes small_draw{.frame = 1280, .draw = 96};
    const shader::StageReflection old_draw = reflection_with(small_draw);
    context.expect(!render::detail::check_blocks(old_draw, sizes, "model.vs").has_value(), "khối của lệnh vẽ khác cỡ");
    const render::detail::BlockSizes small_frame{.frame = 96, .draw = 128};
    const shader::StageReflection old_frame = reflection_with(small_frame);
    context.expect(!render::detail::check_blocks(old_frame, sizes, "model.vs").has_value(), "khối của khung khác cỡ");
    const render::detail::BlockSizes unchecked{};
    context.expect(render::detail::check_blocks(old_frame, unchecked, "ui.vs").has_value(),
        "không khai cỡ thì không kiểm");
}

constexpr std::array kCases{
    Case{.name = "bare_primitive_gets_scene_ambient", .body = &bare_primitive_gets_scene_ambient},
    Case{.name = "classic_material_adds_emissive_and_specular", .body = &classic_material_adds_emissive_and_specular},
    Case{.name = "actor_uses_actor_ambient", .body = &actor_uses_actor_ambient},
    Case{.name = "texture_op_scales_or_adds", .body = &texture_op_scales_or_adds},
    Case{.name = "lit_kinds_and_fog_set_their_bits", .body = &lit_kinds_and_fog_set_their_bits},
    Case{.name = "gltf_unlit_only_without_classic", .body = &gltf_unlit_only_without_classic},
    Case{.name = "nearest_lamp_needs_reach_and_prefers_the_closer",
        .body = &nearest_lamp_needs_reach_and_prefers_the_closer},
    Case{.name = "reach_follows_place_and_largest_scale", .body = &reach_follows_place_and_largest_scale},
    Case{.name = "copies_keep_order_and_their_own_lamp", .body = &copies_keep_order_and_their_own_lamp},
    Case{.name = "copies_outside_the_view_are_dropped", .body = &copies_outside_the_view_are_dropped},
    Case{.name = "stale_shader_package_is_refused", .body = &stale_shader_package_is_refused},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "shade_tests: mọi ca phải qua");
    return 0;
}

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
