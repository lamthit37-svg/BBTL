#pragma once
// Giao diện của sổ billing: mọi việc billing làm với dữ liệu đều đi qua đây. Hai bản cài đặt:
// MemoryBook (bản nhớ, chạy test không cần database) và PgBook (PostgreSQL, billing/db). Cả hai gọi
// cùng bộ hàm luật trong rules.hpp nên không lệch luật; test so hai bản trên cùng một kịch bản.
//
// Thời gian do bên gọi đưa (UnixTime, giây UTC), không có hàm nào đọc đồng hồ: test điều khiển được
// hạn chờ, hạn mã, ranh giới ngày. Ngày của hạn mức tiêu và đối soát là ngày UTC (UnixTime / 86400).
//
// Mọi thao tác ghi đều có khoá lặp lại, để bên gọi gọi lại sau khi mạng đứt hay tiến trình khởi động
// lại mà không nhân đôi: đơn nạp (provider, trade_no), xin đổi (account, request_id), báo kết quả
// (order_id, mang kết quả cũ thì trả lại như cũ), sự kiện tiêu (event id). Lỗi database luôn là kBusy
// và không để lại nửa giao dịch.
//
// Sổ điểm chỉ ghi thêm: số dư của một tài khoản là tổng delta trong point_ledger; point_balance chỉ là
// bản nhớ đệm và ledger_check/rebuild_balance kiểm và dựng lại nó từ sổ. Không hàm nào sửa số dư mà
// không thêm một dòng sổ.

#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing {

// Cấu hình chạy của sổ, lấy từ billing.toml và bảng giới hạn.
struct BookConfig {
    Limits limits;
    // Một điểm đổi được bao nhiêu ingot (billing.toml points.ingot_per_point).
    std::int64_t ingot_per_point = 1;
    // Điểm tặng khi tài khoản được billing thấy lần đầu, phần mười (billing.toml register_gift x 10).
    Points register_gift;
    // Trần ingot một nhân vật tiêu mỗi ngày; 0 là không giới hạn.
    std::int64_t daily_ingot_cap = 0;
    // Đơn đổi chờ quá số giây này thì sang kStale; 0 là không bao giờ.
    std::int64_t pending_timeout_seconds = 0;
};

// ---- Số dư và sổ -------------------------------------------------------------------------------

struct Balance {
    // Điểm dùng được: tổng sổ (điểm đang giữ cho đơn đổi chờ đã bị trừ khỏi đây).
    Points available;
    // Điểm đang bị giữ cho đơn đổi kPending và kStale.
    Points held;
    bool frozen = false;
};

enum class LedgerKind : std::uint8_t {
    kTopUp = 1,
    kRefund,
    kExchangeHold,
    kExchangeRelease,
    kRegisterGift,
    kRedeem,
    kAdmin,
};

[[nodiscard]] std::string_view to_text(LedgerKind kind) noexcept;
[[nodiscard]] std::optional<LedgerKind> ledger_kind_of(std::string_view text) noexcept;

struct LedgerEntry {
    std::uint64_t id = 0;
    AccountId account;
    Points delta;
    LedgerKind kind = LedgerKind::kAdmin;
    // Id của đơn, mã hay tài khoản mà dòng sổ này thuộc về; 0 khi không có (chỉnh tay).
    std::uint64_t ref = 0;
    std::string reason;
    std::string actor;
    UnixTime at;
};

// Lý do và người làm của một thao tác quản trị; cả hai đi vào sổ kiểm toán nên không được rỗng.
struct Audit {
    std::string_view reason;
    std::string_view actor;
};

// Khoá tự nhiên của đơn nạp.
struct PaymentKey {
    std::string_view provider;
    std::string_view trade_no;
};

// ---- Đơn nạp -----------------------------------------------------------------------------------

