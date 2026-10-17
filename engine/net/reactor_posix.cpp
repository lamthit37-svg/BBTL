/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/reactor_posix.cpp
 *  PHÂN HỆ   : Net / Reactor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Reactor trên Apple: cùng hợp đồng với IOCP và epoll, phía dưới là poll.
 *    Linux và Android dùng reactor_epoll.cpp.
 *  - Đánh thức từ luồng khác bằng một pipe không chặn, gộp nhiều lần thành một
 *    byte. UDP lấy bằng recvfrom khi take_udp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/reactor.hpp"

#include "core/check.hpp"
#include "net/detail/native.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cerrno>
#include <cstddef>
#include <cstdint>
#include <span>
#include <unordered_map>
#include <utility>

#include <fcntl.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

namespace game::net {
namespace {

constexpr std::uint64_t kWakeTag = std::uint64_t{1} << 63U;
constexpr int kClosedFd = -1;

[[nodiscard]] int fd_of(SocketHandle handle) noexcept {
    return static_cast<int>(static_cast<std::intptr_t>(handle));
}

[[nodiscard]] bool set_nonblocking(int fd) noexcept {
    const int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return false;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

void drain_fd(int fd) noexcept {
    std::array<char, 32> sink{};
    for (;;) {
        const ssize_t got = ::read(fd, sink.data(), sink.size());
        if (got < 0) return;
        if (got < static_cast<ssize_t>(sink.size())) return;
    }
}

} // namespace

struct ReactorNative {
    PollSet poll;
    std::unordered_map<std::uint64_t, SocketHandle> sockets;
    std::unordered_map<std::uint64_t, TcpListener*> listeners;
    std::unordered_map<std::uint64_t, bool> datagrams;
    int wake_read = kClosedFd;
    int wake_write = kClosedFd;
    std::atomic<std::uint32_t> wake_flag{0};

    ReactorNative() {
        int ends[2] = {kClosedFd, kClosedFd};
        core::check(pipe(ends) == 0, "không tạo được pipe đánh thức");
        wake_read = ends[0];
        wake_write = ends[1];
        core::check(set_nonblocking(wake_read) && set_nonblocking(wake_write),
            "pipe không chuyển được sang không chặn");
        core::check(poll.add(static_cast<SocketHandle>(static_cast<std::uintptr_t>(wake_read)), kWakeTag),
            "không gắn được pipe vào tập chờ");
    }

