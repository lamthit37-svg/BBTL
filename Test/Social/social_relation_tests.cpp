// Quan hệ: kết bạn hai chiều, danh sách đen/kẻ thù/bạn tạm, kết hôn, sư đồ, khối lưu bền. Sai thì hỏng
// thầm (bạn một chiều, trần bị vượt), nên mỗi ca dựng sổ thật rồi gọi validate().
#include "ids/ids.hpp"
#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/relation.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using social::BondKind;
using social::MentorTable;
using social::RelationBook;
using social::RelationError;
using social::RelationEvent;
using social::RelationEventKind;
using social::RelationKind;
using social::RelationResult;
using social::RelationSheet;
using social::Tick;

constexpr Tick kNow{1000};

[[nodiscard]] std::size_t count_kind(const std::vector<RelationEvent>& events, RelationEventKind kind) {
    return static_cast<std::size_t>(
        std::ranges::count_if(events, [kind](const RelationEvent& event) { return event.kind == kind; }));
}

[[nodiscard]] const RelationEvent* first_kind(const std::vector<RelationEvent>& events, RelationEventKind kind) {
    const auto found = std::ranges::find_if(events, [kind](const RelationEvent& event) { return event.kind == kind; });
    return found == events.end() ? nullptr : &*found;
}

struct World {
    FakeDirectory directory;
    RelationBook book{sample_limits(), sample_relation_rules()};
    bool ready = true;  // false nếu nạp sổ trống thất bại (không xảy ra với sổ rỗng)

    explicit World(std::uint64_t count) {
        for (std::uint64_t id = 1; id <= count; ++id) {
            directory.add(id, "p" + std::to_string(id));
            ready = book.load(cid(id), RelationSheet{}).has_value() && ready;
        }
    }

    bool befriend(std::uint64_t left, std::uint64_t right) {
        const RelationResult asked = book.request(kNow, directory, BondKind::kFriend, cid(left), cid(right));
        if (!asked.ok()) return false;
        return book.answer(kNow, directory, BondKind::kFriend, cid(right), cid(left), true).ok();
    }
};

void expect_valid(Context& context, const RelationBook& book) {
    const auto checked = book.validate();
    context.expect(checked.has_value(), "validate() đạt");
}

[[nodiscard]] std::int64_t value_of(const std::vector<RelationEvent>& events, RelationEventKind kind) {
    const RelationEvent* event = first_kind(events, kind);
    return event == nullptr ? -1 : event->value;
}

[[nodiscard]] const social::RelationEntry* entry_of(const RelationBook& book, std::uint64_t owner, std::uint64_t other) {
    const RelationSheet* sheet = book.sheet(cid(owner));
    if (sheet == nullptr) return nullptr;
    const auto found = std::ranges::find(sheet->entries, cid(other), &social::RelationEntry::id);
    return found == sheet->entries.end() ? nullptr : &*found;
}

[[nodiscard]] std::optional<RelationKind> kind_of(const RelationBook& book, std::uint64_t owner, std::uint64_t other) {
    const social::RelationEntry* entry = entry_of(book, owner, other);
    if (entry == nullptr) return std::nullopt;
    return entry->kind;
}

[[nodiscard]] std::optional<int> group_of(const RelationBook& book, std::uint64_t owner, std::uint64_t other) {
    const social::RelationEntry* entry = entry_of(book, owner, other);
    if (entry == nullptr) return std::nullopt;
    return entry->group;
}

[[nodiscard]] std::optional<int> point_of(const RelationBook& book, std::uint64_t owner, std::uint64_t other) {
    const social::RelationEntry* entry = entry_of(book, owner, other);
    if (entry == nullptr) return std::nullopt;
    return entry->point;
}

void friend_handshake(Context& context) {
    World world(3);
    const RelationResult asked = world.book.request(kNow, world.directory, BondKind::kFriend, cid(1), cid(2));
    context.expect(asked.ok() && count_kind(asked.events, RelationEventKind::kBondAsk) == 1, "hỏi kết bạn");
    context.expect(entry_of(world.book, 1, 2) == nullptr, "chưa trả lời thì chưa là bạn");
    // Trả lời giả: người chưa từng hỏi.
    context.expect(world.book.answer(kNow, world.directory, BondKind::kFriend, cid(2), cid(3), true).error ==
                       RelationError::kNoPending, "trả lời giả mạo bị từ chối");
    // Người sai vai (người hỏi tự trả lời).
    context.expect(world.book.answer(kNow, world.directory, BondKind::kFriend, cid(1), cid(2), true).error ==
                       RelationError::kNoPending, "người hỏi không tự trả lời được");
    const RelationResult done = world.book.answer(kNow, world.directory, BondKind::kFriend, cid(2), cid(1), true);
    context.expect(done.ok() && count_kind(done.events, RelationEventKind::kFriendAdded) == 1, "thành bạn");
    context.expect(entry_of(world.book, 1, 2) != nullptr && entry_of(world.book, 2, 1) != nullptr, "hai chiều");
    context.expect(kind_of(world.book, 1, 2) == RelationKind::kFriend && group_of(world.book, 1, 2) == 0, "nhóm đầu");
    context.expect(world.book.answer(kNow, world.directory, BondKind::kFriend, cid(2), cid(1), true).error ==
                       RelationError::kNoPending, "lời chờ chỉ dùng một lần");
    // Từ chối.
    static_cast<void>(world.book.request(kNow, world.directory, BondKind::kFriend, cid(1), cid(3)));
    const RelationResult refused = world.book.answer(kNow, world.directory, BondKind::kFriend, cid(3), cid(1), false);
    context.expect(refused.ok() && count_kind(refused.events, RelationEventKind::kBondRefused) == 1, "từ chối");
    context.expect(entry_of(world.book, 1, 3) == nullptr, "từ chối thì không thành bạn");
    expect_valid(context, world.book);
}

