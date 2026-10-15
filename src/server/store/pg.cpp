#include "store/pg.hpp"

#include "io/file.hpp"

#include <charconv>
#include <libpq-fe.h>

#include <algorithm>
#include <array>
#include <print>
#include <utility>

namespace game::store {
namespace {

constexpr int kParamCap = 32;

// Giữ PGresult cho tới hết phạm vi (chỉ from_result dùng), nên không cần chuyển quyền sở hữu.
struct Result {
    PGresult* raw;

    explicit Result(PGresult* handle) noexcept : raw(handle) {}
    ~Result() {
        if (raw != nullptr) PQclear(raw);
    }
    Result(const Result&) = delete;
    Result& operator=(const Result&) = delete;
};

[[nodiscard]] std::string trimmed(const char* text) {
    if (text == nullptr) return {};
    std::string out{text};
    while (!out.empty() && (out.back() == '\n' || out.back() == '\r'))
        out.pop_back();
    return out;
}

[[nodiscard]] PgExec from_result(PGresult* raw) {
    Result held{raw};
    PgExec exec;
    if (held.raw == nullptr) {
        exec.message = "libpq không trả kết quả";
        return exec;
    }
    const ExecStatusType status = PQresultStatus(held.raw);
    const bool tuples = status == PGRES_TUPLES_OK;
    const bool command = status == PGRES_COMMAND_OK;
    exec.ok = tuples || command;
    if (const char* state = PQresultErrorField(held.raw, PG_DIAG_SQLSTATE)) exec.sqlstate = state;
    if (!exec.ok) {
        exec.message = trimmed(PQresultErrorMessage(held.raw));
        return exec;
    }
    if (command) {
        const char* count = PQcmdTuples(held.raw);
        if (count != nullptr && count[0] != '\0') {
            int value = 0;
            const auto parsed = std::from_chars(count, count + std::char_traits<char>::length(count), value);
            if (parsed.ec == std::errc{}) exec.affected = value;
        }
        return exec;
    }
    const int rows = PQntuples(held.raw);
    const int cols = PQnfields(held.raw);
    exec.rows.reserve(static_cast<std::size_t>(rows));
    for (int row = 0; row < rows; ++row) {
        PgRow line;
        line.cells.reserve(static_cast<std::size_t>(cols));
        for (int col = 0; col < cols; ++col) {
            PgCell cell;
            if (PQgetisnull(held.raw, row, col) == 1) {
                cell.null = true;
            } else {
                cell.text = PQgetvalue(held.raw, row, col);
            }
            line.cells.push_back(std::move(cell));
        }
        exec.rows.push_back(std::move(line));
    }
    return exec;
}

[[nodiscard]] int leading_number(std::string_view name) noexcept {
    int value = 0;
    if (name.empty() || name.front() < '0' || name.front() > '9') return 0;
    const auto parsed = std::from_chars(name.data(), name.data() + name.size(), value);
    if (parsed.ec != std::errc{}) return 0;
    return value;
}

} // namespace

struct PgConn::Native {
    PGconn* raw = nullptr;

