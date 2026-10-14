// Kịch bản tất định chạy trên một Book: nạp tiền (kể cả gọi lại, báo muộn, mâu thuẫn), hoàn tiền, đổi điểm lấy
// ingot hai pha (kể cả mạng đứt giữa chừng, báo lặp, báo ngược), chỉnh tay, tiêu ingot, đóng băng, quét
// đơn quá hạn. Mỗi bước ghi một dòng vết bằng chữ; id không có trong vết, nên MemoryBook và PgBook
// (id cấp khác nhau) phải ra CÙNG vết. Cuối kịch bản: sổ phải cân (điểm nạp = điểm còn + điểm đã đổi + hoàn
// + phần chỉnh tay) và bản nhớ đệm khớp sổ.
//
// Nguồn ngẫu nhiên là xorshift64* tại chỗ (không <random>, không dice của dự án): kịch bản là công cụ
// thử, không phải logic game, và cần cố định theo hạt giống trên mọi thư viện chuẩn.
#pragma once

#include "billing/book.hpp"
#include "billing/error.hpp"

#include "billing_support.hpp"

#include <cstdint>
#include <format>
#include <optional>
#include <string>
#include <vector>

namespace game::billing::script {

class Rng {
public:
    explicit Rng(std::uint64_t seed) noexcept : state_(seed == 0 ? 0x9E3779B97F4A7C15ULL : seed) {}
    [[nodiscard]] std::uint64_t next() noexcept {
        state_ ^= state_ >> 12U;
        state_ ^= state_ << 25U;
        state_ ^= state_ >> 27U;
        return state_ * 0x2545F4914F6CDD1DULL;
    }
    [[nodiscard]] std::uint64_t below(std::uint64_t bound) noexcept { return (next() >> 11U) % bound; }

private:
    std::uint64_t state_;
};

struct Outcome {
    std::vector<std::string> trace;
    bool balanced = false;
    std::int64_t mismatched = -1;
    // Số bước theo loại, để test chắc rằng kịch bản thật sự chạm mọi nhánh.
    std::int64_t duplicates = 0;
    std::int64_t conflicts = 0;
    std::int64_t replays = 0;
    std::int64_t refunds = 0;
    std::int64_t stale = 0;
    std::int64_t cancelled = 0;
    std::int64_t confirmed = 0;
    std::int64_t insufficient = 0;
    Conservation final_check;
};

template <typename T>
[[nodiscard]] std::string code_of(const Result<T>& result) {
    return result ? "ok" : std::format("e{}", static_cast<unsigned>(result.error()));
}

class Script {
public:
    Script(Book& book, std::uint64_t seed) : book_(&book), rng_(seed) {}

    [[nodiscard]] Outcome run(int steps) {
        for (int step = 0; step < steps; ++step) {
            now_ += static_cast<std::int64_t>(rng_.below(60)) + 1;
            const std::uint64_t pick = rng_.below(100);
            if (pick < 30) {
                top_up();
            } else if (pick < 35) {
                refund();
            } else if (pick < 65) {
                exchange_begin();
            } else if (pick < 85) {
                exchange_finish();
            } else if (pick < 88) {
                sweep();
            } else if (pick < 91) {
                admin();
            } else if (pick < 94) {
                spend();
            } else if (pick < 97) {
                freeze();
            } else {
                look();
            }
        }
        finish();
        return std::move(out_);
    }

private:
    struct Paid {
        std::string provider;
        std::string trade;
    };

    [[nodiscard]] UnixTime now() const noexcept { return UnixTime{now_}; }
    [[nodiscard]] AccountId pick_account() { return AccountId{1 + rng_.below(20)}; }
    void note(std::string line) { out_.trace.push_back(std::move(line)); }

    static std::string status_text(PaymentStatus status) { return std::string{to_text(status)}; }

    void send(const PaymentEvent& event, std::string_view tag) {
        const Result<PaymentOutcome> result = book_->apply_payment(event, now());
        if (!result) {
            note(std::format("pay {} {} {} -> {}", tag, event.trade_no, status_text(event.status), code_of(result)));
            if (result.error() == Error::kConflict) ++out_.conflicts;
            if (result.error() == Error::kInsufficient) ++out_.insufficient;
            return;
        }
        if (result->result == PaymentResult::kDuplicate) ++out_.duplicates;
        note(std::format("pay {} {} {} -> r{} st={} bal={}", tag, event.trade_no, status_text(event.status),
            static_cast<unsigned>(result->result), status_text(result->record.event.status), result->balance.value()));
    }

