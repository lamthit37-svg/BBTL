// Ghi lệnh của backend Vulkan — các hàm cmd* của Vulkan.c trong _Ref. Mỗi lệnh kiểm tay nắm và
// trạng thái trước khi gọi xuống trình điều khiển; phép kiểm là vài phép so sánh và một lần tra
// bảng không khoá, không cấp phát.
// Nguồn: Forge2 src/gpu/vulkan/commands.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; mọi câu
// return reject(...) và return vkCmd...(...) trong hàm void thành lời gọi rồi return trong ngoặc
// nhọn; begin_rendering tách phần thuần tính toán và lời gọi vkCmdBeginRendering ra is_valid_pass,
// run_each, area_of, begin_pass (kèm struct Pass); vòng lặp của fill_regions đưa điều kiện dừng lên
// điều kiện lặp; khởi tạo aggregate ghi tên trường; biến at của hai lệnh vẽ gián tiếp thành
// position; điều kiện của câu bảo vệ thứ hai trong close có tên; include trực tiếp header của mọi
// tên dùng tới.
#include "gpu/vulkan/commands.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "gpu/barrier.hpp"
#include "gpu/check.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/layout.hpp"
#include "gpu/resource.hpp"
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
#include <span>
#include <string_view>
#include <tuple>
#include <utility>

