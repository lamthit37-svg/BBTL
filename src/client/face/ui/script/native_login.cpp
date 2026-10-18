/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/native_login.cpp
 *  PHÂN HỆ   : Ui / Script / Native Login
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hàm game của chuỗi đăng nhập mà SelectRole.lua và SelectServerQuest.lua
 *    gọi: bảng GameProduceLogin (danh sách nhân vật, chọn ô, vào game, quay
 *    người mẫu, hộp thông báo), hai hàm của DataPool (GetCharSaletimeCyg,
 *    AskCreateChar) và Player:ReportLoginTypeMsg.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Hàm chỉ đọc Context::login (login_port.hpp, thủ tục đăng nhập ghi mỗi khung); việc cần thủ tục
// làm (vào game, xoá, đổi bước) đi qua Context::push_call, hộp thông báo đi qua sự kiện
// GAMELOGIN_*. Mỗi hàm ghi địa chỉ Game.exe 2026 (3.71.9001) của bản gốc. Khác gốc: chuỗi tiếng
// Trung mà gốc tra bảng rồi mới đẩy thì ở đây đẩy dạng "#{khoá}" để cửa sổ tự tra (cùng chữ hiện
// ra).

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/context.hpp"
#include "ui/script/login_port.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Hai lần SendEnterGameMsg cách nhau dưới chừng này thì lần sau bị bỏ (0x14063a7f0).
constexpr std::uint32_t kEnterGapMs = 2000;

// Dòng trả về của GetRoleInfo khi ô không có nhân vật: "", 0, 0, 0, "", 0, 0.
const LoginRole kNoRole{};

[[nodiscard]] bool has_slot(const LoginPort& port, std::int32_t slot) noexcept {
    const auto most = static_cast<std::int32_t>(port.roles.size());
    return slot >= 0 && slot < port.count && slot < most;
}

// Nhân vật ở ô, hoặc dòng rỗng khi ô ngoài số nhân vật.
[[nodiscard]] const LoginRole& role_at(const LoginPort& port, std::int32_t slot) noexcept {
    if (!has_slot(port, slot)) return kNoRole;
    return port.roles.at(static_cast<std::size_t>(slot));
}

// GetRoleCount() (0x1403416a0): số nhân vật của bảng chọn.
NativeResult get_role_count(lua_State* lua) {
    const LoginPort& port = native::context_of(lua).login;
    lua_pushnumber(lua, static_cast<double>(port.count));
    return 1;
}

// GetRoleInfo(ô) (0x1403416e0): tên, môn phái, cấp, ngày chờ xoá, ảnh, trạng thái bán, cấp PK.
// Ô ngoài số nhân vật trả dòng rỗng.
NativeResult get_role_info(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    if (!index) return std::unexpected(NativeError::of("LUA:GetRoleInfo param parameter error"));
    const LoginPort& port = native::context_of(lua).login;
    const std::int32_t slot = native::to_int(*index);
    const LoginRole& role = role_at(port, slot);
    lua_pushlstring(lua, role.name.data(), role.name.size());
    lua_pushnumber(lua, static_cast<double>(role.sect));
    lua_pushnumber(lua, static_cast<double>(role.level));
    lua_pushnumber(lua, static_cast<double>(role.delete_days));
    lua_pushlstring(lua, role.icon.data(), role.icon.size());
    lua_pushnumber(lua, static_cast<double>(role.sale_state));
    lua_pushnumber(lua, static_cast<double>(role.pk_level));
    return 7;
}

// GetCurSelectRole() (0x140341640): ô đang chọn.
NativeResult get_cur_select_role(lua_State* lua) {
    const LoginPort& port = native::context_of(lua).login;
    lua_pushnumber(lua, static_cast<double>(port.selected));
    return 1;
}

// SetCurSelect(ô) (0x140342a20): ô mà DelSelRole và CancelDelRole nhắm tới. Gốc không kiểm kiểu
// đối số (lua_tonumber trả 0 cho giá trị không phải số).
NativeResult set_cur_select(lua_State* lua) {
    const double value = lua_tonumber(lua, 2);
    native::context_of(lua).login.delete_slot = native::to_int(value);
    return 0;
}

// GetSelectedServerIsPKServer() (0x140340000): 1 khi máy chủ đã chọn là máy chủ PK, 0 khi không.
NativeResult get_selected_server_is_pk(lua_State* lua) {
    const LoginPort& port = native::context_of(lua).login;
    lua_pushnumber(lua, port.is_pk_server ? 1.0 : 0.0);
    return 1;
}

