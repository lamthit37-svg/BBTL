// Buffer, texture, view, sampler, truy vấn và bộ nhớ của backend Vulkan.
// Nguồn: Forge2 src/gpu/vulkan/resources.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân
// vòng lặp có nhánh của find_type, format_support, memory_budget đổi thành điều kiện lặp hoặc phép
// chọn (ghi tại chỗ); kSupport và VkExtent3D ghi tên trường; lambda của retire_from bỏ () rỗng;
// include trực tiếp header của mọi tên dùng tới, bỏ core/log.hpp không dùng.
#include "core/error.hpp"
#include "gpu/check.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/memory.hpp"
#include "gpu/resource.hpp"
#include "gpu/timestamp.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/convert.hpp"
#include "gpu/vulkan/device.hpp"

#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <tuple>
#include <utility>
#include <vector>

namespace game::gpu::vulkan {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr std::uint32_t kNoType = ~std::uint32_t{0};

// Cờ bộ nhớ bắt buộc của một miền. Upload không xin DEVICE_LOCAL: card rời chỉ có một dải nhỏ vừa
// của GPU vừa nhìn thấy được từ CPU, dành nó cho dữ liệu tải lên là cướp chỗ của thứ thật sự cần.
[[nodiscard]] VkMemoryPropertyFlags required_flags(MemoryDomain domain) noexcept {
    const VkMemoryPropertyFlags visible = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
    switch (domain) {
    case MemoryDomain::kDevice: return VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
    case MemoryDomain::kUpload: return visible;
    case MemoryDomain::kReadback: return visible | VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
    }
    return 0;
}

// Kiểu bộ nhớ đầu tiên nằm trong type_bits, có đủ wanted và không có cờ nào của avoided.
// NOLINTBEGIN(bugprone-easily-swappable-parameters): chỉ pick_type gọi (lệch API-03)
[[nodiscard]] std::uint32_t find_type(const VkPhysicalDeviceMemoryProperties& memory, std::uint32_t type_bits,
    VkMemoryPropertyFlags wanted, VkMemoryPropertyFlags avoided) noexcept {
    const std::span types(memory.memoryTypes);
    const auto fits = [&](std::uint32_t index) noexcept {
        const VkMemoryPropertyFlags flags = types.subspan(index, 1).front().propertyFlags;
        const bool is_allowed = (type_bits & (1U << index)) != 0;
        const bool is_fitting = (flags & wanted) == wanted && (flags & avoided) == 0;
        return is_allowed && is_fitting;
    };
    std::uint32_t index = 0;
    // Khác gốc: gốc return giữa vòng for; ở đây điều kiện
    // dừng nằm trên điều kiện lặp, cùng thứ tự (PH-01).
    while (index < memory.memoryTypeCount && !fits(index)) {
        ++index;
    }
    return index < memory.memoryTypeCount ? index : kNoType;
}
// NOLINTEND(bugprone-easily-swappable-parameters)

// Thử lần lượt từ chặt tới lỏng: mỗi miền có một lựa chọn tốt nhất và các đường lùi chỉ kém về tốc
// độ, không kém về tính đúng.
[[nodiscard]] std::uint32_t pick_type(const VkPhysicalDeviceMemoryProperties& memory, std::uint32_t type_bits,
    MemoryDomain domain, bool is_transient) noexcept {
    const VkMemoryPropertyFlags lazy = VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT;
    const VkMemoryPropertyFlags local = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
    const VkMemoryPropertyFlags cached = VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
    const VkMemoryPropertyFlags wanted = required_flags(domain);
    std::uint32_t type = kNoType;
    if (is_transient) type = find_type(memory, type_bits, wanted | lazy, 0);
    const bool is_host = domain != MemoryDomain::kDevice;
    if (type == kNoType && is_host) type = find_type(memory, type_bits, wanted, local);
    if (type == kNoType) type = find_type(memory, type_bits, wanted, lazy);
    if (type == kNoType) type = find_type(memory, type_bits, wanted & ~cached, lazy);
    return type;
}

[[nodiscard]] VkImageCreateFlags image_flags(const TextureDesc& desc) noexcept {
    const bool is_cube = desc.kind == TextureKind::kCube || desc.kind == TextureKind::kCubeArray;
    VkImageCreateFlags flags = 0;
    if (is_cube) flags |= VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;
    if (has(desc.usage, TextureUsage::kReinterpret)) flags |= VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT;
    return flags;
}

[[nodiscard]] VkImageAspectFlags view_aspect(const ViewRange& range) noexcept {
    switch (range.aspect) {
    case ViewAspect::kAll: return aspect_of(range.format);
    case ViewAspect::kDepth: return VK_IMAGE_ASPECT_DEPTH_BIT;
    case ViewAspect::kStencil: return VK_IMAGE_ASPECT_STENCIL_BIT;
    }
    return aspect_of(range.format);
}

// Một cờ khả năng của engine và bit tính năng định dạng của Vulkan ứng với nó.
struct SupportRow {
    FormatSupport support;
    VkFormatFeatureFlags feature;
};

constexpr std::array kSupport{
    SupportRow{.support = FormatSupport::kSampled, .feature = VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT},
    SupportRow{.support = FormatSupport::kFiltered, .feature = VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT},
    SupportRow{.support = FormatSupport::kColorTarget, .feature = VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT},
    SupportRow{.support = FormatSupport::kBlendable, .feature = VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT},
    SupportRow{.support = FormatSupport::kDepthTarget, .feature = VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT},
    SupportRow{.support = FormatSupport::kStorage, .feature = VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT},
};

// Một ô kết quả truy vấn đọc kèm cờ "đã có".
struct QueryResult {
    std::uint64_t value = 0;
    std::uint64_t is_available = 0;
};

// Cách dựng một khối của một pool bộ nhớ.
struct BlockPlan {
    VkDevice device = VK_NULL_HANDLE;
    std::uint32_t type = 0;
    // Ánh xạ khối suốt đời nó: kiểu bộ nhớ CPU nhìn thấy được.
    bool is_visible = false;
    // Buffer nào cũng có thể được xin địa chỉ, nên mọi khối của buffer bật cờ địa chỉ.
    bool is_addressed = false;
};

[[nodiscard]] core::Result<Block> make_block(const BlockPlan& plan, std::uint64_t bytes) {
    VkMemoryAllocateFlagsInfo flags{};
    flags.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO;
    flags.flags = VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT;
    VkMemoryAllocateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    info.pNext = plan.is_addressed ? &flags : nullptr;
    info.allocationSize = bytes;
    info.memoryTypeIndex = plan.type;
    VkDeviceMemory memory = VK_NULL_HANDLE;
    const VkResult allocated = vkAllocateMemory(plan.device, &info, nullptr, &memory);
    if (allocated != VK_SUCCESS) return fail_vk(allocated, "không cấp được khối bộ nhớ GPU");
    // Block giữ memory từ đây: đường lỗi bên dưới trả nó qua destructor.
    Block block(plan.device, memory, nullptr);
    if (!plan.is_visible) return block;
    void* mapped = nullptr;
    const VkResult shown = vkMapMemory(plan.device, memory, 0, VK_WHOLE_SIZE, 0, &mapped);
    if (shown != VK_SUCCESS) return fail_vk(shown, "không ánh xạ được khối bộ nhớ GPU");
    block.set_mapped(static_cast<std::byte*>(mapped));
    return block;
}

} // namespace

