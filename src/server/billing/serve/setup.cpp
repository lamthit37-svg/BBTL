#include "billing/serve/setup.hpp"

#include "account/ipc_key.hpp"
#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/http.hpp"
#include "billing/limits.hpp"
#include "billing/throttle.hpp"
#include "billing/types.hpp"
#include "billing/webhook.hpp"
#include "config/billing.hpp"
#include "config/cluster.hpp"
#include "config/issue.hpp"
#include "config/secrets.hpp"
#include "config/types.hpp"
#include "io/file.hpp"
#include "net/net.hpp"
#include "secure/secure.hpp"
#include "store/pg.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <expected>
#include <filesystem>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

using Path = std::filesystem::path;

[[nodiscard]] std::unexpected<SetupFault> fault(int exit_code, std::string message) {
    return std::unexpected(SetupFault{.exit_code = exit_code, .message = std::move(message)});
}

template <typename Value>
[[nodiscard]] std::expected<Value, SetupFault> read_cfg(const Path& path,
    config::ReadResult<Value> (*reader)(std::string_view), std::string_view label) {
    const io::TextResult text = io::read_text(path);
    if (!text) return fault(1, std::format("không đọc được {}", label));
    config::ReadResult<Value> value = reader(*text);
    if (!value) {
        std::string why = std::format("{} không hợp lệ", label);
        if (!value.error().empty()) {
            why += std::format(" (dòng {}: {})", value.error().front().line, value.error().front().message);
        }
        return fault(1, std::move(why));
    }
    return std::move(*value);
}

[[nodiscard]] const config::ProcessBlock* find_billing(const config::Cluster& cluster) noexcept {
    const auto found = std::ranges::find_if(cluster.processes, [](const config::ProcessBlock& block) {
        return block.kind == config::ProcessKind::kBilling && block.id.value() == 0;
    });
    return found == cluster.processes.end() ? nullptr : &*found;
}

[[nodiscard]] std::optional<net::Endpoint> loopback_endpoint(const config::Ipv4Address& host, config::Port port) {
    const std::string text = std::format("{}:{}", host.text(), port.value());
    const net::ZeroPort zero = port.value() == 0 ? net::ZeroPort::kAllow : net::ZeroPort::kRefuse;
    const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(text, zero);
    if (!parsed) return std::nullopt;
    if (parsed->address != net::Ipv4{127, 0, 0, 1}) return std::nullopt;
    return *parsed;
}

// Đường dẫn webhook: bắt đầu bằng '/', bộ ký tự hẹp, không dài quá trần mục tiêu của bộ phân tích HTTP.
[[nodiscard]] bool path_ok(std::string_view path) noexcept {
    if (path.size() < 2 || path.size() > http::kTargetMost || path.front() != '/') return false;
    return std::ranges::all_of(path, [](char c) {
        const bool alnum = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
        return alnum || c == '/' || c == '_' || c == '.' || c == '-';
    });
}

// Khoá HMAC của một nhà cung cấp. Ai đọc được khoá là ký được webhook cộng điểm, nên tệp phải riêng của tài khoản
// chạy máy chủ (cùng phép kiểm với ipc.key); lỏng hơn thì billing từ chối chạy, không tự sửa quyền.
[[nodiscard]] std::expected<ProviderKey, SetupFault> provider_key_of(const config::Provider& declared,
    const Path& config_dir) {
    const Path secret_path = config_dir / io::path_from_utf8(declared.secret_file);
    std::error_code probe;
    // Tệp thiếu thì file_private cũng sai; xét riêng để câu lỗi nói đúng nguyên nhân.
    if (std::filesystem::is_regular_file(secret_path, probe)) {
        std::string why;
        if (!account::file_private(secret_path, declared.secret_file, why)) {
            return fault(1, std::format("tệp khoá của nhà cung cấp '{}': {}", declared.key, why));
        }
    }
    io::TextResult secret = io::read_text(secret_path);
    if (!secret) {
        return fault(1, std::format("không đọc được tệp khoá của nhà cung cấp '{}'", declared.key));
    }
    const std::optional<ProviderKey> key = parse_provider_key(*secret);
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret->data(), secret->size()}));
    if (!key) {
        return fault(1, std::format("tệp khoá của nhà cung cấp '{}' phải là 64 ký tự hex", declared.key));
    }
    return *key;
}

[[nodiscard]] std::expected<std::vector<WebhookProvider>, SetupFault> providers_of(const config::Billing& billing,
    const Path& config_dir) {
    std::vector<WebhookProvider> out;
    for (const config::Provider& declared : billing.providers) {
        if (!declared.enabled) continue;
        // Tên đi vào cột provider của đơn nạp: dùng đúng bộ kiểm của đơn nạp để một tên sai không lọt tới lúc có
        // tiền thật (khi đó mọi webhook của nhà đó sẽ trả 422).
        if (!check_payment_key(declared.key, "x")) {
            return fault(1, std::format("billing.toml dòng {}: tên nhà cung cấp '{}' không hợp lệ", declared.line, declared.key));
        }
        if (!path_ok(declared.webhook_path)) {
            return fault(1, std::format("billing.toml dòng {}: webhook_path '{}' không hợp lệ", declared.line, declared.webhook_path));
        }
        const bool repeated = std::ranges::any_of(out, [&](const WebhookProvider& known) {
            return known.name == declared.key || known.path == declared.webhook_path;
        });
        if (repeated) return fault(1, std::format("billing.toml dòng {}: nhà cung cấp hoặc đường dẫn lặp", declared.line));
        const std::expected<ProviderKey, SetupFault> key = provider_key_of(declared, config_dir);
        if (!key) return std::unexpected(key.error());
        out.push_back(WebhookProvider{.name = declared.key, .path = declared.webhook_path, .key = *key});
    }
    return out;
}

} // namespace

