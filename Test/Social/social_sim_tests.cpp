// Mô phỏng 200 người chơi trên cả sáu sổ của lõi xã hội (đội, bang, quan hệ, thư, chat, xếp hạng) với một dãy
// thao tác ngẫu nhiên tất định (SplitMix64, hạt giống cố định): lập/rời/giải tán đội, lập bang và liên minh,
// kết bạn/kết hôn/bái sư, gửi thư có đồ và tiền thu, chat nhiều kênh, vào/ra mạng. Test không kiểm từng kết quả
// mà kiểm bất biến sau mỗi lô thao tác: không thành viên mồ côi, không đội/bang rỗng, không ai ở hai đội hay hai
// bang, quan hệ khớp hai chiều, không trùng mã thư, đồ và tiền được bảo toàn qua gửi/nhận/trả/hết hạn, kênh
// chat hợp lệ, bảng xếp hạng đúng thứ tự. Hai lượt chạy cùng hạt giống phải ra cùng một dãy sự kiện.
#include "ids/ids.hpp"
#include "social/chat.hpp"
#include "social/directory.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/mail.hpp"
#include "social/policy.hpp"
#include "social/rank.hpp"
#include "social/relation.hpp"
#include "social/team.hpp"
#include "social/types.hpp"
#include "social/wordfilter.hpp"
#include "social_port.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using social::ChatBook;
using social::ChatCatalog;
using social::Guild;
using social::GuildBook;
using social::GuildId;
using social::GuildPosition;
using social::MailBook;
using social::Mailbox;
using social::MailPayload;
using social::RankBook;
using social::RelationBook;
using social::RelationSheet;
using social::TeamBook;
using social::Tick;

constexpr std::uint64_t kPlayers = 200;
constexpr std::size_t kSteps = 30'000;
constexpr std::size_t kBatch = 250;
constexpr std::size_t kMaxViolations = 12;
constexpr social::Copper kStartMoney = 1'000'000;
constexpr std::uint64_t kExpireJump = 52'000'000;  // hơn 30 ngày ở 20 tick/giây: làm thư hết hạn

constexpr std::string_view kChannels =
    "# schema 1\n"
    "id\tchannel_name\tleader_text\tsend_interval_ms\tcost_kind_1\tcost_amount_1\tcost_kind_2\tcost_amount_2\tcost_kind_3\tcost_amount_3\tlevel_limit\n"
    "0\tnearby\tn\t3000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "1\tteam\tt\t1000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "2\tworld\tw\t180000\t1\t2\t2\t2\t-1\t0\t15\n"
    "3\twhisper\tp\t1000\t-1\t0\t-1\t0\t-1\t0\t6\n"
    "4\tsystem\ts\t15000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "5\tcustom\tc\t3000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "6\tguild\tg\t500\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "9\thelp\th\t3000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "12\tleague\te\t1000\t-1\t0\t-1\t0\t-1\t0\t0\n";

constexpr std::string_view kWords = "# schema 1\nid\ttext\ttype\n1\tfuck\t1\n2\tsb\t1\n";

constexpr std::string_view kRewards =
    "# schema 1\napprentice_level\texp_reward_no_guild\texp_reward_guild_1\trating_1\trating_2\trating_3\n"
    "30\t250000\t500000\t100\t80\t40\n45\t500000\t1000000\t100\t80\t40\n";
constexpr std::string_view kShare = "# schema 1\napprentice_rank\tmentor_exp_share\n1\t0\n10\t0.5\n";
constexpr std::string_view kWarPoints = "# schema 1\nid\tpoints\n0\t3\n1\t1\n2\t50\n";

constexpr std::array<std::string_view, 8> kTexts{"xin chào", "fuck", "bán đồ giá rẻ", "sb", "cứu với", "#{_MONEY99}", "50% off", "ok"};
constexpr std::array<std::uint8_t, 10> kChatChannels{0, 1, 2, 3, 5, 6, 9, 12, 4, 7};  // 4 chỉ máy chủ, 7 không khai báo

enum class Presence : std::uint8_t {
    kOnline,
    kDisconnected,  // rớt mạng: sổ quan hệ và hộp thư vẫn nạp, đội giữ chỗ một lúc
    kLoggedOut,     // thoát hẳn: sổ và hộp thư về kho
};

struct Stats {
    std::size_t ops = 0;
    std::size_t teams_formed = 0;
    std::size_t team_departures = 0;
    std::size_t guilds_created = 0;
    std::size_t guild_joins = 0;
    std::size_t guild_exits = 0;
    std::size_t leagues_created = 0;
    std::size_t friends_added = 0;
    std::size_t bonds = 0;
    std::size_t offline_changes = 0;
    std::size_t mails_received = 0;
    std::size_t mails_claimed = 0;
    std::size_t mails_returned = 0;
    std::size_t mails_expired = 0;
    std::size_t chat_messages = 0;
    std::size_t channels_created = 0;
    std::size_t rank_entered = 0;
    std::size_t logins = 0;
    std::size_t logouts = 0;
};

class Sim {
public:
    explicit Sim(std::uint64_t seed);

    [[nodiscard]] bool ready() const noexcept { return setup_problem_.empty(); }
    [[nodiscard]] const std::string& setup_problem() const noexcept { return setup_problem_; }
    void run(std::size_t steps);
    void drain();
    void check_all();

    [[nodiscard]] const std::vector<std::string>& violations() const noexcept { return violations_; }
    [[nodiscard]] std::uint64_t hash() const noexcept { return hash_; }
    [[nodiscard]] const Stats& stats() const noexcept { return stats_; }
    [[nodiscard]] std::size_t team_pending() const noexcept { return teams_.pending_count(); }
    [[nodiscard]] std::size_t relation_pending() const noexcept { return relations_.pending_count(); }

private:
    // ---- chọn người và dựng sự kiện -------------------------------------------------------------------------------
    std::uint64_t online_player();
    std::uint64_t neighbor(std::uint64_t player);
    std::uint64_t friend_or_neighbor(std::uint64_t player);
    std::uint64_t partner_for(std::uint64_t player, social::BondKind kind);
    [[nodiscard]] const Guild* guild_of_player(std::uint64_t player) const;
    std::uint64_t guild_chief_or(std::uint64_t player, const Guild& guild);
    std::uint64_t random_member(const Guild& guild);
    std::optional<GuildId> random_guild();
    void mix(std::uint64_t value) noexcept { hash_ = (hash_ ^ value) * 0x100000001B3ULL; }
    void violate(std::string what);
    void require(bool ok, std::string_view what) {
        if (!ok) setup_problem_ += std::string{what} + "; ";
    }
    // Ghi vào băm và thống kê; riêng sự kiện quan hệ ngoại tuyến thì áp luôn vào kho giả như world phải làm.
    template <class Result>
    void note(const Result& result);
    template <class Events>
    void note_list(const Events& events);
    std::optional<social::MailId> random_mail(std::uint64_t owner);
    social::CustomChannelId custom_of(std::uint64_t player);
    void observe(const social::TeamEvent& event);
    void observe(const social::GuildEvent& event);
    void observe(const social::RelationEvent& event);
    void observe(const social::MailEvent& event);
    void observe(const social::ChatEvent& event);
    void observe(const social::RankEvent& event);

