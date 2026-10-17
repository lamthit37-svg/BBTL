/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/motion/motion.hpp
 *  PHÂN HỆ   : Figure / Motion
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đi trên mặt đất theo đơn vị game. Tốc độ người, tốc độ cưỡi, và nhịp đi
 *    theo chủ của trân thú (AI_Pet 2008).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once
// Đi trên mặt đất theo đơn vị game (một đơn vị là một ô lưới).
// advance là hàm đóng theo thời gian đã đi, giữ cho bài test đường gãy.
// move_tick là một khung của CObject_Character::Tick khi logic là MOVE: quãng = tốc độ * giây,
// dưới 0.01 thì không nhích, gần đích dưới 0.01 thì dừng, vượt đoạn thì đứng đúng đích.
// human_speed là Obj_Human::GetMoveSpeed: gốc 2800 / 1000, rồi nhân mode.
// mounted_speed là chạy nhân (100 + phần trăm Exterior_Ride) / 100. 0 giữ nguyên chạy.
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

// Tốc độ cưỡi: chạy nhân (100 + phần trăm) / 100. Phần trăm 0 hoặc âm giữ nguyên tốc độ chạy.
// Nguồn phần trăm là Exterior_Ride cột Speed. Game.exe không tra bảng này lúc đi.
[[nodiscard]] float mounted_speed(float run, std::int32_t percent) noexcept;

// Góc mặt từ start tới toward. 0 nhìn +z, π/2 nhìn +x.
[[nodiscard]] float face_angle(GroundPoint start, GroundPoint toward) noexcept;

// Một khung đi thẳng tới một đích.
[[nodiscard]] MoveStep move_tick(MoveAsk ask) noexcept;

// Kéo điểm vào trong bản đồ.
[[nodiscard]] GroundPoint verify_pos(GroundPoint point, MapLimit limit) noexcept;

// Nhịp của trân thú. Khác MoveMode của người: gốc liệt kê HOBBLE, WALK, RUN, SPRINT.
// Nguồn: Obj_Pet::GetMoveSpeed và AI_Pet::ChangeMoveMode (server 2008).
enum class PetPace : std::uint8_t { kHobble, kWalk, kRun, kSprint };

// Một lượt xét khoảng cách tới chủ. owner_facing là getDir của chủ (radian).
// has_map thì điểm dịch chuyển đi qua verify_pos.
struct PetAsk {
    GroundPoint pet;
    GroundPoint owner;
    float owner_facing = 0.0F;
    PetPace pace = PetPace::kWalk;
    bool moving = false;
    bool can_move = true;
    bool has_map = false;
    MapLimit limit{};
};

// Lệnh của một lượt: nhịp mới, có dịch tức thì không, có bắt đầu đi không, và điểm đích.
// warp thì at là điểm đáp (z trừ cos). Còn lại at là điểm Baby_Go (z cộng cos), lệch 2 m.
struct PetOrder {
    PetPace pace = PetPace::kWalk;
    bool warp = false;
    bool go = false;
    GroundPoint at{};
};

// Mét mỗi giây. Gốc là move_speed của mẫu quái chia 1000, rồi nhân nhịp.
// Gốc không dương thì 0: thú không bước, vẫn dịch được khi quá xa.
[[nodiscard]] float pet_speed(float base_m_per_s, PetPace pace) noexcept;

// Điểm đáp khi dịch: cùng góc Baby_Go, nhưng z trừ 2*cos. Chưa kẹp vào bản đồ.
[[nodiscard]] GroundPoint pet_warp_at(GroundPoint owner, float owner_facing) noexcept;

// ChangeMoveMode chọn nhịp và điểm dịch. at còn lại là điểm Baby_Go.
// Khác gốc: không IsCanGo, không tìm đường; điểm đi tính lại mỗi lần gọi.
[[nodiscard]] PetOrder pet_follow(PetAsk ask) noexcept;

} // namespace game::motion
