#include "fx/billboard.hpp"
#include "fx/cast.hpp"
#include "fx/field.hpp"
#include "fx/mesh.hpp"
#include "fx/strip.hpp"
#include "fx/system.hpp"

#include "core/check.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

namespace game::test {
namespace {

constexpr std::string_view kTorch = R"(huoba03
{
quota 4
material shidenglong_010
particle_width 40
particle_height 40
renderer billboard
local_space false
emitter Box
{
angle 5
emission_rate 15
velocity_min 2
velocity_max 10
time_to_live_min 0.5
time_to_live_max 0.5
}
affector Rotator
{
rotation_range_end 360
}
affector ScaleInterpolator
{
width_range_start 20
width_range_end 20
height_range_start 30
height_range_end 30
scale1 0 0 0
}
}
)";

constexpr std::string_view kFade = R"(fade
{
quota 8
material white
particle_width 10
particle_height 10
emitter Point
{
emission_rate 30
time_to_live 1
}
affector ColourFading
{
colour0 1 1 1 1
time0 0
colour1 1 1 1 1
time1 1
opacity0 1
opacity1 1
fade_out_time 0
}
}
)";

constexpr std::string_view kSpin = R"(spin
{
quota 4
material white
particle_width 1
particle_height 1
emitter Point
{
emission_rate 100
time_to_live 10
velocity 0
position 1 0 0
}
affector Revolution
{
rotation_speed 90
rotation_axis 0 1 0
}
}
)";

constexpr std::string_view kPole = R"(pole
{
quota 4
material white
particle_width 1
particle_height 1
emitter PolarEmitter
{
emission_rate 100
time_to_live 5
velocity 0
radius_start 4
theta_start 0
phi_start 0
use_polar_step true
}
}
)";

constexpr std::string_view kGrow = R"(grow
{
quota 4
material white
particle_width 40
particle_height 40
emitter Point
{
emission_rate 100
time_to_live 2
velocity 0
}
affector ScaleInterpolator
{
width_range_start 10
width_range_end 10
height_range_start 10
height_range_end 10
use_interpolated_scale false
use_interpolated_increment true
increment_value0 2 4 0
increment_time0 1
}
}
)";

constexpr std::string_view kTurn = R"(turn
{
quota 2
material white
particle_width 1
particle_height 1
emitter Point
{
emission_rate 100
time_to_live 2
velocity 0
}
affector MeshRotator
{
yaw_rotation_range_start 90
yaw_rotation_range_end 90
yaw_rotation_speed_range_start 90
yaw_rotation_speed_range_end 90
}
}
)";

constexpr std::string_view kRibbon = R"(trail
{
quota 2
material white
particle_width 1
particle_height 1
renderer ribbon
element_count 8
emitter Point
{
emission_rate 1000
time_to_live 2
velocity 40
direction 1 0 0
}
}
)";

constexpr std::string_view kIce = R"(ice
{
quota 1
material white
particle_width 2
particle_height 4
renderer mesh
mesh_name ice.mesh
emitter Point
{
emission_rate 1000
position 3 0 0
velocity 0
time_to_live 2
}
affector MeshRotator
{
yaw_rotation_range_start 90
yaw_rotation_range_end 90
yaw_rotation_speed_range_start 0
yaw_rotation_speed_range_end 0
}
affector MeshAnimationAffector
{
animation_name run
animation_loop true
animation_speed 1
}
}
)";

constexpr std::string_view kRune = R"(effect rune
{
element Projector
{
StartTime 0
LifeTime 0
Position 0 0 0
Material rune
ProjectionSize 800
}
LifeTime 0
}
)";

constexpr std::string_view kSheet = R"(sheet
{
quota 1
material white
particle_width 1
particle_height 1
renderer texcoord_billboard
stacks 2
slices 2
emitter Point
{
emission_rate 1000
time_to_live 1
velocity 0
}
}
)";

