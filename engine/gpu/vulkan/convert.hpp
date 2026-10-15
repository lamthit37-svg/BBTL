// Đổi kiểu của tầng đồ hoạ sang kiểu của Vulkan. Mỗi hàm là một bảng một chiều; không hàm nào có
// default trên enum của engine, nên thêm enumerator mà quên ở đây là lỗi dịch (C4062). Thay
// util_to_vk_* của Vulkan.c trong _Ref và convert.cpp của Platium.
// Nguồn: Forge2 src/gpu/vulkan/convert.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "gpu/barrier.hpp"
#include "gpu/device.hpp"
#include "gpu/vulkan/api.hpp"
#include "shader/reflection.hpp"

namespace game::gpu::vulkan {

[[nodiscard]] VkFormat to_vk(Format format) noexcept;
// Ngược của to_vk cho định dạng bề mặt; Unknown khi engine không có định dạng ấy.
[[nodiscard]] Format from_vk(VkFormat format) noexcept;
// Màu, độ sâu, hoặc độ sâu cộng stencil.
[[nodiscard]] VkImageAspectFlags aspect_of(Format format) noexcept;

[[nodiscard]] VkCompareOp to_vk(CompareOp value) noexcept;
[[nodiscard]] VkStencilOp to_vk(StencilOp value) noexcept;
[[nodiscard]] VkBlendFactor to_vk(BlendFactor value) noexcept;
[[nodiscard]] VkBlendOp to_vk(BlendOp value) noexcept;
[[nodiscard]] VkCullModeFlags to_vk(CullMode value) noexcept;
[[nodiscard]] VkFrontFace to_vk(FrontFace value) noexcept;
[[nodiscard]] VkPolygonMode to_vk(FillMode value) noexcept;
[[nodiscard]] VkPrimitiveTopology to_vk(Topology value) noexcept;
[[nodiscard]] VkIndexType to_vk(IndexType value) noexcept;
[[nodiscard]] VkAttachmentLoadOp to_vk(LoadOp value) noexcept;
[[nodiscard]] VkAttachmentStoreOp to_vk(StoreOp value) noexcept;
[[nodiscard]] VkFilter to_vk(Filter value) noexcept;
[[nodiscard]] VkSamplerMipmapMode to_mip_mode(Filter value) noexcept;
[[nodiscard]] VkSamplerAddressMode to_vk(AddressMode value) noexcept;
[[nodiscard]] VkBorderColor to_vk(BorderColor value) noexcept;
[[nodiscard]] VkPresentModeKHR to_vk(PresentMode value) noexcept;
[[nodiscard]] VkSampleCountFlagBits to_samples(std::uint32_t samples) noexcept;

[[nodiscard]] VkBufferUsageFlags to_vk(BufferUsage usage) noexcept;
[[nodiscard]] VkImageUsageFlags to_vk(TextureUsage usage) noexcept;
[[nodiscard]] VkImageType to_image_type(TextureKind kind) noexcept;
[[nodiscard]] VkImageViewType to_view_type(TextureKind kind) noexcept;

// Bit sync1; SyncStage::kNone ra 0 (chỗ gọi đổi thành TOP_OF_PIPE hay BOTTOM_OF_PIPE theo vế).
[[nodiscard]] VkPipelineStageFlags to_vk(SyncStage stages) noexcept;
[[nodiscard]] VkAccessFlags to_vk(Access access) noexcept;
[[nodiscard]] VkImageLayout to_vk(TextureLayout layout) noexcept;

[[nodiscard]] VkShaderStageFlagBits to_vk(shader::Stage stage) noexcept;
[[nodiscard]] VkShaderStageFlags to_vk(shader::StageSet stages) noexcept;
// VK_DESCRIPTOR_TYPE_MAX_ENUM cho loại backend chưa gắn được (texel buffer, input attachment,
// acceleration structure).
[[nodiscard]] VkDescriptorType to_vk(shader::ResourceKind kind) noexcept;

} // namespace game::gpu::vulkan
