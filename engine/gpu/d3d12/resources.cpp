// Tài nguyên D3D12 đặt bằng CreatePlacedResource2, bố cục đầu là UNDEFINED (API bắt vậy với
// buffer). View nằm ở heap descriptor CPU; sampler cũng vậy. Query kèm buffer readback để
// ResolveQueryData ghi, CPU đọc sau khi fence của lần nộp đã xong.
// Nguồn: Forge2 src/gpu/d3d12/resources.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k;
// make_views tách make_sampled, make_storage, make_color vì if lồng if; is_ready đưa điều kiện
// dừng lên while qua slot_done; fill_srv tách hai case mảng và create_query_pool tách mô tả
// readback vì quá 40 dòng; place gộp if trùng điều kiện, format_support tách phép lọc vì
// cognitive quá 10; NOLINT cho .at() trong hàm noexcept; MinGW không đặt tên
// D3D12_UAV_DIMENSION_TEXTURE2DMS nên hai case đó chỉ dịch khi không phải MinGW, vẫn return false;
// Clang bỏ qua __uuidof của IID_PPV_ARGS; include trực tiếp header của từng tên.
#include "gpu/d3d12/device.hpp"

#include "core/error.hpp"
#include "gpu/check.hpp"
#include "gpu/d3d12/convert.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/timestamp.hpp"
#include "gpu/types.hpp"

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d12.h>
#include <dxgi1_4.h>
#include <dxgiformat.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <utility>

#if defined(__clang__)
// __uuidof của IID_PPV_ARGS không có dạng chuẩn.
#pragma clang diagnostic ignored "-Wlanguage-extension-token"
#endif