// Sáu hệ, mỗi hệ một lý do của cửa xét: flame dựng được; fog trộn alpha; plane là hạt mesh; candle có
// affector bộ đọc không biết; scrolled dùng material hai ảnh; bare dùng material ngoài bảng.
constexpr std::string_view kGateParticles = R"(flame
{
quota 2
material fire
emitter Point
{
emission_rate 100
time_to_live 5
}
}
fog
{
quota 2
material mist
emitter Point
{
emission_rate 100
time_to_live 5
}
}
plane
{
quota 1
material fire
renderer mesh
mesh_name plane.mesh
emitter Point
{
emission_rate 100
}
}
candle
{
quota 1
material fire
emitter Point
{
emission_rate 100
}
affector SequenceFrame
{
stacks 7
slices 7
}
}
scrolled
{
quota 1
material flow
emitter Point
{
emission_rate 100
}
}
bare
{
quota 1
material nowhere
emitter Point
{
emission_rate 100
}
}
)";

// camp: một hệ dựng được, một hệ trộn alpha, một element bộ đọc không biết, một projector trộn alpha.
// late: hệ dựng được nhưng nửa giây sau mới tới StartTime.
constexpr std::string_view kGateEffects = R"(effect camp
{
element Particle
{
StartTime 0
ParticleSystem flame
}
element Particle
{
StartTime 0
ParticleSystem fog
}
element PointLight
{
StartTime 0
}
element Projector
{
StartTime 0
Material mist
}
LifeTime 0
}
effect late
{
element Particle
{
StartTime 0.5
ParticleSystem flame
}
LifeTime 0
}
)";

constexpr std::string_view kGateTable =
    "name\timage\tblend\tgain\tsecond\tscroll_u\tscroll_v\tshader\textra\n"
    "fire\tMaterial/fire.png\tone one\t4\t\t0\t0\tparticle\t\n"
    "rune\tMaterial/rune.png\tone one\t1\t\t0\t0\tfixed\t\n"
    "glow\tMaterial/glow.png\tsrc_alpha one\t1\t\t0\t0\tfixed\t\n"
    "mist\tMaterial/mist.png\tsrc_alpha one_minus_src_alpha\t1\t\t0\t0\tparticle\t\n"
    "flow\tMaterial/flow.png\tone one\t2\tMaterial/mask.png\t0\t0\tParticle_TwoTex_PS\t\n"
    "drift\tMaterial/drift.png\tone one\t1\t\t0\t0.5\tparticle\t\n"
    "sized\tMaterial/sized.png\tone one\t1\t\t0\t0\tparticle\tscale 2 1\n";

// Cột đổi chỗ, có cột lạ, xuống dòng CRLF, thiếu ba cột second, scroll, extra; dòng spark dài hơn tiêu
// đề một ô, dòng broken có hệ số không phải số, một dòng không tên, dòng short thiếu ô, dòng swirl dùng
// shader riêng.
constexpr std::string_view kOddTable = "gain\tnote\tname\tblend\timage\tshader\r\n"
                                       "2\tcột lạ\tspark\tone one\tMaterial/spark.png\tfixed\tô thừa\r\n"
                                       "x\t\tbroken\tone one\tMaterial/broken.png\tfixed\r\n"
                                       "1\t\t\tone one\tMaterial/noname.png\tfixed\r\n"
                                       "1\t\tshort\r\n"
                                       "1\t\tswirl\tone one\tMaterial/swirl.png\tModel_Flow_PS\r\n";

// Sáu hệ của kGateParticles và một tên thư viện không có.
constexpr std::array<std::string_view, 7> kGateNames{"flame", "fog", "plane", "candle", "scrolled", "bare", "ghost"};

[[nodiscard]] fx::Library particles_only(std::string_view script) {
    fx::LibraryText text;
    text.particles = std::string(script);
    return fx::Library(std::move(text));
}

[[nodiscard]] fx::Library gate_library() {
    fx::LibraryText text;
    text.particles = std::string(kGateParticles);
    text.effects = std::string(kGateEffects);
    text.materials = std::string(kGateTable);
    return fx::Library(std::move(text));
}

[[nodiscard]] fx::Spawn spawn_of(std::string_view name, bool is_effect) {
    fx::Spawn spawn;
    spawn.name = std::string(name);
    spawn.is_effect = is_effect;
    return spawn;
}

