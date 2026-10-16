#include "ui/panel/logon.hpp"

#include "gui/content.hpp"
#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "LogOn_Frame";
constexpr std::string_view kClassicTab = "LogOn_TraditionLogon";
constexpr std::string_view kCustomTab = "LogOn_OwnDefineLogon";
constexpr std::string_view kHint = "LogOn_TiShi";
constexpr std::string_view kQrTab = "LogOn_ErweimaLogon";
constexpr std::string_view kCardCheck = "LogOn_PassWord_Protect_Check";
constexpr std::string_view kClassicEdit = "LogOn_ID";
constexpr std::string_view kCustomEdit = "LogOn_MailID";
constexpr std::string_view kPasswordEdit = "LogOn_PassWord";
constexpr std::string_view kSuffixList = "LogOn_Region";
// Cửa sổ con mà look của Combobox tự dựng: ô chữ, nút xổ (danh sách thả là kLogonSuffixList).
constexpr std::string_view kSuffixEdit = "LogOn_Region__auto_editbox__";
constexpr std::string_view kSuffixButton = "LogOn_Region__auto_button__";
// TailName của LogOn.lua: chín mục của danh sách đuôi, chữ Hán là chữ của script gốc. Mục 6 là đăng nhập bằng số điện
// thoại, mục 7 chuyển sang tên tự đặt, mục 8 là tên không đuôi.
constexpr std::array<std::string_view, 9> kSuffixes = {"@changyou.com", "@game.sohu.com", "@Sohu.com",
    "@chinaren.com", "@sogou.com", "@17173.com", "手机号码登录", "输入其他账号后缀", "无后缀账号登录"};
constexpr std::size_t kOtherSuffix = 7;
constexpr std::string_view kEnterButton = "LogOn_LogOnGame";
constexpr std::string_view kSituation = "SeverSituation_InfoWindow";

// MaxTextLength của layout: 50 ở LogOn_ID và LogOn_MailID, 32 ở LogOn_PassWord.
constexpr std::size_t kAccountLimit = 50;
constexpr std::size_t kPasswordLimit = 32;
// Dấu che của ô mật khẩu (TLBB_EditBoxSafe vẽ mỗi ký tự thành một dấu sao), đủ cho ô đầy.
constexpr std::string_view kMask = "********************************";
static_assert(kMask.size() == kPasswordLimit);

constexpr char32_t kBackspace = U'\b';
constexpr char32_t kTab = U'\t';
constexpr char32_t kEnter = U'\r';

// Giấu ở mọi kiểu tài khoản: khung WeGame, phần "đăng nhập bằng tài khoản khác", ba cửa sổ của
// bảng bản cũ (LogOn_Initilize) và hai lời nhắc Caps Lock (LogOn_KillCaplockTips).
constexpr std::array<std::string_view, 8> kNeverShown = {"LogOn_Wegame_Frame", "OtherLogon_Frame_ElseLogon",
    "OtherLogon_NewLogon", "OldLogOn_Input_Background_FrameImage", "OldLogOn_TraditionLogon", "OldLogOn_OwnDefineLogon",
    "LogOn_CapsLock1", "LogOn_CapsLock2"};
// Kiểu truyền thống giấu ô và nhãn của kiểu tự đặt cùng dòng nhắc; kiểu tự đặt giấu ô, đuôi và hai
// nhãn của kiểu truyền thống.
constexpr std::array<std::string_view, 3> kCustomOnly = {kCustomEdit, "LogOn_MailID_Text", kHint};
constexpr std::array<std::string_view, 4> kClassicOnly = {
    kClassicEdit, kSuffixList, "LogOn_ID_Text", "LogOn_Region_Text"};

