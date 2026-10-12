// Ghi lệnh D3D12. Viewport giữ nguyên trục: NDC Y hướng lên là mặc định của API này, khác Vulkan.
// Nguồn: Forge2 src/gpu/d3d12/commands.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân vòng
// lồng tách hàm hoặc đưa điều kiện dừng lên for; return reject trong hàm void thành gọi rồi return;
// aggregate ghi tên trường; include trực tiếp header của mọi tên dùng tới.
#include "gpu/d3d12/commands.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "gpu/barrier.hpp"
#include "gpu/check.hpp"
#include "gpu/command.hpp"
#include "gpu/d3d12/convert.hpp"
#include "gpu/d3d12/device.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <basetsd.h>
#include <d3d12.h>
#include <winerror.h>
#include <winnt.h>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <mutex>
#include <optional>
#include <span>
#include <string_view>
#include <utility>

namespace game::gpu::d3d12 {

// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access): barrier và copy location của
// D3D12 là union có thẻ; API không có dạng khác.

using core::ErrorCode;
using core::fail;
using core::ok;

using List7 = ID3D12GraphicsCommandList7;
using CpuHandle = D3D12_CPU_DESCRIPTOR_HANDLE;
using GpuHandle = D3D12_GPU_DESCRIPTOR_HANDLE;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kState = ErrorCode::kInvalidState;

namespace {

static_assert(sizeof(DrawArguments) == sizeof(D3D12_DRAW_ARGUMENTS));
static_assert(sizeof(DrawIndexedArguments) == sizeof(D3D12_DRAW_INDEXED_ARGUMENTS));
static_assert(sizeof(DispatchArguments) == sizeof(D3D12_DISPATCH_ARGUMENTS));

[[nodiscard]] UINT mip_span(const TextureDesc& desc, std::uint32_t first, std::uint32_t count) {
    if (count == kAllMips) return desc.mip_levels - first;
    return count;
}

[[nodiscard]] UINT layer_span(const TextureDesc& desc, std::uint32_t first, std::uint32_t count) {
    if (count == kAllLayers) return layer_count(desc) - first;
    return count;
}

[[nodiscard]] UINT planes_of(Format format) noexcept {
    if (has_stencil(format)) return 2;
    return 1;
}

[[nodiscard]] UINT subresource(UINT mip, UINT layer, UINT mips) noexcept {
    return mip + (layer * mips);
}

[[nodiscard]] D3D12_BARRIER_SUBRESOURCE_RANGE whole(const Texture& texture, const TextureBarrier& item) {
    D3D12_BARRIER_SUBRESOURCE_RANGE range{};
    range.IndexOrFirstMipLevel = item.first_mip;
    range.NumMipLevels = mip_span(texture.desc, item.first_mip, item.mip_count);
    range.FirstArraySlice = item.first_layer;
    range.NumArraySlices = layer_span(texture.desc, item.first_layer, item.layer_count);
    range.FirstPlane = 0;
    range.NumPlanes = planes_of(texture.desc.format);
    return range;
}

void emit_barrier(List7* list, const D3D12_BUFFER_BARRIER& barrier) {
    D3D12_BARRIER_GROUP group{};
    group.Type = D3D12_BARRIER_TYPE_BUFFER;
    group.NumBarriers = 1;
    group.pBufferBarriers = &barrier;
    list->Barrier(1, &group);
}

void emit_barrier(List7* list, const D3D12_TEXTURE_BARRIER& barrier) {
    D3D12_BARRIER_GROUP group{};
    group.Type = D3D12_BARRIER_TYPE_TEXTURE;
    group.NumBarriers = 1;
    group.pTextureBarriers = &barrier;
    list->Barrier(1, &group);
}

struct BufferImage {
    const Buffer* buffer = nullptr;
    const Texture* texture = nullptr;
    bool to_texture = false;
};

void copy_one(List7* list, const BufferImage& pair, const CopyRegion& region, UINT layer) {
    const std::uint64_t slice = std::uint64_t{region.rows} * region.row_bytes;
    D3D12_TEXTURE_COPY_LOCATION footprint{};
    footprint.pResource = pair.buffer->resource.Get();
    footprint.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
    const std::uint64_t layer_bytes = std::uint64_t{layer} * slice;
    footprint.PlacedFootprint.Offset = region.buffer_offset + layer_bytes;
    footprint.PlacedFootprint.Footprint.Format = to_dxgi(pair.texture->desc.format);
    footprint.PlacedFootprint.Footprint.Width = region.width;
    footprint.PlacedFootprint.Footprint.Height = region.height;
    footprint.PlacedFootprint.Footprint.Depth = region.depth;
    footprint.PlacedFootprint.Footprint.RowPitch = region.row_bytes;
    D3D12_TEXTURE_COPY_LOCATION image{};
    image.pResource = pair.texture->resource.Get();
    image.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    const UINT mip = region.mip;
    const UINT array_layer = region.first_layer + layer;
    const UINT mips = pair.texture->desc.mip_levels;
    image.SubresourceIndex = subresource(mip, array_layer, mips);
    if (pair.to_texture) {
        list->CopyTextureRegion(&image, region.x, region.y, region.z, &footprint, nullptr);
    }
    if (!pair.to_texture) list->CopyTextureRegion(&footprint, 0, 0, 0, &image, nullptr);
}

void copy_layers(List7* list, const BufferImage& pair, const CopyRegion& region) {
    for (UINT layer = 0; layer < region.layer_count; ++layer) {
        copy_one(list, pair, region, layer);
    }
}

struct QueryStamp {
    std::uint32_t first = 0;
    std::uint32_t count = 0;
    std::uint64_t value = 0;
};

void stamp_pool(QueryPool& pool, const QueryStamp& stamp) {
    const std::scoped_lock lock(*pool.mutex);
    for (std::uint32_t index = 0; index < stamp.count; ++index) {
        const std::size_t slot = stamp.first + index;
        pool.ready_at.at(slot) = stamp.value;
    }
}

void stamp_use(D3d12Device& device, QueryPoolHandle pool, const QueryStamp& stamp) {
    QueryPool* const found = device.find(pool);
    if (found == nullptr) return;
    stamp_pool(*found, stamp);
}

struct Subresource {
    UINT mip = 0;
    UINT layer = 0;
};

[[nodiscard]] D3D12_BARRIER_SUBRESOURCE_RANGE one_slice(Subresource where) noexcept {
    D3D12_BARRIER_SUBRESOURCE_RANGE range{};
    range.IndexOrFirstMipLevel = where.mip;
    range.NumMipLevels = 1;
    range.FirstArraySlice = where.layer;
    range.NumArraySlices = 1;
    range.FirstPlane = 0;
    range.NumPlanes = 1;
    return range;
}

struct SliceChange {
    ID3D12Resource* resource = nullptr;
    UINT mip = 0;
    UINT layer = 0;
    D3D12_BARRIER_SYNC sync_before{};
    D3D12_BARRIER_SYNC sync_after{};
    D3D12_BARRIER_ACCESS access_before{};
    D3D12_BARRIER_ACCESS access_after{};
    D3D12_BARRIER_LAYOUT layout_before{};
    D3D12_BARRIER_LAYOUT layout_after{};
};

void texture_barrier(List7* list, const SliceChange& change) {
    D3D12_TEXTURE_BARRIER barrier{};
    barrier.SyncBefore = change.sync_before;
    barrier.SyncAfter = change.sync_after;
    barrier.AccessBefore = change.access_before;
    barrier.AccessAfter = change.access_after;
    barrier.LayoutBefore = change.layout_before;
    barrier.LayoutAfter = change.layout_after;
    barrier.pResource = change.resource;
    const Subresource where{.mip = change.mip, .layer = change.layer};
    barrier.Subresources = one_slice(where);
    emit_barrier(list, barrier);
}

[[nodiscard]] SliceChange color_to_source(ID3D12Resource* resource, Subresource where) {
    return SliceChange{.resource = resource,
        .mip = where.mip,
        .layer = where.layer,
        .sync_before = D3D12_BARRIER_SYNC_RENDER_TARGET,
        .sync_after = D3D12_BARRIER_SYNC_RESOLVE,
        .access_before = D3D12_BARRIER_ACCESS_RENDER_TARGET,
        .access_after = D3D12_BARRIER_ACCESS_RESOLVE_SOURCE,
        .layout_before = D3D12_BARRIER_LAYOUT_RENDER_TARGET,
        .layout_after = D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE};
}

[[nodiscard]] SliceChange color_to_dest(ID3D12Resource* resource, Subresource where) {
    return SliceChange{.resource = resource,
        .mip = where.mip,
        .layer = where.layer,
        .sync_before = D3D12_BARRIER_SYNC_RENDER_TARGET,
        .sync_after = D3D12_BARRIER_SYNC_RESOLVE,
        .access_before = D3D12_BARRIER_ACCESS_RENDER_TARGET,
        .access_after = D3D12_BARRIER_ACCESS_RESOLVE_DEST,
        .layout_before = D3D12_BARRIER_LAYOUT_RENDER_TARGET,
        .layout_after = D3D12_BARRIER_LAYOUT_RESOLVE_DEST};
}

[[nodiscard]] SliceChange source_to_color(ID3D12Resource* resource, Subresource where) {
    return SliceChange{.resource = resource,
        .mip = where.mip,
        .layer = where.layer,
        .sync_before = D3D12_BARRIER_SYNC_RESOLVE,
        .sync_after = D3D12_BARRIER_SYNC_RENDER_TARGET,
        .access_before = D3D12_BARRIER_ACCESS_RESOLVE_SOURCE,
        .access_after = D3D12_BARRIER_ACCESS_RENDER_TARGET,
        .layout_before = D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE,
        .layout_after = D3D12_BARRIER_LAYOUT_RENDER_TARGET};
}

[[nodiscard]] SliceChange dest_to_color(ID3D12Resource* resource, Subresource where) {
    return SliceChange{.resource = resource,
        .mip = where.mip,
        .layer = where.layer,
        .sync_before = D3D12_BARRIER_SYNC_RESOLVE,
        .sync_after = D3D12_BARRIER_SYNC_RENDER_TARGET,
        .access_before = D3D12_BARRIER_ACCESS_RESOLVE_DEST,
        .access_after = D3D12_BARRIER_ACCESS_RENDER_TARGET,
        .layout_before = D3D12_BARRIER_LAYOUT_RESOLVE_DEST,
        .layout_after = D3D12_BARRIER_LAYOUT_RENDER_TARGET};
}

struct PassGate {
    bool is_free = false;
    bool is_valid = false;
};

struct PassState {
    bool is_rendering = false;
    QueueType queue = QueueType::kGraphics;
    const RenderingDesc* desc = nullptr;
};

[[nodiscard]] PassGate pass_gate(const PassState& state) noexcept {
    PassGate gate;
    const RenderingDesc& desc = *state.desc;
    gate.is_free = !state.is_rendering && state.queue == QueueType::kGraphics;
    const bool is_empty = desc.colors.empty() && !desc.depth;
    const bool fits = desc.colors.size() <= kMaxColorTargets && desc.layers != 0;
    gate.is_valid = !is_empty && fits;
    return gate;
}

enum class DepthFault : std::uint8_t { kNone, kMissing, kNotDepth };

struct DepthPlan {
    DepthFault fault = DepthFault::kNone;
    const View* view = nullptr;
    bool is_read_only = false;
    bool should_clear = false;
    float clear_depth = 0.0F;
    UINT8 clear_stencil = 0;
};

[[nodiscard]] DepthPlan plan_depth(const D3d12Device& device, const RenderingDesc& desc) {
    DepthPlan plan;
    if (!desc.depth.has_value()) return plan;
    const DepthTarget& target = desc.depth.value();
    plan.view = device.find(target.view);
    if (plan.view == nullptr) {
        plan.fault = DepthFault::kMissing;
        return plan;
    }
    if (!has_depth(plan.view->range.format)) {
        plan.fault = DepthFault::kNotDepth;
        return plan;
    }
    plan.is_read_only = target.is_read_only;
    plan.should_clear = target.load == LoadOp::kClear;
    plan.clear_depth = target.clear.depth;
    plan.clear_stencil = static_cast<UINT8>(target.clear.stencil);
    return plan;
}

struct DepthBinding {
    CpuHandle handle{};
    bool is_bound = false;
    bool should_clear = false;
    float clear_depth = 0.0F;
    UINT8 clear_stencil = 0;
};

[[nodiscard]] DepthBinding depth_binding(const D3d12Device& device, const DepthPlan& plan) {
    DepthBinding binding;
    if (plan.view == nullptr) return binding;
    binding.is_bound = true;
    const UINT read_index = plan.view->dsv_read;
    const UINT draw_index = plan.view->dsv;
    const UINT index = plan.is_read_only ? read_index : draw_index;
    binding.handle = device.dsv_cpu(index);
    binding.should_clear = plan.should_clear;
    binding.clear_depth = plan.clear_depth;
    binding.clear_stencil = plan.clear_stencil;
    return binding;
}

template <class Reject>
[[nodiscard]] bool depth_failed(DepthFault fault, Reject reject_bad) {
    if (fault == DepthFault::kMissing) {
        reject_bad(kBad, "begin_rendering: view độ sâu đã chết");
        return true;
    }
    if (fault == DepthFault::kNotDepth) {
        reject_bad(kBad, "begin_rendering: view màu ở ô attachment độ sâu");
        return true;
    }
    return false;
}

template <class Paint>
[[nodiscard]] bool paint_colors(std::size_t count, Paint paint) {
    bool painted = true;
    // Khác gốc: điều kiện dừng nằm ở for (PH-01).
    for (std::size_t index = 0; index < count && painted; ++index) {
        const UINT slot = static_cast<UINT>(index);
        painted = paint(index, slot);
    }
    return painted;
}

[[nodiscard]] Scissor pass_area(const Scissor& area, UINT width, UINT height) noexcept {
    const bool is_whole = area.width == 0 || area.height == 0;
    if (!is_whole) return area;
    return Scissor{.x = 0, .y = 0, .width = width, .height = height};
}

void clear_color(List7* list, CpuHandle handle, const ColorTarget& target) {
    if (target.load != LoadOp::kClear) return;
    const std::array<float, 4> color{target.clear.red, target.clear.green, target.clear.blue, target.clear.alpha};
    const float* const channels = color.data();
    list->ClearRenderTargetView(handle, channels, 0, nullptr);
}

void clear_depth_if(List7* list, const DepthBinding& bound) {
    if (!bound.should_clear) return;
    list->ClearDepthStencilView(bound.handle, D3D12_CLEAR_FLAG_DEPTH, bound.clear_depth, bound.clear_stencil, 0,
        nullptr);
}

[[nodiscard]] bool is_resolvable_pair(const View& source, const View& resolved) noexcept {
    return source.samples > 1 && resolved.samples == 1;
}

[[nodiscard]] bool is_integer_format(Format format) noexcept {
    return is_uint(format) || is_sint(format);
}

[[nodiscard]] bool both_present(const Texture* source, const Texture* dest) noexcept {
    return source != nullptr && dest != nullptr;
}

void set_root_table(List7* list, bool is_compute, UINT root, GpuHandle gpu) {
    if (is_compute) list->SetComputeRootDescriptorTable(root, gpu);
    if (!is_compute) list->SetGraphicsRootDescriptorTable(root, gpu);
}

struct RootBind {
    List7* list = nullptr;
    bool is_compute = false;
    TableRef table{};
    UINT slot = 0;
};

[[nodiscard]] GpuHandle table_gpu(bool is_sampler, const D3d12Device& device, UINT slot) {
    if (is_sampler) return device.sampler_gpu(slot);
    return device.resource_gpu(slot);
}

void bind_table(const D3d12Device& device, const RootBind& bind, bool is_sampler) {
    if (bind.table.root == kNoDescriptor) return;
    const GpuHandle gpu = table_gpu(is_sampler, device, bind.slot);
    set_root_table(bind.list, bind.is_compute, bind.table.root, gpu);
}

struct RegionJob {
    List7* list = nullptr;
    const Buffer* buffer = nullptr;
    const Texture* texture = nullptr;
    bool to_texture = false;
};

[[nodiscard]] std::optional<core::Error> emit_copy(const RegionJob& job, const BufferTextureCopy& copy) {
    core::Result<CopyRegion> resolved = resolve_copy(copy, job.texture->desc, job.buffer->size);
    if (!resolved) return std::move(resolved.error());
    const CopyRegion region = *resolved;
    const BufferImage pair{.buffer = job.buffer, .texture = job.texture, .to_texture = job.to_texture};
    copy_layers(job.list, pair, region);
    return std::nullopt;
}

} // namespace

// Giữ trong họ make_*; sáu tham số chốt ở header (lệch API-03).
// NOLINTNEXTLINE(readability-convert-member-functions-to-static, readability-function-size)
Commands::Resolve Commands::make_resolve(const View& view, const View& resolved, const Texture& source,
    const Texture& dest, std::uint32_t layer, bool is_integer) const {
    Resolve item;
    item.source = source.resource.Get();
    item.target = dest.resource.Get();
    item.source_mip = view.range.first_mip;
    item.source_layer = view.range.first_layer + layer;
    item.target_mip = resolved.range.first_mip;
    item.target_layer = resolved.range.first_layer + layer;
    const UINT source_mips = source.desc.mip_levels;
    const UINT target_mips = dest.desc.mip_levels;
    item.source_subresource = subresource(item.source_mip, item.source_layer, source_mips);
    item.target_subresource = subresource(item.target_mip, item.target_layer, target_mips);
    item.format = to_dxgi(view.range.format);
    item.is_integer = is_integer;
    return item;
}

void Commands::resolve_item(const Resolve& item) {
    List7* const list = list_.Get();
    const Subresource source{.mip = item.source_mip, .layer = item.source_layer};
    const Subresource target{.mip = item.target_mip, .layer = item.target_layer};
    const SliceChange out_source = color_to_source(item.source, source);
    const SliceChange out_target = color_to_dest(item.target, target);
    texture_barrier(list, out_source);
    texture_barrier(list, out_target);
    list->ResolveSubresource(item.target, item.target_subresource, item.source, item.source_subresource, item.format);
    const SliceChange back_source = source_to_color(item.source, source);
    const SliceChange back_target = dest_to_color(item.target, target);
    texture_barrier(list, back_source);
    texture_barrier(list, back_target);
}

Status Commands::open() {
    const HRESULT reset = allocator_->Reset();
    if (FAILED(reset)) return device_->failed(reset, "không mở được command allocator");
    const HRESULT begun = list_->Reset(allocator_.Get(), nullptr);
    if (FAILED(begun)) return device_->failed(begun, "không mở được command list");
    state_ = State::kRecording;
    is_live_ = true;
    is_rendering_ = false;
    has_warned_ = false;
    open_labels_ = 0;
    error_ = ok();
    pipeline_ = {};
    bound_ = 0;
    extent_width_ = 0;
    extent_height_ = 0;
    resolves_.clear();
    queries_.clear();
    if (queue_ == QueueType::kCopy) return ok();
    const std::array heaps{device_->resource_heap(), device_->sampler_heap()};
    const UINT heap_count = static_cast<UINT>(heaps.size());
    list_->SetDescriptorHeaps(heap_count, heaps.data());
    const std::array<float, 4> constants{};
    list_->OMSetBlendFactor(constants.data());
    list_->OMSetStencilRef(0);
    if (device_->caps().depth_bounds) list_->OMSetDepthBounds(0.0F, 1.0F);
    return ok();
}

Status Commands::close() {
    if (state_ == State::kClosed) return error_;
    if (state_ != State::kRecording) {
        return fail(kState, "command list không ở trạng thái đang ghi");
    }
    if (is_rendering_) reject(fail(kState, "command list còn begin_rendering chưa đóng"));
    if (open_labels_ != 0) reject(fail(kState, "command list còn nhãn chưa đóng"));
    state_ = State::kClosed;
    is_live_ = false;
    const HRESULT closed = list_->Close();
    if (!error_) return error_;
    if (FAILED(closed)) error_ = device_->failed(closed, "không đóng được command list");
    return error_;
}

void Commands::stamp(std::uint64_t value) {
    for (const QueryUse& use : queries_) {
        const QueryStamp stamp{.first = use.first, .count = use.count, .value = value};
        stamp_use(*device_, use.pool, stamp);
    }
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

QueryPool* Commands::need_query(QueryPoolHandle handle, QueryKind kind, std::uint32_t first, std::uint32_t count) {
    QueryPool* const pool = device_->find(handle);
    const bool is_known = pool != nullptr && pool->kind == kind && pool->queue == queue_;
    const bool is_inside = is_known && first < pool->count && count <= pool->count - first;
    if (is_inside) return pool;
    reject(fail(kBad, "truy vấn: pool đã chết, sai hàng, hoặc ô nằm ngoài pool"));
    return nullptr;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký chốt ở header (lệch API-03)
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

bool Commands::is_bound() const noexcept {
    if (pipeline_.layout == nullptr) return false;
    return (pipeline_.layout->used & ~bound_) == 0;
}

bool Commands::can_draw() {
    if (!live()) return false;
    const bool is_ready = is_rendering_ && pipeline_.state != nullptr && !pipeline_.is_compute;
    if (!is_ready) reject(fail(kState, "vẽ: chưa begin_rendering hoặc chưa gắn pipeline đồ hoạ"));
    if (!is_ready) return false;
    if (!is_bound()) reject(fail(kState, "vẽ: còn register space của pipeline chưa có nhóm gắn"));
    return is_bound();
}

bool Commands::can_dispatch() {
    if (!live()) return false;
    const bool is_ready = !is_rendering_ && pipeline_.state != nullptr && pipeline_.is_compute;
    if (!is_ready) reject(fail(kState, "dispatch: đang vẽ hoặc chưa gắn pipeline compute"));
    if (!is_ready) return false;
    if (!is_bound()) reject(fail(kState, "dispatch: còn register space chưa có nhóm gắn"));
    return is_bound();
}

void Commands::begin_label(std::string_view name) {
    if (!live()) return;
    ++open_labels_;
    label_.assign(name);
    const UINT bytes = static_cast<UINT>(label_.size());
    list_->BeginEvent(0, label_.data(), bytes);
}

void Commands::end_label() {
    if (!live()) return;
    if (open_labels_ == 0) {
        reject(fail(kState, "end_label không có begin_label đi trước"));
        return;
    }
    --open_labels_;
    list_->EndEvent();
}

void Commands::insert_label(std::string_view name) {
    if (!live()) return;
    label_.assign(name);
    const UINT bytes = static_cast<UINT>(label_.size());
    list_->SetMarker(0, label_.data(), bytes);
}

void Commands::add_buffer(const BufferBarrier& item) {
    const Buffer* const buffer = need(item.buffer, BufferUsage::kNone, "barrier: buffer đã chết");
    if (buffer == nullptr) return;
    D3D12_BUFFER_BARRIER barrier{};
    barrier.SyncBefore = to_sync(item.stage_before);
    barrier.SyncAfter = to_sync(item.stage_after);
    barrier.AccessBefore = to_access(item.access_before);
    barrier.AccessAfter = to_access(item.access_after);
    barrier.pResource = buffer->resource.Get();
    barrier.Offset = 0;
    barrier.Size = UINT64_MAX;
    buffer_barriers_.push_back(barrier);
}

void Commands::add_texture(const TextureBarrier& item) {
    const Texture* const texture = need(item.texture, TextureUsage::kNone, "barrier: texture đã chết");
    if (texture == nullptr) return;
    D3D12_TEXTURE_BARRIER barrier{};
    barrier.SyncBefore = to_sync(item.stage_before);
    barrier.SyncAfter = to_sync(item.stage_after);
    barrier.AccessBefore = to_access(item.access_before);
    barrier.AccessAfter = to_access(item.access_after);
    barrier.LayoutBefore = to_layout(item.layout_before, queue_);
    barrier.LayoutAfter = to_layout(item.layout_after, queue_);
    barrier.pResource = texture->resource.Get();
    barrier.Subresources = whole(*texture, item);
    barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;
    texture_barriers_.push_back(barrier);
}

void Commands::add_global(const GlobalBarrier& item) {
    D3D12_GLOBAL_BARRIER barrier{};
    barrier.SyncBefore = to_sync(item.stage_before);
    barrier.SyncAfter = to_sync(item.stage_after);
    barrier.AccessBefore = to_access(item.access_before);
    barrier.AccessAfter = to_access(item.access_after);
    global_barriers_.push_back(barrier);
}

void Commands::flush_barriers() {
    std::array<D3D12_BARRIER_GROUP, 3> groups{};
    UINT count = 0;
    if (!global_barriers_.empty()) {
        groups.at(count).Type = D3D12_BARRIER_TYPE_GLOBAL;
        groups.at(count).NumBarriers = static_cast<UINT32>(global_barriers_.size());
        groups.at(count).pGlobalBarriers = global_barriers_.data();
        ++count;
    }
    if (!buffer_barriers_.empty()) {
        groups.at(count).Type = D3D12_BARRIER_TYPE_BUFFER;
        groups.at(count).NumBarriers = static_cast<UINT32>(buffer_barriers_.size());
        groups.at(count).pBufferBarriers = buffer_barriers_.data();
        ++count;
    }
    if (!texture_barriers_.empty()) {
        groups.at(count).Type = D3D12_BARRIER_TYPE_TEXTURE;
        groups.at(count).NumBarriers = static_cast<UINT32>(texture_barriers_.size());
        groups.at(count).pTextureBarriers = texture_barriers_.data();
        ++count;
    }
    if (count == 0 || !is_live_) return;
    list_->Barrier(count, groups.data());
}

void Commands::barrier(BufferBarriers buffers, TextureBarriers textures, GlobalBarriers memory) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "barrier nằm trong begin_rendering"));
        return;
    }
    buffer_barriers_.clear();
    texture_barriers_.clear();
    global_barriers_.clear();
    for (const BufferBarrier& item : buffers) {
        add_buffer(item);
    }
    for (const TextureBarrier& item : textures) {
        add_texture(item);
    }
    for (const GlobalBarrier& item : memory) {
        add_global(item);
    }
    const bool is_empty = buffers.empty() && textures.empty() && memory.empty();
    if (is_empty) return;
    flush_barriers();
}

