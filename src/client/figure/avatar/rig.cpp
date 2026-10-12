// Đổi Model sang xương và animation của anim/ (xem rig.hpp). Phép tính bằng float như dữ liệu gốc;
// khoá tuyệt đối do công cụ xuất tính ở double rồi làm tròn float32, nên phép ngược ở đây khớp
// khoá gốc trong vài ulp, không bit-đúng.
#include "avatar/rig.hpp"

#include "anim/asset.hpp"
#include "core/error.hpp"
#include "math/types.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <map>
#include <optional>
#include <utility>
#include <vector>

namespace game::resource {
namespace {

[[nodiscard]] core::Failure bad(core::Message message) {
    return core::fail(core::ErrorCode::kCorrupt, message);
}

[[nodiscard]] ogre::Vec3 vec3_of(const math::Float3& value) noexcept {
    return {.x = value.x, .y = value.y, .z = value.z};
}

[[nodiscard]] ogre::Quat quat_of(const math::Float4& value) noexcept {
    return {.x = value.x, .y = value.y, .z = value.z, .w = value.w};
}

// Nút của model là xương: skin đầu (nếu có) quyết định, không thì mọi nút.
[[nodiscard]] std::size_t bone_count(const Model& model) noexcept {
    if (model.skins.empty()) return model.nodes.size();
    return model.skins.front().joints.size();
}

[[nodiscard]] core::Status check_bone(const Model& model, std::size_t handle) {
    if (model.skins.empty()) return core::ok();
    if (model.skins.front().joints.at(handle) != handle) return bad("handle xương lệch chỉ số nút");
    return core::ok();
}

[[nodiscard]] core::Result<anim::Bone> bone_of(const Model& model, std::size_t handle) {
    const core::Status checked = check_bone(model, handle);
    if (!checked) return std::unexpected(checked.error());
    const Node& node = model.nodes.at(handle);
    if (!node.parts) return bad("xương khai bằng ma trận, không phải tịnh tiến, xoay, tỉ lệ");
    anim::Bone bone;
    bone.name = node.name;
    bone.handle = static_cast<std::uint16_t>(handle);
    bone.position = vec3_of(node.parts->translation);
    bone.orientation = quat_of(node.parts->rotation);
    bone.scale = vec3_of(node.parts->scale);
    return bone;
}

[[nodiscard]] core::Status append_bone(const Model& model, std::size_t handle, anim::SourceSkeleton& skeleton) {
    auto bone = bone_of(model, handle);
    if (!bone) return std::unexpected(bone.error());
    skeleton.bones.push_back(std::move(*bone));
    return core::ok();
}

// Thêm cạnh cha con cho một nút con, nếu nút con cũng là xương.
void add_edge(anim::SourceSkeleton& skeleton, std::size_t handle, std::uint32_t child) {
    if (child >= skeleton.bones.size()) return;
    skeleton.parents.push_back(anim::BoneParent{
        .child = static_cast<std::uint16_t>(child), .parent = static_cast<std::uint16_t>(handle)});
}

void add_edges(const Model& model, std::size_t handle, anim::SourceSkeleton& skeleton) {
    for (const std::uint32_t child : model.nodes.at(handle).children) {
        add_edge(skeleton, handle, child);
    }
}

// Các kênh của một nút trong một clip.
struct NodeChannels {
    const Track* translation = nullptr;
    const Track* rotation = nullptr;
    const Track* scale = nullptr;
};

// Chỗ của kênh theo loại; kênh trọng số morph không thuộc tư thế xương nên không có chỗ.
[[nodiscard]] const Track** slot_of(NodeChannels& channels, TrackKind kind) noexcept {
    switch (kind) {
    case TrackKind::kTranslation: return &channels.translation;
    case TrackKind::kRotation: return &channels.rotation;
    case TrackKind::kScale: return &channels.scale;
    case TrackKind::kWeights: break;
    }
    return nullptr;
}

[[nodiscard]] core::Status assign_channel(NodeChannels& channels, const Track& track) {
    const bool is_linear = track.interpolation == Interpolation::kLinear;
    if (!is_linear) {
        return core::fail(core::ErrorCode::kUnsupported, "clip xương chỉ nhận nội suy tuyến tính");
    }
    const Track** slot = slot_of(channels, track.kind);
    if (slot == nullptr) return core::ok();
    if (*slot != nullptr) return bad("hai kênh cùng đích trên một nút");
    *slot = &track;
    return core::ok();
}

using ChannelMap = std::map<std::uint32_t, NodeChannels>;

[[nodiscard]] core::Status gather(const Clip& clip, std::size_t nodes, ChannelMap& by_node) {
    core::Status status = core::ok();
    for (std::size_t at = 0; at < clip.tracks.size() && status; ++at) {
        const Track& track = clip.tracks.at(at);
        status = track.node < nodes ? assign_channel(by_node[track.node], track) : bad("kênh trỏ nút ngoài model");
    }
    return status;
}

// Các kênh có mặt của nút.
[[nodiscard]] std::vector<const Track*> present_of(const NodeChannels& channels) {
    std::vector<const Track*> present;
    const std::array<const Track*, 3> all{channels.translation, channels.rotation, channels.scale};
    std::ranges::copy_if(all, std::back_inserter(present), [](const Track* track) { return track != nullptr; });
    return present;
}

// Thời điểm chung của mọi kênh có mặt của nút; rỗng khi kênh lệch thời điểm.
[[nodiscard]] std::optional<std::vector<float>> shared_times(const NodeChannels& channels) {
    const std::vector<const Track*> present = present_of(channels);
    if (present.empty()) return std::vector<float>{};
    const std::vector<float>& first = present.front()->times;
    const auto is_same = [&first](const Track* track) { return track->times == first; };
    if (!std::ranges::all_of(present, is_same)) return std::nullopt;
    return first;
}

// Khoá thứ index của nút: giá trị tuyệt đối trừ ngược tư thế gốc (xem rig.hpp). time lấy từ thời
// điểm chung của nút.
struct KeyAsk {
    const NodeChannels* channels = nullptr;
    const anim::Bone* bind = nullptr;
    std::size_t index = 0;
    float time = 0.0F;
};

[[nodiscard]] anim::BoneKey key_at(const KeyAsk& ask) {
    const NodeChannels& channels = *ask.channels;
    const anim::Bone& bind = *ask.bind;
    const std::size_t index = ask.index;
    anim::BoneKey key;
    key.time = ask.time;
    if (channels.translation != nullptr) {
        const std::size_t base = index * 3;
        const ogre::Vec3 absolute{.x = channels.translation->values.at(base),
            .y = channels.translation->values.at(base + 1),
            .z = channels.translation->values.at(base + 2)};
        key.translate = ogre::sub_vec3(absolute, bind.position);
    }
    if (channels.rotation != nullptr) {
        const std::size_t base = index * 4;
        const ogre::Quat absolute{.x = channels.rotation->values.at(base),
            .y = channels.rotation->values.at(base + 1),
            .z = channels.rotation->values.at(base + 2),
            .w = channels.rotation->values.at(base + 3)};
        key.rotation = ogre::quat_multiply(ogre::quat_inverse(bind.orientation), absolute);
    }
    if (channels.scale != nullptr) {
        const std::size_t base = index * 3;
        const ogre::Vec3 absolute{.x = channels.scale->values.at(base),
            .y = channels.scale->values.at(base + 1),
            .z = channels.scale->values.at(base + 2)};
        key.scale = ogre::div_vec3(absolute, bind.scale);
    }
    return key;
}

[[nodiscard]] std::uint8_t flags_of(const NodeChannels& channels) noexcept {
    const std::uint8_t moves = channels.translation != nullptr ? anim::kKeyTranslate : 0;
    const std::uint8_t turns = channels.rotation != nullptr ? anim::kKeyRotation : 0;
    const std::uint8_t grows = channels.scale != nullptr ? anim::kKeyScale : 0;
    return static_cast<std::uint8_t>(moves | turns | grows);
}

[[nodiscard]] core::Result<anim::BoneTrack> track_of(std::uint32_t node, const NodeChannels& channels,
    const anim::SourceSkeleton& own) {
    if (node >= own.bones.size()) return bad("kênh trỏ nút không phải xương của tệp");
    const std::optional<std::vector<float>> times = shared_times(channels);
    if (!times) return core::fail(core::ErrorCode::kUnsupported, "các kênh của một nút khác thời điểm");
    const anim::Bone& bind = own.bones.at(node);
    anim::BoneTrack track;
    track.bone = bind.handle;
    track.flags = flags_of(channels);
    track.keys.reserve(times->size());
    for (std::size_t index = 0; index < times->size(); ++index) {
        const KeyAsk ask{.channels = &channels, .bind = &bind, .index = index, .time = times->at(index)};
        track.keys.push_back(key_at(ask));
    }
    return track;
}

[[nodiscard]] float last_time(const anim::BoneTrack& track) noexcept {
    return track.keys.empty() ? 0.0F : track.keys.back().time;
}

[[nodiscard]] core::Status add_track(const ChannelMap::value_type& entry, const anim::SourceSkeleton& own,
    anim::Animation& animation) {
    auto track = track_of(entry.first, entry.second, own);
    if (!track) return std::unexpected(track.error());
    animation.length = std::max(animation.length, last_time(*track));
    animation.tracks.push_back(std::move(*track));
    return core::ok();
}

} // namespace

core::Result<anim::SourceSkeleton> bones_of(const Model& model) {
    const std::size_t count = bone_count(model);
    if (count == 0 || count > model.nodes.size()) return bad("model không có xương");
    anim::SourceSkeleton skeleton;
    skeleton.bones.reserve(count);
    core::Status status = core::ok();
    for (std::size_t handle = 0; handle < count && status; ++handle) {
        status = append_bone(model, handle, skeleton);
    }
    if (!status) return std::unexpected(status.error());
    for (std::size_t handle = 0; handle < count; ++handle) {
        add_edges(model, handle, skeleton);
    }
    return skeleton;
}

core::Result<anim::Animation> animation_of(const Model& model, std::size_t index, const anim::SourceSkeleton& own) {
    if (index >= model.clips.size()) {
        return core::fail(core::ErrorCode::kOutOfRange, "clip ngoài miền");
    }
    const Clip& clip = model.clips.at(index);
    ChannelMap by_node;
    const core::Status gathered = gather(clip, model.nodes.size(), by_node);
    if (!gathered) return std::unexpected(gathered.error());
    anim::Animation animation;
    animation.name = clip.name;
    animation.tracks.reserve(by_node.size());
    core::Status status = core::ok();
    for (auto entry = by_node.begin(); entry != by_node.end() && status; ++entry) {
        status = add_track(*entry, own, animation);
    }
    if (!status) return std::unexpected(status.error());
    return animation;
}

} // namespace game::resource
