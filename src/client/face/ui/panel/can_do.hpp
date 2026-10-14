// DataPool:IsCanDoAction() của client 2026 (Game.exe 0x1402e7d70): người chơi làm được một hành động từ
// thanh phím tắt hay không. Mã gốc hỏi IsWindowShow (ô ảo 0xc0 của hệ giao diện, cùng hàm với script
// IsWindowShow 0x140237f50) lần lượt tám cửa sổ giao dịch; cửa sổ nào đang hiện thì trả false, tất cả đều
// ẩn thì true. Hệ giao diện không có (con trỏ null) cũng trả true.
// Tên đọc từ chuỗi của Game.exe: "PS_ShopMag", "StallSale", "MissionReply", "Bank" (0x140b49460),
// "BigBank", "Exchange", "Shop" (0x140b4952c), "CityShop".
#pragma once

#include <array>
#include <concepts>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::array<std::string_view, 8> kActionBlockers = {
    "PS_ShopMag", "StallSale", "MissionReply", "Bank", "BigBank", "Exchange", "Shop", "CityShop"};

// is_shown(tên cửa sổ) là IsWindowShow của game.
template <std::predicate<std::string_view> Shown>
[[nodiscard]] constexpr bool can_do_action(const Shown& is_shown) {
    for (const std::string_view window : kActionBlockers) {
        if (is_shown(window)) return false;
    }
    return true;
}

} // namespace game::ui::panel
