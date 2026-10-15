// Đổi Format, cờ sử dụng và giai đoạn đồng bộ của engine sang hằng Vulkan.
// Bảng định dạng cùng thứ tự enum Format; mỗi cờ đang bật được OR vào bit Vulkan.
// Nguồn: Forge2 src/gpu/vulkan/convert.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; hàng của
// bốn bảng cờ ghi tên trường (.flag, .bits); phép OR có điều kiện trong vòng lặp của map_flags và
// to_vk(StageSet) viết bằng ?:; include trực tiếp header của mọi tên dùng tới.
#include "gpu/vulkan/convert.hpp"

#include "gpu/barrier.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace game::gpu::vulkan {

namespace {

// Cùng thứ tự với enum Format.
constexpr std::array<VkFormat, kFormatCount> kFormats{
    VK_FORMAT_UNDEFINED,
    VK_FORMAT_R8_UNORM,
    VK_FORMAT_R8_SNORM,
    VK_FORMAT_R8_UINT,
    VK_FORMAT_R8_SINT,
    VK_FORMAT_R8G8_UNORM,
    VK_FORMAT_R8G8_SNORM,
    VK_FORMAT_R8G8_UINT,
    VK_FORMAT_R8G8_SINT,
    VK_FORMAT_R8G8B8A8_UNORM,
    VK_FORMAT_R8G8B8A8_SRGB,
    VK_FORMAT_R8G8B8A8_SNORM,
    VK_FORMAT_R8G8B8A8_UINT,
    VK_FORMAT_R8G8B8A8_SINT,
    VK_FORMAT_B8G8R8A8_UNORM,
    VK_FORMAT_B8G8R8A8_SRGB,
    VK_FORMAT_R16_UNORM,
    VK_FORMAT_R16_SNORM,
    VK_FORMAT_R16_UINT,
    VK_FORMAT_R16_SINT,
    VK_FORMAT_R16_SFLOAT,
    VK_FORMAT_R16G16_UNORM,
    VK_FORMAT_R16G16_SNORM,
    VK_FORMAT_R16G16_UINT,
    VK_FORMAT_R16G16_SINT,
    VK_FORMAT_R16G16_SFLOAT,
    VK_FORMAT_R16G16B16A16_UNORM,
    VK_FORMAT_R16G16B16A16_SNORM,
    VK_FORMAT_R16G16B16A16_UINT,
    VK_FORMAT_R16G16B16A16_SINT,
    VK_FORMAT_R16G16B16A16_SFLOAT,
    VK_FORMAT_R32_UINT,
    VK_FORMAT_R32_SINT,
    VK_FORMAT_R32_SFLOAT,
    VK_FORMAT_R32G32_UINT,
    VK_FORMAT_R32G32_SINT,
    VK_FORMAT_R32G32_SFLOAT,
    VK_FORMAT_R32G32B32_UINT,
    VK_FORMAT_R32G32B32_SINT,
    VK_FORMAT_R32G32B32_SFLOAT,
    VK_FORMAT_R32G32B32A32_UINT,
    VK_FORMAT_R32G32B32A32_SINT,
    VK_FORMAT_R32G32B32A32_SFLOAT,
    VK_FORMAT_A2B10G10R10_UNORM_PACK32,
    VK_FORMAT_A2B10G10R10_UINT_PACK32,
    VK_FORMAT_B10G11R11_UFLOAT_PACK32,
    VK_FORMAT_E5B9G9R9_UFLOAT_PACK32,
    VK_FORMAT_D16_UNORM,
    VK_FORMAT_D24_UNORM_S8_UINT,
    VK_FORMAT_D32_SFLOAT,
    VK_FORMAT_D32_SFLOAT_S8_UINT,
    VK_FORMAT_BC1_RGBA_UNORM_BLOCK,
    VK_FORMAT_BC1_RGBA_SRGB_BLOCK,
    VK_FORMAT_BC2_UNORM_BLOCK,
    VK_FORMAT_BC2_SRGB_BLOCK,
    VK_FORMAT_BC3_UNORM_BLOCK,
    VK_FORMAT_BC3_SRGB_BLOCK,
    VK_FORMAT_BC4_UNORM_BLOCK,
    VK_FORMAT_BC4_SNORM_BLOCK,
    VK_FORMAT_BC5_UNORM_BLOCK,
    VK_FORMAT_BC5_SNORM_BLOCK,
    VK_FORMAT_BC6H_UFLOAT_BLOCK,
    VK_FORMAT_BC6H_SFLOAT_BLOCK,
    VK_FORMAT_BC7_UNORM_BLOCK,
    VK_FORMAT_BC7_SRGB_BLOCK,
    VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK,
    VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK,
    VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK,
    VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK,
    VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK,
    VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK,
    VK_FORMAT_EAC_R11_UNORM_BLOCK,
    VK_FORMAT_EAC_R11_SNORM_BLOCK,
    VK_FORMAT_EAC_R11G11_UNORM_BLOCK,
    VK_FORMAT_EAC_R11G11_SNORM_BLOCK,
    VK_FORMAT_ASTC_4x4_UNORM_BLOCK,
    VK_FORMAT_ASTC_4x4_SRGB_BLOCK,
    VK_FORMAT_ASTC_5x5_UNORM_BLOCK,
    VK_FORMAT_ASTC_5x5_SRGB_BLOCK,
    VK_FORMAT_ASTC_6x6_UNORM_BLOCK,
    VK_FORMAT_ASTC_6x6_SRGB_BLOCK,
    VK_FORMAT_ASTC_8x8_UNORM_BLOCK,
    VK_FORMAT_ASTC_8x8_SRGB_BLOCK,
    VK_FORMAT_ASTC_10x10_UNORM_BLOCK,
    VK_FORMAT_ASTC_10x10_SRGB_BLOCK,
    VK_FORMAT_ASTC_12x12_UNORM_BLOCK,
    VK_FORMAT_ASTC_12x12_SRGB_BLOCK,
};

// Một bit của cờ engine và các bit Vulkan ứng với nó.
template <class Flag, class Bits>
struct FlagRow {
    Flag flag;
    Bits bits;
};

// Hợp các bit Vulkan của mọi cờ engine đang bật trong value.
template <class Flag, class Bits, std::size_t Count>
[[nodiscard]] Bits map_flags(Flag value, const std::array<FlagRow<Flag, Bits>, Count>& rows) noexcept {
    Bits bits = 0;
    for (const FlagRow<Flag, Bits>& row : rows) {
        // Khác gốc: if (overlaps(value, row.flag)) bits |= row.bits;
        bits = overlaps(value, row.flag) ? bits | row.bits : bits;
    }
    return bits;
}

using BufferRow = FlagRow<BufferUsage, VkBufferUsageFlags>;
constexpr std::array kBufferUsage{
    BufferRow{.flag = BufferUsage::kVertex, .bits = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT},
    BufferRow{.flag = BufferUsage::kIndex, .bits = VK_BUFFER_USAGE_INDEX_BUFFER_BIT},
    BufferRow{.flag = BufferUsage::kUniform, .bits = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT},
    BufferRow{.flag = BufferUsage::kStorage, .bits = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT},
    BufferRow{.flag = BufferUsage::kIndirect, .bits = VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT},
    BufferRow{.flag = BufferUsage::kCopySource, .bits = VK_BUFFER_USAGE_TRANSFER_SRC_BIT},
    BufferRow{.flag = BufferUsage::kCopyDest, .bits = VK_BUFFER_USAGE_TRANSFER_DST_BIT},
    BufferRow{.flag = BufferUsage::kAddress, .bits = VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT},
};

using TextureRow = FlagRow<TextureUsage, VkImageUsageFlags>;
constexpr std::array kTextureUsage{
    TextureRow{.flag = TextureUsage::kSampled, .bits = VK_IMAGE_USAGE_SAMPLED_BIT},
    TextureRow{.flag = TextureUsage::kStorage, .bits = VK_IMAGE_USAGE_STORAGE_BIT},
    TextureRow{.flag = TextureUsage::kColorTarget, .bits = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT},
    TextureRow{.flag = TextureUsage::kDepthStencilTarget, .bits = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT},
    TextureRow{.flag = TextureUsage::kCopySource, .bits = VK_IMAGE_USAGE_TRANSFER_SRC_BIT},
    TextureRow{.flag = TextureUsage::kCopyDest, .bits = VK_IMAGE_USAGE_TRANSFER_DST_BIT},
    TextureRow{.flag = TextureUsage::kTransient, .bits = VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT},
};

// Bit sync1 (vkCmdPipelineBarrier của Vulkan 1.0): thiết bị 1.1 không có synchronization2. Một lần
// barrier sync1 chỉ có một cặp giai đoạn cho mọi phần tử, nên commands.cpp gộp giai đoạn của cả lô.
using StageRow = FlagRow<SyncStage, VkPipelineStageFlags>;
constexpr std::array kStages{
    StageRow{.flag = SyncStage::kDrawIndirect, .bits = VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT},
    StageRow{.flag = SyncStage::kVertexInput, .bits = VK_PIPELINE_STAGE_VERTEX_INPUT_BIT},
    StageRow{.flag = SyncStage::kVertexShader, .bits = VK_PIPELINE_STAGE_VERTEX_SHADER_BIT},
    StageRow{.flag = SyncStage::kPixelShader, .bits = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT},
    StageRow{.flag = SyncStage::kComputeShader, .bits = VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT},
    StageRow{.flag = SyncStage::kEarlyDepth, .bits = VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT},
    StageRow{.flag = SyncStage::kLateDepth, .bits = VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT},
    StageRow{.flag = SyncStage::kColorOutput, .bits = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT},
    // Sync1 gộp chép và resolve (vkCmdResolveImage) vào giai đoạn TRANSFER.
    StageRow{.flag = SyncStage::kCopy, .bits = VK_PIPELINE_STAGE_TRANSFER_BIT},
    StageRow{.flag = SyncStage::kResolve, .bits = VK_PIPELINE_STAGE_TRANSFER_BIT},
    StageRow{.flag = SyncStage::kAll, .bits = VK_PIPELINE_STAGE_ALL_COMMANDS_BIT},
};

using AccessRow = FlagRow<Access, VkAccessFlags>;
constexpr std::array kAccess{
    AccessRow{.flag = Access::kIndirectRead, .bits = VK_ACCESS_INDIRECT_COMMAND_READ_BIT},
    AccessRow{.flag = Access::kIndexRead, .bits = VK_ACCESS_INDEX_READ_BIT},
    AccessRow{.flag = Access::kVertexRead, .bits = VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT},
    AccessRow{.flag = Access::kUniformRead, .bits = VK_ACCESS_UNIFORM_READ_BIT},
    AccessRow{.flag = Access::kShaderRead, .bits = VK_ACCESS_SHADER_READ_BIT},
    AccessRow{.flag = Access::kShaderWrite, .bits = VK_ACCESS_SHADER_WRITE_BIT},
    AccessRow{.flag = Access::kColorRead, .bits = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT},
    AccessRow{.flag = Access::kColorWrite, .bits = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT},
    AccessRow{.flag = Access::kDepthRead, .bits = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT},
    AccessRow{.flag = Access::kDepthWrite, .bits = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT},
    AccessRow{.flag = Access::kCopyRead, .bits = VK_ACCESS_TRANSFER_READ_BIT},
    AccessRow{.flag = Access::kCopyWrite, .bits = VK_ACCESS_TRANSFER_WRITE_BIT},
    AccessRow{.flag = Access::kResolveRead, .bits = VK_ACCESS_TRANSFER_READ_BIT},
    AccessRow{.flag = Access::kResolveWrite, .bits = VK_ACCESS_TRANSFER_WRITE_BIT},
};

} // namespace

