// Test của cầu nối GLB sang xương OGRE (resource/rig): xương lấy đúng từ nút, cạnh cha con, khoá
// tuyệt đối đổi thành khoá độ lệch rồi cộng dồn lại ra đúng giá trị tuyệt đối ở thời điểm khoá, và
// ca dữ liệu thật của người chơi nữ (bind pose ra ma trận skin đơn vị, clip áp lại đúng khoá tuyệt
// đối của tệp). Ca dữ liệu thật chỉ chạy khi CLIENT/data có tệp; không có thì in thông báo.
#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "core/check.hpp"
#include "core/error.hpp"
#include "fs/disk.hpp"
#include "math/types.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "resource/model.hpp"
#include "resource/rig.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

constexpr float kTight = 1e-5F;

[[nodiscard]] bool near_value(float left, float right, float tolerance) {
    return std::abs(left - right) <= tolerance;
}

[[nodiscard]] bool near_vec3(ogre::Vec3 left, ogre::Vec3 right, float tolerance) {
    const bool is_xy = near_value(left.x, right.x, tolerance) && near_value(left.y, right.y, tolerance);
    return is_xy && near_value(left.z, right.z, tolerance);
}

// Hai quaternion cùng một phép xoay: tích vô hướng gần ±1.
[[nodiscard]] bool same_rotation(ogre::Quat left, ogre::Quat right, float tolerance) {
    return near_value(std::abs(ogre::quat_dot(left, right)), 1.0F, tolerance);
}

[[nodiscard]] resource::Node bone_node(std::string name, const math::Float3& translation, const math::Float4& rotation,
    std::vector<std::uint32_t> children) {
    resource::Node node;
    node.name = std::move(name);
    node.parts = resource::NodeParts{
        .translation = translation, .rotation = rotation, .scale = {.x = 1.0F, .y = 1.0F, .z = 1.0F}};
    node.children = std::move(children);
    return node;
}

// Ba xương: gốc xoay 30 độ quanh Y, con ở (0, 2, 0), cháu ở (1, 0, 0) có scale không đều.
[[nodiscard]] resource::Model chain_model() {
    resource::Model model;
    const math::Float4 turn{.x = 0.0F, .y = 0.258819045F, .z = 0.0F, .w = 0.965925826F};
    const math::Float4 none{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = 1.0F};
    model.nodes.push_back(bone_node("goc", {.x = 0.0F, .y = 1.0F, .z = 0.0F}, turn, {1}));
    model.nodes.push_back(bone_node("con", {.x = 0.0F, .y = 2.0F, .z = 0.0F}, none, {2}));
    model.nodes.push_back(bone_node("chau", {.x = 1.0F, .y = 0.0F, .z = 0.0F}, none, {}));
    model.nodes.back().parts = resource::NodeParts{
        .translation = {.x = 1.0F, .y = 0.0F, .z = 0.0F}, .rotation = none, .scale = {.x = 1.5F, .y = 1.0F, .z = 0.5F}};
    return model;
}

[[nodiscard]] resource::Track track_of(std::uint32_t node, resource::TrackKind kind, std::vector<float> times,
    std::vector<float> values) {
    resource::Track track;
    track.node = node;
    track.kind = kind;
    track.times = std::move(times);
    track.values = std::move(values);
    return track;
}

void bones_follow_nodes(Context& context) {
    const resource::Model model = chain_model();
    const auto bones = resource::bones_of(model);
    context.expect(bones.has_value(), "ba nút khai TRS thành xương");
    if (!bones) return;
    context.expect(bones->bones.size() == 3, "ba xương");
    context.expect(bones->bones[1].name == "con" && bones->bones[1].handle == 1, "tên và handle");
    context.expect(near_vec3(bones->bones[1].position, {.x = 0.0F, .y = 2.0F, .z = 0.0F}, kTight), "vị trí");
    context.expect(near_vec3(bones->bones[2].scale, {.x = 1.5F, .y = 1.0F, .z = 0.5F}, kTight), "scale");
    context.expect(bones->bones[0].orientation.y == 0.258819045F, "xoay giữ nguyên chữ của tệp");
    const std::vector<anim::BoneParent> wanted{{.child = 1, .parent = 0}, {.child = 2, .parent = 1}};
    context.expect(bones->parents == wanted, "cạnh cha con theo children của nút");
    context.expect(anim::Rig::create(*bones).has_value(), "dựng được rig từ xương của model");
}

