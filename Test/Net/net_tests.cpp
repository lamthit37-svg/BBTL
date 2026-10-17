// Test của game::net trên loopback thật, cổng 0 để hệ điều hành chọn. Không ngủ theo giờ: mọi
// chỗ chờ đều là PollSet::wait có hạn; vòng lặp đếm vòng, không đếm giờ.
// Nguồn: danh sách ca của TLBB Dev tests/platform/socket_test.cpp, viết lại không hàm ngủ.
#include "core/check.hpp"
#include "net/net.hpp"
#include "net/reactor.hpp"
#include "net/shard.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using net::Accepted;
using net::Endpoint;
using net::Milliseconds;
using net::NetError;
using net::PollEvents;
using net::PollSet;
using net::SocketHandle;
using net::TcpListener;
using net::TcpStream;
using net::ZeroPort;

constexpr net::Ipv4 kLoopback{127, 0, 0, 1};
constexpr Endpoint kAnyLoopbackPort{.address = kLoopback, .port = 0};
constexpr Milliseconds kReadyLimit{5000};
// Windows thử lại SYN bị từ chối vài lần trước khi báo lỗi: hạn rộng hơn.
constexpr Milliseconds kRefuseLimit{10000};
constexpr Milliseconds kIdleLimit{50};
constexpr std::size_t kBulkBytes = std::size_t{8} << 20U;
constexpr std::size_t kSlowChunk = 4096;
constexpr std::size_t kMaxRounds = 200000;
constexpr std::size_t kCrowd = 200;
constexpr std::uint64_t kFnvBasis = 14695981039346656037ULL;
constexpr std::uint64_t kFnvPrime = 1099511628211ULL;

using Count = net::NetResult<std::size_t>;
using Place = net::NetResult<Endpoint>;
using Pending = net::NetResult<std::optional<Accepted>>;

// Khi không có listener để hỏi: lỗi, không phải giá trị mặc định (NetResult rỗng là có giá trị).
const Place kNoPlace{std::unexpected(NetError::kSocket)};

struct Pair {
    TcpStream client;
    TcpStream server;
    Endpoint peer;
};

[[nodiscard]] Pending no_pending() noexcept {
    return std::unexpected(NetError::kSocket);
}

[[nodiscard]] std::span<const std::byte> bytes_of(std::string_view text) noexcept {
    return std::as_bytes(std::span{text.data(), text.size()});
}

// Một socket, một lần chờ có hạn: true khi socket có sự kiện trước hạn.
[[nodiscard]] bool wait_ready(SocketHandle socket, bool write, Milliseconds limit) {
    PollSet poll;
    PollEvents events;
    if (!poll.add(socket, 1)) return false;
    poll.want_write(1, write);
    return poll.wait(limit, events).has_value() && !events.empty();
}

[[nodiscard]] std::optional<TcpListener> open_listener() noexcept {
    auto listener = TcpListener::open(kAnyLoopbackPort);
    if (!listener) return std::nullopt;
    return std::move(*listener);
}

[[nodiscard]] std::optional<Accepted> accept_ready(TcpListener& listener) {
    if (!wait_ready(listener.handle(), false, kReadyLimit)) return std::nullopt;
    auto accepted = listener.accept();
    if (!accepted) return std::nullopt;
    return std::move(*accepted);
}

// Nối một client tới listener và nhận nó ở phía máy chủ.
[[nodiscard]] std::optional<Pair> connect_pair(TcpListener& listener) {
    const auto target = listener.local();
    if (!target) return std::nullopt;
    auto client = TcpStream::begin_connect(*target);
    if (!client) return std::nullopt;
    auto accepted = accept_ready(listener);
    if (!accepted || !wait_ready(client->handle(), true, kReadyLimit)) return std::nullopt;
    const auto done = client->finish_connect();
    if (!done || !*done) return std::nullopt;
    return Pair{.client = std::move(*client),
        .server = std::move(accepted->stream),
        .peer = accepted->peer};
}

