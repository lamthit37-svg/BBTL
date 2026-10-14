// Sổ cái nguyên tử: sai thì tiền và đồ nhân đôi hoặc mất thầm mà nhìn không ra. Ghim: áp dụng đủ hoặc không gì cả,
// quay lui đúng khi cổng lỗi, gửi lại cùng mã không áp dụng hai lần, bảo toàn qua 10.000 giao dịch ngẫu nhiên hạt giống cố định.
#include "dice/dice.hpp"
#include "ledger/ledger.hpp"
#include "support/ledger_fakes.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <map>
#include <print>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using ledger::Entry;
using ledger::EntryKind;
using ledger::Reason;
using ledger::Receipt;
using ledger::Request;

class VectorAudit final : public ledger::AuditSink {
public:
    struct Seen {
        std::uint64_t request = 0;
        Reason reason = Reason::kCommitted;
        bool replayed = false;
        std::size_t entries = 0;
    };
    std::vector<Seen> seen;
    // NOLINTNEXTLINE(bugprone-exception-escape): đồ giả của test, bad_alloc làm test dừng (HP-07)
    void record(const ledger::AuditRecord& one) noexcept override {
        seen.push_back(Seen{.request = one.request, .reason = one.reason, .replayed = one.replayed, .entries = one.entries.size()});
    }
};

Entry take_item(std::uint32_t item, std::int64_t amount) {
    return Entry{.kind = EntryKind::kTakeItem, .item = item, .amount = amount, .bound = false};
}
Entry give_item(std::uint32_t item, std::int64_t amount, bool bound = false) {
    return Entry{.kind = EntryKind::kGiveItem, .item = item, .amount = amount, .bound = bound};
}
Entry take_money(std::int64_t amount, bool bound = false) {
    return Entry{.kind = EntryKind::kTakeMoney, .item = 0, .amount = amount, .bound = bound};
}
Entry give_money(std::int64_t amount, bool bound = false) {
    return Entry{.kind = EntryKind::kGiveMoney, .item = 0, .amount = amount, .bound = bound};
}
Entry give_exp(std::int64_t amount) { return Entry{.kind = EntryKind::kGiveExp, .item = 0, .amount = amount, .bound = false}; }

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của std::map trong STL MSVC (HP-07)
struct Snapshot {
    std::map<std::uint32_t, std::int64_t> items;
    std::int64_t normal = 0;
    std::int64_t locked = 0;
    std::int64_t exp = 0;
    friend bool operator==(const Snapshot&, const Snapshot&) = default;
};

Snapshot snapshot(const FakeBundle& bundle) {
    Snapshot out;
    for (const auto& [item, amount] : bundle.items.total) {
        if (amount != 0) out.items[item] = amount;
    }
    out.normal = bundle.wallet.normal;
    out.locked = bundle.wallet.locked;
    out.exp = bundle.exp.total;
    return out;
}

Receipt run(ledger::Journal& journal, FakeBundle& bundle, std::uint64_t id, std::vector<Entry> entries,
    ledger::AuditSink* audit = nullptr) {
    const Request request{.id = id, .source = 77, .entries = entries};
    return ledger::commit(journal, request, bundle.ports(), audit);
}

void commit_applies_every_line(Context& context) {
    FakeBundle bundle;
    bundle.items.total[100] = 5;
    bundle.wallet.normal = 1000;
    ledger::Journal journal;
    VectorAudit audit;
    const Receipt receipt = run(journal, bundle, 1,
        {take_item(100, 2), give_item(200, 3, true), take_money(500), give_money(70, true), give_exp(900)}, &audit);
    context.expect(receipt.committed() && !receipt.replayed && receipt.request == 1, "đã áp dụng");
    context.expect(bundle.items.count(100) == 3 && bundle.items.count(200) == 3, "vật phẩm");
    context.expect(bundle.items.bound[200] == 3, "cờ khoá của vật phẩm nhận");
    context.expect(bundle.wallet.normal == 500 && bundle.wallet.locked == 70 && bundle.exp.total == 900, "tiền và kinh nghiệm");
    context.expect(audit.seen.size() == 1 && audit.seen[0].entries == 5 && !audit.seen[0].replayed, "nhật ký kiểm toán");
}

