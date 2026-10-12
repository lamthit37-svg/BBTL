// Kiểm luật đi dọc đường: khoảng cách, chiều dài đường, vị trí giữa đoạn, qua góc, vượt điểm cuối,
// và các ca biên (tốc độ không dương, đường rỗng, đoạn dài 0) không được sinh NaN.
// Nguồn: TLBB Dev tests/motion/motion_test.cpp@e0d89a6. Khác gốc: khung test của dự án
// (Context::expect); đường góc là hàm trả mảng thay cho biến toàn cục vector.
#include "core/check.hpp"
#include "core/ground_point.hpp"
#include "motion/motion.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <span>

namespace game::test {
namespace {

using core::GroundPoint;
using motion::Progress;
using motion::Seconds;

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-4F;
}

[[nodiscard]] bool near_point(GroundPoint left, GroundPoint right) {
    return near_value(left.x, right.x) && near_value(left.z, right.z);
}

// Đường có một góc: từ gốc tới (3, 4) dài 5, rồi tới (3, 10) dài 6.
[[nodiscard]] std::array<GroundPoint, 2> corner_path() {
    return {GroundPoint{.x = 3.0F, .z = 4.0F}, GroundPoint{.x = 3.0F, .z = 10.0F}};
}

void measures(Context& context) {
    const GroundPoint origin{};
    const std::array<GroundPoint, 2> corner = corner_path();
    context.expect(near_value(motion::distance(origin, corner[0]), 5.0F), "tam giác 3-4-5");
    context.expect(near_value(motion::path_length(origin, corner), 11.0F), "5 cộng 6");
    context.expect(near_value(motion::path_length(origin, {}), 0.0F), "đường rỗng dài 0");
}

void mid_segment(Context& context) {
    const std::array<GroundPoint, 1> path{GroundPoint{.x = 10.0F, .z = 0.0F}};
    const Progress step = motion::advance({}, path, 2.0F, Seconds{2.5F});
    context.expect(near_point(step.position, {.x = 5.0F, .z = 0.0F}), "đi 5 trên đoạn dài 10");
    context.expect(step.next == 0 && !step.arrived, "vẫn đang đi tới điểm đầu");
}

void corners(Context& context) {
    const std::array<GroundPoint, 2> corner = corner_path();
    const Progress turned = motion::advance({}, corner, 1.0F, Seconds{8.0F});
    context.expect(near_point(turned.position, {.x = 3.0F, .z = 7.0F}), "qua góc rồi đi thêm 3");
    context.expect(turned.next == 1 && !turned.arrived, "đang ở đoạn thứ hai");
    const Progress exact = motion::advance({}, corner, 1.0F, Seconds{5.0F});
    context.expect(near_point(exact.position, corner[0]), "vừa đúng điểm góc");
    context.expect(exact.next == 1 && !exact.arrived, "tới góc thì điểm kế là điểm thứ hai");
    const Progress done = motion::advance({}, corner, 1.0F, Seconds{100.0F});
    context.expect(near_point(done.position, corner[1]), "vượt quá thì dừng ở điểm cuối");
    context.expect(done.next == corner.size() && done.arrived, "đã tới nơi");
}

void edges(Context& context) {
    const std::array<GroundPoint, 2> corner = corner_path();
    const GroundPoint start{.x = 1.0F, .z = 1.0F};
    const Progress idle = motion::advance(start, corner, 0.0F, Seconds{5.0F});
    const bool is_still = near_point(idle.position, start) && idle.next == 0 && !idle.arrived;
    context.expect(is_still, "tốc độ 0 thì đứng yên");
    const Progress past = motion::advance(start, corner, 1.0F, Seconds{-1.0F});
    context.expect(near_point(past.position, start) && !past.arrived, "thời gian âm thì đứng yên");
    const Progress empty = motion::advance(start, {}, 1.0F, Seconds{1.0F});
    context.expect(near_point(empty.position, start) && empty.arrived, "đường rỗng coi như đã tới");
    const std::array<GroundPoint, 2> repeated{start, GroundPoint{.x = 4.0F, .z = 5.0F}};
    const Progress skip = motion::advance(start, repeated, 1.0F, Seconds{1.0F});
    const bool is_finite = std::isfinite(skip.position.x) && std::isfinite(skip.position.z);
    context.expect(is_finite, "đoạn dài 0 không sinh NaN");
    context.expect(near_point(skip.position, {.x = 1.6F, .z = 1.8F}), "bỏ qua đoạn dài 0 rồi đi tiếp");
}

void speeds(Context& context) {
    const float walk = motion::human_speed(motion::MoveMode::kWalk);
    const float hobble = motion::human_speed(motion::MoveMode::kHobble);
    const float run = motion::human_speed(motion::MoveMode::kRun);
    const float sprint = motion::human_speed(motion::MoveMode::kSprint);
    context.expect(near_value(walk, 2.8F), "2800 / 1000");
    context.expect(near_value(hobble, 1.4F), "đi khập khiễng còn một nửa");
    context.expect(near_value(run, 4.2F), "chạy là 1.5 lần");
    context.expect(near_value(sprint, 14.0F), "nước rút là 5 lần");
}

void faces(Context& context) {
    const GroundPoint origin{};
    const float ahead = motion::face_angle(origin, {.x = 0.0F, .z = 1.0F});
    const float right = motion::face_angle(origin, {.x = 1.0F, .z = 0.0F});
    const float left = motion::face_angle(origin, {.x = -1.0F, .z = 0.0F});
    const float back = motion::face_angle(origin, {.x = 0.0F, .z = -1.0F});
    const float diagonal = motion::face_angle(origin, {.x = 1.0F, .z = 1.0F});
    context.expect(near_value(ahead, 0.0F), "+z là góc 0");
    context.expect(near_value(right, -left), "+x và −x đối nhau");
    context.expect(right > 1.57F && right < 1.58F, "+x là nửa pi");
    context.expect(near_value(back, -left * 2.0F), "−z là pi");
    context.expect(near_value(diagonal, right / 2.0F), "chéo là pi/4");
}

void tick_steps(Context& context) {
    motion::MoveAsk ask;
    ask.here = {};
    ask.target = {.x = 10.0F, .z = 0.0F};
    ask.speed = 2.0F;
    ask.seconds = 2.5F;
    const motion::MoveStep mid = motion::move_tick(ask);
    context.expect(near_point(mid.position, {.x = 5.0F, .z = 0.0F}), "đi 5 trên đoạn dài 10");
    context.expect(mid.moved && !mid.arrived, "chưa tới đích");
    const float toward_x = motion::face_angle({}, {.x = 1.0F, .z = 0.0F});
    context.expect(near_value(mid.facing, toward_x), "nhìn về +x");
    ask.seconds = 0.004F;
    const motion::MoveStep tiny = motion::move_tick(ask);
    context.expect(!tiny.moved && near_point(tiny.position, {}), "quãng dưới 0.01 thì đứng");
    ask.seconds = 1.0F;
    ask.target = {.x = 0.005F, .z = 0.0F};
    const motion::MoveStep close = motion::move_tick(ask);
    context.expect(close.arrived && !close.moved, "cách đích dưới 0.01 thì dừng tại chỗ");
    ask.target = {.x = 3.0F, .z = 0.0F};
    ask.speed = 5.0F;
    const motion::MoveStep over = motion::move_tick(ask);
    context.expect(over.arrived && over.moved, "vượt đoạn thì đứng đúng đích");
    context.expect(near_point(over.position, ask.target), "đích là (3, 0)");
    ask.speed = 2.0F;
    ask.seconds = 5.0F;
    ask.target = {.x = 10.0F, .z = 0.0F};
    const motion::MoveStep exact = motion::move_tick(ask);
    context.expect(exact.moved && !exact.arrived, "quãng đúng bằng đoạn thì chưa coi là tới");
    context.expect(near_point(exact.position, ask.target), "vẫn đứng trên đích");
}

void stays_inside(Context& context) {
    const motion::MapLimit limit{.width = 10.0F, .depth = 8.0F};
    const GroundPoint west = motion::verify_pos({.x = -1.0F, .z = 5.0F}, limit);
    const GroundPoint corner = motion::verify_pos({.x = 10.5F, .z = -2.0F}, limit);
    const GroundPoint inside = motion::verify_pos({.x = 3.0F, .z = 3.0F}, limit);
    context.expect(near_point(west, {.x = 0.0F, .z = 5.0F}), "âm thì về 0");
    context.expect(near_point(corner, {.x = 9.9F, .z = 0.0F}), "quá cạnh thì lùi 0.1");
    context.expect(near_point(inside, {.x = 3.0F, .z = 3.0F}), "trong map thì giữ nguyên");
}

constexpr std::array kCases{
    Case{.name = "measures", .body = &measures},
    Case{.name = "mid_segment", .body = &mid_segment},
    Case{.name = "corners", .body = &corners},
    Case{.name = "edges", .body = &edges},
    Case{.name = "speeds", .body = &speeds},
    Case{.name = "faces", .body = &faces},
    Case{.name = "tick_steps", .body = &tick_steps},
    Case{.name = "stays_inside", .body = &stays_inside},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "motion_tests: mọi ca phải qua");
    return 0;
}
