// Đối tượng widget của script giao diện: metatable, bảng phương thức và hàm C của từng phương thức.
// Nguồn hành vi: UILuaControl.cpp của client 2008 (đọc đối số, im lặng bỏ qua đối số sai kiểu) và hàm cùng tên trong
// UI_CEGUI.dll 2026 (docs/GIAO-DIEN-2026.md mục 8) cho chỗ hai bản lệch; trạng thái ghi vào Widgets theo mô hình mà
// TOOLS/port/lua_oracle.lua đã dùng để sinh số vàng của các bảng port tay.
// Quy tắc của mọi hàm C ở đây: LuaPlus báo lỗi bằng longjmp, nên chỗ gọi raise (lua_error) không được giữ đối tượng có
// destructor còn sống (std::string, vector). Hàm chỉ gọi nó ở đầu hàm (self) hay trước khi dựng gì (SetActionItem).
#include "ui/script/widget.hpp"

#include "gui/asset.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"
#include "ui/script/script_text.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

extern "C" {
#include "lauxlib.h"
#include "lua.h"
}
#include "luanum/luanum.h"

namespace game::ui::script {

std::string Services::icon_full_name(std::string_view icon) const {
    return std::string{icon};
}

std::string Services::action_icon(std::int32_t /*action*/) const {
    return {};
}

bool Services::root_shown() const {
    return true;
}

void Services::set_root_shown(bool /*is_shown*/) {}

std::optional<PixelBox> Services::window_box(std::string_view /*window*/) const {
    return std::nullopt;
}

std::optional<PixelBox> Services::screen_box() const {
    return std::nullopt;
}

namespace {

using panel::Ask;
using panel::Call;
using panel::GridCell;
using panel::GridColumn;
using panel::InfoLife;
using panel::Key;
using panel::kEmptyAction;
using panel::ListItem;

// Khoá của metatable trong sổ đăng ký Lua, cũng là cách nhận ra userdata của widget.
constexpr const char* kMetaName = "thienlong.ui.widget";

// InfoList giữ tối đa chừng này mục (NormalizeItemNumber, mặc định 0x18006b676 của CEGUIFalagard.dll).
constexpr std::size_t kInfoLimit = 5;
// Tuổi thọ và tốc độ mờ của mục khi layout không khai Life và FadeSpeed: giá trị DebugListBox.layout.xml, layout duy nhất của
// bản 2026 có InfoList (mặc định trong hàm dựng FalagardInfoList chưa đọc).
constexpr std::int32_t kInfoLifeMs = 5000;
constexpr std::int32_t kInfoFadeSpeed = 128;

struct Box {
    WindowRef ref;
};

struct KindName {
    std::string_view name;
    Kind kind;
};

// TargetType trong scheme -> lớp UILuaControl. Tên không có ở đây là cửa sổ thường.
constexpr std::array kKinds = {
    KindName{.name = "Falagard/SuperProgress", .kind = Kind::kProgressBar},
    KindName{.name = "Falagard/ActionButton", .kind = Kind::kActionButton},
    KindName{.name = "Falagard/ActionButtonWindow", .kind = Kind::kActionButton},
    KindName{.name = "Falagard/CheckBox", .kind = Kind::kCheckButton},
    KindName{.name = "Falagard/RadioButton", .kind = Kind::kCheckButton},
    KindName{.name = "Falagard/Listbox", .kind = Kind::kListBox},
    KindName{.name = "Falagard/ListBoxEx", .kind = Kind::kListBox},
    KindName{.name = "Falagard/NotSuperList", .kind = Kind::kListBox},
    KindName{.name = "Falagard/ComplexWindow", .kind = Kind::kComplexWindow},
    KindName{.name = "Falagard/MultiColumnList", .kind = Kind::kCtrlList},
    KindName{.name = "Falagard/MultiColumnListNew", .kind = Kind::kCtrlList},
    KindName{.name = "Falagard/Combobox", .kind = Kind::kComboBox},
    KindName{.name = "Falagard/StaticImage", .kind = Kind::kStaticImage},
    KindName{.name = "Falagard/MapImage", .kind = Kind::kStaticImage},
    KindName{.name = "Falagard/Scrollbar", .kind = Kind::kScrollBar},
    KindName{.name = "Falagard/SuperTooltip", .kind = Kind::kSuperTooltip},
    KindName{.name = "Falagard/SuperTooltip/ResizeText", .kind = Kind::kSuperTooltip},
    KindName{.name = "Falagard/MeshWindow", .kind = Kind::kMeshWindow},
    KindName{.name = "Falagard/MeshWindow/ParentWindow", .kind = Kind::kMeshWindow},
    KindName{.name = "Falagard/ChatHistory", .kind = Kind::kChatHistory},
    KindName{.name = "Falagard/ChatChannel", .kind = Kind::kChatChannel},
    KindName{.name = "Falagard/SceneMap", .kind = Kind::kSceneMap},
    KindName{.name = "Falagard/WorldMap", .kind = Kind::kWorldMap},
    KindName{.name = "Falagard/Minimap", .kind = Kind::kMinimap},
    KindName{.name = "Falagard/InfoList", .kind = Kind::kInfoList},
    KindName{.name = "Falagard/SoftKeyWindow", .kind = Kind::kSoftKey},
    KindName{.name = "Falagard/SFZSoftKeyWindow", .kind = Kind::kSoftKey},
    KindName{.name = "Falagard/PhoneSoftKeyWindow", .kind = Kind::kSoftKey},
    KindName{.name = "Falagard/Animate", .kind = Kind::kAnimate},
    KindName{.name = "Falagard/AnimateImage", .kind = Kind::kAnimate},
    KindName{.name = "Falagard/PopupMenu", .kind = Kind::kPopMenu},
    KindName{.name = "Falagard/Editbox", .kind = Kind::kEditBox},
    KindName{.name = "Falagard/IMEEditBox", .kind = Kind::kEditBox},
    KindName{.name = "Falagard/SafeIMEEditBox", .kind = Kind::kEditBox},
    KindName{.name = "Falagard/MultiIMEEditBox", .kind = Kind::kEditBox},
};

// ---- Đọc đối số. Không hàm nào ở đây ném lỗi Lua. ----

// IsString của LuaPlus: chuỗi hoặc số (lua_isstring).
[[nodiscard]] bool is_text(lua_State* state, int index) noexcept {
    return lua_isstring(state, index) != 0;
}

// IsInteger và IsNumber của LuaPlus: kiểu số (chuỗi trông như số không tính).
[[nodiscard]] bool is_number(lua_State* state, int index) noexcept {
    return lua_type(state, index) == LUA_TNUMBER;
}

// Đối số chuỗi hay số dưới dạng chuỗi (số đổi tại chỗ trên ngăn xếp, như lua_tostring); sống tới khi hàm C trả về.
[[nodiscard]] std::string_view text_at(lua_State* state, int index) {
    const char* data = lua_tostring(state, index);
    if (data == nullptr) return {};
    return {data, lua_strlen(state, index)};
}

// GetInteger của LuaPlus: (int) của số, theo MSVCR110.
[[nodiscard]] std::int32_t int_at(lua_State* state, int index) noexcept {
    return luanum_to_int32(lua_tonumber(state, index));
}

// tostring() của Lua cho một đối số bất kỳ (số theo "%.14g" của luanum). Giá trị không có dạng chữ ổn định (bảng, hàm)
// ghi tên kiểu.
[[nodiscard]] std::string tostring_at(lua_State* state, int index) {
    switch (lua_type(state, index)) {
    case LUA_TNIL:
    case LUA_TNONE: return "nil";
    case LUA_TBOOLEAN: return lua_toboolean(state, index) != 0 ? "true" : "false";
    case LUA_TNUMBER:
    case LUA_TSTRING: return std::string{text_at(state, index)};
    default: return lua_typename(state, lua_type(state, index));
    }
}

// Báo lỗi Lua "nơi: thông điệp" (luaL_error ghép nơi bằng luaL_where; tự ghép để khỏi gọi hàm vararg của C).
int raise(lua_State* state, const char* message) {
    luaL_where(state, 1);
    lua_pushstring(state, message);
    lua_concat(state, 2);
    return lua_error(state);
}

// Cửa sổ của lời gọi `đối_tượng:Phương_thức(...)`. Báo lỗi Lua (longjmp) khi đối số 1 không phải widget. Hai chỗ lệch
// Lua 5.0 so với bản sau: luaL_checkudata trả NULL chứ không báo lỗi khi sai kiểu, và lua_getmetatable đọc con trỏ rỗng khi
// ngăn xếp không có chỉ số ấy (`đối_tượng.Phương_thức()` viết nhầm dấu chấm làm chết tiến trình), nên kiểm lua_gettop trước.
[[nodiscard]] const WindowRef& self(lua_State* state) {
    const void* box = lua_gettop(state) >= 1 ? luaL_checkudata(state, 1, kMetaName) : nullptr;
    if (box == nullptr) {
        raise(state, "phương thức của widget phải gọi bằng dấu hai chấm (đối_tượng:Phương_thức())");
        std::unreachable(); // lua_error nhảy khỏi hàm bằng longjmp
    }
    return static_cast<const Box*>(box)->ref;
}

// Số của script sang float32 như phép ép double sang float của mã gốc; số ngoài miền float32 (mã gốc ra vô cực) thành số
// hữu hạn lớn nhất để phép ép không có hành vi không xác định. NaN giữ nguyên.
[[nodiscard]] float to_float(double value) noexcept {
    constexpr auto kLimit = static_cast<double>(std::numeric_limits<float>::max());
    return static_cast<float>(std::clamp(value, -kLimit, kLimit));
}

// Khoá bảng đếm phương thức còn thiếu (tên -> số lần gọi) trong sổ đăng ký Lua; chỉ có từ khi mở Missing::kRecord.
constexpr const char* kMissingName = "thienlong.ui.widget.missing";

// Cộng một vào số lần gọi của `key` trong bảng đếm; false (không làm gì) khi state chưa mở chế độ đo.
bool count_missing(lua_State* state, std::string_view key) {
    lua_pushstring(state, kMissingName);
    lua_rawget(state, LUA_REGISTRYINDEX);
    if (lua_type(state, -1) != LUA_TTABLE) {
        lua_pop(state, 1);
        return false;
    }
    lua_pushlstring(state, key.data(), key.size());
    lua_pushvalue(state, -1);
    lua_rawget(state, -3);
    const lua_Number seen = lua_type(state, -1) == LUA_TNUMBER ? lua_tonumber(state, -1) : 0;
    lua_pop(state, 1);
    lua_pushnumber(state, seen + 1);
    lua_rawset(state, -3);
    lua_pop(state, 1);
    return true;
}

// Phương thức mà tên trùng giữa các lớp 2026 nhưng lớp của widget này chưa có hành vi: không làm gì. Chế độ đo ghi
// "Tên@Lớp" (tên phương thức là upvalue 1 của hàm C) để lượt đo thấy chỗ còn thiếu.
int other_kind(lua_State* state, const WindowRef& window) {
    const char* method = lua_tostring(state, lua_upvalueindex(1));
    count_missing(state, std::format("{}@{}", method == nullptr ? "?" : method, kind_name(window.kind)));
    return 0;
}

// ---- Layout: thuộc tính gốc, cha và anh em ----

[[nodiscard]] std::int32_t window_index(const WindowRef& window) noexcept {
    if (window.asset == nullptr) return -1;
    const auto& windows = window.asset->windows;
    if (window.window >= 0 && static_cast<std::size_t>(window.window) < windows.size()) return window.window;
    const auto found = std::ranges::find(windows, window.name, &gui::GuiWindow::name);
    return found == windows.end() ? -1 : static_cast<std::int32_t>(found - windows.begin());
}

// Giá trị cuối cùng layout khai cho thuộc tính (dòng sau thắng).
[[nodiscard]] std::optional<std::string_view> layout_property(
    const gui::GuiAsset& asset, std::int32_t index, std::string_view name) noexcept {
    const gui::GuiRange range = asset.windows[static_cast<std::size_t>(index)].properties;
    for (std::uint32_t at = range.count; at > 0; --at) {
        const gui::GuiProperty& property = asset.properties[range.first + at - 1];
        if (property.name == name) return property.value;
    }
    return std::nullopt;
}

[[nodiscard]] bool is_false_text(std::string_view value) noexcept {
    return value == "False" || value == "false";
}

// Khoảng cửa sổ của layout chứa cửa sổ index; không có layout nào khai thì cả mảng.
[[nodiscard]] gui::GuiRange layout_range(const gui::GuiAsset& asset, std::int32_t index) noexcept {
    const auto at = static_cast<std::uint32_t>(index);
    for (const gui::GuiLayout& layout : asset.layouts) {
        if (at >= layout.windows.first && at - layout.windows.first < layout.windows.count) return layout.windows;
    }
    return {.first = 0, .count = static_cast<std::uint32_t>(asset.windows.size())};
}

// Cửa sổ gốc đầu tiên của layout là chính `this` (cờ hiện của nó là cờ của host).
[[nodiscard]] bool is_this_window(const gui::GuiAsset& asset, std::int32_t index) noexcept {
    if (asset.windows[static_cast<std::size_t>(index)].parent >= 0) return false;
    return std::cmp_equal(layout_range(asset, index).first, index);
}

// IsVisible (UI_CEGUI 3.71.9509 0x180028b60 gọi Window::isVisible(false)): hiện khi nó và mọi cửa sổ cha đều hiện;
// cửa sổ `this` lấy cờ của host.
[[nodiscard]] bool is_visible(const WindowRef& window) {
    const bool root_shown = window.services == nullptr || window.services->root_shown();
    const std::int32_t first = window_index(window);
    if (first < 0) return window.store->is_shown(window.name) && root_shown;
    const auto& windows = window.asset->windows;
    std::int32_t at = first;
    for (std::size_t step = 0; step < windows.size(); ++step) {
        const gui::GuiWindow& entry = windows[static_cast<std::size_t>(at)];
        if (is_this_window(*window.asset, at)) return root_shown;
        if (!window.store->is_shown(entry.name)) return false;
        if (entry.parent < 0) return true;
        at = entry.parent;
    }
    return false;
}

// Giá trị một thuộc tính: script đã đặt thì lấy, không thì giá trị layout.
[[nodiscard]] std::optional<std::string> known_property(const WindowRef& window, std::string_view name) {
    if (const auto set = window.store->value({.window = window.name, .name = name})) return std::string{*set};
    const std::int32_t index = window_index(window);
    if (index < 0) return std::nullopt;
    if (const auto layout = layout_property(*window.asset, index, name)) return std::string{*layout};
    return std::nullopt;
}

// Các nhóm {a,b} cấp 1 của một giá trị dạng "{{a,b},{c,d},...}".
[[nodiscard]] std::vector<std::string_view> brace_groups(std::string_view value) {
    std::vector<std::string_view> groups;
    int depth = 0;
    std::size_t start = 0;
    for (std::size_t at = 0; at < value.size(); ++at) {
        if (value[at] == '{') {
            ++depth;
            if (depth == 2) start = at;
        } else if (value[at] == '}') {
            if (depth == 2) groups.push_back(value.substr(start, at - start + 1));
            --depth;
        }
    }
    return groups;
}

// UnifiedXPosition, UnifiedYPosition, UnifiedPosition khi layout chỉ khai UnifiedAreaRect hay UnifiedPosition
// (CEGUI tính chúng từ đó); 2 481 trên 4 091 chỗ GetProperty của script là các tên này.
// Khác gốc?: CEGUI in lại số theo định dạng của nó, ở đây giữ nguyên chữ của layout.
[[nodiscard]] std::optional<std::string> derived_position(const WindowRef& window, std::string_view name) {
    const bool is_x = name == "UnifiedXPosition";
    const bool is_y = name == "UnifiedYPosition";
    if (!is_x && !is_y && name != "UnifiedPosition") return std::nullopt;
    for (const std::string_view source : {"UnifiedPosition", "UnifiedAreaRect"}) {
        const std::optional<std::string> value = known_property(window, source);
        if (!value) continue;
        const std::vector<std::string_view> groups = brace_groups(*value);
        if (groups.size() < 2) continue;
        if (is_x) return std::string{groups[0]};
        if (is_y) return std::string{groups[1]};
        return std::format("{{{},{}}}", groups[0], groups[1]);
    }
    return std::nullopt;
}

[[nodiscard]] const char* truth(bool value) noexcept {
    return value ? "True" : "False";
}

// GetProperty: giá trị script đã đặt, rồi của layout, rồi một vài mặc định của CEGUI; không biết thì rỗng
// (getProperty của client 2008 bắt lỗi rồi trả chuỗi rỗng).
[[nodiscard]] std::string property_of(const WindowRef& window, std::string_view name) {
    if (auto known = known_property(window, name)) return *std::move(known);
    if (auto derived = derived_position(window, name)) return *std::move(derived);
    if (name == "Visible") return truth(window.store->is_shown(window.name));
    if (name == "Disabled") return truth(window.store->is_disabled(window.name));
    if (name == "Selected") return truth(window.store->is_checked(window.name));
    if (name == "Alpha") return "1";
    return {};
}

// Các nút đánh dấu cùng cha với window (kể cả chính nó): nhóm mà SetCheck(1) của nút CheckMode 1 tắt.
[[nodiscard]] std::vector<std::string_view> check_group(const WindowRef& window) {
    std::vector<std::string_view> group{window.name};
    const std::int32_t index = window_index(window);
    if (index < 0) return group;
    const gui::GuiAsset& asset = *window.asset;
    const std::int32_t parent = asset.windows[static_cast<std::size_t>(index)].parent;
    if (parent < 0) return group;
    const gui::GuiRange range = layout_range(asset, index);
    for (std::uint32_t at = range.first; at < range.first + range.count; ++at) {
        const gui::GuiWindow& other = asset.windows[at];
        if (std::cmp_equal(at, index) || other.parent != parent) continue;
        if (other.type < 0 || static_cast<std::size_t>(other.type) >= asset.types.size()) continue;
        if (kind_of(asset.types[static_cast<std::size_t>(other.type)].renderer) == Kind::kCheckButton) {
            group.emplace_back(other.name);
        }
    }
    return group;
}

// ---- Window ----

int window_show(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->show(window.name);
    return 0;
}

int window_hide(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->hide(window.name);
    return 0;
}

int window_is_visible(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushboolean(state, is_visible(window) ? 1 : 0);
    return 1;
}

int window_enable(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->enable(window.name);
    return 0;
}

int window_disable(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->disable(window.name);
    return 0;
}

// SetText (UI_CEGUI 0x180040310): số thì sprintf("%d"), chuỗi thì nguyên văn (bộ phân tích thẻ màu chưa có ở bản này).
int window_set_text(lua_State* state) {
    const WindowRef& window = self(state);
    if (is_number(state, 2)) {
        window.store->set_text(window.name, std::format("{}", int_at(state, 2)));
    } else if (is_text(state, 2)) {
        window.store->set_text(window.name, from_script(text_at(state, 2)));
    }
    return 0;
}

int window_get_text(lua_State* state) {
    const WindowRef& window = self(state);
    const std::string text = to_script(property_of(window, "Text"));
    lua_pushlstring(state, text.data(), text.size());
    return 1;
}

// SetTextOriginal: chữ gốc chưa qua bộ phân tích thẻ, giữ ở thuộc tính TextOriginal để TransText đặt lại làm chữ hiện.
int window_set_text_original(lua_State* state) {
    const WindowRef& window = self(state);
    if (is_text(state, 2)) {
        window.store->set({.window = window.name, .name = "TextOriginal", .value = from_script(text_at(state, 2))});
    }
    return 0;
}

int window_trans_text(lua_State* state) {
    const WindowRef& window = self(state);
    if (const auto original = window.store->value({.window = window.name, .name = "TextOriginal"});
        original && !original->empty()) {
        window.store->set_text(window.name, *original);
    }
    return 0;
}

// SetToolTip (UI_CEGUI 0x18003b740): chữ gốc đi qua bộ phân tích thẻ rồi vào thuộc tính Tooltip.
int window_set_tooltip(lua_State* state) {
    const WindowRef& window = self(state);
    if (is_text(state, 2)) {
        window.store->set({.window = window.name, .name = "Tooltip", .value = from_script(text_at(state, 2))});
    }
    return 0;
}

// SetFadeState (FalagardSuperProgressProperties, CEGUIFalagard.dll 0x180079f20): giá trị > 0 mở đoạn mờ dần chừng đó giây
// (advance_widgets chạy nó), ngược lại xoá đoạn ấy và hiện cửa sổ lại (cả `this` khi cửa sổ là gốc layout); mọi giá trị đều
// đặt độ trong về 1.
void set_fade_state(const WindowRef& window, std::string_view value, float amount) {
    window.store->set({.window = window.name, .name = "SetFadeState", .value = value});
    window.store->set_fade(window.name, amount);
    if (!(amount > 0.0F)) {
        window.store->show(window.name);
        const std::int32_t index = window_index(window);
        if (index >= 0 && window.asset->windows[static_cast<std::size_t>(index)].parent < 0 && window.services != nullptr) {
            window.services->set_root_shown(true);
        }
    }
    window.store->set({.window = window.name, .name = "Alpha", .value = "1"});
}

// SetProperty (UI_CEGUI 0x18003f570): cả hai đối số phải là chuỗi; ShortImage đổi tên icon rồi đặt Image.
int window_set_property(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3)) return 0;
    const std::string name{text_at(state, 2)};
    if (name == "SetFadeState") {
        set_fade_state(window, text_at(state, 3), lua_isnumber(state, 3) != 0 ? to_float(lua_tonumber(state, 3)) : 0.0F);
        return 0;
    }
    if (name == "ShortImage") {
        const std::string icon = window.services != nullptr ? window.services->icon_full_name(text_at(state, 3))
                                                            : std::string{text_at(state, 3)};
        window.store->set({.window = window.name, .name = "Image", .value = icon});
        return 0;
    }
    window.store->set({.window = window.name, .name = name, .value = from_script(text_at(state, 3))});
    return 0;
}