[[nodiscard]] bool is_tiny(float difference) {
    return std::fabs(difference) < 1.0e-4F;
}

[[nodiscard]] bool is_small(float difference) {
    return std::fabs(difference) < 1.0e-3F;
}

[[nodiscard]] bool dim_alpha(const fx::Field& field) {
    const auto is_dim = [&field](std::uint32_t index) { return field.grain(index).colour[3] < 0.99F; };
    return std::ranges::any_of(field.order(), is_dim);
}

void fade_out_dims(Context& context) {
    fx::Library library = particles_only(kFade);
    const fx::SystemDef* system = library.system("fade");
    context.expect(system != nullptr, "có hệ fade");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.5F, fx::Node{});
    context.expect(dim_alpha(field), "fade_out 0 làm alpha nhỏ hơn 1");
}

void torch_emits(Context& context) {
    fx::Library library = particles_only(kTorch);
    const fx::SystemDef* system = library.system("huoba03");
    context.expect(system != nullptr, "có hệ huoba03");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.2F, fx::Node{});
    context.expect(!field.order().empty(), "sau 0,2 s đã có hạt");
    if (field.order().empty()) return;
    const fx::Grain& grain = field.grain(field.order().front());
    context.expect(grain.width > 0.0F, "hạt có bề rộng");
}

[[nodiscard]] const fx::Grain* first_grain(const fx::Field& field) {
    if (field.order().empty()) return nullptr;
    return &field.grain(field.order().front());
}

void revolution_turns(Context& context) {
    fx::Library library = particles_only(kSpin);
    const fx::SystemDef* system = library.system("spin");
    context.expect(system != nullptr, "có hệ quay");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.033F, fx::Node{});
    field.update(0.033F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    context.expect(grain != nullptr, "có hạt để quay");
    if (grain == nullptr) return;
    const float angle = 90.0F * fx::kDegree * 0.033F;
    const ogre::Vec3 start{.x = 1.0F};
    const ogre::Quat turn = ogre::quat_from_angle_axis(angle, ogre::Vec3{.y = 1.0F});
    const ogre::Vec3 turned = ogre::quat_rotate(turn, start);
    const bool placed = is_tiny(grain->position.x - turned.x) && is_tiny(grain->position.z - turned.z);
    context.expect(placed, "quay 90 độ/giây quanh y đúng một bước");
}

void polar_places(Context& context) {
    fx::Library library = particles_only(kPole);
    const fx::SystemDef* system = library.system("pole");
    context.expect(system != nullptr, "có cực");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.033F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    context.expect(grain != nullptr && is_tiny(grain->position.z - 4.0F), "theta 0 nằm trên trục z");
}

void increment_grows(Context& context) {
    fx::Library library = particles_only(kGrow);
    const fx::SystemDef* system = library.system("grow");
    context.expect(system != nullptr, "có hệ phóng");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.066F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    context.expect(grain != nullptr, "có hạt phóng");
    if (grain == nullptr) return;
    const bool grown = is_small(grain->width - 10.066F) && is_small(grain->height - 10.132F);
    context.expect(grown, "increment cộng vào kích thước riêng");
}

void mesh_yaw(Context& context) {
    fx::Library library = particles_only(kTurn);
    const fx::SystemDef* system = library.system("turn");
    context.expect(system != nullptr, "có MeshRotator");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.033F, fx::Node{});
    const float yaw = 90.0F * fx::kDegree;
    const fx::Grain* born = first_grain(field);
    context.expect(born != nullptr && is_tiny(born->angles.x - yaw), "yaw khởi tạo 90 độ");
    field.update(0.033F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    const float turned = yaw + (0.033F * (90.0F * fx::kDegree));
    context.expect(grain != nullptr && is_tiny(grain->angles.x - turned), "yaw cộng tốc độ nhân dt");
}