void Commands::note_extent(const View& view) noexcept {
    if (extent_width_ != 0) return;
    extent_width_ = view.width;
    extent_height_ = view.height;
}

bool Commands::fill_color(const ColorTarget& target, UINT slot) {
    if (!target.view) {
        reject(fail(kBad, "begin_rendering: attachment màu trống"));
        return false;
    }
    const View* const view = need(target.view, "begin_rendering: view màu đã chết");
    if (view == nullptr) return false;
    if (has_depth(view->range.format)) {
        reject(fail(kBad, "begin_rendering: view độ sâu ở ô attachment màu"));
        return false;
    }
    const CpuHandle handle = device_->rtv_cpu(view->rtv);
    colors_.at(slot) = handle;
    note_extent(*view);
    List7* const list = list_.Get();
    clear_color(list, handle, target);
    if (!target.resolve) return true;
    const View* const resolved = need(target.resolve, "begin_rendering: view resolve đã chết");
    if (resolved == nullptr) return false;
    if (!is_resolvable_pair(*view, *resolved)) {
        reject(fail(kBad, "resolve cần nguồn đa mẫu và đích một mẫu"));
        return false;
    }
    const Texture* const source = device_->find(view->texture);
    const Texture* const dest = device_->find(resolved->texture);
    if (!both_present(source, dest)) return false;
    const bool is_integer = is_integer_format(view->range.format);
    for (std::uint32_t layer = 0; layer < view->range.layer_count; ++layer) {
        const Resolve made = make_resolve(*view, *resolved, *source, *dest, layer, is_integer);
        resolves_.push_back(made);
    }
    return true;
}

