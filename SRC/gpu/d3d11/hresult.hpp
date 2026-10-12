// HRESULT của D3D11 và DXGI sang mã lỗi của engine, cộng tên gỡ trong PIX.
#pragma once

#include "core/error.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/device.hpp"

#include <d3d11.h>
#include <d3dcommon.h>

#include <string_view>

namespace game::gpu::d3d11 {

// Mã engine của một HRESULT đã thất bại.
[[nodiscard]] core::ErrorCode code_of(HRESULT code) noexcept;
// Loại mất thiết bị; kNone khi HRESULT không phải mất thiết bị.
[[nodiscard]] DeviceLoss loss_of(HRESULT code) noexcept;
// Failure khi HRESULT thất bại. Caller chỉ gọi sau khi đã biết FAILED.
[[nodiscard]] core::Failure failed(HRESULT code, core::Message message);
// Gắn tên UTF-8 cho PIX và lớp kiểm tra. Bỏ qua khi tên rỗng.
void set_debug_name(ID3D11DeviceChild& child, std::string_view name) noexcept;

} // namespace game::gpu::d3d11