// Nút nhờ client một việc ngay khi nhấn, không điều kiện: nạp thẻ (LogOn_AccountChongZhi), đăng ký
// (LogOn_AccountReg), quên mật khẩu (Logon_LostPassWord), thẻ bảo mật (LogOn_Show_MibaoPage), trợ
// giúp (Helper:GotoHelper) và quay lại (LogOn_ExitToSelectServer).
struct ButtonWork {
    std::string_view window;
    LogonAction action;
};

constexpr std::array<ButtonWork, 6> kButtonWorks = {{
    {.window = "LogOn_payment", .action = LogonAction::kOpenTopUp},
    {.window = "LogOn_RequisitionID", .action = LogonAction::kOpenRegister},
    {.window = "LogOn_Input_LostPassword", .action = LogonAction::kOpenLostPassword},
    {.window = "LogOn_mibaoka", .action = LogonAction::kOpenSecurityCard},
    {.window = "LogOn_Input_Help", .action = LogonAction::kOpenHelp},
    {.window = "LogOn_Last", .action = LogonAction::kLeave},
}};

[[nodiscard]] constexpr std::string_view flag(bool is_set) noexcept {
    return is_set ? std::string_view{"True"} : std::string_view{"False"};
}

// Ô field nhận phím. Sự kiện Activated của ô (LogOn_LogonID_Active, LogOn_LogonMailID_Active,
// LogOn_LogonPassWord_Active) đưa luôn ô ngắm của bàn phím ảo về chính ô đó.
void focus_on(Logon& logon, LogonField field) noexcept {
    logon.focus = field;
    logon.aim = field;
}

// LogOn_TraditionLogon_MouseDown và LogOn_OwnDefineLogon_MouseDown: kiểu đang chọn thì thoát sớm,
// kiểu mới thì đưa con nháy về ô tài khoản của nó.
void choose(Logon& logon, AccountKind kind) noexcept {
    if (logon.kind == kind) return;
    logon.kind = kind;
    // LogOn_TraditionLogon_MouseDown: về kiểu truyền thống thì mục "nhập đuôi khác" quay về mục 0.
    if (kind == AccountKind::kClassic && logon.suffix == kOtherSuffix) logon.suffix = 0;
    focus_on(logon, LogonField::kAccount);
}

void hide_all(Deck& deck, std::span<const std::string_view> windows) {
    for (const std::string_view window : windows) {
        deck.hide(window);
    }
}

// Tên tài khoản của kiểu đang chọn: mỗi kiểu gõ vào ô riêng của nó.
[[nodiscard]] std::string& name_of(Logon& logon) noexcept {
    return logon.kind == AccountKind::kClassic ? logon.account : logon.mail;
}

// LogOn_CheckAccount: thiếu tên hay mật khẩu thì thôi, đủ thì nhờ client kiểm tài khoản.
void check_account(Logon& logon) noexcept {
    if (name_of(logon).empty() || logon.password.empty()) return;
    logon.request = LogonAction::kEnterGame;
}

void press_button(Logon& logon, std::string_view window) noexcept {
    if (window == kEnterButton) check_account(logon);
    const auto found = std::ranges::find(kButtonWorks, window, &ButtonWork::window);
    if (found != kButtonWorks.end()) logon.request = found->action;
}

// Chữ của một ô nhập và số ký tự nó chứa được.
struct TypedBox {
    std::string* text = nullptr;
    std::size_t limit = 0;
};

[[nodiscard]] TypedBox box_of(Logon& logon, LogonField field) noexcept {
    if (field == LogonField::kPassword) return {.text = &logon.password, .limit = kPasswordLimit};
    return {.text = &name_of(logon), .limit = kAccountLimit};
}

// Logon_ID_TabPressed và Logon_Password_TabPressed: Tab đổi qua lại giữa ô tài khoản và ô mật khẩu.
void switch_box(Logon& logon) noexcept {
    const bool is_on_account = logon.focus == LogonField::kAccount;
    focus_on(logon, is_on_account ? LogonField::kPassword : LogonField::kAccount);
}

