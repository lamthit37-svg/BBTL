// Phần chủ của giao diện Lua (ui/script): sổ cửa sổ, luật gửi sự kiện, nạp layout lười, nhường chỗ, cửa sổ bật lên, đoạn Lua
// của layout, hẹn giờ và trần lệnh, chạy trên script thử nhỏ viết ngay trong tệp (sai thì cả giao diện lệch mà không báo gì);
// rồi sổ thật mở được, và ProgressBar.lua gốc của client 2026 chạy qua host và widget phải để lại đúng trạng thái mà trọng tài
// ghi (Test/golden/panel/progress_bar_flow.tsv, cùng số vàng với ui_progress_bar_tests).
#include "ui/script/gui_screen.hpp"
#include "ui/script/host.hpp"

#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "io/file.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"
#include "ui/script/windows.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <initializer_list>
#include <ios>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

extern "C" {
#include "lua.h"
}

namespace game::test {
namespace {

using namespace std::chrono_literals;
using ui::script::Host;
using ui::script::MouseButton;
using ui::script::Spot;

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif
#ifdef GAME_SCRIPT_SOURCE
constexpr std::string_view kScriptSource = GAME_SCRIPT_SOURCE;
#else
constexpr std::string_view kScriptSource;
#endif

// Thư mục dữ liệu tạm có Script/windows.tsv và Script/Interface/...; xoá khi ra khỏi phạm vi.
class TempRoot {
public:
    explicit TempRoot(std::string_view name) {
        const auto stamp = std::chrono::steady_clock::now().time_since_epoch().count();
        std::error_code error;
        root_ = std::filesystem::temp_directory_path(error) / std::format("tl_{}_{}", name, stamp);
        std::filesystem::create_directories(root_ / "Script" / "Interface", error);
    }
    TempRoot(const TempRoot&) = delete;
    TempRoot& operator=(const TempRoot&) = delete;
    TempRoot(TempRoot&&) = delete;
    TempRoot& operator=(TempRoot&&) = delete;
    // NOLINTNEXTLINE(bugprone-exception-escape): remove_all(error_code) không ném
    ~TempRoot() noexcept {
        std::error_code error;
        std::filesystem::remove_all(root_, error);
    }

    [[nodiscard]] const std::filesystem::path& path() const noexcept { return root_; }

    // Ghi một tệp dưới Script/; false khi không ghi được.
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): đổi chỗ thì không có tệp script nào, mọi ca đỏ ngay.
    [[nodiscard]] bool write(std::string_view relative, std::string_view text) const {
        const std::filesystem::path target = root_ / "Script" / io::path_from_utf8(relative);
        std::error_code error;
        std::filesystem::create_directories(target.parent_path(), error);
        std::ofstream file(target, std::ios::binary);
        file.write(text.data(), static_cast<std::streamsize>(text.size()));
        return static_cast<bool>(file);
    }

private:
    std::filesystem::path root_;
};

constexpr std::string_view kProbeRegistry = "id\tname\tlayout\tscript\tdemise\n"
                                            "0\tProbe\tProbe/Probe.layout.xml\tProbe/Probe.lua\t2\n"
                                            "1\tMate\tMate/Mate.layout.xml\tMate/Mate.lua\t2\n"
                                            "2\tPop\tPop/Pop.layout.xml\tPop/Pop.lua\t7\n"
                                            "3\tBroken\tBroken/Broken.layout.xml\tBroken/Broken.lua\t1\n";

// Ghi vết vào biến toàn cục thật (gán trong môi trường đi thẳng vào _G, chỉ phép đọc đi qua __index của môi trường).
constexpr std::string_view kProbeScript = R"(
function Probe_PreLoad()
	this:RegisterEvent("ALWAYS")
	this:RegisterEvent("SHOWN_ONLY", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ALWAYS", false)
	trace = "pre"
end
function Probe_OnLoad()
	trace = trace .. "|load"
end
function Probe_OnEvent(event)
	trace = trace .. "|" .. event .. "=" .. tostring(arg0)
	if event ~= "ALWAYS" then return end
	if arg0 == "show" then this:Show() end
	if arg0 == "late" then this:RegisterEvent("LATE") end
	if arg0 == "spin" then while true do end end
	if arg0 == "timer" then
		timer_a = SetTimer("Probe", "ticks = (ticks or 0) + 1", 100)
		timer_b = SetTimer("Probe", "tocks = (tocks or 0) + 1", 5)
		bad_timer = SetTimer("Probe", "x")
	end
end
function Probe_Clicked()
	trace = trace .. "|click=" .. arg0 .. "," .. CEArg:GetValue("MouseButton") .. "," .. tostring(this:IsVisible())
end
)";

constexpr std::string_view kMateScript = R"(
function Mate_PreLoad()
	this:RegisterEvent("ALWAYS")
end
function Mate_OnLoad()
end
function Mate_OnEvent(event)
	if arg0 == "mate" then this:Show() end
end
)";

