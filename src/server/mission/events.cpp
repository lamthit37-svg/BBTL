/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/mission/events.cpp
 *  PHÂN HỆ   : Server / Mission / Events
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đưa sự kiện trên bus vào nhiệm vụ đang giữ, gộp một giao dịch.
 *  - Gặp đúng thầy thì học kỹ năng. Lên cấp thì đối chiếu lại mục tiêu đạt cấp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Sự kiện từ bus tới nhiệm vụ đang làm: nói chuyện, giết quái, vào vùng, đổi vật phẩm, lên cấp. Duyệt ô theo chỉ số tăng dần
// (tất định); nhiệm vụ nào không quan tâm sự kiện thì không bị đụng tới. Mọi thay đổi của một sự kiện gộp vào MỘT giao dịch.

#include "bus/bus.hpp"
#include "dice/dice.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/progress.hpp"
#include "mission/detail/work.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::mission {
namespace {

// Mã chuỗi báo túi đầy khi vật phẩm nhiệm vụ rơi; khoá có sẵn trong StrDictionary của client 2026.
constexpr std::uint32_t kTextBagFull = ops::string_id("GCPickResultHandler_Info_package_Full");

struct Drop {
    std::uint32_t item = 0;
};

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): một lượt xử lý sự kiện: mọi tham chiếu sống lâu hơn nó, không sở hữu, không giữ qua tick (SH-04)
struct Pass {
    detail::Work& work;
    const Catalog& catalog;
    dice::Dice& dice;
    const bus::Event& event;
    std::vector<Drop>& drops;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

[[nodiscard]] bool person_matches(const Objective& objective, const bus::Event& event) noexcept {
    if (objective.target != 0) return std::cmp_equal(objective.target, event.a);
    return objective.name != 0 && objective.name == event.name;
}

[[nodiscard]] bool talk_matches(const Objective& objective, const bus::Event& event) noexcept {
    if (objective.kind != ObjectiveKind::kTalk) return false;
    return person_matches(objective, event);
}

// Học đúng kỹ năng của mục tiêu khi gặp đúng thầy. true khi vừa đủ để sync ghi ô (param còn 0).
[[nodiscard]] bool teach_skill(const Pass& pass, const Slot& slot, const Objective& objective) {
    if (objective.kind != ObjectiveKind::kSkill) return false;
    if (!person_matches(objective, pass.event)) return false;
    const std::size_t param = detail::param_of(objective);
    if (param >= kParamCount || objective.item <= 0) return false;
    if (slot.params.at(param) != 0) return false;
    Character& who = pass.work.who();
    if (!who.skill_known(objective.item) && !who.learn_skill(objective.item)) return false;
    return who.skill_known(objective.item);
}

[[nodiscard]] bool apply_talk(const Pass& pass, Slot& slot, const Objective& objective,
    std::uint32_t& param) {
    if (objective.kind == ObjectiveKind::kSkill) return teach_skill(pass, slot, objective);
    if (!talk_matches(objective, pass.event) || param != 0) return false;
    param = 1;
    return true;
}

[[nodiscard]] bool kill_matches(const Catalog& catalog, const Objective& objective, const bus::Event& event) noexcept {
    if (objective.kind != ObjectiveKind::kKill && objective.kind != ObjectiveKind::kLoot) return false;
    const std::uint32_t group = catalog.group_of_template(event.a);
    const auto target = static_cast<std::uint32_t>(objective.target);
    return (group != 0 && target == group) || (event.name != 0 && target == event.name);
}

void bump(Slot& slot, const Objective& objective, std::uint32_t cap) {
    std::uint32_t& param = slot.params.at(detail::param_of(objective));
    param = std::min(param + 1U, cap);
}

// Tiến độ bảng theo sự kiện; trả true nếu có mục tiêu bị đụng tới.
bool advance_table(const Pass& pass, const Quest& quest) {
    Slot* const slot = pass.work.draft().find(quest.quest);
    if (slot == nullptr) return false;
    bool touched = false;
    for (const Objective& objective : quest.objectives) {
        if (detail::param_of(objective) >= kParamCount) continue;
        std::uint32_t& param = slot->params.at(detail::param_of(objective));
        switch (pass.event.kind) {
        case bus::Kind::kTalk:
            touched = apply_talk(pass, *slot, objective, param) || touched;
            break;
        case bus::Kind::kEnterArea: {
            const bool here = objective.kind == ObjectiveKind::kArea &&
                std::cmp_equal(objective.target, pass.event.b) &&
                (objective.scene <= 0 || std::cmp_equal(objective.scene, pass.event.a));
            if (here && param == 0) {
                param = 1;
                touched = true;
            }
            break;
        }
            case bus::Kind::kKill:
                if (!kill_matches(pass.catalog, objective, pass.event)) break;
                touched = true;
                if (objective.kind == ObjectiveKind::kKill) {
                    bump(*slot, objective, static_cast<std::uint32_t>(std::max(objective.count, 1)));
                } else if (pass.work.projected_items(static_cast<std::uint32_t>(objective.item)) < objective.count &&
                           pass.dice.chance_permille(static_cast<std::uint32_t>(objective.rate) * 10U)) {
                    pass.drops.push_back(Drop{static_cast<std::uint32_t>(objective.item)});
                }
                break;
            case bus::Kind::kItemChanged:
            case bus::Kind::kLevelUp: break;
        }
    }
    return touched;
}

[[nodiscard]] HookEvent hook_of(bus::Kind kind) noexcept {
    switch (kind) {
        case bus::Kind::kKill: return HookEvent::kKill;
        case bus::Kind::kEnterArea: return HookEvent::kEnterArea;
        default: return HookEvent::kItemChanged;
    }
}

[[nodiscard]] bool hookable(bus::Kind kind) noexcept {
    return kind == bus::Kind::kKill || kind == bus::Kind::kEnterArea || kind == bus::Kind::kItemChanged;
}

void run_hooks(const Pass& pass, const Quest& quest, Character& who, const ops::Calendar& calendar) {
    if (!hookable(pass.event.kind)) return;
    const HeroFacade hero(who, &pass.catalog);
    ops::Context context = detail::make_context(hero, calendar);
    switch (pass.event.kind) {
        case bus::Kind::kKill:
            context.event.monster = pass.event.a;
            context.event.monster_name = pass.event.name;
            break;
        case bus::Kind::kEnterArea: context.event.area = static_cast<std::int32_t>(pass.event.b); break;
        default: context.event.item = pass.event.a; break;
    }
    for (const Hook& hook : quest.hooks) {
        if (hook.event == hook_of(pass.event.kind)) pass.work.apply(pass.catalog.program().plan(hook.effects, context));
    }
}

// Tự nhận / tự hoàn thành theo cấp (scene.lua: g_AutoAccept_MissionList và g_FullLevel_MissionList).
void level_up(detail::Work& work, const Catalog& catalog, const bus::Event& event, std::int32_t level) {
    const auto now = static_cast<std::int32_t>(event.a);
    const std::int32_t before = event.c >= 0 && event.c < now ? event.c : now - 1;
    for (std::int32_t reached = before + 1; reached <= now; ++reached) {
        for (const AutoRule& rule : catalog.autos()) {
            const Quest* const quest = catalog.by_script(rule.script);
            if (rule.level == reached && quest != nullptr && quest->runnable() && quest->quest == rule.quest) {
                const Book& draft = work.draft();
                const bool open = draft.free_slots() > 0 && draft.find(rule.quest) == nullptr && !draft.is_done(rule.quest) &&
                                  (rule.pre_quest <= 0 || draft.is_done(rule.pre_quest));
                if (open) {
                    work.add_quest(quest->quest, quest->script, quest->watch);
                    if (quest->source == Source::kTable) detail::sync_table(work, *quest);
                }
            }
            if (rule.full_level != reached || rule.complete_idx < 0) continue;
            Slot* const slot = work.draft().find(rule.quest);
            const auto complete = static_cast<std::size_t>(rule.complete_idx);
            if (slot == nullptr || level < rule.full_level || slot->params.at(complete) != 0U) continue;
            slot->params.at(complete) = 1;
            if (rule.record_idx >= 0) slot->params.at(static_cast<std::size_t>(rule.record_idx)) = 1;
            Notice tip;
            tip.kind = NoticeKind::kText;
            tip.quest = rule.quest;
            const std::string_view key = std::string_view(rule.message);
            const bool wrapped = key.starts_with("#{") && key.ends_with('}');
            tip.text.id = wrapped ? ops::string_id(key.substr(2, key.size() - 3)) : 0U;
            work.outcome().notices.push_back(std::move(tip));
            work.notice(NoticeKind::kUpdated, rule.quest);
        }
    }
}

[[nodiscard]] const Quest* held_table(const Catalog& catalog, const Slot& slot) {
    if (!slot.used()) return nullptr;
    const auto script = static_cast<std::uint32_t>(std::max(slot.script, 0));
    const Quest* const quest = catalog.by_script(script);
    if (quest == nullptr || quest->source != Source::kTable) return nullptr;
    if (quest->quest != slot.mission) return nullptr;
    return quest;
}

// Cấp đổi thì đối chiếu lại mục tiêu đạt cấp và túi của mọi nhiệm vụ bảng đang giữ.
void sync_held_tables(detail::Work& work, const Catalog& catalog) {
    for (const Slot& slot : work.draft().slots) {
        const Quest* const quest = held_table(catalog, slot);
        if (quest == nullptr) continue;
        detail::sync_table(work, *quest);
    }
}

// Vật phẩm nhiệm vụ rơi: mỗi món là một giao dịch riêng để túi đầy không làm mất tiến độ giết quái
// đã ghi.
void deliver_drops(Character& who, const Catalog& catalog, const ops::Calendar& calendar, const std::vector<Drop>& drops,
    Outcome& out) {
    for (const Drop& drop : drops) {
        detail::Work work(who, catalog, calendar);
        work.entry(ledger::EntryKind::kGiveItem, drop.item, 1, false);
        for (const Slot& slot : work.draft().slots) {
            const Quest* const quest = slot.used() ? catalog.by_script(static_cast<std::uint32_t>(std::max(slot.script, 0))) : nullptr;
            if (quest != nullptr && quest->source == Source::kTable && quest->quest == slot.mission) {
                detail::sync_table(work, *quest);
            }
        }
        Result done = work.finish(drop.item);
        if (!done) {
            Notice tip;
            tip.kind = NoticeKind::kText;
            tip.text.id = kTextBagFull;
            out.notices.push_back(std::move(tip));
            continue;
        }
        for (Notice& notice : done->notices) out.notices.push_back(std::move(notice));
        out.receipt = done->receipt;
    }
}

}  // namespace

