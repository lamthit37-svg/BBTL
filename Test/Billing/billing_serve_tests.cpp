// Exe thienlong_billing thật trên một database PostgreSQL tạm: ipc (khung của account, khoá ipc.key), webhook HTTP
// trên 127.0.0.1, hai pha đổi điểm, billing bị giết giữa hai pha rồi chạy lại, và một đợt 1.000 đơn nạp có chèn
// lỗi (chữ ký sai, mốc thời gian cũ, đường dẫn lạ, đứt kết nối giữa yêu cầu, gọi lại, mâu thuẫn) trong lúc billing bị
// giết ba lần. Đối soát cuối cùng bằng SQL viết riêng: điểm nạp trong sổ = tổng điểm các đơn đã trả, mỗi đơn đúng một
// lần. Không có role postgres hoặc không nối được PostgreSQL thì từng ca tự bỏ qua.
#include "account/ipc_key.hpp"
#include "account/rpc.hpp"
#include "billing/book.hpp"
#include "billing/error.hpp"
#include "billing/rpc.hpp"
#include "billing/rules.hpp"
#include "billing/serve/client.hpp"
#include "billing/types.hpp"
#include "billing/webhook.hpp"
#include "ids/ids.hpp"
#include "net/net.hpp"
#include "store/pg.hpp"

#include "billing_pg_support.hpp"
#include "billing_script.hpp"
#include "billing_serve_support.hpp"
#include "test.hpp"

#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <format>
#include <memory>
#include <mutex>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

using test::Case;
using test::Context;
namespace sv = test::billing_serve;
namespace pg = test::billing_pg;

constexpr AccountId kSeven{7};

// Một ca: dựng thư mục + database tạm, chạy billingd. Rỗng khi môi trường không đủ (đã in "bỏ qua").
struct Rig {
    std::unique_ptr<sv::Stage> stage;
    std::unique_ptr<sv::Daemon> daemon;
    std::unique_ptr<Client> client;
};

[[nodiscard]] std::optional<Rig> boot(Context& context, std::string_view name, const sv::StageOptions& options = {}) {
    const pg::Access* access = pg::shared_access(name);
    if (access == nullptr) return std::nullopt;
    Rig rig;
    std::string why;
    rig.stage = sv::Stage::create(*access, options, why);
    if (!rig.stage) {
        // Không có role postgres là thiếu môi trường, không phải lỗi mã.
        std::println("[bỏ qua] {}: {}", name, why);
        return std::nullopt;
    }
    rig.daemon = sv::Daemon::start(*rig.stage);
    context.expect(rig.daemon != nullptr, "billingd phải in ready");
    if (!rig.daemon) return std::nullopt;
    rig.client = rig.daemon->client();
    context.expect(rig.client != nullptr, "đọc được ipc.key");
    if (!rig.client) return std::nullopt;
    return rig;
}

// Chạy lại billingd trên cùng thư mục và database (ipc.key và dữ liệu còn nguyên).
[[nodiscard]] bool relaunch(Context& context, Rig& rig) {
    rig.client.reset();
    // Tiến trình cũ phải chết hẳn trước: hai billingd không cùng nghe một cổng webhook.
    if (rig.daemon) rig.daemon->crash();
    rig.daemon.reset();
    rig.daemon = sv::Daemon::start(*rig.stage);
    context.expect(rig.daemon != nullptr, "billingd chạy lại phải in ready");
    if (!rig.daemon) return false;
    rig.client = rig.daemon->client();
    return rig.client != nullptr;
}

[[nodiscard]] Reply ask(const Rig& rig, const Request& request) {
    return rig.client->call(request);
}

// POST một đơn nạp đã ký đúng; status HTTP, 0 khi không có trả lời.
[[nodiscard]] int post_order(const Rig& rig, std::string_view trade, std::uint64_t account, std::int64_t points,
    std::string_view status = "paid") {
    const sv::Delivery delivery{.body = sv::order_body(trade, account, points, status), .timestamp = sv::unix_now()};
    const sv::HttpAnswer answer = sv::http_exchange(rig.stage->webhook_port(), sv::webhook_request(delivery));
    return answer.answered ? answer.status : 0;
}

