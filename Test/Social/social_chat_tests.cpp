// Chat: bảng kênh, đường đi tin tới đúng người, quyền gửi (câm, cấp, tiêu hao), chữ người chơi (lọc, vô hiệu
// token), nhịp token bucket, chống lặp, kênh tự lập, và một kịch bản hạt giống cố định kiểm các bất biến
// của nhịp bằng tính chất toán học độc lập (không chép lại công thức của lõi).
#include "ids/ids.hpp"
#include "social/chat.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/team.hpp"
#include "social/types.hpp"
#include "social/wordfilter.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using social::ChannelId;
using social::ChannelRole;
using social::ChatAudience;
using social::ChatBook;
using social::ChatCatalog;
using social::ChatError;
using social::ChatEvent;
using social::ChatEventKind;
using social::ChatResource;
using social::ChatResult;
using social::ChatWorld;
using social::Limits;
using social::CustomChannelId;
using social::SendRequest;
using social::Tick;
using social::WordFilter;

// Cột như chat_channels.tsv thật. Kênh 31 là kênh lạ (chỉ máy chủ được phát).
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
    "7\tsect\tm\t10000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "8\tself\tu\t3000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "9\thelp\th\t3000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "10\thorn\tl\t0\t0\t7\t-1\t0\t-1\t0\t0\n"
    "12\tleague\te\t1000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "13\traid\tr\t1000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "18\trecruit\tz\t180000\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "21\tscene\t-1\t0\t-1\t0\t-1\t0\t-1\t0\t0\n"
    "31\tunknown\tq\t0\t-1\t0\t-1\t0\t-1\t0\t0\n";

constexpr std::string_view kWords =
    "# schema 1\nid\ttext\ttype\n"
    "1\t江泽民\t1\n"
    "2\tfuck\t1\n"
    "3\tsb\t1\n";

constexpr ChannelId kNearby{0};
constexpr ChannelId kTeamChannel{1};
constexpr ChannelId kWorldChannel{2};
constexpr ChannelId kWhisperChannel{3};
constexpr ChannelId kSystemChannel{4};
constexpr ChannelId kCustomChannel{5};
constexpr ChannelId kGuildChannel{6};
constexpr ChannelId kSectChannel{7};
constexpr ChannelId kSelfChannel{8};
constexpr ChannelId kHelpChannel{9};
constexpr ChannelId kHornChannel{10};
constexpr ChannelId kLeagueChannel{12};
constexpr ChannelId kRaidChannel{13};
constexpr ChannelId kRecruitChannel{18};
constexpr ChannelId kSceneChannel{21};
constexpr ChannelId kUnknownChannel{31};

constexpr Tick kT0{1000};

SendRequest make_request(CharacterId sender, ChannelId channel, std::string_view text) {
    return {.sender = sender, .channel = channel, .text = text, .target_name = {}, .custom = {}, .wallet = {}};
}

struct Fixture {
    FakeDirectory directory;
    social::AllowAllText policy;
    social::TeamBook teams;
    social::GuildBook guilds;
    social::RelationBook relations;
    std::unique_ptr<WordFilter> filter;
    ChatBook chat;

    explicit Fixture(std::uint64_t players, const Limits& limits = sample_limits())
        : teams(limits),
          guilds(limits, sample_guild_rules(), policy),
          relations(limits, sample_relation_rules()),
          filter(WordFilter::parse({.words_tsv = kWords, .reserved_tsv = {}, .extra_tsv = {}}).value_or(nullptr)),
          chat(limits, ChatCatalog::parse(kChannels).value_or(ChatCatalog{}), *filter) {
        for (std::uint64_t id = 1; id <= players; ++id) directory.add(id, "p" + std::to_string(id), 50);
    }

    [[nodiscard]] ChatWorld world() const {
        return {.directory = &directory, .teams = &teams, .guilds = &guilds, .relations = &relations};
    }

    ChatResult say(Tick now, std::uint64_t who, ChannelId channel, std::string_view text) {
        SendRequest request = make_request(cid(who), channel, text);
        request.wallet = {100, 100, 100};
        return chat.send(now, world(), request);
    }

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hàm trợ giúp của test, chỗ gọi luôn đặt tên theo thứ tự cố định
    ChatResult whisper(Tick now, std::uint64_t who, std::string_view target, std::string_view text) {
        SendRequest request = make_request(cid(who), kWhisperChannel, text);
        request.target_name = target;
        request.wallet = {100, 100, 100};
        return chat.send(now, world(), request);
    }

    ChatResult say_custom(Tick now, std::uint64_t who, CustomChannelId custom, std::string_view text) {
        SendRequest request = make_request(cid(who), kCustomChannel, text);
        request.custom = custom;
        request.wallet = {100, 100, 100};
        return chat.send(now, world(), request);
    }

    // Lập đội gồm `members`, người đầu là đội trưởng.
    void make_team(const std::vector<std::uint64_t>& members) {
        for (std::size_t index = 1; index < members.size(); ++index) {
            static_cast<void>(teams.invite(kT0, directory, cid(members.front()), cid(members.at(index))));
            static_cast<void>(teams.answer_invite(kT0, directory, cid(members.at(index)), cid(members.front()), true));
        }
    }

    // Lập bang do `chief` làm chủ với các `members` vào bang.
    social::GuildId make_guild(std::uint64_t chief, std::string_view name, const std::vector<std::uint64_t>& members) {
        const auto made = guilds.create(kT0, directory, cid(chief), name, "", 1'000'000);
        if (!made.ok() || made.events.empty()) return social::GuildId{};
        const social::GuildId id = made.events.front().guild;
        for (const std::uint64_t who : members) {
            static_cast<void>(guilds.apply(kT0, directory, cid(who), id));
            static_cast<void>(guilds.answer_application(kT0, directory, cid(chief), cid(who), true));
        }
        return id;
    }
};

[[nodiscard]] const ChatEvent* message_of(const ChatResult& result) {
    for (const ChatEvent& event : result.events) {
        if (event.kind == ChatEventKind::kMessage) return &event;
    }
    return nullptr;
}

