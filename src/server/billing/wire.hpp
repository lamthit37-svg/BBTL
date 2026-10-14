#pragma once
// Tầng byte của ipc billing: số nguyên little-endian, chuỗi là u16 độ dài rồi byte UTF-8. Bộ đọc không
// bao giờ ném hay check: thiếu byte, chuỗi quá trần, số phần tử quá trần, giá trị enum lạ đều đặt cờ
// hỏng và trả 0 hoặc rỗng; nơi gọi hỏi done() một lần ở cuối. Mọi bộ nhớ cấp theo số client khai được
// kiểm trần và kiểm lượng byte còn lại trước.
//
// Bản ghi bền của billing là các cột SQL, không phải khối nhị phân, nên không có mã hoá có số phiên
// bản ở đây: dây chỉ là giao thức giữa hai tiến trình cùng một bản dựng, đổi hình thì đổi cả hai bên.

#include "billing/book.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing::wire {

class Writer {
public:
    void u8(std::uint8_t value) { bytes_.push_back(static_cast<std::byte>(value)); }
    void u16(std::uint16_t value);
    void u32(std::uint32_t value);
    void u64(std::uint64_t value);
    void i64(std::int64_t value) { u64(static_cast<std::uint64_t>(value)); }
    void flag(bool value) { u8(value ? 1U : 0U); }
    // Chuỗi dài hơn 65535 byte không biểu diễn được; nơi gọi đã kiểm trần nhỏ hơn nhiều.
    void text(std::string_view value);

    [[nodiscard]] std::vector<std::byte> take() { return std::move(bytes_); }
    [[nodiscard]] std::size_t size() const noexcept { return bytes_.size(); }

private:
    std::vector<std::byte> bytes_;
};

class Reader {
public:
    explicit Reader(std::span<const std::byte> bytes) noexcept : rest_(bytes) {}

    [[nodiscard]] std::uint8_t u8();
    [[nodiscard]] std::uint16_t u16();
    [[nodiscard]] std::uint32_t u32();
    [[nodiscard]] std::uint64_t u64();
    [[nodiscard]] std::int64_t i64() { return static_cast<std::int64_t>(u64()); }
    // 0 hoặc 1; giá trị khác làm hỏng bộ đọc.
    [[nodiscard]] bool flag();
    [[nodiscard]] std::string text(std::size_t most);
    // Số phần tử khai trước một danh sách: kiểm count <= most và count * element_min <= số byte còn lại.
    [[nodiscard]] std::size_t count(std::size_t most, std::size_t element_min);

    void fail() noexcept { ok_ = false; }
    // Đã đọc đúng hết byte và không lỗi.
    [[nodiscard]] bool done() const noexcept { return ok_ && rest_.empty(); }
    [[nodiscard]] bool ok() const noexcept { return ok_; }

private:
    std::span<const std::byte> rest_;
    bool ok_ = true;
};

// ---- cấu trúc dùng chung (ghi luôn đủ trường, đọc kiểm miền) ---------------------------------------------

void write(Writer& out, const Balance& value);
[[nodiscard]] Balance read_balance(Reader& in);

void write(Writer& out, const PaymentRecord& value);
[[nodiscard]] PaymentRecord read_payment_record(Reader& in);

void write(Writer& out, const PaymentOutcome& value);
[[nodiscard]] PaymentOutcome read_payment_outcome(Reader& in);

void write(Writer& out, const ExchangeOrder& value);
[[nodiscard]] ExchangeOrder read_exchange_order(Reader& in);

void write(Writer& out, const ExchangeOutcome& value);
[[nodiscard]] ExchangeOutcome read_exchange_outcome(Reader& in);

void write(Writer& out, const GrantRecord& value);
[[nodiscard]] GrantRecord read_grant_record(Reader& in);

void write(Writer& out, const GrantOrder& value);
[[nodiscard]] GrantOrder read_grant_order(Reader& in);

void write(Writer& out, const GrantClaimed& value);
[[nodiscard]] GrantClaimed read_grant_claimed(Reader& in);

void write(Writer& out, const GrantFinished& value);
[[nodiscard]] GrantFinished read_grant_finished(Reader& in);

void write(Writer& out, const RedeemOutcome& value);
[[nodiscard]] RedeemOutcome read_redeem_outcome(Reader& in);

void write(Writer& out, const BatchRecord& value);
[[nodiscard]] BatchRecord read_batch_record(Reader& in);

void write(Writer& out, const LedgerEntry& value);
[[nodiscard]] LedgerEntry read_ledger_entry(Reader& in);

void write(Writer& out, const Conservation& value);
[[nodiscard]] Conservation read_conservation(Reader& in);

void write(Writer& out, const DayReport& value);
[[nodiscard]] DayReport read_day_report(Reader& in);

// Mốc tuỳ chọn: -1 là "không có".
void write_optional_time(Writer& out, const std::optional<UnixTime>& value);
[[nodiscard]] std::optional<UnixTime> read_optional_time(Reader& in);

} // namespace game::billing::wire
