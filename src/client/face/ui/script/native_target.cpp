// Hàm game của mục tiêu đang chọn (bảng Target và CachedTarget dùng chung CharacterMetaTable; GMGameInterface_Script_Target.cpp) của Game.exe
// 2026. Gốc hỏi ObjectManager (DAT_14103db40) đối tượng đang chọn (+0xa8). Client này chưa có khái niệm mục tiêu nên mọi hàm trả kết quả của
// "không có mục tiêu". Từng hàm ghi địa chỉ và Khác gốc.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/pool_image.hpp"

#include <array>
#include <cstdint>

namespace game::ui::script {
namespace {

using lua::NativeResult;

// Cờ mà Target:IsPresent(số) đọc (int ở DataPool + 0x13ae0, khác 0 là có): hàm dựng CDataPool đặt -1, nên trước khi máy chủ ghi thì "có".
constexpr std::uint32_t kPresentFlag = 0x13ae0;
constexpr std::array<PoolInitial, 1> kPresentInitial = {{{.offset = kPresentFlag, .width = Width::kI32, .value = -1}}};

// Target:GetMenPai() và CachedTarget:GetMenPai() (0x1402b83b0): môn phái của mục tiêu khi mục tiêu là người chơi hay NPC có môn, còn không có
// mục tiêu thì 0. Khác gốc: không có mục tiêu nên luôn 0. Gốc ném "Not a valid obj" khi self không phải đối tượng mục tiêu; ở đây bảng là
// bảng thường nên không có gì để so.
NativeResult target_menpai(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// Target:IsPresent([số]) và CachedTarget:IsPresent([số]) (0x140687a14 chuyển tiếp ô ảo 3, thân ở 0x1402b9a20): có đối số số nghiêm thì true khi
// cờ ở DataPool + 0x13ae0 khác 0, không có thì true khi có đối tượng đang chọn. Khác gốc: không có đối tượng đang chọn nên dạng không đối số
// luôn false.
NativeResult target_is_present(lua_State* lua) {
    bool present = false;
    if (native::strict_number(lua, 2)) {
        present = native::context_of(lua).facts.pool.read({.offset = kPresentFlag, .width = Width::kI32}, kPresentInitial) != 0;
    }
    lua_pushboolean(lua, present ? 1 : 0);
    return 1;
}

// Lua_CheckMainTargetHaveMaskBuff() (0x1402846a0): 1 khi đối tượng đang chọn (hay chủ của nó, nếu đối tượng kiểu 2) thuộc kiểu 1 và mang
// impact 0x22d7, còn không 0. Khác gốc: không có mục tiêu nên luôn 0.
NativeResult check_main_target_have_mask_buff(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

constexpr std::array<native::Entry, 2> kCharacter = {{
    {.name = "GetMenPai", .function = &lua::adapt<target_menpai>},
    {.name = "IsPresent", .function = &lua::adapt<target_is_present>},
}};
constexpr std::array<native::Entry, 1> kGlobals = {{
    {.name = "Lua_CheckMainTargetHaveMaskBuff", .function = &lua::adapt<check_main_target_have_mask_buff>},
}};

} // namespace

void register_target(lua_State* lua) {
    native::register_globals(lua, kGlobals);
    native::register_table(lua, "Target", kCharacter);
    native::register_table(lua, "CachedTarget", kCharacter);
}

} // namespace game::ui::script
