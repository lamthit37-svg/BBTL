#include "social/team.hpp"

#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <expected>
#include <format>
#include <iterator>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint8_t kNoClientCode = 255;

[[nodiscard]] TeamResult rejected(TeamError error, TeamEvents events = {}) {
    return TeamResult{.events = std::move(events), .error = error};
}

[[nodiscard]] TeamResult accepted(TeamEvents events) {
    return TeamResult{.events = std::move(events), .error = std::nullopt};
}

[[nodiscard]] TeamEvent make_event(TeamEventKind kind, TeamId team, CharacterId subject) {
    TeamEvent event;
    event.kind = kind;
    event.team = team;
    event.subject = subject;
    return event;
}

template <class Range>
[[nodiscard]] bool has_id(const Range& range, CharacterId id) {
    return std::ranges::find(range, id) != range.end();
}

[[nodiscard]] std::vector<CharacterId> without(std::vector<CharacterId> ids, CharacterId removed) {
    std::erase(ids, removed);
    return ids;
}

} // namespace

std::uint8_t client_code(TeamError error) noexcept {
    switch (error) {
    case TeamError::kInviteDestHasTeam: return 0;
    case TeamError::kInviteRefuse: return 1;
    case TeamError::kInviteTeamFull: return 2;
    case TeamError::kInviteLeaderRefuse: return 3;
    case TeamError::kDismissNotLeader: return 4;
    case TeamError::kKickNotLeader: return 5;
    case TeamError::kApplySourHasTeam: return 6;
    case TeamError::kApplyDestHasNoTeam: return 7;
    case TeamError::kApplyLeaderRefuse: return 8;
    case TeamError::kApplyTeamFull: return 9;
    case TeamError::kApplyLeaderChanged: return 10;
    case TeamError::kAppointSourNoTeam: return 11;
    case TeamError::kAppointDestNoTeam: return 12;
    case TeamError::kAppointNotSameTeam: return 13;
    case TeamError::kAppointSourNotLeader: return 14;
    case TeamError::kApplyLeaderCannotAnswer: return 15;
    case TeamError::kInviterNotInTeam: return 16;
    case TeamError::kApplyWhenInTeam: return 17;
    case TeamError::kTeamFull: return 18;
    case TeamError::kRefuseInviteSetting: return 19;
    case TeamError::kTargetNotOnline: return 20;
    case TeamError::kNotLeader: return 4;
    case TeamError::kUnknownPlayer:
    case TeamError::kNotInTeam:
    case TeamError::kNoPending:
    case TeamError::kTooManyPending:
    case TeamError::kHostile:
    case TeamError::kTooManyTeams:
    case TeamError::kNotFollowable:
    case TeamError::kBadValue: return kNoClientCode;
    }
    return kNoClientCode;
}

std::string_view describe(TeamError error) noexcept {
    switch (error) {
    case TeamError::kInviteDestHasTeam: return "người được mời đã có đội";
    case TeamError::kInviteRefuse: return "người được mời từ chối";
    case TeamError::kInviteTeamFull: return "đội của người mời đã đầy";
    case TeamError::kInviteLeaderRefuse: return "đội trưởng không đồng ý cho người này vào";
    case TeamError::kDismissNotLeader: return "người giải tán đội không phải đội trưởng";
    case TeamError::kKickNotLeader: return "người đuổi không phải đội trưởng";
    case TeamError::kApplySourHasTeam: return "người xin vào đã có đội";
    case TeamError::kApplyDestHasNoTeam: return "người được xin không có đội";
    case TeamError::kApplyLeaderRefuse: return "đội trưởng từ chối đơn xin vào";
    case TeamError::kApplyTeamFull: return "đội đã đầy";
    case TeamError::kApplyLeaderChanged: return "đội trưởng đã đổi";
    case TeamError::kAppointSourNoTeam: return "đội trưởng cũ không ở trong đội";
    case TeamError::kAppointDestNoTeam: return "đội trưởng mới không ở trong đội";
    case TeamError::kAppointNotSameTeam: return "hai người không cùng đội";
    case TeamError::kAppointSourNotLeader: return "người giao quyền không còn là đội trưởng";
    case TeamError::kApplyLeaderCannotAnswer: return "đội trưởng chưa trả lời được";
    case TeamError::kInviterNotInTeam: return "người mời không còn trong đội của đội trưởng";
    case TeamError::kApplyWhenInTeam: return "đang ở trong đội không thể xin vào đội khác";
    case TeamError::kTeamFull: return "đội đã đầy";
    case TeamError::kRefuseInviteSetting: return "đối phương đặt từ chối lời mời vào đội";
    case TeamError::kTargetNotOnline: return "đối phương không trực tuyến";
    case TeamError::kUnknownPlayer: return "không tìm thấy người chơi";
    case TeamError::kNotInTeam: return "không ở trong đội";
    case TeamError::kNotLeader: return "chỉ đội trưởng làm được";
    case TeamError::kNoPending: return "không có lời mời hay đơn xin còn hiệu lực";
    case TeamError::kTooManyPending: return "quá nhiều lời mời đang chờ";
    case TeamError::kHostile: return "hai bên thù địch";
    case TeamError::kTooManyTeams: return "máy chủ đã đủ số đội";
    case TeamError::kNotFollowable: return "không theo đội trưởng được";
    case TeamError::kBadValue: return "giá trị không hợp lệ";
    }
    return "lỗi đội không rõ";
}

