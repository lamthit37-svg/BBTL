/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Ui/ui_npc_talk_tests.cpp
 *  PHÂN HỆ   : Test / Ui / NpcTalk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy trạng thái hộp thoại NPC (ui/panel/npc_talk): việc gửi lên máy chủ
 *    theo từng lần bấm, khoá khi chờ đáp, phiên cũ, chọn thưởng, và chữ đổ sang
 *    các cửa sổ của layout Quest.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chỉ ca mà sai thì hỏng thầm: thứ tự phiên, khoá khi chờ, chọn thưởng trước khi nộp, và chỉ số lựa chọn gửi đi. Phần vẽ lên cửa sổ
// kiểm bằng chạy bản dựng và nhìn.

#include "ui/panel/npc_talk.hpp"

#include "gui/content.hpp"
#include "gui/sheet.hpp"
#include "quest/log.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/packet.hpp"
#include "ui/panel/talk.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace game::test {
namespace {

namespace tk = ui::panel::talk;
using ui::panel::NpcTalk;
using std::chrono::milliseconds;

constexpr milliseconds kStart{1000};

tk::Dialog list_dialog(std::uint64_t session) {
    tk::Dialog dialog;
    dialog.session = session;
    dialog.npc = 77;
    dialog.mode = tk::Mode::kList;
    dialog.lines = {"你好，少侠。"};
    dialog.choices = {tk::Choice{.index = 3, .icon = 0, .text = "我想接任务"}, tk::Choice{.index = 9, .icon = 5, .text = "再见"}};
    return dialog;
}

tk::Dialog offer_dialog(std::uint64_t session) {
    tk::Dialog dialog;
    dialog.session = session;
    dialog.npc = 77;
    dialog.mode = tk::Mode::kMissionInfo;
    dialog.lines = {"帮我杀三只野狼。"};
    dialog.panel_quest = 1201;
    dialog.bonuses = {tk::Bonus{.kind = tk::BonusKind::kMoney, .a = 500, .b = 0, .c = 0}};
    return dialog;
}

tk::Dialog turn_in_dialog(std::uint64_t session, bool with_radio) {
    tk::Dialog dialog;
    dialog.session = session;
    dialog.npc = 77;
    dialog.mode = tk::Mode::kDemand;
    dialog.lines = {"做得好。"};
    dialog.panel_quest = 1201;
    if (with_radio) {
        dialog.bonuses = {tk::Bonus{.kind = tk::BonusKind::kRadio, .a = 10100001, .b = 1, .c = 0},
            tk::Bonus{.kind = tk::BonusKind::kRadio, .a = 10100002, .b = 1, .c = 0}};
    }
    return dialog;
}

template <typename Message>
const Message* last_say(const NpcTalk& talk) {
    if (talk.says.empty()) return nullptr;
    return std::get_if<Message>(&talk.says.back());
}

void choice_goes_up_with_the_session(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    context.expect(talk.is_open, "mở hộp");
    ui::panel::pick_talk_option(talk, 3, kStart);
    const auto* chosen = last_say<tk::Choose>(talk);
    context.expect(chosen != nullptr && chosen->session == 5 && chosen->index == 3, "gửi Choose đúng phiên và số lựa chọn");
    context.expect(talk.is_waiting, "đang chờ máy chủ đáp");
}

void second_click_is_dropped_while_waiting(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::pick_talk_option(talk, 3, kStart);
    ui::panel::pick_talk_option(talk, 9, kStart);
    context.expect(talk.says.size() == 1, "lần bấm thứ hai khi đang chờ không gửi thêm");
    ui::panel::open_talk(talk, list_dialog(6));
    context.expect(!talk.is_waiting, "hộp mới của máy chủ mở khoá");
    ui::panel::pick_talk_option(talk, 9, kStart);
    const auto* chosen = last_say<tk::Choose>(talk);
    context.expect(talk.says.size() == 2 && chosen != nullptr && chosen->session == 6, "bấm tiếp dùng mã phiên mới");
}

void unknown_option_is_ignored(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::pick_talk_option(talk, 4, kStart);
    context.expect(talk.says.empty() && !talk.is_waiting, "số lựa chọn máy chủ không đưa thì không gửi");
}

void silent_server_unlocks_after_timeout(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::pick_talk_option(talk, 3, kStart);
    ui::panel::step_talk(talk, kStart + ui::panel::kReplyTimeout);
    context.expect(talk.is_waiting, "đúng hạn chưa mở khoá");
    ui::panel::step_talk(talk, kStart + ui::panel::kReplyTimeout + milliseconds{1});
    context.expect(!talk.is_waiting, "quá hạn thì mở khoá");
}

void accept_only_in_offer_mode(Context& context) {
    NpcTalk list;
    ui::panel::open_talk(list, list_dialog(5));
    ui::panel::press_talk(list, ui::panel::kTalkAccept, kStart);
    context.expect(list.says.empty(), "hộp danh sách không nhận nhiệm vụ");
    NpcTalk offer;
    ui::panel::open_talk(offer, offer_dialog(8));
    ui::panel::press_talk(offer, ui::panel::kTalkAccept, kStart);
    const auto* accepted = last_say<tk::Accept>(offer);
    context.expect(accepted != nullptr && accepted->session == 8 && accepted->quest == 1201, "Accept mang phiên và nhiệm vụ của bảng");
}

void turn_in_waits_for_reward_choice(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, turn_in_dialog(11, true));
    ui::panel::press_talk(talk, ui::panel::kTalkContinue, kStart);
    context.expect(talk.says.empty() && talk.notices.size() == 1, "có nhóm chọn một mà chưa chọn thì không nộp, nhắc người chơi");
    ui::panel::pick_talk_option(talk, ui::panel::kRewardBase + 1, kStart);
    context.expect(talk.reward == 10100002, "chọn dòng thứ hai của nhóm thưởng");
    context.expect(talk.says.empty(), "chọn thưởng chỉ là chọn phía client");
    ui::panel::press_talk(talk, ui::panel::kTalkContinue, kStart);
    const auto* turned = last_say<tk::TurnIn>(talk);
    context.expect(turned != nullptr && turned->session == 11 && turned->quest == 1201 && turned->reward == 10100002,
        "TurnIn mang vật phẩm đã chọn");
}

