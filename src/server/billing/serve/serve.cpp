#include "billing/serve/serve.hpp"

#include "account/rpc.hpp"
#include "billing/book.hpp"
#include "billing/db/pg_book.hpp"
#include "billing/error.hpp"
#include "billing/rpc.hpp"
#include "billing/serve/setup.hpp"
#include "billing/serve/webhook_server.hpp"
#include "billing/throttle.hpp"
#include "billing/types.hpp"
#include "billing/webhook.hpp"
#include "ids/ids.hpp"
#include "net/net.hpp"
#include "process/process.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "store/pg.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <expected>
#include <filesystem>
#include <optional>
#include <print>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>

namespace game::billing {
namespace {

using Clock = std::chrono::steady_clock;

// Khung ipc dùng chung với account tự trả kBusy khi hàng việc đầy; hai bên phải cùng một số.
static_assert(wire_code(Error::kBusy) == static_cast<std::uint16_t>(protocol::ErrorCode::kBusy));
static_assert(wire_code(Error::kRateLimited) == static_cast<std::uint16_t>(protocol::ErrorCode::kRateLimited));

constexpr std::chrono::milliseconds kIdleSleep{20};
// Nhịp của luồng phụ: đủ ngắn để dừng nhanh và để việc định kỳ không lệch quá 100 ms.
constexpr std::chrono::milliseconds kSideBeat{100};
// 20 tick mỗi giây (ids::Tick): một tick là 50 ms.
constexpr std::int64_t kTickMillis = 50;
// Lỗi không phục hồi được của luồng phụ (tập chờ socket hỏng): thoát để trình giám sát chạy lại.
constexpr int kExitSideFailed = 3;

void idle_until_stop() {
    std::println("ready");
    static_cast<void>(std::fflush(stdout));
    while (!process::stop_requested()) {
        std::this_thread::sleep_for(kIdleSleep);
    }
}

[[nodiscard]] UnixTime unix_now() {
    const auto since = std::chrono::system_clock::now().time_since_epoch();
    return UnixTime{std::chrono::duration_cast<std::chrono::seconds>(since).count()};
}

bool os_random(void* /*context*/, std::span<std::byte> out) {
    return secure::fill_random(out);
}

// ---- ipc -------------------------------------------------------------------------------------------

struct IpcCtx {
    PgBook* book = nullptr;
    RedeemThrottle* throttle = nullptr;
    const BookConfig* config = nullptr;
    Clock::time_point origin;
};

// Chữ ký do account::Handler áp đặt (void* ctx); ở đây ngữ cảnh chỉ đọc nên ép về con trỏ const ngay dòng đầu.
// NOLINTNEXTLINE(misc-const-correctness): không đổi được kiểu tham số của Handler (HP-07, DD-08)
[[nodiscard]] account::Reply on_ipc(void* raw, const account::Call& call) {
    const auto* const ctx = static_cast<const IpcCtx*>(raw);
    const auto op = static_cast<std::uint16_t>(call.op);
    // Op của billing là một byte; khung của account mang hai byte nên giá trị lớn hơn là yêu cầu hỏng, không phải
    // một Op bị cắt cụt thành Op khác.
    if (op > 0xFF) return account::Reply{.code = wire_code(Error::kMalformed), .body = {}};
    const std::int64_t elapsed =
        std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - ctx->origin).count();
    const Dispatch dispatch{.book = ctx->book,
        .throttle = ctx->throttle,
        .config = ctx->config,
        .random = {.fill = &os_random, .context = nullptr},
        .now = unix_now(),
        .tick = ids::Tick{static_cast<std::uint64_t>(elapsed / kTickMillis)}};
    Reply reply = handle(dispatch, Request{.op = static_cast<Op>(op), .body = call.body});
    return account::Reply{.code = reply.code, .body = std::move(reply.body)};
}

// ---- việc định kỳ ----------------------------------------------------------------------------------

// Quét đơn đổi quá hạn, đối soát toàn sổ, báo cáo ngày. Chỉ in khi có chuyện: bình thường im lặng. Lỗi database
// in một lần khi bắt đầu lỗi và một lần khi hết lỗi, không in lại mỗi nhịp.
struct Intervals {
    std::chrono::seconds sweep{60};
    std::chrono::seconds check{21600};
};

class Maintenance {
public:
    Maintenance(PgBook& book, Intervals every) : book_(&book), every_(every) {}

