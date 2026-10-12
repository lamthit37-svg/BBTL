#pragma once
// Phép kiểm chung cho rules/*.toml và scene.toml: đọc được và schema = 1.
// Khoá khác không bị coi là lạ, vì các tệp này chưa có struct.

#include "config/issue.hpp"

#include <cstdint>
#include <string_view>

namespace game::config {

struct LooseDocument {
    std::int64_t schema = 0;
};

[[nodiscard]] ReadResult<LooseDocument> read_loose(std::string_view text);

} // namespace game::config
