// Lớp lấy từ SkyLayer và TextureGroup của thời tiết current_weather. Vòm đơn vị: pitch 0
// ở +Y, chân trời ở mặt phẳng XZ.
#include "client/stage/sky.hpp"

#include "client/stage/stage.hpp"
#include "core/check.hpp"
#include "core/number.hpp"
#include "scene/placement.hpp"
#include "xml/document.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

constexpr int kYawSteps = 32;
constexpr int kPitchSteps = 8;
constexpr float kTurn = 6.2831853F;

[[nodiscard]] std::string attr(const xml::Element& element, std::string_view name) {
    return std::string(xml::attribute(element, name).value_or(std::string_view{}));
}

[[nodiscard]] float number_attr(const xml::Element& element, std::string_view name) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (!text) return 0.0F;
    const core::OptionalDouble parsed = core::parse_double(*text);
    if (!parsed) return 0.0F;
    return static_cast<float>(parsed->value);
}

[[nodiscard]] int repeat_attr(const xml::Element& element, std::string_view name) noexcept {
    const float value = number_attr(element, name);
    if (value < 1.0F) return 1;
    return static_cast<int>(value);
}

struct Walk {
    const xml::Document* document = nullptr;
    std::vector<std::uint32_t> pending;
    const xml::Element* group = nullptr;
};

void push_children(Walk& walk, const xml::Element& element) {
    for (const std::uint32_t child : element.children)
        walk.pending.push_back(child);
}

void take_group(Walk& walk, std::uint32_t index) {
    const xml::Element& element = walk.document->elements[index];
    if (element.name == "TextureGroup" && walk.group == nullptr) walk.group = &element;
    push_children(walk, element);
}

[[nodiscard]] const xml::Element* texture_group(const xml::Document& document, std::uint32_t root) {
    Walk walk;
    walk.document = &document;
    walk.pending.push_back(root);
    while (!walk.pending.empty()) {
        const std::uint32_t index = walk.pending.back();
        walk.pending.pop_back();
        take_group(walk, index);
    }
    return walk.group;
}

struct NameHit {
    const xml::Element* element = nullptr;
};

void consider_name(NameHit& hit, const xml::Document& document, std::uint32_t child, std::string_view name) {
    if (hit.element != nullptr || document.elements[child].name != name) return;
    hit.element = &document.elements[child];
}

[[nodiscard]] const xml::Element* child_named(const xml::Document& document, const xml::Element& parent,
    std::string_view name) {
    NameHit hit;
    for (const std::uint32_t child : parent.children)
        consider_name(hit, document, child, name);
    return hit.element;
}

struct WeatherHit {
    const xml::Element* element = nullptr;
    std::uint32_t index = 0;
    bool matched = false;
};

void consider_weather(WeatherHit& hit, const xml::Document& document, std::uint32_t index, std::string_view current) {
    if (hit.matched) return;
    const xml::Element& element = document.elements[index];
    if (element.name != "Weather") return;
    if (hit.element == nullptr) {
        hit.element = &element;
        hit.index = index;
    }
    if (attr(element, "name") != current) return;
    hit.element = &element;
    hit.index = index;
    hit.matched = true;
}

[[nodiscard]] WeatherHit weather_of(const xml::Document& document) {
    WeatherHit hit;
    const xml::Element* seasons = child_named(document, document.elements.front(), "SkyWeathers");
    if (seasons == nullptr) return hit;
    const std::string current = attr(*seasons, "current_weather");
    for (const std::uint32_t child : seasons->children)
        consider_weather(hit, document, child, current);
    return hit;
}

struct LayerName {
    std::string_view layer;
    std::string_view texture;
    std::string_view repeats;
    bool blends = false;
};

