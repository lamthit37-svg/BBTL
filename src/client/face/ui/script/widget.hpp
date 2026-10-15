// Đối tượng widget của script giao diện (UILuaControl của client gốc): mỗi cửa sổ con của layout là một
// userdata Lua mang các phương thức SetText, Show, SetProgress, AddItem... Phương thức ghi vào
// ui::panel::Widgets (trạng thái giữ lại của cửa sổ, cùng thứ mà các bảng port tay ghi) và hàng Call (việc nhờ
// game), nên script gốc chạy trên LuaPlus cho ra đúng trạng thái mà bản port tay cho ra.
// Chỉ dùng C API của LuaPlus (third_party/luaplus) và mã thuần: không đụng GPU hay hệ điều hành, dựng được ở
// mọi nền tảng. Nửa còn lại của tầng (sổ cửa sổ, môi trường <Tên>_Env, `this`, sự kiện) là host.
// Khác gốc: client gốc đặt mọi lớp con lên cùng một metatable Window ở 2008 và xích thừa kế ở 2026; bản này
// gom mọi phương thức vào một bảng cho mọi widget (gọi phương thức của lớp khác không lỗi mà theo kiểu của
// widget): Kind chỉ đổi hành vi, không đổi tập phương thức.
#pragma once

#include "gui/asset.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/widgets.hpp"

#include <cstdint>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

struct lua_State;

namespace game::ui::script {

// Lớp Falagard của cửa sổ (TargetType trong scheme), tên theo lớp UILuaControl tương ứng.
enum class Kind : std::uint8_t {
    kWindow,
    kProgressBar,
    kActionButton,
    kCheckButton,
    kListBox,
    kComplexWindow,
    kCtrlList,
    kComboBox,
    kStaticImage,
    kScrollBar,
    kSuperTooltip,
    kMeshWindow,
    kChatHistory,
    kChatChannel,
    kSceneMap,
    kWorldMap,
    kMinimap,
    kInfoList,
    kSoftKey,
    kAnimate,
    kPopMenu,
    kEditBox,
};

// "Falagard/SuperProgress" -> kProgressBar; tên lạ -> kWindow.
[[nodiscard]] Kind kind_of(std::string_view falagard_type) noexcept;

// Tên lớp để in ("ProgressBar", "CtrlList"...).
[[nodiscard]] std::string_view kind_name(Kind kind) noexcept;

// Thứ widget cần hỏi hay nhờ phía game/host mà Widgets không có. Mọi hàm có mặc định để chỗ dùng chỉ ghi đè
// phần mình có.
class Services {
public:
    Services() = default;
    Services(const Services&) = delete;
    Services& operator=(const Services&) = delete;
    virtual ~Services() = default;

    // Tên đầy đủ "set:<bộ ảnh> image:<tên ảnh>" của một tên icon (IconManager::GetIconFullName), cho
    // SetProperty("ShortImage", ...). Mặc định giữ nguyên tên.
    [[nodiscard]] virtual std::string icon_full_name(std::string_view icon) const;
    // Tên đầy đủ của icon của action (SetActionItem); rỗng khi không có.
    [[nodiscard]] virtual std::string action_icon(std::int32_t action) const;
    // Cờ hiện của chính cửa sổ chủ (`this`): cửa sổ gốc của layout dùng cờ này, mọi cửa sổ con hiện khi gốc hiện.
    [[nodiscard]] virtual bool root_shown() const;
    virtual void set_root_shown(bool is_shown);

protected:
    Services(Services&&) = default;
    Services& operator=(Services&&) = default;
};

// Một cửa sổ con. Sao nguyên khối vào userdata Lua nên chỉ chứa con trỏ và khung nhìn; những thứ trỏ tới phải
// sống lâu hơn lua_State.
struct WindowRef {
    // Widgets của cửa sổ chủ (CUIWindowItem).
    ui::panel::Widgets* store = nullptr;
    // Hàng việc nhờ game (DoAction...).
    std::vector<ui::panel::Call>* calls = nullptr;
    // Giá trị gốc của layout (GetProperty, tìm cửa sổ cha và anh em).
    const gui::GuiAsset* asset = nullptr;
    // Tên cửa sổ con trong layout; host giữ chuỗi.
    std::string_view name;
    Kind kind = Kind::kWindow;
    // Chỉ số của cửa sổ trong asset->windows, -1 khi host không biết (tìm theo tên, chậm hơn).
    std::int32_t window = -1;
    // Có thể null: icon giữ nguyên tên, cửa sổ gốc coi là đang hiện.
    Services* services = nullptr;
};
static_assert(std::is_trivially_copyable_v<WindowRef>);

// Việc làm khi script gọi một phương thức mà bảng phương thức chưa có.
enum class Missing : std::uint8_t {
    // Như bản gốc gặp phương thức lạ: Lua báo lỗi "attempt to call", hàm xử lý sự kiện dừng ở đó.
    kRaise,
    // Chế độ đo (lượt chạy hàng loạt hàm xử lý của mọi cửa sổ để kê phương thức còn thiếu): ghi tên và số lần gọi,
    // rồi trả 0 như một phương thức không làm gì để hàm xử lý chạy tiếp. Không dùng khi chạy thật.
    kRecord,
};

// Một phương thức bị gọi mà chưa có, kèm số lần (chế độ Missing::kRecord).
struct MissingMethod {
    std::string name;
    std::uint32_t calls = 0;
};

// Dựng metatable và bảng phương thức sau khi mở state. Gọi lại là vô hại, và đổi được chế độ `missing` của state.
void open_widget_classes(lua_State* state, Missing missing = Missing::kRaise);

// Nhịp thời gian của các widget (FalagardSuperProgress::updateSelf): mọi cửa sổ của store có đoạn mờ dần (SetFadeState > 0)
// và đang hiện thì trừ seconds khỏi thời gian còn, đặt Alpha = còn / tổng; hết giờ (còn < 0) thì giấu cửa sổ, và nếu nó là
// cửa sổ gốc của layout (`this`) thì services.set_root_shown(false). seconds là giây từ đồng hồ khung.
void advance_widgets(ui::panel::Widgets& store, const gui::GuiAsset& asset, Services& services, float seconds);

// Các phương thức bị gọi mà chưa có từ lúc mở chế độ kRecord, theo tên tăng dần; rỗng khi state chưa từng mở chế độ ấy.
[[nodiscard]] std::vector<MissingMethod> missing_methods(lua_State* state);

// Đẩy một đối tượng widget lên đỉnh ngăn xếp. Cửa sổ mà layout khai Visible=False được ghi nhận là giấu theo
// layout (Widgets::seed_hidden) để IsVisible đúng trước khi script gọi Show.
void push_widget(lua_State* state, const WindowRef& window);

} // namespace game::ui::script
