// Bang hội: lập, xin vào, quyền theo chức, hạn ngạch chức vị, nhường chức, giải tán, quỹ, bang chiến,
// liên minh và khối lưu bền. Sai thì hỏng thầm (hai chủ bang, thành viên ở hai bang, tiền biến mất), nên
// mỗi ca gọi validate() sau chuỗi thao tác.
#include "ids/ids.hpp"
#include "social/codec.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using social::Guild;
using social::GuildBook;
using social::GuildError;
using social::GuildEvent;
using social::GuildEventKind;
using social::GuildPosition;
using social::GuildResult;
using social::GuildId;
using social::Tick;

constexpr Tick kNow{1000};

class DenyBad final : public social::TextPolicy {
public:
    [[nodiscard]] bool allowed(std::string_view text) const override { return text.find("bad") == std::string_view::npos; }
};

[[nodiscard]] const GuildEvent* first_kind(const std::vector<GuildEvent>& events, GuildEventKind kind) {
    const auto found = std::ranges::find_if(events, [kind](const GuildEvent& event) { return event.kind == kind; });
    return found == events.end() ? nullptr : &*found;
}

struct World {
    FakeDirectory directory;
    DenyBad policy;
    GuildBook book;

    explicit World(std::uint64_t players, social::Limits limits = sample_limits(), social::GuildRules rules = sample_guild_rules())
        : book(limits, rules, policy) {
        for (std::uint64_t id = 1; id <= players; ++id) directory.add(id, "p" + std::to_string(id), 50);
    }

    // Người 1 lập bang "Thiên Long", người 2..count vào bang làm thành viên.
    GuildId found(std::uint64_t count, std::string_view name = "Thiên Long") {
        const GuildResult made = book.create(kNow, directory, cid(1), name, "tông chỉ", 1'000'000);
        if (!made.ok()) return GuildId{};
        const GuildId id = made.events.front().guild;
        for (std::uint64_t who = 2; who <= count; ++who) {
            if (!book.apply(kNow, directory, cid(who), id).ok()) return GuildId{};
            if (!book.answer_application(kNow, directory, cid(1), cid(who), true).ok()) return GuildId{};
        }
        return id;
    }
};

[[nodiscard]] GuildId guild_id(const GuildBook& book, std::uint64_t who) {
    return book.guild_of(cid(who)).value_or(GuildId{});
}

void expect_valid(Context& context, const GuildBook& book) {
    const auto checked = book.validate();
    context.expect(checked.has_value(), "validate() đạt");
}

