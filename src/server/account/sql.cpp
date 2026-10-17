/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/sql.cpp
 *  PHÂN HỆ   : Server / Account / Sql
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bản PostgreSQL của sổ tài khoản (AuthDb) và sổ nhân vật (GameDb).
 *  - Khối nhị phân của trạng thái chơi đi vào và ra database bằng chữ hex vì
 *    thư viện chỉ có tham số chữ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "account/sql.hpp"

#include "account/book.hpp"
#include "account/play.hpp"
#include "account/rules.hpp"
#include "account/starter.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "store/pg.hpp"

#include <array>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::account {
namespace {

using game::store::pg_i64;
using game::store::PgConn;
using game::store::PgExec;

[[nodiscard]] TicketResult fail_ticket(protocol::ErrorCode code) {
    TicketResult result;
    result.code = code;
    return result;
}

[[nodiscard]] ListResult fail_list(protocol::ErrorCode code) {
    ListResult result;
    result.code = code;
    return result;
}

struct Args {
    std::vector<std::optional<std::string>> values;

    void text(std::string value) { values.emplace_back(std::move(value)); }
    void i64(std::int64_t value) { values.emplace_back(pg_i64(value)); }
    void null() { values.emplace_back(); }

    [[nodiscard]] std::span<const std::optional<std::string>> span() const { return values; }
};

struct Tx {
    PgConn* conn;
    bool open = false;

    explicit Tx(PgConn& connection) : conn(&connection) {}
    ~Tx() {
        if (open) static_cast<void>(conn->exec("ROLLBACK"));
    }
    Tx(const Tx&) = delete;
    Tx& operator=(const Tx&) = delete;
    Tx(Tx&&) = delete;
    Tx& operator=(Tx&&) = delete;

    [[nodiscard]] bool begin() {
        const PgExec started = conn->exec("BEGIN");
        open = started.ok;
        if (!open) return false;
        const PgExec timeout = conn->exec("SET LOCAL statement_timeout = '5s'");
        if (timeout.ok) return true;
        static_cast<void>(conn->exec("ROLLBACK"));
        open = false;
        return false;
    }

    [[nodiscard]] bool commit() {
        if (!open) return false;
        const PgExec done = conn->exec("COMMIT");
        open = false;
        return done.ok;
    }
};

[[nodiscard]] bool unique_hit(const PgExec& exec) noexcept {
    return exec.sqlstate == "23505";
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): dòng rồi cột như PgExec::rows, mọi nơi gọi cùng thứ tự (HP-07)
[[nodiscard]] const std::string* cell(const PgExec& exec, std::size_t row, std::size_t col) {
    if (row >= exec.rows.size()) return nullptr;
    const store::PgRow& line = exec.rows[row];
    if (col >= line.cells.size()) return nullptr;
    if (line.cells[col].null) return nullptr;
    return &line.cells[col].text;
}

[[nodiscard]] std::optional<std::int64_t> as_i64(std::string_view text) {
    std::int64_t value = 0;
    const char* const last = std::to_address(text.end());
    const auto parsed = std::from_chars(std::to_address(text.begin()), last, value);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::nullopt;
    return value;
}

// Khối nhị phân đi vào/ra PostgreSQL bằng chữ hex (`\\x...` khi ghi, encode(.., 'hex') khi đọc): thư viện chỉ có tham số chữ.
[[nodiscard]] std::string hex_literal(const std::vector<std::byte>& blob) {
    constexpr std::string_view kDigits = "0123456789abcdef";
    std::string text = "\\x";
    text.reserve(2 + (blob.size() * 2));
    for (const std::byte value : blob) {
        const auto byte = std::to_integer<unsigned>(value);
        text.push_back(kDigits[byte >> 4U]);
        text.push_back(kDigits[byte & 0xFU]);
    }
    return text;
}

[[nodiscard]] std::optional<std::vector<std::byte>> from_hex(std::string_view text) {
    if (text.size() % 2 != 0) return std::nullopt;
    const auto digit = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        return -1;
    };
    std::vector<std::byte> blob;
    blob.reserve(text.size() / 2);
    for (std::size_t at = 0; at < text.size(); at += 2) {
        const int high = digit(text[at]);
        const int low = digit(text[at + 1]);
        if (high < 0 || low < 0) return std::nullopt;
        blob.push_back(static_cast<std::byte>((high << 4) | low));
    }
    return blob;
}

[[nodiscard]] bool as_flag(std::string_view text) noexcept {
    return text == "t" || text == "true" || text == "1";
}

[[nodiscard]] bool lock_name(PgConn& conn, std::string_view fold) {
    Args args;
    args.text(std::string{fold});
    const PgExec locked = conn.exec("SELECT pg_advisory_xact_lock(hashtextextended($1, 0::bigint))", args.span());
    return locked.ok;
}

void burn_dummy(const AuthOptions& options, std::string_view password) {
    if (options.dummy_hash.empty()) return;
    static_cast<void>(secure::verify_password(options.dummy_hash, password));
}

