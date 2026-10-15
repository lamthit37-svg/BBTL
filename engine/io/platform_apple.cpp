/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/io/platform_apple.cpp
 *  PHÂN HỆ   : Io / Platform
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt io/platform.hpp cho macOS và iOS: thư mục exe qua
 *    _NSGetExecutablePath, open_in_browser chưa làm.
 *  - CHƯA BIÊN DỊCH: máy phát triển không có macOS; viết theo tài liệu dyld(3)
 *    (int _NSGetExecutablePath(char* buf, uint32_t* bufsize), trả -1 và ghi cỡ
 *    cần khi bộ đệm thiếu).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "io/platform.hpp"

#include <mach-o/dyld.h>

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace game::io {

// Terminal của macOS và console của Xcode đã là UTF-8.
void use_utf8_console() noexcept {}

std::vector<std::string> command_arguments(int argc, const char* const* argv) {
    if (argc < 1 || argv == nullptr) return {};
    const std::span<const char* const> given(argv, static_cast<std::size_t>(argc));
    return {given.begin() + 1, given.end()};
}

// Trên iOS exe nằm ở gốc gói ứng dụng, nên thư mục này cũng là gốc dữ liệu đóng kèm.
std::filesystem::path executable_directory() {
    std::uint32_t size = 0;
    // Lần gọi đầu với bộ đệm cỡ 0 chỉ để hỏi cỡ cần.
    static_cast<void>(_NSGetExecutablePath(nullptr, &size));
    std::string name(size, '\0');
    if (_NSGetExecutablePath(name.data(), &size) != 0) return {};
    name.resize(std::char_traits<char>::length(name.c_str()));
    return std::filesystem::path(name).parent_path();
}

// Chưa làm: macOS là NSWorkspace openURL, iOS là UIApplication openURL (docs/NGHI-NGO.md).
bool open_in_browser(const std::filesystem::path& /*page*/) {
    return false;
}

} // namespace game::io
