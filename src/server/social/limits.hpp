#pragma once
// Bảng giới hạn và hằng số của lõi xã hội. Mọi số nằm một chỗ: bảng
// dev/server/tables/server/social_limits.tsv, mỗi dòng ghi nguồn (cột basis: source_2008,
// client_2026 hay made_up). Số made_up là số tự đặt chờ chủ dự án duyệt; không số nào rải trong mã.
//
// Phần luật đã nằm trong dev/server/config/rules/*.toml (guild.toml, social.toml) KHÔNG chép sang
// bảng này: bên gọi đọc TOML rồi điền GuildRules và RelationRules để chỉ có một nơi giữ số.

#include "social/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>

namespace game::social {

// Giá trị bảng nạp xong; trường nào bảng thiếu thì nạp lỗi (không có số mặc định ngầm).
struct Limits {
    // Đội.
    std::int64_t team_max_members = 0;
    std::int64_t team_max_teams = 0;
    std::int64_t team_pending_ttl_seconds = 0;
    std::int64_t team_max_pending_per_target = 0;
    std::int64_t team_max_pending_per_sender = 0;
    std::int64_t team_offline_grace_seconds = 0;
    // Quan hệ.
    std::int64_t relation_max_friends = 0;
    std::int64_t relation_max_per_group = 0;
    std::int64_t relation_max_blacklist = 0;
    std::int64_t relation_max_enemies = 0;
    std::int64_t relation_max_temp_friends = 0;
    std::int64_t relation_max_friend_point = 0;
    std::int64_t relation_mood_max_bytes = 0;
    std::int64_t relation_max_prentices = 0;
    std::int64_t relation_max_moral_point = 0;
    std::int64_t relation_betray_cooldown_seconds = 0;
    std::int64_t relation_pending_ttl_seconds = 0;
    std::int64_t relation_max_pending = 0;
    std::int64_t relation_marry_min_friend_point = 0;
    std::int64_t relation_master_min_level = 0;
    std::int64_t relation_prentice_max_level = 0;
    std::int64_t relation_moral_per_milestone = 0;
    // Bang.
    std::int64_t guild_hard_member_cap = 0;
    std::int64_t guild_max_proposers = 0;
    std::int64_t guild_max_guilds = 0;
    std::int64_t guild_name_max_bytes = 0;
    std::int64_t guild_name_min_codepoints = 0;
    std::int64_t guild_desc_max_bytes = 0;
    std::int64_t guild_position_name_max_bytes = 0;
    std::int64_t guild_create_min_level = 0;
    std::int64_t guild_create_fee_copper = 0;
    std::int64_t guild_war_min_members = 0;
    std::int64_t guild_league_max_members = 0;
    std::int64_t guild_max_elite = 0;
    std::int64_t guild_max_office = 0;
    std::int64_t guild_proposer_ttl_seconds = 0;
    std::int64_t guild_league_invite_ttl_seconds = 0;
    // Thư.
    std::int64_t mail_inbox_cap = 0;
    std::int64_t mail_max_items = 0;
    std::int64_t mail_title_max_bytes = 0;
    std::int64_t mail_text_max_bytes = 0;
    std::int64_t mail_send_min_level = 0;
    std::int64_t mail_send_fee_copper = 0;
    std::int64_t mail_expire_seconds = 0;
    // Chat.
    std::int64_t chat_max_bytes = 0;
    std::int64_t chat_burst = 0;
    std::int64_t chat_global_interval_ms = 0;
    std::int64_t chat_global_burst = 0;
    std::int64_t chat_repeat_window_seconds = 0;
    std::int64_t chat_repeat_max = 0;
    std::int64_t chat_custom_channel_members = 0;
    std::int64_t chat_max_custom_channels = 0;
    // Xếp hạng.
    std::int64_t rank_default_capacity = 0;
    std::int64_t rank_snapshot_interval_seconds = 0;
    std::int64_t rank_max_boards = 0;
    // Thông báo hệ thống.
    std::int64_t notice_daily_broadcast_minute = 0;
    std::int64_t notice_max_text_bytes = 0;
};

// Đọc bảng TSV (nội dung đã nạp). Lỗi: thiếu khoá, khoá lạ, trùng khoá, số ngoài miền, bảng sai
// dạng. Thông báo tiếng Việt có số dòng. Không đọc đĩa.
[[nodiscard]] std::expected<Limits, std::string> parse_limits(std::string_view tsv_text);

// Số khoá bảng phải có; test dùng để canh bảng và mã không lệch nhau.
[[nodiscard]] std::size_t limits_key_count() noexcept;

// Số giây trong bảng đổi sang tick, làm tròn lên (ids::to_ticks). Âm hay 0 thành 0.
[[nodiscard]] TickSpan seconds_to_ticks(std::int64_t seconds) noexcept;
[[nodiscard]] TickSpan millis_to_ticks(std::int64_t milliseconds) noexcept;

// Luật bang từ dev/server/config/rules/guild.toml (bên gọi điền; lõi không đọc TOML).
struct GuildRules {
    std::int32_t initial_member_cap = 0;   // [guild] initial_member_cap
    Copper city_cost = 0;                  // [guild] city_cost
    Copper message_cost = 0;               // [guild] message_cost
    std::int32_t battle_minutes = 0;       // [guild] battle_time (đơn vị phút: giả định, xem SERVER-SOCIAL.md)
    std::array<std::int32_t, 5> county_max_user{};     // [county_office] max_user, cấp 1..5
    std::array<Copper, 5> county_max_money{};          // [county_office] max_money, cấp 1..5
    std::array<Copper, 5> county_standard_money{};     // [county_office] standard_money, cấp 1..5: quỹ chuẩn để lên cấp kế (giả định)
    std::int32_t league_max_count = 0;     // [league] max_count
    std::int32_t league_rejoin_hours = 0;  // [league] rejoin_hours
    Copper league_create_cost = 0;         // [league] create_cost
};

// Luật quan hệ từ dev/server/config/rules/social.toml.
struct RelationRules {
    std::int32_t password_intimacy = 0;  // [relation] password_intimacy: từ mức này xoá bạn cần xác minh
    std::int32_t presence_intimacy = 0;  // [relation] presence_intimacy: từ mức này báo lên/xuống tuyến
};

} // namespace game::social