VkFormat to_vk(Format format) noexcept {
    return kFormats.at(std::to_underlying(format));
}

Format from_vk(VkFormat format) noexcept {
    const auto found = std::ranges::find(kFormats, format);
    if (found == kFormats.end()) return Format::kUnknown;
    return static_cast<Format>(found - kFormats.begin());
}

VkImageAspectFlags aspect_of(Format format) noexcept {
    switch (info(format).aspect) {
    case FormatAspect::kColor: return VK_IMAGE_ASPECT_COLOR_BIT;
    case FormatAspect::kDepth: return VK_IMAGE_ASPECT_DEPTH_BIT;
    case FormatAspect::kDepthStencil: return VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
    }
    return VK_IMAGE_ASPECT_COLOR_BIT;
}

VkCompareOp to_vk(CompareOp value) noexcept {
    switch (value) {
    case CompareOp::kNever: return VK_COMPARE_OP_NEVER;
    case CompareOp::kLess: return VK_COMPARE_OP_LESS;
    case CompareOp::kEqual: return VK_COMPARE_OP_EQUAL;
    case CompareOp::kLessOrEqual: return VK_COMPARE_OP_LESS_OR_EQUAL;
    case CompareOp::kGreater: return VK_COMPARE_OP_GREATER;
    case CompareOp::kNotEqual: return VK_COMPARE_OP_NOT_EQUAL;
    case CompareOp::kGreaterOrEqual: return VK_COMPARE_OP_GREATER_OR_EQUAL;
    case CompareOp::kAlways: return VK_COMPARE_OP_ALWAYS;
    }
    return VK_COMPARE_OP_ALWAYS;
}

