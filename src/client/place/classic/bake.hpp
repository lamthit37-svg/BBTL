// Diễn Classic của client gốc thành Pass trung lập mà engine shade_of đọc. Engine không thấy tệp này.
#pragma once

#include "classic/classic.hpp"
#include "render/shade.hpp"
#include "resource/model.hpp"

namespace game::classic {

[[nodiscard]] inline resource::Material::Pass pass_of(const Classic& classic) noexcept {
    resource::Material::Pass pass;
    pass.ambient = classic.ambient;
    pass.diffuse = classic.diffuse;
    pass.specular = classic.specular;
    pass.shininess = classic.shininess;
    pass.emissive = classic.emissive;
    if (classic.combine == TexOp::kModulate2) pass.color_scale = 2.0F;
    if (classic.combine == TexOp::kModulate4) pass.color_scale = 4.0F;
    const bool is_terrain = classic.lit == Lit::kTerrain;
    if (classic.lit == Lit::kPixel || is_terrain) pass.flags |= render::kPixelLit;
    if (is_terrain) pass.flags |= render::kRawSum;
    if (!classic.has_fog) pass.flags |= render::kNoFog;
    if (classic.combine == TexOp::kAdd) pass.flags |= render::kAddLight;
    if (classic.tracks_vertex) pass.flags |= render::kVertexColor;
    pass.lit = classic.lit != Lit::kOff;
    return pass;
}

// Gán pass cho chất liệu nào còn JSON extras. Engine chỉ giữ chuỗi.
inline void note(resource::Model& model) {
    for (resource::Material& material : model.materials) {
        if (material.extras.empty()) continue;
        const std::optional<Classic> classic = read_classic(material.extras);
        if (classic) material.pass = pass_of(*classic);
    }
}

} // namespace game::classic
