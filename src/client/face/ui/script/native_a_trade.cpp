// Hàm game của ngân hàng, cửa hàng, giao dịch và quầy hàng mà cửa sổ làn A gọi khi đóng (Bank:Close, CloseBooth, RestoreShopFitting,
// Exchange:ExchangeCancel, StallSale:CloseStallMessage, DataPool:AskMyBagList) của Game.exe 2026 (bản 9001).
// Gốc gửi gói lên máy chủ (CGShopClose, CGExchangeCancel, CGAskMyBagList) và hỏi CUISystem cửa sổ nào đang hiện. Client này chưa có
// đường gửi gói từ script và Context chưa biết cửa sổ nào hiện, nên phần đó bỏ (ghi Khác gốc ở từng hàm; gói cần máy chủ ghi ở
// docs/giao-viec/UI-FULL/A-CAN-MAY-CHU.md). Phần sự kiện giữ đúng thứ tự gốc.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <expected>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Bank:Close() (0x1402a5170): MessageBox_Self đang hiện và int ở DataPool + 0x5b8cb8 bằng 3 thì đóng hộp đó; rồi đẩy CLOSE_INPUT_MONEY (0x9f).
// Khác gốc: Context chưa biết MessageBox_Self có hiện không nên coi như không hiện, không đóng.
NativeResult bank_close(lua_State* lua) {
    native::context_of(lua).push_event("CLOSE_INPUT_MONEY", {});
    return 0;
}

// CloseBooth() (0x14023acf0): gọi CGameInterface ô 0x1a0 (0x140229020): gửi CGShopClose, gọi CDataPool ô 0x628, và nếu nút đang kéo
// thuộc cửa hàng thì bỏ kéo. Trả 0 giá trị.
// Khác gốc: chưa gửi gói, chưa có kho cửa hàng NPC nên không còn gì để dọn.
NativeResult close_booth(lua_State* /*lua*/) {
    return 0;
}

// RestoreShopFitting(n) (0x14023bf40): n không phải số thì ném "LUA: EnumAction Wrong Param" (gốc dùng nhầm nhãn của EnumAction). Có nhân vật
// thì trả từng phần thử đồ (n = 0..9, 10 là tất cả) về đồ đang mặc, cuối cùng nếu Shop_Fitting2 hiện thì đẩy sự kiện 0x480 "onlyrefresh".
// Khác gốc: client chưa có trạng thái thử đồ (cờ +0x7a4..+0x7c4 của nhân vật đều 0), nên sau khi kiểm đối số không còn việc; chưa biết cửa
// sổ Shop_Fitting2 có hiện không nên không đẩy 0x480.
NativeResult restore_shop_fitting(lua_State* lua) {
    if (lua_type(lua, 1) != LUA_TNUMBER) return std::unexpected(NativeError::of("LUA: EnumAction Wrong Param"));
    return 0;
}

// Exchange:ExchangeCancel() (0x140333680): cửa sổ Exchange đang hiện thì đẩy CLOSE_INPUT_MONEY (0x9f), CLOSE_PET_LIST (0xec),
// EXCHANGE_BOX_CLOSED (0x1f6) rồi gửi CGExchangeCancel. Trả 0 giá trị.
// Khác gốc: Context chưa biết Exchange có hiện không; chưa có giao dịch nào mở nên coi như không hiện, không đẩy và không gửi gói.
NativeResult exchange_cancel(lua_State* /*lua*/) {
    return 0;
}

// StallSale:CloseStallMessage() (0x1403bd6f0): đẩy CLOSE_STALL_MESSAGE (0xb9), CLOSE_INPUT_MONEY (0x9f), CLOSE_PET_LIST (0xec).
NativeResult stall_close_message(lua_State* lua) {
    Context& context = native::context_of(lua);
    context.push_event("CLOSE_STALL_MESSAGE", {});
    context.push_event("CLOSE_INPUT_MONEY", {});
    context.push_event("CLOSE_PET_LIST", {});
    return 0;
}

// DataPool:AskMyBagList() (0x1402e92d0): trong 30000 ms (< 0x7531) kể từ lần gửi trước thì trả 0; ngoài đó gửi CGAskMyBagList và trả 1.
// Khác gốc: chưa có đường gửi gói nên luôn đi nhánh bị chặn, trả 0 (script hiểu là chưa xin danh sách túi).
NativeResult datapool_ask_my_bag_list(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

constexpr std::array<native::Entry, 2> kGlobals = {{
    {.name = "CloseBooth", .function = &lua::adapt<close_booth>},
    {.name = "RestoreShopFitting", .function = &lua::adapt<restore_shop_fitting>},
}};
constexpr std::array<native::Entry, 1> kBank = {{{.name = "Close", .function = &lua::adapt<bank_close>}}};
constexpr std::array<native::Entry, 1> kExchange = {{{.name = "ExchangeCancel", .function = &lua::adapt<exchange_cancel>}}};
constexpr std::array<native::Entry, 1> kStallSale = {{{.name = "CloseStallMessage", .function = &lua::adapt<stall_close_message>}}};
constexpr std::array<native::Entry, 1> kDataPool = {{{.name = "AskMyBagList", .function = &lua::adapt<datapool_ask_my_bag_list>}}};

} // namespace

void register_a_trade(lua_State* lua) {
    native::register_globals(lua, kGlobals);
    native::register_table(lua, "Bank", kBank);
    native::register_table(lua, "Exchange", kExchange);
    native::register_table(lua, "StallSale", kStallSale);
    native::register_table(lua, "DataPool", kDataPool);
}

} // namespace game::ui::script
