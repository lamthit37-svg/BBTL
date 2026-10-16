/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/scene.cpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc .EnScene thành ensky::Scene. Số đọc bằng std::from_chars; thuộc tính
 *    hỏng hoặc vắng giữ giá trị mặc định của kiểu, đúng với hàm dựng của bản gốc.
 *  - Các nhóm thuộc tính (SkyCloudsLayer, Moon...) tách thành hàm riêng để mỗi
 *    hàm chỉ một cấp lồng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ensky/scene.hpp"

#include "core/gbk.hpp"
#include "core/number.hpp"
#include "xml/document.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ensky {
namespace {

constexpr std::string_view kBackground = "backgroud";

// Số byte nối tiếp sau byte đầu của một ký tự UTF-8; -1 khi byte không thể mở đầu ký tự.
[[nodiscard]] int tail_of(std::uint8_t lead) noexcept {
    if (lead < 0x80U) return 0;
    if ((lead & 0xE0U) == 0xC0U) return 1;
    if ((lead & 0xF0U) == 0xE0U) return 2;
    if ((lead & 0xF8U) == 0xF0U) return 3;
    return -1;
}

// Số byte nối tiếp còn đợi sau byte này; -1 khi chuỗi sai.
[[nodiscard]] int step_utf8(int pending, std::uint8_t byte) noexcept {
    const bool is_tail = (byte & 0xC0U) == 0x80U;
    if (pending > 0) return is_tail ? pending - 1 : -1;
    return tail_of(byte);
}

// UTF-8 hợp lệ (không đòi chặt chẽ mọi trường hợp tối thiểu): đủ để phân biệt với GBK.
[[nodiscard]] bool is_utf8(std::string_view text) noexcept {
    int pending = 0;
    for (const char raw : text) {
        pending = step_utf8(pending, static_cast<std::uint8_t>(raw));
        if (pending < 0) return false;
    }
    return pending == 0;
}

[[nodiscard]] std::optional<std::string> utf8_of(std::string_view bytes) {
    if (is_utf8(bytes)) return std::string(bytes);
    return core::utf8_from_gbk(bytes);
}

using xml::Document;
using xml::Element;

// Phần tử con đầu tiên mang tên này; nullptr khi không có.
[[nodiscard]] const Element* child_of(const Document& document, const Element& parent,
    std::string_view name) {
    for (const std::uint32_t index : parent.children) {
        const Element& item = document.elements[index];
        if (item.name == name) return &item;
    }
    return nullptr;
}

// Chữ của phần tử con; rỗng khi không có.
[[nodiscard]] std::string text_of(const Document& document, const Element& parent,
    std::string_view name) {
    const Element* item = child_of(document, parent, name);
    if (item == nullptr) return {};
    return item->text;
}

[[nodiscard]] float number_in(std::string_view text, float fallback) noexcept {
    const core::OptionalDouble parsed = core::parse_double(text);
    if (!parsed) return fallback;
    return static_cast<float>(parsed->value);
}

[[nodiscard]] std::size_t after_spaces(std::string_view text, std::size_t from) noexcept {
    const std::size_t end = text.find_first_not_of(' ', from);
    return end == std::string_view::npos ? text.size() : end;
}

// Các số cách nhau bằng khoảng trắng. Thiếu thì phần còn lại giữ fallback.
template <std::size_t N>
[[nodiscard]] std::array<float, N> numbers_in(std::string_view text, float fallback) noexcept {
    std::array<float, N> values{};
    values.fill(fallback);
    std::size_t cursor = 0;
    for (std::size_t index = 0; index < N; ++index) {
        cursor = after_spaces(text, cursor);
        const core::OptionalDouble parsed = core::parse_double(text.substr(cursor));
        if (!parsed) break;
        values.at(index) = static_cast<float>(parsed->value);
        cursor += parsed->length;
    }
    return values;
}

[[nodiscard]] float float_of(const Document& document, const Element& parent, std::string_view name,
    float fallback = 0.0F) {
    const std::string text = text_of(document, parent, name);
    return number_in(text, fallback);
}

[[nodiscard]] int int_of(const Document& document, const Element& parent, std::string_view name) {
    return static_cast<int>(float_of(document, parent, name));
}

[[nodiscard]] bool bool_of(std::string_view text) noexcept {
    return text == "true" || text == "1";
}

[[nodiscard]] float attr_float(const Element& element, std::string_view name,
    float fallback = 0.0F) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (!text) return fallback;
    return number_in(*text, fallback);
}