TeamBook::TeamBook(const Limits& limits)
    : limits_(limits),
      pending_ttl_(seconds_to_ticks(limits.team_pending_ttl_seconds)),
      offline_grace_(seconds_to_ticks(limits.team_offline_grace_seconds)) {}

Team* TeamBook::mutable_team_of(CharacterId member) {
    const auto link = member_team_.find(member);
    return link == member_team_.end() ? nullptr : mutable_find(link->second);
}

Team* TeamBook::mutable_find(TeamId id) {
    const auto found = teams_.find(id);
    return found == teams_.end() ? nullptr : &found->second;
}

std::vector<CharacterId> TeamBook::ids_of(const Team& team) {
    std::vector<CharacterId> ids;
    ids.reserve(team.members.size());
    for (const TeamMember& member : team.members) {
        ids.push_back(member.id);
    }
    return ids;
}

void TeamBook::notice(TeamEvents& out, CharacterId to, TeamError error, CharacterId subject) const {
    TeamEvent event = make_event(TeamEventKind::kNotice, TeamId{}, subject);
    event.error = error;
    event.audience = {to};
    out.push_back(std::move(event));
}

const TeamBook::Pending* TeamBook::find_pending(const PendingKey& key) const {
    const auto found = pending_.find(key);
    return found == pending_.end() ? nullptr : &found->second;
}

void TeamBook::remove_pending(const PendingKey& key) {
    const auto found = pending_.find(key);
    if (found == pending_.end()) return;
    for (auto* counts : {&held_count_, &sent_count_}) {
        const CharacterId who = counts == &held_count_ ? found->second.holder : found->second.sender;
        const auto count = counts->find(who);
        if (count != counts->end() && --count->second == 0) counts->erase(count);
    }
    pending_.erase(found);
}

std::optional<TeamError> TeamBook::add_pending(
    Tick now, const PendingKey& key, CharacterId from, CharacterId to, TeamId team) {
    // Lời mời trùng khoá là mời lại: thay bản cũ, không cộng dồn.
    remove_pending(key);
    if (std::cmp_greater_equal(held_count_[to], limits_.team_max_pending_per_target) ||
        std::cmp_greater_equal(sent_count_[from], limits_.team_max_pending_per_sender)) {
        // operator[] vừa tạo ô 0 cho người chưa có lời nào: dọn để map không phình theo id lạ.
        if (held_count_[to] == 0) held_count_.erase(to);
        if (sent_count_[from] == 0) sent_count_.erase(from);
        return TeamError::kTooManyPending;
    }
    Pending pending;
    pending.sender = from;
    pending.holder = to;
    pending.team = team;
    pending.expires = ids::advance(now, pending_ttl_);
    pending.serial = next_serial_++;
    ++held_count_[to];
    ++sent_count_[from];
    expiry_.push_back(Expiry{.expires = pending.expires, .key = key, .serial = pending.serial});
    pending_.insert_or_assign(key, pending);
    compact_expiry();
    return std::nullopt;
}

void TeamBook::compact_expiry() {
    // Mỗi lời mời đã trả lời để lại một mục chết trong hàng hết hạn; chặn hàng phình khi bị lạm dụng.
    if (expiry_.size() <= (pending_.size() * 4U) + 256U) return;
    std::vector<Expiry> live;
    live.reserve(pending_.size());
    for (const auto& [key, pending] : pending_) {
        live.push_back(Expiry{.expires = pending.expires, .key = key, .serial = pending.serial});
    }
    std::ranges::sort(live, [](const Expiry& left, const Expiry& right) {
        return left.expires != right.expires ? left.expires < right.expires : left.serial < right.serial;
    });
    expiry_.assign(live.begin(), live.end());
}

