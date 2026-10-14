// Đọc khối hệ hạt và effect. Khoá lạ bị bỏ, như OGRE. Góc trong script là độ.
#include "fx/system.hpp"

#include <algorithm>
#include <cmath>
#include <optional>
#include <string_view>

namespace game::fx {
namespace {

using ogre::Vec3;

[[nodiscard]] float number_of(const ScriptProperty& property, float fallback, std::size_t index) {
    if (index >= property.args.size()) return fallback;
    const std::optional<float> value = parse_float(property.args[index]);
    return value ? *value : fallback;
}

[[nodiscard]] Vec3 vec3_of(const ScriptProperty& property) {
    Vec3 value;
    value.x = number_of(property, 0.0F, 0);
    value.y = number_of(property, 0.0F, 1);
    value.z = number_of(property, 0.0F, 2);
    return value;
}

[[nodiscard]] Colour colour_of(const ScriptProperty& property) {
    Colour colour{1.0F, 1.0F, 1.0F, 1.0F};
    colour[0] = number_of(property, 1.0F, 0);
    colour[1] = number_of(property, 1.0F, 1);
    colour[2] = number_of(property, 1.0F, 2);
    colour[3] = number_of(property, 1.0F, 3);
    return colour;
}

[[nodiscard]] std::optional<std::size_t> stage_index(std::string_view key, std::string_view stem) {
    if (!key.starts_with(stem) || key.size() != stem.size() + 1) return std::nullopt;
    const char digit = key.back();
    if (digit < '0' || digit > '5') return std::nullopt;
    return static_cast<std::size_t>(digit - '0');
}

[[nodiscard]] Vec3 perpendicular(Vec3 value) {
    const Vec3 by_x = ogre::cross_vec3(value, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F});
    if (ogre::dot_vec3(by_x, by_x) >= 1.0e-12F) return by_x;
    return ogre::cross_vec3(value, Vec3{.x = 0.0F, .y = 1.0F, .z = 0.0F});
}

void finish_emitter(EmitterDef& emitter) {
    emitter.direction = ogre::normalize_vec3(emitter.direction);
    emitter.up = ogre::normalize_vec3(perpendicular(emitter.direction));
    const Vec3 left = ogre::cross_vec3(emitter.up, emitter.direction);
    emitter.x_range = ogre::scale_vec3(left, emitter.size.x * 0.5F);
    emitter.y_range = ogre::scale_vec3(emitter.up, emitter.size.y * 0.5F);
    emitter.z_range = ogre::scale_vec3(emitter.direction, emitter.size.z * 0.5F);
}

[[nodiscard]] std::optional<EmitterKind> emitter_kind(std::string_view name) {
    if (name == "Point") return EmitterKind::kPoint;
    if (name == "Box") return EmitterKind::kBox;
    if (name == "Ring") return EmitterKind::kRing;
    if (name == "Ellipsoid") return EmitterKind::kEllipsoid;
    if (name == "HollowEllipsoid") return EmitterKind::kHollowEllipsoid;
    if (name == "Cylinder") return EmitterKind::kCylinder;
    if (name == "PolarEmitter") return EmitterKind::kPolar;
    return std::nullopt;
}

void set_emitter(EmitterDef& emitter, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "angle") emitter.angle = number_of(property, 0.0F, 0) * kDegree;
    if (key == "colour_range_start") emitter.colour_start = colour_of(property);
    if (key == "colour_range_end") emitter.colour_end = colour_of(property);
    if (key == "direction") emitter.direction = vec3_of(property);
    if (key == "emission_rate") emitter.emission_rate = number_of(property, emitter.emission_rate, 0);
    if (key == "position") emitter.position = vec3_of(property);
    if (key == "velocity") emitter.velocity_min = emitter.velocity_max = number_of(property, 0.0F, 0);
    if (key == "velocity_min") emitter.velocity_min = number_of(property, 0.0F, 0);
    if (key == "velocity_max") emitter.velocity_max = number_of(property, 0.0F, 0);
    if (key == "time_to_live") emitter.ttl_min = emitter.ttl_max = number_of(property, 1.0F, 0);
    if (key == "time_to_live_min") emitter.ttl_min = number_of(property, 1.0F, 0);
    if (key == "time_to_live_max") emitter.ttl_max = number_of(property, 1.0F, 0);
    if (key == "duration_min") emitter.duration_min = number_of(property, 0.0F, 0);
    if (key == "duration_max") emitter.duration_max = number_of(property, 0.0F, 0);
    if (key == "width") emitter.size.x = number_of(property, emitter.size.x, 0);
    if (key == "height") emitter.size.y = number_of(property, emitter.size.y, 0);
    if (key == "depth") emitter.size.z = number_of(property, emitter.size.z, 0);
    if (key == "inner_width") emitter.inner.x = number_of(property, emitter.inner.x, 0);
    if (key == "inner_height") emitter.inner.y = number_of(property, emitter.inner.y, 0);
    if (key == "inner_depth") emitter.inner.z = number_of(property, emitter.inner.z, 0);
    if (key == "radius_start") emitter.radius_start = number_of(property, 0.0F, 0);
    if (key == "radius_step") emitter.radius_step = number_of(property, 0.0F, 0);
    if (key == "radius_end") emitter.radius_end = number_of(property, 0.0F, 0);
    if (key == "theta_start") emitter.theta_start = number_of(property, 0.0F, 0);
    if (key == "theta_step") emitter.theta_step = number_of(property, 0.0F, 0);
    if (key == "theta_end") emitter.theta_end = number_of(property, 0.0F, 0);
    if (key == "phi_start") emitter.phi_start = number_of(property, 0.0F, 0);
    if (key == "phi_step") emitter.phi_step = number_of(property, 0.0F, 0);
    if (key == "phi_end") emitter.phi_end = number_of(property, 0.0F, 0);
    if (key == "use_polar_step") emitter.polar_step = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "flip_yz_axis") emitter.flip_yz = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "reset_radius") emitter.reset_radius = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "reset_radius_count") emitter.reset_count = static_cast<int>(number_of(property, 0.0F, 0));
}

