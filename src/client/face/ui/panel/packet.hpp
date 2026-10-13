// Hòm đồ (Packet): ba thẻ đạo cụ, vật liệu, nhiệm vụ; số hàng hiện theo sức chứa của thẻ, ô quá số đang
// dùng được mang hình khoá, khung cao theo số hàng; dưới cùng là tiền, nguyên bảo và các điểm.
// Nguồn: Interface/Packet/Packet.lua của client 2026, giải bằng TOOLS/content/lua_plain.py
// (Packet_OnUpdateShow 638, Packet_UpdateBagLine 617, Packet_ChangeTabIndex 608, Packet_CloseFunction 162).
// SystemSetup:IsClassic luôn trả 1 (Game.exe 0x14045fbb0) nên khung cao số hàng * 35 + 278.
// Khác gốc: chưa có vật phẩm nên mọi ô trống; số ô của từng thẻ do máy chủ gửi (DataPool:GetBaseBag_Num,
// GetBaseBag_RealMaxNum...) mà chưa có máy chủ, nên lấy số mặc định của script: 20 ô dùng được trên
// 60 ô (6 hàng) cho thẻ đạo cụ và vật liệu, thẻ nhiệm vụ 20 ô trên 20 (giả định, chưa đo); chưa có
// tooltip, ô trang bị túi và hòm phụ, nút bày sạp, sắp xếp, khoá, thú (chưa nối việc nào), hướng dẫn
// người mới, cột kéo thả.
#pragma once

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

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

struct Packet {
    // 0 đạo cụ, 1 vật liệu, 2 nhiệm vụ (nTheTabIndex).
    std::uint8_t tab = 0;
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
// Chỉ thị của hòm đồ cho thẻ đang chọn và ví purse. Gọi khi hòm đang mở.
void paint_packet(Deck& deck, const Packet& packet, const hero::Purse& purse);

} // namespace game::ui::panel
