/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Server/guard_tests.cpp
 *  PHÂN HỆ   : Server / Guard Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Luật bước đi (H1-B): máy chủ làm chủ vị trí. Client khai chỗ đứng, máy chủ
 *    đi theo đường đó với tốc độ của nó (không đóng phiên vì tốc độ). Thời gian
 *    chỉ theo đồng hồ máy chủ; lao sau khi đứng yên chỉ nhảy tối đa quỹ; lệch
 *    tích luỹ quá xa thì kéo về, không phạt.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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

constexpr float kResyncCm = guard::kRunCmPerSec * 10.0F;
constexpr float kTickCm = guard::kRunCmPerSec * guard::kTickSeconds;
constexpr float kEpsilon = 0.01F;

[[nodiscard]] Pace anchored(float x, std::uint32_t tick) {
    Pace pace;
    pace.reset(Anchor{.x_cm = x, .z_cm = 0}, tick, tick, kResyncCm);
    return pace;
}

// Client và máy chủ cùng nhịp: tick khai bằng tick máy chủ.
[[nodiscard]] Verdict walk(Pace& pace, float x, std::uint32_t tick) {
    const Verdict verdict = pace.observe({.x_cm = x, .z_cm = 0, .tick = tick});
    static_cast<void>(pace.advance(tick));
    return verdict;
}

// Client chạy `step_cm` mỗi tick trong `ticks` tick, máy chủ đi theo mỗi tick. Trả số lần không kOk.
[[nodiscard]] int run(Pace& pace, float step_cm, std::uint32_t from_tick, std::uint32_t ticks) {
    int refused = 0;
    float x = pace.anchor().x_cm + pace.lag_cm();
    for (std::uint32_t tick = from_tick + 1; tick <= from_tick + ticks; ++tick) {
        x += step_cm;
        if (walk(pace, x, tick) != Verdict::kOk) ++refused;
    }
    return refused;
}

void legal_walk_is_followed(Context& context) {
    Pace pace = anchored(0, 0);
    const int refused = run(pace, 15.0F, 0, 60);
    context.expect(refused == 0, "chạy đều trong tầm thì nhận mọi bước");
    context.expect(!pace.pending(), "máy chủ theo kịp, không còn đường chờ");
    context.expect(pace.anchor().x_cm > 899.0F, "mốc tới chỗ client khai");
}

void no_anchor_no_trust(Context& context) {
    Pace pace;
    context.expect(pace.observe({.x_cm = 9000, .z_cm = 0, .tick = 0}) == Verdict::kNoAnchor,
        "bước đầu của client không thành mốc");
}

// Đứng yên bao lâu rồi lao cũng chỉ nhảy tối đa quỹ; phần còn lại máy chủ đi dần.
void jump_after_idle_is_capped_by_bank(Context& context) {
    Pace pace = anchored(0, 0);
    static_cast<void>(pace.advance(600));
    context.expect(pace.observe({.x_cm = 3000, .z_cm = 0, .tick = 600}) == Verdict::kOk, "nhận bước xa");
    static_cast<void>(pace.advance(600));
    context.expect(pace.anchor().x_cm <= guard::kBankCm + kEpsilon, "cú lao chỉ nhảy tối đa quỹ");
    context.expect(pace.anchor().x_cm >= guard::kBankCm - kEpsilon, "quỹ đầy sau khi đứng yên");
    context.expect(pace.pending(), "phần còn lại vẫn chờ");
}

// Chạy gấp đôi: không phạt, không đóng phiên; vị trí máy chủ bị bóp ở tốc độ trần.
void overspeed_is_clamped_not_punished(Context& context) {
    Pace pace = anchored(0, 0);
    const int refused = run(pace, 2.0F * kTickCm, 0, 100);
    const float cap_cm = 100.0F * kTickCm * guard::kSlack;
    context.expect(refused == 0, "chạy gấp đôi trong 3 giây vẫn được nhận");
    context.expect(pace.anchor().x_cm <= cap_cm + kEpsilon, "vị trí máy chủ không vượt tốc độ trần");
    context.expect(pace.anchor().x_cm > 0.9F * cap_cm, "máy chủ vẫn đi hết tốc độ trần");
    context.expect(pace.pending(), "client đã chạy xa hơn máy chủ");
}

