// Kiểm đánh giá tư thế: bất biến tự suy (bind pose ra ma trận đơn vị, lặp thời gian, lấy mẫu khoá ở
// mọi biên, cộng dồn, rig và animation hỏng, ba chỗ lệch có chủ đích so với OGRE) và khung tham
// chiếu vàng lấy từ chính mã OGRE 1.2.5 của _ref.
// Nguồn: TLBB Dev tests/anim/anim_test.cpp@e0d89a6. Khác gốc: khung test của dự án
// (Context::expect, mỗi ca nhận Context); apply nhận Blend; vòng và hàm phụ viết lại cho cổng
// (không `if` trong vòng lặp, tên dài hơn ba ký tự, hậu tố F); khung vàng giữ nguyên từng số.
#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "core/check.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using anim::Affine;
using anim::BoneKey;
using anim::BoneTrack;
using anim::Pose;
using anim::Rig;
using anim::RigError;
using anim::RigResult;
using ogre::Quat;
using ogre::Vec3;

[[nodiscard]] bool near_value(float left, float right, float tolerance) {
    return std::abs(left - right) <= tolerance;
}

[[nodiscard]] bool near_affine(const Affine& left, const Affine& right, float tolerance) {
    const auto close = [tolerance](float one, float two) { return near_value(one, two, tolerance); };
    return std::ranges::equal(left, right, close);
}

[[nodiscard]] bool near_vec3(Vec3 left, Vec3 right) {
    const bool is_xy = near_value(left.x, right.x, 1e-6F) && near_value(left.y, right.y, 1e-6F);
    return is_xy && near_value(left.z, right.z, 1e-6F);
}

[[nodiscard]] bool near_quat(Quat left, Quat right) {
    const bool is_xyz =
        near_vec3(Vec3{.x = left.x, .y = left.y, .z = left.z}, Vec3{.x = right.x, .y = right.y, .z = right.z});
    return is_xyz && near_value(left.w, right.w, 1e-6F);
}

// Dữ liệu tổng hợp

// Bốn xương, handle con có thể nhỏ hơn handle cha (tay 1 là con của thân 2) để thứ tự cập nhật
// không trùng thứ tự handle; thân có scale không đều. Cùng số liệu với công cụ nháp sinh khung
// vàng.
[[nodiscard]] anim::Bone bone_of(std::string name, std::uint16_t handle, Vec3 position) {
    anim::Bone bone;
    bone.name = std::move(name);
    bone.handle = handle;
    bone.position = position;
    return bone;
}

[[nodiscard]] anim::SourceSkeleton make_skeleton() {
    anim::Bone root = bone_of("goc", 0, Vec3{.x = 0.0F, .y = 1.0F, .z = 0.0F});
    root.orientation = Quat{.x = 0.0F, .y = 0.258819045F, .z = 0.0F, .w = 0.965925826F};
    anim::Bone arm = bone_of("tay", 1, Vec3{.x = 0.5F, .y = 1.5F, .z = 0.0F});
    arm.orientation = Quat{.x = -0.130526192F, .y = 0.0F, .z = 0.0F, .w = 0.991444861F};
    anim::Bone body = bone_of("than", 2, Vec3{.x = 0.0F, .y = 2.0F, .z = 0.0F});
    body.orientation = Quat{.x = 0.0F, .y = 0.0F, .z = 0.173648178F, .w = 0.984807753F};
    body.scale = Vec3{.x = 1.2F, .y = 1.0F, .z = 0.8F};
    const anim::Bone leg = bone_of("chan", 3, Vec3{.x = -1.0F, .y = 0.0F, .z = 0.5F});
    anim::SourceSkeleton skeleton;
    skeleton.bones = {root, arm, body, leg};
    skeleton.parents = {anim::BoneParent{.child = 1, .parent = 2}, anim::BoneParent{.child = 2, .parent = 0},
        anim::BoneParent{.child = 3, .parent = 0}};
    return skeleton;
}

