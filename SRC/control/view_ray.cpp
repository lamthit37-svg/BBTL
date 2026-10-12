// Tia từ màn hình và chọn điểm đất; luật ở view_ray.hpp.
#include "control/view_ray.hpp"

#include "control/ground.hpp"
#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"

#include <cmath>
#include <optional>

namespace game::control {

// getCameraToViewportRay: x = 2x - 1, y = 1 - 2y trên mặt gần cách mắt một đơn vị; nửa rộng của
// mặt đó là tan(fov_y / 2) nhân tỉ lệ khung, nửa cao là tan(fov_y / 2).
Ray screen_ray(const Lens& lens, ScreenPoint point) {
    const float across_x = (2.0F * point.x) - 1.0F;
    const float across_y = 1.0F - (2.0F * point.y);
    const float half_height = std::tan(lens.fov_y * 0.5F);
    const float half_width = half_height * lens.aspect;
    const ogre::Vec3 world_up{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    const ogre::Vec3 right = ogre::normalize_vec3(ogre::cross_vec3(lens.forward, world_up));
    const ogre::Vec3 screen_up = ogre::cross_vec3(right, lens.forward);
    const ogre::Vec3 across = ogre::scale_vec3(right, across_x * half_width);
    const ogre::Vec3 rise = ogre::scale_vec3(screen_up, across_y * half_height);
    const ogre::Vec3 through = ogre::add_vec3(ogre::add_vec3(lens.forward, across), rise);
    return Ray{.origin = lens.eye, .direction = ogre::normalize_vec3(through)};
}

std::optional<core::GroundPoint> pick_ground(const Ground& ground, const Lens& lens, ScreenPoint point) {
    const Ray ray = screen_ray(lens, point);
    const std::optional<ogre::Vec3> hit = ground.intersect(ray);
    if (!hit) return std::nullopt;
    return ground.to_game(*hit);
}

} // namespace game::control
