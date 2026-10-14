// PgBook trên PostgreSQL thật. Mỗi ca dựng schema riêng trong database billing của bản thử (không đụng bảng thật)
// rồi dọn. Không có secrets.local.toml hoặc không nối được thì mỗi ca in một dòng "bỏ qua" và đạt (test tự bỏ qua).
// Ba thứ được thử:
//  1. Cùng kịch bản và cùng vết với MemoryBook (billing_scenarios.hpp, script::Script): hai nơi lưu, một luật.
//  2. Những gì chỉ database bảo đảm được: ràng buộc, sổ chỉ ghi thêm, hai kết nối tranh nhau, nối lại sau khi kết
//     nối bị giết, billing chạy lại giữa hai pha.
//  3. Bảo toàn điểm sau một kịch bản dài bị giết kết nối ngẫu nhiên giữa chừng, đối soát bằng SQL viết riêng
//     (không dùng chính mã ledger_check mà ca đang thử).
#include "billing/book.hpp"
#include "billing/db/pg_book.hpp"
#include "billing/error.hpp"
#include "billing/memory_book.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"
#include "ids/ids.hpp"
#include "store/pg.hpp"

#include "billing_pg_support.hpp"
#include "billing_scenarios.hpp"
#include "billing_script.hpp"
#include "billing_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <format>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

using test::Case;
using test::Context;
namespace pg = test::billing_pg;
using test::billing_support::test_config;
using scenario::at;
using scenario::kA;
using scenario::kB;
using scenario::paid;

[[nodiscard]] const pg::Access* access_or_skip(std::string_view name) {
    return pg::shared_access(name);
}

[[nodiscard]] std::unique_ptr<pg::Schema> make_schema(Context& context, const pg::Access& access) {
    std::string why;
    std::unique_ptr<pg::Schema> schema = pg::Schema::create(access, why);
    context.expect(schema != nullptr, why);
    return schema;
}

[[nodiscard]] std::unique_ptr<PgBook> open_book(Context& context, const pg::Schema& schema, std::string_view application = {}) {
    auto book = std::make_unique<PgBook>(schema.options(application), test_config());
    const bool connected = book->connect();
    context.expect(connected, book->last_error());
    if (!connected) return nullptr;
    return book;
}

// Mỗi fresh() là một schema mới; corrupt() sửa thẳng bản nhớ đệm trong schema của sổ đó.
class PgScenarioEnv {
public:
    explicit PgScenarioEnv(const pg::Access& access) : access_(&access) {}

    [[nodiscard]] scenario::Env env() {
        return scenario::Env{.fresh = [this] { return make(); },
            .corrupt = [this](Book& book, AccountId account, Points value) { corrupt(book, account, value); }};
    }

private:
    [[nodiscard]] std::unique_ptr<Book> make() {
        std::string why;
        std::unique_ptr<pg::Schema> schema = pg::Schema::create(*access_, why);
        if (!schema) {
            std::println(stderr, "không dựng được schema test: {}", why);
            std::abort();
        }
        auto book = std::make_unique<PgBook>(schema->options(), test_config());
        if (!book->connect()) {
            std::println(stderr, "không nối được PostgreSQL: {}", book->last_error());
            std::abort();
        }
        owners_.emplace_back(book.get(), std::move(schema));
        return book;
    }

    void corrupt(Book& book, AccountId account, Points value) {
        const auto owner = std::ranges::find(owners_, &book, &std::pair<const Book*, std::unique_ptr<pg::Schema>>::first);
        if (owner == owners_.end()) return;
        const std::array<std::optional<std::string>, 2> params{std::to_string(account.value()), std::to_string(value.value())};
        static_cast<void>(owner->second->exec("UPDATE point_balance SET points = $2::bigint WHERE account_id = $1::bigint", params));
    }

    const pg::Access* access_;
    std::vector<std::pair<const Book*, std::unique_ptr<pg::Schema>>> owners_;
};

// ---- ràng buộc của schema ----------------------------------------------------------------------------

// Một câu lệnh phải bị database từ chối với đúng SQLSTATE.
struct Rejection {
    std::string_view sql;
    std::string_view state;
    std::string_view what;
};