void friend_rejections(Context& context) {
    World world(6);
    world.directory.at(2).settings = social::setting::kCannotAddFriend;
    world.directory.at(3).camp = 1;
    world.directory.at(1).camp = 2;
    world.directory.at(5).online = false;
    const auto ask = [&world](std::uint64_t from, std::uint64_t to) {
        return world.book.request(kNow, world.directory, BondKind::kFriend, cid(from), cid(to)).error;
    };
    context.expect(ask(1, 1) == RelationError::kSelf, "tự kết bạn");
    context.expect(ask(1, 2) == RelationError::kRefused, "cài đặt không nhận bạn");
    context.expect(ask(1, 3) == RelationError::kRefused, "thù địch");
    context.expect(ask(1, 5) == RelationError::kUnknownPlayer, "ngoại tuyến");
    context.expect(ask(1, 99) == RelationError::kUnknownPlayer, "id lạ");
    // Bị đối phương đưa vào danh sách đen thì chỉ thấy "từ chối", không lộ lý do.
    context.expect(world.book.blacklist(world.directory, cid(4), cid(6)).ok(), "4 chặn 6");
    context.expect(ask(6, 4) == RelationError::kRefused, "bị chặn không lộ");
    // Mình đã chặn người kia thì phải gỡ chặn trước.
    context.expect(ask(4, 6) == RelationError::kInBlacklist, "đang chặn người kia");
    world.directory.at(1).camp = 0;
    context.expect(world.befriend(1, 4), "kết bạn được");
    context.expect(ask(1, 4) == RelationError::kAlready, "đã là bạn");
    world.directory.at(2).settings = 0;
    context.expect(world.book.note_enemy(world.directory, cid(4), cid(2)).ok(), "ghi kẻ thù");
    context.expect(ask(4, 2) == RelationError::kInEnemyList, "đang là kẻ thù");
    expect_valid(context, world.book);
}

void capacity_rules(Context& context) {
    // Sổ 1 đã đủ 80 bạn (20 mỗi nhóm): kết bạn thêm báo đầy, mà không đổi sổ nào.
    World world(2);
    RelationSheet full;
    for (std::uint64_t index = 0; index < 80; ++index) {
        full.entries.push_back(social::RelationEntry{.id = cid(1000 + index),
            .name = "f" + std::to_string(index),
            .kind = RelationKind::kFriend,
            .group = static_cast<std::uint8_t>(index / 20)});
    }
    context.expect(world.book.load(cid(1), full).has_value(), "nạp sổ đủ trần");
    const RelationResult asked = world.book.request(kNow, world.directory, BondKind::kFriend, cid(1), cid(2));
    context.expect(asked.error == RelationError::kListFull, "danh sách đầy");
    context.expect(world.book.pending_count() == 0, "không để lại lời chờ");
    // Nạp sổ vượt trần bị từ chối.
    RelationSheet over = full;
    over.entries.push_back(social::RelationEntry{.id = cid(5000), .name = "x", .kind = RelationKind::kFriend, .group = 0});
    context.expect(!world.book.load(cid(2), over).has_value(), "sổ vượt trần bị từ chối");
    // Nhóm đầy: move_group.
    World small(3);
    context.expect(small.befriend(1, 2), "bạn");
    RelationSheet group_full;
    for (std::uint64_t index = 0; index < 20; ++index) {
        group_full.entries.push_back(social::RelationEntry{
            .id = cid(2000 + index), .name = "g", .kind = RelationKind::kFriend, .group = 1});
    }
    group_full.entries.push_back(social::RelationEntry{.id = cid(2), .name = "p2", .kind = RelationKind::kFriend, .group = 0});
    context.expect(small.book.load(cid(1), group_full).has_value(), "nạp");
    context.expect(small.book.move_group(cid(1), cid(2), 1).error == RelationError::kGroupFull, "nhóm 2 đầy");
    context.expect(small.book.move_group(cid(1), cid(2), 4).error == RelationError::kBadGroup, "nhóm 5 không có");
    context.expect(small.book.move_group(cid(1), cid(2), 2).ok() && group_of(small.book, 1, 2) == 2, "đổi nhóm");
    context.expect(small.book.move_group(cid(1), cid(77), 0).error == RelationError::kNotFound, "không có người đó");
}

