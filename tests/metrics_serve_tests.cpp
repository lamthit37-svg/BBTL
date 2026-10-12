// Test của cổng đọc số đo trên loopback thật, cổng do hệ điều hành chọn. Hàng bên đọc được lái
// từng bước với thời điểm tự đưa, nên ca quá hạn không ngủ; chỗ chờ duy nhất là PollSet::wait có hạn.
#include "core/check.hpp"
#include "core/clock.hpp"
#include "metrics/metrics.hpp"
#include "metrics/serve/serve.hpp"
#include "net/net.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using metrics::Counter;
using metrics::Readers;
using metrics::Registry;
using net::Endpoint;
using net::Milliseconds;
using net::NetError;
using net::TcpListener;
using net::TcpStream;

constexpr net::Ipv4 kLoopback{127, 0, 0, 1};
constexpr Milliseconds kReadyLimit{5000};
constexpr Milliseconds kNoWait{0};
constexpr std::string_view kSmallText = "metrics 1\nend\n";

// Bên đọc đã thấy gì ở cuối: máy chủ đóng êm, máy chủ huỷ kết nối, hay hết hạn chờ của test.
enum class End : std::uint8_t { kClosed, kReset, kTimeout };

struct Read {
    std::string text;
    End end = End::kTimeout;
};

[[nodiscard]] bool wait_ready(net::SocketHandle socket, bool write, Milliseconds limit) {
    net::PollSet poll;
    net::PollEvents events;
    if (!poll.add(socket, 1)) return false;
    poll.want_write(1, write);
    return poll.wait(limit, events).has_value() && !events.empty();
}

// Nối xong mới trả về: kết nối đã nằm trong hàng chờ của cổng nghe dù phía kia chưa accept.
[[nodiscard]] std::optional<TcpStream> connect_to(std::uint16_t port) {
    net::NetResult<TcpStream> client = TcpStream::begin_connect(Endpoint{.address = kLoopback, .port = port});
    if (!client) return std::nullopt;
    if (!wait_ready(client->handle(), true, kReadyLimit)) return std::nullopt;
    const net::NetResult<bool> done = client->finish_connect();
    if (!done || !*done) return std::nullopt;
    return std::move(*client);
}

// Đọc tới khi máy chủ đóng hoặc huỷ kết nối.
[[nodiscard]] Read read_all(TcpStream& stream) {
    Read read;
    std::array<std::byte, 65536> buffer{};
    while (wait_ready(stream.handle(), false, kReadyLimit)) {
        const net::NetResult<std::size_t> got = stream.receive(buffer);
        if (!got) {
            read.end = got.error() == NetError::kClosed ? End::kClosed : End::kReset;
            return read;
        }
        const std::span<const std::byte> bytes = std::span{buffer}.first(*got);
        std::ranges::transform(bytes, std::back_inserter(read.text), [](std::byte one) { return static_cast<char>(one); });
    }
    return read;
}

[[nodiscard]] Readers::Fill fill_with(std::string_view text) {
    return Readers::Fill{[text](std::span<char> out) {
        std::ranges::copy(text, out.begin());
        return text.size();
    }};
}

struct Line {
    std::uint16_t port = 0;
    Readers readers;
};

[[nodiscard]] std::optional<Line> open_line(Registry& tally, Readers::Fill fill) {
    net::NetResult<TcpListener> listener = TcpListener::open(Endpoint{.address = kLoopback, .port = 0});
    if (!listener) return std::nullopt;
    const net::NetResult<Endpoint> local = listener->local();
    if (!local) return std::nullopt;
    return Line{.port = local->port, .readers = Readers{std::move(*listener), tally, std::move(fill)}};
}

void server_serves_registry(Context& context) {
    const auto registry = std::make_unique<Registry>();
    registry->add(Counter::kGateDropRate, 100);
    const net::NetResult<metrics::Server> server = metrics::Server::start(*registry);
    context.expect(server.has_value(), "mở được cổng đọc số đo");
    if (!server) return;
    context.expect(server->port() != 0, "cổng do hệ điều hành chọn khác 0");
    const auto snapshot = std::make_unique<metrics::Snapshot>();
    for (std::uint64_t round = 1; round <= 3; ++round) {
        std::optional<TcpStream> client = connect_to(server->port());
        context.expect(client.has_value(), "nối được cổng đọc số đo");
        if (!client) return;
        const Read read = read_all(*client);
        context.expect(read.end == End::kClosed, "máy chủ gửi xong thì đóng êm");
        context.expect(metrics::parse_snapshot(read.text, *snapshot).has_value(), "bên đọc nhận trọn một ảnh chụp");
        context.expect(metrics::find_counter(*snapshot, "gate.drop.rate") == 100 * round, "số đọc được là số hiện tại");
        registry->add(Counter::kGateDropRate, 100);
    }
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 0, "không bên đọc nào bị bỏ");
}