// Nhờ thủ tục vào game với nhân vật ở ô. Ô ngoài số nhân vật thì thôi.
void ask_enter(Context& context, panel::Ask ask, std::int32_t slot) noexcept {
    if (!has_slot(context.login, slot)) return;
    context.push_call(ask, std::to_string(slot));
}

// SendEnterGameMsg(ô) (0x140341da0, thân thật 0x14063a7f0): bỏ lần gọi cách lần trước dưới 2000
// ms; không thì ghi giờ rồi vào game với ô đó. Giờ ghi cả khi ô sai, như gốc.
NativeResult send_enter_game(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    if (!index) {
        return std::unexpected(NativeError::of("LUA:SendEnterGameMsg param parameter error"));
    }
    Context& context = native::context_of(lua);
    const auto now = static_cast<std::uint32_t>(context.facts.clock.count());
    const std::optional<std::uint32_t> last = context.login.last_enter_tick;
    const bool is_soon = last && now - *last < kEnterGapMs;
    if (is_soon) return 0;
    context.login.last_enter_tick = now;
    ask_enter(context, panel::Ask::kEnterGame, native::to_int(*index));
    return 0;
}

// SendEnterGameMsg_New(ô) (0x140341e00, thân thật 0x14063ae50): như trên nhưng không bỏ lần gọi
// nào; chỉ ghi giờ. SelectRole.lua gọi nó khi quay về bảng chọn từ bảng tạo.
NativeResult send_enter_game_new(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    if (!index) {
        return std::unexpected(NativeError::of("LUA:SendEnterGameMsg_New param parameter error"));
    }
    Context& context = native::context_of(lua);
    context.login.last_enter_tick = static_cast<std::uint32_t>(context.facts.clock.count());
    ask_enter(context, panel::Ask::kEnterGameNew, native::to_int(*index));
    return 0;
}

// MoveToCharacter(ô) (0x1403442c0, thân thật 0x14063c480): máy quay lướt sang nhân vật ở ô và
// bắn GAMELOGIN_SELECTCHARACTER(ô). Đối số không phải số thì gốc bỏ qua.
NativeResult move_to_character(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    if (!index) return 0;
    Context& context = native::context_of(lua);
    const std::int32_t slot = native::to_int(*index);
    if (!has_slot(context.login, slot)) return 0;
    context.push_call(panel::Ask::kMoveToCharacter, std::to_string(slot));
    return 0;
}

// Nhờ thủ tục đặt tốc độ quay hay hướng phóng của người mẫu. Gốc chỉ nhận số.
void ask_pose(lua_State* lua, panel::Ask ask) noexcept {
    const std::optional<double> value = native::strict_number(lua, 2);
    if (!value) return;
    native::context_of(lua).push_call(ask, std::format("{}", *value));
}

// ModelRotBegin(vòng/giây) (0x1403441a0) và ModelRotEnd(vòng/giây) (0x140344230): đặt tốc độ quay
// người mẫu của bước đang mở. Cả hai chỉ đặt tốc độ (Begin truyền số, End thường truyền 0).
NativeResult model_rot_begin(lua_State* lua) {
    ask_pose(lua, panel::Ask::kModelRotBegin);
    return 0;
}

NativeResult model_rot_end(lua_State* lua) {
    ask_pose(lua, panel::Ask::kModelRotEnd);
    return 0;
}

// ModelZoom(hướng) (0x140344320): -1 lùi, 1 tiến, 0 thôi.
NativeResult model_zoom(lua_State* lua) {
    ask_pose(lua, panel::Ask::kModelZoom);
    return 0;
}

// Câu hỏi của ExitToAccountInput_YesNo, dạng khoá của ui_strings.tsv.
constexpr auto kExitAsk = "#{GMGameInterface_Script_GameLogin_Info_Exit_To_Account_Input_YesNo}";

// Loại hộp thông báo của ShowMessageBox và sự kiện nó bắn (id sự kiện ở SU-KIEN-GAME.tsv).
struct BoxKind {
    std::string_view type;
    std::string_view event;
};

constexpr std::array<BoxKind, 5> kBoxKinds = {{
    {.type = "NoButton", .event = "GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON"},
    {.type = "OK", .event = "GAMELOGIN_SYSTEM_INFO_OK"},
    {.type = "YesNo", .event = "GAMELOGIN_SYSTEM_INFO_YESNO"},
    {.type = "Cancel", .event = "GAMELOGIN_SYSTEM_INFO_CANCEL"},
    {.type = "Close", .event = "GAMELOGIN_SYSTEM_INFO_CLOSE"},
}};

