/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/native_a_vcall.cpp
 *  PHÂN HỆ   : Ui / Script / Native A Vcall
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Sinh bằng TOOLS/port/luagen/gen_a_vcall_natives.py từ decompile và mã máy
 *    của Game.exe 2026 (bản 9001); không sửa tay (sửa bộ sinh rồi sinh lại).
 *  - Hàm game mà thân chỉ đẩy kết quả một hàm ảo: getter của CDataPool (đọc
 *    Facts::pool) và phương thức của ActionItem rỗng mà EnumAction trả.
 *  - Khác gốc: client chưa có CActionSystem nên EnumAction luôn trả ActionItem
 *    rỗng (s_InvalidAction), như gốc khi vị trí không có action.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/pool_image.hpp"

#include <array>
#include <cstddef>
#include <expected>
#include <span>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

struct Getter {
    const char* table = nullptr; // nullptr là hàm toàn cục
    const char* name = nullptr;
    PoolField field;
};

// Getter ảo của CDataPool: hàm lá ở ô vtable đọc đúng một trường (độ rộng và dấu là của giá trị Lua thấy).
constexpr std::array<Getter, 35> kGetters = {{
    {.table = nullptr, .name = "GetMultiUpperLimit", .field = {.offset = 0x13ea0, .width = Width::kI32}}, // 0x140239d20, ô 0x820 của vtable CDataPool -> 0x14015b9a0
    {.table = nullptr, .name = "GetOperationType", .field = {.offset = 0x13de0, .width = Width::kI32}}, // 0x14023b430, ô 0x648 của vtable CDataPool -> 0x14015ba80
    {.table = nullptr, .name = "GetShowShopCredit", .field = {.offset = 0x13db4, .width = Width::kI32}}, // 0x14023ac70, ô 0x600 của vtable CDataPool -> 0x14015bb20
    {.table = "Bank", .name = "GetNpcId", .field = {.offset = 0x13f50, .width = Width::kI32}}, // 0x1402a53a0, ô 0x8d8 của vtable CDataPool -> 0x1401606a0
    {.table = "Bank", .name = "GetWorldItemStoreNpcId", .field = {.offset = 0x14070, .width = Width::kI32}}, // 0x1402a70a0, ô 0xad8 của vtable CDataPool -> 0x140160820
    {.table = "Bank", .name = "GetWorldItemStoreOpenIdx", .field = {.offset = 0x14064, .width = Width::kI32}}, // 0x1402a7020, ô 0xb00 của vtable CDataPool -> 0x140160850
    {.table = "BieYeFurniture", .name = "GetBankFurTypeNum", .field = {.offset = 0x62e378, .width = Width::kI32}}, // 0x1402b0d20, ô 0x1c58 của vtable CDataPool -> 0x14015b8b0
    {.table = "CityBank", .name = "GetNpcId", .field = {.offset = 0x62beec, .width = Width::kI32}}, // 0x1402c4210, ô 0x1af0 của vtable CDataPool -> 0x14015bde0
    {.table = "DataPool", .name = "GetBaseBag_Num", .field = {.offset = 0x13b30, .width = Width::kU8}}, // 0x1402e8ff0, ô 0x288 của vtable CDataPool -> 0x1400bdcd0
    {.table = "DataPool", .name = "GetBoothList_Num", .field = {.offset = 0x13d5c, .width = Width::kI32}}, // 0x1402d5670, ô 0x5e8 của vtable CDataPool -> 0x14015b9b0
    {.table = "DataPool", .name = "GetMatBag_Num", .field = {.offset = 0x13b31, .width = Width::kU8}}, // 0x1402e9100, ô 0x298 của vtable CDataPool -> 0x1400bdcf0
    {.table = "MailSystem", .name = "GetMailCount", .field = {.offset = 0x14234, .width = Width::kI32}}, // 0x140355ea0, ô 0xbc8 của vtable CDataPool -> 0x14015eec0
    {.table = "NpcShop", .name = "GetNpcId", .field = {.offset = 0x13f20, .width = Width::kI32}}, // 0x1403595b0, ô 0x6c8 của vtable CDataPool -> 0x14015bad0
    {.table = "Pneuma", .name = "GetPneumaChip", .field = {.offset = 0x13b74, .width = Width::kI32}}, // 0x14045d260, ô 0x2e0 của vtable CDataPool -> 0x1401607e0
    {.table = "Pneuma", .name = "GetPneumaExp", .field = {.offset = 0x13b70, .width = Width::kI32}}, // 0x14045d2b0, ô 0x2d0 của vtable CDataPool -> 0x1401607f0
    {.table = "StallBuy", .name = "GetCoinType", .field = {.offset = 0x15d38, .width = Width::kU8}}, // 0x1403ba060, ô 0x10f8 của vtable CDataPool -> 0x14015f400
    {.table = "StallBuy", .name = "GetDefaultPage", .field = {.offset = 0x15c60, .width = Width::kI32}}, // 0x1403bae20, ô 0x10d8 của vtable CDataPool -> 0x14015f410
    {.table = "StallBuy", .name = "GetPrePrice", .field = {.offset = 0x15df0, .width = Width::kI32}}, // 0x1403bb1f0, ô 0x14d0 của vtable CDataPool -> 0x14015ee10
    {.table = "StallBuy", .name = "GetServerType", .field = {.offset = 0x15d39, .width = Width::kU8}}, // 0x1403ba0b0, ô 0x1108 của vtable CDataPool -> 0x14015f490
    {.table = "StallBuy", .name = "GetTradeTax", .field = {.offset = 0x15c70, .width = Width::kI32}}, // 0x1403ba010, ô 0x10e8 của vtable CDataPool -> 0x14015f4d0
    {.table = "StallSale", .name = "GetCoinType", .field = {.offset = 0x15c00, .width = Width::kU8}}, // 0x1403bb960, ô 0xe38 của vtable CDataPool -> 0x14015efd0
    {.table = "StallSale", .name = "GetDefaultPage", .field = {.offset = 0x15b28, .width = Width::kI32}}, // 0x1403be1c0, ô 0xe08 của vtable CDataPool -> 0x14015eff0
    {.table = "StallSale", .name = "GetPosTax", .field = {.offset = 0x15b34, .width = Width::kI32}}, // 0x1403bb8c0, ô 0xe18 của vtable CDataPool -> 0x14015f110
    {.table = "StallSale", .name = "GetServerType", .field = {.offset = 0x15c01, .width = Width::kU8}}, // 0x1403bb9b0, ô 0xe48 của vtable CDataPool -> 0x14015f130
    {.table = "StallSale", .name = "GetStallServerType", .field = {.offset = 0x15c01, .width = Width::kU8}}, // 0x1403be5f0, ô 0xe48 của vtable CDataPool -> 0x14015f130
    {.table = "StallSale", .name = "GetTradeTax", .field = {.offset = 0x15b38, .width = Width::kI32}}, // 0x1403bb910, ô 0xe28 của vtable CDataPool -> 0x14015f170
    {.table = "SystemSetup", .name = "GetCaredObjId", .field = {.offset = 0x5b8f08, .width = Width::kI32}}, // 0x140466fc0, ô 0x1498 của vtable CDataPool -> 0x14015f790
    {.table = "SystemSetup", .name = "NineHeadGetUITipFlag", .field = {.offset = 0x6ba2fc, .width = Width::kI32}}, // 0x1404675a0, ô 0x14a0 của vtable CDataPool -> 0x1400da7b0
    {.table = "YiGui", .name = "GetWeaponYiGuiMoveFromIndex", .field = {.offset = 0x14014, .width = Width::kI32}}, // 0x1403c7140, ô 0xa40 của vtable CDataPool -> 0x1401609c0
    {.table = "YiGui", .name = "GetWeaponYiGuiMoveToIndex", .field = {.offset = 0x14018, .width = Width::kI32}}, // 0x1403c7190, ô 0xa50 của vtable CDataPool -> 0x1401609d0
    {.table = "YiGui", .name = "GetWeaponYiGuiSize", .field = {.offset = 0x14010, .width = Width::kU8}}, // 0x1403c6f80, ô 0xa30 của vtable CDataPool -> 0x1401609e0
    {.table = "YiGui", .name = "GetYiGuiMoveFromIndex", .field = {.offset = 0x13fec, .width = Width::kI32}}, // 0x1403c64a0, ô 0x9e0 của vtable CDataPool -> 0x1401609f0
    {.table = "YiGui", .name = "GetYiGuiMoveToIndex", .field = {.offset = 0x13ff0, .width = Width::kI32}}, // 0x1403c64f0, ô 0x9f0 của vtable CDataPool -> 0x140160a00
    {.table = "YiGui", .name = "GetYiGuiNpcID", .field = {.offset = 0x13ff4, .width = Width::kI32}}, // 0x1403c6910, ô 0xa00 của vtable CDataPool -> 0x140160a10
    {.table = "YiGui", .name = "GetYiGuiSize", .field = {.offset = 0x13fe8, .width = Width::kU8}}, // 0x1403c5e20, ô 0x9d0 của vtable CDataPool -> 0x140160a20
}};

