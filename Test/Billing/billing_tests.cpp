// Lõi billing: luật, máy trạng thái, bộ đếm tốc độ, mã đổi, HTTP/webhook/chữ ký, giao thức ipc và sổ
// bản nhớ (MemoryBook). Không cần mạng hay database. Số vàng (băm mã, chữ ký HMAC, chi phí đổi, lịch hồi
// token) tính độc lập bằng Python/tay từ định nghĩa, không sinh từ chính mã C++ đang thử.
#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/code.hpp"
#include "billing/error.hpp"
#include "billing/http.hpp"
#include "billing/limits.hpp"
#include "billing/memory_book.hpp"
#include "billing/rpc.hpp"
#include "billing/rules.hpp"
#include "billing/throttle.hpp"
#include "billing/types.hpp"
#include "billing/webhook.hpp"
#include "billing/wire.hpp"
#include "ids/ids.hpp"

#include "billing_scenarios.hpp"
#include "billing_script.hpp"
#include "billing_support.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <memory>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

using test::Case;
using test::Context;
namespace support = test::billing_support;
using support::kT0;
using support::test_config;

using scenario::at;
using scenario::Counter;
using scenario::fill_counter;
using scenario::fill_fail;
using scenario::fill_ones;
using scenario::kA;
using scenario::kB;
using scenario::paid;

// Nguồn giả ngẫu nhiên cố định hạt: `state` là script::Rng.
bool fill_rng(void* state, std::span<std::byte> out) {
    auto* rng = static_cast<script::Rng*>(state);
    for (std::byte& byte : out)
        byte = static_cast<std::byte>(rng->below(256));
    return true;
}

// ---- limits --------------------------------------------------------------------------------------

void limits_table(Context& context) {
    const auto limits = parse_limits(support::kLimitsTsv);
    context.expect(limits.has_value(), "bảng mẫu hợp lệ");
    if (!limits) return;
    context.expect(limits->max_ingot_per_order == 500000 && limits->min_ingot_per_order == 1, "trần 500000 của client");
    context.expect(limits->webhook_max_skew_seconds == 300 && limits->throttle_max_keys == 1024, "khoá khác");

    std::string missing{support::kLimitsTsv};
    missing.erase(missing.find("throttle_max_keys"));
    context.expect(!parse_limits(missing), "thiếu một khoá là lỗi");

    std::string unknown{support::kLimitsTsv};
    unknown += "mystery\t1\tx\tmade_up\tx\n";
    context.expect(!parse_limits(unknown), "khoá lạ là lỗi");

    std::string twice{support::kLimitsTsv};
    twice += "max_balance\t5\tx\tmade_up\tx\n";
    context.expect(!parse_limits(twice), "khoá lặp là lỗi");

    std::string basis{support::kLimitsTsv};
    basis.replace(basis.find("client_2026"), 11, "guess");
    context.expect(!parse_limits(basis), "basis lạ là lỗi");

    std::string range{support::kLimitsTsv};
    range.replace(range.find("\t500000\t"), 8, "\t0\t");
    context.expect(!parse_limits(range), "giá trị ngoài miền là lỗi");

    std::string inverted{support::kLimitsTsv};
    inverted.replace(inverted.find("min_ingot_per_order\t1\t"), 22, "min_ingot_per_order\t900000\t");
    context.expect(!parse_limits(inverted), "min lớn hơn max là lỗi");
    context.expect(!parse_limits("not a table"), "không phải bảng");
}

// ---- rules ---------------------------------------------------------------------------------------

void exchange_cost_golden(Context& context) {
    const Limits limits = support::test_limits();
    struct Row {
        std::int64_t ingot = 0;
        std::int64_t per_point = 0;
        std::int64_t cost = 0;
    };
    // cost = ceil(ingot * 10 / per_point), tính tay: 10/3 = 3,33 -> 4; 70/3 = 23,33 -> 24; 30/4 = 7,5 -> 8.
    constexpr std::array<Row, 8> kRows{{
        {.ingot = 1, .per_point = 1, .cost = 10}, {.ingot = 500000, .per_point = 1, .cost = 5'000'000}, {.ingot = 1, .per_point = 3, .cost = 4}, {.ingot = 7, .per_point = 3, .cost = 24}, {.ingot = 3, .per_point = 4, .cost = 8}, {.ingot = 1, .per_point = 10, .cost = 1}, {.ingot = 3, .per_point = 10, .cost = 3}, {.ingot = 1, .per_point = 1000, .cost = 1},
    }};
    for (const Row& row : kRows) {
        const Result<Points> cost = exchange_cost(Ingot{row.ingot}, row.per_point, limits);
        context.expect(cost && cost->value() == row.cost, std::format("{} ingot ở {}: {}", row.ingot, row.per_point, row.cost));
    }
    context.expect(!exchange_cost(Ingot{0}, 1, limits) && exchange_cost(Ingot{0}, 1, limits).error() == Error::kBadAmount,
        "0 ingot");
    context.expect(!exchange_cost(Ingot{500001}, 1, limits), "quá trần mỗi đơn");
    context.expect(!exchange_cost(Ingot{-5}, 1, limits), "ingot âm");
    context.expect(!exchange_cost(Ingot{5}, 0, limits), "tỉ giá 0");
    const Result<Points> frozen = exchange_begin_step(Ingot{5}, 1, Points{1000}, true, limits);
    context.expect(!frozen && frozen.error() == Error::kFrozen, "đóng băng đứng trước");
    const Result<Points> poor = exchange_begin_step(Ingot{5}, 1, Points{49}, false, limits);
    context.expect(!poor && poor.error() == Error::kInsufficient, "thiếu điểm");
    const Result<Points> exact = exchange_begin_step(Ingot{5}, 1, Points{50}, false, limits);
    context.expect(exact && exact->value() == 50, "đủ đúng");
}

void payment_step_table(Context& context) {
    using S = PaymentStatus;
    using A = PaymentAct;
    struct Row {
        std::optional<S> existing;
        S incoming = S::kPending;
        // Lỗi mong đợi; nullopt là bước hợp lệ và `act` là hành động mong đợi.
        std::optional<Error> error;
        A act = A::kDuplicate;
    };
    constexpr std::array<Row, 20> kRows{{
        {.existing = std::nullopt, .incoming = S::kPending, .error = std::nullopt, .act = A::kCreatePending},
        {.existing = std::nullopt, .incoming = S::kPaid, .error = std::nullopt, .act = A::kCreatePaid},
        {.existing = std::nullopt, .incoming = S::kFailed, .error = std::nullopt, .act = A::kCreateFailed},
        {.existing = std::nullopt, .incoming = S::kRefunded, .error = Error::kBadState, .act = A::kDuplicate},
        {.existing = S::kPending, .incoming = S::kPending, .error = std::nullopt, .act = A::kDuplicate},
        {.existing = S::kPending, .incoming = S::kPaid, .error = std::nullopt, .act = A::kPromote},
        {.existing = S::kPending, .incoming = S::kFailed, .error = std::nullopt, .act = A::kFail},
        {.existing = S::kPending, .incoming = S::kRefunded, .error = Error::kBadState, .act = A::kDuplicate},
        {.existing = S::kPaid, .incoming = S::kPending, .error = std::nullopt, .act = A::kIgnore},
        {.existing = S::kPaid, .incoming = S::kPaid, .error = std::nullopt, .act = A::kDuplicate},
        {.existing = S::kPaid, .incoming = S::kFailed, .error = Error::kConflict, .act = A::kDuplicate},
        {.existing = S::kPaid, .incoming = S::kRefunded, .error = std::nullopt, .act = A::kRefund},
        {.existing = S::kFailed, .incoming = S::kPending, .error = std::nullopt, .act = A::kIgnore},
        {.existing = S::kFailed, .incoming = S::kPaid, .error = Error::kConflict, .act = A::kDuplicate},
        {.existing = S::kFailed, .incoming = S::kFailed, .error = std::nullopt, .act = A::kDuplicate},
        {.existing = S::kFailed, .incoming = S::kRefunded, .error = Error::kBadState, .act = A::kDuplicate},
        {.existing = S::kRefunded, .incoming = S::kPending, .error = std::nullopt, .act = A::kIgnore},
        {.existing = S::kRefunded, .incoming = S::kPaid, .error = std::nullopt, .act = A::kIgnore},
        {.existing = S::kRefunded, .incoming = S::kFailed, .error = Error::kConflict, .act = A::kDuplicate},
        {.existing = S::kRefunded, .incoming = S::kRefunded, .error = std::nullopt, .act = A::kDuplicate},
    }};
    for (const Row& row : kRows) {
        const Result<PaymentAct> got = payment_step(row.existing, row.incoming);
        const std::string name = std::format("{} <- {}", row.existing ? std::string{to_text(*row.existing)} : "none",
            std::string{to_text(row.incoming)});
        if (!row.error) {
            context.expect(got && *got == row.act, name);
        } else {
            context.expect(!got && got.error() == *row.error, name + " (lỗi)");
        }
    }
}