void remove_rules(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    context.expect(world.book.add_point(cid(1), cid(2), 600).ok(), "thân thiết 600");
    // Từ mức password_intimacy (500) xoá bạn cần xác minh.
    context.expect(world.book.remove(cid(1), cid(2), false).error == RelationError::kNeedVerify, "cần mật khẩu cấp hai");
    context.expect(entry_of(world.book, 1, 2) != nullptr, "chưa xoá");
    const RelationResult removed = world.book.remove(cid(1), cid(2), true);
    context.expect(removed.ok() && count_kind(removed.events, RelationEventKind::kPeerRemoved) == 1, "xoá được");
    context.expect(entry_of(world.book, 1, 2) == nullptr && entry_of(world.book, 2, 1) == nullptr, "mất cả hai phía");
    // Xoá bạn có sổ đối phương chưa nạp: phát sự kiện ghi kho.
    context.expect(world.befriend(1, 3), "bạn 1-3");
    static_cast<void>(world.book.unload(cid(3)));
    const RelationResult offline = world.book.remove(cid(1), cid(3), false);
    context.expect(offline.ok() && count_kind(offline.events, RelationEventKind::kOfflineChange) == 1, "đối phương ngoại tuyến");
    context.expect(world.book.remove(cid(1), cid(3), false).error == RelationError::kNotFound, "xoá hai lần");
    expect_valid(context, world.book);
}

void blacklist_transition(Context& context) {
    World world(4);
    context.expect(world.befriend(1, 2), "bạn");
    const RelationResult black = world.book.blacklist(world.directory, cid(1), cid(2));
    context.expect(black.ok() && count_kind(black.events, RelationEventKind::kPeerRemoved) == 1, "bạn thành đen, đối phương mất mục");
    context.expect(kind_of(world.book, 1, 2) == RelationKind::kBlack, "mục là đen");
    context.expect(entry_of(world.book, 2, 1) == nullptr, "đối phương không còn mục");
    context.expect(world.book.blacklist(world.directory, cid(1), cid(2)).error == RelationError::kAlready, "đã đen");
    context.expect(world.book.blacklist(world.directory, cid(1), cid(1)).error == RelationError::kSelf, "tự chặn");
    context.expect(world.book.blacklist(world.directory, cid(1), cid(99)).error == RelationError::kUnknownPlayer, "id lạ");
    context.expect(world.book.remove(cid(1), cid(2), false).ok(), "gỡ đen");
    // Vợ chồng, sư đồ không thể bị chặn thẳng.
    World married(2);
    married.directory.at(1).sex = 0;
    married.directory.at(2).sex = 1;
    context.expect(married.befriend(1, 2) && married.book.add_point(cid(1), cid(2), 2000).ok(), "bạn thân");
    static_cast<void>(married.book.request(kNow, married.directory, BondKind::kMarry, cid(1), cid(2)));
    context.expect(married.book.answer(kNow, married.directory, BondKind::kMarry, cid(2), cid(1), true).ok(), "kết hôn");
    context.expect(married.book.blacklist(married.directory, cid(1), cid(2)).error == RelationError::kBadKind, "không chặn vợ chồng");
    expect_valid(context, world.book);
    expect_valid(context, married.book);
}

void enemy_and_temp_lists(Context& context) {
    World world(40);
    // Kẻ thù tối đa 20: cái cũ nhất rời đi.
    for (std::uint64_t killer = 2; killer <= 25; ++killer) {
        context.expect(world.book.note_enemy(world.directory, cid(1), cid(killer)).ok(), "ghi kẻ thù");
    }
    const RelationSheet* sheet = world.book.sheet(cid(1));
    const auto enemies = std::ranges::count(sheet->entries, RelationKind::kEnemy, &social::RelationEntry::kind);
    context.expect(enemies == 20, "giữ đúng 20 kẻ thù");
    context.expect(entry_of(world.book, 1, 2) == nullptr && entry_of(world.book, 1, 25) != nullptr, "kẻ cũ nhất rời đi");
    // Ghi lại người đã có thì giữ nguyên.
    context.expect(world.book.note_enemy(world.directory, cid(1), cid(25)).events.empty(), "đã có thì không phát sự kiện");
    // Bạn tạm: tự rời khi đầy, và nhường chỗ khi thành bạn thật.
    for (std::uint64_t other = 26; other <= 40; ++other) {
        context.expect(world.book.note_temp(world.directory, cid(1), cid(other)).ok(), "ghi bạn tạm");
    }
    context.expect(kind_of(world.book, 1, 30) == RelationKind::kTemp, "bạn tạm");
    context.expect(world.befriend(1, 30), "bạn tạm thành bạn thật");
    context.expect(kind_of(world.book, 1, 30) == RelationKind::kFriend, "mục đổi thành bạn");
    context.expect(std::ranges::count(world.book.sheet(cid(1))->entries, cid(30), &social::RelationEntry::id) == 1, "không trùng mục");
    expect_valid(context, world.book);
}

