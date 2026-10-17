/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/fx/strip.cpp
 *  PHÂN HỆ   : Place / Fx / Strip
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Điểm của Beam (WXBeamElement) và vệt NewRibbonTrail để cast dựng dải quad.
 *  - Màu vệt theo Render.dll 0x180158970 và saturate của 0x180158fa0 (REA
 *    2026-10-18); vòng cập nhật vệt còn khác gốc, xem docs/NGHI-NGO.md mục 65c.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fx/strip.hpp"

#include "ogre/quat.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <random>

namespace game::fx {
namespace {

using ogre::Vec3;

[[nodiscard]] bool unset_dest(Vec3 dest) {
    return dest.x == 0.0F && dest.y == 1.0F && dest.z == 0.0F;
}

[[nodiscard]] float unit_of(std::mt19937& random) {
    return static_cast<float>(random()) / static_cast<float>(std::mt19937::max());
}

[[nodiscard]] float range_of(std::mt19937& random, float low, float high) {
    return low + (unit_of(random) * (high - low));
}

[[nodiscard]] Colour beam_colour(const ElementDef& element, std::mt19937& random) {
    const bool same = element.colour_a == element.colour_b;
    if (same) return element.colour_a;
    Colour colour{};
    for (std::size_t channel = 0; channel < 4; ++channel) {
        colour[channel] = range_of(random, element.colour_a[channel], element.colour_b[channel]);
    }
    return colour;
}

[[nodiscard]] Vec3 beam_noise(const ElementDef& element, std::mt19937& random) {
    return Vec3{.x = range_of(random, element.noise_min.x, element.noise_max.x),
        .y = range_of(random, element.noise_min.y, element.noise_max.y),
        .z = range_of(random, element.noise_min.z, element.noise_max.z)};
}

// RVA 0x227C90: pha quá 360 về 0 rồi mới dùng. y cộng sin, z cộng cos, rồi quat +0x114.
// IsSinPlay chỉ tăng pha một độ sau mỗi mốc, không tắt sóng.
void sway_beam(Vec3& position, const ElementDef& element, int index, float& phase) {
    if (phase > 360.0F) phase = 0.0F;
    const auto time = static_cast<float>(index);
    const float degrees = (time * element.wave_frequency) + (phase * element.wave_velocity);
    const float radians = degrees * kDegree;
    const float amp_y = (time * element.shade_y) + element.extent_y;
    const float amp_z = (time * element.shade_z) + element.extent_z;
    position.y += std::sin(radians) * amp_y;
    position.z += std::cos(radians) * amp_z;
    position = ogre::quat_rotate(element.wave, position);
    if (element.sin_play) phase += 1.0F;
}

[[nodiscard]] Vec3 beam_place(const ElementDef& element, Vec3 dest, int index, std::mt19937& random, float& phase) {
    const auto count = static_cast<float>(element.links);
    const bool head = index == 0;
    const bool tail = index + 1 == element.links;
    const float along = head ? 0.0F : static_cast<float>(index) / count;
    Vec3 position = ogre::scale_vec3(dest, tail ? 1.0F : along);
    if (head) position = {};
    if (!head && !tail) position = ogre::add_vec3(position, beam_noise(element, random));
    sway_beam(position, element, index, phase);
    return position;
}

void store_beam(std::vector<ChainSample>& points, const ElementDef& element, Vec3 position, int index, Colour colour) {
    const auto count = static_cast<float>(element.links);
    const bool head = index == 0;
    const bool tail = index + 1 == element.links;
    const float along = head ? 0.0F : static_cast<float>(index) / count;
    const float span = tail ? 1.0F : along;
    ChainSample sample;
    sample.position = position;
    sample.width = element.width;
    sample.along = span * static_cast<float>(element.tex_repeat);
    sample.colour = colour;
    points.push_back(sample);
}

void push_beam(std::vector<ChainSample>& points, const ElementDef& element, Vec3 dest, int index, Colour colour,
    std::mt19937& random, float& phase) {
    const Vec3 position = beam_place(element, dest, index, random, phase);
    store_beam(points, element, position, index, colour);
}

void age_marks(TrailRun& run, float dt) {
    for (TrailMark& mark : run.marks)
        mark.age += dt;
}

void keep_mark(std::vector<TrailMark>& kept, const TrailMark& mark, float lift) {
    if (mark.age <= lift) kept.push_back(mark);
}

void drop_lifted(TrailRun& run, float lift) {
    if (!(lift > 0.0F)) return;
    std::vector<TrailMark> kept;
    for (const TrailMark& mark : run.marks)
        keep_mark(kept, mark, lift);
    run.marks = std::move(kept);
}

[[nodiscard]] float trail_span(const TrailRun& run) {
    float length = 0.0F;
    for (std::size_t index = 1; index < run.marks.size(); ++index) {
        const Vec3 step = ogre::sub_vec3(run.marks[index - 1].position, run.marks[index].position);
        length += ogre::length_vec3(step);
    }
    return length;
}

void trim_trail(TrailRun& run, const ElementDef& element) {
    while (static_cast<int>(run.marks.size()) > element.chain_count && run.marks.size() > 2)
        run.marks.pop_back();
    while (trail_span(run) > element.trail_length && run.marks.size() > 2)
        run.marks.pop_back();
}

void follow_head(TrailRun& run, const ElementDef& element, Vec3 head) {
    if (run.marks.empty()) {
        run.marks.push_back(TrailMark{.position = head, .age = 0.0F});
        return;
    }
    const Vec3 step = ogre::sub_vec3(head, run.marks.front().position);
    const float segment = element.trail_length / static_cast<float>(element.chain_count);
    const bool stretched = ogre::dot_vec3(step, step) >= segment * segment;
    if (stretched) run.marks.insert(run.marks.begin(), TrailMark{.position = head, .age = 0.0F});
    if (!stretched) run.marks.front().position = head;
}

[[nodiscard]] float clamp_width(const ElementDef& element, float width) {
    float cut = width;
    if (element.high_cut > element.low_cut && cut < element.low_cut) cut = element.low_cut;
    if (element.high_cut > element.low_cut && cut > element.high_cut) cut = element.high_cut;
    return cut < 0.0F ? 0.0F : cut;
}

// Màu theo tuổi điểm theo Render.dll 0x180158970 (Fairy::RibbonTrail, đọc bằng REA 2026-10-18):
// mốc đầu tiên có time > tuổi quyết định. Mốc 0 trả màu mốc 0; mốc sau nội suy với mốc trước;
// quá cả năm mốc thì màu mốc 4, kể cả khi dữ liệu không đặt mốc ấy (Black của ctor).
[[nodiscard]] std::size_t later_mark(const ElementDef& element, float age) {
    for (std::size_t index = 0; index < kFade; ++index) {
        if (element.fade_time[index] > age) return index;
    }
    return kFade;
}

// Trọng số đúng lệnh gốc: mốc trước nhân (time - tuổi) / span, mốc sau nhân (tuổi - before) /
// span, rồi cộng. span > 0 vì before <= tuổi < time.
[[nodiscard]] Colour blend_fade(const ElementDef& element, float age, std::size_t index) {
    const float time = element.fade_time[index];
    const float before = element.fade_time[index - 1];
    const float span = time - before;
    const float early = (time - age) / span;
    const float late = (age - before) / span;
    const Colour& from = element.fade_colour[index - 1];
    const Colour& to = element.fade_colour[index];
    Colour mixed{};
    for (std::size_t channel = 0; channel < 4; ++channel)
        mixed[channel] = (early * from[channel]) + (late * to[channel]);
    return mixed;
}

[[nodiscard]] Colour marked_colour(const ElementDef& element, float age) {
    const std::size_t index = later_mark(element, age);
    if (index == kFade) return element.fade_colour[kFade - 1];
    if (index == 0) return element.fade_colour[0];
    return blend_fade(element, age, index);
}

// ColourValue::saturate của 0x180158fa0: kẹp từng kênh về [0, 1] trước khi gói màu đỉnh.
[[nodiscard]] Colour saturate(Colour colour) {
    for (float& channel : colour)
        channel = std::clamp(channel, 0.0F, 1.0F);
    return colour;
}

// Khác gốc: 0x180158fa0 so alpha <= AlphaColourCut; khi LiftTime >= 0 thì cắt đuôi vệt tại điểm
// ấy thay vì làm trong suốt (docs/NGHI-NGO.md mục 65c).
[[nodiscard]] Colour fade_at(const ElementDef& element, float age) {
    const Colour marked = marked_colour(element, age);
    Colour colour = saturate(marked);
    if (colour[3] <= element.alpha_cut) colour[3] = 0.0F;
    return colour;
}

void push_trail_point(std::vector<ChainSample>& points, const TrailRun& run, const ElementDef& element,
    std::size_t index, float total) {
    float walked = 0.0F;
    for (std::size_t step = 1; step <= index; ++step) {
        const Vec3 span = ogre::sub_vec3(run.marks[step - 1].position, run.marks[step].position);
        walked += ogre::length_vec3(span);
    }
    const float ratio = total > 0.0F ? walked / total : 0.0F;
    const float grown = element.head_width + ((element.tail_width - element.head_width) * ratio);
    ChainSample sample;
    sample.position = run.marks[index].position;
    sample.width = clamp_width(element, grown + (element.width_change * run.marks[index].age));
    sample.along = ratio;
    sample.colour = fade_at(element, run.marks[index].age);
    points.push_back(sample);
}

} // namespace

std::vector<ChainSample> beam_points(const ElementDef& element, Vec3 dest, std::uint32_t seed, float& phase) {
    std::vector<ChainSample> points;
    if (unset_dest(dest) || element.links < 2) return points;
    std::mt19937 random(seed == 0 ? 1U : seed);
    const Colour colour = beam_colour(element, random);
    for (int index = 0; index < element.links; ++index)
        push_beam(points, element, dest, index, colour, random, phase);
    return points;
}

void trail_step(TrailRun& run, const ElementDef& element, Vec3 head, float dt) {
    age_marks(run, dt);
    drop_lifted(run, element.lift_time);
    follow_head(run, element, head);
    trim_trail(run, element);
}

std::vector<ChainSample> trail_points(const TrailRun& run, const ElementDef& element) {
    std::vector<ChainSample> points;
    const float total = trail_span(run);
    for (std::size_t index = 0; index < run.marks.size(); ++index)
        push_trail_point(points, run, element, index, total);
    return points;
}

} // namespace game::fx