[[nodiscard]] EmitterDef read_emitter(const ScriptBlock& block) {
    const std::optional<EmitterKind> kind = emitter_kind(block.word(1));
    EmitterDef emitter;
    if (kind) emitter.kind = *kind;
    for (const ScriptProperty& property : block.properties)
        set_emitter(emitter, property);
    finish_emitter(emitter);
    return emitter;
}

void set_colour(ColourFading& fading, const ScriptProperty& property) {
    const std::optional<std::size_t> colour = stage_index(property.key, "colour");
    const std::optional<std::size_t> time = stage_index(property.key, "time");
    const std::optional<std::size_t> opacity = stage_index(property.key, "opacity");
    if (colour) fading.colour[*colour] = colour_of(property);
    if (time) fading.time[*time] = number_of(property, 0.0F, 0);
    if (opacity) fading.opacity[*opacity] = number_of(property, 1.0F, 0);
    if (property.key == "opacity") fading.opacity_all = number_of(property, 1.0F, 0);
    if (property.key == "repeat_times") fading.repeat_times = number_of(property, 1.0F, 0);
    if (property.key == "fade_in_time") fading.fade_in = number_of(property, 0.0F, 0);
    if (property.key == "fade_out_time") fading.fade_out = number_of(property, 1.0F, 0);
}

void set_scale(ScaleInterpolator& scale, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "width_range_start") scale.width_start = number_of(property, scale.width_start, 0);
    if (key == "width_range_end") scale.width_end = number_of(property, scale.width_end, 0);
    if (key == "height_range_start") scale.height_start = number_of(property, scale.height_start, 0);
    if (key == "height_range_end") scale.height_end = number_of(property, scale.height_end, 0);
    if (key == "uniform_size") scale.uniform = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "use_interpolated_scale")
        scale.use_interpolated = parse_bool(property.args.empty() ? "" : property.args.front());
    const std::optional<std::size_t> slot = stage_index(key, "scale");
    const std::optional<std::size_t> time = stage_index(key, "time");
    if (slot) scale.scale[*slot] = vec3_of(property);
    if (time) scale.time[*time] = number_of(property, 0.0F, 0);
    if (key == "repeat_times") scale.repeat_times = number_of(property, 1.0F, 0);
    if (key == "use_constant_scale")
        scale.use_constant = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "constant_scale") scale.constant = vec3_of(property);
    if (key == "use_interpolated_increment")
        scale.use_increment = parse_bool(property.args.empty() ? "" : property.args.front());
    const std::optional<std::size_t> grown = stage_index(key, "increment_value");
    const std::optional<std::size_t> grown_time = stage_index(key, "increment_time");
    if (grown) scale.increment[*grown] = vec3_of(property);
    if (grown_time) scale.increment_time[*grown_time] = number_of(property, 1.0F, 0);
    if (key == "increment_repeat_times") scale.increment_repeat = number_of(property, 1.0F, 0);
}

