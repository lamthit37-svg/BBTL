// Bề mặt runtime Lua mà mã C++ sinh từ script giao diện của client 2026 gọi tới: hợp đồng giữa bộ dịch
// (TOOLS/port/luagen) và runtime (module lua). Thiết kế và phân công ở docs/giao-viec/LUA-GEN/THIET-KE.md. Đổi một
// tên hay chữ ký ở mục "BỀ MẶT MÃ SINH" là đổi hợp đồng: báo bên kia và phiên điều phối trong cùng lượt.
//
// Ngữ nghĩa là của LuaPlus.dll trong client 2026 (_VERSION "Lua 5.0.1"; mã tham chiếu
// C:\dev\third_party\reference\lua-5.0.1). Mỗi op làm đúng việc của lệnh máy ảo tương ứng trong lvm.c, lvm.h,
// ltm.c, ltable.c của bản đó: metamethod, ép chuỗi sang số, thứ tự duyệt bảng, câu lỗi. Khác Lua chuẩn, đã đo
// trên LuaPlus.dll ngày 2026-10-15: có `continue`; chuỗi có bảng meta (`("abc"):len()` ra 3); `^` gọi hàm
// toàn cục `__pow` như lvm.c 5.0 làm với số, và `__pow` của LuaPlus là XOR 32 bit (2^10 ra 8, 5^-1 ra 4294967290).
//
// Lỗi không dùng ngoại lệ. Op gặp lỗi ghi lỗi vào State (failed() thành true) rồi trả giá trị rỗng; mã sinh hỏi
// failed() ngay sau mỗi op có thể lỗi và trả về, nên không biểu thức hay lời gọi nào sau chỗ lỗi được chạy, đúng
// thứ tự tác dụng phụ của Lua. pcall của thư viện chuẩn là nơi duy nhất xoá lỗi.
//
// Thu gom rác chỉ chạy khi không có hàm Lua nào đang chạy (State::collect, chủ gọi giữa hai lần gọi vào script).
// Vì thế Value nằm trong biến C++ của mã sinh không cần đăng ký làm gốc, và mã sinh không bao giờ giữ Value qua
// một lần trả về cho chủ.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <span>
#include <string_view>
#include <type_traits>
#include <variant>
#include <vector>

namespace game::lua {

class State;
class String;
class Table;
class Function;
class Cell;

// Sáu kiểu Lua mà script giao diện dùng. Lua 5.0 có thêm userdata và thread: script không tạo, chủ không đưa
// vào, nên chưa có (thêm khi một hàm của game cần trả userdata).
enum class Type : std::uint8_t { kNil, kBoolean, kNumber, kString, kTable, kFunction };

// Một giá trị Lua: 16 byte, chép được như số. Đối tượng (chuỗi, bảng, hàm) thuộc heap của State; Value chỉ trỏ
// tới, không giữ sống (xem câu về thu gom rác ở đầu tệp). Chỉ số của variant trùng thứ tự của Type.
class Value {
public:
    constexpr Value() noexcept = default;

    [[nodiscard]] static constexpr Value boolean(bool is_on) noexcept { return Value(Payload(is_on)); }
    [[nodiscard]] static constexpr Value number(double value) noexcept { return Value(Payload(value)); }
    explicit constexpr Value(String* string) noexcept : payload_(string) {}
    explicit constexpr Value(Table* table) noexcept : payload_(table) {}
    explicit constexpr Value(Function* function) noexcept : payload_(function) {}

    [[nodiscard]] constexpr Type type() const noexcept { return static_cast<Type>(payload_.index()); }
    [[nodiscard]] constexpr bool is_nil() const noexcept { return type() == Type::kNil; }
    // Điều kiện của if/while/and/or/not: mọi giá trị là đúng trừ nil và false.
    [[nodiscard]] constexpr bool truthy() const noexcept {
        const bool* const flag = std::get_if<bool>(&payload_);
        return flag != nullptr ? *flag : !is_nil();
    }

    // Các hàm dưới đòi đúng kiểu (lỗi lập trình nếu sai, core::check): runtime gọi sau khi đã hỏi type().
    [[nodiscard]] bool as_boolean() const;
    [[nodiscard]] double as_number() const;
    [[nodiscard]] String& as_string() const;
    [[nodiscard]] Table& as_table() const;
    [[nodiscard]] Function& as_function() const;

private:
    using Payload = std::variant<std::monostate, bool, double, String*, Table*, Function*>;
    explicit constexpr Value(Payload payload) noexcept : payload_(payload) {}

