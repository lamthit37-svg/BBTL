/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/socket_posix.cpp
 *  PHÂN HỆ   : Net / Socket
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài net.hpp trên POSIX (Linux, Android, macOS, iOS); header mạng POSIX chỉ
 *    có ở tệp này. Nguồn: TLBB Dev src/platform/socket_posix.cpp.
 *  - Khác gốc giống bản Win32; thêm FD_CLOEXEC (tiến trình con không giữ cổng
 *    của cha), Apple chặn SIGPIPE bằng SO_NOSIGPIPE vì thiếu MSG_NOSIGNAL.
 *  - Khôi phục 2026-10-15 theo hợp đồng net.hpp và cấu trúc socket_win32.cpp
 *    (bản ghép sau vụ mất 2026-10-09 thiếu nửa đầu).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/net.hpp"

#include "core/check.hpp"
#include "core/clock.hpp"
#include "net/detail/native.hpp"

#include <algorithm>
#include <cerrno>
#include <climits>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <unordered_map>
#include <utility>
#include <vector>

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

namespace game::net {
namespace {

// Một lần gửi hay nhận tối đa 1 MiB, cùng bản Windows.
constexpr std::size_t kMaxChunk = std::size_t{1} << 20U;
constexpr auto kAddressSize = static_cast<socklen_t>(sizeof(sockaddr_in));
constexpr short kReadOnly = POLLIN;
constexpr short kReadWrite = POLLIN | POLLOUT;
constexpr int kFailedConnect = POLLERR | POLLHUP | POLLNVAL;
// Gửi vào kết nối đã đứt không được giết tiến trình bằng SIGPIPE.
#ifdef MSG_NOSIGNAL
constexpr int kSendFlags = MSG_NOSIGNAL;
#else
constexpr int kSendFlags = 0;
#endif
#ifdef MSG_TRUNC
constexpr int kRecvFlags = MSG_TRUNC;
#else
constexpr int kRecvFlags = 0;
#endif

[[nodiscard]] constexpr int fd_of(SocketHandle handle) noexcept {
    return static_cast<int>(static_cast<std::intptr_t>(handle));
}

[[nodiscard]] constexpr SocketHandle wrap(int descriptor) noexcept {
    return static_cast<SocketHandle>(static_cast<std::uintptr_t>(static_cast<std::intptr_t>(descriptor)));
}

static_assert(fd_of(kNoSocket) == -1, "kNoSocket phải ra fd -1");
static_assert(wrap(-1) == kNoSocket, "fd -1 phải ra kNoSocket");

[[nodiscard]] sockaddr_in to_native(Endpoint endpoint) noexcept {
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_port = htons(endpoint.port);
    address.sin_addr.s_addr = htonl(detail::pack(endpoint.address));
    return address;
}

[[nodiscard]] Endpoint from_native(const sockaddr_in& address) noexcept {
    const auto host = static_cast<std::uint32_t>(ntohl(address.sin_addr.s_addr));
    return Endpoint{.address = detail::unpack(host), .port = ntohs(address.sin_port)};
}

[[nodiscard]] const sockaddr* as_sockaddr(const sockaddr_in& address) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng socket POSIX (lệch UB-03)
    return reinterpret_cast<const sockaddr*>(&address);
}

[[nodiscard]] sockaddr* as_sockaddr(sockaddr_in& address) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng socket POSIX (lệch UB-03)
    return reinterpret_cast<sockaddr*>(&address);
}

template <typename Value>
[[nodiscard]] bool set_option(int descriptor, int level, int name, const Value& value) noexcept {
    return setsockopt(descriptor, level, name, &value, static_cast<socklen_t>(sizeof(Value))) == 0;
}

[[nodiscard]] std::optional<int> get_flag(int descriptor, int level, int name) noexcept {
    int value = 0;
    auto size = static_cast<socklen_t>(sizeof(value));
    if (getsockopt(descriptor, level, name, &value, &size) != 0) return std::nullopt;
    return value;
}

// Không chặn, đóng khi exec, và (Apple) không phát SIGPIPE. Mọi socket của tệp đi qua đây, cả socket vừa accept: trên
// Linux socket nhận được không thừa kế O_NONBLOCK của cổng nghe.
[[nodiscard]] bool prepare(int descriptor) noexcept {
    const int status = fcntl(descriptor, F_GETFL, 0);
    if (status < 0 || fcntl(descriptor, F_SETFL, status | O_NONBLOCK) != 0) return false;
    const int inherit = fcntl(descriptor, F_GETFD, 0);
    if (inherit < 0 || fcntl(descriptor, F_SETFD, inherit | FD_CLOEXEC) != 0) return false;
#ifdef SO_NOSIGPIPE
    const int enabled = 1;
    if (!set_option(descriptor, SOL_SOCKET, SO_NOSIGPIPE, enabled)) return false;
#endif
    return true;
}

