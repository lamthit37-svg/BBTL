/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/reactor_epoll.cpp
 *  PHÂN HỆ   : Net / Reactor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Reactor Linux và Android: epoll mức level, một lần chờ không quét cả tập.
 *    Đánh thức bằng eventfd, nhiều lần gộp thành một lần ghi.
 *  - UDP không nuốt datagram ở vòng chờ. take_udp gọi recvfrom.
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

#include <netinet/in.h>
#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/socket.h>
#include <unistd.h>

namespace game::net {
namespace {

constexpr std::uint64_t kWakeTag = std::uint64_t{1} << 63U;
constexpr int kClosedFd = -1;
constexpr int kBatch = 256;

struct Interest {
    int fd = kClosedFd;
    bool write = false;
    bool datagram = false;
    TcpListener* listener = nullptr;
};

[[nodiscard]] int fd_of(SocketHandle handle) noexcept {
    return static_cast<int>(static_cast<std::intptr_t>(handle));
}

[[nodiscard]] std::uint32_t mask_of(bool write) noexcept {
    std::uint32_t mask = EPOLLIN | EPOLLRDHUP;
    if (write) mask |= EPOLLOUT;
    return mask;
}

[[nodiscard]] int clamp_ms(Milliseconds limit) noexcept {
    const auto count = limit.count();
    if (count <= 0) return 0;
    if (count > 86'400'000) return 86'400'000;
    return static_cast<int>(count);
}

[[nodiscard]] bool arm(int ep, int op, int fd, std::uint32_t mask, std::uint64_t tag) noexcept {
    epoll_event event{};
    event.events = mask;
    event.data.u64 = tag;
    return epoll_ctl(ep, op, fd, &event) == 0;
}

void drain_fd(int fd) noexcept {
    std::uint64_t value = 0;
    const ssize_t got = ::read(fd, &value, sizeof(value));
    static_cast<void>(got);
}

ssize_t read_udp(int fd, std::span<std::byte> buf, sockaddr_in& peer, int flags) noexcept {
    socklen_t size = static_cast<socklen_t>(sizeof(peer));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng recvfrom
    sockaddr* address = reinterpret_cast<sockaddr*>(&peer);
    return ::recvfrom(fd, buf.data(), buf.size(), flags, address, &size);
}

} // namespace

struct ReactorNative {
    int ep = kClosedFd;
    int wake = kClosedFd;
    std::unordered_map<std::uint64_t, Interest> sockets;
    std::atomic<std::uint32_t> wake_flag{0};

    ReactorNative() {
        ep = epoll_create1(EPOLL_CLOEXEC);
        wake = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
        core::check(ep >= 0 && wake >= 0, "không tạo được epoll");
        core::check(arm(ep, EPOLL_CTL_ADD, wake, EPOLLIN, kWakeTag), "không gắn được eventfd");
    }

