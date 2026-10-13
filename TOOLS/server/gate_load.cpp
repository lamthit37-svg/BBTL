// Tải cổng trên Windows: bắt tay N kết nối tốt, rồi trong cửa sổ đo bơm nhịp tim
// cùng khách thù địch. In bộ nhớ và dòng tick trên stderr của gate. Gate được chạy trên 127.0.0.1
// ở hai cổng do hệ điều hành cấp, nên hai lượt đo cùng lúc không tranh cổng.
// Số chính thức lấy ở bản msvc-release. Im: 4 byte rồi im. Rác: 48 byte 0xFF.
// Lũ gửi nhanh hơn trần. Chậm không đọc sau bắt tay, bộ đệm nhận nhỏ để hộp gửi đầy.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <winsock2.h>

#include "config/gate.hpp"
#include "config/issue.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "net/net.hpp"
#include "process/process.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "supervise/supervise.hpp"

#include <fileapi.h>
#include <handleapi.h>
#include <minwinbase.h>
#include <namedpipeapi.h>
#include <processenv.h>
#include <processthreadsapi.h>
#include <psapi.h>
#include <winbase.h>
#include <winnt.h>

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <expected>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace {

using game::secure::ByteView;
using Clock = std::chrono::steady_clock;

constexpr int kConnectSeconds = 20;
constexpr int kPumpMs = 5;
constexpr int kOpenBatch = 128;
constexpr int kReceiveCap = 1024;
constexpr std::size_t kOutBytes = 256;
constexpr std::size_t kReadBytes = 2048;
constexpr int kGood = 0;
constexpr int kSilence = 1;
constexpr int kGarbage = 2;
constexpr int kFlood = 3;
constexpr int kSlow = 4;

struct Plan {
    std::string executable;
    int good = 10000;
    int hostile = 2000;
    int seconds = 20;
    int rate = 10;
};

struct TickLog {
    std::uint64_t p99_us = 0;
    std::uint64_t max_us = 0;
    std::uint64_t late = 0;
    std::uint64_t accept_us = 0;
    std::uint64_t pump_us = 0;
    std::uint64_t advance_us = 0;
    std::uint64_t flush_us = 0;
    int lines = 0;
};

struct Measure {
    double handshake_s = 0;
    int handshakes = 0;
    std::size_t after = 0;
    std::size_t low = 0;
    std::size_t high = 0;
    std::size_t end = 0;
    int good_live = 0;
    int hostile_live = 0;
    int live_silence = 0;
    int live_garbage = 0;
    int live_flood = 0;
    int live_slow = 0;
    int drop_secure = 0;
    int drop_rate = 0;
    int drop_handshake = 0;
    int drop_slow = 0;
    int good_pings = 0;
    int slow_rcvbuf = 0;
    int slow_unread = 0;
    std::size_t bytes_base = 0;
    TickLog before;
    TickLog ticks;
};

struct Slot {
    game::net::TcpStream stream;
    std::optional<game::secure::ClientHandshake> client;
    std::optional<game::secure::RecordPipe> pipe;
    std::array<std::byte, kOutBytes> out{};
    std::size_t out_from = 0;
    std::size_t out_at = 0;
    std::array<std::byte, game::secure::kServerHelloBytes> held{};
    std::size_t held_at = 0;
    Clock::time_point next_ping;
    int kind = kGood;
    bool up = true;
    bool linked = false;
    bool greeted = false;
    bool reading = true;
};

struct Load {
    game::net::PollSet poll;
    std::vector<Slot> slots;
    game::secure::PublicKey pinned{};
    std::vector<std::byte> scratch;
    int rate = 10;
    TickLog ticks;
    HANDLE errors = nullptr;
    std::string pending_line;
    int slow_rcvbuf = 0;
    int drop_secure = 0;
    int drop_rate = 0;
    int drop_handshake = 0;
    int drop_slow = 0;
    int good_pings = 0;
    std::size_t bytes_base = 0;
};

struct Field {
    std::string_view line;
    std::string_view key;
};

struct Started {
    game::process::Child child;
    game::secure::PublicKey pinned{};
    std::filesystem::path dir;
    HANDLE errors = nullptr;
    HANDLE previous_error = nullptr;
    bool ready = false;
    // Cổng game gate đang nghe thật, đọc ở dòng ready; 0 khi gate chưa sẵn sàng.
    std::uint16_t game_port = 0;
    // Bảng [limits] đọc lại từ gate.toml công cụ đã ghi cho lượt này.
    game::config::GateLimits limits;
};

struct NamedCopy {
    std::filesystem::path from;
    std::filesystem::path dir;
    const char* name = "";
};

struct ErrorPipe {
    HANDLE read = nullptr;
    HANDLE write = nullptr;
};

[[nodiscard]] std::int64_t number_of(Field field) {
    const std::size_t place = field.line.find(field.key);
    if (place == std::string_view::npos) return -1;
    const std::string_view tail = field.line.substr(place + field.key.size());
    const char* first = tail.data();
    const char* last = first;
    std::advance(last, static_cast<std::ptrdiff_t>(tail.size()));
    std::int64_t value = 0;
    const std::from_chars_result parsed = std::from_chars(first, last, value);
    if (parsed.ec != std::errc{}) return -1;
    return value;
}

void note_drop(Load& load, std::string_view line) {
    if (!line.starts_with("gate: ngắt ")) return;
    if (line.contains("bản ghi bảo mật sai")) ++load.drop_secure;
    if (line.contains("vượt số tin")) ++load.drop_rate;
    if (line.contains("hết hạn bắt tay")) ++load.drop_handshake;
    if (line.contains("đọc quá chậm")) ++load.drop_slow;
}

void note_tick(TickLog& log, std::string_view line) {
    if (!line.starts_with("gate: tick ")) return;
    const std::int64_t p99 = number_of(Field{.line = line, .key = "p99_us="});
    const std::int64_t widest = number_of(Field{.line = line, .key = "max_us="});
    const std::int64_t late = number_of(Field{.line = line, .key = "late="});
    if (p99 >= 0) log.p99_us = std::max(log.p99_us, static_cast<std::uint64_t>(p99));
    if (widest >= 0) log.max_us = std::max(log.max_us, static_cast<std::uint64_t>(widest));
    if (late >= 0) log.late = static_cast<std::uint64_t>(late);
    const std::int64_t accept = number_of(Field{.line = line, .key = "accept_us="});
    const std::int64_t pumped = number_of(Field{.line = line, .key = "pump_us="});
    const std::int64_t advanced = number_of(Field{.line = line, .key = "advance_us="});
    const std::int64_t flushed = number_of(Field{.line = line, .key = "flush_us="});
    if (accept >= 0) log.accept_us = std::max(log.accept_us, static_cast<std::uint64_t>(accept));
    if (pumped >= 0) log.pump_us = std::max(log.pump_us, static_cast<std::uint64_t>(pumped));
    if (advanced >= 0) log.advance_us = std::max(log.advance_us, static_cast<std::uint64_t>(advanced));
    if (flushed >= 0) log.flush_us = std::max(log.flush_us, static_cast<std::uint64_t>(flushed));
    ++log.lines;
}

[[nodiscard]] std::size_t note_one(Load& load, std::size_t cut) {
    const std::string_view line{load.pending_line};
    note_drop(load, line.substr(0, cut));
    note_tick(load.ticks, line.substr(0, cut));
    load.pending_line.erase(0, cut + 1);
    return load.pending_line.find('\n');
}

void consume_lines(Load& load) {
    std::size_t cut = load.pending_line.find('\n');
    while (cut != std::string::npos) {
        cut = note_one(load, cut);
    }
}

void drain_errors(Load& load) {
    if (load.errors == nullptr) return;
    DWORD ready = 0;
    const BOOL peeked = PeekNamedPipe(load.errors, nullptr, 0, nullptr, &ready, nullptr);
    if (peeked == FALSE || ready == 0) return;
    std::array<char, 4096> buffer{};
    DWORD got = 0;
    const DWORD ask = std::min(ready, static_cast<DWORD>(buffer.size()));
    if (ReadFile(load.errors, buffer.data(), ask, &got, nullptr) == FALSE) return;
    load.pending_line.append(buffer.data(), static_cast<std::size_t>(got));
    consume_lines(load);
}

[[nodiscard]] std::size_t working_set(std::uint32_t pid) {
    const DWORD access = PROCESS_QUERY_INFORMATION | PROCESS_VM_READ;
    HANDLE process = OpenProcess(access, FALSE, pid);
    if (process == nullptr) return 0;
    PROCESS_MEMORY_COUNTERS info{};
    info.cb = sizeof(info);
    const BOOL read = GetProcessMemoryInfo(process, &info, sizeof(info));
    CloseHandle(process);
    if (read == FALSE) return 0;
    return info.WorkingSetSize;
}

// Thư mục cấu hình thật, tính từ thư mục đang đứng (gốc dự án): chỉ đọc làm mẫu.
[[nodiscard]] std::filesystem::path source_config() {
    return game::io::path_from_utf8("dev/server/config");
}

// Bảng [limits] của gate.toml nằm trong dir, đọc bằng bộ đọc của config (có kiểm miền). Rỗng khi
// không đọc được tệp hoặc tệp không qua bộ đọc.
[[nodiscard]] std::optional<game::config::GateLimits> limits_in(const std::filesystem::path& dir) {
    const game::io::TextResult text = game::io::read_text(dir / "gate.toml");
    if (!text.has_value()) return std::nullopt;
    const game::config::ReadResult<game::config::Gate> gate = game::config::read_gate(text.value());
    if (!gate.has_value()) return std::nullopt;
    return gate->limits;
}

// gate.toml của lượt đo: gate nghe 127.0.0.1 ở cổng do hệ điều hành cấp và báo cổng thật ở dòng
// `ready`, nên hai lượt đo chạy cùng lúc không tranh cổng. Trần tin mỗi giây chép từ `source`, bảng
// [limits] của gate.toml thật: số ấy chưa có nguồn (chủ dự án chốt 2026-10-09) nên công cụ không
// tự đặt.
[[nodiscard]] bool write_config(const std::filesystem::path& dir, int max_connections,
    const game::config::GateLimits& source) {
    std::ofstream out{dir / "gate.toml", std::ios::binary};
    out << "schema = 1\nidentity_key_file = \"identity.key\"\ntrusted_proxies = []\n";
    out << "[listen]\ngame = \"127.0.0.1:0\"\nauth = \"127.0.0.1:0\"\n";
    out << "[limits]\nmax_connections = " << max_connections << "\n";
    out << "per_ip_connections = " << max_connections << "\n";
    out << "handshake_timeout_ms = 2000\nidle_timeout_ms = 60000\n";
    out << "client_frame_bytes = 4096\nmessages_per_second = " << source.messages_per_second << "\n";
    out << "[client]\nmin_version = 1\n[ip_filter]\nallow = []\ndeny = []\n";
    return static_cast<bool>(out);
}

// Ghi gate.toml của lượt đo rồi đọc lại chính tệp đó vào started.limits: số in kèm kết quả đo là
// số gate sẽ đọc, không phải số công cụ định ghi.
[[nodiscard]] bool stage_limits(Started& started, int max_connections) {
    const std::optional<game::config::GateLimits> source = limits_in(source_config());
    if (!source.has_value()) {
        std::println(std::cerr, "không đọc được bảng [limits] của dev/server/config/gate.toml");
        return false;
    }
    if (!write_config(started.dir, max_connections, source.value())) return false;
    const std::optional<game::config::GateLimits> staged = limits_in(started.dir);
    if (!staged.has_value()) {
        std::println(std::cerr, "gate.toml của lượt đo không qua bộ đọc cấu hình");
        return false;
    }
    started.limits = staged.value();
    return true;
}

[[nodiscard]] bool copy_named(const NamedCopy& request) {
    std::error_code error;
    const std::filesystem::path source = request.from / request.name;
    const std::filesystem::path dest = request.dir / request.name;
    std::filesystem::copy_file(source, dest, std::filesystem::copy_options::overwrite_existing, error);
    return !error;
}

[[nodiscard]] bool prepare_tree(Started& started) {
    started.dir = game::io::executable_directory() / "gate-load";
    std::error_code error;
    std::filesystem::remove_all(started.dir, error);
    std::filesystem::create_directories(started.dir, error);
    if (error) return false;
    const std::filesystem::path config = source_config();
    NamedCopy cluster;
    cluster.from = config;
    cluster.dir = started.dir;
    cluster.name = "cluster.toml";
    NamedCopy log;
    log.from = config;
    log.dir = started.dir;
    log.name = "log.toml";
    return copy_named(cluster) && copy_named(log);
}

[[nodiscard]] bool write_identity_files(Started& started, int max_connections) {
    game::secure::Result<game::secure::Identity> identity = game::secure::Identity::generate();
    if (!identity.has_value()) return false;
    const game::secure::Identity owned = std::move(identity.value());
    const std::filesystem::path key_path = started.dir / "identity.key";
    const game::secure::Result<void> stored = owned.store_new(key_path);
    if (!stored.has_value()) return false;
    if (!stage_limits(started, max_connections)) return false;
    started.pinned = owned.public_key();
    return true;
}

[[nodiscard]] bool open_error_pipe(ErrorPipe& pipe) {
    SECURITY_ATTRIBUTES attributes{.nLength = sizeof(attributes), .lpSecurityDescriptor = nullptr, .bInheritHandle = 1};
    const DWORD capacity = 1U << 20U;
    if (CreatePipe(&pipe.read, &pipe.write, &attributes, capacity) == FALSE) return false;
    SetHandleInformation(pipe.read, HANDLE_FLAG_INHERIT, 0);
    return true;
}

[[nodiscard]] bool launch(Started& started, const Plan& plan, HANDLE write) {
    started.previous_error = GetStdHandle(STD_ERROR_HANDLE);
    SetStdHandle(STD_ERROR_HANDLE, write);
    const std::string executable = plan.executable;
    const std::string folder = game::io::utf8_of(started.dir);
    const std::array<std::string_view, 2> arguments{"--config", folder};
    game::process::Spawn request;
    request.executable = executable;
    request.arguments = arguments;
    request.mode = game::process::Mode::kService;
    game::core::Result<game::process::Child> child = game::process::spawn(request);
    SetStdHandle(STD_ERROR_HANDLE, started.previous_error);
    if (!child.has_value()) return false;
    started.child = std::move(child.value());
    return true;
}

// Cổng game gate báo ở dòng sẵn sàng `ready game=<cổng> auth=<cổng>`; 0 khi dòng không phải dòng
// ready hợp lệ hoặc thiếu khoá game.
[[nodiscard]] std::uint16_t game_port_of(std::string_view line) noexcept {
    const std::expected<game::supervise::ReadyPorts, game::supervise::ReadyFault> ports =
        game::supervise::parse_ready(line);
    return ports.has_value() ? ports->game : std::uint16_t{0};
}

[[nodiscard]] Started start_gate(const Plan& plan, int max_connections) {
    Started started;
    if (!prepare_tree(started) || !write_identity_files(started, max_connections)) return started;
    ErrorPipe pipe;
    if (!open_error_pipe(pipe)) return started;
    const bool launched = launch(started, plan, pipe.write);
    CloseHandle(pipe.write);
    if (!launched) {
        CloseHandle(pipe.read);
        return started;
    }
    started.errors = pipe.read;
    const game::core::Result<game::process::Line> line = started.child.read_line(std::chrono::seconds{15});
    if (line.has_value()) started.game_port = game_port_of(line.value().text);
    started.ready = started.game_port != 0;
    if (!started.ready) started.child.force_stop();
    return started;
}

[[nodiscard]] bool queue_bytes(Slot& slot, ByteView bytes) {
    if (slot.out_at != slot.out_from) return false;
    if (bytes.size() > slot.out.size()) return false;
    std::ranges::copy(bytes, slot.out.begin());
    slot.out_from = 0;
    slot.out_at = bytes.size();
    return true;
}

[[nodiscard]] bool seal_queued(Slot& slot, const std::vector<std::byte>& scratch) {
    if (!slot.pipe.has_value()) return false;
    std::array<std::byte, game::secure::kMaxRecordBytes> sealed{};
    const game::secure::SealResult wrote = slot.pipe->seal(scratch, sealed);
    if (!wrote.has_value()) return false;
    const ByteView view = std::span{sealed}.first(wrote.value());
    return queue_bytes(slot, view);
}

[[nodiscard]] bool queue_ping(Slot& slot, std::vector<std::byte>& scratch) {
    scratch.clear();
    game::protocol::Ping ping;
    ping.client_time = std::chrono::milliseconds{0};
    if (!game::protocol::encode(scratch, ping)) return false;
    return seal_queued(slot, scratch);
}

[[nodiscard]] bool queue_hello(Slot& slot, std::vector<std::byte>& scratch) {
    scratch.clear();
    game::protocol::Hello hello;
    hello.version = 1;
    hello.platform = game::protocol::Platform::kWindows;
    hello.build = 1;
    if (!game::protocol::encode(scratch, hello)) return false;
    return seal_queued(slot, scratch);
}

void drop_slot(Load& load, Slot& slot, std::uint64_t tag) {
    slot.up = false;
    slot.linked = true;
    slot.reading = false;
    load.poll.remove(tag);
}

void send_out(Load& load, Slot& slot, std::uint64_t tag) {
    if (!slot.up || slot.out_from == slot.out_at) return;
    const std::size_t count = slot.out_at - slot.out_from;
    const ByteView pending = std::span{slot.out}.subspan(slot.out_from, count);
    const game::net::NetResult<std::size_t> sent = slot.stream.send(pending);
    if (!sent.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    slot.out_from += sent.value();
    if (slot.out_from != slot.out_at) {
        load.poll.want_write(tag, true);
        return;
    }
    slot.out_from = 0;
    slot.out_at = 0;
    load.poll.want_write(tag, false);
}

void tighten_receive(game::net::SocketHandle handle) {
    const SOCKET raw{static_cast<std::uintptr_t>(handle)};
    const int bytes = kReceiveCap;
    std::array<char, sizeof(bytes)> stored{};
    std::memcpy(stored.data(), &bytes, sizeof(bytes));
    const int opt_len = static_cast<int>(stored.size());
    const int set = setsockopt(raw, SOL_SOCKET, SO_RCVBUF, stored.data(), opt_len);
    static_cast<void>(set);
}

void remember_rcvbuf(Load& load, game::net::SocketHandle handle) {
    if (load.slow_rcvbuf != 0) return;
    const SOCKET raw{static_cast<std::uintptr_t>(handle)};
    std::array<char, sizeof(int)> stored{};
    int opt_len = static_cast<int>(stored.size());
    const int got = getsockopt(raw, SOL_SOCKET, SO_RCVBUF, stored.data(), &opt_len);
    if (got != 0) {
        load.slow_rcvbuf = -WSAGetLastError();
        return;
    }
    if (opt_len < 0 || static_cast<std::size_t>(opt_len) < sizeof(int)) {
        load.slow_rcvbuf = -opt_len;
        return;
    }
    int actual = 0;
    std::memcpy(&actual, stored.data(), sizeof(actual));
    load.slow_rcvbuf = actual == 0 ? -1 : actual;
}

void begin_one(Load& load, game::net::Endpoint target, int kind) {
    game::net::NetResult<game::net::TcpStream> stream = game::net::TcpStream::begin_connect(target);
    if (!stream.has_value()) return;
    if (kind == kSlow) tighten_receive(stream->handle());
    Slot slot;
    slot.stream = std::move(stream.value());
    slot.kind = kind;
    const std::uint64_t index = load.slots.size();
    if (!load.poll.add(slot.stream.handle(), index)) return;
    load.poll.want_write(index, true);
    load.slots.push_back(std::move(slot));
}

void send_silence(Load& load, Slot& slot, std::uint64_t tag) {
    const std::array<std::byte, 4> partial{};
    if (!queue_bytes(slot, partial)) drop_slot(load, slot, tag);
}

void send_garbage(Load& load, Slot& slot, std::uint64_t tag) {
    std::array<std::byte, 48> noise{};
    noise.fill(std::byte{0xFF});
    if (!queue_bytes(slot, noise)) drop_slot(load, slot, tag);
}

void send_client_hello(Load& load, Slot& slot, std::uint64_t tag) {
    game::secure::Result<game::secure::ClientHandshake> client = game::secure::ClientHandshake::begin();
    if (!client.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    slot.client = std::move(client.value());
    if (!queue_bytes(slot, slot.client->hello())) drop_slot(load, slot, tag);
}

void on_connected(Load& load, Slot& slot, std::uint64_t tag) {
    const game::net::NetResult<bool> done = slot.stream.finish_connect();
    if (!done.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    if (!done.value()) return;
    slot.linked = true;
    if (slot.kind == kSlow) remember_rcvbuf(load, slot.stream.handle());
    if (slot.kind == kSilence) send_silence(load, slot, tag);
    if (slot.kind == kSilence) return;
    if (slot.kind == kGarbage) send_garbage(load, slot, tag);
    if (slot.kind == kGarbage) return;
    send_client_hello(load, slot, tag);
}

[[nodiscard]] int pace_ms(const Load& load, int kind) {
    if (kind == kFlood) return 0;
    if (kind == kSlow) return 1000 / 30;
    return 1000 / std::max(load.rate, 1);
}

void mark_greeted(const Load& load, Slot& slot) {
    slot.greeted = true;
    const int gap = pace_ms(load, slot.kind);
    if (gap == 0) return;
    slot.next_ping = Clock::now() + std::chrono::milliseconds{gap};
}

void append_held(Slot& slot, ByteView bytes) {
    const std::span<std::byte> dest = std::span{slot.held}.subspan(slot.held_at, bytes.size());
    std::ranges::copy(bytes, dest.begin());
    slot.held_at += bytes.size();
}

void mute_slow(Load& load, Slot& slot, std::uint64_t tag) {
    if (slot.kind != kSlow || !slot.pipe.has_value() || !slot.reading) return;
    slot.reading = false;
    load.poll.remove(tag);
}

void accept_server_hello(Load& load, Slot& slot, std::uint64_t tag) {
    if (!slot.client.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    const ByteView hello = std::span{slot.held}.first(game::secure::kServerHelloBytes);
    game::secure::ClientHandshake client = std::move(slot.client.value());
    slot.client.reset();
    game::secure::Result<game::secure::SessionKeys> keys = client.finish(hello, load.pinned);
    slot.held_at = 0;
    if (!keys.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    slot.pipe.emplace(std::move(keys.value()));
    if (!queue_hello(slot, load.scratch)) drop_slot(load, slot, tag);
    if (!slot.up) return;
    mark_greeted(load, slot);
    mute_slow(load, slot, tag);
}

[[nodiscard]] std::size_t take_reply(Load& load, Slot& slot, std::uint64_t tag, ByteView bytes) {
    if (!slot.client.has_value() || bytes.empty()) return 0;
    const std::size_t need = game::secure::kServerHelloBytes;
    if (slot.held_at >= need) return 0;
    const std::size_t take = std::min(need - slot.held_at, bytes.size());
    append_held(slot, bytes.first(take));
    if (slot.held_at < need) return take;
    accept_server_hello(load, slot, tag);
    return take;
}

[[nodiscard]] bool open_next(Slot& slot, ByteView& bytes, std::span<std::byte> plain) {
    if (!slot.pipe.has_value() || !slot.up || bytes.empty()) return false;
    const game::secure::OpenResult opened = slot.pipe->open_bytes(bytes, plain);
    if (!opened.has_value()) {
        slot.up = false;
        return false;
    }
    const game::secure::Opened done = opened.value();
    if (done.consumed > bytes.size()) return false;
    bytes = bytes.subspan(done.consumed);
    return done.written > 0 && !bytes.empty();
}

void take_live(Slot& slot, ByteView bytes) {
    std::array<std::byte, game::secure::kMaxPlainBytes> plain{};
    bool more = true;
    while (more) {
        more = open_next(slot, bytes, plain);
    }
}

void on_readable(Load& load, Slot& slot, std::uint64_t tag) {
    if (!slot.reading || !slot.up) return;
    std::array<std::byte, kReadBytes> buffer{};
    const game::net::NetResult<std::size_t> got = slot.stream.receive(buffer);
    if (!got.has_value()) {
        drop_slot(load, slot, tag);
        return;
    }
    if (got.value() == 0) return;
    ByteView bytes = std::span{buffer}.first(got.value());
    if (!slot.pipe.has_value()) bytes = bytes.subspan(take_reply(load, slot, tag, bytes));
    if (!slot.up || !slot.reading) return;
    if (!slot.pipe.has_value()) return;
    take_live(slot, bytes);
    if (!slot.up) drop_slot(load, slot, tag);
}

void send_due(Load& load, Slot& slot, std::uint64_t tag, Clock::time_point now) {
    if (!slot.up || !slot.greeted || slot.out_at != slot.out_from) return;
    if (now < slot.next_ping) return;
    const bool paces = slot.kind == kGood || slot.kind == kFlood || slot.kind == kSlow;
    if (!paces) return;
    if (!queue_ping(slot, load.scratch)) {
        drop_slot(load, slot, tag);
        return;
    }
    if (slot.kind == kGood) ++load.good_pings;
    const int gap = pace_ms(load, slot.kind);
    if (gap != 0) slot.next_ping = now + std::chrono::milliseconds{gap};
    send_out(load, slot, tag);
}

void drive_slot(Load& load, Slot& slot, std::uint64_t tag, Clock::time_point now) {
    if (!slot.up) return;
    send_out(load, slot, tag);
    send_due(load, slot, tag, now);
}

void sweep(Load& load, Clock::time_point now) {
    for (std::size_t index = 0; index < load.slots.size(); ++index) {
        const std::uint64_t tag = index;
        drive_slot(load, load.slots[index], tag, now);
    }
}

void pump_one(Load& load, const game::net::PollEvent& event) {
    if (event.tag >= load.slots.size()) return;
    Slot& slot = load.slots[event.tag];
    if (!slot.up) return;
    const bool connecting = (event.writable || event.failed) && !slot.linked;
    if (connecting) on_connected(load, slot, event.tag);
    if (!slot.up) return;
    if (event.writable || event.failed) send_out(load, slot, event.tag);
    if (!slot.up) return;
    if (event.readable || event.failed) on_readable(load, slot, event.tag);
}

void dispatch_events(Load& load, const game::net::PollEvents& events) {
    for (const game::net::PollEvent& event : events) {
        pump_one(load, event);
    }
}

void pump(Load& load) {
    game::net::PollEvents events;
    const game::net::NetResult<void> waited = load.poll.wait(game::net::Milliseconds{kPumpMs}, events);
    const Clock::time_point now = Clock::now();
    if (waited.has_value()) dispatch_events(load, events);
    sweep(load, now);
    drain_errors(load);
}

[[nodiscard]] bool counts(const Slot& slot, bool hostile) {
    const bool is_hostile = slot.kind != kGood;
    if (!slot.up || is_hostile != hostile) return false;
    if (hostile) return true;
    return slot.greeted;
}

[[nodiscard]] int count_up(const Load& load, bool hostile) {
    int count = 0;
    for (const Slot& slot : load.slots) {
        count += counts(slot, hostile) ? 1 : 0;
    }
    return count;
}

[[nodiscard]] int decimal_of(std::string_view text) {
    int value = 0;
    const char* first = text.data();
    const char* last = first;
    std::advance(last, static_cast<std::ptrdiff_t>(text.size()));
    const std::from_chars_result parsed = std::from_chars(first, last, value);
    if (parsed.ec != std::errc{}) return 0;
    return value;
}

struct Arg {
    std::string_view key;
    std::string_view raw;
};

void apply_arg(Plan& plan, Arg arg) {
    if (arg.key == "--exe") plan.executable = std::string{arg.raw};
    const int value = decimal_of(arg.raw);
    if (arg.key == "--good") plan.good = value;
    if (arg.key == "--hostile") plan.hostile = value;
    if (arg.key == "--seconds") plan.seconds = value;
    if (arg.key == "--rate") plan.rate = value;
}

[[nodiscard]] Plan arguments_of(int argc, char* const* argv) {
    Plan plan;
    const std::filesystem::path exe = game::io::executable_directory() / "thienlong_gate.exe";
    plan.executable = game::io::utf8_of(exe);
    const auto count = static_cast<std::size_t>(argc);
    const std::span<char* const> args{argv, count};
    for (std::size_t index = 1; index + 1 < args.size(); index += 2) {
        const Arg arg{.key = args[index], .raw = args[index + 1]};
        apply_arg(plan, arg);
    }
    return plan;
}

struct Progress {
    game::net::Endpoint target{};
    bool ready = false;
    int goods = 0;
    int silence = 0;
    int garbage = 0;
    int flood = 0;
    int slow = 0;
    int each = 0;
    int slow_want = 0;
};

[[nodiscard]] Progress progress_of(const Plan& plan, std::uint16_t game_port) {
    Progress progress;
    progress.target = game::net::Endpoint{.address = {127, 0, 0, 1}, .port = game_port};
    progress.ready = true;
    progress.each = plan.hostile / 4;
    progress.slow_want = plan.hostile - (3 * progress.each);
    return progress;
}

struct KindStep {
    int want = 0;
    int kind = kGood;
};

struct OpenState {
    int started = 0;
    int budget = 0;
};

[[nodiscard]] OpenState open_kind(Load& load, const Progress& progress, KindStep step, OpenState state) {
    if (!progress.ready || state.budget <= 0 || state.started >= step.want) return state;
    begin_one(load, progress.target, step.kind);
    --state.budget;
    ++state.started;
    return state;
}

void step_one(Load& load, const Progress& progress, int& started, KindStep step, int& budget) {
    OpenState opened{.started = started, .budget = budget};
    opened = open_kind(load, progress, step, opened);
    started = opened.started;
    budget = opened.budget;
}

void open_hostiles(Load& load, Progress& progress, int& budget) {
    const KindStep silence{.want = progress.each, .kind = kSilence};
    step_one(load, progress, progress.silence, silence, budget);
    const KindStep garbage{.want = progress.each, .kind = kGarbage};
    step_one(load, progress, progress.garbage, garbage, budget);
    const KindStep flood{.want = progress.each, .kind = kFlood};
    step_one(load, progress, progress.flood, flood, budget);
    const KindStep slow{.want = progress.slow_want, .kind = kSlow};
    step_one(load, progress, progress.slow, slow, budget);
}

[[nodiscard]] int connecting(const Load& load) {
    int count = 0;
    for (const Slot& slot : load.slots) {
        count += slot.up && !slot.linked ? 1 : 0;
    }
    return count;
}

void open_batch(Load& load, Progress& progress, const Plan& plan, bool hostiles) {
    if (connecting(load) >= kOpenBatch) return;
    int budget = kOpenBatch;
    while (budget > 0) {
        const int before = budget;
        const KindStep good{.want = plan.good, .kind = kGood};
        step_one(load, progress, progress.goods, good, budget);
        if (hostiles) open_hostiles(load, progress, budget);
        if (budget == before) return;
    }
}

void pump_until_goods(Load& load, Progress& progress, const Plan& plan) {
    const Clock::time_point deadline = Clock::now() + std::chrono::seconds{kConnectSeconds};
    while (Clock::now() < deadline && count_up(load, false) < plan.good) {
        open_batch(load, progress, plan, false);
        pump(load);
    }
}

void watch_memory(Measure& measure, std::size_t bytes) {
    measure.low = std::min(measure.low, bytes);
    measure.high = std::max(measure.high, bytes);
    measure.end = bytes;
}

struct Alive {
    int silence = 0;
    int garbage = 0;
    int flood = 0;
    int slow = 0;
};

void tally_one(Alive& alive, const Slot& slot) {
    if (!slot.up) return;
    if (slot.kind == kSilence) ++alive.silence;
    if (slot.kind == kGarbage) ++alive.garbage;
    if (slot.kind == kFlood) ++alive.flood;
    if (slot.kind == kSlow) ++alive.slow;
}

[[nodiscard]] Alive tally(const Load& load) {
    Alive alive;
    for (const Slot& slot : load.slots) {
        tally_one(alive, slot);
    }
    return alive;
}

void fill_handshake(Measure& measure, const Load& load, std::uint32_t pid, Clock::time_point began) {
    measure.handshake_s = std::chrono::duration<double>(Clock::now() - began).count();
    measure.handshakes = count_up(load, false);
    measure.bytes_base = load.bytes_base;
    measure.after = working_set(pid);
    measure.low = measure.after;
    measure.high = measure.after;
    measure.end = measure.after;
}

[[nodiscard]] int unread_bytes(game::net::SocketHandle handle) {
    const SOCKET raw{static_cast<std::uintptr_t>(handle)};
    u_long pending = 0;
    if (ioctlsocket(raw, FIONREAD, &pending) != 0) return -WSAGetLastError();
    if (pending > 1000000000UL) return 1000000000;
    return static_cast<int>(pending);
}

[[nodiscard]] int unread_if_slow(const Slot& slot) {
    if (slot.kind != kSlow || !slot.stream.is_open()) return -1;
    return unread_bytes(slot.stream.handle());
}

[[nodiscard]] int keep_unread(int found, const Slot& slot) {
    if (found >= 0) return found;
    return unread_if_slow(slot);
}

[[nodiscard]] int slow_pending(const Load& load) {
    int found = -1;
    for (const Slot& slot : load.slots) {
        found = keep_unread(found, slot);
    }
    return found;
}

struct RunAt {
    std::uint32_t pid = 0;
    Clock::time_point began;
};

[[nodiscard]] Measure sample_run(Load& load, Progress& progress, const Plan& plan, RunAt at) {
    Measure measure;
    fill_handshake(measure, load, at.pid, at.began);
    measure.before = load.ticks;
    const Clock::time_point done = Clock::now() + std::chrono::seconds{plan.seconds};
    while (Clock::now() < done) {
        open_batch(load, progress, plan, true);
        pump(load);
        watch_memory(measure, working_set(at.pid));
    }
    drain_errors(load);
    measure.good_live = count_up(load, false);
    measure.hostile_live = count_up(load, true);
    const Alive alive = tally(load);
    measure.live_silence = alive.silence;
    measure.live_garbage = alive.garbage;
    measure.live_flood = alive.flood;
    measure.live_slow = alive.slow;
    measure.drop_secure = load.drop_secure;
    measure.drop_rate = load.drop_rate;
    measure.drop_handshake = load.drop_handshake;
    measure.drop_slow = load.drop_slow;
    measure.good_pings = load.good_pings;
    measure.slow_rcvbuf = load.slow_rcvbuf;
    measure.slow_unread = slow_pending(load);
    measure.ticks = load.ticks;
    return measure;
}

[[nodiscard]] double per_connection(const Measure& measure) {
    if (measure.handshakes == 0 || measure.after <= measure.bytes_base) return 0;
    const std::size_t grew = measure.after - measure.bytes_base;
    return static_cast<double>(grew) / static_cast<double>(measure.handshakes);
}

[[nodiscard]] double per_second(const Measure& measure) {
    if (measure.handshake_s <= 0) return 0;
    return static_cast<double>(measure.handshakes) / measure.handshake_s;
}

// Giới hạn gate dùng trong lượt đo. Mọi số đo đi kèm dòng này: messages_per_second chưa có nguồn,
// nên một số đo không ghi giá trị ấy thì không so được với lượt khác.
void print_config(const game::config::GateLimits& limits) {
    std::println("config messages_per_second={} handshake_timeout_ms={} idle_timeout_ms={} max_connections={}",
        limits.messages_per_second, limits.handshake_timeout_ms.count(), limits.idle_timeout_ms.count(),
        limits.max_connections);
}

void print_report(const Plan& plan, const Measure& measure) {
    std::println("good {} hostile {} seconds {}", plan.good, plan.hostile, plan.seconds);
    std::println("handshake_s {:.3f} handshakes {} handshake_per_s {:.1f}", measure.handshake_s, measure.handshakes,
        per_second(measure));
    std::println("bytes_base {} bytes_after {} bytes_per_good {:.0f}", measure.bytes_base, measure.after,
        per_connection(measure));
    std::println("bytes_low {} bytes_high {} bytes_end {}", measure.low, measure.high, measure.end);
    std::println("good_live {} hostile_live {} good_pings {}", measure.good_live, measure.hostile_live,
        measure.good_pings);
    std::println("live_silence {} live_garbage {} live_flood {} live_slow {}", measure.live_silence,
        measure.live_garbage, measure.live_flood, measure.live_slow);
    std::println("drop_secure {} drop_rate {} drop_handshake {} drop_slow {}", measure.drop_secure, measure.drop_rate,
        measure.drop_handshake, measure.drop_slow);
    std::println("slow_rcvbuf {} slow_unread {}", measure.slow_rcvbuf, measure.slow_unread);
    std::println("tick_lines {} p99_us {} max_us {} late {}", measure.ticks.lines, measure.ticks.p99_us,
        measure.ticks.max_us, measure.ticks.late);
    std::println("p99_before {} max_before {} late_before {}", measure.before.p99_us, measure.before.max_us,
        measure.before.late);
    std::println("accept_us {} pump_us {} advance_us {} flush_us {}", measure.ticks.accept_us, measure.ticks.pump_us,
        measure.ticks.advance_us, measure.ticks.flush_us);
}

void abort_one(Slot& slot) {
    if (slot.stream.is_open()) slot.stream.abort();
}

void abort_open(Load& load) {
    for (Slot& slot : load.slots) {
        abort_one(slot);
    }
}

void stop_child(Started& started) {
    if (started.child) {
        started.child.close_input();
        const game::process::ExitStatus status = started.child.wait_for(std::chrono::seconds{10});
        if (status.kind != game::process::WaitKind::kExited) started.child.force_stop();
    }
    if (started.errors != nullptr) CloseHandle(started.errors);
    started.errors = nullptr;
    std::error_code error;
    if (!started.dir.empty()) std::filesystem::remove_all(started.dir, error);
}

[[nodiscard]] bool plan_ok(const Plan& plan) {
    if (plan.good < 0 || plan.hostile < 0) return false;
    return plan.seconds >= 1 && plan.rate >= 1;
}

void arm_load(Load& load, const Started& started, const Plan& plan, int cap) {
    load.pinned = started.pinned;
    load.rate = plan.rate;
    load.errors = started.errors;
    load.scratch.reserve(64);
    load.slots.reserve(static_cast<std::size_t>(cap));
}

[[nodiscard]] int run(int argc, char* const* argv) {
    SetConsoleOutputCP(CP_UTF8);
    const Plan plan = arguments_of(argc, argv);
    if (!plan_ok(plan)) return 1;
    const game::net::NetResult<game::net::Network> network = game::net::Network::start();
    if (!network.has_value()) return 1;
    const int cap = std::max(plan.good + plan.hostile + 16, 32);
    Started started = start_gate(plan, cap);
    if (!started.ready) {
        // Gate chưa chạy là hỏng ở bước dựng cây cấu hình của lượt đo, không phải ở dòng ready.
        const bool has_launched = static_cast<bool>(started.child);
        stop_child(started);
        std::println(std::cerr, "{}",
            has_launched ? "gate không in dòng ready mang cổng game" : "không chuẩn bị được lượt đo, gate chưa chạy");
        return 1;
    }
    Load load;
    arm_load(load, started, plan, cap);
    load.bytes_base = working_set(started.child.id());
    const Clock::time_point began = Clock::now();
    Progress progress = progress_of(plan, started.game_port);
    pump_until_goods(load, progress, plan);
    const RunAt at{.pid = started.child.id(), .began = began};
    const Measure measure = sample_run(load, progress, plan, at);
    print_config(started.limits);
    print_report(plan, measure);
    abort_open(load);
    stop_child(started);
    return 0;
}

} // namespace

int main(int argc, char* const* argv) {
    try {
        return run(argc, argv);
    } catch (const std::exception& error) {
        static_cast<void>(std::fputs("gate_load: unhandled exception: ", stderr));
        static_cast<void>(std::fputs(error.what(), stderr));
        static_cast<void>(std::fputc('\n', stderr));
        return 1;
    } catch (...) {
        static_cast<void>(std::fputs("gate_load: unhandled non-standard exception\n", stderr));
        return 1;
    }
}
