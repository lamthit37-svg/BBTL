#include "fx/field.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>

namespace game::fx {
namespace {

constexpr float kStep = 0.033F;
constexpr int kMaxSteps = 30;

using ogre::Vec3;

[[nodiscard]] Vec3 add(Vec3 left, Vec3 right) {
    return ogre::add_vec3(left, right);
}

[[nodiscard]] Vec3 scaled(Vec3 value, float factor) {
    return ogre::scale_vec3(value, factor);
}

[[nodiscard]] float mix_channel(float from, float to, float amount) {
    return (to * amount) + (from * (1.0F - amount));
}

[[nodiscard]] float repeated(float life, float repeat) {
    if (repeat == 1.0F) return life;
    return static_cast<float>(std::fmod(static_cast<double>(repeat) * static_cast<double>(life), 1.0));
}

[[nodiscard]] Colour mix_colour(Colour from, Colour to, float amount) {
    Colour mixed;
    mixed[0] = mix_channel(from[0], to[0], amount);
    mixed[1] = mix_channel(from[1], to[1], amount);
    mixed[2] = mix_channel(from[2], to[2], amount);
    mixed[3] = mix_channel(from[3], to[3], amount);
    return mixed;
}

[[nodiscard]] Vec3 mix_vec(Vec3 from, Vec3 to, float amount) {
    return add(scaled(to, amount), scaled(from, 1.0F - amount));
}

[[nodiscard]] std::optional<Colour> stage_colour(float time, const std::array<float, kStages>& times,
    const std::array<Colour, kStages>& values) {
    if (time <= times[0]) return values[0];
    if (time >= times[kStages - 1]) return values[kStages - 1];
    for (std::size_t index = 0; index + 1 < kStages; ++index) {
        const bool inside = time >= times[index] && time < times[index + 1];
        if (!inside) continue;
        const float amount = (time - times[index]) / (times[index + 1] - times[index]);
        return mix_colour(values[index], values[index + 1], amount);
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<Vec3> stage_vec(float time, const std::array<float, kStages>& times,
    const std::array<Vec3, kStages>& values) {
    if (time <= times[0]) return values[0];
    if (time >= times[kStages - 1]) return values[kStages - 1];
    for (std::size_t index = 0; index + 1 < kStages; ++index) {
        const bool inside = time >= times[index] && time < times[index + 1];
        if (!inside) continue;
        const float amount = (time - times[index]) / (times[index + 1] - times[index]);
        return mix_vec(values[index], values[index + 1], amount);
    }
    return std::nullopt;
}

void set_size(Grain& grain, float width, float height, float depth) {
    grain.own = true;
    grain.width = width;
    grain.height = height;
    grain.depth = depth;
}

[[nodiscard]] float clamp_size(float value) {
    return value < 0.0F ? 0.0F : value;
}

void grow(Grain& grain, float width_step, float height_step, float depth_step) {
    const float width = clamp_size(grain.width + width_step);
    const float height = clamp_size(grain.height + height_step);
    const float depth = clamp_size(grain.depth + depth_step);
    set_size(grain, width, height, depth);
}

} // namespace

Field::Field(const SystemDef& definition, std::uint32_t seed) : definition_(&definition), random_(seed) {
    pool_.resize(definition.quota);
    chains_.resize(definition.quota);
    const std::size_t links = static_cast<std::size_t>(std::max(2, definition.element_count));
    for (RibbonChain& chain : chains_)
        chain.slots.resize(links);
    free_.reserve(definition.quota);
    for (std::size_t index = definition.quota; index > 0; --index)
        free_.push_back(static_cast<std::uint32_t>(index - 1));
    emitters_.resize(definition.emitters.size());
    for (std::size_t index = 0; index < emitters_.size(); ++index) {
        emitters_[index].radius = definition.emitters[index].radius_start;
        emitters_[index].theta = definition.emitters[index].theta_start;
        emitters_[index].phi = definition.emitters[index].phi_start;
    }
}

float Field::unit() {
    return static_cast<float>(random_()) / static_cast<float>(std::mt19937::max());
}

float Field::range(float low, float high) {
    return low + (unit() * (high - low));
}

void Field::update(float seconds, const Node& node) {
    node_ = node;
    remain_ += seconds;
    int steps = 0;
    while (remain_ >= kStep && steps < kMaxSteps) {
        step(kStep);
        remain_ -= kStep;
        ++steps;
    }
    if (steps == kMaxSteps) remain_ = 0.0F;
}

void Field::step(float dt) {
    expire(dt);
    affect(dt);
    move(dt);
    emit(dt);
}

void Field::expire(float dt) {
    std::vector<std::uint32_t> kept;
    kept.reserve(active_.size());
    for (const std::uint32_t index : active_) {
        Grain& grain = pool_[index];
        if (grain.ttl < dt) {
            free_.push_back(index);
            continue;
        }
        grain.ttl -= dt;
        kept.push_back(index);
    }
    active_ = std::move(kept);
}

// BillboardChain::addChainElement: head lùi, đầy thì tail lùi theo.
void Field::add_link(RibbonChain& chain, const ChainPoint& fresh) {
    const std::uint32_t limit = static_cast<std::uint32_t>(chain.slots.size());
    const bool empty = chain.head == kEmptyLink;
    const std::uint32_t retreated = chain.head == 0 ? limit - 1 : chain.head - 1;
    const std::uint32_t head = empty ? limit - 1 : retreated;
    const bool full = !empty && head == chain.tail;
    const bool wrapped = full && chain.tail == 0;
    std::uint32_t tail = empty ? limit - 1 : chain.tail;
    if (wrapped) tail = limit - 1;
    if (full && !wrapped) tail = chain.tail - 1;
    chain.slots[head] = fresh;
    chain.head = head;
    chain.tail = tail;
}

// updateRibbon: vượt chiều dài phần tử thì chốt đầu cũ rồi thêm đầu mới.
// Khác gốc: khoảng cách 0 thì không chia; file gốc chia sqrt(0) khi chiều dài phần tử cũng là 0.
// Sau addChainElement, diff = newPos - newElem.position của bản sao cục bộ, nên bằng 0.
float Field::extend_link(RibbonChain& chain, const ChainPoint& fresh, float segment) {
    ChainPoint& head = chain.slots[chain.head];
    const std::uint32_t limit = static_cast<std::uint32_t>(chain.slots.size());
    const std::uint32_t next = chain.head + 1 == limit ? 0 : chain.head + 1;
    const Vec3 diff = ogre::sub_vec3(fresh.position, chain.slots[next].position);
    const float squared = ogre::dot_vec3(diff, diff);
    const bool grows = squared >= segment * segment && squared > 0.0F;
    if (!grows) head.position = fresh.position;
    if (!grows) return std::sqrt(squared);
    const float distance = std::sqrt(squared);
    head.position = add(chain.slots[next].position, scaled(diff, segment / distance));
    add_link(chain, fresh);
    return 0.0F;
}

void Field::shrink_link(RibbonChain& chain, float leftover) {
    const std::uint32_t limit = static_cast<std::uint32_t>(chain.slots.size());
    const std::uint32_t ahead = chain.tail + 1 == limit ? 0 : chain.tail + 1;
    if (ahead != chain.head) return;
    const std::uint32_t before = chain.tail == 0 ? limit - 1 : chain.tail - 1;
    ChainPoint& tail = chain.slots[chain.tail];
    const Vec3 span = ogre::sub_vec3(tail.position, chain.slots[before].position);
    const float length = ogre::length_vec3(span);
    if (!(length > 1.0e-6F)) return;
    tail.position = add(chain.slots[before].position, scaled(span, leftover / length));
}

[[nodiscard]] std::uint32_t Field::link_count(const RibbonChain& chain) {
    if (chain.head == kEmptyLink) return 0;
    if (chain.head > chain.tail) return static_cast<std::uint32_t>(chain.slots.size());
    if (chain.head < chain.tail) return chain.tail - chain.head + 1;
    return 0;
}

namespace {

[[nodiscard]] bool near_one(float value) {
    return std::fabs(value - 1.0F) <= std::numeric_limits<float>::epsilon();
}

void paint_one_link(Field::ChainPoint& point, ogre::Vec3 tail, float total, const SystemDef& definition,
    const Grain& grain, float width) {
    const ogre::Vec3 toward = ogre::sub_vec3(point.position, tail);
    const float ratio = 1.0F - std::sqrt(ogre::dot_vec3(toward, toward) / total);
    point.texcoord = ratio;
    const float alpha = definition.head_alpha + ((definition.tail_alpha - definition.head_alpha) * ratio);
    const bool tint = !near_one(definition.head_alpha) || !near_one(definition.tail_alpha);
    if (tint) {
        point.colour =
            Colour{grain.colour[0] * alpha, grain.colour[1] * alpha, grain.colour[2] * alpha, grain.colour[3] * alpha};
    }
    const float scale = definition.head_width + ((definition.tail_width - definition.head_width) * ratio);
    const bool reshape = !near_one(definition.head_width) || !near_one(definition.tail_width);
    if (reshape) point.width = width * scale;
}

} // namespace

void Field::paint_link(RibbonChain& chain, const Grain& grain, float width) {
    const ogre::Vec3 span = ogre::sub_vec3(chain.slots[chain.head].position, chain.slots[chain.tail].position);
    const float total = ogre::dot_vec3(span, span);
    if (std::fabs(total) <= kRealEpsilon) return;
    const std::uint32_t count = link_count(chain);
    const std::uint32_t limit = static_cast<std::uint32_t>(chain.slots.size());
    const ogre::Vec3 tail = chain.slots[chain.tail].position;
    for (std::uint32_t step = 0; step < count; ++step) {
        const std::uint32_t slot = (chain.head + step) % limit;
        paint_one_link(chain.slots[slot], tail, total, *definition_, grain, width);
    }
}

void Field::publish_link(RibbonChain& chain) {
    chain.ordered.clear();
    const std::uint32_t count = link_count(chain);
    const std::uint32_t limit = static_cast<std::uint32_t>(chain.slots.size());
    for (std::uint32_t step = 0; step < count; ++step) {
        const std::uint32_t slot = (chain.head + step) % limit;
        chain.ordered.push_back(chain.slots[slot]);
    }
}

ogre::Vec3 Field::ribbon_local(ogre::Vec3 position) const {
    if (definition_->local_space) return position;
    const ogre::Vec3 shifted = ogre::sub_vec3(position, node_.position);
    const ogre::Vec3 turned = ogre::quat_rotate(ogre::quat_inverse(node_.orientation), shifted);
    return ogre::div_vec3(turned, node_.scale);
}

void Field::update_ribbon(std::uint32_t index) {
    const Grain& grain = pool_[index];
    RibbonChain& chain = chains_[index];
    const float width = grain.own ? grain.width : definition_->width;
    const ChainPoint fresh{ribbon_local(grain.position), width, 0.0F, grain.colour};
    if (chain.head == kEmptyLink) {
        add_link(chain, fresh);
        add_link(chain, fresh);
    }
    const float moved = extend_link(chain, fresh, definition_->height);
    shrink_link(chain, definition_->height - moved);
    paint_link(chain, grain, width);
    publish_link(chain);
}

void Field::move(float dt) {
    for (const std::uint32_t index : active_) {
        Grain& grain = pool_[index];
        grain.position = add(grain.position, scaled(grain.direction, dt));
    }
    if (definition_->renderer != RendererKind::kRibbon) return;
    for (const std::uint32_t index : active_)
        update_ribbon(index);
}

std::span<const Field::ChainPoint> Field::chain(std::uint32_t index) const {
    return chains_.at(index).ordered;
}

namespace {

// Plugin_ParticleFX2.dll bản 2026, ColourFadingAffector::_affectParticles (RVA 0x2670):
// rgb lấy từ colour, alpha lấy từ opacity cùng mốc; quá mốc cuối thì mốc đầu có time >= 1.
// fade_in bằng 0 và fade_out bằng 1 thì bỏ nhánh đó. Rồi nhân cả bốn kênh với độ mờ.
[[nodiscard]] std::size_t full_stage(const std::array<float, kStages>& times) {
    std::size_t found = kStages;
    for (std::size_t index = 0; index < kStages; ++index)
        found = times[index] >= 1.0F && found == kStages ? index : found;
    return found;
}

void paint_late(Grain& grain, const ColourFading& fading, const std::array<Colour, kStages>& stages) {
    const std::size_t slot = full_stage(fading.time);
    if (slot < kStages) grain.colour = stages[slot];
}

void paint_stage(Grain& grain, const ColourFading& fading, const std::array<Colour, kStages>& stages, float time) {
    if (time <= fading.time[0]) {
        grain.colour = stages[0];
        return;
    }
    if (time >= fading.time[kStages - 1]) {
        paint_late(grain, fading, stages);
        return;
    }
    const std::optional<Colour> colour = stage_colour(time, fading.time, stages);
    if (colour) grain.colour = *colour;
}

[[nodiscard]] float faded_opacity(float life, const ColourFading& fading) {
    const bool fading_in = life <= fading.fade_in && fading.fade_in != 0.0F;
    if (fading_in) return (life / fading.fade_in) * fading.opacity_all;
    const bool fading_out = life >= fading.fade_out && fading.fade_out != 1.0F;
    if (!fading_out) return fading.opacity_all;
    const float span = 1.0F - fading.fade_out;
    return (1.0F - ((life - fading.fade_out) / span)) * fading.opacity_all;
}

void fade_colour(Grain& grain, const ColourFading& fading) {
    const float life = grain.life();
    const float time = repeated(life, fading.repeat_times);
    std::array<Colour, kStages> stages{};
    for (std::size_t index = 0; index < kStages; ++index) {
        stages[index] =
            Colour{fading.colour[index][0], fading.colour[index][1], fading.colour[index][2], fading.opacity[index]};
    }
    paint_stage(grain, fading, stages, time);
    const float opacity = faded_opacity(life, fading);
    grain.colour[0] *= opacity;
    grain.colour[1] *= opacity;
    grain.colour[2] *= opacity;
    grain.colour[3] *= opacity;
}

void scale_constant(Grain& grain, const ScaleInterpolator& scale, float dt) {
    grow(grain, scale.constant.x * dt, scale.constant.y * dt, scale.constant.z * dt);
}

void scale_lerp(const SystemDef& definition, Grain& grain, const ScaleInterpolator& scale) {
    const std::optional<Vec3> factor = stage_vec(repeated(grain.life(), scale.repeat_times), scale.time, scale.scale);
    if (!factor) return;
    set_size(grain, definition.width * factor->x, definition.height * factor->y, definition.depth * factor->z);
}

void scale_increment(Grain& grain, const ScaleInterpolator& scale, float dt) {
    const float time = repeated(grain.life(), scale.increment_repeat);
    const std::optional<Vec3> step = stage_vec(time, scale.increment_time, scale.increment);
    if (!step) return;
    grow(grain, step->x * dt, step->y * dt, step->z * dt);
}

// _affectParticles của ScaleInterpolatorAffector, RVA 0xD640. Increment nội suy cả ba trục rồi
// cộng vào kích thước riêng, kẹp về 0.
void scale_grain(const SystemDef& definition, Grain& grain, const ScaleInterpolator& scale, float dt) {
    if (!grain.own) return set_size(grain, definition.width, definition.height, definition.depth);
    if (scale.use_constant) return scale_constant(grain, scale, dt);
    if (scale.use_interpolated) return scale_lerp(definition, grain, scale);
    if (scale.use_increment) scale_increment(grain, scale, dt);
}

void affect_one(Field& field, Grain& grain, const Affector& affector, float dt) {
    if (const auto* force = std::get_if<LinearForce>(&affector)) {
        if (force->average) grain.direction = scaled(add(grain.direction, force->force), 0.5F);
        if (!force->average) grain.direction = add(grain.direction, scaled(force->force, dt));
        return;
    }
    if (const auto* scaler = std::get_if<Scaler>(&affector)) {
        const float delta = scaler->rate * dt;
        const float width = grain.own ? grain.width + delta : field.definition().width + delta;
        const float height = grain.own ? grain.height + delta : field.definition().height + delta;
        return set_size(grain, width, height, field.definition().depth);
    }
    if (const auto* rotator = std::get_if<Rotator>(&affector)) {
        grain.rotation += dt * grain.rotation_speed;
        static_cast<void>(rotator);
        return;
    }
    if (const auto* fading = std::get_if<ColourFading>(&affector)) return fade_colour(grain, *fading);
    if (const auto* scale = std::get_if<ScaleInterpolator>(&affector))
        return scale_grain(field.definition(), grain, *scale, dt);
    if (const auto* movement = std::get_if<Movement>(&affector)) {
        const Vec3 jitter{.x = field.range(movement->random_min.x, movement->random_max.x),
            .y = field.range(movement->random_min.y, movement->random_max.y),
            .z = field.range(movement->random_min.z, movement->random_max.z)};
        grain.direction = add(grain.direction, scaled(movement->acceleration, dt));
        grain.direction = add(grain.direction, scaled(jitter, dt));
    }
    if (std::holds_alternative<MeshRotator>(affector)) grain.angles = add(grain.angles, scaled(grain.angle_speeds, dt));
    if (const auto* jitter = std::get_if<DirectionRandomiser>(&affector)) {
        // scope là phần trăm hạt bị rung mỗi nhịp.
        if (field.unit() * 100.0F >= jitter->scope) return;
        const float length = std::sqrt((grain.direction.x * grain.direction.x) +
            (grain.direction.y * grain.direction.y) + (grain.direction.z * grain.direction.z));
        const Vec3 kick{.x = field.range(-jitter->randomness, jitter->randomness),
            .y = field.range(-jitter->randomness, jitter->randomness),
            .z = field.range(-jitter->randomness, jitter->randomness)};
        grain.direction = add(grain.direction, scaled(kick, dt));
        if (!jitter->keep_velocity) return;
        const float rotated = std::sqrt((grain.direction.x * grain.direction.x) +
            (grain.direction.y * grain.direction.y) + (grain.direction.z * grain.direction.z));
        if (rotated > 0.0F) grain.direction = scaled(grain.direction, length / rotated);
    }
}

void init_one(Field& field, Grain& grain, const Affector& affector) {
    if (const auto* rotator = std::get_if<Rotator>(&affector)) {
        grain.rotation = field.range(rotator->angle_start, rotator->angle_end);
        grain.rotation_speed = field.range(rotator->speed_start, rotator->speed_end);
    }
    if (std::get_if<ColourFading>(&affector) != nullptr) grain.colour = Colour{0.0F, 0.0F, 0.0F, 1.0F};
    if (const auto* scale = std::get_if<ScaleInterpolator>(&affector)) {
        const bool ranged =
            scale->width_start != field.definition().width || scale->height_start != field.definition().height;
        if (!ranged) return;
        const float width = field.range(scale->width_start, scale->width_end);
        const float height = scale->uniform ? width : field.range(scale->height_start, scale->height_end);
        set_size(grain, width, height, field.definition().depth);
    }
    if (const auto* movement = std::get_if<Movement>(&affector)) {
        if (!movement->use_start) return;
        grain.direction = Vec3{.x = field.range(movement->start_min.x, movement->start_max.x),
            .y = field.range(movement->start_min.y, movement->start_max.y),
            .z = field.range(movement->start_min.z, movement->start_max.z)};
    }
    if (const auto* frames = std::get_if<SequenceFrame>(&affector)) {
        grain.frame_start = field.range(frames->start_min, frames->start_max);
    }
    if (const auto* mesh = std::get_if<MeshRotator>(&affector)) {
        grain.angle_speeds.x = field.range(mesh->speed_start.x, mesh->speed_end.x);
        grain.angle_speeds.y = field.range(mesh->speed_start.y, mesh->speed_end.y);
        grain.angle_speeds.z = field.range(mesh->speed_start.z, mesh->speed_end.z);
        grain.angles.x = field.range(mesh->angle_start.x, mesh->angle_end.x);
        grain.angles.y = field.range(mesh->angle_start.y, mesh->angle_end.y);
        grain.angles.z = field.range(mesh->angle_start.z, mesh->angle_end.z);
    }
}

[[nodiscard]] Vec3 area_point(Field& field, const EmitterDef& emitter) {
    const Vec3 unit{.x = field.range(-1.0F, 1.0F), .y = field.range(-1.0F, 1.0F), .z = field.range(-1.0F, 1.0F)};
    const Vec3 spread =
        add(add(scaled(emitter.x_range, unit.x), scaled(emitter.y_range, unit.y)), scaled(emitter.z_range, unit.z));
    return add(emitter.position, spread);
}

[[nodiscard]] Vec3 sub(Vec3 left, Vec3 right) {
    return ogre::sub_vec3(left, right);
}

[[nodiscard]] Vec3 unit_vec(Vec3 value) {
    const float length = ogre::length_vec3(value);
    if (!(length > 1.0e-8F)) return value;
    return scaled(value, 1.0F / length);
}

[[nodiscard]] std::optional<float> stage_float(float time, const std::array<float, kStages>& times,
    const std::array<float, kStages>& values) {
    if (time <= times[0]) return values[0];
    if (time >= times[kStages - 1]) return values[kStages - 1];
    for (std::size_t index = 0; index + 1 < kStages; ++index) {
        const bool inside = time >= times[index] && time < times[index + 1];
        if (!inside) continue;
        const float amount = (time - times[index]) / (times[index + 1] - times[index]);
        return (values[index + 1] * amount) + (values[index] * (1.0F - amount));
    }
    return std::nullopt;
}

struct PolarCursor {
    float* radius = nullptr;
    float* theta = nullptr;
    float* phi = nullptr;
    int* resets = nullptr;
};

void advance_polar(PolarCursor cursor, const EmitterDef& source) {
    *cursor.theta = std::fmod(*cursor.theta + source.theta_step, 360.0F);
    *cursor.phi = std::fmod(*cursor.phi + source.phi_step, 360.0F);
    const bool reset = source.reset_radius && ++*cursor.resets > source.reset_count;
    if (reset) *cursor.resets = 0;
    *cursor.radius = reset ? source.radius_start : *cursor.radius + source.radius_step;
}

[[nodiscard]] Vec3 place_polar(Field& field, PolarCursor cursor, const EmitterDef& source) {
    const float radius = source.polar_step ? *cursor.radius : field.range(source.radius_start, source.radius_end);
    const float theta_deg = source.polar_step ? *cursor.theta : field.range(source.theta_start, source.theta_end);
    const float phi_deg = source.polar_step ? *cursor.phi : field.range(source.phi_start, source.phi_end);
    const float theta = theta_deg * kDegree;
    const float phi = phi_deg * kDegree;
    const float ring = radius * std::sin(theta);
    Vec3 place{.x = ring * std::cos(phi), .z = radius * std::cos(theta)};
    place.y = ring * std::sin(phi);
    if (source.flip_yz) {
        const float swapped = place.y;
        place.y = place.z;
        place.z = swapped;
    }
    if (source.polar_step) advance_polar(cursor, source);
    return place;
}

void add_spin_scale(Grain& grain, const Revolution& spin, Vec3 radial) {
    const std::optional<float> grown = stage_float(repeated(grain.life(), spin.repeat_times), spin.time, spin.scale);
    if (spin.use_scale && grown) grain.direction = add(grain.direction, scaled(radial, *grown));
    if (!spin.use_scale) grain.direction = add(grain.direction, scaled(radial, spin.radius_increment));
}

void add_drift(Grain& grain, const Revolution& spin) {
    if (!spin.move) return;
    if (!spin.variable_velocity) {
        grain.direction = add(grain.direction, spin.move_velocity);
        return;
    }
    const std::optional<Vec3> drift =
        stage_vec(repeated(grain.life(), spin.move_repeat), spin.move_time, spin.move_points);
    if (drift) grain.direction = add(grain.direction, *drift);
}

void spin_one(Grain& grain, const Revolution& spin, const ogre::Quat& turn, Vec3 center, float dt) {
    const Vec3 relative = sub(grain.position, center);
    const Vec3 turned = ogre::quat_rotate(turn, relative);
    grain.direction = scaled(sub(turned, relative), 1.0F / dt);
    add_spin_scale(grain, spin, unit_vec(relative));
    add_drift(grain, spin);
}

} // namespace

void Field::revolve(const Revolution& spin, float dt) {
    if (std::fabs(dt) <= 1.1920929e-7F) return;
    const ogre::Quat turn = ogre::quat_from_angle_axis(spin.speed * dt, spin.axis);
    const Vec3 offset{.x = range(spin.center_min.x, spin.center_max.x),
        .y = range(spin.center_min.y, spin.center_max.y),
        .z = range(spin.center_min.z, spin.center_max.z)};
    Vec3 center = offset;
    if (!definition_->local_space) center = add(node_.position, offset);
    for (const std::uint32_t index : active_)
        spin_one(pool_[index], spin, turn, center, dt);
}

void Field::apply_kind(const Affector& affector, float dt) {
    if (const auto* spin = std::get_if<Revolution>(&affector)) {
        revolve(*spin, dt);
        return;
    }
    for (const std::uint32_t index : active_)
        affect_one(*this, pool_[index], affector, dt);
}

void Field::affect(float dt) {
    for (const Affector& affector : definition_->affectors)
        apply_kind(affector, dt);
}

void Field::init_grain(std::size_t emitter, Grain& grain) {
    const EmitterDef& source = definition_->emitters[emitter];
    grain = Grain{};
    EmitterState& state = emitters_[emitter];
    PolarCursor cursor{&state.radius, &state.theta, &state.phi, &state.reset_count};
    if (source.kind == EmitterKind::kPolar) grain.position = add(source.position, place_polar(*this, cursor, source));
    if (source.kind == EmitterKind::kPoint) grain.position = source.position;
    if (source.kind != EmitterKind::kPolar && source.kind != EmitterKind::kPoint)
        grain.position = area_point(*this, source);
    const float angle = source.angle != 0.0F ? unit() * source.angle : 0.0F;
    Vec3 direction = source.direction;
    if (angle != 0.0F) {
        const ogre::Quat deviate = ogre::quat_from_angle_axis(angle, source.up);
        direction = ogre::quat_rotate(deviate, direction);
    }
    grain.direction = scaled(direction, range(source.velocity_min, source.velocity_max));
    grain.ttl = grain.total = range(source.ttl_min, source.ttl_max);
    grain.colour = source.colour_start;
}

void Field::spawn(std::size_t emitter, float offset) {
    if (free_.empty()) return;
    const std::uint32_t index = free_.back();
    free_.pop_back();
    active_.push_back(index);
    chains_[index].head = kEmptyLink;
    chains_[index].tail = kEmptyLink;
    chains_[index].ordered.clear();
    Grain& grain = pool_[index];
    init_grain(emitter, grain);
    if (!definition_->local_space) {
        const Vec3 local = ogre::mul_vec3(node_.scale, grain.position);
        grain.position = add(ogre::quat_rotate(node_.orientation, local), node_.position);
        grain.direction = ogre::quat_rotate(node_.orientation, grain.direction);
    }
    grain.position = add(grain.position, scaled(grain.direction, offset));
    for (const Affector& affector : definition_->affectors)
        init_one(*this, grain, affector);
}

std::uint16_t Field::emission_count(std::size_t emitter, float dt) {
    const EmitterDef& source = definition_->emitters[emitter];
    EmitterState& state = emitters_[emitter];
    if (!state.enabled) return 0;
    state.remainder += source.emission_rate * dt;
    const float whole = std::clamp(std::floor(state.remainder), 0.0F, 65535.0F);
    state.remainder -= whole;
    return static_cast<std::uint16_t>(whole);
}

void Field::emit(float dt) {
    for (std::size_t index = 0; index < emitters_.size(); ++index) {
        const std::uint16_t count = emission_count(index, dt);
        const float step = count > 0 ? dt / static_cast<float>(count) : 0.0F;
        for (std::uint16_t born = 0; born < count; ++born)
            spawn(index, step * static_cast<float>(born));
    }
}

} // namespace game::fx