void create_rules(Context& context) {
    World world(6);
    world.directory.at(2).level = 39;
    context.expect(world.book.create(kNow, world.directory, cid(2), "Thiên Long", "", 1'000'000).error == GuildError::kLevelTooLow, "cấp 39");
    context.expect(world.book.create(kNow, world.directory, cid(99), "Thiên Long", "", 1'000'000).error == GuildError::kUnknownPlayer, "id lạ");
    const auto make = [&world](std::string_view name, std::string_view desc, social::Copper wallet) {
        return world.book.create(kNow, world.directory, cid(1), name, desc, wallet).error;
    };
    context.expect(make("", "", 1'000'000) == GuildError::kInvalidName, "tên rỗng");
    context.expect(make("1234567890123", "", 1'000'000) == GuildError::kInvalidName, "13 byte");
    context.expect(make("A", "", 1'000'000) == GuildError::kInvalidName, "một điểm mã");
    context.expect(make("ab\ncd", "", 1'000'000) == GuildError::kInvalidName, "ký tự điều khiển");
    context.expect(make(" ab", "", 1'000'000) == GuildError::kInvalidName, "dấu cách đầu");
    context.expect(make("ab ", "", 1'000'000) == GuildError::kInvalidName, "dấu cách cuối");
    context.expect(make(std::string_view("\xC3\x28", 2), "", 1'000'000) == GuildError::kInvalidName, "UTF-8 hỏng");
    context.expect(make("abad", "", 1'000'000) == GuildError::kInvalidName, "bộ lọc chữ cấm");
    context.expect(make("Rồng", std::string(51, 'a'), 1'000'000) == GuildError::kBadText, "tông chỉ 51 byte");
    context.expect(make("Rồng", "bad", 1'000'000) == GuildError::kBadText, "tông chỉ bị lọc");
    context.expect(make("Rồng", "", 499'999) == GuildError::kNotEnoughMoney, "thiếu 1 đồng");
    context.expect(world.book.guild_count() == 0, "lỗi thì không lập bang");
    const GuildResult ok = world.book.create(kNow, world.directory, cid(1), "Rồng", "", 500'000);
    context.expect(ok.ok() && ok.events[0].value == 500'000, "đúng 50 vàng: trừ 500000 đồng");
    context.expect(make("Rồng 2", "", 1'000'000) == GuildError::kInGuild, "đã ở bang");
    context.expect(world.book.create(kNow, world.directory, cid(3), "rồng", "", 1'000'000).error == GuildError::kDuplicateName,
        "trùng tên không phân biệt hoa thường ASCII");
    // Chữ hoa có dấu không được gập (giới hạn đã ghi ở docs/SERVER-SOCIAL.md): "RỒNG" là tên khác.
    context.expect(world.book.create(kNow, world.directory, cid(3), "RỒNG", "", 1'000'000).ok(), "RỒNG khác rồng");
    const Guild* found = world.book.find_by_name("rồng");
    context.expect(found != nullptr && found->members.size() == 1 && found->members[0].position == GuildPosition::kChief, "chủ bang là người lập");
    context.expect(found->members[0].access == 0x37F, "bang chủ giữ đủ quyền (0x17F và quyền sửa tông chỉ)");
    expect_valid(context, world.book);
}

void guild_count_cap(Context& context) {
    social::Limits limits = sample_limits();
    limits.guild_max_guilds = 2;
    World world(4, limits);
    context.expect(world.book.create(kNow, world.directory, cid(1), "aa", "", 1'000'000).ok(), "bang 1");
    context.expect(world.book.create(kNow, world.directory, cid(2), "bb", "", 1'000'000).ok(), "bang 2");
    context.expect(world.book.create(kNow, world.directory, cid(3), "cc", "", 1'000'000).error == GuildError::kGuildFull, "đủ bang");
    context.expect(world.book.dismiss(cid(2)).ok(), "giải tán bang 2");
    context.expect(world.book.create(kNow, world.directory, cid(3), "cc", "", 1'000'000).ok(), "lập lại được");
    expect_valid(context, world.book);
}

void apply_and_recruit(Context& context) {
    World world(14);
    const GuildId id = world.found(2);
    context.expect(id.value() != 0, "dựng bang");
    context.expect(world.book.apply(kNow, world.directory, cid(3), GuildId{99}).error == GuildError::kNotExist, "bang không có");
    context.expect(world.book.apply(kNow, world.directory, cid(2), id).error == GuildError::kInGuild, "đã ở bang");
    const GuildResult applied = world.book.apply(kNow, world.directory, cid(3), id);
    context.expect(applied.ok() && applied.events[0].audience.size() >= 1, "xin vào");
    context.expect(world.book.apply(kNow, world.directory, cid(3), id).error == GuildError::kAlreadyProposer, "xin hai lần");
    // Thành viên thường không có quyền nhận người.
    context.expect(world.book.answer_application(kNow, world.directory, cid(2), cid(3), true).error == GuildError::kUnauthorized, "thành viên không có quyền nhận");
    context.expect(world.book.answer_application(kNow, world.directory, cid(1), cid(9), true).error == GuildError::kNoPending, "không có đơn của người 9");
    const GuildResult rejected = world.book.answer_application(kNow, world.directory, cid(1), cid(3), false);
    context.expect(rejected.ok() && first_kind(rejected.events, GuildEventKind::kApplyRejected) != nullptr, "từ chối đơn");
    context.expect(!world.book.proposer_guild_of(cid(3)).has_value() && !world.book.guild_of(cid(3)).has_value(), "không vào bang");
    // Đơn có hạn.
    context.expect(world.book.apply(kNow, world.directory, cid(4), id).ok(), "xin");
    const Tick late = ids::advance(kNow, ids::TickSpan{259'200LL * 20});
    const auto expired = world.book.tick(late);
    context.expect(first_kind(expired, GuildEventKind::kApplyRejected) != nullptr && !world.book.proposer_guild_of(cid(4)).has_value(), "đơn hết hạn");
    context.expect(world.book.answer_application(late, world.directory, cid(1), cid(4), true).error == GuildError::kNoPending, "trả lời đơn hết hạn");
    // Chặn tối đa 10 đơn chờ.
    for (std::uint64_t who = 3; who <= 12; ++who) {
        context.expect(world.book.apply(kNow, world.directory, cid(who), id).ok(), "đơn trong trần");
    }
    context.expect(world.book.apply(kNow, world.directory, cid(13), id).error == GuildError::kProposerFull, "đủ 10 đơn chờ");
    // Nhận người: bị đuổi khỏi danh sách đơn khi đã vào.
    const GuildResult joined = world.book.answer_application(kNow, world.directory, cid(1), cid(3), true);
    context.expect(joined.ok() && joined.events[0].audience.size() == 3, "nhận người");
    context.expect(world.book.guild_of(cid(3)) == id && !world.book.proposer_guild_of(cid(3)).has_value(), "chỉ mục chuyển từ đơn sang thành viên");
    context.expect(world.book.cancel_application(cid(5)).ok() && world.book.cancel_application(cid(5)).error == GuildError::kNoPending, "huỷ đơn");
    expect_valid(context, world.book);
}

void camp_and_member_cap(Context& context) {
    social::GuildRules rules = sample_guild_rules();
    rules.initial_member_cap = 3;
    World world(6, sample_limits(), rules);
    world.directory.at(1).camp = 1;
    world.directory.at(5).camp = 2;
    const GuildId id = world.found(3);
    context.expect(world.book.apply(kNow, world.directory, cid(5), id).error == GuildError::kInvalidCamp, "khác phe");
    context.expect(world.book.apply(kNow, world.directory, cid(4), id).error == GuildError::kMemberFull, "bang đầy 3/3");
    // Nâng cấp nha môn mở thêm chỗ.
    context.expect(world.book.set_county(id, 1, social::CityId{7}).has_value(), "cấp 1 có thành phố");
    context.expect(world.book.member_cap(*world.book.find(id)) == 70, "trần cấp 1 = 70");
    context.expect(world.book.apply(kNow, world.directory, cid(4), id).ok(), "xin được");
    context.expect(!world.book.set_county(id, 6, social::CityId{7}).has_value(), "cấp 6 không có");
    context.expect(!world.book.set_county(id, 0, social::CityId{7}).has_value(), "cấp 0 phải không có thành phố");
    context.expect(!world.book.set_county(GuildId{999}, 1, social::CityId{7}).has_value(), "bang lạ");
    context.expect(world.book.set_county(id, 5, social::CityId{7}).has_value() && world.book.member_cap(*world.book.find(id)) == 110, "cấp 5 = 110");
    expect_valid(context, world.book);
}

void expel_and_leave(Context& context) {
    World world(5);
    const GuildId id = world.found(5);
    static_cast<void>(id);
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kAssistant).ok(), "2 làm bang phó");
    context.expect(world.book.expel(cid(3), cid(4)).error == GuildError::kUnauthorized, "thành viên không đuổi");
    context.expect(world.book.expel(cid(2), cid(2)).error == GuildError::kSelf, "tự đuổi");
    context.expect(world.book.expel(cid(2), cid(1)).error == GuildError::kRankTooLow, "bang phó không đuổi chủ");
    context.expect(world.book.expel(cid(2), cid(77)).error == GuildError::kMemberNotExist, "người ngoài bang");
    const GuildResult gone = world.book.expel(cid(2), cid(4));
    context.expect(gone.ok() && gone.events[0].audience.size() == 5 && gone.events[0].subject == cid(4), "đuổi: báo cả bang gồm người bị đuổi");
    context.expect(!world.book.guild_of(cid(4)).has_value(), "không còn trong bang");
    context.expect(world.book.leave(cid(1)).error == GuildError::kChiefCannotLeave, "chủ không rời");
    const GuildResult left = world.book.leave(cid(3));
    context.expect(left.ok() && !world.book.guild_of(cid(3)).has_value(), "rời bang");
    context.expect(world.book.leave(cid(3)).error == GuildError::kNotInGuild, "rời hai lần");
    // Người đã rời xin vào lại được.
    context.expect(world.book.apply(kNow, world.directory, cid(3), guild_id(world.book, 1)).ok(), "xin lại");
    expect_valid(context, world.book);
}

void appoint_rules(Context& context) {
    World world(20);
    const GuildId id = world.found(20);
    context.expect(world.book.appoint(cid(2), cid(3), GuildPosition::kElite).error == GuildError::kUnauthorized, "thành viên không bổ nhiệm");
    context.expect(world.book.appoint(cid(1), cid(1), GuildPosition::kElite).error == GuildError::kSelf, "tự bổ nhiệm");
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kChief).error == GuildError::kBadPosition, "không bổ nhiệm bang chủ");
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kTrainee).error == GuildError::kBadPosition, "không bổ nhiệm dự bị");
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kMember).error == GuildError::kBadValue, "giữ nguyên chức");
    context.expect(world.book.appoint(cid(1), cid(99), GuildPosition::kElite).error == GuildError::kMemberNotExist, "người ngoài bang");
    // Hạn ngạch: tinh anh tối đa 10.
    for (std::uint64_t who = 2; who <= 11; ++who) {
        context.expect(world.book.appoint(cid(1), cid(who), GuildPosition::kElite).ok(), "tinh anh trong hạn ngạch");
    }
    context.expect(world.book.appoint(cid(1), cid(12), GuildPosition::kElite).error == GuildError::kPosFull, "tinh anh thứ 11");
    // Mỗi chức thương/nông/công/nhân sự tối đa 4.
    for (std::uint64_t who = 12; who <= 15; ++who) {
        context.expect(world.book.appoint(cid(1), cid(who), GuildPosition::kCommerce).ok(), "chức thương trong hạn ngạch");
    }
    context.expect(world.book.appoint(cid(1), cid(16), GuildPosition::kCommerce).error == GuildError::kPosFull, "chức thương thứ 5");
    context.expect(world.book.appoint(cid(1), cid(16), GuildPosition::kAgriculture).ok(), "chức nông còn chỗ");
    // Một bang phó.
    context.expect(world.book.appoint(cid(1), cid(17), GuildPosition::kAssistant).ok(), "bang phó");
    context.expect(world.book.appoint(cid(1), cid(18), GuildPosition::kAssistant).error == GuildError::kPosFull, "bang phó thứ hai");
    // Bang phó chỉ bổ nhiệm được xuống dưới mình, kể cả đối với chức mới (chỗ 2008 bỏ ngỏ).
    context.expect(world.book.appoint(cid(17), cid(18), GuildPosition::kAssistant).error == GuildError::kRankTooLow,
        "bang phó không phong bang phó (chức mới không thấp hơn người phong)");
    context.expect(world.book.appoint(cid(17), cid(3), GuildPosition::kMember).ok(), "bang phó giáng tinh anh xuống thành viên");
    context.expect(world.book.appoint(cid(17), cid(2), GuildPosition::kPersonnel).ok(), "bang phó phong nhân sự");
    context.expect(world.book.appoint(cid(17), cid(1), GuildPosition::kMember).error == GuildError::kRankTooLow, "không giáng bang chủ");
    // Quyền về mặc định theo chức mới.
    context.expect(world.book.member(cid(17))->access == social::power::kAssistantDefault, "quyền bang phó mặc định");
    context.expect(world.book.member(cid(2))->access == social::power::kMemberDefault, "quyền nhân sự mặc định");
    context.expect(id.value() != 0, "id");
    expect_valid(context, world.book);
}

