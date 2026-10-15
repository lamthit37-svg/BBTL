// Phần chủ của giao diện chạy bằng script Lua gốc (tầng C của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-C.md): port CUIWindowMng,
// CUIWindowItem, CGameUIScript của UI_CEGUI.dll và CScriptEnvironment, bộ hẹn giờ Lua của Game.exe, bản 3.71.9509.
// Một máy Lua (LuaPlus 5.0.1 gốc, third_party/luaplus) cho mọi cửa sổ, như client gốc:
//  - Mở: mỗi dòng của sổ (Script/windows.tsv, thứ tự dòng) tạo bảng toàn cục <Tên>_Env, chạy script của cửa sổ trong _G
//    thường (không đặt môi trường, 0x140652d60), đặt <Tên>_Env.this (userdata, metatable MetaTable_UIWindowItem), rồi gọi
//    <Tên>_PreLoad (PreLoadWindow 0x180078390).
//  - Mọi lời gọi của một cửa sổ (PreLoad, OnLoad, OnEvent, đoạn Lua của layout, hẹn giờ) chạy trong "môi trường" của nó:
//    trước đó _G mang metatable {__index = <Tên>_Env}, sau đó đặt lại môi trường cũ CHỈ KHI môi trường cũ khác rỗng
//    (0x140653830), nên ngoài lời gọi _G giữ môi trường của cửa sổ chạy lời gọi đầu tiên. `this` và tên các cửa sổ con
//    vì thế không phải biến toàn cục thật.
//  - Layout nạp lười ở lần đầu cần (LoadWindow 0x180077f20): mỗi cửa sổ của layout thành một đối tượng widget (widget.hpp)
//    trong <Tên>_Env, rồi gọi <Tên>_OnLoad.
//  - Sự kiện game: luật gửi của 0x180079310 và _OnGameEvent 0x18007b8e0 (arg<k> và eventTable[k + 1] toàn cục, không xoá
//    giữa hai sự kiện).
// Quy tắc với longjmp (LuaPlus báo lỗi bằng longjmp, không unwinding C++): mã C++ của host chỉ gọi API Lua có thể báo lỗi
// (cấp phát, siêu phương thức) bên trong lua_pcall / lua_cpcall; hàm C mà Lua gọi (phương thức của `this`, SetTimer...) chỉ
// đọc đối số và báo lỗi ở đầu hàm, trước khi dựng đối tượng C++ có destructor, và chỉ đẩy chuỗi nằm trong kho của host.
// Đa nền tảng: chỉ C API của Lua, io::read_text và mã thuần; hẹn giờ theo đồng hồ khung (gốc dùng WM_TIMER của Win32).
// Một luồng: mọi hàm của Host chạy trên cùng một luồng (luồng giao diện).
#pragma once

#include "gui/asset.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"
#include "ui/script/widget.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

struct lua_State;

namespace game::ui::script {

// Nút chuột của một sự kiện CEGUI, cho CEArg:GetValue("MouseButton").
enum class MouseButton : std::uint8_t { kLeft, kRight, kMiddle, kX1, kX2, kNone };

// Vị trí theo điểm ảnh.
struct Spot {
    float x = 0.0F;
    float y = 0.0F;
};

// Cỡ vùng khách của cửa sổ chương trình, pixel.
struct ClientSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Phía giao diện mà host cần (HUD nối với gui::GuiLoader và gui::Hub; test dùng bản giả). Một luồng, như Host.
class Screen {
public:
    Screen() = default;
    Screen(const Screen&) = delete;
    Screen& operator=(const Screen&) = delete;
    virtual ~Screen() = default;