namespace game::gpu::vulkan {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kState = ErrorCode::kInvalidState;

// kAllMips và kAllLayers trùng giá trị với hằng "phần còn lại" của Vulkan nên đi thẳng xuống.
static_assert(kAllMips == VK_REMAINING_MIP_LEVELS);
static_assert(kAllLayers == VK_REMAINING_ARRAY_LAYERS);
// Tham số lệnh gián tiếp của engine có đúng bố cục của Vulkan (và của D3D12).
static_assert(sizeof(DrawArguments) == sizeof(VkDrawIndirectCommand));
static_assert(sizeof(DrawIndexedArguments) == sizeof(VkDrawIndexedIndirectCommand));
static_assert(sizeof(DispatchArguments) == sizeof(VkDispatchIndirectCommand));

// Hai queue family của một lần chuyển quyền dùng; cả hai IGNORED khi không chuyển.
struct Families {
    std::uint32_t source = VK_QUEUE_FAMILY_IGNORED;
    std::uint32_t target = VK_QUEUE_FAMILY_IGNORED;
};

// Hai loại hàng đợi cùng một family (thiết bị thiếu hàng chuyên) thì không có gì để chuyển.
[[nodiscard]] Families families(VulkanDevice& device, const QueueTransfer& transfer) noexcept {
    if (!transfer.is_active) return {};
    const std::uint32_t source = device.queue(transfer.from).family;
    const std::uint32_t target = device.queue(transfer.to).family;
    if (source == target) return {};
    return {.source = source, .target = target};
}

[[nodiscard]] VkMemoryBarrier2 global_barrier(const GlobalBarrier& item) noexcept {
    VkMemoryBarrier2 barrier{};
    barrier.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER_2;
    barrier.srcStageMask = to_vk(item.stage_before);
    barrier.srcAccessMask = to_vk(item.access_before);
    barrier.dstStageMask = to_vk(item.stage_after);
    barrier.dstAccessMask = to_vk(item.access_after);
    return barrier;
}

// Số thực sang số nguyên của kênh màu, kẹp vào miền của kiểu đích: ép số ngoài miền là hành vi
// không xác định.
[[nodiscard]] std::uint32_t to_uint(float channel) noexcept {
    return static_cast<std::uint32_t>(std::clamp(channel, 0.0F, 4294967040.0F));
}

[[nodiscard]] std::int32_t to_sint(float channel) noexcept {
    return static_cast<std::int32_t>(std::clamp(channel, -2147483648.0F, 2147483520.0F));
}

// VkClearValue là union của API C: thành viên được ghi phải khớp kiểu số của định dạng; không
// thành viên nào bị đọc lại qua thành viên khác (KG-05).
// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access)
[[nodiscard]] VkClearValue clear_color(const ClearColor& color, Format format) noexcept {
    const std::array<float, 4> channels{color.red, color.green, color.blue, color.alpha};
    const bool is_integer = is_uint(format) || is_sint(format);
    VkClearValue value{};
    if (is_uint(format)) std::ranges::transform(channels, std::begin(value.color.uint32), to_uint);
    if (is_sint(format)) std::ranges::transform(channels, std::begin(value.color.int32), to_sint);
    if (!is_integer) std::ranges::copy(channels, std::begin(value.color.float32));
    return value;
}

[[nodiscard]] VkClearValue clear_depth(const ClearDepth& clear) noexcept {
    VkClearValue value{};
    value.depthStencil = {.depth = clear.depth, .stencil = clear.stencil};
    return value;
}
// NOLINTEND(cppcoreguidelines-pro-type-union-access)

// Attachment độ sâu của một lần vẽ. Chỉ đọc thì không ghi lại: trên GPU chia ô đó là một lần ghi
// attachment ra bộ nhớ được bỏ hẳn.
[[nodiscard]] VkRenderingAttachmentInfo depth_info(const DepthTarget& target, const View& view) {
    const TextureLayout layout = target.is_read_only ? TextureLayout::kDepthRead : TextureLayout::kDepthWrite;
    VkRenderingAttachmentInfo info{};
    info.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO;
    info.imageView = view.handle;
    info.imageLayout = to_vk(layout);
    info.loadOp = to_vk(target.load);
    info.storeOp = target.is_read_only ? VK_ATTACHMENT_STORE_OP_NONE : to_vk(target.store);
    info.clearValue = clear_depth(target.clear);
    return info;
}

[[nodiscard]] VkRenderingAttachmentInfo stencil_info(const DepthTarget& target,
    const VkRenderingAttachmentInfo& depth) noexcept {
    VkRenderingAttachmentInfo info = depth;
    info.loadOp = to_vk(target.stencil_load);
    info.storeOp = target.is_read_only ? VK_ATTACHMENT_STORE_OP_NONE : to_vk(target.stencil_store);
    return info;
}

[[nodiscard]] VkRect2D to_rect(const Scissor& scissor) noexcept {
    const VkOffset2D offset{.x = scissor.x, .y = scissor.y};
    const VkExtent2D extent{.width = scissor.width, .height = scissor.height};
    return {.offset = offset, .extent = extent};
}

// Chiều cao âm lật trục Y: NDC của engine có Y hướng lên như D3D12, còn gốc của viewport vẫn là góc
// trên trái của đích vẽ.
[[nodiscard]] VkViewport to_viewport(const Viewport& viewport) noexcept {
    VkViewport flipped{};
    flipped.x = viewport.x;
    flipped.y = viewport.y + viewport.height;
    flipped.width = viewport.width;
    flipped.height = -viewport.height;
    flipped.minDepth = viewport.min_depth;
    flipped.maxDepth = viewport.max_depth;
    return flipped;
}

[[nodiscard]] VkImageSubresourceLayers layers_of(Format format, std::uint32_t mip, std::uint32_t first_layer,
    std::uint32_t count) noexcept {
    // Định dạng độ sâu chỉ chép phần độ sâu; định dạng có stencil đã bị resolve_copy từ chối.
    const VkImageAspectFlags aspect =
        has_depth(format) ? VkImageAspectFlags{VK_IMAGE_ASPECT_DEPTH_BIT} : aspect_of(format);
    return {.aspectMask = aspect, .mipLevel = mip, .baseArrayLayer = first_layer, .layerCount = count};
}

[[nodiscard]] VkOffset3D to_offset(std::uint32_t left, std::uint32_t top, std::uint32_t front) noexcept {
    return {.x = static_cast<std::int32_t>(left),
        .y = static_cast<std::int32_t>(top),
        .z = static_cast<std::int32_t>(front)};
}

[[nodiscard]] VkBufferImageCopy to_copy(const CopyRegion& region, Format format) noexcept {
    const FormatInfo layout = info(format);
    VkBufferImageCopy copy{};
    copy.bufferOffset = region.buffer_offset;
    // Vulkan đo bước dòng và chiều cao một lát bằng texel, không bằng byte.
    copy.bufferRowLength = region.row_bytes / layout.block_bytes * layout.block_width;
    copy.bufferImageHeight = region.rows * layout.block_height;
    copy.imageSubresource = layers_of(format, region.mip, region.first_layer, region.layer_count);
    copy.imageOffset = to_offset(region.x, region.y, region.z);
    copy.imageExtent = {.width = region.width, .height = region.height, .depth = region.depth};
    return copy;
}

[[nodiscard]] VkImageCopy to_copy(const TextureCopy& region, Format format) noexcept {
    const TexturePoint& from = region.source;
    const TexturePoint& target = region.target;
    VkImageCopy copy{};
    copy.srcSubresource = layers_of(format, from.mip, from.layer, region.layer_count);
    copy.srcOffset = to_offset(from.x, from.y, from.z);
    copy.dstSubresource = layers_of(format, target.mip, target.layer, region.layer_count);
    copy.dstOffset = to_offset(target.x, target.y, target.z);
    copy.extent = {.width = region.width, .height = region.height, .depth = region.depth};
    return copy;
}

// Khác gốc: phép kiểm số attachment và số lớp của begin_rendering tách ra đây.
[[nodiscard]] bool is_valid_pass(const RenderingDesc& desc) noexcept {
    const bool is_empty = desc.colors.empty() && !desc.depth;
    return !is_empty && desc.colors.size() <= kMaxColorTargets && desc.layers != 0;
}

// Khác gốc: gốc viết vòng for có câu if (!fill_color(...)) return trong thân của begin_rendering;
// ở đây một hàm chạy step trên từng chỉ số theo thứ tự và dừng ở lần đầu step trả false.
template <class Step>
[[nodiscard]] bool run_each(std::size_t count, const Step& step) {
    bool is_done = true;
    for (std::size_t index = 0; index < count && is_done; ++index) {
        is_done = step(index);
    }
    return is_done;
}

// Khác gốc: phép chọn vùng vẽ của begin_rendering tách ra đây. Vùng chỗ gọi xin, hoặc trọn cỡ
// extent (attachment đầu tiên) khi chỗ gọi để rộng hay cao bằng 0.
[[nodiscard]] Scissor area_of(const Scissor& wanted, VkExtent2D extent) noexcept {
    const bool is_whole = wanted.width == 0 || wanted.height == 0;
    const Scissor whole{.x = 0, .y = 0, .width = extent.width, .height = extent.height};
    return is_whole ? whole : wanted;
}

// Khác gốc: gói những thứ begin_rendering đã kiểm và gom xong, đầu vào của begin_pass.
struct Pass {
    // kMaxColorTargets ô; desc.colors.size() ô đầu đã điền.
    std::span<const VkRenderingAttachmentInfo> colors;
    // nullptr khi lần vẽ không có attachment độ sâu.
    const View* depth_view = nullptr;
    Scissor area{};
};

// Khác gốc: phần dựng attachment độ sâu, stencil và VkRenderingInfo của begin_rendering tách ra
// đây, kèm lời gọi vkCmdBeginRendering; giá trị và thứ tự gán như gốc.
void begin_pass(VkCommandBuffer buffer, const RenderingDesc& desc, const Pass& pass) {
    const DepthTarget depth_target = desc.depth.value_or(DepthTarget{});
    const View* const depth_view = pass.depth_view;
    const Format depth_format = depth_view == nullptr ? Format::kUnknown : depth_view->range.format;
    VkRenderingAttachmentInfo depth{};
    if (depth_view != nullptr) depth = depth_info(depth_target, *depth_view);
    const VkRenderingAttachmentInfo stencil = stencil_info(depth_target, depth);
    VkRenderingInfo info{};
    info.sType = VK_STRUCTURE_TYPE_RENDERING_INFO;
    info.renderArea = to_rect(pass.area);
    info.layerCount = desc.layers;
    info.colorAttachmentCount = static_cast<std::uint32_t>(desc.colors.size());
    info.pColorAttachments = pass.colors.data();
    info.pDepthAttachment = has_depth(depth_format) ? &depth : nullptr;
    info.pStencilAttachment = has_stencil(depth_format) ? &stencil : nullptr;
    cmd_begin_rendering(buffer, &info);
}

} // namespace