void TeamBook::expire(Tick now) {
    while (!expiry_.empty() && expiry_.front().expires <= now) {
        const Expiry entry = expiry_.front();
        expiry_.pop_front();
        const Pending* pending = find_pending(entry.key);
        if (pending != nullptr && pending->serial == entry.serial) remove_pending(entry.key);
    }
}

TeamId TeamBook::create_team(const PlayerCard& leader, TeamEvents& out) {
    const TeamId id{next_team_++};
    Team team;
    team.id = id;
    team.members.push_back(TeamMember{.id = leader.id, .scene = leader.scene});
    teams_.emplace(id, std::move(team));
    member_team_.emplace(leader.id, id);
    TeamEvent created = make_event(TeamEventKind::kCreated, id, leader.id);
    created.audience = {leader.id};
    out.push_back(std::move(created));
    TeamEvent roster = make_event(TeamEventKind::kRoster, id, leader.id);
    roster.members = {leader.id};
    roster.audience = {leader.id};
    out.push_back(std::move(roster));
    return id;
}

void TeamBook::join_team(Team& team, const PlayerCard& member, TeamEvents& out) {
    team.members.push_back(TeamMember{.id = member.id, .scene = member.scene});
    member_team_.emplace(member.id, team.id);
    TeamEvent joined = make_event(TeamEventKind::kMemberJoined, team.id, member.id);
    joined.audience = ids_of(team);
    out.push_back(std::move(joined));
    TeamEvent roster = make_event(TeamEventKind::kRoster, team.id, member.id);
    roster.members = ids_of(team);
    roster.audience = {member.id};
    out.push_back(std::move(roster));
}

void TeamBook::destroy_team(TeamId id) {
    const auto found = teams_.find(id);
    if (found == teams_.end()) return;
    for (const TeamMember& member : found->second.members) {
        member_team_.erase(member.id);
        offline_until_.erase(member.id);
    }
    teams_.erase(found);
}

void TeamBook::drop_followers(Team& team, TeamEvents& out) {
    for (const CharacterId follower : team.followers) {
        TeamEvent stopped = make_event(TeamEventKind::kFollowStopped, team.id, follower);
        stopped.audience = ids_of(team);
        out.push_back(std::move(stopped));
    }
    team.followers.clear();
}

bool TeamBook::promote_online(Team& team, TeamEvents& out) {
    if (team.members.empty() || team.members.front().online) return false;
    const auto online = std::ranges::find_if(team.members, [](const TeamMember& member) { return member.online; });
    if (online == team.members.end()) return false;
    const CharacterId old_leader = team.members.front().id;
    drop_followers(team, out);
    // Xoay người trực tuyến đầu tiên lên đầu, giữ nguyên thứ tự những người còn lại (Team::Appoint 2008).
    std::rotate(team.members.begin(), online, std::next(online));
    TeamEvent changed = make_event(TeamEventKind::kLeaderChanged, team.id, old_leader);
    changed.other = team.members.front().id;
    changed.audience = ids_of(team);
    out.push_back(std::move(changed));
    return true;
}

void TeamBook::remove_member(Team& team, CharacterId member, TeamEventKind kind, TeamEvents& out) {
    const std::vector<CharacterId> before = ids_of(team);
    const bool was_leader = team.members.front().id == member;
    std::erase_if(team.members, [member](const TeamMember& entry) { return entry.id == member; });
    std::erase(team.followers, member);
    member_team_.erase(member);
    offline_until_.erase(member);
    TeamEvent event = make_event(kind, team.id, member);
    event.audience = before;
    if (team.members.empty()) {
        // Hết người thì đội giải tán; người cuối cùng vừa rời nhận kDismissed thay vì kMemberLeft.
        TeamEvent dismissed = make_event(TeamEventKind::kDismissed, team.id, member);
        dismissed.audience = before;
        const TeamId id = team.id;
        out.push_back(std::move(dismissed));
        destroy_team(id);
        return;
    }
    if (was_leader) {
        // Đội trưởng mới là người đứng đầu danh sách còn lại, nếu họ rớt mạng thì nhường tiếp.
        event.other = team.members.front().id;
        out.push_back(std::move(event));
        drop_followers(team, out);
        static_cast<void>(promote_online(team, out));
        return;
    }
    out.push_back(std::move(event));
}