Pool& VulkanDevice::pool_at(std::uint32_t index) {
    const std::scoped_lock lock(memory_mutex_);
    std::unique_ptr<Pool>& slot = pools_.at(index);
    if (slot) return *slot;
    const std::uint32_t type = index / 2;
    const bool is_image = index % 2 != 0;
    const VkMemoryType layout = std::span(memory_.memoryTypes).subspan(type, 1).front();
    const VkMemoryHeap heap = std::span(memory_.memoryHeaps).subspan(layout.heapIndex, 1).front();
    BlockPlan plan{.device = device_, .type = type};
    plan.is_visible = (layout.propertyFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) != 0;
    plan.is_addressed = traits_.address && !is_image;
    const auto factory = [plan](std::uint64_t bytes) { return make_block(plan, bytes); };
    // Heap nhỏ (GPU tích hợp, điện thoại) thì khối nhỏ theo: một khối không được nuốt cả heap.
    constexpr std::uint64_t kLargest = std::uint64_t{64} << 20U;
    constexpr std::uint64_t kSmallest = std::uint64_t{4} << 20U;
    MemoryConfig config{.block_bytes = std::clamp(heap.size / 8, kSmallest, kLargest)};
    config.max_nodes = 16384;
    slot = std::make_unique<Pool>(config, factory);
    return *slot;
}

