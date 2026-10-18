// DataPool:GetPlayerMission_* và hàm theo dõi nhiệm vụ (ui/script/native_mission). Chỉ giữ ca mà sai
// thì hỏng thầm so với mã máy Game.exe: thứ tự byte và dấu của tham số ô, chỉ số ngoài biên, mặc định
// của cờ State_n và MissionVar_<script>, nạp trễ bản ghi định nghĩa (Description), cột Display, dòng thưởng,
// mục tiêu tuỳ biến, Memo và loại theo dõi. Phần còn lại do E2E n1-tanthu chứng minh bằng ảnh.
#include "quest/defs.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "support/script_rig.hpp"
#include "ui/panel/npc_talk.hpp"
#include "ui/script/context.hpp"
#include "ui/script/mission_data.hpp"

#include "test.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <optional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

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
    context.expect(rig.eval("return DataPool:GetPlayerMission_Variable(0, 0, 1, 2)").contains("g_Parameter_"),
        "bảng 1 cần g_Parameter_* (NGHI-NGO 76) nên báo lỗi rõ thay vì số giả");
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

// Khối MisDesc dựng cho ca định nghĩa: mục tiêu "%s ... %s" lấy g_StrList theo tham số của ô, ba dòng
// thưởng (tiền, vật phẩm, kinh nghiệm), một mục tiêu tuỳ biến, một vật phẩm cần.
constexpr std::string_view kDefText =
    "--MisDescBegin\r\n"
    "x1_g_MissionKind = 13\r\n"
    "x1_g_MissionLevel = 5\r\n"
    "x1_g_IfMissionElite = 1\r\n"
    "x1_g_MissionName = \"初涉江湖\"\r\n"
    "x1_g_MissionTarget = \"找%s取%s\"\r\n"
    "x1_g_StrForePart = 0\r\n"
    "x1_g_StrList = {\"甲\",\"乙\"}\r\n"
    "x1_g_MoneyBonus = 100\r\n"
    "x1_g_ItemBonus = {{id=38002071,num=20}}\r\n"
    "x1_g_ExpBonus = 50\r\n"
    "x1_g_Custom = { {id=\"已找到\",num=1} }\r\n"
    "x1_g_DemandItem = {{id=10101001,num=3}}\r\n"
    "x1_g_IsMissionOkFail = 0\r\n"
    "--MisDescEnd\r\n";

quest::Log definition_log() {
    quest::Log log;
    log.slots.at(0) = {.mission = 1400, .script = 210262, .flags = 0, .params = {1, 0}};
    return log;
}

quest::DefBook definition_book() {
    const auto index = quest::parse_script_index("MGR_TXT\r\n210262=\\event\\dali\\a.lua\r\n");
    const auto reader = [](std::string_view path) -> std::optional<std::string> {
        if (path == "event/dali/a.lua") return std::string(kDefText);
        return std::nullopt;
    };
    return quest::DefBook(*index, reader);
}

void definition_loads_on_description(Context& context) {
    const quest::Log log = definition_log();
    quest::DefBook book = definition_book();
    ui::script::Context script;
    script.facts.missions = &log;
    script.facts.mission_defs = &book;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Trước Description bản ghi là bản vừa dựng (-1 hết), như gốc: getter không tự nạp tệp.
    context.expect(rig.eval("return DataPool:GetPlayerMission_Kind(0)") == "-1", "chưa nạp: loại -1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Level(0)") == "-1", "chưa nạp: cấp -1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Description(0)") == "", "Description vứt chuỗi");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Kind(0)") == "13", "loại sau khi nạp");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Level(0)") == "5", "cấp sau khi nạp");
    context.expect(rig.eval("return DataPool:GetPlayerMission_IsElite(0)") == "1", "tinh anh");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Level(20)") == "0", "ô ngoài biên là 0");
    // Display: cột 7 và 8 là id script và id nhiệm vụ của ô; cột dương thì đọc, không thì số mặc định
    // của cột (cột 3 mặc định -1, cột 2 mặc định 0); cột lạ là 0.
    context.expect(rig.eval("return DataPool:GetPlayerMission_Display(0, 7)") == "210262", "cột id script");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Display(0, 8)") == "1400", "cột id nhiệm vụ");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Display(0, 2)") == "0", "thời hạn mặc định 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Display(0, 3)") == "-1", "vòng mặc định -1");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Display(0, 99)") == "0", "cột lạ là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Info(0)") == "mission_info", "chuỗi hằng");
    context.expect(book.take_notes().empty(), "nạp xong không có lỗi");
}

