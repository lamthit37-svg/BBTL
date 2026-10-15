// Bảng biến, điều game biết về thế giới và ScriptGlobal_Format của script giao diện (ui/script/variable, message_format,
// native_variable, native_world, native_format): luật thuần của bảng biến và bố cục byte của lời nhắn, rồi chạy đoạn Lua thật. Sai ở
// đây hỏng thầm (lời nhắn bị cắt hay lệch byte, sự kiện biến đổi không phát hay phát thừa, cửa sổ rẽ nhánh sai theo cảnh) nên có test.
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/scene_table.hpp"
#include "ui/script/context.hpp"
#include "ui/script/message_format.hpp"
#include "ui/script/variable.hpp"

#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using ui::script::VariableSystem;

void variable_system_follows_the_original_rules(Context& context) {
    VariableSystem variables;
    context.expect(!variables.get("a").has_value(), "chưa có biến thì không có giá trị");
    const std::optional<ui::script::VariableChange> created = variables.set("a", "1");
    context.expect(created.has_value() && created->name == "a" && created->value == "1", "biến mới có giá trị khác rỗng phát sự kiện");
    context.expect(variables.get("a") == "1", "đọc lại giá trị");
    context.expect(!variables.set("a", "1").has_value(), "ghi giá trị cũ không phát sự kiện");
    const std::optional<ui::script::VariableChange> changed = variables.set("a", "2");
    context.expect(changed.has_value() && changed->value == "2", "đổi giá trị phát sự kiện với giá trị mới");
    // Biến mới có giá trị cũ là chuỗi rỗng: ghi rỗng tạo biến mà không phát sự kiện, và biến đó đọc ra chuỗi rỗng chứ không phải không có.
    context.expect(!variables.set("empty", "").has_value(), "ghi rỗng lên biến mới không phát sự kiện");
    context.expect(variables.get("empty") == "", "biến rỗng khác biến chưa có");
    const std::optional<ui::script::VariableChange> cleared = variables.set("a", "");
    context.expect(cleared.has_value() && cleared->value.empty(), "đổi về rỗng vẫn là đổi");
    // View_DefaultCamera* và View_FOV* theo tiền tố: ghi được nhưng không phát sự kiện.
    context.expect(!variables.set("View_FOV", "90").has_value() && variables.get("View_FOV") == "90", "View_FOV im lặng");
    context.expect(!variables.set("View_FOV_Extra", "1").has_value(), "tiền tố View_FOV");
    context.expect(!variables.set("View_DefaultCamera2", "1").has_value(), "tiền tố View_DefaultCamera");
    context.expect(variables.set("View_Other", "1").has_value(), "View_ khác vẫn phát sự kiện");
}

void variable_system_bounds_its_input(Context& context) {
    VariableSystem variables;
    const std::string longest(ui::script::kVariableValueLimit - 1, 'x');
    context.expect(variables.set("long", longest).has_value() && variables.get("long") == std::string_view(longest), "giá trị dài nhất được nhận");
    const std::string too_long(ui::script::kVariableValueLimit, 'x');
    context.expect(!variables.set("longer", too_long).has_value() && !variables.get("longer").has_value(), "giá trị quá dài bị bỏ, không tạo biến");
    context.expect(!variables.set("", "1").has_value() && variables.size() == 1, "tên rỗng bị bỏ");
    const std::string name_limit(ui::script::kVariableNameLimit, 'n');
    context.expect(variables.set(name_limit, "1").has_value(), "tên dài nhất được nhận");
    context.expect(!variables.set(name_limit + "n", "1").has_value(), "tên quá dài bị bỏ");
    VariableSystem full;
    for (std::size_t index = 0; index < ui::script::kVariableCountLimit; ++index) static_cast<void>(full.set("v" + std::to_string(index), "1"));
    context.expect(full.size() == ui::script::kVariableCountLimit, "đầy bảng");
    context.expect(!full.set("extra", "1").has_value() && !full.get("extra").has_value(), "bảng đầy thì biến mới bị bỏ");
    context.expect(full.set("v0", "2").has_value(), "bảng đầy vẫn sửa được biến đã có");
}

