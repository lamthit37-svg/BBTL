// Bảng đổi kiểu engine sang Direct3D 12. Thứ tự kFormats khớp enum Format.
// Nguồn: Forge2 src/gpu/d3d12/convert.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k;
// hàng kStages, kAccess, kTypeless và kDepthSrv ghi đủ tên trường; if trong for của
// map_flags và to_visibility tách thành or_row và note_stage; map_flags nhận FlagRows;
// to_dxgi(Format) tách chỉ số khỏi .at; include trực tiếp header của mọi tên dùng tới.
#include "gpu/d3d12/convert.hpp"

#include "gpu/barrier.hpp"
#include "gpu/format.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/types.hpp"

#include <d3d12.h>
#include <d3dcommon.h>
#include <dxgiformat.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace game::gpu::d3d12 {

namespace {

template <class Flag, class Bits>
struct FlagRow {
    Flag flag;
    Bits bits;
};

template <class Flag, class Bits>
void or_row(Bits& bits, Flag value, const FlagRow<Flag, Bits>& row) noexcept {
    // Khác gốc: if (overlaps) bits |= row.bits;
    if (overlaps(value, row.flag)) bits |= row.bits;
}

template <class Flag, class Bits, std::size_t Count>
using FlagRows = std::array<FlagRow<Flag, Bits>, Count>;

template <class Flag, class Bits, std::size_t Count>
[[nodiscard]] Bits map_flags(Flag value, const FlagRows<Flag, Bits, Count>& rows) noexcept {
    Bits bits{};
    for (const FlagRow<Flag, Bits>& row : rows) {
        or_row(bits, value, row);
    }
    return bits;
}

constexpr std::array<DXGI_FORMAT, kFormatCount> kFormats{
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_R8_UNORM,
    DXGI_FORMAT_R8_SNORM,
    DXGI_FORMAT_R8_UINT,
    DXGI_FORMAT_R8_SINT,
    DXGI_FORMAT_R8G8_UNORM,
    DXGI_FORMAT_R8G8_SNORM,
    DXGI_FORMAT_R8G8_UINT,
    DXGI_FORMAT_R8G8_SINT,
    DXGI_FORMAT_R8G8B8A8_UNORM,
    DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
    DXGI_FORMAT_R8G8B8A8_SNORM,
    DXGI_FORMAT_R8G8B8A8_UINT,
    DXGI_FORMAT_R8G8B8A8_SINT,
    DXGI_FORMAT_B8G8R8A8_UNORM,
    DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
    DXGI_FORMAT_R16_UNORM,
    DXGI_FORMAT_R16_SNORM,
    DXGI_FORMAT_R16_UINT,
    DXGI_FORMAT_R16_SINT,
    DXGI_FORMAT_R16_FLOAT,
    DXGI_FORMAT_R16G16_UNORM,
    DXGI_FORMAT_R16G16_SNORM,
    DXGI_FORMAT_R16G16_UINT,
    DXGI_FORMAT_R16G16_SINT,
    DXGI_FORMAT_R16G16_FLOAT,
    DXGI_FORMAT_R16G16B16A16_UNORM,
    DXGI_FORMAT_R16G16B16A16_SNORM,
    DXGI_FORMAT_R16G16B16A16_UINT,
    DXGI_FORMAT_R16G16B16A16_SINT,
    DXGI_FORMAT_R16G16B16A16_FLOAT,
    DXGI_FORMAT_R32_UINT,
    DXGI_FORMAT_R32_SINT,
    DXGI_FORMAT_R32_FLOAT,
    DXGI_FORMAT_R32G32_UINT,
    DXGI_FORMAT_R32G32_SINT,
    DXGI_FORMAT_R32G32_FLOAT,
    DXGI_FORMAT_R32G32B32_UINT,
    DXGI_FORMAT_R32G32B32_SINT,
    DXGI_FORMAT_R32G32B32_FLOAT,
    DXGI_FORMAT_R32G32B32A32_UINT,
    DXGI_FORMAT_R32G32B32A32_SINT,
    DXGI_FORMAT_R32G32B32A32_FLOAT,
    DXGI_FORMAT_R10G10B10A2_UNORM,
    DXGI_FORMAT_R10G10B10A2_UINT,
    DXGI_FORMAT_R11G11B10_FLOAT,
    DXGI_FORMAT_R9G9B9E5_SHAREDEXP,
    DXGI_FORMAT_D16_UNORM,
    DXGI_FORMAT_D24_UNORM_S8_UINT,
    DXGI_FORMAT_D32_FLOAT,
    DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
    DXGI_FORMAT_BC1_UNORM,
    DXGI_FORMAT_BC1_UNORM_SRGB,
    DXGI_FORMAT_BC2_UNORM,
    DXGI_FORMAT_BC2_UNORM_SRGB,
    DXGI_FORMAT_BC3_UNORM,
    DXGI_FORMAT_BC3_UNORM_SRGB,
    DXGI_FORMAT_BC4_UNORM,
    DXGI_FORMAT_BC4_SNORM,
    DXGI_FORMAT_BC5_UNORM,
    DXGI_FORMAT_BC5_SNORM,
    DXGI_FORMAT_BC6H_UF16,
    DXGI_FORMAT_BC6H_SF16,
    DXGI_FORMAT_BC7_UNORM,
    DXGI_FORMAT_BC7_UNORM_SRGB,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
    DXGI_FORMAT_UNKNOWN,
};

using StageRow = FlagRow<SyncStage, D3D12_BARRIER_SYNC>;
constexpr auto kVertexInputSync = D3D12_BARRIER_SYNC_INDEX_INPUT | D3D12_BARRIER_SYNC_VERTEX_SHADING;
constexpr std::array kStages{
    StageRow{.flag = SyncStage::kDrawIndirect, .bits = D3D12_BARRIER_SYNC_EXECUTE_INDIRECT},
    StageRow{.flag = SyncStage::kVertexInput, .bits = kVertexInputSync},
    StageRow{.flag = SyncStage::kVertexShader, .bits = D3D12_BARRIER_SYNC_VERTEX_SHADING},
    StageRow{.flag = SyncStage::kPixelShader, .bits = D3D12_BARRIER_SYNC_PIXEL_SHADING},
    StageRow{.flag = SyncStage::kComputeShader, .bits = D3D12_BARRIER_SYNC_COMPUTE_SHADING},
    StageRow{.flag = SyncStage::kEarlyDepth, .bits = D3D12_BARRIER_SYNC_DEPTH_STENCIL},
    StageRow{.flag = SyncStage::kLateDepth, .bits = D3D12_BARRIER_SYNC_DEPTH_STENCIL},
    StageRow{.flag = SyncStage::kColorOutput, .bits = D3D12_BARRIER_SYNC_RENDER_TARGET},
    StageRow{.flag = SyncStage::kCopy, .bits = D3D12_BARRIER_SYNC_COPY},
    StageRow{.flag = SyncStage::kResolve, .bits = D3D12_BARRIER_SYNC_RESOLVE},
    StageRow{.flag = SyncStage::kAll, .bits = D3D12_BARRIER_SYNC_ALL},
};

using AccessRow = FlagRow<Access, D3D12_BARRIER_ACCESS>;
constexpr std::array kAccess{
    AccessRow{.flag = Access::kIndirectRead, .bits = D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT},
    AccessRow{.flag = Access::kIndexRead, .bits = D3D12_BARRIER_ACCESS_INDEX_BUFFER},
    AccessRow{.flag = Access::kVertexRead, .bits = D3D12_BARRIER_ACCESS_VERTEX_BUFFER},
    AccessRow{.flag = Access::kUniformRead, .bits = D3D12_BARRIER_ACCESS_CONSTANT_BUFFER},
    AccessRow{.flag = Access::kShaderRead, .bits = D3D12_BARRIER_ACCESS_SHADER_RESOURCE},
    AccessRow{.flag = Access::kShaderWrite, .bits = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS},
    AccessRow{.flag = Access::kColorRead, .bits = D3D12_BARRIER_ACCESS_RENDER_TARGET},
    AccessRow{.flag = Access::kColorWrite, .bits = D3D12_BARRIER_ACCESS_RENDER_TARGET},
    AccessRow{.flag = Access::kDepthRead, .bits = D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ},
    AccessRow{.flag = Access::kDepthWrite, .bits = D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE},
    AccessRow{.flag = Access::kCopyRead, .bits = D3D12_BARRIER_ACCESS_COPY_SOURCE},
    AccessRow{.flag = Access::kCopyWrite, .bits = D3D12_BARRIER_ACCESS_COPY_DEST},
    AccessRow{.flag = Access::kResolveRead, .bits = D3D12_BARRIER_ACCESS_RESOLVE_SOURCE},
    AccessRow{.flag = Access::kResolveWrite, .bits = D3D12_BARRIER_ACCESS_RESOLVE_DEST},
};

struct FormatPair {
    DXGI_FORMAT typed;
    DXGI_FORMAT typeless;
};

constexpr std::array kTypeless{
    FormatPair{.typed = DXGI_FORMAT_R8_UNORM, .typeless = DXGI_FORMAT_R8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8_SNORM, .typeless = DXGI_FORMAT_R8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8_UINT, .typeless = DXGI_FORMAT_R8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8_SINT, .typeless = DXGI_FORMAT_R8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8_UNORM, .typeless = DXGI_FORMAT_R8G8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8_SNORM, .typeless = DXGI_FORMAT_R8G8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8_UINT, .typeless = DXGI_FORMAT_R8G8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8_SINT, .typeless = DXGI_FORMAT_R8G8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8B8A8_UNORM, .typeless = DXGI_FORMAT_R8G8B8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8B8A8_UNORM_SRGB, .typeless = DXGI_FORMAT_R8G8B8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8B8A8_SNORM, .typeless = DXGI_FORMAT_R8G8B8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8B8A8_UINT, .typeless = DXGI_FORMAT_R8G8B8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R8G8B8A8_SINT, .typeless = DXGI_FORMAT_R8G8B8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_B8G8R8A8_UNORM, .typeless = DXGI_FORMAT_B8G8R8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB, .typeless = DXGI_FORMAT_B8G8R8A8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16_UNORM, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16_SNORM, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16_UINT, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16_SINT, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16_FLOAT, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16_UNORM, .typeless = DXGI_FORMAT_R16G16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16_SNORM, .typeless = DXGI_FORMAT_R16G16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16_UINT, .typeless = DXGI_FORMAT_R16G16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16_SINT, .typeless = DXGI_FORMAT_R16G16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16_FLOAT, .typeless = DXGI_FORMAT_R16G16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16B16A16_UNORM, .typeless = DXGI_FORMAT_R16G16B16A16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16B16A16_SNORM, .typeless = DXGI_FORMAT_R16G16B16A16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16B16A16_UINT, .typeless = DXGI_FORMAT_R16G16B16A16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16B16A16_SINT, .typeless = DXGI_FORMAT_R16G16B16A16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R16G16B16A16_FLOAT, .typeless = DXGI_FORMAT_R16G16B16A16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32_UINT, .typeless = DXGI_FORMAT_R32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32_SINT, .typeless = DXGI_FORMAT_R32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32_FLOAT, .typeless = DXGI_FORMAT_R32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32_UINT, .typeless = DXGI_FORMAT_R32G32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32_SINT, .typeless = DXGI_FORMAT_R32G32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32_FLOAT, .typeless = DXGI_FORMAT_R32G32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32_UINT, .typeless = DXGI_FORMAT_R32G32B32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32_SINT, .typeless = DXGI_FORMAT_R32G32B32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32_FLOAT, .typeless = DXGI_FORMAT_R32G32B32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32A32_UINT, .typeless = DXGI_FORMAT_R32G32B32A32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32A32_SINT, .typeless = DXGI_FORMAT_R32G32B32A32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R32G32B32A32_FLOAT, .typeless = DXGI_FORMAT_R32G32B32A32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R10G10B10A2_UNORM, .typeless = DXGI_FORMAT_R10G10B10A2_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_R10G10B10A2_UINT, .typeless = DXGI_FORMAT_R10G10B10A2_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_D16_UNORM, .typeless = DXGI_FORMAT_R16_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_D24_UNORM_S8_UINT, .typeless = DXGI_FORMAT_R24G8_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_D32_FLOAT, .typeless = DXGI_FORMAT_R32_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_D32_FLOAT_S8X24_UINT, .typeless = DXGI_FORMAT_R32G8X24_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC1_UNORM, .typeless = DXGI_FORMAT_BC1_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC1_UNORM_SRGB, .typeless = DXGI_FORMAT_BC1_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC2_UNORM, .typeless = DXGI_FORMAT_BC2_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC2_UNORM_SRGB, .typeless = DXGI_FORMAT_BC2_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC3_UNORM, .typeless = DXGI_FORMAT_BC3_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC3_UNORM_SRGB, .typeless = DXGI_FORMAT_BC3_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC4_UNORM, .typeless = DXGI_FORMAT_BC4_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC4_SNORM, .typeless = DXGI_FORMAT_BC4_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC5_UNORM, .typeless = DXGI_FORMAT_BC5_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC5_SNORM, .typeless = DXGI_FORMAT_BC5_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC6H_UF16, .typeless = DXGI_FORMAT_BC6H_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC6H_SF16, .typeless = DXGI_FORMAT_BC6H_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC7_UNORM, .typeless = DXGI_FORMAT_BC7_TYPELESS},
    FormatPair{.typed = DXGI_FORMAT_BC7_UNORM_SRGB, .typeless = DXGI_FORMAT_BC7_TYPELESS},
};

struct DepthSrv {
    Format format;
    ViewAspect aspect;
    DXGI_FORMAT dxgi;
};

constexpr std::array kDepthSrv{
    DepthSrv{.format = Format::kD16Unorm, .aspect = ViewAspect::kAll, .dxgi = DXGI_FORMAT_R16_UNORM},
    DepthSrv{.format = Format::kD16Unorm, .aspect = ViewAspect::kDepth, .dxgi = DXGI_FORMAT_R16_UNORM},
    DepthSrv{
        .format = Format::kD24UnormS8Uint, .aspect = ViewAspect::kDepth, .dxgi = DXGI_FORMAT_R24_UNORM_X8_TYPELESS},
    DepthSrv{
        .format = Format::kD24UnormS8Uint, .aspect = ViewAspect::kStencil, .dxgi = DXGI_FORMAT_X24_TYPELESS_G8_UINT},
    DepthSrv{.format = Format::kD32Float, .aspect = ViewAspect::kAll, .dxgi = DXGI_FORMAT_R32_FLOAT},
    DepthSrv{.format = Format::kD32Float, .aspect = ViewAspect::kDepth, .dxgi = DXGI_FORMAT_R32_FLOAT},
    DepthSrv{
        .format = Format::kD32FloatS8Uint, .aspect = ViewAspect::kDepth, .dxgi = DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS},
    DepthSrv{
        .format = Format::kD32FloatS8Uint, .aspect = ViewAspect::kStencil, .dxgi = DXGI_FORMAT_X32_TYPELESS_G8X24_UINT},
};

} // namespace

