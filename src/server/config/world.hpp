#pragma once
// Bộ đọc world.toml: sức chứa bộ nhớ, các giờ báo cáo số người, thông báo vào bang
// và luật PC có gặp mobile hay không. Engine không đọc luật này.

#include "config/issue.hpp"

#include <cstdint>
#include <string_view>
#include <vector>

namespace game::config {

// Phía người chơi. APK và iOS đều là kMobile, không phải hai phía.
enum class ClientKind : std::uint8_t { kPc, kMobile };

struct World {
    std::int64_t online_users = 0;
    std::int64_t mail_users = 0;
    std::int64_t offline_cache = 0;
    std::int64_t speakers = 0;
    std::int64_t pet_friend_ads = 0;
    std::vector<std::int64_t> hours;
    bool join_guild = false;
    bool pc_meets_mobile = false;
};

[[nodiscard]] ReadResult<World> read_world(std::string_view text);

// Cùng phía thì gặp. Khác phía chỉ khi pc_meets_mobile bật.
[[nodiscard]] bool may_meet(ClientKind left, ClientKind right, const World& world) noexcept;

} // namespace game::config