    ~Native() {
        if (raw != nullptr) PQfinish(raw);
    }
};

PgConn::~PgConn() = default;

PgConn::PgConn(PgConn&& other) noexcept = default;

PgConn& PgConn::operator=(PgConn&& other) noexcept = default;

std::optional<PgConn> PgConn::open(const PgLogin& login, std::string& error) {
    const char* keys[] = {
        "host", "port", "dbname", "user", "password", "connect_timeout", "sslmode", "client_encoding", nullptr};
    const char* values[] = {login.host.c_str(), login.port.c_str(), login.dbname.c_str(), login.user.c_str(),
        login.password.c_str(), "5", "disable", "UTF8", nullptr};
    PGconn* raw = PQconnectdbParams(keys, values, 0);
    if (raw == nullptr) {
        error = "hết bộ nhớ khi nối database";
        return std::nullopt;
    }
    if (PQstatus(raw) != CONNECTION_OK) {
        error = trimmed(PQerrorMessage(raw));
        PQfinish(raw);
        return std::nullopt;
    }
    PgConn conn;
    conn.native_ = std::make_unique<Native>();
    conn.native_->raw = raw;
    return conn;
}

bool PgConn::is_open() const noexcept {
    return native_ != nullptr && native_->raw != nullptr && PQstatus(native_->raw) == CONNECTION_OK;
}

PgExec PgConn::exec(std::string_view sql, std::span<const std::optional<std::string>> params) {
    PgExec failed;
    if (!is_open()) {
        failed.message = "mất kết nối database";
        return failed;
    }
    if (params.size() > kParamCap) {
        failed.message = "quá nhiều tham số";
        std::println(stderr, "db: {}", failed.message);
        return failed;
    }
    std::array<const char*, kParamCap> values{};
    std::array<int, kParamCap> lengths{};
    const int count = static_cast<int>(params.size());
    for (int index = 0; index < count; ++index) {
        const std::optional<std::string>& param = params[static_cast<std::size_t>(index)];
        const bool present = param.has_value();
        values[static_cast<std::size_t>(index)] = present ? param->data() : nullptr;
        lengths[static_cast<std::size_t>(index)] = present ? static_cast<int>(param->size()) : 0;
        if (present && param->empty()) values[static_cast<std::size_t>(index)] = "";
    }
    const std::string statement{sql};
    const char* const* passed = count == 0 ? nullptr : values.data();
    const int* sized = count == 0 ? nullptr : lengths.data();
    return from_result(PQexecParams(native_->raw, statement.c_str(), count, nullptr, passed, sized, nullptr, 0));
}

PgExec PgConn::exec(std::string_view sql) {
    return exec(sql, {});
}

PgExec PgConn::script(std::string_view sql) {
    PgExec failed;
    if (!is_open()) {
        failed.message = "mất kết nối database";
        return failed;
    }
    const std::string statement{sql};
    return from_result(PQexec(native_->raw, statement.c_str()));
}

std::string pg_i64(std::int64_t value) {
    std::array<char, 32> buffer{};
    const auto written = std::to_chars(buffer.data(), buffer.data() + buffer.size(), value);
    if (written.ec != std::errc{}) return {};
    return std::string{buffer.data(), written.ptr};
}

bool migrate(PgConn& conn, const std::filesystem::path& dir, std::string& error) {
    std::error_code io_error;
    std::filesystem::directory_iterator it{dir, io_error};
    const std::filesystem::directory_iterator end;
    std::vector<std::filesystem::path> files;
    while (!io_error && it != end) {
        const std::string name = io::utf8_of(it->path().filename());
        if (name.ends_with(".sql")) files.push_back(it->path());
        it.increment(io_error);
    }
    if (io_error) {
        error = "không đọc được thư mục sql";
        return false;
    }
    // Sắp theo số đầu tên (1 < 2 < 10), rồi theo tên khi cùng số: sắp từ điển thuần đặt
    // "10_x.sql" trước "2_x.sql" khi qua file 10 không zero-pad. Hiện 001..005 nên thứ tự không đổi.
    std::ranges::sort(files, [](const std::filesystem::path& left, const std::filesystem::path& right) {
        const int first = leading_number(io::utf8_of(left.filename()));
        const int second = leading_number(io::utf8_of(right.filename()));
        if (first != second) return first < second;
        return left < right;
    });
    for (const std::filesystem::path& file : files) {
        const int version = leading_number(io::utf8_of(file.filename()));
        if (version <= 0) continue;
        const std::optional<std::string> wanted = pg_i64(version);
        const PgExec seen = conn.exec("SELECT version FROM schema_version WHERE version = $1", std::span{&wanted, 1});
        const bool missing_table = !seen.ok && seen.sqlstate == "42P01";
        if (seen.ok && !seen.rows.empty()) continue;
        if (!seen.ok && !missing_table) {
            error = seen.message;
            return false;
        }
        const io::TextResult script = io::read_text(file);
        if (!script) {
            error = "không đọc được tệp sql";
            return false;
        }
        const PgExec applied = conn.script(*script);
        if (!applied.ok) {
            static_cast<void>(conn.exec("ROLLBACK"));
            error = applied.message;
            return false;
        }
    }
    return true;
}

} // namespace game::store
