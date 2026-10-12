#include "client/stage/stage.hpp"

#include "scene/placement.hpp"
#include "scene/scene_file.hpp"
#include "xml/document.hpp"

#include <cstdint>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Ba số của thuộc tính màu, cùng luật token với parseVector3: sai số token thì đen.
[[nodiscard]] Rgb rgb_of(std::string_view text) noexcept {
    const scene::Vector3 colour = scene::parse_vector3(text);
    return Rgb{.red = colour.x, .green = colour.y, .blue = colour.z};
}

// StaticEntity không có "mesh name" không vẽ được. Model đi vào figures, không phải bước này.
void take_prop(Stage& stage, const scene::Object& object) {
    const scene::OptionalText mesh = scene::property(object, "mesh name");
    if (!mesh || mesh->empty()) return;
    Prop prop;
    prop.mesh = std::string(*mesh);
    prop.placement = scene::placement_of(object);
    stage.props.push_back(std::move(prop));
}

void take_figure(Stage& stage, const scene::Object& object) {
    const scene::OptionalText name = scene::property(object, "model name");
    if (!name || name->empty()) return;
    Figure figure;
    figure.model = std::string(*name);
    figure.placement = scene::placement_of(object);
    stage.figures.push_back(std::move(figure));
}

constexpr std::string_view kMainLightOne = "#FairyMainLightOne";
constexpr std::string_view kMainLightTwo = "#FairyMainLightTwo";

// Màu diffuse mặc định của Ogre::Light; specular mặc định là đen.
constexpr Rgb kWhite{.red = 1.0F, .green = 1.0F, .blue = 1.0F};

struct RealAsk {
    std::string_view name;
    float fallback = 0.0F;
};

// Số của thuộc tính, hoặc fallback khi vật thể không khai thuộc tính đó.
[[nodiscard]] float real_or(const scene::Object& object, RealAsk ask) noexcept {
    const scene::OptionalText text = scene::property(object, ask.name);
    if (!text) return ask.fallback;
    return scene::parse_real(*text);
}

struct ColourAsk {
    std::string_view name;
    Rgb fallback;
};

[[nodiscard]] Rgb colour_or(const scene::Object& object, ColourAsk ask) noexcept {
    const scene::OptionalText text = scene::property(object, ask.name);
    if (!text) return ask.fallback;
    return rgb_of(*text);
}

void take_sun(Stage& stage, const scene::Object& object) {
    Sun sun;
    const scene::OptionalText direction = scene::property(object, "direction");
    if (direction) sun.direction = scene::parse_vector3(*direction);
    sun.colour = colour_or(object, {.name = "diffuse", .fallback = kWhite});
    sun.specular = colour_or(object, {.name = "specular", .fallback = Rgb{}});
    sun.power = real_or(object, {.name = "intensity", .fallback = 1.0F});
    stage.suns.push_back(sun);
}

void take_lamp(Stage& stage, const scene::Object& object) {
    Lamp lamp;
    const scene::OptionalText position = scene::property(object, "position");
    if (position) lamp.position = scene::parse_vector3(*position);
    lamp.colour = colour_or(object, {.name = "diffuse", .fallback = kWhite});
    lamp.range = real_or(object, {.name = "range", .fallback = lamp.range});
    lamp.falloff = real_or(object, {.name = "attenuation", .fallback = lamp.falloff});
    lamp.power = real_or(object, {.name = "intensity", .fallback = lamp.power});
    stage.lamps.push_back(lamp);
}

// Đèn không khai type, đèn điểm và đèn spot đều dùng công thức đèn điểm. Bản 2026 không đọc
// góc nón. Đèn directional lấy ở take_suns vì đèn chính phải đứng đầu.
void take_light(Stage& stage, const scene::Object& object) {
    const scene::OptionalText kind = scene::property(object, "type");
    const bool is_lamp = !kind || *kind == "point" || *kind == "spot" || *kind == "spotlight";
    if (is_lamp) take_lamp(stage, object);
}

[[nodiscard]] FogMode fog_mode_of(std::string_view text) noexcept {
    if (text == "exp") return FogMode::kExp;
    if (text == "exp2") return FogMode::kExp2;
    if (text == "linear") return FogMode::kLinear;
    return FogMode::kNone;
}

