#pragma once
// Cấu hình của tiến trình billingd gom ở MỘT chỗ: cluster.toml (cổng ipc của billing, địa chỉ PostgreSQL),
// billing.toml, secrets.local.toml (mật khẩu role billing), ipc.key, billing_limits.tsv và khoá HMAC của từng
// nhà cung cấp thanh toán. Tiến trình và test cùng gọi load_setup nên không có hai cách đọc lệch nhau.
//
// Mọi lỗi cấu hình là SetupFault (có mã thoát và câu tiếng Việt), không dừng tiến trình tại đây: nơi gọi in
// rồi thoát. Hàm này đọc đĩa và có thể TẠO ipc.key lần đầu (load_or_create_ipc_key, quyền riêng).

#include "account/ipc_key.hpp"
#include "billing/book.hpp"
#include "billing/throttle.hpp"
#include "billing/webhook.hpp"
#include "net/net.hpp"
#include "store/pg.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <expected>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace game::billing {

struct Setup {
    store::PgLogin login;
    // dev/server/sql/billing, cạnh thư mục config.
    std::filesystem::path sql_dir;
    // Cổng ipc của billing 0 trong cluster.toml; luôn là 127.0.0.1 (cổng 0: hệ điều hành chọn).
    net::Endpoint ipc;
    // Có khi billing.toml khai [webhook] port và có ít nhất một [[provider]] bật. Luôn 127.0.0.1.
    std::optional<net::Endpoint> webhook;
    std::array<std::byte, account::kIpcKeyBytes> key{};
    BookConfig book;
    RedeemRates redeem;
    // Chỉ nhà cung cấp bật, đã đọc và kiểm khoá.
    std::vector<WebhookProvider> providers;
    // Chu kỳ quét đơn đổi quá hạn.
    std::chrono::seconds reconcile_interval{0};
    // Chu kỳ đối soát toàn sổ.
    std::chrono::seconds ledger_check_interval{0};
};

struct SetupFault {
    int exit_code = 1;
    std::string message;
};

// true khi có secrets.local.toml đọc được (không đọc nội dung): chưa có thì billingd chờ dừng mà không
// động tới database, như authd và stored.
[[nodiscard]] bool has_secrets(const std::filesystem::path& config_dir);

[[nodiscard]] std::expected<Setup, SetupFault> load_setup(const std::filesystem::path& config_dir);

} // namespace game::billing
