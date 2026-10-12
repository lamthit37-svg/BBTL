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
using detail::Cursor;
using detail::finish;
using detail::keep;
using detail::keep_enum;
using detail::NamedValue;
using detail::Node;
using detail::parse_text;

constexpr std::string_view kRoot[] = {"schema", "audit", "file", "level"};
constexpr std::string_view kFile[] = {"dir", "rotate_mb"};
constexpr std::string_view kLevel[] = {"default"};
constexpr NamedValue kLevels[] = {
    {"error", static_cast<std::uint8_t>(LogLevel::kError)},
    {"warn", static_cast<std::uint8_t>(LogLevel::kWarn)},
    {"info", static_cast<std::uint8_t>(LogLevel::kInfo)},
    {"debug", static_cast<std::uint8_t>(LogLevel::kDebug)},
};

void read_file(Bag& bag, const Node* table, Log& log) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kFile);
    keep(cursor.text("dir", detail::kPathText), log.dir);
    keep(cursor.bounded("rotate_mb", detail::kCount), log.rotate_mb);
}

void read_level(Bag& bag, const Node* table, Log& log) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kLevel);
    keep_enum(cursor.named("default", kLevels), log.level);
}

[[nodiscard]] Log read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.unknown(kRoot);
    Log log;
    keep(cursor.flag("audit"), log.audit);
    read_file(bag, cursor.child("file"), log);
    read_level(bag, cursor.child("level"), log);
    return log;
}

} // namespace

ReadResult<Log> read_log(std::string_view text) {
    const detail::Parsed parsed = parse_text(text);
    if (!parsed.issues.empty()) return std::unexpected(std::move(parsed.issues));
    Bag bag;
    return finish(read_sections(bag, parsed.root), bag);
}

} // namespace game::config
