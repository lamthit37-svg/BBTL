// Danh sách lệnh D3D11 ghi trên deferred context. Lỗi đầu được giữ, lệnh sau bỏ.
// Không lật trục Y. Cache pipeline, nhóm gắn, đỉnh và trạng thái để khỏi gắn lại.
// Khác gốc: bgfx chỉ có immediate context.
#include "gpu/d3d11/commands.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "gpu/barrier.hpp"
#include "gpu/check.hpp"
#include "gpu/command.hpp"
#include "gpu/d3d11/binding_map.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d11/device.hpp"
#include "gpu/d3d11/hresult.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <basetsd.h>
#include <d3d11.h>
#include <d3d11_1.h>
#include <dxgiformat.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <mutex>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gpu::d3d11 {

namespace {

using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;
using U32 = std::uint32_t;
using U64 = std::uint64_t;
using Gpu = D3d11Device;
using DeviceContext = ID3D11DeviceContext;
using Context1 = ID3D11DeviceContext1;
using GpuBuffer = ID3D11Buffer;
using ShaderView = ID3D11ShaderResourceView;
using TargetView = ID3D11RenderTargetView;
using DepthView = ID3D11DepthStencilView;
using Texture2D = ID3D11Texture2D;
using PoolHandle = QueryPoolHandle;
using ImageCopy = BufferTextureCopy;

constexpr core::ErrorCode kBad = core::ErrorCode::kInvalidArgument;
constexpr core::ErrorCode kState = core::ErrorCode::kInvalidState;
constexpr std::uint64_t kUintMax = 0xFFFFFFFFULL;
constexpr std::int64_t kLongMax = 0x7FFFFFFFLL;
constexpr GUID kPassGuid{
    .Data1 = 0x6C1A0B3E,
    .Data2 = 0x4F27,
    .Data3 = 0x4A91,
    .Data4 = {0x9C, 0x55, 0x1E, 0x8A, 0x7D, 0x2B, 0x60, 0x14},
};

static_assert(sizeof(DrawArguments) == 16);
static_assert(sizeof(DrawIndexedArguments) == 20);
static_assert(sizeof(DispatchArguments) == 12);

struct BindEnv {
    ID3D11DeviceContext* context = nullptr;
    ID3D11DeviceContext1* context1 = nullptr;
    D3d11Device* device = nullptr;
};

struct FixedState {
    UINT stencil = 0;
    bool blend_set = false;
    const float* factors = nullptr;
};

struct StoredResolve {
    TextureViewHandle color{};
    TextureViewHandle resolve{};
};

struct StoredPass {
    std::uint32_t count = 0;
    std::array<StoredResolve, kMaxColorTargets> items{};
};

struct TargetSet {
    std::array<ID3D11RenderTargetView*, kMaxColorTargets> colors{};
    ID3D11DepthStencilView* depth = nullptr;
    const View* extent = nullptr;
    StoredPass pass{};
};

struct IndirectRequest {
    const Buffer* buffer = nullptr;
    std::uint64_t offset = 0;
    std::uint32_t count = 0;
    std::uint32_t stride = 0;
    std::uint32_t element = 0;
};

struct IndirectRange {
    UINT base = 0;
    UINT step = 0;
};

struct ReadbackJob {
    ID3D11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    const Texture* source = nullptr;
    BufferHandle target{};
    std::uint64_t buffer_size = 0;
    std::vector<PendingReadback>* out = nullptr;
};

struct StagingDesc {
    ID3D11Device* device = nullptr;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t layers = 0;
    DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
};

struct ResolveJob {
    ID3D11DeviceContext* context = nullptr;
    D3d11Device* device = nullptr;
};

[[nodiscard]] core::Failure failure_of(const core::Status& status) {
    const core::Error& cause = status.error();
    return std::unexpected(cause);
}

[[nodiscard]] bool fits_uint(std::uint64_t value) noexcept {
    return value <= kUintMax;
}

[[nodiscard]] bool rect_fits(const Scissor& area) noexcept {
    const std::int64_t origin_x = area.x;
    const std::int64_t origin_y = area.y;
    const std::int64_t right = origin_x + static_cast<std::int64_t>(area.width);
    const std::int64_t bottom = origin_y + static_cast<std::int64_t>(area.height);
    return right <= kLongMax && bottom <= kLongMax;
}

[[nodiscard]] bool same_viewport(const Viewport& left, const Viewport& right) noexcept {
    const bool same_origin = left.x == right.x && left.y == right.y;
    const bool same_size = left.width == right.width && left.height == right.height;
    const bool same_depth = left.min_depth == right.min_depth && left.max_depth == right.max_depth;
    return same_origin && same_size && same_depth;
}

[[nodiscard]] bool same_scissor(const Scissor& left, const Scissor& right) noexcept {
    const bool same_origin = left.x == right.x && left.y == right.y;
    const bool same_size = left.width == right.width && left.height == right.height;
    return same_origin && same_size;
}

[[nodiscard]] bool is_target_layout(TextureLayout layout) noexcept {
    if (layout == TextureLayout::kColorTarget) return true;
    if (layout == TextureLayout::kDepthWrite) return true;
    if (layout == TextureLayout::kDepthRead) return true;
    return false;
}

[[nodiscard]] bool leaves_target(const TextureBarrier& item) noexcept {
    const bool was_target = is_target_layout(item.layout_before);
    const bool still_target = is_target_layout(item.layout_after);
    return was_target && !still_target;
}

void note_release(bool& drop, const TextureBarrier& item) noexcept {
    const bool leaves = leaves_target(item);
    drop = drop || leaves;
}

[[nodiscard]] bool is_buffer(const Buffer* buffer, BufferUsage usage) noexcept {
    if (buffer == nullptr || buffer->resource == nullptr) return false;
    return has(buffer->usage, usage);
}

[[nodiscard]] bool is_texture(const Texture* texture, TextureUsage usage) noexcept {
    if (texture == nullptr || texture->resource == nullptr) return false;
    return has(texture->usage, usage);
}

[[nodiscard]] core::Status outside_render(bool is_rendering) {
    if (is_rendering) return fail(kState, "lệnh chép nằm trong begin_rendering");
    return ok();
}

[[nodiscard]] core::Status create_push(ID3D11Device& device, ComPtr<ID3D11Buffer>& out) {
    D3D11_BUFFER_DESC desc{};
    desc.ByteWidth = kConstantBytes;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
    desc.CPUAccessFlags = 0;
    ID3D11Buffer** slot = out.GetAddressOf();
    const HRESULT created = device.CreateBuffer(&desc, nullptr, slot);
    if (FAILED(created)) return failed(created, "không tạo được buffer push constant");
    return ok();
}

[[nodiscard]] core::Status ensure_push(const D3d11Device& owner, ComPtr<ID3D11Buffer>& push) {
    if (push != nullptr) return ok();
    ID3D11Device* native = owner.device();
    if (native == nullptr) return fail(kState, "open: thiết bị D3D11 đã mất");
    return create_push(*native, push);
}

[[nodiscard]] const Pipeline* draw_pipeline(const Gpu& owner, PipelineHandle pipe, bool drawing) {
    if (!drawing) return nullptr;
    const Pipeline* found = owner.find(pipe);
    if (found == nullptr || found->is_compute) return nullptr;
    return found;
}

[[nodiscard]] QueryPool* query_span(D3d11Device& device, PoolHandle pool, U32 first, U32 count) {
    QueryPool* found = device.find(pool);
    if (found == nullptr) return nullptr;
    if (first > found->count) return nullptr;
    if (count > found->count - first) return nullptr;
    return found;
}

[[nodiscard]] QueryPool* query_slot(D3d11Device& owner, PoolHandle pool, QueryKind tag, U32 index) {
    QueryPool* found = query_span(owner, pool, index, 1);
    if (found == nullptr || found->kind != tag) return nullptr;
    if (index >= found->queries.size()) return nullptr;
    if (found->queries[index] == nullptr) return nullptr;
    return found;
}

void bind_shaders(DeviceContext& context, const Pipeline& pipeline) {
    ID3D11InputLayout* layout = pipeline.inputs.Get();
    ID3D11VertexShader* vertex = pipeline.vertex.Get();
    ID3D11PixelShader* pixel = pipeline.pixel.Get();
    ID3D11GeometryShader* geometry = pipeline.geometry.Get();
    ID3D11HullShader* hull = pipeline.hull.Get();
    ID3D11DomainShader* domain = pipeline.domain.Get();
    ID3D11ComputeShader* compute = pipeline.compute.Get();
    context.IASetInputLayout(layout);
    context.VSSetShader(vertex, nullptr, 0);
    context.PSSetShader(pixel, nullptr, 0);
    context.GSSetShader(geometry, nullptr, 0);
    context.HSSetShader(hull, nullptr, 0);
    context.DSSetShader(domain, nullptr, 0);
    context.CSSetShader(compute, nullptr, 0);
    context.IASetPrimitiveTopology(pipeline.topology);
}

void bind_fixed(DeviceContext& context, const Pipeline& pipeline, const FixedState& state) {
    ID3D11RasterizerState* raster = pipeline.raster.Get();
    ID3D11DepthStencilState* depth = pipeline.depth.Get();
    ID3D11BlendState* blend = pipeline.blend.Get();
    context.RSSetState(raster);
    context.OMSetDepthStencilState(depth, state.stencil);
    const float* factors = nullptr;
    if (state.blend_set) factors = state.factors;
    context.OMSetBlendState(blend, factors, 0xFFFFFFFFU);
}

void bind_uniform_whole(ID3D11DeviceContext& list, const GroupBuffer& item, ID3D11Buffer& buffer) {
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11Buffer* resource = &buffer;
    if (item.in_vertex) list.VSSetConstantBuffers(item.slot, 1, &resource);
    if (item.in_pixel) list.PSSetConstantBuffers(item.slot, 1, &resource);
    if (item.in_compute) list.CSSetConstantBuffers(item.slot, 1, &resource);
}

[[nodiscard]] core::Status bind_range(Context1& list, const GroupBuffer& item, GpuBuffer& gpu) {
    const bool aligned = item.offset % 16U == 0U && item.bytes % 16U == 0U;
    if (!aligned) return fail(kBad, "bind_group: cbuffer không căn 16 byte");
    if (item.offset / 16U > kUintMax) {
        return fail(core::ErrorCode::kOverflow, "bind_group: offset cbuffer không vừa UINT");
    }
    const UINT first = static_cast<UINT>(item.offset / 16U);
    const UINT count = item.bytes / 16U;
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11Buffer* resource = &gpu;
    const UINT* first_constant = &first;
    const UINT* constant_count = &count;
    if (item.in_vertex) {
        list.VSSetConstantBuffers1(item.slot, 1, &resource, first_constant, constant_count);
    }
    if (item.in_pixel) {
        list.PSSetConstantBuffers1(item.slot, 1, &resource, first_constant, constant_count);
    }
    if (item.in_compute) {
        list.CSSetConstantBuffers1(item.slot, 1, &resource, first_constant, constant_count);
    }
    return ok();
}

[[nodiscard]] core::Status bind_cb(const BindEnv& env, const GroupBuffer& item, GpuBuffer& gpu) {
    const bool ranged = item.offset != 0 || item.bytes != 0;
    if (item.offset != 0 && env.context1 == nullptr) {
        return fail(core::ErrorCode::kUnsupported, "D3D11.1 mới gắn được một khoảng cbuffer");
    }
    if (ranged && env.context1 != nullptr) return bind_range(*env.context1, item, gpu);
    bind_uniform_whole(*env.context, item, gpu);
    return ok();
}

void bind_srv(DeviceContext& context, UINT slot, ShaderView& view, const GroupBinding& stages) {
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11ShaderResourceView* resource = &view;
    if (stages.in_vertex) context.VSSetShaderResources(slot, 1, &resource);
    if (stages.in_pixel) context.PSSetShaderResources(slot, 1, &resource);
    if (stages.in_compute) context.CSSetShaderResources(slot, 1, &resource);
}

[[nodiscard]] core::Status bind_storage_uav(ID3D11DeviceContext& context, const GroupBuffer& item) {
    if (!item.in_compute) return ok();
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11UnorderedAccessView* view = item.uav.Get();
    if (view == nullptr) return fail(kBad, "bind_group: UAV rỗng");
    context.CSSetUnorderedAccessViews(item.slot, 1, &view, nullptr);
    return ok();
}

[[nodiscard]] core::Status bind_buffer(const BindEnv& env, const GroupBuffer& item) {
    const Buffer* found = env.device->find(item.buffer);
    if (found == nullptr || found->resource == nullptr) {
        return fail(kBad, "bind_group: buffer chưa hiện thực");
    }
    ID3D11Buffer* resource = found->resource.Get();
    if (item.is_uniform) return bind_cb(env, item, *resource);
    if (item.uav != nullptr) return bind_storage_uav(*env.context, item);
    if (item.srv == nullptr) return fail(kBad, "bind_group: buffer thiếu SRV");
    ID3D11ShaderResourceView* view = item.srv.Get();
    bind_srv(*env.context, item.slot, *view, item);
    return ok();
}

[[nodiscard]] core::Status bind_uav(DeviceContext& list, const GroupView& item, const View& view) {
    if (!item.in_compute || view.uav == nullptr) return fail(kBad, "bind_group: view không có SRV");
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11UnorderedAccessView* uav = view.uav.Get();
    list.CSSetUnorderedAccessViews(item.slot, 1, &uav, nullptr);
    return ok();
}

[[nodiscard]] core::Status bind_view(const BindEnv& env, const GroupView& item) {
    const View* view = env.device->find(item.view);
    if (view == nullptr) return fail(kBad, "bind_group: view đã chết");
    if (view->srv == nullptr) return bind_uav(*env.context, item, *view);
    ID3D11ShaderResourceView* srv = view->srv.Get();
    bind_srv(*env.context, item.slot, *srv, item);
    return ok();
}

[[nodiscard]] core::Status bind_sampler(const BindEnv& env, const GroupSampler& item) {
    const Sampler* sampler = env.device->find(item.sampler);
    if (sampler == nullptr || sampler->state == nullptr) {
        return fail(kBad, "bind_group: sampler đã chết");
    }
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11SamplerState* state = sampler->state.Get();
    if (item.in_vertex) env.context->VSSetSamplers(item.slot, 1, &state);
    if (item.in_pixel) env.context->PSSetSamplers(item.slot, 1, &state);
    if (item.in_compute) env.context->CSSetSamplers(item.slot, 1, &state);
    return ok();
}

[[nodiscard]] core::Status bind_all(const BindEnv& env, const BindGroup& group) {
    core::Status status = ok();
    const std::size_t buffer_count = group.buffers.size();
    for (std::size_t index = 0; index < buffer_count && status; ++index) {
        status = bind_buffer(env, group.buffers[index]);
    }
    const std::size_t view_count = group.views.size();
    for (std::size_t index = 0; index < view_count && status; ++index) {
        status = bind_view(env, group.views[index]);
    }
    const std::size_t sampler_count = group.samplers.size();
    for (std::size_t index = 0; index < sampler_count && status; ++index) {
        status = bind_sampler(env, group.samplers[index]);
    }
    return status;
}

[[nodiscard]] core::Status indirect_buffer(const Buffer* buffer) {
    if (buffer == nullptr || buffer->resource == nullptr) {
        return fail(kBad, "lệnh gián tiếp: buffer đã chết");
    }
    if (!has(buffer->usage, BufferUsage::kIndirect)) {
        return fail(kBad, "lệnh gián tiếp: buffer thiếu cờ Indirect");
    }
    return ok();
}

[[nodiscard]] U32 indirect_step(const IndirectRequest& request) noexcept {
    if (request.stride == 0) return request.element;
    return request.stride;
}

[[nodiscard]] core::Status indirect_layout(const IndirectRequest& request, U32 step) {
    const bool wide = step >= request.element;
    const bool aligned = step % 4U == 0U;
    if (!wide || !aligned) return fail(kBad, "lệnh gián tiếp: stride sai căn");
    if (request.offset % 4U != 0U) return fail(kBad, "lệnh gián tiếp: offset sai căn");
    if (request.offset > kUintMax) {
        return fail(core::ErrorCode::kOverflow, "lệnh gián tiếp: offset không vừa UINT");
    }
    return ok();
}

[[nodiscard]] core::Status fit_indirect(const IndirectRequest& call, U32 step, IndirectRange& out) {
    const std::uint64_t gaps = std::uint64_t{call.count - 1} * step;
    const bool gaps_fit = step == 0 || gaps / step == call.count - 1;
    if (!gaps_fit) return fail(core::ErrorCode::kOverflow, "lệnh gián tiếp: offset không vừa UINT");
    const std::uint64_t last = call.offset + gaps;
    if (last > kUintMax) {
        return fail(core::ErrorCode::kOverflow, "lệnh gián tiếp: offset không vừa UINT");
    }
    out.base = static_cast<UINT>(call.offset);
    out.step = step;
    return ok();
}

[[nodiscard]] core::Status check_indirect(const IndirectRequest& request, IndirectRange& out) {
    const core::Status alive = indirect_buffer(request.buffer);
    if (!alive) return alive;
    const U32 step = indirect_step(request);
    const core::Status layout = indirect_layout(request, step);
    if (!layout) return layout;
    IndirectRange fitted{};
    const core::Status ready = fit_indirect(request, step, fitted);
    if (!ready) return ready;
    const std::uint64_t gaps = std::uint64_t{request.count - 1} * step;
    const std::uint64_t bytes = gaps + request.element;
    const Buffer* buffer = request.buffer;
    const core::Status inside = check_span(buffer->size, request.offset, bytes);
    if (!inside) return fail(kBad, "lệnh gián tiếp: tham số nằm ngoài buffer");
    out = fitted;
    return ok();
}

void draw_one_indirect(ID3D11DeviceContext& context, ID3D11Buffer& buffer, UINT offset) {
    context.DrawInstancedIndirect(&buffer, offset);
}

void draw_one_indexed(ID3D11DeviceContext& context, ID3D11Buffer& buffer, UINT offset) {
    context.DrawIndexedInstancedIndirect(&buffer, offset);
}

[[nodiscard]] UINT indirect_byte(const IndirectRange& range, U32 index) noexcept {
    const std::uint64_t shift = std::uint64_t{index} * range.step;
    const std::uint64_t scaled = std::uint64_t{range.base} + shift;
    return static_cast<UINT>(scaled);
}

void emit_draws(DeviceContext& context, GpuBuffer& buffer, const IndirectRange& range, U32 count) {
    for (std::uint32_t index = 0; index < count; ++index) {
        const UINT byte_at = indirect_byte(range, index);
        draw_one_indirect(context, buffer, byte_at);
    }
}

void emit_indexed(DeviceContext& list, GpuBuffer& buffer, const IndirectRange& range, U32 count) {
    for (std::uint32_t index = 0; index < count; ++index) {
        const UINT byte_at = indirect_byte(range, index);
        draw_one_indexed(list, buffer, byte_at);
    }
}

[[nodiscard]] D3D11_BOX byte_box(UINT offset, UINT size) noexcept {
    D3D11_BOX box{};
    box.left = offset;
    box.right = offset + size;
    box.top = 0;
    box.bottom = 1;
    box.front = 0;
    box.back = 1;
    return box;
}

[[nodiscard]] D3D11_BOX region_box(const CopyRegion& region) noexcept {
    D3D11_BOX box{};
    box.left = region.x;
    box.top = region.y;
    box.front = region.z;
    box.right = region.x + region.width;
    box.bottom = region.y + region.height;
    box.back = region.z + region.depth;
    return box;
}

[[nodiscard]] D3D11_BOX source_box(const TextureCopy& copy) noexcept {
    D3D11_BOX box{};
    box.left = copy.source.x;
    box.top = copy.source.y;
    box.front = copy.source.z;
    box.right = copy.source.x + copy.width;
    box.bottom = copy.source.y + copy.height;
    box.back = copy.source.z + copy.depth;
    return box;
}

struct LayerCopy {
    DeviceContext* context = nullptr;
    const Texture* source = nullptr;
    const Texture* dest = nullptr;
    const TextureCopy* copy = nullptr;
};

void copy_texture_layer(const LayerCopy& job, U32 layer) {
    const TextureCopy& copy = *job.copy;
    const Texture& source = *job.source;
    const Texture& dest = *job.dest;
    const UINT source_mip = copy.source.mip;
    const UINT source_layer = copy.source.layer + layer;
    const UINT source_sub = D3D11CalcSubresource(source_mip, source_layer, source.mip_levels);
    const UINT dest_mip = copy.target.mip;
    const UINT dest_layer = copy.target.layer + layer;
    const UINT dest_sub = D3D11CalcSubresource(dest_mip, dest_layer, dest.mip_levels);
    const D3D11_BOX box = source_box(copy);
    ID3D11Resource* target = dest.resource.Get();
    ID3D11Resource* origin = source.resource.Get();
    const UINT dest_x = copy.target.x;
    const UINT dest_y = copy.target.y;
    const UINT dest_z = copy.target.z;
    job.context->CopySubresourceRegion(target, dest_sub, dest_x, dest_y, dest_z, origin, source_sub, &box);
}

// Nhân factor với count phải ra product.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] bool product_fits(U64 factor, U64 count, U64 product) noexcept {
    if (factor == 0) return true;
    return product / factor == count;
}

