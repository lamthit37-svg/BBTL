#pragma once
// Đọc dữ liệu cảnh từ đĩa: chỗ DUY NHẤT của module chạm hệ tệp. Mọi hàm không ném: lỗi đọc là LoadError.
// Phần còn lại của module (scene.hpp, ai_rules.hpp) thuần và nhận chữ đã đọc.
//
// Thư mục cảnh là phẳng: chỉ tệp thường ở ngay trong thư mục được xét (không đệ quy, liên kết tượng trưng và
// thư mục con bị bỏ). Tệp nhận: scene.toml, walk.path, walk.nav và mọi *.tsv.

#include "scenedata/ai_rules.hpp"
#include "scenedata/scene.hpp"

#include <cstddef>
#include <filesystem>

namespace game::scenedata {

// Trần số mục duyệt trong một thư mục cảnh (kể cả mục không nhận), chống thư mục khổng lồ.
inline constexpr std::size_t kMaxDirectoryEntries = 8192;

// Đọc nội dung các tệp của thư mục cảnh. Tên cảnh là tên thư mục. Thiếu scene.toml là lỗi.
[[nodiscard]] Loaded<SceneFiles> read_scene_files(const std::filesystem::path& directory);

// read_scene_files rồi parse_scene.
[[nodiscard]] Loaded<Scene> load_scene(const std::filesystem::path& directory);

// Đọc monster_ai_rules.tsv và monster_ai_rule_files.tsv trong thư mục (thường dev/server/tables/server).
[[nodiscard]] Loaded<AiRuleTable> load_ai_rules(const std::filesystem::path& tables_directory);

} // namespace game::scenedata
