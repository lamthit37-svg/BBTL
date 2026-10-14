#pragma once
// Hằng và kiểu nền của lõi cửa hàng NPC: giới hạn, phạm vi thu mua và sửa, loại tiền "như vàng".
//
// Nguồn: CGShopBuyHandler/CGShopSellHandler/CGShopRepairHandler, ShopManager và GameDefine2.h (NPC_SHOP_TYPE) của
// 2008 cho phạm vi và giới hạn; ShopTable.txt của client 2026 cho bố cục cột; chú thích trong RandShop/*.ini của
// XJL7457 cho luật giá (docs/SERVER-ITEM.md, mục Cửa hàng).
// Khác gốc: 2008 chỉ có hai loại tiền (vàng, nguyên bảo) gán theo "ShopType"; bản này nhận mã CU_* của client 2026 ở cột
// currency_kind. Phạm vi 8 và 9 của cột buy_kind không có trong enum 2008: xem scope_of ở tables.cpp.

#include "item/catalog.hpp"
#include "item/types.hpp"

#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>

namespace game::shop {

using ShopId = ids::ShopId;

// Chỉ số hàng ≥ 200 là ngăn "mua lại" (BUY_BACK_INDEX của 2008), nên một cửa hàng không có quá 200 hàng.
inline constexpr std::size_t kMaxGoods = 200;
inline constexpr std::uint16_t kBuyBackIndex = 200;
// MAX_BOOTH_SOLD_NUMBER của 2008: số món người chơi mua lại được; món thứ sáu đè món cũ nhất.
inline constexpr std::size_t kSoldCapacity = 5;
// PerItemNum > 100 bị 2008 kẹp về 100.
inline constexpr std::uint16_t kMaxGroupSize = 100;
// Số tự đặt: 2008 mỗi lượt bấm mua đúng một nhóm; client 2026 có cột "mua nhiều" chưa rõ nghĩa, nên trần số nhóm một lượt là
// số này (docs/SERVER-ITEM.md, mục Số tự đặt).
inline constexpr std::uint16_t kMaxBuyGroups = 100;
// Một kho ngẫu nhiên không quá số mục này (bảng thật: 84).
inline constexpr std::size_t kMaxPool = 1024;
// PMAX = -1 là bán không hạn (2008: "-1 代表无限").
inline constexpr std::int32_t kUnlimited = -1;
inline constexpr std::uint32_t kPercent = 100;

[[nodiscard]] constexpr bool is_buy_back_index(std::uint16_t index) noexcept { return index >= kBuyBackIndex; }

// Loại tiền đọc giá thẳng từ bảng vật phẩm: vàng và giao tử (tiền khoá cùng thang giá với vàng). Cột giá ghi sẵn của
// ShopTable.txt (và `Value` của RandShop/*.ini, "khi tiền là vàng thì bỏ qua, đọc từ bảng vật phẩm") chỉ dùng cho tiền khác.
[[nodiscard]] constexpr bool is_gold_like(item::Currency currency) noexcept {
    return currency == item::Currency::kGold || currency == item::Currency::kBoundGold;
}

// NPC_SHOP_TYPE của 2008, dùng cho cả thu mua lẫn sửa.
enum class Scope : std::uint8_t {
    kNone = 0,      // không nhận gì
    kAll = 1,       // mọi thứ
    kDefence = 2,   // phòng cụ: mũ, giáp, bao tay, giày (điểm lắp 1..4)
    kAdorn = 3,     // trang sức: đai, nhẫn, dây chuyền, thú cưỡi (điểm lắp 5..8)
    kWeapon = 4,    // vũ khí (điểm lắp 0)
    kFood = 5,      // thuốc và đồ ăn (lớp 3)
    kMaterial = 6,  // nguyên liệu (lớp 2)
    kMedicine = 7,  // thuốc (lớp 3, cùng lớp với đồ ăn)
};

// Cửa hàng có thu mua món này không (chỉ xét loại, không xét cấp).
[[nodiscard]] bool accepts(Scope scope, const item::Template& tmpl) noexcept;
// Cửa hàng có sửa món lắp ở điểm này không (chỉ xét loại, không xét cấp).
[[nodiscard]] bool covers_point(Scope scope, std::uint8_t point) noexcept;

} // namespace game::shop
