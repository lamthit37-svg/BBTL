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
#include <string_view>
#include <utility>

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

// native_events.cpp là mã sinh: ba dạng đối số (không có, chuỗi hằng, số in %d kể cả -1) qua hàm toàn cục và hàm của bảng.
void generated_event_pushes_carry_their_arguments(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const std::array<std::pair<std::string_view, std::string_view>, 5> cases = {{
        {"OpenSafeScore()", "OPEN_SAFECENTER_SAFESCORE"},
        {"ToggleYuanbaoShop()", "TOGGLE_YUANBAOSHOP\tnormal"},
        {"SystemSetup:OpenOtherJingMai()", "OPEN_OTHERPLAYER_JINGMAI\t-1"},
        {"City:OpenPhoenixPlainWarScoreMultiTable()", "SHOW_PHOENIXPLAINWAR_SCORE_M\t1"},
        {"City:ClosePhoenixPlainWarScoreMultiTable()", "SHOW_PHOENIXPLAINWAR_SCORE_M\t0"},
    }};
    for (const auto& [call, wanted] : cases) {
        script.calls.clear();
        context.expect(rig.eval(std::string(call) + " return 'ok'") == "ok", std::string(call) + " chạy được");
        context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kPushEvent && script.calls.front().text == wanted,
            std::string(call) + " đẩy " + std::string(wanted));
    }
}

// Hàm mở cửa sổ có kiểm khoá cảnh địa ngục (IsInHell) và đối số số lấy từ script: thứ tự "ném trước khoá" / "khoá trước ném" khác
// nhau theo từng hàm của gốc, đối số không phải số (chuỗi số cũng không) hoặc bị bỏ qua im lặng hoặc ném câu riêng của hàm.
void locked_pushes_follow_the_hell_scene_and_arguments(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const auto pushed = [&](std::string_view code) {
        script.calls.clear();
        const std::string result = rig.eval(code);
        if (script.calls.empty()) return result.starts_with("LỖI") ? result : std::string("không đẩy");
        return script.calls.front().text;
    };
    context.expect(rig.eval("return IsInHell()") == "0", "chưa vào cảnh thì không phải địa ngục");
    for (const std::int32_t scene : {0x4d, 0x242, 0x337}) {
        script.facts.scene_id = scene;
        context.expect(rig.eval("return IsInHell()") == "1", "cảnh địa ngục " + std::to_string(scene));
    }
    script.facts.scene_id = 0x4e;
    context.expect(rig.eval("return IsInHell()") == "0", "cảnh liền kề không phải địa ngục");
    context.expect(pushed("ToggleContainer()") == "TOGLE_CONTAINER", "ngoài địa ngục thì đẩy");
    context.expect(pushed("DataPool:OpenFriendList()") == "TOGLE_FRIEND\t2", "đối số chuỗi hằng của gốc là \"2\"");
    context.expect(pushed("OpenEquip(7)") == "OPEN_EQUIP\t7", "đối số số được chuyển");
    context.expect(pushed("OpenEquip(1e20)") == "OPEN_EQUIP\t-2147483648", "ép (int) ngoài miền ra INT32_MIN");
    context.expect(pushed("OpenEquip('7')") == "không đẩy", "chuỗi số không phải số nghiêm: bỏ qua im lặng");
    context.expect(pushed("OpenEquip()") == "không đẩy", "thiếu đối số: bỏ qua im lặng");
    script.facts.scene_id = 0x242;
    context.expect(pushed("ToggleContainer()") == "không đẩy", "trong địa ngục thì không đẩy");
    context.expect(pushed("OpenEquip(7)") == "không đẩy", "trong địa ngục thì không đẩy, có đối số");
    // LuaFnOpenCangPin: gốc kiểm (và ném) đối số TRƯỚC khi kiểm khoá.
    script.facts.scene_id = 0x4e;
    context.expect(pushed("LuaFnOpenCangPin(3)") == "OPEN_CANGPIN\t3", "đối số hợp lệ");
    context.expect(pushed("LuaFnOpenCangPin('3')").contains("LUA:LuaFnOpenCangPin Param 1 Error"), "sai kiểu thì ném câu của hàm");
    script.facts.scene_id = 0x242;
    context.expect(pushed("LuaFnOpenCangPin(3)") == "không đẩy", "trong địa ngục không đẩy");
    context.expect(pushed("LuaFnOpenCangPin()").contains("LUA:LuaFnOpenCangPin Param 1 Error"), "trong địa ngục vẫn ném trước khi kiểm khoá");
    // PlayerPackage:OpenLockFrame: gốc kiểm khoá TRƯỚC, nên trong địa ngục sai kiểu cũng không ném.
    context.expect(pushed("PlayerPackage:OpenLockFrame()") == "không đẩy", "trong địa ngục: khoá trước, không ném");
    script.facts.scene_id.reset();
    context.expect(pushed("PlayerPackage:OpenLockFrame(5)") == "OPEN_ITEM_COFFER\t5", "bảng:hàm lấy đối số ở chỉ số 2");
    context.expect(pushed("PlayerPackage:OpenLockFrame()").contains("OpenLockFrame Wrong Param1"), "ngoài địa ngục sai kiểu thì ném");
}

constexpr std::array<Case, 6> kCases = {{
    {.name = "GetTickCount quấn như (int)", .body = tick_count_wraps_like_the_original_int_cast},
    {.name = "cờ nhắc cập nhật có biên", .body = update_tip_flags_are_bounds_checked},
    {.name = "việc nhờ game được ghi lại", .body = requests_to_the_game_are_recorded},
    {.name = "hằng và cờ theo gốc", .body = constants_and_flags_follow_the_original},
    {.name = "hàm đẩy sự kiện sinh tự động", .body = generated_event_pushes_carry_their_arguments},
    {.name = "khoá cảnh địa ngục và đối số số", .body = locked_pushes_follow_the_hell_scene_and_arguments},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
