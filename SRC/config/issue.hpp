#pragma once
// Một lỗi đọc cấu hình: số dòng trong văn bản (từ 1) và câu tiếng Việt.
// Bộ đọc trả mọi lỗi một lượt, không dừng ở lỗi đầu và không dừng tiến trình.

#include <cstddef>
#include <expected>
#include <string>
#include <vector>

namespace game::config {

struct Issue {
    std::size_t line = 0;
    std::string message;
};

using IssueList = std::vector<Issue>;

template <typename Value>
using ReadResult = std::expected<Value, IssueList>;

using StartupResult = std::expected<void, IssueList>;

} // namespace game::config
