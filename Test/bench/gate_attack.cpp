// Tấn công thật vào gate + auth + store đang chạy trên máy này (dev/server, PostgreSQL cục bộ).
// Không thư viện mới: Winsock, libsodium qua game_secure, mã khung của game_protocol.
// Mỗi kịch bản in một dòng "kq ..." với số đo; dòng "SAI ..." là hành vi sai so với thiết kế.
// Dùng: gate_attack --pub <hex khoá công khai gate> --pids <gate>,<auth>,<store> [--only <tên>]
// Địa chỉ nguồn là 127.1.x.y khác nhau để vượt trần mỗi IP khi cần nhiều kết nối.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <psapi.h>

#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <format>
#include <mutex>
#include <optional>
#include <print>
#include <random>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <variant>
#include <vector>

namespace {

using namespace game;
using Clock = std::chrono::steady_clock;
using Bytes = std::vector<std::byte>;

constexpr std::uint16_t kGamePort = 7000;
constexpr std::uint16_t kAuthPort = 7001;
constexpr std::uint16_t kStoreIpc = 7010;
constexpr std::uint16_t kAuthIpc = 7011;

secure::PublicKey g_pub{};
std::array<DWORD, 3> g_pids{};
std::atomic<int> g_faults{0};

void fault(std::string_view what) {
    ++g_faults;
    std::println("SAI {}", what);
    std::fflush(stdout);
}

[[nodiscard]] double ms_since(Clock::time_point start) {
    return std::chrono::duration<double, std::milli>(Clock::now() - start).count();
}

struct Samples {
    std::mutex lock;
    std::vector<double> values;
    void add(double value) {
        const std::scoped_lock hold{lock};
        values.push_back(value);
    }
};

[[nodiscard]] double pick(std::vector<double> values, double share) {
    if (values.empty()) return 0;
    std::ranges::sort(values);
    const auto at = std::min(values.size() - 1, static_cast<std::size_t>(share * static_cast<double>(values.size())));
    return values[at];
}

void report(std::string_view name, Samples& samples) {
    const std::scoped_lock hold{samples.lock};
    std::println("kq {} n={} p50_ms={:.2f} p99_ms={:.2f} max_ms={:.2f}", name, samples.values.size(),
        pick(samples.values, 0.5), pick(samples.values, 0.99), pick(samples.values, 1.0));
}

struct Usage {
    double cpu_s = 0;
    std::size_t working = 0;
    std::size_t peak = 0;
};

[[nodiscard]] Usage usage_of(DWORD pid) {
    Usage usage;
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (process == nullptr) return usage;
    FILETIME created{}, exited{}, kernel{}, user{};
    if (GetProcessTimes(process, &created, &exited, &kernel, &user) != 0) {
        const auto ticks = [](FILETIME time) {
            return (static_cast<std::uint64_t>(time.dwHighDateTime) << 32U) | time.dwLowDateTime;
        };
        usage.cpu_s = static_cast<double>(ticks(kernel) + ticks(user)) / 1e7;
    }
    PROCESS_MEMORY_COUNTERS counters{};
    if (GetProcessMemoryInfo(process, &counters, sizeof(counters)) != 0) {
        usage.working = counters.WorkingSetSize;
        usage.peak = counters.PeakWorkingSetSize;
    }
    CloseHandle(process);
    return usage;
}

[[nodiscard]] bool alive(DWORD pid) {
    HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, pid);
    if (process == nullptr) return false;
    const bool running = WaitForSingleObject(process, 0) == WAIT_TIMEOUT;
    CloseHandle(process);
    return running;
}

struct Phase {
    std::string name;
    Clock::time_point start = Clock::now();
    std::array<Usage, 3> before{};

    explicit Phase(std::string label) : name(std::move(label)) {
        for (std::size_t at = 0; at < 3; ++at) before[at] = usage_of(g_pids[at]);
        std::println("== {}", name);
        std::fflush(stdout);
    }

    ~Phase() {
        const double seconds = ms_since(start) / 1000.0;
        constexpr std::array<std::string_view, 3> kNames{"gate", "auth", "store"};
        for (std::size_t at = 0; at < 3; ++at) {
            const Usage after = usage_of(g_pids[at]);
            const double cpu = seconds > 0 ? 100.0 * (after.cpu_s - before[at].cpu_s) / seconds : 0;
            std::println("kq {} {} cpu_pct_1core={:.1f} ws_mb={:.1f} peak_ws_mb={:.1f} alive={}", name, kNames[at], cpu,
                static_cast<double>(after.working) / 1048576.0, static_cast<double>(after.peak) / 1048576.0,
                alive(g_pids[at]));
            if (!alive(g_pids[at])) fault(std::format("{} chết sau {}", kNames[at], name));
        }
        std::println("kq {} seconds={:.2f}", name, seconds);
        std::fflush(stdout);
    }

    Phase(const Phase&) = delete;
    Phase& operator=(const Phase&) = delete;
};

[[nodiscard]] std::uint32_t source_of(int index) {
    const auto third = static_cast<std::uint32_t>((index / 250) & 0xFF);
    const auto fourth = static_cast<std::uint32_t>((index % 250) + 1);
    return (127U << 24U) | (1U << 16U) | (third << 8U) | fourth;
}

[[nodiscard]] SOCKET open_socket(std::uint32_t source, std::uint16_t port, bool blocking) {
    SOCKET handle = WSASocketW(AF_INET, SOCK_STREAM, IPPROTO_TCP, nullptr, 0, WSA_FLAG_NO_HANDLE_INHERIT);
    if (handle == INVALID_SOCKET) return INVALID_SOCKET;
    sockaddr_in local{};
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = htonl(source);
    if (bind(handle, reinterpret_cast<const sockaddr*>(&local), sizeof(local)) != 0) {
        closesocket(handle);
        return INVALID_SOCKET;
    }
    const int one = 1;
    setsockopt(handle, IPPROTO_TCP, TCP_NODELAY, reinterpret_cast<const char*>(&one), sizeof(one));
    if (blocking) {
        const DWORD limit = 15000;
        setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&limit), sizeof(limit));
        setsockopt(handle, SOL_SOCKET, SO_SNDTIMEO, reinterpret_cast<const char*>(&limit), sizeof(limit));
    } else {
        u_long enabled = 1;
        ioctlsocket(handle, FIONBIO, &enabled);
    }
    sockaddr_in target{};
    target.sin_family = AF_INET;
    target.sin_port = htons(port);
    target.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    const int rc = connect(handle, reinterpret_cast<const sockaddr*>(&target), sizeof(target));
    if (rc != 0 && WSAGetLastError() != WSAEWOULDBLOCK) {
        closesocket(handle);
        return INVALID_SOCKET;
    }
    return handle;
}

void hard_close(SOCKET handle) {
    if (handle == INVALID_SOCKET) return;
    const linger hard{1, 0};
    setsockopt(handle, SOL_SOCKET, SO_LINGER, reinterpret_cast<const char*>(&hard), sizeof(hard));
    closesocket(handle);
}

