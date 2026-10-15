#include "hero/hero.hpp"
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeResult;

// Hàm của gốc giữ mọi số này trong CCharacterData dưới dạng int32 (đọc ở `*(*(người+8) + offset)`), nên nó không có ca tràn;
// Hero giữ int64 cho thanh máu và kinh nghiệm, ép về int32 kẹp biên thay vì quấn vòng.
constexpr std::int32_t narrow(std::int64_t value) noexcept {
    constexpr std::int64_t kLow = std::numeric_limits<std::int32_t>::min();
    constexpr std::int64_t kHigh = std::numeric_limits<std::int32_t>::max();
    return static_cast<std::int32_t>(std::clamp(value, kLow, kHigh));
}

// MAXRAGE của gốc không đọc từ dữ liệu: mã máy đẩy thẳng 0x3e8 (Game.exe 0x140388065).
constexpr std::int32_t kMaxRage = 1000;

using Reader = std::int32_t (*)(const Facts&, const hero::Hero&) noexcept;

struct NumberKey {
    std::string_view key;
    Reader read;
};

// Khoá số của Player:GetData (Game.exe 0x140387360, SCRIPT_SANDBOX::PlayerMySelf slot 21): mỗi khoá một getter của CCharacterData,
// kết quả đẩy bằng LuaState::PushInteger (lua_pushnumber((double)int)). Offset ghi cạnh để đối chiếu với mã máy; chỉ đưa vào khoá mà
// hero::Hero có dữ liệu thật, khoá còn lại chờ nguồn từ máy chủ (không đưa số giả).
constexpr std::array kNumbers = std::to_array<NumberKey>({
    {.key = "LEVEL", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.level; }},                       // người+0x74
    {.key = "HP", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.health.now); }},             // +0x6350
    {.key = "MP", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.mana.now); }},               // +0x6354
    {.key = "MAXHP", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.health.top); }},          // +0x63d4
    {.key = "MAXMP", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.mana.top); }},            // +0x63d8
    {.key = "RAGE", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.rage.now); }},             // người+0x7c
    {.key = "MAXRAGE", .read = [](const Facts&, const hero::Hero&) noexcept { return kMaxRage; }},                      // hằng
    {.key = "STRIKEPOINT", .read = [](const Facts&, const hero::Hero& self) noexcept { return std::int32_t{self.strike_points}; }}, // +0x6364
    {.key = "MEMPAI", .read = [](const Facts&, const hero::Hero& self) noexcept { return static_cast<std::int32_t>(self.sect); }},  // +0x2bc
    {.key = "STR", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.roots.strength; }},                // +0x63bc
    {.key = "SPR", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.roots.spirit; }},                  // +0x63c0
    {.key = "CON", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.roots.constitution; }},            // +0x63ac
    {.key = "INT", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.roots.stability; }},               // +0x63b0
    {.key = "DEX", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.roots.agility; }},                 // +0x63b4
    {.key = "POINT_REMAIN", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.spare_points; }},         // +0x63b8
    {.key = "ATT_PHYSICS", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.attack_physical; }},   // +0x63c4
    {.key = "ATT_MAGIC", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.attack_magic; }},        // +0x63c8
    {.key = "DEF_PHYSICS", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.defence_physical; }},  // +0x63cc
    {.key = "DEF_MAGIC", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.defence_magic; }},       // +0x63d0
    {.key = "HIT", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.hit; }},                       // +0x63e4
    {.key = "MISS", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.miss; }},                     // +0x63e8
    {.key = "CRITICALATTACK", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.critical_attack; }},    // +0x63ec
    {.key = "CRITICALDEFENCE", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.combat.critical_defence; }}, // +0x63f0
    {.key = "GUILD", .read = [](const Facts& facts, const hero::Hero&) noexcept { return facts.guild_id; }},               // +0x2b4, có dấu
    {.key = "ZONEWORLDID", .read = [](const Facts& facts, const hero::Hero&) noexcept { return facts.zone_world_id; }}, // +0xd8, có dấu
    {.key = "VIGOR", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.vigor.now); }},           // +0x6370
    {.key = "MAXVIGOR", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.vigor.top); }},        // +0x6374
    {.key = "ENERGY", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.energy.now); }},         // +0x6378
    {.key = "MAXENERGY", .read = [](const Facts&, const hero::Hero& self) noexcept { return narrow(self.energy.top); }},      // +0x637c
    {.key = "BATTLESCORE", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.battle_score; }},          // +0x6774
    {.key = "MONEY_JZ", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.money_voucher; }},      // +0x49bc
    {.key = "YUANBAO", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.yuanbao; }},             // +0x64e0
    {.key = "BIND_YUANBAO", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.bind_yuanbao; }},   // +0x64e8
    {.key = "GIFTTOKEN", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.gift_token; }},        // +0x64ec
    {.key = "ZENGDIAN", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.bonus_point; }},        // +0x64f0
    {.key = "LIJIN", .read = [](const Facts&, const hero::Hero& self) noexcept { return self.purse.cash_gift; }},             // +0x64f4
    // Cờ loại máy chủ ở đối tượng hệ thống (DAT_141034c40 + 0x6f5868, 0x6f586c, 0x6f5874), không ở nhân vật.
    {.key = "IsPKServer_JD", .read = [](const Facts& f, const hero::Hero&) noexcept { return f.server.pk_jd; }},
    {.key = "IsOriginalJD", .read = [](const Facts& f, const hero::Hero&) noexcept { return f.server.original_jd; }},
    {.key = "Is2606S", .read = [](const Facts& f, const hero::Hero&) noexcept { return f.server.s2606; }},
});

