#include "ui/script/variable.hpp"

#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

// Gốc so strncmp(tên, "View_DefaultCamera", 0x12) và strncmp(tên, "View_FOV", 8): tiền tố, không phải toàn tên.
[[nodiscard]] bool is_silent(std::string_view name) noexcept {
    return name.starts_with("View_DefaultCamera") || name.starts_with("View_FOV");
}

} // namespace

std::optional<std::string_view> VariableSystem::get(std::string_view name) const {
    const auto found = values_.find(name);
    if (found == values_.end()) return std::nullopt;
    return std::string_view(found->second);
}

// NOLINTNEXTLINE(bugprone-exception-escape)
std::optional<VariableChange> VariableSystem::set(std::string_view name, std::string_view value) noexcept {
    if (name.empty() || name.size() > kVariableNameLimit || value.size() >= kVariableValueLimit) return std::nullopt;
    auto found = values_.find(name);
    if (found == values_.end()) {
        if (values_.size() >= kVariableCountLimit) return std::nullopt;
        found = values_.emplace(std::string(name), std::string()).first;
    }
    if (found->second == value) return std::nullopt;
    found->second.assign(value);
    if (is_silent(name)) return std::nullopt;
    return VariableChange{.name = std::string(name), .value = std::string(value)};
}

} // namespace game::ui::script