    void top_up() {
        PaymentEvent event;
        event.provider = rng_.below(2) == 0 ? "alpha" : "beta";
        event.trade_no = std::format("T{}", next_trade_++);
        event.account = pick_account();
        event.points = Points{10 + static_cast<std::int64_t>(rng_.below(5000))};
        event.amount_minor = event.points.value() * 1000;
        event.currency = "VND";
        const std::uint64_t style = rng_.below(10);
        if (style < 2) {
            event.status = PaymentStatus::kPending;
            send(event, "first");
        }
        event.status = style == 2 ? PaymentStatus::kFailed : PaymentStatus::kPaid;
        send(event, "final");
        if (rng_.below(10) < 3) send(event, "again");
        if (rng_.below(20) == 0) {
            PaymentEvent bad = event;
            bad.points = Points{event.points.value() + 1};
            send(bad, "mismatch");
        }
        if (event.status == PaymentStatus::kPaid && rng_.below(10) < 2) {
            PaymentEvent late = event;
            late.status = PaymentStatus::kPending;
            send(late, "late");
        }
        if (event.status == PaymentStatus::kPaid) paid_.push_back({.provider = event.provider, .trade = event.trade_no});
    }

    void refund() {
        if (paid_.empty()) return;
        const std::size_t index = rng_.below(paid_.size());
        const Paid target = paid_[index];
        const Result<PaymentOutcome> result = book_->refund_payment({.provider = target.provider, .trade_no = target.trade}, {.reason = "kiểm thử", .actor = "bot"}, now());
        if (result) {
            ++out_.refunds;
            paid_.erase(paid_.begin() + static_cast<std::ptrdiff_t>(index));
            note(std::format("refund {} -> ok bal={}", target.trade, result->balance.value()));
            const Result<PaymentOutcome> again = book_->refund_payment({.provider = target.provider, .trade_no = target.trade}, {.reason = "lần hai", .actor = "bot"}, now());
            note(std::format("refund-again {} -> {} r{}", target.trade, code_of(again),
                again ? static_cast<unsigned>(again->result) : 0U));
            return;
        }
        if (result.error() == Error::kInsufficient) ++out_.insufficient;
        note(std::format("refund {} -> {}", target.trade, code_of(result)));
    }

    void exchange_begin() {
        ExchangeRequest request;
        request.account = pick_account();
        request.character = CharacterId{1000 + request.account.value()};
        request.request = RequestId{next_request_++};
        request.ingot = Ingot{1 + static_cast<std::int64_t>(rng_.below(200))};
        const Result<ExchangeOutcome> result = book_->exchange_begin(request, now());
        if (!result) {
            if (result.error() == Error::kInsufficient) ++out_.insufficient;
            note(std::format("begin a={} i={} -> {}", request.account.value(), request.ingot.value(), code_of(result)));
            return;
        }
        open_.push_back(result->order.id);
        note(std::format("begin a={} i={} -> ok cost={} bal={}", request.account.value(), request.ingot.value(),
            result->order.points.value(), result->balance.value()));
        if (rng_.below(10) < 3) {
            // Mạng đứt sau pha một: world gọi lại với cùng request.
            const Result<ExchangeOutcome> again = book_->exchange_begin(request, now());
            if (again && again->replayed) ++out_.replays;
            note(std::format("begin-replay -> {} replayed={} same={} bal={}", code_of(again),
                again ? again->replayed : false, again ? again->order.id == result->order.id : false,
                again ? again->balance.value() : -1));
        }
        if (rng_.below(20) == 0) {
            ExchangeRequest changed = request;
            changed.ingot = Ingot{request.ingot.value() + 1};
            const Result<ExchangeOutcome> conflict = book_->exchange_begin(changed, now());
            if (!conflict && conflict.error() == Error::kConflict) ++out_.conflicts;
            note(std::format("begin-conflict -> {}", code_of(conflict)));
        }
    }

    void exchange_finish() {
        if (open_.empty()) return;
        const std::size_t index = rng_.below(open_.size());
        const ExchangeId order = open_[index];
        const Verdict verdict = rng_.below(10) < 7 ? Verdict::kDone : Verdict::kCancelled;
        const Result<ExchangeOutcome> result = book_->exchange_finish(order, verdict, now());
        if (!result) {
            note(std::format("finish v={} -> {}", static_cast<unsigned>(verdict), code_of(result)));
            return;
        }
        open_.erase(open_.begin() + static_cast<std::ptrdiff_t>(index));
        if (verdict == Verdict::kDone) ++out_.confirmed;
        if (verdict == Verdict::kCancelled) ++out_.cancelled;
        note(std::format("finish v={} -> ok st={} bal={}", static_cast<unsigned>(verdict),
            std::string{to_text(result->order.status)}, result->balance.value()));
        if (rng_.below(4) == 0) {
            const Result<ExchangeOutcome> again = book_->exchange_finish(order, verdict, now());
            if (again && again->replayed) ++out_.replays;
            note(std::format("finish-replay -> {} replayed={}", code_of(again), again ? again->replayed : false));
        }
        if (rng_.below(10) == 0) {
            const Verdict opposite = verdict == Verdict::kDone ? Verdict::kCancelled : Verdict::kDone;
            const Result<ExchangeOutcome> flipped = book_->exchange_finish(order, opposite, now());
            if (!flipped && flipped.error() == Error::kBadState) ++out_.conflicts;
            note(std::format("finish-opposite -> {}", code_of(flipped)));
        }
    }

