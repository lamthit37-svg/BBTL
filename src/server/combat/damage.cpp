// Công thức sát thương (xem damage.hpp).
#include "combat/damage.hpp"

#include "actor/numeric.hpp"
#include "combat/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace game::combat {
namespace {

using actor::clamp32;
using actor::round_ratio;
using actor::saturate32;

constexpr std::int32_t kLowGeneral = 1;     // LL_GENERAL_ATTACK_DEFENCE
constexpr std::int32_t kLowTrait = 0;       // LL_TRAIT_ATTACK

// atk²/(atk+def) bằng số nguyên 64 bit, cắt xuống như phép chia int của bản gốc. Khác gốc: bản gốc nhân int32
// nên tràn khi atk > 46340; ở đây dùng 64 bit rồi kẹp về int32.
[[nodiscard]] std::int32_t ratio_damage(std::int64_t attack, std::int64_t defence) noexcept {
    const std::int64_t sum = attack + defence;
    if (sum == 0) return 0;
    return saturate32(attack * attack / sum);
}

// Trừ miễn nhiễm: phần trăm kẹp 0..100. Ngoại công cắt xuống (chia int), nội công làm tròn (chia float).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): sát thương và phần trăm khác vai (HP-07)
[[nodiscard]] std::int32_t minus_immunity_trunc(std::int32_t damage, std::int32_t percent) noexcept {
    const std::int32_t rate = clamp32(percent, 0, 100);
    const std::int64_t cut = static_cast<std::int64_t>(damage) * rate / 100;
    return std::max<std::int32_t>(0, saturate32(damage - cut));
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): sát thương và phần trăm khác vai (HP-07)
[[nodiscard]] std::int32_t minus_immunity_round(std::int32_t damage, std::int32_t percent) noexcept {
    const std::int32_t rate = clamp32(percent, 0, 100);
    const std::int64_t cut = round_ratio(static_cast<std::int64_t>(damage) * rate, 100);
    return std::max<std::int32_t>(0, saturate32(damage - cut));
}

} // namespace

std::int32_t verify_general(std::int64_t value) noexcept {
    return saturate32(std::max<std::int64_t>(value, kLowGeneral));
}

std::int32_t verify_trait(std::int64_t value) noexcept {
    return saturate32(std::max<std::int64_t>(value, kLowTrait));
}

std::int32_t verify_resist(std::int64_t value) noexcept { return clamp32(value, kMinResist, kMaxResist); }

std::int32_t verify_hit_miss(std::int64_t value) noexcept { return clamp32(value, kMinHitMiss, kMaxHitMiss); }

std::int32_t verify_critical(std::int64_t value) noexcept { return clamp32(value, 0, kMaxCritical); }

std::int32_t hit_rate(std::int64_t hit, std::int64_t miss) noexcept {
    const std::int64_t h = verify_hit_miss(hit);
    const std::int64_t m = verify_hit_miss(miss);
    if (h + m == 0) return 0;
    return saturate32(h * 100 / (h + m));
}

bool is_hit(std::int64_t rate, std::int32_t roll) noexcept { return roll < clamp32(rate, 0, 100); }

bool is_critical(std::int64_t rate, std::int32_t roll) noexcept { return roll < verify_critical(rate); }

ChannelDamage channel_damage(const AttackerView& attacker, const DefenderView& defender,
    const Additions& additions) noexcept {
    ChannelDamage out;
    const std::int64_t phy_attack = verify_general(static_cast<std::int64_t>(attacker.attack_phy) + additions.attack[Channel::kPhysical]);
    const std::int64_t phy_defence = verify_general(static_cast<std::int64_t>(defender.defence_phy) + additions.defence[Channel::kPhysical]);
    out[Channel::kPhysical] = minus_immunity_trunc(ratio_damage(phy_attack, phy_defence), defender.immunity_phy);

    const std::int64_t mag_attack = verify_general(static_cast<std::int64_t>(attacker.attack_magic) + additions.attack[Channel::kMagic]);
    const std::int64_t mag_defence = verify_general(static_cast<std::int64_t>(defender.defence_magic) + additions.defence[Channel::kMagic]);
    out[Channel::kMagic] = minus_immunity_round(ratio_damage(mag_attack, mag_defence), defender.immunity_magic);

    for (const Element element : {Element::kCold, Element::kFire, Element::kLight, Element::kPoison}) {
        const Channel channel = channel_of(element);
        const std::int64_t attack = verify_trait(static_cast<std::int64_t>(attacker.attack_element[element]) + additions.attack[channel]);
        // Khác gốc: giảm kháng của kẻ tấn công (buff, thuộc tính quái) trừ vào kháng trước khi kẹp.
        const std::int64_t resist_raw = static_cast<std::int64_t>(defender.resist_element[element]) + additions.defence[channel]
            - attacker.resist_reduce[element];
        const std::int64_t resist = std::clamp<std::int64_t>(verify_resist(resist_raw), -kMaxEffectiveResist, kMaxEffectiveResist);
        const std::int64_t damage = attack * (100 - resist) / 100;
        out[channel] = saturate32(std::max<std::int64_t>(damage, 0));
    }
    return out;
}

std::int32_t fluctuation_percent(std::int32_t amplitude, std::int32_t roll) noexcept {
    return saturate32(round_ratio(2 * static_cast<std::int64_t>(amplitude) * (50 - roll), 100));
}

std::int32_t apply_fluctuation(std::int32_t value, std::int32_t percent) noexcept {
    return saturate32(static_cast<std::int64_t>(value) + (static_cast<std::int64_t>(value) * percent / 100));
}

std::int32_t refix_percent(std::int64_t value, std::int64_t percent) noexcept {
    return saturate32(round_ratio(value * (100 + percent), 100));
}

std::int64_t total(const ChannelDamage& damage) noexcept {
    std::int64_t sum = 0;
    for (std::size_t i = 0; i < kChannelCount; ++i) sum += damage[static_cast<Channel>(i)];
    return sum;
}

} // namespace game::combat