void Commands::apply_area(const Scissor& area) {
    const auto left = static_cast<float>(area.x);
    const auto top = static_cast<float>(area.y);
    const auto width = static_cast<float>(area.width);
    const auto height = static_cast<float>(area.height);
    const D3D12_VIEWPORT viewport{
        .TopLeftX = left, .TopLeftY = top, .Width = width, .Height = height, .MinDepth = 0.0F, .MaxDepth = 1.0F};
    const auto right = area.x + static_cast<LONG>(area.width);
    const auto bottom = area.y + static_cast<LONG>(area.height);
    const D3D12_RECT rect{.left = area.x, .top = area.y, .right = right, .bottom = bottom};
    list_->RSSetViewports(1, &viewport);
    list_->RSSetScissorRects(1, &rect);
}

void Commands::begin_rendering(const RenderingDesc& desc) {
    if (!live()) return;
    const PassState state{.is_rendering = is_rendering_, .queue = queue_, .desc = &desc};
    const PassGate gate = pass_gate(state);
    if (!gate.is_free) {
        reject(fail(kState, "begin_rendering lồng nhau hoặc ngoài hàng Graphics"));
        return;
    }
    if (!gate.is_valid) {
        reject(fail(kBad, "begin_rendering: số attachment hoặc số lớp sai"));
        return;
    }
    extent_width_ = 0;
    extent_height_ = 0;
    const CpuHandle empty{};
    colors_.assign(desc.colors.size(), empty);
    resolves_.clear();
    const auto paint = [this, &desc](std::size_t index, UINT slot) { return fill_color(desc.colors[index], slot); };
    if (!paint_colors(desc.colors.size(), paint)) return;
    const DepthPlan depth = plan_depth(*device_, desc);
    const auto reject_bad = [this](ErrorCode code, core::Message message) { reject(fail(code, message)); };
    if (depth_failed(depth.fault, reject_bad)) return;
    if (depth.view != nullptr) note_extent(*depth.view);
    const DepthBinding bound = depth_binding(*device_, depth);
    const CpuHandle* const depth_ptr = bound.is_bound ? &bound.handle : nullptr;
    List7* const list = list_.Get();
    const UINT targets = static_cast<UINT>(colors_.size());
    const CpuHandle* const colors = colors_.data();
    list->OMSetRenderTargets(targets, colors, FALSE, depth_ptr);
    clear_depth_if(list, bound);
    const Scissor area = pass_area(desc.area, extent_width_, extent_height_);
    apply_area(area);
    is_rendering_ = true;
}