// Một khoá mô tả bằng thời điểm, hướng, dịch và scale.
struct KeySpec {
    float time = 0.0F;
    Quat rotation;
    Vec3 translate;
    Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

[[nodiscard]] BoneKey key_of(const KeySpec& spec) {
    return BoneKey{.time = spec.time, .rotation = spec.rotation, .translate = spec.translate, .scale = spec.scale};
}

constexpr Vec3 kZero{};
constexpr Vec3 kUnit{.x = 1.0F, .y = 1.0F, .z = 1.0F};

[[nodiscard]] BoneKey key(float time, Quat rotation, Vec3 translate, Vec3 scale) {
    return key_of(KeySpec{.time = time, .rotation = rotation, .translate = translate, .scale = scale});
}

[[nodiscard]] BoneTrack track_of(std::uint16_t bone) {
    BoneTrack track;
    track.bone = bone;
    return track;
}

[[nodiscard]] anim::Blend blend_at(float time) {
    anim::Blend blend;
    blend.time = time;
    return blend;
}

// Animation "di" dài 2 giây: gốc quay và dịch qua ba khoá, thân quay và giãn qua hai khoá bắt đầu
// sau 0, tay dịch với khoá cuối đúng bằng độ dài, chân chỉ có một khoá.
[[nodiscard]] anim::Animation make_walk() {
    const std::uint8_t moves = anim::kKeyRotation | anim::kKeyTranslate;
    BoneTrack root = track_of(0);
    root.flags = moves;
    root.keys = {key(0.0F, Quat{}, kZero, kUnit),
        key(0.5F, Quat{.x = 0.0F, .y = 0.342020143F, .z = 0.0F, .w = 0.939692621F},
            Vec3{.x = 0.2F, .y = 0.0F, .z = 0.0F}, kUnit),
        key(1.5F, Quat{.x = 0.0F, .y = -0.173648178F, .z = 0.0F, .w = 0.984807753F},
            Vec3{.x = 0.0F, .y = 0.1F, .z = 0.0F}, kUnit)};
    const std::uint8_t grows = anim::kKeyRotation | anim::kKeyScale;
    BoneTrack body = track_of(2);
    body.flags = grows;
    body.keys = {key(0.25F, Quat{.x = 0.0F, .y = 0.0F, .z = 0.258819045F, .w = 0.965925826F}, kZero, kUnit),
        key(1.0F, Quat{.x = 0.298836239F, .y = 0.298836239F, .z = 0.0F, .w = 0.906307787F}, kZero,
            Vec3{.x = 1.5F, .y = 1.0F, .z = 1.0F})};
    BoneTrack arm = track_of(1);
    arm.flags = anim::kKeyTranslate;
    arm.keys = {key(0.0F, Quat{}, kZero, kUnit), key(2.0F, Quat{}, Vec3{.x = 0.0F, .y = 0.0F, .z = 0.4F}, kUnit)};
    BoneTrack leg = track_of(3);
    leg.flags = anim::kKeyRotation;
    leg.keys = {key(0.7F, Quat{.x = 0.5F, .y = 0.0F, .z = 0.0F, .w = 0.866025404F}, kZero, kUnit)};
    return anim::Animation{.name = "di", .length = 2.0F, .tracks = {root, body, arm, leg}};
}

// Animation "xoay" dài 1 giây: hai khoá của chân có tích vô hướng âm, nlerp phải đi đường ngắn
// nhất.
[[nodiscard]] anim::Animation make_turn() {
    BoneTrack leg = track_of(3);
    leg.flags = anim::kKeyRotation;
    leg.keys = {key(0.0F, Quat{.x = 0.0F, .y = 0.996194698F, .z = 0.0F, .w = 0.087155743F}, kZero, kUnit),
        key(1.0F, Quat{.x = 0.0F, .y = -0.996194698F, .z = 0.0F, .w = 0.087155743F}, kZero, kUnit)};
    return anim::Animation{.name = "xoay", .length = 1.0F, .tracks = {leg}};
}

// Khung tham chiếu vàng

// Sinh bởi công cụ nháp scratchpad/c3c/oracle/ogre_pose.cpp của TLBB ngày 2026-09-24: biên dịch
// Bone, Node, Animation, NodeAnimationTrack, TransformKeyFrame, AnimationState cùng phần toán
// (Quaternion, Vector3, Matrix3, Matrix4, Math) từ OgreMain/src của _ref, dựng đúng skeleton và
// animation ở trên, đặt thời gian qua AnimationState lặp, cộng dồn bằng Animation::apply, rồi in
// Bone::_getOffsetTransform của từng xương theo handle. Không skeleton thật nào trong đó.
struct Golden {
    bool with_walk = true;
    float walk_time = 0.0F;
    float walk_weight = 1.0F;
    float walk_scale = 1.0F;
    bool with_turn = false;
};

constexpr std::array<Golden, 8> kGolden = {
    // di tại -0.3, weight 1, scale 1
    Golden{.walk_time = -0.3F},
    // di tại 0.5, weight 1, scale 1
    Golden{.walk_time = 0.5F},
    // di tại 0.9, weight 1, scale 1
    Golden{.walk_time = 0.9F},
    // di tại 1.75, weight 1, scale 1
    Golden{.walk_time = 1.75F},
    // di tại 2, weight 1, scale 1
    Golden{.walk_time = 2.0F},
    // di tại 0.9, weight 0.6, scale 0.5
    Golden{.walk_time = 0.9F, .walk_weight = 0.6F, .walk_scale = 0.5F},
    // di tại 0.9 rồi xoay tại 0.5
    Golden{.walk_time = 0.9F, .with_turn = true},
    // bind pose
    Golden{.with_walk = false},
};

// Ma trận skin của từng ca theo đúng thứ tự kGolden: bốn xương mỗi ca theo handle, mười hai số
// mỗi ma trận theo hàng.
// NOLINTBEGIN(modernize-use-std-numbers): số của khung vàng sinh từ OGRE, không phải hằng toán
// (HP-07)
constexpr std::array<float, 384> kGoldenSkin = {// di tại -0.3, weight 1, scale 1
    0.978129864F, -0.0F, -0.207995161F, 0.0F, 0.0F, 1.0F, -0.0F, 0.0599999428F, 0.207995161F, 0.0F, 0.978129864F, 0.0F,
    1.18127048F, -0.184483305F, 0.168668643F, 0.800716758F, 0.272203654F, 0.942077935F, -0.250414848F, 0.284994125F,
    -0.137496039F, 0.280098259F, 0.953332722F, -0.68855232F, 1.18127048F, -0.18448326F, 0.168668702F, 0.55344975F,
    0.272203654F, 0.942077935F, -0.250414878F, 0.233766079F, -0.137496114F, 0.280098289F, 0.953332722F, -0.840294898F,
    0.900895894F, 0.267546415F, -0.341768324F, -0.190312445F, -0.433012784F, 0.499999881F, -0.750000179F, 0.993012846F,
    -0.0297756344F, 0.823662102F, 0.566298842F, -0.585891426F,
    // di tại 0.5, weight 1, scale 1
    0.766044378F, 0.0F, 0.642787755F, 0.200000003F, 0.0F, 1.0F, 0.0F, 0.0F, -0.642787755F, 0.0F, 0.766044378F, 0.0F,
    0.670188725F, 0.0431854725F, 0.817401528F, 0.155661941F, 0.323097557F, 0.92946136F, -0.243732363F, 0.269556046F,
    -0.898646891F, 0.366383225F, 0.521966934F, -1.16282892F, 0.670188904F, 0.0431854352F, 0.817401528F, 0.0704436749F,
    0.323097497F, 0.92946136F, -0.243732378F, 0.211616039F, -0.898646891F, 0.366383225F, 0.521967053F, -1.0991497F,
    0.531121135F, 0.813797891F, 0.235888839F, -0.378874719F, -0.433012784F, 0.499999881F, -0.750000119F, 0.933012903F,
    -0.728292823F, 0.29619813F, 0.617945313F, -0.21069324F,
    // di tại 0.9, weight 1, scale 1
    0.960609198F, 0.0F, 0.277902812F, 0.120000005F, 0.0F, 1.0F, 0.0F, 0.0399999619F, -0.277902812F, 0.0F, 0.960609198F,
    0.0F, 0.803195059F, 0.255423903F, 0.78787446F, -0.473317385F, 0.0200438313F, 0.948205888F, -0.31734854F,
    0.282592773F, -1.18698001F, 0.188849926F, 0.527772903F, -0.76747489F, 0.803195059F, 0.255423903F, 0.787874401F,
    -0.646271646F, 0.0200438313F, 0.948205888F, -0.31734854F, 0.195382357F, -1.18697989F, 0.188849926F, 0.527773023F,
    -0.566549778F, 0.780365288F, 0.624383271F, -0.0342888385F, -0.324139267F, -0.433012903F, 0.499999821F,
    -0.750000179F, 0.973012924F, -0.451143026F, 0.600121677F, 0.660548389F, -0.426881433F,
    // di tại 1.75, weight 1, scale 1
    0.98480773F, -0.0F, -0.173648238F, 0.0F, 0.0F, 1.0F, -0.0F, 0.0499999523F, 0.173648238F, 0.0F, 0.98480773F, 0.0F,
    1.15611029F, -0.20427826F, 0.173442647F, 0.857218325F, 0.292071939F, 0.937844455F, -0.247401565F, 0.284618378F,
    -0.134548172F, 0.280567676F, 0.953262866F, -0.678440809F, 1.15611029F, -0.204278275F, 0.173442677F, 0.612834811F,
    0.292071968F, 0.937844455F, -0.247401595F, 0.236466646F, -0.134548217F, 0.280567706F, 0.953262866F, -0.841703117F,
    0.899302661F, 0.296198189F, -0.321747363F, -0.210693061F, -0.433012843F, 0.499999821F, -0.750000238F, 0.983012974F,
    -0.0612749904F, 0.813797951F, 0.577908754F, -0.578874648F,
    // di tại 2, weight 1, scale 1
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.899518967F, -0.433012933F, 0.0580127463F,
    1.29903877F, 0.433012933F, 0.866025329F, -0.250000089F, 0.401924133F, 0.058012709F, 0.250000089F, 0.966506362F,
    -0.750000358F, 0.899519026F, -0.433012873F, 0.0580127537F, 1.29903865F, 0.433012873F, 0.866025329F, -0.250000089F,
    0.401923895F, 0.0580127016F, 0.250000089F, 0.966506362F, -0.750000298F, 0.875F, 0.433012784F, -0.216506362F,
    -0.308012784F, -0.433012784F, 0.49999994F, -0.75000006F, 0.933012843F, -0.216506422F, 0.75000006F, 0.625F,
    -0.533493638F,
    // di tại 0.9, weight 0.6, scale 0.5
    0.985751629F, 0.0F, 0.168207437F, 0.0360000022F, 0.0F, 1.0F, 0.0F, 0.0119999647F, -0.168207437F, 0.0F, 0.985751629F,
    0.0F, 1.01264834F, 0.123213753F, 0.540437222F, -0.242853701F, -0.0228209682F, 0.980683863F, -0.194698095F,
    0.115949631F, -0.674018145F, 0.151912957F, 0.818547726F, -0.533652902F, 1.01264834F, 0.123213746F, 0.540437222F,
    -0.333641231F, -0.0228209365F, 0.980683863F, -0.194698095F, 0.0699484348F, -0.674018145F, 0.151912957F,
    0.818547726F, -0.455738872F, 0.924332619F, 0.376545876F, 0.0618265048F, -0.279126734F, -0.294845551F, 0.807628989F,
    -0.510687411F, 0.499216557F, -0.242230058F, 0.453815788F, 0.857540607F, -0.379793048F,
    // di tại 0.9 rồi xoay tại 0.5
    0.960609198F, 0.0F, 0.277902812F, 0.120000005F, 0.0F, 1.0F, 0.0F, 0.0399999619F, -0.277902812F, 0.0F, 0.960609198F,
    0.0F, 0.803195059F, 0.255423903F, 0.78787446F, -0.473317385F, 0.0200438313F, 0.948205888F, -0.31734854F,
    0.282592773F, -1.18698001F, 0.188849926F, 0.527772903F, -0.76747489F, 0.803195059F, 0.255423903F, 0.787874401F,
    -0.646271646F, 0.0200438313F, 0.948205888F, -0.31734854F, 0.195382357F, -1.18697989F, 0.188849926F, 0.527773023F,
    -0.566549778F, -0.780365944F, 0.624383271F, 0.0342888385F, -1.34957325F, 0.433012903F, 0.499999821F, 0.750000179F,
    0.106987298F, 0.451143026F, 0.600121677F, -0.660549045F, 1.36155033F,
    // bind pose
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 1.0F, -2.98023259e-08F, 1.11022302e-16F, 8.94069814e-08F, 2.98023259e-08F, 1.0F,
    -7.45058149e-09F, 0.0F, 1.11022302e-16F, 7.45058149e-09F, 1.0F, -2.23517453e-08F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F,
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F};
// NOLINTEND(modernize-use-std-numbers)

// Tư thế

// Tư thế trong tệp chính là bind pose: mọi ma trận skin là ma trận đơn vị.
void bind_is_identity(Context& context) {
    const RigResult rig = Rig::create(make_skeleton());
    context.expect(rig.has_value(), "dựng rig bốn xương");
    if (!rig) return;
    context.expect(rig->size() == 4, "bốn xương");
    const std::vector<Affine> skin = rig->skin(anim::bind_pose(*rig));
    context.expect(skin.size() == 4, "một ma trận mỗi xương");
    const auto is_identity = [](const Affine& matrix) { return near_affine(matrix, anim::kIdentityAffine, 1e-6F); };
    context.expect(std::ranges::all_of(skin, is_identity), "bind pose ra ma trận đơn vị");
}

// Ma trận thứ index của khung vàng.
[[nodiscard]] Affine golden_matrix(std::size_t index) {
    Affine matrix{};
    std::copy_n(kGoldenSkin.begin() + static_cast<std::ptrdiff_t>(index * 12), 12, matrix.begin());
    return matrix;
}

// Chênh lệch lớn nhất giữa hai thành phần cùng chỗ của hai ma trận.
[[nodiscard]] float matrix_gap(const Affine& ours, const Affine& theirs) {
    const auto difference = [](float left, float right) { return std::abs(left - right); };
    std::array<float, 12> gaps{};
    std::ranges::transform(ours, theirs, gaps.begin(), difference);
    return *std::ranges::max_element(gaps);
}

// Sai lệch lớn nhất giữa bốn ma trận skin của một ca và bốn ma trận khung vàng bắt đầu từ first.
[[nodiscard]] float golden_error(const std::vector<Affine>& skin, std::size_t first) {
    if (skin.size() != 4) return std::numeric_limits<float>::infinity();
    float worst = 0.0F;
    for (std::size_t matrix = 0; matrix < skin.size(); ++matrix) {
        worst = std::max(worst, matrix_gap(skin.at(matrix), golden_matrix(first + matrix)));
    }
    return worst;
}

// Cộng dồn "di" (và "xoay" nếu ca có) vào bind pose rồi so ma trận skin với khung vàng.
struct GoldenRun {
    const Rig* rig = nullptr;
    const anim::Animation* walk = nullptr;
    const anim::Animation* turn = nullptr;
};

[[nodiscard]] float run_golden(Context& context, const GoldenRun& run, std::size_t index) {
    const Golden& golden = kGolden.at(index);
    Pose pose = anim::bind_pose(*run.rig);
    const float walk_time = anim::loop_time(golden.walk_time, run.walk->length);
    const float weight = golden.with_walk ? golden.walk_weight : 0.0F;
    const anim::Blend walking{.time = walk_time, .weight = weight, .scale = golden.walk_scale};
    context.expect(anim::apply(*run.walk, walking, pose).has_value(), "cộng dồn di");
    const anim::Blend turning = blend_at(anim::loop_time(0.5F, run.turn->length));
    const bool turned = !golden.with_turn || anim::apply(*run.turn, turning, pose).has_value();
    context.expect(turned, "xoay");
    return golden_error(run.rig->skin(pose), index * 4);
}

// Mỗi ca của khung vàng: sai lệch tối đa 1e-5 vì thứ tự phép float có thể khác khi trình biên dịch
// gộp nhân cộng.
void matches_ogre(Context& context) {
    const RigResult rig = Rig::create(make_skeleton());
    context.expect(rig.has_value(), "dựng rig bốn xương");
    if (!rig) return;
    const anim::Animation walk = make_walk();
    const anim::Animation turn = make_turn();
    const GoldenRun run{.rig = &*rig, .walk = &walk, .turn = &turn};
    std::vector<float> errors;
    errors.reserve(kGolden.size());
    for (std::size_t index = 0; index < kGolden.size(); ++index) {
        errors.push_back(run_golden(context, run, index));
    }
    const auto is_close = [](float error) { return error <= 1e-5F; };
    context.expect(std::ranges::all_of(errors, is_close), "mọi ca khớp OGRE trong 1e-5");
}

// Như AnimationState::setTimePosition khi lặp: fmod theo độ dài, âm thì cộng một độ dài.
void loops_time(Context& context) {
    context.expect(near_value(anim::loop_time(2.6F, 2.0F), 0.6F, 1e-6F), "quá độ dài thì quấn lại");
    context.expect(near_value(anim::loop_time(-0.3F, 2.0F), 1.7F, 1e-6F), "âm thì cộng một độ dài");
    context.expect(anim::loop_time(2.0F, 2.0F) == 0.0F, "đúng bằng độ dài là 0");
    context.expect(anim::loop_time(0.75F, 2.0F) == 0.75F, "trong khoảng giữ nguyên");
    context.expect(anim::loop_time(5.0F, 0.0F) == 0.0F, "độ dài 0 đứng ở 0, không NaN");
}

// Lấy mẫu ở mọi biên của getKeyFramesAtTime.
void samples_keys(Context& context) {
    const anim::Animation walk = make_walk();
    const BoneTrack& root = walk.tracks[0];
    const BoneKey on_key = anim::sample(root, 0.5F, walk.length);
    context.expect(on_key.rotation == root.keys[1].rotation, "đúng thời điểm khoá thì lấy nguyên");
    context.expect(on_key.translate == root.keys[1].translate, "dịch của khoá giữ nguyên");
    const BoneKey middle = anim::sample(root, 1.0F, walk.length);
    const Quat half = ogre::quat_nlerp(0.5F, root.keys[1].rotation, root.keys[2].rotation, ogre::Arc::kShortest);
    context.expect(near_quat(middle.rotation, half), "giữa hai khoá là nlerp đường ngắn nhất");
    const Vec3 shifted{.x = 0.1F, .y = 0.05F, .z = 0.0F};
    context.expect(near_vec3(middle.translate, shifted), "dịch nội suy tuyến tính");
    const BoneKey after = anim::sample(root, 1.75F, walk.length);
    const Quat wrap =
        ogre::quat_nlerp(0.25F / 0.5F, root.keys[2].rotation, root.keys[0].rotation, ogre::Arc::kShortest);
    context.expect(near_quat(after.rotation, wrap), "qua khoá cuối thì nội suy về khoá đầu");
    const BoneTrack& body = walk.tracks[1];
    const BoneKey before = anim::sample(body, 0.1F, walk.length);
    context.expect(before.rotation == body.keys[0].rotation, "trước khoá đầu thì giữ khoá đầu");
    const BoneTrack& leg = walk.tracks[3];
    const BoneKey lone = anim::sample(leg, 1.3F, walk.length);
    context.expect(near_quat(lone.rotation, leg.keys[0].rotation), "một khoá thì giữ khoá đó");
    const BoneKey empty = anim::sample(BoneTrack{}, 0.3F, 2.0F);
    context.expect(empty == BoneKey{}, "track rỗng cho khoá mặc định");
}

// Hai khoá cùng thời điểm: lower_bound lấy khoá đầu, thời gian khoá bằng nhau thì không chia.
void samples_equal_times(Context& context) {
    BoneTrack twin = track_of(0);
    twin.flags = anim::kKeyTranslate;
    twin.keys = {key(0.5F, Quat{}, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F}, kUnit),
        key(0.5F, Quat{}, Vec3{.x = 2.0F, .y = 0.0F, .z = 0.0F}, kUnit),
        key(1.0F, Quat{}, Vec3{.x = 3.0F, .y = 0.0F, .z = 0.0F}, kUnit)};
    const BoneKey exact = anim::sample(twin, 0.5F, 2.0F);
    const Vec3 first{.x = 1.0F, .y = 0.0F, .z = 0.0F};
    context.expect(exact.translate == first, "đúng thời điểm trùng lấy khoá đầu");
    const BoneKey later = anim::sample(twin, 0.75F, 2.0F);
    const Vec3 mixed{.x = 2.5F, .y = 0.0F, .z = 0.0F};
    context.expect(near_vec3(later.translate, mixed), "sau thời điểm trùng nội suy từ khoá sau");
}

