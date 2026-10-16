// Hội thoại do máy chủ giữ: mở phiên, lựa chọn tính lại ở trạng thái hiện tại, phiên cũ bị từ chối, đóng khi xa / đổi cảnh / quá hạn /
// NPC biến mất, nhận và nộp nhiệm vụ qua phiên, nhiệm vụ kế, handler viết tay, và các khối hỏng không làm treo hay tràn ngăn xếp.
// Dữ liệu là thế giới nhỏ viết tay (support/talk_world.hpp); ca trên bảng thật nằm ở talk_data_tests.
#include "bus/bus.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "support/mission_fakes.hpp"
#include "support/mission_world.hpp"
#include "support/talk_data.hpp"
#include "support/talk_world.hpp"
#include "talk/service.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <vector>

namespace game::test {
namespace {

namespace w = world;
using talk::Error;
using talk::Stage;

struct Fixture {
    explicit Fixture(std::span<const talk::HandlerSpec> handlers = {}, bool extra_quests = false)
        : catalog(make_catalog(extra_quests)), script(make_script(catalog)), dice(5), engine(catalog, dice),
          service(script, engine, handlers, talk::Options{}) {
        hero.level_value = 5;
        calendar.day = 100;
        calendar.unix_seconds = 1'000'000;
        npc = talk::NpcRef{static_cast<std::uint32_t>(w::kElder), w::kSceneId, ops::name_id("老人"), talkw::kNpcScript};
    }

    static TalkData data(bool extra_quests) {
        TalkData built;
        talkw::fill(built);
        // Trưởng làng giao và nhận thêm các nhiệm vụ khác của thế giới thử (bốn dòng của nhiệm vụ vòng cùng một id nhiệm vụ).
        for (const std::uint32_t script : {w::kLootScript, w::kAreaScript, w::kRingLow, w::kRingMid, w::kRingMidTwin, w::kRingHigh, w::kAutoScript}) {
            built.npc(script, "give", w::kElder, w::kSceneId);
            built.npc(script, "turn", w::kElder, w::kSceneId);
        }
        if (extra_quests) {
            // Chuỗi nhiệm vụ cùng trưởng làng: 70 -> 71, nộp 70 thì mời tiếp 71.
            built.quest({.script = 7100, .quest = 70, .level = 1, .accept_guid = w::kElder, .turn_guid = w::kElder, .next_script = 7101});
            built.objective(7100, 0, "area", 0, w::kAreaId, 1, 0, 0, w::kSceneId);
            built.reward(7100, 0, "fixed", "exp", 0, 5);
            built.npc(7100, "give", w::kElder, w::kSceneId);
            built.npc(7100, "turn", w::kElder, w::kSceneId);
            built.quest({.script = 7101, .quest = 71, .level = 1, .accept_guid = w::kElder, .turn_guid = w::kElder});
            built.objective(7101, 0, "area", 0, w::kAreaId, 1, 0, 0, w::kSceneId);
            built.reward(7101, 0, "fixed", "exp", 0, 7);
            built.prereq(7101, 70);
        }
        return built;
    }

    static mission::Catalog make_catalog(bool extra_quests) {
        auto built = data(extra_quests).build();
        if (!built) {
            std::print(stderr, "danh mục thử không nạp được: {} {}\n", built.error().table, built.error().detail);
            std::abort();
        }
        return std::move(*built);
    }

    static talk::Script make_script(const mission::Catalog& catalog) {
        // Cùng dữ liệu hai lần dựng: bảng hội thoại không phụ thuộc phần nhiệm vụ thêm vào.
        auto built = data(false).build_script(catalog);
        if (!built) {
            std::print(stderr, "chương trình hội thoại thử không nạp được: {} {}\n", built.error().table,
                built.error().detail);
            std::abort();
        }
        return std::move(*built);
    }

    mission::Catalog catalog;
    talk::Script script;
    dice::Dice dice;
    mission::Engine engine;
    talk::Service service;
    FakeCharacter hero;
    ops::Calendar calendar;
    FakeTalkWorld world_view;
    talk::NpcRef npc;
    ids::Tick now{100};