[[nodiscard]] std::int64_t available_of(const Rig& rig, AccountId account) {
    const Result<Balance> balance = rpc::read_balance(ask(rig, rpc::balance(account)));
    return balance ? balance->available.value() : -1;
}

// ---- khởi động, ipc, dừng ------------------------------------------------------------------------------

void serve_boot_and_ipc(Context& context) {
    std::optional<Rig> rig = boot(context, "serve_boot_and_ipc");
    if (!rig) return;
    context.expect(rig->daemon->ready_line().starts_with("ready ipc="), "dòng sẵn sàng mang cổng ipc");
    context.expect(rig->daemon->ipc_port() != 0, "cổng ipc thật");

    context.expect(available_of(*rig, kSeven) == 0, "tài khoản chưa có: số dư 0");
    const Result<Balance> ensured = rpc::read_balance(ask(*rig, rpc::ensure_account(kSeven)));
    context.expect(ensured && ensured->available.value() == 0, "quà đăng ký của bản thử là 0");
    // ingot_per_point = 1 trong billing.toml của bản thử: 10 ingot = ceil(10 * 10 / 1) = 100 phần mười điểm.
    const Result<Quote> quote = rpc::read_quote(ask(*rig, rpc::quote(Ingot{10})));
    context.expect(quote && quote->cost.value() == 100 && quote->max_ingot == 500000 && quote->min_ingot == 1, "báo giá");

    // Khoá sai: khung không mở được thì bị bỏ, bên gọi chỉ thấy kBusy.
    std::string error;
    std::array<std::byte, account::kIpcKeyBytes> wrong{};
    wrong.fill(std::byte{0x5A});
    const Client intruder{net::Endpoint{.address = {127, 0, 0, 1}, .port = rig->daemon->ipc_port()}, wrong};
    context.expect(intruder.call(rpc::balance(kSeven), std::chrono::seconds{3}).code == wire_code(Error::kBusy),
        "khoá ipc sai không được trả lời");

    // Op hai byte của khung account: giá trị > 255 là yêu cầu hỏng, không bị cắt cụt thành Op khác.
    const std::optional<std::array<std::byte, account::kIpcKeyBytes>> key =
        account::load_ipc_key(account::ipc_key_path(rig->stage->config()), error);
    context.expect(key.has_value(), "đọc được ipc.key");
    if (key) {
        const std::optional<account::Reply> wide = account::exchange(
            net::Endpoint{.address = {127, 0, 0, 1}, .port = rig->daemon->ipc_port()},
            account::Call{.op = static_cast<account::Op>(0x0101), .body = {}}, std::chrono::seconds{3}, *key);
        context.expect(wide && wide->code == wire_code(Error::kMalformed), "op ngoài một byte là kMalformed");
    }

    // Byte rác, khung khổng lồ, kết nối mở rồi đóng ngay: billingd vẫn sống và vẫn trả lời.
    for (const std::size_t size : {std::size_t{7}, std::size_t{1000}, std::size_t{70000}}) {
        std::optional<sv::Socket> junk = sv::Socket::connect(rig->daemon->ipc_port(), std::chrono::seconds{3});
        context.expect(junk.has_value(), "nối được cổng ipc");
        if (!junk) continue;
        const std::string noise(size, '\x5A');
        static_cast<void>(junk->send_text(noise, std::chrono::seconds{2}));
    }
    for (int index = 0; index < 20; ++index) {
        const std::optional<sv::Socket> idle = sv::Socket::connect(rig->daemon->ipc_port(), std::chrono::seconds{3});
        context.expect(idle.has_value(), "nối rồi đóng ngay");
    }
    context.expect(rpc::read_quote(ask(*rig, rpc::quote(Ingot{10}))).has_value(), "vẫn trả lời sau byte rác");
    context.expect(rig->daemon->alive(), "billingd còn sống");

    // Dừng êm (stdin đóng như trình giám sát), rồi chạy lại trên cùng database: migration chạy lặp không sao.
    const std::optional<int> code = rig->daemon->stop_clean();
    context.expect(code && *code == 0, "dừng êm thoát mã 0");
    if (!relaunch(context, *rig)) return;
    context.expect(rpc::read_balance(ask(*rig, rpc::balance(kSeven))).has_value(), "chạy lại vẫn nối được database");
    const std::optional<int> second = rig->daemon->stop_clean();
    context.expect(second && *second == 0, "dừng êm lần hai");
}

