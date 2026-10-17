/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/mind.hpp
 *  PHÂN HỆ   : Server / Zone / Mind
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trí khôn của quái và NPC đặt sẵn: tính nết (số lấy từ bảng MonsterAITable
 *    của máy chủ 2008, đã đổi sang cm và tick) và trạng thái chạy của một con.
 *    Phần chạy nằm ở Scene::think (zone/mind.cpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Hành vi port từ AI_Monster.cpp của máy chủ 2008 (AI_Logic_Idle, ScanEnemy, ToRandMove, AI_Logic_Approach,
// AI_Logic_Gohome, IsToGoHome): đứng, đi lang thang quanh chỗ sinh, quét người trong tầm, đuổi, bỏ cuộc và chạy về khi
// rời chỗ phát hiện quá xa. Khác gốc: không có kịch bản AI (AIScript), nhóm đồng đội, tuần tra và đánh nhau (lát sau);
// đứng gần mục tiêu thì chờ, chưa ra đòn. Đường đi là bước thẳng kiểm bằng luật đi của cảnh, chưa tìm đường vòng.

#pragma once

#include <cstdint>

namespace game::zone {

// Số đo đã đổi đơn vị: centimet, tick của nhịp cảnh (mặc định kTickHz) và centimet mỗi giây.
struct Temperament {
    // > 0: chủ động, quét người mỗi chừng này tick (AIPARAM_SCANTIME). 0: không bao giờ tự đuổi.
    std::uint32_t scan_ticks = 0;
    // > 0: đi lang thang, chờ chừng này tick cộng ngẫu nhiên tới chừng đó nữa giữa hai lần (AIPARAM_RANDMOVETIME).
    std::uint32_t wander_ticks = 0;
    // Quét người trong tầm này (AIPARAM_SCANENEMYDIST).
    std::uint32_t scan_cm = 0;
    // Rời chỗ phát hiện xa hơn thế này thì bỏ đuổi, chạy về (AIPARAM_RETURN).
    std::uint32_t return_cm = 0;
    // Bán kính lang thang quanh chỗ sinh (position range, mặc định 10 m theo monster.toml).
    std::uint32_t range_cm = 0;
    // Tốc độ đi bộ, cm/s (move_speed của mẫu chia 10). 0: đứng yên mãi.
    std::uint16_t walk_cm = 0;

    friend bool operator==(const Temperament&, const Temperament&) = default;
};

enum class Mode : std::uint8_t {
    kIdle,   // đứng; chờ tới giờ quét hoặc đi lang thang
    kWander, // đang đi tới điểm lang thang
    kChase,  // đang đuổi mục tiêu
    kHold,   // đã áp sát mục tiêu, đứng chờ (lát đánh nhau sẽ ra đòn ở đây)
    kHome,   // bỏ cuộc, chạy về chỗ sinh
};

// Trạng thái chạy của một con quái. `target` là id thực thể (xem id_of) của người đang bị đuổi, 0 là không có.
struct Mind {
    Temperament nature;
    float home_x_cm = 0.0F;
    float home_z_cm = 0.0F;
    Mode mode = Mode::kIdle;
    std::uint32_t target = 0;
    // Điểm tới của kWander, và chỗ bắt đầu đuổi (gốc của khoảng bỏ cuộc) của kChase.
    float goal_x_cm = 0.0F;
    float goal_z_cm = 0.0F;
    float origin_x_cm = 0.0F;
    float origin_z_cm = 0.0F;
    // Tick sớm nhất cần xét lại con này; chưa tới thì bỏ qua.
    std::uint32_t wake = 0;
    std::uint32_t next_scan = 0;
    std::uint32_t next_wander = 0;
    // Số bước liền không đi được (luật đi chặn): vượt kStuckSteps thì bỏ cuộc.
    std::uint8_t stuck = 0;
    // Vị trí trong Scene::thinkers_ (0xFFFFFFFF: không chạy).
    std::uint32_t slot = 0xFFFFFFFFU;
};

} // namespace game::zone
