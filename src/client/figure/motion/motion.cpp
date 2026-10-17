/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/motion/motion.cpp
 *  PHÂN HỆ   : Figure / Motion
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Luật đi và tốc độ. Phần trăm cưỡi nhân vào tốc độ chạy, không đổi clip.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Đi trên mặt đất. advance giữ hàm đóng của đường gãy. move_tick, human_speed, face_angle và
// verify_pos chép phép của client 2008 và server: Tick_Move, GetMoveSpeed, TDU_GetYAngle,
// VerifyPos. mounted_speed nhân tốc độ chạy với phần trăm Exterior_Ride.
// Khác gốc: else-if của tốc độ tách thành return sớm; một đích nên không có vòng sang nút kế.
#include "motion/motion.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <span>

namespace game::motion {
namespace {

// Điểm nằm trên đoạn a-b, cách a một khoảng travelled. Bên gọi bảo đảm 0 <= travelled < length.
struct Leg {
    GroundPoint start;
    GroundPoint finish;
    float length = 0.0F;
};

GroundPoint along(const Leg& leg, float travelled) {
    const float blend = travelled / leg.length;
    return {.x = leg.start.x + ((leg.finish.x - leg.start.x) * blend),
        .z = leg.start.z + ((leg.finish.z - leg.start.z) * blend)};
}

// Trạng thái của lượt đi: vị trí hiện tại, quãng còn lại và kết quả khi đã dừng giữa đường.
struct Walk {
    GroundPoint at;
    float budget = 0.0F;
    bool is_stopped = false;
    Progress stopped;
};

// Đi tiếp đoạn thứ index; dừng giữa đoạn khi quãng còn lại không đủ.
void step_leg(Walk& walk, std::span<const GroundPoint> path, std::size_t index) {
    if (walk.is_stopped) return;
    const GroundPoint next = path[index];
    const float leg = distance(walk.at, next);
    // budget còn dương nên leg > budget kéo theo leg > 0: along() không chia cho 0.
    if (walk.budget < leg) {
        const Leg inside{.start = walk.at, .finish = next, .length = leg};
        walk.stopped = {.position = along(inside, walk.budget), .next = index, .arrived = false};
        walk.is_stopped = true;
        return;
    }
    walk.budget -= leg;
    walk.at = next;
}

} // namespace

float distance(GroundPoint left, GroundPoint right) {
    return std::hypot(right.x - left.x, right.z - left.z);
}

float path_length(GroundPoint from, std::span<const GroundPoint> path) {
    float total = 0.0F;
    GroundPoint here = from;
    for (const GroundPoint& point : path) {
        total += distance(here, point);
        here = point;
    }
    return total;
}

Progress advance(GroundPoint from, std::span<const GroundPoint> path, float speed, Seconds elapsed) {
    const float budget = speed * elapsed.count();
    // Viết dạng phủ định để NaN cũng rơi vào nhánh đứng yên.
    if (!(budget > 0.0F)) return {.position = from, .next = 0, .arrived = path.empty()};
    Walk walk;
    walk.at = from;
    walk.budget = budget;
    for (std::size_t index = 0; index < path.size() && !walk.is_stopped; ++index) {
        step_leg(walk, path, index);
    }
    if (walk.is_stopped) return walk.stopped;
    return {.position = walk.at, .next = path.size(), .arrived = true};
}

namespace {

// TDU_PI và TDU_MINFLOAT. Giữ đúng chữ số của macro, không đổi sang std::numbers::pi.
// NOLINTNEXTLINE(modernize-use-std-numbers)
constexpr double kPi = 3.1415926535;
constexpr double kMinFloat = 1.0E-9;

[[nodiscard]] float half_turn(double cosine, GroundPoint start, GroundPoint toward) noexcept {
    const bool is_flat = cosine > -kMinFloat && cosine < kMinFloat;
    if (is_flat && toward.x > start.x) return static_cast<float>(kPi) / 2.0F;
    if (is_flat) return -(static_cast<float>(kPi) / 2.0F);
    const double angle = std::acos(cosine);
    if (toward.x >= start.x) return static_cast<float>(angle);
    return static_cast<float>((2 * kPi) - angle);
}

} // namespace

float human_speed(MoveMode mode) noexcept {
    const float speed = 2800.0F / 1000.0F;
    if (mode == MoveMode::kHobble) return speed * 0.5F;
    if (mode == MoveMode::kRun) return speed * 1.5F;
    if (mode == MoveMode::kSprint) return speed * 5.0F;
    return speed;
}

float mounted_speed(float run, std::int32_t percent) noexcept {
    if (percent <= 0) return run;
    const float extra = static_cast<float>(percent);
    const float scale = (100.0F + extra) / 100.0F;
    return run * scale;
}

float face_angle(GroundPoint start, GroundPoint toward) noexcept {
    const float delta_x = toward.x - start.x;
    const float delta_z = toward.z - start.z;
    const float length = std::sqrt((delta_x * delta_x) + (delta_z * delta_z));
    const auto distance = static_cast<double>(length);
    if (distance <= 0.0) return 0.0F;
    double cosine = static_cast<double>(delta_z) / distance;
    if (cosine > 1.0) cosine = 0.0;
    if (cosine < -1.0) cosine = kPi;
    return half_turn(cosine, start, toward);
}

MoveStep move_tick(MoveAsk ask) noexcept {
    MoveStep step;
    step.position = ask.here;
    const float move_dist = ask.speed * ask.seconds;
    if (move_dist < 0.01F) return step;
    const float delta_x = ask.target.x - ask.here.x;
    const float delta_z = ask.target.z - ask.here.z;
    const float dist_sq = (delta_x * delta_x) + (delta_z * delta_z);
    const float dist = std::sqrt(dist_sq);
    if (dist < 0.01F) {
        step.arrived = true;
        return step;
    }
    if (move_dist > dist) {
        step.position = ask.target;
        step.facing = face_angle(ask.here, ask.target);
        step.moved = true;
        step.arrived = true;
        return step;
    }
    const float shift_x = (move_dist * delta_x) / dist;
    const float shift_z = (move_dist * delta_z) / dist;
    step.position.x = ask.here.x + shift_x;
    step.position.z = ask.here.z + shift_z;
    step.facing = face_angle(ask.here, ask.target);
    step.moved = true;
    return step;
}

GroundPoint verify_pos(GroundPoint point, MapLimit limit) noexcept {
    point.x = std::max(point.x, 0.0F);
    point.z = std::max(point.z, 0.0F);
    // Điểm nằm giữa cạnh và cạnh trừ 0.1 phải giữ nguyên. std::min kéo luôn về cạnh trừ 0.1.
    if (point.x > limit.width) point.x = limit.width - 0.1F;
    if (point.z > limit.depth) point.z = limit.depth - 0.1F;
    return point;
}

} // namespace game::motion
