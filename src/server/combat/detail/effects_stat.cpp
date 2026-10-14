// Mã logic hiệu ứng đổi chỉ số và cờ trạng thái của người mang: các bảng chỉ số (logic 11, 12, 13, 15, 16, 36, 56, 59,
// 79, 91, 94, 95), cờ trạng thái (14), choáng (35), miễn nhiễm sát thương (83), bỏ qua gián đoạn (62).
//
// Nguồn: GameServer 2008 StdImpact011..016, 035, 036, 056 (cùng số logic, hàm GetIntAttrRefix/GetBoolAttrRefix);
// thứ tự tham số theo cột mô tả của dữ liệu client 2026 (docs/SERVER-COMBAT.md, mục "Logic hiệu ứng"), vì thứ tự
// 2026 của logic 13 và 56 khác bản 2008. Khác gốc ghi tại chỗ.
#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/detail/effects.hpp"
#include "combat/detail/effects_impl.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>

namespace game::combat::detail {
namespace {

using actor::Stat;

// Cách một tham số đi vào người mang.
enum class Mode : std::uint8_t {
    kPoint,          // cộng thẳng vào chỉ số
    kRate,           // phần trăm của giá trị gốc theo phái
    kRageGain,       // phần trăm nộ khí nhận thêm
    kResistReduce,   // giảm kháng đối phương theo hệ
    kDetect,         // cấp dò ẩn thân
    kStopMove,       // giá trị 0 nghĩa là không đi được (cờ, không nhân cường hóa)
};

struct Line {
    std::uint8_t param;
    Stat stat;
    Mode mode;
    Element element;  // chỉ dùng cho kResistReduce
};

constexpr Line point(std::uint8_t param, Stat stat) noexcept {
    return {.param = param, .stat = stat, .mode = Mode::kPoint, .element = Element::kCold};
}
constexpr Line rate(std::uint8_t param, Stat stat) noexcept {
    return {.param = param, .stat = stat, .mode = Mode::kRate, .element = Element::kCold};
}
constexpr Line reduce(std::uint8_t param, Element element) noexcept {
    return {.param = param, .stat = Stat::kStr, .mode = Mode::kResistReduce, .element = element};
}

// Logic 11: cộng điểm vào 16 chỉ số. Logic 12: cùng 16 chỉ số nhưng theo phần trăm.
constexpr std::array kPointLines = {
    point(0, Stat::kAttackPhy), point(1, Stat::kDefencePhy), point(2, Stat::kAttackMagic), point(3, Stat::kDefenceMagic),
    point(4, Stat::kAttackCold), point(5, Stat::kResistCold), point(6, Stat::kAttackFire), point(7, Stat::kResistFire),
    point(8, Stat::kAttackLight), point(9, Stat::kResistLight), point(10, Stat::kAttackPoison), point(11, Stat::kResistPoison),
    point(12, Stat::kMaxHp), point(13, Stat::kMaxMp), point(14, Stat::kMaxRage), point(15, Stat::kMaxStrikePoint),
};
constexpr std::array kRateLines = {
    rate(0, Stat::kAttackPhy), rate(1, Stat::kDefencePhy), rate(2, Stat::kAttackMagic), rate(3, Stat::kDefenceMagic),
    rate(4, Stat::kAttackCold), rate(5, Stat::kResistCold), rate(6, Stat::kAttackFire), rate(7, Stat::kResistFire),
    rate(8, Stat::kAttackLight), rate(9, Stat::kResistLight), rate(10, Stat::kAttackPoison), rate(11, Stat::kResistPoison),
    rate(12, Stat::kMaxHp), rate(13, Stat::kMaxMp), rate(14, Stat::kMaxRage), rate(15, Stat::kMaxStrikePoint),
};
// Logic 13: trúng, né, hội tâm, hội tâm phòng.
constexpr std::array kHitLines = {
    point(0, Stat::kHit), point(1, Stat::kMiss), point(2, Stat::kCritical), point(3, Stat::kCriticalDefence),
};
// Logic 15: cộng điểm thuộc tính cấp một (thể, tâm, căn, trí). Logic 16: theo phần trăm, thêm thân pháp.
// Thứ tự cột 2026: STR, CON, SPR, INT, (DEX).
constexpr std::array kPrimaryLines = {
    point(0, Stat::kStr), point(1, Stat::kCon), point(2, Stat::kSpr), point(3, Stat::kInt),
};
constexpr std::array kPrimaryRateLines = {
    rate(0, Stat::kStr), rate(1, Stat::kCon), rate(2, Stat::kSpr), rate(3, Stat::kInt), rate(4, Stat::kDex),
};
// Logic 56: bốn chỉ số điểm, rồi HP tối đa và công/thủ theo phần trăm của giá trị gốc.
constexpr std::array kMixedLines = {
    point(0, Stat::kHit), point(1, Stat::kMiss), point(2, Stat::kCritical), point(3, Stat::kCriticalDefence),
    rate(4, Stat::kMaxHp), rate(5, Stat::kAttackPhy), rate(6, Stat::kDefencePhy), rate(7, Stat::kAttackMagic),
    rate(8, Stat::kDefenceMagic),
};
// Logic 59: tăng nộ khí nhận, kháng bốn hệ, thủ ngoại/nội, HP tối đa, né (tham số 4, 7 theo cột mô tả).
constexpr std::array kToughLines = {
    Line{.param = 0, .stat = Stat::kStr, .mode = Mode::kRageGain, .element = Element::kCold},
    point(1, Stat::kResistCold), point(2, Stat::kResistFire), point(3, Stat::kResistLight), point(4, Stat::kResistPoison),
    point(5, Stat::kDefencePhy), point(6, Stat::kDefenceMagic), point(7, Stat::kMaxHp), point(8, Stat::kMiss),
};
// Logic 91: công ngoại và nội theo phần trăm.
constexpr std::array kAttackRateLines = {rate(0, Stat::kAttackPhy), rate(1, Stat::kAttackMagic)};
// Logic 94: giảm kháng của đối phương theo hệ.
constexpr std::array kReduceLines = {
    reduce(0, Element::kCold), reduce(1, Element::kFire), reduce(2, Element::kLight), reduce(3, Element::kPoison),
};
// Logic 95: thủ ngoại/nội và kháng bốn hệ rất lớn (xe chiến Xi Vưu); tham số 6 là mã script.
constexpr std::array kChariotLines = {
    point(0, Stat::kDefencePhy), point(1, Stat::kDefenceMagic), point(2, Stat::kResistCold), point(3, Stat::kResistFire),
    point(4, Stat::kResistLight), point(5, Stat::kResistPoison),
};
// Logic 36: cấp dò ẩn thân.
constexpr std::array kDetectLines = {
    Line{.param = 0, .stat = Stat::kDetectLevel, .mode = Mode::kDetect, .element = Element::kCold}};
// Logic 79: không đi được (tham số 0 bằng 0) và tăng công mọi hệ theo phần trăm (tham số 1).
constexpr std::array kWeakenLines = {
    Line{.param = 0, .stat = Stat::kMoveSpeed, .mode = Mode::kStopMove, .element = Element::kCold},
    rate(1, Stat::kAttackPhy), rate(1, Stat::kAttackMagic), rate(1, Stat::kAttackCold), rate(1, Stat::kAttackFire),
    rate(1, Stat::kAttackLight), rate(1, Stat::kAttackPoison),
};

// Một bảng chỉ số: mỗi dòng đưa một tham số (đã nhân cường hóa) vào người mang. `script_param` >= 0 là ô chứa mã
// script gọi lại: ở lõi không có Lua nên chỉ phát sự kiện cho nơi gọi.
class StatTable final : public RefixedLogic {
public:
    StatTable(std::span<const Line> lines, std::int32_t script_param) noexcept : lines_(lines), script_param_(script_param) {}