void finish_steps(Context& context) {
    using E = ExchangeStatus;
    constexpr std::array<E, 4> kAll{E::kPending, E::kStale, E::kConfirmed, E::kCancelled};
    for (const E status : kAll) {
        const Result<FinishAct> done = exchange_finish_step(status, Verdict::kDone);
        const Result<FinishAct> cancel = exchange_finish_step(status, Verdict::kCancelled);
        if (status == E::kPending || status == E::kStale) {
            context.expect(done && *done == FinishAct::kConfirm, "mở + done");
            context.expect(cancel && *cancel == FinishAct::kCancel, "mở + cancel");
        } else if (status == E::kConfirmed) {
            context.expect(done && *done == FinishAct::kDuplicate, "đã chốt + done");
            context.expect(!cancel && cancel.error() == Error::kBadState, "đã chốt + cancel");
        } else {
            context.expect(!done && done.error() == Error::kBadState, "đã huỷ + done");
            context.expect(cancel && *cancel == FinishAct::kDuplicate, "đã huỷ + cancel");
        }
    }
    context.expect(exchange_overdue(at(0), at(600), 600), "đúng hạn là quá hạn");
    context.expect(!exchange_overdue(at(0), at(599), 600), "chưa tới hạn");
    context.expect(!exchange_overdue(at(0), at(100000), 0), "hạn 0 là không bao giờ");
    const Result<FinishAct> grant_done = grant_finish_step(GrantOrderStatus::kPending, Verdict::kDone);
    context.expect(grant_done && *grant_done == FinishAct::kConfirm, "quà chờ + done");
    const Result<FinishAct> grant_bad = grant_finish_step(GrantOrderStatus::kDone, Verdict::kCancelled);
    context.expect(!grant_bad && grant_bad.error() == Error::kBadState, "quà đã giao + cancel");
}

void redeem_step_order(Context& context) {
    CodeFacts facts;
    facts.batch_enabled = true;
    facts.now = at(500);
    facts.starts = at(100);
    facts.ends = at(1000);
    context.expect(redeem_step(facts).has_value(), "mã hợp lệ");
    facts.frozen = true;
    context.expect(redeem_step(facts).error() == Error::kFrozen, "đóng băng đứng đầu");
    facts.frozen = false;
    facts.batch_enabled = false;
    context.expect(redeem_step(facts).error() == Error::kCodeDisabled, "đợt tắt");
    facts.batch_enabled = true;
    facts.used = true;
    context.expect(redeem_step(facts).error() == Error::kCodeUsed, "đã dùng");
    facts.used = false;
    facts.now = at(99);
    context.expect(redeem_step(facts).error() == Error::kCodeNotYet, "chưa mở");
    facts.now = at(1001);
    context.expect(redeem_step(facts).error() == Error::kCodeExpired, "hết hạn");
    facts.now = at(1000);
    context.expect(redeem_step(facts).has_value(), "đúng mốc đóng vẫn dùng được");
    facts.used_in_batch = 1;
    context.expect(redeem_step(facts).error() == Error::kLimitReached, "đủ lượt đổi của đợt");
}

void admin_and_credit_steps(Context& context) {
    const Limits limits = support::test_limits();
    const Result<Points> good = admin_step(Points{500}, "bù lỗi", "gm_a", Points{100}, limits);
    context.expect(good && good->value() == 600, "cộng tay");
    context.expect(admin_step(Points{500}, "", "gm_a", Points{0}, limits).error() == Error::kReasonRequired, "thiếu lý do");
    context.expect(admin_step(Points{500}, "ok", "  ", Points{0}, limits).error() == Error::kReasonRequired, "thiếu người làm");
    context.expect(admin_step(Points{500}, "xuống\ndòng", "gm", Points{0}, limits).error() == Error::kReasonRequired,
        "lý do có ký tự điều khiển");
    context.expect(admin_step(Points{0}, "ok", "gm", Points{0}, limits).error() == Error::kBadAmount, "delta 0");
    context.expect(admin_step(Points{100001}, "ok", "gm", Points{0}, limits).error() == Error::kBadAmount, "quá trần");
    context.expect(admin_step(Points{-101}, "ok", "gm", Points{100}, limits).error() == Error::kInsufficient, "âm quá số dư");
    context.expect(admin_step(Points{INT64_MIN}, "ok", "gm", Points{100}, limits).error() == Error::kBadAmount, "int64 min");
    context.expect(admin_step(Points{1}, "ok", "gm", Points{limits.max_balance}, limits).error() == Error::kBadAmount,
        "vượt trần số dư");
    context.expect(credit_step(Points{5}, Points{limits.max_balance - 5}, limits).has_value(), "chạm đúng trần");
    context.expect(!credit_step(Points{6}, Points{limits.max_balance - 5}, limits), "vượt trần");
    context.expect(!credit_step(Points{0}, Points{1}, limits), "cộng 0");
    context.expect(token_ok("alpha-1.x_Y", 32) && !token_ok("", 32) && !token_ok("a b", 32) && !token_ok("é", 32),
        "token");
    context.expect(currency_ok("VND") && !currency_ok("vnd") && !currency_ok("VN"), "tiền tệ");
    context.expect(parse_ipv4("10.0.0.255") == std::uint32_t{0x0A0000FF}, "ipv4 hợp lệ");
    context.expect(!parse_ipv4("10.0.0") && !parse_ipv4("10.0.0.256") && !parse_ipv4("010.0.0.1") && !parse_ipv4("a.b.c.d") &&
            !parse_ipv4("1.2.3.4 "),
        "ipv4 hỏng");
    const auto trimmed = clean_text("  lý do  ", 20);
    context.expect(trimmed && *trimmed == "lý do", "cắt khoảng trắng, giữ UTF-8");
    context.expect(!clean_text("0123456789", 5), "quá dài");
}

// ---- code ----------------------------------------------------------------------------------------