void matrix_bone_is_rejected(Context& context) {
    resource::Model model = chain_model();
    model.nodes[1].parts.reset();
    context.expect(!resource::bones_of(model).has_value(), "xương khai bằng ma trận bị từ chối");
    const resource::Model empty;
    context.expect(!resource::bones_of(empty).has_value(), "model không xương bị từ chối");
}

// Khoá tuyệt đối đổi thành độ lệch rồi cộng dồn lại phải ra đúng giá trị tuyệt đối ở thời điểm
// khoá.
void deltas_reapply_to_absolute(Context& context) {
    resource::Model model = chain_model();
    const std::array<float, 4> absolute_turn{0.0F, 0.5F, 0.0F, 0.8660254F};
    resource::Clip clip;
    clip.name = "xoay";
    clip.tracks.push_back(track_of(1, resource::TrackKind::kRotation, {0.0F, 1.0F},
        {0.0F, 0.0F, 0.0F, 1.0F, absolute_turn[0], absolute_turn[1], absolute_turn[2], absolute_turn[3]}));
    clip.tracks.push_back(track_of(1, resource::TrackKind::kTranslation, {0.0F, 1.0F},
        {0.0F, 2.0F, 0.0F, 0.5F, 3.0F, -1.0F}));
    model.clips.push_back(clip);
    const auto bones = resource::bones_of(model);
    const auto animation = resource::animation_of(model, 0, *bones);
    context.expect(animation.has_value(), "clip đổi được sang khoá độ lệch");
    if (!animation) return;
    context.expect(near_value(animation->length, 1.0F, kTight), "độ dài là thời điểm khoá muộn nhất");
    context.expect(animation->tracks.size() == 1, "một nút một track, hai kênh gộp");
    const anim::BoneTrack& track = animation->tracks.front();
    context.expect(track.bone == 1, "track của nút 1");
    context.expect(track.flags == (anim::kKeyRotation | anim::kKeyTranslate), "cờ theo kênh có mặt");
    const auto rig = anim::Rig::create(*bones);
    anim::Pose pose = anim::bind_pose(*rig);
    const anim::Blend at_end{.time = 1.0F, .weight = 1.0F, .scale = 1.0F};
    context.expect(anim::apply(*animation, at_end, pose).has_value(), "cộng dồn ở thời điểm khoá cuối");
    const ogre::Quat want_turn{.x = 0.0F, .y = 0.5F, .z = 0.0F, .w = 0.8660254F};
    context.expect(same_rotation(pose[1].orientation, want_turn, kTight), "xoay ra đúng giá trị tuyệt đối");
    const ogre::Vec3 want_move{.x = 0.5F, .y = 3.0F, .z = -1.0F};
    context.expect(near_vec3(pose[1].position, want_move, kTight), "dịch ra đúng giá trị tuyệt đối");
    context.expect(near_vec3(pose[0].position, {.x = 0.0F, .y = 1.0F, .z = 0.0F}, kTight), "nút khác giữ bind");
}

void odd_clips_are_rejected(Context& context) {
    resource::Model model = chain_model();
    resource::Clip clip;
    clip.tracks.push_back(track_of(1, resource::TrackKind::kRotation, {0.0F, 1.0F},
        {0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 1.0F}));
    clip.tracks.push_back(track_of(1, resource::TrackKind::kTranslation, {0.0F, 2.0F},
        {0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F}));
    model.clips.push_back(clip);
    const auto bones = resource::bones_of(model);
    context.expect(!resource::animation_of(model, 0, *bones).has_value(), "kênh lệch thời điểm bị từ chối");
    context.expect(!resource::animation_of(model, 5, *bones).has_value(), "clip ngoài miền bị từ chối");
    resource::Model stepped = chain_model();
    resource::Clip step_clip;
    step_clip.tracks.push_back(track_of(1, resource::TrackKind::kRotation, {0.0F}, {0.0F, 0.0F, 0.0F, 1.0F}));
    step_clip.tracks.front().interpolation = resource::Interpolation::kStep;
    stepped.clips.push_back(step_clip);
    context.expect(!resource::animation_of(stepped, 0, *resource::bones_of(stepped)).has_value(),
        "nội suy bậc thang bị từ chối");
}

// Dữ liệu thật

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì các ca dữ liệu thật tự bỏ qua có thông báo.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

// Đường dẫn UTF-8 của một tệp trong CLIENT/data; rỗng khi bản dựng không biết thư mục đó.
[[nodiscard]] std::string real_file(std::string_view relative) {
    if (kClientData.empty()) return {};
    return std::string(kClientData).append("/").append(relative);
}

[[nodiscard]] bool has_real_data(const std::string& file) {
    return !file.empty() && fs::is_file(file);
}

