// Phần dùng chung của thư viện chuẩn: lauxlib.c (đọc đối số, luaL_openlib, getn/setn) và luaB_tostring.
//
// Port từ lauxlib.c, lbaselib.c. Khác gốc:
// - Câu lỗi đối số nêu tên hàm theo Proto của hàm C++ (gốc lấy tên từ thông tin gỡ lỗi nơi gọi) và không đổi chỉ số đối số
//   cho lời gọi kiểu phương thức.
// - setn/getn giữ cỡ khai báo ngay trong Table (declared_size) thay vì bảng `sizes` có khoá yếu trong sổ đăng ký.
// - tostring của bảng và hàm in số thứ tự tạo (16 chữ số hex như %p của MSVC) thay vì địa chỉ: địa chỉ không tất định.
#include "core/check.hpp"
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/table.hpp"
#include "lua/vm.hpp"

#include <cstddef>
#include <algorithm>
#include <array>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::lua {
namespace {

// luaL_typename: "no value" khi thiếu đối số.
[[nodiscard]] std::string_view argument_type_name(const Arguments& in, std::size_t index) {
    return in.present(index) ? type_name(in.at(index).type()) : std::string_view("no value");
}

// lua_tonumber: số, hoặc chuỗi ép được; nullopt là "0 và không phải số" của luaL_checknumber.
[[nodiscard]] std::optional<double> numeric_value(Value value) {
    if (value.type() == Type::kNumber) return value.as_number();
    if (value.type() == Type::kString) return string_to_number(value.as_string().view());
    return std::nullopt;
}

} // namespace

void Arguments::argument_error(std::size_t index, std::string_view detail) {
    state_->native_error(std::format("bad argument #{} to `{}' ({})", index + 1, self_->proto().name, detail));
}

void Arguments::type_error(std::size_t index, std::string_view expected) {
    argument_error(index, std::format("{} expected, got {}", expected, argument_type_name(*this, index)));
}

double Arguments::number(std::size_t index) {
    if (const std::optional<double> value = numeric_value(at(index))) return *value;
    type_error(index, "number");
    return 0.0;
}

double Arguments::opt_number(std::size_t index, double fallback) {
    return missing(index) ? fallback : number(index);
}

std::int32_t Arguments::integer(std::size_t index) {
    return truncate_to_int32(number(index));
}

std::int32_t Arguments::opt_integer(std::size_t index, std::int32_t fallback) {
    return missing(index) ? fallback : integer(index);
}

std::string_view Arguments::text(std::size_t index) {
    const Value value = at(index);
    if (value.type() == Type::kString) return value.as_string().view();
    if (value.type() == Type::kNumber) {
        const Value converted = state_->make_string(number_to_string(value.as_number()));
        if (!state_->failed()) return converted.as_string().view();
        return {};
    }
    type_error(index, "string");
    return {};
}

std::string_view Arguments::opt_text(std::size_t index, std::string_view fallback) {
    return missing(index) ? fallback : text(index);
}

Table* Arguments::table(std::size_t index) {
    const Value value = at(index);
    if (value.type() == Type::kTable) return &value.as_table();
    type_error(index, "table");
    return nullptr;
}

void Arguments::any(std::size_t index) {
    if (!present(index)) argument_error(index, "value expected");
}

void register_functions(State& state, Table& into, std::span<const Proto> protos) {
    for (const Proto& proto : protos) {
        const Value name = state.make_string(proto.name);
        const Value function = state.make_native(proto);
        if (state.failed()) return;
        const Table::Slot slot = into.set_slot(name);
        core::check(slot.fault == Table::Fault::kNone && slot.value != nullptr, "register_functions: khoá chuỗi bị từ chối");
        *slot.value = function;
    }
}

Table* open_library(State& state, std::string_view name, std::span<const Proto> protos) {
    Table* const library = state.make_table(0, 0);
    if (library == nullptr) return nullptr;
    state.set_global(name, Value(library));
    register_functions(state, *library, protos);
    return library;
}

