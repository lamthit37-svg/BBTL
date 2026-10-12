// Camera chọn và tạo nhân vật (xem char_camera.hpp). Số của bốn track là mẫu bit mà 0x180001dc0 ghi
// vào khoá; phép nội suy theo NodeAnimationTrack::getInterpolatedKeyFrame, SimpleSpline và
// RotationalSpline của OgreMain.dll bản 2026, giữ thứ tự phép tính.
#include "control/char_camera.hpp"

#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::control {
namespace {

using Keys = std::span<const CameraKey>;

// Trần lượng phóng của màn tạo (0x1802bbda8) và hai mốc của bảng chọn (0x1802bbd70, 0x1802bbda4).
constexpr float kCreateZoomLimit = 400.0F;
constexpr float kSelectZoomFloor = bits(0x3DCCCCCDU);
constexpr float kSelectZoomLimit = 100.0F;

constexpr float kCreateLength = 0.5F;
constexpr float kRole0To1Length = 2.0F;
constexpr float kRole1To2Length = 2.5F;
constexpr float kRole2To0Length = 2.0F;

// Mắt nghỉ của ba ô và mắt hai giới ở màn tạo.
constexpr ogre::Vec3 kSlot0Eye = kRolePlaces[0].eye;
constexpr ogre::Vec3 kSlot1Eye = kRolePlaces[1].eye;
constexpr ogre::Vec3 kSlot2Eye = kRolePlaces[2].eye;
constexpr ogre::Vec3 kMaleEye{.x = bits(0x444D83C7U), .y = bits(0x44A8670AU), .z = bits(0x4565E852U)};

// Khoá giữa của ba đoạn chạy: camera lùi ra rồi mới tiến vào ô kế.
constexpr CameraKey kMid0To1{
    .time = 1.0F,
    .eye = {.x = bits(0xC29AD604U), .y = bits(0x44A37B85U), .z = bits(0x44F0EF0AU)},
    .look = {.x = bits(0x3C38BDB7U), .y = bits(0x3C07F710U), .z = bits(0x38C50223U), .w = bits(0x3F7FFA1AU)},
};
constexpr CameraKey kMid1To2{
    .time = 1.25F,
    .eye = {.x = bits(0x4447DD91U), .y = bits(0x44A37B85U), .z = bits(0x450B6052U)},
    .look = {.x = bits(0xBCBE666DU), .y = bits(0x3B3031B7U), .z = bits(0x3883D6FBU), .w = bits(0x3F7FEE80U)},
};
constexpr CameraKey kMid2To0{
    .time = 1.0F,
    .eye = {.x = bits(0x44C93333U), .y = bits(0x44A37B85U), .z = bits(0x44F0EF0AU)},
    .look = {.x = bits(0xBBAD68D9U), .y = bits(0x3C07F8D3U), .z = bits(0x3839B8DCU), .w = bits(0x3F7FFD61U)},
};

[[nodiscard]] constexpr CameraKey rest_key(float time, ogre::Vec3 eye) noexcept {
    return CameraKey{.time = time, .eye = eye, .look = kRoleLook};
}

[[nodiscard]] constexpr ogre::Quat add(ogre::Quat left, ogre::Quat right) noexcept {
    return {.x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z, .w = left.w + right.w};
}

[[nodiscard]] constexpr ogre::Quat scale(float factor, ogre::Quat value) noexcept {
    return {.x = factor * value.x, .y = factor * value.y, .z = factor * value.z, .w = factor * value.w};
}

// Kết quả của AnimationTrack::getKeyFramesAtTime: khoá trước, khoá sau và tham số giữa hai khoá.
struct Segment {
    std::size_t first = 0;
    std::size_t second = 0;
    float blend = 0.0F;
};

// Độ dài animation và thời điểm của state, giây.
struct Moment {
    float length = 0.0F;
    float time = 0.0F;
};

// time đã nằm trong [0, length] (AnimationState không lặp kẹp sẵn). Khoá sau là khoá đầu tiên có
// thời điểm không nhỏ hơn time; không còn khoá nào thì quay về khoá đầu, cộng độ dài animation.
[[nodiscard]] Segment segment_at(Keys keys, Moment moment) noexcept {
    const float time = moment.time;
    const float length = moment.length;
    std::size_t next = 0;
    while (next < keys.size() && keys[next].time < time)
        ++next;
    Segment found;
    float later = 0.0F;
    if (next == keys.size()) {
        found.second = 0;
        later = length + keys.front().time;
        found.first = next - 1;
    } else {
        found.second = next;
        later = keys[next].time;
        found.first = next != 0 && time < keys[next].time ? next - 1 : next;
    }
    const float earlier = keys[found.first].time;
    found.blend = earlier == later ? 0.0F : (time - earlier) / (later - earlier);
    return found;
}

// SimpleSpline::recalcTangents (Catmull-Rom): đường khép kín khi điểm đầu trùng điểm cuối.
[[nodiscard]] ogre::Vec3 eye_tangent(Keys keys, std::size_t index) noexcept {
    const std::size_t last = keys.size() - 1;
    const bool is_closed = keys.front().eye == keys[last].eye;
    if (index == 0 || (index == last && is_closed)) {
        const ogre::Vec3 before = is_closed ? keys[last - 1].eye : keys[0].eye;
        return ogre::scale_vec3(ogre::sub_vec3(keys[1].eye, before), 0.5F);
    }
    if (index == last) return ogre::scale_vec3(ogre::sub_vec3(keys[index].eye, keys[index - 1].eye), 0.5F);
    return ogre::scale_vec3(ogre::sub_vec3(keys[index + 1].eye, keys[index - 1].eye), 0.5F);
}

// Một toạ độ của SimpleSpline::interpolate: (t³, t², t, 1) nhân ma trận Hermite rồi nhân bốn hàng
// điểm đầu, điểm cuối, tiếp tuyến đầu, tiếp tuyến cuối; giữ cả các số hạng nhân 0 của phép nhân ma
// trận 4x4.
struct Hermite {
    float from = 0.0F;
    float finish = 0.0F;
    float from_tangent = 0.0F;
    float finish_tangent = 0.0F;
};

[[nodiscard]] constexpr float hermite(const Hermite& row, float blend) noexcept {
    const float square = blend * blend;
    const float cube = square * blend;
    const float near_weight = (cube * 2.0F) + (square * -3.0F) + (blend * 0.0F) + (1.0F * 1.0F);
    const float far_weight = (cube * -2.0F) + (square * 3.0F) + (blend * 0.0F) + (1.0F * 0.0F);
    const float near_slope = (cube * 1.0F) + (square * -2.0F) + (blend * 1.0F) + (1.0F * 0.0F);
    const float far_slope = (cube * 1.0F) + (square * -1.0F) + (blend * 0.0F) + (1.0F * 0.0F);
    return (near_weight * row.from) + (far_weight * row.finish) + (near_slope * row.from_tangent) +
        (far_slope * row.finish_tangent);
}

[[nodiscard]] ogre::Vec3 spline_eye(Keys keys, const Segment& at) noexcept {
    if (at.first + 1 == keys.size()) return keys[at.first].eye;
    if (at.blend == 1.0F) return keys[at.first + 1].eye;
    const ogre::Vec3 from = keys[at.first].eye;
    const ogre::Vec3 finish = keys[at.first + 1].eye;
    const ogre::Vec3 leave = eye_tangent(keys, at.first);
    const ogre::Vec3 arrive = eye_tangent(keys, at.first + 1);
    return {
        .x = hermite({.from = from.x, .finish = finish.x, .from_tangent = leave.x, .finish_tangent = arrive.x},
            at.blend),
        .y = hermite({.from = from.y, .finish = finish.y, .from_tangent = leave.y, .finish_tangent = arrive.y},
            at.blend),
        .z = hermite({.from = from.z, .finish = finish.z, .from_tangent = leave.z, .finish_tangent = arrive.z},
            at.blend),
    };
}

// RotationalSpline::recalcTangents (Shoemake): p * exp(-0,25 * (log(p⁻¹ * kế) + log(p⁻¹ * trước))).
// Đầu mút của đường hở lấy chính nó làm hàng xóm còn thiếu; đường khép kín vòng sang đầu kia.
[[nodiscard]] ogre::Quat look_tangent(Keys keys, std::size_t index) noexcept {
    const std::size_t last = keys.size() - 1;
    const bool is_closed = keys.front().look == keys[last].look;
    const ogre::Quat point = keys[index].look;
    const ogre::Quat inverse = ogre::quat_inverse(point);
    ogre::Quat after = point;
    ogre::Quat before = point;
    if (index < last) after = keys[index + 1].look;
    if (index == last && is_closed) after = keys[1].look;
    if (index > 0) before = keys[index - 1].look;
    if (index == 0 && is_closed) before = keys[last - 1].look;
    const ogre::Quat ahead = ogre::quat_log(ogre::quat_multiply(inverse, after));
    const ogre::Quat behind = ogre::quat_log(ogre::quat_multiply(inverse, before));
    return ogre::quat_multiply(point, ogre::quat_exp(scale(-0.25F, add(ahead, behind))));
}

[[nodiscard]] ogre::Quat spline_look(Keys keys, const Segment& at) noexcept {
    if (at.first + 1 == keys.size()) return keys[at.first].look;
    if (at.blend == 1.0F) return keys[at.first + 1].look;
    const ogre::SquadSpan span{
        .from = keys[at.first].look,
        .from_tangent = look_tangent(keys, at.first),
        .finish_tangent = look_tangent(keys, at.first + 1),
        .finish = keys[at.first + 1].look,
    };
    return ogre::quat_squad(at.blend, span, ogre::Arc::kShortest);
}

// Khoá dời theo hướng nhìn: vị trí trừ trục z đã chuẩn hoá nhân lượng dời (camera OGRE nhìn theo
// -z của nó). Khác gốc: Vector3::normalise bỏ qua vector ngắn hơn 1e-8, normalize_vec3 bỏ qua vector
// 0; trục z của một phép xoay không rơi vào cả hai.
void push_key(CameraKey& key, float amount) noexcept {
    const ogre::Vec3 axis = ogre::normalize_vec3(ogre::quat_z_axis(key.look));
    key.eye = {
        .x = key.eye.x - (axis.x * amount),
        .y = key.eye.y - (axis.y * amount),
        .z = key.eye.z - (axis.z * amount),
    };
}

// AnimationState::setTimePosition của state không lặp: kẹp vào [0, length].
[[nodiscard]] constexpr float clamped_time(float time, float length) noexcept {
    if (time < 0.0F) return 0.0F;
    return time > length ? length : time;
}

} // namespace

