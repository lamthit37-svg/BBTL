// VkInstance, lớp kiểm tra và danh sách thiết bị vật lý — phần initVulkanRendererContext và
// util_query_gpu của Vulkan.c trong _Ref, vulkan/context của Platium. Tách khỏi Device vì nó sống
// lâu hơn: mất thiết bị thì Device được dựng lại, instance thì không. Khác gốc: thiếu lớp kiểm tra
// trên máy thì ghi cảnh báo rồi chạy tiếp (không từ chối chạy vì thiếu công cụ gỡ lỗi); thông điệp
// của lớp kiểm tra đi vào log của engine; VK_EXT_debug_utils bật cả khi không kiểm tra, để nhãn và
// tên tài nguyên hiện trong RenderDoc.
// Nguồn: Forge2 src/gpu/vulkan/instance.hpp@d7fcd76. Khác gốc (so với Forge2): không.
#pragma once

#include "gpu/device.hpp"
#include "gpu/vulkan/api.hpp"

#include <atomic>
#include <memory>
#include <vector>

namespace game::gpu::vulkan {

struct PhysicalDevice {
    VkPhysicalDevice handle = VK_NULL_HANDLE;
    AdapterInfo info{};
};

class Instance {
    // Chìa khoá chỉ thành viên của lớp gọi tên được: hàm dựng công khai cho make_unique mà bên
    // ngoài vẫn không dựng được Instance dở dang.
    struct Key {
        explicit Key() = default;
    };

public:
    [[nodiscard]] static core::Result<std::unique_ptr<Instance>> create(bool is_validated);

    explicit Instance(Key /*key*/) noexcept {}
    ~Instance();
    Instance(const Instance&) = delete;
    Instance& operator=(const Instance&) = delete;
    Instance(Instance&&) = delete;
    Instance& operator=(Instance&&) = delete;

    [[nodiscard]] VkInstance handle() const noexcept { return instance_; }
    [[nodiscard]] bool has_debug_utils() const noexcept { return has_debug_utils_; }
    // Phần mở rộng bề mặt của nền tảng có mặt: tạo được swapchain.
    [[nodiscard]] bool has_surface() const noexcept { return has_surface_; }
    // Phiên bản Vulkan mà instance đã xin (1.1 tới 1.3, theo bộ nạp): trần của chức năng lõi dùng được.
    [[nodiscard]] std::uint32_t api_version() const noexcept { return api_version_; }
    [[nodiscard]] bool is_validated() const noexcept { return messenger_ != VK_NULL_HANDLE; }
    // Số thông điệp mức lỗi của lớp kiểm tra từ lúc tạo instance.
    [[nodiscard]] std::uint64_t errors() const noexcept { return errors_.load(); }

    // Thiết bị đạt Vulkan 1.1, theo thứ tự ưu tiên: rời, rồi tích hợp, rồi phần mềm; trong cùng
    // loại thì nhiều bộ nhớ trước. Unsupported khi không có thiết bị nào đạt.
    [[nodiscard]] core::Result<std::vector<PhysicalDevice>> devices() const;

private:
    VkInstance instance_ = VK_NULL_HANDLE;
    VkDebugUtilsMessengerEXT messenger_ = VK_NULL_HANDLE;
    std::uint32_t api_version_ = 0;
    bool has_debug_utils_ = false;
    bool has_surface_ = false;
    // Hàm gọi lại của lớp kiểm tra tăng bộ đếm này từ luồng bất kỳ.
    std::atomic<std::uint64_t> errors_{0};
};

} // namespace game::gpu::vulkan