void ribbon_grows(Context& context) {
    fx::Library library = particles_only(kRibbon);
    const fx::SystemDef* system = library.system("trail");
    context.expect(system != nullptr && system->renderer == fx::RendererKind::kRibbon, "renderer ribbon");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.2F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    context.expect(grain != nullptr, "có hạt ribbon");
    if (grain == nullptr) return;
    const auto points = field.chain(field.order().front());
    context.expect(points.size() > 2, "ribbon dài hơn hai mốc");
    if (points.size() < 2) return;
    const bool ends = is_tiny(points.front().texcoord) && is_tiny(points.back().texcoord - 1.0F);
    context.expect(ends, "đầu ribbon u = 0, đuôi u = 1");
}

void ribbon_faces(Context& context) {
    fx::Library library = particles_only(kRibbon);
    const fx::SystemDef* system = library.system("trail");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.2F, fx::Node{});
    fx::CameraAxes camera;
    camera.forward = {.x = 0.0F, .y = 0.0F, .z = -1.0F};
    camera.eye = {.x = 0.0F, .y = 5.0F, .z = 0.0F};
    const fx::Field* view = &field;
    const std::vector<fx::BillboardBatch> batches = fx::billboards_of(std::span{&view, 1}, camera);
    context.expect(!batches.empty() && batches.front().vertices.size() >= 4, "ribbon có quad");
    if (batches.empty()) return;
    const fx::BillboardVertex& corner = batches.front().vertices.front();
    const bool faces_eye = std::fabs(corner.z) > 0.2F && std::fabs(corner.y) < 0.2F;
    context.expect(faces_eye, "cạnh ribbon theo mắt, không theo forward");
}

[[nodiscard]] bool is_ice_pose(const fx::MeshPose& pose) {
    const ogre::Quat yaw = ogre::quat_from_angle_axis(90.0F * fx::kDegree, ogre::Vec3{.y = 1.0F});
    const bool sized = is_tiny(pose.scale.x - 2.0F) && is_tiny(pose.scale.y - 4.0F) && is_tiny(pose.scale.z - 2.0F);
    const bool turned = is_tiny(pose.orientation.w - yaw.w) && is_tiny(pose.orientation.y - yaw.y);
    return is_tiny(pose.position.x - 3.0F) && sized && turned;
}

void mesh_places(Context& context) {
    fx::Library library = particles_only(kIce);
    const fx::SystemDef* system = library.system("ice");
    context.expect(system != nullptr && system->mesh_name == "ice.mesh", "có tên mesh");
    if (system == nullptr) return;
    const bool clip = !system->affectors.empty() && std::holds_alternative<fx::MeshAnimation>(system->affectors.back());
    context.expect(clip, "giữ MeshAnimationAffector");
    fx::Field field(*system, 1);
    field.update(0.033F, fx::Node{});
    const std::vector<fx::MeshPose> poses = fx::mesh_poses(field);
    context.expect(poses.size() == 1, "một tư thế mesh");
    if (poses.size() != 1) return;
    context.expect(is_ice_pose(poses.front()), "vị trí, scale xz/y và yaw 90 độ");
}

void beam_line(Context& context) {
    fx::ElementDef element;
    element.kind = fx::ElementKind::kBeam;
    element.links = 4;
    element.width = 2.0F;
    element.extent_y = 0.0F;
    element.extent_z = 0.0F;
    element.sin_play = false;
    element.colour_a = fx::Colour{1.0F, 0.0F, 0.0F, 1.0F};
    element.colour_b = element.colour_a;
    const ogre::Vec3 dest{.z = 10.0F};
    float phase = 0.0F;
    const std::vector<fx::ChainSample> points = fx::beam_points(element, dest, 1, phase);
    context.expect(points.size() == 4, "beam bốn mốc");
    if (points.size() != 4) return;
    const bool reaches = is_tiny(points.back().position.z - 10.0F) && is_tiny(points.back().along - 1.0F);
    context.expect(is_tiny(points[1].position.z - 2.5F) && reaches, "mốc giữa nằm trên đoạn tới đích");
    const std::vector<fx::ChainSample> idle = fx::beam_points(element, ogre::Vec3{.y = 1.0F}, 1, phase);
    context.expect(idle.empty(), "chưa có đích thì beam không dựng");
}

