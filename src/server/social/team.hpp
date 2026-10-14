#pragma once
// Tổ đội: lập, mời, xin vào, rời, giải tán, đuổi, đổi đội trưởng, chia kinh nghiệm/đồ, máu cho khung
// đội, đội gắn với cảnh, thành viên ngoại tuyến còn giữ chỗ một lúc. Lõi thuần: bên gọi (world) đưa
// Tick và PlayerDirectory, nhận lại danh sách sự kiện để phát tới client.
//
// Nguồn: WorldServer 2008 (WorldData/Team.cpp, Packets/GWTeam*Handler.cpp, OnlineUser::UserLeaveTeam
// và AppointTeamLeader), mã lỗi TEAM_ERROR_* và TEAM_RESULT_* của GameDefine2.h; khung đội, chế độ
// chia kinh nghiệm (Team_Exp_Mode), danh sách xin vào/được mời và biểu tượng ngoại tuyến theo
// TeamFrame.lua của client 2026.
// Khác gốc: (1) lời mời/xin vào được GHI NHỚ và có hạn (2008 chỉ chuyển tiếp gói, nên client giả mạo
// "trả lời mời" cho người chưa từng mời vẫn lọt); (2) thành viên rớt mạng giữ chỗ team_offline_grace
// (2008 cho rời ngay); (3) đội còn 1 người vẫn tồn tại, chỉ giải tán khi hết người, y như 2008.
// Số thành viên tối đa 6 (MAX_TEAM_MEMBER), đội trưởng luôn đứng đầu danh sách.

#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include <cstddef>
#include <cstdint>
#include <deque>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

// Mã lỗi gắn với TEAM_ERROR_* của 2008 (client hiểu số 0..20); lỗi lõi tự thêm có mã 255 (client hiện
// thông báo chung).
enum class TeamError : std::uint8_t {
    kInviteDestHasTeam = 0,
    kInviteRefuse,
    kInviteTeamFull,
    kInviteLeaderRefuse,
    kDismissNotLeader,
    kKickNotLeader,
    kApplySourHasTeam,
    kApplyDestHasNoTeam,
    kApplyLeaderRefuse,
    kApplyTeamFull,
    kApplyLeaderChanged,
    kAppointSourNoTeam,
    kAppointDestNoTeam,
    kAppointNotSameTeam,
    kAppointSourNotLeader,
    kApplyLeaderCannotAnswer,
    kInviterNotInTeam,
    kApplyWhenInTeam,
    kTeamFull,
    kRefuseInviteSetting,
    kTargetNotOnline,
    // Từ đây là lỗi lõi tự thêm.
    kUnknownPlayer,
    kNotInTeam,
    kNotLeader,
    kNoPending,
    kTooManyPending,
    kHostile,
    kTooManyTeams,
    kNotFollowable,
    kBadValue,
};

// Mã số gửi client (TEAM_ERROR_*). 255 khi client không có mã riêng.
[[nodiscard]] std::uint8_t client_code(TeamError error) noexcept;
[[nodiscard]] std::string_view describe(TeamError error) noexcept;

enum class ExpMode : std::uint8_t {
    kAverage = 0,  // "平均分配"
    kTamer = 1,    // "驯兽模式"
};

// Chia đồ rơi trong đội. 2008 và client 2026 không có luật chung (kịch bản quái quyết định), nên đây
// là cơ chế tối thiểu của lõi: tự do, xoay vòng theo thứ tự đội, đội trưởng nhặt. Ghi made_up ở
// docs/SERVER-SOCIAL.md.
enum class LootMode : std::uint8_t {
    kFree = 0,
    kRoundRobin = 1,
    kLeader = 2,
};

struct Vitals {
    std::uint32_t hp = 0;
    std::uint32_t hp_max = 0;
    std::uint32_t mp = 0;
    std::uint32_t mp_max = 0;
    bool dead = false;

    friend bool operator==(const Vitals&, const Vitals&) noexcept = default;
};

struct TeamMember {
    CharacterId id{};
    SceneId scene{};
    Vitals vitals{};
    bool online = true;
};

struct Team {
    TeamId id{};
    std::vector<TeamMember> members;  // đội trưởng đứng đầu (LEADER_ID = 0)
    ExpMode exp_mode = ExpMode::kAverage;
    LootMode loot_mode = LootMode::kFree;
    std::uint32_t loot_cursor = 0;
    std::vector<CharacterId> followers;  // đang theo đội trưởng (tối đa số thành viên - 1)
};

