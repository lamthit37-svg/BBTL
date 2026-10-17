/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/bullet.hpp
 *  PHÂN HỆ   : Figure / Look / Bullet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bay của đạn kỹ năng và hai bảng bullets.tsv, skill_bullets.tsv.
 *  - Nguồn: CObject_Bullet::Tick (client 2008) và Bullet.txt (client 2026).
 *    Độ nâng cung là m_fContrailParam; bảng 2026 không có cột đó nên mặc định 0.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "look/appearance.hpp"

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// 0 thẳng, 1 cung, 2 không bay (nổ tại đích). -1 của gốc cũng nổ tại đích.
enum class Trail : std::int8_t { kLine = 0, kArc = 1, kNone = 2 };

struct FlightPoint {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
};

struct BulletRow {
    std::uint32_t id = 0;
    Trail trail = Trail::kLine;
    float speed = 0.0F;
    std::string flight;
    std::string flight_sound;
    std::string explosion;
    std::string explosion_sound;
    std::string anchor;
};

struct SkillBullet {
    std::uint32_t skill = 0;
    std::uint32_t bullet = 0;
    std::string spawn;
};

// Trạng thái một viên đang bay. Đơn vị là đơn vị của nơi gọi (mét game hoặc thế giới).
// seconds của step_bullet đã là giây: gốc nhân speed với delta mili-giây rồi chia 1000.
struct BulletFlight {
    Trail trail = Trail::kLine;
    float speed = 0.0F;
    float arc_height = 0.0F;
    FlightPoint at{};
    FlightPoint start{};
    float span = 0.0F;
    bool hit = false;
};

struct BulletStep {
    FlightPoint at{};
    float facing = 0.0F;
    bool hit = false;
};

class BulletBook {
public:
    void reset(std::vector<BulletRow> rows);
    [[nodiscard]] const BulletRow* find(std::uint32_t id) const noexcept;

private:
    std::vector<BulletRow> rows_;
};

class SkillBulletBook {
public:
    void reset(std::vector<SkillBullet> rows);
    [[nodiscard]] const SkillBullet* find(std::uint32_t skill) const noexcept;

private:
    std::vector<SkillBullet> rows_;
};

[[nodiscard]] BulletFlight begin_flight(Trail trail, float speed, float arc_height,
    FlightPoint from, FlightPoint to) noexcept;

// Bay một khung về target. Target mất thì nơi gọi đưa (-1, -1, -1), như gốc.
[[nodiscard]] BulletStep step_bullet(const BulletFlight& flight, FlightPoint target,
    float seconds) noexcept;

using BulletRows = std::expected<std::vector<BulletRow>, std::string>;
using SkillRows = std::expected<std::vector<SkillBullet>, std::string>;

[[nodiscard]] BulletRows parse_bullets(std::string_view text);
[[nodiscard]] SkillRows parse_skill_bullets(std::string_view text);

} // namespace game::look
