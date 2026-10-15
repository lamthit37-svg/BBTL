// Runtime Lua (src/client/face/lua) so với chính LuaPlus.dll của client 2026.
//
// lib_cases.tsv (Test/golden/lua, sinh bằng TOOLS/port/lua_rt_golden.py) gồm hai nhóm ca, mỗi dòng là đường dẫn, đối số và
// kết quả mà DLL trả (cả câu lỗi, trạng thái các đối số sau lời gọi, vết của hàm gọi lại):
// - lời gọi thư viện chuẩn (base, string, table, math) và thứ tự duyệt của mọi bảng thư viện;
// - phép toán của máy ảo (vm.hpp): số học và ép chuỗi, `^` XOR, nối chuỗi, so sánh, metamethod, index/set trên mọi kiểu, call,
//   vòng for số, vararg, hàm dựng bảng. Bên DLL mỗi ca là một hàm Lua nhỏ (`function(a, b) return a + b end`); bên này là mã
//   C++ dựng tay đúng như bộ dịch sinh cho hàm ấy (op_*).
// Mọi ca chạy trong CÙNG MỘT State theo đúng thứ tự dòng (hạt math.random và đối tượng của setup_ops là trạng thái chung) và
// so từng ký tự, trừ chữ số thứ 17 của hàm toán lấy từ thư viện của máy (xem tolerates_one_ulp).
#include "lua/cformat.hpp"
#include "lua/host.hpp"
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/table.hpp"
#include "lua/vm.hpp"

#include "core/check.hpp"
#include "io/file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <format>
#include <limits>
#include <map>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace game::test {
namespace {

#ifdef GAME_LUA_GOLDEN
constexpr std::string_view kGoldenFolder = GAME_LUA_GOLDEN;
#else
constexpr std::string_view kGoldenFolder;
#endif

using game::lua::add;
using game::lua::Args;
using game::lua::Body;
using game::lua::call;
using game::lua::concat;
using game::lua::div;
using game::lua::equal;
using game::lua::for_next;
using game::lua::format_double;
using game::lua::FormatSpec;
using game::lua::Function;
using game::lua::get_global;
using game::lua::host;
using game::lua::Host;
using game::lua::index;
using game::lua::less;
using game::lua::less_equal;
using game::lua::Limits;
using game::lua::mul;
using game::lua::native;
using game::lua::new_state;
using game::lua::new_table;
using game::lua::number_to_string;
using game::lua::open_standard;
using game::lua::pow;
using game::lua::protected_call;
using game::lua::Proto;
using game::lua::put_global;
using game::lua::raise_error;
using game::lua::raw_equal;
using game::lua::Results;
using game::lua::set_host;
using game::lua::set_index;
using game::lua::set_list;
using game::lua::set_metatable;
using game::lua::State;
using game::lua::StatePtr;
using game::lua::sub;
using game::lua::Table;
using game::lua::to_display_string;
using game::lua::Type;
using game::lua::unm;
using game::lua::Value;
using game::lua::vararg_table;

// Ngữ cảnh chủ của các hàm gọi lại: vết mà @rec và các hàm note của setup_ops ghi.
class Fixture final : public Host {
public:
    std::vector<std::string> log;
};

// ---- định dạng kết quả, giống từng ký tự với prelude của lua_rt_golden.py ----

[[nodiscard]] bool printable(char letter) noexcept {
    const auto byte = static_cast<unsigned char>(letter);
    return byte >= 0x20 && byte <= 0x7E && letter != '"' && letter != '\\';
}

[[nodiscard]] std::string escaped(std::string_view bytes) {
    std::string out;
    for (const char letter : bytes) {
        if (printable(letter)) out.push_back(letter);
        else out += std::format("\\x{:02X}", static_cast<unsigned>(static_cast<unsigned char>(letter)));
    }
    return out;
}

class Dumper {
public:
    // dump và dump_table gọi nhau theo độ lồng của bảng đang in; dữ liệu thử là bảng nông và có kiểm vòng (seen_).
    // NOLINTBEGIN(misc-no-recursion)
    [[nodiscard]] std::string dump(Value value) {
        switch (value.type()) {
        case Type::kNil: return "nil";
        case Type::kBoolean: return value.as_boolean() ? "true" : "false";
        case Type::kNumber:
            return "n:" + number_to_string(value.as_number()) + "~" + format_double('g', FormatSpec{.precision = 17}, value.as_number());
        case Type::kString: return "s:\"" + escaped(value.as_string().view()) + "\"";
        case Type::kFunction: return "fn";
        case Type::kTable: return dump_table(value.as_table());
        }
        return "?";
    }

private:
    [[nodiscard]] std::string dump_table(const Table& table) {
        if (const auto found = seen_.find(&table); found != seen_.end()) return "#" + std::to_string(found->second);
        seen_.emplace(&table, seen_.size() + 1);
        std::string out = "{";
        bool first = true;
        Value key;
        for (;;) {
            const Table::Advance step = table.next(key);
            if (step.step != Table::Step::kFound) break;
            if (!first) out += ';';
            first = false;
            out += dump(step.key) + "=" + dump(step.value);
            key = step.key;
        }
        return out + "}";
    }
    // NOLINTEND(misc-no-recursion)