// Giá trị đầu khác 0 của các trường trên theo hàm dựng CDataPool 0x1400dec40 (trường không có ở đây là 0).
constexpr std::array<PoolInitial, 11> kInitial = {{
    {.offset = 0x13b30, .width = Width::kU8, .value = 20}, // hàm dựng ghi
    {.offset = 0x13b31, .width = Width::kU8, .value = 20}, // hàm dựng ghi
    {.offset = 0x13db4, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x13de0, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x13fec, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x13ff0, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x14014, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x14018, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x14064, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x14070, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x62beec, .width = Width::kI32, .value = -1}, // hàm dựng ghi
}};

template <std::size_t Index>
NativeResult pool_number(lua_State* lua) {
    constexpr const Getter& getter = kGetters.at(Index);
    lua_pushnumber(lua, static_cast<double>(native::context_of(lua).facts.pool.read(getter.field, kInitial)));
    return 1;
}

template <std::size_t... Index>
constexpr std::array<native::Entry, sizeof...(Index)> make_getters(std::index_sequence<Index...>) {
    return {{{.name = kGetters.at(Index).name, .function = &lua::adapt<pool_number<Index>>}...}};
}

constexpr std::array kGetterEntries = make_getters(std::make_index_sequence<kGetters.size()>{});

// Phương thức của ActionItem rỗng: số (text == nullptr) hay chuỗi hằng.
struct ActionMethod {
    const char* name = nullptr;
    double number = 0;
    const char* text = nullptr;
};

