/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/reactor_win32.cpp
 *  PHÂN HỆ   : Net / Reactor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Reactor trên Windows: một cổng hoàn thành cho mọi socket của luồng.
 *  - Đọc là WSARecv 0 byte (không nuốt dữ liệu) để biết lúc recv() có việc; gửi
 *    là WSASend bản sao, nên outbox của gate dịch chuyển được khi kernel còn
 *    giữ bản sao.
 *  - Nhận kết nối là AcceptEx đăng sẵn, khỏi đánh thức rồi mới accept.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/reactor.hpp"

#include "core/check.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "net/detail/native.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>
#include <optional>
#include <span>
#include <unordered_map>
#include <utility>
#include <vector>

#include <winerror.h>
#include <winsock2.h>
#include <ws2tcpip.h>

// mswsock.h cần SOCKET của winsock2.h nên đứng sau, khối riêng để clang-format không xếp lại.
#include <mswsock.h>

namespace game::net {
namespace {

constexpr SOCKET kInvalid = INVALID_SOCKET;
constexpr int kAcceptPosts = 32;
constexpr DWORD kAddrLen = static_cast<DWORD>(sizeof(sockaddr_in) + 16);
constexpr std::size_t kSendCap = 2048;
constexpr ULONG kBatch = 32;
constexpr std::uint32_t kCancelled = 995;

enum class Kind : std::uint8_t { kRead, kWrite, kAccept };

struct Slot;

struct Op {
    OVERLAPPED ov{};
    Kind kind = Kind::kRead;
    Slot* slot = nullptr;
    bool posted = false;
};

struct AcceptOp {
    Op op{};
    SOCKET sock = kInvalid;
    std::array<char, std::size_t{kAddrLen} * 2> buf{};
};

struct Slot {
    SOCKET fd = kInvalid;
    std::uint64_t tag = 0;
    bool listener = false;
    bool dead = false;
    bool dirty = false;
    bool read_hot = false;
    bool write_hot = false;
    bool failed = false;
    bool send_posted = false;
    int posted = 0;
    Op read{};
    Op write{};
    std::array<std::byte, kSendCap> send_buf{};
    std::size_t send_len = 0;
    std::size_t completed_send = 0;
    std::vector<std::unique_ptr<AcceptOp>> accepts;
    std::vector<AcceptOp*> ready;
};

[[nodiscard]] SOCKET raw_of(SocketHandle handle) noexcept {
    return static_cast<SOCKET>(handle);
}

[[nodiscard]] SocketHandle wrap(SOCKET socket) noexcept {
    return static_cast<SocketHandle>(socket);
}

[[nodiscard]] Endpoint endpoint_of(const sockaddr_in& address) noexcept {
    const auto host = static_cast<std::uint32_t>(ntohl(address.sin_addr.s_addr));
    return Endpoint{.address = detail::unpack(host), .port = ntohs(address.sin_port)};
}

void close_accept(AcceptOp& accept) noexcept {
    if (accept.sock == kInvalid) return;
    closesocket(accept.sock);
    accept.sock = kInvalid;
}

[[nodiscard]] SOCKET open_raw() noexcept {
    const DWORD flags = WSA_FLAG_OVERLAPPED | WSA_FLAG_NO_HANDLE_INHERIT;
    return WSASocketW(AF_INET, SOCK_STREAM, IPPROTO_TCP, nullptr, 0, flags);
}

// FIONBIO của SDK là unsigned long, ioctlsocket nhận long: ép một lần (như socket_win32.cpp).
constexpr long kNonBlockingCommand = static_cast<long>(FIONBIO);

[[nodiscard]] bool set_nonblocking(SOCKET socket) noexcept {
    u_long enabled = 1;
    return ioctlsocket(socket, kNonBlockingCommand, &enabled) == 0;
}

[[nodiscard]] bool set_nodelay(SOCKET socket) noexcept {
    const int enabled = 1;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock
    const auto* bytes = reinterpret_cast<const char*>(&enabled);
    return setsockopt(socket, IPPROTO_TCP, TCP_NODELAY, bytes, static_cast<int>(sizeof(enabled))) == 0;
}

[[nodiscard]] DWORD clamp_ms(Milliseconds limit) noexcept {
    const auto count = limit.count();
    if (count <= 0) return 0;
    if (count > 86'400'000) return 86'400'000;
    return static_cast<DWORD>(count);
}

} // namespace

struct ReactorNative {
    HANDLE port = nullptr;
    LPFN_ACCEPTEX accept_ex = nullptr;
    LPFN_GETACCEPTEXSOCKADDRS accept_addrs = nullptr;
    std::unordered_map<std::uint64_t, std::unique_ptr<Slot>> slots;
    std::vector<std::uint64_t> dirty;
    int pending = 0;
    OVERLAPPED wake_ov{};
    std::atomic<std::uint32_t> wake_flag{0};