[[nodiscard]] bool attr_bool(const Element& element, std::string_view name) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    return text && bool_of(*text);
}

[[nodiscard]] std::string attr_text(const Element& element, std::string_view name) {
    return std::string(xml::attribute(element, name).value_or(std::string_view{}));
}

[[nodiscard]] Colour colour_in(std::string_view text) noexcept {
    const std::array<float, 3> rgb = numbers_in<3>(text, 0.0F);
    return Colour{.red = rgb[0], .green = rgb[1], .blue = rgb[2]};
}

[[nodiscard]] Colour attr_colour(const Element& element, std::string_view name,
    Colour fallback = {}) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (!text) return fallback;
    return colour_in(*text);
}

[[nodiscard]] ogre::Vec3 attr_vec3(const Element& element, std::string_view name) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (!text) return {};
    const std::array<float, 3> xyz = numbers_in<3>(*text, 0.0F);
    return ogre::Vec3{.x = xyz[0], .y = xyz[1], .z = xyz[2]};
}

[[nodiscard]] Dome dome_of(const Document& document, const Element& element) {
    Dome dome;
    dome.texture = text_of(document, element, "texture");
    dome.texture_ex = text_of(document, element, "textureEx");
    dome.height = float_of(document, element, "hight");
    dome.mie_amount = float_of(document, element, "mieAmount");
    dome.vertex_height_effect = float_of(document, element, "vertexHeightEffect");
    dome.sun_height_effect = float_of(document, element, "sunHeightEffect");
    dome.power = float_of(document, element, "power", 1.0F);
    return dome;
}

[[nodiscard]] Rim rim_of(const Document& document, const Element& element) {
    Rim rim;
    rim.scatter_strength = float_of(document, element, "scatteringStrength");
    rim.scatter_power = float_of(document, element, "scatteringPower");
    rim.strength = float_of(document, element, "rimStrength");
    rim.power = float_of(document, element, "rimPower");
    rim.detect_power = float_of(document, element, "rimDetectPower");
    rim.detect_width = float_of(document, element, "rimDetectWidth");
    return rim;
}

[[nodiscard]] CloudKey cloud_key_of(const Element& element) noexcept {
    CloudKey key;
    key.time = attr_float(element, "time");
    key.fog = attr_float(element, "fog");
    key.alpha = attr_float(element, "alpha");
    key.speed = attr_float(element, "cloudspeed");
    key.ambient_blend = attr_float(element, "ambientBlend");
    return key;
}

[[nodiscard]] RingKey ring_key_of(const Element& element) noexcept {
    RingKey key;
    key.time = attr_float(element, "time");
    key.fog_blend = attr_float(element, "fogblend");
    key.ambient_blend = attr_float(element, "ambientBlend");
    key.alpha = attr_float(element, "alpha");
    key.roll_speed = attr_float(element, "rollspeed");
    key.vertical_speed = attr_float(element, "verticalSpeed");
    key.fade_range = attr_float(element, "fadeRange");
    return key;
}

// Mốc TimeNode của một lớp, xếp theo time tăng (bản gốc giữ chúng trong std::map).
// Hai mốc cùng time: mốc đứng trước thắng, như map::insert.
template <class Key>
void sort_keys(std::vector<Key>& keys) {
    std::ranges::stable_sort(keys, {}, &Key::time);
    const auto same = [](const Key& left, const Key& right) { return left.time == right.time; };
    keys.erase(std::ranges::unique(keys, same).begin(), keys.end());
}

