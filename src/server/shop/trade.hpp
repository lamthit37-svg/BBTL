#pragma once
// Mua, bán, mua lại, sửa và thu hồi phế phẩm ở cửa hàng NPC, dựng trên item::Planner. Mọi hàm plan_* là NGUYÊN TỬ: lỗi thì
// Planner giữ nguyên trạng thái trước lời gọi (kể cả khi thao tác gồm nhiều bước nhỏ), thành công thì Planner mang đủ mọi
// thay đổi; kế hoạch chỉ có hiệu lực sau Inventory::apply. Thứ thuộc về cửa hàng hay danh sách mua lại của người chơi
// (tồn kho, SoldList) chỉ đổi qua bước commit/remember/take sau khi apply thành công.
//
// Nguồn: CGShopBuyHandler (kiểm hết hàng, tiền, rồi chỗ trong túi; mỗi lượt một nhóm), CGShopSellHandler (cổng cấp và loại, giá
// bán, danh sách mua lại), CGShopRepairHandler (cổng cấp và loại, phí sửa; sửa hết dừng ở món đầu tiên không đủ tiền và chỉ tính
// những món đã sửa) và Obj_Human::AddToSoldList (vòng 5 ô, đè món cũ nhất) của 2008.
// Khác gốc: giá mua lấy theo cột giá ghi sẵn khi tiền không phải vàng hay giao tử (tables.hpp); chiết khấu và hệ số cửa hàng
// nhân MỘT lần rồi làm tròn nửa lên (2008 ép hệ số về int trước khi nhân, nên hệ số 0,5 cho giá 0); trần ví được kiểm lúc bán
// (2008 để tràn); số nhóm mỗi lượt mua là tham số (2008 luôn một nhóm); danh sách mua lại chỉ ghi khi cửa hàng có can_buy_back
// (2008 không đọc cờ này ở server, client dùng nó để ẩn ngăn mua lại); tiền bán luôn là vàng, như 2008.

#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/price.hpp"
#include "item/types.hpp"
#include "shop/npc_shop.hpp"
#include "shop/tables.hpp"
#include "shop/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::shop {

// Giá của MỘT nhóm (đã nhân chiết khấu và hệ số cửa hàng), tính bằng tiền của cửa hàng. Lỗi: kUnknownTemplate, kBadAmount (tràn).
[[nodiscard]] std::expected<std::int64_t, item::Error> price_of(const ShopDef& shop, const Goods& goods, const item::Catalog& catalog);

// ---- mua ----------------------------------------------------------------------------------------------------------------

struct BuyRequest {
    std::size_t line = 0;        // chỉ số trong NpcShop::lines()
    std::uint16_t groups = 1;    // số nhóm, 1..kMaxBuyGroups
};

// Trừ tiền rồi cất hàng vào túi. Thứ tự kiểm như 2008: hết hàng, thiếu tiền, hết chỗ. Lỗi: kBadCount, kNoSuchEntry, kSoldOut,
// kInsufficientFunds, kBagFull (và các lỗi cất đồ của Planner::add), kBadAmount. Serial đã cấp cho món sinh dở không hoàn lại
// (bỏ phí chỉ để lại khoảng trống). Thành công thì đưa BuyTicket cho NpcShop::commit SAU Inventory::apply.
[[nodiscard]] std::expected<BuyTicket, item::Error> plan_buy(const NpcShop& shop, const BuyRequest& request,
    const item::Factory& factory, dice::Dice& dice, item::SerialAllocator& serials, ids::Tick now, item::Planner& planner);

// ---- bán và mua lại -----------------------------------------------------------------------------------------------------

// Món người chơi bán, đủ để mua lại.
struct SellTicket {
    item::Instance item;
    std::int64_t price = 0;   // vàng nhận được, cũng là giá mua lại
    bool remember = false;    // cửa hàng cho mua lại: SoldList::remember sẽ ghi
};

// Bán TOÀN BỘ chồng ở ô túi `from` (túi đạo cụ, nguyên liệu hay nhiệm vụ) lấy vàng. Lỗi: kWrongPlace (không phải ba túi),
// kNoSuchSlot, kSlotEmpty, kLocked, kShopRefuses (cấp cao hơn buy_level hay loại ngoài phạm vi), kForbidden (vật phẩm cấm bán),
// kBadAmount, kOverCap (ví đầy).
[[nodiscard]] std::expected<SellTicket, item::Error> plan_sell(const ShopDef& shop, const item::Catalog& catalog,
    const item::PriceRules& rules, item::SlotRef from, item::Planner& planner);