// Lệch có chủ đích: animation dài 0 đứng ở khoá đầu, không chia cho độ dài, không NaN.
void zero_length_stands(Context& context) {
    BoneTrack fall = track_of(0);
    fall.flags = anim::kKeyRotation;
    fall.keys = {key(0.0F, Quat{.x = 0.5F, .y = 0.0F, .z = 0.0F, .w = 0.866025404F}, kZero, kUnit),
        key(0.4F, Quat{}, kZero, kUnit)};
    const BoneKey still = anim::sample(fall, 0.3F, 0.0F);
    context.expect(still.rotation == fall.keys[0].rotation, "độ dài 0 lấy khoá đầu");
    const anim::Animation death{.name = "chet", .length = 0.0F, .tracks = {fall}};
    const RigResult rig = Rig::create(make_skeleton());
    if (!rig) return;
    Pose pose = anim::bind_pose(*rig);
    const anim::Blend blend = blend_at(anim::loop_time(1.5F, death.length));
    context.expect(anim::apply(death, blend, pose).has_value(), "cộng dồn animation dài 0");
    const bool is_finite = std::isfinite(pose[0].orientation.w) && std::isfinite(pose[0].position.x);
    context.expect(is_finite, "tư thế hữu hạn");
}

// Cộng dồn như applyToNode: dịch cộng translate * weight * scale, quay nhân phải
// nlerp(weight, đơn vị, khoá) không đi đường ngắn nhất, scale nhân; weight 0 và track rỗng bỏ qua.
void accumulates(Context& context) {
    const RigResult rig = Rig::create(make_skeleton());
    if (!rig) return;
    BoneTrack push = track_of(3);
    push.flags = anim::kKeyTranslate | anim::kKeyScale;
    push.keys = {key(0.0F, Quat{}, Vec3{.x = 1.0F, .y = 2.0F, .z = 3.0F}, Vec3{.x = 2.0F, .y = 1.0F, .z = 1.0F})};
    const anim::Animation shove{.name = "day", .length = 1.0F, .tracks = {push, BoneTrack{}}};
    Pose pose = anim::bind_pose(*rig);
    const anim::Blend half{.time = 0.0F, .weight = 0.5F, .scale = 0.5F};
    context.expect(anim::apply(shove, half, pose).has_value(), "cộng dồn nửa weight, nửa scale");
    const Vec3 start{.x = -1.0F, .y = 0.0F, .z = 0.5F};
    const Vec3 moved{.x = -0.75F, .y = 0.5F, .z = 1.25F};
    context.expect(near_vec3(pose[3].position, moved), "dịch nhân weight rồi scale");
    const Vec3 grown{.x = 1.5F, .y = 1.0F, .z = 1.0F};
    context.expect(near_vec3(pose[3].scale, grown), "scale khoá kéo về 1 theo scale link");
    Pose idle = anim::bind_pose(*rig);
    const anim::Blend none{.time = 0.0F, .weight = 0.0F, .scale = 1.0F};
    context.expect(anim::apply(shove, none, idle).has_value(), "weight 0");
    context.expect(idle[3].position == start, "weight 0 không đổi gì");
    BoneTrack spin = track_of(3);
    spin.flags = anim::kKeyRotation;
    spin.keys = {key(0.0F, Quat{.x = 0.0F, .y = 0.866025404F, .z = 0.0F, .w = -0.5F}, kZero, kUnit)};
    const anim::Animation turn{.name = "quay", .length = 1.0F, .tracks = {spin}};
    Pose turned = anim::bind_pose(*rig);
    const anim::Blend half_weight{.time = 0.0F, .weight = 0.5F, .scale = 1.0F};
    context.expect(anim::apply(turn, half_weight, turned).has_value(), "quay nửa weight");
    const Quat target = spin.keys[0].rotation;
    const Quat direct = ogre::quat_nlerp(0.5F, Quat{}, target, ogre::Arc::kDirect);
    const Quat shortest = ogre::quat_nlerp(0.5F, Quat{}, target, ogre::Arc::kShortest);
    context.expect(near_quat(turned[3].orientation, direct), "nlerp cộng dồn đi thẳng tới khoá");
    context.expect(!near_quat(turned[3].orientation, shortest), "không đi đường ngắn nhất");
}

