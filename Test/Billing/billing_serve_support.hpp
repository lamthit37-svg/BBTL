// Hàng rào cho test chạy exe thienlong_billing thật: dựng một thư mục cấu hình tạm cạnh exe test (bản chép của
// dev/server/config với billing.toml, cluster.toml, secrets.local.toml viết lại), một database PostgreSQL tạm cho
// riêng test (CREATE DATABASE bằng role postgres, bỏ khi xong), chạy/giết/chạy lại tiến trình, và một máy khách
// HTTP/ipc tối thiểu. Không có role postgres hoặc không nối được PostgreSQL thì open_stage trả rỗng và test tự bỏ
// qua. Mật khẩu chỉ đi vào secrets.local.toml tạm trong cây dựng, không vào chuỗi in ra.
#pragma once

#include "account/ipc_key.hpp"
#include "billing/rpc.hpp"
#include "billing/serve/client.hpp"
#include "billing/webhook.hpp"
#include "core/number.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "net/net.hpp"
#include "process/process.hpp"
#include "secure/private_file.hpp"
#include "store/pg.hpp"

#include "billing_pg_support.hpp"
#include "support/lax_file.hpp"
#include "support/loopback_config.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::test::billing_serve {

using Path = std::filesystem::path;

#ifdef _WIN32
inline constexpr std::string_view kExe = "thienlong_billing.exe";
#else
inline constexpr std::string_view kExe = "thienlong_billing";
#endif

inline constexpr std::string_view kProviderName = "alpha";
inline constexpr std::string_view kProviderPath = "/pay/alpha";

// Khoá HMAC của nhà cung cấp thử: byte 0, 1, ..., 31.
[[nodiscard]] inline billing::ProviderKey provider_key() {
    billing::ProviderKey key{};
    std::size_t next = 0;
    std::ranges::generate(key, [&next] { return static_cast<std::byte>(next++); });
    return key;
}

[[nodiscard]] inline std::string provider_key_hex() {
    std::string hex;
    for (const std::byte byte : provider_key())
        hex += std::format("{:02x}", static_cast<unsigned>(byte));
    return hex;
}

struct StageOptions {
    // pending_timeout_seconds và reconcile_interval_seconds của billing.toml.
    int pending_timeout = 600;
    int reconcile_interval = 60;
    bool write_secrets = true;
    // Khác rỗng: ghi vào tệp khoá của nhà cung cấp (thử khoá hỏng).
    std::string key_file_text;
    // Mở quyền đọc tệp khoá cho mọi người (thử billing từ chối khoá lỏng quyền).
    bool lax_key_file = false;
    // Mở quyền đọc secrets.local.toml cho mọi người (thử billing từ chối mật khẩu database lỏng quyền).
    bool lax_secrets = false;
    // Khác rỗng: đè mật khẩu database (thử sai mật khẩu).
    std::string password_override;
};

// Thư mục cấu hình + database tạm. Huỷ thì bỏ cả hai.
class Stage {
public:
    [[nodiscard]] static std::unique_ptr<Stage> create(const billing_pg::Access& access, const StageOptions& options,
        std::string& why) {
        if (!access.admin) {
            why = "không có mật khẩu role postgres để dựng database tạm";
            return nullptr;
        }
        std::unique_ptr<Stage> stage{new Stage{access, *access.admin}};
        stage->database_ = billing_pg::random_name("tb_serve_");
        stage->drop_sql_ = std::format("DROP DATABASE IF EXISTS {} WITH (FORCE)", stage->database_);
        stage->root_ = io::executable_directory() / io::path_from_utf8(stage->database_);
        if (!stage->make_database(why)) return nullptr;
        if (!stage->write_files(options, why)) return nullptr;
        return stage;
    }

