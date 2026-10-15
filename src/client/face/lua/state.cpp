#include "lua/state.hpp"

#include "core/check.hpp"
#include "core/log.hpp"
#include "lua/capi.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <expected>
#include <format>
#include <iterator>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::lua {

// Mọi thứ LuaPlus gọi lại vào vỏ (cấp phát, móc, traceback, panic) tìm Machine qua lua_getglobaluserdata, và hàm cấp phát nhận
// thẳng con trỏ Machine làm dữ liệu. Machine do State giữ bằng unique_ptr nên địa chỉ không đổi khi State bị move.
struct Machine {
    explicit Machine(const Limits& requested) noexcept
        : limits(requested)
        , soft_heap(requested.heap_bytes / kSoftHeapDivisor * kSoftHeapShare)
        , base_period(std::min(kHookPeriod, requested.instructions))
        , period(base_period) {}

    // Trên mức này (3/4 trần) móc ép LuaPlus chạy GC ở chỗ an toàn kế tiếp. LuaPlus 5.0 chỉ chạy GC khi nblocks vượt ngưỡng 2 lần
    // dữ liệu sống sau lần GC trước, nên rác chưa dọn có thể đẩy dữ liệu sống nhỏ qua trần và gây kMemory giả.
    static constexpr std::size_t kSoftHeapDivisor = 4;
    static constexpr std::size_t kSoftHeapShare = 3;
    // Số lệnh giữa hai lần móc đếm lệnh; tối thiểu phải nhỏ hơn trần để trần nhỏ vẫn cắt đúng.
    static constexpr std::int32_t kHookPeriod = 1000;

    Limits limits;
    std::size_t heap_used = 0;
    std::size_t soft_heap;
    lua_State* state = nullptr;
    int handler_ref = LUA_NOREF; // hàm traceback, neo trong registry
    int anchor_ref = LUA_NOREF;  // chuỗi lỗi của LuaPlus neo sẵn để khâu xử lý lỗi không phải cấp phát nó
    int runner_ref = LUA_NOREF;  // hàm C chạy thân của protect, neo trong registry để protect không phải cấp phát nó
    void* host = nullptr;
    std::int32_t base_period;
    std::int32_t period;
    std::int64_t consumed = 0;
    std::int32_t depth = 0;
    bool tripped = false;
};

namespace {

constexpr int kTraceLevels = 12;
constexpr std::size_t kTraceCapacity = 2048;
constexpr std::size_t kMessageCapacity = 1024;

[[nodiscard]] Machine& machine_of(lua_State* state) noexcept {
    auto* const machine = static_cast<Machine*>(lua_getglobaluserdata(state));
    core::check(machine != nullptr, "lua: lua_State không do lua::State::open dựng");
    return *machine;
}

// ---- cấp phát: trần bộ nhớ của state ----

// Chữ ký cố định bởi lua_ReallocFunction của LuaPlus (kích thước kiểu int; lmem.c đã chặn khối lớn hơn INT_MAX).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void* reallocate(void* block, int old_size, int new_size, void* data, const char* /*name*/, unsigned int /*flags*/) {
    auto& machine = *static_cast<Machine*>(data);
    const std::size_t before = block == nullptr ? 0U : static_cast<std::size_t>(old_size);
    const auto after = static_cast<std::size_t>(new_size);
    const std::size_t room = machine.limits.heap_bytes > machine.heap_used ? machine.limits.heap_bytes - machine.heap_used : 0U;
    if (after > before && after - before > room) return nullptr; // vượt trần: LuaPlus ném LUA_ERRMEM
    // LuaPlus gọi realloc rồi trả khối cho free của chính nó; giao diện này là hình dạng của realloc.
    // NOLINTNEXTLINE(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory,hicpp-no-malloc)
    void* const result = std::realloc(block, after);
    if (result == nullptr) return nullptr;
    machine.heap_used = machine.heap_used - std::min(machine.heap_used, before) + after;
    return result;
}

void release(void* block, int old_size, void* data) {
    auto& machine = *static_cast<Machine*>(data);
    machine.heap_used -= std::min(machine.heap_used, static_cast<std::size_t>(old_size));
    // NOLINTNEXTLINE(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory,hicpp-no-malloc)
    std::free(block);
}

// ---- móc đếm lệnh ----