    Payload payload_;
};
static_assert(sizeof(Value) == 16);
static_assert(std::is_trivially_copyable_v<Value>);
static_assert(Value().type() == Type::kNil && Value::boolean(false).type() == Type::kBoolean);
static_assert(Value::number(0.0).type() == Type::kNumber && !Value::boolean(false).truthy());
static_assert(Value::number(0.0).truthy() && !Value().truthy());

// rawequal: cùng kiểu và cùng giá trị; số so bằng == của double (NaN khác chính nó), đối tượng so theo địa chỉ
// (chuỗi được intern nên hai chuỗi cùng nội dung là một đối tượng).
[[nodiscard]] bool raw_equal(Value left, Value right) noexcept;

// Các giá trị một lần gọi trả về, hoặc danh sách đối số dựng lúc chạy (khi đối số cuối là một lời gọi hay `...`).
// Tới kInline giá trị không cấp phát; nhiều hơn thì dùng vector.
class Results {
public:
    static constexpr std::size_t kInline = 4;

    Results() noexcept = default;
    Results(std::initializer_list<Value> values);

    [[nodiscard]] std::size_t size() const noexcept { return size_; }
    // Giá trị thứ index, nil khi thiếu: đúng cách Lua điều chỉnh số kết quả về số biến nhận.
    [[nodiscard]] Value at_or_nil(std::size_t index) const noexcept;
    [[nodiscard]] Value first() const noexcept { return at_or_nil(0); }
    [[nodiscard]] std::span<const Value> values() const noexcept;