// Rig và animation hỏng

[[nodiscard]] anim::SourceSkeleton with_handle(std::size_t index, std::uint16_t handle) {
    anim::SourceSkeleton skeleton = make_skeleton();
    skeleton.bones[index].handle = handle;
    return skeleton;
}

[[nodiscard]] bool fails(const RigResult& result, RigError error) {
    return !result.has_value() && result.error() == error;
}

void rejects_bad_rig(Context& context) {
    const anim::SourceSkeleton nothing;
    context.expect(fails(Rig::create(nothing), RigError::kEmpty), "skeleton rỗng");
    context.expect(fails(Rig::create(with_handle(3, 7)), RigError::kBadHandle), "handle lệch");
    context.expect(fails(Rig::create(with_handle(3, 1)), RigError::kDuplicateHandle), "handle trùng");
    anim::SourceSkeleton stray = make_skeleton();
    stray.parents.push_back(anim::BoneParent{.child = 3, .parent = 9});
    context.expect(fails(Rig::create(stray), RigError::kBadParent), "cha không có");
    anim::SourceSkeleton twice = make_skeleton();
    twice.parents.push_back(anim::BoneParent{.child = 1, .parent = 0});
    context.expect(fails(Rig::create(twice), RigError::kSecondParent), "hai cha");
    anim::SourceSkeleton loop = make_skeleton();
    loop.parents.push_back(anim::BoneParent{.child = 0, .parent = 1});
    context.expect(fails(Rig::create(loop), RigError::kCycle), "vòng cha con");
}

