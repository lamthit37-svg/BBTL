/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Gate/gate_motion_tests.cpp
 *  PHÂN HỆ   : Gate / Gate Motion Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Gate làm chủ vị trí (H1-B): bước chưa có mốc bị từ chối, bước hợp lệ được
 *    xếp vào đường đi và máy chủ đi theo, bước hỏng bị kéo về mốc, vượt tốc
 *    không bị đóng phiên mà bị bóp. Đồng hồ là đồng hồ máy chủ (now_ns), không
 *    lấy từ client.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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

constexpr float kResyncCm = guard::kRunCmPerSec * 10.0F;
constexpr float kEpsilon = 0.01F;

[[nodiscard]] std::int64_t at_tick(std::int64_t tick) { return tick * kMotionTickNs; }

[[nodiscard]] protocol::Move step(float x, std::uint32_t tick) {
    return protocol::Move{.x_cm = x, .z_cm = 0, .tick = tick};
}

[[nodiscard]] Motion placed_at(float x) {
    Motion motion;
    static_cast<void>(motion.place({.x_cm = x, .z_cm = 0}, at_tick(0), kResyncCm));
    return motion;
}

void server_tick_follows_server_clock(Context& context) {
    context.expect(gate::motion_tick(0) == 0, "tick 0 lúc 0");
    context.expect(gate::motion_tick(at_tick(30)) == 30, "30 tick sau một giây");
    context.expect(gate::motion_tick(-5) == 0, "đồng hồ âm không tạo tick");
}

void move_before_placement_is_out_of_order(Context& context) {
    Motion motion;
    context.expect(motion.judge(step(0, 0)).act == MotionAct::kOutOfOrder, "chưa có mốc thì không nhận bước");
}

void place_sends_server_anchor(Context& context) {
    Motion motion;
    const protocol::Position sent = motion.place({.x_cm = 100, .z_cm = 200}, at_tick(10), kResyncCm);
    context.expect(sent.x_cm == 100 && sent.z_cm == 200 && sent.tick == 0, "mốc do máy chủ đặt, tick client từ 0");
    context.expect(motion.placed(), "đã có mốc");
}

void legal_steps_are_accepted_and_followed(Context& context) {
    Motion motion = placed_at(0);
    context.expect(motion.judge(step(10, 1)).act == MotionAct::kAccept, "bước nhỏ tick 1");
    const guard::Trail first = motion.chase(at_tick(1));
    context.expect(first.count > 0, "máy chủ đi và có chỗ báo zone");
    context.expect(motion.judge(step(20, 2)).act == MotionAct::kAccept, "bước nhỏ tick 2");
    static_cast<void>(motion.chase(at_tick(2)));
    context.expect(motion.anchor().x_cm == 20, "mốc theo bước đã nhận");
    context.expect(!motion.pending(), "máy chủ theo kịp");
}

void invalid_steps_are_pulled_back(Context& context) {
    Motion motion = placed_at(0);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const float inf = std::numeric_limits<float>::infinity();
    const auto first = motion.judge(step(nan, 1));
    context.expect(first.act == MotionAct::kCorrect, "NaN bị kéo về");
    context.expect(first.position.x_cm == 0, "kéo về mốc cũ");
    context.expect(motion.judge(step(inf, 2)).act == MotionAct::kCorrect, "vô cực bị kéo về");
    context.expect(motion.anchor().x_cm == 0, "mốc giữ nguyên");
}

// Vượt tốc không còn bị đóng phiên: bước được nhận, máy chủ đi theo tối đa quỹ.
void overspeed_is_clamped_not_kicked(Context& context) {
    Motion motion = placed_at(0);
    context.expect(motion.judge(step(1000, 1)).act == MotionAct::kAccept, "bước xa được nhận");
    static_cast<void>(motion.chase(at_tick(1)));
    context.expect(motion.anchor().x_cm < 20.0F, "máy chủ chỉ đi một tick quỹ");
    context.expect(motion.pending(), "phần còn lại đang chờ");
    for (std::int64_t tick = 2; tick < 100 && motion.pending(); ++tick)
        static_cast<void>(motion.chase(at_tick(tick)));
    context.expect(!motion.pending(), "hết đường chờ, không cần client gửi thêm");
    context.expect(motion.anchor().x_cm > 1000.0F - kEpsilon, "mốc tới chỗ client khai");
}

void lag_beyond_resync_is_pulled_back(Context& context) {
    Motion motion = placed_at(0);
    const auto far = motion.judge(step(kResyncCm + 100.0F, 1));
    context.expect(far.act == MotionAct::kCorrect, "lệch quá hạn thì kéo về");
    context.expect(far.position.x_cm == 0, "kéo về mốc của máy chủ");
    context.expect(!motion.pending(), "bỏ đường chờ");
}

void rewound_tick_is_pulled_back(Context& context) {
    Motion motion = placed_at(0);
    context.expect(motion.judge(step(10, 5)).act == MotionAct::kAccept, "bước hợp lệ");
    const auto back = motion.judge(step(12, 3));
    context.expect(back.act == MotionAct::kCorrect, "tick lùi không được nhận");
    context.expect(back.position.tick == 5, "kéo về kèm tick của bước nhận gần nhất");
}

void client_tick_ahead_of_server_buys_nothing(Context& context) {
    Motion motion = placed_at(0);
    context.expect(motion.judge(step(2000, 900)).act == MotionAct::kAccept, "nhận bước");
    static_cast<void>(motion.chase(at_tick(1)));
    context.expect(motion.anchor().x_cm < 20.0F, "đo theo đồng hồ máy chủ");
}

void clear_drops_anchor(Context& context) {
    Motion motion = placed_at(0);
    motion.clear();
    context.expect(motion.judge(step(1, 1)).act == MotionAct::kOutOfOrder, "rời game thì bỏ mốc");
    context.expect(!motion.pending(), "không còn đường chờ");
}

const std::array kCases{
    Case{.name = "server_tick_follows_server_clock", .body = &server_tick_follows_server_clock},
    Case{.name = "move_before_placement_is_out_of_order", .body = &move_before_placement_is_out_of_order},
    Case{.name = "place_sends_server_anchor", .body = &place_sends_server_anchor},
    Case{.name = "legal_steps_are_accepted_and_followed", .body = &legal_steps_are_accepted_and_followed},
    Case{.name = "invalid_steps_are_pulled_back", .body = &invalid_steps_are_pulled_back},
    Case{.name = "overspeed_is_clamped_not_kicked", .body = &overspeed_is_clamped_not_kicked},
    Case{.name = "lag_beyond_resync_is_pulled_back", .body = &lag_beyond_resync_is_pulled_back},
    Case{.name = "rewound_tick_is_pulled_back", .body = &rewound_tick_is_pulled_back},
    Case{.name = "client_tick_ahead_of_server_buys_nothing", .body = &client_tick_ahead_of_server_buys_nothing},
    Case{.name = "clear_drops_anchor", .body = &clear_drops_anchor},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
