#pragma once
// Phần chung giữa net.cpp và hai tệp nền: đổi Ipv4 với số 32 bit, đọc chuỗi IPv4 bằng inet_pton.
// Không include header mạng của hệ điều hành.
// Nguồn: không có ở Dev (Dev đọc địa chỉ ngay trong từng tệp nền bằng getaddrinfo).

#include "net/net.hpp"

#include <array>
#include <cstdint>
#include <optional>

namespace game::net::detail {

// Chuỗi host dài nhất của IPv4 là "255.255.255.255": 15 ký tự, thêm '\0'.
using HostText = std::array<char, 16>;

// Ipv4 ra số theo thứ tự máy (byte đầu là byte cao), đưa qua htonl trước khi vào sockaddr_in.
[[nodiscard]] constexpr std::uint32_t pack(const Ipv4& address) noexcept {
    std::uint32_t value = 0;
    for (const std::uint8_t part : address)
        value = (value << 8U) | part;
    return value;
}

// Ngược của pack: số theo thứ tự máy (sau ntohl) ra Ipv4.
[[nodiscard]] constexpr Ipv4 unpack(std::uint32_t value) noexcept {
    return Ipv4{static_cast<std::uint8_t>(value >> 24U), static_cast<std::uint8_t>(value >> 16U),
        static_cast<std::uint8_t>(value >> 8U), static_cast<std::uint8_t>(value)};
}

// Đọc host IPv4 dạng chấm bằng inet_pton; text kết thúc bằng '\0'. nullopt khi không phải IPv4.
// Định nghĩa ở socket_win32.cpp hoặc socket_posix.cpp.
[[nodiscard]] std::optional<Ipv4> parse_ipv4(const HostText& text) noexcept;

} // namespace game::net::detail
