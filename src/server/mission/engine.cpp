#include "mission/engine.hpp"

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/progress.hpp"
#include "mission/detail/work.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <algorithm>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::mission {
namespace {

[[nodiscard]] std::unexpected<Failure> bad(Error error) {
    return std::unexpected(Failure{.error = error, .ledger = ledger::Reason::kCommitted});
}

// Hiệu ứng lúc nhận và việc cấp đồ của nhiệm vụ giao vật phẩm.
void begin_effects(detail::Work& work, const Catalog& catalog, const Quest& quest, const ops::Context& context) {
    work.add_quest(quest.quest, quest.script, quest.watch);
    work.apply(catalog.program().plan(quest.accept_fx, context));
    for (const Objective& objective : quest.objectives) {
        if (objective.kind == ObjectiveKind::kDeliver && objective.flag == 1) {
            work.entry(ledger::EntryKind::kGiveItem, static_cast<std::uint32_t>(objective.item), objective.count, false);
        }
    }
    if (quest.source == Source::kTable) detail::sync_table(work, quest);
}

// Điểm quan hệ mà nhiệm vụ bảng này cộng khi xong (cùng chỉ số bị trừ khi bỏ); -1 nếu không có.
[[nodiscard]] std::int32_t relation_index(const Quest& quest) noexcept {
    const auto found = std::ranges::find(quest.rewards, RewardKind::kRelation, &Reward::kind);
    return found == quest.rewards.end() ? -1 : found->ref;
}

// Rời khỏi sổ: bỏ (có phạt và thời gian cấm nhận lại) hoặc hỏng (có phạt, không cấm).
Result leave(Character& who, const Catalog& catalog, std::int32_t quest_id, const ops::Calendar& calendar, bool failed) {
    const Slot* const slot = who.book().find(quest_id);
    if (slot == nullptr) return bad(Error::kNotActive);
    const Quest* const quest = catalog.by_script(static_cast<std::uint32_t>(std::max(slot->script, 0)));
    detail::Work work(who, catalog, calendar);
    work.outcome().quest = quest_id;
    work.outcome().script = static_cast<std::uint32_t>(std::max(slot->script, 0));
    if (quest != nullptr && quest->quest == quest_id) {
        const HeroFacade hero(who, &catalog);
        const ops::Context context = detail::make_context(hero, calendar);
        work.apply(catalog.program().plan(quest->abandon_fx, context));
        for (const Objective& objective : quest->objectives) {
            if (objective.kind != ObjectiveKind::kDeliver || objective.flag != 1) continue;
            // Thu lại đồ nhiệm vụ đã cấp: chỉ thu phần còn trong túi.
            const std::int64_t have = who.ports().items.count(static_cast<std::uint32_t>(objective.item));
            work.entry(ledger::EntryKind::kTakeItem, static_cast<std::uint32_t>(objective.item),
                std::min<std::int64_t>(have, objective.count), false);
        }
        const std::int32_t relation = relation_index(*quest);
        if (quest->penalty > 0 && relation >= 0) work.add_relation(relation, -quest->penalty);
        if (!failed && quest->ban_slot >= 0 && quest->ban_seconds > 0 &&
            !work.draft().set_counter(quest->ban_slot, calendar.unix_seconds + quest->ban_seconds)) {
            work.fail_with(Error::kBookLimit);
        }
    }
    work.remove_quest(quest_id);
    if (failed) work.notice(NoticeKind::kFailed, quest_id);
    return work.finish(static_cast<std::uint32_t>(quest_id));
}

}  // namespace

std::string_view describe(Error error) noexcept {
    switch (error) {
        case Error::kUnknownQuest: return "không có nhiệm vụ này";
        case Error::kNotRunnable: return "nhiệm vụ chưa chạy được";
        case Error::kAlreadyActive: return "đang làm nhiệm vụ này";
        case Error::kAlreadyDone: return "đã hoàn thành nhiệm vụ này";
        case Error::kBookFull: return "sổ nhiệm vụ đã đầy";
        case Error::kLevelTooLow: return "cấp chưa đủ";
        case Error::kPrerequisite: return "chưa xong nhiệm vụ tiền đề";
        case Error::kCondition: return "chưa đủ điều kiện nhận";
        case Error::kBanned: return "đang trong thời gian cấm nhận lại";
        case Error::kNotActive: return "không đang làm nhiệm vụ này";
        case Error::kNotReady: return "chưa đủ điều kiện nộp";
        case Error::kNeedChoice: return "cần chọn phần thưởng";
        case Error::kBadChoice: return "phần thưởng chọn không hợp lệ";
        case Error::kBookLimit: return "vượt trần sổ nhiệm vụ";
        case Error::kLedger: return "sổ cái từ chối";
    }
    return "lỗi không rõ";
}

