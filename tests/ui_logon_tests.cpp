// Bảng nhập tài khoản (ui/panel/logon): trạng thái lúc mở, sau từng lần nhấn và từng phím phải đúng
// những lời gọi Show, Hide, SetCheck, SetText mà LogOn.lua bản 2026 thực hiện; mỗi nút nhờ client
// đúng việc script gốc gọi qua GameProduceLogin; và mọi tên cửa sổ bảng nêu đều có thật trong layout
// của client 2026.
#include "ui/panel/logon.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using ui::panel::AccountKind;
using ui::panel::Deck;
using ui::panel::Logon;
using ui::panel::LogonAction;
using ui::panel::LogonField;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca đối chiếu layout thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";

// Cửa sổ script giấu ở mọi kiểu tài khoản khi không phải client WeGame.
constexpr std::array<std::string_view, 8> kNeverShown = {"LogOn_Wegame_Frame", "OtherLogon_Frame_ElseLogon",
    "OtherLogon_NewLogon", "OldLogOn_Input_Background_FrameImage", "OldLogOn_TraditionLogon", "OldLogOn_OwnDefineLogon",
    "LogOn_CapsLock1", "LogOn_CapsLock2"};
// Cửa sổ chỉ của kiểu tài khoản truyền thống, và chỉ của kiểu tự đặt.
constexpr std::array<std::string_view, 4> kClassicOnly = {
    "LogOn_ID", "LogOn_Region", "LogOn_ID_Text", "LogOn_Region_Text"};
constexpr std::array<std::string_view, 3> kCustomOnly = {"LogOn_MailID", "LogOn_MailID_Text", "LogOn_TiShi"};

// Giá trị cuối cùng đặt cho một thuộc tính trong khung này; nullopt khi bảng không đặt.
std::optional<std::string_view> said(Deck& deck, std::string_view window, std::string_view name) {
    std::optional<std::string_view> value;
    for (const gui::Override& item : deck.overrides()) {
        const bool is_mine = item.window == window && item.name == name;
        value = is_mine ? std::optional(item.value) : value;
    }
    return value;
}

bool is_hidden(const Deck& deck, std::string_view window) {
    return std::ranges::contains(deck.hidden(), window);
}

bool all_hidden(const Deck& deck, std::span<const std::string_view> windows) {
    return std::ranges::all_of(windows, [&deck](std::string_view window) { return is_hidden(deck, window); });
}

bool none_hidden(const Deck& deck, std::span<const std::string_view> windows) {
    return std::ranges::none_of(windows, [&deck](std::string_view window) { return is_hidden(deck, window); });
}

Deck painted(const Logon& logon) {
    Deck deck;
    ui::panel::paint_logon(deck, logon);
    return deck;
}

// GAMELOGIN_OPEN_COUNT_INPUT với g_AccountType bằng 1: LogOn_Initilize gọi
// LogOn_TraditionLogon_MouseDown rồi LogOn_LogonID_Active.
void opens_on_classic_account(Context& context) {
    Logon logon;
    logon.focus = LogonField::kPassword;
    logon.uses_card = true;
    ui::panel::open_logon(logon);
    context.expect(logon.kind == AccountKind::kClassic, "kiểu tài khoản đầu tiên là truyền thống");
    context.expect(logon.focus == LogonField::kAccount, "mở bảng thì ô tài khoản nhận phím");
    context.expect(!logon.uses_card, "Game_MiBao chưa lưu thì ô thẻ bảo mật bỏ trống");
    Deck deck = painted(logon);
    context.expect(deck.is_shown("LogOn_Frame"), "gốc của bảng được kê");
    context.expect(all_hidden(deck, kNeverShown), "khung WeGame, bản cũ và lời nhắc Caps Lock bị giấu");
    context.expect(all_hidden(deck, kCustomOnly), "ô và nhãn của kiểu tự đặt bị giấu");
    context.expect(none_hidden(deck, kClassicOnly), "ô, nhãn và đuôi của kiểu truyền thống còn hiện");
    context.expect(said(deck, "LogOn_TraditionLogon", "Selected") == kTrue, "thẻ truyền thống đang chọn");
    context.expect(said(deck, "LogOn_OwnDefineLogon", "Selected") == kFalse, "thẻ tự đặt không chọn");
    context.expect(said(deck, "LogOn_PassWord_Protect_Check", "Selected") == kFalse, "ô thẻ bảo mật trống");
    context.expect(said(deck, "LogOn_ID", "Caret") == kTrue, "con nháy ở ô tài khoản");
    context.expect(said(deck, "LogOn_PassWord", "Caret") == kFalse, "ô mật khẩu không có con nháy");
    context.expect(said(deck, "LogOn_Region", "Text") == "@changyou.com", "đuôi đầu tiên của TailName");
}

