#pragma once
// Chế biến ở lò rèn: nung ngọc, chạm ngọc, nâng cấp siêu vũ khí. Một lời gọi plan_craft là NGUYÊN TỬ trên item::Planner:
// lỗi thì Planner giữ nguyên trạng thái trước lời gọi, thành công thì Planner mang đủ mọi thay đổi (bớt 1 món đầu vào, trừ
// vật liệu, trừ vàng, cất món ra) và chỉ có hiệu lực sau Inventory::apply.
//
// Nguồn: công thức ở tables.hpp. Thứ tự kiểm: món đầu vào, công thức, vật liệu (bộ chính rồi bộ thay thế), vàng, chỗ trong túi.
// Khác gốc: 2008 không có hệ thống này (xem tables.hpp); thứ tự kiểm vật liệu rồi vàng theo thứ tự cột của ba bảng công thức.

#include "forge/tables.hpp"

#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstdint>
#include <expected>

namespace game::forge {

struct CraftReport {
    item::TemplateId input;       // món đã bớt đi
    item::Instance produced;      // món vừa sinh (đã cất vào túi trong kế hoạch)
    std::int64_t gold = 0;        // vàng đã trừ
    bool used_substitute = false; // vật liệu thay thế được dùng thay bộ chính (nung ngọc)
};

// Chế biến món ở ô túi `from` (túi đạo cụ, nguyên liệu hay nhiệm vụ): bớt 1 cái, trừ vật liệu trong ba túi và vàng, cất món
// ra. Món ra là món MỚI sinh bằng Factory (Origin::kForge, cấp nguyên liệu 0) và mang cờ khoá của món vào. Lỗi: kWrongPlace
// (không phải ba túi), kNoSuchSlot, kSlotEmpty, kLocked, kNoSuchEntry (món này không có công thức loại `kind`),
// kNotEnoughItems (thiếu vật liệu cả bộ chính lẫn bộ thay thế), kInsufficientFunds, kBagFull (và các lỗi cất đồ của
// Planner::add), cùng lỗi của Factory. Serial đã cấp cho món sinh dở không hoàn lại (chỉ để lại khoảng trống).
[[nodiscard]] std::expected<CraftReport, item::Error> plan_craft(const ForgeTables& tables, Kind kind, item::SlotRef from,
    const item::Factory& factory, dice::Dice& dice, item::SerialAllocator& serials, ids::Tick now, item::Planner& planner);

} // namespace game::forge