void set_movement(Movement& movement, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "use_start_velocity")
        movement.use_start = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "start_velocity_min") movement.start_min = vec3_of(property);
    if (key == "start_velocity_max") movement.start_max = vec3_of(property);
    if (key == "acceleration") movement.acceleration = vec3_of(property);
    if (key == "randomness_min") movement.random_min = vec3_of(property);
    if (key == "randomness_max") movement.random_max = vec3_of(property);
}

void set_revolution(Revolution& spin, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "rotation_speed") spin.speed = number_of(property, 0.0F, 0) * kDegree;
    if (key == "rotation_axis") spin.axis = vec3_of(property);
    if (key == "radius_increment") spin.radius_increment = number_of(property, 0.0F, 0);
    if (key == "center_offset_min") spin.center_min = vec3_of(property);
    if (key == "center_offset_max") spin.center_max = vec3_of(property);
    if (key == "use_radius_increment_scale")
        spin.use_scale = parse_bool(property.args.empty() ? "" : property.args.front());
    const std::optional<std::size_t> grown = stage_index(key, "radius_increment_scale");
    const std::optional<std::size_t> time = stage_index(key, "time");
    if (grown) spin.scale[*grown] = number_of(property, 0.0F, 0);
    if (time) spin.time[*time] = number_of(property, 1.0F, 0);
    if (key == "repeat_times") spin.repeat_times = number_of(property, 1.0F, 0);
    if (key == "move_velocity") spin.move_velocity = vec3_of(property);
    if (key == "move_usevariablevelocity")
        spin.variable_velocity = parse_bool(property.args.empty() ? "" : property.args.front());
    const std::optional<std::size_t> point = stage_index(key, "move_velocity_point");
    const std::optional<std::size_t> move_time = stage_index(key, "move_time");
    if (point) spin.move_points[*point] = vec3_of(property);
    if (move_time) spin.move_time[*move_time] = number_of(property, 1.0F, 0);
    if (key == "move_repeattimes") spin.move_repeat = number_of(property, 1.0F, 0);
}

void set_rotator(Rotator& rotator, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "rotation_speed_range_start") rotator.speed_start = number_of(property, 0.0F, 0) * kDegree;
    if (key == "rotation_speed_range_end") rotator.speed_end = number_of(property, 0.0F, 0) * kDegree;
    if (key == "rotation_range_start") rotator.angle_start = number_of(property, 0.0F, 0) * kDegree;
    if (key == "rotation_range_end") rotator.angle_end = number_of(property, 0.0F, 0) * kDegree;
}

// Render.dll MeshRotator::_initParticle RVA 0x1475c0 và _affectParticles RVA 0x1474d0.
// doSet gọi Ogre::StringConverter::parseAngle: số trần là độ.
[[nodiscard]] RendererKind renderer_kind(std::string_view name) {
    if (name == "texcoord_billboard") return RendererKind::kTexcoord;
    if (name == "mesh") return RendererKind::kMesh;
    if (name == "ribbon") return RendererKind::kRibbon;
    return RendererKind::kBillboard;
}

void set_mesh_axis(ogre::Vec3& target, std::string_view axis, float value) {
    if (axis == "yaw") target.x = value;
    if (axis == "pitch") target.y = value;
    if (axis == "roll") target.z = value;
}

void set_mesh(MeshRotator& spin, const ScriptProperty& property) {
    const std::string_view key = property.key;
    const std::size_t cut = key.find('_');
    if (cut == std::string_view::npos) return;
    const std::string_view axis = key.substr(0, cut);
    const std::string_view rest = key.substr(cut + 1);
    const float value = number_of(property, 0.0F, 0) * kDegree;
    if (rest == "rotation_speed_range_start") set_mesh_axis(spin.speed_start, axis, value);
    if (rest == "rotation_speed_range_end") set_mesh_axis(spin.speed_end, axis, value);
    if (rest == "rotation_range_start") set_mesh_axis(spin.angle_start, axis, value);
    if (rest == "rotation_range_end") set_mesh_axis(spin.angle_end, axis, value);
}