void mood_rules(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.directory.at(2).online = true;
    const RelationResult changed = world.book.set_mood(world.directory, cid(1), "vui vẻ");
    context.expect(changed.ok() && changed.events.size() == 1 && changed.events[0].audience == std::vector{cid(2)}, "báo bạn trực tuyến");
    context.expect(changed.events[0].text == "vui vẻ", "nội dung");
    context.expect(world.book.set_mood(world.directory, cid(1), "vui vẻ").events.empty(), "không đổi thì không phát");
    context.expect(world.book.set_mood(world.directory, cid(1), std::string(26, 'a')).error == RelationError::kBadText, "quá 25 byte");
    context.expect(world.book.set_mood(world.directory, cid(1), std::string(25, 'a')).ok(), "đúng 25 byte");
    context.expect(world.book.set_mood(world.directory, cid(1), "a\nb").error == RelationError::kBadText, "ký tự điều khiển");
    context.expect(world.book.set_mood(world.directory, cid(1), std::string_view("\xFF\xFE", 2)).error == RelationError::kBadText, "UTF-8 hỏng");
    context.expect(world.book.set_mood(world.directory, cid(9), "x").error == RelationError::kNotLoaded, "sổ lạ");
    world.directory.at(2).online = false;
    context.expect(world.book.set_mood(world.directory, cid(1), "khác").events[0].audience.empty(), "bạn ngoại tuyến không nhận");
}

void points_and_presence(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    context.expect(world.book.add_point(cid(1), cid(2), 5).ok() && point_of(world.book, 2, 1) == 5, "cả hai phía cùng đổi");
    context.expect(world.book.add_point(cid(1), cid(2), 20000).ok() && point_of(world.book, 1, 2) == 9999, "kẹp ở 9999");
    context.expect(world.book.add_point(cid(1), cid(2), 1).events.empty(), "đã trần thì không phát");
    context.expect(world.book.add_point(cid(2), cid(1), -100000).ok() && point_of(world.book, 1, 2) == 0, "kẹp ở 0");
    context.expect(world.book.add_point(cid(1), cid(3), 5).error == RelationError::kNotFriend, "chưa là bạn");
    context.expect(world.book.add_point(cid(1), cid(1), 5).error == RelationError::kSelf, "tự cộng");
    // Báo lên tuyến chỉ tới bạn đủ thân (>= 10) đang trực tuyến.
    context.expect(world.book.on_presence(world.directory, cid(1), true).empty(), "thân 0: im lặng");
    static_cast<void>(world.book.add_point(cid(1), cid(2), 10));
    const auto up = world.book.on_presence(world.directory, cid(1), true);
    context.expect(up.size() == 1 && up[0].value == 1 && up[0].audience == std::vector{cid(2)}, "lên tuyến");
    context.expect(world.book.on_presence(world.directory, cid(1), false)[0].value == 0, "xuống tuyến");
    world.directory.at(2).online = false;
    context.expect(world.book.on_presence(world.directory, cid(1), true).empty(), "bạn ngoại tuyến: im lặng");
    expect_valid(context, world.book);
}

