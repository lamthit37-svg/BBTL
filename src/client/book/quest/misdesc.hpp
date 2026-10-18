/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/book/quest/misdesc.hpp
 *  PHÂN HỆ   : Client / Sổ sách / Nhiệm vụ
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - MissionDef: bản ghi mà DataPool:GetPlayerMission_* của Game.exe đọc ra
 *    (dựng ở 0x1401e0d00, mặc định ở 0x1401e2710).
 *  - parse_misdesc đọc khối MisDesc của tệp Config/event như vòng 0x1402cdbc0
 *    (mảng tên 0x140b40fe0 và mảng hàm xử lý 0x140f15e80 cùng chỉ số, đã đối
 *    chiếu: NGHI-NGO 79). Logic thuần, không I/O. Chưa dựng sáu biến
 *    g_Parameter_* của nhiệm vụ ngẫu nhiên (NGHI-NGO 76).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::quest {

// Số kind của một dòng phần thưởng, đúng số gốc ghi vào bản ghi (0x1402cdbc0 in từng loại).
enum class BonusKind : std::uint8_t {
    kMoney = 0,
    kMoneyJz = 1,
    kItem = 2,
    kItemRandom = 3,
    kItemRadio = 4,
    kExp = 5,
};

struct Bonus {
    BonusKind kind = BonusKind::kMoney;
    // Số tiền, kinh nghiệm hoặc số lượng vật phẩm.
    // Khác gốc: gốc chỉ giữ byte thấp của số lượng vật phẩm; ở đây giữ nguyên số.
    std::int32_t value = 0;
    // Id vật phẩm của ba loại vật phẩm; 0 với tiền và kinh nghiệm.
    std::int32_t item = 0;
};

// Yêu cầu vật phẩm: {id=..., num=...}.
struct ItemCount {
    std::int32_t item = 0;
    std::int32_t count = 0;
};

// Yêu cầu giết quái: {id=..., num=...}. Gốc tra tên quái (bảng 0x6e) ngay lúc đọc và giữ cùng
// bản ghi; ở đây tra lúc dùng (Khác gốc: bảng quái tĩnh nên kết quả như nhau).
struct KillCount {
    std::int32_t creature = 0;
    std::int32_t count = 0;
};

// Mục tiêu tuỳ biến: {id="chữ", num=...}.
struct Counted {
    std::string text;
    std::int32_t count = 0;
};

// Mục tiêu tuỳ biến ngẫu nhiên: {id="chữ", số thứ nhất, số thứ hai}.
struct RandomCounted {
    std::string text;
    std::int32_t first = 0;
    std::int32_t second = 0;
};

// Dấu NPC: {key=..., npcIdIndex=...}.
struct NpcIndicator {
    std::int32_t key = 0;
    std::int32_t index = 0;
};

// Các trường theo thứ tự và offset của bản ghi gốc. -1 là "chưa khai" (mặc định của gốc).
struct MissionDef {
    std::int32_t level = -1;
    std::int32_t kind = -1;
    std::int32_t elite = -1;
    std::int32_t circumstance = -1;
    std::int32_t double_exp = -1;
    std::int32_t stopwatch_pause = -1;
    std::int32_t pos_x = -1;
    std::int32_t pos_z = -1;
    std::int32_t scene = -1;
    std::string npc_name;
    std::int32_t ok_fail = -1;
    std::int32_t limit_time = -1;
    std::int32_t round = -1;
    std::int32_t bill = -1;
    // Số tham số của ô nhiệm vụ đứng trước phần chữ nối (g_StrForePart), mặc định 4.
    std::int32_t fore_part = 4;
    std::int32_t shimen_index = -1;
    std::vector<Bonus> bonuses;
    std::vector<ItemCount> demand_items;
    std::vector<KillCount> demand_kills;
    std::vector<Counted> customs;
    std::vector<std::string> str_list;
    std::vector<std::string> format_list;
    std::vector<RandomCounted> random_customs;
    std::string name;
    std::string target;
    std::string state;
    std::string bill_name;
    std::vector<NpcIndicator> npc_indicators;
};

// Đọc khối MisDesc của một tệp script (UTF-8). Tệp không có khối thì trả bản ghi mặc định, như gốc
// (đánh dấu đã nạp mà không có gì). Lỗi: câu tiếng Việt kèm dòng gây lỗi; gốc ném ngoại lệ ở các
// chỗ đó và để bản ghi chưa đánh dấu đã nạp.
[[nodiscard]] std::expected<MissionDef, std::string> parse_misdesc(std::string_view file_text);

} // namespace game::quest
