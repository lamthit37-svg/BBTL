#pragma once
// Dòng lệnh của một tiến trình máy chủ: --config <thư mục> [--id <n>] [--no-postgres].
// --id chỉ dành cho loại có khối [[process]] trong cluster.toml (store, auth, billing, world,
// zone), vắng thì là 0. --no-postgres chỉ dành cho trình giám sát.

#include "service/service.hpp"

#include <cstdint>
#include <expected>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::service::detail {

struct Request {
    std::filesystem::path config_dir;
    // Số thứ tự trong cùng loại; trình giám sát và gate không có.
    std::optional<std::int32_t> id;
    bool skips_postgres = false;
    // Có thì thienlong_gate chỉ sinh khoá rồi thoát, không cần --config và không in ready.
    std::optional<std::filesystem::path> identity_out;
};

// Lỗi là một câu tiếng Việt, in kèm dòng cách dùng.
using RequestResult = std::expected<Request, std::string>;

// arguments không gồm tên exe.
[[nodiscard]] RequestResult parse_request(Kind kind, std::span<const std::string> arguments);

// Tên trong cluster.toml và trong tên exe: store, auth, billing, world, zone, gate, server.
[[nodiscard]] std::string_view kind_name(Kind kind) noexcept;

// Một dòng cách dùng của loại tiến trình này.
[[nodiscard]] std::string usage(Kind kind);

} // namespace game::service::detail