// LogOn_OwnDefineLogon_MouseDown: đổi ô tài khoản, giấu đuôi, hiện dòng nhắc quay lại.
void custom_tab_swaps_fields(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    logon.focus = LogonField::kPassword;
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    context.expect(logon.kind == AccountKind::kCustom, "nhấn thẻ tự đặt thì sang kiểu tự đặt");
    context.expect(logon.focus == LogonField::kAccount, "đổi kiểu thì ô tài khoản nhận phím");
    Deck deck = painted(logon);
    context.expect(all_hidden(deck, kClassicOnly), "ô, nhãn và đuôi của kiểu truyền thống bị giấu");
    context.expect(none_hidden(deck, kCustomOnly), "ô, nhãn và dòng nhắc của kiểu tự đặt hiện");
    context.expect(all_hidden(deck, kNeverShown), "phần luôn giấu vẫn giấu");
    context.expect(said(deck, "LogOn_TraditionLogon", "Selected") == kFalse, "thẻ truyền thống thôi chọn");
    context.expect(said(deck, "LogOn_OwnDefineLogon", "Selected") == kTrue, "thẻ tự đặt đang chọn");
    context.expect(said(deck, "LogOn_MailID", "Caret") == kTrue, "con nháy ở ô tài khoản tự đặt");
    context.expect(said(deck, "LogOn_ID", "Caret") == kFalse, "ô truyền thống không có con nháy");
}

// Thẻ của kiểu đang chọn thoát sớm (g_AccountType không đổi): ô đang nhận phím giữ nguyên.
void same_tab_keeps_focus(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::press_logon(logon, "LogOn_PassWord");
    context.expect(logon.focus == LogonField::kPassword, "nhấn ô mật khẩu thì nó nhận phím");
    ui::panel::press_logon(logon, "LogOn_TraditionLogon");
    context.expect(logon.focus == LogonField::kPassword, "thẻ đang chọn không dời con nháy");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    ui::panel::press_logon(logon, "LogOn_PassWord");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    context.expect(logon.kind == AccountKind::kCustom, "vẫn là kiểu tự đặt");
    context.expect(logon.focus == LogonField::kPassword, "thẻ tự đặt đang chọn cũng không dời con nháy");
    ui::panel::press_logon(logon, "LogOn_MailID");
    context.expect(logon.focus == LogonField::kAccount, "nhấn ô tài khoản tự đặt thì nó nhận phím");
}

// LogOn_TiShi_Clicked và LogOn_ErweimaLogon_MouseDown: về kiểu truyền thống rồi luôn gọi
// LogOn_LogonID_Active, kể cả khi đang là kiểu truyền thống.
void hint_and_qr_return_to_classic(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    ui::panel::press_logon(logon, "LogOn_TiShi");
    context.expect(logon.kind == AccountKind::kClassic, "dòng nhắc đưa về kiểu truyền thống");
    ui::panel::press_logon(logon, "LogOn_PassWord");
    ui::panel::press_logon(logon, "LogOn_ErweimaLogon");
    context.expect(logon.kind == AccountKind::kClassic, "thẻ mã QR giữ kiểu truyền thống");
    context.expect(logon.focus == LogonField::kAccount, "thẻ mã QR đưa con nháy về ô tài khoản");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    ui::panel::press_logon(logon, "LogOn_ErweimaLogon");
    context.expect(logon.kind == AccountKind::kClassic, "thẻ mã QR đưa kiểu tự đặt về truyền thống");
}

void card_check_toggles(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::press_logon(logon, "LogOn_PassWord_Protect_Check");
    context.expect(logon.uses_card, "nhấn ô thẻ bảo mật thì đánh dấu");
    Deck deck = painted(logon);
    context.expect(said(deck, "LogOn_PassWord_Protect_Check", "Selected") == kTrue, "ô vẽ ở trạng thái chọn");
    ui::panel::press_logon(logon, "LogOn_PassWord_Protect_Check");
    context.expect(!logon.uses_card, "nhấn lần nữa thì bỏ dấu");
}

