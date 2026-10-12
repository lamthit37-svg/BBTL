// Bảng chọn nhân vật (SelectRole/SelectRole.layout.xml). Ba ô, nút vào game, tạo, xoá và quay lại.
// Script gốc: SelectRole.lua của client 2026 (SelectRole_Clicked, SelectRole_DoubleClicked,
// SelectRole_EnterGame, SelectRole_CreateRole, SelectRole_DelRole, SelectRole_Return,
// SelectRole_ShowSelRoleInfo, SelectRole_HighLight).
// Khác gốc: một lần nhấn ô trống mở tạo nhân vật (gốc đòi nhấn đúp; client chỉ báo lúc nhấn);
// nhấn lần hai vào ô đã chọn thì vào game. Xoá hỏi trên dòng SelectRole_Info rồi nhấn Xoá lần nữa,
// vì hộp YesNo chưa có. Không có giờ xoá trễ và không có trạng thái bán nhân vật.
#pragma once

#include "ui/panel/deck.hpp"
#include "ui/panel/roles.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kSelectLayout = "SelectRole/SelectRole.layout.xml";

// Việc bảng nhờ chuỗi đăng nhập làm sau lần nhấn.
enum class SelectAction : std::uint8_t { kEnter, kCreate, kDelete, kBack };

struct SelectRole {
    std::array<Role, kRoleCap> roles{};
    std::uint8_t count = 0;
    std::uint8_t selected = 0;
    // Ô đang chọn đã được nhấn ít nhất một lần: lần nhấn kế trên đúng ô đó là vào game.
    bool was_clicked = false;
    bool confirming = false;
    std::string info;
    std::optional<SelectAction> request;
};

// Mở bảng với roster. selected nằm ngoài số nhân vật thì kẹp về ô cuối, hoặc 0 khi chưa có ai.
void open_select(SelectRole& select, const Roster& roster, std::uint8_t selected);
// Một lần nhấn trái lên cửa sổ window.
void press_select(SelectRole& select, std::string_view window);
// Lấy việc đang chờ; lấy rồi thì hết.
[[nodiscard]] std::optional<SelectAction> take_select(SelectRole& select) noexcept;
// Nhân vật đang chọn; không có khi ô đó trống.
[[nodiscard]] const Role* chosen_role(const SelectRole& select) noexcept;
// Ghi chỉ thị của khung: một gốc, chữ và ảnh của từng ô, viền ô đang chọn, câu trên dòng trạng thái.
void paint_select(Deck& deck, const SelectRole& select);

} // namespace game::ui::panel
