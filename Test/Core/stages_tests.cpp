// Test của core::StageStats và core::StageClock: trung bình theo chặng, phân vị của tổng trên cửa sổ
// khung gần nhất, khung sai hình dạng bị bỏ thay vì làm lệch số, và đồng hồ chỉ nộp khung đủ chặng.
#include "core/check.hpp"
#include "core/stages.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <limits>
#include <string>

namespace game::test {
namespace {

[[nodiscard]] bool near_ms(double actual, double expected) {
    return std::abs(actual - expected) < 1.0e-9;
}

void means_and_percentiles(Context& context) {
    core::StageStats stats(2);
    context.expect(stats.add(std::array{1.0, 2.0}), "khung đủ hai chặng được nhận");
    context.expect(stats.add(std::array{3.0, 4.0}), "khung thứ hai");
    context.expect(stats.add(std::array{5.0, 6.0}), "khung thứ ba");
    context.expect(stats.frames() == 3, "ba khung");
    context.expect(near_ms(stats.mean(0), 3.0), "trung bình chặng đầu");
    context.expect(near_ms(stats.mean(1), 4.0), "trung bình chặng sau");
    context.expect(near_ms(stats.total_percentile(0.5), 7.0), "trung vị của tổng 3, 7, 11");
    context.expect(near_ms(stats.total_percentile(0.95), 11.0), "p95 lấy hạng gần nhất");
    context.expect(near_ms(stats.total_percentile(0.0), 3.0), "phân vị 0 là nhỏ nhất");
    context.expect(near_ms(stats.mean(2), 0.0), "chặng ngoài biên ra 0");
}

void rejects_malformed_frames(Context& context) {
    core::StageStats stats(2);
    const double not_a_number = std::numeric_limits<double>::quiet_NaN();
    context.expect(!stats.add(std::array{1.0}), "thiếu chặng thì bỏ");
    context.expect(!stats.add(std::array{-1.0, 1.0}), "số âm thì bỏ");
    context.expect(!stats.add(std::array{not_a_number, 1.0}), "NaN thì bỏ");
    context.expect(stats.frames() == 0, "không khung nào lọt vào");
    context.expect(near_ms(stats.total_percentile(0.5), 0.0), "chưa có khung thì phân vị 0");
}

// 1500 khung có tổng 0..1499: cửa sổ 1024 khung giữ 476..1499.
void window_keeps_recent_frames(Context& context) {
    core::StageStats stats(1);
    for (std::size_t index = 0; index < 1500; ++index) {
        const std::array one{static_cast<double>(index)};
        context.expect(stats.add(one), "khung hợp lệ");
    }
    context.expect(stats.frames() == 1500, "đếm mọi khung");
    context.expect(near_ms(stats.total_percentile(0.0), 476.0), "khung cũ đã rời cửa sổ");
    context.expect(near_ms(stats.total_percentile(1.0), 1499.0), "khung mới nhất còn trong cửa sổ");
    context.expect(near_ms(stats.mean(0), 749.5), "trung bình tính trên mọi khung");
}

constexpr std::array<const char*, 3> kNames{"một", "hai", "ba"};

void clock_submits_whole_frames(Context& context) {
    core::StageClock clock(kNames);
    clock.begin();
    clock.next();
    clock.next();
    clock.end();
    context.expect(clock.stats().frames() == 1, "đủ ba chặng thì nộp");
    clock.begin();
    clock.next();
    clock.end();
    context.expect(clock.stats().frames() == 1, "thiếu chặng thì không nộp");
    clock.begin();
    clock.next();
    clock.next();
    clock.next();
    clock.end();
    context.expect(clock.stats().frames() == 1, "thừa chặng thì không nộp");
    clock.end();
    context.expect(clock.stats().frames() == 1, "end khi không chạy thì không làm gì");
    context.expect(clock.stats().mean(2) >= 0.0, "thời gian không âm");
}

// Khung bỏ dở (begin rồi begin lại, như khi draw_world thoát sớm vì lỗi) không làm hỏng khung sau.
void clock_restarts_after_abandoned_frame(Context& context) {
    core::StageClock clock(kNames);
    clock.begin();
    clock.next();
    clock.begin();
    clock.next();
    clock.next();
    clock.end();
    context.expect(clock.stats().frames() == 1, "khung sau khung bỏ dở vẫn được nộp");
}

void describe_names_every_stage(Context& context) {
    core::StageStats stats(3);
    const std::string empty = core::describe("CPU", kNames, stats);
    context.expect(empty.empty(), "chưa có khung thì không có dòng nào");
    context.expect(stats.add(std::array{1.0, 2.0, 3.0}), "một khung");
    const std::string line = core::describe("CPU", kNames, stats);
    context.expect(line.starts_with("CPU: một 1.00, hai 2.00, ba 3.00 ms"), "tên và số từng chặng");
    context.expect(line.contains("(1 khung)"), "số khung");
    const std::array<const char*, 1> wrong{"lệch"};
    context.expect(core::describe("CPU", wrong, stats).empty(), "sai số tên thì không in");
}

constexpr std::array kCases{
    Case{.name = "means_and_percentiles", .body = &means_and_percentiles},
    Case{.name = "rejects_malformed_frames", .body = &rejects_malformed_frames},
    Case{.name = "window_keeps_recent_frames", .body = &window_keeps_recent_frames},
    Case{.name = "clock_submits_whole_frames", .body = &clock_submits_whole_frames},
    Case{.name = "clock_restarts_after_abandoned_frame", .body = &clock_restarts_after_abandoned_frame},
    Case{.name = "describe_names_every_stage", .body = &describe_names_every_stage},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "stages_tests: mọi ca phải qua");
    return 0;
}
