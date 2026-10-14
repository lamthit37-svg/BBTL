// Chuỗi đăng nhập: chọn máy chủ, tài khoản, chọn nhân vật, tạo nhân vật. Chuỗi mở ở bảng chọn máy
// chủ (CGamePro_Login: +0x2c0 bằng 2) khi có danh sách máy chủ; chọn xong thì sang bảng tài khoản,
// và "bước trước" hay phím Esc của bảng tài khoản (ExitToSelectServer) quay về bảng chọn, nhớ máy chủ
// đã chọn. Thiếu danh sách thì chuỗi mở thẳng ở bảng tài khoản. Nút vào game của bảng tài khoản chỉ
// báo khi cả hai ô đã có chữ; chuỗi nuốt việc đó và mở bảng chọn, không đưa nó ra client. Vào
// game thật chỉ bật khi đã chọn một nhân vật. Sổ là của mọi tài khoản; mật khẩu không lưu.
// Client ghi tệp khi book_text có chữ, và chỉ gọi mark_saved sau khi ghi đĩa thành công.
// Ở bước tạo, chuỗi đóng vai game của bảng tạo: nó gieo số cho math.random của script, nhận việc
// bảng nhờ (CreateRole, ChangeToSelectRoleDlgFromCreateRole, GameLoginShowSystemInfo) và lưu nhân
// vật mới với đúng mặt, tóc, ảnh chân dung và bộ đồ tân thủ mà bảng đã đặt cho game.
// Khác gốc: chưa có máy chủ, hộp YesNo, hộp thông báo (lời nhắn hiện ở dòng mô tả của bảng tạo),
// và danh sách tên cấm; tên được nhận theo luật của roles.hpp. Người mẫu của hai màn đứng trong
// cảnh; hướng mặt quay khi giữ nút (role_pose.hpp).
#pragma once

#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/select_role.hpp"
#include "ui/panel/select_server.hpp"
#include "ui/panel/servers.hpp"
#include "ui/panel/system_info.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

enum class FlowStep : std::uint8_t { kServers, kAccount, kRoles, kCreate };

// Ký tự điều khiển của phím Esc trong dãy ký tự gõ.
inline constexpr char32_t kEscapeKey = 0x1B;

// Hạt đầu của xúc xắc bảng tạo (xorshift32 không nhận 0).
inline constexpr std::uint32_t kDiceSeed = 0x6C8E944DU;

// Điều chuỗi đọc của game ở một sự kiện, cho bảng tạo; bước khác không dùng. Con trỏ mượn phải
// sống tới hết lời gọi; rỗng thì phần đó coi như không có dữ liệu.
struct LoginFacts {
    // Bảng của màn tạo, bảng chân dung (ảnh lưu kèm nhân vật) và bản dịch tên kiểu mặt, tóc, bộ đồ.
    const RoleCast* cast = nullptr;
    const Portraits* portraits = nullptr;
    const gui::StringBook* words = nullptr;
    // Muối của sự kiện (đồng hồ khung), trộn vào xúc xắc để mỗi lần chạy gieo khác nhau.
    std::uint32_t salt = 0;
    // Nút phần tử của cột vùng (bảng chọn máy chủ) dưới chuột khi cửa sổ nhấn là cột ấy, và lần nhấn
    // này là lần thứ hai của một cú nhấn đúp trên cùng cửa sổ.
    std::optional<std::size_t> element;
    bool is_double = false;
};

struct LoginFlow {
    SelectServer servers;
    // Danh sách máy chủ đã nạp (rỗng thì chuỗi bỏ bước chọn máy chủ), máy chủ đã chọn ở lần đi qua
    // bảng chọn và máy chủ của lần vào game trước (nhớ giữa hai lần chạy, ghi tệp khi last_dirty).
    ServerDirectory directory;
    std::optional<ServerRef> chosen;
    std::optional<ServerRef> last;
    bool is_last_dirty = false;
    SystemInfo system_info;
    Logon logon;
    SelectRole select;
    CreateRole create;
    Book book;
    std::string account;
    FlowStep step = FlowStep::kAccount;
    std::optional<Role> entering;
    bool dirty = false;
    bool enter_game = false;
    std::optional<LogonAction> pending;
    // Hướng mặt và tốc độ quay của bảng chọn; màn tạo dùng spin của nó và giữ hướng riêng từng giới
    // (chỉ số là giới), cùng số lần đặt lại hướng đã thấy của CreateGame::turns_back.
    RolePose pose;
    std::array<float, 2> create_yaw{};
    std::array<std::uint32_t, 2> seen_turns{};
    // Trạng thái xúc xắc của bảng tạo, luôn khác 0.
    std::uint32_t dice = kDiceSeed;
};

