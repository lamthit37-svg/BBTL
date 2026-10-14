#pragma once
// zoned: nghe cổng ipc của zone trong cluster.toml, nhận kênh bền từ gate và chạy các cảnh ở 20 Hz.
// Cổng 0 (cấp động, chỉ loopback) vẫn chạy; gate không tìm được thì không nối. Dòng `ready ipc=<cổng>`
// báo cổng thật cho giám sát.

#include <filesystem>

namespace game::zone {

[[nodiscard]] int serve(const std::filesystem::path& config_dir);

} // namespace game::zone