constexpr std::array<LayerName, 5> kLayers{{
    {.layer = "background", .texture = "background_texture", .repeats = "background_wrap"},
    {.layer = "far_cloud", .texture = "far_cloud_texture", .repeats = "far_cloud_wrap"},
    {.layer = "mountain", .texture = "mountain_texture", .repeats = "mountain_wrap"},
    {.layer = "near_cloud", .texture = "near_cloud_texture", .repeats = "near_cloud_wrap"},
    {.layer = "fog", .texture = "fog_texture", .repeats = "fog_wrap", .blends = true},
}};

struct LayerHit {
    const LayerName* layer = nullptr;
};

void consider_layer_name(LayerHit& hit, const LayerName& layer, std::string_view name) noexcept {
    if (hit.layer == nullptr && layer.layer == name) hit.layer = &layer;
}

[[nodiscard]] const LayerName* layer_named(std::string_view name) noexcept {
    LayerHit hit;
    for (const LayerName& layer : kLayers)
        consider_layer_name(hit, layer, name);
    return hit.layer;
}

void add_band(SkyDome& dome, const xml::Element& layer, const xml::Element& group) {
    const LayerName* named = layer_named(attr(layer, "name"));
    if (named == nullptr) return;
    if (number_attr(layer, "texture_count") < 1.0F) return;
    const std::string texture = attr(group, named->texture);
    if (texture.empty()) return;
    SkyBand band;
    band.texture = texture;
    band.pitch_start = number_attr(layer, "pitch_start");
    band.pitch_end = number_attr(layer, "pitch_end");
    band.repeats = repeat_attr(group, named->repeats);
    band.blends = named->blends;
    dome.bands.push_back(std::move(band));
}

void consider_layer(SkyDome& dome, const xml::Document& document, const xml::Element& group, std::uint32_t child) {
    const xml::Element& element = document.elements[child];
    if (element.name != "SkyLayer") return;
    add_band(dome, element, group);
}

void add_layers(SkyDome& dome, const xml::Document& document, const xml::Element& group) {
    const xml::Element* layers = child_named(document, document.elements.front(), "SkySphereLayers");
    if (layers == nullptr) return;
    for (const std::uint32_t child : layers->children)
        consider_layer(dome, document, group, child);
}

// Một nút lưới của vòm: cột chạy theo yaw, hàng chạy theo pitch.
struct GridNode {
    int column = 0;
    int row = 0;
};

void push_vertex(SkyMesh& mesh, const SkyBand& band, GridNode node) {
    const float around = static_cast<float>(node.column) / static_cast<float>(kYawSteps);
    const float upward = static_cast<float>(node.row) / static_cast<float>(kPitchSteps);
    const float yaw = kTurn * around;
    const float span = band.pitch_end - band.pitch_start;
    const float pitch = band.pitch_start + (span * upward);
    const int repeats = band.repeats > 0 ? band.repeats : 1;
    SkyVertex vertex;
    vertex.x = std::sin(pitch) * std::sin(yaw);
    vertex.y = std::cos(pitch);
    vertex.z = std::sin(pitch) * std::cos(yaw);
    vertex.u = (yaw / kTurn) * static_cast<float>(repeats);
    vertex.v = span == 0.0F ? 0.0F : (pitch - band.pitch_start) / span;
    mesh.vertices.push_back(vertex);
}

void push_row(SkyMesh& mesh, const SkyBand& band, int row) {
    for (int column = 0; column <= kYawSteps; ++column) {
        const GridNode node{.column = column, .row = row};
        push_vertex(mesh, band, node);
    }
}

void push_cell(std::vector<std::uint32_t>& indices, int columns, int column, int row) {
    const auto stride = static_cast<std::uint32_t>(columns);
    const auto near_left = (static_cast<std::uint32_t>(row) * stride) + static_cast<std::uint32_t>(column);
    const auto near_right = near_left + 1U;
    const auto far_left = near_left + stride;
    const auto far_right = far_left + 1U;
    indices.push_back(near_left);
    indices.push_back(far_left);
    indices.push_back(near_right);
    indices.push_back(near_right);
    indices.push_back(far_left);
    indices.push_back(far_right);
}

