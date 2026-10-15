// Đối tượng widget của script giao diện (ui/script/widget) trên LuaPlus thật: quy tắc đọc đối số của từng phương
// thức (đối số sai thì im lặng bỏ qua, riêng SetActionItem báo lỗi), trạng thái ghi vào Widgets, GetProperty từ
// layout, IsVisible theo chuỗi cha và nhóm nút đánh dấu; cuối cùng chạy ProgressBar.lua gốc qua một host tối thiểu
// của test và so từng bước với số vàng của trọng tài (Test/golden/panel/progress_bar_flow.tsv).
#include "ui/script/widget.hpp"

#include "gui/asset.hpp"
#include "io/file.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <initializer_list>
#include <memory>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}

namespace game::test {
namespace {

using ui::panel::Ask;
using ui::panel::Call;
using ui::panel::Key;
using ui::panel::Widgets;
using ui::script::Kind;
using ui::script::WindowRef;

struct StateCloser {
    void operator()(lua_State* state) const noexcept { lua_close(state); }
};
using StatePtr = std::unique_ptr<lua_State, StateCloser>;

StatePtr open_state() {
    StatePtr state{lua_open()};
    luaopen_base(state.get());
    luaopen_table(state.get());
    luaopen_string(state.get());
    luaopen_math(state.get());
    lua_settop(state.get(), 0);
    ui::script::open_widget_classes(state.get());
    return state;
}

// Phần phía game mà widget hỏi: icon đổi tên có tiền tố, cờ hiện của `this` giữ trong test.
class FakeServices final : public ui::script::Services {
public:
    [[nodiscard]] std::string icon_full_name(std::string_view icon) const override {
        return std::format("set:Icon image:{}", icon);
    }
    [[nodiscard]] std::string action_icon(std::int32_t action) const override { return std::format("action{}", action); }
    [[nodiscard]] bool root_shown() const override { return root; }
    void set_root_shown(bool is_shown) override { root = is_shown; }

    bool root = false;
};

using PropertyList = std::initializer_list<std::pair<std::string_view, std::string_view>>;

void add_window(gui::GuiAsset& asset, std::string_view name, std::int32_t type, std::int32_t parent, PropertyList properties) {
    const auto first = static_cast<std::uint32_t>(asset.properties.size());
    for (const auto& [property, value] : properties) {
        asset.properties.push_back(gui::GuiProperty{.name = std::string(property), .value = std::string(value)});
    }
    asset.windows.push_back(gui::GuiWindow{.name = std::string(name),
        .type = type,
        .parent = parent,
        .properties = {.first = first, .count = static_cast<std::uint32_t>(properties.size())},
        .events = {},
        .child = -1});
}

// Layout nhỏ: Root (gốc, tức `this`) có Child (layout giấu, có vị trí), ba nút đánh dấu CheckA, CheckB (CheckMode 1) và
// CheckC (CheckMode 0), một nút action và một danh sách.
gui::GuiAsset small_layout() {
    gui::GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "Plain", .renderer = "Falagard/StaticImage", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Check", .renderer = "Falagard/CheckBox", .look = -1});
    add_window(asset, "Root", 0, -1, {});
    add_window(asset, "Child", 0, 0,
        {{"Visible", "False"}, {"Text", "chữ layout"}, {"UnifiedAreaRect", "{{0.1,5},{0.2,6},{0.9,-5},{0.8,-6}}"}});
    add_window(asset, "CheckA", 1, 0, {{"CheckMode", "1"}});
    add_window(asset, "CheckB", 1, 0, {{"CheckMode", "1"}});
    add_window(asset, "CheckC", 1, 0, {{"CheckMode", "0"}});
    add_window(asset, "Action", 0, 0, {});
    add_window(asset, "List", 0, 0, {});
    return asset;
}

// Một state Lua cùng Widgets, hàng việc và layout; mỗi cửa sổ của layout là một biến toàn cục cùng tên.
struct Lab {
    StatePtr lua = open_state();
    Widgets widgets;
    std::vector<Call> calls{};
    gui::GuiAsset asset;
    FakeServices services;

