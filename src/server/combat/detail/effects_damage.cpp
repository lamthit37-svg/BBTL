// Mã logic hiệu ứng gây sát thương, hồi phục và phát hiệu ứng con: damage_flat, damage_percent, damage_attack,
// restore_value, restore_rate, steal, hp_threshold, explosion, interval_aoe, composite.
//
// Nguồn: GameServer 2008 StdImpact001..005, 010 (cùng số logic); logic 67, 68, 70, 86 chỉ có ở dữ liệu client 2026,
// nghĩa tham số lấy từ cột mô tả trong effects.tsv (docs/SERVER-COMBAT.md). Khác gốc ghi tại chỗ.
#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/damage.hpp"
#include "combat/detail/effects.hpp"
#include "combat/detail/effects_impl.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <functional>
#include <memory>
#include <vector>

namespace game::combat::detail {
namespace {

using actor::round_ratio;
using actor::saturate32;

// Hai sát thương phần trăm: v * pct / 100 làm tròn kiểu Float2Int.
[[nodiscard]] std::int32_t percent_of(std::int64_t value, std::int64_t percent) noexcept {
    return saturate32(round_ratio(value * percent, 100));
}

// Trần khi hiệu ứng vùng không khai số mục tiêu tối đa.
[[nodiscard]] std::size_t target_cap(std::int32_t declared) noexcept {
    return declared > 0 ? std::min<std::size_t>(static_cast<std::size_t>(declared), kMaxScanTargets) : kMaxScanTargets;
}

// ---------------------------------------------------------------------------------------------------------

// Logic 1: sát thương thẳng một số. slot[0] = sát thương.
class DamageFlat final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        set_slot(buff, 0, refix_percent(slot_of(buff, 0), percent));
        return true;
    }

    void critical_refix(Buff& buff, const Effect& /*effect*/) const override {
        set_slot(buff, 0, saturate32(static_cast<std::int64_t>(slot_of(buff, 0)) * 2));
        buff.critical = true;
    }

    void on_active(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        ctx.arena.damage_flat(ctx.me, ctx.buff.caster, slot_of(ctx.buff, 0), ctx.buff.critical, ctx.buff.skill);
    }
};

// Logic 2: sát thương theo phần trăm HP tối đa. slot[0] = phần trăm.
// Khác gốc: bản 2008 lấy GetBaseMaxHP (HP gốc theo phái, không buff); Body chỉ giữ HP tối đa cuối cùng nên dùng giá
// trị ấy. Dữ liệu chỉ có 3 dòng logic này.
class DamagePercent final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        set_slot(buff, 0, refix_percent(slot_of(buff, 0), percent));
        return true;
    }

    void critical_refix(Buff& buff, const Effect& /*effect*/) const override {
        set_slot(buff, 0, saturate32(static_cast<std::int64_t>(slot_of(buff, 0)) * 2));
        buff.critical = true;
    }

    void on_active(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        const std::int32_t damage = percent_of(ctx.me.body.stat(actor::Stat::kMaxHp), slot_of(ctx.buff, 0));
        ctx.arena.damage_flat(ctx.me, ctx.buff.caster, damage, ctx.buff.critical, ctx.buff.skill);
    }
};