CharCamera::CharCamera() noexcept {
    const std::span<Track> tracks(tracks_);
    Track& create = tracks[0];
    create.length = kCreateLength;
    create.key_count = 2;
    create.keys[0] = CameraKey{.time = 0.0F, .eye = kMaleEye, .look = kCreateLook};
    create.keys[1] = CameraKey{.time = kCreateLength, .eye = kCreateEye, .look = kCreateLook};
    Track& first = tracks[1];
    first.length = kRole0To1Length;
    first.keys = {rest_key(0.0F, kSlot0Eye), kMid0To1, rest_key(kRole0To1Length, kSlot1Eye)};
    Track& second = tracks[2];
    second.length = kRole1To2Length;
    second.keys = {rest_key(0.0F, kSlot1Eye), kMid1To2, rest_key(kRole1To2Length, kSlot2Eye)};
    Track& third = tracks[3];
    third.length = kRole2To0Length;
    third.keys = {rest_key(0.0F, kSlot2Eye), kMid2To0, rest_key(kRole2To0Length, kSlot0Eye)};
    for (Track& track : tracks.subspan(1)) {
        track.is_spline = true;
        track.key_count = 3;
    }
}

void CharCamera::activate_only(std::size_t index) noexcept {
    const std::span<Track> tracks(tracks_);
    for (std::size_t at = 0; at < tracks.size(); ++at)
        tracks[at].is_active = at == index;
}