    ~Stage() {
        // Dọn cố gắng hết sức: lỗi cấp phát lúc dọn chỉ để lại thư mục hoặc database mồ côi, mà lần chạy sau tự quét
        // (sweep_orphans). Destructor không được ném, nên chặn ở đây và báo ra stderr.
        try {
            std::error_code ignored;
            std::filesystem::remove_all(root_, ignored);
            std::string error;
            std::optional<store::PgConn> admin = store::PgConn::open(*admin_, error);
            if (admin) static_cast<void>(admin->exec(drop_sql_));
        } catch (const std::exception& problem) {
            static_cast<void>(std::fputs("billing_serve: không dọn hết thư mục và database tạm: ", stderr));
            static_cast<void>(std::fputs(problem.what(), stderr));
            static_cast<void>(std::fputs("\n", stderr));
        }
    }
    Stage(const Stage&) = delete;
    Stage& operator=(const Stage&) = delete;
    Stage(Stage&&) = delete;
    Stage& operator=(Stage&&) = delete;

    [[nodiscard]] const Path& config() const noexcept { return config_; }
    [[nodiscard]] const std::string& database() const noexcept { return database_; }
    [[nodiscard]] std::uint16_t webhook_port() const noexcept { return webhook_port_; }

    // Đăng nhập thẳng vào database tạm bằng role billing, để đối soát bằng SQL viết riêng.
    [[nodiscard]] std::optional<store::PgConn> open_sql(std::string& why) const {
        store::PgLogin login = access_->billing;
        login.dbname = database_;
        return store::PgConn::open(login, why);
    }

private:
    Stage(const billing_pg::Access& access, const store::PgLogin& admin) : access_(&access), admin_(&admin) {}

    [[nodiscard]] bool make_database(std::string& why) {
        std::optional<store::PgConn> admin = store::PgConn::open(*admin_, why);
        if (!admin) return false;
        sweep_orphans(*admin);
        const store::PgExec made =
            admin->exec(std::format("CREATE DATABASE {} OWNER {}", database_, access_->billing.user));
        if (!made.ok) {
            why = made.message;
            return false;
        }
        static_cast<void>(admin->exec(
            std::format("COMMENT ON DATABASE {} IS 'tb_test {}'", database_, billing_pg::unix_seconds())));
        return true;
    }

    static void sweep_orphans(store::PgConn& admin) {
        const store::PgExec found = admin.exec(
            "SELECT datname, COALESCE(shobj_description(oid, 'pg_database'), '') FROM pg_database WHERE datname LIKE "
            "'tb\\_serve\\_%'");
        if (!found.ok) return;
        const std::int64_t cutoff = billing_pg::unix_seconds() - 3600;
        constexpr std::string_view kTag = "tb_test ";
        for (const store::PgRow& row : found.rows) {
            if (row.cells.size() != 2 || !row.cells[1].text.starts_with(kTag)) continue;
            std::int64_t made = 0;
            const std::string& comment = row.cells[1].text;
            // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
            const auto parsed = std::from_chars(comment.data() + kTag.size(), comment.data() + comment.size(), made);
            if (parsed.ec != std::errc{} || made >= cutoff) continue;
            static_cast<void>(admin.exec(std::format("DROP DATABASE IF EXISTS {} WITH (FORCE)", row.cells[0].text)));
        }
    }

    // Cổng TCP trống do hệ điều hành cấp rồi trả lại: billingd nghe lại đúng cổng đó (đổi cổng giữa hai lần chạy
    // lại sẽ làm nhà cung cấp giả gọi nhầm). Có khe hở rất ngắn giữa lúc trả và lúc billingd nghe.
    [[nodiscard]] static std::uint16_t free_port() {
        const net::NetResult<net::Network> network = net::Network::start();
        if (!network) return 0;
        net::NetResult<net::TcpListener> listener = net::TcpListener::open(net::Endpoint{.address = {127, 0, 0, 1}, .port = 0});
        if (!listener) return 0;
        const net::NetResult<net::Endpoint> local = listener->local();
        return local ? local->port : std::uint16_t{0};
    }

    [[nodiscard]] static bool write_text(const Path& file, std::string_view text) {
        std::ofstream out{file, std::ios::binary | std::ios::trunc};
        out << text;
        out.close();
        return static_cast<bool>(out);
    }

