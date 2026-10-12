// Kiểm tra các định nghĩa POSIX của core mà bản Win32 đã có. Thất bại ghi tên ca, không abort:
// vỏ ứng dụng vẫn phải mở được để nhìn thấy máy đang chạy.
#include "client/mobile.hpp"

#include "core/clock.hpp"
#include "core/error.hpp"
#include "core/log.hpp"
#include "core/system.hpp"
#include "core/text.hpp"
#include "core/thread.hpp"

#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <thread>

namespace game::client {

namespace {

[[nodiscard]] bool text_round_trip() {
    constexpr std::string_view kSource = "Thiên Long";
    if (!core::is_valid_utf8(kSource)) return false;
    const std::wstring wide = core::widen(kSource);
    if (wide.empty()) return false;
    return core::narrow(wide) == kSource;
}

[[nodiscard]] bool clock_advances() {
    const core::Clock::time_point start = core::Clock::now();
    core::sleep_for(std::chrono::milliseconds(1));
    if (core::Clock::now() < start) return false;
    const core::TickConfig config{.hz = 60, .max_steps = 10};
    auto step = core::FixedStep::create(config);
    if (!step) return false;
    return step->advance(core::Clock::now()) == 0;
}

struct Gate {
    std::atomic<std::uint32_t> ready{0};
    std::atomic<std::uint32_t> flag{0};
    bool woke = false;
};

void wait_for_release(Gate* gate) {
    gate->ready.store(1, std::memory_order_release);
    core::unpark_all(gate->ready);
    const bool parked = core::park(gate->flag, 0U, std::chrono::seconds(2));
    gate->woke = parked && gate->flag.load(std::memory_order_acquire) == 1U;
}

[[nodiscard]] bool park_wakes() {
    Gate gate;
    std::jthread worker(wait_for_release, &gate);
    const bool seen = core::park(gate.ready, 0U, std::chrono::seconds(2));
    if (!seen && gate.ready.load(std::memory_order_acquire) == 0U) return false;
    gate.flag.store(1, std::memory_order_release);
    core::unpark_all(gate.flag);
    worker.join();
    return gate.woke;
}

void note_line(bool& found, std::string_view line) {
    if (line.contains("dòng-kiểm")) found = true;
}

[[nodiscard]] bool log_keeps_line() {
    core::LogConfig config;
    config.console = false;
    config.full = core::Full::kWait;
    const auto created = core::Log::create(config);
    if (!created) return false;
    core::LogHistory history(4096);
    const core::LevelMask levels = core::at_least(core::Level::kInfo);
    (*created)->add_sink(levels, core::history_sink(history));
    core::info("dòng-kiểm");
    (*created)->flush();
    bool found = false;
    const auto visit = [&](core::Level, std::string_view line) { note_line(found, line); };
    history.for_each(visit);
    return found;
}

[[nodiscard]] bool machine_reports() {
    if (core::cpu_count() == 0) return false;
    if (core::performance_cpus().none()) return false;
    if (core::exe_path().empty()) return false;
    if (core::os_info().name.empty()) return false;
    const auto missing = static_cast<std::uint32_t>(ENOENT);
    return core::from_system(missing) == core::ErrorCode::kNotFound;
}

void note(std::string& detail, std::string_view name, bool passed) {
    if (passed) return;
    if (!detail.empty()) detail.append(", ");
    detail.append(name);
}

} // namespace

ProbeReport mobile_probe() {
    ProbeReport report;
    std::string failed;
    note(failed, "đổi mã", text_round_trip());
    note(failed, "đồng hồ", clock_advances());
    note(failed, "park", park_wakes());
    note(failed, "log", log_keeps_line());
    note(failed, "máy", machine_reports());
    report.passed = failed.empty();
    report.detail = report.passed ? "THIENLONG: nền tảng sẵn sàng" : "THIENLONG: hỏng " + failed;
    return report;
}

} // namespace game::client
