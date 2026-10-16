/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/secure/private_file.cpp
 *  PHÂN HỆ   : Shared / Secure / Private File
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tạo và xét tệp bí mật: chỉ SYSTEM, Administrators và chủ được đụng nội
 *    dung.
 *  - Đọc đúng số byte trên handle vừa xét quyền. Symlink và mount point bị từ
 *    chối.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "secure/private_file.hpp"

#include <cstddef>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>

#ifdef _WIN32
#include "core/win32.hpp" // IWYU pragma: keep

// Các header con và aclapi.h, sddl.h cần kiểu của windows.h nên đứng sau, khối riêng để
// clang-format không xếp lại.
#include <accctrl.h>
#include <aclapi.h>
#include <cstring>
#include <errhandlingapi.h>
#include <fileapi.h>
#include <handleapi.h>
#include <limits>
#include <minwinbase.h>
#include <optional>
#include <processthreadsapi.h>
#include <sddl.h>
#include <securitybaseapi.h>
#include <vector>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>
#else
#include <cerrno>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#endif

namespace game::secure {
namespace {

#ifdef _WIN32

struct LocalBlock {
    void* data = nullptr;
    LocalBlock() = default;
    LocalBlock(const LocalBlock&) = delete;
    LocalBlock& operator=(const LocalBlock&) = delete;
    LocalBlock(LocalBlock&&) = delete;
    LocalBlock& operator=(LocalBlock&&) = delete;
    ~LocalBlock() {
        if (data != nullptr) LocalFree(data);
    }
};

struct Handle {
    HANDLE value = INVALID_HANDLE_VALUE;
    Handle() = default;
    explicit Handle(HANDLE handle) : value(handle) {}
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
    Handle(Handle&& other) noexcept : value(other.value) { other.value = INVALID_HANDLE_VALUE; }
    Handle& operator=(Handle&& other) noexcept {
        if (this == &other) return *this;
        reset();
        value = other.value;
        other.value = INVALID_HANDLE_VALUE;
        return *this;
    }
    ~Handle() { reset(); }
    void reset() noexcept {
        if (value != INVALID_HANDLE_VALUE && value != nullptr) CloseHandle(value);
        value = INVALID_HANDLE_VALUE;
    }
};

enum class ReparseKind : std::uint8_t { kNone, kLink, kOther, kUnknown };

enum class AclVerdict : std::uint8_t { kOk, kExposed, kIo };

// SID của người dùng đang chạy tiến trình, dạng chuỗi "S-1-5-21-...".
[[nodiscard]] std::optional<std::wstring> process_user_sid() {
    HANDLE raw = nullptr;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &raw) == 0) return std::nullopt;
    const Handle token{raw};
    DWORD need = 0;
    static_cast<void>(GetTokenInformation(token.value, TokenUser, nullptr, 0, &need));
    if (need < sizeof(TOKEN_USER)) return std::nullopt;
    std::vector<std::byte> buffer(need);
    const BOOL got = GetTokenInformation(token.value, TokenUser, buffer.data(), need, &need);
    if (got == 0) return std::nullopt;
    if (buffer.size() < sizeof(TOKEN_USER)) return std::nullopt;
    // Sao phần đầu ra một TOKEN_USER có căn lề đúng (bộ đệm byte không bảo đảm căn lề); Sid vẫn trỏ
    // vào `buffer`.
    TOKEN_USER user{};
    std::memcpy(&user, buffer.data(), sizeof(user));
    LocalBlock text;
    LPWSTR sid_text = nullptr;
    if (ConvertSidToStringSidW(user.User.Sid, &sid_text) == 0) return std::nullopt;
    text.data = sid_text;
    return std::wstring{sid_text};
}

[[nodiscard]] bool trusted_sid(PSID sid, PSID self) noexcept {
    if (sid == nullptr) return false;
    if (self != nullptr && EqualSid(sid, self) != 0) return true;
    const bool system = IsWellKnownSid(sid, WinLocalSystemSid) != 0;
    const bool admin = IsWellKnownSid(sid, WinBuiltinAdministratorsSid) != 0;
    return system || admin;
}

// SYNCHRONIZE và READ_CONTROL không đọc hay sửa byte. Mọi bit khác là đụng nội dung hoặc chiếm
// quyền.
[[nodiscard]] bool touches_file(ACCESS_MASK mask) noexcept {
    constexpr ACCESS_MASK kLookup = SYNCHRONIZE | READ_CONTROL;
    return (mask & ~kLookup) != 0;
}