// Bản sao của tin trong kết quả, hoặc tin rỗng khi không có: dùng để đọc trường mà không cần con trỏ thô.
[[nodiscard]] ChatEvent message_copy(const ChatResult& result) {
    const ChatEvent* found = message_of(result);
    return found != nullptr ? *found : ChatEvent{};
}

[[nodiscard]] std::vector<social::CharacterId> ids_of(const std::vector<std::uint64_t>& values) {
    std::vector<social::CharacterId> out;
    out.reserve(values.size());
    for (const std::uint64_t value : values) out.push_back(cid(value));
    return out;
}

[[nodiscard]] bool has_error(const ChatResult& result, ChatError error) { return result.error == error; }

[[nodiscard]] std::size_t charges_of(const ChatResult& result) {
    return static_cast<std::size_t>(std::ranges::count(result.events, ChatEventKind::kCharge, &ChatEvent::kind));
}

void catalog_parse(Context& context) {
    const auto catalog = ChatCatalog::parse(kChannels);
    context.expect(catalog.has_value() && catalog->channels().size() == 16, "mười sáu kênh");
    if (!catalog) return;
    const auto* world = catalog->find(kWorldChannel);
    context.expect(world != nullptr && world->role == ChannelRole::kWorld && world->audience == ChatAudience::kEverybody, "kênh thế giới");
    if (world != nullptr) {
        context.expect(world->interval.count == 3600 && world->level_limit == 15, "180 giây = 3600 tick, cấp 15");
        context.expect(world->costs.size() == 2 && world->costs.at(0).resource == ChatResource::kEnergy && world->costs.at(0).amount == 2 &&
                           world->costs.at(1).resource == ChatResource::kVigor && world->costs.at(1).amount == 2,
                       "tiêu hao tinh lực 2 và hoạt lực 2");
    }
    const auto* horn = catalog->find(kHornChannel);
    context.expect(horn != nullptr && horn->needs_item && horn->interval.count == 0 && horn->costs.size() == 1 &&
                       horn->costs.at(0).resource == ChatResource::kMp && horn->costs.at(0).amount == 7,
                   "loa: cần vật phẩm, không giãn cách, tốn 7 MP");
    const auto* system = catalog->find(kSystemChannel);
    context.expect(system != nullptr && system->server_only, "kênh hệ thống chỉ máy chủ");
    const auto* scene = catalog->find(kSceneChannel);
    context.expect(scene != nullptr && scene->server_only && scene->audience == ChatAudience::kNearby, "thông báo cảnh: server, cận");
    const auto* unknown = catalog->find(kUnknownChannel);
    context.expect(unknown != nullptr && unknown->role == ChannelRole::kUnknown && unknown->server_only, "id lạ chỉ máy chủ");
    const auto* raid = catalog->find(kRaidChannel);
    context.expect(raid != nullptr && raid->audience == ChatAudience::kExternal, "đột kích: world phân phối");
    context.expect(catalog->find(ChannelId{11}) == nullptr, "kênh không khai báo");

    const auto parse = [](std::string_view rows) {
        return ChatCatalog::parse(std::string{"# schema 1\nid\tchannel_name\tleader_text\tsend_interval_ms\tcost_kind_1\tcost_amount_1\t"
                                              "cost_kind_2\tcost_amount_2\tcost_kind_3\tcost_amount_3\tlevel_limit\n"} +
                                  std::string{rows}).has_value();
    };
    context.expect(parse("0\ta\tb\t0\t-1\t0\t-1\t0\t-1\t0\t0\n"), "dòng tối thiểu");
    context.expect(!parse("0\ta\tb\t0\t-1\t0\t-1\t0\t-1\t0\t0\n0\ta\tb\t0\t-1\t0\t-1\t0\t-1\t0\t0\n"), "trùng id");
    context.expect(!parse("32\ta\tb\t0\t-1\t0\t-1\t0\t-1\t0\t0\n"), "id 32 ngoài trần");
    context.expect(!parse("0\ta\tb\t0\t3\t1\t-1\t0\t-1\t0\t0\n"), "loại tiêu hao 3");
    context.expect(!parse("0\ta\tb\t-5\t-1\t0\t-1\t0\t-1\t0\t0\n"), "giãn cách âm");
    context.expect(!parse("0\ta\tb\t0\t0\t-1\t-1\t0\t-1\t0\t0\n"), "số tiêu hao âm");
    context.expect(!ChatCatalog::parse("# schema 1\nid\tchannel_name\n0\ta\n").has_value(), "thiếu cột");
}

