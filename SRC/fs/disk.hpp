// Thao tác trên hệ tệp của hệ điều hành — thay phần còn lại của IToolFileSystem.h: fsCheckPath,
// fsFileExist, fsRemoveFile, fsRenameFile, fsCopyFile, fsCreateDirectory, fsGetLastModifiedTime và
// duyệt thư mục (fsDirectoryIterator*, fsGetSubDirectories, fsGetFilesWithExtension). Mọi hàm nhận
// đường dẫn UTF-8 (gốc: fsCheckPath gọi GetFileAttributesA, iterator đổi mã bằng mbstowcs_s, nên
// đường dẫn tiếng Việt hỏng) và báo lỗi bằng Result (gốc: tạo thư mục coi ACCESS_DENIED là thành
// công). Gốc nhận (thư mục tài nguyên, tên); ở đây ghép trước bằng FileSystem::resolve.
// Nguồn: Forge2 src/fs/disk.hpp@d7fcd76. Khác gốc (so với Forge2): bỏ {} thừa của
// PathInfo::modified và DirectoryEntry::name.
#pragma once

#include "fs/stream.hpp"

#include <chrono>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::fs {

enum class Kind : std::uint8_t {
    kMissing,
    kFile,
    kDirectory,
};

struct PathInfo {
    Kind kind = Kind::kMissing;
    std::uint64_t size = 0;
    // Độ phân giải 100 ns của NTFS; gốc trả time_t một giây nên hai lần lưu trong một giây trùng
    // nhau.
    std::chrono::file_clock::time_point modified;
};

// Loại, cỡ, thời điểm sửa trong một lời gọi (fsCheckPath). Không tồn tại là Kind::kMissing, không
// phải lỗi.
[[nodiscard]] Result<PathInfo> info(std::string_view path);

[[nodiscard]] bool exists(std::string_view path);
// fsFileExist; gốc trả true cả cho thư mục.
[[nodiscard]] bool is_file(std::string_view path);
[[nodiscard]] bool is_directory(std::string_view path);

// fsGetLastModifiedTime; tệp không có là NotFound (gốc trả 0 tức năm 1970).
[[nodiscard]] Result<std::chrono::file_clock::time_point> last_write(std::string_view path);

// Xoá một tệp.
[[nodiscard]] Status remove(std::string_view path);

// Đổi tên, thay đích nếu đã có (gốc dùng _wrename, thất bại khi đích tồn tại).
[[nodiscard]] Status rename(std::string_view source, std::string_view target);

// Chép, ghi đè đích.
[[nodiscard]] Status copy(std::string_view source, std::string_view target);

// Một cấp; đã có thư mục là thành công, trùng tên một tệp là lỗi.
[[nodiscard]] Status create_directory(std::string_view path);

// Mọi cấp còn thiếu; "" là thành công như gốc.
[[nodiscard]] Status create_directories(std::string_view path);

struct DirectoryEntry {
    // Mượn: hết hiệu lực ở lần next() sau.
    std::string_view name;
    bool directory = false;
};

// Duyệt một thư mục, bỏ ".", ".." và mục ngoại tuyến như gốc. Gốc quay vòng về mục đầu sau mục cuối
// để fsGetFilesWithExtension đếm rồi đọc lại; ở đây hết là hết, đọc lại thì mở lại.
class DirectoryReader {
public:
    [[nodiscard]] static Result<DirectoryReader> open(std::string_view path);

    DirectoryReader(DirectoryReader&&) noexcept;
    DirectoryReader& operator=(DirectoryReader&&) noexcept;
    DirectoryReader(const DirectoryReader&) = delete;
    DirectoryReader& operator=(const DirectoryReader&) = delete;
    ~DirectoryReader();

    // Mục kế tiếp; nullopt khi hết.
    [[nodiscard]] Result<std::optional<DirectoryEntry>> next();

private:
    struct State;

    explicit DirectoryReader(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

// Tên tệp trong directory có phần mở rộng ext, không phân biệt hoa thường; "", "*" hay "*.*" là mọi
// tệp (fsGetFilesWithExtension). Một lượt duyệt: gốc duyệt hai lượt, thư mục đổi giữa hai lượt là
// ghi tràn mảng kết quả.
[[nodiscard]] Result<std::vector<std::string>> list_files(std::string_view directory, std::string_view ext = {});

// Tên các thư mục con (fsGetSubDirectories).
[[nodiscard]] Result<std::vector<std::string>> list_directories(std::string_view directory);

} // namespace game::fs