    talk::Result talk() { return service.talk(hero, npc, world_view, now, calendar); }
    talk::Result choose(talk::SessionId session, std::uint32_t index) { return service.choose(hero, session, index, world_view, now, calendar); }
    talk::Result accept(talk::SessionId session, std::int32_t quest) { return service.accept(hero, session, quest, world_view, now, calendar); }
    talk::Result turn_in(talk::SessionId session, std::int32_t quest, std::int32_t pick = -1) {
        return service.turn_in(hero, session, quest, pick, world_view, now, calendar);
    }
};

bool has_mark(const talk::View& view, std::int32_t quest, Stage stage) {
    return std::ranges::find(view.marks, talk::Mark{quest, stage}) != view.marks.end();
}

bool bonus_is(const talk::Bonus& bonus, talk::BonusKind kind, std::int32_t a, std::int32_t b) {
    return bonus.kind == kind && bonus.a == a && bonus.b == b;
}

bool has_bonus(const talk::View& view, talk::BonusKind kind, std::int32_t a, std::int32_t b) {
    for (const talk::Bonus& bonus : view.bonuses) {
        if (bonus_is(bonus, kind, a, b)) return true;
    }
    return false;
}

bool failed_with(const talk::Result& result, Error error) { return !result.has_value() && result.error().error == error; }

std::int32_t choice_of(const talk::View& view, std::uint32_t text) {
    for (const talk::Choice& one : view.choices) {
        if (one.text.id == text) return one.index;
    }
    return -1;
}

void open_builds_the_first_dialogue(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    context.expect(opened.has_value(), "mở được");
    if (!opened) return;
    const talk::View& view = opened->view;
    context.expect(opened->session.value() != 0 && !opened->closed, "có mã phiên");
    context.expect(view.mode == talk::Mode::kList && view.lines.size() == 1 && view.lines[0].text.id == talkw::id("lua.hello"),
        "lời chào dùng mã chuỗi, không gửi chữ");
    context.expect(view.lines[0].text.params.size() == 1 && view.lines[0].text.params[0].kind == ops::TextParam::Kind::kPlayer,
        "tham số có kiểu: tên người chơi");
    // Cấp 5: không có lựa chọn của cấp 10; có lựa chọn thường theo thứ tự trong script, chỉ số liền từ 0.
    context.expect(choice_of(view, talkw::id("lua.vet")) == -1, "lựa chọn cấp 10 ẩn ở cấp 5");
    context.expect(view.choices.size() == 10, "mười lựa chọn thường");
    for (std::size_t i = 0; i < view.choices.size(); ++i) context.expect(view.choices[i].index == i, "chỉ số liền");
    // Dấu nhiệm vụ của bảng tại NPC theo cấp 5: giết quái, loot, vào vùng, vòng, tự nhận. Đưa thư cần xong giết quái nên chưa có.
    for (const std::int32_t quest : {w::kKillQuest, w::kLootQuest, w::kAreaQuest, w::kRingQuest, w::kAutoQuest}) {
        context.expect(has_mark(view, quest, Stage::kAvailable), "nhiệm vụ nhận được có dấu");
    }
    context.expect(!has_mark(view, w::kPostQuest, Stage::kAvailable), "thiếu tiền đề thì không có dấu");
    context.expect(view.marks.size() == 5 && std::ranges::is_sorted(view.marks, {}, &talk::Mark::quest), "dấu theo id nhiệm vụ, không trùng");
    context.expect(f.service.open_sessions() == 1 && f.service.session_of(f.hero.id()) == opened->session, "phiên được giữ");
    // Cấp 12: lựa chọn riêng của cấp 10 xuất hiện ở chỗ nhánh đặt nó (trước các lựa chọn thường).
    Fixture high;
    high.hero.level_value = 12;
    const talk::Result veteran = high.talk();
    context.expect(veteran.has_value() && veteran->view.choices.size() == 11 && veteran->view.choices[0].text.id == talkw::id("lua.vet"),
        "lựa chọn cấp 10 hiện ở cấp 12, đứng đầu");
}

void unsupported_and_empty_npcs(Context& context) {
    Fixture f;
    f.npc.script = 0;
    f.npc.guid = 99999;  // NPC không có việc nào trong danh mục
    context.expect(failed_with(f.talk(), Error::kNoDialog), "NPC không script, không nhiệm vụ: không có hội thoại");
    context.expect(f.service.open_sessions() == 0, "lỗi mở không để lại phiên");
    // NPC không script nhưng có nhiệm vụ bảng: chỉ có dấu nhiệm vụ.
    Fixture quest_only;
    quest_only.npc.script = 0;
    const talk::Result marks = quest_only.talk();
    context.expect(marks.has_value() && marks->view.lines.empty() && !marks->view.marks.empty(), "chỉ có dấu nhiệm vụ");
    // Điểm vào chưa trích được hay không có hội thoại: không có hộp thoại để vẽ.
    const auto reasons = f.script.report().reasons;
    context.expect(f.script.report().unsupported == 1 && f.script.report().no_dialog == 1 && reasons.size() == 1 &&
                       reasons.begin()->first.find("LuaFnGetCopySceneData_Param") != std::string::npos,
        "báo cáo đếm điểm vào không chạy được kèm lý do");
}

void session_ids_are_strictly_increasing_and_stale_ones_refused(Context& context) {
    Fixture f;
    const talk::Result first = f.talk();
    const talk::Result second = f.talk();
    context.expect(first.has_value() && second.has_value() && second->session.value() > first->session.value(),
        "mã phiên tăng ngặt");
    if (!first || !second) return;
    context.expect(f.service.open_sessions() == 1, "mở phiên mới thay phiên cũ");
    context.expect(failed_with(f.choose(first->session, 0), Error::kStale), "phiên cũ bị từ chối");
    context.expect(failed_with(f.accept(first->session, w::kKillQuest), Error::kStale), "nhận qua phiên cũ bị từ chối");
    context.expect(failed_with(f.turn_in(first->session, w::kKillQuest), Error::kStale), "nộp qua phiên cũ bị từ chối");
    for (const std::uint64_t forged : {0ULL, 1ULL, 999ULL, ~0ULL}) {
        if (forged == second->session.value()) continue;
        context.expect(failed_with(f.choose(talk::SessionId{forged}, 0), Error::kStale), "mã bịa bị từ chối");
    }
    context.expect(f.service.session_of(f.hero.id()) == second->session, "mã sai không phá phiên đang mở");
    context.expect(f.choose(second->session, 0).has_value(), "phiên hiện tại vẫn dùng được sau các lần từ chối");
    // Nhân vật khác không dùng được phiên của người này.
    FakeCharacter other;
    other.who = ids::CharacterId{2};
    context.expect(!f.service.choose(other, second->session, 0, f.world_view, f.now, f.calendar).has_value(), "phiên của người khác");
    f.service.close(f.hero.id());
    context.expect(failed_with(f.choose(second->session, 0), Error::kNoSession), "sau khi đóng không còn phiên");
    const talk::Result third = f.talk();
    context.expect(third.has_value() && third->session.value() > second->session.value(), "mã không dùng lại sau khi đóng");
}

void choose_runs_the_entry_atomically(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto pay = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.pay")));
    context.expect(pay < opened->view.choices.size(), "có lựa chọn trả tiền");
    const talk::Result paid = f.choose(opened->session, pay);
    context.expect(paid.has_value(), "chạy được");
    if (!paid) return;
    context.expect(f.hero.bundle.wallet.normal == 100, "tiền vào ví đúng một lần");
    context.expect(paid->view.lines.size() == 1 && paid->view.lines[0].text.id == talkw::id("lua.paying"), "hộp thoại mới");
    context.expect(paid->outcome.notices.size() == 1 && paid->outcome.notices[0].kind == mission::NoticeKind::kText &&
                       paid->outcome.notices[0].text.id == talkw::id("lua.paid"),
        "thông báo mang mã chuỗi + tham số");
    context.expect(paid->outcome.receipt.committed() && paid->outcome.receipt.request != 0, "có biên nhận sổ cái");
    // Sau lựa chọn đầu, hộp thoại mới không có lựa chọn: chọn tiếp là chỉ số ngoài.
    context.expect(failed_with(f.choose(paid->session, 0), Error::kBadOption), "chỉ số ngoài hộp thoại hiện tại");
    context.expect(failed_with(f.choose(paid->session, 0xFFFFFFFFU), Error::kBadOption), "chỉ số khổng lồ");
}

void failed_effects_change_nothing(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto gift = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.gift")));
    const talk::Result refused = f.choose(opened->session, gift);
    context.expect(!refused.has_value() && refused.error().error == Error::kMission &&
                       refused.error().mission.error == mission::Error::kLedger &&
                       refused.error().mission.ledger == ledger::Reason::kMissingItems,
        "sổ cái từ chối vì thiếu vật phẩm");
    context.expect(f.hero.bundle.exp.total == 0, "kinh nghiệm trong cùng bộ cũng không vào (nguyên tử)");
    context.expect(f.service.session_of(f.hero.id()) == opened->session, "phiên còn nguyên sau lỗi");
    // Lựa chọn khác vẫn chạy được trên cùng phiên.
    const auto pay = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.pay")));
    context.expect(f.choose(opened->session, pay).has_value() && f.hero.bundle.wallet.normal == 100, "chạy tiếp được");
}

void choose_recomputes_and_refuses_changed_options(Context& context) {
    Fixture f;
    f.hero.level_value = 12;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const std::int32_t vet = choice_of(opened->view, talkw::id("lua.vet"));
    context.expect(vet == 0, "lựa chọn cấp 10 đứng đầu");
    // Cấp tụt xuống 5 giữa chừng (bị trừ cấp): lựa chọn 0 từng là "vet", giờ là "pay".
    f.hero.level_value = 5;
    const talk::Result gone = f.choose(opened->session, 0);
    context.expect(!gone.has_value() && gone.error().error == Error::kOptionGone, "lựa chọn đã đổi thì từ chối, không chạy nhầm");
    if (gone) return;
    context.expect(gone.error().view.choices.size() == 10 && gone.error().view.choices[0].text.id == talkw::id("lua.pay"),
        "kèm hộp thoại tính lại để client vẽ");
    context.expect(f.hero.bundle.wallet.normal == 0, "không có hiệu ứng nào chạy");
    // Chọn lại bằng chỉ số mới thì được.
    const talk::Result again = f.choose(opened->session, 0);
    context.expect(again.has_value() && f.hero.bundle.wallet.normal == 100, "sau khi nhận hộp thoại mới, chọn lại chạy đúng lựa chọn");
}

void recompute_does_not_reapply_effects(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto shown = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.shown_option")));
    const talk::Result entered = f.choose(opened->session, shown);
    context.expect(entered.has_value() && f.hero.have(4002) == 1, "điểm vào có hiệu ứng: ngọc vào túi đúng một lần");
    if (!entered) return;
    const auto next = static_cast<std::uint32_t>(choice_of(entered->view, talkw::id("lua.next")));
    const talk::Result stepped = f.choose(entered->session, next);
    context.expect(stepped.has_value(), "chọn mục kế");
    // Tính lại hộp thoại 'lua.shown' để kiểm lựa chọn là chạy KHÔ: ngọc không được vào lần hai.
    context.expect(f.hero.have(4002) == 1, "tính lại không áp hiệu ứng lần hai");
}

void sessions_close_for_environment_reasons(Context& context) {
    {
        Fixture f;
        const talk::Result opened = f.talk();
        f.world_view.value.distance = 8.01F;
        const talk::Result far = f.choose(opened->session, 0);
        context.expect(!far.has_value() && far.error().error == Error::kFar && far.error().closed, "xa quá thì đóng phiên");
        context.expect(f.service.open_sessions() == 0, "phiên đã bị xoá");
    }
    {
        Fixture f;
        const talk::Result opened = f.talk();
        f.world_view.value.distance = 8.0F;
        context.expect(f.choose(opened->session, 0).has_value(), "đúng tầm tối đa vẫn được");
        f.world_view.value.distance = std::numeric_limits<float>::quiet_NaN();
        context.expect(failed_with(f.choose(opened->session, 0), Error::kFar), "khoảng cách NaN coi là xa");
    }
    {
        Fixture f;
        const talk::Result opened = f.talk();
        f.world_view.value.hero_scene = 4;
        const talk::Result moved = f.choose(opened->session, 0);
        context.expect(!moved.has_value() && moved.error().error == Error::kSceneChanged && moved.error().closed, "đổi cảnh đóng phiên");
    }
    {
        Fixture f;
        const talk::Result opened = f.talk();
        f.world_view.present = false;
        const talk::Result gone = f.accept(opened->session, w::kKillQuest);
        context.expect(!gone.has_value() && gone.error().error == Error::kNoNpc && gone.error().closed, "NPC biến mất đóng phiên");
        f.world_view.present = true;
        context.expect(failed_with(f.choose(opened->session, 0), Error::kNoSession), "đã đóng thì không mở lại được bằng mã cũ");
    }
    {
        Fixture f;
        const talk::Result opened = f.talk();
        const ids::Tick edge = ids::advance(f.now, talk::Options{}.idle);
        f.now = ids::Tick{edge.value() - 1};
        context.expect(failed_with(f.choose(opened->session, 99), Error::kBadOption), "chưa hết hạn: phiên còn sống");
        // Mọi ý định hợp lệ của phiên đang sống gia hạn nó: hạn tính từ lần dùng cuối.
        f.now = ids::Tick{edge.value() + 100};
        context.expect(failed_with(f.choose(opened->session, 99), Error::kBadOption), "hoạt động đã gia hạn");
        f.now = ids::advance(f.now, ids::TickSpan{talk::Options{}.idle.count});
        const talk::Result late = f.choose(opened->session, 0);
        context.expect(!late.has_value() && late.error().error == Error::kExpired && late.error().closed, "quá hạn không hoạt động");
    }
    {
        Fixture f;
        const talk::Result opened = f.talk();
        FakeCharacter other;
        other.who = ids::CharacterId{2};
        other.level_value = 5;
        context.expect(f.service.talk(other, f.npc, f.world_view, f.now, f.calendar).has_value() && f.service.open_sessions() == 2, "hai nhân vật hai phiên");
        context.expect(f.service.sweep(f.now) == 0, "chưa ai quá hạn");
        const ids::Tick later = ids::advance(f.now, ids::TickSpan{talk::Options{}.idle.count + 1});
        context.expect(f.service.sweep(later) == 2 && f.service.open_sessions() == 0, "dọn phiên quá hạn");
        context.expect(opened.has_value(), "mở được");
    }
}

void accept_and_turn_in_through_the_session(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    context.expect(failed_with(f.accept(opened->session, w::kPostQuest), Error::kNotOffered), "nhiệm vụ không được mời");
    context.expect(failed_with(f.accept(opened->session, 3999), Error::kNotOffered), "id lạ");
    context.expect(failed_with(f.accept(opened->session, -5), Error::kNotOffered), "id âm");
    context.expect(f.service.session_of(f.hero.id()) == opened->session, "lời đòi sai không đóng phiên");
    const talk::Result accepted = f.accept(opened->session, w::kKillQuest);
    context.expect(accepted.has_value() && accepted->closed && accepted->session.value() == 0, "nhận xong thì đóng phiên");
    context.expect(f.hero.book().find(w::kKillQuest) != nullptr, "nhiệm vụ vào sổ");
    context.expect(f.service.open_sessions() == 0, "phiên đã đóng");
    // Giết đủ 3 sói rồi quay lại: dấu 'đủ điều kiện nộp'.
    for (int i = 0; i < 3; ++i) {
        bus::Event event;
        event.kind = bus::Kind::kKill;
        event.hero = f.hero.id();
        event.a = w::kWolfTemplate;
        static_cast<void>(f.engine.handle(f.hero, event, f.calendar));
    }
    const talk::Result back = f.talk();
    context.expect(back.has_value() && has_mark(back->view, w::kKillQuest, Stage::kReady), "dấu đủ điều kiện nộp");
    context.expect(!has_mark(back->view, w::kKillQuest, Stage::kAvailable), "đang làm thì không còn dấu nhận");
    if (!back) return;
    const talk::Result sheet = f.turn_in(back->session, w::kKillQuest);
    context.expect(sheet.has_value() && !sheet->closed, "thiếu lựa chọn thì mở bảng nộp");
    if (!sheet) return;
    context.expect(sheet->view.mode == talk::Mode::kDemand, "bảng nộp");
    context.expect(sheet->view.panel_quest == w::kKillQuest, "đúng nhiệm vụ trên bảng");
    context.expect(has_bonus(sheet->view, talk::BonusKind::kRadio, 5001, 1), "món 5001");
    context.expect(has_bonus(sheet->view, talk::BonusKind::kRadio, 5002, 1), "món 5002");
    context.expect(has_bonus(sheet->view, talk::BonusKind::kMoney, 50, 0), "tiền thường");
    context.expect(has_bonus(sheet->view, talk::BonusKind::kItem, 4001, 2), "vật phẩm cố định");
    context.expect(!has_bonus(sheet->view, talk::BonusKind::kItem, 6001, 1), "món ẩn không hiện");
    context.expect(f.service.session_of(f.hero.id()) == sheet->session, "phiên còn để chọn thưởng");
    const talk::Result done = f.turn_in(sheet->session, w::kKillQuest, 5001);
    context.expect(done.has_value() && done->closed && f.hero.book().is_done(w::kKillQuest), "nộp được");
    context.expect(f.hero.bundle.exp.total == 100 && f.hero.have(5001) == 1, "thưởng đúng");
}

void next_quest_is_offered_in_the_same_session(Context& context) {
    Fixture f({}, true);
    f.hero.level_value = 5;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    context.expect(has_mark(opened->view, 70, Stage::kAvailable) && !has_mark(opened->view, 71, Stage::kAvailable),
        "nhiệm vụ kế chưa có dấu khi chưa xong tiền đề");
    context.expect(f.accept(opened->session, 70).has_value(), "nhận nhiệm vụ 70");
    const talk::Result second = f.talk();
    if (!second) return context.expect(false, "mở lại");
    bus::Event event;
    event.kind = bus::Kind::kEnterArea;
    event.hero = f.hero.id();
    event.a = static_cast<std::uint32_t>(w::kSceneId);
    event.b = static_cast<std::uint32_t>(w::kAreaId);
    static_cast<void>(f.engine.handle(f.hero, event, f.calendar));
    const talk::Result turned = f.turn_in(second->session, 70);
    context.expect(turned.has_value() && !turned->closed && turned->session == second->session, "nộp xong mời tiếp trong cùng phiên");
    if (!turned) return;
    context.expect(turned->view.mode == talk::Mode::kMissionInfo && turned->view.panel_quest == 71 &&
                       has_mark(turned->view, 71, Stage::kAvailable),
        "lời mời nhiệm vụ 71");
    const talk::Result next = f.accept(turned->session, 71);
    context.expect(next.has_value() && f.hero.book().find(71) != nullptr, "nhận nhiệm vụ kế qua lời mời");
}

void script_quest_panel_names_its_quest(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto quest = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.quest")));
    const talk::Result panel = f.choose(opened->session, quest);
    context.expect(panel.has_value(), "chọn mục nhiệm vụ");
    if (!panel) return;
    context.expect(panel->view.mode == talk::Mode::kMissionInfo && panel->view.panel_quest == w::kKillQuest, "bảng nói về nhiệm vụ 10");
    context.expect(panel->view.bonuses == std::vector<talk::Bonus>{{talk::BonusKind::kMoney, 50, 0, 0}, {talk::BonusKind::kItem, 4001, 2, 0}},
        "dòng thưởng hiển thị");
    context.expect(f.accept(panel->session, w::kKillQuest).has_value(), "nhận qua bảng của script");
}

void directives_reach_the_caller(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto travel = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.travel")));
    const talk::Result moved = f.choose(opened->session, travel);
    context.expect(moved.has_value() && moved->outcome.directives.size() == 1 &&
                       moved->outcome.directives[0].op == ops::EffectOp::kTeleport &&
                       moved->outcome.directives[0].arg == std::array<std::int32_t, 3>{7, 100, 200},
        "dịch chuyển là chỉ thị cho thế giới, không phải trạng thái sổ");
}

void broken_blocks_are_bounded(Context& context) {
    Fixture f;
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    for (const int which : {talkw::kLoop, talkw::kDeep, talkw::kFlood}) {
        const char* const key = which == talkw::kLoop ? "lua.loop" : which == talkw::kDeep ? "lua.deep" : "lua.flood";
        const auto index = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id(key)));
        context.expect(failed_with(f.choose(opened->session, index), Error::kTooLong), "khối hỏng dừng ở trần");
    }
    context.expect(f.service.session_of(f.hero.id()) == opened->session, "phiên còn nguyên sau lỗi");
}

