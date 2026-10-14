// CPU, tải, đường dẫn exe và hệ điều hành trên POSIX. x86 không có ở đây: cờ SSE/AVX để trống,
// require_cpu báo thiếu đúng như hợp đồng. Android đọc /proc và thuộc tính hệ thống; Linux khác
// (máy chủ) đọc /proc và uname; Apple đọc sysctl và Mach. Không biên C: CpuInfo và Status là kiểu C++ dùng chung với
// bản Win32.
#if !defined(_WIN32)

#include "core/system.hpp"

#include "core/uarch.hpp"

#include <unistd.h>

#if defined(__APPLE__)
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#elif defined(__ANDROID__)
#include <sys/system_properties.h>
#endif

#include <sys/utsname.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <fstream>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::core {

namespace {

constexpr std::size_t kPathLimit = 32768;

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    while (!text.empty() && (text.front() == ' ' || text.front() == '\t')) {
        text.remove_prefix(1);
    }
    while (!text.empty() && (text.back() == ' ' || text.back() == '\t' || text.back() == '\r')) {
        text.remove_suffix(1);
    }
    return text;
}

void take_cpu_field(CpuInfo& info, std::string_view line) {
    const std::size_t colon = line.find(':');
    if (colon == std::string_view::npos) return;
    const std::string_view key = trim(line.substr(0, colon));
    const std::string_view value = trim(line.substr(colon + 1));
    const bool model = key == "model name" || key == "Hardware";
    if (model) info.name = std::string(value);
    if (key == "CPU implementer" && info.vendor.empty()) info.vendor = std::string(value);
}

[[nodiscard]] std::int64_t take_number(std::string_view& line) noexcept {
    while (!line.empty() && line.front() == ' ') {
        line.remove_prefix(1);
    }
    std::int64_t value = 0;
    while (!line.empty() && line.front() >= '0' && line.front() <= '9') {
        value = value * 10 + static_cast<std::int64_t>(line.front() - '0');
        line.remove_prefix(1);
    }
    return value;
}

[[nodiscard]] bool is_cpu_row(std::string_view line) noexcept {
    if (line.size() < 4 || !line.starts_with("cpu")) return false;
    return line[3] >= '0' && line[3] <= '9';
}

struct CpuTimes {
    std::int64_t idle = 0;
    std::int64_t total = 0;
};

[[nodiscard]] std::optional<CpuTimes> times_of(std::string_view line) noexcept {
    if (!is_cpu_row(line)) return std::nullopt;
    const std::size_t space = line.find(' ');
    if (space == std::string_view::npos) return std::nullopt;
    line.remove_prefix(space);
    const std::int64_t user = take_number(line);
    const std::int64_t nice = take_number(line);
    const std::int64_t system = take_number(line);
    const std::int64_t idle = take_number(line);
    const std::int64_t iowait = take_number(line);
    const std::int64_t irq = take_number(line);
    const std::int64_t softirq = take_number(line);
    CpuTimes times;
    times.idle = idle + iowait;
    times.total = user + nice + system + times.idle + irq + softirq;
    return times;
}

#if defined(__APPLE__)

[[nodiscard]] std::string sysctl_text(const char* key) {
    std::array<char, 256> text{};
    std::size_t size = text.size();
    if (::sysctlbyname(key, text.data(), &size, nullptr, 0) != 0) return {};
    if (size == 0) return {};
    if (text[size - 1] == '\0') --size;
    return std::string(text.data(), size);
}

[[nodiscard]] std::filesystem::path exe_from_dyld() {
    std::uint32_t size = 0;
    static_cast<void>(_NSGetExecutablePath(nullptr, &size));
    if (size == 0 || size > kPathLimit) return {};
    std::string buffer(size, '\0');
    if (_NSGetExecutablePath(buffer.data(), &size) != 0) return {};
    const std::size_t end = buffer.find('\0');
    if (end != std::string::npos) buffer.resize(end);
    return std::filesystem::path(buffer);
}

#else

#if defined(__ANDROID__)
[[nodiscard]] std::string property_of(const char* key) {
    std::array<char, PROP_VALUE_MAX> text{};
    const int length = __system_property_get(key, text.data());
    if (length <= 0) return {};
    return std::string(text.data(), static_cast<std::size_t>(length));
}
#endif

