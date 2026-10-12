#pragma once
// Một lần chờ cho nhiều kết nối. Trên Windows là cổng hoàn thành: GetQueuedCompletionStatusEx
// trả đúng các socket vừa xong, AcceptEx nhận sẵn, WSASend chồng bản sao tối đa 2 KiB.
// PollSet quét mọi socket (WSAPoll). Seastar gộp hoàn thành ở epoll/io_uring; GNS gom poll group.
// Một luồng gọi wait/watch/submit. wake() được gọi từ luồng khác và chỉ đăng một gói đánh thức.
// Hợp đồng socket giống PollSet: reactor không sở hữu socket dữ liệu; gỡ nhãn trước khi đóng.

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
    // Sao tối đa 2 KiB rồi gửi chồng. POSIX gửi ngay trên socket không chặn.
    [[nodiscard]] SendOutcome submit_send(std::uint64_t tag, std::span<const std::byte> data) noexcept;
    [[nodiscard]] NetResult<void> wait(Milliseconds limit, PollEvents& events);
    // Luồng khác. Đánh thức wait đang ngủ; nhiều lần gộp thành một gói.
    void wake() noexcept;
    [[nodiscard]] std::size_t size() const noexcept;

private:
    [[nodiscard]] ReactorNative& state() const noexcept;

    std::unique_ptr<ReactorNative> native_;
};

} // namespace game::net