    // Tệp bí mật (khoá nhà cung cấp, secrets.local.toml) phải riêng ngay lúc tạo: billing từ chối tệp mà tài khoản khác
    // đọc được (secure::file_private), và quyền kế thừa từ cây dựng thì không chắc đã riêng.
    [[nodiscard]] static bool write_secret_file(const Path& file, std::string_view text, bool lax) {
        if (lax) return write_world_readable(file, text);
        bool existed = false;
        std::string error;
        return secure::create_private_file(file, std::as_bytes(std::span{text}), "tệp bí mật", existed, error);
    }

    // Các giá trị billing.toml bị đổi.
    struct BillingEdits {
        std::string_view database;
        std::uint16_t port;
        int pending_timeout;
        int reconcile_interval;
    };

    // Dòng `name = "..."` đầu tiên sau [database] đổi sang tên database tạm; dòng `port` sau [webhook] đổi sang cổng
    // webhook; thêm khối [[provider]].
    [[nodiscard]] static std::string billing_toml(std::string_view text, const BillingEdits& edits) {
        std::string out;
        std::string section;
        while (!text.empty()) {
            const std::string_view line = take_line(text);
            if (line.starts_with('[')) section = std::string{line.substr(0, line.find(']') + 1)};
            if (section == "[database]" && has_key(line, "name")) {
                out += std::format("name = \"{}\"\n", edits.database);
            } else if (section == "[webhook]" && has_key(line, "port")) {
                out += std::format("port = {}\n", edits.port);
            } else if (section == "[orders]" && has_key(line, "pending_timeout_seconds")) {
                out += std::format("pending_timeout_seconds = {}\n", edits.pending_timeout);
            } else if (section == "[orders]" && has_key(line, "reconcile_interval_seconds")) {
                out += std::format("reconcile_interval_seconds = {}\n", edits.reconcile_interval);
            } else {
                out += line;
                out += '\n';
            }
        }
        out += std::format("\n[[provider]]\nkey = \"{}\"\nwebhook_path = \"{}\"\nsecret_file = \"alpha.key\"\nenabled = true\n",
            kProviderName, kProviderPath);
        return out;
    }

    // cluster.toml: khối [[process]] của billing nghe cổng 0 (hệ điều hành cấp, báo ở dòng ready).
    [[nodiscard]] static std::string cluster_toml(std::string_view text) {
        std::string out;
        bool in_billing = false;
        while (!text.empty()) {
            const std::string_view line = take_line(text);
            if (line.starts_with('[')) in_billing = false;
            if (has_key(line, "kind")) in_billing = quoted_value(line) == std::string_view{"billing"};
            if (in_billing && has_key(line, "port")) {
                out += "port = 0\n";
            } else {
                out += line;
                out += '\n';
            }
        }
        return out;
    }

    [[nodiscard]] bool write_files(const StageOptions& options, std::string& why) {
        const Path real_config = io::path_from_utf8(billing_pg::kConfigDir);
        config_ = root_ / "config";
        std::error_code error;
        std::filesystem::create_directories(config_, error);
        std::filesystem::create_directories(root_ / "sql" / "billing", error);
        std::filesystem::create_directories(root_ / "tables" / "server", error);
        if (error) {
            why = "không dựng được thư mục tạm";
            return false;
        }
        if (!copy_public_toml({.from = real_config, .into = config_})) {
            why = "không chép được cấu hình";
            return false;
        }
        for (const auto& entry : std::filesystem::directory_iterator{access_->sql_dir, error}) {
            std::filesystem::copy_file(entry.path(), root_ / "sql" / "billing" / entry.path().filename(), error);
        }
        std::filesystem::copy_file(real_config / ".." / "tables" / "server" / "billing_limits.tsv",
            root_ / "tables" / "server" / "billing_limits.tsv", error);
        if (error) {
            why = "không chép được sql và bảng giới hạn";
            return false;
        }
        webhook_port_ = free_port();
        const io::TextResult billing = io::read_text(config_ / "billing.toml");
        const io::TextResult cluster = io::read_text(config_ / "cluster.toml");
        if (!billing || !cluster || webhook_port_ == 0) {
            why = "không đọc được billing.toml hoặc cluster.toml";
            return false;
        }
        const BillingEdits edits{.database = database_,
            .port = webhook_port_,
            .pending_timeout = options.pending_timeout,
            .reconcile_interval = options.reconcile_interval};
        bool ok = write_text(config_ / "billing.toml", billing_toml(*billing, edits));
        ok = write_text(config_ / "cluster.toml", cluster_toml(*cluster)) && ok;
        const std::string key_text = options.key_file_text.empty() ? provider_key_hex() + "\n" : options.key_file_text;
        ok = write_secret_file(config_ / "alpha.key", key_text, options.lax_key_file) && ok;
        if (options.write_secrets) {
            const std::string password =
                options.password_override.empty() ? access_->billing.password : options.password_override;
            ok = write_secret_file(config_ / "secrets.local.toml",
                     std::format("schema = 1\n\n[database.postgres]\npassword = \"\"\n\n[database.thienlong_auth]\n"
                                 "password = \"\"\n\n[database.thienlong_billing]\npassword = \"{}\"\n\n"
                                 "[database.thienlong_store]\npassword = \"\"\n",
                         password),
                     options.lax_secrets) &&
                ok;
        }
        if (!ok) why = "không ghi được tệp cấu hình tạm";
        return ok;
    }

