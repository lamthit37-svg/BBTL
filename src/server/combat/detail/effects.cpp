// Mặc định của lớp EffectLogic, sổ đăng ký mã xử lý và các hàm gửi hiệu ứng con (xem effects.hpp, effects_impl.hpp).
//
// Nguồn: GameServer 2008 ImpactLogic.cpp (hàm ảo mặc định của ImpactLogic_T), ImpactLogics.cpp (bảng đăng ký).
#include "combat/detail/effects.hpp"

#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/damage.hpp"
#include "combat/detail/effects_impl.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::combat::detail {

std::int32_t scaled(const Buff& buff, std::int32_t value) noexcept { return refix_percent(value, buff.refix); }

// ---------------------------------------------------------------------------------------------------------
// Mặc định: logic không ghi đè hook nào thì không làm gì

void EffectLogic::init(Buff& /*buff*/, const Effect& /*effect*/) const {}

bool EffectLogic::refix_power(Buff& /*buff*/, const Effect& /*effect*/, std::int32_t /*percent*/) const { return false; }

bool EffectLogic::refix_continuance(Buff& buff, const Effect& effect, std::int32_t percent) const {
    if (!effect.over_timed || buff.continuance < 0) return false;
    buff.continuance = refix_percent(buff.continuance, percent);
    return true;
}

void EffectLogic::critical_refix(Buff& /*buff*/, const Effect& /*effect*/) const {}

void EffectLogic::compute(Arena& /*arena*/, Fighter& /*caster*/, Fighter& /*target*/, Buff& /*buff*/, const Effect& /*effect*/) const {}

void EffectLogic::on_active(HookCtx& /*ctx*/) const {}
void EffectLogic::on_fade_out(HookCtx& /*ctx*/) const {}
void EffectLogic::on_interval(HookCtx& /*ctx*/) const {}

void EffectLogic::on_damages(HookCtx& /*ctx*/, Fighter* /*attacker*/, ChannelDamage& /*amounts*/, std::uint32_t /*skill*/) const {}

void EffectLogic::on_damage(HookCtx& /*ctx*/, Fighter* /*attacker*/, std::int32_t& /*damage*/, std::uint32_t /*skill*/) const {}

void EffectLogic::on_damage_target(HookCtx& /*ctx*/, Fighter& /*target*/, std::int32_t& /*damage*/, std::uint32_t /*skill*/) const {}

void EffectLogic::on_be_hit(HookCtx& /*ctx*/, Fighter& /*attacker*/) const {}
void EffectLogic::on_hit_target(HookCtx& /*ctx*/, Fighter& /*target*/) const {}
void EffectLogic::on_critical_hit_target(HookCtx& /*ctx*/, Fighter& /*target*/) const {}
void EffectLogic::on_be_critical_hit(HookCtx& /*ctx*/, Fighter& /*attacker*/) const {}
void EffectLogic::on_heal_target(HookCtx& /*ctx*/, Fighter& /*target*/, std::int32_t& /*healed*/) const {}
void EffectLogic::on_be_heal(HookCtx& /*ctx*/, Fighter& /*healer*/, std::int32_t& /*healed*/) const {}
void EffectLogic::on_die(HookCtx& /*ctx*/) const {}
void EffectLogic::on_use_skill(HookCtx& /*ctx*/, CastInfo& /*info*/) const {}
void EffectLogic::refix_skill(HookCtx& /*ctx*/, CastInfo& /*info*/) const {}
void EffectLogic::refix_impact(HookCtx& /*ctx*/, Buff& /*outgoing*/, const Effect& /*outgoing_effect*/) const {}

std::optional<MissKind> EffectLogic::filtrate(HookCtx& /*ctx*/, const Buff& /*incoming*/, const Effect& /*incoming_effect*/) const {
    return std::nullopt;
}

void EffectLogic::contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& /*buff*/, const Effect& /*effect*/,
    Contribution& /*out*/) const {}

