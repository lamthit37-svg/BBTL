// Phần không phụ thuộc nền của game::net: câu mô tả lỗi và đọc Endpoint từ chữ.
// Nguồn: TLBB Dev src/platform/socket.cpp (describe).
// Khác gốc: tên lỗi kCamelCase; parse_endpoint mới, thay việc truyền host và cổng rời rồi gọi
// getaddrinfo của Dev.

#include "net/net.hpp"

#include "net/detail/native.hpp"

#include <algorithm>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>
#include <system_error>

namespace game::net {
namespace {

constexpr std::size_t kMaxPortDigits = 5;
constexpr unsigned kMaxPort = 65535;

[[nodiscard]] bool all_digits(std::string_view text) noexcept {
    return std::ranges::all_of(text, [](char letter) { return letter >= '0' && letter <= '9'; });
}

// Cổng 1 tới 5 chữ số thập phân, không dấu, không khoảng trắng.
[[nodiscard]] std::optional<std::uint16_t> parse_port(std::string_view text) noexcept {
    if (text.empty() || text.size() > kMaxPortDigits || !all_digits(text)) return std::nullopt;
    unsigned value = 0;
    const char* begin = text.data();
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars (lệch STD-08)
    const char* end = begin + text.size();
    const auto result = std::from_chars(begin, end, value);
    if (result.ec != std::errc{} || result.ptr != end || value > kMaxPort) return std::nullopt;
    return static_cast<std::uint16_t>(value);
}

// Chép host vào mảng có '\0' cho inet_pton; nullopt khi rỗng, quá dài hay có '\0' giữa chừng.
[[nodiscard]] std::optional<detail::HostText> terminated(std::string_view host) noexcept {
    detail::HostText text{};
    if (host.empty() || host.size() >= text.size()) return std::nullopt;
    if (host.contains('\0')) return std::nullopt;
    std::ranges::copy(host, text.begin());
    return text;
}

} // namespace

std::string_view describe(NetError error) noexcept {
    switch (error) {
    case NetError::kStartup: return "không khởi động được thư viện mạng";
    case NetError::kAddress: return "địa chỉ không hợp lệ";
    case NetError::kSocket: return "không tạo hay cấu hình được socket";
    case NetError::kBind: return "không gắn được cổng";
    case NetError::kListen: return "không nghe được trên cổng";
    case NetError::kAccept: return "không nhận được kết nối";
    case NetError::kConnect: return "không kết nối được";
    case NetError::kClosed: return "bên kia đã đóng kết nối";
    case NetError::kReset: return "kết nối bị đứt";
    case NetError::kPoll: return "lỗi khi chờ socket";
    }
    return "lỗi mạng không rõ";
}

NetResult<Endpoint> parse_endpoint(std::string_view text, ZeroPort zero) noexcept {
    const auto colon = text.rfind(':');
    if (colon == std::string_view::npos) return std::unexpected(NetError::kAddress);
    const auto port = parse_port(text.substr(colon + 1));
    if (!port || (*port == 0 && zero == ZeroPort::kRefuse)) {
        return std::unexpected(NetError::kAddress);
    }
    const auto host = terminated(text.substr(0, colon));
    const auto address = host ? detail::parse_ipv4(*host) : std::nullopt;
    if (!address) return std::unexpected(NetError::kAddress);
    return Endpoint{.address = *address, .port = *port};
}

} // namespace game::net
