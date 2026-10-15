/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/npc_talk.cpp
 *  PHÂN HỆ   : UI / Panel / NpcTalk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy trạng thái hộp thoại NPC phía client và việc đổ nội dung vào các cửa
 *    sổ của layout Quest (xem npc_talk.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/npc_talk.hpp"

#include "core/number.hpp"
#include "gui/content.hpp"
#include "gui/sheet.hpp"
#include "quest/log.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/talk.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <format>
#include <initializer_list>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

namespace tk = talk;

// Chữ cứng của bảng là chữ Trung gốc (chủ dự án chốt 2026-10-13).
constexpr std::string_view kTitleTint = "#gFF0FA0";
constexpr std::string_view kContinueText = "继续";
constexpr std::string_view kCompleteText = "完成";
constexpr std::string_view kGoodbyeText = "再见";
constexpr std::string_view kCancelText = "取消";
constexpr std::string_view kCloseText = "关闭";
constexpr std::string_view kFixedHeader = "#Y固定奖励:#W";
constexpr std::string_view kRadioHeader = "#Y完成任务后可选一个作为奖品:#W";
constexpr std::string_view kDemandHeader = "#Y所需物品:#W";
constexpr std::string_view kPickReward = "请选择奖励物品！";
constexpr std::string_view kChosen = "●";
constexpr std::string_view kUnchosen = "○";

// Chỉ số biểu tượng mặc định của một lựa chọn: chỉ số ngoài 1..34 (kể cả 0 "không có") về 8, như Quest_EventListUpdate.
constexpr std::int32_t kDefaultIcon = 8;
constexpr std::int32_t kLastIcon = 34;
// Chỉ số không ứng với ảnh nào của look: nút không có biểu tượng.
constexpr std::int32_t kNoIcon = -1;

[[nodiscard]] std::int32_t icon_of(std::int32_t icon) noexcept {
    return icon <= 0 || icon > kLastIcon ? kDefaultIcon : icon;
}

void request(NpcTalk& talk, talk::Say say, std::chrono::milliseconds clock) {
    talk.says.push_back(say);
    talk.is_waiting = true;
    talk.waiting_since = clock;
}

// Đóng hộp và báo máy chủ; không chờ đáp.
void hang_up(NpcTalk& talk) {
    if (!talk.is_open) return;
    talk.says.emplace_back(tk::Close{.session = talk.dialog.session});
    drop_talk(talk);
}

[[nodiscard]] bool has_radio(const tk::Dialog& dialog) noexcept {
    return std::ranges::any_of(dialog.bonuses, [](const tk::Bonus& bonus) { return bonus.kind == tk::BonusKind::kRadio; });
}

[[nodiscard]] bool offers_item(const tk::Dialog& dialog, std::int32_t item) noexcept {
    return std::ranges::any_of(dialog.bonuses, [item](const tk::Bonus& bonus) {
        return bonus.kind == tk::BonusKind::kRadio && bonus.a == item;
    });
}

void send_accept(NpcTalk& talk, std::chrono::milliseconds clock) {
    const tk::Dialog& dialog = talk.dialog;
    if (dialog.mode != tk::Mode::kMissionInfo || dialog.panel_quest < 0) return;
    request(talk, tk::Accept{.session = dialog.session, .quest = static_cast<std::uint16_t>(dialog.panel_quest)}, clock);
}

void send_turn_in(NpcTalk& talk, std::chrono::milliseconds clock) {
    const tk::Dialog& dialog = talk.dialog;
    if (dialog.mode != tk::Mode::kDemand || dialog.panel_quest < 0) return;
    if (has_radio(dialog) && talk.reward < 0) {
        talk.notices.emplace_back(kPickReward);
        return;
    }
    request(talk,
        tk::TurnIn{.session = dialog.session, .quest = static_cast<std::uint16_t>(dialog.panel_quest), .reward = talk.reward},
        clock);
}

[[nodiscard]] std::string_view refusal_text(tk::Refusal why) noexcept {
    switch (why) {
    case tk::Refusal::kTooFar: return "距离太远，无法对话。";
    case tk::Refusal::kQuestLogFull: return "任务栏已满，无法接受更多任务。";
    case tk::Refusal::kQuestUnavailable: return "无法接受该任务。";
    case tk::Refusal::kQuestState: return "任务状态不符，无法完成该操作。";
    case tk::Refusal::kBagFull: return "背包已满，请先整理背包。";
    case tk::Refusal::kNotEnoughMoney: return "金钱不足。";
    case tk::Refusal::kNotEnoughItems: return "所需物品不足。";
    case tk::Refusal::kCannotAbandon: return "该任务无法放弃。";
    case tk::Refusal::kRateLimited: return "操作过于频繁，请稍后再试。";
    case tk::Refusal::kNoSession:
    case tk::Refusal::kStaleSession:
    case tk::Refusal::kBadOption:
    case tk::Refusal::kNoSuchEntity:
    case tk::Refusal::kBadChoice:
    case tk::Refusal::kOther: break;
    }
    return {};
}

// Chữ nhắc khi máy chủ đóng hộp vì một lý do người chơi cần biết; rỗng với lý do bình thường.
[[nodiscard]] std::string_view closed_text(tk::Reason reason) noexcept {
    switch (reason) {
    case tk::Reason::kFar: return "距离太远，对话已结束。";
    case tk::Reason::kNpcGone: return "对方已经离开。";
    case tk::Reason::kExpired: return "对话已超时。";
    case tk::Reason::kDone:
    case tk::Reason::kSceneChanged:
    case tk::Reason::kReplaced:
    case tk::Reason::kDead:
    case tk::Reason::kClient: break;
    }
    return {};
}

// Bản ghi của thuộc tính Elements (gui/content.hpp): các trường cách nhau kFieldMark, các bản ghi cách nhau kRecordMark.
void add_record(std::string& blob, std::initializer_list<std::string_view> fields) {
    if (!blob.empty()) blob.push_back(gui::kRecordMark);
    bool is_first = true;
    for (const std::string_view field : fields) {
        if (!is_first) blob.push_back(gui::kFieldMark);
        blob.append(field);
        is_first = false;
    }
}

void add_text(std::string& blob, std::string_view text) {
    add_record(blob, {gui::kTextElement, text});
}

// Số thứ tự máy chủ chờ nhận lại và chỉ số biểu tượng của một dòng lựa chọn.
struct OptionMark {
    std::uint32_t index = 0;
    std::int32_t icon = kNoIcon;
};

void add_option(std::string& blob, std::string_view text, OptionMark mark) {
    const std::string number = std::to_string(mark.index);
    const std::string picture = std::to_string(mark.icon);
    add_record(blob, {gui::kOptionElement, text, number, picture});
}

[[nodiscard]] std::string item_line(const ItemNames& items, const tk::Bonus& bonus) {
    const std::string_view known = items.name(bonus.a);
    if (known.empty()) return std::format("物品{} x{}", bonus.a, bonus.b);
    return std::format("{} x{}", known, bonus.b);
}

// Một nhóm phần thưởng hay yêu cầu: tiêu đề hiện một lần khi gặp phần tử đầu của nhóm (như cờ nRadio_Necessary và nRadio
// của Quest_QuestInfoUpdate).
struct BonusFlow {
    bool has_fixed = false;
    bool has_radio = false;
    bool has_demand = false;
};

void add_bonus(std::string& blob, BonusFlow& flow, const tk::Dialog& dialog, std::size_t at, const NpcTalk& talk,
    const ItemNames& items) {
    const tk::Bonus& bonus = dialog.bonuses.at(at);
    if (bonus.kind == tk::BonusKind::kRadio) {
        if (!flow.has_radio) add_text(blob, kRadioHeader);
        flow.has_radio = true;
        const bool is_chosen = talk.reward == bonus.a;
        const std::string line = std::format("{} {}", is_chosen ? kChosen : kUnchosen, item_line(items, bonus));
        add_option(blob, line, {.index = kRewardBase + static_cast<std::uint32_t>(at), .icon = kNoIcon});
        return;
    }
    if (bonus.kind == tk::BonusKind::kDemand) {
        if (!flow.has_demand) add_text(blob, kDemandHeader);
        flow.has_demand = true;
        add_text(blob, item_line(items, bonus));
        return;
    }
    if (bonus.kind == tk::BonusKind::kMoney && bonus.a <= 0) return;
    if (!flow.has_fixed) add_text(blob, kFixedHeader);
    flow.has_fixed = true;
    if (bonus.kind == tk::BonusKind::kMoney) {
        add_record(blob, {gui::kMoneyElement, std::to_string(bonus.a)});
        return;
    }
    add_text(blob, item_line(items, bonus));
}

void paint_buttons(Deck& deck, const tk::Dialog& dialog) {
    constexpr std::string_view kDisabled = "Disabled";
    const bool is_offer = dialog.mode == tk::Mode::kMissionInfo;
    const bool is_turn_in = dialog.mode == tk::Mode::kDemand;
    std::string_view refuse = kCancelText;
    if (dialog.mode == tk::Mode::kList || dialog.mode == tk::Mode::kBox) refuse = kGoodbyeText;
    if (dialog.mode == tk::Mode::kTips) refuse = kCloseText;
    deck.set(gui::Override{.window = kTalkAccept, .name = kDisabled, .value = is_offer ? "False" : "True"});
    deck.set(gui::Override{.window = kTalkContinue, .name = kDisabled, .value = is_turn_in ? "False" : "True"});
    deck.set(gui::Override{.window = kTalkContinue, .name = "Text", .value = is_turn_in ? kCompleteText : kContinueText});
    deck.set(gui::Override{.window = kTalkRefuse, .name = "Text", .value = refuse});
}

} // namespace