void rejects_leave_state_untouched(Context& context) {
    struct Case {
        std::vector<Entry> entries;
        Reason expected;
        const char* what;
    };
    const std::vector<Case> cases{
        {.entries = {}, .expected = Reason::kEmpty, .what = "rỗng"},
        {.entries = {take_item(100, 99)}, .expected = Reason::kMissingItems, .what = "thiếu đồ"},
        {.entries = {take_money(5000)}, .expected = Reason::kMissingMoney, .what = "thiếu tiền"},
        {.entries = {take_money(5000, true)}, .expected = Reason::kMissingMoney, .what = "thiếu tiền khoá"},
        {.entries = {give_item(300, 400)}, .expected = Reason::kNoRoom, .what = "túi đầy"},
        {.entries = {give_money(std::int64_t{1} << 40)}, .expected = Reason::kWalletFull, .what = "đúng trần một dòng nhưng ví không chứa nổi"},
        {.entries = {give_item(0, 1)}, .expected = Reason::kBadEntry, .what = "mẫu 0"},
        {.entries = {take_item(100, 0)}, .expected = Reason::kBadEntry, .what = "số lượng 0"},
        {.entries = {take_item(100, -3)}, .expected = Reason::kBadEntry, .what = "số lượng âm"},
        {.entries = {give_exp((std::int64_t{1} << 40) + 1)}, .expected = Reason::kBadEntry, .what = "vượt trần"},
        {.entries = {Entry{.kind = EntryKind::kGiveMoney, .item = 5, .amount = 10, .bound = false}}, .expected = Reason::kBadEntry, .what = "tiền mang mẫu vật phẩm"},
        {.entries = {Entry{.kind = EntryKind::kGiveExp, .item = 0, .amount = 10, .bound = true}}, .expected = Reason::kBadEntry, .what = "kinh nghiệm khoá"},
        {.entries = {Entry{.kind = static_cast<EntryKind>(9), .item = 0, .amount = 10, .bound = false}}, .expected = Reason::kBadEntry, .what = "loại dòng ngoài tập"},
    };
    std::uint64_t id = 1;
    for (const Case& one : cases) {
        FakeBundle bundle;
        bundle.items.total[100] = 5;
        bundle.items.capacity = 1;
        bundle.wallet.normal = 100;
        bundle.wallet.cap = 1000;
        ledger::Journal journal;
        const Snapshot before = snapshot(bundle);
        const Receipt receipt = run(journal, bundle, id++, one.entries);
        context.expect(receipt.reason == one.expected, one.what);
        context.expect(snapshot(bundle) == before, one.what);
    }
    const std::vector<Entry> many(ledger::kMaxEntries + 1, give_exp(1));
    FakeBundle bundle;
    ledger::Journal journal;
    context.expect(run(journal, bundle, 1, many).reason == Reason::kTooManyEntries, "quá nhiều dòng");
    context.expect(run(journal, bundle, 0, {give_exp(1)}).reason == Reason::kBadRequest, "mã 0");
    context.expect(bundle.exp.total == 0, "không dòng nào chạy");
}

void port_failure_rolls_back_everything(Context& context) {
    for (std::int64_t after = 0; after < 6; ++after) {
        FakeBundle bundle;
        bundle.items.total[100] = 5;
        bundle.items.bound[100] = 2;
        bundle.wallet.normal = 1000;
        bundle.items.fail_after = after;
        ledger::Journal journal;
        const Snapshot before = snapshot(bundle);
        const auto bound_before = bundle.items.bound;
        const Receipt receipt = run(journal, bundle, 1,
            {take_item(100, 2), give_item(200, 3), give_item(201, 1), take_money(10), give_exp(5)});
        // Số thao tác vật phẩm của giao dịch là 3: lỗi chèn trước thao tác thứ 3 thì phải quay lui, sau đó thì xong.
        if (after < 3) {
            context.expect(receipt.reason == Reason::kPortFailure, "báo lỗi cổng");
            context.expect(snapshot(bundle) == before && bundle.items.bound == bound_before, "quay lui cả cờ khoá");
        } else {
            context.expect(receipt.committed(), "đủ thao tác thì xong");
        }
    }
    FakeBundle wallet_fail;
    wallet_fail.wallet.normal = 50;
    wallet_fail.wallet.fail_give = true;
    ledger::Journal journal;
    const Snapshot before = snapshot(wallet_fail);
    context.expect(run(journal, wallet_fail, 1, {take_money(10), give_money(5)}).reason == Reason::kPortFailure, "ví lỗi");
    context.expect(snapshot(wallet_fail) == before, "ví lỗi quay lui");
    FakeBundle exp_fail;
    exp_fail.items.total[7] = 3;
    exp_fail.exp.fail = true;
    const Snapshot exp_before = snapshot(exp_fail);
    context.expect(run(journal, exp_fail, 2, {take_item(7, 3), give_exp(10)}).reason == Reason::kPortFailure,
        "kinh nghiệm lỗi");
    context.expect(snapshot(exp_fail) == exp_before, "kinh nghiệm lỗi kéo theo mọi thứ quay lui");
}