// Chuỗi 100 câu if liên tiếp chạy hết với trần độ sâu 32: khung đã chạy hết bị thay chứ không bị giữ lại. Từng là lỗi thật: 45 script
// NPC của bản gốc (Đại Lý) có chuỗi như vậy mà bị coi là vượt trần.
void long_branch_chains_stay_shallow(Context& context) {
    Fixture f;
    f.npc = talk::NpcRef{static_cast<std::uint32_t>(w::kElder), w::kSceneId, ops::name_id("老人"), talkw::kChainScript};
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "chuỗi nhánh dài mở được");
    context.expect(opened->view.lines.size() == 1 && opened->view.lines[0].text.id == talkw::id("lua.chain_end"), "chạy tới câu cuối chuỗi");
}

std::optional<mission::Failure> greet_handler(talk::HandlerContext& context) {
    static_cast<void>(context.dialogue.line(ops::TextRef{ops::string_id("lua.handler"), {}}));
    if (!context.dialogue.choice(talkw::kNpcScript, 1, 77, ops::TextRef{ops::string_id("lua.handler_next"), {}})) {
        return mission::Failure{mission::Error::kBookLimit, ledger::Reason::kCommitted};
    }
    context.dialogue.set_mode(talk::Mode::kList);
    if (!context.dry) {
        auto result = context.engine.run_effects(context.hero, talkw::kEffPay, {}, context.calendar);
        if (!result) return result.error();
        context.outcome.notices.insert(context.outcome.notices.end(), result->notices.begin(), result->notices.end());
    }
    return std::nullopt;
}

