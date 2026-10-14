// Dùng chung cho các test billing: bảng giới hạn mẫu, cấu hình sổ và kịch bản có chèn lỗi chạy trên bất
// kỳ Book nào (MemoryBook trong billing_tests, PgBook trong billing_db_tests).
#pragma once

#include "billing/book.hpp"
#include "billing/limits.hpp"

#include <cstdint>
#include <string_view>

namespace game::test::billing_support {

// Bảng giới hạn dùng cho test; cùng hình với dev/server/tables/server/billing_limits.tsv.
inline constexpr std::string_view kLimitsTsv =
    "# schema 1\n"
    "# source: test\n"
    "# types: text\tint\ttext\ttext\ttext\n"
    "key\tvalue\tunit\tbasis\tnote\n"
    "min_ingot_per_order\t1\tingot\tclient_2026\tx\n"
    "max_ingot_per_order\t500000\tingot\tclient_2026\tx\n"
    "webhook_max_skew_seconds\t300\tgiây\tmade_up\tx\n"
    "max_points_per_topup\t10000000\tphần mười điểm\tmade_up\tx\n"
    "max_admin_adjust\t100000\tphần mười điểm\tmade_up\tx\n"
    "max_balance\t2000000000\tphần mười điểm\tmade_up\tx\n"
    "redeem_ip_attempts_per_hour\t60\tlượt\tmade_up\tx\n"
    "max_codes_per_batch\t5000\tmã\tmade_up\tx\n"
    "max_grant_quantity\t1000000\tcái\tmade_up\tx\n"
    "throttle_max_keys\t1024\tkhoá\tmade_up\tx\n"
    "ledger_check_interval_seconds\t21600\tgiây\tmade_up\tx\n";

[[nodiscard]] inline billing::Limits test_limits() {
    const auto parsed = billing::parse_limits(kLimitsTsv);
    return parsed ? *parsed : billing::Limits{};
}

[[nodiscard]] inline billing::BookConfig test_config() {
    billing::BookConfig config;
    config.limits = test_limits();
    config.ingot_per_point = 3;
    config.register_gift = billing::Points{100};
    config.daily_ingot_cap = 1000;
    config.pending_timeout_seconds = 600;
    return config;
}

// Mốc thời gian cơ sở của test: 2023-11-14 22:13:20 UTC, vừa tròn giây.
inline constexpr std::int64_t kT0 = 1'700'000'000;

} // namespace game::test::billing_support
