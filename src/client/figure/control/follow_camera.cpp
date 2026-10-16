/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/control/follow_camera.cpp
 *  PHÂN HỆ   : Figure / Control / Follow Camera
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Camera cảnh của client 2026; luật và nguồn ở follow_camera.hpp. Mỗi hàm
 *    dưới ghi địa chỉ hàm tương ứng trong Render.dll bản 3.71 (gốc
 *    0x180000000).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "control/follow_camera.hpp"

#include "control/ground.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>

namespace game::control {
namespace {

// TDU_PI là hằng double; mọi phép đổi độ sang radian của bản gốc nhân chia bằng double rồi mới
// gán vào FLOAT.
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng TDU_PI của bản gốc (HP-07)
constexpr double kPi = 3.1415926535;
// TDU_PI / 2 như bản gốc lưu (0x1802bc008).
constexpr double kHalfPi = 1.57079632675;
// MIN_ANGLE (0x1803b0204) và STEP_ANGLE (0x1803b0208): 0,1 và 1 độ.
constexpr float kMinAngle = 0.00174532924F;
constexpr float kStepAngle = 0.0174532924F;
// Camera_SetPitch chỉ nhận pitch nằm hẳn trong khoảng này: 89 độ (0x1802c2e50).
constexpr double kPitchLimit = 1.5533430342305554;
// Bước zoom của Camera_SetZoom(BOOL, INT) (0x1802c2e4c).
constexpr float kZoomSpeed = 0.05F;
// Khoảng cách thế Camera_SetZoom dùng khi phép nội suy ra số âm (0x1802c2e58).
constexpr float kFallbackDistance = 17.5F;
// Hướng và khoảng cách lúc Render.dll dựng CCamera_Scene (0x1802c2d8c, 0x1803b01f0); chưa có địa
// hình thì GetScale trả 100 cho cả ba trục.
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng 3.1416 của bản gốc (HP-07)
constexpr float kBuiltDirection = 3.1416F;
constexpr float kBuiltDistance = 17.5F;
constexpr float kBareScale = 100.0F;
// __PI của GameUtil.h: hướng lúc vào cảnh (Game.exe 0x140b0dde8).
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng __PI của bản gốc (HP-07)
constexpr float kEnterDirection = 3.1415F;
// Pitch lúc gần nhất của công thức vào cảnh, độ (Game.exe 0x140b79650).
constexpr double kNearPitchDegrees = 26.0;
// PI float mà Game.exe nhân khi đổi lại sang radian (0x140baea28).
constexpr float kFloatPi = std::numbers::pi_v<float>;
// kDistance: mắt trống thì nới 10 (0x1803b01f8), nới quá thì lùi 0,1; mắt vướng thì rút 1.
constexpr float kOpenStep = 10.0F;
constexpr float kOpenBack = 0.1F;
constexpr float kCloseStep = 1.0F;
// Camera_FOV ép chỉ có hiệu lực khi lớn hơn 0,1 và lệch góc của luật quá 0,01 (0x180003fc9).
constexpr float kFovFloor = 0.1F;
constexpr double kFovSlack = 0.01;

// Một lần thử mắt: mặt đất, điểm nhìn, hướng, bán kính quả cầu mắt và cách chữa đang dùng.
struct Probe {
    const Ground* ground = nullptr;
    Vec3 target;
    float direction = 0.0F;
    float radius = 0.0F;
    CameraFit fit = CameraFit::kPitch;
};

// Khoảng cách và pitch của một lần thử; hướng lấy ở Probe.
struct Try {
    float distance = 0.0F;
    float pitch = 0.0F;
};

[[nodiscard]] EyeArm arm_of(const Probe& probe, Try tried) noexcept {
    return EyeArm{.distance = tried.distance, .direction = probe.direction, .pitch = tried.pitch};
}

// _IsValidEye (0x180004c50): không lấy được ô quanh mắt thì cảnh thường coi là trống, cảnh sửa
// khoảng cách coi là vướng.
[[nodiscard]] bool is_clear(const Probe& probe, Try tried) noexcept {
    const Vec3 eye = eye_position(probe.target, arm_of(probe, tried));
    const EyeProbe found = probe.ground->probe_sphere(eye, probe.radius);
    if (found == EyeProbe::kNoPatch) return probe.fit == CameraFit::kPitch;
    return found == EyeProbe::kClear;
}

// Pitch mắt đang dùng và pitch người chơi muốn.
struct PitchPair {
    float now = 0.0F;
    float wanted = 0.0F;
};

// Mắt đang vướng: dốc thêm từng độ tới khi thoát hoặc tới sát thẳng đứng; hết vòng mà vẫn vướng
// thì trả pitch cuối (0x180004aa3).
[[nodiscard]] float lift_pitch(const Probe& probe, Try stuck) noexcept {
    const double lowest = -(kHalfPi - static_cast<double>(kMinAngle));
    Try tried{.distance = stuck.distance, .pitch = stuck.pitch - kStepAngle};
    while (static_cast<double>(tried.pitch) > lowest && !is_clear(probe, tried)) {
        tried.pitch -= kStepAngle;
    }
    return tried.pitch;
}

// _GetValidPitch (0x1800048c0): mắt ổn thì tiến một độ về pitch muốn, bước đó vướng thì đứng yên;
// mắt vướng thì dốc thêm.
[[nodiscard]] float valid_pitch(const Probe& probe, float distance, PitchPair pitch) noexcept {
    const Try now{.distance = distance, .pitch = pitch.now};
    if (!is_clear(probe, now)) return lift_pitch(probe, now);
    const float gap = std::fabs(pitch.wanted - pitch.now);
    if (kMinAngle >= gap) return pitch.wanted;
    const float stepped = std::min(kStepAngle + pitch.now, pitch.wanted);
    const bool is_step_clear = is_clear(probe, Try{.distance = distance, .pitch = stepped});
    return is_step_clear ? stepped : pitch.now;
}

// Rút khoảng cách từng bước tới khi mắt trống; chạm sàn thì dừng ở sàn mà không thử nữa.
struct Shrink {
    float start = 0.0F;
    float step = 0.0F;
    float lowest = 0.0F;
    float pitch = 0.0F;
};

[[nodiscard]] float pull_in(const Probe& probe, Shrink shrink) noexcept {
    Try tried{.distance = shrink.start, .pitch = shrink.pitch};
    while (tried.distance > shrink.lowest && !is_clear(probe, tried)) {
        tried.distance -= shrink.step;
    }
    return std::max(tried.distance, shrink.lowest);
}

// Khoảng cách thế giới đang có, khoảng cách người chơi muốn và sàn (gần nhất nhân tỉ lệ đứng).
struct Reach {
    float now = 0.0F;
    float wanted = 0.0F;
    float lowest = 0.0F;
};

// Nhánh sửa khoảng cách của Update (0x180004540): mắt trống thì nới 10, trần là khoảng cách
// muốn, nới quá thì lùi 0,1; mắt vướng thì rút 1. Khoảng cách đã ở sàn thì trả nguyên.
[[nodiscard]] float fit_distance(const Probe& probe, Reach reach, float pitch) noexcept {
    const bool is_now_clear = is_clear(probe, Try{.distance = reach.now, .pitch = pitch});
    const float grown = std::min(kOpenStep + reach.now, reach.wanted);
    const float start = is_now_clear ? grown : reach.now;
    if (!(start > reach.lowest)) return start;
    Shrink shrink;
    shrink.start = start;
    shrink.step = is_now_clear ? kOpenBack : kCloseStep;
    shrink.lowest = reach.lowest;
    shrink.pitch = pitch;
    return pull_in(probe, shrink);
}

} // namespace

// _GetEyePos (đoạn đầu của 0x1800048c0): y = d sin(-p), r = d cos(-p), x = -r sin(hướng),
// z = -r cos(hướng), cộng điểm nhìn sau cùng.
Vec3 eye_position(Vec3 target, EyeArm arm) noexcept {
    const float tilt = -arm.pitch;
    const float reach = std::cos(tilt) * arm.distance;
    const float along_x = -(std::sin(arm.direction) * reach);
    const float rise = std::sin(tilt) * arm.distance;
    const float along_z = -(std::cos(arm.direction) * reach);
    return Vec3{.x = along_x + target.x, .y = rise + target.y, .z = along_z + target.z};
}

// CRenderSystem dựng camera cảnh (0x180026115): pitch gốc = -Camera_Pitch đổi sang radian, cũng
// là pitch đang dùng và pitch muốn; khoảng cách 17,5 nhân tỉ lệ khi chưa có địa hình.
FollowCamera::FollowCamera(CameraRules rules) noexcept
    : rules_(rules), distance_(kBuiltDistance * kBareScale), direction_(kBuiltDirection) {
    const auto degrees = static_cast<double>(-rules.pitch_degrees);
    base_pitch_ = static_cast<float>(degrees * kPi / 180.0);
    pitch_ = base_pitch_;
    wanted_pitch_ = base_pitch_;
    pose_.fov_degrees = rules.fov_degrees;
    pose_.near_plane = rules.near_plane;
    pose_.far_plane = rules.far_plane;
}

void FollowCamera::enter(const Ground& ground, Vec3 foot, float zoom) noexcept {
    set_look_at(ground, foot);
    set_direction(ground, kEnterDirection);
    set_zoom(ground, zoom);
    const float base_degrees = base_pitch_ * 180.0F;
    const double spread = (static_cast<double>(base_degrees) / kPi) + kNearPitchDegrees;
    const double degrees = (spread * static_cast<double>(zoom)) - kNearPitchDegrees;
    set_pitch(ground, static_cast<float>(degrees) * kFloatPi / 180.0F);
}

// CCamera_Scene::SetLookAt (0x180003c10).
void FollowCamera::set_look_at(const Ground& ground, Vec3 foot) noexcept {
    const bool is_settled = kMinAngle > wanted_pitch_ - pitch_;
    if (foot == foot_ && is_settled) return;
    foot_ = foot;
    update(ground);
}

// Camera_SetZoom(FLOAT) (0x18002add0).
void FollowCamera::set_zoom(const Ground& ground, float zoom) noexcept {
    if (0.0F > zoom || zoom > 1.0F) return;
    const float span = rules_.max_distance - rules_.min_distance;
    float distance = (span * zoom) + rules_.min_distance;
    if (0.0F > distance) distance = kFallbackDistance;
    set_distance(ground, std::max(distance, rules_.min_distance));
}

// Camera_SetZoom(BOOL, INT) (0x18002ad30).
void FollowCamera::zoom_step(const Ground& ground, ZoomWay way, int multiple) noexcept {
    const float step = static_cast<float>(multiple) * kZoomSpeed;
    const float level = zoom(ground);
    const float closer = std::max(level - step, 0.0F);
    const float farther = std::min(level + step, 1.0F);
    set_zoom(ground, way == ZoomWay::kCloser ? closer : farther);
}

void FollowCamera::set_direction(const Ground& ground, float radians) noexcept {
    direction_ = radians;
    update(ground);
}

void FollowCamera::add_direction(const Ground& ground, float radians) noexcept {
    set_direction(ground, direction_ + radians);
}

// Camera_SetPitch (0x18002acd0): CCamera::SetPitch tự Update, rồi CRenderSystem Update lần nữa.
void FollowCamera::set_pitch(const Ground& ground, float radians) noexcept {
    const auto wide = static_cast<double>(radians);
    const bool is_inside = kPitchLimit > wide && wide > -kPitchLimit;
    if (!is_inside) return;
    wanted_pitch_ = radians;
    pitch_ = radians;
    update(ground);
    update(ground);
}

// Camera_GetZoom (0x18002ab20).
float FollowCamera::zoom(const Ground& ground) const noexcept {
    const float distance = distance_ / ground.vertical_scale();
    return (distance - rules_.min_distance) / (rules_.max_distance - rules_.min_distance);
}

// CCamera_Scene::SetDistance (0x1800038d0).
void FollowCamera::set_distance(const Ground& ground, float game_distance) noexcept {
    distance_ = ground.vertical_scale() * game_distance;
    if (rules_.fit == CameraFit::kDistance) settle_wanted(ground);
    update(ground);
}

// Nhánh cờ khác 0 của SetDistance (0x180003931): mắt trống ở khoảng cách mới thì đó là khoảng cách
// người chơi muốn; vướng thì lùi từng 0,1 tới sàn. Bản gốc so khoảng cách thế giới với
// Camera_MinDistance chưa nhân tỉ lệ trước khi lùi, giữ nguyên. Khác gốc: tỉ lệ đứng dưới 1 thì
// bản gốc còn dừng ở chính số chưa nhân đó; mọi cảnh có tỉ lệ 100 nên không tới được.
void FollowCamera::settle_wanted(const Ground& ground) noexcept {
    Probe probe;
    probe.ground = &ground;
    probe.target = look_point(ground);
    probe.direction = direction_;
    probe.radius = rules_.near_plane;
    probe.fit = rules_.fit;
    const bool is_now_clear = is_clear(probe, Try{.distance = distance_, .pitch = pitch_});
    if (is_now_clear) wanted_distance_ = distance_;
    if (is_now_clear || !(distance_ > rules_.min_distance)) return;
    Shrink shrink;
    shrink.start = distance_;
    shrink.step = kOpenBack;
    shrink.lowest = rules_.min_distance * ground.vertical_scale();
    shrink.pitch = pitch_;
    distance_ = pull_in(probe, shrink);
}

Vec3 FollowCamera::look_point(const Ground& ground) const noexcept {
    const float lift = ground.vertical_scale() * rules_.add_height;
    return Vec3{.x = foot_.x, .y = foot_.y + lift, .z = foot_.z};
}

float FollowCamera::fov() const noexcept {
    const auto asked = static_cast<double>(fov_override_);
    const auto usual = static_cast<double>(rules_.fov_degrees);
    const bool is_apart = asked > usual + kFovSlack || usual - kFovSlack > asked;
    return fov_override_ > kFovFloor && is_apart ? fov_override_ : rules_.fov_degrees;
}

// CCamera_Scene::Update (0x180003d00).
void FollowCamera::update(const Ground& ground) noexcept {
    Probe probe;
    probe.ground = &ground;
    probe.target = look_point(ground);
    probe.direction = direction_;
    probe.radius = rules_.near_plane;
    probe.fit = rules_.fit;
    const float lowest = rules_.min_distance * ground.vertical_scale();
    const Reach reach{.now = distance_, .wanted = wanted_distance_, .lowest = lowest};
    const PitchPair pitch{.now = pitch_, .wanted = wanted_pitch_};
    if (rules_.fit == CameraFit::kDistance) distance_ = fit_distance(probe, reach, pitch_);
    if (rules_.fit == CameraFit::kPitch) pitch_ = valid_pitch(probe, distance_, pitch);
    const Try settled{.distance = distance_, .pitch = pitch_};
    pose_.eye = eye_position(probe.target, arm_of(probe, settled));
    pose_.target = probe.target;
    pose_.eye.y += vib_.bias;
    pose_.target.y += vib_.bias;
    pose_.fov_degrees = fov();
    pose_.near_plane = rules_.near_plane;
    pose_.far_plane = rules_.far_plane;
}

void FollowCamera::tick_shake(const Ground& ground) noexcept {
    const bool was = vib_.active;
    static_cast<void>(vib_step(vib_));
    if (was) update(ground);
}

} // namespace game::control