void variable_natives_read_and_write(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    context.expect(rig.ok(), "mở được máy Lua");
    if (!rig.ok()) return;
    context.expect(rig.eval("return type(Variable:GetVariable('nope'))") == "nil", "biến chưa có là nil");
    context.expect(rig.eval("return type(Variable:GetVariable({}))") == "nil", "tên không phải chuỗi cũng là nil");
    context.expect(rig.eval("Variable:SetVariable('SkillPageNumber', 3, 1) return Variable:GetVariable('SkillPageNumber')") == "3",
        "số được đổi thành chuỗi");
    context.expect(script.calls.size() == 1 && script.calls.front().ask == ui::panel::Ask::kPushEvent &&
                       script.calls.front().text == "VARIABLE_CHANGED\tSkillPageNumber\t3",
        "đổi giá trị phát VARIABLE_CHANGED với tên và giá trị");
    context.expect(rig.eval("Variable:SetVariable('SkillPageNumber', '3', 1) return 'ok'") == "ok" && script.calls.size() == 1,
        "ghi lại giá trị cũ không phát sự kiện nữa");
    // Chuỗi C: byte NUL cắt cả tên lẫn giá trị.
    context.expect(rig.eval(R"(Variable:SetVariable("cut\0name", "ab\0cd", 1) return Variable:GetVariable("cut"))") == "ab",
        "NUL cắt tên và giá trị");
    const std::string no_value = rig.eval("Variable:SetVariable('x')");
    context.expect(no_value.contains("Lua_SetGlobalVariable[3] param parameter error"), "thiếu giá trị");
    const std::string bad_name = rig.eval("Variable:SetVariable({}, 'v', 1)");
    context.expect(bad_name.contains("Lua_SetGlobalVariable[2] param parameter error"), "tên sai kiểu");
    const std::string bad_flag = rig.eval("Variable:SetVariable('x', 'v', '1')");
    context.expect(bad_flag.contains("Lua_SetGlobalVariable[4] param parameter error"), "cờ phải là số nghiêm");
    context.expect(!script.variables.get("x").has_value(), "lời gọi sai không tạo biến");
}

void world_facts_drive_the_scene_functions(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Chưa vào cảnh.
    context.expect(rig.eval("local scene = GetSceneID() return type(scene)") == "nil", "GetSceneID không trả gì khi chưa vào cảnh");
    context.expect(rig.eval("return CSongliaoWarData:TSLGetLocalSceneID()") == "-1", "TSLGetLocalSceneID là -1");
    context.expect(rig.eval("return WuLinZhiDian:IsWuLinZhiDianScene()") == "-1", "không ở cảnh Võ Lâm Chi Điên");
    // Quanh khoảng [0x2f1, 0x2f4) = [753, 756).
    const std::array<std::pair<int, std::string_view>, 6> scenes = {{{752, "-1"}, {753, "1"}, {754, "1"}, {755, "1"}, {756, "-1"}, {2, "-1"}}};
    for (const auto& [id, wanted] : scenes) {
        script.facts.scene_id = id;
        context.expect(rig.eval("return WuLinZhiDian:IsWuLinZhiDianScene()") == wanted, "IsWuLinZhiDianScene");
        context.expect(rig.eval("return JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene()") == wanted, "IsJueZhanWuLinZhiDianScene");
    }
    script.facts.scene_id = 2;
    context.expect(rig.eval("return GetSceneID()") == "2", "GetSceneID");
    context.expect(rig.eval("return CSongliaoWarData:TSLGetLocalSceneID()") == "2", "TSLGetLocalSceneID");
    context.expect(rig.eval("return SystemSetup:IsClassic()") == "1", "IsClassic luôn 1");
    context.expect(rig.eval("return DataPool:GetCurDialogNpcId()") == "-1", "không hội thoại là -1");
    script.facts.dialog_npc_id = 4021;
    context.expect(rig.eval("return DataPool:GetCurDialogNpcId()") == "4021", "NPC đang hội thoại");
    script.facts.gm_visible_type = 2;
    script.facts.zbs2018_server = 1;
    context.expect(rig.eval("return DataPool:LuaFnGetGMVisibleType() .. '|' .. IsZbs2018SpeicalServer()") == "2|1", "cờ GM và máy chủ đặc biệt");
}