void marriage_rules(Context& context) {
    World world(4);
    world.directory.at(1).sex = 0;
    world.directory.at(2).sex = 1;
    world.directory.at(3).sex = 0;
    world.directory.at(4).sex = 1;
    const auto marry = [&world](std::uint64_t a, std::uint64_t b) {
        return world.book.request(kNow, world.directory, BondKind::kMarry, cid(a), cid(b)).error;
    };
    context.expect(marry(1, 2) == RelationError::kNotFriend, "chưa là bạn");
    context.expect(world.befriend(1, 2) && world.befriend(1, 3) && world.befriend(2, 4), "kết bạn");
    context.expect(marry(1, 2) == RelationError::kPointTooLow, "chưa đủ thân");
    static_cast<void>(world.book.add_point(cid(1), cid(2), 1000));
    static_cast<void>(world.book.add_point(cid(1), cid(3), 1000));
    context.expect(marry(1, 3) == RelationError::kSameSex, "cùng giới");
    context.expect(!marry(1, 2).has_value(), "hỏi cưới");
    const RelationResult done = world.book.answer(kNow, world.directory, BondKind::kMarry, cid(2), cid(1), true);
    context.expect(done.ok() && count_kind(done.events, RelationEventKind::kMarried) == 1, "kết hôn");
    context.expect(kind_of(world.book, 1, 2) == RelationKind::kSpouse && kind_of(world.book, 2, 1) == RelationKind::kSpouse, "hai phía");
    context.expect(marry(1, 3) == RelationError::kAlreadyMarried, "đã có chồng/vợ");
    static_cast<void>(world.book.add_point(cid(2), cid(4), 1000));
    context.expect(marry(4, 2) == RelationError::kAlreadyMarried, "người kia đã có vợ/chồng");
    // Xoá bạn không xoá được vợ chồng.
    context.expect(world.book.remove(cid(1), cid(2), true).error == RelationError::kBadKind, "chỉ ly hôn mới huỷ");
    const RelationResult split = world.book.divorce(cid(1));
    context.expect(split.ok() && count_kind(split.events, RelationEventKind::kDivorced) == 1, "ly hôn");
    context.expect(kind_of(world.book, 1, 2) == RelationKind::kFriend && kind_of(world.book, 2, 1) == RelationKind::kFriend, "về làm bạn");
    context.expect(world.book.divorce(cid(1)).error == RelationError::kNotFound, "ly hôn hai lần");
    expect_valid(context, world.book);
}

constexpr std::string_view kRewardsTsv =
    "# schema 1\n# source: test\n# tool: test\n# types: int\tint\tint\tint\tint\tint\n"
    "apprentice_level\texp_reward_no_guild\texp_reward_guild_1\trating_1\trating_2\trating_3\n"
    "30\t250000\t500000\t100\t80\t40\n45\t500000\t1000000\t100\t80\t40\n";
constexpr std::string_view kShareTsv =
    "# schema 1\n# source: test\n# tool: test\n# types: int\tfloat\napprentice_rank\tmentor_exp_share\n1\t0\n10\t0.5\n";

void master_prentice_flow(Context& context) {
    World world(5);
    world.directory.at(1).level = 60;  // sư phụ
    world.directory.at(2).level = 20;  // đồ đệ
    world.directory.at(3).level = 20;
    world.directory.at(4).level = 20;
    world.directory.at(5).level = 45;
    const auto recruit = [&world](std::uint64_t master, std::uint64_t prentice) {
        return world.book.request(kNow, world.directory, BondKind::kRecruit, cid(master), cid(prentice)).error;
    };
    context.expect(recruit(1, 2) == RelationError::kNotFriend, "chưa là bạn");
    context.expect(world.befriend(1, 2) && world.befriend(1, 3) && world.befriend(1, 4) && world.befriend(1, 5), "kết bạn");
    context.expect(recruit(2, 1) == RelationError::kLevelTooLow, "sư phụ thấp cấp");
    context.expect(recruit(1, 5) == RelationError::kLevelTooHigh, "đồ đệ cao cấp");
    context.expect(!recruit(1, 2).has_value(), "mời nhận đồ đệ");
    const RelationResult joined = world.book.answer(kNow, world.directory, BondKind::kRecruit, cid(2), cid(1), true);
    context.expect(joined.ok() && count_kind(joined.events, RelationEventKind::kRecruited) == 1, "nhận đồ đệ");
    context.expect(kind_of(world.book, 1, 2) == RelationKind::kPrentice && kind_of(world.book, 2, 1) == RelationKind::kMaster, "hai chiều đối ngược");
    // Bái sư theo chiều ngược: đồ đệ xin, sư phụ đồng ý.
    context.expect(!world.book.request(kNow, world.directory, BondKind::kApprentice, cid(3), cid(1)).error.has_value(), "xin bái sư");
    context.expect(world.book.answer(kNow, world.directory, BondKind::kApprentice, cid(1), cid(3), true).ok(), "nhận");
    // Đã đủ 2 đồ đệ.
    context.expect(recruit(1, 4) == RelationError::kPrenticeFull, "đủ hai đồ đệ");
    // Đồ đệ đã có sư phụ không bái thêm.
    World second(3);
    second.directory.at(1).level = 60;
    second.directory.at(2).level = 60;
    second.directory.at(3).level = 10;
    context.expect(second.befriend(1, 3) && second.befriend(2, 3), "bạn");
    static_cast<void>(second.book.request(kNow, second.directory, BondKind::kRecruit, cid(1), cid(3)));
    context.expect(second.book.answer(kNow, second.directory, BondKind::kRecruit, cid(3), cid(1), true).ok(), "bái 1");
    context.expect(second.book.request(kNow, second.directory, BondKind::kRecruit, cid(2), cid(3)).error == RelationError::kHasMaster, "đã có sư phụ");
    // Sư phụ cũng có thể có sư phụ (mục kMaster và kPrentice cùng sổ).
    expect_valid(context, world.book);
    expect_valid(context, second.book);
}