static_assert(kFormats.size() == kFormatCount);

DXGI_FORMAT to_dxgi(Format format) noexcept {
    // Khác gốc: không gọi lồng trong .at.
    const auto index = std::to_underlying(format);
    return kFormats.at(index);
}

Format from_dxgi(DXGI_FORMAT format) noexcept {
    const auto found = std::ranges::find(kFormats, format);
    if (found == kFormats.end()) return Format::kUnknown;
    return static_cast<Format>(found - kFormats.begin());
}

DXGI_FORMAT typeless_format(DXGI_FORMAT format) noexcept {
    const auto matches = [format](const FormatPair& pair) { return pair.typed == format; };
    const auto found = std::ranges::find_if(kTypeless, matches);
    if (found == kTypeless.end()) return DXGI_FORMAT_UNKNOWN;
    return found->typeless;
}

DXGI_FORMAT depth_srv_format(Format format, ViewAspect aspect) noexcept {
    const auto matches = [format, aspect](const DepthSrv& row) { return row.format == format && row.aspect == aspect; };
    const auto found = std::ranges::find_if(kDepthSrv, matches);
    if (found == kDepthSrv.end()) return DXGI_FORMAT_UNKNOWN;
    return found->dxgi;
}

D3D12_COMPARISON_FUNC to_dxgi(CompareOp value) noexcept {
    switch (value) {
    case CompareOp::kNever: return D3D12_COMPARISON_FUNC_NEVER;
    case CompareOp::kLess: return D3D12_COMPARISON_FUNC_LESS;
    case CompareOp::kEqual: return D3D12_COMPARISON_FUNC_EQUAL;
    case CompareOp::kLessOrEqual: return D3D12_COMPARISON_FUNC_LESS_EQUAL;
    case CompareOp::kGreater: return D3D12_COMPARISON_FUNC_GREATER;
    case CompareOp::kNotEqual: return D3D12_COMPARISON_FUNC_NOT_EQUAL;
    case CompareOp::kGreaterOrEqual: return D3D12_COMPARISON_FUNC_GREATER_EQUAL;
    case CompareOp::kAlways: return D3D12_COMPARISON_FUNC_ALWAYS;
    }
    return D3D12_COMPARISON_FUNC_ALWAYS;
}