// Mở thủ tục đăng nhập: bảng chọn máy chủ khi đã nạp danh sách, không thì bảng tài khoản. Giữ sổ và
// chữ đã gõ; bỏ việc vào game và việc chưa lấy.
void start_login(LoginFlow& flow);
// Nạp danh sách máy chủ từ chữ TSV (servers.hpp); false khi tệp sai dạng (danh sách rỗng).
[[nodiscard]] bool recall_directory(LoginFlow& flow, std::string_view text);
// Nạp máy chủ của lần vào game trước từ chữ tệp; sai dạng hay không còn trong danh sách thì bỏ.
void recall_last(LoginFlow& flow, std::string_view text);
// Chữ tệp khi máy chủ lần vào game trước đổi kể từ lần ghi; không có khi chưa đổi.
[[nodiscard]] std::optional<std::string> last_text(const LoginFlow& flow);
// Ghi tệp xong: lần last_text sau không trả lại cùng bản.
void mark_last_saved(LoginFlow& flow) noexcept;
// Đang ở bảng tài khoản: bàn phím ảo chỉ mở ở bước này.
[[nodiscard]] bool on_account(const LoginFlow& flow) noexcept;
// Một lần nhấn trái.
void press_flow(LoginFlow& flow, std::string_view window, const LoginFacts& facts);
// Nhả nút trái: nút xoay hay phóng của bảng tạo thôi tác dụng.
void release_flow(LoginFlow& flow);
// Cửa sổ đang nằm dưới chuột (rỗng khi không có) và nút phần tử của cột vùng dưới chuột: bảng tạo đổi
// dòng mô tả, bảng chọn máy chủ đổi thanh thông tin.
void hover_flow(LoginFlow& flow, std::string_view window, std::optional<std::size_t> element);
// Nút dưới chuột đang giữ, cho hai nút xoay của bảng chọn. Rỗng hay nút khác thì hết quay. Ở bảng
// tạo, tốc độ quay là thứ bảng đã đặt cho game.
void hold_flow(LoginFlow& flow, std::string_view window) noexcept;
// Cộng hướng mặt theo spin đang giữ, seconds là khoảng từ khung trước.
void advance_flow(LoginFlow& flow, float seconds) noexcept;
// Một khung của khung cuộn ô mô tả môn phái ở bảng tạo (roll_detail); bước khác thì không làm gì.
void roll_flow(LoginFlow& flow, const DetailRoll& roll) noexcept;
// Mô hình của bước chọn và bước tạo. Bước khác thì không hiện.
[[nodiscard]] ShownModel shown_model(const LoginFlow& flow, const LoginFacts& facts);
// Một ký tự bàn phím. Bảng chọn nhân vật không nhận chữ. Esc (kEscapeKey) ở bảng tài khoản quay về bảng
// chọn máy chủ.
void type_flow(LoginFlow& flow, char32_t code, const LoginFacts& facts);
// Một phím của bàn phím ảo, chỉ khi đang ở bảng tài khoản.
void key_flow(LoginFlow& flow, char32_t code);
// Đúng một bảng của bước hiện tại, rồi hộp thông báo nếu đang mở. meter đo chữ để hộp thông báo co lại.
void paint_flow(Deck& deck, const LoginFlow& flow, const gui::TextMeter* meter);
// Việc client phải làm: vào game, mở trang, hoặc rời. Lấy rồi thì hết. Nhân vật đang vào vẫn giữ.
[[nodiscard]] std::optional<LogonAction> take_flow(LoginFlow& flow) noexcept;
// Nạp sổ từ chữ TSV. Chuỗi rỗng là sổ trống và thành công. Sai phiên bản thì sổ trống và thất bại.
[[nodiscard]] bool recall_book(LoginFlow& flow, std::string_view text);
// Chữ TSV khi sổ đổi kể từ lần lưu; không có khi chưa đổi. Không xoá cờ đổi.
[[nodiscard]] std::optional<std::string> book_text(const LoginFlow& flow);
// Ghi đĩa xong: lần book_text sau không trả lại cùng bản.
void mark_saved(LoginFlow& flow) noexcept;
// Nhân vật lần vào game gần nhất sẽ dùng; không có khi chưa chọn.
[[nodiscard]] const Role* entering_role(const LoginFlow& flow) noexcept;

} // namespace game::ui::panel