// Cửa sổ không phải của bảng thì trạng thái giữ nguyên.
void other_windows_change_nothing(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::press_logon(logon, "LogOn_PassWord");
    ui::panel::press_logon(logon, "LogOn_Input_Background_FrameImage");
    ui::panel::press_logon(logon, "Button_Character");
    context.expect(logon.kind == AccountKind::kClassic, "kiểu tài khoản không đổi");
    context.expect(logon.focus == LogonField::kPassword, "ô đang nhận phím không đổi");
    context.expect(!logon.uses_card, "ô thẻ bảo mật không đổi");
}

void type_text(Logon& logon, std::string_view text) {
    for (const char letter : text) {
        ui::panel::type_logon(logon, static_cast<char32_t>(letter));
    }
}

constexpr char32_t kTab = U'\t';
constexpr char32_t kEnter = U'\r';
constexpr char32_t kBackspace = U'\b';

// Chữ gõ vào ô đang nhận phím; Tab đổi ô (Logon_ID_TabPressed, Logon_Password_TabPressed); mật khẩu
// vẽ bằng dấu sao (TLBB_EditBoxSafe).
void typing_fills_the_focused_box(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    type_text(logon, "thieuhiep");
    ui::panel::type_logon(logon, kTab);
    context.expect(logon.focus == LogonField::kPassword, "Tab ở ô tài khoản sang ô mật khẩu");
    type_text(logon, "abc12");
    ui::panel::type_logon(logon, kBackspace);
    context.expect(logon.account == "thieuhiep" && logon.password == "abc1", "chữ vào đúng ô, xoá lùi một ký tự");
    Deck deck = painted(logon);
    context.expect(said(deck, "LogOn_ID", "Text") == "thieuhiep", "ô tài khoản hiện chữ đã gõ");
    context.expect(said(deck, "LogOn_PassWord", "Text") == "****", "ô mật khẩu hiện dấu sao");
    ui::panel::type_logon(logon, kTab);
    context.expect(logon.focus == LogonField::kAccount, "Tab ở ô mật khẩu về ô tài khoản");
    ui::panel::type_logon(logon, U'\x1b');
    ui::panel::type_logon(logon, U'\u1ea1');
    context.expect(logon.account == "thieuhiep", "phím điều khiển và chữ ngoài ASCII in được bị bỏ");
    ui::panel::type_logon(logon, kBackspace);
    context.expect(logon.account == "thieuhie", "xoá lùi ở ô tài khoản");
    Logon empty;
    ui::panel::type_logon(empty, kBackspace);
    context.expect(empty.account.empty(), "xoá lùi ở ô rỗng không làm gì");
}

// MaxTextLength của layout: 50 ở hai ô tài khoản, 32 ở ô mật khẩu. Kiểu tự đặt gõ vào LogOn_MailID.
void typing_respects_the_box_limits(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    const std::string long_text(60, 'a');
    type_text(logon, long_text);
    context.expect(logon.account.size() == 50, "ô tài khoản nhận tối đa 50 ký tự");
    ui::panel::press_logon(logon, "LogOn_PassWord");
    type_text(logon, long_text);
    context.expect(logon.password.size() == 32, "ô mật khẩu nhận tối đa 32 ký tự");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    type_text(logon, "ten@thu.vn");
    context.expect(logon.mail == "ten@thu.vn" && logon.account.size() == 50, "kiểu tự đặt gõ vào ô của nó");
    Deck deck = painted(logon);
    context.expect(said(deck, "LogOn_MailID", "Text") == "ten@thu.vn", "ô tự đặt hiện chữ đã gõ");
}

// LogOn_CheckAccount: thiếu tài khoản hay mật khẩu thì thôi; đủ thì nhờ client vào game. Enter ở ô
// tài khoản sang ô mật khẩu (Logon_LogOn_ID_Return), Enter ở ô mật khẩu là kiểm tài khoản
// (Logon_Password_Return).
void enter_game_needs_account_and_password(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::press_logon(logon, "LogOn_LogOnGame");
    context.expect(!ui::panel::take_request(logon), "chưa gõ gì thì nút vào game không làm gì");
    type_text(logon, "thieuhiep");
    ui::panel::press_logon(logon, "LogOn_LogOnGame");
    context.expect(!ui::panel::take_request(logon), "thiếu mật khẩu thì thôi");
    ui::panel::type_logon(logon, kEnter);
    context.expect(logon.focus == LogonField::kPassword, "Enter ở ô tài khoản sang ô mật khẩu");
    context.expect(!ui::panel::take_request(logon), "Enter ở ô tài khoản chưa kiểm tài khoản");
    type_text(logon, "matkhau");
    ui::panel::type_logon(logon, kEnter);
    context.expect(ui::panel::take_request(logon) == LogonAction::kEnterGame, "Enter ở ô mật khẩu vào game");
    context.expect(!ui::panel::take_request(logon), "việc đã lấy thì không còn");
    ui::panel::press_logon(logon, "LogOn_LogOnGame");
    context.expect(ui::panel::take_request(logon) == LogonAction::kEnterGame, "nút vào game khi đã đủ hai ô");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    ui::panel::press_logon(logon, "LogOn_LogOnGame");
    context.expect(!ui::panel::take_request(logon), "kiểu tự đặt chưa gõ tên thì thôi");
}

