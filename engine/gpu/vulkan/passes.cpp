// Render pass và framebuffer dựng theo nhu cầu, giữ trong hai bảng có khoá (passes.hpp).
// Một subpass, không phụ thuộc ngoài: bố cục đầu, trong và cuối của mỗi attachment trùng nhau nên
// không có chuyển bố cục ngầm, và barrier chỗ gọi ghi trước begin_rendering đồng bộ mọi thứ như với
// dynamic rendering.
#include "gpu/vulkan/passes.hpp"

#include "core/error.hpp"
#include "gpu/format.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/convert.hpp"

#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <mutex>
#include <span>
#include <utility>
#include <vector>

namespace game::gpu::vulkan {

namespace {

constexpr VkImageLayout kColorLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

[[nodiscard]] std::uint64_t number(VkImageView view) noexcept {
    return std::bit_cast<std::uint64_t>(view);
}

[[nodiscard]] std::uint64_t number(VkRenderPass pass) noexcept {
    return std::bit_cast<std::uint64_t>(pass);
}

[[nodiscard]] VkAttachmentDescription attachment(VkFormat format, VkSampleCountFlagBits samples,
    VkImageLayout layout) noexcept {
    VkAttachmentDescription description{};
    description.format = format;
    description.samples = samples;
    description.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    description.storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    description.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    description.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    description.initialLayout = layout;
    description.finalLayout = layout;
    return description;
}

[[nodiscard]] VkAttachmentReference unused() noexcept {
    return {.attachment = VK_ATTACHMENT_UNUSED, .layout = VK_IMAGE_LAYOUT_UNDEFINED};
}

// Mảng của VkRenderPassCreateInfo, giữ sống tới khi lời gọi tạo xong.
struct PassParts {
    std::vector<VkAttachmentDescription> attachments;
    std::array<VkAttachmentReference, kMaxColorTargets> colors{};
    std::array<VkAttachmentReference, kMaxColorTargets> resolves{};
    VkAttachmentReference depth{};
    bool has_resolve = false;
};

} // namespace

Passes::~Passes() {
    for (const auto& [key, framebuffer] : framebuffers_) {
        vkDestroyFramebuffer(device_, framebuffer, nullptr);
    }
    for (const auto& [key, pass] : passes_) {
        vkDestroyRenderPass(device_, pass, nullptr);
    }
}

Passes::PassKey Passes::key_of(const PassTargets& targets) const noexcept {
    PassKey key;
    key.color_count = targets.color_count;
    key.samples = targets.samples;
    for (std::uint32_t slot = 0; slot < targets.color_count; ++slot) {
        const ColorAttach& color = targets.colors.at(slot);
        if (color.view == VK_NULL_HANDLE) continue;
        ColorKey& wanted = key.colors.at(slot);
        wanted.format = color.format;
        wanted.load = color.load;
        wanted.store = color.store;
        wanted.is_resolved = color.resolve != VK_NULL_HANDLE;
    }
    const DepthAttach& depth = targets.depth;
    if (depth.view == VK_NULL_HANDLE) return key;
    key.depth = depth.format;
    key.depth_load = depth.load;
    key.depth_store = depth.store;
    key.is_depth_read_only = depth.is_read_only;
    const bool has_stencil_part = has_stencil(from_vk(depth.format));
    key.stencil_load = has_stencil_part ? depth.stencil_load : VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    key.stencil_store = has_stencil_part ? depth.stencil_store : VK_ATTACHMENT_STORE_OP_DONT_CARE;
    // Chỉ thử, không ghi: lưu lại là chép nguyên dữ liệu cũ ra bộ nhớ; STORE_OP_NONE bỏ hẳn lần chép ấy.
    const VkAttachmentStoreOp kept = store_none_ ? VK_ATTACHMENT_STORE_OP_NONE : VK_ATTACHMENT_STORE_OP_STORE;
    if (depth.is_read_only) key.depth_store = kept;
    if (depth.is_read_only && has_stencil_part) key.stencil_store = kept;
    return key;
}

core::Result<VkRenderPass> Passes::pass_for(const PassKey& key) {
    const auto known = passes_.find(key);
    if (known != passes_.end()) return known->second;
    PassParts parts;
    // Màu theo ô, rồi resolve theo ô, rồi độ sâu: đúng thứ tự view mà begin dựng framebuffer.
    for (std::uint32_t slot = 0; slot < key.color_count; ++slot) {
        const ColorKey& color = key.colors.at(slot);
        parts.colors.at(slot) = unused();
        if (color.format == VK_FORMAT_UNDEFINED) continue;
        VkAttachmentDescription description = attachment(color.format, key.samples, kColorLayout);
        description.loadOp = color.load;
        description.storeOp = color.store;
        const auto index = static_cast<std::uint32_t>(parts.attachments.size());
        parts.colors.at(slot) = {.attachment = index, .layout = kColorLayout};
        parts.attachments.push_back(description);
    }
    for (std::uint32_t slot = 0; slot < key.color_count; ++slot) {
        const ColorKey& color = key.colors.at(slot);
        parts.resolves.at(slot) = unused();
        if (!color.is_resolved) continue;
        VkAttachmentDescription description = attachment(color.format, VK_SAMPLE_COUNT_1_BIT, kColorLayout);
        description.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        const auto index = static_cast<std::uint32_t>(parts.attachments.size());
        parts.resolves.at(slot) = {.attachment = index, .layout = kColorLayout};
        parts.attachments.push_back(description);
        parts.has_resolve = true;
    }
    const bool has_depth_part = key.depth != VK_FORMAT_UNDEFINED;
    const VkImageLayout depth_layout = key.is_depth_read_only ? VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
                                                              : VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
    if (has_depth_part) {
        VkAttachmentDescription description = attachment(key.depth, key.samples, depth_layout);
        description.loadOp = key.depth_load;
        description.storeOp = key.depth_store;
        description.stencilLoadOp = key.stencil_load;
        description.stencilStoreOp = key.stencil_store;
        parts.depth = {.attachment = static_cast<std::uint32_t>(parts.attachments.size()), .layout = depth_layout};
        parts.attachments.push_back(description);
    }
    VkSubpassDescription subpass{};
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = key.color_count;
    subpass.pColorAttachments = parts.colors.data();
    subpass.pResolveAttachments = parts.has_resolve ? parts.resolves.data() : nullptr;
    subpass.pDepthStencilAttachment = has_depth_part ? &parts.depth : nullptr;
    VkRenderPassCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    info.attachmentCount = static_cast<std::uint32_t>(parts.attachments.size());
    info.pAttachments = parts.attachments.data();
    info.subpassCount = 1;
    info.pSubpasses = &subpass;
    VkRenderPass pass = VK_NULL_HANDLE;
    const VkResult created = vkCreateRenderPass(device_, &info, nullptr, &pass);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được render pass");
    passes_.emplace(key, pass);
    return pass;
}

core::Result<VkFramebuffer> Passes::framebuffer_for(const FramebufferKey& key) {
    const auto known = framebuffers_.find(key);
    if (known != framebuffers_.end()) return known->second;
    std::array<VkImageView, kMaxAttachments> views{};
    for (std::uint32_t index = 0; index < key.view_count; ++index) {
        views.at(index) = std::bit_cast<VkImageView>(key.views.at(index));
    }
    VkFramebufferCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    info.renderPass = std::bit_cast<VkRenderPass>(key.pass);
    info.attachmentCount = key.view_count;
    info.pAttachments = views.data();
    info.width = key.width;
    info.height = key.height;
    info.layers = key.layers;
    VkFramebuffer framebuffer = VK_NULL_HANDLE;
    const VkResult created = vkCreateFramebuffer(device_, &info, nullptr, &framebuffer);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được framebuffer");
    framebuffers_.emplace(key, framebuffer);
    return framebuffer;
}

core::Result<VkRenderPass> Passes::compatible(const PassFormats& formats) {
    PassKey key;
    if (formats.colors.size() > kMaxColorTargets) {
        return core::fail(core::ErrorCode::kInvalidArgument, "pipeline: quá nhiều đích màu");
    }
    key.color_count = static_cast<std::uint32_t>(formats.colors.size());
    key.samples = to_samples(formats.samples);
    for (std::uint32_t slot = 0; slot < key.color_count; ++slot) {
        const Format color = formats.colors.subspan(slot, 1).front();
        key.colors.at(slot).format = to_vk(is_raw_ ? raw_of(color) : color);
    }
    if (has_depth(formats.depth)) key.depth = to_vk(formats.depth);
    const std::scoped_lock lock(mutex_);
    return pass_for(key);
}

core::Status Passes::begin(VkCommandBuffer buffer, const PassTargets& targets, const VkRect2D& area) {
    const PassKey key = key_of(targets);
    FramebufferKey frame{.width = targets.width, .height = targets.height, .layers = targets.layers};
    std::array<VkClearValue, kMaxAttachments> clears{};
    const auto add = [&frame, &clears](VkImageView view, const VkClearValue& clear) {
        clears.at(frame.view_count) = clear;
        frame.views.at(frame.view_count) = number(view);
        ++frame.view_count;
    };
    for (std::uint32_t slot = 0; slot < targets.color_count; ++slot) {
        const ColorAttach& color = targets.colors.at(slot);
        if (color.view != VK_NULL_HANDLE) add(color.view, color.clear);
    }
    for (std::uint32_t slot = 0; slot < targets.color_count; ++slot) {
        const ColorAttach& color = targets.colors.at(slot);
        if (color.resolve != VK_NULL_HANDLE) add(color.resolve, VkClearValue{});
    }
    if (targets.depth.view != VK_NULL_HANDLE) add(targets.depth.view, targets.depth.clear);
    VkRenderPass pass = VK_NULL_HANDLE;
    VkFramebuffer framebuffer = VK_NULL_HANDLE;
    {
        const std::scoped_lock lock(mutex_);
        const core::Result<VkRenderPass> made = pass_for(key);
        if (!made) return std::unexpected(made.error());
        pass = *made;
        frame.pass = number(pass);
        const core::Result<VkFramebuffer> built = framebuffer_for(frame);
        if (!built) return std::unexpected(built.error());
        framebuffer = *built;
    }
    VkRenderPassBeginInfo info{};
    info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    info.renderPass = pass;
    info.framebuffer = framebuffer;
    info.renderArea = area;
    info.clearValueCount = frame.view_count;
    info.pClearValues = clears.data();
    vkCmdBeginRenderPass(buffer, &info, VK_SUBPASS_CONTENTS_INLINE);
    return core::ok();
}

void Passes::forget(VkImageView view) noexcept {
    const std::uint64_t wanted = number(view);
    const std::scoped_lock lock(mutex_);
    std::erase_if(framebuffers_, [this, wanted](const auto& entry) {
        const FramebufferKey& key = entry.first;
        const std::span used = std::span(key.views).first(key.view_count);
        const bool is_using = std::ranges::find(used, wanted) != used.end();
        if (is_using) vkDestroyFramebuffer(device_, entry.second, nullptr);
        return is_using;
    });
}

} // namespace game::gpu::vulkan
