// Trạng thái của một máy Lua (lstate.h, ldo.c, lgc.c của Lua 5.0.1, viết lại cho mã C++ sinh sẵn thay vì bytecode):
// heap (chuỗi, bảng, closure, ô upvalue), bảng toàn cục, bảng meta theo kiểu, ngăn xếp gọi, cờ lỗi và các trần.
//
// Tệp này là phần BÊN TRONG của module lua: mã sinh chỉ gọi vm.hpp (qua gen_support.hpp, kéo tệp này để các hàm nóng
// failed/tick/Function::constant được inline), chủ chỉ dùng host.hpp. State dùng thẳng được trong các tệp của module.
//
// Khác gốc (cùng với những điểm đã nêu ở vm.hpp, host.hpp, table.hpp, string.hpp):
// - Không có ngăn xếp giá trị của Lua: mỗi hàm là một hàm C++ nhận Args và trả Results; ngăn xếp gọi chỉ là danh sách
//   closure đang chạy để đo độ sâu và dựng vị trí câu lỗi.
// - Lỗi đi bằng cờ failed() thay longjmp. Op gặp lỗi đặt cờ rồi trả giá trị rỗng; mã gọi trả về ngay.
// - Thu gom rác mark-sweep chạy duy nhất trong collect() khi không có lời gọi nào, nên Value nằm trong biến C++ của
//   mã sinh không cần là gốc. Gốc: bảng toàn cục, bảng meta mặc định và bảng theo kiểu, tên metamethod, hằng của chunk.
//   Không có __gc, __mode (bảng yếu), userdata, thread: script giao diện không dùng.
// - Mọi kiểu không phải bảng có một bảng riêng (LuaPlus; bảng của chuỗi là chính bảng `string`), và luaT_gettmbyobj trả
//   CHÍNH bảng đó làm "metamethod" của mọi sự kiện (đo trên LuaPlus.dll): đọc, ghi trường của nil/số/boolean/hàm không
//   lỗi mà đi vào bảng kiểu; so sánh hai nil, hai hàm... gọi "bảng" đó nên lỗi "attempt to call a table value".
#pragma once

#include "lua/element.hpp"
#include "lua/host.hpp"
#include "lua/string.hpp"
#include "lua/table.hpp"
#include "lua/vm.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::lua {

// Sự kiện metamethod theo thứ tự TMS của ltm.h.
enum class Event : std::uint8_t {
    kIndex,
    kNewIndex,
    kGc,
    kMode,
    kEq,
    kAdd,
    kSub,
    kMul,
    kDiv,
    kPow,
    kUnm,
    kLt,
    kLe,
    kConcat,
    kCall
};
inline constexpr std::size_t kEventCount = 15;
inline constexpr std::array<std::string_view, kEventCount> kEventNames = {"__index", "__newindex", "__gc", "__mode", "__eq",
    "__add", "__sub", "__mul", "__div", "__pow", "__unm", "__lt", "__le", "__concat", "__call"};

// luaT_typenames: tên kiểu trong câu lỗi và trong type().
[[nodiscard]] constexpr std::string_view type_name(Type type) noexcept {
    switch (type) {
    case Type::kNil: return "nil";
    case Type::kBoolean: return "boolean";
    case Type::kNumber: return "number";
    case Type::kString: return "string";
    case Type::kTable: return "table";
    case Type::kFunction: return "function";
    }
    return "?";
}

class State {
public:
    // ---- đối tượng heap mà vm.hpp chỉ khai trước ----

    // Hằng chuỗi của một chunk đã nạp. Sống tới khi State bị huỷ.
    struct LoadedChunk {
        std::string_view name;
        std::vector<Value> constants;
    };

    // Function của vm.hpp mang dữ liệu nội bộ. Chỉ State tạo (hàm dựng của lớp cơ sở là riêng, State là bạn).
    class CellObject final : public Cell {
    public:
        explicit CellObject(Value initial) { value = initial; }
        bool marked_ = false;
    };

    class FunctionObject final : public Function {
    public:
        FunctionObject(const Proto& proto, const LoadedChunk* chunk, std::vector<CellObject*> upvalues, std::uint32_t serial,
            bool is_native)
            : proto_(&proto), chunk_(chunk), upvalues_(std::move(upvalues)), serial_(serial), is_native_(is_native) {}

        const Proto* proto_;
        // nullptr cho hàm C++.
        const LoadedChunk* chunk_;
        std::vector<CellObject*> upvalues_;
        std::uint32_t serial_;
        bool is_native_;
        bool marked_ = false;
    };

