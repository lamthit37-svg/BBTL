/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/mission/detail/progress.cpp
 *  PHÂN HỆ   : Mission / Detail / Progress
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đồng bộ ô tiến độ từ túi, từ cấp và từ kỹ năng đã biết.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "mission/detail/progress.hpp"

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/work.hpp"
#include "mission/engine.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>

namespace game::mission::detail {
namespace {

// Học kỹ năng và đạt cấp không đếm sự kiện: 1 khi nhân vật đã đủ, 0 khi chưa.
[[nodiscard]] std::optional<std::uint32_t> state_shown(const Character& who,
    const Objective& objective) noexcept {
    if (objective.kind == ObjectiveKind::kLevel) return who.level() >= objective.count ? 1U : 0U;
    if (objective.kind == ObjectiveKind::kSkill) return who.skill_known(objective.item) ? 1U : 0U;
    return std::nullopt;
}

void note_state(Work& work, const Objective& objective, Slot& slot, bool& changed) {
    const std::optional<std::uint32_t> shown = state_shown(work.who(), objective);
    const std::size_t param = param_of(objective);
    if (!shown || param >= kParamCount || slot.params.at(param) == *shown) return;
    slot.params.at(param) = *shown;
    changed = true;
}

void note_items(Work& work, const Objective& objective, Slot& slot, std::int64_t& items,
    bool& changed) {
    const bool counted =
        objective.kind == ObjectiveKind::kLoot || objective.kind == ObjectiveKind::kDeliver;
    if (!counted) return;
    items = work.projected_items(static_cast<std::uint32_t>(objective.item));
    const auto cap =
        static_cast<std::uint32_t>(std::clamp<std::int64_t>(items, 0, objective.count));
    const std::size_t param = param_of(objective);
    if (slot.params.at(param) == cap) return;
    slot.params.at(param) = cap;
    changed = true;
}

[[nodiscard]] bool track_one(Work& work, const Objective& objective, Slot& slot, bool& changed) {
    if (param_of(objective) >= kParamCount) return false;
    note_state(work, objective, slot, changed);
    std::int64_t items = 0;
    note_items(work, objective, slot, items, changed);
    return objective_met(objective, slot, items);
}

} // namespace

bool objective_met(const Objective& objective, const Slot& slot, std::int64_t items) noexcept {
    const std::size_t param = param_of(objective);
    if (param >= kParamCount) return false;
    const std::uint32_t progress = slot.params.at(param);
    switch (objective.kind) {
    case ObjectiveKind::kTalk:
    case ObjectiveKind::kArea:
    case ObjectiveKind::kSkill:
    case ObjectiveKind::kLevel: return progress >= 1U;
    case ObjectiveKind::kKill:
        return std::cmp_greater_equal(progress, std::max(objective.count, 1));
    case ObjectiveKind::kLoot:
    case ObjectiveKind::kDeliver: return items >= objective.count;
    case ObjectiveKind::kEscort:
    case ObjectiveKind::kProgress:
    case ObjectiveKind::kCollect: return false; // không thuộc nhiệm vụ bảng
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
        all_met = track_one(work, objective, *slot, changed) && all_met;
    }
    const std::uint32_t flag = all_met ? 1U : 0U;
    if (slot->params.at(0) != flag) {
        slot->params.at(0) = flag;
        work.notice(all_met ? NoticeKind::kReady : NoticeKind::kUpdated, quest.quest);
    } else if (changed) {
        work.notice(NoticeKind::kUpdated, quest.quest);
    }
}

} // namespace game::mission::detail
