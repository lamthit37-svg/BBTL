/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/relive.hpp
 *  PHÂN HỆ   : Face / Ui / Panel / Relive
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cửa sổ hồi sinh (Relive) khi người chơi đã chết. Nguồn: Relive.lua 2026,
 *    nhánh Event_Relive thường. Hai nút khớp hai chỗ của tin Respawn.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ui/panel/deck.hpp"
#include "ui/panel/talk.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::panel {

// Số mất khi chết. Có khi máy chủ đã gửi DeathNotice.
struct DeathLoss {
    std::uint64_t exp = 0;
    std::uint64_t money = 0;
};

// Hiện cửa sổ khi is_dead. loss rỗng thì không ghi dòng phạt.
void fill_relive(Deck& deck, bool is_dead, const std::optional<DeathLoss>& loss);

// Nút hồi thành hay tại chỗ. Rỗng khi không phải nút của cửa sổ này.
[[nodiscard]] std::optional<talk::Place> relive_place(std::string_view window) noexcept;

} // namespace game::ui::panel
