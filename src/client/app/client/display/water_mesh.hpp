// Mặt TerrainLiquid: lũ trên địa hình thành một model. Ảnh lấy từ Material/all.material,
// tìm ở Material/ rồi Scene/. Không có ảnh thì bỏ mặt đó. scroll_anim ghi vào emissive để
// shader model cuộn UV; shader_water01 của login không khai scroll_anim.
#pragma once

#include "client/display/sky_mesh.hpp"
#include "client/map/ground.hpp"
#include "client/map/liquid.hpp"
#include "client/stage/stage.hpp"
#include "io/file.hpp"
#include "render/shade.hpp"
#include "resource/model.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>

namespace game::client {

[[nodiscard]] inline std::string water_key(const Stage& stage, const map::Ground* ground) {
    if (ground == nullptr || stage.liquids.empty()) return {};
    std::string key = ground->file.name;
    key.push_back('\n');
    for (const Liquid& liquid : stage.liquids) {
        key.append(liquid.material);
        key.push_back(' ');
        key.append(std::to_string(liquid.position.x));
        key.push_back(' ');
        key.append(std::to_string(liquid.position.y));
        key.push_back(' ');
        key.append(std::to_string(liquid.position.z));
        key.push_back('\n');
    }
    return key;
}

[[nodiscard]] inline std::string material_book(const std::filesystem::path& root) {
    const io::TextResult text = io::read_text(root / "Material" / "all.material");
    if (!text) return {};
    return *text;
}

inline void add_water(resource::Model& model, const map::LiquidSheet& sheet, resource::Image image, bool blends,
    float speed_u, float speed_v) {
    if (sheet.points.empty() || sheet.indices.empty()) return;
    const auto image_index = static_cast<std::uint32_t>(model.images.size());
    model.images.push_back(std::move(image));
    resource::Material material;
    material.double_sided = true;
    material.alpha = blends ? resource::Alpha::kBlend : resource::Alpha::kOpaque;
    const bool scrolls = speed_u != 0.0F || speed_v != 0.0F;
    if (scrolls) material.unlit = true;
    if (scrolls) material.emissive = math::Float3{speed_u, speed_v, 0.0F};
    material.color.image = image_index;
    material.color.sampler = 0;
    const auto material_index = static_cast<std::uint32_t>(model.materials.size());
    model.materials.push_back(std::move(material));
    resource::Primitive primitive;
    primitive.material = material_index;
    primitive.indices = sheet.indices;
    primitive.vertices.reserve(sheet.points.size());
    for (const map::LiquidPoint& source : sheet.points) {
        resource::Vertex vertex;
        vertex.position = {source.x, source.y, source.z};
        vertex.normal = {0.0F, 1.0F, 0.0F};
        vertex.uv = {source.u, source.v};
        primitive.vertices.push_back(vertex);
    }
    model.meshes.front().primitives.push_back(std::move(primitive));
}

// Rỗng khi không mặt nào có cả lưới lẫn ảnh.
[[nodiscard]] inline resource::Model water_model(const Stage& stage, const map::Ground& ground,
    std::string_view script, const std::filesystem::path& root) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.name = "water";
    model.meshes.push_back(std::move(mesh));
    resource::Sampler sampler;
    sampler.wrap_u = resource::Wrap::kRepeat;
    sampler.wrap_v = resource::Wrap::kRepeat;
    model.samplers.push_back(sampler);
    for (const Liquid& liquid : stage.liquids) {
        const map::LiquidLookResult look = map::find_liquid_look(script, liquid.material);
        if (!look || look->texture.empty()) continue;
        std::optional<resource::Image> image = sky_image(root, look->texture);
        if (!image) continue;
        map::LiquidField field;
        field.terrain = &ground.file;
        field.heights = &ground.heights;
        field.grid = &ground.grid;
        field.place.x = liquid.position.x;
        field.place.y = liquid.position.y;
        field.place.z = liquid.position.z;
        field.place.texture_scale = liquid.texture_scale;
        add_water(model, map::build_liquid(field), std::move(*image), look->blends, look->speed_u, look->speed_v);
    }
    if (model.meshes.front().primitives.empty()) return {};
    resource::Node node;
    node.name = "water";
    node.mesh = 0;
    model.nodes.push_back(std::move(node));
    model.roots.push_back(0);
    return model;
}

} // namespace game::client
