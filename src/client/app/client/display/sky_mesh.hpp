// Dựng model vòm từ các dải đã nạp. Ảnh tìm ở Material/ rồi Scene/. Thiếu ảnh thì bỏ dải đó.
// Chất liệu không thắp sáng, không sương, hai mặt: camera đứng trong lòng cầu.
#pragma once

#include "client/stage/sky.hpp"
#include "client/stage/stage.hpp"
#include "io/file.hpp"
#include "render/shade.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::client {

[[nodiscard]] inline std::string sky_key(const Stage& stage) {
    std::string key;
    for (const SkyBand& band : stage.sky) {
        key.append(band.texture);
        key.push_back('\n');
    }
    return key;
}

[[nodiscard]] inline std::optional<resource::Image> sky_image(const std::filesystem::path& root,
    std::string_view file) {
    const std::filesystem::path name = io::path_from_utf8(std::string(file));
    const std::filesystem::path material = root / "Material" / name;
    core::Result<resource::Image> first = resource::load_image_file(io::utf8_of(material));
    if (first) return std::move(*first);
    const std::filesystem::path scene = root / "Scene" / name;
    core::Result<resource::Image> second = resource::load_image_file(io::utf8_of(scene));
    if (!second) return std::nullopt;
    return std::move(*second);
}

inline void add_sky_band(resource::Model& model, const SkyBand& band, resource::Image image) {
    const SkyMesh mesh = sky_band(band);
    if (mesh.vertices.empty()) return;
    const auto image_index = static_cast<std::uint32_t>(model.images.size());
    model.images.push_back(std::move(image));
    resource::Material material;
    material.name = band.texture;
    material.double_sided = true;
    material.unlit = true;
    material.alpha = band.blends ? resource::Alpha::kBlend : resource::Alpha::kOpaque;
    material.color.image = image_index;
    material.color.sampler = 0;
    resource::Material::Pass pass;
    pass.lit = false;
    pass.flags = render::kNoFog | render::kUnlit;
    material.pass = pass;
    const auto material_index = static_cast<std::uint32_t>(model.materials.size());
    model.materials.push_back(std::move(material));
    resource::Primitive primitive;
    primitive.material = material_index;
    primitive.indices = mesh.indices;
    primitive.vertices.reserve(mesh.vertices.size());
    for (const SkyVertex& source : mesh.vertices) {
        resource::Vertex vertex;
        vertex.position = {source.x, source.y, source.z};
        vertex.normal = {source.x, source.y, source.z};
        vertex.uv = {source.u, source.v};
        primitive.vertices.push_back(vertex);
    }
    model.meshes.front().primitives.push_back(std::move(primitive));
}

// Rỗng khi không dải nào có ảnh đọc được.
[[nodiscard]] inline resource::Model sky_model(const Stage& stage, const std::filesystem::path& root) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.name = "sky";
    model.meshes.push_back(std::move(mesh));
    resource::Sampler sampler;
    sampler.wrap_u = resource::Wrap::kRepeat;
    sampler.wrap_v = resource::Wrap::kClamp;
    sampler.has_mip = true;
    model.samplers.push_back(sampler);
    for (const SkyBand& band : stage.sky) {
        std::optional<resource::Image> image = sky_image(root, band.texture);
        if (!image) continue;
        add_sky_band(model, band, std::move(*image));
    }
    if (model.meshes.front().primitives.empty()) return {};
    resource::Node node;
    node.name = "sky";
    node.mesh = 0;
    model.nodes.push_back(std::move(node));
    model.roots.push_back(0);
    return model;
}

} // namespace game::client
