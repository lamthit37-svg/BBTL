// Thư viện cơ sở (lbaselib.c của Lua 5.0.1) với bộ tên của LuaPlus.dll trong client 2026.
//
// Port từ lbaselib.c. Khác gốc:
// - Không có trình biên dịch Lua lúc chạy: loadstring, loadfile, dofile, require trả (nil, lỗi) hay báo lỗi "not supported".
//   Script giao diện không dùng chúng (quét 2 043 tệp).
// - Không có coroutine, userdata, chuỗi rộng (towstring): các hàm có đủ tên nhưng báo "not supported", để tên toàn cục
//   khớp bộ tên của máy gốc (đo bằng pairs(_G) trên LuaPlus.dll).
// - setfenv chỉ nhận cấp 0 hoặc hàm: bảng toàn cục của State là duy nhất, nên đổi môi trường từng hàm không có nghĩa.
// - collectgarbage không làm gì (thu gom rác chỉ chạy ở collect() của chủ), gcinfo trả số KB đang dùng và 0.
// - xpcall gọi hàm xử lý lỗi SAU khi ngăn xếp gọi đã gỡ (gốc gọi tại chỗ lỗi để traceback thấy khung). Hàm xử lý tự lỗi thì
//   trả "error in error handling" ngay; gốc gọi lại nó đệ quy tới khi tràn ngăn xếp C (~200 lần) rồi mới ra cùng câu ấy.
// - print ghi ra stdout (gốc cũng vậy); tostring của bảng, hàm không in địa chỉ (xem lib_common.cpp).
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <optional>
#include <string>
#include <string_view>