D3D12_STENCIL_OP to_dxgi(StencilOp value) noexcept {
    switch (value) {
    case StencilOp::kKeep: return D3D12_STENCIL_OP_KEEP;
    case StencilOp::kZero: return D3D12_STENCIL_OP_ZERO;
    case StencilOp::kReplace: return D3D12_STENCIL_OP_REPLACE;
    case StencilOp::kIncrementClamp: return D3D12_STENCIL_OP_INCR_SAT;
    case StencilOp::kDecrementClamp: return D3D12_STENCIL_OP_DECR_SAT;
    case StencilOp::kInvert: return D3D12_STENCIL_OP_INVERT;
    case StencilOp::kIncrementWrap: return D3D12_STENCIL_OP_INCR;
    case StencilOp::kDecrementWrap: return D3D12_STENCIL_OP_DECR;
    }
    return D3D12_STENCIL_OP_KEEP;
}

D3D12_BLEND to_dxgi(BlendFactor value) noexcept {
    switch (value) {
    case BlendFactor::kZero: return D3D12_BLEND_ZERO;
    case BlendFactor::kOne: return D3D12_BLEND_ONE;
    case BlendFactor::kSrcColor: return D3D12_BLEND_SRC_COLOR;
    case BlendFactor::kOneMinusSrcColor: return D3D12_BLEND_INV_SRC_COLOR;
    case BlendFactor::kDstColor: return D3D12_BLEND_DEST_COLOR;
    case BlendFactor::kOneMinusDstColor: return D3D12_BLEND_INV_DEST_COLOR;
    case BlendFactor::kSrcAlpha: return D3D12_BLEND_SRC_ALPHA;
    case BlendFactor::kOneMinusSrcAlpha: return D3D12_BLEND_INV_SRC_ALPHA;
    case BlendFactor::kDstAlpha: return D3D12_BLEND_DEST_ALPHA;
    case BlendFactor::kOneMinusDstAlpha: return D3D12_BLEND_INV_DEST_ALPHA;
    case BlendFactor::kSrcAlphaSaturate: return D3D12_BLEND_SRC_ALPHA_SAT;
    case BlendFactor::kConstant: return D3D12_BLEND_BLEND_FACTOR;
    case BlendFactor::kOneMinusConstant: return D3D12_BLEND_INV_BLEND_FACTOR;
    }
    return D3D12_BLEND_ONE;
}