void resend_is_idempotent(Context& context) {
    FakeBundle bundle;
    bundle.items.total[100] = 5;
    ledger::Journal journal;
    VectorAudit audit;
    const Receipt first = run(journal, bundle, 5, {take_item(100, 2), give_exp(40)}, &audit);
    const Snapshot after_first = snapshot(bundle);
    const Receipt again = run(journal, bundle, 5, {take_item(100, 2), give_exp(40)}, &audit);
    context.expect(first.committed() && !first.replayed, "lần đầu");
    context.expect(again.committed() && again.replayed && again.request == 5, "gửi lại trả biên nhận cũ");
    context.expect(snapshot(bundle) == after_first, "không áp dụng lần hai");
    context.expect(audit.seen.size() == 2 && audit.seen[1].replayed, "kiểm toán ghi lần gửi lại");
    // Cùng mã nhưng nội dung khác vẫn là gửi lại: mã định danh giao dịch, nội dung không được tin lần hai.
    const Receipt changed = run(journal, bundle, 5, {give_exp(999999)});
    context.expect(changed.replayed && snapshot(bundle) == after_first, "đổi nội dung dưới cùng mã không có tác dụng");
    // Từ chối cũng được nhớ: trạng thái đổi sau đó không làm lần gửi lại thành công.
    const Receipt rejected = run(journal, bundle, 6, {take_item(100, 50)});
    bundle.items.total[100] = 500;
    const Receipt rejected_again = run(journal, bundle, 6, {take_item(100, 50)});
    context.expect(rejected.reason == Reason::kMissingItems && rejected_again.reason == Reason::kMissingItems &&
                       rejected_again.replayed,
        "từ chối được nhớ");
    context.expect(bundle.items.count(100) == 500, "không thu gì");
}

void stale_ids_are_refused(Context& context) {
    FakeBundle bundle;
    ledger::Journal journal;
    for (std::uint64_t id = 1; id <= ledger::kJournalSize + 10; ++id) {
        context.expect(run(journal, bundle, id, {give_exp(1)}).committed(), "chạy tuần tự");
    }
    const std::int64_t exp = bundle.exp.total;
    context.expect(journal.records().size() == ledger::kJournalSize, "nhật ký đầy thì giữ đúng kích thước");
    const Receipt stale = run(journal, bundle, 3, {give_exp(1)});
    context.expect(stale.reason == Reason::kStale && !stale.replayed, "mã đã bị quên bị từ chối");
    context.expect(bundle.exp.total == exp, "không áp dụng");
    context.expect(journal.floor() >= 10, "mốc đã nâng");
    const Receipt recent = run(journal, bundle, ledger::kJournalSize + 10, {give_exp(1)});
    context.expect(recent.replayed && recent.committed(), "mã gần đây còn nhớ");
    // Mã cách quãng chưa từng dùng vẫn mới.
    const Receipt gap = run(journal, bundle, 1000, {give_exp(1)});
    const Receipt below = run(journal, bundle, 999, {give_exp(1)});
    context.expect(gap.committed() && below.committed() && !below.replayed, "khoảng trống mã là mã mới");
}

void line_order_does_not_matter(Context& context) {
    std::vector<Entry> lines{take_item(100, 2), give_item(200, 3), take_money(40), give_money(5), give_exp(9),
        give_item(200, 1, true)};
    std::array<Snapshot, 2> results;
    for (std::size_t round = 0; round < 2; ++round) {
        FakeBundle bundle;
        bundle.items.total[100] = 5;
        bundle.wallet.normal = 100;
        ledger::Journal journal;
        if (round == 1) std::ranges::reverse(lines);
        context.expect(run(journal, bundle, 1, lines).committed(), "xong");
        results.at(round) = snapshot(bundle);
    }
    context.expect(results[0] == results[1], "đảo thứ tự dòng cho cùng kết quả");
}

