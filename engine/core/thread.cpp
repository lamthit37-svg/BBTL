/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/thread.cpp
 *  PHÂN HỆ   : Core / Thread
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/thread.hpp.
 *  - Tên luồng giữ trong biến thread_local (thread_name() của _Ref cũng vậy) và
 *    đồng thời gửi cho hệ điều hành để debugger và công cụ đo hiện đúng. _Ref
 *    chỉ đặt tên hệ điều hành cho luồng do nó tạo, dùng mbstowcs nên tên có dấu
 *    thành rác, và tìm SetThreadDescription qua GetProcAddress cho Windows 7.
 *  - Nguồn: Forge2 src/core/thread.cpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k; macro của windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header
 *    con của Win32 include trực tiếp; thân vòng lặp có nhánh tách thành hàm
 *    (ghi tại chỗ); bỏ reserve_crash_stack vì core/check của THIENLONG không có
 *    trình báo crash; lệnh return kèm lời gọi hàm void tách làm hai.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/thread.hpp"

#include "core/log.hpp"
#include "core/text.hpp"
#include "core/thread_slot.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <basetsd.h>
#include <errhandlingapi.h>
#include <processthreadsapi.h>
#include <processtopologyapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>
#include <optional>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::core {

namespace {

constexpr auto kPriorities = std::to_array<int>({
    THREAD_PRIORITY_LOWEST,
    THREAD_PRIORITY_BELOW_NORMAL,
    THREAD_PRIORITY_NORMAL,
    THREAD_PRIORITY_ABOVE_NORMAL,
    THREAD_PRIORITY_HIGHEST,
});

// Một CPU logic theo GetSystemCpuSetInformation: nhóm, chỉ số trong nhóm, lớp hiệu năng.
struct CpuEntry {
    WORD group = 0;
    BYTE index = 0;
    BYTE efficiency = 0;
};

// Khác gốc: hai hàm dưới là thân vòng lặp của cpu_entries tách ra. Bản ghi ở offset, chép ra biến
// cục bộ; hết dữ liệu thì trả bản ghi có Size 0, cũng là dấu dừng của gốc.
using Bytes = std::span<const std::byte>;

[[nodiscard]] SYSTEM_CPU_SET_INFORMATION item_at(Bytes bytes, std::size_t offset) noexcept {
    SYSTEM_CPU_SET_INFORMATION item{};
    if (offset >= bytes.size()) return item;
    const Bytes rest = bytes.subspan(offset);
    std::memcpy(&item, rest.data(), std::min(sizeof(item), rest.size()));
    return item;
}

void add_entry(std::vector<CpuEntry>& entries, const SYSTEM_CPU_SET_INFORMATION& item) {
    if (item.Type != CpuSetInformation) return;
    // Union của Win32, nhánh CpuSet đúng khi Type là CpuSetInformation (kiểm ngay trên).
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-union-access)
    const auto& cpu = item.CpuSet;
    const CpuEntry entry{.group = cpu.Group, .index = cpu.LogicalProcessorIndex, .efficiency = cpu.EfficiencyClass};
    entries.push_back(entry);
}

// Bản ghi có độ dài thay đổi (trường Size) nên chép từng bản ra biến cục bộ thay vì ép con trỏ.
[[nodiscard]] std::vector<CpuEntry> cpu_entries() {
    ULONG size = 0;
    GetSystemCpuSetInformation(nullptr, 0, &size, GetCurrentProcess(), 0);
    std::vector<std::byte> buffer(size);
    // Win32 nhận bộ đệm byte qua con trỏ kiểu bản ghi; đọc lại bằng memcpy bên dưới.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    auto* data = reinterpret_cast<PSYSTEM_CPU_SET_INFORMATION>(buffer.data());
    if (GetSystemCpuSetInformation(data, size, &size, GetCurrentProcess(), 0) == 0) return {};
    std::vector<CpuEntry> entries;
    const std::span<const std::byte> bytes(buffer.data(), size);
    std::size_t offset = 0;
    SYSTEM_CPU_SET_INFORMATION item = item_at(bytes, offset);
    while (item.Size != 0) {
        add_entry(entries, item);
        offset += item.Size;
        item = item_at(bytes, offset);
    }
    return entries;
}

// Chỉ số toàn cục của CPU đầu tiên trong nhóm, như cách CpuSet đánh số.
[[nodiscard]] std::size_t group_start(WORD group) {
    std::size_t start = 0;
    for (WORD earlier = 0; earlier < group; ++earlier) {
        start += GetActiveProcessorCount(earlier);
    }
    return start;
}