int window_get_property(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const std::string value = to_script(property_of(window, text_at(state, 2)));
    lua_pushlstring(state, value.data(), value.size());
    return 1;
}

// Độ trong: GetAlpha đọc thuộc tính Alpha (mặc định 1); StartFade(từ, tới, giây) đặt thẳng đích (không có đồng hồ ở
// đây, như trọng tài): GetAlpha sau đó trả đúng số mà client gốc trả khi đoạn mờ dần đã chạy xong.
int window_get_alpha(lua_State* state) {
    const WindowRef& window = self(state);
    const std::string text = property_of(window, "Alpha");
    lua_pushlstring(state, text.data(), text.size());
    const double alpha = lua_isnumber(state, -1) != 0 ? lua_tonumber(state, -1) : 1.0;
    lua_pop(state, 1);
    lua_pushnumber(state, alpha);
    return 1;
}

int window_start_fade(lua_State* state) {
    const WindowRef& window = self(state);
    if (is_number(state, 3)) {
        window.store->set({.window = window.name, .name = "Alpha", .value = text_at(state, 3)});
    }
    return 0;
}

// Việc chỉ đổi cách hiện hay nhận phím (giành tiêu điểm, bắt phím) không có trạng thái để giữ: nhận lời gọi, không làm gì.
int window_ignore(lua_State* state) {
    static_cast<void>(self(state));
    return 0;
}

