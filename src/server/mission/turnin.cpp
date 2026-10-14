// Nộp nhiệm vụ: thu đồ nhiệm vụ, chọn thưởng, chạy hiệu ứng nộp, đánh dấu xong. Một giao dịch sổ cái duy nhất.
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/work.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <algorithm>
#include <cstdint>
#include <expected>
#include <utility>
#include <vector>

namespace game::mission {
namespace {

[[nodiscard]] std::unexpected<Failure> bad(Error error) {
    return std::unexpected(Failure{.error = error, .ledger = ledger::Reason::kCommitted});
}

// Phần thưởng sẽ phát: nhóm cố định và ẩn phát hết, nhóm chọn một phát đúng món đã chọn. Điều kiện từng món xét trên trạng thái
// trước khi nộp.
struct Payout {
    std::vector<const Reward*> given;
    bool has_choice = false;
    bool matched = false;
};

[[nodiscard]] Payout payout_of(const Quest& quest, const ops::Program& program, const ops::Context& context,
    std::int32_t choice) {
    Payout payout;
    for (const Reward& reward : quest.rewards) {
        if (!program.holds(reward.cond, context)) continue;
        if (reward.group == RewardGroup::kChoice) {
            payout.has_choice = true;
            if (reward.kind != RewardKind::kItem || reward.ref != choice) continue;
            payout.matched = true;
        }
        payout.given.push_back(&reward);
    }
    return payout;
}

void pay(detail::Work& work, const Reward& reward) {
    switch (reward.kind) {
        case RewardKind::kMoney:
            work.entry(ledger::EntryKind::kGiveMoney, 0, reward.count, false);
            work.notice(NoticeKind::kRewardMoney, -1, reward.count, 0);
            return;
        case RewardKind::kBoundMoney:
            work.entry(ledger::EntryKind::kGiveMoney, 0, reward.count, true);
            work.notice(NoticeKind::kRewardMoney, -1, reward.count, 1);
            return;
        case RewardKind::kExp:
            work.entry(ledger::EntryKind::kGiveExp, 0, reward.count, false);
            work.notice(NoticeKind::kRewardExp, -1, reward.count, 0);
            return;
        case RewardKind::kItem:
            work.entry(ledger::EntryKind::kGiveItem, static_cast<std::uint32_t>(reward.ref), reward.count, false);
            work.notice(NoticeKind::kRewardItem, -1, reward.count, reward.ref);
            return;
        case RewardKind::kRelation: work.add_relation(reward.ref, reward.count); return;
    }
}

}  // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id nhiệm vụ và mẫu vật phẩm đã chọn khác vai, nơi gọi nêu tên (HP-07)
Result Engine::turn_in(Character& who, std::int32_t quest_id, std::int32_t choice, const ops::Calendar& calendar) {
    const Slot* const slot = who.book().find(quest_id);
    if (slot == nullptr) return bad(Error::kNotActive);
    const Quest* const quest = catalog_.by_script(static_cast<std::uint32_t>(std::max(slot->script, 0)));
    if (quest == nullptr || quest->quest != quest_id || !quest->runnable()) return bad(Error::kNotRunnable);
    if (!ready(who, *quest, calendar)) return bad(Error::kNotReady);

    const HeroFacade hero(who, &catalog_);
    ops::Context context = detail::make_context(hero, calendar);
    context.radio = choice;
    const Payout payout = payout_of(*quest, catalog_.program(), context, choice);
    if (payout.has_choice && choice < 0) return bad(Error::kNeedChoice);
    if (payout.has_choice && !payout.matched) return bad(Error::kBadChoice);

    detail::Work work(who, catalog_, calendar);
    work.outcome().quest = quest_id;
    work.outcome().script = quest->script;
    for (const Objective& objective : quest->objectives) {
        if (objective.kind == ObjectiveKind::kLoot || objective.kind == ObjectiveKind::kDeliver) {
            work.entry(ledger::EntryKind::kTakeItem, static_cast<std::uint32_t>(objective.item), objective.count, false);
        }
    }
    for (const Reward* reward : payout.given) pay(work, *reward);
    work.apply(catalog_.program().plan(quest->submit_fx, context));
    work.remove_quest(quest_id);
    if (quest->repeat == Repeat::kOnce) {
        work.draft().mark_done(quest_id);
        work.notice(NoticeKind::kDone, quest_id);
    }
    if (quest->next_quest >= 0 || quest->next_script > 0) {
        Directive next;
        next.op = ops::EffectOp::kOfferNext;
        next.arg = {quest->next_quest, static_cast<std::int32_t>(quest->next_script), 0};
        work.outcome().directives.push_back(std::move(next));
    }
    return work.finish(static_cast<std::uint32_t>(quest_id));
}

}  // namespace game::mission
