#include "gate/motion.hpp"

namespace game::gate {

std::uint32_t motion_tick(std::int64_t now_ns) noexcept {
    if (now_ns < 0) return 0;
    return static_cast<std::uint32_t>(static_cast<std::uint64_t>(now_ns / kMotionTickNs));
}

protocol::Position Motion::place(guard::Anchor at, std::int64_t now_ns) noexcept {
    pace_.reset(at, 0, motion_tick(now_ns));
    placed_ = true;
    client_tick_ = 0;
    return protocol::Position{.x_cm = at.x_cm, .z_cm = at.z_cm, .tick = 0};
}

void Motion::clear() noexcept {
    pace_ = guard::Pace{};
    placed_ = false;
    client_tick_ = 0;
}

MotionOutcome Motion::judge(const protocol::Move& move, std::int64_t now_ns) noexcept {
    MotionOutcome outcome;
    if (!placed_) return outcome;
    const guard::Step step{.x_cm = move.x_cm, .z_cm = move.z_cm, .tick = move.tick};
    switch (pace_.observe(step, motion_tick(now_ns))) {
    case guard::Verdict::kOk:
        client_tick_ = move.tick;
        outcome.act = MotionAct::kAccept;
        return outcome;
    case guard::Verdict::kRejected: {
        const guard::Anchor at = pace_.anchor();
        outcome.act = MotionAct::kCorrect;
        outcome.position = protocol::Position{.x_cm = at.x_cm, .z_cm = at.z_cm, .tick = client_tick_};
        return outcome;
    }
    case guard::Verdict::kSpeed:
    case guard::Verdict::kTeleport: outcome.act = MotionAct::kKick; return outcome;
    case guard::Verdict::kNoAnchor: break;
    }
    return outcome;
}

} // namespace game::gate