[[nodiscard]] bool shadow_products(const CopyRegion& region, U64& bytes) noexcept {
    const U64 row = region.row_bytes;
    const U64 row_span = row * region.rows;
    if (!product_fits(row, region.rows, row_span)) return false;
    const U64 slice = row_span * region.depth;
    if (!product_fits(row_span, region.depth, slice)) return false;
    const U64 total = slice * region.layer_count;
    if (!product_fits(slice, region.layer_count, total)) return false;
    if (row > kUintMax || row_span > kUintMax) return false;
    bytes = total;
    return true;
}

[[nodiscard]] bool fits_shadow(const Buffer& source, const CopyRegion& region, U64 bytes) noexcept {
    if (region.buffer_offset > source.shadow.size()) return false;
    if (bytes > source.shadow.size() - region.buffer_offset) return false;
    if (bytes != 0 && source.shadow.data() == nullptr) return false;
    return true;
}

[[nodiscard]] bool shadow_covers(const Buffer& source, const CopyRegion& region) noexcept {
    if (source.domain != MemoryDomain::kUpload) return false;
    U64 bytes = 0;
    if (!shadow_products(region, bytes)) return false;
    return fits_shadow(source, region, bytes);
}

[[nodiscard]] const void* layer_pixels(const Buffer& source, const CopyRegion& region, U32 layer) {
    const std::uint64_t slice = std::uint64_t{region.row_bytes} * region.rows * region.depth;
    const std::uint64_t byte_at = region.buffer_offset + (slice * layer);
    const auto byte_index = static_cast<std::size_t>(byte_at);
    const std::span<const std::byte> shadow = source.shadow;
    const std::span<const std::byte> pixels = shadow.subspan(byte_index);
    return pixels.data();
}

