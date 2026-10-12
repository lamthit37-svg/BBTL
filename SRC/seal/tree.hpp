#pragma once
// Đọc và ghi cây tệp cho công cụ niêm. Một tệp trong bộ nhớ tại một lúc. Game không gọi file này.
#include "seal/package.hpp"

#include <cstdint>
#include <filesystem>

namespace game::seal {

struct Saved {
    std::uint64_t files = 0;
    std::uint64_t bytes = 0;
};

using SaveResult = std::expected<Saved, Error>;

// from là thư mục nguồn hoặc tệp gói; into là tệp gói hoặc thư mục đích.
struct TreePaths {
    const std::filesystem::path* from = nullptr;
    const std::filesystem::path* into = nullptr;
};

[[nodiscard]] KeyResult load_key(const std::filesystem::path& path);
[[nodiscard]] UnitResult store_key(const Key& key, const std::filesystem::path& path);

[[nodiscard]] SaveResult seal_folder(const Key& key, const TreePaths& paths);
[[nodiscard]] SaveResult open_folder(const Key& key, const TreePaths& paths);
[[nodiscard]] SaveResult verify_folder(const Key& key, const std::filesystem::path& package);

} // namespace game::seal