void routes(Context& context) {
    Fixture fixture(14);
    // Đội 1,2,3; người 3 rớt mạng nên không nhận.
    fixture.make_team({1, 2, 3});
    static_cast<void>(fixture.teams.on_disconnect(kT0, cid(3)));
    ChatResult team = fixture.say(kT0, 2, kTeamChannel, "đội ơi");
    const ChatEvent* team_message = message_of(team);
    context.expect(team.ok() && team_message != nullptr && team_message->audience == ChatAudience::kRecipients &&
                       team_message->recipients == ids_of({1, 2}),
                   "đội: người nhận là thành viên trực tuyến kể cả người nói");
    context.expect(team_message != nullptr && team_message->sender_name == "p2" && team_message->subject == cid(2) && team_message->text == "đội ơi",
                   "tin mang tên và nội dung");
    context.expect(has_error(fixture.say(kT0, 5, kTeamChannel, "x"), ChatError::kNoTeam), "chưa có đội");

    // Bang A: 4 (chủ), 5, 6 (ngoại tuyến); bang B: 8 (chủ), 9; bang C: 10 không liên minh.
    const social::GuildId guild_a = fixture.make_guild(4, "Bang A", {5, 6});
    const social::GuildId guild_b = fixture.make_guild(8, "Bang B", {9});
    static_cast<void>(fixture.make_guild(10, "Bang C", {}));
    fixture.directory.at(6).online = false;
    const ChatResult guild = fixture.say(kT0, 5, kGuildChannel, "bang ơi");
    context.expect(guild.ok() && message_of(guild) != nullptr && message_copy(guild).recipients == ids_of({4, 5}) &&
                       message_copy(guild).guild == guild_a,
                   "bang: thành viên trực tuyến, ngoại tuyến bị bỏ");
    context.expect(has_error(fixture.say(kT0, 7, kGuildChannel, "x"), ChatError::kNoGuild), "chưa vào bang");
    context.expect(has_error(fixture.say(kT0, 10, kLeagueChannel, "x"), ChatError::kNoLeague), "bang chưa vào liên minh");
    context.expect(has_error(fixture.say(kT0, 7, kLeagueChannel, "x"), ChatError::kNoGuild), "liên minh cần có bang");
    context.expect(fixture.guilds.league_create(kT0, cid(4), "Liên Minh", 1'000'000).ok(), "lập liên minh");
    context.expect(fixture.guilds.league_invite(kT0, cid(4), guild_b).ok() && fixture.guilds.league_answer(kT0, cid(8), guild_a, true).ok(),
                   "bang B vào liên minh");
    const ChatResult league = fixture.say(kT0, 9, kLeagueChannel, "liên minh ơi");
    context.expect(league.ok() && message_of(league) != nullptr && message_copy(league).recipients == ids_of({4, 5, 8, 9}),
                   "liên minh: mọi thành viên trực tuyến của các bang theo thứ tự bang rồi thành viên");

    const ChatResult self = fixture.say(kT0, 11, kSelfChannel, "tự nói");
    context.expect(self.ok() && message_of(self) != nullptr && message_copy(self).recipients == ids_of({11}), "kênh tự dùng chỉ về người nói");

    fixture.directory.at(12).scene = social::SceneId{77};
    fixture.directory.at(12).camp = 3;
    fixture.directory.at(12).sect = 4;
    const ChatResult nearby = fixture.say(kT0, 12, kNearby, "gần đây");
    const ChatEvent* near_message = message_of(nearby);
    context.expect(nearby.ok() && near_message != nullptr && near_message->audience == ChatAudience::kNearby &&
                       near_message->recipients.empty() && near_message->scene == social::SceneId{77} && near_message->camp == 3,
                   "kênh cận: world phân phối theo cảnh, tin mang cảnh và phe");
    const ChatResult sect = fixture.say(kT0, 12, kSectChannel, "môn phái");
    context.expect(sect.ok() && message_of(sect) != nullptr && message_copy(sect).audience == ChatAudience::kSect && message_copy(sect).sect == 4,
                   "kênh môn phái mang môn phái người nói");
    fixture.directory.at(13).sect = ids::kSectNone;
    context.expect(has_error(fixture.say(kT0, 13, kSectChannel, "x"), ChatError::kNoSect), "chưa có môn phái");
    const ChatResult help = fixture.say(kT0, 13, kHelpChannel, "giúp với");
    context.expect(help.ok() && message_of(help) != nullptr && message_copy(help).audience == ChatAudience::kEverybody, "kênh trợ giúp: mọi người");
    const ChatResult raid = fixture.say(kT0, 13, kRaidChannel, "đột kích");
    context.expect(raid.ok() && message_of(raid) != nullptr && message_copy(raid).audience == ChatAudience::kExternal &&
                       message_copy(raid).recipients.empty(),
                   "kênh ngoài lõi: world phân phối");
}

void whispers(Context& context) {
    Fixture fixture(8);
    // Mỗi lần gọi cách 100 tick để nhịp (thì thầm: 20 tick, burst 2) không xen vào kết quả cần xem.
    std::uint64_t at = kT0.value();
    const auto next = [&at]() {
        at += 100;
        return Tick{at};
    };
    const ChatResult ok = fixture.whisper(next(), 1, "p2", "chào");
    context.expect(ok.ok() && message_of(ok) != nullptr && message_copy(ok).recipients == ids_of({2}) && message_copy(ok).subject == cid(1),
                   "thì thầm tới đúng một người");
    context.expect(has_error(fixture.whisper(next(), 1, "nobody", "x"), ChatError::kTargetNotFound), "không có người đó");
    context.expect(has_error(fixture.whisper(next(), 1, "", "x"), ChatError::kBadTarget), "tên rỗng");
    context.expect(has_error(fixture.whisper(next(), 1, "p1", "x"), ChatError::kBadTarget), "tự thì thầm");
    context.expect(has_error(fixture.whisper(next(), 1, "p\x01q", "x"), ChatError::kBadTarget), "tên có ký tự điều khiển");
    fixture.directory.at(3).online = false;
    context.expect(has_error(fixture.whisper(next(), 1, "p3", "x"), ChatError::kTargetNotFound), "người nhận ngoại tuyến");
    fixture.directory.at(4).camp = 1;
    fixture.directory.at(1).camp = 2;
    context.expect(has_error(fixture.whisper(next(), 1, "p4", "x"), ChatError::kTargetNotFound), "thù địch xử như không có người đó");
    fixture.directory.at(1).camp = 0;
    // Người nhận chặn người gửi: người gửi thấy ok, không có tin nào đi.
    social::RelationSheet sheet;
    sheet.entries.push_back({.id = cid(1), .name = "p1", .kind = social::RelationKind::kBlack});
    context.expect(fixture.relations.load(cid(5), sheet).has_value(), "nạp sổ có danh sách đen");
    const ChatResult silent = fixture.whisper(next(), 1, "p5", "hello?");
    context.expect(silent.ok() && message_of(silent) == nullptr && silent.events.empty(), "bị chặn: ok nhưng không có tin đi");
    // Cấp tối thiểu của kênh thì thầm là 6.
    fixture.directory.at(6).level = 5;
    context.expect(has_error(fixture.whisper(next(), 6, "p7", "x"), ChatError::kLevelTooLow), "cấp 5 chưa được thì thầm");
    context.expect(fixture.whisper(next(), 7, "p6", "hi").ok(), "người cấp thấp vẫn nhận được thì thầm");
}