[[nodiscard]] bool set_nodelay(int descriptor) noexcept {
    const int enabled = 1;
    return set_option(descriptor, IPPROTO_TCP, TCP_NODELAY, enabled);
}

// Socket IPv4 đã qua prepare.
[[nodiscard]] NetResult<Socket> make_socket() noexcept {
    const int descriptor = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (descriptor < 0) return std::unexpected(NetError::kSocket);
    Socket socket{wrap(descriptor)};
    if (!prepare(descriptor)) return std::unexpected(NetError::kSocket);
    return socket;
}

[[nodiscard]] NetResult<Endpoint> local_of(SocketHandle handle) noexcept {
    sockaddr_in address{};
    socklen_t size = kAddressSize;
    if (getsockname(fd_of(handle), as_sockaddr(address), &size) != 0) return std::unexpected(NetError::kSocket);
    return from_native(address);
}

[[nodiscard]] bool is_blocked(int code) noexcept {
    return code == EAGAIN || code == EWOULDBLOCK || code == EINTR;
}

// Lỗi của send hay recv: "phải chờ" (hay bị tín hiệu cắt) là 0 byte, còn lại là kết nối đứt.
[[nodiscard]] NetResult<std::size_t> blocked_or_reset(int code) noexcept {
    if (is_blocked(code)) return std::size_t{0};
    return std::unexpected(NetError::kReset);
}

// Hỏi kết quả nối không chờ. SO_ERROR quyết định, POLLHUP một mình không phải nối hỏng: byte và
// FIN tới trước lần hỏi đầu vẫn để receive đọc; RST ngay sau khi nối là kReset.
[[nodiscard]] NetResult<bool> connect_state(int descriptor) noexcept {
    pollfd item{.fd = descriptor, .events = POLLOUT, .revents = 0};
    const int ready = poll(&item, 1, 0);
    if (ready < 0 && errno != EINTR) return std::unexpected(NetError::kConnect);
    if (ready <= 0) return false;
    const int code = get_flag(descriptor, SOL_SOCKET, SO_ERROR).value_or(-1);
    if (code == 0 && (item.revents & POLLOUT) != 0) return true;
    if (code == ECONNRESET) return std::unexpected(NetError::kReset);
    if (code != 0 || (item.revents & kFailedConnect) != 0) return std::unexpected(NetError::kConnect);
    return false;
}

[[nodiscard]] int accept_native(int listener, sockaddr_in& peer) noexcept {
    socklen_t size = kAddressSize;
    return ::accept(listener, as_sockaddr(peer), &size);
}

// Một kết nối nhận lỗi: không có ai chờ, bên nối đã bỏ đi trước khi accept, hay lỗi tạm của giao thức (Linux báo lỗi
// mạng của socket mới qua accept).
[[nodiscard]] NetResult<std::optional<Accepted>> accept_failure(int code) noexcept {
    bool is_transient = is_blocked(code) || code == ECONNABORTED;
#ifdef EPROTO
    is_transient = is_transient || code == EPROTO;
#endif
    if (is_transient) return std::optional<Accepted>{};
    return std::unexpected(NetError::kAccept);
}

[[nodiscard]] int timeout_of(Milliseconds limit) noexcept {
    return static_cast<int>(std::clamp<Milliseconds::rep>(limit.count(), 0, INT_MAX));
}

void append_event(const pollfd& item, std::uint64_t tag, PollEvents& events) {
    if (item.revents == 0) return;
    const int flags = item.revents;
    events.push_back(PollEvent{.tag = tag,
        .readable = (flags & (POLLIN | POLLHUP)) != 0,
        .writable = (flags & POLLOUT) != 0,
        .failed = (flags & (POLLERR | POLLNVAL)) != 0});
}

// Chừa chỗ cho một phần tử: push_back ngay sau đó không cấp phát nên không ném.
template <typename Item>
void make_room(std::vector<Item>& items) {
    if (items.size() == items.capacity()) items.reserve((items.size() * 2) + 1);
}

bool set_dont_fragment(int descriptor) noexcept {
#ifdef __APPLE__
    const int on = 1;
    return set_option(descriptor, IPPROTO_IP, IP_DONTFRAG, on);
#else
    const int mode = IP_PMTUDISC_DO;
    return set_option(descriptor, IPPROTO_IP, IP_MTU_DISCOVER, mode);
#endif
}

