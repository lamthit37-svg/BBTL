#pragma once
// Luật K6: đọc TOML của config và scene.toml, thêm lỗi vào kết quả lint.

#include "content/lint.hpp"

#include <filesystem>

namespace game::linttool {

void append_config(const std::filesystem::path& root, game::content::LintResult& result);

} // namespace game::linttool
