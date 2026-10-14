#pragma once
// Các trần số của billing, đọc từ MỘT bảng: dev/server/tables/server/billing_limits.tsv (cột key, value,
// unit, basis, note). Cột basis nói số từ đâu ra: client_2026 (đo từ script giao diện), x2008 (mã gốc),
// made_up (số tự đặt, chờ chủ dự án duyệt). Không có số nào nằm rải trong mã; thiếu khoá hay khoá
// lạ, giá trị ngoài miền là lỗi, bộ đọc không có mặc định âm thầm.
//
// Lõi không đọc đĩa: nơi gọi đưa nội dung tệp vào.

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>

namespace game::billing {

struct Limits {
    // Số ingot một lần xin đổi. client_2026: YuanbaoExchange.lua chặn 1 tới 500000.
    std::int64_t min_ingot_per_order = 0;
    std::int64_t max_ingot_per_order = 0;
    // Độ lệch tối đa giữa mốc thời gian của webhook và đồng hồ billing, giây.
    std::int64_t webhook_max_skew_seconds = 0;
    // Điểm (phần mười) cộng tối đa cho một đơn nạp.
    std::int64_t max_points_per_topup = 0;
    // Điểm (phần mười) tối đa của một lần chỉnh tay.
    std::int64_t max_admin_adjust = 0;
    // Số dư tối đa của một tài khoản, phần mười điểm.
    std::int64_t max_balance = 0;
    // Số lần nhập mã tối đa mỗi giờ cho một IP (trần theo tài khoản nằm ở billing.toml).
    std::int64_t redeem_ip_attempts_per_hour = 0;
    // Số mã tối đa của một đợt.
    std::int64_t max_codes_per_batch = 0;
    // Số lượng tối đa của một khoản quà.
    std::int64_t max_grant_quantity = 0;
    // Số khoá tối đa bộ đếm tốc độ giữ cùng lúc.
    std::int64_t throttle_max_keys = 0;
    // Chu kỳ đối soát toàn sổ của billingd (quét cả sổ nên thưa hơn chu kỳ quét đơn quá hạn), giây.
    std::int64_t ledger_check_interval_seconds = 0;
};

// O(số dòng); bảng quá 64 dòng là lỗi.
[[nodiscard]] std::expected<Limits, std::string> parse_limits(std::string_view tsv_text);

} // namespace game::billing
