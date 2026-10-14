#include "mission/detail/work.hpp"

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <utility>

namespace game::mission::detail {
namespace {

[[nodiscard]] bool valid_param(std::int32_t index) noexcept {
    return index >= 0 && std::cmp_less(index, kParamCount);
}

[[nodiscard]] std::int64_t clamp_counter(std::int64_t value) noexcept {
    return std::clamp(value, -kCounterLimit, kCounterLimit);
}

}  // namespace

std::uint32_t saturating_param(std::int64_t value) noexcept {
    return static_cast<std::uint32_t>(std::clamp<std::int64_t>(value, 0, std::numeric_limits<std::uint32_t>::max()));
}

ops::Context make_context(const HeroFacade& hero, const ops::Calendar& calendar) noexcept {
    ops::Context context;
    context.hero = &hero;
    context.calendar = calendar;
    return context;
}

Work::Work(Character& who, const Catalog& catalog, const ops::Calendar& calendar)
    : who_(who), catalog_(catalog), calendar_(calendar), draft_(who.book()) {}

std::int64_t Work::projected_items(std::uint32_t item) const noexcept {
    std::int64_t total = who_.ports().items.count(item);
    for (const ledger::Entry& one : entries_) {
        if (one.item != item) continue;
        if (one.kind == ledger::EntryKind::kGiveItem) total += one.amount;
        if (one.kind == ledger::EntryKind::kTakeItem) total -= one.amount;
    }
    return total;
}

void Work::fail_with(Error error) noexcept {
    if (!failed_) failed_ = Failure{.error = error, .ledger = ledger::Reason::kCommitted};
}

void Work::entry(ledger::EntryKind kind, std::uint32_t item, std::int64_t amount, bool bound) {
    if (amount <= 0) return;  // thưởng bằng 0 là không có dòng
    // Gộp dòng cùng loại: sổ cái cũng gộp, nhưng chỉ nhận tối đa kMaxEntries dòng nên một nhiệm vụ nhiều dòng thưởng
    // điều kiện (script 2091 có 97 dòng) sẽ bị từ chối oan nếu chuyển nguyên từng dòng.
    for (ledger::Entry& existing : entries_) {
        const bool same = existing.kind == kind && existing.item == item && existing.bound == bound;
        if (same && amount <= ledger::kMaxAmount - existing.amount) {
            existing.amount += amount;
            return;
        }
    }
    entries_.push_back(ledger::Entry{.kind = kind, .item = item, .amount = amount, .bound = bound});
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): nhiệm vụ, giá trị và tham chiếu khác vai, nơi gọi nêu tên (HP-07)
void Work::notice(NoticeKind kind, std::int32_t quest, std::int64_t value, std::int32_t ref) {
    Notice one;
    one.kind = kind;
    one.quest = quest;
    one.value = value;
    one.ref = ref;
    out_.notices.push_back(std::move(one));
}

void Work::add_quest(std::int32_t quest, std::uint32_t script, std::uint8_t watch) {
    if (draft_.find(quest) != nullptr) return;  // đã giữ: không đổi tiến độ
    if (draft_.add(quest, static_cast<std::int32_t>(script), watch) == nullptr) {
        fail_with(draft_.free_slots() == 0 ? Error::kBookFull : Error::kBookLimit);
        return;
    }
    notice(NoticeKind::kAdded, quest);
}

void Work::remove_quest(std::int32_t quest) {
    if (draft_.remove(quest)) notice(NoticeKind::kRemoved, quest);
}

void Work::add_relation(std::int32_t index, std::int64_t delta) {
    const std::int64_t value = std::clamp<std::int64_t>(draft_.counter(index) + delta, 0, kMaxRelationship);
    if (!draft_.set_counter(index, value)) {
        fail_with(Error::kBookLimit);
        return;
    }
    notice(NoticeKind::kRelation, -1, value, index);
}

void Work::apply(const ops::Plan& plan) {
    for (const ops::Effect* effect : plan.steps) apply(*effect);
}

void Work::apply(const ops::Effect& effect) {
    const auto& a = effect.arg;
    switch (effect.op) {
        case ops::EffectOp::kGiveItem:
            entry(ledger::EntryKind::kGiveItem, static_cast<std::uint32_t>(std::max(a[0], 0)), a[1], false);
            return;
        case ops::EffectOp::kTakeItem:
            entry(ledger::EntryKind::kTakeItem, static_cast<std::uint32_t>(std::max(a[0], 0)), a[1], false);
            return;
        case ops::EffectOp::kGiveMoney: entry(ledger::EntryKind::kGiveMoney, 0, a[0], a[1] != 0); return;
        case ops::EffectOp::kTakeMoney: entry(ledger::EntryKind::kTakeMoney, 0, a[0], a[1] != 0); return;
        case ops::EffectOp::kGiveExp: entry(ledger::EntryKind::kGiveExp, 0, a[0], false); return;
        case ops::EffectOp::kQuestAccept: {
            const Quest* const known = catalog_.by_script(static_cast<std::uint32_t>(std::max(a[1], 0)));
            add_quest(a[0], static_cast<std::uint32_t>(std::max(a[1], 0)), known != nullptr ? known->watch : kWatchMask);
            return;
        }
        case ops::EffectOp::kQuestRemove: remove_quest(a[0]); return;
        case ops::EffectOp::kQuestMarkDone:
            draft_.mark_done(a[0]);
            notice(NoticeKind::kDone, a[0]);
            return;
        case ops::EffectOp::kObjectiveSet:
        case ops::EffectOp::kObjectiveAdd: {
            Slot* const slot = draft_.find(a[0]);
            if (slot == nullptr || !valid_param(a[1])) return;  // nhiệm vụ không còn: bỏ qua như script gốc
            std::uint32_t& param = slot->params.at(static_cast<std::size_t>(a[1]));
            param = saturating_param(effect.op == ops::EffectOp::kObjectiveSet
                                         ? static_cast<std::int64_t>(a[2])
                                         : static_cast<std::int64_t>(param) + a[2]);
            notice(NoticeKind::kUpdated, a[0]);
            return;
        }
        case ops::EffectOp::kSetCounter:
            if (!draft_.set_counter(a[0], a[1])) fail_with(Error::kBookLimit);
            return;
        case ops::EffectOp::kCounterAdd:
            if (!draft_.set_counter(a[0], clamp_counter(draft_.counter(a[0]) + a[1]))) fail_with(Error::kBookLimit);
            return;
        case ops::EffectOp::kSetCounterClock:
            if (!draft_.set_counter(a[0], calendar_.clock(a[1]))) fail_with(Error::kBookLimit);
            return;
        case ops::EffectOp::kSetFlag:
            if (!draft_.set_flag(a[0], true)) fail_with(Error::kBookLimit);
            return;
        case ops::EffectOp::kClearFlag:
            if (!draft_.set_flag(a[0], false)) fail_with(Error::kBookLimit);
            return;
        case ops::EffectOp::kNotify:
        case ops::EffectOp::kAnnounce: {
            Notice one;
            one.kind = effect.op == ops::EffectOp::kNotify ? NoticeKind::kText : NoticeKind::kAnnounce;
            one.text = effect.text;
            out_.notices.push_back(std::move(one));
            return;
        }
        case ops::EffectOp::kTeleport:
        case ops::EffectOp::kOpenShop:
        case ops::EffectOp::kSignpost:
        case ops::EffectOp::kSignpostPos:
        case ops::EffectOp::kOfferNext:
        case ops::EffectOp::kUiCommand: {
            Directive one;
            one.op = effect.op;
            one.arg = effect.arg;
            one.text = effect.text;
            out_.directives.push_back(std::move(one));
            return;
        }
    }
}

Result Work::finish(std::uint32_t source) {
    if (failed_) return std::unexpected(*failed_);
    if (!entries_.empty()) {
        const ledger::Request request{.id = draft_.next_request(), .source = source, .entries = entries_};
        const ledger::Receipt receipt = ledger::commit(draft_.journal, request, who_.ports());
        if (!receipt.committed()) return std::unexpected(Failure{.error = Error::kLedger, .ledger = receipt.reason});
        out_.receipt = receipt;
    }
    who_.book() = std::move(draft_);
    return std::move(out_);
}

}  // namespace game::mission::detail
