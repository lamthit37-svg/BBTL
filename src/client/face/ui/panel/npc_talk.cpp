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
#include "table/localize.hpp"
#include "table/tsv.hpp"
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
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
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
// Biểu tượng của dòng nhiệm vụ: trạng thái AddNumText của gốc (edali_0210.lua: 1 là nhận được, 2 là
// đang giữ và nộp) đi thẳng thành chỉ số ảnh QuestButtonImage
// (TLBBLook_ComplexWindow.looknfeel.xml: 1 là QuestIcon_0, 2 là QuestIcon_1), như
// Quest_EventListUpdate của Quest.lua (resState). Mục dùng cho nút nhận (1) và nút nộp (2).
constexpr std::int32_t kAcceptIcon = 1;
constexpr std::int32_t kTurnInIcon = 2;

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

// Một dòng TSV đã tách ô. Cột không có trong tệp là npos.
struct ItemColumns {
    std::size_t id = std::string_view::npos;
    std::size_t name = std::string_view::npos;
    std::size_t icon = std::string_view::npos;
};

std::size_t column_at(const std::vector<std::string_view>& fields, std::string_view title) {
    const auto found = std::ranges::find(fields, title);
    if (found == fields.end()) return std::string_view::npos;
    return static_cast<std::size_t>(found - fields.begin());
}

std::vector<std::string_view> split_fields(std::string_view line) {
    std::vector<std::string_view> fields;
    for (std::size_t from = 0;;) {
        const std::size_t tab = line.find('\t', from);
        fields.push_back(line.substr(from, tab == std::string_view::npos ? tab : tab - from));
        if (tab == std::string_view::npos) break;
        from = tab + 1;
    }
    return fields;
}

std::string_view field_at(const std::vector<std::string_view>& fields, std::size_t column) {
    if (column == std::string_view::npos || column >= fields.size()) return {};
    return fields[column];
}

// need_name: bảng tên bắt buộc có cột name. Bảng phụ chỉ bắt buộc id. Dòng hỏng bị bỏ, không làm hỏng cả tệp.
template <typename Put>
bool take_item_rows(std::string_view text, bool need_name, Put put) {
    ItemColumns columns;
    bool has_header = false;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        const std::vector<std::string_view> fields = split_fields(line);
        if (!has_header) {
            columns.id = column_at(fields, "id");
            columns.name = column_at(fields, "name");
            columns.icon = column_at(fields, "icon");
            const bool has_name = !need_name || columns.name != std::string_view::npos;
            if (columns.id == std::string_view::npos || !has_name) return false;
            has_header = true;
            continue;
        }
        if (fields.size() <= columns.id) continue;
        if (need_name && fields.size() <= columns.name) continue;
        const std::optional<int> id = core::parse_whole_int(field_at(fields, columns.id));
        if (!id) continue;
        put(*id, field_at(fields, columns.name), field_at(fields, columns.icon));
    }
    return has_header;
}

constexpr std::string_view kMissingFace = "set:X image:X";

} // namespace

bool ItemNames::load(std::string_view text) {
    rows_.clear();
    is_loaded_ = false;
    const bool loaded = take_item_rows(text, true, [this](int id, std::string_view item_name, std::string_view item_icon) {
        rows_.emplace(id, Entry{.name = std::string(item_name), .icon = std::string(item_icon)});
    });
    is_loaded_ = loaded;
    return loaded;
}

bool ItemNames::load_table(const table::Tsv& table, bool replace) {
    const std::optional<std::size_t> id_column = table::column_of(table, "id");
    const std::optional<std::size_t> name_column = table::column_of(table, "name");
    const std::optional<std::size_t> icon_column = table::column_of(table, "icon");
    if (!id_column) return false;
    if (replace && !name_column) return false;
    if (replace) {
        rows_.clear();
        is_loaded_ = false;
    }
    for (const std::vector<std::string>& cells : table.rows) {
        if (cells.size() <= *id_column) continue;
        const std::optional<int> id = core::parse_whole_int(cells[*id_column]);
        if (!id) continue;
        if (!replace && rows_.contains(*id)) continue;
        const std::string_view item_name = name_column && cells.size() > *name_column ? std::string_view{cells[*name_column]}
                                                                                      : std::string_view{};
        if (table::is_reserved_name(item_name)) continue;
        const std::string_view item_icon = icon_column && cells.size() > *icon_column ? std::string_view{cells[*icon_column]}
                                                                                      : std::string_view{};
        rows_.insert_or_assign(*id, Entry{.name = std::string(item_name), .icon = std::string(item_icon)});
    }
    if (replace) is_loaded_ = true;
    return true;
}

