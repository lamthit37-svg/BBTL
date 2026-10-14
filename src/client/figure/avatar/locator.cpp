// Công thức đặt locator; luật ở locator.hpp, toán tử theo từng hàm OGRE ghi ở chỗ dùng.
#include "avatar/locator.hpp"

#include "anim/asset.hpp"
#include "anim/rig.hpp"
#include "look/weapon.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <optional>
#include <span>

namespace game::avatar {

Locator make_locator(const look::LocatorRow& row, const anim::SourceSkeleton& skeleton) {
    Locator locator;
    const auto found = std::ranges::find(skeleton.bones, row.bone, &anim::Bone::name);
    if (!row.bone.empty() && found != skeleton.bones.end()) locator.bone = found->handle;
    locator.offset = ogre::Vec3{.x = row.offset.at(0), .y = row.offset.at(1), .z = row.offset.at(2)};
    const ogre::Vec3 axis{.x = row.axis.at(0), .y = row.axis.at(1), .z = row.axis.at(2)};
    locator.rotation = ogre::quat_from_angle_axis(row.angle, axis);
    locator.is_translate_first = row.is_translate_first;
    return locator;
}

// _updateLocatorPos: setPosition và setOrientation theo xương rồi translate, rotate TS_LOCAL
// (Node::translate: p += q·d; Node::rotate: q = q ⊗ r) theo thứ tự translate_first. Không xương thì
// như _createLocatorSceneNode: translate(offset) theo TS_PARENT từ gốc, setOrientation(rotation).
anim::Transform locator_pose(const Locator& locator, std::span<const anim::Transform> bones) {
    const bool is_boned = locator.bone && *locator.bone < bones.size();
    if (!is_boned) return anim::Transform{.position = locator.offset, .orientation = locator.rotation};
    const anim::Transform& bone = bones[*locator.bone];
    const ogre::Quat turned = ogre::quat_multiply(bone.orientation, locator.rotation);
    const ogre::Quat along = locator.is_translate_first ? bone.orientation : turned;
    const ogre::Vec3 step = ogre::quat_rotate(along, locator.offset);
    return anim::Transform{.position = ogre::add_vec3(bone.position, step), .orientation = turned};
}

anim::Transform slot_pose(const Locator& locator, std::span<const anim::Transform> bones, ogre::Vec3 scale) {
    const anim::Transform point = locator_pose(locator, bones);
    const anim::Transform child{.position = {}, .orientation = {}, .scale = scale};
    return anim::from_parent(point, child);
}

} // namespace game::avatar