// SID phải nằm trọn trong ACE trước IsValidSid: count do attacker khai có thể lớn hơn ACE.
[[nodiscard]] bool sid_fits(const ACE_HEADER& header, const ACCESS_ALLOWED_ACE& allowed) noexcept {
    constexpr std::size_t kPrefix = 8;
    const std::size_t ace = header.AceSize;
    const std::size_t at = offsetof(ACCESS_ALLOWED_ACE, SidStart);
    if (ace < at + kPrefix) return false;
    unsigned char prefix[kPrefix]{};
    std::memcpy(prefix, &allowed.SidStart, kPrefix);
    const unsigned count = prefix[1];
    if (count > 15U) return false;
    const std::size_t need = at + kPrefix + (std::size_t{count} * 4U);
    return ace >= need;
}

[[nodiscard]] AclVerdict strange_ace(std::string_view name, std::string& error) {
    error = std::string{name} +
        " có quyền lạ (không phải cho/cấm thường); xoá tệp, xoay khoá rồi chạy lại";
    return AclVerdict::kExposed;
}

[[nodiscard]] AclVerdict foreign_ace(std::string_view name, std::string& error) {
    error = std::string{name} +
        " cho tài khoản khác đụng (đọc, sửa hoặc xoá); xoá tệp, xoay khoá rồi chạy lại";
    return AclVerdict::kExposed;
}

[[nodiscard]] AclVerdict one_ace(PACL dacl, DWORD index, PSID self, std::string_view name,
    std::string& error) {
    void* raw = nullptr;
    if (GetAce(dacl, index, &raw) == 0 || raw == nullptr) {
        error = "không đọc được quyền của " + std::string{name};
        return AclVerdict::kIo;
    }
    const auto* header = static_cast<const ACE_HEADER*>(raw);
    if ((header->AceFlags & INHERIT_ONLY_ACE) != 0) return AclVerdict::kOk;
    if (header->AceType == ACCESS_DENIED_ACE_TYPE) return AclVerdict::kOk;
    if (header->AceType != ACCESS_ALLOWED_ACE_TYPE) return strange_ace(name, error);
    if (header->AceSize < sizeof(ACCESS_ALLOWED_ACE)) return strange_ace(name, error);
    auto* allowed = static_cast<ACCESS_ALLOWED_ACE*>(raw);
    if (!sid_fits(*header, *allowed)) return strange_ace(name, error);
    PSID sid = &allowed->SidStart;
    if (IsValidSid(sid) == 0) return strange_ace(name, error);
    if (touches_file(allowed->Mask) && !trusted_sid(sid, self)) return foreign_ace(name, error);
    return AclVerdict::kOk;
}

[[nodiscard]] AclVerdict scan_aces(PACL dacl, PSID self, std::string_view name,
    std::string& error) {
    ACL_SIZE_INFORMATION size{};
    if (GetAclInformation(dacl, &size, sizeof(size), AclSizeInformation) == 0) {
        error = "không đọc được quyền của " + std::string{name};
        return AclVerdict::kIo;
    }
    for (DWORD index = 0; index < size.AceCount; ++index) {
        const AclVerdict one = one_ace(dacl, index, self, name, error);
        if (one != AclVerdict::kOk) return one;
    }
    return AclVerdict::kOk;
}

// Không đọc được DACL thì không chứng minh được tệp riêng: coi như lộ, cùng hướng file_private trả
// false.
[[nodiscard]] AclVerdict judge_acl(HANDLE file, std::string_view label, std::string& error) {
    const std::string name{label};
    PACL dacl = nullptr;
    PSID owner = nullptr;
    LocalBlock descriptor;
    PSECURITY_DESCRIPTOR sd = nullptr;
    const DWORD status = GetSecurityInfo(file, SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, &owner, nullptr, &dacl, nullptr,
        &sd);
    if (status != ERROR_SUCCESS) {
        error = "không đọc được quyền của " + name;
        return AclVerdict::kExposed;
    }
    descriptor.data = sd;
    if (dacl == nullptr) {
        error = name + " không có DACL: mọi người đọc được; xoá tệp, xoay khoá rồi chạy lại";
        return AclVerdict::kExposed;
    }
    const std::optional<std::wstring> self_text = process_user_sid();
    LocalBlock self_block;
    PSID self = nullptr;
    if (self_text && ConvertStringSidToSidW(self_text->c_str(), &self) != 0) self_block.data = self;
    if (!trusted_sid(owner, self)) {
        error = name + " thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return AclVerdict::kExposed;
    }
    return scan_aces(dacl, self, name, error);
}

