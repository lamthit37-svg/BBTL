#include "social/chat.hpp"

#include "core/text.hpp"
#include "ids/ids.hpp"
#include "social/directory.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/team.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <bitset>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::size_t kRepeatHistory = 16;
constexpr std::size_t kMaxAnnounceBytes = 4096;
constexpr std::size_t kMaxTargetNameBytes = 255;
constexpr std::int32_t kRoleCount = static_cast<std::int32_t>(ChannelRole::kJianghu) + 1;
constexpr std::uint64_t kFnvOffset = 14'695'981'039'346'656'037ULL;
constexpr std::uint64_t kFnvPrime = 1'099'511'628'211ULL;

[[nodiscard]] ChatResult reject(ChatError error) {
    ChatResult result;
    result.error = error;
    return result;
}

struct RoleTraits {
    ChatAudience audience;
    bool server_only;
    bool needs_item;
};

[[nodiscard]] constexpr RoleTraits traits_of(ChannelRole role) noexcept {
    switch (role) {
    case ChannelRole::kNearby: return {.audience = ChatAudience::kNearby, .server_only = false, .needs_item = false};
    case ChannelRole::kTeam:
    case ChannelRole::kWhisper:
    case ChannelRole::kCustom:
    case ChannelRole::kGuild:
    case ChannelRole::kSelf:
    case ChannelRole::kLeague: return {.audience = ChatAudience::kRecipients, .server_only = false, .needs_item = false};
    case ChannelRole::kWorld:
    case ChannelRole::kHelp:
    case ChannelRole::kRecruit:
    case ChannelRole::kJianghu: return {.audience = ChatAudience::kEverybody, .server_only = false, .needs_item = false};
    case ChannelRole::kSystem: return {.audience = ChatAudience::kEverybody, .server_only = true, .needs_item = false};
    case ChannelRole::kSect: return {.audience = ChatAudience::kSect, .server_only = false, .needs_item = false};
    case ChannelRole::kHorn:
    case ChannelRole::kLongRange:
    case ChannelRole::kStoryHorn: return {.audience = ChatAudience::kEverybody, .server_only = false, .needs_item = true};
    case ChannelRole::kServerHorn: return {.audience = ChatAudience::kEverybody, .server_only = true, .needs_item = false};
    case ChannelRole::kSceneNotice: return {.audience = ChatAudience::kNearby, .server_only = true, .needs_item = false};
    case ChannelRole::kSameCity:
    case ChannelRole::kRaid:
    case ChannelRole::kSquad:
    case ChannelRole::kRegion:
    case ChannelRole::kClan:
    case ChannelRole::kWarAlliance:
    case ChannelRole::kBeyond: return {.audience = ChatAudience::kExternal, .server_only = false, .needs_item = false};
    case ChannelRole::kUnknown: break;
    }
    return {.audience = ChatAudience::kExternal, .server_only = true, .needs_item = false};
}

[[nodiscard]] ChannelRole role_of(std::uint32_t id) noexcept {
    return std::cmp_less(id, kRoleCount) ? static_cast<ChannelRole>(id) : ChannelRole::kUnknown;
}

[[nodiscard]] bool is_blank(std::string_view text) noexcept {
    return std::ranges::all_of(text, [](char c) { return c == ' ' || c == '\t'; });
}

// Chữ người chơi không bao giờ được client giải thành token: '%' thành '?' như ReplaceIllegalString của 2008,
// và "#{" (client giải thành chuỗi hệ thống/tiền/vật phẩm) thành "##{" - hai '#' là một dấu '#' chữ.
// Duyệt đúng cách client tách lệnh: "##" là một cặp nên "###{" vẫn còn một "#{" thật và được vô hiệu.
[[nodiscard]] std::string neutralize_tokens(std::string_view text) {
    std::string out;
    out.reserve(text.size() + (text.size() / 2U));
    for (std::size_t pos = 0; pos < text.size();) {
        const char c = text[pos];
        if (c == '%') {
            out.push_back('?');
            ++pos;
        } else if (c == '#' && pos + 1 < text.size() && text[pos + 1] == '#') {
            out.append("##");
            pos += 2;
        } else if (c == '#' && pos + 1 < text.size() && text[pos + 1] == '{') {
            out.append("##{");
            pos += 2;
        } else {
            out.push_back(c);
            ++pos;
        }
    }
    return out;
}

