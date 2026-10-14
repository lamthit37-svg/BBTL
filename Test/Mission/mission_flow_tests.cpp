// Máy trạng thái nhiệm vụ: nhận, tiến độ theo sự kiện, nộp, bỏ, hỏng, lặp theo ngày, tiền đề, và tính nguyên tử với sổ cái.
// Dữ liệu là thế giới nhỏ viết tay (support/mission_world.hpp) để mỗi ca nhìn ra ngay giá trị mong đợi; ca trên bảng thật
// nằm ở mission_data_tests.
#include "bus/bus.hpp"
#include "dice/dice.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "support/mission_data.hpp"
#include "support/mission_fakes.hpp"
#include "support/mission_world.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <print>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using mission::Engine;
using mission::Error;
using mission::NoticeKind;
using mission::Result;
namespace w = world;

mission::Catalog make_catalog() {
    MissionData data;
    w::fill(data);
    auto catalog = data.build();
    // Dữ liệu viết tay luôn nạp được: nếu không thì cả bộ test vô nghĩa, dừng ngay.
    if (!catalog) {
        std::print(stderr, "danh mục thử không nạp được: {} {}\n", catalog.error().table, catalog.error().detail);
        std::abort();
    }
    return std::move(*catalog);
}

struct Fixture {
    explicit Fixture(std::uint64_t seed = 7) : dice(seed), catalog(make_catalog()), engine(catalog, dice) {
        hero.level_value = 5;
        calendar.day = 100;
        calendar.week_time = 14;
        calendar.unix_seconds = 1'000'000;
    }
    dice::Dice dice;
    mission::Catalog catalog;
    Engine engine;
    FakeCharacter hero;
    ops::Calendar calendar;

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): mẫu quái và mã tên quái khác vai, nơi gọi nêu tên (HP-07)
    [[nodiscard]] bus::Event kill(std::uint32_t monster_template, std::uint32_t name = 0) const {
        bus::Event event;
        event.kind = bus::Kind::kKill;
        event.hero = hero.id();
        event.a = monster_template;
        event.b = static_cast<std::uint32_t>(w::kSceneId);
        event.name = name;
        return event;
    }
    [[nodiscard]] bus::Event talk(std::uint32_t guid) const {
        bus::Event event;
        event.kind = bus::Kind::kTalk;
        event.hero = hero.id();
        event.a = guid;
        event.b = static_cast<std::uint32_t>(w::kSceneId);
        return event;
    }
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cảnh và vùng khác vai, nơi gọi nêu tên (HP-07)
    [[nodiscard]] bus::Event area(std::uint32_t scene, std::uint32_t area_id) const {
        bus::Event event;
        event.kind = bus::Kind::kEnterArea;
        event.hero = hero.id();
        event.a = scene;
        event.b = area_id;
        return event;
    }
    [[nodiscard]] bus::Event items(std::uint32_t item) const {
        bus::Event event;
        event.kind = bus::Kind::kItemChanged;
        event.hero = hero.id();
        event.a = item;
        return event;
    }
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cấp mới và cấp trước khác vai, nơi gọi nêu tên (HP-07)
    [[nodiscard]] bus::Event level_up(std::uint32_t now, std::int32_t before) const {
        bus::Event event;
        event.kind = bus::Kind::kLevelUp;
        event.hero = hero.id();
        event.a = now;
        event.c = before;
        return event;
    }
    mission::Outcome send(const bus::Event& event) { return engine.handle(hero, event, calendar); }
    Result accept(std::int32_t quest) { return engine.accept(hero, quest, calendar); }
    Result turn_in(std::int32_t quest, std::int32_t choice = -1) { return engine.turn_in(hero, quest, choice, calendar); }
};

bool has(const mission::Outcome& out, NoticeKind kind) {
    return std::ranges::any_of(out.notices, [kind](const mission::Notice& one) { return one.kind == kind; });
}

bool has(const Result& result, NoticeKind kind) { return result.has_value() && has(*result, kind); }

bool failed_with(const Result& result, Error error) { return !result.has_value() && result.error().error == error; }

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): nhiệm vụ và chỉ số tham số khác vai, nơi gọi nêu tên (HP-07)
std::uint32_t param(const FakeCharacter& hero, std::int32_t quest, std::size_t index) {
    const mission::Slot* const slot = hero.book().find(quest);
    return slot == nullptr ? 0xFFFFFFFFU : slot->params.at(index);
}

