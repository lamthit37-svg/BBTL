// Thứ nằm dưới chuột, như Find_HitWXObject: tia phải chạm hộp lưới, và nếu có hộp ngoài thì
// phải chạm cả hộp đó. Trong mỗi lớp giữ thứ gần mắt nhất; lớp số nhỏ nhất thắng (NPC và quái 3,
// người chơi khác 5, mình 6, thú 7).
// Nguồn: TLBB Dev src/control/hover.hpp và hover.cpp. Khác gốc: namespace game::control; hộp
// biến đổi nhận BoxFrame (ba trục và gốc) thay cho Mat4 SIMD, cùng phép nhân hàng.
#pragma once

#include "control/cursor_rules.hpp"
#include "control/ground.hpp"
#include "ogre/vec3.hpp"

#include <cstddef>
#include <optional>
#include <span>
#include <vector>

namespace game::control {

struct Box {
    ogre::Vec3 min{};
    ogre::Vec3 max{};
};

// Ba trục của biến đổi affine và gốc, như ba cột đầu và cột tịnh tiến của ma trận.
struct BoxFrame {
    ogre::Vec3 axis_x{.x = 1.0F};
    ogre::Vec3 axis_y{.y = 1.0F};
    ogre::Vec3 axis_z{.z = 1.0F};
    ogre::Vec3 origin{};
};

struct Pickable {
    std::vector<Box> meshes;
    std::optional<Box> external;
    HoverKind kind = HoverKind::kNpc;
};

// 0 khi gốc tia nằm trong hộp; nullopt khi không chạm hoặc hộp nằm sau gốc.
[[nodiscard]] std::optional<float> ray_box(const Ray& ray, const Box& box);

// Hộp thẳng trục bao tám góc của box sau frame.
[[nodiscard]] Box transform_box(const Box& box, const BoxFrame& frame);

// Hộp cục bộ của BoundingBox "x y z": từ (-x/2, 0, -z/2) tới (x/2, y, z/2).
[[nodiscard]] Box external_box(ogre::Vec3 size) noexcept;

// Chỉ số thứ được chọn; nullopt khi tia không chạm gì.
[[nodiscard]] std::optional<std::size_t> pick_hover(const Ray& ray, std::span<const Pickable> items);

} // namespace game::control
