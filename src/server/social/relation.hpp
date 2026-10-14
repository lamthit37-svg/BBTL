#pragma once
// Quan hệ giữa người chơi: bạn bè theo nhóm, danh sách đen, kẻ thù, bạn tạm, vợ chồng, sư đồ; độ
// thân thiết, tâm trạng, báo lên/xuống tuyến, mốc thưởng sư đồ. Lõi thuần: world đưa Tick và
// PlayerDirectory, nhận lại danh sách sự kiện.
//
// Nguồn: GameServer 2008 (Other/HumanRelation.cpp, GameDefine.h: MAX_FRIEND_POINT, MAX_MOOD_SIZE,
// MAX_PRENTICE_COUNT, MAX_MORAL_POINT, RELATION_TYPE_*, RET_ERR_*; CanTransition, IsGroupFull);
// nhóm bạn/danh sách đen/kẻ thù/bạn tạm và thanh trạng thái theo friend.lua của client 2026; bảng thưởng
// sư đồ theo MasterExpBounty.txt (dev/server/tables/server/mentor_exp_rewards.tsv).
// Khác gốc: (1) lời kết bạn/kết hôn/bái sư được GHI NHỚ và có hạn, nên "trả lời" giả mạo bị từ chối
// (2008 tin gói của client); (2) kết quả chỉ đổi dữ liệu khi cả hai sổ đang nạp (world nạp sổ của người
// trực tuyến), đổi/huỷ quan hệ với người ngoại tuyến phát sự kiện kOfflineChange để world ghi vào kho;
// (3) các ngưỡng cấp độ và độ thân thiết khi kết hôn/bái sư là made_up (2008 để kịch bản quyết định).
//
// Quy ước: kFriend, kSpouse, kMaster, kPrentice cùng nằm trong danh sách bạn (trần relation_max_friends);
// chuyển kiểu kFriend sang kSpouse/kMaster/kPrentice đổi tại chỗ, như ModifyFriendType của 2008.
// Độ phức tạp: mỗi sổ không quá relation_max_friends + danh sách phụ nên tìm tuyến tính, trần < 2000.

#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

enum class RelationKind : std::uint8_t {
    kFriend = 1,
    kBlack,
    kEnemy,
    kTemp,
    kSpouse,
    kMaster,    // người này là sư phụ của chủ sổ
    kPrentice,  // người này là đồ đệ của chủ sổ
};

// Số nhóm bạn của friend.lua (nhóm 1..4), lưu 0..3.
inline constexpr std::uint8_t kFriendGroups = 4;

enum class RelationError : std::uint8_t {
    kUnknownPlayer = 1,
    kSelf,
    kAlready,         // đã có quan hệ cùng loại
    kListFull,
    kGroupFull,
    kNotFound,
    kBadGroup,
    kBadText,
    kRefused,         // đối phương chặn (cài đặt, danh sách đen, thù địch): cố ý không nói rõ lý do
    kInBlacklist,
    kInEnemyList,
    kNoPending,
    kTooManyPending,
    kNotFriend,
    kPointTooLow,
    kSameSex,
    kAlreadyMarried,
    kHasMaster,
    kPrenticeFull,
    kLevelTooLow,
    kLevelTooHigh,
    kBetrayCooldown,
    kNotMaster,
    kNotPrentice,
    kNeedVerify,      // xoá bạn từ mức thân thiết password_intimacy cần mật khẩu cấp hai
    kBadKind,
    kNotLoaded,       // sổ của một bên chưa được world nạp
};

[[nodiscard]] std::string_view describe(RelationError error) noexcept;

struct RelationEntry {
    CharacterId id{};
    std::string name;
    RelationKind kind = RelationKind::kFriend;
    std::uint8_t group = 0;       // chỉ có nghĩa với kFriend: 0..3
    std::int32_t point = 0;       // độ thân thiết 0..relation_max_friend_point
    std::uint8_t milestones = 0;  // chỉ kMaster: bit i = đã nhận thưởng hàng i của bảng thưởng
};

struct RelationSheet {
    std::string mood;
    std::vector<RelationEntry> entries;
    std::int64_t moral_point = 0;  // điểm sư đức của chủ sổ khi làm sư phụ
    Tick betray_until{};           // chưa tới mốc này thì chưa được bái sư lại
};

enum class BondKind : std::uint8_t {
    kFriend = 1,
    kMarry,
    kRecruit,      // sư phụ mời nhận đồ đệ
    kApprentice,   // đồ đệ xin bái sư
};

