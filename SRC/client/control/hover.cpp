// Vòng chọn tách consider_item để khỏi lồng if trong for. Phép so và thứ tự như Find_HitWXObject:
// lớp nhỏ nhất thắng, trong một lớp lấy khoảng cách nhỏ nhất.
#include "control/hover.hpp"

#include "control/cursor_rules.hpp"
#include "control/ground.hpp"
#include "ogre/vec3.hpp"

#include <cmath>
#include <cstddef>
#include <map>
#include <optional>
#include <span>

namespace game::control {
namespace {

[[nodiscard]] float axis_of(ogre::Vec3 value, int index) noexcept {
    if (index == 0) return value.x;
    return index == 1 ? value.y : value.z;
}

[[nodiscard]] bool on_span(float value, float low, float high) noexcept {
    return value >= low && value <= high;
}

[[nodiscard]] bool face_contains(ogre::Vec3 point, const Box& box, int face) noexcept {
    const bool x_ok = face == 0 || on_span(point.x, box.min.x, box.max.x);
    const bool y_ok = face == 1 || on_span(point.y, box.min.y, box.max.y);
    const bool z_ok = face == 2 || on_span(point.z, box.min.z, box.max.z);
    return x_ok && y_ok && z_ok;
}

[[nodiscard]] ogre::Vec3 point_at(const Ray& ray, float distance) noexcept {
    return ogre::Vec3{.x = ray.origin.x + (ray.direction.x * distance),
        .y = ray.origin.y + (ray.direction.y * distance),
        .z = ray.origin.z + (ray.direction.z * distance)};
}

struct FaceQuery {
    const Ray* ray = nullptr;
    const Box* box = nullptr;
    int face = 0;
    bool is_low = false;
};

[[nodiscard]] std::optional<float> face_hit(FaceQuery query) {
    const float origin = axis_of(query.ray->origin, query.face);
    const float direction = axis_of(query.ray->direction, query.face);
    const float plane = query.is_low ? axis_of(query.box->min, query.face) : axis_of(query.box->max, query.face);
    const bool facing = query.is_low ? origin < plane && direction > 0.0F : origin > plane && direction < 0.0F;
    if (!facing) return std::nullopt;
    const float distance = (plane - origin) / direction;
    if (!(distance > 0.0F)) return std::nullopt;
    if (!face_contains(point_at(*query.ray, distance), *query.box, query.face)) return std::nullopt;
    return distance;
}

[[nodiscard]] bool inside_box(ogre::Vec3 origin, const Box& box) noexcept {
    const bool x_in = origin.x > box.min.x && origin.x < box.max.x;
    const bool y_in = origin.y > box.min.y && origin.y < box.max.y;
    const bool z_in = origin.z > box.min.z && origin.z < box.max.z;
    return x_in && y_in && z_in;
}

void keep_nearer(std::optional<float>& best, std::optional<float> distance) {
    if (!distance) return;
    if (!best || *distance < *best) best = distance;
}

[[nodiscard]] float spread_row(const BoxFrame& frame, int row, ogre::Vec3 half) noexcept {
    const float along_x = std::fabs(axis_of(frame.axis_x, row)) * half.x;
    const float along_y = std::fabs(axis_of(frame.axis_y, row)) * half.y;
    const float along_z = std::fabs(axis_of(frame.axis_z, row)) * half.z;
    return (along_x + along_y) + along_z;
}

[[nodiscard]] ogre::Vec3 moved_centre(const BoxFrame& frame, ogre::Vec3 centre) noexcept {
    const ogre::Vec3 along_x = ogre::scale_vec3(frame.axis_x, centre.x);
    const ogre::Vec3 along_y = ogre::scale_vec3(frame.axis_y, centre.y);
    const ogre::Vec3 along_z = ogre::scale_vec3(frame.axis_z, centre.z);
    return ogre::add_vec3(frame.origin, ogre::add_vec3(ogre::add_vec3(along_x, along_y), along_z));
}

[[nodiscard]] int level_of(HoverKind kind) noexcept {
    switch (kind) {
    case HoverKind::kNpc:
    case HoverKind::kMonster: return 3;
    case HoverKind::kOtherPlayer: return 5;
    case HoverKind::kMyself: return 6;
    case HoverKind::kPet: return 7;
    }
    return 3;
}

[[nodiscard]] std::optional<float> nearest_mesh(const Ray& ray, const Pickable& item) {
    std::optional<float> nearest;
    for (const Box& mesh : item.meshes)
        keep_nearer(nearest, ray_box(ray, mesh));
    return nearest;
}

[[nodiscard]] std::optional<float> item_hit(const Ray& ray, const Pickable& item) {
    const std::optional<float> nearest = nearest_mesh(ray, item);
    if (!nearest) return std::nullopt;
    const bool guarded = !item.external || ray_box(ray, *item.external).has_value();
    return guarded ? nearest : std::nullopt;
}

struct Nearest {
    std::size_t index = 0;
    float distance = 0.0F;
};

struct HoverQuery {
    std::map<int, Nearest>* by_level = nullptr;
    const Ray* ray = nullptr;
};

void note_hit(const HoverQuery& query, std::size_t index, HoverKind kind, float distance) {
    const Nearest candidate{.index = index, .distance = distance};
    const auto placed = query.by_level->try_emplace(level_of(kind), candidate);
    if (placed.second) return;
    if (distance < placed.first->second.distance) placed.first->second = candidate;
}

void consider_item(const HoverQuery& query, std::size_t index, const Pickable& item) {
    const std::optional<float> distance = item_hit(*query.ray, item);
    if (!distance) return;
    note_hit(query, index, item.kind, *distance);
}

} // namespace

std::optional<float> ray_box(const Ray& ray, const Box& box) {
    if (inside_box(ray.origin, box)) return 0.0F;
    std::optional<float> lowest;
    for (int face = 0; face < 3; ++face) {
        const FaceQuery low{.ray = &ray, .box = &box, .face = face, .is_low = true};
        const FaceQuery high{.ray = &ray, .box = &box, .face = face, .is_low = false};
        keep_nearer(lowest, face_hit(low));
        keep_nearer(lowest, face_hit(high));
    }
    return lowest;
}

Box transform_box(const Box& box, const BoxFrame& frame) {
    const ogre::Vec3 centre{
        .x = (box.min.x + box.max.x) * 0.5F, .y = (box.min.y + box.max.y) * 0.5F, .z = (box.min.z + box.max.z) * 0.5F};
    const ogre::Vec3 half{
        .x = (box.max.x - box.min.x) * 0.5F, .y = (box.max.y - box.min.y) * 0.5F, .z = (box.max.z - box.min.z) * 0.5F};
    const ogre::Vec3 moved = moved_centre(frame, centre);
    const ogre::Vec3 extent{
        .x = spread_row(frame, 0, half), .y = spread_row(frame, 1, half), .z = spread_row(frame, 2, half)};
    return Box{.min = {.x = moved.x - extent.x, .y = moved.y - extent.y, .z = moved.z - extent.z},
        .max = {.x = moved.x + extent.x, .y = moved.y + extent.y, .z = moved.z + extent.z}};
}

Box external_box(ogre::Vec3 size) noexcept {
    return Box{.min = {.x = -size.x / 2.0F, .y = 0.0F, .z = -size.z / 2.0F},
        .max = {.x = size.x / 2.0F, .y = size.y, .z = size.z / 2.0F}};
}

std::optional<std::size_t> pick_hover(const Ray& ray, std::span<const Pickable> items) {
    std::map<int, Nearest> by_level;
    const HoverQuery query{.by_level = &by_level, .ray = &ray};
    for (std::size_t index = 0; index < items.size(); ++index)
        consider_item(query, index, items[index]);
    if (by_level.empty()) return std::nullopt;
    return by_level.begin()->second.index;
}

} // namespace game::control