    explicit Lab(gui::GuiAsset layout = small_layout()) : asset(std::move(layout)) {
        std::int32_t at = 0;
        for (const gui::GuiWindow& window : asset.windows) {
            const WindowRef ref{.store = &widgets,
                .calls = &calls,
                .asset = &asset,
                .name = window.name,
                .kind = ui::script::kind_of(asset.types[static_cast<std::size_t>(window.type)].renderer),
                .window = at,
                .services = &services};
            ui::script::push_widget(lua.get(), ref);
            lua_setglobal(lua.get(), window.name.c_str());
            ++at;
        }
    }

    // Chạy một đoạn Lua; rỗng khi chạy được, không thì thông điệp lỗi.
    [[nodiscard]] std::string run(std::string_view code) const {
        // luaL_loadbuffer + lua_pcall thay lua_dobuffer: lua_dobuffer của Lua 5.0 còn in lỗi ra stderr (_ALERT).
        if (luaL_loadbuffer(lua.get(), code.data(), code.size(), "=test") == 0 && lua_pcall(lua.get(), 0, 0, 0) == 0) return {};
        const char* message = lua_tostring(lua.get(), -1);
        const std::string text = message != nullptr ? message : "lỗi không có thông điệp";
        lua_pop(lua.get(), 1);
        return text;
    }

    // Biến toàn cục dạng chuỗi (số theo tostring của Lua, boolean là true hay false); rỗng khi chưa gán.
    std::string global(const char* name) const {
        lua_getglobal(lua.get(), name);
        std::string value;
        if (lua_type(lua.get(), -1) == LUA_TBOOLEAN) {
            value = lua_toboolean(lua.get(), -1) != 0 ? "true" : "false";
        } else if (const char* text = lua_tostring(lua.get(), -1); text != nullptr) {
            value = text;
        }
        lua_pop(lua.get(), 1);
        return value;
    }

