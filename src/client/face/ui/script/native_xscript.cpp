#include "ui/script/native_groups.hpp"

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/xscript.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Mọi hàm ở đây là hàm toàn cục: đối số đầu ở chỉ số 1. Địa chỉ mã máy ở xscript.hpp.

// Get_XParam_INT(n) (Game.exe 0x140240ea0): số thứ n của bản ghi XParam của sự kiện đang chạy; không có bản ghi thì -1, chỉ số
// ngoài đếm thì 0.
NativeResult get_xparam_int(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 1);
    if (!index) return std::unexpected(NativeError::of("LUA: Lua_Get_XParam_INT Wrong Param"));
    const XParamRecord* const record = native::context_of(lua).xparam;
    lua_pushnumber(lua, record == nullptr ? -1.0 : static_cast<double>(record->int_at(native::to_int(*index))));
    return 1;
}

// Get_XParam_UINT(n) (0x140240f50): như trên nhưng số không dấu 32 bit.
NativeResult get_xparam_uint(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 1);
    if (!index) return std::unexpected(NativeError::of("LUA: Lua_Get_XParam_UINT Wrong Param"));
    const XParamRecord* const record = native::context_of(lua).xparam;
    lua_pushnumber(lua, record == nullptr ? -1.0 : static_cast<double>(static_cast<std::uint32_t>(record->int_at(native::to_int(*index)))));
    return 1;
}

// Get_XParam_STR(n) (0x140241000): chuỗi thứ n; không có bản ghi hay chỉ số ngoài đếm thì chuỗi rỗng.
NativeResult get_xparam_str(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 1);
    if (!index) return std::unexpected(NativeError::of("LUA: Lua_Get_XParam_STR Wrong Param"));
    const XParamRecord* const record = native::context_of(lua).xparam;
    const std::string_view text = record == nullptr ? std::string_view{} : record->string_at(native::to_int(*index));
    lua_pushlstring(lua, text.data(), text.size());
    return 1;
}

// Get_XParam_INT_Count() (0x1402410b0) và Get_XParam_STR_Count() (0x140241110): số phần tử; không có bản ghi thì 0.
NativeResult get_xparam_int_count(lua_State* lua) {
    const XParamRecord* const record = native::context_of(lua).xparam;
    lua_pushnumber(lua, record == nullptr ? 0.0 : static_cast<double>(record->int_count));
    return 1;
}

NativeResult get_xparam_str_count(lua_State* lua) {
    const XParamRecord* const record = native::context_of(lua).xparam;
    lua_pushnumber(lua, record == nullptr ? 0.0 : static_cast<double>(record->string_count));
    return 1;
}

// Set_XSCRIPT_ScriptID(id) (0x140241560).
// Khác gốc: câu lỗi của gốc kèm tên môi trường giao diện đang chạy (uiEnv); native không biết nó nên bỏ trường đó.
NativeResult set_xscript_script_id(lua_State* lua) {
    const std::optional<double> id = native::strict_number(lua, 1);
    if (!id) return std::unexpected(NativeError::format("LUA: Lua_Set_XSCRIPT_ScriptID[type={}] Wrong Param", native::type_at(lua, 1)));
    native::context_of(lua).xscript.set_script_id(native::to_int(*id));
    return 0;
}

// Set_XSCRIPT_Function_Name(tên) (0x140241400): chuỗi hay số; tối đa 63 byte, dừng ở NUL đầu tiên. Khác gốc: như trên, bỏ uiEnv.
NativeResult set_xscript_function_name(lua_State* lua) {
    const std::optional<std::string_view> name = native::text_arg(lua, 1);
    if (!name) {
        const Context& context = native::context_of(lua);
        return std::unexpected(NativeError::format("LUA: Lua_Set_XSCRIPT_Function_Name[type={},sid={}] Wrong Param", native::type_at(lua, 1),
            context.xscript.record().script_id));
    }
    native::context_of(lua).xscript.set_function(*name);
    return 0;
}

// Set_XSCRIPT_ParamCount(n) (0x140241630): chỉ 8 bit thấp được giữ.
NativeResult set_xscript_param_count(lua_State* lua) {
    const std::optional<double> count = native::strict_number(lua, 1);
    if (!count) return std::unexpected(NativeError::of("LUA: Lua_Set_XSCRIPT_ParamCount Wrong Param"));
    native::context_of(lua).xscript.set_param_count(native::to_int(*count));
    return 0;
}

// Set_XSCRIPT_Parameter(chỉ số, giá trị) (0x140241360): cả hai là số nghiêm; chỉ số ngoài 14 ô thì bỏ qua.
// Khác gốc: câu lỗi của gốc còn nguyên chuỗi định dạng "<%s>" không kèm đối số (nội dung trong `<>` không xác định); bỏ phần đó.
NativeResult set_xscript_parameter(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 1);
    const std::optional<double> value = native::strict_number(lua, 2);
    if (!index || !value) return std::unexpected(NativeError::of("LUA: Lua_Set_XSCRIPT_Parameter Wrong Param"));
    native::context_of(lua).xscript.set_param(static_cast<std::uint8_t>(native::to_int(*index) & 0xFF), native::to_int(*value));
    return 0;
}

// Clear_XSCRIPT() (0x140241170) và Send_XSCRIPT() (0x1402411a0).
NativeResult clear_xscript(lua_State* lua) {
    native::context_of(lua).xscript.clear();
    return 0;
}

NativeResult send_xscript(lua_State* lua) {
    native::context_of(lua).xscript.send();
    return 0;
}

constexpr std::array<native::Entry, 11> kGlobals = {{
    {.name = "Get_XParam_INT", .function = &lua::adapt<get_xparam_int>},
    {.name = "Get_XParam_UINT", .function = &lua::adapt<get_xparam_uint>},
    {.name = "Get_XParam_STR", .function = &lua::adapt<get_xparam_str>},
    {.name = "Get_XParam_INT_Count", .function = &lua::adapt<get_xparam_int_count>},
    {.name = "Get_XParam_STR_Count", .function = &lua::adapt<get_xparam_str_count>},
    {.name = "Set_XSCRIPT_ScriptID", .function = &lua::adapt<set_xscript_script_id>},
    {.name = "Set_XSCRIPT_Function_Name", .function = &lua::adapt<set_xscript_function_name>},
    {.name = "Set_XSCRIPT_ParamCount", .function = &lua::adapt<set_xscript_param_count>},
    {.name = "Set_XSCRIPT_Parameter", .function = &lua::adapt<set_xscript_parameter>},
    {.name = "Clear_XSCRIPT", .function = &lua::adapt<clear_xscript>},
    {.name = "Send_XSCRIPT", .function = &lua::adapt<send_xscript>},
}};

} // namespace

void register_xscript(lua_State* lua) { native::register_globals(lua, kGlobals); }

} // namespace game::ui::script