void Commands::resolve_stored() {
    std::size_t index = 0;
    const std::size_t count = resolves_.size();
    // Khác gốc: gốc return giữa vòng; điều kiện dừng nằm ở for (PH-01).
    for (; index < count && is_live_ && !resolves_[index].is_integer; ++index) {
        resolve_item(resolves_[index]);
    }
    const bool is_integer = index < count && resolves_[index].is_integer;
    if (!is_integer) return;
    reject(fail(kBad, "resolve số nguyên không lấy trung bình được"));
}

void Commands::end_rendering() {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "end_rendering không có begin_rendering"));
        return;
    }
    resolve_stored();
    is_rendering_ = false;
}

void Commands::set_viewport(const Viewport& viewport) {
    if (!live()) return;
    const D3D12_VIEWPORT rect{.TopLeftX = viewport.x,
        .TopLeftY = viewport.y,
        .Width = viewport.width,
        .Height = viewport.height,
        .MinDepth = viewport.min_depth,
        .MaxDepth = viewport.max_depth};
    list_->RSSetViewports(1, &rect);
}

void Commands::set_scissor(const Scissor& scissor) {
    if (!live()) return;
    const auto right = scissor.x + static_cast<LONG>(scissor.width);
    const auto bottom = scissor.y + static_cast<LONG>(scissor.height);
    const D3D12_RECT rect{.left = scissor.x, .top = scissor.y, .right = right, .bottom = bottom};
    list_->RSSetScissorRects(1, &rect);
}

