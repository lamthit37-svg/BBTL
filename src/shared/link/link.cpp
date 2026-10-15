#include "link/link.hpp"

#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <stop_token>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

namespace game::link {
namespace {

using Clock = std::chrono::steady_clock;

constexpr std::uint64_t kSocket = 1;

// Mỗi lần chờ socket không quá kCancelSlice khi hạn có thể bị huỷ, để yêu cầu dừng được thấy kịp.
constexpr net::Milliseconds kCancelSlice{50};

struct Deadline {
    Clock::time_point at;
    std::stop_token stop{};

    [[nodiscard]] bool late() const noexcept { return stop.stop_requested() || Clock::now() >= at; }

    [[nodiscard]] net::Milliseconds left() const noexcept {
        const auto rest = std::chrono::duration_cast<net::Milliseconds>(at - Clock::now());
        const net::Milliseconds floor{1};
        const net::Milliseconds capped = stop.stop_possible() ? std::min(rest, kCancelSlice) : rest;
        return std::max(capped, floor);
    }
};

[[nodiscard]] LinkResult<std::size_t> take_send(net::TcpStream& stream, std::span<const std::byte> data) {
    const net::NetResult<std::size_t> sent = stream.send(data);
    if (!sent) return std::unexpected(LinkError::kNetwork);
    return *sent;
}

// Các hàm trả std::optional<LinkError> dùng nullopt cho "xong, không lỗi": LinkError không có giá trị 0.
[[nodiscard]] std::optional<LinkError> send_all(net::TcpStream& stream, net::PollSet& poll,
    std::span<const std::byte> data, const Deadline& deadline) {
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
    return std::nullopt;
}

[[nodiscard]] std::optional<LinkError> recv_some(net::TcpStream& stream, net::PollSet& poll,
    std::vector<std::byte>& inbox, const Deadline& deadline) {
    if (deadline.late()) return LinkError::kTimeout;
    std::array<std::byte, 2048> chunk{};
    const net::NetResult<std::size_t> got = stream.receive(chunk);
    if (!got) return LinkError::kNetwork;
    if (*got > 0) {
        inbox.insert(inbox.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
        // Peer flood: vượt trần thì đóng với kSecure, như gate đóng khi held tràn.
        if (inbox.size() > kMaxInboxBytes) return LinkError::kSecure;
        return std::nullopt;
    }
    net::PollEvents events;
    if (!poll.wait(deadline.left(), events)) return LinkError::kNetwork;
    return std::nullopt;
}

[[nodiscard]] std::optional<LinkError> fill_to(net::TcpStream& stream, net::PollSet& poll,
    std::vector<std::byte>& inbox, std::size_t need, const Deadline& deadline) {
    while (inbox.size() < need) {
        if (const std::optional<LinkError> more = recv_some(stream, poll, inbox, deadline)) return more;
    }
    return std::nullopt;
}

[[nodiscard]] LinkResult<net::TcpStream> connect_to(net::Endpoint peer, net::PollSet& poll, const Deadline& deadline) {
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
    const Deadline& deadline) {
    secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
    if (!client) return std::unexpected(LinkError::kSecure);
    const secure::ByteView hello = client->hello();
    if (const std::optional<LinkError> sent = send_all(stream, poll, hello, deadline)) return std::unexpected(*sent);
    std::vector<std::byte> inbox;
    if (const std::optional<LinkError> filled = fill_to(stream, poll, inbox, secure::kServerHelloBytes, deadline)) {
        return std::unexpected(*filled);
    }
    const secure::ByteView reply{inbox.data(), secure::kServerHelloBytes};
    secure::Result<secure::SessionKeys> keys = client->finish(reply, server);
    if (!keys) return std::unexpected(LinkError::kSecure);
    return secure::RecordPipe{std::move(*keys)};
}

[[nodiscard]] std::optional<LinkError> seal_send(net::TcpStream& stream, net::PollSet& poll, secure::RecordPipe& pipe,
    std::span<const std::byte> plain, const Deadline& deadline) {
    std::array<std::byte, secure::kMaxRecordBytes> record{};
    const secure::SealResult wrote = pipe.seal(plain, record);
    if (!wrote) return LinkError::kSecure;
    return send_all(stream, poll, std::span{record}.first(*wrote), deadline);
}

[[nodiscard]] LinkResult<std::vector<std::byte>> open_one(net::TcpStream& stream, net::PollSet& poll,
    secure::RecordPipe& pipe, const Deadline& deadline) {
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
        if (const std::optional<LinkError> more = recv_some(stream, poll, inbox, deadline)) {
            return std::unexpected(*more);
        }
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
    const Deadline deadline{.at = Clock::now() + desc.timeout, .stop = desc.stop};
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
    if (const std::optional<LinkError> sealed = seal_send(*stream, poll, *pipe, plain, deadline)) {
        return std::unexpected(*sealed);
    }
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
    if (const std::optional<LinkError> sealed = seal_send(stream_, poll, pipe_, frame, deadline)) {
        return std::unexpected(*sealed);
    }
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
        const std::optional<LinkError> more = recv_some(stream_, poll, inbox_, deadline);
        if (more && *more != LinkError::kTimeout) return std::unexpected(*more);
    }
}

} // namespace game::link