// ---- ProgressBar ----

// SetProgress (UI_CEGUI 0x18003a390): chỉ khi cả hai là số.
int progress_set(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || !is_number(state, 3)) return 0;
    window.store->set_progress(window.name, lua_tonumber(state, 2), lua_tonumber(state, 3));
    return 0;
}

// ---- Nút đánh dấu ----

// SetCheck (UI_CEGUI 0x180036e30): Selected = (int)n == 1. Nút CheckMode 1 được bật thì mọi nút đánh dấu cùng cha tắt.
int check_set(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    const bool is_on = int_at(state, 2) == 1;
    const std::optional<std::string> mode = known_property(window, "CheckMode");
    if (is_on && mode && *mode == "1") {
        const std::vector<std::string_view> group = check_group(window);
        window.store->check_one(window.name, group);
    } else {
        window.store->check(window.name, is_on);
    }
    return 0;
}

int check_get(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->is_checked(window.name) ? 1.0 : 0.0);
    return 1;
}

// ---- Nút action ----

// SetActionItem (UI_CEGUI 0x180028d70): id phải là số, nếu không là lỗi của script. Id -1 làm trống ô.
int action_set_item(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return raise(state, "SetActionItem: id phải là số");
    const std::int32_t id = int_at(state, 2);
    panel::ActionFace face{.id = id, .icon = {}};
    if (id != kEmptyAction && window.services != nullptr) face.icon = window.services->action_icon(id);
    window.store->set_action(window.name, std::move(face));
    return 0;
}

int action_get_item(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->action_item(window.name));
    return 1;
}

int action_set_pushed(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    window.store->push(window.name, int_at(state, 2) == 1);
    return 0;
}

int action_set_new_flash(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->flash(window.name);
    return 0;
}

// DoAction (UI_CEGUI 3.71.9509 0x180028c00): ô trống thì không làm gì; có action thì nhờ game dùng nó.
int action_do(lua_State* state) {
    const WindowRef& window = self(state);
    const std::int32_t action = window.store->action_item(window.name);
    if (action != kEmptyAction && window.calls != nullptr) {
        window.calls->push_back(Call{.ask = Ask::kDoAction, .text = std::format("{}\t{}", window.name, action)});
    }
    return 0;
}

int action_gloom(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->gloom(window.name, true);
    return 0;
}

int action_bright(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->gloom(window.name, false);
    return 0;
}

// Play(lặp) của cửa sổ hoạt ảnh.
int animate_play(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->play(window.name, lua_toboolean(state, 2) != 0);
    return 0;
}

// ---- Danh sách ----

int list_clear(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->clear_list(window.name);
    return 0;
}

// AddItem(chữ, id[, màu]): chữ là chuỗi, id là số (ListBox::AddItem), màu "AARRGGBB" tuỳ chọn.
int list_add_item(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_number(state, 3)) return 0;
    ListItem item{.text = from_script(text_at(state, 2)), .id = int_at(state, 3), .colour = {}};
    if (is_text(state, 4)) item.colour = std::string{text_at(state, 4)};
    window.store->add_item(window.name, std::move(item));
    return 0;
}

int list_first_selected(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->selected_item(window.name));
    return 1;
}

int list_select_by_id(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    window.store->select_item(window.name, int_at(state, 2));
    return 0;
}

int list_get_first_item(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->first_item(window.name));
    return 1;
}

int list_set_first_item(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    window.store->set_first_item(window.name, int_at(state, 2));
    return 0;
}

int list_get_click_item(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->clicked_item(window.name));
    return 1;
}

// ---- Cửa sổ phức hợp ----

int complex_clear(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->clear_elements(window.name);
    return 0;
}

// AddTextElement(chữ[, phông]), AddMoneyElement(số), AddJiaoZiElement(số): một phần tử "loại<tab>giá trị".
int complex_add_text(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_element(window.name, std::format("text\t{}", from_script(text_at(state, 2))));
    return 0;
}

int complex_add_money(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_element(window.name, std::format("money\t{}", text_at(state, 2)));
    return 0;
}

int complex_add_jiaozi(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_element(window.name, std::format("jiaozi\t{}", text_at(state, 2)));
    return 0;
}

// AddActionElement(action, số lượng, radio[, thêm]): ba số đầu bắt buộc.
int complex_add_action(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || !is_number(state, 3) || !is_number(state, 4)) return 0;
    std::string line = std::format("action\t{}\t{}\t{}", tostring_at(state, 2), tostring_at(state, 3), tostring_at(state, 4));
    if (!lua_isnoneornil(state, 5)) line += std::format("\t{}", tostring_at(state, 5));
    window.store->add_element(window.name, std::move(line));
    return 0;
}

int complex_keep_scroll(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->keep_scroll(window.name);
    return 0;
}

int complex_reset_scroll(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->reset_scroll(window.name);
    return 0;
}

// ---- Cửa sổ mesh ----

int mesh_set_fake_object(lua_State* state) {
    const WindowRef& window = self(state);
    if (is_text(state, 2)) {
        window.store->set({.window = window.name, .name = "FakeObject", .value = text_at(state, 2)});
    }
    return 0;
}

