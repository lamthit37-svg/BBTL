/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/skill_bar.cpp
 *  PHÂN HỆ   : Ui / Panel / SkillBar
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Xem skill_bar.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/skill_bar.hpp"

#include "core/number.hpp"
#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/npc_talk.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";
// Một dòng dài hơn thế là tệp hỏng, bỏ dòng chứ không cắt giữa ô.
constexpr std::size_t kLineCap = 65536;

constexpr std::array<std::string_view, kSkillBarSlots> kButtons = {
    "Button_Action1",
    "Button_Action2",
    "Button_Action3",
    "Button_Action4",
    "Button_Action5",
    "Button_Action6",
    "Button_Action7",
    "Button_Action8",
    "Button_Action9",
    "Button_Action10",
};

struct Columns {
    std::size_t id = std::string_view::npos;
    std::size_t name = std::string_view::npos;
    std::size_t icon = std::string_view::npos;
};

[[nodiscard]] std::vector<std::string_view> split_fields(std::string_view line) {
    std::vector<std::string_view> fields;
    while (!line.empty()) {
        const std::size_t tab = line.find('\t');
        if (tab == std::string_view::npos) {
            fields.push_back(line);
            break;
        }
        fields.push_back(line.substr(0, tab));
        line.remove_prefix(tab + 1);
    }
    return fields;
}

[[nodiscard]] std::size_t column_at(const std::vector<std::string_view>& fields, std::string_view name) {
    const auto found = std::ranges::find(fields, name);
    if (found == fields.end()) return std::string_view::npos;
    return static_cast<std::size_t>(found - fields.begin());
}

[[nodiscard]] std::string_view field_at(const std::vector<std::string_view>& fields, std::size_t column) {
    if (column == std::string_view::npos || column >= fields.size()) return {};
    return fields[column];
}

void put_text(Deck& deck, std::string_view window, std::string_view name, std::string_view value) {
    deck.set(gui::Override{.window = window, .name = name, .value = value});
}

void paint_empty(Deck& deck, std::string_view window) {
    put_text(deck, window, "Empty", kTrue);
    put_text(deck, window, "NormalImage", {});
    put_text(deck, window, "Gloom", kFalse);
    put_text(deck, window, "Tooltip", {});
}

void paint_held(Deck& deck, std::string_view window, std::uint32_t skill, bool cooling, const SkillBook& book,
    const ItemNames& icons) {
    put_text(deck, window, "Empty", kFalse);
    put_text(deck, window, "NormalImage", book.face(skill, icons));
    put_text(deck, window, "Gloom", cooling ? kTrue : kFalse);
    const auto largest = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    const std::string_view tooltip = skill <= largest ? book.name(static_cast<std::int32_t>(skill)) : std::string_view{};
    put_text(deck, window, "Tooltip", tooltip);
}

// span của MSVC 14.51 chưa có at(); đã kiểm biên trước khi lấy phần tử.
[[nodiscard]] bool is_cooling(std::span<const std::uint32_t> left_ms, std::size_t slot) noexcept {
    if (slot >= left_ms.size()) return false;
    return left_ms[slot] > 0;
}

void paint_slot(Deck& deck, std::size_t slot, std::span<const std::uint32_t> skills, std::span<const std::uint32_t> left_ms,
    const SkillBook& book, const ItemNames& icons) {
    const std::string_view window = kButtons.at(slot);
    if (slot >= skills.size()) {
        paint_empty(deck, window);
        return;
    }
    paint_held(deck, window, skills[slot], is_cooling(left_ms, slot), book, icons);
}

} // namespace

bool SkillBook::load(std::string_view text) {
    rows_.clear();
    is_loaded_ = false;
    Columns columns;
    bool has_header = false;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        if (line.size() > kLineCap) continue;
        const std::vector<std::string_view> fields = split_fields(line);
        if (!has_header) {
            columns.id = column_at(fields, "id");
            columns.name = column_at(fields, "name");
            columns.icon = column_at(fields, "icon");
            if (columns.id == std::string_view::npos || columns.name == std::string_view::npos) return false;
            has_header = true;
            continue;
        }
        if (rows_.size() >= kSkillBookRows) break;
        if (fields.size() <= columns.id || fields.size() <= columns.name) continue;
        const std::optional<int> id = core::parse_whole_int(field_at(fields, columns.id));
        if (!id || rows_.contains(*id)) continue;
        rows_.emplace(*id, Entry{.name = std::string(field_at(fields, columns.name)), .icon = std::string(field_at(fields, columns.icon))});
    }
    is_loaded_ = has_header;
    return has_header;
}

std::string_view SkillBook::name(std::int32_t skill) const noexcept {
    const auto found = rows_.find(skill);
    return found == rows_.end() ? std::string_view{} : std::string_view(found->second.name);
}

std::string_view SkillBook::icon(std::int32_t skill) const noexcept {
    const auto found = rows_.find(skill);
    return found == rows_.end() ? std::string_view{} : std::string_view(found->second.icon);
}

std::string SkillBook::face(std::uint32_t skill, const ItemNames& icons) const {
    const auto largest = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    if (skill > largest) return icons.image({});
    return icons.image(icon(static_cast<std::int32_t>(skill)));
}

std::optional<std::uint32_t> skill_slot_of(std::string_view window) noexcept {
    const auto found = std::ranges::find(kButtons, window);
    if (found == kButtons.end()) return std::nullopt;
    return static_cast<std::uint32_t>(found - kButtons.begin());
}

void paint_skill_bar(Deck& deck, std::span<const std::uint32_t> skills, std::span<const std::uint32_t> left_ms,
    const SkillBook& book, const ItemNames& icons) {
    for (std::size_t slot = 0; slot < kButtons.size(); ++slot)
        paint_slot(deck, slot, skills, left_ms, book, icons);
}

} // namespace game::ui::panel
