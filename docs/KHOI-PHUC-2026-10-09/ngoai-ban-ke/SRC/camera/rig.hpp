// Kính chơi ClientCamera. Thứ tự: lăn, chuột, bay, rồi mới tới nhân vật.
// Bay bước 40 mỗi lần gọi, không nhân delta. Lò xo occult 1000 cm/s, tia bước 10.
// Ma trận cuối là SetLookAt sau khi nâng look và kẹp mắt, không dựng lại Euler.
// Độ trễ 2 giây trước khi bung lò xo đang bị chú thích trong gốc: không thêm.
// step_opacity là UpdateRoleTransparent. Update gốc không gọi nó.
// Hàm probe null thì bỏ phép thử đó. Tia dài 0 thì giữ khoảng cách.
// expect_distance là 0 tới set_default; gốc để giá trị rác. Con trỏ trả bằng cờ.
#pragma once

#include "camera/basis.hpp"
#include "camera/lens.hpp"

#include <cstdint>
#include <optional>

namespace game::camera {

struct Planar {
    float x = 0.0F;
    float z = 0.0F;
};

struct WaterQuery {
    math::Point3 origin{};
    math::Vector3 direction;
    float reach = 0.0F;
};

struct SceneQuery {
    math::Point3 origin{};
    math::Vector3 direction;
};

struct Probe {
    void* user = nullptr;
    float (*ground)(void* user, Planar place) noexcept = nullptr;
    std::optional<float> (*water_height)(void* user, math::Point3 place) noexcept = nullptr;
    std::optional<math::Point3> (*water_ray)(
        void* user, const WaterQuery& query) noexcept = nullptr;
    std::optional<float> (*scene_ray)(void* user, const SceneQuery& query) noexcept = nullptr;
};

struct PointerInput {
    // lZ của DirectInput nhân độ nhạy (mặc định 1): một nấc là 120, không phải số nấc.
    std::int32_t wheel = 0;
    std::int32_t relative_x = 0;
    std::int32_t relative_y = 0;
    std::int32_t cursor_x = 0;
    std::int32_t cursor_y = 0;
    bool over_desktop = false;
    bool right_held = false;
    bool right_pressed = false;
    bool right_released = false;
    bool moved = false;
};

struct FlyKeys {
    bool forward = false;
    bool back = false;
    bool left = false;
    bool right = false;
};

struct Clock {
    float delta_seconds = 0.0F;
    std::uint32_t accum_ms = 0;
    std::uint32_t wall_ms = 0;
};

struct Subject {
    bool present = false;
    math::Point3 position{};
};

struct FrameInput {
    PointerInput pointer{};
    FlyKeys keys{};
    Clock clock{};
    Subject subject{};
    Probe probe{};
};

struct RigOutput {
    bool capture = false;
    bool release = false;
    bool warp = false;
    bool yaw_turned = false;
    std::int32_t warp_x = 0;
    std::int32_t warp_y = 0;
};

struct Rig {
    Euler euler{};
    Basis basis{};
    Lens lens{};
    float expect_distance = 0.0F;
    float height_scale = 1.0F;
    float role_opacity = 1.0F;
    std::uint32_t quake_start_ms = 0;
    std::uint32_t last_occult_ms = 0;
    std::int32_t locked_x = 0;
    std::int32_t locked_y = 0;
    bool is_fly = false;
    bool is_quaking = false;
    bool is_fading = false;
};

// z_far lưu 25600, ma trận chiếu vẫn đơn vị.
[[nodiscard]] Rig make_rig(std::uint32_t wall_ms) noexcept;
// Ghi euler rồi dựng mắt và ma trận nhìn.
void place(Rig& rig, const Euler& euler) noexcept;
// Góc 45, gần 20, nhìn (0, 500, 0), xa 660.
void set_default(Rig& rig, Viewport viewport, float z_far) noexcept;
// Fov theo độ, gần luôn là 20. Cũng gán expect bằng khoảng cách đang có, như SetFov.
void set_fov(Rig& rig, Viewport viewport, float degrees) noexcept;
// Đổi cỡ khung: chỉ dựng lại phép chiếu, không đụng expect.
void resize(Rig& rig, Viewport viewport) noexcept;
// Bắt đầu rung nếu chưa đang rung.
void play_quake(Rig& rig, std::uint32_t accum_ms) noexcept;
// Trong suốt, tốc độ 4 mỗi giây. Update gốc không gọi.
void step_opacity(Rig& rig, float delta_seconds) noexcept;
// Chuột, lăn và bay của Update, trước khi bám nhân vật.
[[nodiscard]] RigOutput steer(Rig& rig, const PointerInput& pointer, const FlyKeys& keys) noexcept;
// Bám nhân vật, occult, nâng điểm nhìn rồi SetLookAt. Đang bay thì không làm gì.
void settle(Rig& rig, const FrameInput& frame) noexcept;
// Cộng yaw. Cửa sổ dùng cho phím mũi tên; Update gốc không có phím này.
void add_yaw(Rig& rig, float radians) noexcept;
// Cộng khoảng cách mong muốn rồi kẹp [220, 1800], cùng trần của nấc lăn.
void add_expect(Rig& rig, float delta) noexcept;
// Yaw, pitch, roll và khoảng cách về mặc định của SetDefault. Giữ điểm nhìn.
void restore_aim(Rig& rig) noexcept;
// Một khung Update: steer rồi settle. Bay thì dừng trước nhân vật.
[[nodiscard]] RigOutput update(Rig& rig, const FrameInput& frame) noexcept;

} // namespace game::camera
