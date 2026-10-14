#pragma once
// Bang hội: lập bang, xin vào, nhận/đuổi/rời, chức vị và quyền hạn, nhường chức, giải tán, tông chỉ,
// tên chức vị tuỳ chỉnh, ngân quỹ, điểm bang chiến và liên minh bang. Lõi thuần: world đưa Tick và
// PlayerDirectory, nhận lại danh sách sự kiện; tiền của người chơi do world trừ/cộng theo sự kiện.
//
// Nguồn: WorldServer 2008 (WorldData/Guild.cpp: OnGuildCreate, OnUserEnter, OnRecruitUser, OnUserLeave,
// OnDemise, CanAppointedBy; GameDefine_Guild.h: GUILD_POSITION_*, GUILD_AUTHORITY_*, GUILD_ERROR_*;
// GameStruct_Guild.h: GUILD_ADMIN_t hạn ngạch chức vị); mười quyền và tên chức vị tuỳ chỉnh theo
// NewBangHui_Hygl.lua của client 2026 (GetMyGuildPower trả chuỗi 10 ký tự); điều kiện lập bang (cấp 40,
// 50 vàng) theo OtherRef.txt; điểm bang chiến theo GuildWarPoint.txt; liên minh theo ConfigInfo.ini.
// Khác gốc: (1) 2008 kiểm quyền ASSIGN rồi vẫn tiếp tục bổ nhiệm và không so cấp người bổ nhiệm với chức
// mới: lõi chặn cả hai (người bổ nhiệm phải cao chức hơn cả người được bổ nhiệm lẫn chức mới); (2) ba
// tay cầm rỗng của 2008 (điều chỉnh quyền, rút tiền, nộp tiền) được làm đầy đủ; (3) quyền thứ 10 "sửa tông
// chỉ" là của client 2026; (4) đơn xin vào bang có hạn (guild.proposer_ttl_seconds) và mỗi người chỉ xin
// được một bang một lúc; (5) giải tán bị chặn khi quỹ còn tiền, còn thành phố hay còn liên minh, để tiền và
// tài sản không biến mất; (6) FoundDuration/ResponseUserCount của ConfigInfo.ini (giai đoạn "chuẩn bị lập
// bang" chờ người hưởng ứng) KHÔNG làm: bang lập xong là chính thức.
// Khi bổ nhiệm, quyền của người được bổ nhiệm về mặc định của chức mới (2008 giữ quyền cũ).
//
// Độ phức tạp: bang tối đa guild_hard_member_cap thành viên nên duyệt tuyến tính; tra bang theo người
// qua bảng chỉ mục O(log n).

#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {

// Chức vị: số khớp GUILD_POSITION_* của 2008 (client 2026 dùng chung).
enum class GuildPosition : std::uint8_t {
    kTrainee = 1,      // dự bị (đơn xin vào bang); lõi giữ riêng ở danh sách chờ, không là thành viên
    kMember = 2,
    kElite = 3,
    kCommerce = 4,
    kAgriculture = 5,
    kIndustry = 6,
    kPersonnel = 7,
    kAssistant = 8,
    kChief = 9,
};

inline constexpr std::size_t kGuildPositionCount = 9;

// Mười quyền (bit): chín bit đầu là GUILD_AUTHORITY_* của 2008, bit thứ mười của client 2026.
namespace power {
inline constexpr std::uint16_t kAssign = 0x1;
inline constexpr std::uint16_t kAuthorize = 0x2;
inline constexpr std::uint16_t kRecruit = 0x4;
inline constexpr std::uint16_t kExpel = 0x8;
inline constexpr std::uint16_t kDemise = 0x10;
inline constexpr std::uint16_t kWithdraw = 0x20;
inline constexpr std::uint16_t kDeposit = 0x40;
inline constexpr std::uint16_t kLeave = 0x80;
inline constexpr std::uint16_t kDismiss = 0x100;
inline constexpr std::uint16_t kChangeDesc = 0x200;
inline constexpr std::uint16_t kAll = 0x3FF;
// Quyền mặc định theo chức (GUILD_AUTHORITY_MEMBER, ASSCHIEFTAIN, CHIEFTAIN của 2008 + bit mười).
inline constexpr std::uint16_t kMemberDefault = kDeposit | kLeave;
inline constexpr std::uint16_t kAssistantDefault = kAssign | kRecruit | kExpel | kLeave;
inline constexpr std::uint16_t kChiefDefault = 0x17F | kChangeDesc;
// Bốn quyền gắn với chức, không trao/thu bằng điều chỉnh quyền.
inline constexpr std::uint16_t kReserved = kAuthorize | kDemise | kLeave | kDismiss;
} // namespace power

