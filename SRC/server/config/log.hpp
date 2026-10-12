#pragma once
// Bộ đọc log.toml: bật kiểm toán, thư mục tệp log, cỡ xoay vòng và mức mặc định.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <cstdint>
#include <string>
#include <string_view>

namespace game::config {

struct Log {
    bool audit = false;
    std::string dir;
    std::int64_t rotate_mb = 0;
    LogLevel level = LogLevel::kInfo;
};

[[nodiscard]] ReadResult<Log> read_log(std::string_view text);

} // namespace game::config