    [[nodiscard]] std::string text_of(std::string_view window, std::string_view name) const {
        const auto found = widgets.value(Key{.window = window, .name = name});
        return found ? std::string(*found) : std::string("<chưa đặt>");
    }
};

void kind_follows_the_falagard_type(Context& context) {
    context.expect(ui::script::kind_of("Falagard/SuperProgress") == Kind::kProgressBar, "thanh tiến trình");
    context.expect(ui::script::kind_of("Falagard/CheckBox") == Kind::kCheckButton, "nút đánh dấu");
    context.expect(ui::script::kind_of("Falagard/ActionButton") == Kind::kActionButton, "nút action");
    context.expect(ui::script::kind_of("Falagard/MultiColumnList") == Kind::kCtrlList, "danh sách nhiều cột");
    context.expect(ui::script::kind_of("Falagard/ChưaBiết") == Kind::kWindow, "tên lạ là cửa sổ thường");
    context.expect(ui::script::kind_of("") == Kind::kWindow, "rỗng là cửa sổ thường");
}

void text_follows_the_original_rules(Context& context) {
    const Lab lab;
    context.expect(lab.run("r = Child:GetText()").empty() && lab.global("r") == "chữ layout", "chưa đặt thì lấy chữ của layout");
    context.expect(lab.run("Child:SetText(7.9)").empty() && lab.text_of("Child", "Text") == "7", "số thì sprintf(%d)");
    context.expect(lab.run("Child:SetText(-3)").empty() && lab.text_of("Child", "Text") == "-3", "số âm");
    context.expect(lab.run("Child:SetText('xin chào')").empty() && lab.text_of("Child", "Text") == "xin chào", "chuỗi nguyên văn");
    context.expect(lab.run("Child:SetText({})").empty() && lab.text_of("Child", "Text") == "xin chào", "đối số sai kiểu thì bỏ qua");
    context.expect(lab.run("Child:SetText()").empty() && lab.text_of("Child", "Text") == "xin chào", "thiếu đối số thì bỏ qua");
    context.expect(lab.run("r = Child:GetText()").empty() && lab.global("r") == "xin chào", "GetText đọc lại chữ vừa đặt");
    context.expect(lab.run("Child:SetToolTip('gợi ý')").empty() && lab.text_of("Child", "Tooltip") == "gợi ý", "SetToolTip");
    context.expect(lab.run("Child:SetToolTip(12)").empty() && lab.text_of("Child", "Tooltip") == "12", "SetToolTip nhận số như chuỗi");
    context.expect(lab.run("Child:SetTextOriginal('gốc') Child:TransText()").empty() && lab.text_of("Child", "Text") == "gốc",
        "TransText đặt chữ gốc làm chữ hiện");
}

void set_property_special_cases(Context& context) {
    const Lab lab;
    context.expect(lab.run("Child:SetProperty('Image', 'set:A image:B')").empty() && lab.text_of("Child", "Image") == "set:A image:B",
        "thuộc tính thường giữ nguyên");
    context.expect(lab.run("Child:SetProperty('ShortImage', 'bieu_tuong')").empty()
            && lab.text_of("Child", "Image") == "set:Icon image:bieu_tuong",
        "ShortImage đổi tên icon rồi đặt Image");
    context.expect(lab.text_of("Child", "ShortImage") == "<chưa đặt>", "ShortImage không thành thuộc tính");
    context.expect(lab.run("Child:SetProperty('Alpha', {})").empty() && lab.text_of("Child", "Alpha") == "<chưa đặt>",
        "giá trị không phải chuỗi thì bỏ qua");
    context.expect(lab.run("Child:SetProperty({}, 'x') Child:SetProperty(nil, 'x') Child:SetProperty('Alpha')").empty()
            && lab.text_of("Child", "Alpha") == "<chưa đặt>",
        "tên không phải chuỗi hay thiếu giá trị thì bỏ qua");
    context.expect(lab.run("Child:SetProperty(5, 'x')").empty() && lab.text_of("Child", "5") == "x",
        "IsString của LuaPlus nhận cả số: tên là số vẫn là tên");
    context.expect(lab.run("Child:SetProperty('Alpha', 0.5)").empty() && lab.text_of("Child", "Alpha") == "0.5", "số đổi thành chuỗi");

    context.expect(lab.run("Child:SetProperty('SetFadeState', '2')").empty() && lab.text_of("Child", "SetFadeState") == "2"
            && lab.text_of("Child", "Alpha") == "1",
        "SetFadeState lớn hơn 0: đặt độ trong về 1");
    context.expect(!lab.widgets.is_shown("Child") && !lab.services.root, "SetFadeState lớn hơn 0 không hiện cửa sổ");
    context.expect(lab.run("Child:SetProperty('SetFadeState', '0')").empty() && lab.widgets.is_shown("Child"),
        "SetFadeState 0 hiện cửa sổ");
    context.expect(!lab.services.root, "cửa sổ con không đụng tới cờ hiện của this");
    context.expect(lab.run("Root:SetProperty('SetFadeState', '0')").empty() && lab.services.root,
        "SetFadeState 0 trên cửa sổ gốc cũng hiện this");
}

void get_property_reads_script_then_layout(Context& context) {
    const Lab lab;
    context.expect(lab.run("r = Child:GetProperty('UnifiedXPosition')").empty() && lab.global("r") == "{0.1,5}", "X suy từ UnifiedAreaRect");
    context.expect(lab.run("r = Child:GetProperty('UnifiedYPosition')").empty() && lab.global("r") == "{0.2,6}", "Y suy từ UnifiedAreaRect");
    context.expect(lab.run("r = Child:GetProperty('UnifiedPosition')").empty() && lab.global("r") == "{{0.1,5},{0.2,6}}", "vị trí suy từ UnifiedAreaRect");
    context.expect(lab.run("r = Child:GetProperty('Text')").empty() && lab.global("r") == "chữ layout", "thuộc tính khai trong layout");
    context.expect(lab.run("Child:SetProperty('UnifiedPosition', '{{0.5,1},{0.6,2}}') r = Child:GetProperty('UnifiedXPosition')").empty()
            && lab.global("r") == "{0.5,1}",
        "vị trí script đặt thắng layout");
    context.expect(lab.run("Child:SetProperty('Text', 'mới') r = Child:GetProperty('Text')").empty() && lab.global("r") == "mới", "thuộc tính script đặt");
    context.expect(lab.run("r = Child:GetProperty('KhongCo')").empty() && lab.global("r").empty(), "thuộc tính lạ thì chuỗi rỗng");
    context.expect(lab.run("r = Child:GetProperty('Visible')").empty() && lab.global("r") == "False", "Visible theo cờ hiện của layout");
    context.expect(lab.run("r = Child:GetProperty()").empty() && lab.global("r").empty(), "thiếu tên thì không trả gì");
}

void visibility_walks_the_parents(Context& context) {
    Lab lab;
    context.expect(lab.run("r = Root:IsVisible()").empty() && lab.global("r") == "false", "this đang giấu thì cửa sổ gốc giấu");
    lab.services.root = true;
    context.expect(lab.run("r = Root:IsVisible()").empty() && lab.global("r") == "true", "this hiện thì cửa sổ gốc hiện");
    context.expect(lab.run("r = Action:IsVisible()").empty() && lab.global("r") == "true", "cửa sổ con của gốc hiện");
    context.expect(lab.run("r = Child:IsVisible()").empty() && lab.global("r") == "false", "layout khai Visible=False thì giấu tới khi Show");
    context.expect(lab.run("Child:Show() r = Child:IsVisible()").empty() && lab.global("r") == "true", "Show hiện cửa sổ");
    context.expect(lab.run("Child:Hide() r = Child:IsVisible()").empty() && lab.global("r") == "false", "Hide giấu cửa sổ");
    lab.services.root = false;
    context.expect(lab.run("Child:Show() r = Child:IsVisible()").empty() && lab.global("r") == "false", "gốc giấu thì cả cây giấu");
    context.expect(lab.run("Child:Disable()").empty() && lab.widgets.is_disabled("Child"), "Disable khoá cửa sổ");
    context.expect(lab.run("Child:Enable()").empty() && !lab.widgets.is_disabled("Child"), "Enable mở khoá");
}

void check_buttons_group_in_mode_one(Context& context) {
    const Lab lab;
    context.expect(lab.run("CheckC:SetCheck(1) CheckA:SetCheck(1)").empty(), "chạy được");
    context.expect(lab.widgets.is_checked("CheckA") && !lab.widgets.is_checked("CheckC"), "bật nút CheckMode 1 thì nút anh em tắt, dù mang CheckMode nào");
    context.expect(lab.run("CheckB:SetCheck(1)").empty() && lab.widgets.is_checked("CheckB") && !lab.widgets.is_checked("CheckA"),
        "bật nút CheckMode 1 khác thì nút trước tắt");
    context.expect(lab.run("CheckC:SetCheck(1)").empty() && lab.widgets.is_checked("CheckC") && lab.widgets.is_checked("CheckB"),
        "nút CheckMode 0 bật không đụng nút khác");
    context.expect(lab.run("CheckB:SetCheck(0)").empty() && !lab.widgets.is_checked("CheckB"), "SetCheck(0) tắt");
    context.expect(lab.run("CheckB:SetCheck('1')").empty() && !lab.widgets.is_checked("CheckB"), "chuỗi '1' không phải số: bỏ qua");
    context.expect(lab.run("CheckB:SetCheck(1) r = CheckB:GetCheck() q = CheckA:GetCheck()").empty() && lab.global("r") == "1"
            && lab.global("q") == "0",
        "GetCheck trả 1 hay 0");
}

void bad_arguments_are_dropped_quietly(Context& context) {
    const Lab lab;
    context.expect(lab.run("Child:SetProgress('1', 2) Child:SetProgress(1) Child:SetProgress()").empty()
            && !lab.widgets.progress("Child"),
        "SetProgress chỉ nhận hai số");
    context.expect(lab.run("Child:SetProgress(25, 100)").empty() && lab.widgets.progress("Child").value_or(-1.0F) == 0.25F,
        "SetProgress(25, 100) là mức 0,25");
    context.expect(lab.run("List:AddItem('chữ') List:AddItem('chữ', 'x') List:AddItem(nil, 1)").empty(), "AddItem thiếu hay sai đối số");
    std::vector<std::string> lines;
    lab.widgets.describe(lines);
    context.expect(std::ranges::none_of(lines, [](const std::string& line) { return line.starts_with("List\t"); }),
        "AddItem thiếu hay sai đối số thì không thêm mục nào");
    context.expect(!lab.run("Action:SetActionItem('a')").empty(), "SetActionItem nhận chuỗi là lỗi của script");
    context.expect(!lab.run("Action.Show()").empty(), "gọi bằng dấu chấm (không có đối tượng) là lỗi");
    context.expect(!lab.run("Action.Show(5)").empty(), "đối số 1 không phải widget là lỗi");
    context.expect(!lab.run("Action:KhongCo()").empty(), "phương thức không có là lỗi Lua");
}

void action_button_keeps_the_action(Context& context) {
    Lab lab;
    context.expect(lab.run("r = Action:GetActionItem()").empty() && lab.global("r") == "-1", "ô chưa đặt là -1");
    context.expect(lab.run("Action:DoAction()").empty() && lab.calls.empty(), "ô trống thì DoAction không nhờ game");
    context.expect(lab.run("Action:SetActionItem(1234)").empty() && lab.widgets.action("Action") == 1234, "SetActionItem giữ id");
    context.expect(lab.run("r = Action:GetActionItem()").empty() && lab.global("r") == "1234", "GetActionItem đọc lại");
    context.expect(lab.run("Action:DoAction()").empty() && lab.calls.size() == 1 && lab.calls[0].ask == Ask::kDoAction
            && lab.calls[0].text == "Action\t1234",
        "DoAction nhờ game dùng action trong ô");
    context.expect(lab.run("Action:SetPushed(1)").empty(), "SetPushed chạy được");
    context.expect(lab.run("Action:Gloom() Action:Bright() Action:SetNewFlash() Action:PlayWarning(1)").empty(), "Gloom, Bright, SetNewFlash, PlayWarning");
    context.expect(lab.text_of("Action", "Gloom") == "False", "Bright sau Gloom thì Gloom False");
    context.expect(lab.run("Action:SetActionItem(-1) r = Action:GetActionItem()").empty() && lab.global("r") == "-1", "id -1 làm trống ô");
    lab.calls.clear();
    context.expect(lab.run("Action:DoAction()").empty() && lab.calls.empty(), "ô trống lại thì DoAction không nhờ game");
}

void lists_and_elements(Context& context) {
    const Lab lab;
    context.expect(lab.run("List:ClearListBox() List:AddItem('một', 10) List:AddItem('hai', 20, 'FFFF0000')").empty(), "thêm mục");
    context.expect(lab.run("r = List:GetFirstSelectItem()").empty() && lab.global("r") == "-1", "chưa chọn thì -1");
    context.expect(lab.run("List:SetItemSelectByItemID(20) r = List:GetFirstSelectItem()").empty() && lab.global("r") == "20", "chọn theo id");
    context.expect(lab.run("List:SetCurrentFirstItem(1) r = List:GetCurrentFirstItem() q = List:GetClickItem()").empty()
            && lab.global("r") == "1" && lab.global("q") == "-1",
        "mục đầu đang thấy và mục vừa bấm");
    std::vector<std::string> lines;
    lab.widgets.describe(lines);
    const auto has = [&lines](std::string_view wanted) { return std::ranges::contains(lines, wanted); };
    context.expect(has("List\tItems\t2") && has("List\tItem1\t10\t\tmột") && has("List\tItem2\t20\tFFFF0000\thai"), "mục ghi đủ chữ, id và màu");

    context.expect(lab.run("for i = 1, 7 do Child:AddInfo('tin ' .. i) end").empty(), "AddInfo");
    lines.clear();
    lab.widgets.describe(lines);
    context.expect(has("Child\tItems\t5") && has("Child\tItem1\t0\t\ttin 3") && has("Child\tItem5\t0\t\ttin 7"), "AddInfo giữ năm mục mới nhất");
    context.expect(lab.widgets.is_shown("Child"), "AddInfo hiện danh sách");

    context.expect(lab.run("Child:ClearAllElement() Child:AddTextElement('chữ') Child:AddMoneyElement(1500) Child:AddJiaoZiElement('20')"
                           " Child:AddActionElement(7, 3, 0) Child:AddActionElement(8, 1, 1, 'thêm') Child:AddActionElement('x', 1, 1)")
            .empty(),
        "thêm phần tử");
    lines.clear();
    lab.widgets.describe(lines);
    context.expect(has("Child\tElements\t5"), "năm phần tử đúng kiểu, lời gọi sai kiểu bị bỏ");
    context.expect(has("Child\tElement1\ttext\tchữ") && has("Child\tElement2\tmoney\t1500") && has("Child\tElement3\tjiaozi\t20"),
        "phần tử chữ và tiền");
    context.expect(has("Child\tElement4\taction\t7\t3\t0") && has("Child\tElement5\taction\t8\t1\t1\tthêm"), "phần tử action");
}

// ---- ProgressBar.lua gốc qua host tối thiểu ----

// Phần của host mà ProgressBar.lua dùng: `this` có Show, Hide, IsVisible, RegisterEvent; sự kiện chỉ tới hàm
// ProgressBar_OnEvent khi đăng ký cờ true hay khi `this` đang hiện (bộ phân phối 0x180079310 của UI_CEGUI.dll).
gui::GuiAsset progress_layout() {
    gui::GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "Progress", .renderer = "Falagard/SuperProgress", .look = -1});
    add_window(asset, "ProgressBar_Progress", 0, -1, {});
    return asset;
}