constexpr std::string_view kPopScript = R"(
function Pop_PreLoad()
	this:RegisterEvent("ALWAYS")
end
function Pop_OnLoad()
end
function Pop_OnEvent(event)
	if arg0 == "pop" then this:Show() end
	if arg0 == "asked" then popped = this:ClickHide() end
end
)";

// Màn giả: mọi cửa sổ có sẵn trong một asset viết tay; Pop_Frame chiếm ô (0, 0)-(10, 10).
class ProbeScreen final : public ui::script::Screen {
public:
    ProbeScreen() {
        const auto window = [this](std::string_view name, std::int32_t parent, gui::GuiRange events) {
            gui::GuiWindow made;
            made.name = name;
            made.parent = parent;
            made.events = events;
            asset_.windows.push_back(std::move(made));
        };
        window("Probe_Frame", -1, {});
        window("Probe_Button", 0, {.first = 0, .count = 1});
        window("Mate_Frame", -1, {});
        window("Pop_Frame", -1, {});
        window("Broken_Frame", -1, {});
        asset_.events.push_back(gui::GuiEvent{.name = "Clicked", .function = "Probe_Clicked()"});
    }

    [[nodiscard]] std::expected<gui::GuiRange, std::string> load_layout(std::string_view layout) override {
        ++loads_;
        if (layout == "Probe/Probe.layout.xml") return gui::GuiRange{.first = 0, .count = 2};
        if (layout == "Mate/Mate.layout.xml") return gui::GuiRange{.first = 2, .count = 1};
        if (layout == "Pop/Pop.layout.xml") return gui::GuiRange{.first = 3, .count = 1};
        if (layout == "Broken/Broken.layout.xml") return gui::GuiRange{.first = 4, .count = 1};
        return std::unexpected(std::format("không có layout {}", layout));
    }
    [[nodiscard]] const gui::GuiAsset& asset() const noexcept override { return asset_; }
    [[nodiscard]] std::optional<Spot> offset(std::string_view window, std::string_view root) const override {
        if (window == "Probe_Button" && root == "Probe_Frame") return Spot{.x = 12.0F, .y = 34.0F};
        return std::nullopt;
    }
    [[nodiscard]] bool hits(std::string_view window, Spot spot) const override {
        return window == "Pop_Frame" && spot.x < 10.0F && spot.y < 10.0F;
    }

    // Số lần host xin nạp layout.
    [[nodiscard]] std::int32_t loads() const noexcept { return loads_; }

private:
    gui::GuiAsset asset_;
    std::int32_t loads_ = 0;
};

// Giá trị của biến toàn cục thật (không qua __index của môi trường) ở dạng chuỗi; "nil" khi không có.
[[nodiscard]] std::string global(const Host& host, const char* name) {
    lua_State* lua = host.lua();
    lua_pushstring(lua, name);
    lua_rawget(lua, LUA_GLOBALSINDEX);
    std::string text = "nil";
    if (lua_type(lua, -1) == LUA_TBOOLEAN) text = lua_toboolean(lua, -1) != 0 ? "true" : "false";
    if (lua_type(lua, -1) == LUA_TNUMBER) text = std::format("{}", lua_tonumber(lua, -1));
    if (lua_type(lua, -1) == LUA_TSTRING) text = std::string(lua_tostring(lua, -1), lua_strlen(lua, -1));
    lua_pop(lua, 1);
    return text;
}

void post(Host& host, std::string_view event, std::initializer_list<std::string_view> args = {}) {
    const std::vector<std::string_view> list(args);
    host.post(event, list);
}

struct Probe {
    TempRoot root{"ui_script_host"};
    ProbeScreen screen;
    std::optional<Host> host;