bool ItemNames::absorb(std::string_view text) {
    return take_item_rows(text, false, [this](int id, std::string_view item_name, std::string_view item_icon) {
        if (rows_.contains(id)) return;
        rows_.emplace(id, Entry{.name = std::string(item_name), .icon = std::string(item_icon)});
    });
}

bool ItemNames::load_icons(std::string_view text) {
    std::unordered_map<std::string, std::string> next;
    std::size_t icon_column = std::string_view::npos;
    std::size_t set_column = std::string_view::npos;
    bool has_header = false;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        const std::vector<std::string_view> fields = split_fields(line);
        if (!has_header) {
            icon_column = column_at(fields, "icon");
            set_column = column_at(fields, "imageset");
            if (icon_column == std::string_view::npos || set_column == std::string_view::npos) return false;
            has_header = true;
            continue;
        }
        const std::string_view icon = field_at(fields, icon_column);
        const std::string_view imageset = field_at(fields, set_column);
        if (icon.empty()) continue;
        next.emplace(std::string(icon), std::string(imageset));
    }
    if (!has_header) return false;
    imagesets_ = std::move(next);
    has_icons_ = true;
    return true;
}

std::string ItemNames::image(std::string_view icon) const {
    if (icon.empty()) return std::string(kMissingFace);
    const auto imageset = imagesets_.find(std::string(icon));
    if (imageset == imagesets_.end() || imageset->second.empty()) return std::string(kMissingFace);
    return std::format("set:{} image:{}", imageset->second, icon);
}

std::string_view ItemNames::name(std::int32_t item) const noexcept {
    const auto found = rows_.find(item);
    return found == rows_.end() ? std::string_view{} : std::string_view(found->second.name);
}

std::string_view ItemNames::icon(std::int32_t item) const noexcept {
    const auto found = rows_.find(item);
    return found == rows_.end() ? std::string_view{} : std::string_view(found->second.icon);
}

