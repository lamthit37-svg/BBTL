/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/cores.cpp
 *  PHÂN HỆ   : Core / Cores
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/cores.hpp. Đo 2026-10-17 trên TB-X306F (MT8768, 4 x 2,3 GHz
 *    và 4 x 1,8 GHz bị chặn 1,05 GHz): khi tải giảm, bộ lập lịch dời luồng vẽ
 *    sang cụm chậm (87% mẫu ở cpu4-7), mỗi khung tốn gấp 2,2 lần và máy kẹt ở
 *    30 khung; giữ được 60 thì 97% mẫu nằm ở cpu0-3.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/cores.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <iterator>
#include <span>
#include <vector>

#if defined(__ANDROID__) || defined(__linux__)
#include <sched.h>
#include <unistd.h>

#include <format>
#include <fstream>
#include <optional>
#include <string>
#include <string_view>
#endif
#if defined(__APPLE__)
#include <pthread.h>
#include <pthread/qos.h>
#endif

namespace game::core {
namespace {

constexpr std::size_t kMinFrameCpus = 2;
constexpr std::size_t kMostCpus = CpuSet{}.size();

[[nodiscard]] std::size_t count_at_least(std::span<const std::uint64_t> capacity,
    std::uint64_t floor) noexcept {
    const auto reaches = [floor](std::uint64_t value) { return value >= floor; };
    return static_cast<std::size_t>(std::ranges::count_if(capacity, reaches));
}

// Các mức sức khác nhau đã đọc được, mạnh trước.
[[nodiscard]] std::vector<std::uint64_t> levels_of(std::span<const std::uint64_t> capacity) {
    std::vector<std::uint64_t> levels;
    const auto is_known = [](std::uint64_t value) { return value > 0; };
    std::ranges::copy_if(capacity, std::back_inserter(levels), is_known);
    std::ranges::sort(levels, std::ranges::greater{});
    const auto repeated = std::ranges::unique(levels);
    levels.erase(repeated.begin(), repeated.end());
    return levels;
}

// Mức thấp nhất phải lấy: đi từ lớp mạnh nhất xuống tới khi đủ kMinFrameCpus CPU.
[[nodiscard]] std::uint64_t floor_of(std::span<const std::uint64_t> capacity,
    std::span<const std::uint64_t> levels) noexcept {
    for (const std::uint64_t level : levels) {
        if (count_at_least(capacity, level) >= kMinFrameCpus) return level;
    }
    return levels.back();
}

[[nodiscard]] CpuSet read_fast_cores() {
    const std::vector<std::uint64_t> capacity = cpu_capacities();
    return frame_cpus(capacity);
}

#if defined(__ANDROID__) || defined(__linux__)

[[nodiscard]] std::optional<std::uint64_t> read_number(const std::string& path) {
    std::ifstream file(path);
    std::uint64_t value = 0;
    if (!(file >> value)) return std::nullopt;
    return value;
}

[[nodiscard]] std::string cpu_file(std::size_t index, std::string_view name) {
    return std::format("/sys/devices/system/cpu/cpu{}/{}", index, name);
}

// Một thước đo cho mọi CPU. cpu_capacity (EAS) so được lõi khác vi kiến trúc; nhân 4.9 của
// TB-X306F không có nó, mà hai cụm cùng là A53 nên xung tối đa xếp đúng thứ tự.
[[nodiscard]] std::string_view capacity_name() {
    const std::string first = cpu_file(0, "cpu_capacity");
    if (read_number(first)) return "cpu_capacity";
    return "cpufreq/cpuinfo_max_freq";
}

void add_cpu(cpu_set_t& set, std::size_t index, const CpuSet& cpus) noexcept {
    if (!cpus[index]) return;
    CPU_SET(index, &set);
}

[[nodiscard]] cpu_set_t native_set(const CpuSet& cpus) noexcept {
    cpu_set_t set;
    CPU_ZERO(&set);
    const std::size_t count = std::min<std::size_t>(cpus.size(), CPU_SETSIZE);
    for (std::size_t i = 0; i < count; ++i) {
        add_cpu(set, i, cpus);
    }
    return set;
}

// Đọc affinity trước khi đặt: lần gọi định kỳ chỉ tốn một syscall khi không có gì đổi. cpuset của
// tiến trình hẹp hơn (đang ở nền) thì nhân đặt phần giao, lần sau đọc khác nên đặt lại, vẫn rẻ.
[[nodiscard]] bool pin_drifted(const CpuSet& wanted) noexcept {
    cpu_set_t want = native_set(wanted);
    cpu_set_t now;
    CPU_ZERO(&now);
    const bool is_read = sched_getaffinity(0, sizeof(now), &now) == 0;
    const bool is_same = is_read && CPU_EQUAL(&now, &want);
    if (is_same) return true;
    return sched_setaffinity(0, sizeof(want), &want) == 0;
}

#endif

} // namespace

std::vector<std::uint64_t> cpu_capacities() {
#if defined(__ANDROID__) || defined(__linux__)
    // CPU đã cấu hình chứ không chỉ CPU đang bật: MediaTek tắt cả cụm khi rảnh.
    const long configured = ::sysconf(_SC_NPROCESSORS_CONF);
    if (configured <= 0) return {};
    const std::size_t count = std::min(static_cast<std::size_t>(configured), kMostCpus);
    const std::string_view name = capacity_name();
    std::vector<std::uint64_t> capacity(count, 0);
    for (std::size_t i = 0; i < count; ++i) {
        const std::string path = cpu_file(i, name);
        capacity[i] = read_number(path).value_or(0);
    }
    return capacity;
#else
    return {};
#endif
}

CpuSet frame_cpus(std::span<const std::uint64_t> capacity) {
    const std::vector<std::uint64_t> levels = levels_of(capacity);
    if (levels.size() < 2) return {};
    const std::uint64_t floor = floor_of(capacity, levels);
    // Phải lấy tới lớp yếu nhất là lấy mọi CPU đọc được: ghim không thêm gì.
    if (floor == levels.back()) return {};
    CpuSet cpus;
    const std::size_t count = std::min(capacity.size(), kMostCpus);
    for (std::size_t i = 0; i < count; ++i) {
        if (capacity[i] < floor) continue;
        cpus.set(i);
    }
    return cpus;
}

const CpuSet& fast_cores() {
    static const CpuSet cores = read_fast_cores();
    return cores;
}

bool prefer_fast_cores() {
#if defined(__APPLE__)
    // iOS bỏ qua affinity của thread_policy_set; QoS là cách duy nhất xin lõi P.
    return pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0) == 0;
#elif defined(__ANDROID__) || defined(__linux__)
    const CpuSet& wanted = fast_cores();
    if (wanted.none()) return true;
    return pin_drifted(wanted);
#else
    // Windows: bộ lập lịch đã ưu tiên luồng của cửa sổ đang dùng; chưa đo thấy cần ghim.
    return true;
#endif
}

} // namespace game::core
