// Script gốc của các cửa sổ HUD đã có bản port tay (FunctionBarRight, FunctionBarRight_2, MainMenuBar_2/3/4, CreateRole, QuestLog)
// chạy qua Host thật và widget thật, bằng CHÍNH kịch bản của trọng tài (TOOLS/port/oracle/*.lua, nguyên văn) và hàm game giả
// của nó (các tệp *_api.lua), rồi so từng khối __dump với số vàng của bản port tay (Test/golden/panel/*.tsv). Cùng số vàng mà bản port
// tay đã khớp: khớp ở đây nghĩa là cửa sổ ấy chạy bằng script gốc cho ra đúng trạng thái đó, cửa sổ có thể chuyển sang kScripted.
//
// Trọng tài (TOOLS/port/lua_oracle.py) dựng cửa sổ giả bằng Lua; ở đây cửa sổ là widget thật nên chỉ cần phần keo mỏng: __dump,
// __dump_events, __note, __fire, __post bằng C, và __event, __check, __toggle, __pick bằng Lua trên phương thức của widget. Hai
// cách đưa sự kiện game: trực tiếp (gọi thẳng <Tên>_OnEvent như trọng tài) và qua Host::post (luật gửi thật: chỉ cửa sổ đã đăng
// ký, cờ false thì chỉ khi cửa sổ đang hiện); khác nhau ở khối nào thì chỗ đó trọng tài đơn giản hơn client.
// Không dùng hàm game của tầng B: hàm game ở đây là của trọng tài, để chỉ kiểm script, host và widget.
#include "ui/script/gui_screen.hpp"
#include "ui/script/host.hpp"
#include "ui/script/widget.hpp"
#include "ui/script/windows.hpp"

#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "io/file.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <functional>
#include <ios>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

