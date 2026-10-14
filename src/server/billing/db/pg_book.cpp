#include "billing/db/pg_book.hpp"

#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"
#include "store/pg.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

// Khoá cố vấn của mọi giao dịch ghi. Số tuỳ ý, chỉ cần không trùng khoá cố vấn của module khác trong cùng
// database (database billing chỉ có billing dùng).
constexpr std::int64_t kWriteLock = 7'457'001;
constexpr std::string_view kSystem = "system";

using Params = std::vector<std::optional<std::string>>;
using Rows = std::vector<store::PgRow>;

[[nodiscard]] std::optional<std::string> text(std::string_view value) {
    return std::string{value};
}

[[nodiscard]] std::optional<std::string> num(std::int64_t value) {
    return store::pg_i64(value);
}

[[nodiscard]] std::optional<std::string> num(std::uint64_t value) {
    return std::to_string(value);
}

[[nodiscard]] std::optional<std::string> when(UnixTime at) {
    return store::pg_i64(at.value());
}

[[nodiscard]] std::optional<std::string> maybe(const std::optional<UnixTime>& at) {
    if (!at) return std::nullopt;
    return store::pg_i64(at->value());
}

[[nodiscard]] std::size_t clamp_limit(std::size_t limit, std::size_t most) noexcept {
    return std::clamp<std::size_t>(limit, 1, most);
}

[[nodiscard]] bool is_open(ExchangeStatus status) noexcept {
    return status == ExchangeStatus::kPending || status == ExchangeStatus::kStale;
}

// Đọc lần lượt các ô của một dòng. Ô sai kiểu hay thiếu làm ok() sai; mọi giá trị lấy ra sau đó là 0 hay rỗng.
class RowReader {
public:
    explicit RowReader(const store::PgRow& row) noexcept : row_(&row) {}

    [[nodiscard]] std::int64_t i64() {
        const store::PgCell* cell = next();
        std::int64_t value = 0;
        if (cell == nullptr || cell->null || !parse(cell->text, value)) ok_ = false;
        return ok_ ? value : 0;
    }

    [[nodiscard]] std::uint64_t u64() {
        const store::PgCell* cell = next();
        std::uint64_t value = 0;
        if (cell == nullptr || cell->null || !parse(cell->text, value)) ok_ = false;
        return ok_ ? value : 0;
    }

    [[nodiscard]] std::optional<std::int64_t> opt_i64() {
        const store::PgCell* cell = next();
        if (cell == nullptr) {
            ok_ = false;
            return std::nullopt;
        }
        if (cell->null) return std::nullopt;
        std::int64_t value = 0;
        if (!parse(cell->text, value)) {
            ok_ = false;
            return std::nullopt;
        }
        return value;
    }

    [[nodiscard]] std::string str() {
        const store::PgCell* cell = next();
        if (cell == nullptr || cell->null) {
            ok_ = false;
            return {};
        }
        return cell->text;
    }

    [[nodiscard]] bool flag() {
        const store::PgCell* cell = next();
        if (cell == nullptr || cell->null || (cell->text != "t" && cell->text != "f")) {
            ok_ = false;
            return false;
        }
        return cell->text == "t";
    }

    [[nodiscard]] bool ok() const noexcept { return ok_; }

private:
    template <typename Int>
    [[nodiscard]] static bool parse(const std::string& source, Int& out) {
        if (source.empty()) return false;
        const char* const first = source.data();
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
        const char* const last = first + source.size();
        const auto parsed = std::from_chars(first, last, out);
        return parsed.ec == std::errc{} && parsed.ptr == last;
    }

    [[nodiscard]] const store::PgCell* next() noexcept {
        if (!ok_ || column_ >= row_->cells.size()) {
            ok_ = false;
            return nullptr;
        }
        return &row_->cells[column_++];
    }

    const store::PgRow* row_;
    std::size_t column_ = 0;
    bool ok_ = true;
};

constexpr std::string_view kPaymentCols =
    "id, provider, trade_no, account_id, points, amount_minor, currency, status, created_at, updated_at";
constexpr std::string_view kExchangeCols =
    "id, account_id, character_id, request_id, ingot, points, status, created_at, updated_at";
constexpr std::string_view kGrantCols = "id, account_id, kind, ref_id, quantity, status, source, created_at";
constexpr std::string_view kGrantOrderCols = "id, grant_id, character_id, status, created_at, updated_at";
constexpr std::string_view kLedgerCols = "id, account_id, delta, kind, ref_id, reason, actor, at";

[[nodiscard]] std::optional<PaymentRecord> payment_of(const store::PgRow& row) {
    RowReader in{row};
    PaymentRecord record;
    record.id = PaymentId{in.u64()};
    record.event.provider = in.str();
    record.event.trade_no = in.str();
    record.event.account = AccountId{in.u64()};
    record.event.points = Points{in.i64()};
    record.event.amount_minor = in.i64();
    record.event.currency = in.str();
    const std::optional<PaymentStatus> status = payment_status_of(in.str());
    record.created = UnixTime{in.i64()};
    record.updated = UnixTime{in.i64()};
    if (!in.ok() || !status) return std::nullopt;
    record.event.status = *status;
    return record;
}

[[nodiscard]] std::optional<ExchangeOrder> exchange_of(const store::PgRow& row) {
    RowReader in{row};
    ExchangeOrder order;
    order.id = ExchangeId{in.u64()};
    order.account = AccountId{in.u64()};
    order.character = CharacterId{in.u64()};
    order.request = RequestId{in.u64()};
    order.ingot = Ingot{in.i64()};
    order.points = Points{in.i64()};
    const std::optional<ExchangeStatus> status = exchange_status_of(in.str());
    order.created = UnixTime{in.i64()};
    order.updated = UnixTime{in.i64()};
    if (!in.ok() || !status) return std::nullopt;
    order.status = *status;
    return order;
}

[[nodiscard]] std::optional<GrantRecord> grant_of(const store::PgRow& row) {
    RowReader in{row};
    GrantRecord grant;
    grant.id = GrantId{in.u64()};
    grant.account = AccountId{in.u64()};
    const std::optional<GrantKind> kind = grant_kind_of(in.str());
    grant.ref_id = in.u64();
    grant.quantity = in.i64();
    const std::optional<GrantStatus> status = grant_status_of(in.str());
    grant.source = in.str();
    grant.created = UnixTime{in.i64()};
    if (!in.ok() || !kind || !status) return std::nullopt;
    grant.kind = *kind;
    grant.status = *status;
    return grant;
}

[[nodiscard]] std::optional<GrantOrder> grant_order_of(const store::PgRow& row) {
    RowReader in{row};
    GrantOrder order;
    order.id = GrantOrderId{in.u64()};
    order.grant = GrantId{in.u64()};
    order.character = CharacterId{in.u64()};
    const std::optional<GrantOrderStatus> status = grant_order_status_of(in.str());
    order.created = UnixTime{in.i64()};
    order.updated = UnixTime{in.i64()};
    if (!in.ok() || !status) return std::nullopt;
    order.status = *status;
    return order;
}

[[nodiscard]] std::optional<LedgerEntry> ledger_of(const store::PgRow& row) {
    RowReader in{row};
    LedgerEntry entry;
    entry.id = in.u64();
    entry.account = AccountId{in.u64()};
    entry.delta = Points{in.i64()};
    const std::optional<LedgerKind> kind = ledger_kind_of(in.str());
    entry.ref = in.u64();
    entry.reason = in.str();
    entry.actor = in.str();
    entry.at = UnixTime{in.i64()};
    if (!in.ok() || !kind) return std::nullopt;
    entry.kind = *kind;
    return entry;
}

[[nodiscard]] std::string select_from(std::string_view columns, std::string_view tail) {
    std::string sql = "SELECT ";
    sql.append(columns);
    sql.push_back(' ');
    sql.append(tail);
    return sql;
}

} // namespace

// Một lần làm việc với database: nối (nếu cần), mở giao dịch, chạy truy vấn, chốt hoặc huỷ.
class PgBook::Session {
public:
    enum class Mode : std::uint8_t {
        // Truy vấn đơn lẻ, không giao dịch: mỗi câu là một giao dịch riêng của PostgreSQL.
        kSingle,
        // Giao dịch ghi, giữ khoá cố vấn.
        kWrite,
        // Giao dịch chỉ đọc trên một ảnh nhất quán.
        kSnapshot,
    };

