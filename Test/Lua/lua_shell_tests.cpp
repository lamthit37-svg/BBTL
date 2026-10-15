// Vỏ C++ lua::State của LuaPlus (src/client/face/lua): các trần (bộ nhớ, lệnh, độ sâu), lời lỗi kèm traceback, hàm native an toàn
// với longjmp, và một script thật của client 2026 (ProgressBar.lua) chạy qua vỏ với vết khớp lúc chạy trên LuaPlus.dll gốc.
// Logic an toàn: sai thì script treo client hay rò bộ nhớ lặng lẽ, nên mỗi mã Fault có một ca đi tới (CL-04).
#include "io/file.hpp"
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "lua/state.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using lua::Fault;
using lua::Failure;
using lua::Limits;
using lua::NativeError;
using lua::NativeResult;
using lua::State;

#ifdef GAME_SCRIPT_ROOT
constexpr std::string_view kScriptRoot = GAME_SCRIPT_ROOT;
#else
constexpr std::string_view kScriptRoot;
#endif

constexpr std::size_t kMiB = std::size_t{1} << 20U;

[[nodiscard]] State open_or_die(Context& context, const Limits& limits = {}) {
    std::expected<State, Failure> opened = State::open(limits);
    context.expect(opened.has_value(), opened ? "State::open" : opened.error().message);
    // Test không đi tiếp được nếu không dựng được state; lỗi đã ghi, trả một state mặc định để các ca sau không crash.
    if (!opened) opened = State::open();
    return *std::move(opened);
}

[[nodiscard]] bool has(const Failure& failure, std::string_view part) {
    return failure.message.contains(part);
}

// Kiểm một Failure đã có: mã và một đoạn của lời lỗi.
void check_failure(Context& context, const Failure& failure, Fault fault, std::string_view part) {
    context.expect(failure.fault == fault,
        std::format("fault {} (muốn {}): {}", lua::to_string(failure.fault), lua::to_string(fault), failure.message));
    context.expect(has(failure, part), std::format("lời lỗi chứa '{}': {}", part, failure.message));
}

// Chạy `code`, kỳ vọng thất bại với `fault` và lời lỗi chứa `part`.
void expect_failure(Context& context, State& state, std::string_view code, Fault fault, std::string_view part) {
    const std::expected<void, Failure> outcome = state.run(code, "=test");
    context.expect(!outcome.has_value(), std::format("phải thất bại: {}", code.substr(0, 60)));
    if (!outcome) check_failure(context, outcome.error(), fault, part);
}

void expect_ok(Context& context, State& state, std::string_view code) {
    const std::expected<void, Failure> outcome = state.run(code, "=test");
    context.expect(outcome.has_value(), outcome ? "run" : std::format("{}: {}", code.substr(0, 60), outcome.error().message));
}

[[nodiscard]] double number_global(State& state, const char* name) {
    lua_getglobal(state.raw(), name);
    const double value = lua_tonumber(state.raw(), -1);
    lua_pop(state.raw(), 1);
    return value;
}

// ---- dựng, chạy, move ----

void open_run_move(Context& context) {
    State first = open_or_die(context);
    expect_ok(context, first, "answer = 6 * 7");
    context.expect(number_global(first, "answer") == 42.0, "script đặt được biến toàn cục");
    context.expect(first.heap_used() > 0 && first.heap_used() <= lua::kDefaultHeapBytes, "heap_used trong (0, trần]");

    const lua_State* const raw = first.raw();
    State second = std::move(first);
    context.expect(second.raw() == raw, "move giữ nguyên lua_State");
    expect_ok(context, second, "answer = answer + 1");
    context.expect(number_global(second, "answer") == 43.0, "state đã move vẫn chạy");

    State third = open_or_die(context);
    third = std::move(second); // đóng state cũ của third rồi nhận state của second
    context.expect(third.raw() == raw, "gán move nhận lua_State");
    State other = open_or_die(context);
    expect_ok(context, other, "answer = 1");
    context.expect(number_global(third, "answer") == 43.0, "hai state độc lập");
}

