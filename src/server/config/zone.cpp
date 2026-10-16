#include "config/zone.hpp"

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

constexpr std::string_view kRoot[] = {
    "schema",
    "tick",
    "aoi",
    "capacity",
    "session",
    "world_clock",
    "drops",
    "audit",
    "text",
};
constexpr std::string_view kText[] = {"language"};

enum class Speech : std::uint8_t { kVi, kZh, kEn };

constexpr detail::Choice<Speech> kSpeech[] = {
    {.name = "vi", .value = Speech::kVi},
    {.name = "zh", .value = Speech::kZh},
    {.name = "en", .value = Speech::kEn},
};
constexpr std::string_view kTick[] = {"hz"};
constexpr std::string_view kAoi[] = {"cell_size"};
constexpr std::string_view kCapacity[] = {
    "monsters",
    "pets",
    "special_objects",
    "platforms",
    "buses",
    "player_shops",
    "scene_timers",
    "human_timers",
};
constexpr std::string_view kSession[] = {"linger_after_disconnect_ms", "linger_hidden_ms", "kick_idle_ms"};
constexpr std::string_view kClock[] = {"period_change_ms"};
constexpr std::string_view kDrops[] = {"box_recycle_ms"};
constexpr std::string_view kAudit[] = {"packet_stats_ms"};

void read_capacity(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kCapacity);
    keep(cursor.bounded("monsters", detail::kCount), zone.monsters);
    keep(cursor.bounded("pets", detail::kCount), zone.pets);
    keep(cursor.bounded("special_objects", detail::kCount), zone.special_objects);
    keep(cursor.bounded("platforms", detail::kCount), zone.platforms);
    keep(cursor.bounded("buses", detail::kCount), zone.buses);
    keep(cursor.bounded("player_shops", detail::kCount), zone.player_shops);
    keep(cursor.bounded("scene_timers", detail::kCount), zone.scene_timers);
    keep(cursor.bounded("human_timers", detail::kCount), zone.human_timers);
}

void read_session(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kSession);
    keep(cursor.millis("linger_after_disconnect_ms"), zone.linger_after_disconnect_ms);
    keep(cursor.millis("linger_hidden_ms"), zone.linger_hidden_ms);
    keep(cursor.millis("kick_idle_ms"), zone.kick_idle_ms);
}

void read_tick(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kTick);
    keep(cursor.bounded("hz", detail::kCount), zone.hz);
}

void read_aoi(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kAoi);
    keep(cursor.bounded("cell_size", detail::kCount), zone.cell_size);
}

void read_clock(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kClock);
    keep(cursor.millis("period_change_ms"), zone.period_change_ms);
}

void read_drops(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kDrops);
    keep(cursor.millis("box_recycle_ms"), zone.box_recycle_ms);
}

void read_speech(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kText);
    const std::optional<Speech> speech = cursor.choice("language", kSpeech);
    if (!speech) return;
    if (*speech == Speech::kZh) zone.language = "zh";
    if (*speech == Speech::kEn) zone.language = "en";
    if (*speech == Speech::kVi) zone.language = "vi";
}

void read_audit(Bag& bag, const Node* table, Zone& zone) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kAudit);
    keep(cursor.millis("packet_stats_ms"), zone.packet_stats_ms);
}

[[nodiscard]] Zone read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Zone zone;
    if (cursor.has("text")) read_speech(bag, cursor.child("text"), zone);
    read_tick(bag, cursor.child("tick"), zone);
    read_aoi(bag, cursor.child("aoi"), zone);
    read_capacity(bag, cursor.child("capacity"), zone);
    read_session(bag, cursor.child("session"), zone);
    read_clock(bag, cursor.child("world_clock"), zone);
    read_drops(bag, cursor.child("drops"), zone);
    read_audit(bag, cursor.child("audit"), zone);
    return zone;
}

} // namespace

ReadResult<Zone> read_zone(std::string_view text) {
    return detail::read_document<Zone>(text, read_sections);
}

} // namespace game::config
