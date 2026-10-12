#include "ui/panel/wording.hpp"

#include "gui/strings.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kTagOpen = "#{";
constexpr std::string_view kTagClose = "}";
constexpr std::string_view kSlotMark = "%s";
// Một chỗ điền dài bằng dấu mở cộng một chữ số.
constexpr std::size_t kSlotChars = kSlotMark.size() + 1;

// Số của chỗ điền ở đầu rest; nullopt khi rest không mở đầu bằng "%s" rồi một chữ số.
[[nodiscard]] std::optional<std::size_t> slot_at(std::string_view rest) noexcept {
    if (!rest.starts_with(kSlotMark) || rest.size() < kSlotChars) return std::nullopt;
    const char digit = rest[kSlotMark.size()];
    if (digit < '0' || digit > '9') return std::nullopt;
    return static_cast<std::size_t>(digit - '0');
}

// Chép đoạn đầu của mẫu vào out rồi trả phần còn lại: chỗ điền thành đối số của nó, chữ thường thì
// chép tới chỗ có thể là chỗ điền kế tiếp.
[[nodiscard]] std::string_view copy_piece(std::string& out, std::string_view rest, Slots slots) {
    const std::optional<std::size_t> slot = slot_at(rest);
    if (slot) {
        const bool is_given = *slot < slots.size();
        out.append(is_given ? slots[*slot] : std::string_view{});
        return rest.substr(kSlotChars);
    }
    const std::size_t next = rest.find(kSlotMark, 1);
    out.append(rest.substr(0, next));
    return next == std::string_view::npos ? std::string_view{} : rest.substr(next);
}

// Mẫu của tag "#{khoá}" trong bảng; nullopt khi tag không đúng dạng hay bảng không có khoá.
[[nodiscard]] std::optional<std::string_view> pattern_of(const gui::StringBook& book, std::string_view tag) noexcept {
    const bool is_tag = tag.starts_with(kTagOpen) && tag.ends_with(kTagClose);
    if (!is_tag || tag.size() < kTagOpen.size() + kTagClose.size()) return std::nullopt;
    tag.remove_prefix(kTagOpen.size());
    tag.remove_suffix(kTagClose.size());
    return book.find(tag);
}

} // namespace

void format_pattern(std::string& out, std::string_view pattern, Slots slots) {
    std::string_view rest = pattern;
    while (!rest.empty()) {
        rest = copy_piece(out, rest, slots);
    }
}

void format_key(std::string& out, const gui::StringBook& book, std::string_view tag, Slots slots) {
    const std::optional<std::string_view> pattern = pattern_of(book, tag);
    if (!pattern) return;
    format_pattern(out, *pattern, slots);
}

} // namespace game::ui::panel

