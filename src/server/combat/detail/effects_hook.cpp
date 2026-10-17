/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/detail/effects_hook.cpp
 *  PHÂN HỆ   : Combat / Detail / Effects Hook
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mã logic hiệu ứng làm việc qua hook: khiên và phản đòn, miễn nhiễm và gỡ
 *    buff, chỉnh kỹ năng và hiệu ứng khác, hồi sinh, khuếch đại sát thương,
 *    kích hoạt hiệu ứng con khi đánh hoặc bị đánh, và các sự kiện giao cho
 *    module ngoài.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: GameServer 2008 StdImpact008, 009, 017..029, 053, 054, 058 (cùng số logic); các logic 60..95 chỉ có ở dữ liệu
// client 2026, nghĩa tham số lấy từ cột mô tả trong effects.tsv (docs/SERVER-COMBAT.md). Khác gốc ghi tại chỗ.

#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/damage.hpp"
#include "combat/detail/effects.hpp"
#include "combat/detail/effects_impl.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <utility>

namespace game::combat::detail {
namespace {

using actor::round_ratio;
using actor::saturate32;

constexpr std::int64_t kCounterDelayMs = 500;  // phản đòn tới sau nửa giây (RegisterImpactEvent(..., 500))
constexpr std::int32_t kDefaultDamageEffect = 0;  // dòng "đòn đánh thường" của effects.tsv, không bao giờ được xoá

[[nodiscard]] std::int32_t percent_of(std::int64_t value, std::int64_t percent) noexcept {
    return saturate32(round_ratio(value * percent, 100));
}

void fade(HookCtx& ctx) { ctx.arena.fade_out(ctx.me, ctx.buff); }

[[nodiscard]] bool hostile(const Arena& arena, const Fighter& from, const Fighter& to) { return !arena.is_friend(from, to); }

// Đề nghị hồi sinh theo phần trăm HP/MP/nộ khí ở tham số 0..2, nhân (100 + cường hóa)%, tối thiểu 0.
[[nodiscard]] actor::Revival revival_of(const HookCtx& ctx) {
    const std::int64_t rate = std::max<std::int64_t>(0, 100 + static_cast<std::int64_t>(ctx.buff.refix));
    const auto amount = [&ctx, rate](std::size_t index) {
        return actor::Amount{.percent = true, .value = percent_of(param_of(ctx.effect, index), rate)};
    };
    return actor::Revival{.hp = amount(0), .mp = amount(1), .rage = amount(2)};
}

void offer_relive(HookCtx& ctx, Fighter& dead) {
    const actor::Revival revival = revival_of(ctx);
    dead.relive = ReliveInfo{revival};
    ctx.arena.emit(EventKind::kReliveOffered, ctx.buff.caster, dead.handle, 0, revival.hp.value);
}

// ---------------------------------------------------------------------------------------------------------
// Sự kiện giao cho module ngoài lõi

// Logic 6, 27, 28, 57: hiệu ứng của thú cưng. Thú nằm ngoài lõi nên chỉ báo cho nơi gọi biết.
class PetEvent final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        ctx.arena.emit(EventKind::kUnsupported, ctx.buff.caster, ctx.me.handle, ctx.effect.id,
            static_cast<std::int32_t>(UnsupportedReason::kOutOfModule));
    }
};

// Logic 90: gọi script. Lõi không chạy Lua nên chỉ báo mã script cho nơi gọi.
class ScriptEvent final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        const std::int32_t script = param_of(ctx.effect, 0);
        if (script <= 0) return;
        ctx.arena.emit(EventKind::kUnsupported, ctx.buff.caster, ctx.me.handle, static_cast<std::uint32_t>(script),
            static_cast<std::int32_t>(UnsupportedReason::kScript));
    }
};

// Logic 8: khiêu khích quái. Tham số 0: 1 là đặt người tạo làm mục tiêu chính, 0 là đổi mục tiêu chính khác.
class AggroSwitch final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        if (ctx.me.kind != FighterKind::kMonster || !ctx.me.alive()) return;
        ctx.arena.emit(EventKind::kAggro, ctx.buff.caster, ctx.me.handle, ctx.effect.id, param_of(ctx.effect, 0) == 1 ? 1 : 0);
    }
};

// Logic 74: chế giễu, quái buộc đánh người tạo và giảm phòng ngự nội (tham số 1, điểm cộng; thường âm).
class Taunt final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        if (ctx.me.kind != FighterKind::kMonster || !ctx.me.alive()) return;
        ctx.arena.emit(EventKind::kAggro, ctx.buff.caster, ctx.me.handle, ctx.effect.id, 1);
    }

    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& buff, const Effect& effect,
        Contribution& out) const override {
        if (const std::int32_t value = scaled(buff, param_of(effect, 1)); value != 0) out.mods.add_point(actor::Stat::kDefenceMagic, value);
    }
};