constexpr std::array<ActionMethod, 8> kActionMethods = {{
    {.name = "GetDefineID", .number = -1}, // 0x1400135a0, ô 0x40 của vtable CActionItem -> 0x14006a450
    {.name = "GetID", .number = 0}, // 0x140012eb0, ô 0x0 của vtable CActionItem -> 0x1406ad5d0
    {.name = "GetMaxNum", .number = 0}, // 0x140014310, ô 0x130 của vtable CActionItem -> 0x14041cb60
    {.name = "GetName", .text = ""}, // 0x140012f30, ô 0x8 của vtable CActionItem -> 0x140030cb0
    {.name = "GetNum", .number = 0}, // 0x1400137e0, ô 0x48 của vtable CActionItem -> 0x14041cb60
    {.name = "GetPrice", .number = -1}, // 0x1400137a0, ô 0x100 của vtable CActionItem -> 0x140010980
    {.name = "GetType", .text = ""}, // 0x140012ef0, ô 0x38 của vtable CActionItem -> 0x140030e90
    {.name = "IsEnable", .number = 1}, // 0x140013cb0, ô 0x80 của vtable CActionItem -> 0x140653e90
}};

template <std::size_t Index>
NativeResult action_method(lua_State* lua) {
    constexpr const ActionMethod& method = kActionMethods.at(Index);
    if (method.text == nullptr) {
        lua_pushnumber(lua, method.number);
    } else {
        lua_pushstring(lua, method.text);
    }
    return 1;
}

template <std::size_t... Index>
constexpr std::array<native::Entry, sizeof...(Index)> make_methods(std::index_sequence<Index...>) {
    return {{{.name = kActionMethods.at(Index).name, .function = &lua::adapt<action_method<Index>>}...}};
}

constexpr std::array kActionEntries = make_methods(std::make_index_sequence<kActionMethods.size()>{});

// Khoá registry của metatable ActionItem (gốc: DAT_141034670, LuaObject tạo lúc khởi động hệ script).
[[nodiscard]] void* action_metatable_key() noexcept {
    static char key = 0;
    return &key;
}

// EnumAction(vị trí, "bộ lọc") (0x1402348b0): đối số 1 số nghiêm, đối số 2 chuỗi hay số, sai thì câu lỗi của gốc. Gốc hỏi
// CActionSystem (DAT_141034678, ô 0xb8) action thứ vị trí trong bộ lọc, không có thì đóng hộp s_InvalidAction; cả hai gắn metatable
// ActionItem. Khác gốc: chưa có CActionSystem nên luôn đóng hộp ActionItem rỗng (userdata 8 byte, giữ nullptr).
NativeResult enum_action(lua_State* lua) {
    if (!native::strict_number(lua, 1)) return std::unexpected(NativeError::of("LUA: EnumAction Wrong Param1"));
    if (!native::text_arg(lua, 2)) return std::unexpected(NativeError::of("LUA: EnumAction Wrong Param2"));
    void* const box = lua_newuserdata(lua, sizeof(void*));
    *static_cast<void**>(box) = nullptr;
    lua_pushlightuserdata(lua, action_metatable_key());
    lua_rawget(lua, LUA_REGISTRYINDEX);
    lua_setmetatable(lua, -2);
    return 1;
}

constexpr std::array<native::Entry, 1> kGlobals = {{
    {.name = "EnumAction", .function = &lua::adapt<enum_action>},
}};

} // namespace

void register_a_vcall(lua_State* lua) {
    for (std::size_t index = 0; index < kGetters.size(); ++index) {
        const std::span<const native::Entry> entry(&kGetterEntries.at(index), 1);
        if (kGetters.at(index).table == nullptr) {
            native::register_globals(lua, entry);
        } else {
            native::register_table(lua, kGetters.at(index).table, entry);
        }
    }
    // Metatable ActionItem: __index là bảng phương thức (gốc: LuaObject có __index trỏ chính nó và các hàm đăng ký bằng RegisterObjectDirect).
    lua_pushlightuserdata(lua, action_metatable_key());
    lua_newtable(lua);
    lua_pushstring(lua, "__index");
    lua_newtable(lua);
    for (const native::Entry& entry : kActionEntries) {
        lua_pushstring(lua, entry.name);
        lua_pushcfunction(lua, entry.function);
        lua_rawset(lua, -3);
    }
    lua_rawset(lua, -3);
    lua_rawset(lua, LUA_REGISTRYINDEX);
    native::register_globals(lua, kGlobals);
}

} // namespace game::ui::script
