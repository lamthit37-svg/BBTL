/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/native_mission.cpp
 *  PHÂN HỆ   : Client / Giao diện / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - DataPool:GetPlayerMission_* và hàm theo dõi mà QuestLog.lua,
 *    MissionTrack.lua gọi: sổ 20 ô từ Facts::missions, định nghĩa từ
 *    Facts::mission_defs.
 *  - Cờ State_1, State_2, MissionVar_<script> nằm trong bảng biến như gốc.
 *  - Description nạp trễ tệp event như gốc; chỗ chưa làm: docs/NGHI-NGO.md 86.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "quest/defs.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "ui/panel/npc_talk.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/variable.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Sổ rỗng cho lúc host chưa đặt Facts::missions: gốc luôn có CDataPool nên không có ca "không sổ".
constexpr quest::Log kNoMissions{};
// GetVariable của gốc trả -1 khi chưa có khoá; cờ theo dõi coi -1 là "dùng mặc định".
constexpr std::int32_t kStoredMissing = -1;
constexpr std::string_view kStateMissions = "State_1";
constexpr std::string_view kStateCampaigns = "State_2";
constexpr std::string_view kNeedsParameters = "GetPlayerMission_Variable: g_Parameter_* chưa dựng";
constexpr std::string_view kBadIndex = "LUA:GetPlayerMission_InUse error index[{}]";

[[nodiscard]] const quest::Log& log_of(const Facts& facts) noexcept {
    return facts.missions == nullptr ? kNoMissions : *facts.missions;
}

// Chỉ số ô đổi như (int) của gốc rồi so không dấu với 20: số âm thành số rất lớn nên ra ngoài biên.
[[nodiscard]] std::uint32_t slot_number(double value) noexcept {
    return static_cast<std::uint32_t>(native::to_int(value));
}

[[nodiscard]] const quest::Slot* slot_at(const Facts& facts, std::uint32_t number) noexcept {
    if (number >= quest::kSlotCount) return nullptr;
    return &log_of(facts).slots.at(number);
}

// Ô đang dùng khi cả id nhiệm vụ lẫn id script khác -1 (Game.exe 0x1402cdae0).
[[nodiscard]] bool in_use(const quest::Slot& slot) noexcept {
    return slot.script != quest::kNoMission && slot.mission != quest::kNoMission;
}

[[nodiscard]] NativeResult bad_param(std::string_view message) {
    return std::unexpected(NativeError::of(message));
}

[[nodiscard]] NativeResult push_number(lua_State* lua, double value) {
    lua_pushnumber(lua, value);
    return 1;
}

// Khác gốc: gốc in nguyên "%d" vì không đưa đối số cho tThrowStringException; ở đây in chỉ số thật.
[[nodiscard]] NativeResult bad_index(std::uint32_t number) {
    const auto shown = static_cast<std::int32_t>(number);
    const std::string message = std::format(kBadIndex, shown);
    return bad_param(message);
}

// Tham số thứ at của ô number; 0 khi ô hay chỉ số tham số ngoài biên (gốc kiểm không dấu cả hai).
[[nodiscard]] std::int32_t param_of(const Facts& facts, std::uint32_t number, std::uint32_t at) {
    if (at >= quest::kParamCount) return 0;
    const quest::Slot* slot = slot_at(facts, number);
    if (slot == nullptr) return 0;
    return static_cast<std::int32_t>(slot->params.at(at));
}

// Giá trị cờ lưu trong bảng biến: -1 hay chưa có thì dùng mặc định, còn lại dương là bật.
[[nodiscard]] bool stored_flag(const VariableSystem& variables, std::string_view name,
    bool fallback) {
    const std::optional<std::string_view> text = variables.get(name);
    if (!text) return fallback;
    const std::int32_t value = variables.get_int(name);
    if (value == kStoredMissing) return fallback;
    return value > 0;
}

// Gốc ghi thẳng bảng (và tệp .trk, chưa làm ở đây), không phát VARIABLE_CHANGED.
void store_flag(VariableSystem& variables, std::string_view name, bool is_on) {
    const std::string_view text = is_on ? "1" : "0";
    static_cast<void>(variables.set(name, text));
}

[[nodiscard]] bool mission_track_open(const VariableSystem& variables, std::int32_t script) {
    const std::string name = std::format("MissionVar_{}", script);
    return stored_flag(variables, name, true);
}

void set_mission_track_open(VariableSystem& variables, std::int32_t script, bool is_open) {
    const std::string name = std::format("MissionVar_{}", script);
    store_flag(variables, name, is_open);
}

// DataPool:GetPlayerMission_Num() (Game.exe 0x1402cda90). Gốc đọc byte đếm ở đầu mảng ô; client
// này không giữ byte đó mà đếm ô đang dùng (Khác gốc: sổ có lỗ thì byte của gốc do máy chủ đặt).
NativeResult get_mission_num(lua_State* lua) {
    const quest::Log& log = log_of(native::context_of(lua).facts);
    const std::ptrdiff_t held = std::ranges::count_if(log.slots, in_use);
    return push_number(lua, static_cast<double>(held));
}

// DataPool:GetPlayerMission_InUse(ô) (0x1402cdae0): 1 khi ô đang giữ nhiệm vụ, 0 khi trống; chỉ số
// ngoài 0..19 là lỗi.
NativeResult get_in_use(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMission_InUse");
    const std::uint32_t number = slot_number(*raw);
    const quest::Slot* slot = slot_at(native::context_of(lua).facts, number);
    if (slot == nullptr) return bad_index(number);
    return push_number(lua, in_use(*slot) ? 1 : 0);
}

// DataPool:GetPlayerMissionIndexByID(id) (0x1402cfe30, FUN_14009e050): chỉ số ô giữ nhiệm vụ id, -1
// khi không có.
NativeResult get_index_by_id(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionIndexByID");
    const std::int32_t mission = native::to_int(*raw);
    const quest::Log& log = log_of(native::context_of(lua).facts);
    const auto found = std::ranges::find(log.slots, mission, &quest::Slot::mission);
    if (found == log.slots.end()) return push_number(lua, -1);
    return push_number(lua, static_cast<double>(found - log.slots.begin()));
}