[[nodiscard]] bool send_all(SOCKET handle, std::span<const std::byte> data) {
    std::size_t sent = 0;
    while (sent < data.size()) {
        const int wrote = send(handle, reinterpret_cast<const char*>(data.data() + sent),
            static_cast<int>(data.size() - sent), 0);
        if (wrote <= 0) return false;
        sent += static_cast<std::size_t>(wrote);
    }
    return true;
}

// Chờ bên kia đóng: true khi recv thấy FIN/RST trong hạn.
[[nodiscard]] bool closed_within(SOCKET handle, int limit_ms) {
    const DWORD limit = static_cast<DWORD>(limit_ms);
    setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&limit), sizeof(limit));
    std::array<char, 4096> sink{};
    const Clock::time_point start = Clock::now();
    while (ms_since(start) < limit_ms) {
        const int got = recv(handle, sink.data(), static_cast<int>(sink.size()), 0);
        if (got == 0) return true;
        if (got < 0) return WSAGetLastError() != WSAETIMEDOUT;
    }
    return false;
}

struct Got {
    enum class Kind : std::uint8_t { kNone, kWant, kReject, kGoodbye } kind = Kind::kNone;
    protocol::ErrorCode code = protocol::ErrorCode::kMalformed;
    protocol::GameServerMessage game;
    protocol::AuthServerMessage auth;
};

class Link {
public:
    Link() = default;
    Link(const Link&) = delete;
    Link& operator=(const Link&) = delete;
    ~Link() { close(); }

    [[nodiscard]] bool open(std::uint32_t source, std::uint16_t port) {
        socket_ = open_socket(source, port, true);
        if (socket_ == INVALID_SOCKET) return false;
        secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
        if (!client || !send_all(socket_, client->hello())) return false;
        std::array<std::byte, secure::kServerHelloBytes> reply{};
        if (!recv_exact(reply)) return false;
        secure::Result<secure::SessionKeys> keys = client->finish(reply, g_pub);
        if (!keys) return false;
        pipe_.emplace(std::move(*keys));
        return true;
    }

    template <typename Message>
    [[nodiscard]] bool send(const Message& message) {
        Bytes plain;
        if (!protocol::encode(plain, message)) return false;
        return send_plain(plain);
    }

    [[nodiscard]] bool send_plain(std::span<const std::byte> plain) {
        std::array<std::byte, secure::kMaxRecordBytes> out{};
        const secure::SealResult sealed = pipe_->seal(plain, out);
        if (!sealed) return false;
        return send_all(socket_, std::span<const std::byte>{out}.first(*sealed));
    }

    [[nodiscard]] bool send_raw(std::span<const std::byte> bytes) { return send_all(socket_, bytes); }

    [[nodiscard]] std::optional<Bytes> next_frame() {
        std::array<std::byte, secure::kMaxPlainBytes> plain{};
        for (;;) {
            if (!held_.empty()) {
                const secure::OpenResult opened = pipe_->open_bytes(held_, plain);
                if (!opened) return std::nullopt;
                held_.erase(held_.begin(), held_.begin() + static_cast<std::ptrdiff_t>(opened->consumed));
                if (opened->written > 0) return Bytes{plain.begin(), plain.begin() + static_cast<std::ptrdiff_t>(opened->written)};
                if (opened->consumed > 0 && !held_.empty()) continue;
            }
            std::array<std::byte, 8192> chunk{};
            const int got = recv(socket_, reinterpret_cast<char*>(chunk.data()), static_cast<int>(chunk.size()), 0);
            if (got <= 0) return std::nullopt;
            held_.insert(held_.end(), chunk.begin(), chunk.begin() + got);
        }
    }

    template <typename Want>
    [[nodiscard]] Got await_game() {
        for (;;) {
            Got got;
            const std::optional<Bytes> frame = next_frame();
            if (!frame) return got;
            const protocol::FrameResult peeked = protocol::peek_frame(*frame, protocol::kMaxBodyBytes);
            if (!peeked || !peeked->has_value()) return got;
            const secure::ByteView body = std::span<const std::byte>{*frame}.subspan(protocol::kHeaderBytes);
            protocol::GameServerResult decoded = protocol::decode_game_server(**peeked, body);
            if (!decoded) return got;
            if (std::holds_alternative<Want>(*decoded)) {
                got.kind = Got::Kind::kWant;
                got.game = std::move(*decoded);
                return got;
            }
            if (const auto* reject = std::get_if<protocol::Reject>(&*decoded)) {
                got.kind = Got::Kind::kReject;
                got.code = reject->code;
                return got;
            }
            if (std::holds_alternative<protocol::Goodbye>(*decoded)) {
                got.kind = Got::Kind::kGoodbye;
                return got;
            }
        }
    }

    template <typename Want>
    [[nodiscard]] Got await_auth() {
        for (;;) {
            Got got;
            const std::optional<Bytes> frame = next_frame();
            if (!frame) return got;
            const protocol::FrameResult peeked = protocol::peek_frame(*frame, protocol::kMaxBodyBytes);
            if (!peeked || !peeked->has_value()) return got;
            const secure::ByteView body = std::span<const std::byte>{*frame}.subspan(protocol::kHeaderBytes);
            protocol::AuthServerResult decoded = protocol::decode_auth_server(**peeked, body);
            if (!decoded) return got;
            if (std::holds_alternative<Want>(*decoded)) {
                got.kind = Got::Kind::kWant;
                got.auth = std::move(*decoded);
                return got;
            }
            if (const auto* reject = std::get_if<protocol::Reject>(&*decoded)) {
                got.kind = Got::Kind::kReject;
                got.code = reject->code;
                return got;
            }
            if (std::holds_alternative<protocol::Goodbye>(*decoded)) {
                got.kind = Got::Kind::kGoodbye;
                return got;
            }
        }
    }

    [[nodiscard]] bool greet_game() {
        protocol::Hello hello;
        hello.version = protocol::kVersion;
        return send(hello) && await_game<protocol::Welcome>().kind == Got::Kind::kWant;
    }

    [[nodiscard]] bool greet_auth() {
        protocol::Hello hello;
        hello.version = protocol::kVersion;
        return send(hello) && await_auth<protocol::Welcome>().kind == Got::Kind::kWant;
    }

    void abort() {
        hard_close(socket_);
        socket_ = INVALID_SOCKET;
    }

    void close() {
        if (socket_ != INVALID_SOCKET) closesocket(socket_);
        socket_ = INVALID_SOCKET;
    }

    [[nodiscard]] SOCKET raw() const noexcept { return socket_; }

private:
    [[nodiscard]] bool recv_exact(std::span<std::byte> out) {
        std::size_t got = 0;
        while (got < out.size()) {
            const int read = recv(socket_, reinterpret_cast<char*>(out.data() + got), static_cast<int>(out.size() - got), 0);
            if (read <= 0) return false;
            got += static_cast<std::size_t>(read);
        }
        return true;
    }

    SOCKET socket_ = INVALID_SOCKET;
    std::optional<secure::RecordPipe> pipe_;
    Bytes held_;
};