void serve_no_secrets(Context& context) {
    const pg::Access* access = pg::shared_access("serve_no_secrets");
    if (access == nullptr) return;
    std::string why;
    sv::StageOptions options;
    options.write_secrets = false;
    const std::unique_ptr<sv::Stage> stage = sv::Stage::create(*access, options, why);
    if (!stage) return;
    const std::unique_ptr<sv::Daemon> daemon = sv::Daemon::start(*stage);
    context.expect(daemon != nullptr && daemon->ready_line() == "ready" && !daemon->has_database(),
        "thiếu secrets.local.toml: in ready trần rồi chờ dừng");
    if (!daemon) return;
    const std::optional<int> code = daemon->stop_clean();
    context.expect(code && *code == 0, "dừng êm");
}

void serve_bad_config(Context& context) {
    const pg::Access* access = pg::shared_access("serve_bad_config");
    if (access == nullptr) return;
    std::string why;
    sv::StageOptions wrong_password;
    wrong_password.password_override = "mat-khau-sai";
    const std::unique_ptr<sv::Stage> first = sv::Stage::create(*access, wrong_password, why);
    if (!first) return;
    const std::optional<int> code = sv::Daemon::start_and_wait_exit(*first);
    context.expect(code && *code == 1, "sai mật khẩu database: thoát mã 1");

    sv::StageOptions bad_key;
    bad_key.key_file_text = "khong-phai-hex\n";
    const std::unique_ptr<sv::Stage> second = sv::Stage::create(*access, bad_key, why);
    if (!second) return;
    const std::optional<int> key_code = sv::Daemon::start_and_wait_exit(*second);
    context.expect(key_code && *key_code == 1, "khoá nhà cung cấp không phải 64 ký tự hex: thoát mã 1");
}

// ---- webhook --------------------------------------------------------------------------------------------

