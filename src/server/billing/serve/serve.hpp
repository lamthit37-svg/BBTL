#pragma once
// billingd: giữ sổ điểm nạp trong PostgreSQL, nghe ipc cho world (khung của account, khoá ipc.key) và nghe
// webhook thanh toán trên 127.0.0.1. Không có secrets.local.toml thì in `ready` rồi chờ dừng để cụm thử không có
// PostgreSQL vẫn khởi động được (như authd và stored).
//
// Luồng: luồng chính chạy account::serve_loop (một luồng database bên trong, giữ kết nối ipc); luồng phụ giữ kết nối
// thứ hai, chạy webhook và việc định kỳ (quét đơn đổi quá hạn, đối soát toàn sổ, báo cáo ngày). Hai kết nối
// ghi tuần tự nhờ khoá cố vấn của PgBook.
//
// Dòng stdout: `ready ipc=<cổng>` khi đã migrate, nối database và mở mọi cổng nghe. Mọi thứ khác ra stderr.

#include <filesystem>

namespace game::billing {

[[nodiscard]] int serve_billing(const std::filesystem::path& config_dir);

} // namespace game::billing