void CharCamera::enable(std::size_t index) noexcept {
    shown_ = index;
}

void CharCamera::set_mode(CameraMode mode) noexcept {
    if (mode == CameraMode::kSelect) return;
    const bool is_female = mode == CameraMode::kCreateFemale;
    is_held_ = true;
    is_select_ = false;
    activate_only(0);
    is_forward_ = is_female;
    enable(0);
    Track& track = tracks_.front();
    track.time = is_female ? track.length : 0.0F;
    last_played_.reset();
}

void CharCamera::play(const TrackPlay& play) noexcept {
    const auto index = static_cast<std::size_t>(play.track);
    is_select_ = index != 0;
    is_held_ = play.is_held;
    activate_only(index);
    Track& track = std::span<Track>(tracks_)[index];
    is_forward_ = play.is_forward;
    enable(index);
    if (play.is_held) {
        track.time = play.is_forward ? track.length : 0.0F;
        last_played_.reset();
        return;
    }
    if (last_played_ == index) return;
    float from_start = 0.0F;
    if (!(0.0F > play.time)) from_start = play.time > track.length ? track.length : play.time;
    const float wanted = play.is_forward ? from_start + 0.0F : track.length - from_start;
    track.time = clamped_time(wanted, track.length);
    last_played_ = index;
}