std::optional<mission::Failure> refusing_handler(talk::HandlerContext&) {
    return mission::Failure{mission::Error::kBookLimit, ledger::Reason::kCommitted};
}

void hand_written_handlers_fill_unsupported_entries(Context& context) {
    const std::array specs{
        talk::HandlerSpec{talkw::kNpcScript, talkw::kHand, greet_handler, "thử: điểm vào chưa trích được"},
        talk::HandlerSpec{talkw::kNpcScript, talkw::kHandRefused, refusing_handler, "thử: handler từ chối"},
    };
    {
        Fixture bare;
        const talk::Result opened = bare.talk();
        const auto hand = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.hand")));
        context.expect(failed_with(bare.choose(opened->session, hand), Error::kNoDialog), "không handler: điểm vào chưa trích được không có hội thoại");
    }
    Fixture f(specs);
    const talk::Result opened = f.talk();
    if (!opened) return context.expect(false, "mở được");
    const auto hand = static_cast<std::uint32_t>(choice_of(opened->view, talkw::id("lua.hand")));
    const talk::Result ran = f.choose(opened->session, hand);
    context.expect(ran.has_value() && ran->view.lines.size() == 1 && ran->view.lines[0].text.id == talkw::id("lua.handler"),
        "handler dựng hộp thoại");
    context.expect(f.hero.bundle.wallet.normal == 100 && ran.has_value() && ran->outcome.notices.size() == 1, "handler áp hiệu ứng qua engine, một lần");
    if (!ran) return;
    // Chọn mục của hộp thoại do handler dựng: máy chủ tính lại bằng handler ở chế độ khô, không áp hiệu ứng lần hai; mục đó trỏ tới
    // điểm vào 77 không tồn tại nên không có hội thoại.
    context.expect(failed_with(f.choose(ran->session, 0), Error::kNoDialog), "mục trỏ tới điểm vào không có");
    context.expect(f.hero.bundle.wallet.normal == 100, "tính lại bằng handler là chạy khô");
    const talk::Result second = f.talk();
    const auto refused = static_cast<std::uint32_t>(choice_of(second->view, talkw::id("lua.hand_refused")));
    const talk::Result no = f.choose(second->session, refused);
    context.expect(!no.has_value() && no.error().error == Error::kMission && no.error().mission.error == mission::Error::kBookLimit,
        "handler từ chối thành lỗi có kiểu");
}

