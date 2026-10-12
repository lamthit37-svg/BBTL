// Test của io: đọc tệp theo tên không phân biệt hoa thường. Dữ liệu của client gốc gọi tên tệp lệch
// hoa thường so với tệp thật (bảng cảnh ghi "shuhe.scene", tệp là "shuhe.Scene"); Windows bỏ qua
// khác biệt đó còn Android thì không, nên io phải tự tra (KT-01, KT-02).
#include "core/check.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "test.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <ios>
#include <string>
#include <system_error>

namespace game::test {
namespace {

// Thư mục dữ liệu thử, tương đối với thư mục làm việc của test.
[[nodiscard]] std::filesystem::path root() {
    return "io_tests_data";
}

// Dựng io_tests_data/Scene/Abc.Scene trong thư mục làm việc của test.
void write_sample() {
    std::error_code ignored;
    std::filesystem::remove_all(root(), ignored);
    std::filesystem::create_directories(root() / "Scene", ignored);
    std::ofstream output(root() / "Scene" / "Abc.Scene", std::ios::binary);
    output << "noi dung";
}

void read_text_finds_exact_name(Context& context) {
    write_sample();
    const io::TextResult text = io::read_text(root() / "Scene" / "Abc.Scene");
    context.expect(text.has_value(), "tên đúng hoa thường đọc được");
    context.expect(text.value_or(std::string{}) == "noi dung", "nội dung giữ nguyên");
}

void read_text_ignores_ascii_case(Context& context) {
    write_sample();
    const io::TextResult file_only = io::read_text(root() / "Scene" / "abc.scene");
    context.expect(file_only.has_value(), "tên tệp lệch hoa thường vẫn đọc được");
    const io::TextResult both = io::read_text(root() / "scene" / "ABC.SCENE");
    context.expect(both.has_value(), "thư mục và tệp cùng lệch hoa thường vẫn đọc được");
    context.expect(both.value_or(std::string{}) == "noi dung", "đọc đúng tệp");
}

void read_text_reports_missing_file(Context& context) {
    write_sample();
    const io::TextResult text = io::read_text(root() / "Scene" / "khong-co.Scene");
    const bool is_missing = !text && text.error() == io::FileError::kNotFound;
    context.expect(is_missing, "tệp không có là kNotFound");
    const io::TextResult folder = io::read_text(root() / "Scene");
    context.expect(!folder.has_value(), "thư mục không phải tệp đọc được");
}

void find_ignoring_case_returns_openable_path(Context& context) {
    write_sample();
    const std::filesystem::path found = io::find_ignoring_case(root() / "SCENE" / "abc.scene");
    context.expect(io::read_text(found).has_value(), "đường dẫn trả về mở được");
    context.expect(io::find_ignoring_case(root() / "Scene" / "xyz").empty(), "không có thì rỗng");
}

// Trang không có, hay là một thư mục, thì từ chối và không hiện hộp thoại nào. Ca mở được thật
// không nằm ở đây: nó bật trình duyệt của người đang dùng máy.
void open_in_browser_refuses_what_is_not_a_file(Context& context) {
    write_sample();
    context.expect(!io::open_in_browser(root() / "Web" / "khong_co.html"), "tệp không có");
    context.expect(!io::open_in_browser(root() / "Scene"), "thư mục");
}

// Ca cuối của bảng: dọn thư mục thử, để chạy tay exe ở gốc dự án không để lại tệp lạ cho git.
void sample_folder_is_removed(Context& context) {
    std::error_code failure;
    std::filesystem::remove_all(root(), failure);
    const bool is_gone = !failure && !std::filesystem::exists(root(), failure);
    context.expect(is_gone, "thư mục thử đã được dọn");
}

constexpr std::array kCases{
    Case{.name = "read_text_finds_exact_name", .body = &read_text_finds_exact_name},
    Case{.name = "read_text_ignores_ascii_case", .body = &read_text_ignores_ascii_case},
    Case{.name = "read_text_reports_missing_file", .body = &read_text_reports_missing_file},
    Case{.name = "find_ignoring_case_returns_openable_path", .body = &find_ignoring_case_returns_openable_path},
    Case{.name = "open_in_browser_refuses_what_is_not_a_file", .body = &open_in_browser_refuses_what_is_not_a_file},
    Case{.name = "sample_folder_is_removed", .body = &sample_folder_is_removed},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "io_tests: mọi ca phải qua");
    return 0;
}