// Phương thức giả của chế độ đo: trả 0 để phép tính và phép nối chuỗi sau lời gọi không lỗi.
int missing_stub(lua_State* state) {
    lua_pushnumber(state, 0);
    return 1;
}

// __index của chế độ đo. Upvalue 1 là bảng phương thức thật, upvalue 2 là missing_stub; tên chưa có thì đếm rồi trả
// missing_stub, khoá không phải chuỗi thì trả nil.
int index_recording(lua_State* state) {
    if (lua_gettop(state) < 2 || lua_type(state, 2) != LUA_TSTRING) {
        lua_pushnil(state);
        return 1;
    }
    lua_pushvalue(state, 2);
    lua_rawget(state, lua_upvalueindex(1));
    if (lua_type(state, -1) != LUA_TNIL) return 1;
    lua_pop(state, 1);
    count_missing(state, text_at(state, 2));
    lua_pushvalue(state, lua_upvalueindex(2));
    return 1;
}

// ---- Hộp thả (Combobox) ----
// Nguồn: hàm cùng tên trong UI_CEGUI.dll 3.71.9509 (D:\XTLBB\Bin64; đọc bằng TOOLS/port/ghidra/DecompileAt.java, khoá m:
// cho địa chỉ hàm; bản trong dự án Ghidra TLBB cho cùng mã từng hàm). Danh sách thả giữ trong items/selected của Widgets
// như danh sách thường.

// ComboBoxAddItem và AddTextItem (0x180023700, 0x1800228f0): chữ (chuỗi hay số) và id (số, thiếu thì 0).
int combo_add_item(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_item(window.name, ListItem{.text = from_script(text_at(state, 2)), .id = int_at(state, 3), .colour = {}});
    return 0;
}

// ResetList (Combobox::resetList -> Listbox::resetList): bỏ mọi mục.
int combo_reset_list(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->clear_list(window.name);
    return 0;
}

// ResetText (Combobox::resetText): chữ của ô nhập về rỗng.
int combo_reset_text(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->set_text(window.name, {});
    return 0;
}

int combo_clear_selections(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->clear_selection(window.name);
    return 0;
}

// GetCurrentSelect (0x180025d60): (chữ, id) của mục đang chọn; chưa chọn thì ("-1", -1).
int combo_get_current(lua_State* state) {
    const WindowRef& window = self(state);
    const ListItem* item = window.store->chosen_item(window.name);
    if (item == nullptr) {
        lua_pushstring(state, "-1");
        lua_pushnumber(state, -1);
        return 2;
    }
    const std::string text = to_script(item->text);
    lua_pushlstring(state, text.data(), text.size());
    lua_pushnumber(state, item->id);
    return 2;
}

// SetCurrentSelect(chỉ số từ 0) (0x180037f70): chọn mục rồi đặt chữ của ô nhập bằng chữ của mục; chỉ số ngoài danh sách
// thì bỏ qua.
int combo_set_current(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    const std::int32_t index = int_at(state, 2);
    if (index < 0 || !window.store->select_index(window.name, static_cast<std::size_t>(index))) return 0;
    if (const ListItem* item = window.store->chosen_item(window.name); item != nullptr) {
        const std::string text = item->text;
        window.store->set_text(window.name, text);
    }
    return 0;
}

int combo_count(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, static_cast<lua_Number>(window.store->item_count(window.name)));
    return 1;
}

// GetTextItemId(chỉ số) (0x180027740): id của mục; chỉ số ngoài danh sách thì không trả gì.
int combo_item_id(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    const std::int32_t index = int_at(state, 2);
    const ListItem* item = index < 0 ? nullptr : window.store->item_at(window.name, static_cast<std::size_t>(index));
    if (item == nullptr) return 0;
    lua_pushnumber(state, item->id);
    return 1;
}

// SetTextItemText(chỉ số, chữ) (0x18003b930).
int combo_set_item_text(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || !is_text(state, 3)) return 0;
    const std::int32_t index = int_at(state, 2);
    if (index < 0) return 0;
    window.store->set_item_text(window.name, static_cast<std::size_t>(index), from_script(text_at(state, 3)));
    return 0;
}

// ---- Bảng nhiều cột (CtrlList, MultiColumnList của CEGUI) ----
// Hàng và cột đánh số từ 0; id cột do script đặt ở AddColumn. Phương thức trùng tên với lớp khác (DeleteItem, SetItemText...)
// chỉ chạy cho Kind::kCtrlList.

[[nodiscard]] bool is_ctrl_list(const WindowRef& window) noexcept {
    return window.kind == Kind::kCtrlList;
}

// AddColumn(chữ, id, bề rộng) (0x18001e570).
int grid_add_column(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_column(window.name,
        GridColumn{.title = from_script(text_at(state, 2)), .id = int_at(state, 3), .width = to_float(lua_tonumber(state, 4))},
        std::nullopt);
    return 0;
}

// InsertColumn(chữ, id, bề rộng, vị trí) (0x180028840); vị trí âm hay vượt số cột thì thêm cuối.
int grid_insert_column(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const auto position = static_cast<std::size_t>(static_cast<std::uint32_t>(int_at(state, 5)));
    window.store->add_column(window.name,
        GridColumn{.title = from_script(text_at(state, 2)), .id = int_at(state, 3), .width = to_float(lua_tonumber(state, 4))},
        position);
    return 0;
}

// Đối số 5 của AddNewItem là màu chữ, của AddNewItemTooltips là chữ gợi ý.
enum class FifthArgument : std::uint8_t { kColour, kTooltip };

// AddNewItem(chữ, id cột, hàng[, màu]) (0x1800216f0) và AddNewItemTooltips(chữ, id cột, hàng[, gợi ý]) (0x180021aa0): hàng
// đã có ô ở cột 0 thì ô vào hàng đó ở cột mang id, không thì mở hàng mới.
int grid_put(lua_State* state, FifthArgument fifth) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const std::int32_t column = int_at(state, 3);
    GridCell cell{.text = from_script(text_at(state, 2)), .tooltip = {}, .id = column, .colour = {}, .user = 0};
    if (is_text(state, 5)) {
        std::string extra = from_script(text_at(state, 5));
        if (fifth == FifthArgument::kColour) {
            cell.colour = std::move(extra);
        } else {
            cell.tooltip = std::move(extra);
        }
    }
    window.store->put_cell(window.name, std::move(cell), int_at(state, 4));
    return 0;
}

int grid_add_new_item(lua_State* state) {
    return grid_put(state, FifthArgument::kColour);
}

int grid_add_new_item_tooltips(lua_State* state) {
    return grid_put(state, FifthArgument::kTooltip);
}

// SetItemText(hàng, cột, chữ) (0x180039790).
int grid_set_text(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    if (!is_text(state, 4)) return 0;
    window.store->set_cell_text(window.name, int_at(state, 2), int_at(state, 3), from_script(text_at(state, 4)));
    return 0;
}

// GetItemText(hàng, cột) (0x180026410). Ô không có thì hàm gốc không đẩy gì rồi trả 1 kết quả, tức Lua nhận giá trị ở đỉnh
// ngăn xếp (đối số cuối); giữ nguyên.
int grid_get_text(lua_State* state) {
    const WindowRef& window = self(state);
    const std::optional<std::string_view> text = window.store->cell_text(window.name, int_at(state, 2), int_at(state, 3));
    if (!text) return 1;
    const std::string script = to_script(*text);
    lua_pushlstring(state, script.data(), script.size());
    return 1;
}

// SetRowUserData(hàng, số) (0x18003a5c0), GetRowUserData(hàng) (0x180027220), SetRowTooltip(hàng, chữ) (0x18003a440): theo ô
// cột 0 của hàng.
int grid_set_row_data(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->set_row_data(window.name, {.row = int_at(state, 2), .value = int_at(state, 3)});
    return 0;
}

int grid_get_row_data(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, window.store->row_data(window.name, int_at(state, 2)));
    return 1;
}

int grid_set_row_tooltip(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 3)) return 0;
    window.store->set_row_tooltip(window.name, int_at(state, 2), from_script(text_at(state, 3)));
    return 0;
}

// DeleteItem(hàng) (0x180024680), RemoveAllItem() (0x180032c40).
int grid_delete(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    window.store->remove_row(window.name, int_at(state, 2));
    return 0;
}

int grid_clear(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    window.store->clear_rows(window.name);
    return 0;
}

// GetItemCount() (số hàng, 0x1800262d0), GetColumnCount() (0x180025cc0).
int grid_row_count(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    lua_pushnumber(state, static_cast<lua_Number>(window.store->row_count(window.name)));
    return 1;
}

int grid_column_count(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, static_cast<lua_Number>(window.store->column_count(window.name)));
    return 1;
}

// GetSelectItem() (0x180027380): id của ô cột 0 ở hàng đang chọn, -1 khi không chọn. SetSelectItem(hàng) (0x18003aa20).
int grid_get_selected(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    lua_pushnumber(state, window.store->selected_row(window.name));
    return 1;
}

int grid_select(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    window.store->select_row(window.name, int_at(state, 2));
    return 0;
}

// SetVertScollPosition(hàng) (0x18003bcd0; tên sai chính tả của gốc): 0 đến số hàng.
int grid_scroll(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_ctrl_list(window)) return other_kind(state, window);
    window.store->scroll_rows(window.name, int_at(state, 2));
    return 0;
}

// RemoveColumnByPos(chỉ số) (0x180032cb0).
int grid_remove_column(lua_State* state) {
    const WindowRef& window = self(state);
    const std::int32_t index = int_at(state, 2);
    if (index >= 0) window.store->remove_column(window.name, static_cast<std::size_t>(index));
    return 0;
}