void toggle_power_rules(Context& context) {
    World world(5);
    static_cast<void>(world.found(5));
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kAssistant).ok(), "bang phó");
    using social::power::kChangeDesc;
    using social::power::kExpel;
    using social::power::kReserved;
    context.expect(world.book.appoint(cid(1), cid(3), GuildPosition::kElite).ok(), "3 làm tinh anh");
    context.expect(world.book.toggle_power(cid(2), cid(3), kExpel).error == GuildError::kUnauthorized, "bang phó không có quyền điều chỉnh quyền");
    context.expect(world.book.toggle_power(cid(1), cid(1), kExpel).error == GuildError::kSelf, "tự chỉnh quyền");
    context.expect(world.book.toggle_power(cid(1), cid(3), 0x3).error == GuildError::kBadValue, "hai bit một lúc");
    context.expect(world.book.toggle_power(cid(1), cid(3), 0x400).error == GuildError::kBadValue, "bit ngoài mười quyền");
    for (const std::uint16_t bit : {social::power::kAuthorize, social::power::kDemise, social::power::kLeave, social::power::kDismiss}) {
        context.expect((bit & kReserved) != 0 && world.book.toggle_power(cid(1), cid(3), bit).error == GuildError::kBadValue, "quyền gắn chức không trao được");
    }
    const GuildResult granted = world.book.toggle_power(cid(1), cid(3), kExpel);
    context.expect(granted.ok() && (world.book.member(cid(3))->access & kExpel) != 0, "trao quyền đuổi người");
    context.expect(world.book.expel(cid(3), cid(4)).ok(), "người được trao quyền đuổi được");
    const GuildResult revoked = world.book.toggle_power(cid(1), cid(3), kExpel);
    context.expect(revoked.ok() && (world.book.member(cid(3))->access & kExpel) == 0, "thu quyền");
    context.expect(world.book.toggle_power(cid(1), cid(2), kChangeDesc).ok() && (world.book.member(cid(2))->access & kChangeDesc) != 0, "trao quyền sửa tông chỉ");
    context.expect(world.book.set_description(cid(2), "mới").ok() && world.book.find(guild_id(world.book, 2))->description == "mới", "người đó sửa tông chỉ");
    // Người không giữ bit thì không trao đi được: cho bang phó quyền điều chỉnh bằng cách khác không có;
    // dùng quyền rút quỹ mà bang phó không có.
    context.expect(world.book.toggle_power(cid(1), cid(3), social::power::kWithdraw).ok(), "chủ trao quyền rút");
    expect_valid(context, world.book);
}