    // ---- thao tác -------------------------------------------------------------------------------------------------
    void step();
    void tick_all();
    void team_op();
    void guild_op();
    void league_op(std::uint64_t player);
    void relation_op();
    void bond_flow(social::BondKind kind, std::uint64_t asker, std::uint64_t asked);
    void mail_op();
    void send_mail(std::uint64_t from, std::uint64_t to);
    void send_system_mail(std::uint64_t to);
    void chat_op();
    void rank_op();
    void session_op();
    void log_out(std::uint64_t player);
    void log_in(std::uint64_t player);
    void apply_cold(const social::RelationEvent& event);

    // ---- bất biến -------------------------------------------------------------------------------------------------
    void check_teams();
    void check_guilds();
    void check_relations();
    void check_mail();
    void check_chat();
    void check_presence();

    FakeDirectory dir_;
    social::AllowAllText allow_;
    social::Limits limits_ = sample_limits();
    TeamBook teams_;
    GuildBook guilds_;
    RelationBook relations_;
    MailBook mail_;
    std::unique_ptr<social::WordFilter> filter_;
    social::PassThroughFilter plain_;  // dự phòng khi bảng chữ cấm mẫu không nạp được (ready() sẽ báo)
    ChatBook chat_;
    RankBook rank_;
    social::MentorTable mentors_;
    social::WarPointTable war_table_;
    FakePort port_;
    SplitMix rng_;
    std::uint64_t now_ = 1000;
    std::vector<Presence> presence_;
    std::map<social::CharacterId, RelationSheet> cold_relations_;
    std::map<social::CharacterId, Mailbox> cold_mail_;
    std::set<std::uint64_t> initial_items_;
    std::set<std::uint64_t> created_items_;
    social::Copper initial_money_ = 0;
    social::Copper created_money_ = 0;
    std::uint64_t next_system_serial_ = 1'000'000;
    std::uint32_t max_custom_ = 0;
    std::vector<GuildId> guild_ids_;
    std::uint64_t counter_ = 0;
    std::vector<std::string> violations_;
    std::uint64_t hash_ = 0xCBF29CE484222325ULL;
    Stats stats_;
    std::string setup_problem_;
};

template <class Result>
void Sim::note(const Result& result) {
    mix(result.error ? 0x100U + static_cast<std::uint64_t>(*result.error) : 0U);
    note_list(result.events);
}

template <class Events>
void Sim::note_list(const Events& events) {
    mix(events.size());
    for (const auto& event : events) {
        mix(static_cast<std::uint64_t>(event.kind));
        observe(event);
    }
}

void Sim::observe(const social::TeamEvent& event) {
    using social::TeamEventKind;
    if (event.kind == TeamEventKind::kCreated) ++stats_.teams_formed;
    if (event.kind == TeamEventKind::kMemberLeft || event.kind == TeamEventKind::kKicked || event.kind == TeamEventKind::kDismissed) ++stats_.team_departures;
}

void Sim::observe(const social::GuildEvent& event) {
    using social::GuildEventKind;
    if (event.kind == GuildEventKind::kCreated) ++stats_.guilds_created;
    if (event.kind == GuildEventKind::kRecruited) ++stats_.guild_joins;
    if (event.kind == GuildEventKind::kLeft || event.kind == GuildEventKind::kExpelled || event.kind == GuildEventKind::kDismissed) ++stats_.guild_exits;
    if (event.kind == GuildEventKind::kLeagueCreated) ++stats_.leagues_created;
}

void Sim::observe(const social::RelationEvent& event) {
    using social::RelationEventKind;
    if (event.kind == RelationEventKind::kFriendAdded) ++stats_.friends_added;
    if (event.kind == RelationEventKind::kMarried || event.kind == RelationEventKind::kRecruited) ++stats_.bonds;
    if (event.kind == RelationEventKind::kOfflineChange) {
        ++stats_.offline_changes;
        apply_cold(event);
    }
}

void Sim::observe(const social::MailEvent& event) {
    using social::MailEventKind;
    if (event.kind == MailEventKind::kReceived) ++stats_.mails_received;
    if (event.kind == MailEventKind::kClaimed) ++stats_.mails_claimed;
    if (event.kind == MailEventKind::kReturned) ++stats_.mails_returned;
    if (event.kind == MailEventKind::kExpired) ++stats_.mails_expired;
}

void Sim::observe(const social::ChatEvent& event) {
    using social::ChatEventKind;
    if (event.kind == ChatEventKind::kMessage) ++stats_.chat_messages;
    if (event.kind == ChatEventKind::kChannelCreated) {
        ++stats_.channels_created;
        if (event.custom.value() > max_custom_) max_custom_ = event.custom.value();
    }
}

void Sim::observe(const social::RankEvent& event) {
    if (event.kind == social::RankEventKind::kEntered) ++stats_.rank_entered;
}

void Sim::violate(std::string what) {
    if (violations_.size() < kMaxViolations) violations_.push_back("bước " + std::to_string(stats_.ops) + ": " + std::move(what));
}