Result<Allocation> VulkanDevice::allocate(const VkMemoryRequirements& needs, MemoryDomain domain, bool is_image,
    bool is_transient) {
    const std::uint32_t type = pick_type(memory_, needs.memoryTypeBits, domain, is_transient);
    if (type == kNoType) return fail(ErrorCode::kUnsupported, "không có kiểu bộ nhớ GPU phù hợp");
    const std::uint32_t index = (type * 2) + (is_image ? 1U : 0U);
    core::Result<MemorySpan> span = pool_at(index).allocate(needs.size, needs.alignment);
    if (!span) return std::unexpected(std::move(span).error());
    return Allocation{.span = *span, .pool = index};
}

void VulkanDevice::free(const Allocation& allocation) noexcept {
    if (!allocation.span.valid()) return;
    pools_.at(allocation.pool)->free(allocation.span);
}

FormatSupport VulkanDevice::format_support(Format format) const {
    VkFormatProperties properties{};
    vkGetPhysicalDeviceFormatProperties(physical_, to_vk(format), &properties);
    FormatSupport support = FormatSupport::kNone;
    for (const SupportRow& row : kSupport) {
        const bool is_present = (properties.optimalTilingFeatures & row.feature) != 0;
        // Khác gốc: gốc là câu if một dòng, cùng kết quả (PH-01).
        support |= is_present ? row.support : FormatSupport::kNone;
    }
    return support;
}

MemoryBudget VulkanDevice::memory_budget() const {
    VkPhysicalDeviceMemoryBudgetPropertiesEXT budget{};
    budget.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT;
    VkPhysicalDeviceMemoryProperties2 properties{};
    properties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2;
    properties.pNext = traits_.memory_budget ? &budget : nullptr;
    vkGetPhysicalDeviceMemoryProperties2(physical_, &properties);
    const VkPhysicalDeviceMemoryProperties& memory = properties.memoryProperties;
    const std::span heaps(memory.memoryHeaps);
    const std::span allowed(budget.heapBudget);
    const std::span used(budget.heapUsage);
    MemoryBudget total;
    for (std::uint32_t index = 0; index < memory.memoryHeapCount; ++index) {
        const VkMemoryHeap heap = heaps.subspan(index, 1).front();
        // Khác gốc: gốc continue với heap ngoài GPU; ở đây nó cộng 0 (PH-01).
        const bool is_local = (heap.flags & VK_MEMORY_HEAP_DEVICE_LOCAL_BIT) != 0;
        // Không có VK_EXT_memory_budget thì chỉ biết cỡ heap, không biết các tiến trình khác giữ
        // bao nhiêu.
        const std::uint64_t budgeted = allowed.subspan(index, 1).front();
        const std::uint64_t limit = traits_.memory_budget ? budgeted : heap.size;
        total.budget_bytes += is_local ? limit : 0;
        total.used_bytes += is_local ? used.subspan(index, 1).front() : 0;
    }
    return total;
}

