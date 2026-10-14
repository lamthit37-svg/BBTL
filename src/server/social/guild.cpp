#include "social/guild.hpp"

#include "ids/ids.hpp"
#include "protocol/wire.hpp"
#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint16_t kGuildVersion = 1;
constexpr std::uint16_t kLeagueVersion = 1;
constexpr std::size_t kMaxNameBytes = 63;          // tên nhân vật trong danh sách thành viên
constexpr std::size_t kMaxMembers = 2000;          // trần giải mã, rộng hơn guild_hard_member_cap
constexpr std::size_t kMaxProposers = 100;
constexpr std::size_t kMaxLeagueGuilds = 1000;
constexpr std::uint8_t kMaxCountyLevel = 5;
constexpr std::int64_t kMaxWarTimes = 1'000'000;

[[nodiscard]] constexpr int rank_of(GuildPosition position) noexcept { return static_cast<int>(position); }

[[nodiscard]] constexpr bool valid_position(std::uint8_t raw) noexcept {
    return raw >= static_cast<std::uint8_t>(GuildPosition::kMember) && raw <= static_cast<std::uint8_t>(GuildPosition::kChief);
}

[[nodiscard]] GuildResult reject(GuildError error) {
    GuildResult result;
    result.error = error;
    return result;
}

[[nodiscard]] GuildEvent make_event(GuildEventKind kind, GuildId guild, CharacterId subject, CharacterId other,
    std::vector<CharacterId> audience) {
    GuildEvent event;
    event.kind = kind;
    event.guild = guild;
    event.subject = subject;
    event.other = other;
    event.audience = std::move(audience);
    return event;
}

[[nodiscard]] const GuildMember* find_member(const Guild& guild, CharacterId id) noexcept {
    const auto found = std::ranges::find(guild.members, id, &GuildMember::id);
    return found == guild.members.end() ? nullptr : &*found;
}

[[nodiscard]] GuildMember* find_member(Guild& guild, CharacterId id) noexcept {
    const auto found = std::ranges::find(guild.members, id, &GuildMember::id);
    return found == guild.members.end() ? nullptr : &*found;
}

[[nodiscard]] const GuildMember* find_position(const Guild& guild, GuildPosition position) noexcept {
    const auto found = std::ranges::find(guild.members, position, &GuildMember::position);
    return found == guild.members.end() ? nullptr : &*found;
}

[[nodiscard]] bool has_power(const GuildMember& member, std::uint16_t bit) noexcept { return (member.access & bit) != 0; }

// Hạn ngạch một chức; -1 = không giới hạn (thành viên thường).
[[nodiscard]] std::int64_t quota_of(GuildPosition position, const Limits& limits) noexcept {
    switch (position) {
    case GuildPosition::kChief:
    case GuildPosition::kAssistant: return 1;
    case GuildPosition::kElite: return limits.guild_max_elite;
    case GuildPosition::kCommerce:
    case GuildPosition::kAgriculture:
    case GuildPosition::kIndustry:
    case GuildPosition::kPersonnel: return limits.guild_max_office;
    case GuildPosition::kMember:
    case GuildPosition::kTrainee: break;
    }
    return -1;
}

// Hình dạng một bang so với trần. Chuỗi rỗng = hợp lệ. Dùng cho nạp từ kho và validate().
[[nodiscard]] std::string_view guild_problem(const Guild& guild, const Limits& limits) {
    if (guild.id.value() == 0) return "id bang 0";
    if (!is_plain_text(guild.name, static_cast<std::size_t>(limits.guild_name_max_bytes)) || guild.name.empty() ||
        has_edge_space(guild.name) || codepoint_count(guild.name) < static_cast<std::size_t>(limits.guild_name_min_codepoints)) {
        return "tên bang sai";
    }
    if (!is_plain_text(guild.description, static_cast<std::size_t>(limits.guild_desc_max_bytes))) return "tông chỉ sai";
    if (guild.level > kMaxCountyLevel) return "cấp nha môn ngoài miền";
    if ((guild.level == 0) != (guild.city.value() == 0)) return "cấp nha môn và thành phố không khớp";
    if (guild.funds < 0 || guild.funds > kCopperCeiling) return "quỹ ngoài miền";
    if (guild.war_points < 0) return "điểm bang chiến âm";
    for (const std::string& name : guild.position_names) {
        if (!is_plain_text(name, static_cast<std::size_t>(limits.guild_position_name_max_bytes))) return "tên chức sai";
    }
    if (guild.members.empty() || std::cmp_greater(guild.members.size(), limits.guild_hard_member_cap)) return "số thành viên ngoài miền";
    if (std::cmp_greater(guild.proposers.size(), limits.guild_max_proposers)) return "quá trần đơn xin vào";
    std::set<CharacterId> seen;
    std::array<std::int64_t, kGuildPositionCount + 1> per_position{};
    for (const GuildMember& member : guild.members) {
        if (member.id.value() == 0 || !seen.insert(member.id).second) return "thành viên id 0 hoặc trùng";
        if (!is_plain_text(member.name, kMaxNameBytes)) return "tên thành viên sai";
        if (!valid_position(static_cast<std::uint8_t>(member.position))) return "chức vị ngoài miền";
        if ((member.access & ~power::kAll) != 0) return "quyền ngoài miền";
        if (member.contribution < 0 || member.contribution > kCopperCeiling) return "đóng góp ngoài miền";
        ++per_position.at(static_cast<std::size_t>(rank_of(member.position)));
    }
    for (const GuildProposer& proposer : guild.proposers) {
        if (proposer.id.value() == 0 || !seen.insert(proposer.id).second) return "người xin vào id 0, trùng hoặc đã là thành viên";
        if (!is_plain_text(proposer.name, kMaxNameBytes)) return "tên người xin vào sai";
    }
    if (per_position.at(static_cast<std::size_t>(rank_of(GuildPosition::kChief))) != 1) return "phải có đúng một bang chủ";
    for (int raw = rank_of(GuildPosition::kElite); raw <= rank_of(GuildPosition::kAssistant); ++raw) {
        const std::int64_t quota = quota_of(static_cast<GuildPosition>(raw), limits);
        if (per_position.at(static_cast<std::size_t>(raw)) > quota) return "quá hạn ngạch chức vị";
    }
    return {};
}

