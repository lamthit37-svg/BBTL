#include "billing/error.hpp"

#include <array>
#include <cstdint>
#include <string_view>

namespace game::billing {
namespace {

struct Entry {
    Error error;
    std::string_view text;
};

constexpr std::array kEntries{
    Entry{.error = Error::kMalformed, .text = "yêu cầu hỏng"},
    Entry{.error = Error::kRateLimited, .text = "quá nhiều lần thử"},
    Entry{.error = Error::kBusy, .text = "billing bận hoặc database lỗi"},
    Entry{.error = Error::kBadAmount, .text = "số lượng ngoài miền"},
    Entry{.error = Error::kInsufficient, .text = "không đủ điểm"},
    Entry{.error = Error::kFrozen, .text = "tài khoản đang bị đóng băng"},
    Entry{.error = Error::kNotFound, .text = "không tìm thấy"},
    Entry{.error = Error::kConflict, .text = "nội dung lệch với bản đã ghi"},
    Entry{.error = Error::kBadState, .text = "trạng thái không cho phép bước này"},
    Entry{.error = Error::kBadCode, .text = "mã không đúng"},
    Entry{.error = Error::kCodeUsed, .text = "mã đã dùng"},
    Entry{.error = Error::kCodeNotYet, .text = "mã chưa tới hạn dùng"},
    Entry{.error = Error::kCodeExpired, .text = "mã đã hết hạn"},
    Entry{.error = Error::kCodeDisabled, .text = "đợt mã đã tắt"},
    Entry{.error = Error::kLimitReached, .text = "đã đủ số lần đổi của đợt này"},
    Entry{.error = Error::kReasonRequired, .text = "thiếu lý do hoặc người làm"},
    Entry{.error = Error::kTooMany, .text = "quá nhiều phần tử"},
    Entry{.error = Error::kBadSignature, .text = "chữ ký sai"},
    Entry{.error = Error::kStaleTimestamp, .text = "mốc thời gian lệch quá hạn"},
    Entry{.error = Error::kUnknownProvider, .text = "nhà cung cấp lạ"},
};

} // namespace

std::string_view describe(Error error) noexcept {
    for (const Entry& entry : kEntries) {
        if (entry.error == error) return entry.text;
    }
    return "lỗi không rõ";
}

Error error_of(std::uint16_t code) noexcept {
    for (const Entry& entry : kEntries) {
        if (wire_code(entry.error) == code) return entry.error;
    }
    return Error::kBusy;
}

} // namespace game::billing