[[nodiscard]] std::string ticket_text(const protocol::Ticket& ticket) {
    std::string text;
    for (const std::byte value : ticket.token) {
        if (value == std::byte{0}) break;
        text.push_back(static_cast<char>(value));
    }
    return text;
}

std::string g_run_tag;

[[nodiscard]] std::string account_name(std::string_view kind, int index) {
    return std::format("atk{}{}{}", g_run_tag, kind, index);
}

struct Player {
    std::string name;
    std::string ticket;
    std::uint64_t character = 0;
    std::array<std::byte, protocol::kSessionStartTokenBytes> token{};
};

Samples s_create, s_signin, s_login, s_char, s_enter, s_resume;

[[nodiscard]] std::optional<std::string> take_ticket(std::uint32_t source, bool create, std::string_view name,
    std::string_view password, Samples* timing, protocol::ErrorCode* code = nullptr) {
    Link link;
    if (!link.open(source, kAuthPort) || !link.greet_auth()) return std::nullopt;
    const Clock::time_point start = Clock::now();
    bool sent = false;
    if (create) {
        protocol::CreateAccount request;
        request.account = std::string{name};
        request.password = std::string{password};
        sent = link.send(request);
    } else {
        protocol::SignIn request;
        request.account = std::string{name};
        request.password = std::string{password};
        sent = link.send(request);
    }
    if (!sent) return std::nullopt;
    const Got got = link.await_auth<protocol::Ticket>();
    if (timing != nullptr) timing->add(ms_since(start));
    if (code != nullptr) *code = got.code;
    if (got.kind != Got::Kind::kWant) return std::nullopt;
    return ticket_text(std::get<protocol::Ticket>(got.auth));
}

[[nodiscard]] Got login(Link& link, std::string_view name, std::string_view ticket) {
    protocol::Login request;
    request.account = std::string{name};
    request.ticket = std::string{ticket};
    if (!link.send(request)) return {};
    return link.await_game<protocol::CharacterList>();
}

[[nodiscard]] Got enter_game(Link& link, std::uint64_t character) {
    protocol::EnterGame request;
    request.character = character;
    if (!link.send(request)) return {};
    return link.await_game<protocol::SessionStart>();
}

[[nodiscard]] Got resume(Link& link, const std::array<std::byte, protocol::kSessionStartTokenBytes>& token) {
    protocol::Resume request;
    request.token = token;
    if (!link.send(request)) return {};
    return link.await_game<protocol::SessionStart>();
}

[[nodiscard]] std::uint32_t worker_source(int index) {
    return source_of(1000 + index);
}

// Một người chơi đủ đường: tạo, đăng nhập, tạo nhân vật, vào, rớt, nối lại, các lần dùng lại.
void play_one(int index) {
    const std::uint32_t source = worker_source(index % 200);
    Player player;
    player.name = account_name("p", index);
    const std::string password = "matkhau-dai-" + std::to_string(index);
    protocol::ErrorCode code{};
    const std::optional<std::string> ticket = take_ticket(source, true, player.name, password, &s_create, &code);
    if (!ticket) {
        fault(std::format("tạo tài khoản {} hỏng code={}", player.name, static_cast<int>(code)));
        return;
    }
    Link game;
    if (!game.open(source, kGamePort) || !game.greet_game()) {
        fault("gate không chào");
        return;
    }
    Clock::time_point start = Clock::now();
    Got listed = login(game, player.name, *ticket);
    s_login.add(ms_since(start));
    if (listed.kind != Got::Kind::kWant) {
        fault(std::format("login hỏng code={}", static_cast<int>(listed.code)));
        return;
    }
    protocol::CreateCharacter made;
    made.name = std::format("Tk{}{}", g_run_tag, index);
    made.gender = protocol::Gender::kFemale;
    made.face = 1;
    made.hair = 1;
    made.portrait = 49;
    start = Clock::now();
    if (!game.send(made)) return;
    Got created = game.await_game<protocol::CharacterList>();
    s_char.add(ms_since(start));
    const auto* roster = std::get_if<protocol::CharacterList>(&created.game);
    if (created.kind != Got::Kind::kWant || roster == nullptr || roster->characters.empty()) {
        fault(std::format("tạo nhân vật hỏng code={}", static_cast<int>(created.code)));
        return;
    }
    player.character = roster->characters.back().id;
    start = Clock::now();
    Got entered = enter_game(game, player.character);
    s_enter.add(ms_since(start));
    if (entered.kind != Got::Kind::kWant) {
        fault(std::format("vào game hỏng code={}", static_cast<int>(entered.code)));
        return;
    }
    player.token = std::get<protocol::SessionStart>(entered.game).token;

    // Vé đã đổi một lần: dùng lại phải bị từ chối.
    {
        Link replay;
        if (replay.open(source, kGamePort) && replay.greet_game()) {
            const Got again = login(replay, player.name, *ticket);
            if (again.kind == Got::Kind::kWant) fault("vé dùng lại vẫn đăng nhập được");
        }
    }
    // Rớt mạng (RST), rồi nối lại bằng token.
    game.abort();
    Link back;
    if (!back.open(source, kGamePort) || !back.greet_game()) {
        fault("không nối lại được gate");
        return;
    }
    // Gate cần một lượt tick để thấy RST; Resume tới trước đó vẫn hợp lệ: phiên cũ bị đẩy ra.
    start = Clock::now();
    Got resumed = resume(back, player.token);
    s_resume.add(ms_since(start));
    if (resumed.kind != Got::Kind::kWant) {
        fault(std::format("Resume hỏng code={}", static_cast<int>(resumed.code)));
        return;
    }
    const auto fresh = std::get<protocol::SessionStart>(resumed.game).token;
    if (fresh == player.token) fault("Resume không đổi token");
    {
        Link stale;
        if (stale.open(source, kGamePort) && stale.greet_game()) {
            const Got again = resume(stale, player.token);
            if (again.kind == Got::Kind::kWant) fault("token cũ Resume lần hai vẫn được");
            if (again.kind == Got::Kind::kReject && again.code != protocol::ErrorCode::kNoSession) {
                fault(std::format("token cũ trả mã {}", static_cast<int>(again.code)));
            }
        }
    }
    // Logout xoá phiên: token mới cũng hết dùng.
    if (!back.send(protocol::Logout{})) return;
    static_cast<void>(back.await_game<protocol::Pong>());
    back.close();
    Link after;
    if (after.open(source, kGamePort) && after.greet_game()) {
        const Got again = resume(after, fresh);
        if (again.kind == Got::Kind::kWant) fault("Resume sau Logout vẫn được");
    }
}

void run_threads(int threads, int total, void (*body)(int)) {
    std::atomic<int> next{0};
    std::vector<std::jthread> pool;
    for (int worker = 0; worker < threads; ++worker) {
        pool.emplace_back([&] {
            for (int index = next.fetch_add(1); index < total; index = next.fetch_add(1)) body(index);
        });
    }
}

