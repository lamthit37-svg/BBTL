#include "client/stage.hpp"

#include "scene/placement.hpp"
#include "scene/scene_file.hpp"

#include <string>
#include <string_view>
#include <utility>

namespace game::client {
namespace {

// Ba số của thuộc tính màu, cùng luật token với parseVector3: sai số token thì đen.
[[nodiscard]] Rgb rgb_of(std::string_view text) noexcept {
    const scene::Vector3 colour = scene::parse_vector3(text);
    return Rgb{.red = colour.x, .green = colour.y, .blue = colour.z};
}

// StaticEntity không có "mesh name" không vẽ được; đèn điểm và Model không thuộc bước này.
void take_prop(Stage& stage, const scene::Object& object) {
    const scene::OptionalText mesh = scene::property(object, "mesh name");
    if (!mesh || mesh->empty()) return;
    Prop prop;
    prop.mesh = std::string(*mesh);
    prop.placement = scene::placement_of(object);
    stage.props.push_back(std::move(prop));
}

// OGRE ghi đèn directional bằng thuộc tính type; đèn điểm của cảnh không có thuộc tính đó.
void take_sun(Stage& stage, const scene::Object& object) {
    const scene::OptionalText kind = scene::property(object, "type");
    if (!kind || *kind != "directional") return;
    Sun sun;
    const scene::OptionalText direction = scene::property(object, "direction");
    const scene::OptionalText diffuse = scene::property(object, "diffuse");
    if (direction) sun.direction = scene::parse_vector3(*direction);
    if (diffuse) sun.colour = rgb_of(*diffuse);
    stage.suns.push_back(sun);
}

void take_ambient(Stage& stage, const scene::Object& object) {
    const scene::OptionalText ambient = scene::property(object, "ambient");
    if (!ambient) return;
    stage.ambient = rgb_of(*ambient);
}

void take_object(Stage& stage, const scene::Object& object) {
    if (object.type == "StaticEntity")
        take_prop(stage, object);
    else if (object.type == "Light")
        take_sun(stage, object);
    else if (object.type == "Enviroment")
        take_ambient(stage, object);
}

} // namespace

Stage stage_of(const scene::SceneFile& file) {
    Stage stage;
    for (const scene::Object& object : file.objects)
        take_object(stage, object);
    return stage;
}

} // namespace game::client
