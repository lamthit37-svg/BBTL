// Socket TCP không chặn và tập chờ trên Winsock. Header mạng của Windows chỉ có ở tệp này.
// Nguồn: TLBB Dev src/platform/socket_win32.cpp.
// Khác gốc: WSASocketW với WSA_FLAG_NO_HANDLE_INHERIT thay socket(); chỉ IPv4 qua sockaddr_in,
// địa chỉ đọc bằng inet_pton, không getaddrinfo; accept trả địa chỉ bên kia; bật TCP_NODELAY
// ngay lúc tạo socket nối; thêm abort (SO_LINGER 0), local, nodelay; send và receive tự hỏi
// kết quả nối khi còn đang nối; tập rỗng ngủ bằng core::sleep_for thay std::this_thread.

#include "net/net.hpp"

#include "core/check.hpp"
#include "core/clock.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "net/detail/native.hpp"

#include <algorithm>
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

#include <inaddr.h>
#include <winerror.h>
#include <winsock2.h>
#include <ws2tcpip.h>

namespace game::net {
namespace {

constexpr SOCKET kNoNative = ~SOCKET{0};
// Một lần gửi hay nhận tối đa 1 MiB: len của Winsock là int.
constexpr std::size_t kMaxChunk = std::size_t{1} << 20U;
constexpr int kAddressSize = static_cast<int>(sizeof(sockaddr_in));
using PollMask = decltype(WSAPOLLFD{}.events);
constexpr PollMask kReadOnly = POLLRDNORM;
constexpr PollMask kReadWrite = POLLRDNORM | POLLWRNORM;
constexpr int kFailedConnect = POLLERR | POLLHUP | POLLNVAL;
// FIONBIO của SDK là unsigned long, ioctlsocket nhận long: ép một lần ở đây.
constexpr long kNonBlockingCommand = static_cast<long>(FIONBIO);

[[nodiscard]] SOCKET raw_of(SocketHandle handle) noexcept {
    return static_cast<SOCKET>(handle);
}

[[nodiscard]] SocketHandle wrap(SOCKET socket) noexcept {
    return static_cast<SocketHandle>(socket);
}

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
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    return reinterpret_cast<const sockaddr*>(&address);
}

[[nodiscard]] sockaddr* as_sockaddr(sockaddr_in& address) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    return reinterpret_cast<sockaddr*>(&address);
}

[[nodiscard]] const char* as_chars(std::span<const std::byte> data) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    return reinterpret_cast<const char*>(data.data());
}

[[nodiscard]] char* as_chars(std::span<std::byte> data) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    return reinterpret_cast<char*>(data.data());
}

template <typename Value>
[[nodiscard]] bool set_option(SOCKET socket, int level, int name, const Value& value) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    const auto* bytes = reinterpret_cast<const char*>(&value);
    return setsockopt(socket, level, name, bytes, static_cast<int>(sizeof(Value))) == 0;
}

[[nodiscard]] std::optional<int> get_flag(SOCKET socket, int level, int name) noexcept {
    int value = 0;
    int size = static_cast<int>(sizeof(value));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock (lệch UB-03)
    auto* bytes = reinterpret_cast<char*>(&value);
    if (getsockopt(socket, level, name, bytes, &size) != 0) return std::nullopt;
    return value;
}

[[nodiscard]] bool set_nonblocking(SOCKET socket) noexcept {
    u_long enabled = 1;
    return ioctlsocket(socket, kNonBlockingCommand, &enabled) == 0;
}

[[nodiscard]] bool set_nodelay(SOCKET socket) noexcept {
    const int enabled = 1;
    return set_option(socket, IPPROTO_TCP, TCP_NODELAY, enabled);
}

// Socket IPv4 không chặn, không cho tiến trình con thừa kế.
[[nodiscard]] NetResult<Socket> make_socket() noexcept {
    const DWORD flags = WSA_FLAG_OVERLAPPED | WSA_FLAG_NO_HANDLE_INHERIT;
    const SOCKET raw = WSASocketW(AF_INET, SOCK_STREAM, IPPROTO_TCP, nullptr, 0, flags);
    if (raw == kNoNative) return std::unexpected(NetError::kSocket);
    Socket socket{wrap(raw)};
    if (!set_nonblocking(raw)) return std::unexpected(NetError::kSocket);
    return socket;
}