[[nodiscard]] std::optional<Pair> loopback_pair(Context& context) {
    auto listener = open_listener();
    context.expect(listener.has_value(), "mở được cổng nghe loopback");
    auto pair = listener ? connect_pair(*listener) : std::nullopt;
    context.expect(pair.has_value(), "nối được một cặp loopback");
    return pair;
}

[[nodiscard]] NetError error_of(const Count& result) noexcept {
    return result.error_or(NetError::kStartup);
}

// Chờ có byte rồi nhận một lần.
[[nodiscard]] Count receive_ready(TcpStream& stream, std::span<std::byte> sink) {
    static_cast<void>(wait_ready(stream.handle(), false, kReadyLimit));
    return stream.receive(sink);
}

[[nodiscard]] std::uint64_t fnv(std::uint64_t hash, std::span<const std::byte> data) noexcept {
    for (const std::byte one : data) {
        hash = (hash ^ std::to_integer<std::uint64_t>(one)) * kFnvPrime;
    }
    return hash;
}

struct Good {
    std::string_view text;
    ZeroPort zero;
    Endpoint want;
};

void endpoint_parses_valid(Context& context) {
    constexpr std::array kGood{
        Good{.text = "127.0.0.1:7000",
            .zero = ZeroPort::kRefuse,
            .want = Endpoint{.address = kLoopback, .port = 7000}},
        Good{.text = "0.0.0.0:7000",
            .zero = ZeroPort::kRefuse,
            .want = Endpoint{.address = {}, .port = 7000}},
        Good{.text = "255.255.255.255:65535",
            .zero = ZeroPort::kRefuse,
            .want = Endpoint{.address = {255, 255, 255, 255}, .port = 65535}},
        Good{.text = "10.20.30.40:1",
            .zero = ZeroPort::kRefuse,
            .want = Endpoint{.address = {10, 20, 30, 40}, .port = 1}},
        Good{.text = "127.0.0.1:0",
            .zero = ZeroPort::kAllow,
            .want = Endpoint{.address = kLoopback, .port = 0}},
    };
    for (const Good& one : kGood) {
        context.expect(net::parse_endpoint(one.text, one.zero) == one.want, one.text);
    }
}

void endpoint_rejects_invalid(Context& context) {
    constexpr std::array kBad{std::string_view{""}, std::string_view{"127.0.0.1"},
        std::string_view{"127.0.0.1:"}, std::string_view{":7000"}, std::string_view{"127.0.0.1:0"},
        std::string_view{"127.0.0.1:65536"}, std::string_view{"127.0.0.1:99999"},
        std::string_view{"127.0.0.1:123456"}, std::string_view{"localhost:7000"},
        std::string_view{"::1:7000"}, std::string_view{"[::1]:7000"}, std::string_view{"1.2.3:80"},
        std::string_view{"1.2.3.4.5:80"}, std::string_view{"256.1.1.1:80"},
        std::string_view{"127.0.0.1:80x"}, std::string_view{"127.0.0.1:-1"},
        std::string_view{"127.0.0.1:+80"}, std::string_view{" 127.0.0.1:80"},
        std::string_view{"127.0.0.1: 80"}, std::string_view{"127.0.0.1\0:80", 13}};
    for (const std::string_view text : kBad) {
        context.expect(net::parse_endpoint(text, ZeroPort::kRefuse).error_or(NetError::kStartup) ==
                NetError::kAddress,
            text);
    }
}

void describe_covers_every_error(Context& context) {
    std::vector<std::string_view> seen;
    for (std::uint8_t value = 1; value <= static_cast<std::uint8_t>(NetError::kPoll); ++value) {
        seen.push_back(net::describe(static_cast<NetError>(value)));
    }
    std::ranges::sort(seen);
    context.expect(std::ranges::adjacent_find(seen) == seen.end(), "mỗi lỗi một câu riêng");
    context.expect(std::ranges::find(seen, std::string_view{}) == seen.end(), "không câu nào rỗng");
}

void listener_picks_port(Context& context) {
    auto listener = open_listener();
    const auto local = listener ? listener->local() : kNoPlace;
    context.expect(local.has_value() && local->port != 0, "cổng 0 được hệ điều hành chọn");
    context.expect(local.has_value() && local->address == kLoopback, "gắn đúng 127.0.0.1");
}

