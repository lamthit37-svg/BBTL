#include "config/startup.hpp"

#include "config/cluster.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"
#include "config/supervisor.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <cstddef>
#include <expected>
#include <format>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

// Bước chạy một loại mà cluster.toml không có khối [[process]] nào của loại đó thì không chạy được
// tiến trình nào. Gate không có khối: nó luôn là đúng một tiến trình.
void check_step(detail::Bag& bag, const Cluster& cluster, const StartStep& step) {
    if (step.process == ServiceKind::kGate) return;
    const auto serves = [&](const ProcessBlock& block) { return service_of(block.kind) == step.process; };
    if (std::ranges::any_of(cluster.processes, serves)) return;
    const std::size_t line = step.line == 0 ? 1 : step.line;
    const std::string_view name = name_of(step.process);
    detail::add_issue(bag, line, std::format("thiếu process {} trong cluster", name));
}

} // namespace

StartupResult check_startup(const Cluster& cluster, const Supervisor& supervisor) {
    detail::Bag bag;
    for (const StartStep& step : supervisor.steps) {
        check_step(bag, cluster, step);
    }
    IssueList issues = detail::take_issues(bag);
    if (!issues.empty()) return std::unexpected(std::move(issues));
    return {};
}

} // namespace game::config
