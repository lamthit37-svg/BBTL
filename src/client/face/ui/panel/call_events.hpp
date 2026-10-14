// Việc nhờ game của một bảng (Call) mà thực chất là đẩy một sự kiện giao diện cho các bảng khác: PushEvent của script, và
// hai hàm DataPool của chuỗi gỡ gói hành động chat (UnInstall_RMB_ChatAction cấp 0..5, Clear_ChatAction_Bar) mà Game.exe
// cài bằng cách đẩy sự kiện UI theo id (0x325..0x328, 0x38c, 0x38d, 0x329; tên ở bảng đăng ký của Game.exe 0x140a272b0).
// Cùng với EventQueue: hàng đợi sự kiện của một khung, theo CEventSystem của Game.exe (đo ngày 2026-10-15):
//  - PushEvent (Lua, 0x140255060 -> 0x1401fce10) và hai hàm DataPool (0x1402f30d0 -> vtable[28] của CEventSystem 0x1401feb70)
//    đều kết ở 0x140205950, hàm này không gọi bộ xử lý nào mà chỉ thêm sự kiện vào danh sách chờ của CEventSystem:
//    +0x48 khi cờ trễ của sự kiện (Ev+0x10) là 0, +0x58 khi khác 0.
//  - CEventSystem::Tick (0x140205430) duyệt danh sách +0x48 từ đầu tới hết, gồm cả nút do bộ xử lý thêm vào trong lúc duyệt
//    (std::list: nút mới chèn trước nút gác nên duyệt tới nó), nên sự kiện do bảng đẩy tới các bảng sau sự kiện đang xử lý
//    xong, ngay trong cùng khung, theo thứ tự đẩy. Mỗi nút gọi 0x140205c70: gọi mọi bộ xử lý đã đăng ký của sự kiện đó,
//    đồng bộ. Nút bị bỏ nếu một nút đứng trước nó trong danh sách cùng sự kiện và cùng mọi đối số (0x140207180), trừ id 0x85
//    NEW_DEBUGMESSAGE; xong thì xoá cả danh sách.
//  - Danh sách +0x58 (cờ trễ khác 0: 71 sự kiện UNIT_* và 9 sự kiện khác như UPDATE_QUICK, VARIABLE_CHANGED) mỗi Tick chỉ
//    xử lý một nút, cách nhau trên một mili giây. Khác gốc: chưa mô hình; không sự kiện nào của nhóm thanh action ở đó
//    (cờ 0: CHANGE_BAR, ACTION_UPDATE, FLASH_COMBOSKILL, HIDE_THIS_UI, PLAYER_ENTERING_WORLD, SHOW_TRANSFIGURATION_SKILL,
//    OPEN_*_BAR_2, OPEN_MENUBAR_2, SWITCH_MENU_BUTTON, UI_COMMAND, CLEAR_CHAT_ACTION_BAR, các UNINSTALL_*).
// Khác gốc: gốc không đặt trần số sự kiện của một Tick; EventQueue có trần do người dùng đặt, để một chuỗi sự kiện đẩy nhau
// mãi (mỗi lần một đối số mới, vì sự kiện giống hệt thì đã bị bỏ) không giữ khung vô hạn.
// Thuần logic, không đụng GPU.
#pragma once

#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::ui::panel {

// (int) của game lên số thực của Lua: cắt phần thập phân, ép về miền int32 (NaN thành 0) thay vì tràn.
[[nodiscard]] std::int32_t game_int(double value) noexcept;

// Sự kiện mà call đẩy; nullopt khi call không phải việc đẩy sự kiện (DoAction, PushDebugMessage...), khi tên sự kiện rỗng,
// hay khi UnInstall_RMB_ChatAction có cấp ngoài 0..5 (cấp 6 gửi gói tin xoá, không đẩy sự kiện).
[[nodiscard]] std::optional<PostedEvent> event_of(const Call& call);

// Hàng đợi sự kiện của một khung (một lượt CEventSystem::Tick, danh sách +0x48). Dựng từ các sự kiện game phát kể từ khung
// trước; bảng nào đẩy sự kiện thì push, sự kiện tới sau các sự kiện đang chờ. next() bỏ nút lặp như Tick.
class EventQueue {
public:
    // limit là trần số nút (kể cả nút lặp bị bỏ) mà một khung được xử lý.
    EventQueue(std::span<const PostedEvent> first, std::size_t limit);

    // Sự kiện kế tiếp cần gửi cho các bảng; nullopt khi hết hàng đợi hay chạm trần. Trả bản sao: push có thể cấp lại bộ nhớ.
    [[nodiscard]] std::optional<PostedEvent> next();

    // Thêm một sự kiện vào cuối hàng đợi (PushEvent của script, hay hàm DataPool đẩy sự kiện).
    void push(PostedEvent event);

private:
    std::vector<PostedEvent> events_;
    std::size_t at_ = 0;
    std::size_t limit_;
};

} // namespace game::ui::panel