void opening_a_dialogue_records_a_held_talk(Context& context) {
    Fixture box;
    const talk::Result opened = box.talk();
    if (!opened) return context.expect(false, "mở được");
    context.expect(box.hero.book().find(w::kAutoQuest) == nullptr, "chưa nhận thì lần gặp không thêm nhiệm vụ");
    const talk::Result accepted = box.accept(opened->session, w::kAutoQuest);
    context.expect(accepted.has_value(), "nhận được nhiệm vụ nói chuyện");
    const mission::Slot* held = box.hero.book().find(w::kAutoQuest);
    context.expect(held != nullptr && held->params[0] == 0 && held->params[1] == 0, "mới nhận thì chưa gặp");
    const talk::Result again = box.talk();
    context.expect(again.has_value(), "mở lại được");
    held = box.hero.book().find(w::kAutoQuest);
    context.expect(held != nullptr && held->params[1] == 1 && held->params[0] == 1, "gặp NPC thì mục nói xong");
    if (!again) return;
    const bool ready = std::ranges::any_of(again->outcome.notices, [](const mission::Notice& notice) {
        return notice.kind == mission::NoticeKind::kReady && notice.quest == w::kAutoQuest;
    });
    context.expect(ready, "hội thoại mang tin sẵn sàng nộp");
}