[[nodiscard]] std::string_view league_problem(const League& league, const Limits& limits) {
    if (league.id.value() == 0) return "id liên minh 0";
    if (!is_plain_text(league.name, static_cast<std::size_t>(limits.guild_name_max_bytes)) || league.name.empty() ||
        has_edge_space(league.name)) {
        return "tên liên minh sai";
    }
    if (league.members.empty() || std::cmp_greater(league.members.size(), limits.guild_league_max_members)) {
        return "số bang trong liên minh ngoài miền";
    }
    if (league.members.front() != league.leader) return "bang đứng đầu phải ở đầu danh sách";
    const std::set<GuildId> unique(league.members.begin(), league.members.end());
    if (unique.size() != league.members.size() || unique.contains(GuildId{})) return "bang trùng hoặc id 0";
    return {};
}

} // namespace

std::uint16_t default_power(GuildPosition position) noexcept {
    switch (position) {
    case GuildPosition::kChief: return power::kChiefDefault;
    case GuildPosition::kAssistant: return power::kAssistantDefault;
    default: return power::kMemberDefault;
    }
}

std::string power_string(std::uint16_t mask) {
    std::string out(10, '0');
    for (unsigned bit = 0; bit < 10; ++bit) {
        if (((static_cast<unsigned>(mask) >> bit) & 1U) != 0) out.at(bit) = '1';
    }
    return out;
}

std::int8_t client_code(GuildError error) noexcept {
    switch (error) {
    case GuildError::kInvalidName: return -2;
    case GuildError::kDuplicateName: return -3;
    case GuildError::kGuildFull: return -4;
    case GuildError::kMemberFull: return -5;
    case GuildError::kProposerFull: return -6;
    case GuildError::kInGuild: return -7;
    case GuildError::kNotExist: return -8;
    case GuildError::kUnauthorized: return -9;
    case GuildError::kNoVacancy: return -10;
    case GuildError::kNoQualification: return -11;
    case GuildError::kCashboxFull: return -12;
    case GuildError::kAlreadyMember: return -13;
    case GuildError::kMemberNotExist: return -14;
    case GuildError::kNoAssistant: return -15;
    case GuildError::kPosFull: return -17;
    case GuildError::kAlreadyProposer: return -18;
    case GuildError::kInvalidCamp: return -19;
    default: return 0;
    }
}

std::string_view describe(GuildError error) noexcept {
    switch (error) {
    case GuildError::kInvalidName: return "tên không hợp lệ";
    case GuildError::kDuplicateName: return "tên đã có người dùng";
    case GuildError::kGuildFull: return "đã đủ số bang";
    case GuildError::kMemberFull: return "bang đã đủ thành viên";
    case GuildError::kProposerFull: return "danh sách chờ duyệt đã đầy";
    case GuildError::kInGuild: return "đã ở trong một bang";
    case GuildError::kNotExist: return "bang không tồn tại";
    case GuildError::kUnauthorized: return "không có quyền";
    case GuildError::kNoVacancy: return "chức vị không còn chỗ";
    case GuildError::kNoQualification: return "không đủ tư cách";
    case GuildError::kCashboxFull: return "quỹ bang đã đầy";
    case GuildError::kAlreadyMember: return "đã là thành viên";
    case GuildError::kMemberNotExist: return "người này không ở trong bang";
    case GuildError::kNoAssistant: return "bang chưa có bang phó";
    case GuildError::kPosFull: return "chức vị đã đủ người";
    case GuildError::kAlreadyProposer: return "đã xin vào một bang";
    case GuildError::kInvalidCamp: return "khác phe";
    case GuildError::kUnknownPlayer: return "không thấy người chơi";
    case GuildError::kLevelTooLow: return "cấp chưa đủ";
    case GuildError::kNotEnoughMoney: return "không đủ tiền";
    case GuildError::kBadText: return "văn bản không hợp lệ";
    case GuildError::kBadPosition: return "chức vị không hợp lệ";
    case GuildError::kSelf: return "không thể tự làm với bản thân";
    case GuildError::kChiefCannotLeave: return "bang chủ không thể rời bang, hãy nhường chức hoặc giải tán";
    case GuildError::kRankTooLow: return "chức vị không đủ cao";
    case GuildError::kBadValue: return "giá trị không hợp lệ";
    case GuildError::kNotInGuild: return "chưa vào bang";
    case GuildError::kNotChief: return "chỉ bang chủ làm được";
    case GuildError::kCashboxNotEmpty: return "quỹ bang còn tiền";
    case GuildError::kHasCity: return "bang còn giữ thành phố";
    case GuildError::kInLeague: return "bang đang ở trong liên minh";
    case GuildError::kNotInLeague: return "bang chưa ở trong liên minh";
    case GuildError::kLeagueFull: return "liên minh đã đủ bang";
    case GuildError::kRejoinCooldown: return "bang vừa rời liên minh, chưa được vào lại";
    case GuildError::kAtWar: return "đang trong bang chiến";
    case GuildError::kNotAtWar: return "không trong bang chiến";
    case GuildError::kTooFewMembers: return "bang chưa đủ người để bang chiến";
    case GuildError::kNoPending: return "không có lời chờ trả lời";
    }
    return "lỗi bang hội lạ";
}

// ---------------------------------------------------------------------------------------------
// WarPointTable
// ---------------------------------------------------------------------------------------------

std::expected<WarPointTable, std::string> WarPointTable::parse(std::string_view tsv) {
    auto sheet = table::parse_tsv(tsv);
    if (!sheet) return std::unexpected(std::move(sheet.error()));
    if (sheet->rows.size() > 256) return std::unexpected("bảng điểm bang chiến quá 256 hàng");
    WarPointTable out;
    for (std::size_t row = 0; row < sheet->rows.size(); ++row) {
        table::RowReader reader(*sheet, row);
        const std::uint32_t id = reader.number("id", 0, 1'000'000);
        const std::int32_t points = reader.integer("points", 0, 1'000'000);
        if (reader.error()) return std::unexpected(*reader.error());
        out.points_.emplace_back(id, points);
    }
    std::ranges::sort(out.points_);
    const auto dup = std::ranges::adjacent_find(out.points_, {}, &std::pair<std::uint32_t, std::int64_t>::first);
    if (dup != out.points_.end()) return std::unexpected(std::format("trùng mã sự kiện {}", dup->first));
    return out;
}

std::int64_t WarPointTable::points_for(std::uint32_t event_id) const noexcept {
    const auto found = std::ranges::lower_bound(points_, event_id, {}, &std::pair<std::uint32_t, std::int64_t>::first);
    return found == points_.end() || found->first != event_id ? 0 : found->second;
}

// ---------------------------------------------------------------------------------------------
// GuildBook: tiện ích
// ---------------------------------------------------------------------------------------------

GuildBook::GuildBook(const Limits& limits, const GuildRules& rules, const TextPolicy& policy)
    : limits_(limits),
      rules_(rules),
      policy_(&policy),
      proposer_ttl_(seconds_to_ticks(limits.guild_proposer_ttl_seconds)),
      invite_ttl_(seconds_to_ticks(limits.guild_league_invite_ttl_seconds)),
      war_length_(seconds_to_ticks(std::int64_t{rules.battle_minutes} * 60)),
      rejoin_wait_(seconds_to_ticks(std::int64_t{rules.league_rejoin_hours} * 3600)) {}

