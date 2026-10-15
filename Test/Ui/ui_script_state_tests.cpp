// Hàm đọc trạng thái nhỏ và hàm nhờ game của script (native_state.cpp): giờ thế giới, hằng của gốc, tỉ lệ kinh nghiệm (chia số nguyên,
// chia cho 0, tràn), cờ chấm đỏ có biên không dấu, lớp hướng dẫn tân thủ (kiểm đối số, chủ lớp, lời nhờ), trang thanh menu.
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <cstdint>
#include <limits>
#include <string>

namespace game::test {
namespace {

void time_validity_and_constants(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return GetCurrentTime()") == "0", "chưa đặt WorldTime thì 0");
    static_cast<void>(script.variables.set("WorldTime", "1700000000abc"));
    context.expect(rig.eval("return GetCurrentTime()") == "1700000000", "atoi của biến");
    const hero::Hero who = hero::newcomer();
    context.expect(rig.eval("return Player:IsVaild()") == "0", "chưa có người chơi");
    script.facts.hero = &who;
    context.expect(rig.eval("return Player:IsVaild()") == "1", "đã có người chơi");
    context.expect(rig.eval("return Player:GetDefineHumanMaxLevel() .. '|' .. Player:GetDefineHumanMaxLevelSub()") == "129|119", "cấp tối đa");
    context.expect(rig.eval("return GameProduceLogin:IsWeGameClient() .. '|' .. GameProduceLogin:IsWeGameServer()") == "0|0", "mặc định không phải WeGame");
    script.facts.we_game_server = 1;
    context.expect(rig.eval("return GameProduceLogin:IsWeGameServer()") == "1", "đọc Facts");
}

void experience_ratio_is_integer_percent(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    hero::Hero who = hero::newcomer();
    const auto ratio = [&](std::int64_t now, std::int64_t top) {
        who.experience = {.now = now, .top = top};
        return rig.eval("return Player:GetHumanExpRatioToNeedExp()");
    };
    context.expect(rig.eval("return Player:GetHumanExpRatioToNeedExp()") == "0", "chưa có người chơi thì 0");
    script.facts.hero = &who;
    context.expect(ratio(5, 20) == "0.25", "5/20 = 25%");
    context.expect(ratio(1, 3) == "0.33", "1/3 cắt về 33%, không làm tròn");
    context.expect(ratio(2, 3) == "0.66", "2/3 cắt về 66%");
    context.expect(ratio(7, 0) == "0", "cần 0 thì 0 (gốc chia cho 0)");
    context.expect(ratio(-5, 10) == "0", "kinh nghiệm âm kẹp về 0");
    static_cast<void>(ratio(std::numeric_limits<std::int64_t>::max(), 100));
    context.expect(rig.eval("return Player:GetHumanExpRatioToNeedExp() > 0 and 'dương' or 'không dương'") == "dương",
        "kinh nghiệm cực lớn kẹp lại, phép nhân không tràn thành số âm");
}

void red_points_are_unsigned_bounded(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    script.facts.red_points.front() = 7;
    script.facts.red_points.back() = 9;
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow(0)") == "7", "ô đầu");
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow(42)") == "9", "ô cuối");
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow(43)") == "0", "ngoài miền");
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow(-1)") == "0", "so sánh không dấu: -1 là rất lớn");
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow('1')").contains("Lua_IsRedPointInUIShow parameter error!"), "chuỗi bị ném");
    context.expect(rig.eval("return DataPool:Lua_IsRedPointInUIShow()").contains("Lua_IsRedPointInUIShow parameter error!"), "thiếu đối số bị ném");
}

void fresh_man_guide_checks_arguments_and_records_the_request(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return GetFreshManGuideOwner()").empty(), "chưa mở thì chủ rỗng");
    context.expect(rig.eval("OpenFreshManGuideNew(1, 10.5, 20, 30, 40, 2, 3, 'MainMenuBar_2') return 'ok'") == "ok", "loại 1 đủ đối số");
    context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kOpenFreshManGuide &&
                       script.calls.front().text == "1\t10.5\t20\t30\t40\t2\t3\tMainMenuBar_2",
        "lời nhờ mở mang tám đối số, số in như Lua");
    context.expect(rig.eval("return GetFreshManGuideOwner()") == "MainMenuBar_2", "chủ lớp là đối số 8");
    script.calls.clear();
    context.expect(rig.eval("OpenFreshManGuideNew(2, 1, 2, 3, 4) return 'ok'") == "ok", "loại 2");
    context.expect(script.calls.size() == 1 && script.calls.front().text == "2\t1\t2\t3\t4", "loại 2 mang năm đối số");
    context.expect(rig.eval("return GetFreshManGuideOwner()") == "MainMenuBar_2", "loại 2 không đổi chủ");
    script.calls.clear();
    context.expect(rig.eval("OpenFreshManGuideNew(3, 1, 2, 3, 4) return 'ok'") == "ok" && script.calls.empty(), "loại khác không làm gì");
    context.expect(rig.eval("OpenFreshManGuideNew('1', 2, 3, 4, 5)").contains("Wrong Param1"), "đối số 1 phải là số nghiêm");
    context.expect(rig.eval("OpenFreshManGuideNew(1, 2, 3, 'x', 5)").contains("Wrong Param4"), "đối số 4");
    context.expect(rig.eval("OpenFreshManGuideNew(1, 2, 3, 4)").contains("Wrong Param5"), "thiếu đối số 5");
    context.expect(rig.eval("OpenFreshManGuideNew(1, 1, 2, 3, 4, 5, 6)").contains("Wrong ParamEx"), "loại 1 thiếu chủ");
    context.expect(rig.eval("OpenFreshManGuideNew(1, 1, 2, 3, 4, 5, 6, {})").contains("Wrong ParamEx"), "chủ không phải chuỗi");
    context.expect(script.calls.empty(), "lời gọi sai không ghi lời nhờ");
    context.expect(rig.eval("CloseFreshManGuide() return 'ok'") == "ok", "đóng");
    context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kCloseFreshManGuide, "lời nhờ đóng");
    context.expect(rig.eval("return GetFreshManGuideOwner()").empty(), "đóng xoá chủ");
}