std::int32_t table_length(State& state, const Table& table) {
    // checkint của lauxlib.c: (int) giá trị; "không phải số" là -1.
    const auto as_count = [](Value value) -> std::int32_t {
        const std::optional<double> number = numeric_value(value);
        return number ? truncate_to_int32(*number) : -1;
    };
    const Value name = state.make_string("n");
    if (state.failed()) return 0;
    if (const std::int32_t from_field = as_count(table.get(name)); from_field >= 0) return from_field;
    if (table.declared_size() >= 0) return table.declared_size();
    std::int32_t length = 0;
    while (!table.get_int(length + 1).is_nil())
        ++length;
    return length;
}

void set_table_length(State& state, Table& table, std::int32_t length) {
    const Value name = state.make_string("n");
    if (state.failed()) return;
    const Value current = table.get(name);
    const std::optional<double> number = numeric_value(current);
    if (number && truncate_to_int32(*number) >= 0) {
        const Table::Slot slot = table.set_slot(name);
        core::check(slot.fault == Table::Fault::kNone && slot.value != nullptr, "set_table_length: khoá n bị từ chối");
        *slot.value = Value::number(static_cast<double>(length));
    } else {
        table.set_declared_size(length);
    }
}

Buffer::Buffer(State& state) : state_(&state) {
    const std::size_t used = state.used_bytes();
    cap_ = state.limits().heap_bytes > used ? state.limits().heap_bytes - used : 0;
}

bool Buffer::room(std::size_t extra) {
    if (state_->failed()) return false;
    if (extra <= cap_ - std::min(cap_, text_.size())) return true;
    state_->raise_text("not enough memory");
    return false;
}

void Buffer::add(std::string_view piece) {
    if (room(piece.size())) text_.append(piece);
}

void Buffer::add(char letter, std::size_t count) {
    if (room(count)) text_.append(count, letter);
}

Value Buffer::finish() {
    if (state_->failed()) return {};
    return state_->make_string(text_);
}

Value raw_get_int(const Table& table, std::int64_t key) noexcept {
    if (key >= std::numeric_limits<std::int32_t>::min() && key <= std::numeric_limits<std::int32_t>::max())
        return table.get_int(static_cast<std::int32_t>(key));
    return table.get(Value::number(static_cast<double>(key)));
}

bool raw_set_int(State& state, Table& table, std::int64_t key, Value value) {
    if (state.over_limit()) {
        state.raise_text("not enough memory");
        return false;
    }
    if (key >= std::numeric_limits<std::int32_t>::min() && key <= std::numeric_limits<std::int32_t>::max()) {
        *table.set_slot_int(static_cast<std::int32_t>(key)) = value;
        return true;
    }
    const Table::Slot slot = table.set_slot(Value::number(static_cast<double>(key)));
    core::check(slot.fault == Table::Fault::kNone && slot.value != nullptr, "raw_set_int: khoá số bị từ chối");
    *slot.value = value;
    return true;
}

Value to_display_string(State& state, Value value) {
    // luaL_callmeta(L, 1, "__tostring"): bảng meta của giá trị (bảng của kiểu với giá trị không phải bảng).
    const Table* const metatable =
        value.type() == Type::kTable ? value.as_table().metatable() : state.type_table(value.type());
    if (metatable != nullptr) {
        const Value name = state.make_string("__tostring");
        if (state.failed()) return {};
        const Value handler = metatable->get(name);
        if (!handler.is_nil()) {
            const std::array<Value, 1> args = {value};
            return call(state, handler, args).first();
        }
    }
    switch (value.type()) {
    case Type::kNil: return state.make_string("nil");
    case Type::kBoolean: return state.make_string(value.as_boolean() ? "true" : "false");
    case Type::kNumber: return state.make_string(number_to_string(value.as_number()));
    case Type::kString: return value;
    case Type::kTable: return state.make_string(std::format("table: {:016X}", value.as_table().serial()));
    case Type::kFunction: return state.make_string(std::format("function: {:016X}", function_serial(value.as_function())));
    }
    core::fail("to_display_string: kiểu ngoài miền");
}

} // namespace game::lua