    explicit State(const Limits& limits);
    ~State();
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;

    // ---- lỗi ----

    [[nodiscard]] bool failed() const noexcept { return failed_; }
    // Đặt giá trị lỗi (bất kỳ) và bật cờ. Lỗi đầu tiên thắng: đã lỗi rồi thì giữ nguyên.
    void raise(Value error);
    // Lỗi chuỗi đúng như đưa (error() của script không thêm vị trí khi level 0, câu lỗi dựng sẵn).
    void raise_text(std::string_view message);
    // luaG_runerror: thêm vị trí của hàm Lua đang chạy ("<chunk>:<dòng>: ") nếu hàm trong cùng là Lua.
    void runtime_error(std::string_view message);
    // luaL_error: thêm vị trí của nơi gọi hàm C++ đang chạy (luaL_where(1)).
    void native_error(std::string_view message);
    // luaL_where(level): "<chunk>:<dòng>: " của hàm Lua ở mức level (0 là hàm đang chạy), rỗng nếu là hàm C++.
    [[nodiscard]] std::string where(std::size_t level) const;
    // Lấy giá trị lỗi và xoá cờ (chỗ duy nhất xoá lỗi: pcall của thư viện và protected_call của chủ).
    Value take_error() noexcept;
    // Giá trị lỗi đổi thành chữ như lua_tostring: chuỗi và số theo nội dung, còn lại "(error object is not a string)".
    [[nodiscard]] static std::string error_text(Value error);

    // ---- gọi ----

    // luaD_call cho hàm Lua và hàm C++: đo độ sâu, đẩy khung, chạy thân. Trả rỗng khi lỗi.
    [[nodiscard]] Results invoke(const Function& function, Args args);
    [[nodiscard]] std::size_t depth() const noexcept { return frames_.size(); }
    // Ngân sách vòng lặp của vm.hpp tick(); false (và đã ghi lỗi) khi hết.
    // NOLINTNEXTLINE(bugprone-exception-escape): loop_budget_exceeded chỉ cấp chuỗi lỗi; hết bộ nhớ ở đó là kết thúc tiến trình như mọi nơi khác (HP-07).
    [[nodiscard]] bool consume_tick() noexcept {
        if (++ticks_ <= limits_.loop_budget) return true;
        return loop_budget_exceeded();
    }
    void reset_ticks() noexcept { ticks_ = 0; }

    // ---- đối tượng ----

    // Chuỗi mang đúng các byte. Vượt trần heap thì ghi lỗi "not enough memory" và trả nil.
    [[nodiscard]] Value make_string(std::string_view bytes);
    // luaH_new. Cỡ phải trong miền Table (kMaxBits); vượt trần heap thì ghi lỗi và trả nullptr.
    [[nodiscard]] Table* make_table(std::int32_t array_size, std::int32_t log2_nodes);
    [[nodiscard]] Cell* make_cell(Value initial);
    // Closure Lua: dùng chunk của parent. native: hàm C++.
    [[nodiscard]] Value make_closure(const Proto& proto, const LoadedChunk* chunk, std::span<Cell* const> upvalues);
    [[nodiscard]] Value make_native(const Proto& proto);
    // Hàm C++ có upvalue (iterator của gfind): mỗi giá trị đầu vào thành một ô.
    [[nodiscard]] Value make_native_closure(const Proto& proto, std::span<const Value> upvalues);
    // Nạp chunk (intern hằng chuỗi); gọi lại với cùng chunk trả bản đã nạp.
    [[nodiscard]] const LoadedChunk& load_chunk(const Chunk& chunk);

    [[nodiscard]] std::size_t used_bytes() const noexcept { return heap_bytes_ + strings_.bytes(); }
    // Đã vượt trần heap (kiểm trước mỗi thao tác tạo hay ghi bảng; xem "trần mềm" ở host.hpp::Limits).
    [[nodiscard]] bool over_limit() const noexcept { return used_bytes() > limits_.heap_bytes; }
    // Ghi lỗi "not enough memory" nếu còn extra byte nữa là vượt trần; true khi được phép.
    [[nodiscard]] bool reserve(std::size_t extra);

    // ---- bảng meta ----

