#pragma once
// Khoá 32 byte chung của cụm, chỉ để bịt khung ipc. Không phải mật khẩu database.
// Tệp nằm cạnh dữ liệu: <config>/../data/ipc.key. Store tạo nếu chưa có; gate chỉ đọc.

#include <array>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>

namespace game::account {

inline constexpr std::size_t kIpcKeyBytes = 32;

[[nodiscard]] std::filesystem::path ipc_key_path(const std::filesystem::path& config_dir);

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> load_ipc_key(const std::filesystem::path& path,
    std::string& error);

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> load_or_create_ipc_key(
    const std::filesystem::path& path, std::string& error);

} // namespace game::account
