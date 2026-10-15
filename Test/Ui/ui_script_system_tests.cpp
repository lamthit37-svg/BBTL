// Hàm hệ thống nhỏ của script giao diện (ui/script/native_system): đồng hồ int32 quấn vòng, cờ nhắc cập nhật có biên, việc script nhờ
// game (sự kiện đóng hộp thoại, cờ phím tắt), và các hằng của gốc. Sai ở đây hỏng thầm (chỉ số âm đọc ngoài mảng, đồng hồ không quấn
// như (int) của gốc, sự kiện đóng hộp thoại đẩy sai tên) nên có test.
#include "support/script_rig.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <string>

namespace game::test {
namespace {

void tick_count_wraps_like_the_original_int_cast(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return OSAPI:GetTickCount()") == "0", "đồng hồ bắt đầu từ 0");
    script.facts.clock = std::chrono::milliseconds(1234567);
    context.expect(rig.eval("return OSAPI:GetTickCount()") == "1234567", "mili giây của khung");
    // 2^31 ms là mốc quấn: (int) của gốc cho số âm.
    script.facts.clock = std::chrono::milliseconds(std::int64_t{1} << 31);
    context.expect(rig.eval("return OSAPI:GetTickCount()") == "-2147483648", "quấn sang âm ở 2^31");
    script.facts.clock = std::chrono::milliseconds((std::int64_t{1} << 32) + 5);
    context.expect(rig.eval("return OSAPI:GetTickCount()") == "5", "quấn vòng 32 bit");
}

void update_tip_flags_are_bounds_checked(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    script.facts.update_tips.front() = 7;
    script.facts.update_tips.back() = 9;
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag(0)") == "7", "cờ đầu");
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag(99)") == "9", "cờ cuối");
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag(100)") == "0", "ngoài mảng là 0");
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag(-1)") == "0", "chỉ số âm là 0, không đọc trước mảng");
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag(1e18)") == "0", "số khổng lồ là 0");
    context.expect(rig.eval("return DataPool:Lua_GetUpdateTipsFlag('0')").contains("Lua_GetUpdateTipsFlag parameter error!"),
        "chuỗi số không qua kiểm số nghiêm");
}

void requests_to_the_game_are_recorded(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("CloseMessageBoxCommon() return 'ok'") == "ok", "CloseMessageBoxCommon chạy");
    context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kPushEvent &&
                       script.calls.front().text == "MESSAGEBOX_COMMON_CLOSE",
        "đẩy MESSAGEBOX_COMMON_CLOSE không đối số");
    context.expect(!script.can_use_hotkey.has_value(), "chưa đặt phím tắt");
    context.expect(rig.eval("DataPool:SetCanUseHotKey(0) return 'ok'") == "ok" && script.can_use_hotkey == 0, "đặt 0");
    context.expect(rig.eval("DataPool:SetCanUseHotKey(1.9) return 'ok'") == "ok" && script.can_use_hotkey == 1, "ép (int) cắt phần thập phân");
    context.expect(rig.eval("DataPool:SetCanUseHotKey('0') return 'ok'") == "ok" && script.can_use_hotkey == 1,
        "đối số không phải số nghiêm bị bỏ qua, không báo lỗi");
}

void constants_and_flags_follow_the_original(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return Infant:GetMaxSkillNum()") == "4", "con có tối đa 4 skill");
    context.expect(rig.eval("return KaJi:LuaFnIsKaJiServer()") == "0", "bảng KaJi rỗng thì không phải máy chủ KaJi");
    context.expect(rig.eval("return KaJi:LuaFnGetKaJiType(3)") == "0", "loại KaJi là 0");
    context.expect(rig.eval("return KaJi:LuaFnGetKaJiType('3')").contains("LUA:LuaFnGetKaJiType param parameter1 error"),
        "đối số phải là số nghiêm");
    context.expect(rig.eval("return ZBS:IsViewerWatching()") == "0" && rig.eval("return IsDfsSpeicalServer()") == "0", "cờ mặc định 0");
    script.facts.viewer_watching = 3;
    script.facts.dfs_server = 2;
    context.expect(rig.eval("return ZBS:IsViewerWatching() .. '|' .. IsDfsSpeicalServer()") == "3|2", "cờ đọc từ Facts");
}

constexpr std::array<Case, 4> kCases = {{
    {.name = "GetTickCount quấn như (int)", .body = tick_count_wraps_like_the_original_int_cast},
    {.name = "cờ nhắc cập nhật có biên", .body = update_tip_flags_are_bounds_checked},
    {.name = "việc nhờ game được ghi lại", .body = requests_to_the_game_are_recorded},
    {.name = "hằng và cờ theo gốc", .body = constants_and_flags_follow_the_original},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