struct UploadSlice {
    DeviceContext* context = nullptr;
    const Buffer* source = nullptr;
    const Texture* target = nullptr;
    const CopyRegion* region = nullptr;
};

void upload_layer(const UploadSlice& job, U32 layer) {
    const CopyRegion& region = *job.region;
    const Texture& target = *job.target;
    const UINT mip = region.mip;
    const UINT slice = region.first_layer + layer;
    const UINT subresource = D3D11CalcSubresource(mip, slice, target.mip_levels);
    const UINT row_pitch = region.row_bytes;
    const UINT depth_pitch = region.row_bytes * region.rows;
    const D3D11_BOX box = region_box(region);
    const void* pixels = layer_pixels(*job.source, region, layer);
    ID3D11Resource* resource = target.resource.Get();
    job.context->UpdateSubresource(resource, subresource, &box, pixels, row_pitch, depth_pitch);
}

struct UploadJob {
    DeviceContext* context = nullptr;
    const Buffer* source = nullptr;
    const Texture* target = nullptr;
};

[[nodiscard]] core::Status upload_region(const UploadJob& job, const ImageCopy& region) {
    const TextureDesc desc = texture_of(*job.target);
    const core::Result<CopyRegion> resolved = resolve_copy(region, desc, job.source->size);
    if (!resolved) {
        const core::Error& cause = resolved.error();
        return std::unexpected(cause);
    }
    const CopyRegion copy = *resolved;
    if (!shadow_covers(*job.source, copy)) {
        return fail(kBad, "chép vào texture: buffer không phải upload hoặc shadow thiếu byte");
    }
    UploadSlice slice;
    slice.context = job.context;
    slice.source = job.source;
    slice.target = job.target;
    slice.region = &copy;
    for (U32 layer = 0; layer < copy.layer_count; ++layer) {
        upload_layer(slice, layer);
    }
    return ok();
}