    // Nạp layout (đường dẫn dưới Interface/) nếu chưa nạp; trả khoảng các cửa sổ của nó trong asset().windows (kể cả cửa
    // sổ con mà look tự dựng). Lỗi: một câu tiếng Việt.
    [[nodiscard]] virtual std::expected<gui::GuiRange, std::string> load_layout(std::string_view layout) = 0;
    // Asset của mọi layout đã nạp; tham chiếu đúng suốt đời Screen, nội dung lớn dần sau mỗi load_layout.
    [[nodiscard]] virtual const gui::GuiAsset& asset() const noexcept = 0;
    // Toạ độ trên trái của cửa sổ window so với cửa sổ root theo lần dàn trang gần nhất (GetChildOffset); nullopt khi
    // chưa dàn trang lần nào.
    [[nodiscard]] virtual std::optional<Spot> offset(std::string_view window, std::string_view root) const = 0;
    // Điểm có nằm trong cửa sổ window theo lần dàn trang gần nhất không (Window::isHit của CEGUI).
    [[nodiscard]] virtual bool hits(std::string_view window, Spot spot) const = 0;
    // Ô trên màn hình của cửa sổ window theo lần dàn trang gần nhất, cho phương thức hình học của widget (GetWindowSize,
    // CenterWindow...); nullopt khi chưa dàn trang hay cửa sổ đang ẩn. Mặc định nullopt.
    [[nodiscard]] virtual std::optional<PixelBox> box(std::string_view window) const;

protected:
    Screen(Screen&&) = default;
    Screen& operator=(Screen&&) = default;
};

// Trần lệnh Lua mặc định của một lời gọi từ host (PreLoad, OnEvent, đoạn của layout, hẹn giờ), tính cả lời gọi lồng.
// Khác gốc: gốc không có trần, một vòng lặp vô tận trong script treo client.
inline constexpr std::uint32_t kDefaultInstructionLimit = 50'000'000;

struct HostDesc {
    // Thư mục dữ liệu client: Script/windows.tsv và Script/Interface/<cửa sổ>/<tên>.lua.
    std::filesystem::path data_root;
    // Chỉ những cửa sổ này (tên trong sổ) được nạp script, PreLoad và nhận sự kiện; rỗng là cả sổ. Dành cho lúc HUD chuyển
    // dần từng cửa sổ từ bảng port tay sang script: cửa sổ ngoài danh sách chưa tồn tại với host, nên nhóm nhường chỗ
    // (Demise) chỉ tính trong các cửa sổ có mặt. Tên không có trong sổ ghi một dòng notes.
    std::vector<std::string> only;
    std::uint32_t instruction_limit = kDefaultInstructionLimit;
    // Đăng ký hàm của game (tầng B: DataPool, Player, PushEvent...) sau thư viện chuẩn và hàm của host, trước khi chạy
    // script nào. Chạy trong lua_cpcall: lỗi Lua bên trong được bắt; hàm này không được giữ đối tượng C++ có destructor
    // qua một lời gọi API Lua có thể báo lỗi (xem đầu tệp). Rỗng thì không đăng ký gì.
    std::function<void(lua_State*)> natives;
};

// Một dòng đăng ký sự kiện của PreLoad: tên và cờ (true là nhận cả lúc cửa sổ ẩn).
struct Registration {
    std::string name;
    bool is_always = true;
};

class Host {
public:
    // Mở máy Lua, đăng ký lớp của host và widget, chạy script và PreLoad của mọi cửa sổ trong sổ. Lỗi khi không đọc được
    // sổ hay không mở được máy Lua; script hỏng của một cửa sổ chỉ ghi vào notes. screen phải sống lâu hơn Host.
    [[nodiscard]] static std::expected<Host, std::string> open(const HostDesc& desc, Screen& screen);

    Host(Host&&) noexcept;
    Host& operator=(Host&&) noexcept;
    Host(const Host&) = delete;
    Host& operator=(const Host&) = delete;
    ~Host();