[[nodiscard]] std::uint16_t default_power(GuildPosition position) noexcept;
// Chuỗi 10 ký tự '0'/'1' mà GetMyGuildPower của client 2026 đọc: ký tự thứ i ứng bit i-1.
[[nodiscard]] std::string power_string(std::uint16_t mask);

enum class GuildError : std::uint8_t {
    kInvalidName = 1,      // GUILD_ERROR_INVALID_NAME
    kDuplicateName,        // GUILD_ERROR_DUPLICATED_NAME
    kGuildFull,            // GUILD_ERROR_GUILD_FULL: đủ số bang
    kMemberFull,           // GUILD_ERROR_MEMBER_FULL
    kProposerFull,         // GUILD_ERROR_PROPOSER_FULL
    kInGuild,              // GUILD_ERROR_IN_GUILD
    kNotExist,             // GUILD_ERROR_NOT_EXIST
    kUnauthorized,         // GUILD_ERROR_UNAUTHORIZED
    kNoVacancy,            // GUILD_ERROR_NO_VACANCY
    kNoQualification,      // GUILD_ERROR_NO_QUALIFICATION
    kCashboxFull,          // GUILD_ERROR_CASHBOX_FULL
    kAlreadyMember,        // GUILD_ERROR_ALREADY_MEMBER
    kMemberNotExist,       // GUILD_ERROR_MEMBER_NOT_EXIST
    kNoAssistant,          // GUILD_ERROR_NO_ASS_CHIEF
    kPosFull,              // GUILD_ERROR_POS_FULL
    kAlreadyProposer,      // GUILD_ERROR_ALREADY_IN_PROPOSER_LIST
    kInvalidCamp,          // GUILD_ERROR_INVALID_CAMP
    // Từ đây là lỗi lõi tự thêm.
    kUnknownPlayer,
    kLevelTooLow,
    kNotEnoughMoney,
    kBadText,
    kBadPosition,
    kSelf,
    kChiefCannotLeave,
    kRankTooLow,
    kBadValue,
    kNotInGuild,
    kNotChief,
    kCashboxNotEmpty,
    kHasCity,
    kInLeague,
    kNotInLeague,
    kLeagueFull,
    kRejoinCooldown,
    kAtWar,
    kNotAtWar,
    kTooFewMembers,
    kNoPending,
};

// Mã gửi client: số âm của GUILD_ERROR_*, 0 khi lõi tự thêm (client hiện thông báo chung).
[[nodiscard]] std::int8_t client_code(GuildError error) noexcept;
[[nodiscard]] std::string_view describe(GuildError error) noexcept;

struct GuildMember {
    CharacterId id{};
    std::string name;
    GuildPosition position = GuildPosition::kMember;
    std::uint16_t access = power::kMemberDefault;
    std::uint16_t level = 0;
    std::uint8_t sect = 0;
    std::int64_t contribution = 0;
};

struct GuildProposer {
    CharacterId id{};
    std::string name;
    std::uint16_t level = 0;
    std::uint8_t sect = 0;
    Tick expires{};
};

struct Guild {
    GuildId id{};
    std::string name;
    std::string description;
    CharacterId founder{};
    std::uint8_t camp = 0;
    std::uint8_t level = 0;  // cấp nha môn 0..5; 0 = chưa có thành phố
    CityId city{};           // 0 = chưa có thành phố
    Copper funds = 0;
    std::int64_t war_points = 0;
    std::array<std::string, kGuildPositionCount> position_names{};  // chỉ số = chức - 1; rỗng = tên mặc định
    std::vector<GuildMember> members;
    std::vector<GuildProposer> proposers;
};

