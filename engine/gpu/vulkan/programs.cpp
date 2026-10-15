// Shader, bố cục gắn dựng từ phản chiếu, pipeline và nhóm gắn của backend Vulkan.
// Nguồn: Forge2 src/gpu/vulkan/programs.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân vòng
// lặp có nhánh của gather, create_set_layout, fill_layout, take_set, write_group tách hàm hoặc đưa
// điều kiện dừng lên điều kiện lặp, allocate_set bỏ khối if lồng (ghi tại chỗ); kPoolSizes ghi tên
// trường; handle Vulkan cục bộ khai auto* const; include trực tiếp header của mọi tên dùng tới.
#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/binding.hpp"
#include "gpu/check.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/layout.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/convert.hpp"
#include "gpu/vulkan/device.hpp"
#include "shader/package.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <array>
#include <bit>
#include <cstdint>
#include <cstring>
#include <expected>
#include <memory>
#include <mutex>
#include <span>
#include <utility>
#include <variant>
#include <vector>

namespace game::gpu::vulkan {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kMissing = ErrorCode::kUnsupported;

// Sức chứa của một pool set dùng chung: số set và số descriptor từng loại.
constexpr std::uint32_t kPoolSets = 1024;
constexpr std::array kPoolSizes{
    VkDescriptorPoolSize{.type = VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 2048},
    VkDescriptorPoolSize{.type = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 8192},
    VkDescriptorPoolSize{.type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 2048},
    VkDescriptorPoolSize{.type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 4096},
    VkDescriptorPoolSize{.type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 4096},
};

// Cờ của chỗ gắn là mảng không chặn: gắn dần, cỡ khai lúc cấp set, ghi được khi set đang dùng.
constexpr VkDescriptorBindingFlags kOpenFlags = VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT |
    VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT | VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT |
    VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT;

[[nodiscard]] bool is_pool_full(VkResult result) noexcept {
    return result == VK_ERROR_OUT_OF_POOL_MEMORY || result == VK_ERROR_FRAGMENTED_POOL;
}

[[nodiscard]] core::Failure unbindable(const shader::Resource& resource) noexcept {
    return fail(kMissing, "loại tài nguyên shader chưa gắn được", "{}", resource.name);
}

[[nodiscard]] bool is_same_place(const shader::Resource& left, const shader::Resource& right) noexcept {
    const bool is_same_slot = left.kind == right.kind && left.binding == right.binding;
    return is_same_slot && left.count == right.count && left.stages == right.stages;
}

[[nodiscard]] bool is_same_space(const SpaceLayout& left, const SpaceLayout& right) noexcept {
    return std::ranges::equal(left.resources, right.resources, is_same_place);
}

// Hai bố cục trùng băm có thật sự là một: chặn trường hợp băm 64 bit va nhau.
[[nodiscard]] bool is_same_layout(const ProgramLayout& left, const ProgramLayout& right) noexcept {
    const bool is_same_push = left.push_bytes == right.push_bytes && left.push_stages == right.push_stages;
    return is_same_push && std::ranges::equal(left.spaces, right.spaces, is_same_space);
}

// Mọi cấu trúc của một VkGraphicsPipelineCreateInfo, giữ sống tới khi lời gọi tạo xong.
struct GraphicsState {
    std::vector<VkPipelineShaderStageCreateInfo> stages;
    std::vector<VkVertexInputBindingDescription> bindings;
    std::vector<VkVertexInputAttributeDescription> attributes;
    std::vector<VkPipelineColorBlendAttachmentState> blends;
    std::vector<VkDynamicState> dynamics;
    VkPipelineVertexInputStateCreateInfo input{};
    VkPipelineInputAssemblyStateCreateInfo assembly{};
    VkPipelineTessellationStateCreateInfo tessellation{};
    VkPipelineViewportStateCreateInfo viewport{};
    VkPipelineRasterizationStateCreateInfo raster{};
    VkPipelineRasterizationConservativeStateCreateInfoEXT conservative{};
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkPipelineMultisampleStateCreateInfo multisample{};
    VkPipelineDepthStencilStateCreateInfo depth{};
    VkPipelineColorBlendStateCreateInfo blend{};
    VkPipelineDynamicStateCreateInfo dynamic{};
};

void fill_input(GraphicsState& state, const GraphicsPipelineDesc& desc) {
    for (std::uint32_t slot = 0; slot < desc.vertex_buffers.size(); ++slot) {
        const VertexBufferLayout& buffer = desc.vertex_buffers.subspan(slot, 1).front();
        const VkVertexInputRate rate =
            buffer.is_per_instance ? VK_VERTEX_INPUT_RATE_INSTANCE : VK_VERTEX_INPUT_RATE_VERTEX;
        state.bindings.push_back({.binding = slot, .stride = buffer.stride, .inputRate = rate});
    }
    for (const VertexAttribute& attribute : desc.vertex_attributes) {
        VkVertexInputAttributeDescription item{};
        item.location = attribute.location;
        item.binding = attribute.buffer;
        item.format = to_vk(attribute.format);
        item.offset = attribute.offset;
        state.attributes.push_back(item);
    }
    state.input.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    state.input.vertexBindingDescriptionCount = static_cast<std::uint32_t>(state.bindings.size());
    state.input.pVertexBindingDescriptions = state.bindings.data();
    state.input.vertexAttributeDescriptionCount = static_cast<std::uint32_t>(state.attributes.size());
    state.input.pVertexAttributeDescriptions = state.attributes.data();
    state.assembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    state.assembly.topology = to_vk(desc.topology);
    state.tessellation.sType = VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO;
    state.tessellation.patchControlPoints = desc.patch_points;
    // Viewport và scissor đặt bằng lệnh; ở đây chỉ khai số lượng.
    state.viewport.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    state.viewport.viewportCount = 1;
    state.viewport.scissorCount = 1;
}

void fill_raster(GraphicsState& state, const GraphicsPipelineDesc& desc, const Traits& traits) {
    const RasterState& raster = desc.raster;
    const bool is_biased = raster.depth_bias != 0.0F || raster.depth_bias_slope != 0.0F;
    state.raster.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    state.raster.depthClampEnable = raster.is_depth_clipped ? VK_FALSE : VK_TRUE;
    state.raster.polygonMode = to_vk(raster.fill);
    state.raster.cullMode = to_vk(raster.cull);
    state.raster.frontFace = to_vk(raster.front_face);
    state.raster.depthBiasEnable = is_biased ? VK_TRUE : VK_FALSE;
    state.raster.depthBiasConstantFactor = raster.depth_bias;
    // Thiết bị không kẹp được độ dịch thì bỏ kẹp: độ dịch vẫn đúng ở mọi góc trừ góc rất xiên.
    state.raster.depthBiasClamp = traits.bias_clamp ? raster.depth_bias_clamp : 0.0F;
    state.raster.depthBiasSlopeFactor = raster.depth_bias_slope;
    state.raster.lineWidth = 1.0F;
    state.conservative.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT;
    state.conservative.conservativeRasterizationMode = VK_CONSERVATIVE_RASTERIZATION_MODE_OVERESTIMATE_EXT;
    if (raster.is_conservative) state.raster.pNext = &state.conservative;
    state.multisample.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    state.multisample.rasterizationSamples = to_samples(desc.samples);
    state.multisample.alphaToCoverageEnable = desc.is_alpha_to_coverage ? VK_TRUE : VK_FALSE;
}

[[nodiscard]] VkStencilOpState stencil_face(const StencilFace& face, const DepthState& depth) noexcept {
    VkStencilOpState state{};
    state.failOp = to_vk(face.fail);
    state.passOp = to_vk(face.pass);
    state.depthFailOp = to_vk(face.depth_fail);
    state.compareOp = to_vk(face.compare);
    state.compareMask = depth.stencil_read_mask;
    state.writeMask = depth.stencil_write_mask;
    return state;
}

void fill_depth(GraphicsState& state, const GraphicsPipelineDesc& desc) {
    const DepthState& depth = desc.depth;
    state.depth.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
    state.depth.depthTestEnable = depth.is_tested ? VK_TRUE : VK_FALSE;
    state.depth.depthWriteEnable = depth.is_written ? VK_TRUE : VK_FALSE;
    state.depth.depthCompareOp = to_vk(depth.compare);
    state.depth.depthBoundsTestEnable = depth.is_bounds_tested ? VK_TRUE : VK_FALSE;
    state.depth.stencilTestEnable = depth.is_stencil_tested ? VK_TRUE : VK_FALSE;
    state.depth.front = stencil_face(depth.front, depth);
    state.depth.back = stencil_face(depth.back, depth);
    state.depth.maxDepthBounds = 1.0F;
}

[[nodiscard]] VkPipelineColorBlendAttachmentState blend_of(const BlendState& blend) noexcept {
    VkPipelineColorBlendAttachmentState state{};
    state.blendEnable = blend.is_enabled ? VK_TRUE : VK_FALSE;
    state.srcColorBlendFactor = to_vk(blend.src_color);
    state.dstColorBlendFactor = to_vk(blend.dst_color);
    state.colorBlendOp = to_vk(blend.color_op);
    state.srcAlphaBlendFactor = to_vk(blend.src_alpha);
    state.dstAlphaBlendFactor = to_vk(blend.dst_alpha);
    state.alphaBlendOp = to_vk(blend.alpha_op);
    state.colorWriteMask = blend.write_mask;
    return state;
}

// Trạng thái trộn của đích thứ index: rỗng thì mặc định, một phần tử thì dùng chung.
[[nodiscard]] BlendState blend_at(std::span<const BlendState> blends, std::size_t index) noexcept {
    if (blends.empty()) return {};
    return blends.size() == 1 ? blends.front() : blends.subspan(index, 1).front();
}

void fill_targets(GraphicsState& state, const GraphicsPipelineDesc& desc) {
    for (std::size_t index = 0; index < desc.color_formats.size(); ++index) {
        state.blends.push_back(blend_of(blend_at(desc.blends, index)));
    }
    state.blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    state.blend.attachmentCount = static_cast<std::uint32_t>(state.blends.size());
    state.blend.pAttachments = state.blends.data();
    state.dynamics = {VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR, VK_DYNAMIC_STATE_STENCIL_REFERENCE,
        VK_DYNAMIC_STATE_BLEND_CONSTANTS};
    if (desc.depth.is_bounds_tested) state.dynamics.push_back(VK_DYNAMIC_STATE_DEPTH_BOUNDS);
    state.dynamic.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    state.dynamic.dynamicStateCount = static_cast<std::uint32_t>(state.dynamics.size());
    state.dynamic.pDynamicStates = state.dynamics.data();
}

[[nodiscard]] VkPipelineShaderStageCreateInfo stage_info(const Shader& shader) noexcept {
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkPipelineShaderStageCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    info.stage = to_vk(shader.reflection.stage);
    info.module = shader.handle;
    info.pName = shader.reflection.entry.c_str();
    return info;
}

using Reflections = std::vector<shader::StageReflection>;
using Stages = std::vector<VkPipelineShaderStageCreateInfo>;

// Khác gốc: thân vòng lặp của gather tách ra đây (PH-01).
// Chép phản chiếu và thông tin stage của một shader; false khi shader đã chết.
[[nodiscard]] bool add_shader(const Shader* shader, Reflections& reflections, Stages& stages) {
    if (shader == nullptr) return false;
    reflections.push_back(shader->reflection);
    stages.push_back(stage_info(*shader));
    return true;
}

// Gom shader của một pipeline: bản chép phản chiếu cho make_program và thông tin stage cho Vulkan.
[[nodiscard]] Result<Program> gather(const VulkanDevice& device, std::span<const ShaderHandle> handles,
    std::vector<VkPipelineShaderStageCreateInfo>& stages) {
    std::vector<shader::StageReflection> reflections;
    reflections.reserve(handles.size());
    bool is_alive = true;
    // Khác gốc: gốc return fail giữa vòng for; ở đây vòng dừng ở shader chết đầu tiên,
    // cùng thứ tự duyệt, rồi mới trả lỗi (PH-01).
    for (auto handle = handles.begin(); handle != handles.end() && is_alive; ++handle) {
        is_alive = add_shader(device.find(*handle), reflections, stages);
    }
    if (!is_alive) return fail(kBad, "pipeline: shader đã chết");
    return make_program(reflections);
}

// Thông tin ảnh và buffer của các descriptor đang ghi. Địa chỉ phần tử không đổi vì ba vector được
// reserve đủ trước khi thêm.
struct Writes {
    std::vector<VkDescriptorImageInfo> images;
    std::vector<VkDescriptorBufferInfo> buffers;
    std::vector<VkWriteDescriptorSet> writes;
};

// Một descriptor đang dựng: chỗ gắn của nó trong bố cục và thiết bị để tra tài nguyên.
struct WriteTarget {
    const VulkanDevice* device = nullptr;
    const SpaceLayout* space = nullptr;
    const shader::Resource* resource = nullptr;
};

[[nodiscard]] Status add_buffer(Writes& batch, const WriteTarget& target, const BufferRange& range) {
    const shader::Resource& resource = *target.resource;
    const Buffer* const buffer = target.device->find(range.buffer);
    if (buffer == nullptr) return fail(kBad, "nhóm gắn: buffer đã chết", "{}", resource.name);
    const bool is_uniform = resource.kind == shader::ResourceKind::kUniformBuffer;
    const BufferUsage wanted = is_uniform ? BufferUsage::kUniform : BufferUsage::kStorage;
    if (!has(buffer->usage, wanted)) {
        return fail(kBad, "nhóm gắn: buffer thiếu cờ Uniform hoặc Storage", "{}", resource.name);
    }
    const Result<std::uint64_t> size = resolve_binding(*target.space, resource, range, buffer->size);
    if (!size) return std::unexpected(size.error());
    // Hai giới hạn của riêng Vulkan. Căn của cbuffer đã nằm trong kUniformAlignment (đặc tả không
    // cho thiết bị đòi quá 256).
    const VkPhysicalDeviceLimits& limits = target.device->limits();
    const bool is_storage_aligned = range.offset % limits.minStorageBufferOffsetAlignment == 0;
    if (!is_uniform && !is_storage_aligned) {
        return fail(kBad, "nhóm gắn: offset của buffer không căn theo thiết bị", "{} % {}", range.offset,
            limits.minStorageBufferOffsetAlignment);
    }
    if (is_uniform && *size > limits.maxUniformBufferRange) {
        return fail(kMissing, "nhóm gắn: cbuffer vượt maxUniformBufferRange", "{}", resource.name);
    }
    batch.buffers.push_back({.buffer = buffer->handle, .offset = range.offset, .range = *size});
    batch.writes.back().pBufferInfo = &batch.buffers.back();
    return ok();
}

[[nodiscard]] Status add_view(Writes& batch, const WriteTarget& target, TextureViewHandle handle) {
    const shader::Resource& resource = *target.resource;
    const View* const view = target.device->find(handle);
    if (view == nullptr) return fail(kBad, "nhóm gắn: view đã chết", "{}", resource.name);
    const Texture* const texture = target.device->find(view->texture);
    if (texture == nullptr) return fail(kBad, "nhóm gắn: texture đã chết", "{}", resource.name);
    const bool is_written = resource.kind == shader::ResourceKind::kRwTexture;
    const TextureUsage wanted = is_written ? TextureUsage::kStorage : TextureUsage::kSampled;
    if (!has(texture->desc.usage, wanted)) {
        return fail(kBad, "nhóm gắn: texture thiếu cờ Sampled hoặc Storage", "{}", resource.name);
    }
    // RWTexture ở bố cục General; texture độ sâu được đọc ở DepthRead (cùng lúc làm attachment chỉ
    // đọc được); còn lại ShaderRead.
    VkDescriptorImageInfo info{};
    info.imageView = view->handle;
    info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    if (has_depth(view->range.format)) info.imageLayout = to_vk(TextureLayout::kDepthRead);
    if (is_written) info.imageLayout = VK_IMAGE_LAYOUT_GENERAL;
    batch.images.push_back(info);
    batch.writes.back().pImageInfo = &batch.images.back();
    return ok();
}

[[nodiscard]] Status add_sampler(Writes& batch, const WriteTarget& target, SamplerHandle handle) {
    const Sampler* const sampler = target.device->find(handle);
    if (sampler == nullptr) {
        return fail(kBad, "nhóm gắn: sampler đã chết", "{}", target.resource->name);
    }
    VkDescriptorImageInfo info{};
    info.sampler = sampler->handle;
    batch.images.push_back(info);
    batch.writes.back().pImageInfo = &batch.images.back();
    return ok();
}

// Thêm một descriptor vào lô ghi; lỗi khi tài nguyên của entry đã chết hay không hợp chỗ gắn. entry
// đã qua check_entries: chỗ gắn có thật và đúng loại tài nguyên.
[[nodiscard]] Status add_write(Writes& batch, const VulkanDevice& device, const BindGroup& group,
    const BindEntry& entry) {
    const SpaceLayout& space = group.layout->program.spaces.at(group.space);
    const shader::Resource* const resource = find_resource(space, entry.type, entry.slot);
    if (resource == nullptr) return fail(ErrorCode::kInternal, "nhóm gắn: entry chưa được kiểm");
    VkWriteDescriptorSet write{};
    write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    write.dstSet = group.set;
    write.dstBinding = resource->binding;
    write.dstArrayElement = entry.element;
    write.descriptorCount = 1;
    write.descriptorType = to_vk(resource->kind);
    batch.writes.push_back(write);
    const WriteTarget target{.device = &device, .space = &space, .resource = resource};
    if (const auto* const range = std::get_if<BufferRange>(&entry.resource)) {
        return add_buffer(batch, target, *range);
    }
    if (const auto* const view = std::get_if<TextureViewHandle>(&entry.resource)) {
        return add_view(batch, target, *view);
    }
    return add_sampler(batch, target, std::get<SamplerHandle>(entry.resource));
}

// Chỗ gắn của một descriptor set layout đang dựng và cờ của từng chỗ; hai vector song song.
struct SetBindings {
    std::vector<VkDescriptorSetLayoutBinding> bindings;
    std::vector<VkDescriptorBindingFlags> flags;
};

// Khác gốc: thân vòng lặp của create_set_layout tách ra đây (PH-01).
// Thêm chỗ gắn của một tài nguyên; lỗi khi backend chưa gắn được loại ấy.
[[nodiscard]] Status add_binding(SetBindings& list, const shader::Resource& resource, const DeviceCaps& caps) {
    const VkDescriptorType type = to_vk(resource.kind);
    if (type == VK_DESCRIPTOR_TYPE_MAX_ENUM) return unbindable(resource);
    // Mảng không chặn khai với trần của thiết bị; sức chứa thật của từng nhóm khai lúc cấp set.
    const bool is_sampler = resource.kind == shader::ResourceKind::kSampler;
    const std::uint32_t most = is_sampler ? caps.max_unbounded_samplers : caps.max_unbounded;
    const bool is_open = resource.count == 0;
    VkDescriptorSetLayoutBinding binding{};
    binding.binding = resource.binding;
    binding.descriptorType = type;
    binding.descriptorCount = is_open ? most : resource.count;
    binding.stageFlags = to_vk(resource.stages);
    list.bindings.push_back(binding);
    list.flags.push_back(is_open ? kOpenFlags : 0);
    return ok();
}

using SetLayout = Result<VkDescriptorSetLayout>;

// Khác gốc: phần nhận kết quả create_set_layout của vòng lặp fill_layout tách ra đây
// (PH-01). Ghi set layout của register space thứ space vào bố cục; lỗi tạo thì trả lại.
[[nodiscard]] Status keep_set(Layout& layout, std::uint32_t space, const SetLayout& set) {
    if (!set) return std::unexpected(set.error());
    layout.sets.at(space) = *set;
    return ok();
}

} // namespace