void code_roundtrip(Context& context) {
    Counter counter;
    const std::optional<std::string> code = mint_code({.fill = &fill_counter, .context = &counter});
    context.expect(code == std::optional<std::string>{"ABCDEFGHJKMNPQRS"}, "byte 0..15 ra 16 chữ đầu của bảng");
    if (!code) return;
    context.expect(format_code(*code) == "ABCD-EFGH-JKMN-PQRS", "định dạng bốn nhóm");
    context.expect(normalize_code("abcd-efgh jkmn-pqrs") == code, "chữ thường, dấu gạch và khoảng trắng");
    context.expect(!normalize_code("ABCD-EFGH-JKMN-PQR"), "thiếu ký tự");
    context.expect(!normalize_code("ABCD-EFGH-JKMN-PQRST"), "thừa ký tự");
    for (const std::string_view bad : {"O", "I", "L", "0", "1", "!", "é"}) {
        const std::string typed = std::string{"ABCDEFGHJKMNPQR"} + std::string{bad};
        context.expect(!normalize_code(typed), std::format("ký tự dễ nhầm '{}' bị từ chối", bad));
    }
    context.expect(!normalize_code(std::string(200, 'A')), "chuỗi dài quá trần");
    // SHA-256("TLBB-CODE-1:ABCDEFGHJKMNPQRS"), tính bằng Python hashlib.
    context.expect(hash_code(*code) == "73e188ac9492cb5a98368a050dc4d88c26d317a47c2d49613f0bb765d20c2374", "băm mã");
    context.expect(!mint_code({.fill = &fill_ones, .context = nullptr}), "toàn byte bị loại thì thất bại, không treo");
    context.expect(!mint_code({.fill = &fill_fail, .context = nullptr}), "hết entropy");
    context.expect(!mint_code({}), "không có nguồn");
    // Mỗi mã dùng 16 trong 32 byte nên bộ đếm tuần tự chỉ phủ 23 chữ; dùng nguồn giả ngẫu nhiên cố định hạt.
    script::Rng sweep(7);
    std::set<char> seen;
    for (int index = 0; index < 200; ++index) {
        const std::optional<std::string> minted = mint_code({.fill = &fill_rng, .context = &sweep});
        if (!minted) continue;
        seen.insert(minted->begin(), minted->end());
    }
    const auto distinct = std::ranges::count_if(kCodeAlphabet, [&](char c) { return seen.contains(c); });
    context.expect(distinct == 31 && seen.size() == 31, "đủ 31 chữ và không chữ nào ngoài bảng");
}

// ---- throttle --------------------------------------------------------------------------------------

void throttle_schedule(Context& context) {
    // 10 lượt mỗi giờ: hồi một lượt mỗi 72000 / 10 = 7200 tick.
    TokenBuckets bucket({.per_hour = 10, .max_keys = 16});
    const ids::Tick zero{0};
    for (int index = 0; index < 10; ++index)
        context.expect(bucket.take(1, zero), "mười lượt đầu");
    context.expect(!bucket.take(1, zero), "lượt thứ mười một");
    context.expect(!bucket.take(1, ids::Tick{7199}), "chưa hồi");
    context.expect(bucket.take(1, ids::Tick{7200}), "hồi đúng một lượt");
    context.expect(!bucket.take(1, ids::Tick{7200}), "hết lại");
    context.expect(!bucket.take(1, ids::Tick{14399}), "lượt kế phải đợi tới 14400");
    context.expect(bucket.take(1, ids::Tick{14400}), "lượt kế");
    context.expect(bucket.take(2, zero), "khoá khác độc lập");
    context.expect(!bucket.take(1, ids::Tick{100}), "tick lùi không hồi thêm");
    // Sau đúng một giờ đầy lại cả mười.
    int after_hour = 0;
    for (int index = 0; index < 12; ++index) {
        if (bucket.take(1, ids::Tick{14400 + 72000})) ++after_hour;
    }
    context.expect(after_hour == 10, "một giờ sau đầy mười lượt");

    TokenBuckets never({.per_hour = 0, .max_keys = 4});
    context.expect(!never.take(1, zero), "0 lượt mỗi giờ là cấm hẳn");

    // Trần số khoá: hai khoá đầy, khoá thứ ba bị từ chối; sau một giờ khoá cũ đã đầy nên bị dọn nhường chỗ.
    TokenBuckets small({.per_hour = 10, .max_keys = 2});
    context.expect(small.take(1, zero) && small.take(2, zero), "hai khoá");
    context.expect(!small.take(3, zero), "khoá thứ ba bị từ chối khi bảng đầy và chưa khoá nào hồi đầy");
    context.expect(small.take(3, ids::Tick{72000}), "sau một giờ dọn được chỗ");
    context.expect(small.size() <= 2, "bảng không vượt trần");

    RedeemThrottle both({.account_per_hour = 2, .ip_per_hour = 5, .max_keys = 8});
    context.expect(both.take(1, 100, zero) && both.take(1, 100, zero), "hai lượt của tài khoản");
    context.expect(!both.take(1, 101, zero), "tài khoản hết lượt dù IP khác");
    context.expect(both.take(2, 100, zero) && both.take(3, 100, zero) && both.take(4, 100, zero),
        "IP còn lượt cho tài khoản khác");
}

// ---- HTTP ------------------------------------------------------------------------------------------

[[nodiscard]] std::string sample_request(std::string_view body = "a=1") {
    return std::format("POST /hooks/alpha HTTP/1.1\r\nHost: x\r\nContent-Type: application/x-www-form-urlencoded\r\n"
                       "Content-Length: {}\r\nX-Timestamp: 1700000000\r\nX-Signature: {}\r\n\r\n{}",
        body.size(), std::string(64, 'a'), body);
}

void http_parse(Context& context) {
    const std::string good = sample_request("trade_no=T1&account=7");
    const http::Parsed parsed = http::parse(good);
    context.expect(parsed.state == http::Parsed::State::kDone, "yêu cầu hợp lệ");
    context.expect(parsed.request.path == "/hooks/alpha" && parsed.request.timestamp == 1'700'000'000 &&
            parsed.request.body == "trade_no=T1&account=7" && parsed.request.signature == std::string(64, 'a') &&
            parsed.consumed == good.size(),
        "các trường");
    // Mọi tiền tố ngắn hơn đều cần thêm byte, không bao giờ từ chối hay xong sớm.
    bool prefixes_wait = true;
    for (std::size_t cut = 0; cut < good.size(); ++cut) {
        const http::Parsed partial = http::parse(std::string_view{good}.substr(0, cut));
        if (partial.state != http::Parsed::State::kNeedMore) prefixes_wait = false;
    }
    context.expect(prefixes_wait, "tiền tố chưa đủ thì chờ");
    // Byte thừa sau thân bị bỏ qua nhưng không tính vào consumed.
    const http::Parsed extra = http::parse(good + "GET / HTTP/1.1\r\n\r\n");
    context.expect(extra.state == http::Parsed::State::kDone && extra.consumed == good.size(), "byte thừa");
    context.expect(http::parse(std::format("POST /hooks/alpha HTTP/1.0\r\nContent-Type: application/x-www-form-urlencoded;"
                                           " charset=utf-8\r\nContent-Length: 0\r\nX-Timestamp: 5\r\nX-Signature: {}\r\n\r\n",
                       std::string(64, 'b')))
                .state == http::Parsed::State::kDone,
        "HTTP/1.0, charset, thân rỗng");
}

[[nodiscard]] http::Status reject_of(std::string_view data) {
    const http::Parsed parsed = http::parse(data);
    return parsed.state == http::Parsed::State::kReject ? parsed.reject : http::Status::kOk;
}

