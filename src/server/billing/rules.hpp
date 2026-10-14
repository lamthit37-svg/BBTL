#pragma once
// Luật thuần của billing: các máy trạng thái nhỏ và phép kiểm đứng trước mọi thao tác ghi. MemoryBook
// (bản nhớ, cho test) và PgBook (PostgreSQL) cùng gọi đúng những hàm này nên hai bản không thể lệch
// luật; chỗ chúng khác nhau chỉ là nơi lưu.
//
// Không hàm nào đọc đồng hồ, database hay đĩa. Thời gian do bên gọi đưa vào (UnixTime).
//
// Nguồn ngữ nghĩa: KE-HOACH-SERVER mục 4; trần mỗi lần đổi 500000 ingot và số dư hiển thị theo phần
// mười điểm từ script client 2026 (YuanbaoExchange.lua); loại tiền của quà 1 vàng, 5 ingot, 6 điểm tặng,
// 8 giao tử từ cột loại tiền của ShopTable.
// Khác gốc: bản 2008 không có máy trạng thái hai pha, đơn chỉ-thêm hay khoá lặp lại; bản mới thêm.

#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/types.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::billing {

// ---- Đơn nạp ---------------------------------------------------------------------------------

enum class PaymentStatus : std::uint8_t { kPending = 1, kPaid, kFailed, kRefunded };

// Việc phải làm khi một sự kiện của nhà cung cấp tới.
enum class PaymentAct : std::uint8_t {
    kCreatePending = 1,
    kCreatePaid,
    kCreateFailed,
    // Đơn đang chờ nay đã trả.
    kPromote,
    // Đơn đang chờ nay hỏng.
    kFail,
    kRefund,
    // Cùng trạng thái đã ghi: trả lời thành công, không đổi gì.
    kDuplicate,
    // Sự kiện cũ tới muộn (chờ sau khi đã trả): thừa nhận để nhà cung cấp thôi gọi lại, không đổi gì.
    kIgnore,
};

// existing là trạng thái đã ghi của (provider, trade_no), nullopt nếu chưa có. kConflict khi nhà
// cung cấp tự mâu thuẫn (trả rồi báo hỏng), kBadState khi bước không có nghĩa (hoàn một đơn chưa có).
[[nodiscard]] Result<PaymentAct> payment_step(std::optional<PaymentStatus> existing, PaymentStatus incoming) noexcept;

// ---- Đổi điểm lấy ingot, hai pha ------------------------------------------------------------

enum class ExchangeStatus : std::uint8_t {
    // Đã trừ điểm, chờ game báo.
    kPending = 1,
    // Quá hạn chờ: chờ đối soát, điểm vẫn bị giữ, không tự hoàn.
    kStale,
    kConfirmed,
    kCancelled,
};

// Kết quả game báo ở pha hai.
enum class Verdict : std::uint8_t {
    // Game đã cộng ingot (trong cùng giao dịch với dòng ledger_entry mang order_id).
    kDone = 1,
    // Game chắc chắn không cộng.
    kCancelled,
};

enum class FinishAct : std::uint8_t { kConfirm = 1, kCancel, kDuplicate };

// Số điểm (phần mười) phải trừ cho ingot: ceil(ingot * 10 / ingot_per_point). Làm tròn lên để máy chủ
// không bao giờ phát ingot mà thu thiếu điểm.
[[nodiscard]] Result<Points> exchange_cost(Ingot ingot, std::int64_t ingot_per_point, const Limits& limits) noexcept;

// Phép kiểm trước khi trừ điểm: đóng băng, số ingot, đủ điểm. Trả số điểm phải trừ.
[[nodiscard]] Result<Points> exchange_begin_step(Ingot ingot, std::int64_t ingot_per_point, Points balance,
    bool frozen, const Limits& limits) noexcept;

// Pha hai: kBadState khi báo ngược với kết quả đã chốt (đã xác nhận mà báo huỷ hoặc ngược lại).
[[nodiscard]] Result<FinishAct> exchange_finish_step(ExchangeStatus current, Verdict verdict) noexcept;

// Đơn đang chờ quá hạn thì sang kStale. timeout_seconds <= 0 nghĩa là không bao giờ quá hạn.
[[nodiscard]] bool exchange_overdue(UnixTime created, UnixTime now, std::int64_t timeout_seconds) noexcept;

// ---- Quà ----------------------------------------------------------------------------------

