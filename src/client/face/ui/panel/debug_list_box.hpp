// Danh sách lời nhắn gỡ lỗi (DebugListBox): dải chữ ở đầu màn hình (cao 20%, từ 8% chiều cao) mà game đẩy lời nhắn vào
// bằng PushDebugMessage (sự kiện NEW_DEBUGMESSAGE); mỗi lời hiện vài giây rồi mờ dần và biến mất.
// Nguồn: Interface/DebugListBox/DebugListBox.lua của client 2026. Port 5/5 hàm:
// DebugListBox_PreLoad là kDebugListBoxEvents; DebugListBox_OnLoad và DebugListBox_OnShown có thân rỗng (toàn chú
// thích) nên không có hàm C++; DebugListBox_OnEvent là debug_list_box_event; DebugListBox_Update là
// debug_list_box_update.
// Test/golden/panel/debug_list_box_flow.tsv (TOOLS/port/oracle/debug_list_box_flow.lua) là trạng thái mà script gốc để
// lại khi chạy trên LuaPlus.dll của client D:\XTLBB 3.71.9509.
// Danh sách là TLBB_InfoList (FalagardInfoList của CEGUIFalagard.dll, lớp con của Listbox): AddInfo 0x18006b940 thêm một
// mục mang tuổi thọ Life và tốc độ mờ FadeSpeed, NormalizeItemNumber 0x18006ba00 bỏ mục cũ nhất khi quá 5 mục
// (mặc định ở 0x18006b676), updateSelf 0x18006bd60 trừ tuổi thọ, hết tuổi thì giảm độ trong và bỏ mục khi độ trong âm.
// Life 5000 và FadeSpeed 128 là giá trị của DebugListBox.layout.xml.
// Khác gốc: gui::Hub vẽ InfoList như SimpleText (docs/NGHI-NGO.md mục 18 và (f) của mục về InfoList), nên các mục vẽ
// thành một khối chữ, mỗi mục một dòng, đủ độ đục tới lúc bị bỏ (chưa có độ trong của từng mục); DataPool:GetUIColor
// và DataPool:Check_StringCode xem ui/panel/data_pool.hpp (kiểm theo UTF-8). Chữ dài hơn 400 byte bị cắt như script
// (399 byte khi 400 byte đầu kết thúc giữa một ký tự), rồi lùi tiếp tới đầu ký tự UTF-8 vì ký tự UTF-8 dài tới bốn byte
// mà script chỉ lùi một byte (ký tự GBK dài hai byte): dãy bị chẻ không bao giờ tới màn hình. DebugListBox_Update khi
// arg0 là nil: script gọi Show rồi lỗi ở string.len, bản này cũng chỉ hiện bảng.
#pragma once

#include "ui/panel/data_pool.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

inline constexpr std::string_view kDebugListBoxLayout = "DebugListBox/DebugListBox.layout.xml";
// Cửa sổ gốc của layout, cũng là `this` của script.
inline constexpr std::string_view kDebugListBoxRoot = "DebugListBox";
inline constexpr std::string_view kDebugListBoxList = "DebugListBox_ListBox";

// DebugListBox_PreLoad: các this:RegisterEvent theo thứ tự đăng ký (cả hai nhận cả lúc bảng đang ẩn).
inline constexpr std::array<EventSub, 2> kDebugListBoxEvents = {{
    {.name = "APPLICATION_INITED", .is_always = true},
    {.name = "NEW_DEBUGMESSAGE", .is_always = true},
}};

// Một mục của InfoList (ListboxTextItem của FalagardInfoList): chữ, tuổi thọ còn lại (ms, âm là đang mờ), tốc độ mờ
// và độ trong 1..0.
struct InfoLine {
    std::string text;
    std::int32_t life_ms = 0;
    std::int32_t fade_speed = 0;
    float alpha = 1.0F;
};

// Trạng thái của bảng: this:IsVisible() và các mục của danh sách (Widgets giữ bản chữ của chúng cho số vàng).
struct DebugListBox {
    Widgets widgets;
    bool is_shown = false;
    std::vector<InfoLine> lines;
};

// DebugListBox_OnEvent; colour là kết quả của DataPool:GetUIColor(1000) lúc sự kiện tới.
void debug_list_box_event(DebugListBox& panel, const UiEvent& event, UiColour colour);
// DebugListBox_Update(arg0): hiện bảng rồi thêm một mục "#c<màu chữ>#e<màu viền><arg0>".
void debug_list_box_update(DebugListBox& panel, std::optional<std::string_view> arg0, UiColour colour);
// Một nhịp updateSelf của danh sách trong seconds giây.
void debug_list_box_tick(DebugListBox& panel, float seconds);
// Hiện gốc, chép trạng thái và các mục (mỗi mục một dòng của thuộc tính Text của danh sách) khi bảng đang hiện.
void paint_debug_list_box(Deck& deck, const DebugListBox& panel);

} // namespace game::ui::panel