    explicit Session(PgBook& book) noexcept : book_(book) {}
    ~Session() {
        if (open_) rollback();
    }
    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;
    Session(Session&&) = delete;
    Session& operator=(Session&&) = delete;

    template <typename Body>
    static auto run(PgBook& book, Mode mode, Body&& body) -> decltype(body(std::declval<Session&>())) {
        using Outcome = decltype(body(std::declval<Session&>()));
        Session session{book};
        if (!session.begin(mode)) return std::unexpected(Error::kBusy);
        Outcome outcome = std::forward<Body>(body)(session);
        if (!outcome) return outcome;
        if (!session.commit()) return std::unexpected(Error::kBusy);
        return outcome;
    }

    [[nodiscard]] const BookConfig& config() const noexcept { return book_.config_; }

    [[nodiscard]] Result<Rows> query(std::string_view sql, const Params& params = {}) {
        store::PgExec result = conn_->exec(sql, params);
        if (!result.ok) return std::unexpected(book_.note_failure(result));
        return std::move(result.rows);
    }

    // Câu lệnh không trả dòng (UPDATE, DELETE): số dòng bị đổi.
    [[nodiscard]] Result<std::int64_t> command(std::string_view sql, const Params& params = {}) {
        const store::PgExec result = conn_->exec(sql, params);
        if (!result.ok) return std::unexpected(book_.note_failure(result));
        return static_cast<std::int64_t>(result.affected);
    }

    // Câu một dòng một cột số nguyên (COUNT, SUM, COALESCE).
    [[nodiscard]] Result<std::int64_t> scalar(std::string_view sql, const Params& params = {}) {
        const Result<Rows> rows = query(sql, params);
        if (!rows) return std::unexpected(rows.error());
        if (rows->size() != 1) return std::unexpected(corrupt("câu scalar không trả đúng một dòng"));
        RowReader in{rows->front()};
        const std::int64_t value = in.i64();
        if (!in.ok()) return std::unexpected(corrupt("câu scalar trả giá trị không phải số"));
        return value;
    }

    [[nodiscard]] Error corrupt(std::string_view what) {
        book_.last_error_ = std::string{what};
        return Error::kBusy;
    }

    [[nodiscard]] Result<Points> cache_of(AccountId account) {
        const Result<std::int64_t> points =
            scalar("SELECT COALESCE((SELECT points FROM point_balance WHERE account_id = $1::bigint), 0)",
                {num(account.value())});
        if (!points) return std::unexpected(points.error());
        return Points{*points};
    }

    [[nodiscard]] Result<bool> frozen_of(AccountId account) {
        const Result<Rows> rows = query(
            "SELECT COALESCE((SELECT frozen FROM billing_account WHERE account_id = $1::bigint), false)",
            {num(account.value())});
        if (!rows) return std::unexpected(rows.error());
        if (rows->size() != 1) return std::unexpected(corrupt("frozen_of không trả đúng một dòng"));
        RowReader in{rows->front()};
        const bool frozen = in.flag();
        if (!in.ok()) return std::unexpected(corrupt("frozen_of trả giá trị lạ"));
        return frozen;
    }

    [[nodiscard]] Result<Points> held_of(AccountId account) {
        const Result<std::int64_t> held = scalar(
            "SELECT COALESCE((SELECT SUM(points) FROM exchange_order WHERE account_id = $1::bigint AND status IN "
            "('pending', 'stale')), 0)",
            {num(account.value())});
        if (!held) return std::unexpected(held.error());
        return Points{*held};
    }

    [[nodiscard]] Result<Balance> balance(AccountId account) {
        const Result<Points> available = cache_of(account);
        if (!available) return std::unexpected(available.error());
        const Result<Points> held = held_of(account);
        if (!held) return std::unexpected(held.error());
        const Result<bool> frozen = frozen_of(account);
        if (!frozen) return std::unexpected(frozen.error());
        return Balance{.available = *available, .held = *held, .frozen = *frozen};
    }

    // Tài khoản có hàng ở billing_account và point_balance (khoá ngoại của mọi bảng khác).
    [[nodiscard]] Result<void> ensure_row(AccountId account, UnixTime now) {
        const Result<Rows> account_row = query(
            "INSERT INTO billing_account (account_id, created_at) VALUES ($1::bigint, $2::bigint) ON CONFLICT DO NOTHING",
            {num(account.value()), when(now)});
        if (!account_row) return std::unexpected(account_row.error());
        const Result<Rows> balance_row = query(
            "INSERT INTO point_balance (account_id, points, updated_at) VALUES ($1::bigint, 0, $2::bigint) ON CONFLICT "
            "DO NOTHING",
            {num(account.value()), when(now)});
        if (!balance_row) return std::unexpected(balance_row.error());
        return {};
    }

    [[nodiscard]] Result<bool> ledger_has(LedgerKind kind, std::uint64_t ref) {
        const Result<std::int64_t> count = scalar(
            "SELECT COUNT(*) FROM point_ledger WHERE kind = $1 AND ref_id = $2::bigint",
            {text(to_text(kind)), num(ref)});
        if (!count) return std::unexpected(count.error());
        return *count > 0;
    }

    // Cộng một dòng vào sổ và cập nhật bản nhớ đệm. Cùng luật với MemoryBook::post.
    [[nodiscard]] Result<void> post(AccountId account, Points delta, LedgerKind kind, std::uint64_t ref,
        std::string_view reason, std::string_view actor, UnixTime now) {
        if (ref != 0) {
            const Result<bool> known = ledger_has(kind, ref);
            if (!known) return std::unexpected(known.error());
            if (*known) return std::unexpected(Error::kConflict);
        }
        const Result<Points> cache = cache_of(account);
        if (!cache) return std::unexpected(cache.error());
        const std::optional<std::int64_t> next = add_checked(cache->value(), delta.value());
        if (!next) return std::unexpected(Error::kBadAmount);
        if (*next < 0) return std::unexpected(Error::kInsufficient);
        const Result<Rows> inserted = query(
            "INSERT INTO point_ledger (account_id, delta, kind, ref_id, reason, actor, at) VALUES "
            "($1::bigint, $2::bigint, $3, $4::bigint, $5, $6, $7::bigint)",
            {num(account.value()), num(delta.value()), text(to_text(kind)), num(ref), text(reason), text(actor),
                when(now)});
        if (!inserted) return std::unexpected(inserted.error());
        const Result<Rows> updated = query(
            "UPDATE point_balance SET points = $2::bigint, updated_at = $3::bigint WHERE account_id = $1::bigint",
            {num(account.value()), num(*next), when(now)});
        if (!updated) return std::unexpected(updated.error());
        return {};
    }

    [[nodiscard]] Result<void> audit(std::string_view kind, std::uint64_t subject, std::string_view detail,
        std::string_view actor, UnixTime now) {
        const Result<Rows> done = query(
            "INSERT INTO audit_event (kind, subject, detail, actor, at) VALUES ($1, $2::bigint, $3, $4, $5::bigint)",
            {text(kind), num(subject), text(detail), text(actor), when(now)});
        if (!done) return std::unexpected(done.error());
        return {};
    }

    [[nodiscard]] Result<std::optional<PaymentRecord>> payment_by_key(const PaymentKey& key) {
        const Result<Rows> rows = query(select_from(kPaymentCols, "FROM payment WHERE provider = $1 AND trade_no = $2"),
            {text(key.provider), text(key.trade_no)});
        if (!rows) return std::unexpected(rows.error());
        if (rows->empty()) return std::optional<PaymentRecord>{};
        std::optional<PaymentRecord> record = payment_of(rows->front());
        if (!record) return std::unexpected(corrupt("dòng payment hỏng"));
        return record;
    }

    [[nodiscard]] Result<std::optional<ExchangeOrder>> exchange_by_id(ExchangeId order) {
        const Result<Rows> rows =
            query(select_from(kExchangeCols, "FROM exchange_order WHERE id = $1::bigint"), {num(order.value())});
        if (!rows) return std::unexpected(rows.error());
        if (rows->empty()) return std::optional<ExchangeOrder>{};
        std::optional<ExchangeOrder> found = exchange_of(rows->front());
        if (!found) return std::unexpected(corrupt("dòng exchange_order hỏng"));
        return found;
    }

