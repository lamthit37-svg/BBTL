// Phần của io phụ thuộc hệ điều hành; mỗi nền tảng một tệp cài đặt (platform_win32.cpp,
// platform_posix.cpp cho Linux và Android), CMake chọn một. Header này không kéo header hệ thống.
#pragma once

#include <filesystem>

namespace game::io {

// Đặt console sang UTF-8 để chữ tiếng Việt và tên tệp chữ Hán in ra đúng. Gọi một lần ở đầu main.
void use_utf8_console() noexcept;

// Thư mục chứa exe đang chạy; rỗng khi hệ điều hành không cho biết. Dữ liệu của client được tìm
// tương đối với thư mục này, không theo thư mục làm việc.
[[nodiscard]] std::filesystem::path executable_directory();

// Mở một tệp có sẵn trên đĩa bằng chương trình mặc định của hệ điều hành; trang HTML thì là trình
// duyệt. false khi tệp không có, hệ điều hành từ chối, hoặc nền tảng chưa làm (mọi bản không phải
// Windows). Không hiện hộp báo lỗi nào của hệ điều hành.
[[nodiscard]] bool open_in_browser(const std::filesystem::path& page);

} // namespace game::io
