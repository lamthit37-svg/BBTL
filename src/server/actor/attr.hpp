#pragma once
// Từ điển thuộc tính của thân thể (người, quái): id thuộc tính vật phẩm giữ ĐÚNG số của bản gốc,
// chỉ số dẫn xuất (Stat) giữ đúng thứ tự CharIntAttrs_T của GameServer 2008.
//
// Nguồn: Common/GameDefine_Item.h (ITEM_ATTRIBUTE), GameServer/Obj/Attributes.h (CharIntAttrs_T,
// CharBoolAttrs_T), Obj_Human_Calc.cpp (CaculateEffect). Tên và nghĩa của dòng 33..59 theo cột tên của
// ItemValue.txt (XJL7457) vì client 2026 mô tả đúng như vậy; riêng ba dòng 51..53 bản 2008 gọi là
// USESKILL/RAND_SKILL/SKILL_RATE nhưng dữ liệu hai bản 14 và 2026 đã đổi nghĩa thành "cộng cấp kỹ
// năng". Module vật phẩm trả về cặp thô {attr_id: u16, value: i32}; actor là nơi duy nhất hiểu nghĩa.

#include "actor/numeric.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::actor {

// Id thuộc tính vật phẩm. Số = hàng của item_attribute_value_ranges.tsv.
enum class AttrId : std::uint8_t {
    kPointMaxHp = 0,       // Cộng điểm HP tối đa.
    kRateMaxHp = 1,        // Cộng phần trăm HP tối đa (trên giá trị gốc theo môn phái).
    kRestoreHp = 2,        // Hồi HP mỗi nhịp.
    kPointMaxMp = 3,
    kRateMaxMp = 4,
    kRestoreMp = 5,
    kColdAttack = 6,       // Công băng.
    kColdResist = 7,       // Kháng băng.
    kColdTime = 8,         // Giảm thời gian băng/chậm.
    kFireAttack = 9,
    kFireResist = 10,
    kFireTime = 11,        // Giảm thời gian thiêu đốt/suy yếu.
    kLightAttack = 12,     // Công "điện" (client 2026 gọi là Huyền).
    kLightResist = 13,
    kLightTime = 14,       // Giảm thời gian choáng.
    kPoisonAttack = 15,
    kPoisonResist = 16,
    kPoisonTime = 17,      // Giảm thời gian trúng độc.
    kResistAll = 18,       // Cộng cùng lúc kháng bốn hệ.
    kAttackP = 19,         // Ngoại công.
    kRateAttackP = 20,     // % ngoại công trên giá trị gốc.
    kRateAttackEp = 21,    // % ngoại công cộng thêm trên điểm ngoại công gốc của chính trang bị.
    kDefenceP = 22,
    kRateDefenceP = 23,
    kRateDefenceEp = 24,
    kImmunityP = 25,       // % miễn ngoại công (kẹp 0..100).
    kAttackM = 26,         // Nội công.
    kRateAttackM = 27,
    kRateAttackEm = 28,
    kDefenceM = 29,
    kRateDefenceM = 30,
    kRateDefenceEm = 31,
    kImmunityM = 32,
    kAttackSpeed = 33,     // Giảm khoảng cách hai đòn đánh.
    kSkillTime = 34,       // Tốc độ hồi chiêu (cooldown ngắn đi).
    kHit = 35,
    kMiss = 36,
    kCritical = 37,        // Điểm hội tâm.
    kNoDefenceRate = 38,   // Xác suất % bỏ qua phòng thủ đối phương.
    kSpeedRate = 39,       // Cộng tốc độ chạy (đơn vị của kStat::kMoveSpeed).
    kDamageReturn = 40,    // % sát thương phản lại.
    kDamageToMana = 41,    // % sát thương trừ vào nội lực trước.
    kStr = 42,
    kSpr = 43,
    kCon = 44,
    kInt = 45,
    kDex = 46,
    kLuck = 47,            // Ngộ tính (bản gốc cộng nhưng không dùng vào công thức nào).
    kAllBase = 48,         // Cộng cả sáu thuộc tính một cấp.
    kHpThieve = 49,        // % sát thương hút thành HP.
    kMpThieve = 50,
    kSkillLevel = 51,      // Cộng cấp một kỹ năng (kỹ năng nào nằm ở dữ liệu trang bị, ngoài actor).
    kAllSkillLevel = 52,   // Cộng cấp mọi kỹ năng.
    kSkillRate = 53,       // Xác suất phát kỹ năng đặc biệt.
    kBaseAttackP = 54,     // Điểm ngoại công gốc của vũ khí.
    kBaseAttackM = 55,
    kBaseAttackTime = 56,  // Khoảng cách đòn đánh gốc, chỉ đòn thường.
    kBaseDefenceP = 57,
    kBaseDefenceM = 58,
    kBaseMiss = 59,
};
inline constexpr std::size_t kAttrIdCount = 60;