struct PaymentEvent {
    std::string provider;
    std::string trade_no;
    AccountId account;
    // Điểm (phần mười) mà đơn này cộng khi trả xong.
    Points points;
    // Số tiền nhà cung cấp thu, đơn vị nhỏ nhất của tiền tệ; chỉ để lưu và đối chiếu.
    std::int64_t amount_minor = 0;
    std::string currency;
    PaymentStatus status = PaymentStatus::kPaid;
};

struct PaymentRecord {
    PaymentId id;
    PaymentEvent event;
    UnixTime created;
    UnixTime updated;
};

enum class PaymentResult : std::uint8_t {
    // Sự kiện làm đổi trạng thái đơn.
    kApplied = 1,
    // Cùng trạng thái đã ghi: nhà cung cấp gọi lại.
    kDuplicate,
    // Sự kiện cũ tới muộn, không đổi gì.
    kIgnored,
};

struct PaymentOutcome {
    PaymentResult result = PaymentResult::kApplied;
    PaymentRecord record;
    Points balance;
};

// ---- Đổi điểm lấy ingot ------------------------------------------------------------------------------

struct ExchangeRequest {
    AccountId account;
    CharacterId character;
    RequestId request;
    Ingot ingot;
};

struct ExchangeOrder {
    ExchangeId id;
    AccountId account;
    CharacterId character;
    RequestId request;
    Ingot ingot;
    // Điểm (phần mười) đã giữ.
    Points points;
    ExchangeStatus status = ExchangeStatus::kPending;
    UnixTime created;
    UnixTime updated;
};

struct ExchangeOutcome {
    ExchangeOrder order;
    // Gọi lại với cùng khoá: trả đơn đã có, không trừ thêm.
    bool replayed = false;
    Points balance;
};

// ---- Quà và mã đổi -------------------------------------------------------------------------------

// Một khoản trong đợt mã. kind 0 là điểm nạp (cộng vào sổ billing ngay, quantity phần mười); các
// giá trị khác là GrantKind (thành quà chờ phát cho nhân vật).
struct Reward {
    std::uint8_t kind = 0;
    std::uint64_t ref_id = 0;
    std::int64_t quantity = 0;
};

inline constexpr std::size_t kRewardsMost = 16;

[[nodiscard]] bool reward_ok(const Reward& reward, const Limits& limits) noexcept;

struct BatchSpec {
    std::string name;
    std::optional<UnixTime> starts;
    std::optional<UnixTime> ends;
    std::int64_t per_account_limit = 1;
    std::vector<Reward> rewards;
    std::string actor;
};

struct BatchRecord {
    BatchId id;
    BatchSpec spec;
    bool enabled = true;
    std::int64_t code_count = 0;
    UnixTime created;
};

struct GrantRecord {
    GrantId id;
    AccountId account;
    GrantKind kind = GrantKind::kItem;
    std::uint64_t ref_id = 0;
    std::int64_t quantity = 0;
    GrantStatus status = GrantStatus::kPending;
    // "redeem", "admin" hoặc "prize".
    std::string source;
    UnixTime created;
};

struct RedeemOutcome {
    BatchId batch;
    // Điểm đã cộng ngay vào sổ.
    Points points;
    Points balance;
    std::vector<GrantRecord> grants;
};

struct GrantOrder {
    GrantOrderId id;
    GrantId grant;
    CharacterId character;
    GrantOrderStatus status = GrantOrderStatus::kPending;
    UnixTime created;
    UnixTime updated;
};

struct GrantClaimed {
    GrantOrder order;
    GrantRecord grant;
    // Gọi lại cho cùng quà khi đơn còn mở: trả đơn đang mở.
    bool replayed = false;
};

struct GrantFinished {
    GrantOrder order;
    GrantRecord grant;
    bool replayed = false;
};

struct GrantSpec {
    AccountId account;
    GrantKind kind = GrantKind::kItem;
    std::uint64_t ref_id = 0;
    std::int64_t quantity = 0;
    std::string source;
    std::string reason;
    std::string actor;
};

