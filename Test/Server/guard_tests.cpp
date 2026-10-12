// Luật bước đi: trong tầm tốc độ thì nhận; vượt thì không nhận và kéo về mốc; vượt lặp lại (kể cả
// xen kẽ bước thường) thì phạt. Thời gian đo theo tick máy chủ, client không mua thêm quãng đường.
#include "guard/pace.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <limits>

namespace game::test {
namespace {

using guard::Anchor;
using guard::Pace;
using guard::Step;
using guard::Verdict;

[[nodiscard]] Pace anchored(float x, std::uint32_t tick) {
    Pace pace;
    pace.reset(Anchor{.x_cm = x, .z_cm = 0}, tick, tick);
    return pace;
}

// Client và máy chủ cùng nhịp: tick khai bằng tick máy chủ.
[[nodiscard]] Verdict walk(Pace& pace, float x, std::uint32_t tick) {
    return pace.observe({.x_cm = x, .z_cm = 0, .tick = tick}, tick);
}

void legal_walk_is_kept(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(walk(pace, 15, 1) == Verdict::kOk, "một tick trong tầm");
    context.expect(walk(pace, 30, 2) == Verdict::kOk, "tick kế trong tầm");
    context.expect(pace.anchor().x_cm == 30, "mốc dời tới bước đã nhận");
}

void no_anchor_no_trust(Context& context) {
    Pace pace;
    context.expect(pace.observe({.x_cm = 9000, .z_cm = 0, .tick = 0}, 0) == Verdict::kNoAnchor,
        "bước đầu của client không thành mốc");
}

// G4: vượt một lần là kRejected (khác kOk), mốc giữ nguyên để người gọi kéo về.
void one_burst_is_rejected_not_penalized(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(walk(pace, 80, 1) == Verdict::kRejected, "vượt tốc một tick: không nhận, chưa phạt");
    context.expect(pace.anchor().x_cm == 0, "mốc không dời theo bước bị từ chối");
}

void repeated_overspeed_is_speed(Context& context) {
    Pace pace = anchored(0, 0);
    static_cast<void>(walk(pace, 80, 1));
    static_cast<void>(walk(pace, 160, 2));
    context.expect(walk(pace, 240, 3) == Verdict::kSpeed, "ba tick vượt tốc là speed");
}

void two_jumps_are_teleport(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(walk(pace, 20000, 1) == Verdict::kRejected, "cú nhảy đầu: kéo về, chưa phạt");
    context.expect(walk(pace, 40000, 2) == Verdict::kTeleport, "hai cú nhảy là dịch chuyển");
}

// G6: tick lùi không dời mốc và không được nhận.
void rewound_tick_does_not_move(Context& context) {
    Pace pace = anchored(0, 5);
    context.expect(walk(pace, 9000, 4) == Verdict::kRejected, "tick lùi bị từ chối");
    context.expect(pace.anchor().x_cm == 0, "tick lùi không dời mốc");
    context.expect(walk(pace, 15, 6) == Verdict::kOk, "mốc vẫn là bước đã nhận");
}

void jump_then_walk_is_still_teleport(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(walk(pace, 20000, 1) == Verdict::kRejected, "cú nhảy đầu chưa phạt");
    context.expect(walk(pace, 20020, 2) == Verdict::kTeleport, "bước thường sau cú nhảy vẫn đo từ mốc cũ");
}

// G5: bước cùng tick đo với thời gian 0.
void same_tick_jump_is_measured(Context& context) {
    Pace pace = anchored(0, 3);
    context.expect(walk(pace, 9000, 3) == Verdict::kRejected, "nhảy trong cùng tick bị từ chối");
    context.expect(walk(pace, 9010, 4) == Verdict::kTeleport, "mốc không bị dời bởi bước cùng tick");
}

void rewound_tick_keeps_anchor(Context& context) {
    Pace pace = anchored(0, 5);
    static_cast<void>(walk(pace, 9000, 4));
    static_cast<void>(walk(pace, 9000, 6));
    context.expect(walk(pace, 9000, 7) == Verdict::kTeleport, "tick lùi không thành mốc");
}

// G2: client khai tick vọt 300 tick trong khi máy chủ mới qua 1 tick. Trước đây 300 tick cho phép
// đi ~49 m; nay chỉ được tính 1 + kJitterTicks tick.
void client_tick_cannot_buy_distance(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(pace.observe({.x_cm = 4000, .z_cm = 0, .tick = 300}, 1) != Verdict::kOk,
        "tick client vọt không mua thêm quãng đường");
    context.expect(pace.anchor().x_cm == 0, "mốc giữ nguyên");
    context.expect(pace.observe({.x_cm = 4000, .z_cm = 0, .tick = 300}, 300) == Verdict::kOk,
        "đủ thời gian máy chủ thì nhận");
}

// G3: xen bước thường giữa các cú vượt (vượt, thường, vượt, thường, vượt) vẫn bị phạt.
// Chuỗi cũ đặt lại về 0 ở mỗi bước thường nên không bao giờ phạt.
void interleaved_overspeed_is_speed(Context& context) {
    Pace pace = anchored(0, 0);
    Verdict last = Verdict::kOk;
    for (std::uint32_t tick = 1; tick <= 20 && last != Verdict::kSpeed; ++tick) {
        const bool burst = (tick % 2U) == 1U;
        const float target = pace.anchor().x_cm + (burst ? 60.0F : 10.0F);
        last = walk(pace, target, tick);
    }
    context.expect(last == Verdict::kSpeed, "vượt xen kẽ vẫn thành speed");
}

// Vượt lẻ tẻ (mạng giật) cách nhau lâu thì ngân sách rò hết, không phạt oan.
void rare_bursts_leak_away(Context& context) {
    Pace pace = anchored(0, 0);
    bool penalized = false;
    std::uint32_t tick = 0;
    for (int round = 0; round < 10; ++round) {
        tick += 60;
        const Verdict burst = walk(pace, pace.anchor().x_cm + 2000, tick);
        penalized = penalized || burst == Verdict::kSpeed || burst == Verdict::kTeleport;
        tick += 1;
        static_cast<void>(walk(pace, pace.anchor().x_cm + 10, tick));
    }
    context.expect(!penalized, "vượt cách nhau 2 giây không bị phạt");
}

void reset_clears_debt(Context& context) {
    Pace pace = anchored(0, 0);
    static_cast<void>(walk(pace, 80, 1));
    static_cast<void>(walk(pace, 160, 2));
    pace.reset(Anchor{.x_cm = 500, .z_cm = 0}, 3, 3);
    context.expect(walk(pace, 580, 4) == Verdict::kRejected, "sau reset chưa phạt ngay");
    context.expect(pace.anchor().x_cm == 500, "mốc là chỗ máy chủ đặt");
}

void nan_is_rejected(Context& context) {
    Pace pace = anchored(0, 0);
    const float nan = std::numeric_limits<float>::quiet_NaN();
    context.expect(pace.observe({.x_cm = nan, .z_cm = 0, .tick = 1}, 1) != Verdict::kOk, "NaN không được nhận");
    context.expect(pace.anchor().x_cm == 0, "NaN không thành mốc");
}

const std::array kCases{
    Case{.name = "legal_walk_is_kept", .body = &legal_walk_is_kept},
    Case{.name = "no_anchor_no_trust", .body = &no_anchor_no_trust},
    Case{.name = "one_burst_is_rejected_not_penalized", .body = &one_burst_is_rejected_not_penalized},
    Case{.name = "repeated_overspeed_is_speed", .body = &repeated_overspeed_is_speed},
    Case{.name = "two_jumps_are_teleport", .body = &two_jumps_are_teleport},
    Case{.name = "rewound_tick_does_not_move", .body = &rewound_tick_does_not_move},
    Case{.name = "jump_then_walk_is_still_teleport", .body = &jump_then_walk_is_still_teleport},
    Case{.name = "same_tick_jump_is_measured", .body = &same_tick_jump_is_measured},
    Case{.name = "rewound_tick_keeps_anchor", .body = &rewound_tick_keeps_anchor},
    Case{.name = "client_tick_cannot_buy_distance", .body = &client_tick_cannot_buy_distance},
    Case{.name = "interleaved_overspeed_is_speed", .body = &interleaved_overspeed_is_speed},
    Case{.name = "rare_bursts_leak_away", .body = &rare_bursts_leak_away},
    Case{.name = "reset_clears_debt", .body = &reset_clears_debt},
    Case{.name = "nan_is_rejected", .body = &nan_is_rejected},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
