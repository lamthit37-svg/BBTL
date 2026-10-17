/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/stages.cpp
 *  PHÂN HỆ   : Core / Stages
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt StageStats, StageClock và vùng ATrace (core/stages.hpp). ATrace
 *    nằm trong libandroid (API 23); máy chưa bật ghi vết thì hai lời gọi gần
 *    như không tốn gì.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/stages.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <numeric>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#ifdef __ANDROID__
#include <android/trace.h>
#endif

namespace game::core {
namespace {

[[nodiscard]] bool is_valid_ms(double value) noexcept {
    return std::isfinite(value) && value >= 0.0;
}

[[nodiscard]] double millis_since(Clock::time_point from, Clock::time_point until) noexcept {
    return std::chrono::duration<double, std::milli>(until - from).count();
}

} // namespace

StageStats::StageStats(std::size_t stages) : sums_(stages, 0.0) {}

bool StageStats::add(std::span<const double> stage_ms) {
    if (stage_ms.size() != sums_.size()) return false;
    if (!std::ranges::all_of(stage_ms, is_valid_ms)) return false;
    for (std::size_t index = 0; index < stage_ms.size(); ++index) {
        sums_[index] += stage_ms[index];
    }
    const double total = std::accumulate(stage_ms.begin(), stage_ms.end(), 0.0);
    totals_.at(frames_ % kWindow) = total;
    ++frames_;
    return true;
}

double StageStats::mean(std::size_t stage) const noexcept {
    if (frames_ == 0 || stage >= sums_.size()) return 0.0;
    return sums_[stage] / static_cast<double>(frames_);
}

// Phân vị theo hạng gần nhất trên cửa sổ: khi chưa đầy cửa sổ thì chỉ các ô đầu đã có số.
double StageStats::total_percentile(double share) const {
    if (frames_ == 0) return 0.0;
    const std::uint64_t window = std::min<std::uint64_t>(frames_, kWindow);
    const auto count = static_cast<std::size_t>(window);
    const auto first = totals_.begin();
    std::vector<double> sorted(first, first + static_cast<std::ptrdiff_t>(count));
    const double clamped = std::clamp(share, 0.0, 1.0);
    const double position = std::round(clamped * static_cast<double>(count - 1));
    const auto rank = static_cast<std::ptrdiff_t>(position);
    std::ranges::nth_element(sorted, sorted.begin() + rank);
    return sorted[static_cast<std::size_t>(rank)];
}

std::string describe(std::string_view label, std::span<const char* const> names,
    const StageStats& stats) {
    if (stats.frames() == 0 || names.size() != stats.stages()) return {};
    std::string line(label);
    line += ": ";
    for (std::size_t index = 0; index < names.size(); ++index) {
        const std::string_view separator = index == 0 ? "" : ", ";
        const std::string_view name = names[index];
        line += std::format("{}{} {:.2f}", separator, name, stats.mean(index));
    }
    const double median = stats.total_percentile(0.5);
    const double high = stats.total_percentile(0.95);
    line += std::format(" ms; tổng trung vị {:.2f}, p95 {:.2f} ms", median, high);
    line += std::format(" ({} khung)", stats.frames());
    return line;
}

StageClock::StageClock(std::span<const char* const> names)
    : names_(names), stats_(names.size()), laps_(names.size(), 0.0) {}

// Khung trước chưa end (chỗ gọi thoát sớm vì lỗi): đóng vùng ATrace còn mở rồi bắt đầu lại.
void StageClock::begin() noexcept {
    if (names_.empty()) return;
    const bool is_open = is_running_ && stage_ < names_.size();
    if (is_open) trace_end();
    stage_ = 0;
    is_running_ = true;
    last_ = Clock::now();
    trace_begin(names_.front());
}

// Vùng ATrace chỉ mở khi stage_ còn trong số chặng, nên chỉ đóng khi ấy: next thừa không làm lệch
// cặp begin và end của ATrace.
void StageClock::next() noexcept {
    if (!is_running_) return;
    const Clock::time_point now = Clock::now();
    const bool is_open = stage_ < names_.size();
    if (is_open) trace_end();
    if (is_open) laps_[stage_] = millis_since(last_, now);
    ++stage_;
    last_ = now;
    if (stage_ < names_.size()) trace_begin(names_[stage_]);
}

void StageClock::end() {
    if (!is_running_) return;
    next();
    is_running_ = false;
    // laps_ luôn đủ số chặng và là khoảng của đồng hồ đơn điệu, nên add không bỏ khung nào ở đây.
    if (stage_ == names_.size()) stats_.add(laps_);
}

void trace_begin(const char* name) noexcept {
#ifdef __ANDROID__
    ATrace_beginSection(name);
#else
    static_cast<void>(name);
#endif
}

void trace_end() noexcept {
#ifdef __ANDROID__
    ATrace_endSection();
#endif
}

} // namespace game::core
