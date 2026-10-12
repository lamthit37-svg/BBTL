#pragma once
// Bộ đọc world.toml: sức chứa bộ nhớ, các giờ báo cáo số người và thông báo vào bang.

#include "config/issue.hpp"

#include <cstdint>
#include <string_view>
#include <vector>

namespace game::config {

struct World {
    std::int64_t online_users = 0;
    std::int64_t mail_users = 0;
    std::int64_t offline_cache = 0;
    std::int64_t speakers = 0;
    std::int64_t pet_friend_ads = 0;
    std::vector<std::int64_t> hours;
    bool join_guild = false;
};

[[nodiscard]] ReadResult<World> read_world(std::string_view text);

} // namespace game::config
