// Nạp DLL của trình dịch shader (slang.dll, dxcompiler.dll) lúc chạy: tệp cạnh exe, rồi tới
// %VULKAN_SDK%\Bin. Không bao giờ tìm theo PATH: bản dxcompiler.dll của Windows SDK không sinh
// được SPIR-V, và nạp DLL theo tên trần là cửa cho DLL lạ. DLL nạp lúc chạy nên module shader không
// phụ thuộc trình dịch lúc link: thiếu DLL thì Compiler::create trả Unsupported, còn gói đã dịch
// sẵn vẫn đọc được (shader/package.hpp).
#pragma once

#include "core/system.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <winbase.h>

#include <bit>
#include <filesystem>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

namespace game::shader::detail {

struct LibraryCloser {
    void operator()(HMODULE module) const noexcept { ::FreeLibrary(module); }
};

using Library = std::unique_ptr<std::remove_pointer_t<HMODULE>, LibraryCloser>;

[[nodiscard]] inline std::wstring environment(const wchar_t* name) {
    const DWORD size = ::GetEnvironmentVariableW(name, nullptr, 0);
    if (size == 0) return {};
    std::wstring value(size, L'\0');
    const DWORD written = ::GetEnvironmentVariableW(name, value.data(), size);
    value.resize(written < size ? written : 0);
    return value;
}

// Những chỗ một DLL của trình dịch có thể nằm, theo thứ tự thử.
[[nodiscard]] inline std::vector<std::filesystem::path> library_candidates(std::wstring_view file) {
    std::vector<std::filesystem::path> paths;
    paths.push_back(core::exe_directory() / file);
    const std::wstring sdk = environment(L"VULKAN_SDK");
    if (!sdk.empty()) paths.push_back(std::filesystem::path(sdk) / L"Bin" / file);
    return paths;
}

// Đường dẫn tuyệt đối cộng cờ LOAD_WITH_ALTERED_SEARCH_PATH: DLL mà trình dịch cần được tìm cạnh nó
// trước. Rỗng khi không mở được.
[[nodiscard]] inline Library open_library(const std::filesystem::path& path) noexcept {
    return Library(::LoadLibraryExW(path.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH));
}

// Hàm xuất tên name của DLL đã nạp, đọc thành kiểu hàm Fn do người gọi biết; nullptr khi DLL không có.
// GetProcAddress trả FARPROC; std::bit_cast giữ nguyên các bit của con trỏ mà không qua phép ép giữa
// hai chữ ký hàm khác nhau, thứ -Wcast-function-type của GCC và Clang đều từ chối. Kiểm
// bugprone-bitwise-pointer-cast nhắm vào con trỏ đối tượng; ở đây cả hai bên là con trỏ hàm và
// static_assert giữ đúng điều đó.
template <class Fn>
[[nodiscard]] Fn find_symbol(const Library& library, const char* name) noexcept {
    static_assert(std::is_pointer_v<Fn> && std::is_function_v<std::remove_pointer_t<Fn>>);
    // NOLINTNEXTLINE(bugprone-bitwise-pointer-cast)
    return std::bit_cast<Fn>(::GetProcAddress(library.get(), name));
}

} // namespace game::shader::detail