    [[nodiscard]] Result<std::optional<GrantRecord>> grant_by_id(GrantId grant) {
        const Result<Rows> rows =
            query(select_from(kGrantCols, "FROM reward_grant WHERE id = $1::bigint"), {num(grant.value())});
        if (!rows) return std::unexpected(rows.error());
        if (rows->empty()) return std::optional<GrantRecord>{};
        std::optional<GrantRecord> found = grant_of(rows->front());
        if (!found) return std::unexpected(corrupt("dòng reward_grant hỏng"));
        return found;
    }

    [[nodiscard]] Result<std::optional<GrantOrder>> open_grant_order(GrantId grant) {
        const Result<Rows> rows = query(
            select_from(kGrantOrderCols, "FROM grant_order WHERE grant_id = $1::bigint AND status = 'pending'"),
            {num(grant.value())});
        if (!rows) return std::unexpected(rows.error());
        if (rows->empty()) return std::optional<GrantOrder>{};
        std::optional<GrantOrder> found = grant_order_of(rows->front());
        if (!found) return std::unexpected(corrupt("dòng grant_order hỏng"));
        return found;
    }

    [[nodiscard]] Result<GrantRecord> insert_grant(AccountId account, GrantKind kind, std::uint64_t ref_id,
        std::int64_t quantity, std::string_view source, std::string_view reason, std::string_view actor,
        UnixTime now) {
        const Result<Rows> rows = query(
            "INSERT INTO reward_grant (account_id, kind, ref_id, quantity, status, source, reason, actor, created_at, "
            "updated_at) VALUES ($1::bigint, $2, $3::bigint, $4::bigint, 'pending', $5, $6, $7, $8::bigint, $8::bigint) "
            "RETURNING id",
            {num(account.value()), text(to_text(kind)), num(ref_id), num(quantity), text(source), text(reason),
                text(actor), when(now)});
        if (!rows) return std::unexpected(rows.error());
        if (rows->size() != 1) return std::unexpected(corrupt("INSERT reward_grant không trả id"));
        RowReader in{rows->front()};
        const GrantId id{in.u64()};
        if (!in.ok()) return std::unexpected(corrupt("id reward_grant hỏng"));
        return GrantRecord{.id = id,
            .account = account,
            .kind = kind,
            .ref_id = ref_id,
            .quantity = quantity,
            .status = GrantStatus::kPending,
            .source = std::string{source},
            .created = now};
    }

    // Đối soát toàn sổ (không phụ thuộc ngày). Cùng công thức với MemoryBook::ledger_check.
    [[nodiscard]] Result<Conservation> conservation() {
        const Result<Rows> kinds = query("SELECT kind, COALESCE(SUM(delta), 0) FROM point_ledger GROUP BY kind");
        if (!kinds) return std::unexpected(kinds.error());
        std::int64_t topped = 0;
        std::int64_t refunded = 0;
        std::int64_t other = 0;
        std::int64_t hold_sum = 0;
        std::int64_t release_sum = 0;
        for (const store::PgRow& row : *kinds) {
            RowReader in{row};
            const std::optional<LedgerKind> kind = ledger_kind_of(in.str());
            const std::int64_t sum = in.i64();
            if (!in.ok() || !kind) return std::unexpected(corrupt("dòng tổng sổ hỏng"));
            switch (*kind) {
            case LedgerKind::kTopUp: topped += sum; break;
            case LedgerKind::kRefund: refunded -= sum; break;
            case LedgerKind::kExchangeHold: hold_sum += sum; break;
            case LedgerKind::kExchangeRelease: release_sum += sum; break;
            case LedgerKind::kRegisterGift:
            case LedgerKind::kRedeem:
            case LedgerKind::kAdmin: other += sum; break;
            }
        }
        const Result<std::int64_t> balance_sum = scalar("SELECT COALESCE(SUM(points), 0) FROM point_balance");
        if (!balance_sum) return std::unexpected(balance_sum.error());
        const Result<std::int64_t> mismatched = scalar(
            "SELECT COUNT(*) FROM point_balance b FULL JOIN (SELECT account_id, SUM(delta) AS total FROM point_ledger "
            "GROUP BY account_id) l USING (account_id) WHERE COALESCE(b.points, 0) <> COALESCE(l.total, 0)");
        if (!mismatched) return std::unexpected(mismatched.error());
        const Result<Rows> orders = query(
            "SELECT status, COALESCE(SUM(points), 0) FROM exchange_order GROUP BY status");
        if (!orders) return std::unexpected(orders.error());
        std::int64_t confirmed = 0;
        std::int64_t held = 0;
        std::int64_t all_points = 0;
        std::int64_t cancelled_points = 0;
        for (const store::PgRow& row : *orders) {
            RowReader in{row};
            const std::optional<ExchangeStatus> status = exchange_status_of(in.str());
            const std::int64_t sum = in.i64();
            if (!in.ok() || !status) return std::unexpected(corrupt("dòng tổng đơn đổi hỏng"));
            all_points += sum;
            if (*status == ExchangeStatus::kConfirmed) confirmed += sum;
            if (is_open(*status)) held += sum;
            if (*status == ExchangeStatus::kCancelled) cancelled_points += sum;
        }
        Conservation report;
        report.topped_up = Points{topped};
        report.refunded = Points{refunded};
        report.other_net = Points{other};
        report.balance_sum = Points{*balance_sum};
        report.exchange_confirmed = Points{confirmed};
        report.exchange_held = Points{held};
        report.mismatched_accounts = *mismatched;
        const bool identity = topped + other == *balance_sum + confirmed + held + refunded;
        const bool exchange_rows = hold_sum == -all_points && release_sum == cancelled_points;
        report.balanced = identity && exchange_rows && report.mismatched_accounts == 0;
        return report;
    }

private:
    [[nodiscard]] bool begin(Mode mode) {
        conn_ = book_.ensure_conn();
        if (conn_ == nullptr) return false;
        if (mode == Mode::kSingle) return true;
        const std::string_view opening =
            mode == Mode::kWrite ? "BEGIN" : "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY";
        store::PgExec started = conn_->exec(opening);
        if (!started.ok && !conn_->is_open()) {
            // Kết nối đã chết từ lúc rảnh: nối lại một lần, chưa làm gì nên thử lại là an toàn.
            conn_ = book_.ensure_conn();
            if (conn_ == nullptr) return false;
            started = conn_->exec(opening);
        }
        if (!started.ok) {
            static_cast<void>(book_.note_failure(started));
            return false;
        }
        open_ = true;
        if (mode == Mode::kWrite) {
            const store::PgExec locked =
                conn_->exec("SELECT pg_advisory_xact_lock($1::bigint)", std::array{num(kWriteLock)});
            if (!locked.ok) {
                static_cast<void>(book_.note_failure(locked));
                rollback();
                return false;
            }
        }
        return true;
    }

    [[nodiscard]] bool commit() {
        if (!open_) return true;
        open_ = false;
        const store::PgExec done = conn_->exec("COMMIT");
        if (!done.ok) {
            static_cast<void>(book_.note_failure(done));
            return false;
        }
        return true;
    }

    void rollback() {
        open_ = false;
        if (conn_ != nullptr && conn_->is_open()) static_cast<void>(conn_->exec("ROLLBACK"));
    }

    PgBook& book_;
    // Kết nối của PgBook tại thời điểm begin() thành công; null trước đó. Địa chỉ ổn định: nằm trong std::optional của
    // PgBook, nối lại chỉ thay giá trị chứ không đổi chỗ.
    store::PgConn* conn_ = nullptr;
    bool open_ = false;
};

PgBook::PgBook(PgOptions options, BookConfig config) : options_(std::move(options)), config_(config) {}

PgBook::~PgBook() = default;

bool PgBook::connect() {
    return ensure_conn() != nullptr;
}

store::PgConn* PgBook::ensure_conn() {
    if (conn_ && conn_->is_open()) return &*conn_;
    std::string error;
    std::optional<store::PgConn> fresh = store::PgConn::open(options_.login, error);
    if (!fresh) {
        last_error_ = error;
        conn_.reset();
        return nullptr;
    }
    if (!options_.session_setup.empty()) {
        const store::PgExec setup = fresh->script(options_.session_setup);
        if (!setup.ok) {
            last_error_ = setup.message;
            return nullptr;
        }
    }
    if (ever_connected_) ++reconnects_;
    ever_connected_ = true;
    conn_ = std::move(fresh);
    return &*conn_;
}