void scenario_flow(int users, int threads) {
    const Phase phase{std::format("flow users={} threads={}", users, threads)};
    const Clock::time_point start = Clock::now();
    run_threads(threads, users, &play_one);
    const double seconds = ms_since(start) / 1000.0;
    report("tao_tai_khoan", s_create);
    report("login", s_login);
    report("tao_nhan_vat", s_char);
    report("vao_game", s_enter);
    report("resume", s_resume);
    std::println("kq flow nguoi_choi_moi_giay={:.2f}", static_cast<double>(users) / seconds);
}

// Ban sau khi đăng nhập: cap còn hạn 8 giờ nhưng store phải từ chối sau tối đa kStandingTtl.
void scenario_ban() {
    const Phase phase{"ban"};
    const std::uint32_t source = worker_source(201);
    const std::string name = account_name("ban", 0);
    const std::optional<std::string> ticket = take_ticket(source, true, name, "matkhau-cam-dai", nullptr);
    if (!ticket) {
        fault("ban: không tạo được tài khoản");
        return;
    }
    Link game;
    if (!game.open(source, kGamePort) || !game.greet_game() || login(game, name, *ticket).kind != Got::Kind::kWant) {
        fault("ban: không đăng nhập được");
        return;
    }
    const std::string command = std::format("python -B Test\\bench\\ban_account.py {}", name);
    if (std::system(command.c_str()) != 0) {
        fault("ban: không ghi được ban");
        return;
    }
    const Clock::time_point banned = Clock::now();
    int round = 0;
    for (;;) {
        protocol::CreateCharacter made;
        made.name = std::format("Bn{}{}", g_run_tag, round);
        made.gender = protocol::Gender::kMale;
        made.face = 1;
        made.hair = 1;
        if (!game.send(made)) {
            fault("ban: gate đóng kết nối");
            return;
        }
        const Got got = game.await_game<protocol::CharacterList>();
        if (got.kind == Got::Kind::kReject && got.code == protocol::ErrorCode::kBadCredentials) {
            std::println("kq ban bi_chan_sau_ms={:.0f} lan_thu={}", ms_since(banned), round + 1);
            break;
        }
        if (ms_since(banned) > 8000) {
            fault("ban: sau 8 giây vẫn thao tác được");
            return;
        }
        ++round;
        std::this_thread::sleep_for(std::chrono::milliseconds{500});
    }
    // Đăng nhập lại bằng mật khẩu cũng phải bị chặn.
    protocol::ErrorCode code{};
    if (take_ticket(source, false, name, "matkhau-cam-dai", nullptr, &code)) fault("ban: vẫn lấy được vé mới");
}

void spam_one(int index) {
    const std::uint32_t source = worker_source(300 + (index % 50));
    protocol::ErrorCode code{};
    static_cast<void>(take_ticket(source, false, account_name("spam", 0), "sai-mat-khau-" + std::to_string(index),
        &s_signin, &code));
}

void scenario_signin_spam(int tries, int threads) {
    const Phase phase{std::format("signin_spam tries={} threads={}", tries, threads)};
    static_cast<void>(take_ticket(worker_source(299), true, account_name("spam", 0), "matkhau-dung-dai", nullptr));
    std::atomic<bool> stop{false};
    Samples legit;
    std::jthread probe([&] {
        int index = 0;
        while (!stop.load()) {
            const std::string name = account_name("legit", index);
            const Clock::time_point start = Clock::now();
            if (!take_ticket(worker_source(400 + index), true, name, "matkhau-hop-le", nullptr)) {
                // Busy dưới tải là đúng thiết kế; chỉ đếm.
            }
            legit.add(ms_since(start));
            ++index;
            std::this_thread::sleep_for(std::chrono::milliseconds{200});
        }
    });
    run_threads(threads, tries, &spam_one);
    stop.store(true);
    probe.join();
    report("signin_sai", s_signin);
    report("tao_tai_khoan_hop_le_duoi_spam", legit);
    protocol::ErrorCode code{};
    const bool still = take_ticket(worker_source(298), false, account_name("spam", 0), "matkhau-dung-dai", nullptr, &code)
                           .has_value();
    std::println("kq signin_spam dung_mat_khau_sau_spam={} code={}", still, static_cast<int>(code));
}

// Nhiều kết nối giữ cùng lúc, mỗi kết nối Ping mỗi giây; đo RTT Pong và số kết nối gate nhận.
struct Held {
    SOCKET socket = INVALID_SOCKET;
    std::optional<secure::ClientHandshake> client;
    std::optional<secure::RecordPipe> pipe;
    Bytes in;
    int stage = 0;  // 0 nối, 1 chờ lời đáp, 2 chờ Welcome, 3 sống, 9 chết
    Clock::time_point sent_at;
    bool waiting = false;
    Clock::time_point next_ping;
};

void seal_send(Held& held, const auto& message) {
    Bytes plain;
    if (!protocol::encode(plain, message)) return;
    std::array<std::byte, secure::kMaxRecordBytes> out{};
    const secure::SealResult sealed = held.pipe->seal(plain, out);
    if (!sealed || !send_all(held.socket, std::span<const std::byte>{out}.first(*sealed))) held.stage = 9;
}

