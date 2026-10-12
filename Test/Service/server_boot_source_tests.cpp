// Ca B của nợ (a): chạy trọn bộ test `server_boot` (cụm thật, bảy exe thật) rồi so thư mục
// dev/server/data/gate của cây nguồn trước và sau. Test chạy exe thật không được ghi gì vào cây nguồn:
// khoá danh tính của gate, log và dữ liệu đều phải nằm trong cây dựng.
// Phép so dùng tên, cỡ và thời điểm ghi cuối của từng tệp, không đọc nội dung: thư mục ấy ở cây
// chính chứa khoá danh tính thật, và tạo mới, xoá hay ghi lại một tệp đều làm ba số ấy đổi.
#include "core/check.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "process/process.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <ios>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using Path = std::filesystem::path;

#ifdef GAME_SERVER_CONFIG
constexpr std::string_view kConfigDir = GAME_SERVER_CONFIG;
#else
// check.py dịch tệp này không có định nghĩa của CMake; đường dẫn từ gốc dự án để tệp tự đứng được.
constexpr std::string_view kConfigDir = "dev/server/config";
#endif

// Hạn cho cả bộ server_boot; bản ASan chạy cụm bảy tiến trình bốn lượt mất hơn một phút.
constexpr std::chrono::minutes kPatience{10};

// Dấu của một tệp: đổi khi tệp được tạo, bị xoá hay được ghi lại.
struct Mark {
    std::string name;
    std::uintmax_t bytes = 0;
    std::filesystem::file_time_type written;

    [[nodiscard]] friend bool operator==(const Mark&, const Mark&) = default;
};

void add_mark(std::vector<Mark>& marks, const Path& root, const std::filesystem::directory_entry& entry) {
    std::error_code error;
    if (!entry.is_regular_file(error)) return;
    Mark mark;
    mark.name = io::utf8_of(entry.path().lexically_relative(root));
    mark.bytes = entry.file_size(error);
    mark.written = entry.last_write_time(error);
    marks.push_back(std::move(mark));
}

// Dấu của mọi tệp dưới root, xếp theo tên. Thư mục không có thì là danh sách rỗng: một tệp xuất
// hiện sau đó vẫn làm hai lần chụp khác nhau.
[[nodiscard]] std::vector<Mark> snapshot(const Path& root) {
    std::vector<Mark> marks;
    std::error_code error;
    std::filesystem::recursive_directory_iterator entry{root, error};
    while (!error && entry != std::filesystem::recursive_directory_iterator{}) {
        add_mark(marks, root, *entry);
        entry.increment(error);
    }
    std::ranges::sort(marks, {}, &Mark::name);
    return marks;
}

void write_text(const Path& file, std::string_view text) {
    std::ofstream out{file, std::ios::binary | std::ios::trunc};
    out << text;
}

// Phép so có răng: tệp mới, tệp đổi cỡ và tệp bị xoá đều làm hai lần chụp khác nhau.
void snapshot_sees_new_changed_and_removed_files(Context& context) {
    const Path root = io::executable_directory() / "server-boot-source-marks";
    std::error_code error;
    std::filesystem::remove_all(root, error);
    context.expect(snapshot(root).empty(), "thư mục chưa có thì không có dấu nào");
    std::filesystem::create_directories(root / "gate", error);
    const std::vector<Mark> empty = snapshot(root);
    write_text(root / "gate" / "identity.key", "một");
    const std::vector<Mark> created = snapshot(root);
    context.expect(created != empty && created.size() == 1, "tệp mới được thấy");
    write_text(root / "gate" / "identity.key", "một hai");
    const std::vector<Mark> grown = snapshot(root);
    context.expect(grown != created, "tệp ghi lại với cỡ khác được thấy");
    context.expect(snapshot(root) == grown, "không ai ghi thì hai lần chụp bằng nhau");
    std::filesystem::remove(root / "gate" / "identity.key", error);
    context.expect(snapshot(root) != grown, "tệp bị xoá được thấy");
    std::filesystem::remove_all(root, error);
}

// Chạy exe test server_boot nằm cạnh exe này tới khi nó thoát; trả mã thoát, -1 khi không chạy
// được hoặc quá hạn.
[[nodiscard]] int run_server_boot() {
    const std::string exe = io::utf8_of(io::executable_directory() / "server_boot.exe");
    process::Spawn request;
    request.executable = exe;
    request.mode = process::Mode::kCommand;
    core::Result<process::Child> child = process::spawn(request);
    if (!child) return -1;
    const process::ExitStatus status = child->wait_for(kPatience);
    if (status.kind != process::WaitKind::kExited) return -1;
    return status.code;
}

void server_boot_leaves_source_tree_alone(Context& context) {
    const Path watched = io::path_from_utf8(kConfigDir).parent_path() / "data" / "gate";
    const std::vector<Mark> before = snapshot(watched);
    context.expect(run_server_boot() == 0, "bộ server_boot chạy xong và xanh");
    const std::vector<Mark> after = snapshot(watched);
    context.expect(after == before, "dev/server/data/gate của cây nguồn không đổi sau server_boot");
}

constexpr std::array kCases{
    Case{.name = "snapshot_sees_new_changed_and_removed_files", .body = &snapshot_sees_new_changed_and_removed_files},
    Case{.name = "server_boot_leaves_source_tree_alone", .body = &server_boot_leaves_source_tree_alone},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "server_boot_source_clean");
    return 0;
}