// Logic 9: dịch chuyển. Tham số: 0 cảnh đích (-1 là cùng cảnh), 1 toạ độ X và 2 toạ độ Z (centimet). Cùng cảnh thì
// lõi đổi vị trí ngay; khác cảnh chỉ phát sự kiện (id = cảnh đích + 1) cho zone chuyển cảnh.
class Teleport final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        const std::int32_t scene = param_of(ctx.effect, 0);
        const Position where{.x_cm = param_of(ctx.effect, 1), .z_cm = param_of(ctx.effect, 2)};
        if (scene < 0) {
            ctx.me.position = where;
            ctx.arena.emit(EventKind::kTeleport, ctx.buff.caster, ctx.me.handle, 0, 0, 0, where);
            return;
        }
        if (ctx.me.kind != FighterKind::kHuman) return;  // bản gốc: chỉ người đổi được cảnh
        ctx.arena.emit(EventKind::kTeleport, ctx.buff.caster, ctx.me.handle, static_cast<std::uint32_t>(scene) + 1U, 0, 0, where);
    }
};

// Logic 58: tặng điểm thân thiện cho người nhận. Điểm cộng vào Fighter::friendliness_points cho module xã hội đọc.
class Friendliness final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        const std::int32_t amount = param_of(ctx.effect, 0);
        ctx.me.friendliness_points = saturate32(static_cast<std::int64_t>(ctx.me.friendliness_points) + amount);
        ctx.arena.emit(EventKind::kFriendliness, ctx.buff.caster, ctx.me.handle, 0, amount);
    }
};

// Logic 53: xoá hồi chiêu mọi kỹ năng đã học, trừ bốn nhóm ở tham số 0..3.
class CooldownReset final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        Fighter& me = ctx.me;
        if (me.kind != FighterKind::kHuman) return;
        const std::array<std::int32_t, 4> keep{param_of(ctx.effect, 0), param_of(ctx.effect, 1), param_of(ctx.effect, 2), param_of(ctx.effect, 3)};
        for (const SkillEntry& entry : me.skills) {
            const SkillTemplate* tmpl = ctx.arena.catalog().skill(entry.id);
            if (tmpl == nullptr || tmpl->cooldown_id < 0) continue;
            if (std::ranges::find(keep, tmpl->cooldown_id) != keep.end()) continue;
            if (ctx.arena.cooldown_remaining(me, tmpl->cooldown_id) == 0) continue;
            ctx.arena.clear_cooldown(me, tmpl->cooldown_id);
            ctx.arena.emit(EventKind::kCooldownCleared, ctx.buff.caster, me.handle, static_cast<std::uint32_t>(tmpl->cooldown_id));
        }
    }
};

// ---------------------------------------------------------------------------------------------------------
// Hồi sinh

// Logic 54: hồi sinh người đã chết. Tham số 0..2: phần trăm HP, MP, nộ khí sau khi sống lại. Người chết chưa sống lại
// ngay: lõi chỉ đặt đề nghị (Fighter::relive) để người chơi chấp nhận qua Arena::accept_relive.
class Resurrect final : public RefixedLogic {
public:
    [[nodiscard]] bool works_on_corpse() const noexcept override { return true; }

    void on_active(HookCtx& ctx) const override {
        if (ctx.me.alive()) return;
        offer_relive(ctx, ctx.me);
    }
};

// Logic 20: tự hồi sinh khi chết, cùng tham số với logic 54.
class SelfResurrect final : public RefixedLogic {
public:
    void on_die(HookCtx& ctx) const override { offer_relive(ctx, ctx.me); }
};

// ---------------------------------------------------------------------------------------------------------
// Miễn nhiễm, hấp thụ, gỡ buff

// Logic 17: miễn nhiễm các hiệu ứng thuộc tập. Tham số 0 là cấp miễn nhiễm (chỉ chặn hiệu ứng có cấp không quá
// cấp này), 1..8 là các tập hiệu ứng.
class Immunity final : public RefixedLogic {
public:
    [[nodiscard]] std::optional<MissKind> filtrate(HookCtx& ctx, const Buff& incoming, const Effect& incoming_effect) const override {
        if (scaled(ctx.buff, param_of(ctx.effect, 0)) < incoming_effect.level) return std::nullopt;
        for (std::size_t index = 1; index <= kCollections; ++index) {
            const std::int32_t collection = param_of(ctx.effect, index);
            if (collection != kInvalidId && ctx.arena.buff_in_collection(incoming, collection)) return MissKind::kImmune;
        }
        return std::nullopt;
    }

private:
    static constexpr std::size_t kCollections = 8;
};

