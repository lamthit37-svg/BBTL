// Mặt đất của cảnh: độ cao, tia chạm đất; luật và nguồn ở ground.hpp.
#include "control/ground.hpp"

#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <limits>
#include <optional>
#include <utility>
#include <vector>

namespace game::control {
namespace {

using ogre::Vec3;

// std::numeric_limits<Real>::epsilon() của OgreMath.cpp, Real là float.
constexpr float kEpsilon = std::numeric_limits<float>::epsilon();
// Dung sai của phép kiểm điểm trong tam giác, EPSILON = 1e-3f trong Math::intersects.
constexpr float kTriangleTolerance = 1e-3F;

// Góc của một ô theo Corner của TerrainData.h: 0 trái trên (x, z), 1 phải trên (x + 1, z), 2 trái
// dưới (x, z + 1), 3 phải dưới (x + 1, z + 1). Hai dòng là msConnerMap: mặc định và khi lật.
constexpr std::array<std::array<std::size_t, 4>, 2> kCorners = {{{0, 1, 2, 3}, {2, 0, 3, 1}}};

[[nodiscard]] float axis(Vec3 value, int index) {
    const std::array<float, 3> parts = {value.x, value.y, value.z};
    return parts.at(static_cast<std::size_t>(index));
}

[[nodiscard]] bool is_finite(Vec3 value) {
    return std::isfinite(value.x) && std::isfinite(value.y) && std::isfinite(value.z);
}

[[nodiscard]] int floor_int(float value) {
    return static_cast<int>(std::floor(value));
}

using Box = Ground::Box;

// Bốn ô chung nhau một đỉnh lưới, tính theo độ lệch so với đỉnh đó, như getJunction của ref.
constexpr std::array<GridCell, 4> kAround{{
    {.column = -1, .row = -1},
    {.column = -1, .row = 0},
    {.column = 0, .row = -1},
    {.column = 0, .row = 0},
}};

// Math::intersects(sphere, box): chỉ loại khi quả cầu nằm hẳn ngoài một mặt của hộp.
[[nodiscard]] bool sphere_touches(Vec3 center, float radius, const Box& box) {
    const bool is_apart_x = box.low.x - center.x > radius || center.x - box.high.x > radius;
    const bool is_apart_y = box.low.y - center.y > radius || center.y - box.high.y > radius;
    const bool is_apart_z = box.low.z - center.z > radius || center.z - box.high.z > radius;
    return !(is_apart_x || is_apart_y || is_apart_z);
}

// Thêm hộp của một ô vào danh sách nếu ô ấy có trong map.
void append_box(std::vector<Box>& boxes, const std::optional<Box>& box) {
    if (box) boxes.push_back(*box);
}

// Tia với hộp

// Thứ tự trục theo độ lớn thành phần hướng, trục lớn nhất xét trước để ít sai số, như OgreMath.cpp.
struct AxisOrder {
    int largest = 0;
    int middle = 1;
    int smallest = 2;
};

[[nodiscard]] AxisOrder order_axes(Vec3 size) {
    AxisOrder order;
    if (size.x < size.z) order = AxisOrder{.largest = 2, .middle = 1, .smallest = 0};
    const float largest = axis(size, order.largest);
    const float smallest = axis(size, order.smallest);
    const AxisOrder y_smallest{.largest = order.largest, .middle = order.smallest, .smallest = 1};
    const AxisOrder y_largest{.largest = 1, .middle = order.largest, .smallest = order.smallest};
    if (size.y < smallest) return y_smallest;
    if (size.y > largest) return y_largest;
    return order;
}

// Khoảng tham số của tia nằm trong hộp; thu hẹp theo từng trục như macro _CALC_AXIS.
struct Span {
    float start = 0.0F;
    float end = std::numeric_limits<float>::infinity();
};

[[nodiscard]] bool clip_axis(const Ray& ray, const Box& box, int index, Span& span) {
    const float denom = 1 / axis(ray.direction, index);
    float first = (axis(box.low, index) - axis(ray.origin, index)) * denom;
    float second = (axis(box.high, index) - axis(ray.origin, index)) * denom;
    if (first > second) std::swap(first, second);
    if (first > span.end || second < span.start) return false;
    span.start = std::max(span.start, first);
    span.end = std::min(span.end, second);
    return true;
}

[[nodiscard]] bool within_axis(const Ray& ray, const Box& box, int index) {
    const float origin = axis(ray.origin, index);
    return origin >= axis(box.low, index) && origin <= axis(box.high, index);
}

// Trục nhỏ nhất: song song thì chỉ kiểm gốc tia nằm trong hộp, không thì thu hẹp như hai trục kia.
[[nodiscard]] bool clip_smallest(const Ray& ray, const Box& box, int index, Span& span) {
    const float size = std::fabs(axis(ray.direction, index));
    if (size < kEpsilon) return within_axis(ray, box, index);
    return clip_axis(ray, box, index, span);
}

// Trục giữa song song với hộp: cả hai trục còn lại phải có gốc tia nằm trong hộp.
[[nodiscard]] std::optional<Span> clip_parallel(const Ray& ray, const Box& box, const AxisOrder& order,
    const Span& span) {
    const bool is_inside = within_axis(ray, box, order.middle) && within_axis(ray, box, order.smallest);
    if (!is_inside) return std::nullopt;
    return span;
}

// Math::intersects(ray, box, &d1, &d2).
[[nodiscard]] std::optional<Span> clip_box(const Ray& ray, const Box& box) {
    const Vec3 size{.x = std::fabs(ray.direction.x), .y = std::fabs(ray.direction.y), .z = std::fabs(ray.direction.z)};
    const AxisOrder order = order_axes(size);
    Span span;
    if (!clip_axis(ray, box, order.largest, span)) return std::nullopt;
    if (axis(size, order.middle) < kEpsilon) return clip_parallel(ray, box, order, span);
    if (!clip_axis(ray, box, order.middle, span)) return std::nullopt;
    if (!clip_smallest(ray, box, order.smallest, span)) return std::nullopt;
    return span;
}

// Tia với tam giác

// Hai trục của mặt chiếu lớn nhất theo pháp tuyến, để kiểm điểm trong tam giác trên mặt phẳng 2D.
[[nodiscard]] std::pair<int, int> projection_axes(Vec3 normal) {
    const float abs_x = std::fabs(normal.x);
    const float abs_y = std::fabs(normal.y);
    const float abs_z = std::fabs(normal.z);
    if (abs_y > abs_z) return abs_y > abs_x ? std::pair{0, 2} : std::pair{1, 2};
    return abs_z > abs_x ? std::pair{1, 0} : std::pair{1, 2};
}

[[nodiscard]] bool inside_triangle(const Ray& ray, float distance, const std::array<Vec3, 3>& triangle, Vec3 normal) {
    const auto [first_axis, second_axis] = projection_axes(normal);
    const Vec3 base = triangle.at(0);
    const float edge1_u = axis(triangle.at(1), first_axis) - axis(base, first_axis);
    const float edge1_v = axis(triangle.at(1), second_axis) - axis(base, second_axis);
    const float edge2_u = axis(triangle.at(2), first_axis) - axis(base, first_axis);
    const float edge2_v = axis(triangle.at(2), second_axis) - axis(base, second_axis);
    const float point_u =
        (distance * axis(ray.direction, first_axis)) + axis(ray.origin, first_axis) - axis(base, first_axis);
    const float point_v =
        (distance * axis(ray.direction, second_axis)) + axis(ray.origin, second_axis) - axis(base, second_axis);
    const float alpha = (point_u * edge2_v) - (edge2_u * point_v);
    const float beta = (edge1_u * point_v) - (point_u * edge1_v);
    const float area = (edge1_u * edge2_v) - (edge2_u * edge1_v);
    const float tolerance = -kTriangleTolerance * area;
    const bool outside_positive = alpha < tolerance || beta < tolerance || alpha + beta > area - tolerance;
    const bool outside_negative = alpha > tolerance || beta > tolerance || alpha + beta < area - tolerance;
    return area > 0 ? !outside_positive : !outside_negative;
}

// Math::intersects(ray, a, b, c, positiveSide = true, negativeSide = false): chỉ nhận tia đi ngược
// pháp tuyến, tức đi xuống mặt trên của địa hình.
[[nodiscard]] std::optional<float> intersect_triangle(const Ray& ray, const std::array<Vec3, 3>& triangle) {
    const Vec3 normal = ogre::cross_vec3(ogre::sub_vec3(triangle.at(1), triangle.at(0)),
        ogre::sub_vec3(triangle.at(2), triangle.at(0)));
    const float denom = ogre::dot_vec3(normal, ray.direction);
    if (!(denom < -kEpsilon)) return std::nullopt;
    const float distance = ogre::dot_vec3(normal, ogre::sub_vec3(triangle.at(0), ray.origin)) / denom;
    if (distance < 0) return std::nullopt;
    if (!inside_triangle(ray, distance, triangle, normal)) return std::nullopt;
    return distance;
}

// Vị trí trong một ô theo một trục: chỉ số ô và phần lẻ, kẹp về mép khi ngoài map, như getHeightAt.
struct Slot {
    int index = 0;
    float fraction = 0.0F;
};

// Một trục của lưới: khoảng thế giới của địa hình, gốc, nghịch đảo tỉ lệ và số ô.
struct GridAxis {
    float low = 0.0F;
    float high = 0.0F;
    float origin = 0.0F;
    float inverse = 1.0F;
    int size = 0;
};

[[nodiscard]] Slot locate(float value, const GridAxis& along) {
    if (value <= along.low) return Slot{.index = 0, .fraction = 0.0F};
    if (value >= along.high) return Slot{.index = along.size - 1, .fraction = 1.0F};
    float fraction = (value - along.origin) * along.inverse;
    const int index = static_cast<int>(std::trunc(fraction));
    fraction -= static_cast<float>(index);
    if (index >= along.size) return Slot{.index = along.size - 1, .fraction = 1.0F};
    return Slot{.index = index, .fraction = fraction};
}

// Trục bước (main) của lưới là z khi along_z, không thì x; trục trượt (side) là trục còn lại.
[[nodiscard]] float main_of(Vec3 value, bool is_along_z) {
    return is_along_z ? value.z : value.x;
}

[[nodiscard]] float side_of(Vec3 value, bool is_along_z) {
    return is_along_z ? value.x : value.z;
}

} // namespace

std::optional<Ground> Ground::create(GroundShape shape) {
    const bool is_sized = shape.x_size > 0 && shape.z_size > 0;
    const bool is_scaled = shape.scale.x > 0.0F && shape.scale.y > 0.0F && shape.scale.z > 0.0F;
    if (!is_sized || !is_scaled) return std::nullopt;
    const auto columns = static_cast<std::size_t>(shape.x_size);
    const auto rows = static_cast<std::size_t>(shape.z_size);
    if (shape.heights.size() != (columns + 1) * (rows + 1)) return std::nullopt;
    if (!shape.flipped.empty() && shape.flipped.size() != columns * rows) return std::nullopt;
    Ground ground;
    ground.x_size_ = shape.x_size;
    ground.z_size_ = shape.z_size;
    ground.scale_ = shape.scale;
    ground.inverse_scale_ = Vec3{.x = 1.0F / shape.scale.x, .y = 1.0F / shape.scale.y, .z = 1.0F / shape.scale.z};
    ground.position_ = shape.position;
    const auto [lowest, highest] = std::ranges::minmax(shape.heights);
    const Vec3 position = shape.position;
    ground.box_min_ = Vec3{.x = position.x, .y = position.y + (shape.scale.y * lowest), .z = position.z};
    const float max_x = position.x + (shape.scale.x * static_cast<float>(shape.x_size));
    const float max_z = position.z + (shape.scale.z * static_cast<float>(shape.z_size));
    ground.box_max_ = Vec3{.x = max_x, .y = position.y + (shape.scale.y * highest), .z = max_z};
    ground.heights_ = std::move(shape.heights);
    ground.flipped_ = std::move(shape.flipped);
    return ground;
}

ogre::Vec3 Ground::to_world(core::GroundPoint point) const {
    const float world_x = position_.x + (point.x * scale_.x);
    const float world_z = position_.z + (point.z * scale_.z);
    return Vec3{.x = world_x, .y = height_at(world_x, world_z), .z = world_z};
}

core::GroundPoint Ground::to_game(ogre::Vec3 world) const {
    return core::GroundPoint{.x = (world.x - position_.x) / scale_.x, .z = (world.z - position_.z) / scale_.z};
}

// Nội suy trên tam giác chứa điểm, theo hướng đường chéo của ô; công thức của getHeightAt.
float Ground::height_at(float world_x, float world_z) const {
    const GridAxis along_x{
        .low = box_min_.x, .high = box_max_.x, .origin = position_.x, .inverse = inverse_scale_.x, .size = x_size_};
    const GridAxis along_z{
        .low = box_min_.z, .high = box_max_.z, .origin = position_.z, .inverse = inverse_scale_.z, .size = z_size_};
    const Slot slot_x = locate(world_x, along_x);
    const Slot slot_z = locate(world_z, along_z);
    const int column = slot_x.index;
    const int row = slot_z.index;
    const float frac_x = slot_x.fraction;
    const float frac_z = slot_z.fraction;
    const bool flipped = is_flipped({.column = column, .row = row});
    const float h00 = raw_height({.column = column + 0, .row = row + 0});
    const float h10 = raw_height({.column = column + 1, .row = row + 0});
    const float h01 = raw_height({.column = column + 0, .row = row + 1});
    const float h11 = raw_height({.column = column + 1, .row = row + 1});
    float height = 0.0F;
    if (flipped && frac_z <= frac_x) {
        height = h10 + ((h00 - h10) * (1 - frac_x)) + ((h11 - h10) * frac_z);
    } else if (flipped) {
        height = h01 + ((h00 - h01) * (1 - frac_z)) + ((h11 - h01) * frac_x);
    } else if (frac_x + frac_z <= 1) {
        height = h00 + ((h10 - h00) * frac_x) + ((h01 - h00) * frac_z);
    } else {
        height = h11 + ((h10 - h11) * (1 - frac_z)) + ((h01 - h11) * (1 - frac_x));
    }
    return position_.y + (scale_.y * height);
}

// Trường hợp riêng của getIntersects: tia thẳng đứng chỉ nhận khi đi xuống, gốc trong map và không
// nằm dưới mặt đất.
std::optional<ogre::Vec3> Ground::intersect_vertical(Ray ray) const {
    if (ray.direction.y >= 0) return std::nullopt;
    const float world_x = ray.origin.x;
    const float world_z = ray.origin.z;
    const bool is_valid =
        box_min_.x <= world_x && world_x <= box_max_.x && box_min_.z <= world_z && world_z <= box_max_.z;
    if (!is_valid) return std::nullopt;
    const float height = height_at(world_x, world_z);
    if (ray.origin.y < height) return std::nullopt;
    return Vec3{.x = world_x, .y = height, .z = world_z};
}

// getIntersects với allowOutside = false, positiveSide = true, negativeSide = false.
std::optional<ogre::Vec3> Ground::intersect(Ray ray) const {
    if (!is_finite(ray.origin) || !is_finite(ray.direction)) return std::nullopt;
    if (ray.direction.x == 0 && ray.direction.z == 0) return intersect_vertical(ray);
    const auto span = clip_box(ray, Box{.low = box_min_, .high = box_max_});
    if (!span) return std::nullopt;
    const Vec3 start = ogre::add_vec3(ray.origin, ogre::scale_vec3(ray.direction, span->start));
    const Vec3 end = ogre::add_vec3(ray.origin, ogre::scale_vec3(ray.direction, span->end));
    const auto distance = walk_grids(ray, start, end);
    if (!distance) return std::nullopt;
    const float world_x = ray.origin.x + (ray.direction.x * *distance);
    const float world_z = ray.origin.z + (ray.direction.z * *distance);
    return Vec3{.x = world_x, .y = height_at(world_x, world_z), .z = world_z};
}

float Ground::raw_height(GridCell vertex) const {
    const auto first = static_cast<std::size_t>(vertex.row) * static_cast<std::size_t>(x_size_ + 1);
    return heights_.at(first + static_cast<std::size_t>(vertex.column));
}

// _getPosition: đỉnh (x, z) của lưới trong thế giới.
ogre::Vec3 Ground::corner(int column, int row) const {
    const auto along_x = static_cast<float>(column);
    const auto along_z = static_cast<float>(row);
    const float height = raw_height({.column = column, .row = row});
    return Vec3{.x = position_.x + (scale_.x * along_x),
        .y = position_.y + (scale_.y * height),
        .z = position_.z + (scale_.z * along_z)};
}

// Ô (x, z) phải hợp lệ; không có ô thì mọi ô không lật.
bool Ground::is_flipped(GridCell cell) const {
    if (flipped_.empty()) return false;
    const auto first = static_cast<std::size_t>(cell.row) * static_cast<std::size_t>(x_size_);
    return flipped_.at(first + static_cast<std::size_t>(cell.column));
}

bool Ground::is_valid_grid(int column, int row) const {
    return 0 <= column && column < x_size_ && 0 <= row && row < z_size_;
}

// _intersectGrid: hai tam giác của ô theo thứ tự góc của msConnerMap.
std::optional<float> Ground::intersect_grid(Ray ray, int column, int row) const {
    if (!is_valid_grid(column, row)) return std::nullopt;
    const std::array<Vec3, 4> vertices = {corner(column + 0, row + 0), corner(column + 1, row + 0),
        corner(column + 0, row + 1), corner(column + 1, row + 1)};
    const bool flipped = is_flipped({.column = column, .row = row});
    const std::array<std::size_t, 4>& order = kCorners.at(flipped ? 1 : 0);
    const auto pick = [&vertices, &order](std::size_t slot) { return vertices.at(order.at(slot)); };
    const auto first = intersect_triangle(ray, {pick(1), pick(0), pick(2)});
    if (first) return first;
    return intersect_triangle(ray, {pick(1), pick(2), pick(3)});
}

// Cách duyệt lưới: bước theo trục main (z khi along_z), trượt theo trục side; hàng đầu và hàng cuối
// của vòng, dấu bước, đoạn trượt mỗi bước và làn bắt đầu.
struct March {
    bool is_along_z = false;
    int sign = 1;
    int begin = 0;
    int finish = 0;
    float side_step = 0.0F;
    float lane = 0.0F;
};

// Thông số duyệt của đoạn [start, end]; không có khi khoảng bước ngược chiều tia, thay cho assert
// của bản gốc.
std::optional<March> Ground::plan_march(Ray ray, ogre::Vec3 start, ogre::Vec3 end) const {
    const float step_x = ray.direction.x * scale_.z;
    const float step_z = ray.direction.z * scale_.x;
    March march;
    march.is_along_z = std::fabs(step_x) < std::fabs(step_z);
    const bool along_z = march.is_along_z;
    march.sign = main_of(ray.direction, along_z) > 0 ? +1 : -1;
    const float main_inverse = main_of(inverse_scale_, along_z);
    const float main_start = (main_of(start, along_z) - main_of(position_, along_z)) * main_inverse;
    const float main_end = (main_of(end, along_z) - main_of(position_, along_z)) * main_inverse;
    march.begin = floor_int(main_start) - march.sign;
    march.finish = floor_int(main_end) + march.sign;
    if ((march.finish - march.begin) * march.sign <= 0) return std::nullopt;
    const float factor = along_z ? step_x / step_z : step_z / step_x;
    march.side_step = static_cast<float>(march.sign) * factor;
    const float side_inverse = side_of(inverse_scale_, along_z);
    const float side_start = (side_of(start, along_z) - side_of(position_, along_z)) * side_inverse;
    march.lane = side_start - ((main_start - static_cast<float>(march.begin)) * factor);
    return march;
}

// Duyệt các ô mà đoạn [start, end] đi qua, bước theo trục mà tia đổi ô nhiều hơn, xét cả hai ô kề
// bên ở mỗi bước như getIntersects.
std::optional<float> Ground::walk_grids(Ray ray, ogre::Vec3 start, ogre::Vec3 end) const {
    const std::optional<March> plan = plan_march(ray, start, end);
    if (!plan) return std::nullopt;
    float lane = plan->lane;
    std::optional<float> hit;
    for (int row = plan->begin; row != plan->finish && !hit; row += plan->sign) {
        hit = intersect_step(ray, row, floor_int(lane), plan->is_along_z);
        lane += plan->side_step;
    }
    return hit;
}

// Một bước duyệt: ô trên đường tia rồi hai ô kề theo trục trượt, thứ tự 0, -1, +1 như bản gốc.
std::optional<float> Ground::intersect_step(Ray ray, int row, int lane, bool along_z) const {
    constexpr std::array<int, 3> kOffsets = {0, -1, +1};
    std::optional<float> hit;
    for (std::size_t at = 0; at < kOffsets.size() && !hit; ++at) {
        const int offset = kOffsets.at(at);
        const int cell_x = along_z ? lane + offset : row;
        const int cell_z = along_z ? row : lane + offset;
        hit = intersect_grid(ray, cell_x, cell_z);
    }
    return hit;
}

float Ground::base_scale() const noexcept {
    return std::sqrt(scale_.x * scale_.z);
}

// Hộp của một ô cho camera, như _GetInterPatch: đáy âm vô cùng, đỉnh là góc cao nhất của ô.
std::optional<Ground::Box> Ground::camera_box(int column, int row) const {
    if (!is_valid_grid(column, row)) return std::nullopt;
    const float near_left = corner(column, row).y;
    const float near_right = corner(column + 1, row).y;
    const float far_left = corner(column, row + 1).y;
    const float far_right = corner(column + 1, row + 1).y;
    const float highest = std::max({near_left, near_right, far_left, far_right});
    const float lowest = -std::numeric_limits<float>::max();
    const auto along_x = static_cast<float>(column);
    const auto along_z = static_cast<float>(row);
    const Vec3 low{.x = (along_x * scale_.x) + position_.x, .y = lowest, .z = (along_z * scale_.z) + position_.z};
    const Vec3 high{
        .x = ((along_x + 1) * scale_.x) + position_.x, .y = highest, .z = ((along_z + 1) * scale_.z) + position_.z};
    return Box{.low = low, .high = high};
}

// Hộp của các ô quanh một đỉnh lưới, theo thứ tự của kAround; ô ngoài map thì bỏ.
std::vector<Ground::Box> Ground::camera_boxes(GridCell junction) const {
    std::vector<Box> boxes;
    boxes.reserve(kAround.size());
    for (const GridCell offset : kAround) {
        append_box(boxes, camera_box(junction.column + offset.column, junction.row + offset.row));
    }
    return boxes;
}

EyeProbe Ground::probe_sphere(ogre::Vec3 center, float radius) const {
    const bool is_inside =
        box_min_.x <= center.x && center.x <= box_max_.x && box_min_.z <= center.z && center.z <= box_max_.z;
    if (!is_inside) return EyeProbe::kNoPatch;
    // getJunction: đỉnh lưới gần nhất.
    const int junction_x = floor_int(((center.x - position_.x) * inverse_scale_.x) + 0.5F);
    const int junction_z = floor_int(((center.z - position_.z) * inverse_scale_.z) + 0.5F);
    const std::vector<Box> boxes = camera_boxes({.column = junction_x, .row = junction_z});
    if (boxes.size() != 2 && boxes.size() != 4) return EyeProbe::kNoPatch;
    const auto touches = [&](const Box& box) { return sphere_touches(center, radius, box); };
    const bool is_touching = std::ranges::any_of(boxes, touches);
    return is_touching ? EyeProbe::kTouching : EyeProbe::kClear;
}

bool Ground::touches_sphere(ogre::Vec3 center, float radius) const {
    return probe_sphere(center, radius) == EyeProbe::kTouching;
}

} // namespace game::control
