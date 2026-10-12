#include "config/world.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::finish;
using detail::keep;
using detail::Node;
using detail::parse_text;

constexpr std::string_view kRoot[] = {"schema", "capacity", "player_count_report", "notice"};
constexpr std::string_view kCapacity[] = {
    "online_users",
    "mail_users",
    "offline_cache",
    "speakers",
    "pet_friend_ads",
};
constexpr std::string_view kReport[] = {"hours"};
constexpr std::string_view kNotice[] = {"join_guild"};

void read_capacity(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kCapacity);
    keep(cursor.bounded("online_users", detail::kCount), world.online_users);
    keep(cursor.bounded("mail_users", detail::kCount), world.mail_users);
    keep(cursor.bounded("offline_cache", detail::kCount), world.offline_cache);
    keep(cursor.bounded("speakers", detail::kCount), world.speakers);
    keep(cursor.bounded("pet_friend_ads", detail::kCount), world.pet_friend_ads);
}

void read_report(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kReport);
    keep(cursor.hours("hours"), world.hours);
}

void read_notice(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kNotice);
    keep(cursor.flag("join_guild"), world.join_guild);
}

[[nodiscard]] World read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.unknown(kRoot);
    World world;
    read_capacity(bag, cursor.child("capacity"), world);
    read_report(bag, cursor.child("player_count_report"), world);
    read_notice(bag, cursor.child("notice"), world);
    return world;
}

} // namespace

ReadResult<World> read_world(std::string_view text) {
    const detail::Parsed parsed = parse_text(text);
    if (!parsed.issues.empty()) return std::unexpected(std::move(parsed.issues));
    Bag bag;
    return finish(read_sections(bag, parsed.root), bag);
}

} // namespace game::config