Guild* GuildBook::mutable_guild(GuildId id) {
    const auto found = guilds_.find(id);
    return found == guilds_.end() ? nullptr : &found->second;
}

const Guild* GuildBook::find(GuildId id) const {
    const auto found = guilds_.find(id);
    return found == guilds_.end() ? nullptr : &found->second;
}

const Guild* GuildBook::find_by_name(std::string_view name) const {
    const auto found = name_index_.find(fold_name(name));
    return found == name_index_.end() ? nullptr : find(found->second);
}

std::optional<GuildId> GuildBook::guild_of(CharacterId member) const {
    const auto found = member_index_.find(member);
    if (found == member_index_.end()) return std::nullopt;
    return found->second;
}

std::optional<GuildId> GuildBook::proposer_guild_of(CharacterId applicant) const {
    const auto found = proposer_index_.find(applicant);
    if (found == proposer_index_.end()) return std::nullopt;
    return found->second;
}

const GuildMember* GuildBook::member(CharacterId id) const {
    const auto owner = guild_of(id);
    if (!owner) return nullptr;
    const Guild* guild = find(*owner);
    return guild == nullptr ? nullptr : find_member(*guild, id);
}

GuildMember* GuildBook::mutable_member(CharacterId id, Guild** guild_out) {
    const auto owner = guild_of(id);
    if (!owner) return nullptr;
    Guild* guild = mutable_guild(*owner);
    if (guild == nullptr) return nullptr;
    if (guild_out != nullptr) *guild_out = guild;
    return find_member(*guild, id);
}

std::int64_t GuildBook::member_cap(const Guild& guild) const noexcept {
    const std::int64_t base = guild.level == 0
        ? std::int64_t{rules_.initial_member_cap}
        : std::int64_t{rules_.county_max_user.at(std::size_t{guild.level} - 1U)};
    return std::min(base, limits_.guild_hard_member_cap);
}

Copper GuildBook::funds_cap(const Guild& guild) const noexcept {
    const std::size_t index = guild.level == 0 ? 0U : std::size_t{guild.level} - 1U;
    return std::min(rules_.county_max_money.at(index), kCopperCeiling);
}

std::vector<CharacterId> GuildBook::everyone(const Guild& guild) const {
    std::vector<CharacterId> out;
    out.reserve(guild.members.size());
    for (const GuildMember& member : guild.members) out.push_back(member.id);
    return out;
}

std::vector<CharacterId> GuildBook::with_power(const Guild& guild, std::uint16_t bit) const {
    std::vector<CharacterId> out;
    for (const GuildMember& member : guild.members) {
        if (has_power(member, bit)) out.push_back(member.id);
    }
    return out;
}

bool GuildBook::name_ok(std::string_view name, std::size_t max_bytes, std::size_t min_codepoints) const {
    return !name.empty() && is_plain_text(name, max_bytes) && !has_edge_space(name) && codepoint_count(name) >= min_codepoints &&
           policy_->allowed(name);
}

std::int64_t GuildBook::position_count(const Guild& guild, GuildPosition position) const {
    return std::ranges::count(guild.members, position, &GuildMember::position);
}

void GuildBook::add_member(Guild& guild, const PlayerCard& card, GuildPosition position) {
    GuildMember member;
    member.id = card.id;
    member.name = card.name;
    member.position = position;
    member.access = default_power(position);
    member.level = card.level;
    member.sect = card.sect;
    guild.members.push_back(std::move(member));
    member_index_.insert_or_assign(card.id, guild.id);
}

void GuildBook::erase_member(Guild& guild, CharacterId id) {
    std::erase_if(guild.members, [id](const GuildMember& member) { return member.id == id; });
    member_index_.erase(id);
}

void GuildBook::drop_proposals_of(CharacterId id) {
    const auto found = proposer_index_.find(id);
    if (found == proposer_index_.end()) return;
    if (Guild* guild = mutable_guild(found->second)) {
        std::erase_if(guild->proposers, [id](const GuildProposer& proposer) { return proposer.id == id; });
    }
    proposer_index_.erase(found);
}

void GuildBook::set_next_ids(GuildId guild, LeagueId league) {
    next_guild_ = std::max(next_guild_, guild.value());
    next_league_ = std::max(next_league_, league.value());
}

std::string_view GuildBook::custom_position_name(const Guild& guild, GuildPosition position) noexcept {
    const auto raw = static_cast<std::size_t>(rank_of(position));
    if (raw == 0 || raw > kGuildPositionCount) return {};
    return guild.position_names.at(raw - 1U);
}

bool GuildBook::at_war(GuildId guild) const {
    return std::ranges::any_of(wars_, [guild](const War& war) { return war.a == guild || war.b == guild; });
}

const League* GuildBook::league_of(GuildId guild) const {
    const auto found = league_index_.find(guild);
    return found == league_index_.end() ? nullptr : find_league(found->second);
}

const League* GuildBook::find_league(LeagueId id) const {
    const auto found = leagues_.find(id);
    return found == leagues_.end() ? nullptr : &found->second;
}

std::expected<void, GuildError> GuildBook::set_county(GuildId id, std::uint8_t level, CityId city) {
    Guild* guild = mutable_guild(id);
    if (guild == nullptr) return std::unexpected(GuildError::kNotExist);
    if (level > kMaxCountyLevel || (level == 0) != (city.value() == 0)) return std::unexpected(GuildError::kBadValue);
    guild->level = level;
    guild->city = city;
    return {};
}

void GuildBook::refresh_member(const PlayerCard& card) {
    Guild* guild = nullptr;
    GuildMember* member = mutable_member(card.id, &guild);
    if (member == nullptr) return;
    member->level = card.level;
    member->sect = card.sect;
}

