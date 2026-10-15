#include "core/governor.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace game::core {
namespace {

constexpr double kFloorHz = 30.0;
// Mức vững để bắt đầu: máy chưa chứng minh được gì thì không hứa quá 60 khung.
constexpr double kStartHz = 60.5;
// Khung trễ là khung dài hơn ngân sách 25%; quá 10% số khung trễ thì mức này không giữ nổi, dưới 2% thì giữ vững.
constexpr double kLateFactor = 1.25;
constexpr double kLateShare = 0.10;
constexpr double kSteadyShare = 0.02;
// Việc thật quá 70% ngân sách mức cao hơn thì không dư sức; chấp nhận 5% khung như thế (một lần nạp, một lần dựng lại).
constexpr double kHeadroom = 0.7;
constexpr double kHeavyShare = 0.05;
constexpr std::uint32_t kMostBackoff = 16;
constexpr std::uint32_t kFirstBackoff = 4;
constexpr double kUnknownRefreshHz = 60.0;

[[nodiscard]] double budget_ms(double rate) noexcept {
    return 1000.0 / rate;
}

} // namespace

RateGovernor::RateGovernor(GovernorConfig config) noexcept : config_(config) {
    build(config.refresh_hz);
}

void RateGovernor::fill_tiers(double refresh_hz) noexcept {
    const bool is_known = std::isfinite(refresh_hz) && refresh_hz > 0.0;
    const double refresh = is_known ? refresh_hz : kUnknownRefreshHz;
    const double ceiling = static_cast<double>(std::max<std::uint32_t>(config_.ceiling_hz, 1U)) + 0.5;
    count_ = 0;
    for (std::size_t divisor = 1; divisor <= tiers_.size(); ++divisor) {
        const double rate = refresh / static_cast<double>(divisor);
        if (rate < kFloorHz - 0.5 || rate > ceiling) continue;
        tiers_.at(count_) = rate;
        ++count_;
    }
    // Màn dưới 30 Hz hay trần dưới mọi mức: một mức duy nhất là chính tần số quét.
    if (count_ > 0) return;
    tiers_.at(0) = std::min(refresh, ceiling);
    count_ = 1;
}

void RateGovernor::build(double refresh_hz) noexcept {
    fill_tiers(refresh_hz);
    index_ = 0;
    while (index_ + 1 < count_ && tiers_.at(index_) > kStartHz) {
        ++index_;
    }
    is_probing_ = false;
    hold_ = 0;
    backoff_ = kFirstBackoff;
    restart_window();
}

void RateGovernor::restart_window() noexcept {
    frames_ = 0;
    late_ = 0;
    heavy_ = 0;
}

void RateGovernor::set_refresh(double refresh_hz) noexcept {
    config_.refresh_hz = refresh_hz;
    build(refresh_hz);
}

bool RateGovernor::note_frame(FrameSample frame) noexcept {
    const double budget = budget_ms(target_hz());
    if (frame.interval_ms > budget * kLateFactor) ++late_;
    if (index_ > 0 && frame.busy_ms > budget_ms(tiers_.at(index_ - 1)) * kHeadroom) ++heavy_;
    ++frames_;
    if (frames_ < kWindow) return false;
    return judge();
}

// Lùi một mức. Thăm dò hỏng: lần sau lùi lâu hơn. Mức đang giữ mà trễ (máy nóng, cảnh nặng hơn): chờ ngắn rồi thăm dò lại.
void RateGovernor::step_down() noexcept {
    ++index_;
    if (is_probing_) {
        backoff_ = std::min(backoff_ * 2, kMostBackoff);
        hold_ = backoff_;
    } else {
        hold_ = std::max(hold_, kFirstBackoff);
    }
    is_probing_ = false;
}

bool RateGovernor::can_step_up(double late, double heavy) const noexcept {
    return hold_ == 0 && index_ > 0 && late <= kSteadyShare && heavy <= kHeavyShare;
}

// Hết một cửa sổ: lùi nếu trễ nhiều, thăm dò lên nếu vững và còn dư sức, không thì giữ.
bool RateGovernor::judge() noexcept {
    const auto window = static_cast<double>(kWindow);
    const double late = static_cast<double>(late_) / window;
    const double heavy = static_cast<double>(heavy_) / window;
    const std::size_t before = index_;
    if (late > kLateShare && index_ + 1 < count_) {
        step_down();
    } else if (can_step_up(late, heavy)) {
        --index_;
        is_probing_ = true;
    } else {
        // Cửa sổ thăm dò đã qua mà không lùi: mức mới vững, quên lần hỏng cũ. Đang chờ thì đếm lùi.
        if (hold_ > 0) --hold_;
        if (is_probing_) backoff_ = kFirstBackoff;
        is_probing_ = false;
    }
    restart_window();
    return index_ != before;
}

} // namespace game::core