void leave_expel_and_cooldown(Context& context) {
    World world(4);
    world.directory.at(1).level = 60;
    world.directory.at(2).level = 60;
    world.directory.at(3).level = 10;
    world.directory.at(4).level = 10;
    context.expect(world.befriend(1, 3) && world.befriend(2, 3) && world.befriend(1, 4), "bạn");
    static_cast<void>(world.book.request(kNow, world.directory, BondKind::kRecruit, cid(1), cid(3)));
    static_cast<void>(world.book.answer(kNow, world.directory, BondKind::kRecruit, cid(3), cid(1), true));
    context.expect(world.book.leave_master(kNow, cid(1)).error == RelationError::kNotPrentice, "sư phụ không dùng lệnh này");
    // Phản sư: về làm bạn, và phải chờ trước khi bái sư khác.
    const RelationResult left = world.book.leave_master(kNow, cid(3));
    context.expect(left.ok() && value_of(left.events, RelationEventKind::kPrenticeLeft) == 1, "rời sư môn");
    context.expect(kind_of(world.book, 3, 1) == RelationKind::kFriend && kind_of(world.book, 1, 3) == RelationKind::kFriend, "về làm bạn");
    const Tick soon = ids::advance(kNow, ids::TickSpan{100});
    context.expect(world.book.request(soon, world.directory, BondKind::kRecruit, cid(2), cid(3)).error == RelationError::kBetrayCooldown, "đang chờ");
    const Tick later = ids::advance(kNow, ids::TickSpan{259'200LL * 20});
    context.expect(world.book.request(later, world.directory, BondKind::kRecruit, cid(2), cid(3)).ok(), "hết chờ thì được");
    context.expect(world.book.answer(later, world.directory, BondKind::kRecruit, cid(3), cid(2), true).ok(), "bái sư mới");
    // Sư phụ đuổi: không bị phạt chờ.
    static_cast<void>(world.book.request(later, world.directory, BondKind::kRecruit, cid(1), cid(4)));
    static_cast<void>(world.book.answer(later, world.directory, BondKind::kRecruit, cid(4), cid(1), true));
    context.expect(world.book.expel_prentice(cid(2), cid(4)).error == RelationError::kNotMaster, "không phải sư phụ của người này");
    context.expect(world.book.expel_prentice(cid(1), cid(4)).ok(), "đuổi");
    context.expect(kind_of(world.book, 4, 1) == RelationKind::kFriend, "về làm bạn");
    context.expect(world.book.sheet(cid(4))->betray_until == Tick{}, "không bị phạt chờ");
    expect_valid(context, world.book);
}

void mentor_rewards(Context& context) {
    const auto table = MentorTable::parse({.rewards_tsv = kRewardsTsv, .share_tsv = kShareTsv});
    context.expect(table.has_value(), "bảng thưởng đọc được");
    if (!table) return;
    context.expect(table->rewards().size() == 2 && table->share_at(10) == 0.5 && table->share_at(11) == 0.0, "hệ số theo cấp");
    World world(2);
    world.directory.at(1).level = 60;
    world.directory.at(2).level = 10;
    context.expect(world.befriend(1, 2), "bạn");
    static_cast<void>(world.book.request(kNow, world.directory, BondKind::kRecruit, cid(1), cid(2)));
    static_cast<void>(world.book.answer(kNow, world.directory, BondKind::kRecruit, cid(2), cid(1), true));
    context.expect(world.book.on_prentice_level(world.directory, *table, cid(2), 29).events.empty(), "cấp 29 chưa tới mốc");
    const RelationResult first = world.book.on_prentice_level(world.directory, *table, cid(2), 30);
    context.expect(first.events.size() == 1 && first.events[0].value == 250000 && first.events[0].level == 30, "thưởng mốc 30 (chưa có bang)");
    context.expect(world.book.sheet(cid(1))->moral_point == 10, "cộng điểm sư đức");
    context.expect(world.book.on_prentice_level(world.directory, *table, cid(2), 30).events.empty(), "mốc đã nhận không nhận lại");
    // Nhảy cấp qua mốc 45: nhận đúng một lần, theo cột có bang vì sư phụ vào bang.
    world.directory.at(1).guild = social::GuildId{9};
    const RelationResult second = world.book.on_prentice_level(world.directory, *table, cid(2), 50);
    context.expect(second.events.size() == 1 && second.events[0].value == 1'000'000 && second.events[0].level == 45, "thưởng mốc 45 (có bang)");
    context.expect(world.book.sheet(cid(1))->moral_point == 20, "sư đức 20");
    // Không có sư phụ: không có gì.
    World alone(1);
    context.expect(alone.book.on_prentice_level(alone.directory, *table, cid(1), 50).events.empty(), "không sư phụ");
    // Bảng sai: cấp không tăng dần.
    const std::string bad = "apprentice_level\texp_reward_no_guild\texp_reward_guild_1\n30\t1\t1\n30\t1\t1\n";
    context.expect(!MentorTable::parse({.rewards_tsv = bad, .share_tsv = kShareTsv}).has_value(), "bảng thưởng cấp trùng bị từ chối");
    const std::string bad_share = "apprentice_rank\tmentor_exp_share\n1\t2.5\n";
    context.expect(!MentorTable::parse({.rewards_tsv = kRewardsTsv, .share_tsv = bad_share}).has_value(), "hệ số > 1 bị từ chối");
    expect_valid(context, world.book);
}

void pending_expiry_and_caps(Context& context) {
    World world(30);
    static_cast<void>(world.book.request(kNow, world.directory, BondKind::kFriend, cid(1), cid(2)));
    const Tick late = ids::advance(kNow, ids::TickSpan{60LL * 20});
    world.book.tick(late);
    context.expect(world.book.pending_count() == 0, "hết hạn thì xoá");
    context.expect(world.book.answer(late, world.directory, BondKind::kFriend, cid(2), cid(1), true).error == RelationError::kNoPending, "trả lời lời đã hết hạn");
    // Một người nhận tối đa 16 lời chờ.
    for (std::uint64_t sender = 2; sender <= 17; ++sender) {
        context.expect(world.book.request(kNow, world.directory, BondKind::kFriend, cid(sender), cid(1)).ok(), "trong trần");
    }
    context.expect(world.book.request(kNow, world.directory, BondKind::kFriend, cid(18), cid(1)).error == RelationError::kTooManyPending, "vượt trần");
    // Hỏi lại cùng người không cộng dồn.
    context.expect(world.book.request(kNow, world.directory, BondKind::kFriend, cid(2), cid(1)).ok(), "hỏi lại");
    context.expect(world.book.pending_count() == 16, "vẫn 16 lời");
    // Gỡ sổ xoá lời chờ liên quan.
    static_cast<void>(world.book.unload(cid(1)));
    context.expect(world.book.pending_count() == 0, "gỡ sổ xoá lời chờ");
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

void codec_golden_and_round_trip(Context& context) {
    RelationSheet sheet;
    sheet.mood = "ab";
    sheet.moral_point = 5;
    sheet.entries.push_back(social::RelationEntry{.id = cid(7), .name = "x", .kind = RelationKind::kFriend, .group = 2, .point = 300});
    social::Bytes bytes;
    context.expect(social::encode_relation(sheet, kNow, bytes).has_value(), "mã hoá");
    // Số vàng tính tay từ bố cục: đầu khung (độ dài thân 42, kind 0x5103, cờ 0), thân (phiên bản 1,
    // tâm trạng "ab", sư đức 5, chờ 0, một mục: id 7, tên "x", loại 1, nhóm 2, điểm 300, mốc 0).
    const auto golden = from_hex(
        "2a000000" "0351" "0000"
        "0100" "0200" "6162" "0500000000000000" "0000000000000000" "0100"
        "0700000000000000" "0100" "78" "01" "02" "2c010000" "00");
    context.expect(bytes == golden, "khớp số vàng");
    const auto back = social::decode_relation(bytes, kNow, sample_limits());
    context.expect(back.has_value() && back->mood == "ab" && back->moral_point == 5 && back->entries.size() == 1 &&
                       back->entries[0].id == cid(7) && back->entries[0].point == 300 && back->entries[0].group == 2,
        "giải mã trả đúng");
    // Thời hạn lưu theo số tick còn lại, nên nạp lại ở thời điểm khác vẫn đúng độ dài.
    sheet.betray_until = ids::advance(kNow, ids::TickSpan{500});
    social::Bytes with_wait;
    context.expect(social::encode_relation(sheet, kNow, with_wait).has_value(), "mã hoá có hạn chờ");
    const Tick restart{50};
    const auto reloaded = social::decode_relation(with_wait, restart, sample_limits());
    context.expect(reloaded.has_value() && reloaded->betray_until == Tick{550}, "hạn chờ tính lại theo mốc mới");
}

void codec_rejects_garbage(Context& context) {
    RelationSheet sheet;
    sheet.mood = "tốt";
    for (std::uint64_t index = 1; index <= 5; ++index) {
        sheet.entries.push_back(social::RelationEntry{
            .id = cid(index), .name = "bạn" + std::to_string(index), .kind = RelationKind::kFriend, .group = static_cast<std::uint8_t>(index % 4), .point = static_cast<std::int32_t>(index)});
    }
    social::Bytes bytes;
    context.expect(social::encode_relation(sheet, kNow, bytes).has_value(), "mã hoá");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        const std::span<const std::byte> view(bytes.data(), cut);
        every_cut_rejected = every_cut_rejected && !social::decode_relation(view, kNow, sample_limits()).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt đều bị từ chối");
    social::Bytes extra = bytes;
    extra.push_back(std::byte{0});
    context.expect(!social::decode_relation(extra, kNow, sample_limits()).has_value(), "byte thừa bị từ chối");
    // Lật từng byte một: không bao giờ sập; bản nào còn giải mã được phải qua kiểm miền.
    std::size_t decoded = 0;
    for (std::size_t index = 0; index < bytes.size(); ++index) {
        for (const unsigned flip : {0x01U, 0x80U, 0xFFU}) {
            social::Bytes copy = bytes;
            copy.at(index) = static_cast<std::byte>(static_cast<unsigned>(copy.at(index)) ^ flip);
            const auto result = social::decode_relation(copy, kNow, sample_limits());
            if (result.has_value()) ++decoded;
        }
    }
    context.expect(decoded < bytes.size() * 3, "không phải mọi lật đều lọt (văn bản, id, điểm có kiểm miền)");
    // Kind sai.
    social::Bytes wrong = bytes;
    wrong.at(4) = std::byte{0x04};
    context.expect(social::decode_relation(wrong, kNow, sample_limits()).error() == social::CodecError::kBadKind, "kind sai");
    // Phiên bản lạ.
    social::Bytes future = bytes;
    future.at(8) = std::byte{2};
    context.expect(social::decode_relation(future, kNow, sample_limits()).error() == social::CodecError::kBadVersion, "phiên bản lạ");
    // Hai mục trùng id bị từ chối.
    RelationSheet dup = sheet;
    dup.entries.push_back(dup.entries.front());
    social::Bytes dup_bytes;
    context.expect(social::encode_relation(dup, kNow, dup_bytes).has_value(), "mã hoá sổ trùng");
    context.expect(social::decode_relation(dup_bytes, kNow, sample_limits()).error() == social::CodecError::kBadValue, "trùng id bị từ chối");
    // Số mục báo to hơn thân thật.
    social::Bytes huge = bytes;
    huge.at(8 + 2 + 2 + 5 + 8 + 8) = std::byte{0xFF};
    huge.at(8 + 2 + 2 + 5 + 8 + 8 + 1) = std::byte{0xFF};
    context.expect(!social::decode_relation(huge, kNow, sample_limits()).has_value(), "số mục khổng lồ bị từ chối");
}

void load_rejects_bad_sheets(Context& context) {
    RelationBook book(sample_limits(), sample_relation_rules());
    RelationSheet sheet;
    sheet.entries.push_back(social::RelationEntry{.id = cid(1), .name = "tự mình", .kind = RelationKind::kFriend});
    context.expect(!book.load(cid(1), sheet).has_value(), "tự tham chiếu");
    sheet.entries.clear();
    sheet.entries.push_back(social::RelationEntry{.id = cid(2), .name = "a", .kind = RelationKind::kFriend, .point = 10'000});
    context.expect(!book.load(cid(1), sheet).has_value(), "điểm quá trần");
    sheet.entries.back().point = 5;
    sheet.entries.back().milestones = 1;
    context.expect(!book.load(cid(1), sheet).has_value(), "mốc thưởng ở mục bạn");
    sheet.entries.back().milestones = 0;
    sheet.entries.back().kind = RelationKind::kSpouse;
    sheet.entries.push_back(social::RelationEntry{.id = cid(3), .name = "b", .kind = RelationKind::kSpouse});
    context.expect(!book.load(cid(1), sheet).has_value(), "hai vợ chồng");
    sheet.entries.pop_back();
    context.expect(book.load(cid(1), sheet).has_value(), "một vợ/chồng hợp lệ");
    context.expect(!book.load(cid(0), RelationSheet{}).has_value(), "chủ sổ id 0");
}

constexpr std::array kCases{
    Case{.name = "friend_handshake", .body = friend_handshake},
    Case{.name = "friend_rejections", .body = friend_rejections},
    Case{.name = "capacity_rules", .body = capacity_rules},
    Case{.name = "remove_rules", .body = remove_rules},
    Case{.name = "blacklist_transition", .body = blacklist_transition},
    Case{.name = "enemy_and_temp_lists", .body = enemy_and_temp_lists},
    Case{.name = "mood_rules", .body = mood_rules},
    Case{.name = "points_and_presence", .body = points_and_presence},
    Case{.name = "marriage_rules", .body = marriage_rules},
    Case{.name = "master_prentice_flow", .body = master_prentice_flow},
    Case{.name = "leave_expel_and_cooldown", .body = leave_expel_and_cooldown},
    Case{.name = "mentor_rewards", .body = mentor_rewards},
    Case{.name = "pending_expiry_and_caps", .body = pending_expiry_and_caps},
    Case{.name = "codec_golden_and_round_trip", .body = codec_golden_and_round_trip},
    Case{.name = "codec_rejects_garbage", .body = codec_rejects_garbage},
    Case{.name = "load_rejects_bad_sheets", .body = load_rejects_bad_sheets},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