// DataPool:GetPlayerMission_Variable(ô, tham số [, bảng, chỉ số]) (0x1402cfeb0). Hai đối số: tham
// số thứ hai của ô (0 khi ngoài biên). Bốn đối số với bảng 1, 2, 3 đọc qua các bảng g_Parameter_*
// của sáu bộ xử lý ở 0x1401db7b0..0x1401dc240 (Khác gốc: bảng chưa dựng, báo lỗi rõ thay vì trả số
// giả); bảng khác thì như hai đối số; đối số năm không phải số thì 0.
NativeResult get_mission_variable(lua_State* lua) {
    const std::optional<double> raw_slot = native::strict_number(lua, 2);
    const std::optional<double> raw_param = native::strict_number(lua, 3);
    if (!raw_slot || !raw_param) return bad_param("LUA:GetPlayerMission_Variable");
    const std::uint32_t number = slot_number(*raw_slot);
    if (number >= quest::kSlotCount) return push_number(lua, 0);
    const Facts& facts = native::context_of(lua).facts;
    const std::int32_t plain = param_of(facts, number, slot_number(*raw_param));
    const std::optional<double> table = native::strict_number(lua, 4);
    if (!table) return push_number(lua, plain);
    if (!native::strict_number(lua, 5)) return push_number(lua, 0);
    const std::int32_t which = native::to_int(*table);
    if (which < 1 || which > 3) return push_number(lua, plain);
    return bad_param(kNeedsParameters);
}

// Byte thứ offset (0 là byte cao nhất) của tham số first + offset / 4; phép chia và dư cắt về 0 như
// C, dịch số học rồi lấy byte thấp, dịch bị che 5 bit như sar của x86. Đọc từ mã máy 0x1402d1312
// đến 0x1402d135d: cdq/and 3/sar 2 cho thương và dư, ((3 - dư) << 3) vào cl rồi sar eax, cl, movzx
// al. Bốn đối số của Variable (0x1402cfeb0, bảng 0x188, 0x1b8, 0x1e8 của bản ghi, mỗi mục 0x14
// byte, mục +4 là chỉ số tham số, +0x10 là vị trí byte) dùng cùng phép dịch ở 0x1402d003b.
[[nodiscard]] std::int32_t byte_of(const Facts& facts, std::uint32_t number, std::int32_t first,
    std::int32_t offset) {
    const std::int64_t word = std::int64_t{first} + offset / 4;
    if (word < 0 || word >= static_cast<std::int64_t>(quest::kParamCount)) return 0;
    const auto at = static_cast<std::uint32_t>(word);
    const std::int32_t value = param_of(facts, number, at);
    if (value == 0) return 0;
    const std::int32_t lane = offset % 4;
    const auto shift = static_cast<unsigned>((3 - lane) * 8) & 31U;
    return static_cast<std::uint8_t>(value >> shift);
}

// DataPool:GetPlayerMission_VariableByByte(ô, tham số, byte) (0x1402d1280).
NativeResult get_variable_by_byte(lua_State* lua) {
    const std::optional<double> raw_slot = native::strict_number(lua, 2);
    const std::optional<double> raw_first = native::strict_number(lua, 3);
    const std::optional<double> raw_byte = native::strict_number(lua, 4);
    const bool is_valid = raw_slot && raw_first && raw_byte;
    if (!is_valid) return bad_param("LUA:GetPlayerMission_VariableByByte");
    const std::uint32_t number = slot_number(*raw_slot);
    if (number >= quest::kSlotCount) return push_number(lua, 0);
    const Facts& facts = native::context_of(lua).facts;
    const std::int32_t first = native::to_int(*raw_first);
    const std::int32_t offset = native::to_int(*raw_byte);
    return push_number(lua, byte_of(facts, number, first, offset));
}

NativeResult push_mission_name(lua_State* lua, std::int32_t mission) {
    std::array<char, 32> text{};
    const auto written = std::format_to_n(text.data(), text.size() - 1, "Mission:{}", mission);
    lua_pushlstring(lua, text.data(), static_cast<std::size_t>(written.size));
    return 1;
}

// DataPool:GetPlayerMission_Name(ô) (0x1402cf6b0): "Mission:<id nhiệm vụ>", khóa tra tên trong
// bảng chữ. Ô ngoài 0..19 gốc không đẩy gì mà vẫn trả 1, nên Lua nhận giá trị trên cùng là chính
// chỉ số vừa truyền.
NativeResult get_mission_name(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMission_Name");
    const quest::Slot* slot = slot_at(native::context_of(lua).facts, slot_number(*raw));
    if (slot == nullptr) return 1;
    return push_mission_name(lua, slot->mission);
}

// DataPool:IsMissionTrackOpen(ô) (0x1402d3dd0): cờ MissionVar_<script> của ô; chưa có khoá thì
// mở (kể cả ô trống, script -1). Ô ngoài biên là 0.
NativeResult is_mission_track_open(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:IsMissionTrackOpen");
    const Context& context = native::context_of(lua);
    const quest::Slot* slot = slot_at(context.facts, slot_number(*raw));
    if (slot == nullptr) return push_number(lua, 0);
    const bool is_open = mission_track_open(context.variables, slot->script);
    return push_number(lua, is_open ? 1 : 0);
}

// DataPool:SetMissionTrackOpen(ô, giá trị) (0x1402d3e70): ghi cờ, bật khi giá trị > 0.
NativeResult set_mission_track_open(lua_State* lua) {
    const std::optional<double> raw_slot = native::strict_number(lua, 2);
    const std::optional<double> raw_value = native::strict_number(lua, 3);
    if (!raw_slot || !raw_value) return bad_param("LUA:SetMissionTrackOpen");
    Context& context = native::context_of(lua);
    const quest::Slot* slot = slot_at(context.facts, slot_number(*raw_slot));
    if (slot == nullptr) return 0;
    set_mission_track_open(context.variables, slot->script, native::to_int(*raw_value) > 0);
    return 0;
}

// DataPool:IsTrackFuncShow(khung) (0x1402d3f20): khung 1 (nhiệm vụ) mặc định bật, khung 2 (hoạt
// động) mặc định tắt; số khác là 0.
NativeResult is_track_func_show(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:IsTrackFuncShow");
    const VariableSystem& variables = native::context_of(lua).variables;
    const std::int32_t frame = native::to_int(*raw);
    bool is_shown = false;
    if (frame == 1) is_shown = stored_flag(variables, kStateMissions, true);
    if (frame == 2) is_shown = stored_flag(variables, kStateCampaigns, false);
    return push_number(lua, is_shown ? 1 : 0);
}