    ReactorNative() {
        port = CreateIoCompletionPort(INVALID_HANDLE_VALUE, nullptr, 0, 1);
        core::check(port != nullptr, "không tạo được cổng hoàn thành");
    }

    ReactorNative(const ReactorNative&) = delete;
    ReactorNative& operator=(const ReactorNative&) = delete;
    ReactorNative(ReactorNative&&) = delete;
    ReactorNative& operator=(ReactorNative&&) = delete;
    ~ReactorNative();
};

namespace {

[[nodiscard]] Slot* find(ReactorNative& native, std::uint64_t tag) noexcept {
    const auto found = native.slots.find(tag);
    if (found == native.slots.end()) return nullptr;
    return found->second.get();
}

void mark(ReactorNative& native, Slot& slot) {
    if (slot.dirty) return;
    slot.dirty = true;
    native.dirty.push_back(slot.tag);
}

void retire(ReactorNative& native, Slot& slot) {
    if (!slot.dead || slot.posted != 0) return;
    native.slots.erase(slot.tag);
}

[[nodiscard]] bool join_port(ReactorNative& native, SOCKET socket) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): HANDLE của socket
    const HANDLE joined = CreateIoCompletionPort(reinterpret_cast<HANDLE>(socket), native.port, 0, 1);
    return joined != nullptr;
}

[[nodiscard]] bool load_ex(ReactorNative& native, SOCKET socket) noexcept {
    if (native.accept_ex != nullptr && native.accept_addrs != nullptr) return true;
    GUID accept_id = WSAID_ACCEPTEX;
    GUID addr_id = WSAID_GETACCEPTEXSOCKADDRS;
    DWORD bytes = 0;
    const int accept = WSAIoctl(socket, SIO_GET_EXTENSION_FUNCTION_POINTER, &accept_id, sizeof(accept_id),
        &native.accept_ex, sizeof(native.accept_ex), &bytes, nullptr, nullptr);
    bytes = 0;
    const int addrs = WSAIoctl(socket, SIO_GET_EXTENSION_FUNCTION_POINTER, &addr_id, sizeof(addr_id),
        &native.accept_addrs, sizeof(native.accept_addrs), &bytes, nullptr, nullptr);
    return accept == 0 && addrs == 0 && native.accept_ex != nullptr && native.accept_addrs != nullptr;
}

void finish_op(ReactorNative& native, Op& op) noexcept {
    op.posted = false;
    if (op.slot != nullptr && op.slot->posted > 0) --op.slot->posted;
    if (native.pending > 0) --native.pending;
}

[[nodiscard]] bool post_accept(ReactorNative& native, Slot& slot, AcceptOp& accept) noexcept {
    if (accept.op.posted || slot.dead || native.accept_ex == nullptr) return false;
    const SOCKET fresh = open_raw();
    if (fresh == kInvalid) return false;
    accept.sock = fresh;
    accept.op.ov = {};
    accept.op.kind = Kind::kAccept;
    accept.op.slot = &slot;
    DWORD got = 0;
    const BOOL ok = native.accept_ex(slot.fd, fresh, accept.buf.data(), 0, kAddrLen, kAddrLen, &got, &accept.op.ov);
    if (ok == TRUE || WSAGetLastError() == WSA_IO_PENDING) {
        accept.op.posted = true;
        ++slot.posted;
        ++native.pending;
        return true;
    }
    close_accept(accept);
    return false;
}

[[nodiscard]] bool post_read(ReactorNative& native, Slot& slot) noexcept {
    if (slot.dead || slot.read.posted || slot.listener) return !slot.dead;
    slot.read.ov = {};
    slot.read.kind = Kind::kRead;
    slot.read.slot = &slot;
    WSABUF buf{0, nullptr};
    DWORD flags = 0;
    DWORD got = 0;
    const int rc = WSARecv(slot.fd, &buf, 1, &got, &flags, &slot.read.ov, nullptr);
    if (rc != 0 && WSAGetLastError() != WSA_IO_PENDING) {
        slot.failed = true;
        mark(native, slot);
        return false;
    }
    slot.read.posted = true;
    ++slot.posted;
    ++native.pending;
    return true;
}

