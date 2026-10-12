#include "io/file.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <fstream>
#include <ios>
#include <string>
#include <string_view>
#include <system_error>

namespace game::io {
namespace {

// Tệp lớn nhất client đọc trọn vào bộ nhớ: .Scene lớn nhất của kho gốc là 2,6 MB.
constexpr std::uintmax_t kMaxFileBytes = std::uintmax_t{256} * 1024 * 1024;

using Path = std::filesystem::path;

// Chữ thường ASCII; byte khác, kể cả byte của ký tự UTF-8 nhiều byte, giữ nguyên.
[[nodiscard]] char lower_ascii(char letter) noexcept {
    const bool is_upper = letter >= 'A' && letter <= 'Z';
    return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
}

// entry khi tên của nó trùng wanted nếu bỏ qua hoa thường ASCII; không thì rỗng.
[[nodiscard]] Path matched(const Path& entry, std::string_view wanted) {
    const std::string name = utf8_of(entry.filename());
    const bool is_same = std::ranges::equal(name, wanted, {}, lower_ascii, lower_ascii);
    return is_same ? entry : Path{};
}

// Mục của folder trùng tên name khi bỏ qua hoa thường; rỗng khi không có hay không liệt kê được.
[[nodiscard]] Path entry_like(const Path& folder, std::string_view wanted) {
    std::error_code error;
    const std::filesystem::directory_iterator end;
    std::filesystem::directory_iterator walk(folder, error);
    Path found;
    for (; !error && walk != end && found.empty(); walk.increment(error)) {
        found = matched(walk->path(), wanted);
    }
    return found;
}

// Đường đang lần theo: current là phần đã khớp với tên thật trên đĩa.
struct Trail {
    Path current;
    bool is_lost = false;
};

// Đi thêm một đoạn: có thật thì đi thẳng, không thì tìm mục trùng tên bỏ qua hoa thường.
void follow(Trail& trail, const Path& part) {
    if (trail.is_lost) return;
    const Path direct = trail.current / part;
    std::error_code error;
    if (std::filesystem::exists(direct, error)) {
        trail.current = direct;
        return;
    }
    const Path folder = trail.current.empty() ? Path(".") : trail.current;
    trail.current = entry_like(folder, utf8_of(part));
    trail.is_lost = trail.current.empty();
}

} // namespace

Path find_ignoring_case(const Path& path) {
    Trail trail;
    trail.current = path.root_path();
    for (const Path& part : path.relative_path()) {
        follow(trail, part);
    }
    return trail.is_lost ? Path{} : trail.current;
}

TextResult read_text(const std::filesystem::path& path) {
    std::error_code error;
    // Tên trong dữ liệu của client gốc lệch hoa thường so với tệp thật; chỉ tra lại khi tên trần
    // hụt.
    const bool is_direct = std::filesystem::is_regular_file(path, error);
    const Path real = is_direct ? path : find_ignoring_case(path);
    if (real.empty()) return std::unexpected(FileError::kNotFound);
    const std::uintmax_t size = std::filesystem::file_size(real, error);
    if (error) return std::unexpected(FileError::kNotFound);
    if (size > kMaxFileBytes) return std::unexpected(FileError::kTooLarge);
    std::ifstream input(real, std::ios::binary);
    if (!input) return std::unexpected(FileError::kUnreadable);
    std::string text(static_cast<std::size_t>(size), '\0');
    input.read(text.data(), static_cast<std::streamsize>(size));
    const bool is_whole = input.gcount() == static_cast<std::streamsize>(size);
    if (!is_whole) return std::unexpected(FileError::kUnreadable);
    return text;
}

std::filesystem::path path_from_utf8(std::string_view text) {
    const std::u8string utf8(text.begin(), text.end());
    return {utf8};
}

std::string utf8_of(const std::filesystem::path& path) {
    const std::u8string text = path.generic_u8string();
    return {text.begin(), text.end()};
}

std::string_view describe(FileError error) noexcept {
    switch (error) {
    case FileError::kNotFound: return "không thấy tệp";
    case FileError::kUnreadable: return "không đọc được tệp";
    case FileError::kTooLarge: return "tệp quá lớn";
    }
    return "lỗi tệp không rõ";
}

} // namespace game::io
