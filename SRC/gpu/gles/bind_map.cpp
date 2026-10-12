#include "gpu/gles/bind_map.hpp"

#include "shader/types.hpp"

#include <algorithm>
#include <ranges>

namespace game::gpu::gles {
namespace {

[[nodiscard]] bool is_storage(shader::ResourceKind kind) noexcept {
    return kind == shader::ResourceKind::kBuffer || kind == shader::ResourceKind::kRwBuffer;
}

[[nodiscard]] bool is_texture(shader::ResourceKind kind) noexcept {
    return kind == shader::ResourceKind::kTexture || kind == shader::ResourceKind::kRwTexture;
}

[[nodiscard]] const BindSlot* texture_unit(const BindMap& map, std::uint32_t space, std::uint32_t slot) noexcept {
    for (const BindSlot& item : map.slots) {
        const bool matched = item.kind == BindClass::kTexture && item.space == space && item.slot == slot;
        if (matched) return &item;
    }
    return nullptr;
}

} // namespace

BindMap map_bindings(const shader::ProgramReflection& program) {
    std::vector<shader::Resource> ordered = program.resources;
    std::ranges::sort(ordered, [](const shader::Resource& left, const shader::Resource& right) {
        if (left.space != right.space) return left.space < right.space;
        const shader::RegisterType left_type = shader::register_type(left.kind);
        const shader::RegisterType right_type = shader::register_type(right.kind);
        if (left_type != right_type) return left_type < right_type;
        return left.slot < right.slot;
    });
    BindMap map;
    std::uint32_t uniforms = 0;
    std::uint32_t storages = 0;
    std::uint32_t textures = 0;
    for (const shader::Resource& resource : ordered) {
        BindSlot item;
        item.space = resource.space;
        item.slot = resource.slot;
        item.type = shader::register_type(resource.kind);
        if (resource.kind == shader::ResourceKind::kUniformBuffer) {
            item.kind = BindClass::kUniform;
            item.index = uniforms;
            ++uniforms;
        } else if (is_storage(resource.kind)) {
            item.kind = BindClass::kStorage;
            item.index = storages;
            ++storages;
        } else if (is_texture(resource.kind)) {
            item.kind = BindClass::kTexture;
            item.index = textures;
            ++textures;
        } else if (resource.kind == shader::ResourceKind::kSampler) {
            item.kind = BindClass::kSampler;
            const BindSlot* texture = texture_unit(map, resource.space, resource.slot);
            item.index = texture != nullptr ? texture->index : textures;
            if (texture == nullptr) ++textures;
        } else if (resource.kind == shader::ResourceKind::kPushConstant) {
            item.kind = BindClass::kPush;
            item.index = uniforms;
            map.push_binding = uniforms;
            map.has_push = true;
            ++uniforms;
        } else {
            continue;
        }
        map.slots.push_back(item);
    }
    return map;
}

const BindSlot* find_slot(const BindMap& map, std::uint32_t space, shader::RegisterType type,
    std::uint32_t slot) noexcept {
    for (const BindSlot& item : map.slots) {
        const bool matched = item.space == space && item.type == type && item.slot == slot;
        if (matched) return &item;
    }
    return nullptr;
}

} // namespace game::gpu::gles
