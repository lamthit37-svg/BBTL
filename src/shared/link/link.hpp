// Phía client của một kết nối cổng: TCP không chặn, bắt tay ghim khoá máy chủ, rồi khung đã niêm.
// Gate là phía kia. Engine không biết protocol; lớp này nằm ở shared vì cả client và công cụ thử đều gọi.
#pragma once

#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"

#include <chrono>
#include <cstdint>
#include <expected>
#include <span>
#include <vector>

namespace game::link {

enum class [[nodiscard]] LinkError : std::uint8_t {
    kNetwork = 1,
    kSecure,
    kProtocol,
    kTimeout,
};

[[nodiscard]] std::string_view describe(LinkError error) noexcept;

template <typename T>
using LinkResult = std::expected<T, LinkError>;

// Một phiên đã bắt tay và đã nhận Welcome. Hết hạn là giờ tường vì đây là I/O, không phải luật game.
class Link {
public:
    struct HelloDesc {
        net::Endpoint peer{};
        secure::PublicKey server{};
        std::uint32_t build = 0;
        protocol::Platform platform = protocol::Platform::kWindows;
        net::Milliseconds timeout{3000};
    };

    [[nodiscard]] static LinkResult<Link> open(const HelloDesc& desc);
    ~Link();
    Link(const Link&) = delete;
    Link& operator=(const Link&) = delete;
    Link(Link&& other) noexcept;
    Link& operator=(Link&& other) noexcept;

    [[nodiscard]] const protocol::Welcome& welcome() const noexcept { return welcome_; }

    [[nodiscard]] LinkResult<protocol::Pong> ping(std::chrono::milliseconds client_time, net::Milliseconds timeout);

    // Gửi một khung đã mã hoá (protocol::encode). Hết hạn hay mạng hỏng thì lỗi; Link không dùng được nữa.
    [[nodiscard]] LinkResult<void> send_frame(std::span<const std::byte> frame, net::Milliseconds timeout);
    // Chờ một bản ghi từ server: một khung đầy đủ. Hết hạn là LinkError::kTimeout và Link vẫn dùng được
    // (chưa mất byte nào); lỗi khác thì phải đóng.
    [[nodiscard]] LinkResult<std::vector<std::byte>> receive_frame(net::Milliseconds timeout);

private:
    Link(net::TcpStream stream, secure::RecordPipe pipe, protocol::Welcome welcome);

    net::TcpStream stream_;
    secure::RecordPipe pipe_;
    protocol::Welcome welcome_{};
    // Byte đã nhận mà chưa mở thành bản ghi: một lần đọc có thể mang nhiều bản ghi.
    std::vector<std::byte> inbox_;
};

} // namespace game::link