bool has_secrets(const std::filesystem::path& config_dir) {
    return io::read_text(config_dir / "secrets.local.toml").has_value();
}

std::expected<Setup, SetupFault> load_setup(const std::filesystem::path& config_dir) {
    const std::expected<config::Cluster, SetupFault> cluster =
        read_cfg(config_dir / "cluster.toml", config::read_cluster, "cluster.toml");
    if (!cluster) return std::unexpected(cluster.error());
    const std::expected<config::Billing, SetupFault> billing =
        read_cfg(config_dir / "billing.toml", config::read_billing, "billing.toml");
    if (!billing) return std::unexpected(billing.error());
    std::expected<config::Secrets, SetupFault> secrets =
        read_cfg(config_dir / "secrets.local.toml", config::read_secrets, "secrets.local.toml");
    if (!secrets) return std::unexpected(secrets.error());
    if (secrets->billing.empty()) return fault(1, "thiếu mật khẩu database billing");
    if (cluster->postgres.host.text() != "127.0.0.1") return fault(1, "postgres chỉ được ở 127.0.0.1");

    const config::ProcessBlock* process = find_billing(*cluster);
    if (process == nullptr) return fault(2, "cluster.toml không có tiến trình billing 0");
    const std::optional<net::Endpoint> ipc = loopback_endpoint(process->host, process->port);
    if (!ipc) return fault(2, "ipc chỉ nghe 127.0.0.1");
    // billing chỉ nghe loopback, nên [access] allow phải có 127.0.0.1: thiếu thì không ai gọi được, và cấu hình
    // đang nói điều billing không làm được (nghe địa chỉ khác) thì dừng ngay chứ không lặng lẽ bỏ qua.
    if (!std::ranges::contains(billing->allow, std::string{"127.0.0.1"})) {
        return fault(2, "billing.toml [access] allow phải có 127.0.0.1: billing chỉ nghe loopback");
    }

    const io::TextResult limits_text =
        io::read_text(config_dir / ".." / "tables" / "server" / "billing_limits.tsv");
    if (!limits_text) return fault(1, "không đọc được tables/server/billing_limits.tsv");
    const std::expected<Limits, std::string> limits = parse_limits(*limits_text);
    if (!limits) return fault(1, std::format("billing_limits.tsv: {}", limits.error()));

    std::expected<std::vector<WebhookProvider>, SetupFault> providers = providers_of(*billing, config_dir);
    if (!providers) return std::unexpected(providers.error());

    std::string key_error;
    const std::optional<std::array<std::byte, account::kIpcKeyBytes>> key =
        account::load_or_create_ipc_key(account::ipc_key_path(config_dir), key_error);
    if (!key) return fault(1, key_error);

    Setup setup;
    setup.login.host = std::string{cluster->postgres.host.text()};
    setup.login.port = std::to_string(static_cast<unsigned>(cluster->postgres.port.value()));
    setup.login.dbname = billing->database.name;
    setup.login.user = billing->database.user;
    setup.login.password = std::move(secrets->billing);
    setup.sql_dir = (config_dir / ".." / "sql" / "billing").lexically_normal();
    setup.ipc = *ipc;
    setup.key = *key;
    setup.book.limits = *limits;
    setup.book.ingot_per_point = billing->ingot_per_point;
    // billing.toml ghi điểm nạp theo điểm nguyên; sổ đếm phần mười (client 2026 hiện UINT/10).
    setup.book.register_gift = Points{billing->register_gift * kTenthsPerPoint};
    setup.book.daily_ingot_cap = billing->daily_ingot_cap;
    setup.book.pending_timeout_seconds = billing->pending_timeout_seconds.count();
    setup.redeem = RedeemRates{.account_per_hour = billing->attempts_per_hour,
        .ip_per_hour = limits->redeem_ip_attempts_per_hour,
        .max_keys = static_cast<std::size_t>(limits->throttle_max_keys)};
    setup.reconcile_interval = billing->reconcile_interval_seconds;
    setup.ledger_check_interval = std::chrono::seconds{limits->ledger_check_interval_seconds};
    setup.providers = std::move(*providers);
    if (!setup.providers.empty() && billing->webhook_port) {
        setup.webhook = net::Endpoint{.address = net::Ipv4{127, 0, 0, 1}, .port = *billing->webhook_port};
    }
    return setup;
}

} // namespace game::billing