// ---------------------------------------------------------------------------------------------
// Lập, xin vào, nhận
// ---------------------------------------------------------------------------------------------

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên và tông chỉ khác vai; nơi gọi đặt tên biến rõ nghĩa
GuildResult GuildBook::create(Tick /*now*/, const PlayerDirectory& directory, CharacterId actor, std::string_view name,
    std::string_view description, Copper wallet) {
    const auto card = directory.find(actor);
    if (!card || !card->online) return reject(GuildError::kUnknownPlayer);
    if (member_index_.contains(actor)) return reject(GuildError::kInGuild);
    if (std::cmp_less(card->level, limits_.guild_create_min_level)) return reject(GuildError::kLevelTooLow);
    if (!name_ok(name, static_cast<std::size_t>(limits_.guild_name_max_bytes),
            static_cast<std::size_t>(limits_.guild_name_min_codepoints))) {
        return reject(GuildError::kInvalidName);
    }
    if (!is_plain_text(description, static_cast<std::size_t>(limits_.guild_desc_max_bytes)) ||
        (!description.empty() && !policy_->allowed(description))) {
        return reject(GuildError::kBadText);
    }
    if (name_index_.contains(fold_name(name))) return reject(GuildError::kDuplicateName);
    if (std::cmp_greater_equal(guilds_.size(), limits_.guild_max_guilds)) return reject(GuildError::kGuildFull);
    if (wallet < limits_.guild_create_fee_copper) return reject(GuildError::kNotEnoughMoney);

    drop_proposals_of(actor);
    Guild guild;
    guild.id = GuildId{next_guild_++};
    guild.name = std::string(name);
    guild.description = std::string(description);
    guild.founder = actor;
    guild.camp = card->camp;
    add_member(guild, *card, GuildPosition::kChief);
    const GuildId id = guild.id;
    name_index_.insert_or_assign(fold_name(name), id);
    guilds_.insert_or_assign(id, std::move(guild));

    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kCreated, id, actor, CharacterId{}, {actor});
    event.value = limits_.guild_create_fee_copper;
    event.text = std::string(name);
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::apply(Tick now, const PlayerDirectory& directory, CharacterId actor, GuildId target) {
    const auto card = directory.find(actor);
    if (!card || !card->online) return reject(GuildError::kUnknownPlayer);
    if (member_index_.contains(actor)) return reject(GuildError::kInGuild);
    if (proposer_index_.contains(actor)) return reject(GuildError::kAlreadyProposer);
    Guild* guild = mutable_guild(target);
    if (guild == nullptr) return reject(GuildError::kNotExist);
    if (guild->camp != 0 && card->camp != 0 && guild->camp != card->camp) return reject(GuildError::kInvalidCamp);
    // Đơn quá hạn nhường chỗ trước khi đếm trần.
    std::erase_if(guild->proposers, [this, now](const GuildProposer& proposer) {
        if (proposer.expires > now) return false;
        proposer_index_.erase(proposer.id);
        return true;
    });
    if (std::cmp_greater_equal(guild->proposers.size(), limits_.guild_max_proposers)) return reject(GuildError::kProposerFull);
    if (std::cmp_greater_equal(guild->members.size(), member_cap(*guild))) return reject(GuildError::kMemberFull);
    GuildProposer proposer;
    proposer.id = actor;
    proposer.name = card->name;
    proposer.level = card->level;
    proposer.sect = card->sect;
    proposer.expires = ids::advance(now, proposer_ttl_);
    guild->proposers.push_back(std::move(proposer));
    proposer_index_.insert_or_assign(actor, target);
    GuildResult result;
    result.events.push_back(make_event(GuildEventKind::kApplied, target, actor, CharacterId{}, with_power(*guild, power::kRecruit)));
    return result;
}

GuildResult GuildBook::cancel_application(CharacterId actor) {
    if (!proposer_index_.contains(actor)) return reject(GuildError::kNoPending);
    drop_proposals_of(actor);
    return {};
}

GuildResult GuildBook::answer_application(
    Tick now, const PlayerDirectory& directory, CharacterId actor, CharacterId applicant, bool accept) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kRecruit)) return reject(GuildError::kUnauthorized);
    const auto proposal = std::ranges::find(guild->proposers, applicant, &GuildProposer::id);
    if (proposal == guild->proposers.end()) return reject(GuildError::kNoPending);
    if (proposal->expires <= now) {
        drop_proposals_of(applicant);
        return reject(GuildError::kNoPending);
    }
    GuildResult result;
    if (!accept) {
        drop_proposals_of(applicant);
        result.events.push_back(make_event(GuildEventKind::kApplyRejected, guild->id, applicant, actor, {applicant}));
        return result;
    }
    if (member_index_.contains(applicant)) {
        drop_proposals_of(applicant);
        return reject(GuildError::kInGuild);
    }
    if (std::cmp_greater_equal(guild->members.size(), member_cap(*guild))) return reject(GuildError::kMemberFull);
    PlayerCard card;
    if (const auto fresh = directory.find(applicant)) {
        card = *fresh;
    } else {
        card.id = applicant;
        card.name = proposal->name;
        card.level = proposal->level;
        card.sect = proposal->sect;
    }
    if (guild->camp != 0 && card.camp != 0 && guild->camp != card.camp) {
        drop_proposals_of(applicant);
        return reject(GuildError::kInvalidCamp);
    }
    drop_proposals_of(applicant);
    add_member(*guild, card, GuildPosition::kMember);
    result.events.push_back(make_event(GuildEventKind::kRecruited, guild->id, applicant, actor, everyone(*guild)));
    return result;
}

// ---------------------------------------------------------------------------------------------
// Đuổi, rời, bổ nhiệm, quyền, nhường chức, giải tán
// ---------------------------------------------------------------------------------------------

GuildResult GuildBook::expel(CharacterId actor, CharacterId target) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kExpel)) return reject(GuildError::kUnauthorized);
    if (actor == target) return reject(GuildError::kSelf);
    const GuildMember* victim = find_member(*guild, target);
    if (victim == nullptr) return reject(GuildError::kMemberNotExist);
    if (rank_of(self->position) <= rank_of(victim->position)) return reject(GuildError::kRankTooLow);
    GuildResult result;
    result.events.push_back(make_event(GuildEventKind::kExpelled, guild->id, target, actor, everyone(*guild)));
    erase_member(*guild, target);
    return result;
}

GuildResult GuildBook::leave(CharacterId actor) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position == GuildPosition::kChief) return reject(GuildError::kChiefCannotLeave);
    if (!has_power(*self, power::kLeave)) return reject(GuildError::kUnauthorized);
    GuildResult result;
    result.events.push_back(make_event(GuildEventKind::kLeft, guild->id, actor, CharacterId{}, everyone(*guild)));
    erase_member(*guild, actor);
    return result;
}

