/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/fs/file.cpp
 *  PHÂN HỆ   : Fs / File
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bảng chế độ mở thay fsFileModeToString của _Ref, nơi FM_READ_WRITE_APPEND
 *    và FM_APPEND rơi vào "r" (mở chỉ đọc) và FM_READ_APPEND thành "ab+" (tạo
 *    tệp, ghi được). Ghi ép về cuối dùng offset 0xFFFFFFFF'FFFFFFFF của
 *    WriteFile thay vì quyền FILE_APPEND_DATA, vì FlushFileBuffers cần
 *    GENERIC_WRITE.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mở chỉ đọc chia cả FILE_SHARE_DELETE: trình sửa thay tệp bằng đổi tên trong lúc engine còn giữ nó (nạp nóng) mà
// không gặp lỗi chia sẻ. Nguồn: Forge2 src/fs/file.cpp@d7fcd76.

// Khác gốc (so với Forge2): macro của windows.h lấy từ core/win32.hpp (gốc khai ở CMake), header con của Win32
// include trực tiếp; các câu if trong vòng của write_at và read_at lên điều kiện lặp (ghi tại chỗ); biến at của
// write_at thành target; bỏ bốn phép ép uint64 sang size_t mà GCC báo thừa (kèm static_assert nền 64 bit).

#include "fs/file.hpp"

#include "core/error.hpp"
#include "core/handle.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "core/trace.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "fs/stream.hpp"

#include <errhandlingapi.h>
#include <fileapi.h>
#include <handleapi.h>
#include <memoryapi.h>
#include <minwinbase.h>
#include <processthreadsapi.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::fs {

using core::ErrorCode;
using core::fail;
using core::fail_system;
using core::UniqueHandle;