[[nodiscard]] core::Status make_staging(const StagingDesc& desc, ComPtr<ID3D11Texture2D>& out) {
    D3D11_TEXTURE2D_DESC texture{};
    texture.Width = desc.width;
    texture.Height = desc.height;
    texture.MipLevels = 1;
    texture.ArraySize = desc.layers;
    texture.Format = desc.format;
    texture.SampleDesc.Count = 1;
    texture.Usage = D3D11_USAGE_STAGING;
    texture.BindFlags = 0;
    texture.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    ID3D11Texture2D** slot = out.GetAddressOf();
    const HRESULT created = desc.device->CreateTexture2D(&texture, nullptr, slot);
    if (FAILED(created)) return failed(created, "không tạo được ảnh staging để đọc");
    return ok();
}

struct StageCopy {
    DeviceContext* context = nullptr;
    const Texture* source = nullptr;
    Texture2D* staging = nullptr;
    const CopyRegion* region = nullptr;
};

void stage_layer(const StageCopy& job, U32 layer) {
    const CopyRegion& region = *job.region;
    const Texture& source = *job.source;
    const UINT mip = region.mip;
    const UINT slice = region.first_layer + layer;
    const UINT source_sub = D3D11CalcSubresource(mip, slice, source.mip_levels);
    const UINT dest_sub = D3D11CalcSubresource(0, layer, 1);
    const D3D11_BOX box = region_box(region);
    ID3D11Resource* origin = source.resource.Get();
    job.context->CopySubresourceRegion(job.staging, dest_sub, 0, 0, 0, origin, source_sub, &box);
}

[[nodiscard]] core::Status readback_region(const ReadbackJob& job, const ImageCopy& region) {
    const TextureDesc desc = texture_of(*job.source);
    const core::Result<CopyRegion> resolved = resolve_copy(region, desc, job.buffer_size);
    if (!resolved) {
        const core::Error& cause = resolved.error();
        return std::unexpected(cause);
    }
    const CopyRegion copy = *resolved;
    StagingDesc staging;
    staging.device = job.device;
    staging.width = copy.width;
    staging.height = copy.height;
    staging.layers = copy.layer_count;
    staging.format = to_dxgi(job.source->format);
    ComPtr<ID3D11Texture2D> texture;
    const core::Status created = make_staging(staging, texture);
    if (!created) return created;
    StageCopy stage;
    stage.context = job.context;
    stage.source = job.source;
    stage.staging = texture.Get();
    stage.region = &copy;
    for (U32 layer = 0; layer < copy.layer_count; ++layer) {
        stage_layer(stage, layer);
    }
    PendingReadback pending;
    pending.staging = texture;
    pending.target = job.target;
    pending.region = copy;
    job.out->push_back(pending);
    return ok();
}

struct ColorBind {
    D3d11Device* device = nullptr;
    TargetSet* out = nullptr;
};

[[nodiscard]] core::Status take_color(const ColorBind& bind, const ColorTarget& target, U32 index) {
    if (index >= kMaxColorTargets) return fail(kBad, "begin_rendering: chỉ số màu vượt mảng");
    const View* view = bind.device->find(target.view);
    if (view == nullptr || view->rtv == nullptr) {
        return fail(kBad, "begin_rendering: view màu không có RTV");
    }
    TargetSet& out = *bind.out;
    // Chỉ số đã nhỏ hơn trần.
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index)
    out.colors[index] = view->rtv.Get();
    if (out.extent == nullptr) out.extent = view;
    out.pass.items[index].color = target.view;
    out.pass.items[index].resolve = target.resolve;
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
    return ok();
}

[[nodiscard]] core::Status add_colors(D3d11Device& gpu, const RenderingDesc& desc, TargetSet& out) {
    if (desc.colors.size() > kMaxColorTargets) {
        return fail(kBad, "begin_rendering: quá kMaxColorTargets đích màu");
    }
    out.pass.count = static_cast<U32>(desc.colors.size());
    ColorBind bind;
    bind.device = &gpu;
    bind.out = &out;
    core::Status status = ok();
    for (U32 index = 0; index < out.pass.count && status; ++index) {
        status = take_color(bind, desc.colors[index], index);
    }
    return status;
}

[[nodiscard]] core::Status take_depth(const Gpu& gpu, const RenderingDesc& desc, TargetSet& out) {
    if (!desc.depth.has_value()) return ok();
    const DepthTarget& target = *desc.depth;
    const View* view = gpu.find(target.view);
    if (view == nullptr) return fail(kBad, "begin_rendering: view độ sâu đã chết");
    DepthView* depth = view->dsv.Get();
    if (target.is_read_only) depth = view->dsv_read.Get();
    if (depth == nullptr) return fail(kBad, "begin_rendering: view độ sâu không có DSV");
    out.depth = depth;
    if (out.extent == nullptr) out.extent = view;
    return ok();
}

void clear_color(DeviceContext& context, const ColorTarget& target, TargetView* view) {
    if (target.load != LoadOp::kClear || view == nullptr) return;
    const ClearColor& clear = target.clear;
    const std::array<float, 4> channels{clear.red, clear.green, clear.blue, clear.alpha};
    const float* color = channels.data();
    context.ClearRenderTargetView(view, color);
}

void clear_colors(DeviceContext& context, const RenderingDesc& desc, const TargetSet& targets) {
    if (targets.pass.count > kMaxColorTargets) return;
    // Chỉ số đã nhỏ hơn trần.
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index)
    for (U32 index = 0; index < targets.pass.count; ++index) {
        clear_color(context, desc.colors[index], targets.colors[index]);
    }
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
}