void rejects_bad_animation(Context& context) {
    const RigResult rig = Rig::create(make_skeleton());
    if (!rig) return;
    BoneTrack stray = track_of(4);
    stray.flags = anim::kKeyTranslate;
    stray.keys = {key(0.0F, Quat{}, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F}, kUnit)};
    BoneTrack fine = track_of(0);
    fine.flags = anim::kKeyTranslate;
    fine.keys = stray.keys;
    const anim::Animation broken{.name = "hong", .length = 1.0F, .tracks = {fine, stray}};
    Pose pose = anim::bind_pose(*rig);
    const auto result = anim::apply(broken, anim::Blend{}, pose);
    context.expect(!result && result.error() == anim::PoseError::kBadBone, "track trỏ xương không có");
    const Vec3 untouched{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    context.expect(pose[0].position == untouched, "lỗi thì tư thế không đổi");
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const auto timeless = anim::apply(make_walk(), blend_at(nan), pose);
    context.expect(!timeless && timeless.error() == anim::PoseError::kBadTime, "thời gian NaN");
}

// Lệch có chủ đích: bảng xương trỏ handle ngoài skeleton ra ma trận đơn vị.
void palette_outside(Context& context) {
    const RigResult rig = Rig::create(make_skeleton());
    if (!rig) return;
    Pose pose = anim::bind_pose(*rig);
    const anim::Blend blend = blend_at(0.9F);
    context.expect(anim::apply(make_walk(), blend, pose).has_value(), "cộng dồn di");
    const std::vector<Affine> skin = rig->skin(pose);
    const std::array<std::uint16_t, 4> palette = {2, 28, 0, 39};
    const std::vector<Affine> used = anim::palette_matrices(skin, palette);
    context.expect(used.size() == 4, "một ma trận mỗi phần tử bảng");
    if (used.size() != 4) return;
    context.expect(used[0] == skin[2] && used[2] == skin[0], "handle có thật lấy đúng ma trận");
    const bool is_identity = used[1] == anim::kIdentityAffine && used[3] == anim::kIdentityAffine;
    context.expect(is_identity, "handle ngoài skeleton ra đơn vị");
}