void demise_rules(Context& context) {
    World world(3);
    static_cast<void>(world.found(3));
    context.expect(world.book.demise(cid(2)).error == GuildError::kUnauthorized, "thành viên không nhường chức");
    context.expect(world.book.demise(cid(1)).error == GuildError::kNoAssistant, "chưa có bang phó");
    context.expect(world.book.appoint(cid(1), cid(2), GuildPosition::kAssistant).ok(), "phong bang phó");
    const GuildResult done = world.book.demise(cid(1));
    context.expect(done.ok() && done.events[0].subject == cid(2) && done.events[0].other == cid(1), "nhường chức");
    context.expect(world.book.member(cid(2))->position == GuildPosition::kChief && world.book.member(cid(1))->position == GuildPosition::kAssistant, "đổi chỗ chủ - phó");
    context.expect(world.book.member(cid(2))->access == social::power::kChiefDefault && world.book.member(cid(1))->access == social::power::kAssistantDefault, "quyền đổi theo chức");
    context.expect(world.book.leave(cid(1)).ok(), "bang chủ cũ giờ rời được");
    context.expect(world.book.leave(cid(2)).error == GuildError::kChiefCannotLeave, "chủ mới không rời");
    expect_valid(context, world.book);
}

void dismiss_blockers(Context& context) {
    World world(12);
    const GuildId id = world.found(12);
    context.expect(world.book.dismiss(cid(2)).error == GuildError::kUnauthorized, "thành viên không giải tán");
    // Còn tiền thì không giải tán: tiền không được biến mất.
    context.expect(world.book.deposit(cid(2), 1000, 5000).ok(), "nộp 1000");
    context.expect(world.book.dismiss(cid(1)).error == GuildError::kCashboxNotEmpty, "quỹ còn tiền");
    context.expect(world.book.withdraw(cid(1), 1000).ok(), "rút hết");
    context.expect(world.book.set_county(id, 1, social::CityId{5}).has_value(), "có thành phố");
    context.expect(world.book.dismiss(cid(1)).error == GuildError::kHasCity, "còn giữ thành phố");
    context.expect(world.book.set_county(id, 0, social::CityId{}).has_value(), "trả thành phố");
    context.expect(world.book.league_create(kNow, cid(1), "Liên Minh", 1'000'000).ok(), "lập liên minh");
    context.expect(world.book.dismiss(cid(1)).error == GuildError::kInLeague, "còn trong liên minh");
    context.expect(world.book.league_disband(cid(1)).ok(), "giải tán liên minh");
    // Đơn chờ rơi cùng bang.
    context.expect(world.book.apply(kNow, world.directory, cid(12), id).error == GuildError::kInGuild, "đã ở bang");
    World other(3);
    const GuildId small = other.found(2);
    context.expect(other.book.apply(kNow, other.directory, cid(3), small).ok(), "người 3 xin vào");
    const GuildResult gone = other.book.dismiss(cid(1));
    const GuildEvent* dismissed = first_kind(gone.events, GuildEventKind::kDismissed);
    context.expect(gone.ok() && dismissed != nullptr && dismissed->audience.size() == 2, "giải tán báo cả bang");
    context.expect(first_kind(gone.events, GuildEventKind::kApplyRejected) != nullptr, "đơn chờ nhận thông báo từ chối");
    context.expect(other.book.guild_count() == 0 && !other.book.guild_of(cid(2)).has_value() && !other.book.proposer_guild_of(cid(3)).has_value(), "mọi chỉ mục sạch");
    context.expect(other.book.create(kNow, other.directory, cid(1), "Thiên Long", "", 1'000'000).ok(), "tên được dùng lại");
    expect_valid(context, world.book);
    expect_valid(context, other.book);
}

