/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/npc_talk.hpp
 *  PHÂN HỆ   : UI / Panel / NpcTalk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hộp thoại NPC (cửa sổ Quest của client 2026): lời NPC, các lựa chọn, bảng
 *    nhiệm vụ nhận/nộp với phần thưởng, và máy trạng thái của phiên hội thoại
 *    phía client (đang mở, đang chờ máy chủ đáp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: Interface/Quest/Quest.lua và Quest.layout.xml của client 2026 (giải bằng TOOLS/content/lua_plain.py): tiêu đề là tên
// NPC màu #gFF0FA0, ba nút Continue/Accept/Refuse với chữ và trạng thái khoá theo từng chế độ (Quest_EventListUpdate,
// Quest_QuestInfoUpdate, Quest_MissionContinueUpdate), phần thưởng chia "固定奖励" và "完成任务后可选一个作为奖品".
// Khác gốc: client gốc đọc dữ liệu hộp thoại từ DataPool do gói tin cũ đổ vào; ở đây máy chủ gửi một DialogOpen đã dựng chữ
// (ui/panel/talk.hpp) nên bảng ghi thẳng các phần tử vào cửa sổ phức hợp. Phần thưởng vật phẩm hiện bằng chữ (tên và số lượng),
// chưa có ô action có icon vì client chưa có hệ vật phẩm; biểu tượng của lựa chọn theo chỉ số QuestButtonImage của look.
//
// Cách hỏng đã tính trước (CL-03):
//   máy chủ im sau một việc đã gửi -> sau kReplyTimeout bảng tự mở khoá (step_talk), người chơi bấm lại được.
//   DialogClosed của phiên cũ tới sau DialogOpen của phiên mới (thay hộp) -> bỏ, chỉ đóng khi đúng phiên đang mở.
//   bấm hai lần liền                -> lần hai bị bỏ khi đang chờ đáp, không gửi hai việc cho cùng một phiên.
//   nộp nhiệm vụ có nhóm thưởng chọn một mà chưa chọn -> không gửi, nhắc người chơi (như bản gốc).
//   chỉ số lựa chọn lạ               -> bỏ; máy chủ cũng kiểm lại (BadOption).
//   danh sách vượt trần của giao thức -> không xảy ra (giao thức giới hạn 16 dòng, 48 lựa chọn, 24 phần thưởng); bảng vẽ nguyên.
// Độ phức tạp: mỗi lần vẽ O(số dòng + lựa chọn + phần thưởng), trần đầu vào theo giao thức.

#pragma once

#include "ui/panel/deck.hpp"
#include "quest/log.hpp"
#include "ui/panel/talk.hpp"

#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::ui::panel {

// Các cửa sổ của layout Quest.
inline constexpr std::string_view kTalkRoot = "Quest_Frame";
inline constexpr std::string_view kTalkTitle = "Quest_Frame_Debug";
inline constexpr std::string_view kTalkDesc = "QuestGreeting_Desc";
inline constexpr std::string_view kTalkContinue = "Quest_Button_Continue";
inline constexpr std::string_view kTalkAccept = "Quest_Button_Accept";
inline constexpr std::string_view kTalkRefuse = "Quest_Button_Refuse";
inline constexpr std::string_view kTalkClose = "Quest_Close";

// Chỉ số lựa chọn từ kRewardBase trở lên là mục thưởng chọn một (kRewardBase + vị trí trong Dialog::bonuses), không phải
// Choice::index của máy chủ. Choice::index là u16 nên hai miền không giao nhau.
inline constexpr std::uint32_t kRewardBase = 0x10000;

// Hạn chờ máy chủ đáp một việc của hộp thoại trước khi bảng mở khoá.
inline constexpr std::chrono::milliseconds kReplyTimeout{3000};

// Tên vật phẩm theo mẫu (Table/items.tsv, cột id và name) cho phần thưởng và yêu cầu.
class ItemNames {
public:
    // Đọc cột id và name của bảng TSV (văn bản cả tệp). Bảng hỏng hay thiếu cột thì giữ bảng rỗng và trả false.
    bool load(std::string_view tsv_text);
    // Tên của mẫu; rỗng khi không có.
    [[nodiscard]] std::string_view name(std::int32_t item) const noexcept;
    [[nodiscard]] bool is_loaded() const noexcept { return is_loaded_; }

private:
    std::unordered_map<std::int32_t, std::string> names_;
    bool is_loaded_ = false;
};

struct NpcTalk {
    bool is_open = false;
    talk::Dialog dialog;
    // Mẫu vật phẩm đã chọn trong nhóm thưởng chọn một; -1 khi chưa chọn.
    std::int32_t reward = -1;
    // Đã gửi một việc và chờ máy chủ đáp bằng DialogOpen hay DialogClosed; từ lúc waiting_since.
    bool is_waiting = false;
    std::chrono::milliseconds waiting_since{0};
    // Việc chờ gửi lên máy chủ; Hud::take_says lấy đi.
    std::vector<talk::Say> says;
    // Lời nhắn cho người chơi (khung hệ thống) do bảng sinh ra; Hud lấy đi.
    std::vector<std::string> notices;
};

// Máy chủ mở hay thay hộp thoại: bảng hiện nội dung mới và mở khoá. Cùng phiên với hộp đang mở là cập nhật nội dung (giữ lựa
// chọn thưởng nếu mẫu đó còn trong danh sách mới).
void open_talk(NpcTalk& talk, talk::Dialog dialog);
// Máy chủ đóng phiên: bảng đóng khi đúng phiên đang mở; phiên khác (cũ hơn) thì bỏ. Lý do đáng nói thì ghi vào notices.
void close_talk(NpcTalk& talk, const talk::Closed& closed);
// Máy chủ từ chối một việc: mở khoá và nhắc người chơi.
void refuse_talk(NpcTalk& talk, talk::Refusal why);
// Đóng hộp ngay phía client (rời cảnh, mất phiên mạng) mà không gửi gì.
void drop_talk(NpcTalk& talk) noexcept;
// Thông báo của hệ nhiệm vụ thành dòng khung hệ thống (notices). Máy chủ gửi sẵn chữ thì dùng nguyên; không có thì phần thưởng
// (kinh nghiệm, tiền, vật phẩm) tự dựng từ số, các loại khác không có gì để nói nên bỏ.
void note_notice(NpcTalk& talk, const talk::Notice& notice, const ItemNames& items);
// Sổ nhiệm vụ máy chủ gửi thành sổ của client (quest::Log). Ô quá 20 và tham số quá 8 bị bỏ (giao thức đã chặn trần này).
[[nodiscard]] quest::Log log_of(const talk::Book& book);
// Nhịp mỗi khung: mở khoá khi chờ quá kReplyTimeout.
void step_talk(NpcTalk& talk, std::chrono::milliseconds clock) noexcept;
// Người chơi nhấn trái lên cửa sổ window của bảng (nút Accept, Continue, Refuse, Close).
void press_talk(NpcTalk& talk, std::string_view window, std::chrono::milliseconds clock);
// Người chơi nhấn dòng lựa chọn mang số index (Hub::option_at của kTalkDesc).
void pick_talk_option(NpcTalk& talk, std::uint32_t index, std::chrono::milliseconds clock);
// Chép bảng sang deck khi đang mở. title là tên NPC (rỗng thì để tiêu đề trống).
void paint_talk(Deck& deck, const NpcTalk& talk, std::string_view title, const ItemNames& items);

} // namespace game::ui::panel
