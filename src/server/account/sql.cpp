#include "account/sql.hpp"

#include "account/rules.hpp"
#include "account/starter.hpp"
#include "secure/secure.hpp"

#include <array>
#include <charconv>
#include <chrono>
#include <optional>
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

    void text(std::string value) { values.push_back(std::move(value)); }
    void i64(std::int64_t value) { values.push_back(pg_i64(value)); }
    void null() { values.emplace_back(); }

    [[nodiscard]] std::span<const std::optional<std::string>> span() const { return values; }
};

struct Tx {
    PgConn& conn;
    bool open = false;

    explicit Tx(PgConn& connection) : conn(connection) {}
    ~Tx() {
        if (open) static_cast<void>(conn.exec("ROLLBACK"));
    }
    Tx(const Tx&) = delete;
    Tx& operator=(const Tx&) = delete;

    [[nodiscard]] bool begin() {
        const PgExec started = conn.exec("BEGIN");
        open = started.ok;
        if (!open) return false;
        const PgExec timeout = conn.exec("SET LOCAL statement_timeout = '5s'");
        if (timeout.ok) return true;
        static_cast<void>(conn.exec("ROLLBACK"));
        open = false;
        return false;
    }

    [[nodiscard]] bool commit() {
        if (!open) return false;
        const PgExec done = conn.exec("COMMIT");
        open = false;
        return done.ok;
    }
};

[[nodiscard]] bool unique_hit(const PgExec& exec) noexcept {
    return exec.sqlstate == "23505";
}

[[nodiscard]] const std::string* cell(const PgExec& exec, std::size_t row, std::size_t col) {
    if (row >= exec.rows.size()) return nullptr;
    const store::PgRow& line = exec.rows[row];
    if (col >= line.cells.size()) return nullptr;
    if (line.cells[col].null) return nullptr;
    return &line.cells[col].text;
}

