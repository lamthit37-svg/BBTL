// Đồ phụ cho test của lõi xã hội: bảng người chơi giả (PlayerDirectory) và bộ giới hạn mẫu. Bộ
// giới hạn ở đây là số của TEST, đặt tường minh để mỗi ca tự đứng được; số thật nằm ở
// dev/server/tables/server/social_limits.tsv (ca social_limits_tests đọc và đối chiếu bảng thật).
#pragma once

#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {

using social::CharacterId;
using social::Limits;
using social::PlayerCard;

[[nodiscard]] inline CharacterId cid(std::uint64_t value) { return CharacterId{value}; }

// Bộ sinh số tất định (SplitMix64) cho kịch bản hạt giống cố định. Không dùng <random>: phân phối của nó khác nhau
// giữa các thư viện chuẩn, còn kịch bản phải ra đúng một dãy sự kiện ở mọi nơi.
struct SplitMix {
    std::uint64_t state;
    std::uint64_t next() {
        std::uint64_t z = (state += 0x9E3779B97F4A7C15ULL);
        z = (z ^ (z >> 30U)) * 0xBF58476D1CE4E5B9ULL;
        z = (z ^ (z >> 27U)) * 0x94D049BB133111EBULL;
        return z ^ (z >> 31U);
    }
    // Số trong [0, bound); bound > 0. Chệch modulo không đáng kể với bound nhỏ so với 2^64.
    std::uint64_t below(std::uint64_t bound) { return next() % bound; }
    // Đúng với xác suất `percent` phần trăm.
    bool chance(std::uint64_t percent) { return below(100) < percent; }
};

[[nodiscard]] inline Limits sample_limits() {
    Limits limits;
    limits.team_max_members = 6;
    limits.team_max_teams = 3000;
    limits.team_pending_ttl_seconds = 60;
    limits.team_max_pending_per_target = 8;
    limits.team_max_pending_per_sender = 16;
    limits.team_offline_grace_seconds = 300;
    limits.relation_max_friends = 80;
    limits.relation_max_per_group = 20;
    limits.relation_max_blacklist = 20;
    limits.relation_max_enemies = 20;
    limits.relation_max_temp_friends = 20;
    limits.relation_max_friend_point = 9999;
    limits.relation_mood_max_bytes = 25;
    limits.relation_max_prentices = 2;
    limits.relation_max_moral_point = 1'000'000;
    limits.relation_betray_cooldown_seconds = 259'200;
    limits.relation_pending_ttl_seconds = 60;
    limits.relation_max_pending = 16;
    limits.relation_marry_min_friend_point = 1000;
    limits.relation_master_min_level = 40;
    limits.relation_prentice_max_level = 29;
    limits.relation_moral_per_milestone = 10;
    limits.guild_hard_member_cap = 160;
    limits.guild_max_proposers = 10;
    limits.guild_max_guilds = 1024;
    limits.guild_name_max_bytes = 12;
    limits.guild_name_min_codepoints = 2;
    limits.guild_desc_max_bytes = 50;
    limits.guild_position_name_max_bytes = 23;
    limits.guild_create_min_level = 40;
    limits.guild_create_fee_copper = 500'000;
    limits.guild_war_min_members = 5;
    limits.guild_league_max_members = 8;
    limits.guild_max_elite = 10;
    limits.guild_max_office = 4;
    limits.guild_proposer_ttl_seconds = 259'200;
    limits.guild_league_invite_ttl_seconds = 300;
    limits.mail_inbox_cap = 15;
    limits.mail_max_items = 5;
    limits.mail_title_max_bytes = 20;
    limits.mail_text_max_bytes = 253;
    limits.mail_send_min_level = 50;
    limits.mail_send_fee_copper = 2000;
    limits.mail_expire_seconds = 2'592'000;
    limits.chat_max_bytes = 255;
    limits.chat_burst = 2;
    limits.chat_global_interval_ms = 500;
    limits.chat_global_burst = 4;
    limits.chat_repeat_window_seconds = 30;
    limits.chat_repeat_max = 2;
    limits.chat_custom_channel_members = 11;
    limits.chat_max_custom_channels = 3000;
    limits.rank_default_capacity = 100;
    limits.rank_snapshot_interval_seconds = 300;
    limits.rank_max_boards = 256;
    limits.notice_daily_broadcast_minute = 480;
    limits.notice_max_text_bytes = 1024;
    return limits;
}

[[nodiscard]] inline social::GuildRules sample_guild_rules() {
    social::GuildRules rules;
    rules.initial_member_cap = 60;
    rules.city_cost = 10'000'000;
    rules.message_cost = 1000;
    rules.battle_minutes = 120;
    rules.county_max_user = {70, 80, 90, 100, 110};
    rules.county_max_money = {10'000'000, 20'000'000, 40'000'000, 60'000'000, 80'000'000};
    rules.county_standard_money = {1'666'667, 3'333'333, 6'666'667, 13'333'333, 26'666'667};
    rules.league_max_count = 255;
    rules.league_rejoin_hours = 72;
    rules.league_create_cost = 1'000'000;
    return rules;
}

[[nodiscard]] inline social::RelationRules sample_relation_rules() {
    social::RelationRules rules;
    rules.password_intimacy = 500;
    rules.presence_intimacy = 10;
    return rules;
}

// Bảng người chơi giả: thêm/sửa bằng add; hostile khi cả hai có phe khác 0 và khác nhau.
class FakeDirectory final : public social::PlayerDirectory {
public:
    PlayerCard& add(std::uint64_t value, std::string name, std::uint16_t level = 50) {
        PlayerCard card;
        card.id = cid(value);
        card.name = std::move(name);
        card.level = level;
        card.online = true;
        card.sex = static_cast<std::uint8_t>(value % 2U);
        return cards_.insert_or_assign(card.id, std::move(card)).first->second;
    }

    PlayerCard* get(std::uint64_t value) {
        const auto found = cards_.find(cid(value));
        return found == cards_.end() ? nullptr : &found->second;
    }

    // Thẻ của một người đã thêm bằng add; id chưa thêm là lỗi của test (map::at ném).
    PlayerCard& at(std::uint64_t value) { return cards_.at(cid(value)); }

    [[nodiscard]] std::optional<PlayerCard> find(CharacterId id) const override {
        const auto found = cards_.find(id);
        if (found == cards_.end()) return std::nullopt;
        return found->second;
    }

    [[nodiscard]] std::optional<PlayerCard> find_by_name(std::string_view name) const override {
        for (const auto& [id, card] : cards_) {
            if (card.name == name) return card;
        }
        return std::nullopt;
    }

    [[nodiscard]] bool hostile(const PlayerCard& left, const PlayerCard& right) const override {
        return left.camp != 0 && right.camp != 0 && left.camp != right.camp;
    }

private:
    std::map<CharacterId, PlayerCard> cards_;
};

} // namespace game::test