    explicit Probe(Context& context, std::uint32_t limit = ui::script::kDefaultInstructionLimit,
        std::vector<std::string> only = {}) {
        const bool is_written = root.write("windows.tsv", kProbeRegistry) &&
                                root.write("Interface/Probe/Probe.lua", kProbeScript) &&
                                root.write("Interface/Mate/Mate.lua", kMateScript) &&
                                root.write("Interface/Pop/Pop.lua", kPopScript) &&
                                root.write("Interface/Broken/Broken.lua", "this is not lua");
        context.expect(is_written, "ghi được dữ liệu thử");
        auto opened = Host::open(ui::script::HostDesc{.data_root = root.path(), .only = std::move(only), .instruction_limit = limit, .natives = {}}, screen);
        context.expect(opened.has_value(), opened ? "mở" : opened.error());
        if (opened) host.emplace(std::move(*opened));
    }
};

// Mở: chạy script và PreLoad theo thứ tự sổ; đăng ký lặp giữ cờ đầu; script hỏng chỉ ghi notes.
void open_runs_preload(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    context.expect(host.window_count() == 4, "bốn cửa sổ");
    context.expect(global(host, "trace") == "pre", "PreLoad đã chạy");
    const auto events = host.registrations("Probe");
    context.expect(events.size() == 3, "đăng ký lặp không thêm dòng");
    if (events.size() == 3) {
        context.expect(events[0].name == "ALWAYS" && events[0].is_always, "cờ đầu của ALWAYS thắng");
        context.expect(events[1].name == "SHOWN_ONLY" && !events[1].is_always, "cờ false");
    }
    const std::vector<std::string> notes = host.take_notes();
    context.expect(notes.size() == 2, "script hỏng: một dòng lỗi cú pháp, một dòng gọi Broken_PreLoad rỗng");
    context.expect(probe.screen.loads() == 0, "chưa nạp layout nào");
    context.expect(!host.is_shown("Probe") && host.widgets("Probe") != nullptr && host.widgets("None") == nullptr, "tra theo tên");
}

// Bộ gửi 0x180079310: cờ false và cửa sổ ẩn thì bỏ, trừ hai sự kiện giữ bản mới nhất khi đã nạp layout.
void dispatch_follows_original(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    post(host, "SHOWN_ONLY", {"a"});
    post(host, "VIEW_RESOLUTION_CHANGED", {"v1"});
    context.expect(global(host, "trace") == "pre" && probe.screen.loads() == 0, "chưa nạp thì bỏ hẳn, kể cả sự kiện giữ");
    post(host, "ALWAYS", {"x"});
    context.expect(global(host, "trace") == "pre|load|ALWAYS=x", "cờ true nạp layout rồi gửi");
    post(host, "VIEW_RESOLUTION_CHANGED", {"v2"});
    post(host, "VIEW_RESOLUTION_CHANGED", {"v3"});
    post(host, "SHOWN_ONLY", {"s"});
    context.expect(global(host, "trace") == "pre|load|ALWAYS=x", "ẩn: giữ chứ chưa gửi");
    post(host, "ALWAYS", {"y"});
    context.expect(global(host, "trace") == "pre|load|ALWAYS=x|VIEW_RESOLUTION_CHANGED=v3|ALWAYS=y",
        "phát lại bản mới nhất trước sự kiện kế");
    post(host, "ALWAYS", {"show"});
    post(host, "SHOWN_ONLY", {"s2"});
    context.expect(global(host, "trace").ends_with("|ALWAYS=show|SHOWN_ONLY=s2"), "đang hiện thì nhận cả cờ false");
    context.expect(probe.screen.loads() == 3, "mỗi layout nạp một lần (Probe, Mate, Pop nhận ALWAYS)");
    context.expect(host.take_notes().empty(), "không lỗi");
}

