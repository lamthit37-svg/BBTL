#pragma once
// Bộ đọc zone.toml: nhịp mô phỏng, ô vùng nhìn, sức chứa, phiên, đồng hồ và rơi đồ.

#include "config/issue.hpp"

#include <chrono>
#include <cstdint>
#include <string_view>

namespace game::config {

struct Zone {
    std::int64_t hz = 0;
    std::int64_t cell_size = 0;
    std::int64_t monsters = 0;
    std::int64_t pets = 0;
    std::int64_t special_objects = 0;
    std::int64_t platforms = 0;
    std::int64_t buses = 0;
    std::int64_t player_shops = 0;
    std::int64_t scene_timers = 0;
    std::int64_t human_timers = 0;
    std::chrono::milliseconds linger_after_disconnect_ms{0};
    std::chrono::milliseconds linger_hidden_ms{0};
    std::chrono::milliseconds kick_idle_ms{0};
    std::chrono::milliseconds period_change_ms{0};
    std::chrono::milliseconds box_recycle_ms{0};
    std::chrono::milliseconds packet_stats_ms{0};
};

[[nodiscard]] ReadResult<Zone> read_zone(std::string_view text);

} // namespace game::config