void turn_in_without_radio_sends_no_reward(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, turn_in_dialog(12, false));
    ui::panel::press_talk(talk, ui::panel::kTalkContinue, kStart);
    const auto* turned = last_say<tk::TurnIn>(talk);
    context.expect(turned != nullptr && turned->reward == -1, "không có nhóm chọn một thì reward là -1");
}

void reward_choice_survives_a_same_session_update(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, turn_in_dialog(11, true));
    ui::panel::pick_talk_option(talk, ui::panel::kRewardBase, kStart);
    ui::panel::open_talk(talk, turn_in_dialog(11, true));
    context.expect(talk.reward == 10100001, "cùng phiên cập nhật nội dung thì giữ lựa chọn");
    ui::panel::open_talk(talk, turn_in_dialog(12, true));
    context.expect(talk.reward == -1, "phiên mới thì bỏ lựa chọn");
}

void stale_close_is_ignored(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::open_talk(talk, list_dialog(6));
    ui::panel::close_talk(talk, tk::Closed{.session = 5, .reason = tk::Reason::kReplaced});
    context.expect(talk.is_open, "DialogClosed của phiên bị thay đến sau thì bỏ");
    ui::panel::close_talk(talk, tk::Closed{.session = 6, .reason = tk::Reason::kFar});
    context.expect(!talk.is_open, "đóng đúng phiên đang mở");
    context.expect(talk.notices.size() == 1, "lý do Far được nhắc");
}

void old_dialog_is_ignored(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(9));
    ui::panel::open_talk(talk, list_dialog(4));
    context.expect(talk.dialog.session == 9, "DialogOpen cũ hơn hộp đang mở thì bỏ");
}

