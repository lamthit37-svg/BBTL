// Giới hạn và tin mức phiên của bảng kết nối, không mở socket và không ngủ.
#include "gate/table.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <optional>
#include <span>
#include <string_view>
#include <variant>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using gate::AdmitCode;
using gate::Cidr;
using gate::Drop;
using gate::Handle;
using gate::Limits;
using gate::Table;
using metrics::Counter;
using metrics::Gauge;
using secure::ByteView;

constexpr net::Ipv4 kOne{10, 0, 0, 1};
constexpr net::Ipv4 kTwo{10, 0, 0, 2};
constexpr std::int64_t kNow = 1'000'000'000;

[[nodiscard]] Limits small_limits() noexcept {
    Limits limits;
    limits.max_connections = 2;
    limits.per_ip = 1;
    limits.handshake_ns = 5'000'000'000;
    limits.idle_ns = 10'000'000'000;
    limits.frame_bytes = 4096;
    limits.per_second = 2;
    limits.min_version = 1;
    return limits;
}

[[nodiscard]] secure::Identity make_identity() {
    secure::Result<secure::Identity> made = secure::Identity::generate();
    core::check(made.has_value(), "sinh được khoá");
    return std::move(*made);
}

[[nodiscard]] std::vector<std::byte> sealed(secure::RecordPipe& pipe, ByteView plain) {
    std::array<std::byte, secure::kMaxRecordBytes> out{};
    const secure::SealResult wrote = pipe.seal(plain, out);
    core::check(wrote.has_value(), "niêm được");
    return {out.begin(), out.begin() + static_cast<std::ptrdiff_t>(*wrote)};
}

[[nodiscard]] std::vector<std::byte> opened(secure::RecordPipe& pipe, ByteView record) {
    std::array<std::byte, secure::kMaxPlainBytes> plain{};
    const secure::OpenResult read = pipe.open_bytes(record, plain);
    core::check(read.has_value(), "mở được");
    return {plain.begin(), plain.begin() + static_cast<std::ptrdiff_t>(read->written)};
}

struct Linked {
    Table table;
    Handle handle;
    secure::RecordPipe client;
};

[[nodiscard]] Linked connected(const secure::Identity& identity, Limits limits) {
    Table table{limits, {}, {}, identity};
    const gate::Admit admitted = table.admit(kOne, kNow);
    core::check(admitted.code == AdmitCode::kOk, "nhận kết nối");
    secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu");
    table.receive(admitted.handle, client->hello(), kNow);
    const ByteView reply = table.outgoing(admitted.handle);
    secure::Result<secure::SessionKeys> keys = client->finish(reply, identity.public_key());
    core::check(keys.has_value(), "client xong bắt tay");
    table.mark_sent(admitted.handle, reply.size());
    secure::RecordPipe pipe{std::move(*keys)};
    return Linked{.table = std::move(table), .handle = admitted.handle, .client = std::move(pipe)};
}

void full_refuses(Context& context) {
    const secure::Identity identity = make_identity();
    Table table{small_limits(), {}, {}, identity};
    context.expect(table.admit(kOne, kNow).code == AdmitCode::kOk, "kết nối đầu");
    context.expect(table.admit(kTwo, kNow).code == AdmitCode::kOk, "kết nối hai");
    context.expect(table.admit(kTwo, kNow).code == AdmitCode::kFull, "đầy thì không nhận");
    context.expect(!table.listening(), "đầy thì ngừng nghe");
}

void per_ip_refuses(Context& context) {
    const secure::Identity identity = make_identity();
    Limits limits = small_limits();
    limits.max_connections = 4;
    Table table{limits, {}, {}, identity};
    context.expect(table.admit(kOne, kNow).code == AdmitCode::kOk, "địa chỉ được một kết nối");
    context.expect(table.admit(kOne, kNow).code == AdmitCode::kPerIp, "cùng địa chỉ bị chặn");
}