[[nodiscard]] bool has_blacklisted(const RelationSheet& sheet, CharacterId other) noexcept {
    const auto found = std::ranges::find(sheet.entries, other, &RelationEntry::id);
    return found != sheet.entries.end() && found->kind == RelationKind::kBlack;
}

} // namespace

std::string_view describe(ChatError error) noexcept {
    switch (error) {
    case ChatError::kUnknownPlayer: return "không thấy người chơi";
    case ChatError::kUnknownChannel: return "kênh chat không tồn tại";
    case ChatError::kServerOnly: return "kênh này chỉ máy chủ được phát";
    case ChatError::kMuted: return "bạn đang bị cấm chat";
    case ChatError::kLevelTooLow: return "cấp chưa đủ để chat ở kênh này";
    case ChatError::kNoResource: return "không đủ tài nguyên để chat ở kênh này";
    case ChatError::kEmpty: return "nội dung trống";
    case ChatError::kTooLong: return "nội dung quá dài";
    case ChatError::kBadText: return "nội dung chứa ký tự không hợp lệ";
    case ChatError::kRateLimited: return "gửi quá nhanh trên kênh này";
    case ChatError::kFlood: return "gửi quá nhanh";
    case ChatError::kRepeated: return "đừng lặp lại cùng một nội dung";
    case ChatError::kNoTeam: return "bạn chưa có tổ đội";
    case ChatError::kNoGuild: return "bạn chưa vào bang";
    case ChatError::kNoSect: return "bạn chưa gia nhập môn phái";
    case ChatError::kNoLeague: return "bang của bạn chưa vào liên minh";
    case ChatError::kTargetNotFound: return "không tìm thấy người nhận";
    case ChatError::kBadTarget: return "người nhận không hợp lệ";
    case ChatError::kNoSuchChannel: return "kênh tự lập không tồn tại";
    case ChatError::kNotInChannel: return "không ở trong kênh này";
    case ChatError::kNotOwner: return "chỉ chủ kênh mới làm được việc này";
    case ChatError::kChannelFull: return "kênh đã đủ người";
    case ChatError::kAlreadyMember: return "đã ở trong kênh";
    case ChatError::kHasChannel: return "bạn đã lập một kênh tự lập";
    case ChatError::kTooManyChannels: return "máy chủ đã đủ số kênh tự lập";
    case ChatError::kHostile: return "không thể mời người thuộc phe địch";
    case ChatError::kBadValue: return "giá trị không hợp lệ";
    }
    return "lỗi chat lạ";
}

// ---------------------------------------------------------------------------------------------
// Bảng kênh.
// ---------------------------------------------------------------------------------------------

std::expected<ChatCatalog, std::string> ChatCatalog::parse(std::string_view tsv_text) {
    auto parsed = table::parse_tsv(tsv_text);
    if (!parsed) return std::unexpected(std::move(parsed.error()));
    const table::Tsv& sheet = *parsed;
    ChatCatalog catalog;
    std::bitset<kMaxChannels> seen;
    constexpr std::array<std::pair<std::string_view, std::string_view>, 3> kCostColumns{{
        {"cost_kind_1", "cost_amount_1"},
        {"cost_kind_2", "cost_amount_2"},
        {"cost_kind_3", "cost_amount_3"},
    }};
    for (std::size_t row = 0; row < sheet.rows.size(); ++row) {
        table::RowReader reader(sheet, row);
        ChatChannelInfo info;
        const std::uint32_t id = reader.number("id", 0, static_cast<std::uint32_t>(kMaxChannels - 1));
        info.name = std::string{reader.text("channel_name")};
        info.leader_text = std::string{reader.text("leader_text")};
        info.interval = millis_to_ticks(reader.integer("send_interval_ms", 0, 3'600'000));
        for (const auto& [kind_column, amount_column] : kCostColumns) {
            const std::int32_t kind = reader.integer(kind_column, -1, 2);
            const std::int32_t amount = reader.integer(amount_column, 0, 1'000'000);
            if (kind >= 0 && amount > 0) {
                info.costs.push_back({.resource = static_cast<ChatResource>(kind), .amount = amount});
            }
        }
        info.level_limit = static_cast<std::uint16_t>(reader.integer("level_limit", 0, 1000));
        if (reader.error()) return std::unexpected(*reader.error());
        if (seen.test(id)) return std::unexpected(std::format("dòng {}: trùng id kênh {}", sheet.lines[row], id));
        seen.set(id);
        info.id = ChannelId{static_cast<std::uint8_t>(id)};
        info.role = role_of(id);
        const RoleTraits traits = traits_of(info.role);
        info.audience = traits.audience;
        info.server_only = traits.server_only;
        info.needs_item = traits.needs_item;
        catalog.channels_.push_back(std::move(info));
    }
    std::ranges::sort(catalog.channels_, {}, &ChatChannelInfo::id);
    return catalog;
}

