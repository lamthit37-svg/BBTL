#include "ui/panel/quest_log.hpp"

#include "gui/strings.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "quest/track.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::string_view kAmount = "QuestLog_Amount";
constexpr std::string_view kMissionsMode = "QuestLog_Mode1";
constexpr std::string_view kCampaignsMode = "QuestLog_Mode2";
constexpr std::string_view kHeldTab = "QuestLog_CurrentMission";
constexpr std::string_view kOffersTab = "QuestLog_AcceptMission";
// Hai thẻ là hai nút đánh dấu CheckMode 1 cùng cha: bật thẻ này thì thẻ kia tắt.
constexpr std::array<std::string_view, 2> kTabs = {kHeldTab, kOffersTab};
constexpr std::string_view kTarget = "QuestLog_TargetMission";
constexpr std::string_view kDesc = "QuestLog_Desc";
constexpr std::string_view kAccept = "QuestLog_AcceptMission_Button";
constexpr std::string_view kStop = "QuestLog_Stop";
constexpr std::string_view kRefuse = "QuestLog_Refuse";
constexpr std::string_view kClose = "QuestLog_Close";
constexpr std::string_view kCalendar = "QuestLog_huodongricheng";
constexpr std::string_view kHelp = "QuestLog_Help";

// Chữ của nút theo dõi: ở thẻ nhận được nó là nút đóng (khoá từ điển "Đóng"); ở thẻ hiện tại, khi
// không có nhiệm vụ theo dõi được thì là "不可追踪" của script.
constexpr std::string_view kCloseLabel = "#{INTERFACE_XML_301}";
constexpr std::string_view kCannotTrack = "不可追踪";
// Dấu gập mở và màu của dòng tên loại.
constexpr std::string_view kOpenKind = "#gFE7E82- ";
constexpr std::string_view kShutKind = "#gFE7E82+ ";
// Ba dòng mô tả của một nhiệm vụ nhận được ("任务所在地：", "任务发布人：", "任务等级：").
constexpr std::string_view kPlaceLabel = "任务所在地：";
constexpr std::string_view kGiverLabel = "任务发布人：";
constexpr std::string_view kLevelLabel = "任务等级：";
// Loại 153 chỉ hiện với người chơi của đợt dẫn "hiệp khách hành".
constexpr std::int32_t kWandererKind = 153;
// id của mục danh sách thẻ nhận được: loại x 10000 là dòng tên loại, cộng số thứ tự là nhiệm vụ.
constexpr std::int32_t kKindStride = 10000;
constexpr std::string_view kShownEvent = "ON_SHOWQUESTLOGWINDOW";
constexpr std::string_view kMissionsFrame = "MissionTrack";
constexpr std::string_view kCampaignsFrame = "CampaignTrack";
constexpr std::string_view kHelpTopic = "*QuestLog";

// Màu chữ của một nhiệm vụ theo hiệu cấp nhiệm vụ trừ cấp người chơi (nhánh IsClassic() == 1, giá
// trị duy nhất Game.exe 2026 trả): xám, lục, vàng, cam, đỏ.
[[nodiscard]] constexpr std::string_view level_colour(std::int64_t gap) noexcept {
    if (gap < -11) return "FFB9B9B9";
    if (gap <= -6) return "FF0A9605";
    if (gap <= 5) return "FFD9F80A";
    if (gap <= 10) return "FFF8A10A";
    return "FFFA0A0A";
}

// Bản dịch của một tên gốc theo khoá nguyên văn; chưa dịch thì chính tên gốc.
[[nodiscard]] std::string_view translated(const gui::StringBook* words, std::string_view text) noexcept {
    if (words == nullptr) return text;
    return words->find_literal(text).value_or(text);
}

// Tên cảnh đã dịch (bảng tên cảnh tra theo tên gốc).
[[nodiscard]] std::string_view scene_title(const gui::StringBook* scenes, std::string_view name) noexcept {
    if (scenes == nullptr) return name;
    return scenes->find(name).value_or(name);
}

void add_text(Widgets& widgets, std::string_view text) {
    widgets.add_element(kDesc, std::format("text\t{}", text));
}

// QuestLog_TrackButtonState: nút dưới phải là nút đóng ở thẻ nhận được; ở thẻ hiện tại nó bật tắt
// theo dõi của nhiệm vụ đang chọn, và không có nhiệm vụ theo dõi được thì khoá.
void refresh_track_button(QuestLog& panel) {
    if (panel.list != QuestList::kHeld) {
        panel.widgets.set_text(kRefuse, kCloseLabel);
        panel.widgets.enable(kRefuse);
        return;
    }
    panel.widgets.set_text(kRefuse, kCannotTrack);
    panel.widgets.disable(kRefuse);
}

// Nhánh thẻ hiện tại của QuestLog_ListBox_SelectChanged khi không giữ nhiệm vụ nào: ô mô tả và tên
// nhiệm vụ để trống.
void show_no_mission(QuestLog& panel) {
    panel.widgets.clear_elements(kDesc);
    panel.widgets.set_text(kTarget, "");
}