bool bind_udp(int descriptor, Endpoint local) noexcept {
    const sockaddr_in where = to_native(local);
    return ::bind(descriptor, as_sockaddr(where), kAddressSize) == 0;
}

NetResult<Socket> make_udp() noexcept {
    const int descriptor = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (descriptor < 0) return std::unexpected(NetError::kSocket);
    Socket socket{wrap(descriptor)};
    if (!prepare(descriptor)) return std::unexpected(NetError::kSocket);
    if (!set_dont_fragment(descriptor)) return std::unexpected(NetError::kSocket);
    return socket;
}

NetResult<std::size_t> udp_send_error(int code) noexcept {
    if (is_blocked(code)) return std::size_t{0};
    return std::unexpected(NetError::kReset);
}

UdpInbound truncated_packet() noexcept {
    UdpInbound inbound;
    inbound.truncated = true;
    return inbound;
}

bool udp_soft(int code) noexcept {
    if (is_blocked(code)) return true;
    return code == ECONNREFUSED;
}

int post_udp(int descriptor, std::span<const std::byte> data, const sockaddr_in& where) noexcept {
    const auto count = static_cast<int>(std::min(data.size(), kMaxChunk));
    const sockaddr* address = as_sockaddr(where);
    return ::sendto(descriptor, data.data(), count, kSendFlags, address, kAddressSize);
}

using UdpRead = NetResult<std::optional<UdpInbound>>;

ssize_t pull_udp(int fd, std::span<std::byte> buf, sockaddr_in& peer, socklen_t& size) noexcept {
    sockaddr* address = as_sockaddr(peer);
    return ::recvfrom(fd, buf.data(), buf.size(), kRecvFlags, address, &size);
}

UdpRead udp_recv_error(int code) noexcept {
    if (udp_soft(code)) return std::optional<UdpInbound>{};
    return std::unexpected(NetError::kReset);
}

UdpRead inbound_of(const sockaddr_in& peer, ssize_t got, std::size_t room) {
    if (static_cast<std::size_t>(got) > room) return truncated_packet();
    UdpInbound inbound;
    inbound.from = from_native(peer);
    inbound.size = static_cast<std::size_t>(got);
    if (room == 0) inbound.truncated = true;
    if (room == 0) inbound.size = 0;
    return inbound;
}

} // namespace

namespace detail {

std::optional<Ipv4> parse_ipv4(const HostText& text) noexcept {
    in_addr address{};
    if (inet_pton(AF_INET, text.data(), &address) != 1) return std::nullopt;
    return unpack(static_cast<std::uint32_t>(ntohl(address.s_addr)));
}

} // namespace detail

// POSIX không có bước khởi động thư viện mạng; Network chỉ giữ hợp đồng chung với bản Windows.
NetResult<Network> Network::start() noexcept {
    Network network;
    network.active_ = true;
    return network;
}

Network::~Network() {
    stop();
}

Network::Network(Network&& other) noexcept : active_(std::exchange(other.active_, false)) {}

Network& Network::operator=(Network&& other) noexcept {
    if (this == &other) return *this;
    stop();
    active_ = std::exchange(other.active_, false);
    return *this;
}

void Network::stop() noexcept {
    active_ = false;
}

Socket::~Socket() {
    close();
}

Socket::Socket(Socket&& other) noexcept : handle_(std::exchange(other.handle_, kNoSocket)) {}

Socket& Socket::operator=(Socket&& other) noexcept {
    if (this == &other) return *this;
    close();
    handle_ = std::exchange(other.handle_, kNoSocket);
    return *this;
}

// close không thử lại khi EINTR: trên Linux và Android bộ mô tả đã được trả dù close báo lỗi, đóng lần hai có thể đóng
// nhầm bộ mô tả vừa được cấp cho luồng khác.
void Socket::close() noexcept {
    if (!is_open()) return;
    static_cast<void>(::close(fd_of(handle_)));
    handle_ = kNoSocket;
}

TcpStream::TcpStream(Socket socket) noexcept : socket_(std::move(socket)) {}

TcpStream::TcpStream(TcpStream&& other) noexcept : socket_(std::move(other.socket_)), connecting_(other.connecting_) {
    other.connecting_ = false;
}

TcpStream& TcpStream::operator=(TcpStream&& other) noexcept {
    socket_ = std::move(other.socket_);
    connecting_ = other.connecting_;
    other.connecting_ = false;
    return *this;
}