const ChatChannelInfo* ChatCatalog::find(ChannelId id) const {
    const auto found = std::ranges::lower_bound(channels_, id, {}, &ChatChannelInfo::id);
    return found == channels_.end() || found->id != id ? nullptr : &*found;
}

// ---------------------------------------------------------------------------------------------
// ChatBook.
// ---------------------------------------------------------------------------------------------

ChatBook::ChatBook(const Limits& limits, ChatCatalog catalog, const TextFilter& filter)
    : limits_(limits),
      catalog_(std::move(catalog)),
      filter_(&filter),
      global_interval_(millis_to_ticks(limits.chat_global_interval_ms)),
      repeat_window_(seconds_to_ticks(limits.chat_repeat_window_seconds)) {}

bool ChatBook::take_token(Tick& next, Tick now, TickSpan interval, std::int64_t burst) const {
    if (interval.count <= 0) return true;
    // GCRA: `next` là mốc lý thuyết của tin kế; chỉ được gửi khi chưa dồn quá (burst - 1) khoảng.
    const TickSpan tolerance{interval.count * (burst - 1)};
    if (next > ids::advance(now, tolerance)) return false;
    next = ids::advance(std::max(next, now), interval);
    return true;
}

std::uint64_t ChatBook::fingerprint(std::string_view text, CharacterId target) {
    std::uint64_t hash = kFnvOffset;
    for (const char c : text) {
        if (c == ' ' || c == '\t') continue;
        auto byte = static_cast<std::uint8_t>(c);
        if (byte >= 'A' && byte <= 'Z') byte = static_cast<std::uint8_t>(byte - 'A' + 'a');
        hash = (hash ^ byte) * kFnvPrime;
    }
    return (hash ^ target.value()) * kFnvPrime;
}

bool ChatBook::repeated(const Speaker& speaker, Tick now, std::uint64_t fingerprint_value) const {
    std::int64_t same = 0;
    for (const Recent& recent : speaker.recent) {
        if (recent.fingerprint == fingerprint_value && ids::advance(recent.at, repeat_window_) > now) ++same;
    }
    return same >= limits_.chat_repeat_max;
}

std::vector<CharacterId> ChatBook::online_only(const PlayerDirectory& directory, const std::vector<CharacterId>& ids) const {
    std::vector<CharacterId> out;
    out.reserve(ids.size());
    for (const CharacterId id : ids) {
        const auto card = directory.find(id);
        if (card && card->online) out.push_back(id);
    }
    return out;
}

ChatEvent ChatBook::notice(CharacterId to, ChatError error) {
    ChatEvent event;
    event.kind = ChatEventKind::kNotice;
    event.error = error;
    event.recipients = {to};
    return event;
}

