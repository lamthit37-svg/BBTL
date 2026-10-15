// Các phép của vm.hpp: mỗi hàm làm đúng việc của lệnh máy ảo tương ứng trong lvm.c (luaV_gettable, luaV_settable,
// Arith, luaV_concat, luaV_equalval, luaV_lessthan, luaV_lessequal, OP_FORLOOP...), giữ thứ tự thao tác của gốc.
//
// Port từ lvm.c, ldo.c (luaD_precall, tryfuncTM, adjust_varargs), lparser.c (mã hoá OP_NEWTABLE). Khác gốc:
// - Không có ngăn xếp giá trị: toán hạng và kết quả đi qua tham số và giá trị trả về; luaV_concat chạy trên một mảng tạm.
// - Câu lỗi không nêu tên biến ("attempt to index global 'x'" thành "attempt to index a nil value"): mã sinh không có
//   thông tin gỡ lỗi. Vị trí là "<chunk>:<dòng của chữ function>:" thay vì dòng đang chạy.
// - `^` của hai số là XOR 32 bit (LuaPlus: đo `a^b` ra 8 với a=2, b=10 cả khi là biến); chỉ khi một toán hạng là chuỗi
//   thì Arith ép số rồi gọi hàm toàn cục `__pow` (pow thật). Gốc Lua 5.0.1 luôn gọi `__pow`.
// - NaN sinh ra từ phép tính trên số không phải NaN luôn là NaN âm (như SSE của x86 mà LuaPlus.dll chạy), không phụ thuộc
//   máy: in ra "-1.#IND" như bản gốc kể cả trên ARM.
// - Ghi vào bảng và tạo đối tượng kiểm trần heap trước khi làm (State::reserve, over_limit).
#include "core/check.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::lua {
namespace {

// MAXTAGLOOP của lvm.c: số bước tối đa qua chuỗi __index/__newindex.
constexpr int kMaxTagLoop = 100;

// luaV_tonumber: số giữ nguyên, chuỗi ép theo luaO_str2d, còn lại nullopt.
[[nodiscard]] std::optional<double> to_number(Value value) {
    if (value.type() == Type::kNumber) return value.as_number();
    if (value.type() == Type::kString) return string_to_number(value.as_string().view());
    return std::nullopt;
}

// NaN do phép tính sinh ra (hai toán hạng không phải NaN) là "real indefinite" của x86: NaN âm. Toán hạng đã là NaN thì
// giữ nguyên cách các CPU đều làm (kết quả mang NaN của toán hạng).
[[nodiscard]] double settle_nan(double result, double left, double right) noexcept {
    if (std::isnan(result) && !std::isnan(left) && !std::isnan(right)) return -std::numeric_limits<double>::quiet_NaN();
    return result;
}

[[nodiscard]] Value number_value(double result, double left, double right) noexcept {
    return Value::number(settle_nan(result, left, right));
}

// Phép `/` của gốc theo IEEE 754: x/0 là ±vô cực theo dấu hai toán hạng, 0/0 là NaN âm, toán hạng NaN được giữ. Viết tường
// minh vì chia số thực cho 0 là hành vi không xác định theo chuẩn C++ và cổng kiểm (float-divide-by-zero) bắt nó; kết quả
// bằng đúng divsd của SSE.
[[nodiscard]] double divide(double left, double right) noexcept {
    if (right != 0.0) return left / right;
    if (std::isnan(left)) return left;
    if (left == 0.0) return -std::numeric_limits<double>::quiet_NaN();
    constexpr double kInfinity = std::numeric_limits<double>::infinity();
    return std::signbit(left) != std::signbit(right) ? -kInfinity : kInfinity;
}

// (unsigned)n trên MSVC x64: cvttsd2si 64 bit rồi lấy 32 bit thấp; ngoài miền int64 và NaN cho 0 (INT64_MIN).
[[nodiscard]] std::uint32_t xor_operand(double number) noexcept {
    if (number > -9.2233720368547758e18 && number < 9.2233720368547758e18)
        return static_cast<std::uint32_t>(static_cast<std::int64_t>(number));
    return 0;
}

void type_error(State& state, Value culprit, std::string_view action) {
    state.runtime_error(std::format("attempt to {} a {} value", action, type_name(culprit.type())));
}

void arith_error(State& state, Value left, Value right) {
    // luaG_aritherror: toán hạng đầu nếu nó không ép được sang số, ngược lại toán hạng sau.
    type_error(state, to_number(left) ? right : left, "perform arithmetic on");
}

// callTMres: gọi f(a, b) lấy đúng một kết quả.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): callTMres(L, f, p1, p2) của gốc: hàm rồi hai toán hạng.
[[nodiscard]] Value call_tm_res(State& state, Value handler, Value left, Value right) {
    const std::array<Value, 2> args = {left, right};
    return call(state, handler, args).first();
}

// call_binTM: metamethod của toán hạng đầu, không có thì của toán hạng sau; nullopt khi không có hàm nào.
[[nodiscard]] std::optional<Value> call_bin_tm(State& state, Event event, Value first, Value second) {
    Value handler = state.metamethod(first, event);
    if (handler.is_nil()) handler = state.metamethod(second, event);
    if (handler.type() != Type::kFunction) return std::nullopt;
    return call_tm_res(state, handler, first, second);
}

// Arith của lvm.c cho các toán hạng chưa phải cả hai là số (hoặc là POW).
[[nodiscard]] Value arith(State& state, Event op, Value left, Value right) {
    const std::optional<double> b = to_number(left);
    const std::optional<double> c = b ? to_number(right) : std::nullopt;
    if (b && c) {
        switch (op) {
        case Event::kAdd: return number_value(*b + *c, *b, *c);
        case Event::kSub: return number_value(*b - *c, *b, *c);
        case Event::kMul: return number_value(*b * *c, *b, *c);
        case Event::kDiv: return number_value(divide(*b, *c), *b, *c);
        case Event::kPow: {
            const Value function = state.globals().get_string(state.event_name(Event::kPow));
            if (function.type() != Type::kFunction) {
                state.runtime_error("`__pow' (`^' operator) is not a function");
                return {};
            }
            return call_tm_res(state, function, Value::number(*b), Value::number(*c));
        }
        default: core::fail("arith: sự kiện không phải phép số học");
        }
    }
    if (const std::optional<Value> handled = call_bin_tm(state, op, left, right)) return *handled;
    arith_error(state, left, right);
    return {};
}

// luaV_tostring tại chỗ: số thành chuỗi. false khi không phải chuỗi hay số, hoặc khi tạo chuỗi bị trần heap chặn
// (State đã ghi lỗi): người gọi hỏi failed() trước khi đọc.
[[nodiscard]] bool to_string_in_place(State& state, Value& value) {
    if (value.type() == Type::kString) return true;
    if (value.type() != Type::kNumber) return false;
    value = state.make_string(number_to_string(value.as_number()));
    return !state.failed();
}

// luaV_strcmp: so từng byte như số không dấu, byte 0 là byte thường, ngắn hơn thì nhỏ hơn (strcoll của locale "C").
[[nodiscard]] int compare_strings(const String& left, const String& right) noexcept {
    return left.view().compare(right.view());
}

[[nodiscard]] std::string_view comparison_noun(Type type) noexcept {
    return type_name(type);
}

void order_error(State& state, Value left, Value right) {
    const std::string_view first = comparison_noun(left.type());
    const std::string_view second = comparison_noun(right.type());
    if (first == second) {
        state.runtime_error(std::format("attempt to compare two {} values", first));
    } else {
        state.runtime_error(std::format("attempt to compare {} with {}", first, second));
    }
}

// call_orderTM: -1 khi không có metamethod dùng được, ngược lại 0 hay 1.
[[nodiscard]] int call_order_tm(State& state, Value left, Value right, Event event) {
    const Value handler = state.metamethod(left, event);
    if (handler.is_nil()) return -1;
    const Value other_handler = state.metamethod(right, event);
    if (!raw_equal(handler, other_handler)) return -1;
    return call_tm_res(state, handler, left, right).truthy() ? 1 : 0;
}

// luaV_equalval cho hai giá trị cùng kiểu.
[[nodiscard]] bool equal_same_type(State& state, Value left, Value right) {
    if (left.type() != Type::kTable) return raw_equal(left, right);
    if (&left.as_table() == &right.as_table()) return true;
    // get_compTM: cả hai bảng meta cùng có __eq và là cùng một hàm.
    const Table* const first_meta = left.as_table().metatable();
    const Table* const second_meta = right.as_table().metatable();
    const Value handler = state.fast_metamethod(first_meta, Event::kEq);
    if (handler.is_nil()) return false;
    if (first_meta != second_meta) {
        const Value other_handler = state.fast_metamethod(second_meta, Event::kEq);
        if (other_handler.is_nil() || !raw_equal(handler, other_handler)) return false;
    }
    return call_tm_res(state, handler, left, right).truthy();
}

// luaO_int2fb: số nguyên dạng "mmmmmxxx" (giá trị xxx * 2^mmmmm) làm tròn lên.
[[nodiscard]] std::uint32_t int_to_float_byte(std::uint32_t value) noexcept {
    std::uint32_t exponent = 0;
    while (value >= 8) {
        value = (value + 1) >> 1;
        ++exponent;
    }
    return (exponent << 3) | value;
}

[[nodiscard]] std::uint64_t float_byte_to_int(std::uint32_t coded) noexcept {
    return static_cast<std::uint64_t>(coded & 7U) << (coded >> 3);
}

[[nodiscard]] std::int32_t log2_floor_or_minus_one(std::size_t value) noexcept {
    return value == 0 ? -1 : std::bit_width(value) - 1;
}

} // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký của vm.hpp (OP_GETTABLE: đối tượng rồi khoá).
Value index(State& state, Value object, Value key) {
    Value current = object;
    for (int loop = 0;; ++loop) {
        if (loop > kMaxTagLoop) {
            state.runtime_error("loop in gettable");
            return {};
        }
        Value handler;
        if (current.type() == Type::kTable) {
            const Table& table = current.as_table();
            const Value found = table.get(key);
            if (!found.is_nil()) return found;
            handler = state.fast_metamethod(table.metatable(), Event::kIndex);
            if (handler.is_nil()) return {};
        } else {
            handler = state.metamethod(current, Event::kIndex);
            if (handler.is_nil()) {
                type_error(state, current, "index");
                return {};
            }
        }
        if (handler.type() == Type::kFunction) return call_tm_res(state, handler, current, key);
        current = handler;
    }
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký của vm.hpp (OP_SETTABLE: đối tượng, khoá, giá trị).
void set_index(State& state, Value object, Value key, Value value) {
    if (state.over_limit()) {
        state.raise_text("not enough memory");
        return;
    }
    Value current = object;
    for (int loop = 0; loop <= kMaxTagLoop; ++loop) {
        Value handler;
        if (current.type() == Type::kTable) {
            Table& table = current.as_table();
            // luaH_set tạo khoá (giá trị nil) TRƯỚC khi xét __newindex, kể cả khi sau đó metamethod xử lý: thứ tự duyệt
            // của bảng phụ thuộc vào việc khoá đã chiếm nút.
            const Table::Slot slot = table.set_slot(key);
            if (slot.fault != Table::Fault::kNone) {
                state.runtime_error(slot.fault == Table::Fault::kNilKey ? "table index is nil" : "table index is NaN");
                return;
            }
            if (!slot.value->is_nil()) {
                *slot.value = value;
                return;
            }
            handler = state.fast_metamethod(table.metatable(), Event::kNewIndex);
            if (handler.is_nil()) {
                *slot.value = value;
                return;
            }
        } else {
            handler = state.metamethod(current, Event::kNewIndex);
            if (handler.is_nil()) {
                type_error(state, current, "index");
                return;
            }
        }
        if (handler.type() == Type::kFunction) {
            const std::array<Value, 3> args = {current, key, value};
            static_cast<void>(call(state, handler, args));
            return;
        }
        current = handler;
    }
    state.runtime_error("loop in settable");
}

Value get_global(State& state, Value name) {
    const Value found = state.globals().get(name);
    if (!found.is_nil()) return found;
    return index(state, Value(&state.globals()), name);
}

void set_global(State& state, Value name, Value value) {
    set_index(state, Value(&state.globals()), name, value);
}

Results call(State& state, Value callee, Args args) {
    if (callee.type() == Type::kFunction) return state.invoke(callee.as_function(), args);
    // tryfuncTM: __call của giá trị, gọi với chính giá trị làm đối số đầu.
    const Value handler = state.metamethod(callee, Event::kCall);
    if (handler.type() != Type::kFunction) {
        type_error(state, callee, "call");
        return {};
    }
    Results extended;
    extended.push(callee);
    extended.append(args);
    return state.invoke(handler.as_function(), extended.values());
}

Value method_of(State& state, Value object, Value name) {
    return index(state, object, name);
}

Value add(State& state, Value left, Value right) {
    if (left.type() == Type::kNumber && right.type() == Type::kNumber)
        return number_value(left.as_number() + right.as_number(), left.as_number(), right.as_number());
    return arith(state, Event::kAdd, left, right);
}

Value sub(State& state, Value left, Value right) {
    if (left.type() == Type::kNumber && right.type() == Type::kNumber)
        return number_value(left.as_number() - right.as_number(), left.as_number(), right.as_number());
    return arith(state, Event::kSub, left, right);
}

Value mul(State& state, Value left, Value right) {
    if (left.type() == Type::kNumber && right.type() == Type::kNumber)
        return number_value(left.as_number() * right.as_number(), left.as_number(), right.as_number());
    return arith(state, Event::kMul, left, right);
}

Value div(State& state, Value left, Value right) {
    if (left.type() == Type::kNumber && right.type() == Type::kNumber)
        return number_value(divide(left.as_number(), right.as_number()), left.as_number(), right.as_number());
    return arith(state, Event::kDiv, left, right);
}

Value pow(State& state, Value left, Value right) {
    if (left.type() == Type::kNumber && right.type() == Type::kNumber)
        return Value::number(static_cast<double>(xor_operand(left.as_number()) ^ xor_operand(right.as_number())));
    return arith(state, Event::kPow, left, right);
}

Value unm(State& state, Value operand) {
    if (const std::optional<double> number = to_number(operand)) return Value::number(-*number);
    if (const std::optional<Value> handled = call_bin_tm(state, Event::kUnm, operand, Value())) return *handled;
    arith_error(state, operand, Value());
    return {};
}

Value concat(State& state, Args parts) {
    core::check(parts.size() >= 2, "concat: bộ dịch phải gộp ít nhất hai toán hạng");
    std::vector<Value> stack(parts.begin(), parts.end());
    std::size_t total = stack.size();
    std::size_t last = total - 1;
    do {
        std::size_t used = 2;
        // `&&` ngắn mạch như gốc: toán hạng trái đã ép sang chuỗi tại chỗ ngay cả khi toán hạng phải không ép được.
        const bool both_text = to_string_in_place(state, stack[last - 1]) && to_string_in_place(state, stack[last]);
        if (state.failed()) return {};
        if (!both_text) {
            const std::optional<Value> handled = call_bin_tm(state, Event::kConcat, stack[last - 1], stack[last]);
            if (!handled) {
                type_error(state, stack[last - 1].type() == Type::kString ? stack[last] : stack[last - 1], "concatenate");
                return {};
            }
            if (state.failed()) return {};
            stack[last - 1] = *handled;
        } else if (!stack[last].as_string().view().empty()) {
            // Gộp được bao nhiêu chuỗi liền nhau thì gộp một lượt.
            std::size_t length = stack[last].as_string().size() + stack[last - 1].as_string().size();
            while (used < total && to_string_in_place(state, stack[last - used])) {
                length += stack[last - used].as_string().size();
                ++used;
            }
            if (state.failed() || !state.reserve(length)) return {};
            std::string buffer;
            buffer.reserve(length);
            for (std::size_t at = last + 1 - used; at <= last; ++at)
                buffer += stack[at].as_string().view();
            stack[last + 1 - used] = state.make_string(buffer);
            if (state.failed()) return {};
        }
        total -= used - 1;
        last -= used - 1;
    } while (total > 1);
    return stack[0];
}

bool equal(State& state, Value left, Value right) {
    if (left.type() != right.type()) return false;
    return equal_same_type(state, left, right);
}

bool less(State& state, Value left, Value right) {
    if (left.type() != right.type()) {
        order_error(state, left, right);
        return false;
    }
    if (left.type() == Type::kNumber) return left.as_number() < right.as_number();
    if (left.type() == Type::kString) return compare_strings(left.as_string(), right.as_string()) < 0;
    const int handled = call_order_tm(state, left, right, Event::kLt);
    if (handled != -1) return handled == 1;
    order_error(state, left, right);
    return false;
}

bool less_equal(State& state, Value left, Value right) {
    if (left.type() != right.type()) {
        order_error(state, left, right);
        return false;
    }
    if (left.type() == Type::kNumber) return left.as_number() <= right.as_number();
    if (left.type() == Type::kString) return compare_strings(left.as_string(), right.as_string()) <= 0;
    int handled = call_order_tm(state, left, right, Event::kLe);
    if (handled != -1) return handled == 1;
    // Không có __le thì thử not (right < left).
    // NOLINTNEXTLINE(readability-suspicious-call-argument): đổi chỗ toán hạng có chủ ý, a <= b là not (b < a).
    handled = call_order_tm(state, right, left, Event::kLt);
    if (handled != -1) return handled == 0;
    order_error(state, left, right);
    return false;
}

Value new_table(State& state, std::size_t list_items, std::size_t record_items) {
    // Mã hoá như lparser.c: cỡ mảng qua luaO_int2fb (làm tròn lên), cỡ phần băm là log2(số mục) + 1. record_items chỉ đếm mục
    // dạng `Tên = giá trị` (recfield chỉ tăng cc->nh ở nhánh TK_NAME), không đếm mục `[khoá] = giá trị`.
    constexpr std::size_t kLargest = std::size_t{1} << Table::kMaxBits;
    const std::uint32_t coded = int_to_float_byte(static_cast<std::uint32_t>(std::min(list_items, kLargest)));
    const std::uint64_t array_size = float_byte_to_int(coded);
    const std::int32_t log2_nodes = log2_floor_or_minus_one(std::min(record_items, kLargest)) + 1;
    if (array_size > kLargest || log2_nodes > Table::kMaxBits) {
        state.runtime_error("table overflow");
        return {};
    }
    Table* const made = state.make_table(static_cast<std::int32_t>(array_size), log2_nodes);
    return made != nullptr ? Value(made) : Value();
}

void set_list(State& state, Value table, std::size_t first, Args items) {
    core::check(table.type() == Type::kTable, "set_list: đích không phải bảng");
    if (state.over_limit()) {
        state.raise_text("not enough memory");
        return;
    }
    constexpr auto kLargestKey = static_cast<std::size_t>(std::numeric_limits<std::int32_t>::max());
    if (first > kLargestKey || items.size() > kLargestKey - first) {
        state.runtime_error("table overflow");
        return;
    }
    Table& destination = table.as_table();
    // OP_SETLIST gán từ phần tử cuối về đầu; thứ tự này quyết định chỗ các khoá rơi vào phần băm.
    for (std::size_t i = items.size(); i-- > 0;)
        *destination.set_slot_int(static_cast<std::int32_t>(first + i)) = items[i];
}

Cell* new_cell(State& state, Value initial) {
    return state.make_cell(initial);
}

Value closure(State& state, const Proto& proto, const Function& parent, std::span<Cell* const> upvalues) {
    core::check(upvalues.size() == proto.upvalues, "closure: số upvalue không khớp Proto");
    return state.make_closure(proto, object_of(parent).chunk_, upvalues);
}

Value vararg_table(State& state, Args extra) {
    // adjust_varargs: luaH_new(extra, 1), extra[i] vào chỉ số i + 1, rồi trường n.
    if (extra.size() > (std::size_t{1} << Table::kMaxBits)) {
        state.runtime_error("table overflow");
        return {};
    }
    Table* const made = state.make_table(static_cast<std::int32_t>(extra.size()), 1);
    if (made == nullptr) return {};
    for (std::size_t i = 0; i < extra.size(); ++i)
        *made->set_slot_int(static_cast<std::int32_t>(i + 1)) = extra[i];
    const Value name = state.make_string("n");
    if (state.failed()) return {};
    const Table::Slot slot = made->set_slot(name);
    core::check(slot.fault == Table::Fault::kNone, "vararg_table: khoá n bị từ chối");
    *slot.value = Value::number(static_cast<double>(extra.size()));
    return Value(made);
}

void for_prep(State& state, Value& generator, Value& invariant) {
    if (generator.type() != Type::kTable) return;
    invariant = generator;
    generator = state.global("next");
}

bool for_next(State& state, Value& index, Value& limit, Value& step) {
    if (index.type() != Type::kNumber) {
        state.runtime_error("`for' initial value must be a number");
        return false;
    }
    // tonumber(plimit, ra+1): ép tại chỗ nên lượt sau thấy số.
    if (limit.type() != Type::kNumber) {
        const std::optional<double> converted = to_number(limit);
        if (!converted) {
            state.runtime_error("`for' limit must be a number");
            return false;
        }
        limit = Value::number(*converted);
    }
    if (step.type() != Type::kNumber) {
        const std::optional<double> converted = to_number(step);
        if (!converted) {
            state.runtime_error("`for' step must be a number");
            return false;
        }
        step = Value::number(*converted);
    }
    const double increment = step.as_number();
    const double next = index.as_number() + increment;
    if (increment > 0 ? next <= limit.as_number() : next >= limit.as_number()) {
        index = Value::number(next);
        return true;
    }
    return false;
}

} // namespace game::lua
