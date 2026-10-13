// Phần của fs mà thiết bị (Android, iOS) cần: đọc cả tệp, ghi nguyên tử, hỏi tệp và tạo thư mục. Bản
// Win32 (file.cpp, disk.cpp) gọi thẳng CreateFileW; ở đây dùng open/read/write của POSIX và
// std::filesystem, cùng hợp đồng như khai báo ở file.hpp và disk.hpp. Mọi đường dẫn là UTF-8.
// Chỉ làm đúng năm hàm mà resource và world gọi; thêm hàm khác của disk.hpp khi nơi gọi cần.
#include "core/error.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/stream.hpp"

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <limits>
#include <span>
#include <string>
#include <string_view>
#include <system_error>

namespace game::fs {
namespace {

using core::ErrorCode;
using core::fail;

[[nodiscard]] ErrorCode code_of(int error) noexcept {
    switch (error) {
    case ENOENT: return ErrorCode::kNotFound;
    case EACCES:
    case EPERM: return ErrorCode::kPermissionDenied;
    case EEXIST: return ErrorCode::kAlreadyExists;
    case ENOTDIR: return ErrorCode::kNotADirectory;
    case EISDIR: return ErrorCode::kIsADirectory;
    case ENOSPC: return ErrorCode::kNoSpace;
    case EROFS: return ErrorCode::kReadOnly;
    case EBUSY: return ErrorCode::kBusy;
    case ENOMEM: return ErrorCode::kOutOfMemory;
    default: return ErrorCode::kIo;
    }
}

[[nodiscard]] core::Failure failed(int error, core::Message message, std::string_view path) {
    return fail(code_of(error), message, path);
}

// Đóng descriptor khi ra khỏi phạm vi, kể cả đường lỗi.
class Descriptor {
public:
    explicit Descriptor(int fd) noexcept : fd_(fd) {}
    ~Descriptor() {
        if (fd_ >= 0) ::close(fd_);
    }
    Descriptor(const Descriptor&) = delete;
    Descriptor& operator=(const Descriptor&) = delete;
    Descriptor(Descriptor&&) = delete;
    Descriptor& operator=(Descriptor&&) = delete;

    [[nodiscard]] int get() const noexcept { return fd_; }
    // Đóng tường minh để biết lỗi của close (NFS và vài hệ tệp báo lỗi ghi muộn ở đây).
    [[nodiscard]] int close() noexcept {
        const int closed = ::close(fd_);
        fd_ = -1;
        return closed;
    }

private:
    int fd_ = -1;
};

// Đọc đúng out.size() byte từ offset 0, lặp qua các lần đọc ngắn và EINTR. Trả số byte đọc được (ít
// hơn khi tệp co lại giữa lúc hỏi cỡ và lúc đọc), hoặc errno.
[[nodiscard]] std::expected<std::size_t, int> read_all(int fd, std::span<std::byte> out) noexcept {
    std::size_t done = 0;
    while (done < out.size()) {
        const ssize_t got = ::pread(fd, out.data() + done, out.size() - done, static_cast<off_t>(done));
        if (got < 0 && errno == EINTR) continue;
        if (got < 0) return std::unexpected(errno);
        if (got == 0) break;
        done += static_cast<std::size_t>(got);
    }
    return done;
}

[[nodiscard]] std::expected<void, int> write_all(int fd, std::span<const std::byte> data) noexcept {
    std::size_t done = 0;
    while (done < data.size()) {
        const ssize_t put = ::write(fd, data.data() + done, data.size() - done);
        if (put < 0 && errno == EINTR) continue;
        if (put < 0) return std::unexpected(errno);
        done += static_cast<std::size_t>(put);
    }
    return {};
}

// Tên tạm riêng theo tiến trình và lần gọi, cùng thư mục với đích để rename không qua hệ tệp khác.
[[nodiscard]] std::string temporary_name(std::string_view path) {
    static std::atomic<std::uint32_t> counter{0};
    return std::format("{}.{}.{}.tmp", path, static_cast<long>(::getpid()), counter.fetch_add(1));
}

} // namespace

Result<Bytes> read_file(std::string_view path) {
    const std::string native(path);
    const Descriptor file(::open(native.c_str(), O_RDONLY | O_CLOEXEC));
    if (file.get() < 0) return failed(errno, "không mở được tệp", path);
    struct stat info{};
    if (::fstat(file.get(), &info) != 0) return failed(errno, "không hỏi được cỡ tệp", path);
    if (S_ISDIR(info.st_mode)) return fail(ErrorCode::kIsADirectory, "đường dẫn là thư mục", path);
    const auto total = static_cast<std::uint64_t>(info.st_size);
    constexpr std::uint64_t kLimit = std::numeric_limits<std::size_t>::max();
    if (total > kLimit) return fail(ErrorCode::kOverflow, "tệp lớn hơn bộ nhớ", path);
    Bytes bytes(static_cast<std::size_t>(total));
    const std::expected<std::size_t, int> got = read_all(file.get(), bytes.span());
    if (!got) return failed(got.error(), "không đọc được tệp", path);
    // Tệp co lại giữa lúc hỏi cỡ và lúc đọc thì giữ phần thật sự đọc được.
    bytes.shrink(*got);
    return bytes;
}

Status write_file_atomic(std::string_view path, std::span<const std::byte> data) {
    const std::string temporary = temporary_name(path);
    Descriptor file(::open(temporary.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644));
    if (file.get() < 0) return failed(errno, "không tạo được tệp tạm", temporary);
    const std::expected<void, int> wrote = write_all(file.get(), data);
    // fsync trước rename: sau mất điện người đọc thấy bản cũ hoặc bản mới đủ, không bao giờ tệp rỗng.
    const int synced = wrote ? ::fsync(file.get()) : 0;
    const int synced_error = errno;
    const int closed = file.close();
    const int closed_error = errno;
    const std::string target(path);
    const bool is_written = wrote && synced == 0 && closed == 0;
    if (is_written && ::rename(temporary.c_str(), target.c_str()) == 0) return core::ok();
    const int error = !wrote ? wrote.error() : (synced != 0 ? synced_error : (closed != 0 ? closed_error : errno));
    ::unlink(temporary.c_str());
    return failed(error, "không ghi được tệp", path);
}

bool is_file(std::string_view path) {
    std::error_code error;
    const std::filesystem::path native{std::string(path)};
    return std::filesystem::exists(native, error) && !error;
}

Result<std::chrono::file_clock::time_point> last_write(std::string_view path) {
    std::error_code error;
    const std::filesystem::path native{std::string(path)};
    const auto stamp = std::filesystem::last_write_time(native, error);
    if (error) return fail(error == std::errc::no_such_file_or_directory ? ErrorCode::kNotFound : ErrorCode::kIo,
        "không hỏi được thời điểm sửa", path);
    return stamp;
}

Status create_directories(std::string_view path) {
    if (path.empty()) return core::ok();
    std::error_code error;
    const std::filesystem::path native{std::string(path)};
    std::filesystem::create_directories(native, error);
    if (error) return failed(error.value(), "không tạo được thư mục", path);
    return core::ok();
}

} // namespace game::fs