// Khi client dừng, máy chủ đi nốt đường đã nhận rồi khép lại, không bỏ phần nào.
void server_catches_up_when_client_stops(Context& context) {
    Pace pace = anchored(0, 0);
    static_cast<void>(run(pace, 2.0F * kTickCm, 0, 100));
    const float goal_cm = pace.anchor().x_cm + pace.lag_cm();
    for (std::uint32_t tick = 101; tick <= 400 && pace.pending(); ++tick)
        static_cast<void>(pace.advance(tick));
    context.expect(!pace.pending(), "hết đường chờ sau khi client dừng");
    context.expect(pace.anchor().x_cm > goal_cm - kEpsilon, "mốc tới đúng chỗ client khai cuối");
}

// Gấp bốn lần: lệch tích luỹ vượt hạn thì kéo về mốc, không phạt, bước kế từ mốc được nhận lại.
void far_lag_pulls_back_without_penalty(Context& context) {
    Pace pace = anchored(0, 0);
    int resyncs = 0;
    float x = 0;
    for (std::uint32_t tick = 1; tick <= 300 && resyncs == 0; ++tick) {
        x += 4.0F * kTickCm;
        const Verdict verdict = walk(pace, x, tick);
        if (verdict == Verdict::kResync) ++resyncs;
        context.expect(verdict == Verdict::kOk || verdict == Verdict::kResync, "chỉ nhận hoặc kéo về");
    }
    context.expect(resyncs == 1, "gấp bốn lần bị kéo về trong 10 giây");
    context.expect(!pace.pending(), "kéo về thì bỏ đường chờ");
    const float back = pace.anchor().x_cm;
    context.expect(walk(pace, back + 10.0F, 301) == Verdict::kOk, "bước kế từ mốc được nhận, không phạt");
}

// Mạng đứng 9 giây rồi dồn hết Move: không kéo về (người thật), mốc nhảy tối đa quỹ.
void stall_then_burst_is_kept(Context& context) {
    Pace pace = anchored(0, 0);
    int refused = 0;
    float x = 0;
    for (std::uint32_t tick = 1; tick <= 270; ++tick) {
        x += kTickCm;
        const Step step{.x_cm = x, .z_cm = 0, .tick = tick};
        if (pace.observe(step) != Verdict::kOk) ++refused;
    }
    context.expect(refused == 0, "gói dồn sau 9 giây đứng mạng đều được nhận");
    static_cast<void>(pace.advance(270));
    context.expect(pace.anchor().x_cm <= guard::kBankCm + kEpsilon, "mốc chỉ nhảy tối đa quỹ");
    for (std::uint32_t tick = 271; tick <= 600 && pace.pending(); ++tick)
        static_cast<void>(pace.advance(tick));
    context.expect(!pace.pending(), "máy chủ khép lại khi client dừng");
    context.expect(pace.anchor().x_cm > x - 1.0F, "mốc tới chỗ client khai cuối");
}

// G2: client khai tick vọt 300 trong khi máy chủ mới qua một tick không mua thêm quãng đường.
void client_tick_buys_no_distance(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(pace.observe({.x_cm = 4000, .z_cm = 0, .tick = 300}) == Verdict::kOk, "nhận bước");
    static_cast<void>(pace.advance(1));
    context.expect(pace.anchor().x_cm <= 1.05F * kTickCm + kEpsilon, "mốc chỉ đi theo tick máy chủ");
}

// G6: tick lùi, NaN và vô cực không được nhận, bỏ đường chờ; bước hợp lệ sau đó vẫn được nhận.
void invalid_steps_are_rejected(Context& context) {
    Pace pace = anchored(0, 5);
    context.expect(walk(pace, 10, 6) == Verdict::kOk, "bước hợp lệ");
    context.expect(pace.observe({.x_cm = 12, .z_cm = 0, .tick = 4}) == Verdict::kRejected, "tick lùi");
    context.expect(!pace.pending(), "bước từ chối bỏ đường chờ");
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const float inf = std::numeric_limits<float>::infinity();
    context.expect(pace.observe({.x_cm = nan, .z_cm = 0, .tick = 7}) == Verdict::kRejected, "NaN");
    context.expect(pace.observe({.x_cm = inf, .z_cm = 0, .tick = 7}) == Verdict::kRejected, "vô cực");
    const float back = pace.anchor().x_cm;
    context.expect(walk(pace, back + 5.0F, 8) == Verdict::kOk, "bước hợp lệ sau đó vẫn nhận");
}