// Chuỗi đóng gói theo bố cục của message_format.hpp: dựng từ byte để thấy từng byte điều khiển.
std::string packed(std::string_view pattern, std::span<const std::string_view> args) {
    std::array<char, ui::script::kMessageBufferSize> buffer{};
    const std::optional<std::size_t> length = ui::script::pack_message(pattern, args, buffer);
    return length ? std::string(buffer.data(), *length) : std::string("<không đóng gói được>");
}

void message_layout_is_byte_exact(Context& context) {
    const std::array<std::string_view, 1> one = {"xy"};
    // "abc" bỏ ký tự cuối thành "ab", '*' ghi đè nó, số đối số 1, tổng 2 + 2 = 4 cộng 3 là 7, rồi '*', độ dài 2, "xy", '}'.
    context.expect(packed("abc", one) == std::string({'a', 'b', '*', 1, 7, '*', 2, 'x', 'y', '}'}), "một đối số");
    const std::array<std::string_view, 2> two = {"x", "yz"};
    context.expect(packed("m", two) == std::string({'*', 2, 10, '*', 1, 'x', '*', 2, 'y', 'z', '}'}), "hai đối số, mẫu một ký tự");
    // Đối số rỗng có byte độ dài 0: lua_pushstring cắt lời nhắn ở đó.
    const std::array<std::string_view, 1> empty = {""};
    context.expect(packed("abc", empty) == std::string({'a', 'b', '*', 1, 5, '*'}), "đối số rỗng cắt lời nhắn ở byte độ dài");
    // Tổng đúng 0x38 thì thêm một dấu cách đệm và byte tổng là 0x39 + 3.
    const std::string fifty_four(54, 'q');
    const std::array<std::string_view, 1> padded = {fifty_four};
    const std::string expected_padded = std::string({'a', '*', 1, 0x3c, '*', 54}) + fifty_four + " }";
    context.expect(packed("ab", padded) == expected_padded, "tổng 0x38 thêm dấu cách");
    // Đối số có NUL nhúng: chuỗi C cắt ở NUL.
    const std::array<std::string_view, 1> embedded = {std::string_view("ab\0cd", 5)};
    context.expect(packed("abc", embedded) == std::string({'a', 'b', '*', 1, 7, '*', 2, 'a', 'b', '}'}), "NUL nhúng cắt đối số");
    // Không đối số: byte đếm là 0 nên lua_pushstring cắt ngay sau '*' (ScriptGlobal_Format không đóng gói trường hợp này).
    const std::array<std::string_view, 0> none;
    context.expect(packed("a", none) == "*", "không đối số thì byte đếm 0 cắt lời nhắn");
}

void message_rejects_what_cannot_be_packed(Context& context) {
    std::array<char, ui::script::kMessageBufferSize> buffer{};
    const std::array<std::string_view, 1> one = {"x"};
    context.expect(!ui::script::pack_message("", one, buffer).has_value(), "mẫu rỗng");
    std::array<std::string_view, 16> sixteen;
    sixteen.fill("x");
    context.expect(!ui::script::pack_message("a", sixteen, buffer).has_value(), "16 đối số");
    const std::string huge(1000, 'h');
    const std::array<std::string_view, 1> big = {huge};
    context.expect(!ui::script::pack_message(huge, big, buffer).has_value(), "lời nhắn không vừa 1024 byte");
    // Biên: mẫu n byte cộng tiêu đề 2, một đối số rỗng 2, '}' và NUL cuối 2 vừa khít 1024 khi n = 1018.
    const std::array<std::string_view, 1> small = {""};
    context.expect(ui::script::pack_message(std::string(1018, 'f'), small, buffer).has_value(), "vừa khít bộ đệm");
    context.expect(!ui::script::pack_message(std::string(1019, 'f'), small, buffer).has_value(), "thừa một byte");
}

