// Bảng chọn nhân vật (xem select_role.hpp).
#include "ui/panel/select_role.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/sect.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "SelectRole_Frame";
constexpr std::string_view kInfo = "SelectRole_Info";
constexpr std::string_view kPlay = "SelectRole_Play";
constexpr std::string_view kCreate = "SelectRole_Create";
constexpr std::string_view kDelete = "SelectRole_Delete";
constexpr std::string_view kBack = "SelectRole_Last";
constexpr std::string_view kCreateHint = "#{DLJM_XML_22}";
constexpr std::string_view kNoneChosen = "#{produce_char_sel_Info_Please_Sel_Role}";
constexpr std::string_view kDeleteAsk = "#{{CHAR_SEL_DELETE_HEAD}}{} #c00ff00{}#cffffff#{{CHAR_SEL_DELETE_TAIL}}";
constexpr std::string_view kSectLine = "#c00ff00#{{INTERFACE_XML_1143}}#cffffff {}";
constexpr std::string_view kLevelLine = "#c00ff00#{{INTERFACE_XML_1144}}#cffffff {}";

// Ô nhân vật: nút chọn, tên, môn phái, cấp, lời tạo, ảnh, viền, dòng bán và dòng xoá trễ.
struct SlotView {
    std::string_view button;
    std::string_view name;
    std::string_view sect;
    std::string_view level;
    std::string_view create;
    std::string_view icon;
    std::string_view highlight;
    std::string_view sell;
    std::string_view pending;
};

constexpr std::array<SlotView, kRoleCap> kSlots{{
    {.button = "SelectRole_TargetInfo_Button1",
        .name = "SelectRole_TargetInfo_Name_Text",
        .sect = "SelectRole_TargetInfo_Menpai_Text",
        .level = "SelectRole_TargetInfo_Level_Text",
        .create = "SelectRole_TargetInfo_Create",
        .icon = "SelectRole_Icon",
        .highlight = "SelectRole_TargetInfo_Gaoliang1",
        .sell = "SelectRole_TargetInfo_Sell",
        .pending = "SelectRole_TargetInfo_Delete"},
    {.button = "SelectRole_TargetInfo_Button2",
        .name = "SelectRole_TargetInfo_Name_Text2",
        .sect = "SelectRole_TargetInfo_Menpai_Text2",
        .level = "SelectRole_TargetInfo_Level_Text2",
        .create = "SelectRole_TargetInfo_Create2",
        .icon = "SelectRole_Icon2",
        .highlight = "SelectRole_TargetInfo_Gaoliang2",
        .sell = "SelectRole_TargetInfo_Sell2",
        .pending = "SelectRole_TargetInfo_Delete2"},
    {.button = "SelectRole_TargetInfo_Button3",
        .name = "SelectRole_TargetInfo_Name_Text3",
        .sect = "SelectRole_TargetInfo_Menpai_Text3",
        .level = "SelectRole_TargetInfo_Level_Text3",
        .create = "SelectRole_TargetInfo_Create3",
        .icon = "SelectRole_Icon3",
        .highlight = "SelectRole_TargetInfo_Gaoliang3",
        .sell = "SelectRole_TargetInfo_Sell3",
        .pending = "SelectRole_TargetInfo_Delete3"},
}};

void put(Deck& deck, std::string_view window, std::string_view name, std::string_view value) {
    deck.set(gui::Override{.window = window, .name = name, .value = value});
}

void put_text(Deck& deck, std::string_view window, std::string_view value) {
    put(deck, window, "Text", value);
}

[[nodiscard]] const Role* role_at(const SelectRole& select, std::uint8_t index) noexcept {
    if (index >= select.count) return nullptr;
    const auto at = static_cast<std::ptrdiff_t>(index);
    return &*std::next(select.roles.begin(), at);
}

[[nodiscard]] std::optional<std::uint8_t> slot_of(std::string_view window) noexcept {
    constexpr std::string_view kPrefix = "SelectRole_TargetInfo_Button";
    if (!window.starts_with(kPrefix) || window.size() != kPrefix.size() + 1) return std::nullopt;
    const char digit = window.back();
    if (digit < '1' || digit > '3') return std::nullopt;
    return static_cast<std::uint8_t>(digit - '1');
}

[[nodiscard]] std::string delete_question(const Role& role) {
    std::string text;
    std::format_to(std::back_inserter(text), kDeleteAsk, role.level, role.name);
    return text;
}

void press_delete(SelectRole& select) {
    const Role* role = chosen_role(select);
    if (role == nullptr) {
        select.info = std::string(kNoneChosen);
        return;
    }
    if (!select.confirming) {
        select.confirming = true;
        select.info = delete_question(*role);
        return;
    }
    select.confirming = false;
    select.info.clear();
    select.request = SelectAction::kDelete;
}

