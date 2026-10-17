/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/config/log.hpp
 *  PHÂN HỆ   : Server / Config / Log
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc log.toml: bật kiểm toán, log kiểm theo việc người chơi, thư mục tệp
 *    log, cỡ xoay vòng và mức mặc định.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "config/issue.hpp"
#include "config/types.hpp"

#include <cstdint>
#include <string>
#include <string_view>

namespace game::config {

struct Log {
    bool audit = false;
    // true: zone ghi một dòng stderr cho mỗi việc của người chơi (zone/trace.hpp).
    bool play_trace = false;
    std::string dir;
    std::int64_t rotate_mb = 0;
    LogLevel level = LogLevel::kInfo;
};

[[nodiscard]] ReadResult<Log> read_log(std::string_view text);

} // namespace game::config
