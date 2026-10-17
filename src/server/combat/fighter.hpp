/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/fighter.hpp
 *  PHÂN HỆ   : Server / Combat / Fighter
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Người ra đòn / chịu đòn: thân thể (actor::Body) cộng danh sách buff, sổ kỹ
 *    năng, hồi chiêu và trạng thái đang ra chiêu. Là túi dữ liệu có bất biến
 *    nhỏ (số buff <= kMaxBuffs, số hồi chiêu <= kMaxCooldowns, số kỹ năng <=
 *    kMaxSkills); mọi thay đổi đi qua Arena (arena.hpp) để sự kiện và hook chạy
 *    đúng thứ tự.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: GameServer 2008 Obj_Character*.cpp (danh sách buff _IMPACT_LIST, hồi chiêu, ActionParams),
// Common/GameStruct_Impact.h (OWN_IMPACT). Thời gian tính bằng tick của nhịp zone (mặc định 20 Hz);
// mili giây làm tròn lên. Hết hạn lưu thành tick tuyệt đối của nhịp lúc ghi.

#pragma once

#include "actor/body.hpp"
#include "combat/catalog.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::combat {

inline constexpr std::int64_t kTicksPerSecond = 20;
inline constexpr std::int64_t kTickMs = 1000 / kTicksPerSecond;
inline constexpr std::size_t kBuffSlots = 8;  // MAX_IMPACT_PARAM_NUMBER: trạng thái riêng của một logic hiệu ứng

// Mili giây thiết kế sang tick, làm tròn lên; âm hoặc 0 là 0.
[[nodiscard]] constexpr std::int64_t ms_to_ticks(std::int64_t milliseconds) noexcept {
    return ids::to_ticks(milliseconds, kTicksPerSecond).count;
}

// Một buff đang mang, đồng thời là "tác động" đang chờ giao (OWN_IMPACT).
struct Buff {
    std::int32_t sn = -1;                       // số thứ tự duy nhất trong danh sách của người mang
    std::uint32_t effect = 0;                   // dòng effects.tsv
    std::uint32_t skill = 0;                    // kỹ năng đã sinh ra buff (0 nếu không)
    ids::EntityHandle caster{};
    std::uint64_t caster_character = 0;         // CharacterId của người tạo, 0 nếu không phải người chơi
    bool by_player = false;
    bool critical = false;
    bool fade_out = false;
    std::int64_t continuance = 0;               // tick; -1 vô hạn
    std::int64_t elapsed = 0;                   // tick đã trôi
    std::int64_t interval_elapsed = 0;
    std::int32_t refix = 0;                     // phần trăm cường hóa cộng dồn (RefixPowerByRate)
    std::array<std::int32_t, kBuffSlots> slot{}; // trạng thái riêng của logic (lượt còn lại, máu khiên...)

    friend constexpr bool operator==(const Buff&, const Buff&) noexcept = default;
};

struct SkillEntry {
    std::uint32_t id = 0;
    std::uint8_t level = 1;

    friend constexpr bool operator==(const SkillEntry&, const SkillEntry&) noexcept = default;
};

struct Cooldown {
    std::int32_t id = 0;
    ids::Tick until;  // hết hồi chiêu khi now >= until

    friend constexpr bool operator==(const Cooldown&, const Cooldown&) noexcept = default;
};

// Mục tiêu của một lần ra chiêu.
struct Target {
    ids::EntityHandle unit{};
    Position position{};
    std::int32_t direction_deg = 0;
};

// Bản kỹ năng đã dựng cho một lượt ra chiêu: số liệu cấp kỹ năng sau khi buff cường hóa (SkillInfo_T).
struct CastInfo {
    std::uint32_t skill = 0;
    std::uint8_t level = 1;
    std::int32_t logic = -1;
    std::int32_t cooldown_ms = 0;
    std::int32_t charge_ms = 0;
    std::int32_t channel_ms = 0;
    std::int32_t accuracy = -1;       // -1: tính từ trúng/né
    std::int32_t critical = -1;       // -1: dùng hội tâm của người ra chiêu
    std::int32_t power_value = 0;     // cường hóa uy lực theo điểm
    std::int32_t power_rate = 0;      // cường hóa uy lực theo phần trăm
    std::int32_t deplete_value = 0;
    std::int32_t deplete_rate = 0;
    std::int32_t time_value = 0;      // cường hóa thời gian hiệu ứng/bẫy
    std::int32_t time_rate = 0;
    std::int32_t target_level = -1;   // giới hạn cấp mục tiêu, -1 không giới hạn
    std::int32_t strike_spent = 0;    // điểm liên kích đã tiêu ở lần ra chiêu này (chọn đoạn liên kích)
    std::array<Term, kConditionTerms> terms{};
    std::array<std::int32_t, kSkillParamCount> param{};
};