namespace game::gpu::d3d12 {

using core::ErrorCode;
using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr UINT64 kInvalidSize = ~UINT64{0};

namespace {

using SrvDesc = D3D12_SHADER_RESOURCE_VIEW_DESC;
using SrvDim = D3D12_SRV_DIMENSION;

[[nodiscard]] PoolKind pool_of(MemoryDomain domain) noexcept {
    if (domain == MemoryDomain::kUpload) return PoolKind::kUpload;
    if (domain == MemoryDomain::kReadback) return PoolKind::kReadback;
    return PoolKind::kDeviceBuffer;
}

[[nodiscard]] PoolKind texture_pool(TextureUsage usage) noexcept {
    const bool is_target = has(usage, TextureUsage::kColorTarget) || has(usage, TextureUsage::kDepthStencilTarget);
    if (is_target) return PoolKind::kDeviceTarget;
    return PoolKind::kDeviceTexture;
}

[[nodiscard]] D3D12_RESOURCE_DESC1 as_desc1(const D3D12_RESOURCE_DESC& desc) noexcept {
    D3D12_RESOURCE_DESC1 out{};
    out.Dimension = desc.Dimension;
    out.Alignment = desc.Alignment;
    out.Width = desc.Width;
    out.Height = desc.Height;
    out.DepthOrArraySize = desc.DepthOrArraySize;
    out.MipLevels = desc.MipLevels;
    out.Format = desc.Format;
    out.SampleDesc = desc.SampleDesc;
    out.Layout = desc.Layout;
    out.Flags = desc.Flags;
    return out;
}

[[nodiscard]] D3D12_RESOURCE_DESC buffer_desc(const BufferDesc& desc) noexcept {
    D3D12_RESOURCE_DESC info{};
    info.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    info.Width = desc.size;
    info.Height = 1;
    info.DepthOrArraySize = 1;
    info.MipLevels = 1;
    info.Format = DXGI_FORMAT_UNKNOWN;
    info.SampleDesc.Count = 1;
    info.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    if (has(desc.usage, BufferUsage::kStorage)) {
        info.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    }
    return info;
}

[[nodiscard]] DXGI_FORMAT resource_format(const TextureDesc& desc) noexcept {
    const DXGI_FORMAT typed = to_dxgi(desc.format);
    const bool is_depth_sampled = has_depth(desc.format) && has(desc.usage, TextureUsage::kSampled);
    const bool is_reinterpret = has(desc.usage, TextureUsage::kReinterpret);
    if (!is_depth_sampled && !is_reinterpret) return typed;
    const DXGI_FORMAT bare = typeless_format(typed);
    if (bare == DXGI_FORMAT_UNKNOWN) return typed;
    return bare;
}

[[nodiscard]] D3D12_RESOURCE_FLAGS texture_flags(const TextureDesc& desc) noexcept {
    D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE;
    if (has(desc.usage, TextureUsage::kColorTarget)) {
        flags |= D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
    }
    if (has(desc.usage, TextureUsage::kDepthStencilTarget)) {
        flags |= D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
    }
    if (has(desc.usage, TextureUsage::kStorage)) flags |= D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    const bool deny_sample =
        has(desc.usage, TextureUsage::kDepthStencilTarget) && !has(desc.usage, TextureUsage::kSampled);
    if (deny_sample) flags |= D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE;
    return flags;
}

[[nodiscard]] D3D12_RESOURCE_DESC texture_desc(const TextureDesc& desc) noexcept {
    D3D12_RESOURCE_DESC info{};
    info.Dimension = to_dimension(desc.kind);
    info.Width = desc.width;
    info.Height = desc.height;
    info.DepthOrArraySize = static_cast<UINT16>(desc.depth_or_layers);
    info.MipLevels = static_cast<UINT16>(desc.mip_levels);
    info.Format = resource_format(desc);
    info.SampleDesc.Count = std::max(desc.samples, 1U);
    info.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
    info.Flags = texture_flags(desc);
    return info;
}

// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access): view của D3D12 là union có thẻ.
[[nodiscard]] D3D12_CLEAR_VALUE clear_value(const TextureDesc& desc) noexcept {
    D3D12_CLEAR_VALUE value{};
    value.Format = to_dxgi(desc.format);
    const bool is_depth = has(desc.usage, TextureUsage::kDepthStencilTarget);
    if (is_depth) value.DepthStencil.Depth = desc.clear_depth.depth;
    if (is_depth) value.DepthStencil.Stencil = static_cast<UINT8>(desc.clear_depth.stencil);
    if (!is_depth) value.Color[0] = desc.clear_color.red;
    if (!is_depth) value.Color[1] = desc.clear_color.green;
    if (!is_depth) value.Color[2] = desc.clear_color.blue;
    if (!is_depth) value.Color[3] = desc.clear_color.alpha;
    return value;
}

[[nodiscard]] bool wants_clear(TextureUsage usage) noexcept {
    return has(usage, TextureUsage::kColorTarget) || has(usage, TextureUsage::kDepthStencilTarget);
}

[[nodiscard]] UINT plane_of(ViewAspect aspect) noexcept {
    switch (aspect) {
    case ViewAspect::kAll:
    case ViewAspect::kDepth: return 0;
    case ViewAspect::kStencil: return 1;
    }
    return 0;
}

[[nodiscard]] DXGI_FORMAT srv_format(const Texture& texture, const ViewRange& range) noexcept {
    if (has_depth(texture.desc.format)) return depth_srv_format(texture.desc.format, range.aspect);
    return to_dxgi(range.format);
}

void prepare_srv(SrvDesc& desc, DXGI_FORMAT format, SrvDim dimension) noexcept {
    desc.Format = format;
    desc.ViewDimension = dimension;
    desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
}

[[nodiscard]] bool fill_cube_array(SrvDesc& desc, const ViewRange& range) noexcept {
    const UINT cubes = range.layer_count / 6;
    if (cubes == 0) return false;
    desc.TextureCubeArray.MostDetailedMip = range.first_mip;
    desc.TextureCubeArray.MipLevels = range.mip_count;
    desc.TextureCubeArray.First2DArrayFace = range.first_layer;
    desc.TextureCubeArray.NumCubes = cubes;
    return true;
}

// Khác gốc: case TEXTURE1DARRAY của fill_srv.
[[nodiscard]] bool fill_srv_1d_array(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1DArray.MostDetailedMip = range.first_mip;
    desc.Texture1DArray.MipLevels = range.mip_count;
    desc.Texture1DArray.FirstArraySlice = range.first_layer;
    desc.Texture1DArray.ArraySize = range.layer_count;
    return true;
}

// Khác gốc: case TEXTURE2DARRAY của fill_srv.
[[nodiscard]] bool fill_srv_2d_array(SrvDesc& desc, const ViewRange& range, UINT plane) noexcept {
    desc.Texture2DArray.MostDetailedMip = range.first_mip;
    desc.Texture2DArray.MipLevels = range.mip_count;
    desc.Texture2DArray.FirstArraySlice = range.first_layer;
    desc.Texture2DArray.ArraySize = range.layer_count;
    desc.Texture2DArray.PlaneSlice = plane;
    return true;
}

[[nodiscard]] bool fill_srv(SrvDesc& desc, const ViewRange& range, UINT plane) noexcept {
    switch (desc.ViewDimension) {
    case D3D12_SRV_DIMENSION_TEXTURE1D:
        desc.Texture1D.MostDetailedMip = range.first_mip;
        desc.Texture1D.MipLevels = range.mip_count;
        return true;
    case D3D12_SRV_DIMENSION_TEXTURE1DARRAY: return fill_srv_1d_array(desc, range);
    case D3D12_SRV_DIMENSION_TEXTURE2D:
        desc.Texture2D.MostDetailedMip = range.first_mip;
        desc.Texture2D.MipLevels = range.mip_count;
        desc.Texture2D.PlaneSlice = plane;
        return true;
    case D3D12_SRV_DIMENSION_TEXTURE2DARRAY: return fill_srv_2d_array(desc, range, plane);
    case D3D12_SRV_DIMENSION_TEXTURE2DMS: desc.Texture2DMS.UnusedField_NothingToDefine = 0; return true;
    case D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY:
        desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
        desc.Texture2DMSArray.ArraySize = range.layer_count;
        return true;
    case D3D12_SRV_DIMENSION_TEXTURE3D:
        desc.Texture3D.MostDetailedMip = range.first_mip;
        desc.Texture3D.MipLevels = range.mip_count;
        return true;
    case D3D12_SRV_DIMENSION_TEXTURECUBE:
        desc.TextureCube.MostDetailedMip = range.first_mip;
        desc.TextureCube.MipLevels = range.mip_count;
        return true;
    case D3D12_SRV_DIMENSION_TEXTURECUBEARRAY: return fill_cube_array(desc, range);
    case D3D12_SRV_DIMENSION_UNKNOWN:
    case D3D12_SRV_DIMENSION_BUFFER:
    case D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE: return false;
    }
    return false;
}

[[nodiscard]] bool fill_uav(D3D12_UNORDERED_ACCESS_VIEW_DESC& desc, const ViewRange& range, const TextureDesc& texture,
    UINT plane) noexcept {
    switch (desc.ViewDimension) {
    case D3D12_UAV_DIMENSION_TEXTURE1D: desc.Texture1D.MipSlice = range.first_mip; return true;
    case D3D12_UAV_DIMENSION_TEXTURE1DARRAY:
        desc.Texture1DArray.MipSlice = range.first_mip;
        desc.Texture1DArray.FirstArraySlice = range.first_layer;
        desc.Texture1DArray.ArraySize = range.layer_count;
        return true;
    case D3D12_UAV_DIMENSION_TEXTURE2D:
        desc.Texture2D.MipSlice = range.first_mip;
        desc.Texture2D.PlaneSlice = plane;
        return true;
    case D3D12_UAV_DIMENSION_TEXTURE2DARRAY:
        desc.Texture2DArray.MipSlice = range.first_mip;
        desc.Texture2DArray.FirstArraySlice = range.first_layer;
        desc.Texture2DArray.ArraySize = range.layer_count;
        desc.Texture2DArray.PlaneSlice = plane;
        return true;
    case D3D12_UAV_DIMENSION_TEXTURE3D:
        desc.Texture3D.MipSlice = range.first_mip;
        desc.Texture3D.FirstWSlice = 0;
        desc.Texture3D.WSize = mip_size(depth_of(texture), range.first_mip);
        return true;
    case D3D12_UAV_DIMENSION_UNKNOWN:
    case D3D12_UAV_DIMENSION_BUFFER:
#if !defined(__MINGW32__)
    case D3D12_UAV_DIMENSION_TEXTURE2DMS:
    case D3D12_UAV_DIMENSION_TEXTURE2DMSARRAY:
#endif
        return false;
    }
    return false;
}

[[nodiscard]] bool fill_rtv(D3D12_RENDER_TARGET_VIEW_DESC& desc, const ViewRange& range,
    const TextureDesc& texture) noexcept {
    switch (desc.ViewDimension) {
    case D3D12_RTV_DIMENSION_TEXTURE1D: desc.Texture1D.MipSlice = range.first_mip; return true;
    case D3D12_RTV_DIMENSION_TEXTURE1DARRAY:
        desc.Texture1DArray.MipSlice = range.first_mip;
        desc.Texture1DArray.FirstArraySlice = range.first_layer;
        desc.Texture1DArray.ArraySize = range.layer_count;
        return true;
    case D3D12_RTV_DIMENSION_TEXTURE2D:
        desc.Texture2D.MipSlice = range.first_mip;
        desc.Texture2D.PlaneSlice = 0;
        return true;
    case D3D12_RTV_DIMENSION_TEXTURE2DARRAY:
        desc.Texture2DArray.MipSlice = range.first_mip;
        desc.Texture2DArray.FirstArraySlice = range.first_layer;
        desc.Texture2DArray.ArraySize = range.layer_count;
        desc.Texture2DArray.PlaneSlice = 0;
        return true;
    case D3D12_RTV_DIMENSION_TEXTURE2DMS: desc.Texture2DMS.UnusedField_NothingToDefine = 0; return true;
    case D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY:
        desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
        desc.Texture2DMSArray.ArraySize = range.layer_count;
        return true;
    case D3D12_RTV_DIMENSION_TEXTURE3D:
        desc.Texture3D.MipSlice = range.first_mip;
        desc.Texture3D.FirstWSlice = 0;
        desc.Texture3D.WSize = mip_size(depth_of(texture), range.first_mip);
        return true;
    case D3D12_RTV_DIMENSION_UNKNOWN:
    case D3D12_RTV_DIMENSION_BUFFER: return false;
    }
    return false;
}

[[nodiscard]] bool fill_dsv(D3D12_DEPTH_STENCIL_VIEW_DESC& desc, const ViewRange& range) noexcept {
    switch (desc.ViewDimension) {
    case D3D12_DSV_DIMENSION_TEXTURE1D: desc.Texture1D.MipSlice = range.first_mip; return true;
    case D3D12_DSV_DIMENSION_TEXTURE1DARRAY:
        desc.Texture1DArray.MipSlice = range.first_mip;
        desc.Texture1DArray.FirstArraySlice = range.first_layer;
        desc.Texture1DArray.ArraySize = range.layer_count;
        return true;
    case D3D12_DSV_DIMENSION_TEXTURE2D: desc.Texture2D.MipSlice = range.first_mip; return true;
    case D3D12_DSV_DIMENSION_TEXTURE2DARRAY:
        desc.Texture2DArray.MipSlice = range.first_mip;
        desc.Texture2DArray.FirstArraySlice = range.first_layer;
        desc.Texture2DArray.ArraySize = range.layer_count;
        return true;
    case D3D12_DSV_DIMENSION_TEXTURE2DMS: desc.Texture2DMS.UnusedField_NothingToDefine = 0; return true;
    case D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY:
        desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
        desc.Texture2DMSArray.ArraySize = range.layer_count;
        return true;
    case D3D12_DSV_DIMENSION_UNKNOWN: return false;
    }
    return false;
}

// NOLINTEND(cppcoreguidelines-pro-type-union-access)

[[nodiscard]] core::Status assign_slot(std::optional<UINT> taken, UINT& slot) {
    if (!taken) return fail(ErrorCode::kExhausted, "hết descriptor");
    slot = *taken;
    return ok();
}

[[nodiscard]] core::Status take_slot(D3d12Device& device, UINT& slot, bool is_rtv, bool is_dsv) {
    if (is_rtv) return assign_slot(device.allocate_rtv(), slot);
    if (is_dsv) return assign_slot(device.allocate_dsv(), slot);
    return assign_slot(device.allocate_staging(), slot);
}

[[nodiscard]] core::Status make_srv(D3d12Device& device, View& view, const Texture& texture) {
    const DXGI_FORMAT format = srv_format(texture, view.range);
    if (format == DXGI_FORMAT_UNKNOWN) return ok();
    const core::Status slot = take_slot(device, view.srv, false, false);
    if (!slot) return slot;
    D3D12_SHADER_RESOURCE_VIEW_DESC desc{};
    prepare_srv(desc, format, to_srv(texture.desc.kind, texture.desc.samples));
    const bool filled = fill_srv(desc, view.range, plane_of(view.range.aspect));
    if (!filled) return fail(ErrorCode::kUnsupported, "view SRV không dựng được");
    device.device()->CreateShaderResourceView(texture.resource.Get(), &desc, device.staging_cpu(view.srv));
    return ok();
}

[[nodiscard]] core::Status make_uav(D3d12Device& device, View& view, const Texture& texture) {
    if (view.range.mip_count != 1) return fail(kBad, "view đích chỉ một mức mip");
    if (texture.desc.samples > 1) return fail(ErrorCode::kUnsupported, "UAV đa mẫu không có");
    const core::Status slot = take_slot(device, view.uav, false, false);
    if (!slot) return slot;
    D3D12_UNORDERED_ACCESS_VIEW_DESC desc{};
    desc.Format = to_dxgi(view.range.format);
    desc.ViewDimension = to_uav(texture.desc.kind);
    const bool filled = fill_uav(desc, view.range, texture.desc, plane_of(view.range.aspect));
    if (!filled) return fail(ErrorCode::kUnsupported, "view UAV không dựng được");
    device.device()->CreateUnorderedAccessView(texture.resource.Get(), nullptr, &desc, device.staging_cpu(view.uav));
    return ok();
}

[[nodiscard]] core::Status make_rtv(D3d12Device& device, View& view, const Texture& texture) {
    if (view.range.mip_count != 1) return fail(kBad, "view đích chỉ một mức mip");
    const core::Status slot = take_slot(device, view.rtv, true, false);
    if (!slot) return slot;
    D3D12_RENDER_TARGET_VIEW_DESC desc{};
    desc.Format = to_dxgi(view.range.format);
    desc.ViewDimension = to_rtv(texture.desc.kind, texture.desc.samples);
    const bool filled = fill_rtv(desc, view.range, texture.desc);
    if (!filled) return fail(ErrorCode::kUnsupported, "view RTV không dựng được");
    device.device()->CreateRenderTargetView(texture.resource.Get(), &desc, device.rtv_cpu(view.rtv));
    return ok();
}

[[nodiscard]] core::Status make_dsv(D3d12Device& device, const View& view, const Texture& texture, UINT& slot,
    D3D12_DSV_FLAGS flags) {
    if (view.range.mip_count != 1) return fail(kBad, "view đích chỉ một mức mip");
    const core::Status taken = take_slot(device, slot, false, true);
    if (!taken) return taken;
    D3D12_DEPTH_STENCIL_VIEW_DESC desc{};
    desc.Format = to_dxgi(texture.desc.format);
    desc.ViewDimension = to_dsv(texture.desc.kind, texture.desc.samples);
    desc.Flags = flags;
    const bool filled = fill_dsv(desc, view.range);
    if (!filled) return fail(ErrorCode::kUnsupported, "view DSV không dựng được");
    device.device()->CreateDepthStencilView(texture.resource.Get(), &desc, device.dsv_cpu(slot));
    return ok();
}

// Khác gốc: if lồng if khi có cờ Sampled.
[[nodiscard]] Status make_sampled(D3d12Device& device, View& view, const Texture& texture) {
    if (!has(texture.desc.usage, TextureUsage::kSampled)) return ok();
    return make_srv(device, view, texture);
}

// Khác gốc: if lồng if khi có cờ Storage.
[[nodiscard]] Status make_storage(D3d12Device& device, View& view, const Texture& texture) {
    if (!has(texture.desc.usage, TextureUsage::kStorage)) return ok();
    return make_uav(device, view, texture);
}

// Khác gốc: if lồng if khi có cờ ColorTarget.
[[nodiscard]] Status make_color(D3d12Device& device, View& view, const Texture& texture) {
    if (!has(texture.desc.usage, TextureUsage::kColorTarget)) return ok();
    return make_rtv(device, view, texture);
}

[[nodiscard]] Status make_views(D3d12Device& device, View& view, const Texture& texture) {
    const Status sampled = make_sampled(device, view, texture);
    if (!sampled) return sampled;
    const Status stored = make_storage(device, view, texture);
    if (!stored) return stored;
    const Status color = make_color(device, view, texture);
    if (!color) return color;
    const TextureUsage usage = texture.desc.usage;
    if (!has(usage, TextureUsage::kDepthStencilTarget)) return ok();
    const core::Status depth = make_dsv(device, view, texture, view.dsv, D3D12_DSV_FLAG_NONE);
    if (!depth) return depth;
    // READ_ONLY_STENCIL trên D16/D32 (không có stencil) làm driver gỡ thiết bị.
    D3D12_DSV_FLAGS read_only = D3D12_DSV_FLAG_READ_ONLY_DEPTH;
    const bool has_stencil = info(texture.desc.format).aspect == FormatAspect::kDepthStencil;
    if (has_stencil) read_only |= D3D12_DSV_FLAG_READ_ONLY_STENCIL;
    return make_dsv(device, view, texture, view.dsv_read, read_only);
}

[[nodiscard]] std::array<float, 4> border_color(BorderColor border) noexcept {
    switch (border) {
    case BorderColor::kTransparentBlack: return {0.0F, 0.0F, 0.0F, 0.0F};
    case BorderColor::kOpaqueBlack: return {0.0F, 0.0F, 0.0F, 1.0F};
    case BorderColor::kOpaqueWhite: return {1.0F, 1.0F, 1.0F, 1.0F};
    }
    return {0.0F, 0.0F, 0.0F, 1.0F};
}

// .at() nội bộ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] D3D12_QUERY_HEAP_TYPE query_heap(const DeviceCaps& caps, const QueryPoolDesc& desc) noexcept {
    const bool is_copy = desc.kind == QueryKind::kTimestamp && desc.queue == QueueType::kCopy;
    const bool is_native = caps.has_queue.at(std::to_underlying(QueueType::kCopy));
    if (is_copy && is_native) return D3D12_QUERY_HEAP_TYPE_COPY_QUEUE_TIMESTAMP;
    if (desc.kind == QueryKind::kOcclusion) return D3D12_QUERY_HEAP_TYPE_OCCLUSION;
    return D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
}

// .at() nội bộ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] bool timestamps_ok(const DeviceCaps& caps, QueueType queue) noexcept {
    if (caps.has_timestamps.at(std::to_underlying(queue))) return true;
    if (caps.has_queue.at(std::to_underlying(queue))) return false;
    return caps.has_timestamps.at(std::to_underlying(QueueType::kGraphics));
}

