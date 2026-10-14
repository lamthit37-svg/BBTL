#include "social/limits.hpp"

#include "social/types.hpp"

#include "ids/ids.hpp"
#include "table/tsv.hpp"

#include <array>
#include <bitset>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <string>
#include <string_view>
#include <utility>

namespace game::social {
namespace {

struct Field {
    std::string_view key;
    std::int64_t Limits::* member;
    std::int32_t low;
    std::int32_t high;
};

constexpr std::int32_t kInt32Max = std::numeric_limits<std::int32_t>::max();

// Miền từng khoá là trần chống số thù địch trong tệp bảng, không phải luật chơi: luật chơi nằm ở
// cột value. Mỗi khoá có chỗ dùng thật trong mã của module (không khoá thừa).
constexpr std::array kFields{
    Field{.key = "team.max_members", .member = &Limits::team_max_members, .low = 2, .high = 64},
    Field{.key = "team.max_teams", .member = &Limits::team_max_teams, .low = 1, .high = 1'000'000},
    Field{.key = "team.pending_ttl_seconds", .member = &Limits::team_pending_ttl_seconds, .low = 1, .high = 86'400},
    Field{.key = "team.max_pending_per_target", .member = &Limits::team_max_pending_per_target, .low = 1, .high = 1000},
    Field{.key = "team.max_pending_per_sender", .member = &Limits::team_max_pending_per_sender, .low = 1, .high = 1000},
    Field{.key = "team.offline_grace_seconds", .member = &Limits::team_offline_grace_seconds, .low = 0, .high = 86'400},
    Field{.key = "relation.max_friends", .member = &Limits::relation_max_friends, .low = 1, .high = 1000},
    Field{.key = "relation.max_per_group", .member = &Limits::relation_max_per_group, .low = 1, .high = 1000},
    Field{.key = "relation.max_blacklist", .member = &Limits::relation_max_blacklist, .low = 1, .high = 1000},
    Field{.key = "relation.max_enemies", .member = &Limits::relation_max_enemies, .low = 1, .high = 1000},
    Field{.key = "relation.max_temp_friends", .member = &Limits::relation_max_temp_friends, .low = 1, .high = 1000},
    Field{.key = "relation.max_friend_point", .member = &Limits::relation_max_friend_point, .low = 1, .high = 1'000'000},
    Field{.key = "relation.mood_max_bytes", .member = &Limits::relation_mood_max_bytes, .low = 1, .high = 255},
    Field{.key = "relation.max_prentices", .member = &Limits::relation_max_prentices, .low = 1, .high = 16},
    Field{.key = "relation.max_moral_point", .member = &Limits::relation_max_moral_point, .low = 1, .high = kInt32Max},
    Field{.key = "relation.betray_cooldown_seconds", .member = &Limits::relation_betray_cooldown_seconds, .low = 0, .high = 31'536'000},
    Field{.key = "relation.pending_ttl_seconds", .member = &Limits::relation_pending_ttl_seconds, .low = 1, .high = 86'400},
    Field{.key = "relation.max_pending", .member = &Limits::relation_max_pending, .low = 1, .high = 1000},
    Field{.key = "relation.marry_min_friend_point", .member = &Limits::relation_marry_min_friend_point, .low = 0, .high = 1'000'000},
    Field{.key = "relation.master_min_level", .member = &Limits::relation_master_min_level, .low = 1, .high = 1000},
    Field{.key = "relation.prentice_max_level", .member = &Limits::relation_prentice_max_level, .low = 1, .high = 1000},
    Field{.key = "relation.moral_per_milestone", .member = &Limits::relation_moral_per_milestone, .low = 0, .high = 1'000'000},
    Field{.key = "guild.hard_member_cap", .member = &Limits::guild_hard_member_cap, .low = 1, .high = 10'000},
    Field{.key = "guild.max_proposers", .member = &Limits::guild_max_proposers, .low = 1, .high = 1000},
    Field{.key = "guild.max_guilds", .member = &Limits::guild_max_guilds, .low = 1, .high = 10'000'000},
    Field{.key = "guild.name_max_bytes", .member = &Limits::guild_name_max_bytes, .low = 1, .high = 255},
    Field{.key = "guild.name_min_codepoints", .member = &Limits::guild_name_min_codepoints, .low = 1, .high = 64},
    Field{.key = "guild.desc_max_bytes", .member = &Limits::guild_desc_max_bytes, .low = 1, .high = 1023},
    Field{.key = "guild.position_name_max_bytes", .member = &Limits::guild_position_name_max_bytes, .low = 1, .high = 255},
    Field{.key = "guild.create_min_level", .member = &Limits::guild_create_min_level, .low = 1, .high = 1000},
    Field{.key = "guild.create_fee_copper", .member = &Limits::guild_create_fee_copper, .low = 0, .high = kInt32Max},
    Field{.key = "guild.war_min_members", .member = &Limits::guild_war_min_members, .low = 1, .high = 10'000},
    Field{.key = "guild.league_max_members", .member = &Limits::guild_league_max_members, .low = 2, .high = 1000},
    Field{.key = "guild.max_elite", .member = &Limits::guild_max_elite, .low = 0, .high = 1000},
    Field{.key = "guild.max_office", .member = &Limits::guild_max_office, .low = 0, .high = 1000},
    Field{.key = "guild.proposer_ttl_seconds", .member = &Limits::guild_proposer_ttl_seconds, .low = 1, .high = 31'536'000},
    Field{.key = "guild.league_invite_ttl_seconds", .member = &Limits::guild_league_invite_ttl_seconds, .low = 1, .high = 86'400},
    Field{.key = "mail.inbox_cap", .member = &Limits::mail_inbox_cap, .low = 1, .high = 1000},
    Field{.key = "mail.max_items", .member = &Limits::mail_max_items, .low = 0, .high = 64},
    Field{.key = "mail.title_max_bytes", .member = &Limits::mail_title_max_bytes, .low = 1, .high = 255},
    Field{.key = "mail.text_max_bytes", .member = &Limits::mail_text_max_bytes, .low = 1, .high = 4095},
    Field{.key = "mail.send_min_level", .member = &Limits::mail_send_min_level, .low = 1, .high = 1000},
    Field{.key = "mail.send_fee_copper", .member = &Limits::mail_send_fee_copper, .low = 0, .high = kInt32Max},
    Field{.key = "mail.expire_seconds", .member = &Limits::mail_expire_seconds, .low = 1, .high = kInt32Max},
    Field{.key = "chat.max_bytes", .member = &Limits::chat_max_bytes, .low = 1, .high = 4095},
    Field{.key = "chat.burst", .member = &Limits::chat_burst, .low = 1, .high = 1000},
    Field{.key = "chat.global_interval_ms", .member = &Limits::chat_global_interval_ms, .low = 0, .high = 3'600'000},
    Field{.key = "chat.global_burst", .member = &Limits::chat_global_burst, .low = 1, .high = 1000},
    Field{.key = "chat.repeat_window_seconds", .member = &Limits::chat_repeat_window_seconds, .low = 1, .high = 86'400},
    Field{.key = "chat.repeat_max", .member = &Limits::chat_repeat_max, .low = 1, .high = 16},
    Field{.key = "chat.custom_channel_members", .member = &Limits::chat_custom_channel_members, .low = 2, .high = 1000},
    Field{.key = "chat.max_custom_channels", .member = &Limits::chat_max_custom_channels, .low = 1, .high = 1'000'000},
    Field{.key = "rank.default_capacity", .member = &Limits::rank_default_capacity, .low = 1, .high = 100'000},
    Field{.key = "rank.snapshot_interval_seconds", .member = &Limits::rank_snapshot_interval_seconds, .low = 1, .high = 86'400},
    Field{.key = "rank.max_boards", .member = &Limits::rank_max_boards, .low = 1, .high = 100'000},
    Field{.key = "notice.daily_broadcast_minute", .member = &Limits::notice_daily_broadcast_minute, .low = 0, .high = 1439},
    Field{.key = "notice.max_text_bytes", .member = &Limits::notice_max_text_bytes, .low = 16, .high = 4095},
};

[[nodiscard]] const Field* find_field(std::string_view key) noexcept {
    for (const Field& field : kFields) {
        if (field.key == key) return &field;
    }
    return nullptr;
}

[[nodiscard]] bool known_basis(std::string_view basis) noexcept {
    return basis == "source_2008" || basis == "client_2026" || basis == "made_up";
}

} // namespace

std::size_t limits_key_count() noexcept { return kFields.size(); }

TickSpan seconds_to_ticks(std::int64_t seconds) noexcept {
    // Trần để seconds * 1000 không tràn: bảng đã chặn ở 2^31, đây chặn thêm cho bên gọi khác.
    constexpr std::int64_t kCap = std::int64_t{1} << 40;
    const std::int64_t capped = seconds > kCap ? kCap : seconds;
    return ids::to_ticks(capped * 1000, kTicksPerSecond);
}

TickSpan millis_to_ticks(std::int64_t milliseconds) noexcept {
    constexpr std::int64_t kCap = std::int64_t{1} << 50;
    return ids::to_ticks(milliseconds > kCap ? kCap : milliseconds, kTicksPerSecond);
}

std::expected<Limits, std::string> parse_limits(std::string_view tsv_text) {
    auto parsed = table::parse_tsv(tsv_text);
    if (!parsed) return std::unexpected(std::move(parsed.error()));
    const table::Tsv& sheet = *parsed;
    Limits limits;
    std::bitset<kFields.size()> seen;
    for (std::size_t row = 0; row < sheet.rows.size(); ++row) {
        table::RowReader reader(sheet, row);
        const std::string_view key = reader.text("key");
        const Field* field = find_field(key);
        if (field == nullptr && !reader.error()) {
            reader.reject("key", "khoá giới hạn lạ");
        }
        const std::int32_t value = field != nullptr ? reader.integer("value", field->low, field->high) : 0;
        const std::string_view basis = reader.text("basis");
        if (!known_basis(basis) && !reader.error()) {
            reader.reject("basis", "cột basis chỉ nhận source_2008, client_2026 hoặc made_up");
        }
        if (reader.text("source").empty() && !reader.error()) {
            reader.reject("source", "thiếu nguồn của số");
        }
        if (reader.error()) return std::unexpected(*reader.error());
        const auto index = static_cast<std::size_t>(field - kFields.data());
        if (seen.test(index)) {
            return std::unexpected(std::format("dòng {}: trùng khoá {}", sheet.lines[row], key));
        }
        seen.set(index);
        limits.*(field->member) = value;
    }
    if (seen.count() != kFields.size()) {
        std::size_t index = 0;
        for (const Field& field : kFields) {
            if (!seen.test(index++)) return std::unexpected(std::format("thiếu khoá {}", field.key));
        }
    }
    return limits;
}

} // namespace game::social
