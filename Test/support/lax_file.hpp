#pragma once
// Tệp mà mọi tài khoản đọc được, để thử phép kiểm quyền của tệp bí mật (secure::file_private). Không thể dựa vào
// quyền kế thừa của thư mục dựng: trên Windows nó có thể đã riêng sẵn, nên phải đặt quyền rõ ràng.

#include <filesystem>
#include <fstream>
#include <string>
#include <string_view>
#include <system_error>

#ifdef _WIN32
#include "core/win32.hpp" // IWYU pragma: keep

// aclapi.h và sddl.h cần kiểu của windows.h nên đứng sau, khối riêng để clang-format không xếp lại.
#include <aclapi.h>
#include <sddl.h>
#endif

namespace game::test {

// Ghi `text` rồi cho Everyone FILE_GENERIC_WRITE, không có bit đọc. Dùng để chặn hồi quy: mặt nạ cũ
// chỉ bắt đọc nên tệp này từng được coi là riêng, trong khi tài khoản khác ghi đè được bí mật.
[[nodiscard]] inline bool write_world_writable(const std::filesystem::path& path, std::string_view text) {
    {
        std::ofstream out{path, std::ios::binary | std::ios::trunc};
        out << text;
        if (!out) return false;
    }
#ifdef _WIN32
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    const wchar_t* sddl = L"D:P(A;;FA;;;BA)(A;;FW;;;WD)";
    if (ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl, SDDL_REVISION_1, &descriptor, nullptr) == 0) {
        return false;
    }
    BOOL present = FALSE;
    BOOL defaulted = FALSE;
    PACL dacl = nullptr;
    DWORD status = ERROR_INVALID_DATA;
    if (GetSecurityDescriptorDacl(descriptor, &present, &dacl, &defaulted) != 0 && present != FALSE) {
        std::wstring native = path.native();
        status = SetNamedSecurityInfoW(native.data(), SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION, nullptr, nullptr, dacl, nullptr);
    }
    LocalFree(descriptor);
    return status == ERROR_SUCCESS;
#else
    namespace fs = std::filesystem;
    std::error_code error;
    const fs::perms mode = fs::perms::owner_read | fs::perms::owner_write | fs::perms::group_write | fs::perms::others_write;
    fs::permissions(path, mode, fs::perm_options::replace, error);
    return !error;
#endif
}

// Ghi `text` vào `path` rồi mở quyền đọc cho mọi người: Windows gắn DACL "Everyone: toàn quyền" không kế thừa,
// POSIX đặt chế độ 0644. Trả false nếu không ghi hoặc không đặt được quyền.
[[nodiscard]] inline bool write_world_readable(const std::filesystem::path& path, std::string_view text) {
    {
        std::ofstream out{path, std::ios::binary | std::ios::trunc};
        out << text;
        if (!out) return false;
    }
#ifdef _WIN32
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    if (ConvertStringSecurityDescriptorToSecurityDescriptorW(L"D:P(A;;FA;;;WD)", SDDL_REVISION_1, &descriptor,
            nullptr) == 0) {
        return false;
    }
    BOOL present = FALSE;
    BOOL defaulted = FALSE;
    PACL dacl = nullptr;
    DWORD status = ERROR_INVALID_DATA;
    if (GetSecurityDescriptorDacl(descriptor, &present, &dacl, &defaulted) != 0 && present != FALSE) {
        std::wstring native = path.native();
        status = SetNamedSecurityInfoW(native.data(), SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION, nullptr, nullptr, dacl, nullptr);
    }
    LocalFree(descriptor);
    return status == ERROR_SUCCESS;
#else
    namespace fs = std::filesystem;
    std::error_code error;
    fs::permissions(path,
        fs::perms::owner_read | fs::perms::owner_write | fs::perms::group_read | fs::perms::others_read,
        fs::perm_options::replace, error);
    return !error;
#endif
}

// Mở thư mục cho mọi người kèm kế thừa: tệp tạo trong đó bằng cách thường (ofstream) thì ai cũng đọc được, nên một
// bộ ghi tệp bí mật chỉ qua được phép kiểm nếu tự đặt quyền riêng lúc tạo. Windows gắn "Everyone: toàn quyền, kế thừa
// xuống tệp và thư mục con" không kế thừa từ cha; POSIX đặt 0777 (tệp thường vẫn ra 0644 theo umask).
[[nodiscard]] inline bool open_dir_to_everyone(const std::filesystem::path& path) {
#ifdef _WIN32
    PSECURITY_DESCRIPTOR descriptor = nullptr;
    if (ConvertStringSecurityDescriptorToSecurityDescriptorW(L"D:P(A;OICI;FA;;;WD)", SDDL_REVISION_1, &descriptor,
            nullptr) == 0) {
        return false;
    }
    BOOL present = FALSE;
    BOOL defaulted = FALSE;
    PACL dacl = nullptr;
    DWORD status = ERROR_INVALID_DATA;
    if (GetSecurityDescriptorDacl(descriptor, &present, &dacl, &defaulted) != 0 && present != FALSE) {
        std::wstring native = path.native();
        status = SetNamedSecurityInfoW(native.data(), SE_FILE_OBJECT,
            DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION, nullptr, nullptr, dacl, nullptr);
    }
    LocalFree(descriptor);
    return status == ERROR_SUCCESS;
#else
    std::error_code error;
    std::filesystem::permissions(path, std::filesystem::perms::all, std::filesystem::perm_options::replace, error);
    return !error;
#endif
}

} // namespace game::test