void on_count(lua_State* state, lua_Debug* /*info*/) {
    Machine& machine = machine_of(state);
    machine.consumed += machine.period;
    if (machine.heap_used > machine.soft_heap) lua_setgcthreshold(state, 0);
    if (machine.consumed < machine.limits.instructions) return;
    if (!machine.tripped) {
        // Đã vượt trần: từ đây móc chạy sau MỖI lệnh. Script bọc vòng lặp trong pcall để nuốt lỗi móc ném ra thì lệnh kế tiếp ngoài
        // pcall (ít nhất là lệnh gọi pcall) ném lại, nên lỗi tới được vỏ.
        machine.tripped = true;
        machine.period = 1;
        lua_sethook(state, &on_count, LUA_MASKCOUNT, 1);
    }
    // Hàm này không có đối tượng nào cần destructor; luaL_error nhảy tới lua_pcall gần nhất.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg,hicpp-vararg)
    luaL_error(state, "script vượt giới hạn %d lệnh", machine.limits.instructions);
}

// Đặt lại ngân sách lệnh cho một lần gọi ngoài cùng; luôn đặt lại bộ đếm của LuaPlus để lần móc đầu cách đúng một bước.
void begin_budget(Machine& machine, lua_State* state) noexcept {
    machine.consumed = 0;
    machine.tripped = false;
    machine.period = machine.base_period;
    lua_sethook(state, &on_count, LUA_MASKCOUNT, machine.period);
}

// ---- traceback ----

// Bộ đệm ghi lời lỗi kèm traceback. Destructor tầm thường (cả khung chứa nó có thể bị longjmp bỏ qua), không cấp phát.
class TraceBuffer {
public:
    // Phần không vừa bị cắt bỏ. Không dùng std::format: đây là đường lỗi chạy trong vùng bảo vệ của LuaPlus, cần chứng minh được
    // là không ném.
    void add(std::string_view text) noexcept {
        const std::span<char> room = std::span<char>(text_).subspan(used_);
        const std::size_t count = std::min(text.size(), room.size());
        std::ranges::copy(text.substr(0, count), room.begin());
        used_ += count;
    }

    void add(int number) noexcept {
        std::array<char, kDigits> digits{};
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): to_chars nhận cặp con trỏ đầu-cuối.
        const std::to_chars_result written = std::to_chars(digits.data(), digits.data() + digits.size(), number);
        add(std::string_view(digits.data(), static_cast<std::size_t>(std::distance(digits.data(), written.ptr))));
    }

    void push(lua_State* state) const { lua_pushlstring(state, text_.data(), used_); }

private:
    static constexpr std::size_t kDigits = 12; // đủ cho int 32 bit kèm dấu

    std::array<char, kTraceCapacity> text_{};
    std::size_t used_ = 0;
};

// Hàm xử lý lỗi của lua_pcall: biến đối tượng lỗi thành chuỗi "lời lỗi + traceback" (tối đa kTraceCapacity byte). Chạy trong vùng
// bảo vệ của lua_pcall; mọi biến cục bộ ở đây có destructor tầm thường vì cấp phát hỏng cũng nhảy.
int traceback(lua_State* state) {
    TraceBuffer trace;
    const char* const message = lua_tostring(state, 1);
    if (message != nullptr) {
        trace.add(std::string_view(message).substr(0, kMessageCapacity));
    } else {
        trace.add("(đối tượng lỗi kiểu ");
        trace.add(std::string_view(lua_typename(state, lua_type(state, 1))));
        trace.add(")");
    }
    lua_Debug info{};
    int shown = 0;
    for (int level = 1; lua_getstack(state, level, &info) != 0; ++level) {
        if (shown == kTraceLevels) {
            trace.add("\n\t...");
            break;
        }
        ++shown;
        lua_getinfo(state, "Snl", &info);
        const std::string_view source(static_cast<const char*>(info.short_src));
        trace.add("\n\t");
        trace.add(source);
        if (info.currentline > 0) {
            trace.add(":");
            trace.add(info.currentline);
        }
        trace.add(": ");
        const std::string_view what(info.what != nullptr ? info.what : "?");
        if (what == "main") {
            trace.add("in main chunk");
        } else if (info.namewhat != nullptr && *info.namewhat != '\0' && info.name != nullptr) {
            trace.add("in function `");
            trace.add(std::string_view(info.name));
            trace.add("'");
        } else if (what == "C") {
            trace.add("in ?");
        } else {
            trace.add("in function <");
            trace.add(source);
            trace.add(":");
            trace.add(info.linedefined);
            trace.add(">");
        }
    }
    trace.push(state);
    return 1;
}

// ---- panic ----

