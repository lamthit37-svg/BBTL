// Nạp danh mục nhiệm vụ: bảng đi vào máy chủ từ công cụ trích và từ tay người sửa, nên mọi ô sai phải thành lỗi nạp có dòng chứ
// không phải nhiệm vụ chạy sai thầm. Ghim: từng loại lỗi nạp, phát hiện vòng tiền đề (kể cả tự trỏ và phụ thuộc vào vòng),
// phân loại không chạy được kèm lý do, và tra NPC giao/trả.
#include "mission/catalog.hpp"

#include "mission/book.hpp"
#include "ops/ops.hpp"
#include "support/mission_data.hpp"
#include "support/mission_world.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using mission::LoadError;
using mission::Support;
namespace w = world;

bool load_fails(const MissionData& data, LoadError expected, std::string_view table = "") {
    const auto built = data.build();
    return !built.has_value() && built.error().error == expected && (table.empty() || built.error().table == table);
}

MissionData baseline() {
    MissionData data;
    w::fill(data);
    return data;
}

void replace_once(std::string& text, std::string_view from, std::string_view to) {
    const std::size_t at = text.find(from);
    if (at != std::string::npos) text.replace(at, from.size(), to);
}

void baseline_loads(Context& context) {
    const auto built = baseline().build();
    context.expect(built.has_value(), "thế giới thử nạp được");
    if (!built) return;
    context.expect(built->quests().size() == 16, "đủ số dòng nhiệm vụ của thế giới thử");
    const mission::Quest* const kill = built->by_script(w::kKillScript);
    context.expect(kill != nullptr && kill->objectives.size() == 1 && kill->objectives[0].kind == mission::ObjectiveKind::kKill &&
                       kill->objectives[0].count == 3 && kill->rewards.size() == 8 && kill->prereqs.empty(),
        "nhiệm vụ giết quái đọc đủ");
    const mission::Quest* const post = built->by_script(w::kPostScript);
    context.expect(post != nullptr && post->prereqs == std::vector<std::int32_t>{w::kKillQuest} && post->objectives.size() == 2,
        "tiền đề và mục tiêu của nhiệm vụ đưa thư");
    if (post == nullptr) return;
    context.expect(post->objectives[0].name == ops::name_id("信使") && post->objectives[1].flag == 1, "mã tên và cờ cấp đồ");
    const mission::Quest* const daily = built->by_script(w::kDailyScript);
    context.expect(daily != nullptr && daily->source == mission::Source::kScript && daily->repeat == mission::Repeat::kLoop &&
                       daily->watch == mission::kWatchKill && daily->hooks.size() == 1,
        "nhiệm vụ script: nguồn, lặp, cờ theo dõi lấy từ hook");
    context.expect(built->autos().size() == 2 && built->autos()[1].message == "#{YD_20080421_188}", "luật tự nhận");
}

