#pragma once
// Camera chọn và tạo nhân vật của client 2026: bản port của CCamera_CharSel (Render.dll, hàm dựng
// 0x180001b30, vtable 0x1802bbc58). Lớp gốc giữ một quỹ đạo thành viên (nhìn (0, 80, 0), pitch −10
// độ, khoảng cách 500, hướng pi) nhưng Update của nó (0x1800031a0) chỉ đặt mặt cắt xa: thứ đang vẽ
// là một SceneNode chạy theo bốn animation dựng ở 0x180001dc0, camera gắn vào node đó.
// - "CameraTrack" (0,5 giây, tuyến tính): khoá đầu là mắt của người mẫu nam, khoá cuối của nữ. Màn
//   tạo chạy xuôi khi chọn nữ, chạy ngược khi chọn nam (Game.exe 0x140641210).
// - Role0To1 (2 giây), Role1To2 (2,5 giây), Role2To0 (2 giây), spline ba khoá: đoạn chạy giữa ba ô
//   của bảng chọn (Game.exe 0x14063c480).
// OGRE của client áp animation cảnh từng state một, state nào cũng đặt lại node trước khi áp
// (SceneManager::_applySceneAnimations, OgreMain.dll 0x18016e340), và setEnabled(true) đưa state về
// cuối danh sách: tư thế đang vẽ là của track được bật gần nhất. Lớp gốc không tắt state nào.
// Phóng (0x180002b30): màn tạo dời mắt tới 400 cm theo hướng nhìn, bảng chọn tới 100 cm, bằng cách
// dời khoá đầu và khoá cuối của track; lượng phóng sống suốt đời camera, vào lại màn không đặt lại.
// FOV dọc 65 độ do 0x1800027a0 đặt mỗi lần đổi chế độ. Chân ba ô ghi ở Game.exe 0x14063d97a.
// Khác gốc: đồng hồ là số mili giây bên gọi đưa (bản gốc TdGetTimeTickCountSafe); ô +0x6c (ô đích,
// chỉ ghi không đọc) và ô +0x70 (luôn 1) không giữ.
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::control {

[[nodiscard]] constexpr float bits(std::uint32_t pattern) noexcept {
    return std::bit_cast<float>(pattern);
}

// Quỹ đạo trong thành viên CCamera. Không phải tư thế Ogre lúc đang chọn nhân vật.
inline constexpr float kCharLookX = 0.0F;
inline constexpr float kCharLookY = bits(0x42A00000U);
inline constexpr float kCharLookZ = 0.0F;
inline constexpr float kCharPitch = bits(0xBE32B8C2U);
inline constexpr float kCharDistance = bits(0x43FA0000U);
inline constexpr float kCharDirection = bits(0x40490FDBU);
inline constexpr float kCharFar = bits(0x47C35000U);

// Cảnh của bảng chọn và bảng tạo (Scene_Load -2, "tl3chuangjian.Scene").
inline constexpr std::string_view kRoleScene = "tl3chuangjian";

// Góc nhìn dọc do 0x1800027a0 đặt trước khi tua track. Mặt xa do CharSel::Update.
inline constexpr float kRoleFov = bits(0x42820000U);
inline constexpr float kRoleNear = 5.0F;
inline constexpr float kRoleFar = kCharFar;

// Hướng nghỉ của ba ô: cùng một quaternion (w x y z trên đĩa, đây xếp x y z w).
inline constexpr ogre::Quat kRoleLook{
    .x = bits(0xBD24CF8DU),
    .y = bits(0x399FFDBFU),
    .z = bits(0x37565DA8U),
    .w = bits(0x3F7FCEFBU),
};

// Khoá cuối của CameraTrack (0,5 giây): mắt và hướng nhìn người mẫu nữ ở màn tạo.
inline constexpr ogre::Vec3 kCreateEye{
    .x = bits(0x444D83C7U),
    .y = bits(0x44A36C29U),
    .z = bits(0x4567C4A4U),
};
inline constexpr ogre::Quat kCreateLook{
    .x = bits(0xBD349DB1U),
    .y = bits(0x3B779F33U),
    .z = bits(0x392EE45AU),
    .w = bits(0x3F7FC07FU),
};

// Người mẫu của màn tạo (Game.exe 0x140641bd0 ghi chỗ đứng, 0x140641e60 dựng): hai giới đứng cùng
// một chỗ, hướng 0, tỉ lệ 1,5.
inline constexpr ogre::Vec3 kCreateFeet{
    .x = bits(0x444C8000U),
    .y = bits(0x44850000U),
    .z = bits(0x453D9000U),
};
inline constexpr float kCreateScale = bits(0x3FC00000U);

// Mắt ở tư thế nghỉ của track và chân nhân vật của cùng ô, centimet.
struct RolePlace {
    ogre::Vec3 eye;
    ogre::Vec3 feet;
};

inline constexpr std::array<RolePlace, 3> kRolePlaces{{
    {
        .eye = {.x = bits(0x4447470AU), .y = bits(0x44A42BD7U), .z = bits(0x44B018F6U)},
        .feet = {.x = bits(0x4447224EU), .y = bits(0x448F4000U), .z = bits(0x448475C3U)},
    },
    {
        .eye = {.x = bits(0xC3908646U), .y = bits(0x44A42BD7U), .z = bits(0x44B00BD7U)},
        .feet = {.x = bits(0xC390B2F2U), .y = bits(0x448E6000U), .z = bits(0x4484847BU)},
    },
    {
        .eye = {.x = bits(0x44EC5B85U), .y = bits(0x44A42BD7U), .z = bits(0x44B00BD7U)},
        .feet = {.x = bits(0x44EC6429U), .y = bits(0x448E6000U), .z = bits(0x4484FEB8U)},
    },
}};

// Ô ngoài 0..2 về ô đầu, như nhánh r9 = 1 khi chỉ số chọn không nằm trong 0..2.
[[nodiscard]] inline const RolePlace& role_place(std::uint8_t slot) noexcept {
    if (slot == 1) return kRolePlaces[1];
    if (slot == 2) return kRolePlaces[2];
    return kRolePlaces[0];
}

struct CharSight {
    float eye_x = 0.0F;
    float eye_y = 0.0F;
    float eye_z = 0.0F;
    float target_x = 0.0F;
    float target_y = 0.0F;
    float target_z = 0.0F;
};

// Mắt của quỹ đạo thành viên. pitch dương ngẩng lên. Không dùng làm camera đang vẽ.
[[nodiscard]] inline CharSight char_sel_sight() noexcept {
    const float rise = kCharDistance * std::sin(-kCharPitch);
    const float reach = kCharDistance * std::cos(-kCharPitch);
    const float across = -reach * std::sin(kCharDirection);
    const float depth = -reach * std::cos(kCharDirection);
    CharSight sight;
    sight.eye_x = kCharLookX + across;
    sight.eye_y = kCharLookY + rise;
    sight.eye_z = kCharLookZ + depth;
    sight.target_x = kCharLookX;
    sight.target_y = kCharLookY;
    sight.target_z = kCharLookZ;
    return sight;
}

// Mẫu bit trên đĩa không chuẩn hoá lại: Role0To1 lệch đơn vị khoảng 1,2e-4.
inline constexpr float kRoleLookNorm = ogre::quat_dot(kRoleLook, kRoleLook);
inline constexpr float kCreateLookNorm = ogre::quat_dot(kCreateLook, kCreateLook);
static_assert(kRoleLookNorm > 0.999F && kRoleLookNorm < 1.001F);
static_assert(kCreateLookNorm > 0.999F && kCreateLookNorm < 1.001F);

// Bốn track theo thứ tự 0x180001dc0 dựng; số là chỉ số mà Game.exe đưa cho 0x1800025e0.
enum class CameraTrack : std::uint8_t { kCreate, kRole0To1, kRole1To2, kRole2To0 };
inline constexpr std::size_t kCameraTrackCount = 4;
inline constexpr std::size_t kCameraKeyLimit = 3;

// Chế độ Game.exe đưa cho 0x1800027a0: 1 và 2 là màn tạo (giới + 1), 3 là bảng chọn.
enum class CameraMode : std::uint8_t { kCreateFemale = 1, kCreateMale = 2, kSelect = 3 };

// Một khoá của NodeAnimationTrack: thời điểm (giây), mắt và hướng nhìn.
struct CameraKey {
    float time = 0.0F;
    ogre::Vec3 eye;
    ogre::Quat look;
};

// Đối số của 0x1800025e0. time âm: chạy từ đầu chiều đang đi, trừ khi track này vừa chạy (lúc đó
// chỉ đổi chiều). time không âm: nhảy tới thời điểm đó tính từ đầu chiều đang đi.
struct TrackPlay {
    bool is_forward = true;
    // Giữ: nhảy thẳng tới cuối chiều đang đi và đứng yên.
    bool is_held = false;
    CameraTrack track = CameraTrack::kCreate;
    float time = -1.0F;
};

struct TrackPose {
    ogre::Vec3 eye;
    ogre::Quat look;
};

class CharCamera {
public:
    CharCamera() noexcept;

    // 0x1800027a0. Màn tạo: giữ ở khoá cuối (nữ) hay khoá đầu (nam) của CameraTrack. Bảng chọn:
    // không đụng track nào.
    void set_mode(CameraMode mode) noexcept;
    // 0x1800025e0.
    void play(const TrackPlay& play) noexcept;
    // 0x180002b20: đơn vị phóng mỗi mili giây, âm là lùi ra, 0 là thôi.
    void set_zoom_speed(float speed) noexcept;
    // 0x180002b30, mỗi nhịp của thủ tục: cờ đang chạy giữa hai ô và lượng phóng. now_ms không lùi
    // (tràn 32 bit thì quay vòng như bản gốc).
    void update(std::uint32_t now_ms) noexcept;
    // frameStarted (0x180003410): cộng thời gian khung vào track đang chạy, O(1).
    void advance(float seconds) noexcept;
    // 0x180001ce0: bảng chọn đang chạy giữa hai ô.
    [[nodiscard]] bool is_transitioning() const noexcept;
    // Tư thế OGRE áp lên node: của track được bật gần nhất; chưa bật track nào thì không có.
    [[nodiscard]] std::optional<TrackPose> pose() const noexcept;

private:
    struct Track {
        float length = 0.0F;
        bool is_spline = false;
        std::uint8_t key_count = 0;
        std::array<CameraKey, kCameraKeyLimit> keys{};
        // Byte đầu của ô 64 byte trong vector +0x50 và thời điểm của AnimationState.
        bool is_active = false;
        float time = 0.0F;
    };

    void activate_only(std::size_t index) noexcept;
    void enable(std::size_t index) noexcept;
    void zoom_create(float elapsed_ms) noexcept;
    void zoom_select(float elapsed_ms) noexcept;

    std::array<Track, kCameraTrackCount> tracks_{};
    // +0x49 chiều chạy, +0x4a giữ, +0x71 chế độ bảng chọn, +0x7c đang chạy giữa hai ô.
    bool is_forward_ = false;
    bool is_held_ = false;
    bool is_select_ = false;
    bool is_transitioning_ = false;
    // +0x74 nhịp trước, +0x80 và +0x88 lượng phóng của bảng chọn và màn tạo, +0x8c tốc độ phóng.
    std::uint32_t last_ms_ = 0;
    float select_zoom_ = 0.1F;
    float create_zoom_ = 0.0F;
    float zoom_speed_ = 0.0F;
    // +0x90 track vừa chạy; state được bật gần nhất (cuối danh sách của OGRE).
    std::optional<std::size_t> last_played_;
    std::optional<std::size_t> shown_;
};

} // namespace game::control
