// Đọc tệp dữ liệu của client từ đĩa. Đường dẫn trong dữ liệu game (tên mesh, tên map) là UTF-8;
// path_from_utf8 đổi sang đường dẫn hệ điều hành mà không đi qua bảng mã ANSI của Windows.
// Quyết định: tệp là dữ liệu ngoài nên mọi lỗi đọc trả về qua std::expected, không dừng tiến trình;
// có trần cỡ để một tệp hỏng không nuốt hết bộ nhớ.
// Tên tệp tra không phân biệt hoa thường ASCII, như client gốc (nó hạ chữ thường tên trước khi tra
// gói): bảng cảnh ghi "shuhe.scene" cho tệp "shuhe.Scene". Windows tự bỏ qua khác biệt đó, Android
// thì không, nên read_text tra lại từng đoạn đường dẫn khi tên trần không có (đo: 186 trên 219
// cảnh).
#pragma once

#include <cstdint>
#include <expected>
#include <filesystem>
#include <string>
#include <string_view>

namespace game::io {

enum class [[nodiscard]] FileError : std::uint8_t { kNotFound, kUnreadable, kTooLarge };

using TextResult = std::expected<std::string, FileError>;

// Trọn nội dung tệp dạng chuỗi byte, không đổi xuống dòng hay bảng mã.
[[nodiscard]] TextResult read_text(const std::filesystem::path& path);

// Đường dẫn mở được ứng với path khi bỏ qua hoa thường ASCII ở từng đoạn; rỗng khi không có. Trên
// hệ tệp không phân biệt hoa thường (Windows) kết quả có thể giữ cách viết của path.
[[nodiscard]] std::filesystem::path find_ignoring_case(const std::filesystem::path& path);

// Đường dẫn hệ điều hành của một chuỗi UTF-8.
[[nodiscard]] std::filesystem::path path_from_utf8(std::string_view text);

// Đường dẫn ở dạng UTF-8 với dấu phân cách "/", để in ra hoặc ghi vào tệp.
[[nodiscard]] std::string utf8_of(const std::filesystem::path& path);

// Tên lỗi để in ra cho người dùng.
[[nodiscard]] std::string_view describe(FileError error) noexcept;

} // namespace game::io