void description_and_names(Context& context) {
    World world(3);
    static_cast<void>(world.found(3));
    context.expect(world.book.set_description(cid(2), "x").error == GuildError::kUnauthorized, "thành viên không sửa tông chỉ");
    context.expect(world.book.set_description(cid(1), std::string(51, 'a')).error == GuildError::kBadText, "tông chỉ 51 byte");
    context.expect(world.book.set_description(cid(1), "bad words").error == GuildError::kBadText, "tông chỉ bị lọc");
    context.expect(world.book.set_description(cid(1), "tông chỉ").events.empty(), "giữ nguyên không phát");
    const GuildResult changed = world.book.set_description(cid(1), "mới");
    context.expect(changed.ok() && changed.events[0].text == "mới" && changed.events[0].audience.size() == 3, "đổi tông chỉ");
    context.expect(world.book.rename_position(cid(2), GuildPosition::kMember, "Lính").error == GuildError::kNotChief, "chỉ chủ đặt tên chức");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kTrainee, "Lính").error == GuildError::kBadPosition, "dự bị không có tên");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kMember, std::string(24, 'a')).error == GuildError::kBadText, "24 byte");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kMember, "bad").error == GuildError::kBadText, "bị lọc");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kMember, " Lính").error == GuildError::kBadText, "dấu cách đầu");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kMember, "Lính").ok(), "đặt tên chức");
    const Guild* guild = world.book.find(guild_id(world.book, 1));
    context.expect(GuildBook::custom_position_name(*guild, GuildPosition::kMember) == "Lính" && GuildBook::custom_position_name(*guild, GuildPosition::kElite).empty(), "tên tuỳ chỉnh");
    context.expect(world.book.rename_position(cid(1), GuildPosition::kMember, "").ok() && GuildBook::custom_position_name(*world.book.find(guild->id), GuildPosition::kMember).empty(), "xoá tên về mặc định");
    // Chuỗi quyền 10 ký tự của GetMyGuildPower.
    context.expect(social::power_string(social::power::kChiefDefault) == "1111111011", "chuỗi quyền của bang chủ");
    context.expect(social::power_string(social::power::kMemberDefault) == "0000001100", "chuỗi quyền của thành viên");
    expect_valid(context, world.book);
}

void treasury_rules(Context& context) {
    World world(3);
    const GuildId id = world.found(3);
    context.expect(world.book.deposit(cid(2), 0, 100).error == GuildError::kBadValue, "nộp 0");
    context.expect(world.book.deposit(cid(2), -5, 100).error == GuildError::kBadValue, "nộp số âm");
    context.expect(world.book.deposit(cid(2), 200, 100).error == GuildError::kNotEnoughMoney, "ví không đủ");
    context.expect(world.book.deposit(cid(2), 10'000'000, 10'000'000).ok() && world.book.find(id)->funds == 10'000'000, "nộp đúng trần cấp 0");
    context.expect(world.book.deposit(cid(2), 1, 100).error == GuildError::kCashboxFull, "quỹ đầy");
    context.expect(world.book.member(cid(2))->contribution == 10'000'000, "ghi đóng góp");
    context.expect(world.book.set_county(id, 3, social::CityId{4}).has_value(), "cấp 3");
    context.expect(world.book.deposit(cid(3), 30'000'000, 30'000'000).ok(), "trần cấp 3 = 40 triệu");
    context.expect(world.book.deposit(cid(3), 1, 1).error == GuildError::kCashboxFull, "đầy 40 triệu");
    // Rút: chỉ người có quyền, không quá số dư.
    context.expect(world.book.withdraw(cid(2), 1).error == GuildError::kUnauthorized, "thành viên không rút");
    context.expect(world.book.withdraw(cid(1), 0).error == GuildError::kBadValue, "rút 0");
    context.expect(world.book.withdraw(cid(1), 40'000'001).error == GuildError::kNotEnoughMoney, "rút quá số dư");
    context.expect(world.book.withdraw(cid(1), 15'000'000).ok() && world.book.find(id)->funds == 25'000'000, "rút 15 triệu");
    // Hạ cấp nha môn không làm mất tiền.
    context.expect(world.book.set_county(id, 1, social::CityId{4}).has_value() && world.book.find(id)->funds == 25'000'000, "hạ cấp giữ nguyên quỹ");
    context.expect(world.book.deposit(cid(2), 1, 1).error == GuildError::kCashboxFull, "quỹ vượt trần mới thì không nộp thêm");
    // Số vàng tràn: không bao giờ vượt trần số học.
    context.expect(world.book.deposit(cid(2), social::kCopperCeiling + 1, social::kCopperCeiling + 1).error == GuildError::kBadValue, "số tiền khổng lồ");
    expect_valid(context, world.book);
}