    void on_active(HookCtx& ctx) const override {
        if (script_param_ < 0) return;
        const std::int32_t script = param_of(ctx.effect, static_cast<std::size_t>(script_param_));
        if (script <= 0) return;
        ctx.arena.emit(EventKind::kUnsupported, ctx.buff.caster, ctx.me.handle, static_cast<std::uint32_t>(script),
            static_cast<std::int32_t>(UnsupportedReason::kScript));
    }

    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& buff, const Effect& effect,
        Contribution& out) const override {
        for (const Line& line : lines_) {
            const std::int32_t raw = param_of(effect, line.param);
            switch (line.mode) {
            case Mode::kPoint:
                if (const std::int32_t value = scaled(buff, raw); value != 0) out.mods.add_point(line.stat, value);
                break;
            case Mode::kRate:
                if (const std::int32_t value = scaled(buff, raw); value != 0) out.mods.add_rate(line.stat, value);
                break;
            case Mode::kRageGain: out.mods.rage_gain_percent = actor::saturate32(static_cast<std::int64_t>(out.mods.rage_gain_percent) + scaled(buff, raw)); break;
            case Mode::kResistReduce:
                out.agg.resist_reduce[line.element] = actor::saturate32(static_cast<std::int64_t>(out.agg.resist_reduce[line.element]) + scaled(buff, raw));
                break;
            case Mode::kDetect: out.agg.detect = actor::saturate32(static_cast<std::int64_t>(out.agg.detect) + raw); break;
            case Mode::kStopMove:
                if (raw == 0 && (out.claimed & kClaimMove) == 0) {
                    out.agg.can_move = false;
                    out.claimed |= kClaimMove;
                }
                break;
            }
        }
    }

private:
    std::span<const Line> lines_;
    std::int32_t script_param_;
};

// Logic 14: cờ trạng thái. Tham số: 0 CanAction1, 1 CanAction2, 2 CanMove, 3 Unbreakable (-1 là không đặt; 1 là
// bật, 0 là tắt), 4 tốc chạy (% của tốc gốc), 5 cấp ẩn thân cộng, 6 cấp dò ẩn thân cộng, 7 mã mô hình (-1 không
// đổi), 8 mã thú cưỡi (-1 không đổi), 9 cho phép hay cấm (1 cho phép, 0 cấm, -1 không dùng), 10 tập kỹ năng, 11 tập
// hiệu ứng. Cờ bool: buff đứng trước trong danh sách thắng (bản gốc dừng ở buff đầu tiên đặt cờ).
class StateFlags final : public RefixedLogic {
public:
    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& buff, const Effect& effect,
        Contribution& out) const override {
        claim_flag(param_of(effect, 0), kClaimAction1, out.claimed, out.agg.can_action1);
        claim_flag(param_of(effect, 1), kClaimAction2, out.claimed, out.agg.can_action2);
        claim_flag(param_of(effect, 2), kClaimMove, out.claimed, out.agg.can_move);
        // Unbreakable: bản gốc đặt `0 < giá trị`, khác ba cờ kia đặt `1 == giá trị`.
        if (const std::int32_t unbreakable = param_of(effect, 3); unbreakable >= 0 && (out.claimed & kClaimUnbreakable) == 0) {
            out.agg.unbreakable = unbreakable > 0;
            out.claimed |= kClaimUnbreakable;
        }
        // Khác gốc: bản 2008 cộng tốc chạy theo từng buff đã làm tròn riêng; ở đây gộp làm một phần trăm của tốc gốc.
        if (const std::int32_t speed = scaled(buff, param_of(effect, 4)); speed != 0) out.mods.add_rate(Stat::kMoveSpeed, speed);
        out.agg.stealth = actor::saturate32(static_cast<std::int64_t>(out.agg.stealth) + param_of(effect, 5));
        out.agg.detect = actor::saturate32(static_cast<std::int64_t>(out.agg.detect) + param_of(effect, 6));
        if (const std::int32_t model = param_of(effect, 7); model >= 0) out.agg.model = model;
        if (const std::int32_t mount = param_of(effect, 8); mount >= 0) out.agg.mount = mount;
        const std::int32_t allow = param_of(effect, 9);
        const std::int32_t skills = param_of(effect, 10);
        const std::int32_t effects = param_of(effect, 11);
        if (allow >= 0 && (skills != kInvalidId || effects != kInvalidId)) {
            out.agg.filters.push_back(SkillFilter{.allow = allow == 1, .skill_collection = skills, .effect_collection = effects});
        }
    }

private:
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): giá trị, bit, tập bit đã chiếm, cờ đích khác vai (HP-07)
    static void claim_flag(std::int32_t value, std::uint8_t bit, std::uint8_t& claimed, bool& flag) noexcept {
        if (value < 0 || (claimed & bit) != 0) return;
        flag = value == 1;
        claimed |= bit;
    }
};