// Logic 18: gỡ buff thuộc các tập khi kích hoạt. Tham số: 0 cấp gỡ tối đa, 1 số buff gỡ (0: không giới hạn; cường
// hóa chỉ đổi số này), 2..5 tập buff.
// Giữ nguyên bản gốc: hạn mức dừng khi một lần gỡ trong riêng một tập đã đủ số, không cộng dồn qua các tập.
class Dispel final : public RefixedLogic {
public:
    void on_active(HookCtx& ctx) const override {
        if (!ctx.me.alive()) return;
        const std::int32_t level = param_of(ctx.effect, 0);
        const std::int32_t count = scaled(ctx.buff, param_of(ctx.effect, 1));
        for (std::size_t index = 2; index < 2 + kCollections; ++index) {
            const std::int32_t collection = param_of(ctx.effect, index);
            if (collection == kInvalidId || ctx.arena.catalog().collection(collection) == nullptr) continue;
            const std::int32_t dispelled = ctx.arena.dispel_collection(ctx.me, collection, level, count);
            if (count > 0 && dispelled >= count) break;
        }
    }

private:
    static constexpr std::size_t kCollections = 4;
};

// Logic 24: xác suất hấp thụ (vô hiệu) hiệu ứng thuộc tập. Tham số 0 là xác suất %, 1..4 là các tập.
class ImmuneOdds final : public RefixedLogic {
public:
    [[nodiscard]] std::optional<MissKind> filtrate(HookCtx& ctx, const Buff& incoming, const Effect& /*incoming_effect*/) const override {
        bool listed = false;
        for (std::size_t index = 1; index <= kCollections && !listed; ++index) {
            const std::int32_t collection = param_of(ctx.effect, index);
            listed = collection != kInvalidId && ctx.arena.buff_in_collection(incoming, collection);
        }
        // Khác gốc: chỉ rút xúc xắc khi hiệu ứng đến thuộc tập (bản 2008 rút trước, bằng rand() ngoài dice của cảnh).
        if (!listed || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return std::nullopt;
        return MissKind::kAbsorb;
    }

private:
    static constexpr std::size_t kCollections = 4;
};

// Logic 25: xác suất hấp thụ hiệu ứng đến từ đòn hội tâm. Tham số 0 là xác suất %.
class CritAbsorb final : public RefixedLogic {
public:
    [[nodiscard]] std::optional<MissKind> filtrate(HookCtx& ctx, const Buff& incoming, const Effect& /*incoming_effect*/) const override {
        if (!incoming.critical || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return std::nullopt;
        return MissKind::kAbsorb;
    }
};

// ---------------------------------------------------------------------------------------------------------
// Khiên và phản đòn

// Phần sát thương khiên hút: kẹp bởi máu khiên còn lại. Trả lượng đã hút và cập nhật ô 0 (máu khiên).
[[nodiscard]] std::int32_t absorb_into_shield(Buff& buff, std::int32_t damage, std::int32_t rate) {
    const std::int32_t wanted = percent_of(damage, rate);
    const std::int32_t shield = slot_of(buff, 0);
    const std::int32_t taken = std::clamp(wanted, 0, std::max(shield, 0));
    set_slot(buff, 0, shield - taken);
    return taken;
}

// Logic 26: khiên sát thương. Tham số: 0 máu khiên, 1 tỉ lệ hút, 2 tỉ lệ miễn, 3 tỉ lệ phản, 4 xác suất phản,
// 5 trần sát thương phản (0: không trần). Chỉ một chế độ có hiệu lực: hút, rồi miễn, rồi phản (đúng thứ tự mã gốc).
class Shield final : public RefixedLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }

    void on_damage(HookCtx& ctx, Fighter* attacker, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        if (ctx.buff.fade_out) return;
        if (const std::int32_t absorb = param_of(ctx.effect, 1); absorb != 0) {
            damage -= absorb_into_shield(ctx.buff, damage, absorb);
            if (slot_of(ctx.buff, 0) <= 0) fade(ctx);
        } else if (const std::int32_t ignore = param_of(ctx.effect, 2); ignore != 0) {
            damage -= percent_of(damage, ignore);
        } else if (const std::int32_t reflect = param_of(ctx.effect, 3); reflect != 0) {
            if (attacker == nullptr || !roll_chance(ctx.arena, param_of(ctx.effect, 4))) return;
            std::int32_t reflected = percent_of(damage, reflect);
            if (const std::int32_t cap = param_of(ctx.effect, 5); cap > 0) reflected = std::min(reflected, cap);
            ctx.arena.change_hp(*attacker, ctx.me.handle, -static_cast<std::int64_t>(reflected));
        }
    }
};