GuildResult GuildBook::appoint(CharacterId actor, CharacterId target, GuildPosition position) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kAssign)) return reject(GuildError::kUnauthorized);
    if (!valid_position(static_cast<std::uint8_t>(position)) || position == GuildPosition::kChief) {
        return reject(GuildError::kBadPosition);
    }
    if (actor == target) return reject(GuildError::kSelf);
    GuildMember* subject = find_member(*guild, target);
    if (subject == nullptr) return reject(GuildError::kMemberNotExist);
    if (subject->position == position) return reject(GuildError::kBadValue);
    // 2008 chỉ kiểm quyền ASSIGN: người bổ nhiệm phải cao chức hơn cả người được bổ nhiệm lẫn chức mới.
    if (rank_of(self->position) <= rank_of(subject->position) || rank_of(self->position) <= rank_of(position)) {
        return reject(GuildError::kRankTooLow);
    }
    const std::int64_t quota = quota_of(position, limits_);
    if (quota >= 0 && position_count(*guild, position) >= quota) return reject(GuildError::kPosFull);
    const GuildPosition old = subject->position;
    subject->position = position;
    subject->access = default_power(position);
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kAppointed, guild->id, target, actor, everyone(*guild));
    event.value = rank_of(position);
    event.old_value = rank_of(old);
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::toggle_power(CharacterId actor, CharacterId target, std::uint16_t bit) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kAuthorize)) return reject(GuildError::kUnauthorized);
    if (std::popcount(bit) != 1 || (bit & power::kAll) == 0 || (bit & power::kReserved) != 0) return reject(GuildError::kBadValue);
    if (actor == target) return reject(GuildError::kSelf);
    GuildMember* subject = find_member(*guild, target);
    if (subject == nullptr) return reject(GuildError::kMemberNotExist);
    if (rank_of(self->position) <= rank_of(subject->position)) return reject(GuildError::kRankTooLow);
    const bool granting = !has_power(*subject, bit);
    if (granting && !has_power(*self, bit)) return reject(GuildError::kUnauthorized);
    subject->access = static_cast<std::uint16_t>(subject->access ^ bit);
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kPowerChanged, guild->id, target, actor, {target, actor});
    event.value = subject->access;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::demise(CharacterId actor) {
    Guild* guild = nullptr;
    GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kDemise)) return reject(GuildError::kUnauthorized);
    GuildMember* assistant = nullptr;
    for (GuildMember& member : guild->members) {
        if (member.position == GuildPosition::kAssistant) assistant = &member;
    }
    if (assistant == nullptr) return reject(GuildError::kNoAssistant);
    const CharacterId new_chief = assistant->id;
    assistant->position = GuildPosition::kChief;
    assistant->access = default_power(GuildPosition::kChief);
    self->position = GuildPosition::kAssistant;
    self->access = default_power(GuildPosition::kAssistant);
    GuildResult result;
    result.events.push_back(make_event(GuildEventKind::kDemised, guild->id, new_chief, actor, everyone(*guild)));
    return result;
}

void GuildBook::remove_guild(GuildId id, GuildEvents& out) {
    const auto found = guilds_.find(id);
    if (found == guilds_.end()) return;
    const Guild& guild = found->second;
    for (const GuildProposer& proposer : guild.proposers) {
        proposer_index_.erase(proposer.id);
        out.push_back(make_event(GuildEventKind::kApplyRejected, id, proposer.id, CharacterId{}, {proposer.id}));
    }
    for (const GuildMember& member : guild.members) member_index_.erase(member.id);
    name_index_.erase(fold_name(guild.name));
    rejoin_until_.erase(id);
    std::erase_if(invites_, [id](const auto& item) { return item.first.second == id; });
    guilds_.erase(found);
}

GuildResult GuildBook::dismiss(CharacterId actor) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kDismiss)) return reject(GuildError::kUnauthorized);
    if (guild->funds != 0) return reject(GuildError::kCashboxNotEmpty);
    if (guild->city.value() != 0) return reject(GuildError::kHasCity);
    if (league_index_.contains(guild->id)) return reject(GuildError::kInLeague);
    if (at_war(guild->id)) return reject(GuildError::kAtWar);
    GuildResult result;
    result.events.push_back(make_event(GuildEventKind::kDismissed, guild->id, actor, CharacterId{}, everyone(*guild)));
    remove_guild(guild->id, result.events);
    return result;
}

GuildResult GuildBook::set_description(CharacterId actor, std::string_view text) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kChangeDesc)) return reject(GuildError::kUnauthorized);
    if (!is_plain_text(text, static_cast<std::size_t>(limits_.guild_desc_max_bytes)) || (!text.empty() && !policy_->allowed(text))) {
        return reject(GuildError::kBadText);
    }
    GuildResult result;
    if (guild->description == text) return result;
    guild->description = std::string(text);
    GuildEvent event = make_event(GuildEventKind::kDescriptionChanged, guild->id, actor, CharacterId{}, everyone(*guild));
    event.text = guild->description;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::rename_position(CharacterId actor, GuildPosition position, std::string_view text) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    if (!valid_position(static_cast<std::uint8_t>(position))) return reject(GuildError::kBadPosition);
    if (!is_plain_text(text, static_cast<std::size_t>(limits_.guild_position_name_max_bytes)) ||
        (!text.empty() && (has_edge_space(text) || !policy_->allowed(text)))) {
        return reject(GuildError::kBadText);
    }
    std::string& slot = guild->position_names.at(static_cast<std::size_t>(rank_of(position)) - 1U);
    GuildResult result;
    if (slot == text) return result;
    slot = std::string(text);
    GuildEvent event = make_event(GuildEventKind::kPositionRenamed, guild->id, actor, CharacterId{}, everyone(*guild));
    event.value = rank_of(position);
    event.text = slot;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::deposit(CharacterId actor, Copper amount, Copper wallet) {
    Guild* guild = nullptr;
    GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kDeposit)) return reject(GuildError::kUnauthorized);
    if (amount <= 0 || amount > kCopperCeiling) return reject(GuildError::kBadValue);
    if (wallet < amount) return reject(GuildError::kNotEnoughMoney);
    if (amount > funds_cap(*guild) - std::min(guild->funds, funds_cap(*guild))) return reject(GuildError::kCashboxFull);
    guild->funds += amount;
    self->contribution = add_clamped(self->contribution, amount);
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kDeposited, guild->id, actor, CharacterId{}, {actor});
    event.value = amount;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::withdraw(CharacterId actor, Copper amount) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (!has_power(*self, power::kWithdraw)) return reject(GuildError::kUnauthorized);
    if (amount <= 0 || amount > kCopperCeiling) return reject(GuildError::kBadValue);
    if (guild->funds < amount) return reject(GuildError::kNotEnoughMoney);
    guild->funds -= amount;
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kWithdrawn, guild->id, actor, CharacterId{}, {actor});
    event.value = amount;
    result.events.push_back(std::move(event));
    return result;
}

// ---------------------------------------------------------------------------------------------
// Bang chiến
// ---------------------------------------------------------------------------------------------

