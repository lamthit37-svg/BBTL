// Phần chủ của giao diện Lua: sổ cửa sổ, môi trường <Tên>_Env, `this`, gửi sự kiện, nhường chỗ, hẹn giờ. Hợp đồng và quy
// tắc longjmp ở host.hpp. Địa chỉ ghi ở từng hàm là của UI_CEGUI.dll hay Game.exe bản 3.71.9509 (D:\XTLBB\Bin64), tháo bằng
// TOOLS/port/pe_refs.py; mã 2008 (G:\TLBB\_ref\client\Game\Client\CEGUISystem) chỉ để đọc cho dễ, không phải chuẩn.
#include "ui/script/host.hpp"

#include "gui/asset.hpp"
#include "io/file.hpp"
#include "lua/state.hpp"
#include "luanum/luanum.h"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"
#include "ui/script/raise.hpp"
#include "ui/script/widget.hpp"
#include "ui/script/windows.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <expected>
#include <filesystem>
#include <format>
#include <functional>
#include <limits>
#include <map>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}

namespace game::ui::script {
namespace {

constexpr const char* kItemMeta = "MetaTable_UIWindowItem";
constexpr const char* kEventMeta = "CEGUIEventMetaTable";
constexpr const char* kEventArg = "CEArg";
constexpr const char* kEventTable = "eventTable";
constexpr std::size_t kNoteLimit = 512;
// Trần số đối số của một sự kiện được đưa vào arg<k> (gốc không có trần; sự kiện của game mang vài đối số).
constexpr std::size_t kArgLimit = 64;
// SetTimer của Win32: chu kỳ dưới USER_TIMER_MINIMUM thành 10 ms, trên USER_TIMER_MAXIMUM thành 0x7FFFFFFF.
constexpr std::chrono::milliseconds kTimerMinimum{10};
constexpr std::chrono::milliseconds kTimerMaximum{0x7FFF'FFFF};
// Khác gốc: gốc không có trần số hẹn giờ; script sai đặt hẹn giờ mỗi khung sẽ chạm trần này rồi báo lỗi.
constexpr std::size_t kTimerLimit = 4096;
// Hai sự kiện mà cửa sổ ẩn đã nạp layout vẫn giữ bản mới nhất để phát lại khi nó nhận sự kiện kế (id 0x166 và 0x2f7 của
// bộ gửi 0x180079310; tên tra ở bảng sự kiện của Game.exe 0x140a10cd0 và 0x140a272b0), theo thứ tự phát lại.
constexpr std::array<std::string_view, 2> kKeptEvents = {"VIEW_RESOLUTION_CHANGED", "ADJEST_UI_POS"};
// CloseAllWindow không giấu cửa sổ này mà đẩy sự kiện EUS_SHOW_RESULT (id 0xbf1) để script của nó tự đóng (0x18007643c).
constexpr std::string_view kEquipEducation = "EquipEducation_Upstage";
constexpr std::string_view kEquipEducationEvent = "EUS_SHOW_RESULT";
// Sự kiện mà hàm game của script đẩy: OpenWindow (0x176), CloseWindow không ép (0x177), PushDebugMessage (0x85).
constexpr std::string_view kOpenWindowEvent = "OPEN_WINDOW";
constexpr std::string_view kCloseWindowEvent = "CLOSE_WINDOW";
constexpr std::string_view kDebugMessageEvent = "NEW_DEBUGMESSAGE";
// GetCurClientSize không trả nhỏ hơn cỡ tối thiểu của client gốc.
constexpr std::uint32_t kMinClientWidth = 800;
constexpr std::uint32_t kMinClientHeight = 600;

// Tên bảng môi trường của một cửa sổ (<Tên>_Env).
struct Env {
    std::string_view name;
};

// Một đoạn Lua và nhãn của nó (tên chunk trong thông điệp lỗi, đầu dòng notes).
struct Chunk {
    std::string_view code;
    std::string_view label;
};

struct Core;

// Bản giữ của một sự kiện kKeptEvents.
struct Kept {
    std::vector<std::string> args;
};

// Cờ hiện của `this` cho widget (cửa sổ gốc của layout là `this`).
class ItemServices final : public Services {
public:
    ItemServices(Core& core, std::uint32_t index) noexcept : core_(&core), index_(index) {}

    [[nodiscard]] bool root_shown() const override;
    void set_root_shown(bool is_shown) override;

private:
    Core* core_;
    std::uint32_t index_;
};

// Một cửa sổ của sổ (CUIWindowItem). Nằm trong unique_ptr: widget và userdata `this` giữ địa chỉ của nó.
struct Item {
    Item(Core& core, std::uint32_t index, WindowDef from) : def(std::move(from)), env(def.name + "_Env"), services(core, index) {}

    WindowDef def;
    // Tên bảng toàn cục của môi trường.
    std::string env;
    // Bảng môi trường trong sổ đăng ký Lua.
    int env_ref = LUA_NOREF;
    bool is_loaded = false;
    // m_bShow (+0x160).
    bool is_shown = false;
    // Cờ của ClickHide (+0x174): vừa bị đóng vì người chơi bấm ra ngoài.
    bool is_clicked_away = false;
    std::vector<Registration> events;
    std::array<std::optional<Kept>, kKeptEvents.size()> kept;
    panel::Widgets widgets;
    ItemServices services;
    // Cửa sổ gốc của layout và khoảng cửa sổ của layout trong asset; có khi đã nạp.
    std::string_view root;
    gui::GuiRange windows;
};

struct Timer {
    std::string window;
    std::string code;
    std::chrono::milliseconds period{0};
    std::chrono::milliseconds due{0};
    // KillTimer(id) chỉ tắt hẹn giờ của Win32 mà không xoá dòng của bảng (0x1406975f0); KillTimer(đoạn lệnh) xoá dòng
    // đầu tiên trùng đoạn lệnh, kể cả dòng đã tắt (0x140697760).
    bool is_live = true;
};

// Trạng thái của Host. Mọi thứ Lua giữ con trỏ tới (Item, names, calls) có địa chỉ ổn định suốt đời máy Lua.
struct Core {
    Core() = default;
    Core(const Core&) = delete;
    Core& operator=(const Core&) = delete;
    Core(Core&&) = delete;
    Core& operator=(Core&&) = delete;
    // Đóng máy Lua trước khi huỷ thứ mà userdata trỏ tới.
    ~Core() {
        lua = nullptr;
        state.reset();
    }

    Screen* screen = nullptr;
    std::filesystem::path script_root;
    std::optional<lua::State> state;
    // state->raw(): luồng chính, hợp lệ suốt đời state (State move không đổi nó).
    lua_State* lua = nullptr;
    std::vector<std::unique_ptr<Item>> items;
    std::map<std::string, std::uint32_t, std::less<>> by_name;
    // Tên cửa sổ của layout đã nạp sang cửa sổ sổ chứa nó.
    std::map<std::string, std::uint32_t, std::less<>> owners;
    // Tên cửa sổ con mà widget giữ (deque: thêm không dời phần tử cũ).
    std::deque<std::string> names;
    std::map<std::string, std::vector<std::uint32_t>, std::less<>> subscribers;
    // Cửa sổ loại kPopup theo thứ tự sổ (danh sách +0x18 của CUIWindowMng, dựng ở Init 0x1800775ae).
    std::vector<std::uint32_t> popups;
    // Cửa sổ đang hiện, dưới lên trên.
    std::vector<std::uint32_t> stack;
    std::vector<panel::Call> calls;
    std::vector<std::string> notes;
    std::size_t dropped_notes = 0;
    // Môi trường đang đặt (m_strEnvName của CScriptSystem); rỗng tới lời gọi đầu tiên.
    std::string active_env;
    int item_meta_ref = LUA_NOREF;
    int event_table_ref = LUA_NOREF;
    // Sự kiện CEGUI đang chạy, cho CEArg:GetValue.
    bool has_arg = false;
    std::string arg_window;
    MouseButton arg_button = MouseButton::kNone;
    std::map<std::int32_t, Timer> timers;
    std::int32_t next_timer = 1;
    std::chrono::milliseconds now{0};
    // Đã có nhịp nào chưa: nhịp đầu không tính thời gian trôi (đồng hồ khung của người gọi bắt đầu ở đâu cũng được).
    bool has_ticked = false;
    // Vùng khách của cửa sổ chương trình (GetCurClientSize); 0 khi người gọi chưa báo.
    ClientSize client_size;
};

// Userdata của `this` (BoxPointer của CUIWindowItem).
struct ThisBox {
    Core* core;
    std::uint32_t index;
};

void add_note(Core& core, std::string text) {
    if (core.notes.size() < kNoteLimit)
        core.notes.push_back(std::move(text));
    else
        ++core.dropped_notes;
}

// Thân của một vùng bảo vệ: chỉ gọi API Lua, không dựng đối tượng C++ có destructor.
struct GuardCall {
    void* body;
    void (*invoke)(void* body, lua_State* lua);
};

// lua::protect đòi thân tự cân bằng ngăn xếp; thân của host không bảo đảm điều đó (ngăn xếp trước đây bỏ cả khi cpcall về).
// NOLINTNEXTLINE(misc-const-correctness): chữ ký cố định của lua::ProtectedBody (void*, không const)
void guard_entry(lua_State* lua, void* data) {
    const auto* call = static_cast<const GuardCall*>(data);
    const int top = lua_gettop(lua);
    call->invoke(call->body, lua);
    lua_settop(lua, top);
}

// Chạy body(lua) trong lua::protect (trần lệnh tính từ lời gọi ngoài cùng, trần độ sâu của các vùng lồng nhau). Lỗi Lua hay vượt
// trần: một dòng notes "<where>: <thông điệp>", lỗi chạy kèm traceback.
template <class Body>
bool guard(Core& core, std::string_view where, Body& body) {
    GuardCall call{.body = &body, .invoke = [](void* raw, lua_State* lua) { (*static_cast<Body*>(raw))(lua); }};
    const std::expected<void, lua::Failure> done = lua::protect(core.lua, &guard_entry, &call);
    if (done) return true;
    add_note(core, std::format("{}: {}", where, done.error().message));
    return false;
}

[[nodiscard]] Core* core_of(lua_State* lua) {
    return static_cast<Core*>(lua_touserdata(lua, lua_upvalueindex(1)));
}

// SetActiveEnvironment (0x140653830): _G mang metatable {__index = <tên>}. Như gốc, tên tra trong _G lúc đặt.
void set_env(Core& core, Env env) {
    auto body = [env](lua_State* lua) {
        lua_pushvalue(lua, LUA_GLOBALSINDEX);
        lua_newtable(lua);
        lua_pushliteral(lua, "__index");
        lua_pushlstring(lua, env.name.data(), env.name.size());
        lua_gettable(lua, LUA_GLOBALSINDEX);
        lua_settable(lua, -3);
        lua_setmetatable(lua, -2);
        lua_pop(lua, 1);
    };
    if (guard(core, "đặt môi trường", body)) core.active_env = env.name;
}

// DoString của CScriptEnvironment: đặt môi trường env, chạy body, rồi đặt lại môi trường cũ khi nó khác rỗng.
template <class Body>
bool run_in(Core& core, Env env, std::string_view where, Body& body) {
    const std::string old = core.active_env;
    set_env(core, env);
    const bool is_done = guard(core, where, body);
    if (!old.empty()) set_env(core, Env{old});
    return is_done;
}

// Gọi hàm toàn cục <tên cửa sổ><suffix>(argument) trong môi trường của cửa sổ (DoFunction: "%s(%s);").
bool call_function(Core& core, const Item& item, std::string_view suffix, std::optional<std::string_view> argument) {
    const std::string function = item.def.name + std::string(suffix);
    auto body = [&function, argument](lua_State* lua) {
        lua_pushlstring(lua, function.data(), function.size());
        lua_gettable(lua, LUA_GLOBALSINDEX);
        if (argument) lua_pushlstring(lua, argument->data(), argument->size());
        lua_call(lua, argument ? 1 : 0, 0);
    };
    return run_in(core, Env{item.env}, function, body);
}

// Biên dịch và chạy một đoạn Lua; lỗi cú pháp đi theo cùng đường với lỗi lúc chạy.
void load_and_call(lua_State* lua, std::string_view code, const char* chunk) {
    if (luaL_loadbuffer(lua, code.data(), code.size(), chunk) != 0) lua_error(lua);
    lua_call(lua, 0, 0);
}

bool run_code_in(Core& core, Env env, Chunk chunk) {
    const std::string name = std::format("={}", chunk.label);
    auto body = [code = chunk.code, &name](lua_State* lua) { load_and_call(lua, code, name.c_str()); };
    return run_in(core, env, chunk.label, body);
}

[[nodiscard]] Item* find_item(Core& core, std::string_view name) {
    const auto found = core.by_name.find(name);
    return found == core.by_name.end() ? nullptr : core.items[found->second].get();
}

void raise_to_top(Core& core, std::uint32_t index) {
    std::erase(core.stack, index);
    core.stack.push_back(index);
}

bool load_window(Core& core, std::uint32_t index);

// Chạy mọi đoạn Lua mà layout nối vào sự kiện event của cửa sổ window thuộc cửa sổ sổ owner (FireUIEvent 0x1800768b0:
// globals.arg0 = tên cửa sổ phát, rồi DoString trong môi trường của chủ), với CEArg trỏ vào sự kiện này.
bool fire_in(Core& core, std::uint32_t owner, std::string_view window, std::string_view event, MouseButton button) {
    const Item& item = *core.items[owner];
    const gui::GuiAsset& asset = core.screen->asset();
    std::vector<std::string> codes;
    for (std::uint32_t slot = 0; slot < item.windows.count; ++slot) {
        const gui::GuiWindow& found = asset.windows.at(std::size_t{item.windows.first} + slot);
        if (found.name != window) continue;
        for (std::uint32_t at = 0; at < found.events.count; ++at) {
            const gui::GuiEvent& said = asset.events.at(std::size_t{found.events.first} + at);
            if (said.name == event) codes.push_back(said.function);
        }
        break;
    }
    if (codes.empty()) return false;
    const bool had_arg = core.has_arg;
    std::string saved_window = std::exchange(core.arg_window, std::string(window));
    const MouseButton saved_button = std::exchange(core.arg_button, button);
    core.has_arg = true;
    const std::string where = std::format("{}:{}", window, event);
    for (const std::string& code : codes) {
        auto set_arg = [window](lua_State* lua) {
            lua_pushliteral(lua, "arg0");
            lua_pushlstring(lua, window.data(), window.size());
            lua_settable(lua, LUA_GLOBALSINDEX);
        };
        if (!guard(core, where, set_arg)) continue;
        run_code_in(core, Env{item.env}, Chunk{.code = code, .label = where});
    }
    core.has_arg = had_arg;
    core.arg_window = std::move(saved_window);
    core.arg_button = saved_button;
    return true;
}

// Show(bShow) của CUIWindowItem (0x180078aa0). CEGUI phát Shown hay Hidden của cửa sổ gốc ngay trong setVisible, trước khi
// m_bShow đổi, nên đoạn Lua của sự kiện ấy thấy IsVisible cũ.
// Khác gốc: gốc gọi setVisible lên cửa sổ chưa nạp (con trỏ rỗng); ở đây hiện cửa sổ chưa nạp thì nạp trước. Âm thanh mở và
// đóng (cột open_sound, close_sound), báo cho hệ hướng dẫn (vtable 0x340) và cờ lớp vẽ +0x1d8 chưa port.
void show_item(Core& core, std::uint32_t index, bool is_shown) {
    Item& item = *core.items[index];
    if (is_shown == item.is_shown) return;
    if (is_shown && !item.is_loaded && !load_window(core, index)) return;
    const std::string root(item.root);
    if (!root.empty()) fire_in(core, index, root, is_shown ? "Shown" : "Hidden", MouseButton::kNone);
    if (is_shown)
        raise_to_top(core, index);
    else
        std::erase(core.stack, index);
    item.is_shown = is_shown;
}

// Đóng mọi cửa sổ cùng nhóm đang hiện, theo thứ tự list; gặp chính cửa sổ đang hiện thì thôi (0x18007675e).
template <class Pick>
void close_group(Core& core, std::uint32_t self, std::span<const std::uint32_t> list, Pick picks) {
    for (const std::uint32_t other : list) {
        if (!picks(*core.items[other])) continue;
        if (other == self && core.items[other]->is_shown) return;
        if (core.items[other]->is_shown) show_item(core, other, false);
    }
}

bool close_all(Core& core) {
    bool is_closed = false;
    for (std::uint32_t index = 0; index < core.items.size(); ++index) {
        const Item& item = *core.items[index];
        if (item.def.demise == Demise::kKeep || item.def.demise == Demise::kCloseAllKept || !item.is_shown) continue;
        if (item.def.name == kEquipEducation) {
            core.calls.push_back(panel::Call{.ask = panel::Ask::kPushEvent, .text = std::string(kEquipEducationEvent)});
            continue;
        }
        show_item(core, index, false);
        is_closed = true;
    }
    return is_closed;
}

// DemiseWindow(item, TRUE) (0x180076710).
void demise(Core& core, std::uint32_t index) {
    const Demise kind = core.items[index]->def.demise;
    std::vector<std::uint32_t> all(core.items.size());
    switch (kind) {
    case Demise::kKeep:
    case Demise::kPlain:
    case Demise::kNearCursor: return;
    case Demise::kGroupA:
    case Demise::kGroupB:
        for (std::uint32_t at = 0; at < all.size(); ++at)
            all[at] = at;
        close_group(core, index, all, [kind](const Item& item) { return item.def.demise == kind; });
        return;
    case Demise::kCloseAll:
    case Demise::kCloseAllKept: close_all(core); return;
    case Demise::kPopup: {
        const std::vector<std::uint32_t> popups = core.popups;
        close_group(core, index, popups, [](const Item&) { return true; });
        return;
    }
    }
}

// Một cửa sổ nhận một sự kiện (_OnGameEvent 0x18007b8e0): arg<k> và eventTable[k + 1] là đối số thứ k, rồi
// <Tên>_OnEvent("<sự kiện>").
void deliver(Core& core, std::uint32_t index, std::string_view event, std::span<const std::string_view> args) {
    std::vector<std::string> names;
    const std::size_t count = std::min(args.size(), kArgLimit);
    names.reserve(count);
    for (std::size_t at = 0; at < count; ++at)
        names.push_back(std::format("arg{}", at));
    auto set_args = [&core, &names, args, count](lua_State* lua) {
        for (std::size_t at = 0; at < count; ++at) {
            lua_pushlstring(lua, names[at].data(), names[at].size());
            lua_pushlstring(lua, args[at].data(), args[at].size());
            lua_settable(lua, LUA_GLOBALSINDEX);
            lua_rawgeti(lua, LUA_REGISTRYINDEX, core.event_table_ref);
            lua_pushlstring(lua, args[at].data(), args[at].size());
            lua_rawseti(lua, -2, static_cast<int>(at) + 1);
            lua_pop(lua, 1);
        }
    };
    if (args.size() > kArgLimit) add_note(core, std::format("{}: {} đối số, chỉ đưa {}", event, args.size(), kArgLimit));
    if (!guard(core, event, set_args)) return;
    call_function(core, *core.items[index], "_OnEvent", event);
}

void replay_kept(Core& core, std::uint32_t index) {
    for (std::size_t slot = 0; slot < kKeptEvents.size(); ++slot) {
        std::optional<Kept> kept = std::exchange(core.items[index]->kept.at(slot), std::nullopt);
        if (!kept) continue;
        const std::vector<std::string_view> views(kept->args.begin(), kept->args.end());
        deliver(core, index, kKeptEvents.at(slot), views);
    }
}

// Bộ gửi của một cửa sổ (0x180079310).
void dispatch(Core& core, std::uint32_t index, bool is_always, std::string_view event, std::span<const std::string_view> args) {
    Item& item = *core.items[index];
    if (!is_always && !item.is_shown) {
        if (!item.is_loaded) return;
        const auto slot = std::ranges::find(kKeptEvents, event);
        if (slot != kKeptEvents.end()) {
            item.kept.at(static_cast<std::size_t>(slot - kKeptEvents.begin())) = Kept{.args = {args.begin(), args.end()}};
        }
        return;
    }
    if (!item.is_loaded && !load_window(core, index)) return;
    replay_kept(core, index);
    deliver(core, index, event, args);
}

// LoadWindow (0x180077f20): nạp layout, mỗi cửa sổ của nó thành một widget trong <Tên>_Env, rồi <Tên>_OnLoad. Cờ đã nạp
// đặt trước OnLoad (khác gốc: gốc đặt sau) để một sự kiện tới cửa sổ này trong lúc OnLoad chạy không nạp lại layout.
bool load_window(Core& core, std::uint32_t index) {
    Item& item = *core.items[index];
    if (item.is_loaded) return true;
    const auto range = core.screen->load_layout(item.def.layout);
    if (!range) {
        add_note(core, std::format("{}: không nạp được layout {}: {}", item.def.name, item.def.layout, range.error()));
        return false;
    }
    const gui::GuiAsset& asset = core.screen->asset();
    std::vector<WindowRef> refs;
    refs.reserve(range->count);
    for (std::uint32_t slot = 0; slot < range->count; ++slot) {
        const auto at = static_cast<std::int32_t>(range->first + slot);
        const gui::GuiWindow& window = asset.windows.at(static_cast<std::size_t>(at));
        const std::string_view name = core.names.emplace_back(window.name);
        const auto [owner, is_new] = core.owners.try_emplace(window.name, index);
        if (!is_new && owner->second != index)
            add_note(core, std::format("{}: cửa sổ {} trùng tên với cửa sổ của {}", item.def.name, window.name,
                core.items[owner->second]->def.name));
        const bool has_type = window.type >= 0 && std::cmp_less(window.type, asset.types.size());
        const Kind kind = has_type ? kind_of(asset.types.at(static_cast<std::size_t>(window.type)).renderer) : Kind::kWindow;
        if (item.root.empty() && window.parent < 0) item.root = name;
        refs.push_back(WindowRef{.store = &item.widgets, .calls = &core.calls, .asset = &asset, .name = name, .kind = kind,
            .window = at, .services = &item.services});
    }
    item.windows = *range;
    auto body = [&refs, &item](lua_State* lua) {
        lua_rawgeti(lua, LUA_REGISTRYINDEX, item.env_ref);
        for (const WindowRef& ref : refs) {
            lua_pushlstring(lua, ref.name.data(), ref.name.size());
            push_widget(lua, ref);
            lua_rawset(lua, -3);
        }
        lua_pop(lua, 1);
    };
    if (!guard(core, item.def.name, body)) return false;
    item.is_loaded = true;
    call_function(core, item, "_OnLoad", std::nullopt);
    return true;
}

// --- Hàm C mà script gọi. Mỗi hàm chỉ báo lỗi ở đầu, trước khi dựng đối tượng C++ (host.hpp). ---

// Cửa sổ của self (đối số 1) khi nó là userdata `this` của host này; nullptr khi không.
[[nodiscard]] Item* this_item(lua_State* lua, Core& core) {
    if (lua_type(lua, 1) != LUA_TUSERDATA || lua_getmetatable(lua, 1) == 0) return nullptr;
    lua_rawgeti(lua, LUA_REGISTRYINDEX, core.item_meta_ref);
    const bool is_ours = lua_rawequal(lua, -1, -2) != 0;
    lua_pop(lua, 2);
    if (!is_ours) return nullptr;
    const auto* box = static_cast<const ThisBox*>(lua_touserdata(lua, 1));
    if (box->core != &core || box->index >= core.items.size()) return nullptr;
    return core.items[box->index].get();
}

[[nodiscard]] std::uint32_t index_of(const Core& core, const Item& item) {
    return core.by_name.find(item.def.name)->second;
}

int lua_this_error(lua_State* lua) {
    return raise(lua, "this: đối số self không phải cửa sổ (viết this:Hàm() thay cho this.Hàm())");
}

void register_event(Core& core, Item& item, std::string_view name, bool is_always) {
    const auto same = [name](const Registration& said) { return said.name == name; };
    if (std::ranges::any_of(item.events, same)) return;
    item.events.push_back(Registration{.name = std::string(name), .is_always = is_always});
    core.subscribers[std::string(name)].push_back(index_of(core, item));
}

// RegisterEvent(tên[, cờ]) (0x180077be0).
int this_register_event(lua_State* lua) {
    Core& core = *core_of(lua);
    Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    if (lua_isstring(lua, 2) == 0) return 0;
    const char* name = lua_tostring(lua, 2);
    const std::size_t size = lua_strlen(lua, 2);
    if (item->is_loaded) {
        lua_pushlstring(lua, item->def.name.data(), item->def.name.size());
        lua_pushliteral(lua, " Must register event in \"***PreLoad\" Function ");
        return raise_pushed(lua, 2);
    }
    const bool is_always = lua_type(lua, 3) != LUA_TBOOLEAN || lua_toboolean(lua, 3) != 0;
    register_event(core, *item, std::string_view(name, size), is_always);
    return 0;
}

// Show() (0x180077e70): nhường chỗ rồi hiện.
int this_show(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    const std::uint32_t index = index_of(core, *item);
    demise(core, index);
    show_item(core, index, true);
    return 0;
}

// Hide() (0x180077af0): không nhường chỗ.
int this_hide(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    show_item(core, index_of(core, *item), false);
    return 0;
}

// TogleShow() (0x180077eb0): đang hiện thì giấu (không nhường chỗ), không thì nhường chỗ rồi hiện.
int this_togle_show(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    const std::uint32_t index = index_of(core, *item);
    if (item->is_shown) {
        show_item(core, index, false);
    } else {
        demise(core, index);
        show_item(core, index, true);
    }
    return 0;
}

// IsVisible() (0x180077ba0): m_bShow.
int this_is_visible(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    lua_pushboolean(lua, item->is_shown ? 1 : 0);
    return 1;
}

// TransAllWindowText() (0x180077f00): gốc dịch lại thẻ #{} trong chữ của mọi cửa sổ. Bộ vẽ của bản này dịch thẻ lúc vẽ nên
// không còn gì phải làm.
int this_trans_all_window_text(lua_State* lua) {
    Core& core = *core_of(lua);
    if (this_item(lua, core) == nullptr) return lua_this_error(lua);
    return 0;
}

void care_object(Core& core, const Item& item, std::int32_t object) {
    core.calls.push_back(panel::Call{.ask = panel::Ask::kCareObject, .text = std::format("{}\t{}", object, item.def.name)});
}

// CareObject(id, cờ) (0x180077870): id phải là số; cờ khác 0 thì nhờ hệ đối tượng theo dõi, cờ 0 thì không làm gì.
int this_care_object(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    if (lua_type(lua, 2) != LUA_TNUMBER) {
        lua_pushliteral(lua, "LUA: CUIWindowItem::LUA_CareObject[2] Wrong Param:");
        lua_pushnumber(lua, lua_type(lua, 2));
        lua_pushliteral(lua, ",WindowName:");
        lua_pushlstring(lua, item->def.name.data(), item->def.name.size());
        return raise_pushed(lua, 4);
    }
    const std::int32_t object = luanum_to_int32(lua_tonumber(lua, 2));
    const std::int32_t care = luanum_to_int32(lua_tonumber(lua, 3));
    if (care != 0) care_object(core, *item, object);
    return 0;
}

// ClickHide() (0x180077910): cờ "vừa bị đóng vì bấm ra ngoài" rồi xoá cờ.
int this_click_hide(lua_State* lua) {
    Core& core = *core_of(lua);
    Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    lua_pushboolean(lua, item->is_clicked_away ? 1 : 0);
    item->is_clicked_away = false;
    return 1;
}

[[nodiscard]] Spot child_offset(const Core& core, std::uint32_t index, std::string_view child) {
    const Item& item = *core.items[index];
    const auto owner = core.owners.find(child);
    if (!item.is_loaded || owner == core.owners.end() || owner->second != index) return {};
    return core.screen->offset(child, item.root).value_or(Spot{});
}

// GetChildOffset(tên) (0x180077960): cộng vị trí tuyệt đối (so với cha) của cửa sổ con theo chuỗi cha tới cửa sổ gốc;
// không thấy cửa sổ con thì (0, 0). Tên không qua lua_isstring (LuaStackObject::IsString: chuỗi hay số) là lỗi.
int this_get_child_offset(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    if (lua_isstring(lua, 2) == 0) return raise(lua, "LUA: CUIWindowItem::LUA_GetChildOffset Wrong Param1");
    const std::string_view child(lua_tostring(lua, 2), lua_strlen(lua, 2));
    const Spot offset = child_offset(core, index_of(core, *item), child);
    lua_pushnumber(lua, static_cast<lua_Number>(offset.x));
    lua_pushnumber(lua, static_cast<lua_Number>(offset.y));
    return 2;
}

// Activate() (0x180077850): đưa cửa sổ gốc lên trên cùng (CEGUI Window::activate). Cửa sổ ẩn không có trên chồng vẽ; lần
// hiện sau đưa nó lên trên cùng như gốc.
int this_activate(lua_State* lua) {
    Core& core = *core_of(lua);
    const Item* item = this_item(lua, core);
    if (item == nullptr) return lua_this_error(lua);
    if (item->is_shown) raise_to_top(core, index_of(core, *item));
    return 0;
}

[[nodiscard]] const char* button_name(MouseButton button) noexcept {
    switch (button) {
    case MouseButton::kLeft: return "LeftButton";
    case MouseButton::kRight: return "RightButton";
    case MouseButton::kMiddle: return "MiddleButton";
    case MouseButton::kX1: return "X1Button";
    case MouseButton::kX2: return "X2Button";
    case MouseButton::kNone: return "NoButton";
    }
    return "";
}

// CEArg:GetValue(khoá) (CEventArg::LUA_GetValue, UI_CEGUI 0x180044670): WindowName và MouseButton của sự kiện CEGUI đang
// chạy; không có sự kiện hay khoá không phải chuỗi thì chuỗi rỗng.
// Khác gốc: HyperLinkName, MousePosition, MouseClickCount trả chuỗi rỗng (bộ vẽ chưa đưa các số đó; kho script không dùng).
int event_get_value(lua_State* lua) {
    const Core& core = *core_of(lua);
    if (lua_isstring(lua, 2) == 0 || !core.has_arg) {
        lua_pushliteral(lua, "");
        return 1;
    }
    const std::string_view key(lua_tostring(lua, 2), lua_strlen(lua, 2));
    if (key == "WindowName")
        lua_pushlstring(lua, core.arg_window.data(), core.arg_window.size());
    else if (key == "MouseButton")
        lua_pushstring(lua, button_name(core.arg_button));
    else
        lua_pushliteral(lua, "");
    return 1;
}

// SetTimer của Win32: chu kỳ kẹp vào [10 ms, 0x7FFFFFFF ms]; số âm đổi sang UINT thành số lớn nên cũng thành trần trên.
[[nodiscard]] std::chrono::milliseconds timer_period(std::int32_t milliseconds) noexcept {
    if (milliseconds < 0) return kTimerMaximum;
    return std::clamp(std::chrono::milliseconds{milliseconds}, kTimerMinimum, kTimerMaximum);
}

[[nodiscard]] std::optional<std::int32_t> add_timer(Core& core, std::string_view window, std::string_view code, std::int32_t milliseconds) {
    // Khác gốc: dòng đã tắt bằng KillTimer(id) nằm lại bảng như gốc (KillTimer(đoạn lệnh) vẫn có thể xoá nó), nhưng bảng chạm
    // trần thì bỏ hết dòng đã tắt, để script đặt rồi tắt theo id mỗi lần bấm không làm bảng lớn mãi.
    if (core.timers.size() >= kTimerLimit * 2) std::erase_if(core.timers, [](const auto& entry) { return !entry.second.is_live; });
    const auto live = std::ranges::count_if(core.timers, [](const auto& entry) { return entry.second.is_live; });
    if (std::cmp_greater_equal(live, kTimerLimit) || core.next_timer == std::numeric_limits<std::int32_t>::max()) return std::nullopt;
    const std::int32_t id = core.next_timer++;
    const std::chrono::milliseconds period = timer_period(milliseconds);
    core.timers.emplace(id, Timer{.window = std::string(window), .code = std::string(code), .period = period,
        .due = core.now + period});
    return id;
}

// SetTimer(tên cửa sổ, đoạn lệnh, ms) (Game.exe 0x140697f00, 0x140697440): hai đối số đầu là chuỗi, ms là số; sai thì -1.
// Mỗi lần gọi một hẹn giờ lặp mới, id mới.
int lua_set_timer(lua_State* lua) {
    Core& core = *core_of(lua);
    if (lua_isstring(lua, 1) == 0 || lua_isstring(lua, 2) == 0 || lua_type(lua, 3) != LUA_TNUMBER) {
        lua_pushnumber(lua, -1);
        return 1;
    }
    const std::string_view window(lua_tostring(lua, 1), lua_strlen(lua, 1));
    const std::string_view code(lua_tostring(lua, 2), lua_strlen(lua, 2));
    const std::int32_t milliseconds = luanum_to_int32(lua_tonumber(lua, 3));
    const std::optional<std::int32_t> id = add_timer(core, window, code, milliseconds);
    if (!id) {
        lua_pushliteral(lua, "SetTimer: đã có ");
        lua_pushnumber(lua, static_cast<lua_Number>(kTimerLimit));
        lua_pushliteral(lua, " hẹn giờ");
        return raise_pushed(lua, 3);
    }
    lua_pushnumber(lua, *id);
    return 1;
}

void kill_timer_code(Core& core, std::string_view code) {
    const auto found = std::ranges::find_if(core.timers, [code](const auto& entry) { return entry.second.code == code; });
    if (found != core.timers.end()) core.timers.erase(found);
}

// KillTimer(id hay đoạn lệnh) (0x140698110): số thì tắt hẹn giờ id, chuỗi thì xoá hẹn giờ đầu tiên (id nhỏ nhất) mang đúng
// đoạn lệnh; cả hai trả true. Kiểu khác trả false.
int lua_kill_timer(lua_State* lua) {
    Core& core = *core_of(lua);
    if (lua_type(lua, 1) == LUA_TNUMBER) {
        const auto found = core.timers.find(luanum_to_int32(lua_tonumber(lua, 1)));
        if (found != core.timers.end()) found->second.is_live = false;
        lua_pushboolean(lua, 1);
        return 1;
    }
    if (lua_isstring(lua, 1) == 0) {
        lua_pushboolean(lua, 0);
        return 1;
    }
    kill_timer_code(core, std::string_view(lua_tostring(lua, 1), lua_strlen(lua, 1)));
    lua_pushboolean(lua, 1);
    return 1;
}

// Đẩy sự kiện lên hàng đợi của game (CEventSystem, id 0xd8 của vtable): hàng đợi Call, HUD đưa lại cho mọi cửa sổ.
// Đối số cách nhau bằng tab (ui/panel/call.hpp).
void push_event(Core& core, std::string_view event, std::span<const std::string_view> args) {
    std::string text(event);
    for (const std::string_view arg : args) {
        text += '\t';
        text += arg;
    }
    core.calls.push_back(panel::Call{.ask = panel::Ask::kPushEvent, .text = std::move(text)});
}

// PushEvent(tên[, đối số...]) (Game.exe 0x140255060): tên là chuỗi hay số (lua_isstring), các đối số sau gom tới đối số đầu tiên
// không phải chuỗi hay số (nil, boolean, bảng...). Khác gốc: đối số chứa ký tự tab tách thành nhiều đối số (Call ngăn đối số
// bằng tab); trần kArgLimit đối số.
int lua_push_event(lua_State* lua) {
    Core& core = *core_of(lua);
    // Chính tả "PushEvnet" là của gốc.
    if (lua_isstring(lua, 1) == 0) return raise(lua, "Lua_PushEvnet Wrong Param1");
    std::array<std::string_view, kArgLimit + 1> given;
    std::size_t count = 0;
    const int top = lua_gettop(lua);
    for (int index = 1; index <= top && count < given.size() && lua_isstring(lua, index) != 0; ++index)
        given.at(count++) = std::string_view(lua_tostring(lua, index), lua_strlen(lua, index));
    push_event(core, given.front(), std::span(given).subspan(1, count - 1));
    return 0;
}

// PushDebugMessage(chữ) (0x140233920): chữ là chuỗi hay số; sự kiện NEW_DEBUGMESSAGE (0x85) rồi FUN_14007af80(3).
// Khác gốc: FUN_14007af80(3) chưa đọc, không làm gì.
int lua_push_debug_message(lua_State* lua) {
    Core& core = *core_of(lua);
    if (lua_isstring(lua, 1) == 0) return raise(lua, "LUA: Lua_PushDebugMessage Wrong Param");
    const std::array<std::string_view, 1> text = {std::string_view(lua_tostring(lua, 1), lua_strlen(lua, 1))};
    push_event(core, kDebugMessageEvent, text);
    return 0;
}

// OpenWindow(tên) (0x140246320): sự kiện OPEN_WINDOW (0x176) với tên cửa sổ. Khác gốc: tên không phải chuỗi hay số thì bỏ qua
// (gốc đưa con trỏ rỗng); FUN_140229d50 (cờ khoá) chưa đọc, coi như không khoá.
int lua_open_window(lua_State* lua) {
    Core& core = *core_of(lua);
    if (lua_isstring(lua, 1) == 0) return 0;
    const std::array<std::string_view, 1> name = {std::string_view(lua_tostring(lua, 1), lua_strlen(lua, 1))};
    push_event(core, kOpenWindowEvent, name);
    return 0;
}

// CloseWindow(tên[, ép]) (0x140246390): ép là boolean true thì đóng ngay (CUISystem vtable 0xe0), không thì sự kiện CLOSE_WINDOW
// (0x177). Khác gốc: đóng ngay một cửa sổ của host là giấu nó như this:Hide(); cửa sổ ngoài host (bảng port tay) chưa có phía
// nhận.
int lua_close_window(lua_State* lua) {
    Core& core = *core_of(lua);
    if (lua_isstring(lua, 1) == 0) return 0;
    const std::string_view name(lua_tostring(lua, 1), lua_strlen(lua, 1));
    if (lua_type(lua, 2) == LUA_TBOOLEAN && lua_toboolean(lua, 2) != 0) {
        if (const auto found = core.by_name.find(name); found != core.by_name.end()) show_item(core, found->second, false);
        return 0;
    }
    push_event(core, kCloseWindowEvent, std::array<std::string_view, 1>{name});
    return 0;
}

// IsWindowShow(tên) (0x140237f50): CUISystem vtable 0xc0. Khác gốc: chỉ biết cửa sổ của host; cửa sổ khác (bảng port tay chưa
// chuyển sang script) trả false.
int lua_is_window_show(lua_State* lua) {
    const Core& core = *core_of(lua);
    if (lua_isstring(lua, 1) == 0) return raise(lua, "LUA: Lua_IsWindowShow Wrong Param");
    const std::string_view name(lua_tostring(lua, 1), lua_strlen(lua, 1));
    const auto found = core.by_name.find(name);
    lua_pushboolean(lua, found != core.by_name.end() && core.items[found->second]->is_shown ? 1 : 0);
    return 1;
}

// GetCurClientSize() (0x140248ba0): rộng và cao vùng khách của cửa sổ chương trình, không nhỏ hơn 800x600.
int lua_get_client_size(lua_State* lua) {
    const Core& core = *core_of(lua);
    lua_pushnumber(lua, static_cast<lua_Number>(std::max(core.client_size.width, kMinClientWidth)));
    lua_pushnumber(lua, static_cast<lua_Number>(std::max(core.client_size.height, kMinClientHeight)));
    return 2;
}

void push_closure(lua_State* lua, Core& core, lua_CFunction function) {
    lua_pushlightuserdata(lua, &core);
    lua_pushcclosure(lua, function, 1);
}

// lua::State đã mở base, table, string, math; thêm io (kèm os) vì Agreement*.lua đọc tệp bằng io.open và vài script gọi os.time,
// os.date. Khác LuaState::Init(true) của gốc: không loadlib (nạp thư viện native), debug (debug.sethook gỡ được móc trần lệnh),
// wstring và các hàm LOG, _ALERT, LuaDump*; không script nào của kho gọi chúng (grep 2026-10-15 trên src/client/script).
void open_libraries(lua_State* lua) {
    luaopen_io(lua);
    lua_settop(lua, 0);
}

struct Method {
    const char* name;
    lua_CFunction function;
};

// MetaTable_UIWindowItem (CGameUIScript::createBindings, UI_CEGUI 0x180044db0): mười phương thức của `this`.
constexpr std::array<Method, 10> kThisMethods = {{
    {.name = "RegisterEvent", .function = &this_register_event},
    {.name = "Show", .function = &this_show},
    {.name = "Hide", .function = &this_hide},
    {.name = "TogleShow", .function = &this_togle_show},
    {.name = "IsVisible", .function = &this_is_visible},
    {.name = "TransAllWindowText", .function = &this_trans_all_window_text},
    {.name = "CareObject", .function = &this_care_object},
    {.name = "ClickHide", .function = &this_click_hide},
    {.name = "GetChildOffset", .function = &this_get_child_offset},
    {.name = "Activate", .function = &this_activate},
}};

// Hàm toàn cục của game mà host làm chủ vì chúng đụng hàng đợi sự kiện, cửa sổ và hẹn giờ của chính nó (nhóm C của TANG-B.md).
constexpr std::array<Method, 8> kGlobals = {{
    {.name = "SetTimer", .function = &lua_set_timer},
    {.name = "KillTimer", .function = &lua_kill_timer},
    {.name = "PushEvent", .function = &lua_push_event},
    {.name = "PushDebugMessage", .function = &lua_push_debug_message},
    {.name = "OpenWindow", .function = &lua_open_window},
    {.name = "CloseWindow", .function = &lua_close_window},
    {.name = "IsWindowShow", .function = &lua_is_window_show},
    {.name = "GetCurClientSize", .function = &lua_get_client_size},
}};

// Bảng toàn cục name (__index là chính nó) với các phương thức, giữ một tham chiếu trong sổ đăng ký.
int make_class(lua_State* lua, Core& core, const char* name, std::span<const Method> methods) {
    lua_newtable(lua);
    lua_pushliteral(lua, "__index");
    lua_pushvalue(lua, -2);
    lua_rawset(lua, -3);
    for (const Method& method : methods) {
        lua_pushstring(lua, method.name);
        push_closure(lua, core, method.function);
        lua_rawset(lua, -3);
    }
    lua_pushstring(lua, name);
    lua_pushvalue(lua, -2);
    lua_settable(lua, LUA_GLOBALSINDEX);
    return luaL_ref(lua, LUA_REGISTRYINDEX);
}

void open_host(lua_State* lua, Core& core) {
    core.item_meta_ref = make_class(lua, core, kItemMeta, kThisMethods);
    constexpr std::array<Method, 1> event_methods = {{{.name = "GetValue", .function = &event_get_value}}};
    const int event_meta = make_class(lua, core, kEventMeta, event_methods);
    lua_pushstring(lua, kEventArg);
    lua_newuserdata(lua, sizeof(void*));
    lua_rawgeti(lua, LUA_REGISTRYINDEX, event_meta);
    lua_setmetatable(lua, -2);
    lua_settable(lua, LUA_GLOBALSINDEX);
    luaL_unref(lua, LUA_REGISTRYINDEX, event_meta);
    lua_newtable(lua);
    lua_pushstring(lua, kEventTable);
    lua_pushvalue(lua, -2);
    lua_settable(lua, LUA_GLOBALSINDEX);
    core.event_table_ref = luaL_ref(lua, LUA_REGISTRYINDEX);
    for (const Method& global : kGlobals) {
        lua_pushstring(lua, global.name);
        push_closure(lua, core, global.function);
        lua_settable(lua, LUA_GLOBALSINDEX);
    }
    open_widget_classes(lua);
}

// PreLoadWindow (0x180078390): bảng <Tên>_Env, chạy script trong _G thường, `this`, rồi <Tên>_PreLoad.
void preload(Core& core, std::uint32_t index) {
    Item& item = *core.items[index];
    auto make_env = [&item](lua_State* lua) {
        lua_pushlstring(lua, item.env.data(), item.env.size());
        lua_newtable(lua);
        lua_pushvalue(lua, -1);
        item.env_ref = luaL_ref(lua, LUA_REGISTRYINDEX);
        lua_settable(lua, LUA_GLOBALSINDEX);
    };
    if (!guard(core, item.def.name, make_env)) return;
    const io::TextResult text = io::read_text(core.script_root / io::path_from_utf8(item.def.script));
    if (!text) {
        add_note(core, std::format("{}: không đọc được script {}: {}", item.def.name, item.def.script, io::describe(text.error())));
    } else {
        const std::string chunk = std::format("=Interface/{}", item.def.script);
        auto run_file = [&text, &chunk](lua_State* lua) { load_and_call(lua, *text, chunk.c_str()); };
        guard(core, item.def.script, run_file);
    }
    auto make_this = [&core, &item, index](lua_State* lua) {
        lua_rawgeti(lua, LUA_REGISTRYINDEX, item.env_ref);
        lua_pushliteral(lua, "this");
        std::construct_at(static_cast<ThisBox*>(lua_newuserdata(lua, sizeof(ThisBox))), ThisBox{.core = &core, .index = index});
        lua_rawgeti(lua, LUA_REGISTRYINDEX, core.item_meta_ref);
        lua_setmetatable(lua, -2);
        lua_rawset(lua, -3);
        lua_pop(lua, 1);
    };
    if (!guard(core, item.def.name, make_this)) return;
    call_function(core, item, "_PreLoad", std::nullopt);
}

bool ItemServices::root_shown() const {
    return core_->items[index_]->is_shown;
}

// Script đặt cờ hiện của cửa sổ gốc qua widget (SetFadeState, Show/Hide của chính cửa sổ gốc): đổi cờ của `this` và chồng
// vẽ, không nhường chỗ, không phát Shown/Hidden.
// Khác gốc: gốc giữ hai cờ (cờ hiện của cửa sổ CEGUI và m_bShow); bản này một cờ, như mô hình của trọng tài.
void ItemServices::set_root_shown(bool is_shown) {
    Item& item = *core_->items[index_];
    if (item.is_shown == is_shown) return;
    item.is_shown = is_shown;
    if (is_shown)
        raise_to_top(*core_, index_);
    else
        std::erase(core_->stack, index_);
}

// OPEN_WINDOW và CLOSE_WINDOW (id 0x176, 0x177) do cửa sổ nào của host mang tên ở đối số đầu: hiện như this:Show() hay giấu như
// this:Hide(). Khác gốc: nơi xử lý hai sự kiện này trong UI_CEGUI.dll chưa tìm thấy; giả định như CUISystem đóng/mở theo tên.
void open_close_by_event(Core& core, std::string_view event, std::span<const std::string_view> args) {
    const bool is_open = event == kOpenWindowEvent;
    if ((!is_open && event != kCloseWindowEvent) || args.empty()) return;
    const auto found = core.by_name.find(args.front());
    if (found == core.by_name.end()) return;
    if (is_open) demise(core, found->second);
    show_item(core, found->second, is_open);
}

} // namespace

struct Host::State {
    Core core;
};

Host::Host(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Host::Host(Host&&) noexcept = default;
Host& Host::operator=(Host&&) noexcept = default;
Host::~Host() = default;

std::expected<Host, std::string> Host::open(const HostDesc& desc, Screen& screen) {
    const std::filesystem::path registry = desc.data_root / "Script" / "windows.tsv";
    const io::TextResult text = io::read_text(registry);
    if (!text) return std::unexpected(std::format("không đọc được {}: {}", io::utf8_of(registry), io::describe(text.error())));
    auto windows = parse_windows(*text);
    if (!windows) return std::unexpected(std::format("{}: {}", io::utf8_of(registry), windows.error()));
    auto state = std::make_unique<State>();
    Core& core = state->core;
    for (const std::string& name : desc.only) {
        const auto same = [&name](const WindowDef& window) { return window.name == name; };
        if (!std::ranges::any_of(*windows, same)) add_note(core, std::format("{}: không có trong sổ cửa sổ", name));
    }
    if (!desc.only.empty()) {
        std::erase_if(*windows, [&desc](const WindowDef& window) { return !std::ranges::contains(desc.only, window.name); });
    }
    core.screen = &screen;
    core.script_root = desc.data_root / "Script" / "Interface";
    lua::Limits limits;
    limits.instructions = static_cast<std::int32_t>(std::min<std::uint32_t>(desc.instruction_limit, std::numeric_limits<std::int32_t>::max()));
    auto machine = lua::State::open(limits);
    if (!machine) return std::unexpected(std::format("không mở được máy Lua: {}", machine.error().message));
    core.state.emplace(std::move(*machine));
    core.lua = core.state->raw();
    auto open_all = [&core](lua_State* lua) {
        open_libraries(lua);
        open_host(lua, core);
    };
    if (!guard(core, "mở máy Lua", open_all)) return std::unexpected(std::move(core.notes.back()));
    if (desc.natives) {
        auto natives = [&desc](lua_State* lua) { desc.natives(lua); };
        guard(core, "hàm của game", natives);
    }
    core.items.reserve(windows->size());
    for (WindowDef& window : *windows) {
        const auto index = static_cast<std::uint32_t>(core.items.size());
        core.by_name.emplace(window.name, index);
        if (window.demise == Demise::kPopup) core.popups.push_back(index);
        core.items.push_back(std::make_unique<Item>(core, index, std::move(window)));
    }
    for (std::uint32_t index = 0; index < core.items.size(); ++index)
        preload(core, index);
    return Host(std::move(state));
}

void Host::post(std::string_view event, std::span<const std::string_view> args) {
    Core& core = state_->core;
    open_close_by_event(core, event, args);
    const auto found = core.subscribers.find(event);
    if (found == core.subscribers.end()) return;
    const std::vector<std::uint32_t> targets = found->second;
    for (const std::uint32_t index : targets) {
        const std::vector<Registration>& events = core.items[index]->events;
        const auto said = std::ranges::find(events, event, &Registration::name);
        dispatch(core, index, said == events.end() || said->is_always, event, args);
    }
}

bool Host::fire(std::string_view window, std::string_view event, MouseButton button) {
    Core& core = state_->core;
    const auto owner = core.owners.find(window);
    if (owner == core.owners.end()) return false;
    return fire_in(core, owner->second, window, event, button);
}

void Host::pressed(Spot spot) {
    Core& core = state_->core;
    const std::vector<std::uint32_t> popups = core.popups;
    for (const std::uint32_t index : popups) {
        Item& item = *core.items[index];
        if (!item.is_shown || (item.is_loaded && core.screen->hits(item.root, spot))) {
            item.is_clicked_away = false;
            continue;
        }
        show_item(core, index, false);
        item.is_clicked_away = true;
    }
}

void Host::tick(std::chrono::milliseconds now) {
    Core& core = state_->core;
    const std::chrono::milliseconds before = std::exchange(core.now, now);
    // Nhịp của widget có đồng hồ riêng (mờ dần của SuperProgress), mỗi cửa sổ đã nạp với thời gian trôi từ nhịp trước; đồng hồ
    // lùi thì coi như không trôi.
    const bool is_forward = std::exchange(core.has_ticked, true) && now >= before;
    const float seconds = is_forward ? std::chrono::duration<float>(now - before).count() : 0.0F;
    if (seconds > 0.0F) {
        for (const std::unique_ptr<Item>& item : core.items) {
            if (item->is_loaded) advance_widgets(item->widgets, core.screen->asset(), item->services, seconds);
        }
    }
    std::vector<std::pair<std::chrono::milliseconds, std::int32_t>> due;
    for (const auto& [id, timer] : core.timers) {
        if (timer.is_live && timer.due <= now) due.emplace_back(timer.due, id);
    }
    std::ranges::sort(due);
    for (const auto& [when, id] : due) {
        const auto found = core.timers.find(id);
        if (found == core.timers.end() || !found->second.is_live) continue;
        found->second.due = now + found->second.period;
        const std::string env = found->second.window + "_Env";
        const std::string code = found->second.code;
        const std::string label = std::format("hẹn giờ {}", id);
        run_code_in(core, Env{env}, Chunk{.code = code, .label = label});
    }
}

void Host::set_client_size(ClientSize size) noexcept {
    state_->core.client_size = size;
}

bool Host::set_shown(std::string_view name, bool is_shown) {
    Core& core = state_->core;
    const auto found = core.by_name.find(name);
    if (found == core.by_name.end()) return false;
    if (is_shown) demise(core, found->second);
    show_item(core, found->second, is_shown);
    return true;
}

bool Host::close_all() {
    return script::close_all(state_->core);
}

bool Host::is_shown(std::string_view name) const {
    const Item* item = find_item(state_->core, name);
    return item != nullptr && item->is_shown;
}

void Host::paint(panel::Deck& deck) const {
    const Core& core = state_->core;
    for (const std::uint32_t index : core.stack) {
        const Item& item = *core.items[index];
        if (item.root.empty()) continue;
        deck.show(item.root);
        item.widgets.paint(deck);
    }
}

std::vector<panel::Call> Host::take_calls() {
    return std::exchange(state_->core.calls, {});
}

std::vector<std::string> Host::take_notes() {
    Core& core = state_->core;
    std::vector<std::string> notes = std::exchange(core.notes, {});
    if (core.dropped_notes > 0) notes.push_back(std::format("… đã bỏ {} dòng lỗi", std::exchange(core.dropped_notes, 0)));
    return notes;
}

std::size_t Host::window_count() const noexcept {
    return state_->core.items.size();
}

const panel::Widgets* Host::widgets(std::string_view name) const {
    const Item* item = find_item(state_->core, name);
    return item == nullptr ? nullptr : &item->widgets;
}

std::span<const Registration> Host::registrations(std::string_view name) const {
    const Item* item = find_item(state_->core, name);
    if (item == nullptr) return {};
    return item->events;
}

bool Host::run(std::string_view code) {
    auto body = [code](lua_State* lua) { load_and_call(lua, code, "=run"); };
    return guard(state_->core, "run", body);
}

lua_State* Host::lua() const noexcept {
    return state_->core.lua;
}

} // namespace game::ui::script