// Logic 29: khiên hút sát thương và chỉnh kỹ năng. Tham số: 0 máu khiên, 1 tỉ lệ hút, 2 tập kỹ năng được giảm tiêu
// hao, 3 mức giảm tiêu hao (%), 4 tập kỹ năng được chỉnh thời gian gom khí, 5 mức chỉnh (%), 6 nộ khí cộng khi tan.
// Khác gốc: RefixPowerByRate của bản 2008 chia cho 1000 (`*(rate+100)/1000`, nên giá trị cường hóa 0 làm khiên còn một
// phần mười); ở đây chia 100 như mọi RefixPowerByRate khác.
class AbsorbShield final : public EffectLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }

    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        set_slot(buff, 0, std::max(0, refix_percent(slot_of(buff, 0), percent)));
        return true;
    }

    void refix_skill(HookCtx& ctx, CastInfo& info) const override {
        if (ctx.arena.skill_in_collection(info.skill, param_of(ctx.effect, 2))) {
            info.deplete_rate = param_of(ctx.effect, 3);
        } else if (ctx.arena.skill_in_collection(info.skill, param_of(ctx.effect, 4)) && info.charge_ms > 0) {
            info.charge_ms = percent_of(info.charge_ms, 100 + static_cast<std::int64_t>(param_of(ctx.effect, 5)));
        }
    }

    void on_damage(HookCtx& ctx, Fighter* /*attacker*/, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        if (ctx.buff.fade_out) return;
        damage -= absorb_into_shield(ctx.buff, damage, param_of(ctx.effect, 1));
        if (slot_of(ctx.buff, 0) <= 0) fade(ctx);
    }

    void on_fade_out(HookCtx& ctx) const override {
        if (ctx.me.kind != FighterKind::kHuman) return;
        if (const std::int32_t rage = param_of(ctx.effect, 6); rage != 0) ctx.arena.change_rage(ctx.me, ctx.me.handle, rage);
    }
};

// Logic 66: hấp thụ một phần trăm sát thương nhận vào. Tham số 0 là phần trăm. Khác gốc: không có trong mã 2008;
// nghĩa suy từ tên cột "吸收百分率" (hấp thụ phần trăm), không có máu khiên nên không tan.
class AbsorbPercent final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* /*attacker*/, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        damage -= std::clamp(percent_of(damage, scaled(ctx.buff, param_of(ctx.effect, 0))), 0, damage);
    }
};

// Logic 89: phản một phần sát thương về người đánh. Tham số: 0 xác suất %, 1 tỉ lệ phản (%).
class Reflect final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* attacker, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        if (attacker == nullptr || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        const std::int32_t reflected = percent_of(damage, param_of(ctx.effect, 1));
        if (reflected > 0) ctx.arena.change_hp(*attacker, ctx.me.handle, -static_cast<std::int64_t>(reflected));
    }
};

// Logic 22: phản kích. Tham số: 0 xác suất %, 1 số đòn phản kích, 2 tỉ lệ phản sát thương, 3 tỉ lệ hút máu.
class Counter final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* attacker, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        if (ctx.buff.fade_out || attacker == nullptr || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        EffectOrigin origin;
        origin.caster = ctx.me.handle;
        origin.skill = ctx.buff.skill;
        origin.computed = true;
        const std::int64_t delay = ctx.arena.milliseconds_to_ticks(kCounterDelayMs);
        origin.delay_ticks = delay;
        const std::int32_t strikes = std::clamp(param_of(ctx.effect, 1), 0, kMaxStrikes);
        for (std::int32_t i = 0; i < strikes; ++i) {
            static_cast<void>(ctx.arena.send_effect(attacker->handle, static_cast<std::uint32_t>(kDefaultDamageEffect), origin));
        }
        if (const std::int32_t reflect = param_of(ctx.effect, 2); reflect > 0) {
            // Khác gốc: bản 2008 xếp sát thương phản qua hiệu ứng trễ 500 ms; ở đây trừ máu ngay.
            ctx.arena.change_hp(*attacker, ctx.me.handle, -static_cast<std::int64_t>(percent_of(damage, reflect)));
        }
    }

    void on_damage_target(HookCtx& ctx, Fighter& /*target*/, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        if (ctx.buff.fade_out) return;
        const std::int32_t drained = percent_of(damage, param_of(ctx.effect, 3));
        if (drained > 0) ctx.arena.change_hp(ctx.me, ctx.me.handle, drained);
    }

private:
    static constexpr std::int32_t kMaxStrikes = 8;
};

// Logic 23: thân pháp né tránh. Tham số: 0 xác suất %, 1 tỉ lệ sát thương nhận (0: không dùng), 2 tỉ lệ hút nội lực
// của đối phương theo sát thương gây ra, 3 tỉ lệ tiêu nộ khí đối phương.
class Guard final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* /*attacker*/, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        const std::int32_t taken = param_of(ctx.effect, 1);
        if (ctx.buff.fade_out || taken <= 0 || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        damage = percent_of(damage, taken);
    }

    void on_damage_target(HookCtx& ctx, Fighter& target, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        const std::int32_t mp_rate = param_of(ctx.effect, 2);
        const std::int32_t rage_rate = param_of(ctx.effect, 3);
        if (ctx.buff.fade_out || (mp_rate <= 0 && rage_rate <= 0) || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        if (mp_rate > 0) ctx.arena.change_mp(target, ctx.me.handle, -static_cast<std::int64_t>(percent_of(damage, mp_rate)));
        if (rage_rate > 0) ctx.arena.change_rage(target, ctx.me.handle, -static_cast<std::int64_t>(percent_of(target.body.rage(), rage_rate)));
    }
};

