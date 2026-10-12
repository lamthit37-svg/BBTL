// Khung nhân vật (PlayerFrame): tên, cấp, ba thanh máu, khí, nộ, điểm liên kích, dấu đội trưởng,
// chân dung và cảnh báo máu thấp, theo PlayerFrame_Update của script gốc.
// Nguồn: G:\TLBB\_content\source\Interface\PlayerFrame\PlayerFrame.lua (dòng 219-291, 345-355).
// Chân dung là ảnh 2D gán vào PlayerFrame_Head_3D, cửa sổ con của PlayerFrame_Head_Parent. Cha bật
// RoundEnabled trước MaskImage HeadRoundRegion, nên hub che quad của con bằng mặt nạ đó. Khác gốc:
// đầu 3D (FakeObject) chưa dựng, ảnh bảng chân dung thế chỗ texture render-to-texture. Các ô riêng
// của môn phái mới và dấu trạng thái PK chỉ có ở layout 2026, script của chúng đã mã hoá nên giấu
// là suy từ layout (docs/NGHI-NGO.md mục 19); cửa sổ nháy máu thấp bị giấu khi máu đủ thay cho
// Play(false) (cùng kết quả trên màn hình).
#pragma once

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

#include <string_view>

namespace game::ui::panel {

// Tên fake object của đầu người chơi, như đối số SetFakeObject của client gốc.
inline constexpr std::string_view kPlayerHead = "Player_Head";
// Tên ảnh toàn thân mà bảng nhân vật gắn vào SelfEquip_FakeObject.
inline constexpr std::string_view kEquipModel = "SelfEquip_Player";

// Chân dung của khung. model là tên fake object của đầu 3D mà nơi vẽ đã dựng ảnh (rỗng khi chưa
// có); image là ảnh phẳng của bảng chân dung, dạng "set:<bộ> image:<ảnh>", dùng khi không có đầu
// 3D. Cả hai rỗng thì ô chân dung để trống.
struct Face {
    std::string_view image;
    std::string_view model;
};

// Ghi chỉ thị của khung nhân vật cho hero. Các chuỗi mượn phải sống tới hết khung.
void fill_player(Deck& deck, const hero::Hero& hero, const Face& face);

} // namespace game::ui::panel