// Logic 3: sát thương sáu kênh + sát thương thẳng. slot[0..5] = ngoại, nội, băng, hỏa, điện, độc; slot[6] = thẳng.
// Nằm trong kỹ năng (computed): tham số 0..5 là điểm công cộng thêm, compute() đổi slot[0..5] thành sát thương thật
// sau khi áp công thức; tham số 6 là sát thương thẳng cộng sau hook. Gửi từ buff/bẫy (không computed): tham số là
// sát thương cuối của từng kênh.
class DamageAttack final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, param_of(effect, i));
    }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, refix_percent(slot_of(buff, i), percent));
        return true;
    }

    void critical_refix(Buff& buff, const Effect& /*effect*/) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, saturate32(static_cast<std::int64_t>(slot_of(buff, i)) * 2));
        buff.critical = true;
    }

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): người ra chiêu rồi mục tiêu, khớp lớp cha, nơi gọi nêu tên (HP-07)
    void compute(Arena& arena, Fighter& caster, Fighter& target, Buff& buff, const Effect& /*effect*/) const override {
        Additions add;
        for (std::size_t i = 0; i < kChannelCount; ++i) add.attack[static_cast<Channel>(i)] = slot_of(buff, i);
        const AttackerView attacker = arena.attacker_view(caster);
        DefenderView defender = arena.defender_view(target);
        if (consume_ignore_defence(arena, caster)) {
            defender.defence_phy = 0;
            defender.defence_magic = 0;
        }
        const ChannelDamage base = channel_damage(attacker, defender, add);
        // Một lần rút dao động cho cả hiệu ứng (bản gốc rút một lần trong GetResultImpact).
        const std::int32_t swing = fluctuation_percent(attacker.fluctuation, arena.roll100());
        for (std::size_t i = 0; i < kChannelCount; ++i) {
            set_slot(buff, i, apply_fluctuation(base[static_cast<Channel>(i)], swing));
        }
    }

    void on_active(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        ChannelDamage amounts;
        for (std::size_t i = 0; i < kChannelCount; ++i) amounts[static_cast<Channel>(i)] = slot_of(ctx.buff, i);
        ctx.arena.damage_channels(ctx.me, ctx.buff.caster, amounts, slot_of(ctx.buff, kChannelCount), ctx.buff.critical,
            ctx.buff.skill);
    }

private:
    static constexpr std::size_t kSlots = kChannelCount + 1U;
};

// Logic 4: đổi HP/MP/nộ khí/liên kích theo số. slot[0..3] = HP, MP, nộ khí, điểm liên kích.
class RestoreValue final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, param_of(effect, i));
    }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, refix_percent(slot_of(buff, i), percent));
        return true;
    }

    void on_active(HookCtx& ctx) const override {
        Fighter& me = ctx.me;
        if (!me.alive()) return;
        apply(ctx.arena, me, ctx.buff.caster, ctx.buff.skill,
            Amounts{.hp = slot_of(ctx.buff, 0), .mp = slot_of(ctx.buff, 1), .rage = slot_of(ctx.buff, 2),
                .strike = slot_of(ctx.buff, 3)});
    }

    // Số cần đổi theo từng nguồn; dùng chung với restore_rate sau khi đổi phần trăm sang số.
    struct Amounts {
        std::int32_t hp = 0;
        std::int32_t mp = 0;
        std::int32_t rage = 0;
        std::int32_t strike = 0;
    };

    static void apply(Arena& arena, Fighter& me, ids::EntityHandle source, std::uint32_t skill, const Amounts& amounts) {
        if (amounts.hp > 0) {
            arena.heal(me, source, amounts.hp, skill);
        } else if (amounts.hp < 0) {
            arena.change_hp(me, source, amounts.hp);
        }
        if (!me.body.is_human()) return;  // bản gốc: MP, nộ khí, liên kích chỉ đổi cho người
        if (amounts.mp != 0) arena.change_mp(me, source, amounts.mp);
        if (amounts.rage != 0) arena.change_rage(me, source, amounts.rage);
        if (amounts.strike != 0) arena.change_strike(me, source, amounts.strike);
    }

private:
    static constexpr std::size_t kSlots = 4;
};

// Logic 5: đổi HP/MP/nộ khí/liên kích theo phần trăm mức tối đa.
// Khác gốc: bản 2008 cộng thêm 100 vào phần trăm HP (`nHP += 100`) nên giá trị 0 hồi đầy máu và OnHealTarget gọi qua
// con trỏ null; dữ liệu 2026 ("pháp lực thiêu đốt" -mp) dùng giá trị là phần trăm thật, nên bỏ phép cộng 100.
class RestoreRate final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, param_of(effect, i));
    }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        for (std::size_t i = 0; i < kSlots; ++i) set_slot(buff, i, refix_percent(slot_of(buff, i), percent));
        return true;
    }

    void on_active(HookCtx& ctx) const override {
        Fighter& me = ctx.me;
        if (!me.alive()) return;
        const actor::Body& body = me.body;
        RestoreValue::apply(ctx.arena, me, ctx.buff.caster, ctx.buff.skill,
            RestoreValue::Amounts{.hp = percent_of(body.stat(actor::Stat::kMaxHp), slot_of(ctx.buff, 0)),
                .mp = percent_of(body.stat(actor::Stat::kMaxMp), slot_of(ctx.buff, 1)),
                .rage = percent_of(body.stat(actor::Stat::kMaxRage), slot_of(ctx.buff, 2)),
                .strike = percent_of(body.stat(actor::Stat::kMaxStrikePoint), slot_of(ctx.buff, 3))});
    }

