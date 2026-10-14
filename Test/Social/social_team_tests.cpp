// Máy trạng thái đội: sai thì đội mồ côi, hai đội chung một người, lời "trả lời mời" giả lọt qua. Mỗi ca
// dựng bằng bảng người chơi giả; sau mỗi chuỗi thao tác gọi validate().
#include "ids/ids.hpp"
#include "social/directory.hpp"
#include "social/team.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace game::test {
namespace {

using social::ExpMode;
using social::LootMode;
using social::TeamBook;
using social::TeamError;
using social::TeamEvent;
using social::TeamEventKind;
using social::TeamEvents;
using social::TeamResult;
using social::Team;
using social::TeamId;
using social::Tick;
using social::Vitals;

constexpr Tick kT0{100};

[[nodiscard]] TeamId team_id(const TeamBook& book, std::uint64_t who) {
    return book.team_of(cid(who)).value_or(TeamId{});
}

[[nodiscard]] std::size_t member_count(const TeamBook& book, TeamId id) {
    const Team* team = book.find(id);
    return team == nullptr ? 0U : team->members.size();
}

[[nodiscard]] std::size_t count_kind(const TeamEvents& events, TeamEventKind kind) {
    return static_cast<std::size_t>(
        std::ranges::count_if(events, [kind](const TeamEvent& event) { return event.kind == kind; }));
}

[[nodiscard]] const TeamEvent* first_kind(const TeamEvents& events, TeamEventKind kind) {
    const auto found = std::ranges::find_if(events, [kind](const TeamEvent& event) { return event.kind == kind; });
    return found == events.end() ? nullptr : &*found;
}

[[nodiscard]] std::optional<TeamError> notice_error(const TeamEvents& events) {
    const TeamEvent* event = first_kind(events, TeamEventKind::kNotice);
    if (event == nullptr) return std::nullopt;
    return event->error;
}

[[nodiscard]] std::size_t audience_count(const TeamEvents& events, TeamEventKind kind) {
    const TeamEvent* event = first_kind(events, kind);
    return event == nullptr ? 0U : event->audience.size();
}

[[nodiscard]] social::CharacterId other_of(const TeamEvents& events, TeamEventKind kind) {
    const TeamEvent* event = first_kind(events, kind);
    return event == nullptr ? social::CharacterId{} : event->other;
}

void expect_valid(Context& context, const TeamBook& book) {
    const auto checked = book.validate();
    context.expect(checked.has_value(), "validate() đạt");
}

void fill_directory(FakeDirectory& directory, std::uint64_t count) {
    for (std::uint64_t id = 1; id <= count; ++id) {
        directory.add(id, "p" + std::to_string(id));
    }
}

// Dựng đội {1,2,...,size} do 1 làm đội trưởng bằng chuỗi mời - đồng ý thật.
void build_team(TeamBook& book, const FakeDirectory& directory, std::uint64_t size) {
    for (std::uint64_t id = 2; id <= size; ++id) {
        const TeamResult invite = book.invite(kT0, directory, cid(1), cid(id));
        const TeamResult answer = book.answer_invite(kT0, directory, cid(id), cid(1), true);
        static_cast<void>(invite);
        static_cast<void>(answer);
    }
}

void invite_creates_team_on_accept(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    const TeamResult asked = book.invite(kT0, directory, cid(1), cid(2));
    context.expect(asked.ok(), "mời được");
    context.expect(count_kind(asked.events, TeamEventKind::kInviteAsk) == 1, "một hộp thoại mời");
    context.expect(!book.team_of(cid(1)).has_value(), "chưa đồng ý thì chưa có đội");
    const TeamResult joined = book.answer_invite(kT0, directory, cid(2), cid(1), true);
    context.expect(joined.ok(), "đồng ý được");
    context.expect(count_kind(joined.events, TeamEventKind::kCreated) == 1, "lập đội");
    context.expect(count_kind(joined.events, TeamEventKind::kMemberJoined) == 1, "người mới vào");
    context.expect(book.team_of(cid(1)) == book.team_of(cid(2)) && book.team_of(cid(1)).has_value(), "cùng đội");
    const TeamId team = team_id(book, 1);
    context.expect(book.leader_of(team) == cid(1), "người mời là đội trưởng");
    context.expect(member_count(book, team) == 2, "hai người");
    expect_valid(context, book);
}

void forged_answer_is_rejected(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    // Client giả mạo "trả lời mời" cho người chưa từng mời: 2008 cho lọt, lõi từ chối.
    const TeamResult forged = book.answer_invite(kT0, directory, cid(2), cid(1), true);
    context.expect(forged.error == TeamError::kNoPending, "không có lời mời thì không vào được");
    context.expect(!book.team_of(cid(2)).has_value(), "không thành đội");
    const TeamResult forged_apply = book.answer_apply(kT0, directory, cid(1), cid(2), true);
    context.expect(forged_apply.error.has_value(), "trả lời đơn xin không có thật bị từ chối");
    expect_valid(context, book);
}

void invite_expires(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    static_cast<void>(book.invite(kT0, directory, cid(1), cid(2)));
    context.expect(book.pending_count() == 1, "một lời chờ");
    const Tick late = ids::advance(kT0, ids::TickSpan{60LL * 20});
    static_cast<void>(book.tick(late));
    context.expect(book.pending_count() == 0, "hết hạn thì xoá");
    const TeamResult stale = book.answer_invite(late, directory, cid(2), cid(1), true);
    context.expect(stale.error == TeamError::kNoPending, "trả lời lời mời đã hết hạn");
    expect_valid(context, book);
}

void invite_rejections(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 4);
    directory.at(2).settings = social::setting::kRefuseTeamInvite;
    directory.at(3).camp = 1;
    directory.at(1).camp = 2;
    directory.at(4).online = false;
    TeamBook book(sample_limits());
    context.expect(book.invite(kT0, directory, cid(1), cid(2)).error == TeamError::kRefuseInviteSetting, "từ chối cài đặt");
    context.expect(book.invite(kT0, directory, cid(1), cid(3)).error == TeamError::kHostile, "thù địch");
    context.expect(book.invite(kT0, directory, cid(1), cid(4)).error == TeamError::kTargetNotOnline, "ngoại tuyến");
    context.expect(book.invite(kT0, directory, cid(1), cid(99)).error == TeamError::kTargetNotOnline, "id lạ");
    context.expect(book.invite(kT0, directory, cid(98), cid(1)).error == TeamError::kUnknownPlayer, "người mời lạ");
    context.expect(book.pending_count() == 0, "từ chối thì không lưu lời mời");
}