// TextAccepted: Enter ở ô tài khoản sang ô mật khẩu (Logon_LogOn_ID_Return), Enter ở ô mật khẩu là
// kiểm tài khoản (Logon_Password_Return).
void accept_text(Logon& logon) noexcept {
    const bool was_on_password = logon.focus == LogonField::kPassword;
    focus_on(logon, LogonField::kPassword);
    if (was_on_password) check_account(logon);
}

// Ký tự in được nối vào ô trong trần của nó, xoá lùi bỏ ký tự cuối; mã khác không đổi gì.
void edit_box(const TypedBox& box, char32_t code) {
    const bool is_printable = code >= U' ' && code <= U'~';
    if (code == kBackspace && !box.text->empty()) box.text->pop_back();
    if (is_printable && box.text->size() < box.limit) box.text->push_back(static_cast<char>(code));
}

// Nhận mục index của danh sách đuôi (ComboDropList::EventListSelectionAccepted): đổi chữ ô đuôi, đóng danh sách, rồi
// LogOn_Region_Accept đổi sang tên tự đặt khi là mục 7.
void accept_suffix(Logon& logon, std::size_t index) noexcept {
    logon.drop = DropList{};
    logon.suffix = std::min(index, kSuffixes.size() - 1);
    if (logon.suffix == kOtherSuffix) choose(logon, AccountKind::kCustom);
}

// Cửa sổ của danh sách thả: chính nó hay con của nó (thanh cuộn).
[[nodiscard]] bool is_in_drop_list(std::string_view window) noexcept {
    return window.starts_with(kLogonSuffixList);
}

// Combobox::button_PressHandler và editbox_MouseDownHandler: mở danh sách, mục đang chọn sáng sẵn.
void open_suffix_list(Logon& logon, bool is_from_text) noexcept {
    logon.drop = DropList{.is_open = true, .is_armed = false, .is_opening = is_from_text, .lit = logon.suffix};
}

} // namespace

void open_logon(Logon& logon) noexcept {
    focus_on(logon, LogonField::kAccount);
    logon.uses_card = false;
    logon.request.reset();
}

void press_suffix_list(Logon& logon, std::string_view window, std::optional<std::size_t> row) {
    if (!logon.drop.is_open) return;
    if (!is_in_drop_list(window)) {
        // ComboDropList::onMouseButtonDown ngoài danh sách: bỏ mục sáng và trả chuột; mục chọn cuối giữ nguyên.
        logon.drop = DropList{};
        return;
    }
    logon.drop.lit = window == kLogonSuffixList ? row : std::nullopt;
    logon.drop.is_armed = true;
}

void release_suffix_list(Logon& logon, std::string_view window) {
    DropList& drop = logon.drop;
    if (!drop.is_open) return;
    const bool is_on_bar = is_in_drop_list(window) && window != kLogonSuffixList;
    const bool was_opening = std::exchange(drop.is_opening, false);
    if (!drop.is_armed || is_on_bar || was_opening) {
        drop.is_armed = true;
        return;
    }
    if (drop.lit) {
        accept_suffix(logon, *drop.lit);
        return;
    }
    drop = DropList{};
}

void move_suffix_list(Logon& logon, std::string_view window, std::optional<std::size_t> row, bool is_down) {
    DropList& drop = logon.drop;
    if (!drop.is_open) return;
    if (!is_in_drop_list(window)) {
        if (is_down) drop.lit.reset();
        return;
    }
    if (window == kLogonSuffixList && drop.is_armed) drop.lit = row;
}

void dismiss_suffix_list(Logon& logon) noexcept {
    logon.drop = DropList{};
}

