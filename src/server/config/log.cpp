/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/config/log.cpp
 *  PHÂN HỆ   : Server / Config / Log
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt read_log: đọc log.toml (audit, play_trace, [file], [level]).
 *  - play_trace là khoá tuỳ chọn, thiếu thì log kiểm tắt; mọi khoá khác bắt
 *    buộc như trước.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "config/log.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

using detail::Bag;
using detail::Choice;
using detail::Cursor;
using detail::keep;
using detail::Node;

constexpr std::string_view kRoot[] = {"schema", "audit", "play_trace", "file", "level"};
constexpr std::string_view kFile[] = {"dir", "rotate_mb"};
constexpr std::string_view kLevel[] = {"default"};
constexpr std::array<Choice<LogLevel>, 4> kLevels{{
    {.name = "error", .value = LogLevel::kError},
    {.name = "warn", .value = LogLevel::kWarn},
    {.name = "info", .value = LogLevel::kInfo},
    {.name = "debug", .value = LogLevel::kDebug},
}};

void read_file(Bag& bag, const Node* table, Log& log) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kFile);
    keep(cursor.text("dir", detail::kPathText), log.dir);
    keep(cursor.bounded("rotate_mb", detail::kCount), log.rotate_mb);
}

void read_level(Bag& bag, const Node* table, Log& log) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kLevel);
    keep(cursor.choice("default", kLevels), log.level);
}

[[nodiscard]] Log read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Log log;
    keep(cursor.flag("audit"), log.audit);
    // Khoá tuỳ chọn: thiếu thì log kiểm tắt, nên cấu hình sản xuất cũ vẫn đọc được.
    if (cursor.has("play_trace")) keep(cursor.flag("play_trace"), log.play_trace);
    read_file(bag, cursor.child("file"), log);
    read_level(bag, cursor.child("level"), log);
    return log;
}

} // namespace

ReadResult<Log> read_log(std::string_view text) {
    return detail::read_document<Log>(text, read_sections);
}

} // namespace game::config