std::optional<ChatError> ChatBook::route(const ChatChannelInfo& info, const ChatWorld& world, const PlayerCard& card,
                                         const SendRequest& request, std::vector<CharacterId>& recipients,
                                         bool& silent) const {
    switch (info.role) {
    case ChannelRole::kTeam: {
        const auto team_id = world.teams->team_of(card.id);
        const Team* team = team_id ? world.teams->find(*team_id) : nullptr;
        if (team == nullptr) return ChatError::kNoTeam;
        for (const TeamMember& member : team->members) {
            if (member.online) recipients.push_back(member.id);
        }
        return std::nullopt;
    }
    case ChannelRole::kGuild: {
        const auto guild_id = world.guilds->guild_of(card.id);
        const Guild* guild = guild_id ? world.guilds->find(*guild_id) : nullptr;
        if (guild == nullptr) return ChatError::kNoGuild;
        std::vector<CharacterId> everyone;
        everyone.reserve(guild->members.size());
        for (const GuildMember& member : guild->members) everyone.push_back(member.id);
        recipients = online_only(*world.directory, everyone);
        return std::nullopt;
    }
    case ChannelRole::kLeague: {
        const auto guild_id = world.guilds->guild_of(card.id);
        if (!guild_id) return ChatError::kNoGuild;
        const League* league = world.guilds->league_of(*guild_id);
        if (league == nullptr) return ChatError::kNoLeague;
        std::vector<CharacterId> everyone;
        for (const GuildId member_guild : league->members) {
            const Guild* guild = world.guilds->find(member_guild);
            if (guild == nullptr) continue;
            for (const GuildMember& member : guild->members) everyone.push_back(member.id);
        }
        recipients = online_only(*world.directory, everyone);
        return std::nullopt;
    }
    case ChannelRole::kCustom: {
        const CustomChannel* channel = find_channel(request.custom);
        if (channel == nullptr) return ChatError::kNoSuchChannel;
        if (std::ranges::find(channel->members, card.id) == channel->members.end()) return ChatError::kNotInChannel;
        recipients = online_only(*world.directory, channel->members);
        return std::nullopt;
    }
    case ChannelRole::kWhisper: {
        if (request.target_name.empty() || !is_plain_text(request.target_name, kMaxTargetNameBytes)) return ChatError::kBadTarget;
        const auto target = world.directory->find_by_name(request.target_name);
        if (!target || !target->online) return ChatError::kTargetNotFound;
        if (target->id == card.id) return ChatError::kBadTarget;
        // Thù địch xử như không có người đó (2008 GWChatHandler: "处理方法跟查无此人相同").
        if (world.directory->hostile(card, *target)) return ChatError::kTargetNotFound;
        // Bị chặn: người gửi thấy tin đã đi, người nhận không thấy gì (không lộ việc bị chặn).
        const RelationSheet* sheet = world.relations->sheet(target->id);
        silent = sheet != nullptr && has_blacklisted(*sheet, card.id);
        recipients = {target->id};
        return std::nullopt;
    }
    case ChannelRole::kSelf: recipients = {card.id}; return std::nullopt;
    case ChannelRole::kSect:
        if (card.sect == ids::kSectNone || card.sect >= ids::kSectCount) return ChatError::kNoSect;
        return std::nullopt;
    default: return std::nullopt;
    }
}