enum class RelationEventKind : std::uint8_t {
    kBondAsk,        // audience = {người được hỏi}; subject = người hỏi; value = BondKind
    kBondRefused,    // audience = {người hỏi}; subject = người từ chối; value = BondKind
    kFriendAdded,    // audience = cả hai; subject, other; group
    kRemoved,        // audience = {người xoá}; subject = người bị xoá khỏi sổ
    kPeerRemoved,    // audience = {người kia}; subject = người đã xoá mình
    kOfflineChange,  // audience rỗng; subject = người ra lệnh; other = chủ sổ ngoại tuyến cần ghi vào kho; value = kiểu mới của mục (0 = xoá)
    kBlacklisted,    // audience = {chủ sổ}; subject = người bị đưa vào
    kEnemyAdded,     // audience = {chủ sổ}; subject
    kGroupMoved,     // audience = {chủ sổ}; subject; group
    kMoodChanged,    // audience = bạn trực tuyến; subject; text
    kPointChanged,   // audience = cả hai; subject, other; value = điểm mới
    kPresence,       // audience = bạn đủ thân; subject; value = 1 lên tuyến, 0 xuống tuyến
    kMarried,        // audience = cả hai
    kDivorced,       // audience = cả hai
    kRecruited,      // audience = cả hai; subject = sư phụ; other = đồ đệ
    kPrenticeLeft,   // audience = cả hai; subject = đồ đệ; other = sư phụ; value = 1 nếu phản sư
    kPrenticeExpelled, // audience = cả hai; subject = sư phụ; other = đồ đệ
    kMentorReward,   // audience = {sư phụ}; subject = sư phụ; other = đồ đệ; value = kinh nghiệm thưởng; level
    kNotice,         // audience = {người nhận}; error
};

struct RelationEvent {
    RelationEventKind kind = RelationEventKind::kNotice;
    CharacterId subject{};
    CharacterId other{};
    RelationError error = RelationError::kBadKind;
    std::int64_t value = 0;
    std::uint8_t group = 0;
    std::uint16_t level = 0;
    std::string text;
    std::vector<CharacterId> audience;
};

using RelationEvents = std::vector<RelationEvent>;
using RelationResult = Outcome<RelationEvent, RelationError>;

// Một hàng của bảng thưởng sư đồ (mentor_exp_rewards.tsv).
struct MentorReward {
    std::uint16_t apprentice_level = 0;
    std::int64_t exp_no_guild = 0;
    std::int64_t exp_guild = 0;
};

// Nội dung hai bảng (đã nạp vào bộ nhớ; lõi không đọc đĩa).
struct MentorSources {
    std::string_view rewards_tsv;  // mentor_exp_rewards.tsv
    std::string_view share_tsv;    // mentor_exp_share.tsv
};

// Bảng thưởng sư đồ và hệ số chia kinh nghiệm theo cấp (mentor_exp_share.tsv). Hàng thưởng xếp tăng
// theo cấp đồ đệ; tối đa 8 hàng vì mốc đã nhận lưu trong một byte.
class MentorTable {
public:
    [[nodiscard]] static std::expected<MentorTable, std::string> parse(const MentorSources& sources);

    [[nodiscard]] const std::vector<MentorReward>& rewards() const noexcept { return rewards_; }
    // Hệ số (0..1) kinh nghiệm đồ đệ chia cho sư phụ ở cấp `level`; cấp ngoài bảng là 0.
    [[nodiscard]] double share_at(std::uint16_t level) const noexcept;

private:
    std::vector<MentorReward> rewards_;
    std::vector<double> share_;  // chỉ số = cấp (hàng apprentice_rank của bảng gốc)
};

class RelationBook {
public:
    RelationBook(const Limits& limits, const RelationRules& rules);

    // Nạp/gỡ sổ của một nhân vật. Sổ lạ được kiểm bất biến trước khi nạp (lỗi: sổ bị từ chối, giữ nguyên).
    [[nodiscard]] std::expected<void, std::string> load(CharacterId owner, RelationSheet incoming);
    // Gỡ sổ và mọi lời chờ liên quan. Trả sổ để world ghi kho.
    [[nodiscard]] std::optional<RelationSheet> unload(CharacterId owner);
    [[nodiscard]] const RelationSheet* sheet(CharacterId owner) const;
    [[nodiscard]] std::size_t loaded_count() const noexcept { return sheets_.size(); }
    [[nodiscard]] std::size_t pending_count() const noexcept { return pending_.size(); }

    // Hỏi kết bạn/kết hôn/nhận đồ đệ/bái sư. Người được hỏi trả lời bằng answer.
    [[nodiscard]] RelationResult request(Tick now, const PlayerDirectory& directory, BondKind kind, CharacterId actor, CharacterId target);
    [[nodiscard]] RelationResult answer(Tick now, const PlayerDirectory& directory, BondKind kind, CharacterId answerer,
        CharacterId requester, bool accept);