void script_global_format_packs_or_reports(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return ScriptGlobal_Format('abc', 'xy')") == std::string({'a', 'b', '*', 1, 7, '*', 2, 'x', 'y', '}'}),
        "trả chuỗi đóng gói");
    context.expect(rig.eval("return ScriptGlobal_Format('m', 5, 'yz')") == std::string({'*', 2, 10, '*', 1, '5', '*', 2, 'y', 'z', '}'}),
        "đối số số đổi thành chuỗi");
    context.expect(script.calls.empty(), "có đối số thì không phát lời nhắn");
    context.expect(rig.eval("local out = ScriptGlobal_Format('hello') return type(out)") == "nil", "không đối số thì không trả gì");
    context.expect(script.calls.size() == 1 && script.calls.front().text == "NEW_DEBUGMESSAGE\thello", "không đối số thì phát NEW_DEBUGMESSAGE");
    const std::string no_pattern = rig.eval("return ScriptGlobal_Format({})");
    context.expect(no_pattern.contains("LUA: Lua_ScriptGlobal_Format Wrong Param0!"), "mẫu sai kiểu");
    const std::string bad_arg = rig.eval("return ScriptGlobal_Format('p', 'a', {}, 'c')");
    context.expect(bad_arg.contains("LUA: Lua_ScriptGlobal_Format Wrong Param2! Param0=p"), "đối số thứ hai sai kiểu");
    const std::string many = rig.eval("return ScriptGlobal_Format('p', 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)");
    context.expect(many.contains("LUA: Lua_ScriptGlobal_Format too many Params! Param0=p"), "16 đối số");
    context.expect(rig.eval("return ScriptGlobal_Format('p', 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)").starts_with('*'), "15 đối số được");
    const std::string empty_pattern = rig.eval("return ScriptGlobal_Format('', 'x')");
    context.expect(empty_pattern.starts_with("LỖI: "), "mẫu rỗng kèm đối số là lỗi Lua, không chết");
}

// Một dòng của Config/SceneDefineEx.txt: 25 ô cách nhau bằng tab; chỉ đặt các ô mà bảng cảnh đọc (id, cỡ, token), ô còn lại là "0".
std::string scene_line(int id, std::string_view name, int width, int depth, std::string_view token) {
    std::array<std::string, 25> cells;
    cells.fill("0");
    cells.at(0) = std::to_string(id);
    cells.at(1) = name;
    cells.at(2) = std::to_string(width);
    cells.at(3) = std::to_string(depth);
    cells.at(10) = token;
    std::string line;
    for (const std::string& cell : cells) line += (line.empty() ? "" : "\t") + cell;
    return line;
}

void scene_functions_read_the_scene_table(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const std::string size_code = "local w, d = GetSceneSizeByID(2) return w .. '|' .. d";
    context.expect(rig.eval("return GetSceneMapByID(2)").empty(), "chưa nạp bảng cảnh thì token rỗng");
    context.expect(rig.eval(size_code) == "0|0", "chưa nạp bảng cảnh thì cỡ 0 và 0");
    const ui::panel::SceneTable table =
        ui::panel::SceneTable::from_text(scene_line(2, "dali", 512, 256, "dali_map") + "\n" + scene_line(753, "wulin", 300, 200, "wulin_map") + "\n");
    script.facts.scenes = &table;
    context.expect(rig.eval("return GetSceneMapByID(2)") == "dali_map", "token cảnh 2");
    context.expect(rig.eval("return GetSceneMapByID('753')") == "wulin_map", "chuỗi số cũng được nhận (lua_tonumber không nghiêm)");
    context.expect(rig.eval("return GetSceneMapByID(99)").empty(), "id lạ thì token rỗng");
    context.expect(rig.eval("return GetSceneMapByID({})").empty(), "đối số không phải số thành id 0, không có dòng");
    context.expect(rig.eval(size_code) == "512|256", "cỡ cảnh 2");
    context.expect(rig.eval("local w, d = GetSceneSizeByID(99) return w .. '|' .. d") == "0|0", "id lạ thì cỡ 0 và 0");
    const std::string current = "local w, d = GetSceneSize() return w .. '|' .. d";
    context.expect(rig.eval(current) == "0|0", "chưa vào cảnh thì cỡ 0 và 0");
    script.facts.scene_size = ui::script::Facts::SceneSize{.width = 512, .depth = 256};
    context.expect(rig.eval(current) == "512|256", "cỡ cảnh đang đứng");
}