// ---------------------------------------------------------------------------------------------------------
// Chỉnh kỹ năng và hiệu ứng khác

// Logic 19: chỉnh sức mạnh / thời gian của hiệu ứng người mang gửi đi, nếu hiệu ứng ấy thuộc tập. Tham số: 0 số lần
// (-1 vô hạn), 1 tập đích, 2 chỉnh sức mạnh (%), 3 chỉnh thời gian (%).
// Giữ nguyên bản gốc: `đạt = đạt || chỉnhThờiGian()` nên khi đã chỉnh sức mạnh thì không chỉnh thời gian nữa.
class RefixImpact final : public RefixedLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }

    void refix_impact(HookCtx& ctx, Buff& outgoing, const Effect& outgoing_effect) const override {
        const std::int32_t times = slot_of(ctx.buff, 0);
        if (times == 0 || ctx.buff.fade_out) return;
        if (!ctx.arena.buff_in_collection(outgoing, param_of(ctx.effect, 1))) return;
        const EffectLogic* logic = ctx.arena.effect_handler(outgoing_effect.logic);
        if (logic == nullptr) return;
        bool done = false;
        if (const std::int32_t power = param_of(ctx.effect, 2); power != 0) done = done || logic->refix_power(outgoing, outgoing_effect, power);
        if (const std::int32_t time = param_of(ctx.effect, 3); time != 0) done = done || logic->refix_continuance(outgoing, outgoing_effect, time);
        if (!done || times < 0) return;
        set_slot(ctx.buff, 0, times - 1);
        if (times == 1) fade(ctx);
    }
};

// Ô tham số của các logic chỉnh kỹ năng (21, 61, 93); -1 là logic không có ô ấy.
struct SkillLayout {
    std::int8_t activations = -1;
    std::int8_t collection = -1;
    std::int8_t hit = -1;
    std::int8_t critical = -1;
    std::int8_t power_value = -1;
    std::int8_t power_rate = -1;
    std::int8_t deplete_value = -1;
    std::int8_t deplete_rate = -1;
    std::int8_t time_value = -1;
    std::int8_t time_rate = -1;
    std::int8_t cooldown_value = -1;
    std::int8_t cooldown_rate = -1;
    std::int8_t charge_value = -1;
    std::int8_t charge_rate = -1;
    std::int8_t channel_value = -1;
    std::int8_t channel_rate = -1;
    std::int8_t rage_gain = -1;
};

// Logic 21: buff "tuyệt kỹ" chỉnh kỹ năng trong tập, dùng được vài lần. Logic 61: bớt gom khí/hồi chiêu, chỉnh trúng
// và hội tâm, không đếm lần. Logic 93: bớt gom khí/hồi chiêu và tăng nộ khí nhận, không đếm lần.
class SkillRefix final : public RefixedLogic {
public:
    explicit SkillRefix(const SkillLayout& layout) noexcept : layout_(layout) {}

    void init(Buff& buff, const Effect& effect) const override {
        set_slot(buff, 0, layout_.activations < 0 ? -1 : value(effect, layout_.activations));
    }

    void refix_skill(HookCtx& ctx, CastInfo& info) const override {
        if (!applies(ctx, info.skill)) return;
        const Effect& effect = ctx.effect;
        if (const std::int32_t hit = value(effect, layout_.hit); hit != 0) info.accuracy = hit;
        if (const std::int32_t critical = value(effect, layout_.critical); critical != 0) info.critical = critical;
        if (const std::int32_t v = value(effect, layout_.power_value); v != 0) info.power_value = v;
        if (const std::int32_t v = value(effect, layout_.power_rate); v != 0) info.power_rate = v;
        if (const std::int32_t v = value(effect, layout_.deplete_value); v != 0) info.deplete_value = v;
        if (const std::int32_t v = value(effect, layout_.deplete_rate); v != 0) info.deplete_rate = v;
        if (const std::int32_t v = value(effect, layout_.time_value); v != 0) info.time_value = v;
        if (const std::int32_t v = value(effect, layout_.time_rate); v != 0) info.time_rate = v;
        refix_time(info.cooldown_ms, value(effect, layout_.cooldown_value), value(effect, layout_.cooldown_rate));
        refix_time(info.charge_ms, value(effect, layout_.charge_value), value(effect, layout_.charge_rate));
        refix_time(info.channel_ms, value(effect, layout_.channel_value), value(effect, layout_.channel_rate));
    }

