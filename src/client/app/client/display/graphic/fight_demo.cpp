/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/fight_demo.cpp
 *  PHÂN HỆ   : Display / Graphic / FightDemo
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Công cụ thử --talk-demo fight và fall: quái của --creature đánh được, mỗi
 *    chiêu người chơi gửi được đáp bằng tin thế giới đúng hình protocol v6 thay
 *    cho máy chủ (SkillCast, CombatEvent, EntityHurt, EntityDied), để nhìn và
 *    thử vòng đánh tự động, động tác, số bay khi chưa có máy chủ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Công cụ thử của dự án, client gốc không có. Kịch bản không giữ trạng thái nào ngoài bộ đếm chiêu và sinh lực quái: chiêu thứ
// 5 trượt, thứ 4 hội tâm, thứ 7 kèm một đợt hồi cho chính mình; mỗi đòn trúng lấy một phần tư sinh lực quái, đòn thứ tư hạ nó.
//
// Cách hỏng đã tính trước (CL-03): chiêu nhắm vào quái không còn trong cảnh -> trả Declined(kGone) như máy chủ, không dựng
// tin thế giới nào; việc người chơi nhờ không phải chiêu hay hồi sinh (Talk...) -> bỏ. Hồi sinh được đáp bằng sinh lực đầy.

#include "client/display/graphic/state.hpp"

#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "client/display/display.hpp"
#include "ui/panel/talk.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <mutex>
#include <ranges>
#include <utility>
#include <variant>
#include <vector>

namespace game::client {
namespace {

namespace tk = ui::panel::talk;

constexpr std::int32_t kFullLife = 100;
constexpr std::int32_t kLifePerHit = 25;
constexpr std::uint32_t kMissEvery = 5;
constexpr std::uint32_t kCriticalEvery = 4;
constexpr std::uint32_t kHealEvery = 7;
constexpr std::int32_t kHealValue = 120;
constexpr std::int32_t kFallDamage = 999;

// Sát thương giả, đều và có phần lẻ nhìn như thật: 80..479.
[[nodiscard]] std::int32_t damage_of(std::uint32_t hit) noexcept {
    return 80 + static_cast<std::int32_t>((hit * 37U) % 400U);
}

} // namespace

// Chiêu Cái Bang trên thanh, đúng id sect 2 của skills.tsv bản 2026. Phím 1 là ô đầu.
constexpr std::array<std::uint16_t, 10> kGaibangSkills{341, 347, 358, 357, 360, 361, 364, 365, 353, 359};

void Display::State::start_fight_demo(std::uint32_t first) {
    is_online_play = true;
    apply_vitals(tk::Vitals{.hp = 800, .hp_max = 1000, .mp = 400, .mp_max = 500, .rage = 0, .rage_max = 100});
    // Gậy Cái Bang (丐帮门派高手武器): cả thanh là chiêu môn, phím 1 là 蟠龙击. Không có gậy thì đánh thường
    // đứng trước và --skill đứng sau, để đuổi mục tiêu vẫn ra đòn thường.
    constexpr std::uint32_t kGaibangStaff = 10101047;
    std::vector<tk::Learned> learned;
    if (weapon_item && *weapon_item == kGaibangStaff) {
        for (const std::uint16_t skill : kGaibangSkills) {
            learned.push_back(tk::Learned{.skill = skill, .level = 1, .cooldown_ms = 0});
        }
    } else {
        // Nhân vật mới và mọi nhân vật không cầm gậy Cái Bang: giữ bộ skill đang có (mặc định là bộ tân thủ).
        for (const std::uint32_t skill : hero.skills) {
            if (skill > 0xFFFFU) continue;
            learned.push_back(tk::Learned{.skill = static_cast<std::uint16_t>(skill), .level = 1, .cooldown_ms = 0});
        }
        const bool is_known = skill_id && std::ranges::find(hero.skills, *skill_id) != hero.skills.end();
        if (skill_id && *skill_id > 0 && *skill_id <= 0xFFFFU && !is_known) {
            learned.push_back(tk::Learned{.skill = static_cast<std::uint16_t>(*skill_id), .level = 1, .cooldown_ms = 0});
        }
    }
    apply_skills(tk::Skills{.learned = std::move(learned)});
    combat.engage(first);
}

// Chết ở chiêu đầu (--talk-demo fall): quái đánh trả một đòn chí mạng, SelfVitals về 0, DeathNotice, EntityDied của chính mình.
void Display::State::fall_in_demo(std::vector<cast::Note>& notes, std::uint32_t killer) {
    const std::uint32_t self = people.self_id();
    notes.emplace_back(cast::Struck{.source = killer,
        .target = self,
        .skill = 0,
        .kind = cast::Blow::kDamage,
        .value = kFallDamage,
        .is_critical = false});
    notes.emplace_back(cast::Died{.id = self, .killer = killer});
    const std::scoped_lock<std::mutex> locked(talk_guard);
    talk_heard.emplace_back(tk::Vitals{.hp = 0, .hp_max = 1000, .mp = 400, .mp_max = 500, .rage = 0, .rage_max = 100});
    talk_heard.emplace_back(tk::Slain{.exp_lost = 120, .money_lost = 0});
}

void Display::State::answer_fight_demo(const tk::Say& said) {
    if (std::holds_alternative<tk::Revive>(said)) {
        const std::scoped_lock<std::mutex> locked(talk_guard);
        talk_heard.emplace_back(tk::Vitals{.hp = 1000, .hp_max = 1000, .mp = 500, .mp_max = 500, .rage = 0, .rage_max = 100});
        return;
    }
    const auto* asked = std::get_if<tk::Cast>(&said);
    if (asked == nullptr) return;
    const cast::Actor* target = people.find(asked->target);
    if (target == nullptr) {
        const std::scoped_lock<std::mutex> locked(talk_guard);
        talk_heard.emplace_back(tk::Declined{.why = tk::Decline::kGone});
        return;
    }
    ++demo_hits;
    const std::uint32_t self = people.self_id();
    std::vector<cast::Note> notes;
    notes.emplace_back(cast::Casting{.source = self,
        .skill = asked->skill,
        .target = target->id,
        .x = target->x,
        .z = target->z,
        .level = 1,
        .seq = asked->seq});
    const bool is_miss = demo_hits % kMissEvery == 0;
    const bool is_critical = demo_hits % kCriticalEvery == 0;
    const std::int32_t damage = damage_of(demo_hits) * (is_critical ? 2 : 1);
    notes.emplace_back(cast::Struck{.source = self,
        .target = target->id,
        .skill = asked->skill,
        .kind = is_miss ? cast::Blow::kMiss : cast::Blow::kDamage,
        .value = is_miss ? 0 : damage,
        .is_critical = is_critical && !is_miss});
    if (demo_hits % kHealEvery == 0) {
        notes.emplace_back(cast::Struck{.source = self,
            .target = self,
            .skill = asked->skill,
            .kind = cast::Blow::kHeal,
            .value = kHealValue,
            .is_critical = false});
    }
    if (talk_demo == "fall" && demo_hits == 1) fall_in_demo(notes, target->id);
    if (!is_miss) {
        std::int32_t& life = demo_life.try_emplace(target->id, kFullLife).first->second;
        life = std::max(0, life - kLifePerHit);
        notes.emplace_back(cast::Hurt{.id = target->id, .hp_percent = static_cast<std::uint8_t>(life)});
        if (life == 0) notes.emplace_back(cast::Died{.id = target->id, .killer = self});
    }
    const std::scoped_lock<std::mutex> locked(world_guard);
    for (cast::Note& note : notes) world_notes.push_back(std::move(note));
}

} // namespace game::client