[[nodiscard]] NetResult<Endpoint> local_of(SocketHandle handle) noexcept {
    sockaddr_in address{};
    int size = kAddressSize;
    if (getsockname(raw_of(handle), as_sockaddr(address), &size) != 0) {
        return std::unexpected(NetError::kSocket);
    }
    return from_native(address);
}

// Lỗi của send hay recv: "phải chờ" là 0 byte, còn lại là kết nối đứt.
[[nodiscard]] NetResult<std::size_t> blocked_or_reset(int code) noexcept {
    if (code == WSAEWOULDBLOCK) return std::size_t{0};
    return std::unexpected(NetError::kReset);
}

[[nodiscard]] int chunk_of(std::size_t size) noexcept {
    return static_cast<int>(std::min(size, kMaxChunk));
}

// Hỏi kết quả nối không chờ. SO_ERROR quyết định, POLLHUP một mình không phải nối hỏng: byte và
// FIN tới trước lần hỏi đầu vẫn để receive đọc; RST ngay sau khi nối là kReset.
[[nodiscard]] NetResult<bool> connect_state(SOCKET socket) noexcept {
    WSAPOLLFD item{.fd = socket, .events = POLLWRNORM, .revents = 0};
    if (WSAPoll(&item, 1, 0) == SOCKET_ERROR) return std::unexpected(NetError::kConnect);
    const int code = get_flag(socket, SOL_SOCKET, SO_ERROR).value_or(-1);
    if (code == 0 && (item.revents & POLLWRNORM) != 0) return true;
    if (code == WSAECONNRESET) return std::unexpected(NetError::kReset);
    if (code != 0 || (item.revents & kFailedConnect) != 0) {
        return std::unexpected(NetError::kConnect);
    }
    return false;
}

// Một kết nối nhận lỗi: không có ai chờ, hoặc bên nối đã bỏ đi trước khi accept.
[[nodiscard]] NetResult<std::optional<Accepted>> accept_failure(int code) noexcept {
    if (code == WSAEWOULDBLOCK || code == WSAECONNRESET) return std::optional<Accepted>{};
    return std::unexpected(NetError::kAccept);
}

[[nodiscard]] INT timeout_of(Milliseconds limit) noexcept {
    return static_cast<INT>(std::clamp<Milliseconds::rep>(limit.count(), 0, INT_MAX));
}

void append_event(const WSAPOLLFD& item, std::uint64_t tag, PollEvents& events) {
    if (item.revents == 0) return;
    const int flags = item.revents;
    events.push_back(PollEvent{.tag = tag,
        .readable = (flags & (POLLRDNORM | POLLHUP)) != 0,
        .writable = (flags & POLLWRNORM) != 0,
        .failed = (flags & (POLLERR | POLLNVAL)) != 0});
}

// Chừa chỗ cho một phần tử: push_back ngay sau đó không cấp phát nên không ném.
template <typename Item>
void make_room(std::vector<Item>& items) {
    if (items.size() == items.capacity()) items.reserve((items.size() * 2) + 1);
}

} // namespace

namespace detail {

std::optional<Ipv4> parse_ipv4(const HostText& text) noexcept {
    in_addr address{};
    if (inet_pton(AF_INET, text.data(), &address) != 1) return std::nullopt;
    return unpack(static_cast<std::uint32_t>(ntohl(address.s_addr)));
}

} // namespace detail

NetResult<Network> Network::start() noexcept {
    WSADATA data{};
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return std::unexpected(NetError::kStartup);
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
    if (!active_) return;
    static_cast<void>(WSACleanup());
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

void Socket::close() noexcept {
    if (!is_open()) return;
    static_cast<void>(closesocket(raw_of(handle_)));
    handle_ = kNoSocket;
}

TcpStream::TcpStream(Socket socket) noexcept : socket_(std::move(socket)) {}

TcpStream::TcpStream(TcpStream&& other) noexcept
    : socket_(std::move(other.socket_)), connecting_(other.connecting_) {
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
    const SOCKET raw = raw_of(socket->handle());
    if (!set_nodelay(raw)) return std::unexpected(NetError::kSocket);
    const sockaddr_in address = to_native(target);
    const bool started = connect(raw, as_sockaddr(address), kAddressSize) == 0;
    if (!started && WSAGetLastError() != WSAEWOULDBLOCK) return std::unexpected(NetError::kConnect);
    TcpStream stream{std::move(*socket)};
    stream.connecting_ = true;
    return stream;
}

NetResult<bool> TcpStream::finish_connect() noexcept {
    if (!is_open()) return std::unexpected(NetError::kConnect);
    if (!connecting_) return true;
    const auto state = connect_state(raw_of(handle()));
    if (!state) socket_.close();
    connecting_ = state.has_value() && !*state;
    return state;
}

NetResult<std::size_t> TcpStream::send(std::span<const std::byte> data) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    const auto ready = finish_connect();
    if (!ready) return std::unexpected(ready.error());
    if (!*ready || data.empty()) return std::size_t{0};
    const int sent = ::send(raw_of(handle()), as_chars(data), chunk_of(data.size()), 0);
    if (sent >= 0) return static_cast<std::size_t>(sent);
    return blocked_or_reset(WSAGetLastError());
}

