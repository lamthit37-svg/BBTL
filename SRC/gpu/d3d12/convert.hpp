// Đổi kiểu của tầng đồ hoạ sang kiểu Direct3D 12. Mỗi hàm là một bảng một chiều; không hàm nào có
// default trên enum của engine, nên thêm enumerator mà quên ở đây là lỗi dịch (C4062). Enhanced
// Barriers: D3D12 không có giai đoạn nạp đỉnh tách khỏi vertex shader, VertexInput gồm cả
// INDEX_INPUT và VERTEX_SHADING.
// Nguồn: Forge2 src/gpu/d3d12/convert.hpp@d7fcd76. Khác gốc: core/win32.hpp trước d3d12.h vì
// check.py không có NOMINMAX của CMake.
#pragma once

#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/barrier.hpp"
#include "gpu/device.hpp"
#include "shader/types.hpp"

#include <d3d12.h>
#include <dxgiformat.h>

namespace game::gpu::d3d12 {

[[nodiscard]] DXGI_FORMAT to_dxgi(Format format) noexcept;
// Ngược của to_dxgi; Unknown khi engine không có định dạng ấy, hoặc định dạng chỉ có trên Vulkan.
[[nodiscard]] Format from_dxgi(DXGI_FORMAT format) noexcept;
// Định dạng typeless cùng họ, cho TextureUsage::kReinterpret. Unknown khi họ không có bản typeless.
[[nodiscard]] DXGI_FORMAT typeless_format(DXGI_FORMAT format) noexcept;
// Định dạng SRV của một texture độ sâu. Unknown khi aspect không lấy mẫu được.
[[nodiscard]] DXGI_FORMAT depth_srv_format(Format format, ViewAspect aspect) noexcept;

[[nodiscard]] D3D12_COMPARISON_FUNC to_dxgi(CompareOp value) noexcept;
[[nodiscard]] D3D12_STENCIL_OP to_dxgi(StencilOp value) noexcept;
[[nodiscard]] D3D12_BLEND to_dxgi(BlendFactor value) noexcept;
[[nodiscard]] D3D12_BLEND_OP to_dxgi(BlendOp value) noexcept;
[[nodiscard]] D3D12_CULL_MODE to_dxgi(CullMode value) noexcept;
[[nodiscard]] D3D12_FILL_MODE to_dxgi(FillMode value) noexcept;
[[nodiscard]] D3D12_PRIMITIVE_TOPOLOGY to_topology(Topology value) noexcept;
[[nodiscard]] D3D12_PRIMITIVE_TOPOLOGY_TYPE to_topology_type(Topology value) noexcept;
[[nodiscard]] DXGI_FORMAT to_index(IndexType value) noexcept;
[[nodiscard]] D3D12_FILTER to_filter(const SamplerDesc& desc) noexcept;
[[nodiscard]] D3D12_TEXTURE_ADDRESS_MODE to_dxgi(AddressMode value) noexcept;
[[nodiscard]] D3D12_COMMAND_LIST_TYPE to_list(QueueType value) noexcept;
[[nodiscard]] D3D12_RESOURCE_DIMENSION to_dimension(TextureKind kind) noexcept;
[[nodiscard]] D3D12_RTV_DIMENSION to_rtv(TextureKind kind, std::uint32_t samples) noexcept;
[[nodiscard]] D3D12_DSV_DIMENSION to_dsv(TextureKind kind, std::uint32_t samples) noexcept;
[[nodiscard]] D3D12_SRV_DIMENSION to_srv(TextureKind kind, std::uint32_t samples) noexcept;
[[nodiscard]] D3D12_UAV_DIMENSION to_uav(TextureKind kind) noexcept;

[[nodiscard]] D3D12_BARRIER_SYNC to_sync(SyncStage stages) noexcept;
[[nodiscard]] D3D12_BARRIER_ACCESS to_access(Access access) noexcept;
// Hàng Compute dùng biến thể COMPUTE_QUEUE_* cho các bố cục mà hàng đó được phép.
[[nodiscard]] D3D12_BARRIER_LAYOUT to_layout(TextureLayout layout, QueueType queue) noexcept;
[[nodiscard]] D3D12_SHADER_VISIBILITY to_visibility(shader::StageSet stages) noexcept;

} // namespace game::gpu::d3d12
