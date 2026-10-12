// Đường dẫn UTF-8 — thay phần "Minor filename manipulation" của IToolFileSystem.h (_Ref). Mọi hàm
// làm việc trên chuỗi UTF-8, không giới hạn FS_MAX_PATH 512, không cắt im lặng, không ghi vào bộ
// đệm của người gọi. normalize giữ luật của fsNormalizePathContinue vì tên trong archive Buny được
// bộ ghi chuẩn hoá bằng chính luật đó: "./" bỏ, "//" gộp, "a/../b" thành "b", ".." không giải được
// thì giữ, "a/.." thành ".", '/' cuối giữ. Khác gốc, có chủ ý: gốc ổ đĩa "C:/.." ra "C:/" (gốc ra
// "."), UNC "//máy/chia sẻ" giữ hai dấu đầu, join để tên tuyệt đối thắng, parent("/a") ra "/" (gốc
// ra ""). Không dùng std::filesystem::path cho đường dẫn ảo: nó đi qua wchar_t và lexically_normal
// giải ".." sau gốc khác gốc.
// Nguồn: Forge2 src/fs/path.hpp@d7fcd76. Khác gốc (so với Forge2): tham số c của is_separator thành
// unit; bỏ {} thừa của ba thành viên PathParts.
#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace game::fs {

inline constexpr char kSeparator = '/';

[[nodiscard]] constexpr bool is_separator(char unit) noexcept {
    return unit == '/' || unit == '\\';
}

// Dạng chuẩn với dấu phân cách separator; "" giữ "", chuỗi rút hết thành ".".
[[nodiscard]] std::string normalize(std::string_view path, char separator = kSeparator);

[[nodiscard]] bool is_normalized(std::string_view path, char separator = kSeparator);

// Có gốc: "/", "X:/" hay UNC "//máy".
[[nodiscard]] bool is_absolute(std::string_view path) noexcept;

// dir rồi name, chuẩn hoá, bỏ dấu phân cách cuối trừ khi chỉ còn gốc; name tuyệt đối hay dir rỗng
// thì chỉ còn name (fsMergeDirAndFileName, fsAppendPathComponent).
[[nodiscard]] std::string join(std::string_view dir, std::string_view name, char separator = kSeparator);

// Các hàm trả string_view dưới đây MƯỢN path: path phải sống lâu hơn kết quả.

// Thư mục cha không có dấu phân cách cuối, trừ gốc; "a" ra "".
[[nodiscard]] std::string_view parent(std::string_view path) noexcept;

// Phần sau dấu phân cách cuối cùng.
[[nodiscard]] std::string_view file_name(std::string_view path) noexcept;

// Tên tệp bỏ phần mở rộng (fsGetPathFileName).
[[nodiscard]] std::string_view stem(std::string_view path) noexcept;

// Phần mở rộng không có dấu chấm (fsGetPathExtension); tệp ẩn ".abc" không có phần mở rộng.
[[nodiscard]] std::string_view extension(std::string_view path) noexcept;

// fsSplitPath: nullopt khi không có dấu phân cách hay không có dấu chấm.
struct PathParts {
    std::optional<std::string_view> parent;
    std::string_view stem;
    std::optional<std::string_view> extension;
};

[[nodiscard]] PathParts split(std::string_view path) noexcept;

// Thêm phần mở rộng, có hay không có '.' đầu đều được; rỗng thì giữ nguyên path.
[[nodiscard]] std::string append_extension(std::string_view path, std::string_view ext);

// Thay phần mở rộng; ext rỗng thì bỏ phần mở rộng.
[[nodiscard]] std::string replace_extension(std::string_view path, std::string_view ext);

} // namespace game::fs