NetResult<std::size_t> TcpStream::receive(std::span<std::byte> sink) noexcept {
    if (!is_open()) return std::unexpected(NetError::kReset);
    const auto ready = finish_connect();
    if (!ready) return std::unexpected(ready.error());
    if (!*ready || sink.empty()) return std::size_t{0};
    const int got = recv(raw_of(handle()), as_chars(sink), chunk_of(sink.size()), 0);
    if (got > 0) return static_cast<std::size_t>(got);
    if (got == 0) return std::unexpected(NetError::kClosed);
    return blocked_or_reset(WSAGetLastError());
}

// NOLINTNEXTLINE(readability-make-member-function-const): đổi trạng thái socket (lệch API-05)
void TcpStream::shutdown_send() noexcept {
    if (!is_open()) return;
    static_cast<void>(shutdown(raw_of(handle()), SD_SEND));
}

void TcpStream::abort() noexcept {
    if (!is_open()) return;
    const linger hard{.l_onoff = 1, .l_linger = 0};
    static_cast<void>(set_option(raw_of(handle()), SOL_SOCKET, SO_LINGER, hard));
    socket_.close();
    connecting_ = false;
}

NetResult<Endpoint> TcpStream::local() const noexcept {
    return local_of(handle());
}

bool TcpStream::nodelay() const noexcept {
    return get_flag(raw_of(handle()), IPPROTO_TCP, TCP_NODELAY).value_or(0) != 0;
}

TcpListener::TcpListener(Socket socket) noexcept : socket_(std::move(socket)) {}

NetResult<TcpListener> TcpListener::open(Endpoint address) noexcept {
    auto socket = make_socket();
    if (!socket) return std::unexpected(socket.error());
    const SOCKET raw = raw_of(socket->handle());
    const sockaddr_in where = to_native(address);
    if (bind(raw, as_sockaddr(where), kAddressSize) != 0) return std::unexpected(NetError::kBind);
    if (listen(raw, SOMAXCONN) != 0) return std::unexpected(NetError::kListen);
    return TcpListener{std::move(*socket)};
}

NetResult<Endpoint> TcpListener::local() const noexcept {
    return local_of(handle());
}

// NOLINTNEXTLINE(readability-make-member-function-const): đổi trạng thái socket (lệch API-05)
NetResult<std::optional<Accepted>> TcpListener::accept() noexcept {
    sockaddr_in peer{};
    int size = kAddressSize;
    const SOCKET raw = ::accept(raw_of(handle()), as_sockaddr(peer), &size);
    if (raw == kNoNative) return accept_failure(WSAGetLastError());
    Socket socket{wrap(raw)};
    if (!set_nonblocking(raw) || !set_nodelay(raw)) return std::unexpected(NetError::kAccept);
    return Accepted{.stream = TcpStream{std::move(socket)}, .peer = from_native(peer)};
}

struct PollSet::Native {
    std::vector<WSAPOLLFD> items;
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
    set.items.push_back(WSAPOLLFD{.fd = raw_of(socket), .events = kReadOnly, .revents = 0});
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

NetResult<void> PollSet::wait(Milliseconds limit, PollEvents& events) {
    Native& set = state();
    events.clear();
    if (set.items.empty()) core::sleep_for(limit);
    if (set.items.empty()) return {};
    const auto count = static_cast<ULONG>(set.items.size());
    const int ready = WSAPoll(set.items.data(), count, timeout_of(limit));
    if (ready == SOCKET_ERROR) return std::unexpected(NetError::kPoll);
    const auto wanted = static_cast<std::size_t>(ready);
    for (std::size_t index = 0; index < set.items.size() && events.size() < wanted; ++index) {
        append_event(set.items[index], set.tags[index], events);
    }
    return {};
}

} // namespace game::net
