#pragma once
// Dịch văn bản TOML thành cây Node. Đây là chỗ duy nhất biết thư viện toml++.

#include "config/detail/node.hpp"
#include "config/issue.hpp"

#include <string_view>

namespace game::config::detail {

struct Parsed {
    Node root;
    IssueList issues;
};

[[nodiscard]] Parsed parse_text(std::string_view text);

} // namespace game::config::detail