    const billing_pg::Access* access_;
    // Quyền role postgres (từ access_->admin, đã kiểm có ở create).
    const store::PgLogin* admin_;
    std::string database_;
    // Câu DROP dựng sẵn để destructor không còn gì có thể ném.
    std::string drop_sql_;
    Path root_;
    Path config_;
    std::uint16_t webhook_port_ = 0;
};

// Một tiến trình thienlong_billing đang chạy.
class Daemon {
public:
    // Chạy exe, chờ dòng `ready ipc=<cổng>` (hoặc `ready` khi không có secrets) tối đa `patience`.
    [[nodiscard]] static std::unique_ptr<Daemon> start(const Stage& stage,
        std::chrono::milliseconds patience = std::chrono::seconds{30}) {
        std::unique_ptr<Daemon> daemon{new Daemon{}};
        if (!daemon->launch(stage, patience)) return nullptr;
        return daemon;
    }

    // Tiến trình đã thoát trước khi sẵn sàng: mã thoát. nullopt nếu còn chạy hoặc không có.
    [[nodiscard]] static std::optional<int> start_and_wait_exit(const Stage& stage,
        std::chrono::milliseconds patience = std::chrono::seconds{30}) {
        const std::string program = io::utf8_of(io::executable_directory() / io::path_from_utf8(kExe));
        const std::string config = io::utf8_of(stage.config());
        const std::array<std::string_view, 2> arguments{"--config", config};
        core::Result<process::Child> child =
            process::spawn(process::Spawn{.executable = program, .arguments = arguments, .mode = process::Mode::kService});
        if (!child) return std::nullopt;
        const process::ExitStatus status = child->wait_for(patience);
        if (status.kind != process::WaitKind::kExited) return std::nullopt;
        return status.code;
    }

    ~Daemon() = default;
    Daemon(const Daemon&) = delete;
    Daemon& operator=(const Daemon&) = delete;
    Daemon(Daemon&&) = delete;
    Daemon& operator=(Daemon&&) = delete;

    [[nodiscard]] std::uint16_t ipc_port() const noexcept { return ipc_port_; }
    [[nodiscard]] bool has_database() const noexcept { return ipc_port_ != 0; }
    [[nodiscard]] const std::string& ready_line() const noexcept { return ready_line_; }

    // Khách ipc dùng khoá ipc.key mà billingd đã sinh.
    [[nodiscard]] std::unique_ptr<billing::Client> client() const {
        if (!key_) return nullptr;
        return std::make_unique<billing::Client>(net::Endpoint{.address = {127, 0, 0, 1}, .port = ipc_port_}, *key_);
    }

    // Đóng stdin như trình giám sát: tiến trình dừng êm. Mã thoát, nullopt nếu quá hạn.
    [[nodiscard]] std::optional<int> stop_clean(std::chrono::milliseconds patience = std::chrono::seconds{30}) {
        child_.close_input();
        const process::ExitStatus status = child_.wait_for(patience);
        if (status.kind != process::WaitKind::kExited) return std::nullopt;
        return status.code;
    }

