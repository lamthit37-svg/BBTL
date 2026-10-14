#include "social/relation.hpp"

#include "ids/ids.hpp"
#include "protocol/wire.hpp"
#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
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

// Tên nhân vật là chữ do world cấp; bản sao trong sổ bị chặn để dữ liệu thù địch không phình sổ.
constexpr std::size_t kMaxNameBytes = 63;
constexpr std::size_t kMaxEntries = 2000;
constexpr std::size_t kMaxMentorRows = 8;
constexpr std::uint16_t kRelationVersion = 1;

[[nodiscard]] bool in_friend_list(RelationKind kind) noexcept {
    return kind == RelationKind::kFriend || kind == RelationKind::kSpouse || kind == RelationKind::kMaster ||
           kind == RelationKind::kPrentice;
}

[[nodiscard]] bool valid_kind(std::uint8_t raw) noexcept {
    return raw >= static_cast<std::uint8_t>(RelationKind::kFriend) && raw <= static_cast<std::uint8_t>(RelationKind::kPrentice);
}

[[nodiscard]] RelationEntry* find_entry(RelationSheet& sheet, CharacterId id) noexcept {
    const auto found = std::ranges::find(sheet.entries, id, &RelationEntry::id);
    return found == sheet.entries.end() ? nullptr : &*found;
}

[[nodiscard]] const RelationEntry* find_entry(const RelationSheet& sheet, CharacterId id) noexcept {
    const auto found = std::ranges::find(sheet.entries, id, &RelationEntry::id);
    return found == sheet.entries.end() ? nullptr : &*found;
}

void erase_entry(RelationSheet& sheet, CharacterId id) {
    std::erase_if(sheet.entries, [id](const RelationEntry& entry) { return entry.id == id; });
}

[[nodiscard]] std::int64_t count_if_kind(const RelationSheet& sheet, RelationKind kind) {
    return std::ranges::count(sheet.entries, kind, &RelationEntry::kind);
}

[[nodiscard]] std::int64_t friend_total(const RelationSheet& sheet) {
    return std::ranges::count_if(sheet.entries, [](const RelationEntry& e) { return in_friend_list(e.kind); });
}

[[nodiscard]] std::int64_t group_total(const RelationSheet& sheet, std::uint8_t group) {
    return std::ranges::count_if(sheet.entries, [group](const RelationEntry& e) {
        return e.kind == RelationKind::kFriend && e.group == group;
    });
}

// Nhóm bạn còn chỗ đầu tiên; kFriendGroups nếu hết.
[[nodiscard]] std::uint8_t first_free_group(const RelationSheet& sheet, std::int64_t per_group) {
    for (std::uint8_t group = 0; group < kFriendGroups; ++group) {
        if (group_total(sheet, group) < per_group) return group;
    }
    return kFriendGroups;
}

// Đổi loại của mục đã có (check_request đã bảo đảm mục tồn tại; thiếu thì không làm gì). Nhóm và mốc
// thưởng về 0 vì chỉ kFriend có nhóm và chỉ kMaster có mốc.
void retag(RelationSheet& sheet, CharacterId id, RelationKind kind) {
    RelationEntry* entry = find_entry(sheet, id);
    if (entry == nullptr) return;
    entry->kind = kind;
    entry->group = 0;
    entry->milestones = 0;
}

[[nodiscard]] RelationKind mirror_of(RelationKind kind) noexcept {
    switch (kind) {
    case RelationKind::kMaster: return RelationKind::kPrentice;
    case RelationKind::kPrentice: return RelationKind::kMaster;
    default: return kind;
    }
}

[[nodiscard]] RelationResult reject(RelationError error) {
    RelationResult result;
    result.error = error;
    return result;
}

[[nodiscard]] RelationEvent make_event(RelationEventKind kind, CharacterId subject, CharacterId other,
    std::vector<CharacterId> audience) {
    RelationEvent event;
    event.kind = kind;
    event.subject = subject;
    event.other = other;
    event.audience = std::move(audience);
    return event;
}

