// Hàm DataPool: của game mà script giao diện gọi, port từ mã máy client D:\XTLBB 3.71.9509 (Game.exe và UI_CEGUI.dll).
// Mỗi hàm ghi địa chỉ mã máy ở chỗ định nghĩa; hàm phụ thuộc dữ liệu hay trạng thái game thì bảng gọi nhận kết quả
// làm đầu vào (như UiColour dưới đây) thay vì tự hỏi game.
#pragma once

#include <string_view>

namespace game::ui::panel {

// Kết quả của DataPool:GetUIColor(id): màu chữ và màu viền dạng "RRGGBB" (hay thẻ #g / #c / #e của bảng SystemColour),
// "-1" là không có.
struct UiColour {
    std::string_view font;
    std::string_view extent;
};

// GetUIColor (Game.exe 0x1402e7710) tra SystemColour (DBC id 0xa7, 47 dòng ở 3.71.9509: id 1 tới 16, 21 tới 26,
// 100 tới 114 và 2000 tới 2009) và trả hai chuỗi "-1" khi id không có dòng nào (0x140b394cc, 0x140b39514).
// Khác gốc: chưa nạp bảng SystemColour, nên chỉ có kết quả của id vắng mặt. Bảng giao diện nào cần id có dòng thì phải
// nạp bảng trước; DebugListBox dùng id 1000 nên đúng với bảng của 3.71.9509.
inline constexpr UiColour kUiColourMissing{.font = "-1", .extent = "-1"};

// DataPool:Check_StringCode(text) (Game.exe 0x1402e5db0 gọi CUISystem ô ảo 73, UI_CEGUI.dll 0x180055430): false khi chuỗi
// có ký tự điều khiển ngoài tab, xuống dòng, về đầu dòng, hay kết thúc giữa một ký tự, hay có ký tự sai. Hàm gốc kiểm
// byte đầu 0x81..0xFE và byte đuôi 0x40..0x7E hoặc 0x80..0xFE của ký tự hai byte GBK; với trang mã một byte (1251, 1252,
// 1254, 1258, 874, 949) nó trả true ngay.
// Khác gốc: dự án giữ chữ bằng UTF-8 nên kiểm theo UTF-8 (RFC 3629) với cùng hợp đồng.
[[nodiscard]] bool check_string_code(std::string_view text) noexcept;

} // namespace game::ui::panel