    void on_use_skill(HookCtx& ctx, CastInfo& info) const override {
        if (layout_.activations < 0 || !applies(ctx, info.skill)) return;
        const std::int32_t left = slot_of(ctx.buff, 0);
        if (left <= 0) return;  // vô hạn (-1) hay đã hết (0) thì không đếm
        set_slot(ctx.buff, 0, left - 1);
        if (left == 1) fade(ctx);
    }

    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& buff, const Effect& effect,
        Contribution& out) const override {
        if (layout_.rage_gain < 0) return;
        out.mods.rage_gain_percent = saturate32(static_cast<std::int64_t>(out.mods.rage_gain_percent) + scaled(buff, value(effect, layout_.rage_gain)));
    }

private:
    [[nodiscard]] static std::int32_t value(const Effect& effect, std::int8_t index) noexcept {
        return index < 0 ? 0 : param_of(effect, static_cast<std::size_t>(index));
    }

    [[nodiscard]] bool applies(HookCtx& ctx, std::uint32_t skill) const {
        if (slot_of(ctx.buff, 0) == 0) return false;
        return ctx.arena.skill_in_collection(skill, value(ctx.effect, layout_.collection));
    }

    // Cộng theo giá trị rồi theo phần trăm, không âm (SkillInfo_T::SetCooldownTime/ChargeTime/ChannelTime).
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): thời gian, lượng cộng, phần trăm khác vai, nơi gọi nêu tên (HP-07)
    static void refix_time(std::int32_t& time_ms, std::int32_t by_value, std::int32_t by_rate) noexcept {
        if (by_value != 0) time_ms = std::max(0, saturate32(static_cast<std::int64_t>(time_ms) + by_value));
        if (by_rate != 0) time_ms = std::max(0, saturate32(static_cast<std::int64_t>(time_ms) + round_ratio(static_cast<std::int64_t>(time_ms) * by_rate, 100)));
    }

    SkillLayout layout_;
};

constexpr SkillLayout kLayout21{
    .activations = 0, .collection = 1, .hit = 2, .critical = 3, .power_value = 4, .power_rate = 5, .deplete_value = 6,
    .deplete_rate = 7, .time_value = 8, .time_rate = 9, .cooldown_value = 10, .cooldown_rate = 11, .charge_value = 12,
    .charge_rate = 13, .channel_value = 14, .channel_rate = 15};
constexpr SkillLayout kLayout61{
    .collection = 0, .hit = 5, .critical = 6, .cooldown_value = 3, .cooldown_rate = 4, .charge_value = 1, .charge_rate = 2};
constexpr SkillLayout kLayout93{
    .collection = 0, .cooldown_value = 3, .cooldown_rate = 4, .charge_value = 1, .charge_rate = 2, .rage_gain = 5};

// ---------------------------------------------------------------------------------------------------------
// Khuếch đại và đánh dấu sát thương

// Logic 69: người mang bị đánh dấu yếu, nhận thêm sát thương từ kỹ năng trong tập. Tham số: 0 tập kỹ năng (-1: mọi
// kỹ năng), 1 tỉ lệ cộng thêm (%).
class DamageAmp final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* /*attacker*/, std::int32_t& damage, std::uint32_t skill) const override {
        const std::int32_t set = param_of(ctx.effect, 0);
        if (set != kInvalidId && !ctx.arena.skill_in_collection(skill, set)) return;
        damage = percent_of(damage, 100 + static_cast<std::int64_t>(scaled(ctx.buff, param_of(ctx.effect, 1))));
    }
};

// Logic 92: như logic 69 nhưng tỉ lệ khác nhau cho quái (tham số 1) và người (tham số 2).
class DamageAmpByKind final : public RefixedLogic {
public:
    void on_damage(HookCtx& ctx, Fighter* /*attacker*/, std::int32_t& damage, std::uint32_t skill) const override {
        const std::int32_t set = param_of(ctx.effect, 0);
        if (set != kInvalidId && !ctx.arena.skill_in_collection(skill, set)) return;
        const std::size_t index = ctx.me.kind == FighterKind::kMonster ? 1U : 2U;
        damage = percent_of(damage, 100 + static_cast<std::int64_t>(scaled(ctx.buff, param_of(ctx.effect, index))));
    }
};

// Logic 76: sát thương từ kỹ năng trong tập kèm thêm một lượng cố định ở một kênh. Tham số: 0 tập kỹ năng, 1 kênh
// (0..5: ngoại, nội, băng, hỏa, điện, độc), 2 lượng thêm.
class MarkDamage final : public RefixedLogic {
public:
    void on_damages(HookCtx& ctx, Fighter* /*attacker*/, ChannelDamage& amounts, std::uint32_t skill) const override {
        if (!ctx.arena.skill_in_collection(skill, param_of(ctx.effect, 0))) return;
        const std::int32_t channel = param_of(ctx.effect, 1);
        if (channel < 0 || std::cmp_greater_equal(channel, kChannelCount)) return;
        auto& slot = amounts[static_cast<Channel>(channel)];
        slot = saturate32(static_cast<std::int64_t>(slot) + scaled(ctx.buff, param_of(ctx.effect, 2)));
    }
};

