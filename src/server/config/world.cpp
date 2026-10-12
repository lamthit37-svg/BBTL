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
using detail::keep;
using detail::Node;

constexpr std::string_view kRoot[] = {"schema", "capacity", "player_count_report", "notice", "platform"};
constexpr std::string_view kCapacity[] = {
    "online_users",
    "mail_users",
    "offline_cache",
    "speakers",
    "pet_friend_ads",
};
constexpr std::string_view kReport[] = {"hours"};
constexpr std::string_view kNotice[] = {"join_guild"};
constexpr std::string_view kPlatform[] = {"pc_meets_mobile"};

void read_capacity(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kCapacity);
    keep(cursor.bounded("online_users", detail::kCount), world.online_users);
    keep(cursor.bounded("mail_users", detail::kCount), world.mail_users);
    keep(cursor.bounded("offline_cache", detail::kCount), world.offline_cache);
    keep(cursor.bounded("speakers", detail::kCount), world.speakers);
    keep(cursor.bounded("pet_friend_ads", detail::kCount), world.pet_friend_ads);
}

void read_report(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kReport);
    keep(cursor.hours("hours"), world.hours);
}

void read_notice(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kNotice);
    keep(cursor.flag("join_guild"), world.join_guild);
}

void read_platform(Bag& bag, const Node* table, World& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kPlatform);
    keep(cursor.flag("pc_meets_mobile"), world.pc_meets_mobile);
}

[[nodiscard]] World read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    World world;
    read_capacity(bag, cursor.child("capacity"), world);
    read_report(bag, cursor.child("player_count_report"), world);
    read_notice(bag, cursor.child("notice"), world);
    read_platform(bag, cursor.child("platform"), world);
    return world;
}

} // namespace

ReadResult<World> read_world(std::string_view text) {
    return detail::read_document<World>(text, read_sections);
}

bool may_meet(ClientKind left, ClientKind right, const World& world) noexcept {
    if (left == right) return true;
    return world.pc_meets_mobile;
}

} // namespace game::config