enum class TeamEventKind : std::uint8_t {
    kCreated,          // subject = đội trưởng
    kMemberJoined,     // subject = người mới; audience = mọi thành viên gồm người mới
    kRoster,           // audience = {người mới}; members = danh sách đầy đủ, đội trưởng đứng đầu
    kMemberLeft,       // subject rời; other = đội trưởng mới (0 nếu không đổi); audience gồm cả người rời
    kLeaderChanged,    // subject = đội trưởng cũ, other = đội trưởng mới
    kKicked,           // subject bị đuổi; audience = mọi thành viên trước khi đuổi
    kDismissed,        // audience = mọi thành viên trước khi giải tán
    kInviteAsk,        // audience = {người được mời}; subject = người mời; members = đội của người mời
    kLeaderAskInvite,  // audience = {đội trưởng}; subject = người mời; other = người được mời
    kApplyAsk,         // audience = {đội trưởng}; subject = người xin vào
    kNotice,           // audience = {người nhận}; error; subject = người liên quan
    kExpModeChanged,   // value = ExpMode
    kLootModeChanged,  // value = LootMode
    kMemberOffline,    // subject
    kMemberOnline,     // subject
    kVitals,           // subject; vitals
    kMemberScene,      // subject; scene
    kFollowStarted,    // subject = người theo
    kFollowStopped,    // subject = người thôi theo
};

struct TeamEvent {
    TeamEventKind kind = TeamEventKind::kNotice;
    TeamId team{};
    CharacterId subject{};
    CharacterId other{};
    TeamError error = TeamError::kBadValue;
    std::uint8_t value = 0;
    SceneId scene{};
    Vitals vitals{};
    std::vector<CharacterId> members;
    std::vector<CharacterId> audience;
};

using TeamEvents = std::vector<TeamEvent>;
using TeamResult = Outcome<TeamEvent, TeamError>;

class TeamBook {
public:
    explicit TeamBook(const Limits& limits);

    // Mời `target` vào đội của `actor` (actor chưa có đội: lập đội khi target đồng ý). actor == target
    // là "tự lập đội". Người mời không phải đội trưởng thì lời mời đi qua đội trưởng trước.
    [[nodiscard]] TeamResult invite(Tick now, const PlayerDirectory& directory, CharacterId actor, CharacterId target);
    [[nodiscard]] TeamResult answer_invite(
        Tick now, const PlayerDirectory& directory, CharacterId invitee, CharacterId inviter, bool accept);
    [[nodiscard]] TeamResult leader_answer_invite(Tick now, const PlayerDirectory& directory, CharacterId leader,
        CharacterId inviter, CharacterId invitee, bool accept);

    // Xin vào đội của `target`; đội trưởng nhận hộp thoại.
    [[nodiscard]] TeamResult apply(Tick now, const PlayerDirectory& directory, CharacterId applicant, CharacterId target);
    [[nodiscard]] TeamResult answer_apply(
        Tick now, const PlayerDirectory& directory, CharacterId leader, CharacterId applicant, bool accept);

    [[nodiscard]] TeamResult leave(CharacterId actor);
    [[nodiscard]] TeamResult dismiss(CharacterId actor);
    [[nodiscard]] TeamResult kick(CharacterId leader, CharacterId target);
    [[nodiscard]] TeamResult appoint(CharacterId leader, CharacterId new_leader);

    [[nodiscard]] TeamResult set_exp_mode(CharacterId actor, ExpMode mode);
    [[nodiscard]] TeamResult set_loot_mode(CharacterId actor, LootMode mode);

    // Máu/khí cho khung đội. Chỉ phát sự kiện khi số đổi.
    [[nodiscard]] TeamResult report_vitals(CharacterId actor, const Vitals& vitals);
    // Thành viên sang cảnh khác (GWTeamMemberEnterScene).
    [[nodiscard]] TeamResult set_scene(CharacterId actor, SceneId scene);

    // Theo đội trưởng (zone đã kiểm khoảng cách; lõi kiểm cùng cảnh và vai).
    [[nodiscard]] TeamResult start_follow(CharacterId actor);
    [[nodiscard]] TeamResult stop_follow(CharacterId actor);

    // Rớt mạng: giữ chỗ, đội trưởng rớt thì nhường cho người trực tuyến kế tiếp.
    [[nodiscard]] TeamEvents on_disconnect(Tick now, CharacterId actor);
    // Vào lại trong hạn.
    [[nodiscard]] TeamEvents on_reconnect(CharacterId actor);
    // Thoát hẳn: rời đội ngay.
    [[nodiscard]] TeamEvents on_logout(CharacterId actor);
    // Hết hạn lời mời/xin vào và thành viên ngoại tuyến quá hạn giữ chỗ. Gọi mỗi tick hoặc thưa hơn.
    [[nodiscard]] TeamEvents tick(Tick now);

