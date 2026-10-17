/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/fx/area.cpp
 *  PHÂN HỆ   : Place / Fx / Area
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Port _initParticle của Box, Ring, Cylinder, Ellipsoid, HollowEllipsoid từ
 *    Plugin_ParticleFX bản TLBB; địa chỉ lệnh ghi ở từng hàm. Giữ thứ tự rút số
 *    ngẫu nhiên và phép tính float như mã máy.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fx/area.hpp"

#include "fx/field.hpp"
#include "fx/system.hpp"
#include "ogre/vec3.hpp"

#include <cmath>
#include <numbers>

namespace game::fx {
namespace {

using ogre::Vec3;

constexpr float kPi = std::numbers::pi_v<float>;
constexpr float kTwoPi = 2.0F * kPi;
// Math::TWO_PI·2/3, góc dời của nghiệm lượng giác thứ ba.
constexpr float kTwoThirdsTurn = (kTwoPi * 2.0F) / 3.0F;
// Math::RealEqual với dung sai của mã gốc (0x1800131e0).
constexpr float kTolerance = 1.1920929e-07F;
// Ngưỡng của curve và bend_angle; mã gốc so ở double.
constexpr double kBendFloor = 0.05;

[[nodiscard]] bool real_equal(float left, float right) noexcept {
    return std::fabs(right - left) <= kTolerance;
}

// Vector3::isZeroLength.
[[nodiscard]] bool is_zero_length(Vec3 value) noexcept {
    const float squared = ogre::dot_vec3(value, value);
    return static_cast<double>(squared) < 1.0e-12;
}

// Math::ACos: ngoài (−1, 1) thì trả π hoặc 0.
[[nodiscard]] float clamped_acos(float value) noexcept {
    if (value <= -1.0F) return kPi;
    if (value >= 1.0F) return 0.0F;
    return std::acos(value);
}

// P + x·xRange + y·yRange + z·zRange.
[[nodiscard]] Vec3 spread(const EmitterDef& emitter, Vec3 weights) {
    const Vec3 x_part = ogre::scale_vec3(emitter.x_range, weights.x);
    const Vec3 y_part = ogre::scale_vec3(emitter.y_range, weights.y);
    const Vec3 z_part = ogre::scale_vec3(emitter.z_range, weights.z);
    const Vec3 flat = ogre::add_vec3(x_part, y_part);
    const Vec3 offset = ogre::add_vec3(flat, z_part);
    return ogre::add_vec3(emitter.position, offset);
}

// BoxEmitter (0x180002570), giống OGRE gốc: SymmetricRandom cho x, y, z theo thứ tự ấy.
[[nodiscard]] Vec3 box_point(Field& field, const EmitterDef& emitter) {
    const float across = field.range(-1.0F, 1.0F);
    const float along = field.range(-1.0F, 1.0F);
    const float depth = field.range(-1.0F, 1.0F);
    const Vec3 weights{.x = across, .y = along, .z = depth};
    return spread(emitter, weights);
}

// RingEmitter (0x18000d680): góc 0..2π, hai bán kính trong [inner, 1], chiều sâu SymmetricRandom.
// Khác OGRE gốc lấy chiều sâu 0..1.
[[nodiscard]] Vec3 ring_point(Field& field, const EmitterDef& emitter) {
    const float alpha = field.range(0.0F, kTwoPi);
    const float across = field.range(emitter.inner.x, 1.0F);
    const float along = field.range(emitter.inner.y, 1.0F);
    const float depth = field.range(-1.0F, 1.0F);
    const Vec3 weights{.x = across * std::sin(alpha), .y = std::cos(alpha) * along, .z = depth};
    return spread(emitter, weights);
}

// Uốn theo bend_angle (0x180006590): điểm quay quanh tâm cách trục 2/θ, góc tỉ lệ chiều sâu.
[[nodiscard]] Vec3 bend_point(Vec3 point, float degrees) {
    const bool is_straight = static_cast<double>(std::fabs(degrees)) < kBendFloor;
    if (is_straight) return point;
    const float theta = -(degrees * kDegree);
    const float radius = 2.0F / theta;
    const float phi = point.z * 0.5F * theta;
    const float reach = radius + point.x;
    return Vec3{.x = (std::cos(phi) * reach) - radius, .y = point.y, .z = std::sin(phi) * reach};
}

// CylinderEmitter (0x180006690): vành khuyên góc angle_range, co theo topdown_ratio dọc chiều sâu
// và phình theo curve, rồi uốn. Chiều sâu 0 (zRange dài 0) làm phần X bằng 0, như mã gốc.
[[nodiscard]] Vec3 cylinder_point(Field& field, const EmitterDef& emitter) {
    const float first = emitter.angle_range.x * kDegree;
    const float last = emitter.angle_range.y * kDegree;
    const float alpha = field.range(first, last);
    const float across = field.range(emitter.inner.x, 1.0F);
    const float along = field.range(emitter.inner.y, 1.0F);
    const float depth = field.range(-1.0F, 1.0F);
    const bool curves = static_cast<double>(std::fabs(emitter.curve)) >= kBendFloor;
    const float bulge = curves ? ((1.0F - (depth * depth)) * emitter.curve) + 1.0F : 1.0F;
    const float spread_top = emitter.topdown.x - emitter.topdown.y;
    const float taper = (spread_top * (depth + 1.0F) * 0.5F) + emitter.topdown.y;
    const float scale = taper * bulge;
    const float side_x = std::sin(alpha) * across * scale;
    const float side_y = std::cos(alpha) * along * scale;
    const float x_length = ogre::length_vec3(emitter.x_range);
    const float z_length = ogre::length_vec3(emitter.z_range);
    const bool has_depth = !is_zero_length(emitter.z_range);
    const float stretched = has_depth ? (x_length * side_x) / z_length : 0.0F;
    const Vec3 straight{.x = stretched, .y = side_y, .z = depth};
    const Vec3 bent = bend_point(straight, emitter.bend);
    const bool has_width = !is_zero_length(emitter.x_range);
    const float back = has_width ? (z_length * bent.x) / x_length : 0.0F;
    const Vec3 weights{.x = back, .y = bent.y, .z = bent.z};
    return spread(emitter, weights);
}

// Ba bán kính trong của Ellipsoid và V = ix·iy·iz.
struct Shell {
    float width = 0.0F;
    float height = 0.0F;
    float depth = 0.0F;
    float volume = 0.0F;
};

// Fo(h) = (3h − h³ + 2)/3: thể tích chỏm cầu đơn vị từ đáy tới h, nhân 3/π.
[[nodiscard]] float cap_volume(float height) noexcept {
    return ((3.0F * height) - (height * height * height) + 2.0F) / 3.0F;
}

// Fu(h) = (3h − h³ + 2 − 4V)/3: như Fo nhưng trừ cả lõi rỗng.
[[nodiscard]] float upper_volume(const Shell& shell, float height) noexcept {
    const float cube = height * height * height;
    return ((3.0F * height) - cube + 2.0F - (4.0F * shell.volume)) / 3.0F;
}

// Fm(h): thể tích từ đáy tới h khi h cắt qua lõi rỗng.
[[nodiscard]] float band_volume(const Shell& shell, float height) noexcept {
    const float flat = shell.width * shell.height;
    const float deep = shell.depth * shell.depth;
    const float cube = height * height * height;
    const float rest = (2.0F - (2.0F * shell.volume)) / 3.0F;
    return ((1.0F - flat) * height) + (((flat - deep) * cube) / (3.0F * deep)) + rest;
}

// Nghiệm của h³ − 3h + 2 − 3u = 0 trong [−1, 1], với c = 1 − 1,5u (0x180009464..).
[[nodiscard]] float cap_height(float cosine) noexcept {
    return 2.0F * std::cos((clamped_acos(cosine) / 3.0F) + kTwoThirdsTurn);
}

// Pow(|x|, 1/3) mang dấu của x.
[[nodiscard]] float signed_cbrt(float value) noexcept {
    const float size = std::pow(std::fabs(value), 1.0F / 3.0F);
    return std::copysign(size, value);
}

// h³ + p·h + q = 0.
struct Cubic {
    float slope = 0.0F;
    float shift = 0.0F;
};

// D < 0: nghiệm lượng giác thứ ba.
[[nodiscard]] float trig_root(const Cubic& cubic) noexcept {
    const float slope = cubic.slope;
    const float size = std::sqrt(-(slope * slope * slope) / 27.0F);
    const float turn = clamped_acos(-cubic.shift / (2.0F * size)) / 3.0F;
    return 2.0F * std::pow(size, 1.0F / 3.0F) * std::cos(turn + kTwoThirdsTurn);
}

// Chiều cao của dải cắt qua lõi rỗng (0x1800088f1..): Fm(h) = u. Lõi tròn theo đáy (ix·iy = iz²)
// thì Fm tuyến tính; còn lại giải bậc ba theo Cardano.
[[nodiscard]] float band_height(const Shell& shell, float volume) noexcept {
    const float flat = shell.width * shell.height;
    const float deep = shell.depth * shell.depth;
    const float rest = (2.0F - (2.0F * shell.volume)) / 3.0F;
    if (real_equal(flat, deep)) return (volume - rest) / (1.0F - flat);
    const float slope = (3.0F * deep * (1.0F - flat)) / (flat - deep);
    const float lead = 2.0F - (2.0F * shell.volume) - (3.0F * volume);
    const float shift = (lead * deep) / (flat - deep);
    const float half = shift / 2.0F;
    const float third = slope / 3.0F;
    const float discriminant = (half * half) + (third * third * third);
    const Cubic cubic{.slope = slope, .shift = shift};
    if (discriminant < 0.0F) return trig_root(cubic);
    const float root = std::sqrt(discriminant);
    return signed_cbrt(root - half) + signed_cbrt(-half - root);
}

[[nodiscard]] float angle_of(Field& field, const EmitterDef& emitter) {
    const float degrees = field.range(emitter.angle_range.x, emitter.angle_range.y);
    return degrees * kDegree;
}

// Chỏm của Ellipsoid (0x1800094aa..0x1800095c2): góc rồi w = UnitRandom, bán kính co theo
// 1 − w², góc 0 trên trục +X (cos·X + sin·Y; Ring và Cylinder dùng sin·X).
[[nodiscard]] Vec3 cap_point(Field& field, const EmitterDef& emitter, float height) {
    const float angle = angle_of(field, emitter);
    const float spin = field.unit();
    const float reach = std::sqrt(1.0F - (height * height)) * (1.0F - (spin * spin));
    const Vec3 weights{.x = reach * std::cos(angle), .y = reach * std::sin(angle), .z = height};
    return spread(emitter, weights);
}

// Dải cắt qua lõi: nội suy theo w² giữa mặt ngoài và mặt lõi.
[[nodiscard]] Vec3 band_point(Field& field, const EmitterDef& emitter, const Shell& shell,
    float volume) {
    const float height = band_height(shell, volume);
    const float angle = angle_of(field, emitter);
    const float spin = field.unit();
    const float pull = spin * spin;
    const float keep = 1.0F - pull;
    const float outer = std::sqrt(1.0F - (height * height));
    const float inner = std::sqrt(1.0F - ((height * height) / (shell.depth * shell.depth)));
    const float cosine = std::cos(angle);
    const float sine = std::sin(angle);
    const float weight_x = (keep * outer * cosine) + (pull * inner * cosine * shell.width);
    const float weight_y = (keep * outer * sine) + (pull * inner * sine * shell.height);
    const Vec3 weights{.x = weight_x, .y = weight_y, .z = height};
    return spread(emitter, weights);
}

[[nodiscard]] float low_volume(const Shell& shell, float height) noexcept {
    if (height <= -shell.depth) return cap_volume(height);
    if (height <= shell.depth) return band_volume(shell, height);
    return upper_volume(shell, height);
}

// Cận trên so nghiêm ngặt, cận dưới so không nghiêm (0x1800086aa..).
[[nodiscard]] float high_volume(const Shell& shell, float height) noexcept {
    if (height < -shell.depth) return cap_volume(height);
    if (height < shell.depth) return band_volume(shell, height);
    return upper_volume(shell, height);
}

// Nhánh rỗng (0x18000851d): rút thể tích u trong [lo, hi] rồi chọn chỏm dưới, dải, chỏm trên.
[[nodiscard]] Vec3 shell_point(Field& field, const EmitterDef& emitter, Pair heights) {
    const Vec3& inner = emitter.inner;
    const float core = inner.x * inner.y * inner.z;
    const Shell shell{.width = inner.x, .height = inner.y, .depth = inner.z, .volume = core};
    const float low = low_volume(shell, heights.x);
    const float high = high_volume(shell, heights.y);
    const float volume = field.range(low, high);
    const float lower_cap = cap_volume(-shell.depth);
    const float upper_band = upper_volume(shell, shell.depth);
    const float whole = (4.0F * (1.0F - shell.volume)) / 3.0F;
    const bool in_lower = volume >= 0.0F && volume <= lower_cap;
    const bool in_band = volume > lower_cap && volume < upper_band;
    const bool in_upper = volume >= upper_band && volume <= whole;
    const float lower_height = cap_height(1.0F - (1.5F * volume));
    const float upper_height = cap_height(1.0F - (2.0F * shell.volume) - (1.5F * volume));
    if (in_lower) return cap_point(field, emitter, lower_height);
    if (in_band) return band_point(field, emitter, shell, volume);
    if (in_upper) return cap_point(field, emitter, upper_height);
    // Khác gốc: mã gốc không ghi vị trí (hạt giữ vị trí đời trước trong pool); ở đây đứng ở tâm.
    return emitter.position;
}

// Nhánh mặt (0x1800083e6): ba bán kính trong bằng 1.
[[nodiscard]] Vec3 surface_point(Field& field, const EmitterDef& emitter, Pair heights) {
    const float height = field.range(heights.x, heights.y);
    const float reach = std::sqrt(1.0F - (height * height));
    const float angle = angle_of(field, emitter);
    const Vec3 weights{.x = reach * std::cos(angle), .y = reach * std::sin(angle), .z = height};
    return spread(emitter, weights);
}

// Nhánh đặc (0x1800093cc): một bán kính trong bằng 0.
[[nodiscard]] Vec3 solid_point(Field& field, const EmitterDef& emitter, Pair heights) {
    const float lowest = cap_volume(heights.x);
    const float highest = cap_volume(heights.y);
    const float volume = field.range(lowest, highest);
    const float height = cap_height(1.0F - (1.5F * volume));
    return cap_point(field, emitter, height);
}

[[nodiscard]] bool has_zero_inner(Vec3 inner) noexcept {
    const bool flat = real_equal(0.0F, inner.x) || real_equal(0.0F, inner.y);
    return flat || real_equal(0.0F, inner.z);
}

[[nodiscard]] bool is_unit_inner(Vec3 inner) noexcept {
    const bool flat = real_equal(1.0F, inner.x) && real_equal(1.0F, inner.y);
    return flat && real_equal(1.0F, inner.z);
}

// EllipsoidEmitter (0x1800082c0) của bản TLBB: phân bố theo thể tích trong dải height_range
// (0..1 dọc trục Z, đổi sang −1..1) và góc angle_range.
[[nodiscard]] Vec3 ellipsoid_point(Field& field, const EmitterDef& emitter) {
    const float low = (2.0F * emitter.height_range.x) - 1.0F;
    const float high = (2.0F * emitter.height_range.y) - 1.0F;
    const Pair heights{.x = low, .y = high};
    if (has_zero_inner(emitter.inner)) return solid_point(field, emitter, heights);
    if (is_unit_inner(emitter.inner)) return surface_point(field, emitter, heights);
    return shell_point(field, emitter, heights);
}

// HollowEllipsoidEmitter (0x180009e10), giống OGRE gốc; không đọc angle_range, height_range.
[[nodiscard]] Vec3 hollow_point(Field& field, const EmitterDef& emitter) {
    const float alpha = field.range(0.0F, kTwoPi);
    const float beta = field.range(0.0F, kPi);
    const float across = field.range(emitter.inner.x, 1.0F);
    const float along = field.range(emitter.inner.y, 1.0F);
    const float depth = field.range(emitter.inner.z, 1.0F);
    const float lift = std::sin(beta);
    const float weight_x = across * std::cos(alpha) * lift;
    const float weight_y = along * std::sin(alpha) * lift;
    const Vec3 weights{.x = weight_x, .y = weight_y, .z = depth * std::cos(beta)};
    return spread(emitter, weights);
}

} // namespace

Vec3 area_point(Field& field, const EmitterDef& emitter) {
    switch (emitter.kind) {
    case EmitterKind::kBox: return box_point(field, emitter);
    case EmitterKind::kRing: return ring_point(field, emitter);
    case EmitterKind::kCylinder: return cylinder_point(field, emitter);
    case EmitterKind::kEllipsoid: return ellipsoid_point(field, emitter);
    case EmitterKind::kHollowEllipsoid: return hollow_point(field, emitter);
    case EmitterKind::kPoint:
    case EmitterKind::kPolar: return emitter.position;
    }
    return emitter.position;
}

} // namespace game::fx
