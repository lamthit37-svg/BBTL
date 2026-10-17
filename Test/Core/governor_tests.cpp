/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Core/governor_tests.cpp
 *  PHÂN HỆ   : Core / Governor Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test RateGovernor bằng số liệu giả: các mức, lùi khi trễ, thăm dò lên, lùi
 *    gấp đôi, nhớ mức xa tầm.
 *  - Máy mô phỏng đo trên tablet (chậm sau nạp cảnh và sau mỗi lần lên mức) cho
 *    ca bỏ qua khung ổn định.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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

// Số khung một lần phán xét cần từ trạng thái hiện tại: phần bỏ qua sau khi đổi mức, rồi một cửa sổ.
[[nodiscard]] std::size_t frames_to_judge(const core::RateGovernor& governor) {
    return governor.settle_left() + kWindow;
}

// Một cửa sổ khung đều: mỗi khung dài `interval_ms`, việc thật `busy_ms`.
[[nodiscard]] bool run_window(core::RateGovernor& governor, core::FrameSample frame) {
    bool changed = false;
    const std::size_t count = frames_to_judge(governor);
    for (std::size_t i = 0; i < count; ++i) {
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
    // Đúng nhịp 60 nhưng việc thật 20 ms: mức 120 chỉ có 8,3 ms, gấp 2,4 lần nên lên sẽ không kịp.
    const core::FrameSample heavy{.interval_ms = 1000.0 / 60.0, .busy_ms = 20.0};
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

// Một cửa sổ mà cứ bốn khung có một khung trễ: trễ 25%, đủ để lùi nhưng chưa phải xa tầm.
[[nodiscard]] bool run_near_window(core::RateGovernor& governor) {
    const core::FrameSample easy = easy_frame(governor);
    const core::FrameSample late = late_frame(governor);
    bool changed = false;
    const std::size_t count = frames_to_judge(governor);
    for (std::size_t i = 0; i < count; ++i) {
        const core::FrameSample frame = i % 4 == 0 ? late : easy;
        changed = governor.note_frame(frame) || changed;
    }
    return changed;
}

void failed_probe_backs_off_longer(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    context.expect(windows_until_change(governor) == 1, "lần đầu thăm dò ngay");
    static_cast<void>(run_near_window(governor));
    const int first_wait = windows_until_change(governor);
    context.expect(first_wait > 1, "thăm dò hỏng thì chờ rồi mới thử lại");
    static_cast<void>(run_near_window(governor));
    context.expect(windows_until_change(governor) > first_wait, "hỏng lần nữa thì chờ lâu hơn");
}

// Thăm dò mà mọi khung đều trễ: mức ấy xa tầm máy, thử lại chỉ thêm một đợt khung so le. Đo
// 2026-10-17 trên TB-X306F: GPU 21 ms, mỗi lần thử 60 khung là ~2 giây so le một nhịp, hai nhịp quét.
void far_failed_probe_is_not_retried(Context& context) {
    core::RateGovernor governor({.refresh_hz = 120.0, .ceiling_hz = 120});
    context.expect(windows_until_change(governor) == 1, "tiền đề: thăm dò 120 ngay");
    static_cast<void>(run_window(governor, late_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 60.0), "thăm dò hỏng thì lùi về 60");
    context.expect(windows_until_change(governor) == 100, "mức xa tầm thì không thăm dò lại");
    context.expect(windows_until_change(governor) < 100, "rất lâu sau thì quên, cảnh có thể nhẹ đi");
    static_cast<void>(run_window(governor, late_frame(governor)));
    governor.set_refresh(120.0);
    context.expect(windows_until_change(governor) == 1, "dựng lại thì được thăm dò lại");
}

// Cửa sổ đầu ở mức khởi đầu thường trùng lúc nạp cảnh: trễ ở đó không phải là thăm dò hỏng.
void start_window_is_not_a_probe(Context& context) {
    core::RateGovernor governor({.refresh_hz = 60.0, .ceiling_hz = 60});
    static_cast<void>(run_window(governor, late_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 30.0), "mức khởi đầu trễ thì lùi về 30");
    context.expect(windows_until_change(governor) < 100, "rồi vẫn thăm dò lại 60 sau một lúc");
}

// Máy chậm dần đo 2026-10-17 trên TB-X306F: ở mức 30 việc thật phình tới 22 ms; vừa vào cảnh thì
// 180 khung đầu chạy ~22 ms, vừa lên 60 thì 50 khung đầu, rồi còn 13 ms và giữ đúng nhịp.
class RampingMachine {
public:
    static constexpr int kStartRamp = 180;
    static constexpr int kRampFrames = 50;

    [[nodiscard]] core::FrameSample frame(const core::RateGovernor& governor) {
        const double hz = governor.target_hz();
        if (std::abs(hz - last_hz_) > 0.01) restart(last_hz_ > 0.0 ? kRampFrames : kStartRamp);
        last_hz_ = hz;
        ++since_change_;
        if (hz < 45.0) return {.interval_ms = 1000.0 / 30.0, .busy_ms = 22.0};
        if (since_change_ <= ramp_) return {.interval_ms = 22.0, .busy_ms = 20.0};
        return {.interval_ms = 1000.0 / 60.0, .busy_ms = 13.0};
    }

private:
    void restart(int ramp) {
        since_change_ = 0;
        ramp_ = ramp;
    }

    double last_hz_ = 0.0;
    int since_change_ = 0;
    int ramp_ = kStartRamp;
};

// Một lần phán xét với máy mô phỏng: mỗi khung lấy theo mức hiện hành.
void run_machine_window(core::RateGovernor& governor, RampingMachine& machine) {
    const std::size_t count = frames_to_judge(governor);
    for (std::size_t i = 0; i < count; ++i) {
        const core::FrameSample frame = machine.frame(governor);
        static_cast<void>(governor.note_frame(frame));
    }
}

// Đợt chạy chậm lúc vào cảnh không phải lý do để lùi: máy này giữ 60 ổn khi xung nhịp đã lên.
void ramp_after_start_is_ignored(Context& context) {
    core::RateGovernor governor({.refresh_hz = 60.0, .ceiling_hz = 60});
    RampingMachine machine;
    for (int round = 0; round < 4; ++round) {
        run_machine_window(governor, machine);
    }
    context.expect(near_hz(governor.target_hz(), 60.0), "đợt chạy chậm lúc đầu không làm lùi");
}

// Đã lùi về 30 (xung nhịp hạ, việc thật phình 22 ms): thăm dò lên 60 vẫn phải thành, không khoá ở 30.
void ramp_after_probe_is_ignored(Context& context) {
    core::RateGovernor governor({.refresh_hz = 60.0, .ceiling_hz = 60});
    static_cast<void>(run_window(governor, late_frame(governor)));
    context.expect(near_hz(governor.target_hz(), 30.0), "tiền đề: lùi về 30");
    RampingMachine machine;
    for (int round = 0; round < 14; ++round) {
        run_machine_window(governor, machine);
    }
    context.expect(near_hz(governor.target_hz(), 60.0), "máy đủ sức thì lên lại 60 và giữ được");
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
    Case{.name = "far_failed_probe_is_not_retried", .body = &far_failed_probe_is_not_retried},
    Case{.name = "start_window_is_not_a_probe", .body = &start_window_is_not_a_probe},
    Case{.name = "ramp_after_start_is_ignored", .body = &ramp_after_start_is_ignored},
    Case{.name = "ramp_after_probe_is_ignored", .body = &ramp_after_probe_is_ignored},
    Case{.name = "refresh_change_restarts", .body = &refresh_change_restarts},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "governor_tests: mọi ca phải qua");
    return 0;
}