void decline_notifies_inviter(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    static_cast<void>(book.invite(kT0, directory, cid(1), cid(2)));
    const TeamResult declined = book.answer_invite(kT0, directory, cid(2), cid(1), false);
    context.expect(declined.ok(), "từ chối là kết quả hợp lệ");
    const TeamEvent* notice = first_kind(declined.events, TeamEventKind::kNotice);
    context.expect(notice != nullptr && notice->error == TeamError::kInviteRefuse, "người mời nhận thông báo từ chối");
    context.expect(notice != nullptr && notice->audience.size() == 1 && notice->audience[0] == cid(1), "gửi đúng người mời");
    context.expect(book.team_count() == 0, "không lập đội");
}

void solo_team_by_self_invite(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 2);
    TeamBook book(sample_limits());
    const TeamResult solo = book.invite(kT0, directory, cid(1), cid(1));
    context.expect(solo.ok() && count_kind(solo.events, TeamEventKind::kCreated) == 1, "tự lập đội");
    context.expect(book.invite(kT0, directory, cid(1), cid(1)).error == TeamError::kInviteDestHasTeam, "đã có đội thì không lập lại");
    // Từ đội một người, mời tiếp: người mời là đội trưởng nên đi thẳng.
    const TeamResult asked = book.invite(kT0, directory, cid(1), cid(2));
    context.expect(asked.ok() && count_kind(asked.events, TeamEventKind::kInviteAsk) == 1, "đội trưởng mời thẳng");
    context.expect(book.answer_invite(kT0, directory, cid(2), cid(1), true).ok(), "vào đội đã có");
    context.expect(member_count(book, team_id(book, 1)) == 2, "hai người");
    expect_valid(context, book);
}

