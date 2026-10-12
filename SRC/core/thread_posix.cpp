// Luồng POSIX: tên đầy đủ ở thread_local, pthread chỉ nhận 15 byte; ưu tiên là nice của đúng luồng
// (gettid, không phải cả tiến trình); ghim bằng sched_setaffinity. Chờ trên địa chỉ dùng futex 4
// byte. Nhân 4.9 của máy kiểm chứng không có futex_waitv (Linux 5.16), nên atomic 8 byte chờ nửa
// thấp little-endian: park cho phép thức giả, tail của log tăng từng dòng chứ không nhảy 4 GiB.
// iOS dùng __ulock_wait (darwin-xnu bsd/sys/ulock.h, cùng số với libc++ atomic.cpp). Không biên C
// riêng: park là template và ThreadBody là MoveOnlyFunction.
#if !defined(_WIN32)

#include "core/thread.hpp"

#include "core/check.hpp"
#include "core/log.hpp"
#include "core/text.hpp"

#include <pthread.h>
#include <sched.h>
#include <time.h>
#include <unistd.h>

#if defined(__ANDROID__) || defined(__linux__)
#include <linux/futex.h>
#include <sys/syscall.h>
#endif
#if defined(__APPLE__)
#include <sys/syscall.h>
extern "C" int __ulock_wait(std::uint32_t operation, void* address, std::uint64_t value, std::uint32_t timeout_us);
extern "C" int __ulock_wake(std::uint32_t operation, void* address, std::uint64_t wake_value);
#endif
#if defined(__x86_64__)
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_acle.h>
#endif

#include <sys/resource.h>

#include <algorithm>
#include <array>
#include <bit>
#include <cerrno>
#include <climits>
#include <cstdint>
#include <cstring>
#include <format>
#include <fstream>
#include <limits>
#include <optional>
#include <string>
#include <thread>
#include <utility>

#if defined(__ANDROID__) || defined(__linux__)
#ifndef SYS_futex
#define SYS_futex __NR_futex
#endif
#endif

namespace game::core {

namespace {

// Bảng nice. Giá trị âm cần quyền; từ chối thì cảnh báo.
constexpr auto kNice = std::to_array<int>({19, 10, 0, -10, -20});

// Luồng đã nạp .so, trước main.
const pthread_t kMainThread = pthread_self();

[[nodiscard]] std::string& local_name() {
    thread_local std::string name;
    return name;
}

[[nodiscard]] std::string system_name() {
    std::array<char, 16> text{};
    if (pthread_getname_np(pthread_self(), text.data(), text.size()) != 0) return {};
    return std::string(text.data());
}

void pause_cpu() noexcept {
#if defined(__x86_64__)
    _mm_pause();
#elif defined(__aarch64__)
    __yield();
#else
#error "thread_posix: chưa có lệnh pause"
#endif
}

[[nodiscard]] int apply_name(const char* text) noexcept {
#if defined(__APPLE__)
    return pthread_setname_np(text);
#else
    return pthread_setname_np(pthread_self(), text);
#endif
}

[[nodiscard]] id_t this_tid() noexcept {
#if defined(__APPLE__)
    return id_t{0};
#else
    return static_cast<id_t>(::gettid());
#endif
}

[[nodiscard]] CpuSet all_cpus() noexcept {
    CpuSet cpus;
    const std::size_t count = std::min<std::size_t>(cpu_count(), cpus.size());
    for (std::size_t i = 0; i < count; ++i) {
        cpus.set(i);
    }
    return cpus;
}

#if !defined(__APPLE__)

[[nodiscard]] std::optional<int> capacity_of(std::uint32_t index) {
    const std::string path = std::format("/sys/devices/system/cpu/cpu{}/cpu_capacity", index);
    std::ifstream file(path);
    int value = 0;
    if (!(file >> value)) return std::nullopt;
    return value;
}

void mark_if_top(CpuSet& cpus, std::uint32_t index, int top) {
    const std::optional<int> capacity = capacity_of(index);
    if (!capacity || *capacity != top || index >= cpus.size()) return;
    cpus.set(index);
}

void raise_top(int& top, std::uint32_t index) {
    const std::optional<int> capacity = capacity_of(index);
    if (!capacity) return;
    top = std::max(top, *capacity);
}

[[nodiscard]] int highest_capacity(std::uint32_t count) {
    int top = -1;
    for (std::uint32_t i = 0; i < count; ++i) {
        raise_top(top, i);
    }
    return top;
}

void set_one(cpu_set_t& set, std::size_t index, const CpuSet& cpus) {
    if (index >= CPU_SETSIZE || !cpus.test(index)) return;
    CPU_SET(index, &set);
}

#endif

void pin(const CpuSet& cpus) {
    if (!cpus.any()) return warn("Tập CPU không có CPU nào đang chạy, không ghim");
#if defined(__APPLE__)
    warn("iOS không ghim được luồng từ tiến trình thường");
    static_cast<void>(cpus);
#else
    cpu_set_t set;
    CPU_ZERO(&set);
    const std::size_t count = std::min(cpus.size(), static_cast<std::size_t>(CPU_SETSIZE));
    for (std::size_t i = 0; i < count; ++i) {
        set_one(set, i, cpus);
    }
    if (sched_setaffinity(0, sizeof(set), &set) == 0) return;
    warn("Không ghim được luồng: lỗi {}", errno);
#endif
}

class ThreadStart {
public:
    using Config = ThreadConfig;
    using Body = ThreadBody;