void apply_read(ReactorNative& native, Slot& slot, bool ok, int error) {
    slot.read.posted = false;
    if (slot.dead || error == static_cast<int>(kCancelled)) return;
    if (!ok) slot.failed = true;
    if (ok) slot.read_hot = true;
    mark(native, slot);
}

void apply_write(ReactorNative& native, Slot& slot, bool ok, int error, DWORD bytes) {
    slot.send_posted = false;
    if (slot.dead || error == static_cast<int>(kCancelled)) return;
    if (!ok || bytes == 0) slot.failed = true;
    if (ok && bytes > 0) slot.completed_send = bytes;
    mark(native, slot);
}

void apply_accept(ReactorNative& native, Slot& slot, AcceptOp& accept, bool ok, int error) {
    if (slot.dead || error == static_cast<int>(kCancelled) || !ok) {
        close_accept(accept);
        if (!slot.dead) static_cast<void>(post_accept(native, slot, accept));
        return;
    }
    slot.ready.push_back(&accept);
    mark(native, slot);
}

void apply(ReactorNative& native, const OVERLAPPED_ENTRY& entry) {
    OVERLAPPED* ov = entry.lpOverlapped;
    if (ov == nullptr) return;
    if (ov == &native.wake_ov) {
        native.wake_flag.store(0, std::memory_order_release);
        return;
    }
    // OVERLAPPED là trường đầu của Op.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): gói hoàn thành trả đúng Op
    Op* op = reinterpret_cast<Op*>(ov);
    Slot* slot = op->slot;
    if (slot == nullptr) return;
    DWORD bytes = 0;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): HANDLE của socket
    const BOOL done = GetOverlappedResult(reinterpret_cast<HANDLE>(slot->fd), ov, &bytes, FALSE);
    const int error = done == TRUE ? 0 : static_cast<int>(GetLastError());
    const Kind kind = op->kind;
    finish_op(native, *op);
    if (kind == Kind::kAccept) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): Op đứng đầu AcceptOp
        apply_accept(native, *slot, *reinterpret_cast<AcceptOp*>(op), done == TRUE, error);
    } else if (kind == Kind::kWrite) {
        apply_write(native, *slot, done == TRUE, error, bytes);
    } else {
        apply_read(native, *slot, done == TRUE, error);
    }
    retire(native, *slot);
}

struct Harvest {
    bool failed = false;
    ULONG count = 0;
};

[[nodiscard]] Harvest harvest(ReactorNative& native, DWORD timeout) {
    Harvest result;
    if (native.port == nullptr) {
        result.failed = true;
        return result;
    }
    std::array<OVERLAPPED_ENTRY, kBatch> entries{};
    ULONG got = 0;
    const BOOL ok = GetQueuedCompletionStatusEx(native.port, entries.data(), kBatch, &got, timeout, FALSE);
    if (ok == FALSE) {
        result.failed = GetLastError() != WAIT_TIMEOUT;
        return result;
    }
    result.count = got;
    for (ULONG index = 0; index < got; ++index)
        apply(native, entries[index]);
    return result;
}

[[nodiscard]] bool pump_io(ReactorNative& native, DWORD timeout) {
    for (int pass = 0; pass < 8; ++pass) {
        const Harvest once = harvest(native, timeout);
        if (once.failed) return false;
        if (once.count == 0) return true;
        timeout = 0;
    }
    return true;
}

void emit(ReactorNative& native, PollEvents& events) {
    for (const std::uint64_t tag : native.dirty) {
        Slot* slot = find(native, tag);
        if (slot == nullptr) continue;
        slot->dirty = false;
        PollEvent event{};
        event.tag = slot->tag;
        if (slot->read_hot) {
            event.readable = true;
            slot->read_hot = false;
        }
        if (slot->write_hot) {
            event.writable = true;
            slot->write_hot = false;
        }
        if (slot->completed_send > 0) {
            event.sent = slot->completed_send;
            slot->completed_send = 0;
        }
        if (slot->failed) {
            event.failed = true;
            slot->failed = false;
        }
        if (slot->listener && !slot->ready.empty()) event.readable = true;
        const bool any = event.readable || event.writable || event.failed || event.sent > 0;
        if (!any) continue;
        events.push_back(event);
    }
    native.dirty.clear();
}