void expect_state(Context& context, pg::Schema& schema, const Rejection& rejection) {
    const store::PgExec result = schema.exec(rejection.sql);
    context.expect(!result.ok && result.sqlstate == rejection.state,
        std::format("{} (cần {}, được '{}')", rejection.what, rejection.state, result.sqlstate));
}

void pg_schema_rules(Context& context) {
    const pg::Access* access = access_or_skip("pg_schema_rules");
    if (access == nullptr) return;
    const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
    if (!schema) return;
    pg::Schema& s = *schema;

    context.expect(s.scalar("SELECT COUNT(*) FROM schema_version") == 5 && s.scalar("SELECT MAX(version) FROM schema_version") == 5,
        "năm migration đã áp");
    std::string error;
    std::optional<store::PgConn> again = store::PgConn::open(access->billing, error);
    context.expect(again.has_value(), error);
    if (!again) return;
    static_cast<void>(again->exec(std::format("SET search_path TO {}", s.name())));
    context.expect(store::migrate(*again, access->sql_dir, error), "áp lại migration là không làm gì");
    context.expect(s.scalar("SELECT COUNT(*) FROM schema_version") == 5, "áp lại không thêm dòng phiên bản");

    context.expect(s.exec("INSERT INTO billing_account (account_id, created_at) VALUES (1, 0), (2, 0)").ok, "chuẩn bị tài khoản");
    context.expect(s.exec("INSERT INTO point_balance (account_id, points, updated_at) VALUES (1, 0, 0), (2, 0, 0)").ok, "chuẩn bị số dư");
    expect_state(context, s, {.sql = "INSERT INTO billing_account (account_id, created_at) VALUES (0, 0)", .state = "23514", .what = "id tài khoản 0"});
    expect_state(context, s, {.sql = "UPDATE point_balance SET points = -1 WHERE account_id = 1", .state = "23514", .what = "số dư âm"});

    constexpr std::string_view kLedger = "INSERT INTO point_ledger (account_id, delta, kind, ref_id, reason, actor, at) VALUES ";
    expect_state(context, s, {.sql = std::format("{}(1, -5, 'top_up', 9, 'x', 'y', 0)", kLedger), .state = "23514", .what = "nạp mà delta âm"});
    expect_state(context, s, {.sql = std::format("{}(1, 5, 'refund', 9, 'x', 'y', 0)", kLedger), .state = "23514", .what = "hoàn mà delta dương"});
    expect_state(context, s, {.sql = std::format("{}(1, 0, 'admin', 0, 'x', 'y', 0)", kLedger), .state = "23514", .what = "delta 0"});
    expect_state(context, s, {.sql = std::format("{}(1, 5, 'bogus', 9, 'x', 'y', 0)", kLedger), .state = "23514", .what = "loại dòng sổ lạ"});
    expect_state(context, s, {.sql = std::format("{}(1, 5, 'top_up', 9, '', 'y', 0)", kLedger), .state = "23514", .what = "lý do rỗng"});
    expect_state(context, s, {.sql = std::format("{}(99, 5, 'top_up', 9, 'x', 'y', 0)", kLedger), .state = "23503", .what = "tài khoản chưa có"});
    context.expect(s.exec(std::format("{}(1, 5, 'top_up', 9, 'x', 'y', 0)", kLedger)).ok, "dòng sổ hợp lệ");
    expect_state(context, s, {.sql = std::format("{}(2, 5, 'top_up', 9, 'x', 'y', 0)", kLedger), .state = "23505", .what = "cùng (loại, ref) lần hai"});
    context.expect(s.exec(std::format("{}(1, 1, 'admin', 0, 'x', 'y', 0), (1, 1, 'admin', 0, 'x', 'y', 0)", kLedger)).ok,
        "ref 0 được lặp");
    expect_state(context, s, {.sql = "UPDATE point_ledger SET delta = 6 WHERE kind = 'top_up'", .state = "23000", .what = "sửa dòng sổ"});
    expect_state(context, s, {.sql = "DELETE FROM point_ledger", .state = "23000", .what = "xoá dòng sổ"});
    expect_state(context, s, {.sql = "TRUNCATE point_ledger", .state = "23000", .what = "TRUNCATE sổ"});
    context.expect(s.scalar("SELECT COUNT(*) FROM point_ledger") == 3, "sổ còn nguyên ba dòng");

    constexpr std::string_view kPayment = "INSERT INTO payment (provider, trade_no, account_id, points, amount_minor, currency, status, created_at, updated_at) VALUES ";
    context.expect(s.exec(std::format("{}('alpha', 'T1', 1, 5, 5000, 'VND', 'paid', 0, 0)", kPayment)).ok, "đơn nạp hợp lệ");
    expect_state(context, s, {.sql = std::format("{}('alpha', 'T1', 1, 5, 5000, 'VND', 'paid', 0, 0)", kPayment), .state = "23505", .what = "cùng (provider, trade_no)"});
    context.expect(s.exec(std::format("{}('beta', 'T1', 1, 5, 5000, 'VND', 'paid', 0, 0)", kPayment)).ok, "cùng mã khác nhà cung cấp");
    expect_state(context, s, {.sql = std::format("{}('alpha', 'T2', 1, 0, 5000, 'VND', 'paid', 0, 0)", kPayment), .state = "23514", .what = "đơn nạp 0 điểm"});
    expect_state(context, s, {.sql = std::format("{}('alpha', 'T3', 1, 5, 5000, 'vnd', 'paid', 0, 0)", kPayment), .state = "23514", .what = "tiền tệ chữ thường"});
    expect_state(context, s, {.sql = std::format("{}('alpha', 'T4', 1, 5, 5000, 'VND', 'weird', 0, 0)", kPayment), .state = "23514", .what = "trạng thái lạ"});
    expect_state(context, s, {.sql = "INSERT INTO redeem_code (batch_id, code_hash) VALUES (1, repeat('a', 64))", .state = "23503", .what = "đợt chưa có"});
    expect_state(context, s, {.sql = "INSERT INTO redeem_code (batch_id, code_hash) VALUES (1, 'abc')", .state = "23514", .what = "băm sai hình dạng"});
}