void invalid_limits(Context& context) {
    for (const Limits& limits : {Limits{.heap_bytes = 0}, Limits{.instructions = 0}, Limits{.depth = 0}, Limits{.instructions = -5}}) {
        const std::expected<State, Failure> opened = State::open(limits);
        context.expect(!opened.has_value() && opened.error().fault == Fault::kInvalidLimits, "Limits không dương bị từ chối");
    }
    const std::expected<State, Failure> tiny = State::open(Limits{.heap_bytes = 64});
    context.expect(!tiny.has_value() && tiny.error().fault == Fault::kMemory, "trần nhỏ hơn kích thước một state: kMemory");
}

// Trần tăng dần cho tới khi dựng được: cấp phát thất bại ở mọi bước dựng state (lua_State, global_State, ngăn xếp, bảng, bảng chuỗi,
// bốn thư viện) đều thành kMemory sạch, không rò (ctest bắt dòng log "chưa trả về bộ cấp phát"), và state dựng được thì chạy được.
[[nodiscard]] bool opens_with(Context& context, std::size_t bytes) {
    std::expected<State, Failure> opened = State::open(Limits{.heap_bytes = bytes});
    if (!opened) {
        context.expect(opened.error().fault == Fault::kMemory, std::format("trần {} B: {}", bytes, opened.error().message));
        return false;
    }
    // Trần vừa đủ dựng mà không đủ chạy: lần chạy hết bộ nhớ là kMemory, state vẫn đóng sạch.
    const std::expected<void, Failure> ran = opened->run("x = 1 + 1", "=pressure");
    if (!ran) context.expect(ran.error().fault == Fault::kMemory, std::format("trần {} B, chạy: {}", bytes, ran.error().message));
    return ran.has_value();
}

void open_under_pressure(Context& context) {
    constexpr std::size_t kStep = 61;
    constexpr std::size_t kCeiling = std::size_t{256} * 1024;
    std::size_t bytes = kStep;
    while (bytes <= kCeiling && !opens_with(context, bytes)) bytes += kStep;
    context.expect(bytes <= kCeiling && bytes / kStep > 100, std::format("dựng được ở {} B sau {} lần bị từ chối", bytes, (bytes / kStep) - 1));
}

// ---- cú pháp và lỗi lúc chạy ----

void syntax_errors(Context& context) {
    State state = open_or_die(context);
    expect_failure(context, state, "x = = 1", Fault::kSyntax, "test:1:");
    expect_failure(context, state, "\x1BLua binary", Fault::kSyntax, "nhị phân");
    expect_failure(context, state, "if true then", Fault::kSyntax, "test:1:");
    context.expect(lua_gettop(state.raw()) == 0, "lỗi cú pháp không để lại gì trên ngăn xếp");
    expect_ok(context, state, "fine = 1");
}

void runtime_errors(Context& context) {
    State state = open_or_die(context);
    const std::expected<void, Failure> outcome = state.run(
        "local function inner() error('boom') end\nfunction outer() inner() end\nouter()", "=trace");
    context.expect(!outcome && outcome.error().fault == Fault::kRuntime, "error() là kRuntime");
    if (!outcome) {
        const Failure& failure = outcome.error();
        context.expect(failure.message.starts_with("trace:1: boom"), "lời lỗi mở đầu bằng vị trí và nội dung: " + failure.message);
        context.expect(has(failure, "\n\t[C]: in function `error'"), "traceback có error: " + failure.message);
        context.expect(has(failure, "\n\ttrace:2: in function `outer'"), "traceback có outer: " + failure.message);
        context.expect(has(failure, "\n\ttrace:3: in main chunk"), "traceback có main chunk: " + failure.message);
    }
    expect_failure(context, state, "error({})", Fault::kRuntime, "table");
    expect_failure(context, state, "error(nil)", Fault::kRuntime, "nil");
    expect_failure(context, state, "local a = nil + 1", Fault::kRuntime, "arithmetic");
    expect_failure(context, state, "undefined_function()", Fault::kRuntime, "undefined_function");
    context.expect(lua_gettop(state.raw()) == 0, "lỗi lúc chạy không để lại gì trên ngăn xếp");
    expect_ok(context, state, "after_errors = 1");

    // Tràn ngăn xếp gọi của script và tràn ngăn xếp C (gsub gọi lại script gọi lại gsub): LuaPlus báo lỗi thường, bộ traceback vẫn
    // chạy được ở đáy tràn và cắt chuỗi gọi ở kTraceLevels tầng.
    expect_failure(context, state, "local function f() return 1 + f() end f()", Fault::kRuntime, "stack overflow");
    expect_failure(context, state, "local function f() return (string.gsub('a', 'a', f)) end f()", Fault::kRuntime, "C stack overflow");
    expect_ok(context, state, "after_overflow = 1");
}

