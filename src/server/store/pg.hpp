#pragma once
// Lớp mỏng trên libpq. Không exception. Một kết nối, một luồng: auth và store mỗi bên giữ một
// kết nối vì vòng xử lý của chúng là một luồng. Mật khẩu chỉ đi vào PQconnectdbParams, không vào
// chuỗi lệnh và không vào log.

#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::store {

struct PgLogin {
    std::string host;
    std::string port;
    std::string dbname;
    std::string user;
    std::string password;
};

struct PgCell {
    bool null = false;
    std::string text;
};

struct PgRow {
    std::vector<PgCell> cells;
};

struct PgExec {
    bool ok = false;
    std::string sqlstate;
    std::string message;
    std::vector<PgRow> rows;
    int affected = 0;
};

class PgConn {
public:
    PgConn() = default;
    ~PgConn();
    PgConn(PgConn&& other) noexcept;
    PgConn& operator=(PgConn&& other) noexcept;
    PgConn(const PgConn&) = delete;
    PgConn& operator=(const PgConn&) = delete;

    [[nodiscard]] static std::optional<PgConn> open(const PgLogin& login, std::string& error);

    [[nodiscard]] bool is_open() const noexcept;

    // params rỗng là câu không tham số. Phần tử rỗng (optional rỗng) là NULL.
    [[nodiscard]] PgExec exec(std::string_view sql, std::span<const std::optional<std::string>> params);

    [[nodiscard]] PgExec exec(std::string_view sql);

    // Nhiều câu trong một chuỗi, cho tệp migration. exec() chỉ nhận một câu vì dùng tham số.
    [[nodiscard]] PgExec script(std::string_view sql);

private:
    struct Native;

    std::unique_ptr<Native> native_;
};

// Áp các tệp NNN_*.sql theo thứ tự tên. Tệp đã có số trong schema_version thì bỏ qua.
// Tệp SQL tự BEGIN/COMMIT. Lỗi thì ROLLBACK và error nhận câu của PostgreSQL, không có mật khẩu.
[[nodiscard]] bool migrate(PgConn& conn, const std::filesystem::path& dir, std::string& error);

[[nodiscard]] std::string pg_i64(std::int64_t value);

} // namespace game::store