// Logic 77: trúng sát thương từ kỹ năng trong tập thì có xác suất nhận thêm một hiệu ứng. Tham số: 0 tập kỹ năng,
// 1 hiệu ứng thêm (vai sub), 2 xác suất %.
class MarkTrigger final : public RefixedLogic {
public:
    void on_damages(HookCtx& ctx, Fighter* /*attacker*/, ChannelDamage& /*amounts*/, std::uint32_t skill) const override {
        if (!ctx.arena.skill_in_collection(skill, param_of(ctx.effect, 0))) return;
        if (!roll_chance(ctx.arena, param_of(ctx.effect, 2))) return;
        send_sub(ctx, ctx.me, param_of(ctx.effect, 1), false);
    }
};

// Logic 81: khuếch đại sát thương người mang gây ra. Tham số 0 là phần trăm cộng thêm.
class DamageBoost final : public RefixedLogic {
public:
    void on_damage_target(HookCtx& ctx, Fighter& /*target*/, std::int32_t& damage, std::uint32_t /*skill*/) const override {
        damage = percent_of(damage, 100 + static_cast<std::int64_t>(scaled(ctx.buff, param_of(ctx.effect, 0))));
    }
};

// Logic 64: đòn kế tiếp bỏ qua phòng thủ. Tham số: 0 số lần (-1 vô hạn), 1 cờ bật. DamageAttack::compute dùng qua
// consume_ignore_defence.
class IgnoreDefence final : public RefixedLogic {
public:
    void init(Buff& buff, const Effect& effect) const override { set_slot(buff, 0, param_of(effect, 0)); }
};

// ---------------------------------------------------------------------------------------------------------
// Kích hoạt hiệu ứng khi đánh / bị đánh

// Logic 60: tăng nộ khí nhận, và khi đánh trúng địch có xác suất giáng hiệu ứng lên địch và/hoặc người mang. Tham số:
// 0 tăng nộ khí (%), 1 xác suất %, 2 hiệu ứng cho mục tiêu, 3 hiệu ứng cho bản thân. Khác gốc: không có trong mã
// 2008; thời điểm kích hoạt (trúng địch) suy từ dữ liệu: hiệu ứng mục tiêu là "攻击破绽" (giảm công của địch).
class RageTrigger final : public RefixedLogic {
public:
    void on_hit_target(HookCtx& ctx, Fighter& target) const override {
        if (!hostile(ctx.arena, ctx.me, target) || !roll_chance(ctx.arena, param_of(ctx.effect, 1))) return;
        send_sub(ctx, target, param_of(ctx.effect, 2), false);
        send_sub(ctx, ctx.me, param_of(ctx.effect, 3), false);
    }

    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& buff, const Effect& effect,
        Contribution& out) const override {
        out.mods.rage_gain_percent = saturate32(static_cast<std::int64_t>(out.mods.rage_gain_percent) + scaled(buff, param_of(effect, 0)));
    }
};

// Logic 65: nâng trần điểm liên kích, và khi đánh trúng địch có xác suất cộng điểm liên kích. Tham số: 0 nâng trần,
// 1 xác suất %, 2 điểm cộng mỗi lần.
class ComboPoints final : public RefixedLogic {
public:
    void on_hit_target(HookCtx& ctx, Fighter& target) const override {
        if (!hostile(ctx.arena, ctx.me, target) || !roll_chance(ctx.arena, param_of(ctx.effect, 1))) return;
        ctx.arena.change_strike(ctx.me, ctx.me.handle, param_of(ctx.effect, 2));
    }

    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& /*buff*/, const Effect& effect,
        Contribution& out) const override {
        if (const std::int32_t cap = param_of(effect, 0); cap != 0) out.mods.add_point(actor::Stat::kMaxStrikePoint, cap);
    }
};

// Logic 88: có xác suất kích hoạt hiệu ứng khi gây sát thương, gây hội tâm, hoặc bị sát thương bằng kỹ năng trong tập.
// Tham số: 0, 1, 2 xác suất % ở ba thời điểm; 3 tập kỹ năng (-1: mọi kỹ năng; hội tâm không biết kỹ năng nên bỏ lọc);
// 4 khuếch đại sát thương gây ra (%); 5, 6 hiệu ứng cho bản thân; 7, 8 hiệu ứng cho đối phương.
class TriggerOnHit final : public RefixedLogic {
public:
    void on_damage_target(HookCtx& ctx, Fighter& target, std::int32_t& damage, std::uint32_t skill) const override {
        if (ctx.buff.fade_out || !in_set(ctx, skill) || !roll_chance(ctx.arena, param_of(ctx.effect, 0))) return;
        if (const std::int32_t amp = param_of(ctx.effect, 4); amp > 0) damage = percent_of(damage, 100 + static_cast<std::int64_t>(amp));
        fire(ctx, target);
    }

