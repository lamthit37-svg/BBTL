#pragma once
// Tệp mà mọi tài khoản đọc được, để thử phép kiểm quyền của tệp bí mật (account::file_private). Không thể dựa vào
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

} // namespace game::test