void hostile_tables_are_refused(Context& context) {
    {
        MissionData data = baseline();
        data.quest({.script = w::kKillScript, .quest = 70});
        context.expect(load_fails(data, LoadError::kDuplicateScript, "mission_quests"), "script trùng");
    }
    for (const std::int32_t quest : {-1, 4096, 100000}) {
        MissionData data = baseline();
        data.quest({.script = 9100, .quest = quest});
        context.expect(load_fails(data, LoadError::kBadCell, "mission_quests"), "id nhiệm vụ ngoài 0..4095");
    }
    for (const auto& [from, to] : {std::pair<std::string_view, std::string_view>{"	table	", "	web	"},
             {"	ok	", "	maybe	"}, {"	loop	", "	daily	"}}) {
        MissionData data = baseline();
        replace_once(data.quests_, from, to);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_quests"), "từ khoá lạ của mission_quests");
    }
    {
        MissionData data = baseline();
        data.quest({.script = 9100, .quest = 70, .accept_cond = 99});
        context.expect(load_fails(data, LoadError::kBadReference, "mission_quests"), "điều kiện nhận không có");
    }
    {
        MissionData data = baseline();
        data.quest({.script = 9100, .quest = 70, .submit_fx = 99});
        context.expect(load_fails(data, LoadError::kBadReference, "mission_quests"), "bộ hiệu ứng nộp không có");
    }
    {
        MissionData data = baseline();
        data.quests_ += "abc\t70\n";
        context.expect(!data.build().has_value(), "dòng thiếu ô");
    }
    {
        MissionData data = baseline();
        replace_once(data.quests_, "1000\t10\t", "x1000\t10\t");
        context.expect(load_fails(data, LoadError::kBadCell, "mission_quests"), "ô số không phải số");
    }
    {
        MissionData data = baseline();
        data.objective(9999, 0, "kill", 0, 1, 1);
        context.expect(load_fails(data, LoadError::kUnknownScript, "mission_objectives"), "mục tiêu của script không có");
    }
    {
        MissionData data = baseline();
        data.objective(w::kKillScript, 5, "kill", 1, 1, 1);
        context.expect(load_fails(data, LoadError::kBadOrder, "mission_objectives"), "seq nhảy cóc");
    }
    {
        MissionData data = baseline();
        data.objective(w::kLootScript, 1, "dance", 1, 1, 1);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_objectives"), "loại mục tiêu lạ");
    }
    {
        MissionData data = baseline();
        data.objective(w::kAreaScript, 1, "kill", 1, 1, 5000000);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_objectives"), "số lượng quá lớn");
    }
    {
        MissionData data = baseline();
        data.objective(w::kAreaScript, 1, "loot", 1, 1, 1, 5, 101);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_objectives"), "tỉ lệ rơi trên 100");
    }
    {
        MissionData data = baseline();
        data.objective(w::kAreaScript, 1, "kill", 8, 1, 1);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_objectives"), "chỉ số tham số 8");
    }
    {
        MissionData data = baseline();
        data.reward(w::kAreaScript, 1, "secret", "exp", 0, 5);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_rewards"), "nhóm thưởng lạ");
    }
    {
        MissionData data = baseline();
        data.reward(w::kAreaScript, 1, "fixed", "gold_bar", 0, 5);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_rewards"), "loại thưởng lạ");
    }
    {
        MissionData data = baseline();
        data.reward(w::kAreaScript, 1, "fixed", "exp", 0, 5, 77);
        context.expect(load_fails(data, LoadError::kBadReference, "mission_rewards"), "điều kiện thưởng không có");
    }
    {
        MissionData data = baseline();
        data.reward(w::kAreaScript, 1, "fixed", "exp", 0, -5);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_rewards"), "thưởng âm");
    }
    {
        MissionData data = baseline();
        data.prereq(9999, 3);
        context.expect(load_fails(data, LoadError::kUnknownScript, "mission_prereqs"), "tiền đề của script không có");
    }
    {
        MissionData data = baseline();
        data.prereq(w::kAreaScript, 4096);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_prereqs"), "tiền đề ngoài miền");
    }
    {
        MissionData data = baseline();
        data.hook(w::kDailyScript, 1, "teleport", 3);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_hooks"), "sự kiện hook lạ");
    }
    {
        MissionData data = baseline();
        data.hook(w::kDailyScript, 1, "kill", 99);
        context.expect(load_fails(data, LoadError::kBadReference, "mission_hooks"), "hook trỏ bộ hiệu ứng không có");
    }
    {
        MissionData data = baseline();
        data.npc(w::kKillScript, "boss", 1, 1);
        context.expect(load_fails(data, LoadError::kUnknownWord, "mission_npcs"), "vai NPC lạ");
    }
    {
        MissionData data = baseline();
        data.npc(9999, "give", 1, 1);
        context.expect(load_fails(data, LoadError::kUnknownScript, "mission_npcs"), "NPC của script không có");
    }
    {
        MissionData data = baseline();
        data.automatic(2000, 5, 1, 0);
        context.expect(load_fails(data, LoadError::kBadCell, "mission_auto"), "cấp tự nhận ngoài miền");
    }
    {
        MissionData data = baseline();
        data.group(1, -5, "x");
        context.expect(load_fails(data, LoadError::kBadCell, "mission_name_groups"), "mẫu quái âm");
    }
    {
        MissionData data = baseline();
        data.group(1, -1, "x");
        context.expect(data.build().has_value(), "mẫu quái -1 là 'chưa có mẫu', chỉ bị bỏ qua");
    }
    {
        MissionData data;
        for (std::uint32_t script = 1; script <= 20001; ++script) data.quest({.script = script, .quest = 0});
        context.expect(load_fails(data, LoadError::kTooLarge, "mission_quests"), "quá nhiều nhiệm vụ");
    }
}