void listener_port_in_use_fails(Context& context) {
    auto first = open_listener();
    const auto local = first ? first->local() : kNoPlace;
    context.expect(local.has_value(), "cổng đầu mở được");
    const auto second = TcpListener::open(local.value_or(kAnyLoopbackPort));
    context.expect(!second && second.error() == NetError::kBind, "cổng đang dùng là kBind");
}

void accept_without_pending_returns_nothing(Context& context) {
    auto listener = open_listener();
    const auto accepted = listener ? listener->accept() : no_pending();
    context.expect(accepted.has_value() && !accepted->has_value(), "không ai chờ thì nullopt");
}

void accept_reports_peer(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    const auto client_local = pair->client.local();
    context.expect(client_local.has_value(), "đọc được địa chỉ phía client");
    context.expect(client_local == pair->peer, "accept trả đúng địa chỉ và cổng bên nối");
    context.expect(pair->peer.address == kLoopback && pair->peer.port != 0, "peer là loopback");
}

void connect_rejects_port_zero(Context& context) {
    const auto client = TcpStream::begin_connect(kAnyLoopbackPort);
    context.expect(!client && client.error() == NetError::kConnect, "nối tới cổng 0 là kConnect");
}

// Cổng vừa đóng: mở rồi huỷ listener, không ai nghe ở đó nữa.
[[nodiscard]] Endpoint closed_port() noexcept {
    const auto listener = open_listener();
    const auto local = listener ? listener->local() : kNoPlace;
    return local.value_or(kAnyLoopbackPort);
}

void connect_to_closed_port_fails(Context& context) {
    const Endpoint target = closed_port();
    context.expect(target.port != 0, "lấy được một cổng vừa đóng");
    auto client = TcpStream::begin_connect(target);
    context.expect(
        client.has_value() || client.error() == NetError::kConnect, "từ chối ngay là kConnect");
    if (!client) return;
    context.expect(wait_ready(client->handle(), true, kRefuseLimit), "lỗi nối được báo trong hạn");
    const auto done = client->finish_connect();
    context.expect(!done && done.error() == NetError::kConnect, "nối hỏng là kConnect");
}

void streams_set_nodelay(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    context.expect(pair->client.nodelay(), "client bật TCP_NODELAY");
    context.expect(pair->server.nodelay(), "luồng accept cũng bật TCP_NODELAY");
}

void receive_without_data_returns_zero(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    std::array<std::byte, 16> sink{};
    context.expect(pair->server.receive(sink) == std::size_t{0}, "chưa có byte thì 0");
    context.expect(pair->client.send({}) == std::size_t{0}, "gửi rỗng thì 0");
}

void peer_shutdown_gives_closed(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    context.expect(pair->client.send(bytes_of("hello")) == std::size_t{5}, "gửi đủ 5 byte");
    pair->client.shutdown_send();
    std::array<std::byte, 16> sink{};
    context.expect(receive_ready(pair->server, sink) == std::size_t{5}, "nhận đủ 5 byte trước FIN");
    context.expect(pair->server.receive({}) == std::size_t{0}, "sink rỗng thì 0, không gọi recv");
    context.expect(
        error_of(receive_ready(pair->server, sink)) == NetError::kClosed, "FIN là kClosed");
    context.expect(pair->server.send(bytes_of("bye")) == std::size_t{3}, "chiều kia vẫn gửi được");
    context.expect(receive_ready(pair->client, sink) == std::size_t{3}, "đóng một chiều vẫn nhận");
}

void peer_abort_gives_reset(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    pair->client.abort();
    context.expect(!pair->client.is_open(), "abort đóng luồng");
    std::array<std::byte, 16> sink{};
    context.expect(
        error_of(receive_ready(pair->server, sink)) == NetError::kReset, "RST là kReset");
}

