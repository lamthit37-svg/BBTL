#include "account/ipc_key.hpp"

#include "secure/secure.hpp"

#include <cerrno>
#include <fstream>
#include <span>
#include <vector>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <aclapi.h>
#include <sddl.h>
#else
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

namespace game::account {
namespace {

[[nodiscard]] bool all_zero(const std::array<std::byte, kIpcKeyBytes>& key) noexcept {
    for (const std::byte value : key) {
        if (value != std::byte{0}) return false;
    }
    return true;
}

#ifdef _WIN32

struct LocalBlock {
    void* data = nullptr;
    LocalBlock() = default;
    LocalBlock(const LocalBlock&) = delete;
    LocalBlock& operator=(const LocalBlock&) = delete;
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
    const auto* user = reinterpret_cast<const TOKEN_USER*>(buffer.data());
    LocalBlock text;
    LPWSTR sid_text = nullptr;
    if (ConvertSidToStringSidW(user->User.Sid, &sid_text) == 0) return std::nullopt;
    text.data = sid_text;
    return std::wstring{sid_text};
}

[[nodiscard]] bool trusted_sid(PSID sid, PSID self) noexcept {
    if (sid == nullptr) return false;
    if (self != nullptr && EqualSid(sid, self) != 0) return true;
    return IsWellKnownSid(sid, WinLocalSystemSid) != 0 || IsWellKnownSid(sid, WinBuiltinAdministratorsSid) != 0;
}

// Quyền nào trong mặt nạ cho phép đọc nội dung tệp.
[[nodiscard]] bool grants_read(ACCESS_MASK mask) noexcept {
    constexpr ACCESS_MASK kRead = FILE_READ_DATA | GENERIC_READ | GENERIC_ALL | MAXIMUM_ALLOWED;
    constexpr ACCESS_MASK kTakeOver = WRITE_DAC | WRITE_OWNER;
    return (mask & (kRead | kTakeOver)) != 0;
}

[[nodiscard]] bool create_private(const std::filesystem::path& path, std::span<const std::byte> key, bool& existed,
    std::string& error) {
    existed = false;
    const std::optional<std::wstring> self = process_user_sid();
    if (!self) {
        error = "không đọc được SID của tiến trình để khoá quyền ipc.key";
        return false;
    }
    // P: không kế thừa quyền của thư mục cha. Chỉ SYSTEM, Administrators và chủ được chạm tệp.
    const std::wstring sddl = L"D:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;FA;;;" + *self + L")";
    LocalBlock descriptor;
    PSECURITY_DESCRIPTOR sd = nullptr;
    if (ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl.c_str(), SDDL_REVISION_1, &sd, nullptr) == 0) {
        error = "không dựng được quyền riêng cho ipc.key";
        return false;
    }
    descriptor.data = sd;
    SECURITY_ATTRIBUTES attributes{};
    attributes.nLength = sizeof(attributes);
    attributes.lpSecurityDescriptor = sd;
    attributes.bInheritHandle = FALSE;
    const Handle file{CreateFileW(path.c_str(), GENERIC_WRITE, 0, &attributes, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr)};
    if (file.value == INVALID_HANDLE_VALUE) {
        existed = GetLastError() == ERROR_FILE_EXISTS;
        if (!existed) error = "không tạo được ipc.key";
        return false;
    }
    DWORD wrote = 0;
    const BOOL ok = WriteFile(file.value, key.data(), static_cast<DWORD>(key.size()), &wrote, nullptr);
    if (ok == 0 || wrote != key.size() || FlushFileBuffers(file.value) == 0) {
        error = "không ghi được ipc.key";
        return false;
    }
    return true;
}

#else

[[nodiscard]] bool create_private(const std::filesystem::path& path, std::span<const std::byte> key, bool& existed,
    std::string& error) {
    existed = false;
    const int fd = ::open(path.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if (fd < 0) {
        existed = errno == EEXIST;
        if (!existed) error = "không tạo được ipc.key";
        return false;
    }
    std::size_t done = 0;
    while (done < key.size()) {
        const ssize_t got = ::write(fd, key.data() + done, key.size() - done);
        if (got <= 0) break;
        done += static_cast<std::size_t>(got);
    }
    const bool synced = done == key.size() && ::fsync(fd) == 0;
    ::close(fd);
    if (!synced) error = "không ghi được ipc.key";
    return synced;
}

#endif

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> read_key(const std::filesystem::path& path,
    std::string& error) {
    if (!ipc_key_private(path, error)) return std::nullopt;
    std::ifstream in{path, std::ios::binary};
    if (!in) {
        error = "không đọc được ipc.key";
        return std::nullopt;
    }
    std::array<std::byte, kIpcKeyBytes> key{};
    in.read(reinterpret_cast<char*>(key.data()), static_cast<std::streamsize>(key.size()));
    const auto got = in.gcount();
    char extra = 0;
    in.read(&extra, 1);
    const bool extra_byte = in.gcount() != 0;
    if (got != static_cast<std::streamsize>(key.size()) || extra_byte || all_zero(key)) {
        secure::wipe_bytes(key);
        error = "ipc.key không đúng 32 byte";
        return std::nullopt;
    }
    return key;
}

} // namespace

std::filesystem::path ipc_key_path(const std::filesystem::path& config_dir) {
    return (config_dir / ".." / "data" / "ipc.key").lexically_normal();
}

#ifdef _WIN32

bool ipc_key_private(const std::filesystem::path& path, std::string& error) {
    PACL dacl = nullptr;
    PSID owner = nullptr;
    LocalBlock descriptor;
    PSECURITY_DESCRIPTOR sd = nullptr;
    const DWORD status = GetNamedSecurityInfoW(path.c_str(), SE_FILE_OBJECT,
        OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, &owner, nullptr, &dacl, nullptr, &sd);
    if (status != ERROR_SUCCESS) {
        error = "không đọc được quyền của ipc.key";
        return false;
    }
    descriptor.data = sd;
    if (dacl == nullptr) {
        error = "ipc.key không có DACL: mọi người đọc được; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    const std::optional<std::wstring> self_text = process_user_sid();
    LocalBlock self_block;
    PSID self = nullptr;
    if (self_text && ConvertStringSidToSidW(self_text->c_str(), &self) != 0) self_block.data = self;
    if (!trusted_sid(owner, self)) {
        error = "ipc.key thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    ACL_SIZE_INFORMATION size{};
    if (GetAclInformation(dacl, &size, sizeof(size), AclSizeInformation) == 0) {
        error = "không đọc được quyền của ipc.key";
        return false;
    }
    for (DWORD index = 0; index < size.AceCount; ++index) {
        void* raw = nullptr;
        if (GetAce(dacl, index, &raw) == 0) {
            error = "không đọc được quyền của ipc.key";
            return false;
        }
        const auto* header = static_cast<const ACE_HEADER*>(raw);
        if (header->AceFlags & INHERIT_ONLY_ACE) continue;
        if (header->AceType == ACCESS_DENIED_ACE_TYPE) continue;
        if (header->AceType != ACCESS_ALLOWED_ACE_TYPE) {
            error = "ipc.key có quyền lạ (không phải cho/cấm thường); xoá tệp, xoay khoá rồi chạy lại";
            return false;
        }
        const auto* allowed = static_cast<const ACCESS_ALLOWED_ACE*>(raw);
        PSID sid = const_cast<DWORD*>(&allowed->SidStart);
        if (grants_read(allowed->Mask) && !trusted_sid(sid, self)) {
            error = "ipc.key cho tài khoản khác đọc (ví dụ Users); xoá tệp, xoay khoá rồi chạy lại";
            return false;
        }
    }
    return true;
}

#else

bool ipc_key_private(const std::filesystem::path& path, std::string& error) {
    struct stat info{};
    if (::stat(path.c_str(), &info) != 0) {
        error = "không đọc được quyền của ipc.key";
        return false;
    }
    if (info.st_uid != ::geteuid()) {
        error = "ipc.key thuộc tài khoản khác; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    if ((info.st_mode & 077) != 0) {
        error = "ipc.key cho nhóm hoặc người khác đọc; xoá tệp, xoay khoá rồi chạy lại";
        return false;
    }
    return true;
}

#endif

std::optional<std::array<std::byte, kIpcKeyBytes>> load_ipc_key(const std::filesystem::path& path, std::string& error) {
    std::error_code io;
    if (!std::filesystem::is_regular_file(path, io)) {
        error = "chưa có ipc.key";
        return std::nullopt;
    }
    return read_key(path, error);
}

std::optional<std::array<std::byte, kIpcKeyBytes>> load_or_create_ipc_key(const std::filesystem::path& path,
    std::string& error) {
    std::error_code io;
    if (std::filesystem::is_regular_file(path, io)) return read_key(path, error);
    std::filesystem::create_directories(path.parent_path(), io);
    if (io) {
        error = "không tạo được thư mục ipc.key";
        return std::nullopt;
    }
    std::array<std::byte, kIpcKeyBytes> key{};
    if (!secure::fill_random(key)) {
        error = "không sinh được khoá ipc";
        return std::nullopt;
    }
    bool existed = false;
    // Tạo tệp kèm quyền riêng ngay lúc tạo: không có khe giữa "tạo" và "khoá quyền".
    if (!create_private(path, key, existed, error)) {
        secure::wipe_bytes(key);
        if (existed) return read_key(path, error);
        return std::nullopt;
    }
    return key;
}

} // namespace game::account