void push_cells(SkyMesh& mesh, int row) {
    for (int column = 0; column < kYawSteps; ++column)
        push_cell(mesh.indices, kYawSteps + 1, column, row);
}

// Mốc môi trường.

// Thuộc tính màu "r g b"; vắng thì giữ nguyên giá trị đang có.
void take_colour(Rgb& colour, const xml::Element& element, std::string_view name) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (!text) return;
    const scene::Vector3 parsed = scene::parse_vector3(*text);
    colour = Rgb{.red = parsed.x, .green = parsed.y, .blue = parsed.z};
}

void take_real(float& value, const xml::Element& element, std::string_view name) noexcept {
    const xml::OptionalText text = xml::attribute(element, name);
    if (text) value = scene::parse_real(*text);
}

// Bản gốc: màu của nhân vật ghi đúng "0 0 0" thì lấy màu tương ứng của cảnh.
void fall_back(Rgb& colour, const Rgb& scene_colour) noexcept {
    if (colour == Rgb{}) colour = scene_colour;
}

[[nodiscard]] DayKey day_key_of(const xml::Element& element) noexcept {
    DayKey key;
    take_real(key.time, element, "time");
    take_colour(key.ambient, element, "ambient");
    take_colour(key.fog, element, "fog");
    take_real(key.fog_near, element, "fog_near_distance");
    take_real(key.fog_far, element, "fog_far_distance");
    take_colour(key.sky_fog, element, "sky_fog");
    take_colour(key.light_one, element, "light_one");
    take_colour(key.light_one_specular, element, "light_one_specular");
    take_real(key.light_one_power, element, "light_one_intensity");
    take_colour(key.light_two, element, "light_two");
    take_colour(key.light_two_specular, element, "light_two_specular");
    take_real(key.light_two_power, element, "light_two_intensity");
    take_colour(key.actor_one, element, "actor_light_one");
    take_real(key.actor_one_power, element, "actor_light_one_intensity");
    take_colour(key.actor_two, element, "actor_light_two");
    take_real(key.actor_two_power, element, "actor_light_two_intensity");
    take_colour(key.actor_ambient, element, "actor_light_ambient");
    fall_back(key.actor_one, key.light_one);
    fall_back(key.actor_two, key.light_two);
    fall_back(key.actor_ambient, key.ambient);
    return key;
}

struct DayWalk {
    const xml::Document* document = nullptr;
    std::vector<std::uint32_t> pending;
    std::vector<DayKey>* days = nullptr;
};

void take_day(DayWalk& walk, std::uint32_t index) {
    const xml::Element& element = walk.document->elements[index];
    if (element.name == "EnvKey") walk.days->push_back(day_key_of(element));
    for (const std::uint32_t child : element.children)
        walk.pending.push_back(child);
}

[[nodiscard]] bool is_earlier(const DayKey& left, const DayKey& right) noexcept {
    return left.time < right.time;
}

// Mọi EnvKey nằm dưới phần tử Weather, xếp theo giờ (bản gốc giữ chúng trong std::map theo time).
void add_days(SkyDome& dome, const xml::Document& document, std::uint32_t weather) {
    DayWalk walk;
    walk.document = &document;
    walk.days = &dome.days;
    walk.pending.push_back(weather);
    while (!walk.pending.empty()) {
        const std::uint32_t index = walk.pending.back();
        walk.pending.pop_back();
        take_day(walk, index);
    }
    std::ranges::stable_sort(dome.days, is_earlier);
}

[[nodiscard]] float mix(float from, float toward, float share) noexcept {
    return from + ((toward - from) * share);
}

[[nodiscard]] Rgb mix(const Rgb& from, const Rgb& toward, float share) noexcept {
    return Rgb{.red = mix(from.red, toward.red, share),
        .green = mix(from.green, toward.green, share),
        .blue = mix(from.blue, toward.blue, share)};
}