    void on_critical_hit_target(HookCtx& ctx, Fighter& target) const override {
        if (ctx.buff.fade_out || !roll_chance(ctx.arena, param_of(ctx.effect, 1))) return;
        fire(ctx, target);
    }

    void on_damage(HookCtx& ctx, Fighter* attacker, std::int32_t& /*damage*/, std::uint32_t skill) const override {
        if (ctx.buff.fade_out || attacker == nullptr || !in_set(ctx, skill) || !roll_chance(ctx.arena, param_of(ctx.effect, 2))) return;
        fire(ctx, *attacker);
    }

private:
    [[nodiscard]] static bool in_set(const HookCtx& ctx, std::uint32_t skill) {
        const std::int32_t set = param_of(ctx.effect, 3);
        return set == kInvalidId || ctx.arena.skill_in_collection(skill, set);
    }

    static void fire(const HookCtx& ctx, Fighter& other) {
        send_sub(ctx, ctx.me, param_of(ctx.effect, 5), false);
        send_sub(ctx, ctx.me, param_of(ctx.effect, 6), false);
        send_sub(ctx, other, param_of(ctx.effect, 7), false);
        send_sub(ctx, other, param_of(ctx.effect, 8), false);
    }
};

} // namespace

bool consume_ignore_defence(Arena& arena, Fighter& attacker) {
    for (std::size_t i = 0; i < attacker.buff_count; ++i) {
        Buff& buff = attacker.buffs.at(i);
        if (buff.fade_out) continue;
        const Effect* effect = arena.catalog().effect(buff.effect);
        const LogicSpec* spec = effect == nullptr ? nullptr : arena.catalog().effect_logic(effect->logic);
        if (spec == nullptr || spec->handler != "ignore_defence" || param_of(*effect, 1) == 0) continue;
        const std::int32_t left = slot_of(buff, 0);
        if (left == 0) continue;
        if (left > 0) {
            set_slot(buff, 0, left - 1);
            if (left == 1) arena.fade_out(attacker, buff);
        }
        return true;
    }
    return false;
}

void add_hook_effects(EffectRegistry& registry) {
    registry.add("pet_event", std::make_unique<PetEvent>());
    registry.add("script_event", std::make_unique<ScriptEvent>());
    registry.add("aggro_switch", std::make_unique<AggroSwitch>());
    registry.add("taunt", std::make_unique<Taunt>());
    registry.add("teleport", std::make_unique<Teleport>());
    registry.add("friendliness", std::make_unique<Friendliness>());
    registry.add("cooldown_reset", std::make_unique<CooldownReset>());
    registry.add("resurrect", std::make_unique<Resurrect>());
    registry.add("self_resurrect", std::make_unique<SelfResurrect>());
    registry.add("immunity", std::make_unique<Immunity>());
    registry.add("dispel", std::make_unique<Dispel>());
    registry.add("immune_odds", std::make_unique<ImmuneOdds>());
    registry.add("crit_absorb", std::make_unique<CritAbsorb>());
    registry.add("shield", std::make_unique<Shield>());
    registry.add("absorb_shield", std::make_unique<AbsorbShield>());
    registry.add("absorb_percent", std::make_unique<AbsorbPercent>());
    registry.add("reflect", std::make_unique<Reflect>());
    registry.add("counter", std::make_unique<Counter>());
    registry.add("guard", std::make_unique<Guard>());
    registry.add("refix_impact", std::make_unique<RefixImpact>());
    registry.add("skill_refix", std::make_unique<SkillRefix>(kLayout21));
    registry.add("skill_refix_time", std::make_unique<SkillRefix>(kLayout61));
    registry.add("skill_refix_rage", std::make_unique<SkillRefix>(kLayout93));
    registry.add("damage_amp", std::make_unique<DamageAmp>());
    registry.add("damage_amp_kind", std::make_unique<DamageAmpByKind>());
    registry.add("mark_damage", std::make_unique<MarkDamage>());
    registry.add("mark_trigger", std::make_unique<MarkTrigger>());
    registry.add("damage_boost", std::make_unique<DamageBoost>());
    registry.add("ignore_defence", std::make_unique<IgnoreDefence>());
    registry.add("rage_trigger", std::make_unique<RageTrigger>());
    registry.add("combo_points", std::make_unique<ComboPoints>());
    registry.add("trigger_on_hit", std::make_unique<TriggerOnHit>());
}

} // namespace game::combat::detail