Commands::~Commands() {
    vkDestroyCommandPool(device_->handle(), pool_, nullptr);
}

Status Commands::open() {
    const VkResult reset = vkResetCommandPool(device_->handle(), pool_, 0);
    if (reset != VK_SUCCESS) return device_->failed(reset, "không đặt lại được command pool");
    VkCommandBufferBeginInfo info{};
    info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    info.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    const VkResult begun = vkBeginCommandBuffer(buffer_, &info);
    if (begun != VK_SUCCESS) return device_->failed(begun, "không mở được command buffer");
    state_ = State::kRecording;
    is_live_ = true;
    is_rendering_ = false;
    has_warned_ = false;
    open_labels_ = 0;
    error_ = ok();
    pipeline_ = {};
    bound_ = 0;
    if (queue_ != QueueType::kGraphics) return ok();
    // Giá trị đầu của trạng thái động, như nhau ở hai backend (Vulkan để chúng không xác định).
    const std::array<float, 4> constants{};
    vkCmdSetStencilReference(buffer_, VK_STENCIL_FACE_FRONT_AND_BACK, 0);
    vkCmdSetBlendConstants(buffer_, constants.data());
    if (device_->caps().depth_bounds) vkCmdSetDepthBounds(buffer_, 0.0F, 1.0F);
    return ok();
}

Status Commands::close() {
    if (state_ == State::kClosed) return error_;
    // Khác gốc: điều kiện có tên, để câu bảo vệ vẫn một dòng khi kRecording dài thêm.
    const bool is_recording = state_ == State::kRecording;
    if (!is_recording) return fail(kState, "command list không ở trạng thái đang ghi");
    if (is_rendering_) reject(fail(kState, "command list còn begin_rendering chưa đóng"));
    if (open_labels_ != 0) reject(fail(kState, "command list còn nhãn chưa đóng"));
    state_ = State::kClosed;
    is_live_ = false;
    if (!error_) return error_;
    const VkResult ended = vkEndCommandBuffer(buffer_);
    if (ended != VK_SUCCESS) error_ = device_->failed(ended, "không đóng được command buffer");
    return error_;
}

bool Commands::live() {
    if (is_live_) return true;
    const bool is_stale = state_ != State::kRecording && !has_warned_;
    if (is_stale) core::error("gpu: ghi lệnh vào command list đã nộp hoặc đã bị thu hồi");
    if (is_stale) has_warned_ = true;
    return false;
}

void Commands::reject(core::Failure failure) {
    is_live_ = false;
    if (error_) error_ = std::move(failure);
}

const Buffer* Commands::need(BufferHandle handle, BufferUsage usage, core::Message message) {
    const Buffer* const buffer = device_->find(handle);
    const bool is_usable = buffer != nullptr && has(buffer->usage, usage);
    if (is_usable) return buffer;
    reject(fail(kBad, message));
    return nullptr;
}

const Texture* Commands::need(TextureHandle handle, TextureUsage usage, core::Message message) {
    const Texture* const texture = device_->find(handle);
    const bool is_usable = texture != nullptr && has(texture->desc.usage, usage);
    if (is_usable) return texture;
    reject(fail(kBad, message));
    return nullptr;
}

const View* Commands::need(TextureViewHandle handle, core::Message message) {
    const View* const view = device_->find(handle);
    if (view == nullptr) reject(fail(kBad, message));
    return view;
}