// ShowMessageBox(chữ, loại, mã) (0x140342a90): bắn sự kiện của loại với đối số chữ và mã. Thiếu
// một trong ba chuỗi thì không làm gì; loại lạ là assert của gốc (GMGameinterface_Script_
// GameProduceLogin.cpp dòng 0x420). Khác gốc: chữ có ký tự tab tách thành đối số thừa (Call ngăn
// đối số bằng tab), như PushEvent ở host.cpp.
NativeResult show_message_box(lua_State* lua) {
    const std::optional<std::string_view> text = native::text_arg(lua, 2);
    const std::optional<std::string_view> type = native::text_arg(lua, 3);
    const std::optional<std::string_view> tag = native::text_arg(lua, 4);
    const bool is_complete = text && type && tag;
    if (!is_complete) return 0;
    const std::string_view kind_name = native::c_string(*type);
    const auto kind = std::ranges::find(kBoxKinds, kind_name, &BoxKind::type);
    if (kind == kBoxKinds.end()) {
        return std::unexpected(NativeError::of("GameProduceLogin:ShowMessageBox: loại hộp lạ"));
    }
    const std::array<std::string_view, 2> args = {native::c_string(*text), native::c_string(*tag)};
    native::context_of(lua).push_event(kind->event, args);
    return 0;
}

// ExitToAccountInput_YesNo() (0x140342440): hỏi có về bảng tài khoản không (mã hộp "2").
NativeResult exit_to_account_yes_no(lua_State* lua) {
    const std::array<std::string_view, 2> args = {kExitAsk, "2"};
    native::context_of(lua).push_event("GAMELOGIN_SYSTEM_INFO_YESNO", args);
    return 0;
}

// ChangeToAccountInputDlgFromSelectRole() (0x140341480, thân thật 0x14063a000): về bảng tài khoản.
NativeResult change_to_account(lua_State* lua) {
    native::context_of(lua).push_call(panel::Ask::kBackToAccount, {});
    return 0;
}

// ChangeToCreateRoleDlgFromSelectRole() (0x1403414a0) và DataPool:AskCreateChar() (0x1402ea3d0):
// sang bảng tạo nhân vật; đủ ba nhân vật thì hộp "Role_Is_Full". Gốc AskCreateChar hỏi máy chủ
// (CLCheckAllowCreateChar) rồi mới mở; thủ tục đăng nhập của ta quyết theo số nhân vật đang có.
NativeResult open_create_role(lua_State* lua) {
    native::context_of(lua).push_call(panel::Ask::kOpenCreateRole, {});
    return 0;
}

// Ô mà DelSelRole và CancelDelRole nhắm tới có hợp lệ không (0x14063a500, 0x14063a750: ô nhỏ hơn
// số nhân vật và nhỏ hơn 3, so không dấu).
[[nodiscard]] bool has_delete_slot(const LoginPort& port) noexcept {
    return has_slot(port, port.delete_slot);
}

// DelSelRole() (0x140342a50, thân thật 0x14063a500): xin xoá nhân vật ở ô SetCurSelect đã đặt và
// hiện hộp không nút "đang xoá".
NativeResult delete_selected_role(lua_State* lua) {
    Context& context = native::context_of(lua);
    if (!has_delete_slot(context.login)) return 0;
    context.push_call(panel::Ask::kDeleteRole, std::to_string(context.login.delete_slot));
    const std::array<std::string_view, 1> args = {"#{produce_char_sel_Info_Deling_Role}"};
    context.push_event("GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON", args);
    return 0;
}

// CancelDelRole() (0x140342a70, thân thật 0x14063a750): xin huỷ lệnh xoá nhân vật ở ô đó. Máy chủ
// của ta không giữ lệnh xoá chờ (delete_days luôn 0) nên script không bao giờ tới đây.
NativeResult cancel_delete_role(lua_State* lua) {
    Context& context = native::context_of(lua);
    if (!has_delete_slot(context.login)) return 0;
    context.push_call(panel::Ask::kCancelDeleteRole, std::to_string(context.login.delete_slot));
    return 0;
}