void clear_depth_view(DeviceContext& context, const RenderingDesc& desc, DepthView* view) {
    if (!desc.depth.has_value() || view == nullptr) return;
    const DepthTarget& target = *desc.depth;
    UINT flags = 0;
    if (target.load == LoadOp::kClear) flags |= D3D11_CLEAR_DEPTH;
    if (target.stencil_load == LoadOp::kClear) flags |= D3D11_CLEAR_STENCIL;
    if (flags == 0) return;
    const auto stencil = static_cast<UINT8>(target.clear.stencil);
    context.ClearDepthStencilView(view, flags, target.clear.depth, stencil);
}

[[nodiscard]] Scissor pass_area(const Scissor& area, const View* extent) noexcept {
    if (area.width != 0 && area.height != 0) return area;
    Scissor full{};
    full.x = 0;
    full.y = 0;
    if (extent == nullptr) return full;
    full.width = extent->width;
    full.height = extent->height;
    return full;
}

// Resolve nằm trên context: Commands không có mảng riêng.
[[nodiscard]] core::Status store_pass(ID3D11DeviceContext& context, const StoredPass& pass) {
    const UINT bytes = static_cast<UINT>(sizeof(pass));
    const HRESULT stored = context.SetPrivateData(kPassGuid, bytes, &pass);
    if (FAILED(stored)) return failed(stored, "không lưu được danh sách resolve");
    return ok();
}

[[nodiscard]] bool load_pass(ID3D11DeviceContext& context, StoredPass& pass) {
    UINT bytes = static_cast<UINT>(sizeof(pass));
    const HRESULT got = context.GetPrivateData(kPassGuid, &bytes, &pass);
    return SUCCEEDED(got) && bytes == sizeof(pass);
}

struct MsaaResolve {
    DeviceContext* context = nullptr;
    const Texture* source = nullptr;
    const Texture* dest = nullptr;
    const View* color = nullptr;
    const View* resolved = nullptr;
};

void resolve_layer(const MsaaResolve& job, U32 layer) {
    const Texture& source = *job.source;
    const Texture& dest = *job.dest;
    const View& color = *job.color;
    const View& resolved = *job.resolved;
    const UINT source_slice = color.first_layer + layer;
    const UINT source_sub = D3D11CalcSubresource(color.first_mip, source_slice, source.mip_levels);
    const UINT dest_slice = resolved.first_layer + layer;
    const UINT dest_sub = D3D11CalcSubresource(0, dest_slice, dest.mip_levels);
    const DXGI_FORMAT format = to_dxgi(color.format);
    ID3D11Resource* target = dest.resource.Get();
    ID3D11Resource* origin = source.resource.Get();
    job.context->ResolveSubresource(target, dest_sub, origin, source_sub, format);
}

[[nodiscard]] core::Status resolve_one(const ResolveJob& job, const StoredResolve& item) {
    if (!item.resolve) return ok();
    const View* color = job.device->find(item.color);
    const View* resolved = job.device->find(item.resolve);
    if (color == nullptr || resolved == nullptr) {
        return fail(kBad, "end_rendering: view resolve đã chết");
    }
    if (is_uint(color->format) || is_sint(color->format)) {
        return fail(kBad, "resolve số nguyên không lấy trung bình được");
    }
    const Texture* source = job.device->find(color->texture);
    const Texture* dest = job.device->find(resolved->texture);
    const bool source_ok = is_texture(source, TextureUsage::kNone);
    const bool dest_ok = is_texture(dest, TextureUsage::kNone);
    if (!source_ok || !dest_ok) return fail(kBad, "end_rendering: texture resolve đã chết");
    MsaaResolve resolve;
    resolve.context = job.context;
    resolve.source = source;
    resolve.dest = dest;
    resolve.color = color;
    resolve.resolved = resolved;
    for (U32 layer = 0; layer < color->layer_count; ++layer) {
        resolve_layer(resolve, layer);
    }
    return ok();
}

} // namespace

Commands::Commands(D3d11Device& device, QueueType queue, Context context)
    : device_(&device), queue_(queue), context_(std::move(context)) {
    const HRESULT context_1 = context_.As(&context1_);
    if (FAILED(context_1)) context1_.Reset();
    const HRESULT marked = context_.As(&annotation_);
    if (FAILED(marked)) annotation_.Reset();
}

core::Status Commands::open() {
    if (state_ != State::kIdle) return fail(kState, "open: danh sách không ở trạng thái rỗi");
    const core::Status made = ensure_push(*device_, push_);
    if (!made) return made;
    context_->ClearState();
    const std::byte zero{0};
    push_bytes_.fill(zero);
    pipeline_ = {};
    layout_hash_ = 0;
    forget_groups();
    vertex_set_.fill(false);
    index_set_ = false;
    viewport_set_ = false;
    scissor_set_ = false;
    blend_set_ = false;
    stencil_ = 0;
    blend_ = {};
    readbacks_.clear();
    state_ = State::kRecording;
    error_ = ok();
    is_rendering_ = false;
    targets_bound_ = false;
    return ok();
}

core::Status Commands::close(List& out) {
    if (state_ != State::kRecording) return fail(kState, "close: danh sách không đang ghi");
    ID3D11CommandList** slot = out.GetAddressOf();
    const HRESULT closed = context_->FinishCommandList(FALSE, slot);
    if (FAILED(closed)) return failed(closed, "không đóng được danh sách lệnh");
    state_ = State::kClosed;
    return ok();
}

void Commands::mark_pending() {
    const std::scoped_lock lock(device_->pool_mutex_);
    state_ = State::kPending;
}

void Commands::mark_idle() {
    const std::scoped_lock lock(device_->pool_mutex_);
    state_ = State::kIdle;
}

std::vector<PendingReadback> Commands::take_readbacks() {
    std::vector<PendingReadback> taken;
    taken.swap(readbacks_);
    return taken;
}

bool Commands::live() {
    if (state_ != State::kRecording) return false;
    if (!error_) return false;
    return true;
}

void Commands::reject(core::Failure failure) {
    if (!error_) return;
    error_ = std::move(failure);
}

void Commands::unbind_targets() {
    if (!targets_bound_) return;
    context_->OMSetRenderTargets(0, nullptr, nullptr);
    targets_bound_ = false;
}

void Commands::apply_area(const Scissor& area) {
    D3D11_VIEWPORT view{};
    view.TopLeftX = static_cast<float>(area.x);
    view.TopLeftY = static_cast<float>(area.y);
    view.Width = static_cast<float>(area.width);
    view.Height = static_cast<float>(area.height);
    view.MinDepth = 0.0F;
    view.MaxDepth = 1.0F;
    const std::int64_t origin_x = area.x;
    const std::int64_t span_x = area.width;
    const std::int64_t right = origin_x + span_x;
    const std::int64_t origin_y = area.y;
    const std::int64_t span_y = area.height;
    const std::int64_t bottom = origin_y + span_y;
    D3D11_RECT rect{};
    rect.left = area.x;
    rect.top = area.y;
    rect.right = static_cast<LONG>(right);
    rect.bottom = static_cast<LONG>(bottom);
    context_->RSSetViewports(1, &view);
    context_->RSSetScissorRects(1, &rect);
    viewport_.x = view.TopLeftX;
    viewport_.y = view.TopLeftY;
    viewport_.width = view.Width;
    viewport_.height = view.Height;
    viewport_.min_depth = 0.0F;
    viewport_.max_depth = 1.0F;
    scissor_ = area;
    viewport_set_ = true;
    scissor_set_ = true;
}

void Commands::forget_groups() noexcept {
    group_set_.fill(false);
}

void Commands::begin_label(std::string_view name) {
    if (!live()) return;
    if (annotation_ == nullptr) return;
    const std::wstring wide = core::widen(name);
    const wchar_t* text = wide.c_str();
    annotation_->BeginEvent(text);
}

void Commands::end_label() {
    if (!live()) return;
    if (annotation_ == nullptr) return;
    annotation_->EndEvent();
}

