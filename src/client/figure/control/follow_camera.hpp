#pragma once
// Camera cảnh của client 2026: CCamera_Scene của Render.dll cùng các hàm Camera_* của
// CRenderSystem, đọc từ mã máy bản 3.71. Địa chỉ từng hàm, bảng hằng và các chỗ khác bản 2008
// nằm ở docs/CAMERA-2026.md.
// - Mắt quanh điểm nhìn theo khoảng cách, pitch (âm là nhìn xuống) và hướng (_GetEyePos); điểm
//   nhìn là chân nhân vật cộng add_height nhân tỉ lệ đứng của địa hình.
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
// 0x1800041a6) và chưa có rung của kỹ năng (AddOneVib).

#include "control/ground.hpp"
#include "ogre/vec3.hpp"

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
};

// Vị trí mắt quanh điểm nhìn, như _GetEyePos: pitch âm là mắt ở trên.
struct EyeArm {
    float distance = 0.0F;
    float direction = 0.0F;
    float pitch = 0.0F;
};

[[nodiscard]] Vec3 eye_position(Vec3 target, EyeArm arm) noexcept;

} // namespace game::control