// ---- cùng kịch bản với MemoryBook ----------------------------------------------------------------------

void pg_topup_exchange(Context& context) {
    const pg::Access* access = access_or_skip("pg_topup_exchange");
    if (access == nullptr) return;
    PgScenarioEnv env{*access};
    scenario::topup_exchange(context, env.env());
}

void pg_redeem_and_grants(Context& context) {
    const pg::Access* access = access_or_skip("pg_redeem_and_grants");
    if (access == nullptr) return;
    PgScenarioEnv env{*access};
    scenario::redeem_and_grants(context, env.env());
}

void pg_admin_spend_audit(Context& context) {
    const pg::Access* access = access_or_skip("pg_admin_spend_audit");
    if (access == nullptr) return;
    PgScenarioEnv env{*access};
    scenario::admin_spend_audit(context, env.env());
}

void pg_text_fields(Context& context) {
    const pg::Access* access = access_or_skip("pg_text_fields");
    if (access == nullptr) return;
    PgScenarioEnv env{*access};
    scenario::text_fields(context, env.env());
}

// Cùng hạt giống thì MemoryBook và PgBook phải ra cùng vết từng dòng (id không nằm trong vết).
void pg_script_equals_memory(Context& context) {
    const pg::Access* access = access_or_skip("pg_script_equals_memory");
    if (access == nullptr) return;
    for (const std::uint64_t seed : {std::uint64_t{20260507}, std::uint64_t{99}}) {
        MemoryBook memory{test_config()};
        script::Script on_memory(memory, seed);
        const script::Outcome expected = on_memory.run(600);

        const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
        if (!schema) return;
        const std::unique_ptr<PgBook> book = open_book(context, *schema);
        if (!book) return;
        script::Script on_pg(*book, seed);
        const script::Outcome actual = on_pg.run(600);

        context.expect(actual.trace.size() == expected.trace.size(),
            std::format("seed {}: số dòng vết {} khác {}", seed, actual.trace.size(), expected.trace.size()));
        const std::size_t common = std::min(actual.trace.size(), expected.trace.size());
        for (std::size_t line = 0; line < common; ++line) {
            if (actual.trace[line] == expected.trace[line]) continue;
            context.expect(false, std::format("seed {}: dòng {} khác nhau\n  memory: {}\n  pg:     {}", seed, line,
                                      expected.trace[line], actual.trace[line]));
            break;
        }
        context.expect(actual.balanced && actual.mismatched == 0, "sổ PgBook cân sau kịch bản");
        context.expect(actual.duplicates == expected.duplicates && actual.refunds == expected.refunds &&
                actual.confirmed == expected.confirmed && actual.cancelled == expected.cancelled,
            "đếm bước giống nhau");
    }
}