TeamResult TeamBook::invite(Tick now, const PlayerDirectory& directory, CharacterId actor, CharacterId target) {
    expire(now);
    const auto self = directory.find(actor);
    if (!self || !self->online) return rejected(TeamError::kUnknownPlayer);
    const auto dest = directory.find(target);
    if (!dest || !dest->online) return rejected(TeamError::kTargetNotOnline);
    if (directory.hostile(*self, *dest)) return rejected(TeamError::kHostile);
    if (actor != target && dest->has(setting::kRefuseTeamInvite)) return rejected(TeamError::kRefuseInviteSetting);
    if (member_team_.contains(target)) return rejected(TeamError::kInviteDestHasTeam);
    TeamEvents out;
    if (actor == target) {
        if (teams_.size() >= static_cast<std::size_t>(limits_.team_max_teams)) return rejected(TeamError::kTooManyTeams);
        static_cast<void>(create_team(*self, out));
        return accepted(std::move(out));
    }
    Team* team = mutable_team_of(actor);
    if (team != nullptr) {
        if (team->members.size() >= static_cast<std::size_t>(limits_.team_max_members)) {
            return rejected(TeamError::kInviteTeamFull);
        }
        const CharacterId leader = team->members.front().id;
        if (leader != actor) {
            // Người mời không phải đội trưởng: hỏi đội trưởng trước (GWTeamLeaderAskInvite).
            const auto leader_card = directory.find(leader);
            if (!leader_card || !leader_card->online) return rejected(TeamError::kApplyLeaderCannotAnswer);
            const PendingKey key{.kind = PendingKind::kLeaderApproval, .first = leader.value(), .second = actor.value(), .third = target.value()};
            if (const auto failure = add_pending(now, key, actor, leader, team->id)) return rejected(*failure);
            TeamEvent ask = make_event(TeamEventKind::kLeaderAskInvite, team->id, actor);
            ask.other = target;
            ask.audience = {leader};
            out.push_back(std::move(ask));
            return accepted(std::move(out));
        }
    }
    const PendingKey key{.kind = PendingKind::kInvite, .first = target.value(), .second = actor.value(), .third = 0};
    if (const auto failure = add_pending(now, key, actor, target, team != nullptr ? team->id : TeamId{})) {
        return rejected(*failure);
    }
    TeamEvent ask = make_event(TeamEventKind::kInviteAsk, team != nullptr ? team->id : TeamId{}, actor);
    ask.members = team != nullptr ? ids_of(*team) : std::vector<CharacterId>{actor};
    ask.audience = {target};
    out.push_back(std::move(ask));
    return accepted(std::move(out));
}

TeamResult TeamBook::answer_invite(
    Tick now, const PlayerDirectory& directory, CharacterId invitee, CharacterId inviter, bool accept) {
    expire(now);
    const PendingKey key{.kind = PendingKind::kInvite, .first = invitee.value(), .second = inviter.value(), .third = 0};
    if (find_pending(key) == nullptr) return rejected(TeamError::kNoPending);
    remove_pending(key);
    TeamEvents out;
    if (!accept) {
        notice(out, inviter, TeamError::kInviteRefuse, invitee);
        return accepted(std::move(out));
    }
    const auto self = directory.find(invitee);
    if (!self || !self->online) return rejected(TeamError::kUnknownPlayer);
    const auto host = directory.find(inviter);
    if (!host || !host->online) return rejected(TeamError::kTargetNotOnline);
    if (directory.hostile(*self, *host)) return rejected(TeamError::kHostile);
    if (member_team_.contains(invitee)) {
        notice(out, inviter, TeamError::kInviteDestHasTeam, invitee);
        return rejected(TeamError::kInviteDestHasTeam, std::move(out));
    }
    Team* team = mutable_team_of(inviter);
    if (team == nullptr) {
        if (teams_.size() >= static_cast<std::size_t>(limits_.team_max_teams)) return rejected(TeamError::kTooManyTeams);
        const TeamId created = create_team(*host, out);
        join_team(*mutable_find(created), *self, out);
        return accepted(std::move(out));
    }
    if (team->members.size() >= static_cast<std::size_t>(limits_.team_max_members)) {
        notice(out, inviter, TeamError::kInviteTeamFull, invitee);
        return rejected(TeamError::kApplyTeamFull, std::move(out));
    }
    join_team(*team, *self, out);
    return accepted(std::move(out));
}

