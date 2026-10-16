/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/target_frame.cpp
 *  PHÂN HỆ   : Face / Ui / Panel / Target frame
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Điền TargetFrame theo script 2026 cho mục tiêu thường (không phải boss ba
 *    thanh). Khác gốc: không có khí, nộ, môn phái, loại NPC hay chân dung trên
 *    dây, nên các ô đó bị giấu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/target_frame.hpp"

#include "gui/sheet.hpp"

#include <algorithm>
#include <array>
#include <format>
#include <iterator>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kHostile = "#R";
constexpr std::string_view kFriendly = "#W";
constexpr std::string_view kOrange = "#cff9000";
constexpr std::string_view kYellow = "#Y";

constexpr std::array<std::string_view, 7> kHidden = {
    "TargetFrame_DataBack2",
    "TargetFrame_GQ",
    "TargetFrame_HPHDSandBoxHPBK",
    "TargetFrame_MP",
    "TargetFrame_SP",
    "TargetFrame_CampFrame",
    "TargetFrame_TypeIcon",
};

// TargetFrame_Update_Level: chênh cấp mục tiêu trừ cấp mình.
std::string_view level_ink(int gap) noexcept {
    if (gap > 5) return kHostile;
    if (gap > 2) return kOrange;
    if (gap >= -2) return kYellow;
    return kFriendly;
}

void fill_shown(Deck& deck, const Target& mark) {
    deck.show("TargetFrame");
    deck.reveal("TargetFrame_DataBack");
    for (const std::string_view window : kHidden) deck.hide(window);
    const std::string_view name_ink = mark.is_hostile ? kHostile : kFriendly;
    std::string& name = deck.compose(Key{.window = "TargetFrame_Name", .name = "Text"});
    name.append(name_ink).append(mark.name);
    const int gap = static_cast<int>(mark.level) - mark.player_level;
    std::string& level = deck.compose(Key{.window = "TargetFrame_LevelText", .name = "Text"});
    level.append(level_ink(gap));
    if (mark.level >= 200) {
        level.push_back('?');
    } else {
        std::format_to(std::back_inserter(level), "{}", mark.level);
    }
    const float hp = std::clamp(mark.hp, 0.0F, 1.0F);
    deck.bar("TargetFrame_HP", hp);
}

} // namespace

void fill_target(Deck& deck, const std::optional<Target>& mark) {
    if (!mark) {
        deck.hide("TargetFrame");
        return;
    }
    fill_shown(deck, *mark);
}

} // namespace game::ui::panel
