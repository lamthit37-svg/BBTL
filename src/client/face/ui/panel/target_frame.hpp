/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/target_frame.hpp
 *  PHÂN HỆ   : Face / Ui / Panel / Target frame
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Khung mục tiêu (TargetFrame): tên, cấp, thanh máu của thực thể đang chọn.
 *    Không có mục tiêu thì giấu cả khung. Nguồn: TargetFrame.lua 2026,
 *    TargetFrame_Update_Name, TargetFrame_Update_Level, TargetFrame_Update_HP
 *    nhánh không phải boss.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ui/panel/deck.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::panel {

// Một mục tiêu đang chọn, đã tra tên. hp là phần đầy 0..1. player_level là cấp người chơi để tô màu cấp.
struct Target {
    std::string_view name;
    std::uint16_t level = 1;
    std::int32_t player_level = 1;
    float hp = 1.0F;
    // Quái: chữ tên đỏ. NPC, trân thú và người chơi: chữ trắng (RELATIVE thân thiện của script).
    bool is_hostile = true;
};

// Ghi chỉ thị của khung. mark rỗng thì giấu TargetFrame. Chuỗi mượn phải sống tới hết khung.
void fill_target(Deck& deck, const std::optional<Target>& mark);

} // namespace game::ui::panel
