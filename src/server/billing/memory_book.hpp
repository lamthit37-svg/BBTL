#pragma once
// Bản nhớ của Book: cùng luật với PgBook (cả hai gọi rules.hpp và checks.hpp), dữ liệu nằm trong
// bản đồ có thứ tự nên kết quả tất định. Dùng cho test lõi, cho test bộ điều phối ipc và làm bản đối
// chiếu cho PgBook (cùng một kịch bản chạy trên hai bản phải ra cùng kết quả).
//
// Id cấp tuần tự từ 1 theo từng loại. Số liệu chỉ sống trong tiến trình.

#include "billing/book.hpp"

#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace game::billing {

class MemoryBook final : public Book {
public:
    explicit MemoryBook(BookConfig config);

    [[nodiscard]] Result<Balance> ensure_account(AccountId account, UnixTime now) override;
    [[nodiscard]] Result<Balance> balance(AccountId account) override;
    [[nodiscard]] Result<void> set_frozen(AccountId account, bool frozen, const Audit& audit,
        UnixTime now) override;

    [[nodiscard]] Result<PaymentOutcome> apply_payment(const PaymentEvent& event, UnixTime now) override;
    [[nodiscard]] Result<PaymentOutcome> refund_payment(const PaymentKey& key, const Audit& audit,
        UnixTime now) override;
    [[nodiscard]] Result<PaymentRecord> find_payment(const PaymentKey& key) override;

    [[nodiscard]] Result<ExchangeOutcome> exchange_begin(const ExchangeRequest& request, UnixTime now) override;
    [[nodiscard]] Result<ExchangeOutcome> exchange_finish(ExchangeId order, Verdict verdict, UnixTime now) override;
    [[nodiscard]] Result<ExchangeOrder> find_exchange(ExchangeId order) override;
    [[nodiscard]] Result<std::vector<ExchangeOrder>> exchange_open(std::size_t limit) override;
    [[nodiscard]] Result<std::int64_t> exchange_sweep(UnixTime now) override;

    [[nodiscard]] Result<BatchRecord> create_batch(const BatchSpec& spec, UnixTime now) override;
    [[nodiscard]] Result<void> set_batch_enabled(BatchId batch, bool enabled, std::string_view actor,
        UnixTime now) override;
    [[nodiscard]] Result<std::int64_t> add_codes(BatchId batch, std::span<const std::string> hashes,
        UnixTime now) override;
    [[nodiscard]] Result<RedeemOutcome> redeem(AccountId account, std::string_view code_hash, std::string_view ip,
        UnixTime now) override;
    [[nodiscard]] Result<GrantRecord> grant_add(const GrantSpec& spec, UnixTime now) override;
    [[nodiscard]] Result<std::vector<GrantRecord>> grant_list(AccountId account, std::size_t limit) override;
    [[nodiscard]] Result<GrantClaimed> grant_claim(GrantId grant, AccountId account, CharacterId character,
        UnixTime now) override;
    [[nodiscard]] Result<GrantFinished> grant_finish(GrantOrderId order, Verdict verdict, UnixTime now) override;
    [[nodiscard]] Result<std::vector<GrantOrder>> grant_open(std::size_t limit) override;

    [[nodiscard]] Result<Points> admin_adjust(AccountId account, Points delta, RequestId request,
        const Audit& audit, UnixTime now) override;
    [[nodiscard]] Result<std::vector<LedgerEntry>> ledger_tail(AccountId account, std::size_t limit) override;

    [[nodiscard]] Result<SpendSummary> record_spend(std::span<const SpendEvent> events, UnixTime now) override;
    [[nodiscard]] Result<Ingot> spend_headroom(CharacterId character, UnixTime now) override;
    [[nodiscard]] Result<Conservation> ledger_check() override;
    [[nodiscard]] Result<Points> rebuild_balance(AccountId account, std::string_view actor, UnixTime now) override;
    [[nodiscard]] Result<DayReport> day_report(std::int64_t day) override;

    // Chỉ cho test: ghi đè bản nhớ đệm của một tài khoản để thử ledger_check và rebuild_balance.
    void corrupt_cache_for_test(AccountId account, Points value);

private:
    struct CodeRow {
        CodeId id;
        BatchId batch;
        std::optional<AccountId> used_by;
    };
    struct BatchRow {
        BatchRecord record;
    };
    struct GrantRow {
        GrantRecord record;
        std::optional<GrantOrderId> open_order;
    };
    struct SpendRow {
        SpendEvent event;
        std::int64_t day = 0;
    };

    [[nodiscard]] Points cache_of(AccountId account) const;
    [[nodiscard]] bool frozen_of(AccountId account) const;
    // Thêm một dòng sổ và cập nhật bản nhớ đệm. Trả lỗi (không đổi gì) khi số dư mới âm hoặc tràn.
    [[nodiscard]] Result<void> post(AccountId account, Points delta, LedgerKind kind, std::uint64_t ref,
        std::string_view reason, std::string_view actor, UnixTime now);
    [[nodiscard]] Points held_of(AccountId account) const;
    [[nodiscard]] std::int64_t spent_today(CharacterId character, std::int64_t day) const;

    BookConfig config_;
    std::vector<LedgerEntry> ledger_;
    std::set<std::pair<LedgerKind, std::uint64_t>> ledger_keys_;
    std::map<AccountId, Points> cache_;
    std::set<AccountId> frozen_;
    std::map<std::pair<std::string, std::string>, PaymentRecord> payments_;
    std::map<ExchangeId, ExchangeOrder> exchanges_;
    std::map<std::pair<AccountId, RequestId>, ExchangeId> exchange_keys_;
    std::map<BatchId, BatchRow> batches_;
    std::set<std::string> batch_names_;
    std::map<std::string, CodeRow> codes_;
    std::map<GrantId, GrantRow> grants_;
    std::map<GrantOrderId, GrantOrder> grant_orders_;
    std::map<std::uint64_t, SpendRow> spends_;
    std::uint64_t next_payment_ = 1;
    std::uint64_t next_exchange_ = 1;
    std::uint64_t next_batch_ = 1;
    std::uint64_t next_code_ = 1;
    std::uint64_t next_grant_ = 1;
    std::uint64_t next_grant_order_ = 1;
    std::uint64_t next_ledger_ = 1;
};

} // namespace game::billing