[[nodiscard]] constexpr std::optional<AttrId> attr_id_of(std::uint32_t raw) noexcept {
    if (raw >= kAttrIdCount) return std::nullopt;
    return static_cast<AttrId>(raw);
}

// Chỉ số dẫn xuất, thứ tự đúng CharIntAttrs_T (39 chỉ số), thêm kCriticalDefence ở cuối. Các kiểu CAMP, MODEL_ID, MOUNT_ID,
// STEALTH, DETECT, EXP_REFIX nằm cùng không gian để buff chỉnh được như bản gốc.
enum class Stat : std::uint8_t {
    kStr,
    kSpr,
    kCon,
    kInt,
    kDex,
    kMaxHp,
    kHpRegen,
    kMaxMp,
    kMpRegen,
    kMaxStrikePoint,
    kMaxRage,
    kCamp,
    kModelId,
    kMountId,
    kExpRefix,
    kStealthLevel,
    kDetectLevel,
    kAttackPhy,
    kDefencePhy,
    kAttackMagic,
    kDefenceMagic,
    kAttackCold,
    kResistCold,
    kAttackFire,
    kResistFire,
    kAttackLight,
    kResistLight,
    kAttackPoison,
    kResistPoison,
    kMiss,
    kHit,
    kCritical,
    kMoveSpeed,
    kAttackSpeed,
    kReduceSlowerDuration,
    kReduceWeakenDuration,
    kReduceFaintDuration,
    kReducePoisonedDuration,
    kVisionRange,
    kCriticalDefence, // hội tâm phòng: chỉ có ở bảng hệ số của dữ liệu hiện hành, mã 2008 chưa có
};
inline constexpr std::size_t kStatCount = 40;

// Cờ logic, đúng thứ tự CharBoolAttrs_T.
enum class Flag : std::uint8_t {
    kAlive,
    kInCombat,
    kCanMove,
    kCanAction1,
    kCanAction2,
    kDisableFlag2,
    kUnbreakable,
    kInStealthMode,
    kCanDetectStealth,
};
inline constexpr std::size_t kFlagCount = 9;

// Điểm thuộc tính cấp một của nhân vật, đúng thứ tự CHAR_ATTR_LEVEL1.
inline constexpr std::size_t kPrimaryCount = 5;
inline constexpr std::array<Stat, kPrimaryCount> kPrimaryStats{Stat::kStr, Stat::kSpr, Stat::kCon, Stat::kInt,
    Stat::kDex};

// Một dòng thuộc tính do module vật phẩm trao: id thô, chưa kiểm.
struct AttrEntry {
    std::uint16_t attr_id = 0;
    std::int32_t value = 0;

    friend constexpr bool operator==(const AttrEntry&, const AttrEntry&) noexcept = default;
};

// Một thuộc tính vật phẩm cộng vào chỉ số nào và theo cách nào.
enum class AttrKind : std::uint8_t {
    kNone,        // Không vào chỉ số dẫn xuất (xem AttrInfo::special).
    kPoint,       // Cộng thẳng.
    kRateOfBase,  // value% của giá trị gốc theo môn phái.
    kRateOfEquip, // value% của điểm gốc trang bị (kBase*).
    kEquipBase,   // Điểm gốc của trang bị, cộng thẳng và còn làm đáy cho kRateOfEquip.
};

// Mẫu số của kRateOfBase/kRateOfEquip là 100 (phần trăm). Bản gốc dùng 1000 ở ba dòng nội công
// (Obj_Human_Attributes.cpp:1043..1060) nhưng dữ liệu cùng thang với ngoại công, nên actor dùng 100 cho cả
// hai (Khác gốc, ghi ở docs/SERVER-COMBAT.md).
struct AttrInfo {
    constexpr AttrInfo(Stat stat_in, AttrKind kind_in) noexcept : stat(stat_in), kind(kind_in) {}

    Stat stat;
    AttrKind kind;
};

