/*==============================================================================
 *  THIENLONG  |  VẬT THỂ MODEL CÓ XƯƠNG TRONG CẢNH
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/avatar/ambient.cpp
 *  PHÂN HỆ   : Figure / Avatar
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt ambient.hpp. Thứ tự giống Skinner::update của avatar.cpp: bind_pose, apply clip,
 *    rig.skin; thêm một lượt cho frame để ra ma trận gắn của nút.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "avatar/ambient.hpp"

#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "avatar/avatar.hpp"
#include "avatar/rig.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "math/matrix.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <cstddef>
#include <expected>
#include <filesystem>
#include <iterator>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::avatar {
namespace {

constexpr std::string_view kClipName = "auto";

// Một tệp GLB đã nạp: xương của chính nó và model để lấy clip.
struct Source {
    resource::Model model;
    anim::SourceSkeleton bones;
};

[[nodiscard]] core::Result<Source> source_of(const std::filesystem::path& file) {
    auto model = resource::load_glb_file(io::utf8_of(file));
    if (!model) return std::unexpected(model.error());
    auto bones = resource::bones_of(*model);
    if (!bones) return std::unexpected(bones.error());
    return Source{.model = std::move(*model), .bones = std::move(*bones)};
}

[[nodiscard]] std::size_t clip_index(const resource::Model& model) {
    const auto found = std::ranges::find(model.clips, kClipName, &resource::Clip::name);
    if (found == model.clips.end()) return 0;
    return static_cast<std::size_t>(found - model.clips.begin());
}

// Tệp không có clip (frame đứng yên) cho nullopt.
[[nodiscard]] core::Result<std::optional<anim::Animation>> clip_of(const Source& source) {
    if (source.model.clips.empty()) return std::optional<anim::Animation>{};
    auto clip = resource::animation_of(source.model, clip_index(source.model), source.bones);
    if (!clip) return std::unexpected(clip.error());
    return std::optional<anim::Animation>(std::move(*clip));
}

[[nodiscard]] std::optional<std::size_t> node_of(const anim::SourceSkeleton& bones,
    std::string_view name) {
    for (const anim::Bone& bone : bones.bones)
        if (bone.name == name) return bone.handle;
    return std::nullopt;
}

[[nodiscard]] core::Failure rig_failure() {
    return core::fail(core::ErrorCode::kCorrupt, "xương của vật thể không dựng được rig");
}

// Phát lặp clip ở giây seconds lên pose đã về bind pose. Không có clip thì giữ bind pose.
[[nodiscard]] core::Status play(const std::optional<anim::Animation>& clip, float seconds,
    anim::Pose& pose) {
    if (!clip) return core::ok();
    const bool has_length = clip->length > 0.0F;
    const float time = has_length ? anim::loop_time(seconds, clip->length) : 0.0F;
    const anim::Blend blend{.time = time, .weight = 1.0F, .scale = 1.0F};
    const auto applied = anim::apply(*clip, blend, pose);
    if (!applied) return core::fail(core::ErrorCode::kCorrupt, "clip trỏ xương không có trong rig");
    return core::ok();
}

} // namespace

core::Result<Ambient> Ambient::load(const AmbientFiles& files) {
    auto frame = source_of(files.frame);
    if (!frame) return std::unexpected(frame.error());
    const std::optional<std::size_t> node = node_of(frame->bones, files.node);
    if (!node) return core::fail(core::ErrorCode::kNotFound, "frame không có nút gắn lưới");
    auto body = source_of(files.skeleton);
    if (!body) return std::unexpected(body.error());
    auto frame_rig = anim::Rig::create(frame->bones);
    if (!frame_rig) return rig_failure();
    auto rig = anim::Rig::create(body->bones);
    if (!rig) return rig_failure();
    auto frame_clip = clip_of(*frame);
    if (!frame_clip) return std::unexpected(frame_clip.error());
    auto clip = clip_of(*body);
    if (!clip) return std::unexpected(clip.error());
    Ambient made(std::move(*frame_rig), std::move(*rig));
    made.node_ = *node;
    made.frame_clip_ = std::move(*frame_clip);
    made.clip_ = std::move(*clip);
    return made;
}

core::Status Ambient::update(float seconds) {
    anim::bind_pose(frame_rig_, frame_pose_);
    const core::Status moved = play(frame_clip_, seconds, frame_pose_);
    if (!moved) return moved;
    frame_rig_.skin(frame_pose_, frame_skin_, frame_derived_);
    const bool is_inside = node_ < frame_derived_.size();
    if (!is_inside) return core::fail(core::ErrorCode::kCorrupt, "nút gắn ngoài rig");
    attach_ = matrix_of(anim::affine_of(frame_derived_[node_]));
    anim::bind_pose(rig_, pose_);
    const core::Status waved = play(clip_, seconds, pose_);
    if (!waved) return waved;
    rig_.skin(pose_, skin_, derived_);
    joints_.clear();
    joints_.reserve(skin_.size());
    std::ranges::transform(skin_, std::back_inserter(joints_), matrix_of);
    return core::ok();
}

} // namespace game::avatar
