/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/motion/jump.hpp
 *  PHÂN HỆ   : Figure / Motion / Jump
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nhảy theo CObject_Character::Jump của Game.exe 2026.
 *  - Màn chơi điền is_mounted. Đứng trên thú không bật vật lý.
 *  - Chưa gửi CGCharJump vì không có máy chủ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nhảy của nhân vật theo client 2026 (Game.exe 64 bit, tháo bằng TOOLS/port/pe_refs.py):
// - CObject_Character::Jump (0x1405ea2b0..0x1405ea4b8, bản thu gọn 0x1405ea4d0): từ chối khi chết,
//   bị khoá di chuyển, đang nhảy hay logic không cho. Đang chạy mà không cưỡi thì rand() % 4 == 0
//   chọn BASE_ACTION_N_JUMP_R (12), còn lại BASE_ACTION_N_JUMP_N (9). Cưỡi mà chạy luôn là 12.
//   Đứng yên luôn là 9. Đứng trên thú chỉ phát clip, không bật vật lý. Có bay thì vận tốc đứng 12
//   (hằng 0x140c1cdb8).
// - CObject_Phy::Tick (0x1405c5440): lần tick đầu chỉ ghi mốc giờ; dưới 10 ms thì bỏ qua và giữ mốc
//   cũ; còn lại cộng dồn thời gian bay d (ms), đặt vận tốc đứng vy = 15 * (1 - d / 900)^2 - 18 * (d
//   / 900)^2 (hằng 15, 18, 900 ở 0x140a57ccc, 0x140c151d8, 0x140c151dc) rồi dời vị trí một bước vy
//   * 0.01, không nhân số bước như bản 2008 (bản 2008 trọng lực 9.8 + 25 hay + 70 không còn trong
//   Game.exe). Vận tốc 12 của Jump vì thế bị ghi đè ngay ở tick đầu có bay.
// - CObject_Phy::SetMapPosition (theo ref Obj_Phy.cpp, bản 2026 cùng vị trí trong vtable): đang rơi
//   (vy < 0) mà mặt đất cao hơn thân thì đặt lên mặt đất và chạm đất (hết nhảy); đang lên mà mặt
//   đất cao hơn thì chỉ nâng thân lên mặt đất.
// Đơn vị độ cao là đơn vị game (thế giới = position.y + game * scale.y theo Axis_Trans).
// Khác gốc: không có máy chủ nên chưa gửi CGCharJump. Màn chơi điền is_mounted từ thú đang vẽ.
// Đội và bày hàng vẫn do người gọi đưa vào. rand() của gốc là số lăn để test được.

#pragma once

#include <cstdint>

namespace game::motion {

// Hành động cơ sở của cú nhảy (ENUM_BASE_ACTION).
enum class JumpAction : std::uint8_t { kJumpStand = 9, kJumpRun = 12 };

// Điều kiện ngoài của CAI_MySelf::IsCanJump và CObject_Character::Jump.
struct JumpGate {
    bool is_dead = false;
    bool is_move_limited = false;
    // Logic đang là ACTION, SKILL_SEND, DEAD hay STALL (gốc chỉ cho IDLE, MOVE, SKILL_GATHER,
    // SKILL_LEAD, ABILITY_ACTION).
    bool is_busy = false;
    bool is_moving = false;
    bool is_mounted = false;
    bool is_following_team = false;
    bool is_in_stall = false;
    // Đã biến hình (Get_ModelID() != INVALID_ID).
    bool is_transformed = false;
};

// Trạng thái vật lý của cú nhảy: đang bay, độ cao thân (đơn vị game), mốc tick, thời gian bay.
struct Jump {
    bool is_jumping = false;
    bool has_mark = false;
    float height = 0.0F;
    float speed = 0.0F;
    std::uint32_t mark_ms = 0;
    std::uint32_t flown_ms = 0;
};

// Vận tốc đứng của Jump trước tick đầu, và các hằng của CObject_Phy::Tick.
inline constexpr float kJumpSpeed = 12.0F;
inline constexpr std::uint32_t kPhyTickMs = 10;
inline constexpr float kPhyStep = 0.01F;
inline constexpr float kRiseScale = 15.0F;
inline constexpr float kFallScale = 18.0F;
inline constexpr float kFlightMs = 900.0F;

// Cho nhảy không (IsCanJump cùng các điều kiện đầu của Jump).
[[nodiscard]] bool can_jump(const Jump& jump, const JumpGate& gate) noexcept;

// Bắt đầu nhảy từ độ cao ground (đơn vị game); roll là rand() của gốc. Không nhảy được thì has_started
// là false và jump giữ nguyên.
struct JumpStart {
    bool has_started = false;
    JumpAction action = JumpAction::kJumpStand;
};
[[nodiscard]] JumpStart start_jump(Jump& jump, const JumpGate& gate, float ground, std::uint32_t roll) noexcept;

// Một lần CObject_Phy::Tick cùng SetMapPosition lúc now_ms; ground là độ cao mặt đất (đơn vị game) ở
// chỗ đứng hiện tại. Trả true khi lần này chạm đất.
bool tick_jump(Jump& jump, std::uint32_t now_ms, float ground) noexcept;

} // namespace game::motion