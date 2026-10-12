#include "io/platform.hpp"

#include <filesystem>
#include <system_error>

namespace game::io {

// Terminal của Linux và Android (adb shell) đã là UTF-8.
void use_utf8_console() noexcept {}

std::filesystem::path executable_directory() {
    std::error_code error;
    const std::filesystem::path exe = std::filesystem::read_symlink("/proc/self/exe", error);
    if (error) return {};
    return exe.parent_path();
}

// Chưa làm: Android phải gửi Intent ACTION_VIEW qua JNI, Linux là xdg-open (docs/NGHI-NGO.md).
bool open_in_browser(const std::filesystem::path& /*page*/) {
    return false;
}

} // namespace game::io
