#include "social/text.hpp"

#include "core/text.hpp"

#include <algorithm>
#include <cstddef>
#include <string>
#include <string_view>

namespace game::social {

bool is_plain_text(std::string_view text, std::size_t max_bytes) noexcept {
    if (text.size() > max_bytes || !core::is_valid_utf8(text)) return false;
    return std::ranges::none_of(text, [](char c) {
        const auto byte = static_cast<unsigned char>(c);
        return byte < 0x20U || byte == 0x7FU;
    });
}

std::size_t codepoint_count(std::string_view text) noexcept {
    std::size_t count = 0;
    while (!text.empty()) {
        const core::Utf8Step step = core::utf8_step(text);
        text.remove_prefix(step.length);
        ++count;
    }
    return count;
}

bool has_edge_space(std::string_view text) noexcept {
    return !text.empty() && (text.front() == ' ' || text.back() == ' ');
}

std::string fold_name(std::string_view text) {
    std::string out(text);
    std::ranges::transform(out, out.begin(), [](char c) { return c >= 'A' && c <= 'Z' ? static_cast<char>(c - 'A' + 'a') : c; });
    return out;
}

} // namespace game::social