const QueryPool* Commands::need(QueryPoolHandle handle, QueryKind kind, std::uint32_t first, std::uint32_t count) {
    const QueryPool* const pool = device_->find(handle);
    const bool is_known = pool != nullptr && pool->kind == kind;
    const bool is_inside = is_known && first < pool->count && count <= pool->count - first;
    if (is_inside) return pool;
    reject(fail(kBad, "truy vấn: pool đã chết, sai loại, hoặc ô nằm ngoài pool"));
    return nullptr;
}

// Offset, số lệnh rồi bước là thứ tự tham số của lệnh gián tiếp trong Vulkan; chữ ký do
// commands.hpp định (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
const Buffer* Commands::need_arguments(BufferHandle handle, std::uint64_t offset, std::uint32_t count,
    std::uint32_t stride, std::uint32_t size) {
    const Buffer* const buffer =
        need(handle, BufferUsage::kIndirect, "lệnh gián tiếp: buffer đã chết hoặc thiếu cờ Indirect");
    if (buffer == nullptr) return nullptr;
    const bool is_aligned = offset % 4 == 0 && stride % 4 == 0 && stride >= size;
    const std::uint64_t needed = (std::uint64_t{count - 1} * stride) + size;
    const bool is_inside = offset <= buffer->size && needed <= buffer->size - offset;
    if (is_aligned && is_inside) return buffer;
    reject(fail(kBad, "lệnh gián tiếp: tham số sai căn hoặc nằm ngoài buffer"));
    return nullptr;
}

bool Commands::can_draw() {
    if (!live()) return false;
    const bool is_graphics = pipeline_.point == VK_PIPELINE_BIND_POINT_GRAPHICS;
    const bool is_ready = is_rendering_ && pipeline_.handle != VK_NULL_HANDLE && is_graphics;
    if (!is_ready) reject(fail(kState, "vẽ: chưa begin_rendering hoặc chưa gắn pipeline đồ hoạ"));
    if (!is_ready) return false;
    const bool is_bound = (pipeline_.layout->used & ~bound_) == 0;
    if (!is_bound) reject(fail(kState, "vẽ: còn register space của pipeline chưa có nhóm gắn"));
    return is_bound;
}

bool Commands::can_dispatch() {
    if (!live()) return false;
    const bool is_compute = pipeline_.point == VK_PIPELINE_BIND_POINT_COMPUTE;
    const bool is_ready = !is_rendering_ && pipeline_.handle != VK_NULL_HANDLE && is_compute;
    if (!is_ready) reject(fail(kState, "dispatch: đang vẽ hoặc chưa gắn pipeline compute"));
    if (!is_ready) return false;
    const bool is_bound = (pipeline_.layout->used & ~bound_) == 0;
    if (!is_bound) reject(fail(kState, "dispatch: còn register space chưa có nhóm gắn"));
    return is_bound;
}

void Commands::set_label(VkDebugUtilsLabelEXT& label, std::string_view name) {
    label_.assign(name);
    label.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
    label.pLabelName = label_.c_str();
}

void Commands::begin_label(std::string_view name) {
    if (!live()) return;
    ++open_labels_;
    const DebugApi& debug = device_->debug();
    if (debug.begin_label == nullptr) return;
    VkDebugUtilsLabelEXT label{};
    set_label(label, name);
    debug.begin_label(buffer_, &label);
}

void Commands::end_label() {
    if (!live()) return;
    if (open_labels_ == 0) {
        reject(fail(kState, "end_label không có begin_label đi trước"));
        return;
    }
    --open_labels_;
    const DebugApi& debug = device_->debug();
    if (debug.end_label != nullptr) debug.end_label(buffer_);
}

void Commands::insert_label(std::string_view name) {
    if (!live()) return;
    const DebugApi& debug = device_->debug();
    if (debug.insert_label == nullptr) return;
    VkDebugUtilsLabelEXT label{};
    set_label(label, name);
    debug.insert_label(buffer_, &label);
}

void Commands::add_barrier(const BufferBarrier& item) {
    const Buffer* const buffer = need(item.buffer, BufferUsage::kNone, "barrier: buffer đã chết");
    if (buffer == nullptr) return;
    const Families moved = families(*device_, item.queue);
    VkBufferMemoryBarrier2 barrier{};
    barrier.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2;
    barrier.srcStageMask = to_vk(item.stage_before);
    barrier.srcAccessMask = to_vk(item.access_before);
    barrier.dstStageMask = to_vk(item.stage_after);
    barrier.dstAccessMask = to_vk(item.access_after);
    barrier.srcQueueFamilyIndex = moved.source;
    barrier.dstQueueFamilyIndex = moved.target;
    barrier.buffer = buffer->handle;
    barrier.size = VK_WHOLE_SIZE;
    buffer_barriers_.push_back(barrier);
}

void Commands::add_barrier(const TextureBarrier& item) {
    const Texture* const texture = need(item.texture, TextureUsage::kNone, "barrier: texture đã chết");
    if (texture == nullptr) return;
    const Families moved = families(*device_, item.queue);
    VkImageMemoryBarrier2 barrier{};
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2;
    barrier.srcStageMask = to_vk(item.stage_before);
    barrier.srcAccessMask = to_vk(item.access_before);
    barrier.dstStageMask = to_vk(item.stage_after);
    barrier.dstAccessMask = to_vk(item.access_after);
    barrier.oldLayout = to_vk(item.layout_before);
    barrier.newLayout = to_vk(item.layout_after);
    barrier.srcQueueFamilyIndex = moved.source;
    barrier.dstQueueFamilyIndex = moved.target;
    barrier.image = texture->handle;
    barrier.subresourceRange.aspectMask = aspect_of(texture->desc.format);
    barrier.subresourceRange.baseMipLevel = item.first_mip;
    barrier.subresourceRange.levelCount = item.mip_count;
    barrier.subresourceRange.baseArrayLayer = item.first_layer;
    barrier.subresourceRange.layerCount = item.layer_count;
    image_barriers_.push_back(barrier);
}

