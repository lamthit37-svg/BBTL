/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/control/follow_camera.hpp
 *  PHÂN HỆ   : Figure / Control / Follow Camera
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Camera cảnh của client 2026: CCamera_Scene của Render.dll cùng các hàm
 *    Camera_* của CRenderSystem, đọc từ mã máy bản 3.71. Địa chỉ từng hàm, bảng
 *    hằng và các chỗ khác bản 2008 nằm ở docs/CAMERA-2026.md.
 *  - Mắt quanh điểm nhìn theo khoảng cách, pitch (âm là nhìn xuống) và hướng
 *    (_GetEyePos); điểm nhìn là chân nhân vật cộng add_height nhân tỉ lệ đứng
 *    của địa hình.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// - Mỗi hàm đặt hướng, pitch, khoảng cách hay điểm nhìn gọi Update ngay như bản gốc, nên đều nhận
//   mặt đất: Update thử quả cầu mắt (bán kính là mặt gần) với địa hình.
// - CameraFit::kPitch, cảnh thường: mắt vướng thì dốc pitch từng độ; hết vướng thì mỗi lần Update
//   trả một độ về pitch người chơi đặt. CameraFit::kDistance, cảnh có dòng riêng trong
//   SpecialSceneCamera: giữ pitch, rút khoảng cách từng 1, mắt trống thì nới 10 tới khoảng cách
//   người chơi muốn.
// - Zoom là phần trong [0, 1] giữa khoảng cách gần nhất và xa nhất.
// Khác gốc: biến toàn cục của Render.dll (pitch muốn, khoảng cách muốn, khoảng zoom, FOV ép) thành
// thành viên; quả cầu mắt luôn lấy near_plane của luật (bản gốc đọc mặt gần mà lần Update trước
// vừa đặt, khác ở đúng lần đầu); chưa có độ cao mặt đi của công trình trong hộp ô (Render.dll
// 0x1800041a6). Rung của kỹ năng là AddOneVib: một lần mỗi khung ở tick_shake, không bước thêm
// mỗi lần setter gọi Update (set_look_at bỏ Update khi chân không đổi).

#pragma once

#include "control/ground.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <cstdint>

namespace game::control {

using ogre::Vec3;

// Cách Update chữa mắt vướng địa hình: cột 2 của SpecialSceneCamera bằng 0 là kPitch.
enum class CameraFit : std::uint8_t { kPitch, kDistance };

enum class ZoomWay : std::uint8_t { kCloser, kFarther };

// Số của một cảnh thường khi View_DefaultCamera = 1: Bin/System.cfg, dòng 1 của SpecialSceneCamera
// và hai cột mặt cắt của SceneDefineEx (CScene::EnterScene, Game.exe 0x1406c0c8d).
struct CameraRules {
    // Camera_MinDistance, Camera_MaxDistance: đơn vị game.
    float min_distance = 6.0F;
    float max_distance = 27.5F;
    // Camera_Pitch: góc nhìn xuống lúc dựng camera, độ.
    float pitch_degrees = 40.0F;
    // Camera_FOV: góc nhìn dọc, độ.
    float fov_degrees = 35.0F;
    // Điểm nhìn cao hơn chân nhân vật, đơn vị game (cột 10 của SpecialSceneCamera).
    float add_height = 1.5F;
    // Mặt cắt gần và xa, đơn vị thế giới (cột 17 và 16 của SceneDefineEx).
    float near_plane = 10.0F;
    float far_plane = 15000.0F;
    CameraFit fit = CameraFit::kPitch;
};

// Mắt, điểm nhìn và phép chiếu của một khung hình, trong toạ độ thế giới.
struct CameraPose {
    Vec3 eye;
    Vec3 target;
    float fov_degrees = 35.0F;
    float near_plane = 10.0F;
    float far_plane = 15000.0F;
};

// AddOneVib / _UpdateCurStatus của CCamera_Scene. range và step là centimet (cùng đơn vị mắt).
// Đang rung thì lần gọi sau bỏ qua. range, step không dương hoặc times bằng 0 thì bỏ.
struct Vib {
    float range = 0.0F;
    float step = 0.0F;
    std::uint32_t times = 0;
    float bias = 0.0F;
    float step_now = 0.0F;
    bool going_up = true;
    std::uint32_t done = 0;
    bool active = false;
};

constexpr void add_vib(Vib& vib, float range, float step, std::uint32_t times) noexcept {
    if (!(range > 0.0F) || !(step > 0.0F) || times == 0 || vib.active) return;
    vib.range = range;
    vib.step = step;
    vib.times = times;
    vib.bias = 0.0F;
    vib.step_now = step;
    vib.going_up = true;
    vib.done = 0;
    vib.active = true;
}

// Một nhịp Update. Trả độ lệch Y cộng vào mắt và điểm nhìn; 0 khi không rung. Hết số lần thì tắt
// và trả 0 (gốc đưa bias về 0 trong _SetStatus rồi return, không cộng ở khung đó).
[[nodiscard]] constexpr float vib_step(Vib& vib) noexcept {
    if (!vib.active) return 0.0F;
    if (vib.done == vib.times) {
        vib.active = false;
        vib.bias = 0.0F;
        return 0.0F;
    }
    vib.bias += vib.step_now;
    if (!vib.going_up && vib.bias > 0.0F) {
        ++vib.done;
        vib.going_up = true;
    } else if (vib.going_up && vib.bias < 0.0F) {
        vib.going_up = false;
    }
    if (vib.bias > vib.range) {
        vib.bias = vib.range;
        vib.step_now = -vib.step;
    } else if (vib.bias < -vib.range) {
        vib.bias = -vib.range;
        vib.step_now = vib.step;
    }
    return vib.bias;
}

// Camera_VibrateOneTime: AddOneVib(10, 8, 2).
inline constexpr float kVibRange = 10.0F;
inline constexpr float kVibStep = 8.0F;
inline constexpr std::uint32_t kVibTimes = 2;

// 13 nhịp có lệch rồi khung thứ 14 tắt (done == times ngay đầu nhịp). Số tính tay từ _UpdateCurStatus.
[[nodiscard]] constexpr bool vib_one_time() noexcept {
    Vib vib;
    add_vib(vib, kVibRange, kVibStep, kVibTimes);
    constexpr std::array<float, 14> kBias{8.0F, 10.0F, 2.0F, -6.0F, -10.0F, -2.0F, 6.0F, 10.0F, 2.0F, -6.0F, -10.0F, -2.0F,
        6.0F, 0.0F};
    for (const float want : kBias) {
        if (vib_step(vib) != want) return false;
    }
    return !vib.active && vib_step(vib) == 0.0F;
}

static_assert(vib_one_time());

class FollowCamera {
public:
    // Như Render.dll dựng CCamera_Scene: pitch gốc từ Camera_Pitch, hướng 3,1416, khoảng cách 17,5.
    explicit FollowCamera(CameraRules rules) noexcept;