TeamResult TeamBook::leader_answer_invite(Tick now, const PlayerDirectory& directory, CharacterId leader,
    CharacterId inviter, CharacterId invitee, bool accept) {
    expire(now);
    const PendingKey key{.kind = PendingKind::kLeaderApproval, .first = leader.value(), .second = inviter.value(), .third = invitee.value()};
    if (find_pending(key) == nullptr) return rejected(TeamError::kNoPending);
    remove_pending(key);
    Team* team = mutable_team_of(leader);
    if (team == nullptr || team->members.front().id != leader) return rejected(TeamError::kNotLeader);
    TeamEvents out;
    if (!has_id(ids_of(*team), inviter)) {
        return rejected(TeamError::kInviterNotInTeam);
    }
    if (!accept) {
        notice(out, inviter, TeamError::kInviteLeaderRefuse, leader);
        return accepted(std::move(out));
    }
    const auto dest = directory.find(invitee);
    if (!dest || !dest->online) {
        notice(out, inviter, TeamError::kTargetNotOnline, invitee);
        return rejected(TeamError::kTargetNotOnline, std::move(out));
    }
    if (member_team_.contains(invitee)) {
        notice(out, inviter, TeamError::kInviteDestHasTeam, invitee);
        return rejected(TeamError::kInviteDestHasTeam, std::move(out));
    }
    if (team->members.size() >= static_cast<std::size_t>(limits_.team_max_members)) {
        notice(out, inviter, TeamError::kInviteTeamFull, leader);
        return rejected(TeamError::kInviteTeamFull, std::move(out));
    }
    // Đội trưởng đồng ý: lời mời đi tiếp tới người được mời, mang tên đội trưởng (sGUID = lGuid).
    const PendingKey invite_key{.kind = PendingKind::kInvite, .first = invitee.value(), .second = leader.value(), .third = 0};
    if (const auto failure = add_pending(now, invite_key, leader, invitee, team->id)) return rejected(*failure);
    TeamEvent ask = make_event(TeamEventKind::kInviteAsk, team->id, leader);
    ask.members = ids_of(*team);
    ask.audience = {invitee};
    out.push_back(std::move(ask));
    return accepted(std::move(out));
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai vai khác nhau (người xin, người được xin) cùng kiểu ID mạnh
TeamResult TeamBook::apply(Tick now, const PlayerDirectory& directory, CharacterId applicant, CharacterId target) {
    expire(now);
    const auto self = directory.find(applicant);
    if (!self || !self->online) return rejected(TeamError::kUnknownPlayer);
    if (member_team_.contains(applicant)) return rejected(TeamError::kApplyWhenInTeam);
    const auto dest = directory.find(target);
    if (!dest || !dest->online) return rejected(TeamError::kTargetNotOnline);
    if (directory.hostile(*self, *dest)) return rejected(TeamError::kHostile);
    Team* team = mutable_team_of(target);
    if (team == nullptr) return rejected(TeamError::kApplyDestHasNoTeam);
    if (team->members.size() >= static_cast<std::size_t>(limits_.team_max_members)) {
        return rejected(TeamError::kApplyTeamFull);
    }
    const CharacterId leader = team->members.front().id;
    const auto leader_card = directory.find(leader);
    if (!leader_card || !leader_card->online || leader_card->status != PlayerStatus::kNormal) {
        return rejected(TeamError::kApplyLeaderCannotAnswer);
    }
    const PendingKey key{.kind = PendingKind::kApply, .first = applicant.value(), .second = team->id.value(), .third = 0};
    if (const auto failure = add_pending(now, key, applicant, leader, team->id)) return rejected(*failure);
    TeamEvents out;
    TeamEvent ask = make_event(TeamEventKind::kApplyAsk, team->id, applicant);
    ask.audience = {leader};
    out.push_back(std::move(ask));
    return accepted(std::move(out));
}

TeamResult TeamBook::answer_apply(
    Tick now, const PlayerDirectory& directory, CharacterId leader, CharacterId applicant, bool accept) {
    expire(now);
    Team* team = mutable_team_of(leader);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    const PendingKey key{.kind = PendingKind::kApply, .first = applicant.value(), .second = team->id.value(), .third = 0};
    const Pending* pending = find_pending(key);
    if (pending == nullptr) return rejected(TeamError::kNoPending);
    // Người trả lời phải là đội trưởng HIỆN TẠI của đội đã nhận đơn (đội trưởng có thể đã đổi).
    if (team->members.front().id != leader || pending->holder != leader) return rejected(TeamError::kApplyLeaderChanged);
    remove_pending(key);
    TeamEvents out;
    if (!accept) {
        notice(out, applicant, TeamError::kApplyLeaderRefuse, leader);
        return accepted(std::move(out));
    }
    const auto self = directory.find(applicant);
    if (!self || !self->online) return rejected(TeamError::kTargetNotOnline);
    if (member_team_.contains(applicant)) {
        notice(out, leader, TeamError::kApplySourHasTeam, applicant);
        return rejected(TeamError::kApplySourHasTeam, std::move(out));
    }
    if (team->members.size() >= static_cast<std::size_t>(limits_.team_max_members)) {
        notice(out, applicant, TeamError::kApplyTeamFull, leader);
        return rejected(TeamError::kApplyTeamFull, std::move(out));
    }
    join_team(*team, *self, out);
    return accepted(std::move(out));
}

TeamResult TeamBook::leave(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    TeamEvents out;
    remove_member(*team, actor, TeamEventKind::kMemberLeft, out);
    return accepted(std::move(out));
}

TeamResult TeamBook::dismiss(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (team->members.front().id != actor) return rejected(TeamError::kDismissNotLeader);
    TeamEvents out;
    TeamEvent event = make_event(TeamEventKind::kDismissed, team->id, actor);
    event.audience = ids_of(*team);
    out.push_back(std::move(event));
    destroy_team(team->id);
    return accepted(std::move(out));
}

TeamResult TeamBook::kick(CharacterId leader, CharacterId target) {
    Team* team = mutable_team_of(leader);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (team->members.front().id != leader) return rejected(TeamError::kKickNotLeader);
    if (leader == target) return rejected(TeamError::kBadValue);
    if (!has_id(ids_of(*team), target)) return rejected(TeamError::kNotInTeam);
    TeamEvents out;
    remove_member(*team, target, TeamEventKind::kKicked, out);
    return accepted(std::move(out));
}

TeamResult TeamBook::appoint(CharacterId leader, CharacterId new_leader) {
    Team* team = mutable_team_of(leader);
    if (team == nullptr) return rejected(TeamError::kAppointSourNoTeam);
    const auto link = member_team_.find(new_leader);
    if (link == member_team_.end()) return rejected(TeamError::kAppointDestNoTeam);
    if (link->second != team->id) return rejected(TeamError::kAppointNotSameTeam);
    if (team->members.front().id != leader) return rejected(TeamError::kAppointSourNotLeader);
    if (leader == new_leader) return rejected(TeamError::kBadValue);
    const auto next = std::ranges::find_if(team->members, [new_leader](const TeamMember& m) { return m.id == new_leader; });
    if (!next->online) return rejected(TeamError::kTargetNotOnline);
    std::rotate(team->members.begin(), next, std::next(next));
    TeamEvents out;
    drop_followers(*team, out);
    TeamEvent event = make_event(TeamEventKind::kLeaderChanged, team->id, leader);
    event.other = new_leader;
    event.audience = ids_of(*team);
    out.push_back(std::move(event));
    return accepted(std::move(out));
}

TeamResult TeamBook::set_exp_mode(CharacterId actor, ExpMode mode) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (team->members.front().id != actor) return rejected(TeamError::kNotLeader);
    if (mode != ExpMode::kAverage && mode != ExpMode::kTamer) return rejected(TeamError::kBadValue);
    if (team->exp_mode == mode) return accepted({});
    team->exp_mode = mode;
    TeamEvent event = make_event(TeamEventKind::kExpModeChanged, team->id, actor);
    event.value = static_cast<std::uint8_t>(mode);
    event.audience = ids_of(*team);
    return accepted({std::move(event)});
}