std::optional<Failure> Engine::check_accept(Character& who, const Quest& quest, const ops::Calendar& calendar) const {
    const Book& book = who.book();
    const auto reject = [](Error error) { return std::optional<Failure>(Failure{.error = error, .ledger = ledger::Reason::kCommitted}); };
    if (!quest.runnable()) return reject(Error::kNotRunnable);
    if (book.find(quest.quest) != nullptr) return reject(Error::kAlreadyActive);
    if (quest.repeat == Repeat::kOnce && book.is_done(quest.quest)) return reject(Error::kAlreadyDone);
    if (book.free_slots() == 0) return reject(Error::kBookFull);
    if (quest.source == Source::kTable && who.level() < quest.level) return reject(Error::kLevelTooLow);
    if (!std::ranges::all_of(quest.prereqs, [&](std::int32_t prereq) { return book.is_done(prereq); })) {
        return reject(Error::kPrerequisite);
    }
    if (quest.ban_slot >= 0 && quest.ban_seconds > 0 && book.counter(quest.ban_slot) > calendar.unix_seconds) {
        return reject(Error::kBanned);
    }
    const HeroFacade hero(who, &catalog_);
    if (!catalog_.program().holds(quest.accept_cond, detail::make_context(hero, calendar))) return reject(Error::kCondition);
    return std::nullopt;
}

bool Engine::ready(Character& who, const Quest& quest, const ops::Calendar& calendar) const {
    const Slot* const slot = who.book().find(quest.quest);
    if (slot == nullptr || std::cmp_not_equal(slot->script, quest.script)) return false;
    if (quest.source == Source::kScript) {
        const HeroFacade hero(who, &catalog_);
        return catalog_.program().holds(quest.ready_cond, detail::make_context(hero, calendar));
    }
    return detail::table_ready(quest, *slot, who.ports().items);
}

Result Engine::accept_script(Character& who, std::uint32_t script, const ops::Calendar& calendar) {
    const Quest* const quest = catalog_.by_script(script);
    if (quest == nullptr) return bad(Error::kUnknownQuest);
    if (const std::optional<Failure> refused = check_accept(who, *quest, calendar)) return std::unexpected(*refused);
    detail::Work work(who, catalog_, calendar);
    const HeroFacade hero(who, &catalog_);
    begin_effects(work, catalog_, *quest, detail::make_context(hero, calendar));
    work.outcome().quest = quest->quest;
    work.outcome().script = quest->script;
    return work.finish(static_cast<std::uint32_t>(quest->quest));
}

namespace {

struct Eligible {
    std::vector<const Quest*> list;  // biến thể nhận được, chỉ giữ cấp cao nhất
    std::optional<Failure> worst;    // lý do của biến thể dễ nhất khi không có biến thể nào nhận được
};

// Các biến thể nhận được của một id nhiệm vụ: cấp cao nhất không vượt cấp nhân vật (kiểm ở check_accept), ngang cấp thì giữ hết.
[[nodiscard]] std::expected<Eligible, Failure> eligible_variants(const Engine& engine, Character& who, std::int32_t quest,
    const ops::Calendar& calendar) {
    const std::vector<const Quest*> variants = engine.catalog().variants(quest);
    if (variants.empty()) return std::unexpected(Failure{.error = Error::kUnknownQuest, .ledger = ledger::Reason::kCommitted});
    Eligible found;
    std::int32_t worst_level = 0;
    for (const Quest* variant : variants) {
        const std::optional<Failure> refused = engine.check_accept(who, *variant, calendar);
        if (!refused) {
            found.list.push_back(variant);
        } else if (!found.worst || variant->level < worst_level) {
            found.worst = refused;  // lý do của biến thể dễ nhất: người chơi cần biết thiếu gì ít nhất
            worst_level = variant->level;
        }
    }
    if (found.list.empty()) {
        return std::unexpected(found.worst.value_or(Failure{.error = Error::kUnknownQuest, .ledger = ledger::Reason::kCommitted}));
    }
    const std::int32_t top = std::ranges::max(found.list, {}, &Quest::level)->level;
    std::erase_if(found.list, [top](const Quest* variant) { return variant->level != top; });
    return found;
}

}  // namespace

std::optional<Failure> Engine::can_accept(Character& who, std::int32_t quest, const ops::Calendar& calendar) const {
    const auto found = eligible_variants(*this, who, quest, calendar);
    if (found) return std::nullopt;
    return found.error();
}

Result Engine::accept(Character& who, std::int32_t quest, const ops::Calendar& calendar) {
    const auto found = eligible_variants(*this, who, quest, calendar);
    if (!found) return std::unexpected(found.error());
    const Quest* chosen = found->list.front();
    if (found->list.size() > 1) chosen = found->list.at(dice_.below(found->list.size()));
    return accept_script(who, chosen->script, calendar);
}

Result Engine::run_effects(Character& who, std::int32_t effects_id, const EffectsRun& run, const ops::Calendar& calendar) {
    detail::Work work(who, catalog_, calendar);
    const HeroFacade hero(who, &catalog_);
    ops::Context context = detail::make_context(hero, calendar);
    context.radio = run.radio;
    context.target_name = run.target_name;
    work.apply(catalog_.program().plan(effects_id, context));
    return work.finish(run.source);
}

Result Engine::abandon(Character& who, std::int32_t quest, const ops::Calendar& calendar) {
    return leave(who, catalog_, quest, calendar, false);
}

Result Engine::fail(Character& who, std::int32_t quest, const ops::Calendar& calendar) {
    return leave(who, catalog_, quest, calendar, true);
}

}  // namespace game::mission