void duplicate_lines_are_summed(Context& context) {
    FakeBundle bundle;
    bundle.items.total[100] = 5;
    bundle.wallet.normal = 100;
    ledger::Journal journal;
    const Snapshot before = snapshot(bundle);
    context.expect(run(journal, bundle, 1, {take_item(100, 3), take_item(100, 3)}).reason == Reason::kMissingItems,
        "hai dòng thu cộng lại vượt số có");
    context.expect(run(journal, bundle, 2, {take_money(60), take_money(60)}).reason == Reason::kMissingMoney,
        "hai dòng thu tiền cộng lại");
    context.expect(snapshot(bundle) == before, "không đổi");
}

void take_frees_room(Context& context) {
    FakeBundle bundle;
    bundle.items.capacity = 1;
    bundle.items.stack_max = 10;
    bundle.items.total[100] = 10;
    bundle.wallet.cap = 100;
    bundle.wallet.normal = 100;
    ledger::Journal journal;
    context.expect(run(journal, bundle, 1, {give_item(200, 10)}).reason == Reason::kNoRoom, "túi đầy");
    context.expect(run(journal, bundle, 2, {take_item(100, 10), give_item(200, 10)}).committed(), "thu rồi mới nhận");
    context.expect(run(journal, bundle, 3, {give_money(1)}).reason == Reason::kWalletFull, "ví đầy");
    context.expect(run(journal, bundle, 4, {take_money(40), give_money(40)}).committed(), "thu tiền cùng ngăn nhả chỗ");
}

void journal_restore_validates(Context& context) {
    ledger::Journal original;
    FakeBundle bundle;
    for (std::uint64_t id = 1; id <= 5; ++id) {
        static_cast<void>(run(original, bundle, id * 3, {give_exp(1)}));
    }
    ledger::Journal copy;
    context.expect(copy.restore(original.floor(), original.records()) && copy == original, "khôi phục nguyên trạng");
    ledger::Journal strict;
    const std::array<ledger::Journal::Record, 2> dup{
        {{.request = 4, .reason = Reason::kCommitted}, {.request = 4, .reason = Reason::kCommitted}}};
    context.expect(!strict.restore(0, dup), "mã trùng bị từ chối");
    const std::array<ledger::Journal::Record, 1> zero{{{.request = 0, .reason = Reason::kCommitted}}};
    context.expect(!strict.restore(0, zero), "mã 0 bị từ chối");
    const std::vector<ledger::Journal::Record> big(ledger::kJournalSize + 1, ledger::Journal::Record{.request = 1, .reason = Reason::kCommitted});
    context.expect(!strict.restore(0, big), "quá cỡ bị từ chối");
    context.expect(strict.records().empty() && strict.floor() == 0, "hỏng thì không đổi gì");
}

// ----- Bảo toàn qua 10.000 giao dịch ngẫu nhiên -----------------------------------------------------------------------
// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của std::map trong STL MSVC (HP-07)
struct Model {
    std::map<std::uint32_t, std::int64_t> items;
    std::array<std::int64_t, 2> money{};
    std::int64_t exp = 0;
};

constexpr std::int64_t kStack = 20;
constexpr std::int32_t kCapacity = 16;
constexpr std::int64_t kWalletCap = 5000;

std::int32_t slots_of(const std::map<std::uint32_t, std::int64_t>& items) {
    std::int64_t used = 0;
    for (const auto& [item, amount] : items) {
        static_cast<void>(item);
        if (amount > 0) used += (amount + kStack - 1) / kStack;
    }
    return static_cast<std::int32_t>(used);
}