enum class GrantKind : std::uint8_t {
    // Số trùng cột loại tiền của ShopTable (1 vàng, 5 ingot, 6 điểm tặng, 8 giao tử); 100 là vật phẩm.
    kCoin = 1,
    kIngot = 5,
    kBonusPoint = 6,
    kBoundCoin = 8,
    kItem = 100,
};

enum class GrantStatus : std::uint8_t { kPending = 1, kDelivering, kDelivered, kVoid };
enum class GrantOrderStatus : std::uint8_t { kPending = 1, kDone, kCancelled };

[[nodiscard]] constexpr bool grant_kind_ok(std::uint8_t value) noexcept {
    return value == 1 || value == 5 || value == 6 || value == 8 || value == 100;
}

// Quà dạng vật phẩm cần id mẫu vật phẩm; các loại tiền không có id (ref_id phải bằng 0).
[[nodiscard]] constexpr bool grant_ref_ok(GrantKind kind, std::uint64_t ref_id) noexcept {
    if (kind == GrantKind::kItem) return id_ok(ref_id);
    return ref_id == 0;
}

[[nodiscard]] Result<FinishAct> grant_finish_step(GrantOrderStatus current, Verdict verdict) noexcept;

// ---- Mã đổi ---------------------------------------------------------------------------------

// Điều kiện để một mã dùng được, gom từ database/bộ nhớ trước khi gọi redeem_step.
struct CodeFacts {
    bool frozen = false;
    bool batch_enabled = false;
    // Mốc mở và đóng của đợt; nullopt là không giới hạn đầu đó.
    std::optional<UnixTime> starts;
    std::optional<UnixTime> ends;
    bool used = false;
    // Số mã của cùng đợt tài khoản này đã dùng.
    std::int64_t used_in_batch = 0;
    std::int64_t per_account_limit = 1;
    UnixTime now;
};

[[nodiscard]] Result<void> redeem_step(const CodeFacts& facts) noexcept;

// ---- Chỉnh tay và hạn mức -----------------------------------------------------------------------

inline constexpr std::size_t kReasonMost = 200;
inline constexpr std::size_t kActorMost = 64;

// Chữ in được, không ký tự điều khiển, đã cắt khoảng trắng đầu cuối; rỗng hoặc quá dài là không hợp lệ.
[[nodiscard]] std::optional<std::string> clean_text(std::string_view text, std::size_t most);

// Cộng hoặc trừ tay: cần lý do và người làm, delta khác 0 và không quá max_admin_adjust, số dư mới
// trong [0, max_balance]. Trả số dư mới.
[[nodiscard]] Result<Points> admin_step(Points delta, std::string_view reason, std::string_view actor, Points balance,
    const Limits& limits) noexcept;

// Cộng điểm không phải đơn nạp (quà đăng ký, mã đổi): số dư mới không quá max_balance.
[[nodiscard]] Result<Points> credit_step(Points delta, Points balance, const Limits& limits) noexcept;

// Tên nhà cung cấp, mã giao dịch: chữ, số, '_', '.', '-' dài 1 tới most.
[[nodiscard]] bool token_ok(std::string_view text, std::size_t most) noexcept;

// Mã tiền tệ ISO viết hoa ba chữ.
[[nodiscard]] bool currency_ok(std::string_view text) noexcept;

// Địa chỉ IPv4 dạng a.b.c.d (chỉ để ghi nhật ký và bộ đếm); không phân giải tên.
[[nodiscard]] std::optional<std::uint32_t> parse_ipv4(std::string_view text) noexcept;

// Tên bảng của trạng thái trong database; PgBook ghi và đọc bằng cặp hàm này.
[[nodiscard]] std::string_view to_text(PaymentStatus status) noexcept;
[[nodiscard]] std::optional<PaymentStatus> payment_status_of(std::string_view text) noexcept;
[[nodiscard]] std::string_view to_text(ExchangeStatus status) noexcept;
[[nodiscard]] std::optional<ExchangeStatus> exchange_status_of(std::string_view text) noexcept;
[[nodiscard]] std::string_view to_text(GrantStatus status) noexcept;
[[nodiscard]] std::optional<GrantStatus> grant_status_of(std::string_view text) noexcept;
[[nodiscard]] std::string_view to_text(GrantOrderStatus status) noexcept;
[[nodiscard]] std::optional<GrantOrderStatus> grant_order_status_of(std::string_view text) noexcept;
[[nodiscard]] std::string_view to_text(GrantKind kind) noexcept;
[[nodiscard]] std::optional<GrantKind> grant_kind_of(std::string_view text) noexcept;

} // namespace game::billing
