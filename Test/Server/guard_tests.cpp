// Luật bước đi: trong tầm tốc độ thì nhận, vượt một lần thì chưa phạt, lặp lại thì phạt.
#include "guard/pace.hpp"
#include "test.hpp"

#include <array>

namespace game::test {
namespace {

using guard::Pace;
using guard::Step;
using guard::Verdict;

void legal_walk_is_kept(Context& context) {
    Pace pace;
    context.expect(pace.observe({.x_cm = 0, .z_cm = 0, .tick = 0}) == Verdict::kOk, "bước đầu");
    context.expect(pace.observe({.x_cm = 20, .z_cm = 0, .tick = 1}) == Verdict::kOk, "một tick trong tầm");
    context.expect(pace.observe({.x_cm = 40, .z_cm = 0, .tick = 2}) == Verdict::kOk, "tick kế trong tầm");
}

void one_burst_is_not_enough(Context& context) {
    Pace pace;
    static_cast<void>(pace.observe({.x_cm = 0, .z_cm = 0, .tick = 0}));
    const Verdict once = pace.observe({.x_cm = 80, .z_cm = 0, .tick = 1});
    context.expect(once == Verdict::kOk, "vượt tốc một tick chưa phạt");
}

void repeated_overspeed_is_speed(Context& context) {
    Pace pace;
    static_cast<void>(pace.observe({.x_cm = 0, .z_cm = 0, .tick = 0}));
    static_cast<void>(pace.observe({.x_cm = 80, .z_cm = 0, .tick = 1}));
    static_cast<void>(pace.observe({.x_cm = 160, .z_cm = 0, .tick = 2}));
    const Verdict third = pace.observe({.x_cm = 240, .z_cm = 0, .tick = 3});
    context.expect(third == Verdict::kSpeed, "ba tick vượt tốc là speed");
}

void two_jumps_are_teleport(Context& context) {
    Pace pace;
    static_cast<void>(pace.observe({.x_cm = 0, .z_cm = 0, .tick = 0}));
    const Verdict first = pace.observe({.x_cm = 20000, .z_cm = 0, .tick = 1});
    context.expect(first == Verdict::kOk, "cú nhảy đầu chưa đủ");
    const Verdict second = pace.observe({.x_cm = 40000, .z_cm = 0, .tick = 2});
    context.expect(second == Verdict::kTeleport, "hai cú nhảy là dịch chuyển");
}

void rewound_tick_does_not_move(Context& context) {
    Pace pace;
    static_cast<void>(pace.observe({.x_cm = 0, .z_cm = 0, .tick = 5}));
    context.expect(pace.observe({.x_cm = 9000, .z_cm = 0, .tick = 4}) == Verdict::kOk, "tick lùi bỏ qua");
    context.expect(pace.observe({.x_cm = 20, .z_cm = 0, .tick = 6}) == Verdict::kOk, "mốc vẫn là bước đã nhận");
}

const std::array kCases{
    Case{.name = "legal_walk_is_kept", .body = &legal_walk_is_kept},
    Case{.name = "one_burst_is_not_enough", .body = &one_burst_is_not_enough},
    Case{.name = "repeated_overspeed_is_speed", .body = &repeated_overspeed_is_speed},
    Case{.name = "two_jumps_are_teleport", .body = &two_jumps_are_teleport},
    Case{.name = "rewound_tick_does_not_move", .body = &rewound_tick_does_not_move},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
