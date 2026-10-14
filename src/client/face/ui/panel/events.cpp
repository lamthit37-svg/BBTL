#include "ui/panel/events.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr char kSeparator = '|';

} // namespace

std::optional<PostedEvent> PostedEvent::parse(std::string_view text) {
    PostedEvent made;
    const std::size_t first = text.find(kSeparator);
    made.name = std::string(text.substr(0, first));
    if (made.name.empty()) return std::nullopt;
    bool has_rest = first != std::string_view::npos;
    std::string_view rest = has_rest ? text.substr(first + 1) : std::string_view{};
    while (has_rest) {
        const std::size_t cut = rest.find(kSeparator);
        made.args.emplace_back(rest.substr(0, cut));
        has_rest = cut != std::string_view::npos;
        if (has_rest) rest = rest.substr(cut + 1);
    }
    return made;
}

std::vector<std::string_view> PostedEvent::arguments() const {
    std::vector<std::string_view> seen;
    seen.reserve(args.size());
    for (const std::string& one : args)
        seen.emplace_back(one);
    return seen;
}

} // namespace game::ui::panel
