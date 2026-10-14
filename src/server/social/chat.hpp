#pragma once
// Chat: kênh theo bảng chat_channels.tsv (client 2026 ChatConfig.txt), kiểm quyền gửi (câm, cấp tối thiểu,
// tiêu hao), giới hạn nhịp bằng token bucket đếm tick, chống lặp tin, lọc chữ cấm, và kênh tự lập (kênh
// 5 "自建"). Lõi thuần: nhận yêu cầu, trả sự kiện tin nhắn kèm danh sách người nhận mà lõi tự tính được
// (đội, bang, liên minh, kênh tự lập, thì thầm); kênh phụ thuộc vị trí hay hệ thống ngoài lõi (cận,
// thế giới, môn phái, đột kích...) trả `audience` để world phân phối.
//
// Nguồn: WorldServer 2008 (Packets/GWChatHandler.cpp, WorldData/ChatCenter.cpp, Packets/GWChannel*.cpp);
// kiểm tiêu hao và cấp của GameServer (Packets/CGChatHandler.cpp); lọc ký tự '%' của
// Common/GameUtil.cpp ReplaceIllegalString; bảng kênh, giãn cách, tiêu hao, cấp của client 2026.
// Khác gốc: (1) tiêu hao chỉ trừ khi tin được gửi (2008 trừ trước khi xét lọc/đích); (2) kênh tự lập có
// chủ là thành viên đầu, thành viên rời được, chủ rời mạng thì kênh giải tán (2008 để chủ ngoài danh sách
// và không bao giờ dọn); (3) lọc chữ cấm che bằng '*' ở máy chủ thay vì để client thay cả dòng bằng
// "请注意你的言辞"; (4) thêm giãn cách theo token bucket, chống lặp, câm; (5) "#{" trong chữ người chơi
// thành "##{" để client không giải thành chuỗi hệ thống (#{_MONEY...}, #{_ITEM...}), '%' thành '?' như 2008.
// Số tiêu hao: cost_kind 0 = MP, 1 = tinh lực, 2 = hoạt lực, -1 = không (tiêu đề cột của bảng gốc).

#include "social/directory.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/team.hpp"
#include "social/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <expected>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

// Số kênh tối đa mà bảng được khai (id 0..31): mảng trạng thái nhịp của mỗi người nói cỡ cố định theo đó.
inline constexpr std::size_t kMaxChannels = 32;

enum class ChatError : std::uint8_t {
    kUnknownPlayer = 1,
    kUnknownChannel,
    kServerOnly,        // kênh chỉ máy chủ được phát (hệ thống, thông báo cảnh)
    kMuted,
    kLevelTooLow,
    kNoResource,        // thiếu MP/tinh lực/hoạt lực theo bảng
    kEmpty,
    kTooLong,
    kBadText,           // UTF-8 hỏng hoặc ký tự điều khiển
    kRateLimited,       // vượt nhịp của riêng kênh
    kFlood,             // vượt nhịp chung mọi kênh
    kRepeated,          // lặp nguyên văn quá số lần trong cửa sổ
    kNoTeam,
    kNoGuild,
    kNoSect,
    kNoLeague,
    kTargetNotFound,    // thì thầm: không có người đó, ngoại tuyến hay thù địch (2008 cũng gộp)
    kBadTarget,         // thì thầm cho chính mình hay tên không hợp lệ
    kNoSuchChannel,     // kênh tự lập không tồn tại
    kNotInChannel,
    kNotOwner,
    kChannelFull,
    kAlreadyMember,
    kHasChannel,        // đã làm chủ một kênh tự lập (2008 CHANNEL_ERROR_HASCHANNEL)
    kTooManyChannels,   // đủ chat_max_custom_channels (2008 CHANNEL_ERROR_CHANNELFULL)
    kHostile,
    kBadValue,
};

[[nodiscard]] std::string_view describe(ChatError error) noexcept;

// Tài nguyên mà bảng kênh bắt trả mỗi tin.
enum class ChatResource : std::uint8_t {
    kMp = 0,
    kEnergy = 1,  // tinh lực
    kVigor = 2,   // hoạt lực
};
inline constexpr std::size_t kChatResourceCount = 3;

struct ChatCost {
    ChatResource resource = ChatResource::kMp;
    std::int64_t amount = 0;
};

// Vai của kênh trong lõi, gắn theo id của client 2026 (chat_channels.tsv: 0 附近 ... 24 江湖).
enum class ChannelRole : std::uint8_t {
    kNearby = 0, kTeam, kWorld, kWhisper, kSystem, kCustom, kGuild, kSect, kSelf, kHelp, kHorn, kSameCity,
    kLeague, kRaid, kSquad, kLongRange, kRegion, kClan, kRecruit, kStoryHorn, kServerHorn, kSceneNotice,
    kWarAlliance, kBeyond, kJianghu,
    kUnknown,  // id ngoài 0..24 của bảng: lõi không biết nghĩa nên chỉ máy chủ được phát
};