void Commands::insert_label(std::string_view name) {
    if (!live()) return;
    if (annotation_ == nullptr) return;
    const std::wstring wide = core::widen(name);
    const wchar_t* text = wide.c_str();
    annotation_->SetMarker(text);
}

void Commands::barrier(BufferBarriers buffers, TextureBarriers textures, GlobalBarriers memory) {
    if (!live()) return;
    (void)buffers;
    (void)memory;
    if (is_rendering_) {
        reject(fail(kState, "barrier nằm trong begin_rendering"));
        return;
    }
    bool drop = false;
    for (const TextureBarrier& item : textures) {
        note_release(drop, item);
    }
    if (drop) unbind_targets();
}

void Commands::begin_rendering(const RenderingDesc& desc) {
    if (!live()) return;
    if (queue_ != QueueType::kGraphics || is_rendering_) {
        reject(fail(kState, "begin_rendering lồng nhau hoặc ngoài hàng Graphics"));
        return;
    }
    TargetSet targets;
    const core::Status colors = add_colors(*device_, desc, targets);
    if (!colors) {
        const core::Failure failure = failure_of(colors);
        reject(failure);
        return;
    }
    const core::Status depth = take_depth(*device_, desc, targets);
    if (!depth) {
        const core::Failure failure = failure_of(depth);
        reject(failure);
        return;
    }
    const UINT count = targets.pass.count;
    ID3D11RenderTargetView* const* views = targets.colors.data();
    context_->OMSetRenderTargets(count, views, targets.depth);
    ID3D11DeviceContext& context = *context_.Get();
    clear_colors(context, desc, targets);
    clear_depth_view(context, desc, targets.depth);
    const Scissor area = pass_area(desc.area, targets.extent);
    if (!rect_fits(area)) {
        reject(fail(core::ErrorCode::kOverflow, "begin_rendering: vùng vẽ vượt LONG"));
        return;
    }
    apply_area(area);
    const core::Status stored = store_pass(context, targets.pass);
    if (!stored) {
        const core::Failure failure = failure_of(stored);
        reject(failure);
        return;
    }
    targets_bound_ = true;
    is_rendering_ = true;
}

void Commands::end_rendering() {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "end_rendering không có begin_rendering"));
        return;
    }
    StoredPass pass{};
    ID3D11DeviceContext& context = *context_.Get();
    if (!load_pass(context, pass)) {
        reject(fail(core::ErrorCode::kInternal, "end_rendering: thiếu danh sách resolve"));
        return;
    }
    if (pass.count > kMaxColorTargets) {
        const core::Failure failure = fail(kBad, "end_rendering: quá kMaxColorTargets resolve");
        reject(failure);
        return;
    }
    ResolveJob job;
    job.context = context_.Get();
    job.device = device_;
    core::Status status = ok();
    // Chỉ số đã nhỏ hơn trần.
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index)
    for (std::uint32_t index = 0; index < pass.count && status; ++index) {
        status = resolve_one(job, pass.items[index]);
    }
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
    if (!status) {
        const core::Failure failure = failure_of(status);
        reject(failure);
        return;
    }
    is_rendering_ = false;
}

void Commands::set_viewport(const Viewport& viewport) {
    if (!live()) return;
    if (viewport_set_ && same_viewport(viewport_, viewport)) return;
    D3D11_VIEWPORT rect{};
    rect.TopLeftX = viewport.x;
    rect.TopLeftY = viewport.y;
    rect.Width = viewport.width;
    rect.Height = viewport.height;
    rect.MinDepth = viewport.min_depth;
    rect.MaxDepth = viewport.max_depth;
    context_->RSSetViewports(1, &rect);
    viewport_ = viewport;
    viewport_set_ = true;
}

void Commands::set_scissor(const Scissor& scissor) {
    if (!live()) return;
    if (scissor_set_ && same_scissor(scissor_, scissor)) return;
    if (!rect_fits(scissor)) {
        reject(fail(core::ErrorCode::kOverflow, "set_scissor: cạnh vượt LONG"));
        return;
    }
    const std::int64_t origin_x = scissor.x;
    const std::int64_t span_x = scissor.width;
    const std::int64_t right = origin_x + span_x;
    const std::int64_t origin_y = scissor.y;
    const std::int64_t span_y = scissor.height;
    const std::int64_t bottom = origin_y + span_y;
    D3D11_RECT rect{};
    rect.left = scissor.x;
    rect.top = scissor.y;
    rect.right = static_cast<LONG>(right);
    rect.bottom = static_cast<LONG>(bottom);
    context_->RSSetScissorRects(1, &rect);
    scissor_ = scissor;
    scissor_set_ = true;
}

void Commands::set_stencil_reference(std::uint32_t value) {
    if (!live()) return;
    if (stencil_ == value) return;
    stencil_ = value;
    const Pipeline* found = device_->find(pipeline_);
    if (found == nullptr) return;
    ID3D11DepthStencilState* depth = found->depth.Get();
    context_->OMSetDepthStencilState(depth, stencil_);
}

void Commands::set_blend_constants(const ClearColor& color) {
    if (!live()) return;
    if (blend_set_ && blend_ == color) return;
    blend_ = color;
    blend_set_ = true;
    const Pipeline* found = device_->find(pipeline_);
    if (found == nullptr || found->blend == nullptr) return;
    const std::array<float, 4> factors{color.red, color.green, color.blue, color.alpha};
    const float* channels = factors.data();
    ID3D11BlendState* blend = found->blend.Get();
    context_->OMSetBlendState(blend, channels, 0xFFFFFFFFU);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::set_depth_bounds(float nearest, float farthest) {
    if (!live()) return;
    (void)nearest;
    (void)farthest;
    reject(fail(core::ErrorCode::kUnsupported, "D3D11 không có depth bounds"));
}

void Commands::bind_pipeline(PipelineHandle pipeline) {
    if (!live()) return;
    if (pipeline_ == pipeline) return;
    const Pipeline* found = device_->find(pipeline);
    if (found == nullptr) {
        reject(fail(kBad, "bind_pipeline: pipeline đã chết"));
        return;
    }
    ID3D11DeviceContext* context = context_.Get();
    bind_shaders(*context, *found);
    const std::array<float, 4> factors{blend_.red, blend_.green, blend_.blue, blend_.alpha};
    FixedState state;
    state.stencil = stencil_;
    state.blend_set = blend_set_;
    state.factors = factors.data();
    bind_fixed(*context, *found, state);
    const std::uint64_t previous = layout_hash_;
    layout_hash_ = found->layout.hash;
    if (layout_hash_ != previous) forget_groups();
    pipeline_ = pipeline;
}

void Commands::bind_group(std::uint32_t space, BindGroupHandle group) {
    if (!live()) return;
    if (space >= kMaxBindGroups) {
        reject(fail(kBad, "bind_group: space vượt kMaxBindGroups"));
        return;
    }
    // Chỉ số đã nhỏ hơn trần.
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index)
    if (group_set_[space] && groups_[space] == group) return;
    const BindGroup* found = device_->find(group);
    if (found == nullptr) {
        reject(fail(kBad, "bind_group: nhóm đã chết"));
        return;
    }
    BindEnv env;
    env.context = context_.Get();
    env.context1 = context1_.Get();
    env.device = device_;
    const core::Status bound = bind_all(env, *found);
    if (!bound) {
        const core::Failure failure = failure_of(bound);
        reject(failure);
        return;
    }
    groups_[space] = group;
    group_set_[space] = true;
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
}