void Commands::set_stencil_reference(std::uint32_t value) {
    if (!live()) return;
    list_->OMSetStencilRef(value);
}

void Commands::set_blend_constants(const ClearColor& color) {
    if (!live()) return;
    const std::array<float, 4> constants{color.red, color.green, color.blue, color.alpha};
    list_->OMSetBlendFactor(constants.data());
}

void Commands::set_depth_bounds(float nearest, float farthest) {
    if (!live()) return;
    const bool is_valid = device_->caps().depth_bounds && nearest <= farthest;
    if (!is_valid) {
        reject(fail(kBad, "set_depth_bounds: thiết bị thiếu hoặc khoảng ngược"));
        return;
    }
    list_->OMSetDepthBounds(nearest, farthest);
}

void Commands::bind_pipeline(PipelineHandle pipeline) {
    if (!live()) return;
    const Pipeline* const found = device_->find(pipeline);
    if (found == nullptr || found->state == nullptr) {
        reject(fail(kBad, "bind_pipeline: pipeline đã chết"));
        return;
    }
    const bool on_copy = queue_ == QueueType::kCopy;
    const bool graphics_elsewhere = !found->is_compute && queue_ != QueueType::kGraphics;
    if (on_copy || graphics_elsewhere) {
        reject(fail(kState, "bind_pipeline: sai hàng đợi"));
        return;
    }
    const bool same = pipeline_.layout == found->layout;
    pipeline_ = *found;
    if (!same) bound_ = 0;
    list_->SetPipelineState(pipeline_.state.Get());
    if (pipeline_.is_compute) list_->SetComputeRootSignature(pipeline_.layout->signature.Get());
    if (!pipeline_.is_compute) list_->SetGraphicsRootSignature(pipeline_.layout->signature.Get());
    if (!pipeline_.is_compute) list_->IASetPrimitiveTopology(pipeline_.topology);
}