// .at() nội bộ (LH-07).
// Khác gốc: slot trước pool.
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] bool slot_done(std::size_t slot, const QueryPool& pool, std::uint64_t done) noexcept {
    const std::uint64_t mark = pool.ready_at.at(slot);
    return mark != 0 && mark <= done;
}

// Khác gốc: dừng lên while.
[[nodiscard]] bool is_ready(const QueryPool& pool, std::uint64_t done, std::uint32_t first,
    std::size_t count) noexcept {
    std::size_t index = 0;
    while (index < count && slot_done(first + index, pool, done)) {
        ++index;
    }
    return index == count;
}

void copy_occlusion(const QueryPool& pool, std::uint32_t first, std::span<std::uint64_t> out) noexcept {
    // NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    // Vùng đọc ngược của pool là khối byte; đọc theo uint64, biên đã kiểm ở copy_raw.
    const auto* ticks = reinterpret_cast<const std::uint64_t*>(pool.mapped);
    for (std::size_t index = 0; index < out.size(); ++index) {
        out[index] = ticks[first + index];
    }
    // NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
}

void copy_times(const D3d12Device& device, const QueryPool& pool, std::uint32_t first,
    std::span<std::uint64_t> out) noexcept {
    // NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    // Như copy_occlusion: khối byte đọc theo uint64, biên đã kiểm ở copy_raw.
    const auto* ticks = reinterpret_cast<const std::uint64_t*>(pool.mapped);
    const std::uint64_t base = ticks[first];
    const double period = device.queue_of(pool.queue).period_ns;
    const double start = ticks_to_ns(mask_timestamp(base, 64), period);
    for (std::size_t index = 0; index < out.size(); ++index) {
        const std::int64_t offset = timestamp_offset(base, ticks[first + index], 64);
        const double nanos = start + (static_cast<double>(offset) * period);
        out[index] = static_cast<std::uint64_t>(std::max(nanos, 0.0));
    }
    // NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
}