void serve_webhook(Context& context) {
    std::optional<Rig> rig = boot(context, "serve_webhook");
    if (!rig) return;
    const std::uint16_t port = rig->stage->webhook_port();
    const auto raw_status = [&](std::string_view raw) {
        const sv::HttpAnswer answer = sv::http_exchange(port, raw);
        return answer.answered ? answer.status : 0;
    };
    const std::int64_t now = sv::unix_now();

    context.expect(post_order(*rig, "W1", 7, 500) == 200, "đơn đúng: 200");
    context.expect(available_of(*rig, kSeven) == 500, "điểm đã cộng");
    const sv::HttpAnswer again = sv::http_exchange(port,
        sv::webhook_request({.body = sv::order_body("W1", 7, 500), .timestamp = now}));
    context.expect(again.answered && again.status == 200 && again.body == "duplicate", "gọi lại: 200 duplicate");
    context.expect(available_of(*rig, kSeven) == 500, "gọi lại không cộng hai lần");
    context.expect(post_order(*rig, "W1", 7, 501) == 409, "cùng mã khác số điểm: 409");
    context.expect(post_order(*rig, "W1", 8, 500) == 409, "cùng mã khác tài khoản: 409");
    context.expect(available_of(*rig, kSeven) == 500 && available_of(*rig, AccountId{8}) == 0, "xung đột không đổi sổ");
    context.expect(post_order(*rig, "W2", 7, 300, "pending") == 200 && available_of(*rig, kSeven) == 500, "báo chờ chưa cộng");
    context.expect(post_order(*rig, "W2", 7, 300) == 200 && available_of(*rig, kSeven) == 800, "báo trả sau báo chờ thì cộng");
    context.expect(post_order(*rig, "W2", 7, 300, "pending") == 200 && available_of(*rig, kSeven) == 800, "báo chờ muộn bị bỏ qua");

    // Ký sai / thời gian / đường dẫn.
    const std::string body = sv::order_body("W3", 7, 100);
    const std::string zeros(64, '0');
    context.expect(raw_status(sv::webhook_request({.body = body, .timestamp = now, .signature_override = zeros})) == 401, "chữ ký sai: 401");
    context.expect(raw_status(sv::webhook_request({.body = body, .timestamp = now - 1000})) == 401, "mốc quá cũ: 401");
    context.expect(raw_status(sv::webhook_request({.body = body, .timestamp = now + 1000})) == 401, "mốc ở tương lai: 401");
    context.expect(raw_status(sv::webhook_request({.path = "/pay/other", .body = body, .timestamp = now})) == 404, "đường dẫn lạ: 404");
    context.expect(raw_status(sv::webhook_request({.body = body + "x", .timestamp = now, .signature_override =
                       billing::sign_webhook(sv::provider_key(), {.path = sv::kProviderPath, .timestamp = now, .body = body})})) == 401,
        "đổi thân sau khi ký: 401");
    // Thân hợp lệ chữ ký nhưng thiếu trường / sai trường: 422 sau khi chữ ký qua.
    context.expect(raw_status(sv::webhook_request({.body = "trade_no=W9&account=7", .timestamp = now})) == 422, "thiếu trường: 422");
    context.expect(raw_status(sv::webhook_request({.body = sv::order_body("W9", 7, 0), .timestamp = now})) == 422, "0 điểm: 422");
    context.expect(raw_status(sv::webhook_request({.body = sv::order_body("W9", 0, 5), .timestamp = now})) == 422, "tài khoản 0: 422");
    context.expect(raw_status(sv::webhook_request({.body = body + "&extra=1", .timestamp = now})) == 422, "trường lạ: 422");
    context.expect(available_of(*rig, kSeven) == 800, "mọi yêu cầu hỏng không đổi sổ");

    // HTTP hỏng.
    context.expect(raw_status("GET /pay/alpha HTTP/1.1\r\nHost: x\r\n\r\n") == 405, "GET: 405");
    context.expect(raw_status("POST /pay/alpha HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n") == 400, "chunked: 400");
    context.expect(raw_status("POST /pay/alpha HTTP/1.1\r\nHost: x\r\n\r\n") == 411, "thiếu Content-Length: 411");
    context.expect(raw_status("POST /pay/alpha HTTP/1.1\r\nContent-Length: 99999\r\n\r\n") == 401,
        "không ký thì 401 trước khi bàn tới cỡ thân");
    context.expect(raw_status(std::format("POST /pay/alpha HTTP/1.1\r\nX-Timestamp: {}\r\nX-Signature: {}\r\n"
                                          "Content-Type: application/x-www-form-urlencoded\r\nContent-Length: 99999\r\n\r\n",
                       now, zeros)) == 413,
        "thân quá trần: 413");
    context.expect(raw_status("\x16\x03\x01garbage\r\n\r\n") == 400, "byte lạ (TLS ClientHello): 400");
    std::string many_headers = "POST /pay/alpha HTTP/1.1\r\n";
    for (int index = 0; index < 60; ++index)
        many_headers += std::format("X-H{}: 1\r\n", index);
    many_headers += "\r\n";
    const int too_many = raw_status(many_headers);
    context.expect(too_many == 400 || too_many == 431, "quá nhiều tiêu đề");
    context.expect(raw_status(std::string(6000, 'A')) == 431, "đầu yêu cầu quá 4 KiB: 431");

    // Đứt giữa yêu cầu rồi kết nối khác: dịch vụ không kẹt.
    {
        std::optional<sv::Socket> cut = sv::Socket::connect(port, std::chrono::seconds{3});
        context.expect(cut.has_value(), "nối được webhook");
        if (cut) {
            const std::string half = sv::webhook_request({.body = body, .timestamp = now});
            static_cast<void>(cut->send_text(half.substr(0, half.size() / 2)));
        }
    }
    context.expect(post_order(*rig, "W4", 7, 200) == 200 && available_of(*rig, kSeven) == 1000, "sau khi bị cắt vẫn phục vụ");

    // Kẻ nói chậm và đám kết nối im lặng vượt trần 64: tất cả bị đóng trong hạn 5 giây, chỗ được trả lại.
    std::vector<sv::Socket> idle;
    for (int index = 0; index < 80; ++index) {
        std::optional<sv::Socket> socket = sv::Socket::connect(port, std::chrono::seconds{3});
        if (socket) idle.push_back(std::move(*socket));
    }
    context.expect(idle.size() == 80, "mở được 80 kết nối im lặng");
    const auto started = std::chrono::steady_clock::now();
    std::int64_t closed_by_server = 0;
    for (sv::Socket& socket : idle) {
        const sv::HttpAnswer answer = socket.read_answer(std::chrono::seconds{9});
        if (answer.closed || (answer.answered && answer.status == 408)) ++closed_by_server;
    }
    const auto waited = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - started);
    context.expect(closed_by_server == 80, std::format("kết nối im lặng đều bị đóng ({}/80)", closed_by_server));
    context.expect(waited < std::chrono::seconds{8}, std::format("đóng trong hạn ({} ms)", waited.count()));
    idle.clear();
    context.expect(post_order(*rig, "W5", 7, 50) == 200 && available_of(*rig, kSeven) == 1050, "chỗ được trả lại");

    // Sổ vẫn cân và đúng từng điểm.
    const Result<Conservation> check = rpc::read_conservation(ask(*rig, rpc::ledger_check()));
    context.expect(check && check->balanced && check->topped_up.value() == 1050 + 0, "sổ cân sau mọi yêu cầu hỏng");
    context.expect(rig->daemon->alive(), "billingd còn sống");
}