Error PgBook::note_failure(const store::PgExec& failed) {
    last_error_ = failed.sqlstate.empty() ? failed.message : std::format("{}: {}", failed.sqlstate, failed.message);
    // 23505 (unique_violation): hàng đã có. Sau khoá cố vấn và các phép kiểm trước khi ghi, nó chỉ còn là
    // chốt chặn cuối của database; nghĩa với bên gọi là xung đột khoá lặp lại.
    if (failed.sqlstate == "23505") return Error::kConflict;
    return Error::kBusy;
}

// ---- tài khoản -----------------------------------------------------------------------------------

Result<Balance> PgBook::ensure_account(AccountId account, UnixTime now) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<Balance> {
        if (const Result<void> row = session.ensure_row(account, now); !row) return std::unexpected(row.error());
        if (config_.register_gift.value() > 0) {
            const Result<bool> given = session.ledger_has(LedgerKind::kRegisterGift, account.value());
            if (!given) return std::unexpected(given.error());
            if (!*given) {
                const Result<Points> cache = session.cache_of(account);
                if (!cache) return std::unexpected(cache.error());
                const Result<Points> next = credit_step(config_.register_gift, *cache, config_.limits);
                if (!next) return std::unexpected(next.error());
                const Result<void> posted = session.post(account, config_.register_gift, LedgerKind::kRegisterGift,
                    account.value(), "quà đăng ký", kSystem, now);
                if (!posted) return std::unexpected(posted.error());
            }
        }
        return session.balance(account);
    });
}

Result<Balance> PgBook::balance(AccountId account) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    // Ba truy vấn (nhớ đệm, đang giữ, cờ đóng băng) phải thấy cùng một thời điểm: một đơn đổi chen vào giữa sẽ
    // làm điểm vừa rời khỏi số dư mà chưa vào điểm giữ (hoặc ngược lại), tức hiện sai số tổng.
    return Session::run(*this, Session::Mode::kSnapshot, [&](Session& session) { return session.balance(account); });
}

Result<void> PgBook::set_frozen(AccountId account, bool frozen, const Audit& audit, UnixTime now) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    const std::optional<std::string> reason = clean_text(audit.reason, kReasonMost);
    const std::optional<std::string> actor = clean_text(audit.actor, kActorMost);
    if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<void> {
        if (const Result<void> row = session.ensure_row(account, now); !row) return row;
        const Result<Rows> updated = session.query(
            "UPDATE billing_account SET frozen = $2::boolean WHERE account_id = $1::bigint",
            {num(account.value()), text(frozen ? "true" : "false")});
        if (!updated) return std::unexpected(updated.error());
        return session.audit(frozen ? "freeze" : "unfreeze", account.value(), *reason, *actor, now);
    });
}

// ---- đơn nạp -------------------------------------------------------------------------------------

Result<PaymentOutcome> PgBook::apply_payment(const PaymentEvent& event, UnixTime now) {
    if (const Result<void> ok = check_payment_event(event, config_.limits); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<PaymentOutcome> {
        const Result<std::optional<PaymentRecord>> found =
            session.payment_by_key({.provider = event.provider, .trade_no = event.trade_no});
        if (!found) return std::unexpected(found.error());
        std::optional<PaymentStatus> existing;
        if (*found) {
            const PaymentEvent& old = (*found)->event;
            const bool same = old.account == event.account && old.points == event.points &&
                old.amount_minor == event.amount_minor && old.currency == event.currency;
            if (!same) return std::unexpected(Error::kConflict);
            existing = old.status;
        }
        const Result<PaymentAct> act = payment_step(existing, event.status);
        if (!act) return std::unexpected(act.error());
        PaymentOutcome outcome;
        if (*act == PaymentAct::kDuplicate || *act == PaymentAct::kIgnore) {
            const Result<Points> cache = session.cache_of(event.account);
            if (!cache) return std::unexpected(cache.error());
            outcome.result = *act == PaymentAct::kDuplicate ? PaymentResult::kDuplicate : PaymentResult::kIgnored;
            outcome.record = **found;
            outcome.balance = *cache;
            return outcome;
        }
        if (const Result<void> row = session.ensure_row(event.account, now); !row) return std::unexpected(row.error());
        PaymentRecord record;
        if (*found) {
            record = **found;
            const Result<Rows> updated = session.query(
                "UPDATE payment SET status = $2, updated_at = $3::bigint WHERE id = $1::bigint",
                {num(record.id.value()), text(to_text(event.status)), when(now)});
            if (!updated) return std::unexpected(updated.error());
            record.event.status = event.status;
            record.updated = now;
        } else {
            const Result<Rows> inserted = session.query(
                "INSERT INTO payment (provider, trade_no, account_id, points, amount_minor, currency, status, "
                "created_at, updated_at) VALUES ($1, $2, $3::bigint, $4::bigint, $5::bigint, $6, $7, $8::bigint, "
                "$8::bigint) RETURNING id",
                {text(event.provider), text(event.trade_no), num(event.account.value()), num(event.points.value()),
                    num(event.amount_minor), text(event.currency), text(to_text(event.status)), when(now)});
            if (!inserted) return std::unexpected(inserted.error());
            if (inserted->size() != 1) return std::unexpected(session.corrupt("INSERT payment không trả id"));
            RowReader in{inserted->front()};
            record = PaymentRecord{.id = PaymentId{in.u64()}, .event = event, .created = now, .updated = now};
            if (!in.ok()) return std::unexpected(session.corrupt("id payment hỏng"));
        }
        const bool credits = *act == PaymentAct::kCreatePaid || *act == PaymentAct::kPromote;
        if (credits) {
            const Result<void> posted = session.post(event.account, event.points, LedgerKind::kTopUp,
                record.id.value(), "nạp", event.provider, now);
            if (!posted) return std::unexpected(posted.error());
        }
        if (*act == PaymentAct::kRefund) {
            const Result<void> posted = session.post(event.account, Points{-event.points.value()}, LedgerKind::kRefund,
                record.id.value(), "nhà cung cấp hoàn tiền", event.provider, now);
            if (!posted) return std::unexpected(posted.error());
        }
        const Result<Points> cache = session.cache_of(event.account);
        if (!cache) return std::unexpected(cache.error());
        outcome.record = std::move(record);
        outcome.balance = *cache;
        return outcome;
    });
}

Result<PaymentOutcome> PgBook::refund_payment(const PaymentKey& key, const Audit& audit, UnixTime now) {
    if (const Result<void> ok = check_payment_key(key.provider, key.trade_no); !ok) return std::unexpected(ok.error());
    const std::optional<std::string> reason = clean_text(audit.reason, kReasonMost);
    const std::optional<std::string> actor = clean_text(audit.actor, kActorMost);
    if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<PaymentOutcome> {
        const Result<std::optional<PaymentRecord>> found = session.payment_by_key(key);
        if (!found) return std::unexpected(found.error());
        if (!*found) return std::unexpected(Error::kNotFound);
        PaymentRecord record = **found;
        const Result<PaymentAct> act = payment_step(record.event.status, PaymentStatus::kRefunded);
        if (!act) return std::unexpected(act.error());
        PaymentOutcome outcome;
        if (*act == PaymentAct::kDuplicate) {
            const Result<Points> cache = session.cache_of(record.event.account);
            if (!cache) return std::unexpected(cache.error());
            outcome.result = PaymentResult::kDuplicate;
            outcome.record = std::move(record);
            outcome.balance = *cache;
            return outcome;
        }
        const Result<void> posted = session.post(record.event.account, Points{-record.event.points.value()},
            LedgerKind::kRefund, record.id.value(), *reason, *actor, now);
        if (!posted) return std::unexpected(posted.error());
        const Result<Rows> updated = session.query(
            "UPDATE payment SET status = 'refunded', updated_at = $2::bigint WHERE id = $1::bigint",
            {num(record.id.value()), when(now)});
        if (!updated) return std::unexpected(updated.error());
        record.event.status = PaymentStatus::kRefunded;
        record.updated = now;
        const Result<Points> cache = session.cache_of(record.event.account);
        if (!cache) return std::unexpected(cache.error());
        outcome.record = std::move(record);
        outcome.balance = *cache;
        return outcome;
    });
}

Result<PaymentRecord> PgBook::find_payment(const PaymentKey& key) {
    if (const Result<void> ok = check_payment_key(key.provider, key.trade_no); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<PaymentRecord> {
        const Result<std::optional<PaymentRecord>> found = session.payment_by_key(key);
        if (!found) return std::unexpected(found.error());
        if (!*found) return std::unexpected(Error::kNotFound);
        return **found;
    });
}