void definition_lists_and_bonuses(Context& context) {
    const quest::Log log = definition_log();
    quest::DefBook book = definition_book();
    ui::panel::ItemNames items;
    context.expect(items.load("id\tname\n10101001\t铜钱袋\n"), "bảng vật phẩm thử nạp được");
    ui::script::Context script;
    script.facts.missions = &log;
    script.facts.mission_defs = &book;
    script.facts.items = &items;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    static_cast<void>(rig.eval("return DataPool:GetPlayerMission_Description(0)"));
    context.expect(rig.eval("return DataPool:GetPlayerMissionBonus_Num()") == "3", "ba dòng thưởng");
    const std::string triple = " local a, b, c = DataPool:GetPlayerMissionBonus_Item(";
    context.expect(rig.eval(triple + "0) return a..','..b..','..c") == "money,0,100", "tiền: (0, số tiền)");
    context.expect(rig.eval(triple + "1) return a..','..b..','..c") == "item,38002071,20", "vật phẩm: (id, số lượng)");
    context.expect(rig.eval(triple + "2) return a..','..b..','..c") == "exp,50,0", "kinh nghiệm: (số, 0)");
    context.expect(rig.eval("return DataPool:GetPlayerMissionBonus_Item(3)").contains("LỖI"),
        "chỉ số ngoài danh sách là lỗi (gốc đọc ngoài vector)");
    context.expect(rig.eval("return DataPool:GetPlayerMissionCustom_Num(0)") == "1", "một mục tiêu tuỳ biến");
    context.expect(rig.eval("local a, b = DataPool:GetPlayerMissionCustom(0) return a..','..b") == "已找到,1",
        "mục tiêu tuỳ biến: (chữ, số cần)");
    context.expect(rig.eval("local a, b = DataPool:GetPlayerMission_StrList(1) return a..','..b") == "乙,0",
        "g_StrList chỉ số 1 kèm số 0");
    context.expect(rig.eval("return DataPool:GetPlayerMission_StrList(2)").contains("LỖI"),
        "chỉ số ngoài g_StrList là lỗi");
    context.expect(rig.eval("local a, b = DataPool:GetPlayerMissionDemand_Num(0) return a..','..b") == "1,0",
        "một vật phẩm cần, loại thường");
    const std::string demand = "local n, id, c = DataPool:GetPlayerMissionDemand_Item(0, 0, 0) return n..','..id..','..c";
    context.expect(rig.eval(demand) == "铜钱袋,10101001,3", "vật phẩm cần: (tên từ bảng vật phẩm, id, số lượng)");
    context.expect(rig.eval("return DataPool:GetPlayerMissionDemand_Item(0, 1, 0)").contains("LỖI"),
        "loại ngẫu nhiên cần g_Parameter_* nên báo lỗi rõ");
    context.expect(rig.eval("local a, b = DataPool:GetPlayerMissionDemandKill_Num(0) return a..','..b") == "0,-1",
        "không có yêu cầu giết quái");
}

void memo_expands_string_directives(Context& context) {
    const quest::Log log = definition_log();
    quest::DefBook book = definition_book();
    ui::script::Context script;
    script.facts.missions = &log;
    script.facts.mission_defs = &book;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    static_cast<void>(rig.eval("return DataPool:GetPlayerMission_Description(0)"));
    // "%s" thứ nhất lấy g_StrList[params[fore_part=0]] = [1] "乙", "%s" thứ hai lấy params[1] = [0] "甲".
    context.expect(rig.eval("local n, m = DataPool:GetPlayerMission_Memo(0) return n..'|'..m") == "初涉江湖|找乙取甲",
        "Memo: tên nhiệm vụ và mục tiêu đã thay %s");
    context.expect(rig.eval("return DataPool:GetPlayerMission_Memo(20)").contains("nIndex : [20]"),
        "ô ngoài biên báo đúng câu lỗi của gốc");
}

