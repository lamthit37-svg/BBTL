#include "account/serve.hpp"

#include "account/cap.hpp"
#include "account/ipc_key.hpp"
#include "account/rpc.hpp"
#include "account/rules.hpp"
#include "account/sql.hpp"
#include "account/standing.hpp"
#include "config/auth.hpp"
#include "config/cluster.hpp"
#include "config/secrets.hpp"
#include "config/store.hpp"
#include "io/file.hpp"
#include "net/net.hpp"
#include "process/process.hpp"
#include "secure/secure.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <format>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <utility>

namespace game::account {
namespace {

using Path = std::filesystem::path;

void idle_until_stop() {
    std::println("ready");
    static_cast<void>(std::fflush(stdout));
    while (!process::stop_requested()) {
        std::this_thread::sleep_for(std::chrono::milliseconds{20});
    }
}

[[nodiscard]] bool file_ok(const Path& path) {
    const io::TextResult text = io::read_text(path);
    return text.has_value();
}

template <typename Value>
[[nodiscard]] std::optional<Value> read_cfg(const Path& path, config::ReadResult<Value> (*reader)(std::string_view),
    std::string& error, std::string_view label) {
    const io::TextResult text = io::read_text(path);
    if (!text) {
        error = std::format("không đọc được {}", label);
        return std::nullopt;
    }
    config::ReadResult<Value> value = reader(*text);
    if (!value) {
        error = std::format("{} không hợp lệ", label);
        return std::nullopt;
    }
    return std::move(*value);
}

[[nodiscard]] std::optional<config::ProcessBlock> find_process(const config::Cluster& cluster, config::ProcessKind kind) {
    for (const config::ProcessBlock& block : cluster.processes) {
        if (block.kind == kind && block.id.value() == 0) return block;
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<net::Endpoint> endpoint_of(const config::Ipv4Address& host, config::Port port) {
    const std::string text = std::format("{}:{}", host.text(), port.value());
    const net::ZeroPort zero = port.value() == 0 ? net::ZeroPort::kAllow : net::ZeroPort::kRefuse;
    const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(text, zero);
    if (!parsed) return std::nullopt;
    return *parsed;
}

[[nodiscard]] bool probe_password(AuthOptions& options, std::string& error) {
    if (options.ops_limit <= 0 || options.mem_limit_kib <= 0 || options.mem_limit_kib > 1024 * 1024) {
        error = "tham số Argon2id ngoài miền";
        return false;
    }
    const secure::PasswordPolicy policy{
        .ops = static_cast<unsigned long long>(options.ops_limit),
        .mem_bytes = static_cast<std::size_t>(options.mem_limit_kib) * 1024U,
    };
    std::string hash;
    if (!secure::hash_password("probe", policy, hash) || !secure::verify_password(hash, "probe")) {
        error = "Argon2id không chạy";
        return false;
    }
    options.dummy_hash = hash;
    secure::wipe_bytes(std::as_writable_bytes(std::span{hash.data(), hash.size()}));
    return true;
}

struct Listen {
    net::Network network;
    net::TcpListener listener;
    std::uint16_t port = 0;
};

[[nodiscard]] std::optional<Listen> open_listen(const net::Endpoint& endpoint, std::string& error) {
    net::NetResult<net::Network> network = net::Network::start();
    if (!network) {
        error = "không khởi động được mạng";
        return std::nullopt;
    }
    net::NetResult<net::TcpListener> listener = net::TcpListener::open(endpoint);
    if (!listener) {
        error = "không nghe được cổng ipc";
        return std::nullopt;
    }
    const net::NetResult<net::Endpoint> local = listener->local();
    if (!local || local->port == 0) {
        error = "không đọc được cổng ipc";
        return std::nullopt;
    }
    Listen opened{.network = std::move(*network), .listener = std::move(*listener), .port = local->port};
    return opened;
}

void wipe_secret(std::string& secret) {
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret.data(), secret.size()}));
    secret.clear();
}

struct AuthCtx {
    AuthDb* db = nullptr;
    const std::array<std::byte, kIpcKeyBytes>* key = nullptr;
};

struct GameCtx {
    GameDb* db = nullptr;
    const std::array<std::byte, kIpcKeyBytes>* key = nullptr;
    std::optional<net::Endpoint> auth;
    StandingCache standing;
};

// Hỏi auth chặn luồng database của store tối đa chừng này; quá hạn là Busy.
constexpr std::chrono::milliseconds kStandingWait{2000};

[[nodiscard]] std::uint64_t unix_now() {
    const auto now = std::chrono::system_clock::now().time_since_epoch();
    return static_cast<std::uint64_t>(std::chrono::duration_cast<std::chrono::seconds>(now).count());
}

struct OpenedCap {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kNotAuthenticated;
    std::uint64_t account = 0;
};

[[nodiscard]] OpenedCap open_account(const GameCtx& ctx, const std::array<std::byte, kCapBytes>& token) {
    Cap cap;
    const CapStatus status = open_cap(*ctx.key, token, unix_now(), cap);
    OpenedCap opened;
    if (status == CapStatus::kExpired) {
        opened.code = protocol::ErrorCode::kSessionExpired;
        return opened;
    }
    if (status != CapStatus::kOk) return opened;
    opened.ok = true;
    opened.account = cap.account;
    return opened;
}

[[nodiscard]] Standing ask_standing(const GameCtx& ctx, const std::array<std::byte, kCapBytes>& token) {
    Standing asked;
    if (!ctx.auth) return asked;
    const std::optional<Reply> reply = exchange(*ctx.auth, standing_call(token), kStandingWait, *ctx.key);
    if (!reply) return asked;
    const EnterResult result = enter_from(*reply);
    asked.ok = result.ok;
    asked.code = result.ok ? protocol::ErrorCode::kBusy : result.code;
    return asked;
}

// Cap đúng chữ ký chưa đủ: tài khoản có thể bị ban sau khi cap được cấp.
[[nodiscard]] OpenedCap open_standing(GameCtx& ctx, const std::array<std::byte, kCapBytes>& token) {
    OpenedCap who = open_account(ctx, token);
    if (!who.ok) return who;
    const StandingCache::Clock::time_point now = StandingCache::Clock::now();
    std::optional<Standing> known = ctx.standing.find(who.account, now);
    if (!known) {
        known = ask_standing(ctx, token);
        ctx.standing.put(who.account, *known, now);
    }
    if (known->ok) return who;
    OpenedCap denied;
    denied.code = known->code;
    return denied;
}

Reply on_auth(void* ctx, const Call& call) {
    auto* box = static_cast<AuthCtx*>(ctx);
    if (call.op == Op::kCreateAccount || call.op == Op::kSignIn) {
        std::string name;
        std::string password;
        std::string ip;
        if (!read_account_call(call, name, password, ip)) return reply_of(TicketResult{});
        const bool create = call.op == Op::kCreateAccount;
        TicketResult result = create ? box->db->create_account(name, password, ip) : box->db->sign_in(name, password, ip);
        wipe_secret(password);
        return reply_of(result);
    }
    if (call.op == Op::kRedeem) {
        std::string hex;
        if (!read_text_call(call, hex)) return reply_of(RedeemResult{});
        RedeemResult result = box->db->redeem(hex);
        if (!result.ok) return reply_of(result);
        const bool sealed = seal_cap(*box->key, result.account, unix_now() + kCapTtlSeconds, result.cap);
        if (!sealed) {
            result.ok = false;
            result.code = protocol::ErrorCode::kBusy;
        }
        return reply_of(result);
    }
    if (call.op == Op::kStanding) {
        std::array<std::byte, kCapBytes> token{};
        EnterResult result;
        result.code = protocol::ErrorCode::kNotAuthenticated;
        if (!read_list_call(call, token)) return reply_of(result);
        Cap cap;
        const CapStatus status = open_cap(*box->key, token, unix_now(), cap);
        if (status == CapStatus::kExpired) result.code = protocol::ErrorCode::kSessionExpired;
        if (status != CapStatus::kOk) return reply_of(result);
        return reply_of(box->db->standing(cap.account));
    }
    return reply_of(TicketResult{});
}

Reply on_game(void* ctx, const Call& call) {
    auto* box = static_cast<GameCtx*>(ctx);
    std::array<std::byte, kCapBytes> token{};
    if (call.op == Op::kList) {
        if (!read_list_call(call, token)) return reply_of(ListResult{});
        const OpenedCap who = open_standing(*box, token);
        if (!who.ok) return reply_of(ListResult{.code = who.code});
        return reply_of(box->db->list(who.account));
    }
    if (call.op == Op::kCreateCharacter) {
        std::string name;
        protocol::Gender gender = protocol::Gender::kFemale;
        std::uint16_t face = 0;
        std::uint16_t hair = 0;
        if (!read_character_call(call, token, name, gender, face, hair)) return reply_of(ListResult{});
        const OpenedCap who = open_standing(*box, token);
        if (!who.ok) return reply_of(ListResult{.code = who.code});
        return reply_of(box->db->create_character(who.account, name, gender, face, hair));
    }
    if (call.op == Op::kDeleteCharacter) {
        std::uint64_t character = 0;
        if (!read_id_call(call, token, character)) return reply_of(ListResult{});
        const OpenedCap who = open_standing(*box, token);
        if (!who.ok) return reply_of(ListResult{.code = who.code});
        return reply_of(box->db->remove_character(who.account, character));
    }
    if (call.op == Op::kEnter) {
        std::uint64_t character = 0;
        if (!read_id_call(call, token, character)) return enter_reply_of(EnterResult{});
        const OpenedCap who = open_standing(*box, token);
        if (!who.ok) {
            EnterResult denied;
            denied.code = who.code;
            return enter_reply_of(denied);
        }
        return enter_reply_of(box->db->enter(who.account, character));
    }
    return reply_of(ListResult{});
}

[[nodiscard]] store::PgLogin login_of(const config::Cluster& cluster, const config::DatabaseLogin& database,
    const std::string& password) {
    store::PgLogin login;
    login.host = std::string{cluster.postgres.host.text()};
    login.port = std::to_string(cluster.postgres.port.value());
    login.dbname = database.name;
    login.user = database.user;
    login.password = password;
    return login;
}

[[nodiscard]] bool loopback_address(const net::Endpoint& endpoint) noexcept {
    const net::Ipv4 loopback{127, 0, 0, 1};
    return endpoint.address == loopback;
}

} // namespace