void CharCamera::set_zoom_speed(float speed) noexcept {
    zoom_speed_ = speed;
}

void CharCamera::zoom_create(float elapsed_ms) noexcept {
    for (Track& track : tracks_) {
        if (!track.is_active) continue;
        const float before = create_zoom_;
        create_zoom_ = (elapsed_ms * zoom_speed_) + before;
        if (create_zoom_ > kCreateZoomLimit) create_zoom_ = kCreateZoomLimit;
        if (0.0F > create_zoom_) create_zoom_ = 0.0F;
        const float moved = create_zoom_ - before;
        const std::span<CameraKey> keys = std::span(track.keys).first(track.key_count);
        push_key(keys.back(), moved);
        push_key(keys.front(), moved);
    }
}

void CharCamera::zoom_select(float elapsed_ms) noexcept {
    is_transitioning_ = false;
    for (const Track& track : std::span(tracks_).subspan(1)) {
        if (track.is_active && track.length > track.time && track.time > 0.0F) is_transitioning_ = true;
    }
    if (zoom_speed_ == 0.0F) return;
    const float before = select_zoom_;
    select_zoom_ = (elapsed_ms * zoom_speed_) + before;
    if (select_zoom_ > kSelectZoomLimit) select_zoom_ = kSelectZoomLimit;
    if (kSelectZoomFloor > select_zoom_) select_zoom_ = kSelectZoomFloor;
    const float moved = select_zoom_ - before;
    if (moved == 0.0F) return;
    for (Track& track : std::span(tracks_).subspan(1)) {
        const std::span<CameraKey> keys = std::span(track.keys).first(track.key_count);
        push_key(keys.front(), moved);
        push_key(keys.back(), moved);
    }
}

void CharCamera::update(std::uint32_t now_ms) noexcept {
    // Khung nạp dài không được hất camera cả mét. Lần đầu last_ms_ là 0, hiệu là tuổi tiến trình.
    constexpr float kZoomStepMs = 50.0F;
    float elapsed_ms = static_cast<float>(now_ms - last_ms_);
    if (elapsed_ms > kZoomStepMs) elapsed_ms = kZoomStepMs;
    if (is_select_) {
        zoom_select(elapsed_ms);
    } else {
        zoom_create(elapsed_ms);
    }
    last_ms_ = now_ms;
}

void CharCamera::advance(float seconds) noexcept {
    if (is_held_) return;
    for (Track& track : tracks_) {
        if (!track.is_active) continue;
        const float step = is_forward_ ? seconds : -seconds;
        track.time = clamped_time(track.time + step, track.length);
    }
}

bool CharCamera::is_transitioning() const noexcept {
    return is_transitioning_;
}

std::optional<TrackPose> CharCamera::pose() const noexcept {
    if (!shown_) return std::nullopt;
    const Track& track = std::span<const Track>(tracks_)[*shown_];
    const Keys keys = std::span(track.keys).first(track.key_count);
    const Segment at = segment_at(keys, Moment{.length = track.length, .time = track.time});
    const CameraKey& from = keys[at.first];
    if (at.blend == 0.0F) return TrackPose{.eye = from.eye, .look = from.look};
    if (track.is_spline) return TrackPose{.eye = spline_eye(keys, at), .look = spline_look(keys, at)};
    const CameraKey& finish = keys[at.second];
    const ogre::Vec3 travelled = ogre::scale_vec3(ogre::sub_vec3(finish.eye, from.eye), at.blend);
    return TrackPose{
        .eye = ogre::add_vec3(from.eye, travelled),
        .look = ogre::quat_nlerp(at.blend, from.look, finish.look, ogre::Arc::kShortest),
    };
}

} // namespace game::control