[[nodiscard]] std::string replace_once(std::string text, std::string_view from, std::string_view to) {
    const std::size_t at_index = text.find(from);
    if (at_index != std::string::npos) text.replace(at_index, from.size(), to);
    return text;
}

void http_reject(Context& context) {
    const std::string good = sample_request();
    using S = http::Status;
    context.expect(reject_of(replace_once(good, "POST", "GET")) == S::kMethodNotAllowed, "GET");
    context.expect(reject_of(replace_once(good, "HTTP/1.1", "HTTP/2")) == S::kBadRequest, "phiên bản lạ");
    context.expect(reject_of(replace_once(good, "/hooks/alpha", "/hooks/alpha?x=1")) == S::kBadRequest, "query");
    context.expect(reject_of(replace_once(good, "/hooks/alpha", "/hooks/%61lpha")) == S::kBadRequest, "phần trăm trong đường dẫn");
    context.expect(reject_of(replace_once(good, "/hooks/alpha", "hooks")) == S::kBadRequest, "đường dẫn không bắt đầu bằng '/'");
    context.expect(reject_of(replace_once(good, "Content-Length: 3", "Transfer-Encoding: chunked\r\nContent-Length: 3")) ==
            S::kBadRequest,
        "chunked");
    context.expect(reject_of(replace_once(good, "Host: x", "Expect: 100-continue")) == S::kBadRequest, "Expect");
    context.expect(reject_of(replace_once(good, "Host: x", "Content-Length: 3")) == S::kBadRequest, "Content-Length lặp");
    context.expect(reject_of(replace_once(good, "Content-Length: 3", "Content-Length: +3")) == S::kBadRequest, "dấu cộng");
    context.expect(reject_of(replace_once(good, "Content-Length: 3", "Content-Length: 123456")) == S::kBadRequest,
        "quá năm chữ số");
    context.expect(reject_of(replace_once(good, "Content-Length: 3", "Content-Length: 4097")) == S::kTooLarge, "thân quá 4 KiB");
    context.expect(reject_of(replace_once(good, "Content-Length: 3\r\n", "")) == S::kLengthRequired, "thiếu độ dài");
    context.expect(reject_of(replace_once(good, "X-Signature", "X-Sig")) == S::kUnauthorized, "thiếu chữ ký");
    context.expect(reject_of(replace_once(good, "X-Timestamp: 1700000000\r\n", "")) == S::kUnauthorized, "thiếu mốc thời gian");
    context.expect(reject_of(replace_once(good, std::string(64, 'a'), std::string(64, 'A'))) == S::kBadRequest, "hex hoa");
    context.expect(reject_of(replace_once(good, std::string(64, 'a'), std::string(63, 'a'))) == S::kBadRequest, "hex thiếu");
    context.expect(reject_of(replace_once(good, "application/x-www-form-urlencoded", "application/json")) == S::kBadRequest,
        "kiểu nội dung lạ");
    context.expect(reject_of(replace_once(good, "Content-Type: application/x-www-form-urlencoded\r\n", "")) == S::kBadRequest,
        "thiếu kiểu nội dung");
    context.expect(reject_of(replace_once(good, "Host: x\r\n", "Host: x\n")) == S::kBadRequest, "LF trần");
    context.expect(reject_of(replace_once(good, "Host: x\r\n", "Host: x\r")) == S::kBadRequest, "CR trần");
    context.expect(reject_of(replace_once(good, "Host: x", "Host: \x01x")) == S::kBadRequest, "byte điều khiển");
    context.expect(reject_of(replace_once(good, "Host: x", "Host: é")) == S::kBadRequest, "byte ngoài ASCII");
    context.expect(reject_of(replace_once(good, "Host: x", "Host x")) == S::kBadRequest, "dòng tiêu đề không có ':'");
    context.expect(reject_of(replace_once(good, "Host: x", " Host: x")) == S::kBadRequest, "gập dòng");
    context.expect(reject_of(replace_once(good, "Host: x", "Host: " + std::string(257, 'v'))) == S::kHeaderTooLarge,
        "giá trị tiêu đề quá dài");
    std::string many = good;
    for (int index = 0; index < 40; ++index)
        many = replace_once(many, "Host: x\r\n", std::format("Host: x\r\nH{}: v\r\n", index));
    context.expect(reject_of(many) == S::kHeaderTooLarge, "quá nhiều tiêu đề");
    context.expect(reject_of(std::string(http::kHeadMost + 10, 'A')) == S::kHeaderTooLarge, "đầu quá 4 KiB không có dòng trống");
    // Trần chờ: không có dòng trống nhưng chưa quá trần thì chờ tiếp.
    context.expect(http::parse(std::string(100, 'A')).state == http::Parsed::State::kNeedMore, "đầu chưa xong");
}

void http_fuzz(Context& context) {
    const std::string good = sample_request("trade_no=T1&account=7&points=5");
    script::Rng rng(0xC0FFEE);
    int done = 0;
    for (int round = 0; round < 20000; ++round) {
        std::string mutated = good;
        const std::uint64_t edits = 1 + rng.below(4);
        for (std::uint64_t edit = 0; edit < edits; ++edit) {
            const std::size_t pos = rng.below(mutated.size());
            switch (rng.below(3)) {
            case 0: mutated[pos] = static_cast<char>(rng.below(256)); break;
            case 1: mutated.erase(pos, 1 + rng.below(4)); break;
            default: mutated.insert(pos, 1, static_cast<char>(rng.below(256))); break;
            }
            if (mutated.empty()) mutated = "x";
        }
        const http::Parsed parsed = http::parse(mutated);
        if (parsed.state != http::Parsed::State::kDone) continue;
        ++done;
        bool sane = parsed.consumed <= mutated.size() && parsed.request.body.size() <= http::kBodyMost &&
            parsed.request.path.size() <= http::kTargetMost && parsed.request.signature.size() == 64 &&
            !parsed.request.path.empty() && parsed.request.path.front() == '/';
        for (const char c : parsed.request.path) {
            if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '/' || c == '_' ||
                    c == '.' || c == '-')) {
                sane = false;
            }
        }
        context.expect(sane, "yêu cầu đã chấp nhận luôn nằm trong miền");
    }
    context.expect(done > 100, "fuzz có đi qua nhánh chấp nhận");
}

void form_parse(Context& context) {
    const auto fields = http::parse_form("a=1&b_c=x%20y+z&d=");
    context.expect(fields && fields->size() == 3 && (*fields)[1].second == "x y z" && (*fields)[2].second.empty(), "cơ bản");
    const auto blank = http::parse_form("");
    context.expect(blank && blank->empty(), "thân rỗng");
    context.expect(!http::parse_form("a=1&a=2"), "khoá lặp");
    context.expect(!http::parse_form("a"), "không có '='");
    context.expect(!http::parse_form("a=1&"), "dư '&'");
    context.expect(!http::parse_form("A=1"), "khoá viết hoa");
    context.expect(!http::parse_form("a=%2"), "phần trăm cụt");
    context.expect(!http::parse_form("a=%zz"), "phần trăm không phải hex");
    context.expect(!http::parse_form("a=%00"), "NUL");
    context.expect(!http::parse_form("a=%0a"), "xuống dòng");
    context.expect(!http::parse_form("a=" + std::string(129, 'x')), "giá trị quá dài");
    std::string seventeen;
    for (int index = 0; index < 17; ++index) {
        if (index != 0) seventeen += '&';
        seventeen += std::string(1, static_cast<char>('a' + index)) + "=1";
    }
    context.expect(!http::parse_form(seventeen), "quá 16 cặp");
}

