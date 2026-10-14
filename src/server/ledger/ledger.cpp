#include "ledger/ledger.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::ledger {
namespace {

constexpr std::size_t kNormal = 0;
constexpr std::size_t kBound = 1;

// Giao dịch đã gộp theo loại: kết quả không phụ thuộc thứ tự dòng của yêu cầu.
struct Tally {
    std::vector<Stack> takes;  // gộp theo item; bound không dùng
    std::vector<Stack> gives;  // gộp theo (item, bound)
    std::array<std::int64_t, 2> money_take{};
    std::array<std::int64_t, 2> money_give{};
    std::int64_t exp = 0;
};

template <typename Match>
void add_stack(std::vector<Stack>& list, const Stack& stack, Match same) {
    const auto found = std::ranges::find_if(list, [&](const Stack& one) { return same(one, stack); });
    if (found != list.end()) {
        found->count += stack.count;
    } else {
        list.push_back(stack);
    }
}

[[nodiscard]] bool amount_ok(const Entry& entry) noexcept { return entry.amount > 0 && entry.amount <= kMaxAmount; }

// Gộp các dòng. Dòng sai hình hoặc tổng vượt trần là kBadEntry; tổng một ô tối đa kMaxEntries * kMaxAmount < 2^47 nên
// phép cộng int64 không tràn trước khi so với trần.
[[nodiscard]] Reason tally_of(std::span<const Entry> entries, Tally& tally) {
    if (entries.empty()) return Reason::kEmpty;
    if (entries.size() > kMaxEntries) return Reason::kTooManyEntries;
    for (const Entry& entry : entries) {
        if (!amount_ok(entry)) return Reason::kBadEntry;
        const std::size_t pool = entry.bound ? kBound : kNormal;
        switch (entry.kind) {
            case EntryKind::kTakeItem:
                if (entry.item == 0) return Reason::kBadEntry;
                add_stack(tally.takes, Stack{.item = entry.item, .count = entry.amount, .bound = false},
                    [](const Stack& one, const Stack& other) { return one.item == other.item; });
                continue;
            case EntryKind::kGiveItem:
                if (entry.item == 0) return Reason::kBadEntry;
                add_stack(tally.gives, Stack{.item = entry.item, .count = entry.amount, .bound = entry.bound},
                    [](const Stack& one, const Stack& other) {
                        return one.item == other.item && one.bound == other.bound;
                    });
                continue;
            case EntryKind::kTakeMoney:
                if (entry.item != 0) return Reason::kBadEntry;
                tally.money_take.at(pool) += entry.amount;
                continue;
            case EntryKind::kGiveMoney:
                if (entry.item != 0) return Reason::kBadEntry;
                tally.money_give.at(pool) += entry.amount;
                continue;
            case EntryKind::kGiveExp:
                if (entry.item != 0 || entry.bound) return Reason::kBadEntry;
                tally.exp += entry.amount;
                continue;
        }
        return Reason::kBadEntry;  // giá trị kind ngoài tập: dữ liệu hỏng
    }
    const auto over = [](const Stack& stack) { return stack.count > kMaxAmount; };
    const bool too_big = std::ranges::any_of(tally.takes, over) || std::ranges::any_of(tally.gives, over) ||
                         std::ranges::any_of(tally.money_take, [](std::int64_t sum) { return sum > kMaxAmount; }) ||
                         std::ranges::any_of(tally.money_give, [](std::int64_t sum) { return sum > kMaxAmount; }) ||
                         tally.exp > kMaxAmount;
    return too_big ? Reason::kBadEntry : Reason::kCommitted;
}

// Kiểm đủ điều kiện trên trạng thái hiện tại, không đổi gì.
[[nodiscard]] Reason check(const Tally& tally, const Ports& ports) {
    for (const Stack& take : tally.takes) {
        if (ports.items.count(take.item) < take.count) return Reason::kMissingItems;
    }
    for (const std::size_t pool : {kNormal, kBound}) {
        if (ports.wallet.balance(pool == kBound) < tally.money_take.at(pool)) return Reason::kMissingMoney;
    }
    for (const std::size_t pool : {kNormal, kBound}) {
        // Thu tiền cùng loại giải phóng chỗ trước khi nhận, đúng thứ tự áp dụng bên dưới.
        if (tally.money_give.at(pool) > ports.wallet.room(pool == kBound) + tally.money_take.at(pool)) {
            return Reason::kWalletFull;
        }
    }
    if (!ports.items.fits(tally.takes, tally.gives)) return Reason::kNoRoom;
    return Reason::kCommitted;
}

[[nodiscard]] bool apply_all(const Tally& tally, const Ports& ports) noexcept {
    for (const Stack& take : tally.takes) {
        if (!ports.items.remove(take.item, take.count)) return false;
    }
    for (const std::size_t pool : {kNormal, kBound}) {
        const std::int64_t amount = tally.money_take.at(pool);
        if (amount > 0 && !ports.wallet.take(amount, pool == kBound)) return false;
    }
    for (const Stack& give : tally.gives) {
        if (!ports.items.give(give.item, give.count, give.bound)) return false;
    }
    for (const std::size_t pool : {kNormal, kBound}) {
        const std::int64_t amount = tally.money_give.at(pool);
        if (amount > 0 && !ports.wallet.give(amount, pool == kBound)) return false;
    }
    return tally.exp == 0 || ports.exp.give(tally.exp);
}

[[nodiscard]] Reason execute(const Request& request, const Ports& ports) {
    Tally tally;
    if (const Reason shape = tally_of(request.entries, tally); shape != Reason::kCommitted) return shape;
    if (const Reason state = check(tally, ports); state != Reason::kCommitted) return state;
    ports.items.checkpoint();
    ports.wallet.checkpoint();
    ports.exp.checkpoint();
    if (apply_all(tally, ports)) return Reason::kCommitted;
    ports.exp.rollback();
    ports.wallet.rollback();
    ports.items.rollback();
    return Reason::kPortFailure;
}

void audit_of(AuditSink* audit, const Request& request, Reason reason, bool replayed) noexcept {
    if (audit == nullptr) return;
    audit->record(AuditRecord{.request = request.id, .source = request.source, .reason = reason, .replayed = replayed,
        .entries = request.entries});
}

}  // namespace

