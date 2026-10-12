#pragma once
// Bộ đọc admin.toml. [[operator]] chưa có trong tệp: thêm được, không bắt buộc.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config {

struct Operator {
    std::string name;
    std::int64_t level = 0;
    std::size_t line = 0;
};

struct Admin {
    Endpoint listen;
    std::string token_file;
    std::vector<Operator> operators;
};

[[nodiscard]] ReadResult<Admin> read_admin(std::string_view text);

} // namespace game::config