GuildResult GuildBook::declare_war(Tick now, CharacterId actor, GuildId enemy) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (rank_of(self->position) < rank_of(GuildPosition::kAssistant)) return reject(GuildError::kUnauthorized);
    if (enemy == guild->id) return reject(GuildError::kSelf);
    const Guild* other = find(enemy);
    if (other == nullptr) return reject(GuildError::kNotExist);
    if (std::cmp_less(guild->members.size(), limits_.guild_war_min_members) ||
        std::cmp_less(other->members.size(), limits_.guild_war_min_members)) {
        return reject(GuildError::kTooFewMembers);
    }
    if (at_war(guild->id) || at_war(enemy)) return reject(GuildError::kAtWar);
    wars_.push_back(War{.a = guild->id, .b = enemy, .ends = ids::advance(now, war_length_)});
    GuildResult result;
    std::vector<CharacterId> audience = everyone(*guild);
    const std::vector<CharacterId> theirs = everyone(*other);
    audience.insert(audience.end(), theirs.begin(), theirs.end());
    GuildEvent event = make_event(GuildEventKind::kWarStarted, guild->id, actor, CharacterId{}, std::move(audience));
    event.other_guild = enemy;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::add_war_points(Tick /*now*/, GuildId guild_id, std::uint32_t event_id, std::int64_t times, const WarPointTable& table) {
    Guild* guild = mutable_guild(guild_id);
    if (guild == nullptr) return reject(GuildError::kNotExist);
    const auto war = std::ranges::find_if(wars_, [guild_id](const War& item) { return item.a == guild_id || item.b == guild_id; });
    if (war == wars_.end()) return reject(GuildError::kNotAtWar);
    if (times <= 0 || times > kMaxWarTimes) return reject(GuildError::kBadValue);
    const std::int64_t gained = table.points_for(event_id) * times;
    GuildResult result;
    if (gained == 0) return result;
    (war->a == guild_id ? war->points_a : war->points_b) += gained;
    guild->war_points += gained;
    GuildEvent event = make_event(GuildEventKind::kWarPoints, guild_id, CharacterId{}, CharacterId{}, everyone(*guild));
    event.value = guild->war_points;
    result.events.push_back(std::move(event));
    return result;
}

// ---------------------------------------------------------------------------------------------
// Liên minh
// ---------------------------------------------------------------------------------------------

GuildResult GuildBook::league_create(Tick /*now*/, CharacterId actor, std::string_view name, Copper wallet) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    if (league_index_.contains(guild->id)) return reject(GuildError::kInLeague);
    if (!name_ok(name, static_cast<std::size_t>(limits_.guild_name_max_bytes),
            static_cast<std::size_t>(limits_.guild_name_min_codepoints))) {
        return reject(GuildError::kInvalidName);
    }
    if (league_names_.contains(fold_name(name))) return reject(GuildError::kDuplicateName);
    if (std::cmp_greater_equal(leagues_.size(), rules_.league_max_count)) return reject(GuildError::kGuildFull);
    if (wallet < rules_.league_create_cost) return reject(GuildError::kNotEnoughMoney);
    League league;
    league.id = LeagueId{next_league_++};
    league.name = std::string(name);
    league.leader = guild->id;
    league.members.push_back(guild->id);
    const LeagueId id = league.id;
    league_names_.insert_or_assign(fold_name(name), id);
    league_index_.insert_or_assign(guild->id, id);
    leagues_.insert_or_assign(id, std::move(league));
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kLeagueCreated, guild->id, actor, CharacterId{}, {actor});
    event.league = id;
    event.value = rules_.league_create_cost;
    event.text = std::string(name);
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::league_invite(Tick now, CharacterId actor, GuildId target) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    const League* league = league_of(guild->id);
    if (league == nullptr || league->leader != guild->id) return reject(GuildError::kNotInLeague);
    if (target == guild->id) return reject(GuildError::kSelf);
    const Guild* other = find(target);
    if (other == nullptr) return reject(GuildError::kNotExist);
    if (league_index_.contains(target)) return reject(GuildError::kInLeague);
    if (std::cmp_greater_equal(league->members.size(), limits_.guild_league_max_members)) return reject(GuildError::kLeagueFull);
    const auto cooldown = rejoin_until_.find(target);
    if (cooldown != rejoin_until_.end() && cooldown->second > now) return reject(GuildError::kRejoinCooldown);
    invites_.insert_or_assign(std::pair{league->id, target}, Invite{.expires = ids::advance(now, invite_ttl_)});
    GuildResult result;
    const GuildMember* chief = find_position(*other, GuildPosition::kChief);
    GuildEvent event = make_event(GuildEventKind::kLeagueInvite, guild->id, actor, CharacterId{},
        chief != nullptr ? std::vector<CharacterId>{chief->id} : std::vector<CharacterId>{});
    event.league = league->id;
    event.other_guild = target;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::league_answer(Tick now, CharacterId actor, GuildId inviter, bool accept) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    const auto lead = league_index_.find(inviter);
    if (lead == league_index_.end()) return reject(GuildError::kNoPending);
    const auto league_it = leagues_.find(lead->second);
    if (league_it == leagues_.end() || league_it->second.leader != inviter) return reject(GuildError::kNoPending);
    League& league = league_it->second;
    const auto invite = invites_.find({league.id, guild->id});
    if (invite == invites_.end() || invite->second.expires <= now) {
        if (invite != invites_.end()) invites_.erase(invite);
        return reject(GuildError::kNoPending);
    }
    invites_.erase(invite);
    GuildResult result;
    if (!accept) return result;
    if (league_index_.contains(guild->id)) return reject(GuildError::kInLeague);
    if (std::cmp_greater_equal(league.members.size(), limits_.guild_league_max_members)) return reject(GuildError::kLeagueFull);
    const auto cooldown = rejoin_until_.find(guild->id);
    if (cooldown != rejoin_until_.end() && cooldown->second > now) return reject(GuildError::kRejoinCooldown);
    league.members.push_back(guild->id);
    league_index_.insert_or_assign(guild->id, league.id);
    std::vector<CharacterId> audience;
    for (const GuildId member_guild : league.members) {
        if (const Guild* g = find(member_guild)) {
            if (const GuildMember* chief = find_position(*g, GuildPosition::kChief)) audience.push_back(chief->id);
        }
    }
    GuildEvent event = make_event(GuildEventKind::kLeagueJoined, guild->id, actor, CharacterId{}, std::move(audience));
    event.league = league.id;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::league_leave(Tick now, CharacterId actor) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    const auto link = league_index_.find(guild->id);
    if (link == league_index_.end()) return reject(GuildError::kNotInLeague);
    League& league = leagues_.at(link->second);
    if (league.leader == guild->id) return reject(GuildError::kBadValue);  // bang đứng đầu giải tán liên minh, không "rời"
    const LeagueId id = league.id;
    std::erase(league.members, guild->id);
    league_index_.erase(link);
    rejoin_until_.insert_or_assign(guild->id, ids::advance(now, rejoin_wait_));
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kLeagueLeft, guild->id, actor, CharacterId{}, {actor});
    event.league = id;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::league_kick(CharacterId actor, GuildId target) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    const auto link = league_index_.find(guild->id);
    if (link == league_index_.end()) return reject(GuildError::kNotInLeague);
    League& league = leagues_.at(link->second);
    if (league.leader != guild->id) return reject(GuildError::kUnauthorized);
    if (target == guild->id) return reject(GuildError::kSelf);
    if (!std::ranges::contains(league.members, target)) return reject(GuildError::kNotInLeague);
    std::erase(league.members, target);
    league_index_.erase(target);
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kLeagueKicked, target, actor, CharacterId{}, {actor});
    event.league = league.id;
    result.events.push_back(std::move(event));
    return result;
}