// LuaPlus gọi khi một lỗi nhảy mà không có lua_pcall nào bảo vệ rồi exit. Mọi đường vào của vỏ đều trong vùng bảo vệ, nên tới đây
// là mã ngoài vỏ gọi API không bảo vệ và hết bộ nhớ hay lỗi: dừng có thông điệp thay vì để exit(1) lặng lẽ.
[[noreturn]] int on_panic(lua_State* /*state*/) {
    core::fail("lua: lỗi ngoài vùng bảo vệ của lua_pcall (gọi API Lua không bảo vệ khi hết bộ nhớ hay sai kiểu)");
}

// ---- lỗi ----

// Lấy lời lỗi từ đỉnh ngăn xếp (và gỡ nó). Vỏ bảo đảm đó là chuỗi: bộ traceback trả chuỗi, LuaPlus đặt chuỗi cho lỗi bộ nhớ, cú
// pháp và xử lý lỗi.
[[nodiscard]] std::string pop_message(lua_State* state) {
    std::string message = lua_type(state, -1) == LUA_TSTRING ? std::string(lua_tostring(state, -1), lua_strlen(state, -1))
                                                              : std::string("(không có lời lỗi)");
    lua_pop(state, 1);
    return message;
}

[[nodiscard]] Fault classify(const Machine& machine, int status, Fault otherwise) noexcept {
    if (machine.tripped) return Fault::kInstructions;
    return status == LUA_ERRMEM ? Fault::kMemory : otherwise;
}

[[nodiscard]] Failure take_failure(const Machine& machine, lua_State* state, int status, Fault otherwise) {
    const Fault fault = classify(machine, status, otherwise);
    return Failure{.fault = fault, .message = pop_message(state)};
}

// ---- protect ----

struct ProtectedRun {
    ProtectedBody body;
    void* data;
};

// Hàm C mà protect gọi qua lua_pcall: đối số 1 là con trỏ ProtectedRun nằm trên ngăn xếp của người gọi.
int run_protected(lua_State* state) {
    const auto* const run = static_cast<const ProtectedRun*>(lua_touserdata(state, 1));
    run->body(state, run->data);
    return 0;
}

// ---- dựng và đăng ký, chạy trong lua_cpcall (có bảo vệ) ----

int open_body(lua_State* state) {
    auto* const machine = static_cast<Machine*>(lua_touserdata(state, 1));
    luaopen_base(state);
    luaopen_string(state);
    luaopen_table(state);
    luaopen_math(state);
    lua_settop(state, 1);
    lua_pushcfunction(state, &traceback);
    machine->handler_ref = luaL_ref(state, LUA_REGISTRYINDEX);
    lua_pushstring(state, "error in error handling");
    machine->anchor_ref = luaL_ref(state, LUA_REGISTRYINDEX);
    lua_pushcfunction(state, &run_protected);
    machine->runner_ref = luaL_ref(state, LUA_REGISTRYINDEX);
    lua_sethook(state, &on_count, LUA_MASKCOUNT, machine->period);
    return 0;
}

struct Registration {
    const char* name;
    lua_CFunction function;
};

int register_body(lua_State* state) {
    const auto* const registration = static_cast<const Registration*>(lua_touserdata(state, 1));
    lua_pushstring(state, registration->name);
    lua_pushcclosure(state, registration->function, 0);
    lua_settable(state, LUA_GLOBALSINDEX);
    return 0;
}

} // namespace

std::expected<void, Failure> protected_call(lua_State* state, int arguments, int results) {
    Machine& machine = machine_of(state);
    core::check(arguments >= 0 && lua_gettop(state) > arguments, "lua::protected_call: thiếu hàm hoặc đối số trên ngăn xếp");
    const int function_index = lua_gettop(state) - arguments;
    if (machine.depth >= machine.limits.depth) {
        lua_settop(state, function_index - 1);
        return std::unexpected(Failure{.fault = Fault::kDepth, .message = std::format("quá {} lần gọi bảo vệ lồng nhau", machine.limits.depth)});
    }
    // Bộ xử lý lỗi nằm ngay dưới hàm: lua_pcall nhận chỉ số của nó. lua_getref, lua_insert, lua_remove không cấp phát.
    lua_rawgeti(state, LUA_REGISTRYINDEX, machine.handler_ref);
    lua_insert(state, function_index);
    const bool outermost = machine.depth == 0;
    if (outermost) begin_budget(machine, state);
    ++machine.depth;
    const int status = lua_pcall(state, arguments, results, function_index);
    --machine.depth;
    lua_remove(state, function_index);
    std::expected<void, Failure> outcome;
    if (status != 0) outcome = std::unexpected(take_failure(machine, state, status, Fault::kRuntime));
    // Lần gọi ngoài cùng xong (kể cả thất bại): trả móc về bước thường để mã chạy giữa hai lần gọi (hàm hủy __gc) không bị móc từng lệnh.
    if (outermost) begin_budget(machine, state);
    return outcome;
}