void press_slot(SelectRole& select, std::uint8_t index) {
    if (index >= select.count) {
        select.request = SelectAction::kCreate;
        return;
    }
    const bool again = select.was_clicked && select.selected == index;
    select.selected = index;
    select.was_clicked = true;
    if (again) select.request = SelectAction::kEnter;
}

void press_play(SelectRole& select) {
    if (chosen_role(select) == nullptr) {
        select.info = std::string(kNoneChosen);
        return;
    }
    select.request = SelectAction::kEnter;
}

void press_create_button(SelectRole& select) {
    if (select.count >= kRoleCap) {
        select.info = std::string(name_fault_text(NameFault::kFull));
        return;
    }
    select.request = SelectAction::kCreate;
}

void route_select(SelectRole& select, std::string_view window) {
    const std::optional<std::uint8_t> slot = slot_of(window);
    if (slot) press_slot(select, *slot);
    if (window == kPlay) press_play(select);
    if (window == kCreate) press_create_button(select);
    if (window == kBack) select.request = SelectAction::kBack;
}

void paint_empty(Deck& deck, const SlotView& slot) {
    deck.hide(slot.highlight);
    deck.hide(slot.sell);
    deck.hide(slot.pending);
    put_text(deck, slot.name, {});
    put_text(deck, slot.sect, {});
    put_text(deck, slot.level, {});
    put_text(deck, slot.create, kCreateHint);
    put(deck, slot.icon, "Image", {});
}

void paint_filled(Deck& deck, const SlotView& slot, const Role& role, bool is_chosen) {
    deck.hide(slot.create);
    deck.hide(slot.sell);
    deck.hide(slot.pending);
    if (is_chosen) deck.reveal(slot.highlight);
    if (!is_chosen) deck.hide(slot.highlight);
    put_text(deck, slot.name, role.name);
    std::string& sect = deck.compose(Key{.window = slot.sect, .name = "Text"});
    std::format_to(std::back_inserter(sect), kSectLine, sect_name(role.sect));
    std::string& level = deck.compose(Key{.window = slot.level, .name = "Text"});
    std::format_to(std::back_inserter(level), kLevelLine, role.level);
    put(deck, slot.icon, "Image", role.icon);
}

void paint_slot(Deck& deck, const SelectRole& select, std::uint8_t index) {
    const SlotView& slot = *std::next(kSlots.begin(), static_cast<std::ptrdiff_t>(index));
    const Role* role = role_at(select, index);
    if (role == nullptr) paint_empty(deck, slot);
    if (role != nullptr) paint_filled(deck, slot, *role, select.selected == index);
}

void copy_role(SelectRole& select, const Roster& roster, std::uint8_t index) {
    const auto at = static_cast<std::ptrdiff_t>(index);
    *std::next(select.roles.begin(), at) = *std::next(roster.roles.begin(), at);
}

} // namespace

void open_select(SelectRole& select, const Roster& roster, std::uint8_t selected) {
    select = {};
    select.count = roster.count;
    for (std::uint8_t index = 0; index < roster.count; ++index)
        copy_role(select, roster, index);
    if (select.count == 0) return;
    const auto last = static_cast<std::uint8_t>(select.count - 1);
    select.selected = selected < select.count ? selected : last;
}

void press_select(SelectRole& select, std::string_view window) {
    if (window == kDelete) {
        press_delete(select);
        return;
    }
    if (select.confirming) {
        select.confirming = false;
        select.info.clear();
        return;
    }
    route_select(select, window);
}

std::optional<SelectAction> take_select(SelectRole& select) noexcept {
    const std::optional<SelectAction> action = select.request;
    select.request.reset();
    return action;
}

const Role* chosen_role(const SelectRole& select) noexcept {
    return role_at(select, select.selected);
}

namespace {

// Script gốc không gọi Disable. Mở bảng mà còn cờ Disabled thì nút vẽ lớp xám.
void clear_disabled(Deck& deck, std::string_view window) {
    put(deck, window, "Disabled", "False");
}

} // namespace

void paint_select(Deck& deck, const SelectRole& select) {
    deck.show(kRoot);
    clear_disabled(deck, kPlay);
    clear_disabled(deck, kCreate);
    clear_disabled(deck, kDelete);
    clear_disabled(deck, kBack);
    for (std::uint8_t index = 0; index < kRoleCap; ++index) {
        const SlotView& slot = *std::next(kSlots.begin(), static_cast<std::ptrdiff_t>(index));
        clear_disabled(deck, slot.button);
        paint_slot(deck, select, index);
    }
    put_text(deck, kInfo, select.info);
}

} // namespace game::ui::panel