// ---- Ảnh tĩnh ----

// SetImage(biểu tượng) hay SetImage(bộ ảnh, ảnh) (0x1800390f0): thuộc tính Image là tên đầy đủ của biểu tượng, hay
// "set:<bộ ảnh> image:<ảnh>".
int image_set(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    std::string value;
    if (is_text(state, 3)) {
        value = std::format("set:{} image:{}", text_at(state, 2), text_at(state, 3));
    } else if (window.services != nullptr) {
        value = window.services->icon_full_name(text_at(state, 2));
    } else {
        value = std::string{text_at(state, 2)};
    }
    window.store->set({.window = window.name, .name = "Image", .value = value});
    return 0;
}

// Đọc số 32 bit từ chuỗi thập lục phân "AARRGGBB" (stringToColour: tối đa 8 chữ số đầu); 0xFF000000 khi chuỗi không mở đầu
// bằng chữ số thập lục phân.
[[nodiscard]] std::uint32_t colour_of(std::string_view text) noexcept {
    constexpr std::uint32_t kBlack = 0xFF000000U;
    constexpr std::size_t kDigits = 8;
    std::uint32_t value = 0;
    std::size_t seen = 0;
    for (const char letter : text.substr(0, kDigits)) {
        std::uint32_t digit = 0;
        if (letter >= '0' && letter <= '9') {
            digit = static_cast<std::uint32_t>(letter - '0');
        } else if (letter >= 'a' && letter <= 'f') {
            digit = static_cast<std::uint32_t>(letter - 'a') + 10U;
        } else if (letter >= 'A' && letter <= 'F') {
            digit = static_cast<std::uint32_t>(letter - 'A') + 10U;
        } else {
            break;
        }
        value = (value << 4U) | digit;
        ++seen;
    }
    return seen == 0 ? kBlack : value;
}

// SetImageColor("AARRGGBB") (0x1800393f0): thuộc tính ImageColours với cả bốn góc cùng màu.
int image_set_colour(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const std::uint32_t colour = colour_of(text_at(state, 2));
    window.store->set({.window = window.name,
        .name = "ImageColours",
        .value = std::format("tl:{0:08X} tr:{0:08X} bl:{0:08X} br:{0:08X}", colour)});
    return 0;
}

// ---- Thanh cuộn ----

// Số trong thuộc tính chuỗi của cửa sổ (script đặt, không thì layout); fallback khi không có hay không phải số.
[[nodiscard]] double number_property(lua_State* state, const WindowRef& window, std::string_view name, double fallback) {
    const std::string text = property_of(window, name);
    lua_pushlstring(state, text.data(), text.size());
    const double value = lua_isnumber(state, -1) != 0 ? lua_tonumber(state, -1) : fallback;
    lua_pop(state, 1);
    return value;
}

// SetPosition(số) (0x18003a340): Scrollbar::setScrollPosition kẹp vào 0..max(DocumentSize - PageSize, 0), NaN về 0
// (docs/GIAO-DIEN-2026.md 6.4). Mặc định của Scrollbar: DocumentSize 1, PageSize 0.
int scrollbar_set_position(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    const float document = to_float(number_property(state, window, "DocumentSize", 1.0));
    const float page = to_float(number_property(state, window, "PageSize", 0.0));
    const float limit = std::max(document - page, 0.0F);
    const float wanted = to_float(lua_tonumber(state, 2));
    const float position = wanted >= 0.0F ? (wanted <= limit ? wanted : limit) : 0.0F;
    window.store->set({.window = window.name, .name = "ScrollPosition", .value = std::format("{}", position)});
    return 0;
}

// GetPosition() (0x180027150): vị trí hiện tại.
int scrollbar_get_position(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, number_property(state, window, "ScrollPosition", 0.0));
    return 1;
}

// AddInfo (FalagardInfoList::AddInfo, CEGUIFalagard.dll 0x18006b940): thêm mục chữ id 0, giữ tối đa kInfoLimit mục, hiện
// danh sách. Mục mang tuổi thọ Life và tốc độ mờ FadeSpeed của cửa sổ (thuộc tính script đặt, không thì của layout); nhịp thời
// gian của chúng là advance_widgets. Tuổi thọ và độ trong của mục không vào trạng thái ghi (describe).
int list_add_info(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const InfoLife life{.life_ms = luanum_to_int32(number_property(state, window, "Life", kInfoLifeMs)),
        .fade_speed = luanum_to_int32(number_property(state, window, "FadeSpeed", kInfoFadeSpeed)),
        .alpha = 1.0F};
    window.store->add_info(window.name, ListItem{.text = from_script(text_at(state, 2)), .id = 0, .colour = {}}, life, kInfoLimit);
    return 0;
}

// ---- Nhận và bỏ qua (hiệu ứng chỉ để nhìn) ----

// Phương thức của bản 2026 mà tác dụng chỉ nằm ở hình vẽ hay ở danh sách cửa sổ con động (hoạt ảnh Tween, cuộn, thanh cuộn
// ẩn hiện, dấu chọn nhiều mục, nháy của danh sách, xoá phần tử con...): script không đọc lại được gì và gui tự bố trí, nên
// nhận mọi đối số rồi không làm gì. Khác gốc: cửa sổ con tạo lúc chạy (AddChild, Clear...) chưa có ở host.
int visual_only(lua_State* /*state*/) {
    return 0;
}

// IsActive (0x180028ad0): Window::isActive, true sau khi cửa sổ được kích hoạt (bấm vào, đưa lên trước). Khác gốc: chưa theo dõi
// kích hoạt nên luôn false.
int window_is_active(lua_State* state) {
    static_cast<void>(self(state));
    lua_pushboolean(state, 0);
    return 1;
}

// ---- Hình học ----

// Ô điểm ảnh của cửa sổ theo lần dàn trang gần nhất của host; ô rỗng (mọi số đo 0) khi host chưa dàn trang.
[[nodiscard]] PixelBox box_of(const WindowRef& window) {
    if (window.services == nullptr) return {};
    return window.services->window_box(window.name).value_or(PixelBox{});
}

// Cỡ màn hình (cửa sổ gốc của CEGUI); nullopt khi host không biết, khi đó phép kẹp theo màn hình bị bỏ.
[[nodiscard]] std::optional<PixelBox> screen_of(const WindowRef& window) {
    if (window.services == nullptr) return std::nullopt;
    return window.services->screen_box();
}

void push_pixels(lua_State* state, float value) {
    lua_pushnumber(state, luanum_to_int32(static_cast<double>(value)));
}

void push_float(lua_State* state, float value) {
    lua_pushnumber(state, static_cast<double>(value));
}

// Đặt vị trí hay cỡ bằng điểm ảnh: Override của thuộc tính hình học mà gui::layout đọc (UnifiedXPosition, AbsolutePosition...).
void put_pair(const WindowRef& window, std::string_view name, float first, float second) {
    window.store->set({.window = window.name, .name = name, .value = std::format("{{{},{}}}", first, second)});
}

// GetWindowSize (0x1800278f0): cỡ điểm ảnh của cửa sổ, hai số nguyên (int).
int window_get_size(lua_State* state) {
    const PixelBox box = box_of(self(state));
    push_pixels(state, box.w);
    push_pixels(state, box.h);
    return 2;
}

// GetPixelRect (0x1800270a0): bốn số nguyên theo thứ tự trái, phải, trên, dưới (Rect của CEGUI 0.4 giữ trên, dưới, trái,
// phải; hàm đẩy trái, phải, trên, dưới). Khác gốc: ô chưa cắt theo cửa sổ cha.
int window_get_pixel_rect(lua_State* state) {
    const PixelBox box = box_of(self(state));
    push_pixels(state, box.x);
    push_pixels(state, box.x + box.w);
    push_pixels(state, box.y);
    push_pixels(state, box.y + box.h);
    return 4;
}

// GetAbsolutePositionToScreen (0x1800255f0): vị trí trên trái so với màn hình, cộng vị trí so với cha của chính nó và của
// các cha (tối đa 50 cấp), nên bằng toạ độ trên màn hình; hai số thực.
int window_get_screen_position(lua_State* state) {
    const PixelBox box = box_of(self(state));
    push_float(state, box.x);
    push_float(state, box.y);
    return 2;
}

// SetWindowSize (0x18003bf40): cỡ điểm ảnh (rộng, cao), lấy phần nguyên; số không phải số tính là 0.
int window_set_size(lua_State* state) {
    const WindowRef& window = self(state);
    put_pair(window, "AbsoluteSize", static_cast<float>(int_at(state, 2)), static_cast<float>(int_at(state, 3)));
    return 0;
}

// SetWindowCenter (0x18003be50): đặt tâm cửa sổ ở (x, y) so với cha, điểm ảnh. Cần cả hai là số.
int window_set_center(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || !is_number(state, 3)) return 0;
    const PixelBox box = box_of(window);
    constexpr float kHalf = 0.5F;
    put_pair(window, "AbsolutePosition", static_cast<float>(int_at(state, 2)) - box.w * kHalf,
        static_cast<float>(int_at(state, 3)) - box.h * kHalf);
    return 0;
}

