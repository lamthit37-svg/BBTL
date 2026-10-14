#include "link/link.hpp"

#include "protocol/wire.hpp"

#include <array>
#include <span>
#include <utility>
#include <vector>

namespace game::link {
namespace {

using Clock = std::chrono::steady_clock;

constexpr std::uint64_t kSocket = 1;

struct Deadline {
    Clock::time_point at;

    [[nodiscard]] bool late() const noexcept { return Clock::now() >= at; }

    [[nodiscard]] net::Milliseconds left() const noexcept {
        const auto rest = std::chrono::duration_cast<net::Milliseconds>(at - Clock::now());
        if (rest.count() < 1) return net::Milliseconds{1};
        return rest;
    }
};

[[nodiscard]] LinkResult<std::size_t> take_send(net::TcpStream& stream, std::span<const std::byte> data) {
    const net::NetResult<std::size_t> sent = stream.send(data);
    if (!sent) return std::unexpected(LinkError::kNetwork);
    return *sent;
}

[[nodiscard]] LinkError send_all(net::TcpStream& stream, net::PollSet& poll, std::span<const std::byte> data,
    Deadline deadline) {
    std::size_t sent = 0;
    while (sent < data.size()) {
        if (deadline.late()) return LinkError::kTimeout;
        const LinkResult<std::size_t> step = take_send(stream, data.subspan(sent));
        if (!step) return step.error();
        if (*step > 0) {
            sent += *step;
            continue;
        }
        poll.want_write(kSocket, true);
        net::PollEvents events;
        if (!poll.wait(deadline.left(), events)) return LinkError::kNetwork;
    }
    poll.want_write(kSocket, false);
    return {};
}

[[nodiscard]] LinkError recv_some(net::TcpStream& stream, net::PollSet& poll, std::vector<std::byte>& inbox,
    Deadline deadline) {
    if (deadline.late()) return LinkError::kTimeout;
    std::array<std::byte, 2048> chunk{};
    const net::NetResult<std::size_t> got = stream.receive(chunk);
    if (!got) return LinkError::kNetwork;
    if (*got > 0) {
        inbox.insert(inbox.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
        return {};
    }
    net::PollEvents events;
    if (!poll.wait(deadline.left(), events)) return LinkError::kNetwork;
    return {};
}

[[nodiscard]] LinkError fill_to(net::TcpStream& stream, net::PollSet& poll, std::vector<std::byte>& inbox,
    std::size_t need, Deadline deadline) {
    while (inbox.size() < need) {
        const LinkError more = recv_some(stream, poll, inbox, deadline);
        if (more != LinkError{}) return more;
    }
    return {};
}

[[nodiscard]] LinkResult<net::TcpStream> connect_to(net::Endpoint peer, net::PollSet& poll, Deadline deadline) {
    net::NetResult<net::TcpStream> stream = net::TcpStream::begin_connect(peer);
    if (!stream) return std::unexpected(LinkError::kNetwork);
    if (!poll.add(stream->handle(), kSocket)) return std::unexpected(LinkError::kNetwork);
    poll.want_write(kSocket, true);
    while (true) {
        if (deadline.late()) return std::unexpected(LinkError::kTimeout);
        const net::NetResult<bool> done = stream->finish_connect();
        if (!done) return std::unexpected(LinkError::kNetwork);
        if (*done) break;
        net::PollEvents events;
        if (!poll.wait(deadline.left(), events)) return std::unexpected(LinkError::kNetwork);
    }
    poll.want_write(kSocket, false);
    return std::move(*stream);
}

[[nodiscard]] LinkResult<secure::RecordPipe> shake(net::TcpStream& stream, net::PollSet& poll, secure::PublicKey server,
    Deadline deadline) {
    secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
    if (!client) return std::unexpected(LinkError::kSecure);
    const secure::ByteView hello = client->hello();
    const LinkError sent = send_all(stream, poll, hello, deadline);
    if (sent != LinkError{}) return std::unexpected(sent);
    std::vector<std::byte> inbox;
    const LinkError filled = fill_to(stream, poll, inbox, secure::kServerHelloBytes, deadline);
    if (filled != LinkError{}) return std::unexpected(filled);
    const secure::ByteView reply{inbox.data(), secure::kServerHelloBytes};
    secure::Result<secure::SessionKeys> keys = client->finish(reply, server);
    if (!keys) return std::unexpected(LinkError::kSecure);
    return secure::RecordPipe{std::move(*keys)};
}

[[nodiscard]] LinkError seal_send(net::TcpStream& stream, net::PollSet& poll, secure::RecordPipe& pipe,
    std::span<const std::byte> plain, Deadline deadline) {
    std::array<std::byte, secure::kMaxRecordBytes> record{};
    const secure::SealResult wrote = pipe.seal(plain, record);
    if (!wrote) return LinkError::kSecure;
    return send_all(stream, poll, std::span{record}.first(*wrote), deadline);
}

[[nodiscard]] LinkResult<std::vector<std::byte>> open_one(net::TcpStream& stream, net::PollSet& poll,
    secure::RecordPipe& pipe, Deadline deadline) {
    std::vector<std::byte> inbox;
    std::array<std::byte, secure::kMaxPlainBytes> plain{};
    while (true) {
        if (deadline.late()) return std::unexpected(LinkError::kTimeout);
        const secure::ByteView input{inbox.data(), inbox.size()};
        const secure::OpenResult opened = pipe.open_bytes(input, plain);
        if (!opened) return std::unexpected(LinkError::kSecure);
        if (opened->consumed > 0)
            inbox.erase(inbox.begin(), inbox.begin() + static_cast<std::ptrdiff_t>(opened->consumed));
        if (opened->written > 0)
            return std::vector<std::byte>(plain.begin(), plain.begin() + static_cast<std::ptrdiff_t>(opened->written));
        const LinkError more = recv_some(stream, poll, inbox, deadline);
        if (more != LinkError{}) return std::unexpected(more);
    }
}

[[nodiscard]] LinkResult<protocol::Welcome> read_welcome(std::span<const std::byte> plain) {
    const protocol::ByteView bytes{plain.data(), plain.size()};
    const protocol::FrameResult frame = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!frame || !frame->has_value()) return std::unexpected(LinkError::kProtocol);
    const protocol::Frame header = **frame;
    if (plain.size() < protocol::kHeaderBytes + header.body_bytes) return std::unexpected(LinkError::kProtocol);
    const protocol::ByteView body = bytes.subspan(protocol::kHeaderBytes, header.body_bytes);
    const protocol::GameServerResult decoded = protocol::decode_game_server(header, body);
    if (!decoded) return std::unexpected(LinkError::kProtocol);
    const protocol::Welcome* welcome = std::get_if<protocol::Welcome>(&*decoded);
    if (welcome == nullptr) return std::unexpected(LinkError::kProtocol);
    return *welcome;
}

} // namespace

std::string_view describe(LinkError error) noexcept {
    switch (error) {
    case LinkError::kNetwork: return "lỗi mạng";
    case LinkError::kSecure: return "bắt tay hoặc bản ghi hỏng";
    case LinkError::kProtocol: return "khung tin không đúng";
    case LinkError::kTimeout: return "hết hạn nối";
    }
    return "lỗi nối";
}

Link::Link(net::TcpStream stream, secure::RecordPipe pipe, protocol::Welcome welcome)
    : stream_(std::move(stream)), pipe_(std::move(pipe)), welcome_(welcome) {}

Link::~Link() = default;

Link::Link(Link&& other) noexcept = default;

Link& Link::operator=(Link&& other) noexcept = default;

LinkResult<Link> Link::open(const HelloDesc& desc) {
    const Deadline deadline{.at = Clock::now() + desc.timeout};
    net::PollSet poll;
    LinkResult<net::TcpStream> stream = connect_to(desc.peer, poll, deadline);
    if (!stream) return std::unexpected(stream.error());
    LinkResult<secure::RecordPipe> pipe = shake(*stream, poll, desc.server, deadline);
    if (!pipe) return std::unexpected(pipe.error());
    protocol::Hello hello;
    hello.version = protocol::kVersion;
    hello.platform = desc.platform;
    hello.build = desc.build;
    std::vector<std::byte> plain;
    if (!protocol::encode(plain, hello)) return std::unexpected(LinkError::kProtocol);
    const LinkError sealed = seal_send(*stream, poll, *pipe, plain, deadline);
    if (sealed != LinkError{}) return std::unexpected(sealed);
    const LinkResult<std::vector<std::byte>> opened = open_one(*stream, poll, *pipe, deadline);
    if (!opened) return std::unexpected(opened.error());
    LinkResult<protocol::Welcome> welcome = read_welcome(*opened);
    if (!welcome) return std::unexpected(welcome.error());
    return Link{std::move(*stream), std::move(*pipe), *welcome};
}

LinkResult<void> Link::send_frame(std::span<const std::byte> frame, net::Milliseconds timeout) {
    const Deadline deadline{.at = Clock::now() + timeout};
    net::PollSet poll;
    if (!poll.add(stream_.handle(), kSocket)) return std::unexpected(LinkError::kNetwork);
    const LinkError sealed = seal_send(stream_, poll, pipe_, frame, deadline);
    if (sealed != LinkError{}) return std::unexpected(sealed);
    return {};
}

LinkResult<std::vector<std::byte>> Link::receive_frame(net::Milliseconds timeout) {
    const Deadline deadline{.at = Clock::now() + timeout};
    net::PollSet poll;
    if (!poll.add(stream_.handle(), kSocket)) return std::unexpected(LinkError::kNetwork);
    std::array<std::byte, secure::kMaxPlainBytes> plain{};
    while (true) {
        const secure::ByteView input{inbox_.data(), inbox_.size()};
        const secure::OpenResult opened = pipe_.open_bytes(input, plain);
        if (!opened) return std::unexpected(LinkError::kSecure);
        if (opened->consumed > 0) {
            inbox_.erase(inbox_.begin(), inbox_.begin() + static_cast<std::ptrdiff_t>(opened->consumed));
        }
        if (opened->written > 0) {
            const auto end = plain.begin() + static_cast<std::ptrdiff_t>(opened->written);
            return std::vector<std::byte>(plain.begin(), end);
        }
        if (opened->consumed > 0) continue;
        if (deadline.late()) return std::unexpected(LinkError::kTimeout);
        const LinkError more = recv_some(stream_, poll, inbox_, deadline);
        if (more != LinkError{} && more != LinkError::kTimeout) return std::unexpected(more);
    }
}

LinkResult<protocol::Pong> Link::ping(std::chrono::milliseconds client_time, net::Milliseconds timeout) {
    const Deadline deadline{.at = Clock::now() + timeout};
    net::PollSet poll;
    if (!poll.add(stream_.handle(), kSocket)) return std::unexpected(LinkError::kNetwork);
    protocol::Ping ping;
    ping.client_time = client_time;
    std::vector<std::byte> plain;
    if (!protocol::encode(plain, ping)) return std::unexpected(LinkError::kProtocol);
    const LinkError sealed = seal_send(stream_, poll, pipe_, plain, deadline);
    if (sealed != LinkError{}) return std::unexpected(sealed);
    const LinkResult<std::vector<std::byte>> opened = open_one(stream_, poll, pipe_, deadline);
    if (!opened) return std::unexpected(opened.error());
    const protocol::ByteView bytes{opened->data(), opened->size()};
    const protocol::FrameResult frame = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!frame || !frame->has_value()) return std::unexpected(LinkError::kProtocol);
    const protocol::Frame header = **frame;
    const protocol::ByteView body = bytes.subspan(protocol::kHeaderBytes, header.body_bytes);
    const protocol::GameServerResult decoded = protocol::decode_game_server(header, body);
    if (!decoded) return std::unexpected(LinkError::kProtocol);
    const protocol::Pong* pong = std::get_if<protocol::Pong>(&*decoded);
    if (pong == nullptr) return std::unexpected(LinkError::kProtocol);
    return *pong;
}

} // namespace game::link