void scenario_hold(int count, int hold_s, int per_ip) {
    const Phase phase{std::format("hold conns={} per_ip={} seconds={}", count, per_ip, hold_s)};
    std::vector<Held> all(static_cast<std::size_t>(count));
    const Clock::time_point began = Clock::now();
    for (int index = 0; index < count; ++index) {
        all[static_cast<std::size_t>(index)].socket = open_socket(source_of(index / per_ip), kGamePort, false);
    }
    Samples rtt;
    std::vector<WSAPOLLFD> fds(all.size());
    const Clock::time_point end = Clock::now() + std::chrono::seconds{hold_s};
    double ready_ms = -1;
    while (Clock::now() < end) {
        std::size_t live = 0;
        for (std::size_t at = 0; at < all.size(); ++at) {
            Held& held = all[at];
            fds[at].fd = held.stage == 9 ? INVALID_SOCKET : held.socket;
            fds[at].events = static_cast<SHORT>(held.stage == 0 ? POLLWRNORM : POLLRDNORM);
            fds[at].revents = 0;
            if (held.stage == 3) ++live;
        }
        if (ready_ms < 0 && live > 0 && live + 0 == all.size()) ready_ms = ms_since(began);
        WSAPoll(fds.data(), static_cast<ULONG>(fds.size()), 50);
        const Clock::time_point now = Clock::now();
        for (std::size_t at = 0; at < all.size(); ++at) {
            Held& held = all[at];
            if (held.stage == 9 || held.socket == INVALID_SOCKET) continue;
            const SHORT revents = fds[at].revents;
            if ((revents & (POLLERR | POLLHUP | POLLNVAL)) != 0 && held.stage == 0) {
                held.stage = 9;
                continue;
            }
            if (held.stage == 0 && (revents & POLLWRNORM) != 0) {
                secure::Result<secure::ClientHandshake> client = secure::ClientHandshake::begin();
                if (!client || !send_all(held.socket, client->hello())) {
                    held.stage = 9;
                    continue;
                }
                held.client.emplace(std::move(*client));
                held.stage = 1;
                continue;
            }
            if ((revents & (POLLRDNORM | POLLHUP | POLLERR)) != 0) {
                std::array<std::byte, 4096> chunk{};
                const int got = recv(held.socket, reinterpret_cast<char*>(chunk.data()), static_cast<int>(chunk.size()), 0);
                if (got <= 0) {
                    held.stage = 9;
                    continue;
                }
                held.in.insert(held.in.end(), chunk.begin(), chunk.begin() + got);
            }
            if (held.stage == 1 && held.in.size() >= secure::kServerHelloBytes) {
                secure::Result<secure::SessionKeys> keys =
                    held.client->finish(std::span<const std::byte>{held.in}.first(secure::kServerHelloBytes), g_pub);
                held.in.erase(held.in.begin(), held.in.begin() + secure::kServerHelloBytes);
                if (!keys) {
                    held.stage = 9;
                    continue;
                }
                held.pipe.emplace(std::move(*keys));
                protocol::Hello hello;
                hello.version = protocol::kVersion;
                seal_send(held, hello);
                if (held.stage != 9) held.stage = 2;
            }
            while ((held.stage == 2 || held.stage == 3) && !held.in.empty()) {
                std::array<std::byte, secure::kMaxPlainBytes> plain{};
                const secure::OpenResult opened = held.pipe->open_bytes(held.in, plain);
                if (!opened) {
                    held.stage = 9;
                    break;
                }
                held.in.erase(held.in.begin(), held.in.begin() + static_cast<std::ptrdiff_t>(opened->consumed));
                if (opened->written == 0) break;
                const std::uint16_t kind = static_cast<std::uint16_t>(static_cast<unsigned>(plain[4]) |
                                                                      (static_cast<unsigned>(plain[5]) << 8U));
                if (kind == protocol::Welcome::kKind && held.stage == 2) {
                    held.stage = 3;
                    held.next_ping = now;
                }
                if (kind == protocol::Pong::kKind && held.waiting) {
                    rtt.add(ms_since(held.sent_at));
                    held.waiting = false;
                }
            }
            if (held.stage == 3 && !held.waiting && now >= held.next_ping) {
                protocol::Ping ping;
                seal_send(held, ping);
                held.sent_at = now;
                held.waiting = true;
                held.next_ping = now + std::chrono::seconds{1};
            }
        }
    }
    int live = 0;
    int dead = 0;
    for (Held& held : all) {
        if (held.stage == 3) ++live;
        if (held.stage == 9) ++dead;
        hard_close(held.socket);
    }
    std::println("kq hold song={} bi_tu_choi_hoac_dong={} khac={} tat_ca_san_sang_ms={:.0f}", live, dead,
        count - live - dead, ready_ms);
    report("ping_rtt", rtt);
}

// Slowloris: mỗi giây một byte lời chào. Gate phải cắt ở handshake_timeout (5 s), và khách thật
// vẫn được phục vụ trong lúc đó.
void scenario_slowloris(int count, bool trickle = true) {
    const Phase phase{std::format("slowloris conns={} trickle={}", count, trickle)};
    std::vector<SOCKET> slow;
    const Clock::time_point opened_at = Clock::now();
    for (int index = 0; index < count; ++index) slow.push_back(open_socket(source_of(3000 + index / 8), kGamePort, false));
    {
        // Thời điểm từng kết nối nối xong (SYN/ACK), đo trước khi gửi gì.
        Samples connected;
        std::vector<bool> done(slow.size(), false);
        std::size_t left = slow.size();
        while (left > 0 && ms_since(opened_at) < 10000) {
            std::vector<WSAPOLLFD> fds;
            std::vector<std::size_t> which;
            for (std::size_t at = 0; at < slow.size(); ++at) {
                if (done[at]) continue;
                fds.push_back(WSAPOLLFD{.fd = slow[at], .events = POLLWRNORM, .revents = 0});
                which.push_back(at);
            }
            WSAPoll(fds.data(), static_cast<ULONG>(fds.size()), 20);
            for (std::size_t at = 0; at < fds.size(); ++at) {
                if (fds[at].revents == 0) continue;
                done[which[at]] = true;
                --left;
                connected.add(ms_since(opened_at));
            }
        }
        std::println("kq slowloris chua_noi_xong_sau_10s={}", left);
        report("slowloris_noi_xong", connected);
    }
    const Clock::time_point start = Clock::now();
    std::vector<double> cut_ms(slow.size(), -1);
    std::atomic<bool> stop{false};
    // Luồng chậm: mỗi giây một byte cho mỗi kết nối, hỏi đóng mỗi 50 ms.
    std::jthread feeder([&] {
        const std::array<std::byte, 1> one{std::byte{'T'}};
        Clock::time_point next_byte = Clock::now();
        while (!stop.load()) {
            const bool feed = trickle && Clock::now() >= next_byte;
            if (feed) next_byte += std::chrono::seconds{1};
            for (std::size_t at = 0; at < slow.size(); ++at) {
                if (cut_ms[at] >= 0) continue;
                if (feed) {
                    const int wrote = send(slow[at], reinterpret_cast<const char*>(one.data()), 1, 0);
                    if (wrote < 0 && WSAGetLastError() != WSAEWOULDBLOCK && WSAGetLastError() != WSAENOTCONN) {
                        cut_ms[at] = ms_since(start);
                        continue;
                    }
                }
                char probe = 0;
                const int got = recv(slow[at], &probe, 1, 0);
                const int error = WSAGetLastError();
                if (got == 0 || (got < 0 && error != WSAEWOULDBLOCK && error != WSAENOTCONN)) cut_ms[at] = ms_since(start);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds{50});
        }
    });
    Samples legit;
    Samples legit_open;
    while (ms_since(start) < 9000) {
        const Clock::time_point once = Clock::now();
        Link link;
        const bool opened = link.open(worker_source(500), kGamePort);
        legit_open.add(ms_since(once));
        if (opened && link.greet_game()) {
            legit.add(ms_since(once));
        } else {
            fault("slowloris: khách thật không bắt tay được");
        }
        link.close();
        std::this_thread::sleep_for(std::chrono::milliseconds{250});
    }
    stop.store(true);
    feeder.join();
    int cut = 0;
    Samples cuts;
    for (const double value : cut_ms) {
        if (value >= 0) {
            ++cut;
            cuts.add(value);
        }
    }
    for (const SOCKET socket : slow) hard_close(socket);
    std::println("kq slowloris bi_cat={}/{}", cut, count);
    report("slowloris_thoi_diem_cat", cuts);
    report("khach_that_bat_tay", legit_open);
    report("khach_that_bat_tay_va_chao", legit);
    if (cut < count) fault("slowloris: còn kết nối chậm sống sau 9 giây");
}

