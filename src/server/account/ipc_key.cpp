#include "account/ipc_key.hpp"

#include "secure/private_file.hpp"
#include "secure/secure.hpp"

#include <array>
#include <cstddef>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <ios>
#include <optional>
#include <span>
#include <string>
#include <system_error>

namespace game::account {
namespace {

[[nodiscard]] bool all_zero(const std::array<std::byte, kIpcKeyBytes>& key) noexcept {
    for (const std::byte value : key) {
        if (value != std::byte{0}) return false;
    }
    return true;
}

[[nodiscard]] std::optional<std::array<std::byte, kIpcKeyBytes>> read_key(const std::filesystem::path& path,
    std::string& error) {
    if (!ipc_key_private(path, error)) return std::nullopt;
    std::ifstream input{path, std::ios::binary};
    if (!input) {
        error = "không đọc được ipc.key";
        return std::nullopt;
    }
    // Đọc dư một byte để phát hiện tệp dài hơn 32 byte.
    std::array<char, kIpcKeyBytes + 1> raw{};
    input.read(raw.data(), static_cast<std::streamsize>(raw.size()));
    const auto got = static_cast<std::size_t>(input.gcount());
    std::array<std::byte, kIpcKeyBytes> key{};
    if (got == kIpcKeyBytes) std::memcpy(key.data(), raw.data(), kIpcKeyBytes);
    secure::wipe_bytes(std::as_writable_bytes(std::span{raw}));
    if (got != kIpcKeyBytes || all_zero(key)) {
        secure::wipe_bytes(key);
        error = "ipc.key không đúng 32 byte";
        return std::nullopt;
    }
    return key;
}

} // namespace

std::filesystem::path ipc_key_path(const std::filesystem::path& config_dir) {
    return (config_dir / ".." / "data" / "ipc.key").lexically_normal();
}

bool ipc_key_private(const std::filesystem::path& path, std::string& error) {
    return secure::file_private(path, "ipc.key", error);
}

std::optional<std::array<std::byte, kIpcKeyBytes>> load_ipc_key(const std::filesystem::path& path, std::string& error) {
    std::error_code io;
    if (!std::filesystem::is_regular_file(path, io)) {
        error = "chưa có ipc.key";
        return std::nullopt;
    }
    return read_key(path, error);
}

std::optional<std::array<std::byte, kIpcKeyBytes>> load_or_create_ipc_key(const std::filesystem::path& path,
    std::string& error) {
    std::error_code io;
    if (std::filesystem::is_regular_file(path, io)) return read_key(path, error);
    std::filesystem::create_directories(path.parent_path(), io);
    if (io) {
        error = "không tạo được thư mục ipc.key";
        return std::nullopt;
    }
    std::array<std::byte, kIpcKeyBytes> key{};
    if (!secure::fill_random(key)) {
        error = "không sinh được khoá ipc";
        return std::nullopt;
    }
    bool existed = false;
    // Tạo tệp kèm quyền riêng ngay lúc tạo: không có khe giữa "tạo" và "khoá quyền".
    if (!secure::create_private_file(path, key, "ipc.key", existed, error)) {
        secure::wipe_bytes(key);
        if (existed) return read_key(path, error);
        return std::nullopt;
    }
    return key;
}

} // namespace game::account