// DataPool:SetTrackFuncShow(khung, giá trị) (0x1402d3fc0): ghi State_1 hay State_2, bật khi giá trị
// > 0.
NativeResult set_track_func_show(lua_State* lua) {
    const std::optional<double> raw_frame = native::strict_number(lua, 2);
    const std::optional<double> raw_value = native::strict_number(lua, 3);
    if (!raw_frame || !raw_value) return bad_param("LUA:SetTrackFuncShow");
    VariableSystem& variables = native::context_of(lua).variables;
    const std::int32_t frame = native::to_int(*raw_frame);
    const bool is_on = native::to_int(*raw_value) > 0;
    if (frame == 1) store_flag(variables, kStateMissions, is_on);
    if (frame == 2) store_flag(variables, kStateCampaigns, is_on);
    return 0;
}

// ---- Bản ghi định nghĩa nhiệm vụ (bước 2) ----
// Mọi getter dưới đây chọn bản ghi của script trong ô (DAT_141035cd8 = FUN_1401dc970(script),
// Context::mission_cursor) rồi đọc một trường; các hàm không nhận ô (StrList, Custom, RandomCustom,
// Bonus_*) đọc bản ghi đã chọn. Bản ghi chỉ có dữ liệu sau khi GetPlayerMission_Description nạp tệp
// event của script, trước đó là bản ghi mặc định (-1 hết) như gốc.

// Bản ghi mặc định cho lúc Facts::mission_defs chưa đặt hay chưa getter nào chọn.
const quest::MissionDef kFreshDef{};
// Dải id script của nhiệm vụ ngẫu nhiên theo cấp (0xf6950, 10000 id) mà Demand_Num kiểm.
constexpr std::uint32_t kLevelMissionBase = 1010000;
constexpr std::uint32_t kMissionSpan = 10000;
// Chỉ thị tham số "ngẫu nhiên" của ô: giá trị tham số shimen_index để Demand_Num coi là loại 6,
// DemandKill_Num là loại 9.
constexpr std::int32_t kItemParamMark = 6;
constexpr std::int32_t kKillParamMark = 9;
// Số trả cho "loại ngẫu nhiên" của Demand_Num khi nhiệm vụ cấp trả đủ (0x1402ceb2a): -100.
constexpr double kLevelMissionType = -100;
// Lời lỗi khi chỉ số ngoài danh sách (gốc đọc ngoài vector) và khi dữ liệu client chưa có.
constexpr std::string_view kNoStrItem = "LUA:GetPlayerMissionStrList Empty Event String";
constexpr std::string_view kNoCustom = "LUA:GetPlayerMissionCustom Empty Event Custom";
constexpr std::string_view kNoRandomCustom = "LUA:GetPlayerMissionCustom Empty Event RandomCustom";
constexpr std::string_view kNoBonus = "LUA:GetMissionDemand_Item Empty Event Item";
constexpr std::string_view kNoDemandItem = "LUA:GetPlayerMissionDemand_Item Empty Event Item";
constexpr std::string_view kRandomTables =
    "LUA:GetPlayerMissionDemand_Item: bảng tham số ngẫu nhiên chưa dựng (docs/NGHI-NGO.md 76)";
constexpr std::string_view kNoMonsterNames =
    "LUA:GetPlayerMissionDemand_NPC: chưa có bảng tên quái (docs/NGHI-NGO.md 86)";

[[nodiscard]] const quest::MissionDef& def_of(const Facts& facts, std::int32_t script) {
    if (facts.mission_defs == nullptr) return kFreshDef;
    return facts.mission_defs->find(script);
}

[[nodiscard]] const quest::MissionDef& cursor_of(const Context& context) noexcept {
    if (context.mission_cursor == nullptr) return kFreshDef;
    return *context.mission_cursor;
}

// FUN_1401dc970 cho ô number: ô ngoài 0..19 không đổi con trỏ và trả nullptr.
[[nodiscard]] const quest::MissionDef* aim_at(Context& context, std::uint32_t number) {
    const quest::Slot* slot = slot_at(context.facts, number);
    if (slot == nullptr) return nullptr;
    context.mission_cursor = &def_of(context.facts, slot->script);
    return context.mission_cursor;
}

// Chỉ số pos nằm trong danh sách size phần tử không (gốc không kiểm, đọc ngoài vector).
[[nodiscard]] bool has_index(std::int32_t pos, std::size_t size) noexcept {
    return std::cmp_less(pos, size);
}

[[nodiscard]] std::string_view item_name_of(const Facts& facts, std::int32_t item) noexcept {
    if (facts.items == nullptr) return {};
    return facts.items->name(item);
}

using IntField = std::int32_t quest::MissionDef::*;

// Số nguyên ở đầu bản ghi (Level +4, Kind +8, IsElite +0xc, ForePart +0x58); ô ngoài biên là 0.
NativeResult push_def_number(lua_State* lua, std::string_view label, IntField field) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param(label);
    const quest::MissionDef* def = aim_at(native::context_of(lua), slot_number(*raw));
    if (def == nullptr) return push_number(lua, 0);
    const auto value = static_cast<double>(def->*field);
    return push_number(lua, value);
}

// DataPool:GetPlayerMission_Level(ô) (0x1402d1000).
NativeResult get_level(lua_State* lua) {
    return push_def_number(lua, "LUA:GetPlayerMission_Level", &quest::MissionDef::level);
}

// DataPool:GetPlayerMission_Kind(ô) (0x1402d10a0).
NativeResult get_kind(lua_State* lua) {
    return push_def_number(lua, "LUA:GetPlayerMission_Kind", &quest::MissionDef::kind);
}

// DataPool:GetPlayerMission_IsElite(ô) (0x1402d1140); câu lỗi của gốc chép từ Level.
NativeResult get_is_elite(lua_State* lua) {
    return push_def_number(lua, "LUA:GetPlayerMission_Level", &quest::MissionDef::elite);
}

// DataPool:GetPlayerMission_ForePart(ô) (0x1402d11e0).
NativeResult get_fore_part(lua_State* lua) {
    return push_def_number(lua, "LUA:GetPlayerMission_ForePart", &quest::MissionDef::fore_part);
}

// Trường dương thì đọc ra, ngược lại số mặc định của cột (cmp edi, 1; jge ở 0x1402d01b7 và
// 0x1402d01fc).
[[nodiscard]] double positive_or(std::int32_t value, std::int32_t otherwise) noexcept {
    const std::int32_t shown = value >= 1 ? value : otherwise;
    return static_cast<double>(shown);
}