// ---- hai pha qua ipc, mạng đứt, billing chạy lại ----------------------------------------------------------

void serve_exchange_phases(Context& context) {
    sv::StageOptions options;
    options.pending_timeout = 2;
    options.reconcile_interval = 1;
    std::optional<Rig> rig = boot(context, "serve_exchange_phases", options);
    if (!rig) return;
    context.expect(post_order(*rig, "E1", 7, 1000) == 200, "nạp 1000 phần mười");

    // ceil(30 * 10 / 1) = 300.
    const ExchangeRequest ask_one{.account = kSeven, .character = CharacterId{70}, .request = RequestId{1}, .ingot = Ingot{30}};
    const Result<ExchangeOutcome> begun = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_begin(ask_one)));
    context.expect(begun && begun->order.points.value() == 300 && begun->balance.value() == 700, "pha một giữ 300");
    if (!begun) return;
    // Mạng đứt: world không nhận được trả lời, gọi lại cùng request.
    const Result<ExchangeOutcome> replay = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_begin(ask_one)));
    context.expect(replay && replay->replayed && replay->order.id == begun->order.id && replay->balance.value() == 700,
        "gọi lại pha một nhận đúng đơn cũ");

    // Không ai báo pha hai: tiến trình tự quét (không cần world gọi exchange_sweep) và đơn sang đối soát.
    ExchangeStatus status = ExchangeStatus::kPending;
    for (int attempt = 0; attempt < 60 && status != ExchangeStatus::kStale; ++attempt) {
        std::this_thread::sleep_for(std::chrono::milliseconds{250});
        const Result<ExchangeOrder> found = rpc::read_exchange(ask(*rig, rpc::find_exchange(begun->order.id)));
        if (found) status = found->status;
    }
    context.expect(status == ExchangeStatus::kStale, "quá hạn thì tự sang stale");
    const Result<std::vector<ExchangeOrder>> open = rpc::read_exchange_list(ask(*rig, rpc::exchange_open(10)));
    context.expect(open && open->size() == 1 && open->front().id == begun->order.id, "đơn nằm trong danh sách đối soát");
    const Result<Balance> held = rpc::read_balance(ask(*rig, rpc::balance(kSeven)));
    context.expect(held && held->available.value() == 700 && held->held.value() == 300, "điểm vẫn bị giữ, không tự hoàn");
    const Result<ExchangeOutcome> done = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_finish(begun->order.id, Verdict::kDone)));
    context.expect(done && done->order.status == ExchangeStatus::kConfirmed, "chốt đơn stale");
    context.expect(rpc::read_exchange_outcome(ask(*rig, rpc::exchange_finish(begun->order.id, Verdict::kCancelled))).error() == Error::kBadState,
        "đã chốt thì không huỷ");

    // Đơn hai: giữ, rồi billing bị giết trước khi world báo; chạy lại; đơn còn đó; world gọi lại và huỷ.
    const ExchangeRequest ask_two{.account = kSeven, .character = CharacterId{70}, .request = RequestId{2}, .ingot = Ingot{20}};
    const Result<ExchangeOutcome> second = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_begin(ask_two)));
    context.expect(second && second->balance.value() == 500, "đơn hai giữ 200");
    if (!second) return;
    rig->daemon->crash();
    context.expect(!rig->daemon->alive(), "billingd đã bị giết");
    context.expect(rig->client->call(rpc::balance(kSeven), std::chrono::seconds{1}).code == wire_code(Error::kBusy),
        "billingd chết thì world thấy kBusy");
    if (!relaunch(context, *rig)) return;
    const Result<ExchangeOrder> survivor = rpc::read_exchange(ask(*rig, rpc::find_exchange(second->order.id)));
    context.expect(survivor && survivor->points.value() == 200, "đơn còn nguyên sau khi chạy lại");
    const Result<ExchangeOutcome> replay_two = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_begin(ask_two)));
    context.expect(replay_two && replay_two->replayed && replay_two->order.id == second->order.id, "gọi lại sau khi chạy lại");
    const Result<ExchangeOutcome> back = rpc::read_exchange_outcome(ask(*rig, rpc::exchange_finish(second->order.id, Verdict::kCancelled)));
    context.expect(back && back->balance.value() == 700, "huỷ hoàn đủ 200");
    context.expect(post_order(*rig, "E1", 7, 1000) == 200 && available_of(*rig, kSeven) == 700, "nhà cung cấp gọi lại sau khi chạy lại");

    const Result<Conservation> check = rpc::read_conservation(ask(*rig, rpc::ledger_check()));
    context.expect(check && check->balanced && check->topped_up.value() == 1000 && check->exchange_confirmed.value() == 300 &&
            check->exchange_held.value() == 0,
        "đối soát: nạp 1000 = còn 700 + đã đổi 300");
}