int serve_auth(const Path& config_dir) {
    const Path secrets_path = config_dir / "secrets.local.toml";
    if (!file_ok(secrets_path)) {
        std::println(stderr, "auth: chưa có secrets.local.toml, bỏ qua database");
        idle_until_stop();
        return 0;
    }
    std::string error;
    const std::optional<config::Cluster> cluster = read_cfg(config_dir / "cluster.toml", config::read_cluster, error, "cluster.toml");
    const std::optional<config::Auth> auth = read_cfg(config_dir / "auth.toml", config::read_auth, error, "auth.toml");
    const std::optional<config::Secrets> secrets = read_cfg(secrets_path, config::read_secrets, error, "secrets.local.toml");
    if (!cluster || !auth || !secrets || secrets->auth.empty()) {
        if (error.empty()) error = "thiếu mật khẩu database tài khoản";
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    const std::optional<config::ProcessBlock> process = find_process(*cluster, config::ProcessKind::kAuth);
    if (!process) {
        std::println(stderr, "auth: cluster.toml không có tiến trình auth 0");
        return 2;
    }
    const std::optional<net::Endpoint> endpoint = endpoint_of(process->host, process->port);
    if (!endpoint || !loopback_address(*endpoint)) {
        std::println(stderr, "auth: ipc chỉ nghe 127.0.0.1");
        return 2;
    }
    AuthOptions options;
    options.auto_register = auth->auto_register;
    options.gift_points = auth->gift_points;
    options.ttl_seconds = static_cast<int>(auth->ttl_seconds.count());
    options.ops_limit = static_cast<int>(auth->ops_limit);
    options.mem_limit_kib = static_cast<int>(auth->mem_limit_kib);
    if (cluster->postgres.host.text() != "127.0.0.1") {
        std::println(stderr, "auth: postgres chỉ được ở 127.0.0.1");
        return 1;
    }
    if (!probe_password(options, error)) {
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    const std::optional<std::array<std::byte, kIpcKeyBytes>> key = load_or_create_ipc_key(ipc_key_path(config_dir), error);
    if (!key) {
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    const store::PgLogin login = login_of(*cluster, auth->database, secrets->auth);
    std::optional<store::PgConn> conn = store::PgConn::open(login, error);
    if (!conn) {
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    const Path sql_dir = (config_dir / ".." / "sql" / "auth").lexically_normal();
    if (!store::migrate(*conn, sql_dir, error)) {
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    std::optional<Listen> opened = open_listen(*endpoint, error);
    if (!opened) {
        std::println(stderr, "auth: {}", error);
        return 1;
    }
    AuthDb db{*conn, options};
    AuthCtx ctx{&db, &*key};
    std::println("ready ipc={}", opened->port);
    static_cast<void>(std::fflush(stdout));
    return serve_loop(opened->listener, &on_auth, &ctx, *key);
}

int serve_game(const Path& config_dir) {
    const Path secrets_path = config_dir / "secrets.local.toml";
    if (!file_ok(secrets_path)) {
        std::println(stderr, "store: chưa có secrets.local.toml, bỏ qua database");
        idle_until_stop();
        return 0;
    }
    std::string error;
    const std::optional<config::Cluster> cluster = read_cfg(config_dir / "cluster.toml", config::read_cluster, error, "cluster.toml");
    const std::optional<config::Store> store_cfg = read_cfg(config_dir / "store.toml", config::read_store, error, "store.toml");
    const std::optional<config::Secrets> secrets = read_cfg(secrets_path, config::read_secrets, error, "secrets.local.toml");
    if (!cluster || !store_cfg || !secrets || secrets->store.empty()) {
        if (error.empty()) error = "thiếu mật khẩu database game";
        std::println(stderr, "store: {}", error);
        return 1;
    }
    if (cluster->postgres.host.text() != "127.0.0.1") {
        std::println(stderr, "store: postgres chỉ được ở 127.0.0.1");
        return 1;
    }
    const std::optional<std::array<std::byte, kIpcKeyBytes>> key = load_or_create_ipc_key(ipc_key_path(config_dir), error);
    if (!key) {
        std::println(stderr, "store: {}", error);
        return 1;
    }
    const std::optional<config::ProcessBlock> process = find_process(*cluster, config::ProcessKind::kStore);
    if (!process) {
        std::println(stderr, "store: cluster.toml không có tiến trình store 0");
        return 2;
    }
    const std::optional<net::Endpoint> endpoint = endpoint_of(process->host, process->port);
    if (!endpoint || !loopback_address(*endpoint)) {
        std::println(stderr, "store: ipc chỉ nghe 127.0.0.1");
        return 2;
    }
    const store::PgLogin login = login_of(*cluster, store_cfg->database, secrets->store);
    std::optional<store::PgConn> conn = store::PgConn::open(login, error);
    if (!conn) {
        std::println(stderr, "store: {}", error);
        return 1;
    }
    const Path sql_dir = (config_dir / ".." / "sql" / "game").lexically_normal();
    if (!store::migrate(*conn, sql_dir, error)) {
        std::println(stderr, "store: {}", error);
        return 1;
    }
    std::optional<Listen> opened = open_listen(*endpoint, error);
    if (!opened) {
        std::println(stderr, "store: {}", error);
        return 1;
    }
    const std::optional<config::ProcessBlock> auth_process = find_process(*cluster, config::ProcessKind::kAuth);
    std::optional<net::Endpoint> auth_endpoint;
    if (auth_process) auth_endpoint = endpoint_of(auth_process->host, auth_process->port);
    if (!auth_endpoint || !loopback_address(*auth_endpoint) || auth_endpoint->port == 0) {
        std::println(stderr, "store: cần cổng auth 0 cố định trên 127.0.0.1 để kiểm ban");
        return 2;
    }
    const config::StoreSecurity& security = store_cfg->security;
    const auto ids = [](const std::vector<std::int64_t>& from) {
        std::vector<std::uint16_t> out;
        out.reserve(from.size());
        for (const std::int64_t id : from) out.push_back(static_cast<std::uint16_t>(id));
        return out;
    };
    CharacterPolicy policy;
    policy.look.female_faces = ids(security.female_faces);
    policy.look.male_faces = ids(security.male_faces);
    policy.look.female_hairs = ids(security.female_hairs);
    policy.look.male_hairs = ids(security.male_hairs);
    policy.name_reserve = std::chrono::hours{24} * security.name_reserve_days;
    GameDb db{*conn, std::move(policy)};
    GameCtx ctx;
    ctx.standing = StandingCache{security.standing_cache_ms};
    ctx.db = &db;
    ctx.key = &*key;
    ctx.auth = *auth_endpoint;
    std::println("ready ipc={}", opened->port);
    static_cast<void>(std::fflush(stdout));
    return serve_loop(opened->listener, &on_game, &ctx, *key);
}

} // namespace game::account
