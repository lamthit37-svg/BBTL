// Thế giới nhiệm vụ nhỏ dùng chung cho test của mission, talk, handlers: một nhiệm vụ mỗi loại bảng, nhiệm vụ vòng có biến thể,
// một nhiệm vụ script lặp theo ngày, và các nhiệm vụ bị chặn. Số liệu viết tay để test đọc được ngay ra mong đợi.
#pragma once

#include "ops/ops.hpp"
#include "support/mission_data.hpp"

#include <cstdint>

namespace game::test::world {

// Nhóm tên quái / NPC (mã băm tên chuẩn hoá, trùng với công cụ trích).
inline std::int32_t wolf() { return static_cast<std::int32_t>(ops::name_id("狼")); }
inline std::int32_t bear() { return static_cast<std::int32_t>(ops::name_id("熊")); }

// Mã quái và NPC dùng trong test.
inline constexpr std::uint32_t kWolfTemplate = 900;
inline constexpr std::uint32_t kBearTemplate = 910;
inline constexpr std::int32_t kElder = 501;     // trưởng làng: giao và nhận hầu hết
inline constexpr std::int32_t kCourier = 502;   // người nhận thư
inline constexpr std::int32_t kSceneId = 3;
inline constexpr std::int32_t kAreaId = 9;
inline constexpr int kRelation = 102;           // chỉ số bộ đếm quan hệ
inline constexpr int kBanSlot = 91;
inline constexpr int kDailySlot = 40;

// Id nhiệm vụ.
inline constexpr std::int32_t kKillQuest = 10;
inline constexpr std::int32_t kPostQuest = 11;
inline constexpr std::int32_t kLootQuest = 12;
inline constexpr std::int32_t kAreaQuest = 13;
inline constexpr std::int32_t kRingQuest = 20;
inline constexpr std::int32_t kDailyQuest = 30;
inline constexpr std::int32_t kCycleA = 40;
inline constexpr std::int32_t kCycleB = 41;
inline constexpr std::int32_t kOutsideQuest = 50;
inline constexpr std::int32_t kEscortQuest = 51;
inline constexpr std::int32_t kAutoQuest = 60;
inline constexpr std::int32_t kMilestoneQuest = 61;

// Script (khoá danh mục).
inline constexpr std::uint32_t kKillScript = 1000;
inline constexpr std::uint32_t kPostScript = 1001;
inline constexpr std::uint32_t kLootScript = 1002;
inline constexpr std::uint32_t kAreaScript = 1003;
inline constexpr std::uint32_t kRingLow = 2000;
inline constexpr std::uint32_t kRingMid = 2001;
inline constexpr std::uint32_t kRingMidTwin = 2002;
inline constexpr std::uint32_t kRingHigh = 2003;
inline constexpr std::uint32_t kDailyScript = 3000;
inline constexpr std::uint32_t kAutoScript = 6000;
inline constexpr std::uint32_t kMilestoneScript = 6001;

inline void fill(MissionData& data) {
    // ----- điều kiện và hiệu ứng của nhiệm vụ script hằng ngày -----
    data.cond(1, 0, 0, "level_at_least", 0, 3);
    data.cond(1, 0, 1, "counter_vs_clock", 0, kDailySlot, 1, -1);  // lần làm cuối < hôm nay
    data.cond(2, 0, 0, "objective_at_least", 0, kDailyQuest, 1, 2);
    data.cond(3, 0, 0, "event_monster_name", 0, 0, 0, 0, "狼");
    data.effect(1, 0, "notify", 0, 0, 0, "lua.daily.accept", "player");
    data.effect(2, 0, "set_counter_clock", kDailySlot, 1);
    data.effect(2, 1, "give_exp", 7);
    data.effect(3, 0, "objective_add", kDailyQuest, 1, 1, "", "", 3);
    data.effect(4, 0, "notify", 0, 0, 0, "lua.daily.abandon", "");

    // ----- nhiệm vụ bảng giết quái: kill 3 con sói, nhiều loại thưởng -----
    data.quest({.script = kKillScript, .quest = kKillQuest, .level = 5, .accept_guid = kElder, .turn_guid = kElder});
    data.objective(kKillScript, 0, "kill", 0, wolf(), 3, 0, 0, 0, 0, "狼");
    data.reward(kKillScript, 0, "fixed", "exp", 0, 100);
    data.reward(kKillScript, 1, "fixed", "money", 0, 50);
    data.reward(kKillScript, 2, "fixed", "bound_money", 0, 20);
    data.reward(kKillScript, 3, "fixed", "item", 4001, 2);
    data.reward(kKillScript, 4, "fixed", "relation", kRelation, 3);
    data.reward(kKillScript, 5, "choice", "item", 5001, 1);
    data.reward(kKillScript, 6, "choice", "item", 5002, 1);
    data.reward(kKillScript, 7, "hidden", "item", 6001, 1);
    data.npc(kKillScript, "give", kElder, 3);
    data.npc(kKillScript, "turn", kElder, 3);
    data.group(static_cast<std::uint32_t>(wolf()), kWolfTemplate, "狼");

    // ----- nhiệm vụ bảng đưa thư: nói chuyện với người nhận + giao 2 thư (nhiệm vụ cấp thư lúc nhận) -----
    data.quest({.script = kPostScript, .quest = kPostQuest, .level = 5, .accept_guid = kElder, .turn_guid = kElder});
    data.objective(kPostScript, 0, "talk", 0, kCourier, 1, 0, 0, kSceneId, 0, "信使");
    data.objective(kPostScript, 1, "deliver", 1, 7001, 2, 7001, 0, 0, 1);
    data.reward(kPostScript, 0, "fixed", "exp", 0, 200);
    data.prereq(kPostScript, kKillQuest);
    data.npc(kPostScript, "give", kElder, 3);
    data.npc(kPostScript, "turn", kElder, 3);
    data.npc(kPostScript, "target", kCourier, 3, "信使");

    // ----- nhiệm vụ bảng loot: giết gấu, nhặt 2 mật gấu với 100% -----
    data.quest({.script = kLootScript, .quest = kLootQuest, .level = 1, .accept_guid = kElder, .turn_guid = kElder});
    data.objective(kLootScript, 0, "loot", 0, bear(), 2, 8001, 100, 0, 0, "熊");
    data.reward(kLootScript, 0, "fixed", "exp", 0, 10);
    data.group(static_cast<std::uint32_t>(bear()), kBearTemplate, "熊");

    // ----- nhiệm vụ bảng vào vùng -----
    data.quest({.script = kAreaScript, .quest = kAreaQuest, .level = 1, .accept_guid = kElder, .turn_guid = kElder});
    data.objective(kAreaScript, 0, "area", 0, kAreaId, 1, 0, 0, kSceneId);
    data.reward(kAreaScript, 0, "fixed", "exp", 0, 30);

    // ----- nhiệm vụ vòng: ba biến thể theo cấp (cặp song sinh cùng cấp 10), cấm nhận lại 900 s sau khi bỏ -----
    const QuestRow ring{.quest = kRingQuest, .level = 10, .repeat = "loop", .accept_guid = kElder, .turn_guid = kElder,
        .penalty = 2, .ban_slot = kBanSlot, .ban_seconds = 900};
    for (const auto& [script, level] : {std::pair{kRingLow, 1}, std::pair{kRingMid, 10}, std::pair{kRingMidTwin, 10},
             std::pair{kRingHigh, 30}}) {
        QuestRow row = ring;
        row.script = script;
        row.level = level;
        data.quest(row);
        data.objective(script, 0, "kill", 0, wolf(), 1, 0, 0, 0, 0, "狼");
        data.reward(script, 0, "fixed", "exp", 0, std::int64_t{10} * level);
        data.reward(script, 1, "fixed", "relation", kRelation, 1);
    }

    // ----- nhiệm vụ script hằng ngày: lặp, nhận một lần mỗi ngày, cần giết 2 con sói qua hook -----
    data.quest({.script = kDailyScript, .quest = kDailyQuest, .source = "script", .level = 3, .repeat = "loop",
        .accept_cond = 1, .ready_cond = 2, .accept_fx = 1, .submit_fx = 2, .abandon_fx = 4});
    data.objective(kDailyScript, 0, "progress", 1, 0, 2);
    data.reward(kDailyScript, 0, "fixed", "money", 0, 15);
    data.hook(kDailyScript, 0, "kill", 3);

    // ----- chặn: vòng tiền đề, ngoài client, chưa hỗ trợ, hộ tống -----
    data.quest({.script = 4000, .quest = kCycleA});
    data.prereq(4000, kCycleB);
    data.quest({.script = 4001, .quest = kCycleB});
    data.prereq(4001, kCycleA);
    data.quest({.script = 4100, .quest = kOutsideQuest, .in_client = 0});
    data.quest({.script = 4200, .quest = 52, .source = "script", .status = "unsupported", .reason = "cần xử lý tay"});
    data.quest({.script = 4300, .quest = kEscortQuest});
    data.objective(4300, 0, "escort", 0, 1, 1);

    // ----- tự nhận và mốc cấp -----
    data.quest({.script = kAutoScript, .quest = kAutoQuest, .level = 1, .accept_guid = kElder, .turn_guid = kElder});
    data.objective(kAutoScript, 0, "talk", 0, kElder, 1);
    data.quest({.script = kMilestoneScript, .quest = kMilestoneQuest, .source = "script", .level = 5});
    data.automatic(3, kAutoQuest, kAutoScript, 0);
    data.automatic(-1, kMilestoneQuest, kMilestoneScript, 0, 5, 0, 1, "#{YD_20080421_188}");
}

}  // namespace game::test::world