// Loại không có trong Plugin_ParticleFX2.dll thì bỏ, không biến thành ScaleInterpolator.
[[nodiscard]] std::optional<Affector> affector_of(const ScriptBlock& block, const SystemDef& system) {
    const std::string_view kind = block.word(1);
    if (kind == "LinearForce") {
        LinearForce force;
        for (const ScriptProperty& property : block.properties) {
            if (property.key == "force_vector") force.force = vec3_of(property);
        }
        return force;
    }
    if (kind == "Scaler") {
        Scaler scaler;
        for (const ScriptProperty& property : block.properties) {
            if (property.key == "rate") scaler.rate = number_of(property, 0.0F, 0);
        }
        return scaler;
    }
    if (kind == "Rotator") {
        Rotator rotator;
        for (const ScriptProperty& property : block.properties)
            set_rotator(rotator, property);
        return rotator;
    }
    if (kind == "ColourFading") {
        ColourFading fading;
        for (const ScriptProperty& property : block.properties)
            set_colour(fading, property);
        return fading;
    }
    if (kind == "Movement") {
        Movement movement;
        for (const ScriptProperty& property : block.properties)
            set_movement(movement, property);
        return movement;
    }
    if (kind == "Revolution" || kind == "RevoluMove") {
        Revolution spin;
        spin.move = kind == "RevoluMove";
        for (const ScriptProperty& property : block.properties)
            set_revolution(spin, property);
        return spin;
    }
    if (kind == "MeshRotator") {
        MeshRotator spin;
        for (const ScriptProperty& property : block.properties)
            set_mesh(spin, property);
        return spin;
    }
    if (kind == "MeshAnimationAffector") {
        MeshAnimation clip;
        for (const ScriptProperty& property : block.properties) {
            if (property.key == "animation_name" && !property.args.empty()) clip.name = property.args.front();
            if (property.key == "animation_loop")
                clip.loop = parse_bool(property.args.empty() ? "" : property.args.front());
            if (property.key == "animation_speed") clip.speed = number_of(property, 1.0F, 0);
        }
        return clip;
    }
    if (kind == "SequenceFrame") {
        SequenceFrame frames;
        for (const ScriptProperty& property : block.properties) {
            if (property.key == "stacks") frames.stacks = std::max(1, static_cast<int>(number_of(property, 1.0F, 0)));
            if (property.key == "slices") frames.slices = std::max(1, static_cast<int>(number_of(property, 1.0F, 0)));
            if (property.key == "repeat_times") frames.repeat_times = number_of(property, 1.0F, 0);
            if (property.key == "loop") frames.loop = parse_bool(property.args.empty() ? "" : property.args.front());
            if (property.key == "pingpang")
                frames.pingpang = parse_bool(property.args.empty() ? "" : property.args.front());
            if (property.key == "start_range") {
                frames.start_min = number_of(property, 0.0F, 0);
                frames.start_max = number_of(property, 0.0F, 1);
            }
        }
        return frames;
    }
    if (kind == "DirectionRandomiser") {
        DirectionRandomiser jitter;
        for (const ScriptProperty& property : block.properties) {
            if (property.key == "randomness") jitter.randomness = number_of(property, 1.0F, 0);
            if (property.key == "scope") jitter.scope = number_of(property, 100.0F, 0);
            if (property.key == "keep_velocity")
                jitter.keep_velocity = parse_bool(property.args.empty() ? "" : property.args.front());
        }
        return jitter;
    }
    if (kind != "ScaleInterpolator") return std::nullopt;
    ScaleInterpolator scale;
    scale.width_start = system.width;
    scale.width_end = system.width;
    scale.height_start = system.height;
    scale.height_end = system.height;
    for (const ScriptProperty& property : block.properties)
        set_scale(scale, property);
    return scale;
}

[[nodiscard]] BillboardKind billboard_of(std::string_view name) {
    if (name == "oriented_common") return BillboardKind::kOrientedCommon;
    if (name == "oriented_self") return BillboardKind::kOrientedSelf;
    if (name == "perpendicular_common") return BillboardKind::kPerpendicularCommon;
    if (name == "perpendicular_self") return BillboardKind::kPerpendicularSelf;
    return BillboardKind::kPoint;
}