TeamResult TeamBook::set_loot_mode(CharacterId actor, LootMode mode) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (team->members.front().id != actor) return rejected(TeamError::kNotLeader);
    if (mode != LootMode::kFree && mode != LootMode::kRoundRobin && mode != LootMode::kLeader) {
        return rejected(TeamError::kBadValue);
    }
    if (team->loot_mode == mode) return accepted({});
    team->loot_mode = mode;
    team->loot_cursor = 0;
    TeamEvent event = make_event(TeamEventKind::kLootModeChanged, team->id, actor);
    event.value = static_cast<std::uint8_t>(mode);
    event.audience = ids_of(*team);
    return accepted({std::move(event)});
}

TeamResult TeamBook::report_vitals(CharacterId actor, const Vitals& vitals) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (vitals.hp > vitals.hp_max || vitals.mp > vitals.mp_max) return rejected(TeamError::kBadValue);
    const auto member = std::ranges::find_if(team->members, [actor](const TeamMember& m) { return m.id == actor; });
    if (member->vitals == vitals) return accepted({});
    member->vitals = vitals;
    TeamEvent event = make_event(TeamEventKind::kVitals, team->id, actor);
    event.vitals = vitals;
    event.audience = without(ids_of(*team), actor);
    return accepted({std::move(event)});
}

