// Phân loại tên card và chấm điểm context GL. Bảng điểm nằm ở profile_score.
#include "gpu/gles/pick.hpp"

namespace game::gpu::gles {
namespace {

[[nodiscard]] bool has_text(std::string_view haystack, std::string_view needle) noexcept {
    if (needle.empty() || haystack.size() < needle.size()) return false;
    for (std::size_t start = 0; start + needle.size() <= haystack.size(); ++start) {
        bool same = true;
        for (std::size_t index = 0; index < needle.size(); ++index) {
            char left = haystack[start + index];
            char right = needle[index];
            if (left >= 'A' && left <= 'Z') left = static_cast<char>(left - 'A' + 'a');
            if (right >= 'A' && right <= 'Z') right = static_cast<char>(right - 'A' + 'a');
            if (left != right) same = false;
        }
        if (same) return true;
    }
    return false;
}

[[nodiscard]] bool is_word_edge(std::string_view text, std::size_t index) noexcept {
    if (index >= text.size()) return true;
    const char letter = text[index];
    const bool is_alpha = (letter >= 'A' && letter <= 'Z') || (letter >= 'a' && letter <= 'z');
    return !is_alpha;
}

// "arc" không được khớp "search".
[[nodiscard]] bool has_word(std::string_view haystack, std::string_view needle) noexcept {
    if (!has_text(haystack, needle)) return false;
    for (std::size_t start = 0; start + needle.size() <= haystack.size(); ++start) {
        bool same = true;
        for (std::size_t index = 0; index < needle.size(); ++index) {
            char left = haystack[start + index];
            char right = needle[index];
            if (left >= 'A' && left <= 'Z') left = static_cast<char>(left - 'A' + 'a');
            if (right >= 'A' && right <= 'Z') right = static_cast<char>(right - 'A' + 'a');
            if (left != right) same = false;
        }
        const bool edged = is_word_edge(haystack, start == 0 ? haystack.size() : start - 1) &&
            is_word_edge(haystack, start + needle.size());
        if (same && edged) return true;
        if (start == 0 && same && is_word_edge(haystack, needle.size())) return true;
    }
    return false;
}

[[nodiscard]] bool is_software_name(std::string_view renderer) noexcept {
    return has_text(renderer, "llvmpipe") || has_text(renderer, "lavapipe") || has_text(renderer, "swiftshader") ||
        has_text(renderer, "softpipe") || has_text(renderer, "microsoft basic") || has_text(renderer, "gdi generic");
}

// "Radeon(TM) Graphics" là APU. Card rời AMD ghi RX, không kèm chữ graphics đó.
[[nodiscard]] bool is_discrete_name(std::string_view renderer) noexcept {
    if (is_software_name(renderer)) return false;
    if (has_text(renderer, "nvidia") || has_text(renderer, "geforce")) return true;
    if (has_text(renderer, "radeon") && !has_text(renderer, "graphics")) return true;
    return has_word(renderer, "arc");
}

} // namespace

RendererClass classify_renderer(std::string_view renderer) noexcept {
    RendererClass kind;
    kind.is_software = is_software_name(renderer);
    kind.is_discrete = is_discrete_name(renderer);
    return kind;
}

void apply_storage_floor(GlProfile& profile) noexcept {
    if (profile.max_storage_blocks != 0) return;
    const bool is_gl = !profile.is_es && (profile.major > 4 || (profile.major == 4 && profile.minor >= 3));
    const bool is_gles = profile.is_es && (profile.major > 3 || (profile.major == 3 && profile.minor >= 1));
    if (!is_gl && !is_gles) return;
    profile.max_storage_blocks = 8;
}

bool is_usable(const GlProfile& profile) noexcept {
    const bool is_gl = !profile.is_es && profile.major >= 4 && (profile.major > 4 || profile.minor >= 3);
    const bool is_gles = profile.is_es && profile.major >= 3 && (profile.major > 3 || profile.minor >= 1);
    if (!is_gl && !is_gles) return false;
    return profile.max_uniform_blocks >= 2 && profile.max_storage_blocks >= 1;
}

int profile_score(const GlProfile& profile) noexcept {
    if (!is_usable(profile) || profile.is_software) return 0;
    return 1;
}

} // namespace game::gpu::gles
