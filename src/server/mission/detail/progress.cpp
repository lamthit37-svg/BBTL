#include "mission/detail/progress.hpp"

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/work.hpp"
#include "mission/engine.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace game::mission::detail {

bool objective_met(const Objective& objective, const Slot& slot, std::int64_t items) noexcept {
    const std::size_t param = param_of(objective);
    if (param >= kParamCount) return false;
    const std::uint32_t progress = slot.params.at(param);
    switch (objective.kind) {
        case ObjectiveKind::kTalk:
        case ObjectiveKind::kArea: return progress >= 1U;
        case ObjectiveKind::kKill: return std::cmp_greater_equal(progress, std::max(objective.count, 1));
        case ObjectiveKind::kLoot:
        case ObjectiveKind::kDeliver: return items >= objective.count;
        case ObjectiveKind::kEscort:
        case ObjectiveKind::kProgress:
        case ObjectiveKind::kCollect: return false;  // không thuộc nhiệm vụ bảng
    }
    return false;
}

bool table_ready(const Quest& quest, const Slot& slot, const ledger::ItemPort& items) noexcept {
    return std::ranges::all_of(quest.objectives, [&](const Objective& objective) {
        const bool counted = objective.kind == ObjectiveKind::kLoot || objective.kind == ObjectiveKind::kDeliver;
        return objective_met(objective, slot, counted ? items.count(static_cast<std::uint32_t>(objective.item)) : 0);
    });
}

void sync_table(Work& work, const Quest& quest) {
    Slot* const slot = work.draft().find(quest.quest);
    if (slot == nullptr) return;
    bool all_met = true;
    bool changed = false;
    for (const Objective& objective : quest.objectives) {
        const std::size_t param = param_of(objective);
        if (param >= kParamCount) {
            all_met = false;
            continue;
        }
        std::int64_t items = 0;
        if (objective.kind == ObjectiveKind::kLoot || objective.kind == ObjectiveKind::kDeliver) {
            items = work.projected_items(static_cast<std::uint32_t>(objective.item));
            const auto shown = static_cast<std::uint32_t>(std::clamp<std::int64_t>(items, 0, objective.count));
            if (slot->params.at(param) != shown) {
                slot->params.at(param) = shown;
                changed = true;
            }
        }
        all_met = objective_met(objective, *slot, items) && all_met;
    }
    const std::uint32_t flag = all_met ? 1U : 0U;
    if (slot->params.at(0) != flag) {
        slot->params.at(0) = flag;
        work.notice(all_met ? NoticeKind::kReady : NoticeKind::kUpdated, quest.quest);
    } else if (changed) {
        work.notice(NoticeKind::kUpdated, quest.quest);
    }
}

}  // namespace game::mission::detail