// Người phán xử độc lập: cùng luật bằng số học thẳng trên Model, không dùng mã của ledger.
Reason oracle(const Model& state, std::span<const Entry> entries, Model& next) {
    next = state;
    if (entries.empty()) return Reason::kEmpty;
    if (entries.size() > ledger::kMaxEntries) return Reason::kTooManyEntries;
    std::map<std::uint32_t, std::int64_t> take;
    std::map<std::uint32_t, std::int64_t> give;
    std::array<std::int64_t, 2> money_take{};
    std::array<std::int64_t, 2> money_give{};
    std::int64_t exp = 0;
    for (const Entry& one : entries) {
        if (one.amount <= 0 || one.amount > ledger::kMaxAmount) return Reason::kBadEntry;
        const std::size_t pool = one.bound ? 1 : 0;
        const bool item_kind = one.kind == EntryKind::kTakeItem || one.kind == EntryKind::kGiveItem;
        if (item_kind && one.item == 0) return Reason::kBadEntry;
        if (one.kind == EntryKind::kTakeItem) take[one.item] += one.amount;
        if (one.kind == EntryKind::kGiveItem) give[one.item] += one.amount;
        if (one.kind == EntryKind::kTakeMoney) money_take.at(pool) += one.amount;
        if (one.kind == EntryKind::kGiveMoney) money_give.at(pool) += one.amount;
        if (one.kind == EntryKind::kGiveExp) exp += one.amount;
    }
    for (const auto& [item, amount] : take) {
        const auto found = state.items.find(item);
        if (found == state.items.end() || found->second < amount) return Reason::kMissingItems;
    }
    for (std::size_t pool = 0; pool < 2; ++pool) {
        if (state.money.at(pool) < money_take.at(pool)) return Reason::kMissingMoney;
    }
    for (std::size_t pool = 0; pool < 2; ++pool) {
        if (state.money.at(pool) - money_take.at(pool) + money_give.at(pool) > kWalletCap) return Reason::kWalletFull;
    }
    for (const auto& [item, amount] : take) next.items[item] -= amount;
    for (const auto& [item, amount] : give) next.items[item] += amount;
    if (slots_of(next.items) > kCapacity) {
        next = state;
        return Reason::kNoRoom;
    }
    for (std::size_t pool = 0; pool < 2; ++pool) next.money.at(pool) += money_give.at(pool) - money_take.at(pool);
    next.exp += exp;
    return Reason::kCommitted;
}

Entry random_entry(dice::Dice& rng) {
    Entry one;
    one.kind = static_cast<EntryKind>(rng.below(5));
    one.amount = rng.between(1, 30);
    if ((one.kind == EntryKind::kTakeMoney || one.kind == EntryKind::kGiveMoney) && rng.chance_permille(500)) {
        one.amount = rng.between(1, 1500);
    }
    if (rng.chance_permille(40)) one.amount = rng.chance_permille(500) ? 0 : -rng.between(1, 5);
    one.bound = rng.chance_permille(500);
    if (one.kind == EntryKind::kTakeItem || one.kind == EntryKind::kGiveItem) {
        one.item = static_cast<std::uint32_t>(rng.between(1, 6));
        if (rng.chance_permille(15)) one.item = 0;
        if (one.kind == EntryKind::kTakeItem) one.bound = false;
    } else if (one.kind == EntryKind::kGiveExp) {
        one.bound = false;
    }
    return one;
}

Model model_of(const FakeBundle& bundle) {
    Model out;
    for (const auto& [item, amount] : bundle.items.total) {
        if (amount != 0) out.items[item] = amount;
    }
    out.money = {bundle.wallet.normal, bundle.wallet.locked};
    out.exp = bundle.exp.total;
    return out;
}

bool same(const Model& left, const Model& right) {
    const auto trim = [](std::map<std::uint32_t, std::int64_t> items) {
        std::erase_if(items, [](const auto& pair) { return pair.second == 0; });
        return items;
    };
    return trim(left.items) == trim(right.items) && left.money == right.money && left.exp == right.exp;
}