D3D12_BLEND_OP to_dxgi(BlendOp value) noexcept {
    switch (value) {
    case BlendOp::kAdd: return D3D12_BLEND_OP_ADD;
    case BlendOp::kSubtract: return D3D12_BLEND_OP_SUBTRACT;
    case BlendOp::kReverseSubtract: return D3D12_BLEND_OP_REV_SUBTRACT;
    case BlendOp::kMin: return D3D12_BLEND_OP_MIN;
    case BlendOp::kMax: return D3D12_BLEND_OP_MAX;
    }
    return D3D12_BLEND_OP_ADD;
}

D3D12_CULL_MODE to_dxgi(CullMode value) noexcept {
    switch (value) {
    case CullMode::kNone: return D3D12_CULL_MODE_NONE;
    case CullMode::kFront: return D3D12_CULL_MODE_FRONT;
    case CullMode::kBack: return D3D12_CULL_MODE_BACK;
    }
    return D3D12_CULL_MODE_BACK;
}

D3D12_FILL_MODE to_dxgi(FillMode value) noexcept {
    switch (value) {
    case FillMode::kSolid: return D3D12_FILL_MODE_SOLID;
    case FillMode::kWireframe: return D3D12_FILL_MODE_WIREFRAME;
    }
    return D3D12_FILL_MODE_SOLID;
}

