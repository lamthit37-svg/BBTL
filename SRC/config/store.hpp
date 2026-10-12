#pragma once
// Bộ đọc store.toml: database game, nhịp đẩy đĩa và thư mục nhật ký.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <string>
#include <string_view>

namespace game::config {

struct Store {
    DatabaseLogin database;
    std::chrono::milliseconds character_ms{0};
    std::chrono::milliseconds world_ms{0};
    std::string dir;
};

[[nodiscard]] ReadResult<Store> read_store(std::string_view text);

} // namespace game::config