void server_stops_with_reader_connected(Context& context) {
    const auto registry = std::make_unique<Registry>();
    std::optional<TcpStream> client;
    {
        const net::NetResult<metrics::Server> server = metrics::Server::start(*registry);
        context.expect(server.has_value(), "mở được cổng đọc số đo");
        if (!server) return;
        client = connect_to(server->port());
    }
    // Ra khỏi khối là luồng phục vụ đã dừng; bên đọc còn nối chỉ thấy kết nối kết thúc.
    context.expect(client.has_value(), "nối được trước khi cổng dừng");
    if (!client) return;
    const Read read = read_all(*client);
    context.expect(read.end != End::kTimeout, "cổng dừng thì bên đọc không bị treo");
}

void fifth_waiting_reader_is_dropped(Context& context) {
    const auto registry = std::make_unique<Registry>();
    std::optional<Line> opened = open_line(*registry, fill_with(kSmallText));
    context.expect(opened.has_value(), "mở được hàng bên đọc");
    if (!opened) return;
    Readers& readers = opened->readers;
    const std::uint16_t port = opened->port;
    std::vector<TcpStream> clients;
    for (std::size_t index = 0; index < metrics::kMaxReaders + 1; ++index) {
        std::optional<TcpStream> client = connect_to(port);
        context.expect(client.has_value(), "nối được bên đọc");
        if (!client) return;
        clients.push_back(std::move(*client));
    }
    // Cả năm đã nằm trong hàng chờ của hệ điều hành: một vòng nhận hết, bốn bên vào hàng, bên thứ năm bị huỷ.
    context.expect(readers.step(kNoWait, core::Clock::now()).has_value(), "một vòng của hàng bên đọc");
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 1, "đúng một bên bị bỏ");
    context.expect(readers.waiting() == 0 && !readers.is_serving(), "bốn bên còn lại được phục vụ xong");
    std::size_t served = 0;
    std::size_t reset = 0;
    for (TcpStream& client : clients) {
        const Read read = read_all(client);
        if (read.end == End::kClosed && read.text == kSmallText) ++served;
        if (read.end == End::kReset && read.text.empty()) ++reset;
    }
    context.expect(served == metrics::kMaxReaders, "bốn bên nhận trọn ảnh chụp");
    context.expect(reset == 1, "bên thứ năm thấy kết nối bị huỷ");
}

void stalled_reader_times_out(Context& context) {
    const auto registry = std::make_unique<Registry>();
    // Ảnh chụp lớn nhất: lớn hơn mọi vùng đệm mặc định của một kết nối loopback, nên bên không đọc
    // làm lần gửi phải chờ.
    const std::string large(metrics::kSnapshotMaxBytes, 'x');
    std::optional<Line> opened = open_line(*registry, fill_with(large));
    context.expect(opened.has_value(), "mở được hàng bên đọc");
    if (!opened) return;
    Readers& readers = opened->readers;
    const std::uint16_t port = opened->port;
    std::optional<TcpStream> stalled = connect_to(port);
    const std::optional<TcpStream> next = connect_to(port);
    context.expect(stalled.has_value() && next.has_value(), "nối được hai bên đọc");
    if (!stalled || !next) return;
    const core::Clock::time_point start = core::Clock::now();
    context.expect(readers.step(kNoWait, start).has_value(), "vòng đầu");
    context.expect(readers.is_serving() && readers.waiting() == 1, "bên không đọc giữ lượt, bên kế chờ");
    const core::Clock::time_point almost = start + metrics::kReaderTimeout - std::chrono::milliseconds{1};
    context.expect(readers.step(kNoWait, almost).has_value(), "vòng sát hạn");
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 0, "chưa tới hạn thì chưa bỏ");
    context.expect(readers.step(kNoWait, start + metrics::kReaderTimeout).has_value(), "vòng đúng hạn");
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 1, "tới hạn thì bỏ và đếm");
    context.expect(readers.is_serving() && readers.waiting() == 0, "bên kế được phục vụ ngay");
    const Read read = read_all(*stalled);
    context.expect(read.end == End::kReset, "bên quá hạn thấy kết nối bị huỷ");
    context.expect(read.text.size() < large.size(), "bên quá hạn không nhận trọn ảnh chụp");
}

