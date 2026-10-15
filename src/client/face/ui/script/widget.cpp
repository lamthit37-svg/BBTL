// Đối tượng widget của script giao diện: metatable, bảng phương thức và hàm C của từng phương thức.
// Nguồn hành vi: UILuaControl.cpp của client 2008 (đọc đối số, im lặng bỏ qua đối số sai kiểu) và hàm cùng tên trong
// UI_CEGUI.dll 2026 (docs/GIAO-DIEN-2026.md mục 8) cho chỗ hai bản lệch; trạng thái ghi vào Widgets theo mô hình mà
// TOOLS/port/lua_oracle.lua đã dùng để sinh số vàng của các bảng port tay.
// Quy tắc của mọi hàm C ở đây: LuaPlus báo lỗi bằng longjmp, nên chỗ gọi raise (lua_error) không được giữ đối tượng có
// destructor còn sống (std::string, vector). Hàm chỉ gọi nó ở đầu hàm (self) hay trước khi dựng gì (SetActionItem).
#include "ui/script/widget.hpp"

#include "gui/asset.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/widgets.hpp"
#include "ui/script/script_text.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
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

namespace {

using panel::Ask;
using panel::Call;
using panel::kEmptyAction;
using panel::ListItem;

// Khoá của metatable trong sổ đăng ký Lua, cũng là cách nhận ra userdata của widget.
constexpr const char* kMetaName = "thienlong.ui.widget";

// InfoList giữ tối đa chừng này mục (NormalizeItemNumber, mặc định 0x18006b676 của CEGUIFalagard.dll).
constexpr std::size_t kInfoLimit = 5;

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

// SetFadeState (FalagardSuperProgressProperties, CEGUIFalagard.dll 0x180079f20): giá trị <= 0 hiện cửa sổ lại (và cả
// `this` khi cửa sổ là gốc layout), mọi giá trị đều đặt độ trong về 1.
void set_fade_state(const WindowRef& window, std::string_view value, bool is_number_value, double number) {
    window.store->set({.window = window.name, .name = "SetFadeState", .value = value});
    if (is_number_value && number <= 0.0) {
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
        set_fade_state(window, text_at(state, 3), lua_isnumber(state, 3) != 0, lua_tonumber(state, 3));
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

// AddInfo (FalagardInfoList::AddInfo, CEGUIFalagard.dll 0x18006b940): thêm mục chữ id 0, giữ tối đa kInfoLimit mục, hiện
// danh sách. Tuổi thọ và độ mờ của mục không vào trạng thái ghi.
int list_add_info(lua_State* state) {
    const WindowRef& window = self(state);
    if (!is_text(state, 2)) return 0;
    window.store->add_info(window.name, ListItem{.text = from_script(text_at(state, 2)), .id = 0, .colour = {}}, kInfoLimit);
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
};

} // namespace

Kind kind_of(std::string_view falagard_type) noexcept {
    const auto found = std::ranges::find(kKinds, falagard_type, &KindName::name);
    return found == kKinds.end() ? Kind::kWindow : found->kind;
}

void open_widget_classes(lua_State* state) {
    const bool is_new = luaL_newmetatable(state, kMetaName) != 0;
    if (is_new) {
        lua_pushstring(state, "__index");
        lua_newtable(state);
        for (const Method& method : kMethods) {
            lua_pushstring(state, method.name);
            lua_pushcclosure(state, method.function, 0);
            lua_rawset(state, -3);
        }
        lua_rawset(state, -3);
    }
    lua_pop(state, 1);
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