bool ItemNames::load(std::string_view text) {
    names_.clear();
    is_loaded_ = false;
    constexpr std::size_t kNone = std::string_view::npos;
    std::size_t id_column = kNone;
    std::size_t name_column = kNone;
    bool has_header = false;
    std::vector<std::string_view> fields;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        fields.clear();
        for (std::size_t from = 0;;) {
            const std::size_t tab = line.find('\t', from);
            fields.push_back(line.substr(from, tab == std::string_view::npos ? tab : tab - from));
            if (tab == std::string_view::npos) break;
            from = tab + 1;
        }
        if (!has_header) {
            const auto id = std::ranges::find(fields, "id");
            const auto name = std::ranges::find(fields, "name");
            if (id == fields.end() || name == fields.end()) return false;
            id_column = static_cast<std::size_t>(id - fields.begin());
            name_column = static_cast<std::size_t>(name - fields.begin());
            has_header = true;
            continue;
        }
        if (fields.size() <= std::max(id_column, name_column)) continue;
        const std::string_view id_text = fields.at(id_column);
        const std::optional<int> id = core::parse_whole_int(id_text);
        if (!id) continue;
        names_.emplace(*id, std::string(fields.at(name_column)));
    }
    is_loaded_ = has_header;
    return has_header;
}

std::string_view ItemNames::name(std::int32_t item) const noexcept {
    const auto found = names_.find(item);
    return found == names_.end() ? std::string_view{} : std::string_view(found->second);
}