// t của RVA 0x227C90 là chỉ số mốc. Tần số 90 độ và vận tốc 0: mốc 1 là sin 90, mốc 3 là sin 270.
void beam_sway(Context& context) {
    fx::ElementDef element;
    element.links = 4;
    element.wave_frequency = 90.0F;
    element.wave_velocity = 0.0F;
    float phase = 0.0F;
    const ogre::Vec3 dest{.z = 10.0F};
    const std::vector<fx::ChainSample> points = fx::beam_points(element, dest, 1, phase);
    context.expect(points.size() == 4, "bốn mốc sóng");
    if (points.size() != 4) return;
    const float rise = 10.0F * std::sin(90.0F * fx::kDegree);
    const float drop = 10.0F * std::sin(270.0F * fx::kDegree);
    const bool rose = is_tiny(points[1].position.y - rise) && is_tiny(points[1].position.z - 2.5F);
    const bool dropped = is_tiny(points[3].position.y - drop) && is_tiny(phase - 4.0F);
    context.expect(rose && dropped, "sin theo chỉ số mốc và pha tăng từng mốc");
    element.links = 2;
    element.sin_play = false;
    element.wave_frequency = 0.0F;
    element.wave_velocity = 5.0F;
    phase = 361.0F;
    const std::vector<fx::ChainSample> wrapped = fx::beam_points(element, dest, 1, phase);
    const bool reset = wrapped.size() == 2 && is_tiny(wrapped.front().position.y) && is_tiny(phase);
    context.expect(reset, "pha quá 360 về 0 trước khi dùng, tắt sin thì không tăng");
}

void trail_follows(Context& context) {
    fx::ElementDef element;
    element.trail_length = 10.0F;
    element.chain_count = 5;
    element.head_width = 4.0F;
    element.tail_width = 0.0F;
    element.high_cut = 10.0F;
    fx::TrailRun run;
    for (int step = 0; step < 7; ++step) {
        const ogre::Vec3 head{.x = static_cast<float>(step) * 2.0F};
        fx::trail_step(run, element, head, 0.033F);
    }
    const std::vector<fx::ChainSample> points = fx::trail_points(run, element);
    context.expect(points.size() == 5, "ribbon cắt còn năm mốc");
    if (points.size() != 5) return;
    const bool wide_head = is_small(points.front().position.x - 12.0F) && is_small(points.front().width - 4.0F);
    context.expect(wide_head && points.back().width < 1.0F, "đầu rộng, đuôi hẹp, không dài hơn TrailLength");
}

void projector_deck(Context& context) {
    fx::LibraryText text;
    text.effects = std::string(kRune);
    text.materials = std::string(kGateTable);
    fx::Library library(std::move(text));
    const fx::EffectDef* effect = library.effect("rune");
    context.expect(effect != nullptr && effect->elements.size() == 1, "có projector");
    if (effect == nullptr || effect->elements.empty()) return;
    context.expect(effect->elements.front().projection == 800.0F, "cạnh chiếu 800");
    fx::Cast cast(&library);
    cast.add(spawn_of("rune", true));
    cast.update(0.05F);
    context.expect(cast.tally().strips == 1 && cast.tally().total_skipped() == 0, "projector cộng sáng được nhận");
    const std::vector<fx::BillboardBatch> batches = cast.strips(fx::CameraAxes{});
    context.expect(batches.size() == 1 && batches.front().vertices.size() == 4, "một quad");
    if (batches.size() != 1) return;
    const float left = batches.front().vertices[0].x;
    const float right = batches.front().vertices[1].x;
    context.expect(is_small((right - left) - 800.0F), "quad rộng bằng ProjectionSize");
}

