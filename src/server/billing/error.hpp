#pragma once
// Mã lỗi của billing. Mã trả qua ipc là chính giá trị số này (0 là thành công). kRateLimited và
// kBusy trùng số với protocol::ErrorCode cùng tên vì khung ipc dùng chung (account::serve_loop) tự
// trả kBusy khi hàng việc đầy; serve.cpp có static_assert giữ hai bên khớp.

#include <cstdint>
#include <expected>
#include <string_view>

namespace game::billing {

enum class [[nodiscard]] Error : std::uint8_t {
    // Thân yêu cầu hỏng: sai độ dài, id hay số ngoài miền, chữ không đúng bộ ký tự.
    kMalformed = 1,
    kRateLimited = 12,
    // Database hoặc hàng việc bận, hoặc lỗi không phân loại được. Gọi lại được vì mọi thao tác ghi
    // đều có khoá lặp lại (request_id, trade_no, order_id).
    kBusy = 16,
    kBadAmount = 101,
    kInsufficient = 102,
    kFrozen = 103,
    kNotFound = 104,
    // Gọi lại với nội dung khác bản đã ghi, hoặc báo kết quả ngược với kết quả đã chốt.
    kConflict = 105,
    kBadState = 106,
    kBadCode = 107,
    kCodeUsed = 108,
    kCodeNotYet = 109,
    kCodeExpired = 110,
    kCodeDisabled = 111,
    kLimitReached = 112,
    kReasonRequired = 113,
    kTooMany = 114,
    kBadSignature = 120,
    kStaleTimestamp = 121,
    kUnknownProvider = 122,
};

template <typename T>
using Result = std::expected<T, Error>;

// Câu tiếng Việt cho log. Không chứa dữ liệu của người chơi.
[[nodiscard]] std::string_view describe(Error error) noexcept;

// Mã số trên dây của một lỗi.
[[nodiscard]] constexpr std::uint16_t wire_code(Error error) noexcept {
    return static_cast<std::uint16_t>(error);
}

// Đọc mã từ dây; mã lạ thành kBusy (bên kia nói một thứ mình không hiểu thì coi như chưa xong).
[[nodiscard]] Error error_of(std::uint16_t code) noexcept;

} // namespace game::billing