void Commands::bind_group(std::uint32_t space, BindGroupHandle group) {
    if (!live()) return;
    if (pipeline_.state == nullptr) {
        reject(fail(kState, "bind_group: chưa gắn pipeline"));
        return;
    }
    const BindGroup* const found = device_->find(group);
    const bool has_group = found != nullptr;
    const bool same_layout = has_group && found->layout == pipeline_.layout;
    const bool matches = same_layout && found->space == space;
    if (!matches) {
        reject(fail(kBad, "bind_group: nhóm đã chết hoặc khác bố cục"));
        return;
    }
    List7* const list = list_.Get();
    const bool is_compute = pipeline_.is_compute;
    const TableRef& resources = pipeline_.layout->resources.at(space);
    const TableRef& samplers = pipeline_.layout->samplers.at(space);
    const RootBind resource_bind{
        .list = list, .is_compute = is_compute, .table = resources, .slot = found->resource_at};
    const RootBind sampler_bind{.list = list, .is_compute = is_compute, .table = samplers, .slot = found->sampler_at};
    bind_table(*device_, resource_bind, false);
    bind_table(*device_, sampler_bind, true);
    bound_ |= 1U << space;
}

void Commands::push_constants(std::span<const std::byte> data, std::uint32_t offset) {
    if (!live()) return;
    if (pipeline_.state == nullptr) {
        reject(fail(kState, "push_constants: thiếu pipeline"));
        return;
    }
    const std::uint32_t limit = pipeline_.layout->program.push_bytes;
    const bool is_aligned = offset % 4 == 0 && data.size() % 4 == 0 && !data.empty();
    const bool is_inside = offset <= limit && data.size() <= limit - offset;
    if (!is_aligned || !is_inside) {
        reject(fail(kBad, "push_constants: sai căn hoặc vượt khối"));
        return;
    }
    const auto words = static_cast<UINT>(data.size() / 4);
    const auto index = offset / 4;
    const void* const bytes = data.data();
    const UINT root = pipeline_.layout->push_root;
    if (pipeline_.is_compute) list_->SetComputeRoot32BitConstants(root, words, bytes, index);
    if (!pipeline_.is_compute) list_->SetGraphicsRoot32BitConstants(root, words, bytes, index);
}