    std::map<const Table*, std::size_t> seen_;
};

[[nodiscard]] std::string dump_all(std::span<const Value> values) {
    std::string out;
    for (std::size_t i = 0; i < values.size(); ++i) {
        if (i > 0) out += ',';
        Dumper dumper;
        out += dumper.dump(values[i]);
    }
    return out;
}

// strip của prelude: bỏ mọi "golden:<dòng>: " (vị trí của đoạn mã thử bên DLL) khỏi câu lỗi. Bỏ ở mọi chỗ chứ không chỉ đầu
// câu vì vài câu lỗi của LuaPlus nối thêm một giá trị đứng trước vị trí (xem Matcher::malformed_end trong lib_string.cpp).
[[nodiscard]] std::string strip_position(std::string message) {
    constexpr std::string_view kChunk = "golden:";
    for (std::size_t at = message.find(kChunk); at != std::string::npos; at = message.find(kChunk, at)) {
        std::size_t digits = at + kChunk.size();
        while (digits < message.size() && message[digits] >= '0' && message[digits] <= '9')
            ++digits;
        if (digits > at + kChunk.size() && message.compare(digits, 2, ": ") == 0) message.erase(at, digits + 2 - at);
        else ++at;
    }
    return message;
}

// ---- hàm gọi lại (cùng nghĩa với F.* của prelude) ----

Fixture& fixture_of(const State& state) {
    auto* const fixture = dynamic_cast<Fixture*>(host(state));
    core::check(fixture != nullptr, "fixture_of: chủ của State không phải Fixture");
    return *fixture;
}

// Đối số thứ index, nil khi thiếu: cách Lua điều chỉnh số đối số về số tham số của hàm.
[[nodiscard]] Value arg_or_nil(Args args, std::size_t index_of) {
    return index_of < args.size() ? args[index_of] : Value();
}

Results cb_id(State&, const Function&, Args args) {
    Results out;
    out.append(args);
    return out;
}
Results cb_lt(State& state, const Function&, Args args) {
    return {Value::boolean(less(state, arg_or_nil(args, 0), arg_or_nil(args, 1)))};
}
Results cb_gt(State& state, const Function&, Args args) {
    return {Value::boolean(less(state, arg_or_nil(args, 1), arg_or_nil(args, 0)))};
}
Results cb_le(State& state, const Function&, Args args) {
    return {Value::boolean(less_equal(state, arg_or_nil(args, 0), arg_or_nil(args, 1)))};
}
Results cb_always(State&, const Function&, Args) {
    return {Value::boolean(true)};
}
Results cb_never(State&, const Function&, Args) {
    return {Value::boolean(false)};
}
Results cb_bylen(State&, const Function&, Args args) {
    const auto length = [&](std::size_t at) {
        const Value value = arg_or_nil(args, at);
        return value.type() == Type::kString ? value.as_string().size() : 0U;
    };
    return {Value::boolean(length(0) < length(1))};
}
Results cb_err(State& state, const Function&, Args) {
    state.raise_text("boom");
    return {};
}
Results cb_nilret(State&, const Function&, Args) {
    return {Value()};
}
Results cb_numret(State&, const Function&, Args) {
    return {Value::number(42.0)};
}
Results cb_tabret(State& state, const Function&, Args) {
    return {Value(state.make_table(0, 0))};
}
Results cb_upper(State& state, const Function&, Args args) {
    const Value library = get_global(state, state.make_string("string"));
    const Value upper = index(state, library, state.make_string("upper"));
    const std::array<Value, 1> first = {arg_or_nil(args, 0)};
    return call(state, upper, first);
}
Results cb_wrap(State& state, const Function&, Args args) {
    std::string out = "<";
    const auto text = [](Value value) { return value.type() == Type::kString ? std::string(value.as_string().view()) : number_to_string(value.as_number()); };
    out += text(arg_or_nil(args, 0));
    if (args.size() > 1 && args[1].truthy()) out += "," + text(args[1]);
    return {state.make_string(out + ">")};
}
Results cb_rec(State& state, const Function&, Args args) {
    fixture_of(state).log.push_back(dump_all(args));
    return {};
}
Results cb_rec_stop(State& state, const Function&, Args args) {
    fixture_of(state).log.push_back(dump_all(args));
    const Value three = Value::number(3.0);
    if (raw_equal(arg_or_nil(args, 0), three) || raw_equal(arg_or_nil(args, 1), three)) return {state.make_string("stop")};
    return {};
}
// gfind_all: mỗi lần lặp thành một bảng {1=a, 2=b, 3=c, 4=d, n=số kết quả}.
Results cb_gfind_all(State& state, const Function&, Args args) {
    const Value library = get_global(state, state.make_string("string"));
    const Value gfind = index(state, library, state.make_string("gfind"));
    const Value iterator = call(state, gfind, args).first();
    if (state.failed()) return {};
    Table* const out = state.make_table(0, 0);
    std::int32_t count = 0;
    for (;;) {
        const Results step = call(state, iterator, {});
        if (state.failed()) return {};
        if (step.size() == 0) break;
        Table* const item = state.make_table(0, 0);
        for (std::int32_t i = 1; i <= 4; ++i)
            *item->set_slot_int(i) = step.at_or_nil(static_cast<std::size_t>(i - 1));
        *item->set_slot(state.make_string("n")).value = Value::number(static_cast<double>(step.size()));
        *out->set_slot_int(++count) = Value(item);
    }
    return {Value(out)};
}
Results cb_emit(State&, const Function&, Args) {
    return {};
}

// ---- phép toán của máy ảo: mã C++ dựng tay như bộ dịch sinh cho F.op_* của prelude ----

// Mỗi toán tử trả giá trị hay boolean; cờ lỗi của State là nơi báo lỗi, nên sau mỗi op hỏi failed() rồi trả về, đúng như mã sinh.
Results op_add(State& state, const Function&, Args args) {
    const Value result = add(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_sub(State& state, const Function&, Args args) {
    const Value result = sub(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_mul(State& state, const Function&, Args args) {
    const Value result = mul(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_div(State& state, const Function&, Args args) {
    const Value result = div(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_pow(State& state, const Function&, Args args) {
    const Value result = pow(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_unm(State& state, const Function&, Args args) {
    const Value result = unm(state, arg_or_nil(args, 0));
    return state.failed() ? Results() : Results{result};
}
Results op_concat(State& state, const Function&, Args args) {
    const std::array<Value, 2> parts = {arg_or_nil(args, 0), arg_or_nil(args, 1)};
    const Value result = concat(state, parts);
    return state.failed() ? Results() : Results{result};
}
Results op_concat3(State& state, const Function&, Args args) {
    const std::array<Value, 3> parts = {arg_or_nil(args, 0), arg_or_nil(args, 1), arg_or_nil(args, 2)};
    const Value result = concat(state, parts);
    return state.failed() ? Results() : Results{result};
}
Results op_eq(State& state, const Function&, Args args) {
    const bool result = equal(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{Value::boolean(result)};
}
Results op_ne(State& state, const Function&, Args args) {
    const bool result = equal(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{Value::boolean(!result)};
}
Results op_lt(State& state, const Function&, Args args) {
    const bool result = less(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{Value::boolean(result)};
}
Results op_le(State& state, const Function&, Args args) {
    const bool result = less_equal(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{Value::boolean(result)};
}
// `a > b` là less(b, a), `a >= b` là less_equal(b, a) (lcode.c 5.0 đổi chỗ toán hạng).
Results op_gt(State& state, const Function&, Args args) {
    const bool result = less(state, arg_or_nil(args, 1), arg_or_nil(args, 0));
    return state.failed() ? Results() : Results{Value::boolean(result)};
}
Results op_ge(State& state, const Function&, Args args) {
    const bool result = less_equal(state, arg_or_nil(args, 1), arg_or_nil(args, 0));
    return state.failed() ? Results() : Results{Value::boolean(result)};
}
Results op_index(State& state, const Function&, Args args) {
    const Value result = index(state, arg_or_nil(args, 0), arg_or_nil(args, 1));
    return state.failed() ? Results() : Results{result};
}
Results op_setget(State& state, const Function&, Args args) {
    const Value object = arg_or_nil(args, 0);
    const Value key = arg_or_nil(args, 1);
    set_index(state, object, key, arg_or_nil(args, 2));
    if (state.failed()) return {};
    const Value result = index(state, object, key);
    return state.failed() ? Results() : Results{result};
}
Results op_call(State& state, const Function&, Args args) {
    Results result = call(state, arg_or_nil(args, 0), args.empty() ? args : args.subspan(1));
    return state.failed() ? Results() : result;
}
Results op_vararg(State& state, const Function&, Args args) {
    const Value result = vararg_table(state, args);
    return state.failed() ? Results() : Results{result};
}

// Vòng `for i = a, b[, c]` như bộ dịch phát: index = sub(init, step) rồi for_next mỗi vòng; thân vòng ghi i vào r[n] và dừng ở 12.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): init, limit, step theo thứ tự của `for`.
Results run_numeric_for(State& state, Value init, Value limit, Value step) {
    Value counter = sub(state, init, step);
    if (state.failed()) return {};
    const Value result = new_table(state, 0, 0);
    if (state.failed()) return {};
    std::int32_t stored = 0;
    while (for_next(state, counter, limit, step)) {
        *result.as_table().set_slot_int(++stored) = counter;
        if (stored >= 12) break;
    }
    return state.failed() ? Results() : Results{result};
}
Results op_for2(State& state, const Function&, Args args) {
    return run_numeric_for(state, arg_or_nil(args, 0), arg_or_nil(args, 1), Value::number(1.0));
}
Results op_for3(State& state, const Function&, Args args) {
    return run_numeric_for(state, arg_or_nil(args, 0), arg_or_nil(args, 1), arg_or_nil(args, 2));
}

// Hàm dựng bảng `{...}`: args là cặp (khoá, giá trị), khoá nil là mục danh sách. new_table(số mục danh sách, số mục `Tên = giá trị`):
// khoá chuỗi hợp lệ làm tên là mục `Tên =`, mọi khoá khác (số, chuỗi không phải tên) viết `[khoá] =` nên không tính, đúng
// recfield của lparser.c. Mục có khoá gán ngay khi gặp, mục danh sách xả bằng set_list theo lô 32 ở chỗ closelistfield và
// lastlistfield.
[[nodiscard]] bool is_name(Value key) {
    if (key.type() != Type::kString) return false;
    const std::string_view text = key.as_string().view();
    const auto is_letter = [](char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'; };
    return !text.empty() && is_letter(text.front()) &&
           std::ranges::all_of(text, [&](char c) { return is_letter(c) || (c >= '0' && c <= '9'); });
}

Results op_ctor(State& state, const Function&, Args args) {
    constexpr std::size_t kFlushSize = 32;
    std::size_t list_items = 0;
    std::size_t record_items = 0;
    for (std::size_t i = 0; i + 1 < args.size(); i += 2) {
        if (args[i].is_nil()) ++list_items;
        else if (is_name(args[i])) ++record_items;
    }
    const Value table = new_table(state, list_items, record_items);
    if (state.failed()) return {};
    std::vector<Value> pending;
    std::size_t flushed = 0;
    for (std::size_t i = 0; i + 1 < args.size(); i += 2) {
        if (pending.size() == kFlushSize) {
            set_list(state, table, flushed + 1, pending);
            flushed += pending.size();
            pending.clear();
        }
        if (args[i].is_nil()) pending.push_back(args[i + 1]);
        else set_index(state, table, args[i], args[i + 1]);
        if (state.failed()) return {};
    }
    if (!pending.empty()) set_list(state, table, flushed + 1, pending);
    return state.failed() ? Results() : Results{table};
}

// Hàm metamethod mẫu: ghi "<tên>:<đối số>" vào vết và trả đúng chuỗi đó (F.note của prelude).
Results op_note(State& state, const Function& self, Args args) {
    const std::string text = std::string(self.upvalue(0).value.as_string().view()) + ":" + dump_all(args);
    fixture_of(state).log.push_back(text);
    return {state.make_string(text)};
}
constexpr Proto kNote = {.body = &op_note, .name = "note", .upvalues = 1};

// __index của fn_index: "fi:" .. tostring(k).
Results op_function_index(State& state, const Function&, Args args) {
    const Value shown = to_display_string(state, arg_or_nil(args, 1));
    if (state.failed()) return {};
    return {state.make_string("fi:" + std::string(shown.as_string().view()))};
}

[[nodiscard]] Table* make_event_metatable(State& state) {
    static constexpr std::array<std::string_view, 13> kEvents = {
        "add", "sub", "mul", "div", "pow", "unm", "concat", "lt", "le", "eq", "index", "newindex", "call"};
    Table* const metatable = state.make_table(0, 0);
    for (const std::string_view event : kEvents) {
        const std::array<Value, 1> upvalues = {state.make_string(event)};
        *metatable->set_slot(state.make_string("__" + std::string(event))).value = state.make_native_closure(kNote, upvalues);
    }
    return metatable;
}

[[nodiscard]] Table* make_object(State& state, Table* metatable) {
    Table* const object = state.make_table(0, 0);
    object->set_metatable(metatable);
    return object;
}

// setup_ops: các đối tượng toàn cục mà ca phép toán dùng ($obj ...). Dựng đúng như F.setup_ops của prelude.
Results op_setup(State& state, const Function&, Args) {
    Table* const shared = make_event_metatable(state);
    Table* const separate = make_event_metatable(state);
    put_global(state, "obj", Value(make_object(state, shared)));
    put_global(state, "obj_b", Value(make_object(state, shared)));
    put_global(state, "other", Value(make_object(state, separate)));
    put_global(state, "plain", Value(state.make_table(0, 0)));
    Table* const base = state.make_table(0, 0);
    *base->set_slot(state.make_string("x")).value = Value::number(1.0);
    *base->set_slot(state.make_string("y")).value = Value::number(2.0);
    put_global(state, "base_t", Value(base));
    const auto make_forwarding = [&state](Table* target) {
        Table* const metatable = state.make_table(0, 2);
        *metatable->set_slot(state.make_string("__index")).value = Value(target);
        *metatable->set_slot(state.make_string("__newindex")).value = Value(target);
        return metatable;
    };
    put_global(state, "via_table", Value(make_object(state, make_forwarding(base))));
    Table* const loop = state.make_table(0, 0);
    loop->set_metatable(make_forwarding(loop));
    put_global(state, "loop_t", Value(loop));
    static constexpr Proto kFunctionIndex = {.body = &op_function_index, .name = "function_index"};
    Table* const by_function = state.make_table(0, 1);
    *by_function->set_slot(state.make_string("__index")).value = state.make_native(kFunctionIndex);
    put_global(state, "fn_index", Value(make_object(state, by_function)));
    return {};
}

constexpr std::array<Proto, 15> kCallbacks = {{
    {.body = &cb_id, .name = "id"},
    {.body = &cb_lt, .name = "lt"},
    {.body = &cb_gt, .name = "gt"},
    {.body = &cb_le, .name = "le"},
    {.body = &cb_always, .name = "always"},
    {.body = &cb_never, .name = "never"},
    {.body = &cb_bylen, .name = "bylen"},
    {.body = &cb_err, .name = "err"},
    {.body = &cb_nilret, .name = "nilret"},
    {.body = &cb_numret, .name = "numret"},
    {.body = &cb_tabret, .name = "tabret"},
    {.body = &cb_upper, .name = "upper"},
    {.body = &cb_wrap, .name = "wrap"},
    {.body = &cb_rec, .name = "rec"},
    {.body = &cb_rec_stop, .name = "rec_stop"},
}};

// Các hàm gọi được bằng đường dẫn trong tệp số vàng ngoài thư viện chuẩn.
constexpr std::array<Proto, 24> kHelpers = {{
    {.body = &cb_gfind_all, .name = "gfind_all"},
    {.body = &op_setup, .name = "setup_ops"},
    {.body = &op_add, .name = "op.add"},
    {.body = &op_sub, .name = "op.sub"},
    {.body = &op_mul, .name = "op.mul"},
    {.body = &op_div, .name = "op.div"},
    {.body = &op_pow, .name = "op.pow"},
    {.body = &op_unm, .name = "op.unm"},
    {.body = &op_concat, .name = "op.concat"},
    {.body = &op_concat3, .name = "op.concat3"},
    {.body = &op_eq, .name = "op.eq"},
    {.body = &op_ne, .name = "op.ne"},
    {.body = &op_lt, .name = "op.lt"},
    {.body = &op_le, .name = "op.le"},
    {.body = &op_gt, .name = "op.gt"},
    {.body = &op_ge, .name = "op.ge"},
    {.body = &op_index, .name = "op.index"},
    {.body = &op_setget, .name = "op.setget"},
    {.body = &op_call, .name = "op.call"},
    {.body = &op_vararg, .name = "op.vararg"},
    {.body = &op_for2, .name = "op.for2"},
    {.body = &op_for3, .name = "op.for3"},
    {.body = &op_ctor, .name = "op.ctor"},
    {.body = &cb_emit, .name = "__emit"},
}};

[[nodiscard]] const Proto& helper(std::string_view name) {
    const auto found = std::ranges::find(kHelpers, name, &Proto::name);
    core::check(found != kHelpers.end(), "helper: không có hàm trợ giúp này");
    return *found;
}

// ---- đọc đối số ----

// Hàm gọi lại là MỘT giá trị mỗi tên trong một State, như F.id của prelude: hai lần viết @id là cùng một hàm (op.eq phân biệt).
using CallbackValues = std::map<std::string_view, Value>;

class ArgumentReader {
public:
    ArgumentReader(State& state, CallbackValues& callbacks, std::string_view text) : state_(&state), callbacks_(&callbacks), text_(text) {}

    [[nodiscard]] bool done() {
        skip_spaces();
        return at_ >= text_.size();
    }

    // value và table gọi nhau theo độ lồng của bảng trong dòng thử; dòng hữu hạn nên đệ quy hữu hạn.
    // NOLINTBEGIN(misc-no-recursion)
    [[nodiscard]] std::optional<Value> value() {
        skip_spaces();
        if (at_ >= text_.size()) return std::nullopt;
        const char first = text_[at_];
        if (first == '{') return table();
        if (first == 's' && text_.substr(at_, 3) == "s:\"") return string_value();
        const std::string_view word = take_word();
        if (word == "nil") return Value();
        if (word == "true") return Value::boolean(true);
        if (word == "false") return Value::boolean(false);
        if (word.starts_with("n:")) return number(word.substr(2));
        if (word.starts_with('@')) return callback(word.substr(1));
        if (word.starts_with('$')) return get_global(*state_, state_->make_string(word.substr(1)));
        return std::nullopt;
    }

private:
    void skip_spaces() {
        while (at_ < text_.size() && text_[at_] == ' ')
            ++at_;
    }
    [[nodiscard]] std::string_view take_word() {
        const std::size_t begin = at_;
        while (at_ < text_.size() && text_[at_] != ' ')
            ++at_;
        return text_.substr(begin, at_ - begin);
    }
    [[nodiscard]] static std::optional<Value> number(std::string_view word) {
        if (word == "inf") return Value::number(std::numeric_limits<double>::infinity());
        if (word == "-inf") return Value::number(-std::numeric_limits<double>::infinity());
        if (word == "nan") return Value::number(-std::numeric_limits<double>::quiet_NaN());
        const std::string owned(word);
        return Value::number(std::strtod(owned.c_str(), nullptr));
    }
    [[nodiscard]] std::optional<Value> string_value() {
        at_ += 3;
        std::string bytes;
        while (at_ < text_.size() && text_[at_] != '"') {
            if (text_[at_] == '\\' && at_ + 3 < text_.size() && text_[at_ + 1] == 'x') {
                bytes.push_back(static_cast<char>(std::strtol(std::string(text_.substr(at_ + 2, 2)).c_str(), nullptr, 16)));
                at_ += 4;
            } else {
                bytes.push_back(text_[at_++]);
            }
        }
        if (at_ >= text_.size()) return std::nullopt;
        ++at_;
        return state_->make_string(bytes);
    }
    [[nodiscard]] std::optional<Value> callback(std::string_view name) const {
        if (const auto cached = callbacks_->find(name); cached != callbacks_->end()) return cached->second;
        const auto found = std::ranges::find(kCallbacks, name, &Proto::name);
        if (found == kCallbacks.end()) return std::nullopt;
        const Value made = state_->make_native(*found);
        callbacks_->emplace(found->name, made);
        return made;
    }
    [[nodiscard]] std::optional<Value> table() {
        ++at_;
        Table* const made = state_->make_table(0, 0);
        for (;;) {
            skip_spaces();
            if (at_ < text_.size() && text_[at_] == '}') {
                ++at_;
                return Value(made);
            }
            const std::optional<Value> key = value();
            const std::optional<Value> item = value();
            if (!key || !item) return std::nullopt;
            const Table::Slot slot = made->set_slot(*key);
            if (slot.fault != Table::Fault::kNone) return std::nullopt;
            *slot.value = *item;
        }
    }
    // NOLINTEND(misc-no-recursion)

    State* state_;
    CallbackValues* callbacks_;
    std::string_view text_;
    std::size_t at_ = 0;
};

// ---- chạy một ca ----

struct Runtime {
    Fixture fixture;
    StatePtr state;
    CallbackValues callbacks;

    Runtime() : state(new_state(Limits{})) {
        open_standard(*state);
        // Máy của trọng tài đăng ký __emit sau khi mở thư viện (lua_oracle.Machine): thứ tự duyệt _G có phần của nó.
        put_global(*state, "__emit", native(*state, helper("__emit")));
        set_host(*state, &fixture);
    }
};

[[nodiscard]] std::optional<Value> resolve(State& state, std::string_view path) {
    if (path == "id") return state.make_native(kCallbacks.front());
    if (path == "gfind_all" || path == "setup_ops" || path.starts_with("op.")) return state.make_native(helper(path));
    std::size_t begin = 0;
    Value current;
    bool first = true;
    while (begin <= path.size()) {
        const std::size_t dot = std::min(path.find('.', begin), path.size());
        const Value name = state.make_string(path.substr(begin, dot - begin));
        current = first ? get_global(state, name) : index(state, current, name);
        first = false;
        begin = dot + 1;
    }
    if (state.failed()) return std::nullopt;
    return current;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): đường dẫn hàm rồi đối số, đúng thứ tự các cột của dòng thử.
[[nodiscard]] std::string run_case(Runtime& runtime, std::string_view path, std::string_view argument_text) {
    State& state = *runtime.state;
    const std::optional<Value> callee = resolve(state, path);
    if (!callee) return "!không tìm được hàm " + std::string(path);
    std::vector<Value> args;
    ArgumentReader reader(state, runtime.callbacks, argument_text);
    while (!reader.done()) {
        const std::optional<Value> one = reader.value();
        if (!one) return "!không đọc được đối số";
        args.push_back(*one);
    }
    const Results out = call(state, *callee, args);
    std::string text;
    if (state.failed()) {
        const Value error = state.take_error();
        Dumper dumper;
        text = "error:" + dumper.dump(error.type() == Type::kString ? state.make_string(strip_position(std::string(error.as_string().view()))) : error);
    } else {
        text = "(" + dump_all(out.values()) + ")";
    }
    std::string log;
    for (std::size_t i = 0; i < runtime.fixture.log.size(); ++i) {
        if (i > 0) log += ';';
        log += runtime.fixture.log[i];
    }
    runtime.fixture.log.clear();
    return text + " | [" + dump_all(args) + "] | [" + log + "]";
}

[[nodiscard]] std::vector<std::string_view> split_tabs(std::string_view line) {
    std::vector<std::string_view> cells;
    std::size_t begin = 0;
    for (;;) {
        const std::size_t tab = line.find('\t', begin);
        if (tab == std::string_view::npos) {
            cells.push_back(line.substr(begin));
            return cells;
        }
        cells.push_back(line.substr(begin, tab - begin));
        begin = tab + 1;
    }
}

// ---- so kết quả ----

// Hàm toán lấy từ thư viện toán của máy dựng (lib_math.cpp): giá trị `%.17g` sau dấu `~` được lệch DLL tối đa một ulp, còn
// chuỗi tostring (14 chữ số) phải khớp từng ký tự.
[[nodiscard]] bool tolerates_one_ulp(std::string_view id) {
    static constexpr std::array<std::string_view, 11> kNames = {
        "math.sin#", "math.cos#", "math.tan#", "math.asin#", "math.acos#", "math.atan#", "math.atan2#", "math.exp#", "math.log#",
        "math.log10#", "math.pow#"};
    return std::ranges::any_of(kNames, [&](std::string_view name) { return id.starts_with(name); });
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai chuỗi số cùng vai, thứ tự không có nghĩa (so đối xứng).
[[nodiscard]] bool within_one_ulp(std::string_view want, std::string_view got) {
    double a = 0.0;
    double b = 0.0;
    const char* const want_end = std::to_address(want.end());
    const char* const got_end = std::to_address(got.end());
    const auto [pa, ea] = std::from_chars(std::to_address(want.begin()), want_end, a);
    const auto [pb, eb] = std::from_chars(std::to_address(got.begin()), got_end, b);
    if (ea != std::errc() || eb != std::errc() || pa != want_end || pb != got_end) return false;
    if (std::signbit(a) != std::signbit(b)) return a == b;
    const auto bits_a = std::bit_cast<std::int64_t>(a);
    const auto bits_b = std::bit_cast<std::int64_t>(b);
    const std::int64_t gap = bits_a > bits_b ? bits_a - bits_b : bits_b - bits_a;
    return gap <= 1;
}

// Hai dòng kết quả giống nhau, trừ các số sau dấu `~` (dấu `~` nằm trong chuỗi ngoặc kép không tính).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai dòng cùng vai.
[[nodiscard]] bool equal_up_to_ulp(std::string_view want, std::string_view got) {
    constexpr std::string_view kEnd = ",)]};=| ";
    std::size_t i = 0;
    std::size_t j = 0;
    bool quoted = false;
    while (i < want.size() && j < got.size()) {
        if (want[i] != got[j]) return false;
        const char letter = want[i];
        ++i;
        ++j;
        if (letter == '"') quoted = !quoted;
        if (letter != '~' || quoted) continue;
        const std::size_t stop_a = std::min(want.find_first_of(kEnd, i), want.size());
        const std::size_t stop_b = std::min(got.find_first_of(kEnd, j), got.size());
        const std::string_view token_a = want.substr(i, stop_a - i);
        const std::string_view token_b = got.substr(j, stop_b - j);
        if (token_a != token_b && !within_one_ulp(token_a, token_b)) return false;
        i = stop_a;
        j = stop_b;
    }
    return i == want.size() && j == got.size();
}

[[nodiscard]] std::string globals_order(State& state) {
    std::string keys;
    Value key;
    for (;;) {
        const Table::Advance step = state.globals().next(key);
        if (step.step != Table::Step::kFound) break;
        if (!keys.empty()) keys += ' ';
        keys += std::string(step.key.as_string().view());
        key = step.key;
    }
    return keys;
}

void library_matches_luaplus(Context& context) {
    if (kGoldenFolder.empty()) return;
    const io::TextResult text = io::read_text(io::path_from_utf8(kGoldenFolder) / io::path_from_utf8("lib_cases.tsv"));
    context.expect(text.has_value(), "đọc được lib_cases.tsv");
    if (!text) return;
    Runtime runtime;
    std::size_t cases = 0;
    std::size_t mismatches = 0;
    std::size_t start = 0;
    while (start < text->size()) {
        const std::size_t stop = std::min(text->find('\n', start), text->size());
        const std::string_view line = std::string_view(*text).substr(start, stop - start);
        start = stop + 1;
        if (line.empty() || line.starts_with('#')) continue;
        const std::vector<std::string_view> cells = split_tabs(line);
        if (cells.front() == "globals-order") {
            const std::string keys = globals_order(*runtime.state);
            ++cases;
            if (keys != cells[1]) {
                ++mismatches;
                context.expect(false, std::format("globals-order\n  muốn: {}\n  được: {}", cells[1], keys));
            }
            continue;
        }
        if (cells.size() != 4) {
            context.expect(false, std::format("dòng sai cột: {}", line.substr(0, 60)));
            continue;
        }
        ++cases;
        const std::string got = run_case(runtime, cells[1], cells[2]);
        if (got != cells[3] && !(tolerates_one_ulp(cells[0]) && equal_up_to_ulp(cells[3], got))) {
            ++mismatches;
            if (mismatches <= 40)
                context.expect(false, std::format("{} {}\n  muốn: {}\n  được: {}", cells[0], cells[2].substr(0, 120), cells[3].substr(0, 400), got.substr(0, 400)));
        }
    }
    context.expect(cases > 10000, "đủ ca");
    context.expect(mismatches == 0, std::format("{} ca lệch trên {}", mismatches, cases));
}

// ---- raise_error và set_metatable của host.hpp: bề mặt mà hàm game (module gameapi) dùng từ ngoài module lua ----

// Hàm game sai tham số: ném đúng một câu rồi trả rỗng, như tThrowStringException của Game.exe.
Results raising(State& state, const Function& /*self*/, Args /*args*/) {
    raise_error(state, "LUA: Lua_Get_XParam_INT Wrong Param");
    raise_error(state, "lỗi thứ hai bị bỏ");
    return {};
}

Results returning_seven(State& /*state*/, const Function& /*self*/, Args /*args*/) {
    return {Value::number(7)};
}

constexpr Proto kRaising{.body = &raising, .name = "Get_XParam_INT"};
constexpr Proto kSeven{.body = &returning_seven, .name = "GetID"};

void host_raises_errors(Context& context) {
    const StatePtr state = new_state(Limits{});
    open_standard(*state);
    const Value raiser = native(*state, kRaising);

    const game::lua::Outcome failed = protected_call(*state, raiser, {});
    context.expect(!failed.has_value(), "raise_error làm protected_call trả lỗi");
    if (!failed.has_value()) context.expect(failed.error().message == "LUA: Lua_Get_XParam_INT Wrong Param", failed.error().message);
    // Cờ lỗi đã xoá: lời gọi sau chạy bình thường.
    const game::lua::Outcome fine = protected_call(*state, native(*state, kSeven), {});
    context.expect(fine.has_value() && fine->first().as_number() == 7, "lỗi không dính sang lời gọi sau");

    // pcall của script bắt lỗi của hàm game với đúng câu ấy (khác Game.exe, nơi ngoại lệ C++ lan qua pcall: không script nào
    // dùng pcall).
    const Value pcall = game::lua::find_global(*state, "pcall");
    const std::array<Value, 1> arguments = {raiser};
    const game::lua::Outcome through_pcall = protected_call(*state, pcall, arguments);
    context.expect(through_pcall.has_value() && !through_pcall->at_or_nil(0).truthy(), "pcall trả false");
    if (through_pcall.has_value())
        context.expect(game::lua::bytes_of(through_pcall->at_or_nil(1)) == "LUA: Lua_Get_XParam_INT Wrong Param", "câu lỗi qua pcall");
}

void host_sets_metatables(Context& context) {
    const StatePtr state = new_state(Limits{});
    open_standard(*state);
    State& machine = *state;
    // Mô hình đối tượng action: handle là bảng, mọi handle chung một bảng meta mà __index là bảng hàm.
    const Value methods = new_table(machine, 0, 1);
    set_index(machine, methods, game::lua::intern(machine, "GetID"), native(machine, kSeven));
    const Value meta = new_table(machine, 0, 1);
    set_index(machine, meta, game::lua::intern(machine, "__index"), methods);
    const Value handle = new_table(machine, 0, 0);
    const Value other = new_table(machine, 0, 0);
    set_metatable(machine, handle, meta);
    set_metatable(machine, other, meta);

    const Value method = index(machine, handle, game::lua::intern(machine, "GetID"));
    context.expect(method.type() == Type::kFunction, "__index của bảng meta tìm ra hàm");
    if (method.type() == Type::kFunction) {
        const std::array<Value, 1> self = {handle};
        context.expect(call(machine, method, self).first().as_number() == 7, "gọi qua handle:GetID()");
    }
    context.expect(index(machine, other, game::lua::intern(machine, "GetID")).type() == Type::kFunction, "handle thứ hai cùng bảng meta");

    // Bảng meta có __metatable: setmetatable của script bị chặn, chủ thì không.
    set_index(machine, meta, game::lua::intern(machine, "__metatable"), Value::boolean(true));
    set_metatable(machine, handle, Value());
    context.expect(index(machine, handle, game::lua::intern(machine, "GetID")).is_nil(), "nil gỡ bảng meta, kể cả bảng meta được bảo vệ");
    context.expect(!machine.failed(), "không lỗi");
}

constexpr std::array<Case, 3> kCases = {{{.name = "thư viện chuẩn và phép toán máy ảo khớp LuaPlus.dll", .body = &library_matches_luaplus},
    {.name = "host: raise_error đặt lỗi đúng câu, một lần", .body = &host_raises_errors},
    {.name = "host: set_metatable cho handle dùng chung bảng meta", .body = &host_sets_metatables}}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
