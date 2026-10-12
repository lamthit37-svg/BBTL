#pragma once
// Bộ đọc store.toml: database game, nhịp đẩy đĩa và thư mục nhật ký.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config {

// Nút bảo mật của store; nhóm [security] tuỳ chọn, thiếu khoá nào thì dùng mặc định dưới đây.
struct StoreSecurity {
    // Store nhớ câu trả lời "còn được chơi" của auth chừng này; là cửa sổ tối đa sau khi ban.
    std::chrono::milliseconds standing_cache_ms{1000};
    // Tên nhân vật xoá mềm giữ chỗ cho chủ cũ chừng này ngày.
    std::int64_t name_reserve_days = 30;
    // Id mặt/tóc tạo được (creatable = 1 trong faces.tsv/hairs.tsv của client).
    std::vector<std::int64_t> female_faces{1, 2, 3, 4, 5, 14};
    std::vector<std::int64_t> male_faces{100, 101, 102, 103, 104, 113};
    std::vector<std::int64_t> female_hairs{1, 17, 19};
    std::vector<std::int64_t> male_hairs{5, 12, 14};
};

struct Store {
    DatabaseLogin database;
    std::chrono::milliseconds character_ms{0};
    std::chrono::milliseconds world_ms{0};
    std::string dir;
    StoreSecurity security;
};

[[nodiscard]] ReadResult<Store> read_store(std::string_view text);

} // namespace game::config
