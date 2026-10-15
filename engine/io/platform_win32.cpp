/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/io/platform_win32.cpp
 *  PHÂN HỆ   : Io / Platform
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt io/platform.hpp cho Windows: console UTF-8, đối số UTF-8 qua
 *    CommandLineToArgvW, thư mục exe, mở tệp bằng ShellExecuteExW.
 *  - windows.h lấy từ core/win32.hpp; header con của Win32 include trực tiếp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "io/platform.hpp"

#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <basetsd.h>
#include <libloaderapi.h>
#include <processenv.h>
#include <shellapi.h>
#include <winbase.h>
#include <winuser.h>

#include <cstddef>
#include <filesystem>
#include <span>
#include <string>
#include <system_error>
#include <vector>

namespace game::io {
namespace {

// Đường dẫn dài của Windows tối đa 32767 ký tự UTF-16.
constexpr DWORD kMaxPathChars = 32768;

// ShellExecuteExW báo thành công bằng một HINSTANCE lớn hơn 32 (quy ước còn lại từ Windows 16 bit).
constexpr INT_PTR kShellSucceeded = 32;

// Danh sách đối số của CommandLineToArgvW; giải phóng bằng LocalFree.
class WideCommand {
public:
    WideCommand() noexcept : list_(CommandLineToArgvW(GetCommandLineW(), &count_)) {}
    WideCommand(const WideCommand&) = delete;
    WideCommand& operator=(const WideCommand&) = delete;
    WideCommand(WideCommand&&) = delete;
    WideCommand& operator=(WideCommand&&) = delete;
    ~WideCommand() {
        if (list_ != nullptr) static_cast<void>(LocalFree(static_cast<void*>(list_)));
    }

    // Rỗng khi dòng lệnh không đọc được.
    [[nodiscard]] std::span<wchar_t* const> arguments() const noexcept {
        if (list_ == nullptr || count_ < 1) return {};
        return {list_, static_cast<std::size_t>(count_)};
    }

private:
    int count_ = 0;
    wchar_t** list_ = nullptr;
};

} // namespace

std::vector<std::string> command_arguments(int argc, const char* const* argv) {
    const WideCommand command;
    const std::span<wchar_t* const> wide = command.arguments();
    if (!wide.empty()) {
        std::vector<std::string> texts;
        texts.reserve(wide.size() - 1);
        for (const wchar_t* const one : wide.subspan(1)) texts.push_back(core::narrow(one));
        return texts;
    }
    if (argc < 1 || argv == nullptr) return {};
    const std::span<const char* const> given(argv, static_cast<std::size_t>(argc));
    return {given.begin() + 1, given.end()};
}

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