struct ButtonWork {
    std::string_view window;
    LogonAction action;
};

// Mỗi nút và việc script gốc gọi: LogOn_AccountChongZhi, LogOn_AccountReg, Logon_LostPassWord,
// LogOn_Show_MibaoPage, Helper:GotoHelper, LogOn_ExitToSelectServer.
constexpr std::array<ButtonWork, 6> kButtonWorks = {{
    {.window = "LogOn_payment", .action = LogonAction::kOpenTopUp},
    {.window = "LogOn_RequisitionID", .action = LogonAction::kOpenRegister},
    {.window = "LogOn_Input_LostPassword", .action = LogonAction::kOpenLostPassword},
    {.window = "LogOn_mibaoka", .action = LogonAction::kOpenSecurityCard},
    {.window = "LogOn_Input_Help", .action = LogonAction::kOpenHelp},
    {.window = "LogOn_Last", .action = LogonAction::kLeave},
}};

void buttons_ask_the_client(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    for (const ButtonWork& work : kButtonWorks) {
        ui::panel::press_logon(logon, work.window);
        context.expect(ui::panel::take_request(logon) == work.action, work.window);
    }
    ui::panel::press_logon(logon, "LogOn_TraditionLogon");
    context.expect(!ui::panel::take_request(logon), "thẻ kiểu tài khoản không nhờ client việc gì");
    ui::panel::press_logon(logon, "LogOn_payment");
    ui::panel::open_logon(logon);
    context.expect(!ui::panel::take_request(logon), "mở lại bảng thì bỏ việc chưa lấy");
}

// SetSoftKeyAim: mở bảng và mỗi lần một ô nhận phím thì ô ngắm về ô đó; nút bàn phím ảo đưa ô ngắm
// về ô mật khẩu mà con nháy ở nguyên chỗ.
void keys_button_aims_at_the_password(Context& context) {
    Logon logon;
    logon.aim = LogonField::kPassword;
    ui::panel::open_logon(logon);
    context.expect(logon.aim == LogonField::kAccount, "mở bảng thì bàn phím ảo ngắm ô tài khoản");
    ui::panel::press_logon(logon, ui::panel::kLogonKeysButton);
    context.expect(logon.aim == LogonField::kPassword, "nút bàn phím ảo đưa ô ngắm về ô mật khẩu");
    context.expect(logon.focus == LogonField::kAccount, "nút bàn phím ảo không đổi ô nhận phím");
    context.expect(!ui::panel::take_request(logon), "nút bàn phím ảo không nhờ client việc gì");
    ui::panel::press_logon(logon, "LogOn_ID");
    context.expect(logon.aim == LogonField::kAccount, "nhấn ô tài khoản thì ô ngắm theo về");
    ui::panel::type_logon(logon, kTab);
    context.expect(logon.aim == LogonField::kPassword, "Tab sang ô mật khẩu thì ô ngắm theo sang");
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    context.expect(logon.aim == LogonField::kAccount, "đổi kiểu tài khoản thì ô ngắm về ô tài khoản");
}