// ---- đổi điểm lấy ingot --------------------------------------------------------------------------

Result<ExchangeOutcome> PgBook::exchange_begin(const ExchangeRequest& request, UnixTime now) {
    if (const Result<void> ok = check_exchange_request(request); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<ExchangeOutcome> {
        const Result<Rows> known = session.query(
            select_from(kExchangeCols, "FROM exchange_order WHERE account_id = $1::bigint AND request_id = $2::bigint"),
            {num(request.account.value()), num(request.request.value())});
        if (!known) return std::unexpected(known.error());
        if (!known->empty()) {
            const std::optional<ExchangeOrder> order = exchange_of(known->front());
            if (!order) return std::unexpected(session.corrupt("dòng exchange_order hỏng"));
            if (order->character != request.character || order->ingot != request.ingot) {
                return std::unexpected(Error::kConflict);
            }
            const Result<Points> cache = session.cache_of(request.account);
            if (!cache) return std::unexpected(cache.error());
            return ExchangeOutcome{.order = *order, .replayed = true, .balance = *cache};
        }
        const Result<Points> cache = session.cache_of(request.account);
        if (!cache) return std::unexpected(cache.error());
        const Result<bool> frozen = session.frozen_of(request.account);
        if (!frozen) return std::unexpected(frozen.error());
        const Result<Points> cost =
            exchange_begin_step(request.ingot, config_.ingot_per_point, *cache, *frozen, config_.limits);
        if (!cost) return std::unexpected(cost.error());
        if (const Result<void> row = session.ensure_row(request.account, now); !row) return std::unexpected(row.error());
        const Result<Rows> inserted = session.query(
            "INSERT INTO exchange_order (account_id, character_id, request_id, ingot, points, status, created_at, "
            "updated_at) VALUES ($1::bigint, $2::bigint, $3::bigint, $4::bigint, $5::bigint, 'pending', $6::bigint, "
            "$6::bigint) RETURNING id",
            {num(request.account.value()), num(request.character.value()), num(request.request.value()),
                num(request.ingot.value()), num(cost->value()), when(now)});
        if (!inserted) return std::unexpected(inserted.error());
        if (inserted->size() != 1) return std::unexpected(session.corrupt("INSERT exchange_order không trả id"));
        RowReader in{inserted->front()};
        const ExchangeId id{in.u64()};
        if (!in.ok()) return std::unexpected(session.corrupt("id exchange_order hỏng"));
        const Result<void> posted = session.post(request.account, Points{-cost->value()}, LedgerKind::kExchangeHold,
            id.value(), "giữ điểm đổi ingot", kSystem, now);
        if (!posted) return std::unexpected(posted.error());
        const Result<Points> after = session.cache_of(request.account);
        if (!after) return std::unexpected(after.error());
        const ExchangeOrder order{.id = id,
            .account = request.account,
            .character = request.character,
            .request = request.request,
            .ingot = request.ingot,
            .points = *cost,
            .status = ExchangeStatus::kPending,
            .created = now,
            .updated = now};
        return ExchangeOutcome{.order = order, .replayed = false, .balance = *after};
    });
}

Result<ExchangeOutcome> PgBook::exchange_finish(ExchangeId order, Verdict verdict, UnixTime now) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<ExchangeOutcome> {
        const Result<std::optional<ExchangeOrder>> found = session.exchange_by_id(order);
        if (!found) return std::unexpected(found.error());
        if (!*found) return std::unexpected(Error::kNotFound);
        ExchangeOrder row = **found;
        const Result<FinishAct> act = exchange_finish_step(row.status, verdict);
        if (!act) return std::unexpected(act.error());
        if (*act == FinishAct::kDuplicate) {
            const Result<Points> cache = session.cache_of(row.account);
            if (!cache) return std::unexpected(cache.error());
            return ExchangeOutcome{.order = row, .replayed = true, .balance = *cache};
        }
        if (*act == FinishAct::kCancel) {
            const Result<void> posted = session.post(row.account, row.points, LedgerKind::kExchangeRelease,
                row.id.value(), "huỷ đơn đổi ingot", kSystem, now);
            if (!posted) return std::unexpected(posted.error());
        }
        const ExchangeStatus next = *act == FinishAct::kConfirm ? ExchangeStatus::kConfirmed : ExchangeStatus::kCancelled;
        const Result<Rows> updated = session.query(
            "UPDATE exchange_order SET status = $2, updated_at = $3::bigint WHERE id = $1::bigint",
            {num(row.id.value()), text(to_text(next)), when(now)});
        if (!updated) return std::unexpected(updated.error());
        row.status = next;
        row.updated = now;
        const Result<Points> cache = session.cache_of(row.account);
        if (!cache) return std::unexpected(cache.error());
        return ExchangeOutcome{.order = row, .replayed = false, .balance = *cache};
    });
}

Result<ExchangeOrder> PgBook::find_exchange(ExchangeId order) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<ExchangeOrder> {
        const Result<std::optional<ExchangeOrder>> found = session.exchange_by_id(order);
        if (!found) return std::unexpected(found.error());
        if (!*found) return std::unexpected(Error::kNotFound);
        return **found;
    });
}

Result<std::vector<ExchangeOrder>> PgBook::exchange_open(std::size_t limit) {
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<std::vector<ExchangeOrder>> {
        const Result<Rows> rows = session.query(
            select_from(kExchangeCols,
                "FROM exchange_order WHERE status IN ('pending', 'stale') ORDER BY created_at, id LIMIT $1::bigint"),
            {num(static_cast<std::int64_t>(clamp_limit(limit, kListMost)))});
        if (!rows) return std::unexpected(rows.error());
        std::vector<ExchangeOrder> out;
        for (const store::PgRow& row : *rows) {
            const std::optional<ExchangeOrder> order = exchange_of(row);
            if (!order) return std::unexpected(session.corrupt("dòng exchange_order hỏng"));
            out.push_back(*order);
        }
        return out;
    });
}

Result<std::int64_t> PgBook::exchange_sweep(UnixTime now) {
    if (config_.pending_timeout_seconds <= 0) return std::int64_t{0};
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<std::int64_t> {
        // Cùng điều kiện với exchange_overdue: now >= created + timeout.
        return session.command(
            "UPDATE exchange_order SET status = 'stale', updated_at = $1::bigint WHERE status = 'pending' AND "
            "created_at + $2::bigint <= $1::bigint",
            {when(now), num(config_.pending_timeout_seconds)});
    });
}

// ---- quà và mã đổi -------------------------------------------------------------------------------

Result<BatchRecord> PgBook::create_batch(const BatchSpec& spec, UnixTime now) {
    BatchSpec clean = spec;
    if (const Result<void> ok = check_batch_spec(clean, config_.limits); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<BatchRecord> {
        const Result<std::int64_t> same = session.scalar("SELECT COUNT(*) FROM reward_batch WHERE name = $1",
            {text(clean.name)});
        if (!same) return std::unexpected(same.error());
        if (*same > 0) return std::unexpected(Error::kConflict);
        const Result<Rows> inserted = session.query(
            "INSERT INTO reward_batch (name, starts_at, ends_at, per_account_limit, enabled, actor, created_at) VALUES "
            "($1, $2::bigint, $3::bigint, $4::integer, true, $5, $6::bigint) RETURNING id",
            {text(clean.name), maybe(clean.starts), maybe(clean.ends), num(clean.per_account_limit),
                text(clean.actor), when(now)});
        if (!inserted) return std::unexpected(inserted.error());
        if (inserted->size() != 1) return std::unexpected(session.corrupt("INSERT reward_batch không trả id"));
        RowReader in{inserted->front()};
        const BatchId id{in.u64()};
        if (!in.ok()) return std::unexpected(session.corrupt("id reward_batch hỏng"));
        std::int64_t seq = 0;
        for (const Reward& reward : clean.rewards) {
            const Result<Rows> added = session.query(
                "INSERT INTO batch_reward (batch_id, seq, kind, ref_id, quantity) VALUES ($1::bigint, $2::smallint, "
                "$3::smallint, $4::bigint, $5::bigint)",
                {num(id.value()), num(seq++), num(static_cast<std::int64_t>(reward.kind)), num(reward.ref_id),
                    num(reward.quantity)});
            if (!added) return std::unexpected(added.error());
        }
        return BatchRecord{.id = id, .spec = clean, .enabled = true, .code_count = 0, .created = now};
    });
}