void close_button_hangs_up(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::press_talk(talk, ui::panel::kTalkClose, kStart);
    const auto* closed = last_say<tk::Close>(talk);
    context.expect(closed != nullptr && closed->session == 5, "nút đóng gửi Close đúng phiên");
    context.expect(!talk.is_open && !talk.is_waiting, "và đóng hộp ngay");
    ui::panel::press_talk(talk, ui::panel::kTalkClose, kStart);
    context.expect(talk.says.size() == 1, "đóng rồi bấm tiếp không gửi thêm");
}

void rejection_unlocks_and_explains(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, offer_dialog(8));
    ui::panel::press_talk(talk, ui::panel::kTalkAccept, kStart);
    ui::panel::refuse_talk(talk, tk::Refusal::kQuestLogFull);
    context.expect(!talk.is_waiting && talk.is_open, "bị từ chối thì mở khoá, hộp còn đó");
    context.expect(talk.notices.size() == 1, "nhắc người chơi");
    ui::panel::refuse_talk(talk, tk::Refusal::kNoSession);
    context.expect(!talk.is_open, "máy chủ nói không có phiên thì đóng hộp");
}

// Chữ trong deck của một thuộc tính; rỗng khi không có.
std::string deck_value(ui::panel::Deck& deck, std::string_view window, std::string_view name) {
    std::string found;
    for (const gui::Override& item : deck.overrides()) {
        if (item.window == window && item.name == name) found = std::string(item.value);
    }
    return found;
}

void paint_lists_text_then_options(Context& context) {
    NpcTalk talk;
    ui::panel::open_talk(talk, list_dialog(5));
    ui::panel::Deck deck;
    const ui::panel::ItemNames items;
    ui::panel::paint_talk(deck, talk, "老村长", items);
    const std::string elements = deck_value(deck, ui::panel::kTalkDesc, gui::kElementsProperty);
    const std::size_t text_at = elements.find("text");
    const std::size_t option_at = elements.find("option");
    context.expect(text_at != std::string::npos && option_at != std::string::npos && text_at < option_at,
        "lời NPC trước, lựa chọn sau");
    context.expect(elements.contains("我想接任务"), "chữ lựa chọn có mặt");
    const std::string mark(1, gui::kFieldMark);
    context.expect(elements.contains(mark + "9" + mark + "5"), "lựa chọn mang số 9 và biểu tượng 5");
    context.expect(elements.contains(mark + "3" + mark + "8"), "biểu tượng 0 về mặc định 8");
    context.expect(deck_value(deck, ui::panel::kTalkTitle, "Text").ends_with("老村长"), "tiêu đề là tên NPC");
    context.expect(deck.is_shown(ui::panel::kTalkRoot), "hộp hiện");
}

void paint_while_closed_shows_nothing(Context& context) {
    const NpcTalk talk;
    ui::panel::Deck deck;
    const ui::panel::ItemNames items;
    ui::panel::paint_talk(deck, talk, "", items);
    context.expect(!deck.is_shown(ui::panel::kTalkRoot), "hộp đóng thì không kê gì");
}

void button_state_follows_mode(Context& context) {
    const ui::panel::ItemNames items;
    NpcTalk offer;
    ui::panel::open_talk(offer, offer_dialog(8));
    ui::panel::Deck offered;
    ui::panel::paint_talk(offered, offer, "", items);
    context.expect(deck_value(offered, ui::panel::kTalkAccept, "Disabled") == "False", "bảng nhận mở nút nhận");
    context.expect(deck_value(offered, ui::panel::kTalkContinue, "Disabled") == "True", "bảng nhận khoá nút tiếp");
    NpcTalk turn;
    ui::panel::open_talk(turn, turn_in_dialog(9, false));
    ui::panel::Deck turned;
    ui::panel::paint_talk(turned, turn, "", items);
    context.expect(deck_value(turned, ui::panel::kTalkContinue, "Disabled") == "False", "bảng nộp mở nút hoàn thành");
    context.expect(deck_value(turned, ui::panel::kTalkAccept, "Disabled") == "True", "bảng nộp khoá nút nhận");
    // Nhiệm vụ đang làm (kContinue): chỉ mô tả và nhắc, không có nút nộp.
    NpcTalk doing;
    tk::Dialog reminder = turn_in_dialog(10, false);
    reminder.mode = tk::Mode::kContinue;
    ui::panel::open_talk(doing, reminder);
    ui::panel::Deck reminded;
    ui::panel::paint_talk(reminded, doing, "", items);
    context.expect(deck_value(reminded, ui::panel::kTalkContinue, "Disabled") == "True", "nhiệm vụ đang làm khoá nút hoàn thành");
    ui::panel::press_talk(doing, ui::panel::kTalkContinue, kStart);
    context.expect(doing.says.empty(), "nhiệm vụ đang làm không nộp được");
}