Sim::Sim(std::uint64_t seed)
    : teams_(limits_),
      guilds_(limits_, sample_guild_rules(), allow_),
      relations_(limits_, sample_relation_rules()),
      mail_(limits_, allow_),
      filter_(social::WordFilter::parse({.words_tsv = kWords, .reserved_tsv = {}, .extra_tsv = {}}).value_or(nullptr)),
      plain_(),
      chat_(limits_, ChatCatalog::parse(kChannels).value_or(ChatCatalog{}), filter_ ? static_cast<const social::TextFilter&>(*filter_) : plain_),
      rank_(limits_),
      mentors_(social::MentorTable::parse({.rewards_tsv = kRewards, .share_tsv = kShare}).value_or(social::MentorTable{})),
      war_table_(social::WarPointTable::parse(kWarPoints).value_or(social::WarPointTable{})),
      rng_{seed},
      presence_(kPlayers + 1, Presence::kOnline) {
    require(filter_ != nullptr, "bảng chữ cấm mẫu");
    require(!chat_.catalog().channels().empty(), "bảng kênh chat mẫu");
    require(!mentors_.rewards().empty(), "bảng thưởng sư đồ mẫu");
    require(war_table_.size() == 3, "bảng điểm bang chiến mẫu");
    for (std::uint64_t id = 1; id <= kPlayers; ++id) {
        social::PlayerCard& card = dir_.add(id, "p" + std::to_string(id), static_cast<std::uint16_t>(10 + rng_.below(71)));
        card.sect = static_cast<std::uint8_t>(id % 16U);
        card.camp = id % 10U == 0 ? 1 : (id % 10U == 1 ? 2 : 0);
        card.scene = social::SceneId{static_cast<std::uint16_t>(1U + (id % 5U))};
        require(relations_.load(cid(id), RelationSheet{}).has_value() && mail_.load(cid(id), Mailbox{}).has_value(), "nạp sổ ban đầu");
        FakePort::Inventory& inventory = port_.inventory[cid(id)];
        inventory.money = kStartMoney;
        initial_money_ += kStartMoney;
        for (std::uint64_t k = 1; k <= 5; ++k) {
            inventory.items.insert((id * 10) + k);
            initial_items_.insert((id * 10) + k);
        }
        inventory.pets.insert(100'000 + id);
    }
    for (std::uint32_t board = 1; board <= 2; ++board) {
        require(rank_.define(Tick{now_}, {.id = social::BoardId{board}, .name = "bảng", .capacity = 30}).has_value(), "khai báo bảng xếp hạng");
    }
}

// ---------------------------------------------------------------------------------------------------------------
// Chọn người
// ---------------------------------------------------------------------------------------------------------------

std::uint64_t Sim::online_player() {
    for (std::size_t attempt = 0; attempt < 16; ++attempt) {
        const std::uint64_t player = 1 + rng_.below(kPlayers);
        if (presence_.at(player) == Presence::kOnline) return player;
    }
    return 0;
}

// Người ở gần theo id (vòng quanh): làm các cặp lặp lại đủ nhiều để lời mời, kết bạn, thư có cơ hội thành công.
std::uint64_t Sim::neighbor(std::uint64_t player) {
    const std::uint64_t span = 1 + rng_.below(6);
    const std::uint64_t shift = rng_.chance(50) ? span : kPlayers - span;
    return 1 + ((player - 1 + shift) % kPlayers);
}

std::uint64_t Sim::friend_or_neighbor(std::uint64_t player) {
    const RelationSheet* sheet = relations_.sheet(cid(player));
    if (sheet != nullptr && !sheet->entries.empty() && rng_.chance(80)) return sheet->entries.at(rng_.below(sheet->entries.size())).id.value();
    return neighbor(player);
}

const Guild* Sim::guild_of_player(std::uint64_t player) const {
    const auto id = guilds_.guild_of(cid(player));
    return id ? guilds_.find(*id) : nullptr;
}

// Phần lớn lệnh của bang do bang chủ ra, để các lệnh chỉ bang chủ làm được có cơ hội thành công.
std::uint64_t Sim::guild_chief_or(std::uint64_t player, const Guild& guild) {
    if (!rng_.chance(70)) return player;
    for (const social::GuildMember& member : guild.members) {
        if (member.position == GuildPosition::kChief) return member.id.value();
    }
    return player;
}

std::uint64_t Sim::random_member(const Guild& guild) {
    return guild.members.empty() ? 0 : guild.members.at(rng_.below(guild.members.size())).id.value();
}

std::optional<GuildId> Sim::random_guild() {
    if (guild_ids_.empty()) return std::nullopt;
    return guild_ids_.at(rng_.below(guild_ids_.size()));
}

std::optional<social::MailId> Sim::random_mail(std::uint64_t owner) {
    const Mailbox* box = mail_.mailbox(cid(owner));
    if (box == nullptr || box->mails.empty()) return std::nullopt;
    return box->mails.at(rng_.below(box->mails.size())).id;
}

social::CustomChannelId Sim::custom_of(std::uint64_t player) {
    if (max_custom_ == 0) return {};
    if (rng_.chance(70)) {
        for (std::uint32_t id = 1; id <= max_custom_; ++id) {
            const social::CustomChannel* channel = chat_.find_channel(social::CustomChannelId{id});
            if (channel != nullptr && std::ranges::find(channel->members, cid(player)) != channel->members.end()) return channel->id;
        }
    }
    return social::CustomChannelId{1 + static_cast<std::uint32_t>(rng_.below(max_custom_ + 1ULL))};
}

// ---------------------------------------------------------------------------------------------------------------
// Thao tác
// ---------------------------------------------------------------------------------------------------------------

void Sim::run(std::size_t steps) {
    for (std::size_t done = 0; done < steps; ++done) {
        step();
        if ((done + 1) % kBatch == 0) check_all();
    }
}

void Sim::step() {
    now_ += 1 + rng_.below(40);
    if (rng_.below(4000) == 0) now_ += kExpireJump + rng_.below(1000);
    const std::uint64_t pick = rng_.below(100);
    if (pick < 20) {
        team_op();
    } else if (pick < 38) {
        guild_op();
    } else if (pick < 58) {
        relation_op();
    } else if (pick < 72) {
        mail_op();
    } else if (pick < 86) {
        chat_op();
    } else if (pick < 92) {
        rank_op();
    } else {
        session_op();
    }
    if (stats_.ops % 64 == 0) tick_all();
    ++stats_.ops;
}

void Sim::tick_all() {
    const Tick now{now_};
    note_list(teams_.tick(now));
    note_list(guilds_.tick(now));
    relations_.tick(now);
    note_list(mail_.tick(now));
    chat_.tick(now);
    note_list(rank_.tick(now));
}

void Sim::team_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    const std::uint64_t b = neighbor(a);
    const auto team = teams_.team_of(cid(a));
    // Phần lớn lệnh của đội do đội trưởng ra, để các lệnh chỉ đội trưởng làm được có cơ hội thành công.
    const std::uint64_t leader = team && rng_.chance(70) ? teams_.leader_of(*team).value_or(cid(a)).value() : a;
    const social::Team* mine = team ? teams_.find(*team) : nullptr;
    const std::uint64_t member = mine != nullptr && !mine->members.empty() ? mine->members.at(rng_.below(mine->members.size())).id.value() : b;
    switch (rng_.below(16)) {
    case 0:
    case 1:
    case 2: {
        const auto asked = teams_.invite(now, dir_, cid(a), cid(b));
        note(asked);
        for (const social::TeamEvent& event : asked.events) {
            if (event.audience.empty() || !rng_.chance(85)) continue;
            if (event.kind == social::TeamEventKind::kInviteAsk) {
                note(teams_.answer_invite(now, dir_, event.audience.front(), event.subject, rng_.chance(75)));
            } else if (event.kind == social::TeamEventKind::kLeaderAskInvite) {
                note(teams_.leader_answer_invite(now, dir_, event.audience.front(), event.subject, event.other, rng_.chance(75)));
            }
        }
        break;
    }
    case 3: {
        const auto applied = teams_.apply(now, dir_, cid(a), cid(b));
        note(applied);
        for (const social::TeamEvent& event : applied.events) {
            if (event.kind == social::TeamEventKind::kApplyAsk && !event.audience.empty() && rng_.chance(85)) {
                note(teams_.answer_apply(now, dir_, event.audience.front(), event.subject, rng_.chance(75)));
            }
        }
        break;
    }
    case 4: note(teams_.leave(cid(a))); break;
    case 5:
        if (rng_.chance(40)) note(teams_.dismiss(cid(leader)));
        break;
    case 6: note(teams_.kick(cid(leader), cid(member))); break;
    case 7: note(teams_.appoint(cid(leader), cid(member))); break;
    case 8: note(teams_.set_exp_mode(cid(leader), static_cast<social::ExpMode>(rng_.below(3)))); break;
    case 9: note(teams_.set_loot_mode(cid(leader), static_cast<social::LootMode>(rng_.below(4)))); break;
    case 10: {
        const auto hp_max = static_cast<std::uint32_t>(500 + rng_.below(500));
        const social::Vitals vitals{.hp = static_cast<std::uint32_t>(rng_.below(hp_max + 1ULL)), .hp_max = hp_max, .mp = 10, .mp_max = 100, .dead = rng_.chance(5)};
        note(teams_.report_vitals(cid(a), vitals));
        break;
    }
    case 11: note(teams_.set_scene(cid(a), social::SceneId{static_cast<std::uint16_t>(1U + rng_.below(6))})); break;
    case 12: note(teams_.start_follow(cid(a))); break;
    case 13: note(teams_.stop_follow(cid(a))); break;
    case 14:
        if (mine != nullptr) {
            std::vector<social::CharacterId> eligible;
            eligible.reserve(mine->members.size());
            for (const social::TeamMember& each : mine->members) eligible.push_back(each.id);
            mix(teams_.next_looter(mine->id, eligible).value_or(social::CharacterId{}).value());
        }
        break;
    default:
        mix(teams_.applicants_of(team.value_or(social::TeamId{})).size() + teams_.inviters_of(cid(a)).size());
        break;
    }
}