// ---- thứ chỉ database bảo đảm ---------------------------------------------------------------------------

struct Tally {
    std::atomic<std::int64_t> applied{0};
    std::atomic<std::int64_t> duplicate{0};
    std::atomic<std::int64_t> other{0};
};

// Hai kết nối cùng nạp cùng một dãy đơn và cùng xin cùng một dãy request: mỗi đơn/request thành công đúng một lần,
// không kBusy (khoá cố vấn làm hai bên đi lần lượt, không deadlock), không mất không thừa điểm.
void pg_two_writers(Context& context) {
    const pg::Access* access = access_or_skip("pg_two_writers");
    if (access == nullptr) return;
    const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
    if (!schema) return;
    const std::unique_ptr<PgBook> first = open_book(context, *schema);
    const std::unique_ptr<PgBook> second = open_book(context, *schema);
    if (!first || !second) return;

    constexpr std::int64_t kOrders = 40;
    constexpr std::int64_t kRequests = 20;
    Tally pays;
    Tally begins;
    const auto race = [&](PgBook& book) {
        for (std::int64_t index = 1; index <= kOrders; ++index) {
            const Result<PaymentOutcome> result = book.apply_payment(paid(std::format("P{}", index), kA, 100), at(index));
            if (result && result->result == PaymentResult::kApplied) {
                ++pays.applied;
            } else if (result && result->result == PaymentResult::kDuplicate) {
                ++pays.duplicate;
            } else {
                ++pays.other;
            }
        }
        for (std::int64_t request = 1; request <= kRequests; ++request) {
            const ExchangeRequest ask{.account = kA, .character = CharacterId{70}, .request = RequestId{static_cast<std::uint64_t>(request)}, .ingot = Ingot{10}};
            const Result<ExchangeOutcome> result = book.exchange_begin(ask, at(100 + request));
            if (!result) {
                ++begins.other;
            } else if (result->replayed) {
                ++begins.duplicate;
            } else {
                ++begins.applied;
            }
        }
    };
    {
        const std::jthread one{[&] { race(*first); }};
        const std::jthread two{[&] { race(*second); }};
    }
    context.expect(pays.applied == kOrders && pays.duplicate == kOrders && pays.other == 0,
        std::format("nạp: áp {} lặp {} khác {}", pays.applied.load(), pays.duplicate.load(), pays.other.load()));
    context.expect(begins.applied == kRequests && begins.duplicate == kRequests && begins.other == 0,
        std::format("đổi: mới {} lặp {} khác {}", begins.applied.load(), begins.duplicate.load(), begins.other.load()));
    // Quà đăng ký không có ở đây (ensure_account không được gọi): 40 đơn x 100 phần mười, trừ 20 lần giữ ceil(100/3) = 34.
    const Result<Balance> balance = first->balance(kA);
    context.expect(balance && balance->available.value() == kOrders * 100 - kRequests * 34 && balance->held.value() == kRequests * 34,
        "số dư và điểm giữ sau cuộc đua");
    context.expect(first->ledger_check()->balanced, "sổ cân sau cuộc đua");

    // Tranh nhau điểm cuối: 340 phần mười đủ cho đúng 10 lần giữ 34; 20 lần xin từ hai bên chỉ được 10, không bên nào làm âm.
    const std::unique_ptr<pg::Schema> poor = make_schema(context, *access);
    if (!poor) return;
    const std::unique_ptr<PgBook> left = open_book(context, *poor);
    const std::unique_ptr<PgBook> right = open_book(context, *poor);
    if (!left || !right) return;
    context.expect(left->apply_payment(paid("Q1", kB, 340), at(0)).has_value(), "chuẩn bị 340 phần mười");
    std::atomic<std::int64_t> won{0};
    std::atomic<std::int64_t> lost{0};
    std::atomic<std::int64_t> odd{0};
    const auto grab = [&](PgBook& book, std::uint64_t base) {
        for (std::uint64_t index = 0; index < 10; ++index) {
            const ExchangeRequest ask{.account = kB, .character = CharacterId{80}, .request = RequestId{base + index}, .ingot = Ingot{10}};
            const Result<ExchangeOutcome> result = book.exchange_begin(ask, at(1));
            if (result) {
                ++won;
            } else if (result.error() == Error::kInsufficient) {
                ++lost;
            } else {
                ++odd;
            }
        }
    };
    {
        const std::jthread one{[&] { grab(*left, 1); }};
        const std::jthread two{[&] { grab(*right, 101); }};
    }
    context.expect(won == 10 && lost == 10 && odd == 0,
        std::format("tranh điểm cuối: được {} hết {} khác {}", won.load(), lost.load(), odd.load()));
    const Result<Balance> last = left->balance(kB);
    context.expect(last && last->available.value() == 0 && last->held.value() == 340, "không bên nào làm số dư âm");
    context.expect(left->ledger_check()->balanced, "sổ cân sau tranh điểm cuối");
}