    // Sự kiện game (PushEvent của Game.exe): gửi cho mọi cửa sổ đã đăng ký tên đó, theo thứ tự đăng ký. Đối số là chuỗi.
    void post(std::string_view event, std::span<const std::string_view> args);
    // Người chơi làm sự kiện CEGUI event (Clicked, MouseLButtonDown, Hidden...) trên cửa sổ window: chạy mọi đoạn Lua mà
    // layout nối vào sự kiện đó, theo thứ tự trong tệp, trong môi trường của cửa sổ chủ, với arg0 toàn cục là tên window
    // (FireUIEvent 0x1800768b0). false khi window không thuộc cửa sổ nào đã nạp hay không nối sự kiện đó.
    bool fire(std::string_view window, std::string_view event, MouseButton button);
    // Nhấn chuột (trái hay phải) tại spot, gọi SAU khi cú nhấn đã tới cửa sổ: cửa sổ loại kPopup đang hiện mà spot nằm
    // ngoài thì đóng và nhớ cờ ClickHide (0x1800764a0, gọi sau injectMouseButtonDown 0x18006bd18).
    void pressed(Spot spot);
    // Đồng hồ đơn điệu của khung: nổ các hẹn giờ tới hạn, mỗi hẹn giờ tối đa một lần mỗi lượt.
    void tick(std::chrono::milliseconds now);

    // Cỡ vùng khách của cửa sổ chương trình, pixel, cho GetCurClientSize (không trả nhỏ hơn 800x600; 0 là chưa biết).
    void set_client_size(ClientSize size) noexcept;

    // Nạp layout của cửa sổ và chạy OnLoad mà không hiện nó (không phát Shown hay Hidden): cho test và khảo sát cần widget của cửa sổ.
    // false khi không có cửa sổ đó hay layout không nạp được (một dòng notes); đã nạp rồi thì true.
    bool load(std::string_view name);
    // Hiện hay giấu một cửa sổ theo tên sổ như this:Show() / this:Hide() (kể cả nhường chỗ khi hiện). false khi không có.
    bool set_shown(std::string_view name, bool is_shown);
    // CloseAllWindow (0x1800763f0): giấu mọi cửa sổ đang hiện trừ loại kKeep và kCloseAllKept; true khi đã giấu ít nhất một.
    bool close_all();
    [[nodiscard]] bool is_shown(std::string_view name) const;

    // Ghi các cửa sổ đang hiện vào deck: gốc layout theo thứ tự chồng (hiện sau nằm trên), rồi trạng thái widget của chúng.
    // Tên trong deck trỏ vào kho của host: đúng tới lần gọi kế của một hàm không const.
    void paint(panel::Deck& deck) const;

    // Việc script nhờ game (DoAction, CareObject, PushEvent của EUS_SHOW_RESULT...) kể từ lần lấy trước.
    [[nodiscard]] std::vector<panel::Call> take_calls();
    // Lỗi của script và của host kể từ lần lấy trước, mỗi dòng một câu tiếng Việt; giữ tối đa 512 dòng, dòng cuối báo số
    // dòng đã bỏ.
    [[nodiscard]] std::vector<std::string> take_notes();

    // Số cửa sổ trong sổ.
    [[nodiscard]] std::size_t window_count() const noexcept;
    // Trạng thái widget của cửa sổ theo tên sổ; nullptr khi không có.
    [[nodiscard]] const panel::Widgets* widgets(std::string_view name) const;
    // Sự kiện mà PreLoad của cửa sổ đã đăng ký, theo thứ tự đăng ký; rỗng khi không có cửa sổ đó.
    [[nodiscard]] std::span<const Registration> registrations(std::string_view name) const;
    // Chạy một đoạn Lua (tên chunk "run") trong _G với môi trường đang đặt, như lua_dostring; false và một dòng notes khi lỗi.
    bool run(std::string_view code);
    // Máy Lua, cho tầng B và test; sống tới khi Host bị huỷ.
    [[nodiscard]] lua_State* lua() const noexcept;

private:
    struct State;
    explicit Host(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::ui::script