// Nhường chỗ cùng loại, cửa sổ bật lên tự đóng khi bấm ra ngoài, CloseAllWindow, vẽ theo chồng.
void demise_and_popups(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    post(host, "ALWAYS", {"show"});
    context.expect(host.is_shown("Probe"), "Show");
    post(host, "ALWAYS", {"mate"});
    context.expect(host.is_shown("Mate") && !host.is_shown("Probe"), "cùng loại 2: hiện Mate đóng Probe");
    post(host, "ALWAYS", {"pop"});
    context.expect(host.is_shown("Pop") && host.is_shown("Mate"), "loại 7 không đóng loại 2");
    host.pressed(Spot{.x = 5.0F, .y = 5.0F});
    context.expect(host.is_shown("Pop"), "bấm trong cửa sổ bật lên thì giữ");
    ui::panel::Deck deck;
    host.paint(deck);
    context.expect(deck.roots().size() == 2 && deck.roots().back() == "Pop_Frame", "hiện sau nằm trên");
    host.pressed(Spot{.x = 50.0F, .y = 5.0F});
    context.expect(!host.is_shown("Pop"), "bấm ra ngoài thì đóng");
    post(host, "ALWAYS", {"asked"});
    context.expect(global(host, "popped") == "true", "ClickHide báo vừa bị đóng");
    post(host, "ALWAYS", {"asked"});
    context.expect(global(host, "popped") == "false", "ClickHide xoá cờ");
    context.expect(host.close_all() && !host.is_shown("Mate"), "CloseAllWindow đóng loại 2");
    context.expect(!host.close_all(), "không còn gì để đóng");
    context.expect(host.set_shown("Probe", true) && host.is_shown("Probe") && !host.set_shown("None", true), "set_shown");
    context.expect(host.take_notes().empty(), "không lỗi");
}

// FireUIEvent: đoạn Lua của layout chạy trong môi trường của chủ, arg0 là tên cửa sổ, CEArg đọc nút chuột.
void layout_snippets_run_in_owner(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    context.expect(!host.fire("Probe_Button", "Clicked", MouseButton::kLeft), "chưa nạp layout thì chưa có cửa sổ");
    post(host, "ALWAYS", {"show"});
    context.expect(host.fire("Probe_Button", "Clicked", MouseButton::kRight), "đã nạp");
    context.expect(global(host, "trace").ends_with("|click=Probe_Button,RightButton,true"), "arg0, nút, this của chủ");
    context.expect(!host.fire("Probe_Button", "MouseEnter", MouseButton::kNone), "sự kiện không nối");
    context.expect(host.run("ox, oy = Probe_Env.this:GetChildOffset(\"Probe_Button\")"), "GetChildOffset");
    context.expect(global(host, "ox") == "12" && global(host, "oy") == "34", "toạ độ của màn");
    context.expect(!host.run("Probe_Env.this:GetChildOffset({})"), "đối số không phải chuỗi (số thì được) là lỗi");
    context.expect(host.take_notes().size() == 1, "một dòng lỗi");
    post(host, "ALWAYS", {"late"});
    const std::vector<std::string> notes = host.take_notes();
    context.expect(notes.size() == 1 && notes.front().contains("Must register event"), "đăng ký sau khi nạp là lỗi");
    context.expect(!host.run("Probe_Env.this.Show()"), "this.Show() thiếu self là lỗi, không chết");
    static_cast<void>(host.take_notes());
}

// SetTimer, KillTimer theo id và theo đoạn lệnh (Game.exe 0x140697440, 0x140698110), nổ theo đồng hồ khung.
void timers_follow_game(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    post(host, "ALWAYS", {"timer"});
    context.expect(global(host, "timer_a") == "1" && global(host, "timer_b") == "2", "id tăng dần");
    context.expect(global(host, "bad_timer") == "-1", "thiếu số mili giây thì -1");
    host.tick(50ms);
    context.expect(global(host, "tocks") == "1" && global(host, "ticks") == "nil", "5 ms thành 10 ms");
    host.tick(100ms);
    context.expect(global(host, "ticks") == "1" && global(host, "tocks") == "2", "mỗi lượt tối đa một lần");
    context.expect(host.run("killed = KillTimer(timer_b)"), "KillTimer(id)");
    host.tick(200ms);
    context.expect(global(host, "killed") == "true" && global(host, "ticks") == "2" && global(host, "tocks") == "2", "tắt theo id");
    context.expect(host.run("killed = KillTimer(\"ticks = (ticks or 0) + 1\")"), "KillTimer(đoạn lệnh)");
    host.tick(300ms);
    context.expect(global(host, "ticks") == "2", "tắt theo đoạn lệnh");
    context.expect(host.run("killed = KillTimer({})"), "KillTimer(bảng)");
    context.expect(global(host, "killed") == "false", "kiểu khác thì false");
    context.expect(host.take_notes().empty(), "không lỗi");
}