void deny_and_allow(Context& context) {
    const secure::Identity identity = make_identity();
    const Cidr deny = gate::parse_cidr("10.0.0.0/8").value_or(Cidr{});
    const Cidr allow = gate::parse_cidr("192.168.0.0/16").value_or(Cidr{});
    context.expect(deny.mask != 0 && allow.mask != 0, "đọc được CIDR");
    Table blocked{small_limits(), {}, std::vector<Cidr>{deny}, identity};
    context.expect(blocked.admit(kOne, kNow).code == AdmitCode::kDenied, "dải chặn thắng");
    const net::Ipv4 other{192, 168, 1, 9};
    Table opened{small_limits(), std::vector<Cidr>{allow}, {}, identity};
    context.expect(opened.admit(kOne, kNow).code == AdmitCode::kDenied, "ngoài allow thì chặn");
    context.expect(opened.admit(other, kNow).code == AdmitCode::kOk, "trong allow thì nhận");
}

void handshake_times_out(Context& context) {
    const secure::Identity identity = make_identity();
    Table table{small_limits(), {}, {}, identity};
    const gate::Admit admitted = table.admit(kOne, kNow);
    table.advance(kNow + small_limits().handshake_ns);
    context.expect(!table.is_live(admitted.handle), "quá hạn bắt tay thì ngắt");
    context.expect(table.drops(Drop::kHandshake) == 1, "đếm hạn bắt tay");
    context.expect(table.listening(), "có chỗ thì nghe lại");
}

void session_round_trip(Context& context) {
    const secure::Identity identity = make_identity();
    Linked linked = connected(identity, small_limits());
    std::vector<std::byte> frame;
    protocol::Hello hello;
    hello.version = 1;
    hello.platform = protocol::Platform::kWindows;
    hello.build = 7;
    core::check(protocol::encode(frame, hello).has_value(), "mã hoá Hello");
    const std::vector<std::byte> record = sealed(linked.client, frame);
    linked.table.receive(linked.handle, record, kNow);
    const ByteView out = linked.table.outgoing(linked.handle);
    const std::vector<std::byte> plain = opened(linked.client, out);
    protocol::FrameResult peeked = protocol::peek_frame(plain, 4096);
    context.expect(peeked.has_value() && peeked->has_value(), "Welcome là một khung");
    if (!peeked || !peeked->has_value()) return;
    const ByteView body = std::span{plain}.subspan(8, (*peeked)->body_bytes);
    const protocol::GameServerResult decoded = protocol::decode_game_server(**peeked, body);
    const bool welcome = decoded && std::holds_alternative<protocol::Welcome>(*decoded);
    context.expect(welcome, "server chào lại");
    context.expect(linked.table.scratch_capacity(linked.handle) == gate::kScratchBytes, "hộp mã hoá không phình");
}

void send_bytes(Linked& linked, const std::vector<std::byte>& frame, std::int64_t at) {
    const std::vector<std::byte> record = sealed(linked.client, frame);
    linked.table.receive(linked.handle, record, at);
}

void send_hello(Linked& linked, std::uint16_t version) {
    std::vector<std::byte> frame;
    protocol::Hello hello;
    hello.version = version;
    hello.platform = protocol::Platform::kWindows;
    hello.build = 1;
    core::check(protocol::encode(frame, hello).has_value(), "mã hoá Hello");
    send_bytes(linked, frame, kNow);
}

void send_ping(Linked& linked, std::int64_t at) {
    std::vector<std::byte> frame;
    protocol::Ping ping;
    ping.client_time = std::chrono::milliseconds{at / gate::kNsPerMs};
    core::check(protocol::encode(frame, ping).has_value(), "mã hoá Ping");
    send_bytes(linked, frame, at);
}

void drain(Linked& linked) {
    const ByteView pending = linked.table.outgoing(linked.handle);
    linked.table.mark_sent(linked.handle, pending.size());
}

void ping_and_rate(Context& context) {
    const secure::Identity identity = make_identity();
    Linked linked = connected(identity, small_limits());
    send_hello(linked, 1);
    send_ping(linked, kNow);
    context.expect(linked.table.is_live(linked.handle), "đúng trần thì vẫn sống");
    send_ping(linked, kNow);
    drain(linked);
    context.expect(!linked.table.is_live(linked.handle), "tin vượt trần bị ngắt");
    context.expect(linked.table.drops(Drop::kRate) == 1, "đếm vượt trần");
}

void reject_version(Context& context) {
    const secure::Identity identity = make_identity();
    Linked low = connected(identity, small_limits());
    send_hello(low, 0);
    drain(low);
    context.expect(!low.table.is_live(low.handle), "phiên bản 0 bị ngắt");
    context.expect(low.table.drops(Drop::kVersion) == 1, "đếm phiên bản thấp");
    Linked high = connected(identity, small_limits());
    send_hello(high, 99);
    drain(high);
    context.expect(high.table.drops(Drop::kVersion) == 1, "đếm phiên bản cao");
}