VkStencilOp to_vk(StencilOp value) noexcept {
    switch (value) {
    case StencilOp::kKeep: return VK_STENCIL_OP_KEEP;
    case StencilOp::kZero: return VK_STENCIL_OP_ZERO;
    case StencilOp::kReplace: return VK_STENCIL_OP_REPLACE;
    case StencilOp::kIncrementClamp: return VK_STENCIL_OP_INCREMENT_AND_CLAMP;
    case StencilOp::kDecrementClamp: return VK_STENCIL_OP_DECREMENT_AND_CLAMP;
    case StencilOp::kInvert: return VK_STENCIL_OP_INVERT;
    case StencilOp::kIncrementWrap: return VK_STENCIL_OP_INCREMENT_AND_WRAP;
    case StencilOp::kDecrementWrap: return VK_STENCIL_OP_DECREMENT_AND_WRAP;
    }
    return VK_STENCIL_OP_KEEP;
}

VkBlendFactor to_vk(BlendFactor value) noexcept {
    switch (value) {
    case BlendFactor::kZero: return VK_BLEND_FACTOR_ZERO;
    case BlendFactor::kOne: return VK_BLEND_FACTOR_ONE;
    case BlendFactor::kSrcColor: return VK_BLEND_FACTOR_SRC_COLOR;
    case BlendFactor::kOneMinusSrcColor: return VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
    case BlendFactor::kDstColor: return VK_BLEND_FACTOR_DST_COLOR;
    case BlendFactor::kOneMinusDstColor: return VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
    case BlendFactor::kSrcAlpha: return VK_BLEND_FACTOR_SRC_ALPHA;
    case BlendFactor::kOneMinusSrcAlpha: return VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    case BlendFactor::kDstAlpha: return VK_BLEND_FACTOR_DST_ALPHA;
    case BlendFactor::kOneMinusDstAlpha: return VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
    case BlendFactor::kSrcAlphaSaturate: return VK_BLEND_FACTOR_SRC_ALPHA_SATURATE;
    case BlendFactor::kConstant: return VK_BLEND_FACTOR_CONSTANT_COLOR;
    case BlendFactor::kOneMinusConstant: return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
    }
    return VK_BLEND_FACTOR_ONE;
}

