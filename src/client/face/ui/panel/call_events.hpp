// Việc nhờ game của một bảng (Call) mà thực chất là đẩy một sự kiện giao diện cho các bảng khác: PushEvent của script, và
// hai hàm DataPool của chuỗi gỡ gói hành động chat (UnInstall_RMB_ChatAction cấp 0..5, Clear_ChatAction_Bar) mà Game.exe
// cài bằng cách đẩy sự kiện UI theo id (0x325..0x328, 0x38c, 0x38d, 0x329; tên ở bảng đăng ký của Game.exe 0x140a272b0).
// HUD xếp các sự kiện này vào hàng đợi rồi gửi tới các bảng nghe, như bộ gửi gốc làm với sự kiện do script đẩy.
// Khác gốc: chưa đo được là sự kiện do script đẩy tới bảng đích ngay (đệ quy trong chính lời gọi hàm) hay xếp hàng; bản
// này xếp hàng, và hai nhánh gỡ gói, dọn gói gọi hàm DataPool cuối cùng của script nên không đọc lại arg<k> sau lời gọi,
// do đó hai cách không khác nhau với bốn thanh action.
// Thuần logic, không đụng GPU.
#pragma once

#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <cstdint>
#include <optional>

namespace game::ui::panel {

// (int) của game lên số thực của Lua: cắt phần thập phân, ép về miền int32 (NaN thành 0) thay vì tràn.
[[nodiscard]] std::int32_t game_int(double value) noexcept;

// Sự kiện mà call đẩy; nullopt khi call không phải việc đẩy sự kiện (DoAction, PushDebugMessage...), khi tên sự kiện rỗng,
// hay khi UnInstall_RMB_ChatAction có cấp ngoài 0..5 (cấp 6 gửi gói tin xoá, không đẩy sự kiện).
[[nodiscard]] std::optional<PostedEvent> event_of(const Call& call);

} // namespace game::ui::panel
