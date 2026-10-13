// Bảng chọn máy chủ (SelectServer, layout SelectServer/SelectServer.layout.xml) của thủ tục đăng
// nhập: cột vùng bên trái (đại khu và vùng con), trang bên phải (mục đề cử, máy chủ của một vùng,
// kết quả tìm), ô tìm, nút "lần đăng nhập trước", và việc mỗi nút nhờ client làm. Client gốc mở bảng
// bằng sự kiện GAMELOGIN_OPEN_SELECT_SERVER và là màn đầu tiên của thủ tục đăng nhập khi bộ khởi động
// không đưa sẵn máy chủ (CGamePro_Login: +0x2c0 bằng 2); chọn xong, GameProduceLogin:SelectLoginServer
// chuyển sang bảng nhập tài khoản. Bảng ở đây chỉ là trạng thái: việc ngoài bảng (vào bảng tài khoản,
// mở trang web, thoát) nằm chờ ở SelectServer::request cho chuỗi đăng nhập lấy bằng take_server_request.
// Nguồn: Interface/SelectServer/SelectServer.lua của client 2026, giải bằng TOOLS/content/lua_plain.py
// (LoginSelectServer_OnEvent 429, SelectServer_SelectAreaServer 1427, SelectServerEvent_Area_SwitchPage
// 1947, SelectServer_Area_BigAreaButtonUpdate 2028, SelectServerEvent_SelectOk 2278, hàm hiện máy chủ
// 980-1260), và mã máy Game.exe (SelectLoginServer 0x140340550, SetLoginServerKeyword 0x1403400d0 với
// 0x140628240, LoadLaunch 0x140340840). Dữ liệu danh sách: ui/panel/servers.hpp.
// Khác gốc: chưa có trang "máy chủ mượt" (GAMELOGIN_OPEN_RECOMMEND_SERVER, chỉ bật khi đăng nhập báo
// máy chủ đầy), thanh cuộn của cột vùng (script ẩn nó), nháy chữ (#b), hoạt ảnh thưởng của máy chủ
// (Server_N), gợi ý nổi (tooltip) và danh sách thả của ô chọn nhà mạng (ô chỉ hiện nhà mạng đang
// chọn); nút "Làm tươi" không tải lại danh sách (LoadLaunch chạy Launch.exe của bộ khởi động, bản này
// không có); nút "Xem phim" (CG_WINDOW_SHOW), "Tra nhân vật" (LuaFindRoleByAcc) và "Bước trước" (hàm
// của script đã bị chú thích) không làm gì, như bản gốc không có bảng tương ứng trong phạm vi này.
// Nhấn đúp (MouseDoubleClick) là việc của người gọi: báo bằng double_server.
#pragma once

#include "gui/strings.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/servers.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Layout của bảng, đường dẫn tương đối với thư mục Interface.
inline constexpr std::string_view kServerLayout = "SelectServer/SelectServer.layout.xml";
// Ô tìm kiếm (MaxTextLength 12 của layout) và cột vùng bên trái: người gọi hỏi chỉ số nút phần tử
// dưới chuột của cột vùng (gui::Hub::element_at).
inline constexpr std::string_view kServerSearchBox = "SelectServer_Server_SearchName";
inline constexpr std::string_view kServerAreaList = "SelectServer_Frame2_List";

// Việc bảng nhờ client làm. kEnter: đã chọn xong máy chủ (SelectLoginServer), sang bảng tài khoản.
// kMustPick: bấm xác nhận khi chưa chọn máy chủ nào (MUST_SELECTSERVER). Bốn mục kia là OpenURL
// nạp thẻ, OpenURL đăng ký và thoát game (QuitApplication("quit")).
enum class ServerWork : std::uint8_t { kEnter, kMustPick, kOpenTopUp, kOpenRegister, kLeave };

struct ServerRequest {
    ServerWork work = ServerWork::kLeave;
    // Máy chủ đã chọn; chỉ có nghĩa với kEnter.
    ServerRef server;
};

// Nút phần tử của cột vùng, theo thứ tự thêm (g_nAreaButtonInfo của script).
struct AreaRow {
    BigArea big = BigArea::kRecommend;
    // Vùng con (chỉ số vào danh sách vùng của đại khu, từ 0); không có khi hàng là nút đại khu.
    std::optional<std::size_t> sub;

    friend bool operator==(const AreaRow&, const AreaRow&) = default;
};

// Trang bên phải đang hiện (g_iCurShowServer).
enum class ServerPage : std::uint8_t { kRecommend, kArea, kSearch };