constexpr std::array kCases{
    Case{.name = "open_builds_the_first_dialogue", .body = open_builds_the_first_dialogue},
    Case{.name = "opening_a_dialogue_records_a_held_talk", .body = opening_a_dialogue_records_a_held_talk},
    Case{.name = "unsupported_and_empty_npcs", .body = unsupported_and_empty_npcs},
    Case{.name = "session_ids_are_strictly_increasing_and_stale_ones_refused", .body = session_ids_are_strictly_increasing_and_stale_ones_refused},
    Case{.name = "choose_runs_the_entry_atomically", .body = choose_runs_the_entry_atomically},
    Case{.name = "failed_effects_change_nothing", .body = failed_effects_change_nothing},
    Case{.name = "choose_recomputes_and_refuses_changed_options", .body = choose_recomputes_and_refuses_changed_options},
    Case{.name = "recompute_does_not_reapply_effects", .body = recompute_does_not_reapply_effects},
    Case{.name = "sessions_close_for_environment_reasons", .body = sessions_close_for_environment_reasons},
    Case{.name = "accept_and_turn_in_through_the_session", .body = accept_and_turn_in_through_the_session},
    Case{.name = "next_quest_is_offered_in_the_same_session", .body = next_quest_is_offered_in_the_same_session},
    Case{.name = "script_quest_panel_names_its_quest", .body = script_quest_panel_names_its_quest},
    Case{.name = "directives_reach_the_caller", .body = directives_reach_the_caller},
    Case{.name = "broken_blocks_are_bounded", .body = broken_blocks_are_bounded},
    Case{.name = "long_branch_chains_stay_shallow", .body = long_branch_chains_stay_shallow},
    Case{.name = "hand_written_handlers_fill_unsupported_entries", .body = hand_written_handlers_fill_unsupported_entries},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