struct League {
    LeagueId id{};
    std::string name;
    GuildId leader{};
    std::vector<GuildId> members;  // gồm cả bang đứng đầu, bang đứng đầu ở đầu danh sách
};

enum class GuildEventKind : std::uint8_t {
    kCreated,           // subject = người lập; value = phí; guild
    kApplied,           // audience = người có quyền nhận; subject = người xin
    kApplyRejected,     // audience = {người xin}; subject = người xin
    kRecruited,         // audience = mọi thành viên gồm người mới; subject = người mới
    kExpelled,          // audience = mọi thành viên trước khi đuổi; subject = người bị đuổi; other = người đuổi
    kLeft,              // audience = mọi thành viên trước khi rời; subject
    kAppointed,         // audience = mọi thành viên; subject = người được bổ nhiệm; other = người bổ nhiệm; value = chức mới; old_value = chức cũ
    kPowerChanged,      // audience = {người bị đổi, người đổi}; subject; value = mặt nạ quyền mới
    kDemised,           // audience = mọi thành viên; subject = chủ mới; other = chủ cũ
    kDismissed,         // audience = mọi thành viên trước khi giải tán
    kDescriptionChanged,
    kPositionRenamed,   // value = chức; text = tên mới
    kDeposited,         // value = số tiền; subject = người nộp
    kWithdrawn,         // value = số tiền; subject = người rút
    kWarStarted,        // guild, other_guild
    kWarPoints,         // guild; value = điểm mới của bang
    kWarEnded,          // guild, other_guild; value = bang thắng (0 = hoà)
    kLeagueCreated,     // league; guild
    kLeagueInvite,      // audience = người có quyền của bang được mời; league; guild = bang mời; other_guild = bang được mời
    kLeagueJoined,      // league; guild = bang vào
    kLeagueLeft,        // league; guild = bang rời
    kLeagueKicked,      // league; guild = bang bị đuổi
    kLeagueDisbanded,   // league
    kNotice,            // audience = {người nhận}; error
};

struct GuildEvent {
    GuildEventKind kind = GuildEventKind::kNotice;
    GuildId guild{};
    GuildId other_guild{};
    LeagueId league{};
    CharacterId subject{};
    CharacterId other{};
    GuildError error = GuildError::kBadValue;
    std::int64_t value = 0;
    std::int64_t old_value = 0;
    std::string text;
    std::vector<CharacterId> audience;
};

using GuildEvents = std::vector<GuildEvent>;
using GuildResult = Outcome<GuildEvent, GuildError>;

// Bảng điểm bang chiến (guild_war_points.tsv): mã sự kiện sang số điểm.
class WarPointTable {
public:
    [[nodiscard]] static std::expected<WarPointTable, std::string> parse(std::string_view tsv);
    // Điểm của một lần xảy ra sự kiện; 0 nếu mã lạ.
    [[nodiscard]] std::int64_t points_for(std::uint32_t event_id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return points_.size(); }

private:
    std::vector<std::pair<std::uint32_t, std::int64_t>> points_;  // xếp tăng theo mã sự kiện
};

class GuildBook {
public:
    // `policy` phải sống lâu hơn GuildBook.
    GuildBook(const Limits& limits, const GuildRules& rules, const TextPolicy& policy);

    // `wallet` = số tiền người chơi đang có: lõi chỉ kiểm đủ, world trừ khi kết quả thành công
    // (xử lý đơn luồng nên không có khe hở giữa kiểm và trừ).
    [[nodiscard]] GuildResult create(Tick now, const PlayerDirectory& directory, CharacterId actor, std::string_view name,
        std::string_view description, Copper wallet);
    [[nodiscard]] GuildResult apply(Tick now, const PlayerDirectory& directory, CharacterId actor, GuildId target);
    [[nodiscard]] GuildResult cancel_application(CharacterId actor);
    [[nodiscard]] GuildResult answer_application(
        Tick now, const PlayerDirectory& directory, CharacterId actor, CharacterId applicant, bool accept);

