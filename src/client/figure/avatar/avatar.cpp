// Nạp người chơi từ tệp GLB và ra ma trận skin mỗi khung (xem avatar.hpp).
#include "avatar/avatar.hpp"

#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "avatar/gait.hpp"
#include "avatar/locator.hpp"
#include "avatar/rig.hpp"
#include "classic/bake.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "look/look.hpp"
#include "look/skill.hpp"
#include "look/weapon.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <iterator>
#include <map>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::avatar {
namespace {

// Một tệp .skeleton đã nạp: xương của chính tệp, và model để lấy clip.
struct File {
    resource::Model model;
    anim::SourceSkeleton bones;
};

// Tệp đã nạp theo tên, để hai clip chung một tệp chỉ nạp một lần.
using Files = std::map<std::string, std::unique_ptr<File>>;

// Nơi nạp: thư mục dữ liệu client và các tệp đã có.
struct Loader {
    std::filesystem::path root;
    Files files;
};

[[nodiscard]] core::Result<const File*> file_of(Loader& loader, const std::string& name) {
    const auto found = loader.files.find(name);
    if (found != loader.files.end()) return found->second.get();
    const std::filesystem::path path = loader.root / "Model" / io::path_from_utf8(name + ".glb");
    auto model = resource::load_glb_file(io::utf8_of(path));
    if (!model) return std::unexpected(model.error());
    classic::note(*model);
    auto bones = resource::bones_of(*model);
    if (!bones) return std::unexpected(bones.error());
    auto kept = std::make_unique<File>(File{.model = std::move(*model), .bones = std::move(*bones)});
    const File* made = kept.get();
    loader.files.emplace(name, std::move(kept));
    return made;
}

// Clip và skeleton chính phải cùng handle và tên xương, vì animation đánh số xương theo handle.
[[nodiscard]] core::Status check_same_bones(const anim::SourceSkeleton& own, const anim::SourceSkeleton& main) {
    const std::size_t shared = std::min(own.bones.size(), main.bones.size());
    const auto differs = [&](std::size_t handle) { return own.bones.at(handle).name != main.bones.at(handle).name; };
    const auto handles = std::views::iota(std::size_t{0}, shared);
    const auto first = std::ranges::find_if(handles, differs);
    if (first == handles.end()) return core::ok();
    return core::fail(core::ErrorCode::kCorrupt, "skeleton của clip lệch skeleton chính", "xương {}", *first);
}

[[nodiscard]] core::Result<anim::Animation> clip_of(Loader& loader, const look::Clip& clip,
    const anim::SourceSkeleton& main) {
    const auto file = file_of(loader, clip.anim);
    if (!file) return std::unexpected(file.error());
    const resource::Model& model = (*file)->model;
    const auto found = std::ranges::find(model.clips, clip.name, &resource::Clip::name);
    if (found == model.clips.end()) {
        return core::fail(core::ErrorCode::kNotFound, "tệp không có clip", "{} / {}", clip.anim, clip.name);
    }
    const core::Status same = check_same_bones((*file)->bones, main);
    if (!same) return std::unexpected(same.error());
    const auto index = static_cast<std::size_t>(found - model.clips.begin());
    return resource::animation_of(model, index, (*file)->bones);
}

[[nodiscard]] core::Result<std::optional<anim::Animation>> optional_clip_of(Loader& loader,
    const std::optional<look::Clip>& clip, const anim::SourceSkeleton& main) {
    if (!clip) return std::optional<anim::Animation>{};
    auto loaded = clip_of(loader, *clip, main);
    if (!loaded) return std::unexpected(loaded.error());
    return {std::move(*loaded)};
}

[[nodiscard]] core::Failure rig_failure(anim::RigError error) {
    static_cast<void>(error);
    return core::fail(core::ErrorCode::kCorrupt, "skeleton chính không dựng được rig");
}

// Tên locator trên mẫu vũ khí nơi hiệu ứng đồ gắn vào (CRFObj_Actor::SetRightWeaponEffect của ref: addEffect(.., "武器特效点")).
constexpr std::string_view kEffectPoint = "武器特效点";

// Affine 3x4 theo hàng của OGRE sang Matrix4 theo cột, hàng cuối (0, 0, 0, 1).
[[nodiscard]] math::Matrix4 matrix_of(const anim::Affine& rows) {
    const math::Vector4 col0(rows.at(0), rows.at(4), rows.at(8), 0.0F);
    const math::Vector4 col1(rows.at(1), rows.at(5), rows.at(9), 0.0F);
    const math::Vector4 col2(rows.at(2), rows.at(6), rows.at(10), 0.0F);
    const math::Vector4 col3(rows.at(3), rows.at(7), rows.at(11), 1.0F);
    return {col0, col1, col2, col3};
}

// Điểm gắn theo tên: locator của mẫu nhân vật trước, rồi xương cùng tên (như LogicModel::getLocatorWorldTransform
// rồi getBoneWorldTransform); xương coi như locator không lệch. Tên rỗng hay không có thì rỗng.
[[nodiscard]] std::optional<Locator> point_of(const std::string& object, const std::string& name,
    std::span<const look::LocatorRow> locators, const anim::SourceSkeleton& skeleton) {
    if (name.empty()) return std::nullopt;
    const look::LocatorRow* row = look::find_locator(locators, object, name);
    if (row != nullptr) return make_locator(*row, skeleton);
    const auto bone = std::ranges::find(skeleton.bones, name, &anim::Bone::name);
    if (bone == skeleton.bones.end()) return std::nullopt;
    Locator locator;
    locator.bone = bone->handle;
    return locator;
}

} // namespace