void item_names_read_the_name_column(Context& context) {
    ui::panel::ItemNames items;
    const std::string table =
        "# chú thích\n"
        "id\tcolumn_1\ticon\tname\n"
        "10100001\t2\tIcon_A\t铁剑\n"
        "10100002\t2\tIcon_B\t布衣\r\n"
        "hỏng\t2\tIcon_C\tbỏ\n"
        "10100003\t2\n";
    context.expect(items.load(table), "đọc được bảng");
    context.expect(items.name(10100001) == "铁剑" && items.name(10100002) == "布衣", "tên theo mẫu, kể cả dòng kết thúc CRLF");
    context.expect(items.icon(10100001) == "Icon_A" && items.icon(10100002) == "Icon_B", "cột icon");
    context.expect(items.name(10100003).empty() && items.icon(10100003).empty() && items.name(1).empty(),
        "dòng thiếu ô và mẫu lạ cho tên rỗng");
    ui::panel::ItemNames broken;
    context.expect(!broken.load("a\tb\n1\t2\n") && !broken.is_loaded(), "bảng thiếu cột id/name thì hỏng, không nạp");
    ui::panel::ItemNames plain;
    context.expect(plain.load("id\tname\n7\t七\n"), "bảng không có cột icon vẫn đọc được");
    context.expect(plain.name(7) == "七" && plain.icon(7).empty(), "không có cột icon thì icon rỗng");
    context.expect(!plain.absorb("x\ty\n1\t2\n") && plain.name(7) == "七", "bảng phụ thiếu cột id thì bỏ, không xoá tên");
    context.expect(plain.absorb("id\ticon\tname\n7\tKhac\t别\n8\tGem\t宝石\n"), "bảng phụ thêm mẫu mới");
    context.expect(plain.name(7) == "七" && plain.icon(7).empty(), "id đã có thì không đè");
    context.expect(plain.name(8) == "宝石" && plain.icon(8) == "Gem", "id mới giữ tên và icon");
    context.expect(!plain.load_icons("a\tb\n1\t2\n") && plain.face(8) == "set:X image:X", "bảng icon thiếu cột thì ảnh thay");
    context.expect(plain.load_icons("icon\timageset\nGem\tGemSet\n"), "đọc bảng icon");
    context.expect(plain.face(8) == "set:GemSet image:Gem", "ảnh đầy đủ");
    context.expect(plain.face(7) == "set:X image:X", "không có tên icon thì ảnh thay");
    context.expect(plain.face(0xFFFFFFFFU) == "set:X image:X", "id vượt int32 thì ảnh thay");
}