    ReactorNative(const ReactorNative&) = delete;
    ReactorNative& operator=(const ReactorNative&) = delete;
    ~ReactorNative() {
        if (wake != kClosedFd) close(wake);
        if (ep != kClosedFd) close(ep);
    }
};

namespace {

// Xoá cờ trước khi đọc eventfd, cùng lý do pipe của bản Apple: wake() chen giữa không bị nuốt.
void consume_wake(ReactorNative& native) noexcept {
    native.wake_flag.store(0, std::memory_order_release);
    drain_fd(native.wake);
}

void collect(PollEvents& events, const epoll_event& ready, bool& woke) {
    if (ready.data.u64 == kWakeTag) {
        woke = true;
        return;
    }
    PollEvent event;
    event.tag = ready.data.u64;
    const std::uint32_t flags = ready.events;
    event.readable = (flags & (EPOLLIN | EPOLLRDHUP | EPOLLHUP)) != 0;
    event.writable = (flags & EPOLLOUT) != 0;
    event.failed = (flags & EPOLLERR) != 0;
    const bool any = event.readable || event.writable || event.failed;
    if (any) events.push_back(event);
}

epoll_event& at_ready(std::array<epoll_event, kBatch>& batch, int index) noexcept {
    return batch[static_cast<std::size_t>(index)];
}

void feed(PollEvents& events, const epoll_event& ready, bool& woke) {
    collect(events, ready, woke);
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
    const int fd = fd_of(socket);
    if (!arm(native.ep, EPOLL_CTL_ADD, fd, mask_of(false), tag)) return false;
    Interest interest;
    interest.fd = fd;
    native.sockets.emplace(tag, interest);
    return true;
}

void Reactor::unwatch(std::uint64_t tag) {
    if (tag == kWakeTag) return;
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    if (found == native.sockets.end()) return;
    epoll_event gone{};
    static_cast<void>(epoll_ctl(native.ep, EPOLL_CTL_DEL, found->second.fd, &gone));
    native.sockets.erase(found);
}

void Reactor::want_write(std::uint64_t tag, bool wanted) {
    if (tag == kWakeTag) return;
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    if (found == native.sockets.end()) return;
    Interest& interest = found->second;
    if (interest.write == wanted) return;
    interest.write = wanted;
    static_cast<void>(arm(native.ep, EPOLL_CTL_MOD, interest.fd, mask_of(wanted), tag));
}

void Reactor::note_read(std::uint64_t tag, std::size_t got) {
    static_cast<void>(tag);
    static_cast<void>(got);
}

bool Reactor::watch_listener(TcpListener& listener, std::uint64_t tag) {
    if (!watch(listener.handle(), tag)) return false;
    TcpListener* saved = &listener;
    state().sockets.find(tag)->second.listener = saved;
    return true;
}

NetResult<std::optional<Accepted>> Reactor::take_accept(std::uint64_t tag) {
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    if (found == native.sockets.end()) return std::optional<Accepted>{};
    if (found->second.listener == nullptr) return std::optional<Accepted>{};
    return found->second.listener->accept();
}

SendOutcome Reactor::submit_send(std::uint64_t tag, std::span<const std::byte> data) noexcept {
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    if (found == native.sockets.end()) return SendOutcome{.state = SendState::kReset};
    if (data.empty()) return SendOutcome{.state = SendState::kDone};
    const int fd = found->second.fd;
    const auto count = std::min(data.size(), std::size_t{1} << 20U);
#ifdef MSG_NOSIGNAL
    constexpr int kFlags = MSG_NOSIGNAL;
#else
    constexpr int kFlags = 0;
#endif
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng send
    const auto* bytes = reinterpret_cast<const char*>(data.data());
    const ssize_t sent = ::send(fd, bytes, count, kFlags);
    if (sent > 0) {
        want_write(tag, static_cast<std::size_t>(sent) < data.size());
        return SendOutcome{.state = SendState::kDone, .sent = static_cast<std::size_t>(sent)};
    }
    if (sent < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        want_write(tag, true);
        return SendOutcome{.state = SendState::kPending};
    }
    return SendOutcome{.state = SendState::kReset};
}

bool Reactor::watch_udp(UdpSocket& socket, std::uint64_t tag) {
    if (!socket.is_open() || !watch(socket.handle(), tag)) return false;
    state().sockets.find(tag)->second.datagram = true;
    return true;
}

UdpSocket::UdpRead Reactor::take_udp(std::uint64_t tag, std::span<std::byte> sink) {
    ReactorNative& native = state();
    const auto found = native.sockets.find(tag);
    const bool missing = found == native.sockets.end() || !found->second.datagram;
    if (missing) return std::unexpected(NetError::kReset);
    std::byte scratch{};
    std::span<std::byte> buf = sink;
    if (sink.empty()) buf = std::span<std::byte>{&scratch, 1};
    sockaddr_in peer{};
#ifdef MSG_TRUNC
    constexpr int kFlags = MSG_TRUNC;
#else
    constexpr int kFlags = 0;
#endif
    const ssize_t got = read_udp(found->second.fd, buf, peer, kFlags);
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

NetResult<void> Reactor::wait(Milliseconds limit, PollEvents& events) {
    ReactorNative& native = state();
    events.clear();
    std::array<epoll_event, kBatch> batch{};
    const int ready = epoll_wait(native.ep, batch.data(), kBatch, clamp_ms(limit));
    if (ready < 0 && errno == EINTR) return {};
    if (ready < 0) return std::unexpected(NetError::kPoll);
    bool woke = false;
    for (int index = 0; index < ready; ++index)
        feed(events, at_ready(batch, index), woke);
    if (woke) consume_wake(native);
    return {};
}

void Reactor::wake() noexcept {
    ReactorNative& native = state();
    const std::uint32_t previous = native.wake_flag.exchange(1, std::memory_order_acq_rel);
    if (previous != 0 || native.wake == kClosedFd) return;
    const std::uint64_t one = 1;
    const ssize_t wrote = ::write(native.wake, &one, sizeof(one));
    if (wrote >= 0 || errno == EAGAIN) return;
    native.wake_flag.store(0, std::memory_order_release);
}

std::size_t Reactor::size() const noexcept {
    return state().sockets.size();
}

} // namespace game::net
