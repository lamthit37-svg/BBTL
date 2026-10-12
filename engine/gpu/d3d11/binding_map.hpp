// Ánh xạ register space của HLSL (D3D12 / Vulkan) sang slot D3D11. D3D11 shader model 5.0 không có
// space. Công thức này phải khớp nhánh F2_DXBC trong shader của render: space 0 và 1 giữ nguyên
// chỉ số, space 2 cộng kSpace2ResourceBase (palette đang là t0 của space 2 thành t8), khối push
// constant đứng ở b1.
#pragma once

#include <cstdint>

namespace game::gpu::d3d11 {

// b1: frame của forward chiếm b0, nên push không được đè lên nó.
inline constexpr std::uint32_t kPushRegister = 1;
// t8: space 1 của model.ps dùng t0..t7. Palette của model.vs là slot 0 của space 2.
// t9: worlds, slot 1 của space 2.
inline constexpr std::uint32_t kSpace2ResourceBase = 8;
// cbuffer và lệnh vẽ của forward đều nhỏ hơn một khối 256 byte.
inline constexpr std::uint32_t kConstantBytes = 256;

using U32 = std::uint32_t;

// space đứng trước slot, cùng thứ tự register(bN, spaceM) của HLSL.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] constexpr U32 resource_register(U32 space, U32 slot) noexcept {
    if (space == 2) return slot + kSpace2ResourceBase;
    return slot;
}

} // namespace game::gpu::d3d11