    [[nodiscard]] Table& globals() noexcept { return *globals_; }
    // setfenv(0, t): bảng toàn cục mới thay bảng cũ cho mọi lời gọi sau đó (bảng cũ thành rác nếu không ai giữ).
    void replace_globals(Table& table) noexcept { globals_ = &table; }
    [[nodiscard]] Table* type_table(Type type) noexcept { return element(type_tables_, static_cast<std::size_t>(type)); }
    // Bảng meta mà setmetatable(t, nil) gán (defaultmeta của lstate.c); khác bảng của kiểu table (xem lua_getmetatable).
    [[nodiscard]] Table* default_meta() noexcept { return default_meta_; }
    [[nodiscard]] const String& event_name(Event event) const noexcept { return *element(event_names_, static_cast<std::size_t>(event)); }
    // luaT_gettmbyobj có sửa của LuaPlus: bảng thì trường của bảng meta; kiểu khác thì chính bảng của kiểu đó.
    [[nodiscard]] Value metamethod(Value object, Event event) const noexcept;
    // fasttm: trường của bảng meta metatable (có thể nullptr).
    [[nodiscard]] Value fast_metamethod(const Table* metatable, Event event) const noexcept;

    // ---- toàn cục ----

    // rawget / rawset trên bảng toàn cục theo tên.
    [[nodiscard]] Value global(std::string_view name);
    void set_global(std::string_view name, Value value);

    // ---- thu gom rác ----

    void collect();

    // ---- chủ ----

    void set_host(Host* host) noexcept { host_ = host; }
    [[nodiscard]] Host* host() const noexcept { return host_; }
    [[nodiscard]] const Limits& limits() const noexcept { return limits_; }
    // Hạt của rand() kiểu MSVCR110 (math.random): đặt bởi math.randomseed.
    [[nodiscard]] std::uint32_t& random_seed() noexcept { return random_seed_; }

    [[nodiscard]] std::uint32_t next_serial() noexcept { return next_serial_++; }

private:
    [[nodiscard]] bool loop_budget_exceeded();
    void mark_value(Value value);
    void drain_gray();

    Limits limits_;
    // Phải khai báo TRƯỚC mọi bộ chứa đối tượng: bảng trừ phần của nó vào đây khi bị huỷ.
    std::size_t heap_bytes_ = 0;
    StringTable strings_;
    std::vector<std::unique_ptr<Table>> tables_;
    std::vector<std::unique_ptr<FunctionObject>> functions_;
    std::vector<std::unique_ptr<CellObject>> cells_;
    std::vector<std::unique_ptr<LoadedChunk>> chunks_;
    std::unordered_map<const Proto*, const LoadedChunk*> loaded_;

    Table* globals_ = nullptr;
    Table* default_meta_ = nullptr;
    // Theo Type: bảng riêng của từng kiểu. kTable là bảng meta mà bảng mới nhận; kString là bảng `string`.
    std::array<Table*, 6> type_tables_{};
    std::array<String*, kEventCount> event_names_{};

    std::vector<const Function*> frames_;
    bool failed_ = false;
    Value error_;
    std::uint64_t ticks_ = 0;
    std::uint32_t next_serial_ = 1;
    std::uint32_t random_seed_ = 1;
    Host* host_ = nullptr;

    // Hàng đợi tô màu của collect().
    std::vector<Value> gray_;
};

// ---- các hàm nóng của vm.hpp, định nghĩa inline ----

inline bool failed(const State& state) noexcept {
    return state.failed();
}

inline bool tick(State& state) noexcept {
    return state.consume_tick();
}

// Function và Cell của vm.hpp chỉ do State tạo (hàm dựng riêng, State là bạn), nên luôn là FunctionObject, CellObject.
[[nodiscard]] inline const State::FunctionObject& object_of(const Function& function) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-static-cast-downcast): bất biến trên; đây là chỗ duy nhất ép xuống (CL-07).
    return static_cast<const State::FunctionObject&>(function);
}
[[nodiscard]] inline State::FunctionObject& object_of(Function& function) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-static-cast-downcast): xem bản const.
    return static_cast<State::FunctionObject&>(function);
}
[[nodiscard]] inline State::CellObject& object_of(Cell& cell) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-static-cast-downcast): xem bản const của Function.
    return static_cast<State::CellObject&>(cell);
}

inline const Proto& Function::proto() const noexcept {
    return *object_of(*this).proto_;
}

inline Value Function::constant(std::size_t index) const noexcept {
    return object_of(*this).chunk_->constants[index];
}

inline Cell& Function::upvalue(std::size_t index) const noexcept {
    return *object_of(*this).upvalues_[index];
}

} // namespace game::lua