Result<ShaderHandle> VulkanDevice::create_shader(const ShaderDesc& desc) {
    const shader::Variant* const variant = desc.variant;
    if (variant == nullptr) return fail(kBad, "shader: variant rỗng");
    const bool is_spirv = variant->target == shader::Target::kSpirV;
    if (!is_spirv) return fail(kBad, "shader: backend Vulkan cần bản dịch SPIR-V");
    const bool is_sized = !variant->code.empty() && variant->code.size() % 4 == 0;
    if (!is_sized) return fail(kBad, "shader: mã SPIR-V rỗng hoặc lẻ word");
    // Chép sang mảng word: pCode phải là uint32_t căn 4 byte, còn code là dãy byte mượn của gói.
    std::vector<std::uint32_t> words(variant->code.size() / 4);
    std::memcpy(words.data(), variant->code.data(), variant->code.size());
    VkShaderModuleCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    info.codeSize = variant->code.size();
    info.pCode = words.data();
    Shader shader{.reflection = variant->reflection};
    const VkResult created = vkCreateShaderModule(device_, &info, nullptr, &shader.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được shader module");
    set_name(VK_OBJECT_TYPE_SHADER_MODULE, std::bit_cast<std::uint64_t>(shader.handle), desc.name);
    auto* const module = shader.handle;
    const ShaderHandle handle = shaders_.insert(std::move(shader));
    if (handle) return handle;
    vkDestroyShaderModule(device_, module, nullptr);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng shader");
}

void VulkanDevice::discard(Shader& shader) noexcept {
    if (shader.handle != VK_NULL_HANDLE) vkDestroyShaderModule(device_, shader.handle, nullptr);
    shader.handle = VK_NULL_HANDLE;
}

// Space trống vẫn nhận một set layout rỗng, để số set của pipeline layout khớp register space.
Result<VkDescriptorSetLayout> VulkanDevice::create_set_layout(const SpaceLayout& space) {
    const bool is_open_missing = space.is_unbounded && !caps_.bindless;
    if (is_open_missing) return fail(kMissing, "thiết bị không có mảng không chặn");
    SetBindings list;
    Status added = ok();
    const auto last = space.resources.end();
    // Khác gốc: gốc dựng chỗ gắn và return lỗi ngay trong vòng for; ở đây thân vòng là
    // add_binding, vòng dừng ở lỗi đầu tiên, cùng thứ tự duyệt (PH-01).
    for (auto resource = space.resources.begin(); resource != last && added; ++resource) {
        added = add_binding(list, *resource, caps_);
    }
    if (!added) return std::unexpected(added.error());
    VkDescriptorSetLayoutBindingFlagsCreateInfo flag_info{};
    flag_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO;
    flag_info.bindingCount = static_cast<std::uint32_t>(list.flags.size());
    flag_info.pBindingFlags = list.flags.data();
    VkDescriptorSetLayoutCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    info.bindingCount = static_cast<std::uint32_t>(list.bindings.size());
    info.pBindings = list.bindings.data();
    if (space.is_unbounded) info.pNext = &flag_info;
    if (space.is_unbounded) info.flags = VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;
    VkDescriptorSetLayout layout = VK_NULL_HANDLE;
    const VkResult created = vkCreateDescriptorSetLayout(device_, &info, nullptr, &layout);
    if (created != VK_SUCCESS) return failed(created, "không tạo được descriptor set layout");
    return layout;
}

namespace {

[[nodiscard]] std::uint32_t highest_set(const ProgramLayout& program) noexcept {
    std::uint32_t count = 0;
    for (std::uint32_t space = 0; space < kMaxBindGroups; ++space) {
        if (program.spaces[space].resources.empty()) continue;
        count = space + 1;
    }
    return count;
}

} // namespace

Status VulkanDevice::fill_layout(Layout& layout, const ProgramLayout& program) {
    const std::uint32_t set_count = highest_set(program);
    // Chỉ số set bằng chỉ số space, nên count là space dùng cao nhất cộng một, không phải lúc nào cũng 8.
    // Thiết bị có maxBoundDescriptorSets bằng 4 vẫn chạy shader chỉ dùng space 0.
    if (set_count > limits_.maxBoundDescriptorSets) {
        return fail(ErrorCode::kInvalidArgument, "pipeline: descriptor set vượt giới hạn thiết bị");
    }
    Status kept = ok();
    // Khác gốc: gốc return lỗi giữa vòng for; ở đây vòng dừng ở space lỗi
    // đầu tiên, cùng thứ tự gọi create_set_layout; bit used chỉ bật khi set
    // của space ấy đã tạo được (PH-01).
    for (std::uint32_t space = 0; space < set_count && kept; ++space) {
        const SpaceLayout& source = program.spaces.at(space);
        const Result<VkDescriptorSetLayout> set = create_set_layout(source);
        kept = keep_set(layout, space, set);
        const bool is_used = kept && !source.resources.empty();
        layout.used |= is_used ? 1U << space : 0U;
    }
    if (!kept) return kept;
    layout.program = program;
    layout.push_stages = to_vk(program.push_stages);
    VkPushConstantRange push{};
    push.stageFlags = layout.push_stages;
    push.size = program.push_bytes;
    VkPipelineLayoutCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    info.setLayoutCount = set_count;
    info.pSetLayouts = set_count == 0 ? nullptr : layout.sets.data();
    info.pushConstantRangeCount = program.push_bytes == 0 ? 0U : 1U;
    info.pPushConstantRanges = &push;
    const VkResult created = vkCreatePipelineLayout(device_, &info, nullptr, &layout.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được pipeline layout");
    return ok();
}

Result<const Layout*> VulkanDevice::layout_for(const ProgramLayout& program) {
    const std::scoped_lock lock(layout_mutex_);
    const auto known = layouts_.find(program.hash);
    const bool is_known = known != layouts_.end();
    if (is_known && is_same_layout(known->second->program, program)) return known->second.get();
    if (is_known) return fail(ErrorCode::kInternal, "hai bố cục gắn khác nhau trùng băm");
    auto layout = std::make_unique<Layout>();
    const Status filled = fill_layout(*layout, program);
    if (!filled) discard(*layout);
    if (!filled) return std::unexpected(filled.error());
    const Layout* const result = layout.get();
    layouts_.emplace(program.hash, std::move(layout));
    return result;
}

void VulkanDevice::discard(Layout& layout) noexcept {
    if (layout.handle != VK_NULL_HANDLE) vkDestroyPipelineLayout(device_, layout.handle, nullptr);
    for (auto* const set : layout.sets) {
        vkDestroyDescriptorSetLayout(device_, set, nullptr);
    }
    layout.handle = VK_NULL_HANDLE;
    layout.sets = {};
}

void VulkanDevice::discard_layouts() noexcept {
    for (const auto& [hash, layout] : layouts_) {
        discard(*layout);
    }
    layouts_.clear();
    for (auto* const pool : set_pools_) {
        vkDestroyDescriptorPool(device_, pool, nullptr);
    }
    set_pools_.clear();
}

Result<PipelineHandle> VulkanDevice::create_pipeline(const GraphicsPipelineDesc& desc) {
    GraphicsState state;
    const Result<Program> program = gather(*this, desc.shaders, state.stages);
    if (!program) return std::unexpected(program.error());
    const Status checked = check_pipeline(desc, *program, caps_);
    if (!checked) return std::unexpected(checked.error());
    const Result<const Layout*> layout = layout_for(program->layout);
    if (!layout) return std::unexpected(layout.error());
    fill_input(state, desc);
    fill_raster(state, desc, traits_);
    fill_depth(state, desc);
    fill_targets(state, desc);
    VkGraphicsPipelineCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    info.stageCount = static_cast<std::uint32_t>(state.stages.size());
    info.pStages = state.stages.data();
    info.pVertexInputState = &state.input;
    info.pInputAssemblyState = &state.assembly;
    info.pTessellationState = desc.topology == Topology::kPatchList ? &state.tessellation : nullptr;
    info.pViewportState = &state.viewport;
    info.pRasterizationState = &state.raster;
    info.pMultisampleState = &state.multisample;
    info.pDepthStencilState = &state.depth;
    info.pColorBlendState = &state.blend;
    info.pDynamicState = &state.dynamic;
    info.layout = (*layout)->handle;
    // Render pass tương thích với mọi pass sẽ vẽ bằng pipeline này (định dạng và số mẫu khớp).
    const Result<VkRenderPass> pass =
        passes_->compatible({.colors = desc.color_formats, .depth = desc.depth.format, .samples = desc.samples});
    if (!pass) return std::unexpected(pass.error());
    info.renderPass = *pass;
    info.subpass = 0;
    Pipeline pipeline{.point = VK_PIPELINE_BIND_POINT_GRAPHICS, .layout = *layout};
    const VkResult created = vkCreateGraphicsPipelines(device_, cache_, 1, &info, nullptr, &pipeline.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được pipeline đồ hoạ");
    return keep(pipeline, desc.name);
}

Result<PipelineHandle> VulkanDevice::create_pipeline(const ComputePipelineDesc& desc) {
    std::vector<VkPipelineShaderStageCreateInfo> stages;
    const std::array<ShaderHandle, 1> shaders{desc.shader};
    const Result<Program> program = gather(*this, shaders, stages);
    if (!program) return std::unexpected(program.error());
    const bool is_compute = program->reflection.stages.has(shader::Stage::kCompute);
    if (!is_compute) return fail(kBad, "pipeline compute cần shader stage Compute");
    const Result<const Layout*> layout = layout_for(program->layout);
    if (!layout) return std::unexpected(layout.error());
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkComputePipelineCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
    info.stage = stages.front();
    info.layout = (*layout)->handle;
    Pipeline pipeline{.point = VK_PIPELINE_BIND_POINT_COMPUTE, .layout = *layout};
    const VkResult created = vkCreateComputePipelines(device_, cache_, 1, &info, nullptr, &pipeline.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được pipeline compute");
    return keep(pipeline, desc.name);
}

Result<PipelineHandle> VulkanDevice::keep(Pipeline& pipeline, std::string_view name) {
    set_name(VK_OBJECT_TYPE_PIPELINE, std::bit_cast<std::uint64_t>(pipeline.handle), name);
    const PipelineHandle handle = pipelines_.insert(pipeline);
    if (handle) return handle;
    discard(pipeline);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng pipeline");
}

void VulkanDevice::discard(Pipeline& pipeline) noexcept {
    if (pipeline.handle != VK_NULL_HANDLE) vkDestroyPipeline(device_, pipeline.handle, nullptr);
    pipeline = {};
}

Result<VkDescriptorPool> VulkanDevice::add_set_pool() {
    VkDescriptorPoolCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    info.flags = VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
    info.maxSets = kPoolSets;
    info.poolSizeCount = static_cast<std::uint32_t>(kPoolSizes.size());
    info.pPoolSizes = kPoolSizes.data();
    VkDescriptorPool pool = VK_NULL_HANDLE;
    const VkResult created = vkCreateDescriptorPool(device_, &info, nullptr, &pool);
    if (created != VK_SUCCESS) return failed(created, "không tạo được descriptor pool");
    set_pools_.push_back(pool);
    return pool;
}

// Pool cũ có chỗ do nhóm đã huỷ trả lại, nên mọi pool đều được thử trước khi mở pool mới.
VkResult VulkanDevice::take_set(VkDescriptorSetAllocateInfo& info, VkDescriptorSet& set) {
    VkResult allocated = VK_ERROR_OUT_OF_POOL_MEMORY;
    // Khác gốc: gốc return giữa vòng for khi kết quả không phải "pool đầy"; ở đây điều kiện ấy
    // nằm trên điều kiện lặp, cùng thứ tự thử và cùng giá trị trả (PH-01).
    for (std::size_t tried = 0; tried < set_pools_.size() && is_pool_full(allocated); ++tried) {
        const std::size_t index = (set_cursor_ + tried) % set_pools_.size();
        info.descriptorPool = set_pools_.at(index);
        allocated = vkAllocateDescriptorSets(device_, &info, &set);
        set_cursor_ = allocated == VK_SUCCESS ? index : set_cursor_;
    }
    return is_pool_full(allocated) ? VK_ERROR_OUT_OF_POOL_MEMORY : allocated;
}

Status VulkanDevice::allocate_set(BindGroup& group, const SpaceLayout& space) {
    if (space.is_unbounded) return allocate_own_set(group, space);
    const std::scoped_lock lock(set_mutex_);
    VkDescriptorSetAllocateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    info.descriptorSetCount = 1;
    info.pSetLayouts = &group.layout->sets.at(group.space);
    VkResult allocated = take_set(info, group.set);
    // Khác gốc: gốc lồng phần mở pool mới trong một
    // khối if; ở đây từng lệnh mang điều kiện ấy,
    // cùng thứ tự, pool cũ còn chỗ thì giữ (PH-01).
    const bool needs_pool = is_pool_full(allocated);
    Result<VkDescriptorPool> pool = info.descriptorPool;
    if (needs_pool) pool = add_set_pool();
    if (!pool) return std::unexpected(pool.error());
    if (needs_pool) set_cursor_ = set_pools_.size() - 1;
    info.descriptorPool = *pool;
    if (needs_pool) allocated = vkAllocateDescriptorSets(device_, &info, &group.set);
    // Pool chung còn trống mà vẫn không đủ: nhóm lớn hơn cả một pool, cho nó pool riêng.
    if (is_pool_full(allocated)) return allocate_own_set(group, space);
    if (allocated != VK_SUCCESS) return failed(allocated, "không cấp được descriptor set");
    group.pool = info.descriptorPool;
    return ok();
}

Status VulkanDevice::allocate_own_set(BindGroup& group, const SpaceLayout& space) {
    std::vector<VkDescriptorPoolSize> sizes;
    for (const shader::Resource& resource : space.resources) {
        const std::uint32_t count = resource.count == 0 ? group.capacity : resource.count;
        sizes.push_back({.type = to_vk(resource.kind), .descriptorCount = count});
    }
    VkDescriptorPoolCreateInfo pool_info{};
    pool_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pool_info.maxSets = 1;
    pool_info.poolSizeCount = static_cast<std::uint32_t>(sizes.size());
    pool_info.pPoolSizes = sizes.data();
    if (space.is_unbounded) pool_info.flags = VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT;
    const VkResult made = vkCreateDescriptorPool(device_, &pool_info, nullptr, &group.pool);
    if (made != VK_SUCCESS) return failed(made, "không tạo được descriptor pool riêng của nhóm");
    group.owns_pool = true;
    VkDescriptorSetVariableDescriptorCountAllocateInfo counts{};
    counts.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO;
    counts.descriptorSetCount = 1;
    counts.pDescriptorCounts = &group.capacity;
    VkDescriptorSetAllocateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    info.pNext = space.is_unbounded ? &counts : nullptr;
    info.descriptorPool = group.pool;
    info.descriptorSetCount = 1;
    info.pSetLayouts = &group.layout->sets.at(group.space);
    const VkResult allocated = vkAllocateDescriptorSets(device_, &info, &group.set);
    if (allocated != VK_SUCCESS) return failed(allocated, "không cấp được descriptor set riêng");
    return ok();
}

Result<BindGroupHandle> VulkanDevice::create_bind_group(const BindGroupDesc& desc) {
    const Pipeline* const pipeline = pipelines_.find(desc.pipeline);
    if (pipeline == nullptr) return fail(kBad, "nhóm gắn: pipeline đã chết");
    if (desc.space >= kMaxBindGroups) return fail(kBad, "nhóm gắn: space vượt kMaxBindGroups");
    const SpaceLayout& space = pipeline->layout->program.spaces.at(desc.space);
    if (space.resources.empty()) return fail(kBad, "nhóm gắn: pipeline không dùng space này");
    const Status checked = check_entries(space, desc.entries, desc.capacity, true);
    if (!checked) return std::unexpected(checked.error());
    const Status sized = check_capacity(space, desc.capacity, caps_);
    if (!sized) return std::unexpected(sized.error());
    BindGroup group{.layout = pipeline->layout, .space = desc.space, .capacity = desc.capacity};
    const Status allocated = allocate_set(group, space);
    if (!allocated) discard(group);
    if (!allocated) return std::unexpected(allocated.error());
    const Status written = write_group(group, desc.entries);
    if (!written) discard(group);
    if (!written) return std::unexpected(written.error());
    set_name(VK_OBJECT_TYPE_DESCRIPTOR_SET, std::bit_cast<std::uint64_t>(group.set), desc.name);
    const BindGroupHandle handle = groups_.insert(group);
    if (handle) return handle;
    discard(group);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng nhóm gắn");
}

Status VulkanDevice::update_bind_group(BindGroupHandle group, std::span<const BindEntry> entries) {
    const BindGroup* const found = groups_.find(group);
    if (found == nullptr) return fail(kBad, "update_bind_group: nhóm đã chết");
    const SpaceLayout& space = found->layout->program.spaces.at(found->space);
    const Status checked = check_update(space, entries, found->capacity);
    if (!checked) return checked;
    return write_group(*found, entries);
}

void VulkanDevice::discard(BindGroup& group) noexcept {
    if (group.owns_pool) vkDestroyDescriptorPool(device_, group.pool, nullptr);
    const bool is_shared = !group.owns_pool && group.set != VK_NULL_HANDLE;
    if (is_shared) {
        const std::scoped_lock lock(set_mutex_);
        vkFreeDescriptorSets(device_, group.pool, 1, &group.set);
    }
    group = {};
}

Status VulkanDevice::write_group(const BindGroup& group, std::span<const BindEntry> entries) {
    Writes batch;
    batch.images.reserve(entries.size());
    batch.buffers.reserve(entries.size());
    batch.writes.reserve(entries.size());
    Status added = ok();
    // Khác gốc: gốc return lỗi giữa vòng for; ở đây vòng dừng ở entry lỗi
    // đầu tiên, cùng thứ tự duyệt (PH-01).
    for (auto entry = entries.begin(); entry != entries.end() && added; ++entry) {
        added = add_write(batch, *this, group, *entry);
    }
    if (!added) return added;
    const auto count = static_cast<std::uint32_t>(batch.writes.size());
    vkUpdateDescriptorSets(device_, count, batch.writes.data(), 0, nullptr);
    return ok();
}

} // namespace game::gpu::vulkan