// Kiểm hình dạng một sổ so với trần. Chuỗi rỗng = hợp lệ.
[[nodiscard]] std::string_view sheet_problem(CharacterId owner, const RelationSheet& sheet, const Limits& limits) {
    if (!is_plain_text(sheet.mood, static_cast<std::size_t>(limits.relation_mood_max_bytes))) return "tâm trạng sai";
    if (sheet.moral_point < 0 || sheet.moral_point > limits.relation_max_moral_point) return "điểm sư đức ngoài miền";
    if (sheet.entries.size() > kMaxEntries) return "sổ quá lớn";
    std::set<CharacterId> seen;
    std::int64_t friends = 0;
    std::int64_t blacks = 0;
    std::int64_t enemies = 0;
    std::int64_t temps = 0;
    std::int64_t spouses = 0;
    std::int64_t masters = 0;
    std::int64_t prentices = 0;
    for (const RelationEntry& entry : sheet.entries) {
        if (entry.id == owner || entry.id.value() == 0) return "mục tự tham chiếu hoặc id 0";
        if (!seen.insert(entry.id).second) return "trùng id";
        if (!is_plain_text(entry.name, kMaxNameBytes)) return "tên sai";
        if (!valid_kind(static_cast<std::uint8_t>(entry.kind))) return "loại quan hệ lạ";
        if (entry.point < 0 || entry.point > limits.relation_max_friend_point) return "độ thân thiết ngoài miền";
        if (entry.kind != RelationKind::kMaster && entry.milestones != 0) return "mốc thưởng ở mục không phải sư phụ";
        if (entry.kind != RelationKind::kFriend && entry.group != 0) return "nhóm ở mục không phải bạn";
        if (entry.group >= kFriendGroups) return "nhóm bạn ngoài miền";
        if (!in_friend_list(entry.kind) && entry.point != 0) return "độ thân thiết ở mục không phải bạn";
        switch (entry.kind) {
        case RelationKind::kFriend: ++friends; break;
        case RelationKind::kSpouse: ++spouses; ++friends; break;
        case RelationKind::kMaster: ++masters; ++friends; break;
        case RelationKind::kPrentice: ++prentices; ++friends; break;
        case RelationKind::kBlack: ++blacks; break;
        case RelationKind::kEnemy: ++enemies; break;
        case RelationKind::kTemp: ++temps; break;
        }
    }
    if (friends > limits.relation_max_friends) return "quá trần bạn bè";
    if (blacks > limits.relation_max_blacklist) return "quá trần danh sách đen";
    if (enemies > limits.relation_max_enemies) return "quá trần kẻ thù";
    if (temps > limits.relation_max_temp_friends) return "quá trần bạn tạm";
    if (prentices > limits.relation_max_prentices) return "quá trần đồ đệ";
    if (spouses > 1 || masters > 1) return "nhiều hơn một vợ/chồng hoặc sư phụ";
    for (std::uint8_t group = 0; group < kFriendGroups; ++group) {
        if (group_total(sheet, group) > limits.relation_max_per_group) return "quá trần một nhóm bạn";
    }
    return {};
}

} // namespace

std::string_view describe(RelationError error) noexcept {
    switch (error) {
    case RelationError::kUnknownPlayer: return "không thấy người chơi";
    case RelationError::kSelf: return "không thể tự làm với bản thân";
    case RelationError::kAlready: return "đã có quan hệ này";
    case RelationError::kListFull: return "danh sách đã đầy";
    case RelationError::kGroupFull: return "nhóm đã đầy";
    case RelationError::kNotFound: return "không có trong danh sách";
    case RelationError::kBadGroup: return "nhóm không hợp lệ";
    case RelationError::kBadText: return "văn bản không hợp lệ";
    case RelationError::kRefused: return "đối phương từ chối";
    case RelationError::kInBlacklist: return "đang trong danh sách đen";
    case RelationError::kInEnemyList: return "đang trong danh sách kẻ thù";
    case RelationError::kNoPending: return "không có lời chờ trả lời";
    case RelationError::kTooManyPending: return "đối phương đang có quá nhiều lời chờ";
    case RelationError::kNotFriend: return "chưa là bạn bè";
    case RelationError::kPointTooLow: return "độ thân thiết chưa đủ";
    case RelationError::kSameSex: return "cùng giới";
    case RelationError::kAlreadyMarried: return "đã có vợ hoặc chồng";
    case RelationError::kHasMaster: return "đã có sư phụ";
    case RelationError::kPrenticeFull: return "sư phụ đã đủ đồ đệ";
    case RelationError::kLevelTooLow: return "cấp chưa đủ";
    case RelationError::kLevelTooHigh: return "cấp quá cao";
    case RelationError::kBetrayCooldown: return "đang trong thời gian chờ sau khi rời sư môn";
    case RelationError::kNotMaster: return "không phải sư phụ của người này";
    case RelationError::kNotPrentice: return "không phải đồ đệ";
    case RelationError::kNeedVerify: return "cần xác minh mật khẩu cấp hai";
    case RelationError::kBadKind: return "loại quan hệ không hợp lệ cho thao tác này";
    case RelationError::kNotLoaded: return "sổ quan hệ chưa được nạp";
    }
    return "lỗi quan hệ lạ";
}

// ---------------------------------------------------------------------------------------------
// MentorTable
// ---------------------------------------------------------------------------------------------

