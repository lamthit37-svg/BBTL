// Đồng hồ, giấc ngủ, lịch tick. Thay ITime/WindowsTime.c/Timer.c và threadSleep của _Ref.
// steady_clock của MSVC đọc QueryPerformanceCounter, nên getUSec, getTimerFrequency, int64MulDiv
// không cần bản riêng; thời gian thực dùng system_clock (getTimeSinceStart của gốc trả time(NULL)).
// Timer mili giây (timeGetTime, quấn sau 49,7 ngày) và HiresTimer gộp thành Stopwatch. threadSleep
// của gốc là Sleep(ms), tròn theo nhịp 15,6 ms; ở đây có sleep_for chỉ hẹn giờ và sleep_until quay
// đoạn cuối. FixedStep là lịch tick số hữu tỉ như VnS và No1, _Ref không có.
// Nguồn: Forge2 src/core/clock.hpp@d7fcd76. Khác gốc: bỏ {} thừa của thành viên anchor_.
#pragma once

#include "core/error.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>

namespace game::core {

using Clock = std::chrono::steady_clock;

// Một đồng hồ, một luồng (như HiresTimer của _Ref): lap và reset ghi trạng thái không khoá.
class Stopwatch {
public:
    // Số lap nhớ để tính trung bình (HIRES_TIMER_LENGTH_OF_HISTORY của _Ref).
    static constexpr std::size_t kHistory = 60;

    // Thời gian từ mốc, không ghi lịch sử.
    [[nodiscard]] Clock::duration elapsed() const noexcept { return Clock::now() - start_; }

    // Thời gian từ mốc, ghi vào lịch sử, đặt lại mốc (getHiresTimerUSec(reset = true) của _Ref).
    Clock::duration lap() noexcept {
        const Clock::time_point now = Clock::now();
        const Clock::duration span = now - start_;
        start_ = now;
        history_.at(next_) = span;
        next_ = (next_ + 1) % kHistory;
        count_ = count_ < kHistory ? count_ + 1 : kHistory;
        return span;
    }

    void reset() noexcept { start_ = Clock::now(); }

    // Trung bình các lap đã ghi, tối đa kHistory lap gần nhất; 0 khi chưa có lap. _Ref luôn chia 60
    // kể cả khi mới có vài mẫu, nên trung bình của giây đầu tiên bị kéo về gần 0.
    [[nodiscard]] Clock::duration average() const noexcept {
        if (count_ == 0) return Clock::duration::zero();
        Clock::duration total = Clock::duration::zero();
        for (std::size_t i = 0; i < count_; ++i) {
            total += history_.at(i);
        }
        return total / static_cast<Clock::rep>(count_);
    }

private:
    Clock::time_point start_ = Clock::now();
    std::array<Clock::duration, kHistory> history_{};
    std::size_t next_ = 0;
    std::size_t count_ = 0;
};

// Thời gian từ lúc hệ điều hành tạo tiến trình tới giờ. Mốc nạp ghi bằng đồng hồ này so thẳng được với số đo từ
// ngoài (TOOLS/run/launch_timeline.py) và với client khác. Windows: GetProcessTimes; nền tảng khác: tính từ
// lúc thư viện core nạp, vài ms sau exec.
[[nodiscard]] std::chrono::microseconds process_age() noexcept;

// Giây dạng float cho vòng lặp khung hình (getHiresTimerSeconds của _Ref).
[[nodiscard]] inline float seconds(Clock::duration span) noexcept {
    return std::chrono::duration<float>(span).count();
}

// Đoạn cuối của sleep_until được quay thay vì hẹn giờ. Cố định: p99 thức muộn của bộ hẹn giờ đo
// trên máy này là 500–750 µs (docs/modules/core.md). Lề tự học đã thua ở cả No1 lẫn phép thử của
// Forge2: CPU giảm nhưng p99 lệch hạn tăng vì lề trôi xuống dưới lần thức muộn thật.
inline constexpr Clock::duration kSpinMargin = std::chrono::milliseconds(1);

// Ngủ ít nhất span, chỉ hẹn giờ, gần như không tốn CPU; trễ theo lần thức muộn của hệ điều hành.
void sleep_for(Clock::duration span) noexcept;

// Ngủ tới deadline, không bao giờ về sớm: hẹn giờ tới deadline - kSpinMargin rồi quay, luồng tạm ở
// ưu tiên TIME_CRITICAL để luồng thợ phủ kín lõi không làm trễ. Hạn đã qua thì trả về ngay.
void sleep_until(Clock::time_point deadline) noexcept;

// Nhịp mô phỏng và nhịp vẽ theo số CPU logic. Máy yếu mô phỏng 30 Hz và vẽ tới 60.
// Máy vừa mô phỏng 60 và vẽ 60. Máy từ 8 luồng mô phỏng 60 và vẽ tới 120.
struct LoopPlan {
    std::uint32_t sim_hz = 60;
    std::uint32_t render_hz = 120;
};

[[nodiscard]] constexpr LoopPlan loop_plan(std::uint32_t logical_cpus) noexcept {
    if (logical_cpus >= 8) return {.sim_hz = 60, .render_hz = 120};
    if (logical_cpus >= 4) return {.sim_hz = 60, .render_hz = 60};
    return {.sim_hz = 30, .render_hz = 60};
}

struct TickConfig {
    std::uint32_t hz = 60;
    // Số bước tối đa mỗi lần advance: 10 bước ở 60 Hz bù được 166 ms trong một vòng; nhiều hơn thì
    // một lần khựng nhỏ thành một lần khựng dài (vòng xoáy tử thần).
    std::uint32_t max_steps = 10;
};

// Lịch tick bước cố định đúng theo số hữu tỉ: tick thứ n rơi vào ceil(n * 10^9 / hz) ns sau mốc,
// không có bước làm tròn nào để trôi (một giờ ở 60 Hz là đúng 216 000 tick). Phần vượt max_steps
// đếm vào dropped, lịch vẫn neo mốc nên nhịp sau không lệch pha. Một lịch, một luồng.
class FixedStep {
public:
    // Trên mức này hai tick có thể rơi vào cùng một nano giây.
    static constexpr std::uint32_t kMaxHz = 1'000'000'000;

