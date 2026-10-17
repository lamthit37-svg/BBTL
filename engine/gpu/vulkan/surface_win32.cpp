/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/vulkan/surface_win32.cpp
 *  PHÂN HỆ   : Gpu / Vulkan / Surface Win32
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần Windows của backend Vulkan: bề mặt của cửa sổ, việc dò thư viện nạp
 *    và cách chờ luồng dựng swapchain mà không chặn thông điệp của cửa sổ. Tệp
 *    duy nhất của backend kéo windows.h: vulkan_win32.h cần HWND và HINSTANCE,
 *    phần còn lại chỉ thấy VkSurfaceKHR. Nguồn: Forge2
 *    src/gpu/vulkan/surface_win32.cpp@d7fcd76.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: enumerator mang tiền tố k; windows.h và macro của nó lấy từ core/win32.hpp (gốc khai ở
// CMake); include trực tiếp header của mọi tên dùng tới; hằng loader thành kLoader; biến handle
// khai auto* const.

#include "gpu/vulkan/swapchain.hpp"

#include "core/error.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/device.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/instance.hpp"

#include <libloaderapi.h>
#include <minwindef.h>
#include <winbase.h>
#include <windef.h>
#include <winuser.h>

#include <thread>

#include <vulkan/vulkan_core.h>
#include <vulkan/vulkan_win32.h>

namespace game::gpu::vulkan {

// Chỉ tìm trong System32, nơi trình điều khiển cài thư viện nạp: tìm theo tên trần là cửa cho DLL
// lạ nằm cạnh exe. Thư viện được giữ lại tới hết tiến trình, nên các hàm nạp trễ dùng đúng bản này.
bool has_loader() noexcept {
    static const HMODULE kLoader = LoadLibraryExW(L"vulkan-1.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    return kLoader != nullptr;
}

Result<VkSurfaceKHR> create_surface(const Instance& instance, void* window) {
    using core::ErrorCode;
    if (!instance.has_surface()) {
        return core::fail(ErrorCode::kUnsupported, "instance Vulkan không có phần mở rộng bề mặt");
    }
    auto* const handle = static_cast<HWND>(window);
    if (IsWindow(handle) == FALSE) {
        return core::fail(ErrorCode::kInvalidArgument, "swapchain: window không phải HWND còn sống");
    }
    VkWin32SurfaceCreateInfoKHR info{};
    info.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
    info.hinstance = GetModuleHandleW(nullptr);
    info.hwnd = handle;
    VkSurfaceKHR surface = VK_NULL_HANDLE;
    const VkResult created = vkCreateWin32SurfaceKHR(instance.handle(), &info, nullptr, &surface);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được bề mặt Vulkan cho cửa sổ");
    return surface;
}

// Trình điều khiển dựng swapchain qua DXGI có thể gửi thông điệp (SendMessage) tới cửa sổ rồi chờ
// trả lời. Cửa sổ thuộc chính luồng đang chờ (luồng vẽ của client), nên join suông là hai luồng chờ
// nhau mãi. PeekMessage với PM_QS_SENDMESSAGE chỉ xử lý thông điệp gửi tới; thông điệp xếp hàng
// (posted) để nguyên cho vòng thông điệp của cửa sổ.
void wait_builder(std::jthread& builder) noexcept {
    if (!builder.joinable()) return;
    auto* const thread = builder.native_handle();
    constexpr DWORD kSent = WAIT_OBJECT_0 + 1;
    DWORD woke = kSent;
    MSG message{};
    while (woke == kSent) {
        PeekMessageW(&message, nullptr, 0, 0, PM_NOREMOVE | PM_QS_SENDMESSAGE);
        woke = MsgWaitForMultipleObjectsEx(1, &thread, INFINITE, QS_SENDMESSAGE, 0);
    }
    builder.join();
}

} // namespace game::gpu::vulkan