void permissions(Context& context) {
    Fixture fixture(6);
    context.expect(has_error(fixture.say(kT0, 1, ChannelId{11}, "x"), ChatError::kUnknownChannel), "kênh không khai báo");
    context.expect(has_error(fixture.say(kT0, 1, kSystemChannel, "x"), ChatError::kServerOnly), "kênh hệ thống");
    context.expect(has_error(fixture.say(kT0, 1, kSceneChannel, "x"), ChatError::kServerOnly), "thông báo cảnh");
    context.expect(has_error(fixture.say(kT0, 1, kUnknownChannel, "x"), ChatError::kServerOnly), "kênh lạ");
    context.expect(has_error(fixture.say(kT0, 99, kNearby, "x"), ChatError::kUnknownPlayer), "người nói không tồn tại");
    fixture.directory.at(2).online = false;
    context.expect(has_error(fixture.say(kT0, 2, kNearby, "x"), ChatError::kUnknownPlayer), "người nói ngoại tuyến");

    // Câm.
    fixture.chat.mute(kT0, cid(3), Tick{5000});
    context.expect(fixture.chat.muted(Tick{4999}, cid(3)) && !fixture.chat.muted(Tick{5000}, cid(3)), "câm hết đúng ở tick 5000");
    context.expect(has_error(fixture.say(Tick{4500}, 3, kNearby, "x"), ChatError::kMuted), "đang bị câm");
    context.expect(fixture.say(Tick{5000}, 3, kNearby, "x").ok(), "hết câm gửi được");
    fixture.chat.mute(Tick{5100}, cid(3), Tick{9000});
    fixture.chat.mute(Tick{5200}, cid(3), Tick{5200});
    context.expect(!fixture.chat.muted(Tick{5300}, cid(3)), "mute với until <= now là bỏ câm");

    // Cấp tối thiểu của kênh thế giới là 15.
    fixture.directory.at(4).level = 14;
    context.expect(has_error(fixture.say(kT0, 4, kWorldChannel, "x"), ChatError::kLevelTooLow), "cấp 14 chưa chat thế giới");
    fixture.directory.at(4).level = 15;
    const ChatResult world = fixture.say(kT0, 4, kWorldChannel, "thế giới ơi");
    context.expect(world.ok() && charges_of(world) == 2, "chat thế giới sinh hai sự kiện trừ tài nguyên");
    context.expect(world.events.size() == 3 && world.events.at(0).kind == ChatEventKind::kCharge &&
                       world.events.at(0).resource == ChatResource::kEnergy && world.events.at(0).amount == 2 &&
                       world.events.at(0).subject == cid(4) && world.events.at(1).resource == ChatResource::kVigor &&
                       world.events.at(2).kind == ChatEventKind::kMessage,
                   "thứ tự: trừ tinh lực, trừ hoạt lực, rồi mới tới tin");
    // Thiếu tài nguyên: lỗi, không trừ, không tính nhịp.
    SendRequest poor = make_request(cid(5), kWorldChannel, "nghèo");
    poor.wallet = {100, 1, 100};
    context.expect(has_error(fixture.chat.send(kT0, fixture.world(), poor), ChatError::kNoResource), "thiếu tinh lực");
    poor.wallet = {100, 100, 1};
    context.expect(has_error(fixture.chat.send(kT0, fixture.world(), poor), ChatError::kNoResource), "thiếu hoạt lực");
    poor.wallet = {100, 2, 2};
    context.expect(fixture.chat.send(kT0, fixture.world(), poor).ok(), "đủ vừa khít thì gửi được và nhịp chưa bị lỗi trước đó tiêu");
    // Loa: 7 MP.
    SendRequest horn = make_request(cid(6), kHornChannel, "loa");
    horn.wallet = {6, 0, 0};
    context.expect(has_error(fixture.chat.send(kT0, fixture.world(), horn), ChatError::kNoResource), "6 MP chưa đủ 7");
    horn.wallet = {7, 0, 0};
    const ChatResult horn_ok = fixture.chat.send(kT0, fixture.world(), horn);
    context.expect(horn_ok.ok() && charges_of(horn_ok) == 1 && horn_ok.events.at(0).resource == ChatResource::kMp && horn_ok.events.at(0).amount == 7,
                   "loa trừ 7 MP");
    const auto* horn_info = fixture.chat.catalog().find(kHornChannel);
    context.expect(horn_info != nullptr && horn_info->needs_item, "world biết loa cần vật phẩm");
}

void text_rules(Context& context) {
    Fixture fixture(2);
    Tick now = kT0;
    const auto next = [&now]() { now = social::Tick{now.value() + 100}; return now; };
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, ""), ChatError::kEmpty), "rỗng");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, "     "), ChatError::kEmpty), "toàn dấu cách");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, "a\nb"), ChatError::kBadText), "xuống dòng thô");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, "a\x01" "b"), ChatError::kBadText), "ký tự điều khiển");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, "\xff\xfe"), ChatError::kBadText), "UTF-8 hỏng");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, "\xED\xA0\x80"), ChatError::kBadText), "nửa thay thế UTF-16");
    context.expect(has_error(fixture.say(next(), 1, kHornChannel, std::string(256, 'a')), ChatError::kTooLong), "256 byte quá dài");
    const ChatResult edge = fixture.say(next(), 1, kHornChannel, std::string(255, 'a'));
    context.expect(edge.ok() && message_of(edge) != nullptr && message_copy(edge).text.size() == 255, "255 byte vừa đủ");
    // Che chữ cấm.
    const ChatResult banned = fixture.say(next(), 1, kHornChannel, "江泽民 và fuck");
    context.expect(banned.ok() && message_of(banned) != nullptr && message_copy(banned).text == "*** và ****", "chữ cấm bị che bằng '*'");
    // Vô hiệu token: '%' -> '?', "#{" -> "##{".
    const ChatResult tokens = fixture.say(next(), 1, kHornChannel, "50% #{_MONEY99} ##{x} ###{y} # #");
    context.expect(tokens.ok() && message_of(tokens) != nullptr && message_copy(tokens).text == "50? ##{_MONEY99} ##{x} ####{y} # #",
                   "token bị vô hiệu đúng quy tắc cặp '#'");
    const ChatResult color = fixture.say(next(), 1, kHornChannel, "#R đỏ #cFF0000 #aB{x}link#aE");
    context.expect(color.ok() && message_of(color) != nullptr && message_copy(color).text == "#R đỏ #cFF0000 #aB{x}link#aE",
                   "màu và liên kết vật phẩm của người chơi vẫn đi (chỉ #{ bị chặn)");
    // Số thứ tự tăng dần theo từng tin được phát.
    const ChatResult first = fixture.say(next(), 1, kHornChannel, "một");
    const ChatResult second = fixture.say(next(), 1, kHornChannel, "hai");
    context.expect(message_of(first) != nullptr && message_of(second) != nullptr && message_copy(second).serial == message_copy(first).serial + 1,
                   "serial liên tiếp");
    // Tin bị từ chối không tốn serial.
    const std::uint64_t before = message_copy(second).serial;
    context.expect(!fixture.say(next(), 1, kHornChannel, "").ok(), "tin rỗng bị từ chối");
    const ChatResult third = fixture.say(next(), 1, kHornChannel, "ba");
    context.expect(message_of(third) != nullptr && message_copy(third).serial == before + 1, "từ chối không đốt serial");
}

