/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/d3d11/hresult.cpp
 *  PHÂN HỆ   : Gpu / D3d11 / Hresult
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đổi HRESULT của D3D11 và DXGI sang mã lỗi chung của core và sang loại mất
 *    thiết bị (DeviceLoss).
 *  - Đặt tên gỡ lỗi cho đối tượng D3D11: xoá tên cũ trước, vì runtime dùng
 *    chung state object cùng mô tả và shader dùng chung giữa các pipeline.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "gpu/d3d11/hresult.hpp"

#include "core/error.hpp"
#include "gpu/device.hpp"

#include <d3d11.h>
#include <d3dcommon.h>
#include <string_view>
#include <winerror.h>
#include <winnt.h>

namespace game::gpu::d3d11 {

core::ErrorCode code_of(HRESULT code) noexcept {
    if (code == DXGI_ERROR_DEVICE_REMOVED) return core::ErrorCode::kDeviceLost;
    if (code == DXGI_ERROR_DEVICE_HUNG) return core::ErrorCode::kDeviceLost;
    if (code == DXGI_ERROR_DEVICE_RESET) return core::ErrorCode::kDeviceLost;
    if (code == E_OUTOFMEMORY) return core::ErrorCode::kOutOfMemory;
    if (code == E_INVALIDARG) return core::ErrorCode::kInvalidArgument;
    if (code == DXGI_ERROR_UNSUPPORTED) return core::ErrorCode::kUnsupported;
    if (code == DXGI_ERROR_WAS_STILL_DRAWING) return core::ErrorCode::kWouldBlock;
    if (code == DXGI_ERROR_INVALID_CALL) return core::ErrorCode::kInvalidState;
    return core::ErrorCode::kUnknown;
}

DeviceLoss loss_of(HRESULT code) noexcept {
    if (code == DXGI_ERROR_DEVICE_REMOVED) return DeviceLoss::kRemoved;
    if (code == DXGI_ERROR_DEVICE_HUNG) return DeviceLoss::kReset;
    if (code == DXGI_ERROR_DEVICE_RESET) return DeviceLoss::kReset;
    if (code == E_OUTOFMEMORY) return DeviceLoss::kOutOfMemory;
    return DeviceLoss::kNone;
}

core::Failure failed(HRESULT code, core::Message message) {
    return core::fail(code_of(code), message);
}

void set_debug_name(ID3D11DeviceChild& child, std::string_view name) noexcept {
    if (name.empty()) return;
    // Runtime trả chung một state object cho cùng mô tả, và shader dùng chung được nhiều pipeline
    // đặt tên: tên cũ khác độ dài thì lớp kiểm tra báo lỗi. Xoá tên cũ trước, tên sau cùng thắng.
    child.SetPrivateData(WKPDID_D3DDebugObjectName, 0, nullptr);
    const auto bytes = static_cast<UINT>(name.size());
    child.SetPrivateData(WKPDID_D3DDebugObjectName, bytes, name.data());
}

} // namespace game::gpu::d3d11
