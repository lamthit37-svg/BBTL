// Cửa backend GLES. Header này không kéo gl.h, để device.cpp chung không mở context.
#pragma once

#include "gpu/device.hpp"

#include <memory>
#include <vector>

namespace game::gpu::gles {

[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();

[[nodiscard]] Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);

} // namespace game::gpu::gles
