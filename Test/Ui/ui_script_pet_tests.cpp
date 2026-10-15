// Hàm thú cưng, thú con và mục tiêu của script (native_pet.cpp, native_target.cpp): kho trống theo hàm dựng CDataPool, ô thú cưng so không dấu,
// đối số sai, khoá cảnh địa ngục, ngưỡng cấp của trang thú con, ghi đè từ Facts::pool.
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <string>
#include <string_view>

namespace game::test {
namespace {

// Chữ của sự kiện đã đẩy: tên và đối số cách nhau tab (Context::push_event); rỗng khi không có sự kiện nào hay có hơn một.
std::string only_event(const ui::script::Context& script) {
    if (script.calls.size() != 1 || script.calls.front().ask != ui::panel::Ask::kPushEvent) return {};
    return script.calls.front().text;
}

void pets_are_empty_and_slots_are_unsigned(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return Pet:GetPet_Count() .. '|' .. Pet:GetPet_Count_PetBank() .. '|' .. Infant:GetInfantCount()") == "0|0|0",
        "kho trống: không thú cưng, không thú con");
    context.expect(rig.eval("return tostring(Pet:IsPresent(0)) .. tostring(Pet:IsPresent(9)) .. tostring(Pet:IsPresent(9.9))") == "falsefalsefalse",
        "ô 0..9 hợp lệ, trống");
    for (const char* bad : {"10", "-1", "4294967296", "'1'", ""}) {
        context.expect(rig.eval(std::string("return Pet:IsPresent(") + bad + ")").contains("LUA:Pet IsPresent parameter error"),
            std::string("ô ngoài 0..9 hay không phải số bị ném: ") + bad);
    }
    context.expect(rig.eval("local a, b = Pet:GetPetList_Appoint(3) return '[' .. a .. '][' .. b .. ']'") == "[][]", "hết ô thì hai chuỗi rỗng");
    context.expect(rig.eval("return Pet:GetPetList_Appoint('1')").contains("LUA:Pet GetPetList_Appoint parameter error"), "chỉ số chuỗi bị ném");
    context.expect(rig.eval("return tostring(TargetPet:IsPresent())") == "false", "id mục tiêu đầu là -1");
    context.expect(script.facts.pool.write(0x5b8fc8, 7), "ghi id thú cưng mục tiêu");
    context.expect(rig.eval("return tostring(TargetPet:IsPresent())") == "true", "id dương là có");
    static_cast<void>(script.facts.pool.write(0x5b8fc8, 0));
    context.expect(rig.eval("return tostring(TargetPet:IsPresent())") == "false", "0 không phải dương");
}

void show_pet_list_opens_and_closes(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("Pet:ShowPetList(1) return 'ok'") == "ok" && only_event(script) == "OPEN_PET_LIST", "n >= 1 mở");
    script.calls.clear();
    context.expect(rig.eval("Pet:ShowPetList(0) return 'ok'") == "ok" && only_event(script) == "CLOSE_PET_LIST", "n < 1 đóng");
    script.calls.clear();
    context.expect(rig.eval("Pet:ShowPetList(0.9) return 'ok'") == "ok" && only_event(script) == "CLOSE_PET_LIST", "0,9 cắt về 0 nên đóng");
    script.calls.clear();
    context.expect(rig.eval("Pet:ShowPetList('1')").contains("LUA:Pet ShowPetList parameter error") && script.calls.empty(), "chuỗi bị ném");
    script.facts.scene_id = 0x4d;
    context.expect(rig.eval("Pet:ShowPetList(1) Pet:ShowPetList('x') return 'ok'") == "ok" && script.calls.empty(),
        "cảnh địa ngục: không đẩy và không kiểm đối số");
}

