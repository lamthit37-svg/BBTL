#include "guard/pace.hpp"

#include <algorithm>
#include <cmath>

namespace game::guard {
namespace {

constexpr float kRunCmPerSec = 465.0F;
constexpr float kTickSeconds = 1.0F / 30.0F;
constexpr float kSlack = 1.05F;
constexpr float kSlackCm = 5.0F;
constexpr float kTeleportMinCm = 1600.0F;
// Gói đến dồn (mạng giật) được bù chừng này tick máy chủ; client khai hơn cũng không được hơn.
constexpr std::uint32_t kJitterTicks = 3;
// Ngân sách: mỗi lần vượt +1. Rò 1 điểm/giây (tốc độ) và 0,5 điểm/giây (dịch chuyển).
// Phạt khi nợ chạm ngưỡng; ngưỡng lẻ nửa điểm để rò trong vài tick không cứu chuỗi vượt liền nhau.
constexpr float kSpeedLeakPerTick = 1.0F * kTickSeconds;
constexpr float kTeleportLeakPerTick = 0.5F * kTickSeconds;
constexpr float kSpeedPenalty = 2.5F;    // ba bước vượt liền nhau, hoặc xen kẽ dày
constexpr float kTeleportPenalty = 1.5F; // hai cú nhảy trong chừng một giây
constexpr float kDebtCap = 16.0F;

struct Bound {
    bool over_speed = false;
    bool over_teleport = false;
};

[[nodiscard]] Bound measure(Step step, float from_x, float from_z, std::uint32_t ticks) noexcept {
    Bound bound;
    const float dx = step.x_cm - from_x;
    const float dz = step.z_cm - from_z;
    const float distance_cm = std::sqrt(dx * dx + dz * dz);
    if (!std::isfinite(distance_cm)) return Bound{.over_speed = true, .over_teleport = true};
    const float seconds = static_cast<float>(ticks) * kTickSeconds;
    const float limit_cm = kRunCmPerSec * seconds * kSlack + kSlackCm;
    bound.over_speed = distance_cm > limit_cm;
    const float floor_cm = std::max(limit_cm * 4.0F, kTeleportMinCm);
    bound.over_teleport = distance_cm > floor_cm;
    return bound;
}

// Hiệu có dấu theo modulo 2^32: tick quay vòng vẫn là tiến, tick lùi là âm.
[[nodiscard]] std::int32_t ticks_between(std::uint32_t from, std::uint32_t to) noexcept {
    return static_cast<std::int32_t>(to - from);
}

} // namespace

void Pace::reset(Anchor at, std::uint32_t client_tick, std::uint32_t server_tick) noexcept {
    has_anchor_ = true;
    x_cm_ = at.x_cm;
    z_cm_ = at.z_cm;
    client_tick_ = client_tick;
    server_tick_ = server_tick;
    leak_tick_ = server_tick;
    speed_debt_ = 0;
    teleport_debt_ = 0;
}

void Pace::leak(std::uint32_t server_tick) noexcept {
    const std::int32_t passed = ticks_between(leak_tick_, server_tick);
    if (passed <= 0) return;
    leak_tick_ = server_tick;
    const float ticks = static_cast<float>(passed);
    speed_debt_ = std::max(0.0F, speed_debt_ - ticks * kSpeedLeakPerTick);
    teleport_debt_ = std::max(0.0F, teleport_debt_ - ticks * kTeleportLeakPerTick);
}

Verdict Pace::observe(Step step, std::uint32_t server_tick) noexcept {
    if (!has_anchor_) return Verdict::kNoAnchor;
    leak(server_tick);
    const std::int32_t client_elapsed = ticks_between(client_tick_, step.tick);
    if (client_elapsed < 0) return Verdict::kRejected;
    const std::int32_t server_elapsed = std::max(0, ticks_between(server_tick_, server_tick));
    const std::int64_t allowed = static_cast<std::int64_t>(server_elapsed) + kJitterTicks;
    const auto elapsed = static_cast<std::uint32_t>(std::min<std::int64_t>(client_elapsed, allowed));
    const Bound bound = measure(step, x_cm_, z_cm_, elapsed);
    if (!bound.over_speed && !bound.over_teleport) {
        x_cm_ = step.x_cm;
        z_cm_ = step.z_cm;
        client_tick_ = step.tick;
        server_tick_ = server_tick;
        return Verdict::kOk;
    }
    if (bound.over_speed) speed_debt_ = std::min(kDebtCap, speed_debt_ + 1.0F);
    if (bound.over_teleport) teleport_debt_ = std::min(kDebtCap, teleport_debt_ + 1.0F);
    if (teleport_debt_ >= kTeleportPenalty) return Verdict::kTeleport;
    if (speed_debt_ >= kSpeedPenalty) return Verdict::kSpeed;
    return Verdict::kRejected;
}

} // namespace game::guard
