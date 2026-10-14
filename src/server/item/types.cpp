// Tên thuộc tính và câu mô tả lỗi của module item.
#include "item/types.hpp"

#include <array>
#include <cstddef>
#include <iterator>
#include <string_view>

namespace game::item {
namespace {

constexpr std::array<std::string_view, kAttrCount> kAttrNames{{
    "max_hp_bonus", "max_hp_percent", "hp_restore_speed",
    "max_mp_bonus", "max_mp_percent", "mp_restore_speed",
    "cold_attack", "cold_resist", "cold_slow_reduction",
    "fire_attack", "fire_resist", "fire_burn_reduction",
    "lightning_attack", "lightning_resist", "lightning_stun_reduction",
    "poison_attack", "poison_resist", "poison_time_reduction",
    "all_element_resist_percent", "physical_attack", "physical_attack_percent",
    "equip_base_physical_attack_percent", "physical_defence", "physical_defence_percent",
    "equip_base_physical_defence_percent", "physical_damage_resist_percent", "magic_attack",
    "magic_attack_percent", "equip_base_magic_attack_percent", "magic_defence",
    "magic_defence_percent", "equip_base_magic_defence_percent", "magic_damage_resist_percent",
    "attack_interval", "magic_cooldown_speed", "hit",
    "miss", "critical_hit", "ignore_defence_rate",
    "move_speed_percent", "damage_reflect", "damage_to_mana",
    "strength", "spirit", "stamina",
    "concentration", "dexterity", "critical_defence",
    "all_primary_attributes", "hp_steal", "mp_steal",
    "one_skill_level", "all_skill_levels", "special_skill_rate",
    "cold_resist_reduction", "fire_resist_reduction", "lightning_resist_reduction",
    "poison_resist_reduction", "base_physical_attack", "base_magic_attack",
    "base_physical_defence", "base_magic_defence", "base_hit",
    "base_miss",
}};

}  // namespace

std::array<std::string_view, kAttrCount> attr_names() noexcept {
    return kAttrNames;
}

std::string_view attr_name(AttrId id) noexcept {
    const std::size_t index = id.value();
    return index < kAttrCount ? *std::next(kAttrNames.begin(), static_cast<std::ptrdiff_t>(index)) : std::string_view{};
}

std::string_view describe(Place place) noexcept {
    switch (place) {
    case Place::kBaseBag: return "túi đạo cụ";
    case Place::kMaterialBag: return "túi nguyên liệu";
    case Place::kQuestBag: return "túi nhiệm vụ";
    case Place::kEquip: return "trang bị";
    case Place::kBank: return "kho";
    }
    return "không rõ";
}

std::string_view describe(Error error) noexcept {
    switch (error) {
    case Error::kUnknownTemplate: return "vật phẩm không có trong bảng";
    case Error::kBadCount: return "số lượng không hợp lệ";
    case Error::kNoSuchSlot: return "ô không tồn tại";
    case Error::kSlotEmpty: return "ô nguồn trống";
    case Error::kSlotOccupied: return "ô đích đã có đồ";
    case Error::kLocked: return "vật phẩm đang bị khoá";
    case Error::kBagFull: return "hết ô trống";
    case Error::kStackFull: return "chồng đã đầy";
    case Error::kNotStackable: return "vật phẩm không chồng được";
    case Error::kDifferentItems: return "hai vật phẩm khác loại";
    case Error::kWrongPlace: return "vật phẩm không để được ở nơi này";
    case Error::kNotEquipment: return "không phải trang bị";
    case Error::kWrongEquipSlot: return "sai điểm lắp";
    case Error::kLevelTooLow: return "chưa đủ cấp";
    case Error::kWrongSect: return "sai môn phái";
    case Error::kWrongSex: return "sai giới tính";
    case Error::kNotIdentified: return "chưa giám định";
    case Error::kForbidden: return "quy tắc vật phẩm không cho phép";
    case Error::kUniqueOwned: return "đã đạt giới hạn sở hữu";
    case Error::kInsufficientFunds: return "không đủ tiền";
    case Error::kOverCap: return "vượt trần ví";
    case Error::kNotEnoughItems: return "không đủ vật phẩm";
    case Error::kStalePlan: return "kế hoạch đã cũ";
    case Error::kBrokenPlan: return "kế hoạch hỏng";
    case Error::kBadAmount: return "số tiền không hợp lệ";
    case Error::kUnknownCurrency: return "loại tiền không có";
    case Error::kNoDurability: return "vật phẩm không có độ bền";
    case Error::kRepairFailed: return "đã hết lượt sửa";
    case Error::kSerialsExhausted: return "hết khối serial";
    case Error::kBadData: return "dữ liệu bảng hỏng";
    case Error::kBadBlob: return "bản ghi nhị phân hỏng";
    case Error::kNoChange: return "không có gì để đổi";
    case Error::kBadOrigin: return "nguồn sinh đồ ngoài miền";
    case Error::kNotOwner: return "không phải đồ của bạn";
    case Error::kBoxExpired: return "gói đồ đã biến mất";
    case Error::kNoSuchEntry: return "mục không tồn tại";
    case Error::kSoldOut: return "hàng đã bán hết";
    case Error::kShopRefuses: return "cửa hàng không nhận món này";
    case Error::kWrongScene: return "cửa hàng không mở được ở cảnh này";
    }
    return "lỗi không rõ";
}

}  // namespace game::item