// Logic 35: choáng (không hành động được). Bản 2008 còn đổi AI sang trạng thái hoảng sợ; AI nằm ngoài lõi nên zone
// đọc Aggregates::can_action1/2 để làm việc đó.
class Terror final : public RefixedLogic {
public:
    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& /*buff*/, const Effect& /*effect*/,
        Contribution& out) const override {
        if ((out.claimed & kClaimAction1) == 0) {
            out.agg.can_action1 = false;
            out.claimed |= kClaimAction1;
        }
        if ((out.claimed & kClaimAction2) == 0) {
            out.agg.can_action2 = false;
            out.claimed |= kClaimAction2;
        }
    }
};

// Logic 83: miễn hẳn sát thương ngoại/nội công. Tham số 0, 1 khác 0 là bật tương ứng.
class ImmunityFlags final : public RefixedLogic {
public:
    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& /*buff*/, const Effect& effect,
        Contribution& out) const override {
        if (param_of(effect, 0) != 0) out.mods.raw[actor::AttrId::kImmunityP] = actor::saturate32(static_cast<std::int64_t>(out.mods.raw[actor::AttrId::kImmunityP]) + kFull);
        if (param_of(effect, 1) != 0) out.mods.raw[actor::AttrId::kImmunityM] = actor::saturate32(static_cast<std::int64_t>(out.mods.raw[actor::AttrId::kImmunityM]) + kFull);
    }