void non_leader_invite_goes_through_leader(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 4);
    TeamBook book(sample_limits());
    build_team(book, directory, 2);
    const TeamResult asked = book.invite(kT0, directory, cid(2), cid(3));
    context.expect(asked.ok() && count_kind(asked.events, TeamEventKind::kLeaderAskInvite) == 1, "hỏi đội trưởng trước");
    context.expect(count_kind(asked.events, TeamEventKind::kInviteAsk) == 0, "chưa tới người được mời");
    context.expect(book.answer_invite(kT0, directory, cid(3), cid(2), true).error == TeamError::kNoPending,
        "người được mời chưa thể trả lời");
    // Chỉ đội trưởng đúng mới trả lời được.
    context.expect(!book.leader_answer_invite(kT0, directory, cid(2), cid(2), cid(3), true).ok(), "không phải đội trưởng");
    const TeamResult refused = book.leader_answer_invite(kT0, directory, cid(1), cid(2), cid(3), false);
    context.expect(refused.ok() && notice_error(refused.events) == TeamError::kInviteLeaderRefuse,
        "đội trưởng từ chối");
    static_cast<void>(book.invite(kT0, directory, cid(2), cid(3)));
    const TeamResult approved = book.leader_answer_invite(kT0, directory, cid(1), cid(2), cid(3), true);
    context.expect(approved.ok() && count_kind(approved.events, TeamEventKind::kInviteAsk) == 1, "đội trưởng đồng ý");
    const TeamEvent* ask = first_kind(approved.events, TeamEventKind::kInviteAsk);
    context.expect(ask != nullptr && ask->subject == cid(1) && ask->audience[0] == cid(3), "lời mời mang tên đội trưởng");
    context.expect(book.answer_invite(kT0, directory, cid(3), cid(1), true).ok(), "người được mời vào");
    context.expect(member_count(book, team_id(book, 1)) == 3, "ba người");
    expect_valid(context, book);
}

void full_team_rejects(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 8);
    TeamBook book(sample_limits());
    build_team(book, directory, 6);
    context.expect(member_count(book, team_id(book, 1)) == 6, "đủ sáu");
    context.expect(book.invite(kT0, directory, cid(1), cid(7)).error == TeamError::kInviteTeamFull, "mời vào đội đầy");
    const TeamResult applied = book.apply(kT0, directory, cid(7), cid(3));
    context.expect(applied.error == TeamError::kApplyTeamFull, "xin vào đội đầy");
    // Lời mời đã gửi lúc còn chỗ, tới lúc trả lời đội đã đầy.
    TeamBook second(sample_limits());
    build_team(second, directory, 5);
    static_cast<void>(second.invite(kT0, directory, cid(1), cid(6)));
    static_cast<void>(second.invite(kT0, directory, cid(1), cid(7)));
    context.expect(second.answer_invite(kT0, directory, cid(6), cid(1), true).ok(), "người thứ sáu vào");
    const TeamResult late = second.answer_invite(kT0, directory, cid(7), cid(1), true);
    context.expect(late.error == TeamError::kApplyTeamFull, "người thứ bảy bị chặn");
    const TeamEvent* told = first_kind(late.events, TeamEventKind::kNotice);
    context.expect(told != nullptr && told->error == TeamError::kInviteTeamFull && told->audience[0] == cid(1),
        "người mời nhận thông báo đầy");
    context.expect(!second.team_of(cid(7)).has_value(), "người thứ bảy không vào");
    expect_valid(context, book);
    expect_valid(context, second);
}