D3D12_PRIMITIVE_TOPOLOGY to_topology(Topology value) noexcept {
    switch (value) {
    case Topology::kPointList: return D3D_PRIMITIVE_TOPOLOGY_POINTLIST;
    case Topology::kLineList: return D3D_PRIMITIVE_TOPOLOGY_LINELIST;
    case Topology::kLineStrip: return D3D_PRIMITIVE_TOPOLOGY_LINESTRIP;
    case Topology::kTriangleList: return D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
    case Topology::kTriangleStrip: return D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
    case Topology::kPatchList: return D3D_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST;
    }
    return D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
}

D3D12_PRIMITIVE_TOPOLOGY_TYPE to_topology_type(Topology value) noexcept {
    switch (value) {
    case Topology::kPointList: return D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT;
    case Topology::kLineList:
    case Topology::kLineStrip: return D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
    case Topology::kTriangleList:
    case Topology::kTriangleStrip: return D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
    case Topology::kPatchList: return D3D12_PRIMITIVE_TOPOLOGY_TYPE_PATCH;
    }
    return D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
}

DXGI_FORMAT to_index(IndexType value) noexcept {
    switch (value) {
    case IndexType::kUint16: return DXGI_FORMAT_R16_UINT;
    case IndexType::kUint32: return DXGI_FORMAT_R32_UINT;
    }
    return DXGI_FORMAT_R16_UINT;
}