    void tick(Clock::time_point now) {
        if (now >= next_sweep_) {
            next_sweep_ = now + every_.sweep;
            sweep();
        }
        const UnixTime wall = unix_now();
        const std::int64_t day = wall.value() / kSecondsPerDay;
        if (now >= next_check_ || day != reported_day_) {
            next_check_ = now + every_.check;
            check();
            report(day);
        }
    }

private:
    void note_failure(bool& failing, std::string_view what) {
        if (!failing) std::println(stderr, "billing: {} lỗi: {}", what, book_->last_error());
        failing = true;
    }

    void note_recovered(bool& failing, std::string_view what) {
        if (failing) std::println(stderr, "billing: {} chạy lại được", what);
        failing = false;
    }

    void sweep() {
        const Result<std::int64_t> swept = book_->exchange_sweep(unix_now());
        if (!swept) {
            note_failure(sweep_failing_, "quét đơn đổi quá hạn");
            return;
        }
        note_recovered(sweep_failing_, "quét đơn đổi quá hạn");
        if (*swept > 0) std::println(stderr, "billing: {} đơn đổi quá hạn sang đối soát", *swept);
    }

    void check() {
        const Result<Conservation> check = book_->ledger_check();
        if (!check) {
            note_failure(check_failing_, "đối soát sổ");
            return;
        }
        note_recovered(check_failing_, "đối soát sổ");
        if (check->balanced) {
            unbalanced_ = false;
            return;
        }
        // Sổ lệch là sự cố nghiêm trọng nhưng không tự sửa: đã có ipc rebuild_balance cho người có quyền. In một
        // lần cho mỗi đợt lệch.
        if (!unbalanced_) {
            std::println(stderr,
                "billing: SỔ ĐIỂM LỆCH: tài khoản lệch bản nhớ đệm={} nạp={} hoàn={} khác={} số dư={} đã đổi={} đang giữ={}",
                check->mismatched_accounts, check->topped_up.value(), check->refunded.value(),
                check->other_net.value(), check->balance_sum.value(), check->exchange_confirmed.value(),
                check->exchange_held.value());
        }
        unbalanced_ = true;
    }

    void report(std::int64_t today) {
        if (today == reported_day_) return;
        // Ngày vừa qua đã trọn vẹn: báo cáo của nó không đổi nữa.
        const Result<DayReport> day = book_->day_report(today - 1);
        if (!day) {
            note_failure(report_failing_, "báo cáo ngày");
            return;
        }
        note_recovered(report_failing_, "báo cáo ngày");
        reported_day_ = today;
        std::println(stderr, "billing: báo cáo ngày {} nạp={} hoàn={} đổi={} ingot cấp={} ingot tiêu={} sự kiện tiêu={} đơn chờ={}",
            today - 1, day->topped_up.value(), day->refunded.value(), day->exchanged.value(),
            day->ingot_issued.value(), day->ingot_spent.value(), day->spend_events, day->open_exchanges);
    }

