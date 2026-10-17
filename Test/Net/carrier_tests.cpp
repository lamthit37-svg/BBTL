// Carrier: tin cậy, mất gói, lane, và UDP loopback. Không ngủ theo đồng hồ tường.
#include "core/check.hpp"
#include "net/carrier.hpp"
#include "net/net.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using net::Carrier;
using net::CarrierMessage;
using net::Delivery;
using net::Endpoint;
using net::UdpSocket;

constexpr net::Ipv4 kLoopback{127, 0, 0, 1};
constexpr std::uint64_t kNow = 0;

[[nodiscard]] std::span<const std::byte> bytes_of(std::string_view text) noexcept {
    return std::as_bytes(std::span{text.data(), text.size()});
}

[[nodiscard]] std::uint16_t packet_number(std::span<const std::byte> packet) noexcept {
    if (packet.size() < 4) return 0;
    const auto lo = static_cast<std::uint16_t>(packet[2]);
    const auto hi = static_cast<std::uint16_t>(packet[3]);
    return static_cast<std::uint16_t>(lo | static_cast<std::uint16_t>(hi << 8U));
}

struct Packet {
    std::vector<std::byte> bytes;
};

void pull_all(Carrier& from, std::vector<Packet>& out, std::uint64_t now) {
    std::array<std::byte, net::kCarrierPacketBytes> buf{};
    std::size_t written = 0;
    while (from.write_packet(buf, written, now)) {
        Packet packet;
        packet.bytes.assign(buf.begin(), buf.begin() + static_cast<std::ptrdiff_t>(written));
        out.push_back(std::move(packet));
    }
}

void deliver(Carrier& to, const Packet& packet, std::uint64_t now) {
    static_cast<void>(to.read_packet(packet.bytes, now));
}

void take_all(Carrier& carrier, std::vector<CarrierMessage>& out) {
    CarrierMessage message;
    while (carrier.take(message)) out.push_back(std::move(message));
}

void carrier_golden_hello(Context& context) {
    Carrier carrier;
    context.expect(carrier.send(0, Delivery::kReliable, bytes_of("hi")), "nhận tin");
    std::array<std::byte, net::kCarrierPacketBytes> out{};
    std::size_t written = 0;
    context.expect(carrier.write_packet(out, written, kNow), "có gói");
    constexpr std::array<unsigned, 20> gold{0x01, 0x02, 0x01, 0x00, 0x01, 0x00, 0x0c, 0x00, 0x01, 0x00,
        0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x68, 0x69};
    bool same = written == gold.size();
    for (std::size_t index = 0; index < gold.size() && same; ++index) {
        same = static_cast<unsigned>(out[index]) == gold[index];
    }
    context.expect(same, "khớp byte vàng");
    for (std::size_t cut = 0; cut < gold.size(); ++cut) {
        Carrier peer;
        const bool bad = !peer.read_packet(std::span<const std::byte>{out.data(), cut}, kNow);
        context.expect(bad, "tiền tố cụt là gói hỏng");
    }
}

void carrier_rejects_bad_send(Context& context) {
    Carrier carrier;
    const auto hello = bytes_of("hi");
    context.expect(!carrier.send(4, Delivery::kReliable, hello), "lane lạ");
    context.expect(!carrier.send(0, Delivery::kReliable, {}), "tin rỗng");
    std::vector<std::byte> huge(net::kCarrierMessageMax + 1);
    context.expect(!carrier.send(0, Delivery::kReliable, huge), "tin quá lớn");
}

