#pragma once
// Dựng kế hoạch thay đổi túi, kho, trang bị và ví của một nhân vật. Planner đọc một Inventory nhưng không bao giờ
// ghi vào nó: mỗi thao tác kiểm HẾT điều kiện trước, chỉ khi qua mới ghi vào lớp phủ (overlay) của Planner, nên một
// thao tác hỏng để lớp phủ giữ nguyên và thao tác sau vẫn dựng tiếp trên trạng thái đúng. `finish()` ra một Plan
// (danh sách thay đổi tuyệt đối có kiểu) để Inventory::apply áp dụng một lần.
//
// Nguồn: ItemOperator/ItemContainer/HumanItemLogic và CGUseEquip/CGUnEquip của 2008 cho luật cất, chồng, đổi chỗ, mặc
// (cấp, giám định đồ lam, khoá khi mặc) và tháo. Khác gốc: có kiểm môn phái và giới tính khi mặc (2008 để client
// chặn); ba túi theo lớp vật phẩm; mọi thao tác nguyên tử. Hao mòn theo OnArmorAbrasion/OnWeaponAbrasion.
//
// Hợp đồng chung của mọi hàm trả Result: lỗi thì lớp phủ KHÔNG đổi (kể cả bộ cấp serial có thể đã tiến, vì serial
// bỏ phí chỉ để lại khoảng trống). Dữ liệu từ client (chỉ số ô, số lượng) được kiểm biên và trả lỗi, không bao giờ vào check.

#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include <cstdint>
#include <expected>
#include <optional>
#include <vector>

namespace game::item {

using Result = std::expected<void, Error>;

// Người mặc: thứ trang bị cần so.
struct Actor {
    std::uint16_t level = 1;
    std::uint8_t sect = kAnySect;
    std::uint8_t sex = kAnySex;
};

class Planner {
public:
    Planner(const Inventory& base, const Catalog& catalog, SerialAllocator& serials) noexcept;

    // ---- đọc trạng thái hiện tại (đã tính các thao tác dựng trước đó)
    [[nodiscard]] const Instance* get(SlotRef where) const noexcept;
    [[nodiscard]] std::uint64_t count_of(TemplateId tmpl) const noexcept;
    // Số ô trống mở được dùng (không bị khoá) của một nơi chứa.
    [[nodiscard]] std::uint32_t free_slots(Place place) const noexcept;
    [[nodiscard]] std::int64_t balance(Account account) const noexcept { return wallet_.balance(account); }
    [[nodiscard]] const Wallet& wallet() const noexcept { return wallet_; }

    // ---- vật phẩm
    // Cất `item` vào túi mặc định của mẫu (hay kho với add_to): lấp chồng cũ trước, rồi ô trống; số lượng vượt cỡ chồng
    // tách thành nhiều chồng (mỗi chồng mới một serial). Lỗi: kUnknownTemplate, kBadCount, kWrongPlace, kUniqueOwned, kBagFull.
    [[nodiscard]] Result add(const Instance& item);
    [[nodiscard]] Result add_to(Place place, const Instance& item);
    // Trừ `count` cái của mẫu từ các chồng trong ba túi (ô khoá không tính). Lỗi: kBadCount, kNotEnoughItems.
    [[nodiscard]] Result remove_count(TemplateId tmpl, std::uint32_t count);
    // Bỏ `count` cái khỏi một ô (hết thì ô trống). Lỗi: kNoSuchSlot, kSlotEmpty, kLocked, kBadCount.
    [[nodiscard]] Result remove_at(SlotRef where, std::uint16_t count);
    // Kéo thả: sang ô trống thì dời, vào chồng cùng loại thì gộp (phần thừa ở lại), vào ô khác loại thì đổi chỗ.
    [[nodiscard]] Result move(SlotRef from, SlotRef to);
    // Chia `count` cái từ một chồng sang ô trống (cùng nơi chứa). Lỗi thêm: kNotStackable, kSlotOccupied.
    [[nodiscard]] Result split(SlotRef from, SlotRef to, std::uint16_t count);
    // Gộp chồng `from` vào chồng `to` cùng loại. Lỗi thêm: kDifferentItems, kStackFull.
    [[nodiscard]] Result merge(SlotRef from, SlotRef to);
    // Dồn và gộp chồng một nơi chứa (túi hay kho), xếp theo lớp, mã mẫu, serial. Lỗi: kLocked nếu có ô khoá.
    [[nodiscard]] Result sort(Place place);

    // ---- trang bị
    // Mặc món ở ô túi `from`. Nhẫn và bùa hộ thân vào ô thứ hai khi ô thứ nhất đã có đồ. Đồ cũ về đúng ô `from`.
    [[nodiscard]] Result equip(SlotRef from, const Actor& actor);
    // Tháo món ở điểm lắp `point` vào ô trống đầu tiên của túi mặc định.
    [[nodiscard]] Result unequip(std::uint8_t point);
    // Giám định đồ lam. Lỗi: kNotEquipment, kNoChange.
    [[nodiscard]] Result identify(SlotRef where);
    // Thay thể hiện tại ô bằng bản đã sửa (cùng serial và mẫu): đường cho forge, đá quý, cường hoá. Lỗi: kSlotEmpty,
    // kLocked, kBrokenPlan khi serial hay mẫu đổi.
    [[nodiscard]] Result update(SlotRef where, const Instance& next);
    // Hao mòn: giáp (mọi điểm lắp trừ vũ khí) khi bị đánh, vũ khí khi đánh. Mỗi lần cộng 1 điểm hao; vượt `threshold`
    // thì về 0 và mất 1 độ bền (ConfigInfo.ini EquipmentDamagePoint = 500).
    [[nodiscard]] Result wear_armor(std::uint16_t threshold);
    [[nodiscard]] Result wear_weapon(std::uint16_t threshold);
    // Sửa một món về đủ độ bền, trừ vàng theo repair_cost. Lỗi: kNoDurability, kNoChange, kInsufficientFunds.
    [[nodiscard]] Result repair(SlotRef where, std::uint32_t shop_repair_permille);

    // ---- tiền
    [[nodiscard]] Result earn(Currency currency, std::int64_t amount);
    [[nodiscard]] Result spend(Currency currency, std::int64_t amount);
    [[nodiscard]] Result deposit_gold(std::int64_t amount);   // ví -> kho
    [[nodiscard]] Result withdraw_gold(std::int64_t amount);  // kho -> ví

    // Chốt thành Plan; bỏ các ô mà trạng thái cuối trùng trạng thái gốc.
    [[nodiscard]] Plan finish() &&;

private:
    class Edits;
    friend class Edits;

    [[nodiscard]] const std::optional<Instance>& cell(SlotRef where) const noexcept;
    [[nodiscard]] Result check_slot(SlotRef where) const noexcept;
    [[nodiscard]] bool placeable(const Template& tmpl, Place place) const noexcept;
    void commit(const Edits& edits);
    [[nodiscard]] Result add_impl(Place place, const Instance& item);
    [[nodiscard]] Result wear_impl(std::uint16_t first, std::uint16_t last, std::uint16_t threshold);

    const Inventory* base_;
    const Catalog* catalog_;
    SerialAllocator* serials_;
    std::vector<SlotChange> touched_;  // tăng theo `where`
    Wallet wallet_;
};

} // namespace game::item