template <class Key, class Make>
[[nodiscard]] std::vector<Key> keys_of(const Document& document, const Element& layer, Make make) {
    std::vector<Key> keys;
    const Element* info = child_of(document, layer, "TimeNodesInfo");
    if (info == nullptr) return keys;
    for (const std::uint32_t index : info->children) {
        const Element& node = document.elements[index];
        if (node.name == "TimeNode") keys.push_back(make(node));
    }
    sort_keys(keys);
    return keys;
}

[[nodiscard]] CloudLayer cloud_of(const Document& document, const Element& element) {
    CloudLayer cloud;
    cloud.name = text_of(document, element, "name");
    cloud.layer = int_of(document, element, "layer");
    cloud.is_flipped = bool_of(text_of(document, element, "turnoverMesh"));
    cloud.height = float_of(document, element, "skyCloudHeight");
    cloud.mesh = text_of(document, element, "meshname");
    cloud.texture = text_of(document, element, "texturename");
    cloud.yaw = float_of(document, element, "rotangle");
    cloud.tile = numbers_in<4>(text_of(document, element, "textureTile"), 0.0F);
    cloud.rim = rim_of(document, element);
    cloud.keys = keys_of<CloudKey>(document, element, cloud_key_of);
    return cloud;
}

[[nodiscard]] RingLayer ring_of(const Document& document, const Element& element) {
    RingLayer ring;
    ring.name = text_of(document, element, "name");
    ring.layer = int_of(document, element, "layer");
    ring.is_flipped = bool_of(text_of(document, element, "turnoverMesh"));
    ring.height = float_of(document, element, "CloudHeight");
    ring.scale = float_of(document, element, "CloudScale", 1.0F);
    ring.repeat = float_of(document, element, "TextureRepeat", 1.0F);
    ring.offset = float_of(document, element, "CloudOffset");
    ring.parallax = float_of(document, element, "parallax");
    ring.mesh = text_of(document, element, "meshname");
    ring.texture = text_of(document, element, "texturename");
    ring.rim = rim_of(document, element);
    ring.keys = keys_of<RingKey>(document, element, ring_key_of);
    return ring;
}

void read_clouds(const Document& document, const Element& group, Sky& sky) {
    for (const std::uint32_t index : group.children) {
        const Element& item = document.elements[index];
        if (item.name == "SkyCloudsLayer") sky.clouds.push_back(cloud_of(document, item));
    }
}

void read_rings(const Document& document, const Element& group, Sky& sky) {
    for (const std::uint32_t index : group.children) {
        const Element& item = document.elements[index];
        if (item.name == "RingCloudsLayer") sky.rings.push_back(ring_of(document, item));
    }
}

[[nodiscard]] Star star_of(const Element& element) {
    Star star;
    star.is_enabled = attr_bool(element, "Enable");
    star.count = static_cast<int>(attr_float(element, "StarCount"));
    star.radius = attr_float(element, "Radius");
    star.intensity = attr_float(element, "Intensity");
    star.size = attr_float(element, "Size");
    star.flicker_speed = attr_float(element, "FlickerSpeed");
    star.start_colour = numbers_in<4>(attr_text(element, "StartColour"), 0.0F);
    star.end_colour = numbers_in<4>(attr_text(element, "EndColour"), 0.0F);
    star.is_fixed = attr_bool(element, "starfix");
    return star;
}

[[nodiscard]] Moon moon_of(const Element& element) {
    Moon moon;
    moon.is_enabled = attr_bool(element, "Enable");
    moon.texture = attr_text(element, "moon_tex_name");
    moon.scale = attr_float(element, "scale", 1.0F);
    moon.orient = attr_float(element, "moonOrient");
    moon.angle = attr_float(element, "moonAngle");
    moon.up_time = attr_float(element, "moonUpTime");
    moon.down_time = attr_float(element, "moonDownTime");
    moon.is_fixed = attr_bool(element, "moonfix");
    moon.layer = static_cast<int>(attr_float(element, "layer"));
    return moon;
}