void foreign_is_not_decoded(Context& context) {
    const secure::Identity identity = make_identity();
    Linked linked = connected(identity, small_limits());
    std::vector<std::byte> frame(8);
    frame[4] = std::byte{0x02};
    frame[5] = std::byte{0x01};
    send_bytes(linked, frame, kNow);
    drain(linked);
    context.expect(!linked.table.is_live(linked.handle), "tin đăng nhập bị ngắt");
    context.expect(linked.table.drops(Drop::kForeign) == 1, "đếm tin ngoài mức phiên");
}

void frame_too_big(Context& context) {
    const secure::Identity identity = make_identity();
    Limits limits = small_limits();
    limits.frame_bytes = 4;
    Linked linked = connected(identity, limits);
    std::vector<std::byte> frame(8);
    frame[0] = std::byte{20};
    send_bytes(linked, frame, kNow);
    context.expect(!linked.table.is_live(linked.handle), "thân khai quá trần thì ngắt");
    context.expect(linked.table.drops(Drop::kFrame) == 1, "đếm khung");
}

void slow_reader(Context& context) {
    const secure::Identity identity = make_identity();
    Limits limits = small_limits();
    limits.per_second = 200;
    Linked linked = connected(identity, limits);
    send_hello(linked, 1);
    int left = 40;
    while (left > 0 && linked.table.is_live(linked.handle)) {
        send_ping(linked, kNow);
        --left;
    }
    context.expect(!linked.table.is_live(linked.handle), "hộp gửi đầy thì ngắt");
    context.expect(linked.table.drops(Drop::kSlow) == 1, "đếm đọc chậm");
}

void logout_closes(Context& context) {
    const secure::Identity identity = make_identity();
    Linked linked = connected(identity, small_limits());
    send_hello(linked, 1);
    std::vector<std::byte> frame;
    core::check(protocol::encode(frame, protocol::Logout{}).has_value(), "mã hoá Logout");
    send_bytes(linked, frame, kNow);
    drain(linked);
    context.expect(!linked.table.is_live(linked.handle), "Logout thì đóng");
    context.expect(linked.table.drops(Drop::kLogout) == 1, "đếm đóng phiên");
}

void burst_resumes(Context& context) {
    const secure::Identity identity = make_identity();
    Limits limits = small_limits();
    limits.per_second = 100;
    Linked linked = connected(identity, limits);
    send_hello(linked, 1);
    drain(linked);
    std::vector<std::byte> burst;
    int left = 9;
    while (left > 0) {
        std::vector<std::byte> frame;
        protocol::Ping ping;
        ping.client_time = std::chrono::milliseconds{1};
        core::check(protocol::encode(frame, ping).has_value(), "mã hoá Ping");
        const std::vector<std::byte> record = sealed(linked.client, frame);
        burst.insert(burst.end(), record.begin(), record.end());
        --left;
    }
    linked.table.receive(linked.handle, burst, kNow);
    const std::size_t before = linked.table.outgoing(linked.handle).size();
    linked.table.receive(linked.handle, {}, kNow);
    const std::size_t after = linked.table.outgoing(linked.handle).size();
    context.expect(linked.table.is_live(linked.handle), "chín tin trong ngân sách thì còn sống");
    context.expect(after > before, "tin còn lại được mở ở lần đọc sau");
}

void idle_times_out(Context& context) {
    const secure::Identity identity = make_identity();
    Linked linked = connected(identity, small_limits());
    linked.table.advance(kNow + small_limits().idle_ns);
    const bool counted = linked.table.drops(Drop::kIdle) == 1;
    const bool told = linked.table.outgoing(linked.handle).size() > 0;
    context.expect(counted || told, "im lặng thì báo đóng");
}