ChatResult ChatBook::send(Tick now, const ChatWorld& world, const SendRequest& request) {
    const ChatChannelInfo* info = catalog_.find(request.channel);
    if (info == nullptr) return reject(ChatError::kUnknownChannel);
    if (info->server_only) return reject(ChatError::kServerOnly);
    const auto card = world.directory->find(request.sender);
    if (!card || !card->online) return reject(ChatError::kUnknownPlayer);
    if (muted(now, request.sender)) return reject(ChatError::kMuted);
    if (card->level < info->level_limit) return reject(ChatError::kLevelTooLow);
    for (const ChatCost& cost : info->costs) {
        if (request.wallet.at(static_cast<std::size_t>(cost.resource)) < cost.amount) return reject(ChatError::kNoResource);
    }
    const auto max_bytes = static_cast<std::size_t>(limits_.chat_max_bytes);
    if (request.text.size() > max_bytes) return reject(ChatError::kTooLong);
    if (!is_plain_text(request.text, max_bytes)) return reject(ChatError::kBadText);
    if (is_blank(request.text)) return reject(ChatError::kEmpty);

    // Nhịp: tính thử cả hai bucket rồi mới ghi, để tin bị từ chối không tiêu token của bucket còn lại.
    Speaker& speaker = speakers_[request.sender];
    Tick channel_next = speaker.channel_next.at(request.channel.value());
    Tick global_next = speaker.global_next;
    if (!take_token(channel_next, now, info->interval, limits_.chat_burst)) return reject(ChatError::kRateLimited);
    if (!take_token(global_next, now, global_interval_, limits_.chat_global_burst)) return reject(ChatError::kFlood);
    speaker.channel_next.at(request.channel.value()) = channel_next;
    speaker.global_next = global_next;

    ChatResult result;
    ChatEvent message;
    bool silent = false;
    if (const auto problem = route(*info, world, *card, request, message.recipients, silent)) return reject(*problem);

    // Thì thầm cho hai người khác nhau không tính là lặp: dấu vân tay gồm cả người nhận.
    const CharacterId salt = info->role == ChannelRole::kWhisper && !message.recipients.empty() ? message.recipients.front() : CharacterId{};
    const std::uint64_t print = fingerprint(request.text, salt);
    if (repeated(speaker, now, print)) return reject(ChatError::kRepeated);

    for (const ChatCost& cost : info->costs) {
        ChatEvent charge;
        charge.kind = ChatEventKind::kCharge;
        charge.subject = card->id;
        charge.channel = info->id;
        charge.resource = cost.resource;
        charge.amount = cost.amount;
        result.events.push_back(std::move(charge));
    }
    while (!speaker.recent.empty() && ids::advance(speaker.recent.front().at, repeat_window_) <= now) speaker.recent.pop_front();
    speaker.recent.push_back({.fingerprint = print, .at = now});
    if (speaker.recent.size() > kRepeatHistory) speaker.recent.pop_front();
    if (silent) return result;

    message.kind = ChatEventKind::kMessage;
    message.serial = next_serial_++;
    message.channel = info->id;
    message.custom = request.custom;
    message.audience = info->audience;
    message.subject = card->id;
    message.sender_name = card->name;
    message.scene = card->scene;
    // Sổ bang là nguồn đúng về bang của người nói; thẻ người chơi của world chỉ là dự phòng khi chưa có sổ.
    message.guild = world.guilds != nullptr ? world.guilds->guild_of(card->id).value_or(card->guild) : card->guild;
    message.sect = card->sect;
    message.camp = card->camp;
    message.text = neutralize_tokens(filter_->mask(request.text));
    result.events.push_back(std::move(message));
    return result;
}

ChatResult ChatBook::announce(ChannelId channel, std::string_view text, std::vector<CharacterId> recipients, SceneId scene) {
    const ChatChannelInfo* info = catalog_.find(channel);
    if (info == nullptr) return reject(ChatError::kUnknownChannel);
    if (text.size() > kMaxAnnounceBytes) return reject(ChatError::kTooLong);
    if (!core::is_valid_utf8(text)) return reject(ChatError::kBadText);
    if (text.empty()) return reject(ChatError::kEmpty);
    ChatResult result;
    ChatEvent message;
    message.kind = ChatEventKind::kMessage;
    message.serial = next_serial_++;
    message.channel = info->id;
    message.audience = info->audience;
    message.scene = scene;
    message.text = std::string{text};
    if (info->audience == ChatAudience::kRecipients) message.recipients = std::move(recipients);
    result.events.push_back(std::move(message));
    return result;
}

void ChatBook::mute(Tick now, CharacterId who, Tick until) {
    if (until <= now) {
        mutes_.erase(who);
        return;
    }
    mutes_.insert_or_assign(who, until);
}

bool ChatBook::muted(Tick now, CharacterId who) const {
    const auto found = mutes_.find(who);
    return found != mutes_.end() && now < found->second;
}

// ---------------------------------------------------------------------------------------------
// Kênh tự lập.
// ---------------------------------------------------------------------------------------------