[[nodiscard]] Sun sun_of(const Element& element) {
    Sun sun;
    sun.is_enabled = attr_bool(element, "Enable");
    sun.texture = attr_text(element, "sun_tex_name");
    sun.uses_flare = attr_bool(element, "useSunFlare");
    sun.flare_texture = attr_text(element, "sunflare_tex_name");
    sun.scale = attr_float(element, "scale", 1.0F);
    sun.orient = attr_float(element, "sunOrient");
    sun.angle = attr_float(element, "sunAngle");
    sun.up_time = attr_float(element, "sunUpTime");
    sun.down_time = attr_float(element, "sunDownTime");
    sun.intensity_step = attr_float(element, "intensityStep");
    sun.is_fixed = attr_bool(element, "sunfix");
    sun.lens_flare = attr_text(element, "lensFlare_settings_name");
    sun.uses_lens_flare = attr_bool(element, "useLensFlare");
    sun.layer = static_cast<int>(attr_float(element, "layer"));
    return sun;
}

[[nodiscard]] EnvKey env_of(const Element& element) {
    EnvKey key;
    key.time = attr_float(element, "time");
    key.ambient = attr_colour(element, "ambient");
    key.fog = attr_colour(element, "fog");
    key.fog_near = attr_float(element, "fog_near_distance");
    key.fog_far = attr_float(element, "fog_far_distance");
    key.light_one = attr_colour(element, "light_one");
    key.light_one_specular = attr_colour(element, "light_one_specular");
    key.light_one_direction = attr_vec3(element, "light_one_direction");
    key.light_one_intensity = attr_float(element, "light_one_intensity", 1.0F);
    key.light_two = attr_colour(element, "light_two");
    key.light_two_specular = attr_colour(element, "light_two_specular");
    key.light_two_direction = attr_vec3(element, "light_two_direction");
    key.light_two_intensity = attr_float(element, "light_two_intensity", 1.0F);
    key.actor_one = attr_colour(element, "actor_light_one");
    key.actor_one_intensity = attr_float(element, "actor_light_one_intensity", 1.0F);
    key.actor_two = attr_colour(element, "actor_light_two");
    key.actor_two_intensity = attr_float(element, "actor_light_two_intensity", 1.0F);
    key.actor_ambient = attr_colour(element, "actor_light_ambient");
    const Colour white{.red = 1.0F, .green = 1.0F, .blue = 1.0F};
    key.dome_ambient = attr_colour(element, "skyDomeAmbientColor", white);
    key.dome_strength = attr_float(element, "skyDomeAmbientColorStrength", 1.0F);
    return key;
}

void read_env(const Document& document, const Element& group, Sky& sky) {
    for (const std::uint32_t index : group.children) {
        const Element& item = document.elements[index];
        if (item.name == "EnvKey") sky.env.push_back(env_of(item));
    }
    sort_keys(sky.env);
}

void read_effects(const Document& document, const Element& group, Sky& sky) {
    for (const std::uint32_t index : group.children) {
        const Element& item = document.elements[index];
        if (item.name != "Effect") continue;
        sky.effects.push_back(attr_text(item, "effect_name"));
    }
}

// Một phần tử con của EnSky: mỗi tên một nhóm, tên không trùng nhau.
void read_part(const Document& document, const Element& item, Sky& sky) {
    const std::string_view name = item.name;
    if (name == "SkyDome") sky.dome = dome_of(document, item);
    if (name == "SkyClouds") read_clouds(document, item, sky);
    if (name == "SkyRingClouds") read_rings(document, item, sky);
    if (name == "Star") sky.star = star_of(item);
    if (name == "Moon") sky.moon = moon_of(item);
    if (name == "Sun") sky.sun = sun_of(item);
    if (name == "Effects") read_effects(document, item, sky);
    if (name == "LightAndFog") read_env(document, item, sky);
}

[[nodiscard]] Sky sky_of(const Document& document, const Element& element) {
    Sky sky;
    for (const std::uint32_t index : element.children) {
        read_part(document, document.elements[index], sky);
    }
    return sky;
}