namespace {

// Khác gốc: gốc ép hiệu hai vị trí và cỡ tệp (uint64) sang std::size_t ở take_buffered, prefetch,
// MappedFile::open và read_file. Trên nền 64 bit hai kiểu cùng độ rộng (GCC báo -Wuseless-cast),
// nên bỏ các phép ép ấy và chặn nền 32 bit ngay tại đây.
static_assert(sizeof(std::size_t) == sizeof(std::uint64_t), "fs/file cần nền 64 bit");

// Một lần ReadFile/WriteFile chuyển tối đa DWORD byte; chia 1 GiB cho chẵn trang.
constexpr std::size_t kMaxTransfer = std::size_t{1} << 30U;
// Dưới ngưỡng này mọi API Win32 nhận đường dẫn thường; CreateDirectoryW dừng ở MAX_PATH - 12.
constexpr std::size_t kShortPath = MAX_PATH - 12;
// Offset của WriteFile nghĩa là "ghi vào cuối tệp", nguyên tử với người ghi khác.
constexpr std::uint64_t kEndOfFile = 0xFFFF'FFFF'FFFF'FFFF;

[[nodiscard]] OVERLAPPED overlapped_at(std::uint64_t offset) noexcept {
    OVERLAPPED overlapped{};
    // OVERLAPPED đặt offset trong một union với Pointer; đây là hợp đồng của ReadFile và WriteFile.
    // NOLINTBEGIN(cppcoreguidelines-pro-type-union-access)
    overlapped.Offset = static_cast<DWORD>(offset);
    overlapped.OffsetHigh = static_cast<DWORD>(offset >> 32U);
    // NOLINTEND(cppcoreguidelines-pro-type-union-access)
    return overlapped;
}

[[nodiscard]] DWORD transfer_size(std::size_t size) noexcept {
    return static_cast<DWORD>(std::min(size, kMaxTransfer));
}

// Đường dẫn tuyệt đối có tiền tố \\?\ (hay \\?\UNC\): bỏ giới hạn MAX_PATH, nhưng Win32 không còn
// giải "..", nên GetFullPathNameW giải trước.
[[nodiscard]] std::wstring extended(const std::wstring& wide) {
    const DWORD need = GetFullPathNameW(wide.c_str(), 0, nullptr, nullptr);
    if (need == 0) return wide;
    const auto fill = [&](wchar_t* out, std::size_t room) {
        const DWORD written = GetFullPathNameW(wide.c_str(), static_cast<DWORD>(room), out, nullptr);
        return written < room ? std::size_t{written} : std::size_t{0};
    };
    std::wstring full;
    full.resize_and_overwrite(need, fill);
    if (full.empty()) return wide;
    if (full.starts_with(L"\\\\")) return L"\\\\?\\UNC\\" + full.substr(2);
    return L"\\\\?\\" + full;
}

struct Plan {
    DWORD access = 0;
    DWORD share = 0;
    DWORD disposition = 0;
    DWORD flags = FILE_ATTRIBUTE_NORMAL;
};

// Ghi một mình thì cắt rỗng; có Read hay Append thì giữ nội dung; chỉ đọc thì tệp phải có sẵn.
[[nodiscard]] DWORD disposition_for(Mode mode) noexcept {
    if (!has(mode, Mode::kWrite)) return OPEN_EXISTING;
    const bool keeps = has(mode, Mode::kRead) || has(mode, Mode::kAppend);
    return keeps ? OPEN_ALWAYS : CREATE_ALWAYS;
}

[[nodiscard]] DWORD share_for(Mode mode) noexcept {
    if (!has(mode, Mode::kWrite)) return FILE_SHARE_READ | FILE_SHARE_DELETE;
    return has(mode, Mode::kAllowRead) ? FILE_SHARE_READ : 0;
}

[[nodiscard]] Plan plan_for(Mode mode) noexcept {
    Plan plan;
    if (has(mode, Mode::kRead)) plan.access |= GENERIC_READ;
    if (has(mode, Mode::kWrite)) plan.access |= GENERIC_WRITE;
    plan.share = share_for(mode);
    plan.disposition = disposition_for(mode);
    const DWORD pattern = has(mode, Mode::kRandom) ? FILE_FLAG_RANDOM_ACCESS : FILE_FLAG_SEQUENTIAL_SCAN;
    if (!has(mode, Mode::kWrite)) plan.flags |= pattern;
    return plan;
}

// CreateFileW trên thư mục báo ERROR_ACCESS_DENIED; hỏi lại thuộc tính để trả IsADirectory như
// EISDIR của gốc.
[[nodiscard]] core::Failure open_failure(const std::wstring& wide, std::string_view path) {
    const DWORD error = GetLastError();
    const DWORD attributes = GetFileAttributesW(wide.c_str());
    const bool exists = attributes != INVALID_FILE_ATTRIBUTES;
    const bool directory = exists && (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    if (directory) return fail(ErrorCode::kIsADirectory, "đường dẫn là thư mục", path);
    return fail_system(error, "không mở được tệp", path);
}

[[nodiscard]] Result<std::size_t> read_once(void* handle, std::uint64_t offset, std::span<std::byte> out) {
    OVERLAPPED overlapped = overlapped_at(offset);
    DWORD got = 0;
    const BOOL done = ReadFile(handle, out.data(), transfer_size(out.size()), &got, &overlapped);
    if (done != 0) return std::size_t{got};
    const DWORD error = GetLastError();
    if (error == ERROR_HANDLE_EOF) return std::size_t{0};
    return fail_system(error, "không đọc được tệp");
}

[[nodiscard]] Result<std::size_t> write_once(void* handle, std::uint64_t offset, std::span<const std::byte> data) {
    OVERLAPPED overlapped = overlapped_at(offset);
    DWORD wrote = 0;
    const BOOL done = WriteFile(handle, data.data(), transfer_size(data.size()), &wrote, &overlapped);
    if (done == 0) return fail_system(GetLastError(), "không ghi được tệp");
    if (wrote == 0) return fail(ErrorCode::kIo, "WriteFile không ghi byte nào");
    return std::size_t{wrote};
}

// Tên tạm cùng thư mục với path, riêng theo tiến trình và lần gọi, để hai lần ghi song song không
// giẫm nhau (No1 dùng cố định path + ".tmp").
[[nodiscard]] std::string temporary_name(std::string_view path) {
    static std::atomic<std::uint64_t> counter = 0;
    const std::uint64_t serial = counter.fetch_add(1);
    return std::format("{}.~f2.{}.{}", path, GetCurrentProcessId(), serial);
}

// Ghi data vào tệp mới rồi đẩy xuống đĩa trước khi đổi tên.
[[nodiscard]] Status write_durable(std::string_view path, std::span<const std::byte> data) {
    auto file = File::open(path, Mode::kWrite);
    if (!file) return std::unexpected(std::move(file).error());
    const auto wrote = file->write(data);
    if (!wrote) return std::unexpected(wrote.error());
    Status synced = file->sync();
    if (!synced) return synced;
    return file->close();
}

// Nguồn rồi đích là thứ tự quen của mọi hàm đổi tên, như MoveFileExW (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] Status replace(std::string_view source, std::string_view target) {
    const std::wstring from = native_path(source);
    const std::wstring into = native_path(target);
    const DWORD flags = MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH;
    if (MoveFileExW(from.c_str(), into.c_str(), flags) != 0) return core::ok();
    const DWORD error = GetLastError();
    DeleteFileW(from.c_str());
    return fail_system(error, "không thay được tệp đích", target);
}

} // namespace