// Ô túi: chỉ số 0 là Line1_Row1. Số chồng > 1 cắt 3 ký tự. Ô trong vùng khoá vẫn hiện đồ. Thẻ khác không lấy túi đạo cụ.
void bag_paint_puts_the_icon_on_the_base_tab(Context& context) {
    ui::panel::ItemNames items;
    context.expect(items.load("id\ticon\tname\n101\tSword\t铁剑\n"), "bảng tên");
    context.expect(items.load_icons("icon\timageset\nSword\tCommonItem\n"), "bảng icon");
    ui::panel::Packet packet;
    packet.bag.slots.push_back(ui::panel::talk::BagSlot{.slot = 0, .item = 101, .count = 12, .bound = true});
    packet.bag.slots.push_back(ui::panel::talk::BagSlot{.slot = 0, .item = 101, .count = 3, .bound = false});
    packet.bag.slots.push_back(ui::panel::talk::BagSlot{.slot = 1, .item = 999, .count = 1, .bound = false});
    packet.bag.slots.push_back(ui::panel::talk::BagSlot{.slot = 25, .item = 101, .count = 1000, .bound = false});
    packet.bag.slots.push_back(ui::panel::talk::BagSlot{.slot = 70, .item = 101, .count = 9, .bound = false});
    ui::panel::Deck deck;
    ui::panel::paint_packet(deck, packet, items, {});
    context.expect(deck_value(deck, "Packet_Space_Line1_Row1_button", "Empty") == "False", "ô 0 có đồ");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row1_button", "NormalImage") == "set:CommonItem image:Sword", "icon ô 0");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row1_button", "CornerBotRight") == "3", "dòng sau thắng, số chồng 3");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row1_button", "BackImage").empty(), "có đồ thì không hình khoá");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row1_button", "Tooltip") == "铁剑", "tên làm tooltip");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row2_button", "NormalImage") == "set:X image:X", "mẫu lạ dùng ảnh thay");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row2_button", "CornerBotRight").empty(), "số chồng 1 không ghi góc");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row3_button", "Empty") == "True", "ô trống");
    context.expect(deck_value(deck, "Packet_Space_Line1_Row3_button", "BackImage").empty(), "ô trống trong sức chứa không khoá");
    context.expect(deck_value(deck, "Packet_Space_Line3_Row1_button", "BackImage") == "set:CommonFrame38 image:ActionLock",
        "ô trống quá sức chứa thì khoá");
    context.expect(deck_value(deck, "Packet_Space_Line3_Row6_button", "Empty") == "False", "ô trong vùng khoá vẫn hiện đồ");
    context.expect(deck_value(deck, "Packet_Space_Line3_Row6_button", "CornerBotRight") == "100", "số chồng cắt 3 ký tự");
    context.expect(deck_value(deck, "Packet_Space_Line3_Row6_button", "BackImage").empty(), "có đồ thì không đè hình khoá");
    bool line_hidden = false;
    for (const std::string_view name : deck.hidden()) line_hidden = line_hidden || name == "Packet_Space_Line7";
    context.expect(line_hidden, "hàng ngoài sức chứa bị giấu, ô 70 không hiện");
    packet.tab = 1;
    ui::panel::Deck other;
    ui::panel::paint_packet(other, packet, items, {});
    context.expect(deck_value(other, "Packet_Space_Line1_Row1_button", "Empty") == "True", "thẻ vật liệu không lấy túi đạo cụ");
    context.expect(deck_value(other, "Packet_Space_Line1_Row1_button", "NormalImage").empty(), "thẻ vật liệu không có icon");
}

// Thông báo nhiệm vụ: chữ của máy chủ giữ nguyên; thiếu chữ thì phần thưởng tự dựng từ số, loại khác im.
void notices_prefer_server_text(Context& context) {
    ui::panel::ItemNames items;
    context.expect(items.load("id\tname\n10100001\t铁剑\n"), "đọc được bảng tên");
    struct Sample {
        tk::NoticeKind kind;
        std::int64_t value;
        std::int32_t ref;
        std::string text;
    };
    const std::vector<Sample> samples = {
        {.kind = tk::NoticeKind::kDone, .value = 0, .ref = 0, .text = "#Y任务完成#W"},
        {.kind = tk::NoticeKind::kRewardExp, .value = 300, .ref = 0, .text = ""},
        {.kind = tk::NoticeKind::kRewardMoney, .value = 500, .ref = 0, .text = ""},
        {.kind = tk::NoticeKind::kRewardMoney, .value = 60, .ref = 1, .text = ""},
        {.kind = tk::NoticeKind::kRewardItem, .value = 2, .ref = 10100001, .text = ""},
        {.kind = tk::NoticeKind::kRewardItem, .value = 1, .ref = 99, .text = ""},
        {.kind = tk::NoticeKind::kAdded, .value = 0, .ref = 0, .text = ""},
        {.kind = tk::NoticeKind::kRelation, .value = 5, .ref = 2, .text = ""},
    };
    NpcTalk talk;
    for (const Sample& sample : samples) {
        tk::Notice notice;
        notice.kind = sample.kind;
        notice.quest = 7;
        notice.text = sample.text;
        notice.value = sample.value;
        notice.ref = sample.ref;
        ui::panel::note_notice(talk, notice, items);
    }
    const std::vector<std::string> expected = {
        "#Y任务完成#W", "#{NPCTALK_GOT_EXP} 300", "#{NPCTALK_GOT_MONEY} 500", "#{NPCTALK_GOT_JIAOZI} 60",
        "#{NPCTALK_GOT_ITEM} 铁剑 x2", "#{NPCTALK_GOT_ITEM} 99 x1"};
    context.expect(talk.notices == expected, "chữ máy chủ, thưởng tự dựng, loại không chữ thì bỏ");
}