// Cột 1..8 của GetPlayerMission_Display (bảng nhảy 0x1402d0248): ok_fail +0x48, limit_time +0x4c,
// round +0x50, bill +0x54, circumstance +0x10, double_exp +0x14, id script, id nhiệm vụ; cột khác
// là 0.
[[nodiscard]] double display_of(const quest::Slot& slot, const quest::MissionDef& def,
    std::int32_t column) noexcept {
    switch (column) {
    case 1: return positive_or(def.ok_fail, 0);
    case 2: return positive_or(def.limit_time, 0);
    case 3: return positive_or(def.round, -1);
    case 4: return positive_or(def.bill, 0);
    case 5: return positive_or(def.circumstance, 0);
    case 6: return positive_or(def.double_exp, -1);
    case 7: return positive_or(slot.script, -1);
    case 8: return static_cast<double>(slot.mission);
    default: return 0;
    }
}

// DataPool:GetPlayerMission_Display(ô, cột) (0x1402d00f0).
NativeResult get_display(lua_State* lua) {
    const std::optional<double> raw_slot = native::strict_number(lua, 2);
    const std::optional<double> raw_column = native::strict_number(lua, 3);
    if (!raw_slot || !raw_column) return bad_param("LUA:GetPlayerMission_Display");
    Context& context = native::context_of(lua);
    const std::uint32_t number = slot_number(*raw_slot);
    const quest::MissionDef* def = aim_at(context, number);
    if (def == nullptr) return push_number(lua, 0);
    const quest::Slot* slot = slot_at(context.facts, number);
    const std::int32_t column = native::to_int(*raw_column);
    return push_number(lua, display_of(*slot, *def, column));
}

// DataPool:GetPlayerMission_Description(ô) (0x1402cdbc0): nạp tệp event của script trong ô nếu chưa
// nạp rồi chọn bản ghi. Khác gốc: gốc còn dựng một chuỗi mô tả (tên, mục tiêu, vật phẩm cần,
// thưởng) và đẩy nó; QuestLog.lua và MissionTrack.lua vứt giá trị đó nên ở đây đẩy chuỗi rỗng. Gốc
// cũng điền toạ độ và tên NPC từ bảng NPC nhiệm vụ cho vài id đặc biệt (NGHI-NGO 86); chưa làm.
NativeResult get_description(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMission_Description 1");
    Context& context = native::context_of(lua);
    const std::uint32_t number = slot_number(*raw);
    const quest::Slot* slot = slot_at(context.facts, number);
    const bool is_loadable = slot != nullptr && context.facts.mission_defs != nullptr;
    if (is_loadable) context.facts.mission_defs->load(slot->script);
    static_cast<void>(aim_at(context, number));
    lua_pushstring(lua, "");
    return 1;
}

// DataPool:GetPlayerMission_Info(ô) (0x1402cf830): chuỗi hằng của gốc.
NativeResult get_info(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return bad_param("LUA:GetPlayerMission_Info");
    lua_pushstring(lua, "mission_info");
    return 1;
}

NativeResult push_text(lua_State* lua, std::string_view text) {
    lua_pushlstring(lua, text.data(), text.size());
    return 1;
}

// DataPool:GetPlayerMission_BillName(ô) (0x1402cf780): tên đơn vị tiền (g_BillName); ô ngoài biên
// là số 0. Câu lỗi của gốc chép từ GetMissionDemand_Item.
NativeResult get_bill_name(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetMissionDemand_Item");
    const quest::MissionDef* def = aim_at(native::context_of(lua), slot_number(*raw));
    if (def == nullptr) return push_number(lua, 0);
    return push_text(lua, def->bill_name);
}

// DataPool:GetPlayerMission_StrList(chỉ số) (0x1402d13d0): chuỗi thứ chỉ số của g_StrList của bản
// ghi đã chọn và một số. Khác gốc: số thứ hai là int chưa khởi tạo trên ngăn xếp của gốc
// (0x1401e3fd0 chép 4 byte sau chuỗi); ở đây luôn 0. Chỉ số ngoài danh sách gốc đọc bộ nhớ ngoài
// vector; ở đây là lỗi.
NativeResult get_str_list(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionStrList");
    const quest::MissionDef& def = cursor_of(native::context_of(lua));
    const std::int32_t pos = native::to_int(*raw);
    if (!has_index(pos, def.str_list.size())) return bad_param(kNoStrItem);
    const std::string& text = def.str_list.at(static_cast<std::size_t>(pos));
    lua_pushlstring(lua, text.data(), text.size());
    lua_pushnumber(lua, 0);
    return 2;
}

// DataPool:GetPlayerMissionCustom_Num(ô) (0x1402cf0e0) và GetPlayerMissionRandomCustom_Num(ô)
// (0x1402cf9b0): số mục tiêu tuỳ biến của bản ghi; ô ngoài biên là 0.
NativeResult push_def_count(lua_State* lua, std::string_view label, bool is_random) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param(label);
    const quest::MissionDef* def = aim_at(native::context_of(lua), slot_number(*raw));
    if (def == nullptr) return push_number(lua, 0);
    const std::size_t count = is_random ? def->random_customs.size() : def->customs.size();
    return push_number(lua, static_cast<double>(count));
}

NativeResult get_custom_num(lua_State* lua) {
    return push_def_count(lua, "LUA:GetPlayerMissionCustom_Num", false);
}

NativeResult get_random_custom_num(lua_State* lua) {
    return push_def_count(lua, "LUA:GetPlayerMissionRandomCustom_Num", true);
}

// DataPool:GetPlayerMissionCustom(chỉ số) (0x1402cf1b0): (chữ, số cần) của mục tiêu tuỳ biến thứ
// chỉ số. Khác gốc: chỉ số ngoài danh sách là lỗi (gốc đọc ngoài vector).
NativeResult get_custom(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionCustom");
    const quest::MissionDef& def = cursor_of(native::context_of(lua));
    const std::int32_t pos = native::to_int(*raw);
    if (!has_index(pos, def.customs.size())) return bad_param(kNoCustom);
    const quest::Counted& entry = def.customs.at(static_cast<std::size_t>(pos));
    lua_pushlstring(lua, entry.text.data(), entry.text.size());
    lua_pushnumber(lua, static_cast<double>(entry.count));
    return 2;
}