void early_fin_keeps_bytes(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    context.expect(pair->client.send(bytes_of("ab")) == std::size_t{2}, "gửi hai byte");
    pair->client.shutdown_send();
    context.expect(wait_ready(pair->server.handle(), false, kReadyLimit), "FIN đã vào hàng");
    std::array<std::byte, 8> sink{};
    context.expect(pair->server.receive(sink) == std::size_t{2}, "FIN tới trước vẫn còn byte");
    context.expect(error_of(pair->server.receive(sink)) == NetError::kClosed, "hết byte thì đóng");
}

void early_reset_gives_reset(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    context.expect(pair->client.send(bytes_of("x")) == std::size_t{1}, "gửi một byte rồi RST");
    pair->client.abort();
    context.expect(wait_ready(pair->server.handle(), false, kReadyLimit), "RST đã vào hàng");
    std::array<std::byte, 8> sink{};
    const Count got = pair->server.receive(sink);
    const bool reset = !got && got.error() == NetError::kReset;
    const bool byte_then_reset = got == std::size_t{1} && error_of(pair->server.receive(sink)) == NetError::kReset;
    context.expect(reset || byte_then_reset, "RST sớm là kReset");
}

struct Transfer {
    std::span<const std::byte> data;
    std::size_t sent = 0;
    std::size_t received = 0;
    std::size_t stalls = 0;
    std::uint64_t hash = kFnvBasis;
    bool broken = false;
    std::array<std::byte, kSlowChunk> sink{};
};

// Gửi một mẩu; false khi phải chờ hoặc hỏng.
[[nodiscard]] bool push(Transfer& transfer, TcpStream& sender) noexcept {
    const auto sent = sender.send(transfer.data.subspan(transfer.sent));
    transfer.broken = !sent;
    if (!sent) return false;
    transfer.stalls += *sent == 0 ? std::size_t{1} : std::size_t{0};
    transfer.sent += *sent;
    return *sent != 0;
}

// Một vòng: bên gửi đẩy tới khi hệ điều hành bảo chờ, bên nhận chậm chỉ lấy một mẩu 4 KiB.
void pump(Transfer& transfer, Pair& pair) {
    while (transfer.sent < transfer.data.size() && push(transfer, pair.client)) {
    }
    const auto got = receive_ready(pair.server, transfer.sink);
    transfer.broken = transfer.broken || !got;
    if (!got) return;
    transfer.hash = fnv(transfer.hash, std::span{transfer.sink}.first(*got));
    transfer.received += *got;
}

[[nodiscard]] std::vector<std::byte> pattern(std::size_t size) {
    std::vector<std::byte> data(size);
    for (std::size_t index = 0; index < size; ++index) {
        data[index] = static_cast<std::byte>((index * 31U) ^ (index >> 13U));
    }
    return data;
}

void slow_reader_gets_eight_mib(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    const std::vector<std::byte> data = pattern(kBulkBytes);
    Transfer transfer{.data = data};
    for (std::size_t round = 0;
        round < kMaxRounds && !transfer.broken && transfer.received < data.size(); ++round)
        pump(transfer, *pair);
    context.expect(!transfer.broken, "không lỗi giữa chừng");
    context.expect(transfer.stalls > 0, "send trả 0 ít nhất một lần");
    context.expect(transfer.received == data.size(), "nhận đủ 8 MiB");
    context.expect(transfer.hash == fnv(kFnvBasis, data), "băm hai đầu trùng");
}

// Nhận mọi kết nối đang chờ, không chờ thêm.
void drain_accepts(TcpListener& listener, std::vector<Accepted>& accepted) {
    auto next = listener.accept();
    for (; next && *next; next = listener.accept()) {
        accepted.push_back(std::move(**next));
    }
}

void wait_and_drain(TcpListener& listener, std::vector<Accepted>& accepted) {
    static_cast<void>(wait_ready(listener.handle(), false, kReadyLimit));
    drain_accepts(listener, accepted);
}

[[nodiscard]] std::uint16_t finished_port(TcpStream& client) {
    static_cast<void>(wait_ready(client.handle(), true, kReadyLimit));
    const auto done = client.finish_connect();
    const auto local = client.local();
    return done.value_or(false) && local ? local->port : 0;
}