void menu_page_server_time_and_clearing_functions(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(!script.menu_bar_page.has_value(), "chưa đặt trang");
    context.expect(rig.eval("SetMenuBarPageNumber(3.7) return 'ok'") == "ok" && script.menu_bar_page == 3, "ép (int)");
    context.expect(rig.eval("SetMenuBarPageNumber('4')").contains("Lua_SetMenuBarPageNumber Wrong Param") && script.menu_bar_page == 3,
        "chuỗi bị ném, trang giữ nguyên");
    context.expect(rig.eval("AskServerTimeAgain() return 'ok'") == "ok", "xin giờ");
    context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kAskServerTime, "lời nhờ xin giờ");
    script.calls.clear();
    const std::array<const char*, 7> silent = {"IMDressCleanUpPayBox()", "SetDefaultMouse()", "DataPool:Lua_ClearZiDianZengYingHaoActionItem()",
        "Lua_ClearZiDianZengYingHaoActionItem()", "City:ClearPhoenixPlainWarScore()", "Match:ClearHuaShanGRMatchScore()",
        "BWDH:CancelPlayerWatchPosDirection() CorpsUI_2016:CancelPlayerWatchPosDirection()"};
    for (const char* code : silent) {
        context.expect(rig.eval(std::string(code) + " return 'ok'") == "ok", std::string(code) + " chạy được");
    }
    context.expect(script.calls.empty(), "hàm xoá trạng thái chưa có không nhờ game gì");
}

constexpr std::array<Case, 5> kCases = {{
    {.name = "giờ, hợp lệ, hằng", .body = time_validity_and_constants},
    {.name = "tỉ lệ kinh nghiệm", .body = experience_ratio_is_integer_percent},
    {.name = "chấm đỏ có biên không dấu", .body = red_points_are_unsigned_bounded},
    {.name = "lớp hướng dẫn tân thủ", .body = fresh_man_guide_checks_arguments_and_records_the_request},
    {.name = "trang menu, giờ máy chủ, hàm xoá", .body = menu_page_server_time_and_clearing_functions},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