// DataPool:GetPlayerMissionRandomCustom(chỉ số, ô) (0x1402cfa80): (chữ, giá trị tham số thứ nhất,
// thứ hai) của ô. Đối số thứ ba không kiểm kiểu (lua_tonumber trả 0 cho giá trị không phải số).
NativeResult get_random_custom(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionCustom");
    const std::optional<double> raw_slot = native::strict_number(lua, 3);
    const Context& context = native::context_of(lua);
    const quest::MissionDef& def = cursor_of(context);
    const std::int32_t pos = native::to_int(*raw);
    if (!has_index(pos, def.random_customs.size())) return bad_param(kNoRandomCustom);
    const quest::RandomCounted& entry = def.random_customs.at(static_cast<std::size_t>(pos));
    const std::uint32_t number = slot_number(raw_slot.value_or(0));
    const auto first_param = static_cast<std::uint32_t>(entry.first);
    const auto second_param = static_cast<std::uint32_t>(entry.second);
    const double first = param_of(context.facts, number, first_param);
    const double second = param_of(context.facts, number, second_param);
    lua_pushlstring(lua, entry.text.data(), entry.text.size());
    lua_pushnumber(lua, first);
    lua_pushnumber(lua, second);
    return 3;
}

// DataPool:GetPlayerMissionBonus_Num() (0x1402cf270): số dòng thưởng của bản ghi đã chọn.
NativeResult get_bonus_num(lua_State* lua) {
    const quest::MissionDef& def = cursor_of(native::context_of(lua));
    return push_number(lua, static_cast<double>(def.bonuses.size()));
}

// Chữ loại thưởng của gốc (0x1402cf2c0): kind 0..5.
[[nodiscard]] std::string_view bonus_label(quest::BonusKind kind) noexcept {
    switch (kind) {
    case quest::BonusKind::kMoney: return "money";
    case quest::BonusKind::kMoneyJz: return "moneyjz";
    case quest::BonusKind::kItem: return "item";
    case quest::BonusKind::kItemRandom: return "itemrand";
    case quest::BonusKind::kItemRadio: return "itemradio";
    case quest::BonusKind::kExp: return "exp";
    }
    return {};
}

// Hai số sau chữ loại: tiền thì (0, số tiền), kinh nghiệm thì (số, 0), vật phẩm thì (id, số lượng);
// số lượng vật phẩm gốc đọc một byte (movzx ở 0x1402cf3ea).
[[nodiscard]] std::pair<double, double> bonus_numbers(const quest::Bonus& bonus) noexcept {
    const auto amount = static_cast<double>(bonus.value);
    if (bonus.kind == quest::BonusKind::kExp) return {amount, 0};
    const bool is_gold = bonus.kind == quest::BonusKind::kMoney;
    const bool is_note = bonus.kind == quest::BonusKind::kMoneyJz;
    if (is_gold || is_note) return {0, amount};
    const auto count = static_cast<double>(static_cast<std::uint8_t>(bonus.value));
    return {static_cast<double>(bonus.item), count};
}

// DataPool:GetPlayerMissionBonus_Item(chỉ số) (0x1402cf2c0): (loại, số thứ nhất, số thứ hai) của
// dòng thưởng. Khác gốc: chỉ số ngoài danh sách là lỗi (gốc đọc ngoài vector).
NativeResult get_bonus_item(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetMissionContinue_Bonus");
    const quest::MissionDef& def = cursor_of(native::context_of(lua));
    const std::int32_t pos = native::to_int(*raw);
    if (!has_index(pos, def.bonuses.size())) return bad_param(kNoBonus);
    const quest::Bonus& bonus = def.bonuses.at(static_cast<std::size_t>(pos));
    const std::string_view label = bonus_label(bonus.kind);
    const auto [first, second] = bonus_numbers(bonus);
    lua_pushlstring(lua, label.data(), label.size());
    lua_pushnumber(lua, first);
    lua_pushnumber(lua, second);
    return 3;
}

// Đẩy hai số (số lượng, loại ngẫu nhiên).
NativeResult push_pair(lua_State* lua, double count, double kind) {
    lua_pushnumber(lua, count);
    lua_pushnumber(lua, kind);
    return 2;
}

// Tham số shimen_index của bản ghi chỉ ra ô tham số báo "loại" của nhiệm vụ; -1 là luôn dùng. Trả
// true khi nhiệm vụ không thuộc loại mark (Demand_Num: 6, DemandKill_Num: 9) và vì vậy không có yêu
// cầu.
[[nodiscard]] bool lacks_mark(const quest::MissionDef& def, const quest::Slot& slot,
    std::int32_t mark) {
    if (def.shimen_index == -1) return false;
    const auto param = static_cast<std::uint32_t>(def.shimen_index);
    if (param >= quest::kParamCount) return true;
    return static_cast<std::int32_t>(slot.params.at(param)) != mark;
}

// Nhiệm vụ cấp trả đủ: id script trong dải 0xf6950, ok_fail dương và tham số 0 của ô dương
// (0x1402ceafc..0x1402ceb0e).
[[nodiscard]] bool is_level_mission(const quest::MissionDef& def,
    const quest::Slot& slot) noexcept {
    const auto offset = static_cast<std::uint32_t>(slot.script) - kLevelMissionBase;
    const bool is_ranged = offset < kMissionSpan;
    const bool is_paid = def.ok_fail > 0 && static_cast<std::int32_t>(slot.params.at(0)) > 0;
    return is_ranged && is_paid;
}

// DataPool:GetPlayerMissionDemand_Num(ô) (0x1402cea10): (số vật phẩm cần, loại ngẫu nhiên). Loại:
// -1 nhiệm vụ không thuộc loại 6; -100 nhiệm vụ cấp trả đủ; 0 thường. Gốc còn xét ba bảng tham số
// ngẫu nhiên (0x1a0, 0x1d0, 0x200 của bản ghi, loại 1, 2, 3) mà g_Parameter_* dựng; chưa dựng
// (NGHI-NGO 76) nên chúng luôn rỗng.
NativeResult get_demand_num(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetMissionDemand_Item");
    Context& context = native::context_of(lua);
    const std::uint32_t number = slot_number(*raw);
    const quest::MissionDef* def = aim_at(context, number);
    if (def == nullptr) return push_pair(lua, 0, 0);
    const quest::Slot* slot = slot_at(context.facts, number);
    if (lacks_mark(*def, *slot, kItemParamMark)) return push_pair(lua, 0, -1);
    const double count = static_cast<double>(def->demand_items.size());
    if (count == 0) return push_pair(lua, 0, 0);
    const double kind = is_level_mission(*def, *slot) ? kLevelMissionType : 0;
    return push_pair(lua, count, kind);
}