void server_and_scene_flags_follow_the_original(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return IsInTServer()") == "0", "mặc định không phải máy chủ T");
    // IsTServer là atoi của biến: khác 0 thì 1, kể cả số có đuôi chữ; chữ thuần và "-0" là 0.
    const std::array<std::pair<std::string_view, std::string_view>, 5> variables = {{{"abc", "0"}, {"-0", "0"}, {" 7x", "1"}, {"-3", "1"}, {"0", "0"}}};
    for (const auto& [value, wanted] : variables) {
        static_cast<void>(script.variables.set("IsTServer", value));
        context.expect(rig.eval("return IsInTServer()") == wanted, "IsTServer = " + std::string(value));
    }
    static_cast<void>(script.variables.set("IsTServer", "0"));
    for (const std::int32_t scene : {0x28a, 0x2d8, 0x2d9}) {
        script.facts.scene_id = scene;
        context.expect(rig.eval("return IsInTServer()") == "1", "cảnh T " + std::to_string(scene));
    }
    script.facts.scene_id = 0x28b;
    context.expect(rig.eval("return IsInTServer()") == "0", "cảnh liền kề không phải");
    // IsInKVKServer: atoi của biến, kẹp biên int32 như strtol.
    context.expect(rig.eval("return KVKInterface:IsInKVKServer()") == "0", "chưa đặt IsKVKServer thì 0");
    const std::array<std::pair<std::string_view, std::string_view>, 6> kvk = {{
        {"12abc", "12"}, {"-5", "-5"}, {"+3", "3"}, {"  9", "9"}, {"99999999999", "2147483647"}, {"-99999999999", "-2147483648"}}};
    for (const auto& [value, wanted] : kvk) {
        static_cast<void>(script.variables.set("IsKVKServer", value));
        context.expect(rig.eval("return KVKInterface:IsInKVKServer()") == wanted, "IsKVKServer = " + std::string(value));
    }
    script.facts.tb_final_server = 4;
    context.expect(rig.eval("return IsTBFinalServer()") == "4", "IsTBFinalServer đọc Facts");
}

void tlcj_scene_needs_a_hero(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const hero::Hero who = hero::newcomer();
    script.facts.scene_id = 0x3e0;
    context.expect(rig.eval("return TLCJ:IsInTLCJScene()") == "0", "không có nhân vật thì 0 dù đúng cảnh");
    script.facts.hero = &who;
    context.expect(rig.eval("return TLCJ:IsInTLCJScene()") == "1", "cảnh 0x3e0");
    script.facts.scene_id = 0x3f7;
    context.expect(rig.eval("return TLCJ:IsInTLCJScene()") == "1", "cảnh 0x3f7");
    script.facts.scene_id = 0x3e1;
    context.expect(rig.eval("return TLCJ:IsInTLCJScene()") == "0", "cảnh khác");
    script.facts.scene_id.reset();
    context.expect(rig.eval("return TLCJ:IsInTLCJScene()") == "0", "chưa vào cảnh");
}

constexpr std::array<Case, 10> kCases = {{
    {.name = "bảng biến theo luật của gốc", .body = variable_system_follows_the_original_rules},
    {.name = "bảng biến có trần", .body = variable_system_bounds_its_input},
    {.name = "Variable:GetVariable và SetVariable", .body = variable_natives_read_and_write},
    {.name = "hàm cảnh và cờ đọc Facts", .body = world_facts_drive_the_scene_functions},
    {.name = "lời nhắn đóng gói đúng từng byte", .body = message_layout_is_byte_exact},
    {.name = "lời nhắn không đóng gói được", .body = message_rejects_what_cannot_be_packed},
    {.name = "ScriptGlobal_Format", .body = script_global_format_packs_or_reports},
    {.name = "hàm cảnh đọc bảng cảnh", .body = scene_functions_read_the_scene_table},
    {.name = "cờ máy chủ và cảnh đặc biệt", .body = server_and_scene_flags_follow_the_original},
    {.name = "IsInTLCJScene cần nhân vật", .body = tlcj_scene_needs_a_hero},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