[[nodiscard]] core::Status copy_raw(const D3d12Device& device, const QueryPool& pool, std::uint32_t first,
    std::span<std::uint64_t> out) {
    if (pool.mapped == nullptr || !pool.mutex) {
        return fail(ErrorCode::kInternal, "read_queries: pool hỏng");
    }
    const std::scoped_lock lock(*pool.mutex);
    const std::uint64_t done = device.completed(pool.queue);
    if (!is_ready(pool, done, first, out.size())) {
        return fail(ErrorCode::kWouldBlock, "kết quả truy vấn chưa có");
    }
    if (pool.kind == QueryKind::kOcclusion) copy_occlusion(pool, first, out);
    if (pool.kind == QueryKind::kTimestamp) copy_times(device, pool, first, out);
    return ok();
}

// Khác gốc: mô tả readback của create_query_pool.
[[nodiscard]] D3D12_RESOURCE_DESC query_readback(std::uint32_t count) noexcept {
    D3D12_RESOURCE_DESC buffer{};
    buffer.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    buffer.Width = std::uint64_t{count} * sizeof(std::uint64_t);
    buffer.Height = 1;
    buffer.DepthOrArraySize = 1;
    buffer.MipLevels = 1;
    buffer.SampleDesc.Count = 1;
    buffer.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    return buffer;
}