// ---- Tiêu ingot và đối soát -----------------------------------------------------------------------

// Một lượt tiêu ingot zone báo về. event là số duy nhất do zone cấp (một sự kiện báo hai lần chỉ
// ghi một lần).
struct SpendEvent {
    std::uint64_t event = 0;
    AccountId account;
    CharacterId character;
    Ingot amount;
};

inline constexpr std::size_t kSpendBatchMost = 64;

struct SpendSummary {
    std::int64_t recorded = 0;
    std::int64_t duplicates = 0;
};

// Kết quả đối chiếu sổ: điểm nạp = điểm còn + điểm đã đổi + điểm hoàn (+ phần chỉnh tay, quà, mã).
struct Conservation {
    // Tổng dòng sổ kTopUp (cộng) của mọi đơn.
    Points topped_up;
    // Tổng dòng sổ kRefund (đã đổi dấu thành số dương).
    Points refunded;
    // Tổng dòng sổ kRegisterGift, kRedeem, kAdmin (có thể âm).
    Points other_net;
    // Tổng point_balance (bản nhớ đệm).
    Points balance_sum;
    // Điểm của đơn đổi đã kConfirmed.
    Points exchange_confirmed;
    // Điểm của đơn đổi còn kPending hoặc kStale.
    Points exchange_held;
    // Số tài khoản có point_balance khác tổng sổ của nó.
    std::int64_t mismatched_accounts = 0;
    // topped_up + other_net == balance_sum + exchange_confirmed + exchange_held + refunded, và dòng sổ
    // kExchangeHold/kExchangeRelease khớp với bảng đơn đổi.
    bool balanced = false;
};

struct DayReport {
    // Số ngày UTC từ 1970-01-01.
    std::int64_t day = 0;
    Points topped_up;
    Points refunded;
    // Điểm của đơn đổi được chốt kConfirmed trong ngày.
    Points exchanged;
    // Ingot đã phát trong ngày: đơn đổi chốt trong ngày cộng quà loại ingot đã giao trong ngày.
    Ingot ingot_issued;
    Ingot ingot_spent;
    std::int64_t spend_events = 0;
    // Đơn đổi còn mở (kPending, kStale) lúc lập báo cáo.
    std::int64_t open_exchanges = 0;
    Conservation conservation;
};

inline constexpr std::size_t kListMost = 100;
// Số ingot "không có trần" mà spend_headroom trả khi daily_ingot_cap == 0.
inline constexpr std::int64_t kNoCapHeadroom = 1'000'000'000'000;
inline constexpr std::size_t kLedgerTailMost = 50;

class Book {
public:
    Book() = default;
    virtual ~Book() = default;
    Book(const Book&) = delete;
    Book& operator=(const Book&) = delete;
    Book(Book&&) = delete;
    Book& operator=(Book&&) = delete;

    // ---- tài khoản
    // Thấy tài khoản lần đầu thì tặng register_gift (một lần, khoá (kRegisterGift, account)). Gọi lại
    // chỉ trả số dư.
    [[nodiscard]] virtual Result<Balance> ensure_account(AccountId account, UnixTime now) = 0;
    [[nodiscard]] virtual Result<Balance> balance(AccountId account) = 0;
    [[nodiscard]] virtual Result<void> set_frozen(AccountId account, bool frozen, const Audit& audit,
        UnixTime now) = 0;

    // ---- đơn nạp
    [[nodiscard]] virtual Result<PaymentOutcome> apply_payment(const PaymentEvent& event, UnixTime now) = 0;
    // Hoàn một đơn đã trả: dòng sổ âm, đơn thành kRefunded. kInsufficient khi người chơi đã tiêu điểm.
    [[nodiscard]] virtual Result<PaymentOutcome> refund_payment(const PaymentKey& key, const Audit& audit,
        UnixTime now) = 0;
    [[nodiscard]] virtual Result<PaymentRecord> find_payment(const PaymentKey& key) = 0;

