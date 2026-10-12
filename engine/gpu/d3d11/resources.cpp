// Tài nguyên D3D11: buffer, texture, view, sampler và query. Map trên immediate context.
// Constant Upload dùng DYNAMIC và WRITE_DISCARD; structured chờ stride lúc materialize.
// Khác gốc: không chép bgfx; heap và bind theo cờ gpu::BufferUsage.
#include "gpu/d3d11/device.hpp"

#include "core/error.hpp"
#include "gpu/check.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d11/hresult.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/slots.hpp"
#include "gpu/types.hpp"

#include <d3d11.h>
#include <d3dcommon.h>
#include <dxgiformat.h>
#include <unknwn.h> // IWYU pragma: keep
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gpu::d3d11 {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kMissing = ErrorCode::kUnsupported;
constexpr ErrorCode kOverflow = ErrorCode::kOverflow;
constexpr ErrorCode kExhausted = ErrorCode::kExhausted;
constexpr ErrorCode kBlock = ErrorCode::kWouldBlock;
constexpr ErrorCode kState = ErrorCode::kInvalidState;

using SrvDesc = D3D11_SHADER_RESOURCE_VIEW_DESC;
using RtvDesc = D3D11_RENDER_TARGET_VIEW_DESC;
using DsvDesc = D3D11_DEPTH_STENCIL_VIEW_DESC;
using UavDesc = D3D11_UNORDERED_ACCESS_VIEW_DESC;
using SrvPtr = ComPtr<ID3D11ShaderResourceView>;
using RtvPtr = ComPtr<ID3D11RenderTargetView>;
using DsvPtr = ComPtr<ID3D11DepthStencilView>;
using UavPtr = ComPtr<ID3D11UnorderedAccessView>;
using QueryPtr = ComPtr<ID3D11Query>;
using BufferPtr = ComPtr<ID3D11Buffer>;
using ResourcePtr = ComPtr<ID3D11Resource>;
using Mapped = D3D11_MAPPED_SUBRESOURCE;
using TexDesc = TextureDesc;

struct BufferPlan {
    D3D11_USAGE heap = D3D11_USAGE_DEFAULT;
    UINT bind = 0;
    UINT cpu = 0;
    UINT misc = 0;
    UINT width = 0;
    bool create = false;
    bool is_structured = false;
    bool keep_shadow = false;
    bool fits = false;
};

struct AlignAsk {
    UINT size = 0;
    UINT step = 1;
};

struct StrideAsk {
    std::uint64_t size = 0;
    std::uint32_t stride = 0;
};

struct ByteSpan {
    std::uint64_t offset = 0;
    std::span<const std::byte> data;
};

struct OutSpan {
    std::uint64_t offset = 0;
    std::span<std::byte> out;
};

struct Wide {
    std::uint64_t low = 0;
    std::uint64_t high = 0;
};

struct TickScale {
    std::uint64_t ticks = 0;
    std::uint64_t frequency = 0;
};

struct DivState {
    std::uint64_t rem = 0;
    std::uint64_t quot = 0;
    std::uint64_t low = 0;
    std::uint64_t divisor = 0;
    std::uint32_t bit = 63;
    bool done = false;
};

struct RawBuffer {
    const BufferPlan* plan = nullptr;
    std::string_view name;
    BufferPtr* out = nullptr;
};

struct MapTarget {
    D3d11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    Buffer* buffer = nullptr;
};

struct TexInfo {
    DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
    UINT bind = 0;
    UINT misc = 0;
    UINT samples = 1;
};

struct TexTarget {
    D3d11Device* device = nullptr;
    ResourcePtr* out = nullptr;
};

struct ViewSeed {
    const Texture* texture = nullptr;
    const ViewRange* range = nullptr;
    TextureHandle handle{};
};

struct ViewMake {
    D3d11Device* device = nullptr;
    View* view = nullptr;
    const Texture* texture = nullptr;
    TextureKind kind = TextureKind::kTex2D;
    ViewRange range{};
};

struct SrvBind {
    const SrvDesc* desc = nullptr;
    SrvPtr* out = nullptr;
};

struct UavBind {
    const UavDesc* desc = nullptr;
    UavPtr* out = nullptr;
};

struct RtvBind {
    const RtvDesc* desc = nullptr;
    RtvPtr* out = nullptr;
};

struct DsvBind {
    const DsvDesc* desc = nullptr;
    DsvPtr* out = nullptr;
};

struct SamplerAsk {
    const D3D11_SAMPLER_DESC* info = nullptr;
    std::string_view name;
    ComPtr<ID3D11SamplerState>* out = nullptr;
};

struct AnisoAsk {
    std::uint32_t asked = 1;
    std::uint32_t cap = 1;
};

struct QueryAsk {
    D3D11_QUERY type = D3D11_QUERY_TIMESTAMP;
    std::string_view name;
};

struct DisjointAsk {
    const QueryPoolDesc* desc = nullptr;
    QueryPool* pool = nullptr;
};

struct QueryFill {
    D3d11Device* device = nullptr;
    D3D11_QUERY type = D3D11_QUERY_TIMESTAMP;
    std::string_view name;
    std::uint32_t left = 0;
    std::vector<QueryPtr>* out = nullptr;
    Status error = ok();
};

struct QueryRead {
    QueryPool* pool = nullptr;
    std::uint32_t first = 0;
    std::span<std::uint64_t> out;
};

struct ClockOut {
    QueryPool* pool = nullptr;
    std::uint64_t* frequency = nullptr;
};

struct Pull {
    D3d11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    QueryPool* pool = nullptr;
    std::uint64_t frequency = 0;
    std::uint32_t cursor = 0;
    std::uint32_t end = 0;
    std::uint32_t first = 0;
    std::span<std::uint64_t> out;
    Status error = ok();
};

template <class T>
[[nodiscard]] core::Failure as_error(const core::Result<T>& result) {
    const core::Error& error = result.error();
    return std::unexpected(error);
}

template <class T, class Tag>
[[nodiscard]] bool kept(Slots<T, Tag>& slots, T& value, Handle<Tag>& handle) {
    handle = slots.insert(value);
    return static_cast<bool>(handle);
}

template <class T>
void retire_com(D3d11Device& device, ComPtr<T>& object) {
    // tidy bỏ sót unknwn.h.
    // NOLINTNEXTLINE(misc-include-cleaner)
    ComPtr<IUnknown> unknown;
    T* const raw = object.Detach();
    unknown.Attach(raw);
    device.retire(unknown);
}

void name_child(ID3D11DeviceChild* child, std::string_view name) noexcept {
    if (child == nullptr) return;
    set_debug_name(*child, name);
}

[[nodiscard]] Status fail_hr(D3d11Device& device, HRESULT code, core::Message message) {
    if (code_of(code) == ErrorCode::kDeviceLost) device.note_loss(code);
    return failed(code, message);
}

// 10^9 < 2^32 nên nửa cao của tích không tràn.
[[nodiscard]] Wide mul_billion(std::uint64_t ticks) noexcept {
    constexpr std::uint64_t kBillion = 1000000000ULL;
    const std::uint64_t low_part = ticks & 0xFFFFFFFFULL;
    const std::uint64_t high_part = ticks >> 32U;
    const std::uint64_t low_prod = low_part * kBillion;
    const std::uint64_t high_prod = high_part * kBillion;
    const std::uint64_t carry = low_prod >> 32U;
    const std::uint64_t mid = high_prod + carry;
    Wide out;
    out.low = (low_prod & 0xFFFFFFFFULL) | ((mid & 0xFFFFFFFFULL) << 32U);
    out.high = mid >> 32U;
    return out;
}

void step_div(DivState& state) noexcept {
    const unsigned shift = state.bit;
    const std::uint64_t incoming = (state.low >> shift) & 1ULL;
    const std::uint64_t half = std::numeric_limits<std::uint64_t>::max() >> 1U;
    const bool carry = state.rem > half;
    state.rem = (state.rem << 1U) | incoming;
    state.quot <<= 1U;
    const bool subtract = carry || state.rem >= state.divisor;
    if (subtract) state.rem -= state.divisor;
    if (subtract) state.quot |= 1ULL;
    if (state.bit == 0) state.done = true;
    if (state.bit != 0) --state.bit;
}

void run_div(DivState& state) noexcept {
    while (!state.done) {
        step_div(state);
    }
}

[[nodiscard]] std::uint64_t quotient(Wide product, std::uint64_t divisor) noexcept {
    DivState state;
    state.rem = product.high;
    state.low = product.low;
    state.divisor = divisor;
    run_div(state);
    return state.quot;
}

[[nodiscard]] bool scale_ns(TickScale scale, std::uint64_t& nanos) noexcept {
    if (scale.frequency == 0) return false;
    const Wide product = mul_billion(scale.ticks);
    if (product.high >= scale.frequency) return false;
    nanos = quotient(product, scale.frequency);
    return true;
}

[[nodiscard]] bool fit_uint(std::uint64_t size, UINT& out) noexcept {
    const UINT max_uint = std::numeric_limits<UINT>::max();
    const auto limit = static_cast<std::uint64_t>(max_uint);
    if (size > limit) return false;
    out = static_cast<UINT>(size);
    return true;
}

[[nodiscard]] UINT align_up(AlignAsk ask, bool& fits) noexcept {
    fits = false;
    if (ask.step == 0) return 0;
    const UINT rest = ask.size % ask.step;
    if (rest == 0) {
        fits = true;
        return ask.size;
    }
    const UINT limit = std::numeric_limits<UINT>::max();
    const UINT pad = ask.step - rest;
    if (ask.size > limit - pad) return 0;
    fits = true;
    return ask.size + pad;
}

[[nodiscard]] bool is_copy_upload(const BufferDesc& desc) noexcept {
    if (desc.memory != MemoryDomain::kUpload) return false;
    return has(desc.usage, BufferUsage::kCopySource);
}

[[nodiscard]] bool is_uniform_upload(const BufferDesc& desc) noexcept {
    if (desc.memory != MemoryDomain::kUpload) return false;
    if (has(desc.usage, BufferUsage::kCopySource)) return false;
    return has(desc.usage, BufferUsage::kUniform);
}

[[nodiscard]] Status reject_upload(const BufferDesc& desc) {
    const bool is_upload = desc.memory == MemoryDomain::kUpload;
    const bool is_uniform = has(desc.usage, BufferUsage::kUniform);
    const bool is_copy = has(desc.usage, BufferUsage::kCopySource);
    if (is_upload && is_uniform && is_copy) {
        return fail(kBad, "Upload không vừa là constant vừa là nguồn chép");
    }
    return ok();
}

[[nodiscard]] UINT bind_flags(BufferUsage usage) noexcept {
    UINT bind = 0;
    if (has(usage, BufferUsage::kVertex)) bind |= D3D11_BIND_VERTEX_BUFFER;
    if (has(usage, BufferUsage::kIndex)) bind |= D3D11_BIND_INDEX_BUFFER;
    if (has(usage, BufferUsage::kUniform)) bind |= D3D11_BIND_CONSTANT_BUFFER;
    if (has(usage, BufferUsage::kStorage)) bind |= D3D11_BIND_SHADER_RESOURCE;
    return bind;
}

[[nodiscard]] BufferPlan plan_readback(UINT size) noexcept {
    BufferPlan plan;
    plan.heap = D3D11_USAGE_STAGING;
    plan.cpu = D3D11_CPU_ACCESS_READ | D3D11_CPU_ACCESS_WRITE;
    plan.width = size;
    plan.create = true;
    plan.fits = true;
    return plan;
}

[[nodiscard]] BufferPlan plan_staging(UINT size) noexcept {
    BufferPlan plan;
    plan.heap = D3D11_USAGE_STAGING;
    plan.cpu = D3D11_CPU_ACCESS_WRITE;
    plan.width = size;
    plan.create = true;
    plan.keep_shadow = true;
    plan.fits = true;
    return plan;
}

[[nodiscard]] BufferPlan plan_constant(UINT size) noexcept {
    BufferPlan plan;
    plan.heap = D3D11_USAGE_DYNAMIC;
    plan.bind = D3D11_BIND_CONSTANT_BUFFER;
    plan.cpu = D3D11_CPU_ACCESS_WRITE;
    plan.create = true;
    plan.keep_shadow = true;
    AlignAsk ask;
    ask.size = size;
    ask.step = 16;
    bool fits = false;
    plan.width = align_up(ask, fits);
    plan.fits = fits;
    return plan;
}

[[nodiscard]] BufferPlan plan_structured(MemoryDomain domain) noexcept {
    BufferPlan plan;
    plan.heap = D3D11_USAGE_DEFAULT;
    plan.is_structured = true;
    plan.fits = true;
    if (domain == MemoryDomain::kUpload) {
        plan.heap = D3D11_USAGE_DYNAMIC;
        plan.keep_shadow = true;
    }
    return plan;
}

[[nodiscard]] BufferPlan plan_generic(const BufferDesc& desc, UINT size) noexcept {
    BufferPlan plan;
    plan.heap = D3D11_USAGE_DEFAULT;
    plan.bind = bind_flags(desc.usage);
    plan.width = size;
    plan.create = true;
    plan.fits = true;
    if (desc.memory == MemoryDomain::kUpload) {
        plan.heap = D3D11_USAGE_DYNAMIC;
        plan.cpu = D3D11_CPU_ACCESS_WRITE;
        plan.keep_shadow = true;
    }
    if (has(desc.usage, BufferUsage::kUniform)) {
        AlignAsk ask;
        ask.size = size;
        ask.step = 16;
        bool fits = false;
        plan.width = align_up(ask, fits);
        plan.fits = fits;
    }
    if (has(desc.usage, BufferUsage::kIndirect)) {
        plan.misc = D3D11_RESOURCE_MISC_DRAWINDIRECT_ARGS;
    }
    return plan;
}

[[nodiscard]] BufferPlan plan_for(const BufferDesc& desc, UINT size) noexcept {
    if (desc.memory == MemoryDomain::kReadback) return plan_readback(size);
    if (is_copy_upload(desc)) return plan_staging(size);
    if (is_uniform_upload(desc)) return plan_constant(size);
    if (has(desc.usage, BufferUsage::kStorage)) return plan_structured(desc.memory);
    return plan_generic(desc, size);
}

[[nodiscard]] Status check_dynamic(const BufferPlan& plan) {
    if (!plan.create) return ok();
    if (plan.heap != D3D11_USAGE_DYNAMIC) return ok();
    if (plan.bind != 0) return ok();
    return fail(kBad, "buffer động không có cờ bind");
}

void apply_plan(Buffer& buffer, const BufferDesc& desc, const BufferPlan& plan) {
    buffer.size = desc.size;
    buffer.usage = desc.usage;
    buffer.domain = desc.memory;
    buffer.heap = plan.heap;
    buffer.is_structured = plan.is_structured;
    buffer.stride = 0;
    if (!plan.keep_shadow) return;
    const auto bytes = static_cast<std::size_t>(desc.size);
    buffer.shadow.resize(bytes);
}

[[nodiscard]] Status create_raw_buffer(D3d11Device& device, const RawBuffer& raw) {
    if (!raw.plan->create) return ok();
    D3D11_BUFFER_DESC info{};
    info.ByteWidth = raw.plan->width;
    info.Usage = raw.plan->heap;
    info.BindFlags = raw.plan->bind;
    info.CPUAccessFlags = raw.plan->cpu;
    info.MiscFlags = raw.plan->misc;
    ID3D11Device* const hardware = device.device();
    ID3D11Buffer** const slot = raw.out->GetAddressOf();
    const HRESULT created = hardware->CreateBuffer(&info, nullptr, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được buffer");
    ID3D11Buffer* const named = raw.out->Get();
    name_child(named, raw.name);
    return ok();
}

[[nodiscard]] bool structured_width(StrideAsk ask, UINT& width) noexcept {
    UINT bytes = 0;
    if (!fit_uint(ask.size, bytes)) return false;
    if (ask.stride == 0) return false;
    AlignAsk align;
    align.size = bytes;
    align.step = ask.stride;
    bool fits = false;
    width = align_up(align, fits);
    return fits;
}

[[nodiscard]] Status create_structured(D3d11Device& device, Buffer& buffer, std::uint32_t stride) {
    StrideAsk ask;
    ask.size = buffer.size;
    ask.stride = stride;
    UINT width = 0;
    const bool fitted = structured_width(ask, width);
    if (!fitted) return fail(kOverflow, "ByteWidth structured tràn");
    D3D11_BUFFER_DESC info{};
    info.ByteWidth = width;
    info.Usage = D3D11_USAGE_DEFAULT;
    info.BindFlags = D3D11_BIND_SHADER_RESOURCE;
    info.MiscFlags = D3D11_RESOURCE_MISC_BUFFER_STRUCTURED;
    info.StructureByteStride = stride;
    if (buffer.domain == MemoryDomain::kUpload) {
        info.Usage = D3D11_USAGE_DYNAMIC;
        info.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
    }
    buffer.heap = info.Usage;
    ID3D11Device* const hardware = device.device();
    ID3D11Buffer** const slot = buffer.resource.GetAddressOf();
    const HRESULT created = hardware->CreateBuffer(&info, nullptr, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được buffer structured");
    return ok();
}

void drop_resource(D3d11Device& device, Buffer& buffer) {
    if (buffer.resource == nullptr) return;
    retire_com(device, buffer.resource);
}

[[nodiscard]] ComPtr<ID3D11DeviceContext> immediate_context(const D3d11Device& device) {
    ComPtr<ID3D11DeviceContext> context;
    ID3D11Device* const hardware = device.device();
    ID3D11DeviceContext** const slot = context.GetAddressOf();
    hardware->GetImmediateContext(slot);
    return context;
}

[[nodiscard]] Status open_map(const MapTarget& target, D3D11_MAP mode, Mapped& mapped) {
    ID3D11Buffer* const resource = target.buffer->resource.Get();
    const HRESULT opened = target.context->Map(resource, 0, mode, 0, &mapped);
    if (FAILED(opened)) return fail_hr(*target.device, opened, "không ánh xạ được buffer");
    return ok();
}

void copy_bytes(void* dest, const std::vector<std::byte>& data) noexcept {
    auto* const target = static_cast<std::byte*>(dest);
    const std::byte* const source = data.data();
    const std::size_t bytes = data.size();
    std::memcpy(target, source, bytes);
}

[[nodiscard]] Status discard_mapped(const MapTarget& target) {
    D3D11_MAPPED_SUBRESOURCE mapped{};
    const Status opened = open_map(target, D3D11_MAP_WRITE_DISCARD, mapped);
    if (!opened) return opened;
    copy_bytes(mapped.pData, target.buffer->shadow);
    ID3D11Buffer* const resource = target.buffer->resource.Get();
    target.context->Unmap(resource, 0);
    return ok();
}

// DISCARD bỏ phần chưa ghi nên phải chép cả shadow.
[[nodiscard]] Status map_discard(D3d11Device& device, Buffer& buffer) {
    ImmediateGuard guard = device.lock_immediate();
    MapTarget target;
    target.device = &device;
    target.context = &guard.context();
    target.buffer = &buffer;
    return discard_mapped(target);
}

void copy_at(void* dest, std::uint64_t size, ByteSpan span) noexcept {
    if (span.data.empty()) return;
    const auto bytes = static_cast<std::size_t>(size);
    auto* const base = static_cast<std::byte*>(dest);
    const std::span<std::byte> whole(base, bytes);
    const auto start = static_cast<std::size_t>(span.offset);
    const std::size_t count = span.data.size();
    const std::span<std::byte> slot = whole.subspan(start, count);
    std::byte* const target = slot.data();
    const std::byte* const source = span.data.data();
    std::memcpy(target, source, count);
}

[[nodiscard]] Status write_mapped(const MapTarget& target, ByteSpan span) {
    D3D11_MAPPED_SUBRESOURCE mapped{};
    const Status opened = open_map(target, D3D11_MAP_WRITE, mapped);
    if (!opened) return opened;
    copy_at(mapped.pData, target.buffer->size, span);
    ID3D11Buffer* const resource = target.buffer->resource.Get();
    target.context->Unmap(resource, 0);
    return ok();
}

[[nodiscard]] Status map_at(D3d11Device& device, Buffer& buffer, ByteSpan span) {
    ImmediateGuard guard = device.lock_immediate();
    MapTarget target;
    target.device = &device;
    target.context = &guard.context();
    target.buffer = &buffer;
    return write_mapped(target, span);
}

void copy_span(std::vector<std::byte>& dest, ByteSpan span) noexcept {
    if (span.data.empty()) return;
    std::byte* const base = dest.data();
    const std::size_t bytes = dest.size();
    const std::span<std::byte> whole(base, bytes);
    const auto start = static_cast<std::size_t>(span.offset);
    const std::size_t count = span.data.size();
    const std::span<std::byte> slot = whole.subspan(start, count);
    std::byte* const target = slot.data();
    const std::byte* const source = span.data.data();
    std::memcpy(target, source, count);
}

void ensure_shadow(Buffer& buffer) {
    if (!buffer.shadow.empty()) return;
    const auto bytes = static_cast<std::size_t>(buffer.size);
    buffer.shadow.resize(bytes);
}

[[nodiscard]] Status write_upload(D3d11Device& device, Buffer& buffer, ByteSpan span) {
    ensure_shadow(buffer);
    copy_span(buffer.shadow, span);
    if (buffer.resource == nullptr) return ok();
    if (buffer.heap == D3D11_USAGE_DYNAMIC) return map_discard(device, buffer);
    if (buffer.heap == D3D11_USAGE_STAGING) return map_at(device, buffer, span);
    return ok();
}

void copy_out(const void* source, std::uint64_t size, OutSpan span) noexcept {
    if (span.out.empty()) return;
    const auto bytes = static_cast<std::size_t>(size);
    const auto* const base = static_cast<const std::byte*>(source);
    const std::span<const std::byte> whole(base, bytes);
    const auto start = static_cast<std::size_t>(span.offset);
    const std::size_t count = span.out.size();
    const std::span<const std::byte> slot = whole.subspan(start, count);
    std::byte* const target = span.out.data();
    const std::byte* const from = slot.data();
    std::memcpy(target, from, count);
}

[[nodiscard]] Status read_mapped(D3d11Device& device, Buffer& buffer, OutSpan span) {
    ImmediateGuard guard = device.lock_immediate();
    MapTarget target;
    target.device = &device;
    target.context = &guard.context();
    target.buffer = &buffer;
    D3D11_MAPPED_SUBRESOURCE mapped{};
    const Status opened = open_map(target, D3D11_MAP_READ, mapped);
    if (!opened) return opened;
    copy_out(mapped.pData, buffer.size, span);
    ID3D11Buffer* const resource = buffer.resource.Get();
    target.context->Unmap(resource, 0);
    return ok();
}

[[nodiscard]] Status upload_if_needed(D3d11Device& device, Buffer& buffer) {
    if (buffer.shadow.empty()) return ok();
    if (buffer.domain != MemoryDomain::kUpload) return ok();
    // Người gọi đang giữ khoá immediate: không khoá lại.
    const ComPtr<ID3D11DeviceContext> context = immediate_context(device);
    if (context == nullptr) return fail(kState, "không có immediate context");
    MapTarget target;
    target.device = &device;
    target.context = context.Get();
    target.buffer = &buffer;
    return discard_mapped(target);
}

[[nodiscard]] bool needs_typeless(const TextureDesc& desc) noexcept {
    const bool depth_sampled =
        has(desc.usage, TextureUsage::kDepthStencilTarget) && has(desc.usage, TextureUsage::kSampled);
    if (depth_sampled) return true;
    return has(desc.usage, TextureUsage::kReinterpret);
}

[[nodiscard]] DXGI_FORMAT texture_format(const TextureDesc& desc) noexcept {
    const DXGI_FORMAT typed = to_dxgi(desc.format);
    if (!needs_typeless(desc)) return typed;
    return typeless_format(typed);
}

[[nodiscard]] Status require_format(const TextureDesc& desc, DXGI_FORMAT format) {
    if (!needs_typeless(desc)) return ok();
    if (format != DXGI_FORMAT_UNKNOWN) return ok();
    return fail(kMissing, "không có định dạng typeless");
}

[[nodiscard]] Status check_msaa(D3d11Device& device, DXGI_FORMAT format, std::uint32_t samples) {
    if (samples <= 1) return ok();
    UINT levels = 0;
    ID3D11Device* const hardware = device.device();
    const HRESULT checked = hardware->CheckMultisampleQualityLevels(format, samples, &levels);
    if (FAILED(checked)) return fail_hr(device, checked, "không hỏi được đa mẫu");
    if (levels == 0) return fail(kMissing, "đa mẫu không được hỗ trợ");
    return ok();
}

[[nodiscard]] UINT texture_bind(TextureUsage usage) noexcept {
    UINT bind = 0;
    if (has(usage, TextureUsage::kSampled)) bind |= D3D11_BIND_SHADER_RESOURCE;
    if (has(usage, TextureUsage::kStorage)) bind |= D3D11_BIND_UNORDERED_ACCESS;
    if (has(usage, TextureUsage::kColorTarget)) bind |= D3D11_BIND_RENDER_TARGET;
    if (has(usage, TextureUsage::kDepthStencilTarget)) bind |= D3D11_BIND_DEPTH_STENCIL;
    return bind;
}

[[nodiscard]] UINT cube_misc(TextureKind kind) noexcept {
    const bool is_cube = kind == TextureKind::kCube || kind == TextureKind::kCubeArray;
    if (!is_cube) return 0;
    return D3D11_RESOURCE_MISC_TEXTURECUBE;
}

[[nodiscard]] UINT array_size(const TextureDesc& desc) noexcept {
    if (desc.kind == TextureKind::kTex2D) return 1;
    return desc.depth_or_layers;
}

[[nodiscard]] Status create_3d(const TexTarget& target, const TexDesc& desc, const TexInfo& info) {
    D3D11_TEXTURE3D_DESC native{};
    native.Width = desc.width;
    native.Height = desc.height;
    native.Depth = desc.depth_or_layers;
    native.MipLevels = desc.mip_levels;
    native.Format = info.format;
    native.Usage = D3D11_USAGE_DEFAULT;
    native.BindFlags = info.bind;
    ComPtr<ID3D11Texture3D> made;
    ID3D11Texture3D** const slot = made.GetAddressOf();
    ID3D11Device* const hardware = target.device->device();
    const HRESULT created = hardware->CreateTexture3D(&native, nullptr, slot);
    if (FAILED(created)) return fail_hr(*target.device, created, "không tạo được texture 3D");
    ID3D11Resource* const raw = made.Detach();
    target.out->Attach(raw);
    return ok();
}

[[nodiscard]] Status create_1d(const TexTarget& target, const TexDesc& desc, const TexInfo& info) {
    D3D11_TEXTURE1D_DESC native{};
    native.Width = desc.width;
    native.MipLevels = desc.mip_levels;
    native.ArraySize = desc.depth_or_layers;
    native.Format = info.format;
    native.Usage = D3D11_USAGE_DEFAULT;
    native.BindFlags = info.bind;
    native.MiscFlags = info.misc;
    ComPtr<ID3D11Texture1D> made;
    ID3D11Texture1D** const slot = made.GetAddressOf();
    ID3D11Device* const hardware = target.device->device();
    const HRESULT created = hardware->CreateTexture1D(&native, nullptr, slot);
    if (FAILED(created)) return fail_hr(*target.device, created, "không tạo được texture 1D");
    ID3D11Resource* const raw = made.Detach();
    target.out->Attach(raw);
    return ok();
}

[[nodiscard]] Status create_2d(const TexTarget& target, const TexDesc& desc, const TexInfo& info) {
    D3D11_TEXTURE2D_DESC native{};
    native.Width = desc.width;
    native.Height = desc.height;
    native.MipLevels = desc.mip_levels;
    native.ArraySize = array_size(desc);
    native.Format = info.format;
    native.SampleDesc.Count = info.samples;
    native.SampleDesc.Quality = 0;
    native.Usage = D3D11_USAGE_DEFAULT;
    native.BindFlags = info.bind;
    native.MiscFlags = info.misc;
    ComPtr<ID3D11Texture2D> made;
    ID3D11Texture2D** const slot = made.GetAddressOf();
    ID3D11Device* const hardware = target.device->device();
    const HRESULT created = hardware->CreateTexture2D(&native, nullptr, slot);
    if (FAILED(created)) return fail_hr(*target.device, created, "không tạo được texture 2D");
    ID3D11Resource* const raw = made.Detach();
    target.out->Attach(raw);
    return ok();
}

[[nodiscard]] Status create_tex(const TexTarget& target, const TexDesc& desc, const TexInfo& info) {
    if (desc.kind == TextureKind::kTex3D) return create_3d(target, desc, info);
    if (desc.kind == TextureKind::kTex1D) return create_1d(target, desc, info);
    return create_2d(target, desc, info);
}

void store_texture(Texture& texture, const TextureDesc& desc, ResourcePtr& resource) {
    ID3D11Resource* const raw = resource.Detach();
    texture.resource.Attach(raw);
    texture.format = desc.format;
    texture.kind = desc.kind;
    texture.usage = desc.usage;
    texture.width = desc.width;
    texture.height = desc.height;
    texture.depth_or_layers = desc.depth_or_layers;
    texture.mip_levels = desc.mip_levels;
    texture.samples = desc.samples;
    texture.is_owned = true;
}

void fill_view(View& view, const ViewSeed& seed) noexcept {
    const ViewRange& range = *seed.range;
    view.texture = seed.handle;
    view.format = range.format;
    view.aspect = range.aspect;
    view.width = mip_size(seed.texture->width, range.first_mip);
    view.height = mip_size(seed.texture->height, range.first_mip);
    view.samples = seed.texture->samples;
    view.first_mip = range.first_mip;
    view.mip_count = range.mip_count;
    view.first_layer = range.first_layer;
    view.layer_count = range.layer_count;
}

[[nodiscard]] DXGI_FORMAT srv_dxgi(const Texture& texture, const ViewRange& range) noexcept {
    if (has_depth(texture.format)) return depth_srv_format(texture.format, range.aspect);
    return to_dxgi(range.format);
}

// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access)
[[nodiscard]] bool fill_srv_1d(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1D.MostDetailedMip = range.first_mip;
    desc.Texture1D.MipLevels = range.mip_count;
    return true;
}

[[nodiscard]] bool fill_srv_1d_array(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1DArray.MostDetailedMip = range.first_mip;
    desc.Texture1DArray.MipLevels = range.mip_count;
    desc.Texture1DArray.FirstArraySlice = range.first_layer;
    desc.Texture1DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_srv_2d(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2D.MostDetailedMip = range.first_mip;
    desc.Texture2D.MipLevels = range.mip_count;
    return true;
}

[[nodiscard]] bool fill_srv_2d_array(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DArray.MostDetailedMip = range.first_mip;
    desc.Texture2DArray.MipLevels = range.mip_count;
    desc.Texture2DArray.FirstArraySlice = range.first_layer;
    desc.Texture2DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_srv_2dms(SrvDesc& desc) noexcept {
    desc.Texture2DMS.UnusedField_NothingToDefine = 0;
    return true;
}

[[nodiscard]] bool fill_srv_2dms_array(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
    desc.Texture2DMSArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_srv_3d(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture3D.MostDetailedMip = range.first_mip;
    desc.Texture3D.MipLevels = range.mip_count;
    return true;
}

[[nodiscard]] bool fill_srv_cube(SrvDesc& desc, const ViewRange& range) noexcept {
    desc.TextureCube.MostDetailedMip = range.first_mip;
    desc.TextureCube.MipLevels = range.mip_count;
    return true;
}

[[nodiscard]] bool fill_srv_cube_array(SrvDesc& desc, const ViewRange& range) noexcept {
    const UINT cubes = range.layer_count / 6U;
    if (cubes == 0) return false;
    desc.TextureCubeArray.MostDetailedMip = range.first_mip;
    desc.TextureCubeArray.MipLevels = range.mip_count;
    desc.TextureCubeArray.First2DArrayFace = range.first_layer;
    desc.TextureCubeArray.NumCubes = cubes;
    return true;
}

[[nodiscard]] bool fill_srv(SrvDesc& desc, const ViewRange& range) noexcept {
    switch (desc.ViewDimension) {
    case D3D11_SRV_DIMENSION_TEXTURE1D: return fill_srv_1d(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURE1DARRAY: return fill_srv_1d_array(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURE2D: return fill_srv_2d(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURE2DARRAY: return fill_srv_2d_array(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURE2DMS: return fill_srv_2dms(desc);
    case D3D11_SRV_DIMENSION_TEXTURE2DMSARRAY: return fill_srv_2dms_array(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURE3D: return fill_srv_3d(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURECUBE: return fill_srv_cube(desc, range);
    case D3D11_SRV_DIMENSION_TEXTURECUBEARRAY: return fill_srv_cube_array(desc, range);
    case D3D11_SRV_DIMENSION_UNKNOWN:
    case D3D11_SRV_DIMENSION_BUFFER:
    case D3D11_SRV_DIMENSION_BUFFEREX: return false;
    }
    return false;
}

[[nodiscard]] bool fill_uav_1d(UavDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_uav_1d_array(UavDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1DArray.MipSlice = range.first_mip;
    desc.Texture1DArray.FirstArraySlice = range.first_layer;
    desc.Texture1DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_uav_2d(UavDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_uav_2d_array(UavDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DArray.MipSlice = range.first_mip;
    desc.Texture2DArray.FirstArraySlice = range.first_layer;
    desc.Texture2DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_uav_3d(UavDesc& desc, const ViewRange& range, UINT depth) noexcept {
    desc.Texture3D.MipSlice = range.first_mip;
    desc.Texture3D.FirstWSlice = 0;
    desc.Texture3D.WSize = mip_size(depth, range.first_mip);
    return true;
}

[[nodiscard]] bool fill_uav(UavDesc& desc, const ViewRange& range, UINT depth) noexcept {
    switch (desc.ViewDimension) {
    case D3D11_UAV_DIMENSION_TEXTURE1D: return fill_uav_1d(desc, range);
    case D3D11_UAV_DIMENSION_TEXTURE1DARRAY: return fill_uav_1d_array(desc, range);
    case D3D11_UAV_DIMENSION_TEXTURE2D: return fill_uav_2d(desc, range);
    case D3D11_UAV_DIMENSION_TEXTURE2DARRAY: return fill_uav_2d_array(desc, range);
    case D3D11_UAV_DIMENSION_TEXTURE3D: return fill_uav_3d(desc, range, depth);
    case D3D11_UAV_DIMENSION_UNKNOWN:
    case D3D11_UAV_DIMENSION_BUFFER: return false;
    }
    return false;
}

[[nodiscard]] bool fill_rtv_1d(RtvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_rtv_1d_array(RtvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1DArray.MipSlice = range.first_mip;
    desc.Texture1DArray.FirstArraySlice = range.first_layer;
    desc.Texture1DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_rtv_2d(RtvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_rtv_2d_array(RtvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DArray.MipSlice = range.first_mip;
    desc.Texture2DArray.FirstArraySlice = range.first_layer;
    desc.Texture2DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_rtv_2dms(RtvDesc& desc) noexcept {
    desc.Texture2DMS.UnusedField_NothingToDefine = 0;
    return true;
}

[[nodiscard]] bool fill_rtv_2dms_array(RtvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
    desc.Texture2DMSArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_rtv_3d(RtvDesc& desc, const ViewRange& range, UINT depth) noexcept {
    desc.Texture3D.MipSlice = range.first_mip;
    desc.Texture3D.FirstWSlice = 0;
    desc.Texture3D.WSize = mip_size(depth, range.first_mip);
    return true;
}

[[nodiscard]] bool fill_rtv(RtvDesc& desc, const ViewRange& range, UINT depth) noexcept {
    switch (desc.ViewDimension) {
    case D3D11_RTV_DIMENSION_TEXTURE1D: return fill_rtv_1d(desc, range);
    case D3D11_RTV_DIMENSION_TEXTURE1DARRAY: return fill_rtv_1d_array(desc, range);
    case D3D11_RTV_DIMENSION_TEXTURE2D: return fill_rtv_2d(desc, range);
    case D3D11_RTV_DIMENSION_TEXTURE2DARRAY: return fill_rtv_2d_array(desc, range);
    case D3D11_RTV_DIMENSION_TEXTURE2DMS: return fill_rtv_2dms(desc);
    case D3D11_RTV_DIMENSION_TEXTURE2DMSARRAY: return fill_rtv_2dms_array(desc, range);
    case D3D11_RTV_DIMENSION_TEXTURE3D: return fill_rtv_3d(desc, range, depth);
    case D3D11_RTV_DIMENSION_UNKNOWN:
    case D3D11_RTV_DIMENSION_BUFFER: return false;
    }
    return false;
}

[[nodiscard]] bool fill_dsv_1d(DsvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_dsv_1d_array(DsvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture1DArray.MipSlice = range.first_mip;
    desc.Texture1DArray.FirstArraySlice = range.first_layer;
    desc.Texture1DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_dsv_2d(DsvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2D.MipSlice = range.first_mip;
    return true;
}

[[nodiscard]] bool fill_dsv_2d_array(DsvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DArray.MipSlice = range.first_mip;
    desc.Texture2DArray.FirstArraySlice = range.first_layer;
    desc.Texture2DArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_dsv_2dms(DsvDesc& desc) noexcept {
    desc.Texture2DMS.UnusedField_NothingToDefine = 0;
    return true;
}

[[nodiscard]] bool fill_dsv_2dms_array(DsvDesc& desc, const ViewRange& range) noexcept {
    desc.Texture2DMSArray.FirstArraySlice = range.first_layer;
    desc.Texture2DMSArray.ArraySize = range.layer_count;
    return true;
}

[[nodiscard]] bool fill_dsv(DsvDesc& desc, const ViewRange& range) noexcept {
    switch (desc.ViewDimension) {
    case D3D11_DSV_DIMENSION_TEXTURE1D: return fill_dsv_1d(desc, range);
    case D3D11_DSV_DIMENSION_TEXTURE1DARRAY: return fill_dsv_1d_array(desc, range);
    case D3D11_DSV_DIMENSION_TEXTURE2D: return fill_dsv_2d(desc, range);
    case D3D11_DSV_DIMENSION_TEXTURE2DARRAY: return fill_dsv_2d_array(desc, range);
    case D3D11_DSV_DIMENSION_TEXTURE2DMS: return fill_dsv_2dms(desc);
    case D3D11_DSV_DIMENSION_TEXTURE2DMSARRAY: return fill_dsv_2dms_array(desc, range);
    case D3D11_DSV_DIMENSION_UNKNOWN: return false;
    }
    return false;
}
// NOLINTEND(cppcoreguidelines-pro-type-union-access)
[[nodiscard]] Status create_srv(D3d11Device& device, const Texture& texture, SrvBind bind) {
    ID3D11Device* const hardware = device.device();
    ID3D11Resource* const resource = texture.resource.Get();
    ID3D11ShaderResourceView** const slot = bind.out->GetAddressOf();
    const HRESULT created = hardware->CreateShaderResourceView(resource, bind.desc, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được SRV");
    return ok();
}

[[nodiscard]] Status create_uav(D3d11Device& device, const Texture& texture, UavBind bind) {
    ID3D11Device* const hardware = device.device();
    ID3D11Resource* const resource = texture.resource.Get();
    ID3D11UnorderedAccessView** const slot = bind.out->GetAddressOf();
    const HRESULT created = hardware->CreateUnorderedAccessView(resource, bind.desc, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được UAV");
    return ok();
}

[[nodiscard]] Status create_rtv(D3d11Device& device, const Texture& texture, RtvBind bind) {
    ID3D11Device* const hardware = device.device();
    ID3D11Resource* const resource = texture.resource.Get();
    ID3D11RenderTargetView** const slot = bind.out->GetAddressOf();
    const HRESULT created = hardware->CreateRenderTargetView(resource, bind.desc, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được RTV");
    return ok();
}

[[nodiscard]] Status create_dsv(D3d11Device& device, const Texture& texture, DsvBind bind) {
    ID3D11Device* const hardware = device.device();
    ID3D11Resource* const resource = texture.resource.Get();
    ID3D11DepthStencilView** const slot = bind.out->GetAddressOf();
    const HRESULT created = hardware->CreateDepthStencilView(resource, bind.desc, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được DSV");
    return ok();
}

[[nodiscard]] Status make_srv(const ViewMake& made) {
    const TextureUsage usage = made.texture->usage;
    if (!has(usage, TextureUsage::kSampled)) return ok();
    const DXGI_FORMAT format = srv_dxgi(*made.texture, made.range);
    if (format == DXGI_FORMAT_UNKNOWN) return ok();
    SrvDesc info{};
    info.Format = format;
    info.ViewDimension = to_srv(made.kind, made.texture->samples);
    const bool filled = fill_srv(info, made.range);
    if (!filled) return fail(kMissing, "view SRV không dựng được");
    SrvBind bind;
    bind.desc = &info;
    bind.out = &made.view->srv;
    return create_srv(*made.device, *made.texture, bind);
}

[[nodiscard]] Status make_uav(const ViewMake& made) {
    const TextureUsage usage = made.texture->usage;
    if (!has(usage, TextureUsage::kStorage)) return ok();
    if (made.range.mip_count != 1) return fail(kBad, "view UAV chỉ một mức mip");
    if (made.texture->samples != 1) return fail(kMissing, "UAV đa mẫu không có");
    UavDesc info{};
    info.Format = to_dxgi(made.range.format);
    info.ViewDimension = to_uav(made.kind);
    const UINT depth = made.texture->depth_or_layers;
    const bool filled = fill_uav(info, made.range, depth);
    if (!filled) return fail(kMissing, "view UAV không dựng được");
    UavBind bind;
    bind.desc = &info;
    bind.out = &made.view->uav;
    return create_uav(*made.device, *made.texture, bind);
}

[[nodiscard]] Status make_rtv(const ViewMake& made) {
    const TextureUsage usage = made.texture->usage;
    if (!has(usage, TextureUsage::kColorTarget)) return ok();
    if (made.range.mip_count != 1) return fail(kBad, "view đích chỉ một mức mip");
    RtvDesc info{};
    info.Format = to_dxgi(made.range.format);
    info.ViewDimension = to_rtv(made.kind, made.texture->samples);
    const UINT depth = made.texture->depth_or_layers;
    const bool filled = fill_rtv(info, made.range, depth);
    if (!filled) return fail(kMissing, "view RTV không dựng được");
    RtvBind bind;
    bind.desc = &info;
    bind.out = &made.view->rtv;
    return create_rtv(*made.device, *made.texture, bind);
}

[[nodiscard]] Status make_one_dsv(const ViewMake& made, UINT flags, DsvPtr& out) {
    DsvDesc info{};
    info.Format = to_dxgi(made.range.format);
    info.ViewDimension = to_dsv(made.kind, made.texture->samples);
    info.Flags = flags;
    const bool filled = fill_dsv(info, made.range);
    if (!filled) return fail(kMissing, "view DSV không dựng được");
    DsvBind bind;
    bind.desc = &info;
    bind.out = &out;
    return create_dsv(*made.device, *made.texture, bind);
}

[[nodiscard]] Status make_dsv_pair(const ViewMake& made) {
    const TextureUsage usage = made.texture->usage;
    if (!has(usage, TextureUsage::kDepthStencilTarget)) return ok();
    if (made.range.mip_count != 1) return fail(kBad, "view đích chỉ một mức mip");
    const Status depth = make_one_dsv(made, 0, made.view->dsv);
    if (!depth) return depth;
    // READ_ONLY_STENCIL trên D16/D32 (không có stencil) không hợp lệ với view chỉ đọc.
    UINT read_only = D3D11_DSV_READ_ONLY_DEPTH;
    const bool has_stencil = info(made.range.format).aspect == FormatAspect::kDepthStencil;
    if (has_stencil) read_only |= D3D11_DSV_READ_ONLY_STENCIL;
    return make_one_dsv(made, read_only, made.view->dsv_read);
}

[[nodiscard]] Status make_views(const ViewMake& made) {
    const Status sampled = make_srv(made);
    if (!sampled) return sampled;
    const Status stored = make_uav(made);
    if (!stored) return stored;
    const Status color = make_rtv(made);
    if (!color) return color;
    return make_dsv_pair(made);
}

void name_view(const View& view, std::string_view name) noexcept {
    ID3D11DeviceChild* const sampled = view.srv.Get();
    name_child(sampled, name);
    ID3D11DeviceChild* const target = view.rtv.Get();
    name_child(target, name);
    ID3D11DeviceChild* const depth = view.dsv.Get();
    name_child(depth, name);
    ID3D11DeviceChild* const read_only = view.dsv_read.Get();
    name_child(read_only, name);
    ID3D11DeviceChild* const stored = view.uav.Get();
    name_child(stored, name);
}

void release_view(D3d11Device& device, View& view) {
    retire_com(device, view.srv);
    retire_com(device, view.rtv);
    retire_com(device, view.dsv);
    retire_com(device, view.dsv_read);
    retire_com(device, view.uav);
}

[[nodiscard]] UINT clamp_anisotropy(AnisoAsk ask) noexcept {
    const std::uint32_t least = std::max(ask.asked, 1U);
    const std::uint32_t most = std::max(ask.cap, 1U);
    return std::min(least, most);
}

void apply_border(D3D11_SAMPLER_DESC& info, BorderColor border) noexcept {
    const float alpha = border == BorderColor::kTransparentBlack ? 0.0F : 1.0F;
    const float color = border == BorderColor::kOpaqueWhite ? 1.0F : 0.0F;
    const std::array<float, 4> channels{color, color, color, alpha};
    const std::span<float> dest(info.BorderColor);
    const float* const from = channels.data();
    float* const target = dest.data();
    const std::size_t count = channels.size();
    const std::size_t bytes = sizeof(float) * count;
    std::memcpy(target, from, bytes);
}

[[nodiscard]] Status create_sampler_state(D3d11Device& device, const SamplerAsk& ask) {
    ID3D11Device* const hardware = device.device();
    ID3D11SamplerState** const slot = ask.out->GetAddressOf();
    const HRESULT created = hardware->CreateSamplerState(ask.info, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được sampler");
    ID3D11SamplerState* const named = ask.out->Get();
    name_child(named, ask.name);
    return ok();
}

[[nodiscard]] Status make_query(D3d11Device& device, const QueryAsk& ask, QueryPtr& out) {
    D3D11_QUERY_DESC info{};
    info.Query = ask.type;
    ID3D11Device* const hardware = device.device();
    ID3D11Query** const slot = out.GetAddressOf();
    const HRESULT created = hardware->CreateQuery(&info, slot);
    if (FAILED(created)) return fail_hr(device, created, "không tạo được query");
    ID3D11Query* const named = out.Get();
    name_child(named, ask.name);
    return ok();
}

void push_query(QueryFill& fill) {
    QueryPtr query;
    QueryAsk ask;
    ask.type = fill.type;
    ask.name = fill.name;
    const Status made = make_query(*fill.device, ask, query);
    if (!made) fill.error = made;
    if (!made) return;
    fill.out->push_back(query);
    --fill.left;
}

void fill_queries(QueryFill& fill) {
    while (fill.left > 0 && fill.error) {
        push_query(fill);
    }
}

[[nodiscard]] D3D11_QUERY query_type(QueryKind kind) noexcept {
    if (kind == QueryKind::kOcclusion) return D3D11_QUERY_OCCLUSION;
    return D3D11_QUERY_TIMESTAMP;
}

[[nodiscard]] Status allow_occlusion(QueueType queue) {
    if (queue == QueueType::kGraphics) return ok();
    return fail(kMissing, "occlusion chỉ có trên hàng Graphics");
}

[[nodiscard]] bool timestamp_ok(const DeviceCaps& caps, QueueType queue) noexcept {
    const auto raw = std::to_underlying(queue);
    const auto index = static_cast<std::size_t>(raw);
    if (index >= kQueueCount) return false;
    // Chỉ số đã kiểm với kQueueCount.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    if (caps.has_timestamps[index]) return true;
    // Chỉ số đã kiểm với kQueueCount.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    if (caps.has_queue[index]) return false;
    const auto graphics_raw = std::to_underlying(QueueType::kGraphics);
    const auto graphics = static_cast<std::size_t>(graphics_raw);
    return caps.has_timestamps[graphics];
}

[[nodiscard]] Status allow_timestamp(const DeviceCaps& caps, QueueType queue) {
    if (timestamp_ok(caps, queue)) return ok();
    return fail(kMissing, "hàng đợi không ghi được dấu thời gian");
}

[[nodiscard]] Status allow_pool(const DeviceCaps& caps, const QueryPoolDesc& desc) {
    if (desc.count == 0) return fail(kBad, "query pool: count bằng 0");
    if (desc.kind == QueryKind::kOcclusion) return allow_occlusion(desc.queue);
    return allow_timestamp(caps, desc.queue);
}

[[nodiscard]] Status make_disjoint(D3d11Device& device, DisjointAsk ask) {
    if (ask.desc->kind != QueryKind::kTimestamp) return ok();
    QueryAsk query;
    query.type = D3D11_QUERY_TIMESTAMP_DISJOINT;
    query.name = ask.desc->name;
    return make_query(device, query, ask.pool->disjoint);
}

void release_pool(D3d11Device& device, QueryPool& pool) {
    for (QueryPtr& query : pool.queries) {
        retire_com(device, query);
    }
    retire_com(device, pool.disjoint);
}

[[nodiscard]] Status query_status(D3d11Device& device, HRESULT code, core::Message message) {
    if (code == S_FALSE) return fail(kBlock, "kết quả truy vấn chưa có");
    if (SUCCEEDED(code)) return ok();
    return fail_hr(device, code, message);
}

void pull_occlusion(Pull& pull) {
    ID3D11Query* const query = pull.pool->queries[pull.cursor].Get();
    std::uint64_t value = 0;
    const auto bytes = static_cast<UINT>(sizeof(value));
    const HRESULT code = pull.context->GetData(query, &value, bytes, 0);
    const Status status = query_status(*pull.device, code, "không đọc được occlusion");
    if (!status) pull.error = status;
    if (!status) return;
    const auto slot = static_cast<std::size_t>(pull.cursor - pull.first);
    pull.out[slot] = value;
    ++pull.cursor;
}

[[nodiscard]] Status read_occlusion(D3d11Device& device, const QueryRead& read) {
    ImmediateGuard guard = device.lock_immediate();
    Pull pull;
    pull.device = &device;
    pull.context = &guard.context();
    pull.pool = read.pool;
    pull.cursor = read.first;
    pull.first = read.first;
    const std::size_t raw_count = read.out.size();
    const auto count = static_cast<std::uint32_t>(raw_count);
    pull.end = read.first + count;
    pull.out = read.out;
    while (pull.cursor < pull.end && pull.error) {
        pull_occlusion(pull);
    }
    return pull.error;
}

[[nodiscard]] Status read_clock(D3d11Device& device, ID3D11DeviceContext& context, ClockOut out) {
    D3D11_QUERY_DATA_TIMESTAMP_DISJOINT data{};
    ID3D11Query* const query = out.pool->disjoint.Get();
    const auto bytes = static_cast<UINT>(sizeof(data));
    const HRESULT code = context.GetData(query, &data, bytes, 0);
    const Status status = query_status(device, code, "không đọc được dấu thời gian");
    if (!status) return status;
    if (data.Disjoint != 0) return fail(kState, "dấu thời gian bị đứt");
    if (data.Frequency == 0) return fail(kState, "tần số dấu thời gian bằng 0");
    *out.frequency = data.Frequency;
    return ok();
}

void pull_stamp(Pull& pull) {
    ID3D11Query* const query = pull.pool->queries[pull.cursor].Get();
    std::uint64_t ticks = 0;
    const auto bytes = static_cast<UINT>(sizeof(ticks));
    const HRESULT code = pull.context->GetData(query, &ticks, bytes, 0);
    const Status status = query_status(*pull.device, code, "không đọc được dấu thời gian");
    if (!status) pull.error = status;
    if (!status) return;
    std::uint64_t nanos = 0;
    TickScale scale;
    scale.ticks = ticks;
    scale.frequency = pull.frequency;
    const bool fitted = scale_ns(scale, nanos);
    if (!fitted) pull.error = fail(kOverflow, "dấu thời gian tràn nano giây");
    if (!fitted) return;
    const auto slot = static_cast<std::size_t>(pull.cursor - pull.first);
    pull.out[slot] = nanos;
    ++pull.cursor;
}

[[nodiscard]] Status read_times(D3d11Device& device, const QueryRead& read) {
    ImmediateGuard guard = device.lock_immediate();
    ID3D11DeviceContext& context = guard.context();
    std::uint64_t frequency = 0;
    ClockOut clock;
    clock.pool = read.pool;
    clock.frequency = &frequency;
    const Status ready = read_clock(device, context, clock);
    if (!ready) return ready;
    Pull pull;
    pull.device = &device;
    pull.context = &context;
    pull.pool = read.pool;
    pull.frequency = frequency;
    pull.cursor = read.first;
    pull.first = read.first;
    const std::size_t raw_count = read.out.size();
    const auto count = static_cast<std::uint32_t>(raw_count);
    pull.end = read.first + count;
    pull.out = read.out;
    while (pull.cursor < pull.end && pull.error) {
        pull_stamp(pull);
    }
    return pull.error;
}

} // namespace

Result<BufferHandle> D3d11Device::create_buffer(const BufferDesc& desc) {
    const Status checked = check_buffer(desc);
    if (!checked) return as_error(checked);
    const Status rejected = reject_upload(desc);
    if (!rejected) return as_error(rejected);
    UINT width = 0;
    const bool fitted = fit_uint(desc.size, width);
    if (!fitted) return fail(kOverflow, "buffer vượt UINT");
    const BufferPlan plan = plan_for(desc, width);
    if (!plan.fits) return fail(kOverflow, "ByteWidth làm tròn tràn");
    const Status dynamic = check_dynamic(plan);
    if (!dynamic) return as_error(dynamic);
    Buffer buffer;
    apply_plan(buffer, desc, plan);
    RawBuffer raw;
    raw.plan = &plan;
    raw.name = desc.name;
    raw.out = &buffer.resource;
    const Status made = create_raw_buffer(*this, raw);
    if (!made) return as_error(made);
    BufferHandle handle;
    const bool stored = kept(buffers_, buffer, handle);
    if (!stored) retire_com(*this, buffer.resource);
    if (!stored) return fail(kExhausted, "hết ô trong bảng buffer");
    return handle;
}

Result<TextureHandle> D3d11Device::create_texture(const TextureDesc& desc) {
    const DeviceCaps& limits = caps();
    const Status checked = check_texture(desc, limits);
    if (!checked) return as_error(checked);
    const DXGI_FORMAT format = texture_format(desc);
    const Status typed = require_format(desc, format);
    if (!typed) return as_error(typed);
    const Status msaa = check_msaa(*this, format, desc.samples);
    if (!msaa) return as_error(msaa);
    TexInfo info;
    // Transient không có reserved.
    info.bind = texture_bind(desc.usage);
    info.format = format;
    info.misc = cube_misc(desc.kind);
    info.samples = desc.samples;
    ResourcePtr resource;
    TexTarget target;
    target.device = this;
    target.out = &resource;
    const Status made = create_tex(target, desc, info);
    if (!made) return as_error(made);
    ID3D11Resource* const raw = resource.Get();
    name_child(raw, desc.name);
    Texture texture;
    store_texture(texture, desc, resource);
    TextureHandle handle;
    const bool stored = kept(textures_, texture, handle);
    if (!stored) retire_com(*this, texture.resource);
    if (!stored) return fail(kExhausted, "hết ô trong bảng texture");
    return handle;
}

Result<TextureViewHandle> D3d11Device::create_view(const TextureViewDesc& desc) {
    const Texture* const texture = find(desc.texture);
    if (texture == nullptr) return fail(kBad, "view: texture đã chết");
    const TextureDesc source = texture_of(*texture);
    const core::Result<ViewRange> resolved = resolve_view(desc, source);
    if (!resolved) return as_error(resolved);
    const ViewRange range = resolved.value();
    View view;
    ViewSeed seed;
    seed.texture = texture;
    seed.range = &range;
    seed.handle = desc.texture;
    fill_view(view, seed);
    ViewMake made;
    made.device = this;
    made.view = &view;
    made.texture = texture;
    made.kind = desc.kind;
    made.range = range;
    const Status built = make_views(made);
    if (!built) return as_error(built);
    name_view(view, desc.name);
    TextureViewHandle handle;
    const bool stored = kept(views_, view, handle);
    if (!stored) release_view(*this, view);
    if (!stored) return fail(kExhausted, "hết ô trong bảng view");
    return handle;
}

Result<SamplerHandle> D3d11Device::create_sampler(const SamplerDesc& desc) {
    const DeviceCaps& limits = caps();
    // SDK không có giá trị 0.
    // NOLINTBEGIN(bugprone-invalid-enum-default-initialization)
    D3D11_SAMPLER_DESC info{};
    // NOLINTEND(bugprone-invalid-enum-default-initialization)
    info.Filter = to_filter(desc);
    info.AddressU = to_dxgi(desc.address_u);
    info.AddressV = to_dxgi(desc.address_v);
    info.AddressW = to_dxgi(desc.address_w);
    info.MipLODBias = desc.mip_bias;
    AnisoAsk aniso;
    aniso.asked = desc.max_anisotropy;
    aniso.cap = limits.max_anisotropy;
    info.MaxAnisotropy = clamp_anisotropy(aniso);
    info.ComparisonFunc = to_dxgi(desc.compare);
    info.MinLOD = desc.min_lod;
    info.MaxLOD = desc.max_lod;
    apply_border(info, desc.border);
    Sampler sampler;
    SamplerAsk ask;
    ask.info = &info;
    ask.name = desc.name;
    ask.out = &sampler.state;
    const Status made = create_sampler_state(*this, ask);
    if (!made) return as_error(made);
    SamplerHandle handle;
    const bool stored = kept(samplers_, sampler, handle);
    if (!stored) retire_com(*this, sampler.state);
    if (!stored) return fail(kExhausted, "hết ô trong bảng sampler");
    return handle;
}

Result<QueryPoolHandle> D3d11Device::create_query_pool(const QueryPoolDesc& desc) {
    const DeviceCaps& limits = caps();
    const Status allowed = allow_pool(limits, desc);
    if (!allowed) return as_error(allowed);
    QueryPool pool;
    pool.kind = desc.kind;
    pool.count = desc.count;
    QueryFill fill;
    fill.device = this;
    fill.type = query_type(desc.kind);
    fill.name = desc.name;
    fill.left = desc.count;
    fill.out = &pool.queries;
    fill_queries(fill);
    if (!fill.error) return as_error(fill.error);
    DisjointAsk disjoint_ask;
    disjoint_ask.desc = &desc;
    disjoint_ask.pool = &pool;
    const Status disjoint = make_disjoint(*this, disjoint_ask);
    if (!disjoint) return as_error(disjoint);
    QueryPoolHandle handle;
    const bool stored = kept(queries_, pool, handle);
    if (!stored) release_pool(*this, pool);
    if (!stored) return fail(kExhausted, "hết ô trong bảng query pool");
    return handle;
}

void D3d11Device::destroy(BufferHandle handle) {
    std::optional<Buffer> removed = buffers_.remove(handle);
    if (!removed.has_value()) return;
    Buffer& buffer = removed.value();
    retire_com(*this, buffer.resource);
}

// Không sở hữu vẫn retire: ta giữ một ref.
void D3d11Device::destroy(TextureHandle handle) {
    std::optional<Texture> removed = textures_.remove(handle);
    if (!removed.has_value()) return;
    Texture& texture = removed.value();
    retire_com(*this, texture.resource);
}

void D3d11Device::destroy(TextureViewHandle handle) {
    std::optional<View> removed = views_.remove(handle);
    if (!removed.has_value()) return;
    View& view = removed.value();
    release_view(*this, view);
}

void D3d11Device::destroy(SamplerHandle handle) {
    std::optional<Sampler> removed = samplers_.remove(handle);
    if (!removed.has_value()) return;
    Sampler& sampler = removed.value();
    retire_com(*this, sampler.state);
}

void D3d11Device::destroy(QueryPoolHandle handle) {
    std::optional<QueryPool> removed = queries_.remove(handle);
    if (!removed.has_value()) return;
    QueryPool& pool = removed.value();
    release_pool(*this, pool);
}

Status D3d11Device::write_buffer(BufferHandle handle, std::uint64_t offset, ByteIn data) {
    Buffer* const buffer = find(handle);
    if (buffer == nullptr) return fail(kBad, "write_buffer: buffer đã chết");
    const bool is_upload = buffer->domain == MemoryDomain::kUpload;
    if (!is_upload) return fail(kBad, "write_buffer: buffer không phải Upload");
    const std::uint64_t count = data.size();
    const Status inside = check_span(buffer->size, offset, count);
    if (!inside) return inside;
    ByteSpan span;
    span.offset = offset;
    span.data = data;
    return write_upload(*this, *buffer, span);
}

Status D3d11Device::read_buffer(BufferHandle handle, std::uint64_t offset, ByteOut out) {
    Buffer* const buffer = find(handle);
    if (buffer == nullptr) return fail(kBad, "read_buffer: buffer đã chết");
    const bool is_readback = buffer->domain == MemoryDomain::kReadback;
    const bool readable = is_readback && buffer->resource != nullptr;
    if (!readable) return fail(kBad, "read_buffer: buffer không phải Readback");
    const std::uint64_t count = out.size();
    const Status inside = check_span(buffer->size, offset, count);
    if (!inside) return inside;
    OutSpan span;
    span.offset = offset;
    span.out = out;
    return read_mapped(*this, *buffer, span);
}

Status D3d11Device::read_queries(QueryPoolHandle pool, U32 first, QueryOut out) {
    QueryPool* const found = find(pool);
    if (found == nullptr) return fail(kBad, "read_queries: pool đã chết");
    const std::uint64_t count = out.size();
    const Status inside = check_span(found->count, first, count);
    if (!inside) return inside;
    QueryRead read;
    read.pool = found;
    read.first = first;
    read.out = out;
    if (found->kind == QueryKind::kOcclusion) return read_occlusion(*this, read);
    return read_times(*this, read);
}

Status D3d11Device::materialize(Buffer& buffer, std::uint32_t stride) {
    if (!buffer.is_structured || stride == 0) return ok();
    const bool same = buffer.resource != nullptr && buffer.stride == stride;
    if (same) return ok();
    drop_resource(*this, buffer);
    const Status made = create_structured(*this, buffer, stride);
    if (!made) return made;
    const Status uploaded = upload_if_needed(*this, buffer);
    if (!uploaded) return uploaded;
    buffer.stride = stride;
    return ok();
}

Result<TextureHandle> D3d11Device::adopt_swap_image(SwapImage image) {
    Texture texture;
    ID3D11Texture2D* const raw = image.texture.Detach();
    texture.resource.Attach(raw);
    texture.format = image.format;
    texture.kind = TextureKind::kTex2D;
    // Không khai kSampled: bộ đệm swapchain là UNORM, view RHI là sRGB. RTV được ép kiểu, SRV thì
    // không, và buffer chỉ có RENDER_TARGET nên CreateShaderResourceView thất bại.
    texture.usage = TextureUsage::kColorTarget | TextureUsage::kCopySource;
    texture.width = image.width;
    texture.height = image.height;
    texture.depth_or_layers = 1;
    texture.mip_levels = 1;
    texture.samples = 1;
    texture.is_owned = false;
    TextureHandle handle;
    const bool stored = kept(textures_, texture, handle);
    if (!stored) retire_com(*this, texture.resource);
    if (!stored) return fail(kExhausted, "hết ô trong bảng texture");
    return handle;
}

} // namespace game::gpu::d3d11
