/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/stages.hpp
 *  PHÂN HỆ   : Core / Stages
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đo thời gian theo chặng của một vòng lặp (khung hình): StageStats gom số
 *    của nhiều khung (trung bình từng chặng, trung vị và p95 của tổng trên cửa
 *    sổ khung gần nhất), StageClock bấm giờ CPU và mở một vùng ATrace cho mỗi
 *    chặng trên Android để xem bằng Perfetto hoặc Android GPU Inspector.
 *  - Bộ đo cố định thay công tắc đo tạm: không in gì mỗi khung, chỉ in một
 *    dòng tổng kết khi chỗ gọi hỏi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/clock.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::core {

// Thời gian từng chặng của nhiều khung. Tổng của mỗi khung giữ trong cửa sổ kWindow khung gần nhất
// để tính trung vị và p95 mà không lớn dần theo thời gian chạy.
class StageStats {
public:
    static constexpr std::size_t kWindow = 1024;

    explicit StageStats(std::size_t stages);

    // Một khung: ms của từng chặng theo đúng thứ tự chặng. Sai số chặng hoặc có số âm, NaN là lỗi
    // của chỗ gọi nên khung bị bỏ (false), không làm lệch thống kê.
    bool add(std::span<const double> stage_ms);

    [[nodiscard]] std::size_t stages() const noexcept { return sums_.size(); }
    [[nodiscard]] std::uint64_t frames() const noexcept { return frames_; }
    // Trung bình ms của chặng; 0 khi chưa có khung hoặc chặng ngoài biên.
    [[nodiscard]] double mean(std::size_t stage) const noexcept;
    // Phân vị share (0..1) của tổng một khung, trên cửa sổ khung gần nhất; 0 khi chưa có khung.
    [[nodiscard]] double total_percentile(double share) const;

private:
    std::vector<double> sums_;
    std::array<double, kWindow> totals_{};
    std::uint64_t frames_ = 0;
};

// "nhãn: chặng a 1.23, chặng b 0.45 ms; tổng trung vị x, p95 y ms (n khung)". names phải cùng số
// chặng với stats; rỗng khi chưa có khung.
[[nodiscard]] std::string describe(std::string_view label, std::span<const char* const> names,
    const StageStats& stats);

// Bấm giờ CPU theo chặng trên một luồng. begin mở chặng 0, next đóng chặng đang chạy và mở chặng
// kế, end đóng chặng cuối rồi nộp khung. Khung có số lần next khác số chặng bị bỏ. Trên Android
// mỗi chặng là một vùng ATrace mang tên của nó. names mượn: phải sống lâu hơn StageClock (dùng
// mảng hằng).
class StageClock {
public:
    explicit StageClock(std::span<const char* const> names);

    void begin() noexcept;
    void next() noexcept;
    void end();

    [[nodiscard]] const StageStats& stats() const noexcept { return stats_; }

private:
    std::span<const char* const> names_;
    StageStats stats_;
    std::vector<double> laps_;
    Clock::time_point last_;
    std::size_t stage_ = 0;
    bool is_running_ = false;
};

// Vùng ATrace (Android) không gắn với StageClock; name là chuỗi hằng. Nền tảng khác không làm gì.
void trace_begin(const char* name) noexcept;
void trace_end() noexcept;

} // namespace game::core