void accepts_two_hundred(Context& context) {
    auto listener = open_listener();
    const auto target = listener ? listener->local() : kNoPlace;
    context.expect(target.has_value(), "mở được cổng nghe");
    if (!listener || !target) return;
    std::vector<TcpStream> clients;
    std::vector<Accepted> accepted;
    clients.reserve(kCrowd);
    accepted.reserve(kCrowd);
    for (std::size_t index = 0; index < kCrowd; ++index) {
        auto client = TcpStream::begin_connect(*target);
        clients.push_back(client ? std::move(*client) : TcpStream{});
        drain_accepts(*listener, accepted);
    }
    for (std::size_t round = 0; round < kCrowd && accepted.size() < kCrowd; ++round) {
        wait_and_drain(*listener, accepted);
    }
    context.expect(accepted.size() == kCrowd, "nhận đủ 200 kết nối");
    std::vector<std::uint16_t> client_ports(clients.size());
    std::ranges::transform(clients, client_ports.begin(), finished_port);
    std::vector<std::uint16_t> peer_ports(accepted.size());
    std::ranges::transform(accepted, peer_ports.begin(), &Endpoint::port, &Accepted::peer);
    std::ranges::sort(client_ports);
    std::ranges::sort(peer_ports);
    context.expect(client_ports == peer_ports, "cổng peer khớp cổng của 200 client");
}

[[nodiscard]] bool has_tag(const PollEvents& events, std::uint64_t tag) noexcept {
    return std::ranges::any_of(events, [tag](const net::PollEvent& one) { return one.tag == tag; });
}

void poll_set_add_and_remove(Context& context) {
    auto first = open_listener();
    auto second = open_listener();
    auto third = open_listener();
    const bool opened = first && second && third;
    context.expect(opened, "mở được ba cổng nghe");
    if (!first || !second || !third) return;
    PollSet poll;
    context.expect(poll.add(first->handle(), 1), "thêm nhãn 1");
    context.expect(!poll.add(second->handle(), 1), "nhãn trùng bị từ chối");
    context.expect(!poll.add(net::kNoSocket, 9), "kNoSocket bị từ chối");
    context.expect(poll.add(second->handle(), 2) && poll.add(third->handle(), 3), "thêm nhãn 2, 3");
    poll.remove(2);
    poll.remove(42);
    context.expect(poll.size() == 2, "bỏ nhãn giữa còn hai, nhãn lạ không làm gì");
    const auto to_second = TcpStream::begin_connect(second->local().value_or(kAnyLoopbackPort));
    const auto to_third = TcpStream::begin_connect(third->local().value_or(kAnyLoopbackPort));
    context.expect(to_second.has_value() && to_third.has_value(), "nối tới hai cổng");
    PollEvents events;
    context.expect(poll.wait(kReadyLimit, events).has_value(), "chờ không lỗi");
    context.expect(has_tag(events, 3), "nhãn 3 dời chỗ vẫn báo đúng");
    context.expect(!has_tag(events, 2) && !has_tag(events, 1), "nhãn đã bỏ và nhãn rảnh im lặng");
}

void poll_set_toggles_write(Context& context) {
    auto pair = loopback_pair(context);
    if (!pair) return;
    PollSet poll;
    PollEvents events;
    context.expect(poll.add(pair->client.handle(), 7), "thêm client");
    context.expect(
        poll.wait(kIdleLimit, events).has_value() && events.empty(), "chưa quan tâm ghi thì im");
    poll.want_write(7, true);
    poll.want_write(99, true);
    context.expect(
        poll.wait(kReadyLimit, events).has_value() && has_tag(events, 7), "bật ghi thì báo");
    context.expect(events.size() == 1 && events.front().writable, "sự kiện là ghi được");
    poll.want_write(7, false);
    context.expect(
        poll.wait(kIdleLimit, events).has_value() && events.empty(), "tắt ghi thì im lại");
    poll.want_write(7, false);
    context.expect(poll.wait(kIdleLimit, events).has_value() && events.empty(), "tắt ghi thì im lại");
    context.expect(pair->server.send(bytes_of("x")) == std::size_t{1}, "máy chủ gửi một byte");
    context.expect(poll.wait(kReadyLimit, events).has_value() && events.size() == 1, "có byte thì báo");
    context.expect(!events.empty() && events.front().readable && !events.front().writable, "đọc được");
}