// Sổ nhiệm vụ của máy chủ thành sổ client: ô giữ id, script, cờ, tham số (cắt ở 8); 4096 bit "đã xong" giữ nguyên.
void book_becomes_the_client_log(Context& context) {
    tk::Book book;
    book.slots.push_back(tk::Slot{.quest = 1201, .script = 5001, .flags = 3, .params = {1, 2, 3}});
    book.slots.push_back(tk::Slot{.quest = 7, .script = -1, .flags = 0, .params = {9, 9, 9, 9, 9, 9, 9, 9, 9, 9}});
    book.done[1] = 1U << 5;
    const quest::Log log = ui::panel::log_of(book);
    context.expect(log.slots[0].mission == 1201 && log.slots[0].script == 5001 && log.slots[0].flags == 3, "ô đầu");
    context.expect(log.slots[0].params[0] == 1 && log.slots[0].params[2] == 3 && log.slots[0].params[3] == 0, "tham số thiếu là 0");
    context.expect(log.slots[1].params[7] == 9, "tham số thừa bị cắt ở 8");
    context.expect(log.slots[2].mission == quest::kNoMission, "ô không dùng là ô trống");
    context.expect(quest::holds(log, 1201) && quest::holds(log, 7) && !quest::holds(log, 8), "đang giữ");
    context.expect(quest::is_done(log, 37) && !quest::is_done(log, 36), "nhiệm vụ 37 là bit 5 của từ 1");
}

std::string mark_line(char stage, int quest, std::string_view name) {
    std::string line = "TLQ";
    line.push_back('\x1f');
    line.push_back(stage);
    line.push_back('\x1f');
    line.append(std::to_string(quest));
    line.push_back('\x1f');
    line.append(name);
    return line;
}