// Skeleton mở rộng

[[nodiscard]] anim::Bone named(std::string name, std::uint16_t handle) {
    return bone_of(std::move(name), handle, Vec3{});
}

// Skeleton mở rộng của make_skeleton: đủ bốn xương chính theo tên nhưng handle khác, cộng chuỗi áo
// choàng vai (con của thân) và vai2 (con của vai), như pifeng01..10 dưới spine1 của client 2026.
[[nodiscard]] anim::SourceSkeleton extended_skeleton() {
    anim::SourceSkeleton skeleton;
    skeleton.bones = {
        named("than", 0), named("goc", 1), named("chan", 2), named("tay", 3), named("vai", 4), named("vai2", 5)};
    skeleton.parents = {anim::BoneParent{.child = 0, .parent = 1}, anim::BoneParent{.child = 2, .parent = 1},
        anim::BoneParent{.child = 3, .parent = 0}, anim::BoneParent{.child = 4, .parent = 0},
        anim::BoneParent{.child = 5, .parent = 4}};
    return skeleton;
}

// Xương chính khớp theo tên (handle của hai skeleton khác nhau); xương thêm đi theo tổ tiên chính
// gần nhất; xương thêm không có tổ tiên nào trong skeleton chính là lỗi.
void retargets_by_name(Context& context) {
    const auto map = anim::retarget(extended_skeleton(), make_skeleton());
    const std::vector<std::uint16_t> wanted = {2, 0, 3, 1, 2, 2};
    context.expect(map && *map == wanted, "tên khớp tên, vai và vai2 theo thân");
    anim::SourceSkeleton orphan = extended_skeleton();
    orphan.bones.push_back(named("treo", 6));
    const auto lost = anim::retarget(orphan, make_skeleton());
    context.expect(!lost && lost.error() == anim::RetargetError::kOrphan, "xương không tổ tiên");
}