void spsc_preserves_order(Context& context) {
    constexpr std::uint32_t kCount = 100000;
    net::SpscMail<std::uint32_t, 1024> mail;
    std::jthread producer([&] {
        for (std::uint32_t index = 0; index < kCount; ++index) {
            std::uint32_t value = index;
            while (!mail.try_push(value)) {
            }
        }
    });
    std::uint32_t expect = 0;
    bool ordered = true;
    while (expect < kCount) {
        std::uint32_t value = 0;
        if (!mail.try_pop(value)) continue;
        if (value != expect) ordered = false;
        if (value != expect) break;
        ++expect;
    }
    producer.join();
    context.expect(ordered && expect == kCount, "hàng một chiều giữ đúng thứ tự");
}

void spsc_rejects_when_full(Context& context) {
    net::SpscMail<std::uint32_t, 8> mail;
    bool filled = true;
    for (std::uint32_t index = 0; index < 8; ++index) {
        std::uint32_t value = index;
        if (!mail.try_push(value)) filled = false;
    }
    std::uint32_t extra = 9;
    const bool refused = !mail.try_push(extra);
    std::uint32_t first = 0;
    const bool popped = mail.try_pop(first) && first == 0;
    const bool pushed = mail.try_push(extra);
    context.expect(filled && refused && popped && pushed, "đầy thì từ chối, có chỗ thì nhận");
}

void spsc_wakes_a_parked_taker(Context& context) {
    net::SpscMail<std::uint32_t, 8> mail;
    std::uint32_t value = 0;
    std::atomic<bool> popped{false};
    std::jthread taker([&] {
        mail.park([&] { return mail.empty(); });
        popped.store(mail.try_pop(value) && value == 7, std::memory_order_release);
    });
    std::uint32_t send = 7;
    while (!mail.try_push(send)) {
    }
    taker.join();
    context.expect(popped.load(std::memory_order_acquire), "bên nhận đang ngủ vẫn lấy được phần tử");
}

void lanes_prefer_login_then_share(Context& context) {
    constexpr std::array<net::LaneSpec, 3> specs{{
        {.priority = 0, .weight = 1},
        {.priority = 1, .weight = 4},
        {.priority = 1, .weight = 1},
    }};
    net::LaneQueue<int> queue;
    queue.reset(specs);
    queue.push(2, 2);
    queue.push(0, 0);
    std::array<int, 1> first{};
    context.expect(queue.pop(first) == 1 && first[0] == 0, "ưu tiên chặt lấy lane đăng nhập trước");
    for (int index = 0; index < 4000; ++index) {
        queue.push(1, 1);
        queue.push(2, 2);
    }
    int control = 0;
    int bulk = 0;
    std::array<int, 64> batch{};
    for (int step = 0; step < 8; ++step) {
        const std::size_t count = queue.pop(batch);
        for (std::size_t index = 0; index < count; ++index) {
            if (batch[index] == 1) ++control;
            if (batch[index] == 2) ++bulk;
        }
    }
    const bool early = control >= 350 && control <= 450 && bulk >= 60 && bulk <= 160;
    context.expect(early, "cùng mức ưu tiên thì trọng số 4 ăn khoảng bốn phần");
}

