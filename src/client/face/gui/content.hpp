// Nội dung động của danh sách và cửa sổ phức hợp đi vào bộ dàn trang qua Override, thay các lời gọi
// AddItem, AddTextElement, AddActionElement... mà script gốc gọi lên cửa sổ CEGUI. Một thuộc tính
// mang cả dãy bản ghi; bản ghi cách nhau bằng kRecordMark, trường trong bản ghi bằng kFieldMark (hai
// ký tự điều khiển không có trong chữ giao diện). Người dựng (ui/panel/widgets) và người đọc
// (gui/widgets.cpp) cùng dùng các hằng ở đây.
#pragma once

#include <string_view>

namespace game::gui {

inline constexpr char kRecordMark = '\x1e';
inline constexpr char kFieldMark = '\x1f';

// Falagard/Listbox: "Items" là các mục, mỗi bản ghi gồm màu chữ "AARRGGBB" (rỗng là trắng) rồi chữ;
// "SelectedItem" là chỉ số (từ 0) của mục đang chọn, vắng hay rỗng là không chọn mục nào.
inline constexpr std::string_view kItemsProperty = "Items";
inline constexpr std::string_view kSelectedProperty = "SelectedItem";
// Vị trí cuộn dọc theo điểm ảnh của danh sách và cửa sổ phức hợp (Scrollbar::d_position).
inline constexpr std::string_view kScrollProperty = "ScrollPosition";

// Falagard/ComplexWindow: "Elements" là các phần tử theo thứ tự thêm; trường đầu của bản ghi là
// loại, các trường sau là đối số:
//   text    chữ (AddTextElement)
//   money   số tiền (AddMoneyElement)
//   jiaozi  số giao tử (AddJiaoZiElement)
//   action  tên đầy đủ của icon "set:... image:...", rồi "1" khi reArrange (AddActionElement)
inline constexpr std::string_view kElementsProperty = "Elements";
inline constexpr std::string_view kTextElement = "text";
inline constexpr std::string_view kMoneyElement = "money";
inline constexpr std::string_view kJiaoZiElement = "jiaozi";
inline constexpr std::string_view kActionElement = "action";

} // namespace game::gui
