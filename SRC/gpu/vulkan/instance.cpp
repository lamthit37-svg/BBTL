// Tạo instance Vulkan, bật lớp kiểm tra và nhận thông điệp của lớp ấy.
// Tên extension surface viết bằng chuỗi để khỏi kéo vulkan_win32.h.
// Callback luôn trả VK_FALSE; chỉ lỗi loại VALIDATION mới tăng bộ đếm.
// Nguồn: Forge2 src/gpu/vulkan/instance.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; đầu
// Instance::create tách thành probe_support và wanted_extensions (ba cờ gom vào struct Support);
// thân vòng lặp của Instance::devices tách thành append_capable; phép cộng có điều kiện trong vòng
// lặp của device_local_bytes viết bằng ?:; AdapterInfo trong describe khai rồi gán trường; NOLINT
// của gốc ghi thêm lý do; include trực tiếp header của mọi tên dùng tới.
#include "gpu/vulkan/instance.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "gpu/device.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/api.hpp"

#include <vulkan/vk_platform.h>
#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gpu::vulkan {

namespace {

constexpr const char* kValidationLayer = "VK_LAYER_KHRONOS_validation";
// Tên chuỗi thay cho hằng của vulkan_win32.h: header ấy kéo windows.h. Android dùng bề mặt
// ANativeWindow của nó (tệp này không kéo vulkan_android.h chỉ vì một tên).
constexpr const char* kSurface = "VK_KHR_surface";
#if defined(__ANDROID__)
constexpr const char* kPlatformSurface = "VK_KHR_android_surface";
#else
constexpr const char* kPlatformSurface = "VK_KHR_win32_surface";
#endif

[[nodiscard]] std::vector<VkLayerProperties> layers() {
    std::uint32_t count = 0;
    vkEnumerateInstanceLayerProperties(&count, nullptr);
    std::vector<VkLayerProperties> list(count);
    vkEnumerateInstanceLayerProperties(&count, list.data());
    list.resize(count);
    return list;
}

[[nodiscard]] std::vector<VkExtensionProperties> extensions() {
    std::uint32_t count = 0;
    vkEnumerateInstanceExtensionProperties(nullptr, &count, nullptr);
    std::vector<VkExtensionProperties> list(count);
    vkEnumerateInstanceExtensionProperties(nullptr, &count, list.data());
    list.resize(count);
    return list;
}

[[nodiscard]] bool has_layer(std::span<const VkLayerProperties> list, std::string_view name) {
    const auto matches = [name](const VkLayerProperties& item) {
        return name == std::string_view(static_cast<const char*>(item.layerName));
    };
    return std::ranges::any_of(list, matches);
}

[[nodiscard]] bool has_extension(std::span<const VkExtensionProperties> list, std::string_view name) {
    const auto matches = [name](const auto& item) {
        return name == std::string_view(static_cast<const char*>(item.extensionName));
    };
    return std::ranges::any_of(list, matches);
}

// Khác gốc: ba cờ này là biến cục bộ của Instance::create ở gốc; gom lại để tách hàm.
struct Support {
    bool has_validation = false;
    bool has_debug = false;
    bool has_surface = false;
};

// Lớp kiểm tra và extension mà máy có. Khác gốc: đoạn này nằm ở đầu Instance::create của gốc
// (cognitive complexity 14, trần 10); thứ tự lời gọi Vulkan và câu cảnh báo giữ nguyên.
[[nodiscard]] Support probe_support(bool is_validated) {
    const std::vector<VkLayerProperties> known_layers = layers();
    const std::vector<VkExtensionProperties> known = extensions();
    const bool has_validation = is_validated && has_layer(known_layers, kValidationLayer);
    if (is_validated && !has_validation) {
        core::warn("vulkan: máy không có {}, chạy không kiểm tra", kValidationLayer);
    }
    const bool has_debug = has_extension(known, VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    const bool has_surface = has_extension(known, kSurface) && has_extension(known, kPlatformSurface);
    return {.has_validation = has_validation, .has_debug = has_debug, .has_surface = has_surface};
}

// Khác gốc: ba câu if dựng danh sách extension trong Instance::create của gốc tách ra đây.
[[nodiscard]] std::vector<const char*> wanted_extensions(const Support& support) {
    std::vector<const char*> wanted;
    if (support.has_surface) wanted.push_back(kSurface);
    if (support.has_surface) wanted.push_back(kPlatformSurface);
    if (support.has_debug) wanted.push_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    return wanted;
}

// Thông điệp của lớp kiểm tra vào log của engine. Luôn trả VK_FALSE: giá trị khác bảo lớp kiểm tra
// huỷ lời gọi đang xét. Không ngoại lệ nào được thoát qua biên giới hàm gọi lại của C.
VKAPI_ATTR VkBool32 VKAPI_CALL on_message(VkDebugUtilsMessageSeverityFlagBitsEXT severity,
    VkDebugUtilsMessageTypeFlagsEXT types, const VkDebugUtilsMessengerCallbackDataEXT* data, void* user) noexcept {
    if (data == nullptr || data->pMessage == nullptr) return VK_FALSE;
    const std::string_view text = data->pMessage;
    const bool is_error = severity >= VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    // Chỉ thông điệp loại VALIDATION là lỗi dùng sai API. Loại GENERAL mức lỗi là chuyện của máy
    // (loader không mở được tệp JSON của một lớp ngầm do phần mềm khác cài rồi gỡ dở): vẫn ghi log,
    // không tính vào bộ đếm.
    const bool is_misuse = (types & VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT) != 0;
    auto* const errors = static_cast<std::atomic<std::uint64_t>*>(user);
    if (is_error && is_misuse && errors != nullptr) errors->fetch_add(1);
    if (is_error) core::error("vulkan: {}", text);
    if (!is_error) core::warn("vulkan: {}", text);
    return VK_FALSE;
}

[[nodiscard]] VkDebugUtilsMessengerCreateInfoEXT messenger_info(std::atomic<std::uint64_t>& errors) noexcept {
    VkDebugUtilsMessengerCreateInfoEXT info{};
    info.pUserData = &errors;
    info.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    info.messageSeverity =
        VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    info.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
        VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    info.pfnUserCallback = on_message;
    return info;
}

[[nodiscard]] VkDebugUtilsMessengerEXT create_messenger(VkInstance instance,
    std::atomic<std::uint64_t>& errors) noexcept {
    using Create = PFN_vkCreateDebugUtilsMessengerEXT;
    const auto create = instance_function<Create>(instance, "vkCreateDebugUtilsMessengerEXT");
    if (create == nullptr) return VK_NULL_HANDLE;
    const VkDebugUtilsMessengerCreateInfoEXT info = messenger_info(errors);
    VkDebugUtilsMessengerEXT messenger = VK_NULL_HANDLE;
    create(instance, &info, nullptr, &messenger);
    return messenger;
}

void destroy_messenger(VkInstance instance, VkDebugUtilsMessengerEXT messenger) noexcept {
    using Destroy = PFN_vkDestroyDebugUtilsMessengerEXT;
    const auto destroy = instance_function<Destroy>(instance, "vkDestroyDebugUtilsMessengerEXT");
    if (destroy != nullptr) destroy(instance, messenger, nullptr);
}

[[nodiscard]] std::uint64_t device_local_bytes(VkPhysicalDevice device) noexcept {
    VkPhysicalDeviceMemoryProperties memory{};
    vkGetPhysicalDeviceMemoryProperties(device, &memory);
    std::uint64_t total = 0;
    for (const VkMemoryHeap& heap : std::span(memory.memoryHeaps).first(memory.memoryHeapCount)) {
        const bool is_local = (heap.flags & VK_MEMORY_HEAP_DEVICE_LOCAL_BIT) != 0;
        // Khác gốc: if (is_local) total += heap.size;
        total = is_local ? total + heap.size : total;
    }
    return total;
}

[[nodiscard]] AdapterInfo describe(VkPhysicalDevice device) {
    // {} đưa driverID về 0, không phải enumerator nào của VkDriverId; cấu trúc ra của Vulkan phải
    // xoá về 0 rồi điền sType, và lời gọi bên dưới ghi đè trường ấy (KG-02).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkPhysicalDeviceDriverProperties driver{};
    driver.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES;
    VkPhysicalDeviceProperties2 properties{};
    properties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
    properties.pNext = &driver;
    vkGetPhysicalDeviceProperties2(device, &properties);
    const VkPhysicalDeviceProperties& base = properties.properties;
    const std::string device_name(static_cast<const char*>(base.deviceName));
    // Khác gốc: gốc viết AdapterInfo info{.name = device_name, .backend = Backend::Vulkan}; trường
    // driver đã bỏ {} ở header nên designated initializer thiếu nó bị cảnh báo, khai rồi gán.
    AdapterInfo info;
    info.name = device_name;
    info.backend = Backend::kVulkan;
    info.vendor_id = base.vendorID;
    info.device_id = base.deviceID;
    info.memory_bytes = device_local_bytes(device);
    info.is_discrete = base.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU;
    info.is_software = base.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;
    const auto* driver_name = static_cast<const char*>(driver.driverName);
    const auto* driver_info = static_cast<const char*>(driver.driverInfo);
    info.driver = std::string(driver_name) + " " + std::string(driver_info);
    return info;
}

[[nodiscard]] bool reaches_api(VkPhysicalDevice device) noexcept {
    VkPhysicalDeviceProperties properties{};
    vkGetPhysicalDeviceProperties(device, &properties);
    return properties.apiVersion >= kApiVersion;
}

// Khác gốc: thân vòng lặp của Instance::devices tách ra đây (gốc: câu bảo vệ continue rồi
// push_back một aggregate khởi tạo ngay trong tham số). Thiết bị dưới Vulkan 1.3 bị bỏ qua.
void append_capable(std::vector<PhysicalDevice>& list, VkPhysicalDevice handle) {
    if (!reaches_api(handle)) return;
    PhysicalDevice device{.handle = handle, .info = describe(handle)};
    list.push_back(std::move(device));
}

// Hạng của một adapter: rời 0, tích hợp 1, phần mềm 2.
[[nodiscard]] int tier(const AdapterInfo& info) noexcept {
    if (info.is_software) return 2;
    return info.is_discrete ? 0 : 1;
}

[[nodiscard]] bool ranks_before(const PhysicalDevice& left, const PhysicalDevice& right) noexcept {
    const int left_tier = tier(left.info);
    const int right_tier = tier(right.info);
    if (left_tier != right_tier) return left_tier < right_tier;
    return left.info.memory_bytes > right.info.memory_bytes;
}

} // namespace

Instance::~Instance() {
    if (messenger_ != VK_NULL_HANDLE) destroy_messenger(instance_, messenger_);
    if (instance_ != VK_NULL_HANDLE) vkDestroyInstance(instance_, nullptr);
}

core::Result<std::unique_ptr<Instance>> Instance::create(bool is_validated) {
    if (!has_loader()) {
        return core::fail(core::ErrorCode::kUnsupported, "máy không có Vulkan (thiếu thư viện nạp)");
    }
    const Support support = probe_support(is_validated);
    std::vector<const char*> wanted_layers;
    if (support.has_validation) wanted_layers.push_back(kValidationLayer);
    const std::vector<const char*> wanted = wanted_extensions(support);

    VkApplicationInfo application{};
    application.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    application.pApplicationName = "Forge2";
    application.pEngineName = "Forge2";
    application.apiVersion = kApiVersion;
    auto instance = std::make_unique<Instance>(Key{});
    // Messenger gắn vào pNext để lỗi phát sinh ngay trong lúc tạo instance cũng được báo.
    const VkDebugUtilsMessengerCreateInfoEXT debug = messenger_info(instance->errors_);
    VkInstanceCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    info.pNext = support.has_validation && support.has_debug ? &debug : nullptr;
    info.pApplicationInfo = &application;
    info.enabledLayerCount = static_cast<std::uint32_t>(wanted_layers.size());
    info.ppEnabledLayerNames = wanted_layers.data();
    info.enabledExtensionCount = static_cast<std::uint32_t>(wanted.size());
    info.ppEnabledExtensionNames = wanted.data();

    const VkResult created = vkCreateInstance(&info, nullptr, &instance->instance_);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được instance Vulkan");
#if defined(__ANDROID__)
    // Loader Android API cũ không xuất tĩnh hàm lõi 1.2/1.3; xin qua instance (xem api.hpp).
    load_core_late(instance->instance_);
#endif
    instance->has_debug_utils_ = support.has_debug;
    instance->has_surface_ = support.has_surface;
    if (!support.has_validation || !support.has_debug) return instance;
    instance->messenger_ = create_messenger(instance->instance_, instance->errors_);
    return instance;
}

core::Result<std::vector<PhysicalDevice>> Instance::devices() const {
    std::uint32_t count = 0;
    const VkResult counted = vkEnumeratePhysicalDevices(instance_, &count, nullptr);
    if (counted != VK_SUCCESS) return fail_vk(counted, "không liệt kê được thiết bị Vulkan");
    std::vector<VkPhysicalDevice> handles(count);
    vkEnumeratePhysicalDevices(instance_, &count, handles.data());
    handles.resize(count);

    std::vector<PhysicalDevice> list;
    for (auto* const handle : handles) {
        append_capable(list, handle);
    }
    if (list.empty()) {
        return core::fail(core::ErrorCode::kUnsupported, "không thiết bị nào đạt Vulkan 1.3");
    }
    std::ranges::stable_sort(list, ranks_before);
    return list;
}

} // namespace game::gpu::vulkan