void open_talk(NpcTalk& talk, tk::Dialog dialog) {
    const bool is_update = talk.is_open && talk.dialog.session == dialog.session;
    // Phiên cũ hơn hộp đang mở là tin đến trễ; phiên tăng ngặt nên bỏ nó.
    if (talk.is_open && dialog.session < talk.dialog.session) return;
    talk.is_waiting = false;
    if (!is_update || !offers_item(dialog, talk.reward)) talk.reward = -1;
    talk.dialog = std::move(dialog);
    talk.is_open = true;
}

void close_talk(NpcTalk& talk, const tk::Closed& closed) {
    if (!talk.is_open || closed.session < talk.dialog.session) return;
    const std::string_view reason = closed_text(closed.reason);
    if (!reason.empty()) talk.notices.emplace_back(reason);
    drop_talk(talk);
}

void refuse_talk(NpcTalk& talk, tk::Refusal why) {
    talk.is_waiting = false;
    if (why == tk::Refusal::kNoSession) drop_talk(talk);
    const std::string_view text = refusal_text(why);
    if (!text.empty()) talk.notices.emplace_back(text);
}

void note_notice(NpcTalk& talk, const tk::Notice& notice, const ItemNames& items) {
    if (!notice.text.empty()) {
        talk.notices.push_back(notice.text);
        return;
    }
    switch (notice.kind) {
    case tk::NoticeKind::kRewardExp: talk.notices.push_back(std::format("获得经验 {}", notice.value)); break;
    case tk::NoticeKind::kRewardMoney:
        talk.notices.push_back(std::format("{} {}", notice.ref == 1 ? "获得交子" : "获得金钱", notice.value));
        break;
    case tk::NoticeKind::kRewardItem: {
        const std::string_view known = items.name(notice.ref);
        talk.notices.push_back(known.empty() ? std::format("获得物品{} x{}", notice.ref, notice.value)
                                             : std::format("获得物品 {} x{}", known, notice.value));
        break;
    }
    case tk::NoticeKind::kAdded:
    case tk::NoticeKind::kUpdated:
    case tk::NoticeKind::kReady:
    case tk::NoticeKind::kRemoved:
    case tk::NoticeKind::kDone:
    case tk::NoticeKind::kFailed:
    case tk::NoticeKind::kText:
    case tk::NoticeKind::kAnnounce:
    case tk::NoticeKind::kRelation: break;
    }
}