void accept_checks_in_order(Context& context) {
    Fixture f;
    f.hero.level_value = 3;
    context.expect(failed_with(f.accept(w::kKillQuest), Error::kLevelTooLow), "cấp 3 < 5");
    f.hero.level_value = 5;
    context.expect(failed_with(f.accept(w::kPostQuest), Error::kPrerequisite), "chưa xong nhiệm vụ 10");
    const Result accepted = f.accept(w::kKillQuest);
    context.expect(accepted.has_value() && accepted->quest == w::kKillQuest && accepted->script == w::kKillScript, "nhận được");
    context.expect(has(accepted, NoticeKind::kAdded), "báo vào sổ");
    const mission::Slot* const slot = f.hero.book().find(w::kKillQuest);
    context.expect(slot != nullptr && std::cmp_equal(slot->script, w::kKillScript) &&
                       slot->flags == mission::kWatchKill && slot->params.at(0) == 0,
        "ô có script, cờ theo dõi giết quái, chưa sẵn sàng");
    context.expect(failed_with(f.accept(w::kKillQuest), Error::kAlreadyActive), "đang làm");
    context.expect(failed_with(f.accept(99), Error::kUnknownQuest), "id lạ");
    context.expect(failed_with(f.accept(w::kCycleA), Error::kNotRunnable), "vòng tiền đề bị chặn");
    context.expect(failed_with(f.accept(w::kOutsideQuest), Error::kNotRunnable), "ngoài client");
    context.expect(failed_with(f.accept(w::kEscortQuest), Error::kNotRunnable), "hộ tống chưa có bộ chạy");
    context.expect(failed_with(f.accept(52), Error::kNotRunnable), "script cần xử lý tay");
    for (std::int32_t quest = 100; quest < 120; ++quest) static_cast<void>(f.hero.book().add(quest, quest, 0));
    f.hero.book().remove(100);
    f.hero.book().add(120, 120, 0);
    context.expect(failed_with(f.accept(w::kAreaQuest), Error::kBookFull), "đủ 20 ô");
}

void classification_is_reported(Context& context) {
    const Fixture f;
    const mission::Report& report = f.catalog.report();
    const mission::Quest* const cycle = f.catalog.by_script(4000);
    context.expect(cycle != nullptr && cycle->support == mission::Support::kBlocked, "vòng tiền đề -> chặn");
    context.expect(f.catalog.by_script(4001)->support == mission::Support::kBlocked, "cả hai đầu vòng");
    context.expect(f.catalog.by_script(4100)->support == mission::Support::kNotInClient, "ngoài client");
    context.expect(f.catalog.by_script(4200)->support == mission::Support::kUnsupported &&
                       f.catalog.by_script(4200)->reason == "cần xử lý tay",
        "giữ nguyên lý do của bảng trích");
    const mission::Quest* const escort = f.catalog.by_script(4300);
    context.expect(escort != nullptr && escort->support == mission::Support::kUnsupported &&
                       escort->reason.find("hộ tống") != std::string::npos,
        "hộ tống ghi lý do");
    context.expect(report.blocked == 2 && report.not_in_client == 1 && report.unsupported == 2, "đếm theo loại");
    context.expect(report.runnable + report.blocked + report.not_in_client + report.unsupported == report.quests, "đếm đủ");
    const auto cycle_reason = std::ranges::find(report.reasons, "chuỗi tiền đề có vòng", &std::pair<std::string, std::size_t>::first);
    context.expect(cycle_reason != report.reasons.end() && cycle_reason->second == 2, "đếm theo lý do");
    context.expect(f.catalog.variants(w::kRingQuest).size() == 4, "bốn biến thể của nhiệm vụ vòng");
    context.expect(f.catalog.group_of_template(w::kWolfTemplate) == static_cast<std::uint32_t>(w::wolf()), "mẫu quái -> nhóm tên");
    context.expect(f.catalog.group_of_template(12345) == 0, "mẫu lạ không có nhóm");
}

