/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/io/platform.hpp
 *  PHÂN HỆ   : Io / Platform
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần io phụ thuộc hệ điều hành: console UTF-8, đối số dòng lệnh UTF-8, thư
 *    mục exe, mở tệp bằng chương trình mặc định.
 *  - Mỗi nền tảng một tệp cài đặt (platform_win32.cpp, platform_posix.cpp cho
 *    Linux và Android, platform_apple.cpp), CMake chọn một; header không kéo
 *    header hệ thống.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace game::io {

// Đặt console sang UTF-8 để chữ tiếng Việt và tên tệp chữ Hán in ra đúng. Gọi một lần ở đầu main.
void use_utf8_console() noexcept;

// Các đối số dòng lệnh sau tên exe, dạng UTF-8; argc và argv là của main. argv của CRT trên Windows theo bảng mã ANSI
// nên làm rơi chữ ngoài bảng mã đó thành '?' (đường dẫn có dấu, chữ Hán): Windows lấy dòng lệnh UTF-16 bằng
// CommandLineToArgvW rồi đổi sang UTF-8, và chỉ dùng argv khi dòng lệnh đó không đọc được. Nền khác: argv (đã là UTF-8).
[[nodiscard]] std::vector<std::string> command_arguments(int argc, const char* const* argv);

// Thư mục chứa exe đang chạy; rỗng khi hệ điều hành không cho biết. Dữ liệu của client được tìm
// tương đối với thư mục này, không theo thư mục làm việc.
[[nodiscard]] std::filesystem::path executable_directory();

// Mở một tệp có sẵn trên đĩa bằng chương trình mặc định của hệ điều hành; trang HTML thì là trình
// duyệt. false khi tệp không có, hệ điều hành từ chối, hoặc nền tảng chưa làm (mọi bản không phải
// Windows). Không hiện hộp báo lỗi nào của hệ điều hành.
[[nodiscard]] bool open_in_browser(const std::filesystem::path& page);

} // namespace game::io