// ---- webhook ---------------------------------------------------------------------------------------

[[nodiscard]] ProviderKey sequence_key(std::uint8_t first = 0) {
    ProviderKey key{};
    std::uint8_t next = first;
    for (std::byte& slot : key)
        slot = static_cast<std::byte>(next++);
    return key;
}

constexpr std::string_view kBody = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=paid";

void webhook_signature(Context& context) {
    const ProviderKey key = sequence_key();
    const std::string tag = sign_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody});
    // HMAC-SHA512 rút còn 32 byte đầu, tính bằng Python hmac/hashlib trên cùng thông điệp.
    context.expect(tag == "22a8dbcccfdf586d9642ba24e3e12343540bfa58a3898b8bff91c7cac0e6f49b", "chữ ký vàng");
    context.expect(verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody}, tag), "đúng");
    context.expect(!verify_webhook(key, {.path = "/hooks/beta", .timestamp = 1'700'000'000, .body = kBody}, tag), "đổi đường dẫn");
    context.expect(!verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'001, .body = kBody}, tag), "đổi mốc thời gian");
    context.expect(!verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = std::string{kBody} + "x"}, tag), "đổi thân");
    context.expect(!verify_webhook(sequence_key(1), {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody}, tag), "khoá khác");
    std::string flipped = tag;
    flipped[10] = flipped[10] == '0' ? '1' : '0';
    context.expect(!verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody}, flipped), "lật một ký tự hex");
    context.expect(!verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody}, tag.substr(1)), "thiếu độ dài");
    context.expect(!verify_webhook(key, {.path = "/hooks/alpha", .timestamp = 1'700'000'000, .body = kBody}, std::string(64, 'g')), "ký tự không phải hex");
    const auto parsed = parse_provider_key("000102030405060708090A0B0C0D0E0F101112131415161718191a1b1c1d1e1f\n");
    context.expect(parsed && *parsed == key, "khoá từ hex hỗn hợp hoa thường kèm xuống dòng");
    context.expect(!parse_provider_key("00") && !parse_provider_key(std::string(64, 'z')), "khoá hỏng");
}

// Một lần nhà cung cấp gọi webhook: offset lệch đồng hồ billing, stamp_offset lệch mốc ký.
struct Delivery {
    std::string_view provider;
    std::string_view body;
    std::int64_t offset = 0;
    std::int64_t stamp_offset = 0;
};

struct Hook {
    MemoryBook book{test_config()};
    Webhooks hooks;

    Hook()
        : hooks(
              [] {
                  std::vector<WebhookProvider> list;
                  list.push_back({.name = "alpha", .path = "/hooks/alpha", .key = sequence_key(0)});
                  list.push_back({.name = "beta", .path = "/hooks/beta", .key = sequence_key(100)});
                  return list;
              }(),
              300) {}

    [[nodiscard]] WebhookAnswer post(const Delivery& delivery) {
        const std::string path = std::format("/hooks/{}", delivery.provider);
        const ProviderKey key = sequence_key(delivery.provider == "alpha" ? 0 : 100);
        http::Request request;
        request.path = path;
        request.timestamp = kT0 + delivery.stamp_offset;
        request.body = std::string{delivery.body};
        request.signature = sign_webhook(key, {.path = path, .timestamp = request.timestamp, .body = request.body});
        return hooks.handle(book, request, at(delivery.offset));
    }
};

void webhook_flow(Context& context) {
    Hook hook;
    constexpr std::string_view kPaid = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=paid";
    const WebhookAnswer first = hook.post({.provider = "alpha", .body = kPaid});
    context.expect(first.status == http::Status::kOk && first.body == "ok", "lần đầu");
    context.expect(hook.book.balance(kA)->available.value() == 500, "đã cộng 500");
    const WebhookAnswer again = hook.post({.provider = "alpha", .body = kPaid});
    context.expect(again.status == http::Status::kOk && again.body == "duplicate", "gọi lại");
    context.expect(hook.book.balance(kA)->available.value() == 500, "gọi lại không cộng hai lần");
    // Cùng mã giao dịch ở nhà cung cấp khác là đơn khác.
    const WebhookAnswer other = hook.post({.provider = "beta", .body = kPaid});
    context.expect(other.body == "ok" && hook.book.balance(kA)->available.value() == 1000, "khoá có cả nhà cung cấp");
    const WebhookAnswer mismatch =
        hook.post({.provider = "alpha", .body = "trade_no=T1&account=7&points=501&amount=50000&currency=VND&status=paid"});
    context.expect(mismatch.status == http::Status::kConflict && mismatch.body == "conflict", "cùng mã khác số điểm");
    const WebhookAnswer late = hook.post({.provider = "alpha", .body = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=pending"});
    context.expect(late.status == http::Status::kOk && late.body == "ignored", "báo chờ tới muộn");
    const WebhookAnswer contradict =
        hook.post({.provider = "alpha", .body = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=failed"});
    context.expect(contradict.status == http::Status::kConflict, "đã trả rồi báo hỏng");
    const WebhookAnswer refund =
        hook.post({.provider = "alpha", .body = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=refunded"});
    context.expect(refund.status == http::Status::kOk && hook.book.balance(kA)->available.value() == 500, "nhà cung cấp hoàn");
    // Chữ ký và định tuyến.
    http::Request forged;
    forged.path = "/hooks/alpha";
    forged.timestamp = kT0;
    forged.body = std::string{kPaid};
    forged.signature = std::string(64, '0');
    context.expect(hook.hooks.handle(hook.book, forged, at(0)).status == http::Status::kUnauthorized, "chữ ký giả");
    forged.path = "/hooks/zzz";
    context.expect(hook.hooks.handle(hook.book, forged, at(0)).status == http::Status::kNotFound, "đường dẫn lạ");
    context.expect(hook.post({.provider = "alpha", .body = kPaid, .offset = 301, .stamp_offset = 0}).status == http::Status::kUnauthorized, "mốc quá cũ");
    context.expect(hook.post({.provider = "alpha", .body = kPaid, .offset = 0, .stamp_offset = 301}).status == http::Status::kUnauthorized, "mốc ở tương lai quá xa");
    // Đơn T1 đã hoàn nên báo paid tới sau chỉ bị bỏ qua; điều cần thấy là mốc đúng biên không bị 401.
    context.expect(hook.post({.provider = "alpha", .body = kPaid, .offset = 300, .stamp_offset = 0}).body == "ignored", "đúng biên độ lệch");
    // Thân hỏng (đã ký đúng).
    constexpr std::array<std::string_view, 13> kBadBodies{
        "trade_no=T2&account=7&points=500&amount=50000&currency=VND",
        "trade_no=T2&account=7&points=500&amount=50000&currency=VND&status=paid&extra=1",
        "trade_no=T2&account=x&points=500&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=7&points=-5&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=7&points=0&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=7&points=99999999&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=7&points=500&amount=50000&currency=vnd&status=paid",
        "trade_no=T2&account=7&points=500&amount=50000&currency=VND&status=PAID",
        "trade_no=%00&account=7&points=500&amount=50000&currency=VND&status=paid",
        "trade_no=T 2&account=7&points=500&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=0&points=500&amount=50000&currency=VND&status=paid",
        "trade_no=T2&account=99999999999999999999&points=500&amount=50000&currency=VND&status=paid",
        "",
    };
    for (const std::string_view body : kBadBodies) {
        const WebhookAnswer answer = hook.post({.provider = "alpha", .body = body});
        context.expect(answer.status == http::Status::kUnprocessable, std::format("thân hỏng: {}", body));
    }
    context.expect(hook.book.balance(kA)->available.value() == 500, "thân hỏng không đổi số dư");
}

// ---- MemoryBook ------------------------------------------------------------------------------------

[[nodiscard]] scenario::Env memory_env() {
    return scenario::Env{
        .fresh = [] { return std::make_unique<MemoryBook>(test_config()); },
        .corrupt = [](Book& book, AccountId account, Points value) {
            dynamic_cast<MemoryBook&>(book).corrupt_cache_for_test(account, value);
        }};
}

void memory_topup_exchange(Context& context) { scenario::topup_exchange(context, memory_env()); }
void memory_redeem_and_grants(Context& context) { scenario::redeem_and_grants(context, memory_env()); }
void memory_admin_spend_audit(Context& context) { scenario::admin_spend_audit(context, memory_env()); }
void memory_text_fields(Context& context) { scenario::text_fields(context, memory_env()); }

// ---- ipc -------------------------------------------------------------------------------------------

struct Rig {
    MemoryBook book{test_config()};
    BookConfig config = test_config();
    RedeemThrottle throttle{{.account_per_hour = 3, .ip_per_hour = 1000, .max_keys = 64}};
    Counter counter;
    std::int64_t now = kT0;
    std::uint64_t tick = 0;

    [[nodiscard]] Reply call(const Request& request) {
        const Dispatch dispatch{.book = &book,
            .throttle = &throttle,
            .config = &config,
            .random = {.fill = &fill_counter, .context = &counter},
            .now = UnixTime{now},
            .tick = ids::Tick{tick}};
        return handle(dispatch, request);
    }
};

void rpc_roundtrip(Context& context) {
    Rig rig;
    context.expect(rpc::read_balance(rig.call(rpc::balance(kA)))->available.value() == 0, "số dư tài khoản mới");
    context.expect(rpc::read_balance(rig.call(rpc::ensure_account(kA)))->available.value() == 100, "quà đăng ký");
    context.expect(rig.book.apply_payment(paid("T1", kA, 700), at(0)).has_value(), "bước chuẩn bị");
    const Result<Quote> quote = rpc::read_quote(rig.call(rpc::quote(Ingot{10})));
    context.expect(quote && quote->cost.value() == 34 && quote->ingot_per_point == 3 && quote->max_ingot == 500000 &&
            quote->min_ingot == 1,
        "báo giá");
    context.expect(rpc::read_quote(rig.call(rpc::quote(Ingot{0}))).error() == Error::kBadAmount, "báo giá 0 ingot");

    const ExchangeRequest begin{.account = kA, .character = CharacterId{70}, .request = RequestId{1}, .ingot = Ingot{10}};
    const Result<ExchangeOutcome> began = rpc::read_exchange_outcome(rig.call(rpc::exchange_begin(begin)));
    context.expect(began && began->order.points.value() == 34 && !began->replayed && began->balance.value() == 766,
        "pha một qua ipc");
    context.expect(rpc::read_exchange_outcome(rig.call(rpc::exchange_begin(begin)))->replayed, "gọi lại qua ipc");
    const Result<std::vector<ExchangeOrder>> open = rpc::read_exchange_list(rig.call(rpc::exchange_open(50)));
    context.expect(open && open->size() == 1 && open->front().id == began->order.id, "danh sách mở");
    context.expect(rpc::read_exchange(rig.call(rpc::find_exchange(began->order.id)))->status == ExchangeStatus::kPending, "tra đơn");
    const Result<ExchangeOutcome> end = rpc::read_exchange_outcome(rig.call(rpc::exchange_finish(began->order.id, Verdict::kDone)));
    context.expect(end && end->order.status == ExchangeStatus::kConfirmed, "pha hai qua ipc");
    context.expect(rpc::read_exchange_outcome(rig.call(rpc::exchange_finish(began->order.id, Verdict::kCancelled))).error() ==
            Error::kBadState,
        "lỗi nghiệp vụ đi qua mã");
    rig.now += 700;
    context.expect(rpc::read_count(rig.call(rpc::exchange_sweep())).value() == 0, "quét không có đơn");

    // Chỉnh tay, hoàn, tra đơn.
    context.expect(rpc::read_points(rig.call(rpc::admin_adjust(kA, Points{50}, RequestId{1}, {.reason = "bù", .actor = "gm"}))).value().value() == 816,
        "chỉnh tay");
    context.expect(rpc::read_payment(rig.call(rpc::find_payment({.provider = "alpha", .trade_no = "T1"})))->event.points.value() == 700, "tra đơn nạp");
    const Result<PaymentOutcome> refunded = rpc::read_payment_outcome(rig.call(rpc::refund_payment({.provider = "alpha", .trade_no = "T1"}, {.reason = "đòi", .actor = "gm"})));
    context.expect(refunded && refunded->record.event.status == PaymentStatus::kRefunded, "hoàn qua ipc");
    context.expect(rpc::read_done(rig.call(rpc::set_frozen(kA, true, {.reason = "x", .actor = "gm"}))).has_value(), "đóng băng qua ipc");
    context.expect(rpc::read_balance(rig.call(rpc::balance(kA)))->frozen, "cờ đóng băng");
    context.expect(rpc::read_done(rig.call(rpc::set_frozen(kA, false, {.reason = "x", .actor = "gm"}))).has_value(), "mở băng");

    // Đợt mã: tạo, sinh mã, đổi bằng chữ người chơi gõ.
    BatchSpec spec;
    spec.name = "Thử";
    spec.actor = "gm";
    spec.per_account_limit = 5;
    spec.rewards = {Reward{.kind = 0, .ref_id = 0, .quantity = 25}, Reward{.kind = 100, .ref_id = 9, .quantity = 3}};
    const Result<BatchRecord> batch = rpc::read_batch(rig.call(rpc::create_batch(spec)));
    context.expect(batch && batch->spec.rewards.size() == 2 && batch->enabled, "tạo đợt qua ipc");
    const Result<MintedCodes> minted = rpc::read_minted(rig.call(rpc::mint_codes(batch->id, 6, "gm")));
    context.expect(minted && minted->codes.size() == 6 && minted->codes.front().size() == 19, "sinh sáu mã in được");
    std::string typed = minted->codes[0];
    for (char& c : typed) {
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    }
    const Result<RedeemOutcome> redeemed = rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = typed})));
    context.expect(redeemed && redeemed->points.value() == 25 && redeemed->grants.size() == 1, "đổi mã gõ chữ thường");
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = minted->codes[0]}))).error() == Error::kCodeUsed, "mã dùng rồi");
    // Bộ đếm: ba lượt mỗi giờ cho một tài khoản (Rig), lượt đầu và lượt trên đã dùng hai.
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = "ZZZZ-ZZZZ-ZZZZ-ZZZZ"}))).error() == Error::kBadCode,
        "mã không tồn tại");
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = minted->codes[1]}))).error() == Error::kRateLimited,
        "lượt thứ tư trong giờ bị chặn dù mã đúng");
    rig.tick += 72000;
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = minted->codes[1]}))).has_value(), "một giờ sau lại đổi được");
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "10.0.0.5", .code = "???"}))).error() == Error::kBadCode, "hình dạng sai tính là một lượt");
    context.expect(rpc::read_redeem(rig.call(rpc::redeem(kB, {.ip = "nope", .code = minted->codes[2]}))).error() == Error::kMalformed, "ip sai");
    context.expect(rpc::read_minted(rig.call(rpc::mint_codes(batch->id, 0, "gm"))).error() == Error::kTooMany, "sinh 0 mã");
    context.expect(rpc::read_minted(rig.call(rpc::mint_codes(batch->id, 301, "gm"))).error() == Error::kTooMany, "sinh quá 300");
    context.expect(rpc::read_minted(rig.call(rpc::mint_codes(batch->id, 3, " "))).error() == Error::kReasonRequired, "thiếu người làm");
    context.expect(rpc::read_done(rig.call(rpc::set_batch_enabled(batch->id, false, "gm"))).has_value(), "tắt đợt");

    // Quà.
    const Result<std::vector<GrantRecord>> grants = rpc::read_grant_list(rig.call(rpc::grant_list(kB, 10)));
    context.expect(grants && grants->size() == 2, "hai quà (hai mã đã đổi)");
    const Result<GrantClaimed> claimed = rpc::read_grant_claimed(rig.call(rpc::grant_claim(grants->front().id, kB, CharacterId{80})));
    context.expect(claimed.has_value(), "nhận quà qua ipc");
    context.expect(rpc::read_grant_orders(rig.call(rpc::grant_open(10)))->size() == 1, "đơn giao mở");
    context.expect(rpc::read_grant_finished(rig.call(rpc::grant_finish(claimed->order.id, Verdict::kDone)))->grant.status ==
            GrantStatus::kDelivered,
        "giao xong qua ipc");
    const GrantSpec manual{.account = kB, .kind = GrantKind::kCoin, .ref_id = 0, .quantity = 5000, .source = "prize",
        .reason = "thưởng", .actor = "gm"};
    context.expect(rpc::read_grant(rig.call(rpc::grant_add(manual)))->kind == GrantKind::kCoin, "quà tay qua ipc");

    // Tiêu ingot, báo cáo.
    const std::array<SpendEvent, 2> events{SpendEvent{.event = 1, .account = kA, .character = CharacterId{70}, .amount = Ingot{40}},
        SpendEvent{.event = 2, .account = kA, .character = CharacterId{70}, .amount = Ingot{10}}};
    context.expect(rpc::read_spend_summary(rig.call(rpc::spend_record(events)))->recorded == 2, "ghi tiêu qua ipc");
    context.expect(rpc::read_headroom(rig.call(rpc::spend_headroom(CharacterId{70})))->remaining.value() == 950, "còn lại");
    const Result<Conservation> check = rpc::read_conservation(rig.call(rpc::ledger_check()));
    context.expect(check && check->balanced, "đối soát qua ipc");
    context.expect(rpc::read_points(rig.call(rpc::rebuild_balance(kA, "gm"))).has_value(), "dựng lại qua ipc");
    const Result<DayReport> day = rpc::read_day_report(rig.call(rpc::day_report(kT0 / kSecondsPerDay)));
    context.expect(day && day->ingot_spent.value() == 50, "báo cáo ngày qua ipc");
    const Result<std::vector<LedgerEntry>> tail = rpc::read_ledger_tail(rig.call(rpc::ledger_tail(kA, 500)));
    context.expect(tail && !tail->empty() && tail->size() <= kLedgerTailWireMost, "đuôi sổ có trần trên dây");
}