VkBlendOp to_vk(BlendOp value) noexcept {
    switch (value) {
    case BlendOp::kAdd: return VK_BLEND_OP_ADD;
    case BlendOp::kSubtract: return VK_BLEND_OP_SUBTRACT;
    case BlendOp::kReverseSubtract: return VK_BLEND_OP_REVERSE_SUBTRACT;
    case BlendOp::kMin: return VK_BLEND_OP_MIN;
    case BlendOp::kMax: return VK_BLEND_OP_MAX;
    }
    return VK_BLEND_OP_ADD;
}

VkCullModeFlags to_vk(CullMode value) noexcept {
    switch (value) {
    case CullMode::kNone: return VK_CULL_MODE_NONE;
    case CullMode::kFront: return VK_CULL_MODE_FRONT_BIT;
    case CullMode::kBack: return VK_CULL_MODE_BACK_BIT;
    }
    return VK_CULL_MODE_NONE;
}

VkFrontFace to_vk(FrontFace value) noexcept {
    const bool is_clockwise = value == FrontFace::kClockwise;
    return is_clockwise ? VK_FRONT_FACE_CLOCKWISE : VK_FRONT_FACE_COUNTER_CLOCKWISE;
}

VkPolygonMode to_vk(FillMode value) noexcept {
    return value == FillMode::kWireframe ? VK_POLYGON_MODE_LINE : VK_POLYGON_MODE_FILL;
}