void apply_flow(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 4);
    TeamBook book(sample_limits());
    build_team(book, directory, 2);
    context.expect(book.apply(kT0, directory, cid(3), cid(4)).error == TeamError::kApplyDestHasNoTeam, "người kia không có đội");
    context.expect(book.apply(kT0, directory, cid(2), cid(1)).error == TeamError::kApplyWhenInTeam, "đang trong đội");
    const TeamResult applied = book.apply(kT0, directory, cid(3), cid(2));
    context.expect(applied.ok(), "xin được");
    const TeamEvent* ask = first_kind(applied.events, TeamEventKind::kApplyAsk);
    context.expect(ask != nullptr && ask->audience[0] == cid(1), "hộp thoại tới đội trưởng chứ không phải người được xin");
    context.expect(book.applicants_of(team_id(book, 1)) == std::vector<social::CharacterId>{cid(3)}, "danh sách xin vào");
    context.expect(book.answer_apply(kT0, directory, cid(2), cid(3), true).error == TeamError::kApplyLeaderChanged,
        "chỉ đội trưởng trả lời");
    const TeamResult accepted = book.answer_apply(kT0, directory, cid(1), cid(3), true);
    context.expect(accepted.ok() && book.team_of(cid(3)) == book.team_of(cid(1)), "được nhận");
    TeamBook other(sample_limits());
    build_team(other, directory, 2);
    static_cast<void>(other.apply(kT0, directory, cid(3), cid(2)));
    const TeamResult refused = other.answer_apply(kT0, directory, cid(1), cid(3), false);
    context.expect(refused.ok() && notice_error(refused.events) == TeamError::kApplyLeaderRefuse,
        "bị từ chối");
    context.expect(!other.team_of(cid(3)).has_value(), "không vào");
    expect_valid(context, book);
    expect_valid(context, other);
}

void apply_after_leader_changed(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 4);
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    static_cast<void>(book.apply(kT0, directory, cid(4), cid(2)));
    context.expect(book.appoint(cid(1), cid(2)).ok(), "đổi đội trưởng");
    // Đơn đang chờ nằm ở đội trưởng cũ: người trả lời phải là đội trưởng hiện tại và là bên nhận đơn.
    context.expect(book.answer_apply(kT0, directory, cid(2), cid(4), true).error == TeamError::kApplyLeaderChanged,
        "đội trưởng mới không phải bên nhận đơn");
    context.expect(book.answer_apply(kT0, directory, cid(1), cid(4), true).error == TeamError::kApplyLeaderChanged,
        "đội trưởng cũ không còn quyền");
    expect_valid(context, book);
}

void leave_dismiss_kick_appoint(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 5);
    TeamBook book(sample_limits());
    build_team(book, directory, 4);
    const TeamId team = team_id(book, 1);
    // Thành viên thường rời.
    const TeamResult left = book.leave(cid(3));
    context.expect(left.ok() && count_kind(left.events, TeamEventKind::kMemberLeft) == 1, "rời đội");
    context.expect(audience_count(left.events, TeamEventKind::kMemberLeft) == 4, "thông báo cả người rời");
    context.expect(!book.team_of(cid(3)).has_value(), "không còn ở đội");
    context.expect(book.leave(cid(3)).error == TeamError::kNotInTeam, "rời hai lần");
    // Chỉ đội trưởng đuổi và giải tán.
    context.expect(book.kick(cid(2), cid(4)).error == TeamError::kKickNotLeader, "không phải đội trưởng đuổi");
    context.expect(book.dismiss(cid(2)).error == TeamError::kDismissNotLeader, "không phải đội trưởng giải tán");
    context.expect(book.kick(cid(1), cid(1)).error == TeamError::kBadValue, "tự đuổi mình");
    context.expect(book.kick(cid(1), cid(5)).error == TeamError::kNotInTeam, "đuổi người ngoài đội");
    const TeamResult kicked = book.kick(cid(1), cid(4));
    context.expect(kicked.ok() && count_kind(kicked.events, TeamEventKind::kKicked) == 1, "đuổi được");
    context.expect(!book.team_of(cid(4)).has_value(), "bị đuổi khỏi đội");
    // Đội trưởng rời: người kế tiếp lên.
    const TeamResult leader_left = book.leave(cid(1));
    const TeamEvent* event = first_kind(leader_left.events, TeamEventKind::kMemberLeft);
    context.expect(event != nullptr && event->other == cid(2), "người kế tiếp làm đội trưởng");
    context.expect(book.leader_of(team) == cid(2), "đội trưởng mới");
    context.expect(member_count(book, team) == 1, "đội còn một người vẫn tồn tại (như 2008)");
    // Người cuối rời thì đội mất.
    const TeamResult last = book.leave(cid(2));
    context.expect(count_kind(last.events, TeamEventKind::kDismissed) == 1, "người cuối rời: đội giải tán");
    context.expect(book.team_count() == 0 && book.find(team) == nullptr, "không còn đội");
    expect_valid(context, book);
    // Giải tán bởi đội trưởng.
    build_team(book, directory, 3);
    const TeamId again = team_id(book, 1);
    const TeamResult dismissed = book.dismiss(cid(1));
    context.expect(dismissed.ok() && audience_count(dismissed.events, TeamEventKind::kDismissed) == 3,
        "giải tán báo cả ba");
    context.expect(book.find(again) == nullptr && !book.team_of(cid(2)).has_value(), "mọi người ra khỏi đội");
    expect_valid(context, book);
}