private:
    static constexpr std::size_t kSlots = 4;
};

// Logic 70: sát thương cộng hút HP/MP/nộ khí về người tạo. Tham số: 0 sát thương, 1 % HP gây ra chuyển cho người
// tạo, 2 MP mất, 3 % MP mất chuyển, 4 nộ khí mất, 5 % nộ khí mất chuyển.
class Steal final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        Fighter& me = ctx.me;
        if (!me.alive()) return;
        Arena& arena = ctx.arena;
        Fighter* caster = caster_of(ctx);
        const std::int32_t damage = scaled(ctx.buff, param_of(ctx.effect, 0));
        const std::int32_t hp_before = me.body.hp();
        if (damage > 0) arena.damage_flat(me, ctx.buff.caster, damage, ctx.buff.critical, ctx.buff.skill);
        const std::int64_t dealt = std::max(0, hp_before - me.body.hp());

        const std::int32_t mp_loss = scaled(ctx.buff, param_of(ctx.effect, 2));
        std::int64_t mp_taken = 0;
        if (mp_loss > 0 && me.body.is_human()) mp_taken = -static_cast<std::int64_t>(arena.change_mp(me, ctx.buff.caster, -mp_loss));
        const std::int32_t rage_loss = scaled(ctx.buff, param_of(ctx.effect, 4));
        std::int64_t rage_taken = 0;
        if (rage_loss > 0) rage_taken = -static_cast<std::int64_t>(arena.change_rage(me, ctx.buff.caster, -rage_loss));

        if (caster == nullptr || !caster->alive()) return;
        const std::int32_t hp_rate = param_of(ctx.effect, 1);
        const std::int32_t mp_rate = param_of(ctx.effect, 3);
        const std::int32_t rage_rate = param_of(ctx.effect, 5);
        if (hp_rate > 0 && dealt > 0) arena.heal(*caster, ctx.buff.caster, saturate32(round_ratio(dealt * hp_rate, 100)), ctx.buff.skill);
        if (mp_rate > 0 && mp_taken > 0 && caster->body.is_human()) arena.change_mp(*caster, ctx.buff.caster, round_ratio(mp_taken * mp_rate, 100));
        if (rage_rate > 0 && rage_taken > 0) arena.change_rage(*caster, ctx.buff.caster, round_ratio(rage_taken * rage_rate, 100));
    }
};

// Logic 67: một nhát theo HP hiện tại. Tham số: 0 xác suất %, 1 sát thương tối thiểu, 2 phần trăm HP hiện tại
// (âm là gây sát thương, dương là hồi).
class HpThreshold final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        Fighter& me = ctx.me;
        if (!me.alive() || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        const std::int32_t percent = param_of(ctx.effect, 2);
        const std::int64_t base = round_ratio(static_cast<std::int64_t>(me.body.hp()) * std::abs(static_cast<std::int64_t>(percent)), 100);
        if (percent < 0) {
            const std::int32_t damage = saturate32(std::max<std::int64_t>(base, param_of(ctx.effect, 1)));
            ctx.arena.damage_flat(me, ctx.buff.caster, damage, ctx.buff.critical, ctx.buff.skill);
        } else if (percent > 0) {
            ctx.arena.heal(me, ctx.buff.caster, saturate32(base), ctx.buff.skill);
        }
    }
};

// Chọn mục tiêu quanh `centre` cho các hiệu ứng vùng: sống, thoả `accept`. Gần trước, tối đa `cap`.
[[nodiscard]] std::vector<ids::EntityHandle> around(const HookCtx& ctx, Position centre, std::int32_t radius_m, std::size_t cap,
    const std::function<bool(const Fighter&)>& accept) {
    return ctx.arena.units_around(centre, radius_m * kCmPerMeter, cap, [&accept](const Fighter& other) {
        return other.alive() && accept(other);
    });
}

