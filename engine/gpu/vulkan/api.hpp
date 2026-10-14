// Cửa vào Vulkan của backend: header của SDK, đổi VkResult sang lỗi của engine, và bảng hàm của
// phần mở rộng gỡ lỗi (loader không xuất các hàm ấy trong thư viện liên kết, phải hỏi từng hàm).
// vulkan.h ở đây không kéo windows.h; riêng phần bề mặt Win32 nằm trong một tệp nguồn của nó.
// Mức tối thiểu là Vulkan 1.3: dynamic rendering, synchronization2 và timeline semaphore là lõi ở
// mức đó, nên backend không có đường lùi nào cho ba thứ ấy (cách của Platium; _Ref còn giữ render
// pass và fence nhị phân cho Vulkan 1.0).
// Nguồn: Forge2 src/gpu/vulkan/api.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "core/error.hpp"

#include <vulkan/vulkan.h>

#include <bit>
#include <cstdint>
#include <string_view>

namespace game::gpu::vulkan {

inline constexpr std::uint32_t kApiVersion = VK_API_VERSION_1_3;

// Máy có thư viện nạp Vulkan (vulkan-1.dll). Thư viện ấy được liên kết kiểu nạp trễ: exe vẫn chạy
// trên máy không có trình điều khiển Vulkan, miễn là không hàm Vulkan nào được gọi khi hàm này trả
// false. Instance::create là cửa duy nhất và nó hỏi trước.
[[nodiscard]] bool has_loader() noexcept;

// Tên hằng của VkResult ("VK_ERROR_DEVICE_LOST"); mã lạ thì "VkResult khác".
[[nodiscard]] std::string_view name(VkResult result) noexcept;

// Chỉ tách những mã khác nhau về cách xử lý; phần còn lại là Internal.
[[nodiscard]] core::ErrorCode code_of(VkResult result) noexcept;

// Lỗi của một lời gọi Vulkan: mã của engine, thông điệp của chỗ gọi, tên VkResult làm chi tiết.
[[nodiscard]] core::Failure fail_vk(VkResult result, core::Message message) noexcept;

// Hàm lõi của Vulkan 1.2/1.3 mà backend dùng. Trên Windows liên kết trực tiếp được; trên Android
// API cũ, loader (libvulkan.so) không xuất tĩnh các symbol này và bionic buộc giải mọi symbol lúc
// nạp, nên phải xin con trỏ qua vkGetInstanceProcAddr — hợp đồng của loader với mọi hàm lõi.
struct CoreLate {
    PFN_vkGetSemaphoreCounterValue semaphore_counter = nullptr;
    PFN_vkWaitSemaphores wait_semaphores = nullptr;
    PFN_vkSignalSemaphore signal_semaphore = nullptr;
    PFN_vkQueueSubmit2 submit2 = nullptr;
    PFN_vkGetBufferDeviceAddress buffer_address = nullptr;
    PFN_vkCmdPipelineBarrier2 cmd_pipeline_barrier2 = nullptr;
    PFN_vkCmdBeginRendering cmd_begin_rendering = nullptr;
    PFN_vkCmdEndRendering cmd_end_rendering = nullptr;
    PFN_vkCmdWriteTimestamp2 cmd_write_timestamp2 = nullptr;
};

#if defined(__ANDROID__)
// Nạp mọi con trỏ CoreLate từ instance; gọi một lần ngay sau vkCreateInstance thành công.
void load_core_late(VkInstance instance) noexcept;
// Con trỏ đã nạp; chỉ dùng sau khi Instance::create chạy xong.
[[nodiscard]] CoreLate& core_late() noexcept;
#else
// Windows: liên kết trực tiếp, không cần con trỏ.
[[nodiscard]] inline CoreLate& core_late() noexcept {
    // Không bao giờ đọc trên Windows; trả về đối tượng tĩnh để chữ ký dùng được chung.
    static CoreLate unused;
    return unused;
}
#endif

// NOLINTBEGIN(bugprone-easily-swappable-parameters): chữ ký giữ nguyên của Vk, sai thứ tự
// tham số là sai API (lệch API-03).
// Bọc 8 chỗ gọi: Windows gọi symbol trực tiếp, Android gọi con trỏ loader.
inline VkResult semaphore_counter(VkDevice device, VkSemaphore sem, std::uint64_t* value) noexcept {
#if defined(__ANDROID__)
    return core_late().semaphore_counter(device, sem, value);
#else
    static_cast<void>(core_late());
    return vkGetSemaphoreCounterValue(device, sem, value);
#endif
}

inline VkResult wait_semaphores(VkDevice device, const VkSemaphoreWaitInfo* info, std::uint64_t nanos) noexcept {
#if defined(__ANDROID__)
    return core_late().wait_semaphores(device, info, nanos);
#else
    static_cast<void>(core_late());
    return vkWaitSemaphores(device, info, nanos);
#endif
}

inline VkResult signal_semaphore(VkDevice device, const VkSemaphoreSignalInfo* info) noexcept {
#if defined(__ANDROID__)
    return core_late().signal_semaphore(device, info);
#else
    static_cast<void>(core_late());
    return vkSignalSemaphore(device, info);
#endif
}

inline VkResult submit2(VkQueue queue, std::uint32_t count, const VkSubmitInfo2* info, VkFence fence) noexcept {
#if defined(__ANDROID__)
    return core_late().submit2(queue, count, info, fence);
#else
    static_cast<void>(core_late());
    return vkQueueSubmit2(queue, count, info, fence);
#endif
}

inline VkDeviceAddress buffer_address(VkDevice device, const VkBufferDeviceAddressInfo* info) noexcept {
#if defined(__ANDROID__)
    return core_late().buffer_address(device, info);
#else
    static_cast<void>(core_late());
    return vkGetBufferDeviceAddress(device, info);
#endif
}

inline void cmd_pipeline_barrier2(VkCommandBuffer buffer, const VkDependencyInfo* info) noexcept {
#if defined(__ANDROID__)
    core_late().cmd_pipeline_barrier2(buffer, info);
#else
    vkCmdPipelineBarrier2(buffer, info);
#endif
}

inline void cmd_begin_rendering(VkCommandBuffer buffer, const VkRenderingInfo* info) noexcept {
#if defined(__ANDROID__)
    core_late().cmd_begin_rendering(buffer, info);
#else
    vkCmdBeginRendering(buffer, info);
#endif
}

inline void cmd_end_rendering(VkCommandBuffer buffer) noexcept {
#if defined(__ANDROID__)
    core_late().cmd_end_rendering(buffer);
#else
    vkCmdEndRendering(buffer);
#endif
}

inline void cmd_write_timestamp2(VkCommandBuffer buffer, VkPipelineStageFlags2 stage, VkQueryPool pool,
    std::uint32_t query) noexcept {
#if defined(__ANDROID__)
    core_late().cmd_write_timestamp2(buffer, stage, pool, query);
#else
    static_cast<void>(core_late());
    vkCmdWriteTimestamp2(buffer, stage, pool, query);
#endif
}

// Hàm của một phần mở rộng theo tên; null khi phần mở rộng không bật. Loader trả con trỏ hàm không
// kiểu, ép về chữ ký của đúng tên đã hỏi là hợp đồng của API.
template <class Function>
[[nodiscard]] Function instance_function(VkInstance instance, const char* name) noexcept {
    // bit_cast chứ không reinterpret_cast: Clang -Wcast-function-type-strict chặn ép giữa hai chữ ký hàm (BAY-DA-BIET).
    // NOLINTNEXTLINE(bugprone-bitwise-pointer-cast): con trỏ hàm do trình nạp Vulkan trả đúng chữ ký đã hỏi theo tên.
    return std::bit_cast<Function>(vkGetInstanceProcAddr(instance, name));
}

template <class Function>
[[nodiscard]] Function device_function(VkDevice device, const char* name) noexcept {
    // NOLINTNEXTLINE(bugprone-bitwise-pointer-cast): xem instance_function.
    return std::bit_cast<Function>(vkGetDeviceProcAddr(device, name));
}

// Hàm của VK_EXT_debug_utils trên một thiết bị; null khi phần mở rộng không bật.
struct DebugApi {
    PFN_vkSetDebugUtilsObjectNameEXT set_name = nullptr;
    PFN_vkCmdBeginDebugUtilsLabelEXT begin_label = nullptr;
    PFN_vkCmdEndDebugUtilsLabelEXT end_label = nullptr;
    PFN_vkCmdInsertDebugUtilsLabelEXT insert_label = nullptr;
};

} // namespace game::gpu::vulkan
// NOLINTEND(bugprone-easily-swappable-parameters)
