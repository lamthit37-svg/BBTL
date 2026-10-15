// Sổ cửa sổ giao diện của client 2026 (Config/InterfaceEx.txt, DBC 801 "Interface.txt" ở bản 2008): mỗi dòng một cửa sổ
// với một layout và một script dưới Interface/. Bảng là Script/windows.tsv trong dữ liệu client, do
// TOOLS/content/export_windows.py xuất và stage_scripts.py đưa vào. CUIWindowMng::Init của client gốc duyệt sổ theo thứ tự
// dòng; host làm y như vậy (thứ tự nạp script, thứ tự đăng ký sự kiện, thứ tự duyệt khi nhường chỗ).
// Thuần logic, không đụng GPU hay hệ điều hành.
#pragma once

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::script {

// Cách một cửa sổ nhường chỗ khi hiện (cột demise; CUIWindowMng::DemiseWindow của UI_CEGUI.dll 3.71.9509 0x180076710,
// CloseAllWindow 0x1800763f0). Bản 9509 có 359 cửa sổ loại 0, 631 loại 1, 228 loại 2, 748 loại 3, 2 loại 4, 2 loại 6, 5 loại 7.
enum class Demise : std::uint8_t {
    // Không đóng ai; CloseAllWindow không đóng nó.
    kKeep = 0,
    // Không đóng ai; CloseAllWindow đóng nó.
    kPlain = 1,
    // Hiện thì đóng mọi cửa sổ cùng loại đang hiện.
    kGroupA = 2,
    kGroupB = 3,
    // Hiện thì CloseAllWindow.
    kCloseAll = 4,
    // Hiện thì đặt cạnh con trỏ chuột (PositionSelf 0x1800781d0). Bản 9509 không cửa sổ nào mang loại này.
    kNearCursor = 5,
    // Như kCloseAll, và CloseAllWindow không đóng nó.
    kCloseAllKept = 6,
    // Cửa sổ bật lên: hiện thì đóng mọi cửa sổ loại 7 khác đang hiện; người chơi bấm chuột ra ngoài nó thì nó tự đóng.
    kPopup = 7,
};

struct WindowDef {
    std::int32_t id = 0;
    // Tên cửa sổ: tiền tố của <tên>_PreLoad, _OnLoad, _OnEvent và tên bảng <tên>_Env.
    std::string name;
    // Đường dẫn dưới Interface/, dấu / (dấu \ của sổ gốc đã đổi lúc đọc).
    std::string layout;
    std::string script;
    Demise demise = Demise::kKeep;
};

// Đọc sổ từ chữ của Script/windows.tsv. Lỗi (câu tiếng Việt kèm số dòng): thiếu cột id, name, layout, script, demise; ô
// sai kiểu hay ngoài miền; tên rỗng hay lặp; đường dẫn rỗng, tuyệt đối, có ổ đĩa hay có "..". Dấu \ của đường dẫn đổi
// thành /. O(độ dài văn bản + n log n).
[[nodiscard]] std::expected<std::vector<WindowDef>, std::string> parse_windows(std::string_view text);

} // namespace game::ui::script