void Commands::barrier(std::span<const BufferBarrier> buffers, std::span<const TextureBarrier> textures,
    std::span<const GlobalBarrier> memory) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "barrier nằm trong begin_rendering"));
        return;
    }
    buffer_barriers_.clear();
    image_barriers_.clear();
    memory_barriers_.clear();
    for (const BufferBarrier& item : buffers) {
        add_barrier(item);
    }
    for (const TextureBarrier& item : textures) {
        add_barrier(item);
    }
    for (const GlobalBarrier& item : memory) {
        memory_barriers_.push_back(global_barrier(item));
    }
    const bool is_empty = buffers.empty() && textures.empty() && memory.empty();
    if (!is_live_ || is_empty) return;
    VkDependencyInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO;
    info.memoryBarrierCount = static_cast<std::uint32_t>(memory_barriers_.size());
    info.pMemoryBarriers = memory_barriers_.data();
    info.bufferMemoryBarrierCount = static_cast<std::uint32_t>(buffer_barriers_.size());
    info.pBufferMemoryBarriers = buffer_barriers_.data();
    info.imageMemoryBarrierCount = static_cast<std::uint32_t>(image_barriers_.size());
    info.pImageMemoryBarriers = image_barriers_.data();
    cmd_pipeline_barrier2(buffer_, &info);
}

void Commands::note_extent(const View& view) noexcept {
    if (extent_.width != 0) return;
    extent_ = {.width = view.width, .height = view.height};
}

// false khi view của target đã chết hay không dùng được (lỗi đã được giữ lại). Tay nắm rỗng là ô
// attachment bỏ trống, hợp lệ.
bool Commands::fill_color(VkRenderingAttachmentInfo& info, const ColorTarget& target) {
    info.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO;
    if (!target.view) return true;
    const View* const view = need(target.view, "begin_rendering: view màu đã chết");
    if (view == nullptr) return false;
    const Format format = view->range.format;
    if (has_depth(format)) reject(fail(kBad, "begin_rendering: view độ sâu ở ô attachment màu"));
    info.imageView = view->handle;
    info.imageLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    info.loadOp = to_vk(target.load);
    info.storeOp = to_vk(target.store);
    info.clearValue = clear_color(target.clear, format);
    note_extent(*view);
    if (!target.resolve) return is_live_;
    const View* const resolved = need(target.resolve, "begin_rendering: view resolve đã chết");
    if (resolved == nullptr) return false;
    const bool is_resolvable = view->samples > 1 && resolved->samples == 1;
    if (!is_resolvable) reject(fail(kBad, "resolve cần nguồn đa mẫu và đích một mẫu"));
    // Định dạng số nguyên không lấy trung bình được: lấy mẫu số 0.
    const bool is_integer = is_uint(format) || is_sint(format);
    info.resolveMode = is_integer ? VK_RESOLVE_MODE_SAMPLE_ZERO_BIT : VK_RESOLVE_MODE_AVERAGE_BIT;
    info.resolveImageView = resolved->handle;
    info.resolveImageLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    return is_live_;
}

const View* Commands::need_depth(TextureViewHandle handle) {
    const View* const view = need(handle, "begin_rendering: view độ sâu đã chết");
    if (view == nullptr) return nullptr;
    const bool is_depth = has_depth(view->range.format);
    if (!is_depth) reject(fail(kBad, "begin_rendering: view màu ở ô attachment độ sâu"));
    return is_depth ? view : nullptr;
}

void Commands::begin_rendering(const RenderingDesc& desc) {
    if (!live()) return;
    const bool is_free = !is_rendering_ && queue_ == QueueType::kGraphics;
    if (!is_free) {
        reject(fail(kState, "begin_rendering lồng nhau hoặc ngoài hàng Graphics"));
        return;
    }
    if (!is_valid_pass(desc)) {
        reject(fail(kBad, "begin_rendering: số attachment hoặc số lớp sai"));
        return;
    }
    extent_ = {};
    std::array<VkRenderingAttachmentInfo, kMaxColorTargets> colors{};
    const auto fill = [&](std::size_t index) {
        return fill_color(colors.at(index), desc.colors.subspan(index, 1).front());
    };
    if (!run_each(desc.colors.size(), fill)) return;
    const DepthTarget depth_target = desc.depth.value_or(DepthTarget{});
    const View* const depth_view = desc.depth ? need_depth(depth_target.view) : nullptr;
    if (desc.depth && depth_view == nullptr) return;
    // Khác gốc: gốc dựng attachment độ sâu rồi mới ghi cỡ; phần dựng nay ở begin_pass, thuần tính
    // toán, nên thứ tự giữa hai việc không đổi kết quả.
    if (depth_view != nullptr) note_extent(*depth_view);
    const Scissor area = area_of(desc.area, extent_);
    const Pass pass{.colors = colors, .depth_view = depth_view, .area = area};
    begin_pass(buffer_, desc, pass);
    is_rendering_ = true;
    // Viewport và scissor phủ trọn vùng vẽ; chỗ gọi đặt lại khi cần vùng khác.
    const auto left = static_cast<float>(area.x);
    const auto top = static_cast<float>(area.y);
    const auto width = static_cast<float>(area.width);
    const auto height = static_cast<float>(area.height);
    const Viewport whole{.x = left, .y = top, .width = width, .height = height};
    const VkViewport viewport = to_viewport(whole);
    const VkRect2D rect = to_rect(area);
    vkCmdSetViewport(buffer_, 0, 1, &viewport);
    vkCmdSetScissor(buffer_, 0, 1, &rect);
}