// CenterWindow (0x180022f80): đặt giữa cửa sổ cha (cửa sổ gốc của layout nằm giữa màn hình). Bản gốc lấy tâm của ô tuyệt đối
// của cha để đặt vị trí so với cha, nên chỉ đúng khi cha ở gốc toạ độ; giữ nguyên phép tính. Không làm gì khi host chưa dàn trang.
int window_center(lua_State* state) {
    const WindowRef& window = self(state);
    const std::int32_t index = window_index(window);
    if (index < 0 || window.services == nullptr) return 0;
    const std::int32_t parent = window.asset->windows[static_cast<std::size_t>(index)].parent;
    const std::optional<PixelBox> around =
        parent < 0 ? window.services->screen_box()
                   : window.services->window_box(window.asset->windows[static_cast<std::size_t>(parent)].name);
    if (!around) return 0;
    const PixelBox box = box_of(window);
    constexpr float kHalf = 0.5F;
    put_pair(window, "AbsolutePosition", (around->x + around->x + around->w) * kHalf - box.w * kHalf,
        (around->y + around->y + around->h) * kHalf - box.h * kHalf);
    return 0;
}

// SetXAttachPos(điểm neo, khoảng cách, cờ) (0x18003bfc0): đặt cửa sổ cạnh một điểm neo theo chiều ngang. Cờ 0 hay
// cửa sổ tràn màn hình nếu đặt bên phải thì nằm bên trái điểm neo (neo - rộng), không thì neo + khoảng cách. Trả vị trí x.
int window_set_x_attach(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3) || !is_number(state, 4)) return 0;
    const float anchor = to_float(lua_tonumber(state, 2));
    const float gap = to_float(lua_tonumber(state, 3));
    const float width = box_of(window).w;
    const std::optional<PixelBox> screen = screen_of(window);
    float across = anchor - width;
    if (int_at(state, 4) != 0) {
        const float beside = gap + anchor;
        const bool is_overflow = screen && beside + width > screen->w;
        if (!is_overflow) across = beside;
    }
    window.store->set({.window = window.name, .name = "UnifiedXPosition", .value = std::format("{{0,{}}}", across)});
    push_float(state, across);
    return 1;
}

// AutoMousePosition(x, y) (0x180022c40): đặt cửa sổ ở điểm (x, y), kéo vào trong khi tràn mép phải hay mép dưới màn hình.
int window_auto_mouse_position(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3)) return 0;
    float across = to_float(lua_tonumber(state, 2));
    float down = to_float(lua_tonumber(state, 3));
    const PixelBox box = box_of(window);
    if (const std::optional<PixelBox> screen = screen_of(window)) {
        if (screen->w <= across) across = screen->w - box.w;
        if (screen->h <= down) down = screen->h - box.h;
    }
    put_pair(window, "AbsolutePosition", across, down);
    return 0;
}

// PositionSelf(x, y, dời x, dời y) (0x180029580): đặt cửa sổ cạnh điểm (x, y), mỗi chiều: nếu còn chỗ (cỡ + dời + 5 không quá
// màn hình) thì nằm ở dời + 0,5, không thì lùi về phía trước điểm (điểm - cỡ); không âm. Trả hai vị trí. Khác gốc: bản gốc gọi một
// hàm ảo của đối tượng con của cửa sổ (trước phép đo) mà chưa biết là gì; không biết cỡ màn hình thì coi là còn chỗ.
int window_position_self(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3)) return 0;
    constexpr float kMargin = 5.0F;
    constexpr float kHalfPixel = 0.5F;
    const float point_x = to_float(lua_tonumber(state, 2));
    const float point_y = to_float(lua_tonumber(state, 3));
    const float shift_x = to_float(lua_tonumber(state, 4));
    const float shift_y = to_float(lua_tonumber(state, 5));
    const PixelBox box = box_of(window);
    const std::optional<PixelBox> screen = screen_of(window);
    float across = point_x - box.w;
    if (!screen || box.w + shift_x + kMargin <= screen->w) across = shift_x + kHalfPixel;
    float down = point_y - box.h;
    if (!screen || box.h + shift_y + kMargin <= screen->h) down = shift_y + kHalfPixel;
    if (across < 0.0F) across = 0.0F;
    if (down < 0.0F) down = 0.0F;
    window.store->set({.window = window.name, .name = "UnifiedXPosition", .value = std::format("{{0,{}}}", across)});
    window.store->set({.window = window.name, .name = "UnifiedYPosition", .value = std::format("{{0,{}}}", down)});
    push_float(state, across);
    push_float(state, down);
    return 2;
}

// SetPopMenuPos(x, y) (0x18003a190): đặt menu bật lên ở (x, y), lùi về phía trước điểm khi tràn mép phải hay mép dưới; vị trí
// đặt theo tỉ lệ của màn hình. Không làm gì khi không biết cỡ màn hình.
int menu_set_position(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3)) return 0;
    const std::optional<PixelBox> screen = screen_of(window);
    if (!screen) return 0;
    float across = to_float(lua_tonumber(state, 2));
    float down = to_float(lua_tonumber(state, 3));
    const PixelBox box = box_of(window);
    if (screen->w < box.w + across) across -= box.w;
    if (screen->h < box.h + down) down -= box.h;
    window.store->set({.window = window.name, .name = "UnifiedXPosition", .value = std::format("{{{},0}}", across / screen->w)});
    window.store->set({.window = window.name, .name = "UnifiedYPosition", .value = std::format("{{{},0}}", down / screen->h)});
    return 0;
}

// OpenPopMenu và ClosePopMenu (0x1800294e0, 0x1800236e0): PopupMenu::openPopupMenu / closePopupMenu là hiện và giấu menu.
int menu_open(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->show(window.name);
    return 0;
}

int menu_close(lua_State* state) {
    const WindowRef& window = self(state);
    window.store->hide(window.name);
    return 0;
}

// SetClippedByParent(số) (0x180037a40): 0 thì không cắt theo cha và luôn nằm trên cùng, số khác thì cắt theo cha.
int window_set_clipped(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    const bool is_clipped = int_at(state, 2) != 0;
    window.store->set({.window = window.name, .name = "ClippedByParent", .value = truth(is_clipped)});
    if (!is_clipped) window.store->set({.window = window.name, .name = "AlwaysOnTop", .value = "True"});
    return 0;
}

// ---- Nháy, thanh cuộn dọc ----

// FlashMe(số) (0x180025470): thuộc tính Flash là "1" khi số là 1, không thì "0".
int window_flash_me(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    window.store->set({.window = window.name, .name = "Flash", .value = int_at(state, 2) == 1 ? "1" : "0"});
    return 0;
}

// SetFlash(số) (0x180029190): thuộc tính Flash là "1" khi số dương, không thì "0". Hai số (mục, cờ) là nháy một mục của danh sách
// (0x180038860): chỉ thấy được ở hình vẽ nên bỏ qua.
int window_set_flash(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || is_number(state, 3)) return 0;
    window.store->set({.window = window.name, .name = "Flash", .value = int_at(state, 2) > 0 ? "1" : "0"});
    return 0;
}

// SetVertScrollbarPosition(số) (0x18003bdb0) và GetVertScrollbarPosition() (0x1800278a0): vị trí thanh cuộn dọc của vùng chứa.
// Khác gốc: giữ nguyên số script đưa, chưa kẹp theo cỡ tài liệu của vùng chứa.
int container_set_scroll(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    window.store->set({.window = window.name, .name = "VertScrollbarPosition", .value = std::format("{}", to_float(lua_tonumber(state, 2)))});
    return 0;
}

int container_get_scroll(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, number_property(state, window, "VertScrollbarPosition", 0.0));
    return 1;
}

// GetListItemCount() (0x180026780, 0x1800267d0): số mục của danh sách; cửa sổ không phải danh sách trả số cửa sổ con khai trong
// layout (Window::getChildCount).
int container_item_count(lua_State* state) {
    const WindowRef& window = self(state);
    switch (window.kind) {
    case Kind::kListBox:
    case Kind::kComboBox:
    case Kind::kInfoList:
    case Kind::kCtrlList: lua_pushnumber(state, static_cast<double>(window.store->item_count(window.name))); return 1;
    default: break;
    }
    const std::int32_t index = window_index(window);
    lua_pushnumber(state, static_cast<double>(index < 0 ? 0 : std::ranges::count(window.asset->windows, index, &gui::GuiWindow::parent)));
    return 1;
}

// ---- Sự kiện nối lúc chạy ----

// SetEvent(sự kiện, hàm[, số]) (0x180038240): nối hàm Lua tên `hàm` vào sự kiện CEGUI của cửa sổ (Window::setdEvent). Cần hai
// chuỗi; số thứ ba không phải số tính là 0. Host đọc danh sách nối bằng Widgets::event_bindings.
int window_set_event(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_text(state, 3)) return 0;
    window.store->bind_event(window.name,
        panel::EventBinding{.event = std::string{text_at(state, 2)},
            .handler = std::string{text_at(state, 3)},
            .flag = is_number(state, 4) ? int_at(state, 4) : 0});
    return 0;
}

// RemoveEvent(sự kiện) (0x180032ce0): EventSet::removeEvent bỏ sự kiện cùng mọi hàm nối vào nó. Hàm gốc trả 1 mà không đẩy gì
// nên script nhận giá trị trên cùng của ngăn xếp (chính chuỗi tên sự kiện); thiếu chuỗi thì không trả gì.
int window_remove_event(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->unbind_event(Key{.window = window.name, .name = text_at(state, 2)});
    return 1;
}

// ---- Cửa sổ mô hình (UI model manager của Game.exe: DAT_1800b6250 cho FakeObject, DAT_1800b6258 cho cửa sổ) ----

// Việc nhờ game: tên cửa sổ rồi các đối số, cách nhau tab.
void ask_mesh(const WindowRef& window, Ask what, const std::string& arguments) {
    if (window.calls != nullptr) window.calls->push_back(Call{.ask = what, .text = arguments});
}