[[nodiscard]] bool is_identity_matrix(const anim::Affine& matrix) {
    const auto gap = [](float one, float two) { return std::abs(one - two); };
    std::array<float, 12> gaps{};
    std::ranges::transform(matrix, anim::kIdentityAffine, gaps.begin(), gap);
    return *std::ranges::max_element(gaps) < 1e-4F;
}

// Sai lệch của dịch ở khoá cuối của một kênh dịch so với khoá tuyệt đối của tệp; kênh khác bỏ qua.
[[nodiscard]] float last_key_gap(const resource::Track& source, const anim::Animation& animation,
    const anim::Rig& rig) {
    if (source.kind != resource::TrackKind::kTranslation) return 0.0F;
    anim::Pose pose = anim::bind_pose(rig);
    const std::size_t last = source.times.size() - 1;
    const anim::Blend at_key{.time = source.times[last], .weight = 1.0F, .scale = 1.0F};
    if (!anim::apply(animation, at_key, pose).has_value()) return 1.0e9F;
    const ogre::Vec3 got = pose[source.node].position;
    const float gap_x = std::abs(got.x - source.values[last * 3]);
    const float gap_y = std::abs(got.y - source.values[(last * 3) + 1]);
    const float gap_z = std::abs(got.z - source.values[(last * 3) + 2]);
    return std::max({gap_x, gap_y, gap_z});
}

// Mọi ma trận skin của skeleton thật ở bind pose phải là ma trận đơn vị: bất biến của công thức
// Bone::_getOffsetTransform, kể cả với xương scale khác 1.
void real_bind_pose_is_identity(Context& context) {
    const std::string file = real_file("Model/女主角.skeleton.glb");
    if (!has_real_data(file)) {
        static_cast<void>(std::fputs("rig_tests: bỏ qua ca dữ liệu thật, không thấy CLIENT/data\n", stderr));
        return;
    }
    const auto model = resource::load_glb_file(file);
    context.expect(model.has_value(), "nạp được skeleton của nữ");
    if (!model) return;
    const auto bones = resource::bones_of(*model);
    context.expect(bones.has_value() && bones->bones.size() == 56, "56 xương");
    if (!bones) return;
    const auto rig = anim::Rig::create(*bones);
    context.expect(rig.has_value(), "dựng rig thật");
    if (!rig) return;
    const std::vector<anim::Affine> skin = rig->skin(anim::bind_pose(*rig));
    const bool is_whole = skin.size() == 56 && std::ranges::all_of(skin, is_identity_matrix);
    context.expect(is_whole, "bind pose: skin là đơn vị");
}

// Clip của tệp, áp lên chính skeleton của tệp, phải ra lại đúng khoá tuyệt đối của GLB ở thời điểm
// khoá: chứng minh phép trừ ngược rồi cộng dồn không đánh mất gì.
void real_clip_reapplies_to_file_keys(Context& context) {
    const std::string file = real_file("Model/女空手站立.skeleton.glb");
    if (!has_real_data(file)) return;
    const auto model = resource::load_glb_file(file);
    context.expect(model.has_value() && model->clips.size() == 2, "hai clip đứng và nghỉ");
    if (!model) return;
    const auto bones = resource::bones_of(*model);
    const auto rig = anim::Rig::create(*bones);
    const auto animation = resource::animation_of(*model, 1, *bones);
    context.expect(animation.has_value() && animation->name == "空手站立01", "clip đứng 01");
    if (!animation || !rig) return;
    context.expect(near_value(animation->length, 2.4F, 1e-4F), "dài 2,4 giây");
    float worst = 0.0F;
    for (const resource::Track& source : model->clips[1].tracks) {
        worst = std::max(worst, last_key_gap(source, *animation, *rig));
    }
    context.expect(worst < 1e-4F, "dịch ở khoá cuối ra đúng giá trị tuyệt đối của tệp");
}

constexpr std::array kCases{
    Case{.name = "bones_follow_nodes", .body = &bones_follow_nodes},
    Case{.name = "matrix_bone_is_rejected", .body = &matrix_bone_is_rejected},
    Case{.name = "deltas_reapply_to_absolute", .body = &deltas_reapply_to_absolute},
    Case{.name = "odd_clips_are_rejected", .body = &odd_clips_are_rejected},
    Case{.name = "real_bind_pose_is_identity", .body = &real_bind_pose_is_identity},
    Case{.name = "real_clip_reapplies_to_file_keys", .body = &real_clip_reapplies_to_file_keys},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "rig_tests: mọi ca phải qua");
    return 0;
}
