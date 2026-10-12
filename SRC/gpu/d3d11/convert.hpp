// Đổi kiểu của tầng đồ hoạ sang Direct3D 11. Mỗi hàm là một bảng một chiều.
// Đối chiếu bảng DXGI với SRC/gpu/d3d12/convert.cpp. Khác gốc: D3D11 không có barrier tường minh.
#pragma once

#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/format.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <d3d11.h>
#include <d3dcommon.h>
#include <dxgiformat.h>

#include <cstdint>

namespace game::gpu::d3d11 {

// Định dạng DXGI cùng chỉ số với enum Format.
[[nodiscard]] DXGI_FORMAT to_dxgi(Format format) noexcept;
// Unknown khi bảng không có định dạng đó.
[[nodiscard]] Format from_dxgi(DXGI_FORMAT format) noexcept;
// Bản typeless cùng họ; Unknown khi không có.
[[nodiscard]] DXGI_FORMAT typeless_format(DXGI_FORMAT format) noexcept;
// SRV của độ sâu; Unknown nếu không lấy mẫu.
[[nodiscard]] DXGI_FORMAT depth_srv_format(Format format, ViewAspect aspect) noexcept;
// Phép so sánh độ sâu, stencil và sampler.
[[nodiscard]] D3D11_COMPARISON_FUNC to_dxgi(CompareOp value) noexcept;
// Phép ghi vào stencil.
[[nodiscard]] D3D11_STENCIL_OP to_dxgi(StencilOp value) noexcept;
// Hệ số nhân trong phép trộn.
[[nodiscard]] D3D11_BLEND to_dxgi(BlendFactor value) noexcept;
// Phép cộng, trừ, min hoặc max khi trộn.
[[nodiscard]] D3D11_BLEND_OP to_dxgi(BlendOp value) noexcept;
// Mặt trước, mặt sau, hoặc không loại.
[[nodiscard]] D3D11_CULL_MODE to_dxgi(CullMode value) noexcept;
// Tô kín hoặc vẽ khung dây.
[[nodiscard]] D3D11_FILL_MODE to_dxgi(FillMode value) noexcept;
// Danh sách điểm, đoạn, tam giác hoặc patch.
[[nodiscard]] D3D_PRIMITIVE_TOPOLOGY to_topology(Topology value) noexcept;
// R16 hoặc R32 không dấu cho chỉ số.
[[nodiscard]] DXGI_FORMAT to_index(IndexType value) noexcept;
// Lọc gần, xa, mip, so sánh, bất đẳng hướng.
[[nodiscard]] D3D11_FILTER to_filter(const SamplerDesc& desc) noexcept;
// Lặp, gương, kẹp cạnh hoặc kẹp viền.
[[nodiscard]] D3D11_TEXTURE_ADDRESS_MODE to_dxgi(AddressMode value) noexcept;
// Chiều RTV theo loại ảnh và số mẫu.
[[nodiscard]] D3D11_RTV_DIMENSION to_rtv(TextureKind kind, std::uint32_t samples) noexcept;
// Chiều DSV theo loại ảnh và số mẫu.
[[nodiscard]] D3D11_DSV_DIMENSION to_dsv(TextureKind kind, std::uint32_t samples) noexcept;
// Chiều SRV theo loại ảnh và số mẫu.
[[nodiscard]] D3D11_SRV_DIMENSION to_srv(TextureKind kind, std::uint32_t samples) noexcept;
// Chiều UAV theo loại ảnh.
[[nodiscard]] D3D11_UAV_DIMENSION to_uav(TextureKind kind) noexcept;

} // namespace game::gpu::d3d11