    ReactorNative(const ReactorNative&) = delete;
    ReactorNative& operator=(const ReactorNative&) = delete;
    ~ReactorNative() {
        if (wake_read != kClosedFd) close(wake_read);
        if (wake_write != kClosedFd) close(wake_write);
    }
};

namespace {

// Xoá cờ TRƯỚC khi rút pipe: wake() tới sau lúc xoá ghi thêm một byte, lần wait sau thức ngay. Thứ tự ngược lại
// (rút rồi mới xoá) làm mất lần wake() rơi vào giữa hai bước: nó thấy cờ còn 1 nên không ghi, rồi cờ bị xoá.
void consume_wake(ReactorNative& native) noexcept {
    native.wake_flag.store(0, std::memory_order_release);
    drain_fd(native.wake_read);
}

} // namespace

Reactor::Reactor() : native_(std::make_unique<ReactorNative>()) {}

Reactor::~Reactor() = default;

Reactor::Reactor(Reactor&&) noexcept = default;

Reactor& Reactor::operator=(Reactor&&) noexcept = default;

ReactorNative& Reactor::state() const noexcept {
    core::check(native_ != nullptr, "Reactor đã bị chuyển đi");
    return *native_;
}

bool Reactor::watch(SocketHandle socket, std::uint64_t tag) {
    if (socket == kNoSocket || tag == kWakeTag) return false;
    ReactorNative& native = state();
    if (native.sockets.contains(tag)) return false;
    if (!native.poll.add(socket, tag)) return false;
    native.sockets.emplace(tag, socket);
    return true;
}

void Reactor::unwatch(std::uint64_t tag) {
    if (tag == kWakeTag) return;
    ReactorNative& native = state();
    native.poll.remove(tag);
    native.sockets.erase(tag);
    native.listeners.erase(tag);
    native.datagrams.erase(tag);
}

void Reactor::want_write(std::uint64_t tag, bool wanted) {
    if (tag == kWakeTag) return;
    state().poll.want_write(tag, wanted);
}

void Reactor::note_read(std::uint64_t tag, std::size_t got) {
    static_cast<void>(tag);
    static_cast<void>(got);
}

bool Reactor::watch_listener(TcpListener& listener, std::uint64_t tag) {
    if (tag == kWakeTag) return false;
    ReactorNative& native = state();
    if (!watch(listener.handle(), tag)) return false;
    native.listeners.emplace(tag, &listener);
    return true;
}

NetResult<std::optional<Accepted>> Reactor::take_accept(std::uint64_t tag) {
    ReactorNative& native = state();
    const auto found = native.listeners.find(tag);
    if (found == native.listeners.end() || found->second == nullptr) return std::optional<Accepted>{};
    return found->second->accept();
}

SendOutcome Reactor::submit_send(std::uint64_t tag, std::span<const std::byte> data) noexcept {
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    if (found == native.sockets.end()) return SendOutcome{.state = SendState::kReset};
    if (data.empty()) return SendOutcome{.state = SendState::kDone};
    const int fd = fd_of(found->second);
    const auto count = static_cast<size_t>(std::min(data.size(), std::size_t{1} << 20U));
#ifdef MSG_NOSIGNAL
    constexpr int kFlags = MSG_NOSIGNAL;
#else
    constexpr int kFlags = 0;
#endif
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng send
    const auto* bytes = reinterpret_cast<const char*>(data.data());
    const ssize_t sent = ::send(fd, bytes, count, kFlags);
    if (sent > 0) {
        // Gửi thiếu thì phải chờ writable: bên gọi có thể dừng vòng gửi trước khi gặp EAGAIN.
        native.poll.want_write(tag, static_cast<std::size_t>(sent) < data.size());
        return SendOutcome{.state = SendState::kDone, .sent = static_cast<std::size_t>(sent)};
    }
    if (sent < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        native.poll.want_write(tag, true);
        return SendOutcome{.state = SendState::kPending};
    }
    return SendOutcome{.state = SendState::kReset};
}

bool Reactor::watch_udp(UdpSocket& socket, std::uint64_t tag) {
    if (!socket.is_open() || !watch(socket.handle(), tag)) return false;
    state().datagrams.emplace(tag, true);
    return true;
}

ssize_t read_udp(int fd, std::span<std::byte> buf, sockaddr_in& peer, int flags) noexcept {
    socklen_t size = static_cast<socklen_t>(sizeof(peer));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng recvfrom
    sockaddr* address = reinterpret_cast<sockaddr*>(&peer);
    return ::recvfrom(fd, buf.data(), buf.size(), flags, address, &size);
}

UdpSocket::UdpRead pull_udp(int fd, std::span<std::byte> sink) noexcept {
    std::byte scratch{};
    std::span<std::byte> buf = sink;
    if (sink.empty()) buf = std::span<std::byte>{&scratch, 1};
    sockaddr_in peer{};
#ifdef MSG_TRUNC
    constexpr int kFlags = MSG_TRUNC;
#else
    constexpr int kFlags = 0;
#endif
    const ssize_t got = read_udp(fd, buf, peer, kFlags);
    if (got < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return std::optional<UdpInbound>{};
    if (got < 0) return std::unexpected(NetError::kReset);
    UdpInbound inbound;
    const auto host = static_cast<std::uint32_t>(ntohl(peer.sin_addr.s_addr));
    inbound.from.address = detail::unpack(host);
    inbound.from.port = ntohs(peer.sin_port);
    if (static_cast<std::size_t>(got) > sink.size()) inbound.truncated = true;
    if (!inbound.truncated) inbound.size = static_cast<std::size_t>(got);
    return inbound;
}

UdpSocket::UdpRead Reactor::take_udp(std::uint64_t tag, std::span<std::byte> sink) {
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    const bool missing = found == native.sockets.end() || !native.datagrams.contains(tag);
    if (missing) return std::unexpected(NetError::kReset);
    return pull_udp(fd_of(found->second), sink);
}

NetResult<void> Reactor::wait(Milliseconds limit, PollEvents& events) {
    ReactorNative& native = state();
    const NetResult<void> waited = native.poll.wait(limit, events);
    if (!waited) return waited;
    bool woke = false;
    std::size_t keep = 0;
    for (const PollEvent& event : events) {
        if (event.tag == kWakeTag) {
            woke = true;
            continue;
        }
        events[keep] = event;
        ++keep;
    }
    events.resize(keep);
    if (woke) consume_wake(native);
    return {};
}

void Reactor::wake() noexcept {
    ReactorNative& native = state();
    const std::uint32_t previous = native.wake_flag.exchange(1, std::memory_order_acq_rel);
    if (previous != 0 || native.wake_write == kClosedFd) return;
    const char byte = 1;
    const ssize_t wrote = ::write(native.wake_write, &byte, 1);
    if (wrote >= 0 || errno == EAGAIN) return;
    native.wake_flag.store(0, std::memory_order_release);
}

std::size_t Reactor::size() const noexcept {
    const std::size_t all = state().poll.size();
    if (all == 0) return 0;
    return all - 1;
}

} // namespace game::net