[[nodiscard]] constexpr AttrInfo info_of(AttrId id) noexcept {
    using S = Stat;
    using K = AttrKind;
    switch (id) {
    case AttrId::kPointMaxHp: return {S::kMaxHp, K::kPoint};
    case AttrId::kRateMaxHp: return {S::kMaxHp, K::kRateOfBase};
    case AttrId::kRestoreHp: return {S::kHpRegen, K::kPoint};
    case AttrId::kPointMaxMp: return {S::kMaxMp, K::kPoint};
    case AttrId::kRateMaxMp: return {S::kMaxMp, K::kRateOfBase};
    case AttrId::kRestoreMp: return {S::kMpRegen, K::kPoint};
    case AttrId::kColdAttack: return {S::kAttackCold, K::kPoint};
    case AttrId::kColdResist: return {S::kResistCold, K::kPoint};
    case AttrId::kColdTime: return {S::kReduceSlowerDuration, K::kPoint};
    case AttrId::kFireAttack: return {S::kAttackFire, K::kPoint};
    case AttrId::kFireResist: return {S::kResistFire, K::kPoint};
    case AttrId::kFireTime: return {S::kReduceWeakenDuration, K::kPoint};
    case AttrId::kLightAttack: return {S::kAttackLight, K::kPoint};
    case AttrId::kLightResist: return {S::kResistLight, K::kPoint};
    case AttrId::kLightTime: return {S::kReduceFaintDuration, K::kPoint};
    case AttrId::kPoisonAttack: return {S::kAttackPoison, K::kPoint};
    case AttrId::kPoisonResist: return {S::kResistPoison, K::kPoint};
    case AttrId::kPoisonTime: return {S::kReducePoisonedDuration, K::kPoint};
    case AttrId::kAttackP: return {S::kAttackPhy, K::kPoint};
    case AttrId::kRateAttackP: return {S::kAttackPhy, K::kRateOfBase};
    case AttrId::kRateAttackEp: return {S::kAttackPhy, K::kRateOfEquip};
    case AttrId::kDefenceP: return {S::kDefencePhy, K::kPoint};
    case AttrId::kRateDefenceP: return {S::kDefencePhy, K::kRateOfBase};
    case AttrId::kRateDefenceEp: return {S::kDefencePhy, K::kRateOfEquip};
    case AttrId::kAttackM: return {S::kAttackMagic, K::kPoint};
    case AttrId::kRateAttackM: return {S::kAttackMagic, K::kRateOfBase};
    case AttrId::kRateAttackEm: return {S::kAttackMagic, K::kRateOfEquip};
    case AttrId::kDefenceM: return {S::kDefenceMagic, K::kPoint};
    case AttrId::kRateDefenceM: return {S::kDefenceMagic, K::kRateOfBase};
    case AttrId::kRateDefenceEm: return {S::kDefenceMagic, K::kRateOfEquip};
    case AttrId::kAttackSpeed: return {S::kAttackSpeed, K::kPoint};
    case AttrId::kHit: return {S::kHit, K::kPoint};
    case AttrId::kMiss: return {S::kMiss, K::kPoint};
    case AttrId::kCritical: return {S::kCritical, K::kPoint};
    case AttrId::kSpeedRate: return {S::kMoveSpeed, K::kPoint};
    case AttrId::kStr: return {S::kStr, K::kPoint};
    case AttrId::kSpr: return {S::kSpr, K::kPoint};
    case AttrId::kCon: return {S::kCon, K::kPoint};
    case AttrId::kInt: return {S::kInt, K::kPoint};
    case AttrId::kDex: return {S::kDex, K::kPoint};
    case AttrId::kBaseAttackP: return {S::kAttackPhy, K::kEquipBase};
    case AttrId::kBaseAttackM: return {S::kAttackMagic, K::kEquipBase};
    case AttrId::kBaseDefenceP: return {S::kDefencePhy, K::kEquipBase};
    case AttrId::kBaseDefenceM: return {S::kDefenceMagic, K::kEquipBase};
    case AttrId::kBaseMiss: return {S::kMiss, K::kEquipBase};
    default: return {S::kStr, K::kNone};
    }
}

// Tên ASCII ổn định của chỉ số, cho nhật ký và công cụ.
[[nodiscard]] constexpr std::string_view stat_name(Stat stat) noexcept {
    constexpr std::array<std::string_view, kStatCount> kNames{"str", "spr", "con", "int", "dex", "max_hp", "hp_regen",
        "max_mp", "mp_regen", "max_strike_point", "max_rage", "camp", "model_id", "mount_id", "exp_refix",
        "stealth_level", "detect_level", "attack_phy", "defence_phy", "attack_magic", "defence_magic",
        "attack_cold", "resist_cold", "attack_fire", "resist_fire", "attack_light", "resist_light",
        "attack_poison", "resist_poison", "miss", "hit", "critical", "move_speed", "attack_speed",
        "reduce_slower_duration", "reduce_weaken_duration", "reduce_faint_duration", "reduce_poisoned_duration",
        "vision_range", "critical_defence"};
    const auto index = static_cast<std::size_t>(stat);
    return index < kNames.size() ? slot(kNames, index) : std::string_view{};
}

} // namespace game::actor