// Ba lý do từ chối lúc nhận tăng đúng bộ đếm của mình, mỗi lần từ chối một đơn vị. Trước khi bảng
// ghi vào kho số đo, cả ba đều ra 0: kết nối bị từ chối chưa có ô nên không đi qua release.
void admit_refusals_are_counted(Context& context) {
    constexpr std::uint8_t kExtra = 5;
    const secure::Identity identity = make_identity();
    const auto full = std::make_unique<metrics::Registry>();
    Table packed{small_limits(), {}, {}, gate::Backing{.identity = identity, .registry = *full}};
    const bool is_packed = packed.admit(kOne, kNow).code == AdmitCode::kOk && packed.admit(kTwo, kNow).code == AdmitCode::kOk;
    context.expect(is_packed, "lấp đầy bảng hai ô");
    for (std::uint8_t last = 0; last < kExtra; ++last) {
        context.expect(packed.admit(net::Ipv4{10, 0, 1, last}, kNow).code == AdmitCode::kFull, "bảng đầy thì từ chối");
    }
    context.expect(packed.drops(Drop::kFull) == kExtra, "đếm đủ số lần từ chối vì đầy");
    context.expect(full->read(Counter::kGateDropFull) == kExtra, "kho số đo thấy cùng con số");
    context.expect(full->read(Counter::kGateAdmitOk) == 2, "hai kết nối được nhận");
    context.expect(packed.drops(Drop::kPerIp) == 0 && packed.drops(Drop::kDenied) == 0, "hai lý do kia không đổi");

    const auto crowded = std::make_unique<metrics::Registry>();
    Limits wide = small_limits();
    wide.max_connections = 16;
    Table shared{wide, {}, {}, gate::Backing{.identity = identity, .registry = *crowded}};
    context.expect(shared.admit(kOne, kNow).code == AdmitCode::kOk, "địa chỉ được một kết nối");
    for (std::uint8_t round = 0; round < kExtra; ++round) {
        context.expect(shared.admit(kOne, kNow).code == AdmitCode::kPerIp, "quá trần của một địa chỉ");
    }
    context.expect(shared.drops(Drop::kPerIp) == kExtra, "đếm đủ số lần từ chối theo địa chỉ");
    context.expect(shared.drops(Drop::kFull) == 0 && shared.drops(Drop::kDenied) == 0, "hai lý do kia không đổi");

    const auto barred = std::make_unique<metrics::Registry>();
    const Cidr deny = gate::parse_cidr("10.0.0.0/8").value_or(Cidr{});
    Table closed{wide, {}, std::vector<Cidr>{deny}, gate::Backing{.identity = identity, .registry = *barred}};
    for (std::uint8_t round = 0; round < kExtra; ++round) {
        context.expect(closed.admit(kOne, kNow).code == AdmitCode::kDenied, "địa chỉ trong dải chặn");
    }
    context.expect(closed.drops(Drop::kDenied) == kExtra, "đếm đủ số lần từ chối vì bị chặn");
    context.expect(barred->read(Counter::kGateAdmitOk) == 0, "không kết nối nào được nhận");
}

// Lý do ngắt xảy ra sau khi kết nối đã được nhận: mọi lý do trừ ba lý do từ chối lúc nhận.
[[nodiscard]] bool is_after_admit(Drop reason) noexcept {
    return reason != Drop::kFull && reason != Drop::kPerIp && reason != Drop::kDenied;
}

[[nodiscard]] std::uint64_t dropped_after_admit(const Table& table) noexcept {
    std::uint64_t sum = 0;
    for (std::uint8_t reason = 1; reason < std::to_underlying(Drop::kCount); ++reason) {
        if (is_after_admit(Drop{reason})) sum += table.drops(Drop{reason});
    }
    return sum;
}

