/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/vulkan/surface_ios.mm
 *  PHÂN HỆ   : Gpu / Vulkan / Surface Ios
 *  CHUẨN     : Objective-C++
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần iOS của backend Vulkan: bề mặt từ CAMetalLayer qua
 *    VK_EXT_metal_surface, chạy trên MoltenVK nhúng trong ứng dụng (MoltenVK
 *    xuất đủ symbol Vulkan 1.3 nên không cần bảng nạp trễ như Android API cũ).
 *    Chưa build trên máy này (không có macOS); hợp đồng has_loader và
 *    create_surface giữ nguyên như surface_win32/surface_android mà
 *    swapchain.cpp đang gọi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn port: Forge2 src/gpu/vulkan/surface_win32.cpp@d7fcd76. Khác gốc: tệp mới của THIENLONG
// cho iOS.

#include "gpu/vulkan/swapchain.hpp"

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/instance.hpp"

#import <QuartzCore/CAMetalLayer.h>

#include <vulkan/vulkan_core.h>
#include <vulkan/vulkan_metal.h>

namespace game::gpu::vulkan {

// MoltenVK link tĩnh vào ứng dụng nên symbol Vulkan có sẵn từ lúc liên kết: không có loader để dò.
bool has_loader() noexcept {
    return true;
}

Result<VkSurfaceKHR> create_surface(const Instance& instance, void* window) {
    using core::ErrorCode;
    if (!instance.has_surface()) {
        return core::fail(ErrorCode::kUnsupported, "instance Vulkan không có phần mở rộng bề mặt");
    }
    if (window == nullptr) {
        return core::fail(ErrorCode::kInvalidArgument, "swapchain: CAMetalLayer là con trỏ rỗng");
    }
    auto* const layer = static_cast<CAMetalLayer*>(window);
    VkMetalSurfaceCreateInfoEXT info{};
    info.sType = VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
    info.pLayer = layer;
    VkSurfaceKHR surface = VK_NULL_HANDLE;
    const auto created =
        instance_function<PFN_vkCreateMetalSurfaceEXT>(instance.handle(), "vkCreateMetalSurfaceEXT");
    if (created == nullptr) {
        return core::fail(
            ErrorCode::kUnsupported, "thiết bị không có VK_EXT_metal_surface (MoltenVK)");
    }
    const VkResult made = created(instance.handle(), &info, nullptr, &surface);
    if (made != VK_SUCCESS) {
        return fail_vk(made, "không tạo được bề mặt Vulkan cho CAMetalLayer");
    }
    return surface;
}

// iOS: CAMetalLayer không có hàng thông điệp gắn với luồng như HWND, join suông là đủ.
void wait_builder(std::jthread& builder) noexcept {
    if (builder.joinable()) builder.join();
}

} // namespace game::gpu::vulkan
