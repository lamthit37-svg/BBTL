#pragma once
// Đặt locator và mẫu con trong khe của mẫu nhân vật theo xương của tư thế đang vẽ, như
// LogicModel::_updateLocatorPos, _createLocatorSceneNode và _createModelInSlot của client ref cùng
// Node::translate, Node::rotate, Node::_updateFromParent của OGRE. Ghép bằng quaternion (from_parent)
// rồi mới ra ma trận, không nhân ma trận từng bước, nên locator có trục lạ (quaternion không đơn vị,
// vì FromAngleAxis không chuẩn hoá trục) ra đúng như ref. Logic thuần, không I/O.
// Nguồn: TLBB Dev src/client_app/locator.hpp@e0d89a6. Khác gốc: namespace game::avatar; locator dựng
// từ hàng bảng của look (tên xương tra thành handle của skeleton chính).

#include "anim/asset.hpp"
#include "anim/rig.hpp"
#include "look/weapon.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <cstddef>
#include <optional>
#include <span>

namespace game::avatar {

// Locator của mẫu nhân vật đã đổi sang kiểu của anim: xương theo handle của skeleton chính.
struct Locator {
    // Không có khi locator không theo xương (tên rỗng) hay skeleton chính không có xương đó: ref ghi
    // log rồi bỏ qua, nút giữ trạng thái lúc tạo.
    std::optional<std::size_t> bone;
    ogre::Vec3 offset;
    ogre::Quat rotation;
    bool is_translate_first = false;
};

// Dựng từ hàng bảng: tên xương thành handle, trục và góc thành quaternion (Quaternion::FromAngleAxis).
[[nodiscard]] Locator make_locator(const look::LocatorRow& row, const anim::SourceSkeleton& skeleton);

// Nút locator so với nút mẫu. bones là biến đổi derived của skeleton mẫu theo handle ở khung này
// (Rig::skin ra cùng ma trận skin). Có xương thì lấy vị trí, hướng của xương (không lấy scale) rồi áp
// offset và rotation trong hệ cục bộ theo thứ tự translate_first. Không xương (hay handle ngoài bones)
// thì nút giữ trạng thái lúc tạo: vị trí offset, hướng rotation. Scale luôn là 1.
[[nodiscard]] anim::Transform locator_pose(const Locator& locator, std::span<const anim::Transform> bones);

// Nút của mẫu con trong khe của locator, so với nút mẫu: nút mẫu con là con của nút locator với vị trí
// 0, hướng đơn vị và scale riêng scale (thuộc tính Scale của mẫu con).
[[nodiscard]] anim::Transform slot_pose(const Locator& locator, std::span<const anim::Transform> bones,
    ogre::Vec3 scale);

} // namespace game::avatar