// Khung sai: mỗi loại phải bị gate đóng, và gate vẫn sống.
void scenario_garbage(int rounds) {
    const Phase phase{std::format("garbage rounds={}", rounds)};
    std::mt19937_64 random{12345};
    std::array<int, 6> closed{};
    for (int round = 0; round < rounds; ++round) {
        const std::uint32_t source = source_of(4000 + round % 200);
        {
            SOCKET socket = open_socket(source, kGamePort, true);
            std::array<std::byte, secure::kClientHelloBytes> hello{};
            for (std::byte& value : hello) value = static_cast<std::byte>(random());
            if (send_all(socket, hello) && closed_within(socket, 3000)) ++closed[0];
            hard_close(socket);
        }
        {
            Link link;
            if (link.open(source, kGamePort)) {
                const std::array<std::byte, 2> header{std::byte{0xFF}, std::byte{0xFF}};
                if (link.send_raw(header) && closed_within(link.raw(), 3000)) ++closed[1];
            }
        }
        {
            Link link;
            if (link.open(source, kGamePort)) {
                std::array<std::byte, 64> forged{};
                forged[0] = std::byte{62};
                for (std::size_t at = 2; at < forged.size(); ++at) forged[at] = static_cast<std::byte>(random());
                if (link.send_raw(forged) && closed_within(link.raw(), 3000)) ++closed[2];
            }
        }
        {
            Link link;
            if (link.open(source, kGamePort) && link.greet_game()) {
                // Khung khai thân 60000 byte, lớn hơn trần 4096 của client.
                // Đầu khung: 4 byte độ dài thân, 2 byte loại, 2 byte cờ.
                Bytes plain(16);
                plain[0] = std::byte{0x60};
                plain[1] = std::byte{0xEA};
                plain[4] = std::byte{0x02};
                plain[5] = std::byte{0x01};
                if (link.send_plain(plain) && closed_within(link.raw(), 3000)) ++closed[3];
            }
        }
        {
            Link link;
            if (link.open(source, kGamePort) && link.greet_game()) {
                const std::array<std::byte, 8> foreign{std::byte{0}, std::byte{0}, std::byte{0}, std::byte{0},
                    std::byte{0x34}, std::byte{0x12}};
                if (link.send_plain(foreign) && closed_within(link.raw(), 3000)) ++closed[4];
            }
        }
        {
            Link link;
            if (link.open(source, kAuthPort) && link.greet_auth()) {
                // Tin của cửa game gửi vào cửa auth.
                protocol::EnterGame wrong;
                if (link.send(wrong) && closed_within(link.raw(), 3000)) ++closed[5];
            }
        }
    }
    std::println("kq garbage hello_rac={} do_dai_ffff={} ban_ghi_gia={} than_qua_tran={} loai_la={} sai_cua={} / {}",
        closed[0], closed[1], closed[2], closed[3], closed[4], closed[5], rounds);
    for (const int value : closed) {
        if (value != rounds) fault("garbage: có kết nối sai không bị đóng trong 3 giây");
    }
}

// Kết nối thẳng vào cổng ipc của auth và store: im lặng, rác, khung mã hoá giả. Trong lúc đó
// khách thật vẫn đăng nhập được: luồng nhận của serve_loop không chờ trên kết nối nào.
void scenario_ipc(int idle) {
    const Phase phase{std::format("ipc idle={}", idle)};
    std::vector<SOCKET> quiet;
    std::mt19937_64 random{777};
    for (int index = 0; index < idle; ++index) {
        const std::uint16_t port = index % 2 == 0 ? kAuthIpc : kStoreIpc;
        SOCKET socket = open_socket(source_of(5000 + index), port, true);
        if (socket == INVALID_SOCKET) continue;
        if (index % 3 == 1) {
            std::array<std::byte, 2> part{std::byte{0x40}, std::byte{0}};
            static_cast<void>(send_all(socket, part));
        }
        if (index % 3 == 2) {
            std::array<std::byte, 64> forged{};
            forged[0] = std::byte{60};
            for (std::size_t at = 4; at < forged.size(); ++at) forged[at] = static_cast<std::byte>(random());
            static_cast<void>(send_all(socket, forged));
        }
        quiet.push_back(socket);
    }
    Samples legit;
    for (int round = 0; round < 10; ++round) {
        const Clock::time_point start = Clock::now();
        const std::string name = account_name("ipc", round);
        const std::optional<std::string> ticket = take_ticket(worker_source(600 + round), true, name, "matkhau-ipc-dai", nullptr);
        Link game;
        const bool ok = ticket && game.open(worker_source(600 + round), kGamePort) && game.greet_game() &&
                        login(game, name, *ticket).kind == Got::Kind::kWant;
        if (!ok) fault("ipc: khách thật không đăng nhập được khi cổng ipc bị lấp");
        legit.add(ms_since(start));
    }
    int cut = 0;
    for (const SOCKET socket : quiet) {
        if (closed_within(socket, 4000)) ++cut;
        hard_close(socket);
    }
    std::println("kq ipc bi_dong_trong_4s={}/{}", cut, quiet.size());
    report("dang_ky_va_login_khi_ipc_bi_lap", legit);
}

// Một IP mở 20 kết nối: gate chỉ giữ per_ip_connections (8 trong gate.toml).
void scenario_per_ip() {
    const Phase phase{"per_ip"};
    std::vector<std::unique_ptr<Link>> links;
    int ok = 0;
    for (int index = 0; index < 20; ++index) {
        auto link = std::make_unique<Link>();
        if (link->open(source_of(6000), kGamePort) && link->greet_game()) ++ok;
        links.push_back(std::move(link));
    }
    std::println("kq per_ip mot_ip_20_ket_noi_duoc_chao={}", ok);
    if (ok > 8) fault("per_ip: vượt trần mỗi IP");
}


// === DATA/AUTH/ITEM red-team: giả mạo vé/cap, leo quyền store, tên, ban window ===
[[nodiscard]] protocol::ErrorCode reject_code(const Got& got) {
    return got.kind == Got::Kind::kReject ? got.code : protocol::ErrorCode::kMalformed;
}

struct Session {
    std::string account;
    std::string password;
    std::string ticket;
    std::uint64_t character = 0;
    std::array<std::byte, protocol::kSessionStartTokenBytes> token{};
    std::unique_ptr<Link> game;
};

[[nodiscard]] std::optional<Session> open_session(int index, std::string_view kind, bool make_char) {
    Session session;
    session.account = account_name(kind, index);
    session.password = "matkhau-data-" + std::to_string(index);
    const std::uint32_t source = worker_source(700 + index);
    protocol::ErrorCode code{};
    const std::optional<std::string> ticket = take_ticket(source, true, session.account, session.password, nullptr, &code);
    if (!ticket) {
        // Có thể đã tồn tại từ lần chạy trước: SignIn.
        const std::optional<std::string> again = take_ticket(source, false, session.account, session.password, nullptr, &code);
        if (!again) return std::nullopt;
        session.ticket = *again;
    } else {
        session.ticket = *ticket;
    }
    session.game = std::make_unique<Link>();
    if (!session.game->open(source, kGamePort) || !session.game->greet_game()) return std::nullopt;
    const Got listed = login(*session.game, session.account, session.ticket);
    if (listed.kind != Got::Kind::kWant) return std::nullopt;
    if (!make_char) return session;
    auto* roster = std::get_if<protocol::CharacterList>(&listed.game);
    if (roster != nullptr && !roster->characters.empty()) {
        session.character = roster->characters.back().id;
        return session;
    }
    protocol::CreateCharacter made;
    made.name = std::format("Dv{}{}", g_run_tag, index);
    made.gender = protocol::Gender::kMale;
    made.face = 1;
    made.hair = 1;
    if (!session.game->send(made)) return std::nullopt;
    const Got created = session.game->await_game<protocol::CharacterList>();
    roster = std::get_if<protocol::CharacterList>(&created.game);
    if (created.kind != Got::Kind::kWant || roster == nullptr || roster->characters.empty()) return std::nullopt;
    session.character = roster->characters.back().id;
    return session;
}

