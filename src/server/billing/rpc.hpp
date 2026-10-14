#pragma once
// Giao thức ipc của billing: một yêu cầu (Op + thân) và một trả lời (mã + thân), cả hai là byte thô.
// Đường vận chuyển (khung mã hoá XChaCha20-Poly1305 bằng khoá ipc, một yêu cầu một kết nối) là của
// billing/serve; ở đây chỉ có nội dung. Chỉ world gọi billing; webhook không đi qua đường này.
//
// Mã trả lời 0 là thành công, khác 0 là billing::Error. Thân trả lời tối đa 8 KiB (trần của khung).
//
// Phía bộ gọi (world, công cụ quản trị) dùng nhóm hàm dựng yêu cầu và đọc trả lời ở namespace rpc;
// phía billing dùng handle(). Hai phía cùng nằm ở đây để test vòng đi-về trong một chỗ.

#include "billing/book.hpp"
#include "billing/code.hpp"
#include "billing/throttle.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing {

enum class Op : std::uint8_t {
    kBalance = 1,
    kEnsureAccount = 2,
    kSetFrozen = 3,
    kQuote = 4,
    kExchangeBegin = 5,
    kExchangeFinish = 6,
    kExchangeOpen = 7,
    kFindExchange = 8,
    kExchangeSweep = 9,
    kRedeem = 10,
    kGrantList = 11,
    kGrantClaim = 12,
    kGrantFinish = 13,
    kGrantOpen = 14,
    kGrantAdd = 15,
    kAdminAdjust = 16,
    kRefundPayment = 17,
    kFindPayment = 18,
    kCreateBatch = 19,
    kSetBatchEnabled = 20,
    kMintCodes = 21,
    kSpendRecord = 22,
    kSpendHeadroom = 23,
    kLedgerCheck = 24,
    kRebuildBalance = 25,
    kDayReport = 26,
    kLedgerTail = 27,
};

struct Request {
    Op op = Op::kBalance;
    std::vector<std::byte> body;
};

struct Reply {
    std::uint16_t code = 0;
    std::vector<std::byte> body;
};

// Trần theo dung lượng trả lời 8 KiB.
inline constexpr std::size_t kMintPerCallMost = 300;
inline constexpr std::size_t kLedgerTailWireMost = 20;

// Mọi thứ billing cần để xử lý một yêu cầu. Con trỏ và config phải sống lâu hơn lời gọi handle.
struct Dispatch {
    Book* book = nullptr;
    RedeemThrottle* throttle = nullptr;
    const BookConfig* config = nullptr;
    RandomSource random;
    UnixTime now;
    ids::Tick tick;
};

// Xử lý một yêu cầu. Không ném, không check trên dữ liệu của yêu cầu. Yêu cầu hỏng trả kMalformed.
[[nodiscard]] Reply handle(const Dispatch& cx, const Request& request);

// Một điểm trả lỗi/ thành công để bên khác (webhook, test) dựng Reply cho giống.
[[nodiscard]] Reply error_reply(Error error);

struct Quote {
    // Số điểm (phần mười) phải trả cho `ingot`.
    Points cost;
    std::int64_t ingot_per_point = 0;
    std::int64_t min_ingot = 0;
    std::int64_t max_ingot = 0;
};

struct MintedCodes {
    // Dạng in được ("ABCD-EFGH-JKMN-PQRS").
    std::vector<std::string> codes;
};

struct SpendHeadroom {
    Ingot remaining;
};

// Mã người chơi gõ nguyên văn (chưa chuẩn hoá) cùng IPv4 của họ.
struct TypedCode {
    std::string_view ip;
    std::string_view code;
};