void quest_mark_line_is_a_local_button(Context& context) {
    tk::Dialog dialog = list_dialog(5);
    dialog.lines.push_back(mark_line('1', 1400, "初涉江湖") + "\x1f" "赵天师");
    dialog.lines.push_back(mark_line('2', 1401, "拜访"));
    dialog.lines.push_back(mark_line('3', 1403, ""));
    dialog.lines.push_back("TLQ khong phai dau");
    dialog.lines.push_back("TLQ\x1f" "9\x1f" "12\x1f" "x");
    NpcTalk talk;
    ui::panel::open_talk(talk, dialog);
    ui::panel::Deck deck;
    const ui::panel::ItemNames items;
    ui::panel::paint_talk(deck, talk, "赵天师", items);
    const std::string elements = deck_value(deck, ui::panel::kTalkDesc, gui::kElementsProperty);
    const std::string field(1, gui::kFieldMark);
    const std::string doing = std::string(gui::kTextElement) + field + "拜访";
    const std::string doing_button = std::string(gui::kOptionElement) + field + "拜访";
    const std::string accept = std::to_string(ui::panel::kMarkAccept + 1400U);
    const std::string turn = std::to_string(ui::panel::kMarkTurn + 1403U);
    const std::string option = std::string(gui::kOptionElement) + field;
    const std::string accept_button = option + "初涉江湖·赵天师" + field + accept + field + "1";
    const std::string turn_button = option + "1403" + field + turn + field + "2";
    context.expect(elements.contains("你好，少侠。"), "lời NPC còn");
    context.expect(elements.contains(accept_button), "nút nhận kèm mục tiêu, biểu tượng 1");
    context.expect(elements.contains(doing), "đang làm là chữ");
    context.expect(!elements.contains(doing_button), "đang làm không phải nút");
    context.expect(elements.contains(turn_button), "nút nộp thiếu tên thì hiện số, biểu tượng 2");
    context.expect(!elements.contains('!') && !elements.contains('?'), "không ghép ký tự trạng thái vào chữ");
    context.expect(elements.contains("TLQ khong phai dau"), "dòng lệch dạng vẫn là chữ");
    context.expect(elements.contains("TLQ 9 12 x"), "US lạ thành khoảng trắng");
    ui::panel::pick_talk_option(talk, ui::panel::kMarkAccept + 1400U, kStart);
    const auto* taken = last_say<tk::Accept>(talk);
    context.expect(taken != nullptr && taken->quest == 1400 && taken->session == 5, "gửi Accept");
    context.expect(last_say<tk::Choose>(talk) == nullptr, "không gửi Choose");
    talk.is_waiting = false;
    talk.says.clear();
    ui::panel::pick_talk_option(talk, ui::panel::kMarkTurn + 1403U, kStart);
    const auto* turned = last_say<tk::TurnIn>(talk);
    context.expect(turned != nullptr && turned->quest == 1403 && turned->reward == -1, "gửi TurnIn");
    talk.is_waiting = false;
    talk.says.clear();
    ui::panel::pick_talk_option(talk, ui::panel::kMarkAccept + 1401U, kStart);
    context.expect(talk.says.empty(), "dòng đang làm không gửi");
    ui::panel::pick_talk_option(talk, ui::panel::kMarkAccept + 1403U, kStart);
    context.expect(talk.says.empty(), "nút nộp không gửi Accept");
    ui::panel::pick_talk_option(talk, 3, kStart);
    const auto* chosen = last_say<tk::Choose>(talk);
    context.expect(chosen != nullptr && chosen->index == 3, "lựa chọn script vẫn là Choose");
}

constexpr std::array<Case, 20> kCases = {{
    {.name = "choice_goes_up_with_the_session", .body = choice_goes_up_with_the_session},
    {.name = "second_click_is_dropped_while_waiting", .body = second_click_is_dropped_while_waiting},
    {.name = "unknown_option_is_ignored", .body = unknown_option_is_ignored},
    {.name = "silent_server_unlocks_after_timeout", .body = silent_server_unlocks_after_timeout},
    {.name = "accept_only_in_offer_mode", .body = accept_only_in_offer_mode},
    {.name = "turn_in_waits_for_reward_choice", .body = turn_in_waits_for_reward_choice},
    {.name = "turn_in_without_radio_sends_no_reward", .body = turn_in_without_radio_sends_no_reward},
    {.name = "reward_choice_survives_a_same_session_update", .body = reward_choice_survives_a_same_session_update},
    {.name = "stale_close_is_ignored", .body = stale_close_is_ignored},
    {.name = "old_dialog_is_ignored", .body = old_dialog_is_ignored},
    {.name = "close_button_hangs_up", .body = close_button_hangs_up},
    {.name = "rejection_unlocks_and_explains", .body = rejection_unlocks_and_explains},
    {.name = "paint_lists_text_then_options", .body = paint_lists_text_then_options},
    {.name = "paint_while_closed_shows_nothing", .body = paint_while_closed_shows_nothing},
    {.name = "button_state_follows_mode", .body = button_state_follows_mode},
    {.name = "item_names_read_the_name_column", .body = item_names_read_the_name_column},
    {.name = "bag_paint_puts_the_icon_on_the_base_tab", .body = bag_paint_puts_the_icon_on_the_base_tab},
    {.name = "notices_prefer_server_text", .body = notices_prefer_server_text},
    {.name = "book_becomes_the_client_log", .body = book_becomes_the_client_log},
    {.name = "quest_mark_line_is_a_local_button", .body = quest_mark_line_is_a_local_button},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