[[nodiscard]] std::vector<Request> sample_requests() {
    BatchSpec spec;
    spec.name = "Thử";
    spec.actor = "gm";
    spec.rewards = {Reward{.kind = 0, .ref_id = 0, .quantity = 5}};
    const std::array<SpendEvent, 1> events{SpendEvent{.event = 1, .account = kA, .character = CharacterId{70}, .amount = Ingot{4}}};
    return {rpc::balance(kA), rpc::ensure_account(kA), rpc::set_frozen(kA, true, {.reason = "lý do", .actor = "gm"}), rpc::quote(Ingot{5}),
        rpc::exchange_begin({.account = kA, .character = CharacterId{70}, .request = RequestId{1}, .ingot = Ingot{5}}), rpc::exchange_finish(ExchangeId{1}, Verdict::kDone),
        rpc::exchange_open(10), rpc::find_exchange(ExchangeId{1}), rpc::redeem(kA, {.ip = "10.0.0.1", .code = "ABCD-EFGH-JKMN-PQRS"}),
        rpc::grant_list(kA, 10), rpc::grant_claim(GrantId{1}, kA, CharacterId{70}),
        rpc::grant_finish(GrantOrderId{1}, Verdict::kDone), rpc::grant_open(10),
        rpc::grant_add({.account = kA, .kind = GrantKind::kCoin, .ref_id = 0, .quantity = 5, .source = "prize", .reason = "lý do", .actor = "gm"}),
        rpc::admin_adjust(kA, Points{5}, RequestId{1}, {.reason = "lý do", .actor = "gm"}), rpc::refund_payment({.provider = "alpha", .trade_no = "T1"}, {.reason = "lý do", .actor = "gm"}),
        rpc::find_payment({.provider = "alpha", .trade_no = "T1"}), rpc::create_batch(spec), rpc::set_batch_enabled(BatchId{1}, true, "gm"),
        rpc::mint_codes(BatchId{1}, 2, "gm"), rpc::spend_record(events), rpc::spend_headroom(CharacterId{70}),
        rpc::rebuild_balance(kA, "gm"), rpc::day_report(19000), rpc::ledger_tail(kA, 5)};
}

