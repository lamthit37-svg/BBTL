#pragma once
// Giá bán cho NPC và phí sửa trang bị. Số nguyên thuần: tiền không bao giờ đi qua số thực.
//
// Nguồn: CGShopSellHandler.cpp và CGShopRepairHandler.cpp của 2008.
//   Bán: giá = giá_gốc * số_lượng * hệ_số_A * (độ_bền_hiện_tại / độ_bền_tối_đa) / (số_lần_sửa_hỏng + 1) * tỉ_lệ_cửa_hàng
//        với hệ_số_A = 1/3 cho đồ đã giám định hay không cần giám định, 1/10 cho đồ lam chưa giám định.
//   Sửa: phí = REPAIR_SPEND(1) * (1 - hiện_tại/tối_đa) * giá_gốc * chi_phí_sửa_của_cửa_hàng, làm tròn nửa lên.
// Khác gốc: hệ số A đọc từ dev/server/config/rules/economy.toml ([price] identified_sale_permille = 250 và
// unidentified_sale_permille = 100, số của XJL7457) thay cho hằng 1/3 và 1/10 của 2008; tỉ lệ cửa hàng và chi phí sửa
// tính theo phần nghìn (1000 = 1,0). Làm tròn xuống ở cuối như phép ép (INT) của 2008, một phép chia duy nhất
// nên không sai lệch tích luỹ. Bảng RepairRate.txt (shared/repair_rates.tsv) của client 2026 chưa dùng: công thức
// phí hiển thị của client nằm trong mã máy, chưa kết luận được (docs/SERVER-ITEM.md).

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/types.hpp"

#include <cstdint>
#include <expected>

namespace game::item {

struct PriceRules {
    std::uint32_t identified_sale_permille = 250;
    std::uint32_t unidentified_sale_permille = 100;
};

inline constexpr std::uint32_t kPermille = 1000;

// Tiền NPC trả cho cả chồng `item` (count cái). Lỗi: kForbidden (rule.sell tắt), kBadAmount (tràn).
[[nodiscard]] std::expected<std::int64_t, Error> sell_value(const Template& tmpl, const Instance& item,
    const PriceRules& rules, std::uint32_t shop_scale_permille);

// Phí sửa về đủ độ bền; 0 khi không cần sửa hay mẫu không hao mòn. Lỗi: kBadAmount khi tràn.
[[nodiscard]] std::expected<std::int64_t, Error> repair_cost(const Template& tmpl, const Instance& item,
    std::uint32_t shop_repair_permille);

} // namespace game::item