private:
    static constexpr std::int32_t kFull = 100;
};

// Logic 62: gom khí/dẫn khí không bị gián đoạn khi mất máu (tham số 0 khác 0).
class IgnoreDisturb final : public RefixedLogic {
public:
    void contribute(const Arena& /*arena*/, const Fighter& /*me*/, const Buff& /*buff*/, const Effect& effect,
        Contribution& out) const override {
        if (param_of(effect, 0) != 0) out.agg.ignore_disturb = true;
    }
};

} // namespace

void add_stat_effects(EffectRegistry& registry) {
    registry.add("stat_point", std::make_unique<StatTable>(kPointLines, -1));
    registry.add("stat_rate", std::make_unique<StatTable>(kRateLines, -1));
    registry.add("stat_hit", std::make_unique<StatTable>(kHitLines, -1));
    registry.add("stat_primary", std::make_unique<StatTable>(kPrimaryLines, -1));
    registry.add("stat_primary_rate", std::make_unique<StatTable>(kPrimaryRateLines, -1));
    registry.add("stat_mixed", std::make_unique<StatTable>(kMixedLines, -1));
    registry.add("stat_tough", std::make_unique<StatTable>(kToughLines, -1));
    registry.add("stat_attack_rate", std::make_unique<StatTable>(kAttackRateLines, -1));
    registry.add("stat_resist_reduce", std::make_unique<StatTable>(kReduceLines, -1));
    registry.add("stat_chariot", std::make_unique<StatTable>(kChariotLines, 6));
    registry.add("stat_detect", std::make_unique<StatTable>(kDetectLines, -1));
    registry.add("stat_weaken", std::make_unique<StatTable>(kWeakenLines, -1));
    registry.add("state_flags", std::make_unique<StateFlags>());
    registry.add("terror", std::make_unique<Terror>());
    registry.add("immunity_flags", std::make_unique<ImmunityFlags>());
    registry.add("ignore_disturb", std::make_unique<IgnoreDisturb>());
}

} // namespace game::combat::detail
