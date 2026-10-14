// Thanh tiến trình (ProgressBar): một thanh SuperProgress ở giữa màn hình (79,5% chiều cao) mang một
// dòng chữ; game hiện nó lúc một việc có thời gian (luyện công, thu thập), đẩy mức đã làm, rồi cho
// nó mờ dần khi xong hay bị ngắt.
// Nguồn: Interface/ProgressBar/ProgressBar.lua của client 2026. Port 6/6 hàm:
// ProgressBar_PreLoad là kProgressBarEvents; ProgressBar_OnLoad có thân rỗng nên không có hàm C++;
// ProgressBar_OnEvent là progress_bar_event; ProgressBar_SetWidth là progress_bar_set_width;
// Progress_Break là progress_bar_break; Progress_close là progress_bar_close.
// Test/golden/panel/progress_bar_flow.tsv (TOOLS/port/oracle/progress_bar_flow.lua) là trạng thái mà
// script gốc để lại khi chạy trên LuaPlus.dll của client 2026.
// Phần mờ dần không nằm trong script mà trong FalagardSuperProgress của CEGUIFalagard.dll, nên đọc từ
// mã máy: thuộc tính SetFadeState (0x180079f20) với giá trị dương bật mờ dần trong chừng ấy giây, giá trị
// không dương hiện lại cửa sổ; cả hai đặt độ trong về 1. Mỗi nhịp updateSelf (0x18007a760) trừ thời gian
// khỏi phần còn lại, đặt độ trong bằng còn lại chia tổng, và khi còn lại xuống dưới 0 thì giấu cửa sổ.
// Khác gốc: bộ dàn trang (gui::Hub) không có độ trong của từng cửa sổ, nên thanh hiện đủ độ đục tới lúc
// hết thời gian rồi biến mất; gui::draw_progress mới vẽ dải mức mà chưa vẽ khung nền, đầu sáng và chữ của
// FalagardSuperProgress (docs/NGHI-NGO.md mục 18), nên chữ do PROGRESSBAR_SHOW đặt đã nằm trong bảng nhưng
// chưa hiện lên màn hình; PROGRESSBAR_SHOW khi chưa sự kiện nào đặt arg0 thì giữ chữ cũ (script gọi
// SetText(nil), chưa đo UI_CEGUI.dll làm gì với nil); ProgressBar_SetWidth với arg0 không phải số bị bỏ như
// lỗi của script.
#pragma once

#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <optional>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kProgressBarLayout = "ProgressBar/ProgressBar.layout.xml";
// Cửa sổ gốc của layout, cũng là `this` của script.
inline constexpr std::string_view kProgressBarRoot = "ProgressBar_Progress";

// ProgressBar_PreLoad: các this:RegisterEvent theo thứ tự đăng ký.
inline constexpr std::array<EventSub, 6> kProgressBarEvents = {{
    {.name = "PROGRESSBAR_SHOW", .is_always = true},
    {.name = "PROGRESSBAR_HIDE", .is_always = false},
    {.name = "PROGRESSBAR_WIDTH", .is_always = false},
    {.name = "PLAYER_LEAVE_WORLD", .is_always = false},
    {.name = "PROGRESSBAR_BREAK", .is_always = false},
    {.name = "HIDE_ON_SCENE_TRANSED", .is_always = false},
}};

// Trạng thái của bảng: this:IsVisible() và phần mờ dần của thanh.
struct ProgressBar {
    Widgets widgets;
    bool is_shown = false;
    // Đang mờ dần (cờ +0x94c của FalagardSuperProgress), tổng và phần còn lại tính bằng giây.
    bool is_fading = false;
    float fade_total = 0.0F;
    float fade_left = 0.0F;
};

// ProgressBar_OnEvent.
void progress_bar_event(ProgressBar& panel, const UiEvent& event);
// ProgressBar_SetWidth(arg0): mức thanh là tonumber(arg0) nhân 100 trên 100.
void progress_bar_set_width(ProgressBar& panel, std::optional<std::string_view> arg0);
// Progress_Break: cho thanh mờ dần trong 2 giây.
void progress_bar_break(ProgressBar& panel);
// Progress_close: giấu bảng.
void progress_bar_close(ProgressBar& panel) noexcept;
// Một nhịp updateSelf của thanh trong seconds giây (phần mờ dần).
void progress_bar_fade(ProgressBar& panel, float seconds);
// Hiện gốc và chép trạng thái khi bảng đang hiện.
void paint_progress_bar(Deck& deck, const ProgressBar& panel);

} // namespace game::ui::panel
