#pragma once
// Việc đọc một tệp refs: đúng tám tên cột theo thứ tự, rồi từng dòng tham chiếu.

#include "content/detail/scan.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace game::content {

struct RefRule {
    std::string child;
    std::string child_column;
    std::string parent;
    std::string parent_column;
    std::vector<std::string> absent;
    std::int64_t known_missing = 0;
    bool known_ok = false;
    std::string path;
    std::size_t line = 0;
    bool parent_star = false;
};

// Đọc một tệp. Dòng sai hình không thành quy tắc. issues nhận mọi lỗi của tệp.
void read_ref_file(const TextFile& file, std::vector<RefRule>& rules, IssueList& issues);

} // namespace game::content