    // Từ chối hz ngoài 1..kMaxHz và max_steps bằng 0.
    [[nodiscard]] static Result<FixedStep> create(TickConfig config) noexcept;

    // Số bước mô phỏng phải chạy bây giờ. Lần đầu chỉ đặt mốc và trả 0.
    [[nodiscard]] std::uint32_t advance(Clock::time_point now) noexcept;

    // Mốc của tick kế, để đưa vào sleep_until. Rỗng trước lần advance đầu hay khi vượt đồng hồ.
    [[nodiscard]] std::optional<Clock::time_point> next_tick() const noexcept;

    // Phần lẻ giữa hai tick, trong [0, 1), để nội suy khi vẽ. Không dùng trong mô phỏng.
    [[nodiscard]] float alpha() const noexcept { return alpha_; }
    [[nodiscard]] std::uint32_t hz() const noexcept { return config_.hz; }
    // Bước mô phỏng đúng 1/hz giây; bước tính bằng nano giây thì phải làm tròn.
    [[nodiscard]] double step_seconds() const noexcept { return 1.0 / config_.hz; }
    // Số bước đã chạy.
    [[nodiscard]] std::uint64_t ticks() const noexcept { return ticks_; }
    // Số chỗ trong lịch bị bỏ; khác 0 nghĩa là vòng lặp không theo kịp.
    [[nodiscard]] std::uint64_t dropped() const noexcept { return dropped_; }
    [[nodiscard]] bool is_started() const noexcept { return is_started_; }

private:
    explicit FixedStep(TickConfig config) noexcept : config_(config) {}

    // Lần advance đầu: đặt mốc, chưa có bước nào đến hạn.
    [[nodiscard]] std::uint32_t start(Clock::time_point now) noexcept;

    TickConfig config_;
    Clock::time_point anchor_;
    // Số tick đã đến hạn và đã xử lý (chạy hoặc bỏ). Tick kế là scheduled_ + 1.
    std::uint64_t scheduled_ = 0;
    std::uint64_t ticks_ = 0;
    std::uint64_t dropped_ = 0;
    float alpha_ = 0.0F;
    bool is_started_ = false;
};

} // namespace game::core