std::wstring native_path(std::string_view path) {
    std::wstring wide = core::widen(path);
    std::ranges::replace(wide, L'/', L'\\');
    if (wide.size() < kShortPath || wide.starts_with(L"\\\\?\\")) return wide;
    return extended(wide);
}

void ViewCloser::operator()(const std::byte* view) const noexcept {
    UnmapViewOfFile(view);
}

Result<MappedFile> MappedFile::open(std::string_view path) {
    const auto file = File::open(path, Mode::kRead);
    if (!file) return std::unexpected(file.error());
    return open(*file);
}

Result<MappedFile> MappedFile::open(const File& file) {
    const bool writable = has(file.mode(), Mode::kWrite);
    if (writable) return fail(ErrorCode::kPermissionDenied, "không map tệp ghi");
    const auto total = file.size();
    if (!total) return std::unexpected(total.error());
    if (*total == 0) return MappedFile(nullptr, 0);
    constexpr std::uint64_t kLimit = std::numeric_limits<std::size_t>::max();
    if (*total > kLimit) return fail(ErrorCode::kOverflow, "tệp lớn hơn không gian địa chỉ");
    void* handle = file.native_handle();
    const UniqueHandle mapping(CreateFileMappingW(handle, nullptr, PAGE_READONLY, 0, 0, nullptr));
    if (!mapping) return fail_system(GetLastError(), "không tạo được ánh xạ tệp");
    // Vùng ánh xạ giữ section sống, nên handle ánh xạ đóng ngay khi ra khỏi hàm.
    const void* view = MapViewOfFile(mapping.get(), FILE_MAP_READ, 0, 0, 0);
    if (view == nullptr) return fail_system(GetLastError(), "không ánh xạ được tệp");
    return MappedFile(static_cast<const std::byte*>(view), *total);
}

void MappedFile::prefetch(std::uint64_t offset, std::size_t size) const noexcept {
    if (offset >= size_ || size == 0) return;
    const std::size_t start = offset;
    const std::span<const std::byte> range = bytes().subspan(start, std::min(size, size_ - start));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): PVOID không mang const; hàm chỉ đọc.
    void* const address = const_cast<std::byte*>(range.data());
    WIN32_MEMORY_RANGE_ENTRY entry{.VirtualAddress = address, .NumberOfBytes = range.size()};
    // Chỉ là gợi ý: thất bại thì trang vẫn nạp theo lỗi trang như thường.
    [[maybe_unused]] const BOOL hinted = PrefetchVirtualMemory(GetCurrentProcess(), 1, &entry, 0);
}

File::File(UniqueHandle handle, Mode mode, std::uint64_t position) noexcept
    : Stream(mode), handle_(std::move(handle)), position_(position) {}