[[nodiscard]] bool is_integer_format(Format format) noexcept {
    return is_uint(format) || is_sint(format);
}

// Khác gốc: sampled và không phải integer mới được lọc.
[[nodiscard]] bool can_filter(FormatSupport support, Format format) noexcept {
    if (!has(support, FormatSupport::kSampled)) return false;
    return !is_integer_format(format);
}

} // namespace

// Khác gốc: lọc texel tách ra can_filter.
FormatSupport D3d12Device::format_support(Format format) const {
    if (format == Format::kUnknown) return FormatSupport::kNone;
    D3D12_FEATURE_DATA_FORMAT_SUPPORT data{};
    data.Format = to_dxgi(format);
    if (data.Format == DXGI_FORMAT_UNKNOWN) return FormatSupport::kNone;
    const HRESULT checked = device_->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, &data, sizeof(data));
    if (FAILED(checked)) return FormatSupport::kNone;
    FormatSupport support = FormatSupport::kNone;
    const auto bits = data.Support1;
    if ((bits & D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE) != 0) support |= FormatSupport::kSampled;
    if (can_filter(support, format)) support |= FormatSupport::kFiltered;
    if ((bits & D3D12_FORMAT_SUPPORT1_RENDER_TARGET) != 0) support |= FormatSupport::kColorTarget;
    if ((bits & D3D12_FORMAT_SUPPORT1_BLENDABLE) != 0) support |= FormatSupport::kBlendable;
    if ((bits & D3D12_FORMAT_SUPPORT1_DEPTH_STENCIL) != 0) support |= FormatSupport::kDepthTarget;
    if ((bits & D3D12_FORMAT_SUPPORT1_TYPED_UNORDERED_ACCESS_VIEW) != 0) {
        support |= FormatSupport::kStorage;
    }
    return support;
}