std::expected<void, Failure> protect(lua_State* state, ProtectedBody body, void* data) {
    // lua_rawgeti và lua_pushlightuserdata không cấp phát (người gọi bảo đảm LUA_MINSTACK ô trống); protected_call lo phần còn lại.
    ProtectedRun run{.body = body, .data = data};
    lua_rawgeti(state, LUA_REGISTRYINDEX, machine_of(state).runner_ref);
    lua_pushlightuserdata(state, &run);
    return protected_call(state, 1, 0);
}

void* host_of(lua_State* state) noexcept { return machine_of(state).host; }

State::State(std::unique_ptr<Machine> machine) noexcept : machine_(std::move(machine)) {}

State::State(State&& other) noexcept = default;

State& State::operator=(State&& other) noexcept {
    if (this != &other) {
        close();
        machine_ = std::move(other.machine_);
    }
    return *this;
}

State::~State() { close(); }

void State::close() noexcept {
    if (!machine_) return;
    // Hàm hủy (__gc) của script chạy trong lua_close: cho chúng một ngân sách lệnh mới thay vì phần dư của lần gọi trước.
    machine_->consumed = 0;
    machine_->tripped = false;
    lua_close(machine_->state);
    if (machine_->heap_used != 0) core::error("lua: State đóng mà còn {} byte chưa trả về bộ cấp phát", machine_->heap_used);
    machine_.reset();
}

std::expected<State, Failure> State::open(const Limits& limits) {
    if (limits.heap_bytes == 0 || limits.instructions <= 0 || limits.depth <= 0) {
        return std::unexpected(Failure{.fault = Fault::kInvalidLimits, .message = "Limits: heap_bytes, instructions, depth phải dương"});
    }
    auto machine = std::make_unique<Machine>(limits);
    lua_State* const state = lua_openwithmemory(&reallocate, &release, machine.get());
    if (state == nullptr) return std::unexpected(Failure{.fault = Fault::kMemory, .message = "không đủ bộ nhớ để dựng state"});
    machine->state = state;
    lua_setglobaluserdata(state, machine.get());
    lua_atpanic(state, &on_panic);
    State opened(std::move(machine));
    const int status = lua_cpcall(state, &open_body, opened.machine_.get());
    if (status != 0) return std::unexpected(take_failure(*opened.machine_, state, status, Fault::kMemory));
    return opened;
}

lua_State* State::raw() const noexcept {
    core::check(machine_ != nullptr, "lua::State đã bị move đi");
    return machine_->state;
}

void State::set_host(void* host) noexcept {
    core::check(machine_ != nullptr, "lua::State đã bị move đi");
    machine_->host = host;
}

std::size_t State::heap_used() const noexcept {
    core::check(machine_ != nullptr, "lua::State đã bị move đi");
    return machine_->heap_used;
}

std::expected<void, Failure> State::load(std::string_view source, const char* chunk_name) {
    constexpr char kBinarySignature = '\x1B';
    if (source.starts_with(kBinarySignature)) {
        return std::unexpected(Failure{.fault = Fault::kSyntax, .message = "chunk nhị phân không được nạp"});
    }
    lua_State* const state = raw();
    const int status = luaL_loadbuffer(state, source.data(), source.size(), chunk_name);
    if (status == 0) return {};
    return std::unexpected(take_failure(*machine_, state, status, Fault::kSyntax));
}

std::expected<void, Failure> State::run(std::string_view source, const char* chunk_name) {
    if (std::expected<void, Failure> loaded = load(source, chunk_name); !loaded) return loaded;
    return call(0, 0);
}

// NOLINTNEXTLINE(readability-make-member-function-const): chạy script đổi trạng thái Lua phía sau con trỏ thô.
std::expected<void, Failure> State::call(int arguments, int results) {
    return protected_call(raw(), arguments, results);
}

std::expected<void, Failure> State::set_global(const char* name, lua_CFunction function) {
    lua_State* const state = raw();
    Registration registration{.name = name, .function = function};
    const int status = lua_cpcall(state, &register_body, &registration);
    if (status == 0) return {};
    return std::unexpected(take_failure(*machine_, state, status, Fault::kRuntime));
}

} // namespace game::lua