    [[nodiscard]] GuildResult expel(CharacterId actor, CharacterId target);
    [[nodiscard]] GuildResult leave(CharacterId actor);
    [[nodiscard]] GuildResult appoint(CharacterId actor, CharacterId target, GuildPosition position);
    // Bật/tắt một quyền của `target` (đảo bit, như OnUserAuthorityChange của 2008).
    [[nodiscard]] GuildResult toggle_power(CharacterId actor, CharacterId target, std::uint16_t bit);
    // Nhường chức bang chủ cho bang phó (2008: OnDemise); bang chủ cũ xuống làm bang phó.
    [[nodiscard]] GuildResult demise(CharacterId actor);
    [[nodiscard]] GuildResult dismiss(CharacterId actor);
    [[nodiscard]] GuildResult set_description(CharacterId actor, std::string_view text);
    [[nodiscard]] GuildResult rename_position(CharacterId actor, GuildPosition position, std::string_view text);
    // Nộp/rút quỹ. Nộp kiểm `wallet`; quỹ không quá trần của cấp nha môn.
    [[nodiscard]] GuildResult deposit(CharacterId actor, Copper amount, Copper wallet);
    [[nodiscard]] GuildResult withdraw(CharacterId actor, Copper amount);
    // Cập nhật cấp/phái của thành viên khi world biết (lên cấp, đổi phái).
    void refresh_member(const PlayerCard& card);

    // Bang chiến: hai bang cùng đủ guild_war_min_members người, kéo dài battle_minutes.
    [[nodiscard]] GuildResult declare_war(Tick now, CharacterId actor, GuildId enemy);
    [[nodiscard]] GuildResult add_war_points(Tick now, GuildId guild, std::uint32_t event_id, std::int64_t times, const WarPointTable& table);

    // Liên minh bang.
    [[nodiscard]] GuildResult league_create(Tick now, CharacterId actor, std::string_view name, Copper wallet);
    [[nodiscard]] GuildResult league_invite(Tick now, CharacterId actor, GuildId target);
    [[nodiscard]] GuildResult league_answer(Tick now, CharacterId actor, GuildId inviter, bool accept);
    [[nodiscard]] GuildResult league_leave(Tick now, CharacterId actor);
    [[nodiscard]] GuildResult league_kick(CharacterId actor, GuildId target);
    [[nodiscard]] GuildResult league_disband(CharacterId actor);

    // Nha môn/thành phố: world đặt sau khi CityBook đổi chủ; quyết định trần thành viên và quỹ.
    [[nodiscard]] std::expected<void, GuildError> set_county(GuildId id, std::uint8_t level, CityId city);

    // Hết hạn đơn xin vào, lời mời liên minh, trận bang chiến.
    [[nodiscard]] GuildEvents tick(Tick now);

    // Truy vấn. Con trỏ chỉ sống tới thao tác ghi kế tiếp.
    [[nodiscard]] std::optional<GuildId> guild_of(CharacterId member) const;
    [[nodiscard]] std::optional<GuildId> proposer_guild_of(CharacterId applicant) const;
    [[nodiscard]] const Guild* find(GuildId id) const;
    [[nodiscard]] const Guild* find_by_name(std::string_view name) const;
    [[nodiscard]] const GuildMember* member(CharacterId id) const;
    [[nodiscard]] std::int64_t member_cap(const Guild& guild) const noexcept;
    [[nodiscard]] Copper funds_cap(const Guild& guild) const noexcept;
    [[nodiscard]] std::size_t guild_count() const noexcept { return guilds_.size(); }
    [[nodiscard]] const League* league_of(GuildId guild) const;
    [[nodiscard]] const League* find_league(LeagueId id) const;
    [[nodiscard]] std::size_t league_count() const noexcept { return leagues_.size(); }
    [[nodiscard]] bool at_war(GuildId guild) const;
    // Tên chức hiện hành: tên tuỳ chỉnh nếu có, rỗng nếu dùng tên mặc định của client.
    [[nodiscard]] static std::string_view custom_position_name(const Guild& guild, GuildPosition position) noexcept;