void Commands::end_rendering() {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "end_rendering không có begin_rendering"));
        return;
    }
    cmd_end_rendering(buffer_);
    is_rendering_ = false;
}

void Commands::set_viewport(const Viewport& viewport) {
    if (!live()) return;
    const VkViewport flipped = to_viewport(viewport);
    vkCmdSetViewport(buffer_, 0, 1, &flipped);
}

void Commands::set_scissor(const Scissor& scissor) {
    if (!live()) return;
    const VkRect2D rect = to_rect(scissor);
    vkCmdSetScissor(buffer_, 0, 1, &rect);
}

void Commands::set_stencil_reference(std::uint32_t value) {
    if (!live()) return;
    vkCmdSetStencilReference(buffer_, VK_STENCIL_FACE_FRONT_AND_BACK, value);
}

void Commands::set_blend_constants(const ClearColor& color) {
    if (!live()) return;
    const std::array<float, 4> constants{color.red, color.green, color.blue, color.alpha};
    vkCmdSetBlendConstants(buffer_, constants.data());
}

void Commands::set_depth_bounds(float nearest, float farthest) {
    if (!live()) return;
    const bool is_valid = device_->caps().depth_bounds && nearest <= farthest;
    if (!is_valid) {
        reject(fail(kBad, "set_depth_bounds: thiết bị thiếu hoặc khoảng ngược"));
        return;
    }
    vkCmdSetDepthBounds(buffer_, nearest, farthest);
}

void Commands::bind_pipeline(PipelineHandle pipeline) {
    if (!live()) return;
    const Pipeline* const found = device_->find(pipeline);
    if (found == nullptr) {
        reject(fail(kBad, "bind_pipeline: pipeline đã chết"));
        return;
    }
    // Hàng Copy không chạy pipeline nào; hàng Compute chỉ chạy pipeline compute.
    const bool is_compute = found->point == VK_PIPELINE_BIND_POINT_COMPUTE;
    const bool is_allowed = queue_ == QueueType::kGraphics || (queue_ == QueueType::kCompute && is_compute);
    if (!is_allowed) {
        reject(fail(kBad, "bind_pipeline: sai hàng đợi cho pipeline này"));
        return;
    }
    // Nhóm đã gắn chỉ còn hiệu lực khi bố cục không đổi.
    if (found->layout != pipeline_.layout) bound_ = 0;
    pipeline_ = *found;
    vkCmdBindPipeline(buffer_, pipeline_.point, pipeline_.handle);
}

void Commands::bind_group(std::uint32_t space, BindGroupHandle group) {
    if (!live()) return;
    const BindGroup* const found = device_->find(group);
    const bool has_pipeline = pipeline_.handle != VK_NULL_HANDLE;
    const bool is_usable = found != nullptr && has_pipeline && space < kMaxBindGroups;
    if (!is_usable) {
        reject(fail(kBad, "bind_group: nhóm chết, thiếu pipeline, sai space"));
        return;
    }
    const SpaceLayout& wanted = pipeline_.layout->program.spaces.at(space);
    const SpaceLayout& given = found->layout->program.spaces.at(found->space);
    const bool is_matching = !wanted.resources.empty() && wanted.hash == given.hash;
    if (!is_matching) {
        reject(fail(kBad, "bind_group: nhóm không khớp bố cục của pipeline"));
        return;
    }
    auto* const layout = pipeline_.layout->handle;
    vkCmdBindDescriptorSets(buffer_, pipeline_.point, layout, space, 1, &found->set, 0, nullptr);
    bound_ |= 1U << space;
}

void Commands::push_constants(std::span<const std::byte> data, std::uint32_t offset) {
    if (!live()) return;
    const bool has_pipeline = pipeline_.handle != VK_NULL_HANDLE;
    if (!has_pipeline) {
        reject(fail(kState, "push_constants: thiếu pipeline"));
        return;
    }
    const std::uint32_t limit = pipeline_.layout->program.push_bytes;
    const bool is_aligned = offset % 4 == 0 && data.size() % 4 == 0 && !data.empty();
    const bool is_inside = offset <= limit && data.size() <= limit - offset;
    const bool is_valid = is_aligned && is_inside;
    if (!is_valid) {
        reject(fail(kBad, "push_constants: sai căn hoặc vượt khối của shader"));
        return;
    }
    const auto size = static_cast<std::uint32_t>(data.size());
    const VkShaderStageFlags stages = pipeline_.layout->push_stages;
    vkCmdPushConstants(buffer_, pipeline_.layout->handle, stages, offset, size, data.data());
}

