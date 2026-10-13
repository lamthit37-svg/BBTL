// Bảng nhập tài khoản (LoginLogOn, layout Logon/LogOn.layout.xml) của thủ tục đăng nhập: cửa sổ
// nào hiện, thẻ kiểu tài khoản nào đang chọn, ô nào đang nhận phím, chữ đã gõ vào ba ô, và việc
// mỗi nút nhờ client làm. Client gốc mở bảng bằng sự kiện GAMELOGIN_OPEN_COUNT_INPUT; script của nó
// đổi kiểu tài khoản khi nhấn hai thẻ và gọi GameProduceLogin khi nhấn các nút. Bảng ở đây chỉ là
// trạng thái: việc phải làm ngoài bảng (vào game, mở trang web, rời bảng) nằm chờ ở Logon::request
// cho client lấy bằng take_request.
// Nguồn: Interface/Logon/LogOn.lua của client 2026, giải bằng TOOLS/content/lua_plain.py
// (LoginLogOn_OnEvent 233, LogOn_Initilize 382, LogOn_ExitToSelectServer 419, LogOn_CheckAccount
// 430, LogOn_AccountReg 523, Logon_ID_TabPressed 530, Logon_LogOn_ID_Return 546,
// Logon_Password_TabPressed 566, Logon_Password_Return 578, LogOn_LogonID_Active 665,
// LogOn_LogonPassWord_Active 721, Logon_LostPassWord 756, LogOn_AccountChongZhi 762,
// LogOn_Show_MibaoPage 772, PassWordProtectCheckClicked 782, LogOn_TraditionLogon_MouseDown 874,
// LogOn_OwnDefineLogon_MouseDown 912, LogOn_TiShi_Clicked 950, LogOn_ErweimaLogon_MouseDown 959;
// ô ngắm của bàn phím ảo là SetSoftKeyAim ở LoginLogOn_OnEvent 297, LogOn_KeyBoard 623 và ba hàm
// Active 665, 679, 721).
// SystemSetup:IsClassic luôn trả 1 (Game.exe 0x14045fbb0), nên ba nhãn đổi theo kiểu tài khoản.
// Khác gốc: đi nhánh không phải client WeGame (IsWeGameClient bằng 0); ô nhập chỉ nhận ASCII in
// được (chưa có IME, chọn vùng, dán, cuộn ngang); chưa có danh sách đuôi tài khoản,
// lời nhắc Caps Lock, tooltip và mã QR; kiểu tài khoản và
// ô thẻ bảo mật chưa lưu giữa hai lần chạy (Account_LogonType, Game_MiBao), nên lần nào cũng mở ở
// kiểu truyền thống. Dòng chữ LogOn_Info không port: khung chứa nó ẩn trong layout và script không
// bao giờ hiện.
#pragma once

#include "ui/panel/deck.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

// Layout của bảng, đường dẫn tương đối với thư mục Interface.
inline constexpr std::string_view kLogonLayout = "Logon/LogOn.layout.xml";
// Nút bàn phím ảo của bảng: LogOn_KeyBoard gọi ToggleWindow("SoftKeyBoard"), việc đó là của người
// gọi (ui/panel/softkey.hpp); bảng chỉ đổi ô ngắm.
inline constexpr std::string_view kLogonKeysButton = "LogOn_Keyboard";

// g_AccountType của script: 1 là tên truyền thống kèm đuôi chọn trong danh sách, 2 là tên tự đặt.
enum class AccountKind : std::uint8_t { kClassic, kCustom };

// Ô đang nhận phím (thuộc tính DefaultEditBox mà script bật cho đúng một ô).
enum class LogonField : std::uint8_t { kAccount, kPassword };

