/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/detail/roots.hpp
 *  PHÂN HỆ   : Shader / Detail / Roots
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chọn ít thư mục nhất để Watcher phủ thư mục của danh sách và mọi include.
 *    Watcher đã theo dõi cả thư mục con. So theo biên thư mục: "C:/a" phủ
 *    "C:/a/b" nhưng không phủ "C:/ab". Đường rỗng không phải tiền tố của mọi
 *    đường. Nguồn: luật chọn của engine/shader/library.cpp trước 2026-10-16
 *    dùng starts_with trên chuỗi. Khác gốc: biên '/' và chuỗi tổ tiên, không
 *    phải tiền tố ký tự.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "fs/path.hpp"
#include "shader/manifest.hpp"

#include <algorithm>
#include <functional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader::detail {

// Dạng so sánh: normalize, rồi bỏ '/' cuối trừ gốc ("/", "C:/", "//").
[[nodiscard]] inline std::string directory_key(std::string_view path) {
    std::string normal = fs::normalize(path);
    const bool keep_slash = normal.size() <= 1 || normal == "//" || (normal.size() == 3 && normal[1] == ':');
    if (keep_slash || normal.back() != '/') return normal;
    normal.pop_back();
    return normal;
}

[[nodiscard]] inline bool contains_key(std::span<const std::string> sorted, std::string_view key) noexcept {
    const auto found = std::ranges::lower_bound(sorted, key, std::less<>{});
    return found != sorted.end() && *found == key;
}

// Có một đường trong sorted (đã sắp, không trùng) là tổ tiên thật của directory. Đi lên bằng
// fs::parent, mỗi bậc một lần tìm nhị phân: O(độ sâu · log n), không quét cả danh sách.
[[nodiscard]] inline bool has_ancestor(std::span<const std::string> sorted, std::string_view directory) noexcept {
    std::string_view cursor = directory;
    while (!cursor.empty()) {
        const std::string_view above = fs::parent(cursor);
        if (above.empty() || above == cursor) return false;
        if (contains_key(sorted, above)) return true;
        cursor = above;
    }
    return false;
}

inline void keep_root(std::vector<std::string>& roots, std::span<const std::string> sorted, const std::string& directory) {
    if (has_ancestor(sorted, directory)) return;
    roots.push_back(directory);
}

// n = 1 + số include. Sắp một lần rồi mỗi đường chỉ hỏi tổ tiên của nó. Trần độ sâu là độ dài
// chính đường đó.
[[nodiscard]] inline std::vector<std::string> watch_roots(const Manifest& manifest) {
    std::vector<std::string> directories;
    directories.reserve(manifest.include_dirs.size() + 1);
    directories.push_back(directory_key(manifest.directory));
    for (const std::string& directory : manifest.include_dirs) {
        directories.push_back(directory_key(directory));
    }
    std::ranges::sort(directories);
    const auto repeated = std::ranges::unique(directories);
    directories.erase(repeated.begin(), repeated.end());
    std::vector<std::string> roots;
    roots.reserve(directories.size());
    for (const std::string& directory : directories) keep_root(roots, directories, directory);
    return roots;
}

} // namespace game::shader::detail