[[nodiscard]] std::vector<Point> polygon_of(const Document& document, const Element& element) {
    std::vector<Point> points;
    for (const std::uint32_t index : element.children) {
        const Element& item = document.elements[index];
        if (item.name != "Point") continue;
        const std::array<float, 2> coords = numbers_in<2>(item.text, 0.0F);
        points.push_back(Point{.x = coords[0], .z = coords[1]});
    }
    return points;
}

void read_groups(const Document& document, const Element& groups, Region& region) {
    for (const std::uint32_t index : groups.children) {
        const Element& item = document.elements[index];
        if (item.name == "polygon") region.polygons.push_back(polygon_of(document, item));
    }
}

[[nodiscard]] std::optional<Region> region_of(const Document& document, const Element& element) {
    const Element* sky = child_of(document, element, "EnSky");
    if (sky == nullptr) return std::nullopt;
    Region region;
    region.name = attr_text(element, "name");
    region.max_distance = attr_float(element, "maxAffectDistance");
    const Element* groups = child_of(document, element, "RegionGroups");
    if (groups != nullptr) read_groups(document, *groups, region);
    region.sky = sky_of(document, *sky);
    return region;
}

void read_composite(const Document& document, const Element& composite, Scene& scene) {
    for (const std::uint32_t index : composite.children) {
        const Element& item = document.elements[index];
        if (item.name != "EnRegion") continue;
        std::optional<Region> region = region_of(document, item);
        if (region) scene.regions.push_back(std::move(*region));
    }
}

void add_unique(std::vector<std::string>& names, const std::string& name) {
    if (name.empty()) return;
    if (std::ranges::find(names, name) != names.end()) return;
    names.push_back(name);
}

} // namespace

std::expected<Scene, Fault> read_scene(std::string_view bytes) {
    const std::optional<std::string> text = utf8_of(bytes);
    if (!text) return std::unexpected(Fault::kBadText);
    const xml::ParseResult parsed = xml::parse(*text);
    if (!parsed) return std::unexpected(Fault::kBadXml);
    const Document& document = *parsed;
    const Element& root = document.elements.front();
    if (root.name != "EnScene") return std::unexpected(Fault::kNotScene);
    Scene scene;
    const Element* composite = child_of(document, root, "EnRegionComposite");
    if (composite != nullptr) read_composite(document, *composite, scene);
    const Element* direct = child_of(document, root, "EnSky");
    if (direct != nullptr) {
        Region region;
        region.name = std::string(kBackground);
        region.sky = sky_of(document, *direct);
        scene.regions.push_back(std::move(region));
    }
    if (scene.regions.empty()) return std::unexpected(Fault::kNoSky);
    return scene;
}

namespace {

template <class Item>
void add_all(std::vector<std::string>& names, const std::vector<Item>& items,
    std::string Item::*field) {
    for (const Item& item : items) {
        add_unique(names, item.*field);
    }
}

void add_textures(std::vector<std::string>& names, const Sky& sky) {
    add_unique(names, sky.dome.texture);
    add_unique(names, sky.dome.texture_ex);
    add_all(names, sky.clouds, &CloudLayer::texture);
    add_all(names, sky.rings, &RingLayer::texture);
    add_unique(names, sky.moon.texture);
    add_unique(names, sky.sun.texture);
    add_unique(names, sky.sun.flare_texture);
}

} // namespace

std::vector<std::string> textures_of(const Scene& scene) {
    std::vector<std::string> names;
    for (const Region& region : scene.regions) {
        add_textures(names, region.sky);
    }
    return names;
}

std::vector<std::string> meshes_of(const Scene& scene) {
    std::vector<std::string> names;
    for (const Region& region : scene.regions) {
        add_all(names, region.sky.clouds, &CloudLayer::mesh);
        add_all(names, region.sky.rings, &RingLayer::mesh);
    }
    return names;
}

} // namespace game::ensky
