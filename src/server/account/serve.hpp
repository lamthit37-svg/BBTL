#pragma once
// authd giữ database tài khoản, stored giữ database nhân vật. Cả hai nghe cổng ipc trong
// cluster.toml sau khi migration xong. Không có secrets.local.toml thì in ready và chờ dừng,
// để cụm thử không có PostgreSQL vẫn khởi động được.

#include <filesystem>

namespace game::account {

[[nodiscard]] int serve_auth(const std::filesystem::path& config_dir);
[[nodiscard]] int serve_game(const std::filesystem::path& config_dir);

} // namespace game::account