VkPrimitiveTopology to_vk(Topology value) noexcept {
    switch (value) {
    case Topology::kPointList: return VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
    case Topology::kLineList: return VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
    case Topology::kLineStrip: return VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
    case Topology::kTriangleList: return VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    case Topology::kTriangleStrip: return VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
    case Topology::kPatchList: return VK_PRIMITIVE_TOPOLOGY_PATCH_LIST;
    }
    return VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
}

VkIndexType to_vk(IndexType value) noexcept {
    return value == IndexType::kUint16 ? VK_INDEX_TYPE_UINT16 : VK_INDEX_TYPE_UINT32;
}

VkAttachmentLoadOp to_vk(LoadOp value) noexcept {
    switch (value) {
    case LoadOp::kLoad: return VK_ATTACHMENT_LOAD_OP_LOAD;
    case LoadOp::kClear: return VK_ATTACHMENT_LOAD_OP_CLEAR;
    case LoadOp::kDiscard: return VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    }
    return VK_ATTACHMENT_LOAD_OP_DONT_CARE;
}

VkAttachmentStoreOp to_vk(StoreOp value) noexcept {
    const bool is_stored = value == StoreOp::kStore;
    return is_stored ? VK_ATTACHMENT_STORE_OP_STORE : VK_ATTACHMENT_STORE_OP_DONT_CARE;
}

VkFilter to_vk(Filter value) noexcept {
    return value == Filter::kNearest ? VK_FILTER_NEAREST : VK_FILTER_LINEAR;
}

VkSamplerMipmapMode to_mip_mode(Filter value) noexcept {
    const bool is_nearest = value == Filter::kNearest;
    return is_nearest ? VK_SAMPLER_MIPMAP_MODE_NEAREST : VK_SAMPLER_MIPMAP_MODE_LINEAR;
}

VkSamplerAddressMode to_vk(AddressMode value) noexcept {
    switch (value) {
    case AddressMode::kRepeat: return VK_SAMPLER_ADDRESS_MODE_REPEAT;
    case AddressMode::kMirrorRepeat: return VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
    case AddressMode::kClampToEdge: return VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    case AddressMode::kClampToBorder: return VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
    }
    return VK_SAMPLER_ADDRESS_MODE_REPEAT;
}

VkBorderColor to_vk(BorderColor value) noexcept {
    switch (value) {
    case BorderColor::kTransparentBlack: return VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
    case BorderColor::kOpaqueBlack: return VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;
    case BorderColor::kOpaqueWhite: return VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
    }
    return VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
}

VkPresentModeKHR to_vk(PresentMode value) noexcept {
    switch (value) {
    case PresentMode::kFifo: return VK_PRESENT_MODE_FIFO_KHR;
    case PresentMode::kImmediate: return VK_PRESENT_MODE_IMMEDIATE_KHR;
    case PresentMode::kMailbox: return VK_PRESENT_MODE_MAILBOX_KHR;
    }
    return VK_PRESENT_MODE_FIFO_KHR;
}

// VkSampleCountFlagBits có giá trị bằng chính số mẫu.
VkSampleCountFlagBits to_samples(std::uint32_t samples) noexcept {
    return static_cast<VkSampleCountFlagBits>(samples);
}

VkBufferUsageFlags to_vk(BufferUsage usage) noexcept {
    return map_flags(usage, kBufferUsage);
}

VkImageUsageFlags to_vk(TextureUsage usage) noexcept {
    return map_flags(usage, kTextureUsage);
}

VkImageType to_image_type(TextureKind kind) noexcept {
    switch (kind) {
    case TextureKind::kTex1D: return VK_IMAGE_TYPE_1D;
    case TextureKind::kTex2D:
    case TextureKind::kTex2DArray:
    case TextureKind::kCube:
    case TextureKind::kCubeArray: return VK_IMAGE_TYPE_2D;
    case TextureKind::kTex3D: return VK_IMAGE_TYPE_3D;
    }
    return VK_IMAGE_TYPE_2D;
}