    // Vào cảnh thường, như CGamePro_Enter (Game.exe 0x140643d13): nhìn vào chân nhân vật, hướng
    // 3,1415, zoom đã lưu, rồi pitch theo zoom: 26 độ lúc gần nhất tới pitch gốc lúc xa nhất.
    void enter(const Ground& ground, Vec3 foot, float zoom) noexcept;
    // Camera_SetLookAt: chân nhân vật không đổi và pitch đã về chỗ thì không Update.
    void set_look_at(const Ground& ground, Vec3 foot) noexcept;
    // Camera_SetZoom(FLOAT): ngoài [0, 1] thì bỏ qua.
    void set_zoom(const Ground& ground, float zoom) noexcept;
    // Camera_SetZoom(BOOL, INT): mỗi bước 0,05 nhân multiple, kẹp trong [0, 1].
    void zoom_step(const Ground& ground, ZoomWay way, int multiple) noexcept;
    // Camera_Direction và Camera_AddDirection, radian; không gói về [0, 2 pi).
    void set_direction(const Ground& ground, float radians) noexcept;
    void add_direction(const Ground& ground, float radians) noexcept;
    // Camera_SetPitch: chỉ nhận trong (-89, 89) độ; Update hai lần như bản gốc.
    void set_pitch(const Ground& ground, float radians) noexcept;
    // Camera_SetFOV: góc ép của cảnh; trùng fov_degrees của luật thì không đổi gì.
    void set_fov(float degrees) noexcept { fov_override_ = degrees; }

    // Camera_GetZoom: phần trong [0, 1] của khoảng cách đang có.
    [[nodiscard]] float zoom(const Ground& ground) const noexcept;
    [[nodiscard]] float direction() const noexcept { return direction_; }
    // Camera_GetPitch: pitch người chơi đặt, không phải pitch mắt đang bị địa hình ép.
    [[nodiscard]] float pitch() const noexcept { return wanted_pitch_; }
    [[nodiscard]] float eye_pitch() const noexcept { return pitch_; }
    // Pitch lúc dựng (thành viên +0x18 của CCamera), radian âm.
    [[nodiscard]] float base_pitch() const noexcept { return base_pitch_; }
    // Tư thế của lần Update gần nhất.
    [[nodiscard]] const CameraPose& pose() const noexcept { return pose_; }
    // OnAnimationShakeEvent: Camera_VibrateOneTime. Đang rung thì bỏ.
    void add_one_vib() noexcept { add_vib(vib_, kVibRange, kVibStep, kVibTimes); }
    // Một nhịp rung rồi Update nếu đang hoặc vừa rung, để pose mang độ lệch của khung này.
    void tick_shake(const Ground& ground) noexcept;

private:
    void set_distance(const Ground& ground, float game_distance) noexcept;
    void settle_wanted(const Ground& ground) noexcept;
    void update(const Ground& ground) noexcept;
    [[nodiscard]] Vec3 look_point(const Ground& ground) const noexcept;
    [[nodiscard]] float fov() const noexcept;

    CameraRules rules_;
    // Chân nhân vật, toạ độ thế giới.
    Vec3 foot_;
    // Âm là nhìn xuống.
    float pitch_ = 0.0F;
    float wanted_pitch_ = 0.0F;
    float base_pitch_ = 0.0F;
    // Đơn vị thế giới: khoảng cách game nhân tỉ lệ đứng, như m_fDistance.
    float distance_ = 0.0F;
    float wanted_distance_ = 1750.0F;
    float direction_ = 0.0F;
    float fov_override_ = 0.0F;
    CameraPose pose_;
    Vib vib_;
};

// Vị trí mắt quanh điểm nhìn, như _GetEyePos: pitch âm là mắt ở trên.
struct EyeArm {
    float distance = 0.0F;
    float direction = 0.0F;
    float pitch = 0.0F;
};

[[nodiscard]] Vec3 eye_position(Vec3 target, EyeArm arm) noexcept;

} // namespace game::control