    PgBook* book_;
    Intervals every_;
    Clock::time_point next_sweep_{};
    Clock::time_point next_check_{};
    std::int64_t reported_day_ = -1;
    bool sweep_failing_ = false;
    bool check_failing_ = false;
    bool report_failing_ = false;
    bool unbalanced_ = false;
};

struct SideCtx {
    PgBook* book = nullptr;
    WebhookServer* server = nullptr;
    Intervals every;
};

void side_main(const std::stop_token& stop, SideCtx ctx) {
    Maintenance maintenance{*ctx.book, ctx.every};
    while (!stop.stop_requested()) {
        if (ctx.server != nullptr) {
            if (!ctx.server->pump(kSideBeat)) {
                std::println(stderr, "billing: tập chờ của webhook hỏng, thoát để chạy lại");
                static_cast<void>(std::fflush(stderr));
                std::quick_exit(kExitSideFailed);
            }
        } else {
            std::this_thread::sleep_for(kSideBeat);
        }
        maintenance.tick(Clock::now());
    }
}

[[nodiscard]] int fail(int code, std::string_view what) {
    std::println(stderr, "billing: {}", what);
    return code;
}

} // namespace

int serve_billing(const std::filesystem::path& config_dir) {
    if (!has_secrets(config_dir)) {
        idle_until_stop();
        return 0;
    }
    std::expected<Setup, SetupFault> loaded = load_setup(config_dir);
    if (!loaded) return fail(loaded.error().exit_code, loaded.error().message);
    Setup setup = std::move(*loaded);

    {
        // Kết nối riêng cho migration: đóng trước khi hai kết nối làm việc mở, nên migration không giữ khoá nào khi
        // dịch vụ bắt đầu nhận việc.
        std::string error;
        std::optional<store::PgConn> conn = store::PgConn::open(setup.login, error);
        if (!conn) return fail(1, error);
        if (!store::migrate(*conn, setup.sql_dir, error)) return fail(1, error);
    }
    PgBook ipc_book{PgOptions{.login = setup.login, .session_setup = {}}, setup.book};
    if (!ipc_book.connect()) return fail(1, ipc_book.last_error());
    PgBook side_book{PgOptions{.login = setup.login, .session_setup = {}}, setup.book};
    if (!side_book.connect()) return fail(1, side_book.last_error());

    const net::NetResult<net::Network> network = net::Network::start();
    if (!network) return fail(1, "không khởi động được mạng");
    net::NetResult<net::TcpListener> ipc_listener = net::TcpListener::open(setup.ipc);
    if (!ipc_listener) return fail(1, "không nghe được cổng ipc");
    const net::NetResult<net::Endpoint> ipc_local = ipc_listener->local();
    if (!ipc_local || ipc_local->port == 0) return fail(1, "không đọc được cổng ipc");

    const Webhooks hooks{std::move(setup.providers), setup.book.limits.webhook_max_skew_seconds};
    std::optional<WebhookServer> webhook;
    if (setup.webhook) {
        net::NetResult<net::TcpListener> listener = net::TcpListener::open(*setup.webhook);
        if (!listener) return fail(1, "không nghe được cổng webhook");
        webhook.emplace(std::move(*listener), hooks, side_book, WebhookServerOptions{});
    }

    RedeemThrottle throttle{setup.redeem};
    IpcCtx ipc{.book = &ipc_book, .throttle = &throttle, .config = &setup.book, .origin = Clock::now()};
    const SideCtx side_ctx{.book = &side_book,
        .server = webhook ? &*webhook : nullptr,
        .every = Intervals{.sweep = setup.reconcile_interval, .check = setup.ledger_check_interval}};

    std::println("ready ipc={}", ipc_local->port);
    static_cast<void>(std::fflush(stdout));
    int code = 0;
    {
        // Luồng phụ dừng và nối lại (jthread) trước khi sổ và webhook bị huỷ.
        std::jthread side{side_main, side_ctx};
        code = account::serve_loop(*ipc_listener, &on_ipc, &ipc, setup.key);
        side.request_stop();
    }
    secure::wipe_bytes(setup.key);
    secure::wipe_bytes(std::as_writable_bytes(std::span{setup.login.password.data(), setup.login.password.size()}));
    return code;
}

} // namespace game::billing