void random_transactions_conserve(Context& context) {
    dice::Dice rng(0x1ED6E7);
    FakeBundle bundle;
    bundle.items.capacity = kCapacity;
    bundle.items.stack_max = kStack;
    bundle.wallet.cap = kWalletCap;
    for (std::uint32_t item = 1; item <= 6; ++item) bundle.items.total[item] = 30;
    bundle.wallet.normal = 1000;
    bundle.wallet.locked = 1000;
    ledger::Journal journal;
    const Model initial = model_of(bundle);
    Model issued;
    Model consumed;
    std::map<Reason, int> outcomes;
    std::vector<std::pair<std::uint64_t, Receipt>> recent;
    std::uint64_t next_id = 1;
    bool every_step_exact = true;
    for (int round = 0; round < 10000; ++round) {
        const bool resend = !recent.empty() && rng.chance_permille(80);
        if (resend) {
            const auto& [id, old] = recent[rng.below(recent.size())];
            const Model before = model_of(bundle);
            const std::vector<Entry> noise{give_exp(1), give_item(1, 1)};
            const Receipt again = ledger::commit(journal, Request{.id = id, .source = 1, .entries = noise}, bundle.ports());
            every_step_exact = every_step_exact && again.replayed && again.reason == old.reason && same(before, model_of(bundle));
            continue;
        }
        std::vector<Entry> entries;
        const auto length = static_cast<std::uint64_t>(rng.chance_permille(5) ? 0 : rng.between(1, 6));
        entries.reserve(length);
        for (std::uint64_t one = 0; one < length; ++one) entries.push_back(random_entry(rng));
        const bool inject = rng.chance_permille(200);
        bundle.items.operations = 0;
        bundle.items.fail_after = inject ? rng.between(0, 4) : -1;
        const Model before = model_of(bundle);
        Model expected;
        const Reason verdict = oracle(before, entries, expected);
        const std::uint64_t id = next_id++;
        const Receipt receipt = ledger::commit(journal, Request{.id = id, .source = 9, .entries = entries}, bundle.ports());
        const Model after = model_of(bundle);
        ++outcomes[receipt.reason];
        bool exact = false;
        if (verdict != Reason::kCommitted) {
            exact = receipt.reason == verdict && same(after, before);
        } else if (receipt.committed()) {
            exact = same(after, expected);
            for (const Entry& one : entries) {
                const std::size_t pool = one.bound ? 1 : 0;
                if (one.kind == EntryKind::kGiveItem) issued.items[one.item] += one.amount;
                if (one.kind == EntryKind::kTakeItem) consumed.items[one.item] += one.amount;
                if (one.kind == EntryKind::kGiveMoney) issued.money.at(pool) += one.amount;
                if (one.kind == EntryKind::kTakeMoney) consumed.money.at(pool) += one.amount;
                if (one.kind == EntryKind::kGiveExp) issued.exp += one.amount;
            }
        } else {
            exact = inject && receipt.reason == Reason::kPortFailure && same(after, before);
        }
        every_step_exact = every_step_exact && exact;
        recent.emplace_back(id, receipt);
        if (recent.size() > 20) recent.erase(recent.begin());
    }
    bundle.items.fail_after = -1;
    for (const auto& [reason, count] : outcomes) {
        const std::string_view name = ledger::describe(reason);
        std::print("  [bảo toàn] {}: {}\n", name, count);
    }
    context.expect(every_step_exact, "mỗi giao dịch khớp người phán xử, từ chối và quay lui không đổi gì, gửi lại không đổi gì");
    context.expect(outcomes[Reason::kCommitted] > 1500, "đủ giao dịch thành công");
    context.expect(outcomes[Reason::kPortFailure] > 150, "đủ ca quay lui");
    context.expect(outcomes[Reason::kMissingItems] > 500 && outcomes[Reason::kMissingMoney] > 100 &&
                       outcomes[Reason::kNoRoom] > 300 && outcomes[Reason::kWalletFull] > 100,
        "đủ ca từ chối theo từng lý do trạng thái");
    context.expect(outcomes[Reason::kBadEntry] > 100, "đủ ca dòng sai hình");
    const Model finish = model_of(bundle);
    bool conserved = finish.exp == initial.exp + issued.exp;
    for (std::uint32_t item = 1; item <= 6; ++item) {
        const std::int64_t start = initial.items.contains(item) ? initial.items.at(item) : 0;
        const std::int64_t now = finish.items.contains(item) ? finish.items.at(item) : 0;
        const std::int64_t gain = issued.items.contains(item) ? issued.items.at(item) : 0;
        const std::int64_t loss = consumed.items.contains(item) ? consumed.items.at(item) : 0;
        conserved = conserved && now == start + gain - loss;
    }
    for (std::size_t pool = 0; pool < 2; ++pool) {
        conserved = conserved && finish.money.at(pool) == initial.money.at(pool) + issued.money.at(pool) - consumed.money.at(pool);
    }
    context.expect(conserved, "cuối cùng: số có = ban đầu + đã nhận - đã thu, cho từng mẫu, ngăn tiền và kinh nghiệm");
}

constexpr std::array kCases{
    Case{.name = "commit_applies_every_line", .body = commit_applies_every_line},
    Case{.name = "rejects_leave_state_untouched", .body = rejects_leave_state_untouched},
    Case{.name = "port_failure_rolls_back_everything", .body = port_failure_rolls_back_everything},
    Case{.name = "resend_is_idempotent", .body = resend_is_idempotent},
    Case{.name = "stale_ids_are_refused", .body = stale_ids_are_refused},
    Case{.name = "line_order_does_not_matter", .body = line_order_does_not_matter},
    Case{.name = "duplicate_lines_are_summed", .body = duplicate_lines_are_summed},
    Case{.name = "take_frees_room", .body = take_frees_room},
    Case{.name = "journal_restore_validates", .body = journal_restore_validates},
    Case{.name = "random_transactions_conserve", .body = random_transactions_conserve},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
