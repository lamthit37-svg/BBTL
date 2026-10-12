#include "account/ipc_key.hpp"

#include "secure/secure.hpp"

#include <fstream>

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
    std::ifstream in{path, std::ios::binary};
    if (!in) {
        error = "không đọc được ipc.key";
        return std::nullopt;
    }
    std::array<std::byte, kIpcKeyBytes> key{};
    in.read(reinterpret_cast<char*>(key.data()), static_cast<std::streamsize>(key.size()));
    const auto got = in.gcount();
    char extra = 0;
    in.read(&extra, 1);
    const bool extra_byte = in.gcount() != 0;
    if (got != static_cast<std::streamsize>(key.size()) || extra_byte || all_zero(key)) {
        error = "ipc.key không đúng 32 byte";
        return std::nullopt;
    }
    return key;
}

} // namespace

std::filesystem::path ipc_key_path(const std::filesystem::path& config_dir) {
    return (config_dir / ".." / "data" / "ipc.key").lexically_normal();
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
    std::ofstream out{path, std::ios::binary | std::ios::noreplace};
    if (!out) return read_key(path, error);
    out.write(reinterpret_cast<const char*>(key.data()), static_cast<std::streamsize>(key.size()));
    out.close();
    if (!out) {
        error = "không ghi được ipc.key";
        return std::nullopt;
    }
    return key;
}

} // namespace game::account