// Bảng xương của submesh đổi sang handle của skeleton chính; handle ngoài skeleton riêng thành
// kUnknownBone, nên palette_matrices cho nó ma trận đơn vị như trước.
void retargets_palettes(Context& context) {
    const auto map = anim::retarget(extended_skeleton(), make_skeleton());
    context.expect(map.has_value(), "dựng được bảng handle");
    if (!map) return;
    std::vector<std::uint16_t> palette = {3, 5, 9};
    anim::retarget_palette(palette, *map);
    const std::vector<std::uint16_t> wanted = {1, 2, anim::kUnknownBone};
    context.expect(palette == wanted, "bảng xương theo skeleton chính");
    std::vector<std::uint16_t> empty;
    anim::retarget_palette(empty, *map);
    context.expect(empty.empty(), "bảng rỗng của submesh không skin giữ nguyên");
}

constexpr std::array kCases{
    Case{.name = "bind_is_identity", .body = &bind_is_identity},
    Case{.name = "matches_ogre", .body = &matches_ogre},
    Case{.name = "loops_time", .body = &loops_time},
    Case{.name = "samples_keys", .body = &samples_keys},
    Case{.name = "samples_equal_times", .body = &samples_equal_times},
    Case{.name = "zero_length_stands", .body = &zero_length_stands},
    Case{.name = "accumulates", .body = &accumulates},
    Case{.name = "rejects_bad_rig", .body = &rejects_bad_rig},
    Case{.name = "rejects_bad_animation", .body = &rejects_bad_animation},
    Case{.name = "palette_outside", .body = &palette_outside},
    Case{.name = "retargets_by_name", .body = &retargets_by_name},
    Case{.name = "retargets_palettes", .body = &retargets_palettes},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "anim_tests: mọi ca phải qua");
    return 0;
}