// RotateBegin(tốc độ) (0x180033090): quay FakeObject của cửa sổ (thuộc tính FakeObject) với tốc độ bằng nửa số đưa vào.
int mesh_rotate_begin(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2)) return 0;
    ask_mesh(window, Ask::kMeshRotateBegin, std::format("{}\t{}", property_of(window, "FakeObject"), to_float(lua_tonumber(state, 2)) * 0.5F));
    return 0;
}

// RotateEnd() (0x180033250): thôi quay FakeObject của cửa sổ.
int mesh_rotate_end(lua_State* state) {
    const WindowRef& window = self(state);
    ask_mesh(window, Ask::kMeshRotateEnd, property_of(window, "FakeObject"));
    return 0;
}

// RotateBeginEx(tên, tốc độ) (0x1800331c0): quay mô hình `tên` của hệ cửa sổ với tốc độ bằng nửa số đưa vào.
int mesh_rotate_begin_ex(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_number(state, 3)) return 0;
    ask_mesh(window, Ask::kMeshRotateBeginEx, std::format("{}\t{}", text_at(state, 2), to_float(lua_tonumber(state, 3)) * 0.5F));
    return 0;
}

// RotateEndEx() (0x180033330): thôi quay mô hình của cửa sổ.
int mesh_rotate_end_ex(lua_State* state) {
    const WindowRef& window = self(state);
    ask_mesh(window, Ask::kMeshRotateEndEx, std::string{window.name});
    return 0;
}

// AttachWindowEx(tên) (0x180022ac0): gắn mô hình `tên` vào cửa sổ, kèm cỡ điểm ảnh của cửa sổ (rộng, cao).
int mesh_attach(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    const PixelBox box = box_of(window);
    ask_mesh(window, Ask::kMeshAttach,
        std::format("{}\t{}\t{}\t{}", window.name, text_at(state, 2), luanum_to_int32(static_cast<double>(box.w)),
            luanum_to_int32(static_cast<double>(box.h))));
    return 0;
}

// DetachWindowEx() (0x180024e60) và RestPositonEx() (0x180033060): gỡ mô hình khỏi cửa sổ; đưa mô hình về chỗ cũ.
int mesh_detach(lua_State* state) {
    const WindowRef& window = self(state);
    ask_mesh(window, Ask::kMeshDetach, std::string{window.name});
    return 0;
}

int mesh_rest_position(lua_State* state) {
    const WindowRef& window = self(state);
    ask_mesh(window, Ask::kMeshRestPosition, std::string{window.name});
    return 0;
}

// SetCameraEx(x, y, z[, w]) (0x180036d70): đặt camera của mô hình trong cửa sổ; w mặc định 0. Số cuối giữ lại để GetCameraEx đọc.
int mesh_set_camera(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_number(state, 2) || !is_number(state, 3) || !is_number(state, 4)) return 0;
    const float eye_x = to_float(lua_tonumber(state, 2));
    const float eye_y = to_float(lua_tonumber(state, 3));
    const float eye_z = to_float(lua_tonumber(state, 4));
    const float extra = is_number(state, 5) ? to_float(lua_tonumber(state, 5)) : 0.0F;
    window.store->set({.window = window.name, .name = "CameraExX", .value = std::format("{}", eye_x)});
    window.store->set({.window = window.name, .name = "CameraExY", .value = std::format("{}", eye_y)});
    window.store->set({.window = window.name, .name = "CameraExZ", .value = std::format("{}", eye_z)});
    ask_mesh(window, Ask::kMeshSetCamera, std::format("{}\t{}\t{}\t{}\t{}", window.name, eye_x, eye_y, eye_z, extra));
    return 0;
}

// GetCameraEx() (0x180025770): camera hiện tại của mô hình, ba số. Khác gốc: hỏi hệ cửa sổ của game; bản này trả số script đã đặt
// bằng SetCameraEx (ba thuộc tính CameraExX, CameraExY, CameraExZ), chưa đặt thì 0 0 0.
int mesh_get_camera(lua_State* state) {
    const WindowRef& window = self(state);
    for (const char* axis : {"CameraExX", "CameraExY", "CameraExZ"}) lua_pushnumber(state, number_property(state, window, axis, 0.0));
    return 3;
}

// ChangeCameraDistanceEx(tên, hướng, mức) (0x1800230d0): nhờ hệ cửa sổ của game dời camera của mô hình `tên` lại gần hay ra xa.
int mesh_change_camera_distance(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2) || !is_number(state, 3) || !is_number(state, 4)) return 0;
    ask_mesh(window, Ask::kMeshZoom,
        std::format("{}\t{}\t{}\t{}", window.name, text_at(state, 2), int_at(state, 3), to_float(lua_tonumber(state, 4))));
    return 0;
}

// ---- Khung chat và vùng chứa ----

// InsertChatString(chuỗi) (0x180028700): chèn một dòng chat vào cuối khung (chỉ số -1). Lưu như một phần tử chữ.
int chat_insert(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_element(window.name, std::format("text\t{}", from_script(text_at(state, 2))));
    return 0;
}

// GetScrollPosition() (0x180027330): vị trí cuộn của vùng chứa danh sách, số thực; chưa đặt thì 0. Khác gốc: không có hàm đặt
// riêng (SetScrollPosition của bản này chỉ là cờ giữ chỗ cuộn), nên chỉ trả thuộc tính ScrollPosition script hay layout đã đặt.
int container_scroll_position(lua_State* state) {
    const WindowRef& window = self(state);
    lua_pushnumber(state, number_property(state, window, "ScrollPosition", 0.0));
    return 1;
}

// SetAimEditBox(tên) (0x18003a0a0): ô nhập mà khung chat gửi chữ tới. Giữ tên làm thuộc tính AimEditBox.
int chat_set_aim_edit_box(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->set({.window = window.name, .name = "AimEditBox", .value = text_at(state, 2)});
    return 0;
}

struct Method {
    const char* name;
    lua_CFunction function;
};

