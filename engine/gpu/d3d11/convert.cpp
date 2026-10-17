/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/d3d11/convert.cpp
 *  PHÂN HỆ   : Gpu / D3d11 / Convert
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bảng đổi kiểu engine sang Direct3D 11. Thứ tự kFormats khớp enum Format.
 *    Đối chiếu bảng DXGI với SRC/gpu/d3d12/convert.cpp. Khác gốc: D3D11 không
 *    có barrier tường minh.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "gpu/d3d11/convert.hpp"

#include "gpu/format.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <d3d11.h>
#include <d3dcommon.h>
#include <dxgiformat.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <utility>

namespace game::gpu::d3d11 {

namespace {

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

D3D11_COMPARISON_FUNC to_dxgi(CompareOp value) noexcept {
    switch (value) {
    case CompareOp::kNever: return D3D11_COMPARISON_NEVER;
    case CompareOp::kLess: return D3D11_COMPARISON_LESS;
    case CompareOp::kEqual: return D3D11_COMPARISON_EQUAL;
    case CompareOp::kLessOrEqual: return D3D11_COMPARISON_LESS_EQUAL;
    case CompareOp::kGreater: return D3D11_COMPARISON_GREATER;
    case CompareOp::kNotEqual: return D3D11_COMPARISON_NOT_EQUAL;
    case CompareOp::kGreaterOrEqual: return D3D11_COMPARISON_GREATER_EQUAL;
    case CompareOp::kAlways: return D3D11_COMPARISON_ALWAYS;
    }
    return D3D11_COMPARISON_ALWAYS;
}

D3D11_STENCIL_OP to_dxgi(StencilOp value) noexcept {
    switch (value) {
    case StencilOp::kKeep: return D3D11_STENCIL_OP_KEEP;
    case StencilOp::kZero: return D3D11_STENCIL_OP_ZERO;
    case StencilOp::kReplace: return D3D11_STENCIL_OP_REPLACE;
    case StencilOp::kIncrementClamp: return D3D11_STENCIL_OP_INCR_SAT;
    case StencilOp::kDecrementClamp: return D3D11_STENCIL_OP_DECR_SAT;
    case StencilOp::kInvert: return D3D11_STENCIL_OP_INVERT;
    case StencilOp::kIncrementWrap: return D3D11_STENCIL_OP_INCR;
    case StencilOp::kDecrementWrap: return D3D11_STENCIL_OP_DECR;
    }
    return D3D11_STENCIL_OP_KEEP;
}

D3D11_BLEND to_dxgi(BlendFactor value) noexcept {
    switch (value) {
    case BlendFactor::kZero: return D3D11_BLEND_ZERO;
    case BlendFactor::kOne: return D3D11_BLEND_ONE;
    case BlendFactor::kSrcColor: return D3D11_BLEND_SRC_COLOR;
    case BlendFactor::kOneMinusSrcColor: return D3D11_BLEND_INV_SRC_COLOR;
    case BlendFactor::kDstColor: return D3D11_BLEND_DEST_COLOR;
    case BlendFactor::kOneMinusDstColor: return D3D11_BLEND_INV_DEST_COLOR;
    case BlendFactor::kSrcAlpha: return D3D11_BLEND_SRC_ALPHA;
    case BlendFactor::kOneMinusSrcAlpha: return D3D11_BLEND_INV_SRC_ALPHA;
    case BlendFactor::kDstAlpha: return D3D11_BLEND_DEST_ALPHA;
    case BlendFactor::kOneMinusDstAlpha: return D3D11_BLEND_INV_DEST_ALPHA;
    case BlendFactor::kSrcAlphaSaturate: return D3D11_BLEND_SRC_ALPHA_SAT;
    case BlendFactor::kConstant: return D3D11_BLEND_BLEND_FACTOR;
    case BlendFactor::kOneMinusConstant: return D3D11_BLEND_INV_BLEND_FACTOR;
    }
    return D3D11_BLEND_ONE;
}

// Hằng (BLEND_FACTOR) và SRC_ALPHA_SAT hợp lệ cho alpha nên giữ nguyên.
D3D11_BLEND to_alpha_blend(BlendFactor value) noexcept {
    switch (value) {
    case BlendFactor::kSrcColor: return D3D11_BLEND_SRC_ALPHA;
    case BlendFactor::kOneMinusSrcColor: return D3D11_BLEND_INV_SRC_ALPHA;
    case BlendFactor::kDstColor: return D3D11_BLEND_DEST_ALPHA;
    case BlendFactor::kOneMinusDstColor: return D3D11_BLEND_INV_DEST_ALPHA;
    case BlendFactor::kZero:
    case BlendFactor::kOne:
    case BlendFactor::kSrcAlpha:
    case BlendFactor::kOneMinusSrcAlpha:
    case BlendFactor::kDstAlpha:
    case BlendFactor::kOneMinusDstAlpha:
    case BlendFactor::kSrcAlphaSaturate:
    case BlendFactor::kConstant:
    case BlendFactor::kOneMinusConstant: return to_dxgi(value);
    }
    return D3D11_BLEND_ONE;
}

D3D11_BLEND_OP to_dxgi(BlendOp value) noexcept {
    switch (value) {
    case BlendOp::kAdd: return D3D11_BLEND_OP_ADD;
    case BlendOp::kSubtract: return D3D11_BLEND_OP_SUBTRACT;
    case BlendOp::kReverseSubtract: return D3D11_BLEND_OP_REV_SUBTRACT;
    case BlendOp::kMin: return D3D11_BLEND_OP_MIN;
    case BlendOp::kMax: return D3D11_BLEND_OP_MAX;
    }
    return D3D11_BLEND_OP_ADD;
}

D3D11_CULL_MODE to_dxgi(CullMode value) noexcept {
    switch (value) {
    case CullMode::kNone: return D3D11_CULL_NONE;
    case CullMode::kFront: return D3D11_CULL_FRONT;
    case CullMode::kBack: return D3D11_CULL_BACK;
    }
    return D3D11_CULL_BACK;
}

D3D11_FILL_MODE to_dxgi(FillMode value) noexcept {
    switch (value) {
    case FillMode::kSolid: return D3D11_FILL_SOLID;
    case FillMode::kWireframe: return D3D11_FILL_WIREFRAME;
    }
    return D3D11_FILL_SOLID;
}

D3D_PRIMITIVE_TOPOLOGY to_topology(Topology value) noexcept {
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

DXGI_FORMAT to_index(IndexType value) noexcept {
    switch (value) {
    case IndexType::kUint16: return DXGI_FORMAT_R16_UINT;
    case IndexType::kUint32: return DXGI_FORMAT_R32_UINT;
    }
    return DXGI_FORMAT_R16_UINT;
}

namespace {

[[nodiscard]] UINT filter_bits(Filter filter, UINT shift) noexcept {
    const bool is_linear = filter == Filter::kLinear;
    const UINT type = is_linear ? D3D11_FILTER_TYPE_LINEAR : D3D11_FILTER_TYPE_POINT;
    return type << shift;
}

} // namespace

// Như D3D11_ENCODE_BASIC_FILTER của d3d11.h: mỗi phép lọc hai bit ở vị trí riêng (min 4, mag 2,
// mip 0), phép so sánh là D3D11_COMPARISON_FILTERING_BIT; dị hướng là lọc tuyến tính cả ba cộng
// D3D11_ANISOTROPIC_FILTERING_BIT. Mã khác các tổ hợp ấy thì CreateSamplerState từ chối.
D3D11_FILTER to_filter(const SamplerDesc& desc) noexcept {
    const bool is_compare = desc.compare != CompareOp::kNever;
    const bool is_aniso = desc.max_anisotropy > 1;
    const Filter min = is_aniso ? Filter::kLinear : desc.min_filter;
    const Filter mag = is_aniso ? Filter::kLinear : desc.mag_filter;
    const Filter mip = is_aniso ? Filter::kLinear : desc.mip_filter;
    UINT code = filter_bits(min, D3D11_MIN_FILTER_SHIFT) | filter_bits(mag, D3D11_MAG_FILTER_SHIFT);
    code |= filter_bits(mip, D3D11_MIP_FILTER_SHIFT);
    if (is_compare) code |= D3D11_COMPARISON_FILTERING_BIT;
    if (is_aniso) code |= D3D11_ANISOTROPIC_FILTERING_BIT;
    return static_cast<D3D11_FILTER>(code);
}

D3D11_TEXTURE_ADDRESS_MODE to_dxgi(AddressMode value) noexcept {
    switch (value) {
    case AddressMode::kRepeat: return D3D11_TEXTURE_ADDRESS_WRAP;
    case AddressMode::kMirrorRepeat: return D3D11_TEXTURE_ADDRESS_MIRROR;
    case AddressMode::kClampToEdge: return D3D11_TEXTURE_ADDRESS_CLAMP;
    case AddressMode::kClampToBorder: return D3D11_TEXTURE_ADDRESS_BORDER;
    }
    return D3D11_TEXTURE_ADDRESS_WRAP;
}

D3D11_RTV_DIMENSION to_rtv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D11_RTV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return is_ms ? D3D11_RTV_DIMENSION_TEXTURE2DMS : D3D11_RTV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray:
        return is_ms ? D3D11_RTV_DIMENSION_TEXTURE2DMSARRAY : D3D11_RTV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D11_RTV_DIMENSION_TEXTURE3D;
    }
    return D3D11_RTV_DIMENSION_TEXTURE2D;
}

D3D11_DSV_DIMENSION to_dsv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D11_DSV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return is_ms ? D3D11_DSV_DIMENSION_TEXTURE2DMS : D3D11_DSV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray:
        return is_ms ? D3D11_DSV_DIMENSION_TEXTURE2DMSARRAY : D3D11_DSV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D11_DSV_DIMENSION_TEXTURE2D;
    }
    return D3D11_DSV_DIMENSION_TEXTURE2D;
}

