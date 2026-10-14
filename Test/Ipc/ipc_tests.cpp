// Kênh ipc bền trên loopback thật (cổng 0): thứ tự khung, hai chiều, khung lớn nhất, trần hàng gửi,
// sai khoá và byte rác làm kênh hỏng. Chờ bằng đếm vòng, không ngủ theo giờ.
#include "core/check.hpp"
#include "ipc/link.hpp"
#include "net/net.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using ipc::Frame;
using ipc::Link;
using ipc::LinkState;

constexpr net::Endpoint kAny{.address = {127, 0, 0, 1}, .port = 0};
constexpr net::Milliseconds kLimit{5000};
constexpr int kRounds = 4000;

struct Pair {
    Link client;
    Link server;
};

[[nodiscard]] std::array<std::byte, ipc::kKeyBytes> key_of(std::uint8_t seed) {
    std::array<std::byte, ipc::kKeyBytes> key{};
    for (std::size_t index = 0; index < key.size(); ++index) {
        key[index] = static_cast<std::byte>(seed + index);
    }
    return key;
}

[[nodiscard]] std::optional<Pair> open_pair(const std::array<std::byte, ipc::kKeyBytes>& client_key,
    const std::array<std::byte, ipc::kKeyBytes>& server_key) {
    net::NetResult<net::TcpListener> listener = net::TcpListener::open(kAny);
    if (!listener) return std::nullopt;
    const net::NetResult<net::Endpoint> where = listener->local();
    if (!where) return std::nullopt;
    std::optional<Link> client = Link::connect(*where, client_key, kLimit);
    if (!client) return std::nullopt;
    for (int round = 0; round < kRounds; ++round) {
        net::NetResult<std::optional<net::Accepted>> got = listener->accept();
        if (!got) return std::nullopt;
        if (got->has_value()) return Pair{std::move(*client), Link(std::move((*got)->stream), server_key)};
    }
    return std::nullopt;
}

// Bơm cả hai đầu tới khi `want` khung tới `receiver`, hoặc hết vòng.
[[nodiscard]] std::vector<Frame> drain(Link& sender, Link& receiver, std::size_t want) {
    std::vector<Frame> got;
    for (int round = 0; round < kRounds && got.size() < want; ++round) {
        static_cast<void>(sender.pump());
        static_cast<void>(receiver.pump());
        while (std::optional<Frame> frame = receiver.next()) {
            got.push_back(std::move(*frame));
        }
    }
    return got;
}

[[nodiscard]] std::vector<std::byte> bytes_of(std::size_t size, std::uint8_t fill) {
    return std::vector<std::byte>(size, static_cast<std::byte>(fill));
}

void frames_arrive_in_order_both_ways(Context& context) {
    const auto key = key_of(1);
    auto pair = open_pair(key, key);
    context.expect(pair.has_value(), "dựng được cặp kênh");
    if (!pair) return;
    for (std::uint16_t kind = 1; kind <= 50; ++kind) {
        const auto body = bytes_of(kind, static_cast<std::uint8_t>(kind));
        context.expect(pair->client.send(kind, 0x1122334455667788ULL + kind, body), "gửi được");
    }
    const std::vector<Frame> got = drain(pair->client, pair->server, 50);
    context.expect(got.size() == 50, "đủ 50 khung");
    for (std::size_t index = 0; index < got.size(); ++index) {
        context.expect(got[index].kind == index + 1, "đúng thứ tự gửi");
        context.expect(got[index].session == 0x1122334455667788ULL + index + 1, "session nguyên vẹn");
        context.expect(got[index].body == bytes_of(index + 1, static_cast<std::uint8_t>(index + 1)), "thân nguyên vẹn");
    }
    context.expect(pair->server.send(0x8001, 7, {}), "chiều ngược: thân rỗng");
    const std::vector<Frame> back = drain(pair->server, pair->client, 1);
    context.expect(back.size() == 1 && back[0].kind == 0x8001 && back[0].session == 7 && back[0].body.empty(),
        "chiều ngược tới");
}

void largest_body_and_oversize(Context& context) {
    const auto key = key_of(2);
    auto pair = open_pair(key, key);
    context.expect(pair.has_value(), "dựng được cặp kênh");
    if (!pair) return;
    const auto biggest = bytes_of(ipc::kBodyMax, 0xAB);
    context.expect(pair->client.send(9, 1, biggest), "thân lớn nhất gửi được");
    context.expect(!pair->client.send(9, 1, bytes_of(ipc::kBodyMax + 1, 0)), "thân quá trần bị từ chối");
    const std::vector<Frame> got = drain(pair->client, pair->server, 1);
    context.expect(got.size() == 1 && got[0].body == biggest, "khung lớn nhất tới nguyên vẹn");
}

