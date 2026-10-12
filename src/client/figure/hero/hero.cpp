#include "hero/hero.hpp"

#include <algorithm>
#include <cstdint>

namespace game::hero {
namespace {

// Nhân vật mới của máy chủ gốc (Server/Config/DefaultChar.ini): cấp 1, chưa môn phái (menpai 9),
// sức mạnh 7, linh khí 6, thể lực 5, định lực 5, thân pháp 2, hoạt lực và tinh lực 10/50.
constexpr Roots kFirstRoots{.strength = 7, .spirit = 6, .constitution = 5, .stability = 5, .agility = 2};
constexpr std::int32_t kFirstLevel = 1;
constexpr Gauge kFirstVigor{.now = 10, .top = 50};

// Một dòng của BaseValueTable.ini: số gốc, hệ số theo chỉ số gốc, hệ số theo cấp, đều đã nhân 100.
struct Scale {
    std::int32_t base = 0;
    std::int32_t per_root = 0;
    std::int32_t per_level = 0;
};

// Obj_Human_Attributes.cpp: Float2Int((gốc + chỉ số x hệ số + cấp x hệ số) / 100.0f), số âm thì 0.
// Float2Int làm tròn nửa lên; với tổng không âm thì bằng (tổng + 50) / 100 trên số nguyên.
constexpr std::int32_t derived(Scale scale, std::int32_t root) noexcept {
    const std::int32_t grown = (root * scale.per_root) + (kFirstLevel * scale.per_level);
    return std::max((scale.base + grown + 50) / 100, 0);
}

// Hệ số [MENPAI9] của BaseValueTable.ini, theo thứ tự AINFOTYPE0..35.
constexpr Scale kHealth{.base = 25000, .per_root = 5500, .per_level = 6000};
constexpr Scale kMana{.base = 13500, .per_root = 2900, .per_level = 3000};
constexpr Scale kAttack{.base = 1523, .per_root = 507, .per_level = 507};
constexpr Scale kDefence{.base = 1523, .per_root = 507, .per_level = 507};
constexpr Scale kHit{.base = 1500, .per_root = 750, .per_level = 750};
constexpr Scale kMiss{.base = 500, .per_root = 250, .per_level = 250};
constexpr Scale kCritical{.base = 100, .per_root = 5, .per_level = 5};

constexpr std::int64_t kHealthTop = derived(kHealth, kFirstRoots.constitution);
constexpr std::int64_t kManaTop = derived(kMana, kFirstRoots.stability);
// MAXRAGE của client gốc là hằng 1000 (GMGameInterface_Script_PlayerMySelf.cpp).
constexpr std::int64_t kRageTop = 1000;
// Kinh nghiệm cần để lên cấp 2: dòng cấp 1 của Config/PlayerExpLevel.txt (client 2026).
constexpr std::int64_t kFirstLevelNeed = 90;
// Chân dung nữ đầu tiên của Config/CharacterFace.txt; người chơi mặc định của client là nữ.
constexpr PortraitId kFirstPortrait{1};

static_assert(kHealthTop == 585);
static_assert(kManaTop == 310);
static_assert(derived(kAttack, kFirstRoots.strength) == 56, "55,79 làm tròn lên");
static_assert(derived(kHit, kFirstRoots.agility) == 38, "37,5 làm tròn nửa lên");
static_assert(derived(kCritical, kFirstRoots.agility) == 1, "1,15 làm tròn xuống");

constexpr Combat first_combat() noexcept {
    Combat combat;
    combat.attack_physical = derived(kAttack, kFirstRoots.strength);
    combat.attack_magic = derived(kAttack, kFirstRoots.spirit);
    combat.defence_physical = derived(kDefence, kFirstRoots.constitution);
    combat.defence_magic = derived(kDefence, kFirstRoots.stability);
    combat.hit = derived(kHit, kFirstRoots.agility);
    combat.miss = derived(kMiss, kFirstRoots.agility);
    combat.critical_attack = derived(kCritical, kFirstRoots.agility);
    combat.critical_defence = derived(kCritical, kFirstRoots.agility);
    return combat;
}

} // namespace

Hero newcomer() {
    Hero hero;
    hero.name = "#{GMGameInterface_Script_Talk_Info_R_Man}";
    hero.level = 1;
    hero.health = Gauge{.now = kHealthTop, .top = kHealthTop};
    hero.mana = Gauge{.now = kManaTop, .top = kManaTop};
    hero.rage = Gauge{.now = 0, .top = kRageTop};
    hero.experience = Gauge{.now = 0, .top = kFirstLevelNeed};
    hero.portrait = kFirstPortrait;
    hero.sect = Sect::kNone;
    hero.roots = kFirstRoots;
    hero.combat = first_combat();
    hero.vigor = kFirstVigor;
    hero.energy = kFirstVigor;
    return hero;
}

} // namespace game::hero
