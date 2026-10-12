// windows.h lấy từ core/win32.hpp; header con của Win32 include trực tiếp.
#include "io/platform.hpp"

#include "core/win32.hpp" // IWYU pragma: keep

#include <libloaderapi.h>
#include <shellapi.h>
#include <winuser.h>

#include <filesystem>
#include <string>
#include <system_error>

namespace game::io {
namespace {

// Đường dẫn dài của Windows tối đa 32767 ký tự UTF-16.
constexpr DWORD kMaxPathChars = 32768;

// ShellExecuteExW báo thành công bằng một HINSTANCE lớn hơn 32 (quy ước còn lại từ Windows 16 bit).
constexpr INT_PTR kShellSucceeded = 32;

} // namespace

// SEE_MASK_FLAG_NO_UI: lỗi trả về bằng mã, không bằng hộp thoại chặn luồng cửa sổ của game.
bool open_in_browser(const std::filesystem::path& page) {
    std::error_code ignored;
    if (!std::filesystem::is_regular_file(page, ignored)) return false;
    const std::wstring target = std::filesystem::absolute(page, ignored).native();
    SHELLEXECUTEINFOW ask{};
    ask.cbSize = sizeof(ask);
    ask.fMask = SEE_MASK_FLAG_NO_UI;
    ask.lpVerb = L"open";
    ask.lpFile = target.c_str();
    ask.nShow = SW_SHOWNORMAL;
    if (ShellExecuteExW(&ask) == FALSE) return false;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hInstApp là mã kết quả đội lốt handle (UB-03)
    return reinterpret_cast<INT_PTR>(ask.hInstApp) > kShellSucceeded;
}

void use_utf8_console() noexcept {
    // Console không có (exe chạy không cửa sổ) thì hai lời gọi thất bại, không ảnh hưởng gì.
    static_cast<void>(SetConsoleOutputCP(CP_UTF8));
    static_cast<void>(SetConsoleCP(CP_UTF8));
}

std::filesystem::path executable_directory() {
    std::wstring name(kMaxPathChars, L'\0');
    const DWORD length = GetModuleFileNameW(nullptr, name.data(), kMaxPathChars);
    const bool is_whole = length > 0 && length < kMaxPathChars;
    if (!is_whole) return {};
    name.resize(length);
    return std::filesystem::path(name).parent_path();
}

} // namespace game::io