void outbox_has_a_ceiling(Context& context) {
    const auto key = key_of(3);
    auto pair = open_pair(key, key);
    context.expect(pair.has_value(), "dựng được cặp kênh");
    if (!pair) return;
    const auto body = bytes_of(ipc::kBodyMax, 1);
    std::size_t accepted = 0;
    while (pair->client.send(1, 1, body)) {
        ++accepted;
        if (accepted > ipc::kOutboxMax) break;
    }
    context.expect(accepted > 0 && accepted <= ipc::kOutboxMax / ipc::kBodyMax, "hàng gửi dừng ở trần");
}

void wrong_key_breaks_the_receiver(Context& context) {
    auto pair = open_pair(key_of(4), key_of(5));
    context.expect(pair.has_value(), "dựng được cặp kênh");
    if (!pair) return;
    context.expect(pair->client.send(1, 1, bytes_of(8, 1)), "gửi được");
    LinkState state = LinkState::kUp;
    for (int round = 0; round < kRounds && state == LinkState::kUp; ++round) {
        static_cast<void>(pair->client.pump());
        state = pair->server.pump();
    }
    context.expect(state == LinkState::kBroken, "sai khoá: kênh nhận hỏng");
    context.expect(!pair->server.next().has_value(), "không có khung nào lọt");
}

void hostile_length_breaks_the_receiver(Context& context) {
    const auto key = key_of(6);
    net::NetResult<net::TcpListener> listener = net::TcpListener::open(kAny);
    context.expect(listener.has_value(), "mở cổng nghe");
    if (!listener) return;
    const net::NetResult<net::Endpoint> where = listener->local();
    net::NetResult<net::TcpStream> raw = net::TcpStream::begin_connect(*where);
    context.expect(raw.has_value(), "nối thô");
    if (!raw) return;
    std::optional<Link> server;
    for (int round = 0; round < kRounds && !server; ++round) {
        static_cast<void>(raw->finish_connect());
        net::NetResult<std::optional<net::Accepted>> got = listener->accept();
        if (got && got->has_value()) server.emplace(std::move((*got)->stream), key);
    }
    context.expect(server.has_value(), "nhận được kết nối");
    if (!server) return;
    // Độ dài khai 0xFFFFFFFF: cấp phát theo số này là cửa cho kẻ tấn công.
    constexpr std::array<std::byte, 4> kHuge{std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}};
    std::size_t sent = 0;
    for (int round = 0; round < kRounds && sent < kHuge.size(); ++round) {
        const net::NetResult<std::size_t> wrote = raw->send(std::span<const std::byte>{kHuge}.subspan(sent));
        if (wrote) sent += *wrote;
    }
    LinkState state = LinkState::kUp;
    for (int round = 0; round < kRounds && state == LinkState::kUp; ++round) {
        state = server->pump();
    }
    context.expect(state == LinkState::kBroken, "độ dài khổng lồ làm kênh hỏng");
}

void peer_close_is_reported(Context& context) {
    const auto key = key_of(7);
    auto pair = open_pair(key, key);
    context.expect(pair.has_value(), "dựng được cặp kênh");
    if (!pair) return;
    context.expect(pair->client.send(2, 3, bytes_of(4, 4)), "gửi được");
    for (int round = 0; round < 50; ++round) {
        static_cast<void>(pair->client.pump());
    }
    { Link gone = std::move(pair->client); }
    std::size_t frames = 0;
    LinkState state = LinkState::kUp;
    for (int round = 0; round < kRounds && state == LinkState::kUp; ++round) {
        state = pair->server.pump();
        while (pair->server.next()) ++frames;
    }
    context.expect(state == LinkState::kClosed || state == LinkState::kBroken, "đóng được phát hiện");
    context.expect(frames == 1, "khung gửi trước khi đóng vẫn tới");
}

constexpr std::array kCases{
    Case{"frames_arrive_in_order_both_ways", frames_arrive_in_order_both_ways},
    Case{"largest_body_and_oversize", largest_body_and_oversize},
    Case{"outbox_has_a_ceiling", outbox_has_a_ceiling},
    Case{"wrong_key_breaks_the_receiver", wrong_key_breaks_the_receiver},
    Case{"hostile_length_breaks_the_receiver", hostile_length_breaks_the_receiver},
    Case{"peer_close_is_reported", peer_close_is_reported},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    if (!network) return 2;
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
