// XSCRIPT và XParam của script giao diện (ui/script/native_xscript, xscript): chạy đoạn Lua thật trên lua::State có open_natives, rồi
// đọc bản ghi bên C++ hay giá trị script nhận. Sai ở đây hỏng thầm (script máy chủ nhận tham số lệch, cửa sổ đọc nhầm tham số của sự kiện)
// và không thấy khi chạy, nên có test.
#include "support/script_rig.hpp"
#include "ui/script/context.hpp"
#include "ui/script/xscript.hpp"

#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::script::XParamRecord;
using ui::script::XScriptRecord;

void script_fills_and_sends_a_record(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    context.expect(rig.ok(), "mở được máy Lua");
    if (!rig.ok()) return;
    context.expect(rig.eval(R"(
        Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(889)
        Set_XSCRIPT_Function_Name("OnEnter")
        Set_XSCRIPT_Parameter(0, 7)
        Set_XSCRIPT_Parameter(1, -3)
        Set_XSCRIPT_Parameter(13, 99)
        Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
        return "xong")") == "xong", "chuỗi lệnh XSCRIPT chạy");
    const std::vector<XScriptRecord> sent = script.xscript.take_sent();
    context.expect(sent.size() == 1, "một bản ghi vào hàng đợi ra");
    if (sent.empty()) return;
    context.expect(sent.front().script_id == 889, "id");
    context.expect(sent.front().function() == "OnEnter", "tên hàm");
    context.expect(sent.front().param_count == 3, "đếm tham số");
    context.expect(sent.front().params[0] == 7 && sent.front().params[1] == -3 && sent.front().params[13] == 99, "tham số");
    context.expect(sent.front().params[2] == 0, "tham số chưa đặt là 0");
    // Send không xoá bản ghi đang soạn; Clear_XSCRIPT mới đưa về trống.
    context.expect(script.xscript.record() == sent.front(), "gửi rồi bản ghi đang soạn giữ nguyên");
    context.expect(rig.eval("Clear_XSCRIPT() return 'ok'") == "ok", "Clear_XSCRIPT");
    context.expect(script.xscript.record() == XScriptRecord{}, "Clear_XSCRIPT về id -1, tên rỗng, đếm và tham số 0");
    context.expect(script.xscript.record().script_id == -1, "id sau Clear_XSCRIPT là -1");
}

void names_and_indexes_follow_the_original_limits(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Tên dài hơn 63 byte bị cắt; byte NUL cắt tên ở đó (strncpy rồi strlen); số đổi thành chuỗi như lua_isstring.
    const std::string sixty_four(64, 'a');
    context.expect(rig.eval("Set_XSCRIPT_Function_Name('" + sixty_four + "') return 'ok'") == "ok", "đặt tên dài");
    context.expect(script.xscript.record().function() == std::string(63, 'a'), "tên cắt ở 63 byte");
    context.expect(rig.eval(R"(Set_XSCRIPT_Function_Name("ab\0cd") return 'ok')") == "ok", "đặt tên có byte NUL");
    context.expect(script.xscript.record().function() == "ab", "tên dừng ở byte NUL đầu tiên");
    context.expect(rig.eval("Set_XSCRIPT_Function_Name(12) return 'ok'") == "ok", "số làm tên");
    context.expect(script.xscript.record().function() == "12", "số thành chuỗi");
    // Chỉ số tham số lấy 8 bit thấp rồi so với 14: 256 trỏ về ô 0, 14 và 255 bị bỏ.
    context.expect(rig.eval("Set_XSCRIPT_Parameter(256, 5) Set_XSCRIPT_Parameter(14, 6) Set_XSCRIPT_Parameter(255, 7) return 'ok'") == "ok",
        "chỉ số ngoài miền không lỗi");
    const XScriptRecord& record = script.xscript.record();
    context.expect(record.params[0] == 5, "256 là ô 0");
    int touched = 0;
    for (const std::int32_t value : record.params) touched += value != 0 ? 1 : 0;
    context.expect(touched == 1, "chỉ ô 0 được ghi");
    // Đếm tham số giữ 8 bit thấp.
    context.expect(rig.eval("Set_XSCRIPT_ParamCount(257) return 'ok'") == "ok", "đặt đếm");
    context.expect(script.xscript.record().param_count == 1, "đếm giữ 8 bit thấp");
}

void outbox_is_bounded(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("Set_XSCRIPT_ScriptID(1) for i = 1, 2000 do Send_XSCRIPT() end return 'ok'") == "ok", "gửi 2000 lần");
    context.expect(script.xscript.pending() == ui::script::kXScriptOutboxLimit, "hàng đợi dừng ở trần");
    context.expect(script.xscript.dropped() == std::size_t{2000} - ui::script::kXScriptOutboxLimit, "phần quá trần được đếm");
    context.expect(script.xscript.take_sent().size() == ui::script::kXScriptOutboxLimit, "lấy ra hết");
    context.expect(script.xscript.pending() == 0, "lấy rồi hàng đợi trống");
}