void track_type_follows_the_script_ranges(Context& context) {
    quest::Log log;
    log.slots.at(0) = {.mission = 1400, .script = 210262};
    log.slots.at(1) = {.mission = 11, .script = 0xd9684};
    log.slots.at(2) = {.mission = 12, .script = 1010005};
    log.slots.at(3) = {.mission = 13, .script = 1000001};
    log.slots.at(4) = {.mission = 14, .script = 0xf3ccf};
    log.slots.at(5) = {.mission = 15, .script = 0xd9a45};
    log.slots.at(6) = {.mission = 16, .script = 0xf4000};
    log.slots.at(7) = {.mission = 17, .script = 0xf4004};
    const std::map<std::int32_t, std::string> tracked = {{210262, "x"}};
    ui::script::Context script;
    script.facts.missions = &log;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(0)") == "0", "id thường không có dòng theo dõi");
    script.facts.track_texts = &tracked;
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(0)") == "1", "có dòng trong MissionTrack.txt");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(1)") == "7", "0xd9684: loại 7");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(2)") == "2", "dải nhiệm vụ theo cấp");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(3)") == "3", "dải 1000000");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(4)") == "38", "mẫu bit 0x1fdfc1");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(5)") == "27", "dải sáu id 0xd9a40: loại 27");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(6)") == "43", "nhóm 0xf3fff: loại 43");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(7)") == "0", "0xf4004 bị loại khỏi nhóm");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(19)") == "0", "ô trống là 0");
    context.expect(rig.eval("return DataPool:GetPlayerMissionTrackType(20)") == "0", "ô ngoài biên là 0");
}

void info_kind_reads_the_table(Context& context) {
    const std::vector<quest::KindRow> kinds = {{.id = 13, .name = "新手"}, {.id = 14, .name = "门派"}};
    ui::script::Context script;
    script.facts.mission_kinds = kinds;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return DataPool:GetMissionInfo_Kind(13)") == "新手", "tên loại 13");
    context.expect(rig.eval("return DataPool:GetMissionInfo_Kind(15)") == "", "loại không có dòng: rỗng");
    context.expect(rig.eval("return DataPool:GetMissionInfo_Kind(200)") == "0", "loại ngoài 0..199 đẩy số 0");
}

void write_file(const std::filesystem::path& path, std::string_view text) {
    std::filesystem::create_directories(path.parent_path());
    std::ofstream out(path, std::ios::binary);
    out << text;
}

void mission_data_reads_staged_files(Context& context) {
    const std::filesystem::path root = std::filesystem::temp_directory_path() / "thienlong_mission_data";
    std::filesystem::remove_all(root);
    const auto missing = ui::script::open_mission_data(root);
    context.expect(!missing.has_value(), "thiếu Script.dat là lỗi có lời");
    // Script.dat theo dạng client: tiêu đề, CRLF, dấu gạch ngược và một đường thoát khỏi Script/Config.
    write_file(root / "Script/Config/Script.dat",
        "MGR_TXT\r\n210262=\\event\\dali\\a.lua\r\n666=\\..\\evil.lua\r\n");
    write_file(root / "Script/Config/event/dali/a.lua", kDefText);
    write_file(root / "Script/evil.lua", kDefText);
    const auto no_track = ui::script::open_mission_data(root);
    context.expect(!no_track.has_value(), "thiếu mission_track.tsv là lỗi có lời");
    write_file(root / "Table/mission_track.tsv",
        "id\ttext\ttext_translated\n530\t去桃花岛\t\n531\t找到\t\n");
    auto opened = ui::script::open_mission_data(root);
    context.expect(opened.has_value(), "đọc được dữ liệu đã chép");
    if (opened) {
        opened->defs.load(210262);
        opened->defs.load(666);
        context.expect(opened->defs.find(210262).kind == 13, "tệp event đọc theo đường dẫn của Script.dat");
        context.expect(opened->defs.find(666).kind == -1, "đường dẫn có '..' bị chặn, không thoát Script/Config");
        context.expect(opened->defs.take_notes().size() == 1, "chỉ đường dẫn lạ để lại ghi chú");
        context.expect(opened->track_texts.size() == 2 && opened->track_texts.at(530) == "去桃花岛", "chữ theo dõi");
    }
    const auto bad_id = ui::script::parse_track_texts("id\ttext\nabc\tx\n");
    context.expect(!bad_id.has_value(), "id không phải số là lỗi");
    std::filesystem::remove_all(root);
}

constexpr std::array<Case, 9> kCases = {{
    {.name = "ô: lỗi chỉ số và tên theo mã máy", .body = slots_report_use_index_and_name},
    {.name = "tham số và byte của ô", .body = variables_read_params_and_bytes},
    {.name = "cờ theo dõi: mặc định và ghi", .body = track_flags_default_and_persist},
    {.name = "định nghĩa nạp trễ ở Description, cột Display", .body = definition_loads_on_description},
    {.name = "danh sách, thưởng, vật phẩm cần", .body = definition_lists_and_bonuses},
    {.name = "Memo thay %s theo tham số của ô", .body = memo_expands_string_directives},
    {.name = "loại theo dõi theo dải id script", .body = track_type_follows_the_script_ranges},
    {.name = "tên loại nhiệm vụ", .body = info_kind_reads_the_table},
    {.name = "kho định nghĩa đọc dữ liệu đã chép", .body = mission_data_reads_staged_files},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