void appoint_rules(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 5);
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    context.expect(book.appoint(cid(5), cid(2)).error == TeamError::kAppointSourNoTeam, "người giao không có đội");
    context.expect(book.appoint(cid(1), cid(5)).error == TeamError::kAppointDestNoTeam, "người nhận không có đội");
    context.expect(book.appoint(cid(2), cid(3)).error == TeamError::kAppointSourNotLeader, "người giao không phải đội trưởng");
    context.expect(book.appoint(cid(1), cid(1)).error == TeamError::kBadValue, "giao cho chính mình");
    const TeamResult done = book.appoint(cid(1), cid(3));
    context.expect(done.ok() && other_of(done.events, TeamEventKind::kLeaderChanged) == cid(3), "giao quyền");
    const TeamId team = team_id(book, 1);
    context.expect(book.leader_of(team) == cid(3), "đội trưởng mới");
    context.expect(book.find(team)->members[1].id == cid(1) && book.find(team)->members[2].id == cid(2),
        "giữ thứ tự những người còn lại");
    expect_valid(context, book);
}

void appoint_across_teams(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 6);
    TeamBook book(sample_limits());
    build_team(book, directory, 2);
    // Dựng đội thứ hai do người 3 làm đội trưởng.
    static_cast<void>(book.invite(kT0, directory, cid(3), cid(4)));
    static_cast<void>(book.answer_invite(kT0, directory, cid(4), cid(3), true));
    context.expect(book.team_count() == 2, "hai đội");
    context.expect(book.appoint(cid(1), cid(4)).error == TeamError::kAppointNotSameTeam, "khác đội");
    expect_valid(context, book);
}

void modes_and_loot(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 4);
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    const TeamId team = team_id(book, 1);
    context.expect(book.set_exp_mode(cid(2), ExpMode::kTamer).error == TeamError::kNotLeader, "không phải đội trưởng");
    const TeamResult changed = book.set_exp_mode(cid(1), ExpMode::kTamer);
    context.expect(changed.ok() && changed.events.size() == 1 && changed.events[0].audience.size() == 3, "đổi chế độ chia kinh nghiệm");
    context.expect(book.set_exp_mode(cid(1), ExpMode::kTamer).events.empty(), "giữ nguyên thì không phát");
    context.expect(book.set_exp_mode(cid(1), static_cast<ExpMode>(7)).error == TeamError::kBadValue, "giá trị lạ");
    context.expect(book.set_loot_mode(cid(1), LootMode::kRoundRobin).ok(), "xoay vòng");
    const std::array<social::CharacterId, 3> all{cid(3), cid(1), cid(2)};
    std::vector<std::uint64_t> order;
    order.reserve(6);
    for (int i = 0; i < 6; ++i) {
        order.push_back(book.next_looter(team, all).value_or(social::CharacterId{}).value());
    }
    context.expect((order == std::vector<std::uint64_t>{1, 2, 3, 1, 2, 3}), "xoay vòng theo thứ tự đội");
    const std::array<social::CharacterId, 1> only{cid(3)};
    context.expect(book.next_looter(team, only) == cid(3), "bỏ qua người không đủ điều kiện");
    context.expect(!book.next_looter(team, {}).has_value(), "không ai đủ điều kiện");
    static_cast<void>(book.set_loot_mode(cid(1), LootMode::kLeader));
    context.expect(book.next_looter(team, all) == cid(1), "đội trưởng nhặt");
    context.expect(!book.next_looter(team, only).has_value(), "đội trưởng không đủ điều kiện");
    static_cast<void>(book.set_loot_mode(cid(1), LootMode::kFree));
    context.expect(!book.next_looter(team, all).has_value(), "nhặt tự do không chỉ định ai");
}