Result<BufferHandle> VulkanDevice::create_buffer(const BufferDesc& desc) {
    const Status checked = check_buffer(desc);
    if (!checked) return std::unexpected(checked.error());
    const bool wants_address = has(desc.usage, BufferUsage::kAddress);
    if (wants_address && !traits_.address) {
        return fail(ErrorCode::kUnsupported, "thiết bị không có địa chỉ buffer");
    }
    VkBufferCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    info.size = desc.size;
    info.usage = to_vk(desc.usage);
    info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    Buffer buffer{.size = desc.size, .usage = desc.usage, .domain = desc.memory};
    const VkResult created = vkCreateBuffer(device_, &info, nullptr, &buffer.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được buffer");
    VkMemoryRequirements needs{};
    vkGetBufferMemoryRequirements(device_, buffer.handle, &needs);
    Result<Allocation> memory = allocate(needs, desc.memory, false, false);
    if (memory) buffer.memory = *memory;
    const Status bound = memory ? bind(buffer) : Status(std::unexpected(memory.error()));
    if (!bound) discard(buffer);
    if (!bound) return std::unexpected(bound.error());
    VkBufferDeviceAddressInfo address{};
    address.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO;
    address.buffer = buffer.handle;
    if (wants_address) buffer.address = buffer_address(device_, &address);
    set_name(VK_OBJECT_TYPE_BUFFER, std::bit_cast<std::uint64_t>(buffer.handle), desc.name);
    const BufferHandle handle = buffers_.insert(buffer);
    if (handle) return handle;
    discard(buffer);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng buffer");
}

// Gắn buffer vào vùng nhớ đã cấp và tính chỗ của nó trong vùng ánh xạ.
Status VulkanDevice::bind(Buffer& buffer) {
    Pool& pool = *pools_.at(buffer.memory.pool);
    const Block& block = pool.block(buffer.memory.span);
    const std::uint64_t offset = buffer.memory.span.offset;
    const VkResult bound = vkBindBufferMemory(device_, buffer.handle, block.memory(), offset);
    if (bound != VK_SUCCESS) return failed(bound, "không gắn được bộ nhớ cho buffer");
    if (block.mapped() == nullptr) return ok();
    const std::span<std::byte> visible(block.mapped(), offset + buffer.size);
    buffer.mapped = visible.subspan(offset).data();
    return ok();
}

void VulkanDevice::discard(Buffer& buffer) noexcept {
    if (buffer.handle != VK_NULL_HANDLE) vkDestroyBuffer(device_, buffer.handle, nullptr);
    free(buffer.memory);
    buffer = {};
}

Result<TextureHandle> VulkanDevice::create_texture(const TextureDesc& desc) {
    const Status checked = check_texture(desc, caps_);
    if (!checked) return std::unexpected(checked.error());
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkImageCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    info.flags = image_flags(desc);
    info.imageType = to_image_type(desc.kind);
    info.format = to_vk(desc.format);
    info.extent = {.width = desc.width, .height = desc.height, .depth = depth_of(desc)};
    info.mipLevels = desc.mip_levels;
    info.arrayLayers = layer_count(desc);
    info.samples = to_samples(desc.samples);
    info.tiling = VK_IMAGE_TILING_OPTIMAL;
    info.usage = to_vk(desc.usage);
    info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    info.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    Texture texture{.desc = desc};
    texture.desc.name = {};
    const VkResult created = vkCreateImage(device_, &info, nullptr, &texture.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được texture");
    VkMemoryRequirements needs{};
    vkGetImageMemoryRequirements(device_, texture.handle, &needs);
    const bool is_transient = has(desc.usage, TextureUsage::kTransient);
    Result<Allocation> memory = allocate(needs, MemoryDomain::kDevice, true, is_transient);
    if (memory) texture.memory = *memory;
    const Status bound = memory ? bind(texture) : Status(std::unexpected(memory.error()));
    if (!bound) discard(texture);
    if (!bound) return std::unexpected(bound.error());
    set_name(VK_OBJECT_TYPE_IMAGE, std::bit_cast<std::uint64_t>(texture.handle), desc.name);
    const TextureHandle handle = textures_.insert(texture);
    if (handle) return handle;
    discard(texture);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng texture");
}

Status VulkanDevice::bind(Texture& texture) {
    Pool& pool = *pools_.at(texture.memory.pool);
    const Block& block = pool.block(texture.memory.span);
    const std::uint64_t offset = texture.memory.span.offset;
    const VkResult bound = vkBindImageMemory(device_, texture.handle, block.memory(), offset);
    if (bound != VK_SUCCESS) return failed(bound, "không gắn được bộ nhớ cho texture");
    return ok();
}

void VulkanDevice::discard(Texture& texture) noexcept {
    const bool is_destroyed = texture.is_owned && texture.handle != VK_NULL_HANDLE;
    if (is_destroyed) vkDestroyImage(device_, texture.handle, nullptr);
    free(texture.memory);
    texture = {};
}

TextureHandle VulkanDevice::adopt(VkImage image, const TextureDesc& desc) {
    Texture texture{.handle = image, .desc = desc, .is_owned = false};
    texture.desc.name = {};
    return textures_.insert(texture);
}

void VulkanDevice::release(TextureHandle handle) {
    std::ignore = textures_.remove(handle);
}

void VulkanDevice::release(TextureViewHandle handle) {
    std::optional<View> view = views_.remove(handle);
    if (view) discard(*view);
}

Result<TextureViewHandle> VulkanDevice::create_view(const TextureViewDesc& desc) {
    const Texture* const texture = textures_.find(desc.texture);
    if (texture == nullptr) return fail(ErrorCode::kInvalidArgument, "view: texture đã chết");
    const core::Result<ViewRange> range = resolve_view(desc, texture->desc);
    if (!range) return std::unexpected(range.error());
    VkImageViewCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    info.image = texture->handle;
    info.viewType = to_view_type(desc.kind);
    info.format = to_vk(range->format);
    info.subresourceRange.aspectMask = view_aspect(*range);
    info.subresourceRange.baseMipLevel = range->first_mip;
    info.subresourceRange.levelCount = range->mip_count;
    info.subresourceRange.baseArrayLayer = range->first_layer;
    info.subresourceRange.layerCount = range->layer_count;
    View view{.texture = desc.texture, .range = *range};
    view.width = mip_size(texture->desc.width, range->first_mip);
    view.height = mip_size(texture->desc.height, range->first_mip);
    view.samples = texture->desc.samples;
    const VkResult created = vkCreateImageView(device_, &info, nullptr, &view.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được view");
    set_name(VK_OBJECT_TYPE_IMAGE_VIEW, std::bit_cast<std::uint64_t>(view.handle), desc.name);
    const TextureViewHandle handle = views_.insert(view);
    if (handle) return handle;
    discard(view);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng view");
}

void VulkanDevice::discard(View& view) noexcept {
    if (view.handle != VK_NULL_HANDLE) vkDestroyImageView(device_, view.handle, nullptr);
    view = {};
}

Result<SamplerHandle> VulkanDevice::create_sampler(const SamplerDesc& desc) {
    const auto most = static_cast<float>(caps_.max_anisotropy);
    const auto anisotropy = std::clamp(static_cast<float>(desc.max_anisotropy), 1.0F, most);
    VkSamplerCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
    info.magFilter = to_vk(desc.mag_filter);
    info.minFilter = to_vk(desc.min_filter);
    info.mipmapMode = to_mip_mode(desc.mip_filter);
    info.addressModeU = to_vk(desc.address_u);
    info.addressModeV = to_vk(desc.address_v);
    info.addressModeW = to_vk(desc.address_w);
    info.mipLodBias = desc.mip_bias;
    info.anisotropyEnable = anisotropy > 1.0F ? VK_TRUE : VK_FALSE;
    info.maxAnisotropy = anisotropy;
    info.compareEnable = desc.compare != CompareOp::kNever ? VK_TRUE : VK_FALSE;
    info.compareOp = to_vk(desc.compare);
    info.minLod = desc.min_lod;
    info.maxLod = desc.max_lod;
    info.borderColor = to_vk(desc.border);
    Sampler sampler;
    const VkResult created = vkCreateSampler(device_, &info, nullptr, &sampler.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được sampler");
    set_name(VK_OBJECT_TYPE_SAMPLER, std::bit_cast<std::uint64_t>(sampler.handle), desc.name);
    const SamplerHandle handle = samplers_.insert(sampler);
    if (handle) return handle;
    discard(sampler);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng sampler");
}

void VulkanDevice::discard(Sampler& sampler) noexcept {
    if (sampler.handle != VK_NULL_HANDLE) vkDestroySampler(device_, sampler.handle, nullptr);
    sampler = {};
}

Result<QueryPoolHandle> VulkanDevice::create_query_pool(const QueryPoolDesc& desc) {
    if (desc.count == 0) return fail(ErrorCode::kInvalidArgument, "query pool: count bằng 0");
    const bool is_timestamp = desc.kind == QueryKind::kTimestamp;
    const bool is_timed = caps_.has_timestamps.at(std::to_underlying(desc.queue));
    if (is_timestamp && !is_timed) {
        return fail(ErrorCode::kUnsupported, "hàng đợi không ghi được dấu thời gian");
    }
    VkQueryPoolCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
    info.queryType = is_timestamp ? VK_QUERY_TYPE_TIMESTAMP : VK_QUERY_TYPE_OCCLUSION;
    info.queryCount = desc.count;
    QueryPool pool{.kind = desc.kind, .count = desc.count, .queue = desc.queue};
    const VkResult created = vkCreateQueryPool(device_, &info, nullptr, &pool.handle);
    if (created != VK_SUCCESS) return failed(created, "không tạo được query pool");
    set_name(VK_OBJECT_TYPE_QUERY_POOL, std::bit_cast<std::uint64_t>(pool.handle), desc.name);
    const QueryPoolHandle handle = queries_.insert(pool);
    if (handle) return handle;
    discard(pool);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng query pool");
}

void VulkanDevice::discard(QueryPool& pool) noexcept {
    if (pool.handle != VK_NULL_HANDLE) vkDestroyQueryPool(device_, pool.handle, nullptr);
    pool = {};
}

Status VulkanDevice::read_queries(QueryPoolHandle pool, std::uint32_t first, std::span<std::uint64_t> out) {
    const QueryPool* const found = queries_.find(pool);
    if (found == nullptr) return fail(ErrorCode::kInvalidArgument, "read_queries: pool đã chết");
    const Status inside = check_span(found->count, first, out.size());
    if (!inside) return inside;
    if (out.empty()) return ok();
    std::vector<QueryResult> results(out.size());
    const auto count = static_cast<std::uint32_t>(out.size());
    const VkQueryResultFlags flags = VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WITH_AVAILABILITY_BIT;
    const VkResult read = vkGetQueryPoolResults(device_, found->handle, first, count,
        results.size() * sizeof(QueryResult), results.data(), sizeof(QueryResult), flags);
    const bool is_usable = read == VK_SUCCESS || read == VK_NOT_READY;
    if (!is_usable) return failed(read, "không đọc được kết quả truy vấn");
    const auto is_ready = [](const QueryResult& result) { return result.is_available != 0; };
    if (!std::ranges::all_of(results, is_ready)) {
        return fail(ErrorCode::kWouldBlock, "kết quả truy vấn chưa có: GPU chưa chạy xong");
    }
    if (found->kind == QueryKind::kOcclusion) {
        std::ranges::transform(results, out.begin(), &QueryResult::value);
        return ok();
    }
    // Mốc đầu là giá trị tuyệt đối; các mốc sau tính bằng khoảng cách có dấu tới mốc đầu, nên so
    // được với nhau cả khi bộ đếm hẹp hơn 64 bit vừa quay vòng.
    const std::uint32_t bits = queue(found->queue).timestamp_bits;
    const auto period = static_cast<double>(limits_.timestampPeriod);
    const std::uint64_t base = results.front().value;
    const double start = ticks_to_ns(mask_timestamp(base, bits), period);
    for (std::size_t index = 0; index < out.size(); ++index) {
        const std::int64_t offset = timestamp_offset(base, results.at(index).value, bits);
        const double nanos = start + (static_cast<double>(offset) * period);
        out.subspan(index, 1).front() = static_cast<std::uint64_t>(std::max(nanos, 0.0));
    }
    return ok();
}

std::uint64_t VulkanDevice::address(BufferHandle handle) const {
    const Buffer* const buffer = buffers_.find(handle);
    return buffer == nullptr ? 0 : buffer->address;
}

Status VulkanDevice::write_buffer(BufferHandle handle, std::uint64_t offset, std::span<const std::byte> data) {
    const Buffer* const buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(ErrorCode::kInvalidArgument, "write_buffer: buffer đã chết");
    const bool is_writable = buffer->domain == MemoryDomain::kUpload && buffer->mapped != nullptr;
    if (!is_writable) return fail(kBad, "write_buffer: buffer không phải Upload");
    const Status inside = check_span(buffer->size, offset, data.size());
    if (!inside) return inside;
    const std::span<std::byte> mapped(buffer->mapped, buffer->size);
    std::ranges::copy(data, mapped.subspan(offset).begin());
    return ok();
}

Status VulkanDevice::read_buffer(BufferHandle handle, std::uint64_t offset, std::span<std::byte> out) {
    const Buffer* const buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(ErrorCode::kInvalidArgument, "read_buffer: buffer đã chết");
    const bool is_readable = buffer->domain == MemoryDomain::kReadback && buffer->mapped != nullptr;
    if (!is_readable) return fail(kBad, "read_buffer: buffer không phải Readback");
    const Status inside = check_span(buffer->size, offset, out.size());
    if (!inside) return inside;
    const std::span<const std::byte> mapped(buffer->mapped, buffer->size);
    std::ranges::copy(mapped.subspan(offset, out.size()), out.begin());
    return ok();
}

template <class T, class Tag>
void VulkanDevice::retire_from(Slots<T, Tag>& table, Handle<Tag> handle) {
    std::optional<T> item = table.remove(handle);
    if (!item) return;
    retire([this, held = std::move(*item)] mutable { discard(held); });
}

void VulkanDevice::destroy(BufferHandle handle) {
    retire_from(buffers_, handle);
}

void VulkanDevice::destroy(TextureHandle handle) {
    retire_from(textures_, handle);
}

void VulkanDevice::destroy(TextureViewHandle handle) {
    retire_from(views_, handle);
}

void VulkanDevice::destroy(SamplerHandle handle) {
    retire_from(samplers_, handle);
}

void VulkanDevice::destroy(ShaderHandle handle) {
    retire_from(shaders_, handle);
}

void VulkanDevice::destroy(PipelineHandle handle) {
    retire_from(pipelines_, handle);
}

void VulkanDevice::destroy(BindGroupHandle handle) {
    retire_from(groups_, handle);
}

void VulkanDevice::destroy(QueryPoolHandle handle) {
    retire_from(queries_, handle);
}

} // namespace game::gpu::vulkan
