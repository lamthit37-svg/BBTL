// Nhảy (motion/jump): điều kiện cho nhảy, chọn động tác 9/12 theo rand() % 4, và đường bay của
// CObject_Phy::Tick 2026 (vy = 15 (1 - d/900)^2 - 18 (d/900)^2, mỗi tick dời vy * 0.01). Số kỳ vọng của
// đường bay tính lại độc lập bằng float 32 bit (docs/AUDIT/evidence/jump_oracle.log): tick 10 ms chạm
// đất ở tick thứ 84 (840 ms bay), đỉnh 3.19524; tick 16 ms chạm đất ở tick 52, đỉnh 1.96921.
#include "core/check.hpp"
#include "motion/jump.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>

namespace game::test {
namespace {

using motion::Jump;
using motion::JumpAction;
using motion::JumpGate;

struct Flight {
    std::uint32_t ticks = 0;
    std::uint32_t flown_ms = 0;
    float peak = 0.0F;
    bool landed = false;
};

// Bay trên đất phẳng độ cao ground, mỗi tick cách nhau step ms, tối đa 1000 tick.
Flight fly(Jump& jump, std::uint32_t step, float ground) {
    Flight flight;
    std::uint32_t now = 1000;
    static_cast<void>(motion::tick_jump(jump, now, ground));
    for (std::uint32_t tick = 1; tick <= 1000; ++tick) {
        now += step;
        const std::uint32_t before = jump.flown_ms;
        if (motion::tick_jump(jump, now, ground)) {
            flight.ticks = tick;
            flight.flown_ms = before + step;
            flight.landed = true;
            return flight;
        }
        flight.peak = std::max(flight.peak, jump.height - ground);
    }
    return flight;
}

void gate_refuses(Context& context) {
    Jump jump;
    context.expect(motion::can_jump(jump, JumpGate{}), "đứng yên thì nhảy được");
    context.expect(!motion::can_jump(jump, JumpGate{.is_dead = true}), "chết không nhảy");
    context.expect(!motion::can_jump(jump, JumpGate{.is_move_limited = true}), "bị khoá di chuyển không nhảy");
    context.expect(!motion::can_jump(jump, JumpGate{.is_busy = true}), "đang ra chiêu không nhảy");
    context.expect(!motion::can_jump(jump, JumpGate{.is_following_team = true}), "đang theo đội không nhảy");
    context.expect(!motion::can_jump(jump, JumpGate{.is_in_stall = true}), "đang bày hàng không nhảy");
    context.expect(!motion::can_jump(jump, JumpGate{.is_transformed = true}), "biến hình không nhảy");
    const motion::JumpStart first = motion::start_jump(jump, JumpGate{}, 0.0F, 0);
    context.expect(first.has_started && jump.is_jumping, "lần đầu nhảy");
    const motion::JumpStart second = motion::start_jump(jump, JumpGate{}, 0.0F, 0);
    context.expect(!second.has_started, "đang bay không nhảy tiếp");
}

void action_follows_roll(Context& context) {
    const std::array<std::uint32_t, 4> rolls{0, 1, 2, 7};
    const std::array<JumpAction, 4> moving{
        JumpAction::kJumpRun, JumpAction::kJumpStand, JumpAction::kJumpStand, JumpAction::kJumpStand};
    for (std::size_t index = 0; index < rolls.size(); ++index) {
        Jump jump;
        const motion::JumpStart run = motion::start_jump(jump, JumpGate{.is_moving = true}, 0.0F, rolls.at(index));
        context.expect(run.action == moving.at(index), "đang chạy: rand() % 4 == 0 mới là 12");
        Jump still;
        const motion::JumpStart stand = motion::start_jump(still, JumpGate{}, 0.0F, rolls.at(index));
        context.expect(stand.action == JumpAction::kJumpStand, "đứng yên luôn là 9");
    }
    Jump mounted;
    const motion::JumpStart ride = motion::start_jump(mounted, JumpGate{.is_moving = true, .is_mounted = true}, 0.0F, 3);
    context.expect(ride.action == JumpAction::kJumpRun && mounted.is_jumping, "cưỡi mà chạy là 12, có bay");
    Jump parked;
    const motion::JumpStart idle = motion::start_jump(parked, JumpGate{.is_mounted = true}, 0.0F, 0);
    context.expect(idle.has_started && !parked.is_jumping, "cưỡi đứng yên chỉ phát động tác");
}

void flight_matches_oracle(Context& context) {
    Jump fast;
    static_cast<void>(motion::start_jump(fast, JumpGate{}, 2.0F, 1));
    const Flight hundred = fly(fast, 10, 2.0F);
    context.expect(hundred.landed && hundred.ticks == 84 && hundred.flown_ms == 840, "tick 10 ms: chạm đất ở tick 84");
    context.expect(std::fabs(hundred.peak - 3.19524F) < 1e-3F, "tick 10 ms: đỉnh 3.195");
    context.expect(!fast.is_jumping && fast.height == 2.0F, "chạm đất thì về mặt đất, hết nhảy");
    Jump slow;
    static_cast<void>(motion::start_jump(slow, JumpGate{}, 0.0F, 1));
    const Flight sixty = fly(slow, 16, 0.0F);
    context.expect(sixty.landed && sixty.ticks == 52, "tick 16 ms: chạm đất ở tick 52");
    context.expect(std::fabs(sixty.peak - 1.96921F) < 1e-3F, "tick 16 ms: đỉnh 1.969 (gốc phụ thuộc tốc độ khung)");
}

void short_ticks_wait(Context& context) {
    Jump jump;
    static_cast<void>(motion::start_jump(jump, JumpGate{}, 0.0F, 1));
    static_cast<void>(motion::tick_jump(jump, 100, 0.0F));
    static_cast<void>(motion::tick_jump(jump, 105, 0.0F));
    context.expect(jump.flown_ms == 0 && jump.height == 0.0F, "dưới 10 ms không bay");
    static_cast<void>(motion::tick_jump(jump, 112, 0.0F));
    context.expect(jump.flown_ms == 12, "mốc cũ giữ nguyên nên lần sau tính cả 12 ms");
    context.expect(jump.height > 0.0F, "đã rời đất");
}

void rising_ground_lifts_not_lands(Context& context) {
    Jump jump;
    static_cast<void>(motion::start_jump(jump, JumpGate{}, 0.0F, 1));
    static_cast<void>(motion::tick_jump(jump, 0, 0.0F));
    const bool landed = motion::tick_jump(jump, 10, 5.0F);
    context.expect(!landed && jump.is_jumping && jump.height == 5.0F, "đang lên gặp dốc: nâng thân, chưa chạm đất");
    bool down = false;
    for (std::uint32_t now = 20; now < 2000 && !down; now += 10) {
        down = motion::tick_jump(jump, now, 5.0F);
    }
    context.expect(down && jump.height == 5.0F, "rơi xuống thì chạm đất ở mặt dốc");
}

constexpr std::array kCases{
    Case{.name = "gate_refuses", .body = &gate_refuses},
    Case{.name = "action_follows_roll", .body = &action_follows_roll},
    Case{.name = "flight_matches_oracle", .body = &flight_matches_oracle},
    Case{.name = "short_ticks_wait", .body = &short_ticks_wait},
    Case{.name = "rising_ground_lifts_not_lands", .body = &rising_ground_lifts_not_lands},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "jump_tests: mọi ca phải qua");
    return 0;
}