    // Giết ngay như mất điện: không dọn gì.
    void crash() noexcept { child_.force_stop(); }

    [[nodiscard]] bool alive() noexcept { return !child_.try_wait().has_value(); }

private:
    Daemon() = default;

    [[nodiscard]] bool launch(const Stage& stage, std::chrono::milliseconds patience) {
        const std::string program = io::utf8_of(io::executable_directory() / io::path_from_utf8(kExe));
        const std::string config = io::utf8_of(stage.config());
        const std::array<std::string_view, 2> arguments{"--config", config};
        core::Result<process::Child> child =
            process::spawn(process::Spawn{.executable = program, .arguments = arguments, .mode = process::Mode::kService});
        if (!child) return false;
        child_ = std::move(*child);
        core::Result<process::Line> line = child_.read_line(patience);
        if (!line || line->kind != process::LineKind::kText) return false;
        ready_line_ = line->text;
        constexpr std::string_view kIpc = "ready ipc=";
        if (ready_line_ == "ready") return true;
        if (!ready_line_.starts_with(kIpc)) return false;
        const std::optional<int> port = core::parse_whole_int(std::string_view{ready_line_}.substr(kIpc.size()));
        if (!port || *port < 1 || *port > 65535) return false;
        ipc_port_ = static_cast<std::uint16_t>(*port);
        std::string error;
        key_ = account::load_ipc_key(account::ipc_key_path(stage.config()), error);
        return key_.has_value();
    }

    process::Child child_;
    std::string ready_line_;
    std::uint16_t ipc_port_ = 0;
    std::optional<std::array<std::byte, account::kIpcKeyBytes>> key_;
};

// ---- HTTP và socket thô -------------------------------------------------------------------------------

struct HttpAnswer {
    // Có nhận được dòng trạng thái không.
    bool answered = false;
    int status = 0;
    std::string body;
    // Bên kia đã đóng kết nối (FIN) trước hạn.
    bool closed = false;
};

class Socket {
public:
    [[nodiscard]] static std::optional<Socket> connect(std::uint16_t port, std::chrono::milliseconds patience) {
        net::NetResult<net::Network> network = net::Network::start();
        if (!network) return std::nullopt;
        net::NetResult<net::TcpStream> stream = net::TcpStream::begin_connect(net::Endpoint{.address = {127, 0, 0, 1}, .port = port});
        if (!stream) return std::nullopt;
        Socket socket{std::move(*network), std::move(*stream)};
        if (!socket.poll_.add(socket.stream_.handle(), kTag)) return std::nullopt;
        socket.poll_.want_write(kTag, true);
        const auto deadline = std::chrono::steady_clock::now() + patience;
        net::PollEvents events;
        while (std::chrono::steady_clock::now() < deadline) {
            if (!socket.poll_.wait(std::chrono::milliseconds{50}, events)) return std::nullopt;
            if (events.empty()) continue;
            const net::NetResult<bool> done = socket.stream_.finish_connect();
            if (!done) return std::nullopt;
            if (*done) {
                socket.poll_.want_write(kTag, false);
                return socket;
            }
        }
        return std::nullopt;
    }

    ~Socket() {
        if (stream_.is_open()) poll_.remove(kTag);
    }
    Socket(Socket&& other) noexcept
        : network_(std::move(other.network_)), stream_(std::move(other.stream_)), poll_(std::move(other.poll_)) {}
    Socket& operator=(Socket&&) = delete;
    Socket(const Socket&) = delete;
    Socket& operator=(const Socket&) = delete;

    // Gửi hết; false khi đứt hoặc quá hạn.
    [[nodiscard]] bool send_all(std::span<const std::byte> data, std::chrono::milliseconds patience) {
        const auto deadline = std::chrono::steady_clock::now() + patience;
        net::PollEvents events;
        while (!data.empty()) {
            const net::NetResult<std::size_t> sent = stream_.send(data);
            if (!sent) return false;
            data = data.subspan(*sent);
            if (data.empty()) break;
            if (*sent == 0) {
                if (std::chrono::steady_clock::now() >= deadline) return false;
                poll_.want_write(kTag, true);
                if (!poll_.wait(std::chrono::milliseconds{50}, events)) return false;
                poll_.want_write(kTag, false);
            }
        }
        return true;
    }