void reader_that_resets_is_not_counted(Context& context) {
    const auto registry = std::make_unique<Registry>();
    const std::string large(metrics::kSnapshotMaxBytes, 'x');
    std::optional<Line> opened = open_line(*registry, fill_with(large));
    context.expect(opened.has_value(), "mở được hàng bên đọc");
    if (!opened) return;
    Readers& readers = opened->readers;
    const std::uint16_t port = opened->port;
    std::optional<TcpStream> client = connect_to(port);
    context.expect(client.has_value(), "nối được bên đọc");
    if (!client) return;
    const core::Clock::time_point start = core::Clock::now();
    context.expect(readers.step(kNoWait, start).has_value(), "vòng đầu");
    context.expect(readers.is_serving(), "bên đọc đang được phục vụ");
    client->abort();
    // RST tới sau lời gọi abort một nhịp của hệ điều hành: chờ sự kiện trên socket đang phục vụ, có hạn.
    bool is_gone = false;
    for (int round = 0; round < 50 && !is_gone; ++round) {
        context.expect(readers.step(Milliseconds{100}, start).has_value(), "vòng chờ bên đọc đứt");
        is_gone = !readers.is_serving();
    }
    context.expect(is_gone, "bên đọc tự đứt thì rời hàng");
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 0, "bên tự đứt không tính là bị bỏ");
}

void accept_burst_is_capped(Context& context) {
    const auto registry = std::make_unique<Registry>();
    std::optional<Line> opened = open_line(*registry, fill_with(kSmallText));
    context.expect(opened.has_value(), "mở được hàng bên đọc");
    if (!opened) return;
    Readers& readers = opened->readers;
    const std::uint16_t port = opened->port;
    constexpr std::size_t kMany = 40;
    std::vector<TcpStream> clients;
    for (std::size_t index = 0; index < kMany; ++index) {
        std::optional<TcpStream> client = connect_to(port);
        context.expect(client.has_value(), "nối được bên đọc");
        if (!client) return;
        clients.push_back(std::move(*client));
    }
    // Mỗi vòng nhận tối đa 16 kết nối: 4 được phục vụ, 12 bị bỏ. Ba vòng thì hết 40 bên.
    const core::Clock::time_point now = core::Clock::now();
    context.expect(readers.step(kNoWait, now).has_value(), "vòng một");
    context.expect(registry->read(Counter::kMetricsReaderDropped) == 12, "vòng một bỏ 12 bên");
    context.expect(readers.step(kNoWait, now).has_value(), "vòng hai");
    context.expect(readers.step(kNoWait, now).has_value(), "vòng ba");
    const std::uint64_t dropped = registry->read(Counter::kMetricsReaderDropped);
    std::size_t served = 0;
    for (TcpStream& client : clients) {
        const Read read = read_all(client);
        if (read.end == End::kClosed && read.text == kSmallText) ++served;
    }
    context.expect(served + dropped == kMany, "mỗi bên hoặc được phục vụ hoặc bị bỏ, không bên nào treo");
    context.expect(served == 12 && dropped == 28, "ba vòng: 12 bên được phục vụ, 28 bên bị bỏ");
}

constexpr std::array kCases{
    Case{.name = "server_serves_registry", .body = server_serves_registry},
    Case{.name = "server_stops_with_reader_connected", .body = server_stops_with_reader_connected},
    Case{.name = "fifth_waiting_reader_is_dropped", .body = fifth_waiting_reader_is_dropped},
    Case{.name = "stalled_reader_times_out", .body = stalled_reader_times_out},
    Case{.name = "reader_that_resets_is_not_counted", .body = reader_that_resets_is_not_counted},
    Case{.name = "accept_burst_is_capped", .body = accept_burst_is_capped},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "metrics_serve_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "metrics_serve_tests: mọi ca phải qua");
    return 0;
}