void rate_limits(Context& context) {
    Fixture fixture(4);
    // Kênh cận: giãn cách 3000 ms = 60 tick, burst 2. Hai tin liền, tin thứ ba phải chờ.
    context.expect(fixture.say(Tick{1000}, 1, kNearby, "a1").ok(), "tin 1 lúc 1000");
    context.expect(fixture.say(Tick{1000}, 1, kNearby, "a2").ok(), "tin 2 lúc 1000 (burst 2)");
    context.expect(has_error(fixture.say(Tick{1000}, 1, kNearby, "a3"), ChatError::kRateLimited), "tin 3 lúc 1000 vượt burst");
    context.expect(has_error(fixture.say(Tick{1059}, 1, kNearby, "a4"), ChatError::kRateLimited), "1059 vẫn chưa tới hạn (mốc 1120 - 60)");
    context.expect(fixture.say(Tick{1060}, 1, kNearby, "a5").ok(), "1060 được thêm một tin");
    context.expect(has_error(fixture.say(Tick{1060}, 1, kNearby, "a6"), ChatError::kRateLimited), "lại hết chỗ");
    context.expect(fixture.say(Tick{1120}, 1, kNearby, "a7").ok(), "1120 được tiếp");
    // Người khác không bị ảnh hưởng.
    context.expect(fixture.say(Tick{1000}, 2, kNearby, "b1").ok(), "nhịp tách theo người");
    // Nhịp chung: 500 ms = 10 tick, burst 4, trên các kênh khác nhau.
    context.expect(fixture.say(Tick{2000}, 3, kNearby, "c0").ok(), "kênh cận");
    context.expect(fixture.say(Tick{2000}, 3, kSelfChannel, "c1").ok(), "kênh tự dùng");
    context.expect(fixture.say(Tick{2000}, 3, kHelpChannel, "c2").ok(), "kênh trợ giúp");
    context.expect(fixture.say(Tick{2000}, 3, kHornChannel, "c3").ok(), "kênh loa (không giãn cách riêng)");
    context.expect(has_error(fixture.say(Tick{2000}, 3, kRecruitChannel, "c4"), ChatError::kFlood), "tin thứ năm vượt nhịp chung");
    context.expect(fixture.say(Tick{2010}, 3, kRecruitChannel, "c4").ok(),
                   "bị từ chối vì nhịp chung không tiêu token của kênh: 10 tick sau gửi được ngay");
    // Kênh loa không có giãn cách riêng nhưng vẫn chịu nhịp chung.
    context.expect(has_error(fixture.say(Tick{2010}, 3, kHornChannel, "h7"), ChatError::kFlood), "loa vẫn chịu nhịp chung");
    context.expect(fixture.say(Tick{2020}, 3, kRecruitChannel, "c5").ok(), "burst 2 của kênh tuyển người: tin thứ hai được ngay");
    context.expect(has_error(fixture.say(Tick{2030}, 3, kRecruitChannel, "c6"), ChatError::kRateLimited),
                   "kênh tuyển người giãn cách 3600 tick nên tin thứ ba bị chặn bởi kênh");
}

void repetition(Context& context) {
    Fixture fixture(12);
    // Cửa sổ 30 giây = 600 tick, tối đa 2 lần.
    context.expect(fixture.say(Tick{3000}, 3, kHornChannel, "Hello").ok(), "lần 1");
    context.expect(fixture.say(Tick{3010}, 3, kHornChannel, "HELLO ").ok(), "lần 2 (khác hoa/thường và dấu cách vẫn cùng nội dung)");
    context.expect(has_error(fixture.say(Tick{3020}, 3, kHornChannel, "h e l l o"), ChatError::kRepeated), "lần 3 trong cửa sổ bị chặn");
    context.expect(fixture.say(Tick{3030}, 3, kHornChannel, "bye").ok(), "nội dung khác gửi được");
    context.expect(fixture.say(Tick{3600}, 3, kHornChannel, "hello").ok(), "lần cũ nhất đã hết hạn nên được gửi lại");
    context.expect(has_error(fixture.say(Tick{3605}, 3, kHornChannel, "hello"), ChatError::kRepeated), "lại thành 2 lần trong cửa sổ");
    context.expect(fixture.say(Tick{3620}, 3, kHornChannel, "hello").ok(), "lần ở 3010 hết hạn lúc 3610");
    // Thì thầm cùng câu cho người khác nhau không tính là lặp.
    context.expect(fixture.whisper(Tick{4100}, 4, "p10", "chúc mừng năm mới").ok(), "gửi p10");
    context.expect(fixture.whisper(Tick{4120}, 4, "p11", "chúc mừng năm mới").ok(), "gửi p11");
    context.expect(fixture.whisper(Tick{4140}, 4, "p12", "chúc mừng năm mới").ok(), "gửi p12");
    context.expect(fixture.whisper(Tick{4160}, 4, "p10", "chúc mừng năm mới").ok(), "gửi lại p10 lần 2");
    context.expect(has_error(fixture.whisper(Tick{4180}, 4, "p10", "chúc mừng năm mới"), ChatError::kRepeated), "p10 lần 3");
    // Tin bị từ chối vì lặp không được ghi nhận thêm nên vẫn lặp ở lần sau, không tự "lăn" ra ngoài cửa sổ.
    context.expect(has_error(fixture.whisper(Tick{4200}, 4, "p10", "chúc mừng năm mới"), ChatError::kRepeated), "vẫn lặp");
}

