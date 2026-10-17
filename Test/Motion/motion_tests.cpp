/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Motion/motion_tests.cpp
 *  PHÂN HỆ   : Motion / Motion Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm luật đi dọc đường: khoảng cách, chiều dài đường, vị trí giữa đoạn,
 *    qua góc, vượt điểm cuối, và các ca biên (tốc độ không dương, đường rỗng,
 *    đoạn dài 0) không được sinh NaN. Nguồn: TLBB Dev
 *    tests/motion/motion_test.cpp@e0d89a6. Khác gốc: khung test của dự án
 *    (Context::expect); đường góc là hàm trả mảng thay cho biến toàn cục
 *    vector.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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
    context.expect(near_value(motion::mounted_speed(run, 0), run), "không có dòng thì giữ chạy");
    context.expect(near_value(motion::mounted_speed(run, -5), run), "phần trăm âm không cộng");
    context.expect(near_value(motion::mounted_speed(run, 10), run * 1.1F), "lục hành điêu +10%");
    context.expect(near_value(motion::mounted_speed(run, 40), run * 1.4F), "hổ +40%");
    context.expect(near_value(motion::mounted_speed(run, 80), run * 1.8F), "lạc đà +80%");
    context.expect(near_value(motion::mounted_speed(run, 125), run * 2.25F), "+125%");
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

void pet_paces(Context& context) {
    motion::PetAsk ask;
    ask.owner = {};
    ask.pet = {.x = 0.0F, .z = 2.0F};
    ask.pace = motion::PetPace::kWalk;
    const motion::PetOrder near = motion::pet_follow(ask);
    context.expect(near.pace == motion::PetPace::kWalk && !near.go && !near.warp, "trong 3 m, đang đi bộ thì đứng");
    ask.pet = {.x = 0.0F, .z = 3.0F};
    const motion::PetOrder edge = motion::pet_follow(ask);
    context.expect(edge.pace == motion::PetPace::kWalk && edge.go && !edge.warp, "đúng 3 m vẫn đi bộ và bắt đầu đi");
    ask.pet = {.x = 0.0F, .z = 5.0F};
    const motion::PetOrder run = motion::pet_follow(ask);
    const bool runs = run.pace == motion::PetPace::kRun && run.go;
    const GroundPoint side{.x = -2.0F, .z = 0.0F};
    context.expect(runs && near_point(run.at, side), "5 m, hướng 0 chạy tới điểm lệch −x");
    ask.owner_facing = 1.5707963F;
    const motion::PetOrder front = motion::pet_follow(ask);
    const bool front_runs = front.pace == motion::PetPace::kRun && front.go;
    const GroundPoint nose{.x = 0.0F, .z = 2.0F};
    context.expect(front_runs && near_point(front.at, nose), "hướng pi/2 thì điểm đi lệch +z");
    ask.owner_facing = 0.0F;
    ask.pace = motion::PetPace::kSprint;
    const motion::PetOrder held = motion::pet_follow(ask);
    context.expect(held.pace == motion::PetPace::kSprint, "dưới 8 m vẫn giữ nước rút");
    ask.pace = motion::PetPace::kWalk;
    ask.pet = {.x = 0.0F, .z = 8.0F};
    const motion::PetOrder eight = motion::pet_follow(ask);
    context.expect(eight.pace == motion::PetPace::kRun, "đúng 8 m thì chạy, chưa nước rút");
    ask.pet = {.x = 0.0F, .z = 10.0F};
    const motion::PetOrder sprint = motion::pet_follow(ask);
    context.expect(sprint.pace == motion::PetPace::kSprint && sprint.go, "10 m thì nước rút");
    ask.pet = {.x = 0.0F, .z = 15.0F};
    const motion::PetOrder fifteen = motion::pet_follow(ask);
    context.expect(fifteen.pace == motion::PetPace::kSprint && !fifteen.warp, "đúng 15 m chưa dịch");
    ask.pet = {.x = 0.0F, .z = 16.0F};
    ask.owner_facing = 0.0F;
    const motion::PetOrder warped = motion::pet_follow(ask);
    context.expect(warped.warp && warped.pace == motion::PetPace::kWalk && !warped.go, "quá 15 m thì dịch và về đi bộ");
    context.expect(near_point(warped.at, {.x = -2.0F, .z = 0.0F}), "hướng 0 đáp lệch 2 m về −x");
    ask.can_move = false;
    const motion::PetOrder stuck = motion::pet_follow(ask);
    context.expect(!stuck.warp && stuck.go && stuck.pace == motion::PetPace::kWalk, "không đi được thì không dịch");
    ask.can_move = true;
    ask.moving = true;
    ask.pet = {.x = 0.0F, .z = 5.0F};
    ask.pace = motion::PetPace::kRun;
    const motion::PetOrder going = motion::pet_follow(ask);
    context.expect(!going.go && going.pace == motion::PetPace::kRun, "đang đi thì không gọi đi thêm");
    context.expect(near_point(going.at, side), "đang đi vẫn nhằm điểm Baby_Go");
    ask.moving = false;
    ask.pace = motion::PetPace::kRun;
    ask.pet = {.x = 1.0F, .z = 1.0F};
    const motion::PetOrder home = motion::pet_follow(ask);
    context.expect(home.pace == motion::PetPace::kHobble, "vào trong 3 m từ chạy thì khập khiễng");
    ask.has_map = true;
    ask.limit = {.width = 1.0F, .depth = 1.0F};
    ask.pet = {.x = 0.0F, .z = 20.0F};
    ask.pace = motion::PetPace::kWalk;
    const motion::PetOrder boxed = motion::pet_follow(ask);
    context.expect(boxed.warp && near_point(boxed.at, {.x = 0.0F, .z = 0.0F}), "điểm đáp ngoài map bị kéo vào");
}

void pet_speeds(Context& context) {
    context.expect(near_value(motion::pet_speed(2.0F, motion::PetPace::kWalk), 2.0F), "đi bộ giữ gốc");
    context.expect(near_value(motion::pet_speed(2.0F, motion::PetPace::kHobble), 1.0F), "khập khiễng một nửa");
    context.expect(near_value(motion::pet_speed(2.0F, motion::PetPace::kRun), 3.0F), "chạy 1.5");
    context.expect(near_value(motion::pet_speed(2.0F, motion::PetPace::kSprint), 10.0F), "nước rút 5");
    context.expect(near_value(motion::pet_speed(0.0F, motion::PetPace::kRun), 0.0F), "gốc 0 thì không bước");
    context.expect(near_value(motion::pet_speed(-1.0F, motion::PetPace::kSprint), 0.0F), "gốc âm thì 0");
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
    Case{.name = "pet_paces", .body = &pet_paces},
    Case{.name = "pet_speeds", .body = &pet_speeds},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "motion_tests: mọi ca phải qua");
    return 0;
}