D3D12_FILTER to_filter(const SamplerDesc& desc) noexcept {
    const bool is_compare = desc.compare != CompareOp::kNever;
    const bool is_min_linear = desc.min_filter == Filter::kLinear;
    const bool is_mag_linear = desc.mag_filter == Filter::kLinear;
    const bool is_mip_linear = desc.mip_filter == Filter::kLinear;
    const bool is_aniso = desc.max_anisotropy > 1;
    if (is_aniso && is_compare) return D3D12_FILTER_COMPARISON_ANISOTROPIC;
    if (is_aniso) return D3D12_FILTER_ANISOTROPIC;
    const int code = (is_min_linear ? 4 : 0) + (is_mag_linear ? 2 : 0) + (is_mip_linear ? 1 : 0);
    if (!is_compare) return static_cast<D3D12_FILTER>(code);
    return static_cast<D3D12_FILTER>(D3D12_FILTER_COMPARISON_MIN_MAG_MIP_POINT + code);
}

D3D12_TEXTURE_ADDRESS_MODE to_dxgi(AddressMode value) noexcept {
    switch (value) {
    case AddressMode::kRepeat: return D3D12_TEXTURE_ADDRESS_MODE_WRAP;
    case AddressMode::kMirrorRepeat: return D3D12_TEXTURE_ADDRESS_MODE_MIRROR;
    case AddressMode::kClampToEdge: return D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    case AddressMode::kClampToBorder: return D3D12_TEXTURE_ADDRESS_MODE_BORDER;
    }
    return D3D12_TEXTURE_ADDRESS_MODE_WRAP;
}

