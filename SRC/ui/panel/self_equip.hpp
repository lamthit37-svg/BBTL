// Bảng nhân vật (SelfEquip) lúc mở: tên, cấp, môn phái, máu, khí, nộ, kinh nghiệm, năm chỉ số gốc,
// tám chỉ số chiến đấu, hoạt lực, tinh lực, điểm trang bị, các nút cộng điểm, nút lên cấp, khoá
// lên cấp, ô trang bị và dãy mười sáu thẻ, theo nhánh OPEN_EQUIP của SelfEquip_OnEvent.
// Nguồn: Interface/SelfEquip/SelfEquip.lua của client 2026, giải bằng TOOLS/content/lua_plain.py
// (Equip_OnUpdateShow 1350, Equip_RefreshEquip 1765, SelfEquip_LevelupButtonShow 1256,
// SelfEquip_LevelupLock_Update 2745, SelfEquip_UpdateGemContainer 3336, SelfEquip_ShowPage 4018).
// Ô trang bị trống theo mã máy Game.exe 2026: GetEquipDur trả 1.0 (0x140013a70) và
// IsLevelEnoughEquip trả 1 (0x140012750) nên không có mặt nạ nhắc; Lua_GetEquipZhiZunType trả -1
// (0x140014bc0) nên không có hoạt ảnh chí tôn.
// Khác gốc: chưa có vật phẩm nên mọi ô trang bị trống; chưa port các nhánh máy chủ Khinh Hưởng
// (Is2606S) và máy chủ PK (IsPKServer_JD), nộ riêng của môn phái 13 (ENG), tooltip, chấm đỏ nhắc
// việc (coi như không có), kỹ năng đổi bảo thạch 278 (coi như chưa học), cường hoá bộ (mức 0),
// hạng thí kiếm (giấu) và mô hình 3D giữa bảng (AttachWindowEx("Player")). Chi tiết ở
// docs/NGHI-NGO.md mục 36.
#pragma once

#include "gui/strings.hpp"
#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

namespace game::ui::panel {

// Ghi chỉ thị của bảng nhân vật cho hero. strings là bảng chuỗi đang dùng (để điền mẫu cấp).
void fill_self_equip(Deck& deck, const hero::Hero& hero, const gui::StringBook& strings);

} // namespace game::ui::panel