[[nodiscard]] std::optional<std::int64_t> as_i64(std::string_view text) {
    std::int64_t value = 0;
    const auto parsed = std::from_chars(text.data(), text.data() + text.size(), value);
    if (parsed.ec != std::errc{} || parsed.ptr != text.data() + text.size()) return std::nullopt;
    return value;
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
    const std::string hex = secure::hex_encode(raw);
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
    std::string_view name, std::string_view fold, std::string_view password) {
    const std::size_t mem_bytes = static_cast<std::size_t>(options.mem_limit_kib) * 1024U;
    const secure::PasswordPolicy policy{
        .ops = static_cast<unsigned long long>(options.ops_limit),
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

[[nodiscard]] std::optional<protocol::CharacterSummary> read_summary(const PgExec& exec, std::size_t row) {
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
    return summary;
}

[[nodiscard]] ListResult list_players(PgConn& conn, std::uint64_t account) {
    Args args;
    args.i64(static_cast<std::int64_t>(account));
    const PgExec found =
        conn.exec("SELECT id::text, name, level::text, gender::text, face::text, hair::text, school::text, scene::text "
                  "FROM player WHERE account_id = $1 AND deleted_at IS NULL ORDER BY id LIMIT 8",
            args.span());
    if (!found.ok) return ListResult{};
    ListResult result;
    result.ok = true;
    result.account = account;
    for (std::size_t row = 0; row < found.rows.size(); ++row) {
        const std::optional<protocol::CharacterSummary> summary = read_summary(found, row);
        if (!summary) return ListResult{};
        result.characters.push_back(*summary);
    }
    return result;
}

[[nodiscard]] bool grant_starter(PgConn& conn, std::int64_t player) {
    for (std::size_t slot = 0; slot < starter::kSkills.size(); ++slot) {
        Args args;
        args.i64(player);
        args.i64(static_cast<std::int64_t>(slot));
        args.i64(starter::kSkills[slot]);
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
    const auto written = std::to_chars(buffer.data(), buffer.data() + buffer.size(), value, std::chars_format::general);
    if (written.ec != std::errc{}) return "0";
    return std::string{buffer.data(), written.ptr};
}

} // namespace

AuthDb::AuthDb(PgConn& conn, AuthOptions options) : conn_(conn), options_(options) {}

TicketResult AuthDb::create_account(std::string_view name, std::string_view password, std::string_view ip) {
    if (!ipv4_ok(ip)) return fail_ticket(protocol::ErrorCode::kBadCredentials);
    const NameFault fault = account_fault(name, password);
    const std::string fold = fold_ascii(name);
    const std::string ip_key = std::string("ip:") + std::string{ip};
    Tx tx{conn_};
    if (!tx.begin() || !lock_name(conn_, ip_key) || !lock_name(conn_, fold)) return {};
    const std::optional<int> by_ip = failure_count_ip(conn_, ip);
    if (!by_ip) return {};
    if (*by_ip >= kIpFailLimit) return fail_ticket(protocol::ErrorCode::kRateLimited);
    if (fault != NameFault::kOk) {
        if (!note_attempt(conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(fault_code(fault));
    }
    Loaded existing = load_account(conn_, fold);
    secure::wipe_bytes(std::as_writable_bytes(std::span{existing.password_hash.data(), existing.password_hash.size()}));
    if (existing.failed) return {};
    if (existing.found) {
        // Tên đã có trả cùng mã và cùng thời gian băm như đăng nhập sai: không dò được tài khoản nào
        // tồn tại. Vẫn là một lần thử hỏng của IP này, nên tổng số lần dò có trần kIpFailLimit.
        burn_dummy(options_, password);
        if (!note_attempt(conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    const std::optional<std::int64_t> id = insert_account(conn_, options_, name, fold, password);
    if (!id) return {};
    if (*id < 0) {
        // Đua với một lệnh tạo khác cùng tên: cùng câu trả lời như tên đã có (đã băm một lần).
        Tx again{conn_};
        tx.open = false;
        static_cast<void>(conn_.exec("ROLLBACK"));
        if (!again.begin() || !note_attempt(conn_, std::nullopt, fold, ip, false) || !again.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    if (!note_attempt(conn_, *id, fold, ip, true)) return {};
    const std::optional<std::string> hex = issue_ticket(conn_, *id, options_.ttl_seconds);
    if (!hex || !tx.commit()) return {};
    TicketResult result;
    result.ok = true;
    result.hex = *hex;
    return result;
}

TicketResult AuthDb::sign_in(std::string_view name, std::string_view password, std::string_view ip) {
    if (!sign_in_shape_ok(name, password) || !ipv4_ok(ip)) {
        burn_dummy(options_, password);
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    const std::string fold = fold_ascii(name);
    const std::string ip_key = std::string("ip:") + std::string{ip};
    Tx tx{conn_};
    if (!tx.begin() || !lock_name(conn_, ip_key) || !lock_name(conn_, fold)) return {};
    const std::optional<int> failures = failure_count(conn_, fold);
    const std::optional<int> by_ip = failure_count_ip(conn_, ip);
    if (!failures || !by_ip) return {};
    if (*failures >= kFailLimit || *by_ip >= kIpFailLimit) return fail_ticket(protocol::ErrorCode::kRateLimited);
    Loaded loaded = load_account(conn_, fold);
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
            if (!note_attempt(conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
            return fail_ticket(protocol::ErrorCode::kBadCredentials);
        }
        const std::optional<std::int64_t> id = insert_account(conn_, options_, name, fold, password);
        if (!id) return {};
        if (*id < 0) {
            if (!note_attempt(conn_, std::nullopt, fold, ip, false) || !tx.commit()) return {};
            return fail_ticket(protocol::ErrorCode::kBadCredentials);
        }
        loaded.id = *id;
        loaded.found = true;
    }
    if (step != SignStep::kOk && step != SignStep::kCreate) {
        if (!loaded.found) burn_dummy(options_, password);
        const std::optional<std::int64_t> who = loaded.found ? std::optional<std::int64_t>{loaded.id} : std::nullopt;
        if (!note_attempt(conn_, who, fold, ip, false) || !tx.commit()) return {};
        return fail_ticket(protocol::ErrorCode::kBadCredentials);
    }
    if (!note_attempt(conn_, loaded.id, fold, ip, true)) return {};
    const std::optional<std::string> hex = issue_ticket(conn_, loaded.id, options_.ttl_seconds);
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
    Tx tx{conn_};
    if (!tx.begin()) return {};
    Args args;
    args.text(stored);
    const PgExec used =
        conn_.exec("UPDATE ticket SET used_at = now() WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now() "
                   "RETURNING account_id::text",
            args.span());
    if (!used.ok) return {};
    if (used.rows.empty()) {
        const PgExec prior =
            conn_.exec("SELECT (used_at IS NOT NULL OR expires_at <= now())::text FROM ticket WHERE token_hash = $1",
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
    const PgExec account = conn_.exec(
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
        conn_.exec("SELECT (disabled_at IS NOT NULL OR EXISTS (SELECT 1 FROM ban WHERE ban.account_id = account.id "
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

GameDb::GameDb(PgConn& conn, CharacterPolicy policy) : conn_(conn), policy_(std::move(policy)) {}

ListResult GameDb::list(std::uint64_t account) {
    return list_players(conn_, account);
}

ListResult GameDb::create_character(std::uint64_t account, std::string_view name, protocol::Gender gender,
    std::uint16_t face, std::uint16_t hair) {
    if (!protocol::is_valid(gender) || !look_ok(policy_.look, gender, face, hair)) {
        ListResult result;
        result.code = protocol::ErrorCode::kBadOption;
        return result;
    }
    const std::optional<std::string> canonical = canonical_character_name(name);
    if (!canonical) return fail_list(protocol::ErrorCode::kNameInvalid);
    const std::string fold = fold_character_name(*canonical);
    Tx tx{conn_};
    if (!tx.begin()) return {};
    Args lock;
    lock.i64(static_cast<std::int64_t>(account));
    const PgExec locked = conn_.exec("SELECT pg_advisory_xact_lock($1)", lock.span());
    if (!locked.ok) return {};
    // Khoá theo tên: chỗ giữ tên đã xoá không có chỉ mục duy nhất nào canh, phải tuần tự hoá ở đây.
    if (!lock_name(conn_, std::string("player:") + fold)) return {};
    Args count_args;
    count_args.i64(static_cast<std::int64_t>(account));
    const PgExec counted =
        conn_.exec("SELECT count(*)::text FROM player WHERE account_id = $1 AND deleted_at IS NULL", count_args.span());
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
        conn_.exec("SELECT 1 FROM player WHERE name_fold = $1 AND (deleted_at IS NULL OR "
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
    insert.i64(static_cast<std::int64_t>(gender));
    insert.i64(face);
    insert.i64(hair);
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
    const PgExec wrote = conn_.exec(
        "INSERT INTO player (account_id, name, name_fold, gender, face, hair, school, level, exp, scene, "
        "position_x, position_z, hp, mp, camp, money, vigor, max_vigor, energy, max_energy, strength, spirit, "
        "constitution, intellect, dexterity, actual_age, motto) "
        "VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27) "
        "RETURNING id::text",
        insert.span());
    if (unique_hit(wrote)) {
        ListResult result;
        result.code = protocol::ErrorCode::kNameTaken;
        return result;
    }
    const std::string* id_text = cell(wrote, 0, 0);
    const std::optional<std::int64_t> id = id_text == nullptr ? std::nullopt : as_i64(*id_text);
    if (!wrote.ok || !id) return {};
    if (!grant_starter(conn_, *id) || !tx.commit()) return {};
    return list_players(conn_, account);
}

ListResult GameDb::remove_character(std::uint64_t account, std::uint64_t character) {
    Args args;
    args.i64(static_cast<std::int64_t>(character));
    args.i64(static_cast<std::int64_t>(account));
    const PgExec wrote =
        conn_.exec("UPDATE player SET deleted_at = now() WHERE id = $1 AND account_id = $2 AND deleted_at IS NULL",
            args.span());
    if (!wrote.ok) return {};
    if (wrote.affected != 1) {
        ListResult result;
        result.code = protocol::ErrorCode::kNoSuchCharacter;
        return result;
    }
    return list_players(conn_, account);
}

EnterResult GameDb::enter(std::uint64_t account, std::uint64_t character) {
    Args args;
    args.i64(static_cast<std::int64_t>(character));
    args.i64(static_cast<std::int64_t>(account));
    // position_x/position_z lưu mét; gate làm việc bằng centimet nguyên.
    const PgExec found =
        conn_.exec("SELECT scene::text, round(position_x * 100)::bigint::text, round(position_z * 100)::bigint::text "
                   "FROM player WHERE id = $1 AND account_id = $2 AND deleted_at IS NULL",
            args.span());
    EnterResult result;
    if (!found.ok) return result;
    if (found.rows.empty()) {
        result.code = protocol::ErrorCode::kNoSuchCharacter;
        return result;
    }
    const std::string* scene = cell(found, 0, 0);
    const std::string* x_cm = cell(found, 0, 1);
    const std::string* z_cm = cell(found, 0, 2);
    const std::optional<std::int64_t> scene_value = scene == nullptr ? std::nullopt : as_i64(*scene);
    const std::optional<std::int64_t> x_value = x_cm == nullptr ? std::nullopt : as_i64(*x_cm);
    const std::optional<std::int64_t> z_value = z_cm == nullptr ? std::nullopt : as_i64(*z_cm);
    // Hàng hỏng hay toạ độ ngoài trần: không cho vào thay vì đặt mốc bừa.
    if (!scene_value || !x_value || !z_value || !fits_wire(*scene_value, 65535) || !spot_fits(*x_value) ||
        !spot_fits(*z_value)) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    result.ok = true;
    result.scene = static_cast<std::uint16_t>(*scene_value);
    result.x_cm = static_cast<std::int32_t>(*x_value);
    result.z_cm = static_cast<std::int32_t>(*z_value);
    return result;
}

} // namespace game::account
