// Value, raw_equal và Results của vm.hpp.
#include "core/check.hpp"
#include "lua/element.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <cstddef>
#include <initializer_list>
#include <span>
#include <utility>
#include <variant>
#include <vector>

namespace game::lua {

bool Value::as_boolean() const {
    const bool* const flag = std::get_if<bool>(&payload_);
    core::check(flag != nullptr, "Value::as_boolean: không phải boolean");
    return *flag;
}

double Value::as_number() const {
    const double* const number = std::get_if<double>(&payload_);
    core::check(number != nullptr, "Value::as_number: không phải số");
    return *number;
}

String& Value::as_string() const {
    String* const* const string = std::get_if<String*>(&payload_);
    core::check(string != nullptr, "Value::as_string: không phải chuỗi");
    return **string;
}

Table& Value::as_table() const {
    Table* const* const table = std::get_if<Table*>(&payload_);
    core::check(table != nullptr, "Value::as_table: không phải bảng");
    return **table;
}

Function& Value::as_function() const {
    Function* const* const function = std::get_if<Function*>(&payload_);
    core::check(function != nullptr, "Value::as_function: không phải hàm");
    return **function;
}

bool raw_equal(Value left, Value right) noexcept {
    if (left.type() != right.type()) return false;
    switch (left.type()) {
    case Type::kNil: return true;
    case Type::kBoolean: return left.as_boolean() == right.as_boolean();
    case Type::kNumber: return left.as_number() == right.as_number();
    case Type::kString: return &left.as_string() == &right.as_string();
    case Type::kTable: return &left.as_table() == &right.as_table();
    case Type::kFunction: return &left.as_function() == &right.as_function();
    }
    core::fail("raw_equal: kiểu ngoài miền");
}

Results::Results(std::initializer_list<Value> values) {
    for (const Value value : values)
        push(value);
}

Value Results::at_or_nil(std::size_t index) const noexcept {
    const std::span<const Value> all = values();
    return index < all.size() ? all[index] : Value();
}

std::span<const Value> Results::values() const noexcept {
    // Bất biến: tới kInline giá trị nằm trong inline_; nhiều hơn thì TẤT CẢ nằm trong spill_ để dải liền một khối.
    if (size_ <= kInline) return {inline_.data(), size_};
    return spill_;
}

void Results::push(Value value) {
    if (size_ < kInline) {
        element(inline_, size_) = value;
    } else {
        if (size_ == kInline) spill_.assign(inline_.begin(), inline_.end());
        spill_.push_back(value);
    }
    ++size_;
}

void Results::append(const Results& other) {
    append(other.values());
}

void Results::append(std::span<const Value> more) {
    if (more.empty()) return;
    const std::size_t total = size_ + more.size();
    if (total <= kInline) {
        // Nguồn có thể là chính inline_ nhưng chỉ ở [0, size_), đích bắt đầu từ size_: hai dải không giao nhau.
        std::ranges::copy(more, inline_.begin() + static_cast<std::ptrdiff_t>(size_));
        size_ = total;
        return;
    }
    // Dựng vector mới rồi mới thay spill_: more có thể trỏ vào chính spill_, vector cũ còn sống tới lúc đó.
    std::vector<Value> merged;
    merged.reserve(total);
    const std::span<const Value> mine = values();
    merged.insert(merged.end(), mine.begin(), mine.end());
    merged.insert(merged.end(), more.begin(), more.end());
    spill_ = std::move(merged);
    size_ = total;
}

} // namespace game::lua