    // ---- đổi điểm lấy ingot
    [[nodiscard]] virtual Result<ExchangeOutcome> exchange_begin(const ExchangeRequest& request, UnixTime now) = 0;
    [[nodiscard]] virtual Result<ExchangeOutcome> exchange_finish(ExchangeId order, Verdict verdict, UnixTime now) = 0;
    [[nodiscard]] virtual Result<ExchangeOrder> find_exchange(ExchangeId order) = 0;
    // Đơn kPending/kStale cũ nhất trước, tối đa kListMost: danh sách world phải hỏi game bằng order_id.
    [[nodiscard]] virtual Result<std::vector<ExchangeOrder>> exchange_open(std::size_t limit) = 0;
    // Đánh dấu kStale các đơn quá hạn; trả số đơn vừa đổi. Không động tới điểm.
    [[nodiscard]] virtual Result<std::int64_t> exchange_sweep(UnixTime now) = 0;

    // ---- quà và mã đổi
    [[nodiscard]] virtual Result<BatchRecord> create_batch(const BatchSpec& spec, UnixTime now) = 0;
    [[nodiscard]] virtual Result<void> set_batch_enabled(BatchId batch, bool enabled, std::string_view actor,
        UnixTime now) = 0;
    // Thêm mã (đã băm bằng hash_code) vào đợt. Trùng băm thì kConflict và không thêm mã nào.
    [[nodiscard]] virtual Result<std::int64_t> add_codes(BatchId batch, std::span<const std::string> hashes,
        UnixTime now) = 0;
    [[nodiscard]] virtual Result<RedeemOutcome> redeem(AccountId account, std::string_view code_hash,
        std::string_view ip, UnixTime now) = 0;
    [[nodiscard]] virtual Result<GrantRecord> grant_add(const GrantSpec& spec, UnixTime now) = 0;
    [[nodiscard]] virtual Result<std::vector<GrantRecord>> grant_list(AccountId account, std::size_t limit) = 0;
    [[nodiscard]] virtual Result<GrantClaimed> grant_claim(GrantId grant, AccountId account, CharacterId character,
        UnixTime now) = 0;
    [[nodiscard]] virtual Result<GrantFinished> grant_finish(GrantOrderId order, Verdict verdict, UnixTime now) = 0;
    [[nodiscard]] virtual Result<std::vector<GrantOrder>> grant_open(std::size_t limit) = 0;

    // ---- chỉnh tay
    // request là khoá lặp lại, duy nhất toàn cục: gọi lại cùng request với cùng nội dung trả số dư
    // hiện tại và không cộng thêm; khác nội dung thì kConflict.
    [[nodiscard]] virtual Result<Points> admin_adjust(AccountId account, Points delta, RequestId request,
        const Audit& audit, UnixTime now) = 0;
    [[nodiscard]] virtual Result<std::vector<LedgerEntry>> ledger_tail(AccountId account, std::size_t limit) = 0;

    // ---- tiêu ingot và đối soát
    [[nodiscard]] virtual Result<SpendSummary> record_spend(std::span<const SpendEvent> events, UnixTime now) = 0;
    // Ingot nhân vật còn được tiêu trong ngày UTC của `now`; kNoCapHeadroom khi không có trần
    // (daily_ingot_cap == 0). Zone hỏi trước khi cho tiêu; vượt trần thì trả 0, không âm.
    [[nodiscard]] virtual Result<Ingot> spend_headroom(CharacterId character, UnixTime now) = 0;
    [[nodiscard]] virtual Result<Conservation> ledger_check() = 0;
    // Dựng lại point_balance của một tài khoản từ sổ; trả số dư đúng. Ghi một dòng kiểm toán.
    [[nodiscard]] virtual Result<Points> rebuild_balance(AccountId account, std::string_view actor, UnixTime now) = 0;
    [[nodiscard]] virtual Result<DayReport> day_report(std::int64_t day) = 0;
};

} // namespace game::billing