void press_logon(Logon& logon, std::string_view window) noexcept {
    const bool is_back_to_classic = window == kHint || window == kQrTab;
    if (window == kClassicTab || is_back_to_classic) choose(logon, AccountKind::kClassic);
    if (window == kCustomTab) choose(logon, AccountKind::kCustom);
    if (window == kCardCheck) logon.uses_card = !logon.uses_card;
    const bool is_account_edit = window == kClassicEdit || window == kCustomEdit;
    if (is_account_edit || is_back_to_classic) focus_on(logon, LogonField::kAccount);
    if (window == kPasswordEdit) focus_on(logon, LogonField::kPassword);
    // LogOn_KeyBoard: SetSoftKeyAim("LogOn_PassWord") sau khi bật tắt bàn phím ảo.
    if (window == kLogonKeysButton) logon.aim = LogonField::kPassword;
    if (window == kSuffixButton) open_suffix_list(logon, false);
    if (window == kSuffixEdit) open_suffix_list(logon, true);
    press_button(logon, window);
}

void type_logon(Logon& logon, char32_t code) {
    const TypedBox box = box_of(logon, logon.focus);
    if (code == kTab) switch_box(logon);
    if (code == kEnter) accept_text(logon);
    edit_box(box, code);
}

void key_logon(Logon& logon, char32_t code) {
    const TypedBox box = box_of(logon, logon.aim);
    edit_box(box, code);
}

std::optional<LogonAction> take_request(Logon& logon) noexcept {
    return std::exchange(logon.request, std::nullopt);
}

namespace {

// Danh sách thả: chỉ hiện khi mở (cửa sổ tự dựng của look ẩn từ đầu), kèm chín mục và mục đang sáng.
void paint_suffix_list(Deck& deck, const Logon& logon) {
    if (!logon.drop.is_open) return;
    deck.reveal(kLogonSuffixList);
    std::string& items = deck.compose(Key{.window = kLogonSuffixList, .name = gui::kItemsProperty});
    for (const std::string_view suffix : kSuffixes) {
        if (!items.empty()) items += gui::kRecordMark;
        items += gui::kFieldMark;
        items += suffix;
    }
    if (!logon.drop.lit) return;
    deck.set(gui::Override{.window = kLogonSuffixList,
        .name = gui::kSelectedProperty,
        .value = std::to_string(*logon.drop.lit)});
}

} // namespace

void paint_logon(Deck& deck, const Logon& logon) {
    const bool is_classic = logon.kind == AccountKind::kClassic;
    const bool is_on_account = logon.focus == LogonField::kAccount;
    const std::string_view masked = kMask.substr(0, logon.password.size());
    deck.show(kRoot);
    hide_all(deck, kNeverShown);
    if (is_classic) hide_all(deck, kCustomOnly);
    if (!is_classic) hide_all(deck, kClassicOnly);
    deck.set(gui::Override{.window = kClassicTab, .name = "Selected", .value = flag(is_classic)});
    deck.set(gui::Override{.window = kCustomTab, .name = "Selected", .value = flag(!is_classic)});
    deck.set(gui::Override{.window = kCardCheck, .name = "Selected", .value = flag(logon.uses_card)});
    deck.set(gui::Override{.window = kClassicEdit, .name = "Caret", .value = flag(is_classic && is_on_account)});
    deck.set(gui::Override{.window = kCustomEdit, .name = "Caret", .value = flag(!is_classic && is_on_account)});
    deck.set(gui::Override{.window = kPasswordEdit, .name = "Caret", .value = flag(!is_on_account)});
    deck.set(gui::Override{.window = kClassicEdit, .name = "Text", .value = logon.account});
    deck.set(gui::Override{.window = kCustomEdit, .name = "Text", .value = logon.mail});
    deck.set(gui::Override{.window = kPasswordEdit, .name = "Text", .value = masked});
    deck.set(gui::Override{.window = kSuffixEdit, .name = "Text", .value = kSuffixes.at(logon.suffix)});
    paint_suffix_list(deck, logon);
    deck.set(gui::Override{.window = kSituation, .name = "Text", .value = logon.situation});
}

} // namespace game::ui::panel
