#pragma once
// Tổng thuộc tính cộng của trang bị đang mặc, trả dạng danh sách {id thuộc tính, giá trị} thô. Module actor (vai
// khác) ghép id với chỉ số nhân vật bằng tên thuộc tính (attr_name), item không biết chỉ số nhân vật là gì.
//
// Nguồn: Obj_Human::ItemEffectFlush và Obj_Human_Calc.cpp của 2008: món hết độ bền (GetDurPoints() == 0) không
// cho thuộc tính. Khác gốc: thuộc tính ngẫu nhiên của đồ lam chưa giám định không tính (2008 cũng không cho mặc đồ lam
// chưa giám định, bản này chặn ở Planner::equip nên nhánh ấy chỉ đề phòng dữ liệu nạp từ ngoài); đá gắn tính theo
// thuộc tính trong GemInfo.txt của đá.

#include "item/catalog.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include <vector>

namespace game::item {

// Cộng gộp theo id, xếp tăng theo id, bỏ giá trị 0; giá trị kẹp trong int32.
[[nodiscard]] std::vector<AttrValue> equipment_bonuses(const Inventory& inventory, const Catalog& catalog);

} // namespace game::item