D3D12_COMMAND_LIST_TYPE to_list(QueueType value) noexcept {
    switch (value) {
    case QueueType::kGraphics: return D3D12_COMMAND_LIST_TYPE_DIRECT;
    case QueueType::kCompute: return D3D12_COMMAND_LIST_TYPE_COMPUTE;
    case QueueType::kCopy: return D3D12_COMMAND_LIST_TYPE_COPY;
    }
    return D3D12_COMMAND_LIST_TYPE_DIRECT;
}

D3D12_RESOURCE_DIMENSION to_dimension(TextureKind kind) noexcept {
    switch (kind) {
    case TextureKind::kTex1D: return D3D12_RESOURCE_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kTex2DArray:
    case TextureKind::kCube:
    case TextureKind::kCubeArray: return D3D12_RESOURCE_DIMENSION_TEXTURE2D;
    case TextureKind::kTex3D: return D3D12_RESOURCE_DIMENSION_TEXTURE3D;
    }
    return D3D12_RESOURCE_DIMENSION_TEXTURE2D;
}

D3D12_RTV_DIMENSION to_rtv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D12_RTV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return is_ms ? D3D12_RTV_DIMENSION_TEXTURE2DMS : D3D12_RTV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray:
        return is_ms ? D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY : D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D12_RTV_DIMENSION_TEXTURE3D;
    }
    return D3D12_RTV_DIMENSION_TEXTURE2D;
}

D3D12_DSV_DIMENSION to_dsv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D12_DSV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return is_ms ? D3D12_DSV_DIMENSION_TEXTURE2DMS : D3D12_DSV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray:
        return is_ms ? D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY : D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D12_DSV_DIMENSION_TEXTURE2D;
    }
    return D3D12_DSV_DIMENSION_TEXTURE2D;
}

D3D12_SRV_DIMENSION to_srv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D12_SRV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D: return is_ms ? D3D12_SRV_DIMENSION_TEXTURE2DMS : D3D12_SRV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
        return is_ms ? D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY : D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D12_SRV_DIMENSION_TEXTURE3D;
    case TextureKind::kCube: return D3D12_SRV_DIMENSION_TEXTURECUBE;
    case TextureKind::kCubeArray: return D3D12_SRV_DIMENSION_TEXTURECUBEARRAY;
    }
    return D3D12_SRV_DIMENSION_TEXTURE2D;
}

D3D12_UAV_DIMENSION to_uav(TextureKind kind) noexcept {
    switch (kind) {
    case TextureKind::kTex1D: return D3D12_UAV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return D3D12_UAV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray: return D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D12_UAV_DIMENSION_TEXTURE3D;
    }
    return D3D12_UAV_DIMENSION_TEXTURE2D;
}