    [[nodiscard]] bool send_text(std::string_view text, std::chrono::milliseconds patience = std::chrono::seconds{5}) {
        return send_all(std::as_bytes(std::span{text}), patience);
    }

    // Đọc tới khi bên kia đóng hoặc hết hạn. closed cho biết đã thấy FIN hay RST.
    [[nodiscard]] HttpAnswer read_answer(std::chrono::milliseconds patience) {
        HttpAnswer answer;
        std::string raw;
        const auto deadline = std::chrono::steady_clock::now() + patience;
        net::PollEvents events;
        std::array<char, 1024> chunk{};
        while (std::chrono::steady_clock::now() < deadline) {
            if (!poll_.wait(std::chrono::milliseconds{50}, events)) break;
            bool finished = false;
            for (;;) {
                const net::NetResult<std::size_t> got = stream_.receive(std::as_writable_bytes(std::span{chunk}));
                if (!got) {
                    answer.closed = true;
                    finished = true;
                    break;
                }
                if (*got == 0) break;
                raw.append(chunk.data(), *got);
            }
            if (finished) break;
        }
        parse_answer(raw, answer);
        return answer;
    }

private:
    static constexpr std::uint64_t kTag = 1;

    Socket(net::Network network, net::TcpStream stream) : network_(std::move(network)), stream_(std::move(stream)) {}

    static void parse_answer(const std::string& raw, HttpAnswer& answer) {
        if (!raw.starts_with("HTTP/1.1 ") || raw.size() < 12) return;
        const std::optional<int> code = core::parse_whole_int(std::string_view{raw}.substr(9, 3));
        if (!code) return;
        answer.answered = true;
        answer.status = *code;
        const std::size_t split = raw.find("\r\n\r\n");
        if (split != std::string::npos) answer.body = raw.substr(split + 4);
    }

    net::Network network_;
    net::TcpStream stream_;
    net::PollSet poll_;
};

// Một yêu cầu webhook hoàn chỉnh. Mỗi trường để lệch được nhằm thử từ chối.
struct Delivery {
    std::string path = std::string{kProviderPath};
    std::string body{};
    std::int64_t timestamp = 0;
    // Rỗng: ký đúng bằng khoá của nhà cung cấp.
    std::string signature_override{};
};

[[nodiscard]] inline std::string webhook_request(const Delivery& delivery) {
    const std::string signature = delivery.signature_override.empty()
        ? billing::sign_webhook(provider_key(),
              {.path = kProviderPath, .timestamp = delivery.timestamp, .body = delivery.body})
        : delivery.signature_override;
    return std::format(
        "POST {} HTTP/1.1\r\nHost: billing\r\nX-Timestamp: {}\r\nX-Signature: {}\r\n"
        "Content-Type: application/x-www-form-urlencoded\r\nContent-Length: {}\r\n\r\n{}",
        delivery.path, delivery.timestamp, signature, delivery.body.size(), delivery.body);
}

// Gửi byte thô tới cổng webhook và đọc câu trả lời. answered false khi không có dòng trạng thái.
[[nodiscard]] inline HttpAnswer http_exchange(std::uint16_t port, std::string_view raw,
    std::chrono::milliseconds patience = std::chrono::seconds{10}) {
    std::optional<Socket> socket = Socket::connect(port, patience);
    if (!socket) return {};
    if (!socket->send_text(raw)) return {};
    return socket->read_answer(patience);
}

[[nodiscard]] inline std::string order_body(std::string_view trade, std::uint64_t account, std::int64_t points,
    std::string_view status = "paid") {
    return std::format("trade_no={}&account={}&points={}&amount={}&currency=VND&status={}", trade, account, points,
        points * 1000, status);
}

[[nodiscard]] inline std::int64_t unix_now() {
    return billing_pg::unix_seconds();
}

} // namespace game::test::billing_serve
