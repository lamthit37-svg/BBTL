// Test ghép protocol và net qua loopback thật (P2 đợt 2, bước 1b, vai L): bên gửi mã hoá mọi mẫu
// của protocol_samples.hpp, đẩy qua TcpStream từng mẩu 1, 7, 4.096 byte; bên nhận đưa từng mẩu
// vào kênh, lấy khung, giải mã và so với giá trị gốc. Ca khung khai thân quá trần: kênh báo
// kBodyTooLarge khi mới có 8 byte đầu, không chờ thân.
// Quyết định: một luồng, hai đầu cùng tiến trình; mỗi vòng gửi một mẩu rồi chờ bằng PollSet::wait
// có hạn và nhận đúng một mẩu, nên kênh thấy byte đến rời rạc như trên mạng thật. Không có
// sleep_for, không có vòng thử lại theo giờ: số vòng có trần, hết trần là test đỏ.
#include "core/check.hpp"
#include "net/net.hpp"
#include "protocol/channel.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "Protocol/protocol_samples.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using protocol::ByteView;
using Bytes = std::vector<std::byte>;
using AcceptResult = net::NetResult<std::optional<net::Accepted>>;
namespace samples = test::samples;

constexpr net::Milliseconds kWait{2'000};
constexpr std::uint64_t kServerTag = 1;
constexpr std::uint64_t kListenerTag = 2;
constexpr std::uint64_t kClientTag = 3;
constexpr std::size_t kSetupRounds = 50;
constexpr std::size_t kMaxRounds = 200'000;
constexpr net::Ipv4 kLoopback{127, 0, 0, 1};

// Hai đầu của một kết nối loopback; network khai trước nên huỷ sau mọi socket.
struct Link {
    net::Network network;
    net::TcpStream client;
    net::TcpStream server;
    net::PollSet poll;
};

// Trạng thái một lượt gửi nhận: byte cần gửi, mẩu, kênh bên nhận và kết quả so.
struct Loop {
    Bytes outgoing;
    std::size_t limit = 0;
    std::size_t sent = 0;
    std::size_t received = 0;
    Bytes sink;
    protocol::Channel channel{protocol::ChannelLimits{}};
    std::size_t checked = 0;
    std::size_t wrong = 0;
    std::optional<protocol::ChannelError> error;
};

[[nodiscard]] AcceptResult poll_accept(net::TcpListener& listener, net::PollSet& poll) {
    net::PollEvents events;
    if (!poll.wait(kWait, events)) return std::unexpected(net::NetError::kPoll);
    return listener.accept();
}

// Chờ có người nối vào cổng nghe rồi nhận; nullopt khi lỗi hoặc hết số vòng chờ.
[[nodiscard]] std::optional<net::TcpStream> accept_one(net::TcpListener& listener) {
    net::PollSet poll;
    if (!poll.add(listener.handle(), kListenerTag)) return std::nullopt;
    AcceptResult accepted = listener.accept();
    for (std::size_t round = 0; round < kSetupRounds && accepted && !*accepted; ++round) {
        accepted = poll_accept(listener, poll);
    }
    if (!accepted || !*accepted) return std::nullopt;
    return std::move((*accepted)->stream);
}

[[nodiscard]] net::NetResult<bool> poll_connect(net::TcpStream& client, net::PollSet& poll) {
    net::PollEvents events;
    if (!poll.wait(kWait, events)) return std::unexpected(net::NetError::kPoll);
    return client.finish_connect();
}

// Bước hai của nối: chờ tập chờ báo ghi được rồi hỏi kết quả.
[[nodiscard]] bool finish(net::TcpStream& client) {
    net::PollSet poll;
    if (!poll.add(client.handle(), kClientTag)) return false;
    poll.want_write(kClientTag, true);
    net::NetResult<bool> done = client.finish_connect();
    for (std::size_t round = 0; round < kSetupRounds && done && !*done; ++round) {
        done = poll_connect(client, poll);
    }
    return done && *done;
}

// Nối một luồng vào cổng nghe 127.0.0.1 do hệ điều hành chọn; nullopt khi bất kỳ bước nào hỏng.
[[nodiscard]] std::optional<Link> open_link() {
    auto network = net::Network::start();
    if (!network) return std::nullopt;
    auto listener = net::TcpListener::open(net::Endpoint{.address = kLoopback, .port = 0});
    if (!listener) return std::nullopt;
    const auto address = listener->local();
    if (!address) return std::nullopt;
    auto client = net::TcpStream::begin_connect(*address);
    if (!client) return std::nullopt;
    auto server = accept_one(*listener);
    if (!server || !finish(*client)) return std::nullopt;
    Link link{.network = std::move(*network),
        .client = std::move(*client),
        .server = std::move(*server),
        .poll = net::PollSet{}};
    if (!link.poll.add(link.server.handle(), kServerTag)) return std::nullopt;
    return link;
}

// Mã của tin trong khung mẫu: byte 4 và 5 của đầu khung, little-endian.
[[nodiscard]] std::uint16_t kind_of(std::span<const std::uint8_t> frame) {
    return static_cast<std::uint16_t>(frame[4] | (static_cast<unsigned>(frame[5]) << 8U));
}

// Khung thứ index nhận được phải cùng mã tin và giải mã ra đúng giá trị của mẫu thứ index.
[[nodiscard]] bool matches(std::size_t index, const protocol::InFrame& frame) {
    const std::span<const samples::Sample> all{samples::kSamples};
    if (index >= all.size()) return false;
    const samples::Sample& sample = all[index];
    const samples::Check decoded = sample.decode(frame.body);
    return decoded && *decoded && frame.kind == kind_of(sample.frame);
}

// Lấy một khung khỏi kênh và so; false khi hết khung hoặc kênh hỏng (lỗi giữ ở loop.error).
[[nodiscard]] bool take_frame(Loop& loop) {
    const protocol::NextFrame next = loop.channel.next();
    if (!next) loop.error = next.error();
    if (!next || !*next) return false;
    loop.wrong += static_cast<std::size_t>(!matches(loop.checked, **next));
    ++loop.checked;
    return true;
}

// Gửi một mẩu, không quá loop.limit; 0 byte khi hộp gửi của hệ điều hành đầy là bình thường.
[[nodiscard]] bool send_piece(Link& link, Loop& loop) {
    const std::size_t room = std::min(loop.sink.size(), loop.limit - loop.sent);
    const auto count = link.client.send(ByteView{loop.outgoing}.subspan(loop.sent, room));
    if (!count) return false;
    loop.sent += *count;
    return true;
}

// Chờ bên nhận đọc được, nhận tối đa một mẩu, đưa vào kênh rồi lấy hết khung đã đủ.
[[nodiscard]] bool receive_piece(Link& link, Loop& loop) {
    net::PollEvents events;
    if (!link.poll.wait(kWait, events)) return false;
    const auto count = link.server.receive(loop.sink);
    if (!count) return false;
    loop.received += *count;
    if (!loop.channel.receive(ByteView{loop.sink}.first(*count))) return false;
    while (take_frame(loop)) {
    }
    return true;
}

[[nodiscard]] bool step(Link& link, Loop& loop) {
    if (loop.sent < loop.limit && !send_piece(link, loop)) return false;
    return receive_piece(link, loop);
}

// Gửi và nhận tới khi bên nhận có đủ loop.limit byte hoặc kênh báo lỗi; false khi socket hỏng
// hoặc hết số vòng.
[[nodiscard]] bool deliver(Link& link, Loop& loop) {
    bool healthy = true;
    std::size_t round = 0;
    for (; healthy && !loop.error && loop.received < loop.limit && round < kMaxRounds; ++round) {
        healthy = step(link, loop);
    }
    return healthy && round < kMaxRounds;
}

// Mọi mẫu nối liền thành một dòng byte, mã hoá bằng bộ mã hoá C++; nullopt khi có mẫu hỏng.
[[nodiscard]] std::optional<Bytes> encode_all() {
    Bytes out;
    bool encoded = true;
    for (const samples::Sample& sample : samples::kSamples) {
        encoded = sample.encode(out).has_value() && encoded;
    }
    if (!encoded) return std::nullopt;
    return out;
}

// Lượt gửi toàn bộ outgoing theo mẩu piece byte; bên nhận cũng đọc mỗi lần tối đa piece byte.
[[nodiscard]] Loop make_loop(Bytes outgoing, std::size_t piece) {
    Loop loop;
    loop.outgoing = std::move(outgoing);
    loop.limit = loop.outgoing.size();
    loop.sink.resize(piece);
    return loop;
}

void loop_with_piece(Context& context, std::size_t piece) {
    auto link = open_link();
    context.expect(link.has_value(), "mở được kết nối loopback 127.0.0.1");
    auto bytes = encode_all();
    context.expect(bytes.has_value(), "mọi mẫu mã hoá được");
    if (!link || !bytes) return;
    Loop loop = make_loop(std::move(*bytes), piece);
    context.expect(deliver(*link, loop), "gửi và nhận hết byte, socket không lỗi");
    context.expect(!loop.error.has_value(), "kênh không báo lỗi");
    context.expect(loop.checked == samples::kSamples.size(), "nhận đủ khung của mọi mẫu");
    context.expect(loop.wrong == 0, "mọi khung giải mã ra đúng giá trị gốc");
}

void pieces_of_1_byte(Context& context) {
    loop_with_piece(context, 1);
}

void pieces_of_7_bytes(Context& context) {
    loop_with_piece(context, 7);
}

void pieces_of_4096_bytes(Context& context) {
    loop_with_piece(context, 4'096);
}

// Đầu khung Hello khai thân kMaxBodyBytes + 1, theo sau là 16 byte thân sẽ không bao giờ gửi.
[[nodiscard]] Bytes oversized_frame() {
    constexpr std::uint32_t kDeclared = protocol::kMaxBodyBytes + 1;
    constexpr std::uint16_t kKind = protocol::Hello::kKind;
    Bytes out(protocol::kHeaderBytes + 16);
    const std::span<std::byte> head{out};
    head[0] = static_cast<std::byte>(kDeclared & 0xFFU);
    head[1] = static_cast<std::byte>((kDeclared >> 8U) & 0xFFU);
    head[2] = static_cast<std::byte>((kDeclared >> 16U) & 0xFFU);
    head[3] = static_cast<std::byte>(kDeclared >> 24U);
    head[4] = static_cast<std::byte>(kKind & 0xFFU);
    head[5] = static_cast<std::byte>(kKind >> 8U);
    return out;
}

void oversized_body_fails_after_header(Context& context) {
    auto link = open_link();
    context.expect(link.has_value(), "mở được kết nối loopback 127.0.0.1");
    if (!link) return;
    Loop loop = make_loop(oversized_frame(), 1);
    loop.limit = protocol::kHeaderBytes - 1;
    context.expect(deliver(*link, loop), "bảy byte đầu đến nơi");
    context.expect(!loop.error.has_value(), "bảy byte đầu: kênh chưa báo lỗi");
    context.expect(loop.channel.inbox_held() == 7, "bảy byte đầu: kênh giữ đủ bảy byte");
    loop.limit = protocol::kHeaderBytes;
    context.expect(deliver(*link, loop), "byte thứ tám đến nơi");
    context.expect(loop.received == protocol::kHeaderBytes, "bên nhận mới có đúng 8 byte");
    const bool too_large = loop.error == protocol::ChannelError::kBodyTooLarge;
    context.expect(too_large, "đủ 8 byte đầu: kênh báo kBodyTooLarge, không chờ thân");
    context.expect(loop.checked == 0, "không khung nào được trả");
}

} // namespace

constexpr std::array kCases{
    Case{.name = "pieces_of_1_byte", .body = &pieces_of_1_byte},
    Case{.name = "pieces_of_7_bytes", .body = &pieces_of_7_bytes},
    Case{.name = "pieces_of_4096_bytes", .body = &pieces_of_4096_bytes},
    Case{.name = "oversized_body_fails_after_header", .body = &oversized_body_fails_after_header},
};

} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "wire_loop_tests");
    return 0;
}