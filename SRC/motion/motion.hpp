#pragma once
// Đi trên mặt đất theo đơn vị game (một đơn vị là một ô lưới).
// advance là hàm đóng theo thời gian đã đi, giữ cho bài test đường gãy.
// move_tick là một khung của CObject_Character::Tick khi logic là MOVE: quãng = tốc độ * giây,
// dưới 0.01 thì không nhích, gần đích dưới 0.01 thì dừng, vượt đoạn thì đứng đúng đích.
// human_speed là Obj_Human::GetMoveSpeed: gốc 2800 / 1000, rồi nhân mode.
// verify_pos là Map::VerifyPos: âm thì 0, quá cạnh thì cạnh trừ 0.1.
// face_angle là TDU_GetYAngle. Khác gốc: chưa có vùng cấm và file nav, nên không phản xạ bước.

#include "core/ground_point.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::motion {

using core::GroundPoint;
using Seconds = std::chrono::duration<float>;

// Kết quả đi được một quãng: vị trí, chỉ số điểm kế tiếp trong path, và đã tới điểm cuối chưa.
struct Progress {
    GroundPoint position;
    std::size_t next = 0;
    bool arrived = false;

    bool operator==(const Progress&) const = default;
};

// Mode tốc độ của người. Đi bộ là gốc, chạy là 1.5, khập khiễng 0.5, nước rút 5.
enum class MoveMode : std::uint8_t { kWalk, kHobble, kRun, kSprint };

// Một lượt tick: chỗ đứng, đích, tốc độ đơn vị game mỗi giây, và số giây của khung.
struct MoveAsk {
    GroundPoint here;
    GroundPoint target;
    float speed = 0.0F;
    float seconds = 0.0F;
};

// Chỗ đứng sau một khung, hướng mặt, đã nhích chưa, và đã tới đích chưa.
struct MoveStep {
    GroundPoint position;
    float facing = 0.0F;
    bool moved = false;
    bool arrived = false;
};

// Cạnh bản đồ theo đơn vị game, cùng m_CX và m_CZ.
struct MapLimit {
    float width = 0.0F;
    float depth = 0.0F;
};

// Khoảng cách giữa hai điểm; hai tham số cùng vai nên không phân biệt thứ tự.
[[nodiscard]] float distance(GroundPoint left, GroundPoint right);

// Tổng chiều dài từ from qua mọi điểm của path.
[[nodiscard]] float path_length(GroundPoint from, std::span<const GroundPoint> path);

// Vị trí sau elapsed khi đi dọc path từ from với speed đơn vị mỗi giây. speed hay elapsed không
// dương thì đứng yên ở from; path rỗng thì coi như đã tới.
[[nodiscard]] Progress advance(GroundPoint from, std::span<const GroundPoint> path, float speed, Seconds elapsed);

// Tốc độ người theo mode, đơn vị game mỗi giây.
[[nodiscard]] float human_speed(MoveMode mode) noexcept;

// Góc mặt từ start tới toward. 0 nhìn +z, π/2 nhìn +x.
[[nodiscard]] float face_angle(GroundPoint start, GroundPoint toward) noexcept;

// Một khung đi thẳng tới một đích.
[[nodiscard]] MoveStep move_tick(MoveAsk ask) noexcept;

// Kéo điểm vào trong bản đồ.
[[nodiscard]] GroundPoint verify_pos(GroundPoint point, MapLimit limit) noexcept;

} // namespace game::motion
