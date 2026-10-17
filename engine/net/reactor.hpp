/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/reactor.hpp
 *  PHÂN HỆ   : Net / Reactor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Một lần chờ cho nhiều socket. Windows: IOCP, AcceptEx, WSASend tới 8 KiB.
 *    Linux và Android: epoll. Apple: poll. Không quét cả tập mỗi vòng.
 *  - UDP đăng bằng watch_udp, lấy bằng take_udp. Một luồng gọi wait; wake()
 *    từ luồng khác. Reactor không sở hữu socket; gỡ nhãn trước khi đóng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "net/net.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>

namespace game::net {

enum class SendState : std::uint8_t {
    kDone,
    // Kernel chưa nhận hết. Lần wait sau báo PollEvent::sent, hoặc POSIX báo writable.
    kPending,
    kReset,
};

struct SendOutcome {
    SendState state = SendState::kPending;
    std::size_t sent = 0;
};

struct ReactorNative;

class Reactor {
public:
    Reactor();
    ~Reactor();
    Reactor(Reactor&& other) noexcept;
    Reactor& operator=(Reactor&& other) noexcept;
    Reactor(const Reactor&) = delete;
    Reactor& operator=(const Reactor&) = delete;

    // Theo dõi đọc. false khi nhãn đã có, socket rỗng, hoặc không gắn được vào cổng.
    [[nodiscard]] bool watch(SocketHandle socket, std::uint64_t tag);
    void unwatch(std::uint64_t tag);
    // POSIX: bật thì lần wait sau có thể báo writable. Windows: gửi đi qua submit_send.
    void want_write(std::uint64_t tag, bool wanted);
    // Sau receive: got == 0 thì đăng ký đọc lại; got > 0 và còn byte thì lần wait sau trả ngay.
    void note_read(std::uint64_t tag, std::size_t got);
    // Nghe bằng AcceptEx (Windows) hoặc poll (POSIX). Listener phải sống lâu hơn nhãn.
    [[nodiscard]] bool watch_listener(TcpListener& listener, std::uint64_t tag);
    [[nodiscard]] NetResult<std::optional<Accepted>> take_accept(std::uint64_t tag);
    // Sao tối đa 8 KiB rồi gửi chồng. POSIX gửi ngay trên socket không chặn.
    [[nodiscard]] SendOutcome submit_send(std::uint64_t tag,
        std::span<const std::byte> data) noexcept;
    // Đăng nhận datagram. false khi nhãn đã có hoặc không gắn được vào cổng.
    [[nodiscard]] bool watch_udp(UdpSocket& socket, std::uint64_t tag);
    // Một datagram đã sẵn. nullopt khi chưa có. Gói dài hơn sink thì truncated.
    using UdpRead = UdpSocket::UdpRead;
    [[nodiscard]] UdpRead take_udp(std::uint64_t tag, std::span<std::byte> sink);
    [[nodiscard]] NetResult<void> wait(Milliseconds limit, PollEvents& events);
    // Luồng khác. Đánh thức wait đang ngủ; nhiều lần gộp thành một gói.
    void wake() noexcept;
    [[nodiscard]] std::size_t size() const noexcept;

private:
    [[nodiscard]] ReactorNative& state() const noexcept;

    std::unique_ptr<ReactorNative> native_;
};

} // namespace game::net