// ---- trần số lệnh ----

void instruction_limit(Context& context) {
    State state = open_or_die(context, Limits{.instructions = 100'000});
    const auto begin = std::chrono::steady_clock::now();
    expect_failure(context, state, "while true do end", Fault::kInstructions, "100000");
    expect_failure(context, state, "while true do pcall(function() while true do end end) end", Fault::kInstructions, "100000");
    expect_failure(context, state,
        "local co = coroutine.create(function() while true do end end)\nlocal ok = coroutine.resume(co)\nwhile true do end",
        Fault::kInstructions, "100000");
    expect_failure(context, state, "coroutine.wrap(function() while true do end end)()", Fault::kInstructions, "100000");
    expect_failure(context, state, "local function f() return f() end f()", Fault::kInstructions, "100000");
    const auto elapsed = std::chrono::steady_clock::now() - begin;
    context.expect(elapsed < std::chrono::seconds(5), "năm vòng lặp vô hạn bị cắt trong vài trăm ms, không treo");

    expect_ok(context, state, "for i = 1, 10000 do end"); // khoảng 10 000 lệnh, dưới trần
    expect_failure(context, state, "for i = 1, 1000000 do end", Fault::kInstructions, "100000");
    // Ngân sách tính lại cho từng lần gọi ngoài cùng: lần trước cạn không ảnh hưởng lần sau.
    expect_ok(context, state, "for i = 1, 10000 do end");
    expect_ok(context, state, "for i = 1, 10000 do end");

    State tight = open_or_die(context, Limits{.instructions = 5});
    expect_failure(context, tight, "local a = 1\nlocal b = 2\nlocal c = 3\nlocal d = 4\nlocal e = 5\nlocal f = 6\nlocal g = 7", Fault::kInstructions, "5 lệnh");
    expect_ok(context, tight, "local a = 1");
}

// ---- trần bộ nhớ ----

void memory_limit(Context& context) {
    State state = open_or_die(context, Limits{.heap_bytes = 2 * kMiB});
    expect_failure(context, state, "local t = {} for i = 1, 10000000 do t[i] = i end", Fault::kMemory, "memory");
    context.expect(state.heap_used() <= 2 * kMiB, "heap_used không vượt trần sau khi hết bộ nhớ");
    expect_ok(context, state, "recovered = 1"); // state còn dùng được: GC chạy và trả lại chỗ
    expect_failure(context, state, "local s = string.rep('x', 100000000)", Fault::kMemory, "memory");
    expect_ok(context, state, "recovered = 2");
    context.expect(number_global(state, "recovered") == 2.0, "script sau khi hết bộ nhớ chạy đúng");

    // Rác nhiều gấp nhiều lần trần nhưng dữ liệu sống nhỏ: GC phải dọn kịp, không báo hết bộ nhớ giả.
    State churn = open_or_die(context, Limits{.heap_bytes = 4 * kMiB, .instructions = 50'000'000});
    expect_ok(context, churn, "keep = {} for i = 1, 20000 do keep[i] = i end");
    expect_ok(context, churn, "for i = 1, 300000 do local s = 'garbage ' .. i end");
    // Dữ liệu sống chiếm nửa trần: phần rác còn lại vẫn phải được dọn trước khi chạm trần.
    expect_ok(context, churn, "for i = 20001, 40000 do keep[i] = 'value ' .. i end");
    expect_ok(context, churn, "for i = 1, 300000 do local s = 'garbage ' .. i end");
}

// ---- hàm native ----

NativeResult add_numbers(lua_State* state) {
    lua_pushnumber(state, luaL_checknumber(state, 1) + luaL_checknumber(state, 2));
    return 1;
}

NativeResult fail_with(lua_State* state) {
    const double code = luaL_checknumber(state, 1);
    return std::unexpected(NativeError::format("giá trị {} bị từ chối ({:.1f})", static_cast<int>(code), code));
}

NativeResult long_error(lua_State* /*state*/) {
    return std::unexpected(NativeError::of(std::string(1000, 'x')));
}

// Nối bốn bản của đối số 1: với chuỗi 512 KiB thì kết quả 2 MiB vượt trần, nên lua_concat hết bộ nhớ ngay trong lời gọi API của
// native và nhảy qua khung adapt.
NativeResult quadruple(lua_State* state) {
    luaL_checktype(state, 1, LUA_TSTRING);
    for (int copy = 0; copy < 4; ++copy) lua_pushvalue(state, 1);
    lua_concat(state, 4);
    return 1;
}

// Các mã Fault mà native gọi lại script đã thấy, theo thứ tự thời gian; nằm ở userdata của state.
struct Seen {
    std::vector<Fault> faults;
};

struct Relay {
    bool failed = false;
    NativeError error = NativeError::of({});
};

// Gọi hàm ở đỉnh ngăn xếp có bảo vệ; Failure (có std::string) chết trong hàm này, không sống qua lời gọi API nào của native.
Relay call_script(lua_State* state, Seen& seen) {
    const std::expected<void, Failure> outcome = lua::protected_call(state, 0, 0);
    if (outcome) return {};
    seen.faults.push_back(outcome.error().fault);
    return {.failed = true, .error = NativeError::of(outcome.error().message)};
}

NativeResult reenter(lua_State* state) {
    lua_pushvalue(state, 1);
    auto* const seen = static_cast<Seen*>(lua_getstateuserdata(state));
    const Relay relay = call_script(state, *seen);
    if (!relay.failed) return 0;
    return std::unexpected(relay.error);
}

void natives(Context& context) {
    State state = open_or_die(context, Limits{.heap_bytes = 2 * kMiB});
    context.expect(state.set_global("add", &lua::adapt<add_numbers>).has_value(), "đăng ký add");
    context.expect(state.set_global("fail_with", &lua::adapt<fail_with>).has_value(), "đăng ký fail_with");
    context.expect(state.set_global("long_error", &lua::adapt<long_error>).has_value(), "đăng ký long_error");
    context.expect(state.set_global("quadruple", &lua::adapt<quadruple>).has_value(), "đăng ký quadruple");

    expect_ok(context, state, "sum = add(2, 40)");
    context.expect(number_global(state, "sum") == 42.0, "native trả giá trị");
    expect_failure(context, state, "add('x', 1)", Fault::kRuntime, "bad argument #1 to `add'");
    expect_failure(context, state, "fail_with(7)", Fault::kRuntime, "giá trị 7 bị từ chối (7.0)");
    expect_ok(context, state, "ok, err = pcall(fail_with, 3)\nassert(not ok and string.find(err, 'giá trị 3 bị từ chối', 1, true))");

    // Lời lỗi dài bị cắt ở kCapacity byte, không tràn bộ đệm.
    const std::expected<void, Failure> cut = state.run("long_error()", "=cut");
    context.expect(!cut.has_value(), "long_error phải thất bại");
    if (!cut) {
        context.expect(has(cut.error(), std::string(NativeError::kCapacity, 'x')), "lời lỗi native giữ đủ kCapacity byte");
        context.expect(!has(cut.error(), std::string(NativeError::kCapacity + 1, 'x')), "lời lỗi native bị cắt ở kCapacity byte");
    }
    context.expect(lua_gettop(state.raw()) == 0, "native lỗi không để lại gì trên ngăn xếp");

    // Hết bộ nhớ ngay trong lời gọi API của native: nhảy qua khung adapt, pcall của script bắt được, state dùng tiếp.
    expect_ok(context, state, "big = 'x' for i = 1, 19 do big = big .. big end");
    expect_failure(context, state, "quadruple(big)", Fault::kMemory, "memory");
    expect_ok(context, state, "ok, err = pcall(quadruple, big)\nassert(not ok and string.find(err, 'memory', 1, true))");
    expect_ok(context, state, "assert(string.len(quadruple('ab')) == 8)");
    expect_ok(context, state, "still_alive = 1");
}

void depth_limit(Context& context) {
    State state = open_or_die(context, Limits{.depth = 4});
    Seen seen;
    lua_setstateuserdata(state.raw(), &seen);
    context.expect(state.set_global("reenter", &lua::adapt<reenter>).has_value(), "đăng ký reenter");
    expect_failure(context, state, "count = 0\nfunction f() count = count + 1 reenter(f) end\nf()", Fault::kRuntime,
        "quá 4 lần gọi bảo vệ lồng nhau");
    context.expect(number_global(state, "count") == 4.0, "script chạy đúng depth lần: một lần ngoài cùng và ba lần native gọi lại");
    context.expect(seen.faults == std::vector<Fault>{Fault::kDepth, Fault::kRuntime, Fault::kRuntime, Fault::kRuntime},
        "tầng sâu nhất thấy kDepth, các tầng trên thấy lỗi chạy");

    // Ba tầng nằm trong trần: chạy trọn.
    seen.faults.clear();
    expect_ok(context, state, "count = 0\nfunction k() count = count + 1 if count < 3 then reenter(k) end end\nk()");
    context.expect(number_global(state, "count") == 3.0 && seen.faults.empty(), "ba tầng nằm trong trần");
    expect_ok(context, state, "fine = 1"); // độ sâu trả về 0 sau lỗi
    lua_setstateuserdata(state.raw(), nullptr);
}

// ---- protect và host ----

void store_marker(lua_State* state, void* data) {
    lua_pushnumber(state, *static_cast<const double*>(data));
    lua_setglobal(state, "marker");
}

void raise_error(lua_State* state, void* /*data*/) { luaL_error(state, "lỗi từ thân %d", 7); }

// Nạp rồi chạy chunk (một chuỗi) bằng lua_call ngay trong thân: trần lệnh vẫn phải cắt được.
void run_chunk(lua_State* state, void* data) {
    const auto* const source = static_cast<const std::string_view*>(data);
    if (luaL_loadbuffer(state, source->data(), source->size(), "=chunk") != 0) lua_error(state);
    lua_call(state, 0, 0);
}

void read_host(lua_State* state, void* data) { *static_cast<void**>(data) = lua::host_of(state); }

struct Nest {
    int levels = 0;
    bool failed = false;
    Fault fault = Fault::kRuntime;
};

// Thân gọi lại protect chính nó cho tới khi bị từ chối; không lời gọi API nào chạy khi `inner` (có std::string) còn sống.
void nest(lua_State* state, void* data) {
    auto& progress = *static_cast<Nest*>(data);
    ++progress.levels;
    const std::expected<void, Failure> inner = lua::protect(state, &nest, data);
    if (inner || progress.failed) return;
    progress.failed = true;
    progress.fault = inner.error().fault;
}

void expect_protect_failure(Context& context, State& state, lua::ProtectedBody body, void* data, Fault fault, std::string_view part) {
    const std::expected<void, Failure> outcome = lua::protect(state.raw(), body, data);
    context.expect(!outcome.has_value(), "protect phải thất bại");
    if (!outcome) check_failure(context, outcome.error(), fault, part);
    context.expect(lua_gettop(state.raw()) == 0, "protect thất bại không để lại gì trên ngăn xếp");
}

void protect_and_host(Context& context) {
    State state = open_or_die(context, Limits{.instructions = 100'000, .depth = 3});
    int host_object = 0;
    void* seen = &state;
    context.expect(lua::protect(state.raw(), &read_host, &seen).has_value() && seen == nullptr, "chưa gắn host thì host_of là nullptr");
    state.set_host(&host_object);
    context.expect(lua::protect(state.raw(), &read_host, &seen).has_value() && seen == &host_object, "host_of thấy con trỏ đã gắn");
    lua_State* const thread = lua_newthread(state.raw());
    context.expect(lua::host_of(thread) == &host_object, "host_of cũng đúng trên coroutine");
    lua_pop(state.raw(), 1);

    double value = 42.0;
    context.expect(lua::protect(state.raw(), &store_marker, &value).has_value(), "thân chạy được");
    context.expect(number_global(state, "marker") == 42.0, "thân đặt được biến toàn cục");
    context.expect(lua_gettop(state.raw()) == 0, "protect thành công cân bằng ngăn xếp");

    expect_protect_failure(context, state, &raise_error, nullptr, Fault::kRuntime, "lỗi từ thân 7");
    std::string_view loop = "while true do end";
    expect_protect_failure(context, state, &run_chunk, &loop, Fault::kInstructions, "100000");
    std::string_view script_error = "error('từ script')";
    expect_protect_failure(context, state, &run_chunk, &script_error, Fault::kRuntime, "từ script");

    // Dùng chung bộ đếm độ sâu với protected_call: tầng thứ tư vượt depth = 3 và thấy kDepth.
    Nest nest_state;
    context.expect(lua::protect(state.raw(), &nest, &nest_state).has_value(), "thân lồng nhau tự nuốt lỗi sâu nhất");
    context.expect(nest_state.levels == 3 && nest_state.failed && nest_state.fault == Fault::kDepth, "ba tầng chạy, tầng thứ tư bị kDepth");
    expect_ok(context, state, "fine = 1"); // vẫn dùng tiếp được sau mọi thất bại
}

// ---- script thật: ProgressBar.lua của client 2026 ----

NativeResult trace_line(lua_State* state) {
    auto* const trace = static_cast<std::string*>(lua_getstateuserdata(state));
    const char* const text = luaL_checkstring(state, 1);
    trace->append(text).push_back('\n');
    return 0;
}

constexpr std::string_view kWorld = R"lua(
local function widget(name)
  local self = {}
  function self:RegisterEvent(event, flag)
    __trace(name .. ":RegisterEvent " .. event .. " " .. tostring(flag))
  end
  function self:Show() __trace(name .. ":Show") end
  function self:Hide() __trace(name .. ":Hide") end
  function self:SetText(text) __trace(name .. ":SetText " .. tostring(text)) end
  function self:SetProperty(key, value) __trace(name .. ":SetProperty " .. key .. "=" .. value) end
  function self:SetProgress(done, total) __trace(name .. ":SetProgress " .. done .. "/" .. total) end
  return self
end
this = widget("ProgressBar")
ProgressBar_Progress = widget("Progress")
function dispatch(event, value)
  arg0 = value
  ProgressBar_OnEvent(event)
end
)lua";

constexpr std::string_view kDrive = R"lua(
ProgressBar_PreLoad()
ProgressBar_OnLoad()
dispatch("PROGRESSBAR_SHOW", "Đang nạp")
dispatch("PROGRESSBAR_WIDTH", "0.5")
dispatch("PROGRESSBAR_WIDTH", nil)
dispatch("PROGRESSBAR_WIDTH", "1")
dispatch("PROGRESSBAR_BREAK")
dispatch("HIDE_ON_SCENE_TRANSED")
dispatch("PROGRESSBAR_HIDE")
dispatch("PLAYER_LEAVE_WORLD")
dispatch("UNKNOWN")
Progress_close()
)lua";

// Vết mà chính ProgressBar.lua để lại khi chạy trên LuaPlus.dll của client 2026 (D:\XTLBB\Bin64, đo 2026-10-15) với thế giới trên.
constexpr std::string_view kExpectedTrace =
    "ProgressBar:RegisterEvent PROGRESSBAR_SHOW true\n"
    "ProgressBar:RegisterEvent PROGRESSBAR_HIDE false\n"
    "ProgressBar:RegisterEvent PROGRESSBAR_WIDTH false\n"
    "ProgressBar:RegisterEvent PLAYER_LEAVE_WORLD false\n"
    "ProgressBar:RegisterEvent PROGRESSBAR_BREAK false\n"
    "ProgressBar:RegisterEvent HIDE_ON_SCENE_TRANSED false\n"
    "Progress:SetText Đang nạp\n"
    "ProgressBar:Show\n"
    "Progress:SetProperty SetFadeState=0\n"
    "Progress:SetProgress 50/100\n"
    "Progress:SetProgress 100/100\n"
    "Progress:SetProperty SetFadeState=2\n"
    "ProgressBar:Hide\n"
    "Progress:SetProperty SetFadeState=2\n"
    "Progress:SetProperty SetFadeState=2\n"
    "ProgressBar:Hide\n";

void progress_bar(Context& context) {
    if (kScriptRoot.empty()) return; // thiết bị không thấy cây nguồn của script
    const std::filesystem::path script_path =
        io::path_from_utf8(kScriptRoot) / io::path_from_utf8("Interface/ProgressBar/ProgressBar.lua");
    const io::TextResult script = io::read_text(script_path);
    context.expect(script.has_value(), "đọc được ProgressBar.lua");
    if (!script) return;

    State state = open_or_die(context);
    std::string trace;
    lua_setstateuserdata(state.raw(), &trace);
    context.expect(state.set_global("__trace", &lua::adapt<trace_line>).has_value(), "đăng ký __trace");
    expect_ok(context, state, kWorld);
    const std::expected<void, Failure> loaded = state.run(*script, "=ProgressBar");
    context.expect(loaded.has_value(), loaded ? "nạp ProgressBar.lua" : loaded.error().message);

    // Gọi PreLoad bằng C API + protected_call như nơi dùng sẽ làm: hàm toàn cục, không đối số.
    lua_getglobal(state.raw(), "ProgressBar_PreLoad");
    const std::expected<void, Failure> pre_load = state.call(0, 0);
    context.expect(pre_load.has_value(), pre_load ? "PreLoad" : pre_load.error().message);
    context.expect(lua_gettop(state.raw()) == 0, "call(0, 0) sạch ngăn xếp");
    const std::string after_pre_load = trace;
    trace.clear();

    // Phần còn lại của kịch bản; PreLoad đã chạy ở trên nên bỏ dòng đầu của kDrive.
    const std::string_view drive = kDrive.substr(kDrive.find("ProgressBar_OnLoad()"));
    expect_ok(context, state, drive);
    context.expect(after_pre_load + trace == kExpectedTrace, "vết ProgressBar khớp LuaPlus.dll gốc:\n" + after_pre_load + trace);
    lua_setstateuserdata(state.raw(), nullptr);
}

constexpr std::array<Case, 10> kCases = {{
    {.name = "dựng, chạy, move State", .body = &open_run_move},
    {.name = "Limits không dương bị từ chối", .body = &invalid_limits},
    {.name = "dựng state dưới áp lực bộ nhớ", .body = &open_under_pressure},
    {.name = "lỗi cú pháp và chunk nhị phân", .body = &syntax_errors},
    {.name = "lỗi lúc chạy có traceback, state dùng tiếp được", .body = &runtime_errors},
    {.name = "trần số lệnh cắt vòng lặp vô hạn, kể cả pcall và coroutine", .body = &instruction_limit},
    {.name = "trần bộ nhớ: hết thì báo, rác dọn kịp", .body = &memory_limit},
    {.name = "native: lỗi an toàn với longjmp, lời lỗi cắt, trần bộ nhớ trong API", .body = &natives},
    {.name = "trần độ sâu của lần gọi bảo vệ lồng nhau", .body = &depth_limit},
    {.name = "protect (thân C++ trong vùng bảo vệ) và host_of từ mọi luồng Lua", .body = &protect_and_host},
}};

constexpr std::array<Case, 1> kRealScript = {{{.name = "ProgressBar.lua của client 2026 chạy qua vỏ", .body = &progress_bar}}};

} // namespace
} // namespace game::test

int main() {
    const std::int32_t failures = game::test::run_all(game::test::kCases) + game::test::run_all(game::test::kRealScript);
    return failures == 0 ? 0 : 1;
}
