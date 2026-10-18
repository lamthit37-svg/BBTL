/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/gate/motion.cpp
 *  PHÂN HỆ   : Server / Gate / Motion
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt gate::Motion: bọc guard::Pace với đồng hồ của gate, đổi kết quả
 *    Pace thành hành động cho table.cpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "gate/motion.hpp"

namespace game::gate {

std::uint32_t motion_tick(std::int64_t now_ns) noexcept {
    if (now_ns < 0) return 0;
    return static_cast<std::uint32_t>(static_cast<std::uint64_t>(now_ns / kMotionTickNs));
}

protocol::Position Motion::place(guard::Anchor at, std::int64_t now_ns, float resync_cm) noexcept {
    pace_.reset(at, 0, motion_tick(now_ns), resync_cm);
    placed_ = true;
    client_tick_ = 0;
    return protocol::Position{.x_cm = at.x_cm, .z_cm = at.z_cm, .tick = 0};
}

void Motion::clear() noexcept {
    pace_ = guard::Pace{};
    placed_ = false;
    client_tick_ = 0;
}

MotionOutcome Motion::judge(const protocol::Move& move) noexcept {
    MotionOutcome outcome;
    if (!placed_) return outcome;
    const guard::Step step{.x_cm = move.x_cm, .z_cm = move.z_cm, .tick = move.tick};
    switch (pace_.observe(step)) {
    case guard::Verdict::kOk:
        client_tick_ = move.tick;
        outcome.act = MotionAct::kAccept;
        return outcome;
    case guard::Verdict::kRejected:
    case guard::Verdict::kResync: return pull_back();
    case guard::Verdict::kNoAnchor: break;
    }
    return outcome;
}

// Kéo client về mốc của máy chủ, kèm tick của bước nhận gần nhất để client đếm tiếp.
MotionOutcome Motion::pull_back() const noexcept {
    const guard::Anchor at = pace_.anchor();
    const protocol::Position pulled{.x_cm = at.x_cm, .z_cm = at.z_cm, .tick = client_tick_};
    return MotionOutcome{.act = MotionAct::kCorrect, .position = pulled};
}

guard::Trail Motion::chase(std::int64_t now_ns) noexcept {
    if (!placed_) return guard::Trail{};
    return pace_.advance(motion_tick(now_ns));
}

} // namespace game::gate
