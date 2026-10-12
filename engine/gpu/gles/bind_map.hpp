// Số binding GL gọn, dựng từ phản chiếu shader. Binding Vulkan (slot + 1000) vượt trần
// GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS của GLES nên không dùng được. Cùng một thứ tự với
// layout(binding) trong shader GLSL của render.
#pragma once

#include "shader/reflection.hpp"

#include <cstdint>
#include <vector>

namespace game::gpu::gles {

enum class BindClass : std::uint8_t {
    kUniform,
    kStorage,
    kTexture,
    kSampler,
    kPush,
};

struct BindSlot {
    BindClass kind = BindClass::kUniform;
    // Binding UBO, binding SSBO, hoặc texture unit.
    std::uint32_t index = 0;
    std::uint32_t space = 0;
    std::uint32_t slot = 0;
    shader::RegisterType type = shader::RegisterType::kConstant;
};

struct BindMap {
    std::vector<BindSlot> slots;
    std::uint32_t push_binding = 0;
    bool has_push = false;
};

// Đi theo thứ tự phản chiếu đã chuẩn hoá. Sampler dùng unit của texture cùng space và slot.
[[nodiscard]] BindMap map_bindings(const shader::ProgramReflection& program);

[[nodiscard]] const BindSlot* find_slot(const BindMap& map, std::uint32_t space, shader::RegisterType type,
    std::uint32_t slot) noexcept;

} // namespace game::gpu::gles
