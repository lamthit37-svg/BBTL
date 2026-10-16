/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/packet.hpp
 *  PHÂN HỆ   : Ui / Panel / Packet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hòm đồ (Packet): ba thẻ đạo cụ, vật liệu, nhiệm vụ; số hàng hiện theo sức
 *    chứa của thẻ, ô quá số đang dùng được mang hình khoá, khung cao theo số
 *    hàng; dưới cùng là tiền, nguyên bảo và các điểm. Nguồn:
 *    Interface/Packet/Packet.lua của client 2026, giải bằng
 *    TOOLS/content/lua_plain.py (Packet_OnUpdateShow 638, Packet_UpdateBagLine
 *    617, Packet_ChangeTabIndex 608, Packet_CloseFunction 162).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// SystemSetup:IsClassic luôn trả 1 (Game.exe 0x14045fbb0) nên khung cao số hàng * 35 + 278. Khác gốc: dây v6 một túi,
// không loại túi và không sức chứa, nên mọi ô của SelfBag đổ vào thẻ đạo cụ (tab 0) theo chỉ số ô; thẻ vật liệu và
// nhiệm vụ để trống. Sức chứa vẫn là số mặc định của script (20/60, 20/60, 20/20) vì máy chủ chưa gửi CurrNum. Ô có
// đồ trong vùng khoá vẫn hiện đồ, không bị hình khoá đè. Số chồng > 1 ghi CornerBotRight, cắt 3 ký tự như
// setCornerChar. bound không làm tối ô (2008 không Gloom ô túi vì ràng buộc). Chưa có: ô trang bị túi, hòm phụ, bày
// sạp, sắp xếp, thú, hướng dẫn người mới, kéo thả, SuperTooltip (Tooltip chỉ là thuộc tính, bộ vẽ chưa đọc).

#pragma once

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/talk.hpp"

#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::ui::panel {

// Bộ ảnh của hình ô khoá: script đặt nó lúc chạy (SetProperty "BackImage"), layout không nhắc tới.
inline constexpr std::string_view kBagLockImageset = "CommonFrame38";

inline constexpr std::size_t kBagTabs = 3;
// Số hàng tối đa của layout và số ô mỗi hàng (PACKAGE_NUM_PER_LINE).
inline constexpr std::size_t kBagLines = 10;
inline constexpr std::size_t kBagRow = 10;

class ItemNames;

struct Packet {
    // 0 đạo cụ, 1 vật liệu, 2 nhiệm vụ (nTheTabIndex).
    std::uint8_t tab = 0;
    // Ảnh chụp gần nhất. Đóng hòm không xoá: máy chủ chỉ gửi lại khi túi đổi.
    talk::Bag bag;
};

// Sức chứa của một thẻ: số ô dùng được và số ô hiện (kể cả ô khoá).
struct BagSize {
    std::uint32_t current = 0;
    std::uint32_t most = 0;
};

[[nodiscard]] BagSize bag_size(std::uint8_t tab) noexcept;
// Số hàng hiện của một thẻ: sức chứa chia cho mười, làm tròn lên.
[[nodiscard]] std::size_t bag_lines(std::uint8_t tab) noexcept;
// Cao khung Packet_Frame với số hàng đó (nhánh IsClassic của Packet_UpdateBagLine).
[[nodiscard]] float bag_frame_height(std::size_t lines) noexcept;

// Bấm vào một thẻ thì đổi thẻ; cửa sổ khác thì bỏ qua.
void press_packet(Packet& packet, std::string_view window) noexcept;
// Chỉ thị của hòm đồ cho thẻ đang chọn, ảnh túi và ví purse. items cho icon và tên. Gọi khi hòm đang mở.
// O(ô của ảnh + ô đang hiện): ảnh tối đa talk::kBagSlots, ô hiện tối đa kBagLines * kBagRow.
void paint_packet(Deck& deck, const Packet& packet, const ItemNames& items, const hero::Purse& purse);

} // namespace game::ui::panel