void vitals_and_scene(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    directory.at(2).scene = social::SceneId{5};
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    const TeamId team = team_id(book, 1);
    const Vitals hurt{.hp = 50, .hp_max = 100, .mp = 10, .mp_max = 20, .dead = false};
    const TeamResult first = book.report_vitals(cid(2), hurt);
    context.expect(first.ok() && first.events.size() == 1 && first.events[0].audience.size() == 2, "máu tới hai người còn lại");
    context.expect(book.report_vitals(cid(2), hurt).events.empty(), "không đổi thì không phát");
    context.expect(book.report_vitals(cid(2), Vitals{.hp = 5, .hp_max = 1}).error == TeamError::kBadValue, "hp vượt hp_max");
    context.expect(book.report_vitals(cid(9), hurt).error == TeamError::kNotInTeam, "người lạ");
    context.expect(book.members_in_scene(team, social::SceneId{5}) == std::vector<social::CharacterId>{cid(2)}, "một người ở cảnh 5");
    const TeamResult moved = book.set_scene(cid(3), social::SceneId{5});
    context.expect(moved.ok() && count_kind(moved.events, TeamEventKind::kMemberScene) == 1, "đổi cảnh");
    context.expect(book.members_in_scene(team, social::SceneId{5}).size() == 2, "hai người ở cảnh 5");
    expect_valid(context, book);
}

void follow_rules(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    context.expect(book.start_follow(cid(1)).error == TeamError::kNotFollowable, "đội trưởng không theo ai");
    context.expect(book.start_follow(cid(2)).ok(), "theo đội trưởng");
    context.expect(book.start_follow(cid(2)).events.empty(), "theo lần hai không đổi gì");
    // Người theo sang cảnh khác thì thôi theo.
    const TeamResult moved = book.set_scene(cid(2), social::SceneId{9});
    context.expect(count_kind(moved.events, TeamEventKind::kFollowStopped) == 1, "tự thôi theo khi khác cảnh");
    context.expect(book.start_follow(cid(2)).error == TeamError::kNotFollowable, "khác cảnh không theo được");
    static_cast<void>(book.set_scene(cid(2), social::SceneId{0}));
    static_cast<void>(book.start_follow(cid(2)));
    static_cast<void>(book.start_follow(cid(3)));
    const TeamResult handed = book.appoint(cid(1), cid(2));
    context.expect(count_kind(handed.events, TeamEventKind::kFollowStopped) == 2, "đổi đội trưởng: mọi người thôi theo");
    context.expect(book.find(team_id(book, 1))->followers.empty(), "danh sách theo rỗng");
    expect_valid(context, book);
}

void offline_grace(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 3);
    TeamBook book(sample_limits());
    build_team(book, directory, 3);
    const TeamId team = team_id(book, 1);
    const TeamEvents dropped = book.on_disconnect(kT0, cid(1));
    context.expect(count_kind(dropped, TeamEventKind::kMemberOffline) == 1, "báo ngoại tuyến");
    context.expect(count_kind(dropped, TeamEventKind::kLeaderChanged) == 1, "đội trưởng rớt mạng nhường chỗ");
    context.expect(book.leader_of(team) == cid(2), "người trực tuyến kế tiếp lên");
    context.expect(book.team_of(cid(1)) == team, "vẫn giữ chỗ");
    const TeamEvents back = book.on_reconnect(cid(1));
    context.expect(count_kind(back, TeamEventKind::kMemberOnline) == 1, "vào lại");
    context.expect(book.leader_of(team) == cid(2), "không đòi lại quyền đội trưởng");
    // Rớt mạng quá hạn thì rời đội.
    static_cast<void>(book.on_disconnect(kT0, cid(3)));
    context.expect(book.tick(ids::advance(kT0, ids::TickSpan{299LL * 20})).empty(), "chưa hết hạn giữ chỗ");
    const TeamEvents timed_out = book.tick(ids::advance(kT0, ids::TickSpan{300LL * 20}));
    context.expect(count_kind(timed_out, TeamEventKind::kMemberLeft) == 1, "hết hạn thì rời đội");
    context.expect(!book.team_of(cid(3)).has_value(), "không còn trong đội");
    // Thoát hẳn thì rời ngay.
    context.expect(count_kind(book.on_logout(cid(2)), TeamEventKind::kMemberLeft) == 1, "thoát hẳn rời ngay");
    context.expect(book.on_logout(cid(9)).empty(), "người ngoài đội thoát chẳng gây gì");
    expect_valid(context, book);
}