VkImageViewType to_view_type(TextureKind kind) noexcept {
    switch (kind) {
    case TextureKind::kTex1D: return VK_IMAGE_VIEW_TYPE_1D;
    case TextureKind::kTex2D: return VK_IMAGE_VIEW_TYPE_2D;
    case TextureKind::kTex2DArray: return VK_IMAGE_VIEW_TYPE_2D_ARRAY;
    case TextureKind::kTex3D: return VK_IMAGE_VIEW_TYPE_3D;
    case TextureKind::kCube: return VK_IMAGE_VIEW_TYPE_CUBE;
    case TextureKind::kCubeArray: return VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
    }
    return VK_IMAGE_VIEW_TYPE_2D;
}

VkPipelineStageFlags to_vk(SyncStage stages) noexcept {
    return map_flags(stages, kStages);
}

VkAccessFlags to_vk(Access access) noexcept {
    return map_flags(access, kAccess);
}

VkImageLayout to_vk(TextureLayout layout) noexcept {
    switch (layout) {
    case TextureLayout::kUndefined: return VK_IMAGE_LAYOUT_UNDEFINED;
    case TextureLayout::kGeneral: return VK_IMAGE_LAYOUT_GENERAL;
    case TextureLayout::kColorTarget: return VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    case TextureLayout::kDepthWrite: return VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
    case TextureLayout::kDepthRead: return VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
    case TextureLayout::kShaderRead: return VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    case TextureLayout::kCopySource:
    case TextureLayout::kResolveSource: return VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    case TextureLayout::kCopyDest:
    case TextureLayout::kResolveDest: return VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    case TextureLayout::kPresent: return VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    }
    return VK_IMAGE_LAYOUT_UNDEFINED;
}

VkShaderStageFlagBits to_vk(shader::Stage stage) noexcept {
    switch (stage) {
    case shader::Stage::kVertex: return VK_SHADER_STAGE_VERTEX_BIT;
    case shader::Stage::kHull: return VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT;
    case shader::Stage::kDomain: return VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
    case shader::Stage::kGeometry: return VK_SHADER_STAGE_GEOMETRY_BIT;
    case shader::Stage::kPixel: return VK_SHADER_STAGE_FRAGMENT_BIT;
    case shader::Stage::kCompute: return VK_SHADER_STAGE_COMPUTE_BIT;
    case shader::Stage::kMesh: return VK_SHADER_STAGE_MESH_BIT_EXT;
    case shader::Stage::kAmplification: return VK_SHADER_STAGE_TASK_BIT_EXT;
    case shader::Stage::kLibrary: return VK_SHADER_STAGE_ALL;
    }
    return VK_SHADER_STAGE_ALL;
}

VkShaderStageFlags to_vk(shader::StageSet stages) noexcept {
    VkShaderStageFlags flags = 0;
    for (std::size_t index = 0; index < shader::kStageCount; ++index) {
        const auto stage = static_cast<shader::Stage>(index);
        // Khác gốc: if (stages.has(stage)) flags |= ...; vế phải giữ nguyên, chỉ tính khi có stage.
        flags = stages.has(stage) ? flags | static_cast<VkShaderStageFlags>(to_vk(stage)) : flags;
    }
    return flags;
}

VkDescriptorType to_vk(shader::ResourceKind kind) noexcept {
    using shader::ResourceKind;
    switch (kind) {
    case ResourceKind::kSampler: return VK_DESCRIPTOR_TYPE_SAMPLER;
    case ResourceKind::kTexture: return VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
    case ResourceKind::kRwTexture: return VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
    // DXC dịch StructuredBuffer và ByteAddressBuffer thành storage buffer, cả bản chỉ đọc.
    case ResourceKind::kBuffer:
    case ResourceKind::kRwBuffer: return VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    case ResourceKind::kUniformBuffer: return VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    case ResourceKind::kTexelBuffer:
    case ResourceKind::kRwTexelBuffer:
    case ResourceKind::kPushConstant:
    case ResourceKind::kAccelerationStructure:
    case ResourceKind::kInputAttachment: return VK_DESCRIPTOR_TYPE_MAX_ENUM;
    }
    return VK_DESCRIPTOR_TYPE_MAX_ENUM;
}

} // namespace game::gpu::vulkan