// Đẩy số thập phân của value như _snprintf("%lld") của gốc. Bộ đệm 24 byte đủ cho int64 (20 chữ số và dấu).
NativeResult push_decimal(lua_State* lua, std::int64_t value) {
    std::array<char, 24> text{};
    const std::to_chars_result done = std::to_chars(std::to_address(text.begin()), std::to_address(text.end()), value);
    lua_pushlstring(lua, text.data(), static_cast<std::size_t>(std::distance(text.data(), done.ptr)));
    return 1;
}

// "MONEY": bốn số liên tiếp: tổng, rồi vàng (tiền / 10000), bạc ((tiền / 100) % 100), đồng (tiền % 100). Gốc tính bằng phép chia nguyên
// cắt về 0 và chỉ tách vàng/bạc khi tiền đủ một đơn vị (>= 10000 và >= 100), nên tiền âm cho vàng và bạc bằng 0.
NativeResult push_money(lua_State* lua, std::int32_t money) {
    const std::int32_t copper = money % 100;
    const std::int32_t silver = money >= 100 ? (money / 100) % 100 : 0;
    const std::int32_t gold = money >= 10000 ? money / 10000 : 0;
    lua_pushnumber(lua, money);
    lua_pushnumber(lua, gold);
    lua_pushnumber(lua, silver);
    lua_pushnumber(lua, copper);
    return 4;
}

// Player:GetData(khoá) (Game.exe 0x140387360): đọc một thuộc tính của nhân vật người chơi. Chưa có nhân vật (chưa vào cảnh) hay đối
// số không phải chuỗi hay số thì không trả gì. Khoá so khớp đúng từng byte, sau khi cắt ở NUL đầu tiên (gốc lấy chuỗi bằng GetString).
// Khác gốc: khoá hero::Hero chưa có dữ liệu (hơn 130 khoá của gốc: hành hội, điểm hoạt động, cờ máy chủ khác...) và khoá lạ cũng không
// trả gì; gốc với khoá lạ đẩy một số thừa trong thanh ghi r8d (Game.exe 0x14038a11c), không có giá trị nào đáng bắt chước.
NativeResult get_data(lua_State* lua) {
    const std::optional<std::string_view> raw = native::text_arg(lua, 2);
    if (!raw) return 0;
    const Facts& facts = native::context_of(lua).facts;
    if (facts.hero == nullptr) return 0;
    const hero::Hero& hero = *facts.hero;
    const std::string_view key = native::c_string(*raw);
    if (key == "MONEY") return push_money(lua, hero.purse.money);
    // Chuỗi, không phải số: kinh nghiệm vượt int32 ở cấp cao. Kinh nghiệm âm in "0" (0x140179ad0 trả -1 khi chưa có).
    if (key == "EXP") return push_decimal(lua, std::max<std::int64_t>(hero.experience.now, 0));
    if (key == "NEEDEXP") return push_decimal(lua, hero.experience.top);
    const auto found = std::ranges::find(kNumbers, key, &NumberKey::key);
    if (found == kNumbers.end()) return 0;
    lua_pushnumber(lua, found->read(facts, hero));
    return 1;
}