// FalagardSoftKeyBoard::onMouseButtonUp: ký tự và xoá lùi đi thẳng vào ô ngắm, ô nhận phím giữ nguyên.
void soft_keys_edit_the_aimed_box(Context& context) {
    Logon logon;
    ui::panel::open_logon(logon);
    ui::panel::key_logon(logon, U'a');
    context.expect(logon.account == "a", "ô ngắm đầu tiên là ô tài khoản");
    ui::panel::press_logon(logon, ui::panel::kLogonKeysButton);
    ui::panel::key_logon(logon, U'x');
    ui::panel::key_logon(logon, U'9');
    context.expect(logon.password == "x9" && logon.account == "a", "sau nút bàn phím ảo thì gõ vào ô mật khẩu");
    context.expect(logon.focus == LogonField::kAccount, "gõ bằng bàn phím ảo không dời con nháy");
    ui::panel::key_logon(logon, kBackspace);
    context.expect(logon.password == "x", "xoá lùi bỏ ký tự cuối của ô ngắm");
    ui::panel::key_logon(logon, kTab);
    ui::panel::key_logon(logon, kEnter);
    context.expect(logon.aim == LogonField::kPassword && logon.password == "x", "mã khác bị bỏ");
    context.expect(!ui::panel::take_request(logon), "bàn phím ảo không tự kiểm tài khoản");
    for (int count = 0; count < 40; ++count) {
        ui::panel::key_logon(logon, U'z');
    }
    context.expect(logon.password.size() == 32, "ô mật khẩu giữ trần 32 ký tự với bàn phím ảo");
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

// Mỗi tên trong chỉ thị của deck phải là một cửa sổ của layout.
void expect_names(Context& context, const gui::GuiAsset& asset, Deck& deck) {
    for (const std::string_view root : deck.roots()) {
        context.expect(has_window(asset, root), root);
    }
    for (const std::string_view window : deck.hidden()) {
        context.expect(has_window(asset, window), window);
    }
    for (const gui::Override& item : deck.overrides()) {
        context.expect(has_window(asset, item.window), item.window);
    }
}

// Cửa sổ mà press_logon nghe ngoài các nút của kButtonWorks.
constexpr std::array<std::string_view, 9> kPressed = {"LogOn_TraditionLogon", "LogOn_OwnDefineLogon", "LogOn_TiShi",
    "LogOn_ErweimaLogon", "LogOn_PassWord_Protect_Check", "LogOn_PassWord", "LogOn_MailID", "LogOn_LogOnGame",
    ui::panel::kLogonKeysButton};

// Mọi cửa sổ bảng nêu (kê, giấu hay đặt thuộc tính) phải có thật trong layout của kho, ở cả hai
// kiểu tài khoản: gõ sai một tên thì chỉ thị đó mất mà không báo gì.
void names_exist_in_layout(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    const auto added = loader->add_layout(ui::panel::kLogonLayout);
    context.expect(added.has_value(), "nạp được layout bảng nhập tài khoản");
    Logon logon;
    ui::panel::open_logon(logon);
    Deck classic = painted(logon);
    context.expect(classic.hidden().size() >= kNeverShown.size() + kCustomOnly.size(), "bảng giấu đủ số cửa sổ");
    expect_names(context, loader->asset(), classic);
    ui::panel::press_logon(logon, "LogOn_OwnDefineLogon");
    Deck custom = painted(logon);
    expect_names(context, loader->asset(), custom);
    for (const std::string_view window : kPressed) {
        context.expect(has_window(loader->asset(), window), window);
    }
    for (const ButtonWork& work : kButtonWorks) {
        context.expect(has_window(loader->asset(), work.window), work.window);
    }
}

constexpr std::array kCases{
    Case{.name = "opens_on_classic_account", .body = &opens_on_classic_account},
    Case{.name = "custom_tab_swaps_fields", .body = &custom_tab_swaps_fields},
    Case{.name = "same_tab_keeps_focus", .body = &same_tab_keeps_focus},
    Case{.name = "hint_and_qr_return_to_classic", .body = &hint_and_qr_return_to_classic},
    Case{.name = "card_check_toggles", .body = &card_check_toggles},
    Case{.name = "other_windows_change_nothing", .body = &other_windows_change_nothing},
    Case{.name = "typing_fills_the_focused_box", .body = &typing_fills_the_focused_box},
    Case{.name = "typing_respects_the_box_limits", .body = &typing_respects_the_box_limits},
    Case{.name = "enter_game_needs_account_and_password", .body = &enter_game_needs_account_and_password},
    Case{.name = "buttons_ask_the_client", .body = &buttons_ask_the_client},
    Case{.name = "keys_button_aims_at_the_password", .body = &keys_button_aims_at_the_password},
    Case{.name = "soft_keys_edit_the_aimed_box", .body = &soft_keys_edit_the_aimed_box},
    Case{.name = "names_exist_in_layout", .body = &names_exist_in_layout},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_logon_tests: mọi ca phải qua");
    return 0;
}
