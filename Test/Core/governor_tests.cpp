// Test của core::RateGovernor: trần khung bắt đầu ở mức vững, chỉ thăm dò lên khi khung còn dư sức, lùi khi trễ, và thăm dò
// hỏng thì lần kế tiếp chờ lâu hơn. Số liệu khung là giả nên không phụ thuộc đồng hồ.
#include "core/check.hpp"
#include "core/governor.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>

namespace game::test {
namespace {

constexpr std::size_t kWindow = core::RateGovernor::kWindow;

[[nodiscard]] bool near_hz(double actual, double expected) {
    return std::abs(actual - expected) < 0.01;
}

// Một cửa sổ khung đều: mỗi khung dài `interval_ms`, việc thật `busy_ms`.
[[nodiscard]] bool run_window(core::RateGovernor& governor, core::FrameSample frame) {
    bool changed = false;
    for (std::size_t i = 0; i < kWindow; ++i) {
        changed = governor.note_frame(frame) || changed;
    }
    return changed;
}

// Khung đúng nhịp của trần hiện hành, việc thật nhẹ.
[[nodiscard]] core::FrameSample easy_frame(const core::RateGovernor& governor) {
    return {.interval_ms = 1000.0 / governor.target_hz(), .busy_ms = 2.0};
}

// Khung trễ gấp đôi ngân sách của trần hiện hành.
[[nodiscard]] core::FrameSample late_frame(const core::RateGovernor& governor) {
    return {.interval_ms = 2000.0 / governor.target_hz(), .busy_ms = 20.0};
}

void starts_at_a_safe_rate(Context& context) {
    context.expect(near_hz(core::RateGovernor({.refresh_hz = 120.0, .ceiling_hz = 120}).target_hz(), 60.0),
                   "màn 120 Hz bắt đầu ở 60");
    context.expect(near_hz(core::RateGovernor({.refresh_hz = 60.0, .ceiling_hz = 120}).target_hz(), 60.0),
                   "màn 60 Hz chỉ có 60");
    context.expect(near_hz(core::RateGovernor({.refresh_hz = 144.0, .ceiling_hz = 144}).target_hz(), 48.0),
                   "màn 144 Hz bắt đầu ở 48, phần nguyên của nhịp quét");
    context.expect(near_hz(core::RateGovernor({.refresh_hz = 0.0, .ceiling_hz = 120}).target_hz(), 60.0),
                   "tần số quét không biết thì coi là 60");
    context.expect(near_hz(core::RateGovernor({.refresh_hz = 24.0, .ceiling_hz = 120}).target_hz(), 24.0),
                   "màn dưới 30 Hz chỉ có chính nó");
}

void ceiling_is_honoured(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 60});
    for (int round = 0; round < 8; ++round) {
        static_cast<void>(run_window(governor, easy_frame(governor)));
    }
    context.expect(near_hz(governor.target_hz(), 60.0), "máy hạng thấp không bao giờ được thăm dò quá trần hạng máy");
}

void rises_when_frames_have_headroom(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    context.expect(run_window(governor, easy_frame(governor)), "cửa sổ vững và nhẹ thì lên mức cao");
    context.expect(near_hz(governor.target_hz(), 120.0), "lên đúng nhịp quét");
    context.expect(!run_window(governor, easy_frame(governor)), "đã ở đỉnh thì không đổi nữa");
}

void stays_when_work_is_heavy(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    // Đúng nhịp 60 nhưng việc thật 10 ms: mức 120 chỉ có 8,3 ms nên lên sẽ không kịp.
    const core::FrameSample heavy{.interval_ms = 1000.0 / 60.0, .busy_ms = 10.0};
    for (int round = 0; round < 6; ++round) {
        context.expect(!run_window(governor, heavy), "việc nặng thì không thăm dò");
    }
    context.expect(near_hz(governor.target_hz(), 60.0), "vẫn ở 60");
}

void steps_down_when_late(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    static_cast<void>(run_window(governor, easy_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 120.0), "tiền đề: đã lên 120");
    context.expect(run_window(governor, late_frame(governor)), "khung trễ thì lùi");
    context.expect(near_hz(governor.target_hz(), 60.0), "lùi về 60");
}

// Số cửa sổ khung nhẹ cho tới khi trần đổi (tối đa 100).
[[nodiscard]] int windows_until_change(core::RateGovernor& governor) {
    int windows = 0;
    while (windows < 100) {
        ++windows;
        if (run_window(governor, easy_frame(governor))) break;
    }
    return windows;
}

void failed_probe_backs_off_longer(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    context.expect(windows_until_change(governor) == 1, "lần đầu thăm dò ngay");
    static_cast<void>(run_window(governor, late_frame(governor)));
    const int first_wait = windows_until_change(governor);
    context.expect(first_wait > 1, "thăm dò hỏng thì chờ rồi mới thử lại");
    static_cast<void>(run_window(governor, late_frame(governor)));
    context.expect(windows_until_change(governor) > first_wait, "hỏng lần nữa thì chờ lâu hơn");
}

void refresh_change_restarts(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    static_cast<void>(run_window(governor, easy_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 120.0), "tiền đề: đã lên 120");
    governor.set_refresh(90.0);
    context.expect(near_hz(governor.target_hz(), 45.0), "đổi sang màn 90 Hz thì dựng lại, bắt đầu ở 45");
    static_cast<void>(run_window(governor, easy_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 90.0), "rồi thăm dò lên 90");
}

constexpr std::array kCases{
    Case{.name = "starts_at_a_safe_rate", .body = &starts_at_a_safe_rate},
    Case{.name = "ceiling_is_honoured", .body = &ceiling_is_honoured},
    Case{.name = "rises_when_frames_have_headroom", .body = &rises_when_frames_have_headroom},
    Case{.name = "stays_when_work_is_heavy", .body = &stays_when_work_is_heavy},
    Case{.name = "steps_down_when_late", .body = &steps_down_when_late},
    Case{.name = "failed_probe_backs_off_longer", .body = &failed_probe_backs_off_longer},
    Case{.name = "refresh_change_restarts", .body = &refresh_change_restarts},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "governor_tests: mọi ca phải qua");
    return 0;
}