void custom_channels(Context& context) {
    social::Limits limits = sample_limits();
    limits.chat_max_custom_channels = 3;
    limits.chat_custom_channel_members = 4;
    Fixture fixture(12, limits);
    const auto created = fixture.chat.create_channel(fixture.directory, cid(1));
    context.expect(created.ok() && created.events.size() == 1 && created.events.front().kind == ChatEventKind::kChannelCreated &&
                       created.events.front().recipients == ids_of({1}),
                   "lập kênh");
    const CustomChannelId channel = created.events.front().custom;
    context.expect(channel.value() == 1, "id kênh đầu là 1");
    context.expect(has_error(fixture.chat.create_channel(fixture.directory, cid(1)), ChatError::kHasChannel), "mỗi người một kênh");
    context.expect(has_error(fixture.chat.create_channel(fixture.directory, cid(99)), ChatError::kUnknownPlayer), "người lạ không lập được");
    context.expect(fixture.chat.validate().has_value(), "bất biến sau khi lập");

    // Mời.
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(1)), ChatError::kBadTarget), "tự mời");
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(99)), ChatError::kTargetNotFound), "mời người lạ");
    fixture.directory.at(5).online = false;
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(5)), ChatError::kTargetNotFound), "mời người ngoại tuyến");
    fixture.directory.at(6).camp = 1;
    fixture.directory.at(1).camp = 2;
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(6)), ChatError::kHostile), "mời người thuộc phe địch");
    fixture.directory.at(1).camp = 0;
    const auto invited = fixture.chat.invite(fixture.directory, cid(1), cid(2));
    context.expect(invited.ok() && invited.events.front().kind == ChatEventKind::kChannelMember && invited.events.front().subject == cid(2) &&
                       invited.events.front().recipients == ids_of({1, 2}),
                   "mời người 2: thông báo cho mọi thành viên gồm người mới");
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(2)), ChatError::kAlreadyMember), "đã là thành viên");
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(2), cid(3)), ChatError::kNotOwner), "thành viên không mời được");
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(7), cid(3)), ChatError::kNoSuchChannel), "người ngoài không có kênh");
    context.expect(fixture.chat.invite(fixture.directory, cid(1), cid(3)).ok() && fixture.chat.invite(fixture.directory, cid(1), cid(4)).ok(),
                   "mời tiếp 3 và 4 (đủ 4 người)");
    context.expect(has_error(fixture.chat.invite(fixture.directory, cid(1), cid(8)), ChatError::kChannelFull), "kênh đã đủ người");
    context.expect(fixture.chat.validate().has_value(), "bất biến khi đầy");

    // Gửi vào kênh.
    const ChatResult said = fixture.say_custom(kT0, 2, channel, "chào kênh");
    context.expect(said.ok() && message_of(said) != nullptr && message_copy(said).recipients == ids_of({1, 2, 3, 4}) &&
                       message_copy(said).custom == channel && message_copy(said).audience == ChatAudience::kRecipients,
                   "tin tới mọi thành viên trực tuyến");
    context.expect(has_error(fixture.say_custom(kT0, 9, channel, "lạ"), ChatError::kNotInChannel), "người ngoài không nói được");
    context.expect(has_error(fixture.say_custom(kT0, 2, CustomChannelId{42}, "x"), ChatError::kNoSuchChannel), "kênh không tồn tại");
    fixture.directory.at(3).online = false;
    const ChatResult partial = fixture.say_custom(Tick{1200}, 2, channel, "ai còn đó");
    context.expect(partial.ok() && message_of(partial) != nullptr && message_copy(partial).recipients == ids_of({1, 2, 4}), "bỏ thành viên ngoại tuyến");
    fixture.directory.at(3).online = true;

    // Đuổi, rời, giải tán.
    context.expect(has_error(fixture.chat.kick(cid(2), cid(3)), ChatError::kNotOwner), "thành viên không đuổi được");
    context.expect(has_error(fixture.chat.kick(cid(1), cid(1)), ChatError::kBadTarget), "chủ không tự đuổi mình");
    context.expect(has_error(fixture.chat.kick(cid(1), cid(9)), ChatError::kNotInChannel), "đuổi người không ở trong kênh");
    const auto kicked = fixture.chat.kick(cid(1), cid(3));
    context.expect(kicked.ok() && kicked.events.front().kind == ChatEventKind::kChannelKicked && kicked.events.front().recipients == ids_of({1, 2, 3, 4}),
                   "đuổi 3: thông báo cho mọi thành viên trước khi đuổi");
    context.expect(has_error(fixture.say_custom(Tick{1300}, 3, channel, "x"), ChatError::kNotInChannel), "bị đuổi thì không nói được");
    const auto left = fixture.chat.leave(cid(4), channel);
    context.expect(left.ok() && left.events.front().kind == ChatEventKind::kChannelLeft && left.events.front().recipients == ids_of({1, 2, 4}),
                   "4 rời: thông báo cho thành viên còn lại và người rời");
    context.expect(has_error(fixture.chat.leave(cid(4), channel), ChatError::kNotInChannel), "rời hai lần");
    context.expect(has_error(fixture.chat.leave(cid(4), CustomChannelId{9}), ChatError::kNoSuchChannel), "rời kênh không tồn tại");
    context.expect(fixture.chat.validate().has_value(), "bất biến sau đuổi và rời");

    // Trần số kênh: 3.
    context.expect(fixture.chat.create_channel(fixture.directory, cid(7)).ok() && fixture.chat.create_channel(fixture.directory, cid(8)).ok(),
                   "lập thêm hai kênh");
    context.expect(has_error(fixture.chat.create_channel(fixture.directory, cid(9)), ChatError::kTooManyChannels), "đủ ba kênh");
    const auto dismissed = fixture.chat.dismiss(cid(1));
    context.expect(dismissed.ok() && dismissed.events.front().kind == ChatEventKind::kChannelDismissed && dismissed.events.front().recipients == ids_of({1, 2}),
                   "giải tán: thông báo mọi thành viên còn lại");
    context.expect(has_error(fixture.chat.dismiss(cid(1)), ChatError::kNoSuchChannel), "giải tán hai lần");
    context.expect(has_error(fixture.say_custom(Tick{1400}, 2, channel, "x"), ChatError::kNoSuchChannel), "kênh đã mất");
    const auto again = fixture.chat.create_channel(fixture.directory, cid(9));
    context.expect(again.ok() && again.events.front().custom.value() == 4, "id không được dùng lại");

    // Rời mạng: chủ giải tán, thành viên thoát.
    context.expect(fixture.chat.invite(fixture.directory, cid(7), cid(10)).ok() && fixture.chat.invite(fixture.directory, cid(7), cid(11)).ok(), "kênh của 7");
    const auto member_out = fixture.chat.on_logout(cid(10));
    context.expect(member_out.size() == 1 && member_out.front().kind == ChatEventKind::kChannelLeft && member_out.front().recipients == ids_of({7, 11}),
                   "thành viên rớt mạng ra khỏi kênh");
    const auto owner_out = fixture.chat.on_logout(cid(7));
    context.expect(owner_out.size() == 1 && owner_out.front().kind == ChatEventKind::kChannelDismissed && owner_out.front().recipients == ids_of({7, 11}),
                   "chủ rớt mạng thì kênh giải tán");
    context.expect(fixture.chat.on_logout(cid(12)).empty(), "người không dính kênh nào");
    context.expect(fixture.chat.validate().has_value(), "bất biến sau rớt mạng");
}