[[nodiscard]] bool grew_link(std::string& buffer) {
    const auto room = static_cast<ssize_t>(buffer.size());
    const ssize_t got = ::readlink("/proc/self/exe", buffer.data(), buffer.size());
    if (got < 0 || got >= room) return false;
    buffer.resize(static_cast<std::size_t>(got));
    return true;
}

[[nodiscard]] bool enlarge(std::string& buffer) {
    if (buffer.size() >= kPathLimit) return false;
    buffer.assign(std::min(buffer.size() * 2, kPathLimit), '\0');
    return true;
}

[[nodiscard]] bool is_link(const std::string& buffer) noexcept {
    return !buffer.empty() && buffer.find('\0') == std::string::npos;
}

[[nodiscard]] std::filesystem::path exe_from_proc() {
    std::string buffer(256, '\0');
    while (!grew_link(buffer) && enlarge(buffer)) {
    }
    if (!is_link(buffer)) return {};
    return std::filesystem::path(buffer);
}

#endif

} // namespace

CpuInfo cpu_info() {
    CpuInfo info;
    info.simd = Simd::kNone;
#if defined(__APPLE__)
    info.vendor = "Apple";
    info.name = sysctl_text("machdep.cpu.brand_string");
    if (info.name.empty()) info.name = sysctl_text("hw.machine");
#else
    std::ifstream file("/proc/cpuinfo");
    std::string line;
    while (std::getline(file, line)) {
        take_cpu_field(info, line);
    }
    if (info.vendor.empty()) info.vendor = "ARM";
    if (info.name.empty()) info.name = "không rõ";
#endif
    info.microarchitecture = microarchitecture(info.vendor, info.family, info.model, info.stepping);
    return info;
}

#if defined(__APPLE__)

std::vector<float> CpuUsage::sample() {
    processor_info_array_t array = nullptr;
    mach_msg_type_number_t count = 0;
    natural_t processors = 0;
    const kern_return_t result =
        host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processors, &array, &count);
    std::vector<float> usage;
    if (result != KERN_SUCCESS || array == nullptr) return usage;
    const auto* ticks = reinterpret_cast<processor_cpu_load_info_t>(array);
    for (natural_t i = 0; i < processors; ++i) {
        const std::int64_t user = ticks[i].cpu_ticks[CPU_STATE_USER];
        const std::int64_t system = ticks[i].cpu_ticks[CPU_STATE_SYSTEM];
        const std::int64_t idle = ticks[i].cpu_ticks[CPU_STATE_IDLE];
        const std::int64_t nice = ticks[i].cpu_ticks[CPU_STATE_NICE];
        const Times now{.idle = idle, .total = user + system + idle + nice};
        record(now, usage);
    }
    const auto bytes = static_cast<vm_size_t>(count) * sizeof(integer_t);
    const auto address = reinterpret_cast<vm_address_t>(array);
    static_cast<void>(vm_deallocate(mach_task_self(), address, bytes));
    return usage;
}

#else

void CpuUsage::note_stat(std::string_view line, std::vector<float>& usage) {
    const std::optional<CpuTimes> times = times_of(line);
    if (!times) return;
    const Times now{.idle = times->idle, .total = times->total};
    record(now, usage);
}

std::vector<float> CpuUsage::sample() {
    std::vector<float> usage;
    std::ifstream file("/proc/stat");
    std::string line;
    while (std::getline(file, line)) {
        note_stat(line, usage);
    }
    return usage;
}

#endif

std::filesystem::path exe_path() {
#if defined(__APPLE__)
    return exe_from_dyld();
#else
    return exe_from_proc();
#endif
}

OsInfo os_info() {
    utsname system{};
    if (::uname(&system) != 0) return {};
#if defined(__APPLE__)
    const std::string version = sysctl_text("kern.osproductversion");
    return OsInfo{
        .name = std::string("iOS ") + version,
        .version = version.empty() ? std::string(system.release) : version,
        .device = sysctl_text("hw.machine"),
    };
#elif defined(__ANDROID__)
    const std::string release = property_of("ro.build.version.release");
    const std::string shown = release.empty() ? std::string(system.release) : release;
    return OsInfo{
        .name = std::string("Android ") + shown,
        .version = shown,
        .device = property_of("ro.product.model"),
    };
#else
    return OsInfo{
        .name = std::string(system.sysname) + " " + system.release,
        .version = std::string(system.release),
        .device = std::string(system.machine),
    };
#endif
}

} // namespace game::core

#endif
