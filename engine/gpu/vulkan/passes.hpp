// Render pass và framebuffer của backend Vulkan thay dynamic rendering (lõi 1.3): thiết bị 1.1
// (tablet PowerVR GE8320 của dự án báo 1.1.100) chỉ có VkRenderPass. Mỗi lần begin_rendering tra
// một render pass theo định dạng, số mẫu và load/store, rồi một framebuffer theo đúng các view; cả
// hai giữ tới khi thiết bị huỷ (render pass) hoặc tới khi một view của nó bị huỷ (framebuffer).
// Bố cục của attachment không đổi trong pass: màu ở COLOR_ATTACHMENT_OPTIMAL, độ sâu ở
// DEPTH_STENCIL_ATTACHMENT_OPTIMAL (hay READ_ONLY khi chỉ thử). Barrier của chỗ gọi đặt bố cục ấy
// trước begin_rendering như với dynamic rendering, nên pass không có phụ thuộc ngoài nào.
// Thứ tự attachment: màu theo ô (bỏ ô trống), rồi resolve theo ô, rồi độ sâu.
#pragma once

#include "core/error.hpp"
#include "gpu/format.hpp"
#include "gpu/types.hpp"

#include <vulkan/vulkan_core.h>

#include <array>
#include <compare> // IWYU pragma: keep (operator<=> mặc định)
#include <cstddef>
#include <cstdint>
#include <map>
#include <mutex>
#include <span>

namespace game::gpu::vulkan {

struct ColorAttach {
    // VK_NULL_HANDLE là ô bỏ trống.
    VkImageView view = VK_NULL_HANDLE;
    // Khác rỗng: view đa mẫu được resolve vào đây lúc kết thúc pass.
    VkImageView resolve = VK_NULL_HANDLE;
    VkFormat format = VK_FORMAT_UNDEFINED;
    VkAttachmentLoadOp load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    VkClearValue clear{};
};

struct DepthAttach {
    // VK_NULL_HANDLE là pass không có độ sâu.
    VkImageView view = VK_NULL_HANDLE;
    VkFormat format = VK_FORMAT_UNDEFINED;
    VkAttachmentLoadOp load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    VkAttachmentLoadOp stencil_load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp stencil_store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    bool is_read_only = false;
    VkClearValue clear{};
};

// Mọi thứ của một lần begin_rendering, đã kiểm tay nắm.
struct PassTargets {
    std::array<ColorAttach, kMaxColorTargets> colors{};
    std::uint32_t color_count = 0;
    DepthAttach depth{};
    VkSampleCountFlagBits samples = VK_SAMPLE_COUNT_1_BIT;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t layers = 1;
};

// Định dạng của các đích mà một pipeline vẽ vào; Format::kUnknown ở ô màu là ô bỏ trống.
struct PassFormats {
    std::span<const Format> colors;
    Format depth = Format::kUnknown;
    std::uint32_t samples = 1;
};

class Passes {
public:
    // store_none: thiết bị có VK_ATTACHMENT_STORE_OP_NONE (1.3 hay VK_EXT_load_store_op_none) để độ sâu
    // chỉ đọc khỏi bị ghi lại ra bộ nhớ; không có thì độ sâu chỉ đọc vẫn STORE (đúng, tốn băng thông).
    // is_raw: thiết bị màu thô (DeviceDesc::is_raw_color): định dạng sRGB của pipeline đổi sang UNORM như mọi tài nguyên.
    Passes(VkDevice device, bool store_none, bool is_raw) noexcept
        : device_(device), store_none_(store_none), is_raw_(is_raw) {}
    // Gọi khi GPU đã rỗi.
    ~Passes();
    Passes(const Passes&) = delete;
    Passes& operator=(const Passes&) = delete;
    Passes(Passes&&) = delete;
    Passes& operator=(Passes&&) = delete;

    // Render pass tương thích cho pipeline (đặc tả: load/store và bố cục không ảnh hưởng tương thích;
    // pass một subpass bỏ qua resolve). Sống tới khi thiết bị huỷ.
    [[nodiscard]] core::Result<VkRenderPass> compatible(const PassFormats& formats);
    // vkCmdBeginRenderPass với pass và framebuffer của targets. area nằm trong cỡ của targets.
    [[nodiscard]] core::Status begin(VkCommandBuffer buffer, const PassTargets& targets, const VkRect2D& area);
    // Huỷ mọi framebuffer có view; gọi ngay trước vkDestroyImageView, khi GPU đã qua mọi lần dùng view.
    void forget(VkImageView view) noexcept;

private:
    // Khoá của render pass: mọi thứ của VkRenderPassCreateInfo. Tay nắm Vulkan lưu thành số để so
    // sánh có thứ tự toàn phần (so con trỏ không cùng mảng là không xác định).
    struct ColorKey {
        VkFormat format = VK_FORMAT_UNDEFINED;
        VkAttachmentLoadOp load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        VkAttachmentStoreOp store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        bool is_resolved = false;
        auto operator<=>(const ColorKey&) const = default;
    };
    struct PassKey {
        std::array<ColorKey, kMaxColorTargets> colors{};
        std::uint32_t color_count = 0;
        VkSampleCountFlagBits samples = VK_SAMPLE_COUNT_1_BIT;
        VkFormat depth = VK_FORMAT_UNDEFINED;
        VkAttachmentLoadOp depth_load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        VkAttachmentStoreOp depth_store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        VkAttachmentLoadOp stencil_load = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        VkAttachmentStoreOp stencil_store = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        bool is_depth_read_only = false;
        auto operator<=>(const PassKey&) const = default;
    };
    // Màu, resolve và độ sâu: tối đa 2 * kMaxColorTargets + 1 attachment.
    static constexpr std::size_t kMaxAttachments = std::size_t{2} * kMaxColorTargets + 1;
    struct FramebufferKey {
        std::uint64_t pass = 0;
        std::array<std::uint64_t, kMaxAttachments> views{};
        std::uint32_t view_count = 0;
        std::uint32_t width = 0;
        std::uint32_t height = 0;
        std::uint32_t layers = 0;
        auto operator<=>(const FramebufferKey&) const = default;
    };

    [[nodiscard]] PassKey key_of(const PassTargets& targets) const noexcept;
    // Gọi khi đang giữ mutex_.
    [[nodiscard]] core::Result<VkRenderPass> pass_for(const PassKey& key);
    [[nodiscard]] core::Result<VkFramebuffer> framebuffer_for(const FramebufferKey& key);

    VkDevice device_;
    bool store_none_;
    bool is_raw_;
    // Bảo vệ passes_ và framebuffers_: nhiều luồng ghi lệnh cùng lúc.
    std::mutex mutex_;
    std::map<PassKey, VkRenderPass> passes_;
    std::map<FramebufferKey, VkFramebuffer> framebuffers_;
};

} // namespace game::gpu::vulkan