namespace game::lua {
namespace {

// strtoul của MSVCR110 (unsigned long 32 bit): bỏ khoảng trắng đầu, dấu +/-, "0x" khi cơ số 16, cộng dồn bão hoà ở
// 4294967295; âm thì lấy số bù hai. consumed là 0 khi không có chữ số nào (người gọi coi như chuỗi không hợp lệ).
struct ParsedInteger {
    std::uint32_t value = 0;
    std::size_t consumed = 0;
};

[[nodiscard]] int digit_value(char letter) noexcept {
    if (letter >= '0' && letter <= '9') return letter - '0';
    if (letter >= 'a' && letter <= 'z') return letter - 'a' + 10;
    if (letter >= 'A' && letter <= 'Z') return letter - 'A' + 10;
    return 99;
}

[[nodiscard]] ParsedInteger parse_unsigned(std::string_view text, int base) noexcept {
    std::size_t at = 0;
    while (at < text.size() && (text[at] == ' ' || (text[at] >= '\t' && text[at] <= '\r')))
        ++at;
    bool negative = false;
    if (at < text.size() && (text[at] == '+' || text[at] == '-')) negative = text[at++] == '-';
    if (base == 16 && at + 2 < text.size() && text[at] == '0' && (text[at + 1] == 'x' || text[at + 1] == 'X') &&
        digit_value(text[at + 2]) < 16)
        at += 2;
    const std::size_t first_digit = at;
    std::uint64_t value = 0;
    bool saturated = false;
    while (at < text.size() && digit_value(text[at]) < base) {
        if (!saturated) {
            value = value * static_cast<std::uint64_t>(base) + static_cast<std::uint64_t>(digit_value(text[at]));
            if (value > 0xFFFFFFFFULL) saturated = true;
        }
        ++at;
    }
    if (at == first_digit) return {.value = 0, .consumed = 0};
    std::uint32_t result = saturated ? 0xFFFFFFFFU : static_cast<std::uint32_t>(value);
    if (negative) result = 0U - result;
    return {.value = result, .consumed = at};
}

[[nodiscard]] bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

Results base_tonumber(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::int32_t base = in.opt_integer(1, 10);
    if (in.failed()) return {};
    if (base == 10) {
        in.any(0);
        if (in.failed()) return {};
        const Value value = in.at(0);
        if (value.type() == Type::kNumber) return {value};
        if (value.type() == Type::kString) {
            if (const std::optional<double> number = string_to_number(value.as_string().view())) return {Value::number(*number)};
        }
        return {Value()};
    }
    const std::string_view text = in.text(0);
    if (in.failed()) return {};
    if (base < 2 || base > 36) {
        in.argument_error(1, "base out of range");
        return {};
    }
    const ParsedInteger parsed = parse_unsigned(text, base);
    if (parsed.consumed != 0) {
        std::size_t at = parsed.consumed;
        while (at < text.size() && is_space(text[at]))
            ++at;
        // Chuỗi C: dừng ở byte 0 đầu tiên.
        if (at == text.size() || text[at] == '\0') return {Value::number(static_cast<double>(parsed.value))};
    }
    return {Value()};
}

Results base_error(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::int32_t level = in.opt_integer(1, 1);
    in.any(0);
    if (in.failed()) return {};
    const Value message = in.at(0);
    const bool is_text = message.type() == Type::kString || message.type() == Type::kNumber;
    if (!is_text || level == 0) {
        state.raise(message);
        return {};
    }
    // luaL_where(level) rồi nối với thông điệp: số được đổi sang chuỗi như phép nối.
    const std::string_view text = in.text(0);
    const std::string prefix = level > 0 ? state.where(static_cast<std::size_t>(level)) : std::string();
    state.raise_text(prefix + std::string(text));
    return {};
}

// Bảng meta mà getmetatable/setmetatable thấy (lua_getmetatable của LuaPlus): bảng thì bảng meta của nó, kiểu khác thì
// bảng của kiểu.
[[nodiscard]] Table* metatable_of(State& state, Value value) {
    return value.type() == Type::kTable ? value.as_table().metatable() : state.type_table(value.type());
}

Results base_getmetatable(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    if (in.failed()) return {};
    Table* const metatable = metatable_of(state, in.at(0));
    const Value name = state.make_string("__metatable");
    if (state.failed()) return {};
    const Value protect = metatable->get(name);
    if (!protect.is_nil()) return {protect};
    return {Value(metatable)};
}

Results base_setmetatable(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    Table* const target = in.table(0);
    if (in.failed()) return {};
    const Value wanted = in.at(1);
    if (!in.present(1) || (!wanted.is_nil() && wanted.type() != Type::kTable)) {
        in.argument_error(1, "nil or table expected");
        return {};
    }
    const Value name = state.make_string("__metatable");
    if (state.failed()) return {};
    if (!target->metatable()->get(name).is_nil()) {
        state.native_error("cannot change a protected metatable");
        return {};
    }
    target->set_metatable(wanted.is_nil() ? state.default_meta() : &wanted.as_table());
    return {in.at(0)};
}

Results base_getfenv(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    if (in.at(0).type() != Type::kFunction) {
        const std::int32_t level = in.opt_integer(0, 1);
        if (level < 0) in.argument_error(0, "level must be non-negative");
        else if (static_cast<std::size_t>(level) >= state.depth()) in.argument_error(0, "invalid level");
    }
    if (in.failed()) return {};
    return {Value(&state.globals())};
}

Results base_setfenv(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    Table* const environment = in.table(1);
    if (in.failed()) return {};
    const Value target = in.at(0);
    const std::optional<double> level =
        target.type() == Type::kNumber ? std::optional<double>(target.as_number()) : std::nullopt;
    if (level && *level == 0.0) {
        state.replace_globals(*environment);
        return {};
    }
    state.native_error("`setfenv' cannot change environment of given function");
    return {};
}

Results base_next(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const Table* const table = in.table(0);
    if (in.failed()) return {};
    const Table::Advance step = table->next(in.at(1));
    if (step.step == Table::Step::kBadKey) {
        state.runtime_error("invalid key for `next'");
        return {};
    }
    if (step.step == Table::Step::kEnd) return {Value()};
    return {step.key, step.value};
}

Results base_pairs(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    static_cast<void>(in.table(0));
    if (in.failed()) return {};
    return {state.global("next"), in.at(0), Value()};
}

Results base_ipairs(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::optional<double> given = in.at(1).type() == Type::kNumber
        ? std::optional<double>(in.at(1).as_number())
        : (in.at(1).type() == Type::kString ? string_to_number(in.at(1).as_string().view()) : std::nullopt);
    const double previous = given.value_or(0.0);
    const Table* const table = in.table(0);
    if (in.failed()) return {};
    if (previous == 0.0 && !in.present(1)) return {state.global("ipairs"), in.at(0), Value::number(0.0)};
    const double next = previous + 1.0;
    const Value item = table->get_int(truncate_to_int32(next));
    if (item.is_nil()) return {};
    return {Value::number(next), item};
}

Results base_print(State& state, const Function&, Args args) {
    const Value tostring = get_global(state, state.make_string("tostring"));
    if (state.failed()) return {};
    std::string line;
    for (std::size_t i = 0; i < args.size(); ++i) {
        const std::array<Value, 1> one = {args[i]};
        const Value shown = call(state, tostring, one).first();
        if (state.failed()) return {};
        if (shown.type() != Type::kString && shown.type() != Type::kNumber) {
            state.native_error("`tostring' must return a string to `print'");
            return {};
        }
        if (i > 0) line += '\t';
        line += shown.type() == Type::kString ? std::string(shown.as_string().view()) : number_to_string(shown.as_number());
    }
    line += '\n';
    static_cast<void>(std::fwrite(line.data(), 1, line.size(), stdout));
    return {};
}

Results base_tostring(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    if (in.failed()) return {};
    return {to_display_string(state, in.at(0))};
}

Results base_type(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    if (in.failed()) return {};
    return {state.make_string(type_name(in.at(0).type()))};
}

Results base_assert(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    if (in.failed()) return {};
    if (in.at(0).truthy()) return {in.at(0)};
    const std::string_view message = in.opt_text(1, "assertion failed!");
    if (!in.failed()) state.native_error(message);
    return {};
}

Results base_unpack(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const Table* const table = in.table(0);
    if (in.failed()) return {};
    const std::int32_t count = table_length(state, *table);
    // luaL_checkstack(L, n, ..) con LUA_MAXCSTACK = 2048, tính cả các đối số đang nằm trên ngăn xếp của hàm.
    constexpr std::int32_t kStackLimit = 2048;
    if (count > kStackLimit || static_cast<std::size_t>(count) + args.size() > static_cast<std::size_t>(kStackLimit)) {
        state.native_error("stack overflow (table too big to unpack)");
        return {};
    }
    Results out;
    for (std::int32_t i = 1; i <= count; ++i)
        out.push(table->get_int(i));
    return out;
}

Results base_rawequal(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    in.any(1);
    if (in.failed()) return {};
    return {Value::boolean(raw_equal(in.at(0), in.at(1)))};
}

Results base_rawget(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const Table* const table = in.table(0);
    in.any(1);
    if (in.failed()) return {};
    return {table->get(in.at(1))};
}

Results base_rawset(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    Table* const table = in.table(0);
    in.any(1);
    in.any(2);
    if (in.failed()) return {};
    if (state.over_limit()) {
        state.raise_text("not enough memory");
        return {};
    }
    const Table::Slot slot = table->set_slot(in.at(1));
    if (slot.fault != Table::Fault::kNone) {
        state.runtime_error(slot.fault == Table::Fault::kNilKey ? "table index is nil" : "table index is NaN");
        return {};
    }
    *slot.value = in.at(2);
    return {in.at(0)};
}

Results base_pcall(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(0);
    if (in.failed()) return {};
    const Results outcome = call(state, args[0], args.subspan(1));
    if (state.failed()) return {Value::boolean(false), state.take_error()};
    Results out;
    out.push(Value::boolean(true));
    out.append(outcome);
    return out;
}

Results base_xpcall(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    in.any(1);
    if (in.failed()) return {};
    const Results outcome = call(state, args[0], {});
    if (state.failed()) {
        const std::array<Value, 1> raised = {state.take_error()};
        const Value handled = call(state, args[1], raised).first();
        if (state.failed()) {
            state.take_error();
            return {Value::boolean(false), state.make_string("error in error handling")};
        }
        return {Value::boolean(false), handled};
    }
    Results out;
    out.push(Value::boolean(true));
    out.append(outcome);
    return out;
}

Results base_collectgarbage(State& state, const Function& self, Args args) {
    // lua_setgcthreshold(L, luaL_optint(L, 1, 0)): đối số chỉ được kiểm kiểu, ngưỡng không có nghĩa ở đây.
    Arguments in(state, self, args);
    static_cast<void>(in.opt_integer(0, 0));
    return {};
}

// NOLINTNEXTLINE(misc-const-correctness): chữ ký Body cố định (State& cho mọi hàm C++).
Results base_gcinfo(State& state, const Function&, Args) {
    constexpr std::size_t kBytesPerKilobyte = 1024;
    const std::size_t kilobytes = state.used_bytes() / kBytesPerKilobyte;
    return {Value::number(static_cast<double>(kilobytes)), Value::number(0.0)};
}

Results base_loadstring(State& state, const Function&, Args) {
    return {Value(), state.make_string("loadstring: this runtime has no Lua compiler")};
}

Results base_loadfile(State& state, const Function&, Args) {
    return {Value(), state.make_string("loadfile: this runtime has no Lua compiler")};
}

Results base_dofile(State& state, const Function&, Args) {
    state.native_error("dofile: this runtime has no Lua compiler");
    return {};
}

Results base_require(State& state, const Function&, Args) {
    state.native_error("require: this runtime has no Lua compiler");
    return {};
}

Results base_unsupported(State& state, const Function& self, Args) {
    state.native_error(std::string(self.proto().name) + ": not supported by this runtime");
    return {};
}

constexpr std::array<Proto, 25> kBaseFunctions = {{
    {.body = &base_error, .name = "error"},
    {.body = &base_getmetatable, .name = "getmetatable"},
    {.body = &base_setmetatable, .name = "setmetatable"},
    {.body = &base_getfenv, .name = "getfenv"},
    {.body = &base_setfenv, .name = "setfenv"},
    {.body = &base_next, .name = "next"},
    {.body = &base_ipairs, .name = "ipairs"},
    {.body = &base_pairs, .name = "pairs"},
    {.body = &base_print, .name = "print"},
    {.body = &base_tonumber, .name = "tonumber"},
    {.body = &base_tostring, .name = "tostring"},
    {.body = &base_type, .name = "type"},
    {.body = &base_assert, .name = "assert"},
    {.body = &base_unpack, .name = "unpack"},
    {.body = &base_rawequal, .name = "rawequal"},
    {.body = &base_rawget, .name = "rawget"},
    {.body = &base_rawset, .name = "rawset"},
    {.body = &base_pcall, .name = "pcall"},
    {.body = &base_xpcall, .name = "xpcall"},
    {.body = &base_collectgarbage, .name = "collectgarbage"},
    {.body = &base_gcinfo, .name = "gcinfo"},
    {.body = &base_loadfile, .name = "loadfile"},
    {.body = &base_dofile, .name = "dofile"},
    {.body = &base_loadstring, .name = "loadstring"},
    {.body = &base_require, .name = "require"},
}};

constexpr std::array<Proto, 5> kCoroutineFunctions = {{
    {.body = &base_unsupported, .name = "create"},
    {.body = &base_unsupported, .name = "wrap"},
    {.body = &base_unsupported, .name = "resume"},
    {.body = &base_unsupported, .name = "yield"},
    {.body = &base_unsupported, .name = "status"},
}};

constexpr Proto kNewProxy = {.body = &base_unsupported, .name = "newproxy"};
constexpr Proto kToWideString = {.body = &base_unsupported, .name = "towstring"};

} // namespace

void open_base(State& state) {
    // base_open của lbaselib.c: hàm vào bảng toàn cục, rồi _VERSION, newproxy, _G; luaopen_base thêm coroutine và _LOADED.
    register_functions(state, state.globals(), kBaseFunctions);
    state.set_global("_VERSION", state.make_string("Lua 5.0.1"));
    state.set_global("newproxy", state.make_native(kNewProxy));
    state.set_global("towstring", state.make_native(kToWideString));
    state.set_global("_G", Value(&state.globals()));
    static_cast<void>(open_library(state, "coroutine", kCoroutineFunctions));
    Table* const loaded = state.make_table(0, 0);
    if (loaded != nullptr) state.set_global("_LOADED", Value(loaded));
}

} // namespace game::lua