void Commands::bind_vertex_buffer(std::uint32_t slot, BufferHandle buffer, std::uint64_t offset) {
    if (!live()) return;
    const Buffer* const found =
        need(buffer, BufferUsage::kVertex, "bind_vertex_buffer: buffer đã chết hoặc thiếu cờ Vertex");
    if (found == nullptr) return;
    const bool is_valid = slot < kMaxVertexBuffers && offset <= found->size && pipeline_.state != nullptr;
    if (!is_valid) {
        reject(fail(kBad, "bind_vertex_buffer: khe, offset hoặc pipeline sai"));
        return;
    }
    const auto size = static_cast<UINT>(found->size - offset);
    const D3D12_VERTEX_BUFFER_VIEW view{.BufferLocation = found->gpu_address + offset,
        .SizeInBytes = size,
        .StrideInBytes = pipeline_.strides.at(slot)};
    list_->IASetVertexBuffers(slot, 1, &view);
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
    const auto size = static_cast<UINT>(found->size - offset);
    const D3D12_INDEX_BUFFER_VIEW view{
        .BufferLocation = found->gpu_address + offset, .SizeInBytes = size, .Format = to_index(type)};
    list_->IASetIndexBuffer(&view);
}

void Commands::draw(const DrawArguments& arguments) {
    if (!can_draw()) return;
    list_->DrawInstanced(arguments.vertex_count, arguments.instance_count, arguments.first_vertex,
        arguments.first_instance);
}

void Commands::draw_indexed(const DrawIndexedArguments& arguments) {
    if (!can_draw()) return;
    list_->DrawIndexedInstanced(arguments.index_count, arguments.instance_count, arguments.first_index,
        arguments.vertex_offset, arguments.first_instance);
}

void Commands::draw_indirect(BufferHandle buffer, std::uint64_t offset, std::uint32_t count, std::uint32_t stride) {
    if (count == 0 || !can_draw()) return;
    const Buffer* const source = need_arguments(buffer, offset, count, stride, sizeof(DrawArguments));
    if (source == nullptr) return;
    ID3D12CommandSignature* const signature = device_->signature(IndirectKind::kDraw, stride);
    if (signature == nullptr) {
        reject(fail(ErrorCode::kInternal, "không tạo được chữ ký lệnh vẽ"));
        return;
    }
    ID3D12Resource* const resource = source->resource.Get();
    list_->ExecuteIndirect(signature, count, resource, offset, nullptr, 0);
}

void Commands::draw_indexed_indirect(BufferHandle buffer, std::uint64_t offset, std::uint32_t count,
    std::uint32_t stride) {
    if (count == 0 || !can_draw()) return;
    const Buffer* const source = need_arguments(buffer, offset, count, stride, sizeof(DrawIndexedArguments));
    if (source == nullptr) return;
    ID3D12CommandSignature* const signature = device_->signature(IndirectKind::kDrawIndexed, stride);
    if (signature == nullptr) {
        reject(fail(ErrorCode::kInternal, "không tạo được chữ ký lệnh vẽ"));
        return;
    }
    ID3D12Resource* const resource = source->resource.Get();
    list_->ExecuteIndirect(signature, count, resource, offset, nullptr, 0);
}

void Commands::dispatch(const DispatchArguments& arguments) {
    if (!can_dispatch()) return;
    list_->Dispatch(arguments.x, arguments.y, arguments.z);
}