namespace game::test {
namespace {

using ui::script::Host;
using ui::script::MouseButton;

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

constexpr std::string_view kStepsMark = "--@steps";
// Trong bảng --words, ký tự này là một dấu cách (U+2423).
constexpr std::string_view kSpaceMark = "\xE2\x90\xA3";

struct TableSpec {
    std::string_view name;
    // Tệp dưới Table/ của dữ liệu client.
    std::string_view file;
};

// Một cửa sổ có bản port tay: tên trong sổ cửa sổ, kịch bản và số vàng, các tệp hàm game giả (TOOLS/port/oracle/<tên>.lua).
struct Spec {
    std::string_view window;
    std::string_view scenario;
    std::string_view golden;
    std::span<const std::string_view> libs;
    std::span<const TableSpec> tables;
    bool has_words = false;
};

constexpr std::array<std::string_view, 3> kRightLibs = {"ui_common_api", "action_bar_api", "function_bar_right_api"};
constexpr std::array<std::string_view, 3> kRight2Libs = {"ui_common_api", "action_bar_api", "function_bar_right_2_api"};
constexpr std::array<std::string_view, 4> kMenu2Libs = {"ui_common_api", "action_bar_api", "main_menu_bar_4_api", "main_menu_bar_2_api"};
constexpr std::array<std::string_view, 2> kMenu3Libs = {"ui_common_api", "main_menu_bar_3_api"};
constexpr std::array<std::string_view, 3> kMenu4Libs = {"ui_common_api", "action_bar_api", "main_menu_bar_4_api"};
constexpr std::array<std::string_view, 1> kCreateLibs = {"create_role_api"};
constexpr std::array<std::string_view, 2> kQuestLibs = {"ui_common_api", "quest_api"};
constexpr std::array<TableSpec, 4> kCreateTables = {{{.name = "portraits", .file = "portraits.tsv"},
    {.name = "faces", .file = "faces.tsv"},
    {.name = "hairs", .file = "hairs.tsv"},
    {.name = "outfits", .file = "newbie_outfits.tsv"}}};

constexpr std::array<Spec, 7> kSpecs = {{
    {.window = "FunctionBarRight", .scenario = "function_bar_right_bar", .golden = "function_bar_right_bar.tsv", .libs = kRightLibs,
        .tables = {}, .has_words = false},
    {.window = "FunctionBarRight_2", .scenario = "function_bar_right_2_bar", .golden = "function_bar_right_2_bar.tsv",
        .libs = kRight2Libs, .tables = {}, .has_words = false},
    {.window = "MainMenuBar_2", .scenario = "main_menu_bar_2_bar", .golden = "main_menu_bar_2_bar.tsv", .libs = kMenu2Libs,
        .tables = {}, .has_words = false},
    {.window = "MainMenuBar_3", .scenario = "main_menu_bar_3_pet", .golden = "main_menu_bar_3_pet.tsv", .libs = kMenu3Libs,
        .tables = {}, .has_words = false},
    {.window = "MainMenuBar_4", .scenario = "main_menu_bar_4_bar", .golden = "main_menu_bar_4_bar.tsv", .libs = kMenu4Libs,
        .tables = {}, .has_words = false},
    {.window = "LoginCreateRole", .scenario = "create_role_newcomer", .golden = "create_role_newcomer.tsv", .libs = kCreateLibs,
        .tables = kCreateTables, .has_words = true},
    {.window = "QuestLog", .scenario = "quest_log_newcomer", .golden = "quest_log_newcomer.tsv", .libs = kQuestLibs, .tables = {},
        .has_words = true},
}};

// ---- Đọc tệp, bảng thay chữ, bảng dữ liệu ----

[[nodiscard]] std::filesystem::path repository_root() {
    return io::path_from_utf8(kPanelGolden).parent_path().parent_path().parent_path();
}

[[nodiscard]] std::string lua_text(std::string_view value) {
    std::string text = "\"";
    for (const char one : value) {
        switch (one) {
        case '\\': text += "\\\\"; break;
        case '"': text += "\\\""; break;
        case '\r': text += "\\r"; break;
        case '\n': text += "\\n"; break;
        default: text += one; break;
        }
    }
    text += '"';
    return text;
}

[[nodiscard]] std::vector<std::string_view> split(std::string_view text, char separator) {
    std::vector<std::string_view> parts;
    std::size_t start = 0;
    while (true) {
        const std::size_t stop = text.find(separator, start);
        if (stop == std::string_view::npos) {
            parts.push_back(text.substr(start));
            return parts;
        }
        parts.push_back(text.substr(start, stop - start));
        start = stop + 1;
    }
}

[[nodiscard]] std::string replaced(std::string text, std::string_view from, std::string_view to) {
    for (std::size_t at = text.find(from); at != std::string::npos; at = text.find(from, at + to.size()))
        text.replace(at, from.size(), to);
    return text;
}

using Words = std::map<std::string, std::string, std::less<>>;

// Bảng nguyên văn sang bản dịch (TOOLS/port/oracle/words.vi.tsv): dòng # và dòng trống bỏ, ký tự kSpaceMark là dấu cách.
[[nodiscard]] std::expected<Words, std::string> parse_words(std::string_view text) {
    Words words;
    std::size_t number = 0;
    for (const std::string_view line : split(text, '\n')) {
        ++number;
        if (line.empty() || line.starts_with('#')) continue;
        const std::size_t tab = line.find('\t');
        if (tab == std::string_view::npos || line.find('\t', tab + 1) != std::string_view::npos)
            return std::unexpected(std::format("words dòng {}: cần nguyên văn, một dấu tab, bản dịch", number));
        words[replaced(std::string(line.substr(0, tab)), kSpaceMark, " ")] = replaced(std::string(line.substr(tab + 1)), kSpaceMark, " ");
    }
    return words;
}

// Thay mọi chuỗi trong nháy kép trùng nguyên văn của words bằng bản dịch, đúng luật của lua_oracle.py (LITERAL): thân chuỗi là
// ký tự thường hay gạch chéo ngược theo sau một ký tự, không qua dòng mới.
[[nodiscard]] std::string localized(std::string_view script, const Words& words) {
    std::string out;
    out.reserve(script.size());
    std::size_t at = 0;
    while (at < script.size()) {
        if (script[at] != '"') {
            out += script[at++];
            continue;
        }
        std::size_t scan = at + 1;
        bool is_closed = false;
        while (scan < script.size()) {
            const char one = script[scan];
            if (one == '"') {
                is_closed = true;
                break;
            }
            if (one == '\n') break;
            if (one == '\\') {
                if (scan + 1 >= script.size() || script[scan + 1] == '\n') break;
                scan += 2;
                continue;
            }
            ++scan;
        }
        if (!is_closed) {
            out += script[at++];
            continue;
        }
        const auto found = words.find(script.substr(at + 1, scan - at - 1));
        if (found != words.end())
            out += lua_text(found->second);
        else
            out += script.substr(at, scan - at + 1);
        at = scan + 1;
    }
    return out;
}

// __tables[tên] từ một bảng TSV của client: dòng # và dòng trống bỏ, dòng kế là tên cột; mỗi dòng dữ liệu một bảng Lua cột -> chữ.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): đổi chỗ thì bảng không đọc được, ca đỏ ngay.
[[nodiscard]] std::expected<std::string, std::string> table_code(std::string_view name, std::string_view text) {
    std::vector<std::string_view> lines;
    for (const std::string_view line : split(text, '\n')) {
        if (!line.empty() && !line.starts_with('#')) lines.push_back(line);
    }
    if (lines.empty()) return std::unexpected(std::format("bảng {} không có dòng tên cột", name));
    const std::vector<std::string_view> header = split(lines.front(), '\t');
    std::string code = std::format("__tables[{}] = {{\n", lua_text(name));
    for (std::size_t number = 1; number < lines.size(); ++number) {
        const std::vector<std::string_view> cells = split(lines[number], '\t');
        if (cells.size() != header.size())
            return std::unexpected(std::format("bảng {}: dòng dữ liệu {} có {} ô, bảng có {} cột", name, number, cells.size(), header.size()));
        code += '{';
        for (std::size_t column = 0; column < header.size(); ++column) {
            if (column > 0) code += ", ";
            code += std::format("[{}] = {}", lua_text(header[column]), lua_text(cells[column]));
        }
        code += "},\n";
    }
    code += "}\n";
    return code;
}

// Thư mục dữ liệu tạm có Script/windows.tsv và Script/Interface/<script>; xoá khi ra khỏi phạm vi.
class TempRoot {
public:
    TempRoot() {
        const auto stamp = std::chrono::steady_clock::now().time_since_epoch().count();
        std::error_code error;
        root_ = std::filesystem::temp_directory_path(error) / std::format("tl_ui_script_golden_{}", stamp);
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

// ---- Keo giữa kịch bản của trọng tài và Host ----

// Màn của host trên giao diện thật, cộng hình học do kịch bản đặt (__geometry): ô dàn trang và độ lệch của vài cửa sổ. Chưa đặt thì hỏi màn
// thật (chưa dàn trang nên không biết).
class ScenarioScreen final : public ui::script::Screen {
public:
    explicit ScenarioScreen(ui::script::GuiScreen& inner) : inner_(&inner) {}

    [[nodiscard]] std::expected<gui::GuiRange, std::string> load_layout(std::string_view layout) override {
        return inner_->load_layout(layout);
    }
    [[nodiscard]] const gui::GuiAsset& asset() const noexcept override { return inner_->asset(); }
    [[nodiscard]] std::optional<ui::script::Spot> offset(std::string_view window, std::string_view root) const override {
        const auto found = offsets_.find(window);
        if (found != offsets_.end()) return found->second;
        return inner_->offset(window, root);
    }
    [[nodiscard]] bool hits(std::string_view window, ui::script::Spot spot) const override { return inner_->hits(window, spot); }
    [[nodiscard]] std::optional<ui::script::PixelBox> box(std::string_view window) const override {
        const auto found = boxes_.find(window);
        if (found != boxes_.end()) return found->second;
        return inner_->box(window);
    }

    void set_offset(std::string_view window, ui::script::Spot spot) { offsets_[std::string(window)] = spot; }
    // Ô của cửa sổ để kịch bản đặt từng số; tạo ô rỗng khi chưa có.
    ui::script::PixelBox& box_of(std::string_view window) { return boxes_[std::string(window)]; }

private:
    ui::script::GuiScreen* inner_;
    std::map<std::string, ui::script::Spot, std::less<>> offsets_;
    std::map<std::string, ui::script::PixelBox, std::less<>> boxes_;
};

enum class Dispatch : std::uint8_t {
    // Gọi thẳng <Tên>_OnEvent như trọng tài.
    kDirect,
    // Qua Host::post: luật gửi thật của client.
    kPost,
};

struct Chunk {
    std::string label;
    std::string code;
};

struct Harness {
    Host* host = nullptr;
    ScenarioScreen* screen = nullptr;
    std::string window;
    std::vector<GoldenBlock> produced;
    // Lời cho lua_error, đặt bởi các hàm bên dưới; hàm C gọi lua_error sau khi mọi đối tượng cục bộ đã huỷ.
    std::string failure;
    // Lỗi lúc nạp keo, thư viện và kịch bản phần đầu (trước khi script chạy).
    std::string setup_errors;

    // Việc game đã nhờ (DoAction...) kể từ lần trước thành dòng "!call", đứng sau những dòng __note trước đó: thứ tự gọi giữ nguyên.
    void settle_calls() {
        for (const ui::panel::Call& call : host->take_calls()) {
            const std::string tail = call.text.empty() ? std::string() : std::format("\t{}", call.text);
            pending.push_back(std::format("{}{}", ui::panel::name_of(call.ask), tail));
        }
    }

    void note(lua_State* state) {
        settle_calls();
        std::string line;
        const int count = lua_gettop(state);
        for (int at = 1; at <= count; ++at) {
            if (at > 1) line += '\t';
            line += text_of(state, at);
        }
        pending.push_back(flat(line));
    }

    void dump(std::string_view label) {
        settle_calls();
        GoldenBlock block{.label = std::string(label), .lines = {}};
        block.lines.push_back(std::format("this\tVisible\t{}", host->is_shown(window) ? "True" : "False"));
        if (const ui::panel::Widgets* widgets = host->widgets(window)) widgets->describe(block.lines);
        std::size_t number = 0;
        for (const std::string& line : pending)
            block.lines.push_back(std::format("!call{}\t{}", ++number, line));
        pending.clear();
        produced.push_back(std::move(block));
    }

    void dump_events(std::string_view label) {
        GoldenBlock block{.label = std::string(label), .lines = {}};
        for (const ui::script::Registration& one : host->registrations(window))
            block.lines.push_back(std::format("event\t{}\t{}", one.name, one.is_always ? "True" : "False"));
        produced.push_back(std::move(block));
    }

    // __fire(cửa sổ[, sự kiện]): chạy đoạn Lua mà layout nối vào sự kiện (mặc định Clicked). Thiếu cửa sổ, thiếu sự kiện hay script
    // lỗi thì báo lỗi Lua như trọng tài.
    void fire(lua_State* state) {
        const char* target = lua_tostring(state, 1);
        const char* event = lua_type(state, 2) <= LUA_TNIL ? "Clicked" : lua_tostring(state, 2);
        if (target == nullptr || event == nullptr) {
            failure = "__fire cần tên cửa sổ và tên sự kiện dạng chuỗi";
            return;
        }
        const MouseButton button = std::string_view(event) == "RBClicked" ? MouseButton::kRight : MouseButton::kLeft;
        if (!host->fire(target, event, button)) {
            failure = std::format("{} không nối sự kiện {}", target, event);
            return;
        }
        take_failure();
    }

    // __geometry(cửa sổ, trường, a[, b]): hình học của cửa sổ do kịch bản đặt. "Offset" là độ lệch (a, b) so với cửa sổ gốc của layout
    // (this:GetChildOffset); AbsoluteXPosition, AbsoluteYPosition, AbsoluteWidth, AbsoluteHeight là số đo điểm ảnh mà GetProperty đọc.
    void place(lua_State* state) const {
        const char* target = lua_tostring(state, 1);
        const char* field = lua_tostring(state, 2);
        if (target == nullptr || field == nullptr || screen == nullptr) return;
        const auto first = static_cast<float>(lua_tonumber(state, 3));
        const auto second = static_cast<float>(lua_tonumber(state, 4));
        const std::string_view name = field;
        if (name == "Offset") {
            screen->set_offset(target, ui::script::Spot{.x = first, .y = second});
            return;
        }
        ui::script::PixelBox& box = screen->box_of(target);
        if (name == "AbsoluteXPosition") box.x = first;
        if (name == "AbsoluteYPosition") box.y = first;
        if (name == "AbsoluteWidth") box.w = first;
        if (name == "AbsoluteHeight") box.h = first;
    }

    // __post(sự kiện, đối số...): sự kiện game qua luật gửi của Host. Script lỗi thì báo lỗi Lua.
    void post(lua_State* state) {
        const char* event = lua_tostring(state, 1);
        if (event == nullptr) {
            failure = "__post cần tên sự kiện dạng chuỗi";
            return;
        }
        std::vector<std::string> args;
        const int count = lua_gettop(state);
        for (int at = 2; at <= count; ++at)
            args.push_back(text_of(state, at));
        const std::vector<std::string_view> views(args.begin(), args.end());
        host->post(event, views);
        take_failure();
    }

    // Lời lỗi đầu tiên của Host (script gọi hỏng) thành failure.
    void take_failure() {
        const std::vector<std::string> notes = host->take_notes();
        if (!notes.empty()) failure = notes.front();
    }

    // tostring của Lua 5.0 cho nil, boolean, số, chuỗi; kiểu khác chỉ ghi tên kiểu.
    static std::string text_of(lua_State* state, int index) {
        switch (lua_type(state, index)) {
        case LUA_TNIL: return "nil";
        case LUA_TBOOLEAN: return lua_toboolean(state, index) != 0 ? "true" : "false";
        case LUA_TNUMBER:
        case LUA_TSTRING: return lua_tostring(state, index);
        default: return lua_typename(state, lua_type(state, index));
        }
    }

    // Gạch chéo ngược, xuống dòng và về đầu dòng viết thành hai ký tự: mỗi việc nhờ là đúng một dòng của tệp ra.
    static std::string flat(std::string_view value) {
        std::string text;
        for (const char one : value) {
            switch (one) {
            case '\\': text += "\\\\"; break;
            case '\n': text += "\\n"; break;
            case '\r': text += "\\r"; break;
            default: text += one; break;
            }
        }
        return text;
    }

    // Dòng "!call" chờ ghi vào khối __dump kế tiếp.
    std::vector<std::string> pending;
};

[[nodiscard]] Harness& harness_of(lua_State* state) {
    return *static_cast<Harness*>(lua_touserdata(state, lua_upvalueindex(1)));
}

// Báo lỗi Lua bằng lời trong failure; không đối tượng cục bộ nào còn sống lúc longjmp.
int raise_failure(lua_State* state) {
    Harness& self = harness_of(state);
    lua_pushlstring(state, self.failure.data(), self.failure.size());
    self.failure.clear();
    return lua_error(state);
}

int golden_note(lua_State* state) {
    harness_of(state).note(state);
    return 0;
}

int golden_dump(lua_State* state) {
    const char* label = lua_tostring(state, 1);
    harness_of(state).dump(label != nullptr ? label : "");
    return 0;
}

int golden_dump_events(lua_State* state) {
    const char* label = lua_tostring(state, 1);
    harness_of(state).dump_events(label != nullptr ? label : "");
    return 0;
}

int golden_fire(lua_State* state) {
    Harness& self = harness_of(state);
    self.fire(state);
    return self.failure.empty() ? 0 : raise_failure(state);
}

int golden_geometry(lua_State* state) {
    harness_of(state).place(state);
    return 0;
}

int golden_post(lua_State* state) {
    Harness& self = harness_of(state);
    self.post(state);
    return self.failure.empty() ? 0 : raise_failure(state);
}

// Phần keo bằng Lua. __event đặt arg<k> và eventTable[k + 1] rồi gọi <Tên>_OnEvent, như trọng tài (lua_oracle.py) và như
// _OnGameEvent của client; __check, __toggle, __pick là người chơi bấm nút đánh dấu hay chọn mục (lua_oracle.lua), dựng trên
// phương thức của widget thật.
constexpr std::string_view kGlueDirect = R"lua(
eventTable = eventTable or {}
function __event(name, ...)
    for index = 1, arg.n do
        local text = tostring(arg[index])
        rawset(_G, "arg" .. (index - 1), text)
        eventTable[index] = text
    end
    _G[__handler_name](name)
end
)lua";

constexpr std::string_view kGluePost = R"lua(
function __event(name, ...)
    __post(name, unpack(arg))
end
)lua";

constexpr std::string_view kGlueWidgets = R"lua(
local function widget(name)
    local found = _G[name]
    if found == nil then error("layout không có cửa sổ " .. tostring(name), 3) end
    return found
end

-- Người chơi bấm một nút đánh dấu: nút CheckMode 1 hay 2 đang bật thì giữ nguyên, còn lại đảo dấu (SetCheck(1) của nút
-- CheckMode 1 tự tắt các nút cùng cha), rồi script nghe sự kiện (mặc định Clicked).
function __check(name, event)
    local one = widget(name)
    local mode = one:GetProperty("CheckMode")
    local stays = (mode == "1" or mode == "2") and one:GetCheck() == 1
    if not stays then one:SetCheck(1 - one:GetCheck()) end
    __fire(name, event)
end

-- Ô đánh dấu thường: dấu đảo rồi script nghe sự kiện.
function __toggle(name, event)
    local one = widget(name)
    one:SetCheck(1 - one:GetCheck())
    __fire(name, event)
end

-- Người chơi bấm mục mang id của một danh sách: mục đó thành mục được chọn, rồi script nghe ItemSelectionChanged.
function __pick(name, id)
    widget(name):SetItemSelectByItemID(id)
    __fire(name, "ItemSelectionChanged")
end
)lua";

// Đăng ký hàm C của keo rồi chạy các đoạn nạp trước (keo Lua, bảng, thư viện hàm game, phần đầu của kịch bản). Chạy trong lua_cpcall
// của Host::open, trước script đầu tiên; lua_pcall từng đoạn nên lỗi của đoạn nào ghi vào setup_errors rồi đoạn kế vẫn chạy.
void install(lua_State* state, Harness& harness, const std::vector<Chunk>& chunks) {
    const std::array<std::pair<const char*, lua_CFunction>, 6> natives = {{
        {"__geometry", &golden_geometry},
        {"__note", &golden_note},
        {"__dump", &golden_dump},
        {"__dump_events", &golden_dump_events},
        {"__fire", &golden_fire},
        {"__post", &golden_post},
    }};
    for (const auto& [name, function] : natives) {
        lua_pushlightuserdata(state, &harness);
        lua_pushcclosure(state, function, 1);
        lua_setglobal(state, name);
    }
    for (const Chunk& chunk : chunks) {
        const std::string label = "=" + chunk.label;
        if (luaL_loadbuffer(state, chunk.code.data(), chunk.code.size(), label.c_str()) == 0 && lua_pcall(state, 0, 0, 0) == 0) continue;
        const char* message = lua_tostring(state, -1);
        harness.setup_errors += std::format("{}: {}\n", chunk.label, message != nullptr ? message : "lỗi không có thông điệp");
        lua_pop(state, 1);
    }
}

// ---- Chạy một cửa sổ ----

struct Rig {
    TempRoot root;
    gui::DiskSource files{io::path_from_utf8(kClientData) / "Interface"};
    gui::GuiSources sources;
    std::optional<gui::GuiLoader> loader;
    std::optional<ui::script::GuiScreen> inner;
    std::optional<ScenarioScreen> screen;
};

[[nodiscard]] std::optional<std::string> read_file(Context& context, const std::filesystem::path& path) {
    io::TextResult text = io::read_text(path);
    context.expect(text.has_value(), std::format("đọc được {}", io::utf8_of(path)));
    if (!text) return std::nullopt;
    return *std::move(text);
}

void run_spec(Context& context, const Spec& spec, Dispatch dispatch) {
    const std::string tag = std::format("{}/{}", spec.window, dispatch == Dispatch::kDirect ? "trực tiếp" : "post");
    const std::filesystem::path oracle = repository_root() / "TOOLS" / "port" / "oracle";

    const std::optional<std::string> registry = read_file(context, io::path_from_utf8(kClientData) / "Script" / "windows.tsv");
    const std::optional<std::string> scenario = read_file(context, oracle / io::path_from_utf8(std::format("{}.lua", spec.scenario)));
    if (!registry || !scenario) return;
    const auto windows = ui::script::parse_windows(*registry);
    context.expect(windows.has_value(), std::format("[{}] đọc được sổ cửa sổ", tag));
    if (!windows) return;
    const auto def = std::ranges::find(*windows, spec.window, &ui::script::WindowDef::name);
    context.expect(def != windows->end(), std::format("[{}] sổ cửa sổ có {}", tag, spec.window));
    if (def == windows->end()) return;

    const std::size_t mark = scenario->find(kStepsMark);
    context.expect(mark != std::string::npos, std::format("[{}] kịch bản có dòng {}", tag, kStepsMark));
    if (mark == std::string::npos) return;
    const std::string before = scenario->substr(0, mark);
    const std::string after = scenario->substr(mark + kStepsMark.size());

    std::optional<std::string> script = read_file(context, io::path_from_utf8(kScriptSource) / "Interface" / io::path_from_utf8(def->script));
    if (!script) return;
    if (spec.has_words) {
        const std::optional<std::string> table = read_file(context, oracle / "words.vi.tsv");
        if (!table) return;
        const auto words = parse_words(*table);
        context.expect(words.has_value(), words ? "đọc được bảng thay chữ" : words.error());
        if (!words) return;
        script = localized(*script, *words);
    }

    std::vector<Chunk> chunks;
    chunks.push_back(Chunk{.label = "keo (tên hàm)", .code = std::format("__handler_name = \"{}_OnEvent\"", spec.window)});
    chunks.push_back(Chunk{.label = "keo (sự kiện)", .code = std::string(dispatch == Dispatch::kDirect ? kGlueDirect : kGluePost)});
    chunks.push_back(Chunk{.label = "keo (widget)", .code = std::string(kGlueWidgets)});
    chunks.push_back(Chunk{.label = "__tables", .code = "__tables = {}"});
    for (const TableSpec& table : spec.tables) {
        const std::optional<std::string> text = read_file(context, io::path_from_utf8(kClientData) / "Table" / io::path_from_utf8(table.file));
        if (!text) return;
        auto code = table_code(table.name, *text);
        context.expect(code.has_value(), code ? "dựng bảng" : code.error());
        if (!code) return;
        chunks.push_back(Chunk{.label = std::format("--table {}", table.name), .code = *std::move(code)});
    }
    for (const std::string_view lib : spec.libs) {
        const std::optional<std::string> text = read_file(context, oracle / io::path_from_utf8(std::format("{}.lua", lib)));
        if (!text) return;
        chunks.push_back(Chunk{.label = std::string(lib), .code = *text});
    }
    chunks.push_back(Chunk{.label = std::format("{} (hàm)", spec.scenario), .code = before});

    Rig rig;
    const std::string registry_text = std::format("id\tname\tlayout\tscript\tdemise\n0\t{}\t{}\t{}\t{}\n", def->name, def->layout, def->script,
        static_cast<int>(def->demise));
    context.expect(rig.root.write("windows.tsv", registry_text) && rig.root.write(std::format("Interface/{}", def->script), *script),
        std::format("[{}] ghi được dữ liệu thử", tag));
    rig.sources.files = &rig.files;
    auto opened_loader = gui::GuiLoader::open(rig.sources);
    context.expect(opened_loader.has_value(), std::format("[{}] mở được giao diện của kho", tag));
    if (!opened_loader) return;
    rig.loader.emplace(std::move(*opened_loader));
    rig.inner.emplace(*rig.loader);
    rig.screen.emplace(*rig.inner);

    Harness harness;
    harness.window = spec.window;
    harness.screen = &*rig.screen;
    ui::script::HostDesc desc;
    desc.data_root = rig.root.path();
    desc.only = {std::string(spec.window)};
    desc.natives = [&harness, &chunks](lua_State* state) { install(state, harness, chunks); };
    auto opened = Host::open(desc, *rig.screen);
    context.expect(opened.has_value(), opened ? std::format("[{}] mở host", tag) : std::format("[{}] {}", tag, opened.error()));
    if (!opened) return;
    Host& host = *opened;
    harness.host = &host;
    context.expect(harness.setup_errors.empty(), std::format("[{}] nạp keo và thư viện: {}", tag, harness.setup_errors));
    for (const std::string& note : host.take_notes())
        context.expect(false, std::format("[{}] lúc mở: {}", tag, note));

    // Trọng tài nạp layout rồi chạy OnLoad trước các bước, không hiện cửa sổ; Host nạp lười ở lần hiện đầu, nên hiện rồi giấu.
    static_cast<void>(host.set_shown(spec.window, true));
    static_cast<void>(host.set_shown(spec.window, false));
    static_cast<void>(host.take_calls());
    for (const std::string& note : host.take_notes())
        context.expect(false, std::format("[{}] lúc nạp layout: {}", tag, note));

    context.expect(host.run(after), std::format("[{}] chạy hết kịch bản", tag));
    for (const std::string& note : host.take_notes())
        context.expect(false, std::format("[{}] {}", tag, note));

    const std::vector<GoldenBlock> golden = read_golden(spec.golden);
    std::erase_if(harness.produced, [](const GoldenBlock& block) { return block.lines.empty(); });
    context.expect(golden.size() == harness.produced.size(),
        std::format("[{}] số khối: số vàng {}, chạy ra {}", tag, golden.size(), harness.produced.size()));
    std::size_t lines = 0;
    for (std::size_t at = 0; at < std::min(golden.size(), harness.produced.size()); ++at) {
        lines += golden[at].lines.size();
        context.expect(golden[at].label == harness.produced[at].label,
            std::format("[{}] nhãn khối {}: số vàng \"{}\", chạy ra \"{}\"", tag, at, golden[at].label, harness.produced[at].label));
        GoldenBlock tagged = golden[at];
        tagged.label = std::format("{}: {}", tag, golden[at].label);
        expect_block(context, tagged, harness.produced[at].lines);
    }
    // Để thấy ca đã so thật bao nhiêu: số khối và số dòng của số vàng.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
    static_cast<void>(std::fprintf(stdout, "  [%s] %lu khối, %lu dòng số vàng\n", tag.c_str(), static_cast<unsigned long>(golden.size()),
        static_cast<unsigned long>(lines)));
}

void original_scripts_match_the_goldens(Context& context) {
    if (kPanelGolden.empty() || kClientData.empty() || kScriptSource.empty()) return;
    for (const Spec& spec : kSpecs) {
        run_spec(context, spec, Dispatch::kDirect);
        run_spec(context, spec, Dispatch::kPost);
    }
}

constexpr std::array<Case, 1> kCases = {{
    {.name = "original_scripts_match_the_goldens", .body = original_scripts_match_the_goldens},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