// QuestLog_UpdateListbox_Ex: dựng thẻ hiện tại.
void build_held_list(QuestLog& panel) {
    Widgets& widgets = panel.widgets;
    if (panel.list == QuestList::kOffers) {
        panel.list = QuestList::kHeld;
        widgets.check_one(kHeldTab, kTabs);
        widgets.show(kStop);
        widgets.hide(kAccept);
    }
    widgets.check_one(kHeldTab, kTabs);
    widgets.check(kOffersTab, false);
    widgets.clear_list(kQuestLogList);
    panel.held_count = 0;
    if (panel.is_first_open) {
        panel.is_first_open = false;
        panel.current_select = panel.held_count - 1;
    }
    if (panel.current_select) widgets.select_item(kQuestLogList, *panel.current_select);
    widgets.set_text(kAmount, std::format("{}/{}", panel.held_count, quest::kSlotCount));
    show_no_mission(panel);
    refresh_track_button(panel);
}

// Các nhiệm vụ của một loại đang mở: mỗi cái một mục "    <cấp> <tên>" tô theo hiệu cấp.
void add_offers(QuestLog& panel, const QuestFacts& facts, std::int32_t kind) {
    const std::int64_t own_level = quest::effective_level(facts.seeker);
    const auto count = static_cast<std::int32_t>(quest::offer_count(panel.offers, kind));
    for (std::int32_t number = 1; number <= count; ++number) {
        const quest::OfferAsk ask{.kind = kind, .number = number};
        const std::optional<quest::OfferView> view = quest::offer_at(facts.outline, panel.offers, facts.seeker, ask);
        if (!view) continue;
        ListItem item;
        item.text = std::format("    {} {}", view->level, translated(facts.words, view->name));
        item.id = (kind * kKindStride) + number;
        item.colour = level_colour(std::int64_t{view->level} - own_level);
        panel.widgets.add_item(kQuestLogList, std::move(item));
    }
}

// QuestLog_UpdateMissionType: dòng tên loại (kèm dấu gập mở) rồi các nhiệm vụ nếu loại đang mở;
// loại không có nhiệm vụ nhận được thì không có dòng nào.
void add_kind(QuestLog& panel, const QuestFacts& facts, std::int32_t kind) {
    if (quest::offer_count(panel.offers, kind) == 0) return;
    const bool is_open = panel.is_kind_open.at(static_cast<std::size_t>(kind) - 1);
    const std::string_view title = translated(facts.words, quest::kind_title(facts.kinds, kind));
    ListItem head;
    head.text = std::format("{}{}", is_open ? kOpenKind : kShutKind, title);
    head.id = kind * kKindStride;
    panel.widgets.add_item(kQuestLogList, std::move(head));
    if (is_open) add_offers(panel, facts, kind);
}

// QuestLog_UpdateMissionOutline: dựng thẻ nhận được, giữ chỗ cuộn của danh sách.
void build_offer_list(QuestLog& panel, const QuestFacts& facts) {
    Widgets& widgets = panel.widgets;
    if (panel.list == QuestList::kHeld) {
        panel.list = QuestList::kOffers;
        widgets.check_one(kOffersTab, kTabs);
        widgets.hide(kStop);
        widgets.hide(kAccept);
        widgets.set_text(kTarget, "");
    }
    const std::int32_t first = widgets.first_item(kQuestLogList);
    const quest::Log empty;
    quest::collect_offers(facts.outline, facts.seeker, facts.log == nullptr ? empty : *facts.log, panel.offers);
    widgets.clear_list(kQuestLogList);
    widgets.clear_elements(kDesc);
    for (std::int32_t kind = 1; std::cmp_less_equal(kind, quest::kKindCount); ++kind) {
        if (kind == kWandererKind && !facts.is_wanderer) continue;
        add_kind(panel, facts, kind);
    }
    widgets.set_first_item(kQuestLogList, first);
    refresh_track_button(panel);
}

// Mô tả của một nhiệm vụ nhận được: tên, nơi nhận kèm liên kết tự tìm đường tới NPC, người giao và
// cấp. Cảnh không có tên thì bỏ dòng nơi nhận.
void describe_offer(QuestLog& panel, const QuestFacts& facts, const quest::OfferView& view) {
    Widgets& widgets = panel.widgets;
    const std::string_view npc = translated(facts.words, view.npc);
    add_text(widgets, std::format("#Y{}#W", translated(facts.words, view.name)));
    const std::string aim = std::format("#{{_INFOAIM{},{},{},{}}}", view.x, view.z, view.scene, npc);
    const std::string_view scene = scene_title(facts.scenes, view.scene_name);
    if (!scene.empty()) add_text(widgets, std::format("{}{}  {}", kPlaceLabel, scene, aim));
    add_text(widgets, std::format("{}{}", kGiverLabel, npc));
    add_text(widgets, std::format("{}{}", kLevelLabel, view.level));
}