void Sim::guild_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    const Guild* mine = guild_of_player(a);
    const std::uint64_t actor = mine != nullptr ? guild_chief_or(a, *mine) : a;
    const std::uint64_t target = mine != nullptr ? random_member(*mine) : neighbor(a);
    const auto position = static_cast<GuildPosition>(1 + rng_.below(10));  // 1 và 10 là giá trị thù địch
    switch (rng_.below(26)) {
    case 0:
    case 1: {
        const auto made = guilds_.create(now, dir_, cid(a), "G" + std::to_string(++counter_), "tông chỉ bang", 10'000'000);
        note(made);
        if (made.ok() && !made.events.empty()) guild_ids_.push_back(made.events.front().guild);
        break;
    }
    case 2:
    case 3:
    case 4: {
        const auto gid = random_guild();
        if (!gid) break;
        const auto applied = guilds_.apply(now, dir_, cid(a), *gid);
        note(applied);
        for (const social::GuildEvent& event : applied.events) {
            if (event.kind == social::GuildEventKind::kApplied && !event.audience.empty() && rng_.chance(85)) {
                note(guilds_.answer_application(now, dir_, event.audience.at(rng_.below(event.audience.size())), event.subject, rng_.chance(80)));
            }
        }
        break;
    }
    case 5: note(guilds_.cancel_application(cid(a))); break;
    case 6: note(guilds_.expel(cid(actor), cid(target))); break;
    case 7: note(guilds_.leave(cid(a))); break;
    case 8: note(guilds_.appoint(cid(actor), cid(target), position)); break;
    case 9: note(guilds_.toggle_power(cid(actor), cid(target), static_cast<std::uint16_t>(1U << rng_.below(12)))); break;
    case 10: note(guilds_.demise(cid(actor))); break;
    case 11:
        if (rng_.chance(30)) note(guilds_.dismiss(cid(actor)));
        break;
    case 12: note(guilds_.set_description(cid(actor), "mô tả mới của bang")); break;
    case 13: note(guilds_.rename_position(cid(actor), position, "Chức vụ mới")); break;
    case 14: note(guilds_.deposit(cid(a), 1 + static_cast<social::Copper>(rng_.below(500'000)), 5'000'000)); break;
    case 15: note(guilds_.withdraw(cid(actor), 1 + static_cast<social::Copper>(rng_.below(300'000)))); break;
    case 16:
        if (const auto enemy = random_guild()) note(guilds_.declare_war(now, cid(actor), *enemy));
        break;
    case 17:
        if (const auto gid = random_guild()) {
            note(guilds_.add_war_points(now, *gid, static_cast<std::uint32_t>(1 + rng_.below(4)), static_cast<std::int64_t>(1 + rng_.below(3)), war_table_));
        }
        break;
    case 18:
    case 19:
    case 20:
    case 21: league_op(a); break;
    case 22:
        if (const auto card = dir_.find(cid(a))) guilds_.refresh_member(*card);
        break;
    default: break;
    }
}

void Sim::league_op(std::uint64_t player) {
    const Tick now{now_};
    const Guild* mine = guild_of_player(player);
    if (mine == nullptr) return;
    const std::uint64_t actor = guild_chief_or(player, *mine);
    const auto other = random_guild();
    switch (rng_.below(6)) {
    case 0: note(guilds_.league_create(now, cid(actor), "L" + std::to_string(++counter_), 5'000'000)); break;
    case 1:
    case 2: {
        if (!other) break;
        const auto invited = guilds_.league_invite(now, cid(actor), *other);
        note(invited);
        for (const social::GuildEvent& event : invited.events) {
            if (event.kind == social::GuildEventKind::kLeagueInvite && !event.audience.empty() && rng_.chance(80)) {
                note(guilds_.league_answer(now, event.audience.front(), event.guild, rng_.chance(80)));
            }
        }
        break;
    }
    case 3: note(guilds_.league_leave(now, cid(actor))); break;
    case 4:
        if (other) note(guilds_.league_kick(cid(actor), *other));
        break;
    default:
        if (rng_.chance(30)) note(guilds_.league_disband(cid(actor)));
        break;
    }
}

void Sim::relation_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    const std::uint64_t b = friend_or_neighbor(a);
    switch (rng_.below(27)) {
    case 0:
    case 1:
    case 2:
    case 3: bond_flow(social::BondKind::kFriend, a, b); break;
    case 4: note(relations_.remove(cid(a), cid(b), rng_.chance(50))); break;
    case 5: note(relations_.blacklist(dir_, cid(a), cid(b))); break;
    case 6: note(relations_.note_enemy(dir_, cid(a), cid(b))); break;
    case 7: note(relations_.note_temp(dir_, cid(a), cid(b))); break;
    case 8: note(relations_.move_group(cid(a), cid(b), static_cast<std::uint8_t>(rng_.below(5)))); break;
    case 9: note(relations_.set_mood(dir_, cid(a), kTexts.at(rng_.below(kTexts.size())))); break;
    case 10:
    case 11:
    case 12: note(relations_.add_point(cid(a), cid(b), static_cast<std::int32_t>(rng_.below(2500)) - 300)); break;
    case 13:
    case 14:
    case 15: bond_flow(social::BondKind::kMarry, a, partner_for(a, social::BondKind::kMarry)); break;
    case 16:
    case 17:
    case 18:
    case 19: bond_flow(social::BondKind::kRecruit, a, partner_for(a, social::BondKind::kRecruit)); break;
    case 20:
    case 21: bond_flow(social::BondKind::kApprentice, a, partner_for(a, social::BondKind::kApprentice)); break;
    case 22: note(relations_.divorce(cid(a))); break;
    case 23: note(relations_.leave_master(now, cid(a))); break;
    case 24: note(relations_.expel_prentice(cid(a), cid(b))); break;
    case 25: note(relations_.on_prentice_level(dir_, mentors_, cid(a), static_cast<std::uint16_t>(25 + rng_.below(30)))); break;
    default: note_list(relations_.on_presence(dir_, cid(a), rng_.chance(50))); break;
    }
}

// Bạn của `player` hợp với loại ràng buộc (khác giới để kết hôn; đủ cấp sư phụ/đồ đệ): nâng tỉ lệ thành công của các
// luồng hiếm để mô phỏng thật sự chạm tới chúng. Không có bạn hợp thì quay về chọn thường.
std::uint64_t Sim::partner_for(std::uint64_t player, social::BondKind kind) {
    const RelationSheet* sheet = relations_.sheet(cid(player));
    const auto me = dir_.find(cid(player));
    if (sheet != nullptr && me) {
        for (const social::RelationEntry& entry : sheet->entries) {
            const auto other = dir_.find(entry.id);
            if (entry.kind != social::RelationKind::kFriend || !other) continue;
            bool fits = false;
            if (kind == social::BondKind::kMarry) fits = me->sex != other->sex;
            if (kind == social::BondKind::kRecruit) fits = me->level >= 40 && other->level <= 29;
            if (kind == social::BondKind::kApprentice) fits = me->level <= 29 && other->level >= 40;
            if (fits && rng_.chance(70)) return entry.id.value();
        }
    }
    return friend_or_neighbor(player);
}

void Sim::bond_flow(social::BondKind kind, std::uint64_t asker, std::uint64_t asked) {
    const Tick now{now_};
    const auto request = relations_.request(now, dir_, kind, cid(asker), cid(asked));
    note(request);
    for (const social::RelationEvent& event : request.events) {
        if (event.kind == social::RelationEventKind::kBondAsk && !event.audience.empty() && rng_.chance(85)) {
            note(relations_.answer(now, dir_, kind, event.audience.front(), event.subject, rng_.chance(80)));
        }
    }
}

void Sim::mail_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    switch (rng_.below(13)) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4: send_mail(a, friend_or_neighbor(a)); break;
    case 5: send_system_mail(friend_or_neighbor(a)); break;
    case 6:
        if (const auto id = random_mail(a)) note(mail_.mark_read(cid(a), *id));
        break;
    case 7:
        if (const auto id = random_mail(a)) note(mail_.remove(cid(a), *id));
        break;
    case 8:
    case 9:
        if (const auto id = random_mail(a)) note(mail_.claim(now, port_, cid(a), *id));
        break;
    case 10:
        if (const auto id = random_mail(a)) note(mail_.return_to_sender(now, cid(a), *id));
        break;
    default: break;
    }
}

void Sim::send_mail(std::uint64_t from, std::uint64_t to) {
    MailPayload payload;
    const FakePort::Inventory& have = port_.inventory[cid(from)];
    std::size_t skip = rng_.below(have.items.size() + 1ULL);
    for (const std::uint64_t serial : have.items) {
        if (skip > 0) {
            --skip;
            continue;
        }
        if (payload.items.size() >= 2) break;
        payload.items.push_back({.serial = ids::ItemSerial{serial}, .item = ids::ItemTemplateId{1000}, .count = 1});
    }
    // Thỉnh thoảng đính kèm món không phải của mình: pha giữ chỗ của hành trang phải từ chối, không gì đổi chỗ.
    if (rng_.chance(5)) payload.items.push_back({.serial = ids::ItemSerial{9'000'000 + rng_.below(100)}, .item = ids::ItemTemplateId{1000}, .count = 1});
    if (!have.pets.empty() && rng_.chance(20)) payload.pet = ids::PetId{*have.pets.begin()};
    payload.money = static_cast<social::Copper>(rng_.below(3000));
    if (payload.has_goods() && rng_.chance(25)) payload.cod = 1 + static_cast<social::Copper>(rng_.below(2000));
    const social::MailRoute route{.sender = cid(from), .recipient = cid(to)};
    note(mail_.send(Tick{now_}, dir_, relations_, port_, route, {.title = "tiêu đề", .text = kTexts.at(rng_.below(kTexts.size())), .payload = std::move(payload)}));
}

void Sim::send_system_mail(std::uint64_t to) {
    MailPayload payload;
    std::uint64_t serial = 0;
    if (rng_.chance(50)) {
        serial = next_system_serial_++;
        payload.items.push_back({.serial = ids::ItemSerial{serial}, .item = ids::ItemTemplateId{2000}, .count = 1});
    }
    payload.money = 1 + static_cast<social::Copper>(rng_.below(5000));
    const social::Copper money = payload.money;
    const auto sent = mail_.send_system(Tick{now_}, cid(to), {.title = "hệ thống", .text = "quà tặng", .payload = std::move(payload)});
    note(sent);
    // Thư hệ thống thành công là đồ và tiền mới sinh ra: tính vào sổ bảo toàn.
    if (sent.ok()) {
        created_money_ += money;
        if (serial != 0) created_items_.insert(serial);
    }
}

void Sim::chat_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    switch (rng_.below(14)) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7: {
        const social::ChannelId channel{kChatChannels.at(rng_.below(kChatChannels.size()))};
        const std::string target = "p" + std::to_string(neighbor(a));
        social::SendRequest request{.sender = cid(a), .channel = channel, .text = kTexts.at(rng_.below(kTexts.size())), .target_name = {}, .custom = {}, .wallet = {100, 100, 100}};
        if (channel.value() == 3) request.target_name = target;
        if (channel.value() == 5) request.custom = custom_of(a);
        const social::ChatWorld world{.directory = &dir_, .teams = &teams_, .guilds = &guilds_, .relations = &relations_};
        note(chat_.send(now, world, request));
        break;
    }
    case 8: note(chat_.create_channel(dir_, cid(a))); break;
    case 9: note(chat_.invite(dir_, cid(a), cid(neighbor(a)))); break;
    case 10: note(chat_.kick(cid(a), cid(neighbor(a)))); break;
    case 11: note(chat_.leave(cid(a), custom_of(a))); break;
    case 12:
        if (rng_.chance(40)) note(chat_.dismiss(cid(a)));
        break;
    default: chat_.mute(now, cid(neighbor(a)), Tick{now_ + rng_.below(400)}); break;
    }
}

void Sim::rank_op() {
    const std::uint64_t a = online_player();
    if (a == 0) return;
    const Tick now{now_};
    const social::BoardId board{static_cast<std::uint32_t>(1 + rng_.below(3))};  // bảng 3 không tồn tại
    switch (rng_.below(8)) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4: {
        const social::RankSubject subject{.id = cid(a), .name = "p" + std::to_string(a), .sect = static_cast<std::uint8_t>(a % 16U), .sex = static_cast<std::uint8_t>(a % 2U)};
        note(rank_.submit(now, board, subject, static_cast<std::int64_t>(rng_.below(2000))));
        break;
    }
    case 5: note_list(rank_.forget(cid(a))); break;
    case 6: note(rank_.settle(now, board)); break;
    default: note_list(rank_.tick(now)); break;
    }
}

void Sim::session_op() {
    const std::uint64_t player = 1 + rng_.below(kPlayers);
    switch (presence_.at(player)) {
    case Presence::kOnline:
        if (rng_.chance(50)) {
            dir_.at(player).online = false;
            presence_.at(player) = Presence::kDisconnected;
            note_list(teams_.on_disconnect(Tick{now_}, cid(player)));
        } else {
            log_out(player);
        }
        break;
    case Presence::kDisconnected:
        if (rng_.chance(60)) {
            dir_.at(player).online = true;
            presence_.at(player) = Presence::kOnline;
            note_list(teams_.on_reconnect(cid(player)));
        } else {
            log_out(player);
        }
        break;
    case Presence::kLoggedOut: log_in(player); break;
    }
}

void Sim::log_out(std::uint64_t player) {
    const social::CharacterId id = cid(player);
    note_list(relations_.on_presence(dir_, id, false));
    dir_.at(player).online = false;
    note_list(teams_.on_logout(id));
    note_list(chat_.on_logout(id));
    if (auto sheet = relations_.unload(id)) cold_relations_[id] = std::move(*sheet);
    if (auto box = mail_.unload(id)) cold_mail_[id] = std::move(*box);
    presence_.at(player) = Presence::kLoggedOut;
    ++stats_.logouts;
}

void Sim::log_in(std::uint64_t player) {
    const social::CharacterId id = cid(player);
    RelationSheet sheet;
    if (const auto found = cold_relations_.find(id); found != cold_relations_.end()) {
        sheet = std::move(found->second);
        cold_relations_.erase(found);
    }
    Mailbox box;
    if (const auto found = cold_mail_.find(id); found != cold_mail_.end()) {
        box = std::move(found->second);
        cold_mail_.erase(found);
    }
    if (const auto loaded = relations_.load(id, std::move(sheet)); !loaded) violate("sổ quan hệ lưu bị từ chối khi nạp lại: " + loaded.error());
    if (const auto loaded = mail_.load(id, std::move(box)); !loaded) violate("hộp thư lưu bị từ chối khi nạp lại: " + loaded.error());
    dir_.at(player).online = true;
    presence_.at(player) = Presence::kOnline;
    ++stats_.logins;
    note_list(relations_.on_presence(dir_, id, true));
}

// Việc world phải làm khi nhận kOfflineChange: sửa sổ đã lưu của chủ sổ ngoại tuyến.
void Sim::apply_cold(const social::RelationEvent& event) {
    const auto found = cold_relations_.find(event.other);
    if (found == cold_relations_.end()) {
        violate("kOfflineChange cho chủ sổ không nằm trong kho");
        return;
    }
    static_cast<void>(social::apply_offline_change(limits_, found->second, event));
}

void Sim::drain() {
    // Nhảy xa quá mọi hạn (lời mời, giữ chỗ ngoại tuyến, đơn xin vào bang, thư): mọi thứ treo phải được dọn.
    now_ += 3 * kExpireJump;
    for (std::size_t round = 0; round < 3; ++round) {
        tick_all();
        now_ += 1000;
    }
    for (std::uint64_t player = 1; player <= kPlayers; ++player) {
        if (presence_.at(player) == Presence::kLoggedOut) log_in(player);
    }
}

// ---------------------------------------------------------------------------------------------------------------
// Bất biến
// ---------------------------------------------------------------------------------------------------------------

void Sim::check_all() {
    check_presence();
    check_teams();
    check_guilds();
    check_relations();
    check_mail();
    check_chat();
    if (const auto done = rank_.validate(); !done) violate("RankBook::validate: " + done.error());
}

void Sim::check_presence() {
    for (std::uint64_t player = 1; player <= kPlayers; ++player) {
        const social::CharacterId id = cid(player);
        const Presence state = presence_.at(player);
        const bool loaded = relations_.sheet(id) != nullptr && mail_.mailbox(id) != nullptr;
        if (state == Presence::kLoggedOut) {
            if (loaded || teams_.team_of(id) || !cold_relations_.contains(id) || !cold_mail_.contains(id)) violate("người đã thoát vẫn còn trạng thái trực tuyến: " + std::to_string(player));
        } else if (!loaded || cold_relations_.contains(id) || cold_mail_.contains(id)) {
            violate("người còn trong game mà sổ không nạp: " + std::to_string(player));
        }
        if ((state == Presence::kOnline) != dir_.at(player).online) violate("bảng người chơi lệch trạng thái: " + std::to_string(player));
    }
}

void Sim::check_teams() {
    if (const auto done = teams_.validate(); !done) violate("TeamBook::validate: " + done.error());
    std::set<social::TeamId> reachable;
    for (std::uint64_t player = 1; player <= kPlayers; ++player) {
        const auto team_id = teams_.team_of(cid(player));
        if (!team_id) continue;
        const social::Team* team = teams_.find(*team_id);
        if (team == nullptr) {
            violate("thành viên mồ côi, đội không tồn tại: " + std::to_string(player));
            continue;
        }
        reachable.insert(*team_id);
        if (std::ranges::none_of(team->members, [player](const social::TeamMember& each) { return each.id.value() == player; })) {
            violate("team_of trỏ tới đội không có mình: " + std::to_string(player));
        }
    }
    if (reachable.size() != teams_.team_count()) violate("có đội rỗng hoặc không ai tra ra được: " + std::to_string(teams_.team_count()) + " so với " + std::to_string(reachable.size()));
    for (const social::TeamId id : reachable) {
        const social::Team* team = teams_.find(id);
        if (team == nullptr || team->members.empty()) {
            violate("đội rỗng");
            continue;
        }
        if (std::cmp_greater(team->members.size(), limits_.team_max_members)) violate("đội quá đông");
        if (teams_.leader_of(id) != std::optional<social::CharacterId>{team->members.front().id}) violate("đội trưởng không đứng đầu danh sách");
        for (const social::TeamMember& each : team->members) {
            if (teams_.team_of(each.id) != std::optional<social::TeamId>{id}) violate("thành viên thuộc hai đội");
        }
    }
}

void Sim::check_guilds() {
    if (const auto done = guilds_.validate(); !done) violate("GuildBook::validate: " + done.error());
    std::set<GuildId> reachable;
    for (std::uint64_t player = 1; player <= kPlayers; ++player) {
        const auto guild_id = guilds_.guild_of(cid(player));
        if (!guild_id) continue;
        const Guild* guild = guilds_.find(*guild_id);
        if (guild == nullptr || guilds_.member(cid(player)) == nullptr) {
            violate("thành viên bang mồ côi: " + std::to_string(player));
            continue;
        }
        reachable.insert(*guild_id);
        if (guilds_.proposer_guild_of(cid(player))) violate("vừa là thành viên vừa là người xin vào bang: " + std::to_string(player));
    }
    if (reachable.size() != guilds_.guild_count()) violate("có bang rỗng hoặc không ai tra ra được");
    std::set<social::LeagueId> leagues;
    for (const GuildId id : reachable) {
        const Guild* guild = guilds_.find(id);
        if (guild == nullptr) continue;
        if (std::cmp_greater(static_cast<std::int64_t>(guild->members.size()), guilds_.member_cap(*guild))) violate("bang vượt trần thành viên");
        if (guild->funds > guilds_.funds_cap(*guild)) violate("quỹ bang vượt trần");
        if (std::ranges::count_if(guild->members, [](const social::GuildMember& each) { return each.position == GuildPosition::kChief; }) != 1) violate("bang không có đúng một bang chủ");
        if (guilds_.find_by_name(guild->name) != guild) violate("chỉ mục tên bang lệch");
        for (const social::GuildMember& each : guild->members) {
            if (guilds_.guild_of(each.id) != std::optional<GuildId>{id}) violate("thành viên thuộc hai bang");
        }
        if (const social::League* league = guilds_.league_of(id)) leagues.insert(league->id);
    }
    if (leagues.size() != guilds_.league_count()) violate("có liên minh rỗng hoặc không bang nào tra ra được");
    for (const social::LeagueId id : leagues) {
        const social::League* league = guilds_.find_league(id);
        if (league == nullptr || league->members.empty() || league->members.front() != league->leader) {
            violate("liên minh sai hình dạng");
            continue;
        }
        for (const GuildId each : league->members) {
            const social::League* back = guilds_.league_of(each);
            if (!reachable.contains(each) || back == nullptr || back->id != id) violate("liên minh trỏ vào bang không tồn tại hoặc ở liên minh khác");
        }
    }
}

[[nodiscard]] const social::RelationEntry* entry_of(const RelationSheet& sheet, social::CharacterId id) {
    for (const social::RelationEntry& entry : sheet.entries) {
        if (entry.id == id) return &entry;
    }
    return nullptr;
}

[[nodiscard]] social::RelationKind mirror(social::RelationKind kind) {
    if (kind == social::RelationKind::kMaster) return social::RelationKind::kPrentice;
    if (kind == social::RelationKind::kPrentice) return social::RelationKind::kMaster;
    return kind;
}

void Sim::check_relations() {
    if (const auto done = relations_.validate(); !done) violate("RelationBook::validate: " + done.error());
    std::size_t expected_loaded = 0;
    for (std::uint64_t player = 1; player <= kPlayers; ++player) expected_loaded += presence_.at(player) == Presence::kLoggedOut ? 0U : 1U;
    if (relations_.loaded_count() != expected_loaded) violate("số sổ quan hệ đang nạp lệch số người còn trong game");
    // Sổ trong kho cũng phải khớp hai chiều với sổ của bạn (đang nạp hay trong kho): nếu không, lúc vào lại validate() mới hỏng.
    for (const auto& [owner, cold] : cold_relations_) {
        for (const social::RelationEntry& entry : cold.entries) {
            if (entry.kind == social::RelationKind::kBlack || entry.kind == social::RelationKind::kEnemy || entry.kind == social::RelationKind::kTemp) continue;
            const RelationSheet* peer = relations_.sheet(entry.id);
            if (peer == nullptr) {
                const auto found = cold_relations_.find(entry.id);
                peer = found == cold_relations_.end() ? nullptr : &found->second;
            }
            const social::RelationEntry* back = peer == nullptr ? nullptr : entry_of(*peer, owner);
            if (back == nullptr || back->kind != mirror(entry.kind) || back->point != entry.point) {
                violate("sổ quan hệ trong kho lệch hai chiều: " + std::to_string(owner.value()) + " - " + std::to_string(entry.id.value()));
            }
        }
    }
}

void Sim::check_mail() {
    if (const auto done = mail_.validate(); !done) violate("MailBook::validate: " + done.error());
    std::map<std::uint64_t, int> item_places;
    std::map<std::uint64_t, int> pet_places;
    std::set<std::uint64_t> mail_ids;
    social::Copper money = port_.fees_burned;
    const auto scan = [&](const Mailbox& box) {
        if (std::cmp_greater(box.mails.size(), limits_.mail_inbox_cap)) violate("hộp thư quá trần");
        for (const social::Mail& entry : box.mails) {
            if (!mail_ids.insert(entry.id.value()).second) violate("trùng mã thư " + std::to_string(entry.id.value()));
            for (const social::MailItem& item : entry.payload.items) ++item_places[item.serial.value()];
            if (entry.payload.pet.value() != 0) ++pet_places[entry.payload.pet.value()];
            money += entry.payload.money;
        }
    };
    for (std::uint64_t player = 1; player <= kPlayers; ++player) {
        if (const Mailbox* box = mail_.mailbox(cid(player))) scan(*box);
    }
    for (const auto& [owner, box] : cold_mail_) scan(box);
    for (const auto& [owner, inventory] : port_.inventory) {
        money += inventory.money;
        for (const std::uint64_t serial : inventory.items) ++item_places[serial];
        for (const std::uint64_t pet : inventory.pets) ++pet_places[pet];
    }
    std::size_t wanted = initial_items_.size() + created_items_.size();
    if (item_places.size() != wanted) violate("số vật phẩm không bảo toàn: " + std::to_string(item_places.size()) + " so với " + std::to_string(wanted));
    for (const auto& [serial, places] : item_places) {
        if (places != 1 || (!initial_items_.contains(serial) && !created_items_.contains(serial))) violate("vật phẩm " + std::to_string(serial) + " ở " + std::to_string(places) + " nơi hoặc không rõ nguồn");
    }
    wanted = kPlayers;
    if (pet_places.size() != wanted) violate("số trân thú không bảo toàn");
    for (const auto& [pet, places] : pet_places) {
        if (places != 1) violate("trân thú " + std::to_string(pet) + " ở " + std::to_string(places) + " nơi");
    }
    if (money != initial_money_ + created_money_) violate("tiền không bảo toàn: " + std::to_string(money) + " so với " + std::to_string(initial_money_ + created_money_));
    if (!port_.held.empty()) violate("còn giữ chỗ chưa chốt hoặc nhả");
}

void Sim::check_chat() {
    if (const auto done = chat_.validate(); !done) violate("ChatBook::validate: " + done.error());
    std::size_t alive = 0;
    for (std::uint32_t id = 1; id <= max_custom_; ++id) {
        const social::CustomChannel* channel = chat_.find_channel(social::CustomChannelId{id});
        if (channel == nullptr) continue;
        ++alive;
        if (channel->members.empty() || std::cmp_greater(channel->members.size(), limits_.chat_custom_channel_members)) {
            violate("kênh tự lập rỗng hoặc quá đông");
            continue;
        }
        if (chat_.channel_owned_by(channel->members.front()) != std::optional<social::CustomChannelId>{channel->id}) violate("chủ kênh không tra ra kênh của mình");
        for (const social::CharacterId member : channel->members) {
            if (member.value() == 0 || member.value() > kPlayers || presence_.at(member.value()) == Presence::kLoggedOut) violate("thành viên kênh đã thoát hoặc ngoài miền");
        }
    }
    if (alive != chat_.channel_count()) violate("số kênh tự lập lệch");
}

// ---------------------------------------------------------------------------------------------------------------
// Ca test
// ---------------------------------------------------------------------------------------------------------------

constexpr std::uint64_t kSeed = 20261014;

void invariants_hold(Context& context) {
    Sim sim(kSeed);
    context.expect(sim.ready(), sim.setup_problem());
    sim.run(kSteps);
    sim.drain();
    sim.check_all();
    for (const std::string& problem : sim.violations()) context.expect(false, problem);
    context.expect(sim.violations().empty(), "không vi phạm bất biến nào sau 30 nghìn thao tác và dọn hạn");
    context.expect(sim.team_pending() == 0 && sim.relation_pending() == 0, "sau khi nhảy qua mọi hạn, không còn lời mời hay lời chờ treo");

    const Stats& stats = sim.stats();
    // Một dòng tóm tắt để người đọc thấy mô phỏng đã chạm tới những gì (không phải điều kiện đạt).
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in một dòng tóm tắt như test.hpp, không kéo <format> vào test
    static_cast<void>(std::fprintf(stdout,
        "[mô phỏng] %zu thao tác: đội lập %zu rời %zu; bang lập %zu vào %zu ra %zu liên minh %zu; bạn %zu ràng buộc %zu đổi ngoại tuyến %zu; "
        "thư nhận %zu lấy %zu trả %zu hết hạn %zu; chat %zu kênh %zu; xếp hạng %zu; vào %zu ra %zu\n",
        stats.ops, stats.teams_formed, stats.team_departures, stats.guilds_created, stats.guild_joins, stats.guild_exits, stats.leagues_created,
        stats.friends_added, stats.bonds, stats.offline_changes, stats.mails_received, stats.mails_claimed, stats.mails_returned, stats.mails_expired,
        stats.chat_messages, stats.channels_created, stats.rank_entered, stats.logins, stats.logouts));
    // Mô phỏng chỉ có nghĩa khi nó thật sự chạm vào từng sổ: các ngưỡng dưới đây thấp hơn nhiều so với số đo.
    context.expect(stats.teams_formed >= 50 && stats.team_departures >= 50, "đã lập và giải tán nhiều đội");
    context.expect(stats.guilds_created >= 5 && stats.guild_joins >= 20 && stats.guild_exits >= 5 && stats.leagues_created >= 5, "đã lập bang và liên minh, nhận và mất thành viên");
    context.expect(stats.friends_added >= 60 && stats.bonds >= 5, "đã kết nhiều cặp bạn và có kết hôn, bái sư");
    context.expect(stats.offline_changes >= 5, "đã phát và áp sự kiện đổi quan hệ với người ngoại tuyến");
    context.expect(stats.mails_received >= 100 && stats.mails_claimed >= 10, "đã chuyển thư và lấy đồ đính kèm");
    context.expect(stats.mails_returned >= 10 && stats.mails_expired >= 20, "đã trả thư và để thư hết hạn");
    context.expect(stats.chat_messages >= 300 && stats.channels_created >= 10, "đã chat và lập kênh tự lập");
    context.expect(stats.rank_entered >= 30, "đã đưa người vào bảng xếp hạng");
    context.expect(stats.logins >= 20 && stats.logouts >= 20, "đã có người vào và ra mạng");
}

void deterministic(Context& context) {
    Sim first(kSeed);
    Sim second(kSeed);
    Sim other(kSeed + 1);
    first.run(5000);
    second.run(5000);
    other.run(5000);
    context.expect(first.hash() == second.hash() && first.stats().ops == second.stats().ops, "cùng hạt giống cho cùng một dãy sự kiện");
    context.expect(first.hash() != other.hash(), "hạt giống khác cho dãy khác");
    context.expect(first.violations().empty() && other.violations().empty(), "không vi phạm bất biến ở cả hai hạt giống");
}

constexpr std::array kCases{
    Case{.name = "invariants_hold", .body = invariants_hold},
    Case{.name = "deterministic", .body = deterministic},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
