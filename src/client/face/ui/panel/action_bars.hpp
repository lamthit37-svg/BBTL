// Nhóm thanh action của HUD (MainMenuBar_2, FunctionBarRight, FunctionBarRight_2, MainMenuBar_4): HUD giữ một ActionBars,
// đưa sự kiện, nhấn ô và khung vẽ vào đây thay vì lần lượt từng thanh. Mỗi thanh khai bảng đăng ký sự kiện (PreLoad của
// script) và hàm xử lý sự kiện riêng của nó; phần chung ở action_bar.hpp.
// Thuần logic, không đụng GPU.
#pragma once

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"

#include <span>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Hàm xử lý sự kiện của một thanh (<Tên>_OnEvent).
using BarEventHandler = void (*)(ActionBar&, const UiEvent&, const BarFacts&, std::vector<Call>&);

// Một thanh trong nhóm: trạng thái, bảng đăng ký sự kiện (<Tên>_PreLoad) và hàm xử lý.
struct BarWindow {
    ActionBar bar;
    std::span<const EventSub> events;
    BarEventHandler on_event = nullptr;
};

class ActionBars {
public:
    // Dựng mọi thanh của nhóm; thanh nào cũng ẩn như lúc nạp layout.
    ActionBars();

    // Đưa một sự kiện cho từng thanh có đăng ký nghe nó (thanh ẩn chỉ nhận sự kiện đăng ký với cờ true) rồi gom việc
    // các thanh nhờ game vào calls.
    void raise(const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

    // Nhấn trái lên cửa sổ window: nếu là ô action của một thanh thì chạy <Tên>_Clicked của thanh đó. can_do là
    // DataPool:IsCanDoAction() lúc nhấn.
    void press(std::string_view window, bool can_do, std::vector<Call>& calls) const;

    // Chép mọi thanh đang hiện sang deck.
    void paint(Deck& deck) const;

    // Thanh của nhóm theo tên layout (không có "_Frame"); nullptr khi không có.
    [[nodiscard]] const ActionBar* find(std::string_view name) const noexcept;

private:
    std::vector<BarWindow> windows_;
};

} // namespace game::ui::panel
