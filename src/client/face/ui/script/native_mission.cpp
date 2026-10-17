/*==============================================================================
 *  THIENLONG  |  Hàm game về sổ nhiệm vụ cho script giao diện
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/native_mission.cpp
 *  PHÂN HỆ   : Client / Giao diện / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nhóm DataPool:GetPlayerMission_* và hàm theo dõi nhiệm vụ mà QuestLog.lua,
 *    MissionTrack.lua gọi; đọc sổ 20 ô từ Facts::missions (quest::Log).
 *  - Cờ theo dõi State_1, State_2, MissionVar_<script> nằm trong bảng biến như
 *    gốc (Game.exe 0x1406b7b20 ghi, 0x1406b7980 đọc, trả -1 khi chưa có).
 *  - Bước 1: hàm chỉ cần sổ ô. Hàm cần bản ghi định nghĩa nhiệm vụ (Level,
 *    Kind, Display, Variable bốn đối số...) chờ bước 2, ghi ở docs/NGHI-NGO.md.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "quest/log.hpp"
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
constexpr std::string_view kNeedsDefinition =
    "GetPlayerMission_Variable: chưa có bản ghi định nghĩa nhiệm vụ (docs/NGHI-NGO.md)";
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
// số thứ hai của ô (0 khi ngoài biên). Bốn đối số với bảng 1, 2, 3 đọc qua bản ghi định nghĩa nhiệm
// vụ (Khác gốc: chưa có, báo lỗi rõ thay vì trả số giả); bảng khác thì như hai đối số; đối số năm
// không phải số thì 0.
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
    return bad_param(kNeedsDefinition);
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

constexpr std::array<native::Entry, 10> kMission = {{
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
}};

} // namespace

void register_mission(lua_State* lua) {
    native::register_table(lua, "DataPool", kMission);
}

} // namespace game::ui::script