// ---- 1.000 đơn có chèn lỗi, billing bị giết ba lần ------------------------------------------------------------

struct Tally {
    std::int64_t expected_points = 0;
    std::int64_t paid_orders = 0;
    std::int64_t failed_orders = 0;
    std::int64_t requests = 0;
    std::int64_t retries = 0;
    std::int64_t wrong = 0;
    std::string first_wrong;
};

enum class Fault : std::uint8_t { kNone, kBadSignature, kStale, kUnknownPath, kCut, kTamperedBody };

// Một lần gửi: đơn `trade` mang thân `body`, làm hỏng theo `fault`.
struct Shot {
    std::string_view trade;
    std::string_view body;
    Fault fault;
};

// Gửi cho tới khi nhận được một trả lời có nghĩa (không phải kết nối bị từ chối hay 5xx do billing đang chạy lại),
// như một nhà cung cấp thật gọi lại tới khi nhận 2xx/4xx. kCut chỉ gửi một lần: không có trả lời là kết quả đúng.
[[nodiscard]] std::optional<int> deliver(Tally& tally, std::uint16_t port, const Shot& shot) {
    const std::int64_t now = sv::unix_now();
    const Fault fault = shot.fault;
    sv::Delivery delivery{.body = std::string{shot.body}, .timestamp = now};
    if (fault == Fault::kBadSignature) delivery.signature_override = std::string(64, 'f');
    if (fault == Fault::kStale) delivery.timestamp = now - 4000;
    if (fault == Fault::kUnknownPath) delivery.path = "/pay/unknown";
    std::string raw = sv::webhook_request(delivery);
    if (fault == Fault::kTamperedBody) raw.back() = raw.back() == 'x' ? 'y' : 'x';
    for (int attempt = 0; attempt < 400; ++attempt) {
        ++tally.requests;
        if (fault == Fault::kCut) {
            std::optional<sv::Socket> socket = sv::Socket::connect(port, std::chrono::seconds{2});
            if (socket) static_cast<void>(socket->send_text(raw.substr(0, raw.size() / 2)));
            return std::nullopt;
        }
        const sv::HttpAnswer answer = sv::http_exchange(port, raw, std::chrono::seconds{10});
        if (answer.answered && answer.status < 500) return answer.status;
        ++tally.retries;
        std::this_thread::sleep_for(std::chrono::milliseconds{50});
    }
    tally.wrong++;
    if (tally.first_wrong.empty()) tally.first_wrong = std::format("{}: hết lượt gọi lại", shot.trade);
    return std::nullopt;
}

