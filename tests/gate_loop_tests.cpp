// Một phiên thật qua socket loopback: bắt tay, Hello, Ping, Logout, rồi một khách gửi rác.
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "net/net.hpp"
#include "process/process.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <ios>
#include <iterator>
#include <optional>
#include <span>
#include <utility>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace game::test {
namespace {

using game::process::Child;
using game::process::ExitStatus;
using game::process::LineKind;
using game::process::WaitKind;
using secure::ByteView;
using Path = std::filesystem::path;

#ifdef GAME_SERVER_CONFIG
constexpr std::string_view kServerConfig = GAME_SERVER_CONFIG;
#else
constexpr std::string_view kServerConfig = "SERVER/config";
#endif

constexpr std::chrono::milliseconds kIo{2000};

struct GateRun {
    Child child;
    secure::Identity identity;
};

[[nodiscard]] bool wait_io(net::SocketHandle socket, bool write) {
    net::PollSet poll;
    if (!poll.add(socket, 1)) return false;
    if (write) poll.want_write(1, true);
    net::PollEvents events;
    const net::NetResult<void> waited = poll.wait(kIo, events);
    return waited.has_value() && !events.empty();
}

[[nodiscard]] bool send_some(net::TcpStream& stream, ByteView data, std::size_t& sent) {
    if (sent >= data.size()) return false;
    if (!wait_io(stream.handle(), true)) return false;
    const net::NetResult<std::size_t> wrote = stream.send(data.subspan(sent));
    if (!wrote || *wrote == 0) return false;
    sent += *wrote;
    return true;
}

[[nodiscard]] bool send_all(net::TcpStream& stream, ByteView data) {
    std::size_t sent = 0;
    while (send_some(stream, data, sent)) {
    }
    return sent == data.size();
}

[[nodiscard]] bool read_some(net::TcpStream& stream, std::span<std::byte> sink, std::size_t& got) {
    if (got >= sink.size()) return false;
    if (!wait_io(stream.handle(), false)) return false;
    const net::NetResult<std::size_t> read = stream.receive(sink.subspan(got));
    if (!read || *read == 0) return false;
    got += *read;
    return true;
}

[[nodiscard]] bool read_exact(net::TcpStream& stream, std::span<std::byte> sink) {
    std::size_t got = 0;
    while (read_some(stream, sink, got)) {
    }
    return got == sink.size();
}

[[nodiscard]] bool connect_to(net::TcpStream& stream) {
    const net::NetResult<net::Endpoint> target = net::parse_endpoint("127.0.0.1:17921", net::ZeroPort::kRefuse);
    if (!target) return false;
    net::NetResult<net::TcpStream> opened = net::TcpStream::begin_connect(*target);
    if (!opened) return false;
    stream = std::move(*opened);
    if (!wait_io(stream.handle(), true)) return false;
    const net::NetResult<bool> done = stream.finish_connect();
    return done.has_value() && *done;
}

[[nodiscard]] bool handshake(net::TcpStream& stream, const secure::Identity& identity, secure::RecordPipe& pipe) {
    secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
    if (!client) return false;
    const ByteView hello = client->hello();
    const std::vector<std::byte> hello_bytes{hello.begin(), hello.end()};
    if (!send_all(stream, hello_bytes)) return false;
    std::array<std::byte, secure::kServerHelloBytes> reply{};
    if (!read_exact(stream, reply)) return false;
    secure::Result<secure::SessionKeys> keys = client->finish(reply, identity.public_key());
    if (!keys) return false;
    pipe = secure::RecordPipe{std::move(*keys)};
    return true;
}

[[nodiscard]] bool read_record(net::TcpStream& stream, std::vector<std::byte>& out) {
    std::array<std::byte, 2> header{};
    if (!read_exact(stream, header)) return false;
    const auto low = static_cast<unsigned>(header.front());
    const auto high = static_cast<unsigned>(header.back()) << 8U;
    const auto body = static_cast<std::uint16_t>(low | high);
    const bool fits = body >= secure::kTagBytes + 1 && body <= secure::kMaxBodyBytes;
    if (!fits) return false;
    out.resize(static_cast<std::size_t>(2) + body);
    out.front() = header.front();
    *std::next(out.begin()) = header.back();
    return read_exact(stream, std::span{out}.subspan(2));
}

[[nodiscard]] bool round_trip(net::TcpStream& stream, secure::RecordPipe& client, const std::vector<std::byte>& plain,
    std::uint16_t kind) {
    std::array<std::byte, secure::kMaxRecordBytes> sealed{};
    const secure::SealResult wrote = client.seal(plain, sealed);
    if (!wrote) return false;
    const std::span<const std::byte> used = std::span{sealed}.first(*wrote);
    const std::vector<std::byte> record{used.begin(), used.end()};
    if (!send_all(stream, record)) return false;
    std::vector<std::byte> back;
    if (!read_record(stream, back)) return false;
    std::array<std::byte, secure::kMaxPlainBytes> opened{};
    const secure::OpenResult read = client.open_bytes(back, opened);
    if (!read || read->written < protocol::kHeaderBytes) return false;
    const ByteView frame{opened.data(), read->written};
    const protocol::FrameResult peeked = protocol::peek_frame(frame, 4096);
    return peeked.has_value() && peeked->has_value() && (**peeked).kind == kind;
}

[[nodiscard]] bool session(net::TcpStream& stream, secure::RecordPipe& client) {
    std::vector<std::byte> hello;
    protocol::Hello message;
    message.version = 1;
    message.platform = protocol::Platform::kWindows;
    message.build = 3;
    if (!protocol::encode(hello, message)) return false;
    if (!round_trip(stream, client, hello, protocol::Welcome::kKind)) return false;
    std::vector<std::byte> ping;
    protocol::Ping beat;
    beat.client_time = std::chrono::milliseconds{1};
    if (!protocol::encode(ping, beat)) return false;
    if (!round_trip(stream, client, ping, protocol::Pong::kKind)) return false;
    std::vector<std::byte> logout;
    if (!protocol::encode(logout, protocol::Logout{})) return false;
    return round_trip(stream, client, logout, protocol::Goodbye::kKind);
}

[[nodiscard]] bool write_config(const Path& dir) {
    std::ofstream out{dir / "gate.toml", std::ios::binary};
    out << "schema = 1\n";
    out << "identity_key_file = \"identity.key\"\n";
    out << "trusted_proxies = []\n";
    out << "[listen]\n";
    out << "game = \"127.0.0.1:17921\"\n";
    out << "auth = \"127.0.0.1:17922\"\n";
    out << "[limits]\n";
    out << "max_connections = 8\n";
    out << "per_ip_connections = 8\n";
    out << "handshake_timeout_ms = 2000\n";
    out << "idle_timeout_ms = 5000\n";
    out << "client_frame_bytes = 4096\n";
    out << "messages_per_second = 30\n";
    out << "[client]\n";
    out << "min_version = 1\n";
    out << "[ip_filter]\n";
    out << "allow = []\n";
    out << "deny = []\n";
    return static_cast<bool>(out);
}

struct Prepared {
    Path dir;
    std::optional<secure::Identity> identity;
};

[[nodiscard]] bool copy_named(const Path& dir, std::string_view name) {
    const Path from = io::path_from_utf8(kServerConfig) / io::path_from_utf8(name);
    std::error_code error;
    std::filesystem::copy_file(from, dir / io::path_from_utf8(name), error);
    return !error;
}

[[nodiscard]] Prepared prepare() {
    Prepared prepared;
    prepared.dir = io::executable_directory() / "gate-e2e";
    std::error_code error;
    std::filesystem::remove_all(prepared.dir, error);
    std::filesystem::create_directories(prepared.dir, error);
    if (error) return prepared;
    if (!copy_named(prepared.dir, "cluster.toml") || !copy_named(prepared.dir, "log.toml")) return prepared;
    secure::Result<secure::Identity> made = secure::Identity::generate();
    if (!made) return prepared;
    const secure::Result<void> stored = made->store_new(prepared.dir / "identity.key");
    if (!stored || !write_config(prepared.dir)) return prepared;
    prepared.identity = std::move(*made);
    return prepared;
}

[[nodiscard]] bool launch(const Path& dir, Child& child) {
    const Path exe = io::executable_directory() / "thienlong_gate.exe";
    const std::string program = io::utf8_of(exe);
    const std::string config = io::utf8_of(dir);
    const std::array<std::string_view, 2> arguments{"--config", config};
    process::Spawn request;
    request.executable = program;
    request.arguments = arguments;
    request.mode = process::Mode::kService;
    core::Result<Child> spawned = process::spawn(request);
    if (!spawned) return false;
    child = std::move(*spawned);
    core::Result<process::Line> line = child.read_line(std::chrono::seconds{10});
    return line.has_value() && line->kind == LineKind::kText && line->text == "ready";
}

void loopback_session(Context& context) {
    const net::NetResult<net::Network> network = net::Network::start();
    context.expect(network.has_value(), "khởi động mạng");
    if (!network) return;
    Prepared prepared = prepare();
    context.expect(prepared.identity.has_value(), "ghi cấu hình và khoá tạm");
    if (!prepared.identity) return;
    Child child;
    const bool started = launch(prepared.dir, child);
    context.expect(started, "gate in ready");
    if (!started) return;
    net::TcpStream stream;
    secure::RecordPipe pipe{secure::SessionKeys{}};
    const bool opened = connect_to(stream) && handshake(stream, *prepared.identity, pipe);
    context.expect(opened, "bắt tay qua loopback");
    if (opened) context.expect(session(stream, pipe), "Hello, Ping và Logout");
    net::TcpStream junk;
    context.expect(connect_to(junk), "khách rác vẫn nối được");
    const std::array<std::byte, 24> noise{};
    context.expect(send_all(junk, noise), "gửi rác");
    std::array<std::byte, 8> sink{};
    context.expect(!read_exact(junk, sink), "rác bị ngắt");
    net::TcpStream again;
    secure::RecordPipe second{secure::SessionKeys{}};
    const bool survived = connect_to(again) && handshake(again, *prepared.identity, second);
    context.expect(survived, "gate còn sống sau khách rác");
    child.close_input();
    const ExitStatus status = child.wait_for(std::chrono::seconds{10});
    context.expect(status.kind == WaitKind::kExited && status.code == 0, "đóng ống thì gate thoát 0");
    std::error_code error;
    std::filesystem::remove_all(prepared.dir, error);
}

constexpr std::array kCases{
    Case{.name = "loopback_session", .body = loopback_session},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