void rpc_hostile(Context& context) {
    Rig rig;
    rig.config.limits = support::test_limits();
    std::int64_t handled = 0;
    for (const Request& request : sample_requests()) {
        // Mọi tiền tố ngắn hơn: kMalformed, không bao giờ thành công, không đổi sổ.
        for (std::size_t cut = 0; cut < request.body.size(); ++cut) {
            const Request truncated{.op = request.op,
                .body = std::vector<std::byte>(request.body.begin(), request.body.begin() + static_cast<std::ptrdiff_t>(cut))};
            const Reply reply = rig.call(truncated);
            context.expect(reply.code == wire_code(Error::kMalformed),
                std::format("op {} cắt còn {} byte phải là kMalformed, được {}", static_cast<unsigned>(request.op), cut, reply.code));
            ++handled;
        }
        Request padded = request;
        padded.body.push_back(std::byte{0});
        context.expect(rig.call(padded).code == wire_code(Error::kMalformed), "byte thừa cuối thân");
    }
    // Thân ngẫu nhiên cho mọi Op: chỉ cần không sập và mã luôn là mã đã biết.
    script::Rng rng(12345);
    for (std::uint16_t op = 0; op < 40; ++op) {
        for (int round = 0; round < 400; ++round) {
            Request junk{.op = static_cast<Op>(op), .body = {}};
            const std::size_t size = rng.below(80);
            for (std::size_t index = 0; index < size; ++index)
                junk.body.push_back(static_cast<std::byte>(rng.below(256)));
            const Reply reply = rig.call(junk);
            const bool known = reply.code == 0 || error_of(reply.code) != Error::kBusy || reply.code == wire_code(Error::kBusy);
            context.expect(known, "mã trả lời luôn thuộc danh sách");
            if (reply.code == 0) {
                // Thành công trên thân ngẫu nhiên vẫn phải giữ sổ cân.
                context.expect(rig.book.ledger_check()->balanced, "sổ cân sau thân ngẫu nhiên");
            }
            ++handled;
        }
    }
    context.expect(handled > 16000, "đã chạy đủ ca");
    context.expect(rig.call(Request{.op = static_cast<Op>(0), .body = {}}).code == wire_code(Error::kMalformed), "op 0");
    context.expect(rig.call(Request{.op = static_cast<Op>(200), .body = {}}).code == wire_code(Error::kMalformed), "op lạ");

    // Thân giả khai số phần tử khổng lồ: bộ đọc từ chối trước khi cấp phát.
    wire::Writer huge;
    huge.u16(60000);
    const std::vector<std::byte> bytes = huge.take();
    wire::Reader reader{bytes};
    context.expect(reader.count(kListMost, 8) == 0 && !reader.ok(), "số phần tử quá trần");
    wire::Writer lying;
    lying.u16(100);
    const std::vector<std::byte> few = lying.take();
    wire::Reader lie{few};
    context.expect(lie.count(kListMost, 8) == 0 && !lie.ok(), "khai 100 phần tử mà không còn byte");
}

