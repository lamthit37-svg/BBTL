// Ba thuật toán kính trong client gốc, centimet, không đụng Win32.
// spring_look_at là SimpleMapCamera: lò xo 4.6, chiều nghỉ 20, ngưỡng 0.05.
// walk_direction là CalcKeyMoveDir: hướng đất từ yaw, pitch không tham gia.
// Đích đi = hướng * 1000, đúng CalcMoveEnd. effect_shake là EffectCamera.
// ArcBall, EditorCamera và DummyClient không đưa vào: công cụ và client thử.
// Khác gốc: lệch mới bằng 0 thì chốt đích; swing hoặc last_time bằng 0 thì đứng yên.
#pragma once

#include "camera/basis.hpp"

#include <cstdint>

namespace game::camera {

struct LookPair {
    math::Point3 current{};
    math::Point3 target{};
};

// Look tiến về đích. Đảo hướng hoặc đi quá thì chốt đúng đích.
[[nodiscard]] math::Point3 spring_look_at(LookPair ends, float delta_seconds) noexcept;

enum class WalkDir : std::uint8_t {
    kFront,
    kRightFront,
    kRight,
    kRightBack,
    kBack,
    kLeftBack,
    kLeft,
    kLeftFront,
};

// Hướng đơn vị trên mặt đất. Lấy từ basis_of, không tính sin/cos lần hai.
[[nodiscard]] math::Vector3 walk_direction(WalkDir direction, float camera_yaw) noexcept;

struct WalkQuery {
    WalkDir direction = WalkDir::kFront;
    float camera_yaw = 0.0F;
    math::Point3 start{};
};

// Điểm đến cách điểm đứng 1000 cm theo hướng đi.
[[nodiscard]] math::Point3 walk_destination(WalkQuery query) noexcept;

struct Shake {
    math::Vector3 swing;
    float last_time = 1.0F;
    float attenuation = 0.0F;
    float state_time = 0.0F;
    float delta_seconds = 0.0F;
    math::Point3 node{};
    math::Point3 eye{};
    math::Point3 look_at{};
};

struct ShakeResult {
    math::Point3 eye{};
    math::Point3 look_at{};
};

// Cùng vận tốc cho mắt và đích. Giữa 25% và 75% thì đảo.
[[nodiscard]] ShakeResult effect_shake(const Shake& shake) noexcept;

} // namespace game::camera
