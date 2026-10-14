// Hàng rào PostgreSQL cho test billing: đọc quyền truy cập từ dev/server/config (secrets.local.toml), dựng một
// schema riêng cho mỗi test (không đụng bảng thật của database billing) và dọn khi xong. Không có
// secrets.local.toml hoặc không nối được thì open_access() trả rỗng kèm lý do và test tự bỏ qua. Mật khẩu chỉ nằm
// trong PgLogin, không bao giờ vào chuỗi in ra.
#pragma once

#include "billing/db/pg_book.hpp"
#include "config/billing.hpp"
#include "config/cluster.hpp"
#include "config/secrets.hpp"
#include "io/file.hpp"
#include "store/pg.hpp"

#include <charconv>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <print>
#include <random>
#include <string>
#include <string_view>
#include <utility>

namespace game::test::billing_pg {

#ifdef GAME_SERVER_CONFIG
inline constexpr std::string_view kConfigDir = GAME_SERVER_CONFIG;
#else
// check.py dịch tệp này không có định nghĩa của CMake; đường dẫn từ gốc dự án để tệp tự đứng được.
inline constexpr std::string_view kConfigDir = "dev/server/config";
#endif

struct Access {
    // Role billing trên database billing: chủ của database, tạo được schema.
    store::PgLogin billing;
    // Role postgres (nếu secrets có mật khẩu), để dựng database tạm cho test chạy exe.
    std::optional<store::PgLogin> admin;
    std::filesystem::path config_dir;
    std::filesystem::path sql_dir;
};

inline void prefix_note(std::string& why, std::string_view text) {
    why = std::format("bỏ qua test PostgreSQL: {}", text);
}

// Quyền truy cập và đã thử nối một lần. `why` có lý do khi trả rỗng.
[[nodiscard]] inline std::optional<Access> open_access(std::string& why) {
    const std::filesystem::path config_dir = io::path_from_utf8(kConfigDir);
    const io::TextResult secrets_text = io::read_text(config_dir / "secrets.local.toml");
    const io::TextResult cluster_text = io::read_text(config_dir / "cluster.toml");
    const io::TextResult billing_text = io::read_text(config_dir / "billing.toml");
    if (!secrets_text || !cluster_text || !billing_text) {
        prefix_note(why, "không có secrets.local.toml, cluster.toml hoặc billing.toml");
        return std::nullopt;
    }
    const config::ReadResult<config::Secrets> secrets = config::read_secrets(*secrets_text);
    const config::ReadResult<config::Cluster> cluster = config::read_cluster(*cluster_text);
    const config::ReadResult<config::Billing> billing = config::read_billing(*billing_text);
    if (!secrets || !cluster || !billing || secrets->billing.empty()) {
        prefix_note(why, "cấu hình không đọc được hoặc thiếu mật khẩu billing");
        return std::nullopt;
    }
    Access access;
    access.config_dir = config_dir;
    access.sql_dir = (config_dir / ".." / "sql" / "billing").lexically_normal();
    access.billing.host = std::string{cluster->postgres.host.text()};
    access.billing.port = std::to_string(static_cast<unsigned>(cluster->postgres.port.value()));
    access.billing.dbname = billing->database.name;
    access.billing.user = billing->database.user;
    access.billing.password = secrets->billing;
    if (!secrets->postgres.empty()) {
        store::PgLogin admin = access.billing;
        admin.dbname = "postgres";
        admin.user = "postgres";
        admin.password = secrets->postgres;
        access.admin = std::move(admin);
    }
    std::string error;
    const std::optional<store::PgConn> probe = store::PgConn::open(access.billing, error);
    if (!probe) {
        prefix_note(why, "không nối được PostgreSQL (cụm chưa chạy?)");
        return std::nullopt;
    }
    return access;
}

struct Shared {
    std::optional<Access> access;
    std::string why;
};

// Tính một lần cho cả tiến trình test. Cố ý không huỷ khi thoát (release): đối tượng tĩnh có destructor chạy sau
// main, lúc thread của một ca còn sống có thể đang đọc nó.
[[nodiscard]] inline const Shared& shared() {
    static const Shared* const value = [] {
        std::unique_ptr<Shared> made = std::make_unique<Shared>();
        made->access = open_access(made->why);
        return made.release();
    }();
    return *value;
}

// Quyền truy cập dùng chung; rỗng thì in một dòng "bỏ qua" mang tên ca.
[[nodiscard]] inline const Access* shared_access(std::string_view name) {
    const Shared& state = shared();
    if (!state.access) {
        std::println("[bỏ qua] {}: {}", name, state.why);
        return nullptr;
    }
    return &*state.access;
}

[[nodiscard]] inline std::int64_t unix_seconds() {
    const auto since = std::chrono::system_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::seconds>(since).count();
}

[[nodiscard]] inline std::string random_name(std::string_view prefix) {
    std::random_device device;
    const std::uint64_t value = (static_cast<std::uint64_t>(device()) << 32U) ^ device();
    return std::format("{}{:012x}", prefix, value & 0xFFFF'FFFF'FFFFULL);
}

// Một schema riêng của test: tạo, áp migration của billing, và DROP ... CASCADE khi huỷ. Schema mồ côi (test bị
// giết giữa chừng) mang dấu giờ tạo trong COMMENT và bị dọn ở lần tạo schema đầu tiên của lần chạy sau.
class Schema {
public:
    [[nodiscard]] static std::unique_ptr<Schema> create(const Access& access, std::string& why) {
        std::optional<store::PgConn> conn = store::PgConn::open(access.billing, why);
        if (!conn) return nullptr;
        sweep_orphans(*conn);
        std::unique_ptr<Schema> schema{new Schema{access, std::move(*conn), random_name("tb_")}};
        if (!schema->setup(why)) return nullptr;
        return schema;
    }

