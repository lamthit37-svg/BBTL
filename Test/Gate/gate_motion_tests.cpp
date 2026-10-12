// Gate làm chủ vị trí: bước chưa có mốc bị từ chối, bước hợp lệ được nhận, bước không hợp lệ bị kéo
// về mốc, vi phạm lặp lại thì đóng phiên. Đồng hồ là đồng hồ máy chủ (now_ns), không lấy từ client.
#include "gate/motion.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <limits>

namespace game::test {
namespace {

using gate::Motion;
using gate::MotionAct;
using gate::kMotionTickNs;

[[nodiscard]] std::int64_t at_tick(std::int64_t tick) { return tick * kMotionTickNs; }

[[nodiscard]] protocol::Move step(float x, std::uint32_t tick) {
    return protocol::Move{.x_cm = x, .z_cm = 0, .tick = tick};
}

void server_tick_follows_server_clock(Context& context) {
    context.expect(gate::motion_tick(0) == 0, "tick 0 lúc 0");
    context.expect(gate::motion_tick(at_tick(30)) == 30, "30 tick sau một giây");
    context.expect(gate::motion_tick(-5) == 0, "đồng hồ âm không tạo tick");
}

void move_before_placement_is_out_of_order(Context& context) {
    Motion motion;
    context.expect(motion.judge(step(0, 0), 0).act == MotionAct::kOutOfOrder, "chưa có mốc thì không nhận bước");
}

void place_sends_server_anchor(Context& context) {
    Motion motion;
    const protocol::Position sent = motion.place({.x_cm = 100, .z_cm = 200}, at_tick(10));
    context.expect(sent.x_cm == 100 && sent.z_cm == 200 && sent.tick == 0, "mốc do máy chủ đặt, tick client từ 0");
    context.expect(motion.placed(), "đã có mốc");
}

void legal_small_steps_are_accepted(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    context.expect(motion.judge(step(10, 1), at_tick(1)).act == MotionAct::kAccept, "bước nhỏ tick 1");
    context.expect(motion.judge(step(20, 2), at_tick(2)).act == MotionAct::kAccept, "bước nhỏ tick 2");
    context.expect(motion.anchor().x_cm == 20, "mốc theo bước đã nhận");
}

void non_finite_is_rejected(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const float inf = std::numeric_limits<float>::infinity();
    const auto first = motion.judge(step(nan, 1), at_tick(1));
    context.expect(first.act != MotionAct::kAccept, "NaN không được nhận");
    context.expect(first.act != MotionAct::kCorrect || first.position.x_cm == 0, "kéo về mốc cũ");
    context.expect(motion.judge(step(inf, 2), at_tick(2)).act != MotionAct::kAccept, "vô cực không được nhận");
    context.expect(motion.anchor().x_cm == 0, "mốc giữ nguyên");
}

void overspeed_is_corrected_then_kicked(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    const auto first = motion.judge(step(1000, 1), at_tick(1));
    context.expect(first.act == MotionAct::kCorrect, "vượt giới hạn Pace lần đầu: kéo về");
    context.expect(first.position.x_cm == 0, "kéo về đúng mốc");
    bool kicked = false;
    for (std::uint32_t tick = 2; tick < 12 && !kicked; ++tick) {
        kicked = motion.judge(step(1000, tick), at_tick(tick)).act == MotionAct::kKick;
    }
    context.expect(kicked, "vi phạm lặp lại thì đóng phiên");
}

void rewound_tick_is_rejected(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    context.expect(motion.judge(step(10, 5), at_tick(5)).act == MotionAct::kAccept, "bước hợp lệ");
    const auto back = motion.judge(step(12, 3), at_tick(6));
    context.expect(back.act == MotionAct::kCorrect, "tick lùi không được nhận");
    context.expect(back.position.x_cm == 10 && back.position.tick == 5, "kéo về bước nhận gần nhất");
}

void client_tick_ahead_of_server_is_capped(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    context.expect(motion.judge(step(2000, 900), at_tick(1)).act != MotionAct::kAccept, "đo theo đồng hồ máy chủ");
    context.expect(motion.anchor().x_cm == 0, "mốc giữ nguyên");
}

void clear_drops_anchor(Context& context) {
    Motion motion;
    (void)motion.place({.x_cm = 0, .z_cm = 0}, at_tick(0));
    motion.clear();
    context.expect(motion.judge(step(1, 1), at_tick(1)).act == MotionAct::kOutOfOrder, "rời game thì bỏ mốc");
}

const std::array kCases{
    Case{.name = "server_tick_follows_server_clock", .body = &server_tick_follows_server_clock},
    Case{.name = "move_before_placement_is_out_of_order", .body = &move_before_placement_is_out_of_order},
    Case{.name = "place_sends_server_anchor", .body = &place_sends_server_anchor},
    Case{.name = "legal_small_steps_are_accepted", .body = &legal_small_steps_are_accepted},
    Case{.name = "non_finite_is_rejected", .body = &non_finite_is_rejected},
    Case{.name = "overspeed_is_corrected_then_kicked", .body = &overspeed_is_corrected_then_kicked},
    Case{.name = "rewound_tick_is_rejected", .body = &rewound_tick_is_rejected},
    Case{.name = "client_tick_ahead_of_server_is_capped", .body = &client_tick_ahead_of_server_is_capped},
    Case{.name = "clear_drops_anchor", .body = &clear_drops_anchor},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}