MemoryBudget D3d12Device::memory_budget() const {
    MemoryBudget budget;
    budget.budget_bytes = adapter_.memory_bytes;
    if (adapter_com_ == nullptr) return budget;
    ComPtr<IDXGIAdapter3> adapter;
    const HRESULT queried = adapter_com_->QueryInterface(IID_PPV_ARGS(&adapter));
    if (FAILED(queried)) return budget;
    DXGI_QUERY_VIDEO_MEMORY_INFO info{};
    const HRESULT read = adapter->QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &info);
    if (FAILED(read)) return budget;
    budget.budget_bytes = info.Budget;
    budget.used_bytes = info.CurrentUsage;
    return budget;
}

// Khác gốc: gộp if trùng điều kiện.
Result<D3d12Device::Placed> D3d12Device::place(const D3D12_RESOURCE_DESC& desc, PoolKind kind,
    const D3D12_CLEAR_VALUE* clear, bool map_cpu) {
    const D3D12_RESOURCE_ALLOCATION_INFO needs = device_->GetResourceAllocationInfo(0, 1, &desc);
    if (needs.SizeInBytes == kInvalidSize) return fail(kBad, "mô tả tài nguyên D3D12 không hợp lệ");
    Result<Allocation> memory = allocate(needs, kind);
    if (!memory) return std::unexpected(memory.error());
    Placed placed;
    placed.memory = *memory;
    const ComPtr<ID3D12Heap> heap = heap_of(placed.memory);
    ComPtr<ID3D12Device10> device10;
    const HRESULT queried = device_->QueryInterface(IID_PPV_ARGS(&device10));
    if (FAILED(queried)) {
        free(placed.memory);
        return fail(ErrorCode::kUnsupported, "thiết bị không có CreatePlacedResource2");
    }
    const D3D12_RESOURCE_DESC1 desc1 = as_desc1(desc);
    const HRESULT created = device10->CreatePlacedResource2(heap.Get(), placed.memory.span.offset, &desc1,
        D3D12_BARRIER_LAYOUT_UNDEFINED, clear, 0, nullptr, IID_PPV_ARGS(&placed.resource));
    if (FAILED(created)) {
        placed.resource.Reset();
        free(placed.memory);
        return failed(created, "không đặt được tài nguyên");
    }
    if (!map_cpu) {
        placed.address = placed.resource->GetGPUVirtualAddress();
        return placed;
    }
    void* mapped = nullptr;
    const HRESULT opened = placed.resource->Map(0, nullptr, &mapped);
    if (FAILED(opened)) {
        placed.resource.Reset();
        free(placed.memory);
        return failed(opened, "không ánh xạ được tài nguyên");
    }
    placed.mapped = static_cast<std::byte*>(mapped);
    placed.address = placed.resource->GetGPUVirtualAddress();
    return placed;
}