    void sweep() {
        now_ += 700;
        const Result<std::int64_t> swept = book_->exchange_sweep(now());
        if (swept) out_.stale += *swept;
        note(std::format("sweep -> {} n={}", code_of(swept), swept ? *swept : -1));
    }

    void admin() {
        const AccountId account = pick_account();
        const std::int64_t size = 1 + static_cast<std::int64_t>(rng_.below(300));
        const Points delta{rng_.below(2) == 0 ? size : -size};
        const RequestId request{next_admin_++};
        const Result<Points> result = book_->admin_adjust(account, delta, request, {.reason = "kiểm thử", .actor = "bot"}, now());
        note(std::format("admin a={} d={} -> {} bal={}", account.value(), delta.value(), code_of(result),
            result ? result->value() : -1));
        if (result && rng_.below(2) == 0) {
            const Result<Points> again = book_->admin_adjust(account, delta, request, {.reason = "kiểm thử", .actor = "bot"}, now());
            if (again) ++out_.replays;
            note(std::format("admin-replay -> {} bal={}", code_of(again), again ? again->value() : -1));
        }
    }

    void spend() {
        std::vector<SpendEvent> events;
        const std::uint64_t count = 1 + rng_.below(3);
        for (std::uint64_t index = 0; index < count; ++index) {
            const AccountId account = pick_account();
            events.push_back(SpendEvent{.event = next_spend_++,
                .account = account,
                .character = CharacterId{1000 + account.value()},
                .amount = Ingot{1 + static_cast<std::int64_t>(rng_.below(400))}});
        }
        const Result<SpendSummary> first = book_->record_spend(events, now());
        note(std::format("spend n={} -> {} rec={} dup={}", events.size(), code_of(first),
            first ? first->recorded : -1, first ? first->duplicates : -1));
        if (rng_.below(2) == 0) {
            const Result<SpendSummary> again = book_->record_spend(events, now());
            note(std::format("spend-again -> {} rec={} dup={}", code_of(again), again ? again->recorded : -1,
                again ? again->duplicates : -1));
        }
        const Result<Ingot> room = book_->spend_headroom(events.front().character, now());
        note(std::format("headroom -> {} left={}", code_of(room), room ? room->value() : -1));
    }

    void freeze() {
        const AccountId account = pick_account();
        const bool on = rng_.below(2) == 0;
        const Result<void> result = book_->set_frozen(account, on, {.reason = "kiểm thử", .actor = "bot"}, now());
        note(std::format("freeze a={} on={} -> {}", account.value(), on, code_of(result)));
    }

    void look() {
        const AccountId account = pick_account();
        const Result<Balance> balance = book_->balance(account);
        note(std::format("balance a={} -> {} avail={} held={} frozen={}", account.value(), code_of(balance),
            balance ? balance->available.value() : -1, balance ? balance->held.value() : -1,
            balance ? balance->frozen : false));
    }

    void finish() {
        const Result<Conservation> check = book_->ledger_check();
        if (check) {
            out_.balanced = check->balanced;
            out_.mismatched = check->mismatched_accounts;
            out_.final_check = *check;
            note(std::format("check topped={} refunded={} other={} balance={} confirmed={} held={} balanced={}",
                check->topped_up.value(), check->refunded.value(), check->other_net.value(),
                check->balance_sum.value(), check->exchange_confirmed.value(), check->exchange_held.value(),
                check->balanced));
        }
        const Result<DayReport> report = book_->day_report(now_ / kSecondsPerDay);
        if (report) {
            note(std::format("day topped={} refunded={} exchanged={} issued={} spent={} events={} open={}",
                report->topped_up.value(), report->refunded.value(), report->exchanged.value(),
                report->ingot_issued.value(), report->ingot_spent.value(), report->spend_events,
                report->open_exchanges));
        }
    }

    Book* book_;
    Rng rng_;
    Outcome out_;
    std::int64_t now_ = test::billing_support::kT0;
    std::uint64_t next_trade_ = 1;
    std::uint64_t next_request_ = 1;
    std::uint64_t next_admin_ = 1;
    std::uint64_t next_spend_ = 1;
    std::vector<Paid> paid_;
    std::vector<ExchangeId> open_;
};

} // namespace game::billing::script