TeamResult TeamBook::set_scene(CharacterId actor, SceneId scene) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    const auto member = std::ranges::find_if(team->members, [actor](const TeamMember& m) { return m.id == actor; });
    if (member->scene == scene) return accepted({});
    member->scene = scene;
    TeamEvents out;
    TeamEvent event = make_event(TeamEventKind::kMemberScene, team->id, actor);
    event.scene = scene;
    event.audience = without(ids_of(*team), actor);
    out.push_back(std::move(event));
    // Người theo sang cảnh khác với đội trưởng thì tự thôi theo.
    const bool is_leader = team->members.front().id == actor;
    if (!is_leader && has_id(team->followers, actor) && team->members.front().scene != scene) {
        std::erase(team->followers, actor);
        TeamEvent stopped = make_event(TeamEventKind::kFollowStopped, team->id, actor);
        stopped.audience = ids_of(*team);
        out.push_back(std::move(stopped));
    }
    return accepted(std::move(out));
}

TeamResult TeamBook::start_follow(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    const TeamMember& leader = team->members.front();
    if (leader.id == actor || !leader.online) return rejected(TeamError::kNotFollowable);
    const auto member = std::ranges::find_if(team->members, [actor](const TeamMember& m) { return m.id == actor; });
    if (member->scene != leader.scene || !member->online) return rejected(TeamError::kNotFollowable);
    if (has_id(team->followers, actor)) return accepted({});
    team->followers.push_back(actor);
    TeamEvent event = make_event(TeamEventKind::kFollowStarted, team->id, actor);
    event.audience = ids_of(*team);
    return accepted({std::move(event)});
}

TeamResult TeamBook::stop_follow(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return rejected(TeamError::kNotInTeam);
    if (!has_id(team->followers, actor)) return accepted({});
    std::erase(team->followers, actor);
    TeamEvent event = make_event(TeamEventKind::kFollowStopped, team->id, actor);
    event.audience = ids_of(*team);
    return accepted({std::move(event)});
}

TeamEvents TeamBook::on_disconnect(Tick now, CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return {};
    TeamEvents out;
    if (offline_grace_.count <= 0) {
        remove_member(*team, actor, TeamEventKind::kMemberLeft, out);
        return out;
    }
    const auto member = std::ranges::find_if(team->members, [actor](const TeamMember& m) { return m.id == actor; });
    if (!member->online) return {};
    member->online = false;
    std::erase(team->followers, actor);
    offline_until_.insert_or_assign(actor, ids::advance(now, offline_grace_));
    TeamEvent event = make_event(TeamEventKind::kMemberOffline, team->id, actor);
    event.audience = without(ids_of(*team), actor);
    out.push_back(std::move(event));
    static_cast<void>(promote_online(*team, out));
    return out;
}

TeamEvents TeamBook::on_reconnect(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return {};
    const auto member = std::ranges::find_if(team->members, [actor](const TeamMember& m) { return m.id == actor; });
    if (member->online) return {};
    member->online = true;
    offline_until_.erase(actor);
    TeamEvent event = make_event(TeamEventKind::kMemberOnline, team->id, actor);
    event.audience = without(ids_of(*team), actor);
    TeamEvents out;
    out.push_back(std::move(event));
    return out;
}

TeamEvents TeamBook::on_logout(CharacterId actor) {
    Team* team = mutable_team_of(actor);
    if (team == nullptr) return {};
    TeamEvents out;
    remove_member(*team, actor, TeamEventKind::kMemberLeft, out);
    return out;
}

TeamEvents TeamBook::tick(Tick now) {
    expire(now);
    std::vector<CharacterId> due;
    for (const auto& [member, deadline] : offline_until_) {
        if (deadline <= now) due.push_back(member);
    }
    TeamEvents out;
    for (const CharacterId member : due) {
        Team* team = mutable_team_of(member);
        if (team != nullptr) remove_member(*team, member, TeamEventKind::kMemberLeft, out);
        offline_until_.erase(member);
    }
    return out;
}

std::optional<TeamId> TeamBook::team_of(CharacterId member) const {
    const auto link = member_team_.find(member);
    if (link == member_team_.end()) return std::nullopt;
    return link->second;
}