    void push(Value value);
    // Nối mọi giá trị của other (lời gọi cuối trong danh sách đối số hay hàm dựng bảng).
    void append(const Results& other);
    void append(std::span<const Value> values);

private:
    std::array<Value, kInline> inline_{};
    std::vector<Value> spill_;
    std::size_t size_ = 0;
};

using Args = std::span<const Value>;

// ===== BỀ MẶT MÃ SINH =====

// Thân của một hàm Lua đã dịch, hay của một hàm C++ (thư viện chuẩn, hàm của game): cùng một kiểu để lời gọi
// không phân biệt. self là closure đang chạy (hằng của chunk và upvalue lấy từ nó).
using Body = Results (*)(State& state, const Function& self, Args args);

// Mô tả tĩnh của một hàm Lua (bộ dịch sinh một Proto constexpr cho mỗi `function`), hay của một hàm C++.
struct Proto {
    Body body = nullptr;
    // Tên để báo lỗi và vết: "<chunk>:<dòng>" của chữ `function`, hay tên hàm C++.
    std::string_view name;
    // Số tham số có tên (kể cả self của `function a:b()`).
    std::uint16_t parameters = 0;
    // Số upvalue mà closure phải mang (bộ dịch biết lúc dịch).
    std::uint16_t upvalues = 0;
    // Hàm có `...`: phần đối số thừa thành bảng `arg` (vararg_table) như adjust_varargs của ldo.c 5.0.1.
    bool is_vararg = false;
};

// Một chunk đã dịch (một tệp .lua, hay một đoạn Lua nối vào sự kiện của layout). strings là bảng hằng chuỗi: mọi
// hàm của chunk đọc hằng thứ i bằng self.constant(i). Chuỗi có thể chứa byte 0. Chunk mà chính LuaPlus.dll báo lỗi cú
// pháp (21 đoạn "();" của layout gốc) vẫn có mặt để chủ biết: main là nullptr, syntax_error là câu lỗi của bộ dịch.
struct Chunk {
    std::string_view name;
    std::span<const std::string_view> strings;
    const Proto* main = nullptr;
    std::string_view syntax_error;
};

class Function {
public:
    [[nodiscard]] const Proto& proto() const noexcept;
    // Hằng chuỗi thứ index của chunk đã tạo closure này (đã intern lúc nạp chunk).
    [[nodiscard]] Value constant(std::size_t index) const noexcept;
    // Upvalue thứ index (bộ dịch đánh số theo thứ tự trong Proto).
    [[nodiscard]] Cell& upvalue(std::size_t index) const noexcept;

private:
    friend class State;
    Function() = default;
};

// Ô chứa một biến cục bộ bị hàm con bắt (upvalue). Biến không bị bắt là Value thường trong biến C++.
class Cell {
public:
    Value value;

private:
    friend class State;
    Cell() = default;
};

// Đường nóng: cờ lỗi. Định nghĩa ở state.hpp; mã sinh include gen_support.hpp có cả hai.
[[nodiscard]] bool failed(const State& state) noexcept;

// Ngân sách vòng lặp: mã sinh gọi ở mỗi lần quay lại đầu vòng while/repeat/for. Trả false (và ghi lỗi) khi một lần
// gọi từ chủ đã quay quá trần của State (Khác gốc: LuaPlus không có trần, script lặp vô hạn làm treo client).
[[nodiscard]] bool tick(State& state) noexcept;

// OP_GETTABLE / OP_SETTABLE (luaV_gettable, luaV_settable): đi qua __index, __newindex; chuỗi đi qua bảng meta
// của chuỗi.
[[nodiscard]] Value index(State& state, Value object, Value key);
void set_index(State& state, Value object, Value key, Value value);
// OP_GETGLOBAL / OP_SETGLOBAL: như index/set_index trên bảng toàn cục (bảng toàn cục có thể có bảng meta).
[[nodiscard]] Value get_global(State& state, Value name);
void set_global(State& state, Value name, Value value);

// OP_CALL: gọi callee (hàm, hoặc giá trị có __call). Lỗi "attempt to call ..." khi không gọi được.
[[nodiscard]] Results call(State& state, Value callee, Args args);
// OP_SELF của object:name(args): index(object, name). OP_SELF chạy TRƯỚC khi tính đối số, nên bộ dịch gọi
// method_of, hỏi failed(), rồi mới tính đối số và call(hàm, {object, đối số...}).
[[nodiscard]] Value method_of(State& state, Value object, Value name);

// OP_ADD .. OP_UNM (luaV_arith, Arith của lvm.c): ép chuỗi sang số theo luaO_str2d, rồi metamethod. pow gọi hàm
// toàn cục `__pow` khi cả hai là số (lvm.c 5.0), metamethod __pow khi không.
[[nodiscard]] Value add(State& state, Value left, Value right);
[[nodiscard]] Value sub(State& state, Value left, Value right);
[[nodiscard]] Value mul(State& state, Value left, Value right);
[[nodiscard]] Value div(State& state, Value left, Value right);
[[nodiscard]] Value pow(State& state, Value left, Value right);
[[nodiscard]] Value unm(State& state, Value operand);

// OP_CONCAT trên một dải: luaV_concat của lvm.c (gộp từ phải sang, số thành chuỗi theo "%.14g" của MSVCR110,
// __concat khi gặp giá trị không phải chuỗi hay số). Bộ dịch gộp chuỗi `a .. b .. c` liền nhau thành một dải như
// lcode.c 5.0 làm.
[[nodiscard]] Value concat(State& state, Args parts);

// OP_EQ, OP_LT, OP_LE (luaV_equalval, luaV_lessthan, luaV_lessequal). `a > b` là less(b, a), `a >= b` là
// less_equal(b, a), `a ~= b` là !equal(a, b): đúng cách lcode.c 5.0 đổi chỗ toán hạng.
[[nodiscard]] bool equal(State& state, Value left, Value right);
[[nodiscard]] bool less(State& state, Value left, Value right);
[[nodiscard]] bool less_equal(State& state, Value left, Value right);

// OP_NEWTABLE: list_items và record_items là số mục danh sách và số mục có khoá của hàm dựng bảng trong mã nguồn;
// runtime tự mã hoá như lparser.c (luaO_int2fb, luaO_log2 + 1) và cấp như luaH_new, để thứ tự duyệt khớp gốc.
[[nodiscard]] Value new_table(State& state, std::size_t list_items, std::size_t record_items);
// OP_SETLIST: table[first + i] = items[i] (rawset). Bộ dịch xả mục danh sách theo lô 32 (LFIELDS_PER_FLUSH) đúng
// chỗ lparser.c xả, còn mục có khoá thì gán ngay khi gặp (set_index).
void set_list(State& state, Value table, std::size_t first, Args items);

// Upvalue và closure (OP_CLOSURE). upvalues theo thứ tự Proto của hàm con mong đợi.
[[nodiscard]] Cell* new_cell(State& state, Value initial);
[[nodiscard]] Value closure(State& state, const Proto& proto, const Function& parent, std::span<Cell* const> upvalues);

// Bảng `arg` của hàm có `...` (adjust_varargs của ldo.c 5.0.1): luaH_new(extra, 1), extra[i] vào chỉ số i + 1,
// rồi trường n.
[[nodiscard]] Value vararg_table(State& state, Args extra);

// OP_FORLOOP: kiểm index là số, ép limit và step sang số (lỗi "`for' ... must be a number"), cộng step vào index
// rồi trả có chạy thân vòng nữa không. Bộ dịch khởi đầu bằng index = sub(init, step) như fornum của lparser.c.
[[nodiscard]] bool for_next(State& state, Value& index, Value& limit, Value& step);

} // namespace game::lua
