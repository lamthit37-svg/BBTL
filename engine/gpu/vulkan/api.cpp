// Đổi VkResult thành tên đọc được và ErrorCode của engine.
// Rẽ trên số nguyên, không trên enum: C4061 đòi liệt kê mọi mã của SDK.
// Nhánh default gom các mã phần mở rộng mà engine không dùng.
// Nguồn: Forge2 src/gpu/vulkan/api.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; include trực
// tiếp header của mọi tên dùng tới.
#include "gpu/vulkan/api.hpp"

#include "core/error.hpp"

#include <cstdint>
#include <string_view>

#include <vulkan/vulkan_core.h>

namespace game::gpu::vulkan {

// VkResult có hàng chục mã của phần mở rộng không dùng tới; default gom chúng lại. Rẽ nhánh trên số
// nguyên: rẽ trên chính enum thì C4061 đòi liệt kê mọi enumerator của SDK.
std::string_view name(VkResult result) noexcept {
    switch (static_cast<std::int32_t>(result)) {
    case VK_SUCCESS: return "VK_SUCCESS";
    case VK_NOT_READY: return "VK_NOT_READY";
    case VK_TIMEOUT: return "VK_TIMEOUT";
    case VK_INCOMPLETE: return "VK_INCOMPLETE";
    case VK_SUBOPTIMAL_KHR: return "VK_SUBOPTIMAL_KHR";
    case VK_ERROR_OUT_OF_HOST_MEMORY: return "VK_ERROR_OUT_OF_HOST_MEMORY";
    case VK_ERROR_OUT_OF_DEVICE_MEMORY: return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
    case VK_ERROR_INITIALIZATION_FAILED: return "VK_ERROR_INITIALIZATION_FAILED";
    case VK_ERROR_DEVICE_LOST: return "VK_ERROR_DEVICE_LOST";
    case VK_ERROR_MEMORY_MAP_FAILED: return "VK_ERROR_MEMORY_MAP_FAILED";
    case VK_ERROR_LAYER_NOT_PRESENT: return "VK_ERROR_LAYER_NOT_PRESENT";
    case VK_ERROR_EXTENSION_NOT_PRESENT: return "VK_ERROR_EXTENSION_NOT_PRESENT";
    case VK_ERROR_FEATURE_NOT_PRESENT: return "VK_ERROR_FEATURE_NOT_PRESENT";
    case VK_ERROR_INCOMPATIBLE_DRIVER: return "VK_ERROR_INCOMPATIBLE_DRIVER";
    case VK_ERROR_TOO_MANY_OBJECTS: return "VK_ERROR_TOO_MANY_OBJECTS";
    case VK_ERROR_FORMAT_NOT_SUPPORTED: return "VK_ERROR_FORMAT_NOT_SUPPORTED";
    case VK_ERROR_FRAGMENTED_POOL: return "VK_ERROR_FRAGMENTED_POOL";
    case VK_ERROR_OUT_OF_POOL_MEMORY: return "VK_ERROR_OUT_OF_POOL_MEMORY";
    case VK_ERROR_SURFACE_LOST_KHR: return "VK_ERROR_SURFACE_LOST_KHR";
    case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
    case VK_ERROR_OUT_OF_DATE_KHR: return "VK_ERROR_OUT_OF_DATE_KHR";
    default: return "VkResult khác";
    }
}

core::ErrorCode code_of(VkResult result) noexcept {
    using core::ErrorCode;
    switch (static_cast<std::int32_t>(result)) {
    case VK_ERROR_OUT_OF_HOST_MEMORY:
    case VK_ERROR_OUT_OF_DEVICE_MEMORY:
    case VK_ERROR_OUT_OF_POOL_MEMORY:
    case VK_ERROR_FRAGMENTED_POOL: return ErrorCode::kOutOfMemory;
    case VK_ERROR_DEVICE_LOST: return ErrorCode::kDeviceLost;
    case VK_ERROR_LAYER_NOT_PRESENT:
    case VK_ERROR_EXTENSION_NOT_PRESENT:
    case VK_ERROR_FEATURE_NOT_PRESENT:
    case VK_ERROR_INCOMPATIBLE_DRIVER:
    case VK_ERROR_FORMAT_NOT_SUPPORTED: return ErrorCode::kUnsupported;
    case VK_ERROR_OUT_OF_DATE_KHR:
    case VK_ERROR_SURFACE_LOST_KHR: return ErrorCode::kInvalidState;
    case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: return ErrorCode::kBusy;
    case VK_ERROR_TOO_MANY_OBJECTS: return ErrorCode::kExhausted;
    case VK_TIMEOUT: return ErrorCode::kTimeout;
    case VK_NOT_READY: return ErrorCode::kWouldBlock;
    default: return ErrorCode::kInternal;
    }
}

core::Failure fail_vk(VkResult result, core::Message message) noexcept {
    return core::fail(code_of(result), message, name(result));
}

} // namespace game::gpu::vulkan