void texcoord_frame(Context& context) {
    fx::Library library = particles_only(kSheet);
    const fx::SystemDef* system = library.system("sheet");
    context.expect(system != nullptr && system->stacks == 2 && system->slices == 2, "lưới 2x2");
    if (system == nullptr) return;
    fx::Field field(*system, 1);
    field.update(0.033F * 16.0F, fx::Node{});
    const fx::Grain* grain = first_grain(field);
    const bool aged = grain != nullptr && grain->life() > 0.49F && grain->life() < 0.5F;
    context.expect(aged, "life nằm trong khung thứ hai");
    const fx::Field* view = &field;
    const std::vector<fx::BillboardBatch> batches = fx::billboards_of(std::span{&view, 1}, fx::CameraAxes{});
    context.expect(!batches.empty() && batches.front().vertices.size() == 4, "một quad");
    if (batches.empty()) return;
    const fx::BillboardVertex& corner = batches.front().vertices.front();
    context.expect(is_tiny(corner.u - 0.5F) && is_tiny(corner.v), "khung thứ hai của lưới");
}

// Bảng material quyết định hệ nào được vẽ, nên đọc sai một ô là vẽ sai cả loạt: chế độ trộn và hệ
// số màu phải đúng từng dòng, material hai ảnh hay có cuộn, có thiết lập riêng không được coi là thường.
void palette_reads_columns(Context& context) {
    const fx::Palette palette(kGateTable);
    const fx::Paint* fire = palette.find("fire");
    context.expect(fire != nullptr, "có dòng fire");
    if (fire == nullptr) return;
    const bool additive = fire->blend == fx::Blend::kAdd && fire->is_plain && fire->image == "Material/fire.png";
    context.expect(additive && fire->gain == 4.0F, "fire: cộng thẳng, một ảnh, hệ số màu 4");
    const fx::Paint* glow = palette.find("glow");
    context.expect(glow != nullptr && glow->blend == fx::Blend::kAlphaAdd && glow->is_plain, "glow: cộng theo alpha");
    const fx::Paint* mist = palette.find("mist");
    context.expect(mist != nullptr && mist->blend == fx::Blend::kOther, "mist: trộn alpha không phải cộng sáng");
    const fx::Paint* flow = palette.find("flow");
    context.expect(flow != nullptr && !flow->is_plain, "flow: hai ảnh, shader riêng");
    const fx::Paint* drift = palette.find("drift");
    context.expect(drift != nullptr && !drift->is_plain, "drift: cuộn UV");
    const fx::Paint* sized = palette.find("sized");
    context.expect(sized != nullptr && !sized->is_plain, "sized: có thiết lập riêng");
    context.expect(palette.find("ghost") == nullptr, "tên lạ không có trong bảng");
}

// Bảng là tệp ngoài: bộ gom thêm cột, đổi thứ tự cột hay ghi hỏng một dòng thì client vẫn phải đọc
// được phần còn lại, và không được coi một dòng hỏng là material vẽ được.
void palette_survives_odd_table(Context& context) {
    const fx::Palette palette(kOddTable);
    context.expect(palette.size() == 3, "ba dòng dùng được: spark, short, swirl");
    const fx::Paint* spark = palette.find("spark");
    context.expect(spark != nullptr, "tra cột theo tên ở dòng tiêu đề");
    if (spark == nullptr) return;
    const bool read = spark->gain == 2.0F && spark->blend == fx::Blend::kAdd && spark->image == "Material/spark.png";
    context.expect(read && spark->is_plain, "spark: cột thiếu thì ô rỗng, vẫn là material thường");
    context.expect(palette.find("broken") == nullptr, "hệ số màu không phải số thì bỏ dòng");
    const fx::Paint* cut = palette.find("short");
    context.expect(cut != nullptr && cut->image.empty() && !cut->is_plain, "dòng thiếu ô: không ảnh, không thường");
    const fx::Paint* swirl = palette.find("swirl");
    context.expect(swirl != nullptr && !swirl->is_plain, "shader riêng thì không thường");
    context.expect(fx::Palette("").size() == 0, "bảng rỗng không làm hỏng gì");
}