void Commands::bind_vertex_buffer(std::uint32_t slot, BufferHandle buffer, std::uint64_t offset) {
    if (!live()) return;
    const Buffer* const found =
        need(buffer, BufferUsage::kVertex, "bind_vertex_buffer: buffer đã chết hoặc thiếu cờ Vertex");
    if (found == nullptr) return;
    const bool is_valid = slot < kMaxVertexBuffers && offset <= found->size;
    if (!is_valid) {
        reject(fail(kBad, "bind_vertex_buffer: khe hoặc offset ngoài miền"));
        return;
    }
    vkCmdBindVertexBuffers(buffer_, slot, 1, &found->handle, &offset);
}

void Commands::bind_index_buffer(BufferHandle buffer, IndexType type, std::uint64_t offset) {
    if (!live()) return;
    const Buffer* const found =
        need(buffer, BufferUsage::kIndex, "bind_index_buffer: buffer đã chết hoặc thiếu cờ Index");
    if (found == nullptr) return;
    if (offset > found->size) {
        reject(fail(kBad, "bind_index_buffer: offset ngoài buffer"));
        return;
    }
    vkCmdBindIndexBuffer(buffer_, found->handle, offset, to_vk(type));
}

void Commands::draw(const DrawArguments& arguments) {
    if (!can_draw()) return;
    vkCmdDraw(buffer_, arguments.vertex_count, arguments.instance_count, arguments.first_vertex,
        arguments.first_instance);
}

void Commands::draw_indexed(const DrawIndexedArguments& arguments) {
    if (!can_draw()) return;
    vkCmdDrawIndexed(buffer_, arguments.index_count, arguments.instance_count, arguments.first_index,
        arguments.vertex_offset, arguments.first_instance);
}

void Commands::draw_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count, std::uint32_t stride) {
    if (count == 0 || !can_draw()) return;
    const Buffer* const buffer = need_arguments(arguments, offset, count, stride, sizeof(DrawArguments));
    if (buffer == nullptr) return;
    const bool is_batched = count == 1 || device_->traits().multi_draw;
    if (is_batched) {
        vkCmdDrawIndirect(buffer_, buffer->handle, offset, count, stride);
        return;
    }
    // Thiết bị không gộp được nhiều lệnh gián tiếp: gọi từng lệnh.
    for (std::uint32_t index = 0; index < count; ++index) {
        const std::uint64_t position = offset + (std::uint64_t{index} * stride);
        vkCmdDrawIndirect(buffer_, buffer->handle, position, 1, stride);
    }
}

void Commands::draw_indexed_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count,
    std::uint32_t stride) {
    if (count == 0 || !can_draw()) return;
    const Buffer* const buffer = need_arguments(arguments, offset, count, stride, sizeof(DrawIndexedArguments));
    if (buffer == nullptr) return;
    const bool is_batched = count == 1 || device_->traits().multi_draw;
    if (is_batched) {
        vkCmdDrawIndexedIndirect(buffer_, buffer->handle, offset, count, stride);
        return;
    }
    for (std::uint32_t index = 0; index < count; ++index) {
        const std::uint64_t position = offset + (std::uint64_t{index} * stride);
        vkCmdDrawIndexedIndirect(buffer_, buffer->handle, position, 1, stride);
    }
}

void Commands::dispatch(const DispatchArguments& arguments) {
    if (!can_dispatch()) return;
    vkCmdDispatch(buffer_, arguments.x, arguments.y, arguments.z);
}

void Commands::dispatch_indirect(BufferHandle arguments, std::uint64_t offset) {
    if (!can_dispatch()) return;
    const std::uint32_t size = sizeof(DispatchArguments);
    const Buffer* const buffer = need_arguments(arguments, offset, 1, size, size);
    if (buffer != nullptr) vkCmdDispatchIndirect(buffer_, buffer->handle, offset);
}

// Nguồn rồi đích là thứ tự quen của mọi lệnh chép; chữ ký do gpu::CommandList định (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void Commands::copy_buffer(BufferHandle source, BufferHandle target, const BufferCopy& region) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Buffer* const from =
        need(source, BufferUsage::kCopySource, "copy_buffer: nguồn đã chết hoặc thiếu cờ CopySource");
    const Buffer* const destination =
        need(target, BufferUsage::kCopyDest, "copy_buffer: đích đã chết hoặc thiếu cờ CopyDest");
    if (from == nullptr || destination == nullptr) return;
    const Status taken = check_span(from->size, region.source_offset, region.size);
    const Status placed = check_span(destination->size, region.target_offset, region.size);
    const bool is_valid = taken && placed && region.size != 0;
    if (!is_valid) {
        reject(fail(kBad, "copy_buffer: khoảng rỗng hoặc vượt biên buffer"));
        return;
    }
    const VkBufferCopy copy{.srcOffset = region.source_offset, .dstOffset = region.target_offset, .size = region.size};
    vkCmdCopyBuffer(buffer_, from->handle, destination->handle, 1, &copy);
}

