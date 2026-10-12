// Luồng: tên, ưu tiên, luồng chính, số CPU, lõi hiệu năng, tạo luồng có tên và affinity, chờ trên
// địa chỉ có hạn — phần IThread/WindowsThread.c của _Ref không có sẵn trong STL. Phần còn lại dùng
// thẳng STL: Mutex/MutexLock là std::mutex và std::scoped_lock, ConditionVariable là
// std::condition_variable, callOnce là std::call_once, initThread/joinThread/detachThread là
// std::jthread. threadSleep là sleep_for ở core/clock.hpp; tải từng core ở core/system.hpp.
// Nguồn: Forge2 src/core/thread.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ khởi tạo {}
// thừa của thành viên có constructor mặc định.
#pragma once

#include "core/function.hpp"

#include <atomic>
#include <bitset>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>

namespace game::core {

// Tập CPU logic đánh số toàn cục qua mọi nhóm bộ xử lý, tối đa 1024 như affinityMask[16] của _Ref.
using CpuSet = std::bitset<1024>;

// Ưu tiên lập lịch của hệ điều hành. Pool nền (nạp tài nguyên, nén) chạy dưới Normal để không cướp
// lõi của vòng khung hình — thay hàng Low/Streaming của VnS, Wicked, No1.
enum class ThreadPriority : std::uint8_t {
    kLowest,
    kBelowNormal,
    kNormal,
    kAboveNormal,
    kHighest,
};

struct ThreadConfig {
    std::string name;
    // Rỗng thì không ghim. Windows chỉ ghim cứng được trong một nhóm bộ xử lý; tập trải nhiều nhóm
    // thì ghim nhóm đầu và ghi cảnh báo.
    CpuSet affinity;
    ThreadPriority priority = ThreadPriority::kNormal;
};

// Đặt tên luồng hiện tại cho log và debugger (SetThreadDescription). Không giới hạn 31 ký tự như
// _Ref.
void set_thread_name(std::string_view name);

// Tên luồng hiện tại: tên đã đặt, tên hệ điều hành nếu có ai đặt, "chính" cho luồng chính, còn lại
// là mã luồng. Mượn: sống tới khi luồng kết thúc hoặc đổi tên.
[[nodiscard]] std::string_view thread_name();

// Ưu tiên của luồng gọi; hệ điều hành từ chối thì giữ nguyên và ghi cảnh báo.
void set_thread_priority(ThreadPriority priority) noexcept;

[[nodiscard]] bool is_main_thread() noexcept;

// Số CPU logic trên mọi nhóm bộ xử lý. getNumCPUCores của _Ref chỉ đếm nhóm của luồng gọi (tối đa
// 64). Không bao giờ 0.
[[nodiscard]] std::uint32_t cpu_count() noexcept;

// CPU logic thuộc lớp hiệu năng cao nhất (lõi P của CPU lai như i5-14600KF;
// GetSystemCpuSetInformation, EfficiencyClass lớn nhất). Máy đồng nhất trả mọi CPU. Chỉ số như
// CpuSet.
[[nodiscard]] CpuSet performance_cpus();

// Thân luồng chỉ chuyển được. Trên MSVC đây là std::move_only_function.
using ThreadBody = MoveOnlyFunction<void(std::stop_token)>;

// Chạy body trên luồng mới đã đặt tên, ưu tiên, affinity và vùng stack dự phòng cho trình báo
// crash. jthread yêu cầu dừng rồi join khi huỷ; ngoại lệ thoát khỏi body là std::terminate.
[[nodiscard]] std::jthread start_thread(ThreadConfig config, ThreadBody body);

// Một hay mọi luồng đang park trên một địa chỉ.
enum class Wake : std::uint8_t {
    kOne,
    kAll,
};

// Đánh thức theo địa chỉ thô, cho nơi chỉ còn địa chỉ của một biến atomic có thể đã huỷ (bộ đếm của
// jobs): dựng tham chiếu tới atomic đã huỷ là UB, còn WakeByAddress* chỉ cần con trỏ. Địa chỉ phải
// trùng địa chỉ người chờ đã park. Bản có kiểu: unpark_one, unpark_all.
void unpark_address(const void* address, Wake wake) noexcept;

namespace detail {

[[nodiscard]] bool park_address(const void* address, const void* old, std::size_t size,
    std::chrono::nanoseconds timeout) noexcept;

} // namespace detail

// Atomic 4 hoặc 8 byte chờ được bằng WaitOnAddress.
template <class T>
concept Parkable = (sizeof(T) == 4 || sizeof(T) == 8) && std::atomic<T>::is_always_lock_free;

// Ngủ tới khi value khác old, có người unpark, hay hết timeout. Có thể thức giả: người gọi luôn
// kiểm lại điều kiện. Trả false khi hết hạn. Hạn làm tròn lên mili giây rồi theo nhịp hẹn giờ của
// hệ thống (đo 2026-10-01: hạn 30 ms thức sau 44,5 ms với nhịp mặc định 15,6 ms) — không dùng cho
// hạn chính xác dưới vài chục mili giây. std::atomic::wait không có hạn, mà wait_idle(timeout) cần.
template <Parkable T>
[[nodiscard]] bool park(const std::atomic<T>& value, T old, std::chrono::nanoseconds timeout) noexcept {
    // Ép tường minh: khi T là con trỏ thì &old là con trỏ hai tầng, và đổi ngầm sang const void* là
    // thứ clang-tidy chặn (bugprone-multi-level-implicit-pointer-conversion).
    return detail::park_address(&value, static_cast<const void*>(&old), sizeof(T), timeout);
}

template <Parkable T>
void unpark_one(const std::atomic<T>& value) noexcept {
    unpark_address(&value, Wake::kOne);
}

template <Parkable T>
void unpark_all(const std::atomic<T>& value) noexcept {
    unpark_address(&value, Wake::kAll);
}

} // namespace game::core