const CustomChannel* ChatBook::find_channel(CustomChannelId id) const {
    const auto found = channels_.find(id);
    return found == channels_.end() ? nullptr : &found->second;
}

CustomChannel* ChatBook::mutable_channel(CustomChannelId id) {
    const auto found = channels_.find(id);
    return found == channels_.end() ? nullptr : &found->second;
}

std::optional<CustomChannelId> ChatBook::channel_owned_by(CharacterId owner) const {
    for (const auto& [id, channel] : channels_) {
        if (!channel.members.empty() && channel.members.front() == owner) return id;
    }
    return std::nullopt;
}

namespace {

[[nodiscard]] ChatEvent channel_event(ChatEventKind kind, CustomChannelId channel, CharacterId subject, std::vector<CharacterId> recipients) {
    ChatEvent event;
    event.kind = kind;
    event.channel = ChannelId{static_cast<std::uint8_t>(ChannelRole::kCustom)};
    event.custom = channel;
    event.subject = subject;
    event.recipients = std::move(recipients);
    return event;
}

[[nodiscard]] ChatResult one(ChatEvent event) {
    ChatResult result;
    result.events.push_back(std::move(event));
    return result;
}

} // namespace

ChatResult ChatBook::create_channel(const PlayerDirectory& directory, CharacterId actor) {
    const auto card = directory.find(actor);
    if (!card || !card->online) return reject(ChatError::kUnknownPlayer);
    if (channel_owned_by(actor)) return reject(ChatError::kHasChannel);
    if (std::cmp_greater_equal(channels_.size(), limits_.chat_max_custom_channels) ||
        next_custom_ == std::numeric_limits<std::uint32_t>::max()) {
        return reject(ChatError::kTooManyChannels);
    }
    const CustomChannelId id{next_custom_++};
    channels_.emplace(id, CustomChannel{.id = id, .members = {actor}});
    return one(channel_event(ChatEventKind::kChannelCreated, id, actor, {actor}));
}

// Không làm chủ kênh nào: nếu là thành viên của một kênh thì lỗi là "không phải chủ", còn không thì "không có kênh".
ChatError ChatBook::not_owner_error(CharacterId actor) const {
    const bool member_somewhere = std::ranges::any_of(channels_, [actor](const auto& entry) {
        return std::ranges::find(entry.second.members, actor) != entry.second.members.end();
    });
    return member_somewhere ? ChatError::kNotOwner : ChatError::kNoSuchChannel;
}

ChatResult ChatBook::invite(const PlayerDirectory& directory, CharacterId actor, CharacterId target) {
    const auto owned = channel_owned_by(actor);
    if (!owned) return reject(not_owner_error(actor));
    CustomChannel* channel = mutable_channel(*owned);
    if (channel == nullptr) return reject(ChatError::kNoSuchChannel);
    const auto actor_card = directory.find(actor);
    const auto target_card = directory.find(target);
    if (!actor_card || !target_card || !target_card->online) return reject(ChatError::kTargetNotFound);
    if (target == actor) return reject(ChatError::kBadTarget);
    if (directory.hostile(*actor_card, *target_card)) return reject(ChatError::kHostile);
    if (std::ranges::find(channel->members, target) != channel->members.end()) return reject(ChatError::kAlreadyMember);
    if (std::cmp_greater_equal(channel->members.size(), limits_.chat_custom_channel_members)) return reject(ChatError::kChannelFull);
    channel->members.push_back(target);
    return one(channel_event(ChatEventKind::kChannelMember, channel->id, target, online_only(directory, channel->members)));
}

ChatResult ChatBook::kick(CharacterId actor, CharacterId target) {
    const auto owned = channel_owned_by(actor);
    if (!owned) return reject(not_owner_error(actor));
    CustomChannel* channel = mutable_channel(*owned);
    if (channel == nullptr) return reject(ChatError::kNoSuchChannel);
    if (target == actor) return reject(ChatError::kBadTarget);
    const auto found = std::ranges::find(channel->members, target);
    if (found == channel->members.end()) return reject(ChatError::kNotInChannel);
    ChatEvent event = channel_event(ChatEventKind::kChannelKicked, channel->id, target, channel->members);
    channel->members.erase(found);
    return one(std::move(event));
}