std::string ItemNames::face(std::uint32_t item) const {
    const auto largest = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    if (item > largest) return std::string(kMissingFace);
    const auto found = rows_.find(static_cast<std::int32_t>(item));
    if (found == rows_.end()) return std::string(kMissingFace);
    return image(found->second.icon);
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

constexpr char kUnitSep = '\x1f';
constexpr char kRecordSep = '\x1e';

struct MarkLine {
    bool ok = false;
    char stage = 0;
    std::uint32_t quest = 0;
    std::string_view name;
    std::string_view hint;
};

bool take_digit(std::uint32_t& quest, char digit) {
    if (digit < '0' || digit > '9') return false;
    if (quest > (kMarkSpan - 1U) / 10U) return false;
    const auto value = static_cast<std::uint32_t>(digit - '0');
    const std::uint32_t next = quest * 10U + value;
    if (next >= kMarkSpan) return false;
    quest = next;
    return true;
}

bool read_quest(std::string_view digits, std::uint32_t& quest) {
    if (digits.empty()) return false;
    quest = 0;
    for (const char digit : digits) {
        if (!take_digit(quest, digit)) return false;
    }
    return true;
}

// Cùng dạng mark_text ở src/server/play/gameplay.cpp. Dòng không đúng dạng giữ làm chữ thường.
MarkLine parse_mark(std::string_view line) {
    MarkLine parsed;
    if (!line.starts_with("TLQ")) return parsed;
    if (line.size() < 6) return parsed;
    if (line[3] != kUnitSep || line[5] != kUnitSep) return parsed;
    const char stage = line[4];
    const bool known = stage == '1' || stage == '2' || stage == '3';
    if (!known) return parsed;
    const std::size_t split = line.find(kUnitSep, 6);
    if (split == std::string_view::npos) return parsed;
    if (!read_quest(line.substr(6, split - 6), parsed.quest)) return parsed;
    const std::string_view rest = line.substr(split + 1);
    const std::size_t hint_at = rest.find(kUnitSep);
    parsed.ok = true;
    parsed.stage = stage;
    parsed.name = rest;
    if (hint_at != std::string_view::npos) parsed.name = rest.substr(0, hint_at);
    if (hint_at != std::string_view::npos) parsed.hint = rest.substr(hint_at + 1);
    return parsed;
}

bool hint_ok(std::string_view hint) {
    if (hint.empty()) return false;
    if (hint.find(kUnitSep) != std::string_view::npos) return false;
    if (hint.find(kRecordSep) != std::string_view::npos) return false;
    return true;
}

// Chữ của dòng nhiệm vụ: tên (thiếu thì số) kèm mục tiêu. Không ghép ký tự trạng thái: gốc vẽ trạng
// thái bằng biểu tượng.
std::string mark_label(const MarkLine& parsed) {
    const bool named = !parsed.name.empty();
    std::string base = named ? std::string{parsed.name} : std::to_string(parsed.quest);
    if (!hint_ok(parsed.hint)) return base;
    return std::format("{}·{}", base, parsed.hint);
}

void add_mark_line(std::string& blob, const MarkLine& parsed) {
    const std::string label = mark_label(parsed);
    if (parsed.stage == '2') add_text(blob, label);
    if (parsed.stage == '2') return;
    const std::uint32_t base = parsed.stage == '1' ? kMarkAccept : kMarkTurn;
    const std::uint32_t index = base + parsed.quest;
    const std::int32_t icon = parsed.stage == '1' ? kAcceptIcon : kTurnInIcon;
    add_option(blob, label, {.index = index, .icon = icon});
}

// US là dấu trường của cửa sổ phức hợp. Chữ thường không được mang nó, kẻo vỡ bản ghi.
std::string plain_text(std::string_view line) {
    std::string plain{line};
    for (char& one : plain) {
        if (one == kUnitSep) one = ' ';
    }
    return plain;
}

void add_spoken(std::string& blob, std::string_view line) {
    const MarkLine parsed = parse_mark(line);
    if (parsed.ok) add_mark_line(blob, parsed);
    if (parsed.ok) return;
    const std::string plain = plain_text(line);
    add_text(blob, plain);
}

bool in_span(std::uint32_t index, std::uint32_t base) {
    return index >= base && index < base + kMarkSpan;
}

bool same_mark(std::string_view line, char stage, std::uint32_t quest) {
    const MarkLine parsed = parse_mark(line);
    return parsed.ok && parsed.stage == stage && parsed.quest == quest;
}

bool dialog_has_mark(const tk::Dialog& dialog, char stage, std::uint32_t quest) {
    for (const std::string& line : dialog.lines) {
        if (same_mark(line, stage, quest)) return true;
    }
    return false;
}

void send_accept_mark(NpcTalk& talk, std::uint32_t quest, std::chrono::milliseconds clock) {
    const auto id = static_cast<std::uint16_t>(quest);
    request(talk, tk::Accept{.session = talk.dialog.session, .quest = id}, clock);
}

void send_turn_mark(NpcTalk& talk, std::uint32_t quest, std::chrono::milliseconds clock) {
    const auto id = static_cast<std::uint16_t>(quest);
    const tk::TurnIn turn{.session = talk.dialog.session, .quest = id, .reward = -1};
    request(talk, turn, clock);
}

bool send_mark(NpcTalk& talk, std::uint32_t index, std::chrono::milliseconds clock) {
    const bool is_turn = in_span(index, kMarkTurn);
    const bool is_accept = in_span(index, kMarkAccept);
    if (!is_turn && !is_accept) return false;
    const std::uint32_t base = is_turn ? kMarkTurn : kMarkAccept;
    const std::uint32_t quest = index - base;
    const char stage = is_turn ? '3' : '1';
    if (!dialog_has_mark(talk.dialog, stage, quest)) return true;
    if (is_accept) send_accept_mark(talk, quest, clock);
    if (is_turn) send_turn_mark(talk, quest, clock);
    return true;
}

void pick_talk_option(NpcTalk& talk, std::uint32_t index, std::chrono::milliseconds clock) {
    if (!talk.is_open || talk.is_waiting) return;
    if (send_mark(talk, index, clock)) return;
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
    for (const std::string& line : dialog.lines) {
        add_spoken(blob, line);
    }
    BonusFlow flow;
    for (std::size_t at = 0; at < dialog.bonuses.size(); ++at) add_bonus(blob, flow, dialog, at, talk, items);
    for (const tk::Choice& choice : dialog.choices) {
        add_option(blob, choice.text, {.index = choice.index, .icon = icon_of(choice.icon)});
    }
    paint_buttons(deck, dialog);
}

} // namespace game::ui::panel
