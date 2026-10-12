#pragma once
// Mặt trước của thienlong_gate: nghe cổng, bắt tay, và chỉ xử lý tin mức phiên.
// Thiết kế ở docs/SERVER-BAO-MAT.md. Không đụng tài khoản hay cảnh.

#include <cstdint>
#include <filesystem>

namespace game::gate {

// Sinh tệp khoá danh tính mới. Tệp đã có thì không ghi đè. 0 khi xong, 2 khi không ghi được.
[[nodiscard]] int write_identity(const std::filesystem::path& path);

// Nạp cấu hình, nghe cổng, in `ready`, chạy tới khi được yêu cầu dừng. Mã thoát của tiến trình.
[[nodiscard]] int serve(const std::filesystem::path& config_dir);

} // namespace game::gate