void cycles_block_quests(Context& context) {
    MissionData data;
    data.quest({.script = 1, .quest = 1});
    data.prereq(1, 2);
    data.quest({.script = 2, .quest = 2});
    data.prereq(2, 1);
    data.quest({.script = 3, .quest = 3});   // phụ thuộc vào vòng
    data.prereq(3, 1);
    data.quest({.script = 4, .quest = 4});   // tự trỏ
    data.prereq(4, 4);
    data.quest({.script = 5, .quest = 5});   // tiền đề ngoài danh mục
    data.prereq(5, 900);
    data.quest({.script = 6, .quest = 6});   // chuỗi bình thường
    data.quest({.script = 7, .quest = 7});
    data.prereq(7, 6);
    data.quest({.script = 8, .quest = 8});   // kim cương: 8 cần 6 và 7
    data.prereq(8, 6);
    data.prereq(8, 7);
    data.quest({.script = 9, .quest = 9});   // vòng ba nút
    data.prereq(9, 10);
    data.quest({.script = 10, .quest = 10});
    data.prereq(10, 11);
    data.quest({.script = 11, .quest = 11});
    data.prereq(11, 9);
    const auto built = data.build();
    context.expect(built.has_value(), "nạp được");
    if (!built) return;
    const auto support = [&](std::uint32_t script) { return built->by_script(script)->support; };
    for (const std::uint32_t script : {1U, 2U, 3U, 4U, 9U, 10U, 11U}) {
        context.expect(support(script) == Support::kBlocked, "nằm trên hoặc sau vòng thì bị chặn");
    }
    for (const std::uint32_t script : {5U, 6U, 7U, 8U}) {
        context.expect(support(script) == Support::kRunnable, "không dính vòng thì chạy được");
    }
    context.expect(built->report().blocked == 7 && built->report().missing_prereq_quests == 1,
        "đếm chặn, và đếm riêng nhiệm vụ có tiền đề ngoài danh mục");
}

void classification_reasons(Context& context) {
    MissionData data;
    data.quest({.script = 1, .quest = 1});
    data.objective(1, 0, "kill", 0, 0, 3);                    // không biết quái nào
    data.quest({.script = 2, .quest = 2});
    data.objective(2, 0, "talk", 0, 0, 1);                    // không biết NPC nào
    data.quest({.script = 3, .quest = 3});
    data.objective(3, 0, "talk", 0, 0, 1, 0, 0, 0, 0, "老人");  // có tên thì hợp lệ
    data.quest({.script = 4, .quest = 4});
    data.objective(4, 0, "loot", 0, 77, 1, 5, 50, 0, 1);      // loot ngẫu nhiên
    data.quest({.script = 5, .quest = 5});
    data.objective(5, 0, "escort", 0, 1, 1);
    data.quest({.script = 6, .quest = 6, .in_client = 0});
    data.quest({.script = 7, .quest = 7, .status = "unsupported"});
    data.quest({.script = 8, .quest = 8, .source = "script", .in_client = 0});
    const auto built = data.build();
    context.expect(built.has_value(), "nạp được");
    if (!built) return;
    const auto reason = [&](std::uint32_t script) { return built->by_script(script)->reason; };
    context.expect(built->by_script(1)->support == Support::kUnsupported && reason(1).find("không xác định") != std::string::npos,
        "mục tiêu giết không rõ quái");
    context.expect(built->by_script(2)->support == Support::kUnsupported, "mục tiêu nói chuyện không rõ NPC");
    context.expect(built->by_script(3)->runnable(), "nói chuyện có tên NPC thì chạy được");
    context.expect(built->by_script(4)->support == Support::kUnsupported && reason(4).find("MissionItem") != std::string::npos,
        "loot ngẫu nhiên nêu bảng thiếu");
    context.expect(built->by_script(5)->support == Support::kUnsupported && reason(5).find("hộ tống") != std::string::npos, "hộ tống");
    context.expect(built->by_script(6)->support == Support::kNotInClient, "ngoài client");
    context.expect(built->by_script(7)->support == Support::kUnsupported && !reason(7).empty(), "bảng trích đánh dấu chưa hỗ trợ mà không ghi lý do thì vẫn có lý do");
    context.expect(built->by_script(8)->support == Support::kNotInClient, "script ngoài client");
    mission::Options permissive;
    permissive.allow_not_in_client = true;
    const auto allowed = data.build(permissive);
    context.expect(allowed.has_value() && allowed->by_script(6)->runnable() && allowed->by_script(8)->runnable(),
        "tuỳ chọn cho phép nhiệm vụ ngoài client");
    MissionData wide;
    wide.quest({.script = 1, .quest = 1});
    for (int index = 0; index < 8; ++index) wide.objective(1, index, "talk", index, 1, 1, 0, 0, 0, 0, "x");
    const auto too_wide = wide.build();
    context.expect(too_wide.has_value() && too_wide->by_script(1)->support == Support::kUnsupported, "8 mục tiêu không đủ 8 tham số");
}