Result<File> File::open(std::string_view path, Mode requested) {
    const Mode mode = normalized(requested);
    const bool usable = has(mode, Mode::kRead) || has(mode, Mode::kWrite);
    if (!usable) return fail(ErrorCode::kInvalidArgument, "chế độ mở thiếu Read và Write");
    const Plan plan = plan_for(mode);
    const BOOL inherit = has(mode, Mode::kInherit) ? TRUE : FALSE;
    SECURITY_ATTRIBUTES security{
        .nLength = sizeof(SECURITY_ATTRIBUTES), .lpSecurityDescriptor = nullptr, .bInheritHandle = inherit};
    const std::wstring wide = native_path(path);
    UniqueHandle handle(CreateFileW(wide.c_str(), plan.access, plan.share, &security, plan.disposition, plan.flags,
        nullptr));
    if (!handle) return open_failure(wide, path);
    // Ghi vết tệp dữ liệu đã mở để đọc (dựng gói APK, iOS): xem core/trace.hpp.
    if (has(mode, Mode::kRead)) core::trace_file(path);
    File file(std::move(handle), mode, 0);
    if (!has(mode, Mode::kAppend)) return file;
    const auto end = file.size();
    if (!end) return std::unexpected(end.error());
    file.position_ = *end;
    return file;
}

void File::flush_quietly() noexcept {
    if (!dirty_ || !handle_) return;
    const std::size_t pending = buffered_;
    const Status flushed = flush_writes();
    if (!flushed) core::error("Mất {} byte chờ ghi khi đóng tệp: {}", pending, flushed.error());
}

File::~File() {
    flush_quietly();
}

File& File::operator=(File&& other) noexcept {
    if (this == &other) return *this;
    flush_quietly();
    handle_ = std::move(other.handle_);
    buffer_ = std::move(other.buffer_);
    mapped_ = std::move(other.mapped_);
    position_ = other.position_;
    buffer_start_ = other.buffer_start_;
    buffered_ = std::exchange(other.buffered_, 0);
    dirty_ = std::exchange(other.dirty_, false);
    // Phần Stream chuyển sau cùng: không member nào của other được đọc sau lần move này.
    Stream::operator=(std::move(other));
    return *this;
}

std::size_t File::take_buffered(std::span<std::byte> out) noexcept {
    const bool inside = !dirty_ && position_ >= buffer_start_ && position_ < buffer_start_ + buffered_;
    if (!inside) return 0;
    const std::size_t skip = position_ - buffer_start_;
    const std::size_t count = std::min(out.size(), buffered_ - skip);
    std::ranges::copy(buffer().subspan(skip, count), out.begin());
    position_ += count;
    return count;
}

// Phần không có trong bộ đệm: từ kBufferSize trở lên đọc thẳng vào out, nhỏ hơn thì nạp lại bộ đệm.
Result<std::size_t> File::read_through(std::span<std::byte> out) {
    const auto advance = [this](std::size_t got) {
        position_ += got;
        return got;
    };
    if (out.size() >= kBufferSize) return read_at(position_, out).transform(advance);
    if (buffer_.empty()) buffer_ = Bytes(kBufferSize);
    const auto got = read_at(position_, buffer());
    if (!got) return got;
    buffer_start_ = position_;
    buffered_ = *got;
    return take_buffered(out);
}

Result<std::size_t> File::read(std::span<std::byte> out) {
    if (!has(mode(), Mode::kRead)) return fail(ErrorCode::kPermissionDenied, "tệp chỉ ghi");
    Status flushed = flush_writes();
    if (!flushed) return std::unexpected(std::move(flushed).error());
    const std::size_t taken = take_buffered(out);
    if (taken == out.size()) return taken;
    const auto more = read_through(out.subspan(taken));
    // Lỗi sau khi đã có byte thì trả phần đã có; lần đọc sau gặp lại lỗi.
    if (!more) return taken != 0 ? Result<std::size_t>(taken) : more;
    return taken + *more;
}

void File::begin_writes() {
    if (buffer_.empty()) buffer_ = Bytes(kBufferSize);
    dirty_ = true;
    buffered_ = 0;
    buffer_start_ = position_;
}

