#pragma once
// Bộ phân tích HTTP/1.1 tối thiểu cho webhook của nhà cung cấp thanh toán. Vì sao tự viết thay vì dùng
// thư viện: client 2026 không gọi HTTP (nó nói giao thức game qua gate), nên HTTP chỉ có một người gọi
// là nhà cung cấp, sau reverse proxy có TLS, và chỉ cần đúng một hình dạng yêu cầu: POST với thân
// application/x-www-form-urlencoded có chữ ký. Bộ phân tích từ chối mọi thứ khác thay vì cố hiểu:
// không chunked, không Expect, không nối tiếp nhiều yêu cầu, không thân dài hơn 4 KiB, không xuống dòng
// trần (chỉ CRLF), không byte ngoài ASCII in được trong đầu yêu cầu. Chống smuggling và chống ăn bộ nhớ
// là mục tiêu thiết kế, tốc độ thì không.
//
// Thuần: nhận byte đã gom, không socket, không đồng hồ.
//
// Hợp đồng: parse() chạy O(độ dài data) và nhìn tối đa kHeadMost + kBodyMost + 4 byte đầu; nơi gọi cắt
// bộ đệm ở trần đó.

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::billing::http {

inline constexpr std::size_t kHeadMost = 4096;
inline constexpr std::size_t kBodyMost = 4096;
inline constexpr std::size_t kHeaderCountMost = 32;
inline constexpr std::size_t kTargetMost = 128;
inline constexpr std::size_t kHeaderValueMost = 256;
// Đầu + thân + dòng trống: trần số byte nơi gọi cần giữ cho một yêu cầu.
inline constexpr std::size_t kRequestMost = kHeadMost + 4 + kBodyMost;

enum class Status : std::uint16_t {
    kOk = 200,
    kBadRequest = 400,
    kUnauthorized = 401,
    kNotFound = 404,
    kMethodNotAllowed = 405,
    kTimeout = 408,
    kConflict = 409,
    kLengthRequired = 411,
    kTooLarge = 413,
    kUnprocessable = 422,
    kHeaderTooLarge = 431,
    kNotImplemented = 501,
    kUnavailable = 503,
};

struct Request {
    // Đường dẫn, đã kiểm bộ ký tự; không có query.
    std::string path;
    // Giá trị X-Timestamp, giây Unix.
    std::int64_t timestamp = 0;
    // Giá trị X-Signature: 64 ký tự hex thường.
    std::string signature;
    std::string body;
};

struct Parsed {
    enum class State : std::uint8_t { kNeedMore, kDone, kReject };
    State state = State::kNeedMore;
    Status reject = Status::kBadRequest;
    Request request;
    // Số byte của data thuộc yêu cầu (đầu + thân).
    std::size_t consumed = 0;
};

[[nodiscard]] Parsed parse(std::string_view data);

// Cụm trả lời đầy đủ với Connection: close.
[[nodiscard]] std::string respond(Status status, std::string_view body);

[[nodiscard]] std::string_view reason_of(Status status) noexcept;

// Cặp khoá-giá trị của thân form. nullopt khi: dư 16 cặp, khoá ngoài [a-z_] 1..24 ký tự, khoá lặp, '%'
// không kèm hai chữ hex, giá trị giải mã quá 128 byte hay có byte điều khiển.
using FormFields = std::vector<std::pair<std::string, std::string>>;
[[nodiscard]] std::optional<FormFields> parse_form(std::string_view body);

} // namespace game::billing::http