ChatResult ChatBook::leave(CharacterId actor, CustomChannelId channel_id) {
    CustomChannel* channel = mutable_channel(channel_id);
    if (channel == nullptr) return reject(ChatError::kNoSuchChannel);
    const auto found = std::ranges::find(channel->members, actor);
    if (found == channel->members.end()) return reject(ChatError::kNotInChannel);
    if (found == channel->members.begin()) return dismiss(actor);  // chủ rời kênh tức là giải tán
    channel->members.erase(found);
    std::vector<CharacterId> remaining = channel->members;
    remaining.push_back(actor);  // người rời cũng nhận để client của họ gỡ kênh
    return one(channel_event(ChatEventKind::kChannelLeft, channel->id, actor, std::move(remaining)));
}

ChatResult ChatBook::dismiss(CharacterId actor) {
    const auto owned = channel_owned_by(actor);
    if (!owned) return reject(not_owner_error(actor));
    ChatEvent event = channel_event(ChatEventKind::kChannelDismissed, *owned, actor, channels_.at(*owned).members);
    channels_.erase(*owned);
    return one(std::move(event));
}

ChatEvents ChatBook::on_logout(CharacterId who) {
    ChatEvents events;
    std::vector<CustomChannelId> dismissed;
    for (auto& [id, channel] : channels_) {
        const auto found = std::ranges::find(channel.members, who);
        if (found == channel.members.end()) continue;
        if (found == channel.members.begin()) {
            events.push_back(channel_event(ChatEventKind::kChannelDismissed, id, who, channel.members));
            dismissed.push_back(id);
            continue;
        }
        channel.members.erase(found);
        events.push_back(channel_event(ChatEventKind::kChannelLeft, id, who, channel.members));
    }
    for (const CustomChannelId id : dismissed) channels_.erase(id);
    return events;
}

// ---------------------------------------------------------------------------------------------
// Dọn dẹp và kiểm bất biến.
// ---------------------------------------------------------------------------------------------

void ChatBook::tick(Tick now) {
    if (now.value() % static_cast<std::uint64_t>(kTicksPerSecond) != 0) return;
    std::erase_if(mutes_, [now](const auto& entry) { return now >= entry.second; });
    std::erase_if(speakers_, [&](auto& entry) {
        Speaker& speaker = entry.second;
        while (!speaker.recent.empty() && ids::advance(speaker.recent.front().at, repeat_window_) <= now) speaker.recent.pop_front();
        const bool cold = speaker.global_next <= now && speaker.recent.empty() &&
                          std::ranges::all_of(speaker.channel_next, [now](Tick next) { return next <= now; });
        return cold;
    });
}

std::expected<void, std::string> ChatBook::validate() const {
    if (std::cmp_greater(channels_.size(), limits_.chat_max_custom_channels)) {
        return std::unexpected(std::format("có {} kênh tự lập, trần {}", channels_.size(), limits_.chat_max_custom_channels));
    }
    std::set<CharacterId> owners;
    for (const auto& [id, channel] : channels_) {
        if (id.value() == 0 || channel.id != id) return std::unexpected(std::format("kênh {}: id sai", id.value()));
        if (channel.members.empty()) return std::unexpected(std::format("kênh {}: không có chủ", id.value()));
        if (std::cmp_greater(channel.members.size(), limits_.chat_custom_channel_members)) {
            return std::unexpected(std::format("kênh {}: {} thành viên quá trần", id.value(), channel.members.size()));
        }
        const std::set<CharacterId> unique(channel.members.begin(), channel.members.end());
        if (unique.size() != channel.members.size()) return std::unexpected(std::format("kênh {}: thành viên trùng", id.value()));
        if (!owners.insert(channel.members.front()).second) {
            return std::unexpected(std::format("kênh {}: chủ {} đã có kênh khác", id.value(), channel.members.front().value()));
        }
    }
    return {};
}

} // namespace game::social
