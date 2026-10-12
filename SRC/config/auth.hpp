#pragma once
// Bộ đọc auth.toml: database, đăng ký, Argon2id, vé, luật đăng nhập, mã và thẻ.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <cstdint>
#include <string_view>

namespace game::config {

struct Auth {
    DatabaseLogin database;
    bool auto_register = false;
    std::int64_t gift_points = 0;
    std::int64_t ops_limit = 0;
    std::int64_t mem_limit_kib = 0;
    std::chrono::seconds ttl_seconds{0};
    bool relogin_limit = false;
    bool relogin_block = false;
    std::chrono::milliseconds relogin_block_ms{0};
    std::int64_t queue_turn_size = 0;
    std::int64_t max_sessions_per_device = 0;
    bool on_create = false;
    bool on_enter = false;
    bool security_card = false;
};

[[nodiscard]] ReadResult<Auth> read_auth(std::string_view text);

} // namespace game::config
