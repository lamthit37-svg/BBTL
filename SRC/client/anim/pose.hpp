#pragma once
// Tư thế theo thời gian. Port từ OGRE 1.2.5 trong _ref: AnimationState::setTimePosition (nhánh
// lặp), Animation::_getTimeIndex (quấn thời gian), AnimationTrack::getKeyFramesAtTime,
// NodeAnimationTrack::getInterpolatedKeyFrame và NodeAnimationTrack::applyToNode nhánh cộng dồn,
// cùng Node::translate, Node::rotate, Node::scale mà nhánh đó gọi. Client đặt
// ANIMBLEND_CUMULATIVE (WXLogicModel.cpp) và để nội suy mặc định IM_LINEAR, RIM_LINEAR
// (WXLogicModelManager.cpp), nên chỉ có các nhánh đó.
//
// Lệch có chủ đích so với OGRE: animation dài 0 giây đứng ở khoá đầu. OGRE lấy fmod thời gian cho
// độ dài 0 ra NaN; trên _ref có hai animation "chết" như vậy.
// Nguồn: TLBB Dev src/anim/pose.hpp@e0d89a6. Khác gốc: namespace game::anim; enumerator mang tiền
// tố k; ba số time, weight, scale của apply gom vào Blend (cổng của dự án gom tham số cùng nhóm).

#include "anim/asset.hpp"
#include "anim/rig.hpp"

#include <cstdint>
#include <expected>
#include <vector>

namespace game::anim {

// Tư thế: biến đổi cục bộ của từng xương, theo handle.
using Pose = std::vector<Transform>;

// Bind pose, như Skeleton::reset đưa mọi xương về trạng thái đầu.
[[nodiscard]] Pose bind_pose(const Rig& rig);

// Như trên, nhưng nạp vào dãy người gọi giữ: đường vẽ gọi mỗi khung cho mọi hình.
void bind_pose(const Rig& rig, Pose& out);

// Thời điểm của animation lặp sau khi cộng thời gian: fmod theo độ dài, âm thì cộng thêm một độ
// dài.
[[nodiscard]] float loop_time(float time, float length);

// Khoá nội suy của track tại time trong animation dài length: hai khoá kẹp thời điểm, quay nlerp
// đường ngắn nhất, dịch và scale nội suy tuyến tính. Qua khoá cuối thì nội suy về khoá đầu như vòng
// lặp; trước khoá đầu thì giữ khoá đầu. Track rỗng cho khoá mặc định.
[[nodiscard]] BoneKey sample(const BoneTrack& track, float time, float length);

enum class PoseError : std::uint8_t { kBadBone, kBadTime };

// Một lần cộng dồn: thời điểm (từ loop_time), trọng số và tỉ lệ. Tỉ lệ là scale của skeleton link
// (SourceSkeleton::animation_scale), 1 khi animation là của chính skeleton.
struct Blend {
    float time = 0.0F;
    float weight = 1.0F;
    float scale = 1.0F;
};

// Cộng dồn animation vào tư thế: dịch cộng translate * weight * scale, quay nhân phải
// nlerp(weight, đơn vị, khoá) không đi đường ngắn nhất, scale nhân. time lấy từ loop_time: vòng
// quấn bên trong trừ dần từng độ dài như OGRE. Track trỏ xương không có hay thời gian không hữu
// hạn thì trả lỗi và tư thế không đổi.
[[nodiscard]] std::expected<void, PoseError> apply(const Animation& animation, const Blend& blend, Pose& pose);

} // namespace game::anim