Result<BufferHandle> D3d12Device::create_buffer(const BufferDesc& desc) {
    const Status checked = check_buffer(desc);
    if (!checked) return std::unexpected(checked.error());
    const bool map_cpu = desc.memory != MemoryDomain::kDevice;
    Result<Placed> placed = place(buffer_desc(desc), pool_of(desc.memory), nullptr, map_cpu);
    if (!placed) return std::unexpected(placed.error());
    Buffer buffer;
    buffer.resource = std::move(placed->resource);
    buffer.memory = placed->memory;
    buffer.size = desc.size;
    buffer.gpu_address = placed->address;
    buffer.usage = desc.usage;
    buffer.domain = desc.memory;
    buffer.mapped = placed->mapped;
    set_name(buffer.resource.Get(), desc.name);
    const BufferHandle handle = buffers_.insert(buffer);
    if (handle) return handle;
    discard(buffer);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng buffer");
}

Result<TextureHandle> D3d12Device::create_texture(const TextureDesc& desc) {
    const Status checked = check_texture(desc, caps_);
    if (!checked) return std::unexpected(checked.error());
    const D3D12_CLEAR_VALUE clear = clear_value(desc);
    const D3D12_CLEAR_VALUE* optimized = wants_clear(desc.usage) ? &clear : nullptr;
    Result<Placed> placed = place(texture_desc(desc), texture_pool(desc.usage), optimized, false);
    if (!placed) return std::unexpected(placed.error());
    Texture texture;
    texture.resource = std::move(placed->resource);
    texture.memory = placed->memory;
    texture.desc = desc;
    texture.desc.name = {};
    texture.is_owned = true;
    set_name(texture.resource.Get(), desc.name);
    const TextureHandle handle = textures_.insert(texture);
    if (handle) return handle;
    discard(texture);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng texture");
}

Result<TextureViewHandle> D3d12Device::create_view(const TextureViewDesc& desc) {
    const Texture* const texture = textures_.find(desc.texture);
    if (texture == nullptr) return fail(kBad, "view: texture đã chết");
    const core::Result<ViewRange> range = resolve_view(desc, texture->desc);
    if (!range) return std::unexpected(range.error());
    View view;
    view.texture = desc.texture;
    view.range = *range;
    view.width = mip_size(texture->desc.width, range->first_mip);
    view.height = mip_size(texture->desc.height, range->first_mip);
    view.samples = texture->desc.samples;
    const Status made = make_views(*this, view, *texture);
    if (!made) discard(view);
    if (!made) return std::unexpected(made.error());
    const TextureViewHandle handle = views_.insert(view);
    if (handle) return handle;
    discard(view);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng view");
}