void everyone_offline_keeps_team_until_timeout(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 2);
    TeamBook book(sample_limits());
    build_team(book, directory, 2);
    static_cast<void>(book.on_disconnect(kT0, cid(1)));
    static_cast<void>(book.on_disconnect(kT0, cid(2)));
    context.expect(book.team_count() == 1, "cả đội rớt mạng vẫn còn đội");
    expect_valid(context, book);
    static_cast<void>(book.tick(ids::advance(kT0, ids::TickSpan{300LL * 20})));
    context.expect(book.team_count() == 0, "hết hạn thì đội mất");
    expect_valid(context, book);
}

void pending_caps(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 40);
    TeamBook book(sample_limits());
    // Một người nhận tối đa 8 lời mời cùng lúc.
    for (std::uint64_t sender = 1; sender <= 8; ++sender) {
        context.expect(book.invite(kT0, directory, cid(sender), cid(40)).ok(), "lời mời trong trần");
    }
    context.expect(book.invite(kT0, directory, cid(9), cid(40)).error == TeamError::kTooManyPending, "vượt trần theo người nhận");
    context.expect(book.inviters_of(cid(40)).size() == 8, "danh sách lời mời");
    // Một người gửi tối đa 16 lời cùng lúc.
    for (std::uint64_t target = 11; target < 27; ++target) {
        context.expect(book.invite(kT0, directory, cid(10), cid(target)).ok(), "gửi trong trần");
    }
    context.expect(book.invite(kT0, directory, cid(10), cid(27)).error == TeamError::kTooManyPending, "vượt trần theo người gửi");
    // Mời lại cùng người không cộng dồn.
    TeamBook again(sample_limits());
    for (int i = 0; i < 50; ++i) {
        context.expect(again.invite(kT0, directory, cid(1), cid(2)).ok(), "mời lại");
    }
    context.expect(again.pending_count() == 1, "mời lại thay bản cũ");
    expect_valid(context, book);
}

void expiry_queue_stays_bounded(Context& context) {
    FakeDirectory directory;
    fill_directory(directory, 2);
    TeamBook book(sample_limits());
    // Mời rồi trả lời liên tục để lại mục chết trong hàng hết hạn; hàng phải được dọn.
    for (int i = 0; i < 5000; ++i) {
        static_cast<void>(book.invite(kT0, directory, cid(1), cid(2)));
        static_cast<void>(book.answer_invite(kT0, directory, cid(2), cid(1), false));
    }
    context.expect(book.pending_count() == 0, "không còn lời chờ");
    expect_valid(context, book);
}

constexpr std::array kCases{
    Case{.name = "invite_creates_team_on_accept", .body = invite_creates_team_on_accept},
    Case{.name = "forged_answer_is_rejected", .body = forged_answer_is_rejected},
    Case{.name = "invite_expires", .body = invite_expires},
    Case{.name = "invite_rejections", .body = invite_rejections},
    Case{.name = "decline_notifies_inviter", .body = decline_notifies_inviter},
    Case{.name = "solo_team_by_self_invite", .body = solo_team_by_self_invite},
    Case{.name = "non_leader_invite_goes_through_leader", .body = non_leader_invite_goes_through_leader},
    Case{.name = "full_team_rejects", .body = full_team_rejects},
    Case{.name = "apply_flow", .body = apply_flow},
    Case{.name = "apply_after_leader_changed", .body = apply_after_leader_changed},
    Case{.name = "leave_dismiss_kick_appoint", .body = leave_dismiss_kick_appoint},
    Case{.name = "appoint_rules", .body = appoint_rules},
    Case{.name = "appoint_across_teams", .body = appoint_across_teams},
    Case{.name = "modes_and_loot", .body = modes_and_loot},
    Case{.name = "vitals_and_scene", .body = vitals_and_scene},
    Case{.name = "follow_rules", .body = follow_rules},
    Case{.name = "offline_grace", .body = offline_grace},
    Case{.name = "everyone_offline_keeps_team_until_timeout", .body = everyone_offline_keeps_team_until_timeout},
    Case{.name = "pending_caps", .body = pending_caps},
    Case{.name = "expiry_queue_stays_bounded", .body = expiry_queue_stays_bounded},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