// Ai nhận tin.
enum class ChatAudience : std::uint8_t {
    kRecipients = 0,  // lõi liệt kê trong `recipients` (đội, bang, liên minh, kênh tự lập, thì thầm, tự thân)
    kNearby,          // world: người cùng cảnh trong tầm nghe của người nói
    kEverybody,       // world: mọi người chơi trực tuyến
    kSect,            // world: người trực tuyến cùng môn phái `sect`
    kExternal,        // world: hệ thống ngoài lõi (đột kích, tiểu đội, thế tộc, chiến minh, cùng thành, khu vực)
};

struct ChatChannelInfo {
    ChannelId id{};
    ChannelRole role = ChannelRole::kUnknown;
    std::string name;
    std::string leader_text;
    TickSpan interval{};                    // giãn cách giữa hai tin của một người trên kênh này; 0 = không
    std::vector<ChatCost> costs;            // chỉ các mục có kind 0..2
    std::uint16_t level_limit = 0;
    ChatAudience audience = ChatAudience::kExternal;
    bool server_only = false;               // client không được gửi
    bool needs_item = false;                // loa: world phải có vật phẩm loa và trừ khi tin được gửi
};

class ChatCatalog {
public:
    // Nạp chat_channels.tsv. Lỗi: thiếu cột, số ngoài miền, trùng id, id ≥ kMaxChannels.
    [[nodiscard]] static std::expected<ChatCatalog, std::string> parse(std::string_view tsv_text);

    [[nodiscard]] const ChatChannelInfo* find(ChannelId id) const;
    [[nodiscard]] const std::vector<ChatChannelInfo>& channels() const noexcept { return channels_; }

private:
    std::vector<ChatChannelInfo> channels_;  // xếp tăng theo id
};

enum class ChatEventKind : std::uint8_t {
    kMessage,           // tin nhắn đi tiếp
    kCharge,            // subject phải bị trừ `amount` của `resource`
    kNotice,            // audience kRecipients, recipients = {người nhận}; error
    kChannelCreated,    // custom, subject = chủ; recipients = {chủ}
    kChannelMember,     // custom, subject = người mới; recipients = mọi thành viên gồm người mới
    kChannelKicked,     // custom, subject bị đuổi; recipients = mọi thành viên trước khi đuổi
    kChannelLeft,       // custom, subject rời; recipients = thành viên còn lại
    kChannelDismissed,  // custom; recipients = mọi thành viên trước khi giải tán
};

// Thứ tự trường xếp theo cỡ giảm dần để không phí đệm (clang-analyzer padding).
struct ChatEvent {
    std::uint64_t serial = 0;         // kMessage: số thứ tự tăng dần toàn thế giới (WorldChatID của 2008)
    CharacterId subject{};            // người nói / người bị trừ / người liên quan
    GuildId guild{};                  // kMessage: bang của người nói
    std::int64_t amount = 0;          // kCharge: số tài nguyên bị trừ
    std::vector<CharacterId> recipients;
    std::string sender_name;          // kMessage
    std::string text;                 // kMessage: đã lọc, đã vô hiệu token
    CustomChannelId custom{};
    SceneId scene{};                  // kMessage: cảnh của người nói (kNearby, kExternal)
    ChatEventKind kind = ChatEventKind::kNotice;
    ChannelId channel{};
    ChatAudience audience = ChatAudience::kRecipients;
    std::uint8_t sect = 0;            // kMessage: môn phái của người nói (kSect)
    std::uint8_t camp = 0;            // kMessage: phe của người nói (client tô màu)
    ChatError error = ChatError::kBadValue;
    ChatResource resource = ChatResource::kMp;
};

using ChatEvents = std::vector<ChatEvent>;
using ChatResult = Outcome<ChatEvent, ChatError>;

// Mọi thứ lõi cần đọc để tính người nhận và quyền; world giữ sở hữu.
struct ChatWorld {
    const PlayerDirectory* directory = nullptr;
    const TeamBook* teams = nullptr;
    const GuildBook* guilds = nullptr;
    const RelationBook* relations = nullptr;
};

struct SendRequest {
    CharacterId sender{};
    ChannelId channel{};
    std::string_view text;
    std::string_view target_name;    // kênh thì thầm
    CustomChannelId custom{};        // kênh tự lập
    // Tài nguyên người nói đang có, theo ChatResource; world điền từ nhân vật.
    std::array<std::int64_t, kChatResourceCount> wallet{};
};