// Gom các lần ghi nhỏ liền nhau vào bộ đệm; khối từ kBufferSize trở lên đi thẳng xuống tệp.
Status File::write_through(std::span<const std::byte> data) {
    // Bộ đệm đang giữ byte đọc trước thì lần ghi này có thể làm chúng cũ.
    if (!dirty_) buffered_ = 0;
    const bool append = has(mode(), Mode::kAppend);
    const bool contiguous = dirty_ && (append || buffer_start_ + buffered_ == position_);
    const bool fits = contiguous && buffered_ + data.size() <= kBufferSize;
    Status flushed = fits ? core::ok() : flush_writes();
    if (!flushed) return flushed;
    if (data.size() >= kBufferSize) return write_at(append ? kEndOfFile : position_, data);
    if (!fits) begin_writes();
    std::ranges::copy(data, buffer().subspan(buffered_).begin());
    buffered_ += data.size();
    return core::ok();
}

Result<std::size_t> File::write(std::span<const std::byte> data) {
    if (!has(mode(), Mode::kWrite)) return fail(ErrorCode::kPermissionDenied, "tệp chỉ đọc");
    if (data.empty()) return std::size_t{0};
    Status written = write_through(data);
    if (!written) return std::unexpected(std::move(written).error());
    position_ += data.size();
    return data.size();
}

Status File::write_at(std::uint64_t offset, std::span<const std::byte> data) {
    std::size_t done = 0;
    // Khác gốc: gốc là while (done < data.size()) có câu if trả lỗi ngay trong thân. Điều kiện dừng
    // ấy lên điều kiện lặp, lỗi trả sau vòng; wrote khởi đầu có giá trị để lượt đầu chỉ phụ thuộc
    // done < data.size() như gốc. Biến at của gốc thành target.
    Result<std::size_t> wrote = std::size_t{0};
    while (wrote && done < data.size()) {
        const std::uint64_t target = offset == kEndOfFile ? offset : offset + done;
        wrote = write_once(handle_.get(), target, data.subspan(done));
        done += wrote.value_or(0);
    }
    if (!wrote) return std::unexpected(std::move(wrote).error());
    return core::ok();
}

// Ghi ép về cuối thì sau khi đẩy, vị trí là cuối tệp thật, kể cả khi tiến trình khác vừa ghi thêm.
Status File::flush_writes() {
    if (!dirty_) return core::ok();
    const bool append = has(mode(), Mode::kAppend);
    const std::span<const std::byte> pending = buffer().first(buffered_);
    Status written = write_at(append ? kEndOfFile : buffer_start_, pending);
    dirty_ = false;
    buffered_ = 0;
    if (!written || !append) return written;
    const auto end = size();
    if (!end) return std::unexpected(end.error());
    position_ = *end;
    return core::ok();
}

Status File::flush() {
    return flush_writes();
}

// Ghi ép về cuối: byte chờ được đẩy trước, như O_APPEND ghi ngay rồi mới seek; không thì lần đọc
// sau đẩy chúng và kéo vị trí về cuối, mất chỗ vừa seek tới.
Status File::seek(Seek base, std::int64_t offset) {
    const bool append = has(mode(), Mode::kAppend);
    if (Status flushed = append ? flush_writes() : core::ok(); !flushed) return flushed;
    const auto end = base == Seek::kEnd ? size() : Result<std::uint64_t>(0);
    if (!end) return std::unexpected(end.error());
    const auto target = seek_target(base, offset, position_, *end);
    if (!target) return std::unexpected(target.error());
    position_ = *target;
    return core::ok();
}

Result<std::uint64_t> File::size() const {
    LARGE_INTEGER value{};
    const BOOL known = GetFileSizeEx(handle_.get(), &value);
    if (known == 0) return fail_system(GetLastError(), "không hỏi được cỡ tệp");
    const auto disk = static_cast<std::uint64_t>(value.QuadPart);
    if (!dirty_) return disk;
    const bool append = has(mode(), Mode::kAppend);
    const std::uint64_t pending = append ? disk + buffered_ : buffer_start_ + buffered_;
    return std::max(disk, pending);
}

