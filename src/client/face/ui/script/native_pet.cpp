// Hàm game của thú cưng và thú con (bảng Pet, TargetPet, Infant; GMInterface_Script_Pet.cpp, GMInterface_Script_Infant.cpp) của Game.exe 2026.
// Gốc đọc kho dữ liệu máy chủ cấp (CDataPool: mười ô thú cưng cỡ 0x238 từ +0x5b8f90, một ô thú con cỡ 0x7f8 từ +0x5f9b28). Client này chưa có
// kho đó, nên mỗi hàm trả đúng trạng thái "kho trống" mà hàm dựng CDataPool để lại (mọi ô có id -1): không có thú cưng, không có thú con.
// Từng hàm ghi địa chỉ và Khác gốc.
#include "hero/hero.hpp"
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/pool_image.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// FUN_1400ce3e0 (Game.exe): chỉ số ô thú cưng so không dấu với 10, tức hợp lệ khi trong 0..9.
constexpr std::int32_t kPetSlots = 10;
// Infant:GetInfantMaxCount trả hằng 1,0 (0x140439870).
constexpr std::int32_t kInfantMaxCount = 1;
// Infant:ToggleInfantPage chỉ mở khi cấp nhân vật lớn hơn 0x31 (0x140439770).
constexpr std::int32_t kInfantPageLevel = 49;
// Id thú cưng đang là mục tiêu (TargetPet:IsPresent đọc int ở DataPool + 0x5b8fc8, dương là có): hàm dựng con FUN_140152550 đặt -1.
constexpr std::array<PoolInitial, 1> kTargetPetInitial = {{{.offset = 0x5b8fc8, .width = Width::kI32, .value = -1}}};

