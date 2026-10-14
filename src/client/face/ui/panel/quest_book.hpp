// Sổ nhiệm vụ của màn chơi: bảng QuestLog (quest_log.hpp) cùng dữ liệu nó đọc (bảng nhiệm vụ nhận
// được, bảng loại, sổ nhiệm vụ đang giữ, trạng thái theo dõi) và việc đồng bộ với bàn các bảng
// (desk.hpp): nút Button_Mission của thanh menu là sự kiện TOGLE_MISSION, nút đóng và nút từ chối
// của bảng đóng cả thứ hạng của bàn.
// Nhấn trái lên một mục của QuestLog_Listbox là sự kiện ListBox_Click: id của mục (AddItem) đưa vào
// pick_quest_item. Khác gốc: sổ đang giữ rỗng cho tới khi có máy chủ; Call của bảng (mở khung theo dõi, lịch hoạt động,
// trợ giúp) trả cho người gọi, HUD chưa làm việc nào trong số đó.
#pragma once

#include "gui/strings.hpp"
#include "hero/hero.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "quest/track.hpp"
#include "table/tsv.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/desk.hpp"
#include "ui/panel/quest_log.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Nút của thanh menu chính mở sổ nhiệm vụ (kQuestLogRoot là cửa sổ gốc).
inline constexpr std::string_view kQuestLogOpener = "Button_Mission";

struct QuestBook {
    QuestLog panel;
    quest::Log log;
    quest::Tracking tracking;
    std::vector<quest::OutlineRow> outline;
    std::vector<quest::KindRow> kinds;
};

// Đọc Table/mission_outline.tsv và Table/mission_kinds.tsv đã phân tích. Lỗi là câu của bộ đọc
// bảng; khi lỗi book giữ nguyên.
[[nodiscard]] std::optional<std::string> load_quest_tables(
    QuestBook& book, const table::Tsv& outline, const table::Tsv& kinds);

// Người chơi dưới mắt bộ lọc: cấp và môn phái của nhân vật; chưa có nhân vật thì nhân vật mới.
[[nodiscard]] quest::Seeker seeker_of(const hero::Hero* hero) noexcept;

// Một lần nhấn trái lên cửa sổ window của màn chơi, sau press_desk. Nút mở đảo bảng; khi bảng đang
// hiện, nút của bảng chạy hàm của script. Sau cùng thứ hạng của bàn khớp với trạng thái hiện của
// bảng. Việc bảng nhờ ghi thêm vào calls.
void press_quest_book(QuestBook& book, Desk& desk, std::string_view window, const hero::Hero* hero,
    const gui::StringBook* scenes, std::vector<Call>& calls);

// Nhấn trái lên mục thứ row (Hub::list_item của kQuestLogList) khi bảng đang hiện: tra id của mục rồi
// pick_quest_item. Bảng ẩn hay row không ứng với mục nào thì không làm gì; trả true khi đã chọn.
bool pick_quest_row(
    QuestBook& book, std::size_t row, const hero::Hero* hero, const gui::StringBook* scenes);

// Kê bảng khi nó đang hiện.
void paint_quest_book(Deck& deck, const QuestBook& book);

} // namespace game::ui::panel