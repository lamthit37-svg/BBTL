// Cửa vào Vulkan của backend: header của SDK, đổi VkResult sang lỗi của engine, và bảng hàm của
// phần mở rộng gỡ lỗi (loader không xuất các hàm ấy trong thư viện liên kết, phải hỏi từng hàm).
// vulkan.h ở đây không kéo windows.h; riêng phần bề mặt Win32 nằm trong một tệp nguồn của nó.
// Mức tối thiểu là Vulkan 1.1 (tablet PowerVR GE8320 của dự án báo 1.1.100): backend chỉ dùng hàm
// lõi 1.0 và 1.1, nên mọi hàm liên kết tĩnh được kể cả trên libvulkan.so của Android 10. Thứ chỉ có
// từ 1.2 trở lên (timeline semaphore, địa chỉ buffer, descriptor indexing) là tuỳ chọn, hỏi theo
// phiên bản của thiết bị; thứ của 1.3 (dynamic rendering, synchronization2) được thay bằng render
// pass (passes.hpp) và barrier sync1 (commands.cpp). Đồng bộ CPU với GPU dùng fence (device.cpp).
// Nguồn: Forge2 src/gpu/vulkan/api.hpp@d7fcd76. Khác gốc: mức tối thiểu 1.1 thay 1.3.
#pragma once

#include "core/error.hpp"

#include <vulkan/vulkan.h>

#include <bit>
#include <cstdint>
#include <string_view>

namespace game::gpu::vulkan {

inline constexpr std::uint32_t kApiVersion = VK_API_VERSION_1_1;

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