// Mọi CPU logic đang chạy, đánh số như CpuSet. Không bật cả 1024 bit: nơi gọi đếm count() hay ghim
// theo tập này.
[[nodiscard]] CpuSet all_cpus() {
    CpuSet cpus;
    const std::size_t count = std::min<std::size_t>(cpu_count(), cpus.size());
    for (std::size_t i = 0; i < count; ++i) {
        cpus.set(i);
    }
    return cpus;
}

// WaitOnAddress nhận mili giây; làm tròn lên để không thức sớm hơn hạn, max là chờ mãi.
[[nodiscard]] DWORD wait_milliseconds(std::chrono::nanoseconds timeout) noexcept {
    if (timeout <= std::chrono::nanoseconds::zero()) return 0;
    if (timeout == std::chrono::nanoseconds::max()) return INFINITE;
    const auto rounded = std::chrono::ceil<std::chrono::milliseconds>(timeout).count();
    constexpr auto kLongest = static_cast<std::int64_t>(INFINITE - 1);
    return static_cast<DWORD>(std::min<std::int64_t>(rounded, kLongest));
}

// Khởi tạo tĩnh của exe chạy trên luồng chính trước main, nên mã luồng chụp ở đây là của luồng
// chính; setMainThread() của _Ref phải gọi tay. Không đúng nếu Forge2 được nạp dưới dạng DLL từ
// luồng khác.
[[nodiscard]] DWORD current_thread_id() noexcept {
    return GetCurrentThreadId();
}

const DWORD kMainThreadId = current_thread_id();

// std::string có destructor nên đi qua thread_slot, không khai thread_local thẳng (GCC MinGW, xem
// core/thread_slot.hpp).
[[nodiscard]] std::string& local_name() {
    return thread_slot([] { return std::string{}; });
}

// Tên hệ điều hành do mã khác đặt (thư viện ngoài, debugger); rỗng nếu chưa có.
[[nodiscard]] std::string system_name() {
    PWSTR text = nullptr;
    const HRESULT result = GetThreadDescription(GetCurrentThread(), &text);
    const std::unique_ptr<wchar_t, decltype(&LocalFree)> owned(text, &LocalFree);
    if (FAILED(result) || text == nullptr) return {};
    return narrow(text);
}

// Các bit của nhóm bộ xử lý bắt đầu ở chỉ số toàn cục first.
[[nodiscard]] KAFFINITY group_bits(const CpuSet& cpus, std::size_t first, std::size_t size) {
    KAFFINITY bits = 0;
    const std::size_t end = std::min(first + size, cpus.size());
    for (std::size_t i = first; i < end; ++i) {
        // Khác gốc: gốc viết if (cpus.test(i)) bits |= KAFFINITY{1} << (i - first).
        const KAFFINITY bit = cpus.test(i) ? 1 : 0;
        bits |= bit << (i - first);
    }
    return bits;
}

// Nhóm đầu tiên có CPU được chọn, cùng số nhóm có CPU được chọn. Nhóm không nhất thiết đủ 64 CPU
// nên đếm theo GetActiveProcessorCount từng nhóm; _Ref chia chỉ số cho 64 và lặp tới cpu/64, nên
// máy dưới 64 CPU không bao giờ được ghim.
struct Placement {
    std::optional<GROUP_AFFINITY> first;
    std::size_t groups = 0;
};

// Khác gốc: phần sau câu if (bits == 0) continue của vòng lặp trong place tách ra đây.
void add_group(Placement& placement, KAFFINITY bits, WORD group) {
    if (bits == 0) return;
    ++placement.groups;
    const GROUP_AFFINITY affinity{.Mask = bits, .Group = group, .Reserved = {}};
    if (!placement.first) placement.first = affinity;
}

[[nodiscard]] Placement place(const CpuSet& cpus) {
    Placement placement;
    std::size_t first = 0;
    const WORD groups = GetActiveProcessorGroupCount();
    for (WORD group = 0; group < groups; ++group) {
        const DWORD size = GetActiveProcessorCount(group);
        const KAFFINITY bits = group_bits(cpus, first, size);
        first += size;
        add_group(placement, bits, group);
    }
    return placement;
}

// SetThreadGroupAffinity trả khác 0 khi thành công; _Ref ghi lỗi đúng lúc thành công.
void pin(const CpuSet& cpus) {
    const Placement placement = place(cpus);
    if (!placement.first) {
        warn("Tập CPU không có CPU nào đang chạy, không ghim");
        return;
    }
    const WORD group = placement.first->Group;
    const bool spread = placement.groups > 1;
    if (spread) warn("Tập CPU trải {} nhóm, chỉ ghim nhóm {}", placement.groups, group);
    if (SetThreadGroupAffinity(GetCurrentThread(), &*placement.first, nullptr) != 0) return;
    warn("Không ghim được luồng vào nhóm {}: lỗi {}", group, GetLastError());
}

