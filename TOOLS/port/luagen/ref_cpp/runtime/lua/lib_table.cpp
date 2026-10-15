// Thư viện bảng (ltablib.c của Lua 5.0.1): concat, foreach, foreachi, getn, setn, sort, insert, remove.
//
// Port từ ltablib.c. Khác gốc:
// - Mọi vòng lặp theo cỡ khai báo (foreachi, insert, remove, concat) trừ một đơn vị ngân sách vòng lặp của State mỗi bước:
//   `table.setn(t, 2^31 - 1)` làm gốc quay hàng tỉ bước, ở đây dừng ở trần như mọi vòng lặp khác.
// - Chỉ số int của gốc tràn thì quấn vòng (UB trong C, quấn trên máy x86 của DLL); ở đây quấn bằng số không dấu hoặc tính
//   bằng int64. Hành vi trong miền hợp lệ giống gốc.
// - sort viết lại không dùng ngăn xếp Lua: mỗi giá trị trên ngăn xếp của gốc là một biến cục bộ, thứ tự đọc, ghi và so
//   sánh giữ nguyên (kể cả khi so sánh thấy hàm thứ tự sai), nên kết quả của hàm so sánh không nhất quán cũng ra đúng
//   thứ tự mà gốc ra.
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::lua {
namespace {

// aux_getn: kiểm đối số là bảng rồi luaL_getn. nullptr khi lỗi đối số.
[[nodiscard]] Table* checked_table(Arguments& in, std::int32_t& length) {
    Table* const table = in.table(0);
    if (in.failed()) return nullptr;
    length = table_length(in.state(), *table);
    return in.failed() ? nullptr : table;
}

Results table_getn(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    std::int32_t length = 0;
    if (checked_table(in, length) == nullptr) return {};
    return {Value::number(static_cast<double>(length))};
}

Results table_setn(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    Table* const table = in.table(0);
    const std::int32_t length = in.integer(1);
    if (in.failed()) return {};
    set_table_length(state, *table, length);
    return {};
}

Results table_foreachi(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    std::int32_t length = 0;
    const Table* const table = checked_table(in, length);
    if (table == nullptr) return {};
    if (in.at(1).type() != Type::kFunction) {
        in.type_error(1, "function");
        return {};
    }
    const Value callback = in.at(1);
    for (std::int64_t i = 1; i <= length; ++i) {
        if (!tick(state)) return {};
        const std::array<Value, 2> pair = {Value::number(static_cast<double>(i)), raw_get_int(*table, i)};
        const Value result = call(state, callback, pair).first();
        if (state.failed()) return {};
        if (!result.is_nil()) return {result};
    }
    return {};
}

Results table_foreach(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const Table* const table = in.table(0);
    if (in.failed()) return {};
    if (in.at(1).type() != Type::kFunction) {
        in.type_error(1, "function");
        return {};
    }
    const Value callback = in.at(1);
    Value key;
    for (;;) {
        if (!tick(state)) return {};
        const Table::Advance step = table->next(key);
        if (step.step == Table::Step::kBadKey) {
            state.runtime_error("invalid key for `next'");
            return {};
        }
        if (step.step == Table::Step::kEnd) return {};
        key = step.key;
        const std::array<Value, 2> pair = {step.key, step.value};
        const Value result = call(state, callback, pair).first();
        if (state.failed()) return {};
        if (!result.is_nil()) return {result};
    }
}

Results table_insert(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    std::int32_t length = 0;
    Table* const table = checked_table(in, length);
    if (table == nullptr) return {};
    std::int32_t top = wrapping_add(length, 1);
    std::int32_t position = top;
    std::size_t value_index = 1;
    if (args.size() != 2) {
        position = in.integer(1);
        if (in.failed()) return {};
        if (position > top) top = position;
        value_index = 2;
    }
    set_table_length(state, *table, top);
    if (state.failed()) return {};
    // t[n + 1] = t[n] cho n từ cuối xuống position.
    for (top = wrapping_add(top, -1); top >= position; top = wrapping_add(top, -1)) {
        if (!tick(state)) return {};
        if (!raw_set_int(state, *table, static_cast<std::int64_t>(top) + 1, table->get_int(top))) return {};
    }
    static_cast<void>(raw_set_int(state, *table, position, in.at(value_index)));
    return {};
}

Results table_remove(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    std::int32_t length = 0;
    Table* const table = checked_table(in, length);
    if (table == nullptr) return {};
    std::int32_t position = in.opt_integer(1, length);
    if (in.failed() || length <= 0) return {};
    set_table_length(state, *table, length - 1);
    if (state.failed()) return {};
    const Value removed = table->get_int(position);
    for (; position < length; ++position) {
        if (!tick(state)) return {};
        if (!raw_set_int(state, *table, position, raw_get_int(*table, static_cast<std::int64_t>(position) + 1))) return {};
    }
    if (!raw_set_int(state, *table, length, Value())) return {};
    return {removed};
}

Results table_concat(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view separator = in.opt_text(1, "");
    const std::int32_t first = in.opt_integer(2, 1);
    std::int32_t last = in.opt_integer(3, 0);
    const Table* const table = in.table(0);
    if (in.failed()) return {};
    if (last == 0) last = table_length(state, *table);
    if (in.failed()) return {};
    Buffer joined(state);
    for (std::int64_t i = first; i <= last; ++i) {
        if (!tick(state)) return {};
        const Value item = raw_get_int(*table, i);
        if (item.type() == Type::kString) {
            joined.add(item.as_string().view());
        } else if (item.type() == Type::kNumber) {
            joined.add(number_to_string(item.as_number()));
        } else {
            in.argument_error(0, "table contains non-strings");
            return {};
        }
        if (i != last) joined.add(separator);
        if (state.failed()) return {};
    }
    const Value result = joined.finish();
    if (state.failed()) return {};
    return {result};
}

// Phần sắp xếp của luaB_sort. Mỗi hàm trả false khi State đã lỗi (hàm so sánh lỗi, "invalid order function"), khi đó
// người gọi thoát ngay không ghi gì thêm.
class Sorter {
public:
    Sorter(State& state, Table& table, Value comparator) noexcept : state_(&state), table_(&table), comparator_(comparator) {}

    // auxsort(L, l, u).
    void sort(std::int64_t low, std::int64_t high);

private:
    // sort_comp(a, b): a < b theo hàm so sánh của người dùng hoặc toán tử `<`.
    [[nodiscard]] bool before(Value left, Value right) {
        if (!comparator_.is_nil()) {
            const std::array<Value, 2> pair = {left, right};
            return call(*state_, comparator_, pair).first().truthy();
        }
        return less(*state_, left, right);
    }
    [[nodiscard]] Value at(std::int64_t index) const noexcept { return raw_get_int(*table_, index); }
    [[nodiscard]] bool put(std::int64_t index, Value value) { return raw_set_int(*state_, *table_, index, value); }
    // Đổi chỗ a[first] và a[second] bằng hai giá trị đã đọc (set2 của gốc: ghi giá trị trên cùng vào chỉ số đầu).
    [[nodiscard]] bool put_pair(std::int64_t first, Value first_value, std::int64_t second, Value second_value) {
        return put(first, first_value) && put(second, second_value);
    }

    State* state_;
    Table* table_;
    Value comparator_;
};

// Đệ quy chỉ trên nửa nhỏ hơn (nửa lớn lặp trong while) nên độ sâu không quá log2 của cỡ mảng, như auxsort của gốc.
// NOLINTNEXTLINE(misc-no-recursion)
void Sorter::sort(std::int64_t low, std::int64_t high) {
    while (low < high) {
        // Sắp xếp a[low], a[(low + high) / 2] và a[high].
        {
            const Value at_low = at(low);
            const Value at_high = at(high);
            const bool swapped = before(at_high, at_low);
            if (state_->failed()) return;
            if (swapped && !put_pair(low, at_high, high, at_low)) return;
        }
        if (high - low == 1) break;
        std::int64_t i = (low + high) / 2;
        {
            const Value at_mid = at(i);
            const Value at_low = at(low);
            const bool mid_first = before(at_mid, at_low);
            if (state_->failed()) return;
            if (mid_first) {
                if (!put_pair(i, at_low, low, at_mid)) return;
            } else {
                const Value at_high = at(high);
                const bool high_first = before(at_high, at_mid);
                if (state_->failed()) return;
                if (high_first && !put_pair(i, at_high, high, at_mid)) return;
            }
        }
        if (high - low == 2) break;
        const Value pivot = at(i);
        if (!put_pair(i, at(high - 1), high - 1, pivot)) return;
        // a[low] <= P == a[high - 1] <= a[high]: chỉ cần sắp từ low + 1 tới high - 2.
        i = low;
        std::int64_t j = high - 1;
        for (;;) {
            // Bất biến: a[low..i] <= P <= a[j..high].
            Value at_i = at(++i);
            while (before(at_i, pivot)) {
                if (state_->failed()) return;
                if (i > high) {
                    state_->native_error("invalid order function for sorting");
                    return;
                }
                at_i = at(++i);
            }
            if (state_->failed()) return;
            Value at_j = at(--j);
            while (before(pivot, at_j)) {
                if (state_->failed()) return;
                if (j < low) {
                    state_->native_error("invalid order function for sorting");
                    return;
                }
                at_j = at(--j);
            }
            if (state_->failed()) return;
            if (j < i) break;
            if (!put_pair(i, at_j, j, at_i)) return;
        }
        // Đổi pivot (a[high - 1]) với a[i].
        const Value last_but_one = at(high - 1);
        const Value at_i = at(i);
        if (!put_pair(high - 1, at_i, i, last_but_one)) return;
        // a[low..i-1] <= a[i] == P <= a[i+1..high]: nửa nhỏ cho đệ quy, nửa lớn cho vòng lặp.
        std::int64_t from = 0;
        std::int64_t to = 0;
        if (i - low < high - i) {
            from = low;
            to = i - 1;
            low = to + 2;
        } else {
            from = i + 1;
            to = high;
            high = from - 2;
        }
        sort(from, to);
        if (state_->failed()) return;
    }
}

Results table_sort(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    std::int32_t length = 0;
    Table* const table = checked_table(in, length);
    if (table == nullptr) return {};
    if (!in.missing(1) && in.at(1).type() != Type::kFunction) {
        in.type_error(1, "function");
        return {};
    }
    Sorter(state, *table, in.at(1)).sort(1, length);
    return {};
}

constexpr std::array<Proto, 8> kTableFunctions = {{
    {.body = &table_concat, .name = "concat"},
    {.body = &table_foreach, .name = "foreach"},
    {.body = &table_foreachi, .name = "foreachi"},
    {.body = &table_getn, .name = "getn"},
    {.body = &table_setn, .name = "setn"},
    {.body = &table_sort, .name = "sort"},
    {.body = &table_insert, .name = "insert"},
    {.body = &table_remove, .name = "remove"},
}};

} // namespace

void open_table(State& state) {
    static_cast<void>(open_library(state, "table", kTableFunctions));
}

} // namespace game::lua
