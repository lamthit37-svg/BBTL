#pragma once
// PgBook: sổ billing trên PostgreSQL (migration ở dev/server/sql/billing). Cùng giao diện Book và cùng bộ
// hàm luật (rules.hpp, checks.hpp) với MemoryBook; chỗ khác nhau chỉ là nơi lưu. Test so hai bản trên cùng
// một kịch bản và đòi cùng vết.
//
// Giao dịch: mỗi thao tác ghi là một giao dịch, mở đầu bằng khoá cố vấn pg_advisory_xact_lock(kWriteLock). Khoá
// toàn cục làm mọi giao dịch ghi của billing chạy lần lượt, nên luật "đọc trạng thái rồi quyết rồi ghi"
// của MemoryBook áp nguyên xi mà không có chạy đua giữa hai kết nối (ipc và webhook), cũng không có
// deadlock giữa các hàng. Giá phải trả là billing ghi tuần tự: đủ cho nạp tiền, đổi ingot và đổi mã (vài
// chục lần mỗi giây là trần thực tế của cửa hàng); khi cần hơn thì đổi sang khoá theo tài khoản, lúc đó
// lý lẽ không-deadlock phải làm lại. Thao tác chỉ đọc không lấy khoá; ledger_check và day_report đọc trong
// một ảnh REPEATABLE READ nên số liệu của chúng nhất quán dù đang có ghi song song.
//
// Mọi lỗi database (mất kết nối, vi phạm ràng buộc không lường trước, hết hạn khoá) thành Error::kBusy và
// giao dịch bị huỷ, không để lại nửa chừng; chi tiết nằm ở last_error() cho log. Mất kết nối thì lần gọi sau
// tự nối lại. Commit mà không biết đã tới đích chưa (kết nối đứt giữa chừng) cũng là kBusy: bên gọi gọi lại
// với cùng khoá lặp lại và nhận kết quả đã chốt.
//
// Một PgBook dùng trong đúng một luồng. Thread khác cần kết nối riêng (PgBook riêng).

#include "billing/book.hpp"
#include "store/pg.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing {

struct PgOptions {
    store::PgLogin login;
    // Chạy sau mỗi lần nối (và nối lại), ví dụ "SET search_path TO ..." của test. Rỗng là không chạy gì.
    std::string session_setup;
};

class PgBook final : public Book {
public:
    PgBook(PgOptions options, BookConfig config);
    ~PgBook() override;
    PgBook(const PgBook&) = delete;
    PgBook& operator=(const PgBook&) = delete;
    PgBook(PgBook&&) = delete;
    PgBook& operator=(PgBook&&) = delete;

    // Mở kết nối ngay để lộ lỗi sớm (sai mật khẩu, database chưa chạy). false thì last_error() có lý do; các
    // thao tác sau vẫn thử nối lại.
    [[nodiscard]] bool connect();

    // Câu lỗi database gần nhất, không có mật khẩu. Rỗng nếu chưa có.
    [[nodiscard]] const std::string& last_error() const noexcept { return last_error_; }

    // Số lần nối lại thành công sau lần nối đầu.
    [[nodiscard]] std::int64_t reconnects() const noexcept { return reconnects_; }

    [[nodiscard]] Result<Balance> ensure_account(AccountId account, UnixTime now) override;
    [[nodiscard]] Result<Balance> balance(AccountId account) override;
    [[nodiscard]] Result<void> set_frozen(AccountId account, bool frozen, const Audit& audit, UnixTime now) override;

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

    [[nodiscard]] Result<Points> admin_adjust(AccountId account, Points delta, RequestId request, const Audit& audit,
        UnixTime now) override;
    [[nodiscard]] Result<std::vector<LedgerEntry>> ledger_tail(AccountId account, std::size_t limit) override;

    [[nodiscard]] Result<SpendSummary> record_spend(std::span<const SpendEvent> events, UnixTime now) override;
    [[nodiscard]] Result<Ingot> spend_headroom(CharacterId character, UnixTime now) override;
    [[nodiscard]] Result<Conservation> ledger_check() override;
    [[nodiscard]] Result<Points> rebuild_balance(AccountId account, std::string_view actor, UnixTime now) override;
    [[nodiscard]] Result<DayReport> day_report(std::int64_t day) override;

private:
    // Một lần làm việc với database (nối, giao dịch, truy vấn); định nghĩa ở pg_book.cpp.
    class Session;

    // Kết nối đang mở (nối lại nếu cần); nullptr khi không nối được, last_error_ có lý do.
    [[nodiscard]] store::PgConn* ensure_conn();
    // Ghi last_error_ và đổi lỗi database sang Error.
    [[nodiscard]] Error note_failure(const store::PgExec& failed);

    PgOptions options_;
    BookConfig config_;
    std::optional<store::PgConn> conn_;
    std::string last_error_;
    std::int64_t reconnects_ = 0;
    bool ever_connected_ = false;
};

} // namespace game::billing