std::expected<MentorTable, std::string> MentorTable::parse(const MentorSources& sources) {
    MentorTable out;
    auto rewards = table::parse_tsv(sources.rewards_tsv);
    if (!rewards) return std::unexpected(std::move(rewards.error()));
    if (rewards->rows.size() > kMaxMentorRows) return std::unexpected("bảng thưởng sư đồ quá 8 hàng");
    std::uint16_t previous = 0;
    for (std::size_t row = 0; row < rewards->rows.size(); ++row) {
        table::RowReader reader(*rewards, row);
        MentorReward reward;
        reward.apprentice_level = static_cast<std::uint16_t>(reader.number("apprentice_level", 1, 1000));
        reward.exp_no_guild = reader.number("exp_reward_no_guild", 0, 2'000'000'000U);
        reward.exp_guild = reader.number("exp_reward_guild_1", 0, 2'000'000'000U);
        if (reader.error()) return std::unexpected(*reader.error());
        if (reward.apprentice_level <= previous) {
            return std::unexpected(std::format("dòng {}: cấp đồ đệ phải tăng dần", rewards->lines[row]));
        }
        previous = reward.apprentice_level;
        out.rewards_.push_back(reward);
    }
    auto share = table::parse_tsv(sources.share_tsv);
    if (!share) return std::unexpected(std::move(share.error()));
    if (share->rows.size() > 1000) return std::unexpected("bảng chia kinh nghiệm sư đồ quá 1000 hàng");
    for (std::size_t row = 0; row < share->rows.size(); ++row) {
        table::RowReader reader(*share, row);
        const std::uint32_t rank = reader.number("apprentice_rank", 0, 1000);
        const float value = reader.real("mentor_exp_share");
        if (reader.error()) return std::unexpected(*reader.error());
        if (value < 0.0F || value > 1.0F) {
            return std::unexpected(std::format("dòng {}: hệ số chia ngoài [0, 1]", share->lines[row]));
        }
        if (out.share_.size() <= rank) out.share_.resize(static_cast<std::size_t>(rank) + 1, 0.0);
        *std::next(out.share_.begin(), static_cast<std::ptrdiff_t>(rank)) = static_cast<double>(value);
    }
    return out;
}

double MentorTable::share_at(std::uint16_t level) const noexcept {
    return level < share_.size() ? share_[level] : 0.0;
}

// ---------------------------------------------------------------------------------------------
// RelationBook
// ---------------------------------------------------------------------------------------------

RelationBook::RelationBook(const Limits& limits, const RelationRules& rules)
    : limits_(limits),
      rules_(rules),
      pending_ttl_(seconds_to_ticks(limits.relation_pending_ttl_seconds)),
      betray_cooldown_(seconds_to_ticks(limits.relation_betray_cooldown_seconds)) {}

RelationSheet* RelationBook::mutable_sheet(CharacterId owner) {
    const auto found = sheets_.find(owner);
    return found == sheets_.end() ? nullptr : &found->second;
}

const RelationSheet* RelationBook::sheet(CharacterId owner) const {
    const auto found = sheets_.find(owner);
    return found == sheets_.end() ? nullptr : &found->second;
}

std::expected<void, std::string> RelationBook::load(CharacterId owner, RelationSheet incoming) {
    if (owner.value() == 0) return std::unexpected("chủ sổ id 0");
    if (const std::string_view problem = sheet_problem(owner, incoming, limits_); !problem.empty()) {
        return std::unexpected(std::string(problem));
    }
    sheets_.insert_or_assign(owner, std::move(incoming));
    return {};
}

std::optional<RelationSheet> RelationBook::unload(CharacterId owner) {
    const auto found = sheets_.find(owner);
    if (found == sheets_.end()) return std::nullopt;
    RelationSheet out = std::move(found->second);
    sheets_.erase(found);
    std::erase_if(pending_, [owner](const auto& item) {
        return item.first.target == owner || item.first.requester == owner;
    });
    return out;
}

std::optional<RelationError> RelationBook::check_request(
    Tick now, const PlayerDirectory& directory, BondKind kind, const PlayerCard& actor, const PlayerCard& target) const {
    if (actor.id == target.id) return RelationError::kSelf;
    const RelationSheet* mine = sheet(actor.id);
    const RelationSheet* theirs = sheet(target.id);
    if (mine == nullptr || theirs == nullptr) return RelationError::kNotLoaded;
    if (!actor.online || !target.online) return RelationError::kUnknownPlayer;
    if (directory.hostile(actor, target)) return RelationError::kRefused;
    const RelationEntry* mine_entry = find_entry(*mine, target.id);
    const RelationEntry* their_entry = find_entry(*theirs, actor.id);
    switch (kind) {
    case BondKind::kFriend: {
        if (target.has(setting::kCannotAddFriend)) return RelationError::kRefused;
        // Chặn mà không lộ: người bị đưa vào danh sách đen chỉ thấy "từ chối" như mọi lời từ chối khác.
        if (their_entry != nullptr && their_entry->kind == RelationKind::kBlack) return RelationError::kRefused;
        if (mine_entry != nullptr) {
            if (in_friend_list(mine_entry->kind)) return RelationError::kAlready;
            if (mine_entry->kind == RelationKind::kBlack) return RelationError::kInBlacklist;
            if (mine_entry->kind == RelationKind::kEnemy) return RelationError::kInEnemyList;
        }
        if (friend_total(*mine) >= limits_.relation_max_friends) return RelationError::kListFull;
        if (friend_total(*theirs) >= limits_.relation_max_friends) return RelationError::kListFull;
        if (first_free_group(*mine, limits_.relation_max_per_group) == kFriendGroups ||
            first_free_group(*theirs, limits_.relation_max_per_group) == kFriendGroups) {
            return RelationError::kGroupFull;
        }
        return std::nullopt;
    }
    case BondKind::kMarry: {
        if (mine_entry == nullptr || their_entry == nullptr || mine_entry->kind != RelationKind::kFriend ||
            their_entry->kind != RelationKind::kFriend) {
            return count_if_kind(*mine, RelationKind::kSpouse) > 0 || count_if_kind(*theirs, RelationKind::kSpouse) > 0
                       ? RelationError::kAlreadyMarried
                       : RelationError::kNotFriend;
        }
        if (count_if_kind(*mine, RelationKind::kSpouse) > 0 || count_if_kind(*theirs, RelationKind::kSpouse) > 0) {
            return RelationError::kAlreadyMarried;
        }
        if (mine_entry->point < limits_.relation_marry_min_friend_point) return RelationError::kPointTooLow;
        if (actor.sex == target.sex) return RelationError::kSameSex;
        return std::nullopt;
    }
    case BondKind::kRecruit:
    case BondKind::kApprentice: {
        const PlayerCard& master = kind == BondKind::kRecruit ? actor : target;
        const PlayerCard& prentice = kind == BondKind::kRecruit ? target : actor;
        const RelationSheet& master_sheet = kind == BondKind::kRecruit ? *mine : *theirs;
        const RelationSheet& prentice_sheet = kind == BondKind::kRecruit ? *theirs : *mine;
        if (mine_entry == nullptr || their_entry == nullptr || mine_entry->kind != RelationKind::kFriend ||
            their_entry->kind != RelationKind::kFriend) {
            return RelationError::kNotFriend;
        }
        if (std::cmp_less(master.level, limits_.relation_master_min_level)) return RelationError::kLevelTooLow;
        if (std::cmp_greater(prentice.level, limits_.relation_prentice_max_level)) return RelationError::kLevelTooHigh;
        if (count_if_kind(prentice_sheet, RelationKind::kMaster) > 0) return RelationError::kHasMaster;
        if (count_if_kind(master_sheet, RelationKind::kPrentice) >= limits_.relation_max_prentices) {
            return RelationError::kPrenticeFull;
        }
        if (prentice_sheet.betray_until > now) return RelationError::kBetrayCooldown;
        return std::nullopt;
    }
    }
    return RelationError::kBadKind;
}

RelationResult RelationBook::request(
    Tick now, const PlayerDirectory& directory, BondKind kind, CharacterId actor, CharacterId target) {
    tick(now);
    const auto actor_card = directory.find(actor);
    const auto target_card = directory.find(target);
    if (!actor_card || !target_card) return reject(RelationError::kUnknownPlayer);
    if (const auto problem = check_request(now, directory, kind, *actor_card, *target_card)) return reject(*problem);
    const PendingKey key{.target = target, .kind = kind, .requester = actor};
    if (!pending_.contains(key)) {
        const auto first = pending_.lower_bound(PendingKey{.target = target, .kind = BondKind::kFriend, .requester = CharacterId{}});
        std::int64_t waiting = 0;
        for (auto it = first; it != pending_.end() && it->first.target == target; ++it) ++waiting;
        if (waiting >= limits_.relation_max_pending) return reject(RelationError::kTooManyPending);
    }
    pending_.insert_or_assign(key, advance(now, pending_ttl_));
    RelationResult result;
    RelationEvent event = make_event(RelationEventKind::kBondAsk, actor, target, {target});
    event.value = static_cast<std::int64_t>(kind);
    event.text = actor_card->name;
    result.events.push_back(std::move(event));
    return result;
}

RelationResult RelationBook::answer(Tick now, const PlayerDirectory& directory, BondKind kind, CharacterId answerer,
    CharacterId requester, bool accept) {
    tick(now);
    const PendingKey key{.target = answerer, .kind = kind, .requester = requester};
    const auto found = pending_.find(key);
    if (found == pending_.end()) return reject(RelationError::kNoPending);
    pending_.erase(found);  // đã trả lời thì lời chờ hết tác dụng, kể cả khi lệnh bị từ chối ở dưới
    RelationResult result;
    if (!accept) {
        RelationEvent event = make_event(RelationEventKind::kBondRefused, answerer, requester, {requester});
        event.value = static_cast<std::int64_t>(kind);
        result.events.push_back(std::move(event));
        return result;
    }
    const auto requester_card = directory.find(requester);
    const auto answerer_card = directory.find(answerer);
    if (!requester_card || !answerer_card) return reject(RelationError::kUnknownPlayer);
    if (const auto problem = check_request(now, directory, kind, *requester_card, *answerer_card)) {
        RelationEvent notice = make_event(RelationEventKind::kNotice, answerer, requester, {requester});
        notice.error = *problem;
        result.events.push_back(std::move(notice));
        result.error = *problem;
        return result;
    }
    apply_bond(kind, *requester_card, *answerer_card, now, result.events);
    return result;
}

void RelationBook::apply_bond(
    BondKind kind, const PlayerCard& requester, const PlayerCard& answerer, Tick /*now*/, RelationEvents& out) {
    RelationSheet& req_sheet = *mutable_sheet(requester.id);
    RelationSheet& ans_sheet = *mutable_sheet(answerer.id);
    switch (kind) {
    case BondKind::kFriend: {
        const std::uint8_t req_group = first_free_group(req_sheet, limits_.relation_max_per_group);
        const std::uint8_t ans_group = first_free_group(ans_sheet, limits_.relation_max_per_group);
        // Bạn tạm và bạn tạm ngược lại nhường chỗ cho bạn thật.
        erase_entry(req_sheet, answerer.id);
        erase_entry(ans_sheet, requester.id);
        req_sheet.entries.push_back(RelationEntry{.id = answerer.id, .name = answerer.name, .kind = RelationKind::kFriend, .group = req_group});
        ans_sheet.entries.push_back(RelationEntry{.id = requester.id, .name = requester.name, .kind = RelationKind::kFriend, .group = ans_group});
        RelationEvent event = make_event(RelationEventKind::kFriendAdded, requester.id, answerer.id, {requester.id, answerer.id});
        event.group = req_group;
        out.push_back(std::move(event));
        return;
    }
    case BondKind::kMarry: {
        retag(req_sheet, answerer.id, RelationKind::kSpouse);
        retag(ans_sheet, requester.id, RelationKind::kSpouse);
        out.push_back(make_event(RelationEventKind::kMarried, requester.id, answerer.id, {requester.id, answerer.id}));
        return;
    }
    case BondKind::kRecruit:
    case BondKind::kApprentice: {
        const bool requester_is_master = kind == BondKind::kRecruit;
        RelationSheet& master_sheet = requester_is_master ? req_sheet : ans_sheet;
        RelationSheet& prentice_sheet = requester_is_master ? ans_sheet : req_sheet;
        const PlayerCard& master = requester_is_master ? requester : answerer;
        const PlayerCard& prentice = requester_is_master ? answerer : requester;
        retag(master_sheet, prentice.id, RelationKind::kPrentice);
        retag(prentice_sheet, master.id, RelationKind::kMaster);
        out.push_back(make_event(RelationEventKind::kRecruited, master.id, prentice.id, {master.id, prentice.id}));
        return;
    }
    }
}

RelationResult RelationBook::remove(CharacterId actor, CharacterId target, bool verified) {
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const RelationEntry* entry = find_entry(*mine, target);
    if (entry == nullptr) return reject(RelationError::kNotFound);
    const RelationKind kind = entry->kind;
    if (kind != RelationKind::kFriend && kind != RelationKind::kBlack && kind != RelationKind::kEnemy &&
        kind != RelationKind::kTemp) {
        return reject(RelationError::kBadKind);  // vợ chồng, sư đồ huỷ bằng thao tác riêng
    }
    if (kind == RelationKind::kFriend && entry->point >= rules_.password_intimacy && !verified) {
        return reject(RelationError::kNeedVerify);
    }
    erase_entry(*mine, target);
    RelationResult result;
    result.events.push_back(make_event(RelationEventKind::kRemoved, target, actor, {actor}));
    if (kind == RelationKind::kFriend) {
        if (RelationSheet* theirs = mutable_sheet(target)) {
            const RelationEntry* back = find_entry(*theirs, actor);
            if (back != nullptr && back->kind == RelationKind::kFriend) {
                erase_entry(*theirs, actor);
                result.events.push_back(make_event(RelationEventKind::kPeerRemoved, actor, target, {target}));
            }
        } else {
            RelationEvent offline = make_event(RelationEventKind::kOfflineChange, actor, target, {});
            offline.value = 0;
            result.events.push_back(std::move(offline));
        }
    }
    return result;
}

RelationResult RelationBook::blacklist(const PlayerDirectory& directory, CharacterId actor, CharacterId target) {
    if (actor == target) return reject(RelationError::kSelf);
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto card = directory.find(target);
    if (!card) return reject(RelationError::kUnknownPlayer);
    const RelationEntry* entry = find_entry(*mine, target);
    RelationResult result;
    if (entry != nullptr) {
        switch (entry->kind) {
        case RelationKind::kBlack: return reject(RelationError::kAlready);
        case RelationKind::kSpouse:
        case RelationKind::kMaster:
        case RelationKind::kPrentice: return reject(RelationError::kBadKind);
        case RelationKind::kFriend:
        case RelationKind::kEnemy:
        case RelationKind::kTemp: break;
        }
    }
    const bool was_friend = entry != nullptr && entry->kind == RelationKind::kFriend;
    if (count_if_kind(*mine, RelationKind::kBlack) >= limits_.relation_max_blacklist) return reject(RelationError::kListFull);
    erase_entry(*mine, target);
    mine->entries.push_back(RelationEntry{.id = target, .name = card->name, .kind = RelationKind::kBlack});
    result.events.push_back(make_event(RelationEventKind::kBlacklisted, target, actor, {actor}));
    if (was_friend) {
        if (RelationSheet* theirs = mutable_sheet(target)) {
            const RelationEntry* back = find_entry(*theirs, actor);
            if (back != nullptr && back->kind == RelationKind::kFriend) {
                erase_entry(*theirs, actor);
                result.events.push_back(make_event(RelationEventKind::kPeerRemoved, actor, target, {target}));
            }
        } else {
            result.events.push_back(make_event(RelationEventKind::kOfflineChange, actor, target, {}));
        }
    }
    return result;
}

namespace {

// Thêm một mục một chiều (kẻ thù, bạn tạm) vào cuối; đầy thì bỏ mục cũ nhất cùng loại.
void push_with_eviction(RelationSheet& sheet, RelationEntry entry, std::int64_t cap) {
    const RelationKind kind = entry.kind;
    while (std::ranges::count(sheet.entries, kind, &RelationEntry::kind) >= cap) {
        const auto oldest = std::ranges::find(sheet.entries, kind, &RelationEntry::kind);
        if (oldest == sheet.entries.end()) break;
        sheet.entries.erase(oldest);
    }
    sheet.entries.push_back(std::move(entry));
}

} // namespace

RelationResult RelationBook::note_enemy(const PlayerDirectory& directory, CharacterId actor, CharacterId killer) {
    if (actor == killer) return reject(RelationError::kSelf);
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto card = directory.find(killer);
    if (!card) return reject(RelationError::kUnknownPlayer);
    RelationResult result;
    if (find_entry(*mine, killer) != nullptr) return result;  // bạn, đen, đã là kẻ thù: giữ nguyên
    push_with_eviction(*mine, RelationEntry{.id = killer, .name = card->name, .kind = RelationKind::kEnemy}, limits_.relation_max_enemies);
    result.events.push_back(make_event(RelationEventKind::kEnemyAdded, killer, actor, {actor}));
    return result;
}

RelationResult RelationBook::note_temp(const PlayerDirectory& directory, CharacterId actor, CharacterId other) {
    if (actor == other) return reject(RelationError::kSelf);
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto card = directory.find(other);
    if (!card) return reject(RelationError::kUnknownPlayer);
    RelationResult result;
    if (find_entry(*mine, other) != nullptr) return result;
    push_with_eviction(*mine, RelationEntry{.id = other, .name = card->name, .kind = RelationKind::kTemp}, limits_.relation_max_temp_friends);
    return result;
}

RelationResult RelationBook::move_group(CharacterId actor, CharacterId friend_id, std::uint8_t group) {
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    if (group >= kFriendGroups) return reject(RelationError::kBadGroup);
    RelationEntry* entry = find_entry(*mine, friend_id);
    if (entry == nullptr) return reject(RelationError::kNotFound);
    if (entry->kind != RelationKind::kFriend) return reject(RelationError::kBadKind);
    RelationResult result;
    if (entry->group == group) return result;
    if (group_total(*mine, group) >= limits_.relation_max_per_group) return reject(RelationError::kGroupFull);
    entry->group = group;
    RelationEvent event = make_event(RelationEventKind::kGroupMoved, friend_id, actor, {actor});
    event.group = group;
    result.events.push_back(std::move(event));
    return result;
}

RelationResult RelationBook::set_mood(const PlayerDirectory& directory, CharacterId actor, std::string_view text) {
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    if (!is_plain_text(text, static_cast<std::size_t>(limits_.relation_mood_max_bytes))) return reject(RelationError::kBadText);
    RelationResult result;
    if (mine->mood == text) return result;
    mine->mood = std::string(text);
    std::vector<CharacterId> audience;
    for (const RelationEntry& entry : mine->entries) {
        if (!in_friend_list(entry.kind)) continue;
        const auto card = directory.find(entry.id);
        if (card && card->online) audience.push_back(entry.id);
    }
    RelationEvent event = make_event(RelationEventKind::kMoodChanged, actor, CharacterId{}, std::move(audience));
    event.text = mine->mood;
    result.events.push_back(std::move(event));
    return result;
}

RelationResult RelationBook::add_point(CharacterId left, CharacterId right, std::int32_t delta) {
    if (left == right) return reject(RelationError::kSelf);
    RelationSheet* left_sheet = mutable_sheet(left);
    RelationSheet* right_sheet = mutable_sheet(right);
    if (left_sheet == nullptr || right_sheet == nullptr) return reject(RelationError::kNotLoaded);
    RelationEntry* a = find_entry(*left_sheet, right);
    RelationEntry* b = find_entry(*right_sheet, left);
    if (a == nullptr || b == nullptr || !in_friend_list(a->kind) || !in_friend_list(b->kind)) {
        return reject(RelationError::kNotFriend);
    }
    const std::int64_t wanted = std::clamp<std::int64_t>(
        std::int64_t{a->point} + delta, 0, limits_.relation_max_friend_point);
    RelationResult result;
    const auto next = static_cast<std::int32_t>(wanted);
    if (a->point == next && b->point == next) return result;
    a->point = next;
    b->point = next;
    RelationEvent event = make_event(RelationEventKind::kPointChanged, left, right, {left, right});
    event.value = next;
    result.events.push_back(std::move(event));
    return result;
}

RelationResult RelationBook::divorce(CharacterId actor) {
    RelationSheet* mine = mutable_sheet(actor);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto spouse = std::ranges::find(mine->entries, RelationKind::kSpouse, &RelationEntry::kind);
    if (spouse == mine->entries.end()) return reject(RelationError::kNotFound);
    const CharacterId other = spouse->id;
    spouse->kind = RelationKind::kFriend;
    spouse->group = std::min(first_free_group(*mine, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
    RelationResult result;
    if (RelationSheet* theirs = mutable_sheet(other)) {
        if (RelationEntry* back = find_entry(*theirs, actor); back != nullptr && back->kind == RelationKind::kSpouse) {
            back->kind = RelationKind::kFriend;
            back->group = std::min(first_free_group(*theirs, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
        }
        result.events.push_back(make_event(RelationEventKind::kDivorced, actor, other, {actor, other}));
    } else {
        RelationEvent offline = make_event(RelationEventKind::kOfflineChange, actor, other, {});
        offline.value = static_cast<std::int64_t>(RelationKind::kFriend);
        result.events.push_back(make_event(RelationEventKind::kDivorced, actor, other, {actor}));
        result.events.push_back(std::move(offline));
    }
    return result;
}

RelationResult RelationBook::leave_master(Tick now, CharacterId prentice) {
    RelationSheet* mine = mutable_sheet(prentice);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto master_entry = std::ranges::find(mine->entries, RelationKind::kMaster, &RelationEntry::kind);
    if (master_entry == mine->entries.end()) return reject(RelationError::kNotPrentice);
    const CharacterId master = master_entry->id;
    master_entry->kind = RelationKind::kFriend;
    master_entry->milestones = 0;
    master_entry->group = std::min(first_free_group(*mine, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
    mine->betray_until = advance(now, betray_cooldown_);
    RelationResult result;
    std::vector<CharacterId> audience{prentice};
    if (RelationSheet* theirs = mutable_sheet(master)) {
        if (RelationEntry* back = find_entry(*theirs, prentice); back != nullptr && back->kind == RelationKind::kPrentice) {
            back->kind = RelationKind::kFriend;
            back->group = std::min(first_free_group(*theirs, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
        }
        audience.push_back(master);
    } else {
        RelationEvent offline = make_event(RelationEventKind::kOfflineChange, prentice, master, {});
        offline.value = static_cast<std::int64_t>(RelationKind::kFriend);
        result.events.push_back(std::move(offline));
    }
    RelationEvent event = make_event(RelationEventKind::kPrenticeLeft, prentice, master, std::move(audience));
    event.value = 1;
    result.events.insert(result.events.begin(), std::move(event));
    return result;
}

RelationResult RelationBook::expel_prentice(CharacterId master, CharacterId prentice) {
    RelationSheet* mine = mutable_sheet(master);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    RelationEntry* entry = find_entry(*mine, prentice);
    if (entry == nullptr || entry->kind != RelationKind::kPrentice) return reject(RelationError::kNotMaster);
    entry->kind = RelationKind::kFriend;
    entry->group = std::min(first_free_group(*mine, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
    RelationResult result;
    std::vector<CharacterId> audience{master};
    if (RelationSheet* theirs = mutable_sheet(prentice)) {
        if (RelationEntry* back = find_entry(*theirs, master); back != nullptr && back->kind == RelationKind::kMaster) {
            back->kind = RelationKind::kFriend;
            back->milestones = 0;
            back->group = std::min(first_free_group(*theirs, limits_.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
        }
        audience.push_back(prentice);
    } else {
        RelationEvent offline = make_event(RelationEventKind::kOfflineChange, master, prentice, {});
        offline.value = static_cast<std::int64_t>(RelationKind::kFriend);
        result.events.push_back(std::move(offline));
    }
    result.events.insert(result.events.begin(), make_event(RelationEventKind::kPrenticeExpelled, master, prentice, std::move(audience)));
    return result;
}

RelationResult RelationBook::on_prentice_level(const PlayerDirectory& directory, const MentorTable& table, CharacterId prentice,
    std::uint16_t level) {
    RelationSheet* mine = mutable_sheet(prentice);
    if (mine == nullptr) return reject(RelationError::kNotLoaded);
    const auto master_entry = std::ranges::find(mine->entries, RelationKind::kMaster, &RelationEntry::kind);
    RelationResult result;
    if (master_entry == mine->entries.end()) return result;
    const CharacterId master = master_entry->id;
    RelationSheet* theirs = mutable_sheet(master);
    if (theirs == nullptr) return reject(RelationError::kNotLoaded);
    const RelationEntry* back = find_entry(*theirs, prentice);
    if (back == nullptr || back->kind != RelationKind::kPrentice) return reject(RelationError::kNotMaster);
    const auto master_card = directory.find(master);
    const bool in_guild = master_card && master_card->guild.value() != 0;
    const auto& rows = table.rewards();
    for (std::size_t index = 0; index < rows.size() && index < kMaxMentorRows; ++index) {
        const auto bit = static_cast<std::uint8_t>(1U << index);
        if (level < rows[index].apprentice_level || (master_entry->milestones & bit) != 0) continue;
        master_entry->milestones = static_cast<std::uint8_t>(master_entry->milestones | bit);
        theirs->moral_point = std::min<std::int64_t>(
            theirs->moral_point + limits_.relation_moral_per_milestone, limits_.relation_max_moral_point);
        RelationEvent event = make_event(RelationEventKind::kMentorReward, master, prentice, {master});
        event.value = in_guild ? rows[index].exp_guild : rows[index].exp_no_guild;
        event.level = rows[index].apprentice_level;
        result.events.push_back(std::move(event));
    }
    return result;
}

RelationEvents RelationBook::on_presence(const PlayerDirectory& directory, CharacterId actor, bool online) const {
    RelationEvents out;
    const RelationSheet* mine = sheet(actor);
    if (mine == nullptr) return out;
    std::vector<CharacterId> audience;
    for (const RelationEntry& entry : mine->entries) {
        if (!in_friend_list(entry.kind) || entry.point < rules_.presence_intimacy) continue;
        const auto card = directory.find(entry.id);
        if (card && card->online) audience.push_back(entry.id);
    }
    if (audience.empty()) return out;
    RelationEvent event = make_event(RelationEventKind::kPresence, actor, CharacterId{}, std::move(audience));
    event.value = online ? 1 : 0;
    out.push_back(std::move(event));
    return out;
}

void RelationBook::tick(Tick now) {
    std::erase_if(pending_, [now](const auto& item) { return item.second <= now; });
}

std::expected<void, std::string> RelationBook::validate() const {
    for (const auto& [owner, mine] : sheets_) {
        if (const std::string_view problem = sheet_problem(owner, mine, limits_); !problem.empty()) {
            return std::unexpected(std::format("sổ {}: {}", owner.value(), problem));
        }
        for (const RelationEntry& entry : mine.entries) {
            if (entry.kind == RelationKind::kBlack || entry.kind == RelationKind::kEnemy || entry.kind == RelationKind::kTemp) {
                continue;
            }
            const RelationSheet* theirs = sheet(entry.id);
            if (theirs == nullptr) continue;
            const RelationEntry* back = find_entry(*theirs, owner);
            if (back == nullptr || back->kind != mirror_of(entry.kind) || back->point != entry.point) {
                return std::unexpected(std::format("quan hệ {} - {} lệch hai chiều", owner.value(), entry.id.value()));
            }
        }
    }
    for (const auto& [key, expires] : pending_) {
        static_cast<void>(expires);
        if (sheet(key.target) == nullptr || sheet(key.requester) == nullptr) {
            return std::unexpected("lời chờ trỏ vào sổ chưa nạp");
        }
    }
    return {};
}

bool apply_offline_change(const Limits& limits, RelationSheet& sheet, const RelationEvent& event) {
    if (event.kind != RelationEventKind::kOfflineChange) return false;
    RelationEntry* entry = find_entry(sheet, event.subject);
    if (entry == nullptr) return false;
    if (event.value == 0) {
        // Người kia xoá hoặc đưa mình vào danh sách đen: chỉ mục bạn thường mất theo (như nhánh cả hai đang nạp).
        if (entry->kind != RelationKind::kFriend) return false;
        erase_entry(sheet, event.subject);
        return true;
    }
    if (event.value != static_cast<std::int64_t>(RelationKind::kFriend)) return false;
    // Ly hôn, đồ đệ rời sư môn, sư phụ đuổi đồ đệ: mục thành bạn thường ở nhóm còn chỗ đầu tiên.
    if (entry->kind != RelationKind::kSpouse && entry->kind != RelationKind::kMaster && entry->kind != RelationKind::kPrentice) return false;
    const std::uint8_t group = std::min(first_free_group(sheet, limits.relation_max_per_group), static_cast<std::uint8_t>(kFriendGroups - 1));
    retag(sheet, event.subject, RelationKind::kFriend);
    entry->group = group;
    return true;
}

// ---------------------------------------------------------------------------------------------
// Mã hoá
// ---------------------------------------------------------------------------------------------

CodecResult encode_relation(const RelationSheet& sheet, Tick now, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kRelationVersion);
    writer.text(sheet.mood, 255);
    writer.i64(sheet.moral_point);
    const std::int64_t remaining = sheet.betray_until > now ? (sheet.betray_until - now).count : 0;
    writer.i64(remaining);
    writer.count(sheet.entries.size(), kMaxEntries);
    for (const RelationEntry& entry : sheet.entries) {
        writer.u64(entry.id.value());
        writer.text(entry.name, kMaxNameBytes);
        writer.u8(static_cast<std::uint8_t>(entry.kind));
        writer.u8(entry.group);
        writer.i32(entry.point);
        writer.u8(entry.milestones);
    }
    return finish_blob(writer, blob::kRelation);
}

std::expected<RelationSheet, CodecError> decode_relation(std::span<const std::byte> bytes, Tick now, const Limits& limits) {
    const auto body = open_blob(bytes, blob::kRelation);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    if (reader.u16() != kRelationVersion) return std::unexpected(reader.is_ok() ? CodecError::kBadVersion : CodecError::kTruncated);
    RelationSheet sheet;
    sheet.mood = reader.text(255);
    sheet.moral_point = reader.i64();
    const std::int64_t remaining = reader.i64();
    const std::size_t count = reader.count(kMaxEntries);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    sheet.entries.reserve(count);
    for (std::size_t index = 0; index < count && reader.is_ok(); ++index) {
        RelationEntry entry;
        entry.id = CharacterId{reader.u64()};
        entry.name = reader.text(kMaxNameBytes);
        const std::uint8_t kind = reader.u8();
        if (!valid_kind(kind)) return std::unexpected(CodecError::kBadValue);
        entry.kind = static_cast<RelationKind>(kind);
        entry.group = reader.u8();
        entry.point = reader.i32();
        entry.milestones = reader.u8();
        sheet.entries.push_back(std::move(entry));
    }
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (remaining < 0) return std::unexpected(CodecError::kBadValue);
    sheet.betray_until = advance(now, TickSpan{remaining});
    // Chủ sổ không có trong khối; id 0 dùng thay chủ để kiểm hình dạng (mục tự tham chiếu đã bị id 0 chặn).
    if (!sheet_problem(CharacterId{std::uint64_t{0xFFFF'FFFF'FFFF'FFFFULL}}, sheet, limits).empty()) {
        return std::unexpected(CodecError::kBadValue);
    }
    return sheet;
}

} // namespace game::social