void maintenance(Context& context) {
    Fixture fixture(4);
    for (std::uint64_t who = 1; who <= 3; ++who) context.expect(fixture.say(Tick{100}, who, kNearby, "hi").ok(), "mỗi người nói một câu");
    context.expect(fixture.chat.speaker_count() == 3, "ba người có trạng thái nhịp");
    fixture.chat.tick(Tick{200});
    context.expect(fixture.chat.speaker_count() == 3, "còn trong cửa sổ chống lặp thì giữ");
    fixture.chat.tick(Tick{721});
    context.expect(fixture.chat.speaker_count() == 3, "tick không chia hết cho 20 thì không dọn");
    fixture.chat.tick(Tick{720});
    context.expect(fixture.chat.speaker_count() == 0, "hết cửa sổ và hết nhịp thì dọn sạch");
    // Dọn không làm mất giới hạn: nhịp tiếp tục đúng sau khi dọn.
    context.expect(fixture.say(Tick{800}, 1, kNearby, "again").ok(), "gửi lại sau khi dọn");
    // Câm hết hạn bị dọn.
    fixture.chat.mute(Tick{800}, cid(2), Tick{900});
    fixture.chat.tick(Tick{900});
    context.expect(!fixture.chat.muted(Tick{900}, cid(2)), "câm đã hết");
}

void announcements(Context& context) {
    Fixture fixture(2);
    const ChatResult system = fixture.chat.announce(kSystemChannel, "Chào mừng đến Thiên Long");
    const ChatEvent* message = message_of(system);
    context.expect(system.ok() && message != nullptr && message->audience == ChatAudience::kEverybody && message->subject == social::CharacterId{} &&
                       message->text == "Chào mừng đến Thiên Long" && message->serial == 1,
                   "thông báo hệ thống tới mọi người, không có người nói");
    const ChatResult scene = fixture.chat.announce(kSceneChannel, "Bão cát", {}, social::SceneId{9});
    const ChatEvent* scene_message = message_of(scene);
    context.expect(scene.ok() && scene_message != nullptr && scene_message->audience == ChatAudience::kNearby &&
                       scene_message->scene == social::SceneId{9} && scene_message->serial == 2,
                   "thông báo cảnh mang số cảnh");
    const ChatResult team = fixture.chat.announce(kTeamChannel, "Đội trưởng đã đổi", ids_of({1, 2}));
    const ChatEvent* team_message = message_of(team);
    context.expect(team.ok() && team_message != nullptr && team_message->recipients == ids_of({1, 2}), "kênh có người nhận rõ thì giữ danh sách");
    const ChatResult world = fixture.chat.announce(kWorldChannel, "x", ids_of({1}));
    const ChatEvent* world_message = message_of(world);
    context.expect(world.ok() && world_message != nullptr && world_message->recipients.empty(), "kênh phát rộng bỏ danh sách người nhận");
    context.expect(has_error(fixture.chat.announce(ChannelId{11}, "x"), ChatError::kUnknownChannel), "kênh không khai báo");
    context.expect(has_error(fixture.chat.announce(kSystemChannel, "\xff"), ChatError::kBadText), "UTF-8 hỏng");
    context.expect(has_error(fixture.chat.announce(kSystemChannel, ""), ChatError::kEmpty), "rỗng");
    context.expect(has_error(fixture.chat.announce(kSystemChannel, std::string(4097, 'a')), ChatError::kTooLong), "quá 4096 byte");
}

// ----- kịch bản hạt giống cố định ------------------------------------------------------------------------------------

struct PoolEntry {
    std::string_view input;
    std::string_view expected;
};

constexpr std::array kPool{
    PoolEntry{.input = "hello world", .expected = "hello world"},
    PoolEntry{.input = "江泽民 xin chào", .expected = "*** xin chào"},
    PoolEntry{.input = "50% off", .expected = "50? off"},
    PoolEntry{.input = "see #{_MONEY99}", .expected = "see ##{_MONEY99}"},
    PoolEntry{.input = "fuck you", .expected = "**** you"},
    PoolEntry{.input = "abc", .expected = "abc"},
    PoolEntry{.input = "你好 sb", .expected = "你好 **"},
    PoolEntry{.input = "Ｈｅｌｌｏ", .expected = "Ｈｅｌｌｏ"},
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07), hàm ngầm định của std::map
struct ScriptOutcome {
    std::uint64_t hash = 0xCBF29CE484222325ULL;
    std::map<ChatError, std::size_t> errors;
    std::size_t accepted = 0;
    std::size_t wrong_text = 0;
    std::size_t charges = 0;
    std::size_t world_accepted = 0;
    std::size_t horn_accepted = 0;
    std::uint64_t last_serial = 0;
    bool serial_gap = false;
    std::map<std::pair<std::uint64_t, std::uint8_t>, std::vector<std::uint64_t>> by_channel;  // (người, kênh) -> tick được nhận
    std::map<std::uint64_t, std::vector<std::uint64_t>> by_player;
};