Result<SamplerHandle> D3d12Device::create_sampler(const SamplerDesc& desc) {
    const auto most = static_cast<float>(caps_.max_anisotropy);
    const float anisotropy = std::clamp(static_cast<float>(desc.max_anisotropy), 1.0F, most);
    const std::optional<UINT> slot = allocate_sampler_staging();
    if (!slot) return fail(ErrorCode::kExhausted, "hết descriptor sampler");
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    D3D12_SAMPLER_DESC info{};
    info.Filter = to_filter(desc);
    info.AddressU = to_dxgi(desc.address_u);
    info.AddressV = to_dxgi(desc.address_v);
    info.AddressW = to_dxgi(desc.address_w);
    info.MipLODBias = desc.mip_bias;
    info.MaxAnisotropy = static_cast<UINT>(anisotropy);
    info.ComparisonFunc = to_dxgi(desc.compare);
    const std::array<float, 4> border = border_color(desc.border);
    const std::span<float, 4> slots(info.BorderColor);
    std::ranges::copy(border, slots.begin());
    info.MinLOD = desc.min_lod;
    info.MaxLOD = desc.max_lod;
    device_->CreateSampler(&info, sampler_staging_cpu(*slot));
    Sampler sampler;
    sampler.index = *slot;
    const SamplerHandle handle = samplers_.insert(sampler);
    if (handle) return handle;
    discard(sampler);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng sampler");
}

Result<QueryPoolHandle> D3d12Device::create_query_pool(const QueryPoolDesc& desc) {
    if (desc.count == 0) return fail(kBad, "query pool: count bằng 0");
    const bool is_occlusion = desc.kind == QueryKind::kOcclusion;
    if (is_occlusion && desc.queue != QueueType::kGraphics) {
        return fail(ErrorCode::kUnsupported, "occlusion chỉ có trên hàng Graphics");
    }
    const bool is_timestamp = desc.kind == QueryKind::kTimestamp;
    if (is_timestamp && !timestamps_ok(caps_, desc.queue)) {
        return fail(ErrorCode::kUnsupported, "hàng đợi không ghi được dấu thời gian");
    }
    QueryPool pool;
    pool.mutex = std::make_shared<std::mutex>();
    pool.kind = desc.kind;
    pool.type = is_occlusion ? D3D12_QUERY_TYPE_OCCLUSION : D3D12_QUERY_TYPE_TIMESTAMP;
    pool.count = desc.count;
    pool.queue = desc.queue;
    pool.ready_at.assign(desc.count, 0);
    pool.last_sync = D3D12_BARRIER_SYNC_NONE;
    pool.last_access = D3D12_BARRIER_ACCESS_NO_ACCESS;
    D3D12_QUERY_HEAP_DESC heap{};
    heap.Type = query_heap(caps_, desc);
    heap.Count = desc.count;
    const HRESULT created = device_->CreateQueryHeap(&heap, IID_PPV_ARGS(&pool.heap));
    if (FAILED(created)) return failed(created, "không tạo được query heap");
    const D3D12_RESOURCE_DESC buffer = query_readback(desc.count);
    Result<Placed> placed = place(buffer, PoolKind::kReadback, nullptr, true);
    if (!placed) pool.heap.Reset();
    if (!placed) return std::unexpected(placed.error());
    pool.readback = std::move(placed->resource);
    pool.memory = placed->memory;
    pool.mapped = placed->mapped;
    set_name(pool.heap.Get(), desc.name);
    const QueryPoolHandle handle = queries_.insert(pool);
    if (handle) return handle;
    discard(pool);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng query pool");
}

std::uint64_t D3d12Device::address(BufferHandle handle) const {
    const Buffer* const buffer = buffers_.find(handle);
    if (buffer == nullptr) return 0;
    if (!has(buffer->usage, BufferUsage::kAddress)) return 0;
    return buffer->gpu_address;
}

Status D3d12Device::write_buffer(BufferHandle handle, std::uint64_t offset, std::span<const std::byte> data) {
    const Buffer* const buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(kBad, "write_buffer: buffer đã chết");
    const bool is_writable = buffer->domain == MemoryDomain::kUpload && buffer->mapped != nullptr;
    if (!is_writable) return fail(kBad, "write_buffer: buffer không phải Upload");
    const Status inside = check_span(buffer->size, offset, data.size());
    if (!inside) return inside;
    const std::span<std::byte> mapped(buffer->mapped, buffer->size);
    std::ranges::copy(data, mapped.subspan(offset).begin());
    return ok();
}

Status D3d12Device::read_buffer(BufferHandle handle, std::uint64_t offset, std::span<std::byte> out) {
    const Buffer* const buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(kBad, "read_buffer: buffer đã chết");
    const bool is_readable = buffer->domain == MemoryDomain::kReadback && buffer->mapped != nullptr;
    if (!is_readable) return fail(kBad, "read_buffer: buffer không phải Readback");
    const Status inside = check_span(buffer->size, offset, out.size());
    if (!inside) return inside;
    const std::span<const std::byte> mapped(buffer->mapped, buffer->size);
    std::ranges::copy(mapped.subspan(offset, out.size()), out.begin());
    return ok();
}

Status D3d12Device::read_queries(QueryPoolHandle pool, std::uint32_t first, std::span<std::uint64_t> out) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    const QueryPool* const found = queries_.find(pool);
    if (found == nullptr) return fail(kBad, "read_queries: pool đã chết");
    const Status inside = check_span(found->count, first, out.size());
    if (!inside) return inside;
    if (out.empty()) return ok();
    return copy_raw(*this, *found, first, out);
}

} // namespace game::gpu::d3d12