// Hai mốc kẹp thời điểm đang hỏi, giờ của chúng đã trải ra ngoài 0..1 khi vòng qua nửa đêm.
struct Bracket {
    const DayKey* before = nullptr;
    const DayKey* after = nullptr;
    float before_time = 0.0F;
    float after_time = 0.0F;
};

// Đi tiếp một mốc: mốc đầu tiên có giờ lớn hơn time là mốc sau; các mốc trước nó đẩy mốc trước lên.
void step_bracket(Bracket& bracket, const DayKey& key, float time) noexcept {
    if (bracket.after != nullptr) return;
    const bool is_after = time >= bracket.before_time && key.time > time;
    if (is_after) {
        bracket.after = &key;
        bracket.after_time = key.time;
        return;
    }
    bracket.before = &key;
    bracket.before_time = key.time;
}

[[nodiscard]] Bracket bracket_of(std::span<const DayKey> days, float time) noexcept {
    Bracket bracket;
    bracket.before = &days.back();
    bracket.before_time = days.back().time - 1.0F;
    for (const DayKey& key : days)
        step_bracket(bracket, key, time);
    if (bracket.after != nullptr) return bracket;
    bracket.after = &days.front();
    bracket.after_time = days.front().time + 1.0F;
    return bracket;
}

} // namespace

SkyDome read_sky(std::string_view text) {
    SkyDome dome;
    const xml::ParseResult document = xml::parse(text);
    if (!document || document->elements.empty()) return dome;
    if (document->elements.front().name != "SkySphere") return dome;
    const WeatherHit weather = weather_of(*document);
    if (weather.element == nullptr) return dome;
    add_days(dome, *document, weather.index);
    const xml::Element* group = texture_group(*document, weather.index);
    if (group == nullptr) return dome;
    add_layers(dome, *document, *group);
    return dome;
}

DayKey day_at(std::span<const DayKey> days, float time) noexcept {
    core::check(!days.empty(), "day_at cần ít nhất một mốc");
    const Bracket bracket = bracket_of(days, time);
    const float span = bracket.after_time - bracket.before_time;
    const float share = span > 0.0F ? (time - bracket.before_time) / span : 0.0F;
    const DayKey& from = *bracket.before;
    const DayKey& toward = *bracket.after;
    DayKey day;
    day.time = time;
    day.ambient = mix(from.ambient, toward.ambient, share);
    day.fog = mix(from.fog, toward.fog, share);
    day.fog_near = mix(from.fog_near, toward.fog_near, share);
    day.fog_far = mix(from.fog_far, toward.fog_far, share);
    day.sky_fog = mix(from.sky_fog, toward.sky_fog, share);
    day.light_one = mix(from.light_one, toward.light_one, share);
    day.light_one_specular = mix(from.light_one_specular, toward.light_one_specular, share);
    day.light_two = mix(from.light_two, toward.light_two, share);
    day.light_two_specular = mix(from.light_two_specular, toward.light_two_specular, share);
    day.actor_one = mix(from.actor_one, toward.actor_one, share);
    day.actor_two = mix(from.actor_two, toward.actor_two, share);
    day.actor_ambient = mix(from.actor_ambient, toward.actor_ambient, share);
    day.light_one_power = mix(from.light_one_power, toward.light_one_power, share);
    day.light_two_power = mix(from.light_two_power, toward.light_two_power, share);
    day.actor_one_power = mix(from.actor_one_power, toward.actor_one_power, share);
    day.actor_two_power = mix(from.actor_two_power, toward.actor_two_power, share);
    return day;
}

SkyMesh sky_band(const SkyBand& band) {
    SkyMesh mesh;
    if (!(band.pitch_end > band.pitch_start)) return mesh;
    const int rows = kPitchSteps + 1;
    mesh.vertices.reserve(static_cast<std::size_t>(rows) * static_cast<std::size_t>(kYawSteps + 1));
    for (int row = 0; row < rows; ++row)
        push_row(mesh, band, row);
    for (int row = 0; row < kPitchSteps; ++row)
        push_cells(mesh, row);
    return mesh;
}

} // namespace game::client