void set_system(SystemDef& system, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "quota") system.quota = static_cast<std::size_t>(std::max(0.0F, number_of(property, 10.0F, 0)));
    if (key == "material" && !property.args.empty()) system.material = property.args.front();
    if (key == "particle_width") system.width = number_of(property, system.width, 0);
    if (key == "particle_height") system.height = number_of(property, system.height, 0);
    if (key == "particle_depth") system.depth = number_of(property, system.depth, 0);
    if (key == "renderer" && !property.args.empty()) system.renderer = renderer_kind(property.args.front());
    if (key == "mesh_name" && !property.args.empty()) system.mesh_name = property.args.front();
    if (key == "orientation_type" && !property.args.empty())
        system.face_direction = property.args.front() == "oriented_self";
    if (key == "stacks") system.stacks = std::max(1, static_cast<int>(number_of(property, 1.0F, 0)));
    if (key == "slices") system.slices = std::max(1, static_cast<int>(number_of(property, 1.0F, 0)));
    if (key == "repeat_times") system.repeat_times = number_of(property, system.repeat_times, 0);
    if (key == "head_alpha") system.head_alpha = number_of(property, 1.0F, 0);
    if (key == "tail_alpha") system.tail_alpha = number_of(property, 1.0F, 0);
    if (key == "head_width_scale") system.head_width = number_of(property, 1.0F, 0);
    if (key == "tail_width_scale") system.tail_width = number_of(property, 1.0F, 0);
    if (key == "element_count") system.element_count = std::max(2, static_cast<int>(number_of(property, 15.0F, 0)));
    if (key == "local_space") system.local_space = parse_bool(property.args.empty() ? "true" : property.args.front());
    if (key == "sorted") system.sorted = parse_bool(property.args.empty() ? "" : property.args.front());
    if (key == "billboard_type" && !property.args.empty()) system.billboard = billboard_of(property.args.front());
    if (key == "billboard_rotation_type")
        system.rotate_texcoord = !property.args.empty() && property.args.front() == "texcoord";
    if (key == "common_direction") system.common_direction = vec3_of(property);
    if (key == "common_up_vector") system.common_up = vec3_of(property);
    if (key == "speed_relatived_size_factor") system.speed_factor = number_of(property, system.speed_factor, 0);
}

[[nodiscard]] ogre::Quat quat_of(const ScriptProperty& property) {
    ogre::Quat turn;
    turn.w = number_of(property, 1.0F, 0);
    turn.x = number_of(property, 0.0F, 1);
    turn.y = number_of(property, 0.0F, 2);
    turn.z = number_of(property, 0.0F, 3);
    return turn;
}

[[nodiscard]] std::optional<std::size_t> fade_slot(std::string_view key, std::string_view prefix) {
    if (!key.starts_with(prefix) || key.size() != prefix.size() + 1) return std::nullopt;
    const char digit = key.back();
    if (digit < '0' || digit > '4') return std::nullopt;
    return static_cast<std::size_t>(digit - '0');
}

[[nodiscard]] bool flag_of(const ScriptProperty& property, bool fallback) {
    if (property.args.empty()) return fallback;
    return parse_bool(property.args.front());
}

void set_wave(ElementDef& element, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "IsSinPlay") element.sin_play = flag_of(property, element.sin_play);
    if (key == "WaveExtent-y") element.extent_y = number_of(property, element.extent_y, 0);
    if (key == "WaveExtent-z") element.extent_z = number_of(property, element.extent_z, 0);
    if (key == "WaveFrequency") element.wave_frequency = number_of(property, element.wave_frequency, 0);
    if (key == "WaveVelocity") element.wave_velocity = number_of(property, element.wave_velocity, 0);
    if (key == "WaveShade-y") element.shade_y = number_of(property, element.shade_y, 0);
    if (key == "WaveShade-z") element.shade_z = number_of(property, element.shade_z, 0);
    if (key == "TexRepeat") element.tex_repeat = static_cast<int>(number_of(property, 1.0F, 0));
    if (key == "IsVisable" || key == "IsVisible") element.visible = flag_of(property, element.visible);
    if (key == "CurveType") element.curve = static_cast<int>(number_of(property, 0.0F, 0));
}

