#pragma once
// Tệp chữ cục bộ của thủ tục đăng nhập trên đĩa: sổ nhân vật (Save/roles.tsv) và máy chủ của lần vào
// game trước (Save/last_server.tsv). Dữ liệu của màn tạo nhân vật (chân dung, kiểu mặt, kiểu tóc, bộ
// đồ tân thủ) do giao diện tự nạp (ui/panel/role_cast).
// Khác gốc: sổ nằm một tệp của máy người chơi, chưa phải danh sách của máy chủ.

#include <filesystem>
#include <string>
#include <string_view>

namespace game::client {

// Nội dung tệp; không có tệp hay không đọc được thì chuỗi rỗng.
[[nodiscard]] std::string read_save_text(const std::filesystem::path& file);
// Ghi đè tệp, tạo thư mục cha khi thiếu. Sai thì false, tệp cũ có thể đã mất.
[[nodiscard]] bool write_save_text(const std::filesystem::path& file, std::string_view text);

} // namespace game::client
