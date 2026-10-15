// Biên chuỗi giữa script giao diện và phần còn lại của client (docs/giao-viec/LUA-GEN/TANG-C.md mục 4).
// Client 2026 giữ chuỗi Lua theo trang mã của máy (zh: GBK 936) và đổi ở biên widget; hai hàm dưới là chỗ
// duy nhất đặt biên đó trong bản này: chữ vào từ script đi qua from_script trước khi vào Widgets, chữ ra
// khỏi Widgets đi qua to_script trước khi trả cho script. Hiện cả hai phía đều UTF-8 nên là phép sao;
// chế độ trang mã gốc (cần bảng GBK riêng, không dùng API Windows vì Android và iOS không có) đổi ở đây
// mà không đụng phương thức nào.
#pragma once

#include <string>
#include <string_view>

namespace game::ui::script {

// Chuỗi từ script sang dạng Widgets giữ.
[[nodiscard]] inline std::string from_script(std::string_view text) {
    return std::string{text};
}

// Chuỗi từ Widgets sang dạng script nhận.
[[nodiscard]] inline std::string to_script(std::string_view text) {
    return std::string{text};
}

} // namespace game::ui::script
