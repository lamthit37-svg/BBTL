/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/vulkan/surface_android.cpp
 *  PHÂN HỆ   : Gpu / Vulkan / Surface Android
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần Android của backend Vulkan: bề mặt của cửa sổ và việc dò thư viện
 *    nạp. ANativeWindow do NativeActivity trao qua android_app->window;
 *    libvulkan.so được liên kết trực tiếp ở lần nạp tiến trình nên has_loader
 *    chỉ việc xác nhận nó mở được — thiết bị không có Vulkan vẫn có thư viện
 *    khoá này, việc hỏng sẽ hiện ở vkCreateInstance và Instance::create trả
 *    Unsupported. Nguồn port: Forge2 src/gpu/vulkan/surface_win32.cpp@d7fcd76.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: tệp mới của THIENLONG cho Android; giữ nguyên hợp đồng has_loader/create_surface mà
// swapchain.cpp đang gọi.

#include "gpu/vulkan/swapchain.hpp"

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/instance.hpp"

#include <dlfcn.h>

#include <android/native_window.h>

#include <vulkan/vulkan_core.h>
// vulkan_android.h dùng VkFlags và VkStructureType mà không tự include vulkan_core.h: phải đứng
// sau.
#include <vulkan/vulkan_android.h>

namespace game::gpu::vulkan {

bool has_loader() noexcept {
    // Liên kết đã có libvulkan.so; dlopen để biết thư viện thật sự mở được trên máy này.
    void* const loader = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
    if (loader == nullptr) return false;
    dlclose(loader);
    return true;
}

Result<VkSurfaceKHR> create_surface(const Instance& instance, void* window) {
    using core::ErrorCode;
    if (!instance.has_surface()) {
        return core::fail(ErrorCode::kUnsupported, "instance Vulkan không có phần mở rộng bề mặt");
    }
    if (window == nullptr) {
        return core::fail(ErrorCode::kInvalidArgument, "swapchain: ANativeWindow là con trỏ rỗng");
    }
    auto* const handle = static_cast<ANativeWindow*>(window);
    VkAndroidSurfaceCreateInfoKHR info{};
    info.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
    info.window = handle;
    VkSurfaceKHR surface = VK_NULL_HANDLE;
    const VkResult created = vkCreateAndroidSurfaceKHR(instance.handle(), &info, nullptr, &surface);
    if (created != VK_SUCCESS) {
        return fail_vk(created, "không tạo được bề mặt Vulkan cho ANativeWindow");
    }
    return surface;
}

// Android: ANativeWindow không có hàng thông điệp gắn với luồng như HWND, join suông là đủ.
void wait_builder(std::jthread& builder) noexcept {
    if (builder.joinable()) builder.join();
}

} // namespace game::gpu::vulkan
