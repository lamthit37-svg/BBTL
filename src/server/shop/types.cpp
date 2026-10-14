// Phạm vi thu mua và sửa của cửa hàng: xem types.hpp.
#include "shop/types.hpp"

#include "item/catalog.hpp"
#include "item/types.hpp"

#include <cstdint>

namespace game::shop {
namespace {

// ITEM_CLASS của 2008 (GameDefine_Item.h): 1 trang bị, 2 nguyên liệu, 3 thuốc và đồ ăn.
constexpr std::uint8_t kClassEquip = 1;
constexpr std::uint8_t kClassMaterial = 2;
constexpr std::uint8_t kClassCommon = 3;

// HUMAN_EQUIP của 2008: 0 vũ khí, 1..4 phòng cụ, 5..8 trang sức. Điểm lắp mới của client 2026 (9..23) không thuộc loại
// nào nên chỉ cửa hàng nhận "mọi thứ" mới sửa được chúng.
constexpr std::uint8_t kFirstDefence = 1;
constexpr std::uint8_t kLastDefence = 4;
constexpr std::uint8_t kFirstAdorn = 5;
constexpr std::uint8_t kLastAdorn = 8;

} // namespace

bool covers_point(Scope scope, std::uint8_t point) noexcept {
    switch (scope) {
    case Scope::kAll: return true;
    case Scope::kDefence: return point >= kFirstDefence && point <= kLastDefence;
    case Scope::kAdorn: return point >= kFirstAdorn && point <= kLastAdorn;
    case Scope::kWeapon: return point == item::kEquipWeapon;
    case Scope::kNone:
    case Scope::kFood:
    case Scope::kMaterial:
    case Scope::kMedicine: return false;
    }
    return false;
}

bool accepts(Scope scope, const item::Template& tmpl) noexcept {
    switch (scope) {
    case Scope::kNone: return false;
    case Scope::kAll: return true;
    case Scope::kDefence:
    case Scope::kAdorn:
    case Scope::kWeapon: return tmpl.item_class == kClassEquip && covers_point(scope, tmpl.equip.point);
    case Scope::kFood:
    case Scope::kMedicine: return tmpl.item_class == kClassCommon;
    case Scope::kMaterial: return tmpl.item_class == kClassMaterial;
    }
    return false;
}

} // namespace game::shop
