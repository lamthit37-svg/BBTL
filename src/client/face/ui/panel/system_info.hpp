// Hộp thông báo của thủ tục đăng nhập (SelectServerQuest, layout
// SelectServerQuest/SelectServerQuest.layout.xml): một khung có dòng chữ và nút "đóng". Client gốc
// mở nó bằng sự kiện GAMELOGIN_SHOW_SYSTEM_INFO kèm chữ (lời báo lỗi đăng nhập, "phải chọn một máy
// chủ", ...). Bản ở đây chỉ có kiểu thông báo thường: một nút đóng, không có hai nút có / không,
// đếm ngược, nút đổi máy chủ hay nút quên mật khẩu. Nguồn:
// Interface/SelectServerQuest/SelectServerQuest.lua của client 2026, giải bằng
// TOOLS/content/lua_plain.py (LoginSelectServerQuest_OnEvent 129, LoginSelectUpdateRect 119,
// SelectServerQuest_Bn1Click 2776) và mã máy CEGUIFalagard.dll
// (FalagardSelfFitWindow::getRenderSize 0x18009c100; mặc định MaxWidth 200 ở 0x18009af60, layout
// đặt 326 và MinHeight 25). Cỡ ô chữ theo getRenderSize (gốc gọi GetWindowSize sau khi
// SelfFitWindow tự co): khối chữ cộng lề 3 điểm hai bên, cộng thêm 5 (rộng, không quá 326) hay 2
// (cao, không dưới 25); hằng 5,0 và 2,0 ở 0x18013c5f0 và 0x18012fb5c, đọc bằng Ghidra 2026-10-18
// (ui/script/widget.cpp ghi đủ thứ tự áp). Khác gốc: khối chữ đo bằng bộ viết chữ của HUD; chưa có
// nháy mờ dần.
#pragma once

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <string>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kSystemInfoLayout = "SelectServerQuest/SelectServerQuest.layout.xml";
// Nút đóng của hộp (SelectServerQuest_Button1).
inline constexpr std::string_view kSystemInfoClose = "SelectServerQuest_Button1";

struct SystemInfo {
    bool is_open = false;
    // Chữ của hộp, viết như script gọi: có thể là thẻ "#{khoá}" hay chữ kèm thẻ màu.
    std::string text;
};

// Mở hộp với chữ text (GAMELOGIN_SHOW_SYSTEM_INFO). Hộp đang mở thì đổi chữ.
void show_system_info(SystemInfo& info, std::string_view text);
// Một lần nhấn trái lên cửa sổ window: nút đóng thì đóng hộp (SelectServerQuest_Bn1Click khi g_iYesNoType
// là -1). Cửa sổ khác không đổi gì.
void press_system_info(SystemInfo& info, std::string_view window) noexcept;
// Ghi chỉ thị của hộp cho khung này (không làm gì khi đóng). meter đo khối chữ để co hộp; nullptr thì
// hộp dùng cỡ nhỏ nhất.
void paint_system_info(Deck& deck, const SystemInfo& info, const gui::TextMeter* meter);

} // namespace game::ui::panel
