/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/error.cpp
 *  PHÂN HỆ   : Core / Error
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/error.hpp.
 *  - Chi tiết dài hơn chỗ nội tuyến lên heap qua make_unique_for_overwrite; hết
 *    bộ nhớ thì giữ phần đuôi vừa chỗ nội tuyến và đánh dấu đã cắt, vì Error
 *    phải tạo được cả khi nguyên nhân chính là hết bộ nhớ. Cắt luôn lùi tới đầu
 *    một ký tự UTF-8.
 *  - Nguồn: Forge2 src/core/error.cpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k; macro của windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header
 *    con của Win32 include trực tiếp; biến một chữ c đổi thành unit.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/error.hpp"

#include "core/text.hpp"
#if defined(_WIN32)
#include "core/win32.hpp" // IWYU pragma: keep

#include <libloaderapi.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>
#else
#include <cerrno>
#include <system_error>
#endif

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <memory>
#include <new>
#include <span>
#include <string>
#include <string_view>

namespace game::core {

namespace {

struct Mapping {
    std::uint32_t system = 0;
    ErrorCode code = ErrorCode::kUnknown;
};

#if defined(_WIN32)
constexpr auto kMappings = std::to_array<Mapping>({
    {.system = ERROR_FILE_NOT_FOUND, .code = ErrorCode::kNotFound},
    {.system = ERROR_PATH_NOT_FOUND, .code = ErrorCode::kNotFound},
    {.system = ERROR_INVALID_DRIVE, .code = ErrorCode::kNotFound},
    {.system = ERROR_BAD_NETPATH, .code = ErrorCode::kNotFound},
    {.system = ERROR_MOD_NOT_FOUND, .code = ErrorCode::kNotFound},
    {.system = ERROR_ACCESS_DENIED, .code = ErrorCode::kPermissionDenied},
    {.system = ERROR_PRIVILEGE_NOT_HELD, .code = ErrorCode::kPermissionDenied},
    {.system = ERROR_ALREADY_EXISTS, .code = ErrorCode::kAlreadyExists},
    {.system = ERROR_FILE_EXISTS, .code = ErrorCode::kAlreadyExists},
    {.system = ERROR_DIRECTORY, .code = ErrorCode::kNotADirectory},
    {.system = ERROR_DIRECTORY_NOT_SUPPORTED, .code = ErrorCode::kIsADirectory},
    {.system = ERROR_DISK_FULL, .code = ErrorCode::kNoSpace},
    {.system = ERROR_HANDLE_DISK_FULL, .code = ErrorCode::kNoSpace},
    {.system = ERROR_WRITE_PROTECT, .code = ErrorCode::kReadOnly},
    {.system = ERROR_SHARING_VIOLATION, .code = ErrorCode::kBusy},
    {.system = ERROR_LOCK_VIOLATION, .code = ErrorCode::kBusy},
    {.system = ERROR_BUSY, .code = ErrorCode::kBusy},
    {.system = ERROR_NOT_ENOUGH_MEMORY, .code = ErrorCode::kOutOfMemory},
    {.system = ERROR_OUTOFMEMORY, .code = ErrorCode::kOutOfMemory},
    {.system = ERROR_INVALID_PARAMETER, .code = ErrorCode::kInvalidArgument},
    {.system = ERROR_INVALID_NAME, .code = ErrorCode::kInvalidArgument},
    {.system = ERROR_FILENAME_EXCED_RANGE, .code = ErrorCode::kInvalidArgument},
    {.system = ERROR_NEGATIVE_SEEK, .code = ErrorCode::kOutOfRange},
    {.system = ERROR_HANDLE_EOF, .code = ErrorCode::kOutOfRange},
    {.system = ERROR_NOT_SUPPORTED, .code = ErrorCode::kUnsupported},
    {.system = ERROR_CALL_NOT_IMPLEMENTED, .code = ErrorCode::kUnsupported},
    {.system = ERROR_TIMEOUT, .code = ErrorCode::kTimeout},
    {.system = WAIT_TIMEOUT, .code = ErrorCode::kTimeout},
    {.system = ERROR_OPERATION_ABORTED, .code = ErrorCode::kCancelled},
    {.system = ERROR_CANCELLED, .code = ErrorCode::kCancelled},
    {.system = ERROR_IO_PENDING, .code = ErrorCode::kWouldBlock},
    {.system = ERROR_CRC, .code = ErrorCode::kCorrupt},
    {.system = ERROR_FILE_CORRUPT, .code = ErrorCode::kCorrupt},
    {.system = ERROR_ARITHMETIC_OVERFLOW, .code = ErrorCode::kOverflow},
    {.system = ERROR_TOO_MANY_OPEN_FILES, .code = ErrorCode::kExhausted},
    {.system = ERROR_NO_MORE_FILES, .code = ErrorCode::kExhausted},
    {.system = ERROR_READ_FAULT, .code = ErrorCode::kIo},
    {.system = ERROR_WRITE_FAULT, .code = ErrorCode::kIo},
    {.system = ERROR_GEN_FAILURE, .code = ErrorCode::kIo},
});

// Thông điệp của FormatMessageW cho một nguồn; nullptr là bảng của hệ thống.
[[nodiscard]] std::wstring format_message(std::uint32_t system, HMODULE source) {
    PWSTR text = nullptr;
    const DWORD from = source == nullptr ? FORMAT_MESSAGE_FROM_SYSTEM : FORMAT_MESSAGE_FROM_HMODULE;
    const DWORD flags = from | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS;
    // ALLOCATE_BUFFER nhận địa chỉ con trỏ qua tham số LPWSTR.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng của FormatMessageW.
    auto* target = reinterpret_cast<LPWSTR>(&text);
    const DWORD length = FormatMessageW(flags, source, system, 0, target, 0, nullptr);
    const std::unique_ptr<wchar_t, decltype(&LocalFree)> owned(text, &LocalFree);
    if (length == 0 || text == nullptr) return {};
    std::wstring_view message(text, length);
    while (!message.empty() && (message.back() == L'\n' || message.back() == L'\r')) {
        message.remove_suffix(1);
    }
    return std::wstring(message);
}

#else

constexpr auto kMappings = std::to_array<Mapping>({
    {.system = ENOENT, .code = ErrorCode::kNotFound},
    {.system = EACCES, .code = ErrorCode::kPermissionDenied},
    {.system = EPERM, .code = ErrorCode::kPermissionDenied},
    {.system = EEXIST, .code = ErrorCode::kAlreadyExists},
    {.system = ENOTDIR, .code = ErrorCode::kNotADirectory},
    {.system = EISDIR, .code = ErrorCode::kIsADirectory},
    {.system = ENOSPC, .code = ErrorCode::kNoSpace},
    {.system = EROFS, .code = ErrorCode::kReadOnly},
    {.system = EBUSY, .code = ErrorCode::kBusy},
    {.system = ENOMEM, .code = ErrorCode::kOutOfMemory},
    {.system = EINVAL, .code = ErrorCode::kInvalidArgument},
    {.system = ENOSYS, .code = ErrorCode::kUnsupported},
    {.system = EOPNOTSUPP, .code = ErrorCode::kUnsupported},
    {.system = ETIMEDOUT, .code = ErrorCode::kTimeout},
    {.system = ECANCELED, .code = ErrorCode::kCancelled},
    {.system = EAGAIN, .code = ErrorCode::kWouldBlock},
    {.system = EIO, .code = ErrorCode::kIo},
    {.system = EMFILE, .code = ErrorCode::kExhausted},
    {.system = ENFILE, .code = ErrorCode::kExhausted},
    {.system = EOVERFLOW, .code = ErrorCode::kOverflow},
});

static_assert(EWOULDBLOCK == EAGAIN, "EWOULDBLOCK và EAGAIN phải cùng một mã");

#endif

// Đích của lượt định dạng đầu: đếm mọi byte, chỉ ghi phần vừa chỗ nội tuyến, nhớ chỗ bắt đầu ký tự
// UTF-8 cuối cùng không vượt giới hạn để cắt phần đầu mà không chẻ ký tự.
struct Spill {
    std::span<char> out;
    std::size_t total = 0;
    std::size_t boundary = 0;
};

class SpillWriter {
public:
    // Tên do khái niệm std::output_iterator của thư viện chuẩn quy định (lệch DD-02).
    // NOLINTNEXTLINE(readability-identifier-naming)
    using difference_type = std::ptrdiff_t;

