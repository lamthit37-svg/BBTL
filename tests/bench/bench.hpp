// Khung đo chung của tests/bench/*.cpp (đề bài P2 đợt 2, mục 7, Đ1 tới Đ3): đồng hồ đơn điệu, tốc
// độ, phân vị của mẫu micro giây. Exe đo không vào ctest và in một dòng TSV mỗi lượt; trung vị, nhỏ
// nhất, lớn nhất của năm lượt tính khi ghi số đo vào so-do/.
#pragma once

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <span>
#include <vector>

namespace game::bench {

using Clock = std::chrono::steady_clock;

[[nodiscard]] inline double seconds_between(Clock::time_point start, Clock::time_point stop) noexcept {
    return std::chrono::duration<double>(stop - start).count();
}

[[nodiscard]] inline double micros_between(Clock::time_point start, Clock::time_point stop) noexcept {
    return std::chrono::duration<double, std::micro>(stop - start).count();
}

// Số việc mỗi giây; quãng đo bằng 0 thì trả 0 thay vì chia cho 0.
[[nodiscard]] inline double per_second(double count, double seconds) noexcept {
    if (seconds <= 0.0) {
        return 0.0;
    }
    return count / seconds;
}

// Phân vị theo hạng gần nhất, percent trong [0, 100], của mẫu đã sắp tăng; mẫu rỗng trả 0.
[[nodiscard]] inline double percentile(std::span<const double> sorted, double percent) noexcept {
    if (sorted.empty()) {
        return 0.0;
    }
    const double rank = std::ceil(percent / 100.0 * static_cast<double>(sorted.size()));
    const auto index = static_cast<std::size_t>(std::max(rank, 1.0)) - 1;
    return sorted[std::min(index, sorted.size() - 1)];
}

struct Latency {
    double p50 = 0.0;
    double p99 = 0.0;
    double max = 0.0;
};

// p50, p99 và lớn nhất của một lượt đo trễ, tính bằng micro giây.
[[nodiscard]] inline Latency summarize(std::vector<double> micros) {
    std::ranges::sort(micros);
    const double largest = micros.empty() ? 0.0 : micros.back();
    return Latency{.p50 = percentile(micros, 50.0), .p99 = percentile(micros, 99.0), .max = largest};
}

} // namespace game::bench