// Hồi sinh chờ xử lý (buff "hồi sinh khi chết" và hiệu ứng hồi sinh).
struct ReliveInfo {
    actor::Revival revival{};
};

// Bộ lọc kỹ năng/hiệu ứng do buff đặt (logic hiệu ứng 14, tham số 9..11).
struct SkillFilter {
    bool allow = false;                 // true: chỉ cho phép tập; false: cấm tập
    std::int32_t skill_collection = -1;
    std::int32_t effect_collection = -1;

    friend constexpr bool operator==(const SkillFilter&, const SkillFilter&) noexcept = default;
};

// Giá trị dẫn xuất từ danh sách buff, tính lại mỗi khi danh sách đổi.
struct Aggregates {
    bool can_action1 = true;
    bool can_action2 = true;
    bool can_move = true;
    bool unbreakable = false;
    std::int32_t stealth = 0;
    std::int32_t detect = 0;
    std::int32_t model = -1;
    std::int32_t mount = -1;
    bool ignore_disturb = false;    // gom khí/dẫn không bị gián đoạn khi mất máu (logic hiệu ứng 62)
    ElementValues resist_reduce;
    std::vector<SkillFilter> filters;

    friend bool operator==(const Aggregates&, const Aggregates&) noexcept = default;
};

// Trạng thái ra chiêu kéo dài: gom khí hoặc dẫn.
struct ActionState {
    enum class Phase : std::uint8_t { kIdle, kCharging, kChanneling };
    Phase phase = Phase::kIdle;
    CastInfo info;
    Target target;
    std::int64_t remaining = 0;         // tick còn lại của gom/dẫn
    std::int64_t charge_total = 0;      // tổng tick gom
    std::int64_t interval = 0;          // tick một nhịp dẫn
    std::int64_t interval_elapsed = 0;
    std::uint32_t logic_count = 0;      // số đếm logic lúc bắt đầu, để buff hỗ trợ dẫn kiểm
};

enum class FighterKind : std::uint8_t { kHuman, kMonster };

struct Fighter {
    Fighter() = default;
    Fighter(ids::EntityHandle handle_in, FighterKind kind_in, actor::Body body_in)
        : handle(handle_in), kind(kind_in), body(std::move(body_in)) {}

    ids::EntityHandle handle{};
    FighterKind kind = FighterKind::kMonster;
    std::uint64_t character = 0;        // CharacterId của người chơi, 0 nếu không phải
    actor::Body body;
    Position position{};
    bool female = false;
    std::int32_t weapon_type = -1;      // loại vũ khí đang cầm, -1 là tay không
    std::int32_t scene_type = 0;

    std::vector<SkillEntry> skills;
    std::vector<Cooldown> cooldowns;
    ids::Tick auto_repeat_until;      // hồi chiêu của đòn tự động lặp

    std::array<Buff, kMaxBuffs> buffs{};
    std::size_t buff_count = 0;
    std::int32_t sn_seed = 0;
    Aggregates aggregates;
    actor::Modifiers passive_modifiers;  // cộng từ kỹ năng bị động, hợp vào set_buffs cùng buff
    std::int32_t friendliness_points = 0; // điểm thân thiện nhận được (logic 58), module xã hội đọc đi

    ActionState action;
    ids::Tick action_lock_until;      // đang diễn hoạt động của đòn tức thời tới tick này
    std::uint32_t logic_count = 0;      // tăng mỗi lần bắt đầu hành động mới
    std::optional<ReliveInfo> relive;

    [[nodiscard]] bool alive() const noexcept { return body.alive(); }
    [[nodiscard]] const Buff* find_buff_by_effect(std::uint32_t effect_id) const noexcept {
        for (std::size_t i = 0; i < buff_count; ++i) {
            if (buffs.at(i).effect == effect_id && !buffs.at(i).fade_out) return &buffs.at(i);
        }
        return nullptr;
    }
};

} // namespace game::combat
