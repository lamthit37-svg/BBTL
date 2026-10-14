#pragma once
// Giới hạn của túi, kho và ví: cỡ từng nơi chứa, số ô mở sẵn, trần từng loại tiền.
//
// Nguồn: dev/server/tables/server/item_limits.tsv, mỗi dòng ghi `basis` (client_lua, source_2008 hay made_up)
// để chủ dự án duyệt số tự đặt. Trần vàng theo cấp lấy từ shared/money_caps_by_level.tsv (LvMaxMoney.txt của
// client 2026; 2008 cũng đọc bảng này ở Obj_Human). Thiếu bảng thì Limits::defaults() cho đúng các số trong
// item_limits.tsv để test không cần tệp.

#include "item/types.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::item {

// Nội dung hai bảng; gold_caps có thể rỗng.
struct LimitSources {
    std::string_view limits{};     // server/item_limits.tsv
    std::string_view gold_caps{};  // shared/money_caps_by_level.tsv
};

struct Limits {
    std::array<std::uint16_t, kPlaceCount> capacity{};  // tổng số ô của từng nơi chứa (kEquip luôn kEquipSlots)
    std::array<std::uint16_t, kPlaceCount> unlocked{};  // số ô đang mở lúc nhân vật mới
    std::array<std::int64_t, kCurrencySlots> currency_cap{};  // trần mỗi loại tiền; 0 = loại không dùng
    std::int64_t bank_gold_cap = 0;
    std::vector<std::int64_t> gold_cap_by_level;  // chỉ số = cấp - 1; rỗng thì dùng currency_cap[kGold]

    [[nodiscard]] static Limits defaults();

    [[nodiscard]] static std::expected<Limits, std::string> load(const LimitSources& sources);

    // Trần vàng của người ở cấp `level` (cấp ngoài bảng lấy dòng gần nhất).
    [[nodiscard]] std::int64_t gold_cap(std::uint32_t level) const noexcept;
};

} // namespace game::item