void scenario_data() {
    const Phase phase{"data_auth_item"};
    const std::uint32_t source = worker_source(750);

    // 1) Oracle tạo tài khoản: tên đã có → kDuplicate (28), tên mới → Ticket.
    {
        const std::string name = account_name("orac", 0);
        protocol::ErrorCode code{};
        static_cast<void>(take_ticket(source, true, name, "matkhau-oracle-1", nullptr, &code));
        protocol::ErrorCode again{};
        const bool dup = !take_ticket(source, true, name, "matkhau-oracle-2", nullptr, &again).has_value();
        std::println("kq enum_oracle first_create_code={} second_code={} duplicate_signal={}", static_cast<int>(code),
            static_cast<int>(again), again == protocol::ErrorCode::kDuplicate);
        if (dup && again == protocol::ErrorCode::kDuplicate) {
            fault("enum_oracle: CreateAccount lộ kDuplicate — dò được danh sách tài khoản");
        }
    }

    // 2) Login sai tên + đúng vé.
    {
        std::optional<Session> victim = open_session(1, "wn", false);
        if (!victim) {
            fault("wrong_name: không mở được phiên");
        } else {
            Link other;
            if (other.open(worker_source(751), kGamePort) && other.greet_game()) {
                // Vé đã redeem ở open_session — cần vé mới.
            }
        }
        // Tạo mới, lấy vé, chưa redeem: login bằng tên khác.
        const std::string real_name = account_name("wn2", 2);
        const std::string password = "matkhau-wrongname";
        const std::optional<std::string> ticket = take_ticket(worker_source(752), true, real_name, password, nullptr);
        if (!ticket) {
            fault("wrong_name: không lấy được vé");
        } else {
            Link game;
            if (!game.open(worker_source(752), kGamePort) || !game.greet_game()) {
                fault("wrong_name: gate");
            } else {
                const Got got = login(game, account_name("wnX", 2), *ticket);
                if (got.kind == Got::Kind::kWant) fault("wrong_name: vé đúng + tên sai vẫn login");
                std::println("kq wrong_name kind={} code={}", static_cast<int>(got.kind), static_cast<int>(got.code));
            }
        }
    }

    // 3) Race redeem: hai Login cùng lúc với một vé.
    {
        const std::string name = account_name("race", 3);
        const std::optional<std::string> ticket = take_ticket(worker_source(753), true, name, "matkhau-race-dai", nullptr);
        if (!ticket) {
            fault("ticket_race: không có vé");
        } else {
            std::atomic<int> wins{0};
            std::atomic<int> loses{0};
            auto body = [&](int /*id*/) {
                Link game;
                if (!game.open(worker_source(754), kGamePort) || !game.greet_game()) return;
                const Got got = login(game, name, *ticket);
                if (got.kind == Got::Kind::kWant) wins.fetch_add(1);
                else loses.fetch_add(1);
            };
            std::vector<std::jthread> pool;
            for (int i = 0; i < 8; ++i) pool.emplace_back(body, i);
            pool.clear();
            std::println("kq ticket_race wins={} loses={}", wins.load(), loses.load());
            if (wins.load() > 1) fault("ticket_race: cùng một vé redeem thành công nhiều lần");
        }
    }

    // 4) Enter / Delete nhân vật người khác.
    {
        std::optional<Session> a = open_session(10, "own", true);
        std::optional<Session> b = open_session(11, "foe", true);
        if (!a || !b) {
            fault("foreign: không mở được hai phiên");
        } else {
            const Got entered_foreign = enter_game(*a->game, b->character);
            std::println("kq enter_foreign kind={} code={}", static_cast<int>(entered_foreign.kind), static_cast<int>(entered_foreign.code));
            if (entered_foreign.kind == Got::Kind::kWant) fault("enter_foreign: vào được nhân vật account khác");
            protocol::DeleteCharacter del;
            del.character = b->character;
            if (a->game->send(del)) {
                const Got gone = a->game->await_game<protocol::CharacterList>();
                std::println("kq delete_foreign kind={} code={}", static_cast<int>(gone.kind), static_cast<int>(gone.code));
                if (gone.kind == Got::Kind::kWant) {
                    // CharacterList ok có thể vẫn trả roster của mình — kiểm nhân vật B còn không.
                    Link check;
                    if (check.open(worker_source(760), kGamePort) && check.greet_game()) {
                        // B vẫn còn session; thử list lại bằng SignIn mới khó. Dùng enter của B.
                        const Got still = enter_game(*b->game, b->character);
                        if (still.kind != Got::Kind::kWant && still.code == protocol::ErrorCode::kNoSuchCharacter) {
                            fault("delete_foreign: A xoá được nhân vật của B");
                        }
                    }
                }
            }
        }
    }

    // 5) Unicode case: hai tên chỉ khác hoa/thường chữ có dấu.
    {
        std::optional<Session> a = open_session(20, "uc", false);
        if (!a) {
            fault("unicode_case: không mở phiên");
        } else {
            protocol::CreateCharacter one;
            one.name = "T\xC3\xA8o" + g_run_tag.substr(0, 2); // Tèo + tag
            // Keep short: TèoXtag
            one.name = std::string("T\xC3\xA8") + g_run_tag.substr(0, 3);
            one.gender = protocol::Gender::kFemale;
            one.face = 1;
            one.hair = 1;
            one.portrait = 49;
            protocol::CreateCharacter two = one;
            two.name = std::string("T\xC3\x88") + g_run_tag.substr(0, 3); // TÈ + tag
            bool first_ok = false;
            bool second_ok = false;
            if (a->game->send(one)) {
                const Got g1 = a->game->await_game<protocol::CharacterList>();
                first_ok = g1.kind == Got::Kind::kWant;
            }
            if (a->game->send(two)) {
                const Got g2 = a->game->await_game<protocol::CharacterList>();
                second_ok = g2.kind == Got::Kind::kWant;
                if (g2.kind == Got::Kind::kReject) {
                    std::println("kq unicode_case second_code={}", static_cast<int>(g2.code));
                }
            }
            std::println("kq unicode_case first_ok={} second_ok={}", first_ok, second_ok);
            if (first_ok && second_ok) fault("unicode_case: hai tên chỉ khác case Unicode cùng sống");
        }
    }

    // 6) Homoglyph Cyrillic а trong tên.
    {
        std::optional<Session> a = open_session(21, "hg", false);
        if (!a) {
            fault("homoglyph: không mở phiên");
        } else {
            protocol::CreateCharacter made;
            made.name = std::string("Adm\xD0\xB0") + g_run_tag.substr(0, 2); // Adm + Cyrillic а
            made.gender = protocol::Gender::kMale;
            made.face = 2;
            made.hair = 2;
            if (a->game->send(made)) {
                const Got got = a->game->await_game<protocol::CharacterList>();
                std::println("kq homoglyph kind={} code={}", static_cast<int>(got.kind), static_cast<int>(got.code));
                if (got.kind == Got::Kind::kWant) fault("homoglyph: tên chứa chữ Cyrillic được chấp nhận");
            }
        }
    }

    // 7) face/hair cực trị — tiêm dữ liệu ngoại lệ vào DB.
    {
        std::optional<Session> a = open_session(22, "fh", false);
        if (!a) {
            fault("face_hair: không mở phiên");
        } else {
            protocol::CreateCharacter made;
            made.name = std::format("Fh{}", g_run_tag);
            made.gender = protocol::Gender::kFemale;
            made.face = 65535;
            made.hair = 65535;
            if (a->game->send(made)) {
                const Got got = a->game->await_game<protocol::CharacterList>();
                std::println("kq face_hair_65535 kind={} code={}", static_cast<int>(got.kind), static_cast<int>(got.code));
                if (got.kind == Got::Kind::kWant) fault("face_hair: face/hair=65535 được ghi DB không kiểm content");
            }
        }
    }

    // 8) Resume hijack từ IP khác (token bearer).
    {
        std::optional<Session> a = open_session(30, "rs", true);
        if (!a) {
            fault("resume_hijack: không mở phiên");
        } else {
            const Got entered = enter_game(*a->game, a->character);
            if (entered.kind != Got::Kind::kWant) {
                fault("resume_hijack: enter thất bại");
            } else {
                a->token = std::get<protocol::SessionStart>(entered.game).token;
                a->game->abort();
                Link thief;
                const std::uint32_t other_ip = worker_source(799);
                if (!thief.open(other_ip, kGamePort) || !thief.greet_game()) {
                    fault("resume_hijack: thief không chào");
                } else {
                    const Got stolen = resume(thief, a->token);
                    std::println("kq resume_hijack kind={} code={}", static_cast<int>(stolen.kind),
                        static_cast<int>(stolen.code));
                    if (stolen.kind == Got::Kind::kWant) {
                        fault("resume_hijack: IP khác Resume bằng token đánh cắp — chiếm phiên");
                    }
                }
            }
        }
    }

    // 9) Soft-delete rồi chiếm tên từ account khác.
    {
        std::optional<Session> a = open_session(40, "sd", true);
        std::optional<Session> b = open_session(41, "sd", false);
        if (!a || !b || a->character == 0) {
            fault("soft_delete_steal: thiếu phiên");
        } else {
            // Lấy tên nhân vật A từ list — tạo tên cố định.
            protocol::DeleteCharacter del;
            del.character = a->character;
            std::string stolen_name = std::format("Sd{}", g_run_tag);
            // Tạo lại với tên biết trước trên A rồi xoá.
            {
                // A đã có char; xoá nó, tạo tên stolen_name, xoá lại, B tạo cùng tên.
                if (a->game->send(del)) static_cast<void>(a->game->await_game<protocol::CharacterList>());
                protocol::CreateCharacter made;
                made.name = stolen_name;
                made.gender = protocol::Gender::kMale;
                made.face = 1;
                made.hair = 1;
                if (a->game->send(made)) {
                    const Got created = a->game->await_game<protocol::CharacterList>();
                    auto* roster = std::get_if<protocol::CharacterList>(&created.game);
                    if (created.kind == Got::Kind::kWant && roster && !roster->characters.empty()) {
                        del.character = roster->characters.back().id;
                        if (a->game->send(del)) static_cast<void>(a->game->await_game<protocol::CharacterList>());
                        protocol::CreateCharacter take = made;
                        if (b->game->send(take)) {
                            const Got got = b->game->await_game<protocol::CharacterList>();
                            std::println("kq soft_delete_steal kind={} code={}", static_cast<int>(got.kind),
                                static_cast<int>(got.code));
                            if (got.kind == Got::Kind::kWant) {
                                fault("soft_delete_steal: account B chiếm tên NV đã xoá của A");
                            }
                        }
                    }
                }
            }
        }
    }

    // 10) Không có RPC client nào ghi bảng item — xác nhận Enter không trả inventory để client sửa.
    {
        std::optional<Session> a = open_session(50, "it", true);
        if (!a) {
            fault("item_surface: không mở phiên");
        } else {
            const Got entered = enter_game(*a->game, a->character);
            std::println("kq item_surface enter_kind={} (không có tin Item/Money client→server trong gate)",
                static_cast<int>(entered.kind));
        }
    }

    std::println("kq data_auth_item xong");
}


} // namespace