std::string_view describe(Reason reason) noexcept {
    switch (reason) {
        case Reason::kCommitted: return "đã áp dụng";
        case Reason::kBadRequest: return "mã yêu cầu không hợp lệ";
        case Reason::kEmpty: return "giao dịch rỗng";
        case Reason::kTooManyEntries: return "quá nhiều dòng";
        case Reason::kBadEntry: return "dòng sai hình hoặc vượt trần";
        case Reason::kMissingItems: return "thiếu vật phẩm";
        case Reason::kMissingMoney: return "thiếu tiền";
        case Reason::kNoRoom: return "túi không đủ chỗ";
        case Reason::kWalletFull: return "ví chạm trần";
        case Reason::kPortFailure: return "cổng báo lỗi, đã quay lui";
        case Reason::kStale: return "mã yêu cầu cũ hơn nhật ký";
    }
    return "lý do không rõ";
}

std::optional<Receipt> Journal::seen(std::uint64_t request) const noexcept {
    const auto found = std::ranges::find(records_, request, &Record::request);
    if (found != records_.end()) return Receipt{.request = request, .reason = found->reason, .replayed = true};
    if (request <= floor_) return Receipt{.request = request, .reason = Reason::kStale, .replayed = false};
    return std::nullopt;
}

void Journal::record(std::uint64_t request, Reason reason) {
    if (request == 0 || std::ranges::contains(records_, request, &Record::request)) return;
    records_.push_back(Record{.request = request, .reason = reason});
    if (records_.size() > kJournalSize) {
        floor_ = std::max(floor_, records_.front().request);
        records_.erase(records_.begin());
    }
}

bool Journal::restore(std::uint64_t floor, std::span<const Record> records) {
    if (records.size() > kJournalSize) return false;
    for (std::size_t index = 0; index < records.size(); ++index) {
        if (records[index].request == 0) return false;
        for (std::size_t other = 0; other < index; ++other) {
            if (records[other].request == records[index].request) return false;
        }
    }
    floor_ = floor;
    records_.assign(records.begin(), records.end());
    return true;
}

Receipt commit(Journal& journal, const Request& request, const Ports& ports, AuditSink* audit) {
    if (request.id == 0) {
        const Receipt bad{.request = 0, .reason = Reason::kBadRequest, .replayed = false};
        audit_of(audit, request, bad.reason, false);
        return bad;
    }
    if (const std::optional<Receipt> before = journal.seen(request.id)) {
        audit_of(audit, request, before->reason, before->replayed);
        return *before;
    }
    const Reason reason = execute(request, ports);
    journal.record(request.id, reason);
    audit_of(audit, request, reason, false);
    return Receipt{.request = request.id, .reason = reason, .replayed = false};
}

}  // namespace game::ledger
