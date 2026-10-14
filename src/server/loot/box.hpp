#pragma once
// Hộp rơi: tối đa 10 vật phẩm nằm trên đất, có chủ nhặt và hạn biến mất tính bằng tick.
//
// Nguồn: Obj_ItemBox của 2008 (Init: hẹn giờ thu hồi m_RecycleTimer bằng DropBoxRecycle của ConfigInfo.ini, zone.toml
// [drops] box_recycle_ms; CanPickBox: hộp rơi từ quái chỉ chủ nhặt được, chủ rỗng thì ai cũng nhặt; hộp điểm sinh trưởng
// cho người khác nhặt sau m_FinalPickTime). Khác gốc: mốc "ai cũng nhặt được" (public_from) tính bằng tick và có thể đặt cho
// cả hộp rơi, 2008 chỉ có cho điểm sinh trưởng; các ô giữ nguyên chỉ số khi một món được nhặt (client gọi nhặt theo chỉ số).
//
// Nhặt gồm hai bước vì hộp nằm ngoài Inventory: plan_pick dựng thay đổi túi mà không đổi hộp, rồi sau khi Inventory::apply
// thành công, take lấy món ra khỏi hộp. Phiếu (PickTicket) mang serial nên hộp đã đổi ở giữa thì take từ chối.

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"
#include "loot/types.hpp"

#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <vector>

namespace game::loot {

struct DropBox {
    std::optional<ids::CharacterId> owner;  // chủ nhặt; rỗng thì ai cũng nhặt được
    ids::Tick expires_at;                   // từ tick này hộp đã hết hạn
    std::optional<ids::Tick> public_from;   // từ tick này ai cũng nhặt được; rỗng thì chỉ chủ
    std::array<std::optional<item::Instance>, kBoxCapacity> slots{};

    [[nodiscard]] bool expired(ids::Tick now) const noexcept { return now >= expires_at; }
    // Quyền nhặt, không xét hạn: chủ, hay ai cũng được (không chủ hoặc đã qua public_from).
    [[nodiscard]] bool can_pick(ids::CharacterId who, ids::Tick now) const noexcept;
    [[nodiscard]] std::size_t item_count() const noexcept;
    [[nodiscard]] bool empty() const noexcept { return item_count() == 0; }
    // nullptr khi chỉ số ngoài hộp hay ô đã trống.
    [[nodiscard]] const item::Instance* item(std::size_t index) const noexcept;
    // Đặt vào ô trống đầu tiên; false khi hộp đầy.
    [[nodiscard]] bool put(const item::Instance& instance);
};

struct PickTicket {
    std::uint8_t index = 0;
    item::Serial serial;
};

// Dựng việc nhặt ô `index` vào túi. Hộp không đổi. Đồ có cờ khoá-khi-nhặt khoá ngay trong kế hoạch. Lỗi: kNoSuchEntry (ô
// ngoài hộp hay trống), kBoxExpired, kNotOwner, và lỗi cất của Planner::add (kBagFull, kUniqueOwned, kWrongPlace...).
[[nodiscard]] std::expected<PickTicket, item::Error> plan_pick(const DropBox& box, std::size_t index, ids::CharacterId who,
    ids::Tick now, const item::Catalog& catalog, item::Planner& planner);

// Nhặt mọi món cất được, theo thứ tự ô; món không cất được ở lại hộp. Lỗi khi hộp hết hạn, không phải của `who`, trống, hay
// không món nào cất được (khi đó trả lỗi cất của món đầu tiên).
[[nodiscard]] std::expected<std::vector<PickTicket>, item::Error> plan_pick_all(const DropBox& box, ids::CharacterId who,
    ids::Tick now, const item::Catalog& catalog, item::Planner& planner);

// Lấy món khỏi hộp sau khi kế hoạch đã áp dụng. Lỗi: kNoSuchEntry (chỉ số ngoài hộp), kStalePlan (ô đã trống hay đã đổi món).
[[nodiscard]] std::expected<item::Instance, item::Error> take(DropBox& box, const PickTicket& ticket);

} // namespace game::loot