// Nguồn rồi đích, như copy_buffer; chữ ký do gpu::CommandList định (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void Commands::copy_texture(TextureHandle source, TextureHandle target, const TextureCopy& region) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Texture* const from =
        need(source, TextureUsage::kCopySource, "copy_texture: nguồn đã chết hoặc thiếu cờ CopySource");
    const Texture* const destination =
        need(target, TextureUsage::kCopyDest, "copy_texture: đích đã chết hoặc thiếu cờ CopyDest");
    if (from == nullptr || destination == nullptr) return;
    const core::Result<TextureCopy> resolved = resolve_copy(region, from->desc, destination->desc);
    if (!resolved) {
        reject(std::unexpected(resolved.error()));
        return;
    }
    const VkImageCopy copy = to_copy(*resolved, from->desc.format);
    vkCmdCopyImage(buffer_, from->handle, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination->handle,
        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copy);
}

// Dựng regions_ cho một lệnh chép giữa buffer và texture; false khi một vùng sai (lỗi đã được giữ)
// hoặc không có vùng nào.
bool Commands::fill_regions(const Buffer& buffer, const Texture& texture, std::span<const BufferTextureCopy> regions) {
    regions_.clear();
    // Khác gốc: gốc là vòng for có hai câu if (!resolved) trong thân; ở đây điều kiện dừng lên điều
    // kiện lặp, cùng thứ tự duyệt, và lỗi của vùng sai đầu tiên được giữ ngay sau vòng lặp.
    const auto add = [&](const CopyRegion& resolved) { regions_.push_back(to_copy(resolved, texture.desc.format)); };
    Status added = ok();
    for (auto region = regions.begin(); region != regions.end() && added; ++region) {
        added = resolve_copy(*region, texture.desc, buffer.size).transform(add);
    }
    if (!added) reject(std::unexpected(added.error()));
    if (!added) return false;
    return !regions_.empty();
}

void Commands::copy_buffer_to_texture(BufferHandle source, TextureHandle target,
    std::span<const BufferTextureCopy> regions) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Buffer* const from =
        need(source, BufferUsage::kCopySource, "chép vào texture: buffer chết hoặc thiếu CopySource");
    const Texture* const destination =
        need(target, TextureUsage::kCopyDest, "chép vào texture: texture chết hoặc thiếu CopyDest");
    if (from == nullptr || destination == nullptr) return;
    if (!fill_regions(*from, *destination, regions)) return;
    const auto count = static_cast<std::uint32_t>(regions_.size());
    vkCmdCopyBufferToImage(buffer_, from->handle, destination->handle, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, count,
        regions_.data());
}

void Commands::copy_texture_to_buffer(TextureHandle source, BufferHandle target,
    std::span<const BufferTextureCopy> regions) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Texture* const from =
        need(source, TextureUsage::kCopySource, "chép ra buffer: texture chết hoặc thiếu CopySource");
    const Buffer* const destination =
        need(target, BufferUsage::kCopyDest, "chép ra buffer: buffer chết hoặc thiếu CopyDest");
    if (from == nullptr || destination == nullptr) return;
    if (!fill_regions(*destination, *from, regions)) return;
    const auto count = static_cast<std::uint32_t>(regions_.size());
    vkCmdCopyImageToBuffer(buffer_, from->handle, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination->handle, count,
        regions_.data());
}

void Commands::reset_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "reset_queries nằm trong begin_rendering"));
        return;
    }
    const QueryPool* const known = device_->find(pool);
    const QueryKind kind = known == nullptr ? QueryKind::kTimestamp : known->kind;
    const QueryPool* const checked = need(pool, kind, first, count);
    if (checked != nullptr) vkCmdResetQueryPool(buffer_, checked->handle, first, count);
}

void Commands::write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) {
    if (!live()) return;
    const QueryPool* const checked = need(pool, QueryKind::kTimestamp, index, 1);
    if (checked == nullptr) return;
    // Một dấu thời gian gắn với đúng một giai đoạn (None là đầu đường ống).
    const bool is_single = std::popcount(std::to_underlying(stage)) <= 1;
    const bool is_valid = is_single && checked->queue == queue_;
    if (!is_valid) {
        reject(fail(kBad, "write_timestamp: nhiều giai đoạn hoặc sai hàng đợi"));
        return;
    }
    cmd_write_timestamp2(buffer_, to_vk(stage), checked->handle, index);
}

void Commands::begin_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "begin_occlusion nằm ngoài begin_rendering"));
        return;
    }
    const QueryPool* const checked = need(pool, QueryKind::kOcclusion, index, 1);
    if (checked == nullptr) return;
    const bool is_precise = device_->caps().precise_occlusion;
    const VkQueryControlFlags flags = is_precise ? VK_QUERY_CONTROL_PRECISE_BIT : 0;
    vkCmdBeginQuery(buffer_, checked->handle, index, flags);
}

void Commands::end_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    const QueryPool* const checked = need(pool, QueryKind::kOcclusion, index, 1);
    if (checked != nullptr) vkCmdEndQuery(buffer_, checked->handle, index);
}

// Vulkan đọc thẳng từ query pool nên không có gì để chốt; chỉ kiểm tay nắm để lỗi dùng sai giống
// backend D3D12.
void Commands::resolve_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) {
    if (!live()) return;
    const QueryPool* const known = device_->find(pool);
    const QueryKind kind = known == nullptr ? QueryKind::kTimestamp : known->kind;
    std::ignore = need(pool, kind, first, count);
}

} // namespace game::gpu::vulkan
