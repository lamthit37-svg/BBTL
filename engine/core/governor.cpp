/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/governor.cpp
 *  PHÂN HỆ   : Core / Governor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt RateGovernor (core/governor.hpp): dựng các mức trần từ tần số
 *    quét, đếm khung trễ và khung nặng theo cửa sổ, lùi mức khi trễ, thăm dò
 *    lên khi vững và còn dư sức, lùi gấp đôi thời gian chờ sau lần thăm dò
 *    hỏng.
 *  - Bỏ qua kSettle khung sau mỗi lần đổi mức (kStartSettle lúc bắt đầu):
 *    đợt chạy chậm lúc máy chưa ổn không phải sức máy.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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
// Việc thật quá 1,5 lần ngân sách mức cao hơn thì chắc chắn không kịp; chấp nhận 5% khung như thế
// (một lần nạp, một lần dựng lại). Đo 2026-10-17 trên TB-X306F: ở mức 30 xung nhịp hạ nên việc thật
// phình từ 13 tới 22 ms, mà lên 60 máy vẫn giữ 59,3 khung/giây. Ngưỡng thấp hơn khoá máy ở 30 mãi;
// thăm dò mới là phép đo thật, và thăm dò hỏng đã có lùi gấp đôi.
constexpr double kHeadroom = 1.5;
constexpr double kHeavyShare = 0.05;
constexpr std::uint32_t kMostBackoff = 16;
constexpr std::uint32_t kFirstBackoff = 4;
// Thăm dò mà nửa số khung trễ là mức xa tầm máy, không phải cảnh nặng thoáng qua. 160 cửa sổ là
// 4 phút ở mức 60, 8 phút ở mức 30: một đợt so le mỗi vài phút thay vì mỗi nửa phút.
constexpr double kFarShare = 0.5;
constexpr std::uint32_t kFarHold = 160;
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
    lowest_ = 0;
    far_hold_ = 0;
    settle_ = kStartSettle;
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
    if (settle_ > 0) {
        --settle_;
        return false;
    }
    const double budget = budget_ms(target_hz());
    if (frame.interval_ms > budget * kLateFactor) ++late_;
    if (index_ > 0 && frame.busy_ms > budget_ms(tiers_.at(index_ - 1)) * kHeadroom) ++heavy_;
    ++frames_;
    if (frames_ < kWindow) return false;
    return judge();
}

// Thăm dò vừa hỏng xa tầm: index_ đã lùi về mức dưới mức hỏng.
void RateGovernor::remember_far() noexcept {
    lowest_ = index_;
    far_hold_ = kFarHold;
}

// Mỗi cửa sổ đếm lùi lần nhớ mức xa tầm; hết thì được thăm dò lại mọi mức.
void RateGovernor::count_far_hold() noexcept {
    if (far_hold_ == 0) return;
    --far_hold_;
    if (far_hold_ == 0) lowest_ = 0;
}

// Lùi một mức. Thăm dò hỏng: lần sau lùi lâu hơn. Mức đang giữ mà trễ (máy nóng, cảnh nặng hơn):
// chờ ngắn rồi thăm dò lại.
void RateGovernor::step_down(double late) noexcept {
    ++index_;
    const bool is_far = is_probing_ && late >= kFarShare;
    if (is_far) remember_far();
    if (is_probing_) {
        backoff_ = std::min(backoff_ * 2, kMostBackoff);
        hold_ = backoff_;
    } else {
        hold_ = std::max(hold_, kFirstBackoff);
    }
    is_probing_ = false;
}

bool RateGovernor::can_step_up(double late, double heavy) const noexcept {
    return hold_ == 0 && index_ > lowest_ && late <= kSteadyShare && heavy <= kHeavyShare;
}

// Hết một cửa sổ: lùi nếu trễ nhiều, thăm dò lên nếu vững và còn dư sức, không thì giữ.
bool RateGovernor::judge() noexcept {
    const auto window = static_cast<double>(kWindow);
    const double late = static_cast<double>(late_) / window;
    const double heavy = static_cast<double>(heavy_) / window;
    const std::size_t before = index_;
    count_far_hold();
    if (late > kLateShare && index_ + 1 < count_) {
        step_down(late);
    } else if (can_step_up(late, heavy)) {
        --index_;
        is_probing_ = true;
    } else {
        // Cửa sổ thăm dò đã qua mà không lùi: mức mới vững, quên lần hỏng cũ. Đang chờ thì đếm lùi.
        if (hold_ > 0) --hold_;
        if (is_probing_) backoff_ = kFirstBackoff;
        is_probing_ = false;
    }
    const bool is_changed = index_ != before;
    if (is_changed) settle_ = kSettle;
    restart_window();
    return is_changed;
}

} // namespace game::core
