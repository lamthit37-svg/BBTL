// Giấc ngủ và lịch tick. Mỗi luồng một bộ hẹn giờ độ phân giải cao, đóng khi luồng kết thúc; dùng
// chung một handle thì luồng này xoá tín hiệu của luồng kia. Pha quay dùng YieldProcessor (pause),
// không yield như VnS và No1: SwitchToThread trao lõi cho luồng khác đang chờ rồi phải đợi nó hết
// lượt, nên p99 lệch hạn cao hơn (docs/modules/core.md). Lịch tick tách giây và phần dư để phép
// nhân không tràn. Phần lẻ alpha tính từ phần dư hữu tỉ thay vì từ hai mốc tick đã làm tròn lên
// nano giây như VnS và No1: lệch nhau dưới 10^-7, nhỏ hơn bước của float.
// Nguồn: Forge2 src/core/clock.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của
// windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp; đổi
// tên cho đủ 3 ký tự (hz thành hertz, at thành spot) và hằng static thành kTimer; const HANDLE viết
// thành auto* const; alias TickOffset cho kiểu trả của offset_of; lệnh return kèm lời gọi hàm void
// tách làm hai.
#include "core/clock.hpp"

#include "core/error.hpp"
#include "core/handle.hpp"
#if defined(_WIN32)
#include "core/thread_slot.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <processthreadsapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <winnt.h>
#else
#include <time.h>

#include <cerrno>
#if defined(__x86_64__)
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_acle.h>
#endif
#include <sys/resource.h>
#include <unistd.h>
#endif

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <limits>
#include <optional>
#include <thread>