// Player:GetLevel() (Game.exe 0x140396650): cấp của người chơi. Chưa có nhân vật thì gốc ném ngoại lệ assert `pMyself`
// (GMGameInterface_Script_PlayerMySelf.cpp dòng 0x1c04); ở đây là lỗi Lua mang cùng tên điều kiện (Khác gốc: câu lỗi không có
// đường dẫn đầy đủ của máy dựng).
NativeResult get_level(lua_State* lua) {
    const hero::Hero* const hero = native::context_of(lua).facts.hero;
    if (hero == nullptr) return std::unexpected(lua::NativeError::of("GMGameInterface_Script_PlayerMySelf.cpp(7172): pMyself"));
    lua_pushnumber(lua, hero->level);
    return 1;
}

// Player:GetName() (PlayerMySelf slot 1, Game.exe 0x1403872f0): tên nhân vật, chuỗi rỗng khi chưa có nhân vật.
NativeResult get_name(lua_State* lua) {
    const hero::Hero* const hero = native::context_of(lua).facts.hero;
    lua_pushstring(lua, hero == nullptr ? "" : hero->name.c_str());
    return 1;
}

// Player:IsLeader() (Game.exe 0x140393f10): 1 khi nhân vật là đội trưởng (cặp id người chơi trùng cặp id đội trưởng của DataPool), 0
// khi không. Chưa có nhân vật thì 0 (Khác gốc: gốc đọc đối tượng người chơi không kiểm null).
NativeResult is_leader(lua_State* lua) {
    const hero::Hero* const hero = native::context_of(lua).facts.hero;
    lua_pushnumber(lua, hero != nullptr && hero->is_leader ? 1 : 0);
    return 1;
}

// DataPool:GetSelfZoneWorldID() (0x1402ff7b0): id thế giới của vùng, -1 khi chưa có nhân vật.
NativeResult get_self_zone_world_id(lua_State* lua) {
    const Facts& facts = native::context_of(lua).facts;
    lua_pushnumber(lua, facts.hero == nullptr ? -1 : facts.zone_world_id);
    return 1;
}

// DataPool:GetGuildClanID() (0x1402ffd80): id bang rồi hằng -1 (id tộc, gốc đẩy -1.0 cố định). Khác gốc: không kiểm nhân vật.
NativeResult get_guild_clan_id(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.guild_id);
    lua_pushnumber(lua, -1);
    return 2;
}

constexpr std::array<native::Entry, 4> kPlayer = {{
    {.name = "GetData", .function = &lua::adapt<get_data>},
    {.name = "GetLevel", .function = &lua::adapt<get_level>},
    {.name = "GetName", .function = &lua::adapt<get_name>},
    {.name = "IsLeader", .function = &lua::adapt<is_leader>},
}};
constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "GetSelfZoneWorldID", .function = &lua::adapt<get_self_zone_world_id>},
    {.name = "GetGuildClanID", .function = &lua::adapt<get_guild_clan_id>},
}};

} // namespace

void register_player(lua_State* lua) {
    native::register_table(lua, "Player", kPlayer);
    native::register_table(lua, "DataPool", kDataPool);
}

} // namespace game::ui::script