struct SoldEntry {
    item::Instance item;
    std::int64_t price = 0;
};

struct BuyBackTicket {
    item::Serial serial;
};

// Danh sách mua lại của một người chơi: tối đa kSoldCapacity món, món mới nhất ở trên cùng, món thứ sáu đè món cũ nhất
// (vòng 5 ô của Obj_Human). Mất khi đóng cửa hàng (clear): món chưa mua lại biến mất hẳn, như 2008.
class SoldList {
public:
    // Ghi món vừa bán; không làm gì khi ticket.remember sai.
    void remember(const SellTicket& ticket);
    [[nodiscard]] const SoldEntry* top() const noexcept { return entries_.empty() ? nullptr : &entries_.back(); }
    [[nodiscard]] std::size_t size() const noexcept { return entries_.size(); }
    void clear() noexcept { entries_.clear(); }
    // Lấy món trên cùng ra sau khi kế hoạch mua lại đã áp dụng. Lỗi: kNoSuchEntry (rỗng), kStalePlan (món trên cùng đã khác).
    [[nodiscard]] std::expected<void, item::Error> take(const BuyBackTicket& ticket);

private:
    std::vector<SoldEntry> entries_;  // cũ nhất ở đầu
};

// Mua lại món trên cùng của danh sách (2008 chỉ cho mua món vừa bán): trả đúng giá đã nhận, món về túi với đúng serial cũ.
// Lỗi: kNoSuchEntry (danh sách rỗng), kInsufficientFunds, kBagFull.
[[nodiscard]] std::expected<BuyBackTicket, item::Error> plan_buy_back(const SoldList& list, item::Planner& planner);

// ---- sửa ----------------------------------------------------------------------------------------------------------------

struct RepairReport {
    std::uint32_t repaired = 0;      // số món đã sửa
    std::int64_t spent = 0;          // vàng đã trừ
    bool short_of_money = false;     // sửa hết dừng giữa chừng vì không đủ tiền cho món kế
};

// Sửa một món ở túi hay đang mặc về đủ độ bền. Lỗi: kShopRefuses (cấp hoặc điểm lắp ngoài phạm vi sửa), kNoDurability, kNoChange,
// kInsufficientFunds và lỗi ô của Planner::repair.
[[nodiscard]] std::expected<RepairReport, item::Error> plan_repair(const ShopDef& shop, const item::Catalog& catalog,
    item::SlotRef where, item::Planner& planner);

// Sửa mọi món đang mặc theo thứ tự điểm lắp. Món vượt cấp, ngoài phạm vi, không hao mòn hay đã đầy độ bền thì bỏ qua. Gặp món
// không đủ tiền thì DỪNG (không nhảy sang món rẻ hơn, như 2008) nhưng giữ các món đã sửa và đánh dấu short_of_money. Lỗi: kNoChange
// (không có gì cần sửa), kInsufficientFunds (không sửa nổi món nào vì thiếu tiền).
[[nodiscard]] std::expected<RepairReport, item::Error> plan_repair_all(const ShopDef& shop, const item::Catalog& catalog,
    item::Planner& planner);

// ---- phế phẩm -----------------------------------------------------------------------------------------------------------

struct RecycleReceipt {
    item::TemplateId item;
    std::uint16_t count = 0;
    std::int64_t gold = 0;
};

// Đổi `count` cái phế phẩm ở ô túi `from` lấy vàng theo bảng junk_recycle (giá cố định mỗi cái, không theo giá vật phẩm).
// NPC nào thu hồi do script quyết định; hàm này không gắn với cửa hàng. Lỗi: kWrongPlace, kNoSuchSlot, kSlotEmpty, kLocked,
// kBadCount (count 0 hay quá chồng), kShopRefuses (mã không có trong bảng thu hồi), kBadAmount, kOverCap.
[[nodiscard]] std::expected<RecycleReceipt, item::Error> plan_recycle(const ShopTables& tables, item::SlotRef from,
    std::uint16_t count, item::Planner& planner);

} // namespace game::shop
