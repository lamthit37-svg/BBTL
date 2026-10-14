#include "mission/book.hpp"

#include "ledger/ledger.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::mission {
namespace {

[[nodiscard]] bool quest_in_range(std::int32_t quest) noexcept { return quest >= 0 && quest < kQuestIdLimit; }

[[nodiscard]] std::size_t word_of(std::int32_t quest) noexcept { return static_cast<std::size_t>(quest / kDoneBits); }
[[nodiscard]] std::uint32_t bit_of(std::int32_t quest) noexcept {
    return std::uint32_t{1} << static_cast<unsigned>(quest % kDoneBits);
}

}  // namespace

const Slot* Book::find(std::int32_t quest) const noexcept {
    if (quest < 0) return nullptr;
    const auto found = std::ranges::find(slots, quest, &Slot::mission);
    return found == slots.end() ? nullptr : &*found;
}

Slot* Book::find(std::int32_t quest) noexcept {
    if (quest < 0) return nullptr;
    const auto found = std::ranges::find(slots, quest, &Slot::mission);
    return found == slots.end() ? nullptr : &*found;
}

std::int32_t Book::active() const noexcept {
    return static_cast<std::int32_t>(std::ranges::count_if(slots, &Slot::used));
}

std::int32_t Book::free_slots() const noexcept { return static_cast<std::int32_t>(kSlotCount) - active(); }

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): nhiệm vụ, script và cờ theo dõi khác vai, nơi gọi nêu tên (HP-07)
Slot* Book::add(std::int32_t quest, std::int32_t script, std::uint8_t watch) noexcept {
    if (!quest_in_range(quest) || find(quest) != nullptr) return nullptr;
    const auto empty = std::ranges::find_if(slots, [](const Slot& slot) { return !slot.used(); });
    if (empty == slots.end()) return nullptr;
    *empty = Slot{};
    empty->mission = quest;
    empty->script = script;
    empty->flags = static_cast<std::uint8_t>(watch & kWatchMask);
    return &*empty;
}

bool Book::remove(std::int32_t quest) noexcept {
    Slot* const slot = find(quest);
    if (slot == nullptr) return false;
    *slot = Slot{};
    return true;
}

bool Book::is_done(std::int32_t quest) const noexcept {
    return quest_in_range(quest) && (done.at(word_of(quest)) & bit_of(quest)) != 0U;
}

void Book::mark_done(std::int32_t quest) noexcept {
    if (quest_in_range(quest)) done.at(word_of(quest)) |= bit_of(quest);
}

void Book::clear_done(std::int32_t quest) noexcept {
    if (quest_in_range(quest)) done.at(word_of(quest)) &= ~bit_of(quest);
}

std::int64_t Book::counter(std::int32_t index) const noexcept {
    const auto found = std::ranges::lower_bound(counters, index, {}, &Counter::index);
    return found != counters.end() && found->index == index ? found->value : 0;
}

bool Book::set_counter(std::int32_t index, std::int64_t value) {
    if (index < 0 || value > kCounterLimit || value < -kCounterLimit) return false;
    const auto found = std::ranges::lower_bound(counters, index, {}, &Counter::index);
    const bool present = found != counters.end() && found->index == index;
    if (value == 0) {
        if (present) counters.erase(found);
        return true;
    }
    if (present) {
        found->value = value;
        return true;
    }
    if (counters.size() >= kMaxCounters) return false;
    counters.insert(found, Counter{.index = index, .value = value});
    return true;
}

bool Book::flag(std::int32_t index) const noexcept { return std::ranges::binary_search(flags, index); }

bool Book::set_flag(std::int32_t index, bool on) {
    if (index < 0) return false;
    const auto found = std::ranges::lower_bound(flags, index);
    const bool present = found != flags.end() && *found == index;
    if (!on) {
        if (present) flags.erase(found);
        return true;
    }
    if (present) return true;
    if (flags.size() >= kMaxFlags) return false;
    flags.insert(found, index);
    return true;
}

bool well_formed(const Book& book) noexcept {
    for (std::size_t first = 0; first < kSlotCount; ++first) {
        const Slot& slot = book.slots.at(first);
        if (!slot.used()) {
            if (slot != Slot{}) return false;
            continue;
        }
        if (!quest_in_range(slot.mission) || slot.script < kNoMission || (slot.flags & ~kWatchMask) != 0) return false;
        for (std::size_t second = 0; second < first; ++second) {
            if (book.slots.at(second).mission == slot.mission) return false;
        }
    }
    if (book.counters.size() > kMaxCounters || book.flags.size() > kMaxFlags) return false;
    for (std::size_t index = 0; index < book.counters.size(); ++index) {
        const Counter& counter = book.counters[index];
        if (counter.index < 0 || counter.value == 0 || counter.value > kCounterLimit || counter.value < -kCounterLimit) {
            return false;
        }
        if (index > 0 && book.counters[index - 1].index >= counter.index) return false;
    }
    for (std::size_t index = 0; index < book.flags.size(); ++index) {
        if (book.flags[index] < 0 || (index > 0 && book.flags[index - 1] >= book.flags[index])) return false;
    }
    for (const ledger::Journal::Record& record : book.journal.records()) {
        if (record.request > book.ledger_seq) return false;
    }
    return book.journal.floor() <= book.ledger_seq;
}

}  // namespace game::mission