// DataPool:GetPlayerMissionDemandKill_Num(ô) (0x1402d0980): (số loại quái cần, loại ngẫu nhiên); ba
// bảng ngẫu nhiên (0x188, 0x1b8, 0x1e8) như Demand_Num chưa dựng. Không có loại nào thì (0, -1).
NativeResult get_demand_kill_num(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionDemandKill_Num");
    Context& context = native::context_of(lua);
    const std::uint32_t number = slot_number(*raw);
    const quest::MissionDef* def = aim_at(context, number);
    if (def == nullptr) return push_pair(lua, 0, 0);
    const quest::Slot* slot = slot_at(context.facts, number);
    if (lacks_mark(*def, *slot, kKillParamMark)) return push_pair(lua, 0, 0);
    const double count = static_cast<double>(def->demand_kills.size());
    if (count == 0) return push_pair(lua, 0, -1);
    return push_pair(lua, count, 0);
}

// Ba đối số số nghiêm của Demand_Item và Demand_NPC (chỉ số, loại ngẫu nhiên, ô); nullopt khi một
// đối số không phải số.
struct DemandArgs {
    std::int32_t pos = 0;
    std::int32_t kind = 0;
    std::uint32_t number = 0;
};

[[nodiscard]] std::optional<DemandArgs> demand_args(lua_State* lua) {
    const std::optional<double> raw_pos = native::strict_number(lua, 2);
    const std::optional<double> raw_kind = native::strict_number(lua, 3);
    const std::optional<double> raw_slot = native::strict_number(lua, 4);
    const bool is_valid = raw_pos && raw_kind && raw_slot;
    if (!is_valid) return std::nullopt;
    DemandArgs args;
    args.pos = native::to_int(*raw_pos);
    args.kind = native::to_int(*raw_kind);
    args.number = slot_number(*raw_slot);
    return args;
}

// DataPool:GetPlayerMissionDemand_Item(chỉ số, loại, ô) (0x1402cec40): (tên, id, số lượng) của vật
// phẩm cần. Loại 0 đọc danh sách cố định của bản ghi; số lượng gốc đọc một byte. Loại 1..3 đọc ba
// bảng ngẫu nhiên chưa dựng (NGHI-NGO 76). Khác gốc: chỉ số ngoài danh sách là lỗi; tên lấy ở
// Facts::items lúc dùng (gốc giữ đối tượng vật phẩm).
NativeResult get_demand_item(lua_State* lua) {
    const std::optional<DemandArgs> args = demand_args(lua);
    if (!args) return bad_param("LUA:GetPlayerMissionDemand_Item");
    const Context& context = native::context_of(lua);
    if (args->kind != 0) return bad_param(kRandomTables);
    const quest::MissionDef& def = cursor_of(context);
    if (!has_index(args->pos, def.demand_items.size())) return bad_param(kNoDemandItem);
    const quest::ItemCount& entry = def.demand_items.at(static_cast<std::size_t>(args->pos));
    const std::string_view name = item_name_of(context.facts, entry.item);
    const auto count = static_cast<std::uint8_t>(entry.count);
    lua_pushlstring(lua, name.data(), name.size());
    lua_pushnumber(lua, static_cast<double>(entry.item));
    lua_pushnumber(lua, static_cast<double>(count));
    return 3;
}

// DataPool:GetPlayerMissionDemand_NPC(chỉ số, loại, ô) (0x1402d0be0): (tên quái, số lượng). Gốc giữ
// tên đã tra ở bảng quái (MonsterAttrEx) ngay lúc đọc tệp event; client này chưa xuất bảng đó
// (NGHI-NGO 86) nên chưa trả được tên.
NativeResult get_demand_npc(lua_State* lua) {
    const std::optional<DemandArgs> args = demand_args(lua);
    if (!args) return bad_param("LUA:GetPlayerMissionDemand_NPC");
    return bad_param(kNoMonsterNames);
}

// DataPool:GetMissionInfo_Kind(loại) (0x1402cd330): tên loại nhiệm vụ; loại ngoài 0..199 gốc đẩy số
// 0. Khác gốc: loại trong 0..199 mà bảng không có dòng trả chuỗi rỗng (gốc ném "index error").
NativeResult get_info_kind(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetMissionInfo_Kind arg error");
    const std::int32_t kind = native::to_int(*raw);
    if (static_cast<std::uint32_t>(kind) >= quest::kKindCount) return push_number(lua, 0);
    const Context& context = native::context_of(lua);
    return push_text(lua, quest::kind_title(context.facts.mission_kinds, kind));
}

// DataPool:EnumPlayerMission_ItemAction(id vật phẩm) (0x1402d0540): id hành động của vật phẩm
// thưởng. Khác gốc: client chưa có hệ hành động (native_a_vcall.cpp), nên như gốc khi không tìm
// thấy hành động: không đẩy gì và trả 0 giá trị.
NativeResult enum_item_action(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return bad_param("LUA:EnumPlayerMission_ItemAction");
    return 0;
}

// DataPool:GetPlayerMission_DataRound(chỉ số) (0x1402d05d0): ô thứ chỉ số của mảng dữ liệu nhiệm vụ
// (3932 số 32 bit, +0x53d của khối nhiệm vụ). Khác gốc: client chưa nhận mảng đó từ máy chủ
// (NGHI-NGO 86) nên mọi ô là 0, như mảng vừa dựng.
NativeResult get_data_round(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return bad_param("LUA:GetPlayerMission_DataRound");
    return push_number(lua, 0);
}

// DataPool:GetPlayerMission_ActivePos(ô) (0x1402e93c0) và GetPlayerMission_DelActivePos(ô)
// (0x1402e9590): chọn bản ghi rồi đặt hay xoá dấu toạ độ nhiệm vụ trên bản đồ. Khác gốc: client
// chưa có dấu bản đồ (NGHI-NGO 86), chỉ chọn bản ghi.
NativeResult select_active_pos(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMission_ActivePos");
    static_cast<void>(aim_at(native::context_of(lua), slot_number(*raw)));
    return 0;
}

using Built = std::expected<void, NativeError>;

// Lời lỗi của gốc khi tham số đọc ra ngoài danh sách chữ (0x1402d1490).
constexpr std::string_view kForePartRange = "nForePart>=0 && nForePart<MAX_MISSION_PARAM_NUM";

[[nodiscard]] std::unexpected<NativeError> fore_part_error() {
    return std::unexpected(NativeError::of(kForePartRange));
}

[[nodiscard]] std::unexpected<NativeError> str_range_error(std::int32_t id) {
    const auto err = NativeError::format("LUA...index is out of range...2[scriptID={}]", id);
    return std::unexpected(err);
}