    ThreadStart(Config config, Body body) : config_(std::move(config)), body_(std::move(body)) {}

    void operator()(std::stop_token token) {
        if (!config_.name.empty()) set_thread_name(config_.name);
        if (config_.affinity.any()) pin(config_.affinity);
        if (config_.priority != ThreadPriority::kNormal) set_thread_priority(config_.priority);
        body_(std::move(token));
    }

private:
    ThreadConfig config_;
    ThreadBody body_;
};

// Làm tròn lên mili giây như WaitOnAddress. max là chờ mãi.
[[nodiscard]] std::optional<timespec> relative_timeout(std::chrono::nanoseconds timeout) noexcept {
    if (timeout == std::chrono::nanoseconds::max()) return std::nullopt;
    timespec out{};
    if (timeout <= std::chrono::nanoseconds::zero()) return out;
    const auto rounded = std::chrono::ceil<std::chrono::milliseconds>(timeout).count();
    const auto milliseconds = std::min<std::int64_t>(rounded, INT_MAX);
    out.tv_sec = static_cast<time_t>(milliseconds / 1000);
    out.tv_nsec = static_cast<long>((milliseconds % 1000) * 1'000'000);
    return out;
}

using Nano = std::chrono::nanoseconds;

struct MemoryWord {
    const void* address = nullptr;
    const void* old = nullptr;
    std::size_t size = 0;
};

struct SpinLimit {
    MemoryWord word{};
    std::chrono::steady_clock::time_point start{};
    Nano timeout{};
};

[[nodiscard]] bool differs(const MemoryWord& word) noexcept {
    std::array<std::byte, 8> current{};
    std::array<std::byte, 8> expected{};
    std::memcpy(current.data(), word.address, word.size);
    std::memcpy(expected.data(), word.old, word.size);
    return std::memcmp(current.data(), expected.data(), word.size) != 0;
}

[[nodiscard]] bool keep_spinning(const SpinLimit& limit) noexcept {
    if (differs(limit.word)) return false;
    if (limit.timeout == Nano::max()) return true;
    const auto elapsed = std::chrono::steady_clock::now() - limit.start;
    return elapsed < limit.timeout;
}

[[nodiscard]] bool spin_until(const MemoryWord& word, Nano timeout) noexcept {
    const auto start = std::chrono::steady_clock::now();
    const SpinLimit limit{.word = word, .start = start, .timeout = timeout};
    while (keep_spinning(limit)) {
        pause_cpu();
    }
    return differs(word);
}

[[nodiscard]] std::uint32_t low_half(const void* old) noexcept {
    std::uint32_t value = 0;
    std::memcpy(&value, old, sizeof(value));
    return value;
}

#if defined(__ANDROID__) || defined(__linux__)

struct Wait {
    const void* address = nullptr;
    const void* old = nullptr;
    std::chrono::nanoseconds timeout = std::chrono::nanoseconds::zero();
    std::size_t size = 0;
};

[[nodiscard]] bool wait_low32(const Wait& wait) noexcept {
    static_assert(std::endian::native == std::endian::little, "futex 4 byte cần little-endian");
    const MemoryWord word{wait.address, wait.old, wait.size};
    const bool none = wait.timeout <= std::chrono::nanoseconds::zero();
    if (none) return differs(word);
    const std::uint32_t expected = low_half(wait.old);
    const std::optional<timespec> relative = relative_timeout(wait.timeout);
    const timespec* spec = relative ? &*relative : nullptr;
    const int operation = FUTEX_WAIT_PRIVATE;
    const long result = ::syscall(SYS_futex, wait.address, operation, expected, spec, nullptr, 0);
    if (result == 0) return true;
    if (errno == ETIMEDOUT) return false;
    if (errno == ENOSYS) return spin_until(word, wait.timeout);
    return true;
}

void wake_low32(const void* address, int count) noexcept {
    const auto operation = static_cast<int>(FUTEX_WAKE_PRIVATE);
    static_cast<void>(::syscall(SYS_futex, address, operation, count, nullptr, nullptr, 0));
}

#else

// Số của ulock.h, darwin-xnu.
constexpr std::uint32_t kUlock32 = 1;
constexpr std::uint32_t kUlock64 = 5;
constexpr std::uint32_t kUlockWakeAll = 0x100;

[[nodiscard]] std::uint32_t timeout_us(std::chrono::nanoseconds timeout) noexcept {
    if (timeout == std::chrono::nanoseconds::max()) return 0;
    const auto microseconds = std::chrono::ceil<std::chrono::microseconds>(timeout).count();
    if (microseconds <= 0) return 1;
    const auto limit = static_cast<std::int64_t>(std::numeric_limits<std::uint32_t>::max());
    return static_cast<std::uint32_t>(std::min(microseconds, limit));
}

[[nodiscard]] std::uint64_t load_old(const void* old, std::size_t size) noexcept {
    std::uint64_t value = 0;
    std::memcpy(&value, old, size);
    return value;
}

[[nodiscard]] bool wait_ulock(const MemoryWord& word, Nano timeout) noexcept {
    if (timeout <= Nano::zero()) return differs(word);
    const std::uint32_t operation = word.size == 8 ? kUlock64 : kUlock32;
    auto* target = const_cast<void*>(word.address);
    const std::uint64_t expected = load_old(word.old, word.size);
    const std::uint32_t usec = timeout_us(timeout);
    const int result = __ulock_wait(operation, target, expected, usec);
    if (result == 0) return true;
    if (errno == ETIMEDOUT) return false;
    if (errno == ENOSYS) return spin_until(word, timeout);
    return true;
}

void wake_ulock(const void* address, std::size_t size, bool all) noexcept {
    const std::uint32_t operation = (size == 8 ? kUlock64 : kUlock32) | (all ? kUlockWakeAll : 0U);
    static_cast<void>(__ulock_wake(operation, const_cast<void*>(address), 0));
}

#endif

} // namespace

void set_thread_name(std::string_view name) {
    local_name() = std::string(name);
    const std::string_view kept = utf8_prefix(name, 15);
    std::array<char, 16> text{};
    std::memcpy(text.data(), kept.data(), kept.size());
    const int applied = apply_name(text.data());
    if (applied == 0) return;
    warn("Không đặt được tên luồng '{}': lỗi {}", name, applied);
}

std::string_view thread_name() {
    std::string& name = local_name();
    if (!name.empty()) return name;
    name = system_name();
    if (!name.empty()) return name;
#if defined(__APPLE__)
    const auto bits = reinterpret_cast<std::uintptr_t>(pthread_self());
    const auto id = static_cast<unsigned long long>(bits);
#else
    const auto id = static_cast<unsigned long long>(pthread_self());
#endif
    name = is_main_thread() ? "chính" : std::to_string(id);
    return name;
}

void set_thread_priority(ThreadPriority priority) noexcept {
    const auto index = std::to_underlying(priority);
    check(index < kNice.size(), "ưu tiên luồng ngoài bảng");
    const int value = kNice[index];
    errno = 0;
    if (setpriority(PRIO_PROCESS, this_tid(), value) == 0) return;
    warn("Không đặt được ưu tiên luồng {}: lỗi {}", value, errno);
}

bool is_main_thread() noexcept {
    return pthread_equal(pthread_self(), kMainThread) != 0;
}

std::uint32_t cpu_count() noexcept {
    const long count = ::sysconf(_SC_NPROCESSORS_ONLN);
    if (count <= 0) return 1;
    const auto limit = static_cast<long>(std::numeric_limits<std::uint32_t>::max());
    return static_cast<std::uint32_t>(std::min(count, limit));
}

CpuSet performance_cpus() {
#if defined(__APPLE__)
    return all_cpus();
#else
    const std::uint32_t count = cpu_count();
    const int top = highest_capacity(count);
    if (top < 0) return all_cpus();
    CpuSet cpus;
    for (std::uint32_t i = 0; i < count; ++i) {
        mark_if_top(cpus, i, top);
    }
    if (cpus.none()) return all_cpus();
    return cpus;
#endif
}

namespace detail {

bool park_address(const void* address, const void* old, std::size_t size, Nano timeout) noexcept {
    if (size != 4 && size != 8) return false;
#if defined(__ANDROID__) || defined(__linux__)
    const Wait wait{.address = address, .old = old, .timeout = timeout, .size = size};
    return wait_low32(wait);
#else
    const MemoryWord word{address, old, size};
    return wait_ulock(word, timeout);
#endif
}

} // namespace detail

void unpark_address(const void* address, Wake wake) noexcept {
#if defined(__ANDROID__) || defined(__linux__)
    const int count = wake == Wake::kAll ? INT_MAX : 1;
    wake_low32(address, count);
#else
    wake_ulock(address, 4, wake == Wake::kAll);
    wake_ulock(address, 8, wake == Wake::kAll);
#endif
}

std::jthread start_thread(ThreadConfig config, ThreadBody body) {
    return std::jthread(ThreadStart(std::move(config), std::move(body)));
}

} // namespace game::core

#endif
