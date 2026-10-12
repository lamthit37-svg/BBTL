// Cửa backend D3D12 cho phần chung của gpu: liệt kê adapter và tạo thiết bị. Header này không kéo
// d3d12.h, để device.cpp của phần chung không trộn Vulkan với Direct3D trong cùng một đơn vị dịch.
// Nguồn: Forge2 src/gpu/d3d12/entry.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "gpu/device.hpp"

#include <memory>
#include <vector>

namespace game::gpu::d3d12 {

[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();

[[nodiscard]] Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);

} // namespace game::gpu::d3d12
