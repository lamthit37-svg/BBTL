// Tư thế theo thời gian. Phép tính theo đúng toán tử và thứ tự của các hàm OGRE 1.2.5 ghi ở từng
// hàm; Animation::_getTimeIndex tra khoá qua bảng chỉ số toàn cục nhưng cho cùng cặp khoá với
// lower_bound trên khoá của track (OGRE tự kiểm điều này ở bản debug), nên ở đây tra thẳng.
// Nguồn: TLBB Dev src/anim/pose.cpp@e0d89a6. Khác gốc: namespace game::anim, kiểu toán ở
// game::ogre; apply nhận Blend; vòng cộng dồn của apply tách thân thành accumulate_all (cổng của
// dự án cấm `if` trong vòng lặp); hằng viết hậu tố F; tên biến dài hơn ba ký tự.
#include "anim/pose.hpp"

#include "anim/asset.hpp"
#include "anim/rig.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <expected>
#include <span>

namespace game::anim {
namespace {

using ogre::Quat;
using ogre::Vec3;

constexpr Vec3 kUnitScale{.x = 1.0F, .y = 1.0F, .z = 1.0F};

// Animation::_getTimeIndex (và nhánh không có chỉ số của getKeyFramesAtTime): trừ dần độ dài khi
// thời gian vượt độ dài; đúng bằng độ dài thì giữ nguyên.
float wrap_time(float time, float length) {
    while (time > length && length > 0.0F) {
        time -= length;
    }
    return time;
}

// Thời điểm cần tra và độ dài của animation chứa nó.
struct Cycle {
    float time = 0.0F;
    float length = 0.0F;
};

// Hai khoá kẹp một thời điểm và thời gian của khoá sau.
struct Bracket {
    std::size_t first = 0;
    std::size_t second = 0;
    float second_time = 0.0F;
};

// AnimationTrack::getKeyFramesAtTime: khoá sau là khoá đầu tiên có thời gian không nhỏ hơn thời
// điểm. Không có khoá như vậy thì khoá sau là khoá đầu cộng một độ dài và khoá trước là khoá cuối;
// còn lại khoá trước lùi một khoá khi thời điểm nhỏ hơn khoá sau.
Bracket bracket(std::span<const BoneKey> keys, const Cycle& cycle) {
    const float time = cycle.time;
    const auto next = std::ranges::lower_bound(keys, time, {}, &BoneKey::time);
    if (next == keys.end()) {
        return Bracket{.first = keys.size() - 1, .second = 0, .second_time = cycle.length + keys.front().time};
    }
    const auto index = static_cast<std::size_t>(next - keys.begin());
    const bool step_back = index != 0 && time < next->time;
    return Bracket{.first = step_back ? index - 1 : index, .second = index, .second_time = next->time};
}

// Vị trí nội suy giữa hai khoá: tỉ lệ t trong [0, 1) và thời điểm đang tra.
struct Moment {
    float blend = 0.0F;
    float time = 0.0F;
};

// NodeAnimationTrack::getInterpolatedKeyFrame, IM_LINEAR và RIM_LINEAR: t bằng 0 thì lấy nguyên
// khoá trước; còn lại quay nlerp đường ngắn nhất (mUseShortestRotationPath mặc định true), dịch và
// scale là base + (sau - base) * t.
BoneKey interpolate(const BoneKey& first, const BoneKey& second, const Moment& moment) {
    const float blend = moment.blend;
    if (blend == 0.0F) return first;
    BoneKey out;
    out.time = moment.time;
    out.rotation = ogre::quat_nlerp(blend, first.rotation, second.rotation, ogre::Arc::kShortest);
    const Vec3 move = ogre::sub_vec3(second.translate, first.translate);
    out.translate = ogre::add_vec3(first.translate, ogre::scale_vec3(move, blend));
    const Vec3 grow = ogre::sub_vec3(second.scale, first.scale);
    out.scale = ogre::add_vec3(first.scale, ogre::scale_vec3(grow, blend));
    return out;
}

// NodeAnimationTrack::applyToNode, nhánh accumulate: scale của skeleton link kéo scale khoá về 1.
Vec3 linked_scale(Vec3 key_scale, float scale) {
    const bool plain = scale == 1.0F || key_scale == kUnitScale;
    if (plain) return key_scale;
    const Vec3 grow = ogre::sub_vec3(key_scale, kUnitScale);
    return ogre::add_vec3(kUnitScale, ogre::scale_vec3(grow, scale));
}

// Một track đang áp lên một nút: vị trí của lần áp và độ dài animation.
struct Step {
    float time = 0.0F;
    float length = 0.0F;
    float weight = 1.0F;
    float scale = 1.0F;
};

// NodeAnimationTrack::applyToNode, nhánh accumulate: Node::translate (TS_PARENT) cộng vào vị trí,
// Node::rotate (TS_LOCAL) nhân phải hướng, Node::scale nhân scale. nlerp từ đơn vị tới khoá dùng cờ
// mặc định shortestPath = false của Quaternion::nlerp.
void accumulate(const BoneTrack& track, const Step& step, Transform& node) {
    if (track.keys.empty() || step.weight == 0.0F) return;
    const BoneKey key = sample(track, step.time, step.length);
    const Vec3 translate = ogre::scale_vec3(ogre::scale_vec3(key.translate, step.weight), step.scale);
    node.position = ogre::add_vec3(node.position, translate);
    const Quat rotate = ogre::quat_nlerp(step.weight, Quat{}, key.rotation, ogre::Arc::kDirect);
    node.orientation = ogre::quat_multiply(node.orientation, rotate);
    node.scale = ogre::mul_vec3(node.scale, linked_scale(key.scale, step.scale));
}

// Áp mọi track lên xương của nó, theo thứ tự track trong animation.
void accumulate_all(const Animation& animation, const Step& step, Pose& pose) {
    for (const BoneTrack& track : animation.tracks) {
        accumulate(track, step, pose[track.bone]);
    }
}

} // namespace

// Skeleton::reset: Node::resetToInitialState của mọi xương.
Pose bind_pose(const Rig& rig) {
    const std::span<const Transform> initial = rig.initial();
    return {initial.begin(), initial.end()};
}

void bind_pose(const Rig& rig, Pose& out) {
    out.assign(rig.initial().begin(), rig.initial().end());
}

// AnimationState::setTimePosition khi mLoop. Lệch có chủ đích: độ dài không dương thì đứng ở 0 thay
// vì fmod ra NaN.
float loop_time(float time, float length) {
    if (!(length > 0.0F)) return 0.0F;
    float wrapped = std::fmod(time, length);
    if (wrapped < 0.0F) wrapped += length;
    return wrapped;
}

// AnimationTrack::getKeyFramesAtTime rồi NodeAnimationTrack::getInterpolatedKeyFrame. Lệch có chủ
// đích: animation dài 0 lấy khoá đầu. Track rỗng không đi tới đây trong OGRE (applyToNode bỏ qua);
// ở đây cho khoá mặc định.
BoneKey sample(const BoneTrack& track, float time, float length) {
    if (track.keys.empty()) return BoneKey{};
    if (!(length > 0.0F)) return track.keys.front();
    const float position = wrap_time(time, length);
    const Bracket pair = bracket(track.keys, Cycle{.time = position, .length = length});
    const BoneKey& first = track.keys[pair.first];
    const BoneKey& second = track.keys[pair.second];
    const float span = pair.second_time - first.time;
    const float blend = first.time == pair.second_time ? 0.0F : (position - first.time) / span;
    return interpolate(first, second, Moment{.blend = blend, .time = position});
}

// Animation::apply với skeleton: quấn thời gian một lần rồi applyToNode từng track lên xương của
// nó.
std::expected<void, PoseError> apply(const Animation& animation, const Blend& blend, Pose& pose) {
    if (!std::isfinite(blend.time)) return std::unexpected(PoseError::kBadTime);
    const auto missing = [&pose](const BoneTrack& track) { return track.bone >= pose.size(); };
    if (std::ranges::any_of(animation.tracks, missing)) {
        return std::unexpected(PoseError::kBadBone);
    }
    const float position = wrap_time(blend.time, animation.length);
    const Step step{.time = position, .length = animation.length, .weight = blend.weight, .scale = blend.scale};
    accumulate_all(animation, step, pose);
    return {};
}

} // namespace game::anim