[[nodiscard]] ReparseKind reparse_kind(HANDLE file) noexcept {
    FILE_ATTRIBUTE_TAG_INFO tag{};
    const BOOL ok = GetFileInformationByHandleEx(file, FileAttributeTagInfo, &tag, sizeof(tag));
    if (ok == 0) return ReparseKind::kUnknown;
    if ((tag.FileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0) return ReparseKind::kNone;
    const bool link =
        tag.ReparseTag == IO_REPARSE_TAG_SYMLINK || tag.ReparseTag == IO_REPARSE_TAG_MOUNT_POINT;
    if (link) return ReparseKind::kLink;
    return ReparseKind::kOther;
}

[[nodiscard]] HANDLE open_existing(const std::filesystem::path& path, DWORD access,
    bool reparse) noexcept {
    const DWORD flags =
        reparse ? FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OPEN_REPARSE_POINT : FILE_ATTRIBUTE_NORMAL;
    return CreateFileW(path.c_str(), access, FILE_SHARE_READ, nullptr, OPEN_EXISTING, flags,
        nullptr);
}

[[nodiscard]] PrivateRead open_failed(DWORD code, const std::filesystem::path& path,
    std::string_view label, std::string& error) {
    const std::string name{label};
    if (code == ERROR_FILE_NOT_FOUND || code == ERROR_PATH_NOT_FOUND) {
        error = "không đọc được quyền của " + name;
        return PrivateRead::kMissing;
    }
    const DWORD attributes = GetFileAttributesW(path.c_str());
    const bool known = attributes != INVALID_FILE_ATTRIBUTES;
    const bool is_dir = known && (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    if (is_dir) {
        error = name + " không phải tệp thường";
        return PrivateRead::kNotFile;
    }
    if (code == ERROR_ACCESS_DENIED) {
        error = name + " không mở được để xét quyền; xoá tệp, xoay khoá rồi chạy lại";
        return PrivateRead::kExposed;
    }
    error = "không đọc được quyền của " + name;
    return PrivateRead::kIo;
}

// Symlink và mount point bị từ chối. Reparse khác (placeholder đám mây) mở lại để tới nội dung.
[[nodiscard]] PrivateRead settle(Handle& file, const std::filesystem::path& path, DWORD access,
    std::string_view label, std::string& error) {
    if (file.value == INVALID_HANDLE_VALUE) return open_failed(GetLastError(), path, label, error);
    const ReparseKind kind = reparse_kind(file.value);
    if (kind == ReparseKind::kNone) return PrivateRead::kOk;
    if (kind == ReparseKind::kLink) {
        error = std::string{label} + " là symlink; xoá tệp, xoay khoá rồi chạy lại";
        return PrivateRead::kExposed;
    }
    if (kind != ReparseKind::kOther) {
        error = "không đọc được quyền của " + std::string{label};
        return PrivateRead::kIo;
    }
    file.reset();
    file = Handle{open_existing(path, access, false)};
    if (file.value == INVALID_HANDLE_VALUE) return open_failed(GetLastError(), path, label, error);
    return PrivateRead::kOk;
}

[[nodiscard]] PrivateRead judge_open_file(HANDLE file, std::string_view label, std::string& error) {
    const std::string name{label};
    if (GetFileType(file) != FILE_TYPE_DISK) {
        error = name + " không phải tệp thường";
        return PrivateRead::kNotFile;
    }
    BY_HANDLE_FILE_INFORMATION info{};
    if (GetFileInformationByHandle(file, &info) == 0) {
        error = "không đọc được quyền của " + name;
        return PrivateRead::kIo;
    }
    if ((info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        error = name + " không phải tệp thường";
        return PrivateRead::kNotFile;
    }
    const AclVerdict verdict = judge_acl(file, label, error);
    if (verdict == AclVerdict::kOk) return PrivateRead::kOk;
    return PrivateRead::kExposed;
}

[[nodiscard]] bool read_some(HANDLE file, std::span<std::byte> out, std::size_t& done) noexcept {
    const std::size_t rest = out.size() - done;
    DWORD ask = static_cast<DWORD>(rest);
    if (rest > std::numeric_limits<DWORD>::max()) ask = std::numeric_limits<DWORD>::max();
    DWORD got = 0;
    if (ReadFile(file, out.data() + done, ask, &got, nullptr) == 0) return false;
    if (got == 0) return false;
    done += got;
    return true;
}

[[nodiscard]] bool read_full(HANDLE file, std::span<std::byte> out) noexcept {
    std::size_t done = 0;
    while (done < out.size()) {
        if (!read_some(file, out, done)) return false;
    }
    return true;
}

[[nodiscard]] PrivateRead read_exact(HANDLE file, std::span<std::byte> out, std::string_view label,
    std::string& error) {
    LARGE_INTEGER size{};
    if (GetFileSizeEx(file, &size) == 0) {
        error = "không đọc được " + std::string{label};
        return PrivateRead::kIo;
    }
    const bool negative = size.QuadPart < 0;
    const auto bytes = static_cast<std::uint64_t>(size.QuadPart);
    if (negative || bytes != out.size()) {
        error = std::string{label} + " sai cỡ";
        return PrivateRead::kWrongSize;
    }
    if (!read_full(file, out)) {
        error = "không đọc được " + std::string{label};
        return PrivateRead::kIo;
    }
    return PrivateRead::kOk;
}

struct Created {
    bool ok = false;
    bool existed = false;
    bool opened = false;
};

[[nodiscard]] BOOL convert_sddl(LPCWSTR text, PSECURITY_DESCRIPTOR* out) {
    const DWORD revision = SDDL_REVISION_1;
    return ConvertStringSecurityDescriptorToSecurityDescriptorW(text, revision, out, nullptr);
}

[[nodiscard]] Created write_new(const std::filesystem::path& path, std::span<const std::byte> bytes,
    SECURITY_ATTRIBUTES* attributes) {
    const Handle file{CreateFileW(path.c_str(), GENERIC_WRITE, 0, attributes, CREATE_NEW,
        FILE_ATTRIBUTE_NORMAL, nullptr)};
    if (file.value == INVALID_HANDLE_VALUE) {
        const bool existed = GetLastError() == ERROR_FILE_EXISTS;
        return Created{.ok = false, .existed = existed, .opened = false};
    }
    DWORD wrote = 0;
    const DWORD ask = static_cast<DWORD>(bytes.size());
    const BOOL ok = WriteFile(file.value, bytes.data(), ask, &wrote, nullptr);
    const bool flushed = ok != 0 && wrote == bytes.size() && FlushFileBuffers(file.value) != 0;
    return Created{.ok = flushed, .existed = false, .opened = true};
}

#else

void fill_open_error(int code, std::string_view label, std::string& error) {
    const std::string name{label};
    if (code == ELOOP) {
        error = name + " là symlink; xoá tệp, xoay khoá rồi chạy lại";
        return;
    }
    error = "không đọc được quyền của " + name;
}

[[nodiscard]] PrivateRead posix_open_kind(int code, std::string_view label, std::string& error) {
    fill_open_error(code, label, error);
    if (code == ENOENT) return PrivateRead::kMissing;
    if (code == ELOOP) return PrivateRead::kExposed;
    return PrivateRead::kIo;
}

[[nodiscard]] int open_no_follow(const std::filesystem::path& path) noexcept {
    return ::open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
}

[[nodiscard]] PrivateRead posix_stat(int fd, std::string_view label, std::string& error,
    struct stat& info) {
    const std::string name{label};
    if (::fstat(fd, &info) != 0) {
        error = "không đọc được quyền của " + name;
        return PrivateRead::kIo;
    }
    if (!S_ISREG(info.st_mode)) {
        error = name + " không phải tệp thường";
        return PrivateRead::kNotFile;
    }
    if (info.st_uid != ::geteuid()) {
        error = name + " thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return PrivateRead::kExposed;
    }
    if ((info.st_mode & 077) != 0) {
        error = name + " cho nhóm hoặc người khác đụng; xoá tệp, xoay khoá rồi chạy lại";
        return PrivateRead::kExposed;
    }
    return PrivateRead::kOk;
}

[[nodiscard]] bool read_some(int fd, std::span<std::byte> out, std::size_t& done) noexcept {
    const ssize_t got = ::read(fd, out.data() + done, out.size() - done);
    if (got < 0 && errno == EINTR) return true;
    if (got <= 0) return false;
    done += static_cast<std::size_t>(got);
    return true;
}

[[nodiscard]] bool read_full(int fd, std::span<std::byte> out) noexcept {
    std::size_t done = 0;
    while (done < out.size()) {
        if (!read_some(fd, out, done)) return false;
    }
    return true;
}

[[nodiscard]] PrivateRead read_fd(int fd, const struct stat& info, std::span<std::byte> out,
    std::string_view label, std::string& error) {
    if (info.st_size < 0 || static_cast<std::uint64_t>(info.st_size) != out.size()) {
        error = std::string{label} + " sai cỡ";
        return PrivateRead::kWrongSize;
    }
    if (!read_full(fd, out)) {
        error = "không đọc được " + std::string{label};
        return PrivateRead::kIo;
    }
    return PrivateRead::kOk;
}

#endif

} // namespace

#ifdef _WIN32

bool file_private(const std::filesystem::path& path, std::string_view label, std::string& error) {
    constexpr DWORD kAccess = READ_CONTROL | FILE_READ_ATTRIBUTES;
    Handle file{open_existing(path, kAccess, true)};
    const PrivateRead settled = settle(file, path, kAccess, label, error);
    if (settled != PrivateRead::kOk) return false;
    return judge_open_file(file.value, label, error) == PrivateRead::kOk;
}

PrivateRead read_private_exact(const std::filesystem::path& path, std::span<std::byte> out,
    std::string_view label, std::string& error) {
    constexpr DWORD kAccess = READ_CONTROL | FILE_READ_DATA | FILE_READ_ATTRIBUTES;
    Handle file{open_existing(path, kAccess, true)};
    const PrivateRead settled = settle(file, path, kAccess, label, error);
    if (settled != PrivateRead::kOk) return settled;
    const PrivateRead judged = judge_open_file(file.value, label, error);
    if (judged != PrivateRead::kOk) return judged;
    return read_exact(file.value, out, label, error);
}

bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes,
    std::string_view label, bool& existed, std::string& error) {
    existed = false;
    if (bytes.size() > std::numeric_limits<DWORD>::max()) {
        error = std::string{label} + " quá lớn";
        return false;
    }
    const std::optional<std::wstring> self = process_user_sid();
    if (!self) {
        error = "không đọc được SID của tiến trình để khoá quyền " + std::string{label};
        return false;
    }
    // P: không kế thừa quyền của thư mục cha. Chỉ SYSTEM, Administrators và chủ được chạm tệp.
    const std::wstring sddl = L"D:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;FA;;;" + *self + L")";
    LocalBlock descriptor;
    PSECURITY_DESCRIPTOR sd = nullptr;
    if (convert_sddl(sddl.c_str(), &sd) == 0) {
        error = "không dựng được quyền riêng cho " + std::string{label};
        return false;
    }
    descriptor.data = sd;
    SECURITY_ATTRIBUTES attributes{};
    attributes.nLength = sizeof(attributes);
    attributes.lpSecurityDescriptor = sd;
    attributes.bInheritHandle = FALSE;
    const Created wrote = write_new(path, bytes, &attributes);
    if (wrote.ok) return true;
    existed = wrote.existed;
    if (!wrote.opened && !existed) error = "không tạo được " + std::string{label};
    if (!wrote.opened) return false;
    static_cast<void>(DeleteFileW(path.c_str()));
    error = "không ghi được " + std::string{label};
    return false;
}

#else

bool file_private(const std::filesystem::path& path, std::string_view label, std::string& error) {
    const int fd = open_no_follow(path);
    if (fd < 0) {
        fill_open_error(errno, label, error);
        return false;
    }
    struct stat info{};
    const PrivateRead kind = posix_stat(fd, label, error, info);
    ::close(fd);
    return kind == PrivateRead::kOk;
}

PrivateRead read_private_exact(const std::filesystem::path& path, std::span<std::byte> out,
    std::string_view label, std::string& error) {
    const int fd = open_no_follow(path);
    if (fd < 0) return posix_open_kind(errno, label, error);
    struct stat info{};
    const PrivateRead kind = posix_stat(fd, label, error, info);
    if (kind != PrivateRead::kOk) {
        ::close(fd);
        return kind;
    }
    const PrivateRead read = read_fd(fd, info, out, label, error);
    ::close(fd);
    return read;
}

bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes,
    std::string_view label, bool& existed, std::string& error) {
    existed = false;
    // Chế độ 0600 lúc tạo; umask chỉ bớt bit nên không làm tệp lỏng hơn.
    const int fd = ::open(path.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if (fd < 0) {
        existed = errno == EEXIST;
        if (!existed) error = "không tạo được " + std::string{label};
        return false;
    }
    std::size_t done = 0;
    while (done < bytes.size()) {
        const ssize_t got = ::write(fd, bytes.data() + done, bytes.size() - done);
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) break;
        done += static_cast<std::size_t>(got);
    }
    const bool synced = done == bytes.size() && ::fsync(fd) == 0;
    ::close(fd);
    if (synced) return true;
    static_cast<void>(::unlink(path.c_str()));
    error = "không ghi được " + std::string{label};
    return false;
}

#endif

} // namespace game::secure
