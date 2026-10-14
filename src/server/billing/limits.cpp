#include "billing/limits.hpp"

#include "table/tsv.hpp"

#include <array>
#include <bitset>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <string>
#include <string_view>

namespace game::billing {
namespace {

struct Field {
    std::string_view key;
    std::int64_t Limits::* slot;
    std::int32_t least;
    std::int32_t most;
};

constexpr std::int32_t kIntMost = 2'000'000'000;

// Miền của từng khoá. Trần trên chặn số sai kiểu chữ số: không khoá nào hợp lệ khi lớn hơn
// miền này (mọi tổng của billing còn nằm trong int64 với phép nhân số lượng có kiểm tràn).
constexpr std::array kFields{
    Field{.key = "min_ingot_per_order", .slot = &Limits::min_ingot_per_order, .least = 1, .most = 1'000'000},
    Field{.key = "max_ingot_per_order", .slot = &Limits::max_ingot_per_order, .least = 1, .most = 100'000'000},
    Field{.key = "webhook_max_skew_seconds", .slot = &Limits::webhook_max_skew_seconds, .least = 1, .most = 86400},
    Field{.key = "max_points_per_topup", .slot = &Limits::max_points_per_topup, .least = 1, .most = kIntMost},
    Field{.key = "max_admin_adjust", .slot = &Limits::max_admin_adjust, .least = 1, .most = kIntMost},
    Field{.key = "max_balance", .slot = &Limits::max_balance, .least = 1, .most = kIntMost},
    Field{.key = "redeem_ip_attempts_per_hour", .slot = &Limits::redeem_ip_attempts_per_hour, .least = 1, .most = 100000},
    Field{.key = "max_codes_per_batch", .slot = &Limits::max_codes_per_batch, .least = 1, .most = 1'000'000},
    Field{.key = "max_grant_quantity", .slot = &Limits::max_grant_quantity, .least = 1, .most = 100'000'000},
    Field{.key = "throttle_max_keys", .slot = &Limits::throttle_max_keys, .least = 16, .most = 10'000'000},
    Field{.key = "ledger_check_interval_seconds", .slot = &Limits::ledger_check_interval_seconds, .least = 60, .most = 604800},
};

constexpr std::size_t kRowMost = 64;
constexpr std::array<std::string_view, 3> kBases{"client_2026", "x2008", "made_up"};

[[nodiscard]] bool basis_known(std::string_view basis) noexcept {
    for (const std::string_view known : kBases) {
        if (known == basis) return true;
    }
    return false;
}

} // namespace

std::expected<Limits, std::string> parse_limits(std::string_view tsv_text) {
    const table::TsvResult parsed = table::parse_tsv(tsv_text);
    if (!parsed) return std::unexpected(parsed.error());
    const table::Tsv& tsv = *parsed;
    if (tsv.rows.size() > kRowMost) return std::unexpected("billing_limits.tsv quá nhiều dòng");
    Limits limits;
    std::bitset<kFields.size()> seen;
    for (std::size_t row = 0; row < tsv.rows.size(); ++row) {
        table::RowReader reader{tsv, row};
        const std::string_view key = reader.text("key");
        const std::int32_t value = reader.integer("value", 0, kIntMost);
        const std::string_view basis = reader.text("basis");
        static_cast<void>(reader.text("unit"));
        static_cast<void>(reader.text("note"));
        if (reader.error()) return std::unexpected(*reader.error());
        const std::string where = std::format("dòng {}", tsv.lines[row]);
        if (!basis_known(basis)) return std::unexpected(std::format("{}: basis lạ '{}'", where, basis));
        bool matched = false;
        std::size_t index = 0;
        for (const Field& field : kFields) {
            const std::size_t slot = index++;
            if (field.key != key) continue;
            matched = true;
            if (seen.test(slot)) return std::unexpected(std::format("{}: khoá '{}' lặp", where, key));
            if (value < field.least || value > field.most) {
                return std::unexpected(std::format("{}: '{}' ngoài miền {}..{}", where, key, field.least, field.most));
            }
            seen.set(slot);
            limits.*(field.slot) = value;
        }
        if (!matched) return std::unexpected(std::format("{}: khoá lạ '{}'", where, key));
    }
    std::size_t index = 0;
    for (const Field& field : kFields) {
        if (!seen.test(index++)) return std::unexpected(std::format("thiếu khoá '{}'", field.key));
    }
    if (limits.min_ingot_per_order > limits.max_ingot_per_order) {
        return std::unexpected("min_ingot_per_order lớn hơn max_ingot_per_order");
    }
    return limits;
}

} // namespace game::billing