GuildResult GuildBook::league_disband(CharacterId actor) {
    Guild* guild = nullptr;
    const GuildMember* self = mutable_member(actor, &guild);
    if (self == nullptr) return reject(GuildError::kNotInGuild);
    if (self->position != GuildPosition::kChief) return reject(GuildError::kNotChief);
    const auto link = league_index_.find(guild->id);
    if (link == league_index_.end()) return reject(GuildError::kNotInLeague);
    const LeagueId id = link->second;
    const League& league = leagues_.at(id);
    if (league.leader != guild->id) return reject(GuildError::kUnauthorized);
    for (const GuildId member_guild : league.members) league_index_.erase(member_guild);
    league_names_.erase(fold_name(league.name));
    std::erase_if(invites_, [id](const auto& item) { return item.first.first == id; });
    leagues_.erase(id);
    GuildResult result;
    GuildEvent event = make_event(GuildEventKind::kLeagueDisbanded, guild->id, actor, CharacterId{}, {actor});
    event.league = id;
    result.events.push_back(std::move(event));
    return result;
}

// ---------------------------------------------------------------------------------------------
// Nhịp thời gian
// ---------------------------------------------------------------------------------------------

GuildEvents GuildBook::tick(Tick now) {
    GuildEvents out;
    for (auto& entry : guilds_) {
        const GuildId owner = entry.first;
        std::erase_if(entry.second.proposers, [this, &out, owner, now](const GuildProposer& proposer) {
            if (proposer.expires > now) return false;
            proposer_index_.erase(proposer.id);
            out.push_back(make_event(GuildEventKind::kApplyRejected, owner, proposer.id, CharacterId{}, {proposer.id}));
            return true;
        });
    }
    std::erase_if(invites_, [now](const auto& item) { return item.second.expires <= now; });
    std::erase_if(rejoin_until_, [now](const auto& item) { return item.second <= now; });
    std::erase_if(wars_, [this, &out, now](const War& war) {
        if (war.ends > now) return false;
        GuildEvent event = make_event(GuildEventKind::kWarEnded, war.a, CharacterId{}, CharacterId{}, {});
        event.other_guild = war.b;
        if (war.points_a != war.points_b) event.value = static_cast<std::int64_t>((war.points_a > war.points_b ? war.a : war.b).value());
        for (const GuildId side : {war.a, war.b}) {
            if (const Guild* g = find(side)) {
                const std::vector<CharacterId> all = everyone(*g);
                event.audience.insert(event.audience.end(), all.begin(), all.end());
            }
        }
        out.push_back(std::move(event));
        return true;
    });
    return out;
}

// ---------------------------------------------------------------------------------------------
// Nạp từ kho và kiểm bất biến
// ---------------------------------------------------------------------------------------------

std::expected<void, std::string> GuildBook::load_guild(Guild guild, Tick /*now*/) {
    if (const std::string_view problem = guild_problem(guild, limits_); !problem.empty()) return std::unexpected(std::string(problem));
    if (guilds_.contains(guild.id)) return std::unexpected("trùng id bang");
    if (name_index_.contains(fold_name(guild.name))) return std::unexpected("trùng tên bang");
    for (const GuildMember& member : guild.members) {
        if (member_index_.contains(member.id) || proposer_index_.contains(member.id)) return std::unexpected("thành viên đã thuộc bang khác");
    }
    for (const GuildProposer& proposer : guild.proposers) {
        if (member_index_.contains(proposer.id) || proposer_index_.contains(proposer.id)) return std::unexpected("người xin vào đã thuộc bang khác");
    }
    for (const GuildMember& member : guild.members) member_index_.insert_or_assign(member.id, guild.id);
    for (const GuildProposer& proposer : guild.proposers) proposer_index_.insert_or_assign(proposer.id, guild.id);
    name_index_.insert_or_assign(fold_name(guild.name), guild.id);
    next_guild_ = std::max(next_guild_, guild.id.value() + 1U);
    const GuildId id = guild.id;
    guilds_.insert_or_assign(id, std::move(guild));
    return {};
}

std::expected<void, std::string> GuildBook::load_league(League league) {
    if (const std::string_view problem = league_problem(league, limits_); !problem.empty()) return std::unexpected(std::string(problem));
    if (leagues_.contains(league.id)) return std::unexpected("trùng id liên minh");
    if (league_names_.contains(fold_name(league.name))) return std::unexpected("trùng tên liên minh");
    for (const GuildId member_guild : league.members) {
        if (!guilds_.contains(member_guild)) return std::unexpected("liên minh trỏ vào bang chưa nạp");
        if (league_index_.contains(member_guild)) return std::unexpected("bang đã ở liên minh khác");
    }
    for (const GuildId member_guild : league.members) league_index_.insert_or_assign(member_guild, league.id);
    league_names_.insert_or_assign(fold_name(league.name), league.id);
    next_league_ = std::max(next_league_, league.id.value() + 1U);
    const LeagueId id = league.id;
    leagues_.insert_or_assign(id, std::move(league));
    return {};
}