    ~Schema() {
        if (conn_.is_open()) {
            // Đưa phiên về schema khác trước khi bỏ schema đang dùng. Câu DROP dựng sẵn ở constructor để destructor
            // không còn gì có thể ném.
            static_cast<void>(conn_.exec("SET search_path TO public"));
            static_cast<void>(conn_.exec(drop_sql_));
        }
    }
    Schema(const Schema&) = delete;
    Schema& operator=(const Schema&) = delete;
    Schema(Schema&&) = delete;
    Schema& operator=(Schema&&) = delete;

    [[nodiscard]] const std::string& name() const noexcept { return name_; }

    // Chuỗi cho PgOptions::session_setup: phiên của PgBook nhìn đúng schema này. `application` rỗng thì
    // không đặt tên ứng dụng.
    [[nodiscard]] std::string session_setup(std::string_view application = {}) const {
        std::string sql = std::format("SET search_path TO {}", name_);
        if (!application.empty()) sql += std::format("; SET application_name = '{}'", application);
        return sql;
    }

    [[nodiscard]] billing::PgOptions options(std::string_view application = {}) const {
        return billing::PgOptions{.login = access_->billing, .session_setup = session_setup(application)};
    }

    // Truy vấn trực tiếp (bỏ qua PgBook) trên schema này.
    [[nodiscard]] store::PgExec exec(std::string_view sql) { return conn_.exec(sql); }

    [[nodiscard]] store::PgExec exec(std::string_view sql, std::span<const std::optional<std::string>> params) {
        return conn_.exec(sql, params);
    }

    // Giá trị số nguyên ở ô đầu của dòng đầu; -1 khi truy vấn hỏng hay rỗng.
    [[nodiscard]] std::int64_t scalar(std::string_view sql) {
        const store::PgExec result = conn_.exec(sql);
        if (!result.ok || result.rows.empty() || result.rows.front().cells.empty()) return -1;
        std::int64_t value = -1;
        const std::string& text = result.rows.front().cells.front().text;
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
        const auto parsed = std::from_chars(text.data(), text.data() + text.size(), value);
        return parsed.ec == std::errc{} ? value : -1;
    }

private:
    Schema(const Access& access, store::PgConn conn, std::string name)
        : access_(&access), conn_(std::move(conn)), name_(std::move(name)),
          drop_sql_(std::format("DROP SCHEMA IF EXISTS {} CASCADE", name_)) {}

    [[nodiscard]] bool setup(std::string& why) {
        // DROP ... CASCADE ở destructor in một NOTICE mỗi bảng; chỉ giữ cảnh báo và lỗi.
        static_cast<void>(conn_.exec("SET client_min_messages TO warning"));
        store::PgExec made = conn_.exec(std::format("CREATE SCHEMA {}", name_));
        if (!made.ok) {
            why = made.message;
            return false;
        }
        static_cast<void>(conn_.exec(std::format("COMMENT ON SCHEMA {} IS 'tb_test {}'", name_, unix_seconds())));
        made = conn_.exec(std::format("SET search_path TO {}", name_));
        if (!made.ok) {
            why = made.message;
            return false;
        }
        return store::migrate(conn_, access_->sql_dir, why);
    }

    static void sweep_orphans(store::PgConn& conn) {
        const store::PgExec found = conn.exec(
            "SELECT n.nspname, COALESCE(obj_description(n.oid, 'pg_namespace'), '') FROM pg_namespace n WHERE n.nspname "
            "LIKE 'tb\\_%'");
        if (!found.ok) return;
        const std::int64_t cutoff = unix_seconds() - 3600;
        for (const store::PgRow& row : found.rows) {
            if (row.cells.size() != 2) continue;
            constexpr std::string_view kTag = "tb_test ";
            const std::string& comment = row.cells[1].text;
            if (!comment.starts_with(kTag)) continue;
            std::int64_t made = 0;
            // NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
            const char* const first = comment.data() + kTag.size();
            const auto parsed = std::from_chars(first, comment.data() + comment.size(), made);
            // NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)
            if (parsed.ec != std::errc{} || made >= cutoff) continue;
            static_cast<void>(conn.exec(std::format("DROP SCHEMA IF EXISTS {} CASCADE", row.cells[0].text)));
        }
    }

    const Access* access_;
    store::PgConn conn_;
    std::string name_;
    std::string drop_sql_;
};

} // namespace game::test::billing_pg
