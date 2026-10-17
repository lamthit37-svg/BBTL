/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/cadence.cpp
 *  PHÂN HỆ   : Core / Cadence
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lưới nhịp quét của FifoCadence: acquire phải chờ thì neo lưới vào mốc đó,
 *    acquire không chờ thì đếm nhịp từ mốc lưới của khung trước.
 *  - PacedClock tiến mốc hoạt hoạ đúng số nhịp lưới đếm, neo lại khi lệch xa
 *    lúc thức, không lùi.
 *  - Không cấp phát, không ném; mọi số vào đều đã chặn biên trước khi đổi kiểu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/cadence.hpp"

#include <algorithm>
#include <cmath>

namespace game::core {
namespace {

constexpr double kUnknownRefreshHz = 60.0;
// Tới muộn quá một phần tư nhịp mới là màn lặp ảnh. Mốc acquire phải chờ dao động ±1,5 ms quanh
// lúc màn thay ảnh (đo TB-X306F); phần tư nhịp 60 Hz là 4,2 ms. Đối chiếu với SurfaceFlinger:
// 0 khớp ít hơn (dao động thành lỡ giả), nửa nhịp bỏ sót khung lặp thật.
constexpr double kSlack = 0.25;
// Hai lần chờ cách nhau quá 8 nhịp thì bỏ: giữa đó máy chạy không chờ, làm tròn dễ lệch một nhịp.
constexpr double kMostGap = 8.0;
// Quãng lệch số nhịp nguyên quá 0,15 nhịp thì một đầu không phải nút lưới (acquire chờ GPU hay
// fence, trả về giữa hai nhịp): làm tròn sẽ sai cả nhịp. Dao động ±1,5 ms ở hai đầu ít khi chạm
// ngưỡng, và loại đối xứng hai phía nên không làm lệch trung bình.
constexpr double kMostOffGrid = 0.15;
// Đủ 300 nhịp (5 giây ở 60 Hz) mới tin chu kỳ đo được; quá 3600 thì giảm một nửa trọng số cũ để
// theo kịp khi màn đổi chế độ.
constexpr double kTrustRefreshes = 300.0;
constexpr double kForgetRefreshes = 3600.0;
// Chu kỳ đo lệch quá 2% so với số hệ điều hành báo là đo sai, không phải màn lệch chuẩn.
constexpr double kMostDrift = 0.02;
// Trần số nhịp của một khung (10 giây ở 60 Hz): khung treo không làm tràn uint32.
constexpr double kMostRefreshes = 600.0;

[[nodiscard]] std::uint32_t whole_refreshes(double refreshes) noexcept {
    const double bounded = std::clamp(refreshes, 1.0, kMostRefreshes);
    return static_cast<std::uint32_t>(bounded);
}

[[nodiscard]] double period_of(double refresh_hz) noexcept {
    const bool is_known = std::isfinite(refresh_hz) && refresh_hz > 0.0;
    const double rate = is_known ? refresh_hz : kUnknownRefreshHz;
    return 1000.0 / rate;
}

} // namespace

FifoCadence::FifoCadence(double refresh_hz) noexcept
    : nominal_ms_(period_of(refresh_hz)), period_ms_(nominal_ms_) {}

void FifoCadence::reset() noexcept {
    grid_ms_.reset();
    last_wait_ms_.reset();
}

// Acquire phải chờ: ảnh nhả lúc màn thay ảnh, nên mốc này là một nút lưới thật. Khoảng tới nút
// trước làm tròn ra số nhịp, rồi neo lưới vào mốc này để sai số chu kỳ không cộng dồn. Acquire
// không chờ: vòng lặp tới sau lúc ảnh được nhả, chỉ biết khung đã muộn bao nhiêu so với nút kế.
ShownSpan FifoCadence::note(AcquireNote frame) noexcept {
    // Mốc hỏng (NaN, vô cực) không vào lưới: NaN đổi sang số nguyên là UB, lưới NaN hỏng mãi.
    if (!std::isfinite(frame.at_ms)) return {.refreshes = 1, .interval_ms = period_ms_};
    if (frame.waited) learn_period(frame.at_ms);
    if (!grid_ms_) {
        grid_ms_ = frame.at_ms;
        return {.refreshes = 1, .interval_ms = period_ms_};
    }
    const double phase = (frame.at_ms - *grid_ms_) / period_ms_;
    const double counted = frame.waited ? std::round(phase) : std::ceil(phase - kSlack);
    const std::uint32_t refreshes = whole_refreshes(counted);
    const double shown_ms = static_cast<double>(refreshes) * period_ms_;
    // Khung treo quá trần: lưới neo lại ở mốc này, nếu không khung kế cũng bị tính là treo.
    const bool is_stalled = counted > kMostRefreshes;
    const double advanced = is_stalled ? frame.at_ms : *grid_ms_ + shown_ms;
    grid_ms_ = frame.waited ? frame.at_ms : advanced;
    return {.refreshes = refreshes, .interval_ms = shown_ms};
}

// Chu kỳ = tổng các quãng giữa hai lần chờ liền nhau chia tổng số nhịp của chúng. Hai đầu mỗi
// quãng đều là nút lưới thật nên dao động chỉ còn ở hai đầu, không cộng theo số khung.
void FifoCadence::learn_period(double at_ms) noexcept {
    const std::optional<double> previous = last_wait_ms_;
    last_wait_ms_ = at_ms;
    if (!previous) return;
    const double gap_ms = at_ms - *previous;
    const double ratio = gap_ms / period_ms_;
    const double refreshes = std::round(ratio);
    const bool is_on_grid = std::abs(ratio - refreshes) <= kMostOffGrid;
    const bool is_usable = refreshes >= 1.0 && refreshes <= kMostGap && is_on_grid;
    if (!is_usable) return;
    span_ms_ += gap_ms;
    span_refreshes_ += refreshes;
    const double keep = span_refreshes_ > kForgetRefreshes ? 0.5 : 1.0;
    span_ms_ *= keep;
    span_refreshes_ *= keep;
    if (span_refreshes_ < kTrustRefreshes) return;
    const double measured = span_ms_ / span_refreshes_;
    const double drift = std::abs((measured / nominal_ms_) - 1.0);
    if (drift > kMostDrift) return;
    period_ms_ = measured;
}

PacedClock::PacedClock(double most_lead_ms) noexcept
    : most_lead_ms_(std::isfinite(most_lead_ms) ? std::max(most_lead_ms, 0.0) : 0.0) {}

void PacedClock::reset() noexcept {
    is_stepping_ = false;
}

// Neo vào lúc thức nhưng không lùi sau mốc đã trả.
double PacedClock::anchor(double woke_ms) noexcept {
    const double anchored = latest_ms_ ? std::max(woke_ms, *latest_ms_) : woke_ms;
    latest_ms_ = anchored;
    is_stepping_ = true;
    ++anchors_;
    return anchored;
}

double PacedClock::next(double woke_ms, std::optional<double> shown_ms) noexcept {
    // Lúc thức hỏng thì giữ mốc cũ: NaN vào lưới thì mọi khung sau hỏng theo.
    if (!std::isfinite(woke_ms)) return latest_ms_.value_or(0.0);
    const bool has_step = shown_ms && std::isfinite(*shown_ms) && *shown_ms > 0.0;
    const bool can_step = has_step && is_stepping_ && latest_ms_.has_value();
    if (!can_step) return anchor(woke_ms);
    const double stepped = *latest_ms_ + *shown_ms;
    if (std::abs(stepped - woke_ms) > most_lead_ms_) return anchor(woke_ms);
    latest_ms_ = stepped;
    ++steps_;
    return stepped;
}

} // namespace game::core
