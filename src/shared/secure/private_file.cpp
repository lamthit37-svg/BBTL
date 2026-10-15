#include "secure/private_file.hpp"

#include <cstddef>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>

#ifdef _WIN32
#include "core/win32.hpp" // IWYU pragma: keep

// Các header con và aclapi.h, sddl.h cần kiểu của windows.h nên đứng sau, khối riêng để clang-format không xếp lại.
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
    explicit Handle(HANDLE handle) : value(handle) {}
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
    Handle(Handle&&) = delete;
    Handle& operator=(Handle&&) = delete;
    ~Handle() {
        if (value != INVALID_HANDLE_VALUE && value != nullptr) CloseHandle(value);
    }
};

// SID của người dùng đang chạy tiến trình, dạng chuỗi "S-1-5-21-...".
[[nodiscard]] std::optional<std::wstring> process_user_sid() {
    HANDLE raw = nullptr;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &raw) == 0) return std::nullopt;
    const Handle token{raw};
    DWORD need = 0;
    static_cast<void>(GetTokenInformation(token.value, TokenUser, nullptr, 0, &need));
    if (need == 0) return std::nullopt;
    std::vector<std::byte> buffer(need);
    if (GetTokenInformation(token.value, TokenUser, buffer.data(), need, &need) == 0) return std::nullopt;
    // Sao phần đầu ra một TOKEN_USER có căn lề đúng (bộ đệm byte không bảo đảm căn lề); Sid vẫn trỏ vào `buffer`.
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
    return IsWellKnownSid(sid, WinLocalSystemSid) != 0 || IsWellKnownSid(sid, WinBuiltinAdministratorsSid) != 0;
}

// Quyền nào trong mặt nạ cho phép đọc nội dung tệp, hoặc chiếm quyền để tự cho mình đọc.
[[nodiscard]] bool grants_read(ACCESS_MASK mask) noexcept {
    constexpr ACCESS_MASK kRead = FILE_READ_DATA | GENERIC_READ | GENERIC_ALL | MAXIMUM_ALLOWED;
    constexpr ACCESS_MASK kTakeOver = WRITE_DAC | WRITE_OWNER;
    return (mask & (kRead | kTakeOver)) != 0;
}

#endif

} // namespace

#ifdef _WIN32

bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes, std::string_view label,
    bool& existed, std::string& error) {
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
    if (ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl.c_str(), SDDL_REVISION_1, &sd, nullptr) == 0) {
        error = "không dựng được quyền riêng cho " + std::string{label};
        return false;
    }
    descriptor.data = sd;
    SECURITY_ATTRIBUTES attributes{};
    attributes.nLength = sizeof(attributes);
    attributes.lpSecurityDescriptor = sd;
    attributes.bInheritHandle = FALSE;
    bool written = false;
    {
        const Handle file{
            CreateFileW(path.c_str(), GENERIC_WRITE, 0, &attributes, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr)};
        if (file.value == INVALID_HANDLE_VALUE) {
            existed = GetLastError() == ERROR_FILE_EXISTS;
            if (!existed) error = "không tạo được " + std::string{label};
            return false;
        }
        DWORD wrote = 0;
        const BOOL ok = WriteFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &wrote, nullptr);
        written = ok != 0 && wrote == bytes.size() && FlushFileBuffers(file.value) != 0;
    }
    if (written) return true;
    // Handle đã đóng ở cuối khối trên, xoá được tệp cụt.
    static_cast<void>(DeleteFileW(path.c_str()));
    error = "không ghi được " + std::string{label};
    return false;
}

bool file_private(const std::filesystem::path& path, std::string_view label, std::string& error) {
    const std::string name{label};
    PACL dacl = nullptr;
    PSID owner = nullptr;
    LocalBlock descriptor;
    PSECURITY_DESCRIPTOR sd = nullptr;
    const DWORD status = GetNamedSecurityInfoW(path.c_str(), SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, &owner, nullptr, &dacl, nullptr, &sd);
    if (status != ERROR_SUCCESS) {
        error = "không đọc được quyền của " + name;
        return false;
    }
    descriptor.data = sd;
    if (dacl == nullptr) {
        error = name + " không có DACL: mọi người đọc được; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    const std::optional<std::wstring> self_text = process_user_sid();
    LocalBlock self_block;
    PSID self = nullptr;
    if (self_text && ConvertStringSidToSidW(self_text->c_str(), &self) != 0) self_block.data = self;
    if (!trusted_sid(owner, self)) {
        error = name + " thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    ACL_SIZE_INFORMATION size{};
    if (GetAclInformation(dacl, &size, sizeof(size), AclSizeInformation) == 0) {
        error = "không đọc được quyền của " + name;
        return false;
    }
    for (DWORD index = 0; index < size.AceCount; ++index) {
        void* raw = nullptr;
        if (GetAce(dacl, index, &raw) == 0) {
            error = "không đọc được quyền của " + name;
            return false;
        }
        const auto* header = static_cast<const ACE_HEADER*>(raw);
        if ((header->AceFlags & INHERIT_ONLY_ACE) != 0) continue;
        if (header->AceType == ACCESS_DENIED_ACE_TYPE) continue;
        if (header->AceType != ACCESS_ALLOWED_ACE_TYPE) {
            error = name + " có quyền lạ (không phải cho/cấm thường); xoá tệp, xoay khoá rồi chạy lại";
            return false;
        }
        auto* allowed = static_cast<ACCESS_ALLOWED_ACE*>(raw);
        PSID sid = &allowed->SidStart;
        if (grants_read(allowed->Mask) && !trusted_sid(sid, self)) {
            error = name + " cho tài khoản khác đọc (ví dụ Users); xoá tệp, xoay khoá rồi chạy lại";
            return false;
        }
    }
    return true;
}

#else

bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes, std::string_view label,
    bool& existed, std::string& error) {
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

bool file_private(const std::filesystem::path& path, std::string_view label, std::string& error) {
    const std::string name{label};
    struct stat info{};
    if (::stat(path.c_str(), &info) != 0) {
        error = "không đọc được quyền của " + name;
        return false;
    }
    if (info.st_uid != ::geteuid()) {
        error = name + " thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    if ((info.st_mode & 077) != 0) {
        error = name + " cho nhóm hoặc người khác đọc; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    return true;
}

#endif

} // namespace game::secure