void npc_offers(Context& context) {
    MissionData data = baseline();
    data.quest({.script = 9100, .quest = 80});
    data.npc(9100, "give", 0, 3, "老人");       // chưa đặt guid: khớp theo (cảnh, tên)
    data.npc(9100, "turn", 0, 3, "老人");
    data.quest({.script = 9101, .quest = 81});
    data.npc(9101, "give", 0, 3, "-1");         // không tên, không guid: không ai giao được
    data.npc(9101, "target", 77, 3);            // vai target không phải chỗ giao
    const auto built = data.build();
    context.expect(built.has_value(), "nạp được");
    if (!built) return;
    const auto at_elder = built->offers_at(static_cast<std::uint32_t>(w::kElder), 3, 0);
    context.expect(at_elder.size() == 4, "trưởng làng giao và nhận hai nhiệm vụ bảng");
    context.expect(std::ranges::is_sorted(at_elder) && std::ranges::adjacent_find(at_elder) == at_elder.end(), "đã sắp và không trùng");
    const auto kill_here = std::ranges::count_if(at_elder, [](const mission::Offer& one) { return one.script == w::kKillScript; });
    context.expect(kill_here == 2, "giao và trả nhiệm vụ giết quái tại trưởng làng");
    const auto by_name = built->offers_at(0, 3, ops::name_id("老人"));
    context.expect(by_name.size() == 2 && by_name[0].script == 9100 && by_name[0].role == mission::NpcRole::kGive &&
                       by_name[1].role == mission::NpcRole::kTurn,
        "khớp theo (cảnh, tên)");
    context.expect(built->offers_at(0, 4, ops::name_id("老人")).empty(), "tên đúng nhưng sai cảnh");
    context.expect(built->offers_at(77, 3, 0).empty(), "vai target không tạo việc giao/trả");
    context.expect(built->offers_at(0, 3, 0).empty() && built->offers_at(123456, 3, 0).empty(), "NPC không có việc");
    context.expect(built->by_script(9101)->runnable(), "nhiệm vụ không NPC vẫn chạy được (tự nhận / handler)");
}

void variants_are_sorted(Context& context) {
    MissionData data;
    for (const std::uint32_t script : {30U, 10U, 20U}) data.quest({.script = script, .quest = 5, .level = static_cast<std::int32_t>(script)});
    const auto built = data.build();
    context.expect(built.has_value(), "nạp được");
    if (!built) return;
    const auto variants = built->variants(5);
    context.expect(variants.size() == 3 && variants[0]->script == 10 && variants[1]->script == 20 && variants[2]->script == 30,
        "biến thể theo script tăng dần dù dòng bảng đảo lộn");
    context.expect(built->variants(6).empty() && built->by_script(99) == nullptr, "id lạ");
}

constexpr std::array kCases{
    Case{.name = "baseline_loads", .body = baseline_loads},
    Case{.name = "hostile_tables_are_refused", .body = hostile_tables_are_refused},
    Case{.name = "cycles_block_quests", .body = cycles_block_quests},
    Case{.name = "classification_reasons", .body = classification_reasons},
    Case{.name = "npc_offers", .body = npc_offers},
    Case{.name = "variants_are_sorted", .body = variants_are_sorted},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