void infant_functions_answer_for_no_infant(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("local a,b,c,d,e,f,g = Infant:GetInfantSkillInfo(0, 0) return a..'|'..b..'|'..c..'|'..d..'|['..e..']['..f..']['..g..']'") ==
            "-1|0|0|0|[][][]",
        "bảy giá trị trống");
    context.expect(rig.eval("local a,b,c,d,e,f,g = Infant:GetInfantSkillInfo(5, 9) return a..'|'..g") == "-1|", "id khác và ô lớn không ném khi không có thú con");
    context.expect(rig.eval("local all = {Infant:GetInfantSkillInfo(0, 0)} return table.getn(all)") == "7", "đúng bảy giá trị");
    context.expect(rig.eval("return Infant:GetInfantSkillInfo('0', 0)").contains("LUA:Infant GetInfantSkillInfo parameter error"), "id chuỗi bị ném");
    context.expect(rig.eval("return Infant:GetInfantSkillInfo(0)").contains("LUA:Infant GetInfantSkillInfo parameter error"), "thiếu ô bị ném");
    context.expect(rig.eval("return Infant:GetInfantMaxCount()") == "1", "tối đa một thú con");
    for (const std::string_view name : {"GetInfantSex", "GetInfantLevel", "GetStage", "GetInfantName"}) {
        context.expect(rig.eval("return Infant:" + std::string(name) + "(0)").contains("LUA:Infant " + std::string(name) + " parameter error"),
            std::string(name) + " ném khi không có thú con");
    }
}

void toggle_infant_page_gates_on_level(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    hero::Hero who = hero::newcomer();
    script.facts.hero = &who;
    who.level = 49;
    context.expect(rig.eval("return Infant:ToggleInfantPage()") == "0" && only_event(script) == "NEW_DEBUGMESSAGE\t#{ZNJCS_130825_8}", "cấp 49 chưa đủ");
    script.calls.clear();
    who.level = 50;
    context.expect(rig.eval("return Infant:ToggleInfantPage()") == "0" && only_event(script) == "NEW_DEBUGMESSAGE\t#{ZNJCS_130825_9}",
        "cấp 50 đủ nhưng chưa có thú con");
    script.calls.clear();
    script.facts.hero = nullptr;
    context.expect(rig.eval("return Infant:ToggleInfantPage()") == "0" && only_event(script) == "NEW_DEBUGMESSAGE\t#{ZNJCS_130825_8}", "chưa có nhân vật coi như cấp 0");
    script.calls.clear();
    script.facts.scene_id = 0x242;
    script.facts.hero = &who;
    context.expect(rig.eval("return Infant:ToggleInfantPage()") == "0" && script.calls.empty(), "cảnh địa ngục: im lặng, trả 0");
}

void target_without_a_selection(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return Target:GetMenPai() .. '|' .. CachedTarget:GetMenPai()") == "0|0", "không có mục tiêu thì môn phái 0");
    context.expect(rig.eval("return Lua_CheckMainTargetHaveMaskBuff()") == "0", "không có mục tiêu thì không có buff");
    context.expect(rig.eval("return tostring(Target:IsPresent()) .. tostring(CachedTarget:IsPresent())") == "falsefalse", "dạng không đối số: chưa chọn ai");
    context.expect(rig.eval("return tostring(Target:IsPresent(1)) .. tostring(CachedTarget:IsPresent(0))") == "truetrue",
        "dạng có số đọc cờ DataPool + 0x13ae0, hàm dựng đặt -1 nên khác 0");
    context.expect(script.facts.pool.write(0x13ae0, 0), "ghi cờ về 0");
    context.expect(rig.eval("return tostring(Target:IsPresent(1))") == "false", "cờ 0 thì không có");
    context.expect(rig.eval("return tostring(Target:IsPresent('1'))") == "false", "chuỗi không phải số nghiêm nên rơi về dạng không đối số");
}

constexpr std::array<Case, 5> kCases = {{
    {.name = "kho trống và ô thú cưng không dấu", .body = pets_are_empty_and_slots_are_unsigned},
    {.name = "ShowPetList mở/đóng và khoá cảnh", .body = show_pet_list_opens_and_closes},
    {.name = "thú con khi chưa có thú con", .body = infant_functions_answer_for_no_infant},
    {.name = "trang thú con theo cấp", .body = toggle_infant_page_gates_on_level},
    {.name = "mục tiêu khi chưa chọn", .body = target_without_a_selection},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