[[nodiscard]] std::optional<Accepted> adopt(ReactorNative& native, Slot& slot, AcceptOp& accept) {
    sockaddr* local = nullptr;
    sockaddr* remote = nullptr;
    int local_len = 0;
    int remote_len = 0;
    if (native.accept_addrs != nullptr) {
        native.accept_addrs(accept.buf.data(), 0, kAddrLen, kAddrLen, &local, &local_len, &remote, &remote_len);
    }
    Endpoint peer{};
    if (remote != nullptr && remote_len >= static_cast<int>(sizeof(sockaddr_in))) {
        sockaddr_in address{};
        std::memcpy(&address, remote, sizeof(address));
        peer = endpoint_of(address);
    }
    const SOCKET raw = accept.sock;
    accept.sock = kInvalid;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng setsockopt
    const auto* listen_bytes = reinterpret_cast<const char*>(&slot.fd);
    const int updated = setsockopt(raw, SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT, listen_bytes, sizeof(slot.fd));
    Socket owned{wrap(raw)};
    const bool ready = updated == 0 && set_nonblocking(raw) && set_nodelay(raw);
    static_cast<void>(post_accept(native, slot, accept));
    if (!ready) return std::nullopt;
    return Accepted{.stream = TcpStream::from_socket(std::move(owned)), .peer = peer};
}

[[nodiscard]] std::optional<Accepted> adopt_ready(ReactorNative& native, Slot& slot) {
    while (!slot.ready.empty()) {
        AcceptOp* accept = slot.ready.back();
        slot.ready.pop_back();
        if (accept == nullptr) continue;
        std::optional<Accepted> taken = adopt(native, slot, *accept);
        if (taken.has_value()) return taken;
    }
    return std::nullopt;
}

void drop_ready(Slot& slot) noexcept {
    for (AcceptOp* accept : slot.ready) {
        if (accept != nullptr) close_accept(*accept);
    }
    slot.ready.clear();
}

} // namespace

ReactorNative::~ReactorNative() {
    for (auto& item : slots) {
        Slot& slot = *item.second;
        slot.dead = true;
        drop_ready(slot);
        if (slot.fd == kInvalid) continue;
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): HANDLE của socket
        static_cast<void>(CancelIoEx(reinterpret_cast<HANDLE>(slot.fd), nullptr));
    }
    for (int spin = 0; spin < 100 && pending > 0; ++spin)
        static_cast<void>(harvest(*this, 20));
    if (pending > 0) {
        for (auto& item : slots)
            static_cast<void>(item.second.release());
    }
    slots.clear();
    if (port != nullptr) CloseHandle(port);
    port = nullptr;
}

Reactor::Reactor() : native_(std::make_unique<ReactorNative>()) {}

Reactor::~Reactor() = default;

Reactor::Reactor(Reactor&&) noexcept = default;

Reactor& Reactor::operator=(Reactor&&) noexcept = default;

ReactorNative& Reactor::state() const noexcept {
    core::check(native_ != nullptr, "Reactor đã bị chuyển đi");
    return *native_;
}

bool Reactor::watch(SocketHandle socket, std::uint64_t tag) {
    if (socket == kNoSocket) return false;
    ReactorNative& native = state();
    if (native.slots.contains(tag)) return false;
    auto slot = std::make_unique<Slot>();
    slot->fd = raw_of(socket);
    slot->tag = tag;
    if (!join_port(native, slot->fd)) return false;
    Slot* view = slot.get();
    native.slots.emplace(tag, std::move(slot));
    if (post_read(native, *view)) return true;
    native.slots.erase(tag);
    return false;
}

void Reactor::unwatch(std::uint64_t tag) {
    ReactorNative& native = state();
    Slot* slot = find(native, tag);
    if (slot == nullptr) return;
    const bool listener = slot->listener;
    slot->dead = true;
    slot->read_hot = false;
    slot->write_hot = false;
    drop_ready(*slot);
    if (slot->fd != kInvalid) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): HANDLE của socket
        static_cast<void>(CancelIoEx(reinterpret_cast<HANDLE>(slot->fd), nullptr));
    }
    if (listener) {
        for (int spin = 0; spin < 50; ++spin) {
            const Slot* current = find(native, tag);
            if (current == nullptr || current->posted == 0) break;
            static_cast<void>(harvest(native, 20));
        }
    }
    Slot* left = find(native, tag);
    if (left != nullptr) retire(native, *left);
}

