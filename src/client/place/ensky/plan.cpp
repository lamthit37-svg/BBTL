/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/plan.cpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt plan.hpp. Khoảng cách xếp hàng là bình phương khoảng cách từ nút
 *    tới camera (Node::getSquaredViewDepth của Ogre): mây ở ngay camera nên 0,
 *    mây vòng ở độ cao CloudHeight, trăng và mặt trời ở xa 9000.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ensky/plan.hpp"

#include "ensky/scene.hpp"

#include <algorithm>
#include <numbers>
#include <span>

namespace game::ensky {
namespace {

constexpr float kPi = std::numbers::pi_v<float>;
constexpr ogre::Vec3 kUnitY{.x = 0.0F, .y = 1.0F, .z = 0.0F};
constexpr ogre::Vec3 kUnitZ{.x = 0.0F, .y = 0.0F, .z = 1.0F};
// Nút con của mặt trời lệch hơn trăng 3 đơn vị (0, 0, +9003 so với 0, 0, -9000).
constexpr float kSunDistance = 9003.0F;

[[nodiscard]] bool is_visible(float alpha) noexcept {
    return static_cast<double>(alpha) > kMinAlpha;
}

[[nodiscard]] Draw cloud_draw(const CloudLayer& layer, std::size_t index) {
    Draw draw;
    draw.kind = Kind::kCloud;
    draw.index = index;
    draw.priority = kCloudPriority + layer.layer;
    draw.orientation = cloud_orientation(layer);
    return draw;
}

[[nodiscard]] Draw ring_draw(const RingLive& live, const RingLayer& layer, std::size_t index) {
    Draw draw;
    draw.kind = Kind::kRing;
    draw.index = index;
    draw.priority = kRingPriority + layer.layer;
    draw.distance_squared = layer.height * layer.height;
    draw.orientation = live.orientation;
    draw.offset = ogre::Vec3{.x = 0.0F, .y = layer.height, .z = 0.0F};
    draw.scale = ogre::Vec3{.x = 1.0F, .y = layer.scale, .z = 1.0F};
    return draw;
}

[[nodiscard]] Draw body_draw(Kind kind, const Pose& pose, float scale, int layer) {
    const float distance = kind == Kind::kSun ? kSunDistance : kBodyDistance;
    Draw draw;
    draw.kind = kind;
    draw.priority = kBodyPriority + layer;
    draw.distance_squared = distance * distance;
    draw.orientation = pose.orientation;
    draw.offset = ogre::scale_vec3(pose.toward, distance);
    draw.scale = ogre::Vec3{.x = scale, .y = scale, .z = scale};
    return draw;
}

void add_clouds(const Playback& playback, std::vector<Draw>& draws) {
    const std::span<const CloudLayer> layers = playback.sky().clouds;
    const std::span<const CloudLive> live = playback.clouds();
    for (std::size_t index = 0; index < layers.size(); ++index) {
        if (!is_visible(live[index].alpha)) continue;
        draws.push_back(cloud_draw(layers[index], index));
    }
}

void add_rings(const Playback& playback, std::vector<Draw>& draws) {
    const std::span<const RingLayer> layers = playback.sky().rings;
    const std::span<const RingLive> live = playback.rings();
    for (std::size_t index = 0; index < layers.size(); ++index) {
        if (!is_visible(live[index].alpha)) continue;
        draws.push_back(ring_draw(live[index], layers[index], index));
    }
}

void add_bodies(const Playback& playback, std::vector<Draw>& draws) {
    const Moon& moon = playback.sky().moon;
    const Sun& sun = playback.sky().sun;
    const Draw moon_draw = body_draw(Kind::kMoon, playback.moon(), moon.scale, moon.layer);
    const Draw sun_draw = body_draw(Kind::kSun, playback.sun(), sun.scale, sun.layer);
    if (moon.is_enabled) draws.push_back(moon_draw);
    if (sun.is_enabled) draws.push_back(sun_draw);
}

// Xa trước (bình phương khoảng cách lớn trước), hoà thì theo thứ tự tạo.
[[nodiscard]] bool drawn_before(const Draw& left, const Draw& right) noexcept {
    if (left.priority != right.priority) return left.priority < right.priority;
    if (left.distance_squared != right.distance_squared) {
        return left.distance_squared > right.distance_squared;
    }
    return left.order < right.order;
}

} // namespace

ogre::Quat cloud_orientation(const CloudLayer& layer) {
    const ogre::Quat identity{};
    const ogre::Quat yaw = ogre::quat_normalize(ogre::quat_from_angle_axis(layer.yaw, kUnitY));
    const ogre::Quat turned = ogre::quat_multiply(identity, yaw);
    if (!layer.is_flipped) return turned;
    const ogre::Quat roll = ogre::quat_normalize(ogre::quat_from_angle_axis(kPi, kUnitZ));
    return ogre::quat_multiply(turned, roll);
}

std::vector<Draw> plan_of(const Playback& playback) {
    std::vector<Draw> draws;
    add_clouds(playback, draws);
    add_rings(playback, draws);
    add_bodies(playback, draws);
    for (std::size_t index = 0; index < draws.size(); ++index) {
        draws[index].order = static_cast<std::uint32_t>(index);
    }
    std::ranges::stable_sort(draws, drawn_before);
    return draws;
}

} // namespace game::ensky