void kill_quest_full_cycle(Context& context) {
    Fixture f;
    context.expect(f.accept(w::kKillQuest).has_value(), "nhận");
    context.expect(failed_with(f.turn_in(w::kKillQuest, 5002), Error::kNotReady), "chưa đủ quái");
    const mission::Outcome first = f.send(f.kill(w::kWolfTemplate));
    context.expect(param(f.hero, w::kKillQuest, 1) == 1 && has(first, NoticeKind::kUpdated) && !has(first, NoticeKind::kReady),
        "con đầu");
    context.expect(f.send(f.kill(w::kBearTemplate)).notices.empty() && param(f.hero, w::kKillQuest, 1) == 1, "quái khác nhóm không tính");
    static_cast<void>(f.send(f.kill(w::kWolfTemplate)));
    const mission::Outcome third = f.send(f.kill(w::kWolfTemplate));
    context.expect(param(f.hero, w::kKillQuest, 1) == 3 && param(f.hero, w::kKillQuest, 0) == 1 && has(third, NoticeKind::kReady),
        "con thứ ba bật cờ sẵn sàng");
    static_cast<void>(f.send(f.kill(w::kWolfTemplate)));
    context.expect(param(f.hero, w::kKillQuest, 1) == 3, "không vượt số cần");

    context.expect(failed_with(f.turn_in(w::kKillQuest, -1), Error::kNeedChoice), "phải chọn thưởng");
    context.expect(failed_with(f.turn_in(w::kKillQuest, 9999), Error::kBadChoice), "chọn món không có");
    const mission::Book before = f.hero.book();
    context.expect(before.ledger_seq == 0, "thất bại không tiêu mã yêu cầu");
    const Result done = f.turn_in(w::kKillQuest, 5002);
    context.expect(done.has_value(), "nộp");
    if (!done) return;
    FakeCharacter& hero = f.hero;
    context.expect(hero.bundle.exp.total == 100 && hero.bundle.wallet.normal == 50 && hero.bundle.wallet.locked == 20, "exp và tiền");
    context.expect(hero.have(4001) == 2 && hero.have(5002) == 1 && hero.have(5001) == 0 && hero.have(6001) == 1,
        "đồ cố định, đồ đã chọn và đồ ẩn");
    context.expect(hero.book().counter(w::kRelation) == 3, "điểm quan hệ");
    context.expect(hero.book().find(w::kKillQuest) == nullptr && hero.book().is_done(w::kKillQuest), "ra khỏi sổ và đánh dấu xong");
    context.expect(done->receipt.committed() && hero.book().ledger_seq == 1 && !done->receipt.replayed, "một giao dịch sổ cái");
    context.expect(has(*done, NoticeKind::kRewardExp) && has(*done, NoticeKind::kRewardItem) && has(*done, NoticeKind::kDone) &&
                       has(*done, NoticeKind::kRemoved) && has(*done, NoticeKind::kRelation),
        "báo đủ cho client");
    context.expect(failed_with(f.turn_in(w::kKillQuest, 5002), Error::kNotActive), "nộp lần hai");
    context.expect(failed_with(f.accept(w::kKillQuest), Error::kAlreadyDone), "không nhận lại nhiệm vụ một lần");
}

void delivery_quest(Context& context) {
    Fixture f;
    context.expect(failed_with(f.accept(w::kPostQuest), Error::kPrerequisite), "cần nhiệm vụ 10");
    f.hero.book().mark_done(w::kKillQuest);
    const Result accepted = f.accept(w::kPostQuest);
    context.expect(accepted.has_value() && accepted->receipt.committed(), "nhận, nhiệm vụ cấp thư qua sổ cái");
    context.expect(f.hero.have(7001) == 2, "đã được cấp 2 thư");
    context.expect(param(f.hero, w::kPostQuest, 2) == 2 && param(f.hero, w::kPostQuest, 1) == 0 && param(f.hero, w::kPostQuest, 0) == 0,
        "thư đủ nhưng chưa gặp người nhận");
    context.expect(f.send(f.talk(501)).notices.empty(), "nói chuyện nhầm người");
    const mission::Outcome talked = f.send(f.talk(static_cast<std::uint32_t>(w::kCourier)));
    context.expect(param(f.hero, w::kPostQuest, 1) == 1 && param(f.hero, w::kPostQuest, 0) == 1 && has(talked, NoticeKind::kReady),
        "gặp người nhận -> sẵn sàng");
    f.hero.bundle.items.total[7001] = 1;
    const mission::Outcome lost = f.send(f.items(7001));
    context.expect(param(f.hero, w::kPostQuest, 0) == 0 && param(f.hero, w::kPostQuest, 2) == 1 && has(lost, NoticeKind::kUpdated),
        "mất thư thì cờ sẵn sàng tụt");
    context.expect(failed_with(f.turn_in(w::kPostQuest), Error::kNotReady), "thiếu thư không nộp được");
    f.hero.bundle.items.total[7001] = 2;
    static_cast<void>(f.send(f.items(7001)));
    context.expect(param(f.hero, w::kPostQuest, 0) == 1, "đủ lại thì sẵn sàng");
    const Result done = f.turn_in(w::kPostQuest);
    context.expect(done.has_value() && f.hero.have(7001) == 0 && f.hero.bundle.exp.total == 200, "nộp thu thư và trả thưởng");
}