int main(int argc, char** argv) {
    std::string only;
    std::string pids;
    std::string pub;
    int users = 60;
    int hold = 2500;
    for (int at = 1; at + 1 < argc; at += 2) {
        const std::string_view key = argv[at];
        if (key == "--pub") pub = argv[at + 1];
        if (key == "--pids") pids = argv[at + 1];
        if (key == "--only") only = argv[at + 1];
        if (key == "--users") users = std::atoi(argv[at + 1]);
        if (key == "--hold") hold = std::atoi(argv[at + 1]);
    }
    if (pub.size() != secure::kPublicBytes * 2) {
        std::println(stderr, "cần --pub <64 hex>");
        return 2;
    }
    for (std::size_t at = 0; at < secure::kPublicBytes; ++at) {
        g_pub.bytes[at] = static_cast<std::byte>(std::stoi(pub.substr(at * 2, 2), nullptr, 16));
    }
    std::size_t from = 0;
    for (DWORD& pid : g_pids) {
        const std::size_t comma = std::min(pids.find(',', from), pids.size());
        pid = static_cast<DWORD>(std::strtoul(pids.substr(from, comma - from).c_str(), nullptr, 10));
        from = comma + 1;
        if (from > pids.size()) break;
    }
    WSADATA data{};
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return 1;
    g_run_tag = std::format("{:x}", static_cast<unsigned>(GetTickCount64() & 0xFFFFFU));
    const auto want = [&](std::string_view name) { return only.empty() || only == name; };
    if (want("flow")) scenario_flow(users, 16);
    if (want("ban")) scenario_ban();
    if (want("per_ip")) scenario_per_ip();
    if (want("garbage")) scenario_garbage(50);
    if (want("slowloris")) scenario_slowloris(400);
    if (want("slowloris40")) scenario_slowloris(40);
    if (want("idle400")) scenario_slowloris(400, false);
    if (want("ipc")) scenario_ipc(300);
    if (want("signin")) scenario_signin_spam(400, 16);
    if (want("hold")) scenario_hold(hold, 15, 8);
    if (want("data")) scenario_data();
    std::println("kq tong_sai={}", g_faults.load());
    WSACleanup();
    return g_faults.load() == 0 ? 0 : 1;
}