[[nodiscard]] std::unexpected<NativeError> format_range_error(std::int32_t id) {
    const auto err = NativeError::format("LUA...index is out of range...1[scriptid={}]", id);
    return std::unexpected(err);
}

[[nodiscard]] std::unexpected<NativeError> memo_slot_error(std::uint32_t number) {
    const auto shown = static_cast<std::int32_t>(number);
    const auto err = NativeError::format("LUA::GetPlayerMission_Memo nIndex : [{}]", shown);
    return std::unexpected(err);
}

// Chuỗi g_StrList mà tham số param của ô trỏ tới, nối vào out.
[[nodiscard]] Built append_param_string(std::string& out, const quest::Slot& slot,
    const quest::MissionDef& def, std::uint32_t param) {
    if (param >= quest::kParamCount) return fore_part_error();
    const auto index = static_cast<std::int32_t>(slot.params.at(param));
    if (!has_index(index, def.str_list.size())) return str_range_error(slot.script);
    out += def.str_list.at(static_cast<std::size_t>(index));
    return {};
}

// Mẫu "%f" lấy từ g_FormatList theo tham số kế tiếp (0x1402d15d7..0x1402d1665); next tăng một.
[[nodiscard]] std::expected<std::string_view, NativeError> pick_format(const quest::Slot& slot,
    const quest::MissionDef& def, std::uint32_t& next) {
    if (next >= quest::kParamCount) return fore_part_error();
    const auto index = static_cast<std::int32_t>(slot.params.at(next));
    if (!has_index(index, def.format_list.size())) return format_range_error(slot.script);
    ++next;
    return std::string_view(def.format_list.at(static_cast<std::size_t>(index)));
}

// Một bước của vòng thay chỉ thị (0x1402d16b0): "%s" thành chuỗi g_StrList, ký tự khác chép nguyên.
// Trả số ký tự mẫu đã dùng.
[[nodiscard]] std::expected<std::size_t, NativeError> expand_one(std::string& out,
    std::string_view pattern, std::size_t pos, const quest::Slot& slot,
    const quest::MissionDef& def, std::uint32_t& next) {
    const bool is_string = pattern.substr(pos, 2) == "%s";
    if (!is_string) {
        out.push_back(pattern[pos]);
        return 1;
    }
    const Built added = append_param_string(out, slot, def, next);
    if (!added) return std::unexpected(added.error());
    ++next;
    return 2;
}

// Mục tiêu nhiệm vụ đã thay chỉ thị (hàm 0x1402d1490, nửa sau của GetPlayerMission_Memo): "%f" đứng
// một mình thì lấy mẫu từ g_FormatList theo tham số fore_part của ô, rồi "%s" lấy g_StrList theo
// tham số kế tiếp. Chỉ thị khác ("%i" vật phẩm,
// "%n" NPC, "%p" thú) gốc tra bảng vật phẩm, NPC, thú và tô màu; client chưa nối các bảng đó nên
// giữ nguyên chữ (NGHI-NGO 86). Khác gốc: gốc cắt mục tiêu ở 1023 byte và còn dịch tên qua từ điển
// ngoại ngữ khi bật chế độ dịch (0x140123c60).
[[nodiscard]] Built format_target(std::string& out, const quest::Slot& slot,
    const quest::MissionDef& def) {
    std::string_view pattern = def.target;
    auto next = static_cast<std::uint32_t>(def.fore_part);
    if (pattern == "%f") {
        const std::expected<std::string_view, NativeError> picked = pick_format(slot, def, next);
        if (!picked) return std::unexpected(picked.error());
        pattern = *picked;
    }
    std::size_t pos = 0;
    while (pos < pattern.size()) {
        const auto used = expand_one(out, pattern, pos, slot, def, next);
        if (!used) return std::unexpected(used.error());
        pos += *used;
    }
    return {};
}

// DataPool:GetPlayerMission_Memo(ô) (0x1402cf480): (tên nhiệm vụ g_MissionName, mục tiêu đã thay
// chỉ thị).
NativeResult get_memo(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMission_Memo IsInteger");
    Context& context = native::context_of(lua);
    const std::uint32_t number = slot_number(*raw);
    if (number >= quest::kSlotCount) return memo_slot_error(number);
    const quest::MissionDef* def = aim_at(context, number);
    const quest::Slot* slot = slot_at(context.facts, number);
    context.scratch.clear();
    const Built built = format_target(context.scratch, *slot, *def);
    if (!built) return std::unexpected(built.error());
    lua_pushlstring(lua, def->name.data(), def->name.size());
    lua_pushlstring(lua, context.scratch.data(), context.scratch.size());
    return 2;
}

// Khoảng id script (first, first + count) ứng với một loại theo dõi (chuỗi else-if của 0x1402d2120,
// sau các phép tra DBC).
struct TrackRule {
    std::uint32_t first;
    std::uint32_t count;
    std::int32_t type;
};

constexpr std::array<TrackRule, 39> kTrackRules = {{
    {0x100590, 10000, 6},
    {0xd9684, 1, 7},
    {0xd970e, 1, 8},
    {0xd96f4, 1, 8},
    {0xd9917, 1, 9},
    {0xd9918, 1, 10},
    {0xd99ba, 1, 11},
    {0xd9a50, 1, 12},
    {0xd9a67, 1, 13},
    {0xd9a51, 1, 14},
    {0xd9a68, 1, 15},
    {0xd9a52, 1, 16},
    {0xd9a69, 1, 17},
    {0xd9a53, 1, 18},
    {0xd9a6a, 1, 19},
    {0xd9a54, 1, 20},
    {0xd9a6b, 1, 21},
    {0xd9a6d, 1, 22},
    {0xd9a6e, 1, 23},
    {0xd9a6f, 1, 24},
    {0xd9a70, 1, 25},
    {0xd9a71, 1, 26},
    {0xd9a40, 6, 27},
    {0xd9b28, 1, 28},
    {0xd9de0, 1, 30},
    {0xd9e63, 4, 32},
    {0xd9ed3, 1, 33},
    {0xf3b7b, 1, 34},
    {0xf3bca, 1, 34},
    {0xf3b7c, 1, 35},
    {0xf3bcb, 1, 35},
    {0xf3b23, 1, 36},
    {0xf3c48, 1, 37},
    {0xf3db7, 1, 39},
    {0xf3eeb, 6, 40},
    {0xf3ecf, 1, 41},
    {0xda2a2, 1, 44},
    {0xdbbd9, 5, 45},
    {0xf3f17, 1, 42},
}};