core::Result<Avatar> Avatar::load(const look::Figure& figure, const std::filesystem::path& data_root,
    std::span<const look::Strike> strikes, std::span<const look::LocatorRow> locators) {
    Loader loader{.root = data_root, .files = {}};
    const auto main = file_of(loader, figure.skeleton);
    if (!main) return std::unexpected(main.error());
    const anim::SourceSkeleton& bones = (*main)->bones;
    auto rig = anim::Rig::create(bones);
    if (!rig) return rig_failure(rig.error());
    auto idle = clip_of(loader, figure.idle, bones);
    if (!idle) return std::unexpected(idle.error());
    auto run = clip_of(loader, figure.run, bones);
    if (!run) return std::unexpected(run.error());
    auto alt = optional_clip_of(loader, figure.idle_alt, bones);
    if (!alt) return std::unexpected(alt.error());
    auto alt2 = optional_clip_of(loader, figure.idle_alt2, bones);
    if (!alt2) return std::unexpected(alt2.error());
    auto jump_stand = optional_clip_of(loader, figure.jump_stand, bones);
    if (!jump_stand) return std::unexpected(jump_stand.error());
    auto jump_run = optional_clip_of(loader, figure.jump_run, bones);
    if (!jump_run) return std::unexpected(jump_run.error());
    auto death = optional_clip_of(loader, figure.death, bones);
    if (!death) return std::unexpected(death.error());
    auto corpse = optional_clip_of(loader, figure.corpse, bones);
    if (!corpse) return std::unexpected(corpse.error());
    std::vector<anim::Animation> strike_clips;
    strike_clips.reserve(strikes.size());
    for (const look::Strike& strike : strikes) {
        auto clip = clip_of(loader, strike.clip, bones);
        if (!clip) return std::unexpected(clip.error());
        strike_clips.push_back(std::move(*clip));
    }
    Avatar avatar(figure, std::move(*rig));
    avatar.strike_defs_.assign(strikes.begin(), strikes.end());
    avatar.strike_clips_ = std::move(strike_clips);
    for (const look::Strike& strike : strikes) {
        std::vector<std::optional<Locator>> points;
        points.reserve(strike.events.size());
        for (const look::StrikeEvent& event : strike.events) {
            points.push_back(point_of(figure.template_name, event.point, locators, bones));
        }
        avatar.event_points_.push_back(std::move(points));
    }
    avatar.idle_ = std::move(*idle);
    avatar.run_ = std::move(*run);
    avatar.idle_alt_ = std::move(*alt);
    avatar.idle_alt2_ = std::move(*alt2);
    avatar.jump_stand_ = std::move(*jump_stand);
    avatar.jump_run_ = std::move(*jump_run);
    avatar.death_ = std::move(*death);
    avatar.corpse_ = std::move(*corpse);
    avatar.mounts_.reserve(figure.held.size());
    for (const look::Held& held : figure.held) {
        const ogre::Vec3 scale{.x = held.scale.at(0), .y = held.scale.at(1), .z = held.scale.at(2)};
        std::optional<Locator> effect_point;
        const look::LocatorRow* point = look::find_locator(locators, held.object, kEffectPoint);
        if (point != nullptr) effect_point = make_locator(*point, bones);
        avatar.mounts_.push_back(
            Mount{.locator = make_locator(held.locator, bones), .scale = scale, .effect_point = effect_point});
    }
    if (figure.idle_trim) {
        const auto found = std::ranges::find(bones.bones, figure.idle_trim->bone, &anim::Bone::name);
        if (found == bones.bones.end()) {
            return core::fail(core::ErrorCode::kCorrupt, "skeleton không có xương cần chỉnh", "{}",
                figure.idle_trim->bone);
        }
        const ogre::Vec3 own_z{.x = 0.0F, .y = 0.0F, .z = 1.0F};
        avatar.trim_ = Trim{.handle = found->handle, .turn = ogre::quat_from_angle_axis(figure.idle_trim->turn, own_z)};
    }
    return avatar;
}

void Avatar::trim_idle(anim::Pose& pose) const noexcept {
    if (!trim_ || trim_->handle >= pose.size()) return;
    anim::Transform& bone = pose[trim_->handle];
    bone.orientation = ogre::quat_multiply(bone.orientation, trim_->turn);
}