// Giết phiên của một PgBook từ kết nối khác, rồi chờ phiên biến mất khỏi pg_stat_activity.
void kill_sessions(const pg::Access& access, std::string_view application) {
    std::string error;
    std::optional<store::PgConn> killer = store::PgConn::open(access.billing, error);
    if (!killer) return;
    const std::array<std::optional<std::string>, 1> params{std::string{application}};
    static_cast<void>(killer->exec(
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = $1 AND pid <> pg_backend_pid()", params));
}

[[nodiscard]] std::int64_t live_sessions(const pg::Access& access, std::string_view application) {
    std::string error;
    std::optional<store::PgConn> probe = store::PgConn::open(access.billing, error);
    if (!probe) return -1;
    const std::array<std::optional<std::string>, 1> params{std::string{application}};
    const store::PgExec rows = probe->exec("SELECT COUNT(*) FROM pg_stat_activity WHERE application_name = $1", params);
    if (!rows.ok || rows.rows.empty()) return -1;
    return std::stoll(rows.rows.front().cells.front().text);
}

void kill_and_wait(const pg::Access& access, std::string_view application) {
    kill_sessions(access, application);
    for (int attempt = 0; attempt < 200 && live_sessions(access, application) != 0; ++attempt) {
        std::this_thread::sleep_for(std::chrono::milliseconds{10});
    }
}

// Kết nối bị giết giữa hai lời gọi: lời gọi kế tiếp nối lại. Ghi và đọc đều qua được, đếm lần nối lại.
void pg_reconnect(Context& context) {
    const pg::Access* access = access_or_skip("pg_reconnect");
    if (access == nullptr) return;
    const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
    if (!schema) return;
    const std::string app = pg::random_name("tb_app_");
    const std::unique_ptr<PgBook> book = open_book(context, *schema, app);
    if (!book) return;
    context.expect(book->apply_payment(paid("C1", kA, 100), at(0)).has_value(), "ghi lần đầu");
    context.expect(book->reconnects() == 0, "chưa nối lại lần nào");
    kill_and_wait(*access, app);
    context.expect(book->apply_payment(paid("C2", kA, 50), at(1)).has_value(), "ghi sau khi bị giết kết nối");
    context.expect(book->reconnects() == 1, "đã nối lại một lần");
    kill_and_wait(*access, app);
    const Result<Balance> balance = book->balance(kA);
    context.expect(balance && balance->available.value() == 150, "đọc sau khi bị giết kết nối");
    context.expect(book->reconnects() == 2, "đã nối lại lần hai");
    context.expect(book->ledger_check()->balanced, "sổ cân");

    // Database không nối được (sai mật khẩu): kBusy, có lý do, không treo, không lộ mật khẩu.
    PgOptions broken = schema->options();
    broken.login.password = "sai-mat-khau";
    PgBook offline{broken, test_config()};
    context.expect(!offline.connect() && !offline.last_error().empty(), "sai mật khẩu thì không nối được");
    context.expect(offline.last_error().find("sai-mat-khau") == std::string::npos, "câu lỗi không chứa mật khẩu");
    context.expect(offline.apply_payment(paid("C3", kA, 1), at(2)).error() == Error::kBusy, "không nối được thì kBusy");
    context.expect(offline.balance(kA).error() == Error::kBusy, "đọc cũng kBusy");
}

// Billing chạy lại giữa hai pha: đối tượng sổ mới trên cùng database thấy đơn đang chờ, lời gọi lại của world
// nhận lại đúng đơn, chốt được, và điểm không đổi qua lần chạy lại.
void pg_restart_mid_flow(Context& context) {
    const pg::Access* access = access_or_skip("pg_restart_mid_flow");
    if (access == nullptr) return;
    const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
    if (!schema) return;
    const ExchangeRequest ask{.account = kA, .character = CharacterId{70}, .request = RequestId{1}, .ingot = Ingot{30}};
    ExchangeId order{};
    {
        const std::unique_ptr<PgBook> before = open_book(context, *schema);
        if (!before) return;
        context.expect(before->apply_payment(paid("R1", kA, 1000), at(0)).has_value(), "nạp trước khi chạy lại");
        const Result<ExchangeOutcome> begun = before->exchange_begin(ask, at(1));
        context.expect(begun && begun->balance.value() == 900, "pha một: giữ ceil(300/3) = 100");
        if (!begun) return;
        order = begun->order.id;
    }
    const std::unique_ptr<PgBook> after = open_book(context, *schema);
    if (!after) return;
    const Result<ExchangeOrder> found = after->find_exchange(order);
    context.expect(found && found->status == ExchangeStatus::kPending, "đơn còn chờ sau khi chạy lại");
    const Result<ExchangeOutcome> replay = after->exchange_begin(ask, at(2));
    context.expect(replay && replay->replayed && replay->order.id == order && replay->balance.value() == 900,
        "world gọi lại pha một: nhận lại đúng đơn, không giữ thêm điểm");
    const Result<ExchangeOutcome> done = after->exchange_finish(order, Verdict::kDone, at(3));
    context.expect(done && done->order.status == ExchangeStatus::kConfirmed && done->balance.value() == 900, "pha hai chốt");
    context.expect(after->apply_payment(paid("R1", kA, 1000), at(4))->result == PaymentResult::kDuplicate, "nhà cung cấp gọi lại sau khi chạy lại");
    context.expect(after->exchange_open(10)->empty(), "hết đơn mở");
    context.expect(after->ledger_check()->balanced, "sổ cân");
}

// ---- bảo toàn điểm dưới lỗi chèn ----------------------------------------------------------------------------

// Đối soát bằng SQL viết riêng, không dùng ledger_check của PgBook.
void expect_conserved(Context& context, pg::Schema& schema, std::string_view what) {
    context.expect(schema.scalar("SELECT COALESCE(SUM(points), 0) FROM payment WHERE status IN ('paid', 'refunded')") ==
            schema.scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'top_up'"),
        std::format("{}: điểm nạp = tổng đơn đã trả", what));
    context.expect(schema.scalar("SELECT COALESCE(SUM(points), 0) FROM payment WHERE status = 'refunded'") ==
            -schema.scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'refund'"),
        std::format("{}: điểm hoàn = tổng đơn đã hoàn", what));
    context.expect(schema.scalar("SELECT COALESCE(SUM(points), 0) FROM point_balance") ==
            schema.scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger"),
        std::format("{}: tổng số dư = tổng sổ", what));
    context.expect(schema.scalar("SELECT COUNT(*) FROM exchange_order") ==
            schema.scalar("SELECT COUNT(*) FROM point_ledger WHERE kind = 'exchange_hold'"),
        std::format("{}: mỗi đơn đổi có đúng một dòng giữ điểm", what));
    context.expect(schema.scalar("SELECT COUNT(*) FROM exchange_order WHERE status = 'cancelled'") ==
            schema.scalar("SELECT COUNT(*) FROM point_ledger WHERE kind = 'exchange_release'"),
        std::format("{}: mỗi đơn huỷ có đúng một dòng hoàn điểm", what));
    context.expect(schema.scalar("SELECT COUNT(*) FROM point_balance WHERE points < 0") == 0, std::format("{}: không số dư âm", what));
    context.expect(schema.scalar("SELECT COALESCE(SUM(points), 0) FROM exchange_order WHERE status IN ('pending', 'stale')") +
                schema.scalar("SELECT COALESCE(SUM(points), 0) FROM exchange_order WHERE status = 'confirmed'") ==
            -schema.scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'exchange_hold'") -
                schema.scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'exchange_release'"),
        std::format("{}: điểm giữ + điểm đã đổi = giữ - hoàn", what));
}

// Một thread giết kết nối của sổ đang chạy kịch bản 1.000 bước vào những lúc ngẫu nhiên, kể cả giữa giao dịch và
// giữa lệnh COMMIT. Mỗi lần bị giết, lời gọi đang chạy thành kBusy (hoặc đã chốt mà chưa biết: kịch bản chỉ ghi vết
// kBusy); lời gọi sau nối lại. Cuối cùng sổ phải cân trên một kết nối sạch.
void pg_fault_injection(Context& context) {
    const pg::Access* access = access_or_skip("pg_fault_injection");
    if (access == nullptr) return;
    for (const std::uint64_t seed : {std::uint64_t{20261014}, std::uint64_t{7}}) {
        const std::unique_ptr<pg::Schema> schema = make_schema(context, *access);
        if (!schema) return;
        const std::string app = pg::random_name("tb_victim_");
        const std::unique_ptr<PgBook> victim = open_book(context, *schema, app);
        if (!victim) return;

        std::atomic<std::int64_t> kills{0};
        script::Outcome outcome;
        {
            const std::jthread killer{[&](const std::stop_token& stop) {
                script::Rng rng(seed ^ 0xFEEDULL);
                while (!stop.stop_requested()) {
                    std::this_thread::sleep_for(std::chrono::milliseconds{3 + static_cast<std::int64_t>(rng.below(20))});
                    kill_sessions(*access, app);
                    ++kills;
                }
            }};
            script::Script run(*victim, seed);
            outcome = run.run(1000);
        }
        std::int64_t busy = 0;
        for (const std::string& line : outcome.trace) {
            if (line.find("e16") != std::string::npos) ++busy;
        }
        context.expect(kills > 5, std::format("seed {}: đã giết {} lần", seed, kills.load()));
        context.expect(victim->reconnects() > 0, "đã phải nối lại");
        context.expect(busy > 0, std::format("seed {}: có lời gọi thấy kBusy ({} dòng vết)", seed, busy));

        const std::unique_ptr<PgBook> clean = open_book(context, *schema);
        if (!clean) return;
        const Result<Conservation> check = clean->ledger_check();
        context.expect(check && check->balanced && check->mismatched_accounts == 0,
            std::format("seed {}: sổ cân sau {} lần giết ({} kBusy)", seed, kills.load(), busy));
        expect_conserved(context, *schema, std::format("seed {}", seed));
        // Đơn đổi bị giết giữa chừng không mất điểm: điểm vẫn bị giữ ở đơn mở, đối soát thấy chúng.
        const Result<DayReport> report = clean->day_report(outcome.trace.empty() ? 0 : test::billing_support::kT0 / kSecondsPerDay);
        context.expect(report && report->conservation.balanced, "báo cáo ngày cân");
    }
}

constexpr std::array kCases{
    Case{.name = "pg_schema_rules", .body = pg_schema_rules},
    Case{.name = "pg_topup_exchange", .body = pg_topup_exchange},
    Case{.name = "pg_redeem_and_grants", .body = pg_redeem_and_grants},
    Case{.name = "pg_admin_spend_audit", .body = pg_admin_spend_audit},
    Case{.name = "pg_text_fields", .body = pg_text_fields},
    Case{.name = "pg_script_equals_memory", .body = pg_script_equals_memory},
    Case{.name = "pg_two_writers", .body = pg_two_writers},
    Case{.name = "pg_reconnect", .body = pg_reconnect},
    Case{.name = "pg_restart_mid_flow", .body = pg_restart_mid_flow},
    Case{.name = "pg_fault_injection", .body = pg_fault_injection},
};

} // namespace
} // namespace game::billing

int main() {
    // Ca nào chết giữa chừng (abort) vẫn để lại dòng của các ca trước và dòng bỏ qua.
    static_cast<void>(std::setvbuf(stdout, nullptr, _IONBF, 0));
    return game::test::run_all(game::billing::kCases) == 0 ? 0 : 1;
}
