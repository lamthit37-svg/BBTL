// Probe Vulkan của thiết bị: in API cao nhất của mọi GPU và các extension quyết định khả năng
// chạy engine (synchronization2, dynamic_rendering, timeline_semaphore). Dịch bằng NDK clang rồi
// đẩy lên /data/local/tmp chạy qua adb shell.
#include <android/log.h>
#include <vulkan/vulkan.h>

#include <cstdio>
#include <string_view>
#include <vector>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "VulkanProbe", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "VulkanProbe", __VA_ARGS__)

int main() {
    VkApplicationInfo app{};
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.apiVersion = VK_API_VERSION_1_3;
    VkInstanceCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    info.pApplicationInfo = &app;
    VkInstance instance = VK_NULL_HANDLE;
    VkResult made = vkCreateInstance(&info, nullptr, &instance);
    LOGI("vkCreateInstance(1.3) = %d", static_cast<int>(made));
    printf("vkCreateInstance(1.3) = %d\n", static_cast<int>(made));
    if (made != VK_SUCCESS) return 1;
    std::uint32_t count = 0;
    vkEnumeratePhysicalDevices(instance, &count, nullptr);
    std::vector<VkPhysicalDevice> devices(count);
    vkEnumeratePhysicalDevices(instance, &count, devices.data());
    LOGI("số thiết bị: %u", count);
    for (VkPhysicalDevice device : devices) {
        VkPhysicalDeviceProperties props{};
        vkGetPhysicalDeviceProperties(device, &props);
        LOGI("thiết bị %s: API %u.%u.%u", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
            VK_API_VERSION_MINOR(props.apiVersion), VK_API_VERSION_PATCH(props.apiVersion));
        std::uint32_t ext_count = 0;
        vkEnumerateDeviceExtensionProperties(device, nullptr, &ext_count, nullptr);
        std::vector<VkExtensionProperties> exts(ext_count);
        vkEnumerateDeviceExtensionProperties(device, nullptr, &ext_count, exts.data());
        for (const VkExtensionProperties& ext : exts) {
            const bool is_key =
                std::string_view(ext.extensionName).find("synchronization2") != std::string_view::npos ||
                std::string_view(ext.extensionName).find("dynamic_rendering") != std::string_view::npos ||
                std::string_view(ext.extensionName).find("timeline_semaphore") != std::string_view::npos ||
                std::string_view(ext.extensionName).find("android_surface") != std::string_view::npos;
            if (is_key) LOGI("  extension: %s", ext.extensionName);
        }
    }
    vkDestroyInstance(instance, nullptr);
    return 0;
}