quest::Log log_of(const tk::Book& book) {
    quest::Log log;
    const std::size_t count = std::min(book.slots.size(), log.slots.size());
    for (std::size_t at = 0; at < count; ++at) {
        const tk::Slot& from = book.slots.at(at);
        quest::Slot& to = log.slots.at(at);
        to.mission = from.quest;
        to.script = from.script;
        to.flags = from.flags;
        const std::size_t kept = std::min(from.params.size(), to.params.size());
        std::copy_n(from.params.begin(), kept, to.params.begin());
    }
    std::ranges::copy(book.done, log.done.begin());
    return log;
}

void drop_talk(NpcTalk& talk) noexcept {
    talk.is_open = false;
    talk.is_waiting = false;
    talk.reward = -1;
}

void step_talk(NpcTalk& talk, std::chrono::milliseconds clock) noexcept {
    if (talk.is_waiting && clock - talk.waiting_since > kReplyTimeout) talk.is_waiting = false;
}

void press_talk(NpcTalk& talk, std::string_view window, std::chrono::milliseconds clock) {
    if (!talk.is_open) return;
    if (window == kTalkClose || window == kTalkRefuse) {
        hang_up(talk);
        return;
    }
    if (talk.is_waiting) return;
    if (window == kTalkAccept) send_accept(talk, clock);
    if (window == kTalkContinue) send_turn_in(talk, clock);
}

void pick_talk_option(NpcTalk& talk, std::uint32_t index, std::chrono::milliseconds clock) {
    if (!talk.is_open || talk.is_waiting) return;
    if (index >= kRewardBase) {
        const std::size_t at = index - kRewardBase;
        if (at < talk.dialog.bonuses.size() && talk.dialog.bonuses.at(at).kind == tk::BonusKind::kRadio) {
            talk.reward = talk.dialog.bonuses.at(at).a;
        }
        return;
    }
    const bool is_offered = std::ranges::any_of(talk.dialog.choices, [index](const tk::Choice& choice) { return choice.index == index; });
    if (!is_offered) return;
    request(talk, tk::Choose{.session = talk.dialog.session, .index = static_cast<std::uint16_t>(index)}, clock);
}

void paint_talk(Deck& deck, const NpcTalk& talk, std::string_view title, const ItemNames& items) {
    if (!talk.is_open) return;
    const tk::Dialog& dialog = talk.dialog;
    deck.show(kTalkRoot);
    std::string& heading = deck.compose(Key{.window = kTalkTitle, .name = "Text"});
    heading.append(kTitleTint);
    heading.append(title);
    std::string& blob = deck.compose(Key{.window = kTalkDesc, .name = gui::kElementsProperty});
    for (const std::string& line : dialog.lines) add_text(blob, line);
    BonusFlow flow;
    for (std::size_t at = 0; at < dialog.bonuses.size(); ++at) add_bonus(blob, flow, dialog, at, talk, items);
    for (const tk::Choice& choice : dialog.choices) {
        add_option(blob, choice.text, {.index = choice.index, .icon = icon_of(choice.icon)});
    }
    paint_buttons(deck, dialog);
}

} // namespace game::ui::panel