namespace game::core {

namespace {

using Nanos = std::chrono::nanoseconds;

constexpr std::uint64_t kNanosPerSecond = 1'000'000'000;

// Số float lớn nhất còn nhỏ hơn 1: 1 trừ nửa ulp có thể làm tròn thành đúng 1.
constexpr float kBelowOne = 0x1.fffffep-1F;
constexpr float kPerBillion = 1e-9F;

#if defined(_WIN32)

[[nodiscard]] UniqueHandle open_timer() noexcept {
    constexpr DWORD kAccess = TIMER_ALL_ACCESS;
    constexpr DWORD kHighResolution = CREATE_WAITABLE_TIMER_HIGH_RESOLUTION;
    HANDLE handle = CreateWaitableTimerExW(nullptr, nullptr, kHighResolution, kAccess);
    // Trước Windows 10 1803 không có cờ độ phân giải cao: bộ hẹn giờ thường, vẫn hơn Sleep vì không
    // làm tròn lên mili giây.
    if (handle == nullptr) handle = CreateWaitableTimerExW(nullptr, nullptr, 0, kAccess);
    return UniqueHandle(handle);
}

// Khác gốc: gốc khai static thread_local const UniqueHandle; qua thread_slot vì lỗi TLS của GCC
// MinGW.
[[nodiscard]] HANDLE thread_timer() noexcept {
    const UniqueHandle& timer = thread_slot([] { return open_timer(); });
    return timer.get();
}

// Đơn vị 100 ns của bộ hẹn giờ, làm tròn lên để không ngủ thiếu. Chia trước rồi cộng: cộng 99 vào
// số sát trần int64 là tràn có dấu.
[[nodiscard]] std::int64_t timer_units(Nanos span) noexcept {
    const std::int64_t whole = span.count() / 100;
    return span.count() % 100 == 0 ? whole : whole + 1;
}

#endif

void pause_cpu() noexcept {
#if defined(_WIN32)
    YieldProcessor();
#elif defined(__x86_64__)
    _mm_pause();
#elif defined(__aarch64__)
    __yield();
#else
#error "clock: chưa có lệnh pause"
#endif
}

void spin_until(Clock::time_point deadline) noexcept {
    while (Clock::now() < deadline)
        pause_cpu();
}

#if defined(_WIN32)

// Chỉ hẹn giờ. Không có bộ hẹn giờ thì std::this_thread::sleep_for (Sleep theo nhịp hệ thống).
void timer_sleep(Clock::duration span) noexcept {
    // Khác gốc: gốc khai const HANDLE; const đặt sau con trỏ để không bị đọc nhầm là const void*.
    auto* const timer = thread_timer();
    LARGE_INTEGER due{};
    due.QuadPart = -timer_units(span);
    const bool armed = timer != nullptr && SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE) != FALSE;
    // Khác gốc: gốc viết return std::this_thread::sleep_for(span) trên một dòng.
    if (!armed) {
        std::this_thread::sleep_for(span);
        return;
    }
    WaitForSingleObject(timer, INFINITE);
}

#else

[[nodiscard]] timespec as_timespec(Nanos span) noexcept {
    timespec out{};
    const auto whole = span.count();
    out.tv_sec = static_cast<time_t>(whole / 1'000'000'000);
    out.tv_nsec = static_cast<long>(whole % 1'000'000'000);
    return out;
}

// clock_nanosleep trả mã lỗi, không phải -1. Apple chưa có nó ở deployment 15: nanosleep.
void timer_sleep(Clock::duration span) noexcept {
    timespec left = as_timespec(std::chrono::duration_cast<Nanos>(span));
#if defined(__APPLE__)
    while (::nanosleep(&left, &left) == -1 && errno == EINTR) {
    }
#else
    while (::clock_nanosleep(CLOCK_MONOTONIC, 0, &left, &left) == EINTR) {
    }
#endif
}

#endif

// Vị trí trên lịch tại elapsed: số tick đã đến hạn floor(elapsed * hz / 10^9) và phần lẻ của tick
// đang chạy, tính bằng phần tỉ. elapsed = q * 10^9 + r nên elapsed * hz = q * hz * 10^9 + r * hz;
// nhân thẳng elapsed * hz tràn sau khoảng mười năm ở 60 Hz. Chỉ chia cho hằng 10^9, trình dịch đổi
// thành phép nhân; không chia cho hz.
struct Position {
    std::uint64_t due = 0;
    std::uint64_t part = 0;
};

// Khác gốc: tham số hz của position và offset_of đổi tên thành hertz (tên dưới 3 ký tự).
[[nodiscard]] Position position(Nanos elapsed, std::uint32_t hertz) noexcept {
    if (elapsed <= Nanos::zero()) return {};
    const auto total = static_cast<std::uint64_t>(elapsed.count());
    const std::uint64_t whole = (total / kNanosPerSecond) * hertz;
    const std::uint64_t scaled = (total % kNanosPerSecond) * hertz;
    return {.due = whole + (scaled / kNanosPerSecond), .part = scaled % kNanosPerSecond};
}

// Khác gốc: alias để chữ ký của offset_of còn nằm trên một dòng sau khi đổi tên tham số.
using TickOffset = std::optional<std::int64_t>;

// ceil(tick * 10^9 / hz); rỗng khi không vừa int64.
[[nodiscard]] TickOffset offset_of(std::uint64_t tick, std::uint32_t hertz) noexcept {
    const std::uint64_t whole = tick / hertz;
    const std::uint64_t rest = tick % hertz;
    const std::uint64_t partial = ((rest * kNanosPerSecond) + (hertz - 1)) / hertz;
    constexpr auto kLimit = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    if (whole > (kLimit - partial) / kNanosPerSecond) return std::nullopt;
    return static_cast<std::int64_t>((whole * kNanosPerSecond) + partial);
}

} // namespace

void sleep_for(Clock::duration span) noexcept {
    if (span <= Clock::duration::zero()) return;
    const Clock::time_point start = Clock::now();
    timer_sleep(span);
    // Bộ hẹn giờ đếm theo đồng hồ ngắt, không phải QueryPerformanceCounter: thức sớm vài trăm ns
    // vẫn là về sớm theo Clock, nên quay nốt phần thiếu. span sát Clock::duration::max() thì
    // start + span tràn có dấu; khoảng đó chưa bao giờ hết.
    const bool fits = span <= Clock::time_point::max() - start;
    if (fits) spin_until(start + span);
}

// Ưu tiên TIME_CRITICAL trong lúc chờ: thức là chiếm lõi ngay, đang quay không bị luồng thường
// chiếm. Ở ưu tiên thường, khi luồng thợ phủ kín lõi, VnS và No1 trễ p50 44–70 ms; ở đây 0,5–0,8 µs
// (docs/modules/core.md). Trả ưu tiên trước hạn một khoảng bằng thời gian lời gọi nâng (đo tại chỗ,
// cùng syscall) để lời gọi trả không nằm sau hạn, rồi quay nốt phần còn lại. Luồng đã ở mức đó thì
// không đổi gì.
namespace {

void raise_thread(bool raise, int old) noexcept;
[[nodiscard]] int raise_critical() noexcept;
#if !defined(_WIN32)
[[nodiscard]] id_t this_tid() noexcept;
#endif

#if defined(_WIN32)

void raise_thread(bool raise, int old) noexcept {
    if (!raise) return;
    auto* const self = GetCurrentThread();
    SetThreadPriority(self, old);
}

[[nodiscard]] int raise_critical() noexcept {
    auto* const self = GetCurrentThread();
    const int old = GetThreadPriority(self);
    if (old < THREAD_PRIORITY_TIME_CRITICAL) SetThreadPriority(self, THREAD_PRIORITY_TIME_CRITICAL);
    return old;
}

#else

[[nodiscard]] id_t this_tid() noexcept {
#if defined(__APPLE__)
    return id_t{0};
#else
    return static_cast<id_t>(::gettid());
#endif
}

void raise_thread(bool raise, int old) noexcept {
    if (!raise) return;
    static_cast<void>(::setpriority(PRIO_PROCESS, this_tid(), old));
}

[[nodiscard]] int raise_critical() noexcept {
    errno = 0;
    const int old = ::getpriority(PRIO_PROCESS, this_tid());
    const bool known = old != -1 || errno == 0;
    if (known && old > -20) static_cast<void>(::setpriority(PRIO_PROCESS, this_tid(), -20));
    return old;
}

#endif

} // namespace

void sleep_until(Clock::time_point deadline) noexcept {
    // So trước khi trừ: deadline rất xa về quá khứ trừ now() là tràn có dấu.
    const Clock::time_point now = Clock::now();
    if (deadline <= now) return;
#if defined(_WIN32)
    auto* const self = GetCurrentThread();
    const int old = GetThreadPriority(self);
    const bool raise = old < THREAD_PRIORITY_TIME_CRITICAL;
#else
    errno = 0;
    const int old = ::getpriority(PRIO_PROCESS, this_tid());
    const bool known = old != -1 || errno == 0;
    const bool raise = known && old > -20;
#endif
    if (raise) static_cast<void>(raise_critical());
    const Clock::time_point raised = Clock::now();
    const Clock::duration lead = raise ? raised - now : Clock::duration::zero();
    const Clock::duration coarse = deadline - raised - kSpinMargin;
    if (coarse > Clock::duration::zero()) timer_sleep(coarse);
    spin_until(deadline - lead);
    raise_thread(raise, old);
    spin_until(deadline);
}

Result<FixedStep> FixedStep::create(TickConfig config) noexcept {
    const bool valid_hz = config.hz >= 1 && config.hz <= kMaxHz;
    if (!valid_hz) return fail(ErrorCode::kInvalidArgument, "hz ngoài 1..10^9", "{}", config.hz);
    if (config.max_steps == 0) return fail(ErrorCode::kInvalidArgument, "trần số bước bằng 0");
    return FixedStep(config);
}

std::uint32_t FixedStep::advance(Clock::time_point now) noexcept {
    if (!is_started_) return start(now);
    // Khác gốc: biến spot ở gốc tên at (tên dưới 3 ký tự).
    const Position spot = position(now - anchor_, config_.hz);
    // now lùi về trước lần gọi trước: lịch giữ nguyên, alpha về 0.
    const bool behind = spot.due < scheduled_;
    const std::uint64_t due = behind ? scheduled_ : spot.due;
    const std::uint64_t pending = due - scheduled_;
    const std::uint64_t run = std::min<std::uint64_t>(pending, config_.max_steps);
    dropped_ += pending - run;
    ticks_ += run;
    scheduled_ = due;
    const float part = static_cast<float>(spot.part) * kPerBillion;
    alpha_ = behind ? 0.0F : std::min(part, kBelowOne);
    return static_cast<std::uint32_t>(run);
}

std::optional<Clock::time_point> FixedStep::next_tick() const noexcept {
    if (!is_started_) return std::nullopt;
    const std::optional<std::int64_t> offset = offset_of(scheduled_ + 1, config_.hz);
    if (!offset) return std::nullopt;
    const Nanos span(*offset);
    if (span > Clock::time_point::max() - anchor_) return std::nullopt;
    return anchor_ + span;
}

std::uint32_t FixedStep::start(Clock::time_point now) noexcept {
    anchor_ = now;
    is_started_ = true;
    alpha_ = 0.0F;
    return 0;
}

} // namespace game::core