Result<void> PgBook::set_batch_enabled(BatchId batch, bool enabled, std::string_view actor, UnixTime now) {
    if (!id_ok(batch.value())) return std::unexpected(Error::kMalformed);
    const std::optional<std::string> who = clean_text(actor, kActorMost);
    if (!who) return std::unexpected(Error::kReasonRequired);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<void> {
        const Result<Rows> updated = session.query(
            "UPDATE reward_batch SET enabled = $2::boolean WHERE id = $1::bigint RETURNING id",
            {num(batch.value()), text(enabled ? "true" : "false")});
        if (!updated) return std::unexpected(updated.error());
        if (updated->empty()) return std::unexpected(Error::kNotFound);
        return session.audit(enabled ? "batch_enable" : "batch_disable", batch.value(), "đợt mã", *who, now);
    });
}

Result<std::int64_t> PgBook::add_codes(BatchId batch, std::span<const std::string> hashes, UnixTime) {
    if (!id_ok(batch.value())) return std::unexpected(Error::kMalformed);
    if (const Result<void> ok = check_code_hashes(hashes); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<std::int64_t> {
        const Result<std::int64_t> exists =
            session.scalar("SELECT COUNT(*) FROM reward_batch WHERE id = $1::bigint", {num(batch.value())});
        if (!exists) return std::unexpected(exists.error());
        if (*exists == 0) return std::unexpected(Error::kNotFound);
        const Result<std::int64_t> have =
            session.scalar("SELECT COUNT(*) FROM redeem_code WHERE batch_id = $1::bigint", {num(batch.value())});
        if (!have) return std::unexpected(have.error());
        const auto added = static_cast<std::int64_t>(hashes.size());
        if (*have + added > config_.limits.max_codes_per_batch) return std::unexpected(Error::kTooMany);
        // Băm là hex thường (check_code_hashes), nên chuỗi mảng không cần escape.
        std::string array = "{";
        std::set<std::string_view> seen;
        for (const std::string& hash : hashes) {
            if (!seen.insert(hash).second) return std::unexpected(Error::kConflict);
            if (array.size() > 1) array.push_back(',');
            array.append(hash);
        }
        array.push_back('}');
        const Result<std::int64_t> clash = session.scalar(
            "SELECT COUNT(*) FROM redeem_code WHERE code_hash = ANY($1::text[])", {text(array)});
        if (!clash) return std::unexpected(clash.error());
        if (*clash > 0) return std::unexpected(Error::kConflict);
        const Result<Rows> inserted = session.query(
            "INSERT INTO redeem_code (batch_id, code_hash) SELECT $1::bigint, unnest($2::text[])",
            {num(batch.value()), text(array)});
        if (!inserted) return std::unexpected(inserted.error());
        return added;
    });
}

Result<RedeemOutcome> PgBook::redeem(AccountId account, std::string_view code_hash, std::string_view ip,
    UnixTime now) {
    if (!id_ok(account.value()) || !hash_hex_ok(code_hash) || !parse_ipv4(ip)) {
        return std::unexpected(Error::kMalformed);
    }
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<RedeemOutcome> {
        const Result<bool> frozen = session.frozen_of(account);
        if (!frozen) return std::unexpected(frozen.error());
        if (*frozen) return std::unexpected(Error::kFrozen);
        const Result<Rows> code = session.query(
            "SELECT id, batch_id, used_by IS NOT NULL FROM redeem_code WHERE code_hash = $1", {text(code_hash)});
        if (!code) return std::unexpected(code.error());
        if (code->empty()) return std::unexpected(Error::kBadCode);
        RowReader code_in{code->front()};
        const CodeId code_id{code_in.u64()};
        const BatchId batch_id{code_in.u64()};
        const bool used = code_in.flag();
        if (!code_in.ok()) return std::unexpected(session.corrupt("dòng redeem_code hỏng"));
        const Result<Rows> batch = session.query(
            "SELECT starts_at, ends_at, per_account_limit, enabled FROM reward_batch WHERE id = $1::bigint",
            {num(batch_id.value())});
        if (!batch) return std::unexpected(batch.error());
        if (batch->size() != 1) return std::unexpected(session.corrupt("redeem_code trỏ tới đợt không có"));
        RowReader batch_in{batch->front()};
        const std::optional<std::int64_t> starts = batch_in.opt_i64();
        const std::optional<std::int64_t> ends = batch_in.opt_i64();
        const std::int64_t per_account = batch_in.i64();
        const bool enabled = batch_in.flag();
        if (!batch_in.ok()) return std::unexpected(session.corrupt("dòng reward_batch hỏng"));
        const Result<std::int64_t> used_in_batch = session.scalar(
            "SELECT COUNT(*) FROM redeem_code WHERE batch_id = $1::bigint AND used_by = $2::bigint",
            {num(batch_id.value()), num(account.value())});
        if (!used_in_batch) return std::unexpected(used_in_batch.error());
        CodeFacts facts{.frozen = false,
            .batch_enabled = enabled,
            .starts = std::nullopt,
            .ends = std::nullopt,
            .used = used,
            .used_in_batch = *used_in_batch,
            .per_account_limit = per_account,
            .now = now};
        if (starts) facts.starts = UnixTime{*starts};
        if (ends) facts.ends = UnixTime{*ends};
        if (const Result<void> ok = redeem_step(facts); !ok) return std::unexpected(ok.error());
        const Result<Rows> rewards = session.query(
            "SELECT kind, ref_id, quantity FROM batch_reward WHERE batch_id = $1::bigint ORDER BY seq",
            {num(batch_id.value())});
        if (!rewards) return std::unexpected(rewards.error());
        std::vector<Reward> list;
        for (const store::PgRow& row : *rewards) {
            RowReader in{row};
            Reward reward;
            reward.kind = static_cast<std::uint8_t>(in.i64());
            reward.ref_id = in.u64();
            reward.quantity = in.i64();
            if (!in.ok()) return std::unexpected(session.corrupt("dòng batch_reward hỏng"));
            list.push_back(reward);
        }
        std::int64_t point_sum = 0;
        for (const Reward& reward : list) {
            if (reward.kind != 0) continue;
            const std::optional<std::int64_t> next = add_checked(point_sum, reward.quantity);
            if (!next) return std::unexpected(Error::kBadAmount);
            point_sum = *next;
        }
        if (const Result<void> row = session.ensure_row(account, now); !row) return std::unexpected(row.error());
        if (point_sum > 0) {
            const Result<Points> cache = session.cache_of(account);
            if (!cache) return std::unexpected(cache.error());
            const Result<Points> next = credit_step(Points{point_sum}, *cache, config_.limits);
            if (!next) return std::unexpected(next.error());
            const Result<void> posted = session.post(account, Points{point_sum}, LedgerKind::kRedeem, code_id.value(),
                "mã đổi", kSystem, now);
            if (!posted) return std::unexpected(posted.error());
        }
        RedeemOutcome outcome;
        outcome.batch = batch_id;
        outcome.points = Points{point_sum};
        for (const Reward& reward : list) {
            if (reward.kind == 0) continue;
            const Result<GrantRecord> grant = session.insert_grant(account, static_cast<GrantKind>(reward.kind),
                reward.ref_id, reward.quantity, "redeem", "mã đổi", kSystem, now);
            if (!grant) return std::unexpected(grant.error());
            outcome.grants.push_back(*grant);
        }
        const Result<Rows> marked = session.query(
            "UPDATE redeem_code SET used_by = $2::bigint, used_at = $3::bigint WHERE id = $1::bigint",
            {num(code_id.value()), num(account.value()), when(now)});
        if (!marked) return std::unexpected(marked.error());
        const Result<Rows> logged = session.query(
            "INSERT INTO redeem_log (code_id, account_id, ip, at) VALUES ($1::bigint, $2::bigint, $3::inet, $4::bigint)",
            {num(code_id.value()), num(account.value()), text(ip), when(now)});
        if (!logged) return std::unexpected(logged.error());
        const Result<Points> after = session.cache_of(account);
        if (!after) return std::unexpected(after.error());
        outcome.balance = *after;
        return outcome;
    });
}

