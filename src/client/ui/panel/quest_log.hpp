// Bảng nhiệm vụ (QuestLog): thẻ "nhiệm vụ hiện tại" và thẻ "nhiệm vụ nhận được", danh sách theo
// loại gập mở được, ô mô tả, hai ô bật khung theo dõi và ba nút dưới bảng.
// Nguồn: Interface/QuestLog/QuestLog.lua của client 2026 (giải bằng TOOLS/content/lua_plain.py); mỗi
// hàm ở quest_log.cpp là bản dịch một hàm của script, ghi vào Widgets đúng những lời gọi script
// làm. tests/ui_quest_tests.cpp so trạng thái đó từng dòng với trạng thái script gốc để lại khi
// chạy trên LuaPlus.dll của client 2026 (TOOLS/port/lua_oracle.py, tests/golden/panel/).
// Hàm C++ mà script gọi (GetMissionOutlineNum, GetMissionInfo_Kind, IsTrackFuncShow...) là module
// quest, port từ mã máy Game.exe (docs/NHIEM-VU-VO-CONG-2026.md).
// Khác gốc: chưa hiện nhiệm vụ đang giữ (danh sách thẻ hiện tại, mô tả, mục tiêu, phần thưởng, bật
// tắt theo dõi từng nhiệm vụ, từ bỏ): sổ nhiệm vụ rỗng cho tới khi có máy chủ, và thông tin của
// nhiệm vụ đang giữ nằm trong script của máy chủ gốc (docs/NGHI-NGO.md); chưa có chỉ dẫn tân thủ
// (OpenFreshManGuideNew), đồng hồ kinh nghiệm nhân đôi và việc trả bảng về chỗ cũ khi đổi độ phân
// giải; TLCJ:IsInTLCJScene coi như 0 (chưa có cảnh đó).
#pragma once

#include "gui/strings.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "quest/track.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Cửa sổ gốc của bảng và nút của thanh menu chính mở nó.
inline constexpr std::string_view kQuestLogRoot = "QuestLog_Frame";
inline constexpr std::string_view kQuestLogList = "QuestLog_Listbox";

// Hai danh sách của bảng (CurList của script).
enum class QuestList : std::uint8_t { kHeld = 1, kOffers = 2 };

// Điều bảng đọc của game khi xử lý một sự kiện, thay Player và DataPool của script. Con trỏ và
// span mượn phải sống tới hết lời gọi.
struct QuestFacts {
    // Người chơi dưới mắt bộ lọc nhiệm vụ nhận được (cấp, môn phái, loại máy chủ).
    quest::Seeker seeker;
    // Player:GetData("IsXiaKe") == 1: người chơi thuộc đợt dẫn "hiệp khách hành", loại 153 mới hiện.
    bool is_wanderer = false;
    const quest::Log* log = nullptr;
    std::span<const quest::OutlineRow> outline;
    std::span<const quest::KindRow> kinds;
    // Trạng thái theo dõi; bảng đọc và ghi.
    quest::Tracking* tracking = nullptr;
    // Bản dịch của tên gốc trong bảng (loại, nhiệm vụ, NPC) theo khoá nguyên văn, và bảng tên cảnh;
    // nullptr hay chưa dịch thì hiện tên gốc.
    const gui::StringBook* words = nullptr;
    const gui::StringBook* scenes = nullptr;
};

// Trạng thái của bảng: cửa sổ đang giữ gì và các biến của script.
struct QuestLog {
    Widgets widgets;
    // this:IsVisible().
    bool is_shown = false;
    QuestList list = QuestList::kHeld;
    // First_Open: lần đầu dựng thẻ hiện tại thì chọn nhiệm vụ cuối.
    bool is_first_open = true;
    // Current_Select: ô nhiệm vụ đang chọn ở thẻ hiện tại; chưa gán lần nào thì rỗng.
    std::optional<std::int32_t> current_select;
    // HaveGetMissionNum: số nhiệm vụ đang giữ đã đếm ở lượt dựng danh sách gần nhất.
    std::int32_t held_count = 0;
    // MissionOutlineDeploy: loại nào của thẻ nhận được đang mở (ô kind - 1); lúc nạp mở hết.
    std::array<bool, quest::kKindCount> is_kind_open = all_open();
    quest::Offers offers;

    [[nodiscard]] static constexpr std::array<bool, quest::kKindCount> all_open() noexcept {
        std::array<bool, quest::kKindCount> open{};
        open.fill(true);
        return open;
    }
};

// Sự kiện TOGLE_MISSION (nút nhiệm vụ của thanh menu chính, phím tắt): dựng lại thẻ hiện tại rồi
// đảo trạng thái hiện của bảng, như nhánh đó của QuestLog_OnEvent.
void toggle_quest_log(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls);

// Người chơi nhấn trái lên cửa sổ window của bảng: chạy hàm mà layout nối vào nút đó (đóng, hai thẻ,
// hai ô theo dõi, lịch hoạt động, trợ giúp, từ bỏ, nút theo dõi). Cửa sổ khác không đổi gì.
void press_quest_log(QuestLog& panel, std::string_view window, const QuestFacts& facts, std::vector<Call>& calls);

// Người chơi nhấn mục mang id của danh sách (ItemSelectionChanged): gập mở một loại, hay hiện mô tả
// của một nhiệm vụ nhận được.
void pick_quest_item(QuestLog& panel, std::int32_t id, const QuestFacts& facts);

// Chép trạng thái của bảng sang deck khi bảng đang hiện.
void paint_quest_log(Deck& deck, const QuestLog& panel);

} // namespace game::ui::panel
