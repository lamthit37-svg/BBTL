// Một lời gọi GetFileAttributesExW cho cả loại, cỡ và thời điểm sửa (gốc: _wstat cho tồn tại,
// GetFileAttributesA cho loại, stat bản hẹp cho thời gian). Duyệt thư mục bằng FindFirstFileExW với
// FindExInfoBasic (bỏ tên 8.3) và FIND_FIRST_EX_LARGE_FETCH (bộ đệm lớn, ít lời gọi nhân).
// Nguồn: Forge2 src/fs/disk.cpp@d7fcd76. Khác gốc (so với Forge2): macro của windows.h lấy từ
// core/win32.hpp (gốc khai ở CMake), header con của Win32 include trực tiếp; các câu if trong vòng
// của make_tree, collect và DirectoryReader::next lên điều kiện lặp, câu if (keep) của collect tách
// thành keep_name (ghi tại chỗ); tham số c của lambda lower thành unit; bỏ {} thừa của State::find
// và State::name.
#include "fs/disk.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"

#include <errhandlingapi.h>
#include <fileapi.h>
#include <handleapi.h>
#include <minwinbase.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::fs {

using core::ErrorCode;
using core::fail;
using core::fail_system;

namespace {

[[nodiscard]] std::chrono::file_clock::time_point to_clock(const FILETIME& time) noexcept {
    // file_clock của MSVC đếm 100 ns từ 1601, đúng mốc và nhịp của FILETIME.
    const std::uint64_t ticks = (std::uint64_t{time.dwHighDateTime} << 32U) | time.dwLowDateTime;
    const auto since = std::chrono::file_clock::duration(static_cast<std::int64_t>(ticks));
    return std::chrono::file_clock::time_point(since);
}

[[nodiscard]] bool is_missing(DWORD error) noexcept {
    return error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND;
}

// So không phân biệt hoa thường theo ASCII, như _strnicmp của gốc.
[[nodiscard]] bool same_ascii(std::string_view left, std::string_view right) noexcept {
    const auto lower = [](char unit) { return unit >= 'A' && unit <= 'Z' ? static_cast<char>(unit + 32) : unit; };
    return std::ranges::equal(left, right, {}, lower, lower);
}

// Phần mở rộng cần khớp sau khi bỏ "*" và "." đầu; rỗng nghĩa là mọi tệp.
[[nodiscard]] std::string_view wanted_extension(std::string_view ext) noexcept {
    if (ext.starts_with('*')) ext.remove_prefix(1);
    if (ext.starts_with('.')) ext.remove_prefix(1);
    return ext == "*" ? std::string_view{} : ext;
}

// path đã chuẩn hoá: mỗi cấp cha là một thư mục thật, không còn "." hay ".." giữa chừng.
// Vòng lặp, không đệ quy: đường \\?\ hàng nghìn cấp tràn stack nếu mỗi cấp là một frame.
Status make_tree(std::string_view path) {
    if (path.empty() || is_directory(path)) return core::ok();
    std::vector<std::string_view> missing;
    std::string_view cursor = path;
    // Khác gốc: gốc thoát vòng bằng if (above.empty() || above.size() >= cursor.size()) break đặt
    // trước cursor = above. Điều kiện ấy (đảo dấu) thành climbing ở điều kiện lặp, đứng đầu để
    // is_directory không bị gọi thêm lần nào; cursor chỉ đổi khi còn leo tiếp.
    bool climbing = true;
    while (climbing && !cursor.empty() && !is_directory(cursor)) {
        missing.push_back(cursor);
        const std::string_view above = parent(cursor);
        climbing = !above.empty() && above.size() < cursor.size();
        cursor = climbing ? above : cursor;
    }
    // Khác gốc: gốc trả lỗi ngay trong thân vòng; ở đây lỗi dừng vòng qua điều kiện lặp.
    Status made = core::ok();
    for (std::size_t index = missing.size(); made && index > 0; --index) {
        made = create_directory(missing.at(index - 1));
    }
    return made;
}

// Khác gốc: câu if (keep(...)) trong thân vòng lặp của collect tách ra đây.
template <class Keep>
void keep_name(std::vector<std::string>& names, const DirectoryEntry& entry, Keep& keep) {
    if (keep(entry)) names.emplace_back(entry.name);
}

template <class Keep>
[[nodiscard]] Result<std::vector<std::string>> collect(std::string_view directory, Keep keep) {
    auto reader = DirectoryReader::open(directory);
    if (!reader) return std::unexpected(std::move(reader).error());
    std::vector<std::string> names;
    // Khác gốc: gốc là for (;;) có ba câu if trong thân: lỗi thì trả lỗi, hết mục thì trả names,
    // keep nhận thì thêm tên. Hai điều kiện dừng lên điều kiện lặp, lỗi trả sau vòng; câu thứ ba
    // là keep_name. Thứ tự next rồi keep giữ nguyên.
    auto entry = reader->next();
    while (entry && *entry) {
        keep_name(names, **entry, keep);
        entry = reader->next();
    }
    if (!entry) return std::unexpected(std::move(entry).error());
    return names;
}

} // namespace

