#include "lua/state.hpp"

#include "core/check.hpp"
#include "lua/element.hpp"
#include "lua/host.hpp"
#include "lua/number.hpp"
#include "lua/table.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::lua {
namespace {

constexpr std::string_view kMemoryError = "not enough memory";
// Số khung gọi cấp sẵn; sâu hơn thì vector tự lớn (chủ có thể đặt max_depth rất lớn).
constexpr std::size_t kReservedFrames = 256;

} // namespace

std::uint32_t function_serial(const Function& function) noexcept {
    return object_of(function).serial_;
}

State::State(const Limits& limits) : limits_(limits) {
    frames_.reserve(std::min<std::size_t>(limits_.max_depth, kReservedFrames) + 1);
    // defaultmeta của lstate.c: bảng rỗng mà setmetatable(t, nil) gán, tự là bảng meta của chính nó.
    default_meta_ = tables_.emplace_back(std::make_unique<Table>(next_serial(), &heap_bytes_, 0, 0)).get();
    default_meta_->set_metatable(default_meta_);
    // Bảng riêng của từng kiểu (LuaPlus). Bảng của kiểu table là bảng meta mà bảng mới nhận; bảng của chuỗi là bảng
    // `string` do open_string đổ hàm vào (tạo sẵn ở đây để chuỗi tra được từ lúc có State).
    for (Table*& slot : type_tables_) {
        slot = tables_.emplace_back(std::make_unique<Table>(next_serial(), &heap_bytes_, 0, 0)).get();
        slot->set_metatable(default_meta_);
    }
    // luaH_new(L, 0, 4): bảng toàn cục có sẵn 16 nút.
    globals_ = tables_.emplace_back(std::make_unique<Table>(next_serial(), &heap_bytes_, 0, 4)).get();
    globals_->set_metatable(type_table(Type::kTable));
    for (std::size_t event = 0; event < kEventCount; ++event)
        element(event_names_, event) = strings_.intern(element(kEventNames, event)).string;
}

State::~State() = default;

// ---- lỗi ----

void State::raise(Value error) {
    if (failed_) return;
    failed_ = true;
    error_ = error;
}

void State::raise_text(std::string_view message) {
    // Qua thẳng bảng chuỗi, không qua trần heap: câu báo hết bộ nhớ cũng phải có chỗ.
    raise(Value(strings_.intern(message).string));
}

std::string State::where(std::size_t level) const {
    if (level >= frames_.size()) return {};
    const auto& frame = object_of(*frames_[frames_.size() - 1 - level]);
    if (frame.is_native_) return {};
    std::string text(frame.proto_->name);
    text += ": ";
    return text;
}

void State::runtime_error(std::string_view message) {
    if (failed_) return;
    raise_text(where(0) + std::string(message));
}

void State::native_error(std::string_view message) {
    if (failed_) return;
    raise_text(where(1) + std::string(message));
}

Value State::take_error() noexcept {
    const Value error = error_;
    error_ = Value();
    failed_ = false;
    return error;
}

std::string State::error_text(Value error) {
    if (error.type() == Type::kString) return std::string(error.as_string().view());
    if (error.type() == Type::kNumber) return number_to_string(error.as_number());
    return "(error object is not a string)";
}

bool State::loop_budget_exceeded() {
    runtime_error("script exceeded the loop budget");
    return false;
}

bool State::reserve(std::size_t extra) {
    if (!over_limit() && extra <= limits_.heap_bytes - used_bytes()) return true;
    raise_text(kMemoryError);
    return false;
}

// ---- gọi ----

Results State::invoke(const Function& function, Args args) {
    if (frames_.size() >= limits_.max_depth) {
        runtime_error("stack overflow");
        return {};
    }
    const Body body = function.proto().body;
    core::check(body != nullptr, "State::invoke: Proto không có thân");
    frames_.push_back(&function);
    Results results = body(*this, function, args);
    frames_.pop_back();
    if (failed_) return {};
    return results;
}

// ---- đối tượng ----

Value State::make_string(std::string_view bytes) {
    if (!reserve(bytes.size() + sizeof(String))) return {};
    return Value(strings_.intern(bytes).string);
}

Table* State::make_table(std::int32_t array_size, std::int32_t log2_nodes) {
    const auto nodes = log2_nodes > 0 ? std::size_t{1} << log2_nodes : std::size_t{0};
    if (!reserve(sizeof(Table) + static_cast<std::size_t>(array_size) * sizeof(Value) + nodes * sizeof(Table::Node))) return nullptr;
    Table* const made = tables_.emplace_back(std::make_unique<Table>(next_serial(), &heap_bytes_, array_size, log2_nodes)).get();
    made->set_metatable(type_table(Type::kTable));
    return made;
}

Cell* State::make_cell(Value initial) {
    if (!reserve(sizeof(CellObject))) return nullptr;
    heap_bytes_ += sizeof(CellObject);
    return cells_.emplace_back(std::make_unique<CellObject>(initial)).get();
}

Value State::make_closure(const Proto& proto, const LoadedChunk* chunk, std::span<Cell* const> upvalues) {
    if (!reserve(sizeof(FunctionObject) + upvalues.size() * sizeof(CellObject*))) return {};
    std::vector<CellObject*> held;
    held.reserve(upvalues.size());
    for (Cell* const cell : upvalues) {
        core::check(cell != nullptr, "State::make_closure: upvalue rỗng");
        held.push_back(&object_of(*cell));
    }
    heap_bytes_ += sizeof(FunctionObject) + held.size() * sizeof(CellObject*);
    FunctionObject* const made =
        functions_.emplace_back(std::make_unique<FunctionObject>(proto, chunk, std::move(held), next_serial(), chunk == nullptr)).get();
    return Value(static_cast<Function*>(made));
}

