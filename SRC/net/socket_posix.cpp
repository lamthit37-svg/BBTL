// Socket TCP không chặn và tập chờ trên POSIX (Linux, Android, macOS). Header mạng của POSIX chỉ
// có ở tệp này. Chưa chạy: chỉ kiểm cú pháp bằng NDK.
// Nguồn: TLBB Dev src/platform/socket_posix.cpp.
// Khác gốc: chỉ IPv4 qua sockaddr_in, địa chỉ đọc bằng inet_pton, không getaddrinfo; accept trả
// địa chỉ bên kia; bật TCP_NODELAY ngay lúc tạo socket nối; thêm abort (SO_LINGER 0), local,
// nodelay; send và receive tự hỏi kết quả nối khi còn đang nối; tập rỗng ngủ bằng core::sleep_for.

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

[[nodiscard]] int fd_of(SocketHandle handle) noexcept {
    return static_cast<int>(static_cast<std::intptr_t>(handle));
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

} // namespace game::net