const Team* TeamBook::find(TeamId id) const {
    const auto found = teams_.find(id);
    return found == teams_.end() ? nullptr : &found->second;
}

std::optional<CharacterId> TeamBook::leader_of(TeamId id) const {
    const Team* team = find(id);
    if (team == nullptr || team->members.empty()) return std::nullopt;
    return team->members.front().id;
}

std::vector<CharacterId> TeamBook::applicants_of(TeamId id) const {
    std::vector<std::pair<std::uint64_t, CharacterId>> found;
    for (const auto& [key, pending] : pending_) {
        if (key.kind == PendingKind::kApply && pending.team == id) {
            found.emplace_back(pending.serial, pending.sender);
        }
    }
    std::ranges::sort(found);
    std::vector<CharacterId> ids;
    ids.reserve(found.size());
    for (const auto& entry : found) {
        ids.push_back(entry.second);
    }
    return ids;
}

std::vector<CharacterId> TeamBook::inviters_of(CharacterId target) const {
    std::vector<std::pair<std::uint64_t, CharacterId>> found;
    for (const auto& [key, pending] : pending_) {
        if (key.kind == PendingKind::kInvite && pending.holder == target) {
            found.emplace_back(pending.serial, pending.sender);
        }
    }
    std::ranges::sort(found);
    std::vector<CharacterId> ids;
    ids.reserve(found.size());
    for (const auto& entry : found) {
        ids.push_back(entry.second);
    }
    return ids;
}

std::vector<CharacterId> TeamBook::members_in_scene(TeamId id, SceneId scene) const {
    std::vector<CharacterId> ids;
    const Team* team = find(id);
    if (team == nullptr) return ids;
    for (const TeamMember& member : team->members) {
        if (member.scene == scene) ids.push_back(member.id);
    }
    return ids;
}

std::optional<CharacterId> TeamBook::next_looter(TeamId id, std::span<const CharacterId> eligible) {
    Team* team = mutable_find(id);
    if (team == nullptr || eligible.empty()) return std::nullopt;
    switch (team->loot_mode) {
    case LootMode::kFree: return std::nullopt;
    case LootMode::kLeader: {
        const CharacterId leader = team->members.front().id;
        if (std::ranges::find(eligible, leader) != eligible.end()) return leader;
        return std::nullopt;
    }
    case LootMode::kRoundRobin: {
        const std::size_t count = team->members.size();
        for (std::size_t step = 0; step < count; ++step) {
            const std::size_t slot = (team->loot_cursor + step) % count;
            const CharacterId candidate = team->members[slot].id;
            if (std::ranges::find(eligible, candidate) != eligible.end()) {
                team->loot_cursor = static_cast<std::uint32_t>((slot + 1U) % count);
                return candidate;
            }
        }
        return std::nullopt;
    }
    }
    return std::nullopt;
}

std::expected<void, std::string> TeamBook::validate() const {
    std::size_t counted = 0;
    for (const auto& [id, team] : teams_) {
        if (team.members.empty()) return std::unexpected(std::format("đội {} rỗng", id.value()));
        if (team.members.size() > static_cast<std::size_t>(limits_.team_max_members)) {
            return std::unexpected(std::format("đội {} vượt trần thành viên", id.value()));
        }
        if (team.id != id) return std::unexpected(std::format("đội {} lệch id", id.value()));
        for (const TeamMember& member : team.members) {
            const auto link = member_team_.find(member.id);
            if (link == member_team_.end() || link->second != id) {
                return std::unexpected(std::format("thành viên {} của đội {} không có liên kết ngược", member.id.value(), id.value()));
            }
            ++counted;
        }
        for (const CharacterId follower : team.followers) {
            const bool member = std::ranges::any_of(team.members, [follower](const TeamMember& m) { return m.id == follower; });
            if (!member || follower == team.members.front().id) {
                return std::unexpected(std::format("người theo {} của đội {} không hợp lệ", follower.value(), id.value()));
            }
        }
    }
    if (counted != member_team_.size()) return std::unexpected("có thành viên mồ côi hoặc ở hai đội");
    for (const auto& [member, deadline] : offline_until_) {
        static_cast<void>(deadline);
        if (!member_team_.contains(member)) return std::unexpected("hạn ngoại tuyến của người không còn ở đội");
    }
    for (const auto& [key, pending] : pending_) {
        static_cast<void>(key);
        if (!held_count_.contains(pending.holder) || !sent_count_.contains(pending.sender)) {
            return std::unexpected("lời chờ không có bộ đếm");
        }
    }
    return {};
}

} // namespace game::social
