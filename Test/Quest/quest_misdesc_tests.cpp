/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Quest/quest_misdesc_tests.cpp
 *  PHÂN HỆ   : Quest / Quest Misdesc Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc khối MisDesc (quest/misdesc). Chỉ giữ ca mà sai thì hỏng thầm so
 *    với mã máy Game.exe 0x1402cdbc0 và các hàm xử lý 0x1401d9330-0x1401dc6f0:
 *    khối thật của nhiệm vụ 1400, các quirk của máy trạng thái (dấu '-' khi
 *    quét chữ số, nháy thoát '\', khối nhiều dòng, dấu ',' trong tên), lỗi báo
 *    thay vì đọc lố, và cả kho Config/event phải đọc không lỗi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "quest/defs.hpp"
#include "quest/misdesc.hpp"

#include "io/file.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdio>
#include <filesystem>
#include <optional>
#include <print>
#include <set>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using quest::BonusKind;
using quest::MissionDef;

// Thư mục Config/event của cây nguồn; rỗng thì ca quét kho tự bỏ qua (thiết bị không thấy cây nguồn).
#ifdef GAME_EVENT_DIR
constexpr std::string_view kEventDir = GAME_EVENT_DIR;
#else
constexpr std::string_view kEventDir;
#endif

// Khối MisDesc của nhiệm vụ 1400 (Config/event/dali/edali_newquest_001.lua), byte nguyên văn.
constexpr std::string_view kNewbie =
    "--MisDescBegin\r\n"
    "x210262_g_ScriptId = 210262\r\n"
    "x210262_g_NextScriptId = 210255\r\n"
    "x210262_g_Position_X = 160\r\n"
    "x210262_g_Position_Z = 158\r\n"
    "x210262_g_SceneID = 2\r\n"
    "x210262_g_AccomplishNPC_Name = \"赵天师\"\r\n"
    "x210262_g_MissionId = 1400\r\n"
    "x210262_g_Name\t=\"赵天师\"\r\n"
    "x210262_g_MissionKind = 13\r\n"
    "x210262_g_MissionLevel = 1\r\n"
    "x210262_g_IfMissionElite = 0\r\n"
    "x210262_g_MissionName = \"初涉江湖\"\r\n"
    "x210262_g_MissionInfo = \"\"\r\n"
    "x210262_g_MissionTarget = \"#{XSRW_100111_1}\"\r\n"
    "x210262_g_MoneyBonus = 1\r\n"
    "x210262_g_ExpBonus = 50\r\n"
    "x210262_g_SignPost = {x = 160, z = 158, tip = \"赵天师\"}\r\n"
    "x210262_g_Custom\t= { {id=\"已找到赵天师\",num=1} }\r\n"
    "x210262_g_IsMissionOkFail = 0\t\t--变量的第0位\r\n"
    "--MisDescEnd\r\n";

// Dựng một tệp có khối MisDesc quanh phần thân.
std::string block_of(std::string_view body) {
    std::string text = "-- đầu tệp\r\nx1_g_MissionKind = 99\r\n--MisDescBegin\r\n";
    text += body;
    text += "\r\n--MisDescEnd\r\nx1_g_MissionKind = 98\r\n";
    return text;
}

void newbie_block_reads_like_the_original(Context& context) {
    const auto parsed = quest::parse_misdesc(kNewbie);
    context.expect(parsed.has_value(), "khối 1400 đọc được");
    if (!parsed) return;
    const MissionDef& def = *parsed;
    context.expect(def.name == "初涉江湖", "tên nhiệm vụ lấy từ g_MissionName, không phải g_Name");
    context.expect(def.target == "#{XSRW_100111_1}", "mục tiêu giữ nguyên khoá #{...}");
    context.expect(def.npc_name == "赵天师", "tên NPC trả nhiệm vụ");
    context.expect(def.kind == 13 && def.level == 1 && def.elite == 0, "loại, cấp, tinh anh");
    context.expect(def.scene == 2 && def.pos_x == 160 && def.pos_z == 158, "cảnh và toạ độ");
    context.expect(def.ok_fail == 1, "dòng g_IsMissionOkFail chỉ cần có mặt");
    context.expect(def.limit_time == -1 && def.round == -1, "biến không khai giữ mặc định -1");
    context.expect(def.fore_part == 4, "g_StrForePart mặc định 4");
    context.expect(def.bonuses.size() == 2, "hai dòng thưởng");
    if (def.bonuses.size() != 2) return;
    context.expect(def.bonuses[0].kind == BonusKind::kMoney && def.bonuses[0].value == 1, "tiền");
    context.expect(def.bonuses[1].kind == BonusKind::kExp && def.bonuses[1].value == 50, "kinh nghiệm");
    context.expect(def.customs.size() == 1, "một mục tiêu tuỳ biến");
    if (def.customs.size() != 1) return;
    context.expect(def.customs[0].text == "已找到赵天师" && def.customs[0].count == 1, "mục tiêu tuỳ biến");
}

void number_scans_keep_the_original_quirks(Context& context) {
    const std::string text = block_of(
        "x1_g_MissionLevel = -3\r\n"
        "x1_g_MissionKind = -3\r\n"
        "x1_g_MissionLimitTime = 15*60*1000 --15分钟\r\n"
        "x1_g_DemandKill ={{id=719,num=8}}\t\t--变量第1位\r\n"
        "x1_g_ItemBonus={{id=38002071,num=20},{id=33011011,num=1}}\r\n");
    const auto parsed = quest::parse_misdesc(text);
    context.expect(parsed.has_value(), "đọc được");
    if (!parsed) return;
    // g_MissionLevel quét tới chữ số đầu tiên nên bỏ dấu '-'; g_MissionKind gọi atoi ngay sau '='.
    context.expect(parsed->level == 3, "cấp: dấu '-' bị bỏ qua khi quét chữ số");
    context.expect(parsed->kind == -3, "loại: atoi giữ dấu");
    context.expect(parsed->limit_time == 900000, "thời hạn: tích các số cách nhau bằng '*'");
    context.expect(parsed->demand_kills.size() == 1, "một yêu cầu giết quái");
    if (parsed->demand_kills.size() == 1) {
        context.expect(parsed->demand_kills[0].creature == 719, "id quái là số thứ nhất");
        context.expect(parsed->demand_kills[0].count == 8, "số lượng là số thứ hai");
    }
    context.expect(parsed->bonuses.size() == 2, "hai vật phẩm thưởng");
    if (parsed->bonuses.size() == 2) {
        context.expect(parsed->bonuses[0].kind == BonusKind::kItem, "loại vật phẩm");
        context.expect(parsed->bonuses[0].item == 38002071, "id vật phẩm là số thứ nhất");
        context.expect(parsed->bonuses[1].value == 1, "số lượng vật phẩm thứ hai");
    }
}

void blocks_and_comments_follow_the_line_loop(Context& context) {
    // Dòng ngoài khối bị bỏ qua; "--" ở đầu dòng là chú thích, nhưng dòng thụt lề rồi mới "--" vẫn
    // được xét (gốc chỉ nhìn hai byte đầu).
    const std::string text = block_of(
        "--x1_g_MissionKind = 5\r\n"
        "\t--x1_g_MissionLevel = 7\r\n"
        "x1_g_StrList = {\"#{A}\",\r\n"
        "\"#{B}\", \"#{C}\"\r\n"
        "}\r\n"
        "x1_g_StrForePart = 2\r\n"
        "x1_g_FormatList = {\"a\\\"b\",\"%s\"}\r\n");
    const auto parsed = quest::parse_misdesc(text);
    context.expect(parsed.has_value(), "đọc được");
    if (!parsed) return;
    context.expect(parsed->kind == -1, "dòng chú thích và dòng ngoài khối không làm đổi loại");
    context.expect(parsed->level == 7, "dòng thụt lề rồi mới '--' vẫn được xét");
    context.expect(parsed->str_list.size() == 3, "g_StrList nối ba dòng, ba chuỗi");
    context.expect(parsed->fore_part == 2, "dòng sau khối nhiều dòng vẫn được xét");
    context.expect(parsed->format_list.size() == 2, "g_FormatList hai chuỗi");
    if (parsed->format_list.size() == 2) {
        context.expect(parsed->format_list[0] == "a\\\"b", "nháy sau '\\' không đóng chuỗi");
        context.expect(parsed->format_list[1] == "%s", "chuỗi thứ hai");
    }
}

void custom_machine_keeps_commas_and_digits_in_names(Context& context) {
    // Tên được lấy ngay lúc gặp nháy mở mà con trỏ không nhảy qua nháy đóng: ',' rồi chữ số nằm
    // trong tên làm máy sinh thêm một mục. Suy từ mã máy 0x1401dac00; không có dữ liệu thật nào
    // chạm tới, ca này giữ để ai sửa máy cho "đúng" thì thấy ngay.
    const std::string text = block_of("x1_g_Custom = { {id=\"a,5\",num=2} }");
    const auto parsed = quest::parse_misdesc(text);
    context.expect(parsed.has_value(), "đọc được");
    if (!parsed) return;
    context.expect(parsed->customs.size() == 2, "hai mục: số 5 trong tên rồi num=2");
    if (parsed->customs.size() != 2) return;
    context.expect(parsed->customs[0].count == 5 && parsed->customs[1].count == 2, "đếm 5 rồi 2");
}

void bill_is_a_flag_not_a_number(Context& context) {
    // g_Bill gọi atoi nhưng bỏ kết quả và đặt 1 (0x1401dae60); "g_Bill" nằm trong "g_BillName".
    const auto zero = quest::parse_misdesc(block_of("x1_g_Bill = 0"));
    context.expect(zero.has_value() && zero->bill == 1, "g_Bill = 0 vẫn đặt bill 1");
    const auto named = quest::parse_misdesc(block_of("x1_g_BillName = \"x\""));
    context.expect(named.has_value() && named->bill == 1, "dòng g_BillName cũng chạy g_Bill");
    if (named) context.expect(named->bill_name == "x", "g_BillName vẫn lấy tên");
}

void quote_machine_skips_the_char_after_the_closing_quote(Context& context) {
    // Sau nháy đóng gốc bỏ qua đúng một ký tự (0x1401daf90): '}' dính liền nháy đóng không đóng khối,
    // nên chuỗi "b" sau nó vẫn được lấy. Dòng đầu có '}' rồi còn nháy nên khối nối sang dòng sau.
    const auto parsed = quest::parse_misdesc(block_of("x1_g_StrList = {\"a\"},\"b\"}\r\n}"));
    context.expect(parsed.has_value(), "đọc được");
    if (!parsed) return;
    context.expect(parsed->str_list.size() == 2, "hai chuỗi: '}' ngay sau nháy đóng bị bỏ qua");
}

void malformed_lines_are_reported(Context& context) {
    context.expect(!quest::parse_misdesc(block_of("x1_g_MissionKind")).has_value(), "thiếu dấu =");
    context.expect(!quest::parse_misdesc(block_of("x1_g_MissionName = abc")).has_value(), "thiếu nháy");
    const std::string open_quote = block_of("x1_g_Custom = {{id=\"abc");
    context.expect(!quest::parse_misdesc(open_quote).has_value(), "g_Custom thiếu nháy đóng");
    const std::string open_list = block_of("x1_g_StrList = {\"a\",");
    context.expect(!quest::parse_misdesc(open_list).has_value(), "khối nhiều dòng không đóng");
    const auto none = quest::parse_misdesc("x1_g_MissionKind = 5\r\n");
    context.expect(none.has_value() && none->kind == -1, "tệp không có khối trả bản ghi mặc định");
}

void script_index_reads_like_the_loader(Context& context) {
    // Bộ nạp 0x1406865b0: bỏ mọi dòng tới "MGR_TXT" (không phân biệt hoa thường) và dòng ';', lấy số
    // trước '=' đầu tiên bằng atoi, id lặp thì dòng sau ghi đè, dòng không có '=' bị bỏ.
    const std::string text =
        "dòng trước tiêu đề bị bỏ\r\n"
        "mgr_txt\r\n"
        "\r\n"
        "; chú thích\r\n"
        "000012=\\obj\\luoyang\\a.lua\r\n"
        "\t210262=\\event\\dali\\edali_newquest_001.lua \r\n"
        "dòng không có dấu bằng\r\n"
        "7x=\\a\\b.lua\r\n"
        "210257=\\event\\dali\\old.lua\r\n"
        "210257=\\event\\dali\\new.lua\r\n";
    const auto index = quest::parse_script_index(text);
    context.expect(index.has_value(), "đọc được bảng có tiêu đề viết thường");
    if (!index) return;
    context.expect(index->size() == 4, "bốn id: dòng chữ và dòng không dấu bằng bị bỏ");
    context.expect(index->at(12) == "obj/luoyang/a.lua", "số 0 đầu bỏ, '\\' thành '/', bỏ '/' đầu");
    context.expect(index->at(210262) == "event/dali/edali_newquest_001.lua", "cắt tab đầu và dấu cách cuối");
    context.expect(index->at(7) == "a/b.lua", "atoi dừng ở chữ không phải số");
    context.expect(index->at(210257) == "event/dali/new.lua", "id lặp: dòng sau thắng");
    context.expect(!quest::parse_script_index("1=\\a.lua\r\n").has_value(), "thiếu MGR_TXT là lỗi");
}

void def_book_loads_on_demand(Context& context) {
    const auto index = quest::parse_script_index(
        "MGR_TXT\r\n210262=\\event\\dali\\a.lua\r\n5=\\event\\gone.lua\r\n6=\\event\\bad.lua\r\n");
    context.expect(index.has_value(), "bảng đọc được");
    if (!index) return;
    int reads = 0;
    const auto reader = [&reads](std::string_view path) -> std::optional<std::string> {
        ++reads;
        if (path == "event/dali/a.lua") return std::string(kNewbie);
        if (path == "event/bad.lua") return std::string("--MisDescBegin\r\nx1_g_MissionKind\r\n--MisDescEnd\r\n");
        return std::nullopt;
    };
    quest::DefBook book(*index, reader);
    context.expect(book.find(210262).kind == -1 && reads == 0, "chưa nạp: bản ghi mặc định, chưa đọc tệp");
    book.load(210262);
    book.load(210262);
    context.expect(reads == 1, "nạp một lần dù gọi hai lần");
    context.expect(book.find(210262).kind == 13 && book.find(210262).name == "初涉江湖", "sau nạp có dữ liệu");
    book.load(999);
    context.expect(reads == 1, "id không có trong bảng thì không đọc tệp");
    book.load(5);
    book.load(6);
    context.expect(book.find(5).kind == -1 && book.find(6).kind == -1, "tệp lỗi giữ bản ghi mặc định");
    const std::vector<std::string> notes = book.take_notes();
    context.expect(notes.size() == 3, "mỗi script lỗi một dòng ghi chú");
    context.expect(book.take_notes().empty(), "lấy ghi chú xong thì rỗng");
    context.expect(quest::DefBook().find(1).kind == -1, "kho rỗng vẫn trả bản ghi mặc định");
}

std::string lowered(std::string text) {
    for (char& letter : text) {
        if (letter >= 'A' && letter <= 'Z') letter = static_cast<char>(letter - 'A' + 'a');
    }
    return text;
}

// Số tệp .lua của cây event mà bảng không có dòng nào trỏ tới (so không phân biệt hoa thường, như Windows).
std::size_t count_unlisted(const quest::ScriptIndex& index, const std::filesystem::path& config) {
    std::set<std::string> listed;
    for (const auto& entry : index) listed.insert(lowered(entry.second));
    std::size_t unlisted = 0;
    const std::filesystem::path events = config / "event";
    for (const auto& entry : std::filesystem::recursive_directory_iterator(events)) {
        if (entry.path().extension() != ".lua") continue;
        const std::string relative = std::filesystem::relative(entry.path(), config).generic_string();
        if (listed.contains(lowered(relative))) continue;
        ++unlisted;
        std::println(stderr, "không có trong Script.dat: {}", relative);
    }
    return unlisted;
}

void shipped_index_matches_event_tree(Context& context) {
    if (kEventDir.empty()) return;
    const std::filesystem::path config = io::path_from_utf8(kEventDir).parent_path();
    const io::TextResult text = io::read_text(config / "Script.dat");
    context.expect(text.has_value(), "đọc được Config/Script.dat");
    if (!text) return;
    const auto index = quest::parse_script_index(*text);
    context.expect(index.has_value(), "Script.dat của client đọc được (CRLF)");
    if (!index) return;
    const auto found = index->find(210262);
    context.expect(found != index->end() && found->second == "event/dali/edali_newquest_001.lua",
        "id script của nhiệm vụ 1400");
    context.expect(count_unlisted(*index, config) == 0, "mọi tệp event của client có dòng trong Script.dat");
}

void whole_event_tree_parses(Context& context) {
    if (kEventDir.empty()) return;
    std::size_t blocks = 0;
    std::size_t bad = 0;
    for (const auto& entry : std::filesystem::recursive_directory_iterator(io::path_from_utf8(kEventDir))) {
        if (entry.path().extension() != ".lua") continue;
        const io::TextResult text = io::read_text(entry.path());
        if (!text) continue;
        if (!text->contains("MisDescBegin")) continue;
        ++blocks;
        const auto parsed = quest::parse_misdesc(*text);
        if (parsed) continue;
        ++bad;
        std::println(stderr, "{}: {}", entry.path().string(), parsed.error());
    }
    context.expect(blocks >= 1000, "thấy đủ tệp có khối MisDesc");
    context.expect(bad == 0, "mọi khối MisDesc của kho đọc không lỗi");
}

constexpr std::array<Case, 11> kCases = {{
    {.name = "khối 1400 đọc như gốc", .body = newbie_block_reads_like_the_original},
    {.name = "máy số giữ quirk của gốc", .body = number_scans_keep_the_original_quirks},
    {.name = "vòng dòng: khối, chú thích, khối nhiều dòng", .body = blocks_and_comments_follow_the_line_loop},
    {.name = "máy g_Custom giữ ',' và chữ số trong tên", .body = custom_machine_keeps_commas_and_digits_in_names},
    {.name = "g_Bill là cờ đặt 1, kể cả dòng g_BillName", .body = bill_is_a_flag_not_a_number},
    {.name = "máy chuỗi bỏ một ký tự sau nháy đóng", .body = quote_machine_skips_the_char_after_the_closing_quote},
    {.name = "dòng hỏng được báo", .body = malformed_lines_are_reported},
    {.name = "cả kho Config/event đọc không lỗi", .body = whole_event_tree_parses},
    {.name = "Script.dat: bộ nạp đọc như gốc", .body = script_index_reads_like_the_loader},
    {.name = "DefBook nạp trễ và ghi lỗi một lần", .body = def_book_loads_on_demand},
    {.name = "Script.dat của client khớp cây event", .body = shipped_index_matches_event_tree},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
