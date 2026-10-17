/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Core/cadence_tests.cpp
 *  PHÂN HỆ   : Core / Cadence Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test FifoCadence bằng mốc acquire giả: khung đúng nhịp, khung muộn, nhịp
 *    bị bỏ, dao động trong dung sai, tự đo chu kỳ thật, mốc hỏng và khung treo.
 *  - Màn giả chạy 59,87 Hz như TB-X306F trong khi hệ điều hành báo 60.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/cadence.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <limits>
#include <optional>

namespace game::test {
namespace {

// Chu kỳ màn thật của TB-X306F, đo bằng SurfaceFlinger 2026-10-17; hệ điều hành báo 60,000 Hz.
constexpr double kRealMs = 16.703;
constexpr double kReportedHz = 60.0;

[[nodiscard]] core::AcquireNote waited_at(double at_ms) {
    return {.at_ms = at_ms, .waited = true};
}

[[nodiscard]] core::AcquireNote free_at(double at_ms) {
    return {.at_ms = at_ms, .waited = false};
}

// Số khung mà mô hình báo màn đã lặp ảnh, khi mọi acquire đều chờ đúng nút lưới thật.
[[nodiscard]] std::size_t repeats_on_real_grid(core::FifoCadence& cadence, std::size_t frames) {
    std::size_t repeats = 0;
    for (std::size_t i = 0; i < frames; ++i) {
        // Dao động ±1 ms quanh lúc màn thay ảnh, như mốc acquire đo trên tablet.
        const double wobble = (i % 2 == 0) ? 1.0 : -1.0;
        const double at_ms = (static_cast<double>(i) * kRealMs) + wobble;
        const core::ShownSpan span = cadence.note(waited_at(at_ms));
        if (span.refreshes > 1) ++repeats;
    }
    return repeats;
}

void steady_waits_show_one_refresh(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    const std::size_t repeats = repeats_on_real_grid(cadence, 600);
    context.expect(repeats == 0, "acquire chờ đúng nhịp thì mọi khung lên màn một nhịp");
}

void learns_the_real_period(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    context.expect(std::abs(cadence.period_ms() - (1000.0 / 60.0)) < 1e-9, "chưa đo thì dùng số báo");
    const std::size_t repeats = repeats_on_real_grid(cadence, 1200);
    context.expect(repeats == 0, "chu kỳ báo lệch 0,2% không sinh khung lặp giả");
    context.expect(std::abs(cadence.period_ms() - kRealMs) < 0.005, "đo ra chu kỳ thật 16,703 ms");
}

void late_arrival_counts_repeats(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    const double period = cadence.period_ms();
    static_cast<void>(cadence.note(free_at(0.0)));
    const core::ShownSpan on_time = cadence.note(free_at(period));
    context.expect(on_time.refreshes == 1, "khung đúng nhịp: một nhịp");
    const core::ShownSpan late = cadence.note(free_at((2.0 * period) + (0.4 * period)));
    context.expect(late.refreshes == 2, "muộn 0,4 nhịp: màn lặp ảnh một lần");
    context.expect(std::abs(late.interval_ms - (2.0 * period)) < 1e-9, "khoảng là hai nhịp");
    const core::ShownSpan back = cadence.note(free_at(4.0 * period));
    context.expect(back.refreshes == 1, "khung kế về đúng lưới: một nhịp");
    const core::ShownSpan stall = cadence.note(free_at(8.5 * period));
    context.expect(stall.refreshes == 5, "tới sau khung trước 4,5 nhịp: màn giữ khung trước năm nhịp");
}

void jitter_within_slack_is_on_time(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    const double period = cadence.period_ms();
    std::size_t repeats = 0;
    for (std::size_t i = 0; i < 300; ++i) {
        // Khung đầu đúng nút lưới, sau đó so le ±3,5 ms (dưới một phần tư nhịp, 4,2 ms).
        const double swing = (i % 2 == 0) ? 3.5 : -3.5;
        const double wobble = i == 0 ? 0.0 : swing;
        const double at_ms = (static_cast<double>(i) * period) + wobble;
        const core::ShownSpan span = cadence.note(free_at(at_ms));
        if (span.refreshes > 1) ++repeats;
    }
    context.expect(repeats == 0, "vòng lặp so le ±3,5 ms mà vẫn kịp nhịp thì không lặp ảnh");
}

void skipped_release_counts_two(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    const double period = cadence.period_ms();
    static_cast<void>(cadence.note(waited_at(0.0)));
    static_cast<void>(cadence.note(waited_at(period)));
    const core::ShownSpan skipped = cadence.note(waited_at(3.0 * period));
    context.expect(skipped.refreshes == 2, "ảnh nhả muộn một nhịp: màn đã giữ khung trước hai nhịp");
    const core::ShownSpan early = cadence.note(waited_at(3.2 * period));
    context.expect(early.refreshes == 1, "acquire chờ mà sớm hơn lưới: một nhịp, lưới neo lại");
}

void unknown_refresh_is_sixty(Context& context) {
    const double sixty = 1000.0 / 60.0;
    const core::FifoCadence zero(0.0);
    const core::FifoCadence nan(std::numeric_limits<double>::quiet_NaN());
    const core::FifoCadence negative(-90.0);
    context.expect(std::abs(zero.period_ms() - sixty) < 1e-9, "0 Hz thì coi là 60");
    context.expect(std::abs(nan.period_ms() - sixty) < 1e-9, "NaN thì coi là 60");
    context.expect(std::abs(negative.period_ms() - sixty) < 1e-9, "số âm thì coi là 60");
}

void reset_starts_a_new_grid(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    static_cast<void>(cadence.note(free_at(0.0)));
    static_cast<void>(cadence.note(free_at(cadence.period_ms())));
    cadence.reset();
    const core::ShownSpan first = cadence.note(free_at(5000.0));
    context.expect(first.refreshes == 1, "sau reset, khung đầu là một nhịp dù cách 5 giây");
}

void stall_and_bad_time_are_bounded(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    static_cast<void>(cadence.note(free_at(0.0)));
    const core::ShownSpan stall = cadence.note(free_at(1e9));
    context.expect(stall.refreshes == 600, "khung treo bị chặn ở 600 nhịp");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const core::ShownSpan broken = cadence.note(free_at(nan));
    context.expect(broken.refreshes == 1, "mốc NaN tính một nhịp");
    const double after_ms = 1e9 + cadence.period_ms();
    const core::ShownSpan after = cadence.note(free_at(after_ms));
    context.expect(after.refreshes == 1, "mốc NaN không làm hỏng lưới");
}

void wild_period_is_rejected(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    for (std::size_t i = 0; i < 1000; ++i) {
        const double at_ms = static_cast<double>(i) * 20.0;
        static_cast<void>(cadence.note(waited_at(at_ms)));
    }
    const double sixty = 1000.0 / 60.0;
    context.expect(std::abs(cadence.period_ms() - sixty) < 1e-9, "lệch 20% là đo sai, giữ số báo");
}

// Acquire chờ vì lý do khác lúc màn thay ảnh (GPU nghẽn, fence) trả về giữa hai nhịp. Cặp có một
// đầu như thế làm tròn sai một nhịp; không loại thì chu kỳ đo lệch 8% và bị bỏ cả.
void off_grid_waits_are_skipped(Context& context) {
    core::FifoCadence cadence(kReportedHz);
    for (std::size_t i = 0; i < 1500; ++i) {
        const double shift = (i % 5 == 4) ? 0.6 : 0.0;
        const double at_ms = (static_cast<double>(i) + shift) * kRealMs;
        static_cast<void>(cadence.note(waited_at(at_ms)));
    }
    context.expect(std::abs(cadence.period_ms() - kRealMs) < 0.005, "vẫn đo ra chu kỳ thật");
}

// Lúc thức dao động ±6 ms quanh lưới như vòng lặp trên tablet; mỗi khung màn giữ một nhịp.
[[nodiscard]] double woke_on_real_grid(std::size_t frame) {
    constexpr std::array<double, 3> kWobble{6.0, -5.0, 1.0};
    return (static_cast<double>(frame) * kRealMs) + kWobble.at(frame % kWobble.size());
}

void paced_steps_are_whole_periods(Context& context) {
    core::PacedClock clock(50.0);
    double previous = clock.next(woke_on_real_grid(0), std::nullopt);
    std::size_t uneven = 0;
    for (std::size_t frame = 1; frame < 600; ++frame) {
        const double now = clock.next(woke_on_real_grid(frame), kRealMs);
        if (std::abs((now - previous) - kRealMs) > 1e-9) ++uneven;
        previous = now;
    }
    context.expect(uneven == 0, "lúc thức lệch ±6 ms mà mỗi khung vẫn tiến đúng một chu kỳ");
}

void paced_late_frame_steps_two(Context& context) {
    core::PacedClock clock(50.0);
    const double first = clock.next(0.0, std::nullopt);
    const double second = clock.next(kRealMs + 3.0, kRealMs);
    const double third = clock.next((3.0 * kRealMs) - 2.0, 2.0 * kRealMs);
    context.expect(std::abs(second - first - kRealMs) < 1e-9, "khung đúng hẹn: một chu kỳ");
    context.expect(std::abs(third - second - (2.0 * kRealMs)) < 1e-9, "màn lặp ảnh: hai chu kỳ");
}

void paced_reanchors_without_going_back(Context& context) {
    core::PacedClock clock(50.0);
    static_cast<void>(clock.next(0.0, std::nullopt));
    const double stalled = clock.next(500.0, kRealMs);
    context.expect(std::abs(stalled - 500.0) < 1e-9, "treo lâu: neo vào lúc thức");
    const double ahead = clock.next(520.0, 200.0);
    context.expect(std::abs(ahead - 520.0) < 1e-9, "lưới đếm vượt xa: neo vào lúc thức");
    clock.reset();
    const double after_reset = clock.next(510.0, kRealMs);
    context.expect(after_reset >= ahead, "neo lại sau reset không lùi");
}

void paced_bad_input_is_ignored(Context& context) {
    core::PacedClock clock(50.0);
    const double first = clock.next(100.0, std::nullopt);
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double kept = clock.next(nan, kRealMs);
    context.expect(std::abs(kept - first) < 1e-9, "lúc thức NaN giữ mốc cũ");
    const double anchored = clock.next(100.0 + kRealMs, nan);
    context.expect(std::abs(anchored - (100.0 + kRealMs)) < 1e-9, "bước NaN thì neo vào lúc thức");
    const double negative = clock.next(100.0 + (2.0 * kRealMs), -kRealMs);
    context.expect(negative > anchored, "bước âm không làm mốc lùi");
}

constexpr std::array kCases{
    Case{.name = "steady_waits_show_one_refresh", .body = &steady_waits_show_one_refresh},
    Case{.name = "learns_the_real_period", .body = &learns_the_real_period},
    Case{.name = "late_arrival_counts_repeats", .body = &late_arrival_counts_repeats},
    Case{.name = "jitter_within_slack_is_on_time", .body = &jitter_within_slack_is_on_time},
    Case{.name = "skipped_release_counts_two", .body = &skipped_release_counts_two},
    Case{.name = "unknown_refresh_is_sixty", .body = &unknown_refresh_is_sixty},
    Case{.name = "reset_starts_a_new_grid", .body = &reset_starts_a_new_grid},
    Case{.name = "stall_and_bad_time_are_bounded", .body = &stall_and_bad_time_are_bounded},
    Case{.name = "wild_period_is_rejected", .body = &wild_period_is_rejected},
    Case{.name = "off_grid_waits_are_skipped", .body = &off_grid_waits_are_skipped},
    Case{.name = "paced_steps_are_whole_periods", .body = &paced_steps_are_whole_periods},
    Case{.name = "paced_late_frame_steps_two", .body = &paced_late_frame_steps_two},
    Case{.name = "paced_reanchors_without_going_back", .body = &paced_reanchors_without_going_back},
    Case{.name = "paced_bad_input_is_ignored", .body = &paced_bad_input_is_ignored},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "cadence_tests: mọi ca phải qua");
    return 0;
}