void expect_status(Tally& tally, std::string_view trade, std::optional<int> got, std::optional<int> want) {
    if (got == want) return;
    ++tally.wrong;
    if (tally.first_wrong.empty()) {
        tally.first_wrong = std::format("{}: cần {}, được {}", trade, want ? *want : 0, got ? *got : 0);
    }
}

struct StormPlan {
    std::uint16_t port;
    int orders;
    std::uint64_t seed;
};

void run_storm(const StormPlan& plan, Tally& tally) {
    script::Rng rng(plan.seed);
    const auto send = [&](std::string_view trade, const std::string& body, Fault fault) {
        return deliver(tally, plan.port, Shot{.trade = trade, .body = body, .fault = fault});
    };
    for (int index = 1; index <= plan.orders; ++index) {
        const std::string trade = std::format("S{}", index);
        const std::uint64_t account = 1 + rng.below(50);
        const std::int64_t points = 10 + static_cast<std::int64_t>(rng.below(5000));
        const bool is_paid = rng.below(10) != 0;
        const std::string_view final_status = is_paid ? "paid" : "failed";
        const std::string pending_body = sv::order_body(trade, account, points, "pending");
        const std::string final_body = sv::order_body(trade, account, points, final_status);
        if (rng.below(5) == 0) expect_status(tally, trade, send(trade, pending_body, Fault::kNone), 200);
        expect_status(tally, trade, send(trade, final_body, Fault::kNone), 200);
        if (rng.below(10) < 3) expect_status(tally, trade, send(trade, final_body, Fault::kNone), 200);
        if (rng.below(20) == 0) {
            const std::string conflicting = sv::order_body(trade, account, points + 1, final_status);
            expect_status(tally, trade, send(trade, conflicting, Fault::kNone), 409);
        }
        if (is_paid && rng.below(10) < 2) expect_status(tally, trade, send(trade, pending_body, Fault::kNone), 200);
        if (is_paid) {
            ++tally.paid_orders;
            tally.expected_points += points;
        } else {
            ++tally.failed_orders;
        }
        // Yêu cầu hỏng chen vào: không bao giờ đổi sổ.
        const std::string noise = std::format("F{}", index);
        const std::string noise_body = sv::order_body(noise, 1, 777);
        switch (rng.below(40)) {
        case 0: expect_status(tally, noise, send(noise, noise_body, Fault::kBadSignature), 401); break;
        case 1: expect_status(tally, noise, send(noise, noise_body, Fault::kStale), 401); break;
        case 2: expect_status(tally, noise, send(noise, noise_body, Fault::kUnknownPath), 404); break;
        case 3: expect_status(tally, noise, send(noise, noise_body, Fault::kCut), std::nullopt); break;
        case 4: expect_status(tally, noise, send(noise, noise_body, Fault::kTamperedBody), 401); break;
        default: break;
        }
    }
}