Result<GrantRecord> PgBook::grant_add(const GrantSpec& spec, UnixTime now) {
    GrantSpec clean = spec;
    if (const Result<void> ok = check_grant_spec(clean, config_.limits); !ok) return std::unexpected(ok.error());
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<GrantRecord> {
        if (const Result<void> row = session.ensure_row(clean.account, now); !row) return std::unexpected(row.error());
        return session.insert_grant(clean.account, clean.kind, clean.ref_id, clean.quantity, clean.source, clean.reason,
            clean.actor, now);
    });
}

Result<std::vector<GrantRecord>> PgBook::grant_list(AccountId account, std::size_t limit) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<std::vector<GrantRecord>> {
        const Result<Rows> rows = session.query(
            select_from(kGrantCols,
                "FROM reward_grant WHERE account_id = $1::bigint AND status = 'pending' ORDER BY id LIMIT $2::bigint"),
            {num(account.value()), num(static_cast<std::int64_t>(clamp_limit(limit, kListMost)))});
        if (!rows) return std::unexpected(rows.error());
        std::vector<GrantRecord> out;
        for (const store::PgRow& row : *rows) {
            std::optional<GrantRecord> grant = grant_of(row);
            if (!grant) return std::unexpected(session.corrupt("dòng reward_grant hỏng"));
            out.push_back(std::move(*grant));
        }
        return out;
    });
}

Result<GrantClaimed> PgBook::grant_claim(GrantId grant, AccountId account, CharacterId character, UnixTime now) {
    if (!id_ok(grant.value()) || !id_ok(account.value()) || !id_ok(character.value())) {
        return std::unexpected(Error::kMalformed);
    }
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<GrantClaimed> {
        const Result<std::optional<GrantRecord>> found = session.grant_by_id(grant);
        if (!found) return std::unexpected(found.error());
        if (!*found || (*found)->account != account) return std::unexpected(Error::kNotFound);
        GrantRecord record = **found;
        const Result<bool> frozen = session.frozen_of(account);
        if (!frozen) return std::unexpected(frozen.error());
        if (*frozen) return std::unexpected(Error::kFrozen);
        if (record.status == GrantStatus::kDelivering) {
            const Result<std::optional<GrantOrder>> open = session.open_grant_order(grant);
            if (!open) return std::unexpected(open.error());
            if (*open) {
                if ((*open)->character != character) return std::unexpected(Error::kBadState);
                return GrantClaimed{.order = **open, .grant = record, .replayed = true};
            }
        }
        if (record.status != GrantStatus::kPending) return std::unexpected(Error::kBadState);
        const Result<Rows> inserted = session.query(
            "INSERT INTO grant_order (grant_id, character_id, status, created_at, updated_at) VALUES ($1::bigint, "
            "$2::bigint, 'pending', $3::bigint, $3::bigint) RETURNING id",
            {num(grant.value()), num(character.value()), when(now)});
        if (!inserted) return std::unexpected(inserted.error());
        if (inserted->size() != 1) return std::unexpected(session.corrupt("INSERT grant_order không trả id"));
        RowReader in{inserted->front()};
        const GrantOrderId order_id{in.u64()};
        if (!in.ok()) return std::unexpected(session.corrupt("id grant_order hỏng"));
        const Result<Rows> updated = session.query(
            "UPDATE reward_grant SET status = 'delivering', updated_at = $2::bigint WHERE id = $1::bigint",
            {num(grant.value()), when(now)});
        if (!updated) return std::unexpected(updated.error());
        record.status = GrantStatus::kDelivering;
        const GrantOrder order{.id = order_id,
            .grant = grant,
            .character = character,
            .status = GrantOrderStatus::kPending,
            .created = now,
            .updated = now};
        return GrantClaimed{.order = order, .grant = record, .replayed = false};
    });
}

Result<GrantFinished> PgBook::grant_finish(GrantOrderId order, Verdict verdict, UnixTime now) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<GrantFinished> {
        const Result<Rows> rows =
            session.query(select_from(kGrantOrderCols, "FROM grant_order WHERE id = $1::bigint"), {num(order.value())});
        if (!rows) return std::unexpected(rows.error());
        if (rows->empty()) return std::unexpected(Error::kNotFound);
        std::optional<GrantOrder> found = grant_order_of(rows->front());
        if (!found) return std::unexpected(session.corrupt("dòng grant_order hỏng"));
        const Result<std::optional<GrantRecord>> grant = session.grant_by_id(found->grant);
        if (!grant) return std::unexpected(grant.error());
        if (!*grant) return std::unexpected(session.corrupt("grant_order trỏ tới quà không có"));
        GrantRecord record = **grant;
        const Result<FinishAct> act = grant_finish_step(found->status, verdict);
        if (!act) return std::unexpected(act.error());
        if (*act == FinishAct::kDuplicate) return GrantFinished{.order = *found, .grant = record, .replayed = true};
        const bool confirm = *act == FinishAct::kConfirm;
        const Result<Rows> order_updated = session.query(
            "UPDATE grant_order SET status = $2, updated_at = $3::bigint WHERE id = $1::bigint",
            {num(order.value()), text(to_text(confirm ? GrantOrderStatus::kDone : GrantOrderStatus::kCancelled)),
                when(now)});
        if (!order_updated) return std::unexpected(order_updated.error());
        const GrantStatus next = confirm ? GrantStatus::kDelivered : GrantStatus::kPending;
        const Result<Rows> grant_updated = session.query(
            "UPDATE reward_grant SET status = $2, updated_at = $3::bigint WHERE id = $1::bigint",
            {num(record.id.value()), text(to_text(next)), when(now)});
        if (!grant_updated) return std::unexpected(grant_updated.error());
        found->status = confirm ? GrantOrderStatus::kDone : GrantOrderStatus::kCancelled;
        found->updated = now;
        record.status = next;
        return GrantFinished{.order = *found, .grant = record, .replayed = false};
    });
}

Result<std::vector<GrantOrder>> PgBook::grant_open(std::size_t limit) {
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<std::vector<GrantOrder>> {
        const Result<Rows> rows = session.query(
            select_from(kGrantOrderCols,
                "FROM grant_order WHERE status = 'pending' ORDER BY created_at, id LIMIT $1::bigint"),
            {num(static_cast<std::int64_t>(clamp_limit(limit, kListMost)))});
        if (!rows) return std::unexpected(rows.error());
        std::vector<GrantOrder> out;
        for (const store::PgRow& row : *rows) {
            const std::optional<GrantOrder> order = grant_order_of(row);
            if (!order) return std::unexpected(session.corrupt("dòng grant_order hỏng"));
            out.push_back(*order);
        }
        return out;
    });
}

// ---- chỉnh tay -----------------------------------------------------------------------------------

Result<Points> PgBook::admin_adjust(AccountId account, Points delta, RequestId request, const Audit& audit,
    UnixTime now) {
    if (!id_ok(account.value()) || !id_ok(request.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<Points> {
        const Result<Rows> known = session.query(
            "SELECT account_id, delta FROM point_ledger WHERE kind = 'admin' AND ref_id = $1::bigint",
            {num(request.value())});
        if (!known) return std::unexpected(known.error());
        if (!known->empty()) {
            RowReader in{known->front()};
            const AccountId owner{in.u64()};
            const Points was{in.i64()};
            if (!in.ok()) return std::unexpected(session.corrupt("dòng sổ admin hỏng"));
            if (owner != account || was != delta) return std::unexpected(Error::kConflict);
            return session.cache_of(account);
        }
        const Result<Points> cache = session.cache_of(account);
        if (!cache) return std::unexpected(cache.error());
        const std::optional<std::string> reason = clean_text(audit.reason, kReasonMost);
        const std::optional<std::string> actor = clean_text(audit.actor, kActorMost);
        if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
        const Result<Points> next = admin_step(delta, *reason, *actor, *cache, config_.limits);
        if (!next) return std::unexpected(next.error());
        if (const Result<void> row = session.ensure_row(account, now); !row) return std::unexpected(row.error());
        const Result<void> posted =
            session.post(account, delta, LedgerKind::kAdmin, request.value(), *reason, *actor, now);
        if (!posted) return std::unexpected(posted.error());
        return session.cache_of(account);
    });
}

Result<std::vector<LedgerEntry>> PgBook::ledger_tail(AccountId account, std::size_t limit) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<std::vector<LedgerEntry>> {
        const Result<Rows> rows = session.query(
            select_from(kLedgerCols, "FROM point_ledger WHERE account_id = $1::bigint ORDER BY id DESC LIMIT $2::bigint"),
            {num(account.value()), num(static_cast<std::int64_t>(clamp_limit(limit, kLedgerTailMost)))});
        if (!rows) return std::unexpected(rows.error());
        std::vector<LedgerEntry> out;
        for (const store::PgRow& row : *rows) {
            std::optional<LedgerEntry> entry = ledger_of(row);
            if (!entry) return std::unexpected(session.corrupt("dòng point_ledger hỏng"));
            out.push_back(std::move(*entry));
        }
        return out;
    });
}