void reactor_accepts_and_echoes(Context& context) {
    auto listener = open_listener();
    context.expect(listener.has_value(), "mở được cổng");
    if (!listener) return;
    net::Reactor reactor;
    context.expect(reactor.watch_listener(*listener, 3), "gắn cổng nghe");
    const auto target = listener->local();
    context.expect(target.has_value(), "đọc được địa chỉ nghe");
    if (!target) return;
    auto client = TcpStream::begin_connect(*target);
    context.expect(client.has_value(), "client nối");
    if (!client) return;
    PollEvents events;
    context.expect(reactor.wait(kReadyLimit, events).has_value(), "chờ nhận");
    auto accepted = reactor.take_accept(3);
    context.expect(accepted.has_value() && accepted->has_value(), "AcceptEx trả một kết nối");
    if (!accepted || !accepted->has_value()) return;
    context.expect(wait_ready(client->handle(), true, kReadyLimit), "client ghi được");
    const auto connected = client->finish_connect();
    context.expect(connected.has_value() && *connected, "client nối xong");
    context.expect(reactor.watch((*accepted)->stream.handle(), 9), "theo dõi socket nhận");
    context.expect(client->send(bytes_of("Z")) == std::size_t{1}, "gửi một byte");
    context.expect(reactor.wait(kReadyLimit, events).has_value() && has_tag(events, 9), "byte làm socket đọc được");
    std::array<std::byte, 4> sink{};
    const auto got = (*accepted)->stream.receive(sink);
    context.expect(got == std::size_t{1} && sink[0] == std::byte{'Z'}, "đọc đúng byte đã gửi");
    if (got) reactor.note_read(9, *got);
    const net::SendOutcome sent = reactor.submit_send(9, bytes_of("Y"));
    context.expect(sent.state != net::SendState::kReset, "đăng gửi được");
    std::array<std::byte, 4> back{};
    const auto echoed = receive_ready(*client, back);
    context.expect(echoed == std::size_t{1} && back[0] == std::byte{'Y'}, "client nhận byte gửi chồng");
}

void reactor_wakes_from_another_thread(Context& context) {
    net::Reactor reactor;
    std::jthread waker([&] {
        std::this_thread::sleep_for(std::chrono::milliseconds{20});
        reactor.wake();
    });
    PollEvents events;
    const auto start = std::chrono::steady_clock::now();
    const auto waited = reactor.wait(Milliseconds{2000}, events);
    const auto elapsed = std::chrono::steady_clock::now() - start;
    waker.join();
    context.expect(waited.has_value(), "chờ không lỗi");
    context.expect(elapsed < Milliseconds{500}, "luồng khác đánh thức lần chờ");
}

void reactor_takes_udp(Context& context) {
    auto left = net::UdpSocket::open(kAnyLoopbackPort);
    auto right = net::UdpSocket::open(kAnyLoopbackPort);
    context.expect(left.has_value() && right.has_value(), "mở UDP");
    if (!left || !right) return;
    const auto dest = right->local();
    context.expect(dest.has_value(), "cổng nhận");
    if (!dest) return;
    net::Reactor reactor;
    context.expect(reactor.watch_udp(*right, 4), "gắn UDP vào cổng hoàn thành");
    const auto payload = bytes_of("iocp");
    context.expect(left->send_to(*dest, payload).has_value(), "gửi datagram");
    PollEvents events;
    const auto waited = reactor.wait(kReadyLimit, events);
    context.expect(waited.has_value() && has_tag(events, 4), "IOCP báo datagram");
    std::array<std::byte, 16> buf{};
    const auto got = reactor.take_udp(4, buf);
    context.expect(got.has_value() && got->has_value(), "lấy được datagram");
    if (!got || !got->has_value()) return;
    context.expect(!got->value().truncated && got->value().size == 4, "đủ 4 byte");
    const auto none = reactor.take_udp(4, buf);
    context.expect(none.has_value() && !none->has_value(), "hết datagram thì rỗng");
}

void reactor_udp_burst(Context& context) {
    auto left = net::UdpSocket::open(kAnyLoopbackPort);
    auto right = net::UdpSocket::open(kAnyLoopbackPort);
    context.expect(left.has_value() && right.has_value(), "mở UDP");
    if (!left || !right) return;
    const auto dest = right->local();
    context.expect(dest.has_value(), "cổng nhận");
    if (!dest) return;
    net::Reactor reactor;
    context.expect(reactor.watch_udp(*right, 6), "treo nhiều lượt nhận");
    constexpr int kBurst = 8;
    for (int index = 0; index < kBurst; ++index) {
        std::array<std::byte, 1> payload{static_cast<std::byte>(index)};
        context.expect(left->send_to(*dest, payload).has_value(), "gửi một gói trong đợt");
    }
    PollEvents events;
    const auto waited = reactor.wait(kReadyLimit, events);
    context.expect(waited.has_value() && has_tag(events, 6), "IOCP báo đợt gói");
    std::array<bool, kBurst> seen{};
    int got_count = 0;
    for (int index = 0; index < kBurst; ++index) {
        std::array<std::byte, 8> buf{};
        const auto got = reactor.take_udp(6, buf);
        if (!got || !got->has_value() || got->value().size != 1) break;
        const auto mark = static_cast<unsigned>(buf[0]);
        if (mark >= static_cast<unsigned>(kBurst) || seen[mark]) break;
        seen[mark] = true;
        ++got_count;
    }
    context.expect(got_count == kBurst, "một lần chờ lấy đủ 8 gói");
    std::array<std::byte, 8> extra{};
    const auto none = reactor.take_udp(6, extra);
    context.expect(none.has_value() && !none->has_value(), "hàng nhận hết");
}

