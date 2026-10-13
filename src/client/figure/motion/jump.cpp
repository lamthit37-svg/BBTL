#include "motion/jump.hpp"

namespace game::motion {

bool can_jump(const Jump& jump, const JumpGate& gate) noexcept {
    if (gate.is_move_limited || gate.is_dead || jump.is_jumping || gate.is_busy) return false;
    if (gate.is_transformed || gate.is_following_team || gate.is_in_stall) return false;
    return true;
}

JumpStart start_jump(Jump& jump, const JumpGate& gate, float ground, std::uint32_t roll) noexcept {
    if (!can_jump(jump, gate)) return JumpStart{};
    JumpStart started;
    started.has_started = true;
    if (gate.is_moving) {
        const bool runs = gate.is_mounted || roll % 4U == 0U;
        started.action = runs ? JumpAction::kJumpRun : JumpAction::kJumpStand;
    }
    // Gốc chỉ bật vật lý khi đang chạy hay không cưỡi; đứng yên trên thú cưỡi chỉ phát động tác.
    if (!gate.is_moving && gate.is_mounted) return started;
    jump = Jump{};
    jump.is_jumping = true;
    jump.height = ground;
    jump.speed = kJumpSpeed;
    return started;
}

bool tick_jump(Jump& jump, std::uint32_t now_ms, float ground) noexcept {
    if (!jump.is_jumping) return false;
    if (!jump.has_mark) {
        jump.has_mark = true;
        jump.mark_ms = now_ms;
        return false;
    }
    const std::uint32_t delta = now_ms - jump.mark_ms;
    if (delta < kPhyTickMs) return false;
    jump.mark_ms = now_ms;
    jump.flown_ms += delta;
    const float part = static_cast<float>(jump.flown_ms) / kFlightMs;
    const float rest = 1.0F - part;
    jump.speed = (rest * rest * kRiseScale) - (part * part * kFallScale);
    const float next = jump.height + (jump.speed * kPhyStep);
    if (ground > next) {
        jump.height = ground;
        if (jump.speed < 0.0F) {
            jump = Jump{.height = ground};
            return true;
        }
        return false;
    }
    jump.height = next;
    return false;
}

} // namespace game::motion