NetResult<TcpStream> TcpStream::begin_connect(Endpoint target) noexcept {
    if (target.port == 0) return std::unexpected(NetError::kConnect);
    auto socket = make_socket();
    if (!socket) return std::unexpected(socket.error());
    const int descriptor = fd_of(socket->handle());
    if (!set_nodelay(descriptor)) return std::unexpected(NetError::kSocket);
    const sockaddr_in address = to_native(target);
    const bool started = ::connect(descriptor, as_sockaddr(address), kAddressSize) == 0;
    // EINPROGRESS là nối đang chạy; EINTR với socket không chặn cũng là nối tiếp ở nền (POSIX connect).
    if (!started && errno != EINPROGRESS && errno != EINTR) return std::unexpected(NetError::kConnect);
    TcpStream stream{std::move(*socket)};
    stream.connecting_ = true;
    return stream;
}

NetResult<bool> TcpStream::finish_connect() noexcept {
    if (!is_open()) return std::unexpected(NetError::kConnect);
    if (!connecting_) return true;
    const auto state = connect_state(fd_of(handle()));
    if (!state) socket_.close();
    connecting_ = state.has_value() && !*state;
    return state;
}

NetResult<std::size_t> TcpStream::send(std::span<const std::byte> data) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    const auto ready = finish_connect();
    if (!ready) return std::unexpected(ready.error());
    if (!*ready || data.empty()) return std::size_t{0};
    const ssize_t sent = ::send(fd_of(handle()), data.data(), std::min(data.size(), kMaxChunk), kSendFlags);
    if (sent >= 0) return static_cast<std::size_t>(sent);
    return blocked_or_reset(errno);
}

NetResult<std::size_t> TcpStream::receive(std::span<std::byte> sink) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    const auto ready = finish_connect();
    if (!ready) return std::unexpected(ready.error());
    if (!*ready || sink.empty()) return std::size_t{0};
    const ssize_t got = ::recv(fd_of(handle()), sink.data(), std::min(sink.size(), kMaxChunk), 0);
    if (got > 0) return static_cast<std::size_t>(got);
    if (got == 0) return std::unexpected(NetError::kClosed);
    return blocked_or_reset(errno);
}

// NOLINTNEXTLINE(readability-make-member-function-const): đổi trạng thái socket (lệch API-05)
void TcpStream::shutdown_send() noexcept {
    if (!is_open()) return;
    static_cast<void>(shutdown(fd_of(handle()), SHUT_WR));
}

void TcpStream::abort() noexcept {
    if (!is_open()) return;
    const linger hard{.l_onoff = 1, .l_linger = 0};
    static_cast<void>(set_option(fd_of(handle()), SOL_SOCKET, SO_LINGER, hard));
    socket_.close();
    connecting_ = false;
}

NetResult<Endpoint> TcpStream::local() const noexcept {
    return local_of(handle());
}

bool TcpStream::nodelay() const noexcept {
    return get_flag(fd_of(handle()), IPPROTO_TCP, TCP_NODELAY).value_or(0) != 0;
}

TcpListener::TcpListener(Socket socket) noexcept : socket_(std::move(socket)) {}

NetResult<TcpListener> TcpListener::open(Endpoint address) noexcept {
    auto socket = make_socket();
    if (!socket) return std::unexpected(socket.error());
    const int descriptor = fd_of(socket->handle());
    const sockaddr_in where = to_native(address);
    // POSIX: SO_REUSEADDR chỉ cho bind lại cổng còn kết nối TIME_WAIT, không cho hai socket nghe cùng cổng (khác
    // Windows, nơi cờ này mở cửa cho tiến trình khác chen vào; xem bản Windows).
    const int reuse = 1;
    if (!set_option(descriptor, SOL_SOCKET, SO_REUSEADDR, reuse)) return std::unexpected(NetError::kBind);
    if (bind(descriptor, as_sockaddr(where), kAddressSize) != 0) return std::unexpected(NetError::kBind);
    if (listen(descriptor, SOMAXCONN) != 0) return std::unexpected(NetError::kListen);
    return TcpListener{std::move(*socket)};
}

NetResult<Endpoint> TcpListener::local() const noexcept {
    return local_of(handle());
}