    // Xoá khỏi danh sách (kFriend, kBlack, kEnemy, kTemp). `verified` = world đã kiểm mật khẩu cấp hai.
    [[nodiscard]] RelationResult remove(CharacterId actor, CharacterId target, bool verified);
    // Đưa vào danh sách đen; bạn bè thì đổi sang đen và đối phương mất mục của mình (CanTransition).
    [[nodiscard]] RelationResult blacklist(const PlayerDirectory& directory, CharacterId actor, CharacterId target);
    // Ghi kẻ thù (bị giết), bạn tạm (vừa nói chuyện). Không phát lỗi khi danh sách đầy: kẻ cũ nhất rời đi.
    [[nodiscard]] RelationResult note_enemy(const PlayerDirectory& directory, CharacterId actor, CharacterId killer);
    [[nodiscard]] RelationResult note_temp(const PlayerDirectory& directory, CharacterId actor, CharacterId other);
    [[nodiscard]] RelationResult move_group(CharacterId actor, CharacterId friend_id, std::uint8_t group);
    [[nodiscard]] RelationResult set_mood(const PlayerDirectory& directory, CharacterId actor, std::string_view text);
    // Cộng/trừ độ thân thiết cho cả hai phía; kẹp trong [0, relation_max_friend_point].
    [[nodiscard]] RelationResult add_point(CharacterId left, CharacterId right, std::int32_t delta);

    [[nodiscard]] RelationResult divorce(CharacterId actor);
    [[nodiscard]] RelationResult leave_master(Tick now, CharacterId prentice);
    [[nodiscard]] RelationResult expel_prentice(CharacterId master, CharacterId prentice);
    // Đồ đệ đạt `level`: trả thưởng cho sư phụ nếu cấp rơi vào một hàng bảng thưởng chưa nhận.
    [[nodiscard]] RelationResult on_prentice_level(const PlayerDirectory& directory, const MentorTable& table, CharacterId prentice,
        std::uint16_t level);

    // Lên/xuống tuyến: báo cho bạn có độ thân thiết >= presence_intimacy đang trực tuyến.
    [[nodiscard]] RelationEvents on_presence(const PlayerDirectory& directory, CharacterId actor, bool online) const;
    // Gọi thưa (vài giây một lần): bỏ lời chờ quá hạn.
    void tick(Tick now);

    // Kiểm bất biến mọi sổ đang nạp (trùng id, quá trần, quan hệ hai chiều lệch, tự tham chiếu).
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    struct PendingKey {
        CharacterId target{};
        BondKind kind = BondKind::kFriend;
        CharacterId requester{};
        friend auto operator<=>(const PendingKey&, const PendingKey&) noexcept = default;
    };

    [[nodiscard]] RelationSheet* mutable_sheet(CharacterId owner);
    [[nodiscard]] std::optional<RelationError> check_request(
        Tick now, const PlayerDirectory& directory, BondKind kind, const PlayerCard& actor, const PlayerCard& target) const;
    void apply_bond(BondKind kind, const PlayerCard& requester, const PlayerCard& answerer, Tick now, RelationEvents& out);

    Limits limits_;
    RelationRules rules_;
    TickSpan pending_ttl_{};
    TickSpan betray_cooldown_{};
    std::map<CharacterId, RelationSheet> sheets_;
    std::map<PendingKey, Tick> pending_;
};

// Áp một sự kiện kOfflineChange lên sổ ĐÃ LƯU của chủ sổ ngoại tuyến (event.other): world đọc sổ từ kho, gọi hàm này,
// ghi lại. Dùng đúng luật chọn nhóm của lúc cả hai sổ đang nạp, nên khi chủ sổ vào lại hai phía vẫn khớp nhau
// (validate() không báo lệch hai chiều). false = sổ không có mục tương ứng hoặc mục đã sang kiểu khác (sự kiện
// đã cũ) và không đổi gì.
[[nodiscard]] bool apply_offline_change(const Limits& limits, RelationSheet& sheet, const RelationEvent& event);

// Mã hoá/giải mã sổ quan hệ (blob::kRelation, phiên bản 1). Thời hạn lưu là số tick CÒN LẠI so với
// `now` để không phụ thuộc đồng hồ của lần chạy trước. Giải mã kiểm miền, UTF-8, trùng id, trần.
[[nodiscard]] CodecResult encode_relation(const RelationSheet& sheet, Tick now, Bytes& out);
[[nodiscard]] std::expected<RelationSheet, CodecError> decode_relation(std::span<const std::byte> bytes, Tick now, const Limits& limits);

} // namespace game::social