// ---- tiêu ingot và đối soát ----------------------------------------------------------------------

Result<SpendSummary> PgBook::record_spend(std::span<const SpendEvent> events, UnixTime now) {
    if (const Result<void> ok = check_spend_events(events); !ok) return std::unexpected(ok.error());
    const std::optional<std::int64_t> day = day_of(now);
    if (!day) return std::unexpected(Error::kBadAmount);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<SpendSummary> {
        std::vector<SpendEvent> fresh;
        SpendSummary summary;
        for (const SpendEvent& event : events) {
            const SpendEvent* known = nullptr;
            SpendEvent stored_event;
            const Result<Rows> stored = session.query(
                "SELECT account_id, character_id, amount FROM spend_log WHERE event = $1::bigint", {num(event.event)});
            if (!stored) return std::unexpected(stored.error());
            if (!stored->empty()) {
                RowReader in{stored->front()};
                stored_event.event = event.event;
                stored_event.account = AccountId{in.u64()};
                stored_event.character = CharacterId{in.u64()};
                stored_event.amount = Ingot{in.i64()};
                if (!in.ok()) return std::unexpected(session.corrupt("dòng spend_log hỏng"));
                known = &stored_event;
            }
            const auto batch = std::ranges::find(fresh, event.event, &SpendEvent::event);
            if (batch != fresh.end()) known = &*batch;
            if (known == nullptr) {
                fresh.push_back(event);
                ++summary.recorded;
                continue;
            }
            const bool same = known->account == event.account && known->character == event.character &&
                known->amount == event.amount;
            if (!same) return std::unexpected(Error::kConflict);
            ++summary.duplicates;
        }
        for (const SpendEvent& event : fresh) {
            if (const Result<void> row = session.ensure_row(event.account, now); !row) return std::unexpected(row.error());
            const Result<Rows> inserted = session.query(
                "INSERT INTO spend_log (event, account_id, character_id, amount, day, at) VALUES ($1::bigint, "
                "$2::bigint, $3::bigint, $4::bigint, $5::bigint, $6::bigint)",
                {num(event.event), num(event.account.value()), num(event.character.value()), num(event.amount.value()),
                    num(*day), when(now)});
            if (!inserted) return std::unexpected(inserted.error());
        }
        return summary;
    });
}

Result<Ingot> PgBook::spend_headroom(CharacterId character, UnixTime now) {
    if (!id_ok(character.value())) return std::unexpected(Error::kMalformed);
    const std::optional<std::int64_t> day = day_of(now);
    if (!day) return std::unexpected(Error::kBadAmount);
    if (config_.daily_ingot_cap == 0) return Ingot{kNoCapHeadroom};
    return Session::run(*this, Session::Mode::kSingle, [&](Session& session) -> Result<Ingot> {
        const Result<std::int64_t> spent = session.scalar(
            "SELECT COALESCE(SUM(amount), 0) FROM spend_log WHERE character_id = $1::bigint AND day = $2::bigint",
            {num(character.value()), num(*day)});
        if (!spent) return std::unexpected(spent.error());
        return Ingot{std::max<std::int64_t>(config_.daily_ingot_cap - *spent, 0)};
    });
}

Result<Conservation> PgBook::ledger_check() {
    return Session::run(*this, Session::Mode::kSnapshot, [&](Session& session) { return session.conservation(); });
}

Result<Points> PgBook::rebuild_balance(AccountId account, std::string_view actor, UnixTime now) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    const std::optional<std::string> who = clean_text(actor, kActorMost);
    if (!who) return std::unexpected(Error::kReasonRequired);
    return Session::run(*this, Session::Mode::kWrite, [&](Session& session) -> Result<Points> {
        if (const Result<void> row = session.ensure_row(account, now); !row) return std::unexpected(row.error());
        const Result<std::int64_t> sum = session.scalar(
            "SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE account_id = $1::bigint", {num(account.value())});
        if (!sum) return std::unexpected(sum.error());
        const Result<Points> was = session.cache_of(account);
        if (!was) return std::unexpected(was.error());
        const Result<Rows> updated = session.query(
            "UPDATE point_balance SET points = $2::bigint, updated_at = $3::bigint WHERE account_id = $1::bigint",
            {num(account.value()), num(*sum), when(now)});
        if (!updated) return std::unexpected(updated.error());
        const Result<void> logged = session.audit("rebuild_balance", account.value(),
            std::format("cache {} -> sổ {}", was->value(), *sum), *who, now);
        if (!logged) return std::unexpected(logged.error());
        return Points{*sum};
    });
}

Result<DayReport> PgBook::day_report(std::int64_t day) {
    if (day < 0 || day > std::numeric_limits<std::int64_t>::max() / kSecondsPerDay - 1) {
        return std::unexpected(Error::kBadAmount);
    }
    return Session::run(*this, Session::Mode::kSnapshot, [&](Session& session) -> Result<DayReport> {
        const std::int64_t from = day * kSecondsPerDay;
        const std::int64_t to = from + kSecondsPerDay;
        const Params range{num(from), num(to)};
        DayReport report;
        report.day = day;
        const Result<std::int64_t> topped = session.scalar(
            "SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'top_up' AND at >= $1::bigint AND at < "
            "$2::bigint",
            range);
        if (!topped) return std::unexpected(topped.error());
        const Result<std::int64_t> refunded = session.scalar(
            "SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'refund' AND at >= $1::bigint AND at < "
            "$2::bigint",
            range);
        if (!refunded) return std::unexpected(refunded.error());
        report.topped_up = Points{*topped};
        report.refunded = Points{-*refunded};
        const Result<Rows> exchanged = session.query(
            "SELECT COALESCE(SUM(points), 0), COALESCE(SUM(ingot), 0) FROM exchange_order WHERE status = 'confirmed' "
            "AND updated_at >= $1::bigint AND updated_at < $2::bigint",
            range);
        if (!exchanged) return std::unexpected(exchanged.error());
        if (exchanged->size() != 1) return std::unexpected(session.corrupt("tổng đơn đổi trong ngày hỏng"));
        RowReader exchanged_in{exchanged->front()};
        report.exchanged = Points{exchanged_in.i64()};
        std::int64_t issued = exchanged_in.i64();
        if (!exchanged_in.ok()) return std::unexpected(session.corrupt("tổng đơn đổi trong ngày hỏng"));
        const Result<std::int64_t> open = session.scalar(
            "SELECT COUNT(*) FROM exchange_order WHERE status IN ('pending', 'stale')");
        if (!open) return std::unexpected(open.error());
        report.open_exchanges = *open;
        const Result<std::int64_t> granted = session.scalar(
            "SELECT COALESCE(SUM(g.quantity), 0) FROM grant_order o JOIN reward_grant g ON g.id = o.grant_id WHERE "
            "o.status = 'done' AND o.updated_at >= $1::bigint AND o.updated_at < $2::bigint AND g.kind = 'ingot'",
            range);
        if (!granted) return std::unexpected(granted.error());
        issued += *granted;
        report.ingot_issued = Ingot{issued};
        const Result<Rows> spent = session.query(
            "SELECT COALESCE(SUM(amount), 0), COUNT(*) FROM spend_log WHERE day = $1::bigint", {num(day)});
        if (!spent) return std::unexpected(spent.error());
        if (spent->size() != 1) return std::unexpected(session.corrupt("tổng tiêu trong ngày hỏng"));
        RowReader spent_in{spent->front()};
        report.ingot_spent = Ingot{spent_in.i64()};
        report.spend_events = spent_in.i64();
        if (!spent_in.ok()) return std::unexpected(session.corrupt("tổng tiêu trong ngày hỏng"));
        const Result<Conservation> check = session.conservation();
        if (!check) return std::unexpected(check.error());
        report.conservation = *check;
        return report;
    });
}

} // namespace game::billing