    explicit SpillWriter(Spill& spill) noexcept : spill_(&spill) {}

    SpillWriter& operator=(char unit) noexcept {
        Spill& spill = *spill_;
        const bool fits = spill.total < spill.out.size();
        if (fits) spill.out.subspan(spill.total).front() = unit;
        const bool starts = spill.total <= spill.out.size() && !is_utf8_continuation(unit);
        if (starts) spill.boundary = spill.total;
        ++spill.total;
        return *this;
    }
    SpillWriter& operator*() noexcept { return *this; }
    SpillWriter& operator++() noexcept { return *this; }
    SpillWriter operator++(int) noexcept { return *this; }

private:
    Spill* spill_;
};

void write_path(std::format_context::iterator& out, std::string_view path) {
    for (const char unit : path) {
        *out++ = unit == '\\' ? '/' : unit;
    }
}

} // namespace

std::string_view name(ErrorCode code) noexcept {
    switch (code) {
    case ErrorCode::kUnknown: return "Unknown";
    case ErrorCode::kInvalidArgument: return "InvalidArgument";
    case ErrorCode::kOutOfRange: return "OutOfRange";
    case ErrorCode::kOutOfMemory: return "OutOfMemory";
    case ErrorCode::kNotFound: return "NotFound";
    case ErrorCode::kAlreadyExists: return "AlreadyExists";
    case ErrorCode::kPermissionDenied: return "PermissionDenied";
    case ErrorCode::kInvalidState: return "InvalidState";
    case ErrorCode::kNotADirectory: return "NotADirectory";
    case ErrorCode::kIsADirectory: return "IsADirectory";
    case ErrorCode::kNoSpace: return "NoSpace";
    case ErrorCode::kReadOnly: return "ReadOnly";
    case ErrorCode::kBusy: return "Busy";
    case ErrorCode::kUnsupported: return "Unsupported";
    case ErrorCode::kIo: return "Io";
    case ErrorCode::kCorrupt: return "Corrupt";
    case ErrorCode::kOverflow: return "Overflow";
    case ErrorCode::kExhausted: return "Exhausted";
    case ErrorCode::kTimeout: return "Timeout";
    case ErrorCode::kWouldBlock: return "WouldBlock";
    case ErrorCode::kCancelled: return "Cancelled";
    case ErrorCode::kDeviceLost: return "DeviceLost";
    case ErrorCode::kInternal: return "Internal";
    }
    return "?";
}

ErrorCode from_system(std::uint32_t system) noexcept {
    const auto found = std::ranges::find(kMappings, system, &Mapping::system);
    return found == kMappings.end() ? ErrorCode::kUnknown : found->code;
}

// Win32: FormatMessage. POSIX: system_category.
std::string system_message(std::uint32_t system) {
#if defined(_WIN32)
    std::wstring text = format_message(system, nullptr);
    if (text.empty()) text = format_message(system, GetModuleHandleW(L"ntdll.dll"));
    return narrow(text);
#else
    if (system == 0) return {};
    return std::system_category().message(static_cast<int>(system));
#endif
}

Error::Error(ErrorCode code, Message message, std::string_view detail, std::uint32_t system) noexcept
    : message_(message.text()), file_(message.file()), line_(message.line()), system_(system), code_(code) {
    assign(detail);
}

Error::Error(const Error& other) noexcept
    : message_(other.message_), file_(other.file_), line_(other.line_), system_(other.system_), code_(other.code_) {
    assign(other.detail());
    truncated_ = truncated_ || other.truncated_;
}

Error& Error::operator=(const Error& other) noexcept {
    if (this == &other) return *this;
    message_ = other.message_;
    file_ = other.file_;
    line_ = other.line_;
    system_ = other.system_;
    code_ = other.code_;
    assign(other.detail());
    truncated_ = truncated_ || other.truncated_;
    return *this;
}

// Lượt đầu ghi thẳng vào chỗ nội tuyến và đếm độ dài thật; dài hơn thì định dạng lại một lần lên
// heap. Formatter của đối số ném thì chi tiết là kFormatFailure. Hết bộ nhớ ở lượt hai thì giữ phần
// đầu đã có (lượt đầu không có phần đuôi như assign) và đánh dấu đã cắt.
void Error::format_erased(std::string_view format, std::format_args args) noexcept {
    heap_.reset();
    truncated_ = false;
    Spill spill{.out = storage_};
    try {
        std::vformat_to(SpillWriter(spill), format, args);
    } catch (...) {
        assign(kFormatFailure);
        return;
    }
    const bool fits = spill.total <= kInlineCapacity;
    size_ = static_cast<std::uint16_t>(fits ? spill.total : spill.boundary);
    if (fits) return;
    try {
        assign(std::vformat(format, args));
    } catch (...) {
        truncated_ = true;
    }
}

void Error::assign(std::string_view text) noexcept {
    heap_.reset();
    const std::string_view kept = utf8_suffix(text, kMaxDetail);
    truncated_ = kept.size() < text.size();
    size_ = static_cast<std::uint16_t>(kept.size());
    if (kept.size() <= kInlineCapacity) {
        std::ranges::copy(kept, storage_.begin());
        return;
    }
    try {
        // NOLINTNEXTLINE(*-avoid-c-arrays): mảng động không khởi tạo, cùng kiểu với heap_.
        heap_ = std::make_unique_for_overwrite<char[]>(kept.size());
        std::ranges::copy(kept, heap_.get());
    } catch (const std::bad_alloc&) {
        const std::string_view tail = utf8_suffix(kept, kInlineCapacity);
        std::ranges::copy(tail, storage_.begin());
        size_ = static_cast<std::uint16_t>(tail.size());
        truncated_ = true;
    }
}

} // namespace game::core

std::format_context::iterator std::formatter<game::core::Error>::format(const game::core::Error& error,
    std::format_context& context) {
    auto out = context.out();
    game::core::write_path(out, error.file());
    out = std::format_to(out, ":{}: {}: {}", error.line(), error.code(), error.message());
    if (!error.detail().empty()) out = std::format_to(out, " ({})", error.detail());
    if (error.system() == 0) return out;
    const std::string text = game::core::system_message(error.system());
    return std::format_to(out, " [hệ thống {:#x}: {}]", error.system(), text);
}
