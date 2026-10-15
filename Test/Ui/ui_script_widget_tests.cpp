// Đối tượng widget của script giao diện (ui/script/widget) trên LuaPlus thật: quy tắc đọc đối số của từng phương
// thức (đối số sai thì im lặng bỏ qua, riêng SetActionItem báo lỗi), trạng thái ghi vào Widgets, GetProperty từ
// layout, IsVisible theo chuỗi cha và nhóm nút đánh dấu; cuối cùng chạy ProgressBar.lua gốc qua một host tối thiểu
// của test và so từng bước với số vàng của trọng tài (Test/golden/panel/progress_bar_flow.tsv).
#include "ui/script/widget.hpp"

#include "gui/asset.hpp"
#include "gui/sheet.hpp"
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
#include <limits>
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
// CheckC (CheckMode 0), một nút action, một danh sách, một hộp thả, một bảng nhiều cột và một thanh cuộn
// (DocumentSize 10, PageSize 3).
gui::GuiAsset small_layout() {
    gui::GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "Plain", .renderer = "Falagard/StaticImage", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Check", .renderer = "Falagard/CheckBox", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Dropdown", .renderer = "Falagard/Combobox", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Table", .renderer = "Falagard/MultiColumnList", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Slider", .renderer = "Falagard/Scrollbar", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Notice", .renderer = "Falagard/InfoList", .look = -1});
    add_window(asset, "Root", 0, -1, {});
    add_window(asset, "Child", 0, 0,
        {{"Visible", "False"}, {"Text", "chữ layout"}, {"UnifiedAreaRect", "{{0.1,5},{0.2,6},{0.9,-5},{0.8,-6}}"}});
    add_window(asset, "CheckA", 1, 0, {{"CheckMode", "1"}});
    add_window(asset, "CheckB", 1, 0, {{"CheckMode", "1"}});
    add_window(asset, "CheckC", 1, 0, {{"CheckMode", "0"}});
    add_window(asset, "Action", 0, 0, {});
    add_window(asset, "List", 0, 0, {});
    add_window(asset, "Combo", 2, 0, {});
    add_window(asset, "Grid", 3, 0, {});
    add_window(asset, "Bar", 4, 0, {{"DocumentSize", "10"}, {"PageSize", "3"}});
    add_window(asset, "Info", 5, 0, {{"Life", "3000"}, {"FadeSpeed", "255"}});
    add_window(asset, "InfoPlain", 5, 0, {});
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

void missing_methods_are_recorded_on_request(Context& context) {
    const Lab lab;
    context.expect(ui::script::missing_methods(lab.lua.get()).empty(), "chưa mở chế độ đo thì chưa có gì để kể");
    context.expect(!lab.run("Child:NoSuch()").empty(), "mặc định phương thức lạ là lỗi Lua");
    ui::script::open_widget_classes(lab.lua.get(), ui::script::Missing::kRecord);
    context.expect(lab.run("r = Child:NoSuch(1) .. 'x' Child:NoSuch() List:Other('a', 2) n = Child:Third() + 1 Child:SetText('vẫn chạy')").empty(),
        "chế độ đo: phương thức lạ trả 0 và hàm xử lý chạy tiếp");
    context.expect(lab.global("r") == "0x" && lab.global("n") == "1", "phương thức lạ trả số 0");
    context.expect(lab.text_of("Child", "Text") == "vẫn chạy", "phương thức có sẵn vẫn chạy thật");
    context.expect(lab.run("e = Child.NoSuch ~= nil f = Child[1] == nil").empty() && lab.global("e") == "true" && lab.global("f") == "true",
        "khoá chuỗi lạ cho hàm đo, khoá không phải chuỗi cho nil");
    const std::vector<ui::script::MissingMethod> missing = ui::script::missing_methods(lab.lua.get());
    context.expect(missing.size() == 3 && missing[0].name == "NoSuch" && missing[0].calls == 3 && missing[1].name == "Other"
            && missing[1].calls == 1 && missing[2].name == "Third" && missing[2].calls == 1,
        "kê đúng tên và số lần, theo tên tăng dần");
    ui::script::open_widget_classes(lab.lua.get());
    context.expect(!lab.run("Child:NoSuch()").empty(), "mở lại chế độ mặc định thì phương thức lạ là lỗi");
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

void combo_box_keeps_items_and_selection(Context& context) {
    const Lab lab;
    context.expect(lab.run("r, n = Combo:GetCurrentSelect()").empty() && lab.global("r") == "-1" && lab.global("n") == "-1",
        "chưa chọn thì (\"-1\", -1)");
    context.expect(lab.run("Combo:AddTextItem('một', 10) Combo:ComboBoxAddItem('hai', 20) Combo:AddTextItem(7, 30)"
                           " Combo:AddTextItem({}, 1) Combo:AddTextItem('ba')")
            .empty(),
        "thêm mục: chữ hay số, id thiếu là 0, chữ sai kiểu bị bỏ");
    context.expect(lab.run("n = Combo:GetListCount()").empty() && lab.global("n") == "4", "bốn mục");
    context.expect(lab.run("Combo:SetCurrentSelect(1) r, n = Combo:GetCurrentSelect()").empty() && lab.global("r") == "hai"
            && lab.global("n") == "20" && lab.text_of("Combo", "Text") == "hai",
        "chọn mục thì ô nhập mang chữ của mục");
    context.expect(lab.run("Combo:SetCurrentSelect(9) Combo:SetCurrentSelect(-1) Combo:SetCurrentSelect('x') r = Combo:GetCurrentSelect()")
                .empty()
            && lab.global("r") == "hai",
        "chỉ số ngoài danh sách hay sai kiểu thì bỏ qua");
    context.expect(lab.run("a = Combo:GetTextItemId(2) b = Combo:GetTextItemId(9)").empty() && lab.global("a") == "30" && lab.global("b").empty(),
        "GetTextItemId: id của mục, ngoài danh sách thì không trả gì");
    context.expect(lab.run("Combo:SetTextItemText(0, 'mới') Combo:SetCurrentSelect(0) r = Combo:GetCurrentSelect()").empty()
            && lab.global("r") == "mới",
        "SetTextItemText đổi chữ của mục");
    context.expect(lab.run("Combo:ClearAllSelections() r = Combo:GetCurrentSelect()").empty() && lab.global("r") == "-1", "bỏ chọn");
    context.expect(lab.run("Combo:ResetText()").empty() && lab.text_of("Combo", "Text").empty(), "ResetText");
    context.expect(lab.run("Combo:ResetList() Combo:ResetLastSelectIndex() n = Combo:GetListCount()").empty() && lab.global("n") == "0",
        "ResetList bỏ mọi mục");
}

void ctrl_list_follows_multi_column_list(Context& context) {
    const Lab lab;
    context.expect(lab.run("Grid:AddColumn('Tên', 0, 100) Grid:AddColumn('Cấp', 1, 50) n = Grid:GetColumnCount()").empty()
            && lab.global("n") == "2",
        "hai cột");
    context.expect(lab.run("Grid:AddNewItem('A', 0, 0) Grid:AddNewItem('1', 1, 0) Grid:AddNewItem('B', 0, 1) Grid:AddNewItem('2', 1, 1)"
                           " n = Grid:GetItemCount()")
            .empty()
            && lab.global("n") == "2",
        "ô cùng hàng gộp vào một hàng");
    context.expect(lab.run("a = Grid:GetItemText(0, 0) b = Grid:GetItemText(1, 1)").empty() && lab.global("a") == "A" && lab.global("b") == "2",
        "GetItemText(hàng, cột)");
    context.expect(lab.run("Grid:SetItemText(1, 1, '20') b = Grid:GetItemText(1, 1)").empty() && lab.global("b") == "20", "SetItemText");
    context.expect(lab.run("Grid:AddNewItem('x', 9, 0) n = Grid:GetItemCount()").empty() && lab.global("n") == "2",
        "cột không có id 9 thì ô bị bỏ");
    context.expect(lab.run("r = Grid:GetItemText(5, 0)").empty() && lab.global("r") == "0",
        "ô không có: Lua nhận giá trị ở đỉnh ngăn xếp (đối số cuối), như hàm gốc");
    context.expect(lab.run("Grid:SetRowUserData(1, 77) a = Grid:GetRowUserData(1) b = Grid:GetRowUserData(0) c = Grid:GetRowUserData(5)")
                .empty()
            && lab.global("a") == "77" && lab.global("b") == "-1" && lab.global("c") == "-1",
        "dữ liệu hàng: chưa đặt hay hàng không có là -1");
    context.expect(lab.run("r = Grid:GetSelectItem()").empty() && lab.global("r") == "-1", "chưa chọn thì -1");
    context.expect(lab.run("Grid:SetSelectItem(1) r = Grid:GetSelectItem() Grid:SetSelectItem(7) q = Grid:GetSelectItem()").empty()
            && lab.global("r") == "1" && lab.global("q") == "1",
        "chọn hàng: GetSelectItem trả số hàng script đưa lúc mở hàng, hàng không có thì giữ nguyên");
    context.expect(lab.run("Grid:SetRowTooltip(0, 'gợi ý') Grid:DeleteItem(0) n = Grid:GetItemCount() r = Grid:GetSelectItem()").empty()
            && lab.global("n") == "1" && lab.global("r") == "1",
        "xoá hàng trước hàng đang chọn thì lựa chọn dời theo");
    context.expect(lab.run("Grid:SetVertScollPosition(1) Grid:SetVertScollPosition(9)").empty(), "cuộn tới hàng");
    context.expect(lab.run("Grid:InsertColumn('Giữa', 5, 10, 1) n = Grid:GetColumnCount() Grid:RemoveColumnByPos(0) m = Grid:GetColumnCount()")
                .empty()
            && lab.global("n") == "3" && lab.global("m") == "2",
        "InsertColumn và RemoveColumnByPos");
    context.expect(lab.run("Grid:RemoveAllItem() n = Grid:GetItemCount() m = Grid:GetColumnCount()").empty() && lab.global("n") == "0"
            && lab.global("m") == "2",
        "RemoveAllItem bỏ hàng, giữ cột");
    context.expect(lab.run("Grid:AddNewItem('N', 1, 0) Grid:AddNewItem('M', 5, 0) n = Grid:GetItemCount() b = Grid:GetSelectItem()").empty()
            && lab.global("n") == "2" && lab.global("b") == "-1",
        "hàng mở bằng cột khác 0 có ô cột 0 trống, nên ô cùng số hàng sau đó vẫn mở hàng mới");
}

void shared_names_follow_the_kind(Context& context) {
    const Lab lab;
    context.expect(lab.run("Child:DeleteItem(0) Child:RemoveAllItem() Child:SetItemText(0, 0, 'x') r = Child:GetSelectItem()").empty()
            && lab.global("r").empty(),
        "tên trùng giữa các lớp: lớp khác CtrlList chưa có hành vi nên không làm gì");
    ui::script::open_widget_classes(lab.lua.get(), ui::script::Missing::kRecord);
    context.expect(lab.run("Child:DeleteItem(0) Child:DeleteItem(1) Grid:DeleteItem(0) Child:Nope()").empty(), "chạy ở chế độ đo");
    const std::vector<ui::script::MissingMethod> missing = ui::script::missing_methods(lab.lua.get());
    const auto count_of = [&missing](std::string_view name) {
        const auto found = std::ranges::find(missing, name, &ui::script::MissingMethod::name);
        return found == missing.end() ? std::uint32_t{0} : found->calls;
    };
    context.expect(count_of("DeleteItem@StaticImage") == 2 && count_of("Nope") == 1 && count_of("DeleteItem@CtrlList") == 0,
        "chế độ đo ghi Tên@Lớp cho phương thức chưa có hành vi ở lớp ấy");
}

void image_and_scrollbar(Context& context) {
    const Lab lab;
    context.expect(lab.run("Child:SetImage('icon1')").empty() && lab.text_of("Child", "Image") == "set:Icon image:icon1",
        "SetImage một đối số là tên icon đầy đủ");
    context.expect(lab.run("Child:SetImage('Set', 'Name')").empty() && lab.text_of("Child", "Image") == "set:Set image:Name",
        "SetImage hai đối số là bộ ảnh và ảnh");
    context.expect(lab.run("Child:SetImageColor('80ff00ff')").empty()
            && lab.text_of("Child", "ImageColours") == "tl:80FF00FF tr:80FF00FF bl:80FF00FF br:80FF00FF",
        "SetImageColor");
    context.expect(lab.run("Child:SetImageColor('zz')").empty() && lab.text_of("Child", "ImageColours") == "tl:FF000000 tr:FF000000 bl:FF000000 br:FF000000",
        "màu không đọc được là đen đặc");
    context.expect(lab.run("Bar:SetPosition(5) a = Bar:GetPosition() Bar:SetPosition(99) b = Bar:GetPosition() Bar:SetPosition(-4)"
                           " c = Bar:GetPosition() Bar:SetPosition(2.5) d = Bar:GetPosition() Bar:SetPosition('x') e = Bar:GetPosition()")
                .empty()
            && lab.global("a") == "5" && lab.global("b") == "7" && lab.global("c") == "0" && lab.global("d") == "2.5"
            && lab.global("e") == "2.5",
        "SetPosition kẹp vào 0..(DocumentSize - PageSize) = 0..7");
}

void fade_follows_super_progress(Context& context) {
    Lab lab;
    const auto tick = [&lab](float seconds) { ui::script::advance_widgets(lab.widgets, lab.asset, lab.services, seconds); };
    lab.services.root = true;
    tick(5.0F);
    context.expect(lab.text_of("Root", "Alpha") == "<chưa đặt>" && lab.services.root, "chưa mờ dần thì nhịp không làm gì");
    context.expect(lab.run("Root:SetProperty('SetFadeState', 2)").empty() && lab.text_of("Root", "Alpha") == "1", "SetFadeState(2) mở đoạn mờ dần");
    tick(1.0F);
    context.expect(lab.text_of("Root", "Alpha") == "0.5" && lab.services.root, "giữa chừng vẫn hiện, độ trong còn một nửa");
    tick(1.0F);
    context.expect(lab.text_of("Root", "Alpha") == "0" && lab.services.root && !lab.widgets.is_hidden("Root"),
        "còn đúng 0 thì chưa giấu (so sánh nhỏ hơn)");
    tick(0.5F);
    context.expect(lab.text_of("Root", "Alpha") == "-0.25" && !lab.services.root && lab.widgets.is_hidden("Root"),
        "hết giờ thì giấu cửa sổ gốc và `this`");
    tick(0.5F);
    context.expect(lab.text_of("Root", "Alpha") == "-0.25", "đã giấu thì nhịp sau không làm gì");
    context.expect(lab.run("Root:SetProperty('SetFadeState', 0)").empty() && lab.services.root && !lab.widgets.is_hidden("Root")
            && lab.text_of("Root", "Alpha") == "1",
        "SetFadeState(0) hiện lại và xoá đoạn mờ dần");
    tick(1.0F);
    context.expect(lab.text_of("Root", "Alpha") == "1", "đoạn mờ dần đã xoá thì nhịp không làm gì");
    context.expect(lab.run("Child:Show() Child:SetProperty('SetFadeState', 1)").empty(), "cửa sổ con");
    tick(2.0F);
    context.expect(lab.widgets.is_hidden("Child") && lab.services.root, "cửa sổ con hết giờ thì chỉ giấu nó");
}

// Chữ mà Widgets::paint đặt cho thuộc tính Text của window (dòng sau thắng); "<không có>" khi không đặt.
std::string painted_text(const Lab& lab, std::string_view window) {
    ui::panel::Deck deck;
    lab.widgets.paint(deck);
    std::string text = "<không có>";
    for (const gui::Override& said : deck.overrides()) {
        if (said.window == window && said.name == "Text") text = std::string(said.value);
    }
    return text;
}

// FalagardInfoList: AddInfo mang Life và FadeSpeed của cửa sổ (script đặt hay layout; không khai thì 5000 và 128), advance_widgets chạy
// updateSelf (trừ tuổi thọ; âm thì mờ FadeSpeed/255 mỗi giây; độ trong âm thì bỏ mục, mục dồn lên bị bỏ qua tới nhịp sau) và
// paint nối chữ các mục thành Text.
void info_list_ages_and_fades(Context& context) {
    Lab lab;
    const auto tick = [&lab](float seconds) { ui::script::advance_widgets(lab.widgets, lab.asset, lab.services, seconds); };
    const auto count = [&lab](std::string_view window) { return lab.widgets.item_count(window); };
    context.expect(painted_text(lab, "Info") == "<không có>", "chưa có mục thì không đặt Text");
    context.expect(lab.run("Info:AddInfo('một') Info:AddInfo('hai')").empty() && count("Info") == 2 && lab.widgets.is_shown("Info"),
        "AddInfo thêm mục và hiện danh sách");
    context.expect(painted_text(lab, "Info") == "một\nhai", "mỗi mục một dòng của Text");
    tick(3.0F);
    context.expect(count("Info") == 2, "hết đúng tuổi thọ (0) thì chưa mờ");
    tick(0.5F);
    context.expect(count("Info") == 2, "mờ còn một nửa");
    tick(0.6F);
    context.expect(count("Info") == 1 && lab.widgets.item_at("Info", 0)->text == "hai", "mục đầu hết độ trong thì bỏ");
    tick(0.4F);
    context.expect(count("Info") == 1, "mục dồn lên bị bỏ qua ở nhịp bỏ mục kia nên còn 0,1 độ trong");
    tick(0.2F);
    context.expect(count("Info") == 0 && painted_text(lab, "Info") == "<không có>", "hết độ trong thì bỏ nốt, Text về layout");

    context.expect(lab.run("InfoPlain:AddInfo('x')").empty(), "danh sách không khai Life và FadeSpeed");
    tick(5.0F);
    tick(1.0F);
    context.expect(count("InfoPlain") == 1, "mặc định 5000 ms và 128: sau 6 giây còn gần nửa độ trong");
    tick(2.0F);
    context.expect(count("InfoPlain") == 0, "sau 8 giây hết độ trong");

    context.expect(lab.run("Info:SetProperty('Life', 100) Info:AddInfo('a') Info:SetProperty('Life', 'xyz') Info:AddInfo('b')").empty()
            && count("Info") == 2,
        "Life đọc lúc AddInfo; chữ không phải số thì mặc định");
    tick(0.2F);
    tick(0.1F);
    context.expect(count("Info") == 2, "mục a mờ dần nhưng chưa hết, mục b còn tuổi thọ");
}

// Mục thêm bằng AddItem không già đi; ClearListBox xoá cả tuổi thọ; mục đang chọn dời theo khi mục trước nó bị bỏ.
void info_list_edge_cases(Context& context) {
    Lab lab;
    const auto tick = [&lab](float seconds) { ui::script::advance_widgets(lab.widgets, lab.asset, lab.services, seconds); };
    context.expect(lab.run("Info:AddItem('trước', 7) Info:AddInfo('a') Info:AddItem('sau', 8)").empty() && lab.widgets.item_count("Info") == 3,
        "AddItem lẫn AddInfo");
    tick(100.0F);
    context.expect(lab.widgets.item_count("Info") == 2 && lab.widgets.item_at("Info", 0)->text == "trước"
            && lab.widgets.item_at("Info", 1)->text == "sau",
        "chỉ mục info già đi và bị bỏ");
    context.expect(lab.run("Info:ClearListBox() Info:AddInfo('mới')").empty() && lab.widgets.item_count("Info") == 1, "xoá rồi thêm lại");
    tick(100.0F);
    context.expect(lab.widgets.item_count("Info") == 0, "mục sau ClearListBox vẫn già đi");

    context.expect(lab.run("Info:AddInfo('a') Info:AddInfo('b') Info:AddInfo('c')").empty() && lab.widgets.select_index("Info", 1),
        "chọn mục b");
    tick(4.0F);
    tick(1.0F);
    context.expect(lab.widgets.item_count("Info") == 1 && lab.widgets.chosen_item("Info") != nullptr
            && lab.widgets.chosen_item("Info")->text == "b",
        "mục a và c bị bỏ, mục b (dồn lên bị bỏ qua) vẫn được chọn");
    tick(10.0F);
    context.expect(lab.widgets.item_count("Info") == 0 && lab.widgets.chosen_item("Info") == nullptr
            && lab.widgets.selected_item("Info") == ui::panel::kNoItem,
        "mục đang chọn bị bỏ thì mất lựa chọn");

    context.expect(lab.run("Info:AddInfo('x')").empty(), "thêm mục");
    tick(-3.0F);
    tick(std::numeric_limits<float>::quiet_NaN());
    context.expect(lab.widgets.item_count("Info") == 1, "thời gian âm hay NaN tính là 0");
    tick(std::numeric_limits<float>::infinity());
    context.expect(lab.widgets.item_count("Info") == 0, "thời gian vô hạn hết tuổi thọ và độ trong mà không tràn số");
    context.expect(lab.run("Info:AddInfo('y')").empty(), "thêm mục");
    tick(1e30F);
    context.expect(lab.widgets.item_count("Info") == 0, "thời gian cực lớn cũng vậy");

    context.expect(lab.run("Info:AddInfo('1') Info:AddInfo('2') Info:AddInfo('3') Info:AddInfo('4') Info:AddInfo('5') Info:AddInfo('6')").empty()
            && lab.widgets.item_count("Info") == 5 && lab.widgets.item_at("Info", 0)->text == "2",
        "tối đa 5 mục, bỏ mục cũ nhất");
    context.expect(lab.run("Child:AddInfo('không phải danh sách') Child:AddInfo(5)").empty(), "cửa sổ khác cũng nhận AddInfo (flat)");
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
    // Tên hàm xử lý sự kiện của script ("<Cửa sổ>_OnEvent").
    std::string handler;
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

    MiniHost(gui::GuiAsset layout, std::string handler_name) : lab(std::move(layout)), handler(std::move(handler_name)) {
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
        return lab.run(std::format("{}(\"{}\")", handler, event));
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

    MiniHost host(progress_layout(), "ProgressBar_OnEvent");
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

// DebugListBox.layout.xml: gốc và danh sách TLBB_InfoList khai Life 5000, FadeSpeed 128.
gui::GuiAsset debug_layout() {
    gui::GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "Plain", .renderer = "Falagard/StaticImage", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "Notice", .renderer = "Falagard/InfoList", .look = -1});
    add_window(asset, "DebugListBox", 0, -1, {});
    add_window(asset, "DebugListBox_ListBox", 1, 0, {{"Text", ""}, {"Life", "5000"}, {"FadeSpeed", "128"}});
    return asset;
}

// DebugListBox.lua gốc qua host tối thiểu và InfoList: cho ra đúng trạng thái của LuaPlus.dll gốc (số vàng của trọng tài, sinh với
// cùng thư viện DataPool ở TOOLS/port/oracle/debug_list_box_api.lua), và vẽ các mục thành Text.
void debug_list_box_matches_the_golden(Context& context) {
    const std::vector<GoldenBlock> blocks = read_golden("debug_list_box_flow.tsv");
    if (blocks.empty()) return;
    const std::filesystem::path root = io::path_from_utf8(kPanelGolden).parent_path().parent_path().parent_path();
    const io::TextResult script = io::read_text(root / "src/client/script/Interface/DebugListBox/DebugListBox.lua");
    const io::TextResult library = io::read_text(root / "TOOLS/port/oracle/debug_list_box_api.lua");
    context.expect(script.has_value() && library.has_value(), "thấy DebugListBox.lua và debug_list_box_api.lua");
    if (!script || !library) return;

    MiniHost host(debug_layout(), "DebugListBox_OnEvent");
    context.expect(host.lab.run(*library).empty(), "nạp DataPool của trọng tài");
    context.expect(host.lab.run(*script).empty(), "nạp DebugListBox.lua");
    context.expect(host.lab.run("DebugListBox_PreLoad()").empty(), "PreLoad");
    context.expect(blocks.size() == 11, "số vàng có 11 khối (1 khối sự kiện đăng ký + 10 bước)");
    if (blocks.size() != 11) return;

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
    const auto message = [&host](std::string_view text) { return host.with_arg(text).fire("NEW_DEBUGMESSAGE"); };
    settle(1, host.fire("APPLICATION_INITED"));
    settle(2, message("Bạn chưa có bang hội"));
    for (const std::string_view line : {"Dòng hai", "Dòng ba", "Dòng bốn"}) context.expect(message(line).empty(), "thêm dòng");
    settle(3, message("Dòng năm"));
    context.expect(message("Dòng sáu").empty(), "thêm dòng");
    settle(4, message("Dòng bảy"));
    settle(5, message(std::string(400, 'a')));
    settle(6, message(std::string(401, 'b')));
    settle(7, message(std::string(399, 'c') + "ă"));
    settle(8, message(std::string(399, 'd') + "ế"));
    std::string two_byte_fit;
    for (int count = 0; count < 200; ++count) two_byte_fit += "đ";
    settle(9, message(two_byte_fit + "e"));
    context.expect(painted_text(host.lab, "DebugListBox_ListBox").starts_with("#c00FFFF#e010101"), "danh sách vẽ thành Text từ các mục");
    settle(10, host.fire("APPLICATION_INITED"));
    context.expect(painted_text(host.lab, "DebugListBox_ListBox") == "<không có>", "danh sách rỗng thì không vẽ Text");

    context.expect(message("Một").empty() && message("Hai").empty(), "hai dòng cuối");
    context.expect(painted_text(host.lab, "DebugListBox_ListBox") == "#c00FFFF#e010101Một\n#c00FFFF#e010101Hai",
        "Text là các mục nối bằng xuống dòng");
    const auto tick = [&host](float seconds) { ui::script::advance_widgets(host.lab.widgets, host.lab.asset, host.lab.services, seconds); };
    tick(5.0F);
    tick(0.5F);
    tick(2.0F);
    context.expect(host.lab.widgets.item_count("DebugListBox_ListBox") == 1, "bản gốc: nhịp mờ bỏ mục đầu, mục dồn lên bị bỏ qua");
    tick(2.0F);
    context.expect(host.lab.widgets.item_count("DebugListBox_ListBox") == 0, "nhịp sau bỏ nốt");
}

constexpr std::array<Case, 19> kCases = {{
    {.name = "kind_follows_the_falagard_type", .body = kind_follows_the_falagard_type},
    {.name = "text_follows_the_original_rules", .body = text_follows_the_original_rules},
    {.name = "set_property_special_cases", .body = set_property_special_cases},
    {.name = "get_property_reads_script_then_layout", .body = get_property_reads_script_then_layout},
    {.name = "visibility_walks_the_parents", .body = visibility_walks_the_parents},
    {.name = "check_buttons_group_in_mode_one", .body = check_buttons_group_in_mode_one},
    {.name = "bad_arguments_are_dropped_quietly", .body = bad_arguments_are_dropped_quietly},
    {.name = "missing_methods_are_recorded_on_request", .body = missing_methods_are_recorded_on_request},
    {.name = "action_button_keeps_the_action", .body = action_button_keeps_the_action},
    {.name = "lists_and_elements", .body = lists_and_elements},
    {.name = "combo_box_keeps_items_and_selection", .body = combo_box_keeps_items_and_selection},
    {.name = "ctrl_list_follows_multi_column_list", .body = ctrl_list_follows_multi_column_list},
    {.name = "shared_names_follow_the_kind", .body = shared_names_follow_the_kind},
    {.name = "image_and_scrollbar", .body = image_and_scrollbar},
    {.name = "fade_follows_super_progress", .body = fade_follows_super_progress},
    {.name = "progress_bar_matches_the_golden", .body = progress_bar_matches_the_golden},
    {.name = "info_list_ages_and_fades", .body = info_list_ages_and_fades},
    {.name = "info_list_edge_cases", .body = info_list_edge_cases},
    {.name = "debug_list_box_matches_the_golden", .body = debug_list_box_matches_the_golden},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