namespace rpc {

// ---- dựng yêu cầu (phía world) ----------------------------------------------------------------------
[[nodiscard]] Request balance(AccountId account);
[[nodiscard]] Request ensure_account(AccountId account);
[[nodiscard]] Request set_frozen(AccountId account, bool frozen, const Audit& audit);
[[nodiscard]] Request quote(Ingot ingot);
[[nodiscard]] Request exchange_begin(const ExchangeRequest& request);
[[nodiscard]] Request exchange_finish(ExchangeId order, Verdict verdict);
[[nodiscard]] Request exchange_open(std::uint16_t limit);
[[nodiscard]] Request find_exchange(ExchangeId order);
[[nodiscard]] Request exchange_sweep();
// code là chữ người chơi gõ nguyên văn (chưa chuẩn hoá); ip là IPv4 của người chơi.
[[nodiscard]] Request redeem(AccountId account, const TypedCode& typed);
[[nodiscard]] Request grant_list(AccountId account, std::uint16_t limit);
[[nodiscard]] Request grant_claim(GrantId grant, AccountId account, CharacterId character);
[[nodiscard]] Request grant_finish(GrantOrderId order, Verdict verdict);
[[nodiscard]] Request grant_open(std::uint16_t limit);
[[nodiscard]] Request grant_add(const GrantSpec& spec);
[[nodiscard]] Request admin_adjust(AccountId account, Points delta, RequestId request, const Audit& audit);
[[nodiscard]] Request refund_payment(const PaymentKey& key, const Audit& audit);
[[nodiscard]] Request find_payment(const PaymentKey& key);
[[nodiscard]] Request create_batch(const BatchSpec& spec);
[[nodiscard]] Request set_batch_enabled(BatchId batch, bool enabled, std::string_view actor);
[[nodiscard]] Request mint_codes(BatchId batch, std::uint16_t count, std::string_view actor);
[[nodiscard]] Request spend_record(std::span<const SpendEvent> events);
[[nodiscard]] Request spend_headroom(CharacterId character);
[[nodiscard]] Request ledger_check();
[[nodiscard]] Request rebuild_balance(AccountId account, std::string_view actor);
[[nodiscard]] Request day_report(std::int64_t day);
[[nodiscard]] Request ledger_tail(AccountId account, std::uint16_t limit);

// ---- đọc trả lời (phía world). Mã khác 0 thành Error; thân hỏng thành kBusy (kết quả không rõ, gọi lại
// được nhờ khoá lặp lại). -------------------------------------------------------------------------------
[[nodiscard]] Result<Balance> read_balance(const Reply& reply);
[[nodiscard]] Result<void> read_done(const Reply& reply);
[[nodiscard]] Result<Quote> read_quote(const Reply& reply);
[[nodiscard]] Result<ExchangeOutcome> read_exchange_outcome(const Reply& reply);
[[nodiscard]] Result<std::vector<ExchangeOrder>> read_exchange_list(const Reply& reply);
[[nodiscard]] Result<ExchangeOrder> read_exchange(const Reply& reply);
[[nodiscard]] Result<std::int64_t> read_count(const Reply& reply);
[[nodiscard]] Result<RedeemOutcome> read_redeem(const Reply& reply);
[[nodiscard]] Result<std::vector<GrantRecord>> read_grant_list(const Reply& reply);
[[nodiscard]] Result<GrantClaimed> read_grant_claimed(const Reply& reply);
[[nodiscard]] Result<GrantFinished> read_grant_finished(const Reply& reply);
[[nodiscard]] Result<std::vector<GrantOrder>> read_grant_orders(const Reply& reply);
[[nodiscard]] Result<GrantRecord> read_grant(const Reply& reply);
[[nodiscard]] Result<Points> read_points(const Reply& reply);
[[nodiscard]] Result<PaymentOutcome> read_payment_outcome(const Reply& reply);
[[nodiscard]] Result<PaymentRecord> read_payment(const Reply& reply);
[[nodiscard]] Result<BatchRecord> read_batch(const Reply& reply);
[[nodiscard]] Result<MintedCodes> read_minted(const Reply& reply);
[[nodiscard]] Result<SpendSummary> read_spend_summary(const Reply& reply);
[[nodiscard]] Result<SpendHeadroom> read_headroom(const Reply& reply);
[[nodiscard]] Result<Conservation> read_conservation(const Reply& reply);
[[nodiscard]] Result<DayReport> read_day_report(const Reply& reply);
[[nodiscard]] Result<std::vector<LedgerEntry>> read_ledger_tail(const Reply& reply);

} // namespace rpc

} // namespace game::billing