Value State::make_native(const Proto& proto) {
    return make_closure(proto, nullptr, {});
}

Value State::make_native_closure(const Proto& proto, std::span<const Value> upvalues) {
    std::vector<Cell*> cells;
    cells.reserve(upvalues.size());
    for (const Value initial : upvalues) {
        Cell* const cell = make_cell(initial);
        if (cell == nullptr) return {};
        cells.push_back(cell);
    }
    return make_closure(proto, nullptr, cells);
}

const State::LoadedChunk& State::load_chunk(const Chunk& chunk) {
    core::check(chunk.main != nullptr, "State::load_chunk: chunk lỗi cú pháp không nạp được");
    if (const auto found = loaded_.find(chunk.main); found != loaded_.end()) return *found->second;
    auto loaded = std::make_unique<LoadedChunk>();
    loaded->name = chunk.name;
    loaded->constants.reserve(chunk.strings.size());
    // Hằng của chunk là gốc vĩnh viễn: qua thẳng bảng chuỗi như tên metamethod.
    for (const std::string_view text : chunk.strings)
        loaded->constants.emplace_back(strings_.intern(text).string);
    const LoadedChunk* const kept = chunks_.emplace_back(std::move(loaded)).get();
    loaded_.emplace(chunk.main, kept);
    return *kept;
}

// ---- bảng meta ----

Value State::fast_metamethod(const Table* metatable, Event event) const noexcept {
    return metatable != nullptr ? metatable->get_string(event_name(event)) : Value();
}

Value State::metamethod(Value object, Event event) const noexcept {
    if (object.type() == Type::kTable) return fast_metamethod(object.as_table().metatable(), event);
    // LuaPlus: kiểu không phải bảng không có bảng meta riêng mà có "bảng của kiểu"; nó đóng vai metamethod của mọi
    // sự kiện (đo trên LuaPlus.dll: nil < nil lỗi "attempt to call a table value").
    return Value(element(type_tables_, static_cast<std::size_t>(object.type())));
}

// ---- toàn cục ----

Value State::global(std::string_view name) {
    return globals_->get_string(*strings_.intern(name).string);
}

void State::set_global(std::string_view name, Value value) {
    const Table::Slot slot = globals_->set_slot(Value(strings_.intern(name).string));
    core::check(slot.fault == Table::Fault::kNone && slot.value != nullptr, "State::set_global: khoá chuỗi bị từ chối");
    *slot.value = value;
}

// ---- thu gom rác ----

void State::mark_value(Value value) {
    switch (value.type()) {
    case Type::kString: value.as_string().set_marked(true); break;
    case Type::kTable:
        if (!value.as_table().marked()) {
            value.as_table().set_marked(true);
            gray_.push_back(value);
        }
        break;
    case Type::kFunction: {
        FunctionObject& function = object_of(value.as_function());
        if (!function.marked_) {
            function.marked_ = true;
            gray_.push_back(value);
        }
        break;
    }
    case Type::kNil:
    case Type::kBoolean:
    case Type::kNumber: break;
    }
}

void State::drain_gray() {
    while (!gray_.empty()) {
        const Value value = gray_.back();
        gray_.pop_back();
        if (value.type() == Type::kTable) {
            const Table& table = value.as_table();
            if (table.metatable() != nullptr) mark_value(Value(table.metatable()));
            for (const Value item : table.array())
                mark_value(item);
            // Khoá cũng được đánh dấu khi giá trị là nil: khoá chết giữ nguyên chỗ cho tới lần rehash, nên xoá đối tượng
            // của nó sẽ để lại con trỏ treo (gốc đổi khoá thành "dead key"; ở đây giữ sống thêm một lúc, không quan sát được).
            for (const Table::Node& node : table.nodes()) {
                mark_value(node.key);
                mark_value(node.value);
            }
        } else {
            for (CellObject* const cell : object_of(value.as_function()).upvalues_) {
                if (cell->marked_) continue;
                cell->marked_ = true;
                mark_value(cell->value);
            }
        }
    }
}

void State::collect() {
    core::check(frames_.empty(), "State::collect: đang có lời gọi chạy");
    // Gốc.
    mark_value(Value(globals_));
    mark_value(Value(default_meta_));
    for (Table* const typed : type_tables_)
        mark_value(Value(typed));
    for (String* const name : event_names_)
        name->set_marked(true);
    for (const std::unique_ptr<LoadedChunk>& chunk : chunks_) {
        for (const Value constant : chunk->constants)
            mark_value(constant);
    }
    mark_value(error_);
    drain_gray();
    // Quét.
    std::erase_if(tables_, [](const std::unique_ptr<Table>& table) { return !table->marked(); });
    for (const std::unique_ptr<Table>& table : tables_)
        table->set_marked(false);
    std::erase_if(cells_, [this](const std::unique_ptr<CellObject>& cell) {
        if (cell->marked_) return false;
        heap_bytes_ -= sizeof(CellObject);
        return true;
    });
    for (const std::unique_ptr<CellObject>& cell : cells_)
        cell->marked_ = false;
    std::erase_if(functions_, [this](const std::unique_ptr<FunctionObject>& function) {
        if (function->marked_) return false;
        heap_bytes_ -= sizeof(FunctionObject) + function->upvalues_.size() * sizeof(CellObject*);
        return true;
    });
    for (const std::unique_ptr<FunctionObject>& function : functions_)
        function->marked_ = false;
    static_cast<void>(strings_.sweep());
}

} // namespace game::lua