// Pet:GetPet_Count (0x14036e940), Pet:GetPet_Count_PetBank (0x14037e830) và Infant:GetInfantCount (0x140439830): số ô đang có thú trong kho.
// Khác gốc: kho trống nên luôn 0.
NativeResult empty_count(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// Pet:IsPresent(ô) (0x14036e850): ô là số nghiêm trong 0..9 (so không dấu), không thì ném. Gốc đẩy true khi ô có id dương, guid khác 0 và cấp
// không âm. Khác gốc: kho trống nên luôn false. Gốc còn ném "Not a valid obj" khi self không phải đối tượng Pet; ở đây
// bảng Pet là bảng thường nên không có gì để so.
NativeResult pet_is_present(lua_State* lua) {
    const std::optional<double> given = native::strict_number(lua, 2);
    const std::int32_t slot = given ? native::to_int(*given) : -1;
    if (slot < 0 || slot >= kPetSlots) return std::unexpected(NativeError::of("LUA:Pet IsPresent parameter error"));
    lua_pushboolean(lua, 0);
    return 1;
}

// Pet:GetPetList_Appoint(chỉ số) (0x14036ea30): tên và nơi cất của thú cưng thứ chỉ số trong các ô có thú; không phải số thì ném. Hết ô thì
// đẩy hai chuỗi rỗng (DAT_140b6a362, DAT_140b6a363). Khác gốc: kho trống nên luôn hai chuỗi rỗng.
NativeResult pet_list_appoint(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return std::unexpected(NativeError::of("LUA:Pet GetPetList_Appoint parameter error"));
    lua_pushlstring(lua, "", 0);
    lua_pushlstring(lua, "", 0);
    return 2;
}

// Pet:ShowPetList(n) (0x140374480): ngoài cảnh khoá, n >= 1 mở danh sách thú cưng (OPEN_PET_LIST, id 0xea), n < 1 đóng (CLOSE_PET_LIST, 0xec);
// không phải số nghiêm thì ném. Cảnh khoá thì không làm gì và không kiểm đối số.
NativeResult pet_show_list(lua_State* lua) {
    Context& context = native::context_of(lua);
    if (context.facts.in_hell()) return 0;
    const std::optional<double> given = native::strict_number(lua, 2);
    if (!given) return std::unexpected(NativeError::of("LUA:Pet ShowPetList parameter error"));
    context.push_event(native::to_int(*given) < 1 ? "CLOSE_PET_LIST" : "OPEN_PET_LIST", {});
    return 0;
}

// TargetPet:IsPresent() (0x1403bebe0): true khi int ở DataPool + 0x5b8fc8 dương. Đọc từ Facts::pool, chưa ghi thì -1 (false).
NativeResult target_pet_is_present(lua_State* lua) {
    const std::int64_t value =
        native::context_of(lua).facts.pool.read({.offset = kTargetPetInitial.front().offset, .width = Width::kI32}, kTargetPetInitial);
    lua_pushboolean(lua, value > 0 ? 1 : 0);
    return 1;
}

// Infant:GetInfantMaxCount() (0x140439870).
NativeResult infant_max_count(lua_State* lua) {
    lua_pushnumber(lua, kInfantMaxCount);
    return 1;
}

// Infant:GetInfantSkillInfo(id, ô) (0x14043abb0): hai đối số phải là số nghiêm. Trả bảy giá trị: id kỹ năng, bậc, mức, tỉ lệ tăng và ba chuỗi
// (tên, mô tả, giá trị tăng). Không có thú con ở id đó, hay ô kỹ năng trống, thì gốc trả -1, 0, 0, 0 và ba chuỗi rỗng (DAT_140ba06dc,
// DAT_140ba06dd, DAT_140ba0529; DAT_140ba052a, 052c, 052e); ô lớn hơn 3 khi có thú con thì ném cùng câu lỗi. Khác gốc: không có thú con nên
// luôn là bộ giá trị trống.
NativeResult infant_skill_info(lua_State* lua) {
    if (!native::strict_number(lua, 2) || !native::strict_number(lua, 3)) {
        return std::unexpected(NativeError::of("LUA:Infant GetInfantSkillInfo parameter error"));
    }
    lua_pushnumber(lua, -1);
    lua_pushnumber(lua, 0);
    lua_pushnumber(lua, 0);
    lua_pushnumber(lua, 0);
    lua_pushlstring(lua, "", 0);
    lua_pushlstring(lua, "", 0);
    lua_pushlstring(lua, "", 0);
    return 7;
}

// Infant:GetInfantSex, GetInfantLevel, GetStage, GetInfantName (id) (0x140439950, 0x140439b40, 0x140439bf0, 0x1404398b0): đối số không phải số
// hay không có thú con ở id đó thì ném "LUA:Infant <tên> parameter error"; ngược lại đẩy một trường của thú con. Khác gốc: không có thú con nên
// luôn ném.
NativeResult infant_sex(lua_State* /*lua*/) {
    return std::unexpected(NativeError::of("LUA:Infant GetInfantSex parameter error"));
}

NativeResult infant_level(lua_State* /*lua*/) {
    return std::unexpected(NativeError::of("LUA:Infant GetInfantLevel parameter error"));
}

NativeResult infant_stage(lua_State* /*lua*/) {
    return std::unexpected(NativeError::of("LUA:Infant GetStage parameter error"));
}

NativeResult infant_name(lua_State* /*lua*/) {
    return std::unexpected(NativeError::of("LUA:Infant GetInfantName parameter error"));
}

// Infant:ToggleInfantPage() (0x140439770): ngoài cảnh khoá, cấp nhân vật phải lớn hơn 49 (không thì báo "#{ZNJCS_130825_8}"); có thú con thì
// bật tắt trang (TOGGLE_OPENT_INFANT, trả 1), không thì báo "#{ZNJCS_130825_9}"; cả hai thông báo đi bằng NEW_DEBUGMESSAGE. Trả 0 mọi nhánh trừ
// khi mở được. Khác gốc: không có thú con nên nhánh bật tắt chưa làm; chưa có nhân vật coi như cấp 0 (gốc đọc thẳng từ đối tượng người chơi).
NativeResult infant_toggle_page(lua_State* lua) {
    Context& context = native::context_of(lua);
    if (!context.facts.in_hell()) {
        const std::int32_t level = context.facts.hero != nullptr ? context.facts.hero->level : 0;
        const std::array<std::string_view, 1> message = {level > kInfantPageLevel ? "#{ZNJCS_130825_9}" : "#{ZNJCS_130825_8}"};
        context.push_event("NEW_DEBUGMESSAGE", message);
    }
    lua_pushnumber(lua, 0);
    return 1;
}

constexpr std::array<native::Entry, 8> kInfant = {{
    {.name = "GetInfantCount", .function = &lua::adapt<empty_count>},
    {.name = "GetInfantMaxCount", .function = &lua::adapt<infant_max_count>},
    {.name = "GetInfantSkillInfo", .function = &lua::adapt<infant_skill_info>},
    {.name = "GetInfantSex", .function = &lua::adapt<infant_sex>},
    {.name = "GetInfantLevel", .function = &lua::adapt<infant_level>},
    {.name = "GetStage", .function = &lua::adapt<infant_stage>},
    {.name = "GetInfantName", .function = &lua::adapt<infant_name>},
    {.name = "ToggleInfantPage", .function = &lua::adapt<infant_toggle_page>},
}};
constexpr std::array<native::Entry, 5> kPet = {{
    {.name = "GetPet_Count", .function = &lua::adapt<empty_count>},
    {.name = "GetPet_Count_PetBank", .function = &lua::adapt<empty_count>},
    {.name = "IsPresent", .function = &lua::adapt<pet_is_present>},
    {.name = "GetPetList_Appoint", .function = &lua::adapt<pet_list_appoint>},
    {.name = "ShowPetList", .function = &lua::adapt<pet_show_list>},
}};
constexpr std::array<native::Entry, 1> kTargetPet = {{{.name = "IsPresent", .function = &lua::adapt<target_pet_is_present>}}};

} // namespace

void register_pet(lua_State* lua) {
    native::register_table(lua, "Infant", kInfant);
    native::register_table(lua, "Pet", kPet);
    native::register_table(lua, "TargetPet", kTargetPet);
}

} // namespace game::ui::script