void war_rules(Context& context) {
    World world(12);
    const GuildId a = world.found(6);
    // Bang thứ hai do người 7 lập, đủ 5 người; bang thứ ba chỉ có người 12.
    const GuildId b = world.book.create(kNow, world.directory, cid(7), "Địa Phủ", "", 1'000'000).events.front().guild;
    for (std::uint64_t who = 8; who <= 11; ++who) {
        context.expect(world.book.apply(kNow, world.directory, cid(who), b).ok(), "xin");
        context.expect(world.book.answer_application(kNow, world.directory, cid(7), cid(who), true).ok(), "nhận");
    }
    const GuildId lone = world.book.create(kNow, world.directory, cid(12), "Cô Độc", "", 1'000'000).events.front().guild;
    const auto table = social::WarPointTable::parse("id\tpoints\tpoints_rule_note\n0\t3\tgiết\n1\t1\tquặng\n2\t50\ttháp\n");
    context.expect(table.has_value() && table->size() == 3 && table->points_for(2) == 50 && table->points_for(9) == 0, "bảng điểm");
    context.expect(!social::WarPointTable::parse("id\tpoints\tnote\n0\t3\ta\n0\t4\tb\n").has_value(), "trùng mã sự kiện bị từ chối");
    if (!table) return;
    context.expect(world.book.declare_war(kNow, cid(2), b).error == GuildError::kUnauthorized, "thành viên không tuyên chiến");
    context.expect(world.book.declare_war(kNow, cid(1), a).error == GuildError::kSelf, "tự tuyên chiến");
    context.expect(world.book.declare_war(kNow, cid(1), GuildId{999}).error == GuildError::kNotExist, "bang không có");
    context.expect(world.book.declare_war(kNow, cid(1), lone).error == GuildError::kTooFewMembers, "bang kia chỉ một người");
    context.expect(world.book.add_war_points(kNow, a, 2, 1, *table).error == GuildError::kNotAtWar, "chưa có chiến sự");
    const GuildResult started = world.book.declare_war(kNow, cid(1), b);
    context.expect(started.ok() && started.events[0].audience.size() == 11, "tuyên chiến báo cả hai bang");
    context.expect(world.book.declare_war(kNow, cid(1), b).error == GuildError::kAtWar, "đang chiến rồi");
    context.expect(world.book.at_war(a) && world.book.at_war(b) && !world.book.at_war(lone), "trạng thái chiến sự");
    context.expect(world.book.dismiss(cid(1)).error == GuildError::kAtWar, "đang chiến không giải tán");
    context.expect(world.book.add_war_points(kNow, a, 2, 0, *table).error == GuildError::kBadValue, "số lần 0");
    context.expect(world.book.add_war_points(kNow, a, 2, 2'000'000, *table).error == GuildError::kBadValue, "số lần quá lớn");
    context.expect(world.book.add_war_points(kNow, lone, 2, 1, *table).error == GuildError::kNotAtWar, "bang kia không dính chiến sự");
    context.expect(world.book.add_war_points(kNow, a, 9, 1, *table).events.empty(), "mã sự kiện lạ không cộng điểm");
    const GuildResult scored = world.book.add_war_points(kNow, a, 2, 2, *table);
    context.expect(scored.ok() && scored.events[0].value == 100, "hai tháp = 100 điểm");
    context.expect(world.book.add_war_points(kNow, a, 0, 1, *table).events[0].value == 103, "cộng dồn một lần giết");
    // Hết giờ: 120 phút. Trước mốc chưa kết thúc, đúng mốc thì kết thúc và bang a thắng.
    const Tick before{kNow.value() + (120ULL * 60 * 20) - 1};
    context.expect(world.book.tick(before).empty() && world.book.at_war(a), "chưa hết giờ");
    const auto ended = world.book.tick(Tick{kNow.value() + (120ULL * 60 * 20)});
    const auto winner = ended.empty() ? std::uint64_t{0} : static_cast<std::uint64_t>(ended.front().value);
    context.expect(ended.size() == 1 && ended.front().kind == GuildEventKind::kWarEnded && winner == a.value(), "hết giờ: bang a thắng");
    context.expect(!world.book.at_war(a) && !world.book.at_war(b), "chiến sự đã xoá");
    // Hoà khi hai bên cùng 0 điểm.
    const Tick second_start{kNow.value() + 1'000'000};
    context.expect(world.book.declare_war(second_start, cid(7), a).ok(), "chiến lần hai");
    const auto drawn = world.book.tick(Tick{second_start.value() + (120ULL * 60 * 20)});
    context.expect(drawn.size() == 1 && drawn[0].value == 0, "hoà thì không bang thắng");
    expect_valid(context, world.book);
}