D3D12_BARRIER_SYNC to_sync(SyncStage stages) noexcept {
    if (stages == SyncStage::kNone) return D3D12_BARRIER_SYNC_NONE;
    if (has(stages, SyncStage::kAll)) return D3D12_BARRIER_SYNC_ALL;
    return map_flags(stages, kStages);
}

D3D12_BARRIER_ACCESS to_access(Access access) noexcept {
    if (access == Access::kNone) return D3D12_BARRIER_ACCESS_NO_ACCESS;
    return map_flags(access, kAccess);
}

D3D12_BARRIER_LAYOUT to_layout(TextureLayout layout, QueueType queue) noexcept {
    const bool is_compute = queue == QueueType::kCompute;
    switch (layout) {
    case TextureLayout::kUndefined: return D3D12_BARRIER_LAYOUT_UNDEFINED;
    case TextureLayout::kGeneral:
        return is_compute ? D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS : D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS;
    case TextureLayout::kColorTarget: return D3D12_BARRIER_LAYOUT_RENDER_TARGET;
    case TextureLayout::kDepthWrite: return D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE;
    case TextureLayout::kDepthRead: return D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ;
    case TextureLayout::kShaderRead:
        return is_compute ? D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE : D3D12_BARRIER_LAYOUT_SHADER_RESOURCE;
    case TextureLayout::kCopySource:
        return is_compute ? D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE : D3D12_BARRIER_LAYOUT_COPY_SOURCE;
    case TextureLayout::kCopyDest:
        return is_compute ? D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST : D3D12_BARRIER_LAYOUT_COPY_DEST;
    case TextureLayout::kResolveSource: return D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE;
    case TextureLayout::kResolveDest: return D3D12_BARRIER_LAYOUT_RESOLVE_DEST;
    case TextureLayout::kPresent: return D3D12_BARRIER_LAYOUT_PRESENT;
    }
    return D3D12_BARRIER_LAYOUT_UNDEFINED;
}

namespace {

struct StageTally {
    std::uint32_t count;
    shader::Stage only;
};

// Khác gốc: if (!stages.has(stage)) continue; rồi only = stage; ++count.
void note_stage(StageTally& tally, const shader::StageSet& stages, shader::Stage stage) noexcept {
    if (!stages.has(stage)) return;
    tally.only = stage;
    ++tally.count;
}

} // namespace

D3D12_SHADER_VISIBILITY to_visibility(shader::StageSet stages) noexcept {
    StageTally tally{.count = 0, .only = shader::Stage::kVertex};
    constexpr std::array kOrder{shader::Stage::kVertex, shader::Stage::kHull, shader::Stage::kDomain,
        shader::Stage::kGeometry, shader::Stage::kPixel, shader::Stage::kCompute, shader::Stage::kMesh,
        shader::Stage::kAmplification, shader::Stage::kLibrary};
    for (const shader::Stage stage : kOrder) {
        note_stage(tally, stages, stage);
    }
    if (tally.count != 1) return D3D12_SHADER_VISIBILITY_ALL;
    switch (tally.only) {
    case shader::Stage::kVertex: return D3D12_SHADER_VISIBILITY_VERTEX;
    case shader::Stage::kHull: return D3D12_SHADER_VISIBILITY_HULL;
    case shader::Stage::kDomain: return D3D12_SHADER_VISIBILITY_DOMAIN;
    case shader::Stage::kGeometry: return D3D12_SHADER_VISIBILITY_GEOMETRY;
    case shader::Stage::kPixel: return D3D12_SHADER_VISIBILITY_PIXEL;
    case shader::Stage::kCompute:
    case shader::Stage::kMesh:
    case shader::Stage::kAmplification:
    case shader::Stage::kLibrary: return D3D12_SHADER_VISIBILITY_ALL;
    }
    return D3D12_SHADER_VISIBILITY_ALL;
}

} // namespace game::gpu::d3d12