void xparam_reads_the_current_record(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Không có bản ghi: số -1 (INT và UINT), chuỗi rỗng, đếm 0.
    context.expect(rig.eval("return Get_XParam_INT(0) .. '|' .. Get_XParam_UINT(0) .. '|' .. Get_XParam_STR(0) .. '|' .. Get_XParam_INT_Count() "
                            ".. '|' .. Get_XParam_STR_Count()") == "-1|-1||0|0",
        "không có bản ghi XParam");
    XParamRecord record;
    record.ints[0] = 7;
    record.ints[1] = -5;
    record.int_count = 2;
    record.strings[0] = "tên";
    record.strings[1] = "khác";
    record.string_count = 2;
    script.xparam = &record;
    context.expect(rig.eval("return Get_XParam_INT(0) .. '|' .. Get_XParam_INT(1)") == "7|-5", "số theo chỉ số");
    context.expect(rig.eval("return Get_XParam_UINT(1)") == "4294967291", "UINT đọc số âm thành không dấu 32 bit");
    context.expect(rig.eval("return Get_XParam_INT(2) .. '|' .. Get_XParam_INT(-1) .. '|' .. Get_XParam_INT(16)") == "0|0|0",
        "chỉ số ngoài đếm cho 0");
    context.expect(rig.eval("return Get_XParam_STR(0) .. '|' .. Get_XParam_STR(1) .. '|' .. Get_XParam_STR(2)") == "tên|khác|", "chuỗi theo chỉ số");
    context.expect(rig.eval("return Get_XParam_INT_Count() .. '|' .. Get_XParam_STR_Count()") == "2|2", "đếm");
    script.xparam = nullptr;
    context.expect(rig.eval("return Get_XParam_INT(0)") == "-1", "bỏ bản ghi thì về -1");
}

void wrong_arguments_throw_the_original_messages(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Số nghiêm: chuỗi số "1" không qua lua_type == LUA_TNUMBER.
    const std::string get_int = rig.eval("return Get_XParam_INT('1')");
    context.expect(get_int.starts_with("LỖI: ") && get_int.contains("LUA: Lua_Get_XParam_INT Wrong Param"), "Get_XParam_INT nhận chuỗi");
    const std::string get_str = rig.eval("return Get_XParam_STR()");
    context.expect(get_str.contains("LUA: Lua_Get_XParam_STR Wrong Param"), "Get_XParam_STR thiếu đối số");
    // Tên hàm là bảng (kiểu 5 của lua_type) và id hiện có của bản ghi đang soạn (-1) nằm trong câu lỗi.
    const std::string name = rig.eval("Set_XSCRIPT_Function_Name({})");
    context.expect(name.contains("Lua_Set_XSCRIPT_Function_Name[type=5,sid=-1] Wrong Param"), "Set_XSCRIPT_Function_Name nhận bảng");
    const std::string id = rig.eval("Set_XSCRIPT_ScriptID(nil)");
    context.expect(id.contains("Lua_Set_XSCRIPT_ScriptID[type=0] Wrong Param"), "Set_XSCRIPT_ScriptID nhận nil");
    const std::string parameter = rig.eval("Set_XSCRIPT_Parameter(1)");
    context.expect(parameter.contains("Lua_Set_XSCRIPT_Parameter Wrong Param"), "Set_XSCRIPT_Parameter thiếu giá trị");
    const std::string count = rig.eval("Set_XSCRIPT_ParamCount('2')");
    context.expect(count.contains("Lua_Set_XSCRIPT_ParamCount Wrong Param"), "Set_XSCRIPT_ParamCount nhận chuỗi");
    context.expect(script.xscript.record() == XScriptRecord{}, "lời gọi sai không đổi bản ghi");
}

constexpr std::array<Case, 5> kCases = {{
    {.name = "script điền rồi gửi bản ghi XSCRIPT", .body = script_fills_and_sends_a_record},
    {.name = "tên và chỉ số theo giới hạn của gốc", .body = names_and_indexes_follow_the_original_limits},
    {.name = "hàng đợi ra có trần", .body = outbox_is_bounded},
    {.name = "Get_XParam đọc bản ghi của sự kiện", .body = xparam_reads_the_current_record},
    {.name = "đối số sai ném câu lỗi của gốc", .body = wrong_arguments_throw_the_original_messages},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