void league_rules(Context& context) {
    World world(6);
    const GuildId a = world.found(2);
    const GuildResult made = world.book.create(kNow, world.directory, cid(3), "Địa Phủ", "", 1'000'000);
    const GuildId b = made.events.front().guild;
    const GuildResult made_c = world.book.create(kNow, world.directory, cid(4), "Thiên Sơn", "", 1'000'000);
    const GuildId c = made_c.events.front().guild;
    context.expect(world.book.league_create(kNow, cid(2), "Liên Minh", 1'000'000).error == GuildError::kNotChief, "chỉ chủ lập liên minh");
    context.expect(world.book.league_create(kNow, cid(1), "Liên Minh", 999'999).error == GuildError::kNotEnoughMoney, "thiếu phí");
    context.expect(world.book.league_create(kNow, cid(1), "bad", 1'000'000).error == GuildError::kInvalidName, "tên bị lọc");
    const GuildResult created = world.book.league_create(kNow, cid(1), "Liên Minh", 1'000'000);
    context.expect(created.ok() && created.events[0].value == 1'000'000, "lập liên minh, phí 1 triệu");
    context.expect(world.book.league_create(kNow, cid(1), "Khác", 1'000'000).error == GuildError::kInLeague, "đã ở liên minh");
    context.expect(world.book.league_create(kNow, cid(3), "liên minh", 1'000'000).error == GuildError::kDuplicateName, "trùng tên liên minh");
    // Mời - trả lời.
    context.expect(world.book.league_invite(kNow, cid(3), a).error == GuildError::kNotInLeague, "bang b chưa ở liên minh");
    context.expect(world.book.league_invite(kNow, cid(1), a).error == GuildError::kSelf, "tự mời");
    context.expect(world.book.league_answer(kNow, cid(3), a, true).error == GuildError::kNoPending, "chưa được mời");
    const GuildResult invited = world.book.league_invite(kNow, cid(1), b);
    context.expect(invited.ok() && invited.events[0].audience == std::vector{cid(3)}, "mời bang b");
    const Tick late = ids::advance(kNow, ids::TickSpan{300LL * 20});
    static_cast<void>(world.book.tick(late));
    context.expect(world.book.league_answer(late, cid(3), a, true).error == GuildError::kNoPending, "lời mời hết hạn");
    context.expect(world.book.league_invite(kNow, cid(1), b).ok(), "mời lại");
    const GuildResult joined = world.book.league_answer(kNow, cid(3), a, true);
    context.expect(joined.ok() && world.book.league_of(b) != nullptr && world.book.league_of(b)->members.size() == 2, "bang b vào liên minh");
    context.expect(world.book.league_of(b)->members.front() == a, "bang đứng đầu ở đầu danh sách");
    context.expect(world.book.dismiss(cid(3)).error == GuildError::kInLeague, "bang trong liên minh không giải tán");
    // Rời có thời gian chờ 72 giờ.
    context.expect(world.book.league_leave(kNow, cid(1)).error == GuildError::kBadValue, "bang đứng đầu không 'rời'");
    context.expect(world.book.league_leave(kNow, cid(3)).ok() && world.book.league_of(b) == nullptr, "bang b rời");
    context.expect(world.book.league_invite(kNow, cid(1), b).error == GuildError::kRejoinCooldown, "chưa được vào lại");
    const Tick later = ids::advance(kNow, ids::TickSpan{72LL * 3600 * 20});
    context.expect(world.book.league_invite(later, cid(1), b).ok() && world.book.league_answer(later, cid(3), a, true).ok(), "hết chờ thì vào lại");
    // Từ chối, đuổi, giải tán.
    context.expect(world.book.league_invite(later, cid(1), c).ok(), "mời c");
    context.expect(world.book.league_answer(later, cid(4), a, false).ok() && world.book.league_of(c) == nullptr, "c từ chối");
    context.expect(world.book.league_invite(later, cid(1), c).ok() && world.book.league_answer(later, cid(4), a, true).ok(), "c vào");
    context.expect(world.book.league_kick(cid(3), a).error == GuildError::kUnauthorized, "bang thường không đuổi");
    context.expect(world.book.league_kick(cid(1), a).error == GuildError::kSelf, "tự đuổi");
    context.expect(world.book.league_kick(cid(1), b).ok() && world.book.league_of(b) == nullptr, "đuổi b");
    context.expect(world.book.league_disband(cid(4)).error == GuildError::kUnauthorized, "bang thường không giải tán");
    context.expect(world.book.league_disband(cid(1)).ok() && world.book.league_count() == 0 && world.book.league_of(c) == nullptr, "giải tán");
    context.expect(world.book.league_create(later, cid(1), "Liên Minh", 1'000'000).ok(), "tên được dùng lại");
    expect_valid(context, world.book);
}

[[nodiscard]] std::vector<std::byte> from_hex(std::string_view hex) {
    std::vector<std::byte> bytes;
    for (std::size_t index = 0; index + 1 < hex.size(); index += 2) {
        const auto digit = [](char c) { return c <= '9' ? c - '0' : c - 'a' + 10; };
        bytes.push_back(static_cast<std::byte>((digit(hex[index]) * 16) + digit(hex[index + 1])));
    }
    return bytes;
}

[[nodiscard]] Guild sample_guild() {
    Guild guild;
    guild.id = GuildId{3};
    guild.name = "ab";
    guild.description = "c";
    guild.founder = cid(7);
    guild.camp = 1;
    guild.funds = 9;
    guild.members.push_back(social::GuildMember{.id = cid(7), .name = "x", .position = GuildPosition::kChief, .access = 0x37F, .level = 50, .sect = 2, .contribution = 4});
    guild.members.push_back(social::GuildMember{.id = cid(8), .name = "y", .position = GuildPosition::kMember, .access = 0xC0, .level = 41, .sect = 3});
    guild.proposers.push_back(social::GuildProposer{.id = cid(9), .name = "z", .level = 40, .sect = 1, .expires = Tick{1500}});
    return guild;
}

void codec_golden_and_round_trip(Context& context) {
    const Guild guild = sample_guild();
    social::Bytes bytes;
    context.expect(social::encode_guild(guild, kNow, bytes).has_value(), "mã hoá bang");
    // Số vàng tính tay từ bố cục (phiên bản 1; id 3; tên "ab"; tông chỉ "c"; chủ lập 7; phe 1; cấp 0;
    // thành phố 0; quỹ 9; điểm chiến 0; chín tên chức rỗng; hai thành viên; một người xin vào còn 500 tick).
    const auto golden = from_hex(
        "8d000000" "0151" "0000"
        "0100" "0300000000000000" "0200" "6162" "0100" "63" "0700000000000000" "01" "00" "00000000"
        "0900000000000000" "0000000000000000"
        "0000" "0000" "0000" "0000" "0000" "0000" "0000" "0000" "0000"
        "0200"
        "0700000000000000" "0100" "78" "09" "7f03" "3200" "02" "0400000000000000"
        "0800000000000000" "0100" "79" "02" "c000" "2900" "03" "0000000000000000"
        "0100"
        "0900000000000000" "0100" "7a" "2800" "01" "f401000000000000");
    context.expect(bytes == golden, "khớp số vàng");
    const auto back = social::decode_guild(bytes, kNow, sample_limits());
    context.expect(back.has_value() && back->name == "ab" && back->members.size() == 2 && back->members[1].access == 0xC0 &&
                       back->proposers.size() == 1 && back->proposers[0].expires == Tick{1500} && back->funds == 9,
        "giải mã trả đúng, hạn đơn tính lại theo mốc");
    const auto restarted = social::decode_guild(bytes, Tick{50}, sample_limits());
    context.expect(restarted.has_value() && restarted->proposers[0].expires == Tick{550}, "nạp ở mốc khác: còn 500 tick");
    // Nạp vào sổ rồi bất biến vẫn đúng.
    World world(1);
    context.expect(world.book.load_guild(*back, kNow).has_value(), "nạp bang");
    context.expect(world.book.guild_of(cid(8)) == GuildId{3} && world.book.proposer_guild_of(cid(9)) == GuildId{3}, "chỉ mục dựng lại");
    context.expect(world.book.next_guild_id() == GuildId{4}, "id kế tiếp sau id đã nạp");
    context.expect(!world.book.load_guild(*back, kNow).has_value(), "nạp lại cùng bang bị từ chối");
    expect_valid(context, world.book);
}

void codec_rejects_garbage(Context& context) {
    const Guild guild = sample_guild();
    social::Bytes bytes;
    context.expect(social::encode_guild(guild, kNow, bytes).has_value(), "mã hoá");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        const std::span<const std::byte> view(bytes.data(), cut);
        every_cut_rejected = every_cut_rejected && !social::decode_guild(view, kNow, sample_limits()).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt bị từ chối");
    social::Bytes extra = bytes;
    extra.push_back(std::byte{0});
    context.expect(!social::decode_guild(extra, kNow, sample_limits()).has_value(), "byte thừa");
    std::size_t decoded = 0;
    for (std::size_t index = 0; index < bytes.size(); ++index) {
        for (const unsigned flip : {0x01U, 0x80U, 0xFFU}) {
            social::Bytes copy = bytes;
            copy.at(index) = static_cast<std::byte>(static_cast<unsigned>(copy.at(index)) ^ flip);
            if (social::decode_guild(copy, kNow, sample_limits()).has_value()) ++decoded;
        }
    }
    context.expect(decoded < bytes.size() * 3, "không phải mọi lật byte đều lọt");
    social::Bytes wrong = bytes;
    wrong.at(4) = std::byte{0x02};
    context.expect(social::decode_guild(wrong, kNow, sample_limits()).error() == social::CodecError::kBadKind, "kind sai");
    social::Bytes future = bytes;
    future.at(8) = std::byte{9};
    context.expect(social::decode_guild(future, kNow, sample_limits()).error() == social::CodecError::kBadVersion, "phiên bản lạ");
    // Hai bang chủ, không bang chủ, thành viên trùng, chức dự bị, quá hạn ngạch: đều bị từ chối.
    const auto reject_shape = [&context](const Guild& bad, std::string_view why) {
        social::Bytes out;
        context.expect(social::encode_guild(bad, kNow, out).has_value(), "mã hoá được bản sai hình dạng");
        context.expect(!social::decode_guild(out, kNow, sample_limits()).has_value(), why);
    };
    Guild two_chiefs = guild;
    two_chiefs.members[1].position = GuildPosition::kChief;
    reject_shape(two_chiefs, "hai bang chủ");
    Guild no_chief = guild;
    no_chief.members[0].position = GuildPosition::kMember;
    reject_shape(no_chief, "không có bang chủ");
    Guild dup = guild;
    dup.members[1].id = dup.members[0].id;
    reject_shape(dup, "thành viên trùng id");
    Guild trainee = guild;
    trainee.members[1].position = GuildPosition::kTrainee;
    reject_shape(trainee, "chức dự bị trong danh sách thành viên");
    Guild many_assistants = guild;
    many_assistants.members.push_back(social::GuildMember{.id = cid(20), .name = "a", .position = GuildPosition::kAssistant});
    many_assistants.members.push_back(social::GuildMember{.id = cid(21), .name = "b", .position = GuildPosition::kAssistant});
    reject_shape(many_assistants, "hai bang phó");
    Guild proposer_is_member = guild;
    proposer_is_member.proposers[0].id = cid(8);
    reject_shape(proposer_is_member, "người xin vào đã là thành viên");
    Guild negative_funds = guild;
    negative_funds.funds = -1;
    reject_shape(negative_funds, "quỹ âm");
    Guild bad_power = guild;
    bad_power.members[1].access = 0x8000;
    reject_shape(bad_power, "quyền ngoài mười bit");
    Guild city_mismatch = guild;
    city_mismatch.level = 2;
    reject_shape(city_mismatch, "có cấp nha môn mà không có thành phố");
}

void league_codec(Context& context) {
    social::League league;
    league.id = social::LeagueId{2};
    league.name = "lm";
    league.leader = GuildId{5};
    league.members = {GuildId{5}, GuildId{6}};
    social::Bytes bytes;
    context.expect(social::encode_league(league, bytes).has_value(), "mã hoá liên minh");
    // Số vàng tính tay: đầu khung (thân 36 byte, kind 0x5107), phiên bản 1, id 2, tên "lm", bang đứng đầu 5,
    // hai bang 5 và 6.
    const auto golden = from_hex(
        "24000000" "0751" "0000"
        "0100" "02000000" "0200" "6c6d" "0500000000000000" "0200" "0500000000000000" "0600000000000000");
    context.expect(bytes == golden, "khớp số vàng liên minh");
    const auto back = social::decode_league(bytes, sample_limits());
    context.expect(back.has_value() && back->id == social::LeagueId{2} && back->members.size() == 2 && back->leader == GuildId{5}, "vòng đầy đủ");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        const std::span<const std::byte> view(bytes.data(), cut);
        every_cut_rejected = every_cut_rejected && !social::decode_league(view, sample_limits()).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt bị từ chối");
    social::League wrong_lead = league;
    wrong_lead.leader = GuildId{6};
    social::Bytes out;
    context.expect(social::encode_league(wrong_lead, out).has_value(), "mã hoá bản sai");
    context.expect(!social::decode_league(out, sample_limits()).has_value(), "bang đứng đầu không ở đầu danh sách");
    social::League dup = league;
    dup.members = {GuildId{5}, GuildId{5}};
    out.clear();
    context.expect(social::encode_league(dup, out).has_value(), "mã hoá bản trùng");
    context.expect(!social::decode_league(out, sample_limits()).has_value(), "bang trùng");
    // Nạp vào sổ: bang chưa nạp thì từ chối.
    World world(1);
    context.expect(!world.book.load_league(league).has_value(), "liên minh trỏ vào bang chưa nạp");
}

constexpr std::array kCases{
    Case{.name = "create_rules", .body = create_rules},
    Case{.name = "guild_count_cap", .body = guild_count_cap},
    Case{.name = "apply_and_recruit", .body = apply_and_recruit},
    Case{.name = "camp_and_member_cap", .body = camp_and_member_cap},
    Case{.name = "expel_and_leave", .body = expel_and_leave},
    Case{.name = "appoint_rules", .body = appoint_rules},
    Case{.name = "toggle_power_rules", .body = toggle_power_rules},
    Case{.name = "demise_rules", .body = demise_rules},
    Case{.name = "dismiss_blockers", .body = dismiss_blockers},
    Case{.name = "description_and_names", .body = description_and_names},
    Case{.name = "treasury_rules", .body = treasury_rules},
    Case{.name = "war_rules", .body = war_rules},
    Case{.name = "league_rules", .body = league_rules},
    Case{.name = "codec_golden_and_round_trip", .body = codec_golden_and_round_trip},
    Case{.name = "codec_rejects_garbage", .body = codec_rejects_garbage},
    Case{.name = "league_codec", .body = league_codec},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