// NOLINTNEXTLINE(readability-make-member-function-const): đổi trạng thái socket (lệch API-05)
NetResult<std::optional<Accepted>> TcpListener::accept() noexcept {
    sockaddr_in peer{};
    const int descriptor = accept_native(fd_of(handle()), peer);
    if (descriptor < 0) return accept_failure(errno);
    Socket socket{wrap(descriptor)};
    if (!prepare(descriptor) || !set_nodelay(descriptor)) return std::unexpected(NetError::kAccept);
    return Accepted{.stream = TcpStream{std::move(socket)}, .peer = from_native(peer)};
}

struct PollSet::Native {
    std::vector<pollfd> items;
    std::vector<std::uint64_t> tags;
    std::unordered_map<std::uint64_t, std::size_t> slots;
};

PollSet::PollSet() : native_(std::make_unique<Native>()) {}

PollSet::~PollSet() = default;

PollSet::PollSet(PollSet&& other) noexcept = default;

PollSet& PollSet::operator=(PollSet&& other) noexcept = default;

PollSet::Native& PollSet::state() const noexcept {
    core::check(native_ != nullptr, "PollSet đã bị chuyển đi");
    return *native_;
}

bool PollSet::add(SocketHandle socket, std::uint64_t tag) {
    Native& set = state();
    if (socket == kNoSocket || set.slots.contains(tag)) return false;
    // Bước có thể ném (cấp phát) chạy hết trước khi đổi gì: lỗi cấp phát để tập nguyên vẹn.
    make_room(set.items);
    make_room(set.tags);
    set.slots.emplace(tag, set.items.size());
    set.items.push_back(pollfd{.fd = fd_of(socket), .events = kReadOnly, .revents = 0});
    set.tags.push_back(tag);
    return true;
}

void PollSet::remove(std::uint64_t tag) noexcept {
    Native& set = state();
    const auto found = set.slots.find(tag);
    if (found == set.slots.end()) return;
    const std::size_t slot = found->second;
    const std::size_t last = set.items.size() - 1;
    set.slots.erase(found);
    set.items[slot] = set.items[last];
    set.tags[slot] = set.tags[last];
    set.items.pop_back();
    set.tags.pop_back();
    if (slot != last) set.slots.find(set.tags[slot])->second = slot;
}

void PollSet::want_write(std::uint64_t tag, bool wanted) noexcept {
    Native& set = state();
    const auto found = set.slots.find(tag);
    if (found == set.slots.end()) return;
    set.items[found->second].events = wanted ? kReadWrite : kReadOnly;
}

std::size_t PollSet::size() const noexcept {
    return state().items.size();
}

// EINTR của poll coi như hết hạn không sự kiện, như gốc.
NetResult<void> PollSet::wait(Milliseconds limit, PollEvents& events) {
    Native& set = state();
    events.clear();
    if (set.items.empty()) core::sleep_for(limit);
    if (set.items.empty()) return {};
    const auto count = static_cast<nfds_t>(set.items.size());
    const int ready = poll(set.items.data(), count, timeout_of(limit));
    if (ready < 0 && errno == EINTR) return {};
    if (ready < 0) return std::unexpected(NetError::kPoll);
    const auto wanted = static_cast<std::size_t>(ready);
    for (std::size_t index = 0; index < set.items.size() && events.size() < wanted; ++index) {
        append_event(set.items[index], set.tags[index], events);
    }
    return {};
}

NetResult<UdpSocket> UdpSocket::open(Endpoint local) noexcept {
    auto socket = make_udp();
    if (!socket) return std::unexpected(socket.error());
    const int descriptor = fd_of(socket->handle());
    if (!bind_udp(descriptor, local)) return std::unexpected(NetError::kBind);
    return UdpSocket{std::move(*socket)};
}

NetResult<Endpoint> UdpSocket::local() const noexcept {
    return local_of(handle());
}

NetResult<std::size_t> UdpSocket::send_to(Endpoint to, std::span<const std::byte> data) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    if (data.empty()) return std::size_t{0};
    const sockaddr_in where = to_native(to);
    const int sent = post_udp(fd_of(handle()), data, where);
    if (sent >= 0) return static_cast<std::size_t>(sent);
    return udp_send_error(errno);
}

NetResult<std::optional<UdpInbound>> UdpSocket::receive_from(std::span<std::byte> sink) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    std::byte scratch{};
    std::span<std::byte> buf = sink;
    if (sink.empty()) buf = std::span<std::byte>{&scratch, 1};
    sockaddr_in peer{};
    socklen_t size = kAddressSize;
    const ssize_t got = pull_udp(fd_of(handle()), buf, peer, size);
    if (got < 0) return udp_recv_error(errno);
    return inbound_of(peer, got, sink.size());
}

} // namespace game::net