void serve_storm_with_crashes(Context& context) {
    sv::StageOptions options;
    options.reconcile_interval = 1;
    std::optional<Rig> rig = boot(context, "serve_storm_with_crashes", options);
    if (!rig) return;
    constexpr int kOrders = 1000;
    Tally tally;
    std::atomic<bool> storming{true};
    std::atomic<int> crashes{0};
    std::atomic<int> failed_restarts{0};
    std::mutex swap;
    {
        // Luồng giết billing ba lần ở những lúc ngẫu nhiên rồi chạy lại ngay; luồng gửi chỉ thấy kết nối bị từ chối
        // hoặc bị cắt và gọi lại.
        const std::jthread killer{[&] {
            script::Rng rng(0xC0FFEEULL);
            while (crashes < 3 && storming) {
                std::this_thread::sleep_for(std::chrono::milliseconds{1200 + static_cast<std::int64_t>(rng.below(2500))});
                if (!storming) break;
                const std::scoped_lock lock{swap};
                rig->daemon->crash();
                ++crashes;
                std::unique_ptr<sv::Daemon> next;
                for (int attempt = 0; attempt < 40 && !next; ++attempt) {
                    next = sv::Daemon::start(*rig->stage, std::chrono::seconds{20});
                    if (!next) std::this_thread::sleep_for(std::chrono::milliseconds{250});
                }
                if (!next) {
                    ++failed_restarts;
                    return;
                }
                rig->daemon = std::move(next);
            }
        }};
        run_storm(StormPlan{.port = rig->stage->webhook_port(), .orders = kOrders, .seed = 20261014}, tally);
        storming = false;
    }
    context.expect(failed_restarts == 0, "billing chạy lại được sau mỗi lần bị giết");
    context.expect(crashes >= 1, std::format("billing đã bị giết {} lần trong lúc gửi", crashes.load()));
    context.expect(tally.wrong == 0, std::format("{} trả lời sai: {}", tally.wrong, tally.first_wrong));
    context.expect(tally.paid_orders > 800 && tally.failed_orders > 30, "đợt đơn có cả đơn trả và đơn hỏng");
    context.expect(rig->daemon->alive(), "billing đang chạy sau đợt thử");
    if (!rig->daemon->alive()) return;
    rig->client = rig->daemon->client();  // lần chạy lại gần nhất đổi cổng ipc
    if (!rig->client) return;

    // Đối soát qua ipc và qua SQL viết riêng, hai đường độc lập.
    const Result<Conservation> check = rpc::read_conservation(ask(*rig, rpc::ledger_check()));
    context.expect(check && check->balanced && check->mismatched_accounts == 0, "ledger_check cân");
    context.expect(check && check->topped_up.value() == tally.expected_points,
        std::format("điểm nạp {} = tổng đơn đã trả {}", check ? check->topped_up.value() : -1, tally.expected_points));
    std::string why;
    std::optional<store::PgConn> sql = rig->stage->open_sql(why);
    context.expect(sql.has_value(), why);
    if (sql) {
        const auto scalar = [&](std::string_view query) {
            const store::PgExec result = sql->exec(query);
            if (!result.ok || result.rows.empty()) return std::int64_t{-1};
            return std::stoll(result.rows.front().cells.front().text);
        };
        context.expect(scalar("SELECT COALESCE(SUM(points), 0) FROM payment WHERE status = 'paid'") == tally.expected_points,
            "SQL: tổng điểm các đơn đã trả");
        context.expect(scalar("SELECT COALESCE(SUM(delta), 0) FROM point_ledger WHERE kind = 'top_up'") == tally.expected_points,
            "SQL: tổng dòng nạp trong sổ, mỗi đơn đúng một lần");
        context.expect(scalar("SELECT COUNT(*) FROM point_ledger WHERE kind = 'top_up'") == tally.paid_orders,
            "SQL: số dòng nạp = số đơn trả");
        context.expect(scalar("SELECT COUNT(*) FROM payment") == tally.paid_orders + tally.failed_orders, "SQL: số đơn");
        context.expect(scalar("SELECT COUNT(*) FROM payment WHERE trade_no LIKE 'F%'") == 0, "SQL: yêu cầu hỏng không tạo đơn");
        context.expect(scalar("SELECT COALESCE(SUM(points), 0) FROM point_balance") == tally.expected_points, "SQL: tổng số dư");
    }
    std::println("[storm] {} yêu cầu, {} lần gọi lại, {} lần giết billing", tally.requests, tally.retries,
        crashes.load());
    const std::optional<int> code = rig->daemon->stop_clean();
    context.expect(code && *code == 0, "dừng êm sau đợt thử");
}

constexpr std::array kCases{
    Case{.name = "serve_boot_and_ipc", .body = serve_boot_and_ipc},
    Case{.name = "serve_no_secrets", .body = serve_no_secrets},
    Case{.name = "serve_bad_config", .body = serve_bad_config},
    Case{.name = "serve_webhook", .body = serve_webhook},
    Case{.name = "serve_exchange_phases", .body = serve_exchange_phases},
    Case{.name = "serve_storm_with_crashes", .body = serve_storm_with_crashes},
};

} // namespace
} // namespace game::billing

int main() {
    static_cast<void>(std::setvbuf(stdout, nullptr, _IONBF, 0));
    return game::test::run_all(game::billing::kCases) == 0 ? 0 : 1;
}