struct DirectoryReader::State {
    // FindClose, không phải CloseHandle.
    struct Closer {
        void operator()(void* handle) const noexcept { FindClose(handle); }
    };

    std::unique_ptr<void, Closer> find;
    WIN32_FIND_DATAW data{};
    std::string name;
    // Mục đầu đã nằm trong data từ FindFirstFileExW, chưa trả ra.
    bool pending = true;

    // Đưa mục kế tiếp vào data; false khi hết.
    [[nodiscard]] Result<bool> advance() {
        const bool first = std::exchange(pending, false);
        if (first) return true;
        if (FindNextFileW(find.get(), &data) != 0) return true;
        const DWORD error = GetLastError();
        if (error == ERROR_NO_MORE_FILES) return false;
        return fail_system(error, "không đọc được thư mục");
    }

    // cFileName là mảng cố định kết thúc bằng số 0.
    [[nodiscard]] std::wstring_view entry() const noexcept { return std::data(data.cFileName); }

    [[nodiscard]] bool skipped() const noexcept {
        const bool offline = (data.dwFileAttributes & FILE_ATTRIBUTE_OFFLINE) != 0;
        return offline || entry() == L"." || entry() == L"..";
    }
};

DirectoryReader::DirectoryReader(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
DirectoryReader::DirectoryReader(DirectoryReader&&) noexcept = default;
DirectoryReader& DirectoryReader::operator=(DirectoryReader&&) noexcept = default;
DirectoryReader::~DirectoryReader() = default;

Result<DirectoryReader> DirectoryReader::open(std::string_view path) {
    // Đường dẫn rỗng là thư mục hiện hành; gốc ghép thành "\*" nên duyệt gốc ổ đĩa.
    const std::wstring pattern = native_path(join(path.empty() ? "." : path, "*"));
    auto state = std::make_unique<State>();
    const DWORD flags = FIND_FIRST_EX_LARGE_FETCH;
    HANDLE found =
        FindFirstFileExW(pattern.c_str(), FindExInfoBasic, &state->data, FindExSearchNameMatch, nullptr, flags);
    const bool opened = found != INVALID_HANDLE_VALUE;
    if (!opened) return fail_system(GetLastError(), "không mở được thư mục", path);
    state->find.reset(found);
    return DirectoryReader(std::move(state));
}

Result<std::optional<DirectoryEntry>> DirectoryReader::next() {
    // Khác gốc: gốc là for (;;) có ba câu if trong thân (lỗi, hết mục, mục bị bỏ qua thì continue).
    // Ở đây vòng chỉ còn bước tiến, dừng khi lỗi, hết mục hay gặp mục không bị bỏ qua; hai câu trả
    // sớm và phần dựng kết quả đứng sau vòng theo đúng thứ tự của gốc.
    auto advanced = state_->advance();
    while (advanced && *advanced && state_->skipped()) {
        advanced = state_->advance();
    }
    if (!advanced) return std::unexpected(std::move(advanced).error());
    if (!*advanced) return std::nullopt;
    state_->name = core::narrow(state_->entry());
    const bool directory = (state_->data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    return DirectoryEntry{.name = state_->name, .directory = directory};
}

// Thư mục rồi phần mở rộng cần lọc: hai vai khác hẳn, theo fsGetFilesWithExtension (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
Result<std::vector<std::string>> list_files(std::string_view directory, std::string_view ext) {
    const std::string_view wanted = wanted_extension(ext);
    const auto keep = [wanted](const DirectoryEntry& entry) {
        return !entry.directory && (wanted.empty() || same_ascii(extension(entry.name), wanted));
    };
    return collect(directory, keep);
}

Result<std::vector<std::string>> list_directories(std::string_view directory) {
    return collect(directory, [](const DirectoryEntry& entry) { return entry.directory; });
}

Result<PathInfo> info(std::string_view path) {
    const std::wstring wide = native_path(path);
    WIN32_FILE_ATTRIBUTE_DATA data{};
    const BOOL known = GetFileAttributesExW(wide.c_str(), GetFileExInfoStandard, &data);
    const DWORD error = known != 0 ? 0 : GetLastError();
    if (known == 0 && is_missing(error)) return PathInfo{};
    if (known == 0) return fail_system(error, "không hỏi được đường dẫn", path);
    const bool directory = (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    const std::uint64_t size = (std::uint64_t{data.nFileSizeHigh} << 32U) | data.nFileSizeLow;
    return PathInfo{
        .kind = directory ? Kind::kDirectory : Kind::kFile, .size = size, .modified = to_clock(data.ftLastWriteTime)};
}

bool exists(std::string_view path) {
    const auto found = info(path);
    return found && found->kind != Kind::kMissing;
}

bool is_file(std::string_view path) {
    const auto found = info(path);
    return found && found->kind == Kind::kFile;
}

bool is_directory(std::string_view path) {
    const auto found = info(path);
    return found && found->kind == Kind::kDirectory;
}

Result<std::chrono::file_clock::time_point> last_write(std::string_view path) {
    const auto found = info(path);
    if (!found) return std::unexpected(found.error());
    if (found->kind == Kind::kMissing) return fail(ErrorCode::kNotFound, "không có tệp", path);
    return found->modified;
}

Status remove(std::string_view path) {
    if (DeleteFileW(native_path(path).c_str()) != 0) return core::ok();
    return fail_system(GetLastError(), "không xoá được tệp", path);
}

// Nguồn rồi đích là thứ tự quen của hàm đổi tên và chép, như MoveFileExW (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
Status rename(std::string_view source, std::string_view target) {
    const std::wstring from = native_path(source);
    const std::wstring into = native_path(target);
    const DWORD flags = MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED;
    if (MoveFileExW(from.c_str(), into.c_str(), flags) != 0) return core::ok();
    return fail_system(GetLastError(), "không đổi tên được", source);
}

Status copy(std::string_view source, std::string_view target) {
    const std::wstring from = native_path(source);
    const std::wstring into = native_path(target);
    if (CopyFileW(from.c_str(), into.c_str(), FALSE) != 0) return core::ok();
    return fail_system(GetLastError(), "không chép được tệp", source);
}
// NOLINTEND(bugprone-easily-swappable-parameters)

Status create_directory(std::string_view path) {
    if (CreateDirectoryW(native_path(path).c_str(), nullptr) != 0) return core::ok();
    const DWORD error = GetLastError();
    const bool taken = error == ERROR_ALREADY_EXISTS;
    if (!taken) return fail_system(error, "không tạo được thư mục", path);
    if (is_directory(path)) return core::ok();
    return fail(ErrorCode::kNotADirectory, "đã có tệp trùng tên thư mục", path);
}

// Chuẩn hoá trước: đệ quy theo parent trên chuỗi thô của "a/../b" sẽ tạo thừa thư mục "a".
Status create_directories(std::string_view path) {
    return make_tree(normalize(path));
}

} // namespace game::fs