// Bảng phương thức chung của mọi widget (xem "Khác gốc" ở đầu widget.hpp).
constexpr std::array kMethods = {
    Method{.name = "Show", .function = &window_show},
    Method{.name = "Hide", .function = &window_hide},
    Method{.name = "IsVisible", .function = &window_is_visible},
    Method{.name = "Enable", .function = &window_enable},
    Method{.name = "Disable", .function = &window_disable},
    Method{.name = "SetText", .function = &window_set_text},
    Method{.name = "GetText", .function = &window_get_text},
    Method{.name = "SetTextOriginal", .function = &window_set_text_original},
    Method{.name = "TransText", .function = &window_trans_text},
    Method{.name = "SetToolTip", .function = &window_set_tooltip},
    Method{.name = "SetProperty", .function = &window_set_property},
    Method{.name = "GetProperty", .function = &window_get_property},
    Method{.name = "GetAlpha", .function = &window_get_alpha},
    Method{.name = "StartFade", .function = &window_start_fade},
    Method{.name = "SetForce", .function = &window_ignore},
    Method{.name = "CaptureInput", .function = &window_ignore},
    Method{.name = "PlayWarning", .function = &window_ignore},
    Method{.name = "SetProgress", .function = &progress_set},
    Method{.name = "SetCheck", .function = &check_set},
    Method{.name = "GetCheck", .function = &check_get},
    Method{.name = "SetActionItem", .function = &action_set_item},
    Method{.name = "GetActionItem", .function = &action_get_item},
    Method{.name = "SetPushed", .function = &action_set_pushed},
    Method{.name = "SetNewFlash", .function = &action_set_new_flash},
    Method{.name = "DoAction", .function = &action_do},
    Method{.name = "Gloom", .function = &action_gloom},
    Method{.name = "Bright", .function = &action_bright},
    Method{.name = "Play", .function = &animate_play},
    Method{.name = "ClearListBox", .function = &list_clear},
    Method{.name = "AddItem", .function = &list_add_item},
    Method{.name = "AddInfo", .function = &list_add_info},
    Method{.name = "GetFirstSelectItem", .function = &list_first_selected},
    Method{.name = "SetItemSelectByItemID", .function = &list_select_by_id},
    Method{.name = "GetCurrentFirstItem", .function = &list_get_first_item},
    Method{.name = "SetCurrentFirstItem", .function = &list_set_first_item},
    Method{.name = "GetClickItem", .function = &list_get_click_item},
    Method{.name = "ClearAllElement", .function = &complex_clear},
    Method{.name = "AddTextElement", .function = &complex_add_text},
    Method{.name = "AddMoneyElement", .function = &complex_add_money},
    Method{.name = "AddJiaoZiElement", .function = &complex_add_jiaozi},
    Method{.name = "AddActionElement", .function = &complex_add_action},
    Method{.name = "SetScrollPosition", .function = &complex_keep_scroll},
    Method{.name = "ResetScrollPosition", .function = &complex_reset_scroll},
    Method{.name = "SetFakeObject", .function = &mesh_set_fake_object},
    Method{.name = "ComboBoxAddItem", .function = &combo_add_item},
    Method{.name = "AddTextItem", .function = &combo_add_item},
    Method{.name = "ResetList", .function = &combo_reset_list},
    Method{.name = "ResetText", .function = &combo_reset_text},
    Method{.name = "ResetLastSelectIndex", .function = &window_ignore},
    Method{.name = "ClearAllSelections", .function = &combo_clear_selections},
    Method{.name = "GetCurrentSelect", .function = &combo_get_current},
    Method{.name = "SetCurrentSelect", .function = &combo_set_current},
    Method{.name = "GetListCount", .function = &combo_count},
    Method{.name = "GetTextItemId", .function = &combo_item_id},
    Method{.name = "SetTextItemText", .function = &combo_set_item_text},
    Method{.name = "AddColumn", .function = &grid_add_column},
    Method{.name = "InsertColumn", .function = &grid_insert_column},
    Method{.name = "AddNewItem", .function = &grid_add_new_item},
    Method{.name = "AddNewItemTooltips", .function = &grid_add_new_item_tooltips},
    Method{.name = "SetItemText", .function = &grid_set_text},
    Method{.name = "GetItemText", .function = &grid_get_text},
    Method{.name = "SetRowUserData", .function = &grid_set_row_data},
    Method{.name = "GetRowUserData", .function = &grid_get_row_data},
    Method{.name = "SetRowTooltip", .function = &grid_set_row_tooltip},
    Method{.name = "DeleteItem", .function = &grid_delete},
    Method{.name = "RemoveAllItem", .function = &grid_clear},
    Method{.name = "GetItemCount", .function = &grid_row_count},
    Method{.name = "GetColumnCount", .function = &grid_column_count},
    Method{.name = "GetSelectItem", .function = &grid_get_selected},
    Method{.name = "SetSelectItem", .function = &grid_select},
    Method{.name = "SetVertScollPosition", .function = &grid_scroll},
    Method{.name = "RemoveColumnByPos", .function = &grid_remove_column},
    Method{.name = "Tween_AddCurveVec3", .function = &visual_only},
    Method{.name = "Tween_SetInfo", .function = &visual_only},
    Method{.name = "Tween_Play", .function = &visual_only},
    Method{.name = "Tween_Stop", .function = &visual_only},
    Method{.name = "Tween_Reset", .function = &visual_only},
    Method{.name = "RefreshLayout", .function = &visual_only},
    Method{.name = "SetElementsInView", .function = &visual_only},
    Method{.name = "SetVertScrollbarHide", .function = &visual_only},
    Method{.name = "SetVertScrollbarShow", .function = &visual_only},
    Method{.name = "PageEnd", .function = &visual_only},
    Method{.name = "ScrollToEnd", .function = &visual_only},
    Method{.name = "SetScrollPosition4Index", .function = &visual_only},
    Method{.name = "Flash", .function = &visual_only},
    Method{.name = "SetVScrollbarAlpha", .function = &visual_only},
    Method{.name = "Clear", .function = &visual_only},
    Method{.name = "CleanAllElement", .function = &visual_only},
    Method{.name = "SetSelected", .function = &visual_only},
    Method{.name = "SetSelect", .function = &visual_only},
    Method{.name = "IsActive", .function = &window_is_active},
    Method{.name = "GetWindowSize", .function = &window_get_size},
    Method{.name = "GetPixelRect", .function = &window_get_pixel_rect},
    Method{.name = "GetAbsolutePositionToScreen", .function = &window_get_screen_position},
    Method{.name = "SetWindowSize", .function = &window_set_size},
    Method{.name = "SetWindowCenter", .function = &window_set_center},
    Method{.name = "CenterWindow", .function = &window_center},
    Method{.name = "SetXAttachPos", .function = &window_set_x_attach},
    Method{.name = "AutoMousePosition", .function = &window_auto_mouse_position},
    Method{.name = "PositionSelf", .function = &window_position_self},
    Method{.name = "SetPopMenuPos", .function = &menu_set_position},
    Method{.name = "OpenPopMenu", .function = &menu_open},
    Method{.name = "ClosePopMenu", .function = &menu_close},
    Method{.name = "SetClippedByParent", .function = &window_set_clipped},
    Method{.name = "FlashMe", .function = &window_flash_me},
    Method{.name = "SetFlash", .function = &window_set_flash},
    Method{.name = "SetVertScrollbarPosition", .function = &container_set_scroll},
    Method{.name = "GetVertScrollbarPosition", .function = &container_get_scroll},
    Method{.name = "GetListItemCount", .function = &container_item_count},
    Method{.name = "SetEvent", .function = &window_set_event},
    Method{.name = "RemoveEvent", .function = &window_remove_event},
    Method{.name = "RotateBegin", .function = &mesh_rotate_begin},
    Method{.name = "RotateEnd", .function = &mesh_rotate_end},
    Method{.name = "RotateBeginEx", .function = &mesh_rotate_begin_ex},
    Method{.name = "RotateEndEx", .function = &mesh_rotate_end_ex},
    Method{.name = "AttachWindowEx", .function = &mesh_attach},
    Method{.name = "DetachWindowEx", .function = &mesh_detach},
    Method{.name = "RestPositonEx", .function = &mesh_rest_position},
    Method{.name = "SetCameraEx", .function = &mesh_set_camera},
    Method{.name = "GetCameraEx", .function = &mesh_get_camera},
    Method{.name = "ChangeCameraDistanceEx", .function = &mesh_change_camera_distance},
    Method{.name = "ClearListBoxEx", .function = &list_clear},
    Method{.name = "RemoveAllText", .function = &complex_clear},
    Method{.name = "RemoveAllChatString", .function = &complex_clear},
    Method{.name = "InsertChatString", .function = &chat_insert},
    Method{.name = "GetScrollPosition", .function = &container_scroll_position},
    Method{.name = "SetAimEditBox", .function = &chat_set_aim_edit_box},
    Method{.name = "CloseSceneMap", .function = &visual_only},
    Method{.name = "SetImage", .function = &image_set},
    Method{.name = "SetImageColor", .function = &image_set_colour},
    Method{.name = "SetPosition", .function = &scrollbar_set_position},
    Method{.name = "GetPosition", .function = &scrollbar_get_position},
};

} // namespace

Kind kind_of(std::string_view falagard_type) noexcept {
    const auto found = std::ranges::find(kKinds, falagard_type, &KindName::name);
    return found == kKinds.end() ? Kind::kWindow : found->kind;
}

std::string_view kind_name(Kind kind) noexcept {
    constexpr std::array<std::string_view, 22> kNames = {"Window", "ProgressBar", "ActionButton", "CheckButton", "ListBox",
        "ComplexWindow", "CtrlList", "ComboBox", "StaticImage", "ScrollBar", "SuperTooltip", "MeshWindow", "ChatHistory",
        "ChatChannel", "SceneMap", "WorldMap", "Minimap", "InfoList", "SoftKey", "Animate", "PopMenu", "EditBox"};
    const auto index = static_cast<std::size_t>(kind);
    return index < kNames.size() ? kNames.at(index) : "?";
}

void advance_widgets(ui::panel::Widgets& store, const gui::GuiAsset& asset, Services& services, float seconds) {
    for (const std::string& name : store.fading()) {
        const WindowRef window{.store = &store,
            .calls = nullptr,
            .asset = &asset,
            .name = name,
            .kind = Kind::kProgressBar,
            .window = -1,
            .services = &services};
        if (!is_visible(window) || !store.step_fade(name, seconds)) continue;
        const std::int32_t index = window_index(window);
        if (index >= 0 && is_this_window(asset, index)) services.set_root_shown(false);
    }
    for (const std::string& name : store.aging()) store.tick_info(name, seconds);
}

void open_widget_classes(lua_State* state, Missing missing) {
    luaL_newmetatable(state, kMetaName);
    lua_pushstring(state, "__index");
    lua_newtable(state);
    for (const Method& method : kMethods) {
        lua_pushstring(state, method.name);
        lua_pushstring(state, method.name);
        lua_pushcclosure(state, method.function, 1);
        lua_rawset(state, -3);
    }
    if (missing == Missing::kRecord) {
        lua_pushcclosure(state, &missing_stub, 0);
        lua_pushcclosure(state, &index_recording, 2);
        lua_pushstring(state, kMissingName);
        lua_rawget(state, LUA_REGISTRYINDEX);
        if (lua_type(state, -1) == LUA_TNIL) {
            lua_pushstring(state, kMissingName);
            lua_newtable(state);
            lua_rawset(state, LUA_REGISTRYINDEX);
        }
        lua_pop(state, 1);
    }
    lua_rawset(state, -3);
    lua_pop(state, 1);
}

std::vector<MissingMethod> missing_methods(lua_State* state) {
    std::vector<MissingMethod> found;
    lua_pushstring(state, kMissingName);
    lua_rawget(state, LUA_REGISTRYINDEX);
    if (lua_type(state, -1) == LUA_TTABLE) {
        lua_pushnil(state);
        while (lua_next(state, -2) != 0) {
            if (lua_type(state, -2) == LUA_TSTRING) {
                found.push_back({.name = lua_tostring(state, -2),
                    .calls = static_cast<std::uint32_t>(luanum_to_int32(lua_tonumber(state, -1)))});
            }
            lua_pop(state, 1);
        }
    }
    lua_pop(state, 1);
    std::ranges::sort(found, {}, &MissingMethod::name);
    return found;
}

void push_widget(lua_State* state, const WindowRef& window) {
    void* memory = lua_newuserdata(state, sizeof(Box));
    std::construct_at(static_cast<Box*>(memory), Box{.ref = window});
    luaL_getmetatable(state, kMetaName);
    lua_setmetatable(state, -2);
    // Cửa sổ mà layout khai Visible=False: IsVisible đúng ngay từ đầu, tới khi script gọi Show hay Hide.
    if (window.store == nullptr || window.asset == nullptr) return;
    const std::int32_t index = window_index(window);
    if (index < 0) return;
    if (const auto visible = layout_property(*window.asset, index, "Visible"); visible && is_false_text(*visible)) {
        window.store->seed_hidden(window.name);
    }
}

} // namespace game::ui::script