inline constexpr std::size_t kBigAreaSlots = kBigAreaCount + 1;

struct SelectServer {
    ServerDirectory directory;
    // Vùng của từng đại khu (g_AreaInfo.AreaServerInfo): chỉ số vào directory.areas, theo thứ tự vùng.
    std::array<std::vector<std::size_t>, kBigAreaSlots> groups;
    std::vector<AreaRow> rows;
    // Trạng thái nút của cột vùng: nút đại khu đang chọn (SetCatalogButtonSelect), các vùng con đang
    // hiện (Show/Hide) và đại khu đang mở (CurShowList).
    std::array<bool, kBigAreaSlots> big_selected{};
    std::array<bool, kBigAreaSlots> subs_shown{};
    std::array<bool, kBigAreaSlots> opened{};
    // Vùng con đang chọn (g_nCurSelSubArea đã gắn cờ chọn).
    std::optional<AreaRow> sub_selected;
    ServerPage page = ServerPage::kRecommend;
    // Vùng đang xem ở trang kArea (g_iCurSelArea khi chọn vùng).
    std::optional<std::size_t> viewed_area;
    // Máy chủ đang chọn (g_iCurSelArea, g_iCurSelLoginServer) và nút đang có dấu chọn. Hai thứ tách
    // nhau vì script bỏ dấu của mọi nút khi hiện trang tìm mà không bỏ máy chủ đang chọn.
    std::optional<ServerRef> picked;
    std::optional<ServerRef> picked_mark;
    std::vector<ServerRef> recommend;
    // Kết quả tìm và trang đang xem (từ 1; 0 là chưa tìm lần nào).
    std::vector<ServerRef> found;
    std::size_t search_page = 0;
    // Chữ ô tên vùng, dòng hướng dẫn dưới, thanh thông tin và ô tìm.
    std::string title;
    std::string help;
    std::string info;
    std::string search;
    bool is_search_focused = false;
    // Lần đăng nhập trước (g_LastArea, g_LastServer) và dấu chọn của nút ấy.
    std::optional<ServerRef> last;
    bool is_last_checked = false;
    // Nhà mạng trong ô chọn (g_iNetProvide), chỉ số 0 tới 3; OnLoad đặt mục 3 ("mặc định").
    std::size_t line = 3;
    std::optional<ServerRequest> request;
};

// Mở bảng với danh sách directory (GAMELOGIN_OPEN_SELECT_SERVER): dựng cột vùng, hiện trang đề cử,
// rồi đặt lần đăng nhập trước (GAMELOGIN_LASTSELECT_AREA_AND_SERVER). back là máy chủ đã chọn trước
// khi quay lại từ bảng tài khoản: có thì mở lại đúng vùng và chọn lại nó (GAMELOGIN_SELECT_AREA rồi
// GAMELOGIN_SELECT_LOGINSERVER); không còn trong danh sách thì ở trang đề cử.
void open_servers(SelectServer& panel, ServerDirectory directory, std::optional<ServerRef> last,
    std::optional<ServerRef> back);
// Một lần nhấn trái lên cửa sổ window. element là chỉ số nút phần tử của cột vùng dưới chuột khi
// window là cột ấy. double_click là lần nhấn thứ hai của một cú nhấn đúp trên cùng cửa sổ.
struct ServerPress {
    std::string_view window;
    std::optional<std::size_t> element;
    bool is_double = false;
    // Bảng chữ cho mẫu "#{FWQWL_201130_02}" của dòng hướng dẫn; vắng thì dòng ấy để trống.
    const gui::StringBook* words = nullptr;
};
void press_server(SelectServer& panel, const ServerPress& press);
// Cửa sổ dưới chuột (rỗng khi không có) và nút phần tử của cột vùng dưới chuột: thanh thông tin đổi
// theo MouseEnter và MouseLeave của script.
void hover_server(SelectServer& panel, std::string_view window, std::optional<std::size_t> element);
// Một ký tự từ bàn phím cho ô tìm khi nó đang nhận phím: ký tự in được nối vào (trần 12 ký tự),
// xoá lùi bỏ ký tự cuối, Enter là tìm. Ô không nhận phím thì không làm gì.
void type_server(SelectServer& panel, char32_t code);
// Lấy việc đang chờ; lấy rồi thì hết.
[[nodiscard]] std::optional<ServerRequest> take_server_request(SelectServer& panel) noexcept;
// Ghi chỉ thị của bảng cho khung này. Chữ mượn từ panel: nó phải sống tới khi deck dùng xong.
void paint_server(Deck& deck, const SelectServer& panel);

} // namespace game::ui::panel
