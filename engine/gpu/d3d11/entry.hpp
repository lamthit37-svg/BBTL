// Cửa backend D3D11 cho phần chung của gpu: liệt kê adapter và tạo thiết bị. Header này không kéo
// d3d11.h, để device.cpp của phần chung không trộn Vulkan với Direct3D trong cùng một đơn vị dịch.
// Backend này là fallback: máy không có Vulkan hoặc không có D3D12 Enhanced Barriers vẫn mở được
// cửa sổ. Đối chiếu quyết định feature level và swapchain với bgfx renderer_d3d11, không chép file
// đó vì nó không cài gpu::Device.
#pragma once

#include "gpu/device.hpp"

#include <memory>
#include <vector>

namespace game::gpu::d3d11 {

[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();

[[nodiscard]] Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);

} // namespace game::gpu::d3d11