// DataPool:GetCharSaletimeCyg(ô) (0x1402dfb10): trạng thái bán nhân vật của ô, 0 khi không bán.
// Chưa đối chiếu nguồn của giá trị đẩy (decompile mất số thực); ta không có trạng thái bán nên
// luôn 0, cùng giá trị mà GetRoleInfo đẩy ở vị trí thứ sáu.
NativeResult get_char_sale_time(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    const LoginPort& port = native::context_of(lua).login;
    const std::int32_t slot = index ? native::to_int(*index) : -1;
    const LoginRole& role = role_at(port, slot);
    lua_pushnumber(lua, static_cast<double>(role.sale_state));
    return 1;
}

// Player:ReportLoginTypeMsg(kiểu, hậu tố) (0x140397630): gốc báo kiểu đăng nhập bằng một yêu cầu
// HTTP tới http://localhost, nơi không có máy chủ nào nghe, nên trả 0. Ở đây chỉ kiểm hai đối số
// chuỗi (câu lỗi của gốc) và trả 0; không gửi gì.
NativeResult report_login_type(lua_State* lua) {
    const std::optional<std::string_view> kind = native::text_arg(lua, 2);
    if (!kind) {
        return std::unexpected(NativeError::of("PlayerMySelf:ReportLoginTypeMsg arg[2] error"));
    }
    const std::optional<std::string_view> postfix = native::text_arg(lua, 3);
    if (!postfix) {
        return std::unexpected(NativeError::of("PlayerMySelf:ReportLoginTypeMsg arg[3] error"));
    }
    lua_pushnumber(lua, 0.0);
    return 1;
}

// Lua_IsPrintMemMode() (0x140280190): trả cờ gỡ lỗi in bộ nhớ (byte ở 0x1410400b9), 1 hay 0.
// SelectRole.lua và SelectServer.lua hỏi nó mỗi lần hiện cửa sổ. Khác gốc: client không có cờ dòng
// lệnh đó nên luôn 0, và Lua_PrintMem (0x1402801e0) không bao giờ được gọi.
NativeResult is_print_mem_mode(lua_State* lua) {
    lua_pushnumber(lua, 0.0);
    return 1;
}

constexpr std::array<native::Entry, 17> kGameProduceLogin = {{
    {.name = "GetRoleCount", .function = &lua::adapt<get_role_count>},
    {.name = "GetRoleInfo", .function = &lua::adapt<get_role_info>},
    {.name = "GetCurSelectRole", .function = &lua::adapt<get_cur_select_role>},
    {.name = "SetCurSelect", .function = &lua::adapt<set_cur_select>},
    {.name = "GetSelectedServerIsPKServer", .function = &lua::adapt<get_selected_server_is_pk>},
    {.name = "SendEnterGameMsg", .function = &lua::adapt<send_enter_game>},
    {.name = "SendEnterGameMsg_New", .function = &lua::adapt<send_enter_game_new>},
    {.name = "MoveToCharacter", .function = &lua::adapt<move_to_character>},
    {.name = "ModelRotBegin", .function = &lua::adapt<model_rot_begin>},
    {.name = "ModelRotEnd", .function = &lua::adapt<model_rot_end>},
    {.name = "ModelZoom", .function = &lua::adapt<model_zoom>},
    {.name = "ShowMessageBox", .function = &lua::adapt<show_message_box>},
    {.name = "ExitToAccountInput_YesNo", .function = &lua::adapt<exit_to_account_yes_no>},
    {.name = "ChangeToAccountInputDlgFromSelectRole", .function = &lua::adapt<change_to_account>},
    {.name = "ChangeToCreateRoleDlgFromSelectRole", .function = &lua::adapt<open_create_role>},
    {.name = "DelSelRole", .function = &lua::adapt<delete_selected_role>},
    {.name = "CancelDelRole", .function = &lua::adapt<cancel_delete_role>},
}};

constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "GetCharSaletimeCyg", .function = &lua::adapt<get_char_sale_time>},
    {.name = "AskCreateChar", .function = &lua::adapt<open_create_role>},
}};

constexpr std::array<native::Entry, 1> kPlayer = {{
    {.name = "ReportLoginTypeMsg", .function = &lua::adapt<report_login_type>},
}};

constexpr std::array<native::Entry, 1> kGlobals = {{
    {.name = "Lua_IsPrintMemMode", .function = &lua::adapt<is_print_mem_mode>},
}};

} // namespace

void register_login(lua_State* lua) {
    native::register_globals(lua, kGlobals);
    native::register_table(lua, "GameProduceLogin", kGameProduceLogin);
    native::register_table(lua, "DataPool", kDataPool);
    native::register_table(lua, "Player", kPlayer);
}

} // namespace game::ui::script