void take_enviroment(Stage& stage, const scene::Object& object) {
    Fog& fog = stage.fog;
    stage.ambient = colour_or(object, {.name = "ambient", .fallback = stage.ambient});
    stage.background = colour_or(object, {.name = "background", .fallback = stage.background});
    const scene::OptionalText mode = scene::property(object, "fog.mode");
    if (mode) fog.mode = fog_mode_of(*mode);
    fog.colour = colour_or(object, {.name = "fog.colour", .fallback = fog.colour});
    fog.density = real_or(object, {.name = "fog.exp density", .fallback = fog.density});
    fog.start = real_or(object, {.name = "fog.linear start", .fallback = fog.start});
    fog.end = real_or(object, {.name = "fog.linear end", .fallback = fog.end});
}

void take_liquid(Stage& stage, const scene::Object& object) {
    Liquid liquid;
    const scene::OptionalText material = scene::property(object, "material");
    const scene::OptionalText position = scene::property(object, "position");
    const scene::OptionalText scale = scene::property(object, "texture scale");
    if (material) liquid.material = std::string(*material);
    if (position) liquid.position = scene::parse_vector3(*position);
    if (scale) liquid.texture_scale = scene::parse_real(*scale);
    stage.liquids.push_back(std::move(liquid));
}

void take_fx(Stage& stage, const scene::Object& object, bool is_effect) {
    const scene::OptionalText name = scene::property(object, is_effect ? "effect name" : "particle system name");
    if (!name || name->empty()) return;
    FxPlace place;
    place.name = std::string(*name);
    place.placement = scene::placement_of(object);
    place.is_effect = is_effect;
    stage.effects.push_back(std::move(place));
}

void take_object(Stage& stage, const scene::Object& object) {
    if (object.type == "StaticEntity")
        take_prop(stage, object);
    else if (object.type == "Model")
        take_figure(stage, object);
    else if (object.type == "Light")
        take_light(stage, object);
    else if (object.type == "Enviroment")
        take_enviroment(stage, object);
    else if (object.type == "TerrainLiquid")
        take_liquid(stage, object);
    else if (object.type == "ParticleSystem")
        take_fx(stage, object, false);
    else if (object.type == "Effect")
        take_fx(stage, object, true);
}

[[nodiscard]] bool is_sun(const scene::Object& object) noexcept {
    const scene::OptionalText kind = scene::property(object, "type");
    return object.type == "Light" && kind && *kind == "directional";
}

// Lượt lấy đèn directional: đèn chính một, đèn chính hai, rồi các đèn còn lại theo thứ tự tệp.
enum class SunPick : std::uint8_t { kOne, kTwo, kRest };

[[nodiscard]] bool is_picked(const scene::Object& object, SunPick pick) noexcept {
    const bool is_one = object.name == kMainLightOne;
    const bool is_two = object.name == kMainLightTwo;
    if (pick == SunPick::kOne) return is_one;
    if (pick == SunPick::kTwo) return is_two;
    return !is_one && !is_two;
}

void take_picked(Stage& stage, const scene::Object& object, SunPick pick) {
    if (!is_sun(object) || !is_picked(object, pick)) return;
    take_sun(stage, object);
}

void take_suns(Stage& stage, const scene::SceneFile& file, SunPick pick) {
    for (const scene::Object& object : file.objects)
        take_picked(stage, object, pick);
}

void take_entity(const xml::Document& document, std::uint32_t index, std::vector<std::string>& meshes) {
    if (index >= document.elements.size()) return;
    const xml::Element& element = document.elements[index];
    const xml::OptionalText mesh = element.name == "entity" ? xml::attribute(element, "mesh") : xml::OptionalText{};
    if (mesh && !mesh->empty()) meshes.emplace_back(*mesh);
    for (const std::uint32_t child : element.children)
        take_entity(document, child, meshes);
}

} // namespace

Stage stage_of(const scene::SceneFile& file) {
    Stage stage;
    for (const scene::Object& object : file.objects)
        take_object(stage, object);
    take_suns(stage, file, SunPick::kOne);
    take_suns(stage, file, SunPick::kTwo);
    take_suns(stage, file, SunPick::kRest);
    return stage;
}

std::vector<std::string> model_meshes(std::string_view text) {
    const xml::ParseResult document = xml::parse(text);
    std::vector<std::string> meshes;
    if (!document) return meshes;
    take_entity(*document, 0, meshes);
    return meshes;
}

} // namespace game::client