void set_noise(ElementDef& element, std::string_view key, float value) {
    if (key == "NoiseXMin") element.noise_min.x = value;
    if (key == "NoiseXMax") element.noise_max.x = value;
    if (key == "NoiseYMin") element.noise_min.y = value;
    if (key == "NoiseYMax") element.noise_max.y = value;
    if (key == "NoiseZMin") element.noise_min.z = value;
    if (key == "NoiseZMax") element.noise_max.z = value;
}

void set_element(ElementDef& element, const ScriptProperty& property) {
    const std::string_view key = property.key;
    if (key == "StartTime") element.start_time = number_of(property, 0.0F, 0);
    if (key == "LifeTime") element.lifetime = number_of(property, 0.0F, 0);
    if (key == "Position") element.position = vec3_of(property);
    if (key == "Orientation") element.orientation = quat_of(property);
    if (key == "ParticleSystem" && !property.args.empty()) element.system = property.args.front();
    if (key == "Material" && !property.args.empty()) element.material = property.args.front();
    if (key == "NumElements") element.links = std::max(2, static_cast<int>(number_of(property, 10.0F, 0)));
    if (key == "Width") element.width = number_of(property, element.width, 0);
    if (key == "Frequency") element.frequency = number_of(property, element.frequency, 0);
    if (key == "Colour") element.colour_a = element.colour_b = colour_of(property);
    if (key == "ColourRangeStart") element.colour_a = colour_of(property);
    if (key == "ColourRangeEnd") element.colour_b = colour_of(property);
    set_noise(element, key, number_of(property, 0.0F, 0));
    set_wave(element, property);
    if (key == "TrailLength") element.trail_length = number_of(property, element.trail_length, 0);
    if (key == "MaxChainElements") element.chain_count = std::max(2, static_cast<int>(number_of(property, 80.0F, 0)));
    if (key == "InitialWidth") element.head_width = number_of(property, element.head_width, 0);
    if (key == "TailWidth") element.tail_width = number_of(property, element.tail_width, 0);
    if (key == "WidthChange") element.width_change = number_of(property, 0.0F, 0);
    if (key == "LowWidthCut") element.low_cut = number_of(property, 0.0F, 0);
    if (key == "HighWidthCut") element.high_cut = number_of(property, 0.0F, 0);
    if (key == "AlphaColourCut") element.alpha_cut = number_of(property, 0.0F, 0);
    if (key == "LiftTime") element.lift_time = number_of(property, 0.0F, 0);
    if (key == "ProjectionSize") element.projection = number_of(property, element.projection, 0);
    const std::optional<std::size_t> time_slot = fade_slot(key, "ColourFadingTime");
    const std::optional<std::size_t> colour_slot = fade_slot(key, "ColourFadingColour");
    if (time_slot) element.fade_time[*time_slot] = number_of(property, 0.0F, 0);
    if (colour_slot) element.fade_colour[*colour_slot] = colour_of(property);
}

[[nodiscard]] std::optional<ElementKind> element_kind(std::string_view name) {
    if (name == "Particle") return ElementKind::kParticle;
    if (name == "Beam") return ElementKind::kBeam;
    if (name == "NewRibbonTrail") return ElementKind::kTrail;
    if (name == "Projector") return ElementKind::kProjector;
    return std::nullopt;
}

void take_child(SystemDef& system, const ScriptBlock& child) {
    if (child.word(0) == "emitter") {
        system.emitters.push_back(read_emitter(child));
        return;
    }
    if (child.word(0) != "affector") return;
    const std::optional<Affector> affector = affector_of(child, system);
    if (affector) system.affectors.push_back(*affector);
}

} // namespace

SystemDef read_system(const ScriptBlock& block) {
    SystemDef system;
    system.name = std::string(block.word(0));
    for (const ScriptProperty& property : block.properties)
        set_system(system, property);
    for (const ScriptBlock& child : block.children)
        take_child(system, child);
    return system;
}

EffectDef read_effect(const ScriptBlock& block) {
    EffectDef effect;
    effect.name = std::string(block.word(1));
    effect.lifetime = block.number("LifeTime", 0.0F);
    for (const ScriptBlock& child : block.children) {
        if (child.word(0) != "element") continue;
        const std::optional<ElementKind> kind = element_kind(child.word(1));
        if (!kind) continue;
        ElementDef element;
        element.kind = *kind;
        for (const ScriptProperty& property : child.properties)
            set_element(element, property);
        effect.elements.push_back(std::move(element));
    }
    return effect;
}

} // namespace game::fx