void carrier_reliable_under_loss(Context& context) {
    Carrier sender;
    Carrier receiver;
    constexpr int kCount = 20;
    for (int index = 0; index < kCount; ++index) {
        std::array<std::byte, 100> body{};
        body[0] = static_cast<std::byte>(index);
        context.expect(sender.send(1, Delivery::kReliable, body), "xếp tin");
    }
    std::vector<CarrierMessage> got;
    for (int round = 0; round < 12 && static_cast<int>(got.size()) < kCount; ++round) {
        std::vector<Packet> batch;
        const std::uint64_t now = static_cast<std::uint64_t>(round) * 200U;
        pull_all(sender, batch, now);
        for (std::size_t index = batch.size(); index > 0; --index) {
            const std::size_t slot = index - 1;
            if (round == 0 && slot % 3 == 0) continue;
            deliver(receiver, batch[slot], now);
        }
        std::vector<Packet> acks;
        pull_all(receiver, acks, now);
        for (const Packet& ack : acks) deliver(sender, ack, now);
        take_all(receiver, got);
    }
    context.expect(static_cast<int>(got.size()) == kCount, "đủ tin sau mất gói");
    bool ordered = static_cast<int>(got.size()) == kCount;
    for (int index = 0; index < kCount && ordered; ++index) {
        ordered = got[static_cast<std::size_t>(index)].bytes[0] == static_cast<std::byte>(index);
    }
    context.expect(ordered, "thứ tự tin cậy giữ nguyên");
}

void carrier_unreliable_is_not_retried(Context& context) {
    Carrier sender;
    Carrier receiver;
    std::vector<std::byte> bulk(1024, std::byte{7});
    context.expect(sender.send(3, Delivery::kUnreliable, bulk), "xếp không tin cậy");
    std::vector<Packet> dropped;
    pull_all(sender, dropped, kNow);
    context.expect(!dropped.empty(), "đã phát một lần");
    std::vector<Packet> again;
    pull_all(sender, again, 5000);
    context.expect(again.empty(), "không gửi lại");
    const auto note = bytes_of("ok");
    context.expect(sender.send(0, Delivery::kReliable, note), "tin cậy lane 0");
    std::vector<Packet> live;
    pull_all(sender, live, 5000);
    for (const Packet& packet : live) deliver(receiver, packet, 5000);
    CarrierMessage message;
    context.expect(receiver.take(message), "nhận tin cậy");
    context.expect(message.lane == 0 && message.delivery == Delivery::kReliable, "đúng lane");
    context.expect(!receiver.take(message), "không có tin đã mất");
}

void carrier_lane_zero_goes_first(Context& context) {
    Carrier sender;
    std::vector<std::byte> slow(1024, std::byte{1});
    std::vector<std::byte> fast(1024, std::byte{2});
    context.expect(sender.send(3, Delivery::kReliable, slow), "lane thấp trước");
    context.expect(sender.send(0, Delivery::kReliable, fast), "lane cao sau");
    std::array<std::byte, net::kCarrierPacketBytes> out{};
    std::size_t written = 0;
    context.expect(sender.write_packet(out, written, kNow), "gói đầu");
    context.expect(written > 9 && out[9] == std::byte{0}, "gói đầu là lane 0");
}

void carrier_fast_retransmit(Context& context) {
    net::CarrierConfig config;
    config.min_rto_ms = 1000;
    config.max_rto_ms = 1000;
    Carrier sender{config};
    Carrier receiver{config};
    for (int index = 0; index < 5; ++index) {
        std::array<std::byte, 900> body{};
        body[0] = static_cast<std::byte>(index + 1);
        context.expect(sender.send(1, Delivery::kReliable, body), "xếp");
    }
    std::vector<Packet> batch;
    pull_all(sender, batch, kNow);
    context.expect(batch.size() >= 5, "năm gói");
    for (const Packet& packet : batch) {
        if (packet_number(packet.bytes) == 2) continue;
        deliver(receiver, packet, kNow);
    }
    std::vector<Packet> acks;
    pull_all(receiver, acks, kNow);
    for (const Packet& ack : acks) deliver(sender, ack, kNow);
    std::vector<Packet> again;
    pull_all(sender, again, kNow);
    bool resent = false;
    for (const Packet& packet : again) resent = resent || !packet.bytes.empty();
    context.expect(resent, "thiếu 3 gói thì gửi lại trước RTO");
}