Result<std::span<const std::byte>> File::map() {
    if (mapped_) return mapped_->bytes();
    auto mapped = MappedFile::open(*this);
    if (!mapped) return std::unexpected(std::move(mapped).error());
    mapped_ = std::move(*mapped);
    return mapped_->bytes();
}

Result<std::size_t> File::read_at(std::uint64_t offset, std::span<std::byte> out) const {
    std::size_t done = 0;
    // Khác gốc: gốc là while (done < out.size()) có hai câu if trong thân (lỗi thì trả ngay, đọc
    // được 0 byte thì break). Hai điều kiện dừng ấy lên điều kiện lặp; got khởi đầu khác 0 để lượt
    // đầu chỉ phụ thuộc done < out.size() như gốc.
    Result<std::size_t> got = std::size_t{1};
    while (got && *got != 0 && done < out.size()) {
        got = read_once(handle_.get(), offset + done, out.subspan(done));
        done += got.value_or(0);
    }
    if (!got) return got;
    return done;
}

Status File::sync() {
    Status flushed = flush_writes();
    if (!flushed) return flushed;
    if (FlushFileBuffers(handle_.get()) != 0) return core::ok();
    return fail_system(GetLastError(), "không đẩy được tệp xuống đĩa");
}

// FileEndOfFileInfo đặt cỡ theo handle, không theo con trỏ hệ điều hành: tệp này đọc
// ghi bằng OVERLAPPED nên con trỏ ấy không có nghĩa.
Status File::truncate(std::uint64_t size) {
    if (!has(mode(), Mode::kWrite)) return fail(ErrorCode::kPermissionDenied, "tệp chỉ đọc");
    constexpr std::uint64_t kLargest = std::numeric_limits<LONGLONG>::max();
    if (size > kLargest) return fail(ErrorCode::kOverflow, "cỡ tệp vượt giới hạn của hệ điều hành");
    Status flushed = flush_writes();
    if (!flushed) return flushed;
    FILE_END_OF_FILE_INFO info{};
    info.EndOfFile.QuadPart = static_cast<LONGLONG>(size);
    if (SetFileInformationByHandle(handle_.get(), FileEndOfFileInfo, &info, sizeof(info)) == 0) {
        return fail_system(GetLastError(), "không đặt được cỡ tệp");
    }
    position_ = std::min(position_, size);
    buffered_ = 0;
    return core::ok();
}

Status File::close() {
    Status flushed = flush_writes();
    mapped_.reset();
    void* raw = handle_.release();
    const bool closed = raw == nullptr || CloseHandle(raw) != 0;
    const DWORD error = closed ? 0 : GetLastError();
    if (!flushed) return flushed;
    if (!closed) return fail_system(error, "không đóng được tệp");
    return core::ok();
}

Result<Bytes> read_file(std::string_view path) {
    const auto file = File::open(path, Mode::kRead);
    if (!file) return std::unexpected(file.error());
    const auto total = file->size();
    if (!total) return std::unexpected(total.error());
    constexpr std::uint64_t kLimit = std::numeric_limits<std::size_t>::max();
    if (*total > kLimit) return fail(ErrorCode::kOverflow, "tệp lớn hơn bộ nhớ", path);
    Bytes bytes(*total);
    const auto got = file->read_at(0, bytes.span());
    if (!got) return std::unexpected(got.error());
    // Tệp co lại giữa lúc hỏi cỡ và lúc đọc thì giữ phần thật sự đọc được.
    bytes.shrink(*got);
    return bytes;
}

Status write_file(std::string_view path, std::span<const std::byte> data) {
    auto file = File::open(path, Mode::kWrite);
    if (!file) return std::unexpected(std::move(file).error());
    const auto wrote = file->write(data);
    if (!wrote) return std::unexpected(wrote.error());
    return file->close();
}

Status write_file_atomic(std::string_view path, std::span<const std::byte> data) {
    const std::string temporary = temporary_name(path);
    Status written = write_durable(temporary, data);
    if (written) return replace(temporary, path);
    DeleteFileW(native_path(temporary).c_str());
    return written;
}

} // namespace game::fs