void Commands::dispatch_indirect(BufferHandle arguments, std::uint64_t offset) {
    if (!can_dispatch()) return;
    const std::uint32_t size = sizeof(DispatchArguments);
    const Buffer* const buffer = need_arguments(arguments, offset, 1, size, size);
    if (buffer == nullptr) return;
    ID3D12CommandSignature* const signature = device_->signature(IndirectKind::kDispatch, size);
    if (signature == nullptr) {
        reject(fail(ErrorCode::kInternal, "không tạo được chữ ký dispatch"));
        return;
    }
    ID3D12Resource* const resource = buffer->resource.Get();
    list_->ExecuteIndirect(signature, 1, resource, offset, nullptr, 0);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký chốt ở header (lệch API-03)
void Commands::copy_buffer(BufferHandle from, BufferHandle dest, const BufferCopy& region) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Buffer* const source =
        need(from, BufferUsage::kCopySource, "copy_buffer: nguồn đã chết hoặc thiếu cờ CopySource");
    const Buffer* const destination =
        need(dest, BufferUsage::kCopyDest, "copy_buffer: đích đã chết hoặc thiếu cờ CopyDest");
    if (source == nullptr || destination == nullptr) return;
    const Status taken = check_span(source->size, region.source_offset, region.size);
    const Status placed = check_span(destination->size, region.target_offset, region.size);
    const bool is_valid = static_cast<bool>(taken) && static_cast<bool>(placed) && region.size != 0;
    if (!is_valid) {
        reject(fail(kBad, "copy_buffer: khoảng rỗng hoặc vượt biên buffer"));
        return;
    }
    ID3D12Resource* const target = destination->resource.Get();
    ID3D12Resource* const origin = source->resource.Get();
    list_->CopyBufferRegion(target, region.target_offset, origin, region.source_offset, region.size);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký chốt ở header (lệch API-03)
void Commands::copy_texture(TextureHandle from, TextureHandle dest, const TextureCopy& region) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    const Texture* const source =
        need(from, TextureUsage::kCopySource, "copy_texture: nguồn đã chết hoặc thiếu cờ CopySource");
    const Texture* const destination =
        need(dest, TextureUsage::kCopyDest, "copy_texture: đích đã chết hoặc thiếu cờ CopyDest");
    if (source == nullptr || destination == nullptr) return;
    const core::Result<TextureCopy> resolved = resolve_copy(region, source->desc, destination->desc);
    if (!resolved) {
        reject(std::unexpected(resolved.error()));
        return;
    }
    const TextureCopy& copy = *resolved;
    D3D12_TEXTURE_COPY_LOCATION src{};
    src.pResource = source->resource.Get();
    src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    src.SubresourceIndex = subresource(copy.source.mip, copy.source.layer, source->desc.mip_levels);
    D3D12_TEXTURE_COPY_LOCATION dst{};
    dst.pResource = destination->resource.Get();
    dst.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    const UINT target_mips = destination->desc.mip_levels;
    dst.SubresourceIndex = subresource(copy.target.mip, copy.target.layer, target_mips);
    const D3D12_BOX box{.left = copy.source.x,
        .top = copy.source.y,
        .front = copy.source.z,
        .right = copy.source.x + copy.width,
        .bottom = copy.source.y + copy.height,
        .back = copy.source.z + copy.depth};
    list_->CopyTextureRegion(&dst, copy.target.x, copy.target.y, copy.target.z, &src, &box);
}

void Commands::copy_regions(const Buffer& buffer, const Texture& texture, std::span<const BufferTextureCopy> regions,
    bool to_texture) {
    List7* const list = list_.Get();
    const RegionJob job{.list = list, .buffer = &buffer, .texture = &texture, .to_texture = to_texture};
    std::optional<core::Error> error;
    const std::size_t count = regions.size();
    // Khác gốc: dừng khi vùng lỗi, rồi mới reject (PH-01).
    for (std::size_t index = 0; index < count && !error.has_value(); ++index) {
        error = emit_copy(job, regions[index]);
    }
    if (!error.has_value()) return;
    core::Error cause = std::move(*error);
    core::Failure failure = std::unexpected(std::move(cause));
    reject(std::move(failure));
}

void Commands::copy_buffer_to_texture(BufferHandle source, TextureHandle target, Regions regions) {
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
    copy_regions(*from, *destination, regions, true);
}

void Commands::copy_texture_to_buffer(TextureHandle source, BufferHandle target, Regions regions) {
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
    copy_regions(*destination, *from, regions, false);
}

void Commands::reset_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) {
    if (!live()) return;
    if (count == 0) return;
    const QueryPool* const found = device_->find(pool);
    const QueryKind kind = found == nullptr ? QueryKind::kTimestamp : found->kind;
    if (need_query(pool, kind, first, count) == nullptr) return;
}

void Commands::write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) {
    if (!live()) return;
    const QueryPool* const checked = need_query(pool, QueryKind::kTimestamp, index, 1);
    if (checked == nullptr) return;
    const bool is_single = std::popcount(std::to_underlying(stage)) <= 1;
    if (!is_single) {
        reject(fail(kBad, "write_timestamp: phải đúng một giai đoạn"));
        return;
    }
    list_->EndQuery(checked->heap.Get(), checked->type, index);
}

void Commands::begin_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "occlusion phải nằm trong begin_rendering"));
        return;
    }
    const QueryPool* const checked = need_query(pool, QueryKind::kOcclusion, index, 1);
    if (checked == nullptr) return;
    list_->BeginQuery(checked->heap.Get(), checked->type, index);
}

void Commands::end_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    const QueryPool* const checked = need_query(pool, QueryKind::kOcclusion, index, 1);
    if (checked == nullptr) return;
    list_->EndQuery(checked->heap.Get(), checked->type, index);
}

void Commands::resolve_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "resolve_queries nằm trong begin_rendering"));
        return;
    }
    const QueryPool* const known = device_->find(pool);
    const QueryKind kind = known == nullptr ? QueryKind::kTimestamp : known->kind;
    QueryPool* const ready = need_query(pool, kind, first, count);
    if (ready == nullptr) return;
    D3D12_BUFFER_BARRIER barrier{};
    barrier.SyncBefore = ready->last_sync;
    barrier.SyncAfter = D3D12_BARRIER_SYNC_COPY;
    barrier.AccessBefore = ready->last_access;
    barrier.AccessAfter = D3D12_BARRIER_ACCESS_COPY_DEST;
    barrier.pResource = ready->readback.Get();
    barrier.Size = UINT64_MAX;
    emit_barrier(list_.Get(), barrier);
    ready->last_sync = D3D12_BARRIER_SYNC_COPY;
    ready->last_access = D3D12_BARRIER_ACCESS_COPY_DEST;
    const std::uint64_t offset = std::uint64_t{first} * sizeof(std::uint64_t);
    list_->ResolveQueryData(ready->heap.Get(), ready->type, first, count, ready->readback.Get(), offset);
    queries_.push_back({.pool = pool, .first = first, .count = count});
}

// NOLINTEND(cppcoreguidelines-pro-type-union-access)
} // namespace game::gpu::d3d12
