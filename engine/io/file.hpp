/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/io/file.hpp
 *  PHÂN HỆ   : Io / File
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - API đọc tệp dữ liệu của client từ đĩa. Tên mesh và map trong mã là UTF-8;
 *    all.material và script hạt ghi tên ảnh bằng GBK (trang 936):
 *    path_from_utf8 nhận cả hai, không qua bảng mã ANSI.
 *  - Tệp là dữ liệu ngoài: mọi lỗi đọc trả qua std::expected, không dừng tiến
 *    trình; có trần cỡ để tệp hỏng không nuốt hết bộ nhớ.
 *  - Tên tệp tra không phân biệt hoa thường ASCII như client gốc (bảng cảnh ghi
 *    "shuhe.scene" cho tệp "shuhe.Scene"); Android phân biệt nên read_text tra
 *    lại từng đoạn đường dẫn (đo: 186 trên 219 cảnh).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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

// Đường dẫn hệ điều hành. UTF-8 giữ nguyên. Byte không phải UTF-8 đọc theo trang 936. Không ném:
// luồng vẽ không bắt exception, một tên GBK ném ra sẽ abort cả tiến trình.
[[nodiscard]] std::filesystem::path path_from_utf8(std::string_view text);

// Đường dẫn ở dạng UTF-8 với dấu phân cách "/", để in ra hoặc ghi vào tệp.
[[nodiscard]] std::string utf8_of(const std::filesystem::path& path);

// Tên lỗi để in ra cho người dùng.
[[nodiscard]] std::string_view describe(FileError error) noexcept;

} // namespace game::io