// Logic 68: nổ quanh người mang. Tham số: 0 bán kính (mét), 1 số mục tiêu tối đa, 2 hiệu ứng con (vai sub).
// Mục tiêu là mọi thực thể địch với người tạo (kể cả người mang); không còn người tạo thì là tất cả.
class Explosion final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        const Fighter* caster = caster_of(ctx);
        Arena& arena = ctx.arena;
        const std::vector<ids::EntityHandle> list = around(ctx, ctx.me.position, param_of(ctx.effect, 0), target_cap(param_of(ctx.effect, 1)),
            [&arena, caster](const Fighter& other) { return caster == nullptr || !arena.is_friend(*caster, other); });
        for (const ids::EntityHandle handle : list) {
            if (const Fighter* other = arena.find(handle)) send_roles(ctx, RoleKind::kSub, *other, true);
        }
    }
};

// Logic 86: vùng gây hiệu ứng theo chu kỳ quanh người mang. Tham số: 0 bán kính (mét), 1 số mục tiêu (-1: không
// giới hạn), 2 chọn mục tiêu (-1 địch, 0 trung lập, 1 bạn, 2 bạn và đồng đội), 3 có tính người mang không, 4 loại
// hiệu ứng chịu ảnh hưởng (chưa dùng), 5 sát thương dùng công thức chiến đấu, 6..8 hiệu ứng con.
// Khác gốc: không có trong mã 2008. "Đồng đội" cần module tổ đội: ở đây 2 coi như 1 (bạn); "trung lập" là mọi người
// còn lại ngoài địch và bạn của người tạo, mà ma trận phe chỉ có hai quan hệ nên coi như không chọn ai.
class IntervalAoe final : public RefixedLogic {
public:
    [[nodiscard]] bool intervaled() const noexcept override { return true; }

    void on_interval(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        const Fighter* caster = caster_of(ctx);
        Arena& arena = ctx.arena;
        const std::int32_t select = param_of(ctx.effect, 2);
        const bool include_self = param_of(ctx.effect, 3) == 1;
        const ids::EntityHandle self = ctx.me.handle;
        const std::vector<ids::EntityHandle> list = around(ctx, ctx.me.position, param_of(ctx.effect, 0), target_cap(param_of(ctx.effect, 1)),
            [&arena, caster, select, include_self, self](const Fighter& other) {
                if (other.handle == self) return include_self;
                if (caster == nullptr) return select == kStandHostile;
                const bool friendly = arena.is_friend(*caster, other);
                if (select == kStandHostile) return !friendly;
                return select >= kStandAmity && friendly;
            });
        const bool computed = param_of(ctx.effect, 5) != 0;
        for (const ids::EntityHandle handle : list) {
            if (const Fighter* other = arena.find(handle)) send_roles(ctx, RoleKind::kSub, *other, computed);
        }
    }
};

// Logic 10: buff phát hiệu ứng con lên người mang theo chu kỳ. Tham số 0..15 là id hiệu ứng con (vai sub).
class Composite final : public RefixedLogic {
public:
    [[nodiscard]] bool intervaled() const noexcept override { return true; }

    void on_interval(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        send_roles(ctx, RoleKind::kSub, ctx.me);
    }
};

} // namespace

void add_damage_effects(EffectRegistry& registry) {
    registry.add("damage_flat", std::make_unique<DamageFlat>());
    registry.add("damage_percent", std::make_unique<DamagePercent>());
    registry.add("damage_attack", std::make_unique<DamageAttack>());
    registry.add("restore_value", std::make_unique<RestoreValue>());
    registry.add("restore_rate", std::make_unique<RestoreRate>());
    registry.add("steal", std::make_unique<Steal>());
    registry.add("hp_threshold", std::make_unique<HpThreshold>());
    registry.add("explosion", std::make_unique<Explosion>());
    registry.add("interval_aoe", std::make_unique<IntervalAoe>());
    registry.add("composite", std::make_unique<Composite>());
}

} // namespace game::combat::detail