void loot_quest(Context& context) {
    Fixture f;
    context.expect(f.accept(w::kLootQuest).has_value(), "nhận");
    const mission::Outcome one = f.send(f.kill(w::kBearTemplate));
    context.expect(f.hero.have(8001) == 1 && param(f.hero, w::kLootQuest, 1) == 1 && one.receipt.committed(), "rơi 100%");
    static_cast<void>(f.send(f.kill(w::kBearTemplate)));
    context.expect(f.hero.have(8001) == 2 && param(f.hero, w::kLootQuest, 0) == 1, "đủ 2 mật gấu thì sẵn sàng");
    static_cast<void>(f.send(f.kill(w::kBearTemplate)));
    context.expect(f.hero.have(8001) == 2, "đủ rồi không rơi thêm");
    context.expect(f.turn_in(w::kLootQuest).has_value() && f.hero.have(8001) == 0, "nộp thu đồ nhiệm vụ");

    Fixture full;
    context.expect(full.accept(w::kLootQuest).has_value(), "nhận");
    full.hero.bundle.items.capacity = 0;
    const mission::Outcome blocked = full.send(full.kill(w::kBearTemplate));
    const bool tip = std::ranges::any_of(blocked.notices, [](const mission::Notice& notice) {
        return notice.kind == NoticeKind::kText && notice.text.id == ops::string_id("GCPickResultHandler_Info_package_Full");
    });
    context.expect(tip && full.hero.have(8001) == 0, "túi đầy: báo và không mất gì");
}

void area_quest(Context& context) {
    Fixture f;
    context.expect(f.accept(w::kAreaQuest).has_value(), "nhận");
    context.expect((f.hero.book().find(w::kAreaQuest)->flags & mission::kWatchArea) != 0, "theo dõi vào vùng");
    static_cast<void>(f.send(f.area(w::kSceneId, 8)));
    static_cast<void>(f.send(f.area(2, w::kAreaId)));
    context.expect(param(f.hero, w::kAreaQuest, 0) == 0, "sai vùng hoặc sai cảnh");
    const mission::Outcome in = f.send(f.area(w::kSceneId, w::kAreaId));
    context.expect(has(in, NoticeKind::kReady) && param(f.hero, w::kAreaQuest, 0) == 1, "đúng vùng");
    context.expect(f.turn_in(w::kAreaQuest).has_value() && f.hero.bundle.exp.total == 30, "nộp");
}

void ring_variants_follow_level(Context& context) {
    {
        Fixture f(1);
        f.hero.level_value = 5;
        const auto before = f.dice.state();
        const Result low = f.accept(w::kRingQuest);
        context.expect(low.has_value() && low->script == w::kRingLow, "cấp 5 chỉ đủ biến thể cấp 1");
        context.expect(f.dice.state() == before, "một ứng viên thì không tiêu ngẫu nhiên");
    }
    {
        Fixture f(1);
        f.hero.level_value = 40;
        const Result high = f.accept(w::kRingQuest);
        context.expect(high.has_value() && high->script == w::kRingHigh, "cấp 40 lấy biến thể cấp cao nhất");
    }
    bool saw_mid = false;
    bool saw_twin = false;
    for (std::uint64_t seed = 1; seed <= 40; ++seed) {
        Fixture f(seed);
        f.hero.level_value = 12;
        const Result chosen = f.accept(w::kRingQuest);
        context.expect(chosen.has_value() && (chosen->script == w::kRingMid || chosen->script == w::kRingMidTwin), "cặp ngang cấp");
        if (!chosen) continue;
        saw_mid = saw_mid || chosen->script == w::kRingMid;
        saw_twin = saw_twin || chosen->script == w::kRingMidTwin;
        Fixture again(seed);
        again.hero.level_value = 12;
        context.expect(again.accept(w::kRingQuest)->script == chosen->script, "cùng hạt giống cùng lựa chọn");
    }
    context.expect(saw_mid && saw_twin, "cả hai biến thể ngang cấp đều có lúc được chọn");
}