void Reactor::want_write(std::uint64_t tag, bool wanted) {
    ReactorNative& native = state();
    Slot* slot = find(native, tag);
    if (slot == nullptr || slot->dead || slot->listener) return;
    slot->write_hot = wanted;
    if (wanted) mark(native, *slot);
}

void Reactor::note_read(std::uint64_t tag, std::size_t got) {
    ReactorNative& native = state();
    Slot* slot = find(native, tag);
    if (slot == nullptr || slot->dead || slot->listener) return;
    if (got > 0) {
        u_long avail = 0;
        if (ioctlsocket(slot->fd, FIONREAD, &avail) == 0 && avail > 0) {
            slot->read_hot = true;
            mark(native, *slot);
            return;
        }
    }
    static_cast<void>(post_read(native, *slot));
}

bool Reactor::watch_listener(TcpListener& listener, std::uint64_t tag) {
    ReactorNative& native = state();
    if (native.slots.contains(tag)) return false;
    const SOCKET listen = raw_of(listener.handle());
    if (listen == kInvalid || !load_ex(native, listen) || !join_port(native, listen)) return false;
    auto slot = std::make_unique<Slot>();
    slot->fd = listen;
    slot->tag = tag;
    slot->listener = true;
    slot->accepts.reserve(static_cast<std::size_t>(kAcceptPosts));
    Slot* view = slot.get();
    native.slots.emplace(tag, std::move(slot));
    for (int index = 0; index < kAcceptPosts; ++index) {
        auto accept = std::make_unique<AcceptOp>();
        AcceptOp* op = accept.get();
        view->accepts.push_back(std::move(accept));
        if (post_accept(native, *view, *op)) continue;
        unwatch(tag);
        return false;
    }
    return true;
}

NetResult<std::optional<Accepted>> Reactor::take_accept(std::uint64_t tag) {
    ReactorNative& native = state();
    Slot* slot = find(native, tag);
    if (slot == nullptr || !slot->listener || slot->dead) return std::optional<Accepted>{};
    return adopt_ready(native, *slot);
}

SendOutcome Reactor::submit_send(std::uint64_t tag, std::span<const std::byte> data) noexcept {
    ReactorNative& native = state();
    Slot* slot = find(native, tag);
    if (slot == nullptr || slot->dead || slot->listener) return SendOutcome{.state = SendState::kReset};
    if (slot->send_posted) return SendOutcome{.state = SendState::kPending};
    if (data.empty()) return SendOutcome{.state = SendState::kDone};
    const std::size_t count = std::min(data.size(), slot->send_buf.size());
    std::copy_n(data.begin(), count, slot->send_buf.begin());
    slot->send_len = count;
    slot->write.ov = {};
    slot->write.kind = Kind::kWrite;
    slot->write.slot = slot;
    WSABUF buf{};
    buf.len = static_cast<ULONG>(count);
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock
    buf.buf = reinterpret_cast<CHAR*>(slot->send_buf.data());
    DWORD sent = 0;
    const int rc = WSASend(slot->fd, &buf, 1, &sent, 0, &slot->write.ov, nullptr);
    if (rc != 0 && WSAGetLastError() != WSA_IO_PENDING) return SendOutcome{.state = SendState::kReset};
    slot->send_posted = true;
    slot->write.posted = true;
    ++slot->posted;
    ++native.pending;
    return SendOutcome{.state = SendState::kPending};
}

NetResult<void> Reactor::wait(Milliseconds limit, PollEvents& events) {
    ReactorNative& native = state();
    events.clear();
    const DWORD timeout = native.dirty.empty() ? clamp_ms(limit) : 0;
    if (!pump_io(native, timeout)) return std::unexpected(NetError::kPoll);
    emit(native, events);
    return {};
}

void Reactor::wake() noexcept {
    ReactorNative& native = state();
    const std::uint32_t previous = native.wake_flag.exchange(1, std::memory_order_acq_rel);
    if (previous != 0 || native.port == nullptr) return;
    if (PostQueuedCompletionStatus(native.port, 0, 0, &native.wake_ov) != 0) return;
    native.wake_flag.store(0, std::memory_order_release);
}

std::size_t Reactor::size() const noexcept {
    return state().slots.size();
}

} // namespace game::net