void Commands::push_constants(std::span<const std::byte> data, std::uint32_t offset) {
    if (!live()) return;
    if (push_ == nullptr) {
        reject(fail(kState, "push_constants: thiếu buffer"));
        return;
    }
    const bool aligned = offset % 4U == 0U && data.size() % 4U == 0U;
    const bool capped = offset <= kMaxPushBytes && data.size() <= kMaxPushBytes;
    const std::size_t end = std::size_t{offset} + data.size();
    const bool inside = aligned && capped && end <= kMaxPushBytes && end <= kConstantBytes;
    if (!inside) {
        reject(fail(kBad, "push_constants: sai căn hoặc vượt khối"));
        return;
    }
    if (!data.empty()) {
        const std::size_t bytes = data.size();
        const std::span<std::byte> dest = push_bytes_;
        const std::span<std::byte> slot = dest.subspan(offset, bytes);
        const void* from = data.data();
        void* into = slot.data();
        std::memcpy(into, from, bytes);
    }
    ID3D11Resource* resource = push_.Get();
    const void* bytes = push_bytes_.data();
    const UINT pitch = kConstantBytes;
    context_->UpdateSubresource(resource, 0, nullptr, bytes, pitch, pitch);
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11Buffer* buffer = push_.Get();
    context_->VSSetConstantBuffers(kPushRegister, 1, &buffer);
    context_->PSSetConstantBuffers(kPushRegister, 1, &buffer);
    context_->CSSetConstantBuffers(kPushRegister, 1, &buffer);
}

void Commands::bind_vertex_buffer(U32 slot, Buf buffer, U64 offset) {
    if (!live()) return;
    if (slot >= kMaxVertexBuffers) {
        reject(fail(kBad, "bind_vertex_buffer: khe vượt kMaxVertexBuffers"));
        return;
    }
    // Chỉ số đã nhỏ hơn trần.
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index)
    const bool same_slot = vertex_set_[slot] && vertices_[slot] == buffer;
    const bool cached = same_slot && vertex_at_[slot] == offset;
    if (cached) return;
    const Buffer* found = device_->find(buffer);
    if (found == nullptr || found->resource == nullptr) {
        reject(fail(kBad, "bind_vertex_buffer: buffer chưa hiện thực"));
        return;
    }
    const Pipeline* pipeline = device_->find(pipeline_);
    if (pipeline == nullptr) {
        reject(fail(kState, "bind_vertex_buffer: thiếu pipeline"));
        return;
    }
    if (!fits_uint(offset)) {
        reject(fail(core::ErrorCode::kOverflow, "bind_vertex_buffer: offset không vừa UINT"));
        return;
    }
    const UINT stride = pipeline->strides[slot];
    const UINT byte_at = static_cast<UINT>(offset);
    // D3D11 không nhận const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11Buffer* resource = found->resource.Get();
    context_->IASetVertexBuffers(slot, 1, &resource, &stride, &byte_at);
    vertices_[slot] = buffer;
    vertex_at_[slot] = offset;
    vertex_set_[slot] = true;
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
}

void Commands::bind_index_buffer(Buf buffer, IndexType type, U64 offset) {
    if (!live()) return;
    const bool same_buffer = index_set_ && index_ == buffer && index_type_ == type;
    const bool cached = same_buffer && index_at_ == offset;
    if (cached) return;
    const Buffer* found = device_->find(buffer);
    if (found == nullptr || found->resource == nullptr) {
        reject(fail(kBad, "bind_index_buffer: buffer chưa hiện thực"));
        return;
    }
    if (!fits_uint(offset)) {
        reject(fail(core::ErrorCode::kOverflow, "bind_index_buffer: offset không vừa UINT"));
        return;
    }
    const UINT byte_at = static_cast<UINT>(offset);
    const DXGI_FORMAT format = to_index(type);
    ID3D11Buffer* resource = found->resource.Get();
    context_->IASetIndexBuffer(resource, format, byte_at);
    index_ = buffer;
    index_type_ = type;
    index_at_ = offset;
    index_set_ = true;
}

void Commands::draw(const DrawArguments& arguments) {
    if (!live()) return;
    if (draw_pipeline(*device_, pipeline_, is_rendering_) == nullptr) {
        reject(fail(kState, "vẽ: thiếu pipeline đồ hoạ hoặc begin_rendering"));
        return;
    }
    const UINT vertices = arguments.vertex_count;
    const UINT instances = arguments.instance_count;
    const UINT first = arguments.first_vertex;
    const UINT base = arguments.first_instance;
    context_->DrawInstanced(vertices, instances, first, base);
}

void Commands::draw_indexed(const DrawIndexedArguments& arguments) {
    if (!live()) return;
    if (draw_pipeline(*device_, pipeline_, is_rendering_) == nullptr) {
        reject(fail(kState, "vẽ: thiếu pipeline đồ hoạ hoặc begin_rendering"));
        return;
    }
    context_->DrawIndexedInstanced(arguments.index_count, arguments.instance_count, arguments.first_index,
        arguments.vertex_offset, arguments.first_instance);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::draw_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) {
    if (!live()) return;
    if (count == 0) return;
    if (draw_pipeline(*device_, pipeline_, is_rendering_) == nullptr) {
        reject(fail(kState, "vẽ: thiếu pipeline đồ hoạ hoặc begin_rendering"));
        return;
    }
    IndirectRequest request;
    request.buffer = device_->find(buffer);
    request.offset = offset;
    request.count = count;
    request.stride = stride;
    request.element = static_cast<std::uint32_t>(sizeof(DrawArguments));
    IndirectRange range;
    const core::Status ready = check_indirect(request, range);
    if (!ready) {
        const core::Failure failure = failure_of(ready);
        reject(failure);
        return;
    }
    ID3D11Buffer* resource = request.buffer->resource.Get();
    ID3D11DeviceContext& context = *context_.Get();
    emit_draws(context, *resource, range, count);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::draw_indexed_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) {
    if (!live()) return;
    if (count == 0) return;
    if (draw_pipeline(*device_, pipeline_, is_rendering_) == nullptr) {
        reject(fail(kState, "vẽ: thiếu pipeline đồ hoạ hoặc begin_rendering"));
        return;
    }
    IndirectRequest request;
    request.buffer = device_->find(buffer);
    request.offset = offset;
    request.count = count;
    request.stride = stride;
    request.element = static_cast<std::uint32_t>(sizeof(DrawIndexedArguments));
    IndirectRange range;
    const core::Status ready = check_indirect(request, range);
    if (!ready) {
        const core::Failure failure = failure_of(ready);
        reject(failure);
        return;
    }
    ID3D11Buffer* resource = request.buffer->resource.Get();
    ID3D11DeviceContext& context = *context_.Get();
    emit_indexed(context, *resource, range, count);
}

void Commands::dispatch(const DispatchArguments& arguments) {
    if (!live()) return;
    const Pipeline* found = device_->find(pipeline_);
    if (found == nullptr || !found->is_compute || is_rendering_) {
        reject(fail(kState, "dispatch: cần pipeline compute và không đang vẽ"));
        return;
    }
    context_->Dispatch(arguments.x, arguments.y, arguments.z);
}