void carrier_duplicate_once(Context& context) {
    Carrier sender;
    Carrier receiver;
    context.expect(sender.send(0, Delivery::kReliable, bytes_of("one")), "xếp");
    std::vector<Packet> batch;
    pull_all(sender, batch, kNow);
    context.expect(batch.size() == 1, "một gói");
    deliver(receiver, batch[0], kNow);
    deliver(receiver, batch[0], kNow);
    CarrierMessage message;
    context.expect(receiver.take(message) && message.bytes.size() == 3, "một tin");
    context.expect(!receiver.take(message), "gói trùng không giao lần hai");
    context.expect(!receiver.read_packet(std::span<const std::byte>{}, kNow), "gói rỗng hỏng");
}

void carrier_budget(Context& context) {
    Carrier carrier;
    std::array<std::byte, 1> one{std::byte{1}};
    int accepted = 0;
    for (int index = 0; index < 300; ++index) {
        if (!carrier.send(1, Delivery::kReliable, one)) break;
        ++accepted;
    }
    context.expect(accepted == 256, "trần 256 mảnh tin cậy");
    context.expect(!carrier.send(1, Delivery::kReliable, one), "hết ngân sách thì từ chối");
}

void udp_exchanges_datagram(Context& context) {
    const Endpoint any{.address = kLoopback, .port = 0};
    auto left = UdpSocket::open(any);
    auto right = UdpSocket::open(any);
    context.expect(left.has_value() && right.has_value(), "mở được UDP");
    if (!left || !right) return;
    const auto left_at = left->local();
    const auto right_at = right->local();
    context.expect(left_at.has_value() && right_at.has_value(), "có cổng");
    if (!left_at || !right_at) return;
    const auto payload = bytes_of("udp");
    const auto sent = left->send_to(*right_at, payload);
    context.expect(sent.has_value() && *sent == payload.size(), "gửi được");
    net::PollSet poll;
    net::PollEvents events;
    context.expect(poll.add(right->handle(), 1), "theo dõi");
    context.expect(poll.wait(net::Milliseconds{1000}, events).has_value(), "chờ");
    std::array<std::byte, 16> buf{};
    const auto got = right->receive_from(buf);
    context.expect(got.has_value() && got->has_value(), "nhận được");
    if (!got || !got->has_value()) return;
    context.expect(!got->value().truncated && got->value().size == 3, "đủ 3 byte");
    context.expect(got->value().from.port == left_at->port, "đúng cổng gửi");
    std::array<std::byte, 1> tiny{};
    context.expect(right->send_to(*left_at, payload).has_value(), "gửi gói dài");
    context.expect(poll.add(left->handle(), 2), "theo dõi bên kia");
    context.expect(poll.wait(net::Milliseconds{1000}, events).has_value(), "chờ gói dài");
    const auto trimmed = left->receive_from(tiny);
    context.expect(trimmed.has_value() && trimmed->has_value() && trimmed->value().truncated, "gói dài hơn sink thì bỏ");
}

constexpr std::array kCases{
    Case{.name = "carrier_golden_hello", .body = carrier_golden_hello},
    Case{.name = "carrier_rejects_bad_send", .body = carrier_rejects_bad_send},
    Case{.name = "carrier_reliable_under_loss", .body = carrier_reliable_under_loss},
    Case{.name = "carrier_unreliable_is_not_retried", .body = carrier_unreliable_is_not_retried},
    Case{.name = "carrier_lane_zero_goes_first", .body = carrier_lane_zero_goes_first},
    Case{.name = "carrier_fast_retransmit", .body = carrier_fast_retransmit},
    Case{.name = "carrier_duplicate_once", .body = carrier_duplicate_once},
    Case{.name = "carrier_budget", .body = carrier_budget},
    Case{.name = "udp_exchanges_datagram", .body = udp_exchanges_datagram},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "carrier_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "carrier_tests: mọi ca phải qua");
    return 0;
}