[[nodiscard]] std::optional<int> failure_count_ip(PgConn& conn, std::string_view ip) {
    Args args;
    args.text(std::string{ip});
    args.i64(kFailWindow.count());
    const PgExec counted =
        conn.exec("SELECT count(*)::text FROM login_attempt "
                  "WHERE ip = $1::inet AND ok = false AND at > now() - make_interval(secs => $2::int)",
            args.span());
    const std::string* text = cell(counted, 0, 0);
    if (!counted.ok || text == nullptr) return std::nullopt;
    const std::optional<std::int64_t> value = as_i64(*text);
    if (!value || *value < 0 || *value > 1000000) return std::nullopt;
    return static_cast<int>(*value);
}

[[nodiscard]] std::optional<int> failure_count(PgConn& conn, std::string_view fold) {
    Args args;
    args.text(std::string{fold});
    args.i64(kFailWindow.count());
    const PgExec counted =
        conn.exec("SELECT count(*)::text FROM login_attempt "
                  "WHERE name_fold = $1 AND ok = false AND at > now() - make_interval(secs => $2::int)",
            args.span());
    const std::string* text = cell(counted, 0, 0);
    if (!counted.ok || text == nullptr) return std::nullopt;
    const std::optional<std::int64_t> value = as_i64(*text);
    if (!value || *value < 0 || *value > 1000000) return std::nullopt;
    return static_cast<int>(*value);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên đã gấp rồi ip, như cột của login_attempt (HP-07)
[[nodiscard]] bool note_attempt(PgConn& conn, std::optional<std::int64_t> account, std::string_view fold,
    std::string_view ip, bool ok) {
    Args args;
    if (account) args.i64(*account);
    if (!account) args.null();
    args.text(std::string{fold});
    args.text(std::string{ip});
    args.text(ok ? "true" : "false");
    const PgExec wrote =
        conn.exec("INSERT INTO login_attempt (account_id, name_fold, ip, ok) VALUES ($1, $2, $3::inet, $4)",
            args.span());
    return wrote.ok;
}

struct Loaded {
    bool failed = false;
    bool found = false;
    bool disabled = false;
    std::int64_t id = 0;
    std::string name{};
    std::string password_hash{};
};

[[nodiscard]] Loaded load_account(PgConn& conn, std::string_view fold) {
    Args args;
    args.text(std::string{fold});
    const PgExec found = conn.exec(
        "SELECT id::text, name, password_hash, (disabled_at IS NOT NULL)::text FROM account WHERE name_fold = $1",
        args.span());
    Loaded loaded;
    if (!found.ok) {
        loaded.failed = true;
        return loaded;
    }
    if (found.rows.empty()) return loaded;
    const std::string* id = cell(found, 0, 0);
    const std::string* name = cell(found, 0, 1);
    const std::string* hash = cell(found, 0, 2);
    const std::string* disabled = cell(found, 0, 3);
    const std::optional<std::int64_t> parsed = id == nullptr ? std::nullopt : as_i64(*id);
    if (!parsed || name == nullptr || hash == nullptr || disabled == nullptr) {
        loaded.failed = true;
        return loaded;
    }
    loaded.found = true;
    loaded.id = *parsed;
    loaded.name = *name;
    loaded.password_hash = *hash;
    loaded.disabled = as_flag(*disabled);
    if (!loaded.disabled) {
        Args ban;
        ban.i64(loaded.id);
        const PgExec banned =
            conn.exec("SELECT 1 FROM ban WHERE account_id = $1 AND (until_at IS NULL OR until_at > now()) LIMIT 1",
                ban.span());
        // Không đọc được bảng cấm thì không cho vào: lỗi database không được mở cửa cho tài khoản bị cấm.
        if (!banned.ok) {
            secure::wipe_bytes(std::as_writable_bytes(std::span{
                loaded.password_hash.data(), loaded.password_hash.size()}));
            return Loaded{.failed = true};
        }
        loaded.disabled = !banned.rows.empty();
    }
    return loaded;
}

[[nodiscard]] std::optional<std::string> issue_ticket(PgConn& conn, std::int64_t account, int ttl_seconds) {
    std::array<std::byte, kTicketRaw> raw{};
    if (!secure::fill_random(raw)) return std::nullopt;
    std::array<std::byte, 32> digest{};
    const bool hashed = secure::sha256(raw, digest);
    std::string hex = secure::hex_encode(raw);
    const std::string stored = secure::hex_encode(digest);
    secure::wipe_bytes(raw);
    secure::wipe_bytes(digest);
    if (!hashed) return std::nullopt;
    Args args;
    args.i64(account);
    args.text(stored);
    args.i64(ttl_seconds);
    const PgExec wrote = conn.exec("INSERT INTO ticket (account_id, token_hash, expires_at) "
                                   "VALUES ($1, $2, now() + make_interval(secs => $3::int))",
        args.span());
    static_cast<void>(conn.exec("DELETE FROM ticket WHERE expires_at < now() - interval '1 day'"));
    if (!wrote.ok) return std::nullopt;
    Args audit;
    audit.i64(account);
    const PgExec noted =
        conn.exec("INSERT INTO audit_event (account_id, kind, detail) VALUES ($1, 'ticket', '')", audit.span());
    if (!noted.ok) return std::nullopt;
    return hex;
}

[[nodiscard]] std::optional<std::int64_t> insert_account(PgConn& conn, const AuthOptions& options,
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên, tên đã gấp, mật khẩu như cột của account (HP-07)
    std::string_view name, std::string_view fold, std::string_view password) {
    const std::size_t mem_bytes = static_cast<std::size_t>(options.mem_limit_kib) * 1024U;
    const secure::PasswordPolicy policy{
        .ops = static_cast<std::uint64_t>(options.ops_limit),
        .mem_bytes = mem_bytes,
    };
    std::string hash;
    if (!secure::hash_password(password, policy, hash)) return std::nullopt;
    Args args;
    args.text(std::string{name});
    args.text(std::string{fold});
    args.text(hash);
    args.i64(options.ops_limit);
    args.i64(options.mem_limit_kib);
    args.i64(options.gift_points);
    secure::wipe_bytes(std::as_writable_bytes(std::span{hash.data(), hash.size()}));
    hash.clear();
    const PgExec wrote =
        conn.exec("INSERT INTO account (name, name_fold, password_hash, ops_limit, mem_limit_kib, gift_points) "
                  "VALUES ($1, $2, $3, $4, $5, $6) RETURNING id::text",
            args.span());
    if (unique_hit(wrote)) return std::int64_t{-1};
    const std::string* id = cell(wrote, 0, 0);
    if (!wrote.ok || id == nullptr) return std::nullopt;
    return as_i64(*id);
}

[[nodiscard]] bool fits_wire(std::int64_t value, std::int64_t max) noexcept {
    return value >= 0 && value <= max;
}

// Ảnh chân dung và bộ đồ tân thủ nằm ở hai cột liền nhau bắt đầu từ col (migration 003).
[[nodiscard]] bool read_look(const PgExec& exec, std::size_t row, std::size_t col,
    protocol::CharacterSummary& summary) {
    const std::string* portrait = cell(exec, row, col);
    const std::string* set = cell(exec, row, col + 1);
    if (portrait == nullptr || set == nullptr) return false;
    const std::optional<std::int64_t> portrait_value = as_i64(*portrait);
    const std::optional<std::int64_t> set_value = as_i64(*set);
    if (!portrait_value || !set_value) return false;
    const bool is_fit = fits_wire(*portrait_value, 65535) && fits_wire(*set_value, 65535);
    if (!is_fit) return false;
    summary.portrait = static_cast<std::uint16_t>(*portrait_value);
    summary.equip_set = static_cast<std::uint16_t>(*set_value);
    return true;
}

[[nodiscard]] std::optional<protocol::CharacterSummary> read_summary(const PgExec& exec,
    std::size_t row, std::size_t look_col) {
    const std::string* id = cell(exec, row, 0);
    const std::string* name = cell(exec, row, 1);
    const std::string* level = cell(exec, row, 2);
    const std::string* gender = cell(exec, row, 3);
    const std::string* face = cell(exec, row, 4);
    const std::string* hair = cell(exec, row, 5);
    const std::string* school = cell(exec, row, 6);
    const std::string* scene = cell(exec, row, 7);
    if (id == nullptr || name == nullptr || level == nullptr || gender == nullptr) return std::nullopt;
    if (face == nullptr || hair == nullptr || school == nullptr || scene == nullptr) return std::nullopt;
    const std::optional<std::int64_t> id_value = as_i64(*id);
    const std::optional<std::int64_t> level_value = as_i64(*level);
    const std::optional<std::int64_t> gender_value = as_i64(*gender);
    const std::optional<std::int64_t> face_value = as_i64(*face);
    const std::optional<std::int64_t> hair_value = as_i64(*hair);
    const std::optional<std::int64_t> school_value = as_i64(*school);
    const std::optional<std::int64_t> scene_value = as_i64(*scene);
    if (!id_value || !level_value || !gender_value || !face_value || !hair_value || !school_value || !scene_value) {
        return std::nullopt;
    }
    if (!fits_wire(*level_value, 65535) || !fits_wire(*face_value, 65535) || !fits_wire(*hair_value, 65535)) {
        return std::nullopt;
    }
    if (!fits_wire(*school_value, 255) || !fits_wire(*scene_value, 65535)) return std::nullopt;
    if (*gender_value != 1 && *gender_value != 2) return std::nullopt;
    protocol::CharacterSummary summary;
    summary.id = static_cast<std::uint64_t>(*id_value);
    summary.name = *name;
    summary.level = static_cast<std::uint16_t>(*level_value);
    summary.gender = static_cast<protocol::Gender>(*gender_value);
    summary.face = static_cast<std::uint16_t>(*face_value);
    summary.hair = static_cast<std::uint16_t>(*hair_value);
    summary.school = static_cast<std::uint8_t>(*school_value);
    summary.scene = static_cast<std::uint16_t>(*scene_value);
    if (!read_look(exec, row, look_col, summary)) return std::nullopt;
    return summary;
}

// Cột 0..7 của summary, rồi ảnh chân dung và bộ đồ ở cột 8 và 9.
constexpr std::size_t kListLookCol = 8;

constexpr std::string_view kListSql =
    "SELECT id::text, name, level::text, gender::text, face::text, hair::text, school::text, "
    "scene::text, portrait::text, equip_set::text "
    "FROM player WHERE account_id = $1 AND deleted_at IS NULL ORDER BY id LIMIT 8";

[[nodiscard]] ListResult list_players(PgConn& conn, std::uint64_t account) {
    Args args;
    args.i64(static_cast<std::int64_t>(account));
    const PgExec found = conn.exec(kListSql, args.span());
    if (!found.ok) return ListResult{};
    ListResult result;
    result.ok = true;
    result.account = account;
    for (std::size_t row = 0; row < found.rows.size(); ++row) {
        const auto shown = read_summary(found, row, kListLookCol);
        if (!shown) return ListResult{};
        result.characters.push_back(*shown);
    }
    return result;
}

// Số nhân vật còn sống của tài khoản và id này có nằm trong số đó không (xoá nhân vật).
struct Census {
    int live = 0;
    bool owned = false;
};

constexpr std::int64_t kCensusMax = 1'000'000;

constexpr std::string_view kCensusSql =
    "SELECT count(*)::text, (count(*) FILTER (WHERE id = $2))::text "
    "FROM player WHERE account_id = $1 AND deleted_at IS NULL";

constexpr std::string_view kRemoveSql =
    "UPDATE player SET deleted_at = now() WHERE id = $1 AND account_id = $2 AND deleted_at IS NULL";

[[nodiscard]] std::optional<std::int64_t> number_at(const PgExec& found, std::size_t col) {
    const std::string* text = cell(found, 0, col);
    if (text == nullptr) return std::nullopt;
    return as_i64(*text);
}

[[nodiscard]] std::optional<Census> census_of(PgConn& conn, std::uint64_t who, std::uint64_t id) {
    Args args;
    args.i64(static_cast<std::int64_t>(who));
    args.i64(static_cast<std::int64_t>(id));
    const PgExec found = conn.exec(kCensusSql, args.span());
    if (!found.ok) return std::nullopt;
    const std::optional<std::int64_t> live = number_at(found, 0);
    const std::optional<std::int64_t> hit = number_at(found, 1);
    if (!live || !hit) return std::nullopt;
    const bool is_sane = *live >= 0 && *live <= kCensusMax;
    if (!is_sane) return std::nullopt;
    return Census{.live = static_cast<int>(*live), .owned = *hit > 0};
}

[[nodiscard]] bool grant_starter(PgConn& conn, std::int64_t player) {
    std::int64_t slot = 0;
    for (const auto skill : starter::kSkills) {
        Args args;
        args.i64(player);
        args.i64(slot++);
        args.i64(skill);
        const PgExec wrote =
            conn.exec("INSERT INTO player_skill (player_id, slot, skill_id) VALUES ($1, $2, $3)", args.span());
        if (!wrote.ok) return false;
    }
    for (const starter::LifeSkill& skill : starter::kLifeSkills) {
        Args args;
        args.i64(player);
        args.i64(skill.id);
        args.i64(skill.level);
        args.i64(skill.exp);
        const PgExec wrote =
            conn.exec("INSERT INTO player_life_skill (player_id, skill_id, level, exp) VALUES ($1, $2, $3, $4)",
                args.span());
        if (!wrote.ok) return false;
    }
    for (const std::int64_t recipe : starter::kRecipes) {
        Args args;
        args.i64(player);
        args.i64(recipe);
        const PgExec wrote = conn.exec("INSERT INTO player_recipe (player_id, recipe_id) VALUES ($1, $2)", args.span());
        if (!wrote.ok) return false;
    }
    for (const starter::Setting& setting : starter::kSettings) {
        Args args;
        args.i64(player);
        args.i64(setting.index);
        args.i64(setting.kind);
        args.i64(setting.data);
        const PgExec wrote =
            conn.exec("INSERT INTO player_setting (player_id, slot_index, kind, data) VALUES ($1, $2, $3, $4)",
                args.span());
        if (!wrote.ok) return false;
    }
    return true;
}

[[nodiscard]] std::string format_double(double value) {
    std::array<char, 64> buffer{};
    const auto written =
        std::to_chars(std::to_address(buffer.begin()), std::to_address(buffer.end()), value, std::chars_format::general);
    if (written.ec != std::errc{}) return "0";
    return std::string{std::to_address(buffer.begin()), written.ptr};
}

} // namespace