// Mẫu bit của dải 0xf3ccf..0xf3ce3 thuộc loại 38 (0x1fdfc1) và các id lẻ loại 42, 43 của gốc.
[[nodiscard]] std::int32_t sparse_track_type(std::uint32_t id) noexcept {
    constexpr std::uint32_t kMaskFirst = 0xf3ccf;
    constexpr std::uint32_t kMaskBits = 0x1fdfc1;
    const std::uint32_t from_mask = id - kMaskFirst;
    if (from_mask < 0x15 && ((kMaskBits >> (from_mask & 0x1f)) & 1U) != 0U) return 38;
    const std::uint32_t from_pair = id - 0xf3f17;
    if ((from_pair & 0xfffffffdU) == 0) return 42;
    const std::uint32_t from_group = id - 0xf3fff;
    const bool is_group = (from_group & 0xfffffffaU) == 0 && id != 0xf4004;
    return is_group ? 43 : 0;
}

[[nodiscard]] std::int32_t ranged_track_type(std::uint32_t id) noexcept {
    for (const TrackRule& rule : kTrackRules) {
        if (id - rule.first < rule.count) return rule.type;
    }
    return sparse_track_type(id);
}

// Loại theo dõi của một script (0x1402d2120): 1 khi MissionTrack.txt có dòng; 2 nhiệm vụ theo cấp
// (dải 1010000); 3 dải 1000000; 4 dải 1030000 khi Mission_LootItem.txt có vật phẩm; rồi dải 1020000
// không loại, các id còn lại theo bảng quy tắc. Khác gốc: dải 1030000 luôn 0 vì client chưa xuất
// Mission_LootItem.txt (NGHI-NGO 86).
[[nodiscard]] std::int32_t track_type_of(const Facts& facts, std::int32_t script) {
    const auto* tracked = facts.track_texts;
    const bool is_tracked = tracked != nullptr && tracked->contains(script);
    if (is_tracked) return 1;
    const auto id = static_cast<std::uint32_t>(script);
    if (id - kLevelMissionBase < kMissionSpan) return 2;
    if (id - 1000000U < kMissionSpan) return 3;
    if (id - 1030000U < kMissionSpan) return 0;
    if (id - 1020000U < kMissionSpan) return 0;
    return ranged_track_type(id);
}

// DataPool:GetPlayerMissionTrackType(ô) (0x1402d2120).
NativeResult get_track_type(lua_State* lua) {
    const std::optional<double> raw = native::strict_number(lua, 2);
    if (!raw) return bad_param("LUA:GetPlayerMissionTrackType Param error");
    const Facts& facts = native::context_of(lua).facts;
    const quest::Slot* slot = slot_at(facts, slot_number(*raw));
    if (slot == nullptr) return push_number(lua, 0);
    return push_number(lua, track_type_of(facts, slot->script));
}

constexpr std::array<native::Entry, 36> kMission = {{
    {.name = "GetPlayerMission_Num", .function = &lua::adapt<get_mission_num>},
    {.name = "GetPlayerMission_InUse", .function = &lua::adapt<get_in_use>},
    {.name = "GetPlayerMissionIndexByID", .function = &lua::adapt<get_index_by_id>},
    {.name = "GetPlayerMission_Variable", .function = &lua::adapt<get_mission_variable>},
    {.name = "GetPlayerMission_VariableByByte", .function = &lua::adapt<get_variable_by_byte>},
    {.name = "GetPlayerMission_Name", .function = &lua::adapt<get_mission_name>},
    {.name = "IsMissionTrackOpen", .function = &lua::adapt<is_mission_track_open>},
    {.name = "SetMissionTrackOpen", .function = &lua::adapt<set_mission_track_open>},
    {.name = "IsTrackFuncShow", .function = &lua::adapt<is_track_func_show>},
    {.name = "SetTrackFuncShow", .function = &lua::adapt<set_track_func_show>},
    {.name = "GetPlayerMission_Level", .function = &lua::adapt<get_level>},
    {.name = "GetPlayerMission_Kind", .function = &lua::adapt<get_kind>},
    {.name = "GetPlayerMission_IsElite", .function = &lua::adapt<get_is_elite>},
    {.name = "GetPlayerMission_ForePart", .function = &lua::adapt<get_fore_part>},
    {.name = "GetPlayerMission_Display", .function = &lua::adapt<get_display>},
    {.name = "GetPlayerMission_Description", .function = &lua::adapt<get_description>},
    {.name = "GetPlayerMission_Info", .function = &lua::adapt<get_info>},
    {.name = "GetPlayerMission_BillName", .function = &lua::adapt<get_bill_name>},
    {.name = "GetPlayerMission_StrList", .function = &lua::adapt<get_str_list>},
    {.name = "GetPlayerMission_Memo", .function = &lua::adapt<get_memo>},
    {.name = "GetPlayerMissionCustom_Num", .function = &lua::adapt<get_custom_num>},
    {.name = "GetPlayerMissionRandomCustom_Num", .function = &lua::adapt<get_random_custom_num>},
    {.name = "GetPlayerMissionCustom", .function = &lua::adapt<get_custom>},
    {.name = "GetPlayerMissionRandomCustom", .function = &lua::adapt<get_random_custom>},
    {.name = "GetPlayerMissionBonus_Num", .function = &lua::adapt<get_bonus_num>},
    {.name = "GetPlayerMissionBonus_Item", .function = &lua::adapt<get_bonus_item>},
    {.name = "GetPlayerMissionDemand_Num", .function = &lua::adapt<get_demand_num>},
    {.name = "GetPlayerMissionDemandKill_Num", .function = &lua::adapt<get_demand_kill_num>},
    {.name = "GetPlayerMissionDemand_Item", .function = &lua::adapt<get_demand_item>},
    {.name = "GetPlayerMissionDemand_NPC", .function = &lua::adapt<get_demand_npc>},
    {.name = "GetMissionInfo_Kind", .function = &lua::adapt<get_info_kind>},
    {.name = "EnumPlayerMission_ItemAction", .function = &lua::adapt<enum_item_action>},
    {.name = "GetPlayerMission_DataRound", .function = &lua::adapt<get_data_round>},
    {.name = "GetPlayerMission_ActivePos", .function = &lua::adapt<select_active_pos>},
    {.name = "GetPlayerMission_DelActivePos", .function = &lua::adapt<select_active_pos>},
    {.name = "GetPlayerMissionTrackType", .function = &lua::adapt<get_track_type>},
}};

} // namespace

void register_mission(lua_State* lua) {
    native::register_table(lua, "DataPool", kMission);
}

} // namespace game::ui::script