    // Số id kế tiếp sẽ cấp; world lưu cùng dữ liệu để id không tái sử dụng sau khi khởi động lại.
    [[nodiscard]] GuildId next_guild_id() const noexcept { return GuildId{next_guild_}; }
    [[nodiscard]] LeagueId next_league_id() const noexcept { return LeagueId{next_league_}; }
    void set_next_ids(GuildId guild, LeagueId league);

    // Nạp một bang/liên minh đọc từ kho (đã qua decode, nhưng vẫn kiểm chéo: trùng tên, thành viên ở bang
    // khác). Lỗi: giữ nguyên.
    [[nodiscard]] std::expected<void, std::string> load_guild(Guild guild, Tick now);
    [[nodiscard]] std::expected<void, std::string> load_league(League league);

    // Bất biến: chủ đúng một, phó không quá một, hạn ngạch chức, thành viên không ở hai bang, chỉ mục khớp,
    // quỹ trong trần, liên minh trỏ vào bang có thật.
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    struct Invite {
        Tick expires{};
    };
    struct War {
        GuildId a{};
        GuildId b{};
        Tick ends{};
        std::int64_t points_a = 0;
        std::int64_t points_b = 0;
    };

    [[nodiscard]] Guild* mutable_guild(GuildId id);
    [[nodiscard]] GuildMember* mutable_member(CharacterId id, Guild** guild_out);
    [[nodiscard]] std::vector<CharacterId> everyone(const Guild& guild) const;
    [[nodiscard]] std::vector<CharacterId> with_power(const Guild& guild, std::uint16_t bit) const;
    [[nodiscard]] bool name_ok(std::string_view name, std::size_t max_bytes, std::size_t min_codepoints) const;
    [[nodiscard]] std::int64_t position_count(const Guild& guild, GuildPosition position) const;
    void add_member(Guild& guild, const PlayerCard& card, GuildPosition position);
    void erase_member(Guild& guild, CharacterId id);
    void drop_proposals_of(CharacterId id);
    void remove_guild(GuildId id, GuildEvents& out);

    Limits limits_;
    GuildRules rules_;
    const TextPolicy* policy_;
    TickSpan proposer_ttl_{};
    TickSpan invite_ttl_{};
    TickSpan war_length_{};
    TickSpan rejoin_wait_{};
    std::uint64_t next_guild_ = 1;
    std::uint32_t next_league_ = 1;
    std::map<GuildId, Guild> guilds_;
    std::map<CharacterId, GuildId> member_index_;
    std::map<CharacterId, GuildId> proposer_index_;
    std::map<std::string, GuildId> name_index_;
    std::map<LeagueId, League> leagues_;
    std::map<GuildId, LeagueId> league_index_;
    std::map<std::string, LeagueId> league_names_;
    std::map<std::pair<LeagueId, GuildId>, Invite> invites_;
    std::map<GuildId, Tick> rejoin_until_;
    std::vector<War> wars_;
};

// Mã hoá/giải mã một bang (blob::kGuild, phiên bản 1) và một liên minh (blob::kLeague). Hạn đơn xin vào
// lưu là số tick còn lại so với `now`. Giải mã kiểm miền, UTF-8, trùng id, hạn ngạch chức, trần.
[[nodiscard]] CodecResult encode_guild(const Guild& guild, Tick now, Bytes& out);
[[nodiscard]] std::expected<Guild, CodecError> decode_guild(std::span<const std::byte> bytes, Tick now, const Limits& limits);
[[nodiscard]] CodecResult encode_league(const League& league, Bytes& out);
[[nodiscard]] std::expected<League, CodecError> decode_league(std::span<const std::byte> bytes, const Limits& limits);

} // namespace game::social
