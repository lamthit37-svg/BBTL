#pragma once
// Giao diện mã xử lý logic hiệu ứng (tương đương ImpactLogic_T của GameServer 2008): mỗi logic là một lớp con
// ghi đè các hook nó cần. Arena gọi hook theo thứ tự buff trong danh sách của người mang, đúng như bản gốc.
// Header nội bộ module combat: module khác không include.

#include "actor/body.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::combat::detail {

// Ngữ cảnh một hook: buff đang xử lý nằm trong danh sách của `me`, nên hook không giữ tham chiếu `buff` qua
// lời gọi nào có thể thêm/thay buff (Arena::send_effect không đụng danh sách ngay, chỉ xếp hàng).
// Hai struct dưới là gói tham chiếu sống đúng một lời gọi hook, không bao giờ rỗng và không bao giờ gán lại: tham chiếu
// diễn đạt đúng điều đó, con trỏ thì buộc mọi hook kiểm null vô nghĩa.
// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): gói tham chiếu sống một lời gọi, không sao chép (HP-07)
struct HookCtx {
    Arena& arena;
    Fighter& me;
    Buff& buff;
    const Effect& effect;
    const LogicSpec& spec;
};

// Phần buff đóng góp vào chỉ số và cờ dẫn xuất của người mang.
struct Contribution {
    actor::Modifiers& mods;
    Aggregates& agg;
    std::uint8_t& claimed;  // bit các cờ bool đã có buff trước đặt (buff đầu tiên đặt cờ thì thắng)
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

inline constexpr std::uint8_t kClaimAction1 = 1U << 0U;
inline constexpr std::uint8_t kClaimAction2 = 1U << 1U;
inline constexpr std::uint8_t kClaimMove = 1U << 2U;
inline constexpr std::uint8_t kClaimUnbreakable = 1U << 3U;

// Giá trị tham số sau cường hóa của buff: Float2Int(value * (100 + refix) / 100).
[[nodiscard]] std::int32_t scaled(const Buff& buff, std::int32_t value) noexcept;

class EffectLogic {
public:
    EffectLogic() = default;
    EffectLogic(const EffectLogic&) = delete;
    EffectLogic& operator=(const EffectLogic&) = delete;
    EffectLogic(EffectLogic&&) = delete;
    EffectLogic& operator=(EffectLogic&&) = delete;
    virtual ~EffectLogic() = default;

    // ---- khởi tạo và cường hóa ----
    // InitFromData: dựng trạng thái riêng của buff từ dòng dữ liệu.
    virtual void init(Buff& buff, const Effect& effect) const;
    // Có chạy theo chu kỳ (OnIntervalOver) hay không.
    [[nodiscard]] virtual bool intervaled() const noexcept { return false; }
    // RefixPowerByRate: true khi logic có sức mạnh để cường hóa.
    virtual bool refix_power(Buff& buff, const Effect& effect, std::int32_t percent) const;
    // RefixContinuanceByRate: đổi thời gian tồn tại theo phần trăm; false với hiệu ứng tức thời hoặc vô hạn.
    virtual bool refix_continuance(Buff& buff, const Effect& effect, std::int32_t percent) const;
    // CriticalRefix: nhân đôi cho đòn hội tâm.
    virtual void critical_refix(Buff& buff, const Effect& effect) const;
    // Tính sát thương của hiệu ứng nằm trong kỹ năng (CombatCore::GetResultImpact). Chỉ logic 3 dùng.
    virtual void compute(Arena& arena, Fighter& caster, Fighter& target, Buff& buff, const Effect& effect) const;
    // true khi hiệu ứng vẫn tác dụng được lên xác (hồi sinh).
    [[nodiscard]] virtual bool works_on_corpse() const noexcept { return false; }

    // ---- hook sự kiện ----
    virtual void on_active(HookCtx& ctx) const;
    virtual void on_fade_out(HookCtx& ctx) const;
    virtual void on_interval(HookCtx& ctx) const;
    virtual void on_damages(HookCtx& ctx, Fighter* attacker, ChannelDamage& amounts, std::uint32_t skill) const;
    virtual void on_damage(HookCtx& ctx, Fighter* attacker, std::int32_t& damage, std::uint32_t skill) const;
    virtual void on_damage_target(HookCtx& ctx, Fighter& target, std::int32_t& damage, std::uint32_t skill) const;
    virtual void on_be_hit(HookCtx& ctx, Fighter& attacker) const;
    virtual void on_hit_target(HookCtx& ctx, Fighter& target) const;
    virtual void on_critical_hit_target(HookCtx& ctx, Fighter& target) const;
    virtual void on_be_critical_hit(HookCtx& ctx, Fighter& attacker) const;
    virtual void on_heal_target(HookCtx& ctx, Fighter& target, std::int32_t& healed) const;
    virtual void on_be_heal(HookCtx& ctx, Fighter& healer, std::int32_t& healed) const;
    virtual void on_die(HookCtx& ctx) const;
    virtual void on_use_skill(HookCtx& ctx, CastInfo& info) const;
    virtual void refix_skill(HookCtx& ctx, CastInfo& info) const;
    // Buff của người gửi chỉnh một hiệu ứng sắp gửi đi.
    virtual void refix_impact(HookCtx& ctx, Buff& outgoing, const Effect& outgoing_effect) const;
    // Buff của người nhận có thể chặn một hiệu ứng tới (miễn nhiễm, hấp thụ).
    [[nodiscard]] virtual std::optional<MissKind> filtrate(HookCtx& ctx, const Buff& incoming, const Effect& incoming_effect) const;
    // Buff đóng góp chỉ số/cờ.
    virtual void contribute(const Arena& arena, const Fighter& me, const Buff& buff, const Effect& effect, Contribution& out) const;
    // Điều kiện riêng để buff còn sống mỗi nhịp (SpecialHeartBeatCheck).
    [[nodiscard]] virtual bool alive_check(HookCtx& ctx) const;
};

// Tra mã xử lý theo tên trong bảng effect_logics.tsv; nullptr khi tên lạ.
// Dựng sổ lần gọi đầu tiên (có thể ném bad_alloc), nên không noexcept.
[[nodiscard]] const EffectLogic* find_effect_handler(std::string_view name);

} // namespace game::combat::detail
