#pragma once
// Bộ đọc billing.toml. [[provider]] không có trong tệp mẫu: thêm được, không bắt buộc.
// Khối provider thiếu khoá vẫn là lỗi, vì chú thích liệt kê đủ khoá của khối đó.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config {

struct Provider {
    std::string key;
    std::string webhook_path;
    std::string secret_file;
    bool enabled = false;
    std::size_t line = 0;
};

struct Billing {
    DatabaseLogin database;
    std::vector<std::string> allow;
    std::int64_t max_clients = 0;
    std::int64_t ingot_per_point = 0;
    std::int64_t register_gift = 0;
    std::int64_t daily_ingot_cap = 0;
    std::chrono::seconds pending_timeout_seconds{0};
    std::chrono::seconds reconcile_interval_seconds{0};
    std::int64_t attempts_per_hour = 0;
    std::vector<Provider> providers;
};

[[nodiscard]] ReadResult<Billing> read_billing(std::string_view text);

} // namespace game::config