// Việc bảng nhờ client làm, mỗi mục là một lời gọi của script gốc: kEnterGame là
// GameProduceLogin:CheckAccount; bốn mục kOpen đầu là OpenURL với trang nạp thẻ (WEB_LOGON_VN), trang
// đăng ký (StartAccountReg), trang quên mật khẩu (WEB_FORGOTPASSWORD), trang thẻ bảo mật
// (WEB_MIBAO); kOpenHelp là Helper:GotoHelper("*LoginLogOn"); kOpenForum là diễn đàn của menu
// hệ thống (WEB_TLLUNTAN, chưa có URL); kLeave là ExitToSelectServer.
enum class LogonAction : std::uint8_t {
    kEnterGame,
    kOpenTopUp,
    kOpenRegister,
    kOpenLostPassword,
    kOpenSecurityCard,
    kOpenHelp,
    kOpenForum,
    kLeave,
};

struct Logon {
    AccountKind kind = AccountKind::kClassic;
    LogonField focus = LogonField::kAccount;
    // Ô bàn phím ảo gõ vào (SetSoftKeyAim): đi theo ô nhận phím mỗi khi ô đó đổi; riêng nút bàn
    // phím ảo đưa nó về ô mật khẩu mà không đổi ô nhận phím.
    LogonField aim = LogonField::kAccount;
    // Ô đánh dấu LogOn_PassWord_Protect_Check: đăng nhập kèm thẻ bảo mật.
    bool uses_card = false;
    // Chữ đã gõ: tên truyền thống (LogOn_ID), tên tự đặt (LogOn_MailID) và mật khẩu.
    std::string account;
    std::string mail;
    std::string password;
    // Dòng "sắp đăng nhập: <máy chủ>" (SeverSituation_InfoWindow): chuỗi thủ tục đăng nhập dựng khi
    // chọn xong máy chủ; rỗng thì dòng ấy trống.
    std::string situation;
    // Việc lần nhấn hay phím gần nhất nhờ client làm, chờ take_request lấy.
    std::optional<LogonAction> request;
};

// Mở bảng: giữ kiểu tài khoản và chữ đã gõ, đưa con nháy và ô ngắm về ô tài khoản, bỏ dấu ô thẻ
// bảo mật và việc chưa lấy.
void open_logon(Logon& logon) noexcept;
// Một lần nhấn trái lên cửa sổ window: hai thẻ kiểu tài khoản, dòng nhắc, thẻ mã QR, ô thẻ bảo mật,
// ba ô nhập, nút bàn phím ảo (ô ngắm về ô mật khẩu), và các nút nhờ client (vào game chỉ khi tài
// khoản và mật khẩu đều đã gõ). Cửa sổ khác không đổi gì.
void press_logon(Logon& logon, std::string_view window) noexcept;
// Một ký tự từ bàn phím cho ô đang nhận phím: ASCII in được thì nối vào (trần của ô theo
// MaxTextLength của layout), xoá lùi bỏ ký tự cuối, Tab đổi ô, Enter ở ô tài khoản sang ô mật khẩu
// và ở ô mật khẩu là kiểm tài khoản như nút vào game. Mã khác bị bỏ.
void type_logon(Logon& logon, char32_t code);
// Một phím của bàn phím ảo cho ô đang ngắm, không đổi ô nhận phím (FalagardSoftKeyBoard gọi thẳng
// addCharater và handleBackspace của ô ngắm): ASCII in được thì nối vào trong trần của ô, xoá lùi
// bỏ ký tự cuối. Mã khác bị bỏ.
void key_logon(Logon& logon, char32_t code);
// Lấy việc đang chờ; lấy rồi thì hết.
[[nodiscard]] std::optional<LogonAction> take_request(Logon& logon) noexcept;
// Tên tài khoản đang gõ: ô truyền thống hay ô tự đặt, theo thẻ đang chọn.
[[nodiscard]] inline std::string_view account_text(const Logon& logon) noexcept {
    if (logon.kind == AccountKind::kClassic) return logon.account;
    return logon.mail;
}
// Ghi chỉ thị của bảng cho khung này: kê gốc, giấu phần không thuộc kiểu tài khoản đang chọn, đặt
// trạng thái chọn của các thẻ, con nháy và chữ của ba ô (mật khẩu thành dấu sao). Chữ mượn từ
// logon: nó phải sống tới khi deck dùng xong.
void paint_logon(Deck& deck, const Logon& logon);

} // namespace game::ui::panel