void wire_sizes_fit(Context& context) {
    constexpr std::size_t kFrame = 8192;
    wire::Writer orders;
    for (std::size_t index = 0; index < kListMost; ++index)
        wire::write(orders, ExchangeOrder{.id = ExchangeId{UINT64_MAX}, .account = AccountId{UINT64_MAX}, .character = CharacterId{UINT64_MAX},
            .request = RequestId{UINT64_MAX}, .ingot = Ingot{INT64_MAX}, .points = Points{INT64_MAX}, .status = ExchangeStatus::kStale,
            .created = UnixTime{INT64_MAX}, .updated = UnixTime{INT64_MAX}});
    context.expect(orders.size() + 2 <= kFrame, std::format("100 đơn đổi: {} byte", orders.size() + 2));
    wire::Writer grants;
    for (std::size_t index = 0; index < kListMost; ++index)
        wire::write(grants, GrantRecord{.id = GrantId{UINT64_MAX}, .account = AccountId{UINT64_MAX}, .kind = GrantKind::kItem,
            .ref_id = UINT64_MAX, .quantity = INT64_MAX, .status = GrantStatus::kDelivering, .source = std::string(kSourceMost, 'x'),
            .created = UnixTime{INT64_MAX}});
    context.expect(grants.size() + 2 <= kFrame, std::format("100 quà: {} byte", grants.size() + 2));
    wire::Writer ledger;
    for (std::size_t index = 0; index < kLedgerTailWireMost; ++index)
        wire::write(ledger, LedgerEntry{.id = UINT64_MAX, .account = AccountId{UINT64_MAX}, .delta = Points{INT64_MIN}, .kind = LedgerKind::kAdmin,
            .ref = UINT64_MAX, .reason = std::string(kReasonMost, 'x'), .actor = std::string(kActorMost, 'x'), .at = UnixTime{INT64_MAX}});
    context.expect(ledger.size() + 2 <= kFrame, std::format("{} dòng sổ: {} byte", kLedgerTailWireMost, ledger.size() + 2));
    context.expect((kMintPerCallMost * (19 + 2)) + 2 <= kFrame, "300 mã in được");
    wire::Writer redeem;
    RedeemOutcome outcome;
    for (std::size_t index = 0; index < kRewardsMost; ++index)
        outcome.grants.push_back(GrantRecord{.id = GrantId{1}, .account = kA, .source = std::string(kSourceMost, 'x'), .created = at(0)});
    wire::write(redeem, outcome);
    context.expect(redeem.size() <= kFrame, "kết quả đổi mã đầy phần thưởng");
    wire::Writer batch;
    BatchRecord record;
    record.spec.name = std::string(kBatchNameMost, 'x');
    record.spec.actor = std::string(kActorMost, 'x');
    record.spec.rewards.assign(kRewardsMost, Reward{.kind = 100, .ref_id = UINT64_MAX, .quantity = INT64_MAX});
    wire::write(batch, record);
    context.expect(batch.size() <= kFrame, "bản ghi đợt đầy phần thưởng");
}

// ---- kịch bản lớn ------------------------------------------------------------------------------------

void script_conservation(Context& context) {
    MemoryBook first{test_config()};
    script::Script run_one(first, 20260507);
    const script::Outcome one = run_one.run(1000);
    context.expect(one.balanced && one.mismatched == 0, "sổ cân sau 1000 bước có chèn lỗi");
    const Conservation& c = one.final_check;
    context.expect(c.topped_up.value() + c.other_net.value() ==
            c.balance_sum.value() + c.exchange_confirmed.value() + c.exchange_held.value() + c.refunded.value(),
        "điểm nạp = điểm còn + điểm đã đổi + điểm giữ + hoàn (+ chỉnh tay)");
    // Kịch bản phải thật sự chạm mọi nhánh lỗi, nếu không phép thử vô nghĩa.
    context.expect(one.duplicates > 20 && one.conflicts > 5 && one.replays > 20 && one.refunds > 5 && one.stale > 0 &&
            one.cancelled > 10 && one.confirmed > 30 && one.insufficient > 0,
        std::format("độ phủ: dup={} conf={} replay={} refund={} stale={} cancel={} confirm={} poor={}", one.duplicates, one.conflicts,
            one.replays, one.refunds, one.stale, one.cancelled, one.confirmed, one.insufficient));
    MemoryBook second{test_config()};
    script::Script run_two(second, 20260507);
    context.expect(run_two.run(1000).trace == one.trace, "cùng hạt giống ra cùng vết (tất định)");
    MemoryBook third{test_config()};
    script::Script run_three(third, 99);
    const script::Outcome other = run_three.run(1000);
    context.expect(other.balanced && other.trace != one.trace, "hạt khác ra vết khác nhưng vẫn cân");
}

constexpr std::array kCases{
    Case{.name = "limits_table", .body = limits_table},
    Case{.name = "exchange_cost_golden", .body = exchange_cost_golden},
    Case{.name = "payment_step_table", .body = payment_step_table},
    Case{.name = "finish_steps", .body = finish_steps},
    Case{.name = "redeem_step_order", .body = redeem_step_order},
    Case{.name = "admin_and_credit_steps", .body = admin_and_credit_steps},
    Case{.name = "code_roundtrip", .body = code_roundtrip},
    Case{.name = "throttle_schedule", .body = throttle_schedule},
    Case{.name = "http_parse", .body = http_parse},
    Case{.name = "http_reject", .body = http_reject},
    Case{.name = "http_fuzz", .body = http_fuzz},
    Case{.name = "form_parse", .body = form_parse},
    Case{.name = "webhook_signature", .body = webhook_signature},
    Case{.name = "webhook_flow", .body = webhook_flow},
    Case{.name = "memory_topup_exchange", .body = memory_topup_exchange},
    Case{.name = "memory_redeem_and_grants", .body = memory_redeem_and_grants},
    Case{.name = "memory_admin_spend_audit", .body = memory_admin_spend_audit},
    Case{.name = "memory_text_fields", .body = memory_text_fields},
    Case{.name = "rpc_roundtrip", .body = rpc_roundtrip},
    Case{.name = "rpc_hostile", .body = rpc_hostile},
    Case{.name = "wire_sizes_fit", .body = wire_sizes_fit},
    Case{.name = "script_conservation", .body = script_conservation},
};

} // namespace
} // namespace game::billing

int main() { return game::test::run_all(game::billing::kCases) == 0 ? 0 : 1; }