Outcome Engine::handle(Character& who, const bus::Event& event, const ops::Calendar& calendar) {
    Outcome out;
    detail::Work work(who, catalog_, calendar);
    std::vector<Drop> drops;
    const Pass pass{.work = work, .catalog = catalog_, .dice = dice_, .event = event, .drops = drops};
    if (event.kind == bus::Kind::kLevelUp) {
        level_up(work, catalog_, event, who.level());
        sync_held_tables(work, catalog_);
    } else {
        const std::uint8_t wanted = event.kind == bus::Kind::kKill       ? kWatchKill
                                    : event.kind == bus::Kind::kEnterArea ? kWatchArea
                                    : event.kind == bus::Kind::kItemChanged ? kWatchItem
                                                                            : std::uint8_t{0};
        for (const Slot& slot : who.book().slots) {
            const bool listens = slot.used() && (event.kind == bus::Kind::kTalk || (slot.flags & wanted) != 0);
            const Quest* const quest = listens ? catalog_.by_script(static_cast<std::uint32_t>(std::max(slot.script, 0))) : nullptr;
            if (quest == nullptr || quest->quest != slot.mission || !quest->runnable()) continue;
            if (quest->source == Source::kTable) {
                if (event.kind == bus::Kind::kItemChanged) {
                    detail::sync_table(work, *quest);  // tiến độ vật phẩm lấy thẳng từ túi
                } else if (advance_table(pass, *quest)) {
                    work.notice(NoticeKind::kUpdated, quest->quest);
                    detail::sync_table(work, *quest);
                }
            }
            run_hooks(pass, *quest, who, calendar);
        }
    }
    if (work.draft() == who.book() && work.outcome().notices.empty() && work.outcome().directives.empty() && drops.empty() &&
        !work.failed()) {
        return out;
    }
    Result done = work.finish(0);
    if (done) {
        out = std::move(*done);
    } else {
        out.refused = done.error();
    }
    if (!drops.empty()) deliver_drops(who, catalog_, calendar, drops, out);
    return out;
}

}  // namespace game::mission
