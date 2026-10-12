// Link nói chuyện với một peer bắt tay thật trên loopback, cổng 0. Chờ bằng PollSet, không ngủ.
#include "core/check.hpp"
#include "link/link.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <thread>
#include <vector>

namespace game::test {
namespace {

constexpr net::Ipv4 kLoopback{127, 0, 0, 1};

[[nodiscard]] bool send_all(net::TcpStream& stream, std::span<const std::byte> data) {
    std::size_t sent = 0;
    net::PollSet poll;
    if (!poll.add(stream.handle(), 1)) return false;
    while (sent < data.size()) {
        const net::NetResult<std::size_t> step = stream.send(data.subspan(sent));
        if (!step) return false;
        if (*step > 0) {
            sent += *step;
            continue;
        }
        poll.want_write(1, true);
        net::PollEvents events;
        if (!poll.wait(net::Milliseconds{1000}, events)) return false;
    }
    return true;
}

[[nodiscard]] bool recv_n(net::TcpStream& stream, std::vector<std::byte>& inbox, std::size_t need) {
    net::PollSet poll;
    if (!poll.add(stream.handle(), 1)) return false;
    while (inbox.size() < need) {
        std::array<std::byte, 2048> chunk{};
        const net::NetResult<std::size_t> got = stream.receive(chunk);
        if (!got) return false;
        if (*got > 0) {
            inbox.insert(inbox.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
            continue;
        }
        net::PollEvents events;
        if (!poll.wait(net::Milliseconds{1000}, events)) return false;
    }
    return true;
}

void peer(net::TcpListener listener, const secure::Identity& identity, bool& ok) {
    ok = false;
    net::PollSet poll;
    if (!poll.add(listener.handle(), 1)) return;
    net::NetResult<std::optional<net::Accepted>> accepted = listener.accept();
    if (!accepted || !accepted->has_value()) {
        net::PollEvents events;
        if (!poll.wait(net::Milliseconds{3000}, events)) return;
        accepted = listener.accept();
    }
    if (!accepted || !accepted->has_value()) return;
    net::TcpStream stream = std::move((*accepted)->stream);
    std::vector<std::byte> inbox;
    if (!recv_n(stream, inbox, secure::kClientHelloBytes)) return;
    secure::ServerHandshake handshake(identity);
    const secure::AbsorbResult absorbed = handshake.absorb(std::span{inbox.data(), secure::kClientHelloBytes});
    if (!absorbed || !handshake.is_done()) return;
    if (!send_all(stream, handshake.reply())) return;
    secure::RecordPipe pipe(handshake.take_keys());
    inbox.clear();
    std::array<std::byte, secure::kMaxPlainBytes> plain{};
    while (true) {
        const secure::OpenResult opened = pipe.open_bytes(std::span{inbox.data(), inbox.size()}, plain);
        if (!opened) return;
        if (opened->written > 0) break;
        if (!recv_n(stream, inbox, inbox.size() + 1)) return;
    }
    protocol::Welcome welcome;
    welcome.version = protocol::kVersion;
    welcome.heartbeat = std::chrono::seconds{1};
    std::vector<std::byte> encoded;
    if (!protocol::encode(encoded, welcome)) return;
    std::array<std::byte, secure::kMaxRecordBytes> record{};
    const secure::SealResult wrote = pipe.seal(encoded, record);
    if (!wrote) return;
    ok = send_all(stream, std::span{record}.first(*wrote));
}

void link_receives_welcome(Context& context) {
    const secure::Result<secure::Identity> identity = secure::Identity::generate();
    context.expect(identity.has_value(), "tạo được khoá");
    if (!identity) return;
    net::NetResult<net::TcpListener> listener = net::TcpListener::open({.address = kLoopback, .port = 0});
    context.expect(listener.has_value(), "nghe được cổng");
    if (!listener) return;
    net::NetResult<net::Endpoint> local = listener->local();
    context.expect(local.has_value(), "đọc được cổng");
    if (!local) return;
    bool served = false;
    std::thread worker(peer, std::move(*listener), std::cref(*identity), std::ref(served));
    link::Link::HelloDesc desc;
    desc.peer = *local;
    desc.server = identity->public_key();
    desc.timeout = net::Milliseconds{3000};
    const link::LinkResult<link::Link> session = link::Link::open(desc);
    worker.join();
    context.expect(session.has_value(), "client nhận Welcome");
    if (!session) return;
    context.expect(session->welcome().version == protocol::kVersion, "đúng phiên bản");
    context.expect(served, "phía nghe gửi xong");
}

} // namespace

const std::array kCases{Case{.name = "link_receives_welcome", .body = &link_receives_welcome}};

} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "link_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "link_tests: mọi ca phải qua");
    return 0;
}