void abandon_penalty_and_ban(Context& context) {
    Fixture f(3);
    f.hero.level_value = 5;
    static_cast<void>(f.hero.book().set_counter(w::kRelation, 5));
    context.expect(f.accept(w::kRingQuest).has_value(), "nhận");
    const Result left = f.engine.abandon(f.hero, w::kRingQuest, f.calendar);
    context.expect(left.has_value() && has(left, NoticeKind::kRemoved), "bỏ");
    context.expect(f.hero.book().counter(w::kRelation) == 3, "phạt 2 điểm quan hệ");
    context.expect(f.hero.book().counter(w::kBanSlot) == f.calendar.unix_seconds + 900, "đặt thời gian cấm nhận lại");
    context.expect(failed_with(f.accept(w::kRingQuest), Error::kBanned), "đang bị cấm");
    f.calendar.unix_seconds += 899;
    context.expect(failed_with(f.accept(w::kRingQuest), Error::kBanned), "còn 1 giây");
    f.calendar.unix_seconds += 2;
    context.expect(f.accept(w::kRingQuest).has_value(), "hết cấm");
    static_cast<void>(f.hero.book().set_counter(w::kRelation, 1));
    context.expect(f.engine.abandon(f.hero, w::kRingQuest, f.calendar).has_value() && f.hero.book().counter(w::kRelation) == 0,
        "điểm quan hệ không xuống dưới 0");
    f.calendar.unix_seconds += 10'000;
    context.expect(f.accept(w::kRingQuest).has_value(), "nhận lại sau khi hết cấm");
    const Result failed = f.engine.fail(f.hero, w::kRingQuest, f.calendar);
    context.expect(failed.has_value() && has(failed, NoticeKind::kFailed), "hỏng báo kFailed");
    context.expect(f.hero.book().counter(w::kBanSlot) == f.calendar.unix_seconds - 10'000 + 900, "hỏng không đặt lại thời gian cấm");
    context.expect(f.accept(w::kRingQuest).has_value(), "hỏng thì nhận lại ngay");
    context.expect(failed_with(f.engine.abandon(f.hero, 77, f.calendar), Error::kNotActive), "bỏ nhiệm vụ không có");
}

void daily_script_quest(Context& context) {
    Fixture f;
    f.hero.level_value = 2;
    context.expect(failed_with(f.accept(w::kDailyQuest), Error::kCondition), "cấp 2 không đạt điều kiện script");
    f.hero.level_value = 3;
    const Result accepted = f.accept(w::kDailyQuest);
    context.expect(accepted.has_value(), "cấp 3, chưa làm hôm nay");
    if (!accepted) return;
    const bool welcome = std::ranges::any_of(accepted->notices, [](const mission::Notice& one) {
        return one.kind == NoticeKind::kText && one.text.id == ops::string_id("lua.daily.accept") &&
               one.text.params.size() == 1 && one.text.params[0].kind == ops::TextParam::Kind::kPlayer;
    });
    context.expect(welcome, "hiệu ứng nhận: thông báo có mã chuỗi và tham số kiểu người chơi");
    context.expect(std::cmp_equal(f.hero.book().find(w::kDailyQuest)->script, w::kDailyScript) &&
                       (f.hero.book().find(w::kDailyQuest)->flags & mission::kWatchKill) != 0,
        "ô theo dõi giết quái do hook");
    const std::uint32_t wolf_name = ops::name_id("狼");
    static_cast<void>(f.send(f.kill(w::kBearTemplate, ops::name_id("熊"))));
    context.expect(param(f.hero, w::kDailyQuest, 1) == 0, "quái khác tên: hook không chạy");
    static_cast<void>(f.send(f.kill(w::kWolfTemplate, wolf_name)));
    context.expect(failed_with(f.turn_in(w::kDailyQuest), Error::kNotReady), "mới 1/2");
    static_cast<void>(f.send(f.kill(w::kWolfTemplate, wolf_name)));
    context.expect(param(f.hero, w::kDailyQuest, 1) == 2, "hook cộng tiến độ");
    const Result done = f.turn_in(w::kDailyQuest);
    context.expect(done.has_value() && f.hero.bundle.wallet.normal == 15 && f.hero.bundle.exp.total == 7, "thưởng + hiệu ứng nộp");
    context.expect(f.hero.book().counter(w::kDailySlot) == 100 && !f.hero.book().is_done(w::kDailyQuest),
        "ghi ngày làm cuối, nhiệm vụ lặp nên không đánh dấu xong");
    context.expect(failed_with(f.accept(w::kDailyQuest), Error::kCondition), "cùng ngày không nhận lại");
    f.calendar.day = 101;
    context.expect(f.accept(w::kDailyQuest).has_value(), "sang ngày mới nhận lại được");
    const Result gave_up = f.engine.abandon(f.hero, w::kDailyQuest, f.calendar);
    const bool farewell = gave_up.has_value() && std::ranges::any_of(gave_up->notices, [](const mission::Notice& one) {
        return one.kind == NoticeKind::kText && one.text.id == ops::string_id("lua.daily.abandon");
    });
    context.expect(farewell, "hiệu ứng bỏ chạy");
}

void ledger_failures_leave_everything_unchanged(Context& context) {
    Fixture f;
    context.expect(f.accept(w::kKillQuest).has_value(), "nhận");
    for (int round = 0; round < 3; ++round) static_cast<void>(f.send(f.kill(w::kWolfTemplate)));
    const mission::Book book_before = f.hero.book();
    f.hero.bundle.items.capacity = 0;
    const Result full = f.turn_in(w::kKillQuest, 5001);
    context.expect(!full.has_value() && full.error().error == Error::kLedger && full.error().ledger == ledger::Reason::kNoRoom, "túi đầy");
    context.expect(f.hero.book() == book_before, "Book không đổi, kể cả nhật ký và mã yêu cầu");
    context.expect(f.hero.bundle.exp.total == 0 && f.hero.bundle.wallet.normal == 0, "ví và kinh nghiệm không đổi");
    f.hero.bundle.items.capacity = 30;
    f.hero.bundle.items.operations = 0;
    f.hero.bundle.items.fail_after = 2;
    const Result broken = f.turn_in(w::kKillQuest, 5001);
    context.expect(!broken.has_value() && broken.error().ledger == ledger::Reason::kPortFailure, "cổng lỗi giữa chừng");
    context.expect(f.hero.book() == book_before && f.hero.have(4001) == 0 && f.hero.have(5001) == 0 && f.hero.bundle.wallet.locked == 0,
        "quay lui sạch");
    f.hero.bundle.items.fail_after = -1;
    const Result fine = f.turn_in(w::kKillQuest, 5001);
    context.expect(fine.has_value() && f.hero.book().ledger_seq == 1, "thử lại thành công và dùng lại mã yêu cầu chưa tiêu");
}

void level_events_auto_accept_and_complete(Context& context) {
    Fixture f;
    f.hero.level_value = 3;
    const mission::Outcome up = f.send(f.level_up(3, 2));
    context.expect(has(up, NoticeKind::kAdded) && f.hero.book().find(w::kAutoQuest) != nullptr, "đúng cấp 3 thì tự nhận");
    context.expect(f.send(f.level_up(3, 2)).notices.empty(), "đã giữ thì không nhận lại");

    Fixture jump;
    jump.hero.level_value = 5;
    context.expect(has(jump.send(jump.level_up(5, 1)), NoticeKind::kAdded) && jump.hero.book().find(w::kAutoQuest) != nullptr,
        "nhảy từ 1 lên 5 vẫn qua mốc 3");
    jump.hero.book().remove(w::kAutoQuest);
    jump.hero.book().mark_done(w::kAutoQuest);
    static_cast<void>(jump.send(jump.level_up(3, 2)));
    context.expect(jump.hero.book().find(w::kAutoQuest) == nullptr, "đã xong thì không tự nhận lại");

    Fixture milestone;
    milestone.hero.level_value = 4;
    context.expect(milestone.engine.accept_script(milestone.hero, w::kMilestoneScript, milestone.calendar).has_value(), "nhận mốc");
    static_cast<void>(milestone.send(milestone.level_up(4, 3)));
    context.expect(param(milestone.hero, w::kMilestoneQuest, 0) == 0, "chưa tới cấp 5");
    milestone.hero.level_value = 5;
    const mission::Outcome reached = milestone.send(milestone.level_up(5, 4));
    context.expect(param(milestone.hero, w::kMilestoneQuest, 0) == 1 && param(milestone.hero, w::kMilestoneQuest, 1) == 1,
        "tới cấp 5: đánh dấu hoàn thành");
    const bool tip = std::ranges::any_of(reached.notices, [](const mission::Notice& one) {
        return one.kind == NoticeKind::kText && one.text.id == ops::string_id("YD_20080421_188");
    });
    context.expect(tip, "thông báo theo khoá chuỗi của bảng");
    context.expect(milestone.send(milestone.level_up(5, 4)).notices.empty(), "không đánh dấu lần hai");
}

void bus_order_does_not_change_outcome(Context& context) {
    const auto run = [&context](bool shuffled, mission::Book& result) {
        Fixture f;
        context.expect(f.accept(w::kKillQuest).has_value() && f.accept(w::kLootQuest).has_value() && f.accept(w::kAreaQuest).has_value(),
            "nhận đủ ba nhiệm vụ trước khi phát sự kiện");
        bus::Bus bus(32);
        std::vector<bus::Event> events{f.kill(w::kWolfTemplate), f.kill(w::kBearTemplate), f.area(w::kSceneId, w::kAreaId),
            f.kill(w::kWolfTemplate), f.items(8001), f.kill(w::kBearTemplate), f.kill(w::kWolfTemplate)};
        if (shuffled) {
            // Đảo thứ tự phát giữa các loại sự kiện (cùng loại giữ nguyên thứ tự tương đối).
            std::ranges::stable_sort(events, [](const bus::Event& left, const bus::Event& right) {
                return static_cast<int>(left.kind) > static_cast<int>(right.kind);
            });
        }
        for (const bus::Event& event : events) static_cast<void>(bus.publish(event));
        for (const bus::Event& event : bus.take()) static_cast<void>(f.send(event));
        result = f.hero.book();
    };
    mission::Book plain;
    mission::Book shuffled;
    run(false, plain);
    run(true, shuffled);
    context.expect(plain == shuffled, "thứ tự phát khác nhau giữa các loại cho cùng sổ cuối");
}

void stale_or_mismatched_slots_are_inert(Context& context) {
    Fixture f;
    static_cast<void>(f.hero.book().add(77, 999999, mission::kWatchMask));  // script đã biến mất khỏi dữ liệu
    static_cast<void>(f.hero.book().add(10, static_cast<std::int32_t>(w::kPostScript), mission::kWatchMask));  // script của nhiệm vụ khác
    const mission::Book before = f.hero.book();
    context.expect(f.send(f.kill(w::kWolfTemplate)).notices.empty() && f.hero.book() == before, "sự kiện không đụng ô lạ");
    context.expect(failed_with(f.turn_in(77), Error::kNotRunnable), "không nộp được ô mồ côi");
    context.expect(failed_with(f.turn_in(10), Error::kNotRunnable), "script không khớp nhiệm vụ");
    const Result removed = f.engine.abandon(f.hero, 77, f.calendar);
    context.expect(removed.has_value() && f.hero.book().find(77) == nullptr, "bỏ ô mồ côi được và dọn sạch");
}

constexpr std::array kCases{
    Case{.name = "accept_checks_in_order", .body = accept_checks_in_order},
    Case{.name = "classification_is_reported", .body = classification_is_reported},
    Case{.name = "kill_quest_full_cycle", .body = kill_quest_full_cycle},
    Case{.name = "delivery_quest", .body = delivery_quest},
    Case{.name = "loot_quest", .body = loot_quest},
    Case{.name = "area_quest", .body = area_quest},
    Case{.name = "ring_variants_follow_level", .body = ring_variants_follow_level},
    Case{.name = "abandon_penalty_and_ban", .body = abandon_penalty_and_ban},
    Case{.name = "daily_script_quest", .body = daily_script_quest},
    Case{.name = "ledger_failures_leave_everything_unchanged", .body = ledger_failures_leave_everything_unchanged},
    Case{.name = "level_events_auto_accept_and_complete", .body = level_events_auto_accept_and_complete},
    Case{.name = "bus_order_does_not_change_outcome", .body = bus_order_does_not_change_outcome},
    Case{.name = "stale_or_mismatched_slots_are_inert", .body = stale_or_mismatched_slots_are_inert},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