std::expected<void, std::string> GuildBook::validate() const {
    std::size_t members = 0;
    std::size_t proposers = 0;
    for (const auto& [id, guild] : guilds_) {
        if (guild.id != id) return std::unexpected("khoá bang lệch id");
        if (const std::string_view problem = guild_problem(guild, limits_); !problem.empty()) {
            return std::unexpected(std::format("bang {}: {}", id.value(), problem));
        }
        const auto named = name_index_.find(fold_name(guild.name));
        if (named == name_index_.end() || named->second != id) return std::unexpected(std::format("bang {}: chỉ mục tên lệch", id.value()));
        for (const GuildMember& member : guild.members) {
            const auto indexed = member_index_.find(member.id);
            if (indexed == member_index_.end() || indexed->second != id) {
                return std::unexpected(std::format("thành viên {}: chỉ mục lệch", member.id.value()));
            }
        }
        for (const GuildProposer& proposer : guild.proposers) {
            const auto indexed = proposer_index_.find(proposer.id);
            if (indexed == proposer_index_.end() || indexed->second != id) {
                return std::unexpected(std::format("người xin vào {}: chỉ mục lệch", proposer.id.value()));
            }
        }
        members += guild.members.size();
        proposers += guild.proposers.size();
    }
    if (members != member_index_.size()) return std::unexpected("chỉ mục thành viên thừa mục");
    if (proposers != proposer_index_.size()) return std::unexpected("chỉ mục người xin vào thừa mục");
    if (name_index_.size() != guilds_.size()) return std::unexpected("chỉ mục tên thừa mục");
    std::size_t in_league = 0;
    for (const auto& [id, league] : leagues_) {
        if (league.id != id) return std::unexpected("khoá liên minh lệch id");
        if (const std::string_view problem = league_problem(league, limits_); !problem.empty()) {
            return std::unexpected(std::format("liên minh {}: {}", id.value(), problem));
        }
        for (const GuildId member_guild : league.members) {
            if (!guilds_.contains(member_guild)) return std::unexpected("liên minh trỏ vào bang không có");
            const auto indexed = league_index_.find(member_guild);
            if (indexed == league_index_.end() || indexed->second != id) return std::unexpected("chỉ mục liên minh lệch");
        }
        in_league += league.members.size();
    }
    if (in_league != league_index_.size()) return std::unexpected("chỉ mục liên minh thừa mục");
    if (league_names_.size() != leagues_.size()) return std::unexpected("chỉ mục tên liên minh thừa mục");
    for (const War& war : wars_) {
        if (!guilds_.contains(war.a) || !guilds_.contains(war.b)) return std::unexpected("bang chiến trỏ vào bang không có");
    }
    return {};
}

// ---------------------------------------------------------------------------------------------
// Mã hoá
// ---------------------------------------------------------------------------------------------

CodecResult encode_guild(const Guild& guild, Tick now, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kGuildVersion);
    writer.u64(guild.id.value());
    writer.text(guild.name, 255);
    writer.text(guild.description, 1023);
    writer.u64(guild.founder.value());
    writer.u8(guild.camp);
    writer.u8(guild.level);
    writer.u32(guild.city.value());
    writer.i64(guild.funds);
    writer.i64(guild.war_points);
    for (const std::string& name : guild.position_names) writer.text(name, 255);
    writer.count(guild.members.size(), kMaxMembers);
    for (const GuildMember& member : guild.members) {
        writer.u64(member.id.value());
        writer.text(member.name, kMaxNameBytes);
        writer.u8(static_cast<std::uint8_t>(member.position));
        writer.u16(member.access);
        writer.u16(member.level);
        writer.u8(member.sect);
        writer.i64(member.contribution);
    }
    writer.count(guild.proposers.size(), kMaxProposers);
    for (const GuildProposer& proposer : guild.proposers) {
        writer.u64(proposer.id.value());
        writer.text(proposer.name, kMaxNameBytes);
        writer.u16(proposer.level);
        writer.u8(proposer.sect);
        writer.i64(proposer.expires > now ? (proposer.expires - now).count : 0);
    }
    return finish_blob(writer, blob::kGuild);
}

std::expected<Guild, CodecError> decode_guild(std::span<const std::byte> bytes, Tick now, const Limits& limits) {
    const auto body = open_blob(bytes, blob::kGuild);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    const std::uint16_t version = reader.u16();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (version != kGuildVersion) return std::unexpected(CodecError::kBadVersion);
    Guild guild;
    guild.id = GuildId{reader.u64()};
    guild.name = reader.text(255);
    guild.description = reader.text(1023);
    guild.founder = CharacterId{reader.u64()};
    guild.camp = reader.u8();
    guild.level = reader.u8();
    guild.city = CityId{reader.u32()};
    guild.funds = reader.i64();
    guild.war_points = reader.i64();
    for (std::string& name : guild.position_names) name = reader.text(255);
    const std::size_t member_count = reader.count(kMaxMembers);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    guild.members.reserve(member_count);
    for (std::size_t index = 0; index < member_count && reader.is_ok(); ++index) {
        GuildMember member;
        member.id = CharacterId{reader.u64()};
        member.name = reader.text(kMaxNameBytes);
        const std::uint8_t position = reader.u8();
        if (!valid_position(position)) return std::unexpected(CodecError::kBadValue);
        member.position = static_cast<GuildPosition>(position);
        member.access = reader.u16();
        member.level = reader.u16();
        member.sect = reader.u8();
        member.contribution = reader.i64();
        guild.members.push_back(std::move(member));
    }
    const std::size_t proposer_count = reader.count(kMaxProposers);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    guild.proposers.reserve(proposer_count);
    for (std::size_t index = 0; index < proposer_count && reader.is_ok(); ++index) {
        GuildProposer proposer;
        proposer.id = CharacterId{reader.u64()};
        proposer.name = reader.text(kMaxNameBytes);
        proposer.level = reader.u16();
        proposer.sect = reader.u8();
        const std::int64_t remaining = reader.i64();
        if (remaining < 0) return std::unexpected(CodecError::kBadValue);
        proposer.expires = ids::advance(now, TickSpan{remaining});
        guild.proposers.push_back(std::move(proposer));
    }
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (!guild_problem(guild, limits).empty()) return std::unexpected(CodecError::kBadValue);
    return guild;
}

CodecResult encode_league(const League& league, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kLeagueVersion);
    writer.u32(league.id.value());
    writer.text(league.name, 255);
    writer.u64(league.leader.value());
    writer.count(league.members.size(), kMaxLeagueGuilds);
    for (const GuildId member : league.members) writer.u64(member.value());
    return finish_blob(writer, blob::kLeague);
}

std::expected<League, CodecError> decode_league(std::span<const std::byte> bytes, const Limits& limits) {
    const auto body = open_blob(bytes, blob::kLeague);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    const std::uint16_t version = reader.u16();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (version != kLeagueVersion) return std::unexpected(CodecError::kBadVersion);
    League league;
    league.id = LeagueId{reader.u32()};
    league.name = reader.text(255);
    league.leader = GuildId{reader.u64()};
    const std::size_t count = reader.count(kMaxLeagueGuilds);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    league.members.reserve(count);
    for (std::size_t index = 0; index < count && reader.is_ok(); ++index) league.members.emplace_back(reader.u64());
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (!league_problem(league, limits).empty()) return std::unexpected(CodecError::kBadValue);
    return league;
}

} // namespace game::social