void Avatar::mount_matrices(std::span<const anim::Transform> bones, std::vector<math::Matrix4>& out) const {
    out.clear();
    out.reserve(mounts_.size());
    for (const Mount& mount : mounts_) {
        out.push_back(matrix_of(anim::affine_of(slot_pose(mount.locator, bones, mount.scale))));
    }
}

ClipLengths Avatar::lengths() const noexcept {
    ClipLengths lengths;
    lengths.idle = idle_.length;
    lengths.run = run_.length;
    if (idle_alt_) lengths.idle_alt = idle_alt_->length;
    if (idle_alt2_) lengths.idle_alt2 = idle_alt2_->length;
    if (jump_stand_) lengths.jump_stand = jump_stand_->length;
    if (jump_run_) lengths.jump_run = jump_run_->length;
    return lengths;
}

std::optional<anim::Transform> Avatar::effect_pose(std::size_t mount, std::span<const anim::Transform> bones) const {
    if (mount >= mounts_.size()) return std::nullopt;
    const Mount& held = mounts_.at(mount);
    const anim::Transform slot = slot_pose(held.locator, bones, held.scale);
    if (!held.effect_point) return slot;
    // Locator của mẫu vũ khí không theo xương của người chơi: bones rỗng thì nút giữ vị trí lệch và hướng của nó.
    const anim::Transform point = locator_pose(*held.effect_point, {});
    return anim::from_parent(slot, point);
}

std::optional<anim::Transform> Avatar::event_pose(std::size_t strike, std::size_t event,
    std::span<const anim::Transform> bones) const {
    if (strike >= event_points_.size() || strike >= strike_defs_.size()) return std::nullopt;
    const auto& points = event_points_.at(strike);
    if (event >= points.size()) return std::nullopt;
    const std::optional<Locator>& attach = points.at(event);
    if (!attach) return std::nullopt;
    const look::StrikeEvent& block = strike_defs_.at(strike).events.at(event);
    const anim::Transform point = locator_pose(*attach, bones);
    const ogre::Quat offset_turn{.x = block.rotation.at(1), .y = block.rotation.at(2), .z = block.rotation.at(3),
        .w = block.rotation.at(0)};
    const ogre::Vec3 offset{.x = block.offset.at(0), .y = block.offset.at(1), .z = block.offset.at(2)};
    anim::Transform pose;
    pose.orientation = ogre::quat_multiply(point.orientation, offset_turn);
    pose.position = ogre::add_vec3(point.position, ogre::quat_rotate(point.orientation, offset));
    return pose;
}

std::optional<std::size_t> Avatar::strike_index(std::uint32_t skill, std::uint32_t step) const noexcept {
    const auto found = std::ranges::find_if(strike_defs_, [&](const look::Strike& strike) {
        return strike.skill == skill && strike.step == step;
    });
    if (found == strike_defs_.end()) return std::nullopt;
    return static_cast<std::size_t>(found - strike_defs_.begin());
}

float Avatar::strike_length(std::size_t index) const noexcept {
    return index < strike_clips_.size() ? strike_clips_.at(index).length : 0.0F;
}

float Avatar::death_length() const noexcept {
    return death_ ? death_->length : 0.0F;
}

float Avatar::corpse_length() const noexcept {
    return corpse_ ? corpse_->length : 0.0F;
}

const anim::Animation& Avatar::animation(const Playing& playing) const noexcept {
    if (playing.stance == Stance::kStrike && playing.strike < strike_clips_.size()) {
        return strike_clips_.at(playing.strike);
    }
    switch (playing.stance) {
    case Stance::kIdle: return idle_;
    case Stance::kIdleAlt: return idle_alt_ ? *idle_alt_ : idle_;
    case Stance::kIdleAlt2: return idle_alt2_ ? *idle_alt2_ : idle_;
    case Stance::kRun: return run_;
    case Stance::kJumpStand: return jump_stand_ ? *jump_stand_ : idle_;
    case Stance::kJumpRun: return jump_run_ ? *jump_run_ : idle_;
    case Stance::kStrike: return idle_;
    case Stance::kDeath: return death_ ? *death_ : idle_;
    case Stance::kCorpse: return corpse_ ? *corpse_ : (death_ ? *death_ : idle_);
    }
    return idle_;
}

core::Status Skinner::update(const Avatar& avatar, const Playing& playing) {
    anim::bind_pose(avatar.rig(), pose_);
    const anim::Blend blend{.time = playing.time, .weight = 1.0F, .scale = 1.0F};
    const auto applied = anim::apply(avatar.animation(playing), blend, pose_);
    if (!applied) return core::fail(core::ErrorCode::kCorrupt, "clip trỏ xương không có trong rig");
    if (playing.stance == Stance::kIdle) avatar.trim_idle(pose_);
    avatar.rig().skin(pose_, skin_, derived_);
    joints_.clear();
    joints_.reserve(skin_.size());
    std::ranges::transform(skin_, std::back_inserter(joints_), matrix_of);
    return core::ok();
}

} // namespace game::avatar