struct CustomChannel {
    CustomChannelId id{};
    std::vector<CharacterId> members;  // chủ đứng đầu, không trùng
};

class ChatBook {
public:
    // `filter` phải sống lâu hơn ChatBook.
    ChatBook(const Limits& limits, ChatCatalog catalog, const TextFilter& filter);

    // Gửi một tin của người chơi. Có lỗi thì không trừ tài nguyên, không ghi nhận lặp; nhịp đã tính.
    [[nodiscard]] ChatResult send(Tick now, const ChatWorld& world, const SendRequest& request);

    // Tin do máy chủ phát (thông báo hệ thống, loa của kịch bản): không lọc, không nhịp, không câm; chỉ
    // kiểm kênh có trong bảng và UTF-8. `scene` dùng cho kênh kNearby.
    [[nodiscard]] ChatResult announce(ChannelId channel, std::string_view text, std::vector<CharacterId> recipients = {},
                                      SceneId scene = SceneId{});

    // Câm: người này không gửi được tin nào tới tick `until` (không gồm). until <= now thì bỏ câm.
    void mute(Tick now, CharacterId who, Tick until);
    [[nodiscard]] bool muted(Tick now, CharacterId who) const;

    // Kênh tự lập (kênh 5).
    [[nodiscard]] ChatResult create_channel(const PlayerDirectory& directory, CharacterId actor);
    [[nodiscard]] ChatResult invite(const PlayerDirectory& directory, CharacterId actor, CharacterId target);
    [[nodiscard]] ChatResult kick(CharacterId actor, CharacterId target);
    [[nodiscard]] ChatResult leave(CharacterId actor, CustomChannelId channel);
    [[nodiscard]] ChatResult dismiss(CharacterId actor);
    // Rời mạng: chủ thì giải tán kênh, thành viên thì ra khỏi mọi kênh. Độ phức tạp O(số kênh).
    [[nodiscard]] ChatEvents on_logout(CharacterId who);

    // Dọn trạng thái nhịp đã nguội và câm hết hạn; gọi mỗi tick, việc thật chạy mỗi giây.
    void tick(Tick now);

    [[nodiscard]] const ChatCatalog& catalog() const noexcept { return catalog_; }
    [[nodiscard]] const CustomChannel* find_channel(CustomChannelId id) const;
    [[nodiscard]] std::optional<CustomChannelId> channel_owned_by(CharacterId owner) const;
    [[nodiscard]] std::size_t channel_count() const noexcept { return channels_.size(); }
    [[nodiscard]] std::size_t speaker_count() const noexcept { return speakers_.size(); }

    // Kiểm bất biến của kênh tự lập; lỗi mô tả bằng tiếng Việt.
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    struct Recent {
        std::uint64_t fingerprint = 0;
        Tick at{};
    };
    struct Speaker {
        Tick global_next{};                       // GCRA: mốc lý thuyết của bucket chung
        std::array<Tick, kMaxChannels> channel_next{};
        std::deque<Recent> recent;                // tin gần nhất, mới ở cuối, tối đa kRepeatHistory
    };

    [[nodiscard]] bool take_token(Tick& next, Tick now, TickSpan interval, std::int64_t burst) const;
    [[nodiscard]] static std::uint64_t fingerprint(std::string_view text, CharacterId target);
    [[nodiscard]] bool repeated(const Speaker& speaker, Tick now, std::uint64_t fingerprint) const;
    [[nodiscard]] std::optional<ChatError> route(const ChatChannelInfo& info, const ChatWorld& world, const PlayerCard& card,
                                                 const SendRequest& request, std::vector<CharacterId>& recipients,
                                                 bool& silent) const;
    [[nodiscard]] std::vector<CharacterId> online_only(const PlayerDirectory& directory, const std::vector<CharacterId>& ids) const;
    [[nodiscard]] static ChatEvent notice(CharacterId to, ChatError error);
    [[nodiscard]] CustomChannel* mutable_channel(CustomChannelId id);
    [[nodiscard]] ChatError not_owner_error(CharacterId actor) const;

    Limits limits_;
    ChatCatalog catalog_;
    const TextFilter* filter_;
    TickSpan global_interval_{};
    TickSpan repeat_window_{};
    std::uint64_t next_serial_ = 1;
    std::uint32_t next_custom_ = 1;
    std::map<CharacterId, Speaker> speakers_;
    std::map<CharacterId, Tick> mutes_;
    std::map<CustomChannelId, CustomChannel> channels_;
};

} // namespace game::social