// HostDesc::only: cửa sổ ngoài danh sách không có script, PreLoad, sự kiện hay chỗ trong nhóm nhường chỗ; tên lạ ghi notes.
void only_limits_the_windows(Context& context) {
    Probe probe(context, ui::script::kDefaultInstructionLimit, {"Mate", "Nobody"});
    if (!probe.host) return;
    Host& host = *probe.host;
    context.expect(host.window_count() == 1, "chỉ Mate");
    context.expect(global(host, "trace") == "nil", "script của Probe không chạy");
    const std::vector<std::string> notes = host.take_notes();
    context.expect(notes.size() == 1 && notes.front().contains("Nobody"), "tên lạ có một dòng notes");
    post(host, "ALWAYS", {"mate"});
    context.expect(host.is_shown("Mate"), "Mate vẫn nhận sự kiện");
    context.expect(!host.set_shown("Probe", true) && host.widgets("Probe") == nullptr, "Probe không tồn tại với host");
}

// Vòng lặp vô tận trong script chạm trần lệnh, ghi notes, host chạy tiếp.
void instruction_limit_stops_runaway(Context& context) {
    Probe probe(context, 200'000);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    post(host, "ALWAYS", {"spin"});
    const std::vector<std::string> notes = host.take_notes();
    context.expect(notes.size() == 1 && notes.front().contains("vượt giới hạn"), "báo quá trần");
    post(host, "ALWAYS", {"after"});
    context.expect(global(host, "trace").ends_with("|ALWAYS=after"), "chạy tiếp được");
}

constexpr std::string_view kProgressRegistry = "id\tname\tlayout\tscript\tdemise\n"
                                               "123\tProgressBar\tProgressBar/ProgressBar.layout.xml\tProgressBar/ProgressBar.lua\t0\n";

// Các bước của TOOLS/port/oracle/progress_bar_flow.lua.
struct FlowStep {
    std::string_view event;
    std::array<std::string_view, 2> args;
    std::size_t count;
};
constexpr std::array<std::array<FlowStep, 2>, 10> kFlow = {{
    {{{.event = "PROGRESSBAR_SHOW", .args = {"Đang luyện công"}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_WIDTH", .args = {"0.25"}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_WIDTH", .args = {" 1e-1 "}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_WIDTH", .args = {"5d-1"}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_WIDTH", .args = {"7"}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_HIDE", .args = {}, .count = 0}, {}}},
    {{{.event = "PROGRESSBAR_SHOW", .args = {"Lần hai"}, .count = 1}, {}}},
    {{{.event = "PROGRESSBAR_BREAK", .args = {}, .count = 0}, {}}},
    {{{.event = "PROGRESSBAR_SHOW", .args = {"Lần ba"}, .count = 1}, {.event = "PLAYER_LEAVE_WORLD", .args = {}, .count = 0}}},
    {{{.event = "HIDE_ON_SCENE_TRANSED", .args = {}, .count = 0}, {}}},
}};

[[nodiscard]] std::vector<std::string> progress_lines(Host& host) {
    std::vector<ui::panel::Call> calls = host.take_calls();
    const ui::panel::Widgets* widgets = host.widgets("ProgressBar");
    if (widgets == nullptr) return {};
    return panel_lines(host.is_shown("ProgressBar"), *widgets, calls);
}

// Host chạy ProgressBar.lua gốc trên layout thật của dữ liệu client (nạp bằng GuiLoader thật qua GuiScreen). host rỗng khi máy dựng
// không có dữ liệu cần (ca bỏ qua) hay mở hỏng (ca đã báo lỗi).
struct ProgressRig {
    explicit ProgressRig(Context& context) {
        if (kClientData.empty() || kScriptSource.empty()) return;
        const io::TextResult script =
            io::read_text(io::path_from_utf8(kScriptSource) / "Interface" / "ProgressBar" / "ProgressBar.lua");
        context.expect(script.has_value(), "đọc được ProgressBar.lua");
        if (!script) return;
        context.expect(root.write("windows.tsv", kProgressRegistry) && root.write("Interface/ProgressBar/ProgressBar.lua", *script),
            "ghi được dữ liệu thử");
        sources.files = &files;
        auto opened_loader = gui::GuiLoader::open(sources);
        context.expect(opened_loader.has_value(), "mở được giao diện của kho");
        if (!opened_loader) return;
        loader.emplace(std::move(*opened_loader));
        screen.emplace(*loader);
        auto opened = Host::open(ui::script::HostDesc{.data_root = root.path(), .only = {},
                                     .instruction_limit = ui::script::kDefaultInstructionLimit, .natives = {}},
            *screen);
        context.expect(opened.has_value(), opened ? "mở host" : opened.error());
        if (opened) host.emplace(std::move(*opened));
    }

    TempRoot root{"ui_script_progress"};
    gui::DiskSource files{io::path_from_utf8(kClientData) / "Interface"};
    gui::GuiSources sources;
    std::optional<gui::GuiLoader> loader;
    std::optional<ui::script::GuiScreen> screen;
    std::optional<Host> host;
};

// ProgressBar.lua gốc qua host và widget cho ra đúng trạng thái của LuaPlus.dll gốc.
void progress_bar_matches_original(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden("progress_bar_flow.tsv");
    context.expect(blocks.size() == kFlow.size() + 2, "số vàng có khối sự kiện, các bước và Progress_close");
    if (blocks.size() != kFlow.size() + 2) return;
    ProgressRig rig(context);
    if (!rig.host) return;
    Host& host = *rig.host;
    std::vector<std::string> events;
    for (const ui::script::Registration& one : host.registrations("ProgressBar"))
        events.push_back(std::format("event\t{}\t{}", one.name, one.is_always ? "True" : "False"));
    expect_block(context, blocks.front(), events);
    std::size_t index = 1;
    for (const std::array<FlowStep, 2>& steps : kFlow) {
        for (const FlowStep& step : steps) {
            if (step.event.empty()) continue;
            host.post(step.event, std::span(step.args).first(step.count));
        }
        expect_block(context, blocks.at(index++), progress_lines(host));
    }
    context.expect(host.run("Progress_close()"), "Progress_close");
    expect_block(context, blocks.at(index), progress_lines(host));
    for (const std::string& note : host.take_notes())
        context.expect(false, note);
}

// FalagardSuperProgress::updateSelf qua Host::tick: PROGRESSBAR_BREAK cho mờ dần hai giây (SetFadeState 2) rồi giấu cả bảng; nhịp
// đầu không tính thời gian trôi, đồng hồ lùi không trừ, đúng 0 thì chưa giấu (như bản port tay ui/panel/progress_bar).
void progress_bar_fades_with_ticks(Context& context) {
    ProgressRig rig(context);
    if (!rig.host) return;
    Host& host = *rig.host;
    post(host, "PROGRESSBAR_SHOW", {"x"});
    post(host, "PROGRESSBAR_BREAK");
    host.tick(10'000ms);
    context.expect(host.is_shown("ProgressBar"), "nhịp đầu không tính thời gian đã trôi của đồng hồ khung");
    host.tick(11'000ms);
    context.expect(host.is_shown("ProgressBar"), "giữa chừng vẫn hiện");
    const ui::panel::Widgets* widgets = host.widgets("ProgressBar");
    context.expect(widgets != nullptr && widgets->value({.window = "ProgressBar_Progress", .name = "Alpha"}) == "0.5", "độ trong 0,5");
    host.tick(10'500ms);
    context.expect(host.is_shown("ProgressBar"), "đồng hồ lùi thì không trôi");
    host.tick(11'500ms);
    context.expect(host.is_shown("ProgressBar"), "đúng 0 thì chưa giấu");
    host.tick(12'000ms);
    context.expect(!host.is_shown("ProgressBar"), "hết thời gian thì giấu cả bảng");
    post(host, "PROGRESSBAR_SHOW", {"y"});
    context.expect(host.is_shown("ProgressBar"), "SHOW hiện lại");
    for (const std::string& note : host.take_notes())
        context.expect(false, note);
}

// Sổ gốc viết dấu \ ở khoảng 590 dòng (dòng 25 QuitRelative\QuitRelative.layout.xml): bộ đọc đổi thành /. Trước bản sửa cả sổ
// thật bị từ chối ở dòng đó và giao diện Lua không mở được.
void registry_accepts_backslash(Context& context) {
    const auto windows = ui::script::parse_windows(
        "id\tname\tlayout\tscript\tdemise\n25\tQuitRelative\tQuitRelative\\QuitRelative.layout.xml\tQuitRelative\\QuitRelative.lua\t1\n");
    context.expect(windows.has_value(), windows ? "đọc được" : windows.error());
    if (!windows || windows->size() != 1) return;
    const ui::script::WindowDef& window = windows->front();
    context.expect(window.layout == "QuitRelative/QuitRelative.layout.xml" && window.script == "QuitRelative/QuitRelative.lua",
        "dấu \\ thành /");
    context.expect(window.id == 25 && window.demise == ui::script::Demise::kPlain, "số và loại nhường chỗ");
    constexpr std::string_view kHead = "id\tname\tlayout\tscript\tdemise\n";
    for (const std::string_view row : {"1\tA\t../x.layout.xml\tA/A.lua\t1\n", "1\tA\tA/A.layout.xml\tC:/A.lua\t1\n",
             "1\tA\t/A.layout.xml\tA/A.lua\t1\n", "1\tA\tA\\..\\..\\x\tA/A.lua\t1\n", "1\t\tA/A.layout.xml\tA/A.lua\t1\n",
             "1\tA\tA/A.layout.xml\tA/A.lua\t8\n", "1\tA\tA/A.layout.xml\tA/A.lua\t1\n2\tA\tB/B.layout.xml\tB/B.lua\t1\n"}) {
        context.expect(!ui::script::parse_windows(std::string(kHead) + std::string(row)).has_value(), row);
    }
}

// Sổ thật của dữ liệu client (Script/windows.tsv do thienlong_scripts đưa vào): mọi script đọc, dịch và chạy được ở cấp
// tệp; lỗi chỉ còn ở PreLoad gọi hàm của game chưa có (tầng B). Đo 2026-10-15: 1 975 cửa sổ, 3 dòng lỗi.
void real_registry_opens(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path data = io::path_from_utf8(kClientData);
    const io::TextResult registry = io::read_text(data / "Script" / "windows.tsv");
    if (!registry) return;
    const auto windows = ui::script::parse_windows(*registry);
    context.expect(windows.has_value(), windows ? "đọc sổ" : windows.error());
    if (!windows) return;
    ProbeScreen screen;
    auto opened = Host::open(
        ui::script::HostDesc{.data_root = data, .only = {}, .instruction_limit = ui::script::kDefaultInstructionLimit, .natives = {}}, screen);
    context.expect(opened.has_value(), opened ? "mở" : opened.error());
    if (!opened) return;
    context.expect(opened->window_count() == windows->size(), "đủ cửa sổ của sổ");
    context.expect(screen.loads() == 0, "PreLoad không nạp layout");
    for (const std::string& note : opened->take_notes())
        context.expect(note.contains("_PreLoad: "), note);
}

// Hàm toàn cục của game mà host làm chủ (Game.exe 0x140255060, 0x140233920, 0x140246320, 0x140246390, 0x140237f50, 0x140248ba0):
// việc đẩy sự kiện đi qua hàng đợi Call, OPEN_WINDOW và CLOSE_WINDOW tới host thì hiện và giấu cửa sổ của nó.
void game_globals_follow_original(Context& context) {
    Probe probe(context);
    if (!probe.host) return;
    Host& host = *probe.host;
    static_cast<void>(host.take_notes());
    context.expect(host.run(R"lua(PushEvent("A", "b", 3, nil, "bỏ"))lua"), "PushEvent");
    context.expect(host.run(R"lua(PushDebugMessage("chào"))lua") && host.run("PushDebugMessage(7)"), "PushDebugMessage nhận chuỗi và số");
    std::vector<ui::panel::Call> calls = host.take_calls();
    context.expect(calls.size() == 3 && calls[0].ask == ui::panel::Ask::kPushEvent && calls[0].text == "A\tb\t3",
        "đối số gom tới nil đầu tiên");
    context.expect(calls.size() == 3 && calls[1].text == "NEW_DEBUGMESSAGE\tchào" && calls[2].text == "NEW_DEBUGMESSAGE\t7", "lời nhắn là sự kiện");
    context.expect(!host.run("PushEvent({})") && !host.run("PushDebugMessage(nil)") && !host.run("IsWindowShow(nil)"), "sai kiểu là lỗi Lua");
    const std::vector<std::string> notes = host.take_notes();
    context.expect(notes.size() == 3 && notes[0].contains("PushEvnet Wrong Param1") && notes[1].contains("PushDebugMessage Wrong Param") &&
                       notes[2].contains("IsWindowShow Wrong Param"), "câu lỗi như gốc");
    context.expect(host.take_calls().empty(), "lỗi không đẩy gì");

    post(host, "ALWAYS", {"show"});
    context.expect(host.run(R"lua(shown = IsWindowShow("Probe"); other = IsWindowShow("Nobody"))lua"), "IsWindowShow");
    context.expect(global(host, "shown") == "true" && global(host, "other") == "false", "cửa sổ của host; tên lạ là false");
    context.expect(host.run(R"lua(CloseWindow("Probe"))lua") && host.is_shown("Probe"), "CloseWindow không ép chỉ đẩy sự kiện");
    calls = host.take_calls();
    context.expect(calls.size() == 1 && calls.front().text == "CLOSE_WINDOW\tProbe", "sự kiện CLOSE_WINDOW");
    post(host, "CLOSE_WINDOW", {"Probe"});
    context.expect(!host.is_shown("Probe"), "CLOSE_WINDOW tới host thì giấu");
    context.expect(host.run(R"lua(OpenWindow("Mate"))lua"), "OpenWindow");
    calls = host.take_calls();
    context.expect(calls.size() == 1 && calls.front().text == "OPEN_WINDOW\tMate", "sự kiện OPEN_WINDOW");
    post(host, "OPEN_WINDOW", {"Mate"});
    context.expect(host.is_shown("Mate"), "OPEN_WINDOW tới host thì hiện");
    context.expect(host.run(R"lua(CloseWindow("Mate", true))lua") && !host.is_shown("Mate") && host.take_calls().empty(),
        "ép boolean true thì đóng ngay, không qua sự kiện");
    context.expect(host.run(R"lua(OpenWindow("Mate"))lua") && host.run(R"lua(CloseWindow("Mate", 1))lua") && host.take_calls().size() == 2,
        "ép không phải boolean true thì vẫn là sự kiện");
    post(host, "OPEN_WINDOW", {});
    post(host, "OPEN_WINDOW", {"Nobody"});

    context.expect(host.run("w, h = GetCurClientSize()") && global(host, "w") == "800" && global(host, "h") == "600", "chưa báo cỡ thì 800x600");
    host.set_client_size(ui::script::ClientSize{.width = 1920, .height = 1080});
    context.expect(host.run("w, h = GetCurClientSize()") && global(host, "w") == "1920" && global(host, "h") == "1080", "cỡ đã báo");
    host.set_client_size(ui::script::ClientSize{.width = 640, .height = 1200});
    context.expect(host.run("w, h = GetCurClientSize()") && global(host, "w") == "800" && global(host, "h") == "1200", "mỗi chiều kẹp riêng");
    context.expect(host.take_notes().empty(), "không lỗi");
}

constexpr std::array<Case, 12> kCases = {{
    {.name = "sổ nhận dấu \\ của bản gốc", .body = registry_accepts_backslash},
    {.name = "sổ thật mở được", .body = real_registry_opens},
    {.name = "mở chạy PreLoad theo sổ", .body = open_runs_preload},
    {.name = "luật gửi sự kiện của bản gốc", .body = dispatch_follows_original},
    {.name = "nhường chỗ và cửa sổ bật lên", .body = demise_and_popups},
    {.name = "đoạn Lua của layout chạy trong môi trường chủ", .body = layout_snippets_run_in_owner},
    {.name = "hẹn giờ như Game.exe", .body = timers_follow_game},
    {.name = "danh sách only", .body = only_limits_the_windows},
    {.name = "trần lệnh chặn vòng lặp vô tận", .body = instruction_limit_stops_runaway},
    {.name = "ProgressBar.lua gốc khớp số vàng", .body = progress_bar_matches_original},
    {.name = "ProgressBar mờ dần theo nhịp", .body = progress_bar_fades_with_ticks},
    {.name = "hàm toàn cục của game: sự kiện, cửa sổ, cỡ màn", .body = game_globals_follow_original},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
