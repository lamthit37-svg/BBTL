// DataPool:GetPlayerMission_* và hàm theo dõi nhiệm vụ (ui/script/native_mission). Chỉ giữ ca mà sai
// thì hỏng thầm so với mã máy Game.exe: thứ tự byte và dấu của tham số ô, chỉ số ngoài biên, mặc định
// của cờ State_n và MissionVar_<script>. Phần còn lại do E2E n1-tanthu chứng minh bằng ảnh.
#include "quest/log.hpp"
#include "support/script_rig.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>

namespace game::test {
namespace {

quest::Log sample_log() {
    quest::Log log;
    log.slots.at(0) = {.mission = 1400, .script = 210262, .flags = 0, .params = {0x01020304, 7}};
    log.slots.at(3) = {.mission = 1403, .script = 210257, .flags = 1, .params = {0xFF000080}};
    return log;
}

void slots_report_use_index_and_name(Context& context) {
    const quest::Log log = sample_log();
    ui::script::Context script;
    script.facts.missions = &log;
    ScriptRig rig(script);
    context.expect(rig.ok(), "mở được máy Lua");
    if (!rig.ok()) return;
    // Ba ca lệch so với mã máy gốc thì script vẫn chạy mà hỏng thầm: ô ngoài biên (0x1402cdae0 ném lỗi,
    // 0x1402cf6b0 trả lại chính chỉ số), khoá tên theo id nhiệm vụ chứ không theo id script.
    context.expect(rig.eval("return DataPool:GetPlayerMission_InUse(20)").contains("index[20]"),
        "ô 20 là lỗi chỉ số");
    context.expect(rig.eval("return DataPool:GetPlayerMission_InUse(-1)").contains("index[-1]"),
        "ô âm là lỗi chỉ số (so không dấu)");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Name(3)") == "Mission:1403",
        "tên theo id nhiệm vụ");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Name(25)") == "25",
        "ô ngoài biên trả lại chính chỉ số, như gốc không đẩy gì");
}

void variables_read_params_and_bytes(Context& context) {
    const quest::Log log = sample_log();
    ui::script::Context script;
    script.facts.missions = &log;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0)") == "16909060",
        "tham số 0 của ô 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 1)") == "7", "tham số 1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(3, 0)") == "-16777088",
        "tham số có bit cao là số âm như int32 của gốc");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 8)") == "0",
        "tham số ngoài biên là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(20, 0)") == "0",
        "ô ngoài biên là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0, 9, 1)") == "16909060",
        "bảng lạ đọc như hai đối số");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0, 1)") == "0",
        "có đối số bốn mà thiếu đối số năm là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0, 1, 'x')") == "0",
        "đối số năm không phải số là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0, 1, 2)").contains("LỖI"),
        "bảng 1 cần bản ghi định nghĩa nên báo lỗi rõ");
    // Byte 0 là byte cao nhất: 0x01020304 ra 1, 2, 3, 4; byte 4 sang tham số kế tiếp (byte cao của 7).
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 0)") == "1", "byte 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 1)") == "2", "byte 1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 2)") == "3", "byte 2");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 3)") == "4", "byte 3");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 4)") == "0",
        "byte 4 là byte cao của tham số 1 (7)");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 7)") == "7",
        "byte 7 là byte thấp của tham số 1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(3, 0, 0)") == "255",
        "dịch số học rồi lấy byte thấp cho ra 255 chứ không âm");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(3, 0, 3)") == "128", "byte 3");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, 32)") == "0",
        "byte ngoài tham số cuối là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_VariableByByte(0, 0, -1)") == "4",
        "byte -1: chia cắt về 0 nên vẫn tham số 0, dịch 32 bit bị che còn 0 nên ra byte thấp");
}

void track_flags_default_and_persist(Context& context) {
    const quest::Log log = sample_log();
    ui::script::Context script;
    script.facts.missions = &log;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return DataPool:IsTrackFuncShow(1)") == "1", "khung nhiệm vụ mặc định bật");
    context.expect(rig.eval("return DataPool:IsTrackFuncShow(2)") == "0", "khung hoạt động mặc định tắt");
    context.expect(rig.eval("return DataPool:IsTrackFuncShow(3)") == "0", "khung lạ là 0");
    static_cast<void>(rig.eval("DataPool:SetTrackFuncShow(1, 0) DataPool:SetTrackFuncShow(2, 5)"));
    context.expect(rig.eval("return DataPool:IsTrackFuncShow(1)") == "0", "tắt khung nhiệm vụ");
    context.expect(rig.eval("return DataPool:IsTrackFuncShow(2)") == "1", "giá trị dương bật khung hoạt động");
    context.expect(script.variables.get("State_1") == "0", "ghi vào biến State_1 như gốc");
    context.expect(script.variables.get("State_2") == "1", "ghi vào biến State_2 như gốc");
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(0)") == "1", "chưa có khoá thì mở");
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(1)") == "1", "ô trống cũng mở theo MissionVar_-1");
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(20)") == "0", "ô ngoài biên là 0");
    static_cast<void>(rig.eval("DataPool:SetMissionTrackOpen(0, 0)"));
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(0)") == "0", "đóng theo dõi ô 0");
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(3)") == "1", "ô khác không đổi");
    context.expect(script.variables.get("MissionVar_210262") == "0", "khoá theo id script, không theo ô");
    static_cast<void>(rig.eval("DataPool:SetMissionTrackOpen(0, 1)"));
    context.expect(rig.eval("return DataPool:IsMissionTrackOpen(0)") == "1", "mở lại");
    context.expect(script.calls.empty(), "ghi cờ theo dõi không phát việc nhờ game");
}

constexpr std::array<Case, 3> kCases = {{
    {.name = "ô: lỗi chỉ số và tên theo mã máy", .body = slots_report_use_index_and_name},
    {.name = "tham số và byte của ô", .body = variables_read_params_and_bytes},
    {.name = "cờ theo dõi: mặc định và ghi", .body = track_flags_default_and_persist},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