// Hai đẳng thức của sổ: kết nối được nhận thì hoặc còn sống hoặc nằm trong đúng một bộ đếm ngắt; lần
// nhận nào cũng hoặc thành công hoặc nằm trong một trong ba bộ đếm từ chối.
void counters_balance_after_mixed_run(Context& context) {
    const secure::Identity identity = make_identity();
    Limits limits = small_limits();
    limits.max_connections = 3;
    limits.per_ip = 2;
    Linked linked = connected(identity, limits);
    const metrics::Registry& registry = *linked.registry;
    context.expect(linked.table.admit(kOne, kNow).code == AdmitCode::kOk, "kết nối thứ hai của cùng địa chỉ");
    context.expect(linked.table.admit(kOne, kNow).code == AdmitCode::kPerIp, "kết nối thứ ba của địa chỉ bị từ chối");
    context.expect(linked.table.admit(kTwo, kNow).code == AdmitCode::kOk, "địa chỉ khác lấp đầy bảng");
    context.expect(linked.table.admit(kTwo, kNow).code == AdmitCode::kFull, "bảng đầy");
    const auto balanced = [&] {
        const std::uint64_t admitted = registry.read(Counter::kGateAdmitOk);
        const std::uint64_t refused = linked.table.drops(Drop::kFull) + linked.table.drops(Drop::kPerIp) + linked.table.drops(Drop::kDenied);
        return admitted == dropped_after_admit(linked.table) + linked.table.live() && admitted + refused == 5;
    };
    context.expect(balanced(), "sổ cân khi ba kết nối còn sống");
    linked.table.advance(kNow);
    context.expect(registry.read(Gauge::kGateLive) == 3, "mức đo số kết nối sống");
    context.expect(registry.read(Gauge::kGateListening) == 0, "bảng đầy thì mức đo nghe bằng 0");
    context.expect(registry.read(Gauge::kGateHandshakePerTick) == 1, "một lần bắt tay từ lúc dựng bảng");
    linked.table.advance(kNow + limits.handshake_ns);
    context.expect(linked.table.drops(Drop::kHandshake) == 2, "hai kết nối chưa bắt tay bị ngắt");
    context.expect(registry.read(Gauge::kGateHandshakePerTick) == 0, "tick không có bắt tay thì mức đo về 0");
    context.expect(balanced(), "sổ cân sau khi hết hạn bắt tay");
    send_hello(linked, 1);
    std::vector<std::byte> frame;
    core::check(protocol::encode(frame, protocol::Logout{}).has_value(), "mã hoá Logout");
    send_bytes(linked, frame, kNow);
    drain(linked);
    context.expect(linked.table.live() == 0 && balanced(), "sổ cân khi không còn kết nối nào");
    context.expect(registry.read(Counter::kGateHandshakeDone) == 1, "một lần bắt tay xong");
    context.expect(registry.read(Counter::kGateClosedOverflow) == 0, "hàng ô đã đóng không tràn");
    linked.table.advance(kNow + limits.handshake_ns);
    context.expect(registry.read(Gauge::kGateLive) == 0 && registry.read(Gauge::kGateListening) == 1, "mức đo sau khi trống");
}

void drop_reasons_have_names(Context& context) {
    context.expect(gate::describe(Drop::kLocal) == "lỗi phía gate", "lý do mới có câu riêng");
    context.expect(gate::describe(Drop::kCount) == gate::describe(Drop{0}), "giá trị ngoài miền chung một câu");
    for (std::uint8_t reason = 1; reason < std::to_underlying(Drop::kCount); ++reason) {
        context.expect(gate::describe(Drop{reason}) != gate::describe(Drop::kCount), "mỗi lý do thật có câu của nó");
    }
    const secure::Identity identity = make_identity();
    const auto registry = std::make_unique<metrics::Registry>();
    const Table table{small_limits(), {}, {}, gate::Backing{.identity = identity, .registry = *registry}};
    context.expect(table.drops(Drop::kCount) == 0 && table.drops(Drop{0}) == 0, "giá trị ngoài miền đọc ra 0");
    context.expect(table.drops(Drop{200}) == 0, "giá trị lạ đọc ra 0");
}

constexpr std::array kCases{
    Case{.name = "full_refuses", .body = full_refuses},
    Case{.name = "per_ip_refuses", .body = per_ip_refuses},
    Case{.name = "deny_and_allow", .body = deny_and_allow},
    Case{.name = "handshake_times_out", .body = handshake_times_out},
    Case{.name = "session_round_trip", .body = session_round_trip},
    Case{.name = "ping_and_rate", .body = ping_and_rate},
    Case{.name = "reject_version", .body = reject_version},
    Case{.name = "foreign_is_not_decoded", .body = foreign_is_not_decoded},
    Case{.name = "frame_too_big", .body = frame_too_big},
    Case{.name = "slow_reader", .body = slow_reader},
    Case{.name = "logout_closes", .body = logout_closes},
    Case{.name = "burst_resumes", .body = burst_resumes},
    Case{.name = "idle_times_out", .body = idle_times_out},
    Case{.name = "admit_refusals_are_counted", .body = admit_refusals_are_counted},
    Case{.name = "counters_balance_after_mixed_run", .body = counters_balance_after_mixed_run},
    Case{.name = "drop_reasons_have_names", .body = drop_reasons_have_names},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