void mix(std::uint64_t& hash, std::uint64_t value) {
    hash = (hash ^ value) * 0x100000001B3ULL;
}

ScriptOutcome run_script(std::uint64_t seed) {
    Fixture fixture(6);
    fixture.directory.at(6).level = 10;  // dưới cấp 15 của kênh thế giới
    constexpr std::array<ChannelId, 6> kChannelsUsed{kNearby, kWorldChannel, kSelfChannel, kHelpChannel, kHornChannel, kRecruitChannel};
    SplitMix rng{seed};
    ScriptOutcome out;
    std::uint64_t now = 100;
    for (std::size_t step = 0; step < 6000; ++step) {
        now += rng.below(4);
        const std::uint64_t who = 1 + rng.below(6);
        const ChannelId channel = kChannelsUsed.at(rng.below(kChannelsUsed.size()));
        const std::size_t pick = rng.below(kPool.size());
        const ChatResult result = fixture.say(Tick{now}, who, channel, kPool.at(pick).input);
        if (result.error) {
            ++out.errors[*result.error];
            mix(out.hash, 1000 + static_cast<std::uint64_t>(*result.error));
            continue;
        }
        ++out.accepted;
        const ChatEvent* message = message_of(result);
        if (message == nullptr) continue;
        if (message->text != kPool.at(pick).expected) ++out.wrong_text;
        if (out.last_serial != 0 && message->serial != out.last_serial + 1) out.serial_gap = true;
        out.last_serial = message->serial;
        out.charges += charges_of(result);
        if (channel == kWorldChannel) ++out.world_accepted;
        if (channel == kHornChannel) ++out.horn_accepted;
        out.by_channel[{who, channel.value()}].push_back(now);
        out.by_player[who].push_back(now);
        for (const char c : message->text) mix(out.hash, static_cast<std::uint8_t>(c));
        mix(out.hash, message->serial);
    }
    return out;
}

// Tính chất của leaky bucket (GCRA) với burst b và khoảng I: trong dãy các tick được nhận t_0 <= t_1 <= ...,
// với mọi m >= b thì t_{i+m} - t_i >= (m - b + 1) * I. Tính chất này đủ để chặn mọi tốc độ vượt trần.
bool conforms(const std::vector<std::uint64_t>& times, std::uint64_t burst, std::uint64_t interval) {
    for (std::size_t from = 0; from < times.size(); ++from) {
        for (std::size_t span = burst; from + span < times.size(); ++span) {
            if (times.at(from + span) - times.at(from) < ((span - burst) + 1) * interval) return false;
        }
    }
    return true;
}

void seeded_script(Context& context) {
    const ScriptOutcome first = run_script(20261014);
    const ScriptOutcome second = run_script(20261014);
    context.expect(first.hash == second.hash && first.accepted == second.accepted, "cùng hạt giống cho cùng kết quả (tất định)");
    const ScriptOutcome other = run_script(7);
    context.expect(other.hash != first.hash, "hạt giống khác cho kết quả khác");
    context.expect(first.accepted > 300, "kịch bản có đủ tin được nhận để các kiểm tra bên dưới có nghĩa");
    context.expect(first.wrong_text == 0, "mọi tin được nhận có nội dung đúng bảng vàng (đã che chữ cấm, vô hiệu token)");
    context.expect(!first.serial_gap && first.last_serial == first.accepted, "serial liên tiếp từ 1, mỗi tin được nhận đúng một số");
    context.expect(first.charges == first.world_accepted * 2 + first.horn_accepted, "mỗi tin kênh thế giới trừ hai khoản, mỗi tin loa trừ một");
    context.expect(first.errors.contains(ChatError::kRateLimited) && first.errors.contains(ChatError::kFlood) &&
                       first.errors.contains(ChatError::kRepeated) && first.errors.contains(ChatError::kLevelTooLow),
                   "kịch bản đã chạm đủ bốn loại giới hạn");
    // Nhịp theo từng kênh: burst 2, khoảng giãn cách theo bảng (đổi từ mili giây ra tick).
    struct ChannelInterval {
        std::uint8_t channel;
        std::uint64_t ticks;
    };
    constexpr std::array kIntervals{ChannelInterval{.channel = 0, .ticks = 60}, ChannelInterval{.channel = 2, .ticks = 3600},
                                    ChannelInterval{.channel = 8, .ticks = 60}, ChannelInterval{.channel = 9, .ticks = 60},
                                    ChannelInterval{.channel = 18, .ticks = 3600}};
    bool channels_conform = true;
    for (const auto& [key, times] : first.by_channel) {
        for (const ChannelInterval& each : kIntervals) {
            if (key.second == each.channel) channels_conform = channels_conform && conforms(times, 2, each.ticks);
        }
    }
    context.expect(channels_conform, "nhịp từng kênh tuân theo leaky bucket burst 2");
    bool global_conform = true;
    for (const auto& [who, times] : first.by_player) global_conform = global_conform && conforms(times, 4, 10);
    context.expect(global_conform, "nhịp chung tuân theo leaky bucket burst 4, khoảng 10 tick");
}

constexpr std::array kCases{
    Case{.name = "catalog_parse", .body = catalog_parse},
    Case{.name = "routes", .body = routes},
    Case{.name = "whispers", .body = whispers},
    Case{.name = "permissions", .body = permissions},
    Case{.name = "text_rules", .body = text_rules},
    Case{.name = "rate_limits", .body = rate_limits},
    Case{.name = "repetition", .body = repetition},
    Case{.name = "custom_channels", .body = custom_channels},
    Case{.name = "maintenance", .body = maintenance},
    Case{.name = "announcements", .body = announcements},
    Case{.name = "seeded_script", .body = seeded_script},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