// Mỗi lý do bỏ phải đếm đúng một lần cho mỗi hệ, và chỉ hệ qua cửa mới thành Field: vẽ một hệ trộn
// alpha bằng pipeline cộng sáng ra quầng sáng thay cho sương.
void cast_skips_by_reason(Context& context) {
    fx::Library library = gate_library();
    fx::Cast cast(&library);
    for (const std::string_view name : kGateNames) {
        cast.add(spawn_of(name, false));
    }
    cast.add(spawn_of("camp", true));
    cast.add(spawn_of("nope", true));
    cast.update(0.1F);
    const fx::Tally& tally = cast.tally();
    context.expect(tally.systems == 2 && tally.strips == 0, "nhận hai hệ flame, không dải nào");
    context.expect(cast.live().size() == 2, "hai Field có hạt");
    context.expect(cast.strips(fx::CameraAxes{}).empty(), "projector trộn alpha không thành dải");
    context.expect(tally.count(fx::Skip::kBlend) == 3, "fog hai lần và projector: không cộng sáng");
    context.expect(tally.count(fx::Skip::kMeshRenderer) == 1, "plane: hạt mesh");
    context.expect(tally.count(fx::Skip::kUnknownAffector) == 1, "candle: affector lạ");
    context.expect(tally.count(fx::Skip::kShading) == 1, "scrolled: material hai ảnh");
    context.expect(tally.count(fx::Skip::kNoMaterial) == 1, "bare: material ngoài bảng");
    context.expect(tally.count(fx::Skip::kUnknownName) == 2, "ghost và nope: tên lạ");
    context.expect(tally.count(fx::Skip::kUnknownElement) == 1, "PointLight: element lạ");
    context.expect(tally.total_skipped() == 10, "tổng mười thứ bị bỏ");
    const auto kind = tally.affectors.find("SequenceFrame");
    const bool named = tally.affectors.size() == 1 && kind != tally.affectors.end() && kind->second == 1;
    context.expect(named, "nêu tên loại affector làm hệ bị bỏ");
}

// Đổi cảnh: hệ của cảnh cũ, kể cả hệ còn chờ StartTime, không được sống sang cảnh mới.
void cast_clear_resets(Context& context) {
    fx::Library library = gate_library();
    fx::Cast cast(&library);
    cast.add(spawn_of("flame", false));
    cast.add(spawn_of("fog", false));
    cast.add(spawn_of("late", true));
    cast.update(0.1F);
    context.expect(cast.live().size() == 1 && cast.tally().systems == 2, "một Field đang chạy, một hệ còn chờ");
    cast.clear();
    const bool reset = cast.tally().systems == 0 && cast.tally().total_skipped() == 0;
    context.expect(cast.live().empty() && reset, "clear bỏ Field và đặt lại số đếm");
    cast.update(1.0F);
    context.expect(cast.live().empty(), "hệ chờ StartTime của cảnh cũ không được dựng sau clear");
    cast.add(spawn_of("flame", false));
    cast.update(0.1F);
    context.expect(cast.live().size() == 1 && cast.tally().systems == 1, "cảnh mới dựng lại từ đầu");
}

constexpr std::array kCases{
    Case{.name = "mesh_yaw", .body = &mesh_yaw},
    Case{.name = "ribbon_grows", .body = &ribbon_grows},
    Case{.name = "ribbon_faces", .body = &ribbon_faces},
    Case{.name = "beam_line", .body = &beam_line},
    Case{.name = "beam_sway", .body = &beam_sway},
    Case{.name = "trail_follows", .body = &trail_follows},
    Case{.name = "projector_deck", .body = &projector_deck},
    Case{.name = "mesh_places", .body = &mesh_places},
    Case{.name = "texcoord_frame", .body = &texcoord_frame},
    Case{.name = "revolution_turns", .body = &revolution_turns},
    Case{.name = "polar_places", .body = &polar_places},
    Case{.name = "increment_grows", .body = &increment_grows},
    Case{.name = "fade_out_dims", .body = &fade_out_dims},
    Case{.name = "torch_emits", .body = &torch_emits},
    Case{.name = "palette_reads_columns", .body = &palette_reads_columns},
    Case{.name = "palette_survives_odd_table", .body = &palette_survives_odd_table},
    Case{.name = "cast_skips_by_reason", .body = &cast_skips_by_reason},
    Case{.name = "cast_clear_resets", .body = &cast_clear_resets},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "fx_tests: mọi ca phải qua");
    return 0;
}