// QuestLog_MissionOutlineClicked: mục đang chọn là dòng tên loại (id chia hết cho 10000) thì gập
// hay mở loại đó; là nhiệm vụ thì hiện mô tả.
// Khác gốc: không có mục nào đang chọn, hay id không ứng với nhiệm vụ nào, thì chỉ xoá ô mô tả; mã
// gốc khi đó ghi ba dòng mang số chưa khởi tạo.
void offer_clicked(QuestLog& panel, const QuestFacts& facts) {
    const std::int32_t id = panel.widgets.selected_item(kQuestLogList);
    const bool is_listed = id >= kKindStride;
    const std::int32_t kind = is_listed ? id / kKindStride : 0;
    const std::int32_t number = is_listed ? id % kKindStride : 0;
    const bool is_kind = is_listed && number == 0 && std::cmp_less_equal(kind, quest::kKindCount);
    if (is_kind) {
        bool& is_open = panel.is_kind_open.at(static_cast<std::size_t>(kind) - 1);
        is_open = !is_open;
        build_offer_list(panel, facts);
    }
    panel.widgets.clear_elements(kDesc);
    if (is_kind) return;
    const quest::OfferAsk ask{.kind = kind, .number = number};
    const std::optional<quest::OfferView> view = quest::offer_at(facts.outline, panel.offers, facts.seeker, ask);
    if (view) describe_offer(panel, facts, *view);
}

// QuestLog_ShowWindow: đảo trạng thái hiện của bảng, đặt hai ô theo dõi theo trạng thái đã lưu.
void show_window(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    panel.is_shown = !panel.is_shown;
    const quest::Tracking none;
    const quest::Tracking& tracking = facts.tracking == nullptr ? none : *facts.tracking;
    panel.widgets.check(kMissionsMode, quest::is_frame_shown(tracking, quest::TrackFrame::kMissions));
    panel.widgets.check(kCampaignsMode, quest::is_frame_shown(tracking, quest::TrackFrame::kCampaigns));
    calls.push_back(Call{.ask = Ask::kPushEvent, .text = std::string(kShownEvent)});
}

// Một ô bật khung theo dõi và khung của nó.
struct ModeBox {
    std::string_view window;
    quest::TrackFrame frame = quest::TrackFrame::kMissions;
    std::string_view frame_window;
};

// QuestLog_MissionTrack_Clicked và QuestLog_CampaignTrack_Clicked: ô đánh dấu vừa bị bấm (CEGUI đảo
// dấu trước), mở hay đóng khung theo dõi tương ứng và lưu trạng thái.
void toggle_mode(QuestLog& panel, const ModeBox& box, const QuestFacts& facts, std::vector<Call>& calls) {
    const bool is_on = !panel.widgets.is_checked(box.window);
    panel.widgets.check(box.window, is_on);
    const Ask ask = is_on ? Ask::kOpenWindow : Ask::kCloseWindow;
    calls.push_back(Call{.ask = ask, .text = std::string(box.frame_window)});
    if (facts.tracking != nullptr) quest::show_frame(*facts.tracking, box.frame, is_on);
}

// QuestLog_TrackCancelOrOpen: ở thẻ nhận được nút này đóng bảng.
void press_refuse(QuestLog& panel) {
    if (panel.list != QuestList::kHeld) panel.is_shown = false;
}

} // namespace

void toggle_quest_log(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    build_held_list(panel);
    show_window(panel, facts, calls);
}

void press_quest_log(QuestLog& panel, std::string_view window, const QuestFacts& facts, std::vector<Call>& calls) {
    if (window == kClose) panel.is_shown = false;
    if (window == kRefuse) press_refuse(panel);
    if (window == kMissionsMode) {
        const ModeBox box{.window = kMissionsMode, .frame = quest::TrackFrame::kMissions, .frame_window = kMissionsFrame};
        toggle_mode(panel, box, facts, calls);
    }
    if (window == kCampaignsMode) {
        const ModeBox box{.window = kCampaignsMode, .frame = quest::TrackFrame::kCampaigns, .frame_window = kCampaignsFrame};
        toggle_mode(panel, box, facts, calls);
    }
    if (window == kHeldTab) {
        panel.widgets.check_one(kHeldTab, kTabs);
        build_held_list(panel);
    }
    if (window == kOffersTab) {
        panel.widgets.check_one(kOffersTab, kTabs);
        build_offer_list(panel, facts);
    }
    if (window == kCalendar) calls.push_back(Call{.ask = Ask::kOpenCampaignList, .text = {}});
    if (window == kHelp) calls.push_back(Call{.ask = Ask::kGotoHelper, .text = std::string(kHelpTopic)});
}

void pick_quest_item(QuestLog& panel, std::int32_t id, const QuestFacts& facts) {
    panel.widgets.pick_item(kQuestLogList, id);
    if (panel.list == QuestList::kOffers) {
        offer_clicked(panel, facts);
        return;
    }
    show_no_mission(panel);
}

void paint_quest_log(Deck& deck, const QuestLog& panel) {
    if (!panel.is_shown) return;
    panel.widgets.paint(deck);
}

} // namespace game::ui::panel