bool EffectLogic::alive_check(HookCtx& /*ctx*/) const { return true; }

// ---------------------------------------------------------------------------------------------------------
// Sổ đăng ký

void EffectRegistry::add(std::string_view name, std::unique_ptr<EffectLogic> logic) {
    entries_.insert_or_assign(std::string(name), std::move(logic));
}

const EffectLogic* EffectRegistry::find(std::string_view name) const noexcept {
    const auto it = entries_.find(name);
    return it == entries_.end() ? nullptr : it->second.get();
}

namespace {

// Lớp không làm gì: hiệu ứng đánh dấu (kỹ năng và hiệu ứng khác hỏi qua tập id) và logic chỉ có hình ảnh phía client.
class MarkerLogic final : public EffectLogic {};

[[nodiscard]] std::unique_ptr<EffectRegistry> build_registry() {
    auto built = std::make_unique<EffectRegistry>();
    built->add("none", std::make_unique<MarkerLogic>());
    add_damage_effects(*built);
    add_stat_effects(*built);
    add_hook_effects(*built);
    return built;
}

[[nodiscard]] const EffectRegistry& registry() {
    // Dựng một lần, an toàn đa luồng nhờ khởi tạo biến tĩnh cục bộ; sau đó chỉ đọc. Sổ sống tới hết tiến trình và cố ý
    // không bị huỷ lúc thoát: các Arena còn giữ con trỏ tới mã xử lý, mà thứ tự huỷ biến tĩnh giữa các đơn vị dịch không
    // được bảo đảm (và Clang -Wexit-time-destructors cấm biến tĩnh có destructor không tầm thường).
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory): cố ý không huỷ sổ lúc thoát tiến trình (HP-07)
    static const EffectRegistry* const kRegistry = build_registry().release();
    return *kRegistry;
}

} // namespace

const EffectLogic* find_effect_handler(std::string_view name) { return registry().find(name); }

// ---------------------------------------------------------------------------------------------------------
// Gửi hiệu ứng con

bool send_sub(const HookCtx& ctx, const Fighter& receiver, std::int32_t effect_id, bool critical, bool computed) {
    if (effect_id <= 0) return false;  // -1 là ô trống; 0 là dòng sát thương mặc định, không bao giờ là hiệu ứng con
    EffectOrigin origin;
    origin.caster = ctx.buff.caster;
    origin.skill = ctx.buff.skill;
    origin.critical = critical;
    origin.power_percent = ctx.buff.refix;
    if (computed) {
        const Effect* sub = ctx.arena.catalog().effect(static_cast<std::uint32_t>(effect_id));
        const LogicSpec* spec = sub == nullptr ? nullptr : ctx.arena.catalog().effect_logic(sub->logic);
        origin.computed = spec != nullptr && spec->handler == "damage_attack";
    }
    return ctx.arena.send_effect(receiver.handle, static_cast<std::uint32_t>(effect_id), origin);
}

bool roll_chance(Arena& arena, std::int32_t percent) {
    if (percent <= 0) return false;
    if (percent >= 100) return true;
    return arena.roll100() < percent;
}

std::int32_t send_roles(const HookCtx& ctx, RoleKind kind, const Fighter& receiver, bool computed) {
    std::int32_t sent = 0;
    for (const Role& role : ctx.spec.roles) {
        if (role.kind != kind) continue;
        if (role.chance >= 0 && !roll_chance(ctx.arena, param_of(ctx.effect, static_cast<std::size_t>(role.chance)))) continue;
        if (send_sub(ctx, receiver, param_of(ctx.effect, static_cast<std::size_t>(role.param)), ctx.buff.critical, computed)) ++sent;
    }
    return sent;
}

Fighter* caster_of(HookCtx& ctx) { return ctx.arena.find(ctx.buff.caster); }

} // namespace game::combat::detail

namespace game::combat {

bool known_effect_handler(std::string_view name) { return detail::find_effect_handler(name) != nullptr; }

} // namespace game::combat
