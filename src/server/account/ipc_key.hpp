#pragma once
// Khoá 32 byte chung của cụm, chỉ để bọc khung ipc và ký cap. Không phải mật khẩu database.
// Tệp nằm cạnh dữ liệu: <config>/../data/ipc.key. Store/auth tạo nếu chưa có; gate chỉ đọc.
// Ai đọc được tệp là ký được cap cho mọi tài khoản, nên tệp phải riêng của tài khoản chạy máy chủ:
// Windows chỉ SYSTEM, Administrators và chủ tiến trình; POSIX chế độ 0600 của chủ. Tệp lỏng hơn
// thì máy chủ từ chối chạy (không tự sửa quyền, để người vận hành biết khoá có thể đã lộ và xoay khoá).

#include <array>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>

namespace game::account {

inline constexpr std::size_t kIpcKeyBytes = 32;

[[nodiscard]] std::filesystem::path ipc_key_path(const std::filesystem::path& config_dir);

// true khi chỉ chủ (và SYSTEM/Administrators trên Windows) đọc được tệp. Sai thì error nói vì sao.
[[nodiscard]] bool ipc_key_private(const std::filesystem::path& path, std::string& error);

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> load_ipc_key(const std::filesystem::path& path,
    std::string& error);

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> load_or_create_ipc_key(
    const std::filesystem::path& path, std::string& error);

} // namespace game::account
