/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/control/view_ray.cpp
 *  PHÂN HỆ   : Figure / Control / View Ray
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tia từ màn hình và chọn điểm đất; luật ở view_ray.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "control/view_ray.hpp"

#include "control/ground.hpp"
#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
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

// Cùng cơ sở right, screen_up của screen_ray: chiếu vectơ từ mắt tới điểm lên ba trục rồi chia cho độ sâu và nửa mặt gần.
std::optional<ScreenPoint> project_point(const Lens& lens, const ogre::Vec3& point) {
    constexpr float kNearest = 1.0e-3F;
    const ogre::Vec3 world_up{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    const ogre::Vec3 right = ogre::normalize_vec3(ogre::cross_vec3(lens.forward, world_up));
    const ogre::Vec3 screen_up = ogre::cross_vec3(right, lens.forward);
    const ogre::Vec3 offset = ogre::sub_vec3(point, lens.eye);
    const float depth = ogre::dot_vec3(offset, lens.forward);
    const float half_height = std::tan(lens.fov_y * 0.5F);
    const float half_width = half_height * lens.aspect;
    if (!(depth > kNearest) || !(half_height > 0.0F) || !(half_width > 0.0F)) return std::nullopt;
    const float across_x = ogre::dot_vec3(offset, right) / (depth * half_width);
    const float across_y = ogre::dot_vec3(offset, screen_up) / (depth * half_height);
    if (!std::isfinite(across_x) || !std::isfinite(across_y)) return std::nullopt;
    return ScreenPoint{.x = (across_x + 1.0F) * 0.5F, .y = (1.0F - across_y) * 0.5F};
}

namespace {

// Đoạn [near, far] của tia trong tấm giữa hai mặt phẳng song song của một trục; tia song song tấm thì chỉ cần gốc nằm trong tấm.
struct Slab {
    float near_t = 0.0F;
    float far_t = std::numeric_limits<float>::infinity();
    bool is_empty = false;

    void clip(float origin, float direction, float low, float high) noexcept {
        if (direction == 0.0F) {
            is_empty = is_empty || origin < low || origin > high;
            return;
        }
        const float first = (low - origin) / direction;
        const float second = (high - origin) / direction;
        near_t = std::max(near_t, std::min(first, second));
        far_t = std::min(far_t, std::max(first, second));
        is_empty = is_empty || near_t > far_t;
    }
};

} // namespace

std::optional<float> ray_box_distance(const Ray& ray, const ogre::Vec3& low, const ogre::Vec3& high) noexcept {
    Slab slab;
    slab.clip(ray.origin.x, ray.direction.x, low.x, high.x);
    slab.clip(ray.origin.y, ray.direction.y, low.y, high.y);
    slab.clip(ray.origin.z, ray.direction.z, low.z, high.z);
    if (slab.is_empty) return std::nullopt;
    return slab.near_t;
}

std::optional<core::GroundPoint> pick_ground(const Ground& ground, const Lens& lens, ScreenPoint point) {
    const Ray ray = screen_ray(lens, point);
    const std::optional<ogre::Vec3> hit = ground.intersect(ray);
    if (!hit) return std::nullopt;
    return ground.to_game(*hit);
}

} // namespace game::control
