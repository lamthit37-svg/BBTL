#pragma once
// Phép kiểm đầu vào của từng thao tác Book, dùng chung cho MemoryBook và PgBook: mọi thứ do bên ngoài
// quyết định (chữ, số, độ dài, số phần tử) được kiểm miền ở đây TRƯỚC khi chạm sổ hay database. Lỗi
// là kMalformed (hình dạng sai) hoặc kBadAmount (số ngoài miền), không bao giờ là check/assert.

#include "billing/book.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace game::billing {

inline constexpr std::size_t kProviderMost = 32;
inline constexpr std::size_t kTradeNoMost = 64;
inline constexpr std::size_t kBatchNameMost = 64;
inline constexpr std::size_t kSourceMost = 16;
inline constexpr std::size_t kCodesPerCallMost = 1000;
inline constexpr std::int64_t kPerAccountLimitMost = 1000;
// Trần một lượt tiêu ingot; chặn tổng tràn và số vô lý, lớn hơn mọi hạn mức hợp lý (tối đa 2e9 mỗi ngày).
inline constexpr std::int64_t kSpendAmountMost = 1'000'000'000;
inline constexpr std::int64_t kAmountMinorMost = 10'000'000'000'000;

[[nodiscard]] Result<void> check_payment_event(const PaymentEvent& event, const Limits& limits);
// Hai ô provider và trade_no dùng để tra cứu hay hoàn.
[[nodiscard]] Result<void> check_payment_key(std::string_view provider, std::string_view trade_no);
[[nodiscard]] Result<void> check_exchange_request(const ExchangeRequest& request);
// name đã cắt gọn được ghi vào spec.
[[nodiscard]] Result<void> check_batch_spec(BatchSpec& spec, const Limits& limits);
// reason và actor đã cắt gọn được ghi vào spec.
[[nodiscard]] Result<void> check_grant_spec(GrantSpec& spec, const Limits& limits);
// 64 ký tự hex thường.
[[nodiscard]] bool hash_hex_ok(std::string_view hash) noexcept;
[[nodiscard]] Result<void> check_code_hashes(std::span<const std::string> hashes);
[[nodiscard]] Result<void> check_spend_events(std::span<const SpendEvent> events);

} // namespace game::billing
