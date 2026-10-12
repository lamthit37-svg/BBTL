#pragma once
// Sổ nhân vật cục bộ của thủ tục đăng nhập trên đĩa. Dữ liệu của màn tạo nhân vật (chân dung, kiểu
// mặt, kiểu tóc, bộ đồ tân thủ) do giao diện tự nạp (ui/panel/role_cast).
// Khác gốc: sổ nằm một tệp Save/roles.tsv của máy người chơi, chưa phải danh sách của máy chủ.

#include <filesystem>
#include <string>
#include <string_view>

namespace game::client {

// Nội dung tệp; không có tệp hay không đọc được thì chuỗi rỗng.
[[nodiscard]] std::string read_role_book(const std::filesystem::path& file);
// Ghi đè tệp, tạo thư mục cha khi thiếu. Sai thì false, tệp cũ có thể đã mất.
[[nodiscard]] bool write_role_book(const std::filesystem::path& file, std::string_view text);

} // namespace game::client