AuthDb::AuthDb(PgConn& conn, AuthOptions options) : conn_(&conn), options_(std::move(options)) {}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên, mật khẩu, ip như Op::kCreateAccount trên dây (HP-07)
TicketResult AuthDb::create_account(std::string_view name, std::string_view password, std::string_view ip) {
    if (!ipv4_ok(ip)) return fail_ticket(protocol::ErrorCode::kBadCredentials);
    const NameFault fault = account_fault(name, password);
    const std::string fold = fold_ascii(name);
    const std::string ip_key = std::string("ip:") + std::string{ip};
    Tx tx{*conn_};
    if (!tx.begin() || !lock_name(*conn_, ip_key) || !lock_name(*conn_, fold)) return {};
    const std::optional<int> by_ip = failure_count_ip(*conn_, ip);
    if (!by_ip) return {};
    if (*by_ip >= kIpFailLimit) return fail_ticket(protocol::ErrorCode::kRateLimited);
    if (fault != NameFault::kOk) {
        if (!note_attempt(*conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(fault_code(fault));
    }
    Loaded existing = load_account(*conn_, fold);
    secure::wipe_bytes(std::as_writable_bytes(std::span{existing.password_hash.data(), existing.password_hash.size()}));
    if (existing.failed) return {};
    if (existing.found) {
        // Tên đã có trả cùng mã và cùng thời gian băm như đăng nhập sai: không dò được tài khoản nào
        // tồn tại. Vẫn là một lần thử hỏng của IP này, nên tổng số lần dò có trần kIpFailLimit.
        burn_dummy(options_, password);
        if (!note_attempt(*conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    const std::optional<std::int64_t> id = insert_account(*conn_, options_, name, fold, password);
    if (!id) return {};
    if (*id < 0) {
        // Đua với một lệnh tạo khác cùng tên: cùng câu trả lời như tên đã có (đã băm một lần).
        Tx again{*conn_};
        tx.open = false;
        static_cast<void>(conn_->exec("ROLLBACK"));
        if (!again.begin() || !note_attempt(*conn_, std::nullopt, fold, ip, false) || !again.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    if (!note_attempt(*conn_, *id, fold, ip, true)) return {};
    const std::optional<std::string> hex = issue_ticket(*conn_, *id, options_.ttl_seconds);
    if (!hex || !tx.commit()) return {};
    TicketResult result;
    result.ok = true;
    result.hex = *hex;
    return result;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên, mật khẩu, ip như Op::kSignIn trên dây (HP-07)
TicketResult AuthDb::sign_in(std::string_view name, std::string_view password, std::string_view ip) {
    if (!sign_in_shape_ok(name, password) || !ipv4_ok(ip)) {
        burn_dummy(options_, password);
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    const std::string fold = fold_ascii(name);
    const std::string ip_key = std::string("ip:") + std::string{ip};
    Tx tx{*conn_};
    if (!tx.begin() || !lock_name(*conn_, ip_key) || !lock_name(*conn_, fold)) return {};
    const std::optional<int> failures = failure_count(*conn_, fold);
    const std::optional<int> by_ip = failure_count_ip(*conn_, ip);
    if (!failures || !by_ip) return {};
    if (*failures >= kFailLimit || *by_ip >= kIpFailLimit) return fail_ticket(protocol::ErrorCode::kRateLimited);
    Loaded loaded = load_account(*conn_, fold);
    if (loaded.failed) return {};
    bool matched = false;
    if (loaded.found) {
        matched = secure::verify_password(loaded.password_hash, password);
        secure::wipe_bytes(std::as_writable_bytes(std::span{loaded.password_hash.data(), loaded.password_hash.size()}));
        loaded.password_hash.clear();
    }
    const SignStep step = sign_step(loaded.found, loaded.disabled, matched, *failures, options_.auto_register);
    if (step == SignStep::kCreate) {
        const NameFault fault = account_fault(name, password);
        if (fault != NameFault::kOk) {
            burn_dummy(options_, password);
            if (!note_attempt(*conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
            return fail_ticket(protocol::ErrorCode::kBadCredentials);
        }
        const std::optional<std::int64_t> id = insert_account(*conn_, options_, name, fold, password);
        if (!id) return {};
        if (*id < 0) {
            if (!note_attempt(*conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
            return fail_ticket(protocol::ErrorCode::kBadCredentials);
        }
        loaded.id = *id;
        loaded.found = true;
    }
    if (step != SignStep::kOk && step != SignStep::kCreate) {
        if (!loaded.found) burn_dummy(options_, password);
        const std::optional<std::int64_t> who = loaded.found ? std::optional<std::int64_t>{loaded.id} : std::nullopt;
        if (!note_attempt(*conn_, who, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    if (!note_attempt(*conn_, loaded.id, fold, ip, true)) return {};
    const std::optional<std::string> hex = issue_ticket(*conn_, loaded.id, options_.ttl_seconds);
    if (!hex || !tx.commit()) return {};
    TicketResult result;
    result.ok = true;
    result.hex = *hex;
    return result;
}

RedeemResult AuthDb::redeem(std::string_view ticket_hex) {
    std::array<std::byte, kTicketRaw> raw{};
    if (!token_bytes(ticket_hex, raw)) {
        RedeemResult result;
        result.code = protocol::ErrorCode::kBadCredentials;
        return result;
    }
    std::array<std::byte, 32> digest{};
    if (!secure::sha256(raw, digest)) return {};
    const std::string stored = secure::hex_encode(digest);
    secure::wipe_bytes(raw);
    secure::wipe_bytes(digest);
    Tx tx{*conn_};
    if (!tx.begin()) return {};
    Args args;
    args.text(stored);
    const PgExec used =
        conn_->exec("UPDATE ticket SET used_at = now() WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now() "
                   "RETURNING account_id::text",
            args.span());
    if (!used.ok) return {};
    if (used.rows.empty()) {
        const PgExec prior =
            conn_->exec("SELECT (used_at IS NOT NULL OR expires_at <= now())::text FROM ticket WHERE token_hash = $1",
                args.span());
        RedeemResult result;
        result.code = prior.ok && !prior.rows.empty() ? protocol::ErrorCode::kSessionExpired
                                                      : protocol::ErrorCode::kBadCredentials;
        return result;
    }
    const std::string* id_text = cell(used, 0, 0);
    const std::optional<std::int64_t> id = id_text == nullptr ? std::nullopt : as_i64(*id_text);
    if (!id) return {};
    Args who;
    who.i64(*id);
    const PgExec account = conn_->exec(
        "SELECT name, (disabled_at IS NOT NULL OR EXISTS (SELECT 1 FROM ban WHERE ban.account_id = account.id "
        "AND (ban.until_at IS NULL OR ban.until_at > now())))::text FROM account WHERE id = $1",
        who.span());
    const std::string* name = cell(account, 0, 0);
    const std::string* disabled = cell(account, 0, 1);
    if (!account.ok || name == nullptr || disabled == nullptr) return {};
    if (as_flag(*disabled)) {
        RedeemResult result;
        result.code = protocol::ErrorCode::kBadCredentials;
        return result;
    }
    if (!tx.commit()) return {};
    RedeemResult result;
    result.ok = true;
    result.account = static_cast<std::uint64_t>(*id);
    result.name = *name;
    return result;
}

EnterResult AuthDb::standing(std::uint64_t account) {
    EnterResult result;
    result.code = protocol::ErrorCode::kBusy;
    Args who;
    who.i64(static_cast<std::int64_t>(account));
    const PgExec found =
        conn_->exec("SELECT (disabled_at IS NOT NULL OR EXISTS (SELECT 1 FROM ban WHERE ban.account_id = account.id "
                   "AND (ban.until_at IS NULL OR ban.until_at > now())))::text FROM account WHERE id = $1",
            who.span());
    if (!found.ok) return result;
    const std::string* disabled = cell(found, 0, 0);
    if (disabled == nullptr) {
        result.code = protocol::ErrorCode::kNotAuthenticated;
        return result;
    }
    if (as_flag(*disabled)) {
        result.code = protocol::ErrorCode::kBadCredentials;
        return result;
    }
    result.ok = true;
    return result;
}

GameDb::GameDb(PgConn& conn, CharacterPolicy policy) : conn_(&conn), policy_(std::move(policy)) {}

ListResult GameDb::list(std::uint64_t account) {
    return list_players(*conn_, account);
}

constexpr std::string_view kInsertSql =
    "INSERT INTO player (account_id, name, name_fold, gender, face, hair, school, level, exp, "
    "scene, "
    "position_x, position_z, hp, mp, camp, money, vigor, max_vigor, energy, max_energy, strength, "
    "spirit, constitution, intellect, dexterity, actual_age, motto, portrait, equip_set) "
    "VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,"
    "$24,$25,$26,$27,$28,$29) RETURNING id::text";

ListResult GameDb::create_character(std::uint64_t account, std::string_view name,
    const Look& look) {
    const bool is_fit = protocol::is_valid(look.gender) && look_ok(policy_.look, look);
    if (!is_fit) {
        ListResult result;
        result.code = protocol::ErrorCode::kBadOption;
        return result;
    }
    const std::optional<std::string> canonical = canonical_character_name(name);
    if (!canonical) return fail_list(protocol::ErrorCode::kNameInvalid);
    const std::string fold = fold_character_name(*canonical);
    Tx tx{*conn_};
    if (!tx.begin()) return {};
    Args lock;
    lock.i64(static_cast<std::int64_t>(account));
    const PgExec locked = conn_->exec("SELECT pg_advisory_xact_lock($1)", lock.span());
    if (!locked.ok) return {};
    // Khoá theo tên: chỗ giữ tên đã xoá không có chỉ mục duy nhất nào canh, phải tuần tự hoá ở đây.
    if (!lock_name(*conn_, std::string("player:") + fold)) return {};
    Args count_args;
    count_args.i64(static_cast<std::int64_t>(account));
    const PgExec counted =
        conn_->exec("SELECT count(*)::text FROM player WHERE account_id = $1 AND deleted_at IS NULL", count_args.span());
    const std::string* count_text = cell(counted, 0, 0);
    if (!counted.ok || count_text == nullptr) return {};
    const std::optional<std::int64_t> live = as_i64(*count_text);
    if (!live || *live < 0) return {};
    const int live_count = *live > 100000 ? 100000 : static_cast<int>(*live);
    Args taken_args;
    taken_args.text(fold);
    taken_args.i64(static_cast<std::int64_t>(account));
    taken_args.i64(policy_.name_reserve.count());
    // Tên đang sống của bất kỳ ai, hoặc tên tài khoản khác vừa xoá mềm còn trong hạn giữ chỗ.
    const PgExec taken =
        conn_->exec("SELECT 1 FROM player WHERE name_fold = $1 AND (deleted_at IS NULL OR "
                   "(account_id <> $2 AND deleted_at > now() - make_interval(secs => $3::int))) LIMIT 1",
            taken_args.span());
    if (!taken.ok) return {};
    const CreateStep step = create_step(character_name_ok(name), live_count, !taken.rows.empty());
    if (step != CreateStep::kOk) {
        ListResult result;
        result.code = create_code(step);
        return result;
    }
    Args insert;
    insert.i64(static_cast<std::int64_t>(account));
    insert.text(*canonical);
    insert.text(fold);
    insert.i64(static_cast<std::int64_t>(look.gender));
    insert.i64(look.face);
    insert.i64(look.hair);
    insert.i64(starter::kSchool);
    insert.i64(starter::kLevel);
    insert.i64(starter::kExp);
    insert.i64(starter::kScene);
    insert.text(format_double(starter::kPositionX));
    insert.text(format_double(starter::kPositionZ));
    insert.i64(starter::kHp);
    insert.i64(starter::kMp);
    insert.i64(starter::kCamp);
    insert.i64(starter::kMoney);
    insert.i64(starter::kVigor);
    insert.i64(starter::kMaxVigor);
    insert.i64(starter::kEnergy);
    insert.i64(starter::kMaxEnergy);
    insert.i64(starter::kStrength);
    insert.i64(starter::kSpirit);
    insert.i64(starter::kConstitution);
    insert.i64(starter::kIntellect);
    insert.i64(starter::kDexterity);
    insert.i64(starter::kActualAge);
    insert.text(std::string{starter::kMotto});
    insert.i64(look.portrait);
    insert.i64(look.equip_set);
    const PgExec wrote = conn_->exec(kInsertSql, insert.span());
    if (unique_hit(wrote)) {
        ListResult result;
        result.code = protocol::ErrorCode::kNameTaken;
        return result;
    }
    const std::string* id_text = cell(wrote, 0, 0);
    const std::optional<std::int64_t> id = id_text == nullptr ? std::nullopt : as_i64(*id_text);
    if (!wrote.ok || !id) return {};
    if (!grant_starter(*conn_, *id) || !tx.commit()) return {};
    return list_players(*conn_, account);
}

// Xoá ngay theo máy chủ gốc (G1-M D1): hết nhân vật là EMPTY, không có id này là NOT_OWNER, xoá
// xong đếm lại mà số không giảm một là INTERNAL_ERROR. Cùng khoá tài khoản với tạo nhân vật.
ListResult GameDb::remove_character(std::uint64_t account, std::uint64_t character) {
    Tx tx{*conn_};
    if (!tx.begin()) return {};
    Args lock;
    lock.i64(static_cast<std::int64_t>(account));
    const PgExec locked = conn_->exec("SELECT pg_advisory_xact_lock($1)", lock.span());
    if (!locked.ok) return {};
    const std::optional<Census> before = census_of(*conn_, account, character);
    if (!before) return {};
    const RemoveStep step = remove_step(before->live, before->owned);
    if (step != RemoveStep::kOk) return fail_list(remove_code(step));
    Args args;
    args.i64(static_cast<std::int64_t>(character));
    args.i64(static_cast<std::int64_t>(account));
    const PgExec wrote = conn_->exec(kRemoveSql, args.span());
    if (!wrote.ok) return {};
    const std::optional<Census> after = census_of(*conn_, account, character);
    if (!after) return {};
    const bool is_dropped = wrote.affected == 1 && after->live + 1 == before->live;
    if (!is_dropped) return fail_list(protocol::ErrorCode::kInternal);
    ListResult left = list_players(*conn_, account);
    if (!left.ok || !tx.commit()) return {};
    return left;
}

namespace {

// Cột 10.. của câu SELECT trong GameDb::enter. Số hỏng hay khối hex hỏng: nullopt (không cho vào thay vì đoán).
constexpr std::int64_t kInt32Max = std::numeric_limits<std::int32_t>::max();

[[nodiscard]] std::optional<PlayRecord> read_play(const PgExec& found, std::size_t row, std::uint16_t level) {
    const auto number = [&](std::size_t col) -> std::optional<std::int64_t> {
        const std::string* text = cell(found, row, col);
        return text == nullptr ? std::nullopt : as_i64(*text);
    };
    const auto blob = [&](std::size_t col) -> std::optional<std::vector<std::byte>> {
        const std::string* text = cell(found, row, col);
        return text == nullptr ? std::nullopt : from_hex(*text);
    };
    const std::optional<std::int64_t> exp = number(10);
    const std::optional<std::int64_t> money = number(11);
    const std::optional<std::int64_t> bound = number(12);
    const std::optional<std::int64_t> hp = number(13);
    const std::optional<std::int64_t> mp = number(14);
    std::optional<std::vector<std::byte>> body = blob(15);
    std::optional<std::vector<std::byte>> mission = blob(16);
    std::optional<std::vector<std::byte>> bag = blob(17);
    if (!exp || !money || !bound || !hp || !mp || !body || !mission || !bag || *exp < 0 || *money < 0 || *bound < 0 ||
        *hp < 0 || *mp < 0 || *hp > kInt32Max || *mp > kInt32Max) {
        return std::nullopt;
    }
    PlayRecord play;
    play.level = level;
    play.exp = static_cast<std::uint64_t>(*exp);
    play.money = static_cast<std::uint64_t>(*money);
    play.bound = static_cast<std::uint64_t>(*bound);
    play.hp = static_cast<std::int32_t>(*hp);
    play.mp = static_cast<std::int32_t>(*mp);
    play.body = std::move(*body);
    play.mission = std::move(*mission);
    play.bag = std::move(*bag);
    return play;
}

} // namespace

// Cột 0..7 là summary, 8..9 toạ độ, 10..17 trạng thái chơi (read_play), ảnh chân dung và bộ đồ
// ở 18.
constexpr std::size_t kEnterLookCol = 18;

constexpr std::string_view kEnterSql =
    "SELECT id::text, name, level::text, gender::text, face::text, hair::text, school::text, "
    "scene::text, round(position_x * 100)::bigint::text, round(position_z * 100)::bigint::text, "
    "exp::text, money::text, bound_coin::text, hp::text, mp::text, "
    "coalesce(encode(body, 'hex'), ''), coalesce(encode(mission, 'hex'), ''), "
    "coalesce(encode(bag, 'hex'), ''), portrait::text, equip_set::text "
    "FROM player WHERE id = $1 AND account_id = $2 AND deleted_at IS NULL";

EnterResult GameDb::enter(std::uint64_t account, std::uint64_t character) {
    Args args;
    args.i64(static_cast<std::int64_t>(character));
    args.i64(static_cast<std::int64_t>(account));
    // position_x/position_z lưu mét; gate làm việc bằng centimet nguyên.
    const PgExec found = conn_->exec(kEnterSql, args.span());
    EnterResult result;
    if (!found.ok) return result;
    if (found.rows.empty()) {
        result.code = protocol::ErrorCode::kNoSuchCharacter;
        return result;
    }
    const std::optional<protocol::CharacterSummary> summary = read_summary(found, 0, kEnterLookCol);
    const std::string* x_cm = cell(found, 0, 8);
    const std::string* z_cm = cell(found, 0, 9);
    const std::optional<std::int64_t> x_value = x_cm == nullptr ? std::nullopt : as_i64(*x_cm);
    const std::optional<std::int64_t> z_value = z_cm == nullptr ? std::nullopt : as_i64(*z_cm);
    // Hàng hỏng hay toạ độ ngoài trần: không cho vào thay vì đặt mốc bừa.
    if (!summary || !x_value || !z_value || !spot_fits(*x_value) || !spot_fits(*z_value)) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    std::optional<PlayRecord> play = read_play(found, 0, summary->level);
    if (!play) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    result.ok = true;
    result.scene = summary->scene;
    result.x_cm = static_cast<std::int32_t>(*x_value);
    result.z_cm = static_cast<std::int32_t>(*z_value);
    result.summary = *summary;
    result.play = std::move(*play);
    return result;
}

EnterResult GameDb::save_spot(const SaveSpot& spot) {
    EnterResult result;
    if (!spot_fits(spot.x_cm) || !spot_fits(spot.z_cm)) {
        result.code = protocol::ErrorCode::kMalformed;
        return result;
    }
    Args args;
    args.i64(static_cast<std::int64_t>(spot.character));
    args.i64(spot.scene);
    // Cột lưu mét (số thực); trên dây là centimet nguyên.
    args.text(std::format("{:.2f}", static_cast<double>(spot.x_cm) / 100.0));
    args.text(std::format("{:.2f}", static_cast<double>(spot.z_cm) / 100.0));
    PgExec wrote;
    if (!spot.play) {
        wrote = conn_->exec("UPDATE player SET scene = $2, position_x = $3::double precision, position_z = $4::double precision "
                           "WHERE id = $1 AND deleted_at IS NULL",
            args.span());
    } else {
        // Một câu UPDATE cho điểm đứng và trạng thái chơi: ghi nửa vời không xảy ra.
        const PlayRecord& play = *spot.play;
        args.i64(play.level);
        args.i64(static_cast<std::int64_t>(play.exp));
        args.i64(static_cast<std::int64_t>(play.money));
        args.i64(static_cast<std::int64_t>(play.bound));
        args.i64(play.hp);
        args.i64(play.mp);
        args.text(hex_literal(play.body));
        args.text(hex_literal(play.mission));
        args.text(hex_literal(play.bag));
        wrote = conn_->exec(
            "UPDATE player SET scene = $2, position_x = $3::double precision, position_z = $4::double precision, "
            "level = $5, exp = $6, money = $7, bound_coin = $8, hp = $9, mp = $10, body = $11::bytea, "
            "mission = $12::bytea, bag = $13::bytea WHERE id = $1 AND deleted_at IS NULL",
            args.span());
    }
    if (!wrote.ok) return result;
    if (wrote.affected != 1) {
        result.code = protocol::ErrorCode::kNoSuchCharacter;
        return result;
    }
    result.ok = true;
    return result;
}

} // namespace game::account