void empty_poll_set_waits_out_limit(Context& context) {
    PollSet poll;
    PollEvents events{net::PollEvent{.tag = 5}};
    const auto start = std::chrono::steady_clock::now();
    const auto waited = poll.wait(Milliseconds{100}, events);
    const auto elapsed = std::chrono::steady_clock::now() - start;
    context.expect(waited.has_value(), "tập rỗng chờ không lỗi");
    context.expect(events.empty(), "tập rỗng không có sự kiện");
    context.expect(elapsed >= Milliseconds{50}, "tập rỗng chờ hết hạn");
}

constexpr std::array kCases{
    Case{.name = "endpoint_parses_valid", .body = endpoint_parses_valid},
    Case{.name = "endpoint_rejects_invalid", .body = endpoint_rejects_invalid},
    Case{.name = "describe_covers_every_error", .body = describe_covers_every_error},
    Case{.name = "listener_picks_port", .body = listener_picks_port},
    Case{.name = "listener_port_in_use_fails", .body = listener_port_in_use_fails},
    Case{.name = "accept_without_pending_returns_nothing",
        .body = accept_without_pending_returns_nothing},
    Case{.name = "accept_reports_peer", .body = accept_reports_peer},
    Case{.name = "connect_rejects_port_zero", .body = connect_rejects_port_zero},
    Case{.name = "connect_to_closed_port_fails", .body = connect_to_closed_port_fails},
    Case{.name = "streams_set_nodelay", .body = streams_set_nodelay},
    Case{.name = "receive_without_data_returns_zero", .body = receive_without_data_returns_zero},
    Case{.name = "peer_shutdown_gives_closed", .body = peer_shutdown_gives_closed},
    Case{.name = "peer_abort_gives_reset", .body = peer_abort_gives_reset},
    Case{.name = "early_fin_keeps_bytes", .body = early_fin_keeps_bytes},
    Case{.name = "early_reset_gives_reset", .body = early_reset_gives_reset},
    Case{.name = "slow_reader_gets_eight_mib", .body = slow_reader_gets_eight_mib},
    Case{.name = "accepts_two_hundred", .body = accepts_two_hundred},
    Case{.name = "poll_set_add_and_remove", .body = poll_set_add_and_remove},
    Case{.name = "poll_set_toggles_write", .body = poll_set_toggles_write},
    Case{.name = "empty_poll_set_waits_out_limit", .body = empty_poll_set_waits_out_limit},
    Case{.name = "spsc_preserves_order", .body = spsc_preserves_order},
    Case{.name = "spsc_rejects_when_full", .body = spsc_rejects_when_full},
    Case{.name = "spsc_wakes_a_parked_taker", .body = spsc_wakes_a_parked_taker},
    Case{.name = "lanes_prefer_login_then_share", .body = lanes_prefer_login_then_share},
    Case{.name = "reactor_accepts_and_echoes", .body = reactor_accepts_and_echoes},
    Case{.name = "reactor_wakes_from_another_thread", .body = reactor_wakes_from_another_thread},
    Case{.name = "reactor_takes_udp", .body = reactor_takes_udp},
    Case{.name = "reactor_udp_burst", .body = reactor_udp_burst},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "net_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "net_tests: mọi ca phải qua");
    return 0;
}
