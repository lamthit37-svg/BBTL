// Hướng mặt xoay dần; luật ghi ở turning.hpp.
// Nguồn: TLBB Dev src/client_app/turning.cpp@e0d89a6. Khác gốc: namespace game::avatar; id là số
// nguyên không dấu; core::Clock; bước xoá của drop_unseen tách hàm (cổng của dự án cấm `if` trong
// vòng lặp).
#include "avatar/turning.hpp"

#include "core/clock.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <numbers>

namespace game::avatar {
namespace {

constexpr float kFullTurn = 2.0F * std::numbers::pi_v<float>;

// Góc đưa về [−π, π]: std::remainder lấy phần dư gần 0 nhất, nên hiệu hai hướng là cung ngắn nhất.
float wrapped(float angle) {
    return std::remainder(angle, kFullTurn);
}

} // namespace

float Turning::face(std::uint32_t id, float target, core::Clock::time_point now) {
    const auto [found, is_new] = turns_.try_emplace(id, Turn{.angle = target, .at = now});
    Turn& turn = found->second;
    turn.is_seen = true;
    if (is_new) return target;
    const std::chrono::duration<float> since = now - turn.at;
    const std::chrono::duration<float> span = kTurnTime;
    const float step = 1.0F - std::exp(-std::max(since.count(), 0.0F) / span.count());
    const float gap = wrapped(target - turn.angle);
    turn.angle = wrapped(turn.angle + (gap * step));
    turn.at = now;
    return turn.angle;
}

void Turning::drop_unseen() {
    std::erase_if(turns_, [](const auto& entry) { return !entry.second.is_seen; });
    for (auto& entry : turns_) {
        entry.second.is_seen = false;
    }
}

} // namespace game::avatar