struct MiniHost {
    struct Registered {
        std::string name;
        bool is_always = true;
    };

    Lab lab;
    std::vector<Registered> events{};

    static MiniHost& host_of(lua_State* state) {
        return *static_cast<MiniHost*>(lua_touserdata(state, lua_upvalueindex(1)));
    }
    static int this_show(lua_State* state) {
        host_of(state).lab.services.root = true;
        return 0;
    }
    static int this_hide(lua_State* state) {
        host_of(state).lab.services.root = false;
        return 0;
    }
    static int this_register(lua_State* state) {
        const char* name = lua_tostring(state, 2);
        // RegisterEvent(tên[, cờ]): cờ không phải boolean thì là true (UI_CEGUI.dll 0x180077be0).
        const bool is_always = lua_type(state, 3) != LUA_TBOOLEAN || lua_toboolean(state, 3) != 0;
        if (name != nullptr) host_of(state).events.push_back(Registered{.name = name, .is_always = is_always});
        return 0;
    }

    MiniHost() : lab(progress_layout()) {
        lua_State* state = lab.lua.get();
        lua_newtable(state);
        const std::array<std::pair<const char*, lua_CFunction>, 3> methods = {{
            {"Show", &MiniHost::this_show},
            {"Hide", &MiniHost::this_hide},
            {"RegisterEvent", &MiniHost::this_register},
        }};
        for (const auto& [name, function] : methods) {
            lua_pushstring(state, name);
            lua_pushlightuserdata(state, this);
            lua_pushcclosure(state, function, 1);
            lua_rawset(state, -3);
        }
        lua_setglobal(state, "this");
    }