// Thân luồng do start_thread tạo; đặt mọi thứ trước khi chạy body.
class ThreadStart {
public:
    ThreadStart(ThreadConfig config, ThreadBody body) : config_(std::move(config)), body_(std::move(body)) {}

    void operator()(std::stop_token token) {
        // Khác gốc: gốc gọi reserve_crash_stack() ở đây cho trình báo crash của Forge2.
        if (!config_.name.empty()) set_thread_name(config_.name);
        if (config_.affinity.any()) pin(config_.affinity);
        if (config_.priority != ThreadPriority::kNormal) set_thread_priority(config_.priority);
        body_(std::move(token));
    }

private:
    ThreadConfig config_;
    ThreadBody body_;
};

} // namespace

void set_thread_name(std::string_view name) {
    local_name() = name;
    const HRESULT result = SetThreadDescription(GetCurrentThread(), widen(name).c_str());
    if (SUCCEEDED(result)) return;
    const auto code = static_cast<std::uint32_t>(result);
    warn("Không đặt được tên luồng '{}': HRESULT {:#010x}", name, code);
}

std::string_view thread_name() {
    std::string& name = local_name();
    if (!name.empty()) return name;
    name = system_name();
    if (!name.empty()) return name;
    name = is_main_thread() ? "chính" : std::to_string(GetCurrentThreadId());
    return name;
}

void set_thread_priority(ThreadPriority priority) noexcept {
    const int value = kPriorities.at(std::to_underlying(priority));
    if (SetThreadPriority(GetCurrentThread(), value) != 0) return;
    warn("Không đặt được ưu tiên luồng {}: lỗi {}", value, GetLastError());
}

bool is_main_thread() noexcept {
    return GetCurrentThreadId() == kMainThreadId;
}

std::uint32_t cpu_count() noexcept {
    return std::max<DWORD>(GetActiveProcessorCount(ALL_PROCESSOR_GROUPS), 1);
}

namespace {

// Khác gốc: thân vòng lặp của performance_cpus tách ra đây.
void mark_if_top(CpuSet& cpus, const CpuEntry& entry, BYTE top) {
    const std::size_t index = group_start(entry.group) + entry.index;
    // CpuSet chỉ có 1024 chỗ; set() ngoài tầm ném out_of_range, còn máy trên 1024 CPU logic thì
    // phần vượt không ghim được chứ không phải lỗi.
    if (entry.efficiency == top && index < cpus.size()) cpus.set(index);
}

} // namespace

CpuSet performance_cpus() {
    const std::vector<CpuEntry> entries = cpu_entries();
    CpuSet cpus;
    if (entries.empty()) return all_cpus();
    const BYTE top = std::ranges::max(entries, {}, &CpuEntry::efficiency).efficiency;
    for (const CpuEntry& entry : entries) {
        mark_if_top(cpus, entry, top);
    }
    return cpus;
}

namespace detail {

// WaitOnAddress và WakeByAddress* nhận con trỏ không const nhưng chỉ đọc vùng nhớ; bỏ const ở đây
// là đúng hợp đồng của API. C6553 của /analyze ở lời gọi là lỗi chú thích của SDK, tắt ở
// cmake/forge2.cmake.
// Hai con trỏ đứng theo đúng thứ tự tham số của WaitOnAddress (lệch API-03).
// NOLINTBEGIN(cppcoreguidelines-pro-type-const-cast,bugprone-easily-swappable-parameters)
bool park_address(const void* address, const void* old, std::size_t size, std::chrono::nanoseconds timeout) noexcept {
    auto* target = const_cast<void*>(address);
    auto* compare = const_cast<void*>(old);
    if (WaitOnAddress(target, compare, size, wait_milliseconds(timeout)) != 0) return true;
    return GetLastError() != ERROR_TIMEOUT;
}
// NOLINTEND(cppcoreguidelines-pro-type-const-cast,bugprone-easily-swappable-parameters)

} // namespace detail

// Cùng lý do bỏ const như park_address.
// NOLINTBEGIN(cppcoreguidelines-pro-type-const-cast)
void unpark_address(const void* address, Wake wake) noexcept {
    auto* target = const_cast<void*>(address);
    if (wake == Wake::kAll) {
        WakeByAddressAll(target);
        return;
    }
    WakeByAddressSingle(target);
}
// NOLINTEND(cppcoreguidelines-pro-type-const-cast)

std::jthread start_thread(ThreadConfig config, ThreadBody body) {
    return std::jthread(ThreadStart(std::move(config), std::move(body)));
}

} // namespace game::core