void Commands::dispatch_indirect(BufferHandle arguments, std::uint64_t offset) {
    if (!live()) return;
    const Pipeline* found = device_->find(pipeline_);
    if (found == nullptr || !found->is_compute || is_rendering_) {
        reject(fail(kState, "dispatch: cần pipeline compute và không đang vẽ"));
        return;
    }
    IndirectRequest request;
    request.buffer = device_->find(arguments);
    request.offset = offset;
    request.count = 1;
    request.stride = static_cast<std::uint32_t>(sizeof(DispatchArguments));
    request.element = request.stride;
    IndirectRange range;
    const core::Status ready = check_indirect(request, range);
    if (!ready) {
        const core::Failure failure = failure_of(ready);
        reject(failure);
        return;
    }
    ID3D11Buffer* resource = request.buffer->resource.Get();
    context_->DispatchIndirect(resource, range.base);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::copy_buffer(BufferHandle from, BufferHandle dest, const BufferCopy& region) {
    if (!live()) return;
    const core::Status gate = outside_render(is_rendering_);
    if (!gate) {
        const core::Failure failure = failure_of(gate);
        reject(failure);
        return;
    }
    const Buffer* source = device_->find(from);
    const Buffer* target = device_->find(dest);
    const bool source_ok = is_buffer(source, BufferUsage::kCopySource);
    const bool target_ok = is_buffer(target, BufferUsage::kCopyDest);
    if (!source_ok || !target_ok) {
        reject(fail(kBad, "copy_buffer: buffer đã chết hoặc thiếu cờ chép"));
        return;
    }
    const core::Status taken = check_span(source->size, region.source_offset, region.size);
    const core::Status placed = check_span(target->size, region.target_offset, region.size);
    const bool spans = static_cast<bool>(taken) && static_cast<bool>(placed) && region.size != 0;
    const bool in_uint = fits_uint(region.source_offset) && fits_uint(region.target_offset);
    const std::uint64_t end = region.source_offset + region.size;
    if (!spans || !in_uint || !fits_uint(region.size) || !fits_uint(end)) {
        reject(fail(kBad, "copy_buffer: khoảng rỗng, vượt biên hoặc không vừa UINT"));
        return;
    }
    const UINT source_at = static_cast<UINT>(region.source_offset);
    const UINT size = static_cast<UINT>(region.size);
    const UINT dest_at = static_cast<UINT>(region.target_offset);
    const D3D11_BOX box = byte_box(source_at, size);
    ID3D11Resource* origin = source->resource.Get();
    ID3D11Resource* destination = target->resource.Get();
    context_->CopySubresourceRegion(destination, 0, dest_at, 0, 0, origin, 0, &box);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::copy_texture(TextureHandle from, TextureHandle dest, const TextureCopy& region) {
    if (!live()) return;
    const core::Status gate = outside_render(is_rendering_);
    if (!gate) {
        const core::Failure failure = failure_of(gate);
        reject(failure);
        return;
    }
    const Texture* source = device_->find(from);
    const Texture* target = device_->find(dest);
    const bool source_ok = is_texture(source, TextureUsage::kCopySource);
    const bool target_ok = is_texture(target, TextureUsage::kCopyDest);
    if (!source_ok || !target_ok) {
        reject(fail(kBad, "copy_texture: texture đã chết hoặc thiếu cờ chép"));
        return;
    }
    const TextureDesc source_desc = texture_of(*source);
    const TextureDesc target_desc = texture_of(*target);
    const core::Result<TextureCopy> resolved = resolve_copy(region, source_desc, target_desc);
    if (!resolved) {
        const core::Error& cause = resolved.error();
        const core::Failure failure = std::unexpected(cause);
        reject(failure);
        return;
    }
    const TextureCopy copy = *resolved;
    LayerCopy job;
    job.context = context_.Get();
    job.source = source;
    job.dest = target;
    job.copy = &copy;
    for (U32 layer = 0; layer < copy.layer_count; ++layer) {
        copy_texture_layer(job, layer);
    }
}

void Commands::copy_buffer_to_texture(Buf source, Tex target, Regions regions) {
    if (!live()) return;
    const core::Status gate = outside_render(is_rendering_);
    if (!gate) {
        const core::Failure failure = failure_of(gate);
        reject(failure);
        return;
    }
    const Buffer* from = device_->find(source);
    const Texture* destination = device_->find(target);
    const bool upload = from != nullptr && from->domain == MemoryDomain::kUpload;
    if (!upload || !is_texture(destination, TextureUsage::kCopyDest)) {
        reject(fail(kBad, "chép vào texture: cần upload và CopyDest"));
        return;
    }
    UploadJob job;
    job.context = context_.Get();
    job.source = from;
    job.target = destination;
    core::Status status = ok();
    for (std::size_t index = 0; index < regions.size() && status; ++index) {
        status = upload_region(job, regions[index]);
    }
    if (status) return;
    const core::Failure failure = failure_of(status);
    reject(failure);
}

void Commands::copy_texture_to_buffer(Tex source, Buf target, Regions regions) {
    if (!live()) return;
    const core::Status gate = outside_render(is_rendering_);
    if (!gate) {
        const core::Failure failure = failure_of(gate);
        reject(failure);
        return;
    }
    const Texture* from = device_->find(source);
    const Buffer* destination = device_->find(target);
    const bool readable = destination != nullptr && has(destination->usage, BufferUsage::kCopyDest);
    if (!is_texture(from, TextureUsage::kCopySource) || !readable) {
        reject(fail(kBad, "chép ra buffer: tài nguyên đã chết hoặc thiếu cờ chép"));
        return;
    }
    ID3D11Device* device = device_->device();
    if (device == nullptr) {
        reject(fail(kState, "chép ra buffer: thiết bị D3D11 đã mất"));
        return;
    }
    ReadbackJob job;
    job.device = device;
    job.context = context_.Get();
    job.source = from;
    job.target = target;
    job.buffer_size = destination->size;
    job.out = &readbacks_;
    core::Status status = ok();
    for (std::size_t index = 0; index < regions.size() && status; ++index) {
        status = readback_region(job, regions[index]);
    }
    if (status) return;
    const core::Failure failure = failure_of(status);
    reject(failure);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::reset_queries(QueryPoolHandle pool, U32 first, U32 count) {
    if (!live()) return;
    if (query_span(*device_, pool, first, count) != nullptr) return;
    reject(fail(kBad, "reset_queries: pool đã chết hoặc ô nằm ngoài pool"));
}

void Commands::write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage /*stage*/) {
    if (!live()) return;
    QueryPool* found = query_slot(*device_, pool, QueryKind::kTimestamp, index);
    if (found == nullptr) {
        reject(fail(kBad, "write_timestamp: pool đã chết hoặc ô nằm ngoài pool"));
        return;
    }
    if (found->disjoint != nullptr && !found->disjoint_open) {
        ID3D11Query* disjoint = found->disjoint.Get();
        context_->Begin(disjoint);
        found->disjoint_open = true;
    }
    ID3D11Query* query = found->queries[index].Get();
    context_->End(query);
}

void Commands::begin_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "occlusion phải nằm trong begin_rendering"));
        return;
    }
    QueryPool* found = query_slot(*device_, pool, QueryKind::kOcclusion, index);
    if (found == nullptr) {
        reject(fail(kBad, "occlusion: pool đã chết hoặc ô nằm ngoài pool"));
        return;
    }
    ID3D11Query* query = found->queries[index].Get();
    context_->Begin(query);
}

void Commands::end_occlusion(QueryPoolHandle pool, std::uint32_t index) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "occlusion phải nằm trong begin_rendering"));
        return;
    }
    QueryPool* found = query_slot(*device_, pool, QueryKind::kOcclusion, index);
    if (found == nullptr) {
        reject(fail(kBad, "occlusion: pool đã chết hoặc ô nằm ngoài pool"));
        return;
    }
    ID3D11Query* query = found->queries[index].Get();
    context_->End(query);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters) API-03
void Commands::resolve_queries(QueryPoolHandle pool, U32 first, U32 count) {
    if (!live()) return;
    QueryPool* found = query_span(*device_, pool, first, count);
    if (found == nullptr) {
        reject(fail(kBad, "resolve_queries: pool đã chết hoặc ô nằm ngoài pool"));
        return;
    }
    const bool close_disjoint = found->kind == QueryKind::kTimestamp && found->disjoint_open;
    if (!close_disjoint) return;
    ID3D11Query* disjoint = found->disjoint.Get();
    context_->End(disjoint);
    found->disjoint_open = false;
}

} // namespace game::gpu::d3d11