// Máy chủ đi dọc các chỗ client đã khai, không cắt góc: điểm góc nằm trong những chỗ báo zone.
void path_goes_through_corner(Context& context) {
    Pace pace = anchored(0, 0);
    context.expect(pace.observe({.x_cm = 100, .z_cm = 0, .tick = 1}) == Verdict::kOk, "đoạn thứ nhất");
    context.expect(pace.observe({.x_cm = 100, .z_cm = 100, .tick = 2}) == Verdict::kOk, "đoạn thứ hai");
    const guard::Trail trail = pace.advance(60);
    bool at_corner = false;
    for (const Anchor& spot : trail.view())
        at_corner = at_corner || (spot.x_cm == 100.0F && spot.z_cm == 0.0F);
    context.expect(at_corner, "đi qua đúng góc");
    const Anchor last = trail.view().back();
    context.expect(last.x_cm == 100.0F && last.z_cm == 100.0F, "điểm cuối là mốc mới");
}

// Hàng đợi đầy: kéo về thay vì cấp thêm; bộ nhớ của một ô không lớn theo client.
void full_queue_pulls_back(Context& context) {
    Pace pace = anchored(0, 0);
    Verdict last = Verdict::kOk;
    for (std::size_t at = 1; at <= guard::kNodes + 1 && last == Verdict::kOk; ++at)
        last = pace.observe({.x_cm = 0.1F * static_cast<float>(at), .z_cm = 0, .tick = 1});
    context.expect(last == Verdict::kResync, "quá số bước chờ thì kéo về");
    context.expect(!pace.pending(), "bỏ đường chờ");
}

void reset_clears_path_and_bank(Context& context) {
    Pace pace = anchored(0, 0);
    static_cast<void>(pace.advance(600));
    context.expect(pace.observe({.x_cm = 900, .z_cm = 0, .tick = 600}) == Verdict::kOk, "nhận bước");
    pace.reset(Anchor{.x_cm = 500, .z_cm = 0}, 601, 601, kResyncCm);
    context.expect(!pace.pending(), "mốc mới bỏ đường chờ");
    static_cast<void>(pace.advance(601));
    context.expect(pace.anchor().x_cm == 500.0F, "mốc là chỗ máy chủ đặt, quỹ về 0");
    static_cast<void>(pace.observe({.x_cm = 900, .z_cm = 0, .tick = 602}));
    static_cast<void>(pace.advance(601));
    context.expect(pace.anchor().x_cm == 500.0F, "chưa qua tick nào thì chưa đi");
}

const std::array kCases{
    Case{.name = "legal_walk_is_followed", .body = &legal_walk_is_followed},
    Case{.name = "no_anchor_no_trust", .body = &no_anchor_no_trust},
    Case{.name = "jump_after_idle_is_capped_by_bank", .body = &jump_after_idle_is_capped_by_bank},
    Case{.name = "overspeed_is_clamped_not_punished", .body = &overspeed_is_clamped_not_punished},
    Case{.name = "server_catches_up_when_client_stops", .body = &server_catches_up_when_client_stops},
    Case{.name = "far_lag_pulls_back_without_penalty", .body = &far_lag_pulls_back_without_penalty},
    Case{.name = "stall_then_burst_is_kept", .body = &stall_then_burst_is_kept},
    Case{.name = "client_tick_buys_no_distance", .body = &client_tick_buys_no_distance},
    Case{.name = "invalid_steps_are_rejected", .body = &invalid_steps_are_rejected},
    Case{.name = "path_goes_through_corner", .body = &path_goes_through_corner},
    Case{.name = "full_queue_pulls_back", .body = &full_queue_pulls_back},
    Case{.name = "reset_clears_path_and_bank", .body = &reset_clears_path_and_bank},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
