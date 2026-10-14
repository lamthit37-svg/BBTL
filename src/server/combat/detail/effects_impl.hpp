#pragma once
// Hạ tầng dùng chung của các tệp mã logic hiệu ứng (effects*.cpp): sổ đăng ký mã xử lý theo tên, hàm lấy tham số an
// toàn, gửi hiệu ứng con theo vai. Header nội bộ module combat: module khác không include.

#include "actor/numeric.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/detail/effects.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <string_view>

namespace game::combat::detail {

// Sổ đăng ký mã xử lý theo tên (cột `handler` của effect_logics.tsv). Dựng một lần khi nạp lần đầu, rồi chỉ đọc.
// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của std::map (HP-07)
class EffectRegistry {
public:
    void add(std::string_view name, std::unique_ptr<EffectLogic> logic);
    [[nodiscard]] const EffectLogic* find(std::string_view name) const noexcept;

private:
    std::map<std::string, std::unique_ptr<EffectLogic>, std::less<>> entries_;
};

void add_damage_effects(EffectRegistry& registry);
void add_stat_effects(EffectRegistry& registry);
void add_hook_effects(EffectRegistry& registry);

// Tham số thứ `index` của dòng hiệu ứng; ngoài miền là 0 (dòng hiệu ứng luôn đủ 16 ô nên chỉ để an toàn).
[[nodiscard]] inline std::int32_t param_of(const Effect& effect, std::size_t index) noexcept {
    return index < effect.param.size() ? effect.param.at(index) : 0;
}

// Ô trạng thái riêng của buff; ngoài miền là 0 / bỏ qua.
[[nodiscard]] inline std::int32_t slot_of(const Buff& buff, std::size_t index) noexcept {
    return index < buff.slot.size() ? buff.slot.at(index) : 0;
}
inline void set_slot(Buff& buff, std::size_t index, std::int32_t value) noexcept {
    if (index < buff.slot.size()) buff.slot.at(index) = value;
}

// Mét sang centimet (tham số bán kính của dữ liệu là mét).
inline constexpr std::int32_t kCmPerMeter = 100;

// Logic mà cường hóa chỉ cộng dồn vào Buff::refix; các hook đọc lại qua scaled().
class RefixedLogic : public EffectLogic {
public:
    bool refix_power(Buff& buff, const Effect& /*effect*/, std::int32_t percent) const override {
        buff.refix = actor::saturate32(static_cast<std::int64_t>(buff.refix) + percent);
        return true;
    }
};

// Gửi hiệu ứng `effect_id` từ người tạo buff tới `receiver`. `computed`: hiệu ứng sát thương công thức (logic
// damage_attack) tính từ chỉ số hai bên như khi nằm trong kỹ năng. Trả true khi đã xếp hàng.
bool send_sub(const HookCtx& ctx, const Fighter& receiver, std::int32_t effect_id, bool critical, bool computed = false);

// Gửi mọi hiệu ứng khai trong vai loại `kind` của dòng logic tới `receiver`; mỗi vai có thể có xác suất (`@`).
// Trả số hiệu ứng đã gửi.
std::int32_t send_roles(const HookCtx& ctx, RoleKind kind, const Fighter& receiver, bool computed = false);

// Rút xác suất phần trăm: giá trị >= 100 luôn qua (không rút), <= 0 không bao giờ qua; còn lại rút Rand100 và qua
// khi roll < giá trị. Khác gốc: bản 2008 qua khi roll <= giá trị (lệch +1%).
[[nodiscard]] bool roll_chance(Arena& arena, std::int32_t percent);

// Người tạo buff, nullptr nếu đã rời đấu trường.
[[nodiscard]] Fighter* caster_of(HookCtx& ctx);

// Dùng một lần "bỏ qua phòng thủ" (logic 64) của người tấn công. true khi lần này được bỏ qua phòng thủ.
[[nodiscard]] bool consume_ignore_defence(Arena& arena, Fighter& attacker);

} // namespace game::combat::detail