    // Phát sự kiện; bỏ qua khi không đăng ký hay cờ false mà `this` đang giấu. Lỗi Lua thì trả thông điệp.
    std::string fire(std::string_view event) {
        const auto found = std::ranges::find(events, event, &Registered::name);
        if (found == events.end() || (!found->is_always && !lab.services.root)) return {};
        return lab.run(std::format("ProgressBar_OnEvent(\"{}\")", event));
    }

    // Đặt đối số arg0 của sự kiện kế tiếp (biến toàn cục arg0, như _OnGameEvent); trả chính host để nối với fire.
    MiniHost& with_arg(std::string_view arg0) {
        lua_pushlstring(lab.lua.get(), arg0.data(), arg0.size());
        lua_setglobal(lab.lua.get(), "arg0");
        return *this;
    }
};

void progress_bar_matches_the_golden(Context& context) {
    // Bản dựng không biết thư mục số vàng (thiết bị Android không thấy cây nguồn) thì read_golden trả rỗng: bỏ qua.
    const std::vector<GoldenBlock> blocks = read_golden("progress_bar_flow.tsv");
    if (blocks.empty()) return;
    // Thư mục số vàng là <gốc>/Test/golden/panel; script gốc nằm trong cây nguồn của client.
    const std::filesystem::path root = io::path_from_utf8(kPanelGolden).parent_path().parent_path().parent_path();
    const io::TextResult script = io::read_text(root / "src/client/script/Interface/ProgressBar/ProgressBar.lua");
    context.expect(script.has_value(), "thấy src/client/script/Interface/ProgressBar/ProgressBar.lua");
    if (!script) return;

    MiniHost host;
    context.expect(host.lab.run(*script).empty(), "nạp ProgressBar.lua");
    context.expect(host.lab.run("ProgressBar_PreLoad()").empty(), "PreLoad");
    context.expect(blocks.size() == 12, "số vàng có 12 khối (1 khối sự kiện đăng ký + 11 bước)");
    if (blocks.size() != 12) return;

    std::vector<std::string> registered;
    registered.reserve(host.events.size());
    for (const MiniHost::Registered& event : host.events) {
        registered.push_back(std::format("event\t{}\t{}", event.name, event.is_always ? "True" : "False"));
    }
    expect_block(context, blocks[0], registered);

    const auto settle = [&](std::size_t block, const std::string& failure) {
        context.expect(failure.empty(), std::format("[{}] {}", blocks[block].label, failure));
        expect_block(context, blocks[block], panel_lines(host.lab.services.root, host.lab.widgets, host.lab.calls));
    };
    settle(1, host.with_arg("Đang luyện công").fire("PROGRESSBAR_SHOW"));
    settle(2, host.with_arg("0.25").fire("PROGRESSBAR_WIDTH"));
    settle(3, host.with_arg(" 1e-1 ").fire("PROGRESSBAR_WIDTH"));
    settle(4, host.with_arg("5d-1").fire("PROGRESSBAR_WIDTH"));
    settle(5, host.with_arg("7").fire("PROGRESSBAR_WIDTH"));
    const auto level = host.lab.widgets.progress("ProgressBar_Progress");
    context.expect(level && *level == 1.0F, "mức 7 (700/100) bị kẹp về đầy");
    settle(6, host.fire("PROGRESSBAR_HIDE"));
    settle(7, host.with_arg("Lần hai").fire("PROGRESSBAR_SHOW"));
    settle(8, host.fire("PROGRESSBAR_BREAK"));
    static_cast<void>(host.with_arg("Lần ba").fire("PROGRESSBAR_SHOW"));
    settle(9, host.fire("PLAYER_LEAVE_WORLD"));
    settle(10, host.fire("HIDE_ON_SCENE_TRANSED"));
    settle(11, host.lab.run("Progress_close()"));
}

constexpr std::array<Case, 10> kCases = {{
    {.name = "kind_follows_the_falagard_type", .body = kind_follows_the_falagard_type},
    {.name = "text_follows_the_original_rules", .body = text_follows_the_original_rules},
    {.name = "set_property_special_cases", .body = set_property_special_cases},
    {.name = "get_property_reads_script_then_layout", .body = get_property_reads_script_then_layout},
    {.name = "visibility_walks_the_parents", .body = visibility_walks_the_parents},
    {.name = "check_buttons_group_in_mode_one", .body = check_buttons_group_in_mode_one},
    {.name = "bad_arguments_are_dropped_quietly", .body = bad_arguments_are_dropped_quietly},
    {.name = "action_button_keeps_the_action", .body = action_button_keeps_the_action},
    {.name = "lists_and_elements", .body = lists_and_elements},
    {.name = "progress_bar_matches_the_golden", .body = progress_bar_matches_the_golden},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