    // Truy vấn. Con trỏ trả về chỉ sống tới thao tác ghi kế tiếp.
    [[nodiscard]] std::optional<TeamId> team_of(CharacterId member) const;
    [[nodiscard]] const Team* find(TeamId id) const;
    [[nodiscard]] std::optional<CharacterId> leader_of(TeamId id) const;
    [[nodiscard]] std::size_t team_count() const noexcept { return teams_.size(); }
    [[nodiscard]] std::size_t pending_count() const noexcept { return pending_.size(); }
    // Người đang chờ đội trưởng của đội trả lời xin vào, theo thứ tự xin (duyệt O(số lời chờ)).
    [[nodiscard]] std::vector<CharacterId> applicants_of(TeamId id) const;
    // Đội đang mời `target` (cho danh sách lời mời trên client), theo thứ tự mời.
    [[nodiscard]] std::vector<CharacterId> inviters_of(CharacterId target) const;
    // Thành viên cùng cảnh `scene` (để chia kinh nghiệm quanh điểm). Thứ tự đội.
    [[nodiscard]] std::vector<CharacterId> members_in_scene(TeamId id, SceneId scene) const;
    // Người nhặt kế tiếp theo LootMode trong số `eligible` (thành viên đủ điều kiện, thứ tự bất kỳ).
    // kFree không chọn ai (nullopt); kLeader trả đội trưởng nếu đủ điều kiện; kRoundRobin xoay theo
    // thứ tự đội và nhớ con trỏ. nullopt khi không ai đủ điều kiện.
    [[nodiscard]] std::optional<CharacterId> next_looter(TeamId id, std::span<const CharacterId> eligible);

    // Kiểm bất biến (test mô phỏng gọi): không thành viên mồ côi, không đội rỗng, không ai ở hai đội,
    // đội trưởng đứng đầu, người theo ⊂ thành viên. Chuỗi lỗi tiếng Việt khi sai.
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    enum class PendingKind : std::uint8_t { kInvite = 0, kLeaderApproval, kApply };

    struct PendingKey {
        PendingKind kind = PendingKind::kInvite;
        std::uint64_t first = 0;
        std::uint64_t second = 0;
        std::uint64_t third = 0;
        friend auto operator<=>(const PendingKey&, const PendingKey&) noexcept = default;
    };

    struct Pending {
        CharacterId sender{};  // bên khởi xướng (đếm theo max_pending_per_sender)
        CharacterId holder{};  // bên phải trả lời (đếm theo max_pending_per_target)
        TeamId team{};
        Tick expires{};
        std::uint64_t serial = 0;
    };

    struct Expiry {
        Tick expires{};
        PendingKey key{};
        std::uint64_t serial = 0;
    };

    [[nodiscard]] Team* mutable_team_of(CharacterId member);
    [[nodiscard]] Team* mutable_find(TeamId id);
    [[nodiscard]] static std::vector<CharacterId> ids_of(const Team& team);
    [[nodiscard]] std::optional<TeamError> add_pending(
        Tick now, const PendingKey& key, CharacterId from, CharacterId to, TeamId team);
    [[nodiscard]] const Pending* find_pending(const PendingKey& key) const;
    void remove_pending(const PendingKey& key);
    void expire(Tick now);
    void compact_expiry();
    [[nodiscard]] TeamId create_team(const PlayerCard& leader, TeamEvents& out);
    void join_team(Team& team, const PlayerCard& member, TeamEvents& out);
    void remove_member(Team& team, CharacterId member, TeamEventKind kind, TeamEvents& out);
    void destroy_team(TeamId id);
    void notice(TeamEvents& out, CharacterId to, TeamError error, CharacterId subject) const;
    // Mọi người đang theo đội trưởng thôi theo (đổi đội trưởng): mỗi người một kFollowStopped.
    void drop_followers(Team& team, TeamEvents& out);
    // Nếu đội trưởng đang ngoại tuyến mà còn người trực tuyến thì nhường cho người trực tuyến đầu tiên
    // (giữ nguyên thứ tự những người còn lại) và thêm kLeaderChanged. Trả true khi có đổi.
    bool promote_online(Team& team, TeamEvents& out);

    Limits limits_;
    TickSpan pending_ttl_{};
    TickSpan offline_grace_{};
    std::map<TeamId, Team> teams_;
    std::map<CharacterId, TeamId> member_team_;
    std::map<PendingKey, Pending> pending_;
    std::deque<Expiry> expiry_;
    std::map<CharacterId, std::uint32_t> held_count_;
    std::map<CharacterId, std::uint32_t> sent_count_;
    std::map<CharacterId, Tick> offline_until_;
    std::uint64_t next_team_ = 1;
    std::uint64_t next_serial_ = 1;
};

} // namespace game::social
