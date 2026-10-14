#pragma once
// Cửa hàng của MỘT NPC lúc đang chạy: bản sao hàng từ bảng tĩnh, tồn kho từng dòng, hẹn giờ làm mới.
//
// Nguồn: DynamicShopManager (ShopManager.cpp, 2008): mỗi NPC giữ một bản sao có tồn kho riêng (m_TypeMaxNum, chỉ phần này
// ghi được), mỗi lượt mua trừ 1 nhóm khi dòng có giới hạn, và mỗi `refresh_time` mili giây tồn kho được đặt lại bằng giá trị của
// bảng tĩnh. Cửa hàng ngẫu nhiên (cột is_random_shop) chọn `Num` mục từ kho RandShop/*.ini theo trọng số `Odds`; 2008 khai báo
// mà không viết hàm chọn (GenerateRandItemPrice), nên luật chọn dưới đây là suy ra từ chú thích của tệp ini: "Total = kích
// thước kho, Count = số đơn vị bán, Odds = tương đối".
// Khác gốc: 2008 tính hạn bằng đồng hồ máy; bản này bằng tick (ids::Tick, 20 Hz), làm mới một lần cho mỗi hạn bị lỡ chứ không
// bù nhiều lần. Cửa hàng ngẫu nhiên chọn LẠI hàng mỗi lần làm mới; mục chọn xếp theo thứ tự của kho, không theo thứ tự rút.
//
// Hợp đồng: lớp không có luồng và không đọc đồng hồ; mọi thay đổi đi qua tick() và commit(). Mua là ba bước trong CÙNG một
// tick: plan_buy (trade.hpp) dựng kế hoạch túi, Inventory::apply, rồi NpcShop::commit trừ tồn. commit từ chối vé của revision cũ
// (kStalePlan) để hai người cùng mua món cuối không ai được hai lần.

#include "item/types.hpp"
#include "shop/tables.hpp"
#include "shop/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <vector>

namespace game::shop {

// Một dòng đang bán.
struct Line {
    Goods goods;
    std::int32_t stock = kUnlimited;  // số nhóm còn lại; kUnlimited là không hạn

    friend constexpr bool operator==(const Line&, const Line&) noexcept = default;
};

// Giấy hẹn từ plan_buy: nguyên liệu để NpcShop::commit trừ tồn sau khi túi người mua đã áp dụng.
struct BuyTicket {
    std::uint16_t line = 0;
    std::uint16_t groups = 1;
    std::uint64_t revision = 0;
};

class NpcShop {
public:
    // Mở cửa hàng `shop` ở `scene`. Lỗi: kNoSuchEntry (không có cửa hàng), kWrongScene (bảng cảnh không cho mở ở đây).
    [[nodiscard]] static std::expected<NpcShop, item::Error> open(const ShopTables& tables, ShopId shop, ids::SceneId scene,
        ids::Tick now, dice::Dice& dice);

    // Làm mới nếu đã tới hạn. true khi hàng hoặc tồn kho thực sự đổi (revision tăng).
    [[nodiscard]] bool tick(ids::Tick now, dice::Dice& dice);

    [[nodiscard]] const ShopDef& def() const noexcept { return *def_; }
    [[nodiscard]] std::span<const Line> lines() const noexcept { return lines_; }
    // Tăng mỗi khi hàng hoặc tồn kho đổi; client cần gửi lại danh sách khi nó đổi.
    [[nodiscard]] std::uint64_t revision() const noexcept { return revision_; }
    // Mốc làm mới kế tiếp; chỉ có nghĩa khi has_refresh().
    [[nodiscard]] ids::Tick next_refresh() const noexcept { return next_refresh_; }
    [[nodiscard]] bool has_refresh() const noexcept { return interval_.count > 0; }

    // Trừ tồn sau khi người mua đã nhận hàng. Lỗi: kStalePlan (revision đã đổi), kNoSuchEntry, kSoldOut.
    [[nodiscard]] std::expected<void, item::Error> commit(const BuyTicket& ticket);

private:
    NpcShop(const ShopTables& tables, const ShopDef& def, ids::Tick now, dice::Dice& dice);

    void stock_fixed();
    void stock_random(dice::Dice& dice);

    const ShopTables* tables_;
    const ShopDef* def_;
    std::vector<Line> lines_;
    ids::TickSpan interval_{};
    ids::Tick next_refresh_{};
    std::uint64_t revision_ = 1;
};

} // namespace game::shop
