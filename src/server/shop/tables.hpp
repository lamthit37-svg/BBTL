#pragma once
// Bảng cửa hàng NPC đã nạp và kiểm chéo: ShopTable.txt (hàng cố định, kho ngẫu nhiên, luật thu mua và sửa), ShopSceneLimiti.txt
// (cảnh được mở cửa hàng), RandShop/*.ini (kho của cửa hàng ngẫu nhiên) và FeiPinHuiShou.txt (đồ phế phẩm thu hồi).
//
// Nguồn: InitShopTable của ShopManager.cpp (2008) cho cách đọc hàng (ngừng ở mã 0, PNUM < 0 thành 1, PNUM > 100 thành
// 100, PMAX 0 thành -1) và cột; tiêu đề cột ShopTable.txt của XJL7457 cho bố cục 2026: 14 cột đầu, 15 cột chưa rõ
// nghĩa (14..28), rồi các khối sáu cột {mã, PNUM, PMAX, giá, chiết khấu, màu} bắt đầu ở cột 29. Tên cột của
// shared/shops.tsv sau khối thứ 29 lệch (công cụ căn cột gán nhầm) nên bộ nạp kiểm tên 14 cột đầu và dựa vào VỊ TRÍ cho
// các khối; vị trí đã đối chiếu trên cả 383 cửa hàng (mã vật phẩm liền nhau từ khối đầu, PNUM/PMAX/chiết khấu trong miền).
// Khác gốc: 2008 tính giá từ bảng vật phẩm cho mọi cửa hàng; bản 2026 có cột giá ghi sẵn cho cả nhóm, chỉ dùng khi tiền
// không phải vàng hay giao tử (chú thích `Value` của RandShop/*.ini). Chiết khấu là phần trăm (`Rebate`: 折扣率 /100).
//
// Hợp đồng nạp: lỗi bảng (cột lạ, số ngoài miền, id trùng, cửa hàng ngẫu nhiên trỏ kho không có) trả câu lỗi tiếng Việt
// kèm bảng và dòng, không dựng gì một nửa. Mục vật phẩm không có trong catalog (id của máy chủ gốc mà client 2026 không
// biết) KHÔNG làm hỏng bảng: bị bỏ và đếm ở diagnostics(), như bộ nạp bảng rơi đồ.

#include "item/catalog.hpp"
#include "item/types.hpp"
#include "shop/types.hpp"

#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::shop {

// Nội dung các bảng; văn bản phải sống tới hết lời gọi ShopTables::load. Chỉ `shops` là bắt buộc.
struct ShopSources {
    std::string_view shops{};         // shared/shops.tsv
    std::string_view scene_limits{};  // shared/shop_scene_limits.tsv
    std::string_view random_goods{};  // server/random_shop_goods.tsv (bắt buộc khi có cửa hàng ngẫu nhiên)
    std::string_view junk_recycle{};  // shared/junk_recycle.tsv
};

// Một mặt hàng: một "nhóm" gồm `group` cái, mỗi lượt mua lấy một nhóm.
struct Goods {
    item::TemplateId item;
    std::uint16_t group = 1;             // số cái mỗi nhóm (PNUM), 1..kMaxGroupSize
    std::int32_t capacity = kUnlimited;  // số nhóm tối đa sau mỗi lần làm mới (PMAX); kUnlimited là bán không hạn
    std::int64_t listed_price = 0;       // giá ghi sẵn cho CẢ nhóm; chỉ dùng khi tiền cửa hàng không phải vàng hay giao tử
    std::uint16_t discount_percent = static_cast<std::uint16_t>(kPercent);  // chiết khấu, phần trăm của giá

    friend constexpr bool operator==(const Goods&, const Goods&) noexcept = default;
};

// Mục của kho ngẫu nhiên (RandShop/*.ini).
struct PoolEntry {
    Goods goods;
    std::uint32_t odds = 1;  // trọng số xuất hiện

    friend constexpr bool operator==(const PoolEntry&, const PoolEntry&) noexcept = default;
};

struct ShopDef {
    ShopId id;
    std::uint16_t repair_level = 0;       // sửa được trang bị có cấp yêu cầu không quá số này
    std::uint16_t buy_level = 0;          // thu mua món có cấp không quá số này
    Scope repair_scope = Scope::kNone;
    Scope buy_scope = Scope::kNone;
    std::uint32_t repair_permille = 1000;  // hệ số phí sửa (cột repair_cost, 1,0 = 1000)
    item::Currency currency = item::Currency::kGold;
    bool can_buy_back = false;
    std::uint32_t scale_permille = 1000;   // hệ số giá của cửa hàng, cho cả giá bán ra lẫn giá thu mua
    std::uint32_t refresh_ms = 0;          // chu kỳ làm mới (0 = không làm mới)
    bool random = false;                   // hàng chọn ngẫu nhiên từ kho
    std::uint16_t pick_count = 0;          // cửa hàng ngẫu nhiên: số mục chọn ra
    std::uint32_t goods_begin = 0;
    std::uint16_t goods_count = 0;
    std::uint32_t pool_begin = 0;
    std::uint16_t pool_count = 0;
    std::uint32_t scene_begin = 0;
    std::uint16_t scene_count = 0;
    bool scene_limited = false;            // có dòng trong bảng cảnh; không có thì mở ở đâu cũng được
};

// Những gì bảng có mà không dùng được, để người soạn bảng thấy; khác 0 không phải lỗi.
struct Diagnostics {
    std::size_t unknown_goods = 0;          // hàng cố định có mã ngoài catalog
    std::size_t unknown_pool_items = 0;     // mục kho ngẫu nhiên có mã ngoài catalog
    std::size_t unknown_junk_items = 0;
    std::size_t repair_rate_not_one = 0;    // cửa hàng có tỉ lệ sửa thành công khác 1: 2008 đọc mà không dùng, bản này cũng vậy
    std::size_t scene_rows_without_shop = 0;
};

class ShopTables {
public:
    [[nodiscard]] static std::expected<ShopTables, std::string> load(const ShopSources& sources, const item::Catalog& catalog);

    [[nodiscard]] const ShopDef* find(ShopId id) const noexcept;
    [[nodiscard]] std::span<const ShopDef> all() const noexcept { return shops_; }
    [[nodiscard]] std::span<const Goods> goods(const ShopDef& shop) const noexcept;
    [[nodiscard]] std::span<const PoolEntry> pool(const ShopDef& shop) const noexcept;
    // Cửa hàng có mở được ở cảnh này không. Cửa hàng không có dòng trong bảng cảnh mở được ở mọi cảnh.
    [[nodiscard]] bool allowed_in(const ShopDef& shop, ids::SceneId scene) const noexcept;
    // Tiền vàng cho MỘT cái đồ phế phẩm; nullopt khi mã không thu hồi.
    [[nodiscard]] std::optional<std::int64_t> junk_value(item::TemplateId item) const noexcept;
    [[nodiscard]] const Diagnostics& diagnostics() const noexcept { return diagnostics_; }

private:
    friend struct ShopLoader;

    std::vector<ShopDef> shops_;  // tăng theo id
    std::vector<Goods> goods_;
    std::vector<PoolEntry> pool_;
    std::vector<std::uint16_t> scenes_;                         // mỗi cửa hàng một đoạn tăng dần, không trùng
    std::vector<std::pair<item::TemplateId, std::int64_t>> junk_;  // tăng theo mã
    Diagnostics diagnostics_{};
};

} // namespace game::shop