D3D11_SRV_DIMENSION to_srv(TextureKind kind, std::uint32_t samples) noexcept {
    const bool is_ms = samples > 1;
    switch (kind) {
    case TextureKind::kTex1D: return D3D11_SRV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D: return is_ms ? D3D11_SRV_DIMENSION_TEXTURE2DMS : D3D11_SRV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
        return is_ms ? D3D11_SRV_DIMENSION_TEXTURE2DMSARRAY : D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D11_SRV_DIMENSION_TEXTURE3D;
    case TextureKind::kCube: return D3D11_SRV_DIMENSION_TEXTURECUBE;
    case TextureKind::kCubeArray: return D3D11_SRV_DIMENSION_TEXTURECUBEARRAY;
    }
    return D3D11_SRV_DIMENSION_TEXTURE2D;
}

D3D11_UAV_DIMENSION to_uav(TextureKind kind) noexcept {
    switch (kind) {
    case TextureKind::kTex1D: return D3D11_UAV_DIMENSION_TEXTURE1D;
    case TextureKind::kTex2D:
    case TextureKind::kCube: return D3D11_UAV_DIMENSION_TEXTURE2D;
    case TextureKind::kTex2DArray:
    case TextureKind::kCubeArray: return D3D11_UAV_DIMENSION_TEXTURE2DARRAY;
    case TextureKind::kTex3D: return D3D11_UAV_DIMENSION_TEXTURE3D;
    }
    return D3D11_UAV_DIMENSION_TEXTURE2D;
}

} // namespace game::gpu::d3d11
